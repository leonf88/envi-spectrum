; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitwriter__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriter class. This class is an abstract
;   class for other file writers.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitWriter object.
;
; Arguments:
;   Extensions   - A string scalar or array of the file extensions
;                  associated with this file type.
;
; Keywords:
;   TYPES  - The data types this writer can accept.
;
;   All are passed to it's superclass.
;
function IDLitWriter::Init, Extensions, TYPES=TYPES, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitComponent::Init(_EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitFileIOAttrs::Init(Extensions, _EXTRA=_extra)) then begin
        self->IDLitComponent::Cleanup
        return, 0
    endif

    self._types = ptr_new('')
    if (n_elements(types) gt 0) then $
        *self._types = types

    self._scaleFactor = 1.0

    self->SetPropertyAttribute, 'NAME', SENSITIVE=0
    self->SetPropertyAttribute, 'DESCRIPTION', SENSITIVE=0, /HIDE

    ; Set the rest.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitWriter::SetProperty, _EXTRA=_extra

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Standard cleanup method for object lifecycle. This just passes
;   control to superclasses.
;
pro IDLitWriter::Cleanup
    compile_opt hidden, idl2

    self->_IDLitFileIOAttrs::Cleanup
    self->IDLitComponent::Cleanup
    ptr_free, self._types
end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitWriter::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;    TYPES   - The data types supported by this writer
;
;    All keywords are passed to the superclasses
;
pro IDLitWriter::GetProperty, $
    BITMAP=bitmap, $
    BIT_DEPTH=bitDepth, $
    GRAPHICS_FORMAT=graphicsFormat, $
    SCALE_FACTOR=scaleFactor, $
    TYPES=TYPES, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (arg_present(types)) then $
        types = *self._types

    if (ARG_PRESENT(bitDepth)) then $
        bitDepth = self._bitDepth

    if (ARG_PRESENT(graphicsFormat)) then $
        graphicsFormat = self._graphicsFormat

    if (ARG_PRESENT(scaleFactor)) then $
        scaleFactor = self._scaleFactor

    if (ARG_PRESENT(bitmap) eq 1) then $
        bitmap = self._graphicsFormat ? 0b : 1b

    if(n_elements(_super) gt 0) then begin
        self->IDLitComponent::GetProperty, _EXTRA=_super
    endif

end


;---------------------------------------------------------------------------
; IDLitWriter::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
;
; Arguments:
;   None.
;
; Keywords:
;   All properties are passed to the super-class
;
pro IDLitWriter::SetProperty, $
    BITMAP=bitmap, $
    BIT_DEPTH=bitDepth, $
    GRAPHICS_FORMAT=graphicsFormat, $
    HAS_CMYK=hasCMYK, $
    SCALE_FACTOR=scaleFactor, $
    _EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(bitDepth) eq 1) then $
        self._bitDepth = bitDepth

    if (N_ELEMENTS(graphicsFormat) eq 1) then $
        self._graphicsFormat = graphicsFormat

    if (N_ELEMENTS(bitmap) eq 1) then $
        self._graphicsFormat = ~KEYWORD_SET(bitmap)

    if (N_ELEMENTS(scaleFactor) eq 1) then $
        self._scaleFactor = scaleFactor

    if (N_ELEMENTS(hasCMYK)) then $
      self._hasCMYK = KEYWORD_SET(hasCMYK)

    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::SetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   This routine is called to set the data in the file. It is the
;   resonsiblity of the subclass to implement the logic of this
;   routine so it can write the file of the particular type.
;
; Parameters:
;   oData [out]   - This routine will write this data object.
;
; Keywords:
;   None.
;
; Return Value:
;    1 - Successful write
;
;    0 - Failure writing to the file.
;
function IDLitWriter::SetData, oData
   compile_opt hidden, idl2
   return, 0
end


