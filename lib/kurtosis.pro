;$Id: //depot/idl/releases/IDL_80/idldir/lib/kurtosis.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       KURTOSIS
;
; PURPOSE:
;       This function computes the statistical kurtosis of an
;       N-element vector. If the variance of the vector is zero,
;       the kurtosis is not defined, and KURTOSIS returns
;       !VALUES.F_NAN as the result.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = KURTOSIS(X)
;
; INPUTS:
;       X:      An N-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;       DIMENSION: Set this keyword to a scalar indicating the dimension
;         across which to calculate the kurtosis. If this keyword is not
;         present or is zero, then the kurtosis is computed across all
;         dimensions of the input array. If this keyword is present,
;         then the kurtosis is only calculated only across a single dimension.
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
;         result = KURTOSIS(x)
;       The result should be:
;       -1.18258
;
; PROCEDURE:
;       KURTOSIS calls the IDL function MOMENT.
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
FUNCTION KURTOSIS, X, DIMENSION=dim, DOUBLE = Double, NAN = NaN

  compile_opt idl2, hidden
  ON_ERROR, 2

  void = MOMENT( X, DIMENSION=dim, Double=Double, $
    Maxmoment=4, NaN = NaN, KURTOSIS=kurt )
  return, kurt
END
