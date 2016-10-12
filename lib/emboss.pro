; $Id: //depot/idl/releases/IDL_80/idldir/lib/emboss.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	EMBOSS
;
; PURPOSE:
;	Apply an emboss convolution to an image array.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = EMBOSS(Array [, /ADD_BACK]
;                         [, AZIMUTH=azimuth]
;                         [, <CONVOL keywords>])
;
; INPUTS:
;	Array = A 2D array of any basic type except string.
;   Keywords:
;     ADD_BACK: Set this keyword to cause the original input array
;               to be added back to the difference array generated
;               by the emboss convolution.  This is often useful
;               for viewing the final image.
;     AZIMUTH: Set this keyword to a scalar value to approximate the
;              angular position (in degrees) of the "light source"
;              used to create the embossing effect.  The default is
;              0 degrees, which specifies that the light is coming
;              from the right.  The angular position increases in
;              a counter-clockwise direction.
;
;     This procedure also accepts all keywords accepted by CONVOL.
;     The scale_factor argument to CONVOL is left at it's default
;     value to 1 since the kernel needs no scaling.
;
; OUTPUTS:
;   If the ADD_BACK keyword is set, the function returns an array of
;   the same type and dimensions as the input array.
;
;	If the ADD_BACK keyword is not set, the function returns an array
;   of the same dimensions as the input array, but with a type described
;	as follows:
;		BYTE --> INT
;		INT --> LONG
;		UINT --> LONG
;		ULONG --> LONG64
;		ULONG64 --> LONG64
;		For all other input types, the output type is the same as the input type.
;
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	Calls the CONVOL function with the appropriate kernel.  See the
;   CONVOL function for information on the treatment of edge pixels.
;
; EXAMPLE CALLING SEQUENCE:
;	file = FILEPATH('mineral.png', SUBDIR=['examples','data'])
;	READ_PNG, file, image
;	iImage, image, VIEW_GRID=[2,1], DIMENSIONS=[288,216]
;	result = EMBOSS(image, /ADD_BACK, AZIMUTH=225)
;	iImage, result, /VIEW_NEXT
;
; MODIFICATION HISTORY:
; 	Oct 2006 - Initial Version
;-
function emboss, arr_in, ADD_BACK=add_back, $
                         AZIMUTH=azimuth, $
                         _REF_EXTRA=_extra
	compile_opt idl2
	on_error, 2              ;Return to caller if an error occurs

	CATCH, err               ;Catch so we can identify ourself
	if err ne 0 then begin
		CATCH, /CANCEL
		MESSAGE, !ERROR_STATE.MSG
	endif

	if N_ELEMENTS(azimuth) eq 0 then $
		azimuth = 0

	;; Set up kernel
	;;
	;; Start with the 8 "outside" values that represent
	;; the kernel for an azimuth value of zero.  That is,
	;; the light is coming from the right.
	;;
	;;    1   0   -1
	;;    1   X   -1
	;;    1   0   -1
	;;
	;; Place in 1D array, starting at upper-right and going CW.
	kernel = [-1,-1,-1,0,1,1,1,0]
	;; Rotate this vector by the supplied azimuth
	shft = (azimuth MOD 360) / 360. * 8
	kernel = SHIFT(kernel, FIX(shft))
	;; Use the fractional leftover to linearly interpolate
	;; the remainder of the azimuth value.
	frac = shft - FIX(shft)
	kernel = (1. - frac) * kernel + frac * SHIFT(kernel, 1)
	;; Bend the vector around to make a 3x3 kernel
	kernel = REFORM(kernel[[6,7,0,5,0,1,4,3,2]], 3, 3)
	;; Fixup middle value that was not in the 1D vector.
	kernel[1,1] = 0

    ;; Use a larger, signed integer type.
    type = SIZE(arr_in, /TYPE)
    case type of
        1: calctype = 2    ; byte --> int
        2: calctype = 3    ; int --> long
        12: calctype = 3   ; uint --> long
        13: calctype = 14  ; ulong --> long64
        15: calctype = 14  ; ulong64 --> long64
        else: calctype = type
    endcase
	arr = FIX(arr_in, TYPE=calctype)

	;; Apply operator
	result = CONVOL(TEMPORARY(arr), kernel, _STRICT_EXTRA=_extra)

	;; Add back original data if requested
	if KEYWORD_SET(add_back) then begin

		result += arr_in

		;; Clip and convert back to original type.
    	case type of
        	1: clip = [0, 255]
        	2: clip = [-32768, 32767]
        	12: clip = [0, 65535U]
        	13: clip = [0, 4294967295UL]
        	15: clip = [0, 9223372036854775807ULL]
        	else: ; no clipping needed
    	endcase

    	if (N_ELEMENTS(clip) gt 0) then begin
        	mn = MIN(result, MAX=mx)
        	if (mn lt clip[0]) then result >= clip[0]
        	if (mx gt clip[1]) then result <= clip[1]
    	endif

		result = FIX(result, TYPE=type)
	endif

	return, result
end

