;$Id: //depot/idl/releases/IDL_80/idldir/lib/determ.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       DETERM
;
; PURPOSE:
;       This function computes the determinant of an N by N array.
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = DETERM(A)
;
; INPUTS:
;       A:      An N by N array of type: float, or double.
;
; KEYWORD PARAMETERS:
;       CHECK:  If set to a non-zero value, A is checked for singularity.
;               The determinant of a singular array is returned as zero if
;               this keyword is set. Run-time errors may result if A is
;               singular and this keyword is not set.
;
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       ZERO:   Use this keyword to set the value of floating-point
;               zero. A floating-point zero on the main diagonal of
;               a triangular matrix results in a zero determinant.
;               For single-precision inputs, the default value is
;               1.0e-6. For double-precision inputs, the default value
;               is 1.0e-12.
;
; EXAMPLE:
;       Define an array (a).
;         a = [[ 2.0,  1.0,  1.0], $
;              [ 4.0, -6.0,  0.0], $
;              [-2.0,  7.0,  2.0]]
;       Compute the determinant.
;         result = determ(a)
;       Note:
;            See CRAMER.PRO, in the same directory as this file, for
;            an application of the determinant function.
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
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, February 1994
;       Modified:    GGS, RSI, November 1994
;                    Added CHECK keyword to check for singular arrays.
;                    Changed NR_LUDCMP to LUDC.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;-

FUNCTION Determ, A, Check = Check, Double = Double, Zero = Zero

  ON_ERROR, 2  ;Return to caller if error occurs.

  dims = SIZE(A, /DIMENSION)
  if (N_ELEMENTS(dims) ne 2) then dims = [0,-1]
  if (dims[0] ne dims[1]) then $
    MESSAGE, "Input array must be square."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  Double = (N_ELEMENTS(Double) gt 0) ? KEYWORD_SET(Double) : $
	(SIZE(A, /TYPE) eq 5)

  if N_ELEMENTS(Zero) eq 0 and Double eq 0 then $
    Zero = 1.0e-6  ;Single-precision zero.
  if N_ELEMENTS(Zero) eq 0 and Double ne 0 then $
    Zero = 1.0d-12 ;Double-precision zero.

  if keyword_set(Check) then $ ;Return a determinant of zero?
    if COND(A, Double = Double) eq -1 then $
      if Double eq 0 then RETURN, 0.0 else RETURN, 0.0d

  ;Make a copy of the array for its LU decomposition.
  ALUd = Double ? DOUBLE(A) : FLOAT(A)

  ;Compute LU decomposition.
  LUDC, ALUd, Index, Double = Double, Interchanges = Sign

  ;Are there any zeros on the main diagonal?
  ii = WHERE( ABS( ALUd[LINDGEN(dims[0])*(dims[0]+1)] ) le Zero, Cnt)

  Det = 1 ;Initialize determinant.

  if Cnt ne 0 then $ ;A zero on the main diagonal results in a zero determ.
    if Double eq 0 then RETURN, 0.0 else RETURN, 0.0d $
  else begin
    FOR k = 0, dims[0]-1 do $
      Det = Det * ALUd[k,k]
    RETURN, Sign * Det
  endelse

END
