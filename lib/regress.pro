; $Id: //depot/idl/releases/IDL_80/idldir/lib/regress.pro#1 $
;
; Copyright (c) 1982-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	REGRESS
;
; PURPOSE:
;	Perform a multiple linear regression fit.
;
;	REGRESS fits the function:
;		Y[i] = Const + A[0]*X[0,i] + A[1]*X[1,i] + ... +
;                      A[Nterms-1]*X[Nterms-1,i]
;
; CATEGORY:
;       G2 - Correlation and regression analysis.
;
; CALLING SEQUENCE:
;
;	Result = REGRESS(X, Y)
;
; INPUTS:
;
;       X:	The array of independent variable data.  X must
;		be dimensioned as an array of Nterms by Npoints, where
;		there are Nterms coefficients (independent variables) to be
;		found and Npoints of samples.
;
;       Y:	The vector of dependent variable points.  Y must have Npoints
;		elements.
;
; OUTPUTS:
;
;	REGRESS returns a column vector of coefficients that has Nterms
;	elements.
;
; KEYWORDS:
;
;   CHISQ:   Sum of squared errors divided by MEASURE_ERRORS if specified.
;
;   CONST:   Constant term. (A0)
;
;	CORRELATION: Vector of linear correlation coefficients.
;
;   COVAR:   Covariance matrix of the coefficients.
;
;	DOUBLE:  if set, force computations to be in double precision.
;
;	FTEST:	The value of F for goodness-of-fit test.
;
;	MCORRELATION:   The multiple linear correlation coefficient.
;
;   MEASURE_ERRORS: Set this keyword to a vector containing standard
;       measurement errors for each point Y[i].  This vector must be the same
;       length as X and Y.
;
;     Note - For Gaussian errors (e.g. instrumental uncertainties),
;        MEASURE_ERRORS should be set to the standard
; 	     deviations of each point in Y. For Poisson or statistical weighting
; 	     MEASURE_ERRORS should be set to sqrt(Y).
;
;   SIGMA:   The 1-sigma error estimates of the returned parameters.
;
;     Note: if MEASURE_ERRORS is omitted, then you are assuming that the
;           regression is the correct model. In this case,
;           SIGMA is multiplied by SQRT(CHISQ/(N-M)), where N is the
;           number of points in X. See section 15.2 of Numerical Recipes
;           in C (Second Edition) for details.
;
;   STATUS = Set this keyword to a named variable to receive the status
;          of the operation. Possible status values are:
;          0 for successful completion, 1 for a singular array (which
;          indicates that the inversion is invalid), and 2 which is a
;          warning that a small pivot element was used and that significant
;          accuracy was probably lost.
;
;    Note: if STATUS is not specified then any error messages will be output
;          to the screen.
;
;   YFIT:   Vector of calculated Y's.
;
; PROCEDURE:
;	Adapted from the program REGRES, Page 172,
;	Bevington, Data Reduction and Error Analysis for the
;	Physical Sciences, 1969.
;
; MODIFICATION HISTORY:
;	Written, DMS, RSI, September, 1982.
;	Added RELATIVE_WEIGHT keyword    W. Landsman   August 1991
;       Fixed bug in invert  Bobby Candey 1991 April 22
;       Added STATUS argument.  GGS, RSI, August 1996
;   CT, RSI, March 2000: Fixed status flag. Cleaned up help.
;   CT, RSI, July 2000: Change arguments to keywords.
;         Add MEASURE_ERRORS [equivalent to 1/sqrt(Weights)],
;         removes need for RELATIVE_WEIGHT.
;-
;
FUNCTION REGRESS,X,Y, $
	weights_old,yfit_old,const_old,sigma_old, $       ; obsolete arguments
	ftest_old,r_old,rmul_old,chisq_old,status_old, $  ; obsolete arguments
	RELATIVE_WEIGHT=relative_weight, $                ; obsolete keyword
	CHISQ=chisq, $
	CONST=const, $
	DOUBLE=double, $
	FTEST=ftest, $
	CORRELATION=correlation, $
	MCORRELATION=mcorrelation, $
	MEASURE_ERRORS=measure_errors, $
	SIGMA=sigma, $
	STATUS=status, $
	YFIT=yfit

COMPILE_OPT idl2

ON_ERROR,2              ;Return to caller if an error occurs
sy = SIZE(Y)            ;Get dimensions of x and y.
sx = SIZE(X)

