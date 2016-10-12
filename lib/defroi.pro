; $Id: //depot/idl/releases/IDL_80/idldir/lib/defroi.pro#1 $
;
; Copyright (c) 1987-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

 ;Define an irregular Region of Interest.
;+
; NAME:         DEFROI
;
; PURPOSE:  Define an irregular region of interest of an image
;       using the image display system and the cursor/mouse.
;
; CATEGORY: Image processing.
;
; CALLING SEQUENCE:
;   R = Defroi(Sx, Sy, X0, Y0)
;
; INPUTS:
;   Sx, Sy = Size of image, in pixels.
;
; Optional Inputs:
;   X0, Y0 = Coordinate of Lower left corner of image on display.
;   If omitted, (0,0) is assumed.  Screen device coordinates.
;   ZOOM = zoom factor, if omitted, 1 is assumed.
;
; OUTPUTS:
;   Function result = vector of subscripts of pixels inside the region.
;   Side effect: The lowest bit in which the write mask is enabled
;   is changed.
;
; OPTIONAL OUTPUTS:
;   Xverts, Yverts = Optional output parameters which will contain
;       the vertices enclosing the region.
;
; KEYWORD Parameters:
;   NOREGION = Setting NOREGION inhibits the return of the
;       pixel subscripts.
;   NOFILL = if set, inhibits filling of irregular region on completion.
;   RESTORE = if set, original image on display is restored to its
;       original state on completion.
;
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   Display is changed if RESTORE is not set.
;
; RESTRICTIONS:
;   Only works for interactive, pixel oriented devices with a
;       cursor and an exclusive or writing mode.
;
; PROCEDURE:
;   The exclusive or drawing mode is used to allow drawing and
;   erasing objects over the original object.
;
;   The operator marks the vertices of the region, either by
;       dragging the mouse with the left button depressed or by
;       marking vertices of an irregular polygon by clicking the
;       left mouse button, or with a combination of both.
;   The center button removes the most recently drawn points.
;   Press the right mouse button when finished.
;   When the operator is finished, the region is filled using
;       the polyfill function, and the polyfillv function is used
;       to compute the subscripts within the region.
;
; MODIFICATION HISTORY:  DMS, March, 1987.
;   Revised for SunView, DMS, Nov, 1987.
;       Added additional argument checking, SNG April, 1991
;   Modified for devices without write masks: DMS, March, 1992.
;       Uses exclusive or mode rather than write masks.
;   Modified to preserve device mode, RJF, Nov 1997.
;   Modified: CT, RSI, Aug 2000: Replace !err with !mouse.
;       Replace /WAIT with /DOWN in CURSOR calls. Prevents multiple
;       points from being erased.
;   Modified: CT, RSI, Aug 2002: Use /WAIT for left mouse button,
;       and /DOWN for middle button. Now you can draw a smooth curve
;       and erase single points. # of points is now unlimited.
;       Also, if less than 3 vertices, it keeps them rather than
;       forcing user to start over.
;   Modified: CT, RSI, June 2003: Better handling for smooth curves
;       on Windows, where it erased points that were just drawn.
;-
;
Function Defroi, Sx, Sy, Xverts, Yverts, X0=x0, Y0=y0, ZOOM = ZOOM, $
    NOREGION = Noregion, NOFILL = Nofill, RESTORE = restore

    COMPILE_OPT idl2

    on_error,2      ;Return to caller if error
    nc1 = !d.table_size-1   ;# of colors available

    if sx lt 1 or sy lt 1 then $        ;Check some obvious things
        message, 'Dimensions of the region must be greater than zero.'

    if sx gt !d.x_size then $
        message, 'The width of the region must be less than ' + $
        strtrim(string(!d.x_size),2)

    sy = sy < !d.y_size

    device, get_graphics_function=oldGrphFunc ; Remember what to restore it to
    device, set_graphics_function=6           ; Set XOR mode

    n = 0

    MESSAGE, /INFO, 'Left button to mark point'
    MESSAGE, /INFO, 'Middle button to erase previous point'
    MESSAGE, /INFO, 'Right button to close region'

    ninc = 100          ; initial max # of points. This can grow.
    xverts = intarr(ninc)        ;arrays
    yverts = intarr(ninc)
    xprev = -1
    yprev = -1
    if n_elements(x0) le 0 then x0 = 0
    if n_elements(y0) le 0 then y0 = 0
    if n_elements(zoom) le 0 then zoom = 1

    !MOUSE.button = 1   ; initialize to left mouse button

    while (1b) do begin  ; infinite loop

        ; Get x,y in device coords.
        ; If the user presses the left button, use /WAIT, which returns
        ; again immediately if the button is still down. This allows the
        ; user to draw curves while holding the button down.
        ; If the user presses the middle or right button, use /DOWN,
        ; which doesn't return until the next button down. Otherwise,
        ; because our loop is so fast, we will get multiple middle
        ; button events, which will erase more than one point at a time.
        Cursor, xx, yy, WAIT=(!MOUSE.button eq 1), $
            DOWN=(!MOUSE.button ne 1), /DEVICE

        switch !MOUSE.button of

        1: begin                ; Add a point.
            xx = (xx - x0) / zoom   ;To image coords
            yy = (yy - y0) / zoom

             ; Out of range or same location?
            if (xx ge sx) || (yy ge sy) || $
                ((xx eq xprev) && (yy eq yprev)) then $
                break
            xprev = xx
            yprev = yy

            if (n ge N_ELEMENTS(xverts)) then begin
                xverts = [xverts, INTARR(ninc)]
                yverts = [yverts, INTARR(ninc)]
            endif

            xverts[n] = xx
            yverts[n] = yy
            addpoint = 1b   ; needed for removing points

            PLOTS, xverts[n]*zoom + x0,yverts[n]*zoom + y0, $
                /DEVICE, COLOR=nc1, /NOCLIP, PSYM=-3, $
                CONTINUE=(n gt 0)

            n++         ; Next point
            break
           end

        ; We use 2 or 5 for the middle button because some Microsoft
        ; compatible mice use 5.
        2:  ; fall thru
        5: begin                ; Delete a point.
            if (n le 1) then $
                break
            ; Back up a point.
            n--
            ; If this is the first point to be removed (we just added a point),
            ; then we need to erase the last point as well.
            if (addpoint) then begin
                PLOTS, xverts[n]*zoom+x0,yverts[n]*zoom + y0, $
                    /DEVICE, COLOR=nc1, /NOCLIP, PSYM=-3
                addpoint = 0b
            endif
            PLOTS, xverts[n-1]*zoom + x0,yverts[n-1]*zoom + y0, $
                /DEVICE, COLOR=nc1, /NOCLIP, PSYM=-3, $
                /CONTINUE
            break
           end

        4: begin                ; Finish ROI.
            if (n ge 3) then $
                goto, done ; out of while loop
            ; If we have less than 3 points, print out a warning and
            ; make the user keep adding points.
            MESSAGE, /INFO, $
              'You must select at least 3 points. Please continue selection.'
            break
           end

        else:  ; ignore
        endswitch

    endwhile

