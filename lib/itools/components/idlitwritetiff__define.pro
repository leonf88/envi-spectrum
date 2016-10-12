; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritetiff__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteTIFF class.
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
function IDLitWriteTIFF::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if (~self->IDLitWriter::Init(['tif','tiff'], $
        TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
        NAME="Tag Image File Format", $
        DESCRIPTION="Tag Image File Format (TIFF)", $
        ICON='demo', $
        _EXTRA=_extra)) then $
        return, 0

    ; This keyword is actually implemented in the superclass, but we
    ; only register it with writers that require it.
    self->RegisterProperty, 'BIT_DEPTH', $
        ENUMLIST=['Automatic', '8 bit', '24 bit'], $
        NAME='Bit depth', $
        DESCRIPTION='Bit depth at which to write the image'

    self->RegisterProperty, 'Compression', $
        ENUMLIST=['None', 'Packbits', 'JPEG'], $
        DESCRIPTION='Type of compression to use'

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
; The destructor for the class.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitWriteTIFF::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitWriter::Cleanup
;end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;   All ::Init keywords.
;
pro IDLitWriteTIFF::GetProperty, $
    COMPRESSION=compression, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(compression)) then $
        compression =  self._compression

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitWriter::GetProperty, _EXTRA=_super

end


;---------------------------------------------------------------------------
; Purpose:
;   Used to set the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;   All ::Init keywords.
;
pro IDLitWriteTIFF::SetProperty, $
    COMPRESSION=compression, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(compression) ne 0) then $
        self._compression = compression

    if (N_ELEMENTS(_super) gt 0) then $
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
function IDLitWriteTIFF::SetData, oImageData

    compile_opt idl2, hidden

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, HAS_PALETTE=hasPalette, $
        /MULTICHANNEL)) then $
        return, 0

    ndim = SIZE(image, /N_DIMENSIONS)

    strFilename = self->GetFilename()

    ; Convert from our COMPRESSION property to the TIFF keyword.
    ; It's missing a value because LZW is no longer available.
    case self._compression of
        1: compression = 2
        2: compression = 3
        else: compression = 0
    endcase

    oImageData->GetProperty, CMYK=cmyk, RESOLUTION=resolution
    
    ; The REVERSE ensures that other applications will read in
    ; the image right side up.
    if (hasPalette) then begin
        WRITE_TIFF, strFilename, REVERSE(image, ndim), $
            COMPRESSION=compression, $
            RED=red, GREEN=green, BLUE=blue, $
            ORIENTATION=1, XRESOL=resolution, YRESOL=resolution
    endif else begin
        WRITE_TIFF, strFilename, REVERSE(image, ndim), $
            CMYK=cmyk, $
            COMPRESSION=compression, $
            ORIENTATION=1, XRESOL=resolution, YRESOL=resolution
    endelse

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteTIFF__Define

    compile_opt idl2, hidden

    void = {IDLitWriteTIFF, $
        inherits IDLitWriter, $
        _compression: 0b $
        }
end
