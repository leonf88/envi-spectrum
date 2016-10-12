;$Id: //depot/idl/releases/IDL_80/idldir/lib/correlate.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CORRELATE
;
; PURPOSE:
;       This function computes the linear Pearson correlation coefficient
;       of two vectors or the Correlation Matrix of an M x N array.
;       Alternatively, this function computes the covariance of two vectors
;       or the Covariance Matrix of an M x N array.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = Correlate(X [,Y])
;
; INPUTS:
;       X:    A vector or an M x N array of type integer, float or double.
;
;       Y:    A vector of type integer, float or double. If X is an M x N
;             array, this parameter should not be supplied.
;
; KEYWORD PARAMETERS:
;       COVARIANCE:    If set to a non-zero value, the sample covariance is
;                      computed.
;
;       DOUBLE:        If set to a non-zero value, computations are done in
;                      double precision arithmetic.
;
; RESTRICTIONS:
;       If X is an M x N array, then Y should not be supplied;
;       Result = Correlate(X)
;
; EXAMPLES:
;       Define the data vectors.
;         x = [65, 63, 67, 64, 68, 62, 70, 66, 68, 67, 69, 71]
;         y = [68, 66, 68, 65, 69, 66, 68, 65, 71, 67, 68, 70]
;
;       Compute the linear Pearson correlation coefficient of x and y.
;         result = correlate(x, y)
;       The result should be 0.702652
;
;       Compute the covariance of x and y.
;         result = correlate(x, y, /covariance)
;       The result should be 3.66667
;
;       Define an array with x and y as its columns.
;         a = [transpose(x), transpose(y)]
;       Compute the correlation matrix.
;         result = correlate(a)
;       The result should be [[1.000000,  0.702652]
;                             [0.702652,  1.000000]]
;
;       Compute the covariance matrix.
;         result = correlate(a, /covariance)
;       The result should be [[7.69697,  3.66667]
;                             [3.66667,  3.53788]]
;
; PROCEDURE:
;       CORRELATE computes the linear Pearson correlation coefficient of
;       two vectors. If the vectors are of unequal length, the longer vector
;       is truncated to the length of the shorter vector. If X is an M x N
;       array, M-columns by N-rows, the result will be an M x M array of
;       linear Pearson correlation coefficients with the iTH column and jTH
;       row element corresponding to the correlation of the iTH and jTH
;       columns of the M x N array. The M x M array of linear Pearson
;       correlation coefficients (also known as the Correlation Matrix) is
;       always symmetric and contains 1s on the main diagonal. The Covariance
;       Matrix is also symmetric, but is not restricted to 1s on the main
;       diagonal.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  DMS, RSI, Sept 1983
;       Modified:    GGS, RSI, July 1994
;                    Added COVARIANCE keyword.
;                    Included support for matrix input.
;                    New documentation header.
;       Modified:    GGS, RSI, April 1996
;                    Included support for scalar and unequal length vector
;                    inputs. Added checking for undefined correlations and
;                    support of IEEE NaN (Not a Number).
;                    Added DOUBLE keyword.
;                    Modified keyword checking and use of double precision.
;   CT, RSI, Sept 2003: Force correlations to be in the range -1 to +1,
;           except for NaN values. Also force values on diagonal to be 1.
;   CT, RSI, Dec 2004: Improve handling for DOUBLE=0, and for complex input.
;
;-

;-------------------------------------------------------------------------
FUNCTION Cov_Mtrx, X, Double = dbl

  compile_opt hidden

  dbl = keyword_set(dbl)
  if n_elements(x) le 1 then RETURN, dbl ? 1d : 1.0

  type = SIZE(x, /TYPE)
  cplx = type eq 6 || type eq 9

  xdata = cplx ? (dbl ? DCOMPLEX(x) : COMPLEX(x)) : $
    (dbl ? DOUBLE(X) : FLOAT(x))

  dims = SIZE(x, /DIMENSIONS)
  meanx = TOTAL(xdata, 2)/dims[1]
  ; Use indices to do the rebin, so we can handle complex.
  idx = REBIN(LINDGEN(dims[0]), dims[0], dims[1])
  VarXi = xdata - meanx[idx]

  RETURN, MATRIX_MULTIPLY(VarXi, cplx ? CONJ(VarXi) : VarXi, $
    /BTRANSPOSE)/(dims[1]-1)

end


