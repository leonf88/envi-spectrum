; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_proj_init.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   MAP_PROJ_INIT
;
; PURPOSE:
;   Set up IDL or GCTP map projections.
;
; CALLING SEQUENCE:
;   Result = MAP_PROJ_INIT(Projection)
;
; INPUTS:
;   Projection: Either an integer giving the projection number,
;       or a string giving the projection name. If Projection is a string,
;       then the GCTP keyword may be used to select the GCTP projection
;       rather than the IDL projection.
;
; OUTPUTS:
;   Result: This is a !MAP structure with the projection parameters.
;       This Result may then be passed into other map projection routines
;       such as MAP_PROJ_FORWARD and MAP_PROJ_INVERSE.
;       Note: The !MAP system variable is not affected by MAP_PROJ_INIT.
;
; KEYWORDS:
;   ELLIPSOID: Set this keyword to either an integer code or a string name
;       for the ellipsoid to use. The default depends upon
;       the projection, but is either the Clarke 1866 ellipsoid, or a
;       sphere of radius 6370.997 km.
;
;   GCTP: Set this keyword to indicate that the GCTP projection
;       should be used rather than the IDL projection.
;       If the Projection name only exists in one system (GCTP or IDL)
;       but not the other (such as "Satellite") then this keyword is ignored.
;
;   LIMIT: Set this keyword to a four-element vector of the form
;       [Latmin, Lonmin, Latmax, Lonmax] that specifies the boundaries
;       of the region to be mapped. (Lonmin, Latmin) and (Lonmax, Latmax)
;       are the longitudes and latitudes of two points diagonal from each
;       other on the region's boundary.
;
;       Note - If the longitude range is less than or equal to 180 degrees,
;       then the map clipping is done in lat/lon before the transform.
;       If the longitude range is greater than 180 degrees then
;       the map clipping is done in X/Y cartesian space after transforming.
;       For non-cylindrical projections, clipping in X/Y space may include
;       lat/lon points that are outside of the original LIMIT.
;
;   RADIANS: Set this keyword to indicate that all projection parameters
;       which are angles are being specified in radians. The default is
;       to assume that all angles are in degrees.
;
;   RELAXED: If this keyword is set, then any projection parameters which
;       do not apply to the given Projection will be quietly ignored.
;       The default behavior is to issue errors for illegal parameters.
;
; REFERENCE:
;   Snyder, John P. (1987), Map Projections - A Working Manual,
;       U.S. Geological Survey Professional Paper 1395,
;       U.S.Government Printing Office, Washington, D.C.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Feb 2002
;       Heavily based upon Dave Stern code.
;       Exposed GCTP projections, previously available only in ENVI.
;       Extracted projection code from MAP_SET, without graphics portion.
;
;   Modified:
;   MP, Feb 2010
;     Added special angles (90, 180, 270. 360) handling for sine and cosine
;-


;---------------------------------------------------------------------------
; Internal function method to convert an angle from degrees to GCTP
; DMS format. DMS = deg * 1e6 + minutes * 1000 + secs.
;
function map_proj_ToDegMinSec, angle
    compile_opt idl2, hidden

    b = ABS(angle)
    deg = FLOOR(b)
    fmin = (b - deg) * 60              ;Minutes
    imin = FLOOR(fmin)
    secs = 60 * (fmin - imin)
    r = deg * 1d6 + imin * 1d3 + secs
    sign = (angle ge 0)*2-1
    return, sign*r
end


;---------------------------------------------------------------------------
; Rotate the vector p(3) counterclockwise
; about the X, Y, and Z, by the amounts rx, ry, rz, degrees, in order.
;
function map_proj_rotate, p, rx, ry, rz

    compile_opt hidden, idl2

    p1 = p
    dtor = !dpi/ 180d

    if (rx ne 0) then begin
        sx = (rx mod 90) ne 0 ? sin(rx *dtor) : $
          (rx ge 0 ? ((rx mod 180) eq 0 ? 0 : (rx eq 90 ? 1: -1)) : $
              ((rx mod 180) eq 0 ? 0 : (rx eq -90 ? -1: 1)))
        cx = (rx mod 90) ne 0? cos(rx *dtor) : $
          (rx ge 0 ? ((rx mod 180) ne 0 ? 0 : (rx eq 180 ? -1: 1)) : $
              ((rx mod 180) ne 0 ? 0 : (rx eq -180 ? -1: 1)))
        t = [[1,0,0],[0,cx, sx], [0, -sx, cx]]
        p1 = p1 ## t
    endif
    if (ry ne 0) then begin
        sy = (ry mod 90) ne 0 ? sin(ry *dtor) : $
          (ry ge 0 ? ((ry mod 180) eq 0 ? 0 : (ry eq 90 ? 1: -1)) : $
              ((ry mod 180) eq 0 ? 0 : (ry eq -90 ? -1: 1)))
        cy = (ry mod 90) ne 0? cos(ry *dtor) : $
          (ry ge 0 ? ((ry mod 180) ne 0 ? 0 : (ry eq 180 ? -1: 1)) : $
              ((ry mod 180) ne 0 ? 0 : (ry eq -180 ? -1: 1)))
        t = [[cy, 0, -sy], [0, 1, 0], [sy, 0, cy]]
        p1 = p1 ## t
    endif
    if (rz ne 0) then begin
        sz = (rz mod 90) ne 0 ? sin(rz *dtor) : $
          (rz ge 0 ? ((rz mod 180) eq 0 ? 0 : (rz eq 90 ? 1: -1)) : $
              ((rz mod 180) eq 0 ? 0 : (rz eq -90 ? -1: 1)))
        cz = (rz mod 90) ne 0? cos(rz *dtor) : $
          (rz ge 0 ? ((rz mod 180) ne 0 ? 0 : (rz eq 180 ? -1: 1)) : $
              ((rz mod 180) ne 0 ? 0 : (rz eq -180 ? -1: 1)))
        t = [[cz, sz, 0], [ -sz, cz, 0], [0,0,1]]
        p1 = p1 ## t
    endif

    return, p1
end


