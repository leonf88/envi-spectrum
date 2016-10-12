; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitfont__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitFont
;
; PURPOSE:
;    The IDLitFont class is the component wrapper for IDLgrFont.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLgrFont
;
; SUBCLASSES:
;
; METHODS:
;  Intrinisic Methods
;    IDLitFont::Cleanup
;    IDLitFont::Init
;
; MODIFICATION HISTORY:
;     Written by:   Chris, August 2002
;     CT, Oct 2006: Added support for system fonts. Added FONT_NAME property.
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitFont::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitFont')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrFont
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitFont::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitComponent::Init(NAME='IDLitFont')) then return, 0

    self._oFont = OBJ_NEW('IDLgrFont')
    self._oFont->SetProperty, SIZE=16
    self._fontSize = 16
    self._fontZoom = 1.0
    self._viewZoom = 1.0
    self._fontNorm = 1.0

    self->IDLitFont::_RegisterProperties

    ; Set any properties. Set default font.
    self->IDLitFont::SetProperty, FONT_NAME='Helvetica', _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
pro IDLitFont::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont
    Ptr_Free, self._pFonts

    ; Cleanup superclass
    self->IDLitComponent::Cleanup

end

;----------------------------------------------------------------------------
pro IDLitFont::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        ; Register font properties. This enumlist will get replaced below.
        self->RegisterProperty, 'FONT_NAME', $
            /STRING, $
            NAME='Font name', $
            DESCRIPTION='Font name', /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'FONT_INDEX', $
            ENUMLIST=['Helvetica', 'Courier', 'Times', 'Symbol', 'Hershey'], $
            NAME='Text font', $
            DESCRIPTION='Font name', /ADVANCED_ONLY

        self->RegisterProperty, 'FONT_STYLE', $
            ENUMLIST=['Normal', 'Bold', 'Italic', 'Bold Italic'], $
            NAME='Text style', $
            DESCRIPTION='Font style', /ADVANCED_ONLY

        self->RegisterProperty, 'FONT_SIZE', /FLOAT, $
            NAME='Text font size', $
            DESCRIPTION='Font size in points'
    endif

    ; We want to update the list of fonts each time this object
    ; gets created or restored.

    ; Collect all possible TrueType fontnames.
    oBuff = OBJ_NEW('IDLgrBuffer', DIMENSIONS=[2,2])
    fontNames = oBuff->GetFontnames('*', STYLES='')
    OBJ_DESTROY, oBuff

    hershey = 'Hershey ' + $
        ['3 Simplex', '4 Simplex Greek', '5 Duplex Roman', $
        '6 Complex Roman', '7 Complex Greek', $
        '8 Complex Italic', '9 Math and Special', $
        '11 Gothic English', '12 Simplex Script', '13 Complex Script', $
        '14 Gothic Italian', '15 Gothic German', '16 Cyrillic', $
        '17 Triplex Roman', '18 Triplex Italic', '20 Miscellaneous']
    sysFonts = ['Helvetica', 'Courier', 'Times', 'Symbol', hershey]

    keep = Where((fontNames ne 'Helvetica') and $
        (fontNames ne 'Courier') and $
        (fontNames ne 'Times') and $
        (fontNames ne 'Symbol'), nkeep)
    if (nkeep gt 0) then begin
        fontNames = [Temporary(sysFonts), fontNames[keep]]
    endif else begin
        fontNames = Temporary(sysFonts)
    endelse

    self->SetPropertyAttribute, 'FONT_INDEX', ENUMLIST=fontNames

end

;----------------------------------------------------------------------------
; IDLitFont::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitFont::Restore
    compile_opt idl2, hidden

    ; No need to call superclass restore (IDLitComponent::Restore)

	; Convert from the old font index to the new font index.
	; We need to do this regardless of IDL version because the system
	; font list can change at any time.
	; Get name of current font family (using the old list).
	self->IDLitFont::GetProperty, FONT_NAME=fontName

    ; Register new properties. This will also update the font list.
    self->IDLitFont::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

	; Set the current font name to convert to the new font index.
    if (fontName eq 'Hershey') then begin
        ; For Hershey, convert from using styles to the actual names.
        case (self._fontStyle) of
        1: fontName = 'Hershey 17 Triplex Roman'
        2: fontName = 'Hershey 8 Complex Italic'
        3: fontName = 'Hershey 18 Triplex Italic'
        else: fontName = 'Hershey 3 Simplex'
        endcase
        self._fontStyle = 0
    endif

	self->IDLitFont::SetProperty, FONT_NAME=fontName

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        self._oFont->GetProperty, SIZE=fSize
        self._fontSize = fSize
        self._fontZoom = 1.0
    endif

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      to 6.2 or above:
    if (self.idlitcomponentversion lt 620) then begin
        self._viewZoom = 1.0
        self._fontNorm = 1.0
    endif

