; $Id: //depot/idl/releases/IDL_80/idldir/lib/colormap_gradient.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	COLORMAP_GRADIENT
;
; PURPOSE:
;	Map an image into a specified luminance-based gradient.
;   This is useful for applying a "false color" to an image,
;   based on image luminance levels.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = COLORMAP_GRADIENT(Image [, Gradient])
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the input image with range [0-255].
;          A 2D array is treated as a greyscale image.
;          A 3D array must contain RGB image data and be of the form [3,m,n].
;
;   Gradient: An optional scalar integer or [3, 256] byte array.
;             If not provided, this function maps the image to a greyscale gradient.
;             If a scalar integer is provided, this function maps the image
;             to a color table specified by the scalar integer (See LOADCT).
;             If a [3, 256] byte array is provided, this function maps the image
;             into the RGB color table stored in this array.
;
; KEYWORDS: None
;
; OUTPUTS:
;   The result is a 3-channel byte array of the same width and height as the input Array.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;   This function obtains Luminance values for the image and then uses the Luminance
;   values as indices into a color table to produce a new 3-channel image.
;
; EXAMPLE CALLING SEQUENCE:
;
;	The following sequence will map the entire image into a blue gradient:
;
;	fn = FILEPATH('rose.jpg', SUBDIR=['examples', 'data'])
;	READ_JPEG, fn, rose
;	result = COLORMAP_GRADIENT(rose, 1)
;   TV, result, /TRUE
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-


function colormap_gradient, in_arr, gradient

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)

	;; Check arguments
	if n_dims ne 2 and n_dims ne 3 then $
		MESSAGE, 'Image array must have 2 or 3 dimensions'
	if n_dims eq 3 && dims[0] ne 3 then $
		MESSAGE, 'Image array must be RGB and in the form [3,m,n]'

	;; Get the luminance channel and make ready for gradient table indexing
	if n_dims eq 2 then $
		y = BYTE(in_arr) $
	else begin
		COLOR_CONVERT, in_arr, yuv, /RGB_YUV
		y = BYTE(REFORM(yuv[0,*,*]) * 255)
	endelse

	;; No gradient?  Use greyscale
	if N_ELEMENTS(gradient) eq 0 then begin
		result = TRANSPOSE([ [[y]], [[y]], [[y]] ], [2,0,1])
		return, result
	;; A single value represents a LOADCT index
	endif else if N_ELEMENTS(gradient) eq 1 then begin
		;; Save current color table
		TVLCT, saveR, saveG, saveB, /GET
		;; Try to load requested table
		CATCH, err               ;Catch so we can identify ourself
			if err ne 0 then begin
			CATCH, /CANCEL
			MESSAGE, !ERROR_STATE.MSG
		endif
		LOADCT, gradient, /SILENT
		CATCH, /CANCEL
		;; Get our colors
		TVLCT, R, G, B, /GET
		;; Restore original table
		TVLCT, saveR, saveG, saveB
	;; Hopefully a [3,256] color table
	endif else begin
		g_dims = SIZE(gradient, /DIMENSIONS)
		if N_ELEMENTS(g_dims) eq 2 && g_dims[0] eq 3 && g_dims[1] eq 256 then begin
			R = BYTE(REFORM(gradient[0,*]))
			G = BYTE(REFORM(gradient[1,*]))
			B = BYTE(REFORM(gradient[2,*]))
		endif else begin
			MESSAGE, 'Gradient must be a scalar or a [3,256] array'
		endelse
	endelse

	;; Construct and return new image
	result = TRANSPOSE([ [[R[y]]], [[G[y]]], [[B[y]]] ], [2,0,1])
	RETURN, result
end