;---------------------------------------------------------------------------
; Check the LIMIT keyword, and set clip planes if necessary.
;
; Limit should be a 4 element array of [Latmin, Lonmin, Latmax, Lonmax]
;
; If Lon1==Lon2 then no longitude clipping is done.
; If Lat1==Lat2 then no latitude clipping is done.
;
pro map_proj_set_limit, sMap, limit

    compile_opt idl2, hidden

    dtor = !DPI/180d


    ; Check longitudes, switch if necessary.
    ; Reduce lon to range [-180, +360]
    limit[[1,3]] = -360 > limit[[1,3]] < 720

    while (limit[3] lt -180) do limit[[1,3]] += 360
    while (limit[3] gt 360) do limit[[1,3]] -= 360
    while (limit[1] lt -180) do limit[[1,3]] += 360
    while (limit[1] gt 360) do limit[[1,3]] -= 360


    if (limit[1] gt limit[3]) then $  ; switch longitudes
        limit[[1,3]] = limit[[3,1]]

    ; Default if lon1==lon2 is no longitude clipping
    if (limit[1] eq limit[3]) then $
        limit[[1,3]] = [-180, 180]



    ; Check latitudes, switch if necessary.
    limit[[0,2]] = -90 > limit[[0,2]] < 90
    if (limit[0] gt limit[2]) then $  ; switch latitudes
        limit[[0,2]] = limit[[2,0]]

    ; Default if lat1==lat2 is no latitude clipping.
    if (limit[0] eq limit[2]) then $
        limit[[0,2]] = [-90, 90]


    ; Range of longitude/latitudes.
    londel = limit[3] - limit[1]
    latdel = limit[2] - limit[0]


    ; To determine the UV range, we use the MAP_SET
    ; brute force method, by choosing a grid of latlon coords,
    ; transforming them, and then finding the min & max.

    eps = 1d-4  ; fudge factor

    ; At least 13 pnts or every 10 degs.
    nlon = (1 + CEIL(londel/10d)) > 13
    lons = DINDGEN(nlon)*(londel/(nlon-1d)) + limit[1]

    ; Add fudge points on either end.
    lons = [limit[1] + eps, lons, limit[3] - eps]
    nlon = nlon + 2

    ; At least 9 pnts or every 10 degs.
    nlat = (1 + CEIL(latdel/10d)) > 9
    lats = DINDGEN(nlat)*(latdel/(nlat-1d)) + limit[0]

    ; Add fudge points on either end.
    lats = [limit[0] + eps, lats, limit[2] - eps]

    ; If limit crosses the equator, include fudge pts on either side.
    if ((limit[0] lt 0) && (limit[2] gt 0)) then $
        lats = [lats, -eps, eps]

    nlat = N_ELEMENTS(lats)

    quiet = !QUIET  ; cache
    !QUIET = 1      ; turn off out-of-range warnings

    ; Turn lon/lat into column vectors of all lon/lat combinations.
    lons = REFORM(REBIN(lons, nlon, nlat), 1, nlon*nlat)
    lats = REFORM(REBIN(TRANSPOSE(lats), nlon, nlat), 1, nlon*nlat)
    lonlatTmp = [TEMPORARY(lons), TEMPORARY(lats)]

    ; Find all of the valid projected points.
    xy = MAP_PROJ_FORWARD(lonlatTmp, MAP=sMap)

    ; Default if no points are valid is just the limit.
    lonlat = limit[[[1,0],[3,2]]]
    good = WHERE(FINITE(xy[0,*]) and FINITE(xy[1,*]), ngood)

    if (ngood gt 0) then begin

        ; Remove all NaNs.
        xy = xy[*, good]
        lonlat = lonlatTmp[*, good]

        ; Now find all of the valid inverse projected points.
        lonlatTmp = MAP_PROJ_INVERSE(xy, MAP=sMap)

        ; Replace all non-finite values with a missing value.
        ; This avoids illegal operands in the ABS below.
        bad = WHERE(TOTAL(FINITE(lonlatTmp), 1) lt 2, nbad)
        if (nbad gt 0) then $
            lonlatTmp[*, bad] = -9999

        ; Points transformed forward & back within tolerances?
        diff = ABS(lonlat - lonlatTmp)

        ; Ignore differences between +180 and -180 longitude.
        diff[0,*] = diff[0,*] mod 360

        ; Within the map range?
        good = WHERE((ABS(lonlatTmp[0,*]) le 720) and $
            (ABS(lonlatTmp[1,*]) le 90) and (TOTAL(diff,1) lt 1d), ngood)

        if (ngood gt 0) then begin
            ; Only keep the points which are good for
            ; both forward and inverse projection.
            lonlat = lonlat[*, good]
            xy = xy[*,good]
        endif

    endif


    !QUIET = quiet   ; restore

    ; Extract the ranges
    xmin = MIN(xy[0,*], /NAN, MAX=xmax)
    ymin = MIN(xy[1,*], /NAN, MAX=ymax)
    lonmin = MIN(lonlat[0,*], /NAN, MAX=lonmax)
    latmin = MIN(lonlat[1,*], /NAN, MAX=latmax)


    ; Fill in map structure.
    sMap.ll_box = [latmin, lonmin, latmax, lonmax]
    sMap.uv_box = [xmin, ymin, xmax, ymax]


    ; Don't bother to clip at poles.
    if (limit[0] gt -90) then $
        MAP_CLIP_SET, MAP=sMap, $
        CLIP_PLANE=[0, 0, 1, $
              -((limit[0] mod 90) ne 0 ? sin(limit[0] *dtor) : $
              (limit[0] ge 0 ? ((limit[0] mod 180) eq 0 ? 0 : (limit[0] eq 90 ? 1: -1)) : $
              ((limit[0] mod 180) eq 0 ? 0 : (limit[0] eq -90 ? -1: 1))))]
    if (limit[2] lt 90) then $
        MAP_CLIP_SET, MAP=sMap, $
        CLIP_PLANE=[0, 0,-1,  $
              (limit[2] mod 90) ne 0 ? sin(limit[2] *dtor) : $
              (limit[2] ge 0 ? ((limit[2] mod 180) eq 0 ? 0 : (limit[2] eq 90 ? 1: -1)) : $
              ((limit[2] mod 180) eq 0 ? 0 : (limit[2] eq -90 ? -1: 1)))]


    if ((londel gt 180) && (londel lt 360)) then begin

        ; If the longitude range is more than 180 degrees,
        ; we can't use 2 clipping planes because they will overlap.
        ; Instead we need to use UV clipping (after the projection).
        ; This may have undesirable effects for non-cylindrical
        ; projections...clipping transformed coordinates is not the
        ; same as clipping longitude before transforming.

        if ((xmin eq xmax) || (ymin eq ymax) || $
            TOTAL(FINITE(sMap.uv_box)) lt 4) then begin
            MESSAGE, 'Invalid map limits. Ignoring...', /INFO
        endif else begin
            MAP_CLIP_SET, MAP=sMap, CLIP_UV = sMap.uv_box
        endelse

    endif else if ((londel gt 0) && (londel le 180)) then begin

        ; If the longitude range is between 0 and 180 degrees,
        ; we use 2 longitude clipping planes.
        MAP_CLIP_SET, MAP=sMap, $
            CLIP_PLANE=[-((limit[1] mod 90) ne 0 ? sin(limit[1] *dtor) : $
              (limit[1] ge 0 ? ((limit[1] mod 180) eq 0 ? 0 : (limit[1] eq 90 ? 1: -1)) : $
              ((limit[1] mod 180) eq 0 ? 0 : (limit[1] eq -90 ? -1: 1)))),  $
            (limit[1] mod 90) ne 0? cos(limit[1] *dtor) : $
              (limit[1] ge 0 ? ((limit[1] mod 180) ne 0 ? 0 : (limit[1] eq 180 ? -1: 1)) : $
              ((limit[1] mod 180) ne 0 ? 0 : (limit[1] eq -180 ? -1: 1))),$ 
            0d, 0d]
        ; Only 1 clip plane needed if 180 degrees apart.
        if (londel ne 180) then MAP_CLIP_SET, MAP=sMap, $
            CLIP_PLANE=[ (limit[3] mod 90) ne 0 ? sin(limit[3] *dtor) : $
              (limit[3] ge 0 ? ((limit[3] mod 180) eq 0 ? 0 : (limit[3] eq 90 ? 1: -1)) : $
              ((limit[3] mod 180) eq 0 ? 0 : (limit[3] eq -90 ? -1: 1))), $
            -((limit[3] mod 90) ne 0? cos(limit[3] *dtor) : $
              (limit[3] ge 0 ? ((limit[3] mod 180) ne 0 ? 0 : (limit[3] eq 180 ? -1: 1)) : $
              ((limit[3] mod 180) ne 0 ? 0 : (limit[3] eq -180 ? -1: 1)))), $
            0d, 0d]

    endif


end


