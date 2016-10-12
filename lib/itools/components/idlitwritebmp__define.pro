; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritebmp__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteBMP class.
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
function IDLitWriteBMP::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitWriter::Init('bmp', $
        NAME='Windows Bitmap', $
        TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
        DESCRIPTION="Bitmap image file", $
        ICON='demo', $
        _EXTRA=_extra) eq 0) then $
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
;pro IDLitWriteBMP::Cleanup
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
function IDLitWriteBMP::SetData, oImageData

    compile_opt idl2, hidden

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, HAS_PALETTE=hasPalette)) then $
        return, 0

    strFilename = self->GetFilename()

    ; WRITE_BMP is much more efficient if you pass it BGR rather than RGB.
    if (SIZE(image, /N_DIM) eq 3) then begin
        dims = SIZE(image, /DIMENSIONS)
        image = REFORM(ROTATE(REFORM(image, 3, dims[1]*dims[2], $
            /OVERWRITE), 5), 3, dims[1], dims[2])
    endif

    if (hasPalette) then $
        WRITE_BMP, strFilename, image, red, green, blue $
    else $
        WRITE_BMP, strFilename, image


    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteBMP__Define

    compile_opt idl2, hidden

    void = {IDLitWriteBMP, $
        inherits IDLitWriter $
        }
end
