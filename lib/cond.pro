;$Id: //depot/idl/releases/IDL_80/idldir/lib/cond.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       COND
;
; PURPOSE:
;       This function computes the condition number of an N by N array.
;
; CATEGORY:
;       Complex Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = COND(A)
;
; INPUTS:
;       A:      An N by N real or complex array.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;   LNORM: Set this keyword to indicate which norm to use for the computation.
;          The possible values are:
;           LNORM=0  Use the L(Infinity) norm (maximum absolute row sum norm).
;           LNORM=1  Use the L(1) norm (maximum absolute column sum norm).
;                    For LNORM=0 or 1 the array A must be square.
;           LNORM=2  Use the L(2) norm (spectral norm), defined as
;                    the largest singular value, computed from SVD.
;           If LNORM is not specified then LNORM=0 is used.
;
; EXAMPLE:
;       Define a complex array (a).
;         a = [[complex(1, 0), complex(2,-2), complex(-3,1)], $
;              [complex(1,-2), complex(2, 2), complex(1, 0)], $
;              [complex(1, 1), complex(0, 1), complex(1, 5)]]
;       Compute the condition number of the complex array (a) using
;       double-precision complex arithmetic.
;         result = cond(a, /double)
;
; PROCEDURE:
;    This function returns the condition number of an N x N real or
;    complex array A.
;       For LNORM=0 or 1, the condition number is norm(A)*norm(A_inverse).
;       If A is real and A_inverse is invalid (due to the singularity of A
;       or floating-point errors in the invert function), the condition
;       number is returned as a -1. If A is complex and A_inverse is invalid
;       (due to the singularity of A), calling COND results in floating-
;       point errors.
;       For LNORM=2, the condition number is defined as the ratio of the
;       largest to smallest singular values, computed using SVD.
;       If the smallest singular value is zero, then Infinity is returned.
;       For LNORM=2 the array A cannot be complex.
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
;       CRC Concise Encyclopedia of Mathematics
;       Eric W. Weisstein
;       ISBN 0-8493-9640-9
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, April 1992
;       Modified:    GGS, RSI, February 1994
;                    Accepts complex inputs. Added DOUBLE keyword.
;       Modified:    GGS, RSI, November 1994
;                    Added support for double-precision complex inputs.
;                    Changed NR_INVERT to INVERT.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;       Modified: CT, RSI, May 2001
;             Added LNORM keyword.
;             Allows L(1), L(2), L(Infinity) norm to be used. L(2) uses SVDC.
;       Modified: CT, RSI, July 2003
;             Change SVDC to LA_SVD so complex input is allowed for L(2)
;   Modified: CT, RSI, Jan 2005: Use double precision for internal
;       calculations, to avoid problems with huge integer inputs.
;-
function Cond, Array, $
    DOUBLE=double, $
    LNORM=lnormIn

    COMPILE_OPT idl2
    ON_ERROR, 2  ;Return to caller if error occurs.

    type = SIZE(Array, /TYPE)
    dim = SIZE(Array, /DIMENSIONS)
    if (N_ELEMENTS(dim) ne 2) then $
        MESSAGE, 'Input must be a two-dimensional array.'

    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        (type eq 5) or (type eq 9)

    ; Default is to use L(Infinity) norm
    nl = N_ELEMENTS(lnormIn)
    if (nl gt 1) then $
        MESSAGE, 'LNORM must be a scalar or 1 element array.'
    lnorm = (nl gt 0) ? FIX(lnormIn[0]) : 0
    if (lnorm lt 0) or (lnorm gt 2) then $
        MESSAGE, 'Keyword LNORM must be equal to 0, 1, or 2'

    ; For L(2) we need to use SVD, otherwise call NORM.
    if (lnorm eq 2) then begin

        LA_SVD, Array, W, U, V, /DOUBLE
        minSV = MIN(W, MAX=maxSV)

        ; Is the matrix singular? If so return Infinity without
        ; throwing an overflow message.
        if (minSV eq 0) then $
            return, dbl ? !VALUES.d_infinity : !VALUES.f_infinity

        ; If the matrix is ill-conditioned this could still overflow.
        result = maxSV/minSV

    endif else begin

        if (dim[0] ne dim[1]) then $
            MESSAGE, 'Input must be a square matrix.'
        InverseA = INVERT(Array, Status, /DOUBLE)

        ; Inversion failed?
        if (Status eq 1) then return, -1

        ; Valid inverse.
        norm1 = NORM(Array, /DOUBLE, LNORM=lnorm)
        norm2 = NORM(InverseA, /DOUBLE, LNORM=lnorm)
        result = norm1*norm2

    endelse

    return, dbl ? result : FLOAT(result)
end
