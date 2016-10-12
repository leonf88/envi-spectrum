; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopisosurface__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopIsoSurface
;
; PURPOSE:
;   This operation creates an isosurface for a volume.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitOperation
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopIsoSurface::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopIsoSurface::Init
;
; Purpose:
; The constructor of the IDLitopIsoSurface object.
;
; Parameters:
; None.
;
function IDLitopIsoSurface::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; This only works with volumes as input
    if ~self->IDLitOperation::Init( $
        NAME="Isosurface", $
        DESCRIPTION="IDL Isosurface", $
        TYPES=["IDLARRAY3D"], _EXTRA=_extra) then $
        return, 0

    self._uiService = 'IsoSurface'

    ;; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'DECIMATE', /INTEGER, $
        NAME='Decimate', $
        DESCRIPTION='Decimate'

    self->RegisterProperty, '_ISOVALUE0', /FLOAT, $
        NAME='Isovalue', $
        DESCRIPTION='Isovalue'

    self->RegisterProperty, '_ISOVALUE1', /FLOAT, $
        NAME='Isovalue 1', $
        DESCRIPTION='Isovalue 1', $
        /HIDE

    self->RegisterProperty, 'SELECTED_DATASET', /INTEGER, $
        NAME='Selected dataset', $
        DESCRIPTION='Selected dataset'

    self._pDataObjects = PTR_NEW(/ALLOC)
    self._pPaletteObjects = PTR_NEW(/ALLOC)
    self._decimate = 100
    self._isovalue0 = 0
    self._isovalue1 = 0

    return, 1
end


;-------------------------------------------------------------------------
; IDLitopIsoSurface::Cleanup
;
; Purpose:
; The destructor of the IDLitopIsoSurface object.
;
; Parameters:
; None.
;
pro IDLitopIsoSurface::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._pDataObjects
    PTR_FREE, self._pPaletteObjects
    self->IDLitOperation::Cleanup
end


;-------------------------------------------------------------------------
; IDLitopIsoSurface::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopIsoSurface::GetProperty, $
    DATA_OBJECTS=dataObjects, $
    _ISOVALUE0=isovalue0, $
    _ISOVALUE1=isovalue1, $
    PALETTE_OBJECTS=paletteObjects, $
    USE_ISOVALUES=useIsoValue, $
    SELECTED_DATASET=selectedDataset, $
    DECIMATE=decimate, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(dataObjects) then $
        dataObjects = *self._pDataObjects

    if ARG_PRESENT(isovalue0) then $
        isovalue0 = self._isovalue0

    if ARG_PRESENT(isovalue1) then $
        isovalue1 = self._isovalue1

    if ARG_PRESENT(paletteObjects) then $
        paletteObjects = *self._pPaletteObjects

    ;; The operation is always creating a new isosurface, so
    ;; there is no existing isovalue to set in the UI.
    if ARG_PRESENT(useIsoValue) then $
        useIsoValue = 0

    if ARG_PRESENT(selectedDataset) then $
        selectedDataset = self._selectedDataset

    if ARG_PRESENT(decimate) then $
        decimate = self._decimate

    if N_ELEMENTS(_extra) gt 0 then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopIsoSurface::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopIsoSurface::SetProperty, $
    DATA_OBJECTS=dataObjects, $
    PALETTE_OBJECTS=paletteObjects, $
    _ISOVALUE0=isovalue0, $
    _ISOVALUE1=isovalue1, $
    SELECTED_DATASET=selectedDataset, $
    DECIMATE=decimate, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if N_ELEMENTS(dataObjects) gt 0 then $
        *self._pDataObjects = dataObjects

    if N_ELEMENTS(paletteObjects) gt 0 then $
        *self._pPaletteObjects = paletteObjects

    if N_ELEMENTS(isovalue0) gt 0 then $
        self._isovalue0 = isovalue0

    if N_ELEMENTS(isovalue1) gt 0 then $
        self._isovalue1 = isovalue1

    if N_ELEMENTS(selectedDataset) gt 0 then $
        self._selectedDataset = selectedDataset

    if N_ELEMENTS(decimate) eq 1 then $
        self._decimate = 1 > decimate < 100

    if N_ELEMENTS(_extra) gt 0 then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopIsoSurface::DoAction
