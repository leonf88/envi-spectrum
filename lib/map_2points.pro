; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_2points.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	Map_2Points
;
; PURPOSE:
;	Return parameters such as distance, azimuth, and path relating to
;	the great circle or rhumb line connecting two points on a sphere.
;
; CATEGORY:
;	Maps.
;
; CALLING SEQUENCE:
;	Result = Map_2Points(lon0, lat0, lon1, lat1)
; INPUTS:
;	Lon0, Lat0 = longitude and latitude of first point, P0.
;	Lon1, Lat1 = longitude and latitude of second point, P1.
;
; KEYWORD PARAMETERS:
;   RADIANS = if set, inputs and angular outputs are in radians, otherwise
;	degrees.
;   NPATH, DPATH = if set, return a (2, n) array containing the
;	longitude / latitude of the points on the great circle or rhumb
;	line connecting P0 and P1.  If NPATH is set, return NPATH equally
;	spaced points.  If DPATH is set, it specifies the maximum angular
;	distance between the points on the path in the prevalent units,
;	degrees or radians.
;   PARAMETERS: if set, return [sin(c), cos(c), sin(az), cos(az)]
;	the parameters determining the great circle connecting the two
;	points.  c is the great circle angular distance, and az is the
;	azimuth of the great circle at P0, in degrees east of north.
;   METERS: Return the distance between the two points in meters,
;	calculated using the Clarke 1866 equatorial radius of the earth.
;   MILES: Return the distance between the two points in miles,
;	calculated using the Clarke 1866 equatorial radius of the earth.
;   RADIUS: If given, return the distance between the two points
;	calculated using the given radius.
;   RHUMB: Set this keyword to return the distance and azimuth of the
;	rhumb line connecting the two points, P0 to P1. The default is to
;	return the distance and azimuth of the great circle connecting the
;	two points.  A rhumb line is the line of constant direction
;	connecting two points.
;
; OUTPUTS:
;	If the keywords NPATH, DPATH, METERS, MILES, or RADIUS, are not
;	specified, the function result is a two element vector containing
;	the distance and azimuth of the great circle or rhumb line
;	connecting the two points, P0 to P1, in the specified angular units.
;
;	If MILES, METERS, or RADIUS is not set, Distances are angular
;	distance, from 0 to 180 degrees (or 0 to !pi if the RADIANS keyword
;	is set), and Azimuth is measured in degrees or radians, east of north.
;
; EXAMPLES:
;	Given the geocoordinates of two points, Boulder and London:
;	B = [ -105.19, 40.02]	;Longitude, latitude in degrees.
;	L = [ -0.07,   51.30]
;
;	print, Map_2Points(B[0], B[1], L[0], L[1])
; prints: 67.854333 40.667833 for the angular distance and
; azimuth, from B, of the great circle connecting the two
; points.
;
;	print, Map_2Points(B[0], B[1], L[0], L[1],/RHUMB)
; prints 73.966280 81.228056, for the angular distance and
; course (azimuth), connecting the two points.
;
;	print, Map_2Points(B[0], B[1], L[0], L[1],/MILES)
; prints:  4693.5845 for the distance in miles between the two points.
;
;	print, Map_2Points(B[0], B[1], L[0], L[1], /MILES,/RHUMB)
; prints: 5116.3569, the distance in miles along the rhumb line
; connecting the two points.
;
; The following code displays a map containing the two points, and
; annotates the map with both the great circle and the rhumb line path
; between the points, drawn at one degree increments.
;	MAP_SET, /MOLLWEIDE, 40,-50, /GRID, SCALE=75e6,/CONTINENTS
;	PLOTS, Map_2Points(B[0], B[1], L[0], L[1],/RHUMB, DPATH=1)
;	PLOTS, Map_2Points(B[0], B[1], L[0], L[1],DPATH=1)
;
;
; MODIFICATION HISTORY:
; 	Written by:
;	DMS, RSI	May, 2000. Written.
;   CT, RSI, September 2001: For /RHUMB, reduce lon range to -180,+180
;   CT, RSI, September 2002: For /RHUMB, fix computation at poles.
;-

Function Map_2points, lon0, lat0, lon1, lat1, $
            DPATH=dPath, $
            METERS=meters, $
            MILES=miles, $
            NPATH=nPath, $
            PARAMETERS=p, $
            RADIANS=radians, $
            RADIUS=radius, $
            RHUMB=rhumb

COMPILE_OPT idl2
ON_ERROR, 2  ; return to caller

IF (N_PARAMS() LT 4) THEN $
	MESSAGE, 'Incorrect number of arguments.'
