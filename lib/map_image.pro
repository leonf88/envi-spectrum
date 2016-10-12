; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_image.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
;+NODOCUMENT
;NAME:
;     map_image
;PURPOSE:
;       This function returns the Image_Orig image warped to fit
;       the current map. Image_Orig must be centered at 0.  This
;   routine works in image space.
;Category:
;        Mapping
;Calling Sequence:
;        result = map_image(Image_Orig [, Startx, Starty [, xsize, ysize]])
;INPUT:
;      Image_Orig--- A two-dimensional array representing geographical
;               image to be overlayed on map.  It has Nx columns,
;     and Ny rows.
;KEYWORDS:
;   LATMIN --- the latitude corresponding to the first row of Image_Orig.
;     The default value is -90.  Latitude and Longitude values
;     refer to the CENTER of each cell.
;   LATMAX --- the latitude corresponding to last row of Image_Orig. The
;     default is  90 - (180. / Ny).
;   LONMIN --- the longitude corresponding to the first [left] column of
;     Image_Orig. The default value is -180.  Lonmin must be
;     in the range of -180 to +180 degrees.
;   LONMAX --- the longitude corresponding to the last column
;     of Image_Orig. Lonmax must be larger than Lonmin.
;     If the longitude of the last column is equal to
;     (lonmin - (360. /Nx)) MODULO 360. it is assumed that
;                the image covers all longitudes.
;   BILINEAR --- A flag, if set, to request bilinear interpolation. The
;     default is nearest neighbor.  Bilinear appears much better.
;   COMPRESS --- Interpolation compression flag.  Setting this to
;     a higher number saves time --- lower numbers produce
;     more accurate results.  Setting this to 1
;     solves the inverse map transformation for every
;     pixel of the output image.  Default = 4 for output devices
;     with fixed pixel sizes. Fix is used to make this an int.
;   SCALE = pixel / graphics scale factor for devices with scalable
;     pixels (e.g. PostScript).  Default = 0.02 pixels/graphic_coord.
;     This yields an approximate output image size of 350 x 250.
;     Make this number larger for more resolution (and larger
;     PostScript files, and images), or smaller for faster
;     and smaller, less accurate images.
;
;   MASK: Set this keyword to a named variable in which to return
;       a byte array of the same dimensions as the Result, containing
;       a mask of the good values. Values in the Result that were
;       set to MISSING will have a mask value of zero, while all
;       other mask values will be one.
;
;   MAP_STRUCTURE: Set this keyword to a !MAP structure as returned
;       from MAP_PROJ_INIT, to be used instead of the default
;       !MAP projection. This keyword is useful if you want to display
;       the image in a UV (Cartesian) coordinate system,
;       instead of a map coordinate system. The Image is warped to
;       fit the current graphics range.
;
;   MISSING = value to set areas outside the valid map coordinates.
;     If omitted, areas outside the map are set to 255 (white) if
;     the current graphics device is PostScript, or 0 otherwise.
;   MAX_VALUE = values in Image_Orig greater than or equal to MAX_VALUE
;     are considered missing.  Pixels in the output image
;     that depend upon missing pixels will be set to MISSING.
;   MIN_VALUE = values in Image_Orig less than or equal to MIN_VALUE
;     are considered missing.
; Optional Output Parameters:
;   Startx --- the  x coordinate where the left edge of the image
;     should be placed on the screen.
;   Starty --- the y coordinate where th bottom edge of the image
;     should be placed on the screen.
;   xsize ---  returns the width of the resulting image expressed in
;     graphic coordinate units.  If current graphics device has
;     scalable pixels,  the value of XSIZE and YSIZE should
;     be passed to the TV procedure.
;   ysize ---  returns the pixel height of the resulting image, if the
;     current graphics device has scalable pixels.
;
;Output:
;      The warped image is returned.
;
; Procedure:  An image space algorithm is used, so the time required
;   is roughly proportional to the size of the final image.
;   For each pixel in the box enclosed by the current window,
;   and enclosed by the Image, the inverse coordinate transform is
;   applied to obtain lat/lon.  The lat/lon coordinates are then scaled
;   into image pixel coordinates, and these coordinates are then
;   interpolated from Image values.
;
;MODIFICATION HISTORY:
;       CAB, Feb, 1992. Map_image has been changed to handle images
;           crossing the international dateline in a more convenient way.
;           Specifically, it no longer requires that the keyword LONMIN be
;           greater than or equal to -180 or the keyword LONMAX be
;     less than or equal to 180.
;   DMS, Aug, 1992.  Completly rewritten.  Uses different algorithms.
;   DMS, Dec, 1992.  Coordinates were off by part of a pixel bin.
;     Also, round when not doing bi-linear interpolation.
;   DMS, Sep, 1993.  Added MAX_VALUE keyword.
;   DMS, Nov, 1994.  Added MIN_VALUE keyword.
;       SVP, Mar, 1995.  Compress is now fix()'d. y is now scaled correctly.
;       SVP, May, 1996.  Removed Whole_Map keyword. Changes in the noborder
;                        behavior of MAP_SET make this keyword obselete.
;   DMS, Nov, 1996.   Adapted for new maps, rev 2.
;   CT, July 2003: Clean up code.
;   CT, April 2004: Add MAP_STRUCTURE, MASK keywords.
;-


