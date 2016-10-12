; $Id: //depot/idl/releases/IDL_80/idldir/lib/trace.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TRACE
;
; PURPOSE:
;       This function computes the trace of an N by N array.
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = TRACE(A)
;
; INPUTS:
;       A:      An N by N real or complex array.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
; EXAMPLE:
;       Define an array, A.
;         A = [[ 2.0,  1.0,  1.0, 1.5], $
;              [ 4.0, -6.0,  0.0, 0.0], $
;              [-2.0,  7.0,  2.0, 2.5], $
;              [ 1.0,  0.5,  0.0, 5.0]]
; 
;       Compute the trace of A.
;         Result = TRACE(A)
;
;       The result should be: 3.00000
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, January 1996
;-

FUNCTION Trace, X, Double = Double

  ON_ERROR, 2

  Sx = SIZE(X) 
  if Sx[0] ne 2 then $
    MESSAGE, "Input array must be 2-dimensional."

  if Sx[1] ne Sx[2] then $
    MESSAGE, "Input array must be square."

  if N_ELEMENTS(Double) eq 0 then $
    Double = (Sx[Sx[0]+1] eq 5) or $
             (Sx[Sx[0]+1] eq 9)

  ;TOTAL(DoubleData, Double = 0) returns a double-precision result. Cast the
  ;result to COMPLEX or FLOAT if Double = 0.
  if Double eq 0 and Sx[Sx[0]+1] eq 9 then RETURN, $
    COMPLEX(TOTAL(X[LINDGEN(Sx[1]) * (Sx[1]+1)], Double = Double)) else $
  if Double eq 0 and Sx[Sx[0]+1] eq 5 then RETURN, $
    FLOAT(TOTAL(X[LINDGEN(Sx[1]) * (Sx[1]+1)], Double = Double)) $
  else RETURN, $
    TOTAL(X[LINDGEN(Sx[1]) * (Sx[1]+1)], Double = Double)

end

