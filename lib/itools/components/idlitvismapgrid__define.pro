; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvismapgrid__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisMapGrid
;
; PURPOSE:
;    The IDLitVisMapGrid class implements a a polyline visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-


;----------------------------------------------------------------------------
function IDLitVisMapGrid::Init, TOOL=oTool, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(NAME="Map Grid", $
        TYPE="IDLMAPGRID", $
        TOOL=oTool, $
        /ISOTROPIC, $
        ICON='axis', $
        DESCRIPTION="Map grid",$
        _EXTRA=_EXTRA))then $
        return, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->_RegisterProperties

    self._gridLongitude = 30
    self._gridLatitude = 15

    self._autoGrid = 1b

    self->_AddLineContainers

    self._oBox = OBJ_NEW('IDLitVisPolyline', NAME='Box Axes', HIDE=1, $
      IMPACTS_RANGE=0, MANIPULATOR_TARGET=0)
    self._oBox->SetPropertyAttribute, $
      ['ARROW_STYLE', 'ARROW_SIZE', 'ZVALUE'], /HIDE
    self->Add, self._oBox, /AGGREGATE, /NO_UPDATE, /NO_NOTIFY

    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisMapGrid::SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
;pro IDLitVisMapGrid::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitVisualization::Cleanup
;end


;----------------------------------------------------------------------------
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisMapGrid::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    ; Property added in IDL62.
    if (registerAll || (updateFromVersion lt 620)) then begin
        self->RegisterProperty, 'AUTO_GRID', /BOOLEAN, /ADVANCED_ONLY, $
            NAME='Automatic grid', $
            DESCRIPTION='Automatically compute the grid range and spacing'
    endif

    if (registerAll) then begin

        self->RegisterProperty, 'BOX_AXES', /BOOLEAN, $
            NAME='Box Axes', $
            DESCRIPTION='Display a box around the map area'

        self->RegisterProperty, 'HORIZON', /BOOLEAN, $
            NAME='Horizon', $
            DESCRIPTION='Draw the current map horizon'

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

        self->RegisterProperty, 'GRID_LONGITUDE', /FLOAT, $
            NAME='Longitude spacing', $
            DESCRIPTION='Longitude grid spacing in degrees', $
            VALID_RANGE=[0,360], /ADVANCED_ONLY

        self->RegisterProperty, 'GRID_LATITUDE', /FLOAT, $
            NAME='Latitude spacing', $
            DESCRIPTION='Latitude grid spacing in degrees', $
            VALID_RANGE=[0,360], /ADVANCED_ONLY

        self->RegisterProperty, 'EDIT_LONGITUDES', USERDEF='Click to edit', $
            NAME='Longitude lines', $
            DESCRIPTION='Edit individual longitude lines', /ADVANCED_ONLY

        self->RegisterProperty, 'EDIT_LATITUDES', USERDEF='Click to edit', $
            NAME='Latitude lines', $
            DESCRIPTION='Edit individual latitude lines', /ADVANCED_ONLY

    endif

end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisMapGrid::Restore

    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisMapGrid::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; In IDL64 we switched to always impact the range.
    if (self.idlitcomponentversion lt 640) then $
        self->SetProperty, /IMPACTS_RANGE
end


;----------------------------------------------------------------------------
pro IDLitVisMapGrid::_AddLineContainers

    compile_opt idl2, hidden


    for i=0,1 do begin
        self._oLineContainer[i] = OBJ_NEW('IDLitVisMapGridContainer', $
            NAME=(['Longitudes','Latitudes'])[i], $
            /PROPERTY_INTERSECTION)
        self._oLineContainer[i]->SetPropertyAttribute, $
            ['NAME', 'DESCRIPTION', 'HIDE'], /HIDE
        self->Add, self._oLineContainer[i], /AGGREGATE, $
            /NO_UPDATE, /NO_NOTIFY
    endfor

    ; Add one grid line so we pick up all the aggregated properties.
    self._limit = [0,0,0,0]  ; temporarily reset
    self->_UpdateGridlines, 0, sMap
    self->_UpdateGridlines, 1, sMap
    self._limit = [-90,-180,90,180]

end


