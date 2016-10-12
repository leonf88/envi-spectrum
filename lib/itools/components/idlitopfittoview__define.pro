; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopfittoview__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopFitToView
;
; Purpose:
;   This class implements an operation that fits the selected
;   item to its view by appropriately setting the view zoom
;   factor.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::Init
;
; Purpose:
;   This function method initializes the object.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.
;
function IDLitopFitToView::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(NAME="Fit To View", $
        DESCRIPTION='Fit selection to the view', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopFitToView::Cleanup
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
; Name:
;   IDLitopFitToView::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopFitToView::Init followed by the word "Get" can be retrieved
;   using this method.
;
;pro IDLitopFitToView::GetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::GetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::SetProperty
;
; Purpose:
;   This procedure method sets the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopFitToView::Init followed by the word "Set" can be set
;   using this method.
;
;pro IDLitopFitToView::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Pixel Scale Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::_Targets
;
; Purpose:
;   This internal function method retrieves the list of targets
;   for this operation.
;
; Return Value:
;   This method returns a vector of object references to
;   the targets found for this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this
;     operation is being performed.
;
; Keywords:
;   COUNT:	Set this keyword to a named variable that upon
;     return will contain the number of returned targets.
;
function IDLitopFitToView::_Targets, oTool, COUNT=count

    compile_opt idl2, hidden

    count = 0

    if (OBJ_VALID(oTool) eq 0) then $
        return, OBJ_NEW()

    ; Retrieve the currently selected item(s) in the tool.
    oSelVis = oTool->GetSelectedItems(COUNT=nSel)
    if (nSel eq 0) then $
      return, OBJ_NEW()
    if (OBJ_VALID(oSelVis[0]) eq 0) then $
        return, OBJ_NEW()

    count = nSel

    return, oSelVis
end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopFitToView::_UndoRedo
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
function IDLitopFitToView::_UndoRedo, oCommandSet, REDO=redo

    ; Pragmas
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~Obj_Valid(oTool)) then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=nObjs-1, 0, -1 do begin
        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (~Obj_Valid(oTarget)) then $
            continue

        ; Retrieve the appropriate values.
        if (Keyword_Set(redo)) then begin
            iStatus = oCmds[i]->GetItem("FINAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then $
                return, 0
        endif else begin
            iStatus = oCmds[i]->GetItem("INITIAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then $
                return, 0
        endelse

        ; Apply the appropriate properties.
        oTarget->SetProperty, VISIBLE_LOCATION=visibleLoc
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopFitToView::UndoOperation
;
; Purpose:
;   This function performs an Undo of the commands contained in the 
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopFitToView::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet)
end


;---------------------------------------------------------------------------
; IDLitopFitToView::RedoOperation
;
; Purpose:
;   This function performs a Redo of the commands contained in the 
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopFitToView::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet, /REDO)
end

