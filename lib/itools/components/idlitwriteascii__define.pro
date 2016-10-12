; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwriteascii__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteASCII class.
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
function IDLitWriteASCII::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitWriter::Init('txt', $
        NAME='ASCII text', $
        TYPES=["IDLIMAGEPIXELS", "IDLPALETTE", $
            "IDLVECTOR", "IDLARRAY2D", "IDLARRAY3D"], $
        DESCRIPTION="ASCII text file (txt)", $
        ICON='ascii', $
        _EXTRA=_extra) eq 0) then $
        return, 0


    self->RegisterProperty, 'STRING_SEPARATOR', /STRING, $
        NAME='Separator', $
        DESCRIPTION='Character string used to separate values'

    self->RegisterProperty, 'USE_DEFAULT_FORMAT', /BOOLEAN, $
        NAME='Use default format', $
        DESCRIPTION='Use the default format for the data type'

    self->RegisterProperty, 'STRING_FORMAT', /STRING, SENSITIVE=0, $
        NAME='Format string', $
        DESCRIPTION='Format string to use for each value'

    ; Default is a null character between each item.
    self._strSeparator = ''

    ; Use default format string.
    self._useDefaultFormat = 1b
    self._strFormat = 'G9.2'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriteASCII::SetProperty, _EXTRA=_extra

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitWriteASCII::GetProperty, $
    STRING_FORMAT=strFormat, $
    STRING_SEPARATOR=strSeparator, $
    USE_DEFAULT_FORMAT=useDefaultFormat, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(strFormat)) then $
        strFormat = self._strFormat

    if (ARG_PRESENT(strSeparator)) then $
        strSeparator = self._strSeparator

    if (ARG_PRESENT(useDefaultFormat)) then $
        useDefaultFormat = self._useDefaultFormat

    ; Call our superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriter::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
pro IDLitWriteASCII::SetProperty, $
    STRING_FORMAT=strFormat, $
    STRING_SEPARATOR=strSeparator, $
    USE_DEFAULT_FORMAT=useDefaultFormat, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(strFormat)) then $
        self._strFormat = strFormat

    if (N_ELEMENTS(strSeparator)) then $
        self._strSeparator = strSeparator

    if (N_ELEMENTS(useDefaultFormat)) then begin
        self._useDefaultFormat = KEYWORD_SET(useDefaultFormat)
        self->SetPropertyAttribute, 'STRING_FORMAT', $
            SENSITIVE=~self._useDefaultFormat
    endif

    ; Call our superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriter::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   Data: An object reference to the data to be written.
;
; Keywords:
;   None.
;
function IDLitWriteASCII::SetData, oData

    compile_opt idl2, hidden

    strFilename = self->GetFilename()
    if (strFilename eq '') then $
        return, 0 ; failure

    if (~OBJ_VALID(oData)) then $
        goto, failed

    if (~oData->GetData(data)) then $
        goto, failed

    oData->GetProperty, $
        NAME=name, DESCRIPTION=description

    if (SIZE(data, /N_DIMENSIONS) eq 1) then $
        data = TRANSPOSE(data)

    if (self._useDefaultFormat) then begin
        case SIZE(data, /TYPE) of
            0: goto, failed
            1: format = 'I3'
            2: format = 'I6'
            3: format = 'I11'
            4: format = 'G'
            5: format = 'G'
            6: format = '"(",G,",",G,")"'
            7: format = 'A'
            8: goto, failed
            9: format = '"(",G,",",G,")"'
            10: goto, failed
            11: goto, failed
            12: format = 'I5'
            13: format = 'I10'
            14: format = 'I20'
            15: format = 'I20'
            else: goto, failed
        endcase
    endif else begin
        format = self._strFormat
    endelse


    if (self._useDefaultFormat) then begin
        dim0 = (SIZE(data, /DIMENSIONS))[0]
        if (dim0 gt 1) then begin
            ; We need to split each line into 2 pieces, with dim0-1 values
            ; each followed by the separator string, then followed by
            ; the last value. Otherwise, if we put the separator string
            ; at the end of the row, read_ascii complains if you try to
            ; import the file back into an iTool.
            format = (self._strSeparator eq '') ? $
                STRTRIM(dim0, 2) + '(' + format + ')' : $
                STRTRIM(dim0-1, 2) + '(' + format + ',"' + $
                self._strSeparator + '"' + '), ' + format
        endif
    endif


    format = '(' + format + ')'

    ON_IOERROR, ioFailed
    OPENW, lun, strFilename, /GET_LUN
    PRINTF, lun, oData->GetFullIdentifier()
    PRINTF, lun, 'Created: ' + SYSTIME()
    PRINTF, lun, 'Name: ' + name
    PRINTF, lun, 'Description: ' + description
    PRINTF, lun, 'Format: ' + format
    PRINTF, lun, data, FORMAT=format
    CLOSE, lun
    ON_IOERROR, null

    return, 1  ; success


failed:
    self->ErrorMessage, $
        [IDLitLangCatQuery('Error:Framework:InvalidWriteData')], $
        title=IDLitLangCatQuery('Error:Error:Title'), severity=2
    return, 0 ; failure

ioFailed:
    self->ErrorMessage, $
        [IDLitLangCatQuery('Error:Framework:FileWriteError'), !ERROR_STATE.msg], $
        title=IDLitLangCatQuery('Error:Error:Title'), severity=2
    return, 0 ; failure

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteASCII__Define

    compile_opt idl2, hidden

    void = {IDLitWriteASCII, $
        inherits IDLitWriter, $
        _strSeparator: '', $
        _strFormat: '', $
        _useDefaultFormat: 0b $
        }
end
