; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituidirectory.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIFileOpen
;
; PURPOSE:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIFileOpen(Requester [, UVALUE=uvalue])
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
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIDirectory, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve working directory.
    oRequester->GetProperty, WORKING_DIRECTORY=workingDirectory

    directory = DIALOG_PICKFILE(/DIRECTORY, $
        PATH=workingDirectory, $
        TITLE=IDLitLangCatQuery('UI:UIOpen:Title'))

    if (directory eq '') then $
        return, 0

    oRequester->SetProperty, WORKING_DIRECTORY=directory

    return, 1
end

