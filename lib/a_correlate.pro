; $Id: //depot/idl/releases/IDL_80/idldir/lib/a_correlate.pro#1 $
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       A_CORRELATE
;
; PURPOSE:
;       This function computes the autocorrelation Px(L) or autocovariance
;       Rx(L) of a sample population X as a function of the lag (L).
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = A_correlate(X, Lag)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double.
;
;     LAG:    A scalar or n-element vector, in the interval [-(n-2), (n-2)],
;             of type integer that specifies the absolute distance(s) between
;             indexed elements of X.
;
; KEYWORD PARAMETERS:
;       COVARIANCE:    If set to a non-zero value, the sample autocovariance
;                      is computed.
;
;       DOUBLE:        If set to a non-zero value, computations are done in
;                      double precision arithmetic.
;
; EXAMPLE
;       Define an n-element sample population.
;         x = [3.73, 3.67, 3.77, 3.83, 4.67, 5.87, 6.70, 6.97, 6.40, 5.57]
;
;       Compute the autocorrelation of X for LAG = -3, 0, 1, 3, 4, 8
;         lag = [-3, 0, 1, 3, 4, 8]
;         result = a_correlate(x, lag)
;
;       The result should be:
;         [0.0146185, 1.00000, 0.810879, 0.0146185, -0.325279, -0.151684]
;
; PROCEDURE:
;       See computational formula published in IDL manual.
;
; REFERENCE:
;       INTRODUCTION TO STATISTICAL TIME SERIES
;       Wayne A. Fuller
;       ISBN 0-471-28715-6
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, October 1994
;       Modified:    GGS, RSI, August 1995
;                    Corrected a condition which excluded the last term of the
;                    time-series.
;       Modified:    GGS, RSI, April 1996
;                    Simplified AUTO_COV function. Added DOUBLE keyword.
;                    Modified keyword checking and use of double precision.
;   CT, RSI, September 2002: Rewrote for speed, per W. Biagiotti suggestions.
;                    Now handles large vectors and complex inputs.
;   CT, RSI, July 2003: Add note about using the mean over entire series.
;-
function A_Correlate, X, Lag, Covariance = Covariance, Double = doubleIn

    compile_opt idl2

    ; Compute the sample-autocorrelation or autocovariance of (Xt, Xt+l)
    ; as a function of the lag (l).

    ON_ERROR, 2

    nX = N_ELEMENTS(x)

    ;Check length.
    if nX lt 2 then $
        MESSAGE, "X array must contain 2 or more elements."

    ;If the DOUBLE keyword is not set then the internal precision and
    ;result are identical to the type of input.
    type = SIZE(x, /TYPE)
    isComplex = (type eq 6) or (type eq 9)
    useDouble = (N_ELEMENTS(doubleIn) eq 1) ? KEYWORD_SET(doubleIn) : $
        (type eq 5) or (type eq 9)

    nLag = N_ELEMENTS(Lag)

    Auto = useDouble ? (isComplex ? DCOMPLEXARR(nLag) : DBLARR(nLag)) : $
        (isComplex ? COMPLEXARR(nLag) : FLTARR(nLag))

    ; Note that we subtract the mean over the entire time series,
    ; rather than subtracting the mean from the first and last N-lag
    ; points separately. This is discussed further in Jenkins & Watts,
    ; Spectral Analysis and its Applications, 1968. In short, the use
    ; of separate means for each portion is not recommended, as it is
    ; not a satisfactory estimate when a several autocorrelations at
    ; different lags are required.
    ;
    ; Users should be aware that A_CORRELATE(X, 1) will therefore not
    ; give the same answer as CORRELATE(X[0:N-2], X[1:*])
    ;
    data = X - (TOTAL(X, Double = useDouble) / nX)

    ;Compute Autocovariance.
    M = ABS(Lag)
    for k = 0L, nLag-1 do $
        Auto[k] = TOTAL(data[0:nX - 1 - M[k]] * data[M[k]:*])

    ; Divide by N for autocovariance, or by variance for autocorrelation.
    Auto = TEMPORARY(Auto) / $
        (KEYWORD_SET(Covariance) ? nX : TOTAL(data^2))

    return, useDouble ? Auto : $
        (isComplex ? COMPLEX(Auto) : FLOAT(Auto))

end
