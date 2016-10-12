; $Id: //depot/idl/releases/IDL_80/idldir/lib/ts_coef.pro#1 $
;
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TS_COEF
;
; PURPOSE:
;       This function computes the coefficients used in a Pth order
;       autoregressive time-series forecasting/backcasting model. The
;       result is a P-element vector whose type is identical to X.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = TS_COEF(X, P)
;
; INPUTS:
;       X:    An n-element vector of type float or double containing time-
;             series samples.
;
;       P:    A scalar of type integer or long integer that specifies the
;             number of coefficients to be computed.
;
; KEYWORD PARAMETERS:
;  DOUBLE:    If set to a non-zero value, computations are done in double
;             precision arithmetic.
;
;     MSE:    Use this keyword to specify a named variable which returns the
;             mean square error of the Pth order autoregressive model.
;
; EXAMPLE:
;       Define an n-element vector of time-series samples.
;         x = [6.63, 6.59, 6.46, 6.49, 6.45, 6.41, 6.38, 6.26, 6.09, 5.99, $
;              5.92, 5.93, 5.83, 5.82, 5.95, 5.91, 5.81, 5.64, 5.51, 5.31, $
;              5.36, 5.17, 5.07, 4.97, 5.00, 5.01, 4.85, 4.79, 4.73, 4.76]
;
;       Compute the coefficients of a 5th order autoregressive model.
;         result = TS_COEF(x, 5)
;
;       The result should be:
;         [1.30168, -0.111783, -0.224527. 0.267629, -0.233363]
;
; REFERENCE:
;       The Analysis of Time Series, An Introduction (Fourth Edition)
;       Chapman and Hall
;       ISBN 0-412-31820-2
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, November 1994
;       Modified:    GGS, RSI, January 1996
;                    Added DOUBLE keyword.
;       Modified:    GGS, RSI, June 1996
;                    Replaced nested FOR loop with vector ops.
;                    Faster execution for values of P > 100.
;       Modified: CT, RSI, October 2000: Make loop variables long integers.
;-

FUNCTION TS_Coef, x, p, MSE = MSE, Double = Double

  COMPILE_OPT strictarr
  ;Compute the coefficients of the Pth order autoregressive model
  ;used in time-series forecasting/backcasting.
  ;ARcoef = ARcoef[0, 1, ... , p-1]

  ON_ERROR, 2

  TypeX = SIZE(x)
  nX = TypeX[TypeX[0]+2]

  if p lt 2 or p gt nX-1 then $
    MESSAGE, "p must be a scalar in the interval: [2, N_ELEMENTS(x)-1]."

  if KEYWORD_SET(Double) eq 0 then Double = 0

  MSE = TOTAL(x^2, Double = Double) / nX

  ;Do all intermediate calculations in double-precision.
  ARcoef = DBLARR(p)
  str1 = [0.0d, x[0:nX-2], 0.0d]
  str2 = [0.0d, x[1:nX-1], 0.0d]
  str3 = DBLARR(nX+1)

  for k = 1, p do begin
    ARcoef[k-1] = 2.0d * TOTAL(str1[1:nX-k] * str2[1:nX-k], /DOUBLE) / $
                     TOTAL(str1[1:nX-k]^2 + str2[1:nX-k]^2, /DOUBLE)
    MSE = MSE * (1.0d - ARcoef[k-1]^2)

    if k gt 1 then begin
      i = LINDGEN(k-1) + 1
      ARcoef[i-1] = str3[i] - (ARcoef[k-1] * str3[k-i])
    endif

    ;if k = p then skip the remaining computations.
    if k eq p then goto, return_ARcoef

    str3[1:k] = ARcoef[0:k-1]
    for j = 1L, nX-k-1 do begin
      str1[j] = str1[j] - str3[k] * str2[j]
      str2[j] = str2[j+1] - str3[k] * str1[j+1]
    endfor
  endfor

  return_ARcoef:

  if TypeX[TypeX[0]+1] eq 5 and KEYWORD_SET(Double) eq 0 then $
    RETURN, FLOAT(ARcoef) else $
  if TypeX[TypeX[0]+1] eq 5 or KEYWORD_SET(Double) ne 0 then $
    RETURN, ARcoef else RETURN, FLOAT(ARcoef)

END

