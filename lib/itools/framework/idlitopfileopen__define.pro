; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfileopen__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a file is opened.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitOpFileOpen::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if(self->IDLitOperation::Init(/MACRO_SHOWUIIFNULLCMD, $
                                _EXTRA=_SUPER) eq 0)then $
      return, 0

    ; this is registered property allows the semicolon separated
    ; list of files to be displayed in the property sheet.  Changes
    ; to this property will cause updates to the the non-registered
    ; _FILENAMES property that stores the data.
    self->RegisterProperty, 'FILENAMES', /STRING, $
        NAME='Filenames', $
        Description='Filenames'

    self._fileNames = PTR_NEW('')

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor of the object.
;
; Arguments:
;   None.
;
pro IDLitopFileOpen::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._fileNames
    self->IDLitOperation::Cleanup
end


;-------------------------------------------------------------------------
; Purpose:
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Get.
;
pro IDLitopFileOpen::GetProperty, FILENAMES=fileNames, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; registered property for user display
    ; data is stored in _filenames
    if (ARG_PRESENT(fileNames)) then $
        filenames = STRJOIN(*self._fileNames, ';')

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose:
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Set.
;
pro IDLitopFileOpen::SetProperty, FILENAMES=fileNames, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; registered property for user display
    ; data is stored in _filenames
    nfiles = N_ELEMENTS(fileNames)
    if (nfiles gt 0) then begin
        if (nfiles eq 1) then begin
            ; String with filenames separated by semicolons (from macros).
            names = strsplit(fileNames, ';', /extract)
            *self._fileNames = n_elements(names) gt 0 ? names : ''
        endif else begin
            ; Array of filenames (from UI service).
            *self._fileNames = fileNames
        endelse
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopFileOpen::DoAction
;
; Purpose:
;    used to read data from a file and create the default viz.
;
; Parameters:
;  oTool   - The tool we are operating in.
;
; Return Value
;   Command if created.
;
function IDLitOpFileOpen::DoAction, oTool, IDENTIFIER=identifier, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get the vis create operation and create the visualizations.
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    if(not obj_valid(oCreateVis))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotCreateVizService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
    endif

    ; Do we have our File Reader service?
    oReadFile = oTool->GetService("READ_FILE")
    if(not obj_valid(oReadFile))then begin
        self->ErrorMessage, $
        [IDLitLangCatQuery('Error:Framework:CannotAccessReaderService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, obj_new()
    endif

    ; Ask the UI service to present the file selection dialog to the user.
    ; The caller sets my filenames property before returning.
    ; This should also call my GetFilterList().
    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI
    if (showUI) then begin
        success = oTool->DoUIService('FileOpen', self)
        if (success eq 0) then $
            return, obj_new()
    endif

    ; check our filename cache
    nFiles = N_ELEMENTS(*self._fileNames)
    if(nFiles eq 0)then $
      return, obj_new()

    ; At this point we want to read in data and place it in the data
    ; manager. After data is in the data manager, we get it's
    ; identifer and place that in a data id array. At the end of the
    ; loop, the CreateVis service is called to handle the rest.
    nData =0
    ; Repeat for each file selected by the user.
    for i=0, nFiles-1 do begin
        status = oReadFile->ReadFile((*self._fileNames)[i], oData)
        ; Throw an error message.
        if (status eq 0) then begin
            self->ErrorMessage, /USE_LAST_ERROR, $
              title=IDLitLangCatQuery('Error:Error:Title'), severity=2, $
              [IDLitLangCatQuery('Error:Framework:FileReadError'), $
              (*self._fileNames)[i]]
        endif
        if (status ne 1) then $   ; user hit cancel or error occurred
            continue
        ; Add data to the data manager!
        nTmp = n_elements(oData)
        oTool->AddByIdentifier, "/Data Manager", oData

        oAllData = (nData eq 0 ? temporary(oData) :  $
                      [oAllData, temporary(oData)])
        nData+=nTmp
    endfor

    ; We never received any data. Either all of the files were bad,
    ; or the user hit cancel on some dialog, or we were restoring
    ; a save state file.
    if (nData eq 0) then $
        return, OBJ_NEW()

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    if (nFiles eq 1) then begin
        filename = FILE_BASENAME((*self._fileNames)[0])
        pos = STRPOS(filename, '.', /REVERSE_SEARCH)
        if (pos gt 0) then $
            filename = STRMID(filename, 0, pos)
    endif

    ; Okay, if we had a data, call create vis
    oVisCmd = oCreateVis->CreateVisualization(oAllData, $
        FOLDER_NAME=filename, _EXTRA=_extra)

   if (~previouslyDisabled) then $
       oTool->EnableUpdates

    return, oVisCmd

end


;---------------------------------------------------------------------------
; Purpose:
;   Basically for the UI service to provide a callback to this
;   object.
;
function IDLitOpFileOpen::GetFilterList, COUNT=count

   compile_opt idl2, hidden

   oTool = self->GetTool()
   oReadFile = oTool->GetService("READ_FILE")
   if(not obj_valid(oReadFile))then begin
       count = 0
       return,''
   endif

   return, oReadFile->GetFilterList(COUNT=count, /system) ;include system filter
end


;-------------------------------------------------------------------------
pro IDLitOpFileOpen__define

    compile_opt idl2, hidden

    struc = {IDLitOpFileOpen,     $
        inherits IDLitOperation,  $
        _fileNames: PTR_NEW()     $
        }

end

