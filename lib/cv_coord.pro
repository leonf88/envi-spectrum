; $Id: //depot/idl/releases/IDL_80/idldir/lib/cv_coord.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       CV_COORD
;
; PURPOSE:
;       Converts 2-D and 3-D coordinates between the RECTANGULAR, POLAR,
;       CYLINDRICAL, and SPHERICAL coordinate systems.
;
; CATEGORY:
;       Graphics
;
; CALLING SEQUENCE:
;       Coord = CV_COORD()
;
; KEYWORD PARAMETERS:
;
;       FROM_RECT:
;                  A vector of the form [x, y] or [x, y, z], or a (2, n) or
;                  (3, n) array containing rectangular coordinates to convert.
;
;       FROM_POLAR:
;                  A vector of the form [angle, radius], or a (2, n) array of
;                  polar coordinates to convert.
;
;       FROM_CYLIN:
;                  A vector of the form [angle, radius, z], or a (3, n) array
;                  of cylindrical coordinates to convert.
;
;       FROM_SPHERE:
;                  A vector of the form [longitude, latitude, radius], or a
;                  (3, n) array of spherical coordinates to convert.
;
;       TO_RECT:   If set, then rectangular coordinates are returned.
;
;       TO_POLAR:  If set, then polar coordinates are returned.
;
;       TO_CYLIN:  If set, then cylindrical coordinates are returned.
;
;       TO_SPHERE: If set, then spherical coordinates are returned.
;
;       DEGREES:   If set, then the input (and output) coordinates are in
;                  degrees (where applicable). Otherwise, the angles are
;                  in radians.
;
;       DOUBLE: Set this keyword to force the computation to be done in
;               double-precision arithmetic.
;
; OUTPUTS:
;       This function returns the converted coordinate(s) based on which of
;       the "TO_" keywords is used :
;
;          TO_RECT   : If the input coordinates were polar, then a vector
;                      of the form [x, y] or a (2, n) array is returned.
;                      Otherwise, a vector of the form [x, y, z], or a
;                      (3, n) array is returned.
;          TO_POLAR  : A vector of the form [angle, radius], or a (2, n)
;                      array is returned.
;          TO_CYLIN  : A vector of the form [angle, radius, z], or a (3, n)
;                      array is returned.
;          TO_SPHERE : A vector of the form [longitude, latitude, radius],
;                      or a (3, n) array is returned.
;
;       If the value passed to the "FROM_" keyword is double precision, then
;       all calculations are performed in double precision and the returned
;       value is double precision. Otherwise, single precision is used.
;
;       If none of the "FROM_" keywords are specified then 0 is returned.
;       If none of the "TO_" keywords are specified then the input coordinates
;       are returned.
;
; PROCEDURE:
;       When converting from spherical to polar coordinates, the points
;       are first projected along the z axis to the x-y plane to get 2-D
;       rectangular coordinates. The 2-D rectangular coordinates are
;       then converted to polar.
;
; EXAMPLE:
;       ; Convert from spherical to cylindrical coordinates.
;
;       sphere_coord = [[45.0, -60.0, 10.0], [0.0, 0.0, 0.0]]
;       rect_coord = CV_COORD(From_Sphere=sphere_coord, /To_Cylin, /Degrees)
;
;       ; Convert from rectangular to polar coordinates.
;
;       rect_coord = [10.0, 10.0]
;       polar_coord = CV_COORD(From_Rect=rect_coord, /To_Polar)
;
; MODIFICATION HISTORY:
;       Written by:     Daniel Carr, Thu Mar 31 14:42:58 MST 1994
;       CT, RSI, August 2000: Fixed double-precision checks, added /DOUBLE.
;-

FUNCTION CV_COORD, From_Rect=from_rect, From_Polar=from_polar, $
                   From_Cylin=from_cylin, From_Sphere=from_sphere, $
                   To_Rect=to_rect, To_Polar=to_polar, $
                   To_Cylin=to_cylin, To_Sphere=to_sphere, $
                   Degrees=degrees, $
                   DOUBLE=doubleIn

