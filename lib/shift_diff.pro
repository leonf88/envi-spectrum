; $Id: //depot/idl/releases/IDL_80/idldir/lib/shift_diff.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	SHIFT_DIFF
;
; PURPOSE:
;	Apply a shift-difference filter to an image array.
;
; CATEGORY:
;	Image Processing.
;
; CALLING SEQUENCE:
;	Result = SHIFT_DIFF(Array [, /ADD_BACK]
;                             [, DIRECTION=direction]
;                             [, <CONVOL keywords>])
;
; INPUTS:
;	Array = A 2D array of any basic type except string.
;   Keywords:
;     ADD_BACK: Set this keyword to cause the original input array
;               to be added back to the difference array generated
;               by the shift-difference operator.  This is often useful
;               for sharpening the image.
;     DIRECTION: An integer between 0 and 7 to specify the direction of
;                the shift:
;                0 1 2
;                3 x 4
;                5 6 7
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
;	For all other input types, the output type is the same as the input type.
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
;   TVSCL, SHIFT_DIFF(DIST(200), DIRECTION=4)
;   should produce an image with black gradients on the left
;   and white gradients on the right.
;
; MODIFICATION HISTORY:
; 	Sep 2006 - Initial Version
;-
function shift_diff, arr_in, ADD_BACK=add_back, $
                             DIRECTION=direction_in, $
	                         _REF_EXTRA=_extra
	compile_opt idl2
	on_error, 2              ;Return to caller if an error occurs
	CATCH, err               ;Catch so we can identify ourself
	if err ne 0 then begin
		CATCH, /CANCEL
		MESSAGE, !ERROR_STATE.MSG
	endif

	;; Set up kernel, based on direction
	if N_ELEMENTS(direction_in) gt 0 then begin
		direction = (direction_in > 0) < 7
		index = direction gt 3 ? direction + 1 : direction
	endif else $
		index = 0
	kernel = INTARR(3,3)
	kernel[4] = 1
	kernel[index] = -1

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

	result = CONVOL(TEMPORARY(arr), kernel, _STRICT_EXTRA=_extra)

	;; Add back original data if requested
	if KEYWORD_SET(add_back) then begin

		result += arr_in

		;; Clip and convert back to original type.
    	case type of
        	1: clip = [0, 255]
        	2: clip = [-32768, 32767]
        	12: clip = [0, 65535u]
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

