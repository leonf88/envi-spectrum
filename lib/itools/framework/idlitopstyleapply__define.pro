; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopstyleapply__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopStyleApply
;
; PURPOSE:
;   This file implements the Style operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopStyleApply::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopStyleApply::Init
;
; Purpose:
; The constructor of the IDLitopStyleApply object.
;
; Arguments:
;   None.
;
function IDLitopStyleApply::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(NAME="Apply Style", $
        TYPES='', NUMBER_DS='1', _EXTRA=_extra)) then $
        return, 0

    ; Defaults.
    self._apply = 1
    self._updateCurrent = 1b

    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oGeneral = oTool->GetByIdentifier("/REGISTRY/SETTINGS/GENERAL_SETTINGS")
        if (OBJ_VALID(oGeneral)) then begin
            oGeneral->GetProperty, UPDATE_CURRENTSTYLE=updateCurrent
            self._updateCurrent = updateCurrent
        endif
    endif

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'STYLE_NAME', /STRING, $
        NAME='Style name', $
        DESCRIPTION='Name of the style to apply'

    self->RegisterProperty, 'APPLY', $
        NAME='Apply style to', $
        ENUMLIST=['Do not apply', 'Selected items', $
            'All items in current view', 'All items in all views'], $
        DESCRIPTION='Apply style to which items'

    self->RegisterProperty, 'UPDATE_CURRENT', /BOOLEAN, $
        NAME='Update current style', $
        DESCRIPTION='Update current style with new style'

    return, 1
end


