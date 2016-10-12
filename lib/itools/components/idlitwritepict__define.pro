; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritepict__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWritePICT class.
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
function IDLitWritePICT::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if (~self->IDLitWriter::Init('pict', $
       TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
       NAME="Macintosh PICT", $
       DESCRIPTION="Macintosh PICT (Version 2)", $
       ICON='demo', $
       _EXTRA=_extra)) then $
        return, 0

    ; PICT is only 8-bit so force a color quantize.
    self._bitDepth = 1

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
;pro IDLitWritePICT::Cleanup
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
function IDLitWritePICT::SetData, oImageData

    compile_opt idl2, hidden

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, HAS_PALETTE=hasPalette)) then $
        return, 0

    strFilename = self->GetFilename()

    ; PICT defaults to the current color table, so we better
    ; build a grayscale if necessary.
    if (~hasPalette) then begin
        red = BINDGEN(256)
        green = red
        blue = red
    endif

    WRITE_PICT, strFilename, image, red, green, blue

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWritePICT__Define

    compile_opt idl2, hidden

    void = {IDLitWritePICT, $
        inherits IDLitWriter $
        }
end
