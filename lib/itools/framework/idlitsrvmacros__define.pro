; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsrvmacros__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool services needed for macros.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitsrvReadFile object.
;
; Arguments:
;   None.
;
;function IDLitsrvMacros::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; IDLitsrvMacros::RenameHistoryFolder
;
; Purpose:
;   Internal method to rename a history folder to a name that
;   doesn't conflict with existing names when the tool is destroyed.
;
; Return value:
;   None
;
; Arguments:
;   None
;
; Keywords:
;   None
;
;
pro IDLitsrvMacros::RenameHistoryFolder

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()
    oTool = oSys->_GetCurrentTool()
    oTool->GetProperty, IDENTIFIER=idTool

    oHistory = oSys->GetByIdentifier('/Registry/History')
    if ~obj_valid(oHistory) then return

    oFolders = oHistory->Get(/ALL, COUNT=nFolders)

    ; Existing history folder names.  Note that names match ids
    ; so we only need to look at ids.
    folderIDs = STRARR(nFolders > 1)
    for i=0,nFolders-1 do begin
        oFolders[i]->GetProperty, IDENTIFIER=identifier
        folderIDs[i] = identifier
    endfor

    ; Be sure to choose a new name that isn't a duplicate.
    newFolderName = idTool
    index = 0
    while (MAX(STRCMP(folderIDs, newFolderName, /FOLD_CASE)) eq 1) do begin
        index++
        newFolderName = idTool + ' (Closed - ' + STRTRIM(index, 2) + ')'
    endwhile

    oCurrentHistoryFolder = oSys->GetByIdentifier('/Registry/History/'+idTool)
    if obj_valid(oCurrentHistoryFolder) then begin
        oCurrentHistoryFolder->SetProperty, $
            NAME=newFolderName, IDENTIFIER=newFolderName
        ; history displayed in tree view will have level rebuilt
        oSys->DoOnNotify, '/Registry/History', "UPDATEITEM", $
          '/Registry/History/'+newFolderName
    endif
end

pro IDLitsrvMacros::MarkAsUndone, oTrans, REDO=redo

    compile_opt idl2, hidden

    if ~obj_valid(oTrans) then return

    if n_elements(redo) eq 0 then redo = 0

    oSys = _IDLitSys_GetSystem()
    oTool = oSys->_GetCurrentTool()
    oTool->GetProperty, IDENTIFIER=idTool

    oHistory = oSys->GetByIdentifier('/Registry/History')
    if ~obj_valid(oHistory) then return

    oTrans->GetProperty, NAME=transName
    oCurrentHistoryFolder = oSys->GetByIdentifier('/Registry/History/'+idTool)
    if obj_valid(oCurrentHistoryFolder) then begin
        oHistoryItems = oCurrentHistoryFolder->Get(/ALL, COUNT=count)
        if redo then begin
            ; search from last undone action (beginning of history)
            for i=0, count-1 do begin
                oHistoryItems[i]->GetProperty, NAME=historyName
                ; remove parens
                if historyName eq '('+transName+')' then begin
                    oHistoryItems[i]->SetProperty, NAME=transName
                    oSys->DoOnNotify, '/Registry/History/'+idTool, "UPDATEITEM", $
                        oHistoryItems[i]->GetFullIdentifier()
                    break   ; only change name of one operation
                endif
                if historyName eq '(SetProperty: '+transName+')' then begin
                    oHistoryItems[i]->SetProperty, NAME='SetProperty: '+transName
                    oSys->DoOnNotify, '/Registry/History/'+idTool, "UPDATEITEM", $
                        oHistoryItems[i]->GetFullIdentifier()
                    break   ; only change name of one operation
                endif
            endfor
        endif else begin
            ; search from lastest action (end of history)
            for i=count-1, 0, -1 do begin
                oHistoryitems[i]->GetProperty, classname=classname
                if strupcase(classname) eq 'IDLITOPRUNMACRO' then begin
                    oHistoryItems[i]->GetProperty, MACRO_NAME=historyName
                endif else begin
                    oHistoryItems[i]->GetProperty, NAME=historyName
                endelse
                ; add parens
                if historyName eq transName || $
                        historyName eq 'SetProperty: '+transName then begin
                    oHistoryItems[i]->SetProperty, NAME='('+historyName+')'
                    oSys->DoOnNotify, '/Registry/History/'+idTool, "UPDATEITEM", $
                        oHistoryItems[i]->GetFullIdentifier()
                    break   ; only change name of one operation
                endif
            endfor
        endelse
    endif
end

;---------------------------------------------------------------------------
; IDLitsrvMacros::_NewMacroName
;
; Purpose:
;   Internal method to construct a new macro name that doesn't conflict
;   with existing names.
;
; Return value:
;   A string containing the new macro name.
;
; Arguments:
;   oMacroSrc: The macro to add.
;
; Keywords:
;   COPY: If set, preface duplicate names with "Copy of".
;       The default is to put a duplicate number in parentheses after.
;
function IDLitsrvMacros::_NewMacroName, macroName, COPY=copy

    compile_opt idl2, hidden

    ; Existing macro names.
    oMacros = self->GetMacro(/ALL, COUNT=nmacro)
    macroIDs = STRARR(2*nmacro > 2)
    for i=0,nmacro-1 do begin
        oMacros[i]->GetProperty, $
            NAME=name, IDENTIFIER=identifier
        macroIDs[2*i] = name
        macroIDs[2*i+1] = identifier
    endfor

    ; Be sure to choose a new name that isn't a duplicate.
    newmacroname = macroname
    index = 0
    while (MAX(STRCMP(macroIDs, newmacroname, /FOLD_CASE)) eq 1) do begin
        index++
        if (KEYWORD_SET(copy)) then begin
            newmacroname = 'Copy '
            if (index gt 1) then $
                newmacroname += STRTRIM(index, 2) + ' '
            newmacroname += 'of ' + macroname
        endif else begin
            newmacroname = macroname + ' (' + STRTRIM(index, 2) + ')'
        endelse
    endwhile

    return, newmacroname
end


