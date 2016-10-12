;$Id: //depot/idl/releases/IDL_80/idldir/lib/t_pdf.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       T_PDF
;
; PURPOSE:
;       This function computes the probabilty (p) such that:
;                   Probability(X <= v) = p
;       where X is a random variable from the Student's t distribution
;       with (df) degrees of freedom.
;
;    Note: T_PDF computes the one-tailed probability.
;       The two-tailed probability, which is Probability(Abs(X) <= v),
;       can be computed as 1 - 2*(1 - T_PDF(V, DF)).
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = T_pdf(V, DF)
;
; INPUTS:
;       V:    A scalar of type integer, float or double that specifies
;             the cutoff value.
;
;      DF:    A positive scalar of type integer, float or double that
;             specifies the degrees of freedom of the Student's t
;             distribution.
;
; EXAMPLE:
;       Compute the probability that a random variable X, from the
;       Student's t distribution with (df = 15) degrees of freedom,
;       is less than or equal to 0.691. The result should be 0.749940
;         result = t_pdf(0.691, 15)
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Modified by:  GGS, RSI, July 1994
;                     Minor changes to code. New documentation header.
;        CT, RSI, March 2000: changed call from ibeta_pdf to ibeta
;        CT, RSI, Jan 2003: Added note about this being a one-tailed test.
;-

function t_pdf , v, df

  on_error, 2  ;Return to caller if error occurs.

  if MIN(df) le 0 then message, $
    'Degrees of freedom must be positive.'
	positive = (v GE 0)   ; negative v is equal to 1-T_PDF(+v,df)

	; Note: The 0.5 in front of the ibeta converts this into a
	; one-tailed Student's-t test. Be careful, because Abramowitz and Stegun
	; define their Student's-t as the probability that the random variable
	; will be less in *absolute* value, which implies a two-tailed test.
	;
  return, positive - (positive-0.5) * ibeta(df/2.0, 0.5, df/(df + v^2.0))
end

