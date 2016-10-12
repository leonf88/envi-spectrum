; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdmacroeditor.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdMacroEditor
;
; PURPOSE:
;   This function implements the iTools Macro editor.
;
; CALLING SEQUENCE:
;   IDLitwdMacroEditor
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
pro IDLitwdMacroEditor_callback, wBase, strID, messageIn, userdata, $
    IGNORE_MAP=ignoreMap

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return
    WIDGET_CONTROL, wBase, GET_UVALUE=pState

    switch messageIn of

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

            ; Remove the old operations.
            if ((*pState).idTool ne '') then begin
                ; This is a little dangerous, but we directly access the tree
                ; widget for the current tool operations and destroy it. This should
                ; probably be moved into a new procedure in cw_ittreeview.
                ; FIND_BY_UNAME requires upper case identifier
                wID = WIDGET_INFO((*pState).wTreeSrc, $
                    FIND_BY_UNAME=(*pState).idTool + '/OPERATIONS')
                if (wID ne 0) then $
                    WIDGET_CONTROL, wID, /DESTROY
            endif
            ; Add the new operations.
            if (OBJ_VALID(oTool)) then begin
               (*pState).idTool = idTool
               oItem = oTool->GetByIdentifier((*pState).idTool + '/Operations')
                ; For now, do not use notifications. This makes it easier
                ; to delete the current tool operations.
                cw_ittreeview_addLevel, (*pState).wTreeSrc, oItem, $
                    (*pState).wTreeSrc, $
                    /NO_NOTIFY
                WIDGET_CONTROL, (*pState).wPropSrc, $
                    SET_VALUE=oItem->GetFullIdentifier()
            endif

            (*pState).idTool = idTool
            (*pState).oTool = oTool
        endif
        IDLitwdMacroEditor_callback, wBase, $
            '', 'SELECTIONCHANGED', '', /IGNORE_MAP
        break
        end
    'SENSITIVE': begin
            WIDGET_CONTROL, wBase, SENSITIVE=userdata
        end

    else:

    endswitch

end


;------------------------------------------------------------------------
pro IDLitwdMacroEditor_Copy, pState, CUT=cut

    compile_opt idl2, hidden

    ; Cut should only be allowed for destination tree, but make sure
    wTree = KEYWORD_SET(cut) ? (*pState).wTreeDst : (*pState).wLastTreeSelected
    idSel = cw_ittreeview_getSelect(wTree, COUNT=nSel)

    ; Destroy previous clipboard item.
    if ((*pState).wasCut) then begin
        OBJ_DESTROY, *((*pState).oCopied)
        ptr_free, (*pState).oCopied
    endif

    (*pState).wasCut = KEYWORD_SET(cut)  ; need to destroy later

    if (nSel eq 0) then $
        return

    oSys = (*pState).oUI->GetTool()
    for i=0, nSel-1 do begin
        oTemp = oSys->GetByIdentifier(idSel[i])
        oCopied = n_elements(oCopied) eq 0 ? oTemp : [oCopied, oTemp]
    endfor

    ; New clipboard item.
    (*pState).oCopied = PTR_NEW(oCopied)

end


;------------------------------------------------------------------------
pro IDLitwdMacroEditor_Paste, pState

    compile_opt idl2, hidden

    if ~ptr_valid((*pState).oCopied) then return

    WIDGET_CONTROL, /HOURGLASS

    oSys = (*pState).oUI->GetTool()

    oSrvMacros = oSys->GetService('MACROS')

    ; Which container are we pasting into?
    idDestination = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSel)
    if strupcase(idDestination) eq "/REGISTRY/MACROS"then begin
        ; upper level macros folder selected
        oSrvMacros->GetProperty, NEW_NAME=idDestination
    endif
    oDestination = oSys->GetByIdentifier(idDestination)

    oCopied = *((*pState).oCopied)

    ; If my destination is just an item within the tree,
    ; then retrieve my parent container instead.
    ; If the copied object is a macro folder, don't set position
    ; because we will have to create a new folder and add items
    ; The position of the destination item in its current folder
    ; is unusable.
    if (OBJ_ISA(oDestination, 'IDLitObjDesc') && $
        OBJ_VALID(oCopied[0]) && $
        ~OBJ_ISA(oCopied[0], "IDLitContainer"))then begin

        void = IDLitBasename(idDestination[0], $
            REMAINDER=idDestination)
        oDestination->GetProperty, _PARENT=oParent
        if oParent->IsContained(oDestination, POSITION=dstPos) then $
            newPos = dstPos + 1
    endif

    oTool = oSys->_GetCurrentTool()
    oDescInsertVis = obj_new()
    if obj_valid(oTool) then $
        oDescInsertVis = oTool->GetByIdentifier('Operations/Insert/Visualization')
    for i=0, n_elements(oCopied)-1 do begin
        if ~OBJ_VALID(oCopied[i]) then $
            continue

        idCopied = oCopied[i]->GetFullIdentifier()
        if (strpos(strupcase(idCopied), "/REGISTRY/VISUALIZATIONS") ge 0) || $
            (oCopied[i] eq oDescInsertVis) then begin

            if obj_valid(oDescInsertVis) then $
                oSrvMacros->PasteMacroOperation, oDescInsertVis, $
                    idDestination, idNewItem, $
                    ; newPos _may_ be defined if destination was a macro item
                    ; and we want to put the new item after the destination item
                    POSITION=newPos, $
                    /SHOW_EXECUTION_UI, /EDITOR
        endif else $
            oSrvMacros->Duplicate, oCopied[i], $
                idDestination, idNewItem, $
                ; newPos _may_ be defined if destination was a macro item
                ; and we want to put the new item after the destination item
                POSITION=newPos, $
                /EDITOR
    endfor

    ; select the last item added
    if n_elements(idNewItem) gt 0 then begin
        cw_ittreeview_setSelect, (*pState).wTreeDst, idNewItem, /CLEAR
        WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=idNewItem
    endif