end

;----------------------------------------------------------------------------
; Internal function to convert a font family and style into a font name.
;
function IDLitFont::_GetFontName

    compile_opt idl2, hidden

    self->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=families
    family = families[self._fontIndex]
    families = 0  ; free memory
    style = 0 > self._fontStyle < 3

    ; For Hershey fonts append the font number.
    if (Strmid(family,0,7) eq 'Hershey') then begin
        index = Strmid(family,7,3)
        self._fontStyle = 0
        self->SetPropertyAttribute,'FONT_STYLE', SENSITIVE=0
        fontName = 'Hershey*' + Strtrim(Abs(index),2)
    	return, fontName
    endif

	; For bold or italic make sure the font supports that style.
    if (~Ptr_Valid(self._pFonts)) then begin
	    ; Find list of all fonts including the font styles.
        oBuff = Obj_New('IDLgrBuffer', DIMENSIONS=[2,2])
        self._pFonts = Ptr_New(oBuff->GetFontnames('*', STYLES='*'))
        Obj_Destroy, oBuff
        Heap_Nosave, self._pFonts
    endif

    ; Substitute in the common names of our built-in fonts in place of their TrueType names
    test =    ['Courier 10 Pitch BT', 'Dutch 801 BT', 'Dutch 801 Roman BT', $
               'Swiss 721 BT', 'Symbol Monospaced BT', 'Symbol Proportional BT']
    replace = ['Courier', 'Times', 'Times', 'Helvetica', 'Monospace Symbol',  'Symbol']
    index = where(test eq family)
    if (index[0] ne -1) then family = replace[index[0]]
    
    case (style) of
    0: fontName = family
    1: fontName = family + ' Bold'
    2: fontName = family + ' Italic'
    3: fontName = family + ' Bold Italic'
    endcase

    ; See if this font supports different styles. Just try bold.
    hasStyles = (Where(*self._pFonts eq (family + ' Bold')))[0] ge 0
    self->SetPropertyAttribute,'FONT_STYLE', SENSITIVE=hasStyles
    if (~hasStyles) then self._fontStyle = 0

    ; Try to match the full font name.
    hasMatch = (Where(*self._pFonts eq fontName))[0] ge 0

    if (hasMatch) then begin
      ; Convert from font names with spaces to font names with stars,
      ; so that export to postscript will work correctly.
      case (style) of
      0: fontName = family
      1: fontName = family + '*Bold'
      2: fontName = family + '*Italic'
      3: fontName = family + '*Bold*Italic'
      endcase
    endif else begin
      ; No match, just return the family.
      fontName = family
    endelse

    return, fontName

end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitFont::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitFont::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitFont::Init followed by the word "Get"
;      can be retrieved using IDLitFont::GetProperty.
;
;-
pro IDLitFont::GetProperty, $
    FONT_INDEX=fontIndex, $
    FONT_NAME=fontName, $
    FONT_NORM=fontNorm, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    FONT_ZOOM=fontZoom, $
    VIEW_ZOOM=viewZoom, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get my properties
    if ARG_PRESENT(fontIndex) then fontIndex = self._fontindex
    if (Arg_Present(fontName)) then begin
        self->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=fonts
	    fontName = fonts[self._fontIndex < (N_Elements(fonts)-1)]
    endif
    if ARG_PRESENT(fontStyle) then fontStyle = self._fontstyle
    ; Report un-zoomed font size.
    if ARG_PRESENT(fontSize) then fontSize = self._fontsize
    if ARG_PRESENT(fontZoom) then fontZoom = self._fontzoom
    if ARG_PRESENT(viewZoom) then viewZoom = self._viewZoom
    if ARG_PRESENT(fontNorm) then fontNorm = self._fontNorm

    ; Get superclass properties
    self->IDLitComponent::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitFont::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitFont::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitFont::Init followed by the word "Set"
