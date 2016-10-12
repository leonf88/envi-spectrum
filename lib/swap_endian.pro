; $Id: //depot/idl/releases/IDL_80/idldir/lib/swap_endian.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	SWAP_ENDIAN
;
; PURPOSE:
;	This function reverses the byte ordering of arbitrary scalars,
;	arrays or structures. It may be used, for example, to make little
;	endian numbers big, or big endian numbers little.
;
; CATEGORY:
;	Utility.
;
; CALLING SEQUENCE:
;	Result = SWAP_ENDIAN(A)
;
; INPUTS:
;	A:	The scalar, array, or structure to be swapped.
;
; KEYWORDS:
;	SWAP_IF_BIG_ENDIAN
;	If this keyword is set, the swap request will only be
;	performed if the platform running IDL uses "big endian"
;	byte ordering. On little endian machines, the SWAP_ENDIAN_INPLACE
;	request quietly returns without doing anything. Note that this keyword
;	does not refer to the byte ordering of the input data, but to the
;	computer hardware.
;
;	SWAP_IF_LITTLE_ENDIAN
;	If this keyword is set, the swap request will only be
;	performed if the platform running IDL uses "little endian"
;	byte ordering. On big endian machines, the SWAP_ENDIAN_INPLACE
;	request quietly returns without doing anything. Note that this keyword
;	does not refer to the byte ordering of the input data, but to the
;	computer hardware.
;
; OUTPUTS:
;	Result:	The same type and structure as the input, with the
;		pertinent bytes reversed.
;
; RESTRICTIONS:
;	Always makes a copy of the input data. If your data is large
;	enough for this to be a problem, and you don't require a separate
;	copy, the SWAP_ENDIAN_INPLACE procedure is recommended.
;
;	Structures are handled correctly, but are not as efficient as
;	simple types.
;
; PROCEDURE:
;	Swap arrays and scalars directly using BYTEORDER.
;	Swap structures recursively.
;
; EXAMPLE:
;	A = SWAP_ENDIAN(A)  ;Reverses the "endianness" of A
;
; MODIFICATION HISTORY:
;	DMS, RSI, May, 1993.	Written.
;	DMS, RSI, July, 1993.   Added double complex.
;	AB, RSI, 5 October 1998, Fixed double complex case and updated for
;		pointer, object reference, unsigned 16, 32, and 64-bit
;		integers, and 64-bit signed integers.
;	AB, RSI, 2 October 2001, Added the SWAP_IF_[BIG|LITTLE]_ENDIAN
;		keywords.
;-

function SWAP_ENDIAN, in, SWAP_IF_BIG_ENDIAN=sw_big, $
	SWAP_IF_LITTLE_ENDIAN=sw_little

  t = in			;Make a copy
  case (size(t, /TYPE)) of
    1: return, t			; BYTES require no swapping.
    2: BYTEORDER, t, /SSWAP, $		; 16-bit signed integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    3: BYTEORDER, t, /LSWAP, $		; 32-bit signed long integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    4: BYTEORDER, t, /LSWAP, $		; Single floats
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    5: BYTEORDER, t, /L64SWAP, $		; Double floats
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    6: BYTEORDER, t, /LSWAP, $		; Single complex
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    7: return, t			; Strings require no swapping
    8: begin
	  if (byte(1L, 0, 1) eq 1) then begin	; Little endian host
	    if (keyword_set(sw_big)) then return, t
	  endif else begin			; Big endian host
	    if (keyword_set(sw_little)) then return, t
	  endelse

	 for i=0, n_tags(t)-1 do begin	; Handle structures recursively.
    	   temp = swap_endian(t.(i))
    	   t.(i) = temp
         endfor
       end
    9: BYTEORDER, t, /L64SWAP, $		; Double complex.
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    10: MESSAGE, 'Unable to swap pointer data type'
    11: MESSAGE, 'Unable to swap object reference data type'
    12: BYTEORDER, t, /SSWAP, $		; Unsigned shorts
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    13: BYTEORDER, t, /LSWAP, $		; Unsigned Longs
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    14: BYTEORDER, t, /L64SWAP, $		; Signed 64-bit integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    15: BYTEORDER, t, /L64SWAP, $		; Unsigned 64-bit integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    else: MESSAGE, 'Internal error: unknown type'
  endcase

  return, t
end

