; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritepng__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWritePNG class.
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
function IDLitWritePNG::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if (~self->IDLitWriter::Init('png', $
       TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
       NAME='Portable Network Graphics', $
       DESCRIPTION="Portable Network Graphics (png)", $
       ICON='demo', $
       _EXTRA=_extra)) then $
        return, 0

    ; This keyword is actually implemented in the superclass, but we
    ; only register it with writers that require it.
    self->RegisterProperty, 'BIT_DEPTH', $
        ENUMLIST=['Automatic', '8 bit', '24 bit'], $
        NAME='Bit depth', $
        DESCRIPTION='Bit depth at which to write the image'

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
;pro IDLitWritePNG::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitWriter::Cleanup
;end


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
function IDLitWritePNG::SetData, oImageData

    compile_opt idl2, hidden

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, HAS_PALETTE=hasPalette, $
        /MULTICHANNEL)) then $
        return, 0

    strFilename = self->GetFilename()

    ; PNG allows up to 4 channels.
    if (SIZE(image, /N_DIM) eq 3 && (SIZE(image, /DIM))[0] gt 4) then $
        image = image[0:3, *, *]

    oImageData->GetProperty, RESOLUTION=resolution

    WRITE_PNG, strFilename, image, red, green, blue, $
      XRESOLUTION=resolution, YRESOLUTION=resolution

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWritePNG__Define

    compile_opt idl2, hidden

    void = {IDLitWritePNG, $
        inherits IDLitWriter $
        }
end
