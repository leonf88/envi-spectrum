; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitmapprojection__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;   _IDLitMapProjection
;
; PURPOSE:
;   The _IDLitMapProjection class is a helper class for objects with
;   map projection data.
;
; MODIFICATION HISTORY:
;   Written by:   CT, May 2004
;-


;----------------------------------------------------------------------------
function _IDLitMapProjection::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->_IDLitMapProjection::_RegisterProperties
    self->_UpdateProjection

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitMapProjection::SetProperty, _EXTRA=_extra

    return, 1 ; Success
end


;----------------------------------------------------------------------------
pro _IDLitMapProjection::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

@map_proj_init_commonblock

    keep = WHERE(c_ProjNumber ge 100)
    projNames = c_ProjNames[keep]
    projNames = projNames[SORT(projNames)]

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'Projection', $
            DESCRIPTION='Map projection', $
            ENUMLIST=['No projection', projNames]

    endif

    if (registerAll || updateFromVersion lt 710) then begin

        self->RegisterProperty, 'IELLIPSOID', $
            NAME='Ellipsoid', $
            DESCRIPTION='Semimajor/minor axes that define the ellipsoid', $
            ENUMLIST=['User defined', c_EllipsoidNames[SORT(c_EllipsoidNames)]]

    endif

    ; Renamed IDATUM to IELLIPSOID
    if (~registerAll && updateFromVersion lt 710) then begin
        self->SetPropertyAttribute, 'IDATUM', /HIDE
    endif
    
    if (~registerAll) then $
        return

    self->RegisterProperty, 'SEMIMAJOR_AXIS', /FLOAT, $
        NAME='Semimajor axis', $
        DESCRIPTION='Semimajor axis for the reference ellipsoid'

    self->RegisterProperty, 'SEMIMINOR_AXIS', /FLOAT, $
        NAME='Semiminor axis', $
        DESCRIPTION='Semiminor axis for the reference ellipsoid'

    self->RegisterProperty, 'CENTER_LONGITUDE', /FLOAT, $
        NAME='Center longitude (degrees)', $
        VALID_RANGE=[-180,360], $
        DESCRIPTION='Longitude in degrees of the map projection center'

    self->RegisterProperty, 'CENTER_LATITUDE', /FLOAT, $
        NAME='Center latitude (degrees)', $
        VALID_RANGE=[-90,90], $
        DESCRIPTION='Latitude in degrees of the map projection center'

    self->RegisterProperty, 'LONGITUDE_MIN', /FLOAT, $
        NAME='Longitude minimum (deg)', $
        VALID_RANGE=[-360,360], $
        DESCRIPTION='Minimum longitude to include in projection (degrees)'

    self->RegisterProperty, 'LONGITUDE_MAX', /FLOAT, $
        NAME='Longitude maximum (deg)', $
        VALID_RANGE=[-360,360], $
        DESCRIPTION='Maximum longitude to include in projection (degrees)'

    self->RegisterProperty, 'LATITUDE_MIN', /FLOAT, $
        NAME='Latitude minimum (deg)', $
        VALID_RANGE=[-90,90], $
        DESCRIPTION='Minimum latitude to include in projection (degrees)'

    self->RegisterProperty, 'LATITUDE_MAX', /FLOAT, $
        NAME='Latitude maximum (deg)', $
        VALID_RANGE=[-90,90], $
        DESCRIPTION='Maximum latitude to include in projection (degrees)'

    self->RegisterProperty, 'FALSE_EASTING', /FLOAT, $
        NAME='False easting (meters)', $
        DESCRIPTION='False easting in meters to be added to each X coordinate'

    self->RegisterProperty, 'FALSE_NORTHING', /FLOAT, $
        NAME='False northing (meters)', $
        DESCRIPTION='False northing in meters to be added to each Y coordinate'

    self->RegisterProperty, 'UTM_ZONE', /INTEGER, $
        NAME='Zone (1-60)', $
        DESCRIPTION='Universal Transverse Mercator grid zone number', $
        VALID_RANGE=[1,60,1]

    self->RegisterProperty, 'STATEPLANE_ZONE27', $
        NAME='NAD27 Zone name (FIPS)', $
        DESCRIPTION='NAD27 State Plane Coordinate System Zone (FIPSZone)', $
        ENUMLIST=c_StatePlane_NAD27names + ' (' + $
            STRTRIM(c_StatePlane_NAD27numbers,2) + ')'

    self->RegisterProperty, 'STATEPLANE_ZONE83', $
        NAME='NAD83 Zone name (FIPS)', $
        DESCRIPTION='NAD83 State Plane Coordinate System Zone (FIPSZone)', $
        ENUMLIST=c_StatePlane_NAD83names + ' (' + $
            STRTRIM(c_StatePlane_NAD83numbers,2) + ')'

    self->RegisterProperty, 'HEMISPHERE', $
        NAME='Hemisphere', $
        ENUMLIST=['Northern', 'Southern'], $
        DESCRIPTION='Hemisphere for UTM and Polar projections'

    self->RegisterProperty, 'STANDARD_PAR1', /FLOAT, $
        NAME='Standard parallel 1 (deg)', $
        VALID_RANGE=[-90,90], $, $
        DESCRIPTION='First standard parallel (degrees latitude) of true scale'

    self->RegisterProperty, 'STANDARD_PAR2', /FLOAT, $
        NAME='Standard parallel 2 (deg)', $
        VALID_RANGE=[-90,90], $, $
        DESCRIPTION='Second standard parallel (degrees latitude) of true scale'

    self->RegisterProperty, 'MERCATOR_SCALE', /FLOAT, $
        NAME='Mercator scale', $
        DESCRIPTION='Scale factor along central meridian or line'

    self->RegisterProperty, 'HEIGHT', /FLOAT, $
        NAME='Height (meters)', $
        DESCRIPTION='Height above surface (meters) for satellite projections'

    self->RegisterProperty, 'HOM_AZIM_ANGLE', /FLOAT, $
        NAME='HOM azimuth angle (deg)', $
        VALID_RANGE=[-360,360], $
        DESCRIPTION='Hotine Oblique Mercator azimuth angle (degrees) east'

    self->RegisterProperty, 'HOM_LONGITUDE1', /FLOAT, $
        NAME='HOM longitude 1 (deg)', $
        VALID_RANGE=[-360,360], $
        DESCRIPTION='Hotine Oblique Mercator longitude of first point (degrees)'

    self->RegisterProperty, 'HOM_LATITUDE1', /FLOAT, $
        NAME='HOM latitude 1 (deg)', $
        VALID_RANGE=[-90,90], $
        DESCRIPTION='Hotine Oblique Mercator latitude of first point (degrees)'

    self->RegisterProperty, 'HOM_LONGITUDE2', /FLOAT, $
        NAME='HOM longitude 2 (deg)', $
        VALID_RANGE=[-360,360], $
        DESCRIPTION='Hotine Oblique Mercator longitude of second point (degrees)'

    self->RegisterProperty, 'HOM_LATITUDE2', /FLOAT, $
        NAME='HOM latitude 2 (deg)', $
        VALID_RANGE=[-90,90], $
        DESCRIPTION='Hotine Oblique Mercator latitude of second point (degrees)'

    self->RegisterProperty, 'SOM_LANDSAT_NUMBER', $
        NAME='SOM Landsat number', $
        ENUMLIST=['Landsat 1,2,3 (WRS-1)', 'Landsat 4,5,7 (WRS-2)'], $
        DESCRIPTION='Space Oblique Mercator Landsat number' + $
            ' (Worldwide Reference System)'

    self->RegisterProperty, 'SOM_LANDSAT_PATH', /INTEGER, $
        NAME='SOM Landsat path', $
        VALID_RANGE=[1,251], $
        DESCRIPTION='Space Oblique Mercator Landsat path number'

    self->RegisterProperty, 'SOM_INCLINATION', /FLOAT, $
        NAME='SOM inclination (deg)', $
        VALID_RANGE=[-180,180], $
        DESCRIPTION='Space Oblique Mercator orbit inclination angle (degrees)'

    self->RegisterProperty, 'SOM_LONGITUDE', /FLOAT, $
        NAME='SOM longitude (deg)', $
        VALID_RANGE=[-180,180], $
        DESCRIPTION='Space Oblique Mercator longitude of ascending node (degrees)'

    self->RegisterProperty, 'SOM_PERIOD', /FLOAT, $
        NAME='SOM period (minutes)', $
        DESCRIPTION='Space Oblique Mercator satellite period (minutes)'

    self->RegisterProperty, 'SOM_RATIO', /FLOAT, $
        NAME='SOM ratio', $
        DESCRIPTION='Space Oblique Mercator Landsat ratio at northern orbit end'

    self->RegisterProperty, 'SOM_FLAG', $
        NAME='SOM end-of-path flag', $
        ENUMLIST=['Start', 'End'], $
        DESCRIPTION='Space Oblique Mercator Landsat end-of-path flag'

    self->RegisterProperty, 'OEA_SHAPEM', /FLOAT, $
        NAME='OEA horizontal shape m', $
        DESCRIPTION='Oblated equal area horizontal (m) shape parameter'

    self->RegisterProperty, 'OEA_SHAPEN', /FLOAT, $
        NAME='OEA vertical shape n', $
        DESCRIPTION='Oblated equal area vertical (n) shape parameter'

    self->RegisterProperty, 'OEA_ANGLE', /FLOAT, $
        NAME='OEA rotation angle (deg)', $
        VALID_RANGE=[-180,180], $
        DESCRIPTION='Oblated equal area rotation angle (degrees)'

    self->RegisterProperty, 'IS_ZONES', /INTEGER, $
        NAME='IS longitudinal zones', $
        VALID_RANGE=[2,360L*3600], $  ; this limit is hardcoded in GCTP
        DESCRIPTION='Integerized Sinusoidal number of logitudinal zones'

    self->RegisterProperty, 'IS_JUSTIFY', $
        NAME='IS row justify flag', $
        ENUMLIST=['Extra column on right', 'Extra column on left', $
            'Even number of columns'], $
        DESCRIPTION='Integerized Sinusoidal flag for rows with odd number of columns'

    self._projection = 'No projection'
    self._ellipsoid = 'Clarke 1866'
    self._limit = [-90, -180, 90, 180]  ; [latmin,lonmin,latmax,lonmax]
    self._userlimit = [-999, -999, -999, -999]
    self._previewDimensions = [200,200]

