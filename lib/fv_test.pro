;$Id: //depot/idl/releases/IDL_80/idldir/lib/fv_test.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       FV_TEST
;
; PURPOSE:
;       This function computes the F-statistic and the probability that two
;       vectors of sampled data have significantly different variances. This
;       type of test is often refered to as the F-variances Test.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = FV_TEST(X, Y)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double.
;
;       Y:    An m-element vector of type integer, float or double.
;
; EXAMPLE
;       Define two n-element vectors of tabulated data.
;         X = [257, 208, 296, 324, 240, 246, 267, 311, 324, 323, 263, 305, $
;               270, 260, 251, 275, 288, 242, 304, 267]
;         Y = [201, 56, 185, 221, 165, 161, 182, 239, 278, 243, 197, 271, $
;               214, 216, 175, 192, 208, 150, 281, 196]
;       Compute the F-statistic (of X and Y) and its significance.
;       The result should be the two-element vector [2.48578, 0.0540116],
;       indicating that X and Y have significantly different variances.
;         result = fv_test(X, Y)
;
; PROCEDURE:
;       FV_TEST computes the F-statistic of X and Y as the ratio of variances
;       and its significance. X and Y may be of different lengths. The result
;       is a two-element vector containing the F-statistic and its
;       significance. The significance is a value in the interval [0.0, 1.0];
;       a small value (0.05 or 0.01) indicates that X and Y have significantly
;       different variances.
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press
;       ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, Aug 1994
;                    FV_TEST is based on the routine: ftest.c described in
;                    section 14.2 of Numerical Recipes, The Art of Scientific
;                    Computing (Second Edition), and is used by permission.
;       CT, RSI, March 2000: removed redundant betacf, ibeta functions
;-


function fv_test, x0, x1

  on_error, 2

  nx0 = n_elements(x0)
  nx1 = n_elements(x1)

  if nx0 le 1 or nx1 le 1 then $
    message, 'x0 and x1 must be vectors of length greater than one.'

  type = size(x0)

  mv0 = moment(x0)
  mv1 = moment(x1)

  if mv0[1] gt mv1[1] then begin
    f = mv0[1] / mv1[1]
    df0 = nx0 - 1
    df1 = nx1 - 1
  endif else begin
    f = mv1[1] / mv0[1]
    df0 = nx1 - 1
    df1 = nx0 - 1
  endelse

  prob = 2.0 * ibeta(0.5*df1, 0.5*df0, df1/(df1+df0*f))

  if type[2] ne 5 then prob = float(prob)

  if prob gt 1 then return, [f, 2.0 - prob] $
  else return, [f, prob]

end
