; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertmapshape__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertMapShape
;
; PURPOSE:
;   This operation creates a map grid visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertMapShape::Init
;
;-

;-------------------------------------------------------------------------
function IDLitopInsertMapShape::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=[""], NUMBER_DS='1', $
        _EXTRA=_extra)) then $
        return, 0

    ; Combine all shapes by default.
    self._combineAll = 1

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopInsertMapShape::SetProperty, _EXTRA=_extra

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitopInsertMapShape::GetProperty, $
    COMBINE_ALL=combineAll, $
    SHAPEFILE=shapefile, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(combineAll)) then $
        combineAll = self._combineAll

    if (ARG_PRESENT(shapefile)) then $
        shapefile = self._shapefile

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopInsertMapShape::SetProperty, $
    COMBINE_ALL=combineAll, $
    SHAPEFILE=shapefile, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(combineAll) eq 1) then $
        self._combineAll = combineAll

    if (N_ELEMENTS(shapefile) eq 1) then $
        self._shapefile = shapefile

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopInsertMapShape::DoAction, oTool, $
  LIMIT=limitIn, NOCLIP=noClip, $
  _REF_EXTRA=ex

    compile_opt idl2, hidden

    oReadFile = oTool->GetService("READ_FILE")
    if (~OBJ_VALID(oReadFile)) then $
        return, OBJ_NEW()

    combineAll = self._combineAll

    if (~self._shapefile) then begin
        ; By default, key off our identifier to get the shapefile name.
        ; This avoids having to create a separate subclass for the
        ; most common cases in the iMap tool.
        self->IDLitComponent::GetProperty, IDENTIFIER=id

        ; For our build-in shapefiles, do not combine by default
        combineAll = 0

        case (id) of
        'CONTINENTS': begin
            combineAll = 1b
            shapefile = 'continents'
            end
        'COUNTRIESLOW': shapefile = 'country'
        'COUNTRIESHIGH': shapefile = 'cntry02'
        'RIVERS': shapefile = 'rivers'
        'LAKES': shapefile = 'lakes'
        'CITIES': shapefile = 'cities'
        'STATES': shapefile = 'states'
        'PROVINCES': shapefile = 'canadaprovince'
        else: shapefile = ''
        endcase

        if (shapefile ne '') then begin
            shapefile += '.shp'
            self._shapefile = FILEPATH(shapefile, $
                SUBDIR=['resource', 'maps', 'shape'])
        endif
    endif

    filename = self._shapefile

    if (~FILE_TEST(filename, /READ)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotOpenFile') + filename], $
            TITLE=IDLitLangCatQuery('Error:MapCont:Title'), severity=2
        return, OBJ_NEW()
    endif

    idReader = oReadFile->FindMatchingReader(filename, _ERRORMSG=errorMsg)
    if (idReader eq '') then begin
        self->ErrorMessage, errorMsg, $
            TITLE=IDLitLangCatQuery('Error:MapCont:Title'), severity=2
        return, OBJ_NEW()
    endif


    limit = [0, 0, 0, 0]   ; do not use limit by default

    if (~ISA(noClip) || ~KEYWORD_SET(noClip)) then begin
      if (ISA(limitIn)) then begin
        limit = limitIn
      endif else begin
        mapProj = (oTool->FindIdentifiers('*PROJECTION*', /VISUALIZATIONS))[0]
        oMap = (mapProj ne '') ? oTool->GetByIdentifier(mapProj) : OBJ_NEW()
        if (OBJ_VALID(oMap)) then $
          oMap->GetProperty, LIMIT=limit
      endelse
    endif


    oReaderDesc = oTool->GetByIdentifier(idReader)
    if (~OBJ_VALID(oReaderDesc)) then $
        return, OBJ_NEW()
    oReader = oReaderDesc->GetObjectInstance()

    ; Cache the old filename and properties.
    oldFilename = oReader->GetFilename()
    oReader->GetProperty, COMBINE_ALL=combineAllOrig

    ; Set our new filename.
    oReader->SetFilename, filename
    oReader->SetProperty, COMBINE_ALL=combineAll, LIMIT=limit

    success = oReader->GetData(oData)

    ; Set our previous values.
    oReader->SetFilename, oldFilename
    oReader->SetProperty, COMBINE_ALL=combineAllOrig
    oReaderDesc->ReturnObjectInstance, oReader

    if (~success) then $
        return, OBJ_NEW()


    self->IDLitComponent::GetProperty, NAME=myname

    ; If we have only 1 data object, change its name to match ours.
    if (combineAll) then $
        oData[0]->SetProperty, NAME=myname, DESCRIPTION=filename

    oData[0]->GetProperty, TYPE=type

    case (type) of
    'IDLSHAPEPOLYGON': visualization = 'Shape Polygon'
    'IDLSHAPEPOLYLINE': visualization = 'Shape Polyline'
    'IDLSHAPEPOINT': visualization = 'Shape Point'
    else: visualization = ''
    endcase


    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreate)) then $
        return, OBJ_NEW()


    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    oTool->AddByIdentifier, "/Data Manager", oData


    if (visualization ne '') then begin

        ; Call _Create so we don't have to worry about type matching.
        oVisDesc = oTool->GetVisualization(visualization)
        ndata = N_ELEMENTS(oData)
        names = (ndata gt 1) ? STRARR(ndata) : ''
        if (ndata gt 1) then $
            oVisDesc = REPLICATE(oVisDesc, ndata)

        for i=0,ndata-1 do begin
          if (ISA(oData[i])) then begin
            oData[i]->IDLitComponent::GetProperty, NAME=name
            names[i] = name
          endif
        endfor

        oVisCmd = oCreate->_Create(oVisDesc, oData, $
            FOLDER_NAME=myname, NAME=names, MANIPULATOR_TARGET=0, _EXTRA=ex)

    endif else begin

        ; Let the service figure out what type of vis to create.
        oVisCmd = oCreate->CreateVisualization(oData, $
            FOLDER_NAME=myname, _EXTRA=ex)

    endelse

    if (~OBJ_VALID(oVisCmd[0])) then $
        goto, skipover

    ; Make a prettier undo/redo name.
    oVisCmd[0]->SetProperty, NAME='Insert Map ' + myname


skipover:

    if (~previouslyDisabled) then $
        oTool->EnableUpdates

    return, oVisCmd

end


;-------------------------------------------------------------------------
pro IDLitopInsertMapShape__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertMapShape, $
        inherits IDLitOperation, $
        _combineAll: 0b, $
        _shapefile: ''}

end

