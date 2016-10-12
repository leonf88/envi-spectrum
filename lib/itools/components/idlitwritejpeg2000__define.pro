; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritejpeg2000__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteJPEG2000 class.
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
;   See RegisterProperty below.
;
function IDLitWriteJPEG2000::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if (~self->IDLitWriter::Init(['jp2', 'jpx', 'j2k'], $
       TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
        NAME='JPEG2000', $
        DESCRIPTION="JPEG2000 File Format (JPEG2000)", $
        ICON='demo', $
        _EXTRA=_extra)) then $
        return, 0

    self->RegisterProperty, 'REVERSIBLE', /BOOLEAN, $
        NAME='Reversible', $
        DESCRIPTION='Use reversible (lossless) compression'

    self->RegisterProperty, 'N_LEVELS', /INTEGER, $
        NAME='Wavelet levels', $
        DESCRIPTION='Number of wavelet decomposition levels', $
        VALID_RANGE=[1,15,1]

    self->RegisterProperty, 'N_LAYERS', /INTEGER, $
        NAME='Quality layers', $
        DESCRIPTION='Number of quality layers to include', $
        VALID_RANGE=[1,32766]

    ; Set defaults.
    self._nLayers = 1
    self._nLevels = 5

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriteJPEG2000::SetProperty, _EXTRA=_extra

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitWriteJPEG2000::GetProperty, $
    N_LAYERS=nLayers, $
    N_LEVELS=nLevels, $
    REVERSIBLE=reversible, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(nLayers)) then $
        nLayers =  self._nLayers

    if (ARG_PRESENT(nLevels)) then $
        nLevels =  self._nLevels

    if (ARG_PRESENT(reversible)) then $
        reversible =  self._reversible

    if(n_elements(_super) gt 0) then $
        self->IDLitWriter::GetProperty, _EXTRA=_super

end


;---------------------------------------------------------------------------
pro IDLitWriteJPEG2000::SetProperty, $
    N_LAYERS=nLayers, $
    N_LEVELS=nLevels, $
    REVERSIBLE=reversible, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (n_elements(nLayers) ne 0) then $
        self._nLayers = nLayers > 1

    if (n_elements(nLevels) ne 0) then $
        self._nLevels = 0 > nLevels < 15

    if (n_elements(reversible) ne 0) then $
        self._reversible = reversible

    if (n_elements(_super) gt 0) then $
        self->IDLitWriter::SetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   ImageData: An object reference to the data to be written.
;
; Keywords:
;   None.
;
function IDLitWriteJPEG2000::SetData, oImageData

    compile_opt idl2, hidden

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, $
        /MULTICHANNEL)) then $
        return, 0

    strFilename = self->GetFilename()

    WRITE_JPEG2000, strFilename, image, red, green, blue, $
        N_LAYERS=self._nLayers, $
        N_LEVELS=self._nLevels, $
        REVERSIBLE=self._reversible

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteJPEG2000__Define

    compile_opt idl2, hidden

    void = {IDLitWriteJPEG2000, $
        inherits IDLitWriter, $
        _nLayers: 0s, $
        _nLevels: 0s, $
        _reversible: 0b $
        }
end
