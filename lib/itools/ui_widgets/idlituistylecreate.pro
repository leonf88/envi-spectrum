; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituistylecreate.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   This function implements the user interface for creating a style.
;   The Result is a success flag, either 0 or 1.
;
; Syntax:
;   Result = IDLituiStyleCreate(UI, Requester)
;
; Arguments:
;   UI: UI object that is calling this function.
;   Requester: The object reference for the operation requesting this UI.
;
; Keywords:
;   None.
;
; Written by:  CT, RSI, Jan 2004
; Modified:
;

;-------------------------------------------------------------------------
function IDLituiStyleCreate, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    result = IDLitwdStyleCreate(oUI, $
        CREATE_ALL=createAll, $
        GROUP_LEADER=groupleader)

    ; User hit cancel?
    if (result eq '') then $
        return, 0

    oRequester->SetProperty, CREATE_ALL=createAll, TEXT=result

    return, 1
end

