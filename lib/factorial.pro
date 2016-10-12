;$Id: //depot/idl/releases/IDL_80/idldir/lib/factorial.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       FACTORIAL
;
; PURPOSE:
;       This function computes the factorial N! as the double-precision
;       product, (N) * (N-1) * (N-2) * ...... * 3 * 2 * 1.
;
; CATEGORY:
;       Special Functions.
;
; CALLING SEQUENCE:
;       Result = Factorial(n)
;
; INPUTS:
;       N:    A non-negative scalar or array of values.
;
; KEYWORD PARAMETERS:
;       STIRLING:    If set to a non-zero value, Stirling's asymptotic
;                    formula is used to approximate N!.
;
;       UL64: Set this keyword to return values as unsigned 64-bit integers.
;
; EXAMPLE:
;       Compute 20! with and without Stirling's asymptotic formula.
;         result_1 = factorial(20, /stirling)
;         result_2 = factorial(20)
;
;       Result_1 and result_2 should be 2.4227869e+18 and 2.4329020e+18
;       respectively.
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, November 1994
;       CT, RSI, June 2000: Rewrote to handle array input; uses GAMMA for
;              non-integers; added UL64 keyword.
;       CT, RSI, October 2000: Separate calculation for scalar input.
;              Use common variable for look-up table.
;-

function factorial, x, stirling = stirling, UL64=ul64

  COMPILE_OPT idl2
  on_error, 2
  COMMON commonFactorial, factorialBuiltIn

	IF KEYWORD_SET(stirling) THEN BEGIN
		if MIN(x) lt 0 then $
			message, 'Values for N must be non-negative.'
		;Approximate N! using Stirling's formula.
		RETURN, SQRT(2.0d * !DPI * x) * (x / EXP(1.0d))^(x+0.0d)
	ENDIF

	IF (N_ELEMENTS(factorialBuiltIn) LT 1) THEN BEGIN
		factorialBuiltIn = $
			[1ull,1,2,6,24,120,720,5040,40320,362880,3628800, $
			39916800,479001600,6227020800,87178291200,1307674368000, $
			20922789888000,355687428096000,6402373705728000, $
			121645100408832000,2432902008176640000ull]
	ENDIF

	isInt = (x EQ FIX(x)) AND (x LE 20)
	n = N_ELEMENTS(x)

; For speed purposes, split the calculation into 1-element or array input

	IF (n EQ 1) THEN BEGIN   ; scalar or 1-element vector

		if x[0] lt 0 then $
			message, 'Values for N must be non-negative.'
		IF isInt[0] THEN BEGIN
		; do the integer factorials
			fact = factorialBuiltIn[x]
			IF NOT KEYWORD_SET(ul64) THEN fact = DOUBLE(fact)
		ENDIF ELSE BEGIN
		; do floating-point factorials using GAMMA(n+1)
		; the x*0 ensures that a 1-element vector remains a vector
			fact = x*0 + GAMMA(x+1d)
			IF KEYWORD_SET(ul64) THEN fact = ULONG64(fact)
		ENDELSE

	ENDIF ELSE BEGIN   ; array

		if MIN(x) lt 0 then $
			message, 'Values for N must be non-negative.'
		fact = KEYWORD_SET(ul64) ? ULON64ARR(n) : DBLARR(n)

		; first do all the integer factorials
		whereInt = WHERE(isInt,nInt, $
			COMPLEMENT=whereNotInt, NCOMPLEMENT=nNotInt)
		IF (nInt GT 0) THEN BEGIN
			; most common cases...
			fact[whereInt] = factorialBuiltIn[x[whereInt]]
		ENDIF

		; now do all the floating-point factorials using GAMMA(n+1)
		IF (nNotInt GT 0) THEN $
			fact[whereNotInt] = GAMMA(x[whereNotInt]+1d)

	ENDELSE

	RETURN, fact

end