;---------------------------------------------------------------------------
; Set the splitting hemisphere.
; Most of this code comes originally from MAP_SET.
;
pro map_proj_set_split, sMap, EQUATOR=equator

    compile_opt idl2, hidden
    
    sinlat = (sMap.p0lat mod 90) ne 0 ? sin(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq 90 ? 1: -1)) : $
              ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq -90 ? -1: 1)))
    coslat = (sMap.p0lat mod 90) ne 0? cos(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq 180 ? -1: 1)) : $
              ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq -180 ? -1: 1)))
              
    sinlon = (sMap.p0lon mod 90) ne 0 ? sin(sMap.u0) : $
      (sMap.p0lon ge 0 ? ((sMap.p0lon mod 180) eq 0 ? 0 : (sMap.p0lon eq 90 ? 1: -1)) : $
              ((sMap.p0lon mod 180) eq 0 ? 0 : (sMap.p0lon eq -90 ? -1: 1)))
    coslon = (sMap.p0lon mod 90) ne 0? cos(sMap.u0) : $
      (sMap.p0lon ge 0 ? ((sMap.p0lon mod 180) ne 0 ? 0 : (sMap.p0lon eq 180 ? -1: 1)) : $
              ((sMap.p0lon mod 180) ne 0 ? 0 : (sMap.p0lon eq -180 ? -1: 1)))
    
    if KEYWORD_SET(equator) then begin ;use lat = 0
        split = [sMap.p0lon, 0, sinlon, -coslon, 0d, 0d]
    endif else begin
        xyzProjCenter = [coslon*coslat, $
            sinlon*coslat, sinlat]
        pole = sMap.pole[4:6]       ;Location of pole
        plane = CROSSP(xyzProjCenter, pole)
        split=[sMap.p0lon, sMap.p0lat, plane, 0d]
    endelse

    MAP_CLIP_SET, MAP=sMap, SPLIT=split
end


;---------------------------------------------------------------------------
; Set up the default clipping/splitting for the given projection.
; Most of this code comes originally from MAP_SET.
;
; The internal MAP_CLIP_SET sets up the clipping/splitting pipeline for
; the projection.
;
; MAP_CLIP_SET keywords:
;
; RESET: (no parameters) resets the map splitting/clipping pipeline
;    to empty.  If empty, a TRANSFORM step is automatically added.
;
; SPLIT = [longitude, latitude, A, B, C, D], enables a splitting
;    stage across the half-plane, Ax + By + Cz + D = 0, opposite the point
;    (longitude, latitude), in degrees.  Lines and polygons that cross this
;    half-plane are split into separate objects.  For cylindrical and
;    pseudo cylindrical projections, (longitude, latitude) is the center of
;    projection, and the plane specified by [A, B, C, D] is the plane that
;    passes through the following three points: the center of projection, a
;    pole of projection, and the center of the sphere.  This splits all
;    objects that cross the plane, behind the center of projection.  The
;    transfomation from longitude/latitude to cartesian coordinates is
;    shown below.
;
;    To set up the splitting, for a center of projection on the equator at
;    a given longitude, and with the north pole one of the poles of the
;    projection:
;    MAP_CLIP_SET, SPLIT = [longitude, 0, sin(!DTOR* longitude), $
;      -cos(!DTOR * longitude), 0.0, 0.0]
;
;    For the general case, to set the splitting for a center of projection
;    at (lon, lat), with cartesian coordinates (x0, y0, z0), and a pole
;    of (x1, y1, z1):
;    MAP_CLIP_SET, SPLIT=[lon, lat, CROSSP([x0, y0, z0], [x1, y1, z1]), 0]
;    CROSSP represents a vector cross product function, implemented via the
;    IDL_*_CROSS_PRODUCT macros.
;
;
; CLIP_PLANE = [ A, B, C, D], adds a clipping plane with the
;    specified coefficients to the pipeline.  Any number of planes may be
;    specified.  In general, the clipping planes should be specified after
;    the SPLIT stage, but before TRANSFORM or CLIP_UV.  When applying the
;    clipping plane, points on the positive side of the plane are retained:
;    Ax + By + Cz + D >= 0, and points on the negative side are clipped.
;
;    For example, to add a clipping plane which retains points within an
;    angular distance s, in radians, of a center point (lon, lat):
;    1) transform (lon, lat) to cartesian coordinates, x,y, and z, as below.
;    2) MAP_CLIP_SET, CLIP_PLANE=[x, y, z, -cos(s)]
;
;    Examples: to clip to the hemisphere, centered on (lon, lat):
;       MAP_CLIP_SET, CLIP_PLANE=[x, y, z, 0]
;    To show the region within 60 degrees of the south pole, i.e. latitudes
;    less than -30 degrees:
;       MAP_CLIP_SET, CLIP_PLANE= [ 0, 0, -1, -cos(60 * !DTOR)]
;    To show latitudes greater than 30 degrees:
;       MAP_CLIP_SET, CLIP_PLANE= [ 0, 0, 1, -cos(60 * !DTOR)]
;    To show latitudes between latitudes s0 and s1, s0 < s1:
;    retain above s0:
;       MAP_CLIP_SET, CLIP_PLANE= [ 0, 0, 1, -sin(s0 * !DTOR)]
;    retain below s1:
;       MAP_CLIP_SET, CLIP_PLANE= [ 0, 0, -1, sin(s1 * !DTOR)]
;
; TRANSFORM: (no parameters) Add the lat/lon to UV transformation step.
;    This step should be after SPLIT and CLIP_PLANE(s), and before CLIP_UV.
;
; CLIP_UV = [ Umin, Vmin, Umax, Vmax], adds a stage which clips to a
;    box in the UV coordinate space.
;
; SHOW: (no parameters) prints a list of the current map splitting and
;    clipping stages with their parameters.
;
;    Transformation from latitude/longitude (in radians) to cartesian
;    coordinates:
;    x = cos(lon) * cos(lat)
;    y = sin(lon) * cos(lat)
;    z = sin(lat)
;
;    With this convention, the northern hemisphere is +Z, southern
;    hemisphere is -Z, north pole at (0,0,1) and the crossing of the
;    equator and the prime meridian is at (1,0,0).
;
pro map_proj_set_clip, index, sMap, $
    LIMIT=limitIn, $
    CLIP_RADIUS = r0

    compile_opt idl2, hidden