;-------------------------------------------------------------------------
FUNCTION CRR_MTRX, X, Double = dbl, N_NAN=nSS

  compile_opt hidden

  dbl = keyword_set(dbl)
  if n_elements(x) le 1 then RETURN, dbl ? 1d : 1.0

  type = SIZE(x, /TYPE)
  cplx = type eq 6 || type eq 9

  xdata = cplx ? (dbl ? DCOMPLEX(x) : COMPLEX(x)) : $
    (dbl ? DOUBLE(X) : FLOAT(x))

  dims = SIZE(x, /DIMENSIONS)
  meanx = TOTAL(xdata, 2)/dims[1]
  ; Use indices to do the rebin, so we can handle complex.
  idx = REBIN(LINDGEN(dims[0]), dims[0], dims[1])
  VarXi = xdata - meanx[idx]

  SS = TOTAL(ABS(VarXi)^2, 2)        ;Sum of squares of columns
  SS = SS # SS

  iSS = WHERE(SS eq 0, nSS)     ;Zero denominator signals undefined Correlation.
  if nSS ne 0 then $
    SS[iSS] = 1

  cm = MATRIX_MULTIPLY(VarXi, cplx ? CONJ(VarXi) : VarXi, $
    /BTRANSPOSE)/SQRT(SS)

  if nSS ne 0 then $
    cm[iSS] = !VALUES.F_NAN

  RETURN, cm
end


;-------------------------------------------------------------------------
FUNCTION Correlate, X, Y, Covariance = Covariance, Double = doubleIn

  ON_ERROR, 2  ;Return to caller if an error occurs.

  if N_PARAMS() eq 2 then begin  ;Vector inputs.

    typex = SIZE(x, /TYPE)
    typey = SIZE(y, /TYPE)
    dbl = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
        (typex eq 5 || typey eq 5)
    cplx = typex eq 6 || typex eq 9 || typey eq 6 || typey eq 9

    Nx = n_elements(x)
    Ny = n_elements(y)

    ;Means.
    sLength = Nx < Ny
    if nx le ny then begin
        xMean = TOTAL(X, Double = dbl) / sLength
        xDev = X - xMean
    endif else begin
        tmp = x[0:ny-1]
        xMean = TOTAL(tmp, Double = dbl) / sLength
        xDev = temporary(tmp) - xMean
    endelse

    if ny le nx then begin
        yMean = TOTAL(Y, Double = dbl) / sLength
        yDev = Y - yMean
    endif else begin
        tmp = y[0:nx-1]
        yMean = TOTAL(tmp, Double = dbl) / sLength
        yDev = temporary(tmp) - yMean
    endelse

    nan = dbl ? !VALUES.D_NAN : !VALUES.F_NAN
    if (KEYWORD_SET(Covariance)) then begin
        if sLength eq 1 then return, nan
        return, TOTAL(xDev * (cplx ? CONJ(yDev) : yDev), Double = dbl)/ $
            (sLength-1)
    endif

    dx2 = TOTAL(ABS(xDev)^2, Double = dbl)
    dy2 = TOTAL(ABS(yDev)^2, Double = dbl)
    if dx2 eq 0 || dy2 eq 0 then return, nan
    result = TOTAL(xDev * (cplx ? CONJ(yDev) : yDev), Double=dbl)/ $
        (SQRT(dx2)*SQRT(dy2))
    if (~cplx) then $
        result = -1 > result < 1
    return, result

  endif

    ;Array input.
    typex = SIZE(x, /TYPE)
    dbl = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
        (typex eq 5)
    cplx = typex eq 6 || typex eq 9

    if (KEYWORD_SET(Covariance)) then $
        return, COV_MTRX(X, Double = dbl)

    ; Correlation.
    result = CRR_MTRX(X, Double = dbl, N_NAN=nNaN)

    ; Make sure our correlation values are in -1 to +1 range.
    dim1 = (SIZE(x, /DIMENSIONS))[0]
    diag = LINDGEN(dim1)*(dim1 + 1)
    if (nNaN gt 0) then begin
        good = WHERE(FINITE(result), ngood)
        ; Only clip if non-complex.
        if (ngood gt 0 && ~cplx) then begin
            result[good] = -1 > result[good] < 1
        endif
        ; Because of roundoff error, values along diagonal are not always 1.
        ; So force them to be exactly 1. However, we need to preserve
        ; any NaN's, so only force the finite values to be 1.
        good = WHERE(FINITE(result[diag]), ngood)
        if (ngood gt 0) then $
            result[diag[good]] = 1
    endif else begin
        ; Only clip if non-complex.
        if (~cplx) then begin
            result = -1 > TEMPORARY(result) < 1
        endif
        ; Because of roundoff error, values along diagonal are not always 1.
        ; So force them to be exactly 1.
        result[diag] = 1
    endelse


  return, result

end

