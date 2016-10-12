; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmapregisterimage__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMapRegisterImage
;
; PURPOSE:
;   This file implements the IDL Tool object that
;   implements the Map Projection action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMapRegisterImage::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopMapRegisterImage::Init
;
; Purpose:
;   The constructor of the IDLitopMapRegisterImage object.
;
; Arguments:
;   None.
;
function IDLitopMapRegisterImage::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=['IDLIMAGE'], $
        DESCRIPTION='Register an image on a map projection', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitPropertyAggregate::Init(_EXTRA=_extra)) then $
        return, 0

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self._updateDataspace = 1

    self->IDLitopMapRegisterImage::_RegisterProperties

    return, 1

end


;----------------------------------------------------------------------------
pro IDLitopMapRegisterImage::_RegisterProperties

    compile_opt idl2, hidden

    ; Register properties
    self->RegisterProperty, 'GRID_UNITS', $
        NAME='Coordinate units', $
        ENUMLIST=['Meters', 'Degrees'], $
        DESCRIPTION='Image coordinate units'

    self->RegisterProperty, 'XORIGIN', $
        DESCRIPTION='X location of image origin in data units', $
        NAME='Origin (x)', /FLOAT

    ; Hide XEND and YEND unless we have an actual image.
    ; Otherwise we don't know what image dimensions to use.
    self->RegisterProperty, 'XEND', $
        DESCRIPTION='X location of image end in data units', $
        NAME='End (x)', /FLOAT, /HIDE

    self->RegisterProperty, 'PIXEL_XSIZE', $
        DESCRIPTION='X size of a pixel in data units', $
        NAME='Pixel size (x)', /FLOAT

    self->RegisterProperty, 'YORIGIN', $
        DESCRIPTION='Y location of image origin in data units', $
        NAME='Origin (y)', /FLOAT

    self->RegisterProperty, 'YEND', $
        DESCRIPTION='Y location of image end in data units', $
        NAME='End (y)', /FLOAT, /HIDE

    self->RegisterProperty, 'PIXEL_YSIZE', $
        DESCRIPTION='Y size of a pixel in data units', $
        NAME='Pixel size (y)', /FLOAT

    self->RegisterProperty, 'MAP_PROJECTION', $
        NAME='Image map projection', $
        DESCRIPTION='Map projection for image', $
        USERDEF='No projection (click to edit)'

    self->RegisterProperty, 'UPDATE_DATASPACE', /BOOLEAN, $
        NAME='Update dataspace projection', $
        DESCRIPTION='Update dataspace projection with image projection'

end


;----------------------------------------------------------------------------
pro IDLitopMapRegisterImage::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oMapProj

    ; Cleanup superclasses.
    self->_IDLitPropertyAggregate::Cleanup
    self->IDLitOperation::Cleanup

end


;-------------------------------------------------------------------------
pro IDLitopMapRegisterImage::GetProperty, $
    PIXEL_XSIZE=pixelXSize, $
    PIXEL_YSIZE=pixelYSize, $
    UPDATE_DATASPACE=updateDataspace, $
    XEND=xEnd, $
    YEND=yEnd, $
    XORIGIN=xOrigin, $
    YORIGIN=yOrigin, $
    GRID_UNITS=gridUnits, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(pixelXSize)) then $
        pixelXSize = self._userStep[0]

    if (ARG_PRESENT(pixelYSize)) then $
        pixelYSize = self._userStep[1]

    if (ARG_PRESENT(updateDataspace)) then $
        updateDataspace = self._updateDataspace

    if (ARG_PRESENT(xEnd)) then $
        xEnd = self._userOrigin[0] + self._dims[0]*self._userStep[0]

    if (ARG_PRESENT(yEnd)) then $
        yEnd = self._userOrigin[1] + self._dims[1]*self._userStep[1]

    if (ARG_PRESENT(xOrigin)) then $
        xOrigin = self._userOrigin[0]

    if (ARG_PRESENT(yOrigin)) then $
        yOrigin = self._userOrigin[1]

    if (ARG_PRESENT(gridUnits)) then $
        gridUnits = self._gridUnits

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::GetProperty, _EXTRA=_extra
        self->GetAggregateProperty, _EXTRA=_extra
    endif