end


;----------------------------------------------------------------------------
; _IDLitMapProjection::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro _IDLitMapProjection::Restore
    compile_opt idl2, hidden

    ; Register new properties.
    self->_IDLitMapProjection::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    if (self._datum ne '') then $
        self._ellipsoid = self._datum

end


;----------------------------------------------------------------------------
function _IDLitMapProjection::_GetMapStructure

    compile_opt idl2, hidden

@map_proj_init_commonblock

    if (STRCMP(self._projection, 'No projection', /FOLD_CASE) || $
        (self._projection eq '')) then $
        return, 0

    ; Use our command-line ZONE property to retrieve the correct number.
    self->_IDLitMapProjection::GetProperty, ZONE=zone

    ; Use either my own ellipsoid or a predefined one.
    if (self._ellipsoid eq 'User defined') then begin
        semiMajor = self._semiMajor
        semiMinor = self._semiMinor
    endif else begin
        ellipsoid = self._ellipsoid
    endelse

    sMap = MAP_PROJ_INIT(self._projection, $
        /GCTP, /RELAXED, $
        CENTER_LONGITUDE=self._centerLongitude, $
        CENTER_LATITUDE=self._centerLatitude, $
        ELLIPSOID=ellipsoid, $
        FALSE_EASTING=self._falseEasting, $
        FALSE_NORTHING=self._falseNorthing, $
        HEIGHT=self._height, $
        HOM_AZIM_ANGLE=self._homAzimAngle, $
        HOM_AZIM_LONGITUDE=self._centerLongitude, $
        HOM_LONGITUDE1=self._homLonlat[0], $
        HOM_LATITUDE1=self._homLonlat[1], $
        HOM_LONGITUDE2=self._homLonlat[2], $
        HOM_LATITUDE2=self._homLonlat[3], $
        IS_ZONES=self._isZones, $
        IS_JUSTIFY=self._isJustify, $
        LIMIT=self._limit, $
        MERCATOR_SCALE=self._mercatorScale, $
        OEA_SHAPEM=self._oeaShapem, $
        OEA_SHAPEN=self._oeaShapen, $
        OEA_ANGLE=self._oeaAngle, $
        SEMIMAJOR_AXIS=semiMajor, $
        SEMIMINOR_AXIS=semiMinor, $
        SPHERE_RADIUS=semiMajor, $
        SOM_LANDSAT_NUMBER=self._somLandsatNumber, $
        SOM_LANDSAT_PATH=self._somLandsatPath + 1, $  ; zero->one-based
        SOM_INCLINATION=self._somInclination, $
        SOM_LONGITUDE=self._somLongitude, $
        SOM_PERIOD=self._somPeriod, $
        SOM_RATIO=self._somRatio, $
        SOM_FLAG=self._somFlag, $
        STANDARD_PARALLEL=self._standardPar1, $
        STANDARD_PAR1=self._standardPar1, $
        STANDARD_PAR2=self._standardPar2, $
        TRUE_SCALE_LATITUDE=self._standardPar1, $
        ZONE=zone)

    return, sMap

end


;----------------------------------------------------------------------------
; Changing the UTM zone requires us to change the center longitude
; and the longitude limits.
;
pro _IDLitMapProjection::_UpdateUTMLongitude

    compile_opt idl2, hidden

    self._centerLongitude = 6*(self._utmZone + 1) - 183
    if (self._centerLongitude lt 0) then begin
        lon0 = (self._centerLongitude - 45) > (-180)
        lon1 = (lon0 + 90) < 180
    endif else begin
        lon1 = (self._centerLongitude + 45) <  180
        lon0 = lon1 - 90
    endelse

    ; If user has never set the limits, then just reset.
    if (ARRAY_EQUAL(self._userlimit, -999)) then begin
      self._limit[1] = lon0
      self._limit[3] = lon1
    endif else begin
      ; Honor the user's limits, as long as they are within range.
      if (self._limit[1] lt lon0 || self._limit[1] ge lon1) then $
        self._limit[1] = lon0
      if (self._limit[3] gt lon1 || self._limit[3] le lon0) then $
        self._limit[3] = lon1
    endelse
    
end


;----------------------------------------------------------------------------
; Update State Plane projection parameters.
;
pro _IDLitMapProjection::_UpdateStatePlane

    compile_opt idl2, hidden