;-------------------------------------------------------------------------
;; IDLitsrvMacros::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
pro IDLitsrvMacros::GetProperty, $
    CURRENT_NAME=currentName, $
    CURRENT_MACRO_ID=currentMacroID, $
    DISPLAY_STEPS=displaySteps, $
    MANIPULATOR_STEPS=manipulatorSteps, $
    SET_CURRENT_ITEM=setCurrentItem, $
    CURRENT_ITEM=currentItem, $
    CHECK_EVENTS=checkEvents, $
    DESTROY_CONTROLS=destroyControls, $
    REFRESH_TREE=refreshTree, $
    NEW_NAME=newName, $
    NESTING_LEVEL=nestingLevel, $
    RECORDING=recording, $
    PAUSE_MACRO=pauseMacro, $
    STEP_MACRO=stepMacro, $
    STEP_DELAY=stepDelay, $
    STOP_MACRO=stopMacro, $
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    if ARG_PRESENT(currentName) then begin
        if strlen(self._currentName) eq 0 then begin
           self._currentName = self->_NewMacroName ('New Macro')
        endif
        currentName = self._currentName
    endif

    ; the editor needs to be able to request a new name
    ; this has side effect of changing current name to the new name
    if ARG_PRESENT(newName) then begin
        self._currentName = self->_NewMacroName ('New Macro')
        newName = self._currentName
    endif

    if (ARG_PRESENT(currentMacroID)) then $
        currentMacroID = self._currentMacroID

    if (ARG_PRESENT(displaySteps)) then $
        displaySteps = self._displaySteps

    if (ARG_PRESENT(manipulatorSteps)) then $
        manipulatorSteps = self._manipulatorSteps

    if (ARG_PRESENT(setCurrentItem)) then $
        setCurrentItem = self._setCurrentItem

    if (ARG_PRESENT(currentItem)) then $
        currentItem = self._currentItem

    if (ARG_PRESENT(checkEvents)) then $
        checkEvents = self._checkEvents

    if (ARG_PRESENT(destroyControls)) then $
        destroyControls = self._destroyControls

    if (ARG_PRESENT(nestingLevel)) then $
        nestingLevel = self._nestingLevel

    if (ARG_PRESENT(refreshTree)) then $
        refreshTree = self._refreshTree

    if (ARG_PRESENT(recording)) then $
        recording = self._bRecording

    if (arg_present(pauseMacro)) then $
        pauseMacro = self._pauseMacro

    if (arg_present(stepMacro)) then $
        stepMacro = self._stepMacro

    if (arg_present(stepDelay)) then $
        stepDelay = self._stepDelay

    if (arg_present(stopMacro)) then $
        stopMacro = self._stopMacro

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::GetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitsrvMacros::SetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
pro IDLitsrvMacros::SetProperty, $
    CURRENT_NAME=currentName, $
    DISPLAY_STEPS=displaySteps,   $
    MANIPULATOR_STEPS=manipulatorSteps, $
    SET_CURRENT_ITEM=setCurrentItem, $
    CHECK_EVENTS=checkEvents, $
    DESTROY_CONTROLS=destroyControls, $
    REFRESH_TREE=refreshTree, $
    RECORDING=recording, $
    PAUSE_MACRO=pauseMacro, $
    STEP_MACRO=stepMacro, $
    STEP_DELAY=stepDelay, $
    STOP_MACRO=stopMacro, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if N_ELEMENTS(currentName) NE 0 then $
        self._currentName = currentName

    if (N_ELEMENTS(displaySteps) ne 0) then $
        self._displaySteps = displaySteps

    if (N_ELEMENTS(manipulatorSteps) gt 0) then $
      self._manipulatorSteps = KEYWORD_SET(manipulatorSteps)

    if (N_ELEMENTS(setCurrentItem) gt 0) then $
      self._setCurrentItem = KEYWORD_SET(setCurrentItem)

    if (N_ELEMENTS(checkEvents) gt 0) then $
      self._checkEvents = KEYWORD_SET(checkEvents)

    if (N_ELEMENTS(destroyControls) gt 0) then $
      self._destroyControls = KEYWORD_SET(destroyControls)

    if (N_ELEMENTS(refreshTree) gt 0) then $
      self._refreshTree = KEYWORD_SET(refreshTree)

    if (N_ELEMENTS(recording) gt 0) then $
      self._bRecording = KEYWORD_SET(recording)

    if (N_ELEMENTS(pauseMacro) ne 0) then begin
        self._pauseMacro = pauseMacro
    endif

    if (N_ELEMENTS(stepMacro) ne 0) then begin
        self._stepMacro = stepMacro
    endif

    if (N_ELEMENTS(stepDelay) ne 0) then begin
        self._stepDelay = stepDelay
    endif

    if (N_ELEMENTS(stopMacro) ne 0) then begin
        self._stopMacro = stopMacro
    endif

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_extra
END

;-------------------------------------------------------------------------
;; IDLitsrvMacros::AddSelectionChange
;;
;; Purpose:
;;
;; Parameters:
;; TYPE: Type of selection change operation to add
;;
;;
;; Rules
;;      When creating a macro, an AddSelectionChange is added, MODE is
;;      left as the default value, New Selection.
;;          If anything is selected SELECTION_TYPE=0, Existing selection
;;          If nothing is selected, SELECTION_TYPE=7, de-select all
;;      When the selection is changed during recording, an
;;      AddSelectionChange is added.
;;          If something is selected (IDLitSelectContainer::SetSelectedItem),
;;              MODE=0, New Selection, SELECTION_TYPE=1, position in container
;;              Should supply container, itemid as well
;;          If something is added to selection (IDLitSelectContainer::AddSelectedItem),
;;              MODE=1, Add to Selection, SELECTION_TYPE=1, position in container
;;              Should supply container, itemid as well
;;          If something is DE-selected (IDLitSelectContainer::RemoveSelectedItem),
;;              MODE=2, Remove from Selection, SELECTION_TYPE=1, position in container
;;              Should supply container, itemid as well
;;          If all items selected (idlitopselectall), no SelectionChange operation is
;;              added.  The SelectAll operation is added as a normal part of the
;;              macro/history system.
;;
pro IDLitsrvMacros::AddSelectionChange, oItem, $
    CONTAINER=container,   $
    MODE=mode,   $
    SELECTION_TYPE=selectionType

    compile_opt idl2, hidden

    ; default type is current selection
    if n_elements(selectionType) eq 0 then selectionType = 0
    ; default mode is new selection
    if n_elements(mode) eq 0 then mode = 0

    oSys = _IDLitSys_GetSystem()
    oTool = oSys->_GetCurrentTool()
    idSrc = "/Registry/MacroTools/SelectionChange"
    oDescSelectionChange = oTool->GetByIdentifier(idSrc)
    oDescSelectionChange->SetProperty, SELECTION_TYPE=selectionType
    ; concatenate name of selected item onto default name
    defaultName = 'Selection Change'
    if n_elements(oItem) gt 0 && obj_valid(oItem[0]) then begin
        oItem[0]->GetProperty, NAME=name
        if n_elements(oItem) gt 1 then name = name + " ..."
        case mode of
        0: newName = defaultName + ": " + name
        1: newName = defaultName + ", Add: " + name
        2: newName = defaultName + ", Remove: " + name
        endcase
        oDescSelectionChange->SetProperty, NAME=newName
    endif else begin
        ; need to do this since we are re-using the original objdesc each time
        oDescSelectionChange->SetProperty, NAME=defaultName
    endelse

    switch selectionType of
    0:          ;current selection
    6:          ;all items
    7: begin    ;no items (deselect all)
    break
    end
    1:  ;position in container
    3:  ;next in container
    4:  ;previous in container
    5: begin    ;identifier
        ; even for position, we set container,itemid and mode
        ; even for previous/next we set position, itemid and mode
        ; even for identifier we set position and mode
        if n_elements(oItem) eq 0 || ~obj_valid(oItem) then begin
            self->ErrorMessage, $
                IDLitLangCatQuery('Error:InvalidSelectChange:Text'), $
                title=IDLitLangCatQuery('Error:InvalidSelectChange:Title'), severity=2
            return
        endif
        idItemFull = oItem->GetFullIdentifier()
        idTool=oTool->GetFullIdentifier()
        oItem->GetProperty, _PARENT=oParent
        itemID = IDLitBasename(idItemFull, REMAINDER=container)
        ; strip tool id off front of container
        container = strmid(container, strlen(idTool)+1)
        ; provide effective-zero-based indexing to the user by
        ; skipping privates.  Must retrieve only privates when
        ; applying the position in idlitopselectionchange.
        position=0
        oObjs = oParent->Get(/ALL, /SKIP_PRIVATE, COUNT=count)
        for i=0, count-1 do begin
            if oObjs[i] eq oItem then begin
                position = i
                break
            endif
        endfor


        oDescSelectionChange->SetProperty, $
            CONTAINER=container,   $
            ITEM_ID=itemID, $
            MODE=mode,   $
            POSITION=position
    break
    end
    2: begin    ;all in container
        if n_elements(container) eq 0 then begin
            self->ErrorMessage, $
                IDLitLangCatQuery('Error:SelectChangeContainer:Text'), $
                title=IDLitLangCatQuery('Error:InvalidSelectChange:Title'), severity=2
            return
        endif
        oDescSelectionChange->SetProperty, $
            CONTAINER=container,   $
            MODE=mode
    break
    end
    endswitch
    self->PasteMacroOperation, oDescSelectionChange, self._currentName
END


;-------------------------------------------------------------------------
;; IDLitsrvMacros::AddToolChange, oTool
;;
;; Purpose:
;;
;; Parameters:
;; oTool: The new tool being activated
;;
;;
;;
pro IDLitsrvMacros::AddToolChange, oToolChange

    compile_opt idl2, hidden

    if n_elements(oToolChange) gt 0 && obj_valid(oToolChange) then begin
        oSys = _IDLitSys_GetSystem()
        oTool = oSys->_GetCurrentTool()
        idSrc = "/Registry/MacroTools/ToolChange"
        oDescToolChange = oTool->GetByIdentifier(idSrc)
        oToolChange->GetProperty, IDENTIFIER=idNewTool, _PARENT=oToolContainer
        void = oToolContainer->IsContained(oToolChange, POSITION=position)
        ; tool change type default is 0 for TOOL_ID
        oDescToolChange->SetProperty, CHANGE_TYPE=0, $
            TOOL_ID=idNewTool, POSITION=position
        ; concatenate id of selected tool onto default name
        defaultName = 'Tool Change'
        newName = defaultName + ": " + idNewTool
        oDescToolChange->SetProperty, NAME=newName
        self->PasteMacroOperation, oDescToolChange, self._currentName
    endif