;
; Purpose: Override from Operation because we are creating a viz
;   instead
;
; Parameters:
; None.
;
function IDLitopIsoSurface::DoAction, oTool

    compile_opt idl2, hidden

    ; Get the selected objects.
    oSelVis = (oTool->GetSelectedItems())[0]

    if (~OBJ_VALID(oSelVis)) then $
        return, OBJ_NEW()

    ;; Set our data objects for upcoming UI
    oVols = oSelVis->GetParameter(['VOLUME0','VOLUME1','VOLUME2','VOLUME3'])
    oPals = oSelVis->GetParameter(['RGB_TABLE0', 'RGB_TABLE1'])

    self->SetProperty, DATA_OBJECTS=oVols

    oPalSet = OBJ_NEW()

    case N_ELEMENTS(oVols) of

    1: if (N_ELEMENTS(oPals) ge 1 && OBJ_VALID(oPals[0])) then $
        oPalSet = oPals[0]

    2: if N_ELEMENTS(oPals) eq 2 && $
        OBJ_VALID(oPals[0]) && OBJ_VALID(oPals[1]) then $
        oPalSet = oPals

    4: if (N_ELEMENTS(oPals) ge 1 && OBJ_VALID(oPals[0])) then $
        oPalSet = oPals[[0,0,0,0]]

    else:

    endcase

    self->SetProperty, PALETTE_OBJECTS=oPalSet

    ;; Is some UI needed prior to execution?
    self->GetProperty, SHOW_EXECUTION_UI=bShowExecutionUI
    hasPropSet = 0b
    if bShowExecutionUI then begin
        ; Record all of our initial registered property values.
        oPropSet = self->IDLitOperation::RecordInitialProperties()
        hasPropSet = OBJ_VALID(oPropSet)
        if (~oTool->DoUIService(self._uiService, self)) then $
            goto, failure
        ; Record all of our final property values.
        if (hasPropSet) then $
            self->IDLitOperation::RecordFinalProperties, oPropSet
    endif

    self->IDLitComponent::GetProperty, NAME=myname

    ; We know that Interval Volume subclasses from us, so just put
    ; a special check here.
    if (myname eq 'Interval Volume' && $
        self._isovalue0 eq self._isovalue1) then begin
        self->ErrorMessage, IDLitLangCatQuery('Error:IsoSurface:IsoValueEqual'), $
            severity=2
        goto, failure
    endif

    void = oTool->DoUIService("HourGlassCursor", self)

    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME=myname + ' Data', $
        DESCRIPTION='Created by ' + myname)

    oParmSet->Add, oVols[self._selectedDataset], PARAMETER_NAME='VOLUME', $
                   /PRESERVE_LOCATION

    rgbData = (N_ELEMENTS(oVols) eq 2 && self._selectedDataset eq 1) ? $
        'RGB_TABLE1' : 'RGB_TABLE0'
    oParmSet->Add, oSelVis->GetParameter(rgbData), $
        PARAMETER_NAME='RGB_TABLE',/PRESERVE_LOCATION

    oParmSet->Add, oSelVis->GetParameter('VOLUME_DIMENSIONS'), $
        PARAMETER_NAME='VOLUME_DIMENSIONS',/PRESERVE_LOCATION
    oParmSet->Add, oSelVis->GetParameter('VOLUME_LOCATION'), $
        PARAMETER_NAME='VOLUME_LOCATION',/PRESERVE_LOCATION

    ; Create the Isosurface Visualization. Use _Create since we know the
    ; vis type (also avoids potential problems with type matching).
    oVisDesc = oTool->GetVisualization(myname)
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    oVisCommand = oCreateVis->_Create(oVisDesc, oParmSet, $
        ID_VISUALIZATION=idVis, $
        DECIMATE=self._decimate, $
        _ISOVALUE0=self._isovalue0, $
        _ISOVALUE1=self._isovalue1)

    oParmSet->Remove,/ALL
    obj_destroy,oParmSet

    ; Make a pretty undo/redo name.
    oVisCommand[N_ELEMENTS(oVisCommand)-1]->SetProperty, NAME=myname

    return, hasPropSet ? [oPropSet, oVisCommand] : oVisCommand

failure:
    if (hasPropSet) then begin
        ; Undo all of our set properties.
        void = self->UndoOperation(oPropSet)
        OBJ_DESTROY, oPropSet
    endif
    return, obj_new()

end

;-------------------------------------------------------------------------
pro IDLitopIsoSurface__define
    compile_opt idl2, hidden
    struc = {IDLitopIsoSurface,            $
             inherits IDLitOperation,      $
             _selectedDataset: 0,          $
             _uiService: '',               $
             _pDataObjects: PTR_NEW(),     $
             _pPaletteObjects: PTR_NEW(),  $
             _isovalue0: 0d,               $
             _isovalue1: 0d,               $
             _decimate:0b                  $
            }

end

