; $Id: //depot/idl/releases/IDL_80/idldir/lib/color_range_map.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	COLOR_RANGE_MAP
;
; PURPOSE:
;	Map all the pixels of an image to another set of pixels, using
;   source and target ranges to control the mapping.
;   The mapping is performed on each image channel individually.
;   Channel values falling within the source range are linearly mapped to
;   the target range.  The same linear mapping is applied to channel values
;   falling outside the source range, and these values are clipped to the
;   range of the image's data type.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = COLOR_RANGE_MAP(Image, FromColor1, FromColor2, ToColor1, ToColor2)
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the input image.
;          2D arrays are treated as one-channel images.
;          3D arrays must be of the form [N x n x m] where N is the
;          number of image channels.
;
;   FromColor1: An N-element vector of any basic type that specifies the
;               starting color in the source range.
;
;   FromColor2: An N-element vector of any basic type that specifies the
;               ending color in the source range.
;
;   ToColor1: An N-element vector of any basic type that specifies the
;             starting color in the target range.
;
;   ToColor2: An N-element vector of any basic type that specifies the
;             ending color in the target range.
;
; KEYWORDS: None
;
; OUTPUTS:
;   The result is an array of the same dimensions and type as the input Array.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	When the input image is of type unsigned 64-bit (ULONG64), the calculations are
;   carried out using unsigned 64-bit arithmetic.  This implies that the following
;   conditions should be in effect to obtain the best results:
;   - FromColor1 should never be greater than any value in the input image.
;   - FromColor1 < FromColor2 and ToColor1 < ToColor2
;
; PROCEDURE:
;
; EXAMPLE CALLING SEQUENCE:
;   This code will "tone down" the first (red) channel in an image:
;   result = COLOR_RANGE_MAP(image, [0,0,0], [255,255,255], [0,0,0], [200,255,255])
;   Make a "negative" of an image:
;   result = COLOR_RANGE_MAP(image, [0,0,0], [255,255,255], [255,255,255], [0,0,0])
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-
function color_range_map, in_arr, from_color_1_in, from_color_2, to_color_1_in, to_color_2

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)
    type = SIZE(in_arr, /TYPE)

	;; Check arguments
	if n_dims ne 2 and n_dims ne 3 then $
		MESSAGE, 'Image array must have 2 or 3 dimensions'
	n_channels = (n_dims eq 2) ? 1 : dims[0]
	if n_channels ne N_ELEMENTS(from_color_1_in) then $
		MESSAGE, 'Source color 1 must have the the same number of elements as image channels'
	if n_channels ne N_ELEMENTS(from_color_2) then $
		MESSAGE, 'Source color 2 must have the the same number of elements as image channels'
	if n_channels ne N_ELEMENTS(to_color_1_in) then $
		MESSAGE, 'Target color 1 must have the the same number of elements as image channels'
	if n_channels ne N_ELEMENTS(to_color_2) then $
		MESSAGE, 'Target color 2 must have the the same number of elements as image channels'

	;; The mapping computations can require up to twice the number of precision bits, and
	;; we need to use signed calculations.
	;; Determine the appropriate type for the type promotion.
    case type of
        1: calctype = 3    ; byte --> long
        2: calctype = 3    ; int --> long
        3: calctype = 14   ; long --> long64
        12: calctype = 14  ; uint --> long64
        13: calctype = 14  ; ulong --> long64
        ;; Need to just leave the float and 64-bit types alone.
        else: calctype = type
    endcase

	;; Determine clip range, based on image data type
	case type of
		1: clip = ['00'XB, 'FF'XB]
		2: clip = ['8000'XS, '7FFF'XS]
		3: clip = ['80000000'XL, '7FFFFFFF'XL]
		12: clip = ['0000'XU, 'FFFF'XU]
		13: clip = ['00000000'XUL, 'FFFFFFFF'XUL]
		else: clip = [0,0] ; don't bother clipping float and 64-bit types
	endcase

	;; Start with a copy and perform the color range mapping.
	result = in_arr

	;; Adjust types of color ranges so calculations are performed with sufficient precision.
	from_color_1 = FIX(from_color_1_in, TYPE=calctype)
	to_color_1 = FIX(to_color_1_in, TYPE=type)

	;; Compute scale factors
	d_from = FIX(from_color_2, TYPE=calctype) - from_color_1
	d_to = FIX(to_color_2, TYPE=calctype) - to_color_1

	;; Apply mapping to each channel
	for ch=0, n_channels-1 do begin
		f1 = from_color_1[ch]
		df = d_from[ch]
		t1 = to_color_1[ch]
		dt = d_to[ch]
		if df eq 0 then df = 1
		if n_channels gt 1 then begin
			if clip[1] ne 0 then begin
				result[ch,0,0] = ((((result[ch,*,*] - f1) * dt) / df + t1) > clip[0] ) < clip[1]
			endif else begin
				result[ch,0,0] = ((result[ch,*,*] - f1) * dt) / df + t1
			endelse
		endif else begin
			if clip[1] ne 0 then begin
				result[0,0] = ((((result - f1) * dt) / df + t1) > clip[0] ) < clip[1]
			endif else begin
				result[0,0] = ((result - f1) * dt) / df + t1
			endelse
		endelse
	endfor

	RETURN, result
end