;-------------------------------------------------------------------------
; Given the latlon range of the image, see if we can use an area
; smaller than the plot range.
;
; Inputs: lonmin, lonmax, latmin, latmax
; Outputs: screen_x, screen_y
;
pro map_image_shrinksize, lonmin, lonmax, latmin, latmax, $
    screen_x, screen_y, $
    MAP_STRUCTURE=mapStruct

    compile_opt idl2, hidden

    n = 31                      ;Subdivisions across lat/lon range.
    lon = REBIN(DINDGEN(n)*((lonmax-lonmin)/(n-1)) + lonmin, n, n)
    lat = REBIN(DINDGEN(1,n)*((latmax-latmin)/(n-1)) + latmin, n, n)

    ; If we have our own MAP structure, then we need to do the
    ; map projection ourself.
    if (N_TAGS(mapStruct) gt 0) then begin
        ; First convert from lonlat to UV.
        u = MAP_PROJ_FORWARD(lon, lat, MAP_STRUCTURE=mapStruct)
        v = reform(u[1,*])
        u = reform(u[0,*])
        ; Filter out NaNs.
        good = where(finite(u) and finite(v))
        u = u[good]
        v = v[good]
        ; Now convert from UV to pixels.
        x = CONVERT_COORD(TEMPORARY(u), TEMPORARY(v), /DATA, /TO_DEVICE)
        y = reform(x[1,*]) ;Get device coords separately
        x = reform(x[0,*])
    endif else begin
        ; For internal !map, just use convert_coord directly.
        x = CONVERT_COORD(TEMPORARY(lon), TEMPORARY(lat), $
            /DATA, /TO_DEVICE)
        y = reform(x[1,*]) ;Get device coords separately
        x = reform(x[0,*])
        ; Filter out NaNs.
        good = where(finite(x) and finite(y))
        x = x[good]
        y = y[good]
    endelse

    ; Find the smaller pixel dimensions.
    minx = MIN(TEMPORARY(x), MAX=maxx)
    miny = MIN(TEMPORARY(y), MAX=maxy)
    screen_x = long([screen_x[0] > minx, screen_x[1] < maxx])
    screen_y = long([screen_y[0] > miny, screen_y[1] < maxy])

end


;-------------------------------------------------------------------------
; Return an array of 1's where the data are outside the range of min_value
; to max_value.  Max_value and/or min_value may be undefined.  If both are
; undefined, return a -1.
;
function map_image_missing, image_orig, max_value, min_value

    compile_opt idl2, hidden

    if (N_ELEMENTS(max_value) eq 1) then begin
        if (N_ELEMENTS(min_value) eq 1) then $
            return, (Image_orig ge max_value) or (Image_orig le min_value)
        return, Image_orig ge max_value
    endif

    if (N_ELEMENTS(min_value) eq 1) then $
        return, Image_orig le min_value

    return, -1

end


