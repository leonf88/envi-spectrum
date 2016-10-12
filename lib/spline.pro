; $Id: //depot/idl/releases/IDL_80/idldir/lib/spline.pro#1 $
;
; Copyright (c) 1983-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	SPLINE
;
; PURPOSE:
;	This function performs cubic spline interpolation.
;
; CATEGORY:
;	Interpolation - E1.
;
; CALLING SEQUENCE:
;	Result = SPLINE(X, Y, T [, Sigma])
;
; INPUTS:
;	X:	The abcissa vector. Values MUST be monotonically increasing.
;
;	Y:	The vector of ordinate values corresponding to X.
;
;	T:	The vector of abcissae values for which the ordinate is
;		desired. The values of T MUST be monotonically increasing.
;
; OPTIONAL INPUT PARAMETERS:
;	Sigma:	The amount of "tension" that is applied to the curve. The
;		default value is 1.0. If sigma is close to 0, (e.g., .01),
;		then effectively there is a cubic spline fit. If sigma
;		is large, (e.g., greater than 10), then the fit will be like
;		a polynomial interpolation.
;
; KEYWORDS:
;   DOUBLE: Set this keyword to force computations to be done
;       using double-precision arithmetic.
;
; OUTPUTS:
;	SPLINE returns a vector of interpolated ordinates.
;	Result(i) = value of the function at T(i).
;
; RESTRICTIONS:
;	Abcissa values must be monotonically increasing.
;
; EXAMPLE:
;	The commands below show a typical use of SPLINE:
;
;		X = [2.,3.,4.]  	;X values of original function
;		Y = (X-3)^2     	;Make a quadratic
;		T = FINDGEN(20)/10.+2 	;Values for interpolated points.
;					;twenty values from 2 to 3.9.
;		Z = SPLINE(X,Y,T) 	;Do the interpolation.
;
; MODIFICATION HISTORY:
;	Author:	Walter W. Jones, Naval Research Laboratory, Sept 26, 1976.
;	Reviewer: Sidney Prahl, Texas Instruments.
;	Adapted for IDL: DMS, March, 1983.
;   CT, RSI, July 2003: Added double precision support and DOUBLE keyword,
;       use vector math to speed up the loops.
;   CT, RSI, August 2003: Must have at least 3 points.
;
;-

function spline,x,y,t,sigmaIn, DOUBLE=double

    compile_opt idl2

    on_error,2                      ;Return to caller if an error occurs

    n = N_ELEMENTS(x) < N_ELEMENTS(y)
    if (n le 2) then $
        MESSAGE, 'X and Y must be arrays of 3 or more elements.'

    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        (SIZE(x,/TYPE) eq 5) || (SIZE(y,/TYPE) eq 5) || (SIZE(t,/TYPE) eq 5)

    sigma = (n_params(0) lt 4) ? (dbl ? 1d : 1.0) : $
        (sigmaIn > (dbl ? 0.001d : 0.001))  ;in range?

    xx = dbl ? DOUBLE(x) : FLOAT(x)
    yy = dbl ? DOUBLE(y) : FLOAT(y)
    tt = dbl ? DOUBLE(t) : FLOAT(t)
    yp = dbl ? DBLARR(2*n) : FLTARR(2*n)  ;temp storage

    delx1 = xx[1] - xx[0]		;1st incr
    dx1 = (yy[1] - yy[0])/delx1

    nm1 = n - 1L
    np1 = n + 1L

    delx2 = xx[2]-xx[1]
    delx12 = xx[2]-xx[0]
    c1 = -(delx12+delx1)/delx12/delx1
    c2 = delx12/delx1/delx2
    c3 = -delx1/delx12/delx2

    slpp1 = c1*yy[0]+c2*yy[1]+c3*yy[2]
    deln = xx[nm1]-xx[nm1-1]
    delnm1 = xx[nm1-1]-xx[nm1-2]
    delnn = xx[nm1]-xx[nm1-2]
    c1 = (delnn+deln)/delnn/deln
    c2 = -delnn/deln/delnm1
    c3 = deln/delnn/delnm1
    slppn = c3*yy[nm1-2]+c2*yy[nm1-1]+c1*yy[nm1]

    sigmap = sigma*nm1/(xx[nm1]-xx[0])
    dels = sigmap*delx1
    exps = exp(dels)
    sinhs = 0.5d*(exps-1./exps)
    sinhin = 1./(delx1*sinhs)
    diag1 = sinhin*(dels*0.5d*(exps+1./exps)-sinhs)
    diagin = 1./diag1
    yp[0] = diagin*(dx1-slpp1)
    spdiag = sinhin*(sinhs-dels)
    yp[n] = diagin*spdiag

    ; Do as much work using vectors as possible.
    delx2 = xx[1:*] - xx
    dx2 = (yy[1:*] - yy)/delx2
    dels = sigmap*delx2
    exps = exp(dels)
    sinhs = 0.5d *(exps-1./exps)
    sinhin = 1./(delx2*sinhs)
    diag2 = sinhin*(dels*(0.5d*(exps+1./exps))-sinhs)
    diag2 = [0, diag2 + diag2[1:*]]
    dx2nm1 = dx2[nm1-1] ; need to save this to calc yp[nm1]
    dx2 = [0, dx2[1:*] - dx2]
    spdiag = sinhin*(sinhs-dels)

    ; Need to do an iterative loop for this part.
    for i=1L,nm1-1 do begin
        diagin = 1./(diag2[i] - spdiag[i-1]*yp[i+n-1])
        yp[i] = diagin*(dx2[i] - spdiag[i-1]*yp[i-1])
        yp[i+n] = diagin*spdiag[i]
    endfor


    diagin = 1./(diag1-spdiag[nm1-1]*yp[n+nm1-1])
    yp[nm1] = diagin*(slppn-dx2nm1-spdiag[nm1-1]*yp[nm1-1])
    for i=n-2,0,-1 do $
        yp[i] = yp[i] - yp[i+n]*yp[i+1]

    m = n_elements(t)
    subs = replicate(long(nm1),m) ;subscripts
    s = xx[nm1]-xx[0]
    sigmap = sigma*nm1/s

    j = 0L
    for i=1L,nm1 do begin ;find subscript where xx[subs] > t(j) > xx[subs-1]
        while tt[j] lt xx[i] do begin
            subs[j]=i
            j++
            if j eq m then goto,done
        endwhile
    endfor


done:
    subs1 = subs - 1
    del1 = tt-xx[subs1]
    del2 = xx[subs] - tt
    dels = xx[subs]-xx[subs1]
    exps1 = exp(sigmap*del1)
    sinhd1 = 0.5*(exps1-1./exps1)
    exps = exp(sigmap*del2)
    sinhd2 = 0.5*(exps-1./exps)
    exps = exps1*exps
    sinhs = 0.5*(exps-1./exps)
    spl = (yp[subs]*sinhd1+yp[subs1]*sinhd2)/sinhs + $
        ((yy[subs]-yp[subs])*del1+(yy[subs1]-yp[subs1])*del2)/dels

    return, (m eq 1) ? spl[0] : spl


end