@map_proj_init_commonblock

    if (self._projection ne 'State Plane') then $
        return

    ; Are we using NAD27 or NAD83?
    isNAD27 = self._ellipsoid eq 'Clarke 1866'
    zones = isNAD27 ? $
        c_StatePlane_NAD27numbers : c_StatePlane_NAD83numbers
    zone = isNAD27 ? self._statePlaneZone27 : self._statePlaneZone83

    proj = isNAD27 ? c_StatePlane_NAD27proj[zone] : $
        c_StatePlane_NAD83proj[zone]
    params = isNAD27 ? c_StatePlane_NAD27params[*, zone] : $
        c_StatePlane_NAD83params[*, zone]

    self._centerLongitude = params[0]
    self._centerLatitude = params[1]

    case (proj) of
    1: self._mercatorScale = params[4]
    2: begin
        self._standardPar1 = params[2]
        self._standardPar2 = params[3]
       end
    4: begin
        self._homAzimAngle[2] = params[2]
        self._mercatorScale = params[4]
       end
    else:
    endcase

    self._falseEasting = params[5]
    self._falseNorthing = params[6]

end


;----------------------------------------------------------------------------
; If ellipsoid changes, update the semimajor & semiminor values.
;
pro _IDLitMapProjection::_UpdateEllipsoid

    compile_opt idl2, hidden

@map_proj_init_commonblock

    userDefined = self._ellipsoid eq 'User defined'
    self->SetPropertyAttribute, ['SEMIMAJOR_AXIS', 'SEMIMINOR_AXIS'], $
        SENSITIVE=userDefined

    if (userDefined) then $
        return

    index = (WHERE(c_EllipsoidNames eq self._ellipsoid))[0]
    if (index lt 0) then $
        return

    self._semiMajor = c_EllipsoidMajor[index]
    self._semiMinor = c_EllipsoidMinor[index]

    ; State Plane for Michigan, NAD1927 zones 2111, 2112, 2113, uses
    ; a modified Clarke 1866 ellipsoid with an added elevation of 800 feet.
    if (self._projection eq 'State Plane' && self._ellipsoid eq 'Clarke 1866' && $
        c_StatePlane_NAD27numbers[self._statePlaneZone27]/10 eq 211) then begin
        self._semiMajor *= 1.0000382d
        self._semiMinor *= 1.0000382d
    endif

end


;----------------------------------------------------------------------------
; Update the new lat lon limit, taking into account the user's limits.
;
pro _IDLitMapProjection::_UpdateLimit

    compile_opt idl2, hidden

    newlimit = [-90, -180, 90, 180] ; default is entire globe
    clat = self._centerLatitude
    clon = self._centerLongitude

    switch (self._projection) of
    'Alaska Conformal': begin
        newlimit = [50, -180, 80, -120]
        break
        end

    'Albers Equal Area':  ; fall thru
    'Equidistant Conic A':  ; fall thru
    'Equidistant Conic B':  ; fall thru
    'Lambert Conformal Conic': begin
        north = self._standardPar1 ge 0 || self._standardPar2 ge 0
        south = self._standardPar1 lt 0 || self._standardPar2 lt 0
        newlimit = [south ? -90 : 0, -180, north ? 90 : 0, 180]
        break
        end

    'Mercator':  ; fall thru
    'Miller Cylindrical': begin
        newlimit = [-75, -180, 75, 180]
        break
        end

    'Polar Stereographic': begin
        newlimit = self._hemisphere ? [-90, -180, 0, 180] : [0, -180, 90, 180]
        break
        end

    'State Plane': begin
        newlimit = [clat-10, clon-10, clat+10, clon+10]
        break
        end

    'UTM': begin
        newlimit = [-90, self._limit[1], 90, self._limit[3]]
        break
        end

    'Gnomonic': begin   ; Gnomonic has a +/-60degree square
        if (clat eq 0) then $
            newlimit = [-60, -180 > (clon-60), 60, (clon+60)<180]
        break
        end

    ; For azimuthal projections, restrict limit to half of globe.
    'Azimuthal Equidistant':  ; fall thru
    'Lambert Azimuthal':  ; fall thru
    'Orthographic':  ; fall thru
    'Polyconic':  ; fall thru
    'Stereographic': begin
        case (clat) of
        0:  newlimit = [-90, -180 > (clon-90), 90, (clon+90)<180]
        90: newlimit = [0, -180, 90, 180]
        -90: newlimit = [-90, -180, 0, 180]
        else:
        endcase
        break
      end

    else:  ; default limit
    endswitch

    self._limit = newlimit

    ; If user has manually set the lonlat limits, then try to
    ; preserve them. We have to restrict the user's limits to the
    ; valid map limits. Sorry.
    if (self._userlimit[0] gt -999) then $
        self._limit[0] = self._limit[0] > self._userlimit[0]
    if (self._userlimit[1] gt -999) then $
        self._limit[1] = self._userlimit[1]
    if (self._userlimit[2] gt -999) then $
        self._limit[2] = self._limit[2] < self._userlimit[2]
    if (self._userlimit[3] gt -999) then $
        self._limit[3] = self._userlimit[3]

end


;----------------------------------------------------------------------------
pro _IDLitMapProjection::_UpdateProjection

    compile_opt idl2, hidden

