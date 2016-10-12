; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlimage__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataIDLImage
;
; PURPOSE:
;   This file implements the IDLitDataIDLImage class.
;   This class is used to store image data and palette information
;   suitable for use with IDL image objects.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataIDLImage::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataIDLImage::Init
;
; Purpose:
; The constructor of the IDLitDataIDLImage object.
;
; Parameters:
;   Image    - (optional) The image data to store in the object.
;     This may be either:
;        - a 2D array
;        - a reference to an IDLitDataIDLImagePixels object
;   Palette  - (optional) The palette data to store in the object
;     This may be either:
;        - a 3x256 array
;        - a reference to an IDLitDataPalette object
;
; Properties:
;   See properties from superclass
;
function IDLitDataIDLImage::Init, Image, Palette, NAME=NAME,  $
                       ICON=ICON, _EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    if (~keyword_set(name)) then name = "Image"
    if (~keyword_set(ICON)) then ICON="demo"

    ; Init superclass
    if(self->IDLitDataContainer::Init(TYPE='IDLIMAGE', name=name, $
                                      ICON=ICON, _EXTRA=_extra) eq 0) then $
        return, 0

    ; If a palette was provided, store it.  Otherwise, do not
    ; create until needed.  In either case, do not add the palette
    ; to this image data container until it is needed.
    objRefType = 11
    if (n_elements(Palette) ne 0) then begin
        if (SIZE(Palette, /TYPE) eq objRefType) then begin
            if (OBJ_ISA(Palette, 'IDLitDataIDLPalette')) then $
                self._oPalette = Palette
        endif else begin
            ; Create the palette data object.
            self._oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                NAME='Palette')
            self._bFreePalette = 1b

            ; Store the given palette data.
            result = self._oPalette->SetData(Palette, _EXTRA=_extra)
            if (result eq 0) then begin
                self->Cleanup
                return, 0
            endif
        endelse
    endif

    ; Prepare image pixel planes.
    oImagePixels = OBJ_NEW()
    bSetImageData = 0b
    if (N_ELEMENTS(Image) ne 0) then begin
        if (SIZE(Image, /TYPE) eq objRefType) then begin
            if (OBJ_ISA(Image, 'IDLitDataIDLImagePixels')) then $
                oImagePixels = Image
        endif else $
            bSetImageData = 1b
    endif

    if (~OBJ_VALID(oImagePixels)) then begin
        oImagePixels = OBJ_NEW('IDLitDataIDLImagePixels', $
            NAME='Image Planes', IDENTIFIER='ImagePixels')
            self._bFreePixels = 1b
    endif

    if (bSetImageData) then begin
        result = oImagePixels->SetData(Image, _EXTRA=_extra)
        if (result eq 0) then begin
            self->Cleanup
            return, 0
        endif
    endif

    self->Add, oImagePixels

    ; Register properties

    ; Note - For now, the interleave setting is de-sensitized
    ; since it is unusual to want to change the interleaving after
    ; the initial display.
    self->RegisterProperty, 'INTERLEAVE', $
        NAME='Interleaving', $
        SENSITIVE=0, $
        ENUMLIST=['Pixel','Scanline','Planar'], $
        DESCRIPTION='Interleave setting for image data'

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataIDLImage::SetProperty, _extra=_extra

    return, 1
end

;---------------------------------------------------------------------------
; IDLitDataIDLImage::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitDataIDLImage::Cleanup

   compile_opt idl2, hidden

    if (self._bFreePixels) then begin
        oPixelData = self->GetByType("IDLIMAGEPIXELS")
        if (OBJ_VALID(oPixelData)) then begin
            self->Remove, oPixelData
            OBJ_DESTROY, oPixelData
        endif
    endif

    if (OBJ_VALID(self._oPalette)) then begin
        if (self._bFreePalette) then begin
            self->Remove, self._oPalette
            OBJ_DESTROY, self._oPalette
        endif
    endif

    ; Cleanup superclass
    self->IDLitDataContainer::Cleanup
