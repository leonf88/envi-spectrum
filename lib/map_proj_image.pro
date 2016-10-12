; $Id: //depot/idl/releases/IDL_80/idldir/lib/map_proj_image.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
;+
; NAME:
;     map_proj_image
;
; PURPOSE:
;   This function returns the Image_Orig image warped to fit
;   the current map. Image_Orig must be centered at 0.  This
;   routine works in image space.
;
; SYNTAX:
;   Result = MAP_PROJ_IMAGE(Image_Orig [, Range] )
;
; INPUT:
;   Image_Orig: A two-dimensional array representing geographical
;       image data.
;
;   Range: An optional 4-element vector giving the image extents as:
;       [Lonmin, Latmin, Lonmax, Latmax].
;
; KEYWORDS:
;   BILINEAR: Set this keyword to use bilinear interpolation. The
;     default is nearest neighbor.
;
;   DIMENSIONS: Set this keyword to a two-element vector giving
;       the width and height of the desired Result.
;       The UVRANGE keyword may be used to retrieve
;       the resulting range of the UV coordinates.
;       If DIMENSIONS is not specified then the Result has the
;       same dimensions as the input image.
;
;   IMAGE_STRUCTURE: Set this keyword to a !MAP structure as returned
;       from MAP_PROJ_INIT, giving the map projection of the
;       original image. If this keyword is present, the original image
;       is assumed to be in meters. In this case, the image is first
;       warped from the IMAGE_STRUCTURE projection to degrees lat/lon,
;       and then wraped to the final MAP_STRUCTURE.
;       If this keyword is omitted, the original image is assumed to be
;       in degrees longitude/latitude (geographic coordinates).
;
;   MAP_STRUCTURE: Set this keyword to a !MAP structure as returned
;       from MAP_PROJ_INIT, giving the map projection to which to
;       warp the image. If this keyword is omitted,
;       the !MAP system variable is used.
;
;   MASK: Set this keyword to a named variable in which to return
;       a byte array of the same dimensions as the Result, containing
;       a mask of the good values. Values in the Result that were
;       set to MISSING will have a mask value of zero, while all
;       other mask values will be one.
;
;   MISSING: Set this keyword to the value to set areas outside
;       the valid map coordinates. If omitted, areas outside the map
;       are set to 0.
;
;   MAX_VALUE = values in Image_Orig greater than or equal to MAX_VALUE
;     are considered missing.  Pixels in the output image
;     that depend upon missing pixels will be set to MISSING.
;
;   MIN_VALUE = values in Image_Orig less than or equal to MIN_VALUE
;     are considered missing.
;
;   UVRANGE: Set this keyword to a named variable in which to return
;       the range of the UV coordinates as: [umin, vmin, umax, vmax].
;
;   XINDEX: The XINDEX and YINDEX keywords are used when warping multiple
;       images (or image channels) that have the same dimensions and map
;       projection. For the first call to MAP_PROJ_IMAGE, XINDEX and YINDEX
;       should be set to named variables which are either undefined or
;       contain scalar values. Upon return, XINDEX and YINDEX will contain
;       the indices that were used for warping the image. For subsequent
;       images, the XINDEX and YINDEX variables should be passed in
;       unmodified. In this case the map projection is bypassed and the
;       indices are used to warp the image.
;
;   YINDEX: The XINDEX and YINDEX keywords are used when warping multiple
;       images. See the XINDEX keyword above for details.
;
;   Note: If the XINDEX and YINDEX keywords are present and contain
;       arrays of indices, then the Range argument and the IMAGE_STRUCTURE,
;       MAP_STRUCTURE, and UVRANGE keywords are ignored. If you specified
;       the BILINEAR, DIMENSIONS, MAX_VALUE, MIN_VALUE, or MISSING keywords
;       on the first call to MAP_PROJ_IMAGE, then you should also supply
;       the same keywords with the same values on subsequent calls.
;
; OUTPUT:
;      The warped image is returned.
;
; PROCEDURE:  An image space algorithm is used, so the time required
;   is roughly proportional to the size of the final image.
;   For each pixel in the Result, the inverse coordinate transform is
;   applied to obtain lat/lon.  The lat/lon coordinates are then scaled
;   into image pixel coordinates, and these coordinates are then
;   interpolated from Image values.
;
; MODIFICATION HISTORY:
;   Written: CT, RSI, April 2004.
;   Modified: CT, RSI, Dec 2004: Added docs for XINDEX, YINDEX.
;
;-


