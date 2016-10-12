; $Id: //depot/idl/releases/IDL_80/idldir/lib/noise_slur.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	NOISE_SLUR
;
; PURPOSE:
;	Introduce noise into an image by picking randomly selected
;   pixels to be replaced by a neighboring pixel from a random
;   location in the row above.  This is meant to simulate a
;   downward melting effect. There is an 80% chance of using the
;   pixel directly above for replacement and a 10% chance of using
;   either of the pixels to the above left and above right.
;   The probability of replacing a pixel is controlled by a
;   parameter which controls the amount of noise introduced
;   into the image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = NOISE_SLUR(Image [, Randomization][, <keywords>])
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the
;          input image.
;          2D arrays are treated as single channel images.
;          For 3D arrays, the first dimension contains the
;          color channels forming a pixel (Pixel Interleave).
;
;	Randomization: A floating-point scalar in the range 0.0-1.0
;                  that specifies the probability of picking each
;                  pixel for replacement.  0.0 means there is no
;                  chance of replacement and 1.0 means that the
;                  pixel is always replaced,  IDL clamps the
;                  incoming value to the range 0.0-1.0.
;                  Note that this value specifies the probability
;                  of replacement for each pixel.  It does not
;                  necessarily mean that a particular percentage of
;                  the pixels are replaced.  The default value is 0.5.
;
; KEYWORDS:
;   ITERATIONS: The number of times to apply the noise filter.
;               Increasing the number of iterations increases
;               the distance pixels can move.
;
;   SEED: The seed value for the random number generator.
;         This keyword is used in the same way as the SEED
;         argument for RANDOMU.
;
;
; OUTPUTS:
;   The result is an array of the same type and dimensions
;   as the input array.
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
;
;	The following sequence will introduce noise to a test image.
;
;	fn = FILEPATH('rose.jpg', SUBDIR=['examples','data'])
;   READ_JPEG, fn, image
;	result = NOISE_SLUR(image, 0.5, ITER=10)
;	tv, result, /true
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-

function noise_slur, in_arr, $
                     randomization_in, $
					 ITERATIONS=iter_in, $
					 SEED=seed

	compile_opt idl2
	on_error, 2              ;Return to caller if an error occurs
	CATCH, err               ;Catch so we can identify ourself
	if err ne 0 then begin
		CATCH, /CANCEL
		MESSAGE, !ERROR_STATE.MSG
	endif

	;; Obtain dimension info
	n_dims = SIZE(in_arr, /N_DIMENSIONS)
	dims = SIZE(in_arr, /DIMENSIONS)

	;; Check arguments and keywords
	if n_dims ne 2 and n_dims ne 3 then $
		MESSAGE, 'Image array must have 2 or 3 dimensions'
	if N_ELEMENTS(randomization_in) eq 0 then randomization=0.5 $
	else randomization = (randomization_in > 0.0) < 1.0
	iter = N_ELEMENTS(iter_in) gt 0 ? iter_in[0] : 1

	;; Figure out the number of channels in a pixel.
	;; For 2 dim arrays, the array is considered single channel
	n_chan = n_dims eq 2 ? 1 : dims[0]
	;; This is the number of pixels
	n = PRODUCT(dims) / n_chan
	;; Reshape to a vector of pixels
	result = REFORM(in_arr, n_chan, n)
	;; Figure out the width (row length) of the image
	width = n_dims eq 2 ? dims[0] : dims[1]
	;; Set up the linear array offset for each of the possible replacements,
	;; weighting so that we use the pixel directly above 8/10 of the time,
	;; and the pixels to the UL and UR 10% of the time.  Also, make an entry
	;; for 'no replacement'.
	offsets = LONG([0, width-1, width+1, width, width, $
	                width, width, width, width, width, width])

	for i=0L, iter-1 do begin
		;; Find the pixels that need to be replaced
		ind = WHERE(RANDOMU(seed, n, DOUBLE=n gt 1e7) le randomization)
		if ind[0] ne -1 then begin
			;; Make array of indicies into the offsets table.
			;; Start out with all offsets pointing to the 'no replace' entry
			off_ind = BYTARR(n)
			;; Change ONLY the offsets selected for replacement with
			;; a random number between 1 and 10, inclusive
			off_ind[ind] = RANDOMU(seed, N_ELEMENTS(ind)) * 10 + 1
			;; Prevent going off the top edge
			tmp = off_ind[n-width:*]
			ind = WHERE(tmp gt 0)
			if ind[0] ne -1 then tmp[ind] = 0
			off_ind[n-width:*] = tmp
			;; Prevent going off the left edge
			tmp = off_ind[0:*:width]
			ind = WHERE(tmp eq 1)
			if ind[0] ne -1 then tmp[ind] = 0
			off_ind[0:*:width] = tmp
			;; Prevent going off the right edge
			tmp = off_ind[width-1:*:width]
			ind = WHERE(tmp eq 2)
			if ind[0] ne -1 then tmp[ind] = 0
			off_ind[width-1:*:width] = tmp
			;; Add the offsets to the "straight copy" index vector
			ind = LINDGEN(n) + offsets[off_ind]
			;; Use these indices to build new array
			result = result[*, ind]
		endif
	endfor
	;; Reshape back to original
	result = REFORM(result, dims, /OVERWRITE)
	RETURN, result
end