END

;;---------------------------------------------------------------------------
;; IDLitsrvMacros::_UpdateMacroAvailability
;;
;; Purpose:
;;   Update menu sensitivity on macro menus.  Macros are a system-wide
;;   facility and the settings need to span the life of tools.
;;
;; Parameters
;;    oTool    - The tool to modify. This tool, must
;;               exist, be valid and part of the system.

PRO IDLitsrvMacros::UpdateMacroAvailability, oTools

    compile_opt idl2, hidden

    ; Setting the disable property on these items will automatically
    ; notify any tool menu items.
    oSys = _IDLitSys_GetSystem()
    oStart = oSys->GetByIdentifier('/Registry/MacroTools/Start Recording')
    if (OBJ_VALID(oStart)) then $
        oStart->SetProperty, DISABLE=self._bRecording
    oStop = oSys->GetByIdentifier('/Registry/MacroTools/Stop Recording')
    if (OBJ_VALID(oStop)) then $
        oStop->SetProperty, DISABLE=~self._bRecording
    oRun = oSys->GetByIdentifier('/Registry/MacroTools/Run Macro')
    if (OBJ_VALID(oRun)) then $
        oRun->SetProperty, DISABLE=self._bRecording

end

;-------------------------------------------------------------------------
;; IDLitsrvMacros::StartRecording
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
pro IDLitsrvMacros::StartRecording, oTool

    compile_opt idl2, hidden

    self->SetProperty, /RECORDING

    self->UpdateMacroAvailability

    ; Create a new unique macro name
    ; must be done prior to AddSelectionChange
    self._currentName = self->_NewMacroName("New Macro")

    ; add initial SelectionChange operation
    ; others will be added by IDLitTool::OnSelectionChange
    ; or by editing the macro
    idSrc = "/Registry/MacroTools/SelectionChange"
    oDescSelectionChange = oTool->GetByIdentifier(idSrc)
    ; Get current selection
    oSelection = oTool->GetSelectedItems(COUNT=count)
    ; something selected, use current selection for macro (0)
    ; nothing selected, de-select all for macro (7)
    selectionType = (count gt 0) ? 0 : 7
    self->AddSelectionChange, oSelection, SELECTION_TYPE=selectionType

    oFolder = oTool->GetByIdentifier('/REGISTRY/MACROS/'+ self._currentName)

    ; Default value for the macro folder display_steps property is false,
    ; but if the recording was started with manipulator_steps turned on then
    ; set display_steps to true.  Any time manipulator steps are
    ; being recorded it makes sense to save the macro with
    ; display_steps set to true to show the steps during playback.
    ; Pass on value obtained from Start Recording to the macro folder
    if obj_valid(oFolder) then $
        ; if we are recording steps, then we want to display them
        oFolder->SetProperty, DISPLAY_STEPS = self._manipulatorSteps

end


;-------------------------------------------------------------------------
;; IDLitsrvMacros::StopRecording
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
pro IDLitsrvMacros::StopRecording, oTool

    compile_opt idl2, hidden

    self->SetProperty, RECORDING=0

    self->UpdateMacroAvailability

    ; save this new macro so it isn't lost if editor is closed without saving
    self->SaveMacro, self._currentName

    ; Clear current name so that new additions go to new macro name
    self._currentName = ''

    success = oTool->DoUIService('/MacroEditor', self)

    return
end


pro IDLitsrvMacros::_MacroControlsUI, $
        SET_CURRENT_ITEM=setCurrentItem, $
        CHECK_EVENTS=checkEvents, $
        CURRENT_ITEM=currentItem, $
        DESTROY_CONTROLS=destroyControls, $
        REFRESH_TREE=refreshTree

    compile_opt idl2, hidden

    ; query the UI for a particular event or request
    ; dismissal by setting a property and calling the
    ; UI.  if one of the events is found the UI responds
    ; by setting a property on the macro service.
    nKeywordsSet = 0

    if keyword_set(setCurrentItem) then begin
        self._setCurrentItem=1
        nKeywordsSet++
    endif

    if keyword_set(checkEvents) then begin
        self._checkEvents=1
        nKeywordsSet++
    endif

    if keyword_set(destroyControls) then begin
        self._destroyControls=1
        nKeywordsSet++
    endif

    if keyword_set(refreshTree) then begin
        self._refreshTree=1
        nKeywordsSet++
    endif

    if keyword_set(currentItem) then begin
        self._currentItem=currentItem
        nKeywordsSet++
    endif

    ; invalid usage, only one keyword can be processed
    ; per call to this routine
    if nKeywordsSet gt 1 then $
        return

    ; default if no keywords is to launch the UI
    oSys = _IDLitSys_GetSystem()
    oTool = oSys->_GetCurrentTool()
    ; a macro might destroy the tool (File/Exit, for example)
    ; in this case, no need to destroy controls - they are
    ; already gone since their group leader was closed
    if obj_valid(oTool) then begin
        success = oTool->DoUIService('ControlMacro', self)
    endif else begin
        ; even if tool has been destroyed, we need to sensitize other tools
        ; and macro editor if this was the destroyControl message
        if keyword_set(destroyControls) then begin
            oSys->DoOnNotify, oSys->GetFullIdentifier(), $
                'SENSITIVE', 1
        endif
    endelse

end


function IDLitsrvMacros::_CheckMacroControlEvents

    compile_opt idl2, hidden

    breakLoop = 0

    ; Check the UI for an event on any of the controls on the
    ; dialog such as pause/continue, step, step delay, etc.
    ; If an event occurred the UI will update certain properties
    ; of the service.
    self->_MacroControlsUI, /CHECK_EVENTS

    ; Check the UI for an event on the step button
    ; If paused and a step occurred, the UI will update the step property
    ; the self._pauseMacro flag will stay set to keep paused
    ; after one macro step.  Step is only processed if paused
    ; and we haven't already gotten a step event.
    if self._pauseMacro && self._stepMacro then begin
        breakLoop = 1
        return, breakLoop
    endif

    ; If a stop event occurred or if a dismiss event occurred while paused
    ; the UI will update the stop macro property
    if self._stopMacro then begin
        breakLoop = 1
        return, breakLoop
    endif

    return, breakLoop

end