end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitDataIDLImage::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;

pro IDLitDataIDLImage::GetProperty, $
    CMYK=cmyk, $
    INTERLEAVE=interleave, $
    RESOLUTION=resolution, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (ARG_PRESENT(cmyk)) then cmyk = self._bIsCMYK

    if (ARG_PRESENT(resolution)) then $
        resolution = self._resolution

    if(arg_present(interleave))then begin
        oPixels = self->GetByIdentifier("IMAGEPIXELS")
       if(obj_Valid(oPixels))then $
         oPixels->GetProperty, INTERLEAVE=interleave $
       else $
         interleave = 0b
    endif
    if(n_elements(_super) gt 0)then $
        self->IDLitDataContainer::GetProperty, _EXTRA=_super

end

;---------------------------------------------------------------------------
; IDLitDataIDLImage::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
;

pro IDLitDataIDLImage::SetProperty, $
    CMYK=cmyk, $
    INTERLEAVE=interleave, $
    RESOLUTION=resolution, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(cmyk)) then self._bIsCMYK = KEYWORD_SET(cmyk)

    if (N_ELEMENTS(resolution) eq 1) then $
        self._resolution = resolution

    if(n_elements(interleave) ne 0) then begin
        oPixels = self->GetByIdentifier("IMAGEPIXELS")
        if(obj_Valid(oPixels))then $
            oPixels->SetProperty, INTERLEAVE=interleave
    endif
    if(n_elements(_super) gt 0)then $
        self->IDLitDataContainer::SetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
; Image Data Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitDataIDLImage::_PreparePalette
;
; Purpose:
;   Creates and/or adds a palette as appropriate based upon the
;   current image pixel data.
;
pro IDLitDataIDLImage::_PreparePalette

    compile_opt idl2, hidden

    bNeedPalette = 0b
    oPixelData = self->GetByType("IDLIMAGEPIXELS")
    if (OBJ_VALID(oPixelData)) then begin
        success = oPixelData->GetData(pData, /POINTER)
        if (success) then begin
            nPlanes = N_ELEMENTS(pData)
            if (nPlanes eq 1) then $
                bNeedPalette = 1b
        endif

        if (bNeedPalette) then begin
            ; Create a palette if none already available.
            if (~OBJ_VALID(self._oPalette)) then begin
                self._oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                    NAME='Palette')
                self._bFreePalette = 1b
            endif

            ; Check if current palette is "empty".
            success = self._oPalette->GetData(pPalData, /POINTER)
            if (success) then $
                if (N_ELEMENTS(*pPalData) eq 0) then success = 0

            ; If necessary, initialize with grayscale ramp.
            if (~success) then begin
                ramp = BINDGEN(256)
                success = self._oPalette->SetData( $
                    TRANSPOSE([[ramp],[ramp],[ramp]]))
            endif

            ; If not already contained, add the palette.
            if (success and (~self->isContained(self._oPalette))) then $
                self->IDLitDataContainer::Add, self._oPalette
        endif else begin
            ; If previously contained, remove the palette.
            if (self->IsContained(self._oPalette)) then $
                self->Remove, self._oPalette
        endelse
    endif
end

