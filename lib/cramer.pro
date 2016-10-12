;$Id: //depot/idl/releases/IDL_80/idldir/lib/cramer.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CRAMER
;
; PURPOSE:
;       This function solves an n by n linear system of equations 
;       using Cramer's rule.
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = CRAMER(A, B)
;
; INPUTS:
;       A:      An N by N array of type: float, or double.
;
;       B:      An N-element vector of type: float, or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       ZERO:   Use this keyword to set the value of floating-point
;               zero. A floating-point zero on the main diagonal of
;               a triangular matrix results in a zero determinant.
;               A zero determinant results in a 'Singular matrix'
;               error and stops the execution of CRAMER.PRO.
;               For single-precision inputs, the default value is 
;               1.0e-6. For double-precision inputs, the default value 
;               is 1.0e-12.
;
; EXAMPLE:
;       Define an array (a).
;         a = [[ 2.0,  1.0,  1.0], $
;              [ 4.0, -6.0,  0.0], $
;              [-2.0,  7.0,  2.0]]
;
;       And right-side vector (b).
;         b = [3.0, 10.0, -5.0]
;
;       Compute the solution of the system, ax = b.
;         result = cramer(a, b)
;
; PROCEDURE:
;       CRAMER.PRO uses ratios of column-wise permutations of the array (a)
;       to calculate the solution vector (x) of the linear system, ax = b.
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, February 1994
;       Modified:    GGS, RSI, November 1994
;                    Added support for double precision results.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;-

FUNCTION Cramer, A, B, Double = Double, Zero = Zero

  ON_ERROR, 2  ;Return to caller if error occurs.

  TypeA = SIZE(A)
  TypeB = SIZE(B)

  if TypeA[1] ne TypeA[2] then $
    MESSAGE, "Input array must be square."

  if TypeA[3] ne 4 and TypeA[3] ne 5 then $
    MESSAGE, "Input array must be float or double."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeA[TypeA[0]+1] eq 5 or TypeB[TypeB[0]+1] eq 5) 

  if N_ELEMENTS(Zero) eq 0 and Double eq 0 then $
    Zero = 1.0e-6  ;Single-precision zero.
  if N_ELEMENTS(Zero) eq 0 and Double ne 0 then $
    Zero = 1.0d-12 ;Double-precision zero.

  DetermA = DETERM(A, Double = Double, Zero = Zero, /Check)
  if DetermA eq 0 then MESSAGE, "Input array is singular."

  if Double eq 0 then xOut = FLTARR(TypeA[1]) $ 
  else xOut = DBLARR(TypeA[1])

  for k = 0, TypeA[1]-1 do begin
    ColumnK = A[k,*] ;Save the Kth column of a.
    a[k,*] = B ;Permute the Kth column of A with B.
               ;Solve for the Kth component of the solution xOut
    xOut[k] = DETERM(A, Double = Double, Zero = Zero) / DetermA
    a[k,*] = ColumnK ;Restore A to its original state.
  endfor

  RETURN, xOut

END