;-------------------------------------------------------------------------
; Given a map structure and a latlon range, determine the corresponding
; range of UV coordinates.
;
function map_proj_image_uvsize, xminIn, xmaxIn, yminIn, ymaxIn, $
    IMAGE_STRUCTURE=imageStructure, $
    MAP_STRUCTURE=mapStruct

    compile_opt idl2, hidden

    hasImageStruct = N_TAGS(imageStructure) gt 0

    ; Subdivisions across lat/lon range.
    nx = 61
    ny = 31

    if (hasImageStruct) then begin

        xmin = xminIn
        xmax = xmaxIn
        ymin = yminIn
        ymax = ymaxIn
        dx = (xmax-xmin)/(nx-1)
        dy = (ymax-ymin)/(ny-1)
        xcoord = REFORM(REBIN(DINDGEN(nx)*dx + xmin, nx, ny), nx*ny)
        ycoord = REFORM(REBIN(DINDGEN(1,ny)*dy + ymin, nx, ny), nx*ny)

        ; First convert from original UV to lonlat.
        lon = MAP_PROJ_INVERSE(xcoord, ycoord, MAP_STRUCTURE=imageStructure)
        lat = REFORM(lon[1,*])
        lon = REFORM(lon[0,*])

        ; Filter out NaNs.
        good = WHERE(FINITE(lon) and FINITE(lat))
        lon = lon[good]
        lat = lat[good]

    endif else begin

        ll_box = mapStruct.ll_box
        ; map_set will set the lat/lon limits to zero if it can't
        ; determine them reliably. In this case use the entire globe.
        if (ARRAY_EQUAL(ll_box, DBLARR(4))) then $
            ll_box = [-90, -180, 90, 180]
        xmin = xminIn > ll_box[1]
        xmax = xmaxIn < ll_box[3]
        ymin = yminIn > ll_box[0]
        ymax = ymaxIn < ll_box[2]
        dx = (xmax-xmin)/(nx-1)
        dy = (ymax-ymin)/(ny-1)
        lon = DINDGEN(nx)*dx + xmin
        lon = REFORM(REBIN(lon, nx, ny), nx*ny)
        lat = DINDGEN(ny)*dy + ymin
        lat = REFORM(REBIN(TRANSPOSE(lat), nx, ny), nx*ny)

    endelse

    ; Convert from lonlat to UV.
    u = MAP_PROJ_FORWARD(lon, lat, MAP_STRUCTURE=mapStruct)
    v = REFORM(u[1,*])
    u = REFORM(u[0,*])

    ; Filter out NaNs.
    good = WHERE(FINITE(u) and FINITE(v), ngood)
    if (~ngood) then $
        return, [0d, 0, 1, 1]

    u = u[good]
    v = v[good]

    minu = MIN(u, MAX=maxu)
    minv = MIN(v, MAX=maxv)

    return, [minu, minv, maxu, maxv]

end


