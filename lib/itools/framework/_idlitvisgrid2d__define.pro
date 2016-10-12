; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitvisgrid2d__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitVisGrid2D
;
; PURPOSE:
;   This class represents a visualization whose underlying data
;   is organized as a grid.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::Init
;
; PURPOSE:
;   This function method initializes the component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('_IDLitVisGrid2D')
;
;    or
;
;   Obj->[_IDLitVisGrid2D::]Init
;
; KEYWORD PARAMETERS:
;   X_DATA_ID:  Set this keyword to the string representing
;     the name of the X data associated with this data.  The default
;     is 'X'.
;
;   Y_DATA_ID:  Set this keyword to the string representing
;     the name of the Y data associated with this data.  The default
;     is 'Y'.
;
;   Z_DATA_ID:  Set this keyword to the string representing
;     the name of the Z data associated with this data.  The default
;     is 'Z'.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function _IDLitVisGrid2D::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Set default values.
    self._gridDims = [1,1]
    self._gridOrigin = [0.0,0.0]
    self._gridStep = [1.0,1.0]
    self._userOrigin = [0.0,0.0]
    self._userStep = [1.0,1.0]
    self._gridUnitLabel = 'samples'
    self._geomUnitLabel = 'samples'
    self._xDataID = 'X'
    self._yDataID = 'Y'
    self._zDataID = 'Z'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisGrid2D::SetProperty, _EXTRA=_extra

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::Cleanup
;
; PURPOSE:
;   This procedure method preforms all cleanup on the object.
;
;   NOTE: Cleanup methods are special lifecycle methods, and as such
;   cannot be called outside the context of object destruction.  This
;   means that in most cases, you cannot call the Cleanup method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Cleanup method
;   from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[_IDLitVisGrid2D::]Cleanup
;
;-
pro _IDLitVisGrid2D::Cleanup

    compile_opt idl2, hidden

end


;----------------------------------------------------------------------------
; _IDLitVisGrid2D::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro _IDLitVisGrid2D::Restore

    compile_opt idl2, hidden

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        self._userOrigin = self._gridOrigin
        self._userStep = self._gridStep
    endif
