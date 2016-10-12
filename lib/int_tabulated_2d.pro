; $Id: //depot/idl/releases/IDL_80/idldir/lib/int_tabulated_2d.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	INT_TABULATED_2D
;
; PURPOSE:
;	Integrate the volume formed by a surface defined by tabulated
;	data, (x[i], y[i], f[i]), and the XY plane, over the area
;	defined by the convex hull of the set of points (x,y).
;
; CATEGORY:
;	Numerical Analysis.
;
; CALLING SEQUENCE:
;	Result = INT_TABULATED_2D(X, Y, F)
;
; INPUTS:
;       X:  The array of tabulated X-value data. This data may be
;           irregularly gridded and in random order.
;       Y:  The tabulated Y-value data, Y[i] corresponds to X[i].
;       F:  The tabulated F-value data. F[i] is the function's value
;           at the point (X[i],Y[i]).;
;       X Y, and F must be of floating point or double precision type.
;
; OUTPUTS:
;       This fuction returns the integral of F computed from the tabulated
;	data over the convex hull defined by the points in (X,Y).
;	Linear interpolation is used.
;
; PROCEDURE:
;	The (X,Y) points are triangulated using TRIANGULATE.  Then for
;	each triangle, in the convex hull, formed by points X[[i,j,k]]
;	and Y[[i,j,k]], the volume of the triangular cylinder formed
;	by the 6 points:
;	(X[i], Y[i], Z[i]), (X[j], Y[j], Z[j]), (X[i], Y[k], Z[k]), 
;	(X[i], Y[i], 0), (X[j], Y[j], 0), and (X[k], Y[k], 0), is
;	computed and summed.
;
; EXAMPLE:
;	Compute the volume between the surface f=x^2+y^2 and the XY
;	plane, over the	interval of x=-1 to +1, y=-1 to 1, with a grid
;	increment of 0.1:
;	n = 21
;	x = (findgen(n) * (2./(n-1)) - 1.0) # replicate(1.0, n)
;	y = transpose(x)
;	f = x^2 + y^2
;	print, int_tabulated_2d(x,y,f)
;	   2.68000
;	(The correct answer computed symbolically is 8/3 = 2.66667)
;
; MODIFICATION HISTORY:
;	DMS, August, 1998.
;-

Function TetraVolume, x, y, z
; Return the signed volume of a tetrahedron with 4 vertices contained in the
; x, y, and z arrays.  If the vertices are ordered counter-clockwise,
; looking from the side opposite vertex [0], then the volume is
; positive, otherwise its negative.

xx = x[1:3]-x[0]                ;Translate one point to the origin
yy = y[1:3]-y[0]
zz = z[1:3]-z[0]

s = (xx[0] * (yy[1]*zz[2] - yy[2]*zz[1]) + $ ;Compute the 3x3 determinant
     yy[0] * (zz[1]*xx[2] - zz[2]*xx[1]) + $
     zz[0] * (xx[1]*yy[2] - xx[2]*yy[1]))
return, s/6.
end

; Old method, now coded in-line.
; Function TriCyl_volume, x, y, z
; ; Determine the volume of a triangular cylinder...  Base is the
; ; triangle with vertices index [0,1,2], all with Z value = 0.  Top is
; ; given by the vertices [3,4,5].  X and Y values for vertices 0 and 3,
; ; 1 and 4, 2 and 5 are identical.
; s = 0.0
; ; Composed of 3 tetrahedra with these vertices. 
; v = [[0,1,2,4],[0,2,5,4],[0,4,5,3]]
; for i=0,2 do begin
;     t = v[*,i]
;     s = s + TetraVolume(x[t],y[t],z[t])
; endfor
; return, s
; end


Function INT_TABULATED_2D, x, y, z

triangulate, x, y, tr
; Subscript indices for the 3 tetrahedra formed with vertex 0 as one
; point. The faces must be order CCW when looking from the side away
; from vertex 0.
s0 = [0,1,2,1]
s1 = [0,2,2,1]
s2 = [0,1,2,0]

vol = 0.0
for i=0, n_elements(tr)/3-1 do begin ;Sum each triangle
    t = tr[*,i]
    x1 = x[t]                   ;Save vertices of this triangle
    y1 = y[t]
    z1 = z[t]
; Sum the three tetrahedra that make this triangular cylinder.
    p = TetraVolume(x1[s0], y1[s0], [0,0,0,z1[1]]) + $
      TetraVolume(x1[s1], y1[s1], [0,0,z1[2],z1[1]]) + $
      TetraVolume(x1[s2], y1[s2], [0,z1[1],z1[2],z1[0]])
    vol = vol + p
endfor
return, vol
end
