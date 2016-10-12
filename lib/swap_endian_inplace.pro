; $Id: //depot/idl/releases/IDL_80/idldir/lib/swap_endian_inplace.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	SWAP_ENDIAN_INPLACE
;
; PURPOSE:
;	This function reverses the byte ordering of arbitrary scalars,
;	arrays or structures. It may be used, for example, to make little
;	endian numbers big, or big endian numbers little. It alters the
;	input data in place rather than making a copy as the SWAP_ENDIAN
;	function does.
;
; CATEGORY:
;	Utility.
;
; CALLING SEQUENCE:
;	SWAP_ENDIAN_INPLACE, A
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
;	The data in A has its pertinent bytes reversed.
;
; RESTRICTIONS:
;	Structures are handled correctly, but are not as efficient as
;	simple types.
;
; PROCEDURE:
;	Swap arrays and scalars directly using BYTEORDER.
;	Swap structures recursively.
;
; EXAMPLE:
;	SWAP_ENDIAN_INPLACE, A  ;Reverses the "endianness" of A
;
; MODIFICATION HISTORY:
;	AB, RSI, 2 October 2001, Written. This routine is based on
;		SWAP_ENDIAN, but performs the swapping on the input
;		rather than on a copy. Since no copy is involved,
;		it is efficient to support the SWAP_IF_[BIG|LITTLE]_ENDIAN
;		keywords, which is not necessarily the case with SWAP_ENDIAN.
;-

pro SWAP_ENDIAN_INPLACE, in, SWAP_IF_BIG_ENDIAN=sw_big, $
	SWAP_IF_LITTLE_ENDIAN=sw_little

  case (size(in, /TYPE)) of
    1:  return				; BYTES require no swapping.
    2:  BYTEORDER, in, /SSWAP, $	; 16-bit signed integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    3:  BYTEORDER, in, /LSWAP, $   	; 32-bit signed long integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    4:  BYTEORDER, in, /LSWAP, $   	; Single floats
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    5:  BYTEORDER, in, /L64SWAP, $ 	; Double floats
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    6:  BYTEORDER, in, /LSWAP, $   	; Single complex
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    7:  return				; Strings require no swapping
    8:  begin				; Handle structures recursively.
	  if (byte(1L, 0, 1) eq 1) then begin	; Little endian host
	    if (keyword_set(sw_big)) then return
	  endif else begin			; Big endian host
	    if (keyword_set(sw_little)) then return
	  endelse

	  for i=0, n_tags(in)-1 do begin
    	    temp = in.(i)
    	    SWAP_ENDIAN_INPLACE, temp
    	    in.(i) = temp
          endfor
        end
    9:  BYTEORDER, in, /L64SWAP, $	; Double complex.
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    10: MESSAGE, 'Unable to swap pointer data type'
    11: MESSAGE, 'Unable to swap object reference data type'
    12: BYTEORDER, in, /SSWAP, $   	; Unsigned shorts
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    13: BYTEORDER, in, /LSWAP, $   	; Unsigned Longs
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    14: BYTEORDER, in, /L64SWAP, $ 	; Signed 64-bit integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    15: BYTEORDER, in, /L64SWAP, $ 	; Unsigned 64-bit integers
	    SWAP_IF_BIG_ENDIAN=sw_big, SWAP_IF_LITTLE_ENDIAN=sw_little
    else: MESSAGE, 'Internal error: unknown type'
  endcase

end

