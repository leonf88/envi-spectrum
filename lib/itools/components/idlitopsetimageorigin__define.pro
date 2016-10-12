; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopsetimageorigin__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Class Name:
;   IDLitopSetImageOrigin
;
; Purpose:
;   This class implements an operation that sets an image origin.
;

;----------------------------------------------------------------------------
; Lifecycle Routines
;----------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitopSetImageOrigin::Init
;
; Purpose:
;   This function method initializes the component object.
;
; Return Value:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
function IDLitopSetImageOrigin::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitOperation::Init(NAME="Set Image Origin", $
        DESCRIPTION="Set image origin", $
        TYPES=['IDLIMAGE'], $
        SHOW_EXECUTION_UI=0, $
        _EXTRA=_extra)

    return, success

end

;-------------------------------------------------------------------------
; IDLitopSetImageOrigin::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopSetImageOrigin::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end

;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::GetProperty
;
; Purpose:
;   This procedure method retrieves the value(s) of one or more properties.
;
pro IDLitopSetImageOrigin::GetProperty, $
    TARGET=target, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(x)) then $
        x = self._x

    if (ARG_PRESENT(y)) then $
        y = self._y

    if (ARG_PRESENT(target)) then $
        target = self._oTarget

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::SetProperty
;
; Purpose:
;   This procedure method sets the value(s) of one or more properties.
;
pro IDLitopSetImageOrigin::SetProperty, $
    TARGET=target, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Note: presume that contraining to target is handled elsewhere.
    if (N_ELEMENTS(x) gt 0) then $
        self._x = x

    if (N_ELEMENTS(y) gt 0) then $
        self._y = y

    if (N_ELEMENTS(target) gt 0) then $
        self._oTarget = target

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::UndoOperation
;
; Purpose:
;   This function method performs an undo of the commands contained in
;   the given command set.
;
function IDLitopSetImageOrigin::UndoOperation, oCommandSet
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=nObjs-1, 0, -1 do begin

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        ; Retrieve initial origin.
        iStatus = oCmds[i]->GetItem("INITIAL_XORIGIN", xOrigin)
        if (iStatus eq 0) then $
            return, 0

        iStatus = oCmds[i]->GetItem("INITIAL_YORIGIN", yOrigin)
        if (iStatus eq 0) then $
            return, 0

        ; Reset the origin.
        oTarget->SetOrigin, xOrigin, yOrigin

    endfor

    return, 1

end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::RedoOperation
;
; Purpose:
;   This function method performs a redo of the commands contained in
;   the given command set.
;
function IDLitopSetImageOrigin::RedoOperation, oCommandSet
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=nObjs-1, 0, -1 do begin

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        ; Retrieve final origin.
        iStatus = oCmds[i]->GetItem("FINAL_XORIGIN", xOrigin)
        if (iStatus eq 0) then $
            return, 0

        iStatus = oCmds[i]->GetItem("FINAL_YORIGIN", yOrigin)
        if (iStatus eq 0) then $
            return, 0

        ; Reset the origin.
        oTarget->SetOrigin, xOrigin, yOrigin

    endfor

    return, 1

end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::RecordInitialValues
;
; Purpose:
;   This function method records all initial state for the target that
;   is required to allow an undo to be performed on the operation.
;
function IDLitopSetImageOrigin::RecordInitialValues, oCommandSet, oTarget, $
    idParameters

    compile_opt idl2, hidden

    ; Note: for this operation, only a single target is ever expected,
    ; so no need to perform a loop.
    if (~OBJ_VALID(oTarget)) then $
        return, 0

    oTarget->GetProperty, XORIGIN=xOrigin, YORIGIN=yOrigin

    ; Create a command that stores the initial origin values.
    oCmd = OBJ_NEW('IDLitCommand', $
        TARGET_IDENTIFIER=oTarget->GetFullIdentifier())

    iStatus = oCmd->AddItem("INITIAL_XORIGIN", xOrigin)
    if (iStatus eq 0) then $
        return, 0

    iStatus = oCmd->AddItem("INITIAL_YORIGIN", yOrigin)
    if (iStatus eq 0) then $
        return, 0

    oCommandSet->Add, oCmd

    return, 1
    
end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::RecordFinalValues
;
; Purpose:
;   This function method records all final state for the target that
;   is required to allow a redo to be performed on the operation.
;
function IDLitopSetImageOrigin::RecordFinalValues, oCommandSet, oTarget, $
    idParameters

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    ; Loop through and record current ranges for each target.
    oCmds = oCommandSet->Get(/ALL, COUNT=nCmds)
    for i=0, nCmds-1 do begin
        oCmd = oCmds[i]
        oCmd->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        ; Retrieve final origin.
        oTarget->GetProperty, XORIGIN=xOrigin, YORIGIN=yOrigin

        iStatus = oCmd->AddItem("FINAL_XORIGIN", xOrigin)
        if (iStatus eq 0) then $
            return, 0

        iStatus = oCmd->AddItem("FINAL_YORIGIN", yOrigin)
        if (iStatus eq 0) then $
            return, 0
    endfor

    return, 1
    
end

;---------------------------------------------------------------------------
; IDLitopSetImageOrigin::DoAction
;
; Purpose:
;   This function method performs an operation that sets the origin on 
;   a given target image.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oTool:	A reference to the tool in which this operation is occurring.
;
function IDLitopSetImageOrigin::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; This operation is a bit unique in that it depends upon
    ; another operation (crop image) to set its target.  If
    ; this has not occurred, then bail.
    if (~OBJ_VALID(self._oTarget)) then $
        return, OBJ_NEW()

    ; Get a commmand set for this operation from the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    iStatus = self->RecordInitialValues(oCommandSet, self._oTarget, '')
    if (iStatus eq 0) then begin
        OBJ_DESTROY, oCommandSet
        if (~wasDisabled) then $
            oTool->EnableUpdates
        return, OBJ_NEW()
    endif

    ; Set the origin.
    self._oTarget->SetOrigin, self._x, self._y

    iStatus = self->RecordFinalValues(oCommandSet, self._oTarget, '')
    if (iStatus eq 0) then begin
        void = self->UndoOperation(oCommandSet)
        OBJ_DESTROY, oCommandSet
        if (~wasDisabled) then $
            oTool->EnableUpdates
        return, OBJ_NEW()
    endif

    if (~wasDisabled) then $
        oTool->EnableUpdates

    ; Return command set.
    return, oCommandSet

end

;-------------------------------------------------------------------------
pro IDLitopSetImageOrigin__define

    compile_opt idl2, hidden

    struc = {IDLitopSetImageOrigin,   $
        inherits IDLitOperation,      $
        _x: 0.0,                      $
        _y: 0.0,                      $
        _oTarget: OBJ_NEW()           $  
    }

end

