; $Id: //depot/idl/releases/IDL_80/idldir/lib/noise_scatter.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	NOISE_SCATTER
;
; PURPOSE:
;	Introduce noise into an image by apply normally distributed
;   noise to the entire image.  In the normal distribution, a
;   large number of pixels will have smaller amounts of noise
;   applied to them, while fewer pixels will have larger amounts
;   of noise applied to them.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = NOISE_SCATTER(Image [, <keywords>])
;
; INPUTS:
;	Image: A 2D or 3D array of any basic type containing the input image.
;          2D arrays are treated as single channel images.
;          For 3D arrays, the first dimension contains the
;          color channels (Pixel Interleave)
;
; KEYWORDS:
;   CORRELATED_NOISE: If this keyword is set to a non-zero value,
;                     the same noise distribution is applied to
;                     all channels of the image.  Otherwise, a new
;                     noise distribution is generated for each channel.
;
;   LEVELS: A n-element array containing noise scale factors for each
;           image channel where n is 1 for a 2D array (1-channel image) or
;           the number of channels in the first dimension of a 3D array.
;           Valid values are in the range [0.0, 1.0] and
;           this function clamps incoming values to this range.  If the
;           levels are not specified, this function uses 0.5 for each channel.
;
;   NOISE_FACTOR: A scalar noise scale factor applied to all channels.
;                 A typical value for this keyword is half the range of
;                 the image data.  The default value is 127, which is
;                 suitable for BYTE images.
;
;   SEED: The seed value for the random number generator. This keyword is used in the
;         same way as the SEED argument for RANDOMN.
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
;	The following sequence will introduce noise to a test image.
;
;	fn = FILEPATH('rose.jpg', SUBDIR=['examples','data'])
;   READ_JPEG, fn, image
;	result = NOISE_SCATTER(image)
;	tv, result, /true
;
; MODIFICATION HISTORY:
; 	Nov 2006 - Initial Version
;-

function noise_scatter, in_arr, $
						CORRELATED_NOISE=correl, $
						LEVELS=levels, $
						NOISE_FACTOR=factor, $
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

	;; Figure out the number of channels in a pixel.
	;; For 2 dim arrays, the array is considered single channel
	n_chan = n_dims eq 2 ? 1 : dims[0]
	noise_dims = dims[n_dims-2:n_dims-1]

	;; Process keywords
	correl = KEYWORD_SET(correl)
	if N_ELEMENTS(levels) eq 0 then $
		levels = FLTARR(n_chan) + 0.5 $
	else if N_ELEMENTS(levels) ne n_dims then $
		MESSAGE, 'Levels must have the same number of elements as image channels'
	levels = (levels < 1.0) > 0.0
	factor = N_ELEMENTS(factor) gt 0 ? factor[0] : 127b

	result = in_arr
	if factor eq 0 then return, result
	for chan=0, n_chan-1 do begin
		;; Compute noise for first iteration or if we need a different
		;; set of noise values for each channel
		if chan eq 0 or correl eq 0 then $
			noise = RANDOMN(seed, noise_dims[0], noise_dims[1])
		;; No noise to add for this channel
		if levels[chan] eq 0 then continue
		if n_dims eq 2 then $
			result= ((result + noise * levels[chan] * factor) < 255) > 0 $
		else $
			result[chan,0,0] = $
				((result[chan,*,*] + noise * levels[chan] * factor) < 255) > 0
	endfor

	RETURN, result
end

