; $Id: //depot/idl/releases/IDL_80/idldir/lib/beta.pro#1 $

; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   BETA
;
; PURPOSE:
;   Return the Beta function of (possibly complex) Z.
;
; CALLING SEQUENCE:
;   Result = BETA(Z)
;
; INPUTS:
;   Z: The expression for which the beta function will be evaluated.
;      If Z is double-precision, the result is double-precision,
;      otherwise the result is floating-point. Z may be complex.
;
; KEYWORD PARAMETERS:
;   DOUBLE: Set this keyword to return a double-precision result.
;
; MODIFICATION HISTORY:
;   3 July 1995, AB, RSI.
;   AB, 5/4/2001, Switch from using _EXTRA to _STRICT_EXTRA, so that
;       incorrect keywords will cause issue proper messages to
;       be issued instead of being silently ignored.
;   CT, RSI, Dec 2001: Rewrote to use LNGAMMA, which now handles complex.
;-

function beta, z, w, DOUBLE=double, _REF_EXTRA=_extra

    ON_ERROR, 2

    tz = SIZE(z,/TYPE)
    tw = SIZE(w,/TYPE)
    isComplex = (tz eq 6) or (tz eq 9) or (tw eq 6) or (tw eq 9)
    doComplex = isComplex

    ; If either Z or W has a negative number,
    ; then we must use complex for the LNGAMMA.
    if (~isComplex) then doComplex = $
        ~Array_Equal(z ge 0b, 1b) || ~Array_Equal(w ge 0b, 1b)

    ; Be sure to do the calculation using double precision.
    z1 = doComplex ? DCOMPLEX(z) : DOUBLE(z)
    w1 = doComplex ? DCOMPLEX(w) : DOUBLE(w)
    result = EXP(LNGAMMA(z1, _STRICT_EXTRA=_extra) + $
        LNGAMMA(w1, _STRICT_EXTRA=_extra) - $
        LNGAMMA(z1+w1, _STRICT_EXTRA=_extra), _STRICT_EXTRA=_extra)

    ; Return double precision if keyword is set, or either arg is double.
    doDouble = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        (tz eq 5) or (tz eq 9) or (tw eq 5) or (tw eq 9)

    ; We may need to convert from DCOMPLEX back to DOUBLE
    ; because Z or W might have had negative numbers.
    return, doDouble ? (isComplex ? result : DOUBLE(result)) : $
        (isComplex ? COMPLEX(result) : FLOAT(result))
end
