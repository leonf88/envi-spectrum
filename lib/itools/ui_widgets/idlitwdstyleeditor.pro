; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdstyleeditor.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdStyleEditor
;
; PURPOSE:
;   This function implements the iTools Style/Macro editor.
;
; CALLING SEQUENCE:
;   IDLitwdStyleEditor
;
; INPUTS:
;   oUI: (required) object reference for the tool user interface
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2003
;
;-


;-------------------------------------------------------------------------
pro IDLitwdStyleEditor_callback, wBase, strID, messageIn, userdata, $
    IGNORE_MAP=ignoreMap

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return
    WIDGET_CONTROL, wBase, GET_UVALUE=pState

    switch messageIn of

; Don't need to do anything.
;    'ADDITEMS':
;    'MOVEITEMS':
;    'REMOVEITEMS': begin
;        break
;        end

    'FOCUS_LOSS':  ; fall thru
    'FOCUS_GAIN': begin
        if (~KEYWORD_SET(ignoreMap) && ~WIDGET_INFO(wBase, /MAP)) then $
            break
        oSys = (*pState).oUI->GetTool()
        oTool = oSys->_GetCurrentTool()
        ; Compare the objrefs instead of the identifiers, because a new
        ; tool may have the same id as a just-deleted old tool.
        if ((*pState).oTool ne oTool) then begin

            idTool = OBJ_VALID(oTool) ? oTool->GetFullIdentifier() : ''

            ; Remove the old current style.
            if ((*pState).idTool ne '') then begin
                ; This is a little dangerous, but we directly access the tree
                ; widget for the current tool style and destroy it. This should
                ; probably be moved into a new procedure in cw_ittreeview.
                wID = WIDGET_INFO((*pState).wTree, $
                    FIND_BY_UNAME=(*pState).idTool + '/CURRENT STYLE')
                if (wID ne 0) then $
                    WIDGET_CONTROL, wID, /DESTROY
            endif
            ; Add the new current style.
            if (OBJ_VALID(oTool)) then begin
                oItem = oTool->GetByIdentifier('Current Style')
                ; For now, do not use notifications. This makes it easier
                ; to delete the current tool style.
                CW_ITTREEVIEW_AddLevel, (*pState).wTree, oItem, $
                    (*pState).wTree, $
                    /NO_NOTIFY
                cw_ittreeview_setSelect, (*pState).wTree, $
                    oItem->GetFullIdentifier()
                WIDGET_CONTROL, (*pState).wProp, $
                    SET_VALUE=oItem->GetFullIdentifier()
                IDLitwdStyleEditor_EnableTree, pState
            endif

            (*pState).idTool = idTool
            (*pState).oTool = oTool
        endif
        IDLitwdStyleEditor_callback, wBase, $
            '', 'SELECTIONCHANGED', '', /IGNORE_MAP
        break
        end

    'SELECTIONCHANGED': begin
        if (~KEYWORD_SET(ignoreMap) && ~WIDGET_INFO(wBase, /MAP)) then $
            break
        oSys = (*pState).oUI->GetTool()
        oTool = oSys->_GetCurrentTool()
        ; If we have a valid window, then assume we have something
        ; (at least a view) selected.
        hasWindow = 0
        if (OBJ_VALID(oTool)) then $
            hasWindow = OBJ_VALID(oTool->GetCurrentWindow())
        (*pState).haveVisSelection = hasWindow
        IDLitwdStyleEditor_EnableTree, pState
        break
        end

    'SENSITIVE': begin
        WIDGET_CONTROL, wBase, SENSITIVE=userdata
    end
    else: ; print, messageIn

    endswitch

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_CopyTree, pState, CUT=cut

    compile_opt idl2, hidden

    WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel

    ; Destroy previous clipboard item.
    if ((*pState).wasCut) then $
        OBJ_DESTROY, (*pState).oCopied

    ; Clear out property list since we copied an entire item.
    *(*pState).pProperties = ''

    (*pState).wasCut = KEYWORD_SET(cut)  ; need to destroy later

    if (idSel eq '') then $
        return

    oSys = (*pState).oUI->GetTool()
    oCopied = oSys->GetByIdentifier(idSel)

    ; New clipboard item.
    (*pState).oCopied = oCopied

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_Paste, pState

    compile_opt idl2, hidden

    if (~OBJ_VALID((*pState).oCopied)) then $
        return

    WIDGET_CONTROL, /HOURGLASS

    oSys = (*pState).oUI->GetTool()

    oService = oSys->GetService('STYLES')

    ; Which container are we pasting into?
    WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idDestination
    oDestination = oSys->GetByIdentifier(idDestination)
    ; If my destination is just an item within the tree,
    ; then retrieve my parent container instead.
    if (OBJ_ISA(oDestination, 'IDLitObjDesc')) then begin
        void = IDLitBasename(idDestination[0], $
            REMAINDER=idDestination)
    endif

    ; If we are pasting a container, just duplicate it.
    if (OBJ_ISA((*pState).oCopied, 'IDLitContainer')) then begin
        (*pState).oCopied->IDLitComponent::GetProperty, NAME=styleName
        oService->Duplicate, styleName
    endif else begin
        if ((*(*pState).pProperties)[0] ne '') then $
            properties = *(*pState).pProperties
        oService->PasteItem, (*pState).oCopied, idDestination, $
            PROPERTIES=properties
        WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idProp
        WIDGET_CONTROL, (*pState).wProp, SET_VALUE=''
        WIDGET_CONTROL, (*pState).wProp, SET_VALUE=idProp
    endelse

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_CopyProp, pState

    compile_opt idl2, hidden

    nsel = WIDGET_INFO((*pState).wProp, $
        /PROPERTYSHEET_NSELECTED)
    if (~nsel) then $
        return

    WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel

    oSys = (*pState).oUI->GetTool()
    oItem = oSys->GetByIdentifier(idSel)
    ; Sanity check.
    if (~OBJ_ISA(oItem, 'IDLitObjDesc')) then $
        return

    ; Destroy previous clipboard item.
    if ((*pState).wasCut) then $
        OBJ_DESTROY, (*pState).oCopied

    (*pState).wasCut = 0  ; do not destroy our object
    (*pState).oCopied = oItem

    props = WIDGET_INFO((*pState).wProp, $
        /PROPERTYSHEET_SELECTED)

    ; New clipboard item.
    *(*pState).pProperties = props

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_DeleteProp, pState

    compile_opt idl2, hidden

    nsel = WIDGET_INFO((*pState).wProp, $
        /PROPERTYSHEET_NSELECTED)
    if (~nsel) then $
        return

    WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel

    oSys = (*pState).oUI->GetTool()
    oItem = oSys->GetByIdentifier(idSel)
    ; Sanity check.
    if (~OBJ_ISA(oItem, 'IDLitObjDesc')) then $
        return

    props = WIDGET_INFO((*pState).wProp, $
        /PROPERTYSHEET_SELECTED)

    oItem->SetPropertyAttribute, props, /HIDE
    WIDGET_CONTROL, (*pState).wProp, /REFRESH

