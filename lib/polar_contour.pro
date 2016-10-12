; $Id: //depot/idl/releases/IDL_80/idldir/lib/polar_contour.pro#1 $
;
; Copyright (c) 1995-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

PRO Polar_Contour, z, theta, r, SHOW_TRIANGULATION=show, DITHER=dither, $
         IRREGULAR=irregular, $
         _Extra = e
;
;+
; NAME:
;	POLAR_CONTOUR
;
; PURPOSE:
;	Produce a contour plot from data in polar coordinates.
;	Data may be in a regular or scattered grid.
; CATEGORY:
;	Graphics.
;
; CALLING SEQUENCE:
;	POLAR_CONTOUR, Z, Theta, R
; INPUTS:
;	Z = data values.  If regulary gridded, Z must have dimensions of
;		(NTheta, NR).
;	Theta = values of theta in radians.  For the regular grid, Theta
;		must have the same number of elements as the first dimension
;		of Z.  For the scattered grid, Theta must have the same number
;		of elements as Z.
;	R = values of radius.  For the regular grid, R
;		must have the same number of elements as the second dimension
;		of Z.  For the scattered grid, R must have the same number
;		of elements as Z.
; KEYWORD PARAMETERS:
;	SHOW_TRIANGULATION = color.  If set, the triangulation connecting
;		the data points is overplotted in the designated color.
; 	DITHER = dither the input points by a small amount (1 part in
; 	        10^5) to avoid ambiguous triangulations.  Regular
; 	        grids frequently make ambiguous triangulations, making
; 	        this keyword necessary.
;
;	Also, most of the keywords accepted by CONTOUR may be specified.
;	Keywords associated with contour following, such as FOLLOW,
;	PATH_xxx, and C_LABELS, are not accepted.

; OUTPUTS:
;	A contour plot is produced.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	Plot is produced on the current graphics output device.
; RESTRICTIONS:
;	None.
; PROCEDURE:
;	The cartesian coordinates of each point are calculated.
;	TRIANGULATE is called to grid the data into triangles.
;	CONTOUR is called to produce the contours from the triangles.
; EXAMPLE:
;		Example with regular grid:
;	nr = 12		;# of radii
;	nt = 18		;# of thetas
;	r = findgen(nr) / (nr-1)   ;Form r and Theta vectors
;	theta = 2 * !pi * findgen(nt) / (nt-1)
;	z = cos(theta*3) # (r-.5)^2   ;Fake function value
;	tek_color
;		Create filled contours:
;	Polar_Contour, z, theta, r, /fill, c_color=[2,3,4,5]
;
;		Example with random (scattered) grid:
;	n = 200
;	r = randomu(seed, n)		;N random r's and Theta's
;	theta = 2*!pi * randomu(seed, n)
;	x = cos(theta) * r		;Make a function to plot
;	y = sin(theta) * r
;	z = x^2 - 2*y
;	Polar_Contour, z, theta, r, Nlevels=10, xrange=[0,1], yrange=[0,1]
;
; MODIFICATION HISTORY:
; 	Written by:	Your name here, Date.
;	January, 1995.	DMS, RSI.
;	AB, 5/4/2001, Switch from using _EXTRA to _STRICT_EXTRA, so that
;		incorrect keywords will cause issue proper messages to
;		be issued instead of being silently ignored.
;-
COMPILE_OPT strictarr

on_error, 2		;Return to caller...
s = size(z)
nz = n_elements(z)

if (s[0] eq 2) and (n_elements(theta) eq s[1]) and $   ;Regular grid case?
   (n_elements(r) eq s[2]) then begin
  tt = theta # replicate(1,n_elements(r))
  ;; If we have zero radii, then we will have ambiguous
  ;; triangulations.  Fudge  it.
  zeroes = where(r eq 0, count)
  if count ne 0 then begin      ;Fudge the center point
      range = max(abs(r))
      rtemp = r
      rtemp[zeroes] = range / 1.0e5 ;Fudge a little
      rr = replicate(1,n_elements(theta)) # rtemp
  endif $
  else rr = replicate(1,n_elements(theta)) # r
  x = rr * cos(tt)
  y = rr * sin(tt)
endif else begin		;Irregular grid
    if n_elements(r) ne nz then message, $
      'R array has wrong number of elements'
    if n_elements(theta) ne nz then message, $
      'Theta array has wrong number of elements'
    x = r * cos(theta)
    y = r * sin(theta)
endelse


if keyword_set(dither) then begin
    eps = 5.0e5                 ;Dither amount
    xmax = max(x, min=xmin)     ;Get extent
    ymax = max(y, min=ymin)
    scale = ((xmax - xmin) > (ymax - ymin)) / eps
    triangulate, x+randomu(seed, n_elements(x))*scale, $
      y + randomu(seed, n_elements(y))*scale, tr
endif else begin
    triangulate, x, y, tr, TOLERANCE=0
endelse

contour, z, x, y, TRIANGULATION=tr, _STRICT_EXTRA=e

if n_elements(show) eq 1 then begin	;Show the triangulation?
    oplot, x, y, /psym, color=show
    for i=0, n_elements(tr)/3-1 do begin
      t = [tr[*,i], tr[0,i]]
      plots, x[t], y[t], color=show
      endfor
    endif
end
