; $Id: //depot/idl/releases/IDL_80/idldir/lib/crvlength.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CRVLENGTH
;
; PURPOSE:
;       This function computes the length of a curve with a tabular
;       representation, y(i) = F(x(i)). 
;
; CATEGORY:
;       Numerical Analysis
;
; CALLING SEQUENCE:
;       Result = Crvlength(X, Y)
;
; INPUTS:
;       X:    An N-element vector (N >= 3) of type float or double. These 
;             values must be specified in ascending order. Duplicate x values 
;             will result in a warning message.
;
;       Y:    An N-element vector of type float or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE:  If set to a non-zero value, computations are done in
;                double precision arithmetic.
;
; RESTRICTIONS:
;       Data that is highly oscillatory requires a sufficient number
;       of samples for an accurate curve length computation.
;
; EXAMPLE:
;       Define a 21-element vector of X-values.
;         x = [-2.00, -1.50, -1.00, -0.50, 0.00, 0.50, 1.00, 1.50, 2.00, $
;               2.50,  3.00,  3.50,  4.00, 4.50, 5.00, 5.50, 6.00, 6.50, $
;               7.00,  7.50,  8.00]
;       Define a 21-element vector of Y-values.
;         y = [-2.99, -2.37, -1.64, -0.84, 0.00, 0.84, 1.64, 2.37, 2.99, $
;               3.48,  3.86,  4.14,  4.33, 4.49, 4.65, 4.85, 5.13, 5.51, $
;               6.02,  6.64,  7.37]
;       Compute the length of the curve.
;         result = CRVLENGTH(x, y)
;       The result should be:
;         14.8115
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, March 1996
;-

FUNCTION CrvLength, X, Y, Double = Double

  ON_ERROR, 2

  TypeX = SIZE(X)
  TypeY = SIZE(Y)

  ;Check Y data type.
  if TypeY[TypeY[0]+1] ne 4 and TypeY[TypeY[0]+1] ne 5 then $
    MESSAGE, "Y values must be float or double."

  ;Check length.
  if TypeX[TypeX[0]+2] lt 3 then $
    MESSAGE, "X and Y arrays must contain 3 or more elements."
  if TypeX[TypeX[0]+2] ne TypeY[TypeY[0]+2] then $
    MESSAGE, "X and Y arrays must have the same number of elements."

  ;Check duplicate values.
  if TypeX[TypeX[0]+2] ne N_ELEMENTS(UNIQ(X)) then $
    MESSAGE, "X array contains duplicate points."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeX[TypeX[0]+1] eq 5 or TypeY[TypeY[0]+1] eq 5) 

  nX = TypeX[TypeX[0]+2]
  Yprime = (SHIFT(Y,-1) - SHIFT(Y,1)) / (SHIFT(x,-1) - SHIFT(x,1) + 0.0)
  Yprime[0] = (-3.0*Y[0] + 4.0*Y[1] - Y[2]) / (x[2] - x[0])
  Yprime[nX-1] = (3.0*Y[nX-1] - 4.0*Y[nX-2] + Y[nX-3]) / (x[nX-1] - x[nX-3])

  RETURN, INT_TABULATED(X, SQRT(1 + Yprime^2), Double = Double)

END
