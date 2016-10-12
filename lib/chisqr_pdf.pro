;$Id: //depot/idl/releases/IDL_80/idldir/lib/chisqr_pdf.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CHISQR_PDF
;
; PURPOSE:
;       This function computes the probabilty (p) such that:
;                   Probability(X <= v) = p
;       where X is a random variable from the Chi-square distribution
;       with (df) degrees of freedom.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = chisqr_pdf(V, DF)
;
; INPUTS:
;       V:    A scalar of type integer, float or double that specifies
;             the cutoff value.
;
;      DF:    A positive scalar of type integer, float or double that
;             specifies the degrees of freedom of the Chi-square distribution.
;
; EXAMPLES:
;       Compute the probability that a random variable X, from the Chi-square
;       distribution with (DF = 3) degrees of freedom, is less than or equal
;       to 6.25. The result should be 0.899939
;         result = chisqr_pdf(6.25, 3)
;
;       Compute the probability that a random variable X, from the Chi-square
;       distribution with (DF = 3) degrees of freedom, is greater than 6.25.
;       The result should be 0.100061
;         result = 1 - chisqr_pdf(6.25, 3)
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Modified by:  GGS, RSI, July 1994
;                     Minor changes to code. New documentation header.
;        CT, RSI, March 2000: changed call from igamma_pdf to igamma
;        CT, RSI, July 2001: Increase # of iterations to 300.
;       CT, RSI, Dec 2004: Remove restriction on # of iterations.
;           Just use the IGAMMA default.
;-

function chisqr_pdf, x, df

    on_error, 2  ;Return to caller if error occurs.

    gres = igamma(df/2.0, (x > 0)/2.0)
    if (MIN(FINITE(gres)) EQ 0) then message, /INFO, $
        'Computational error: IGAMMA failed to converge.'
    return, gres
end

