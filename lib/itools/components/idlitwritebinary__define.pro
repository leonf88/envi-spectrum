; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritebinary__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteBinary class.
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
function IDLitWriteBinary::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitWriter::Init('dat', $
        NAME='Binary data', $
        TYPES=["IDLIMAGEPIXELS", "IDLPALETTE", $
            "IDLVECTOR", "IDLARRAY2D", "IDLARRAY3D"], $
        DESCRIPTION="Binary data (dat)", $
        ICON='binary', $
        _EXTRA=_extra) eq 0) then $
        return, 0


    self->RegisterProperty, 'BYTE_ORDER', $
        NAME='Byte ordering', $
        DESCRIPTION='Byte ordering to use for file', $
        ENUMLIST=['Native', 'Little endian', 'Big endian']

    ; Default is to not use compression because then it's difficult
    ; for us to read it back in because READ_BINARY doesn't
    ; understand compression.
;    self->RegisterProperty, 'Compression', /BOOLEAN, $
;        DESCRIPTION='Compress the file using GZIP'
    self._compression = 0b

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriteBinary::SetProperty, _EXTRA=_extra

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitWriteBinary::GetProperty, $
    BYTE_ORDER=byte_order, $
    COMPRESSION=compression, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(byte_order)) then $
        byte_order = self._byteOrder

    if (ARG_PRESENT(compression)) then $
        compression = self._compression

    ; Call our superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriter::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
pro IDLitWriteBinary::SetProperty, $
    BYTE_ORDER=byte_order, $
    COMPRESSION=compression, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(byte_order)) then $
        self._byteOrder = byte_order

    if (N_ELEMENTS(compression)) then $
        self._compression = compression

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
function IDLitWriteBinary::SetData, oData

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

    ; If desired, switch from our machine's byte ordering
    ; to the desired byte ordering.
    if (self._byteOrder ne 0) then begin
        isLittleEndian = (BYTE(FIX(1), 0, 2))[0] eq 1b
        wantLittleEndian = self._byteOrder eq 1
        if (isLittleEndian ne wantLittleEndian) then $
            swapEndian = 1
    endif

    OPENW, lun, strFilename, /GET_LUN, $
        COMPRESS=self._compression, $
        SWAP_ENDIAN=swapEndian
    WRITEU, lun, data
    CLOSE, lun

    return, 1  ; success


failed:
    self->ErrorMessage, $
        [IDLitLangCatQuery('Error:Framework:InvalidWriteData')], $
        title=IDLitLangCatQuery('Error:Error:Title'), severity=2
    return, 0 ; failure

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteBinary__Define

    compile_opt idl2, hidden

    void = {IDLitWriteBinary, $
        inherits IDLitWriter, $
        _byteOrder: 0b, $
        _compression: 0b $
        }
end