;---------------------------------------------------------------------------
; HAS_PALETTE: Set this keyword to a named variable in which to return
;   a 1 if the image has an associated palette, or a 0 otherwise.
;
; MULTICHANNEL: Set this keyword to return all of the image channels.
;   The default behavior is to return only the first 3 channels.
;   This keyword is useful for file formats that handle multiple channels
;   such as TIFF.
;
function IDLitWriter::_GetImageData, oItem, $
    image, red, green, blue, $
    HAS_PALETTE=hasPalette, $
    MULTICHANNEL=multiChannel

    compile_opt hidden, idl2

    strFilename = self->GetFilename()
    if (strFilename eq '') then $
        return, 0 ; failure

    if (~OBJ_VALID(oItem)) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:Framework:InvalidImage')], $
          title=IDLitLangCatQuery('Error:Error:Title'), severity=2
        return, 0 ; failure
    endif

    ; First look for some image data.
    oData = (oItem->GetByType("IDLIMAGEPIXELS"))[0]

    if (OBJ_VALID(oData)) then begin
        oData->GetProperty, INTERLEAVE=interleave
    endif else begin
        ; No image pixels, how about a 2D array.
        oData = (oItem->GetByType("IDLARRAY2D"))[0]
        interleave = 0
    endelse

    if (~OBJ_VALID(oData)) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:Framework:InvalidWriteData')], $
          title=IDLitLangCatQuery('Error:Error:Title'), severity=2
        return, 0 ; failure
    end

    if (oData->GetData(image) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:Framework:InvalidImage'), $
          IDLitLangCatQuery('Error:Framework:CannotRetrieveInfo')], $
          title=IDLitLangCatQuery('Error:Error:Title'), severity=2
        return, 0 ; failure
    endif

    ; Now look for a palette.
    if (~OBJ_VALID(oPalette)) then $
        oPalette = (oItem->GetByType("IDLPALETTE"))[0]

    if (~OBJ_VALID(oPalette)) then begin
        ; Be nice and search in our parent for a palette.
        ; This can happen if the user doesn't create an IDLIMAGE object
        ; but just stuffs an IDLIMAGEPIXELS or an IDLARRAY2D into a container.
        oItem->GetProperty, _PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oPalette = (oParent->GetByType("IDLPALETTE"))[0]
    endif

    hasPalette = 0
    if (OBJ_VALID(oPalette)) then begin
        success = oPalette->GetData(palette)
        hasPalette = N_ELEMENTS(palette) ge 3
    endif

    ; Need to make sure we have byte data.
    if (SIZE(image, /TYPE) ne 1 && ~hasPalette) then begin
        ; If we don't have a palette, also bytescale.
        image = hasPalette ? BYTE(image) : BYTSCL(image)
    endif


    ndim = SIZE(image, /N_DIMENSIONS)
    dims = SIZE(image, /DIMENSIONS)


    ; Convert to pixel interleaved if necessary.
    case interleave of
        0:  ; do nothing
        1:  image = TRANSPOSE(image, [1, 0, 2])
        2:  image = REFORM(TRANSPOSE( $
            REFORM(image, dims[0]*dims[1], dims[2], /OVERWRITE) $
            ), dims[2], dims[0], dims[1])
    endcase

    ; Recompute dimensions in case it changed.
    dims = SIZE(image, /DIMENSIONS)

    if (ndim ne 2 && ndim ne 3) then $
        return, 0  ; failure

    if (ndim eq 2) then begin
        ; Check if we have palette data.
        if (hasPalette) then begin
            red = REFORM(palette[0,*])
            green = REFORM(palette[1,*])
            blue = REFORM(palette[2,*])
        endif
    endif else begin
        if (~KEYWORD_SET(multiChannel)) then begin
            ; If we have more than 3 channels, just keep
            ; the first 3 (assumed to be RGB).
            case dims[0] of
                2: begin
                    ndim = 1
                    dims = dims[1:*]
                    image = REFORM(image[0, *, *])
                   end
                3:  ; do nothing
                else: image = image[0:2, *, *]
            endcase
        endif
    endelse


    case self._bitDepth of

        0: ; Automatic, don't convert from 8 bit to 24 bit or vice versa.

        1: if (ndim eq 3) then begin  ; 24 bit down to 8 bit
            image = COLOR_QUAN(image, 1, red, green, blue, COLORS=256)
            hasPalette = 1
           endif

        2: if (ndim eq 2) then begin  ; 8 bit up to 24 bit
            if (hasPalette) then begin
                hasPalette = 0
                red = red[image]
                green = green[image]
                blue = blue[image]
                image = [[[TEMPORARY(red)]], $
                    [[TEMPORARY(green)]], $
                    [[TEMPORARY(blue)]]]
                image = TRANSPOSE(image, [2, 0, 1])
            endif else begin
                image = REBIN(REFORM(image, 1, dims[0], dims[1]), $
                    3, dims[0], dims[1])
            endelse
           endif

        else:

    endcase


    return, 1

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition for the IDLitWriter class
;
pro IDLitWriter__Define

  compile_opt idl2, hidden

  void = {IDLitWriter, $
          inherits         IDLitComponent,    $
          inherits         _IDLitFileIOAttrs,   $
          _types     : ptr_new(), $
          _bitdepth  : 0b, $
          _graphicsFormat : 0b, $  ; bitmap or vector
          _hasCMYK: 0b, $
          _scaleFactor : 0.0 $
         }
end
