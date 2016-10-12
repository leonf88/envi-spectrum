;$Id: //depot/idl/releases/IDL_80/idldir/lib/ibeta.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IBETA
;
; PURPOSE:
;   This function computes the incomplete beta function, Ix(a, b).
;
; CATEGORY:
;   Special Functions.
;
; CALLING SEQUENCE:
;   Result = IBETA(A, B, X)
;
; INPUTS:
;   A:    A scalar or array that specifies the parametric exponent of the
;         integrand. A may be real or complex.
;
;   B:    A scalar or array that specifies the parametric exponent of the
;         integrand. A may be real or complex.
;
;   X:    A scalar or array that specifies the upper limit of integration.
;         X may be real or complex. If X is real, and is outside of the
;         range [0,1] then the result is complex.
;
;
; KEYWORD PARAMETERS:
;
;   DOUBLE = Set this keyword to force the computation to be done
;            in double precision.
;
;   EPS = relative accuracy, or tolerance.  The default tolerance
;         is 3.0e-7 for single precision, and 3.0d-12 for double
;         precision.
;
;   ITER = Set this keyword equal to a named variable that will contain
;          the actual number of iterations performed.
;
;   ITMAX = Set this keyword to specify the maximum number of iterations.
;           The default value is 100.
;
; EXAMPLE:
;    Compute the incomplete beta function for the corresponding elements
;    of A, B, and X.
;    Define the parametric exponents.
;      A = [0.5, 0.5, 1.0, 5.0, 10.0, 20.0]
;      B = [0.5, 0.5, 0.5, 5.0,  5.0, 10.0]
;    Define the the upper limits of integration.
;      X = [0.01, 0.1, 0.1, 0.5, 1.0, 0.8]
;    Compute the incomplete beta functions.
;      result = Ibeta(A, B, X)
;    The result should be:
;      [0.0637686, 0.204833, 0.0513167, 0.500000, 1.00000, 0.950737]
;
; REFERENCE:
;    Numerical Recipes, The Art of Scientific Computing (Second Edition)
;    Cambridge University Press
;    ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;    Written by:  GGS, RSI, September 1994
;              IBETA is based on the routines: betacf.c, betai.c and
;              gammln.c described in section 6.2 of Numerical Recipes,
;              The Art of Scientific Computing (Second Edition), and is
;              used by permission.
;   Modified by:
;       CT, RSI, March 2000, added DOUBLE, EPS, ITER, ITMAX keywords.
;       CT, RSI, Dec 2001: Converted to allow complex inputs,
;              change to vector algorithm.
;       CT, RSI, Sept 2003: Improve calc to allow huge A and B values.
;-


;---------------------------------------------------------------------------
; Make sure values smaller than fpmin are set to fpmin.
;
function ibetacf_truncate, z
    compile_opt hidden
    fpmin = 1d-60
    tooSmall = WHERE(ABS(z) lt fpmin, nSmall)
    if (nSmall gt 0) then z[tooSmall] = fpmin
    return, z
end


;---------------------------------------------------------------------------
; IBETA Cumulative sum function.
;
function ibetacf, a, b, x, $
    EPS = epsIn, $
    ITER = m, $
    ITMAX = maxit

    compile_opt idl2, hidden
    on_error, 2

    n = N_ELEMENTS(a)
    eps = (N_ELEMENTS(epsIn) eq 1) ? epsIn[0] : 3d-12
    maxit = (N_ELEMENTS(itmax) eq 1) ? itmax[0] : 100

    qab = a + b
    qap = a + 1
    qam = a - 1
    ; First step of Lentz's method.
    c = 1
    d = IBETACF_TRUNCATE(1 - qab * x / qap)
    d = 1 / TEMPORARY(d)
    h = d

    for m = 1, maxit do begin
        m2 = 2 * m

        ; One step (the even one) of the recurrence.
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = IBETACF_TRUNCATE(1 + aa*TEMPORARY(d))
        c = IBETACF_TRUNCATE(1 + aa/TEMPORARY(c))
        d = 1 / TEMPORARY(d)
        h = TEMPORARY(h) * (d * c)

        ; Next step of the recurrence (the odd one).
        aa = -(a + m) *(qab + m) * x/((a + m2) * (qap + m2))
        d = IBETACF_TRUNCATE(1 + aa*TEMPORARY(d))
        c = IBETACF_TRUNCATE(1 + aa/TEMPORARY(c))
        d = 1 / TEMPORARY(d)
        del = d * c
        h = TEMPORARY(h) * del

        ; Wait until they have all converged.
        good = FINITE(del)
        nGood = TOTAL(good)
        if (nGood eq 0) then break ; out of loop
        if (nGood eq n) then begin ; all are finite
            if (MAX(ABS(del - 1)) lt eps) then break
        endif else begin  ; some are finite
            if (MAX(ABS(del[WHERE(good)] - 1)) lt eps) then break
        endelse

    endfor

    result = TEMPORARY(h)

    if (m gt maxit) then begin
        MESSAGE, /INFORMATIONAL, $
            'Failed to converge within given parameters.'
    endif

    return, result