;----------------------------------------------------------------------------
function IDLitVisMapGrid::_GetGridlines

    compile_opt idl2, hidden

    ; Return either the longitude or the latitude container & contents.
    oContainer = self._oLineContainer[self._container]
    oLines = oContainer->Get(/ALL, $
        ISA='IDLitVisMapGridline', COUNT=nlines)
    count = 0L
    for i=0,nlines-1 do begin
        oLines[i]->IDLgrModel::GetProperty, HIDE=hide
        if (hide) then $
            continue
        oLines[count] = oLines[i]  ; move to front
        count++  ; found a non-hidden line
    endfor

    ; Sanity check.
    oContainer->_CheckIntersectAttributes

    return, (count gt 0) ? [oContainer, oLines[0:count-1]] : oContainer

end


;----------------------------------------------------------------------------
pro IDLitVisMapGrid::_UpdateGridlines, isLatitude, sMap

    compile_opt idl2, hidden

    hasMap = (N_TAGS(sMap) gt 0)

    oLineContainer = self._oLineContainer[isLatitude]

    oLines = oLineContainer->Get(ISA='IDLitVisMapGridline', $
        /ALL, COUNT=ncurrent)

    gridSpacing = isLatitude ? self._gridLatitude : self._gridLongitude

    if (gridSpacing eq 0) then begin
        ; Zero grid spacing: Turn off all grid lines and return.
        for i=0,ncurrent-1 do $
            oLines[i]->SetProperty, /HIDE, IMPACTS_RANGE=0
        return
    endif

    ; Create/modify longitude/latitude lines
    mylimits = isLatitude ? self._limit[[0,2]] : self._limit[[1,3]]

    clip180 = 0b
    if (hasMap) then begin

        maplimits = isLatitude ? sMap.ll_box[[0,2]] : sMap.ll_box[[1,3]]

        if (~isLatitude && sMap.ll_box[1] eq -180 && sMap.ll_box[3] eq 180) then begin
            ; Find the center latitude of the projection.
            latMiddle = 0.5*(sMap.ll_box[0] + sMap.ll_box[2])
            uv180 = MAP_PROJ_FORWARD([-180, 180], [latMiddle, latMiddle], $
                MAP=sMap)
            if (MIN(FINITE(uv180)) eq 1) then begin
                dist = TOTAL((uv180[*,1] - uv180[*,0])^2)
                clip180 = (dist lt 1d-3)
            endif
        endif

    endif


    nlines = LONG((mylimits[1] - mylimits[0])/gridSpacing) + 1
    nlines = 1 > nlines < 360   ; arbitrary cutoff at 360 lines
    locations = DINDGEN(nlines)*gridSpacing + mylimits[0]

    ; Be sure to move the Equator or Prime Meridian to the front.
    izero = WHERE(locations eq 0, nzero, COMPLEMENT=notzero)
    if (nzero gt 0 && nzero lt nlines) then begin
        locations = [locations[izero], locations[notzero]]
    endif


    found180 = 0b

    if (ncurrent gt 0) then begin

        props = oLines[0]->QueryProperty()

        for i=ncurrent-1,0,-1 do begin
            oLines[i]->GetProperty, LOCATION=currLocation
            imatch = (WHERE(locations eq currLocation))[0]

            ; We found a match, so don't duplicate it below.
            if (imatch ge 0) then $
                locations[imatch] = -999

            ; If we already found 180E, and 180W would lie on top,
            ; then hide it.
            if (clip180 && ABS(currLocation) eq 180) then begin
                if (found180) then $
                    imatch = -1
                found180 = 1b
            endif

            ; If we didn't have a match, or the old line is out of bounds,
            ; then hide it. Otherwise turn it on.
            if (imatch lt 0) || $
                (hasMap && (currLocation lt maplimits[0] || $
                currLocation gt maplimits[1])) then begin
                oLines[i]->SetProperty, /HIDE, IMPACTS_RANGE=0
            endif else begin
                oLines[i]->SetProperty, HIDE=0, /IMPACTS_RANGE
                oLines[i]->OnProjectionChange, sMap
            endelse

        endfor

    endif


    ; Create new lines if necessary.
    for i=0,nlines-1 do begin

        if (locations[i] eq -999 || $
            (hasMap && (locations[i] lt maplimits[0] || $
            locations[i] gt maplimits[1]))) then $
            continue

        ; If we already found 180E, and 180W would lie on top,
        ; then hide it.
        if (clip180 && ABS(currLocation) eq 180) then begin
            if (found180) then $
                imatch = -1
            found180 = 1b
        endif

        strloc = STRING(ABS(locations[i]), FORMAT='(g0)')
        if (isLatitude) then begin
            name = (locations[i] eq 0) ? 'Equator (0N)' : $
                'Lat ' + strloc + ((locations[i] ge 0) ? 'N' : 'S')
        endif else begin
            name = (locations[i] eq 0) ? 'Prime Meridian (0E)' : $
                'Lon ' + strloc + ((locations[i] ge 0) ? 'E' : 'W')
        endelse

        oLine = OBJ_NEW('IDLitVisMapGridline', NAME=name, TOOL=self->GetTool())
        ; Copy properties from my first gridline over to the new one.
        for p=0,N_ELEMENTS(props)-1 do begin
            if (oLines[0]->GetPropertyByIdentifier(props[p], value)) then $
                oLine->SetPropertyByIdentifier, props[p], value
        endfor

        oLineContainer->Add, oLine, /AGGREGATE, $
            /NO_NOTIFY, /NO_UPDATE

        ; This will automatically call OnProjectionChange.
        ; Set HIDE=0 in case it got stomped by the copy props above.
        oLine->SetProperty, NAME=name, HIDE=0, $
            ORIENTATION=isLatitude, LOCATION=locations[i]

    endfor

