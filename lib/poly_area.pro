; $Id: //depot/idl/releases/IDL_80/idldir/lib/poly_area.pro#1 $
;
; Copyright (c) 1984-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   POLY_AREA
;
; PURPOSE:
;   Return the area of a polygon given the coordinates
;   of its vertices.
;
; CATEGORY:
;   Analytical Geometry
;
; CALLING SEQUENCE:
;   Result = POLY_AREA(X, Y)
;
; INPUTS:
;   It is assumed that the polygon has N vertices with N sides
;   and the edges connect the vertices in the order:
;
;   [(x1,y1), (x2,y2), ..., (xn,yn), (x1,y1)].
;
;   i.e. the last vertex is connected to the first vertex.
;
;   X:  An N-element vector of X coordinate locations for the vertices.
;
;   Y:  An N-element vector of Y coordinate locations for the vertices.
;
; Keyword Inputs:
;   SIGNED = If set, returned a signed area. Polygons with edges
;   listed in counterclockwise order have a positive area, while those
;   traversed in the clockwise direction have a negative area.
;   DOUBLE = Set this keyword to force the computation to be done using
;      double-precision arithmetic.
; OUTPUTS:
;   POLY_AREA returns the area of the polygon.  This value is
;   positive, unless the SIGNED keyword is set and the polygon is
;   in clockwise order.
;
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   None.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;   The area is computed as:
;       Area =  1/2 * [ x1y2 + x2y3 + x3y4 +...+x(n-1)yn + xny1
;           - y1x2 - y2x3 -...-y(n-1)xn - ynx1)
;
; MODIFICATION HISTORY:
;   DMS, July, 1984.
;   DMS, Aug, 1996, Added SIGNED keyword.
;   CT, Nov 2000, Add DOUBLE keyword, subtract offsets to improve accuracy.
;-
Function Poly_area,x,y, SIGNED=signed, DOUBLE=double
COMPILE_OPT strictarr

on_error,2                      ;Return to caller if an error occurs
n = n_elements(x)
if (n le 2) then message, 'Not enough vertices'
if n ne n_elements(y) then message,'X and Y arrays must have same size'

; Check type of arithmetic result
dbl = SIZE(1d, /TYPE)
do_double = (SIZE(x, /TYPE) eq dbl) or (SIZE(y, /TYPE) eq dbl)
IF (N_ELEMENTS(double) GT 0) THEN do_double = KEYWORD_SET(double)

; force conversion to float or double if necessary
xx = do_double ? DOUBLE(x) : FLOAT(x)
yy = do_double ? DOUBLE(y) : FLOAT(y)
xx = xx - xx[0]
yy = yy - yy[0]
a = total(xx*shift(yy,-1) - yy*shift(xx,-1))/2.

if keyword_set(signed) then return, a else return, abs(a)
end