end


;---------------------------------------------------------------------------
function ibeta, a, b, x, $
    DOUBLE = doubleIn, $
    EPS = eps, $
    ITER = iter, $
    ITMAX = itmax

    compile_opt idl2
    on_error, 2

    ; Result type is single or double precision, real or complex.
    ta = SIZE(a, /TYPE)
    tb = SIZE(b, /TYPE)
    tx = SIZE(x, /TYPE)
    isDouble = (ta eq 5) or (ta eq 9) $
        or (tb eq 5) or (tb eq 9) or (tx eq 5) or (tx eq 9)
    isComplex = (ta eq 6) or (ta eq 9) $
        or (tb eq 6) or (tb eq 9) or (tx eq 6) or (tx eq 9)
    doDouble = (N_ELEMENTS(doubleIn) ge 1) ? $
        KEYWORD_SET(doubleIn) : isDouble


    ; If X is not in the range [0,1] then we need to use complex.
    minx = MIN(x, MAX=maxx)
    if (not isComplex) then begin
        if ((minx lt 0) or (maxx gt 1)) then MESSAGE, $
        'Argument Z must be in the range [0,1] or must be complex.'
    endif


    ; Always do the computation in double-precision, and (possibly)
    ; convert back to single precision at the end.
    xx = isComplex ? DCOMPLEX(x) : DOUBLE(x)
    aa = isComplex ? DCOMPLEX(a) : DOUBLE(a)
    bb = isComplex ? DCOMPLEX(b) : DOUBLE(b)

    ; zero iterations so far
    iter1 = (iter2 = 0)

    ; Avoid exceptions when computing log below.
    isValid = (xx ne 0) and (xx ne 1)
    hasZero = TOTAL(isValid) lt N_ELEMENTS(xx)
    if (hasZero) then begin
        xtmp = xx   ; make a copy
        xx = TEMPORARY(xx)*isValid + 0.5*(~isValid)  ; fill in bogus value
    endif

    ; Factor in front: (x^a)((1-x)^b)/Beta(a,b)
    ; This will also construct result (either a scalar or array).
    y = EXP(LNGAMMA(aa+bb) - LNGAMMA(aa) - LNGAMMA(bb) + $
        aa*ALOG(xx) + bb*ALOG(1 - xx))

    ; Set values where X=0 or 1 to zero.
    if (hasZero) then begin
        y *= isValid
        xx = TEMPORARY(xtmp)  ; put back original data
    endif

    n = N_ELEMENTS(y)

    ; Find cutoff for symmetry relation.
    cutoff = (isComplex ? DOUBLE(xx) : xx) lt $
        ABS((aa + 1)/(aa + bb + 2))
    wSmall = WHERE(cutoff, $
        nSmall, COMPLEMENT=wLarge, NCOMPLEMENT=nLarge)

    ; For small x use continued fraction directly.
    if (nSmall gt 0) then begin
        tmp = IBETACF(aa[wSmall], bb[wSmall], xx[wSmall], $
            EPS=eps, ITER=iter1, ITMAX=itmax)
        y[wSmall] = (y[wSmall]/aa[wSmall])*TEMPORARY(tmp)
    endif

    ; For larger x use symmetry relation.
    if (nLarge gt 0) then begin
        tmp = IBETACF(bb[wLarge], aa[wLarge], 1-xx[wLarge], $
            EPS=eps, ITER=iter2, ITMAX=itmax)
        y[wLarge] = 1 - (y[wLarge]/bb[wLarge])*TEMPORARY(tmp)
    endif

    iter = iter1 > iter2  ; Maximum number of iterations.


    return, doDouble ? y : $
        (isComplex ? COMPLEX(y) : FLOAT(y))
end

