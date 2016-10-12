; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopgroup__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; PURPOSE:
;   This file implements the statistics action.

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopGroup::Init
;
; Purpose:
; The constructor of the IDLitopGroup object.
;
; Parameters:
; None.
;
function IDLitopGroup::Init, _REF_EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    success = self->IDLitopGrouping::Init( $
        NAME="Group", $
        TYPE=['VISUALIZATION'], $
        DESCRIPTION="iTools Group", _EXTRA=_extra)

    return, success
end


;-------------------------------------------------------------------------
; IDLitopGroup::Cleanup
;
; Purpose:
; The destructor of the IDLitopGroup object.
;
; Parameters:
; None.
;
;pro IDLitopGroup::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;    self->IDLitopGrouping::Cleanup
;end


;---------------------------------------------------------------------------
; Purpose:
;  Undo the commands contained in the command set.
;
function IDLitopGroup::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    ; Call our superclass method.
    return, self->IDLitopGrouping::_DoUngroupCommand(oCommandSet)

end


;---------------------------------------------------------------------------
; Purpose:
;  Undo the commands contained in the command set.
;
function IDLitopGroup::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    ; Call our superclass method.
    return, self->IDLitopGrouping::_DoGroupCommand(oCommandSet)

end


;---------------------------------------------------------------------------
; Purpose:
;  Perform the Grouping operation on the selected items.
;
function IDLitopGroup::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; Get the selected objects.
    oSelVis = oTool->GetSelectedItems(COUNT=nVis)

    ; Nothing selected, or only 1 item.
    if (nVis le 1) then $
        return, OBJ_NEW()

    oSelVis[0]->GetProperty, _PARENT=oParent

    ; All selected objects must have the same parent.
    ; We also need to retrieve the positions.
    isContained = oParent->IsContained(oSelVis, POSITION=positions)
    if (MIN(isContained) eq -1) then $
        return, OBJ_NEW()

    ; We want to group objects in the same order as they were in their
    ; parent, not in their selection order.
    oSelVis = oSelVis[SORT(positions)]

    idSelVis = STRARR(nVis)
    idSelVis[0] = oSelVis[0]->GetFullIdentifier()

    for i=1, nVis-1 do $
        idSelVis[i] = oSelVis[i]->GetFullIdentifier()


    ; Let's make a commmand set for this operation. This is produced
    ; by the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)
    oCommandSet->SetProperty, NAME='Group'
    oCmd = OBJ_NEW('IDLitCommand')
    dummy = oCmd->AddItem('GROUPED_ITEMS', idSelVis)
    oCommandSet->Add, oCmd

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; Call our superclass method.
    dummy = self->IDLitopGrouping::_DoGroupCommand(oCommandSet, oSelVis)

    IF (~previouslyDisabled) THEN $
      oTool->EnableUpdates

    return, oCommandSet

end

;-------------------------------------------------------------------------
; IDLitopGroup::QueryAvailability
;
; Purpose:
;   This function method determines whether this object is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if the object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function IDLitopGroup::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    if (~Obj_Valid(oTool)) then return, 0
    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)

    ; Must have at least two items selected.
    if (nSelVis lt 2) then return, 0

    if (Min(Obj_Valid(oSelVis)) eq 0) then return, 0

    ; Get the first parent.
    oSelVis[0]->GetProperty, _PARENT=oParent
    if (~Obj_Valid(oParent)) then return, 0

    ; If all the other parents match then grouping is allowed.
    for i=1,nSelVis-1 do begin
        oSelVis[i]->GetProperty, _PARENT=oOtherParent
        if (oOtherParent ne oParent) then return, 0
    endfor

    ; All parents are the same. Success.
    return, 1
end

;-------------------------------------------------------------------------
pro IDLitopGroup__define

    compile_opt idl2, hidden

    struc = {IDLitopGroup, $
             inherits IDLitopGrouping $
            }

end