end


;---------------------------------------------------------------------------
; For the current dataspace compute a default lon/lat range.
; Returns result as  [Latmin, Lonmin, Latmax, Lonmax]
;
function IDLitVisMapGrid::_ComputeGridRange, sMap

    compile_opt idl2, hidden

    ; Default grid range. [Latmin, Lonmin, Latmax, Lonmax]
    limit = [-90d, -180d, 90d, 180d]

    oDataspace = self->GetDataspace(/UNNORMALIZED)
    if (~OBJ_VALID(oDataspace)) then $
        return, limit

    ; Do we currently have a valid map projection?
    ; If so retrieve the map range and use it instead.
    haveMapProjection = N_TAGS(sMap) gt 0
    if (haveMapProjection) then begin
        oMapProj = oDataspace->_GetMapProjection()
        oMapProj->GetProperty, LIMIT=limit
    endif

    ; Flip range if necessary.
    if (limit[0] gt limit[2]) then $
        limit[[0,2]] = limit[[2,0]]
    if (limit[1] gt limit[3]) then $
        limit[[1,3]] = limit[[3,1]]

    ; Try to directly retrieve the lonlat range.
    success = oDataspace->GetLonLatRange(xrange, yrange, MAP_STRUCTURE=sMap)

    ; If that fails, use a brute force approach, given the dataspace range
    ; and the current map projection.
    if (~success) then begin
        success = oDataspace->GetXYZRange(xrange, yrange, zrange, $
            /NO_TRANSFORM)

        if (~success) then $
            return, limit
        if (xrange[0] eq xrange[1] || yrange[0] eq yrange[1]) then $
            return, limit

        if (haveMapProjection) then begin
            ; If the dataspace has a map projection,
            ; then convert a grid of points back to degrees.
            ; Note that we don't care what our image map projection is, just
            ; the dataspace, since that determines the U/V extent.
            n = 31
            xr = CONGRID(xrange, n, /INTERP, /MINUS)
            yr = REFORM(CONGRID(yrange, n, /INTERP, /MINUS), 1, n)
            lonlat = MAP_PROJ_INVERSE(REBIN(xr, n, n), REBIN(yr, n, n), $
                MAP_STRUCTURE=sMap)

            minn = MIN(lonlat, DIMENSION=2, MAX=maxx, /NAN)
            xrange = [minn[0], maxx[0]]
            yrange = [minn[1], maxx[1]]

        endif

    endif

    ; Flip range if necessary.
    if (xrange[0] gt xrange[1]) then $
        xrange = xrange[[1,0]]
    if (yrange[0] gt yrange[1]) then $
        yrange = yrange[[1,0]]

    ; Restrict our grid range to match contained visualizations.
    if (ABS(limit[1] - xrange[0]) gt 1e-3) then limit[1] >= xrange[0]
    if (ABS(limit[3] - xrange[1]) gt 1e-3) then limit[3] <= xrange[1]
    if (ABS(limit[0] - yrange[0]) gt 1e-3) then limit[0] >= yrange[0]
    if (ABS(limit[2] - yrange[1]) gt 1e-3) then limit[2] <= yrange[1]

    return, limit
