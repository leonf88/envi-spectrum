; $Id: //depot/idl/releases/IDL_80/idldir/lib/lmfit.pro#1 $
;
; Copyright (c) 1988-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       LMFIT
;
; PURPOSE:
;       Non-linear least squares fit to a function of an arbitrary
;       number of parameters.  The function may be any non-linear
;       function.  If available, partial derivatives can be calculated by
;       the user function, else this routine will estimate partial derivatives
;       with a forward difference approximation.
;
; CATEGORY:
;       E2 - Curve and Surface Fitting.
;
; CALLING SEQUENCE:
;       Result = LMFIT(X, Y, A)
;
; INPUTS:
;
;   X:  A row vector of independent variables.  This routine does
;       not manipulate or use values in X, it simply passes X
;       to the user-written function.
;
;   Y:  A row vector containing the dependent variable.
;
;   A:  A vector that contains the initial estimate for each parameter.
;
; KEYWORDS:
;
;   ALPHA:  The value of the Curvature matrix upon exit.
;
;   CHISQ:   Sum of squared errors divided by MEASURE_ERRORS if specified.
;
;   CONVERGENCE: Returns 1 if the fit converges, 0 if it does
;         not meet the convergence criteria in ITMAX iterations,
;         or -1 if a singular matrix is encountered.
;         If CONVERGENCE is not then any error messages will be
;         output.
;
;   COVAR:   Covariance matrix of the coefficients.
;
;	DOUBLE:  if set, force computations to be in double precision.
;
;   FITA:  A vector, with as many elements as A, which contains a Zero for
;        each fixed parameter, and a non-zero value for elements of A to
;        fit. If not supplied, all parameters are taken to be non-fixed.
;
;   FUNCTION_NAME:  The name of the function (actually, a procedure) to
;       fit.  If omitted, "LMFUNCT" is used. The procedure must be written as
;       described under RESTRICTIONS, below.
;
;   ITMAX:  Minimum number of iterations. Default = 50.
;
;   ITER:   The actual number of iterations which were performed
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
;   SIGMA:   The 1-sigma error estimates of the returned parameters,
;            SIGMA=SQRT(VARIANCE).
;
;     Note: if MEASURE_ERRORS is omitted, then you are assuming that
;           your model is correct. In this case,
;           SIGMA is multiplied by SQRT(CHISQ/(N-M)), where N is the
;           number of points in X. See section 15.2 of Numerical Recipes
;           in C (Second Edition) for details.
;
;   TOL:    The convergence tolerance. The routine returns when the
;         relative decrease in chi-squared is less than TOL in an interation.
;         Default = 1.e-6 for single-precision or 1d-12 for double-precision.
;
; Note - The WEIGHTS keyword is obsolete. New code should use MEASURE_ERRORS.
;   WEIGHTS:   A vector of weights for Y[i].  This vector must be the same
;          length as X and Y.  The default is no weighting.
;
;     Note: The error for each term is weighted by Weight[i] when computing the
;           fit.  Gaussian or instrumental uncertianties should be weighted as
;           Weight = 1/Sigma where Sigma is the measurement error or standard
;           deviations of Y. For Poisson or statistical weighting use
;           Weight=1/sqrt(Y), since Sigma=sqrt(Y).
;
; OUTPUTS:
;       Returns a vector containing the fitted function evaluated at the
;       input X values.  The final estimates for the coefficients are
;       returned in the input vector A.
;
; SIDE EFFECTS:
;
;       The vector A is modified to contain the final estimates for the
;       parameters.
;
; RESTRICTIONS:
;       The function to be fit must be defined and called LMFUNCT,
;       unless the FUNCTION_NAME keyword is supplied.  This function,
;       must accept a single value of X (the independent variable), and A
;       (the fitted function's  parameter values), and return  an
;       array whose first (zeroth) element is the evalutated function
;       value, and next n_elements(A) elements are the partial derivatives
;       with respect to each parameter in A.
;
;       If X is passed in as a double, the returned vector MUST be of
;       type double as well. Likewise, if X is a float, the returned
;       vector must also be of type float.
;
;       For example, here is the default LMFUNCT in the IDL User's Libaray.
;       which is called as : out_array = LMFUNCT( X, A )
;
;
;	function lmfunct,x,a
;
;         ;Return a vector appropriate for LMFIT
;         ;
;         ;The function being fit is of the following form:
;         ;  F(x) = A(0) * exp( A(1) * X) + A(2) = bx+A(2)
;         ;
;         ;dF/dA(0) is dF(x)/dA(0) = exp(A(1)*X)
;         ;dF/dA(1) is dF(x)/dA(1) = A(0)*X*exp(A(1)*X) = bx * X
;         ;dF/dA(2) is dF(x)/dA(2) = 1.0
;         ;
;         ;return,[[F(x)],[dF/dA(0)],[dF/dA(1)],[dF/dA(2)]]
;         ;
;         ;Note: returning the required function in this manner
;         ;    ensures that if X is double the returned vector
;         ;    is also of type double. Other methods, such as
;         ;    evaluating size(x) are also valid.
;
;        bx=A(0)*exp(A(1)*X)
;        return,[ [bx+A(2)], [exp(A(1)*X)], [bx*X], [1.0] ]
;	end
;
;
; PROCEDURE:
;       Based upon "MRQMIN", least squares fit to a non-linear
;       function, pages 683-688, Numerical Recipies in C, 2nd Edition,
;       Press, Teukolsky, Vettering, and Flannery, 1992.
;
;       "This method is the Gradient-expansion algorithm which
;       combines the best features of the gradient search with
;       the method of linearizing the fitting function."
;
;       Iterations are performed until three consequtive iterations fail
;       to chang the chi square changes by greater than TOL, or until
;       ITMAX, but at least ITMIN,  iterations have been  performed.
;
;       The initial guess of the parameter values should be
;       as close to the actual values as possible or the solution
;       may not converge.
;
;       The function may fail to converge, or it can encounter
;       a singular matrix. If this happens, the routine will fail
;       with the Numerical Recipes error message:
;
;
; EXAMPLE:
;        Fit a function of the form:
;            f(x)=a(0) * exp(a(1)*x) + a(2) + a(3) * sin(x)
;
;  Define a lmfit return function:
;
;  function myfunct,x,a
;
;       ;Return a vector appropriate for LMFIT
;
;       ;The function being fit is of the following form:
;       ;  F(x) = A(0) * exp( A(1) * X) + A(2) + A(3) * sin(x)
;
;
;       ; dF(x)/dA(0) = exp(A(1)*X)
;       ; dF(x)/dA(1) = A(0)*X*exp(A(1)*X) = bx * X
;       ; dF(x)/dA(2) = 1.0
;       ; dF(x)/dA(3) = sin(x)
;
;        bx=A(0)*exp(A(1)*X)
;        return,[[bx+A(2)+A(3)*sin(x)],[exp(A(1)*X)],[bx*X],[1.0],[sin(x)]]
;     end
;
;   pro run_lmfunct
;         x=findgen(40)/20.		;Define indep & dep variables.
;         y=8.8 * exp( -9.9 * X) + 11.11 + 4.9 * sin(x)
;         sig=0.05 * y
;         a=[10.0,-7.0,9.0,4.0]		;Initial guess
;         fita=[1,1,1,1]
;         ploterr,x,y,sig
;         yfit=lmfit(x,y,a,MEASURE_ERRORS=sig,FITA=FITA,$
;                  SIGMA=SIGMA,FUNCTION_NAME='myfunct')
;         oplot,x,yfit
;         for i=0,3 do print,i,a(i),format='("A (",i1,")= ",F6.2)'
;  end
;
; MODIFICATION HISTORY:
;       Written, SVP, RSI, June 1996.
;       Modified, S. Lett, RSI, Dec 1997
;                               Jan 1998
;                               Feb 1998
;       Modified: CT, RSI, July 2000: Add MEASURE_ERRORS,
;                         Add double-precision default TOL
;
;-
function lmfit, x, y, a, $
        fita=fita, $
        Function_Name = Function_Name, $
        alpha=alpha,covar=covar,$
        itmax=itmax,iter=iter,tol=tol,chisq=chisq, $
        itmin=itmin,double=double,$
        SIGMA=SIGMA,CONVERGENCE=CONVERGENCE, $
        MEASURE_ERRORS=measure_errors, $
        WEIGHTS=weights  ; obsolete keyword

COMPILE_OPT idl2

       inexcept=!except
       !except=0  ; turn off math exceptions
       on_error,2              ;Return to caller if error

       ndata = n_elements(x)    ; # of data points
       ma = n_elements(a)       ; # of parameters
       if ma le 0 then begin
           message, 'A must have at least ONE parameter.'
       endif
       nfree = n_elements(y) - ma ; Degrees of freedom
       if nfree le 0 then message, 'LMFIT - not enough data points.'
;
;      Process the keywords
;
       if n_elements(function_name) le 0 then function_name = "LMFUNCT"
       if n_elements(itmin) eq 0 then itmin= 5 ;Minimum # iterations
       if n_elements(itmax) eq 0 then itmax= 50	;Maximum # iterations
       if (itmin ge itmax) then itmax=itmin
;
;      Prepare the FITA vector
;
       if n_elements(FITA) eq 0 then FITA = replicate(1, ma)
       if n_elements(FITA) ne ma then $
         message, 'The number of elements in FITA must equal those of A'
       FITA=fix(FITA)

;   If DOUBLE keyword is set, then use its value, otherwise,
;   if X, Y or A is double precision, set do_double to true
	double_input = MAX([SIZE(a,/TNAME),SIZE(x,/TNAME),SIZE(y,/TNAME)] EQ 'DOUBLE')
	do_double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : double_input
    one = do_double ? 1d : 1.0
;
;      Prepare the SIG vector, this is MEASURE_ERRORS or 1/sqrt(WEIGHTS)
;
   isWeight = N_ELEMENTS(weights) GT 0
   isMeasure = N_ELEMENTS(measure_errors) GT 0
   IF isWeight OR isMeasure THEN BEGIN
     IF isWeight AND isMeasure THEN $
       MESSAGE, 'Incompatible keywords MEASURE_ERRORS and WEIGHTS.'
     sig = isWeight ? one/sqrt(weights) : measure_errors
     nsig = N_ELEMENTS(sig)
     IF nsig NE ndata THEN $
        MESSAGE, 'MEASURE_ERRORS must have the number of elements as X and Y.'
   ENDIF ELSE BEGIN
     sig = REPLICATE(one, ndata)
     nsig = 0    ; no measure errors actually specified
   ENDELSE




       if do_double then begin
           chisq=0.0D
           xx=double(x) & yy=double(y) & a=double(a)
           ssig=abs(double(sig))
       endif else begin
           chisq=0.0
           xx=float(x) & yy=float(y) & a=float(a)
           ssig=abs(float(sig))
       endelse

       if n_elements(tol) eq 0 then $
         tol = do_double ? 1d-12 : 1e-6 ;Convergence tolerance

;
;       Warning! The following call is to the actual NR recipies code.
;       Direct calls to this by the user are not supported, as this
;       function call will be removed in a future version of IDL
;
       MRQMIN, function_name, xx, yy, ssig, ndata, a, fita, ma, covar, $
         alpha, chisq, alambda, $
         DOUBLE=do_double, itmin=itmin, itmax=itmax, $
         tolerance=tol, niter=iter
;
       convergence=1
       extra = do_double ? '' : ' Try /DOUBLE.'
       if alambda lt 0 then begin
           convergence=-1
           IF NOT ARG_PRESENT(convergence) THEN message, /INFORMATIONAL, $
             'Warning: Singular Covariance Matrix Encountered.' + extra
       endif else begin
           if (iter ge itmax) then begin
             convergence=0
             IF NOT ARG_PRESENT(convergence) THEN message, $
               'Warning: Failed to Converge.' + extra, /INFORMATIONAL
           endif
       endelse

       diag=lindgen(ma)*(ma+1)
       SIGMA=sqrt(abs(covar[diag]))
	IF (nsig EQ 0) THEN $
		sigma = sigma*SQRT(chisq/(ndata-ma))

       if do_double then yfit=dblarr(ndata) else yfit=fltarr(ndata)
       for i=0,ndata-1 do $
         yfit[i] = (call_function(function_name,xx[i],a))[0]

;
;  return the result
;
       !except=inexcept
       return,yfit
;
END
