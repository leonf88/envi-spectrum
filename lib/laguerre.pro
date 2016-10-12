; $Id: //depot/idl/releases/IDL_80/idldir/lib/laguerre.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   LAGUERRE
;
; PURPOSE:
;   This function returns the value of the associated Laguerre polynomial
;   L(N,K)[x], which is a solution to the differential equation,
;   xy" + (k + 1 - x)y' + ny = 0.
;
; CATEGORY:
;   Special Math Functions
;
; CALLING SEQUENCE:
;   Result = LAGUERRE(X, N [, K] [, COEFFICIENTS=coefficients] [, /DOUBLE])
;
; INPUTS:
;	X: The value at which L(N,K) is evaluated.
;      X can be either a scalar or an array of any basic type except string.
;      If X is double-precision floating-point, complex, or double-precision
;      complex, the result is of the same type. Otherwise, the result is
;      single-precision floating-point.
;
;   N: An integer, N >= 0, specifying the order of L(N,K).
;
;   K: An integer specifying the order K of L(N,K). If K is not specified then
;      the default K=0 is used and the Laguerre polynomial, L(N)[x],
;      is returned.
;
; KEYWORD PARAMETERS:
;   COEFFICIENTS: Set this keyword to a named variable that
;      will contain the polynomial coefficients in the expansion,
;      c[0] + c[1]*x + c[2]*x^2 + ...
;
;	DOUBLE:	Set this keyword to force the computation to be done using
;      double-precision arithmetic.
;
; OUTPUT:
;	The result returned by LAGUERRE is a scalar or array that has the
;   same dimensions as the input array X.
;
; EXAMPLE:
;   The radial component of the hydrogen atom wavefunction is proportional to,
;               r^l e^(-r/2) L(n-l-1,2l+1)[r]
;   where r is the normalized radial coordinate, n is the energy state,
;   and l is the orbital angular spin number (Eisberg and Resnick, 1985:
;   Quantum Physics of Atoms, Molecules, Solids, Nuclei, and Particles,
;   Second edition. J.Wiley & Sons, pp. N3-N5).
;
;   To find the radial component of the hydrogen 3s state:
;     r = FINDGEN(101)/5.
;     n = 3  ; energy state
;     l = 0  ; "s" state
;     radial = LAGUERRE(r, n - l - 1, 2*l + 1, COEFF=coeff)
;     PLOT, r, radial*(r^l)*EXP(-r/2), TITLE='Hydrogen 3s radial component'
;     PRINT, "Coefficients c[0] + c[1]r + c[2]r^2 + ... = ",coeff
;
;  IDL prints:
;   Coefficients c[0] + c[1]r + c[2]r^2 + ... =  3.00000  -3.00000  0.500000
;
; MODIFICATION HISTORY:
; 	Written by:	CT, RSI, March 2000.
;
;-
FUNCTION laguerre, x, nIn, kIn, $
	COEFFICIENTS=coefficients, $
	DOUBLE=double

	COMPILE_OPT idl2

; error checking
	ON_ERROR, 2
	IF (N_PARAMS() LT 2) OR (N_PARAMS() GT 3) THEN $
		MESSAGE,'Incorrect number of arguments.'
	IF ((N_ELEMENTS(nIn) GT 1) OR (N_ELEMENTS(kIn) GT 1)) THEN MESSAGE, $
		'N and K must be scalars.'
	n = FLOOR(nIn[0])
	IF (N_PARAMS() EQ 2) THEN kIn = 0   ; default
	k = kIn[0]
	IF (n LT 0) OR (k LT 0) THEN MESSAGE, $
		'Arguments N and K must be greater than or equal to zero.'

; keyword checking
	tname = SIZE(x,/TNAME)
	IF (N_ELEMENTS(double) LT 1) THEN $
		double = (tname EQ 'DOUBLE') OR (tname EQ 'DCOMPLEX') $
	ELSE double = KEYWORD_SET(double)


; convert x (if necessary) to desired precision
	CASE tname OF
		'DOUBLE': xPrec = double ? x : FLOAT(x)
		'DCOMPLEX': xPrec = double ? x : COMPLEX(x)
		ELSE: xPrec = x  ; no need to convert
	ENDCASE

	one = double ? 1d : 1.0

	IF (n EQ 0) THEN BEGIN
		result = one + 0*xPrec
	ENDIF ELSE BEGIN
		; need constants for recursive relation
		Lnm1 = one
		result = -xPrec + k + one
		; construct polynomial coefficients using recursive relation
		; nL(n,k) = -xL(n-1,k) + (2n+k-1)L(n-1,k) - (n+k-1)L(n-2,k)
		FOR i=2L,n DO BEGIN
			Lnm2 = Lnm1   ; save L(n-2,k)
			Lnm1 = result ; save L(n-1,k)
			result = ((-xPrec + 2*i + k - 1)*Lnm1 - (i + k - 1)*Lnm2)/i
		ENDFOR
	ENDELSE

	m = LINDGEN(n+1)
	coefficients = ((-1d)^m)*GAMMA(n+k+1d)/ $
		(GAMMA(n-m+1d)*GAMMA(k+m+1d)*GAMMA(m+1d))
	IF (NOT double) THEN coefficients = FLOAT(coefficients)
	RETURN, result
END