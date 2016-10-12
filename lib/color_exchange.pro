; $Id: //depot/idl/releases/IDL_80/idldir/lib/color_exchange.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	COLOR_EXCHANGE
;
; PURPOSE:
;	Replace image pixels of a given color with a new color.
;   For multi-channel images, every image color channel must match
;   the specified color in order for replacement to occur.  A threshold
;   may be specified to allow replacement of colors close to the specified
;   color.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = COLOR_EXCHANGE(Image, Color, ReplaceColor [, THRESHOLD=Threshold])
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the input image.
;          2D arrays are treated as one-channel images.
;          3D arrays must be of the form [N x n x m] where N is the
;          number of image channels.
;
;   Color: An N-element vector of any basic type that specifies the color
;          in the image that is to be replaced.
;
;   ReplaceColor:  An N-element vector of any basic type that contains
;                  the color to be placed in the image where the image color
;                  matches the Color argument.
;
; KEYWORDS:
;   Threshold: An N-element vector of any basic type that
;              specifies the threshold of the color in the array to
;              be replaced.  Colors where EVERY channel in the range
;              Color +/- Threshold, inclusive, are replaced.
;              The default value is a vector of zeroes, which implies
;              that an exact match is needed to cause a replacement.
;
;              If a threshold is specified, this function promotes the type
;              of the threshold value to ensure the comparisons do not overflow.
;
;
; OUTPUTS:
;   The result is an array of the same dimensions and type as the input Array.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;
; EXAMPLE CALLING SEQUENCE:
;   This code will replace all red pixels in image with green pixels.
;   result = COLOR_EXCHANGE(image, [255,0,0], [0,255,0])
;
; MODIFICATION HISTORY:
; 	Oct 2006 - Initial Version
;-
function color_exchange, in_arr, from_color_in, to_color, THRESHOLD=threshold_in

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)
    type = SIZE(in_arr, /TYPE)

	;; Check array argument
	if n_dims ne 2 and n_dims ne 3 then $
		MESSAGE, 'Image array must have 2 or 3 dimensions'
	n_channels = (n_dims eq 2) ? 1 : dims[0]

	;; Supply default threshold values of zero if not provided by user.
	if N_ELEMENTS(threshold_in) eq 0 then begin
		threshold = FIX(BYTARR(n_channels), TYPE=type)
	endif $
	else threshold = ABS(threshold_in)

	;; Check arguments
	if n_channels ne N_ELEMENTS(from_color_in) then $
		MESSAGE, 'Source color must have the the same number of elements as image channels'
	if n_channels ne N_ELEMENTS(threshold) then $
		MESSAGE, 'Threshold must have the the same number of elements as image channels'
	if n_channels ne N_ELEMENTS(to_color) then $
		MESSAGE, 'Target color must have the the same number of elements as image channels'

	;; Match the type to avoid conversions later on
	from_color = FIX(from_color_in, TYPE=type)

	;; Promote the type of threshold to the next largest signed type, if needed,
	;; so that the threshold comparisons work properly.
	if not ARRAY_EQUAL(FIX(from_color, TYPE=type) - FIX(threshold, TYPE=type), $
	                   FIX(from_color, TYPE=5)    - FIX(threshold, TYPE=5)) or $
	   not ARRAY_EQUAL(FIX(from_color, TYPE=type) + FIX(threshold, TYPE=type), $
	                   FIX(from_color, TYPE=5)    + FIX(threshold, TYPE=5)) then begin
	    case type of
	        1: calctype = 2    ; byte --> int
	        2: calctype = 3    ; int --> long
	        12: calctype = 3   ; uint --> long
	        13: calctype = 14  ; ulong --> long64
	        15: calctype = 15  ; ulong64 --> ulong64 (special case)
	        else: calctype = type
	    endcase
		threshold = FIX(threshold, TYPE=calctype)
		from_color = FIX(from_color, TYPE=calctype)
	endif

	;; Start with a copy and perform the color exchanges.
	result = in_arr

	;; Compute low and high threshold limits
	if type ne 15 then begin
		low = from_color - threshold
		high = from_color + threshold
	endif else begin
		;; Take special care if type is ULONG64
		low = ULON64ARR(N_ELEMENTS(from_color))
		for i=0, N_ELEMENTS(low)-1 do begin
		if threshold[i] le from_color[i] then $
			low[i] = from_color[i] - threshold[i] $
		else $
			low[i] = 0
		endfor
		high = ULON64ARR(N_ELEMENTS(from_color))
		for i=0, N_ELEMENTS(high)-1 do begin
		if 'ffffffffffffffff'XULL - threshold[i] gt from_color[i] then $
			high[i] = ULONG64(from_color[i]) + ULONG64(threshold[i]) $
		else $
			high[i] = 'ffffffffffffffff'XULL
		endfor
	endelse

	;; Special case for 1-channel for efficiency
	if n_channels eq 1 then begin
		ind = WHERE(result ge low[0] AND result le high[0])
		if ind[0] ge 0 then $
			result[TEMPORARY(ind)] = to_color
	endif else begin
		;; Change 2D image to a vector of pixels
		result = REFORM(result, dims[0], dims[1]*dims[2], /OVERWRITE)
		;; A 1 in this flag array mean that the pixel is within the threshold
		t = BYTARR(dims[1]*dims[2]) + 1b
		;; For each channel, keep only the pixels within the threshold
		for i=0, n_channels-1 do begin
			tmp = REFORM(result[i,*])
			t AND= tmp ge low[i] AND tmp le high[i]
		endfor
		tmp = 0
		;; Surviving pixels have a 1 in this array
		ind = WHERE(TEMPORARY(t) eq 1)
		if ind[0] ge 0 then begin
			for i=0, n_channels-1 do begin
				result[i,ind] = to_color[i]
			endfor
		endif
		;; Change back to original dims
		result = REFORM(result, dims[0], dims[1], dims[2], /OVERWRITE)
	endelse
	RETURN, result
end

