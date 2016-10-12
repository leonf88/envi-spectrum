;$Id: //depot/idl/releases/IDL_80/idldir/lib/p_correlate.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       P_CORRELATE
;
; PURPOSE:
;       This function computes the partial correlation coefficient of a
;       dependent variable and one particular independent variable when
;       the effects of all other variables involved are removed.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = P_correlate(X, Y, C)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double that
;             specifies the independent variable data.
;
;       Y:    An n-element vector of type integer, float or double that
;             specifies the dependent variable data.
;
;       C:    An array of type integer, float or double that specifies the
;             independent variable data whose effects are to be removed.
;             The columns of this two dimensional array correspond to the
;             n-element vectors of independent variable data.
;
; KEYWORD PARAMETERS:
;    DOUBLE:  If set to a non-zero value, computations are done in
;             double precision arithmetic.
;
; EXAMPLES:
;       Define the data vectors.
;         x0 = [64, 71, 53, 67, 55, 58, 77, 57, 56, 51, 76, 68]
;         x1 = [57, 59, 49, 62, 51, 50, 55, 48, 52, 42, 61, 57]
;         x2 = [ 8, 10,  6, 11,  8,  7, 10,  9, 10,  6, 12,  9]
;
;       Compute the partial correlation of x0 and x1 with the effects of
;       x2 removed. The result should be 0.533469
;         result = p_correlate(x0, x1, reform(x2, 1, n_elements(x2)))
;
;       Compute the partial correlation of x0 and x2 with the effects of
;       x1 removed. The result should be 0.334572
;         result = p_correlate(x0, x2, reform(x1, 1, n_elements(x1)))
;
;       Compute the partial correlation of x1 and x2 with the effects of
;       x0 removed. The result should be 0.457907
;         result = p_correlate(x1, x2, reform(x0, 1, n_elements(x0)))
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Modified by:  GGS, RSI, July 1994
;                     Minor changes to code. New documentation header.
;       Modified by:  GGS, RSI, August 1996
;                     Added DOUBLE keyword.
;                     Modified keyword checking and use of double precision.
;       CT, RSI, Feb 2003: Completely rewrote to correct formula for
;                     multiple columns. Before it would always return
;                     a positive correlation. Now the sign is correct.
;       CT, RSI, Jan 2004: Use double precision for internal calculations.
;                     Throw error if REGRESS failed due to matrix inversion.
;
;-
function P_Correlate, xVec, yVec, cVec, $
    DOUBLE = doubleIn

    compile_opt idl2

    ON_ERROR, 2  ;Return to caller if an error occurs.

    if (N_PARAMS() ne 3) then $
        MESSAGE, 'Incorrect number of arguments.'

    nDim = SIZE(cVec, /N_DIMENSIONS)
    dimC = SIZE(cVec, /DIMENSIONS)

    nX = N_ELEMENTS(xVec)
    if (nX ne N_ELEMENTS(yVec)) then $
        MESSAGE, 'X and Y must have the same number of elements.'

    if (nDim lt 1) or (nDim gt 2) then MESSAGE, $
        'C must be a vector or a two-dimensional array.'

    twoD = (nDim eq 2) and (dimC[0] gt 1)

    ; Check row dimension of C.
    if (dimC[(nDim eq 2)] ne nX) then $
        MESSAGE, 'Incompatible arrays.'

    ; Check for DOUBLE keyword.
    doDouble = N_ELEMENTS(doubleIn) ? KEYWORD_SET(doubleIn) : $
        ((SIZE(xVec,/TYPE) eq 5) or (SIZE(yVec,/TYPE) eq 5) $
            or (SIZE(cVec,/TYPE) eq 5))

    ; From "Partial Correlation Coefficients", Gerard E. Dallal
    ; http://www.tufts.edu/~gdallal/partial.htm
    ;
    ; Let Y and X be the variables of primary interest
    ; and let C1...Cp be the variables held fixed.
    ; First, calculate the residuals after regressing Y on C1...Cp.
    ; These are the parts of Y that cannot be predicted by C1...Cp.
    ; Then, calculate the residuals after regressing X on C1...Cp.
    ; These are the parts of X that cannot be predicted by C1...Cp.
    ; The partial correlation coefficient between Y and X adjusted for
    ; C1...Cp is the correlation between these two sets of residuals.

    if (not twoD) then begin   ; single column

        ; For efficiency for a single C column, we just compute
        ; the partial correlation directly, without going thru regress.
        pXY = CORRELATE(xVec, yVec, /DOUBLE)
        pXC = CORRELATE(xVec, cVec, /DOUBLE)
        pYC = CORRELATE(yVec, cVec, /DOUBLE)

        result = ((pXC ne 1) and (pYC ne 1)) ? $
            (pxY - pXC*pYC)/SQRT((1 - pXC^2)*(1 - pYC^2)) : 0d

    endif else begin    ; multiple columns

        ; Regress Y on C and compute residuals.
        dummy = REGRESS(cVec, yVec, YFIT=ycFit, /DOUBLE, STATUS=status)
        if (status ne 0) then $
            MESSAGE, 'Inversion failed due to singular array or small pivot element.'
        yresid = yVec - TEMPORARY(ycFit)

        ; Regress X on C and compute residuals.
        dummy = REGRESS(cVec, xVec, YFIT=xcFit, /DOUBLE, STATUS=status)
        if (status ne 0) then $
            MESSAGE, 'Inversion failed due to singular array or small pivot element.'
        xresid = xVec - TEMPORARY(xcFit)
        ; Correlate the residuals.
        result = CORRELATE(yresid, xresid, /DOUBLE)

    endelse

    return, doDouble ? result : FLOAT(result)

end