@map_proj_init_commonblock

    pname = c_ProjNames[index]

    ; Check LIMIT keyword.
    hasLimit = N_ELEMENTS(limitIn) eq 4
    limit = hasLimit ? limitIn : DBLARR(4)

    ; If GCTP projection, add a code
    isGCTP = c_ProjNumToGCTP[index] ge 0
    if (isGCTP) then $
        pname = 'GCTP/' + pname

    dtor = !DPI/180d

    MAP_CLIP_SET, MAP=sMap, /RESET        ;Clear clipping pipeline.

    ; handling special angles
    sinlat = (sMap.p0lat mod 90) ne 0 ? sin(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq 90 ? 1: -1)) : $
              ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq -90 ? -1: 1)))
    coslat = (sMap.p0lat mod 90) ne 0? cos(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq 180 ? -1: 1)) : $
              ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq -180 ? -1: 1)))
              
    sinlon = (sMap.p0lon mod 90) ne 0 ? sin(sMap.u0) : $
      (sMap.p0lon ge 0 ? ((sMap.p0lon mod 180) eq 0 ? 0 : (sMap.p0lon eq 90 ? 1: -1)) : $
              ((sMap.p0lon mod 180) eq 0 ? 0 : (sMap.p0lon eq -90 ? -1: 1)))
    coslon = (sMap.p0lon mod 90) ne 0? cos(sMap.u0) : $
      (sMap.p0lon ge 0 ? ((sMap.p0lon mod 180) ne 0 ? 0 : (sMap.p0lon eq 180 ? -1: 1)) : $
              ((sMap.p0lon mod 180) ne 0 ? 0 : (sMap.p0lon eq -180 ? -1: 1)))
    switch pname of

    ; Conic projections:
    ;
    ; Split across from the center longitude, then clip the poles.
    ;
    'GCTP/Lambert Conformal Conic':
    'GCTP/Albers Equal Area':
    'GCTP/Equidistant Conic A':
    'GCTP/Equidistant Conic B':
    'Lambert Conic':
    'Lambert Ellipsoid Conic':
    'Albers Equal Area Conic': begin  ; Conical projections.

        MAP_PROJ_SET_SPLIT, sMap, /EQUATOR

        ; Clip both poles.
        ; Don't bother to clip if we have latitude limits.
        if (limit[0] ne limit[2]) then break

        ; Hemisphere of the two standard parallels.
        ; Note that the sMap.p indexing is different for GCTP.
        isign1 = (sMap.p[isGCTP ? 2 : 3] ge 0.0) ? 1 : -1
        isign2 = (sMap.p[isGCTP ? 3 : 4] ge 0.0) ? 1 : -1

        ; Default is to clip opposite hemisphere from pole at 10 degs,
        ; clip same hemisphere at 75 degs, unless the standard parallels
        ; are on opposite sides of Equator, in which case both hemispheres
        ; are clipped at 75 degs.
        if (isign1 eq isign2) then begin
            MAP_CLIP_SET, MAP=sMap, $
                CLIP_PLANE=[0, 0, isign1, sin(dtor * 10)]
            MAP_CLIP_SET, MAP=sMap, $
                CLIP_PLANE=[0, 0, -isign1, sin(dtor * 75)]
        endif else begin
            MAP_CLIP_SET, MAP=sMap, $
                CLIP_PLANE=[0, 0, 1, sin(dtor * 75)]
            MAP_CLIP_SET, MAP=sMap, $
                CLIP_PLANE=[0, 0, -1, sin(dtor * 75)]
        endelse

        break
        end

    'GCTP/Polyconic': begin
        MAP_PROJ_SET_SPLIT, sMap, /EQUATOR
        break
        end

    ; Cylindrical/Pseudocylindrical projections:
    ;
    ; Need to be split 180 degrees from map center.
    ;
    'GCTP/Mollweide':
    'GCTP/Hammer':
    'GCTP/Robinson':
    'GCTP/Sinusoidal':
    'GCTP/Equirectangular':
    'GCTP/Van der Grinten':
    'GCTP/Wagner IV':
    'GCTP/Wagner VII':
    'GCTP/Integerized Sinusoidal':
    'GCTP/Cylindrical Equal Area':
    'Cylindrical':
    'Mollweide':
    'Sinusoidal':
    'Aitoff':
    'Hammer Aitoff':
    'Robinson': begin
        MAP_PROJ_SET_SPLIT, sMap
        break
        end


    ; Cylindrical projections:
    ;
    ; Split 180 degrees from map center, clip off poles which map to inf.
    ;
    'GCTP/Mercator':
    'GCTP/Miller Cylindrical':
    'Mercator':
    'Miller Cylindrical': begin
        MAP_PROJ_SET_SPLIT, sMap
        ; Don't bother to clip if we have latitude limits.
        if (limit[0] ne limit[2]) then break
        ; Go out 97.5% of the way to the poles.
        rm = 0.975d
        MAP_CLIP_SET, MAP=sMap, CLIP_PLANE=[-sMap.pole[4:6], rm]
        MAP_CLIP_SET, MAP=sMap, CLIP_PLANE=[ sMap.pole[4:6], rm]
        break
        end


    'GCTP/UTM':
    'GCTP/Transverse Mercator':
    'Transverse Mercator': begin
        ; Clip plane is perpendicular to the XY projection of the vector
        ; to the center of projection, and to the XY Plane.
        MAP_CLIP_SET, MAP=sMap, CLIP_PLANE=[coslon, sinlon, 0, 0]
        break
        end


    ; Interrupted projections:
    ;
    ; Split locations are offset 180 degrees from seams.
    ;
    'GCTP/Interrupted Mollweide': $
        splits = [-100, -70, 20, 110, 140] + 180d
        ; fall thru
    'GCTP/Interrupted Goode':
    'Goodes Homolosine': begin
        ; Avoid redefining splits from falling thru from Mollweide.
        if (N_ELEMENTS(splits) lt 1) then $
            splits = [-180, -40, -100, -20, 80] + 180d + sMap.p0lon
        for i=0, N_ELEMENTS(splits)-1 do begin ;Add each split
            theta = dtor * splits[i]
            MAP_CLIP_SET, MAP=sMap, SPLIT=[splits[i], 0, $
                (splits[i] mod 90) ne 0 ? sin(theta) : $
                (splits[i] ge 0 ? ((splits[i] mod 180) eq 0 ? 0 : (splits[i] eq 90 ? 1: -1)) : $
                ((splits[i] mod 180) eq 0 ? 0 : (splits[i] eq -90 ? -1: 1))),$
                -((splits[i] mod 90) ne 0? cos(theta) : $
                (splits[i] ge 0 ? ((splits[i] mod 180) ne 0 ? 0 : (splits[i] eq 180 ? -1: 1)) : $
              ((splits[i] mod 180) ne 0 ? 0 : (splits[i] eq -180 ? -1: 1)))), $
                0., 0.]
        endfor
        break
        end


    ; Azimuthal projections:
    ;
    ; Set a clipping plane, with different clip distance from the sphere
    ; center, depending upon the projection. We keep falling thru, making
    ; sure we've set the clip distance, until we reach the MAP_CLIP_SET.
    ;
    'GCTP/Stereographic':
    'GCTP/Orthographic':
    'GCTP/Polar Stereographic':
    'GCTP/Lambert Azimuthal':
    'GCTP/Azimuthal Equidistant':
    'Azimuthal Equidistant':
    'Lambert Azimuthal':
    'Orthographic':
    'Stereographic': $
        if (~N_ELEMENTS(r)) then r = 0   ; clip on edge
        ; Note: for the above projections we used to clip at r=1d-5,
        ; which would include a bit past the edge. But this caused
        ; tessellation problems for GCTP/Orthographic, and caused clipping
        ; issues for GCTP/Azimuthal Equidistant and GCTP/Lambert Azimuthal.
        ; So now clip exactly on the edge.

        ; fall thru

    'Satellite': $
        if (~N_ELEMENTS(r)) then r = -1.01d/sMap.p[0]
        ; fall thru

    'GCTP/Near Side Perspective': $
        if (~N_ELEMENTS(r)) then begin
            p = 1d + sMap.p[2]/sMap.a  ; normalized distance from center
            r = -1.01d/p    ; Same as Satellite above.
        endif
        ; fall thru

    'GCTP/Gnomonic':
    'Gnomonic': begin
        if (~N_ELEMENTS(r)) then r = -0.5d  ; 60degrees from center

        ; This is the last azimuthal projection, so now we want
        ; to set the clip plane, using whatever r value we set above.
        ; Set clipping to points on a plane whose normal
        ; passes thru the center (u0,v0), and at a distance of r from the
        ; origin.  r < 0 is the side closer to the center (u0,v0).
        ;

        MAP_CLIP_SET, MAP=sMap, $
            CLIP_PLANE=[coslon*coslat, $
            sinlon*coslat, sinlat, r]
            
        break
        end


    else:  ; MESSAGE, 'Unknown projection type: '+pname, /INFO

    endswitch

    ; Finding the latlon and UV limits may cause floating-point errors.
    ; These are harmless but annoying. So check the error status before
    ; we go in, and swallow the errors if none are currently pending.
    ; If !EXCEPT is set to 2 then all errors will be reported regardless.
    mathError = CHECK_MATH(/NOCLEAR)

    ; Set clipping LIMITs, if any.
    MAP_PROJ_SET_LIMIT, sMap, limit

    ; If no errors are pending, then clear all exceptions.
    if (mathError eq 0) then $
        dummy = CHECK_MATH()


    MAP_CLIP_SET, MAP=sMap, /TRANSFORM

