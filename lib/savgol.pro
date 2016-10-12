; $Id: //depot/idl/releases/IDL_80/idldir/lib/savgol.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	SAVGOL
;
; PURPOSE:
;	Return the coefficients of a Savitzky-Golay smoothing filter,
;	which may then be used with CONVOL() for smoothing and
;	optionally for numeric differentiation.
;
; CATEGORY:
;	Smoothing, differentiation, digital filter, filter
;
; CALLING SEQUENCE:
;	Kernel = SAVGOL(Nleft, Nright, Order, Degree)
;
; INPUTS:
;	Nleft = An integer specifying the number of data points
;           used to the left of each point.
;
;	Nright = An integer specifying the number of data points
;            used to the right of each point.
;            The total width of the filter is Nleft + Nright + 1.
;
;	Order = An integer specifying the order of the derivative desired.
;           For example, set Order to 0 for the smoothed function,
;           Order to 1 for the smoothed first derivative, etc.
;           Order must be less than or equal to degree.
;
;	Degree = An integer specifying the degree of smoothing polynomial.
;            Typical values are 2, 4, or 6.
;            Degree must be less than the filter width.
;
; KEYWORD PARAMETERS:
;	DOUBLE = Set this keyword to do the calculation in double precision.
;            This is suggested for Degree greater than 9.
;
; OUTPUTS:
;	Result = the desired smoothing kernel.
;            Use CONVOL to apply this kernel to each dataset.
;
; PROCEDURE:
;	SAVGOL returns a kernel array that when used
;	with CONVOL, fits a polynomial of the desired degree to each
;	local neighborhood of a dataset with equally spaced points.
;
;	The coefficients returned by SAVGOL() do not depend on the data
;	to be fitted, but depend only on the extent of the window, the
;	degree of the polynomial used for the fit, and the order of the
;	desired derivative.
;
;   SAVGOL is based on the Numerical Recipes routine described in
;   section 14.8 of Numerical Recipes in C: The Art of Scientific Computing
;   (Second Edition), published by Cambridge University Press, and is used
;   by permission. This routine is written in the IDL language.
;   Its source code can be found in the file savgol.pro in the lib
;   subdirectory of the IDL distribution.
;
; EXAMPLE:
; The code below creates a noisy 800-point vector, with 8 gaussian peaks of
; decreasing width.  It then plots the vector, the vector smoothed
; with a 33-point Boxcar smoother (SMOOTH), and the vector smoothed
; with 33-point wide Savitsky-Golay filters of degree 4 and 6.
;
; It may be seen that the Savitsky-Golay filters do a much better job
; of preserving the narrower peaks, when compared to SMOOTH.
;
; n = 800                         ;# of points
; np = 8                          ;# of peaks
; y = replicate(0.5, n)           ;Form baseline
; x = findgen(n)                  ;Index array
; for i=0, np-1 do begin          ;Add each Gaussian peak
;     c = (i + 0.5) * float(n)/np ;Center of peak
;     y = y + exp(-(2 * (x-c) / (75. / 1.5 ^ i))^2)  ;Add Gaussian
; endfor
;
; !p.multi=[0,1,4]                ;Display 4 plots
; y1 = y + 0.10 * randomn(-121147, n) ;Add noise, StDev = 0.10
;
; plot, y1, TITLE='Noisy Data'    ;Show effects of different filters
; plot, y, LINESTYLE=1, TITLE='Smooth of 33'
; oplot, smooth(y1, 33, /EDGE_TRUNCATE)
; plot, y, LINESTYLE=1, TITLE='S-G of (16,16,4)'
; oplot, convol(y1, savgol(16, 16, 0, 4), /EDGE_TRUNCATE)
; plot, y, LINESTYLE=1, TITLE='S-G of (16,16,6)'
; oplot, convol(y1, savgol(16, 16, 0, 6), /EDGE_TRUNCATE)
;
;
; MODIFICATION HISTORY:
;	DMS	RSI	January, 2000
;   CT RSI February 2000: added error checking. Changed argument names.
;          Added /DOUBLE keyword.
;-

function savgol, nleft_in, nright_in, order_in, degree_in, $
	DOUBLE=double
; nLeft, nRight = number of points to left and right to use.
; order = order of derivative, 0 for fcn, 1 for 1st deriv, etc.
; degree = order of smoothing polynomial, usually 2 or 4.

ON_ERROR, 2
IF (N_PARAMS() NE 4) THEN MESSAGE, $
	'Incorrect number of arguments. r = SAVGOL(Nleft,Nright,Order,Degree)'
nLeft = nleft_in[0]   ; change 1-element vectors into scalars
nRight = nright_in[0]
order = order_in[0]
degree  = degree_in[0]
IF ((nLeft LT 0) OR (nRight LT 0)) THEN MESSAGE, $
	'Nleft and Nright must both be positive.'
IF (order GT degree) THEN MESSAGE, $
	'Order must be less than or equal to Degree.'

np = nLeft + nRight + 1                ;# of parameters to return
IF (degree GE np) THEN MESSAGE, $
	'Degree must be less than filter width.'

double = KEYWORD_SET(double)


IF (double) THEN BEGIN
	a = DBLARR(degree+1, degree+1)
	b = DBLARR(degree+1)                 ;Right hand side of equations
	cr = DINDGEN(nRight > 1) + 1d
	cl = -(DINDGEN(nLeft > 1) + 1d)
	power = DINDGEN(degree+1)
	c = DBLARR(np)                  ;Result array
ENDIF ELSE BEGIN
	a = fltarr(degree+1, degree+1)
	b = fltarr(degree+1)                 ;Right hand side of equations
	cr = findgen(nRight > 1) + 1.
	cl = -(findgen(nLeft > 1) + 1.)
	power = FINDGEN(degree+1)
	c = fltarr(np)                  ;Result array
ENDELSE

for ipj = 0, degree*2 do begin       ;Make the coefficient matrix
	sum = (ipj EQ 0) ? 1.0 : 0.0
	IF (nRight GT 0) THEN sum = sum + total(cr ^ ipj)
	IF (nLeft GT 0) THEN sum = sum + total(cl ^ ipj)
    mm = ipj < (2 * degree - ipj)
    for imj = -mm, mm, 2 do a[(ipj+imj)/2, (ipj-imj)/2] = sum
endfor

ludc, a, Indx, DOUBLE=double
b[order] = 1                     ;= 1 for the derivative we want.
b = lusol(a, Indx, b, DOUBLE=double)           ;Solve the system of equations
for k=-nLeft, nRight do c[k+nLeft] = total(b * k ^ power, DOUBLE=double)

return, c
end
