; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopgrouping__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; PURPOSE:
;   This file implements the statistics action.

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopGrouping::Init
;
; Purpose:
; The constructor of the IDLitopGrouping object.
;
; Parameters:
; None.
;
function IDLitopGrouping::Init, _REF_EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    success = self->IDLitOperation::Init( $
        NAME="Grouping", $
        TYPE=['VISUALIZATION'], $
        DESCRIPTION="iTools Group", _EXTRA=_extra)

    return, success
end


;-------------------------------------------------------------------------
; IDLitopGrouping::Cleanup
;
; Purpose:
; The destructor of the IDLitopGrouping object.
;
; Parameters:
; None.
;
;pro IDLitopGrouping::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
function IDLitopGrouping::_Group, oSelVis

    compile_opt idl2, hidden


    oGroup = OBJ_NEW('IDLitVisGroup')
    ; Create a unique identifier from the object heap id.
    str = STRING(oGroup, /PRINT)
    oGroup->SetProperty, IDENTIFIER='GROUP_' + $
        STRMID(str, 11, STRPOS(str,'(')-11)

    isManipTarget = 1

    for i=0, N_ELEMENTS(oSelVis)-1 do begin

        oSubVis = oSelVis[i]

        ; Information we need to store about each viz.
        oSubVis->_IDLitVisualization::GetProperty, $
            MANIPULATOR_TARGET=manipTarget, $
            PRIVATE=private, $
            _PARENT=oParent

        ; If one of my grouped items isn't a manip target,
        ; then disable it for the entire group.
        if (~manipTarget) then $
            isManipTarget = 0

        ; Hide my grouped items from the viz browser.
        oSubVis->_IDLitVisualization::SetProperty, /PRIVATE

        if (i eq 0) then $
            oParent->Add, oGroup

        ; Remove grouped item from its parent and add to myself.
        oParent->Remove, oSubVis

        ; The Group::Add will also GROUP and AGGREGATE.
        oGroup->Add, oSubVis

    endfor

    oGroup->SetProperty, MANIPULATOR_TARGET=isManipTarget

    oGroup->UpdateSelectionVisual

    return, oGroup
end


;---------------------------------------------------------------------------
function IDLitopGrouping::_Ungroup, oGroup, COUNT=count

    compile_opt idl2, hidden

    oVis = oGroup->Get(/ALL)
    good = WHERE(~OBJ_ISA(oVis, 'IDLitManipulatorVisual'), count)
    if (count eq 0) then begin
        OBJ_DESTROY, oGroup
        return, OBJ_NEW()
    endif
    oVis = oVis[good]

    ; Remove all of my grouped items.
    oGroup->Remove, oVis, /NO_NOTIFY

    oGroup->GetProperty, $
        _PARENT=oGroupParent, TRANSFORM=groupTransform

    ; Remove myself from my groupparent.
    oGroupParent->Remove, oGroup

    ; We need to destroy our group each time. This seems wasteful,
    ; especially if the user does an Undo/Redo. However, if the user did
    ; a Group followed by an Undo, we have no way to know when to destroy
    ; the Group object. I tried caching the Group object within the
    ; Command Set but then it gets reaped automatically if the Undo/Redo
    ; command buffer gets cleared out.
    OBJ_DESTROY, oGroup

    ; Restore all grouped items to their parents
    ; and their reset their properties.
    for j=0,count-1 do begin

        oSubVis = oVis[j]

        oSubVis->_IDLitVisualization::GetProperty, $
            TRANSFORM=myTransform

        ; Set my grouped item properties back to original.
        ; We need to premultiply our group transform back onto
        ; the transform of each item, to pick up any group
        ; transformations.
        ;
        ; Note: This assumes that PRIVATE=0 on the original vis.
        ; This should be true if the vis was able to be added to the group
        ; in the first place.
        ;
        oSubVis->_IDLitVisualization::SetProperty, PRIVATE=0, $
            TRANSFORM=groupTransform ## myTransform

        oGroupParent->Add, oSubVis

    endfor

    return, oVis
end


;---------------------------------------------------------------------------
; Purpose:
;  Use the commands contained in the command set to do Grouping.
;
function IDLitopGrouping::_DoGroupCommand, oCommandSet, oSelVis

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if(not obj_valid(oTool))then $
        return, 0

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    oWin->ClearSelections

    oCmds = oCommandSet->Get(/ALL, COUNT=nGroups)

    for i=0, nGroups-1 do begin

        ; Retrieve the ids of the items to group.
        if (~oCmds[i]->GetItem('GROUPED_ITEMS', idItems)) then $
            continue

        ; Retrieve the objrefs of the items to group.
        nItems = N_ELEMENTS(idItems)
        oItems = OBJARR(nItems)
        for j=0,nItems-1 do $
            oItems[j] = oTool->GetByIdentifier(idItems[j])

        ; Call our superclass method.
        oGroup = self->IDLitopGrouping::_Group(oItems)

        ; New group identifier.
        oCmds[i]->SetProperty, $
            TARGET_IDENTIFIER=oGroup->GetFullIdentifier()

        oSelect = (N_ELEMENTS(oSelect) gt 0) ? [oSelect, oGroup] : oGroup
    endfor

    ; Automatically select all our items.
    for i=0,N_ELEMENTS(oSelect)-1 do $
        oSelect[i]->Select, /ADDITIVE

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Purpose:
;  Use the commands contained in the command set to do Ungrouping.
;
function IDLitopGrouping::_DoUngroupCommand, oCommandSet

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if(not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    if (nObjs eq 0) then $
        return, 0

    ; Clear all selected items.
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    oWin->ClearSelections

    for i=0, nObjs-1 do begin

        ;; Get the object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget

        oGroup = oTool->GetByIdentifier(idTarget)
        if (not OBJ_VALID(oGroup)) then $
            continue

        ; Call our superclass method.
        oVis = self->IDLitopGrouping::_Ungroup(oGroup, COUNT=count)
        if (count eq 0) then $
            continue

        oSelect = (N_ELEMENTS(oSelect) gt 0) ? $
            [oSelect, oVis] : oVis
    endfor

    ; Automatically select all our items.
    for i=0,N_ELEMENTS(oSelect)-1 do $
        oSelect[i]->Select, /ADDITIVE

    return, 1  ; success
end


;---------------------------------------------------------------------------
; We have no DoAction since our subclasses should be doing all the work.
;
;function IDLitopGrouping::DoAction, oTool, action
;    compile_opt idl2, hidden
;    return, obj_new()   ; no undo/redo command
;end


;-------------------------------------------------------------------------
pro IDLitopGrouping__define

    compile_opt idl2, hidden

    struc = {IDLitopGrouping, $
             inherits IDLitOperation $
            }

end

