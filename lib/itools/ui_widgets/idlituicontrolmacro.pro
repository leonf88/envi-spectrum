; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituicontrolmacro.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiControlMacro
;
; PURPOSE:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiControlMacro(Requester [, UVALUE=uvalue])
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:  AY, RSI, Dec 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiControlMacro, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    IDLitwdControlMacro, oUI, oRequester, $
        GROUP_LEADER=groupLeader

    return, 1

end

