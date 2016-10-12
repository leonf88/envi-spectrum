;$Id: //depot/idl/releases/IDL_80/idldir/lib/tm_test.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       TM_TEST
;
; PURPOSE:
;       This function computes the Student's t-statistic and the probability
;       that two vectors of sampled data have significantly different means.
;       The default assumption is that the data is drawn from populations with
;       the same true variance. This type of test is often refered to as the
;       T-means Test.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = TM_TEST(X, Y)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double.
;
;       Y:    An m-element vector of type integer, float or double.
;             If the PAIRED keyword is set, X and Y must have the same
;             number of elements.
;
; KEYWORD PARAMETERS:
;       PAIRED:   If set to a non-zero value, X and Y are assumed to be
;                 paired samples and must have the same number of elements.
;
;       UNEQUAL:  If set to a non-zero value, X and Y are assumed to be from
;                 populations with unequal variances.
;
; EXAMPLE
;       Define two n-element vectors of tabulated data.
;         X = [257, 208, 296, 324, 240, 246, 267, 311, 324, 323, 263, 305, $
;               270, 260, 251, 275, 288, 242, 304, 267]
;         Y = [201, 56, 185, 221, 165, 161, 182, 239, 278, 243, 197, 271, $
;               214, 216, 175, 192, 208, 150, 281, 196]
;       Compute the Student's t-statistic and its significance assuming that
;       X and Y belong to populations with the same true variance.
;       The result should be the two-element vector [5.5283890, 2.5245510e-06],
;       indicating that X and Y have significantly different means.
;         result = tm_test(X, Y)
;
; PROCEDURE:
;       TM_TEST computes the t-statistic of X and Y as the ratio;
;       (difference of sample means) / (standard error of differences) and
;       its significance (the probability that |t| could be at least as large
;       large as the computed statistic). X and Y may be of different lengths.
;       The result is a two-element vector containing the t-statistic and its
;       significance. The significance is a value in the interval [0.0, 1.0];
;       a small value (0.05 or 0.01) indicates that X and Y have significantly
;       different means.
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press
;       ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, Aug 1994
;                    TM_TEST is based on the routines: ttest.c, tutest.c and
;                    tptest.c described in section 14.2 of Numerical Recipes,
;                    The Art of Scientific Computing (Second Edition), and is
;                    used by permission.
;       CT, RSI, March 2000: removed redundant betacf, ibeta functions
;-


function tm_test, x0, x1, paired = paired, unequal = unequal

  on_error, 2

  if keyword_set(paired) ne 0 and keyword_set(unequal) ne 0 then $
    message, 'Paired and Unequal keywords cannot be set simultaneously.'

  nx0 = n_elements(x0)
  nx1 = n_elements(x1)

  if nx0 le 1 or nx1 le 1 then $
    message, 'x0 and x1 must be vectors of length greater than one.'

  type = size(x0)

  if keyword_set(paired) ne 0 then begin
    ;x0 and x1 are paired samples with corrected covariance.
    if nx0 ne nx1 then message, $
      'Paired keyword requires vectors of equal size.'
    mv0 = moment(x0)
    mv1 = moment(x1)
    cov = total((x0 - mv0[0]) * (x1 - mv1[0]))
    df = nx0 - 1
    cov = cov / df
    sd = sqrt((mv0[1] + mv1[1] - 2.0 * cov) / nx0)
    t = (mv0[0] - mv1[0]) / sd
    prob = ibeta(0.5*df, 0.5, df/(df+t^2))
    if type[2] eq 4 then return, float([t, prob]) $
    else return, [t, prob]
  endif else if keyword_set(unequal) ne 0 then begin
    ;x0 and x1 are assumed to have different population variances.
    mv0 = moment(x0)
    mv1 = moment(x1)
    t = (mv0[0] - mv1[0]) / sqrt(mv0[1]/nx0 + mv1[1]/nx1)
    df = (mv0[1]/nx0 + mv1[1]/nx1)^2 / $
         ((mv0[1]/nx0)^2/(nx0 - 1.0) + (mv1[1]/nx1)^2/(nx1 - 1.0))
    prob = ibeta(0.5*df, 0.5, df/(df+t^2))
    if type[2] ne 5 then return, float([t, prob]) $
    else return, [t, prob]
  endif else begin
    ;x0 and x1 are assumed to have the same population variance.
    mv0 = moment(x0)
    mv1 = moment(x1)
    df = nx0 + nx1 - 2
    var = ((nx0 - 1)*mv0[1] + (nx1 - 1)*mv1[1]) / df
    t = (mv0[0] - mv1[0]) / sqrt(var*(1.0/nx0 + 1.0/nx1))
    prob = ibeta(0.5*df, 0.5, df/(df+t^2))
    if type[2] ne 5 then return, float([t, prob]) $
    else return, [t, prob]
  endelse

end
