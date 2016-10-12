; $Id: //depot/idl/releases/IDL_80/idldir/lib/sph_4pnt.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       SPH_4PNT
;
; PURPOSE:
;       Given four 3-dimensional points, this procedure returns the
;       center and radius necessary to define the unique sphere passing
;       through those points.
;
; CATEGORY:
;       Analytic Geometry.
;
; CALLING SEQUENCE:
;       SPH_4PNT, X, Y, Z, Xc, Yc, Zc, R
;
; INPUTS:
;       X: A 4-element vector containing the X coordinates of the points.
;       Y: A 4-element vector containing the Y coordinates of the points.
;       Z: A 4-element vector containing the Z coordinates of the points.
;
;	Note: X, Y, and Z should be floating-point or double-precision
;	      vectors.
;
; OUTPUTS:
;       Xc: The sphere's center x-coordinate. 
;       Yc: The sphere's center y-coordinate.
;       Zc: The sphere's center z-coordinate.
;       R:  The sphere's radius.
;
; RESTRICTIONS:
;       Points may not coincide.
;
; EXAMPLE:
;       Find the center and radius of the unique sphere passing through
;       the points: (1, 1, 0), (2, 1, 2), (1, 0, 3), (1, 0, 1)
;       
;       Define the floating-point vectors containing the x, y and z 
;       coordinates of the points. 
;         X = [1, 2, 1, 1] + 0.0
;	  Y = [1, 1, 0, 0] + 0.0
;	  Z = [0, 2, 3, 1] + 0.0
;
;       Compute the sphere's center and radius.
;         SPH_4PNT, X, Y, Z, Xc, Yc, Zc, R
;
;       Print the results.
;         PRINT, Xc, Yc, Zc, R
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, Jan 1993
;       Modified:    GGS, RSI, March 1994
;                    Rewrote documentation header.
;                    Uses the new Numerical Recipes NR_LUDCMP/NR_LUBKSB.
;       Modified:    GGS, RSI, November 1994
;                    Changed internal array from column major to row major.
;                    Changed NR_LUDCMP/NR_LUBKSB to LUDC/LUSOL
;       Modified:    GGS, RSI, June 1995
;                    Added DOUBLE keyword.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;-

PRO SPH_4PNT, X, Y, Z, Xc, Yc, Zc, R, Double = Double

  ON_ERROR, 2

  if N_PARAMS() ne 7 then $
    MESSAGE, "Incorrect number of arguments."

  TypeX = SIZE(X) & TypeY = SIZE(Y) & TypeZ = SIZE(Z)

  if TypeX[TypeX[0]+2] ne 4 or $
     TypeY[TypeY[0]+2] ne 4 or $
     TypeZ[TypeZ[0]+2] ne 4 then $
     MESSAGE, "X, Y, and Z coordinates are of incompatible size."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are determined by the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeX[TypeX[0]+1] eq 5 or $
              TypeY[TypeY[0]+1] eq 5 or $
              TypeZ[TypeZ[0]+1] eq 5)

  if Double eq 0 then A = FLTARR(3,3) else A = DBLARR(3,3)

  ;Define the relationships between X, Y and Z as the linear system.
    for k = 0, 2 do begin
      A[0, k] = X[k] - X[k+1]
      A[1, k] = Y[k] - Y[k+1]
      A[2, k] = Z[k] - Z[k+1]
    endfor

  ;Define right-side of linear system.
    Q = X^2 + Y^2 + Z^2
    C = 0.5 * (Q[0:2] - Q[1:3])

  ;Solve the linear system Ay = c where y = (Xc, Yc, Zc)
    LUDC, A, Index, Double = Double
  ;Solution y is stored in C
    C = LUSOL(A, Index, C, Double = Double)

  ;The sphere's center x-coordinate.
    Xc = C[0]

  ;The sphere's center y-coordinate.
    Yc = C[1]

  ;The sphere's center z-coordinate.
    Zc = C[2]

  ;The sphere's radius.
    R = SQRT(Q[0] - 2*(X[0]*Xc + Y[0]*Yc + Z[0]*Zc) + Xc^2 + Yc^2 + Zc^2)

END