@map_proj_init_commonblock

    allowLimit = 1b
    allowFalse = 1b
    self._centerLongitude = 0
    self._centerLatitude = 0
    self._falseEasting = 0
    self._falseNorthing = 0
    ; Defaults for standard parallels, chosen for the United States.
    ; See Snyder, p. 99.
    self._standardPar1 = 29.5d
    self._standardPar2 = 45.5d
    self._mercatorScale = 0.9996d
    self._homLonlat = [0, 30, 0, 60]
    self._ellipsoid = 'WGS 84'

    switch (self._projection) of

    'No projection': begin
        allowLimit = 0b
        allowFalse = 0b
        break
        end

    'Geographic': begin
        allowLimit = 1b
        allowFalse = 0b
        break
        end

    'UTM': begin
        allowFalse = 0b
        self._falseEasting = 500000
        if (self._hemisphere) then $
            self._falseNorthing = 1d7
        self->_UpdateUTMLongitude
        allowed = ['CENTER_LATITUDE', 'UTM_ZONE', 'HEMISPHERE']
        ; Don't allow user-defined ellipsoid.
        self->SetPropertyAttribute, 'IELLIPSOID', ENUMLIST=c_EllipsoidNames
        break
        end

    'State Plane': begin
        allowFalse = 0b
        nad27 = 'Clarke 1866'
        nad83 = 'GRS 1980'
        ; Default to more recent NAD83.
        self._ellipsoid = nad83
        ; Set center lon/lat.
        self->_UpdateStatePlane
        ; Restrict the allowed ellipsoids.
        self->SetPropertyAttribute, 'IELLIPSOID', ENUMLIST=[nad27, nad83]
        allowed = ['STATEPLANE_ZONE83']
        break
        end

    'Equidistant Conic B': ; fall thru
    'Lambert Conformal Conic': ; fall thru
    'Albers Equal Area': begin
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'STANDARD_PAR1', 'STANDARD_PAR2']
        break
        end

    'Mercator': begin
        self._standardPar1 = 0
        allowed = ['CENTER_LONGITUDE', 'STANDARD_PAR1']
        break
        end

    'Polar Stereographic': begin
        ; Center lat and limit depends upon hemisphere.
        self._centerLatitude = self._hemisphere ? -90 : 90
        self._standardPar1 = self._centerLatitude
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', 'HEMISPHERE', 'STANDARD_PAR1']
        break
        end

    'Polyconic': begin
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE']
        break
        end

    'Equidistant Conic A': begin
        self._standardPar1 = 40d
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'STANDARD_PAR1']
        break
        end

    'Transverse Mercator': begin
        ; Already set Mercator scale = 0.9996 above.
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'MERCATOR_SCALE']
        break
        end

    'Lambert Azimuthal': begin
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE']
        break
        end

    'Orthographic': ; fall thru
    'Azimuthal Equidistant': ; fall thru
    'Stereographic': begin
        self._ellipsoid = 'Sphere'
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE']
        break
        end

    'Gnomonic': begin
        self._ellipsoid = 'Sphere'
        ; Useful limit is 60 degrees from center.
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE']
        break
        end

    'Near Side Perspective': begin
        self._ellipsoid = 'Sphere'
        self._height = 35800000  ; Geosynchronous satellite height
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'HEIGHT']
        break
        end

    'Miller Cylindrical': ; fall thru
    'Wagner VII': ; fall thru
    'Wagner IV': ; fall thru
    'Hammer': ; fall thru
    'Mollweide': ; fall thru
    'Robinson': ; fall thru
    'Sinusoidal': begin
        self._ellipsoid = 'Sphere'
        allowed = ['CENTER_LONGITUDE']
        break
        end

    'Equirectangular': begin
        self._ellipsoid = 'Sphere'
        self._standardPar1 = 0
        allowed = ['CENTER_LONGITUDE', 'STANDARD_PAR1']
        break
        end

    'Van der Grinten': begin
        self._ellipsoid = 'Sphere'
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE']
        break
        end

    'Hotine Oblique Mercator A': begin
        ; Center latitude cannot be 0 or +/-90
        self._centerLatitude = 45
        allowed = ['CENTER_LATITUDE', $
            'MERCATOR_SCALE', $
            'HOM_LONGITUDE1', 'HOM_LATITUDE1', $
            'HOM_LONGITUDE2', 'HOM_LATITUDE2']
        break
        end

    'Hotine Oblique Mercator B': begin
        ; Center latitude cannot be 0 or +/-90
        self._centerLatitude = 45
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'MERCATOR_SCALE', 'HOM_AZIM_ANGLE']
        break
        end

    'Space Oblique Mercator A': begin
        ; The following are the values for the Landsat 1,2,3 satellites.
        self._somInclination = 99.092d  ; degrees
        self._somPeriod = 103.267d  ; minutes
        self._somRatio = 0.5201613d
        allowed = ['SOM_INCLINATION', 'SOM_LONGITUDE', $
            'SOM_PERIOD', 'SOM_RATIO', 'SOM_FLAG']
        break
        end

    'Space Oblique Mercator B': begin
        allowed = ['SOM_LANDSAT_NUMBER', 'SOM_LANDSAT_PATH']
        break
        end

    'Alaska Conformal': begin
        self._centerLongitude = -152
        self._centerLatitude = 64
        break
        end

    'Interrupted Mollweide': ; fall thru
    'Interrupted Goode': begin
        self._ellipsoid = 'Sphere'
        allowFalse = 0b
        break
        end

    'Oblated Equal Area': begin
        self._ellipsoid = 'Sphere'
        ; OEA with m=n=2 is equivalent to the Lambert Azimuthal projection.
        self._oeaShapem = 2
        self._oeaShapen = 2
        allowed = ['CENTER_LONGITUDE', 'CENTER_LATITUDE', $
            'OEA_SHAPEM', 'OEA_SHAPEN', 'OEA_ANGLE']
        break
        end

    'Integerized Sinusoidal': begin
        self._ellipsoid = 'Sphere'
        self._isZones = 8
        allowed = ['CENTER_LONGITUDE', $
            'IS_ZONES', 'IS_JUSTIFY']
        break
        end

    'Cylindrical Equal Area': begin
        self._standardPar1 = 0d  ; Lambert cylindrical equal-area projection
        allowed = ['CENTER_LONGITUDE', 'STANDARD_PAR1']
        break
        end

    else: begin
        self->ErrorMessage, SEVERITY=1, $
            IDLitLangCatQuery('Warning:MapProjection:UnknownProjection') + $
            mapProjection, $
            TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        end

    endswitch

    self->SetPropertyAttribute, 'IELLIPSOID', $
        SENSITIVE=(self._projection ne 'No projection')

    ; If not state plane, put our ellipsoids back.
    if (self._projection ne 'State Plane' && $
        self._projection ne 'UTM') then begin
        ellipsoids = 'User defined'
        ellipsoids = [ellipsoids, (self._ellipsoid eq 'Sphere') ? $
          'Sphere' : c_EllipsoidNames[SORT(c_EllipsoidNames)]]
        self->SetPropertyAttribute, 'IELLIPSOID', ENUMLIST=ellipsoids
    endif

    self->SetPropertyAttribute, ['FALSE_EASTING', 'FALSE_NORTHING'], $
        SENSITIVE=allowFalse
    self->SetPropertyAttribute, ['LONGITUDE_MIN', 'LONGITUDE_MAX', $
        'LATITUDE_MIN', 'LATITUDE_MAX'], SENSITIVE=allowLimit

    ; These may be turned back on below.
    self->SetPropertyAttribute, ['CENTER_LONGITUDE', 'CENTER_LATITUDE'], $
        SENSITIVE=0

    self->_UpdateEllipsoid

    self->_UpdateLimit

    ; Hide all projection-specific properties. Some may be
    ; unhidden below.
    props = self->QueryProperty()
    istart = (WHERE(props eq 'FALSE_NORTHING'))[0] + 1
    self->SetPropertyAttribute, props[istart:*], /HIDE

    if (N_ELEMENTS(allowed) gt 0) then $
        self->SetPropertyAttribute, allowed, HIDE=0, /SENSITIVE

end


