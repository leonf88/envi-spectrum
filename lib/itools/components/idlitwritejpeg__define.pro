; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwritejpeg__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteJPEG class.
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
;   QUALITY: Set this keyword to the percent quality for the JPEG file.
;
;   All superclass keywords.
;
function IDLitWriteJPEG::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if (~self->IDLitWriter::Init(['jpg','jpeg'], $
       TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
        NAME='Joint Photographic Experts Group', $
        DESCRIPTION="Joint Photographic Experts Group (jpeg)", $
        ICON='demo', $
        _EXTRA=_extra)) then $
        return, 0

    ; Initialize ourself

    ; This keyword is actually implemented in the superclass, but we
    ; only register it with writers that require it.
    self->RegisterProperty, 'GRAYSCALE', $
        ENUMLIST=['TrueColor', 'Grayscale'], $
        NAME='Color', $
        DESCRIPTION='Force the image to be written as TrueColor or Grayscale'

    ; Register properties
    self->RegisterProperty, 'Quality', /INTEGER, $
        VALID_RANGE=[0,100,5], $
        Description='Image quality'

    ; Set defaults.
    self._quality = 90

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriteJPEG::SetProperty, _EXTRA=_extra

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
;pro IDLitWriteJPEG::Cleanup
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
pro IDLitWriteJPEG::GetProperty, $
    QUALITY=quality, $
    GRAYSCALE=grayscale, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    ; Use our superclass BIT_DEPTH property.
    if (ARG_PRESENT(grayscale)) then $
        grayscale =  (self._bitDepth eq 1)

    if (ARG_PRESENT(quality)) then $
        quality =  self._quality

    if(n_elements(_super) gt 0) then $
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
pro IDLitWriteJPEG::SetProperty, $
    GRAYSCALE=grayscale, $
    QUALITY=quality, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(quality) ne 0) then $
        self._quality = quality

    ; Use our superclass BIT_DEPTH property.
    if (N_ELEMENTS(grayscale) eq 1) then $
        self._bitDepth = KEYWORD_SET(grayscale) ? 1 : 2

    if(n_elements(_super) gt 0)then $
        self->IDLitWriter::SetProperty, BIT_DEPTH=bitDepth, _EXTRA=_super
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
function IDLitWriteJPEG::SetData, oImageData

    compile_opt idl2, hidden

    ; Use our superclass BIT_DEPTH property. Don't allow BIT_DEPTH=0 (Auto).
    if (~self._bitDepth) then $
        self._bitDepth = 2

    if (~self->IDLitWriter::_GetImageData(oImageData, $
        image, red, green, blue, HAS_PALETTE=hasPalette)) then $
        return, 0

    strFilename = self->GetFilename()

    isTrue = SIZE(image, /N_DIMENSIONS) eq 3
    WRITE_JPEG, strFilename, image, TRUE=isTrue, QUALITY=self._quality

    return, 1  ; success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteJPEG__Define

    compile_opt idl2, hidden

    void = {IDLitWriteJPEG, $
        inherits IDLitWriter, $
        _quality : 0 $
        }
end
