; $Id: //depot/idl/releases/IDL_80/idldir/lib/edge_dog.pro#1 $
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   EDGE_DOG
;
; PURPOSE:
;   Perform Difference of Gaussians Edge Detection on a two-dimensional array.
;
; CALLING SEQUENCE:
;   Result = EDGE_DOG(Image)
;
; INPUTS:
;   Image: The two-dimensional array to be filtered.
;
; RETURNS:
;	An array containing signed difference values representing the detected edges.
;   The type of the returned data depends on the input type as follows:
;
;	BYTE --> INT
;	INT --> LONG
;	UINT --> LONG
;	ULONG --> LONG64
;	ULONG64 --> LONG64
;
;	For all other input types, the output type is the same as the input type.
;
; KEYWORD PARAMETERS:
;
;   RADIUS1, RADIUS2: Set these keywords to scalars giving the radius in pixels
;       of the Gaussian smoothing filters. The defaults are RADIUS1=3.0
;       and RADIUS2=5.0.  The difference between the two RADIUS values influences
;		the size of the features detected by the filter.
;
;       The Gaussian filters are designed to fall to 1/e at a distance
;       of RADIUS/Sqrt(2). The total width of the Gaussian filter
;       is given by CEIL(2*RADIUS)/2*2 + 1 (if RADIUS is an integer then
;       this is just 2*RADIUS + 1).
;
;       Tip: Larger values for both RADIUS values results in isolating larger
;		features and generating thicker edges.
;
;   THRESHOLD: Set this keyword to a non-negative integer (or a float
;       if Image is floating point) giving the clipping threshold.
;       For each element, if the difference between the gaussian-filtered
;       images is greater than or equal to THRESHOLD then the difference
;       is placed in the result array. Otherwise, a zero is placed in the result array.
;       The default is THRESHOLD=0, which implies that every point will
;       contain the gaussian difference
;
;       Tip: Higher values of THRESHOLD will exclude smaller features.
;
;	ZERO_CROSSINGS: Set this keyword to a two-element vector containing the
;		values used for replacing array values less than or equal to 0 and greater
;		than zero, respectively.  This creates a binary image useful for visualizing
;		the edges.
;
;
; EXAMPLE:
;
;	file = FILEPATH('ctbone157.jpg', SUBDIR=['examples','data'])
;	READ_JPEG, file, image
;   ; Display the original image.
;	iImage, image, VIEW_GRID=[2,1], DIMENSIONS = [800, 500]
;   ; Display the edges from the difference of gaussians.
;	result = EDGE_DOG(image, RADIUS1=6.0, RADIUS2=20.0, THRESHOLD=15, ZERO_CROSSINGS=[0,255])
;	iImage, result, /VIEW_NEXT
;
; MODIFICATION HISTORY:
;   Written by: ITTVIS, October 2006
;   Modified:
;
;-
function edge_dog, array, $
    RADIUS1=radius1In, $
    RADIUS2=radius2In, $
    THRESHOLD=thresholdIn, $
    ZERO_CROSSINGS=zeroCrossingsIn

    compile_opt idl2

    ON_ERROR, 2

    ndim = SIZE(array, /N_DIMENSION)
    dims = SIZE(array, /DIMENSIONS)
    if (ndim ne 2) then $
        MESSAGE, 'Input must be a two-dimensional array.'

    radius1 = (N_ELEMENTS(radius1In) eq 1) ? DOUBLE(radius1In[0]) : 3d
    if (radius1 lt 0) then $
        MESSAGE, 'RADIUS1 value must be positive.'
    radius2 = (N_ELEMENTS(radius2In) eq 1) ? DOUBLE(radius2In[0]) : 5d
    if (radius2 lt 0) then $
        MESSAGE, 'RADIUS2 value must be positive.'

    ; Make sure our RADIUS is not too large.
    imageDims = dims
    maxR = MIN(imageDims)/2  ; do not change 2 to 2.0
    if (radius1 ge maxR) then begin
        MESSAGE, 'For array of dimensions (' + $
            STRTRIM(imageDims[0],2) + ',' + STRTRIM(imageDims[1],2) + $
            '), RADIUS1 value must be less than ' + STRTRIM(maxR,2) + '.'
	endif
    if (radius2 ge maxR) then begin
        MESSAGE, 'For array of dimensions (' + $
            STRTRIM(imageDims[0],2) + ',' + STRTRIM(imageDims[1],2) + $
            '), RADIUS2 value must be less than ' + STRTRIM(maxR,2) + '.'
    endif

    threshold = (N_ELEMENTS(thresholdIn) eq 1) ? thresholdIn[0] : 0
    if (threshold lt 0) then $
        MESSAGE, 'THRESHOLD value must be greater than or equal to zero.'


    ; For computations we need to use a larger, signed integer type.
    type = SIZE(array, /TYPE)
    case type of
        1: calctype = 2    ; byte --> int
        2: calctype = 3    ; int --> long
        12: calctype = 3   ; uint --> long
        13: calctype = 14  ; ulong --> long64
        15: calctype = 14  ; ulong64 --> long64
        else: calctype = type
    endcase


    ; Be sure that the Gaussian width is an odd number.
    n1 = CEIL(2*radius1)/2*2 + 1
    n2 = CEIL(2*radius2)/2*2 + 1

    ; Construct Gaussian filters.
    x = DINDGEN(n1) - (n1-1)/2d
    gaussian1 = EXP(-(x^2)/((0.7071*radius1)^2))
    x = DINDGEN(n2) - (n2-1)/2d
    gaussian2 = EXP(-(x^2)/((0.7071*radius2)^2))

    ; Scale the Gaussian by a large factor and fix it.
    gaussian1 = FIX(gaussian1*1000, TYPE=calctype)
    gaussian2 = FIX(gaussian2*1000, TYPE=calctype)

    norm1 = TOTAL(gaussian1)
    norm2 = TOTAL(gaussian2)

    ; Apply the filter in two passes, one for the rows and the
    ; next for the columns. This is much faster than building up a
    ; 2D kernel and doing the convolution all at once.

    smoothed1 = CONVOL(CONVOL(array, gaussian1, norm1, /EDGE_TRUNCATE), $
        TRANSPOSE(gaussian1), norm1, /EDGE_TRUNCATE)
    smoothed2 = CONVOL(CONVOL(array, gaussian2, norm2, /EDGE_TRUNCATE), $
        TRANSPOSE(gaussian2), norm2, /EDGE_TRUNCATE)


    ; Construct the difference array.
    difference = FIX(TEMPORARY(smoothed1), TYPE=calctype) - $
                 FIX(TEMPORARY(smoothed2), TYPE=calctype)

    ; Apply the clipping threshold to the difference.
    if (threshold gt 0) then $
        difference *= (ABS(difference) ge threshold)

	; Apply zero crossings
	if N_ELEMENTS(zeroCrossingsIn) eq 2 then begin
		ind = WHERE(difference gt 0, COMPLEMENT=indn)
		if ind[0] ne -1 then $
			difference[ind] = zeroCrossingsIn[1]
		if indn[0] ne -1 then $
			difference[indn] = zeroCrossingsIn[0]
	endif

	return, difference

end