;-------------------------------------------------------------------------
function _IDLitMapProjection::GetPreview

    compile_opt idl2, hidden

    sMap = self->_GetMapStructure()

    ; Cache our current exceptions, so we can swallow new ones.
    checkMath = CHECK_MATH(/NOCLEAR)

    if (N_TAGS(sMap) eq 0) then $
        sMap = MAP_PROJ_INIT(117)

    ; If lat range is -90,+90 map_grid will map entire globe,
    ; so fool it into not doing this.
    sMap.ll_box[0] >= -89.99d
    sMap.ll_box[2] <= 89.99d

    ; limit is [latmin,lonmin,latmax,lonmax]
    nx = 18
    dx = (self._limit[3] - self._limit[1])/(nx - 1)
    ny = 9
    dy = (self._limit[2] - self._limit[0])/(ny - 1)
    lon = DINDGEN(nx)*dx + self._limit[1]
    lat = DINDGEN(1, ny)*dy + self._limit[0]
    conn = LONARR(2*nx*ny + nx + ny)
    index = 0
    for i=0,nx-1 do begin
        conn[index] = ny
        conn[index+1] = nx*LINDGEN(ny) + i
        index += ny + 1
    endfor
    for j=0,ny-1 do begin
        conn[index] = nx
        conn[index+1] = LINDGEN(nx) + j*nx
        index += nx + 1
    endfor
    vert = MAP_PROJ_FORWARD(REBIN(lon, nx, ny), REBIN(lat, nx, ny), $
        MAP=sMap, CONNECTIVITY=conn, POLYLINES=polylines)

    if (N_ELEMENTS(vert) lt 4) then $
        return, REPLICATE(255b, self._previewDimensions)

    minn = MIN(vert, DIMENSION=2, MAX=maxx, /NAN)

    xrange = [minn[0], maxx[0]] ;sMap.uv_box[[0,2]]
    yrange = [minn[1], maxx[1]] ;sMap.uv_box[[1,3]]

    if (~FINITE(xrange[0]) || ~FINITE(xrange[1])) then $
        xrange = [-1, 1]
    if (~FINITE(yrange[0]) || ~FINITE(yrange[1])) then $
        yrange = [-1, 1]

    ; Make the map isotropic.
    dx = xrange[1] - xrange[0]
    dy = yrange[1] - yrange[0]
    if (dx && dy) then begin
        if (dx lt dy) then begin
            dx *= (dy/dx)
            xrange = (xrange[0] + xrange[1])/2 + dx/2*[-1,1]
        endif else begin
            dy *= (dx/dy)
            yrange = (yrange[0] + yrange[1])/2 + dy/2*[-1,1]
        endelse
    endif

    dev = !D.NAME
    SET_PLOT, 'Z'
    DEVICE, SET_RESOLUTION=self._previewDimensions
    PLOT, [0, 1], /NODATA, $
        XRANGE=xrange, YRANGE=yrange, $
        XSTYLE=5, YSTYLE=5, $
        XMARGIN=[0,0], YMARGIN=[0,0]
    MAP_CONTINENTS, MAP=sMap
    MAP_GRID, MAP=sMap, GLINESTYLE=0
    image = 255b - TVRD()

    SET_PLOT, dev

    ; Quietly clear exceptions.
    if (~checkMath) then $
        void = CHECK_MATH()

    return, image
end


;----------------------------------------------------------------------------
pro _IDLitMapProjection::GetProperty, $
    CENTER_LONGITUDE=centerLongitude, $
    CENTER_LATITUDE=centerLatitude, $
    ELLIPSOID=strEllipsoid, $  ; command-line support
    IDATUM=idatum, $   ; obsolete, keep for BC
    IELLIPSOID=iellipsoid, $
    FALSE_EASTING=falseEasting, $
    FALSE_NORTHING=falseNorthing, $
    HEIGHT=height, $
    HEMISPHERE=hemisphere, $
    HOM_AZIM_ANGLE=homAzimAngle, $
    HOM_AZIM_LONGITUDE=homAzimLongitude, $  ; command-line support
    HOM_LONGITUDE1=homLongitude1, $
    HOM_LATITUDE1=homLatitude1, $
    HOM_LONGITUDE2=homLongitude2, $
    HOM_LATITUDE2=homLatitude2, $
    IS_JUSTIFY=isJustify, $
    IS_ZONES=isZones, $
    LIMIT=limit, $  ; command-line support
    LONGITUDE_MIN=longitudeMin, $
    LONGITUDE_MAX=longitudeMax, $
    LATITUDE_MIN=latitudeMin, $
    LATITUDE_MAX=latitudeMax, $
    MAP_PROJECTION=mapProjection, $  ; command-line support
    MAP_STRUCTURE=sMap, $
    MERCATOR_SCALE=mercatorScale, $
    OEA_ANGLE=oeaAngle, $
    OEA_SHAPEM=oeaShapem, $
    OEA_SHAPEN=oeaShapen, $
    PROJECTION=projection, $
    SEMIMAJOR_AXIS=semiMajor, $
    SEMIMINOR_AXIS=semiMinor, $
    SOM_LANDSAT_NUMBER=somLandsatNumber, $
    SOM_LANDSAT_PATH=somLandsatPath, $
    SOM_INCLINATION=somInclination, $
    SOM_LONGITUDE=somLongitude, $
    SOM_PERIOD=somPeriod, $
    SOM_RATIO=somRatio, $
    SOM_FLAG=somFlag, $
    SPHERE_RADIUS=sphereRadius, $  ; command-line support
    STANDARD_PARALLEL=standardParallel, $  ; command-line support
    STANDARD_PAR1=standardPar1, $
    STANDARD_PAR2=standardPar2, $
    STATEPLANE_ZONE27=statePlaneZone27, $
    STATEPLANE_ZONE83=statePlaneZone83, $
    TRUE_SCALE_LATITUDE=trueScaleLatitude, $  ; command-line support
    UTM_ZONE=utmZone, $
    ZONE=gctpzone, $  ; command-line support
    PREVIEW_DIMENSIONS=previewDimensions, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