end



;---------------------------------------------------------------------------
; Initialize IDL map projections.
; Most of this code comes originally from MAP_SET.
;
function map_proj_map_structure, index, projParams, $
    RADIANS=radians

    compile_opt idl2, hidden

@map_proj_init_commonblock

    ON_ERROR, 2   ;Return to caller.

    del = 1d-6
    dtor = !DPI/180d

    pname = c_ProjNames[index]
    isRadians = KEYWORD_SET(radians)

    gctp = c_ProjNumToGCTP[index]  ; either -1 or GCTP proj #

    ; Supply defaults
    rot = 0d         ; map rotation
    p0lon = 0d       ; center longitude
    p0lat = 0d       ; center latitude
    cent_azim = 0d   ; central azimuth
    std_p = [0d, 0d] ; standard parallels
    semimajor = 6370997d
    e2 = 0d          ; eccentricity squared
    satHeight = 0d   ; satellite height
    satTilt = 0d     ; camera tilt

    ; Pull out allowed parameter names for projection.
    projParamNames = c_ProjParameters[*,index]

    ; Convert from supplied keywords to local variables.
    for i=0,N_ELEMENTS(projParamNames)-1 do begin

        ; If necessary, convert from radians to degrees.
        match = (WHERE(c_keywordNames eq projParamNames[i]))[0]
        isAngle = (match ne -1) ? c_ParamIsAngle[match] : 0
        if (isAngle && isRadians) then $
            projParams[i] = 180d/!DPI*projParams[i]

        case projParamNames[i] of
            'CENTER_AZIMUTH':   cent_azim = projParams[i]
            'CENTER_LATITUDE':  p0lat = projParams[i]
            'CENTER_LONGITUDE': p0lon = projParams[i]
            'HEIGHT':           satHeight = projParams[i]
            'MERCATOR_SCALE':   merc_scale = projParams[i]
            'ROTATION':         rot = projParams[i]
            'SPHERE_RADIUS':    semimajor = projParams[i]
            'SEMIMAJOR_AXIS':   semimajor = projParams[i]
            'SEMIMINOR_AXIS':   semiminor = projParams[i]
            'STANDARD_PARALLEL':std_p[*] = projParams[i]
            'STANDARD_PAR1':    std_p[0] = projParams[i]
            'STANDARD_PAR2':    std_p[1] = projParams[i]
            'TILT':             satTilt = projParams[i]
            else:
        endcase

        ; If angle and gctp, convert degrees to GCTP DMS format.
        ; We need to do this after the case statement, so that our
        ; !map variables are in degrees.
        if (isAngle && (gctp ge 0)) then $
            projParams[i] = map_proj_ToDegMinSec(projParams[i])

    endfor

    ; CR56285: In IDL8.0 we changed the GCTP Polar Stereographic to
    ; use TRUE_SCALE_LATITUDE instead of CENTER_LATITUDE.
    ; However, we still need to set the p0lat field.
    if (pname eq 'Polar Stereographic') then begin
      ; If CENTER_LATITUDE was not passed in, then set it to the
      ; North or South pole, depending upon the true scale latitude.
      ; If it was passed in, it will have been set in the loop above.
      if (projParams[8] eq 0) then $
        p0lat = (projParams[5] ge 0) ? 90d : -90d
    endif

    ; The GCTP UTM projection is a special case. If the user input the
    ; CENTER_LONGITUDE and CENTER_LATITUDE, we need to convert them into
    ; a zone number. This zone number (or the ZONE keyword) is then converted
    ; into the actual center longitude for the zone. This is the same
    ; calculation that GCTP does internally, but we need to do it here
    ; to set the sMap.p0lon correctly, for use in the clipping plane.
    ;
    if (pname eq 'UTM') then begin

        sign = (p0lat ge 0) ? 1 : -1  ; Northern or Southern hemisphere
        p0lat = 0  ; center latitude is irrelevant
        ; Either convert the center longitude, or simply use the zone #.
        gctpZone = projParams[2]
        zone = (gctpZone eq 0) ? sign*FIX((p0lon + 180d)/6d + 1d) : gctpZone
        if (ABS(zone) lt 1) || (ABS(zone) gt 60) then MESSAGE, $
            'UTM ZONE must be in the range -60 to -1, or +1 to +60.'
        ; Convert the zone number into the actual center longitude.
        p0lon = 6d*ABS(zone) - 183
        ; Fill the parameters back in.
        projParams[2] = zone
        if (gctpZone ne 0) then projParams[0] = map_proj_ToDegMinSec(p0lon)

        ; UTM has a fixed False Easting and False Northing
        projParams[6] = 500000
        projParams[7] = (zone ge 1) ? 0 : 10000000
    endif


    ; Convert semiminor to eccentricity squared.
    if (N_ELEMENTS(semiminor) gt 0) then begin
        flattening = 1 - semiminor/semimajor
        e2 = flattening*(2 - flattening)
    endif

    ; Default Transverse Mercator scale is 0.9996 for the UTM.
    ; This is ignored for all other IDL projections.
    if (N_ELEMENTS(merc_scale) eq 0) then merc_scale = 0.9996d

    if (ABS(p0lat) gt 90) then $
        MESSAGE, 'Latitude must be in range of +/- 90 degrees'

    if (ABS(p0lon) gt 360) then $
        MESSAGE, 'Longitude must be in range of +/- 360 degrees'

    if (pname eq 'Goodes Homolosine') && (p0lat ne 0) then begin
        MESSAGE, /INFORMATIONAL, $
            'Goode''s Homolosine: Resetting CENTER_LATITUDE to equator.'
        p0lat = 0d
    endif

    ; Reduce lon to +/- 180
    ; (this should only loop once because of error check above)
    while (p0lon lt -180) do p0lon = p0lon + 360
    while (p0lon gt  180) do p0lon = p0lon - 360

    sMap = {!MAP}
    sMap.projection = c_ProjNumber[index]
    sMap.up_name = pname   ; Fill in the name for convenience.
    sMap.a = semimajor     ; Save ellipsoid
    sMap.e2 = e2
    sMap.p0lon = p0lon
    sMap.p0lat = p0lat
    sMap.u0 = p0lon * dtor
    sMap.v0 = p0lat * dtor

    sMap.sino = (sMap.p0lat mod 90) ne 0 ? sin(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq 90 ? 1: -1)) : $
              ((sMap.p0lat mod 180) eq 0 ? 0 : (sMap.p0lat eq -90 ? -1: 1)))
    sMap.coso = (sMap.p0lat mod 90) ne 0? cos(sMap.v0) : $
      (sMap.p0lat ge 0 ? ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq 180 ? -1: 1)) : $
              ((sMap.p0lat mod 180) ne 0 ? 0 : (sMap.p0lat eq -180 ? -1: 1)))

    sMap.rotation = rot
    sMap.sinr = (rot mod 90) ne 0 ? sin(rot * dtor) : $
      (rot ge 0 ? ((rot mod 180) eq 0 ? 0 : (rot eq 90 ? 1: -1)) : $
              ((rot mod 180) eq 0 ? 0 : (rot eq -90 ? -1: 1)))
    sMap.cosr =(rot mod 90) ne 0? cos(rot * dtor) : $
      (rot ge 0 ? ((rot mod 180) ne 0 ? 0 : (rot eq 180 ? -1: 1)) : $
              ((rot mod 180) ne 0 ? 0 : (rot eq -180 ? -1: 1)))

    ; Compute position of Pole which is a distance of !PI/2 from
    ; (p0lon, p0lat), at an azimuth of rot CCW of north.
    pole = [0.0, $
              (cent_azim mod 90) ne 0 ? sin(cent_azim * dtor) : $
                (cent_azim ge 0 ? ((cent_azim mod 180) eq 0 ? 0 : (cent_azim eq 90 ? 1: -1)) : $
              ((cent_azim mod 180) eq 0 ? 0 : (cent_azim eq -90 ? -1: 1))), $
              (cent_azim mod 90) ne 0? cos(cent_azim * dtor) : $
                (cent_azim  ge 0 ? ((cent_azim  mod 180) ne 0 ? 0 : (cent_azim  eq 180 ? -1: 1)) : $
              ((cent_azim  mod 180) ne 0 ? 0 : (cent_azim  eq -180 ? -1: 1)))]

    ; Rotate to put origin at (0,1,0)
    p2 = MAP_PROJ_ROTATE(pole, 0, -p0lat, p0lon)
    plat = Asin(p2[2])
    cosla = SQRT(1 - p2[2]^2)
    if (cosla eq 0) then begin      ;On pole?
        plon = 0d
        sinln = 0d
        cosln = 1d
    endif else begin
        plon = ATAN(p2[1], p2[0])
        sinln = p2[1]/cosla
        cosln = p2[0]/cosla
    endelse

    ; lon/lat, sin(lat), cos(lat), xyz, Location of pole
    sMap.pole = [plon, plat, p2[2], cosla, p2]


    if (gctp ge 0) then begin

        ; The GCTP code and projection number.
        sMap.projection = 20  ; GCTP projection code
        sMap.simple = gctp    ; GCTP projection number
        sMap.p = projParams   ; GCTP projection parameters

        return, sMap   ; we're done for GCTP projections.

    endif ; gctp


    ; The rest of this function is only for IDL projections.

    ;   Simple projection?  (used for (psuedo) cylindricals)
    sMap.simple = (ABS(p0lat) le del) && (ABS(cent_azim) le del)

    ;special angles
     sin_stdp0 = (std_p[0] mod 90) ne 0 ? sin(std_p[0] * dtor) : $
      (std_p[0] ge 0 ? ((std_p[0] mod 180) eq 0 ? 0 : (std_p[0] eq 90 ? 1: -1)) : $
              ((std_p[0] mod 180) eq 0 ? 0 : (std_p[0] eq -90 ? -1: 1)))
     cos_stdp0 = (std_p[0] mod 90) ne 0? cos(std_p[0] * dtor) : $
      (std_p[0] ge 0 ? ((std_p[0] mod 180) ne 0 ? 0 : (std_p[0] eq 180 ? -1: 1)) : $
              ((std_p[0] mod 180) ne 0 ? 0 : (std_p[0] eq -180 ? -1: 1)))

     sin_stdp1 = (std_p[1] mod 90) ne 0 ? sin(std_p[1] * dtor) : $
      (std_p[1] ge 0 ? ((std_p[1] mod 180) eq 0 ? 0 : (std_p[1] eq 90 ? 1: -1)) : $
              ((std_p[1] mod 180) eq 0 ? 0 : (std_p[1] eq -90 ? -1: 1)))
     cos_stdp1 = (std_p[1] mod 90) ne 0? cos(std_p[1] * dtor) : $
      (std_p[1] ge 0 ? ((std_p[1] mod 180) ne 0 ? 0 : (std_p[1] eq 180 ? -1: 1)) : $
              ((std_p[1] mod 180) ne 0 ? 0 : (std_p[1] eq -180 ? -1: 1)))

    std_p = std_p * dtor

    switch pname of

    'Lambert Conic': ; fall thru
    'Lambert Ellipsoid Conic': ; fall thru
    'Albers Equal Area Conic': begin

        ; Do same error checking for all conics.
        if (ABS(p0lat) eq 90) then MESSAGE, /NONAME, $
            'Center may not be pole for conic projections.'
        if (abs(std_p[0] + std_p[1]) lt del) then $
            MESSAGE, /NONAME, 'Standard parallels cannot be equal and ' + $
                'on opposite sides of Equator.'
              
        ; Now set up specific projection.
        case pname of

            'Lambert Conic': begin
                n = (std_p[0] eq std_p[1]) ? sin_stdp0 : $
                    alog(cos_stdp0/cos_stdp1) / $
                    alog(tan(!dpi/4+std_p[1]/2)/tan(!dpi/4+std_p[0]/2))
                F = cos_stdp0 * tan(!dpi/4 + std_p[0]/2)^n/n
                rho0 = F/tan(!dpi/4d + sMap.v0/2d)^n
                sMap.p = [n, F, rho0, std_p, 0.0]
                end

            'Lambert Ellipsoid Conic': begin
                e = sqrt(e2)
                ;Compute n, F, r0 using formulae from Snyder, Page 107-108.
                m = cos(std_p) / sqrt(1.0d0- e2 * sin(std_p)^2)
                t = [sMap.v0, std_p[0], std_p[1]] ;Angles for t
                t = tan(!dpi/4 - t/2.0) / $
                  ((1.0 - e * sin(t)) / (1.0 + e*sin(t)))^(e/2.)
                n = (std_p[0] eq std_p[1]) ? sin_stdp0 : $
                    (alog(m[0]) - alog(m[1])) / (alog(t[1]) - alog(t[2]))
                F = m[0] / (n * t[1] ^ n)
                rho0 = semimajor * F * t[0]^n
                sMap.p = [n, F, rho0, std_p]
                end

            'Albers Equal Area Conic': begin
                n = (sin_stdp0 + sin_stdp1)/2.
                c = cos_stdp0^2 + 2 * n * sin_stdp0
                rho0 = sqrt(c - 2d*n*sMap.sino)/n
                sMap.p = [n, c, rho0, std_p]
                end

        endcase

        break ; out of conics
        end

    'Satellite': begin ;Special params for satellite projection.

        shgt = (satHeight ne 0d) ? satHeight : sMap.a
        ; Convert from height to distance in radii from center
        sMap.p[0] = 1d + shgt/sMap.a

        ; sat(1) = TRUE for simple case (Vertical perspective)
        omega = (N_ELEMENTS(satTilt) eq 1) ? dtor*satTilt : 0d
        sMap.p[1] = omega
        sMap.p[2] = (satTilt mod 90) ne 0 ? sin(omega) : $
          (satTilt ge 0 ? ((satTilt mod 180) eq 0 ? 0 : (satTilt eq 90 ? 1: -1)) : $
              ((satTilt mod 180) eq 0 ? 0 : (satTilt eq -90 ? -1: 1)))  ;Somega = p[1]
        sMap.p[3] = (satTilt mod 90) ne 0 ? cos(omega) : $
          (satTilt ge 0 ? ((satTilt mod 180) ne 0 ? 0 : (satTilt eq 180 ? -1: 1)) : $
              ((satTilt mod 180) ne 0 ? 0 : (satTilt eq -180 ? -1: 1)))  ;comega
        break
        end

    'Transverse Mercator': begin ;Special params for UTM
        ;   ellipsoid is a 3 element array containing the ellipsoid parameters:
        ;           [a, e^2, k0]
        ;   a = Equatorial radius, in meters.
        ;   b = polar radius, b = a * (1-f), f = 1-b/a
        ;   e^2 = eccentricity^2 = 2*f-f^2, where f = flattening.
        ;   k0 = scale on central meridian, = 0.9996 for UTM.

        e_2 = e2/(1.0-e2)  ; Snyder Eqn 8-12
        ;           k0        e_2  e^2 m0  m
        sMap.p = [merc_scale, e_2, e2, 0., 0.]
        ; Transform projection center to determine map parameter m0.
        dummy = MAP_PROJ_FORWARD(p0lon, p0lat, MAP=sMap)
        sMap.p[3] = sMap.p[4]   ; m0 needs to be stored in p[3]
        break
        end

    ; Set up cylindrical projections
    'Cylindrical':
    'Mercator':
    'Mollweide':
    'Sinusoidal':
    'Aitoff':
    'Hammer Aitoff':
    'Miller Cylindrical':
    'Robinson':
    'Goodes Homolosine': begin
        ; I don't know why we can't solve for this angle (the azimuth of (u0,v0)
        ; from (xp, yp)) using the law of sines.  This is solving it the hard
        ; and long way.....  But it works....
        az = atan(sMap.coso * sin(sMap.u0-plon), $
                  cosla * sMap.sino - p2[2] * sMap.coso * cos(sMap.u0-plon))
        sMap.p[0] = !DPI/2d - az
        break
        end

    ; Do nothing for non-cylindrical projections
    'Geographic':        ; fall thru
    'Stereographic':     ; fall thru
    'Orthographic':      ; fall thru
    'Lambert Azimuthal': ; fall thru
    'Gnomonic':          ; fall thru
    'Azimuthal Equidistant': break

    else: MESSAGE, 'Internal error: Unknown projection type.'
    endswitch

    return, sMap

