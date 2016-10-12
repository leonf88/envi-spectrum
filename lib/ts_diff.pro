;$Id: //depot/idl/releases/IDL_80/idldir/lib/ts_diff.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TS_DIFF
;
; PURPOSE:
;       This function recursively computes the forward differences, of an 
;       N-element time-series, K times. The result is an N-element differenced 
;       time-series with its last K elements as zeros. 
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = TS_Diff(X, K)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double containing
;             time-series samples.
;
;       K:    A positive scalar of type integer or long integer in the 
;             interval [1, N_ELEMENTS(X) - 1], that specifies the number of 
;             times X is differenced.
;
; KEYWORD PARAMETERS:
;     DOUBLE: If set to a non-zero value, computations are done in
;             double precision arithmetic.
;
; EXAMPLE:
;       Define an n-element vector of time-series samples.
;         x = [389, 345, 303, 362, 412, 356, 325, 375, $
;              410, 350, 310, 388, 399, 362, 325, 382, $
;              399, 382, 318, 385, 437, 357, 310, 391]
;
;       Compute the second forward differences of X.
;         result = TS_DIFF(x, 2)
;
;       The result should be:
;         [ 2, 101,   -9,  -106, 25,  81, -15, -95, $
;          20, 118,  -67,   -48,  0,  94, -40, -34, $
;         -47, 131,  -15,  -132, 33, 128,   0,   0]
;
; REFERENCE:
;       The Analysis of Time Series (Fourth Edition)
;       C. Chatfield
;       ISBN 0-412-31820-2
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, December 1994
;       Modified:    GGS, RSI, July 1996
;                    Added DOUBLE keywork.
;-

FUNCTION TS_Diff, x, k, Double = Double

  ON_ERROR, 2

  TypeX = SIZE(x)
  nX = TypeX[TypeX[0]+2]

  if k gt nX - 1 then $
    MESSAGE, "Order of differencing cannot exceed N_ELEMENTS(X) - 1."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then Double = (TypeX[TypeX[0]+1] eq 5)

  if Double eq 0 then tsx = FLOAT([0, x]) else tsx = [0.0d, x]

  if k gt 0 then begin
    for l = 1, k do begin ;Recursively compute differences.
      ;j = [1, 2, 3, ..., nX-1]
      ;tsx[j] = tsx[j] - tsx[j+1]
      j = LINDGEN(nX-1L)+1L
      tsx[j] = tsx[j] - tsx[j+1L]
      tsx[nX] = 0
      nX = nX - 1L
    endfor
    ;;endif else if k lt 0 then begin  ;Backward difference operator.
    ;;  for l = 1, abs(k) do begin     ;  ts_diff(x, 1) = -ts_diff(x, -1)
    ;;    a = tsx[1]                   ;  ts_diff(x, k) =  ts_diff(x, -k)
    ;;    for j = 2, nX do begin       ;    for k >= 2
    ;;      b = tsx[j]
    ;;      tsx[j-1] = tsx[j] - a
    ;;      a = b
    ;;    endfor
    ;;    tsx[nX] = 0.0
    ;;    nX = nX - 1L
    ;;  endfor
    ;;endif else $
  endif else $
    MESSAGE, "Order of differencing must be greater than zero."

  RETURN, tsx[1:*]

END
