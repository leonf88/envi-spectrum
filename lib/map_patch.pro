; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_patch.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

function map_reduce_360, a  ;Reduce an angle to the range of +- 180.
COMPILE_OPT idl2, hidden

b = a mod 360.
neg = where(b lt 0, count)
if count gt 0 then b[neg] = b[neg]+360.
return, b
end


;+
;NAME:
;     map_patch
;PURPOSE:
;   This function linearly interpolates a data sampled in
;   latitude/longitude into device space.  Data values may be
;   either rectangularly or irregularly gridded over the globe.
;Category:
;        Mapping
;Calling Sequence:
;        result = map_patch(Image_Orig [, Lons] [, Lats])
;INPUT:
;      Image_Orig- A array containing the data to be overlayed on map.
;       It may be either 1D or 2D.  If 2D, it has Nx columns,
;       and Ny rows.  The cell connectivity must be
;       rectangular, unless the TRIANGULATE keyword is specified.
;       If Image_Orig is 1D, then Lats and Lons must contain
;       the same number of points.
;   Lons-   A vector or 2D array containing the longitude of each
;       data point or column.  If Lons is 1D, lon(image_orig(i,j)) =
;       Lons(i); if Lons is 2D, lon(image_orig(i,j)) = Lons(i,j).
;       This optional parameter may be omitted if the
;       longitudes are equally spaced and are
;       specified with the LON0 and LON1 keywords.
;   Lats-   A vector or 2D array containing the latitude of each
;       data point or row  If Lats is 1D, lat(image_orig(i,j))
;       = Lats(j); if Lats is 2D, lat(image_orig(i,j)) =
;       Lat(i,j). This optional parameter may be omitted
;       if the latitudes are equally spaced and are specified
;       with the LAT0 and LAT1 keywords.
;KEYWORDS:
;   LAT0-   The latitude of the first row of data.  Default=-90.
;   LAT1-   The latitude of the last row of data.  Default=+90.
;   LATMIN, LATMAX - For compatibility with MAP_IMAGE, the
;                        latitude range of equally spaced cells may be
;                        specified using these keywords, rather than
;                        with LAT0 and LAT1.
;   LON0-   The longitude of the first column of data.  Default=-180.
;   LON1-   The longitude of the last column of data.  Default=180-360/Ny.
;   LONMIN, LONMAX - For compatibility with MAP_IMAGE, the
;                        longitude range of equally spaced cells may be
;                        specified using these keywords, rather than
;                        with LON0 and LON1.
;   MISSING = value to set areas outside the valid map coordinates.
;       If omitted, areas outside the map are set to 255 (white) if
;       the current graphics device is PostScript, or 0 otherwise.
;   MAX_VALUE = values in Image_Orig greater than MAX_VALUE
;       are considered missing.  Pixels in the output image
;       that depend upon missing pixels will be set to MISSING.
;   TRIANGULATE = if set, the points are Delauny triangulated on
;       the sphere using the TRIANGULATE procedure to determine
;       connectivity.   Otherwise, rectangular connectivity is assumed.
; Optional Output Keywords:
;   xstart --- the  x coordinate where the left edge of the image
;       should be placed on the screen.
;   ystart --- the y coordinate where th bottom edge of the image
;       should be placed on the screen.
;   xsize ---  returns the width of the resulting image expressed in
;       graphic coordinate units.  If current graphics device has
;       scalable pixels,  the value of XSIZE and YSIZE should
;       be passed to the TV procedure.
;   ysize ---  returns the pixel height of the resulting image, if the
;       current graphics device has scalable pixels.
;
; Restrictions:
;   This could be quicker.
; Output:
;      The interpolated function/warped image is returned.
;
; Procedure:
;   An object space algorithm is used, so the time required
;   is roughly proportional to the size, in elements, of Image_Orig.
;   Computations are performed in floating point.
;   For rectangular grids, each rectangular cell of the original
;   image is divided by a diagonal, into two triangles.  If
;   TRIANGULATE is set, indicating irregular gridding, the cells are
;   triangulated.  The trianges are then converted from lat/lon to
;   image coordinates and then interpolated into
;   the image array using TRIGRID.
;
;MODIFICATION HISTORY:
;   DMS of RSI, July, 1994.     Written.
;   DMS, Nov, 1996. Rewritten and adapted for new maps, rev 2.
;-
FUNCTION  map_patch, Image_Orig, Lons, Lats, $
        XSTART = xstart, YSTART = ystart, $
        XSIZE = xsize, YSIZE = ysize, $
        LON0 = lon0, LON1 = lon1, $
        LAT0 = lat0, LAT1 = lat1, $
                LATMIN=latmin_in, LATMAX=latmax_in, $
                LONMIN=lonmin_in, LONMAX=lonmax_in, $
        MISSING = missing, MAX_VALUE = max_value, $
        TRIANGULATE=triangulate, DEBUG = debug

compile_opt idl2

ON_ERROR,2

if (!x.type NE 2) and (!x.type ne 3) THEN  $        ;Need Mapping Coordinates
  message, "Current window must have map coordinates"

s = size(Image_Orig)
Nx = s[1]                       ; # of columns
if s[0] eq 2 then Ny = s[2] else Ny = 1 ; # of rows
n = N_elements(Image_orig)

if n_elements(lons) eq 0 then begin ;Make longitudes?
    if n_elements(lon0) le 0 then $
      if n_elements(lonmin_in) then lon0 = lonmin_in else lon0 = -180.
    if n_elements(lon1) le 0 then $
      if n_elements(lonmax_in) then lon1 = lonmax_in else lon1 = 180. ;As documented