end


;-------------------------------------------------------------------------
pro IDLitopMapRegisterImage::SetProperty, $
    PIXEL_XSIZE=pixelXSize, $
    PIXEL_YSIZE=pixelYSize, $
    UPDATE_DATASPACE=updateDataspace, $
    XEND=xEnd, $
    YEND=yEnd, $
    XORIGIN=xOrigin, $
    YORIGIN=yOrigin, $
    GRID_UNITS=gridUnits, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    checkRange = 0b

    if (N_ELEMENTS(gridUnits) eq 1) then begin

        self._gridUnits = gridUnits

        xx = (gridUnits eq 1) ? 'Longitude' : 'X (or U)'
        yy = (gridUnits eq 1) ? 'Latitude' : 'Y (or V)'
        units = (gridUnits eq 1) ? 'deg' : 'meters'

        ; Change the property names.
        self->SetPropertyAttribute, 'XORIGIN', $
            NAME=xx + ' minimum (' + units + ')
        self->SetPropertyAttribute, 'YORIGIN', $
            NAME=yy + ' minimum (' + units + ')'
        self->SetPropertyAttribute, 'XEND', $
            NAME=xx + ' maximum (' + units + ')'
        self->SetPropertyAttribute, 'YEND', $
            NAME=yy + ' maximum (' + units + ')'
        self->SetPropertyAttribute, 'PIXEL_XSIZE', $
            NAME=xx + ' pixel size (' + units + ')'
        self->SetPropertyAttribute, 'PIXEL_YSIZE', $
            NAME=yy + ' pixel size (' + units + ')'

        ; Only need map projection for meters.
        self->SetPropertyAttribute, ['MAP_PROJECTION', 'UPDATE_DATASPACE'], $
            SENSITIVE=self._gridUnits eq 0

        ; Reset the values.
        if (gridUnits eq 1) then begin

            self->IDLitopMapRegisterImage::SetProperty, $
                XORIGIN=-180, YORIGIN=-90, $
                XEND=180, YEND=90

        endif else begin

            self->IDLitopMapRegisterImage::SetProperty, $
                XORIGIN=0, YORIGIN=0, $
                XEND=self._dims[0], YEND=self._dims[1]

        endelse

    endif

    ; Make sure pixel size is positive.
    if (N_ELEMENTS(pixelXSize) eq 1 && pixelXsize gt 0) then begin
        self._userStep[0] = pixelXSize
        checkRange = 1b
    endif

    ; Make sure pixel size is positive.
    if (N_ELEMENTS(pixelYSize) eq 1 && pixelYsize gt 0) then begin
        self._userStep[1] = pixelYSize
        checkRange = 1b
    endif

    if (N_ELEMENTS(xOrigin) eq 1) then begin
        self._userOrigin[0] = xOrigin
        checkRange = 1b
    endif

    if (N_ELEMENTS(yOrigin) eq 1) then begin
        self._userOrigin[1] = yOrigin
        checkRange = 1b
    endif

    if (N_ELEMENTS(xEnd) eq 1) then begin
        self._userStep[0] = (self._dims[0] gt 0) ? $
            (xEnd - self._userOrigin[0])/self._dims[0] : 1
        checkRange = 1b
    endif

    if (N_ELEMENTS(yEnd) eq 1) then begin
        self._userStep[1] = (self._dims[1] gt 0) ? $
            (yEnd - self._userOrigin[1])/self._dims[1] : 1
        checkRange = 1b
    endif

    if (N_ELEMENTS(updateDataspace) eq 1) then $
        self._updateDataspace = updateDataspace

    ; Make sure lat & lon are within valid range.
    if (checkRange && self._gridUnits) then begin

        ; First check the origin.
        self._userOrigin[0] = -180 > self._userOrigin[0] < 360
        self._userOrigin[1] = -90 > self._userOrigin[1] < 90

        ; If we have valid image dims, we can also check the endpoint.
        if (self._dims[0] gt 0) then begin
            self->GetProperty, XEND=xend, YEND=yend
            ; Image longitude can range from -180 to +180, or 0 to 360.
            xmax = (self._userOrigin[0] ge 0) ? 360 : 180
            if (xend gt xmax) then begin
                self._userStep[0] = (xmax - self._userOrigin[0])/self._dims[0]
            endif
            ; Image latitude can range from -90 to +90.
            if (yend gt 90) then begin
                self._userStep[1] = (90 - self._userOrigin[1])/self._dims[1]
            endif
        endif

    endif


    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::SetProperty, _EXTRA=_extra
        self->SetAggregateProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