;---------------------------------------------------------------------------
pro IDLitopStyleApply::GetProperty, $
    APPLY=apply, $
    STYLE_NAME=styleName, $
    UPDATE_CURRENT=updateCurrent, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(styleName) then $
        styleName = self._styleName

    if ARG_PRESENT(apply) then $
        apply = self._apply

    if ARG_PRESENT(updateCurrent) then $
        updateCurrent = self._updateCurrent

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopStyleApply::SetProperty, $
    APPLY=apply, $
    STYLE_NAME=styleName, $
    UPDATE_CURRENT=updateCurrent, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(styleName) eq 1) then $
        self._styleName = styleName

    if (N_ELEMENTS(apply) eq 1) then $
        self._apply = apply

    if (N_ELEMENTS(updateCurrent) eq 1) then $
        self._updateCurrent = updateCurrent

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopStyleApply::_GetSubItems
;
; Purpose:
;   Retrieve all _IDLitVisualization objects within a container.
;
; Arguments:
;   None.
;
function IDLitopStyleApply::_GetSubItems, oContainer, COUNT=count

    compile_opt idl2, hidden

    oItems = oContainer->Get(/ALL, ISA='_IDLitVisualization', COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()

    count = 0
    keep = WHERE(~OBJ_ISA(oItems, 'IDLitManipulatorVisual'), nitems)
    if (nitems eq 0) then $
        return, OBJ_NEW()
    oItems = oItems[keep]

    for i=0,nitems-1 do begin
        oItems[i]->IDLgrModel::GetProperty, HIDE=hide, PRIVATE=private
        if (hide || private) then $
            oItems[i] = OBJ_NEW()
    endfor
    keep = WHERE(OBJ_VALID(oItems), nitems)
    if (nitems eq 0) then $
        return, OBJ_NEW()
    oItems = oItems[keep]

    oResult = oItems     ; return all our contained objects

    for i=0,nitems-1 do begin
        ; Get our item's subitems, if any.
        oSubItems = self->_GetSubItems(oItems[i], COUNT=nsub)
        if (nsub gt 0) then $
            oResult = [oResult, oSubItems]
    endfor

    count = N_ELEMENTS(oResult)
    return, oResult
end


;---------------------------------------------------------------------------
; IDLitopStyleApply::_GetAllItems
;
; Purpose:
;   Retrieve all objects in the current view.
;
; Arguments:
;   None.
;
function IDLitopStyleApply::_GetAllItems, oTool, $
    APPLY=apply, COUNT=count

    compile_opt idl2, hidden

    count = 0

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()

    if (N_ELEMENTS(apply) && (apply eq 3)) then begin
        oScene = oWin->GetScene()
        oView = oScene->Get(/ALL, COUNT=nView)
    endif else begin
        oView = oWin->GetCurrentView()
        nView = OBJ_VALID(oView)
    endelse

    for v=0, nView-1 do begin
        oLayers = oView[v]->Get(/ALL, ISA='IDLitgrLayer', COUNT=nlayers)
        if (nlayers eq 0) then $
            continue

        ; At least return our layers.
        oResult = (N_ELEMENTS(oResult) eq 0) ? $
            oLayers : [oResult, oLayers]

        for i=0,nlayers-1 do begin
            if (OBJ_ISA(oLayers[i], 'IDLitgrAnnotateLayer')) then begin
                ; For the annotation layer we want to bypass the dataspace,
                ; so it doesn't get included in the style.
                oContainer = oLayers[i]->GetCurrentDataspace()
            endif else begin
                ; For other layers just get the world and find
                ; everything within it.
                oContainer = oLayers[i]->GetWorld()
                if (~OBJ_VALID(oContainer)) then $
                    continue
            endelse
            oSubItems = self->_GetSubItems(oContainer, COUNT=nsub)
            if (nsub gt 0) then $
                oResult = [oResult, oSubItems]
        endfor
    endfor

    count = N_ELEMENTS(oResult)
    return, (count gt 0) ? oResult : OBJ_NEW()
end


;---------------------------------------------------------------------------
; Internal function to recurse within a style container
; and retrieve all style items (object descriptors).
;
; oStyle must be a valid IDLitContainer.
;
function IDLitopStyleApply::_GetStyleItems, oStyle, COUNT=count

    compile_opt idl2, hidden

    oItems = oStyle->Get(/ALL, COUNT=nitems)

    for i=0,nitems-1 do begin
        oSubItem = oItems[i]
        if (OBJ_ISA(oSubItem, 'IDLitContainer')) then begin
            oSubItem = self->_GetStyleItems(oSubItem[0], COUNT=nsub)
            if (nsub eq 0) then $
                continue
        endif
        oResult = (N_ELEMENTS(oResult) gt 0) ? $
            [oResult, oSubItem] : oSubItem
    endfor

    count = N_ELEMENTS(oResult)
    return, (count gt 0) ? oResult : OBJ_NEW()

end


;---------------------------------------------------------------------------
; IDLitopStyleApply::DoAction
;
; Purpose:
;
; Arguments:
;   oTool.
;
; Keywords:;
;   NO_TRANSACT: If set then an Undo/Redo command set is not returned.
;
function IDLitopStyleApply::DoAction, oTool, NO_TRANSACT=noTransact

    compile_opt idl2, hidden

    oSys = oTool->_GetSystem()
    oService = oSys->GetService('STYLES')
    if (~Obj_Valid(oService)) then return, Obj_New()
    oService->VerifyStyles

    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI

    if (showUI) then begin

        oldUpdateCurrent = self._updateCurrent

        if (~oTool->DoUIService('StyleApply', self)) then $
            return, OBJ_NEW()

        ; Change hidden Update Current Style preference setting.
        if (self._updateCurrent ne oldUpdateCurrent) then begin
            oGeneral = oSys->GetByIdentifier("/REGISTRY/SETTINGS/GENERAL_SETTINGS")
            oGeneral->SetProperty, UPDATE_CURRENTSTYLE=self._updateCurrent
            oSys->_SaveSettings
        endif

    endif

    void = oTool->DoUIService("HourGlassCursor", self)

    oStyle = oService->GetByName(self._styleName)
    if (~OBJ_VALID(oStyle)) then $
        return, OBJ_NEW()

    ; Update current tool style?
    if (self._updateCurrent) then begin
        oCmd = oService->UpdateCurrentStyle(self._styleName, $
            NO_TRANSACT=noTransact)
        if OBJ_VALID(oCmd[0]) then $
            oCmdSet = oCmd
    endif

    if (~self._apply) then $
        goto, finish

    if (self._apply ge 2) then begin

        oSel = self->_GetAllItems(oTool, APPLY=self._apply, COUNT=nsel)

    endif else begin

        oSel = oTool->GetSelectedItems(COUNT=nsel)

        ; If nothing selected, retrieve the first Visualization Layer.
        if (nsel eq 0) then begin
            oWin = oTool->GetCurrentWindow()
            if (~OBJ_VALID(oWin)) then $
                goto, finish
            oView = oWin->GetCurrentView()
            if (~OBJ_VALID(oView)) then $
                goto, finish
            oSel = oView->Get(ISA='IDLitgrLayer', COUNT=nsel)
        endif

    endelse

    if (~nsel) then $
        goto, finish


    ; Recursively retrieve all style items (object descriptors).
    oPropBags = self->_GetStyleItems(oStyle, COUNT=nitems)
    if (~nitems) then $
        goto, finish

    styleIDs = STRARR(nitems)
    for i=0,nitems-1 do begin
        oPropBags[i]->IDLitComponent::GetProperty, IDENTIFIER=id
        styleIDs[i] = id
    endfor
    slen = STRLEN(styleIDs)

    doTransact = ~KEYWORD_SET(noTransact)

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    for i=0,nsel-1 do begin

        oSel[i]->IDLitComponent::GetProperty, IDENTIFIER=idItem

        ; See if we have a match between the style item and the viz.
        ; We will use the base portion of the identifier to see
        ; if we have a match. The identifier of the viz item should
        ; be identical, except for perhaps an additional number
        ; such as _2, _3, etc.
        idItem = (STRSPLIT(idItem, '_1234567890', /EXTRACT))[0]
        match = (WHERE(STRCMP(idItem, styleIDs, /FOLD_CASE)))[0]
        if (match lt 0) then $
            continue

        ; Record all of our initial registered property values.
        if (doTransact) then begin
            oPropSet = self->RecordInitialProperties( $
                oSel[i], oPropBags[match], /SKIP_HIDDEN)
        endif

        oPropBags[match]->PlaybackProperties, oSel[i], /SKIP_HIDDEN

        ; Record all of our final property values.
        if (OBJ_VALID(oPropSet)) then begin
            self->RecordFinalProperties, oPropSet, $
                /NOTIFY, /SKIP_MACROHISTORY
            oCmdSet = (N_ELEMENTS(oCmdSet) gt 0) ? $
                [oCmdSet, TEMPORARY(oPropSet)] : TEMPORARY(oPropSet)
        endif

        ; Mark the tool as needing a refresh at the end.
        oTool->RefreshCurrentWindow

    endfor  ; selected visualizations

    if (~wasDisabled) then $
        oTool->EnableUpdates

finish:
    nCmd = N_ELEMENTS(oCmdSet)

    ; Make the name of my command set equal to the style name.
    if (nCmd gt 0) then begin
        name = self._styleName
        if (STRPOS(STRUPCASE(name), 'STYLE') eq -1) then $
            name += ' Style'
        oCmdSet[nCmd-1]->IDLitComponent::SetProperty, NAME=name
        return, oCmdSet
    endif

    return, OBJ_NEW()

end


;-------------------------------------------------------------------------
pro IDLitopStyleApply__define

    compile_opt idl2, hidden

    struc = {IDLitopStyleApply, $
             inherits IDLitOperation, $
             _styleName: '', $
             _apply: 0b, $
             _updateCurrent: 0b }
end

