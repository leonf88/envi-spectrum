;$Id: //depot/idl/releases/IDL_80/idldir/lib/la_determ.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   LA_DETERM
;
; PURPOSE:
;   This function computes the determinant of an N by N array.
;
; CALLING SEQUENCE:
;   Result = LA_DETERM(A)
;
; INPUTS:
;   A: An N by N array of any numeric type. A may be complex.
;
; KEYWORD PARAMETERS:
;   CHECK:  If set to a non-zero value, A is checked for singularity.
;           The determinant of a singular array is returned as zero if
;           this keyword is set. Run-time errors may result if A is
;           singular and this keyword is not set.
;
;   DOUBLE: If set to a non-zero value, computations are done in
;           double precision arithmetic.
;
;   ZERO:   Use this keyword to set the value of floating-point
;           zero. A floating-point zero on the main diagonal of
;           a triangular matrix results in a zero determinant.
;           For single-precision inputs, the default value is
;           1.0e-6. For double-precision inputs, the default value
;           is 1.0e-12.
;
; EXAMPLE:
;       Define an array (a).
;         a = [[ 2.0,  1.0,  1.0], $
;              [ 4.0, -6.0,  0.0], $
;              [-2.0,  7.0,  2.0]]
;       Compute the determinant.
;         result = LA_DETERM(a)
;
; PROCEDURE:
;       LU decomposition is used to represent the input array in
;       triangular form. The determinant is computed as the product
;       of diagonal elements of the triangular form. Row interchanges
;       are tracked during the LU decomposition to ensure the correct
;       sign, + or - .
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
;       Anderson et al., LAPACK Users' Guide, 3rd ed., SIAM, 1999.
;
; MODIFICATION HISTORY:
;       Written by:  CT, RSI, December 2001. Similar to determ.pro but
;            uses LAPACK LA_LUDC for complex input.
;-

FUNCTION la_determ, A, $
    Check = Check, $
    Double = DoubleIn, $
    Zero = ZeroIn

    compile_opt idl2

    ON_ERROR, 2  ;Return to caller if error occurs.

    dims = SIZE(A, /DIMENSION)
    if (N_ELEMENTS(dims) ne 2) then dims = [0,-1]
    if (dims[0] ne dims[1]) then $
        MESSAGE, 'Input must be a square array.'

    type = SIZE(A, /TYPE)
    isComplex = (type eq 6) or (type eq 9)

    ; If the DOUBLE keyword is not set then the internal precision and
    ; result are identical to the type of input.
    Double = (N_ELEMENTS(DoubleIn) gt 0) ? KEYWORD_SET(DoubleIn) : $
        ((type eq 5) or (type eq 9))
    zeroRet = isComplex ? COMPLEX(0, DOUBLE=Double) : (Double ? 0d : 0.0)


    ; If ZERO keyword is not set then use the default zero cutoff.
    Zero = (N_ELEMENTS(ZeroIn) gt 0) ? $
        ABS(ZeroIn[0]) : (Double ? 1d-12 : 1e-6)

    ; Make a copy of the array for its LU decomposition.
    ALUd = A

    ; Compute LU decomposition, either with or without STATUS.
    if KEYWORD_SET(Check) then begin
        LA_LUDC, ALUd, Index, $
            Double = Double, $
            Interchanges = Sign, $
            STATUS=status
        ; Singular matrix? Return zero.
        if (status ne 0) then $
            RETURN, zeroRet
    endif else begin
        ; This will throw an error for a singular matrix.
        LA_LUDC, ALUd, Index, $
            Double = Double, $
            Interchanges = Sign
    endelse

    ; We only need the main diagonal.
    ALUd = DIAG_MATRIX(ALUd)

    ;Are there any zeros on the main diagonal?
    Cnt = TOTAL( ABS(ALUd) le Zero)
    if Cnt ne 0 then $ ;A zero on the main diagonal results in a zero determ.
        RETURN, zeroRet

    Det = PRODUCT(TEMPORARY(ALUd), DOUBLE=Double)

    RETURN, Sign * Det

end

