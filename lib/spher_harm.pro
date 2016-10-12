; $Id: //depot/idl/releases/IDL_80/idldir/lib/spher_harm.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	SPHER_HARM
;
; PURPOSE:
;	This function returns the value of the spherical harmonic
;   Y(L,M)[theta,phi], |M| <= L, which is a function of two coordinates
;   (theta, phi) on a spherical surface.
;
; CATEGORY:
;	Special Math Functions
;
; CALLING SEQUENCE:
;
;	Result = SPHER_HARM(Theta, Phi, L, M [, /DOUBLE])
;
; INPUTS:
;	Theta: The value of the polar (colatitudinal) coordinate at which Y(L,M)
;       is evaluated. Theta can be either a scalar or an array.
;
;   Phi: The value of the azimuthal (longitudinal) coordinate at which Y(L,M)
;       is evaluated. Phi can be either a scalar or an array.
;
;       If Theta and Phi are both arrays then they must have the same number
;       of elements.
;
;   L: An integer specifying the order L of Y(L,M). If L is of type float
;      then it will be truncated.
;
;   M: An integer, -L <= M <= L, specifying the azimuthal order M of Y(L,M).
;      If M is of type float then it will be truncated.
;
; KEYWORD PARAMETERS:
;	DOUBLE:	Set this keyword to force the computation to be done in
;       double-precision arithmetic.
;
; OUTPUT:
;	The result returned by SPHER_HARM is a complex array that has the
;   same dimensions as the input arrays.
;
; PROCEDURE:
;	Uses LEGENDRE().
;
; EXAMPLE:
;	To visualize the electron probability density for the hydrogen atom
;   in state 3d0. (Feynman, Leighton, and Sands, 1965:
;   The Feynman Lectures on Physics, Calif. Inst. Tech, Ch. 19).
;
; ;define a data cube (N x N x N)
;   n = 41L
;   a = 60*FINDGEN(n)/(n-1) - 29.999  ; [-1,+1]
;   x = REBIN(a, n, n, n)              ; X-coordinates of cube
;   y = REBIN(REFORM(a,1,n), n, n, n)  ; Y-coordinates
;   z = REBIN(REFORM(a,1,1,n), n, n, n); Z-coordinates
;
; ;convert from rectangular (x,y,z) to spherical (phi, theta, r)
;   spherCoord = CV_COORD(FROM_RECT=TRANSPOSE([[x[*]],[y[*]],[z[*]]]), /TO_SPHERE)
;   phi = REFORM(spherCoord[0,*], n, n, n)
;   theta = REFORM(!PI/2 - spherCoord[1,*], n, n, n)
;   r = REFORM(spherCoord[2,*], n, n, n)
;
; ;find electron probability density for hydrogen atom in state 3d0
;
; ;Angular component
;   L = 2   ; state "d" is electron spin L=2
;   M = 0   ; Z-component of spin is zero
;   angularState = SPHER_HARM(theta, phi, L, M)
;
; ;Radial component for state n=3, L=2
;   radialFunction = EXP(-r/2)*(r^2)
;
;   waveFunction = angularState*radialFunction
;   probabilityDensity = ABS(waveFunction)^2
;
;   SHADE_VOLUME, probabilityDensity, 0.1*MEAN(probabilityDensity), vertex, poly
;   oPolygon = OBJ_NEW('IDLgrPolygon', vertex, POLYGON=poly, COLOR=[180,180,180])
;   XOBJVIEW, oPolygon
;
; MODIFICATION HISTORY:
; 	Written by:	CT, RSI, March 2000.
;
;-

FUNCTION spher_harm, theta, phi, Linput, Minput, $
	DOUBLE=double

	COMPILE_OPT strictarr

; error checking
	ON_ERROR, 2
	IF (N_PARAMS() NE 4) THEN MESSAGE, 'Incorrect number of arguments.'
	IF ((N_ELEMENTS(Linput) NE 1) OR (N_ELEMENTS(Minput) NE 1)) THEN $
		MESSAGE,'L and M must be scalars.'
	L = LONG(Linput[0]) ; convert 1-element array to scalar
	M1 = LONG(Minput[0]) ; convert 1-element array to scalar
	IF (L LT 0) THEN MESSAGE, $
		'Argument L must be greater than or equal to zero.'

	M = ABS(M1)
	IF (M GT L) THEN MESSAGE, 'Argument M must be in the range [-L, L].'

	IF (SIZE(theta,/N_DIM) GT 0) AND (SIZE(phi,/N_DIM) GT 0) THEN $
		IF (N_ELEMENTS(theta) NE N_ELEMENTS(phi)) THEN MESSAGE, $
		'Theta or Phi must be scalar, or have the same number of values.'

; keyword checking
	thetaDouble = (SIZE(theta,/TNAME) EQ 'DOUBLE')
	phiDouble = (SIZE(phi,/TNAME) EQ 'DOUBLE')
	double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : $
		(thetaDouble OR phiDouble)

; normalizing factor (always double precision because of FACTORIAL)
	spherHarm = (M1 LT 0) ? (-1)^M : 1   ; handle negative M
	spherHarm = spherHarm*SQRT((2L*L + 1)/(4*!DPI)* $
		FACTORIAL(L - M)/FACTORIAL(L + M))

; define constants 1, I for single or double precision
	one = 1D
	I = DCOMPLEX(0,1)

	IF (NOT double) THEN BEGIN
		one = 1.0
		I = COMPLEX(0,1)
		spherHarm = FLOAT(spherHarm)  ; convert back
	ENDIF

	IF (M NE M1) THEN I = -I  ; complex conjugate for -M

; Polar coordinate
	cosTheta = (double) ? COS(DOUBLE(theta)) : COS(FLOAT(theta))
	Plm = LEGENDRE(TEMPORARY(cosTheta), L, M, DOUBLE=double)  ; P(L,M)
	spherHarm = spherHarm*TEMPORARY(Plm)

; Azimuthal coordinate
	mPhi = (double) ? M*DOUBLE(phi) : M*FLOAT(phi)

; Spherical harmonic
	realPart = spherHarm*COS(Mphi)
	imagPart = TEMPORARY(spherHarm)*SIN(TEMPORARY(Mphi))
	IF (M1 LT 0) THEN imagPart = -TEMPORARY(imagPart)  ; complex conjugate

	RETURN, COMPLEX(TEMPORARY(realPart), TEMPORARY(imagPart), DOUBLE=double)

END
