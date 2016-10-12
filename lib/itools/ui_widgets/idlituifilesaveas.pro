; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituifilesaveas.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; Syntax:
;   Result = IDLitUIFileSaveAs(UI, Requester)
;
; Arguments:
;   UI: UI object that is calling this function.
;   Requester: The object reference for the operation requesting this UI.
;
; Keywords:
;   None.
;
; Written by:  CT, RSI, March 2003
; Modified:
;

;-------------------------------------------------------------------------
function IDLitUIFileSaveAs, oUI, oRequester

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch,/cancel
        oRequester->ErrorMessage, $
            TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], severity=2
        return, 0
    endif

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve working directory.
    oTool = oUI->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oTool->GetProperty, $
            CHANGE_DIRECTORY=changeDirectory, $
            WORKING_DIRECTORY=workDir
    endif

    oRequester->GetProperty, NAME=operationName, FILENAME=initFile
    filter = oRequester->GetFilterList(COUNT=count)
    if (count eq 0) then $
        return, 0

    ; On Motif, the filters cannot have spaces between them.
    filter[*,0] = STRCOMPRESS(filter[*,0], /REMOVE_ALL)

    ; Always specify a value for the DEFAULT_EXTENSION so the appropriate
    ; file extension will be added if the user does not specify one
    pos = STRPOS(filter[0,0], '.')
    if (pos ge 0) then $
      defaultExtension = STRMID(filter[0,0], pos+1, 3) $
    else $
      defaultExtension = filter[0,0]

    ; Ensure that Windows uses the correct path separator, since the native
    ; dialog does not allow '/' as a separator.
    if (!version.os_family eq 'Windows') then begin
        initFile = STRJOIN(STRSPLIT(initFile, '/', /EXTRACT, /PRESERVE_NULL), '\')
        workDir = STRJOIN(STRSPLIT(workDir, '/', /EXTRACT, /PRESERVE_NULL), '\')
    endif

    title = (N_ELEMENTS(operationName) && operationName ne '') ? $
      operationName : IDLitLangCatQuery('UI:UISaveAs:Title')
      
    filename = DIALOG_PICKFILE( $
        DEFAULT_EXTENSION=defaultExtension, $
        DIALOG_PARENT=groupLeader, $
        FILE=initFile, $
        FILTER=filter, $
        /OVERWRITE_PROMPT, $
        GET_PATH=newDirectory, $
        PATH=workDir, $
        TITLE=title, $
        /WRITE)

    WIDGET_CONTROL, /HOURGLASS

    ; User hit cancel?
    if (filename eq '') then $
        return, 0

    oRequester->SetProperty, FILENAME=filename

    ; Set the new working directory if change_directory is enabled.
    if (OBJ_VALID(oTool) && KEYWORD_SET(changeDirectory)) then $
        oTool->SetProperty, WORKING_DIRECTORY=newDirectory

    return, 1
end