;---------------------------------------------------------------------------
; IDLitopFitToView::RecordInitialValues
;
; Purpose:
;   This function method records the initial values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
function IDLitopFitToView::RecordInitialValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    ; Loop through and record zoom properties for each target.
    for i=0, N_Elements(oTargets)-1 do begin
        if (~Obj_Valid(oTargets[i])) then $
            continue

        ; Retrieve the initial zoom property values.
        oTargets[i]->GetProperty, $
            VISIBLE_LOCATION=visibleLoc

        ; Create a command that stores the initial properties.
        oCmd = Obj_New('IDLitCommand', $
            TARGET_IDENTIFIER=oTargets[i]->GetFullIdentifier())

        iStatus = oCmd->AddItem("INITIAL_VISIBLE_LOCATION", visibleLoc)
        if (iStatus eq 0) then $
            return, 0

        oCommandSet->Add, oCmd
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopFitToView::RecordFinalValues
;
; Purpose:
;   This function method records the final values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
function IDLitopFitToView::RecordFinalValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~Obj_Valid(oTool)) then $
        return, 0

    ; Loop through and record current ranges for each target.
    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=0, nObjs-1 do begin
        oCmd = oCmds[i]
        oCmd->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (~Obj_Valid(oTarget)) then $
            continue

        ; Retrieve the final zoom property values.
        oTarget->GetProperty, $
            VISIBLE_LOCATION=visibleLoc

        iStatus = oCmd->AddItem("FINAL_VISIBLE_LOCATION", visibleLoc)
        if (iStatus eq 0) then $
            return, 0
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::DoAction
;
; Purpose:
;   This function method performs the primary action associated with
;   this operation, namely to fit the targets to the viewport.
;
; Return Value:
;   This function returns a reference to the command set object
;   corresponding to the act of performing this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this operation
;     is to be performed.
;
function IDLitopFitToView::DoAction, oTool

    compile_opt idl2, hidden

    self->_SetTool, oTool

    ; Retrieve the targets from among the selected items.
    oManipTargets = self->IDLitopFitToView::_Targets(oTool, COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()

    ; Walk up to the view.
    oManipTargets[0]->GetProperty, PARENT=oParent
    while (~OBJ_ISA(oParent, 'IDLitgrView')) do begin
        if (~OBJ_VALID(oParent)) then $
            break
        oChild = oParent
        oChild->GetProperty, PARENT=oParent
    endwhile
    if (~OBJ_VALID(oParent)) then $
        return, OBJ_NEW()
    oView = oParent

    ; Walk up to the window.
    oView->IDLgrViewGroup::GetProperty, _PARENT=oWin

    ; Retrieve our SetSubView service.
    oSetSubViewOp = oTool->GetService('SET_SUBVIEW')
    if (not OBJ_VALID(oSetSubViewOp)) then $
        return, OBJ_NEW()

    ; Create two command sets: one for view settings, one for window settigns.
    oViewCmdSet = Obj_New('IDLitCommandSet', $
        NAME='Fit to View', $
        OPERATION_IDENTIFIER=oSetSubViewOp->GetFullIdentifier())
    oWinCmdSet = Obj_New('IDLitCommandSet', $
        NAME='Fit to View', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier())

    ; Record initial values for undo.
    iStatus = oSetSubViewOp->RecordInitialValues(oViewCmdSet, $
        oView, 'CURRENT_ZOOM')
    if (~iStatus) then begin
        Obj_Destroy, [oViewCmdSet, oWinCmdSet]
        return, Obj_New()
    endif
    iStatus = self->RecordInitialValues(oWinCmdSet, $
        oWin, 'VISIBLE_LOCATION')
    if (~iStatus) then begin
        Obj_Destroy, [oViewCmdSet, oWinCmdSet]
        return, Obj_New()
    endif

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    oView->ZoomToFit, oManipTargets

    ; Since this operation changes view zooming, the current manipulator
    ; visuals for the tool may need to be reconfigured for the new zoom
    ; factor.
    oManip = oTool->GetCurrentManipulator()
    if (Obj_Valid(oWin)) then $
      oManip->ResizeSelectionVisuals, oWin

    if (~wasDisabled) then $
       oTool->EnableUpdates

    ; Record final values for redo.
    iStatus = oSetSubViewOp->RecordFinalValues( oViewCmdSet, $
        oView, 'CURRENT_ZOOM')
    if (~iStatus) then begin
        Obj_Destroy, [oViewCmdSet,oWinCmdSet]
        return, Obj_New()
    endif

    iStatus = self->RecordFinalValues( oWinCmdSet, $
        oWin, 'VISIBLE_LOCATION')
    if (~iStatus) then begin
        Obj_Destroy, [oViewCmdSet,oWinCmdSet]
        return, Obj_New()
    endif

    return, [oViewCmdSet, oWinCmdSet]
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitopFitToView__Define
;
; Purpose:
;   Define the object structure for the IDLitopFitToView class.
;
pro IDLitopFitToView__define

    compile_opt idl2, hidden

    struc = {IDLitopFitToView,    $
        inherits IDLitOperation   $
    }

end

