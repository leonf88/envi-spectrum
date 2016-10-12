; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiimportwizard.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;---------------------------------------------------------------------------
;+
; NAME:
;   IDLitUIImportWizard
;
; PURPOSE:
;   This function implements the user interface for the gridding wizard.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIImportWizard(oUI, oRequester)
;
; INPUTS:
;   UI - UI objref.
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIImportWizard, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    result = IDLitwdImportWizard(oUI, oRequester, $
        GROUP_LEADER=groupLeader)

    return, result
end