ndimX = sx[0]
nterm = (ndimX EQ 1) ? 1 : sx[1]   ; # of terms (coefficients)
nptsX = sx[ndimX]       ;# of observations (samples)
npts = sy[1]            ;# of observations (samples)

IF (nptsX NE npts) THEN MESSAGE, $
	'X and Y have incompatible dimensions.'
IF (ndimX EQ 1) THEN x = REFORM(x, 1, npts, /OVER)   ; change X to a 2D array

double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : $
	((SIZE(x,/TNAME) EQ 'DOUBLE') OR (SIZE(y,/TNAME) EQ 'DOUBLE'))
one = double ? 1d : 1.0
two = double ? 2d : 2.0


IF (N_PARAMS() GT 2) THEN BEGIN      ; old-style REGRESS (with arguments)
	IF (N_ELEMENTS(weights_old) NE npts) THEN MESSAGE, $
		'Weight has been replaced by MEASURE_ERRORS. See Online Help.'
	no_weights = KEYWORD_SET(relative_weight)
	weights = no_weights ? one : weights_old  ; note there is no ^2
ENDIF ELSE BEGIN      ; new style (with keywords)
	IF KEYWORD_SET(relative_weight) THEN $
		MESSAGE,/INFO,'Keyword RELATIVE_WEIGHT is obsolete.'
	no_weights = N_ELEMENTS(measure_errors) NE npts
    ; note different meaning from Weights argument
	weights = no_weights ? one : 1/measure_errors^two
ENDELSE

sw = no_weights ? npts : TOTAL(weights, DOUBLE=double) ;sum of weights
ymean = TOTAL(y*weights, DOUBLE=double)/sw   ;y mean
wgt = no_weights ? one : REBIN(TRANSPOSE(weights),nterm,npts)
xmean = TOTAL(wgt*x,2, DOUBLE=double)/sw
wmean = sw/npts
wgt = TEMPORARY(wgt)/wmean
ww = weights/wmean

nfree = npts-1          ;degs of freedom
sigmay = SQRT(TOTAL(ww * (y-ymean)^2)/nfree) ;weights*(y(i)-ymean)
xx = x - REBIN(xmean,nterm,npts)     ;x(j,i) - xmean(i)
wx = TEMPORARY(wgt) * xx             ;weights(i)*(x(j,i)-xmean(i))
sigmax = SQRT(TOTAL(xx*wx,2)/nfree)  ;weights(i)*(x(j,i)-xm)*(x(k,i)-xm)
array = (wx # TRANSPOSE(xx))/(nfree * sigmax #sigmax)

array = INVERT(array, status)
IF (status EQ 1L && ~ARG_PRESENT(status)) THEN BEGIN
	IF (ndimX EQ 1) THEN x = REFORM(x, /OVER)    ; change X back to a vector
	MESSAGE, "Inversion failed due to singular array."
END
IF (status EQ 2L && ~ARG_PRESENT(status)) THEN BEGIN
	MESSAGE, /INFO, $
	    "Inversion used a small pivot element. Results may be inaccurate."
endif

correlation = (TEMPORARY(wx) # (y - ymean)) / (sigmax * sigmay * nfree)
a = (correlation # array)*(sigmay/sigmax)         ;get coefficients
yfit = a # x                            ;compute fit
const = ymean - TOTAL(a*xmean)             ;constant term
yfit = yfit + const                        ;add it in
freen = npts-nterm-1 > 1                ;degs of freedom, at least 1.
chisq = TOTAL(ww*(y - yfit)^2)*wmean ;weighted chi squared


; correction factor for no weights (see Num.Rec. sec 15-2)
varnce = no_weights ? chisq/freen : one/wmean

; error terms
sigma = SQRT(array[LINDGEN(nterm)*(nterm+1)]*varnce/(nfree*sigmax^2))

mult_covariance = TOTAL(a*correlation*sigmax/sigmay)
ftest = (mult_covariance GE 1.) ? 1e6 : $
	mult_covariance/nterm / ((1.-mult_covariance)/freen)
mcorrelation = SQRT(mult_covariance)
IF (ndimX EQ 1) THEN x = REFORM(x, /OVER)    ; change X back to a vector


; fill in obsolete arguments, if necessary
IF (N_PARAMS() GT 3) THEN BEGIN
	status_old = status
	chisq_old = chisq/freen    ; reduced chi-square
	rmul_old = mcorrelation
	r_old = correlation
	ftest_old = ftest
	sigma_old = sigma
	const_old = const
	yfit_old = yfit
ENDIF

RETURN, a
END