end


;---------------------------------------------------------------------------
; Convert from Projection argument to internal projection index.
;
function map_proj_checkprojection, projectionIn, $
    GCTP=gctp, $
    HOM_AZIM_ANGLE=homAngle, HOM_AZIM_LONGITUDE=homLon, $
    SOM_LANDSAT_NUMBER=somNum, SOM_LANDSAT_PATH=somPath, $
    STANDARD_PAR1=sPar1, STANDARD_PAR2=sPar2

    compile_opt idl2, hidden

@map_proj_init_commonblock

    ON_ERROR, 2  ; return to caller

    ; Default is geographic (no projection).
    if (N_ELEMENTS(projectionIn) lt 1) then return, 0

    ; String was supplied?
    if (SIZE(projectionIn, /TYPE) eq 7) then begin

        ; Find closest matching projection name.
        sName = STRUPCASE(STRCOMPRESS(projectionIn, /REMOVE_ALL))
        match = STRCMP(c_ProjCompressNames, sName, $
            STRLEN(sName), /FOLD_CASE)

        ; If there are multiple matches then use GCTP keyword to restrict.
        ; GCTP=-1 (IDL projections) is the default.
        ; If there is only 1 match, ignore the GCTP keyword.
        if (TOTAL(match) gt 1) then begin
          ; Special cases for "A" and "B" forms of projections.
          ; Allow the generic name, and switch based on the keywords.
          case sName of
          'EQUIDISTANTCONIC': begin
            type = (ISA(sPar1) || ISA(sPar2)) ? 'B' : 'A'
            match = c_ProjCompressNames eq 'EquidistantConic' + type
            end
          'HOTINEOBLIQUEMERCATOR': begin
            type = (ISA(homAngle) || ISA(homLon)) ? 'B' : 'A'
            match = c_ProjCompressNames eq 'HotineObliqueMercator' + type
            end
          'SPACEOBLIQUEMERCATOR': begin
            type = (ISA(somNum) || ISA(somPath)) ? 'B' : 'A'
            match = c_ProjCompressNames eq 'SpaceObliqueMercator' + type
            end
          else: begin
            ; User either set GCTP=1 or GCTP=0
            restrict = KEYWORD_SET(gctp) ? $
                (c_ProjNumToGCTP ge 0) : (c_ProjNumToGCTP eq -1)
            match = match and restrict
            end
          endcase
        endif

        index = (WHERE(match, nMatch))[0]

        if (nMatch eq 0) then MESSAGE, /NONAME, $
            'Invalid Projection name: ' + projectionIn

        if (nMatch ne 1) then MESSAGE, /NONAME, $
            'Ambiguous Projection abbreviation: ' + projectionIn


    endif else begin  ; Number was supplied.

        ; Make sure projection number is within range.
        index = (WHERE(c_ProjNumber eq LONG(projectionIn)))[0]

        if (index lt 0) then $
            MESSAGE, /NONAME, $
            'Invalid Projection number: ' + STRTRIM(projectionIn)

    endelse

    return, index
