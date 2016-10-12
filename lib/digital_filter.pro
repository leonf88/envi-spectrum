; $Id: //depot/idl/releases/IDL_80/idldir/lib/digital_filter.pro#1 $
;
; Copyright (c) 1985-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;+
; NAME:
;   DIGITAL_FILTER
;
; PURPOSE:
;   Compute the coefficients of a non-recursive, digital
;   filter.  Highpass, lowpass, bandpass and bandstop
;   filters may be constructed with this function.
;
; CATEGORY:
;   Signal processing.
;
; CALLING SEQUENCE:
;   Coeff = DIGITAL_FILTER(Flow, Fhigh, A, Nterms)  ;To get coefficients.
;
;   Followed by:
;
;   Yout  = CONVOL(Yin, Coeff)  ;To apply the filter.
;
; INPUTS:
;   Flow:   The lower frequency of the filter as a fraction of the Nyquist
;       frequency.
;
;   Fhigh:  The upper frequency of the filter as a fraction of the Nyquist
;       frequency.
;
;   A:  The size of Gibbs phenomenon wiggles in -db.  50 is a good
;       choice.
;
;   Nterms: The number of terms in the filter formula.  The order
;       of filter.
;
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;       The following conditions are necessary for various types of
;       filters:
;
;       No Filtering:   Flow = 0, Fhigh = 1.
;       Low Pass:   Flow = 0, 0 < Fhigh < 1.
;       High Pass:  0 < Flow < 1, Fhigh =1.
;       Band Pass:  0 < Flow < Fhigh < 1.
;       Band Stop:  0 < Fhigh < Flow < 1.
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
;
; KEYWORDS:
;   Double: Set this keyword to use double-precision arithmetic.
;
; OUTPUTS:
;   Returns a vector of coefficients with (2*nterms + 1) elements.
;
; SIDE EFFECTS:
;   None.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;   This function returns the coefficients of a non-recursive,
;   digital filter for evenly spaced data points.  Frequencies are
;   expressed in terms of the Nyquist frequency, 1/2T, where T
;   is the time between data samples.
;
; MODIFICATION HISTORY:
;   DMS, April, 1985.
;   Adapted from:
;   "Digital Filters", Robert Walraven,
;   Proceedings of the Digital Equipment User's Society, Fall, 1984.
;   Department of Applied Science,
;   University of California, Davis, CA 95616.
;
;   CT, RSI, Dec 2001: Add DOUBLE keyword.
;       Convert 1-element inputs to scalars.
;
;-
;
FUNCTION DIGITAL_FILTER,flowIn,fhighIn,aIn,ntermsIn, $
    DOUBLE=double

    COMPILE_OPT idl2

    ON_ERROR,2              ;Return to caller if an error occurs

    ; Convert from 1-element arrays to scalars if necessary.
    fLow = fLowIn[0]
    fHigh = fHighIn[0]
    aGibbs = aIn[0]
    nTerms = nTermsIn[0]

    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        SIZE(fLow,/TYPE) eq 5

    ; Band stop?
    fStop = (fHigh lt fLow) ? 1d : 0d

    ;   computes Kaiser weights W(N,K) for digital filters.
    ; W = COEF = returned array of Kaiser weights
    ; N = value of N in W(N,K), i.e. number of terms
    ; A = Size of gibbs phenomenon wiggles in -DB.
    ;
    IF (aGibbs LE 21.) THEN ALPHA = 0. $
        ELSE IF (aGibbs GE 50.) THEN ALPHA = 0.1102d *(aGibbs-8.7d)  $
        ELSE ALPHA = 0.5842d*(aGibbs-21d)^0.4d + 0.07886d*(aGibbs-21d)

    ARG = (FINDGEN(NTERMS)+1.)/NTERMS
    COEF = BESELI(ALPHA*SQRT(1.-ARG^2),0)/BESELI(ALPHA,0)
    T = (FINDGEN(NTERMS)+1)*!DPI
    COEF = COEF * (SIN(T*FHIGH)-SIN(T*FLOW))/T
    coef = [REVERSE(coef), fHigh - fLow + fStop, coef] ;REPLICATE IT
    RETURN, dbl ? coef : FLOAT(coef)
END