@map_proj_init_commonblock

    if (ARG_PRESENT(centerLongitude)) then $
        centerLongitude = self._centerLongitude

    if (ARG_PRESENT(centerLatitude)) then $
        centerLatitude = self._centerLatitude

    ; command-line support
    if (ARG_PRESENT(strEllipsoid)) then $
        strEllipsoid = self._ellipsoid

    if (ARG_PRESENT(idatum) || ARG_PRESENT(iellipsoid)) then begin
        ; Convert from our string back to an index.
        self->GetPropertyAttribute, 'IELLIPSOID', ENUMLIST=ellipsoids
        iellipsoid = (WHERE(STRCMP(ellipsoids, self._ellipsoid, /FOLD_CASE)))[0] > 0
        idatum = iellipsoid
    endif

    if (ARG_PRESENT(falseEasting)) then $
        falseEasting = self._falseEasting

    if (ARG_PRESENT(falseNorthing)) then $
        falseNorthing = self._falseNorthing

    if (ARG_PRESENT(height)) then $
        height = self._height

    if (ARG_PRESENT(hemisphere)) then $
        hemisphere = self._hemisphere

    if (ARG_PRESENT(homAzimAngle)) then $
        homAzimAngle = self._homAzimAngle

    ; command-line support
    if (ARG_PRESENT(homAzimLongitude)) then $
        homAzimLongitude = self._centerLongitude

    if (ARG_PRESENT(homLongitude1)) then $
        homLongitude1 = self._homLonlat[0]

    if (ARG_PRESENT(homLatitude1)) then $
        homLatitude1 = self._homLonlat[1]

    if (ARG_PRESENT(homLongitude2)) then $
        homLongitude2 = self._homLonlat[2]

    if (ARG_PRESENT(homLatitude2)) then $
        homLatitude2 = self._homLonlat[3]

    if (ARG_PRESENT(isJustify)) then $
        isJustify = self._isJustify

    if (ARG_PRESENT(isZones)) then $
        isZones = self._isZones

    ; command-line support
    if (ARG_PRESENT(limit)) then $
        limit = self._limit

    if (ARG_PRESENT(longitudeMin)) then $
        longitudeMin = self._limit[1]

    if (ARG_PRESENT(longitudeMax)) then $
        longitudeMax = self._limit[3]

    if (ARG_PRESENT(latitudeMin)) then $
        latitudeMin = self._limit[0]

    if (ARG_PRESENT(latitudeMax)) then $
        latitudeMax = self._limit[2]

    ; command-line support
    if (ARG_PRESENT(mapProjection)) then $
        mapProjection = self._projection

    if (ARG_PRESENT(mercatorScale)) then $
        mercatorScale = self._mercatorScale

    if (ARG_PRESENT(oeaAngle)) then $
        oeaAngle = self._oeaAngle

    if (ARG_PRESENT(oeaShapem)) then $
        oeaShapem = self._oeaShapem

    if (ARG_PRESENT(oeaShapen)) then $
        oeaShapen = self._oeaShapen

    if (ARG_PRESENT(projection)) then begin
        ; Convert from our string back to an index.
        self->GetPropertyAttribute, 'PROJECTION', ENUMLIST=projNames
        projection = (WHERE(STRCMP(projNames, $
            self._projection, /FOLD_CASE)))[0] > 0
    endif

    if (ARG_PRESENT(semiMajor)) then $
        semiMajor = self._semiMajor

    if (ARG_PRESENT(semiMinor)) then $
        semiMinor = self._semiMinor

    if (ARG_PRESENT(somLandsatNumber)) then $
        somLandsatNumber = self._somLandsatNumber

    ; Make path zero-based to avoid save/restore issues in future.
    if (ARG_PRESENT(somLandsatPath)) then $
        somLandsatPath = self._somLandsatPath + 1

    if (ARG_PRESENT(somInclination)) then $
        somInclination = self._somInclination

    if (ARG_PRESENT(somLongitude)) then $
        somLongitude = self._somLongitude

    if (ARG_PRESENT(somPeriod)) then $
        somPeriod = self._somPeriod

    if (ARG_PRESENT(somRatio)) then $
        somRatio = self._somRatio

    if (ARG_PRESENT(somFlag)) then $
        somFlag = self._somFlag

    ; command-line support
    if (ARG_PRESENT(sphereRadius)) then $
        sphereRadius = self._semiMajor

    ; command-line support
    if (ARG_PRESENT(standardParallel)) then $
        standardParallel = self._standardPar1

    if (ARG_PRESENT(standardPar1)) then $
        standardPar1 = self._standardPar1

    if (ARG_PRESENT(standardPar2)) then $
        standardPar2 = self._standardPar2

    if (ARG_PRESENT(statePlaneZone27)) then $
        statePlaneZone27 = self._statePlaneZone27

    if (ARG_PRESENT(statePlaneZone83)) then $
        statePlaneZone83 = self._statePlaneZone83

    ; command-line support
    if (ARG_PRESENT(trueScaleLatitude)) then $
        trueScaleLatitude = self._standardPar1

    ; Stored from 0-59 so self._utmZone=0 becomes UTM_ZONE=1.
    if (ARG_PRESENT(utmZone)) then $
        utmZone = self._utmZone + 1

    ; command-line support
    if (ARG_PRESENT(gctpzone)) then begin
        case self._projection of

        'UTM': begin
            ; Zones -60 to -1 are Southern hemisphere, +1 to 60 are Northern.
            gctpzone = self._hemisphere ? $
                (-1 - self._utmZone) : (1 + self._utmZone)
            end

        'State Plane': begin
            if (self._ellipsoid eq 'Clarke 1866') then begin
                gctpzone = c_StatePlane_NAD27numbers[self._statePlaneZone27]
            endif else begin
                gctpzone = c_StatePlane_NAD83numbers[self._statePlaneZone83]
            endelse
            end

        else:

        endcase
    endif

    if (ARG_PRESENT(sMap)) then $
        sMap = self->_GetMapStructure()

    if (ARG_PRESENT(previewDimensions)) then $
        previewDimensions = self._previewDimensions

end


;----------------------------------------------------------------------------
pro _IDLitMapProjection::SetProperty, $
    CENTER_LONGITUDE=centerLongitude, $
    CENTER_LATITUDE=centerLatitude, $
    DATUM=strDatum, $  ; command-line support, obsolete, keep for BC
    IDATUM=idatum, $  ; obsolete, keep for BC
    ELLIPSOID=strEllipsoid, $
    IELLIPSOID=iellipsoid, $
    FALSE_EASTING=falseEasting, $
    FALSE_NORTHING=falseNorthing, $
    HEIGHT=height, $
    HEMISPHERE=hemisphere, $
    HOM_AZIM_ANGLE=homAzimAngle, $
    HOM_AZIM_LONGITUDE=homAzimLongitude, $  ; command-line support
    HOM_LONGITUDE1=homLongitude1, $
    HOM_LATITUDE1=homLatitude1, $
    HOM_LONGITUDE2=homLongitude2, $
    HOM_LATITUDE2=homLatitude2, $
    LIMIT=limit, $  ; command-line support
    LONGITUDE_MIN=longitudeMin, $
    LONGITUDE_MAX=longitudeMax, $
    IS_JUSTIFY=isJustify, $
    IS_ZONES=isZones, $
    LATITUDE_MIN=latitudeMin, $
    LATITUDE_MAX=latitudeMax, $
    MAP_PROJECTION=mapProjection, $  ; command-line support
    MERCATOR_SCALE=mercatorScale, $
    OEA_ANGLE=oeaAngle, $
    OEA_SHAPEM=oeaShapem, $
    OEA_SHAPEN=oeaShapen, $
    PROJECTION=projectionIn, $
    SEMIMAJOR_AXIS=semiMajor, $
    SEMIMINOR_AXIS=semiMinor, $
    SOM_LANDSAT_NUMBER=somLandsatNumber, $
    SOM_LANDSAT_PATH=somLandsatPath, $
    SOM_INCLINATION=somInclination, $
    SOM_LONGITUDE=somLongitude, $
    SOM_PERIOD=somPeriod, $
    SOM_RATIO=somRatio, $
    SOM_FLAG=somFlag, $
    SPHERE_RADIUS=sphereRadius, $  ; command-line support
    STANDARD_PARALLEL=standardParallel, $  ; command-line support
    STANDARD_PAR1=standardPar1, $
    STANDARD_PAR2=standardPar2, $
    STATEPLANE_ZONE27=statePlaneZone27, $
    STATEPLANE_ZONE83=statePlaneZone83, $
    TRUE_SCALE_LATITUDE=trueScaleLatitude, $  ; command-line support
    UTM_ZONE=utmZone, $
    ZONE=gctpzone, $  ; command-line support
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