; Retrieve the Projection object from ourself.
;
function IDLitopMapRegisterImage::_GetMapProjection

    compile_opt idl2, hidden

    ; Should only be true within the DoAction...UIService
    if (OBJ_VALID(self._oVis)) then $
        return, self._oVis->_GetMapProjection()

    if (~OBJ_VALID(self._oMapProj)) then begin
        self._oMapProj = OBJ_NEW('IDLitVisMapProjection', _PARENT=self)
        ; Don't want to set the limits. Our image projection doesn't
        ; need to set its limits, and we want the dataspace projection
        ; to define its own initial limits.
        self._oMapProj->SetPropertyAttribute, $
            ['LONGITUDE_MIN', 'LONGITUDE_MAX', $
            'LATITUDE_MIN', 'LATITUDE_MAX'], /HIDE
    endif

    return, self._oMapProj

end


;---------------------------------------------------------------------------
; Retrieve the GeoTIFF data object from the current vis.
; Returns null object if no current vis or GeoTIFF data.
;
function IDLitopMapRegisterImage::_GetGeoTIFFobj

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oVis)) then $
        return, OBJ_NEW()

    oParamSet = self._oVis->GetParameterSet()
    if (~OBJ_VALID(oParamSet)) then $
        return, OBJ_NEW()

    ; Since GEOTIFF isn't a registered parameter of the image vis,
    ; We can't do oVis->GetParameter('GEOTIFF'),
    ; nor can we do oParamSet->GetByName('GEOTIFF').
    ; Instead, try to just get it out of the container.
    oGeoData = (oParamSet->Get(/ALL, ISA='IDLitDataIDLGeoTIFF'))[0]

    return, OBJ_VALID(oGeoData) ? oGeoData : OBJ_NEW()

end


;----------------------------------------------------------------------------
function IDLitopMapRegisterImage::GetPreview

    compile_opt idl2, hidden

    return, OBJ_VALID(self._oMapProj) ? $
        self._oMapProj->GetPreview() : BYTARR(2,2)
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to edit a user-defined property.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   PropertyIdentifier: String giving the name of the userdef property.
;
; Keywords:
;   None.
;
function IDLitopMapRegisterImage::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'MAP_PROJECTION': begin
        ; Retrieve our map projection object.
        oMapProj = self->_GetMapProjection()

        ; Hide our own properties.
        self->GetPropertyAttribute, 'XEND', HIDE=endWasHidden
        hideProps = ['GRID_UNITS', 'XORIGIN', 'YORIGIN', $
            'PIXEL_XSIZE', 'PIXEL_YSIZE', $
            'MAP_PROJECTION', 'UPDATE_DATASPACE']
        self->SetPropertyAttribute, [hideProps, 'XEND', 'YEND'], /HIDE

        ; Pick up our map projection properties.
        self->AddAggregate, oMapProj

        success = oTool->DoUIService('MapProjection', self)

        self->RemoveAggregate, oMapProj

        self->SetPropertyAttribute, hideProps, HIDE=0
        ; Handle XEND and YEND separately, since they
        ; may already have been hidden.
        if (~endWasHidden) then $
            self->SetPropertyAttribute, ['XEND', 'YEND'], HIDE=0

        ; Update our userdef string.
        oMapProj->GetProperty, MAP_PROJECTION=mapProjection
        name = mapProjection
        name += ' (click to edit)'
        self->SetPropertyAttribute, 'MAP_PROJECTION', USERDEF=name

        return, success
        end

    else:

    endcase

    ; Call our superclass.
    return, self->IDLitOperation::EditUserDefProperty(oTool, identifier)

