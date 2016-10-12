; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitoporder__define.pro#2 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopOrder
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a property sheet is used.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopOrder::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopOrder::Init
;   IDLitopOrder::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopOrder::Init
;;
;; Purpose:
;; The constructor of the IDLitopOrder object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopOrder::Init, _EXTRA=_EXTRA
    compile_opt idl2, hidden

    ; Don't set TYPES since we want this to work with everything,
    ; including views.
    if (not self->IDLitOperation::Init(_EXTRA=_extra)) then $
        return, 0

    ; Register the operation and property this manipulator uses
    self->SetProperty, OPERATION_IDENTIFIER="ORDER"

    return, 1

end


;---------------------------------------------------------------------------
; IDLitopOrder::UndoOperation
;
; Purpose:
;  Undo the commands contained in the command set.
;
function IDLitopOrder::_UndoRedo, oCommandSet, REDO=redo

    ; Pragmas
    compile_opt idl2, hidden
    oTool = self->GetTool()
    if(not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)

    for i=nObjs-1, 0, -1 do begin

        ;; Get the object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oParent = oTool->GetByIdentifier(idTarget)

        if (not obj_valid(oParent)) then $
            continue

        if (oCmds[i]->GetItem('OLD_POSITION', oldPosition) and $
            oCmds[i]->GetItem('NEW_POSITION', newPosition)) then begin

            ; Switch new and old positions for redo.
            if (KEYWORD_SET(redo)) then begin
                tmp = newPosition
                newPosition = oldPosition
                oldPosition = tmp
            endif

            oParent->Move, newPosition, oldPosition
            oParent->OnDataChange
            oParent->OnDataComplete
        endif
  endfor

  return, 1
end

;---------------------------------------------------------------------------
; IDLitopOrder::UndoOperation
;
; Purpose:
;  Undo the commands contained in the command set.
;
function IDLitopOrder::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet)
end


;---------------------------------------------------------------------------
; IDLitopOrder::RedoOperation
;
; Purpose:
;  Redo the commands contained in the command set.
;
function IDLitopOrder::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet, /REDO)
end


;;---------------------------------------------------------------------------
;; IDLitopOrder::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopOrder::DoAction, oTool, type, TARGET=oTarget

    compile_opt idl2, hidden

    if (~ISA(oTarget)) then begin
      oTarget = oTool->GetSelectedItems()
      oTarget = oTarget[0]  ; just pick the first item for now
    endif
    
    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oTarget)) then begin
        if (~OBJ_VALID(oWindow)) then $
            return, OBJ_NEW()
        oTarget = oWindow->GetCurrentView()
    endif

    ; Retrieve the parent container.
    ; This assumes we have a PARENT property...
    oTarget->GetProperty, _PARENT=oParent
    
    ; Special case for dataspaces
    isDataspace = 0b
    if (ISA(oTarget, 'IDLitVisNormDataspace')) then begin
      oParent = oTarget->GetDataspaceRoot()
      isDataspace = 1b
    endif

    if (not OBJ_VALID(oParent)) then $
        return, obj_new()

    success = oParent->IsContained(oTarget, POSITION=position)
    count = oParent->Count()

    ; Don't see how this could fail if we got the parent successfully...
    if ((success eq 0) or (count eq 0)) then $
        return, obj_new()

    case type of
        'Bring Forward':  newposition = (position+1) < (count-1)
        'Bring to Front': newposition = (count-1)
        'Send Backward':  newposition = (position-1) > 0
        'Send to Back':   newposition = 0
        else: ; do nothing
    endcase

    if (newposition eq position) then $
        return, obj_new()

    oParent->Move, position, newposition

    ; Retrieve the new position, just in case it isn't where we think it
    ; moved. This can happen if the parent contains a selection visual or
    ; an axis, which are always kept at the end of the container.
    dummy = oParent->IsContained(oTarget, POSITION=newposition)

    ; Also move the parent dataspace forward/backward
    if (~isDataspace && ~ISA(oParent, 'IDLitgrLayer')) then $
      oCmd2 = self->IDLitOpOrder::DoAction(oTool, type, TARGET=oParent)
    
    ; Make sure we actually moved.
    if (newposition eq position) then $
        return, obj_new()

    ; Let's make a commmand set for this operation. This is produced
    ; by the super-class
    oCommandSet = self->IDLitOperation::DoAction(oTool)
    oCommandSet->SetProperty, NAME=type

    oCmd = OBJ_NEW('IDLitCommand', $
        TARGET_IDENTIFIER=oParent->GetFullIdentifier())
    void = oCmd->AddItem('OLD_POSITION', position)
    void = oCmd->AddItem('NEW_POSITION', newposition)
    oCommandSet->Add, oCmd

    if (ISA(oCmd2)) then $
      oCmd = [oCmd, oCmd2]

    ; Update the graphics hierarchy.
    oTool->RefreshCurrentWindow

    return, oCommandSet
end


;-------------------------------------------------------------------------
pro IDLitopOrder__define

    compile_opt idl2, hidden
    struc = {IDLitopOrder, $
        inherits IDLitOperation}

end

