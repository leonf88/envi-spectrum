;$Id: //depot/idl/releases/IDL_80/idldir/lib/norm.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       NORM
;
; PURPOSE:
;   This function computes the norm of a real or complex vector or array.
;   By default, NORM computes the Euclidean norm of a vector, or the
;   Infinity norm of an array.
;
; CATEGORY:
;       Complex Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = NORM(A)
;
; INPUTS:
;       A:      An N-element real or complex vector.
;               An M by N real or complex array.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;   LNORM: Set this keyword to indicate which norm to compute.
;       If A is a vector, then the possible values are:
;           LNORM=0  Compute the L(Infinity) norm, defined as Max(Abs(A))
;           LNORM=1  Compute the L(1) norm, defined as Total(Abs(A))
;           LNORM=2  Compute the L(2) norm, defined as Sqrt(Total(Abs(A)^2))
;           LNORM=n  Compute the L(n) norm, defined as (Total(Abs(A)^n))^(1/n)
;                    n may be any number, float or integer.
;           If LNORM is not specified then LNORM=2 is used.
;       If A is an array, then the possible values are:
;           LNORM=0  Compute the L(Infinity) norm
;                    (maximum absolute row sum norm), defined as
;                    Max(Total(Abs(A),1))
;           LNORM=1  Compute the L(1) norm
;                    (maximum absolute column sum norm), defined as
;                    Max(Total(Abs(A),2))
;           LNORM=2  Compute the L(2) norm (spectral norm), defined as
;                    the largest singular value, computed from SVD.
;           If LNORM is not specified then LNORM=0 is used.
;
; EXAMPLE:
;       1) Define an N-element complex vector (a).
;            a = [complex(1, 0), complex(2,-2), complex(-3,1)]
;          Compute the Euclidean norm of (a).
;            result = NORM(a)
;
;       2) Define an M by N complex array (a).
;            a = [[complex(1, 0), complex(2,-2), complex(-3,1)], $
;                 [complex(1,-2), complex(2, 2), complex(1, 0)]]
;          Compute the Infinity norm of the complex array (a).
;            result = NORM(a)
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
;                    Computes the Euclidean norm of an N-element vector.
;                    Accepts complex inputs. Added DOUBLE keyword.
;       Modified:    GGS, RSI, September 1994
;                    Added support for double-precision complex inputs.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;       Modified: CT, RSI, May 2001
;             Added LNORM keyword. Allows L(1), L(2),..., L(Infinity) norm.
;       Modified: CT, RSI, July 2003
;             Change SVDC to LA_SVD so complex input is allowed for L(2)
;   Modified: CT, RSI, August 2004: Don't allow arrays for LNORM.
;       Fix bug for LNORM=2 with integer vectors.
;   Modified: CT, RSI, Jan 2005: Use double precision for internal
;       calculations, to avoid problems with huge integer inputs.
;-

function Norm, Array, $
    DOUBLE=double, $
    LNORM=lnormIn

    COMPILE_OPT idl2
    ON_ERROR, 2  ;Return to caller if error occurs.

    type = SIZE(Array, /TYPE)
    ndim = SIZE(Array, /N_DIMENSIONS)
    if (ndim lt 1) or (ndim gt 2) then $
        MESSAGE, 'Input must be an N-element vector or an M by N array.'

    if (N_ELEMENTS(lnormIn) gt 1) then $
        MESSAGE, 'LNORM must be a scalar or 1 element array.'

    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        (type eq 5) or (type eq 9)
    rtype = dbl ? 5 : 4   ; double or float return type

    ; Are all elements finite? If so, we can set NAN to zero.
    nan = 1 - ARRAY_EQUAL(FINITE(Array), 1)

    ; Default is either L(2) for vectors, or L(Infinity) for matrix
    lnorm = (N_ELEMENTS(lnormIn) gt 0) ? lnormIn[0] : (ndim eq 1) ? 2 : 0
    lnorm = DOUBLE(lnorm)

    ;ABS needed for complex.
    if (ndim eq 1) then begin
        ; Vector
        case lnorm of
            ; Handle the special cases first
            ; Infinity norm
            0: result = MAX(ABS(Array), NAN=nan)
            ; L(1) norm
            1: result = TOTAL(ABS(Array), /DOUBLE, NAN=nan)
            ; L(2) norm (Euclidean)
            2: result = SQRT(TOTAL(ABS(Array)^2d, /DOUBLE, NAN=nan))
            ; General L(n) norm
            else: result = $
                (TOTAL(ABS(Array)^lnorm, /DOUBLE, NAN=nan))^(1/lnorm)
        endcase

    endif else begin ;If array, compute the Infinity norm.
        ; Matrix
        case lnorm of
            ; Handle the special cases first
            ; Infinity norm (maximum absolute row sum norm)
            0: result = MAX(TOTAL(ABS(Array), 1, /DOUBLE, NAN=nan))
            ; L(1) norm (maximum absolute column sum norm)
            1: result = MAX(TOTAL(ABS(Array), 2, /DOUBLE, NAN=nan))
            ; L(2) norm (spectral norm)
            2: begin
                LA_SVD, Array, W, U, V, /DOUBLE
                result = MAX(W)
               end
            ; General L(n) norm
            else: MESSAGE, $
                'For array input, LNORM must be equal to 0, 1, or 2'
        endcase

    endelse

    ; TOTAL(DoubleData, Double = 0) returns a double-precision result.
    ; Cast the result to FLOAT if Double = 0.
    return, FIX(result, TYPE=rtype)
END
