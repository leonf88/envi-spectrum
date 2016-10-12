; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopstylecreate__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopStyleCreate
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
;   See IDLitopStyleCreate::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopStyleCreate::Init
;
; Purpose:
; The constructor of the IDLitopStyleCreate object.
;
; Arguments:
;   None.
;
function IDLitopStyleCreate::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitopStyleApply::Init(NAME="Create Style", $
        TYPES='', _EXTRA=_extra)

end


;-------------------------------------------------------------------------
; IDLitopStyleCreate::GetProperty
;
; Purpose:
;
; Arguments:
;   None.
;
pro IDLitopStyleCreate::GetProperty, $
    CREATE_ALL=createAll, $
    TEXT=text, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(createAll)) then $
        createAll = self._createAll

    if (ARG_PRESENT(text)) then $
        text = self._text

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopStyleApply::GetProperty,_EXTRA=_extra

end


;-------------------------------------------------------------------------
; IDLitopStyleCreate::SetProperty
;
; Purpose:
;
; Arguments:
;   None.
;
pro IDLitopStyleCreate::SetProperty, $
    CREATE_ALL=createAll, $
    TEXT=text, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(createAll) gt 0) then $
        self._createAll = createAll

    if (N_ELEMENTS(text) gt 0) then $
        self._text = text

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopStyleApply::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitopStyleCreate::DoAction
;
; Purpose:
;
; Arguments:
;   None.
;
function IDLitopStyleCreate::DoAction, oTool, STYLE=style

    compile_opt idl2, hidden

    oSys = oTool->_GetSystem()

    oService = oSys->GetService('STYLES')
    if (~Obj_Valid(oService)) then return, Obj_New()
    oService->VerifyStyles