end


;------------------------------------------------------------------------
; Called when the state of the isChanged flag changes.
;
pro IDLitwdMacroEditor_SetChanged, pState, isChanged

    compile_opt idl2, hidden

    (*pState).isChanged = isChanged
    WIDGET_CONTROL, (*pState).wSave, SENSITIVE=isChanged

end


;------------------------------------------------------------------------
; Called when either the Save button or the "X" close button is
; pressed (and save is chosen). Saves the macros.
;
pro IDLitwdMacroEditor_Save, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, /HOURGLASS
    ; Need to call property sheet routine here to flush values
    ; if user changed macro values but didn't change focus
    oSys = (*pState).oUI->GetTool()
    oSrvMacro = oSys->GetService('MACROS')
    oSrvMacro->SaveAllMacros
    IDLitwdMacroEditor_SetChanged, pState, 0

end

;------------------------------------------------------------------------
; Called when the "X" close button is pressed (and don't save is chosen).
; Restores macros to their previous state.
;
pro IDLitwdMacroEditor_cancel, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, /HOURGLASS
    oSys = (*pState).oUI->GetTool()
    oSrvMacros = oSys->GetService('MACROS')
    oSrvMacros->RestoreMacros
    IDLitwdMacroEditor_SetChanged, pState, 0
    WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=''
    WIDGET_CONTROL, (*pState).wPropDst, /REFRESH

end


;------------------------------------------------------------------------
; Called when either the Close menu item or the "X" close button is
; pressed.
;
pro IDLitwdMacroEditor_Close, pState

    compile_opt idl2, hidden

    if ((*pState).isChanged) then begin
        result = DIALOG_MESSAGE(IDLitLangCatQuery('UI:wdMacroEdit:SaveChanges'), $
            /QUESTION, /CANCEL, $
            DIALOG_PARENT=(*pState).wTop, $
            TITLE=IDLitLangCatQuery('UI:wdMacroEdit:Title2'))
        if (result eq 'Cancel') then $
            return
        WIDGET_CONTROL, (*pState).wTop, MAP=0
        if (result eq 'Yes') then begin
            IDLitwdMacroEditor_Save, pState
        endif else begin
            IDLitwdMacroEditor_Cancel, pState
        endelse
    endif else begin
        ; Nothing changed. Just unmap.
        WIDGET_CONTROL, (*pState).wTop, MAP=0
    endelse

end

pro IDLitwdMacroEditor_removeProperties, pState

    compile_opt idl2, hidden

    oSys = (*pState).oUI->GetTool()
    nsel = WIDGET_INFO((*pState).wPropDst, /PROPERTYSHEET_NSELECTED)
    if (nsel eq 0) then $
        return
    selected = WIDGET_INFO((*pState).wPropDst, $
        /PROPERTYSHEET_SELECTED)
    WIDGET_CONTROL, (*pState).wPropDst, GET_VALUE=idDstItem
    oDstItem = oSys->GetByIdentifier(idDstItem)
    oDstItem->SetPropertyAttribute, selected, /HIDE
    WIDGET_CONTROL, (*pState).wPropDst, /REFRESH

end

;------------------------------------------------------------------------
pro IDLitwdMacroEditor_buttonevent, event

    compile_opt idl2, hidden

    ON_ERROR, 2
    WIDGET_CONTROL,event.top, GET_UVALUE=pState
    button = WIDGET_INFO(event.id, /UNAME)
    oSys = (*pState).oUI->GetTool()

    switch button of

        'ContextCut': ; fall thru
        'EditCut': begin
            IDLitwdMacroEditor_Copy, pState, /CUT
            if ~ptr_valid((*pState).oCopied) then break
            oCopied = *((*pState).oCopied)
            for i=0, n_elements(oCopied)-1 do begin
                if ~OBJ_VALID(oCopied[i]) then $
                    continue
                ; Remove object from system and notify.
                idSelect = oCopied[i]->GetFullIdentifier()
                oCopied[i]->GetProperty, _PARENT=oParent
                void = oSys->RemoveByIdentifier(idSelect)
                if (OBJ_VALID(oParent)) then begin
                    oSys->DoOnNotify, oParent->GetFullIdentifier(), $
                        "REMOVEITEMS", idSelect
                endif
            endfor
            IDLitwdMacroEditor_SetChanged, pState, 1
            IDLitwdMacroEditor_EnableTree, pState
            break
            end

        'ContextCopy': ; fall thru
        'EditCopy': begin
            IDLitwdMacroEditor_Copy, pState
            break
            end

        'ContextPaste': ; fall thru
        'EditPaste': begin
            IDLitwdMacroEditor_Paste, pState
            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end


        'ContextDelete': ; fall thru
        'EditDelete': begin
            WIDGET_CONTROL, /HOURGLASS
            ; Only allowed if wTreeDst selected
            if (*pState).wLastDestSelected eq (*pState).wTreeDst then begin
                idDelete = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSel)

                ; don't use unregister, it deletes folder if empty
                ; oSys->Unregister, idDelete
                for i=0, nSel-1 do begin
                    oDelete = oSys->GetByIdentifier(idDelete[i])
                    ; object could be invalid - folder could be deleted
                    ; prior to object in folder due to order of selection
                    if obj_valid(oDelete) then begin
                        oDelete->GetProperty, _PARENT=oParent
                        if OBJ_VALID(oParent) then begin
                            ; get new selection target
                            isCont = oParent->IDL_Container::IsContained(oDelete, POSITION=position)
                            count = oParent->Count()
                            ; if not last item, skip past deleted
                            ; if last item, go to prior item
                            ; if last item in container go to parent
                            newPos = (position le count-2) ? position+1 : position-1
                            oNewSel = (newPos lt 0) ? oParent : oParent->Get(POSITION=newPos)
                            idNewSel = oNewSel->GetFullIdentifier()

                            void = oSys->RemoveByIdentifier(idDelete[i])
                            ; items could have different parents so do this in loop
                            oSys->DoOnNotify, oParent->GetFullIdentifier(), $
                                "REMOVEITEMS", idDelete[i]

                            cw_ittreeview_setSelect, (*pState).wTreeDst, idNewSel, /CLEAR
                            ; Actively set the item on the property sheet so that
                            ; it doesn't continue to display the old (deleted) item
                            WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=idNewSel

                        endif
                    endif
                endfor
                IDLitwdMacroEditor_SetChanged, pState, 1
                IDLitwdMacroEditor_EnableTree, pState
            endif
            break
            end


        'ContextDuplicate': ; fall thru
        'EditDuplicate': begin
            WIDGET_CONTROL, /HOURGLASS
            ; Only allowed if wTreeDst selected
            idSel = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSel)
            oSrvMacros = oSys->GetService('MACROS')

            for i=0, nSel-1 do begin
                oItem = oSys->GetByIdentifier(idSel[i])
                oSrvMacros->Duplicate, oItem, /EDITOR
            endfor

            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end

        'TreeCopyPaste': begin
            WIDGET_CONTROL, /HOURGLASS
            ; pretend the srctree was selected.
            (*pState).wLastTreeSelected = (*pState).wTreeSrc
            oTmp = (*pState).oCopied
            IDLitwdMacroEditor_Copy, pState
            IDLitwdMacroEditor_Paste, pState
            ptr_free, (*pState).oCopied
            (*pState).oCopied = oTmp
            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end

        'PropertyMoveUp': begin
            oSrvMacros = oSys->GetService('MACROS')

            ; get the property ids from the src prop sheet
            nsel = WIDGET_INFO((*pState).wPropSrc, /PROPERTYSHEET_NSELECTED)
            if (nsel eq 0) then break
            idProps = WIDGET_INFO((*pState).wPropSrc, $
                /PROPERTYSHEET_SELECTED)

            ; get the destination folder (macroname)
            idSelDst = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSelDst)
            if nSelDst eq 0 || $
                strupcase(idSelDst[0]) eq "/REGISTRY/MACROS"then begin
                ; no selection or upper level macros folder selected
                oSrvMacros->GetProperty, NEW_NAME=macroName
            endif else begin
                fullPath = idSelDst[0]
                oSys = (*pState).oUI->GetTool()
                oDstItem = oSys->GetByIdentifier(fullPath)
                ; If we actually had an item selected in the dst tree,
                ; find its parent.
                if (~obj_isa(oDstItem, "IDLitContainer")) then begin
                    ; if macro item selected, get the macro name
                    macroItemName = IDLitBaseName(fullPath, remainder=fullPath)
                endif
                ; need only the macroName
                macroName = IDLitBaseName(fullPath)
            endelse

            ; get src tree selection
            idTreeSrc = cw_ittreeview_getSelect((*pState).wTreeSrc)
            ; handle multiple selection from tree by looking at last element
            oSrcItem = oSys->GetByIdentifier(idTreeSrc[n_elements(idTreeSrc)-1])

            if n_elements(oDstItem) gt 0 && (obj_isa(oDstItem, "IDLitObjDescMacro")) then begin
                ; classname IDLitOpSetProperty, just add props to existing item
                oSrvMacros->AddProperties, oSrcItem, oDstItem, idProps, $
                    /EDITOR
                idNewItem = idSelDst[0]
                ; have to get property sheet to unload and then reload
                ; the SetProperty item in order to recognize new properties
                WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=macroName
                WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=idNewItem
            endif else begin
                oSrvMacros->PasteMacroSetProperty, oSrcItem, macroName, idNewItem, idProps, $
                    /EDITOR
            endelse
            WIDGET_CONTROL, (*pState).wPropDst, /REFRESH
            cw_ittreeview_setSelect, (*pState).wTreeDst, idNewItem, /CLEAR
            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end

        'PropertyRemove': begin
            IDLitwdMacroEditor_removeProperties, pState
            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end

        'Save': begin
            IDLitwdMacroEditor_Save, pState
            break
            end

        'Close': begin
            IDLitwdMacroEditor_Close, pState
            break
            end

        'Help': begin
            oHelp = oSys->GetService('HELP')
            if (~oHelp) then $
                break
            oHelp->HelpTopic, oSys, 'iToolsMacroEditor'
            break
            end

        'New': begin
            oSrvMacros = oSys->GetService('MACROS')
            WIDGET_CONTROL, /HOURGLASS
            oNewMacro = oSrvMacros->NewMacro(newMacroName)
            fullID = '/REGISTRY/MACROS/'+strupcase(newMacroName)
            ; manually update the tree and property sheet
            cw_ittreeview_setSelect, (*pState).wTreeDst, fullID, /CLEAR
            WIDGET_CONTROL, (*pState).wPropDst, SET_VALUE=fullID
            IDLitwdMacroEditor_EnableTree, pState
            WIDGET_CONTROL, (*pState).wPropDst, /REFRESH
            IDLitwdMacroEditor_SetChanged, pState, 1
            break
            end

        'Import': begin
            oSrvMacros = oSys->GetService('MACROS')
            oTool = oSys->_GetCurrentTool()
            if (OBJ_VALID(oTool)) then $
                oTool->GetProperty, WORKING_DIRECTORY=workingDir
            filename = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
                FILTER=[['*_macro.sav','*'], $
                    ['iTools Macro files (*_macro.sav)', $
                    'All files (*)']], $
                /MULTIPLE_FILES, $
                PATH=workingDir, $
                TITLE=IDLitLangCatQuery('UI:wdMacroEdit:Import'))
            if (filename[0] ne '') then begin
                WIDGET_CONTROL, /HOURGLASS
                oSrvMacros->ImportMacro, filename
                IDLitwdMacroEditor_SetChanged, pState, 1
            endif
            break
            end

        'Export': begin
            oSrvMacros = oSys->GetService('MACROS')

            ; get the destination folder (macroname)
            idSelDst = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSelDst)
            if nSelDst eq 0 || $
                strupcase(idSelDst[0]) eq "/REGISTRY/MACROS"then begin
                ; no selection or upper level macros folder selected
                oSrvMacros->GetProperty, NEW_NAME=macroName
            endif else begin
                oSys = (*pState).oUI->GetTool()
                oItem = oSys->GetByIdentifier(idSelDst[0])
                ; if macro item selected, get the parent to retrieve
                ; the macro name
                if (~obj_isa(oItem, "IDLitContainer")) then $
                    oItem->GetProperty, _PARENT=oItem
                oItem->GetProperty, NAME=macroName
            endelse

            oTool = oSys->_GetCurrentTool()
            if (OBJ_VALID(oTool)) then $
                oTool->GetProperty, WORKING_DIRECTORY=workingDir
            filename = DIALOG_PICKFILE(DIALOG_PARENT=event.top, $
                /WRITE, $
                /OVERWRITE_PROMPT, $
                FILE=IDL_VALIDNAME(macroname, /CONVERT_ALL)+'_macro.sav', $
                FILTER=[['*_macro.sav','*'], $
                    ['iTools Macro files (*_macro.sav)', $
                    'All files (*)']], $
                 PATH=workingDir, $
                TITLE=IDLitLangCatQuery('UI:wdMacroEdit:Export'))
            if (filename[0] ne '') then begin
                WIDGET_CONTROL, /HOURGLASS
                oSrvMacros->saveMacro, macroName, filename
            endif
            break
            end

        'MoveUp':
        'MoveDown': begin
            oSys = (*pState).oUI->GetTool()
            idSel = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSel)
            oRegistry = oSys->GetByIdentifier('/Registry')
            for i=0, nSel-1 do begin
                oItem = oSys->GetByIdentifier(idSel[i])
                oItem->GetProperty, _PARENT=oParent
                if (oParent eq oRegistry) then continue
                if oParent->IsContained(oItem, POSITION=srcPos) then begin
                    switch button of
                        "MoveUp": begin
                                destPos = (srcPos-1) > 0
                            break
                            end
                        "MoveDown": begin
                                destPos = (srcPos+1) < (oParent->Count() - 1)
                            break
                            end
                    endswitch
                    if (srcPos ne destPos) then begin
                        oParent->Move, srcPos, destPos
                        oSys->DoOnNotify, oParent->GetFullIdentifier(), "MOVEITEMS", idSel[i]
                    endif
                endif
            endfor
            if nSel gt 0 then begin
                cw_ittreeview_setSelect, (*pState).wTreeDst, idSel[nSel-1], /CLEAR
                IDLitwdMacroEditor_SetChanged, pState, 1
            endif
            break
            end

        'Run': begin
            oSys = (*pState).oUI->GetTool()
            oTool = oSys->_GetCurrentTool()
            oSrvMacros = oSys->GetService('MACROS')
            ; no tool to run in
            if ~obj_valid(oTool) then break;

            idSel = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSel)
            oMacros = oTool->GetByIdentifier('/Registry/Macros')
            for i=0, nSel-1 do begin
                oItem = oTool->GetByIdentifier(idSel[i])
                if oItem eq oMacros then continue
                oItem->GetProperty, _PARENT=oParent
                ; traverse up to specific macro
                while (oParent ne oMacros) do begin
                    oItem = oParent
                    oItem->GetProperty, _PARENT=oParent
                endwhile
                oItem->GetProperty, NAME=macroName
                ; get macro by name
                oMacro = oSrvMacros->GetMacroByName(macroName)
                if (~OBJ_VALID(oMacro)) then break
                ; get macro properties to pass on to run macro operation
                oMacro->GetProperty, $
                    DISPLAY_STEPS=displaySteps, $
                    STEP_DELAY=stepDelay

                oDesc = oTool->GetByIdentifier('/Registry/MacroTools/Run Macro')
                oDesc->GetProperty, $
                    SHOW_EXECUTION_UI=showUIOrig, $
                    MACRO_NAME=macroNameOrig

                oDesc->SetProperty, $
                    SHOW_EXECUTION_UI=0, $
                    MACRO_NAME=macroName, $
                    DISPLAY_STEPS=displaySteps, $
                    STEP_DELAY=stepDelay

                oOpRunMacro = oDesc->GetObjectInstance()

                ; run the command
                oCmd = oOpRunMacro->DoAction(oTool)

                ; Add this to history explicitly
                if obj_valid(oCmd[0]) then begin
                    oSrvMacros->GetProperty, CURRENT_NAME=currentName
                    oSrvMacros->PasteMacroOperation, oDesc, currentName

                    ; Add this to undo/redo explicitly if command is valid
                    ; note that action might destroy tool, so check it again
                    if obj_valid(oTool) then $
                        oTool->_TransactCommand, oCmd

                endif

                if obj_valid(oTool) then begin
                    ; restore original values on the singleton
                    oDesc->SetProperty, $
                        SHOW_EXECUTION_UI=showUIOrig, $
                        MACRO_NAME=macroNameOrig
                endif
            endfor
            break
            end

        else: MESSAGE, IDLitLangCatQuery('UI:wdMacroEdit:BadButton') + button

    endswitch