;---------------------------------------------------------------------------
; IDLitDataIDLImage::SetPalette
;
; Purpose:
;   Sets the palette to the given palette data.
;
; Parameters:
;   Palette  - (optional) The palette data to store in the object
;     This may be either:
;        - a 3x256 array
;        - a reference to an IDLitDataPalette objec
;
; Return Value:
;   Returns a 1 on success, or a 0 on failure.
function IDLitDataIDLImage::SetPalette, palette

    compile_opt idl2, hidden

    objRefType = 11

    if (N_ELEMENTS(Palette) eq 0) then $
        return, 0

    if (SIZE(Palette, /TYPE) eq objRefType) then begin
        if (OBJ_ISA(Palette, 'IDLitDataIDLPalette')) then begin
            ; Remove, and if appropriate, destroy old palette.
            wasContained = self->IsContained(self._oPalette)
            if (OBJ_VALID(self._oPalette)) then begin
                self->Remove, self._oPalette
                if (self._bFreePalette) then $
                    OBJ_DESTROY, self._oPalette
            endif
            self._oPalette = Palette

            if (wasContained) then $
                self->IDLitDataContainer::Add, self._oPalette

            self._bFreePalette = 0b
            result = 1
        endif else $
            result = 0
    endif else begin
        if (~OBJ_VALID(self._oPalette)) then begin
            self._oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                NAME='Palette')
            self._bFreePalette = 1b
            if (~OBJ_VALID(self._oPalette)) then $
                return, 0
        endif
        result = self._oPalette->SetData(Palette, _EXTRA=_extra)
    endelse

    return, result
end

;---------------------------------------------------------------------------
; Container Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitDataIDLImage::Add
;
; Purpose:
;    Override the add method so that the palette can be prepared as
;    needed.
;
pro IDLitDataIDLImage::Add, oData, _REF_EXTRA=_extra
    compile_opt idl2, hidden

    prepPalette = 0b
    for i=0, n_elements(oData)-1 do begin
        if (OBJ_ISA(oData[i], 'IDLitDataIDLImagePixels')) then begin
            ; This class is designed to only contain one ImagePixels
            ; object at a time.  If it already contains one, remove
            ; the old one.
            oOldPixelData = self->GetByType("IDLIMAGEPIXELS")
            if (OBJ_VALID(oOldPixelData)) then begin
                self->Remove, oOldPixelData
                if (self._bFreePixels) then begin
                    OBJ_DESTROY, oOldPixelData
                    self._bFreePixels = 0b
                endif
            endif
            prepPalette = 1b

            ; Pass on to superclass.
            self->IDLitDataContainer::Add, oData, _EXTRA=_extra

        endif else if (OBJ_ISA(oData[i], 'IDLitDataIDLPalette')) then begin
            ; This will replace this image's palette, and add it to the
            ; data container as necessary.
            success = self->SetPalette(oData[i])
            ; Pass on to superclass.
            self->IDLitDataContainer::Add, oData, _EXTRA=_extra
        endif else begin
            ; Pass on to superclass.
            self->IDLitDataContainer::Add, oData, _EXTRA=_extra
        endelse
    endfor

    ; Update palette if need be.
    if (prepPalette) then $
        self->_PreparePalette
end

;---------------------------------------------------------------------------
; Data Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitDataIDLImage::OnDataComplete
;
; Purpose:
;    Called when this message was sent by the subject.
;
; Parameters:
;    oSubject  - The item that triggered the message

pro IDLitDataIDLImage::OnDataComplete, oSubject
    compile_opt idl2, hidden

    ; Pass on to superclass.
    self->IDLitDataContainer::OnDataComplete, oSubject

    ; If the image data changed, determine whether the palette needs
    ; to be added or removed from this container.
    if (OBJ_ISA(oSubject, 'IDLitDataIDLImagePixels')) then $
        self->_PreparePalette
end

;---------------------------------------------------------------------------
; Object Definition
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitDataIDLImage__Define
;
; Purpose:
; Class definition for the IDLitDataIDLImage class
;

pro IDLitDataIDLImage__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitDataIDLImage, $
          inherits   IDLitDataContainer, $ ; Superclass.
          _oPalette: OBJ_NEW(),          $ ; Palette data object
          _interleave   : 0B,            $ ; Interleave setting
          _bFreePixels: 0B,              $ ; Free image pixels on cleanup?
          _bFreePalette: 0B,             $ ; Free palette on cleanup?
          _bIsCMYK: 0b,                  $ ; Pixels are CMYK, not RGB
          _resolution : 0d               $ ; image resolution in DPI
         }
end