;-------------------------------------------------------------------------
; IDLitsrvMacros::RunMacro
;
; Purpose:
;
; Parameters:
; None.
;
; Keywords:
;   HIDE_CONTROLS: If this keyword is set then do not show the
;       macro controls dialog when running the macro.
;
function IDLitsrvMacros::RunMacro, macroName, HIDE_CONTROLS=hideControls

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()
    oTool = oSys->_GetCurrentTool()

    void = oTool->DoUIService("HourGlassCursor", self)

    oMacro = self->GetMacroByName(macroName)
    if ~obj_valid(oMacro) then begin
        ; this applies to RunMacro macro items with invalid names
        ; names specified via MACRO_NAMES at the command line
        ; have already been checked in IDLitSys_CreateTool
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:RunMacro:Text')+macroName], $
            title=IDLitLangCatQuery('Error:RunMacro:Title'), severity=2
        return, obj_new()
    endif

    self._currentMacroID = oMacro->GetFullIdentifier()
    self._pauseMacro = 0
    self._destroyControls = 0
    self._stopMacro = 0
    self._checkEvents = 0
    self._nestingLevel=self._nestingLevel++

    updatesDisabledByMacros = 0
    if ~self._displaySteps then begin
        oTool->DisableUpdates, $
            PREVIOUSLY_DISABLED=previouslyDisabled
        updatesDisabledByMacros = 1
    endif

    ; always create and show the UI
    if (~KEYWORD_SET(hideControls)) then self->_MacroControlsUI

    oItems = oMacro->Get(/ALL, COUNT=nItems)

    oProp = oTool->GetService("SET_PROPERTY")
    for i=0,nItems-1 do begin
        ; an item can change the tool, so get it again
        oTool = oSys->_GetCurrentTool()
        ; an operation can destroy the last current tool
        if ~obj_valid(oTool) then begin
            continue
        endif

        oItems[i]->_SetTool, oTool

        ; check for events triggering a change in behavior such as:
        ; pause/continue, step delay, step, stop
        self->_MacroControlsUI, /CHECK_EVENTS

        ; Update the UI with the current macro item
        self._currentItem = oItems[i]->GetFullIdentifier()
        self->_MacroControlsUI, /SET_CURRENT_ITEM

        while self._pauseMacro do begin
            ; spin (a fake modal behavior) and check for control events
            ; Check the UI for events such as stop, pause/continue,
            ; delay.  The return value is true if an event was
            ; found that should cause control to break out of this loop
            if self->_CheckMacroControlEvents() then $
                break

        endwhile

        ; if stop was set we want to break out of the macro item loop as well
        if self._stopMacro then $
            break

        oItems[i]->GetProperty, CLASSNAME=classname
        if classname eq 'IDLitOpSetProperty' then begin
            ; property bag
            ; get targets for property settings
            oTargets = oTool->GetSelectedItems(COUNT=nTargets)
            if nTargets eq 0 then begin
                oWin = oTool->GetCurrentWindow()
                if (~OBJ_VALID(oWin)) then $
                    return, OBJ_NEW()
                oView = oWin->GetCurrentView()
                oView->Select
                oTargets = oView
                nTargets = 1
            endif
            idTargets=strarr(nTargets)
            for j=0, nTargets-1 do begin
                idTargets[j] = oTargets[j]->GetFullIdentifier()
            endfor
            idProps = oItems[i]->QueryProperty()
            for k=0, n_elements(idProps)-1 do begin
                oItems[i]->GetPropertyAttribute, idProps[k], $
                    HIDE=hide, UNDEFINED=undefined
                ; Skip hidden or undefined properties.
                ; Also skip OBJ_NAME as it needs special
                ; handling, below
                ; Do not skip USERDEF props
                if (hide || undefined ||  $
                    (idProps[k] eq 'OBJ_NAME') || $
                    (idProps[k] eq 'USE_OBJ_NAME') || $
                    (idProps[k] eq 'OBJ_DESCRIPTION') || $
                    (idProps[k] eq 'USE_OBJ_DESCRIPTION')) then $
                    continue
                if ~oItems[i]->GetPropertyByIdentifier(idProps[k], value) then continue
                ; Do not add the individual SetProperty items to history.
                oCmd = oProp->DoAction(oTool, idTargets, idProps[k], value, $
                    /SKIP_MACROHISTORY)
            endfor
            ; special case for a NAME, description property
            if obj_isa(oItems[i], 'IDLitObjDescMacro') then begin
                oItems[i]->GetProperty, USE_OBJ_NAME=useObjName, $
                    USE_OBJ_DESCRIPTION=useObjDescription
                if useObjName then begin
                    oItems[i]->GetProperty, OBJ_NAME=objName
                    oCmd = oProp->DoAction(oTool, idTargets, "NAME", objName)
                endif
                if useObjDescription then begin
                    oItems[i]->GetProperty, OBJ_DESCRIPTION=objDescription
                    oCmd = oProp->DoAction(oTool, idTargets, "DESCRIPTION", objDescription)
                endif
            endif

            if self._displaySteps then $
                oTool->RefreshCurrentWindow

        endif else if (OBJ_ISA(oItems[i], 'IDLitObjDescVis')) then begin
            ; visualization
            ;;; ACY assuming annotation now, need to handle any vis
            ;;; Should only use annotation layer for regular vis objects
            oAnnotation = oItems[i]->GetObjectInstance()

            if obj_isa(oAnnotation, 'IDLitVisROI') then begin
                ; ACY:  need to get this from the VisROI
                targetClassnames = ["IDLitVisImage","IDLitVisSurface", $
                    "IDLitVisPlot"]
                oSelected = oTool->GetSelectedItems()
                if n_elements(oSelected) gt 0 && $
                    obj_valid(oSelected[0]) then begin

                    foundClass = 0
                    for j=0, n_elements(targetClassnames)-1 do begin
                        if strupcase(targetClassnames[j]) eq $
                            obj_class(oSelected[0]) then begin

                            foundClass = 1
                            break
                        endif
                    endfor
                    if foundClass then begin
                        oSelected[0]->Add, oAnnotation
                        oOperation = oTool->GetService('ANNOTATION') ;
                        oCmd = obj_new("IDLitCommandSet", $
                                                OPERATION_IDENTIFIER= $
                                                oOperation->getFullIdentifier())
                        iStatus = oOperation->RecordFinalValues( oCmd, $
                                                                 oAnnotation, $
                                                                 "")
                        oAnnotation->Select, /SKIP_MACRO
                    endif
                endif
            endif else begin
                oTool->Add, oAnnotation, layer='ANNOTATION'
                oOperation = oTool->GetService('ANNOTATION') ;
                oCmd = obj_new("IDLitCommandSet", $
                                        OPERATION_IDENTIFIER= $
                                        oOperation->getFullIdentifier())
                iStatus = oOperation->RecordFinalValues( oCmd, $
                                                         oAnnotation, $
                                                         "")
                oAnnotation->Select, /SKIP_MACRO
            endelse
        endif else begin
            ; operation
            ; don't need to explicitly refresh window if we are
            ; displaying intermediate steps (self._displaySteps==True)
            ; because the operation does a refresh
            ; (at least dataOperations do)
            idOperation = oItems[i]->GetFullIdentifier()
            oTarget = oItems[i]->GetObjectInstance()
            ; if we are single stepping and this is a single delay operation, skip it.
            ; similar to the way the step delay is skipped for single step mode.
            if ~(self._stepMacro && obj_isa(oTarget, 'IDLitOpMacroDelay')) then begin
                ; These commands are intentionally not added to the undo/redo buffer
                ; or history.
                ; The Run Macro operation is added as a reference to the actions taken,
                ; but adding the individual items causes duplication in history.
                if obj_isa(oTarget, 'IDLitOpRunMacro') then begin
                    self._nestingLevel++
                    ; save displaySteps and stepDelay
                    tempDisplaySteps = self._displaySteps
                    tempStepDelay = self._stepDelay
                endif

                oCmd = oTarget->DoAction(oTool)

                ; if we are popping out we need to refresh the tree
                if obj_isa(oTarget, 'IDLitOpRunMacro') then begin
                    self._currentMacroID = oMacro->GetFullIdentifier()
                    self->_MacroControlsUI, /REFRESH_TREE
                    ; Update the UI with the current macro item
                    self._currentItem = oItems[i]->GetFullIdentifier()
                    self->_MacroControlsUI, /SET_CURRENT_ITEM
                    self._nestingLevel--
                    ; restore displaySteps and stepDelay
                    self._displaySteps = tempDisplaySteps
                    self._stepDelay = tempStepDelay
                endif

                oTarget->GetProperty, $
                    MACRO_SUPPRESSREFRESH=MacroSuppressRefresh
                if self._displaySteps && ~obj_isa(oTarget, 'IDLitDataOperation') && $
                    ~MacroSuppressRefresh then begin
                        if obj_valid(oTool) then $
                            oTool->RefreshCurrentWindow
                endif
            endif
        endelse
        if n_elements(oCmd) gt 1 || obj_valid(oCmd) then $
            oCmdSet = (N_ELEMENTS(oCmdSet) gt 0) ? [oCmdSet, oCmd] : oCmd

        ; don't apply a delay after the last macro item
        ; don't cause the delay when stepping manually
        if self._stepDelay gt 0 && $
            i lt nItems-1 && $
            ~self._stepMacro then $
            WAIT, self._stepDelay

        ; clear this so that we resume looping in the spin loop
        if self._stepMacro then $
            self._stepMacro = 0

        ; displaySteps could change inside loop
        ; due to stepDisplayChange operation
        if ~self._displaySteps then begin
            if ~updatesDisabledByMacros then begin
              oTool->DisableUpdates, $
                    PREVIOUSLY_DISABLED=previouslyDisabled
                updatesDisabledByMacros = 1
            endif
        endif else begin
            if updatesDisabledByMacros && $
                ~previouslyDisabled then begin
                oTool->EnableUpdates
                oTool->RefreshCurrentWindow
                updatesDisabledByMacros = 0
            endif
        endelse
    endfor

    ; always destroy controls when macro finished
    ; this allows the next invocation of runmacro to
    ; rebuild the control dialog macro items tree
    ; with the correct macro items
    ;
    ; might need to skip this if we are running nested macros
    if self._nestingLevel eq 0 then begin
        self->_MacroControlsUI, /DESTROY_CONTROLS
    endif

    if ~self._displaySteps && ~previouslyDisabled then begin
        if obj_valid(oTool) then begin
            oTool->EnableUpdates
            oTool->RefreshCurrentWindow
        endif
    endif

    if (N_ELEMENTS(oCmdSet) gt 0) then begin
        oMacro->GetProperty, NAME=name
        oCmdSet[N_ELEMENTS(oCmdSet)-1]->SetProperty,name=name
        return, oCmdSet
    endif

    return,  obj_new()

