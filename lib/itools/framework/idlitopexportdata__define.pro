; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopexportdata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopExportData
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
;   See IDLitopExportData::Init
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopExportData::Init
;
; Purpose:
; The constructor of the IDLitopExportData object.
;
; Parameters:
; None.
;
function IDLitopExportData::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(NUMBER_DS='1', ICON='export', $
                                    _EXTRA=_extra)) then $
        return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'SOURCE', $
        NAME='Item to export', $
        DESCRIPTION='Item to export', $
        ENUMLIST=['By identifier', 'Current window', 'Current view']

    self->RegisterProperty, 'ITEM_ID', /STRING, $
        NAME='Item identifier', $
        DESCRIPTION='Full identifier of item to export'

    self->RegisterProperty, 'DESTINATION', $
        NAME='Destination', $
        DESCRIPTION='Export destination', $
        ENUMLIST=['File', 'IDL Variable']

    self->RegisterProperty, 'FILENAME', /USERDEF, $
        NAME='File name', $
        DESCRIPTION='File name'

    self->RegisterProperty, 'VARIABLE', /STRING, $
        NAME='Variable name', $
        DESCRIPTION='IDL variable name'

    self->RegisterProperty, 'SCALE_FACTOR', /FLOAT, $
        NAME='Scale factor', $
        DESCRIPTION='Scale factor for file export'

    self._scale = 1

    return, 1
end


;-------------------------------------------------------------------------
; IDLitopExportData::Cleanup
;
; Purpose:
; The destructor of the IDLitopExportData object.
;
; Parameters:
; None.
;
;pro IDLitopExportData::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
pro IDLitopExportData::GetProperty, $
    DESTINATION=destination, $
    FILENAME=fileName, $
    ITEM_ID=itemID, $
    SCALE_FACTOR=scaleFactor, $
    SOURCE=source, $
    VARIABLE=variable, $
    WRITER_ID=writerID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(destination)) then $
        destination = self._bDestination

    if (ARG_PRESENT(filename)) then $
        filename = self._filename

    if (ARG_PRESENT(itemID)) then $
        itemID = self._idSrc

    if (ARG_PRESENT(scaleFactor)) then $
        scaleFactor = self._scale

    if (ARG_PRESENT(source)) then $
        source = self._bSource

    if (ARG_PRESENT(variable)) then $
        variable = self._variable

    if (ARG_PRESENT(writerID)) then $
        writerID = self._idWriter

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopExportData::SetProperty, $
    DESTINATION=destination, $
    FILENAME=filename, $
    ITEM_ID=itemID, $
    SCALE_FACTOR=scaleFactor, $
    SOURCE=source, $
    VARIABLE=variable, $
    WRITER_ID=writerID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(filename) eq 1) then begin
        self._filename = filename
        self->SetPropertyAttribute, 'FILENAME', $
            USERDEF=self._filename
    endif

    if (N_ELEMENTS(variable) eq 1) then $
        self._variable = variable

    if (N_ELEMENTS(destination) eq 1) then begin
        self._bDestination = destination
        self->SetPropertyAttribute, ['FILENAME', 'SCALE_FACTOR'], $
            SENSITIVE=self._bDestination eq 0
        self->SetPropertyAttribute, 'VARIABLE', $
            SENSITIVE=self._bDestination eq 1
    endif

    if (N_ELEMENTS(itemID) eq 1) then $
        self._idSrc = itemID

    if (N_ELEMENTS(scaleFactor) eq 1) then $
        self._scale = scaleFactor

    if (N_ELEMENTS(source) eq 1) then begin
        self._bSource = source
        self->SetPropertyAttribute, 'ITEM_ID', $
            SENSITIVE=self._bSource eq 0
    endif

    if (N_ELEMENTS(writerID) eq 1) then $
        self._idWriter = writerID

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Purpose:
;   Basically for the UI service to provide a callback to this
;   object.
;
function IDLitopExportData::GetFilterList, COUNT=COUNT

    compile_opt idl2, hidden

    ; For simplicity assume we can export to any type, and let
    ; the tool determine the correct writer from the suffix.
    count = 1
    return, [['*'],['All files (*)']]

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
function IDLitopExportData::EditUserDefProperty, oTool, identifier

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
; IDLitopExportData::DoAction
;
; Purpose:
;   The generic operation doAction routine. This operation will
;   trigger off the export wizard. If that returns successfully, it
;   will then perform the desired export operation.
;
; Parameters:
;   oTool   - The tool this operation is executing in.
;
function IDLitopExportData::DoAction, oTool

    compile_opt idl2, hidden

    self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI

    if (showExecutionUI) then begin

        oWin = oTool->GetCurrentWindow()
        idWin = oWin->GetFullIdentifier()
        oView = oWin->GetCurrentView()
        idView = oView->GetFullIdentifier()
        case (self._bSource) of
        0: ; do nothing for full identifier
        1: self._idSrc = idWin
        2: self._idSrc = idView
        endcase

        ; Reset the source flag, so we always start out by identifier.
        self._bSource = 0b

        ; Launch the wizard.
        if (~oTool->DoUIService('DataExportWizard', self)) then $
            return, OBJ_NEW()

        ; Try to set the source flag appropriately.
        if (idWin eq self._idSrc) then begin
            self._bSource = 1b  ; Current window
        endif else if (idView eq self._idSrc) then begin
                self._bSource = 2b  ; Current view
        endif

    endif else begin

        ; If we didn't have the UI, then we must determine the writer type
        ; from the file suffix. This is risky because it might be impossible
        ; to correctly determine the writer type, but we don't have much
        ; choice: The user might have edited the FILENAME property from
        ; within the Macro Editor, which might not have a current tool
        ; to draw file writers from.
        self._idWriter = ''

    endelse


    if (self._bDestination eq 0) then begin
        self->_ExportToFile, oTool
    endif else begin
        self->_ExportToVariable, oTool
    endelse

    return,  OBJ_NEW() ; no undo/redo