;    if n_elements(lon1) le 0 then lon1 = lon0 - 360./nx + 360. ;as it was
    dx = lon1-lon0
    if dx le 0 then dx = dx + 360.
    lons = findgen(nx) * (dx/(nx-1.)) + lon0
endif

if n_elements(lats) eq 0 then begin ;Make lats?
    if n_elements(lat0) le 0 then $
      if n_elements(latmin_in) then lat0 = latmin_in else lat0 = -90.
    if n_elements(lat1) le 0 then $
      if n_elements(latmax_in)then lat1 = latmax_in else lat1 = 90.
    lats = findgen(ny) * ((lat1-lat0)/(ny-1.)) + lat0
endif

if n_elements(lats) ne ny and n_elements(lats) ne n then $
  message, "Lats has incorrect size"
if n_elements(lons) ne nx and n_elements(lons) ne n then $
  message, "Lons has incorrect size"

lonmin = min(lons, MAX=lonmax)
latmin = min(lats, MAX=latmax)
wrap = abs(map_reduce_360(lonmax + 360./nx-lonmin)) lt 1e-4
if wrap eq 0 then lnlim = [lonmin, lonmax] else lnlim = [-180., 180.]
ltlim = [latmin, latmax]
scale = !d.flags and 1      ;TRUE if device has scalable pixels

IF scale THEN BEGIN     ;Fudge for postscript?
    scalef = 0.02       ;PostScript scale factor
    scale_orig = [!x.s, !y.s]
    !x.s = !x.s * scalef
    !y.s = !y.s * scalef
ENDIF ELSE scalef = 1

xw = scalef * !x.window         ;Map extent in normalized coords
yw = scalef * !y.window

xw1 = !map.uv_box[[0,2]] * !x.s[1] + !x.s[0]
yw1 = !map.uv_box[[1,3]] * !y.s[1] + !y.s[0]

;Screen extent of our image in device coords
screen_x = long([ xw[0] > xw1[0], xw[1] < xw1[1] ] * !d.x_size)
screen_y = long([ yw[0] > yw1[0], yw[1] < yw1[1] ] * !d.y_size)

if n_elements(max_value) eq 0 then max_value = max(Image_orig)
if n_elements(missing) le 0 then missing = 0

rect = [screen_x[0], screen_y[0], screen_x[1]-1, screen_y[1]-1]

if keyword_set(triangulate) then begin ;Make our own triangulation?
    if n_elements(lons) eq n_elements(image_orig) then x = lons $
    else if n_elements(lons) eq nx then x = lons # replicate(1., ny) $
    else message, 'Dimension of LONS incompatible'

    if n_elements(lats) eq n_elements(image_orig) then y = lats $
    else if n_elements(lats) eq ny then y =  replicate(1.,nx) # lats $
    else message, 'Dimension of LATS incompatible'

; Use QHULL for triangulation. We used to use TRIANGULATE, SPHERE=, but
; QHULL is faster and more stable for sphereical triangulation.
    QHULL, x, y, triangles, SPHERE=s
    s = 0                       ;don't need it
    x = trigrid(x, y, image_orig, triangles, [1., 1.], rect, $
                MAX_VALUE=max_value, MISSING = missing, $
                MAP=[!x.s * !d.x_size, !y.s * !d.y_size])

endif else begin        ;Make a regular triangular grid

                                ; Make 2D lat/lon arrays
    if n_elements(lons) eq nx then x = lons # replicate(1., ny) $
    else x = lons
    if n_elements(lats) eq ny then y = replicate(1.,nx) # lats $
    else y = lats
    nr = nx - 1 + wrap      ;If wrap, connect last row to first
    do_north = abs(latmax-90.) lt 1.0e-3
    do_south = abs(latmin+90.) lt 1.0e-3
;       # of rows of triangles, 2 / row, except at poles.
    nr1 = 2 * (ny-1) - do_north - do_south
    i = (nx-1) * 6              ;Vertices / row
    t = lonarr(nr * 6, /NOZERO) ;Typical row of rects
; Make our triangles in COUNTERCLOCKWISE order so they'll be properly clipped
; and split by the map routines.
    for i=0, nr-1 do t[i*6] = ([i,i+1,  i, i,i+1,i+1] mod nx) + $
      [0, nx, nx, 0,  0, nx]
    triangles = lonarr(nr1 * nr * 3, /NOZERO)
    j = 0L
    y0 = 0
    if do_south then begin
        for i=0, nr-1 do triangles[i*3] = ([i,i+1,i] mod nx) + [0, nx, nx]
        j = 3*nr
        y0 = 1
    endif
    if do_north then y1 = ny-3 else y1 = ny-2 ;Last row of rects
    for iy= y0, y1 do begin
        triangles[j] = t + iy * nx
        j = j + 6*nr
    endfor
    if do_north then $          ;Top row
      for i=0, nr-1 do triangles[j+i*3] = ([i, i+1, i] mod nx) + $
      [0,0, nx] + nx*(ny-2)

; Interpolate from the triangular grid, in lat/lon onto an image bitmap.
    x = trigrid(x, y, image_orig, triangles, [1., 1.], rect, $
                MAX_VALUE=max_value, MISSING = missing, $
                MAP=[!x.s * !d.x_size, !y.s * !d.y_size])
endelse                         ;triangular grid


xsize = ceil((rect[2] - rect[0] + 1)/scalef)
ysize = ceil((rect[3] - rect[1] + 1)/scalef)

xstart = long(rect[0] / scalef)
ystart = long(rect[1] / scalef)

if scale then begin     ;Restore scale
    !x.s = scale_orig[0:1] & !y.s = scale_orig[2:3]
    endif

return, x
end
