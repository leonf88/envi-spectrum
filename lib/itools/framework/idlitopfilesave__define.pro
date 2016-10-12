; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfilesave__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a file is saved.
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
; Keywords:
;   All superclass keywords.
;
function IDLitopFileSave::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Default is to not show the File Selection dialog,
    ; so set SHOW_EXECUTION_UI to zero.
    if(self->IDLitOperation::Init(SHOW_EXECUTION_UI=0, $
        _EXTRA=_extra) eq 0)then $
      return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'FILENAME', /STRING, $
        NAME='Filename', $
        Description='Name of the saved file'

    self._fileName = 'untitled'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopFileSave::SetProperty, _EXTRA=_extra

    return, 1
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
pro IDLitopFileSave::GetProperty, $
    FILENAME=fileName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(fileName)) then $
        fileName = self._fileName

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
pro IDLitopFileSave::SetProperty, $
    FILENAME=fileName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(fileName) gt 0 ) then $
        self._fileName = fileName

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopFileSave::_GetImageItem, oTool, types

  compile_opt idl2, hidden
  
  oSaveItem = oTool->GetSelectedItems(COUNT=count)
  oSaveItem = oSaveItem[0]
  
  ; If nothing selected, just save the entire window.
  if (~Obj_Valid(oSaveItem)) then begin
    return, oTool->GetCurrentWindow()
  endif
  
  oSaveItem->GetProperty, TYPE=type
  
  ; If the selected item matches one of our writer types, then save it.
  if (Max(types eq type) eq 1) then begin
    return, oSaveItem
  endif

  return, oSaveItem
  
end


;---------------------------------------------------------------------------
; IDLitopFileSave::_Save
;
; Purpose:
;   Used to save the iTool state.
;
; Parameters:
;   oTool   - The tool we are operating in.
;
; Return Value
;   Success (1), Failure (0), or Cancel (-1).
;
function IDLitopFileSave::_Save, oTool, _EXTRA=_extra

    compile_opt idl2, hidden

tryAgain:
    if (LMGR(/DEMO)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:SaveDisabledDemo')], severity=2
        return, 0
    endif

    ; Do we have our File Writer service?
    oWriteFile = oTool->GetService("WRITE_FILE")
    if(not obj_valid(oWriteFile))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotAccessWriterService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, 0
    endif

    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI

    badName = (self._filename eq '') || $
        STRCMP(self._filename, 'untitled', /FOLD_CASE)

    ; If we don't have a valid name, see if the Tool does.
    if (badName) then begin
        oTool->GetProperty, TOOL_FILENAME=filename
        self._filename = filename
    endif

    filebase = FILE_BASENAME(self._filename)

    badName = (self._filename eq '') || $
        STRCMP(self._filename, 'untitled', /FOLD_CASE)

    if (showUI || badName) then begin

        ; Ask the UI service to present the file selection dialog to the user.
        ; The caller sets my filename property before returning.
        ; This should also call my GetFilterList().
        success = oTool->DoUIService('FileSaveAs', self)

        if (success eq 0) then $
            return, -1  ; cancel

    endif

    ; check our filename cache
    if (self._fileName eq '') then $
        return, -1  ; cancel

    idWriter = oWriteFile->FindMatchingWriter(self._fileName)
    
    if (idWriter ne '') then begin
      oDesc = oTool->GetByIdentifier(idWriter)
      oWriter = oDesc->GetObjectInstance()
      oWriter->GetProperty, TYPES=types
      if ISA(_extra) then $
        oWriter->SetProperty, _EXTRA=_extra
      
      case (types[0]) of
      'IDLISV': oSaveItem = oTool
      else: oSaveItem = oTool->GetCurrentWindow()
      endcase
      
    endif
    
    oGeneral = oTool->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
    if (Obj_Valid(oGeneral)) then begin
      oGeneral->GetProperty, RESOLUTION=resolution
    endif

    status = oWriteFile->WriteFile(self._fileName, oSaveItem, $
      RESOLUTION=resolution, _EXTRA=_extra)

    if (status ne 1) then begin
        self->ErrorMessage, /USE_LAST_ERROR, $
          title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
          [IDLitLangCatQuery('Error:Framework:FileWriteError'), $
          self._fileName]
        if (idWriter eq '') then begin
          self._filename = ''
          goto, tryAgain
        endif
        return, 0
    endif

    ; Change my tool filename.
    oTool->SetProperty, TOOL_FILENAME=self._fileName

    return, 1 ; success

end


;---------------------------------------------------------------------------
; IDLitopFileSave::DoAction
;
; Purpose:
;   Used to save the iTool state.
;
; Parameters:
;   oTool   - The tool we are operating in.
;
; Return Value
;   Null object (not undoable).
;
; Keywords:
;   SUCCESS (1), Failure (0), or Cancel (-1).
;
function IDLitopFileSave::DoAction, oTool, SUCCESS=success, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->_Save(oTool, _EXTRA=_extra)

    if (success eq 1) then begin
        ; Be sure our File/Save and File/SaveAs are in sync.
        oDesc = oTool->GetByIdentifier('Operations/File/SaveAs')
        if (OBJ_VALID(oDesc)) then $
            oDesc->SetProperty, FILENAME=self._filename
    endif

    return, OBJ_NEW()  ; not undoable

end


;---------------------------------------------------------------------------
; Purpose:
;   Basically for the UI service to provide a callback to this
;   object.
;
function IDLitopFileSave::GetFilterList, COUNT=COUNT

   compile_opt idl2, hidden

   oTool = self->GetTool()
   oWrite = oTool->GetService("WRITE_FILE")
   if (~obj_valid(oWrite)) then begin
       count = 0
       return,''
   endif

  ; CT: Hack - do not allow ISV files to be saved for new graphics.
  if (ISA(oTool, 'GraphicsTool')) then begin
    filters = oWrite->GetFilterListByType(['IDLDEST', 'IDLIMAGE'], $
      COUNT=count)
  endif else begin
    filters = oWrite->GetFilterListByType(['IDLISV', 'IDLDEST', 'IDLIMAGE'], $
      COUNT=count)
  endelse
  return, filters

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitopFileSave__define

    compile_opt idl2, hidden

    struc = {IDLitopFileSave, $
        inherits IDLitOperation, $
        _fileName: ''  $
        }

end