end


;------------------------------------------------------------------------
; Called when the state of the isChanged flag changes.
;
pro IDLitwdStyleEditor_SetChanged, pState, isChanged

    compile_opt idl2, hidden

    if (isChanged ne (*pState).isChanged) then begin
        (*pState).isChanged = isChanged
        WIDGET_CONTROL, (*pState).wSave, SENSITIVE=isChanged
    endif

end


;------------------------------------------------------------------------
; Called when either the Save button or the "X" close button is
; pressed (and save is chosen). Saves the styles.
;
pro IDLitwdStyleEditor_Save, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, /HOURGLASS
    oSys = (*pState).oUI->GetTool()
    oService = oSys->GetService('STYLES')
    oService->SaveAll
    IDLitwdStyleEditor_SetChanged, pState, 0

end


;------------------------------------------------------------------------
; Called when the "X" close button is pressed (and don't save is chosen).
; Restores styles to original state.
;
pro IDLitwdStyleEditor_Cancel, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, /HOURGLASS
    oSys = (*pState).oUI->GetTool()
    oService = oSys->GetService('STYLES')
    oService->RestoreAll
    IDLitwdStyleEditor_SetChanged, pState, 0

end


;------------------------------------------------------------------------
; Called when either the Close menu item or the "X" close button is
; pressed.
;
pro IDLitwdStyleEditor_Close, pState

    compile_opt idl2, hidden

    if ((*pState).isChanged) then begin
        result = DIALOG_MESSAGE(IDLitLangCatQuery('UI:wdStyleEdit:SaveChanges'), $
            /QUESTION, /CANCEL, $
            DIALOG_PARENT=(*pState).wTop, $
            TITLE=IDLitLangCatQuery('UI:wdStyleEdit:SaveChangesTitle'))
        if (result eq 'Cancel') then $
            return
        WIDGET_CONTROL, (*pState).wTop, MAP=0
        if (result eq 'Yes') then begin
            IDLitwdStyleEditor_Save, pState
        endif else begin
            IDLitwdStyleEditor_Cancel, pState
        endelse
    endif else begin
        ; Nothing changed. Just unmap.
        WIDGET_CONTROL, (*pState).wTop, MAP=0
    endelse

end


;------------------------------------------------------------------------
function IDLitwdStyleEditor_IsStyle, pState, $
    IS_ITEM=isItem, $
    IS_SYSTEMSTYLE=isSystemStyle, $
    IS_SYSTEMITEM=isSystemItem, $
    IS_USERFOLDER=isUserFolder, $
    IS_USERITEM=isUserItem, $
    IS_USERSTYLE=isUserStyle

    compile_opt idl2, hidden

    oSys = (*pState).oUI->GetTool()
    idToolStyle = (*pState).idTool + '/CURRENT STYLE'
    idSysStyle = '/REGISTRY/STYLES/SYSTEM STYLES'

    WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel

    isItem = 0b
    isSystemStyle = 0b
    isSystemItem = 0b
    isUserStyle = 0b
    isUserItem = 0b
    isUserFolder = (idSel eq '/REGISTRY/STYLES/MY STYLES')

    if isUserFolder then $
        return, 0

    ; Is this actually the current tool style?
    if (STRCMP(idSel, idToolStyle, /FOLD_CASE)) then $
        return, 1    ; is a style

    oItem = oSys->GetByIdentifier(idSel)
    isItem = OBJ_ISA(oItem, 'IDLitObjDesc')

    if (isItem) then begin
        isSystemItem = STRCMP(idSel, idSysStyle, STRLEN(idSysStyle))
        isUserItem = ~isSystemItem && $
            ~STRCMP(idSel, idToolStyle, STRLEN(idToolStyle))
        return, 0    ; is not a style
    endif

    ; Now see if we actually have a system or user style.
    oService = oSys->GetService('STYLES')
    oStyles = oService->Get(/ALL, COUNT=nstyles)
    isStyle = 0b

    for i=0,nstyles-1 do begin
        if STRCMP(idSel, oStyles[i]->GetFullIdentifier(), /FOLD_CASE) then begin
            isStyle = 1b
            isSystemStyle = STRCMP(idSel, idSysStyle, STRLEN(idSysStyle))
            isUserStyle = ~isSystemStyle
            break
        endif
    endfor

    return, isStyle

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_EnableTree, pState, CONTEXT=context

    compile_opt idl2, hidden

    context = KEYWORD_SET(context)

    ; Needed to determine whether the tree or the propsheet was most
    ; recently selected when an Edit menu item (like Cut) is chosen.
    (*pState).treeSelect = 1b

    oSys = (*pState).oUI->GetTool()
    hasTool = OBJ_VALID(oSys->_GetCurrentTool())

    isStyle = IDLitwdStyleEditor_IsStyle(pState, $
        IS_ITEM=isItem, $
        IS_SYSTEMSTYLE=isSystemStyle, $
        IS_SYSTEMITEM=isSystemItem, $
        IS_USERFOLDER=isUserFolder, $
        IS_USERSTYLE=isUserStyle, $
        IS_USERITEM=isUserItem)

    isUserStyleOrItem = isUserStyle || isUserItem
    paste = OBJ_VALID((*pState).oCopied) && $
        (isUserStyleOrItem || isUserFolder)
    updateCurrent = hasTool && (isUserStyle || isSystemStyle)

    if (KEYWORD_SET(context)) then begin
        WIDGET_CONTROL, (*pState).wContextCut, $
            SENSITIVE=isUserItem
        WIDGET_CONTROL, (*pState).wContextCopy, $
            SENSITIVE=isStyle || isItem
        WIDGET_CONTROL, (*pState).wContextPaste, $
            SENSITIVE=paste
        WIDGET_CONTROL, (*pState).wContextDelete, $
            SENSITIVE=isUserStyleOrItem

        WIDGET_CONTROL, (*pState).wContextDuplicate, $
            SENSITIVE=isStyle ; not isItem

        WIDGET_CONTROL, (*pState).wContextApplyStyleSelected, $
            SENSITIVE=isStyle && (*pState).haveVisSelection

        WIDGET_CONTROL, (*pState).wContextApplyStyleAll, $
            SENSITIVE=isStyle && hasTool

        WIDGET_CONTROL, (*pState).wContextUpdateCurrentStyle, $
            SENSITIVE=updateCurrent

    endif else begin

        WIDGET_CONTROL, (*pState).wExport, $
            SENSITIVE=isStyle

        WIDGET_CONTROL, (*pState).wEditCut, $
            SENSITIVE=isUserItem
        WIDGET_CONTROL, (*pState).wEditCopy, $
            SENSITIVE=isStyle || isItem
        WIDGET_CONTROL, (*pState).wEditPaste, $
            SENSITIVE=paste
        WIDGET_CONTROL, (*pState).wEditDelete, $
            SENSITIVE=isUserStyleOrItem

        WIDGET_CONTROL, (*pState).wEditDuplicate, $
            SENSITIVE=isStyle ; not isItem

        WIDGET_CONTROL, (*pState).wApplyStyleSelected, $
            SENSITIVE=isStyle && (*pState).haveVisSelection

        WIDGET_CONTROL, (*pState).wApplyStyleAll, $
            SENSITIVE=isStyle && hasTool

        WIDGET_CONTROL, (*pState).wUpdateCurrentStyle, $
            SENSITIVE=updateCurrent

    endelse

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_EnableProp, pState, CONTEXT=context

    compile_opt idl2, hidden

    context = KEYWORD_SET(context)

    ; Needed to determine whether the tree or the propsheet was most
    ; recently selected when an Edit menu item (like Cut) is chosen.
    (*pState).treeSelect = 0b

    nsel = WIDGET_INFO((*pState).wProp, /PROPERTYSHEET_NSELECTED)

    oSys = (*pState).oUI->GetTool()
    hasTool = OBJ_VALID(oSys->_GetCurrentTool())

    isStyle = IDLitwdStyleEditor_IsStyle(pState, $
        IS_ITEM=isItem, $
        IS_USERFOLDER=isUserFolder, $
        IS_USERSTYLE=isUserStyle, $
        IS_USERITEM=isUserItem)

    paste = OBJ_VALID((*pState).oCopied) && $
        (isUserStyle || isUserItem || isUserFolder)

    if (KEYWORD_SET(context)) then begin

        WIDGET_CONTROL, (*pState).wContextPropCut, $
            SENSITIVE=isUserItem && nsel
        WIDGET_CONTROL, (*pState).wContextPropCopy, $
            SENSITIVE=isItem && nsel
        WIDGET_CONTROL, (*pState).wContextPropPaste, $
            SENSITIVE=paste
        WIDGET_CONTROL, (*pState).wContextPropDelete, $
            SENSITIVE=isUserItem && nsel

    endif else begin

        WIDGET_CONTROL, (*pState).wEditCut, $
            SENSITIVE=isUserItem && nsel
        WIDGET_CONTROL, (*pState).wEditCopy, $
            SENSITIVE=isItem && nsel
        WIDGET_CONTROL, (*pState).wEditPaste, $
            SENSITIVE=paste
        WIDGET_CONTROL, (*pState).wEditDelete, $
            SENSITIVE=isUserItem && nsel

        ; Desensitize all other main menu items.
        WIDGET_CONTROL, (*pState).wExport, $
            SENSITIVE=0
        WIDGET_CONTROL, (*pState).wEditDuplicate, $
            SENSITIVE=0
        WIDGET_CONTROL, (*pState).wApplyStyleSelected, $
            SENSITIVE=0
        WIDGET_CONTROL, (*pState).wApplyStyleAll, $
            SENSITIVE=0
        WIDGET_CONTROL, (*pState).wUpdateCurrentStyle, $
            SENSITIVE=0

    endelse

end


;------------------------------------------------------------------------
pro IDLitwdStyleEditor_buttonevent, event

    compile_opt idl2, hidden

    ON_ERROR, 2
    WIDGET_CONTROL,event.top, GET_UVALUE=pState
    button = WIDGET_INFO(event.id, /UNAME)
    oSys = (*pState).oUI->GetTool()

    switch button of

        ; For the context menus we can distinguish between the tree
        ; or the prop sheet. For the main menu Edit items we can't.
        ; So just handle all menu items in one case, and use our
        ; treeSelect state to distinguish.

        'ContextPropCut': ; fall thru
        'ContextCut': ; fall thru
        'EditCut': begin
            if ((*pState).treeSelect) then begin
                WIDGET_CONTROL, /HOURGLASS
                IDLitwdStyleEditor_CopyTree, pState, /CUT
                if (~OBJ_VALID((*pState).oCopied)) then $
                    break
                ; Remove object from system and notify.
                idSelect = (*pState).oCopied->GetFullIdentifier()
                (*pState).oCopied->GetProperty, _PARENT=oParent
                oItem = oSys->RemoveByIdentifier(idSelect)
                if (OBJ_VALID(oParent)) then begin
                    oSys->DoOnNotify, oParent->GetFullIdentifier(), $
                        "REMOVEITEMS", idSelect
                endif
            endif else begin    ; propsheet selection
                IDLitwdStyleEditor_CopyProp, pState
                IDLitwdStyleEditor_DeleteProp, pState
            endelse
            IDLitwdStyleEditor_SetChanged, pState, 1
            break
            end

        'ContextPropCopy': ; fall thru
        'ContextCopy': ; fall thru
        'EditCopy': begin
            if ((*pState).treeSelect) then begin
                IDLitwdStyleEditor_CopyTree, pState
            endif else begin    ; propsheet selection
                IDLitwdStyleEditor_CopyProp, pState
            endelse
            break
            end

        'ContextPropPaste': ; fall thru
        'ContextPaste': ; fall thru
        'EditPaste': begin
            IDLitwdStyleEditor_Paste, pState
            IDLitwdStyleEditor_SetChanged, pState, 1
            break
            end


        'ContextPropDelete': ; fall thru
        'ContextDelete': ; fall thru
        'EditDelete': begin
            if ((*pState).treeSelect) then begin
                WIDGET_CONTROL, /HOURGLASS
                WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idDelete
                ; Rather than using oSys->Unregister (which also deletes
                ; the parent if empty) we manually remove & delete the item.
                oItem = oSys->GetByIdentifier(idDelete)
                if (~OBJ_VALID(oItem)) then $
                    break
                oItem->GetProperty, _PARENT=oParent
                oItem = oSys->RemoveByIdentifier(idDelete)
                ; Send the remove message
                if (OBJ_VALID(oParent)) then begin
                    oSys->DoOnNotify, oParent->GetFullIdentifier(), $
                        "REMOVEITEMS", idDelete
                endif
                OBJ_DESTROY, oItem
            endif else begin    ; propsheet selection
                IDLitwdStyleEditor_DeleteProp, pState
            endelse
            IDLitwdStyleEditor_SetChanged, pState, 1
            break
            end


        'ContextDuplicate': ; fall thru
        'EditDuplicate': begin
            WIDGET_CONTROL, /HOURGLASS
            WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idDuplicate
            oDuplicate = oSys->GetByIdentifier(idDuplicate)
            oService = oSys->GetService('STYLES')
            ; Duplicate entire container.
            if (OBJ_ISA(oDuplicate, 'IDLitContainer')) then begin
                oDuplicate->IDLitComponent::GetProperty, NAME=styleName
                oService->Duplicate, styleName
            endif else begin  ; Duplicate an item.
                ; Retrieve my parent container.
                void = IDLitBasename(idDuplicate, $
                    REMAINDER=idDestination)
                oService->PasteItem, oDuplicate, idDestination
            endelse
            IDLitwdStyleEditor_SetChanged, pState, 1
            break
            end

        'ContextUpdateCurrentStyle': ; fall thru
        'UpdateCurrentStyle': begin
            WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel
            oTool = oSys->_GetCurrentTool()
            if (~OBJ_VALID(oTool)) then $
                break
            oStyle = oSys->GetByIdentifier(idSel)
            oStyle->IDLitComponent::GetProperty, NAME=styleName
            oDesc = oTool->GetByIdentifier('/Registry/Operations/Apply Style')
            oStyleOp = oDesc->GetObjectInstance()
            oStyleOp->GetProperty, SHOW_EXECUTION_UI=showUI
            oStyleOp->SetProperty, SHOW_EXECUTION_UI=0, $
                STYLE_NAME=styleName, APPLY=0, /UPDATE_CURRENT
            success = oTool->DoAction('/Registry/Operations/Apply Style')
            if (showUI) then $
                oStyleOp->SetProperty, /SHOW_EXECUTION_UI
            break
            end

        ; Share same code for Apply Selected/All.
        'ContextApplyStyleSelected': ; fall thru
        'ApplyStyleSelected': ; fall thru
        'ContextApplyStyleAll': ; fall thru
        'ApplyStyleAll': begin
            WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel
            oTool = oSys->_GetCurrentTool()
            if (~OBJ_VALID(oTool)) then $
                break
            oStyle = oSys->GetByIdentifier(idSel)
            oStyle->IDLitComponent::GetProperty, NAME=styleName
            applySelected = (button eq 'ContextApplyStyleSelected') || $
                (button eq 'ApplyStyleSelected')
            oDesc = oTool->GetByIdentifier('/Registry/Operations/Apply Style')
            oStyleOp = oDesc->GetObjectInstance()
            oStyleOp->GetProperty, SHOW_EXECUTION_UI=showUI
            oStyleOp->SetProperty, SHOW_EXECUTION_UI=0, $
                STYLE_NAME=styleName, $
                APPLY=applySelected ? 1 : 2, $
                UPDATE_CURRENT=0
            success = oTool->DoAction('/Registry/Operations/Apply Style')
            if (showUI) then $
                oStyleOp->SetProperty, /SHOW_EXECUTION_UI
            break
            end


        'Save': begin
            IDLitwdStyleEditor_Save, pState
            break
            end

        'Close': begin
            IDLitwdStyleEditor_Close, pState
            break
            end

        'Help': begin
            oHelp = oSys->GetService('HELP')
            if (~oHelp) then $
                break
            oHelp->HelpTopic, oSys, 'iToolsStyleEditor'
            break
            end

        'New': begin
            oService = oSys->GetService('STYLES')
            newstylename = oService->_NewStyleName('New Style')
            oService->CreateStyle, newstylename
            IDLitwdStyleEditor_SetChanged, pState, 1
            break
            end

        'Import': begin
            oService = oSys->GetService('STYLES')
            oTool = oSys->_GetCurrentTool()
            if (OBJ_VALID(oTool)) then $
                oTool->GetProperty, WORKING_DIRECTORY=workingDir
            filename = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
                FILTER=[['*.sav','*'], $
                    ['iTools Style file (*.sav)', $
                    'All files (*)']], $
                /MULTIPLE_FILES, $
                /MUST_EXIST, $
                PATH=workingDir, $
                TITLE=IDLitLangCatQuery('UI:wdStyleEdit:Import'))
            if (filename[0] ne '') then begin
                WIDGET_CONTROL, /HOURGLASS
                oService->Import, filename
                IDLitwdStyleEditor_SetChanged, pState, 1
            endif
            break
            end

        'Export': begin
            oService = oSys->GetService('STYLES')
            oTool = oSys->_GetCurrentTool()
            if (OBJ_VALID(oTool)) then $
                oTool->GetProperty, WORKING_DIRECTORY=workingDir
            filename = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
                DEFAULT_EXTENSION='sav', $
                FILTER=[['*.sav','*'], $
                    ['iTools Style file (*.sav)', $
                    'All files (*)']], $
                /OVERWRITE_PROMPT, $
                PATH=workingDir, $
                TITLE=IDLitLangCatQuery('UI:wdStyleEdit:Export'), $
                /WRITE)
            if (filename[0] ne '') then begin
                WIDGET_CONTROL, /HOURGLASS
                WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel
                oStyle = oSys->GetByIdentifier(idSel)
                oStyle->IDLitComponent::GetProperty, NAME=styleName
                oService->SaveStyle, styleName, FILENAME=filename
            endif
            break
            end

        else: MESSAGE, IDLitLangCatQuery('UI:wdStyleEdit:BadButton') + button

    endswitch