end


;---------------------------------------------------------------------------
; IDLitopExportData::ExportToVariable
;
; Purpose:
;   Used to export a given data item to a variable.
;
; Parameters:
;   oTool   - The tool being used
;
; Return Value:
;    0 - Error
;    1 - Success
;
pro IDLitopExportData::_ExportToVariable, otool

    compile_opt hidden, idl2

   ; Get our source item
    oData = oTool->GetByIdentifier(self._idSrc)
    if(~obj_valid(oData) || ~obj_isa(oData, "IDLitData"))then begin
        self->ErrorMessage, $
       IDLitLangCatQuery('Error:Framework:InvalidExportSource'), severity=1
        return
    endif
    oCL = oTool->GetService("COMMAND_LINE")
    if(not obj_valid(oCL))then begin
        self->ErrorMessage, $
       IDLitLangCatQuery('Error:Framework:CannotAccessCommandLine'), severity=1
        return
    endif

    status = oCL->ExportDataToCL(oData, self._variable)

   ;; Check our status.
    if (status eq 0)then begin ;; unknow error
      self->ErrorMessage, SEVERITY=2, $
        [ IDLitLangCatQuery('Error:Framework:UnknownError') + $
      IDLitLangCatQuery('Error:Framework:UnknownErrorCL') + $
      IDLitLangCatQuery('Error:Framework:UnableToCompleteExport')]
    endif

end


;-------------------------------------------------------------------------
; IDLitopExportData::ExportToFile
;
; Purpose:
;   This routine will take the given/current parameters in this
;   operation and export the given data to a file. If the item needs
;   to be rastorized, the rastorziation service is used to perform
;   this task.
;
; Parameters:
;    oTool  - The tool
;
; Return Value:
;    0 - Error
;    1 - Success
;
pro IDLitopExportdata::_ExportToFile, oTool

    compile_opt hidden, idl2

    ; Get our source item
    case (self._bSource) of
    0: oItem = oTool->GetByIdentifier(self._idSrc)
    1: oItem = oTool->GetCurrentWindow()
    2: begin
        oWin = oTool->GetCurrentWindow()
        oItem = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
      end
    endcase

    if (~obj_valid(oItem)) then begin
        self->ErrorMessage,$
            IDLitLangCatQuery('Error:Framework:InvalidExportSource'), severity=2
        return
    endif

   ; Okay, now send this data to the file writer system
   oWriter = oTool->getService("WRITE_FILE")
   if(not obj_valid(oWriter))then begin
      self->ErrorMessage, $
    IDLitLangCatQuery('Error:Framework:CannotAccessWriterService'), severity=2
       return
   endif

   ; Write out the file.
   status = oWriter->WriteFile(self._filename, oItem, $
        SCALE_FACTOR=self._scale, $
        WRITER=self._idWriter)

    if (status ne 1) then begin
        self->ErrorMessage, /USE_LAST_ERROR, $
          title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
          [IDLitLangCatQuery('Error:Framework:FileWriteError'), $
          self._filename]
    endif

end


;-------------------------------------------------------------------------
; Definition
pro IDLitopExportData__define
    compile_opt idl2, hidden
    struc = {IDLitopExportData,            $
             inherits IDLitOperation,    $
             _bDestination: 0b,  $  ; Type of import (0 - file, 1-variable)
             _bSource: 0b, $
             _idSrc: '', $  ; item being exported
             _filename: '', $  ; Name of the destination
             _variable: '', $  ; Name of the destination
             _idWriter: '', $  ; id of the writer to use
             _scale: 0d $ ; scale factor
             }


end