end


;---------------------------------------------------------------------------
; For min/max range compute a default grid spacing in degrees.
;
function IDLitVisMapGrid::_ComputeGridSpacing, minn, maxx

    compile_opt idl2, hidden

    diff = abs(maxx - minn)

    case (1) of

    (diff le 2): return, diff/2d ; gives 3 lines

    (diff lt 10): return, 1 ; gives 2-10 lines

    (diff le 30): return, 5 ; gives 2-6 lines

    (diff le 60): return, 10 ; gives 3-6 lines

    (diff le 180): return, 15 ; gives 4-12 lines

    else: return, 30 ; gives 6-12 lines

    endcase

end


;----------------------------------------------------------------------------
pro IDLitVisMapGrid::OnProjectionChange, sMap, NO_NOTIFY=noNotify, $
    FORCE_UPDATE_GRID=forceUpdateGrid

    compile_opt idl2, hidden

    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    if (self._autoGrid) then begin

        ; Compute grid range. [Latmin, Lonmin, Latmax, Lonmax]
        limit = self->_ComputeGridRange(sMap)

        doNotify = 0b

        ; Compute grid spacing.
        gridLon = self->_ComputeGridSpacing(limit[1], limit[3])
        gridLat = self->_ComputeGridSpacing(limit[0], limit[2])
        if (gridLon ne self._gridLongitude || $
            gridLat ne self._gridLatitude) then begin
            self._gridLongitude = gridLon
            self._gridLatitude = gridLat
            doNotify = 1b
        endif

        ; Compute grid range.
        gridLon = self._gridLongitude
        gridLat = self._gridLatitude

        ; Make the limits be multiples of the grid spacing.
        if (gridLon gt 1) then begin
            limit[1] = -180 > FLOOR(limit[1]/gridLon)*gridLon
            limit[3] = CEIL(limit[3]/gridLon)*gridLon < 180
        endif
        if (gridLat gt 1) then begin
            limit[0] = -90 > FLOOR(limit[0]/gridLat)*gridLat
            limit[2] = CEIL(limit[2]/gridLat)*gridLat < 90
        endif

        if (~ARRAY_EQUAL(limit, self._limit)) then begin
            self._limit = limit
            doNotify = 1b
        endif


        ; Notify observers (like property sheet) that my lat lon limits
        ; or grid spacing have changed.
        if (doNotify) then begin
            self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
        endif

    endif

;    if (self._autoGrid || Keyword_Set(forceUpdateGrid)) then begin
        self->_UpdateGridlines, 0, sMap
        self->_UpdateGridlines, 1, sMap
;    endif

    self->UpdateSelectionVisual
    
    ; Box axes
    !NULL = self->GetCenterRotation(/NO_TRANSFORM, $
                                    /INCLUDE_AXES, $
                                    XRANGE=xRange, $
                                    YRANGE=yRange, $
                                    ZRANGE=zRange)
    coords = [[xRange[0], yRange[0]], $
              [xRange[0], yRange[1]], $
              [xRange[1], yRange[1]], $
              [xRange[1], yRange[0]], $
              [xRange[0], yRange[0]]]
    self._oBox->SetProperty, DATA=coords, HIDE=~self._boxAxes

    ; Fill
    if (ISA(self._oFill)) then begin
      limit = self._limit
      ; Nudge the corner points to avoid clipping issues.
      dx = 0.0001d*ABS(limit[3] - limit[1])
      dy = 0.0001d*ABS(limit[2] - limit[0])
      limit += [dy, dx, -dy, -dx]
      data = TRANSPOSE([[limit[[1,3,3,1]]], [limit[[0,0,2,2]]]])
      self._oFill->SetProperty, _DATA=data
      self._oFill->OnProjectionChange, self->GetProjection()
    endif
    
    if (~KEYWORD_SET(noNotify)) then begin
        self->IDLgrModel::GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then begin
            ; Lock ourself down, so we don't call back into here
            ; from the OnDataRangeChange.
            self._withinProjChange = 1b
            self->OnDataChange, oParent
            self->OnDataComplete, oParent
            self._withinProjChange = 0b
        endif
    endif

