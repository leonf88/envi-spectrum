; $Id: //depot/idl/releases/IDL_80/idldir/lib/mpeg_put.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MPEG_PUT
;
; PURPOSE:
;       Stores the given image at the given frame index.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       MPEG_PUT, mpegID
;
; INPUTS:
;       mpegID: The object reference returned from an MPEG_OPEN call.
;
; KEYWORD PARAMETERS:
;	COLOR: Set to write 24 bit MPEG from 8 bit pseudo color direct
;		graphics windows.
;       FRAME: Set this keyword to the frame at which the image is to
;              be loaded.  If the frame number matches a previously
;              put frame, the previous frame is overwritten.  The 
;              default is 0.
;       IMAGE: Set this keyword to an mxn or 3xmxn array representing
;              the image to be loaded at the given frame.  Mutually
;              exclusive of the WINDOW keyword.
;       ORDER: Set this keyword to a non-zero value to indicate that
;              the rows of the image should be drawn from top to bottom.
;              By default, the rows are drawn from bottom to top.
;       WINDOW: Set this keyword to the index of a Direct Graphics
;              Window (or to an object reference to an IDLgrWindow or
;              IDLgrBuffer object) to indicate that the image to be
;              loaded is to be read from the given window or buffer.
;
; EXAMPLE:
;       MPEG_PUT, mpegID, FRAME=2, IMAGE=DIST(100)
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, December, 1997
;-

pro MPEG_PUT, mpegID, FRAME = frame, IMAGE = image, ORDER = order, $
              WINDOW = window, COLOR=color

common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

    ON_ERROR,2                    ;Return to caller if an error occurs

    ; let user know about demo mode limitation.
    ; mpeg object is disabled in demo mode
    if (LMGR(/DEMO)) then begin
        MESSAGE, 'Feature disabled for demo mode.'
        return
    endif

    ;; Check all the input parameters
    if (not OBJ_ISA(mpegID, 'IDLgrMPEG')) then $
      MESSAGE,'Argument must be an IDLgrMPEG object reference.'

    if (N_ELEMENTS(frame) eq 0) then $
      frameFlag = 0 $
    else $
      frameFlag = frame
    if (frameFlag lt 0) then $
      MESSAGE,'FRAME values must be non-negative.'
    
    imageFlag = N_ELEMENTS(image) gt 0
    windowFlag = N_ELEMENTS(window) gt 0
    bOrder = keyword_set(order) ;Set if ORDER is set
    
    if ((imageFlag + windowFlag) eq 0) then $
      MESSAGE,'Image is undefined.' $
    else if (imageFlag gt 0) and (windowFlag gt 0) then $
      MESSAGE,'IMAGE and WINDOW are mutually exclusive keywords.'
    
    if (imageFlag gt 0) then begin     ;Must be an image
        nDims = size(image, /N_DIMENSIONS)
        if ((nDims ne 2) and (nDims ne 3)) then $

          MESSAGE,'Image dimensions must be 2D or 3D.'
        if (bOrder) then $
          mpegID->Put, REVERSE(Image, nDims), frameFlag $
        else $
          mpegID->Put, Image, frameFlag
    endif else begin            ;Must be a window    
        if (OBJ_VALID(window)) then begin ;a GR2 window?
            if (OBJ_ISA(window, 'IDLgrWindow') or $
                OBJ_ISA(window, 'IDLgrBuffer')) then begin
                myImage = window->Read() ;(m,n) or (3,m,n)
                if (bOrder) then $
                    myImage->SetProperty, ORDER=1
                mpegID->Put, MyImage, frameFlag
                OBJ_DESTROY, MyImage
            endif
        endif else begin        ;Must be a GR1 window
            oldWin = !D.WINDOW
            WSET, window
            if (!d.n_colors le 256) then $
              myImage = TVRD(ORDER=bOrder) $
            else $
              myImage = TVRD(TRUE=1, ORDER=bOrder)
            WSET, oldWin
            bOrder = 0          ;Now its not reversed
                                ; Convert to 24 bit color from 8 bit?
            if (KEYWORD_SET(color) and (!d.n_colors le 256)) then begin
; Apply color tables and create an (!d.x_size, 3 * !d.y_size) array:
                myImage = [[r_curr[myImage]], [g_curr[myImage]], $
                           [b_curr[myImage]]]
; Reform to (!D.x_size * !D.y_size, 3) and then transpose to
; interleave color as first dimension.
                myImage = TRANSPOSE(REFORM(myImage,!d.x_size * !d.y_size, 3,$ 
                                           /OVERWRITE))
; Now back to (3, !d.x_size, !d.y_size)
                myImage = REFORM(myImage, 3, !d.x_size, !d.y_size, /OVERWRITE)
            endif               ;Colorize
            if (bOrder) then $
               mpegID->Put, $
                 REVERSE(MyImage, size(myImage, /N_DIMENSIONS)), frameFlag $
            else mpegID->Put, MyImage, frameFlag
        endelse                 ;Gr1 window
                                ;Write to MPEG stream
    endelse                     ;A window
end