;-------------------------------------------------------------------------
; Return an array of 1's where the data are outside the range of min_value
; to max_value.  Max_value and/or min_value may be undefined.  If both are
; undefined, return a -1.
;
function map_proj_image_missing, image_orig, max_value, min_value

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
function map_proj_image, Image_Orig, rangeIn, $
    AUTO_DIMENSIONS=autoDim, $
    BILINEAR = bilin, $
    DIMENSIONS=dimensions, $
    IMAGE_STRUCTURE=imageStructure, $
    MAP_STRUCTURE=mapStruct, $
    MASK=mask, $
    MAX_VALUE = max_value, $
    MIN_VALUE=min_value, $
    MISSING = missingIn, $
    UVRANGE=uvrange, $
    XINDEX=xindex, $
    YINDEX=yindex


    compile_opt idl2, hidden

    ON_ERROR,2

    dims = SIZE(Image_Orig, /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2) then $
        MESSAGE, "Image must be a two- dimensional array."

    s1 = dims[0]           ; # of columns
    s2 = dims[1]           ; # of rows
    if (s1 le 1) || (s2 le 1) THEN $
        message, 'Each dimension must be greater than 1."

    ; Missing data value should equal the background or user-supplied value.
    missing = (N_ELEMENTS(missingIn) eq 1) ? missingIn : 0

    if (N_ELEMENTS(dimensions) eq 2) then begin
        nx = LONG(dimensions[0])
        ny = LONG(dimensions[1])
    endif else begin
        nx = s1
        ny = s2
    endelse

    if (nx lt 2 || ny lt 2) then $
        MESSAGE, 'DIMENSIONS must be greater than 1.'

    if (N_TAGS(mapStruct) eq 0) then $
        mapStruct = !MAP

    hasImageStruct = N_TAGS(imageStructure) gt 0

    if (N_ELEMENTS(rangeIn) eq 4) then begin
        xmin = DOUBLE(rangeIn[0])
        ymin = DOUBLE(rangeIn[1])
        xmax = DOUBLE(rangeIn[2])
        ymax = DOUBLE(rangeIn[3])
    endif else begin
        if (hasImageStruct) then $
            MESSAGE, 'Range must be specified with IMAGE_STRUCTURE keyword.'
        ; Assume image covers entire globe.
        xmin = -180d
        ymin = -90d
        xmax = 180d
        ymax = 90d
    endelse


    ; Scale from lat/lon to pixels
    sx = ((s1-1.)/(xmax - xmin))
    sy = ((s2-1.)/(ymax - ymin))


    ;   Does image wrap around globe?
    if (~hasImageStruct) then begin
        wrap = ((xmin - 360./s1 + 720.) mod 360.) - ((xmax + 720.) mod 360.)
        wrap = abs(wrap) lt 1e-4    ;Allow for roundoff
    endif else wrap = 0

    ; If user passed in cached values for XINDEX and YINDEX then use them.
    if (SIZE(xindex, /N_DIM) gt 0 && SIZE(yindex, /N_DIM) gt 0) then $
        goto, skipover

    ; Find the extent of the limits in the map on the screen by
    ; making an n x n array of lon/lats spaced over the extent of
    ; the image and saving the extrema.
    uvrange = MAP_PROJ_IMAGE_UVSIZE(xmin, xmax, ymin, ymax, $
        IMAGE_STRUCTURE=imageStructure, $
        MAP_STRUCTURE=mapStruct)

    du = uvrange[2] - uvrange[0]
    dv = uvrange[3] - uvrange[1]

    if (KEYWORD_SET(autoDim)) then begin
        dimRatio = DOUBLE(nx)/ny
        uvRatio = du/dv

        ; Shrink either nx or ny, to make the dimRatio match the uvRatio.
        if (dimRatio gt uvRatio) then begin
            nx = ROUND(ny*uvRatio)
            ; If dimension shrinks below 2, then increase the other
            ; dimension instead, but only up to 10 times (sanity check).
            if (nx lt 2) then begin
                nx = 2
                ny = ROUND(nx/uvRatio) < 10*ny
            endif
        endif else begin
            ny = ROUND(nx/uvRatio)
            ; If dimension shrinks below 2, then increase the other
            ; dimension instead, but only up to 10 times (sanity check).
            if (ny lt 2) then begin
                ny = 2
                nx = ROUND(ny*uvRatio) < 10*nx
            endif
        endelse
    endif

    ; U and V Cartesian coordinates.
    u = DINDGEN(nx)*(du/(nx-1)) + uvrange[0]
    v = DINDGEN(1, ny)*(dv/(ny-1)) + uvrange[1]
    uvIn = [REFORM(REBIN(u, nx, ny), 1, nx*ny), $
        REFORM(REBIN(v, nx, ny), 1, nx*ny)]

    ; Convert from UV to lonlat.
    lonlat = MAP_PROJ_INVERSE(uvIn, MAP_STRUCTURE=mapStruct)

    ; The GCTP projections tend to collapse invalid UV points
    ; down to "valid" lonlat. To filter out these bad points,
    ; do a forward transform of our lonlat, and compare the
    ; resulting UV values with the originals.
    ; First filter out NaN's to avoid overflow errors.
    bad = WHERE(~FINITE(lonlat), nbad)
    if (nbad gt 0) then $
        lonlat[bad] = 0  ; arbitrary value

    lon = lonlat[0,*]
    lat = lonlat[1,*]

    ; Throw away out-of-bounds latitude values.
    ibad = ABS(lat) gt 90
    bad = WHERE(ibad, nbad)
    if (nbad gt 0) then $
        lonlat[1,bad] = 0

    ll_box = mapStruct.ll_box
    ; map_set will set the lat/lon limits to zero if it can't
    ; determine them reliably. In this case use the entire globe.
    if (ARRAY_EQUAL(ll_box, DBLARR(4))) then $
        ll_box = [-90, -180, 90, 180]

    ; If the bounding box is less than the image range,
    ; then clip the lonlats.
    ibad or= (lon lt ll_box[1])
    ibad or= (lon gt ll_box[3])
    ibad or= (lat lt ll_box[0])
    ibad or= (lat gt ll_box[2])


    uvOut = MAP_PROJ_FORWARD(lonlat, MAP_STRUCTURE=mapStruct)

    ; Filter out NaN's to avoid overflow errors.
    nan = WHERE(~FINITE(uvOut), nNan)
    if (nNan gt 0) then $
        uvOut[nan] = 1d10

    ; Calculate relative error between uvIn/Out.
    diff = TEMPORARY(uvOut) - uvIn
    ; Avoid division by zero.
    zero = WHERE(ABS(uvIn) lt 1, nzero)
    if (nzero gt 0) then $
        uvIn[zero] = 1
    diff = ABS(TEMPORARY(diff)/TEMPORARY(uvIn))
    ; Somewhat arbitrary cutoff of "bad" values.
    ibad or= MAX(TEMPORARY(diff) gt 0.1d, DIM=1)

    ; Mark all bad values.
    bad = WHERE(ibad, nbad)

    if (hasImageStruct) then begin

        xcoord = MAP_PROJ_FORWARD(lonlat, MAP_STRUCTURE=imageStructure)
        if (nbad gt 0) then $
            xcoord[*, bad] = 1d10
        ycoord = REFORM(xcoord[1,*], nx, ny)
        xcoord = REFORM(xcoord[0,*], nx, ny)


    endif else begin

        if (nbad gt 0) then $
            lonlat[*, bad] = 9999

        lat = reform(lonlat[1,*], nx, ny)       ; Separate lat/lon
        lon = reform(lonlat[0,*], nx, ny)
        lonlat = 0  ; free memory


        ; Handle longitude wrap-around.
        lonMinimum = -180   ; (old code: xmin-1d-7)
        w = where(lon lt lonMinimum, count)
        while count gt 0 do begin
            lon[w] += 360.0
            w = where(lon lt xmin, count)
        endwhile

        xcoord = TEMPORARY(lon)
        ycoord = TEMPORARY(lat)

    endelse