done:
    xverts = xverts[0:n-1]      ;truncate
    yverts = yverts[0:n-1]

    if keyword_set(restore) then begin
        ; Erase all points & lines.
        xv = xverts*zoom + x0
        yv = yverts*zoom + y0
        for i=n-1,0,-1 do begin
            plots, xv[i], yv[i], $
                /dev, color=nc1, /noclip, psym=-3, $
                CONTINUE=(i lt (n-1))
            ; This innocuous wait,0 is needed to flush the graphics cache
            ; on certain systems (such as Windows). Otherwise it will store
            ; up the points and try to draw them all at once, which causes
            ; problems with xor trying to erase the points.
            ; This is also why we need to do this in a loop.
            wait, 0
        endfor
    endif else if keyword_set(nofill) then begin
        plots, [xverts[0],xverts[n-1]]*zoom+x0, $
               [yverts[0],yverts[n-1]]*zoom+y0,$
            /dev,color = nc1,/noclip     ;Complete polygon
    endif else begin
        polyfill, xverts*zoom+x0, yverts*zoom+y0,$
            /dev,color = nc1,/noclip ;Complete polygon
    endelse

    if !order ne 0 then $
        yverts = sy/zoom - 1 - yverts   ;Invert Y?

    device,set_graphics=3   ;Re-enable normal copy write

    ; get subscripts inside area.
    a = keyword_set(noregion) ? 0 : polyfillv(xverts,yverts,sx,sy)

    device, set_graphics_function=oldGrphFunc ; Restore old grphx mode

    return,a
end