end


;---------------------------------------------------------------------------
; Check ellipsoid code and convert to semimajor/minor axes.
; If ellipsoid is a string, replaces its value with the corresponding index.
;
function map_proj_getellipsoid, ellipsoid

    compile_opt idl2, hidden

@map_proj_init_commonblock

    ON_ERROR, 2  ; return to caller

    ; String was supplied?
    if (SIZE(ellipsoid, /TYPE) eq 7) then begin
        ; Find closest matching name.
        ellipsoidIn = ellipsoid
        ellipsoidCheck = STRCOMPRESS(ellipsoidIn, /REMOVE_ALL)
        all = STRCOMPRESS(c_EllipsoidNames, /REMOVE_ALL)
        ellipsoid = (WHERE(STRCMP(all, ellipsoidCheck, $
            STRLEN(ellipsoidCheck), /FOLD_CASE), nMatch))[0]
        case nMatch of
            0: MESSAGE, /NONAME, $
                'Invalid value for keyword ELLIPSOID: ' + ellipsoidIn
            1: ; Valid ellipsoid.
            else: MESSAGE, /NONAME, 'Ambiguous ELLIPSOID abbreviation: ' $
                + ellipsoidIn
        endcase
    endif else begin
        ; Make sure ellipsoid number is within range.
        ellipsoid = LONG(ellipsoid)
        if (ellipsoid ge N_ELEMENTS(c_EllipsoidNames)) then $
            MESSAGE, /NONAME, $
            'Invalid value for keyword ELLIPSOID: ' + STRTRIM(ellipsoid)
    endelse

    result = [c_EllipsoidMajor[ellipsoid], c_EllipsoidMinor[ellipsoid]]

    ; GCTP only knows about ellipsoids up to 19. The extra ellipsoids
    ; are simply supplied as semimajor/semiminor.
    if (ellipsoid gt 19) then $
        ellipsoid = -1

    return, result

end


;---------------------------------------------------------------------------
; Check all keywords, match up with parameters.
;
function map_proj_checkparams, index, $
    ELLIPSOID=ellipsoidIn, $
    RELAXED=relaxed, $ ; Don't object to extraneous projection params.
    _EXTRA=_extra

    compile_opt idl2, hidden

