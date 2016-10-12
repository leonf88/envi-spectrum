; $Id: //depot/idl/releases/IDL_80/idldir/lib/extract_slice.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   EXTRACT_SLICE
;
; PURPOSE:
;   This function returns a 2-D planar slice extracted from
;       3-D volumetric data. The slicing plane may be oriented at
;       any angle, and may pass through any desired location in the
;       volume.
;
; CATEGORY:
;   Volume Rendering.
;
; CALLING SEQUENCE:
;       Slice = EXTRACT_SLICE(Vol, X_size, Y_size, X_center, Y_center, $
;                             Z_center, X_rot, Y_rot, Z_rot)
;   OR
;   Slice = EXTRACT_SLICE(Vol, X_size, Y_size, X_center, Y_center, $
;                             Z_center, Plane_Normal, Xvec
;
; INPUTS:
;       Vol:        The three dimensional volume of data to slice.
;                   Data type : Any 3-D array except string or structure.
;       X_size:     The size of the returned slice in X (The returned
;                   slice will have the dimensions X_size by Y_size).
;                   Data type : Long.
;       Y_size:     The size of the returned slice in Y. To preserve
;                   the correct aspect ratio of the data, Y_size should
;                   equal X_size. For optimal results, set X_size and
;                   Y_size to be greater than or equal to the largest of
;                   the three dimensions of Vol.
;                   Data type : Long.
;       X_center:   The X coordinate (index) within the volume that the
;                   slicing plane passes through. The center of the
;                   slicing plane passes through Vol at the coordinate
;                   (X_center, Y_Center, Z_center).
;                   Data type : Any scalar numeric value (usually Long).
;       Y_center:   The Y coordinate (index) within the volume that the
;                   slicing plane passes through.
;                   Data type : Any scalar numeric value (usually Long).
;       Z_center:   The Z coordinate (index) within the volume that the
;                   slicing plane passes through.
;                   Data type : Any scalar numeric value (usually Long).
;       X_rot:      The orientation (X rotation) of the slicing plane.
;                   Before transformation, the slicing plane is parallel
;                   to the X-Y plane. The slicing plane transformations
;                   are performed in the following order :
;                      1. Rotate Z_rot degrees about the Z axis.
;                      2. Rotate Y_rot degrees about the Y axis.
;                      3. Rotate X_rot degrees about the X axis.
;                      4. Translate the center of the plane to
;                         X_center, Y_center, Z_center.
;                   Data type : Float.
;       Y_rot:      The orientation (Y rotation) of the slicing plane.
;                   Data type : Float.
;       Z_rot:      The orientation (Z rotation) of the slicing plane.
;                   Data type : Float.
;
;   Plane_Normal: 3D normal vector of slicing plane
;                   Data type : Float[3].
;   Xvec:       3D vector representing X direction for slicing plane.
;           This vector will be projected onto slicing plane before
;           use.
;                   Data type : Float[3].
;
; KEYWORD PARAMETERS:
;       OUT_VAL:    If OUT_VAL is set, then the portions of the returned
;                   slice that lie outside the original volume are set to
;                   the value passed to OUT_VAL.
;                   Data type : Any scalar numeric value (usually the same
;                               type as Vol).
;       RADIANS:    Set this keyword to a non-zero value to indicate that
;                   X_rot, Y_rot, and Z_rot are in radians. The default
;                   is degrees. Ignored for Plane_Normal,Xvec usage.
;                   Data type : Int.
;       SAMPLE:     If SAMPLE is set to a non-zero value then nearest
;                   neighbor sampling is used to compute the slice.
;                   Otherwise, tri-linear (or cubic) interpolation is used.
;                   A small reduction in execution time will result if
;                   SAMPLE mode is set and the OUT_VAL keyword is NOT
;                   used.
;
;
;       ANISOTROPY: Set this input keyword to a three element array.  This
;           array specifies the spacing between the planes of the
;           input volume in grid units of the (isotropic) output image.
;
;   VERTICES:   Set this output keyword to a named variable in which to
;           return a [3,Xsize,Ysize] floating point array.  This is an
;           array of the x,y,z sample locations for each pixel in the
;           normal output.
;
; OUTPUTS:
;       This function returns the planar slice as a two dimensional
;       array with the same data type as Vol. The dimensions of the
;       returned array are X_size by Y_size.
;
; EXAMPLE:
;       Display an oblique slice through volumetric data.
;
;       ; Create some data.
;          vol = RANDOMU(s, 40, 40, 40)
;          FOR i=0, 10 DO vol = SMOOTH(vol, 3)
;          vol = BYTSCL(vol(3:37, 3:37, 3:37))
;
;       ; Extract and display a slice using angles to specify slice.
;          slice = EXTRACT_SLICE(vol, 40, 40, 17, 17, 17, 0, 0, 45, $
;                   OUT_VAL=0B)
;          TVSCL, REBIN(slice, 400, 400)
;
;       ; Extract and display same slice using vector form.
;       slice = EXTRACT_SLICE(vol, 40,40, 17, 17, 17, $
;           [0,0,1],[1,1,0],OUT_VAL=0B,ANISOTROPY=[2,1,1])
;
; MODIFICATION HISTORY:
;       Written by:     Daniel Carr. Wed Sep  2 14:47:07 MDT 1992
;   Modified by:
;       Daniel Carr. Mon Nov 21 14:59:45 MST 1994
;           Improved speed and added the CUBIC keyword.
;       Karthik B.  March 1999
;           Added vector form of plane specification, ANISOTROPY,
;           and VERTICES keywords.
;       CT, RSI, July 2002
;           Corrected the scaling/rotation transform order.
;           Allow ANISOTROPY to work with X_rot, Y_rot, Z_rot args.
;           Removed CUBIC keyword since INTERPOLATE cannot do 3D cubic.
;
;-

FUNCTION EXTRACT_SLICE, vol, x_size, y_size, $
                        x_center, y_center, z_center, $
                        targ0, targ1,targ2, RADIANS=radians, $
                        OUT_VAL=out_val, SAMPLE=p_sample, $
                        CUBIC=cubic, ANISOTROPY=anisotropy, $
            VERTICES=vertices

compile_opt idl2

ON_ERROR, 2
; *** Check inputs

ndims = SIZE(vol,/N_DIMENSIONS)
sz_vol =  SIZE(vol)

if (N_ELEMENTS(cubic) ne 0) then $
    MESSAGE, /INFO, 'The CUBIC keyword is obsolete and will be ignored.'

IF (ndims NE 3L) THEN $
   MESSAGE, 'Volume array must have three dimensions'

vol_type = SIZE(vol,/TYPE)
IF (vol_type EQ 0L) THEN $
   MESSAGE, 'Volume array must be defined'

IF (vol_type EQ 7L) THEN $
   MESSAGE, 'Invalid volume array type (string)'

IF (vol_type EQ 8L) THEN $
   MESSAGE, 'Invalid volume array type (structure)'

x_size = LONG(x_size[0])
IF (x_size LT 2L) THEN $
   MESSAGE, 'X_size must be >= 2'

y_size = LONG(y_size[0])
IF (y_size LT 2L) THEN $
   MESSAGE, 'Y_size must be >= 2'

x_center = FLOAT(x_center[0])
IF ((x_center LT 0.0) OR (x_center GE Float(sz_vol[1]))) THEN $
   MESSAGE, 'X_center must be >= 0 and less than the x dimension of vol'

y_center = FLOAT(y_center[0])
IF ((y_center LT 0.0) OR (y_center GE Float(sz_vol[2]))) THEN $
   MESSAGE, 'Y_center must be >= 0 and less than the y dimension of vol'

z_center = FLOAT(z_center[0])
IF ((z_center LT 0.0) OR (z_center GE Float(sz_vol[3]))) THEN $
   MESSAGE, 'Z_center must be >= 0 and less than the z dimension of vol'

if (N_ELEMENTS(anisotropy) ne 3) then $
    anisotropy=[1,1,1]

if (TOTAL(anisotropy eq 0) gt 0) then $
    MESSAGE, 'ANISOTROPY values must be nonzero.'


IF(N_ELEMENTS(targ0) EQ 3) THEN BEGIN ;Plane normal specified

    EPSILON = 10.0 * 1.19209290e-07
    zvec = targ0
    xvec = targ1

    xnorm = NORM(xvec)
    znorm = NORM(zvec)
    IF(NOT(xnorm GT EPSILON)) THEN $
        MESSAGE,'XVEC too small'

    IF(NOT(znorm GT EPSILON)) THEN $
        MESSAGE,'PLANE NORMAL too small'

    xvec = xvec/xnorm
    zvec = zvec/znorm
    yvec = CROSSP(zvec,xvec)
    ynorm = NORM(yvec)
    IF(NOT(ynorm GT EPSILON)) THEN $
        MESSAGE,'PLANE NORMAL and XVEC are coincident.'

    xvec = CROSSP(yvec,zvec)

ENDIF ELSE BEGIN  ;Rotation angles specified
    x_rot = targ0
    y_rot = targ1
    z_rot = targ2
    x_rot = Float(x_rot[0])
    y_rot = Float(y_rot[0])
    z_rot = Float(z_rot[0])

    IF (N_Elements(radians) GT 0L) THEN BEGIN
       IF (radians[0] NE 0) THEN BEGIN
      x_rot = x_rot * !RADEG
      y_rot = y_rot * !RADEG
      z_rot = z_rot * !RADEG
       ENDIF
    ENDIF
ENDELSE

; *** Set up the required variables

set_out = (N_Elements(out_val) GT 0L)

sample = 0B
IF (N_Elements(p_sample) GT 0L) THEN sample = Byte(p_sample[0])

vol_ind = [[Reform((Findgen(x_size) # Replicate(1.0, y_size)),  $
                   (x_size * y_size))], $
           [Reform((Replicate(1.0, x_size) # Findgen(y_size)),  $
                   (x_size * y_size))], $
           [Replicate(0.0, (x_size * y_size))],  $
           [Replicate(1.0, (x_size * y_size))]]

; *** Extract the slice

save_pt = !P.T
T3d, /Reset
T3d, Translate=[-(Float(x_size-1L)/2.0), -(Float(y_size-1L)/2.0), 0.0]
IF(N_ELEMENTS(targ0) EQ 3) THEN BEGIN
    ;Rotation matrix
    Mrot = FLTARR(4,4)
    Mrot[0, 0:2]=xvec
    Mrot[1, 0:2]=yvec
    Mrot[2, 0:2]=zvec
    Mrot[3,*]=[0,0,0,1]
    Mscale = FLTARR(4,4)
    Mscale[0,0]=1./anisotropy[0]
    Mscale[1,1]=1./anisotropy[1]
    Mscale[2,2]=1./anisotropy[2]
    Mscale[3,3]=1
    ; CT, RSI, July 2002: Corrected the transformation order.
    ; When the points are transformed, the anisotropic scaling
    ; will be removed before the rotation is applied.
    !P.T = Mscale ## Mrot ## !P.T
END ELSE BEGIN
    ; CT, RSI, July 2002: The ANISOTROPY scaling was missing.
    T3D, SCALE=1d/anisotropy
    T3d, Rotate=[0.0, 0.0, z_rot]
    T3d, Rotate=[0.0, y_rot, 0.0]
    T3d, Rotate=[x_rot, 0.0, 0.0]
END
T3d, Translate=Float([x_center, y_center, z_center])
vol_ind = vol_ind # !P.T
!P.T = save_pt

if(ARG_PRESENT(vertices)) then begin
    vertices = FLTARR(3,x_size,y_size)
    vertices[0,*,*] = vol_ind[*,0]
    vertices[1,*,*] = vol_ind[*,1]
    vertices[2,*,*] = vol_ind[*,2]
end

IF (sample) THEN BEGIN
   slice = Reform((vol[0>vol_ind[*, 0]<(sz_vol[1]-1), $
                  0>vol_ind[*, 1]<(sz_vol[2]-1), $
                  0>vol_ind[*, 2]<(sz_vol[3]-1)]), x_size, y_size)
   IF (set_out) THEN BEGIN
      out_v = Where((((vol_ind[*, 0] LT 0.0) OR $
                      (vol_ind[*, 0] GE sz_vol[1])) OR $
                     ((vol_ind[*, 1] LT 0.0) OR $
                      (vol_ind[*, 1] GE sz_vol[2]))) OR $
                     ((vol_ind[*, 2] LT 0.0) OR (vol_ind[*, 2] GE sz_vol[3])))
      IF (out_v[0] GE 0L) THEN slice[out_v] = out_val
   ENDIF
ENDIF ELSE BEGIN
   IF (set_out) THEN BEGIN
      slice = $
         Reform((Interpolate(vol, $
            vol_ind[*, 0], vol_ind[*, 1], vol_ind[*, 2], $
            Missing=out_val)), x_size, y_size)
   ENDIF ELSE BEGIN
       slice = Reform((Interpolate(vol, vol_ind[*, 0], vol_ind[*, 1],  $
                                   vol_ind[*, 2])), x_size, y_size)
   ENDELSE
ENDELSE

RETURN, slice
END