end


;---------------------------------------------------------------------------
; IDLitsrvMacros::NewMacro
;
; Purpose:
;   Create a new empty macro folder
;
; Arguments:
;   newMacroName (input/output): The requested/resulting macro folder name
;
function IDLitsrvMacros::NewMacro, newMacroName, COPY=copy

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()

    if keyword_set(copy) then begin
        ; Choose a name based on the supplied name.
        newMacroName = self->_NewMacroName(newMacroName, /COPY)
    endif else begin
        ; Choose a new name (not already in use).
        newMacroName = self->_NewMacroName("New Macro")
    endelse

    ; Create the new folder
    oSys->CreateFolders, '/REGISTRY/MACROS/'+newMacroName, $
        CLASSNAME='IDLitMacroFolder', $
        FOLDER_ICON='gears', /NOTIFY
    oDesc = oSys->GetByIdentifier('/REGISTRY/MACROS/'+newMacroName)
    oDesc->SetPropertyAttribute, /SENSITIVE, ['NAME', 'DESCRIPTION']

    return, oDesc
end


;---------------------------------------------------------------------------
; IDLitsrvMacros::GetMacroByName
;
; Purpose:
;   Retrieve a macro object by name.
;
; Parameters:
;   Name: Name of the particular macro being requested
;
; Keywords:
;   None.
;
function IDLitsrvMacros::GetMacroByName, name

    compile_opt idl2, hidden

    oMacros = self->GetMacro(/ALL, COUNT=nMacros)
    for i=0,nMacros-1 do begin
        oMacros[i]->IDLitComponent::GetProperty, NAME=macroName
        if (STRCMP(macroName, name, /FOLD_CASE)) then $
            return, oMacros[i]
    endfor
    return, OBJ_NEW()
end


;---------------------------------------------------------------------------
; IDLitsrvMacros::GetMacro
;
; Purpose:
;   Used to gain external access to the Macro object
;   descriptors contained in the system.
;
; Parameters:
;   id   - ID of the particular macro being requested
;
; Keywords:
;  ALL    - Return All
;  COUNT  - The number of elements returned
;
function IDLitsrvMacros::GetMacro, id, ALL=all, COUNT=count

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()

    if (~KEYWORD_SET(all)) then begin
        oMacro = $
            oSys->IDLitContainer::GetbyIdentifier("/Registry/Macros/" + id)
        count = obj_valid(oMacro)
        return, oMacro
    endif

    oMacros = oSys->IDLitContainer::GetbyIdentifier("/Registry/Macros/")

    count = 0
    return, OBJ_VALID(oMacros) ? $
        oMacros->IDL_Container::Get(/ALL, COUNT=count) : OBJ_NEW()

end



;---------------------------------------------------------------------------
; IDLitsrvMacros::ImportMacro
;
; Purpose:
;   Import saved macros from files.
;
; Arguments:
;   macroFiles: The file name or names.
;
pro IDLitsrvMacros::ImportMacro, macroFiles, $
        ALLOW_OVERWRITE=allowOverwrite, $
        NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    notify = ~KEYWORD_SET(noNotify)

    oSys = _IDLitSys_GetSystem()

    importFuture = 0
    askedFuture = 0
    for i=0,N_ELEMENTS(macroFiles)-1 do begin
        futureMacro = 0
        ; First retrieve all structure/object classnames so we
        ; can instantiate the structures. This prevents the save file
        ; from restoring old object definitions, and also compiles all
        ; of the methods within the __define files.
        oSaveFile = OBJ_NEW('IDL_Savefile', macroFiles[i])
        contents = oSaveFile->Contents()
        if contents.description ne 'iTools Macro File' then begin
            OBJ_DESTROY, oSaveFile
            continue
        endif

        structs = oSaveFile->Names(COUNT=nstruct, /STRUCTURE_DEFINITION)
        OBJ_DESTROY, oSaveFile

        for j=0,nstruct-1 do $
            void = CREATE_STRUCT(NAME=structs[j])

        RESTORE, macroFiles[i], $
            RESTORED_OBJECTS=oObj, $
            /RELAXED_STRUCTURE_ASSIGNMENT

        ; perform check on version to see if this macro came from a
        ; future version of IDL.  If so, ask user and remember this
        ; answer for all others
        if n_elements(oObj[0]) && obj_valid(oObj[0]) then $
            oObj[0]->GetProperty, COMPONENT_VERSION=macroComponentVersion
        if n_elements(macroComponentVersion) gt 0 && $
            macroComponentVersion gt self.idlitComponentVersion then begin

            futureMacro = 1
            if ~askedFuture then begin
                message = [ $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro1') + ' ' + $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro2') + ' ' + $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro3') + ' ' + $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro4'), $
                    '', $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro5'), $
                    '', $
                    IDLitLangCatQuery('Message:Framework:ImportFutureMacro6') $
                ]
                status  = self->PromptUserYesNo(message, answer, $
                    TITLE=IDLitLangCatQuery('Error:ImportMacro:Title'))
                askedFuture = 1
                if (status && answer eq 1) then importFuture = 1
            endif
        endif

        ; Based on response to prompt, if user doesn't want to restore
        ; future version macros then skip this one
        if futureMacro && ~importFuture then $
            continue

        idx = WHERE(OBJ_ISA(oObj, 'IDLitComponent'), ncomp)
        for j=0,ncomp-1 do begin
            oObj[idx[j]]->Restore
            oObj[idx[j]]->UpdateComponentVersion
        endfor

        ; Hook the tool objref back up to all the objects.
        imsg = WHERE(OBJ_ISA(oObj, 'IDLitIMessaging'), nmsg)
        oTool = oSys->_GetCurrentTool()
        for j=0,nmsg-1 do begin
            oObj[imsg[j]]->_SetTool, oTool
        endfor

        if (~OBJ_VALID(oMacro)) then $
            continue

        ; Choose a new name (not already in use).
        if keyword_set(allowOverwrite) then begin
            oMacro->GetProperty, NAME=macroName
            ; delete existing macro by same name
            oMacroContainer = oSys->GetByIdentifier('/REGISTRY/MACROS')
            oMacroExisting = self->GetMacroByName(macroName)
            if ~obj_valid(oMacro) then $
                oMacroContainer->Remove, oMacroExisting
        endif else begin
            oMacro->GetProperty, NAME=macroName
            newMacroName = self->_NewMacroName(macroName)
            oMacro->SetProperty, NAME=newMacroName, $
                IDENTIFIER=STRUPCASE(newMacroName)
        endelse

        ; rename macros from future version
        if futureMacro then begin
            oMacro->GetProperty, NAME=macroName
            macroName = "(" + contents.release + ") " + macroName
            oMacro->SetProperty, NAME=macroName
        endif

        oSys->AddByIdentifier, '/REGISTRY/MACROS', oMacro
        if notify then begin
            oSys->DoOnNotify, '/REGISTRY/MACROS', "ADDITEMS", $
                oMacro->GetFullIdentifier()
        endif
    endfor

end