mx = MAX(ABS([lat0,lat1]))
pi2 = !dpi/2
IF (mx GT (KEYWORD_SET(radians) ? pi2 : 90)) THEN $
	MESSAGE, 'Value of Latitude is out of allowed range.'
IF (N_ELEMENTS(nPath) GT 0) THEN IF (nPath LT 2) THEN $
	MESSAGE, 'Illegal keyword value for NPATH.'

k = KEYWORD_SET(radians) ? 1.0d0 : !dpi/180.0
r_earth = 6378206.4d0 ;Earth equatorial radius, meters, Clarke 1866 ellipsoid

if keyword_set(rhumb) then begin ;Rhumb line section
    x1 = (lon1-lon0)*k          ;Delta longit, to radians
    while x1 lt -!Dpi do x1 = x1 + 2*!DPI ;Reduce to -180 + 180.
    while x1 ge !Dpi do x1 = x1 - 2*!DPI
    lr0 = lat0 * k
    lr1 = lat1 * k

    ; Mercator y coordinates. Avoid computing alog(0).
    y0 = alog(tan(!dpi/4 + lr0 / 2) > 1d-300)
    y1 = alog(tan(!dpi/4 + lr1 / 2) > 1d-300)

    Az = atan(x1, y1-y0)
; S is the angular distance between points, in radians.
    s = (lr0 ne lr1) ? (lr1-lr0)/cos(Az) : abs(x1) * cos(lr0)

    if keyword_set(nPath) or keyword_set(dPath) then begin ;Compute a path?
        n = keyword_set(dPath) ? ceil(s / (dPath*k)) > 2 : (nPath > 2)
        x = dindgen(n) * (x1 / (n-1))
        y = y0 + dindgen(n) * ((y1-y0) / (n-1))
        lat = pi2 - 2 * atan(exp(-y))
        lon = x + lon0*k
        return, transpose([[lon/k], [lat/k]])
    endif
    if keyword_set(radius) then $ ;Radius supplied? Return distance.
      return, s * radius
    if keyword_set(meters) then $ ;Meters?
      return, s * r_earth
    if keyword_set(miles) then $ ;Miles?
      return, s * r_earth * 0.6213712d-3 ;Meters->miles
    return, [s/k, Az/k]         ;Return distance, course (azimuth)
endif


coslt1 = cos(k*lat1)
sinlt1 = sin(k*lat1)
coslt0 = cos(k*lat0)
sinlt0 = sin(k*lat0)

cosl0l1 = cos(k*(lon1-lon0))
sinl0l1 = sin(k*(lon1-lon0))

cosc = sinlt0 * sinlt1 + coslt0 * coslt1 * cosl0l1 ;Cos of angle between pnts
; Avoid roundoff problems by clamping cosine range to [-1,1].
cosc = -1 > cosc < 1
sinc = sqrt(1.0 - cosc^2)

if abs(sinc) gt 1.0e-7 then begin ;Small angle?
    cosaz = (coslt0 * sinlt1 - sinlt0*coslt1*cosl0l1) / sinc ;Azmuith
    sinaz = sinl0l1*coslt1/sinc
endif else begin		;Its antipodal
    cosaz = 1.0
    sinaz = 0.0
endelse

if keyword_set(print) then begin
    print, 'Great circle distance: ', acos(cosc) / k
    print, 'Azimuth: ', atan(sinaz, cosaz)/k
endif

if keyword_set(p) then $        ;Return parameters of great circle?
  return, [sinc, cosc, sinaz, cosaz] ;Return parameters

if keyword_set(nPath) or keyword_set(dPath) then begin ;Compute a path?
    s = acos(cosc)              ;Angular distance between points
    if keyword_set(nPath) then begin ;Desired # of elements req?
        s0 = dindgen(nPath > 2) * (s / (nPath > 2 -1))
    endif else begin            ;Distance between pnts specified..
        delc = dPath * k        ;Angle between points
        s0 = dindgen(ceil(s / delc) + 1) * delc < s ;Last step might be smaller
    endelse

    sins = sin(s0)
    coss = cos(s0)
    lats = asin(sinlt0 * coss + coslt0 * sins * cosaz) / k
    lons = lon0 + atan(sins * sinaz, coslt0 * coss - sinlt0 * sins * cosaz)/k
    return, transpose([[lons], [lats]])
endif

if keyword_set(radius) then $   ;Radius supplied? Return distance.
  return, acos(cosc) * radius
if keyword_set(meters) then $   ;Meters?
  return, acos(cosc) * r_earth
if keyword_set(miles) then $    ;Miles?
  return, acos(cosc) * r_earth * 0.6213712d-3 ;Meters->miles

return, [acos(cosc) / k, atan(sinaz, cosaz) / k] ;Return distance, azimuth
end