@map_proj_init_commonblock

    updateProjection = 0b
    updateLimit = 0b

    ; Be nice and allow the PROJECTION keyword to be a string,
    ; giving the projection name, as well as an integer.
    if (N_ELEMENTS(projectionIn) gt 0) then begin
        if (SIZE(projectionIn,/TYPE) eq 7) then begin
            mapProjection = projectionIn
        endif else begin
            projection = projectionIn
        endelse
    endif

    ; command-line support
    if (N_ELEMENTS(mapProjection) eq 1) then begin
        ; MAP_PROJECTION keyword should only come in from the command line,
        ; and should be a string.
        ; Convert from enumlist index to a string.
        self->GetPropertyAttribute, 'PROJECTION', ENUMLIST=projNames
        ; Look for a match of the starting n characters regardless of
        ; extra spaces or case, where n is the length of the string.
        mapProj = STRCOMPRESS(mapProjection, /REMOVE)
        match = (WHERE(STRCMP(STRCOMPRESS(projNames, /REMOVE), $
            mapProj, STRLEN(mapProj), /FOLD_CASE)))[0]
        if (match ge 0) then begin
            self._projection = projNames[match]
            ; Call this immediately to allow other property attributes
            ; (such as available ellipsoids) to be changed.
            self->_UpdateProjection
        endif else begin
            self->ErrorMessage, SEVERITY=1, $
                IDLitLangCatQuery('Warning:MapProjection:UnknownProjection') + $
                mapProjection, $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endelse
    endif

    if (N_ELEMENTS(projection) eq 1) then begin
        ; Convert from enumlist index to a string.
        self->GetPropertyAttribute, 'PROJECTION', ENUMLIST=projNames
        self._projection = projNames[projection < (N_ELEMENTS(projNames)-1)]
        updateProjection = 1b
    endif

    ; command-line support, obsolete, keep for BC
    if (N_ELEMENTS(strDatum) eq 1) then $
        strEllipsoid = strDatum
        
    ; command-line support
    if (N_ELEMENTS(strEllipsoid) eq 1) then begin
        ; ELLIPSOID keyword should only come in from the command line,
        ; and should be a string.
        ; Convert from enumlist index to a string.
        self->GetPropertyAttribute, 'IELLIPSOID', ENUMLIST=ellipsoids
        ; Look for a match of the starting n characters regardless of
        ; extra spaces or case, where n is the length of the string.
        sEllipsoid = STRCOMPRESS(strEllipsoid, /REMOVE)
        match = (WHERE(STRCMP(STRCOMPRESS(ellipsoids, /REMOVE), $
            sEllipsoid, STRLEN(sEllipsoid), /FOLD_CASE)))[0]

        ; Set property using the index.
        if (match ge 0) then begin
            self->_IDLitMapProjection::SetProperty, IELLIPSOID=match
        endif else begin
            self->ErrorMessage, SEVERITY=1, $
                'Ellipsoid "' + strEllipsoid + '" can not be used with ' + self._projection, $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endelse
    endif

    ; Obsolete, keep for BC
    if (N_ELEMENTS(idatum) eq 1) then $
        iellipsoid = idatum
        
    if (N_ELEMENTS(iellipsoid) eq 1) then begin
        ; Convert from an index into our string.
        self->GetPropertyAttribute, 'IELLIPSOID', ENUMLIST=ellipsoids
        self._ellipsoid = ellipsoids[iellipsoid < (N_ELEMENTS(ellipsoids)-1)]
        if (self._projection eq 'State Plane') then begin
            if (self._ellipsoid eq 'Clarke 1866') then begin
                self->SetPropertyAttribute, 'STATEPLANE_ZONE27', HIDE=0
                self->SetPropertyAttribute, 'STATEPLANE_ZONE83', /HIDE
            endif else begin
                self->SetPropertyAttribute, 'STATEPLANE_ZONE27', /HIDE
                self->SetPropertyAttribute, 'STATEPLANE_ZONE83', HIDE=0
            endelse
            self->_UpdateStatePlane
        endif
        self->_UpdateEllipsoid
    endif

    ; command-line support
    if (N_ELEMENTS(homAzimLongitude) eq 1) then $
        centerLongitude = homAzimLongitude  ; gets set below

    if (N_ELEMENTS(centerLongitude) eq 1) then begin
        self._centerLongitude = centerLongitude
        if (self._projection eq 'UTM') then begin
          ; Convert from center longitude back to UTM zone.
          l = centerLongitude mod 360
          if (l lt -180) then l += 360
          if (l gt 180) then l -= 360
          utmZone = FIX((l + 180d)/6) + 1
        endif else begin
          updateLimit = 1b
        endelse
    endif

    if (N_ELEMENTS(centerLatitude) eq 1) then begin
        if ((ABS(centerLatitude) eq 90 || centerLatitude eq 0) && $
            STRCMP(self._projection, 'Hotine Oblique Mercator', 23)) then begin
            self->ErrorMessage, SEVERITY=1, $
                'Hotine Oblique Mercator: ' + $
                IDLitLangCatQuery('Warning:MapProjection:CenterLatitude'), $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endif else begin
            self._centerLatitude = centerLatitude
            updateLimit = 1b
        endelse
    endif

    if (N_ELEMENTS(falseEasting) eq 1) then $
        self._falseEasting = falseEasting

    if (N_ELEMENTS(falseNorthing) eq 1) then $
        self._falseNorthing = falseNorthing

    if (N_ELEMENTS(height) eq 1) then $
        self._height = height

    if (N_ELEMENTS(hemisphere) eq 1 && $
        hemisphere ne self._hemisphere) then begin
        self._hemisphere = KEYWORD_SET(hemisphere)
        updateProjection = 1b
    endif

    if (N_ELEMENTS(homAzimAngle) eq 1) then $
        self._homAzimAngle = homAzimAngle

    if (N_ELEMENTS(homLatitude1) eq 1) then begin
        if (homLatitude1 ne self._homLonlat[3]) then begin
            self._homLonlat[1] = homLatitude1
        endif else begin
            self->ErrorMessage, SEVERITY=1, $
                'Hotine Oblique Mercator: ' + $
                IDLitLangCatQuery('Warning:MapProjection:Latitudes'), $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endelse
    endif

    if (N_ELEMENTS(homLatitude2) eq 1) then begin
        if (homLatitude2 ne self._homLonlat[1]) then begin
            self._homLonlat[3] = homLatitude2
        endif else begin
            self->ErrorMessage, SEVERITY=1, $
                'Hotine Oblique Mercator: ' + $
                IDLitLangCatQuery('Warning:MapProjection:Latitudes'), $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endelse
    endif

    if (N_ELEMENTS(homLongitude1) eq 1) then $
        self._homLonlat[0] = homLongitude1

    if (N_ELEMENTS(homLongitude2) eq 1) then $
        self._homLonlat[2] = homLongitude2

    if (N_ELEMENTS(isJustify) eq 1) then $
        self._isJustify = isJustify

    if (N_ELEMENTS(isZones) eq 1) then begin
        ; Make sure IS_ZONES is an even number. Round up if previous value
        ; was smaller, otherwise round down.
        self._isZones = ((self._isZones lt isZones) ? $
            2*CEIL(isZones/2d) : 2*FLOOR(isZones/2d)) > 2
    endif

    ; command-line support
    if (N_ELEMENTS(limit) eq 4 && $
        ~ARRAY_EQUAL(limit, self._limit)) then begin
        self._limit = limit
        self._userlimit = self._limit
    endif

    if (N_ELEMENTS(longitudeMin) && $
        self._limit[1] ne longitudeMin) then begin
        self._limit[1] = longitudeMin
        self._userlimit[1] = self._limit[1]
    endif

    if (N_ELEMENTS(longitudeMax) && $
        self._limit[3] ne longitudeMax) then begin
        self._limit[3] = longitudeMax
        self._userlimit[3] = self._limit[3]
    endif

    if (N_ELEMENTS(latitudeMin) && $
        self._limit[0] ne latitudeMin) then begin
        self._limit[0] = latitudeMin
        self._userlimit[0] = self._limit[0]
    endif

    if (N_ELEMENTS(latitudeMax) && $
        self._limit[2] ne latitudeMax) then begin
        self._limit[2] = latitudeMax
        self._userlimit[2] = self._limit[2]
    endif

    if (N_ELEMENTS(mercatorScale) eq 1) then $
        self._mercatorScale = mercatorScale

    if (N_ELEMENTS(oeaAngle) eq 1) then $
        self._oeaAngle = oeaAngle

    if (N_ELEMENTS(oeaShapem) eq 1) then $
        self._oeaShapem = oeaShapem

    if (N_ELEMENTS(oeaShapen) eq 1) then $
        self._oeaShapen = oeaShapen

    ; command-line support
    if (N_ELEMENTS(sphereRadius) eq 1) then begin
        semiMajor = sphereRadius  ; gets set below
        semiMinor = sphereRadius  ; gets set below
    endif

    if (N_ELEMENTS(semiMajor) eq 1 && self._semiMajor ne semiMajor) then begin
        self._semiMajor = semiMajor
        self->_IDLitMapProjection::GetProperty, IELLIPSOID=ell
        if (ell ne 0) then $
            self->_IDLitMapProjection::SetProperty, IELLIPSOID=0
    endif

    if (N_ELEMENTS(semiMinor) eq 1 && self._semiMinor ne semiMinor) then begin
        self._semiMinor = semiMinor
        self->_IDLitMapProjection::GetProperty, IELLIPSOID=ell
        if (ell ne 0) then $
            self->_IDLitMapProjection::SetProperty, IELLIPSOID=0
    endif

    if (N_ELEMENTS(somLandsatNumber) eq 1) then begin
        self._somLandsatNumber = somLandsatNumber
        self->SetPropertyAttribute, 'SOM_LANDSAT_PATH', $
            VALID_RANGE=self._somLandsatNumber ? [1,233] : [1,251]
        ; If switching to Landsat 4,5,7, restrict path to <= 233
        ; (<= 232 since we are zero-based).
        if (self._somLandsatNumber) then $
            self._somLandsatPath <= 232
    endif

    ; Make path zero-based to avoid save/restore issues in future.
    if (N_ELEMENTS(somLandsatPath) eq 1) then $
        self._somLandsatPath = somLandsatPath - 1

    if (N_ELEMENTS(somInclination) eq 1) then $
        self._somInclination = somInclination

    if (N_ELEMENTS(somLongitude) eq 1) then $
        self._somLongitude = somLongitude

    if (N_ELEMENTS(somPeriod) eq 1) then $
        self._somPeriod = somPeriod

    if (N_ELEMENTS(somRatio) eq 1) then $
        self._somRatio = somRatio

    if (N_ELEMENTS(somFlag) eq 1) then $
        self._somFlag = somFlag

    ; command-line support
    if (N_ELEMENTS(standardParallel) eq 1) then $
        standardPar1 = standardParallel  ; gets set below

    ; command-line support
    if (N_ELEMENTS(trueScaleLatitude) eq 1) then $
        standardPar1 = trueScaleLatitude  ; gets set below

    if (N_ELEMENTS(standardPar1) || N_ELEMENTS(standardPar2)) then begin
        sPar1 = N_ELEMENTS(standardPar1) ? standardPar1 : self._standardPar1
        sPar2 = N_ELEMENTS(standardPar2) ? standardPar2 : self._standardPar2

        ; For certain projection do not allow standard parallels
        ; to be equal and opposite.
        if ((sPar1 eq -sPar2) && $
            (self._projection eq 'Lambert Conformal Conic' || $
            self._projection eq 'Albers Equal Area')) then begin
            self->ErrorMessage, SEVERITY=1, $
                self._projection + ': ' + $
                IDLitLangCatQuery('Warning:MapProjection:StandardPars'), $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endif else begin
            self._standardPar1 = sPar1
            self._standardPar2 = sPar2
            updateLimit = 1b
        endelse
    endif

    if (N_ELEMENTS(statePlaneZone27) eq 1) then begin
        self._statePlaneZone27 = statePlaneZone27
        self->_UpdateStatePlane
        self->_UpdateEllipsoid   ; needed for Michigan ellipsoid
    endif

    if (N_ELEMENTS(statePlaneZone83) eq 1) then begin
        self._statePlaneZone83 = statePlaneZone83
        self->_UpdateStatePlane
    endif

    if (N_ELEMENTS(utmZone) eq 1) then begin
        ; Store from 0-59 so self._utmZone=0 becomes ZONE=1.
        newZone = 0 > (utmZone - 1) < 59
        if (newZone ne self._utmZone) then begin
            self._utmZone = newZone
            self->_UpdateUTMLongitude
        endif
    endif

    ; command-line support
    if (N_ELEMENTS(gctpzone) eq 1) then begin

        if (self._projection eq 'State Plane') then begin
            ; Are we using NAD27 or NAD83?
            isNAD27 = self._ellipsoid eq 'Clarke 1866'
            zones = isNAD27 ? $
                c_StatePlane_NAD27numbers : c_StatePlane_NAD83numbers
            ; See if the ZONE matches one of our NAD zones.
            match = (WHERE(FIX(zones) eq gctpzone))[0]
            if (match ge 0) then begin
                if isNAD27 then begin
                    self._statePlaneZone27 = match
                    self->_UpdateEllipsoid   ; needed for Michigan ellipsoid
                endif else begin
                    self._statePlaneZone83 = match
                endelse
                self->_UpdateStatePlane
            endif else begin
                badZone = 1
            endelse
        endif else begin
            ; Assume UTM projection. No big deal if we're not.
            ; Set HEMISPHERE directly to avoid calling _UpdateProjection.
            if (ABS(gctpzone) le 60 && gctpzone ne 0) then begin
                self._hemisphere = (gctpzone lt 0)
                self->_IDLitMapProjection::SetProperty, UTM_ZONE=ABS(gctpzone)
            endif else begin
                badZone = 1
            endelse
        endelse

        if (KEYWORD_SET(badZone)) then begin
            ; Illegal zone number.
            self->ErrorMessage, SEVERITY=1, $
                self._projection + ': ' + $
                IDLitLangCatQuery('Warning:MapProjection:Zone'), $
                TITLE=IDLitLangCatQuery('Menu:Operations:MapProjection')
        endif

    endif

    ; If we update the projection, this will also call _UpdateLimit
    if (updateProjection) then begin
        self->_UpdateProjection
    endif else if (updateLimit) then begin
        self->_UpdateLimit
    endif

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; _IDLitMapProjection__Define
;
; PURPOSE:
;    Defines the object structure for an _IDLitMapProjection object.
;
;-
pro _IDLitMapProjection__Define

    compile_opt idl2, hidden

    struct = { _IDLitMapProjection, $
        _previewDimensions: [0, 0], $
        _projection: '', $
        _datum: '', $  ; obsolete
        _ellipsoid: '', $
        _utmZone: 0b, $
        _hemisphere: 0b, $
        _isJustify: 0b, $
        _somLandsatNumber: 0b, $
        _somFlag: 0b, $
        _somLandsatPath: 0s, $
        _isZones: 0L, $
        _centerLongitude: 0d, $
        _centerLatitude: 0d, $
        _falseEasting: 0d, $
        _falseNorthing: 0d, $
        _height: 0d, $
        _homAzimAngle: 0d, $
        _mercatorScale: 0d, $
        _oeaShapem: 0d, $
        _oeaShapen: 0d, $
        _oeaAngle: 0d, $
        _semiMajor: 0d, $
        _semiMinor: 0d, $
        _somInclination: 0d, $
        _somLongitude: 0d, $
        _somPeriod: 0d, $
        _somRatio: 0d, $
        _standardPar1: 0d, $
        _standardPar2: 0d, $
        _statePlaneZone27: 0, $
        _statePlaneZone83: 0, $
        _homLonlat: DBLARR(4), $  ; [lon1,lat1,lon2,lat2]
        _limit: DBLARR(4), $  ; [latmin,lonmin,latmax,lonmax]
        _userlimit: DBLARR(4) $
        }
end