try_again:
    ; Ask the user for a new name for this style.
    if (~oTool->DoUIService('StyleCreate', self)) then $
        return, OBJ_NEW()
    if (self._text eq '') then $
        return, OBJ_NEW()

    ; Check for / characters.
    if (STRPOS(self._text, '/') ge 0) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Name:Slash'), $
            IDLitLangCatQuery('Error:CreateStyle:DiffName')], $
            TITLE=IDLitLangCatQuery('Error:CreateStyle:Title'), $
            SEVERITY=2
        goto, try_again
    endif

    ; Don't allow null strings or just spaces.
    if (STRLEN(STRCOMPRESS(self._text, /REMOVE)) eq 0) then $
        self._text = oService->_NewStyleName('New Style')

    ; Get by either identifier or by name, in case they don't
    ; match for some styles.
    oExists = oService->Get(self._text)
    if (~OBJ_VALID(oExists)) then $
        oExists = oService->GetByName(self._text)

    if OBJ_VALID(oExists) then begin
        str = '/REGISTRY/STYLES/SYSTEM'
        if (STRCMP(oExists->GetFullIdentifier(), str, STRLEN(str)) || $
            STRCMP(self._text, 'CURRENT STYLE', /FOLD_CASE)) then begin
            self->ErrorMessage, $
                [IDLitLangCatQuery('Error:CreateStyle:SysStyle') + $
                '"' + self._text + '".', $
                IDLitLangCatQuery('Error:CreateStyle:DiffName')], $
                TITLE=IDLitLangCatQuery('Error:CreateStyle:Title'), $
                SEVERITY=2
            goto, try_again
        endif
        void = self->PromptUserYesNo( $
            [IDLitLangCatQuery('Error:StyleExists:Word') + $
            ' ' + self._text + $
            IDLitLangCatQuery('Error:StyleExists:Exists'), $
            IDLitLangCatQuery('Error:StyleExists:Overwrite')], $
            answer, $
            TITLE=IDLitLangCatQuery('Error:StyleExists:Title'))
        if ~answer then $
            goto, try_again
        oSys->Unregister, '/Registry/Styles/My Styles/' + self._text
    endif


    void = oTool->DoUIService("HourGlassCursor", self)


    if (self._createAll) then begin

        ; Retrieve all layers and visualizations in the current view.
        oSel = self->IDLitopStyleApply::_GetAllItems(oTool, COUNT=nsel)
        if (~nsel) then $
            return, OBJ_NEW()

    endif else begin

        oSel = oTool->GetSelectedItems(COUNT=nsel)

        if (nsel gt 0) then begin
            ; GetSelectedItems returns the selections in order from
            ; the most recently selected. We want to create the style
            ; in the opposite order, so that the *first* selected item
            ; is first in the style. Also, if items of the same type
            ; are selected, the first one wins.
            oSel = REVERSE(oSel)
        endif else begin
            ; If nothing selected, retrieve the first Visualization Layer.
            oWin = oTool->GetCurrentWindow()
            if (~OBJ_VALID(oWin)) then $
                return, OBJ_NEW()
            oView = oWin->GetCurrentView()
            if (~OBJ_VALID(oView)) then $
                return, OBJ_NEW()
            oSel = oView->Get(ISA='IDLitgrLayer', COUNT=nsel)
        endelse

    endelse


    ; Filter out undesirable items.
    good = WHERE(~OBJ_ISA(oSel, 'IDLitvisDataSpaceRoot') and $
        ~OBJ_ISA(oSel, 'IDLitvisDataAxes'), ngood)
    if (~ngood) then $
        return, OBJ_NEW()
    oSel = oSel[good]

    ; Make any other changes.
    for i=0,ngood-1 do begin
        ; If a legend item, find our parent legend.
        if (OBJ_ISA(oSel[i], 'IDLitVisLegendItem')) then begin
            oSel[i]->IDLitComponent::GetProperty, _PARENT=oParent
            while OBJ_VALID(oParent) && $
                ~OBJ_ISA(oParent, 'IDLitVisLegend') do begin
                oParent[0]->IDLitComponent::GetProperty, _PARENT=oParent
            endwhile
            oSel[i] = oParent
        endif
    endfor


    for i=0,ngood-1 do begin
        if (~OBJ_VALID(oSel[i])) then $
            continue

        ; Register our new style item for this visualization.
        ; Use our identifier as the new style item name.
        oSel[i]->IDLitComponent::GetProperty, IDENTIFIER=id, $
            DESCRIPTION=description, ICON=icon
        ; Create a pretty name from the ID.
        ; Remove trailing digits and underscores,
        ; which are only used to create distinct identifiers.
        trailing = STREGEX(id, '_*[0-9]+$')
        if (trailing gt 0) then $
            id = STRMID(id, 0, trailing)


        ; For the first item, create the folder.
        if (N_ELEMENTS(alreadyCreated) eq 0) then begin
            oService->CreateStyle, self._text
            alreadyCreated = id
        endif else begin
            ; Otherwise, for the remaining items, make sure we don't
            ; already have this item.
            if (MAX(STRCMP(alreadyCreated, id)) eq 1) then $
                continue
            alreadyCreated = [alreadyCreated, id]
        endelse


        ; Retrieve from either the visualizations or annotations.
        oVisDesc = oTool->GetVisualization(id)
        if (~OBJ_VALID(oVisDesc)) then $
            oVisDesc = oTool->GetAnnotation(id)
        if (~OBJ_VALID(oVisDesc)) then $
            continue

        ; Change all words to mixed case.
        name = STRSPLIT(id, ' ', /EXTRACT)
        for j=0,N_ELEMENTS(name)-1 do begin
            name[j] = STRUPCASE(STRMID(name[j],0,1)) + $
                STRLOWCASE(STRMID(name[j],1))
        endfor
        name = STRJOIN(name, ' ')
        oService->RegisterStyleItem, name, OBJ_CLASS(oSel[i]), $
            DESCRIPTION=description, ICON=icon, $
            IDENTIFIER=self._text + '/' + name
        ; Copy all the properties from our selected viz over
        ; to the new style item.
        oStyleItem = oSys->GetByIdentifier('/Registry/Styles/My Styles/' + $
            self._text + '/' + name)
        oStyleItem->RecordProperties, oVisDesc, /SKIP_HIDDEN
        oStyleItem->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], /HIDE

        idProps = oStyleItem->QueryProperty()
        for j=2,N_ELEMENTS(idProps)-1 do begin
            ; Record the current value
            if (oSel[i]->GetPropertybyIdentifier(idProps[j], value)) then $
                oStyleItem->SetPropertyByIdentifier, idProps[j], Value
        endfor


    endfor

    oStyle = oService->Get(self._text)
    if (~OBJ_VALID(oStyle)) then $
        return, OBJ_NEW()

    oService->SaveStyle, self._text

    ; Fire up the style editor. It's nonmodal so we return immediately.
    void = oTool->DoUIService('/StyleEditor', self)

    return, OBJ_NEW()

end


;-------------------------------------------------------------------------
pro IDLitopStyleCreate__define

    compile_opt idl2, hidden

    struc = {IDLitopStyleCreate,     $
             inherits IDLitopStyleApply, $
             _createAll: 0b, $
             _text: '' }
end

