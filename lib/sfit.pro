; $Id: //depot/idl/releases/IDL_80/idldir/lib/sfit.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

function sfit, z, degree, KX=kx, IRREGULAR=irreg_p, MAX_DEGREE=max_p
;+
; NAME:
;	SFIT
;
; PURPOSE:
;	This function determines a polynomial fit to a surface sampled
;	  over a regular or irregular grid.
;
; CATEGORY:
;	Curve and surface fitting.
;
; CALLING SEQUENCE:
;	Result = SFIT(Data, Degree)    ;Regular input grid
;	Result = SFIT(Data, Degree, /IRREGULAR)  ;Irregular input grid
;
; INPUTS:
; 	Data:	The array of data to fit. If IRREGULAR
; 	is not set, the data are assumed to be sampled over a regular 2D
; 	grid, and should be in an Ncolumns by Nrows array.  In this case, the
; 	column and row subscripts implicitly contain the X and Y
; 	location of the point.  The sizes of the dimensions may be unequal.
;	If IRREGULAR is set, Data is a [3,n] array containing the X,
;	Y, and Z location of each point sampled on the surface.  
;
;	Degree:	The maximum degree of fit (in one dimension).
;
; KEYWORDS:
; 	IRREGULAR: If set, Data is [3,n] array, containing the X, Y,
; 	  and Z locations of n points sampled on the surface.  See
; 	  description above.
; 	MAX_DEGREE: If set, the Degree parameter represents the
; 	    maximum degree of the fitting polynomial of all dimensions
; 	    combined, rather than the maximum degree of the polynomial
; 	    in a single variable. For example, if Degree is 2, and
; 	    MAX_DEGREE is not set, then the terms returned will be
; 	    [[K, y, y^2], [x, xy, xy^2], [x^2, x^2 y, x^2 y^2]].
; 	    If MAX_DEGREE is set, the terms returned will be in a
; 	    vector, [K, y, y^2, x, xy, x^2], in which no term has a
; 	    power higher than two in X and Y combined, and the powers
; 	    of Y vary the fastest. 
;
;
; OUTPUT:
;	This function returns the fitted array.  If IRREGULAR is not
;	set, the dimensions of the result are the same as the
;	dimensions of the Data input parameter, and contain the
;	calculated fit at the grid points.  If IRREGULAR is set, the
;	result contains n points, and contains the value of the
;	fitting polynomial at the sample points.
;
; OUTPUT KEYWORDS:
;	Kx:	The array of coefficients for a polynomial function
;		of x and y to fit data. If MAX_DEGREE is not set, this
;		parameter is returned as a (Degree+1) by (Degree+1)
;		element array.  If MAX_DEGREE is set, this parameter
;		is returned as a (Degree+1) * (Degree+2)/2 element
;		vector. 
;
; PROCEDURE:
; 	Fit a 2D array Z as a polynomial function of x and y.
; 	The function fitted is:
;  	    F(x,y) = Sum over i and j of kx[j,i] * x^i * y^j
; 	where kx is returned as a keyword.  If the keyword MAX_DEGREE
; 	is set, kx is a vector, and the total of the X and Y powers will
; 	not exceed DEGREE, with the Y powers varying the fastest.
;
; MODIFICATION HISTORY:
;	July, 1993, DMS		Initial creation
;	July, 2001		Added MAX_DEGREE and IRREGULAR keywords.
;
;-

   on_error, 2

   s = size(z)
   irreg = keyword_set(irreg_p)
   max_deg = keyword_set(max_p)
   n2 = max_deg ? (degree+1) * (degree+2) / 2 : (degree+1)^2 ;# of coeff to solve

   if irreg then begin
       if (s[0] ne 2) or (s[1] ne 3) then $
         message, 'For IRREGULAR grids, input must be [3,n]'
       m = n_elements(z) / 3    ;# of points
       x = double(z[0,*])       ;Do it in double...
       y = double(z[1,*])
       zz = double(z[2,*])
   endif else begin             ;Regular
       if s[0] ne 2 then message, 'For regular grids, input must be [nx, ny]'
       nx = s[1]
       ny = s[2]
       m = nx * ny		;# of points to fit
       x = findgen(nx) # replicate(1., ny) ;X values at each point
       y = replicate(1.,nx) # findgen(ny)
   endelse

   if n2 gt m then message, 'Fitting degree of '+strtrim(degree,2)+$
     ' requires ' + strtrim(n2,2) + ' points.'
   ut = dblarr(n2, m, /nozero)
   k = 0L
   for i=0, degree do for j=0,degree do begin ;Fill each column of basis
       if max_deg and (i+j gt degree) then continue
       ut[k, 0] = reform(x^i * y^j, 1, m)
       k = k + 1
   endfor

   kk = invert(ut # transpose(ut)) # ut
   kx = float(kk # reform(irreg ? zz : z, m, 1)) ;Coefficients
   if max_deg eq 0 then kx = reform(kx, degree+1, degree+1)

   return, irreg ? reform(reform(kx,n2) # ut, m) : $ ;Return the fit
     reform(reform(kx,n2) # ut, nx, ny)   
end
