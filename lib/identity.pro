; $Id: //depot/idl/releases/IDL_80/idldir/lib/identity.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       IDENTITY
;
; PURPOSE:
;       This function returns an N by N identity array, an array with
;       ones along the main diagonal and zeros elsewhere.
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = IDENTITY(N)
;
; INPUTS:
;       N:      The desired column and row dimensions.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, a double precision identity array
;               is returned.
;
; EXAMPLE:
;       Define an array, A.
;         A = [[ 2.0,  1.0,  1.0, 1.5], $
;              [ 4.0, -6.0,  0.0, 0.0], $
;              [-2.0,  7.0,  2.0, 2.5], $
;              [ 1.0,  0.5,  0.0, 5.0]]
; 
;       Compute the inverse of A using the INVERT function.
;         Inverse = INVERT(A)
;
;       Verify the accuracy of the computed inverse using the mathematical
;       identity, A x A^-1 - I(4) = 0; where A^-1 is the inverse of A, I(4)
;       is the 4 by 4 identity array and 0 is a 4 by 4 array of zeros.
;         PRINT, A ## Inverse - IDENTITY(4)
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, January 1996
;-

FUNCTION Identity, N, Double = Double
  compile_opt idl2, hidden

  ON_ERROR, 2
  if N le 0 then MESSAGE, "N parameter must be greater than 0."

  if KEYWORD_SET(Double) eq 0 then begin
    Array = FLTARR(N, N) 
    Array[LINDGEN(N) * (N+1)] = 1.0
  endif else begin
    Array = DBLARR(N, N)
    Array[LINDGEN(N) * (N+1)] = 1.0d
  endelse

  RETURN, Array
end
