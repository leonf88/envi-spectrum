; $Id: //depot/idl/releases/IDL_80/idldir/lib/ts_smooth.pro#1 $
;
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TS_SMOOTH
;
; PURPOSE:
;       This function computes central, backward or forward moving-averages
;       of an n-element time-series (X). Autoregressive forecasting and
;       backcasting is used to extrapolate the time-series and compute a
;       moving-average for each point of the time-series. The result is an
;       n-element vector whose type is identical to X.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = TS_SMOOTH(X, Nvalues)
;
; INPUTS:
;       X:    An n-element vector of type float or double containing time-
;             series samples, where n >= 11.
;
; Nvalues:    A scalar of type integer or long integer that specifies the
;             number of time-series values used to compute each moving-average.
;             If central-moving-averages are computed (the default), this
;             parameter must be an odd integer of 3 or greater.
;
; KEYWORD PARAMETERS:
;   BACKWARD: If set to a non-zero value, backward-moving-averages are
;             computed. The Nvalues parameter must be an integer greater
;             than 1.
;
;     DOUBLE: If set to a non-zero value, computations are done in
;             double precision arithmetic.
;
;    FORWARD: If set to a non-zero value, forward-moving-averages are computed.
;             The Nvalues parameter must be an integer greater than 1.
;
;      ORDER: A scalar of type integer or long integer that specifies
;             the order of the autoregressive model used to compute the
;             forecasts and backcasts of the time-series. Central-moving-
;             averages require Nvalues/2 forecasts and Nvalues/2 backcasts.
;             Backward-moving-averages require Nvalues-1 backcasts.
;             Forward-moving-averages require Nvalues-1 forecasts.
;             A time-series with a length in the interval [11, 219] will use
;             an autoregressive model with an order of 10. A time-series with
;             a length greater than 219 will use an autoregressive model with
;             an order equal to 5% of its length. The ORDER keyword is used to
;             override this default.
;
; EXAMPLE:
;       Define an n-element vector of time-series samples.
;         x = [6.63, 6.59, 6.46, 6.49, 6.45, 6.41, 6.38, 6.26, 6.09, 5.99, $
;              5.92, 5.93, 5.83, 5.82, 5.95, 5.91, 5.81, 5.64, 5.51, 5.31, $
;              5.36, 5.17, 5.07, 4.97, 5.00, 5.01, 4.85, 4.79, 4.73, 4.76]
;
;       Compute the 11-point central-moving-averages of the time-series.
;         result = ts_smooth(x, 11)
;
; REFERENCE:
;       The Analysis of Time Series, An Introduction (Fourth Edition)
;       Chapman and Hall
;       ISBN 0-412-31820-2
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, September 1995
;       Modified:    GGS, RSI, July 1996
;                    Modified keyword checking and use of Double precision.
;       Modified: CT, RSI, October 2000: Make loop variables long integers.
;-

FUNCTION TS_Smooth, x, Nvalues, Backward = Backward, Double = Double, $
                                Forward = Forward, NaN = NaN, Order = Order

  COMPILE_OPT strictarr
  ON_ERROR, 2

  TypeX = SIZE(x)
  nX = TypeX[TypeX[0]+2]

  ;Check time-series length.
  if nX lt 11 then $
    MESSAGE, "Time-series input must be a vector of at least 11 elements."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then Double = (TypeX[TypeX[0]+1] eq 5)

  ;Define output type.
  if Double eq 0 then SMx = FLTARR(nX) else SMx = DBLARR(nX)

  ;Order of Autoregressive model.
  ;A time-series with a length in the interval [11, 219] will use an
  ;Autoregressive model with an Order of 10. A time-series with a length
  ;greater than 219 will use an Autoregressive model with an Order equal
  ;to 5% of its length. The ORDER keyword is used to override this default.
  if KEYWORD_SET(Order) eq 0 then $
    Order = MAX([10L, LONG(0.05 * nX)])

  if KEYWORD_SET(Backward) ne 0 then begin
    ;Compute Backward-moving-averages.
    if Nvalues lt 2 then MESSAGE, $ ;Nvalues must be 2 or greater.
      "Backward average; Nvalues must be an integer greater than 1."
    ;Requires (Nvalues-1) backcasted values.
    x = [TS_FCAST(x, Order, Nvalues-1, /BACKCAST, Double = Double), x]
    for k = 0L, nX-1 do $
      SMx[k] = TOTAL(x[k:Nvalues+(k-1)], Double = Double)
    ;Restore x to its input state.
    if TypeX[TypeX[0]+1] eq 4 then x = FLOAT(x[Nvalues-1:*]) $
    else x = DOUBLE(x[Nvalues-1:*])
    RETURN, SMx/Nvalues
  endif else if KEYWORD_SET(Forward) ne 0 then begin
    ;Compute Forward-moving-averages.
    if Nvalues lt 2 then MESSAGE, $ ;Nvalues must be 2 or greater.
      "Forward average; Nvalues must be an integer greater than 1."
    ;Requires (Nvalues-1) forecasted values.
    x = [x, TS_FCAST(x, Order, Nvalues-1, Double = Double)]
    for k = 0L, nX-1 do $
      SMx[k] = TOTAL(x[k:Nvalues+(k-1)], Double = Double)
    ;Restore x to its input state.
    if TypeX[TypeX[0]+1] eq 4 then x = FLOAT(x[0:nX-1]) $
    else x = DOUBLE(x[0:nX-1])
    RETURN, SMx/Nvalues
  endif else begin
    ;Compute central-moving-averages.
    if Nvalues lt 3 then MESSAGE, $ ;Nvalues must be odd and 3 or greater.
      "Central average; Nvalues must be an odd integer greater than 2."
    if LONG(Nvalues) MOD 2 eq 0 then SMwidth = LONG(Nvalues) + 1 $
    else SMwidth = LONG(Nvalues)
    ;Requires (Nvalues/2) forecasted values and (Nvalues/2) backcasted values;
    ;where Nvalues is an odd integer.
    x = [TS_FCAST(x, Order, SMwidth/2, /BACKCAST, Double = Double), x, $
         TS_FCAST(x, Order, SMwidth/2, Double = Double)]
    for k = 0L, nX-1 do $
      SMx[k] = TOTAL(x[k:SMwidth+(k-1)], Double = Double)
    ;Restore x to its input state.
    if TypeX[TypeX[0]+1] eq 4 then x = FLOAT(x[SMwidth/2:SMwidth/2+(nX-1)]) $
    else x = DOUBLE(x[SMwidth/2:SMwidth/2+(nX-1)])
    RETURN, SMx/SMwidth
    ;SMx = smooth(ts, SMwidth) & SMx = SMx[SMwidth/2:SMwidth/2+nX-1]
  endelse

END