;-------------------------------------------------------------------------
function  map_image, Image_Orig, Startx, Starty, xsize, ysize, $
    LATMIN = latminIn, LATMAX = latmaxIn,  $
    LONMIN = lonminIn, LONMAX = lonmaxIn,  $
    BILINEAR = bilin, $
    COMPRESS = compressIn, $
    SCALE = scalefIn, $
    MASK=mask, $
    MAP_STRUCTURE=mapStruct, $
    MAX_VALUE = max_value, MIN_VALUE=min_value, $
    MISSING = missingIn, $
    WHOLE_MAP=obsolete_keyword

    compile_opt idl2

    ON_ERROR,2

    hasMapStructure = N_TAGS(mapStruct) gt 0

    if (~hasMapStructure && (!x.type NE 2) && (!x.type ne 3)) THEN  $
       message, "Current window must have map coordinates"

    dims = SIZE(Image_Orig, /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2) then $
        MESSAGE, "Image must be a two- dimensional array."

    s1 = dims[0]           ; # of columns
    s2 = dims[1]           ; # of rows
    if (s1 le 1) || (s2 le 1) THEN $
        message, 'Each dimension must be greater than 1."

    ; If both latmin & latmax are missing, assume image covers entire globe.
    latmin = (N_ELEMENTS(latminIn) eq 1) ? FLOAT(latminIn) : -90.0
    latmax = (N_ELEMENTS(latmaxIn) eq 1) ? FLOAT(latmaxIn) : 90.0

    ; If both lonmin & lonmax are missing, assume image covers all longitudes
    ;       with duplication.
    lonmin = (N_ELEMENTS(lonminIn) eq 1) ? FLOAT(lonminIn) : -180.0
    lonmax = (N_ELEMENTS(lonmaxIn) eq 1) ? FLOAT(lonmaxIn) : 180.0

    ; Scale from lat/lon to pixels
    sx = ((s1-1.)/(lonmax - lonmin))
    sy = ((s2-1.)/(latmax - latmin))


    ;   Does image wrap around globe?
    wrap = ((lonmin - 360./s1 + 720.) mod 360.) - ((lonmax + 720.) mod 360.)
    wrap = abs(wrap) lt 1e-4    ;Allow for roundoff

    ; Find the extent of the our limits in the map on the screen by
    ;       making a n x n array of lon/lats spaced over the extent of
    ;       the image and saving the extrema.


    ;TRUE if device has scalable pixels
    hasScalable = (!d.flags and 1)


    if hasScalable then begin     ; Fudge for postscript?
        ; PostScript scale factor
        scalef = (N_ELEMENTS(scalefIn) eq 1) ? scalefIn : 0.02
        !x.s *= scalef
        !y.s *= scalef
    endif else $
        scalef = 1

    compress = (N_ELEMENTS(compressIn) eq 1) ? FIX(compressIn) : 4

    ; Missing data value should equal the background or user-supplied value.
    missing = (N_ELEMENTS(missingIn) eq 1) ? missingIn : $
        ((!d.flags and 512) ? !d.n_colors-1 : 0)


    dxsize = !d.x_size
    dysize = !d.y_size
    screen_x = long(scalef * !x.window * dxsize) ;Map extent on screen
    screen_y = long(scalef * !y.window * dysize)

    ; See if we can use a smaller area than the plot window
    if (~wrap && abs(latmax-latmin) lt 90) then begin
        MAP_IMAGE_SHRINKSIZE, lonmin, lonmax, latmin, latmax, $
            screen_x, screen_y, $
            MAP_STRUCTURE=mapStruct
    endif

    ;       Get next larger multiple of compress for resulting image size.
    nx = ((screen_x[1] - screen_x[0]+compress) < dxsize) / compress
    ny = ((screen_y[1] - screen_y[0]+compress) < dysize) / compress

    ; Output variables.
    Startx = long(screen_x[0] / scalef)
    Starty = long(screen_y[0] / scalef)
    xsize = long(nx / scalef * compress)
    ysize = long(ny / scalef * compress)

    ; Screen to lat/lon
    ; X and Y screen coordinates
    x = REBIN(FINDGEN(nx) * compress + screen_x[0], nx, ny)
    y = REBIN(FINDGEN(1, ny) * compress + screen_y[0], nx, ny)

    ; Convert pixels to LONLAT (with !map) or UV (with map struct).
    lonlat = CONVERT_COORD(TEMPORARY(x), TEMPORARY(y), /DEVICE, /TO_DATA)

    if (hasMapStructure) then begin
        ; Convert from UV to lonlat.
        lonlat = MAP_PROJ_INVERSE(lonlat[0:1,*], $
            MAP_STRUCTURE=mapStruct)
    endif



    lat = reform(lonlat[1,*], nx, ny, /OVER)       ; Separate lat/lon
    lon = reform(lonlat[0,*], nx, ny, /OVER)
    lonlat = 0  ; free memory

    ; Not all machines handle NaN properly
    bad = where(~finite(lon) or ~finite(lat), count)
    if count gt 0 then begin        ; So fake it for points off the map.
        lon[bad] = 1.0e10
        lat[bad] = 1.0e10
    endif

    w = where(lon lt lonmin, count)        ;Handle longitude wrap-around
    while count gt 0 do begin
        lon[w] += 360.0
        w = where(lon lt lonmin, count)
    endwhile



    ; Now interpolate the screen image from the original.
    if KEYWORD_SET(bilin) then begin

        xindex = (TEMPORARY(lon) - lonmin) * sx     ;To pixels
        yindex = (TEMPORARY(lat) - latmin) * sy

        ; Verify that we indeed have pixels that wrap around.
        if wrap then begin
            ; We will use col1 below if necessary.
            col1 = where(xindex gt (s1-1), nwrap)
            if (~nwrap) then $
                wrap = 0
        endif

        ; Points off the map will be set to missing value.
        Image_Warp = INTERPOLATE(Image_Orig, xindex, yindex, MISSING = missing)

        ; If the image wraps around the globe, we must treat those pixels
        ; after the last column and before the first column specially.
        if (wrap) then begin
            threecol = [Image_Orig[s1-1,*], Image_Orig[0:1,*]]
            col1x = xindex[col1] - (s1-1)   ;Interpolate value
            ; Add in points that wrapped in xindex between s1-1 and s1.
            Image_Warp[col1] = INTERPOLATE(threecol, col1x, yindex[col1], $
                MISSING = missing)
        endif


        badb = MAP_IMAGE_MISSING(image_orig, max_value, min_value)

        if badb[0] ne -1 then begin    ;Missing data value?
            ; Interpolate location of missing data values onto new grid,
            ; then force to missing.
            mask = ~INTERPOLATE(float(badb), xindex, yindex, MISSING=1)
            if (wrap) then begin
                mask[col1] = ~INTERPOLATE(float([badb[s1-1,*], badb[0:1,*]]), $
                col1x, yindex[col1], MISSING=1)
            endif
            bad = where(~mask, nbad)
            if (nbad gt 0) then $
                Image_Warp[bad] = missing

        endif else begin      ; no badb

            ; Don't bother with MASK unless user requested it.
            if ARG_PRESENT(mask) then begin
                ; Do a fake interpolation of an array of ones to find the points
                ; off the map. Set these to missing=zero.
                mask = INTERPOLATE(REPLICATE(1b, s1, s2), xindex, yindex, $
                    MISS = 0)
                if (wrap) then begin
                    mask[col1] = INTERPOLATE(REPLICATE(1b, 3, s2), $
                        col1x, yindex[col1], MISS = 0)
                endif
            endif

        endelse      ; no badb

    endif else begin  ;  Nearest neighbor

    ;  This is the same as: xindex = (lon-lonmin) * sx + 0.5, but faster for arrays.
        xindex = (TEMPORARY(lon) - (lonmin - 0.5/sx)) * sx
        yindex = (TEMPORARY(lat) - (latmin - 0.5/sy)) * sy

        if wrap then begin
            needWrap = where(xindex ge s1 and xindex lt (2*s1), count)
            if count gt 0 then $
                xindex[TEMPORARY(needWrap)] -= s1
        endif

        ; It's okay to index using out-of-bounds values (they will be
        ; clipped), but we need to save the bad locations so we can
        ; set to missing at the end.
        mask = (xindex ge 0 and xindex lt s1 and yindex ge 0 and yindex lt s2)
        bad = where(~mask, offmap)

        Image_Warp = Image_Orig[TEMPORARY(xindex), TEMPORARY(yindex)]

        badb = MAP_IMAGE_MISSING(Image_Warp, max_value, min_value)
        if badb[0] ne -1 then begin
            really_bad = where(badb, nreallybad)
            if nreallybad gt 0 then begin
                mask and= ~badb
                Image_Warp[really_bad] = missing
            endif
        endif

        if offmap gt 0 then $
            Image_Warp[bad] = missing

    endelse  ;  Nearest neighbor


    if compress ne 1 then begin     ;Resample to screen?
       Image_Warp = REBIN(Image_Warp, nx*compress, ny*compress)
       if ARG_PRESENT(mask) then $
            mask = REBIN(mask, nx*compress, ny*compress)
    endif

    if hasScalable then begin     ;Unfudge scale factors
        !x.s /= scalef
        !y.s /= scalef
    endif

    return, Image_Warp

end