;      can be set using IDLitFont::SetProperty.
;-
pro IDLitFont::SetProperty,  $
    FONT_INDEX=fontIndex, $
    FONT_NAME=fontNameIn, $
    FONT_NORM=fontNorm, $
    FONT_STYLE=fontStyle, $
    FONT_SIZE=fontSize, $
    FONT_ZOOM=fontZoom, $
    VIEW_ZOOM=viewZoom, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Set font properties.
    if (N_ELEMENTS(fontNameIn) || N_ELEMENTS(fontIndex) || $
        N_ELEMENTS(fontStyle)) then begin

        ; FONT_STYLE
        ; Make sure the font style is within the valid range.
        self->GetPropertyAttribute, 'FONT_STYLE', ENUMLIST=styles
        if N_ELEMENTS(fontStyle) then begin
            ; Check for human-readable strings and convert.
            if (ISA(fontStyle, 'STRING')) then begin
              case (STRUPCASE(STRCOMPRESS(fontStyle,/REM))) of
              'RM':     self._fontstyle = 0
              'NORMAL': self._fontstyle = 0
              'BF':     self._fontstyle = 1
              'BOLD':   self._fontstyle = 1
              'IT':     self._fontstyle = 2
              'ITALIC': self._fontstyle = 2
              'BI':     self._fontstyle = 3
              'BOLDITALIC': self._fontstyle = 3
              'IB':     self._fontstyle = 3
              'ITALICBOLD': self._fontstyle = 3
              else: MESSAGE, 'Unknown font style: ' + fontStyle
              endcase
            endif else begin
              self._fontstyle = 0 > fontStyle < (N_ELEMENTS(styles)-1)
            endelse
            ; Backwards compat: In IDL64 we converted Hershey from separate
            ; styles to using the actual Hershey font.
            if (self._fontindex eq 4) then begin
                self._fontindex = ([4,17,9,18])[self._fontstyle]
                self._fontstyle = 0
            endif
        endif

        self->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=fontNames

        ; FONT_NAME
        if (N_Elements(fontNameIn) gt 0) then begin
            fontIndex = (Where(STRCMP(fontNames,fontNameIn,/FOLD_CASE)))[0]
	        ; If we don't have a match, then try for the default.
            if (fontIndex lt 0) then begin
                fontIndex = (Where(fontNames eq 'Helvetica'))[0]
                if (fontIndex lt 0) then begin
                    fontIndex = (Where(fontNames eq 'Arial'))[0] > 0
                endif
            endif
        endif

        ; FONT_INDEX
        ; Make sure the font index is within the valid range.
        if N_ELEMENTS(fontIndex) then begin
            self._fontindex = 0 > fontIndex < (N_ELEMENTS(fontNames)-1)
        endif

		; Convert from font family and style to full font name.
		; This will also (de)sensitize the FONT_STYLE property.
        self._oFont->SetProperty, NAME=self->_GetFontName()
    endif


    ; FONT_SIZE
    bUpdateSize = 0b
    if (N_ELEMENTS(fontSize) gt 0) then begin
        ; Constrain font sizes
        self._fontSize = fontSize < 10000 > 0.0001
        bUpdateSize = 1b
    endif

    ; FONT_ZOOM
    if (N_ELEMENTS(fontZoom) gt 0) then begin
        self._fontZoom = fontZoom
        bUpdateSize = 1b
    endif

    ; VIEW_ZOOM
    if (N_ELEMENTS(viewZoom) gt 0) then begin
        self._viewZoom = viewZoom
        bUpdateSize = 1b
    endif

    ; FONT_NORM
    if (N_ELEMENTS(fontNorm) gt 0) then begin
        self._fontNorm = fontNorm
        bUpdateSize = 1b
    endif

    ; Displayed font size is set to:
    ;   FS * CanvasZoom * ViewZoom * FontNorm
    ; where:
    ;   FS = reported font size (as it appears in the property sheet)
    ;   FontNorm = a normalizing factor [usually: the minimum normalized
    ;     dimension of the view (relative to the window in which it appears)
    ;     in which the text appears].
    if (bUpdateSize) then begin
        dspFontSize = self._fontsize
        if (self._fontzoom ne 1.0) then $
            dspFontSize *= self._fontzoom
        if (self._viewzoom ne 1.0) then $
            dspFontSize *= self._viewzoom
        if (self._fontNorm ne 1.0) then $
            dspFontSize *= self._fontNorm
        if (dspFontSize lt 0.1) then $
            dspFontSize = 0.1
        self._oFont->SetProperty, SIZE=dspFontSize
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
function IDLitFont::GetFont

    compile_opt idl2, hidden
    return, self._oFont

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitFont__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitFont object.
;
;-
pro IDLitFont__Define

    compile_opt idl2, hidden

    struct = { IDLitFont,           $
        inherits IDLitComponent, $
        _oFont: OBJ_NEW(), $
        _fontindex: 0L,              $
        _fontsize: 0.0D,              $
        _fontstyle: 0L,              $
        _fontzoom: 0.0,              $  ; Canvas zoom.
        _viewzoom: 0.0,              $  ; View zoom.
        _fontNorm: 0.0,              $  ; Normalizing factor for font size.
        _pFonts: PTR_NEW()           $  ; list of available fonts
    }
end