end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisGrid2D::]GetProperty
;
; KEYWORD PARAMETERS:
;   GRID_DIMENSIONS:    Set this keyword to a named variable that upon
;     return will contain a 2-element vector, [nx, ny], representing
;     the dimensions of the grid.
;
;   GRID_STEP:  Set this keyword to a named variable that upon
;     return will contain a 2-element vector, [xstep, ystep], representing
;     the step size (in visualization data coordinates) between
;     grid indices.
;
;   PIXELATED: Set this keyword to a named variable that upon
;     return will contain a 1 if the grid has been set to represent
;     pixelated data, or 0 otherwise.
;
;   PIXEL_CENTER: Set this keyword to a named variable that upon
;     return will contain a 2-element vector, [cx, cy], representing
;     the location of a pixel center (relative to the grid origin).
;
;-
pro _IDLitVisGrid2D::GetProperty, $
    GRID_UNITS=gridUnits, $
    GEOMETRY_UNIT_LABEL=geomUnitLabel, $
    GRID_DIMENSIONS=gridDimensions, $
    GRID_ORIGIN=gridOrigin, $
    GRID_STEP=gridStep, $
    GRID_UNIT_LABEL=gridUnitLabel, $
    PIXELATED=pixelated, $
    PIXEL_CENTER=pixelCenter, $
    X_DATA_ID=xDataID, $
    Y_DATA_ID=yDataID, $
    Z_DATA_ID=zDataID

    compile_opt idl2, hidden

    if (ARG_PRESENT(gridUnits) ne 0) then $
        gridUnits = self._gridUnits

    if (ARG_PRESENT(geomUnitLabel) ne 0) then $
        geomUnitLabel = self._geomUnitLabel

    if (ARG_PRESENT(gridDimensions) ne 0) then $
        gridDimensions = self._gridDims

    if (ARG_PRESENT(gridOrigin) ne 0) then $
        gridOrigin = self._gridOrigin

    if (ARG_PRESENT(gridStep) ne 0) then $
        gridStep = self._gridStep

    if (ARG_PRESENT(gridUnitLabel) ne 0) then $
        gridUnitLabel = self._gridUnitLabel

    if (ARG_PRESENT(pixelated) ne 0) then $
        pixelated = self._bPixelated

    if (ARG_PRESENT(pixelCenter) ne 0) then $
        pixelCenter = self._pixelCenter

    if (ARG_PRESENT(xDataID)) then $
        xDataID = self._xDataID

    if (ARG_PRESENT(yDataID)) then $
        yDataID = self._yDataID

    if (ARG_PRESENT(zDataID)) then $
        zDataID = self._zDataID
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisGrid2D::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   _IDLitVisGrid2D::Init followed by the word "Set" can be retrieved
;   using _IDLitVisGrid2D::SetProperty.
;-
pro _IDLitVisGrid2D::SetProperty, $
    GRID_UNITS=gridUnitsIn, $
    GEOMETRY_UNIT_LABEL=geomUnitLabel, $
    GRID_ORIGIN=gridOrigin, $
    GRID_STEP=gridStep, $
    GRID_UNIT_LABEL=gridUnitLabel, $
    PIXELATED=pixelated, $
    PIXEL_CENTER=pixelCenter, $
    X_DATA_ID=xDataID, $
    Y_DATA_ID=yDataID, $
    Z_DATA_ID=zDataID

    compile_opt idl2, hidden

    if (N_ELEMENTS(gridUnitsIn) ne 0) then begin
      if (ISA(gridUnitsIn, 'STRING')) then begin
        case (STRLOWCASE(gridUnitsIn)) of
        'm': gridUnits = 1
        'meters': gridUnits = 1
        'deg': gridUnits = 2
        'degrees': gridUnits = 2
        else: gridUnits = 0
        endcase
      endif else begin
        gridUnits = gridUnitsIn
      endelse
      self._gridUnits = gridUnits
    endif

    if (N_ELEMENTS(geomUnitLabel) ne 0) then $
        self._geomUnitLabel = geomUnitLabel

    if (N_ELEMENTS(gridOrigin) eq 2) then $
        self._gridOrigin = gridOrigin

    if (N_ELEMENTS(gridStep) eq 2) then begin
        iNeg = WHERE(gridStep le 0, nNeg)
        if (nNeg eq 0) then $
            self._gridStep = gridStep
    endif

    if (N_ELEMENTS(gridUnitLabel) ne 0) then $
        self._gridUnitLabel = gridUnitLabel

    if (N_ELEMENTS(pixelated) ne 0) then $
        self._bPixelated = KEYWORD_SET(pixelated)

    if (N_ELEMENTS(pixelCenter) eq 1) then begin
        self._pixelCenter[0] = pixelCenter
        self._pixelCenter[1] = pixelCenter
    endif else if (N_ELEMENTS(pixelCenter) eq 2) then $
        self._pixelCenter = pixelCenter

    if (N_ELEMENTS(xDataID) gt 0) then $
        self._xDataID = xDataID
    if (N_ELEMENTS(yDataID) gt 0) then $
        self._yDataID = yDataID
    if (N_ELEMENTS(zDataID) gt 0) then $
        self._zDataID = zDataID
end