@map_proj_init_commonblock

    ON_ERROR, 2  ; return to caller

    nParams = N_TAGS(_extra)

    ; Pull out allowed parameter names for projection.
    projParamNames = c_ProjParameters[*,index]


    projParams = DBLARR(16)


    ; Get the default spheroid parameters.
    ellipsoid = (N_ELEMENTS(ellipsoidIn) gt 0) ? ellipsoidIn : $
        (c_ProjParameters[0,index] eq 'SPHERE_RADIUS') ? 19 : 0
    projParams[0:1] = MAP_PROJ_GETELLIPSOID(ellipsoid)

    ; Default parameters for various projections.
    case c_ProjNames[index] of

        ; UTM longitude/latitude
        'UTM': projParams[0:1] = 0

        ; Default for MERCATOR_SCALE parameter depends upon the projection.
        'Transverse Mercator': projParams[2] = 0.9996d
        'Hotine Oblique Mercator A': projParams[2] = 1
        'Hotine Oblique Mercator B': projParams[2] = 1

        else:  ; default is zero for other parameters
    endcase

    ; Stash the ellipsoid number into the last projection param slot.
    projParams[-1] = ellipsoid

    if (nParams eq 0) then return, projParams

    isGctp = (c_ProjNumToGCTP[index] ge 0)
    notRelax = ~KEYWORD_SET(relaxed)
    paramSupplied = TAG_NAMES(_extra)
    suppliedKeywords = ''

    for i=0,nParams-1 do begin
        slen = STRLEN(paramSupplied[i])

        ; First check for ambiguous keywords among all keywords.
        anymatch = WHERE(STRCMP(c_keywordNames, paramSupplied[i], $
            slen, /FOLD_CASE), nAny)

        if (nAny eq 0) then begin
          if (notRelax) then MESSAGE, /NONAME, 'Keyword ' + paramSupplied[i] + $
            ' not allowed in call to: MAP_PROJ_INIT'
          ; If /relaxed, just quietly ignore any unknown keywords.
          continue
        endif else if (nAny gt 1) then begin   ; Matched more than one.
          MESSAGE, /NONAME, 'Ambiguous keyword abbreviation: ' $
             + paramSupplied[i] + '.'
        endif

        ; Valid keyword, pull out the actual keyword name, rather than
        ; the (possibly shortened) keyword name that user supplied.
        paramMatch = c_keywordNames[anymatch[0]]

        ; Now look for match among projection-specific keywords.
        match = WHERE(projParamNames eq paramMatch, nMatch)
        if (nMatch eq 1) then begin
            suppliedKeywords = [suppliedKeywords, paramMatch]
            projParams[match] = _extra.(i)

        endif else begin
            if (notRelax) then begin
                allowed = ''
                ; We need to remove any null strings or strings of length 1,
                ; since these are just markers within the param list.
                good = WHERE(STRLEN(projParamNames) gt 1, ngood)
                if (ngood gt 0) then begin
                    p = projParamNames[good]
                    allowed = '. Allowed parameters include: ' + $
                        STRING(p[SORT(p)], FORMAT='(255(A,:,", "),".")')
                endif
                MESSAGE, /NONAME, 'Parameter ' + paramMatch + $
                    ' not allowed for projection: ' + $
                    c_ProjNames[index] + allowed + '.'
            endif
        endelse
    endfor

    ; CR56285: In IDL 8.0 we changed the GCTP Polar Stereographic to
    ; use TRUE_SCALE_LATITUDE instead of CENTER_LATITUDE.
    ; However, for backwards compatibility, if the user specified
    ; the CENTER_LATITUDE (and TRUE_SCALE_LATITUDE was zero) then
    ; use that for the true scale latitude.
    if (c_ProjNames[index] eq 'Polar Stereographic') then begin
      trueScale = projParams[5]
      centerLat = projParams[8]
      if (trueScale eq 0) then projParams[5] = centerLat
      ; If we did not have the old CENTER_LATITUDE keyword,
      ; then clear out the parameter, so map.p0lat doesn't get set
      ; incorrectly.
      hasCenterLatKW = MAX(STRCMP(paramSupplied, 'CENTER_LAT', 10)) eq 1
      if (~hasCenterLatKW) then projParams[8] = 0
    endif


    ; A few GCTP projections have 2 forms. The last parameter for these
    ; projections is either a zero or a one. Fill in the 1 if necessary.
    ones = WHERE(projParamNames eq '1', count)
    if (count gt 0) then projParams[ones] = 1

    ; Pairs of keywords that must be supplied together.
    pairs = [ $
        ['SEMIMAJOR_AXIS', 'SEMIMINOR_AXIS'], $
        ['STANDARD_PAR1', 'STANDARD_PAR2']]

    ; Check for specific keyword pairs.
    for i=0,N_ELEMENTS(pairs)/2-1 do begin
        hasEither = (suppliedKeywords eq pairs[0,i]) or $
            (suppliedKeywords eq pairs[1,i])
        if (TOTAL(hasEither) eq 1) then MESSAGE, 'Keywords ' + pairs[0,i] + $
            ' and ' + pairs[1,i] + ' must both be supplied.'
    endfor

    ; If necessary,set ellipsoid to -1 to alert GCTP that the user
    ; supplied the semimajor axis or radius, rather than a ellipsoid code.
    ; This is irrelevant for IDL projections.
    if (TOTAL((suppliedKeywords eq 'SEMIMAJOR_AXIS') or $
        (suppliedKeywords eq 'SPHERE_RADIUS')) gt 0) then ellipsoid = -1

    ; Stash the ellipsoid number into the last projection param slot.
    projParams[-1] = ellipsoid

    return, projParams
end


;---------------------------------------------------------------------------
function map_proj_init, projectionIn, $
    DATUM=datumIn, $     ; Spheroid or Datum code (obsolete keyword)
    ELLIPSOID=ellipsoidIn, $  ; Spheroid code
    GCTP=gctpIn, $       ; Boolean. Ignored if Projection is a number.
    LIMIT=limit, $       ; [Lon1, Lat1, Lon2, Lat2]
    RADIANS=radians, $   ; Angles are in radians.
    RELAXED=relaxed, $   ; Don't object to extraneous projection params.
    SPHERE_RADIUS=sphereRadiusIn, $
    SEMIMAJOR_AXIS=semiMajor, $
    SEMIMINOR=semiMinor, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ON_ERROR, 2  ; return to caller

@map_proj_init_commonblock

    ; Convert from Projection argument to internal projection index.
    index = MAP_PROJ_CHECKPROJECTION(projectionIn, $
        GCTP=gctpIn, _EXTRA=_extra)

    if (N_Elements(datumIn) gt 0) then begin
        ellipsoidIn = datumIn
    endif
    
    if KEYWORD_SET(sphereRadiusIn) then sphereRadius = sphereRadiusIn

    ; In IDL 8.0 we added ellipsoid support to the GCTP Lambert Azimuthal.
    ; For backwards compatibility, if the user suppplied sphere radius,
    ; just use that for the major/minor axes instead of throwing an error.
    if (c_ProjNames[index] eq 'Lambert Azimuthal' && KEYWORD_SET(gctpIn) && $
      KEYWORD_SET(sphereRadiusIn) && ~KEYWORD_SET(semiMajor)) then begin
      semiMajor = sphereRadius
      semiMinor = sphereRadius
      sphereRadius = !NULL
    endif

    ; Check that all keywords, match up with parameters.
    projParams = MAP_PROJ_CHECKPARAMS( index, $
        ELLIPSOID=ellipsoidIn, $
        RELAXED=relaxed, $
        SPHERE_RADIUS=sphereRadius, $
        SEMIMAJOR_AXIS=semiMajor, $
        SEMIMINOR=semiMinor, $
        _EXTRA=_extra)

    ; Construct the !MAP structure for projection.
    sMap = MAP_PROJ_MAP_STRUCTURE(index, projParams, $
        RADIANS=radians)

    if (sMap.projection eq 20) then begin   ; GCTP projection

        ; Pull out the zone for UTM or State Plane.
        gctpZone = (sMap.simple eq 1 || sMap.simple eq 2) ? sMap.p[2] : 0
        ; Pull out the ellipsoid number.
        ellipsoid = sMap.p[-1]

        ; Internal routines to initialize GCTP forward and inverse
        ; projections. Use at your own peril.
        MAP_PROJ_GCTP_FORINIT, sMap.simple, gctpZone, sMap.p, ellipsoid
        MAP_PROJ_GCTP_REVINIT, sMap.simple, gctpZone, sMap.p, ellipsoid


    endif

    MAP_PROJ_SET_CLIP, index, sMap, $
        LIMIT=limit

    return, sMap
end

