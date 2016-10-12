; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopexportimage__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopExportImage
;
; PURPOSE:
;   This class implements an operation that is used to run the export
;   data wizard.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopExportImage::Init
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopExportImage::Init
;
; Purpose:
; The constructor of the IDLitopExportImage object.
;
; Parameters:
; None.
;
function IDLitopExportImage::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(_EXTRA=_extra, $
      TYPES=["IDLIMAGE"], $
      NUMBER_DS='1', $
      ICON='export')) then $
        return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'ITEM_ID', /STRING, $
        NAME='Item identifier', $
        DESCRIPTION='Full identifier of item to export'

    self->RegisterProperty, 'FILENAME', /USERDEF, $
        NAME='File name', $
        DESCRIPTION='File name'

    return, 1
end


;-------------------------------------------------------------------------
; IDLitopExportImage::Cleanup
;
; Purpose:
; The destructor of the IDLitopExportImage object.
;
; Parameters:
; None.
;
;pro IDLitopExportImage::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
pro IDLitopExportImage::GetProperty, $
    FILENAME=fileName, $
    ITEM_ID=itemID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(filename)) then $
        filename = self._filename

    if (ARG_PRESENT(itemID)) then $
        itemID = self._idSrc

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopExportImage::SetProperty, $
    FILENAME=filename, $
    ITEM_ID=itemID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(filename) eq 1) then begin
        self._filename = filename
        self->SetPropertyAttribute, 'FILENAME', $
            USERDEF=self._filename
    endif

    if (N_ELEMENTS(itemID) eq 1) then $
        self._idSrc = itemID

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Purpose:
;   Basically for the UI service to provide a callback to this
;   object.
;
function IDLitopExportImage::GetFilterList, COUNT=COUNT

  compile_opt idl2, hidden
  
  count = 0

  oTool = self->GetTool()
  oWrite = oTool->GetService("WRITE_FILE")
  if (~obj_valid(oWrite)) then begin
    return,''
  endif

  if (self._idSrc eq '') then begin
    return,''
  endif

  oItem = oTool->GetByIdentifier(self._idSrc)
  if (~OBJ_VALID(oItem)) then begin
    return,''
  endif

  filters = oWrite->GetFilterListByType('IDLIMAGE', $
    COUNT=count)
  return, filters
  

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to edit a user-defined property.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   PropertyIdentifier: String giving the name of the userdef property.
;
; Keywords:
;   None.
;
function IDLitopExportImage::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'FILENAME': begin
        ; This should set our FILENAME property.
        void = oTool->DoUIService('FileSaveAs', self)
        return, 0   ; don't need to undo/redo
        end

    else:

    endcase

    return, 0

end

;---------------------------------------------------------------------------
; Retrieve the currently selected item, or if nothing is selected,
; retrieve the first visualization in the current view.
; If the visualization is not an image, then just retrieve the current view.
;
pro IDLitopExportImage::_FindSelectedItem, oTool

  compile_opt idl2, hidden

  oItem = oTool->GetSelectedItems(COUNT=count)
  oItem = oItem[0]
  
  oWin = oTool->GetCurrentWindow()
  oView = Obj_Valid(oWin) ? oWin->GetCurrentView() : Obj_New()

  ; If nothing selected, retrieve the first visualization in the current view.
  if (~Obj_Valid(oItem)) then begin
    oLayer = Obj_Valid(oView) ? oView->GetCurrentLayer() : Obj_New()
    oWorld = Obj_Valid(oLayer) ? oLayer->GetWorld() : Obj_New()
    oDS = Obj_Valid(oWorld) ? oWorld->GetCurrentDataSpace() : Obj_New()
    oVis = Obj_Valid(oDS) ? oDS->GetVisualizations() : Obj_New()
    oItem = oVis[0]
  endif
  
  type = ''
  if (Obj_Valid(oItem)) then begin
    oItem->GetProperty, TYPE=type
  endif
  
  if (type ne 'IDLIMAGE') then begin
    oItem = oView
  endif
  
  self._idSrc = Obj_Valid(oItem) ? oItem->GetFullIdentifier() : ''
end


;---------------------------------------------------------------------------
; IDLitopExportImage::DoAction
;
; Purpose:
;   The generic operation doAction routine.
;
; Parameters:
;   oTool   - The tool this operation is executing in.
;
function IDLitopExportImage::DoAction, oTool

    compile_opt idl2, hidden

tryAgain:
    if (LMGR(/DEMO)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:SaveDisabledDemo')], severity=2
        return, Obj_New()
    endif

    ; Do we have our File Writer service?
    oWriteFile = oTool->GetService("WRITE_FILE")
    if(not obj_valid(oWriteFile))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotAccessWriterService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, Obj_New()
    endif

    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI

    badName = (self._filename eq '') || $
        STRCMP(self._filename, 'untitled', 8, /FOLD_CASE)

    filebase = FILE_BASENAME(self._filename)

    badName = (self._filename eq '') || $
        STRCMP(filebase, 'untitled', 8, /FOLD_CASE)

    self->_FindSelectedItem, oTool
    
    if (self._idSrc eq '') then begin
      return,''
    endif
    
    oItem = oTool->GetByIdentifier(self._idSrc)
    if (~OBJ_VALID(oItem)) then begin
      return,''
    endif
  
    if (showUI || badName) then begin

        ; Ask the UI service to present the file selection dialog to the user.
        ; The caller sets my filename property before returning.
        ; This should also call my GetFilterList().
        success = oTool->DoUIService('FileSaveAs', self)

        if (success eq 0) then $
            return, Obj_New()

    endif


    ; check our filename cache
    if (self._fileName eq '') then $
        return, Obj_New()

    idWriter = oWriteFile->FindMatchingWriter(self._fileName)
    
    status = oWriteFile->WriteFile(self._fileName, oItem)

    if (status ne 1) then begin
        self->ErrorMessage, /USE_LAST_ERROR, $
          title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
          [IDLitLangCatQuery('Error:Framework:FileWriteError'), $
          self._fileName]
        if (idWriter eq '') then begin
          self._filename = ''
          goto, tryAgain
        endif
        return, Obj_New()
    endif


    return,  OBJ_NEW() ; no undo/redo

end


;-------------------------------------------------------------------------
; Definition
pro IDLitopExportImage__define
    compile_opt idl2, hidden
    struc = {IDLitopExportImage,            $
             inherits IDLitOperation,    $
             _filename: '', $
             _idSrc: '' $
             }


end

