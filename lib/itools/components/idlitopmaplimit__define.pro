; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmaplimit__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMapLimit
;
; PURPOSE:
;   This file implements the Map Limit action. This is used by the
;   map panel to change the longitude/latitude min or max.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMapLimit::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopMapLimit::Init
;
; Purpose:
;   The constructor of the IDLitopMapLimit object.
;
; Arguments:
;   None.
;
function IDLitopMapLimit::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=[''], _EXTRA=_extra)) then $
        return, 0

    ; Defaults
    self._setLimit = 4
    self._lonMin = -180
    self._lonMax = 180
    self._latMin = -90
    self._latMax = 90

    self->RegisterProperty, 'SET_LIMIT', $
        NAME='Set limit', $
        ENUMLIST=['Longitude minimum', $
            'Longitude maximum', $
            'Latitude minimum', $
            'Latitude maximum', $
            'All limits']

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

    return, 1

end


;----------------------------------------------------------------------------
pro IDLitopMapLimit::GetProperty, $
    LONGITUDE_MIN=lonMin, $
    LONGITUDE_MAX=lonMax, $
    LATITUDE_MIN=latMin, $
    LATITUDE_MAX=latMax, $
    SET_LIMIT=setLimit, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(lonMin)) then $
        lonMin = self._lonMin

    if (ARG_PRESENT(lonMax)) then $
        lonMax = self._lonMax

    if (ARG_PRESENT(latMin)) then $
        latMin = self._latMin

    if (ARG_PRESENT(latMax)) then $
        latMax = self._latMax

    if (ARG_PRESENT(setLimit)) then $
        setLimit = self._setLimit

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitopMapLimit::SetProperty, $
    LONGITUDE_MIN=lonMin, $
    LONGITUDE_MAX=lonMax, $
    LATITUDE_MIN=latMin, $
    LATITUDE_MAX=latMax, $
    SET_LIMIT=setLimit, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(lonMin) gt 0) then $
        self._lonMin = lonMin

    if (N_ELEMENTS(lonMax) gt 0) then $
        self._lonMax = lonMax

    if (N_ELEMENTS(latMin) gt 0) then $
        self._latMin = latMin

    if (N_ELEMENTS(latMax) gt 0) then $
        self._latMax = latMax

    if (N_ELEMENTS(setLimit) gt 0) then begin
        self._setLimit = setLimit
        self->SetPropertyAttribute, 'LONGITUDE_MIN', $
            SENSITIVE=setLimit eq 0 || setLimit eq 4
        self->SetPropertyAttribute, 'LONGITUDE_MAX', $
            SENSITIVE=setLimit eq 1 || setLimit eq 4
        self->SetPropertyAttribute, 'LATITUDE_MIN', $
            SENSITIVE=setLimit eq 2 || setLimit eq 4
        self->SetPropertyAttribute, 'LATITUDE_MAX', $
            SENSITIVE=setLimit eq 3 || setLimit eq 4
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopMapLimit::_UndoRedoOperation, oCommand, item

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    ; Only look for our item. This is either ORIG_LIMIT or NEW_LIMIT.
    if (~oCommand->GetItem(item, value)) then $
        return, 1

    oCommand->GetProperty, TARGET_IDENTIFIER=idNormDataspace
    oNormDataspace = oTool->GetByIdentifier(idNormDataspace)
    if (~OBJ_VALID(oNormDataspace)) then $  ; sanity check
        return, 0
    oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
    if (~OBJ_VALID(oDataspace)) then $  ; sanity check
        return, 0

    oMapProj = oDataspace->_GetMapProjection()
    oMapProj->SetProperty, LIMIT=value

    ; Force the dataspace to updates its projection.
    oDataspace->OnProjectionChange

end


;---------------------------------------------------------------------------
function IDLitopMapLimit::UndoOperation, oCommand

    compile_opt idl2, hidden

    return, self->_UndoRedoOperation(oCommand, 'ORIG_LIMIT')

end


;---------------------------------------------------------------------------
function IDLitopMapLimit::RedoOperation, oCommand

    compile_opt idl2, hidden

    return, self->_UndoRedoOperation(oCommand, 'NEW_LIMIT')

end


;---------------------------------------------------------------------------
; Retrieve the map projection object for the current dataspace,
; set the new limit, then update the dataspace projection.
;
function IDLitopMapLimit::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve our dataspace on which to set the projection.
    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return, OBJ_NEW()
    oView = oWindow->GetCurrentView()
    oLayer = oView->GetCurrentLayer()
    oWorld = oLayer->GetWorld()
    oNormDataspace = oWorld->GetCurrentDataSpace()
    oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
    oMapProj = oDataspace->_GetMapProjection()

    oMapProj->GetProperty, LIMIT=origLimit

    newLimit = origLimit

    case (self._setLimit) of
    0: newLimit[1] = self._lonMin
    1: newLimit[3] = self._lonMax
    2: newLimit[0] = self._latMin
    3: newLimit[2] = self._latMax
    else: newLimit = [self._latMin, self._lonMin, self._latMax, self._lonMax]
    endcase

    if ARRAY_EQUAL(origLimit, newLimit) then $
        return, OBJ_NEW()

    ; Change our limits and update the dataspace projection.
    oMapProj->SetProperty, LIMIT=newLimit
    oDataspace->OnProjectionChange

    ; Create our command object.
    name = ['Longitude minimum', 'Longitude maximum', $
        'Latitude minimum', 'Latitude maximum', 'Map Limit']
    oCmd = OBJ_NEW('IDLitCommand', $
        NAME=name[self._setLimit < 4], $
        OPERATION_IDENTIFIER=self->GetFullIdentifier(), $
        TARGET_IDENTIFIER=oNormDataspace->GetFullIdentifier())
    void = oCmd->AddItem('ORIG_LIMIT', origLimit)
    void = oCmd->AddItem('NEW_LIMIT', newLimit)

    return, oCmd

end


;-------------------------------------------------------------------------
pro IDLitopMapLimit__define

    compile_opt idl2, hidden
    struc = {IDLitopMapLimit, $
        inherits IDLitOperation, $
        _setLimit: 0b, $
        _lonMin: 0d, $
        _lonMax: 0d, $
        _latMin: 0d, $
        _latMax: 0d $
        }

end