;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::OnDataChangeUpdate
;
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisGrid2D::]OnDataChangeUpdate, Subject, parmName
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;
;   parmName:   A string representing the name of the parameter
;     changed.
;
; KEYWORDS:
;   UPDATE_XYPARAMS_FROM_USERVALS: Set this keyword to a two-element
;     vector, [updateX, updateY], of boolean values indicating whether
;     the corresponding parameters (X, Y) should be updated based upon
;     the current user values (_userOrigin and _userStep).  By default,
;     these flags are 0.
;
;-
pro _IDLitVisGrid2D::OnDataChangeUpdate, oSubject, parmName, $
    UPDATE_XYPARAMS_FROM_USERVALS=inUpdateXYParams

    compile_opt idl2, hidden

    if (self._bDisableGridUpdate) then $
        return

    updateXYParams = (N_ELEMENTS(inUpdateXYParams) eq 2) ? $
        inUpdateXYParams : [0b,0b]

    ; Grab the Z data, if any.
    haveZ = 0
    oZData = self->GetParameter(self._zDataID)
    if (OBJ_VALID(oZData)) then begin
        ; Use the first Array2D in the Z parameter data object as
        ; the Z array for the grid.  Images may have multiple channels,
        ; but the dimensions should be the same.
        oDataObjs = oZData->GetByType("IDLARRAY2D")
        oZData = oDataObjs[0]
        haveZ = OBJ_VALID(oZData) ? oZData->GetData(pZData, /POINTER) : 0
    endif

    ; Grab the X data, if any.
    haveX = 0
    oXData = self->GetParameter(self._xDataID)
    if (OBJ_VALID(oXData) ne 0) then $
        haveX = oXData->GetData(pXData, /POINTER)

    ; Grab the Y data, if any.
    haveY = 0
    oYData = self->GetParameter(self._yDataID)
    if (OBJ_VALID(oYData) ne 0) then $
        haveY = oYData->GetData(pYData, /POINTER)

    ; Cache the grid dimensions.
    self._userDims = (haveZ ? SIZE(*pZData, /DIMENSIONS) : [1,1])
    self._gridDims = self._userDims
    self._gridOrigin = self._userOrigin
    self._gridStep = self._userStep

    ; Cache the X origin and step size.
    if (haveX) then begin
        if (updateXYParams[0] ne 0) then begin
            xData = self._userOrigin[0] + $
                DINDGEN(self._userDims[0]) * self._userStep[0]

            ; Temporarily disable grid updates for two reasons:
            ;   1) avoid redundancy (already in the process
            ;      of updating the grid)
            ;   2) avoid overwriting the grid settings during
            ;      a call back into this routine (as a result
            ;      of the ::SetData call) before the Y settings
            ;      are even processed in this iteration.
            self._bDisableGridUpdate = 1b
            result = oXData->SetData(xData, /NO_COPY)
            self._bDisableGridUpdate = 0b

        endif else begin
            if (self._userDims[0] eq 1) then begin
                dims = SIZE(*pXData, /DIMENSIONS)
                self._userDims[0] = (dims[0] > 2)
            endif

            xMin = MIN(*pXData, MAX=xMax)
            if (xMin eq xMax) then $
                xMax = xMin + self._gridDims[0] - 1
            self._gridOrigin[0] = xMin
            self._gridStep[0] = DOUBLE(xMax-xMin) / $
                DOUBLE(self._gridDims[0] - 1)
            self._userOrigin[0] = self._gridOrigin[0]
            self._userStep[0] = self._gridStep[0]
        endelse
    endif

    ; Cache the Y origin and step size.
    if (haveY) then begin
        if (updateXYParams[1]) then begin
            yData = self._userOrigin[1] + $
                DINDGEN(self._gridDims[1]) * self._userStep[1]

            self._bDisableGridUpdate = 1b
            result = oYData->SetData(yData, /NO_COPY)
            self._bDisableGridUpdate = 0b
        endif else begin
            if (self._gridDims[1] eq 1) then begin
                nDims = SIZE(*pYData, /N_DIMENSIONS)
                dims = SIZE(*pYData, /DIMENSIONS)
                self._gridDims[1] = (((nDims le 1) ? dims[0] : dims[1]) > 2)
            endif

            yMin = MIN(*pYData, MAX=yMax)
            if (yMin eq yMax) then $
                yMax = yMin + self._gridDims[0] - 1
            self._gridOrigin[1] = yMin
            self._gridStep[1] = DOUBLE(yMax-yMin) / $
                DOUBLE(self._gridDims[1] - 1)
            self._userOrigin[1] = self._gridOrigin[1]
            self._userStep[1] = self._gridStep[1]
        endelse
    endif
end

