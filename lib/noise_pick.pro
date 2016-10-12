; $Id: //depot/idl/releases/IDL_80/idldir/lib/noise_pick.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	NOISE_PICK
;
; PURPOSE:
;	Introduce noise into an image by picking randomly selected
;   pixels to be replaced by a neighboring pixel from a random
;   direction.  The probability of replacing a pixel is controlled
;   by a parameter which controls the amount of noise introduced
;   into the image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = NOISE_PICK(Image [, Randomization][, <keywords>])
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
;	image = BYTSCL(DIST(400))
;	result = NOISE_PICK(image, 0.9, ITER=30)
;	tv, result
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-

function noise_pick, in_arr, $
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
	;; Compute the linear array offset for each of the 8 neighbors.
	offsets = LONG([-width-1, -width, -width+1, $
	                        -1, 0, 1, $
	                 width-1, width, width+1])

	for i=0L, iter-1 do begin
		;; Find the pixels that need to be replaced
		ind = WHERE(RANDOMU(seed, n, DOUBLE=n gt 1e7) le randomization)
		if ind[0] ne -1 then begin
			;; Make array of indicies into the offsets table.
			;; Start out with all offsets pointing to the center entry
			off_ind = BYTARR(n) + 4b
			;; Change ONLY the offsets selected for replacement with
			;; a random number between 0 and 8, inclusive
			off_ind[ind] = RANDOMU(seed, N_ELEMENTS(ind)) * 9
			;; Prevent going off the bottom edge
			tmp = off_ind[0:width-1]
			ind = WHERE(tmp lt 3)
			if ind[0] ne -1 then tmp[ind] = 4
			off_ind[0:width-1] = tmp
			;; Prevent going off the top edge
			tmp = off_ind[n-width:*]
			ind = WHERE(tmp gt 5)
			if ind[0] ne -1 then tmp[ind] = 4
			off_ind[n-width:*] = tmp
			;; Prevent going off the left edge
			tmp = off_ind[0:*:width]
			ind = WHERE(tmp eq 0 OR tmp eq 3 OR tmp eq 6)
			if ind[0] ne -1 then tmp[ind] = 4
			off_ind[0:*:width] = tmp
			;; Prevent going off the right edge
			tmp = off_ind[width-1:*:width]
			ind = WHERE(tmp eq 2 OR tmp eq 5 OR tmp eq 8)
			if ind[0] ne -1 then tmp[ind] = 4
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

