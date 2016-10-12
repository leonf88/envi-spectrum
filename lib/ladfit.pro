;$Id: //depot/idl/releases/IDL_80/idldir/lib/ladfit.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       LADFIT
;
; PURPOSE:
;       This function fits the paired data {X(i), Y(i)} to the linear model,
;       y = A + Bx, using a "robust" least absolute deviation method. The
;       result is a two-element vector containing the model parameters, A
;       and B.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = LADFIT(X, Y)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double.
;
;       Y:    An n-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
;  ABSDEV:    Use this keyword to specify a named variable which returns the
;             mean absolute deviation for each data-point in the y-direction.
;
;  DOUBLE:    If set to a non-zero value, computations are done in double
;             precision arithmetic.
;
; EXAMPLE:
;       Define two n-element vectors of paired data.
;         x = [-3.20, 4.49, -1.66, 0.64, -2.43, -0.89, -0.12, 1.41, $
;               2.95, 2.18,  3.72, 5.26]
;         y = [-7.14, -1.30, -4.26, -1.90, -6.19, -3.98, -2.87, -1.66, $
;              -0.78, -2.61,  0.31,  1.74]
;       Compute the model parameters, A and B.
;         result = ladfit(x, y, absdev = absdev)
;       The result should be the two-element vector:
;         [-3.15301, 0.930440]
;       The keyword parameter should be returned as:
;         absdev = 0.636851
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press, 2nd Edition.
;       ISBN 0-521-43108-5
;   This is adapted from the routine MEDFIT described in:
;   Fitting a Line by Minimizing Absolute Deviation, Page 703.
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, September 1994
;       Modified:    GGS, RSI, July 1995
;                    Corrected an infinite loop condition that occured when
;                    the X input parameter contained mostly negative data.
;       Modified:    GGS, RSI, October 1996
;                    If least-absolute-deviation convergence condition is not
;                    satisfied, the algorithm switches to a chi-squared model.
;                    Modified keyword checking and use of double precision.
;       Modified:    GGS, RSI, November 1996
;                    Fixed an error in the computation of the median with
;                    even-length input data. See EVEN keyword to MEDIAN.
;   Modified:    DMS, RSI, June 1997
;            Simplified logic, remove SIGN and MDfunc2 functions.
;   Modified:    RJF, RSI, Jan 1999
;            Fixed the variance computation by adding some double
;            conversions.  This prevents the function from generating
;            NaNs on some specific datasets (bug 11680).
;   Modified: CT, RSI, July 2002: Convert inputs to float or double.
;            Change constants to double precision if necessary.
;   CT, March 2004: Check for quick return if we found solution.
;-

;-------------------------------------------------------------------------
FUNCTION MDfunc, b, x, y, a, absdev, EPS=eps
  COMPILE_OPT hidden

  a = MEDIAN(y - b*x, /EVEN)    ;EVEN has no effect with odd counts.
  d = y - (b * x + a)
  absdev = total(abs(d))
  nz = where(y ne 0.0, nzcount)
  if nzcount ne 0 then d[nz] = d[nz] / abs(y[nz]) ;Normalize
  nz = where(abs(d) gt EPS, nzcount)
  if nzcount ne 0 then $        ;Sign fcn, +1 for d > 0, -1 for d < 0, else 0.
    return, total(x[nz] * ((d[nz] gt 0) - fix(d[nz] lt 0))) $
  else return, 0.0
END

;-------------------------------------------------------------------------
FUNCTION LadFit, xIn, yIn, absdev = absdev, Double = DoubleIn
  ON_ERROR, 2

  nX = N_ELEMENTS(xIn)

  if nX ne N_ELEMENTS(yIn) then $
    MESSAGE, "X and Y must be vectors of equal length."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  Double = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
    (SIZE(xIn,/TYPE) eq 5 or SIZE(yIn,/TYPE) eq 5)

  x = Double ? DOUBLE(xIn) : FLOAT(xIn)
  y = Double ? DOUBLE(yIn) : FLOAT(yIn)

  sx = TOTAL(x, Double = Double)
  sy = TOTAL(y, Double = Double)

;  the variance computation is sensitive to roundoff, so we do this
;  math in DP
  sxy = TOTAL(DOUBLE(x)*DOUBLE(y), Double = Double)
  sxx = TOTAL(DOUBLE(x)*DOUBLE(x), Double = Double)
  del = DOUBLE(nX) * sxx - sx^2

  if (del eq 0.0) then begin          ;All X's are the same
    result = [MEDIAN(y, /EVEN), 0.0] ;Bisect the range w/ a flat line
    return, Double ? result : FLOAT(result)
  endif

  aa = (sxx * sy - sx * sxy) / del ;Least squares solution y = x * aa + bb
  bb = (nX * sxy - sx * sy) / del
  chisqr = TOTAL((y - (aa + bb*x))^2, Double = Double)
  sigb = sqrt(chisqr / del)     ;Standard deviation

  b1 = bb
  eps = Double ? 1d-7 : 1e-7
  f1 = MDfunc(b1, x, y, aa, absdev, EPS=eps)

  ; Quick return. The initial least squares gradient is the LAD solution.
  if (f1 eq 0.) then begin
    bb=b1
    goto, done
  endif

  delb = ((f1 ge 0) ? 3.0 : -3.0) * sigb

  b2 = b1 + delb
  f2 = MDfunc(b2, x, y, aa, absdev, EPS=eps)

  while (f1*f2 gt 0) do begin     ;Bracket the zero of the function
      b1 = b2
      f1 = f2
      b2 = b1 + delb
      f2 = MDfunc(b2, x, y, aa, absdev, EPS=eps)
  endwhile

  ; In case we finish early.
  bb = b2
  f = f2

  ;Narrow tolerance to refine 0 of fcn.
  sigb = (Double ? 0.01d : 0.01) * sigb

  while (abs(b2-b1) gt sigb && f ne 0) do begin ;bisection of interval b1,b2.
    bb = 0.5 * (b1 + b2)
    if (bb eq b1 || bb eq b2) then $
        break
    f = MDfunc(bb, x, y, aa, absdev, EPS=eps)
    if (f*f1 ge 0) then begin
        f1 = f
        b1 = bb
    endif else begin
        f2 = f
        b2 = bb
    endelse
endwhile

done:   absdev = absdev / nX

  RETURN, Double ? [aa, bb] : FLOAT([aa, bb])
END