end


;------------------------------------------------------------------------
; Handle resize events for left-hand side. Called from CW_PANES.
;
pro IDLitwdStyleEditor_leftevent, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState
    event.id = (*pState).wTree
    void = CW_ITTREEVIEW_EVENT(event)
end


;------------------------------------------------------------------------
; Handle resize events for right-hand side. Called from CW_PANES.
;
pro IDLitwdStyleEditor_rightevent, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState
    event.id = (*pState).wProp
    void = CW_ITPROPERTYSHEET_EVENT(event)

end


;------------------------------------------------------------------------
; PURPOSE:
;       Event handler for the browser
;
; INPUTS:
;   EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;
pro IDLitwdStyleEditor_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL,event.top, GET_UVALUE=pState

    oSys = (*pState).oUI->GetTool()

    case TAG_NAMES(event, /STRUCTURE_NAME) of

    'WIDGET_BASE': begin        ; Resize
          newX = event.x > 200
          deltaX = newX - (*pState).x
          newY = event.y > 100
          deltaY = newY - (*pState).y
          if deltaX ne 0 then begin
            ; Do a fake resize to avoid Motif weirdness.
            WIDGET_CONTROL,event.top,xsize=newX + 1
            (*pState).x = newX
            WIDGET_CONTROL,event.top,xsize=newX
          endif
          if deltaY ne 0 then begin
            ; Do a fake resize to avoid Motif weirdness.
            WIDGET_CONTROL,event.top,ysize=newY + 1
            (*pState).y = newY
            WIDGET_CONTROL,event.top,ysize=newY
          endif
          evstruct = {CW_PANES_RESIZE, ID:(*pState).wPanes, TOP:event.top, $
                      HANDLER:event.id, deltaX:deltaX, deltaY:deltaY}
          void = CW_PANES_EVENT(evstruct)
        end

    ; Event from the treeview compound widget.
    'CW_TREE_SEL': begin
        WIDGET_CONTROL, (*pState).wProp, SET_VALUE=event.selected
        IDLitwdStyleEditor_EnableTree, pState
        end


    'WIDGET_PROPSHEET_CHANGE': begin   ; CHANGE_EVENTS
        WIDGET_CONTROL, (*pState).wProp, GET_VALUE=idSel
        ; If we changed a property on the current style, don't mark
        ; as changed (it's not undoable). Otherwise, mark state changed.
        if (STRPOS(idSel, '/CURRENT STYLE') eq -1) then $
            IDLitwdStyleEditor_SetChanged, pState, 1
        end

    'WIDGET_PROPSHEET_SELECT': begin
        IDLitwdStyleEditor_EnableProp, pState
        end


    ; We don't die, we hide
    'WIDGET_KILL_REQUEST' : begin
        IDLitwdStyleEditor_Close, pState
        end

    'WIDGET_CONTEXT': begin
        if (event.id eq (*pState).wTree) then begin
            IDLitwdStyleEditor_EnableTree, pState, /CONTEXT
            wContext = (*pState).wContextTree
        endif else begin
            IDLitwdStyleEditor_EnableProp, pState, /CONTEXT
            wContext = (*pState).wContextProp
        endelse
        WIDGET_DISPLAYCONTEXTMENU, event.id, $
            event.x, event.y, wContext
        end

    else:

    endcase

end


;-------------------------------------------------------------------------
pro IDLitwdStyleEditor_killnotify, wTLB

    compile_opt idl2, hidden

    WIDGET_CONTROL, wTLB, GET_UVALUE=pState

    ; Destroy old clipboard item.
    if ((*pState).wasCut) then $
        OBJ_DESTROY, (*pState).oCopied

    PTR_FREE, (*pState).pProperties
    PTR_FREE, pState

end


;----------------------------------------
; PURPOSE:
;       Put the cw_ittreeview in the left panel
;
; INPUTS:
;       BASE: (required) widget ID of the left base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;
PRO IDLitwdStyleEditor_createtreeview, base

    compile_opt idl2, hidden

    topid = base
    WHILE ((temp=widget_info(topid,/parent))) ne 0l DO topid=temp
    WIDGET_CONTROL,topid,GET_UVALUE=pState

    oSys = (*pState).oUI->GetTool()
    oItem = oSys->GetByIdentifier('/Registry/Styles/My Styles')
    if (~OBJ_VALID(oItem)) then $
        oSys->CreateFolders, "Registry/Styles/My Styles"


    (*pState).wTree = CW_ITTREEVIEW(base, (*pState).oUI, $
        /CONTEXT_EVENTS, $
        IDENTIFIER='/Registry/Styles/My Styles', $
        MULTIPLE=0, $
        XSIZE=(*pState).leftsize, $
        YSIZE=(*pState).ysize, $
        UNAME='StyleDst')

    oItem = oSys->GetByIdentifier('/Registry/Styles/System Styles')
    CW_ITTREEVIEW_AddLevel, (*pState).wTree, oItem, $
        (*pState).wTree, $
        /NO_NOTIFY

    ; Context menu.
    wContext = WIDGET_BASE(topid, /CONTEXT_MENU, $
        event_pro='IDLitwdStyleEditor_buttonevent')
    (*pState).wContextTree = wContext

    (*pState).wContextCut = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Cut'), $
        UNAME='ContextCut')
    (*pState).wContextCopy = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Copy'), $
        UNAME='ContextCopy')
    (*pState).wContextPaste = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Paste'), $
        UNAME='ContextPaste', SENSITIVE=0)
    (*pState).wContextDelete = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Delete'), $
        UNAME='ContextDelete', /SEPARATOR)
    (*pState).wContextDuplicate = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Dup'), $
        UNAME='ContextDuplicate')

    (*pState).wContextApplyStyleSelected = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:ApplySelected'), $
        UNAME='ContextApplyStyleSelected', /SEPARATOR)
    (*pState).wContextApplyStyleAll = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:ApplyView'), $
        UNAME='ContextApplyStyleAll')
    (*pState).wContextUpdateCurrentStyle = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:UpdateCurrent'), $
        UNAME='ContextUpdateCurrentStyle')

