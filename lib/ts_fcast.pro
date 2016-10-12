; $Id: //depot/idl/releases/IDL_80/idldir/lib/ts_fcast.pro#1 $
;
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TS_FCAST
;
; PURPOSE:
;       This function computes future or past values of a stationary time-
;       series (X) using a Pth order autoregressive model. The result is an
;       Nvalues-element vector whose type is identical to X.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = TS_FCAST(X, P, Nvalues)
;
; INPUTS:
;       X:    An n-element vector of type float or double containing time-
;             series samples.
;
;       P:    A scalar of type integer or long integer that specifies the
;             number of actual time-series values to be used in the forecast.
;             In general, a larger number of values results in a more accurate
;             result.
;
; Nvalues:    A scalar of type integer or long integer that specifies the
;             number of future or past values to be computed.
;
; KEYWORD PARAMETERS:
;   BACKCAST: If set to a non-zero value, "backcasts" (backward-forecasts)
;             are computed.
;
;     DOUBLE: If set to a non-zero value, computations are done in
;             double precision arithmetic.
;
; EXAMPLE:
;       Define an n-element vector of time-series samples.
;         x = [6.63, 6.59, 6.46, 6.49, 6.45, 6.41, 6.38, 6.26, 6.09, 5.99, $
;              5.92, 5.93, 5.83, 5.82, 5.95, 5.91, 5.81, 5.64, 5.51, 5.31, $
;              5.36, 5.17, 5.07, 4.97, 5.00, 5.01, 4.85, 4.79, 4.73, 4.76]
;
;       Compute five future and five past values of the time-series using a
;       10th order autoregressive model.
;         resultF = ts_fcast(x, 10, 5)
;         resultB = ts_fcast(x, 10, 5, /backcast)
;
;       The forecast (resultF) should be:
;         [4.65870, 4.58380, 4.50030, 4.48828, 4.46971]
;       The backcast (resultB) should be:
;         [6.94862, 6.91103, 6.86297, 6.77826, 6.70282]
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
;                    Added BACKCAST keyword.
;       Modified:    GGS, RSI, June 1996
;                    Modified keyword checking and use of double precision.
;       Modified: CT, RSI, October 2000: Make loop variables long integers.
;-

FUNCTION TS_Fcast, x, p, Nvalues, Backcast = Backcast, Double = Double, $
                                  Reflect = Reflect

  COMPILE_OPT strictarr
  ;This function uses the last P elements [Xn-1, Xn-2, ... , Xn-p]
  ;of the time-series [x0, x1, ... , xn-1] to compute the forecast.
  ;More coefficients correspond to more past time-series data used
  ;to make the forecast.

  ;REFLECT keyword is not currently supported.

  ON_ERROR, 2

  Nvalues = LONG(Nvalues)

  if Nvalues le 0 then $
    MESSAGE, "Nvalues must be a scalar greater than 0."

  TypeX = SIZE(x)
  nX = TypeX[TypeX[0]+2]

  if p lt 2 or p gt nX-1 then $
    MESSAGE, "p must be a scalar in the interval: [2, N_ELEMENTS(x)-1]."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then Double = (TypeX[TypeX[0]+1] eq 5)

  ;Reverse the time-series for backcasting.
  if KEYWORD_SET(Backcast) ne 0 then x = ROTATE(x,5)

  ;The last p elements of the time-series.
  Data = ROTATE(x[nX-LONG(p):nX-1],5)

  if Double ne 0 then Fcast = DBLARR(Nvalues) $
  else Fcast = FLTARR(Nvalues)

  ;Compute coefficients.
    ARcoeff = TS_COEF(x, LONG(p), Double = Double)

  for j = 0L, Nvalues-1 do begin
    ;;yn = total(Data * ARcoeff, Double = Double)
    ;Data = [yn, Data[0:Nvalues-2]]
    Data = [TOTAL(Data*ARcoeff, Double = Double), Data[0:LONG(p)-2]]
    ;;Data = [yn, Data[0:long(p)-2]]
    Fcast[j] = Data[0]
  endfor

  if KEYWORD_SET(Backcast) ne 0 then begin
    ;Restore the order of the time-series if backcasting.
    x = ROTATE(x,5)
    RETURN, ROTATE(Fcast,5)
  endif else RETURN, Fcast

END



