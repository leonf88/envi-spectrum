; $Id: //depot/idl/releases/IDL_80/idldir/lib/box_cursor.pro#1 $
;
; Copyright (c) 1990-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;+
; NAME:
;	BOX_CURSOR
;
; PURPOSE:
;	Emulate the operation of a variable-sized box cursor (also known as
;	a "marquee" selector).
;
; CATEGORY:
;	Interactive graphics.
;
; CALLING SEQUENCE:
;	BOX_CURSOR, x0, y0, nx, ny [, INIT = init] [, FIXED_SIZE = fixed_size]
;
; INPUTS:
;	No required input parameters.
;
; OPTIONAL INPUT PARAMETERS:
;	x0, y0, nx, and ny give the initial location (x0, y0) and
;	size (nx, ny) of the box if the keyword INIT is set.  Otherwise, the
;	box is initially drawn in the center of the screen.
;
; KEYWORD PARAMETERS:
;	INIT:  If this keyword is set, x0, y0, nx, and ny contain the initial
;	parameters for the box.
;
;	FIXED_SIZE:  If this keyword is set, nx and ny contain the initial
;	size of the box.  This size may not be changed by the user.
;
;	MESSAGE:  If this keyword is set, print a short message describing
;	operation of the cursor.
;
; OUTPUTS:
;	x0:  X value of lower left corner of box.
;	y0:  Y value of lower left corner of box.
;	nx:  width of box in pixels.
;	ny:  height of box in pixels.
;
;	The box is also constrained to lie entirely within the window.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A box is drawn in the currently active window.  It is erased
;	on exit.
;
; RESTRICTIONS:
;	Works only with window system drivers.
;
; PROCEDURE:
;	The graphics function is set to 6 for eXclusive OR.  This
;	allows the box to be drawn and erased without disturbing the
;	contents of the window.
;
;	Operation is as follows:
;	Left mouse button:   Move the box by dragging.
;	Middle mouse button: Resize the box by dragging.  The corner
;		nearest the initial mouse position is moved.
;	Right mouse button:  Exit this procedure, returning the
;			     current box parameters.
;
; MODIFICATION HISTORY:
;	DMS, April, 1990.
;	DMS, April, 1992.  Made dragging more intutitive.
;	June, 1993 - Bill Thompson
;			prevented the box from having a negative size.
;       SJL, Nov, 1997.  Formatted, conform to IDL style guide.
;                       Prevented crash from unitialized corner.
;       RJF, Feb, 1998. Replaced !ERROR_STATE.CODE w/ !MOUSE.BUTTON and
;			fixed some problems w/sizing when a corner might swap.
;       DES, Oct, 1998. Fixed problem when a second btn is pressed before
;			the first was released.  Also corrected problem of checking state
;			of !MOUSE.BUTTON instead of the local variable "button".
;  CT, RSI, May 2000: Add error checking; removed GOTO.
;        Add left+right button=middle button logic.
;-
pro box_cursor, x0, y0, nx, ny, $
	INIT = init, $
	FIXED_SIZE = fixed_size, $
	MESSAGE = message

	ON_ERROR, 2
    DEVICE, GET_GRAPHICS = old, SET_GRAPHICS = 6  ;Set xor
    col = !D.N_COLORS -1
    corner = 0

    if KEYWORD_SET(message) then begin
        print, "Drag Left button to move box."
        print, "Drag Middle button near a corner to resize box."
        print, "Right button when done."
    endif

    if KEYWORD_SET(init) eq 0 then begin ;Supply default values for box:
        if KEYWORD_SET(fixed_size) eq 0 then begin
            nx = !D.X_SIZE/8    ;no fixed size.
            ny = !D.X_SIZE/8
        endif else begin
			IF (N_PARAMS() LT 4) THEN MESSAGE,'Incorrect number of arguments.'
		endelse
        x0 = !D.X_SIZE/2 - nx/2
        y0 = !D.Y_SIZE/2 - ny/2
    endif else begin
		IF (N_PARAMS() LT 4) THEN MESSAGE,'Incorrect number of arguments.'
	endelse

    button = 0
	middleButton = 0
	old_button = 0
	oldMiddleButton = 0

    while(1) do begin
        if (nx lt 0) then begin
            x0 = x0 + nx
            nx = -nx
	    case corner of
		0: corner = 1
		1: corner = 0
		2: corner = 3
		3: corner = 2
	    endcase
; reset the starting drag point...
            mx0 = x & my0 = y
            x00 = x0 & y00 = y0
            nx0 = nx & ny0 = ny
        endif
        if (ny lt 0) then begin
            y0 = y0 + ny
            ny = -ny
	    case corner of
		0: corner = 3
		3: corner = 0
		1: corner = 2
		2: corner = 1
	    endcase
; reset the starting drag point...
            mx0 = x & my0 = y
            x00 = x0 & y00 = y0
            nx0 = nx & ny0 = ny
        endif

        x0 = x0 > 0
        y0 = y0 > 0
        x0 = x0 < (!D.X_SIZE-1 - nx) ;Never outside window
        y0 = y0 < (!D.Y_SIZE-1 - ny)

        px = [x0, x0 + nx, x0 + nx, x0, x0] ;X points
        py = [y0, y0, y0 + ny, y0 + ny, y0] ;Y values

        plots,px, py, COL=col, /DEV, THICK=1, LINES=0 ;Draw the box
        empty                   ;Decwindow bug

        wait, .1		;Dont hog it all


        old_button = button
		oldMiddleButton = middleButton
        cursor, x, y, 2, /DEV	;Wait for a button
        button = !MOUSE.BUTTON
		middleButton = (button eq 2) or (button eq 3) or (button eq 5)

        if ((button ne 0) and (old_button eq 0)) then begin
            mx0 = x		;For dragging, mouse locn...
            my0 = y
            x00 = x0            ;Orig start of ll corner
            y00 = y0
        endif

        if (button eq 1) then begin ;Drag entire box?
            x0 = x00 + x - mx0
            y0 = y00 + y - my0
        endif

        ;;New size?
        if (middleButton and (NOT KEYWORD_SET(fixed_size))) then begin
            if (NOT oldMiddleButton) then begin ;Find closest corner
                mind = 1e6
                for i=0,3 do begin
                    d = float(px[i]-x)^2 + float(py[i]-y)^2
                    if (d lt mind) then begin
                        mind = d
                        corner = i
                    endif
                endfor
                nx0 = nx	;Save sizes.
                ny0 = ny
            endif
            dx = x - mx0 & dy = y - my0	;Distance dragged...
            case corner of
                0: begin
                    x0 = x00 + dx & y0 = y00 + dy
                    nx = nx0 -dx & ny = ny0 - dy
                endcase
                1: begin
                    y0 = y00 + dy
                    nx = nx0 + dx & ny = ny0 - dy
                endcase
                2: begin
                    nx = nx0 + dx & ny = ny0 + dy
                endcase
                3: begin
                    x0 = x00 + dx
                    nx = nx0 -  dx & ny = ny0 + dy
                endcase
            endcase
        endif

        plots, px, py, COL=col, /DEV, THICK=1, LINES=0 ;Erase previous box
        empty                   ;Decwindow bug

        if (button eq 4 AND (NOT oldMiddleButton)) then begin ;Quitting?
            DEVICE,SET_GRAPHICS = old
            return
        endif

    endwhile
end