;---------------------------------------------------------------------------
; IDLitsrvMacros::RestoreMacros
;
; Purpose:
;   Remove existing macros and retrieve all saved macros.
;
pro IDLitsrvMacros::RestoreMacros

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()
    oMacroContainer = oSys->GetByIdentifier('/REGISTRY/MACROS')
    if oMacroContainer->Count() gt 0 then begin
        oMacros=oMacroContainer->Get(/ALL)
        oMacroContainer->Remove, /ALL
        obj_destroy, oMacros ; remove doesn't destroy them
    endif

    if (~IDLitGetResource('macros', path, /USERDIR)) then $
        return
    macroFiles = FILE_SEARCH(path, '*_macro.sav', COUNT=nmacros)

    if nmacros gt 0 then $
        self->ImportMacro, macroFiles, /ALLOW_OVERWRITE, /NO_NOTIFY

    ; Use updateitem, not just additems, so that the tree is rebuilt
    ; and the items removed above are eliminated.  This could include
    ; macros that have been created but not saved which need to be
    ; destroyed.
    oSys->DoOnNotify, '/REGISTRY/MACROS', "UPDATEITEM", '/REGISTRY/MACROS'

end


;---------------------------------------------------------------------------
; IDLitsrvMacros::SaveMacro
;
; Purpose:
;   Save all current macros.
;
pro IDLitsrvMacros::SaveMacro, macroName, filename

    compile_opt idl2, hidden

    ; SaveAllMacros checks this first for Save, but we can
    ; get here directly for Export.
    if LMGR(/DEMO) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:SaveDisabledDemo')], $
            title=IDLitLangCatQuery('Error:ExportMacro:Title'), severity=2
        return
    endif

    oMacro = self->GetMacroByName(macroName)
    if (~OBJ_VALID(oMacro)) then $
        return

    if n_elements(filename) eq 0 then begin
        if (~IDLitGetResource('macros', path, /USERDIR, /WRITE)) then $
            return
        oMacro->GetProperty, NAME=macroName
        ; default, save with name based on macro name
        ; filename may be supplied by user from Export...
        filename = path + PATH_SEP() + $
            STRLOWCASE(IDL_VALIDNAME(macroName, /CONVERT_ALL)) + $
            '_macro.sav'
    endif
    oMacro->GetProperty, _PARENT=oParent
    oMacro->SetProperty, _PARENT=OBJ_NEW()

    SAVE, oMacro, FILENAME=filename, /COMPRESS, $
        DESCRIPTION='iTools Macro File'
    oMacro->SetProperty, _PARENT=oParent

end


;---------------------------------------------------------------------------
; IDLitsrvMacros::SaveAllMacros
;
; Purpose:
;   Save all current macros.
;
pro IDLitsrvMacros::SaveAllMacros

    compile_opt idl2, hidden

    if LMGR(/DEMO) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:SaveDisabledDemo')], $
            title=IDLitLangCatQuery('Error:SaveMacros:Title'), severity=2
        return
    endif

    ; Delete all of our previous macro files.
    if (IDLitGetResource('macros', path, /USERDIR)) then begin
        macroFiles = FILE_SEARCH(path, '*_macro.sav', COUNT=noldmacros)
        if (noldmacros gt 0) then $
            FILE_DELETE, macroFiles, /QUIET
    endif

    oMacros = self->GetMacro(/ALL, COUNT=nmacros)

    for i=0,nmacros-1 do begin
        oMacros[i]->GetProperty, NAME=macroName
        self->SaveMacro, macroName
    endfor

end


;---------------------------------------------------------------------------
; IDLitsrvMacros::_DuplicateItem
;
; Purpose:
;   Duplicate a macro item.  Contains logic to determine the
;   type of the source objdesc and call the appropriate variety
;   of macro paste routine.
;
; Arguments:
;   oMacroSrc: the macro item to duplicate.
;
pro IDLitsrvMacros::_DuplicateItem, oMacroSrc, idDestination, idNewItem, _EXTRA=_extra

    compile_opt idl2, hidden

    oMacroSrc->GetProperty, NAME=name
    if strpos(name, "SetProperty") ge 0 then begin
        idProps = oMacroSrc->QueryProperty()
        ; skip NAME, DESCRIPTION here
        ; if we had a setproperty item where the user really wanted to
        ; change the name or description it would be in the OBJ_NAME
        ; or OBJ_DESCRIPTION properties.
        ; Expecting NAME, DESCRIPTION to be first two elements !
        idPropsNew = idProps[2:n_elements(idProps)-1]
        self->PasteMacroSetProperty, oMacroSrc, idDestination, $
            idNewItem, $
            idPropsNew, $
            _EXTRA=_extra
    endif else begin
        ; ACY::: this is not a complete test.  We need to get all the
        ; objdescs that are not operations.  Not sure how to do this yet
        if OBJ_ISA(oMacroSrc, 'IDLitObjDescVis') then begin
            self->PasteMacroVisualization, oMacroSrc, idDestination, $
                idNewItem, $
                _EXTRA=_extra
        endif else begin
            self->PasteMacroOperation, oMacroSrc, idDestination, $
                idNewItem, $
                _EXTRA=_extra
        endelse
    endelse
end

;---------------------------------------------------------------------------
; IDLitsrvMacros::Duplicate
;
; Purpose:
;   Duplicate a macro or macro item specified by ID.
;
; Arguments:
;   idMacroSrc: ID of the macro or macro item to duplicate.
;
pro IDLitsrvMacros::Duplicate, oMacroSrc, idDestination, idNewItem, _EXTRA=_extra

    compile_opt idl2, hidden

    for i=0,n_elements(oMacroSrc)-1 do begin
        if (OBJ_ISA(oMacroSrc[i], "IDLitContainer")) then begin
            oMacroSrc[i]->GetProperty, NAME=macroName
            idFolderProps = oMacroSrc[i]->QueryProperty()
            newMacroName = macroName
            ; newMacroName can and usually will change
            oNewFolder = self->NewMacro(newMacroName, /COPY)
            ; copy over the folder properties
            for j=0, n_elements(idFolderProps)-1 do begin
                if strupcase(idFolderProps[j]) eq 'NAME' then continue
                if (oMacroSrc[i]->GetPropertyByIdentifier(idFolderProps[j], value)) then $
                    oNewFolder->SetPropertyByIdentifier, idFolderProps[j], value
            endfor

            oItems = oMacroSrc[i]->Get(/ALL, COUNT=nitems)
            for i=0,nitems-1 do $
                self->_DuplicateItem, oItems[i], newmacroname, idNewItem, $
                    _EXTRA=_extra
        endif else begin
            ; if macro item selected, get the macro name
            ; if destination not supplied
            if n_elements(idDestination) eq 0 then $
                base = IDLitBaseName(oMacroSrc[i]->GetFullIdentifier(), remainder=idDestination)
            self->_DuplicateItem, oMacroSrc[i], idDestination, idNewItem, $
                _EXTRA=_extra
        endelse

    endfor

end

function IDLitsrvMacros::_EnsureUniqueIdentifier, idDestFolder, idRequest

    compile_opt idl2, hidden

    ; we may be attempting to add an identifier that already exists.
    ; get unique identifier based on the requested identifier
    ; This is necessary since REGISTER no longer does this - instead
    ; attempting to register an item with an identifier that already
    ; exists will replace the existing item, due to the fix for
    ; CR 37550.

    idReturn = idRequest

    oSys = _IDLitSys_GetSystem()
    oFolder = oSys->IDLitContainer::GetByIdentifier(idDestFolder)
    ; get the objects in this container and grab
    ; their relative identifiers.
    if obj_valid(oFolder) then begin
        oContained = oFolder->_IDLitContainer::Get(/all, count=nObjs)
        if (nObjs gt 0) then begin
            ; Get the list of idents in this container.
            sIDs = strarr(nObjs)
            for i=0, nObjs-1 do begin
               oContained[i]->IDLitComponent::GetProperty, IDENTIFIER=strID
               sIDs[i] = strID
            endfor
            strNewID = IDLitGetUniqueName(sIDs, idRequest)
            if (strNewID ne idRequest) then $
                idReturn=strNewID
        endif
    endif

    return, idReturn
end