end


;---------------------------------------------------------------------------
; MAP_PROJECTION: If present, then do not fire up
;   the Map Projection operation at the end of Map Register Image.
;   Presumably, in this case the use has passed in the desired map
;   projection from the iMap procedure.
;
function IDLitopMapRegisterImage::DoAction, oTool, $
  MAP_PROJECTION=mapProjectionFromCmdLine

    compile_opt idl2, hidden

    oSelVis = oTool->GetSelectedItems()

    for i=0,N_ELEMENTS(oSelVis)-1 do begin

        oVis = oSelVis[i]
        if (~OBJ_VALID(oVis) || ~OBJ_ISA(oVis, 'IDLitVisImage')) then $
            continue

        self->GetProperty, SHOW_EXECUTION_UI=showUI

        if (showUI) then begin

            oVis->GetProperty, $
                GRID_UNITS=imageGridUnits, $
                GRID_DIMENSIONS=gridDimensions

            self._dims = gridDimensions

            if (imageGridUnits eq 0) then begin
                ; If image gridunits is 'None', set our gridunits to Degrees,
                ; so we reset lon/lat limits.
                self->IDLitopMapRegisterImage::SetProperty, GRID_UNITS=1
            endif else begin
                ; If image gridunits is Meters or Degrees, set our gridunits,
                ; but also copy over the image limits.
                oVis->GetProperty, $
                    PIXEL_XSIZE=pixelXSize, $
                    PIXEL_YSIZE=pixelYSize, $
                    XORIGIN=xOrigin, $
                    YORIGIN=yOrigin
                self->IDLitopMapRegisterImage::SetProperty, $
                    GRID_UNITS=imageGridUnits-1, $
                    PIXEL_XSIZE=pixelXSize, $
                    PIXEL_YSIZE=pixelYSize, $
                    XORIGIN=xOrigin, $
                    YORIGIN=yOrigin
            endelse

            ; Since we have image dimensions, show the X/YEND props.
            self->SetPropertyAttribute, ['XEND', 'YEND'], HIDE=0

            ; The MapRegisterImage wizard uses a separate button
            ; for the grid units, so disable the property.
            self->SetPropertyAttribute, 'GRID_UNITS', SENSITIVE=0
            ; The MapRegisterImage wizard uses a separate sheet
            ; for the projection, so hide the property.
            hideProps = ['DESCRIPTION', 'SHOW_EXECUTION_UI', $
                'MAP_PROJECTION', 'UPDATE_DATASPACE']
            self->SetPropertyAttribute, hideProps, /HIDE

            self._oVis = oVis
            success = oTool->DoUIService('MapRegisterImage', self)
            self._oVis = OBJ_NEW()

            if (~success) then $
                return, OBJ_NEW()

            ; Restore my property attributes, so the macro item
            ; will be correct.
            self->SetPropertyAttribute, ['XEND', 'YEND'], /HIDE
            self->SetPropertyAttribute, 'GRID_UNITS', /SENSITIVE
            self->SetPropertyAttribute, hideProps, HIDE=0
            self._dims = [0, 0]

            ; Copy all the projection params from the image to myself,
            ; so we have them available for a macro item.
            oVisProj = oVis->_GetMapProjection()
            props = oVisProj->QueryProperty()

            oVisProj->GetProperty, PROJECTION=projection

            oMapProj = self->_GetMapProjection()
            oMapProj->GetProperty, PROJECTION=currentProjection

            ; Do not combine this SetProperty with the one
            ; below, because setting PROJECTION will reset all
            ; the projection properties.
            if (projection ne currentProjection) then $
                oMapProj->SetProperty, PROJECTION=projection

            ; Start copying after PROJECTION property.
            props = props[(WHERE(props eq 'PROJECTION'))[0] + 1 : *]

            for i=0,N_ELEMENTS(props)-1 do begin
                prop = props[i]
                oVisProj->GetPropertyAttribute, prop, $
                    HIDE=hide, SENSITIVE=sensitive
                if (hide || ~sensitive) then $
                    continue
                if (~oVisProj->GetPropertyByIdentifier(prop, value)) then $
                    continue
                oMapProj->SetPropertyByIdentifier, prop, value
            endfor

            ; Update our userdef string.
            oMapProj->GetProperty, MAP_PROJECTION=mapProjection
            name = mapProjection
            name += ' (click to edit)'
            self->SetPropertyAttribute, 'MAP_PROJECTION', USERDEF=name

        endif ; show UI


        ; Convert from our gridunits property back to image property. This
        ; will set it to either 'Meters' or 'Degrees', but never to 'None'.
        imageGridUnits = self._gridUnits + 1

        _extra = { $
            GRID_UNITS: imageGridUnits, $
            PIXEL_XSIZE: self._userStep[0], $
            PIXEL_YSIZE: self._userStep[1], $
            XORIGIN: self._userOrigin[0], $
            YORIGIN: self._userOrigin[1] $
        }

        oSetProp = oTool->GetService("SET_PROPERTY")
        idVis = oVis->GetFullIdentifier()
        oCmd = oSetProp->DoSetPropertyWith_Extra(idVis, _EXTRA=_extra)

        ; If not run with the GUI, then we need to copy our
        ; projection props over to the image. This is for macros.
        if (~showUI && self._gridUnits eq 0) then begin
            oMapProj = self->_GetMapProjection()
            oVisProj = oVis->_GetMapProjection()

            ; Copy all properties from ourself to the map projection operation.
            props = oMapProj->QueryProperty()

            oMapProj->GetProperty, PROJECTION=projection
            oVisProj->GetProperty, PROJECTION=currentProjection
            ; Only set projection if it changed, to avoid resetting
            ; all the current projection properties.
            _extra = (projection ne currentProjection) ? $
                {PROJECTION: projection} : 0

            ; Start copying after PROJECTION property.
            props = props[(WHERE(props eq 'PROJECTION'))[0] + 1 : *]

            for i=0,N_ELEMENTS(props)-1 do begin
                prop = props[i]
                oMapProj->GetPropertyAttribute, prop, $
                    HIDE=hide, SENSITIVE=sensitive
                if (hide || ~sensitive) then $
                    continue
                if (~oMapProj->GetPropertyByIdentifier(prop, value)) then $
                    continue
                _extra = (N_TAGS(_extra) gt 0) ? $
                    CREATE_STRUCT(_extra, prop, value) : $
                    CREATE_STRUCT(prop, value)
            endfor

            ; Set all the properties on our map projection operation.
            if (N_TAGS(_extra) gt 0) then begin
                oProperty = oTool->GetService("SET_PROPERTY")
                oExtraCmd = oProperty->DoSetPropertyWith_Extra(oVisProj, $
                    _EXTRA=_extra)
                if (~OBJ_VALID(oExtraCmd)) then $
                    return, OBJ_NEW()
                oCmd = [oCmd, oExtraCmd]
            endif

        endif

        ; If Meters and we want to update our dataspace map projection.
        if (self._gridUnits eq 0 && self._updateDataspace) then begin

            oMapProj = self->_GetMapProjection()

            oDesc = oTool->GetByIdentifier('Operations/Operations/Map Projection')
            oMapOper = oDesc->GetObjectInstance()

            ; Copy all properties from ourself to the map projection operation.
            if (N_ELEMENTS(props) eq 0) then $
                props = oMapProj->QueryProperty()

            oMapProj->GetProperty, PROJECTION=projection
            oMapOper->GetProperty, PROJECTION=currentProjection
            ; Only set projection if it changed, to avoid resetting
            ; all the current projection properties.
            _extra = (projection ne currentProjection) ? $
                {PROJECTION: projection} : 0

            ; Start copying after PROJECTION property.
            props = props[(WHERE(props eq 'PROJECTION'))[0] + 1 : *]

            for i=0,N_ELEMENTS(props)-1 do begin
                prop = props[i]
                ; Don't want to set the limits. Our image projection doesn't
                ; need to set its limits, and we want the dataspace projection
                ; to define its own initial limits.
                if (prop eq 'LONGITUDE_MIN' || prop eq 'LONGITUDE_MAX' || $
                    prop eq 'LATITUDE_MIN' || prop eq 'LATITUDE_MAX') then $
                    continue
                oMapProj->GetPropertyAttribute, prop, $
                    HIDE=hide, SENSITIVE=sensitive
                if (hide || ~sensitive) then $
                    continue
                if (~oMapProj->GetPropertyByIdentifier(prop, value)) then $
                    continue
                _extra = (N_TAGS(_extra) gt 0) ? $
                    CREATE_STRUCT(_extra, prop, value) : $
                    CREATE_STRUCT(prop, value)
            endfor

            ; Set all the properties on our map projection operation.
            if (N_TAGS(_extra) gt 0) then begin
                oProperty = oTool->GetService("SET_PROPERTY")
                oExtraCmd = oProperty->DoSetPropertyWith_Extra(oMapOper, $
                    _EXTRA=_extra)
                if (~OBJ_VALID(oExtraCmd)) then $
                    return, OBJ_NEW()
                oCmd = [oCmd, oExtraCmd]
            endif

            oMapOper->GetProperty, SHOW_EXECUTION_UI=showUI
            oMapOper->SetProperty, SHOW_EXECUTION_UI=0
            ; This will automatically copy the projection properties from the
            ; map projection operation to the dataspace map projection,
            ; and insert a map grid if necessary.
            oCmdMap = oMapOper->DoAction(oTool)
            if (showUI) then $
                oMapOper->SetProperty, SHOW_EXECUTION_UI=showUI

            oCmd = [oCmd, oCmdMap]

        endif

        oCmds = (N_ELEMENTS(oCmds) gt 0) ? [oCmds, oCmd] : oCmd

    endfor

    if (N_ELEMENTS(oCmds) eq 0) then $
        return, OBJ_NEW()

    oCmd1 = oCmds[N_ELEMENTS(oCmds)-1]
    if (OBJ_VALID(oCmd1)) then $
        oCmd1->SetProperty, NAME='Register Image'

    ; CT, Dec 2008: If we don't currently have a map projection,
    ; then be nice and bring up the map projection dialog immediately.
    if (showUI && Obj_Valid(oVis) && ~N_Elements(mapProjectionFromCmdLine)) then begin
      sProj = oVis->GetProjection()
      if (N_TAGS(sProj) eq 0) then begin
        ; Add our map register operation to the undo buffer first.
        oTool->_TransactCommand, oCmds
        oCmds = OBJ_NEW()
        void = oTool->DoAction('Operations/Operations/Map Projection')
      endif
    endif

    oTool->RefreshCurrentWindow

    return, oCmds

end


;-------------------------------------------------------------------------
pro IDLitopMapRegisterImage__define

    compile_opt idl2, hidden
    struc = {IDLitopMapRegisterImage, $
        inherits _IDLitPropertyAggregate, $ ; Must come before IDLitComponent
        inherits IDLitOperation, $
        _oMapProj: OBJ_NEW(), $
        _oVis: OBJ_NEW(), $
        _dims: LON64ARR(2), $
        _userOrigin: DBLARR(2),     $ ; User-specified origin, [x,y]
        _userStep: DBLARR(2),        $ ; User-specified step size
        _gridUnits: 0b, $
        _updateDataspace: 0b $
        }

end