COMPILE_OPT idl2
ON_ERROR, 2  ; return to caller

degrees = KEYWORD_SET(degrees)
isDouble = N_ELEMENTS(doubleIn) GT 0
doDouble = KEYWORD_SET(doubleIn)

CASE 1 OF
(N_Elements(from_rect) GT 1L): BEGIN ; Convert from rectangular.
   sz_from = Size(from_rect)
   doDouble = isDouble ? doDouble : $
      SIZE(from_rect, /TNAME) EQ 'DOUBLE'
   IF (sz_from[0] EQ 1L) THEN $
      sz_from = [2L, sz_from[1], 1L, sz_from[2], sz_from[3]]

   IF doDouble THEN BEGIN ; Double precision.
      ang_out = degrees ? 180.0D/!DPI : 1.0D
      zero = 0.0D
   ENDIF ELSE BEGIN ; Single precision
      ang_out = degrees ? !Radeg : 1.0
      zero = 0.0
   ENDELSE

   CASE 1 OF
   Keyword_Set(to_polar): BEGIN
      ang = Replicate(zero, 1L, sz_from[2])
      rad = Sqrt(from_rect[0, *]^2 + from_rect[1, *]^2)
      non_zero_ind = Where(rad NE zero)
      IF (non_zero_ind[0] GE 0L) THEN $
         ang[non_zero_ind] = ang_out * $
            Atan(from_rect[1, non_zero_ind], from_rect[0, non_zero_ind])
      result = [ang, rad]
      END

   Keyword_Set(to_cylin): BEGIN
      ang = Replicate(zero, 1L, sz_from[2])
      rad = Sqrt(from_rect[0, *]^2 + from_rect[1, *]^2)
      non_zero_ind = Where(rad NE zero)
      IF (non_zero_ind[0] GE 0L) THEN $
         ang[non_zero_ind] = ang_out * $
            Atan(from_rect[1, non_zero_ind], from_rect[0, non_zero_ind])
      result = (sz_from[1] GE 3L) ? [ang, rad, from_rect[2, *]] : $
         [ang, rad, Replicate(zero, 1L, sz_from[2])]
      END

   Keyword_Set(to_sphere): BEGIN
      ang1 = Replicate(zero, 1L, sz_from[2])
      ang2 = Replicate(zero, 1L, sz_from[2])
      IF (sz_from[1] LT 3L) THEN z = Replicate(zero, 1L, sz_from[2]) $
      ELSE z = from_rect[2, *]
      rad = Sqrt(from_rect[0, *]^2 + from_rect[1, *]^2 + z^2)
      non_zero_ind = Where(rad GT zero)
      IF (non_zero_ind[0] GE 0L) THEN BEGIN
         ang1[non_zero_ind] = ang_out * $
            Atan(from_rect[1, non_zero_ind], from_rect[0, non_zero_ind])
         ang2[non_zero_ind] = ang_out * Atan(z[0, non_zero_ind], $
            Sqrt(from_rect[0, non_zero_ind]^2 + from_rect[1, non_zero_ind]^2))
      ENDIF
      result = [ang1, ang2, rad]
      END
   ELSE: result = from_rect
   ENDCASE
END

(N_Elements(from_polar) GT 1L): BEGIN ; Convert from polar.
   sz_from = Size(from_polar)
   doDouble = isDouble ? doDouble : $
      SIZE(from_polar, /TNAME) EQ 'DOUBLE'
   IF (sz_from[0] EQ 1L) THEN $
      sz_from = [2L, sz_from[1], 1L, sz_from[2], sz_from[3]]

   IF doDouble THEN BEGIN ; Double precision.
      ang_in = degrees ? !DPI/180.0D : 1.0D
      zero = 0.0D
   ENDIF ELSE BEGIN ; Single precision
      ang_in = degrees ? !Dtor : 1.0
      zero = 0.0
   ENDELSE

   CASE 1 OF
   Keyword_Set(to_rect): $
      result = [from_polar[1, *] * Cos(ang_in * from_polar[0, *]), $
               from_polar[1, *] * Sin(ang_in * from_polar[0, *])]

   Keyword_Set(to_cylin): $
      result = [from_polar[0, *], from_polar[1, *], $
               Replicate(zero, 1, sz_from[2])]

   Keyword_Set(to_sphere): $
      result = [from_polar[0, *], Replicate(zero, 1, sz_from[2]), $
               from_polar[1, *]]
   ELSE: result = from_polar
   ENDCASE