end


;----------------------------------------------------------------------------
pro IDLitVisMapGrid::GetProperty, $
    AUTO_GRID=autoGrid, $
    BOX_AXES=boxAxes, $
    FILL_COLOR=fillColor, $
    HORIZON=horizon, $
    GRID_LATITUDE=gridLatitude, $
    GRID_LONGITUDE=gridLongitude, $
    EDIT_LONGITUDES=editLongitudes, $
    EDIT_LATITUDES=editLatitudes, $
    LONGITUDE_MIN=longitudeMin, $
    LONGITUDE_MAX=longitudeMax, $
    LATITUDE_MIN=latitudeMin, $
    LATITUDE_MAX=latitudeMax, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(autoGrid) then $
        autoGrid = self._autoGrid

    if ARG_PRESENT(boxAxes) then $
        boxAxes = self._boxAxes

    if (ARG_PRESENT(fillColor) && ISA(self._oFill)) then begin
      if (ISA(self._oFill)) then begin
        self._oFill->GetProperty, FILL_COLOR=fillColor
      endif else fillColor = -1
    endif

    if ARG_PRESENT(horizon) then $
        horizon = self._horizon

    if ARG_PRESENT(editLatitudes) then $
        editLatitudes = 0

    if ARG_PRESENT(editLongitudes) then $
        editLongitudes = 0

    if ARG_PRESENT(gridLatitude) then $
        gridLatitude = self._gridLatitude

    if ARG_PRESENT(gridLongitude) then $
        gridLongitude = self._gridLongitude

    if ARG_PRESENT(latitudeMin) then $
        latitudeMin = self._limit[0]

    if ARG_PRESENT(latitudeMax) then $
        latitudeMax = self._limit[2]

    if ARG_PRESENT(longitudeMin) then $
        longitudeMin = self._limit[1]

    if ARG_PRESENT(longitudeMax) then $
        longitudeMax = self._limit[3]

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
pro IDLitVisMapGrid::SetProperty, $
    AUTO_GRID=autoGrid, $
    BOX_AXES=boxAxes, $
    COLOR=color, $
    THICK=thick, $
    LINESTYLE=linestyle, $
    HORIZON=horizon, $
    FILL_COLOR=fillColor, $
    HIDE=hide, $
    TRANSPARENCY=transparency, $
    GRID_LATITUDE=gridLatitude, $
    GRID_LONGITUDE=gridLongitude, $
    LONGITUDE_MIN=longitudeMin, $
    LONGITUDE_MAX=longitudeMax, $
    LATITUDE_MIN=latitudeMin, $
    LATITUDE_MAX=latitudeMax, $
    EDIT_LONGITUDES=editLongitudes, $ ; swallow (just userdef placeholder)
    EDIT_LATITUDES=editLatitudes, $ ; swallow (just userdef placeholder)
    LOCATION=location, $       ; swallow (don't aggregate)
    ORIENTATION=orientation, $ ; swallow (don't aggregate)
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    updateGrid = 0b

    if (N_ELEMENTS(autoGrid)) then begin
        self._autoGrid = autoGrid
        self->SetPropertyAttribute, ['LONGITUDE_MIN', 'LONGITUDE_MAX', $
            'LATITUDE_MIN', 'LATITUDE_MAX', $
            'GRID_LONGITUDE', 'GRID_LATITUDE'], $
            SENSITIVE=~self._autoGrid
        if (self._autoGrid) then updateGrid = 1b
    endif

    if (N_ELEMENTS(boxAxes)) then begin
        self._boxAxes = boxAxes
        updateGrid = 1b
    endif

    if (N_ELEMENTS(horizon)) then begin
        self._horizon = horizon
        updateGrid = 1b
    endif

    if (N_ELEMENTS(gridLatitude) && $
        gridLatitude ne self._gridLatitude) then begin
        self._gridLatitude = gridLatitude
        self._autoGrid = 0b
        updateGrid = 1b
    endif

    if (N_ELEMENTS(gridLongitude) && $
        gridLongitude ne self._gridLongitude) then begin
        self._gridLongitude = gridLongitude
        self._autoGrid = 0b
        updateGrid = 1b
    endif

    if (N_ELEMENTS(latitudeMin) && $
        latitudeMin ne self._limit[0]) then begin
        self._limit[0] = latitudeMin
        self._autoGrid = 0b
        updateGrid = 1b
    endif

    if (N_ELEMENTS(latitudeMax) && $
        latitudeMax ne self._limit[2]) then begin
        self._limit[2] = latitudeMax
        self._autoGrid = 0b
        updateGrid = 1b
    endif

    if (N_ELEMENTS(longitudeMin) && $
        longitudeMin ne self._limit[1]) then begin
        self._limit[1] = longitudeMin
        self._autoGrid = 0b
        updateGrid = 1b
    endif

    if (N_ELEMENTS(longitudeMax) && $
        longitudeMax ne self._limit[3]) then begin
        self._limit[3] = longitudeMax
        self._autoGrid = 0b
        updateGrid = 1b
    endif
    
    if (N_ELEMENTS(oPoly)) then begin
        self._oFill = oPoly
        updateGrid = 1b
    endif

    if (ISA(fillColor)) then begin
      if (ISA(fillColor, 'STRING')) then $
        STYLE_CONVERT, fillColor, COLOR=fillColor
      if (ARRAY_EQUAL(fillColor, [255b,255b,255b])) then $
        fillColor = -1
      if (ISA(self._oFill)) then begin
        self._oFill->SetProperty, FILL_COLOR=fillColor, $
          HIDE=(N_ELEMENTS(fillColor) ne 3)
      endif else begin
        if (N_ELEMENTS(fillColor) gt 1) then begin
          ; Nudge the corner points to avoid clipping issues.
          limit = self._limit
          dx = 0.0001d*ABS(limit[3] - limit[1])
          dy = 0.0001d*ABS(limit[2] - limit[0])
          limit += [dy, dx, -dy, -dx]
          points = limit[ [[1,0], [3,0], [3,2], [1,2]] ]
          self._oBox->GetProperty, TRANSPARENCY=transparency
          iPolygon, points, /DATA, OBJECT=oPolygon, /VISUALIZATION, $
            TARGET=self->GetFullIdentifier(), $
            MANIPULATOR_TARGET=0, FILL_COLOR=fillColor, $
            HIDE=hide, TRANSPARENCY=transparency
          self._oFill = oPolygon
        endif
      endelse
    endif
    
    if (ISA(hide) && ISA(self._oFill)) then $
      self._oFill->SetProperty, HIDE=hide

    if (ISA(transparency) && ISA(self._oFill)) then $
      self._oFill->SetProperty, TRANSPARENCY=transparency

    self._oBox->SetProperty, COLOR=color, HIDE=hide, THICK=thick, LINESTYLE=linestyle, $
      TRANSPARENCY=transparency

    self->IDLitVisualization::SetProperty, COLOR=color, HIDE=hide, THICK=thick, $
      LINESTYLE=linestyle, TRANSPARENCY=transparency, _EXTRA=_extra

    ; Is this object being initialized during creation?
    self->IDLitComponent::GetProperty, Initializing=isInit

    if (~isInit && updateGrid) then begin
        self->OnProjectionChange, /FORCE_UPDATE_GRID
    endif

    if (~isInit) then begin
        ; If more gridlines were created then our properties (like color)
        ; might no longer be equal for all intersected objects. Or if the
        ; labels were changed, some properties might have been (de)sensitized.
        ; In either case, check intersected properties for our line containers.
        self._oLineContainer[0]->_CheckIntersectAttributes
        self._oLineContainer[1]->_CheckIntersectAttributes
    endif

end


;----------------------------------------------------------------------------
function IDLitVisMapGrid::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    switch identifier of

        'EDIT_LONGITUDES': ; fall thru
        'EDIT_LATITUDES': begin
            self._container = (identifier eq 'EDIT_LATITUDES')
            success = oTool->DoUIService('MapGridlines', self)
            ; We want to return "failure" to avoid committing the Userdef
            ; property changes. But we need to commit our individual
            ; SetProperty actions. Note that hitting the "Close" (X) button
            ; still commits the actions.
            oTool->CommitActions
            return, 0   ; "failure", so we don't commit our userdef property
            break
            end

        else: break

    endswitch

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end


;---------------------------------------------------------------------------
; Convert a location from decimal degrees to DDDdMM'SS", where "d" is
; the degrees symbol.
;
function IDLitVisMapGrid::_DegToDMS, x, isLat, spacing

    compile_opt idl2, hidden

    if (~FINITE(x)) then $
        return, '---'

    eps = 1d-9
    x = (x ge 0) ? x + eps : x - eps
    degrees = ABS(FIX(x))
    minutes = FIX((ABS(x) - degrees)*60)
    seconds = (ABS(x) - degrees - minutes/60d)*3600

    dms = STRING(degrees, FORMAT='(I4)') + STRING(176b) + $
        STRING(minutes, FORMAT='(I2.2)') + "'" + $
        STRING(seconds, FORMAT='(I2.2)')

    ; If grid spacing is less than 10 arcseconds (~280 meters),
    ; then also output the fractional arcseconds.
    if (MIN(spacing) lt 0.0028) then $
      dms += STRMID(STRING(seconds mod 1, FORMAT='(f4.2)'),1)

    dms += '"' + (isLat ? (x lt 0 ? 'S' : 'N') : (x lt 0 ? 'W' : 'E'))

    return, dms

end


;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisMapGrid::GetDataString, xyz
    compile_opt idl2, hidden

    x = xyz[0]
    y = xyz[1]

    sMap = self->GetProjection()
    if (N_TAGS(sMap) gt 0) then begin
        lonlat = MAP_PROJ_INVERSE(x, y, MAP_STRUCTURE=sMap)
        x = lonlat[0]
        y = lonlat[1]
    endif

    value = self->_DegToDMS(x, 0, self._gridLongitude) + $
        '  ' + self->_DegToDMS(y, 1, self._gridLatitude)

    return, value

end


;----------------------------------------------------------------------------
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->OnDataRangeChange, oSubject, XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisMapGrid::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; We only care about dataspace range changes if Automatic grid is on.
    ; Use NO_NOTIFY to avoid notifying the dataspace again, since
    ; our range shouldn't affect the dataspace anyway.
    if (self._autoGrid && ~self._withinProjChange) then $
        self->OnProjectionChange, /NO_NOTIFY

end


;----------------------------------------------------------------------------
;+
; :Description:
;    Override the <i>_IDLitVisualization::Remove</i> method, so we can turn off
;    our AUTO_GRID property if one of the grid lines is deleted.
;
; :Params:
;    oVis
;
; :Keywords:
;    _REF_EXTRA
;
; :Author: chris
;-
pro IDLitVisMapGridContainer::Remove, oVis, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ((Obj_Valid(oVis))[0] && Obj_Isa(oVis[0], 'IDLitVisMapGridline')) then begin
        self->GetProperty, PARENT=oParent

        if (Obj_Valid(oParent) && Obj_Isa(oParent, 'IDLitVisMapGrid')) then begin
            oParent->SetProperty, AUTO_GRID=0
        endif
    endif
    
    self->_IDLitVisualization::Remove, oVis, _REF_EXTRA=_extra
end


;----------------------------------------------------------------------------
pro IDLitVisMapGridContainer__Define

    compile_opt idl2, hidden

    struct = { IDLitVisMapGridContainer,           $
        inherits _IDLitVisualization }

end


;----------------------------------------------------------------------------
;+
; IDLitVisMapGrid__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisMapGrid object.
;
;-
pro IDLitVisMapGrid__Define

    compile_opt idl2, hidden

    struct = { IDLitVisMapGrid,           $
        inherits IDLitVisualization,       $
        _oLineContainer: OBJARR(2), $
        _oLatLines: OBJ_NEW(), $
        _oBox: OBJ_NEW(), $
        _oFill: OBJ_NEW(), $
        _boxAxes: 0b, $
        _horizon: 0b, $
        _gridLongitude: 0d, $
        _gridLatitude: 0d, $
        _limit: DBLARR(4), $  ; [latmin,lonmin,latmax,lonmax]
        _autoGrid: 0b, $
        _container: 0b, $  ; current container (either 0 or 1)
        _withinProjChange: 0b $
        }
end
