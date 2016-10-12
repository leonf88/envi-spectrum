; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopsetsubview__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopSetSubView
;
; Purpose:
;   This class implements an operation that modifies the sub-view
;   (i.e., the visible part of a zoomed virtual view) for one or 
;   more target views.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; IDLitopSetSubView::Init
;
; Purpose:
;   This function method initializes the object.
;
; Return Value:
;   This method returns a 1 on success, or 0 on failure.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.
;
function IDLitopSetSubView::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(_EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopSetSubView::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopSetSubView::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitOperation::Cleanup
;end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopSetSubView::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopSetSubView::Init followed by the word "Get" can be retrieved
;   using this method.
;
;pro IDLitopSetSubView::GetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::GetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; IDLitopSetSubView::SetProperty
;
; Purpose:
;   This procedure method sets the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopSetSubView::Init followed by the word "Set" can be set
;   using this method.
;
;pro IDLitopSetSubView::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopSetSubView::_UndoRedo
;
; Purpose:
;   This function method performs an Undo/Redo of the commands contained 
;   in the given command set.
;
; Return Value:
;   This method returns a 1 on success, or 0 on failure.
;
; Keywords:
;   REDO: Set this keyword to a non-zero value to perform a redo.
;     The default is to perform an undo.
;
function IDLitopSetSubView::_UndoRedo, oCommandSet, REDO=redo

    ; Pragmas
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

        ; Retrieve the appropriate values.
        if (KEYWORD_SET(redo)) then begin
            iStatus = oCmds[i]->GetItem("FINAL_ZOOM", zoom)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then return, 0

        endif else begin
            iStatus = oCmds[i]->GetItem("INITIAL_ZOOM", zoom)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then return, 0

        endelse

        ; Apply the appropriate properties.
        oTarget->SetCurrentZoom, zoom
        oTarget->SetProperty, VISIBLE_LOCATION=visibleLoc
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopSetSubView::UndoOperation
;
; Purpose:
;   This function performs an Undo of the commands contained in the 
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopSetSubView::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet)
end


;---------------------------------------------------------------------------
; IDLitopSetSubView::RedoOperation
;
; Purpose:
;   This function performs a Redo of the commands contained in the 
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopSetSubView::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet, /REDO)
end

;---------------------------------------------------------------------------
; IDLitopSetSubView::RecordInitialValues
;
; Purpose:
;   This function method records the initial values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
function IDLitopSetSubView::RecordInitialValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    ; Loop through and record zoom properties for each target.
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_VALID(oTargets[i]) eq 0) then $
            continue

        ; Retrieve the initial zoom property values.
        oTargets[i]->GetProperty, $
            CURRENT_ZOOM=zoom, $
            VISIBLE_LOCATION=visibleLoc

        ; Create a command that stores the initial properties.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oTargets[i]->GetFullIdentifier())

        iStatus = oCmd->AddItem("INITIAL_ZOOM", zoom)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_VISIBLE_LOCATION", visibleLoc)
        if (iStatus eq 0) then return, 0

        oCommandSet->Add, oCmd
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopSetSubView::RecordFinalValues
;
; Purpose:
;   This function method records the final values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
function IDLitopSetSubView::RecordFinalValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    ; Loop through and record current ranges for each target.
    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=0, nObjs-1 do begin
        oCmd = oCmds[i]
        oCmd->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        isNormalizer = OBJ_ISA(oTarget, 'IDLitVisNormalizer')

        ; Retrieve the final zoom property values.
        oTarget->GetProperty, $
            CURRENT_ZOOM=zoom, $
            VISIBLE_LOCATION=visibleLoc

        iStatus = oCmd->AddItem("FINAL_ZOOM", zoom)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_VISIBLE_LOCATION", visibleLoc)
        if (iStatus eq 0) then return, 0

    endfor

    return, 1
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
; IDLitopSetSubView__Define
;
; Purpose:
;   Define the object structure for the IDLitopSetSubView class.
;
pro IDLitopSetSubView__define

    compile_opt idl2, hidden

    struc = {IDLitopSetSubView,   $
        inherits IDLitOperation   $
    }

end