end


;----------------------------------------
; PURPOSE:
;       Put the cw_itpropertysheet in the right panel
;
; INPUTS:
;       BASE: (required) widget ID of the left base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;
PRO IDLitwdStyleEditor_createpropsheet, base

    compile_opt idl2, hidden

    topid = base
    WHILE ((temp=widget_info(topid,/parent))) ne 0l DO topid=temp
    WIDGET_CONTROL,topid,GET_UVALUE=pState

    ; Set the first item to be selected.
    (*pState).wProp = CW_ITPROPERTYSHEET(base, (*pState).oUI, $
        scr_xsize=(*pState).rightsize, $
        scr_ysize=(*pState).ysize, $
        COMMIT=0, $ ; commit mode on the propsheet
        /CHANGE_EVENTS, $
        /CONTEXT_EVENTS, $
        /HIDE_USERDEF, $ ; passed directly to widget_propertysheet
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /MULTIPLE, $
        /SUNKEN_FRAME)

    ; Context menu.
    wContext = WIDGET_BASE(topid, /CONTEXT_MENU, $
        event_pro='IDLitwdStyleEditor_buttonevent')
    (*pState).wContextProp = wContext

    (*pState).wContextPropCut = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Cut'), $
        UNAME='ContextPropCut')
    (*pState).wContextPropCopy = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Copy'), $
        UNAME='ContextPropCopy')
    (*pState).wContextPropPaste = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Paste'), $
        UNAME='ContextPropPaste', SENSITIVE=0)
    (*pState).wContextPropDelete = WIDGET_BUTTON(wContext, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Delete'), $
        UNAME='ContextPropDelete', /SEPARATOR)