;----------------------------------------------------------------------------
; Grid Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::GeometryToGrid
;
; PURPOSE:
;   This procedure method transforms the given geometry to the
;   corresponding grid indices.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisGrid2D::]GeometryToGrid, geomX, geomY, $
;      gridX, gridY
;
; INPUTS:
;   geomX, geomY:   Vectors representing the X and Y components,
;     respectively, of geometrical coordinates in the dataspace of
;     this visualization.
;
;   gridX, gridY:   Vectors representing the X and Y components,
;     respectively, of the nearest grid indices corresponding to
;     the given geometrical coordinates.
;
;-
pro _IDLitVisGrid2D::GeometryToGrid, geomX, geomY, gridX, gridY

    compile_opt idl2, hidden

    ; Transform to grid index space.
    dxpos = DOUBLE(geomX - self._gridOrigin[0]) / self._gridStep[0]
    dypos = DOUBLE(geomY - self._gridOrigin[1]) / self._gridStep[1]

    if (self._bPixelated) then begin
        centerX = self._pixelCenter[0]
        centerY = self._pixelCenter[1]
    endif else begin
        centerX = 0.0
        centerY = 0.0
    endelse

    ; Add a very small epsilon to bump to next integer when extremely
    ; close.
    eps = 1e-12
    gridX = ULONG(((dxpos - centerX + 0.5 + eps) > 0.0)) < $
        (self._gridDims[0]-1)
    gridY = ULONG(((dypos - centerY + 0.5 + eps) > 0.0)) < $
        (self._gridDims[1]-1)
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::GridToGeometry
;
; PURPOSE:
;   This procedure method transforms the given grid indices to the
;   corresponding geometry for this visualization.
;
; CALLING SEQUENCE:
;   Obj->[_IDLitVisGrid2D::]GridToGeometry, gridX, gridY, $
;      geomX, geomY
;
; INPUTS:
;   gridX, gridY:   Vectors representing the X and Y components,
;     respectively, of the grid indices.
;
;   geomX, geomY:   Named variables that upon return will contain
;     vectors representing the X and Y components, respectively, of
;     the geometrical coordinates (in the dataspace of this visualization)
;     that corresponding to the given grid indices.
;
; KEYWORD PARAMETERS:
;   CENTER_ON_PIXEL: Set this keyword to a non-zero value to indicate
;     that the geometry location should be centered on the grid pixel.
;     By default, the computed geometry location falls directly on a
;     corresponding grid location.
;
;   Z_VALUE:    Set this keyword to a named variable that upon return
;     will contain a vector representing the Z components of the
;     grid at the given grid indices.
;
;-
pro _IDLitVisGrid2D::GridToGeometry, inGridX, inGridY, geomX, geomY, $
    CENTER_ON_PIXEL=centerOnPixel, $
    Z_VALUE=geomZ

    compile_opt idl2, hidden

    nCoord = N_ELEMENTS(inGridX)
    geomX = DBLARR(nCoord)
    geomY = DBLARR(nCoord)

    doZ = ARG_PRESENT(geomZ)

    ; Grab the X, Y (and, if requested, Z) data.
    haveX = 0
    oXData = self->GetParameter(self._xDataID)
    if (OBJ_VALID(oXData)) then $
        haveX = oXData->GetData(pXData, /POINTER)

    haveY = 0
    oYData = self->GetParameter(self._yDataID)
    if (OBJ_VALID(oYData)) then $
        haveY = oYData->GetData(pYData, /POINTER)

    if (doZ) then begin
        haveZ = 0
        oZData = self->GetParameter(self._zDataID)
        if (OBJ_VALID(oZData)) then begin
            ; Use the first Array2D in the Z parameter data object as
            ; the Z array for the grid.  Images may have multiple channels,
            ; but the dimensions should be the same.
            oDataObjs = oZData->GetByType("IDLARRAY2D")
            oZData = oDataObjs[0]
            haveZ = OBJ_VALID(oZData) ? oZData->GetData(pZData, /POINTER) : 0
        endif

        if (haveZ eq 0) then begin
            geomZ = DBLARR(nCoord)
            doZ = 0b
        endif
    endif

    ; Map to integral grid locations, and clamp to grid extents.
    if (self._bPixelated) then begin
        centerX = self._pixelCenter[0]
        centerY = self._pixelCenter[1]
    endif else begin
        centerX = 0.0
        centerY = 0.0
    endelse

    ; Add a very small epsilon to bump to next integer when extremely
    ; close.
    eps = 1e-12
    gridX = (ULONG(inGridX - centerX + 0.5d + eps) > 0) < (self._gridDims[0]-1)
    gridY = (ULONG(inGridY - centerY + 0.5d + eps) > 0) < (self._gridDims[1]-1)

    ; Transform to geometry.
    ; It would be nice to avoid potential floating point errors
    ; by doing an actual table lookup rather than computing via stepsize:
    ;    geomX = haveX ? (*pXData)[gridX] : DOUBLE(gridX)
    ;    geomY = haveY ? (*pYData)[gridY] : DOUBLE(gridY)
    ; However, for images, xData and yData are just 2-element
    ; vectors so we cannot in that case do a table lookup.
    geomX = self._gridOrigin[0] + (gridX * self._gridStep[0])
    geomY = self._gridOrigin[1] + (gridY * self._gridStep[1])

    ; If requested, fill in Z values.
    if (doZ) then begin
        indx = gridX + (gridY * self._gridDims[0])
        geomZ = (*pZData)[indx]
    endif

    ; If requested, offset XY results to center of pixel.
    if (KEYWORD_SET(centerOnPixel)) then begin
        if (self._bPixelated) then begin
            geomX = geomX + (self._pixelCenter[0] * self._gridStep[0])
            geomY = geomY + (self._pixelCenter[1] * self._gridStep[1])
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisGrid2D::GetZValue
;
; PURPOSE:
;   This function method retrieves the Z value(s) at the given X, Y
;   location(s) within the grid.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisGrid2D::]GetZValue( X, Y )
;
; INPUTS:
;   X, Y:   Vectors representing the X and Y components,
;     respectively, of the grid locations at which the Z values are
;     to be retrieved.
;
; KEYWORD PARAMETERS:
;   GRID:   Set this keyword to a nonzero value to indicate that
;     the X and Y arguments are grid indices.  By default, the X and
;     Y arguments are geometry values.
;
; OUTPUTS:
;   This function method returns the Z value at the given X, Y location.
;
;-
function _IDLitVisGrid2D::GetZValue, x, y, $
    GRID=grid

    compile_opt idl2, hidden

    ; If the coordinates are not already grid indices, map them
    ; now.
    if (KEYWORD_SET(grid)) then begin
       ; Add a very small epsilon to bump to next integer when extremely
       ; close.
       eps = 1e-12
       gridX = (ULONG(x + 0.5 + eps) > 0) < (self._gridDims[0]-1)
       gridY = (ULONG(y + 0.5 + eps) > 0) < (self._gridDims[1]-1)
    endif else begin
       self->GeometryToGrid, x, y, gridX, gridY
    endelse

    haveZ = 0
    oZData = self->GetParameter(self._zDataID)
    if (OBJ_VALID(oZData)) then begin
        ; Use the first Array2D in the Z parameter data object as
        ; the Z array for the grid.  Images may have multiple channels,
        ; but the dimensions should be the same.
        oDataObjs = oZData->GetByType("IDLARRAY2D")
        oZData = oDataObjs[0]
        haveZ = OBJ_VALID(oZData) ? oZData->GetData(pZData, /POINTER) : 0
    endif

    if (~haveZ) then $
        return, REPLICATE(0.0, N_ELEMENTS(x))

    indx = gridX + (gridY * self._gridDims[0])
    return, (*pZData)[indx]
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; _IDLitVisGrid2D__Define
;
; PURPOSE:
;   Defines the object structure for an _IDLitVisGrid2D object.
;-
pro _IDLitVisGrid2D__Define

    compile_opt idl2, hidden

    struct = { _IDLitVisGrid2D,     $
        _xDataID: '',               $ ; Identifier for X data.
        _yDataID: '',               $ ; Identifier for Y data.
        _zDataID: '',               $ ; Identifier for Z data.
        _gridDims: ULONARR(2),      $ ; Grid dimensions: [nx, ny]
        _gridOrigin: DBLARR(2),     $ ; Origin, [x,y], of grid in data coords
        _gridStep: DBLARR(2),       $ ; Step size between grid samples
                                    $ ;   [xstep, ystep] in data coordinates
        _gridUnitLabel: '',         $ ; Label for grid units
        _geomUnitLabel: '',         $ ; Label for geometry units
        _gridUnits: 0b,             $ ; List of possible units
        _bPixelated: 0b,            $ ; Flag: is data pixelated?
        _pixelCenter: FLTARR(2),    $ ; Pixel center, [x, y]
        _userDims: ULONARR(2),      $ ; Original dimensions
        _userOrigin: DBLARR(2),     $ ; User-specified origin, [x,y]
        _userStep: DBLARR(2),       $ ; User-specified step size
        _bDisableGridUpdate: 0b     $ ; Flag: grid updates temporarily
                                    $ ;   disabled (for optimization)?
    }
end
