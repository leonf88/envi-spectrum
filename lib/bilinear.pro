; $Id: //depot/idl/releases/IDL_80/idldir/lib/bilinear.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	BILINEAR
;
; PURPOSE:
;	Bilinearly interpolate a set of reference points.
;
; CALLING SEQUENCE:
;	Result = BILINEAR(P, IX, JY)
;
; INPUTS:
;	P:  A two-dimensional data array.
;
;	IX and JY:  The "virtual subscripts" of P to look up values
;	  for the output.
;
;	IX can be one of two types:
;	     1)	A one-dimensional, floating-point array of subscripts to look
;		up in P.  The same set of subscripts is used for all rows in
;		the output array.
;	     2)	A two-dimensional, floating-point array that contains both
;		"x-axis" and "y-axis" subscripts specified for all points in
;		the output array.
;
;	JY can be one of two types:
;	     1) A one-dimensional, floating-point array of subscripts to look
;		up in P.  The same set of subscripts is used for all rows in
;		the output array.
;	     2) A two-dimensional, floating-point array that contains both
;               "x-axis" and "y-axis" subscripts specified for all points in
;               the output array.
;
;   Note: Location points outside the bounds of the array Pƒàúthat is,
;      elements of the IX or IY arguments that are either less than
;      zero or greater than the largest subscript in the corresponding
;      dimension of P ƒàú are set equal to the value of the nearest
;      element of P.
;
;  	It is better to use two-dimensional arrays for IX and JY when calling
;  	BILINEAR because the algorithm is somewhat faster.  If IX and JY are
;  	one-dimensional, they are converted to two-dimensional arrays on
;  	return from the function.  The new IX and JY can be re-used on
;	  subsequent calls to take advantage of the faster, 2D algorithm.  The
;	  2D array P is unchanged upon return.
;
; KEYWORDS:
;   MISSING: The value to return for elements outside the bounds of P.
;     The bounds of P are 0 to n-1 and 0 to m-1 where P is an n x m array. 
;
;   Note: If MISSING value is set to a complex number,
;     IDL uses only the real part.
;
; OUTPUT:
;	The two-dimensional, floating-point, interpolated array.
;
; RESTRICTIONS:
;	None.
;
; EXAMPLE:
;	Suppose P = FLTARR(3,3), IX = [.1, .2], and JY = [.6, 2.1] then
;	the result of the command:
;		Z = BILINEAR(P, IX, JY)
;	Z(0,0) will be returned as though it where equal to P(.1,.6)
;	interpolated from the nearest neighbors at P(0,0), P(1,0), P(1,1)
;	and P(0,1).
;
; PROCEDURE:
;	Uses bilinear interpolation algorithm to evaluate each element
;	in the result  at virtual coordinates contained in IX and JY with
;	the data in P.
;
; REVISION HISTORY:
;       Nov. 1985  Written by L. Kramer (U. of Maryland/U. Res. Found.)
;	Aug. 1990  TJA simple bug fix, contributed by Marion Legg of NASA Ames
;	Sep. 1992  DMS, Scrapped the interpolat part and now use INTERPOLATE
;   July 2003, CT: Rewrote to improve error checking and efficiency.
;                  Added MISSING keyword.
;-
function bilinear, p, ix, jy, MISSING=missing

    compile_opt idl2

	ON_ERROR,2              ;Return to caller if an error occurs

	if (N_PARAMS() ne 3) then $
	    MESSAGE, 'Incorrect number of arguments.'

    idim = SIZE(ix, /N_DIMENSIONS)
	jdim = SIZE(jy, /N_DIMENSIONS)
	if (idim gt 2) || (jdim gt 2) then $
	    MESSAGE, 'IX and JY must be vectors or two-dimensional arrays.'

	nx = (SIZE(ix, /DIMENSIONS))[0]
	ny = (SIZE(jy, /DIMENSIONS))[jdim eq 2]

    ; Convert from vector to 2D array.
    ; Note that this replaces the input arguments.
    if (idim eq 1) then $
        ix = REBIN(ix, nx, ny)
	if (jdim eq 1) then $
	    jy = REBIN(TRANSPOSE(jy), nx, ny)

	return, INTERPOLATE(p, ix, jy, MISSING=missing)

end
