; $Id: //depot/idl/releases/IDL_80/idldir/lib/unsharp_mask.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   UNSHARP_MASK
;
; PURPOSE:
;   Implement the unsharp mask sharpening filter on a two-dimensional array
;   or a truecolor image. For truecolor images the unsharp mask is applied
;   to each channel.
;
; CALLING SEQUENCE:
;   Result = UNSHARP_MASK(Image)
;
; INPUTS:
;   Image: The two-dimensional array or multichannel image to be filtered.
;       If Image is a multichannel image then the TRUE keyword may be used
;       to indicate which dimension represents the channels.
;
; KEYWORD PARAMETERS:
;   AMOUNT: Set this keyword to a float giving the amount (or strength)
;       of filtering to be applied. The default is AMOUNT=1.0, which
;       implies that 100% of the filter difference will be applied
;       to the Image.
;
;   RADIUS: Set this keyword to a float giving the radius in pixels
;       of the Gaussian smoothing filter. The default is RADIUS=3.0.
;       The Gaussian filter is designed to fall to 1/e at a distance
;       of RADIUS/Sqrt(2). The total width of the Gaussian filter
;       is given by CEIL(3*RADIUS)/2*2 + 1 (if RADIUS is an integer then
;       this is just 3*RADIUS + 1).
;
;       Tip: Use small RADIUS values (such as 1.0) for small images
;       or images with fine details. Use larger RADIUS values for large
;       images with larger details.
;
;   THRESHOLD: Set this keyword to a non-negative integer (or a float
;       if Image is floating point) giving the clipping threshold.
;       For each element, if the absolute value of the difference between
;       the original Image and the low-pass filtered array is greater than
;       or equal to THRESHOLD then the filter is applied to that point.
;       The default is THRESHOLD=0, which implies that every point will
;       be filtered.
;
;       Tip: Lower values of THRESHOLD will provide greater sharpening
;       but may cause more speckling, while higher values of THRESHOLD
;       will exclude regions of low contrast and cause less speckling.
;
;   TRUE: If Image is a three-dimensional array (a multichannel image),
;       then set this keyword to 1, 2, or 3 to indicate which dimension
;       represents the channels. If TRUE is not set, and Image
;       has three dimensions, then the default is TRUE=1.
;
; EXAMPLE:
;
;    file = FILEPATH('marsglobe.jpg', SUBDIR=['examples','data'])
;    READ_JPEG, file, image
;
;    ; Display the original image.
;    iImage, image, VIEW_GRID=[2,1]
;
;    ; Display the unsharp-mask-filtered image.
;    result = UNSHARP_MASK(image, RADIUS=4)
;    iImage, result, /VIEW_NEXT
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, July 2003
;   Modified: CT, ITTVIS, Sept 2008:
;       Improve performance and memory usage.
;       Increase width of Gaussian filter from 2*radius to 3*radius,
;       to avoid missing the tails in the convolution.
;
;-
function unsharp_mask, array, $
    AMOUNT=amountIn, $
    RADIUS=radiusIn, $
    THRESHOLD=thresholdIn, $
    TRUE=trueIn

    compile_opt idl2

    ON_ERROR, 2

    ndim = SIZE(array, /N_DIMENSION)
    dims = SIZE(array, /DIMENSIONS)
    if (ndim ne 2) && (ndim ne 3) then $
        MESSAGE, 'Input must be a two or three-dimensional array.'

    true = (N_ELEMENTS(trueIn) eq 1) ? (1 > FIX(trueIn[0]) < 3) : 1

    amount = (N_ELEMENTS(amountIn) eq 1) ? FLOAT(amountIn[0]) : 1.0
    if (ABS(amount) gt 1e30 || ~FINITE(amount)) then $
        MESSAGE, 'Illegal value for AMOUNT keyword.'

    radius = (N_ELEMENTS(radiusIn) eq 1) ? DOUBLE(radiusIn[0]) : 3d
    if (radius lt 0) then $
        MESSAGE, 'RADIUS value must be positive.'

    ; Be sure that the Gaussian width is an odd number.
    n = CEIL(3*radius)/2*2 + 1

    ; No effect.
    if (n eq 1) then $
        return, array

    ; Make sure our RADIUS is not too large.
    imageDims = dims
    if (ndim eq 3) then begin
        case true of
        1: imageDims = dims[[1,2]]
        2: imageDims = dims[[0,2]]
        3: imageDims = dims[[0,1]]
        endcase
    endif
    maxR = MIN(imageDims)/2  ; do not change 2 to 2.0
    if (radius ge maxR) then begin
        MESSAGE, 'For ' + (ndim eq 2 ? 'array' : 'image channel') + $
            ' of dimensions (' + $
            STRTRIM(imageDims[0],2) + ',' + STRTRIM(imageDims[1],2) + $
            '), RADIUS value must be less than ' + STRTRIM(maxR,2) + '.'
    endif


    threshold = (N_ELEMENTS(thresholdIn) eq 1) ? thresholdIn[0] : 0
    if (threshold lt 0) then $
        MESSAGE, 'THRESHOLD value must be greater than or equal to zero.'

    type = SIZE(array, /TYPE)

    ; Multichannel, simply loop over all channels.
    if (ndim eq 3) then begin
    
        if (true ne 3) then begin
        
            ; Faster and less memory to transpose to a MxNx3 array, then back again.
            
            result = TRANSPOSE(array, (true eq 1) ? [1,2,0] : [0,2,1])

            for ch=0,dims[true - 1]-1 do begin
                result[0, 0, ch] = UNSHARP_MASK(result[*, *, ch], $
                    AMOUNT=amountIn, RADIUS=radiusIn, THRESHOLD=thresholdIn)
            endfor
            
            result = TRANSPOSE(result, (true eq 1) ? [2,0,1] : [0,2,1])

        endif else begin

            result = MAKE_ARRAY(dims, /NOZERO, TYPE=type)

            for ch=0,dims[2]-1 do begin
                result[0, 0, ch] = UNSHARP_MASK(array[*, *, ch], $
                    AMOUNT=amountIn, RADIUS=radiusIn, THRESHOLD=thresholdIn)
            endfor

        endelse
        
        return, result
    endif


    ; For computations we need to use a larger, signed integer type.
    case type of
        1: calctype = 2    ; byte --> int
        2: calctype = 3    ; int --> long
        12: calctype = 3   ; uint --> long
        13: calctype = 14  ; ulong --> long64
        15: calctype = 14  ; ulong64 --> long64
        else: calctype = type
    endcase


    ; Low pass Gaussian filter.
    x = DINDGEN(n) - (n-1)/2d
    gaussian = EXP(-(x^2)/((0.7071*radius)^2))

    ; Scale the Gaussian by a large factor and fix it.
    if (calctype ne type) then $
        gaussian = FIX(gaussian*1000, TYPE=calctype)

    norm = TOTAL(gaussian)
    ; No effect
    if (norm eq 1000) then $
        return, array

    ; Do the low-pass filter in two passes, one for the rows and the
    ; next for the columns. This is much faster than building up a
    ; 2D kernel and doing the convolution all at once.

    smoothed = CONVOL(CONVOL(array, gaussian, norm, /EDGE_WRAP), $
        TRANSPOSE(gaussian), norm, /EDGE_WRAP)

    ; Construct the high-pass filtered array.
    difference = array - FIX(TEMPORARY(smoothed), TYPE=calctype)

    ; Apply the clipping threshold to the difference.
    if (threshold gt 0) then $
        difference *= (ABS(difference) ge threshold)

    ; Add a percentage of the high pass to the original image.
    if (amount eq FIX(amount)) then $
        amount = FIX(amount)
    result = array + ((amount eq 1) ? $
        TEMPORARY(difference) : amount*TEMPORARY(difference))


    ; Don't bother to clip huge integer types since we may run into
    ; trouble with overflow anyway.
    case type of
        1: clip = [0s, 255s]
        2: clip = [-32768, 32767]
        12: clip = [0, 65535u]
        else: ; no clipping needed
    endcase

    if (N_ELEMENTS(clip) gt 0) then begin
        mn = MIN(result, MAX=mx)
        if (mn lt clip[0]) then result >= clip[0]
        if (mx gt clip[1]) then result <= clip[1]
    endif


    return, FIX(result, TYPE=type)

end