skipover:

    eps = 1d-11

    ; Now interpolate the screen image from the original.
    if KEYWORD_SET(bilin) then begin

        ; Didn't get cached values?
        if (SIZE(xindex, /N_DIM) eq 0) then begin
            xindex = (TEMPORARY(xcoord) - xmin) * sx     ;To pixels
            yindex = (TEMPORARY(ycoord) - ymin) * sy
            ; Tweak indices to avoid roundoff errors.
            xindex[0,*] += eps
            xindex[nx-1,*] -= eps
            yindex[*,0] += eps
            yindex[*,ny-1] -= eps
        endif

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


        badb = MAP_PROJ_IMAGE_MISSING(image_orig, max_value, min_value)

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

        ; Didn't get cached values?
        if (SIZE(xindex, /N_DIM) eq 0) then begin

            ;  This is the same as: xindex = (lon-xmin) * sx + 0.5, but faster for arrays.
            xindex = (TEMPORARY(xcoord) - (xmin - 0.5/sx)) * sx
            yindex = (TEMPORARY(ycoord) - (ymin - 0.5/sy)) * sy

            ; Tweak indices to avoid roundoff errors.
            xindex[0,*] += eps
            xindex[nx-1,*] -= eps
            yindex[*,0] += eps
            yindex[*,ny-1] -= eps

            if wrap then begin
                needWrap = where(xindex ge s1 and xindex lt (2*s1), count)
                if count gt 0 then $
                    xindex[TEMPORARY(needWrap)] -= s1
            endif

            xindex = ROUND(xindex)
            yindex = ROUND(yindex)

        endif

        ; It's okay to index using out-of-bounds values (they will be
        ; clipped), but we need to save the bad locations so we can
        ; set to missing at the end.
        mask = (xindex ge 0 and xindex lt s1 and yindex ge 0 and yindex lt s2)

        Image_Warp = Image_Orig[xindex, yindex]

        badb = MAP_PROJ_IMAGE_MISSING(Image_Warp, max_value, min_value)
        if ((badb[0] ne -1) && ~ARRAY_EQUAL(badb, 1)) then begin
            mask and= ~badb
        endif

        bad = where(~mask, offmap)

        if (offmap gt 0) then $
            Image_Warp[bad] = missing

    endelse  ;  Nearest neighbor

    return, Image_Warp

end
