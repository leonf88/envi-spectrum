; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituifileexport.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIFileExport
;
; PURPOSE:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIFileExport(Requester [, UVALUE=uvalue])
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
function IDLitUIFileExport, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve working directory.
    oTool = oUI->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oTool->GetProperty, $
            CHANGE_DIRECTORY=changeDirectory, $
            WORKING_DIRECTORY=workingDirectory
    endif

    filter = oRequester->GetFileExtensions()
    filter = '*.' + filter

    filename = DIALOG_PICKFILE(DIALOG_PARENT=groupLeader, $
        FILTER=filter, $
        /OVERWRITE_PROMPT, $
        GET_PATH=newDirectory, $
        PATH=workingDirectory, $
        TITLE=IDLitLangCatQuery('UI:UIExport:Title'), $
        /WRITE)

    if (N_ELEMENTS(filename) eq 0) then $
        return, 0

    WIDGET_CONTROL, /HOURGLASS

    oRequester->SetProperty, FILENAME=filename

    ; Set the new working directory if change_directory is enabled.
    if (OBJ_VALID(oTool) && KEYWORD_SET(changeDirectory)) then $
        oTool->SetProperty, WORKING_DIRECTORY=newDirectory

    return, 1
end

