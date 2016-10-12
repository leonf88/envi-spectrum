; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituifileopen.pro#1 $
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
function IDLitUIFileOpen, oUI, oRequester

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

    filter = oRequester->GetFilterList(COUNT=count)
    if (count eq 0) then $
        return, 0

    ; On Motif, the filters cannot have spaces between them.
    filter[*,0] = STRCOMPRESS(filter[*,0], /REMOVE_ALL)

    filenames = DIALOG_PICKFILE(DIALOG_PARENT=groupLeader, $
        FILTER=filter, $
        /MULTIPLE_FILES, $
        /MUST_EXIST, $
        GET_PATH=newDirectory, $
        PATH=workingDirectory, $
        TITLE=IDLitLangCatQuery('UI:UIOpen:Title'))

    if (filenames[0] eq '') then $
        return, 0

    WIDGET_CONTROL, /HOURGLASS

    oRequester->SetProperty, FILENAMES=filenames

    ; Set the new working directory if change_directory is enabled.
    if (OBJ_VALID(oTool) && KEYWORD_SET(changeDirectory)) then $
        oTool->SetProperty, WORKING_DIRECTORY=newDirectory

    return, 1
end

