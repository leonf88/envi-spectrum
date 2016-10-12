; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadcsv__define.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadCSV class.
;


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadCSV object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadCSV::Init, $
    _REF_EXTRA=_extra
    
    
  compile_opt idl2, hidden
  
  ; Init superclass
  ; The only properties that can be set at INIT time can be set
  ; in the superclass Init method.
  if (~self->IDLitReader::Init('csv',  $
    NAME='CSV Comma delimited', $
    DESCRIPTION="CSV Comma delimited (csv)", $
    ICON='ascii', $
    _EXTRA=_extra)) then $
    return, 0

  self->RegisterProperty, 'RECORD_START', /INTEGER, $
    NAME='Starting record number', $
    Description='Index of the first record to read'

  self->RegisterProperty, 'NUM_RECORDS', /INTEGER, $
    NAME='Number of records to read (0=all)', $
    Description='Number of records to read'

  ; Set the properties.
  self->IDLitReadCSV::SetProperty, _EXTRA=_EXTRA
  
  return, 1
end

;---------------------------------------------------------------------------
; IDLitReadCSV::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitReadCSV::Cleanup

  compile_opt idl2, hidden
  
  ; Cleanup superclass
  self->IDLitReadASCII::Cleanup
end

;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitReadCSV::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
pro IDLitReadCSV::GetProperty, $
  NUM_RECORDS=numRecords, $
  RECORD_START=recordStart, $
  _REF_EXTRA=_super

  compile_opt idl2, hidden
  
  if (Arg_Present(numRecords)) then $
    numRecords = self.numRecords

  if (Arg_Present(recordStart)) then $
    recordStart = self.recordStart
    
  if(n_elements(_super) gt 0) then $
    self->IDLitReadASCII::GetProperty, _EXTRA=_super
end

;---------------------------------------------------------------------------
; IDLitReadCSV::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
; Properties:
;
pro IDLitReadCSV::SetProperty, $
  NUM_RECORDS=numRecords, $
  RECORD_START=recordStart, $
  _EXTRA=_super

  compile_opt idl2, hidden
  
  if (N_ELEMENTS(numRecords)) then $
    self.numRecords = numRecords

  if (N_ELEMENTS(recordStart)) then $
    self.recordStart = recordStart

  if (N_ELEMENTS(_super) gt 0) then $
    self->IDLitReadASCII::SetProperty, _EXTRA=_super
end

;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; IDLitReadCSV::GetData
;
; Purpose:
; Internal procedure for obtaining the properties of an image file.
;
; Parameters:
; None.
;
; Returns 1 for success, 0 for error, -1 for cancel.
;
function IDLitReadCSV::GetData, oData
  compile_opt idl2, hidden
  
  @idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    self->SignalError, !error_state.msg, severity=2
    return, 0
  endif
  
  oTool = self->GetTool()
  if (not OBJ_VALID(oTool)) then $
    return, 0
    
  strFilename = self->GetFilename()

  if (self.numRecords ne 0) then $
    numRecords = self.numRecords
  if (self.recordStart ne 0) then $
    recordStart = self.recordStart
   
  sData = READ_CSV(strFilename, $
    COUNT=nrecords, $
    HEADER=header, $
    NUM_RECORDS=numRecords, $
    RECORD_START=recordStart)

  ; Should we throw an error if there are no records?
  if ((nrecords eq 0) || (N_TAGS(sData) eq 0)) then $
    return, 0
    
  name = FILE_BASENAME(strFilename, '.csv', /FOLD_CASE)
  description = STRJOIN(header, ' ')

  return, self->IDLitReadASCII::_HandleData(sData, name, description, oData)
  
end


;---------------------------------------------------------------------------
; IDLitReadCSV::Isa
;
; Purpose:
;   Return true if the give file is ASCII
;
; Paramter:
;   strFilename  - The file to check

function IDLitReadCSV::Isa, strFilename

  compile_opt idl2, hidden
  
  return, QUERY_CSV(strFilename)
  
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadCSV__Define
;
; Purpose:
; Class definition for the IDLitReadCSV class
;

pro IDLitReadCSV__Define

  compile_opt idl2, hidden

  void = {IDLitReadCSV, $
    inherits IDLitReadASCII, $
    numRecords: 0LL, $
    recordStart: 0LL $
    }
end