END

(N_Elements(from_cylin) GT 1L): BEGIN ; Convert from cylindrical.
   sz_from = Size(from_cylin)
   doDouble = isDouble ? doDouble : $
      SIZE(from_cylin, /TNAME) EQ 'DOUBLE'
   IF (sz_from[0] EQ 1L) THEN $
      sz_from = [2L, sz_from[1], 1L, sz_from[2], sz_from[3]]

   IF doDouble THEN BEGIN ; Double precision.
      ang_in = degrees ? !DPI/180.0D : 1.0D
      ang_out = degrees ? 180.0D/!DPI : 1.0D
      zero = 0.0D
   ENDIF ELSE BEGIN ; Single precision
      ang_in = degrees ? !Dtor : 1.0
      ang_out = degrees ? !Radeg : 1.0
      zero = 0.0
   ENDELSE

   CASE 1 OF
   Keyword_Set(to_rect): $
      result = [from_cylin[1, *] * Cos(ang_in * from_cylin[0, *]), $
               from_cylin[1, *] * Sin(ang_in * from_cylin[0, *]), $
               from_cylin[2, *]]

   Keyword_Set(to_polar): result = [from_cylin[0, *], from_cylin[1, *]]

   Keyword_Set(to_sphere): BEGIN
      ang1 = from_cylin[0, *]
      ang2 = Replicate(zero, 1L, sz_from[2])
      rad = Sqrt(from_cylin[1, *]^2 + from_cylin[2, *]^2)
      non_zero_ind = Where(rad GT zero)
      IF (non_zero_ind[0] GE 0L) THEN $
         ang2[non_zero_ind] = ang_out * Atan(from_cylin[2, non_zero_ind], $
                                             from_cylin[1, non_zero_ind])
      result = [ang1, ang2, rad]
      END

   ELSE: result = from_cylin
   ENDCASE
END

(N_Elements(from_sphere) GT 1L): BEGIN ; Convert from spherical.
   sz_from = Size(from_sphere)
   doDouble = isDouble ? doDouble : $
      SIZE(from_sphere, /TNAME) EQ 'DOUBLE'
   IF (sz_from[0] EQ 1L) THEN $
      sz_from = [2L, sz_from[1], 1L, sz_from[2], sz_from[3]]

   IF doDouble THEN BEGIN ; Double precision.
      ang_in = degrees ? !DPI/180.0D : 1.0D
      zero = 0.0D
   ENDIF ELSE BEGIN ; Single precision
      ang_in = degrees ? !Dtor : 1.0
      zero = 0.0
   ENDELSE

   CASE 1 OF
   Keyword_Set(to_rect): result = [ $
          from_sphere[2, *] * Cos(ang_in * from_sphere[0, *]) * $
                                     Cos(ang_in * from_sphere[1, *]), $
          from_sphere[2, *] * Sin(ang_in * from_sphere[0, *]) * $
                                     Cos(ang_in * from_sphere[1, *]), $
          from_sphere[2, *] * Sin(ang_in * from_sphere[1, *])]

   Keyword_Set(to_polar): $
      result = [from_sphere[0, *], $
               from_sphere[2, *] * Cos(ang_in * from_sphere[1, *])]

   Keyword_Set(to_cylin): $
      result = [from_sphere[0, *], $
               from_sphere[2, *] * Cos(ang_in * from_sphere[1, *]), $
               from_sphere[2, *] * Sin(ang_in * from_sphere[1, *])]
   ELSE: result = from_sphere
   ENDCASE
END

ELSE: result = 0   ; no valid FROM_ keywords

ENDCASE

RETURN, doDouble ? DOUBLE(result) : FLOAT(result)

END

