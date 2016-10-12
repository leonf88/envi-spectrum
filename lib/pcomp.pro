; $Id: //depot/idl/releases/IDL_80/idldir/lib/pcomp.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       PCOMP
;
; PURPOSE:
;       This function computes the principal components of an M-column, N-row
;       array, where M is the number of variables and N is the number of
;       observations or samples. The principal components of a multivariate
;       data set may be used to restate the data in terms of derived variables
;       or may be used to reduce the dimensionality of the data by reducing
;       the number of variables (columns). The result is an Nvariables-column
;       (Nvariables <= M), N-row array of derived variables.
;
; CATEGORY:
;       Statistics
;
; CALLING SEQUENCE:
;       Result = Pcomp(A)
;
; INPUTS:
;       A:    An M-column, N-row array of type float or double.
;
; KEYWORD PARAMETERS:
;   COEFFICIENTS:  Use this keyword to specify a named variable which
;                  returns the principal components used to compute the
;                  derived variables. The principal components are the
;                  coefficients of the derived variables and are returned
;                  in an M-column, M-row array. The rows of this array
;                  correspond to the coefficients of the derived variables.
;                  The coefficients are scaled so that the sums of their
;                  squares are equal to the eigenvalue from which they are
;                  computed.
;
;     COVARIANCE:  If set to a non-zero value, the principal components
;                  are computed using the covariances of the original data.
;                  The default is to use the correlations of the original
;                  data to compute the principal components.
;
;         DOUBLE:  If set to a non-zero value, computations are done in
;                  double precision arithmetic.
;
;    EIGENVALUES:  Use this keyword to specify a named variable which returns
;                  a 1-column, M-row array of eigenvalues that correspond to
;                  the principal components. The eigenvalues are listed in
;                  descending order.
;
;     NVARIABLES:  Use this keyword to specify the number of derived variables.
;                  A value of zero, negative values, and values in excess of
;                  the input array's column dimension result in a complete set
;                  (M-columns and N-rows) of derived variables.
;
;    STANDARDIZE:  If set to a non-zero value, the variables (the columns) of
;                  the input array are converted to standardized variables;
;                  variables with a mean of zero and variance of one.
;
;      VARIANCES:  Use this keyword to specify a named variable which returns
;                  a 1-column, M-row array of variances. The variances corr-
;                  espond to the percentage of the total variance for each
;                  derived variable.
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;           Written by:  GGS, RSI, February 1996
;            RJF, RSI, June 1998 - Added protection for the
;                   case where the Coefficients keyword
;                   was not specified.
;   CT, RSI, Nov 2001: Make copy of Array so values don't
;           change with /STANDARDIZE.
;-
FUNCTION Standardvar, X, Sx, Double = Double
  COMPILE_OPT hidden

  no = Sx[2]        ;# of observations
  mean = TOTAL(X, 2, DOUBLE=Keyword_Set(Double)) / no ;Vector of Means
  xstd = X - (mean # replicate(1,No))       ;Deviations from means
  stdev = sqrt(total(xstd^2, 2)/(No-1))     ;Vector of Stdevs

;   zero = where(stdev eq 0, count)     ;Avoid dividing by 0
;   if count gt 0 then stdev(zero) = 1.0

  return, xstd * ((1./stdev) # replicate(1, No))  ;Normalize by 1./Stdev
END

FUNCTION pcomp, ArrayIn, Coefficients = Eigenvectors, Covariance = Covariance, $
                       Double = Double, Eigenvalues = Eigenvalues, $
                       nVariables = nVariables, Standardize = Standardize, $
                       Variances = Variances

ON_ERROR, 2

  Dimension = size(ArrayIn)
  if Dimension[0] ne 2 then message, $
    "Input array must be a two-dimensional."

  Nv = Dimension[1]
  No = Dimension[2]

  if N_ELEMENTS(Double) eq 0 then Double = (Dimension[Dimension[0]+1] eq 5)

  ;The number of Principal Components must be greater than 0 and less
  ;than the column dimension of the input array. Negative values and
  ;values in excess of the input array's column dimension result in a
  ;complete set of derived variables.
  if KEYWORD_SET(nVariables) eq 0 then nVariables = Nv $
  else nVariables = long(nVariables)

  ;Standardize the columns of the input array with a mean of 0.0
  ;and a variance of 1.0
  Array = KEYWORD_SET(Standardize) ? $
    STANDARDVAR(ArrayIn, Dimension, Double = Double) : ArrayIn

  Eigenvalues = TRANSPOSE(EIGENQL( $
                CORRELATE(Array, COVARIANCE = COVARIANCE, Double = Double), $
                EIGENVECTORS = Eigenvectors, Double = Double))

  ;Principal Components (Coefficients) are often scaled so that the sum
  ;of squares of their coefficients are equal to the corresponding eigen-
  ;value. If the components are computed from the correlation matrix, the
  ;scaled coefficients represent correlations between the original variables
  ;and Principal Components.

  ;Scale each eigenvector by the SQRT of its corresponding eigenvalue.

  if Double eq 0 then Tol = 1.0e-6 $
  else Tol = 1.0d-12

  iss = where(abs(Eigenvalues) le Tol, nss) ;Check for ~zero~ eigenvalues.
  if nss ne 0 then Eigenvalues[iss] = 0.0
  Eigenvectors = Eigenvectors * (REPLICATE(1.0, Nv) # SQRT(Eigenvalues))

  ;<< Check the orthogonality of the Principal Components >>
  ;<< orth = Coefficients ## transpose(Coefficients) >>
  ;<< Diagonal elements are eigenvalues. >>

  if ARG_PRESENT(Variances) then $
    Variances = Eigenvalues / $
                TRACE(CORRELATE(Array, COVARIANCE = COVARIANCE, $
                      Double = Double), Double = Double)

  ;Derived variables are stored in the columns of DerivedData.
  if Double eq 0 then $
    DerivedData = TRANSPOSE(Eigenvectors) # FLOAT(Array) $
  else DerivedData = TRANSPOSE(Eigenvectors) # Array

  ;Return the derived variables.
  if nVariables ge Nv or $
     nVariables le 0 then RETURN, DerivedData $
  else RETURN, DerivedData[0:nVariables-1,*]

END

