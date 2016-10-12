; $Id: //depot/idl/releases/IDL_80/idldir/lib/noise_hurl.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	NOISE_HURL
;
; PURPOSE:
;	Introduce noise into an image by changing randomly selected
;   pixels to random colors.  The probability of changing a pixel
;   is controlled by a parameter which controls the amount of
;   noise introduced into the image.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = NOISE_HURL(Image [, Randomization][, <keywords>])
;
; INPUTS:
;	Image: Any array of any basic type containing the input image.
;          1D and 2D arrays are treated as single channel images.
;          Arrays with more than 2 dimensions are treated as n-channel images,
;          where the number of channels is contained in the first dimension.
;          For example, a 3 x 200 x 200 array is a 3-channel 200 by 200 image.
;          And a 4 x 200 x 200 x 5 array is considered as a stack of 5 200 by 200
;          4-channel images.
;
;	Randomization: A floating-point scalar in the range 0.0-1.0 that specifies the
;                  probability of replacing each pixel with a random color.  0.0 means
;                  there is no chance of replacement and 1.0 means that the pixel is
;                  always replaced,  IDL clamps the incoming value to the range 0.0-1.0.
;                  Note that this value specifies the probability of replacement for each
;                  pixel.  It does not necessarily mean that a particular percentage of
;                  the pixels are replaced.  The default value is 0.5.
;
; KEYWORDS:
;   ITERATIONS: The number of times to apply the noise filter.  Note that nearly the same
;               effect can be achieved by increasing the Randomization value.
;
;   REPLACE_MAX: The maximum value used for the randomly-generated replacement colors.
;                The default value is 255.
;
;   REPLACE_MIN: The minimum value used for the randomly-generated replacement colors.
;                The default value is 0.
;
;   SEED: The seed value for the random number generator. This keyword is used in the
;         same way as the SEED argument for RANDOMU.
;
;
; OUTPUTS:
;   The result is an array of the same type and dimensions as the input array.
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
;	The following sequence will add noise to a test image.
;
;	image = BYTSCL(DIST(400))
;	result = NOISE_HURL(image, 0.2)
;	tv, result
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-

function noise_hurl, in_arr, randomization_in, $
								ITERATIONS=iter_in, $
								REPLACE_MAX=rmax_in, $
								REPLACE_MIN=rmin_in, $
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
	if n_dims eq 0 then $
		MESSAGE, 'Input argument must be an array'
	if N_ELEMENTS(randomization_in) eq 0 then randomization=0.5 $
	else randomization = (randomization_in > 0.0) < 1.0
	rmax = N_ELEMENTS(rmax_in) gt 0 ? rmax_in[0] : 255
	rmin = N_ELEMENTS(rmin_in) gt 0 ? rmin_in[0] : 0
	iter = N_ELEMENTS(iter_in) gt 0 ? iter_in[0] : 1

	;; Figure out the number of channels in a pixel.
	;; For 1 or 2 dim arrays, the array is considered single channel
	n_chan = n_dims le 2 ? 1 : dims[0]
	;; This is the number of pixels
	n = PRODUCT(dims) / n_chan
	;; Reshape to a vector of pixels
	result = REFORM(in_arr, n_chan, n)
	for i=0L, iter-1 do begin
		;; Find the pixels that need to be replaced
		ind = WHERE(RANDOMU(seed, n, DOUBLE=n gt 1e7) le randomization)
		if ind[0] ne -1 then begin
			;; Replace 'em!
			result[*, ind] = RANDOMU(seed, N_ELEMENTS(ind) * n_chan) * (rmax-rmin) + rmin
		endif
	endfor
	;; Reshape back to original
	result = REFORM(result, dims, /OVERWRITE)
	RETURN, result
end

