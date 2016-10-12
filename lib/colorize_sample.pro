; $Id: //depot/idl/releases/IDL_80/idldir/lib/colorize_sample.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	COLORIZE_SAMPLE
;
; PURPOSE:
;	"Colorize" a greyscale image by matching luminance levels
;   with an RGB sample table.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = COLORIZE_SAMPLE(Image, Sample)
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the input image with range [0-255].
;          A 2D array is treated as a greyscale image.
;          A 3D array must contain RGB image data and be of the form [3,m,n].  This image
;          is assumed to be greyscale and so only the first channel is used.
;
;	Sample: A 2D or 3D array of any basic type with range [0-255] containing RGB sample colors.
;           The array must be of the form [3,n] or [3,m,n] and is treated as a simple
;           list of RGB values.
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
;   This function finds matches between the luminance values in the souce
;   image and the luminance values of the RGB sample color table. Matching
;   luminance values are replaced with the RGB from the sample table, thus
;   "colorizing" the image.
;
;   Note that, in general, this is an imperfect operation since the luminance
;   value does not completely represent the RGB color it could have.  There
;   are many RGB values that have the same luminance value.  However, a
;   carefully constructed sample table may produce reasonable results in
;   certain situations.
;
;   If there is no luminance value in the sample table that matches image
;   luminance values, the next closest luminance value from the sample
;   table is used.
;
;   If more than one RGB sample color has a given luminance, the colors
;   are distributed in the image where that luminance is present, using
;   the same percentage of RGB distribution of that luminance in the sample
;   table.  For example, COLOR1 and COLOR2 are colors in the sample
;   table that have the same luminance value.  If COLOR1 appears in the
;   sample table 5 times more frequently than COLOR2, then COLOR1 will
;   be used to replace 5 times more pixels than COLOR2 in the
;   resulting image.  These multiple colors are distributed randomly to
;   reduce clumping of too many like colors.  This procedure may not produce
;   the expected results as it is guessing at the location and distribution of
;   the multiple colors that all have the same luminance values.
;
; EXAMPLE CALLING SEQUENCE:
;
;	The following sequence will colorize a test image with an
;   8-color sample table:
;
;	image = BYTSCL(DIST(400))
;	sample = BYTARR(3,8)
;	sample[0,*] = BINDGEN(8) * 32
;	sample[1,*] = BINDGEN(8) * 32
;	result = COLORIZE_SAMPLE(image, sample)
;	tv, result, /TRUE
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-

function colorize_sample, in_arr, sample_arr

	compile_opt idl2
	ON_ERROR, 2              ;Return to caller if an error occurs

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)
	sample_n_dims = SIZE(sample_arr, /N_DIMENSIONS)
	sample_dims = SIZE(sample_arr, /DIMENSIONS)

	;; Check arguments
	if n_dims ne 2 and n_dims ne 3 then $
		MESSAGE, 'Image array must have 2 or 3 dimensions'
	if n_dims eq 3 && dims[0] ne 3 then $
		MESSAGE, 'Image array must be RGB and in the form [3,m,n]'
	if sample_n_dims ne 2 and sample_n_dims ne 3 then $
		MESSAGE, 'Sample array must have 2 or 3 dimensions'
	if sample_dims[0] ne 3 then $
		MESSAGE, 'Sample array must be RGB and in the form [2,m,n] or [3,m,n]'

	;; Input image is 1-channel 2D array.  Convert to byte vector
	if n_dims eq 2 then begin
		image = REFORM(BYTE(in_arr), dims[0]*dims[1])
	endif $
	;; We really wanted to see a 1-channel image here, but if user
	;; passes a 3-channel image, we expect it to be greyscale, so
	;; all channels are equal.  Just grab one channel and forge on.
	else begin
		dims = dims[1:2]
		image = REFORM(BYTE(in_arr[0,*,*]), dims[0]*dims[1])
	endelse

	;; Create a Lum vector out of the RGB sample table
	COLOR_CONVERT, sample_arr, sample_yuv, /RGB_YUV
	sample_lum = REFORM(BYTE(sample_yuv[0,*,*] * 255), N_ELEMENTS(sample_yuv)/3)

	;; Create a packed RGB vector out of RGB sample table. This makes RGB
	;; compare operations easier.
	sample_rgb = BYTE(REFORM(sample_arr, 3, N_ELEMENTS(sample_arr)/3))
	packed_rgb = REFORM(LONG(sample_rgb[0,*]) + ISHFT(LONG(sample_rgb[1,*]),8) + $
	             ISHFT(LONG(sample_rgb[2,*]), 16))

	;; Create result array to return to caller
	result = BYTARR(3, dims[0] * dims[1])

	;; Get the frequencies of the lum values in both the image and sample table.
	;; Both are LONG[256]
	hist = HISTOGRAM(image)
	sample_hist = HISTOGRAM(sample_lum)

	;; For each Lum value in the image, determine an RGB color or colors, using the
	;; sample table, to replace all pixels in the original image with that lum value.
	for lum = 0, 255 do begin
		;; If no pixels in image with this lum value, move along
		if hist[lum] eq 0 then continue
		image_ind = WHERE(image eq lum)
		;; Now we have pixels with the current lum value.  If there are no colors in
		;; the sample table with that lum value, we must seek the closest lum value
		;; that does have colors in the sample table.
		if sample_hist[lum] eq 0 then begin
			;; Find the index of the lum value in the sample table that is closest
			;; to the current lum value
			void = MIN(ABS(FIX(sample_lum) - lum), index)
			;; Get the indicies into the sample table for all RGB's with this lum.
			sample_ind = WHERE(sample_lum eq sample_lum[index])
		endif $
		;; These are the indices into the RGB sample where the RGB values
		;; have the same Lum as the current loop lum.
		else sample_ind = WHERE(sample_lum eq lum)
		;; These are the RGB values that match the lum value
		match = packed_rgb[sample_ind]
		;; Get a frequency count of the RGB values.
		;; Using HISTOGRAM seems natural here, but there are too many bins because
		;; of the long distances between the packed RGB values.
		u = UNIQ(match, SORT(match))
		counts = LONARR(N_ELEMENTS(u), /NOZERO)
		for i=0, N_ELEMENTS(u)-1 do begin
			n = WHERE(match eq match[u[i]], count)
			counts[i] = count
		endfor
		;; We're going to distribute the RGB's corresponding to a given lum
		;; into the result image using the same percentage that they occur in
		;; the sample image.  Convert the frequency count to percentages, total
		;; cumulatively for conversion into array indices that are then scaled
		;; to the result image.
		n = TOTAL(FLOAT(TEMPORARY(counts)) / N_ELEMENTS(match), /CUMULATIVE)
		n = LONG([0,n] * N_ELEMENTS(image_ind)+0.5)
		;; We don't know which pixels get which RGB for the same Lum, so
		;; might as well be random about it, just to be fair,
		shuf = image_ind[SORT(RANDOMU(seed, N_ELEMENTS(image_ind)))]
		;; For each unique RGB, replace the calculated percentage of
		;; randomly-picked result image pixels with the RGB value.
		for i=0, N_ELEMENTS(u)-1 do begin
			if n[i] lt n[i+1] then begin
				ind = shuf[n[i]:n[i+1]-1]
				m = match[u[i]]
				result[0,ind] = m
				result[1,ind] = ISHFT(m, -8)
				result[2,ind] = ISHFT(m, -16)
			endif
		endfor
	endfor
	;; Format and return final result
	result = REFORM(result, 3, dims[0], dims[1], /OVERWRITE)
	RETURN, result
end

