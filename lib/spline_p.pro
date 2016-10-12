; $Id: //depot/idl/releases/IDL_80/idldir/lib/spline_p.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	SPLINE_P
;
; PURPOSE:
;	This procedure performs parameteric cubic spline interpolation.
;
; CATEGORY:
;	Interpolation - E1.
;
; CALLING SEQUENCE:
;	SPLINE_P, X, Y, Xr, Yr
;
; INPUTS:
;	X:	  The abcissa vector (should be floating or double).
;	Y:	  The vector of ordinate values corresponding to X.
;	Neither X or Y need be monotonic.
;
; KEYWORD PARAMETERS:
;   DOUBLE: Set this keyword to force computations to be done
;       using double-precision arithmetic.
;
;	INTERVAL: The interval in XY space between interpolants. If
;		  omitted, approximately 8 interpolants per XY segment
;		  will result.
;	TAN0:	  The tangent to the spline curve at X[0], Y[0]. If omitted,
;		  the tangent is calculated to make the curvature of the
;		  result zero at the beginning. This is a two element vector,
;		  containing the X and Y components of the tangent.
;	TAN1:	  The tangent to the spline curve at X[N-1], Y[N-1].If omitted,
;		  the tangent is calculated to make the curvature of the
;		  result zero at the end. This is a two element vector,
;		  containing the X and Y components of the tangent.
;
; OUTPUTS:
;	XR:	  The abcissa values of the interpolated function. This
;		  may NOT be the same variable as either X or Y.
;	YR:	  The ordinate values of the interpolated function. This
;		  may NOT be the same variable as either X or Y.
;
; RESTRICTIONS:
;	X and Y should be floating or double.
;
; PROCEDURE:
;	Cubic spline interpolation with relaxed or clamped end conditions
;	as used in the Numerical Recipes.
;
;	This routine is both more general and faster than the
;	user's library function SPLINE. One call to SPLINE_P is equivalent
;	to two calls to SPLINE, as both the X and Y are interpolated with
;	splines. It is suited for interpolating between randomly
;	placed points, and the abcissae	values need not be monotonic.
;	In addition, the end conditions may be optionally specified via
;	tangents.
;
; EXAMPLE:
;	The commands below show a typical use of SPLINE_P:
;	  X = [0.,1,0,-1,0]	  ;Abcissae for square with a vertical diagonal
;	  Y = [0.,1,2,1,0]	  ;Ordinates
;	  SPLINE_P, X, Y, XR, YR  ;Interpolate with relaxed end conditions
;	  PLOT, XR, YR		  ;Show it
;
; 	As above, but with setting both the beginning and end tangents:
; 	  SPLINE_P, X, Y, XR, YR, TAN0=[1,0], TAN1=[1,0]
;
; 	This yields approximately 32 interpolants.
;
; 	As above, but with setting the interval to 0.05, making more
;	interpolants, closer together:
; 	  SPLINE_P, X, Y, XR, YR, TAN0=[1,0], TAN1=[1,0], INTERVAL=0.05
;
; 	This yields 116 interpolants and looks close to a circle.
;
; MODIFICATION HISTORY:
;	DMS, RSI.	August, 1993.	Written.
;	DMS, RSI.	Jan, 1994.  Modified to use NR_ spline routines.
;   CT, RSI, July 2003: Quietly discard repeated points,
;       add double-precision support and DOUBLE keyword.
;   CT, RSI, April 2005: If the first and last points are identical,
;       don't discard the first point.
;-

PRO SPLINE_P, xIn, yIn, xr, yr, $
	INTERVAL=interval, TAN0=tan0, TAN1=tan1, $
	DOUBLE=double

    compile_opt idl2

    ON_ERROR, 2

    if N_ELEMENTS(xIn) ne N_ELEMENTS(yIn) then $
	    message,'X and Y must have the same number of points'

    ; Interpoint Distance
    distance = sqrt((xIn - shift(xIn,1))^2 + (yIn - shift(yIn,1))^2)

    ; Just in case the first and last points are identical,
    ; we temporarily force the first point to have a nonzero distance,
    ; so it will pass our repeated point test below.
    wasSame = distance[0] eq 0
    distance[0] = 1

    ; Quietly discard repeated points.
    good = WHERE(distance gt 0, n)
    if (n eq 0 || (n eq 1 && wasSame)) then $
        MESSAGE, 'All points are identical.'

    x = xIn[good]
    y = yIn[good]
    distance = distance[TEMPORARY(good)]

    ; Set the first point distance back to zero.
    distance[0] = 0

    ni = n-1		;Number of intervals
    big = 2.0e30

    ; Default interval = approx 8 points per interval....
    if n_elements(interval) le 0 then interval = total(distance) / (8*ni)

    r = ceil(distance/interval)		;# of elements in each interval
    nr = long(total(r))		;# of elements in result

    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        (SIZE(xIn,/TYPE) eq 5) || (SIZE(yIn,/TYPE) eq 5)
    tt = dbl ? DBLARR(nr+1, /NOZERO) : FLTARR(nr+1, /NOZERO)
    j = 0L

    for int = 0, ni-1 do begin	;Each interval
        i1 = int+1
        nn = r[i1]			;# pnts in this interval
        tt[j] = distance[i1] / nn * findgen(nn) + distance[int]
        distance[i1] = distance[i1] + distance[int]
        j = j + nn
    endfor
    tt[nr] = distance[int]

    ; Use end tangents, or use relaxed condition.
    if n_elements(tan0) ge 2 then begin	;Clamped on left?
        xp0 = tan0[0]
        yp0 = tan0[1]
    endif else begin			;Relaxed
        xp0 = big
        yp0 = big
    endelse

    if n_elements(tan1) ge 2 then begin	;Clamped on right?
        xpn = tan1[0]
        ypn = tan1[1]
    endif else begin
        xpn = big
        ypn = big
    endelse

    ; Compute result
    secondDeriv = SPL_INIT(distance, x, yp1 = xp0, ypn = xpn, DOUBLE=dbl)
    xr = SPL_INTERP(distance, x, secondDeriv, tt, DOUBLE=dbl)
    secondDeriv = SPL_INIT(distance, y, yp1 = yp0, ypn = ypn, DOUBLE=dbl)
    yr = SPL_INTERP(distance, y, secondDeriv, tt, DOUBLE=dbl)

end
