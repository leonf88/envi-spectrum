;$Id: //depot/idl/releases/IDL_80/idldir/lib/variance.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       VARIANCE
;
; PURPOSE:
;       This function computes the statistical variance of an
;       N-element vector. 
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = variance(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DIMENSION: Set this keyword to a scalar indicating the dimension
;         across which to calculate the variance. If this keyword is not
;         present or is zero, then the variance is computed across all
;         dimensions of the input array. If this keyword is present,
;         then the variance is only calculated only across a single dimension.
;         In this case the result is an array with one less dimension
;         than the input.
;       DOUBLE: IF set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;       NAN:    If set, treat NaN data as missing.
;
; EXAMPLE:
;       Define the N-element vector of sample data.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71, 66, 65, 70]
;       Compute the mean.
;         result = variance(x)
;       The result should be:
;       7.06667
;
; PROCEDURE:
;       VARIANCE calls the IDL function MOMENT.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GSL, RSI, August 1997
;       CT, Dec 2009: (from J. Bailin) Added DIMENSION keyword.
;-
FUNCTION variance, X, DIMENSION=dim, DOUBLE = Double, NAN = NaN

  compile_opt idl2, hidden
  ON_ERROR, 2

  void = MOMENT( X, DIMENSION=dim, Double=Double, $
    Maxmoment=2, NaN = NaN, VARIANCE=variance )
  return, variance
END
