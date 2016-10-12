; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopinsertview__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Insert View operation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopInsertView object.
;
; Parameters:
;   None.
;
;-------------------------------------------------------------------------
;function IDLitopInsertView::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; Purpose:
;   Undo the commands contained in the command set.
;
function IDLitopInsertView::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0

    oCommandSet->GetProperty, TARGET_IDENTIFIER=idView
    oView = oTool->GetByIdentifier(idView)
    if (~OBJ_VALID(oView)) then $
        return, 0

    ; Just remove & destroy the old view. This is easier
    ; than trying to cache it.
    oWin->Remove, oView
    OBJ_DESTROY, oView

    oCommandSet->SetProperty, TARGET_IDENTIFIER=''

    return, 1

end


;---------------------------------------------------------------------------
; Purpose:
;   Redo the commands contained in the command set.
;
function IDLitopInsertView::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    ncontained = oWin->Count()

    ; Create the new view and add it.
    oView = OBJ_NEW('IDLitgrView', $
        NAME='View_'+STRTRIM(ncontained+1,2), $
        TOOL=oTool)

    oWin->Add, oView
    oWin->UpdateView, oView

    ; Replace the old ID with the new one.
    oCommandSet->SetProperty, TARGET_IDENTIFIER=oView->GetFullIdentifier()

    return, 1



end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the Insert View operation.
;
; Arguments:
;   Tool: Objref of the current tool.
;
function IDLitopInsertView::DoAction, oTool, NO_DRAW=noDraw

    compile_opt idl2, hidden

    oCmd = OBJ_NEW("IDLitCommand", NAME='Insert View', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier())

    ; Use our redo method, to avoid duplicate code.
    if (~self->RedoOperation(oCmd)) then $
        OBJ_DESTROY, oCmd

    oTool = self->GetTool()
    oTool->RefreshCurrentWindow

    return, oCmd
end


;-------------------------------------------------------------------------
pro IDLitopInsertView__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertView, $
        inherits IDLitOperation}

end