end


;------------------------------------------------------------------------
pro IDLitwdMacroEditor_EnableTree, pState, $
    DESTINATION=destination

    compile_opt idl2, hidden

    oSys = (*pState).oUI->GetTool()
    hasTool = OBJ_VALID(oSys->_GetCurrentTool())

    isDst = (*pState).wLastTreeSelected eq (*pState).wTreeDst
    idTreeDst = cw_ittreeview_getSelect((*pState).wTreeDst, COUNT=nSelDst)
    if nSelDst gt 0 then begin
        result = where(strupcase(idTreeDst) eq '/REGISTRY/MACROS', topFolder)
    endif else topFolder = 0
    propDst = (*pState).wLastDestSelected eq (*pState).wPropDst
    if isDst then begin
        srcSkip = 0
    endif else begin
        ; Allow /Registry/Operations to be moved up
        ; Allow visualizations, they will result in addition of insert/visualization
        ; Skip containers
        ; Skip annotations, they need to be created with data
        ; Note annotations from history are ok.
        ; Check each item of a multiple selection
        idTreeSrc = cw_ittreeview_getSelect((*pState).wTreeSrc)
        srcSkip = 0
        for i=0, n_elements(idTreeSrc)-1 do begin
            if srcSkip then break
            oSrcItem = oSys->GetByIdentifier(idTreeSrc[i])
            srcSkip = obj_isa(oSrcItem, 'IDL_Container') || $
                strpos(strupcase(idTreeSrc[i]), '/REGISTRY/ANNOTATIONS') ge 0
        endfor
    endelse

    WIDGET_CONTROL, (*pState).wTreeCopyPaste, $
        SENSITIVE=~isDst && ~srcSkip && (nSelDst eq 1) && ~propDst

    WIDGET_CONTROL, (*pState).wTreeDelete, $
        SENSITIVE=isDst && ~topFolder && ~propDst

    WIDGET_CONTROL, (*pState).wEditCut, $
        SENSITIVE=isDst && ~topFolder && ~propDst
    WIDGET_CONTROL, (*pState).wContextCut, $
        SENSITIVE=isDst && ~topFolder && ~propDst

    ; allow copy from part of src tree as allowed
    ; by treeCopyPaste
    WIDGET_CONTROL, (*pState).wEditCopy, $
        SENSITIVE=~srcSkip && ~topFolder && ~propDst
    WIDGET_CONTROL, (*pState).wContextCopy, $
        SENSITIVE=~srcSkip && ~topFolder && ~propDst

    WIDGET_CONTROL, (*pState).wEditPaste, $
        SENSITIVE=isDst && ptr_valid((*pState).oCopied) && $
            (nSelDst eq 1) && ~propDst
    WIDGET_CONTROL, (*pState).wContextPaste, $
        SENSITIVE=isDst && ptr_valid((*pState).oCopied) && $
            (nSelDst eq 1) && ~propDst

    WIDGET_CONTROL, (*pState).wEditDelete, $
        SENSITIVE=isDst && ~topFolder && ~propDst
    WIDGET_CONTROL, (*pState).wContextDelete, $
        SENSITIVE=isDst && ~topFolder && ~propDst

    WIDGET_CONTROL, (*pState).wEditDuplicate, $
        SENSITIVE=isDst && ~topFolder && ~propDst ; not isItem
    WIDGET_CONTROL, (*pState).wContextDuplicate, $
        SENSITIVE=isDst && ~topFolder && ~propDst ; not isItem

    ; MACROS
    WIDGET_CONTROL, (*pState).wEditMoveUp, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1) && ~propDst
    WIDGET_CONTROL, (*pState).wEditMoveDown, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1) && ~propDst
    WIDGET_CONTROL, (*pState).wContextMoveUp, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1) && ~propDst
    WIDGET_CONTROL, (*pState).wContextMoveDown, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1) && ~propDst

    ; Only allow one selection to run
    WIDGET_CONTROL, (*pState).wRunRun, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1)
    WIDGET_CONTROL, (*pState).wContextRun, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1)

    WIDGET_CONTROL, (*pState).wExport, $
        SENSITIVE=isDst && ~topFolder && (nSelDst eq 1)
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
pro IDLitwdMacroEditor_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL,event.top, GET_UVALUE=pState

    oSys = (*pState).oUI->GetTool()

    case TAG_NAMES(event, /STRUCTURE_NAME) of

    'WIDGET_BASE': begin        ; Resize
      geomTop = widget_info( (*pState).wTop, /GEOMETRY)
      if !version.os_family eq 'unix' then begin
          spaceAvailableX = geomTop.scr_xsize - 2 * geomTop.xpad
          spaceAvailableY = geomTop.scr_ysize - 2 * geomTop.ypad
      endif else begin
          spaceAvailableX = geomTop.xsize - 2 * geomTop.xpad
          spaceAvailableY = geomTop.ysize - 2 * geomTop.ypad
      endelse
      xPad = (*pState).xPad
      yPad = (*pState).yPad

      ; limit size for each tree or propsheet to 100x100 minimum
      newPaneSizeX = 100 > (spaceAvailableX - xPad)/2
      newPaneSizeY = 100 > (spaceAvailableY - yPad)/2

      widget_control, (*pState).wTop, UPDATE=0
      ; keep all panes equally sized
      widget_control, (*pState).wTreeDst, $
        SCR_XSIZE=newPaneSizeX, SCR_YSIZE=newPaneSizeY
      widget_control, (*pState).wTreeSrc, $
        SCR_XSIZE=newPaneSizeX, SCR_YSIZE=newPaneSizeY
      widget_control, (*pState).wPropDst, $
        SCR_XSIZE=newPaneSizeX, SCR_YSIZE=newPaneSizeY
      widget_control, (*pState).wPropSrc, $
        SCR_XSIZE=newPaneSizeX, SCR_YSIZE=newPaneSizeY
      widget_control, (*pState).wTop, /UPDATE

    end


    ; Event from the treeview compound widget.
    'CW_TREE_SEL': begin
        (*pState).wLastTreeSelected = event.id
        isDest = (*pState).wLastTreeSelected eq (*pState).wTreeDst
        WIDGET_CONTROL, isDest ? $
            (*pState).wPropDst : (*pState).wPropSrc, $
            SET_VALUE=event.selected
        if isDest then $
            (*pState).wLastDestSelected = event.id

        IDLitwdMacroEditor_EnableTree, pState

        ; Disable Property button until a new property selection is made.
        WIDGET_CONTROL, (*pState).wPropertyMoveUp, SENSITIVE=0
        WIDGET_CONTROL, (*pState).wPropertyRemove, SENSITIVE=0
        end


    'WIDGET_PROPSHEET_SELECT': begin
        nsel = WIDGET_INFO(event.id, /PROPERTYSHEET_NSELECTED)
        propMoveUp = 0b
        propRemove = 0b

        if (event.id eq (*pState).wPropSrc) then begin
            wClear = (*pState).wPropDst
            if nsel gt 0 then begin
                ; assume ok to move prop up
                propMoveUp = 1
                ; turn it back off if a userdef prop is selected
                idProps = WIDGET_INFO((*pState).wPropSrc, $
                    /PROPERTYSHEET_SELECTED)
                idTreeSrc = cw_ittreeview_getSelect((*pState).wTreeSrc)
                ; handle multiple selection from tree by looking at last element
                oSrcItem = oSys->GetByIdentifier(idTreeSrc[n_elements(idTreeSrc)-1])
                for i=0, nsel-1 do begin
                    oSrcItem->GetPropertyAttribute, idProps[i], TYPE=type
                    if type eq 0 then propMoveUp = 0
                endfor
            endif else propMoveUp = 0
            propRemove = 0b
        endif else begin     ; in destination propsheet
            (*pState).wLastDestSelected = event.id
            wClear = (*pState).wPropSrc
            propMoveUp = 0b
            classname = ''
            if nsel gt 0 then begin
                WIDGET_CONTROL, (*pState).wPropDst, GET_VALUE=idDstItem
                oDstItem = oSys->GetByIdentifier(idDstItem)
                if obj_isa(oDstItem, 'IDLitObjDesc') then $
                    oDstItem->IDLitObjDesc::GetProperty, CLASSNAME=classname
            endif
            propRemove = (nsel gt 0) && (classname eq 'IDLitOpSetProperty')
        endelse

        IDLitwdMacroEditor_EnableTree, pState

        WIDGET_CONTROL, (*pState).wPropertyMoveUp, SENSITIVE=propMoveUp
        WIDGET_CONTROL, (*pState).wPropertyRemove, SENSITIVE=propRemove

        ; Clear selections from other propsheet.
        WIDGET_CONTROL, wClear, PROPERTYSHEET_SETSELECTED=''

        end

    'WIDGET_PROPSHEET_CHANGE': begin
        if (event.id eq (*pState).wPropDst) then $
            IDLitwdMacroEditor_SetChanged, pState, 1
        end

    ; We don't die, we hide
    'WIDGET_KILL_REQUEST' : begin
        IDLitwdMacroEditor_Close, pState
        end

    'WIDGET_CONTEXT': begin