end


;-------------------------------------------------------------------------
pro IDLitwdStyleEditor, oUI, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_PARAMS() ne 1) then $
        MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

    regName = 'StyleEditor'
    widname = 'IDLitwdStyleEditor'

    ; Has this already been registered and is up and running?
    wID = oUI->GetWidgetByName(regName)

    oSys = oUI->GetTool()

    if (WIDGET_INFO(wID, /VALID)) then begin
        WIDGET_CONTROL, wID, GET_UVALUE=pState
        ; Make sure the tree displays the current tool items.
        IDLitwdStyleEditor_callback, wID, '', 'FOCUS_GAIN', '', /IGNORE_MAP
        WIDGET_CONTROL, wID, /MAP, ICONIFY=0
        return
    end


    pState = PTR_NEW( $
        {oUI: oUI, $
        wTop: 0L, $
        wPanes: 0L, $
        wTree: 0L, $
        wProp: 0L, $
        wApply: 0L, $
        wSave: 0L, $
        wContextTree: 0L, $
        wContextProp: 0L, $
        wExport: 0L, $
        wEditCut: 0L, $
        wEditCopy: 0L, $
        wEditPaste: 0L, $
        wEditDelete: 0L, $
        wEditDuplicate: 0L, $
        wApplyStyleSelected: 0L, $
        wApplyStyleAll: 0L, $
        wUpdateCurrentStyle: 0L, $
        wContextCut: 0L, $
        wContextCopy: 0L, $
        wContextPaste: 0L, $
        wContextDelete: 0L, $
        wContextDuplicate: 0L, $
        wContextApplyStyleSelected: 0L, $
        wContextApplyStyleAll: 0L, $
        wContextUpdateCurrentStyle: 0L, $
        wContextPropCut: 0L, $
        wContextPropCopy: 0L, $
        wContextPropPaste: 0L, $
        wContextPropDelete: 0L, $
        haveVisSelection: 0b, $
        isChanged: 0b, $
        treeSelect: 1b, $
        leftsize: 250, $
        rightsize: 350, $
        ysize: 450, $
        x:0L, $
        y:0L, $
        idSelf:'', $
        idTool:'', $
        wasCut: 0b, $
        oTool: OBJ_NEW(), $
        oCopied: OBJ_NEW(), $
        pProperties: PTR_NEW('') $
        })

    ; Create top level base
    wTop = WIDGET_BASE(/COLUMN, $
        /TLB_SIZE_EVENTS, $
        KILL_NOTIFY='IDLitwdStyleEditor_killnotify', $
        MAP=0, $
        TITLE=IDLitLangCatQuery('UI:wdStyleEdit:Title'), $
        MBAR=wMenubar, $
        XPAD=1, YPAD=1, SPACE=0, $
        /TLB_KILL_REQUEST_EVENTS, $
        UVALUE=pState, $
        _EXTRA=_extra)
    (*pState).wTop = wTop
    WIDGET_CONTROL,wTop,/realize

    wFile = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:File'), $
        EVENT_PRO='IDLitwdStyleEditor_buttonevent')
    wEdit = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Edit'), $
        EVENT_PRO='IDLitwdStyleEditor_buttonevent')
    wApply = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Apply'), $
        EVENT_PRO='IDLitwdStyleEditor_buttonevent')
    wHelp = WIDGET_BUTTON(wMenubar, /MENU, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Help'), /HELP, $
        EVENT_PRO='IDLitwdStyleEditor_buttonevent')

    wNew = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:New'), $
        ACCELERATOR='Ctrl+N', $
        UNAME='New')

    wImport = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Import...'), $
        UNAME='Import')

    (*pState).wExport = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Export...'), $
        UNAME='Export')

    wHelpButton = WIDGET_BUTTON(wHelp, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Help'), $
        ACCELERATOR='F1', $
        UNAME='Help')


    (*pState).wSave = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Save'), $
        ACCELERATOR='Ctrl+S', $
        SENSITIVE=0, $
        UNAME='Save')
    wClose = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Close'), $
        ACCELERATOR='Ctrl+Q', $
        UNAME='Close', /SEPARATOR)


    ; Create panes
    (*pState).wPanes = CW_PANES(wTop, $
        MARGIN=20, $
        /NO_COLLAPSE, $
        left_xsize=(*pState).leftsize, $
        right_xsize=(*pState).rightsize, $
        left_ysize=(*pState).ysize, $
        right_ysize=(*pState).ysize, $
        left_create_pro='IDLitwdStyleEditor_createtreeview', $
        left_event_pro='IDLitwdStyleEditor_leftevent', $
        right_create_pro='IDLitwdStyleEditor_createpropsheet', $
        right_event_pro='IDLitwdStyleEditor_rightevent', $
        top_event_PRO='IDLitwdStyleEditor_event', $
        visible=3)



    (*pState).wEditCut = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Cut'), $
        ACCELERATOR='Ctrl+X', $
        UNAME='EditCut')
    (*pState).wEditCopy = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Copy'), $
        ACCELERATOR='Ctrl+C', $
        UNAME='EditCopy')
    (*pState).wEditPaste = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Paste'), $
        ACCELERATOR='Ctrl+V', $
        UNAME='EditPaste', SENSITIVE=0)
    (*pState).wEditDelete = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Delete'), $
        ACCELERATOR='Del', $
        UNAME='EditDelete', /SEPARATOR)
    (*pState).wEditDuplicate = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:Dup'), $
        UNAME='EditDuplicate')


    (*pState).wApplyStyleSelected = WIDGET_BUTTON(wApply, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:ApplySelected'), $
        UNAME='ApplyStyleSelected')
    (*pState).wApplyStyleAll = WIDGET_BUTTON(wApply, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:ApplyView'), $
        UNAME='ApplyStyleAll')
    (*pState).wUpdateCurrentStyle = WIDGET_BUTTON(wApply, $
        VALUE=IDLitLangCatQuery('UI:wdStyleEdit:UpdateCurrent'), $
        UNAME='UpdateCurrentStyle')


    ; Add our current tool items.
    IDLitwdStyleEditor_callback, wTop, '', 'FOCUS_GAIN', '', /IGNORE_MAP

    ; Add browser to the UI
    (*pState).idSelf = oUI->RegisterWidget(wTop, regName, $
        'IDLitwdStyleEditor_callback', $
        DESCRIPTION=Title, /FLOATING)

    ; Register for notification messages
    oUI->AddOnNotifyObserver, (*pState).idSelf, '/Registry/Styles'
    oUI->AddOnNotifyObserver, (*pState).idSelf, oSys->GetFullIdentifier()
    oUI->AddOnNotifyObserver, (*pState).idSelf, 'Visualization'

    WIDGET_CONTROL, wTop, /MAP

    ; Draw slider bars and arrows
    CW_PANES_DRAW_SLIDER_BAR, wTop

    ; Cache wTop size
    info = WIDGET_INFO(wTop, /GEOMETRY)
    (*pState).x = info.xsize
    (*pState).y = info.ysize

    WIDGET_CONTROL, wTop, /CLEAR_EVENTS

    XMANAGER, widname, wTop, /NO_BLOCK

end

