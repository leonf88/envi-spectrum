;$Id: //depot/idl/releases/IDL_80/idldir/lib/binomial.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       BINOMIAL
;
; PURPOSE:
;       This function computes the probabilty (bp) such that:
;                   Probability(X => v) = bp
;       where X is a random variable from the cumulative binomial distribution
;       (Bernouli distribution).
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = Binomial(V, N, P)
;
; INPUTS:
;       V:    A non-negative integer specifying the minimal number of
;             times an event E occurs in (N) independent performances.
;
;       N:    A non-negative integer specifying the number of performances.
;
;       P:    A non-negative scalar or array, in the interval [0.0, 1.0],
;             of type float or double that specifies the probability of
;             occurrence or success of a single independent performance.
;
; KEYWORDS:
;
;    DOUBLE = Set this keyword to force the computation to be done in
;             double-precision arithmetic.
;
;    GAUSSIAN = Set this keyword to force the computation to be done using
;               the Gaussian approximation.
;
; EXAMPLES:
;       Compute the probability of obtaining at least two 6s in rolling a
;       die four times. The result should be 0.131944
;         result = binomial(2, 4, 1./6.)
;
;       Compute the probability of obtaining exactly two 6s in rolling a
;       die four times. The result should be 0.115741
;         result = binomial(2, 4, 1./6.) - binomial(3, 4, 1./6.)
;
;       Compute the probability of obtaining three or fewer 6s in rolling
;       a die four times. The result should be 0.999228
;         result = (binomial(0, 4, 1./6.) - binomial(1, 4, 1./6.)) + $
;                  (binomial(1, 4, 1./6.) - binomial(2, 4, 1./6.)) + $
;                  (binomial(2, 4, 1./6.) - binomial(3, 4, 1./6.)) + $
;                  (binomial(3, 4, 1./6.) - binomial(4, 4, 1./6.))
;
; PROCEDURE:
;       BINOMIAL computes the probability that an event E occurs at least
;       (V) times in (N) independent performances. The event E is assumed
;       to have a probability of occurance or success (P) in a single
;       performance.
;
;       If an overflow occurs during computation, then the Gaussian
;       distribution is used to approximate the cumulative binomial
;       distribution.
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
;       Schaum's Outline of Theory and Problems of Probability and Statistics,
;       M.R. Spiegel, McGraw-Hill, 1975.
;
; MODIFICATION HISTORY:
;       Modified by:  GGS, RSI, July 1994
;                     Minor changes to code. Rewrote documentation header.
;       CT, RSI, June 2000: Added keywords DOUBLE, GAUSSIAN;
;           changed algorithm to use LNGAMMA function;
;           doesn't use Gaussian unless overflow or /GAUSSIAN;
;           now allows array input for P.
;-


function binomial, v, n, pIn, $
	DOUBLE=double, $
	GAUSSIAN=gaussian

	on_error, 2  ;Return to caller if error occurs.

	if MIN(pIn) lt 0. or MAX(pIn) gt 1. then message, $
		'P must be in the interval [0.0, 1.0]'
	if v lt 0 then message, 'V must be nonnegative.'
	if n lt 0 then message, 'N must be nonnegative.'

	double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : $
		(SIZE(pIn,/TNAME) EQ 'DOUBLE')
	p = double ? DOUBLE(pIn) : FLOAT(pIn)
	sum = p*0

	IF (v EQ 0) THEN RETURN,  sum+1  ; one
	IF (v GT n) THEN RETURN,  sum  ; zero


	q = 1 - p
	nn = fix(n)
	vv = fix(v)
	nn = double ? DOUBLE(nn) : FLOAT(nn)
	vv = double ? DOUBLE(vv) : FLOAT(vv)
	; for accuracy use logarithms to evaluate factorials
	logFact = LNGAMMA(nn+1)-LNGAMMA(vv+1)-LNGAMMA(nn-vv+1)

	; if we are going to overflow, then switch to Gaussian approx
	overflow = logFact GT (double ? 700 : 80)
	do_gauss = (N_ELEMENTS(gaussian) EQ 0) AND overflow

	IF KEYWORD_SET(gaussian) OR do_gauss THEN BEGIN  ; use Gaussian
		sum = 1 - GAUSS_PDF((v-0.5-n*p)/SQRT(n*p*q))
	ENDIF ELSE BEGIN  ; use the binomial summation
		previous = (sum = EXP(logFact) * p^vv * q^(nn-vv))
		zero = WHERE(q EQ 0, nZero)
		IF (nZero GT 0) THEN q[zero] = 1  ; avoid divide by zero
		FOR x = vv+1, nn DO BEGIN
			; ratio of next term in sequence to previous
			previous = previous*(nn-x+1)/x*(p/q)
			sum = sum + previous
		ENDFOR
		IF (nZero GT 0) THEN sum[zero] = 1   ; if p=1 then sum=1
	ENDELSE

	RETURN, sum
end