;        WIDGET_CONTROL, (*pState).wPropDst, GET_VALUE=idSel
        hasTool = OBJ_VALID(oSys->_GetCurrentTool())
        WIDGET_DISPLAYCONTEXTMENU, event.id, $
            event.x, event.y, (*pState).wContextMenu
        end

    else:

    endcase

end


;-------------------------------------------------------------------------
pro IDLitwdMacroEditor_killnotify, wTLB

    compile_opt idl2, hidden

    WIDGET_CONTROL, wTLB, GET_UVALUE=pState

    ; Destroy old clipboard item.
    if ((*pState).wasCut) then begin
        OBJ_DESTROY, *((*pState).oCopied)
        PTR_FREE, (*pState).oCopied
    endif

    PTR_FREE, pState

end


;-------------------------------------------------------------------------
pro IDLitwdMacroEditor, oUI, $
    XSIZE=xsizeIn, $
    YSIZE=ysizeIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_PARAMS() ne 1) then $
        MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

    regName = 'MacroEditor'
    widname = 'IDLitwdMacroEditor'

    ; Has this already been registered and is up and running?
    wID = oUI->GetWidgetByName(regName)

    oSys = oUI->GetTool()

    if (WIDGET_INFO(wID, /VALID)) then begin
        WIDGET_CONTROL, wID, GET_UVALUE=pState
        ; Make sure the tree displays the current tool items.
        IDLitwdMacroEditor_callback, wID, '', 'FOCUS_GAIN', '', /IGNORE_MAP
        WIDGET_CONTROL, wID, /MAP, ICONIFY=0
        return
    end

    xsize = (N_ELEMENTS(xsizeIn) gt 0) ? xsizeIn[0] : 300
    ysize = (N_ELEMENTS(ysizeIn) gt 0) ? ysizeIn[0] : 250


    pState = PTR_NEW( $
        { $
        wTop: 0L, $
        wTreeDst: 0L, $
        wTreeSrc: 0L, $
        wPropDst: 0L, $
        wPropSrc: 0L, $
        wExport: 0L, $
        wSave: 0L, $
        wTreeCopyPaste: 0L, $
        wTreeDelete: 0L, $
        wPropertyMoveUp: 0L, $
        wPropertyRemove: 0L, $
        wEditCut: 0L, $
        wEditCopy: 0L, $
        wEditPaste: 0L, $
        wEditDelete: 0L, $
        wEditDuplicate: 0L, $
        wEditMoveUp: 0L, $
        wEditMoveDown: 0L, $
        wContextCut: 0L, $
        wContextCopy: 0L, $
        wContextPaste: 0L, $
        wContextDelete: 0L, $
        wContextDuplicate: 0L, $
        wContextMoveUp: 0L, $
        wContextMoveDown: 0L, $
        wContextRun: 0L, $
        wRunRun: 0L, $
        haveVisSelection: 0b, $
        isChanged: 0b, $
        wLastTreeSelected: 0L, $    which tree was last selected, dest or src ?
        wLastDestSelected: 0L, $    which dest window last selected, tree or propsheet ?
        oUI: oUI, $
        wContextMenu: 0L, $
        xPad:0L, $  ; all space not taken up by trees or propsheets
        yPad:0L, $  ; all space not taken up by trees or propsheets, includes button row
        idSelf:'', $
        idTool:'', $
        oTool: OBJ_NEW(), $
        wasCut: 0b, $
        oCopied: PTR_NEW() $
        })

    ; Create top level base
    wTop = WIDGET_BASE(/COLUMN, $
        /TLB_SIZE_EVENTS, $
        KILL_NOTIFY=widname+'_killnotify', $
        MAP=0, $
        TITLE=IDLitLangCatQuery('UI:wdMacroEdit:Title'), $
        MBAR=wMenubar, $
        XPAD=0, YPAD=0, SPACE=2, $
        /TLB_KILL_REQUEST_EVENTS, $
        UVALUE=pState, $
        _EXTRA=_extra)

    (*pState).wTop = wTop

    WIDGET_CONTROL,wTop,/realize

    wFile = WIDGET_BUTTON(wMenubar, /MENU, $
                          VALUE=IDLitLangCatQuery('UI:wdMacroEdit:File'), $
                          EVENT_PRO=widname+'_buttonevent')
    wEdit = WIDGET_BUTTON(wMenubar, /MENU, $
                          VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Edit'), $
                          EVENT_PRO=widname+'_buttonevent')
    wRun = WIDGET_BUTTON(wMenubar, /MENU, $
                         VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Run'), $
                         EVENT_PRO=widname+'_buttonevent')
    wHelp = WIDGET_BUTTON(wMenubar, /MENU, $
                          VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Help'), $
                          /HELP, EVENT_PRO=widname+'_buttonevent')

    wImport = WIDGET_BUTTON(wFile, $
        ACCELERATOR='Ctrl+N', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:New'), $
        UNAME='New')

    wImport = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Import...'), $
        UNAME='Import')

    (*pState).wExport = WIDGET_BUTTON(wFile, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Export...'), $
        UNAME='Export')

    (*pState).wSave = WIDGET_BUTTON(wFile, SENSITIVE=0, $
        ACCELERATOR='Ctrl+S', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Save'), $
        UNAME='Save')

    wClose = WIDGET_BUTTON(wFile, $
        ACCELERATOR='Ctrl+Q', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Close'), $
        UNAME='Close', /SEPARATOR)

    wHelpButton = WIDGET_BUTTON(wHelp, $
        ACCELERATOR='F1', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Help'), $
        UNAME='Help')



    wGrid = WIDGET_BASE(wTop, COLUMN=2, SPACE=10, XPAD=10, YPAD=10)

    oSrvMacros = oSys->GetService('MACROS')
    oFolders = oSrvMacros->GetMacro(/ALL, COUNT=nfolders)
    idSelect = (nfolders gt 0) ? oFolders[0]->GetFullIdentifier() : '/Registry/Macros'

    folder = '/Registry/Macros'
    (*pState).wTreeDst = CW_ITTREEVIEW(wGrid, (*pState).oUI, $
        /CONTEXT_EVENTS, $
        IDENTIFIER=folder, $
        /MULTIPLE, $
        SCR_XSIZE=xsize, $
        SCR_YSIZE=ysize, $
        UNAME=regName + 'Dst')

    if (idSelect) then begin
        cw_ittreeview_setSelect, (*pState).wTreeDst, idSelect
        (*pState).wLastTreeSelected = (*pState).wTreeDst
        (*pState).wLastDestSelected = (*pState).wTreeDst
    endif

    wButtonRow = WIDGET_BASE(wGrid, $
        /ALIGN_CENTER, /ROW, SPACE=10, $
        EVENT_PRO=widname+'_buttonevent')
    (*pState).wTreeCopyPaste = WIDGET_BUTTON(wButtonRow, /BITMAP, $
        SENSITIVE=0, $
        TOOLTIP=IDLitLangCatQuery('UI:wdMacroEdit:CopyTTip'), $
        VALUE=FILEPATH('switch_up.bmp', SUBDIR=['resource','bitmaps']), $
        UNAME='TreeCopyPaste')
    (*pState).wTreeDelete = WIDGET_BUTTON(wButtonRow, /BITMAP, $
        SENSITIVE=0, $
        TOOLTIP=IDLitLangCatQuery('UI:wdMacroEdit:DelTTip'), $
        VALUE=FILEPATH('delete.bmp', SUBDIR=['resource','bitmaps']), $
        UNAME='EditDelete')

    (*pState).wTreeSrc = CW_ITTREEVIEW(wGrid, (*pState).oUI, $
        /CONTEXT_EVENTS, $
        IDENTIFIER='/Registry/History', $
        /MULTIPLE, $
        /FRAME, $
        SCR_XSIZE=xsize, $
        SCR_YSIZE=ysize, $
        UNAME=regName + 'Src')

    oTool = oSys->_GetCurrentTool()
    oItem = oTool->GetByIdentifier('/Registry/Visualizations')
    if obj_valid(oItem) then $
        cw_ittreeview_addLevel, $
            (*pState).wTreeSrc, $
            oItem, $
            (*pState).wTreeSrc, $
            /NO_NOTIFY

    oItem = oTool->GetByIdentifier('/Registry/Annotations')
    if obj_valid(oItem) then $
        cw_ittreeview_addLevel, $
            (*pState).wTreeSrc, $
            oItem, $
            (*pState).wTreeSrc, $
            /NO_NOTIFY

    oItem = oTool->GetByIdentifier('/Registry/MacroTools')
    if obj_valid(oItem) then $
        cw_ittreeview_addLevel, $
            (*pState).wTreeSrc, $
            oItem, $
            (*pState).wTreeSrc, $
            /NO_NOTIFY

    ; Context menu.
    wContextMenu = WIDGET_BASE(wGrid, /CONTEXT_MENU, $
        event_pro=widname+'_buttonevent')
    (*pState).wContextMenu = wContextMenu

    (*pState).wContextCut = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Cut'), $
        UNAME='ContextCut')
    (*pState).wContextCopy = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Copy'), $
        UNAME='ContextCopy')
    (*pState).wContextPaste = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Paste'), $
        UNAME='ContextPaste', SENSITIVE=0)
    (*pState).wContextDelete = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Delete'), $
        UNAME='ContextDelete', /SEPARATOR)
    (*pState).wContextDuplicate = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Dup'), $
        UNAME='ContextDuplicate')


    (*pState).wEditCut = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Cut'), $
        ACCELERATOR='Ctrl+X', $
        UNAME='EditCut')
    (*pState).wEditCopy = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Copy'), $
        ACCELERATOR='Ctrl+C', $
        UNAME='EditCopy')
    (*pState).wEditPaste = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Paste'), $
        ACCELERATOR='Ctrl+V', $
        UNAME='EditPaste', SENSITIVE=0)
    (*pState).wEditDelete = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Delete'), $
        ACCELERATOR='Del', $
        UNAME='EditDelete', /SEPARATOR)
    (*pState).wEditDuplicate = WIDGET_BUTTON(wEdit, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:Dup'), $
        UNAME='EditDuplicate')

    (*pState).wContextMoveUp = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:MoveUp'), $
        UNAME='MoveUp', /SEPARATOR)
    (*pState).wContextMoveDown = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:MoveDown'), $
        UNAME='MoveDown')
    (*pState).wContextRun = WIDGET_BUTTON(wContextMenu, $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:RunMacro'), $
        UNAME='Run', /SEPARATOR)

    (*pState).wEditMoveUp = WIDGET_BUTTON(wEdit, $
        ACCELERATOR='Ctrl+U', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:MoveUp'), $
        UNAME='MoveUp', /SEPARATOR)
    (*pState).wEditMoveDown = WIDGET_BUTTON(wEdit, $
        ACCELERATOR='Ctrl+D', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:MoveDown'), $
        UNAME='MoveDown')
    (*pState).wRunRun = WIDGET_BUTTON(wRun, $
        ACCELERATOR='F5', $
        VALUE=IDLitLangCatQuery('UI:wdMacroEdit:RunMacro'), $
        UNAME='Run')

    ; Set the first item to be selected.
    ; don't enable multiple selection
    (*pState).wPropDst = CW_ITPROPERTYSHEET(wGrid, (*pState).oUI, $
        scr_xsize=xsize, $
        scr_ysize=ysize, $
        /CHANGE_EVENTS, $
        COMMIT=0, $ ; commit mode on the propsheet
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /MULTIPLE_PROPERTIES, $
        /SUNKEN_FRAME, $
        /STATUS, $
        VALUE=idSelect)

    wButtonRow = WIDGET_BASE(wGrid, $
        /ALIGN_CENTER, /ROW, SPACE=10, $
        EVENT_PRO=widname+'_buttonevent')
    (*pState).wPropertyMoveUp = WIDGET_BUTTON(wButtonRow, /BITMAP, $
        SENSITIVE=0, $
        TOOLTIP=IDLitLangCatQuery('UI:wdMacroEdit:CopyTTip'), $
        VALUE=FILEPATH('switch_up.bmp', SUBDIR=['resource','bitmaps']), $
        UNAME='PropertyMoveUp')
    (*pState).wPropertyRemove = WIDGET_BUTTON(wButtonRow, /BITMAP, $
        SENSITIVE=0, $
        TOOLTIP=IDLitLangCatQuery('UI:wdMacroEdit:DelTTip'), $
        VALUE=FILEPATH('delete.bmp', SUBDIR=['resource','bitmaps']), $
        UNAME='PropertyRemove')

    (*pState).wPropSrc = CW_ITPROPERTYSHEET(wGrid, (*pState).oUI, $
        scr_xsize=xsize, $
        scr_ysize=ysize, $
        COMMIT=0, $ ; commit mode on the propsheet
        EDITABLE=0, $
        /HIDE_USERDEF, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /MULTIPLE_PROPERTIES, $
        /SUNKEN_FRAME, $
        /STATUS)

    ; Make selections manually, but don't update wLastTreeSelected
    ; leave the destination tree the last tree selected.
    cw_ittreeview_setSelect, (*pState).wTreeSrc, '/Registry/History'
    WIDGET_CONTROL, (*pState).wPropSrc, SET_VALUE='/Registry/History'

    ; enable/disable menus appropriately
    IDLitwdMacroEditor_EnableTree, pState

    ; Add our current tool items.
    IDLitwdMacroEditor_callback, wTop, '', 'FOCUS_GAIN', '', /IGNORE_MAP

    ; Add browser to the UI
    (*pState).idSelf = oUI->RegisterWidget(wTop, regName, $
        widname + '_callback', $
        DESCRIPTION=Title, /FLOATING)

    ; Register for notification messages
    oUI->AddOnNotifyObserver, (*pState).idSelf, folder
    ; Observe the system so that we can be desensitized when a macro is running
    oUI->AddOnNotifyObserver, (*pState).idSelf, oSys->GetFullIdentifier()

    WIDGET_CONTROL, wTop, /MAP

    ; Cache wTop size
    geomTop = WIDGET_INFO(wTop, /GEOMETRY)
    if !version.os_family eq 'unix' then begin
        spaceAvailableX = geomTop.scr_xsize - 2 * geomTop.xpad
        spaceAvailableY = geomTop.scr_ysize - 2 * geomTop.ypad
    endif else begin
        spaceAvailableX = geomTop.xsize - 2 * geomTop.xpad
        spaceAvailableY = geomTop.ysize - 2 * geomTop.ypad
    endelse
    (*pState).xPad = spaceAvailableX - 2*xsize
    (*pState).yPad = spaceAvailableY - 2*ysize

    WIDGET_CONTROL, wTop, /CLEAR_EVENTS

    XMANAGER, widname, wTop, /NO_BLOCK

end

