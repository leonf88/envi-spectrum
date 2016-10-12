; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadascii__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadAscii class.
;


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadAscii object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadAscii::Init, $
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitReader::Init('txt',  $
        NAME='ASCII text', $
        DESCRIPTION="ASCII text file (txt)", $
        ICON='ascii', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    ; Register properties
;    self->RegisterProperty, 'TEMPLATE', USERDEF='Template', $
;        Description='ASCII Template'

    ; Set the properties.
    self->IDLitReadAscii::SetProperty, _EXTRA=_EXTRA

    return, 1
end

;---------------------------------------------------------------------------
; IDLitReadAscii::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitReadAscii::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._pTemplate

    ; Cleanup superclass
    self->IDLitReader::Cleanup
end

;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitReadAscii::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;

pro IDLitReadAscii::GetProperty, $
                  TEMPLATE=template, $
                  _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(template)) then begin
        template =  (PTR_VALID(self._pTemplate) && $
            (N_ELEMENTS(*self._pTemplate) gt 0)) ? *self._pTemplate : 0
    endif

    if(n_elements(_super) gt 0) then $
        self->IDLitReader::GetProperty, _EXTRA=_super
end

;---------------------------------------------------------------------------
; IDLitReadAscii::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
; Properties:
;

pro IDLitReadAscii::SetProperty, $
    TEMPLATE=template, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(template) ne 0) then begin
        ; Initialize if necessary.
        if (~PTR_VALID(self._pTemplate)) then $
            self._pTemplate = PTR_NEW(/ALLOC)
        *self._pTemplate = template
    endif

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitReader::SetProperty, _EXTRA=_super
end

;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Internal method to determine if the data is in vector format.
;
function IDLitReadAscii::_HandleTimeSeriesData, $
    sData, name, description, oData

    compile_opt idl2, hidden

    nFields = N_TAGS(sData)

    if (nFields lt 2) then $
        return, 0

    fieldNames = TAG_NAMES(sData)

    n = N_ELEMENTS(sData.(0))

    ; Make sure all fields are vectors of the same length.
    for i=0,nFields-1 do begin
        if (SIZE(sData.(i), /N_DIMENSIONS) ne 1) then $
            return, 0
        if (n ne N_ELEMENTS(sData.(i))) then $
            return, 0
    endfor

    ; We made it successfully thru all fields.
    ; Now check for "time series" data, where the first column is
    ; monotonically increasing (or decreasing) and evenly-spaced.
    x = sData.(0)
    dx = x[1:*] - x[0:n-2]
    meanDx = TOTAL(dx)/(n-1)

    ; Is the first column evenly spaced?
    if (meanDx && (ABS((MAX(dx) - MIN(dx))/meanDx) lt 0.2)) then begin
        ; Create a separate data container for each column, using
        ; the first column as the indepentent X "time" data and
        ; the other columns as the dependent Y data.
        for i=1,nFields-1 do begin
            oParmSet = OBJ_NEW('IDLitParameterSet', $
                NAME=name, $
                ICON='plot', $
                DESCRIPTION=description)
            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', sData.(i), $
                NAME=fieldNames[i]), PARAMETER_NAME='Y'
            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', x, $
                NAME=fieldNames[0]), PARAMETER_NAME='X'
            oData = (i eq 1) ? oParmSet : [oData, oParmSet]
        endfor
        return, 1
    endif

    ; Failure
    return, 0
end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method to construct parameter sets from data.
;
function IDLitReadAscii::_HandleData, sData, name, description, oData

    compile_opt idl2, hidden

    if (self->_HandleTimeSeriesData(sData, name, description, oData)) then $
        return, 1

    fieldNames = TAG_NAMES(sData)
    nFields = N_TAGS(sData)
    
    if (nFields gt 1) then begin
        oData = OBJ_NEW('IDLitParameterSet', NAME=name, $
                    DESCRIPTION=description, $
                    TYPE='IDLUNKNOWNDATA')
    endif


    for i=0,nFields-1 do begin

        name1 = name
        if (nFields gt 1) then $
            name1 += '.' + fieldNames[i]

        ; Copy out the first field and remove dims of length 1.
        data1 = REFORM(sData.(i))

        ; Create the Data object
        case (SIZE(data1, /N_DIMENSIONS)) of
            1: oData1 = OBJ_NEW('IDLitDataIDLVector', data1, $
                NAME=name1, DESCRIPTION=description)
            2: oData1 = OBJ_NEW('IDLitDataIDLArray2D', data1, $
                NAME=name1, DESCRIPTION=description)
            3: oData1 = OBJ_NEW('IDLitDataIDLArray3D', data1, $
                NAME=name1, DESCRIPTION=description)
            else: oData1 = OBJ_NEW('IDLitData', data1, type="ARRAY", $
                NAME=name1, DESCRIPTION=description)
        endcase

        ; Either add to container, or just copy the data objref.
        if (nFields gt 1) then $
            oData->Add, oData1 $
        else $
            oData = oData1
    endfor


    return, 1
end


;---------------------------------------------------------------------------
; IDLitReadAscii::GetData
;
; Purpose:
;  Get the data.
;
; Parameters:
; None.
;
; Returns 1 for success, 0 for error, -1 for cancel.
;
function IDLitReadAscii::GetData, oData
    compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    self->SignalError, !error_state.msg, severity=2
    return, 0
  endif

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    ; Initialize if necessary.
    if (~PTR_VALID(self._pTemplate)) then $
        self._pTemplate = PTR_NEW(/ALLOC) $
    else $
        *self._pTemplate = 0


    success = oTool->DoUIService('AsciiTemplate', self)

    ; See if user hit "Cancel" on the dialog.
    if (~success || ~N_TAGS(*self._pTemplate)) then $
        return, -1

    strFilename = self->GetFilename()
    sData = READ_ASCII(strFilename, $
        COUNT=nrecords, $
        HEADER=header, $
        TEMPLATE=*self._pTemplate)

    ; Should we throw an error if there are no records?
    nFields = N_TAGS(sData)
    if ((nrecords eq 0) or (nFields eq 0)) then $
        return, 0

    name = FILE_BASENAME(strFilename, '.txt', /FOLD_CASE)

    ; Attempt to use the header as the data description.
    if (N_ELEMENTS(header) gt 0) then begin
        lengths = STRLEN(header)
        good = WHERE(lengths gt 0, ngood)
        ; Just use the first non-blank line as the description.
        if (ngood gt 0) then $
            description = header[good[0]]
    endif


    return, self->_HandleData(sData, name, description, oData)

ioerr: ; IO Error handler
    self->SignalError, !error_state.msg, severity=2
    return, 0
end


;---------------------------------------------------------------------------
; IDLitReadAscii::Isa
;
; Purpose:
;   Return true if the give file is ASCII
;
; Paramter:
;   strFilename  - The file to check

function IDLitReadAscii::Isa, strFilename

    compile_opt idl2, hidden

    return, QUERY_ASCII(strFilename)

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadAscii__Define
;
; Purpose:
; Class definition for the IDLitReadAscii class
;

pro IDLitReadAscii__Define

  compile_opt idl2, hidden

  void = {IDLitReadAscii, $
          inherits IDLitReader, $
          _pTemplate: PTR_NEW() $
         }
end