;---------------------------------------------------------------------------
; IDLitsrvMacros::RegisterMacroItem
;
; Purpose:
;   Used to register a macro item for use by the system.
;
; Arguments:
;   Name: The name of the visualization or annotation item.
;
;   Classname: The classname for the visualization or annotation.
;
; Keywords:
;   IDENTIFIER: The name of the macro in which to place the item.
;       If this macro doesn't exist then a new macro container is
;       automatically created.
;
pro IDLitsrvMacros::RegisterMacroItem, strName, strClassName, $
    EDITOR=editor, $
    OBJ_DESCRIPTOR=objDescriptor, $
    SINGLETON=singleton, $
    SKIP_HISTORY=skipHistory, $
    SKIP_MACRO=skipMacro, $
    DESTINATION_FOLDER=destFolder,  $
    ID_MACROITEM=newIDMacroItem, $      ; output parameter, exists if recording or editor
    ID_HISTORYITEM=newIDHistoryItem, $  ; output parameter, exists if not editor
    IDENTIFIER=identifier, $
    IDTOOL=idTool, $                    ; passed in from tool prior to commit of operation
    _EXTRA=_extra

    compile_opt idl2, hidden

    oSys = _IDLitSys_GetSystem()
    if n_elements(idTool) eq 0 then begin
        oTool = oSys->_GetCurrentTool()
    endif else begin
        oTool = oSys->GetByIdentifier(idTool)
    endelse
    ; Need short id, not full id for history folder
    ; override existing idTool
    if obj_valid(oTool) then begin
        oTool->GetProperty, IDENTIFIER=idTool
    endif else return

    if n_elements(objDescriptor) eq 0 then $
        objDescriptor = 'IDLitObjDescTool'

    if n_elements(skipHistory) eq 0 then $
        skipHistory = 0
    if n_elements(skipMacro) eq 0 then $
        skipMacro = 0

    ; Add to Macro
    if (self._bRecording && ~skipMacro) || $
        keyword_set(editor) then begin

        ; destFolder may be full path to folder (supplied by editor)
        ; or only folder name.  add leading part of path if necessary
        if (strpos(destFolder, "/", 0, /reverse_search)) ne 0 then $
            destFolder = "/Registry/Macros/" + destFolder

        identifier = self->_EnsureUniqueIdentifier(destFolder, identifier)

        ; strip off name of selected item which should appear on history only
        if (strpos(strName, 'Selection Change:') ge 0) then $
            strNameMacro = "Selection Change" $
        else $
            strNameMacro = strName

        ; strip off name of selected tool which should appear on history only
        if (strpos(strName, 'Tool Change:') ge 0) then $
            strNameMacro = "Tool Change"

        oSys->Register, strNameMacro, strClassName, $
            FOLDER_CLASSNAME='IDLitMacroFolder', $
            FOLDER_ICON='gears', $
            OBJ_DESCRIPTOR=objDescriptor, $
            IDENTIFIER=destFolder + "/" + identifier, $
            FULL_IDENTIFIER=newIDMacroItem, $
            TOOL=oTool, $
            SINGLETON=singleton, $
            _EXTRA=_extra
        oFolder = oSys->IDLitContainer::GetByIdentifier(destFolder)
        if obj_valid(oFolder) then begin
            oFolder->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], $
                /SENSITIVE
        endif
    endif

    ; Add to History
    if ~keyword_set(editor) && $
        ~skipHistory then begin

        destFolderHistory = "/Registry/History/" + idTool
        identifier = self->_EnsureUniqueIdentifier(destFolderHistory, strName)

        oSys->Register, strName, strClassName, $
            OBJ_DESCRIPTOR=objDescriptor, $
            IDENTIFIER=destFolderHistory + '/' + $
                        identifier, $
            FULL_IDENTIFIER=newIDHistoryItem, $
            TOOL=oTool, $
            SINGLETON=singleton, $
            _EXTRA=_extra
    endif

end

pro IDLitsrvMacros::_CacheSpecialProperty, oSrcItem, oDesc, $
    propName, idProps, countRemaining

    compile_opt idl2, hidden

    ; only for classname 'IDLitOpSetProperty'
    ; If user wants to set the NAME property, we need to stash
    ; it elsewhere since the NAME of the objdescriptor needs to
    ; remain SetProperty.  Then when playing back the recording,
    ; if the NAME_OVERRIDE is set we will apply this to
    ; the actual NAME property of the targets.  We also set the
    ; flag property USE_OBJ_NAME so we know to retrieve
    ; the property back out.
    ; Similar for DESCRIPTION/OBJ_DESCRIPTION.
    ; Otherwise, record the property

    if countRemaining gt 0 then begin
        indices = where(idProps ne propName, countRemaining)
        if countRemaining lt n_elements(idProps) then begin
            if oSrcItem->GetPropertyByIdentifier(propName, objValue) then begin
                oDesc->SetPropertyByIdentifier, 'OBJ_'+propName, objValue
                oDesc->SetPropertyATTRIBUTE, 'OBJ_'+propName, HIDE=0
                ;oDesc->SetProperty, /USE_OBJ_NAME
                oDesc->SetPropertyByIdentifier, 'USE_OBJ_'+propName, 1
                if countRemaining gt 0 then $
                    idProps = idProps[indices]
            endif
        endif
    endif



end

pro IDLitsrvMacros::_CacheSpecialProperties, oSrcItem, oDesc, idProps, countRemaining

    compile_opt idl2, hidden

    countRemaining = n_elements(idProps)
    self->_CacheSpecialProperty, oSrcItem, oDesc, 'NAME', idProps, countRemaining
    self->_CacheSpecialProperty, oSrcItem, oDesc, 'DESCRIPTION', idProps, countRemaining

end


pro IDLitsrvMacros::_RetrieveSpecialProperty, oSrcItem, oDesc, propName

    compile_opt idl2, hidden

    ; only for classname 'IDLitOpSetProperty'
    ; If we have an objdesc with the OBJ_NAME set and
    ; we are copying this objdesc we need to set OBJ_NAME
    ; on the new objdesc.  We might have a vis, so check to see
    ; if this an objdesc.
    if obj_isa(oSrcItem, 'IDLitObjDescMacro') then begin
        if oSrcItem->GetPropertyByIdentifier('USE_OBJ_'+propName, useObjValue) then begin
            if useObjValue then begin
                ; get the value and cache it
                if oSrcItem->GetPropertyByIdentifier('OBJ_'+propName, objValue) then begin
                    oDesc->SetPropertyByIdentifier, 'OBJ_'+propName, objValue
                    oDesc->SetPropertyATTRIBUTE, 'OBJ_'+propName, HIDE=0
                    oDesc->SetPropertyByIdentifier, 'USE_OBJ_'+propName, 1
                endif
            endif
        endif
    endif
end

pro IDLitsrvMacros::_RetrieveSpecialProperties, oSrcItem, oDesc

    compile_opt idl2, hidden

    self->_RetrieveSpecialProperty, oSrcItem, oDesc, 'NAME'
    self->_RetrieveSpecialProperty, oSrcItem, oDesc, 'DESCRIPTION'

end



pro IDLitsrvMacros::_CopyNonSingletonProperties, oSrcItem, oDesc, idProps, $
    DESENSITIZE_USERDEF=desensitizeUserdef, $
    SENSITIVE=sensitive

    compile_opt idl2, hidden

    ; retrieve classname from destination, class of oSrcItem may be different
    ; for SetProperty item
    oDesc->GetProperty, CLASSNAME=classname

    if classname eq 'IDLitOpSetProperty' then $
        self->_CacheSpecialProperties, oSrcItem, oDesc, $
            idProps, countRemaining $
    else $
        countRemaining = n_elements(idProps)

    for i=0, countRemaining-1 do begin
        oDesc->RecordProperty, oSrcItem, idProps[i], /OVERWRITE
    endfor

    if classname eq 'IDLitOpSetProperty' then begin
        self->_RetrieveSpecialProperties, oSrcItem, oDesc
    endif

    if n_elements(sensitive) gt 0 then $
        oDesc->SetPropertyAttribute, idProps, SENSITIVE=sensitive

    ; can override setting of sensitive applied above
    ; can't have userdef props of setproperty items sensitive
    ; because the object isn't available to handle the setting
    ; note that userdef props of operations can be sensitive
    ; because they are singletons and the object's userdef
    ; code is accessible.
    if keyword_set(desensitizeUserdef) then begin
        for i=0, N_ELEMENTS(idProps)-1 do begin
            oDesc->GetPropertyAttribute, idProps[i], TYPE=type
            if type eq 0 then $
                oDesc->SetPropertyAttribute, idProps[i], SENSITIVE=0
        endfor
    endif

