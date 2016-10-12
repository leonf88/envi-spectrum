;$Id: //depot/idl/releases/IDL_80/idldir/lib/f_pdf.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;     F_PDF
;
; PURPOSE:
;       This function computes the probabilty (p) such that:
;                   Probability(X <= v) = p
;       where X is a random variable from the F distribution with
;       (dfn) and (dfd) degrees of freedom.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;       Result = f_pdf(V, DFN, DFD)
;
; INPUTS:
;       V:    A scalar of type integer, float or double that specifies
;             the cutoff value.
;
;     DFN:    A positive scalar of type integer, float or double that
;             specifies the degrees of freedom of the F distribution
;             numerator.
;
;     DFD:    A positive scalar of type integer, float or double that
;             specifies the degrees of freedom of the F distribution
;
; EXAMPLE:
;       Compute the probability that a random variable X, from the F
;       distribution with (dfn = 5) and (dfd = 24) degrees of freedom,
;       is less than or equal to 3.90. The result should be 0.990059
;         result = f_pdf(3.90, 5, 24)
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
;-

function f_pdf, x, dfn, dfd

  on_error, 2  ;Return to caller if error occurs.

	return, 1.0 - ibeta(dfd/2.0, dfn/2.0, 1.0*dfd/(dfd+dfn*(x > 0)))

end