end



pro IDLitsrvMacros::_CopySingletonProperties, oSrcItem, oDesc, idProps, $
    DESENSITIZE_USERDEF=desensitizeUserdef, $
    SENSITIVE=sensitive

    compile_opt idl2, hidden

    ; Normally we would record properties into oDesc as follows:
    ;   oDesc->RecordProperties, oSrcItem, /OVERWRITE
    ; but oDesc is a singleton so we have to copy properties manually
    oItem = oDesc->GetObjectInstance()
    if (OBJ_VALID(oItem)) then begin
        for i=0, N_ELEMENTS(idProps)-1 do begin
            oDesc->GetPropertyAttribute, idProps[i], TYPE=type
            if type eq 0 && keyword_set(desensitizeUserdef) then begin
                oDesc->SetPropertyAttribute, idProps[i], SENSITIVE=0
                continue
            endif

            if oSrcItem->GetPropertyByIdentifier(idProps[i], value) then begin
                oItem->SetPropertyByIdentifier, idProps[i], value
            endif
        endfor
        if n_elements(sensitive) gt 0 then $
            oDesc->SetPropertyAttribute, idProps, SENSITIVE=sensitive
    endif

end
;---------------------------------------------------------------------------
; IDLitsrvMacros::_CreateMacroItem
;
; Purpose:
;   Duplicate a macro item and put it into a new or existing macro.
;
; Arguments:
;   oSrcItem: Object reference of the macro item to duplicate.
;
; ACY: may need to add current selection in tree as input parameter
; in order to place new item in list before/after selection

;
pro IDLitsrvMacros::_CreateMacroItem, oSrcItem, idDest, idMacroItem, idProps, $
    SHOW_EXECUTION_UI=showExecutionUI, $
    SINGLETON=singleton, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if n_elements(singleton) eq 0 then singleton=0

    oSys = _IDLitSys_GetSystem()

    ; Register our new macro item for this visualization.
    oSrcItem->GetProperty, $
        NAME=name, $
        DESCRIPTION=description, $
        IDENTIFIER=identifier

    ; for visualization such as annotation or container
    ; if not an obj desc, get classname
    if obj_isa(oSrcItem, 'IDLitObjDesc') then begin
        oSrcItem->GetProperty, $
            CLASSNAME=classname, $
            ICON=icon, $
            SKIP_HISTORY=skipHistory, $
            SKIP_MACRO=skipMacro
    endif else begin
        classname = obj_class(oSrcItem)
    endelse

    if (n_elements(idProps) gt 0) || $
        obj_isa(oSrcItem, 'IDLitObjDescMacro') $
    then begin
        if obj_isa(oSrcItem, 'IDLitObjDescMacro') then begin
            ; re-use name of copied objdesc
            oSrcItem->GetProperty, NAME=name
        endif else begin
            ; use selected properties only in the case of a property setting
            ; on an object
                oSrcItem->GetPropertyAttribute, idProps[0], NAME=propName
                name = 'SetProperty: ' + propName
            ; multiple properties may be specified from editor
            if n_elements(idProps) gt 1 then name = name + " ..."
        endelse

        classname = 'IDLitOpSetProperty'
        ; don't use description like "Plot" since these props
        ; will apply to anything selected
        description="Property Settings"
        ; don't use the supplied icon such as "plot"
        ; just use generic icon since props apply to any selected vis
        ICON='propsheet'
        objDescriptor = 'IDLitObjDescMacro'
    endif else begin
        ; leave objDescriptor undefined for default value
        ; get all properties (objdesc props are extra overhead but ok)
        ; in the case of an operation
        idProps = oSrcItem->QueryProperty()
    endelse

    ; Clear parens from history item if necessary
    if strpos(name, "(") eq 0 && $
            strpos(name, ")") eq strlen(name)-1 then begin
        name = strmid(name, 1, strlen(name)-2)
    endif

    self->RegisterMacroItem, name, classname, $
        DESCRIPTION=description, ICON=icon, $
        OBJ_DESCRIPTOR=objDescriptor, $
        SINGLETON=singleton, $
        SKIP_HISTORY=skipHistory, $
        SKIP_MACRO=skipMacro, $
        DESTINATION_FOLDER=idDest, $
        ID_MACROITEM=idMacroItem, $
        ID_HISTORYITEM=idHistoryItem, $
        IDENTIFIER=identifier, $
        _EXTRA=_extra

    if (n_elements(idMacroItem) gt 0) then $
        oDescMacro = oSys->GetByIdentifier(idMacroItem)
    if (n_elements(idHistoryItem) gt 0) then $
        oDescHistory = oSys->GetByIdentifier(idHistoryItem)

    if (singleton eq 0) then begin
        ; NON-SINGLETON, use of propertybag ok
        if obj_valid(oDescMacro) then begin
            self->_CopyNonSingletonProperties, oSrcItem, oDescMacro, $
                idProps, $
                /SENSITIVE, $
                _EXTRA=_extra
        endif
        if obj_valid(oDescHistory) then begin
            self->_CopyNonSingletonProperties, oSrcItem, oDescHistory, $
                idProps, $
                /SENSITIVE, $
                _EXTRA=_extra
         endif
    endif else begin
        ; SINGLETON, cannot use propertybag
        ; Normally we would record properties into oDesc as follows:
        ;   oDesc->RecordProperties, oSrcItem, /OVERWRITE
        ; but oDesc is a singleton so we have to copy properties manually
        if obj_valid(oDescMacro) then $
            self->_CopySingletonProperties, oSrcItem, oDescMacro, idProps

        if obj_valid(oDescHistory) then $
            self->_CopySingletonProperties, oSrcItem, oDescHistory, idProps
    endelse

    ; Set this AFTER copying properties from source, may be different
    ; from source
    if obj_valid(oDescMacro) then begin
        if n_elements(showExecutionUI) gt 0 then $
            oDescMacro->SetProperty, SHOW_EXECUTION_UI=showExecutionUI
        oDescMacro->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], $
            HIDE=(classname eq 'IDLitOpSetProperty')
    endif
    if obj_valid(oDescHistory) then begin
        if n_elements(showExecutionUI) gt 0 then $
            oDescHistory->SetProperty, SHOW_EXECUTION_UI=showExecutionUI
        oDescHistory->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], $
            HIDE=(classname eq 'IDLitOpSetProperty')
    endif

end


pro IDLitsrvMacros::AddProperties, oSrcItem, oDestItem, idProps, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->_CopyNonSingletonProperties, oSrcItem, oDestItem, idProps, $
        /SENSITIVE

end

pro IDLitsrvMacros::PasteMacroSetProperty, oSrcItem, idDest, idNewItem, idProps, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->_CreateMacroItem, oSrcItem, idDest, idNewItem, idProps, $
        /DESENSITIZE_USERDEF, $
        _EXTRA=_extra

end

pro IDLitsrvMacros::PasteMacroOperation, oSrcItem, idDest, idNewItem, $
    SHOW_EXECUTION_UI=showUI, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if n_elements(showUI) eq 0 then showUI=0

    self->_CreateMacroItem, oSrcItem, idDest, idNewItem, $
        ; default for all operations: hide dialogs
        ; can be changed in macro item by macro author after creation
        SHOW_EXECUTION_UI=showUI, $
        /SINGLETON, $
        _EXTRA=_extra

end

pro IDLitsrvMacros::PasteMacroVisualization, oSrcItem, idDest, idNewItem, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->_CreateMacroItem, oSrcItem, idDest, idNewItem, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
pro IDLitsrvMacros__define

    compile_opt idl2, hidden

    struct = {IDLitsrvMacros, $
        inherits IDLitOperation, $
        _bRecording: 0b,           $ ;; True if currently recording macro
        _checkEvents: 0b, $
        _displaySteps: 0b, $
        _destroyControls: 0b, $
        _refreshTree: 0b, $
        _currentName: '', $          ;; Name of current recording or copy destination
        _currentMacroID: '', $
        _currentItem: '', $
        _setCurrentItem:0b, $
        _manipulatorSteps: 0b, $
        _pauseMacro:0b, $
        _stepMacro:0b, $
        _stepDelay:0.0D, $
        _stopMacro:0L, $
        _nestingLevel:0L $
        }

end
