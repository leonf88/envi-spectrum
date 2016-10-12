; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitsymbol__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitSymbol
;
; PURPOSE:
;    The IDLitSymbol class is the component wrapper for IDLgrSymbol.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; MODIFICATION HISTORY:
;     Written by:   Chris, August 2002
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitSymbol::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitSymbol')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrSymbol
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitSymbol::Init, PARENT=oParent, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLgrModel::Init(NAME='Symbol', /REGISTER_PROPERTIES)) then $
        return, 0

    ; Create symbol object with default of "no symbol".
    self._symbolSize = 1   ; initial default, will be scaled by data range after init
    self._oSymbol = OBJ_NEW('IDLgrSymbol', DATA=0, SIZE=self._symbolSize)
    self._useDefaultColor = 1b  ; true

    self->IDLitSymbol::_RegisterProperties

    if (N_ELEMENTS(oParent) gt 0) then $
        self._oParent=oParent

    ; Set any properties
    self->IDLitSymbol::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
pro IDLitSymbol::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oSymbol

    ; Cleanup superclass
    self->IDLgrModel::Cleanup

end

;----------------------------------------------------------------------------
pro IDLitSymbol::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll || updateFromVersion lt 800) then begin
      self->RegisterProperty, 'SYMBOL', /SYMBOL, $
        NAME='Symbol', DESCRIPTION='Symbol', /ADVANCED_ONLY
    endif

    if (registerAll) then begin

        ; Replaced in IDL80 by SYMBOL. But keep for backwards compat.
        self->RegisterProperty, 'SYM_INDEX', /SYMBOL, $
          NAME='Symbol', DESCRIPTION='Symbol', /HIDE

        self->RegisterProperty, 'SYM_SIZE', /FLOAT, $
            NAME='Symbol size', $
            DESCRIPTION='Symbol size', /ADVANCED_ONLY

        ; Allow handling the aggregated color of the parent
        ; makes it possible to set the symbol color to the
        ; color of the parent if use_default_color is set to true.
        ; Note: We must register the property because aggregation
        ; only passes on registered properties.
        self->RegisterProperty, 'COLOR', /COLOR, $
            NAME='Color', $
            DESCRIPTION='Color', $
            /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'USE_DEFAULT_COLOR', /BOOLEAN, $
            NAME='Use default color', /ADVANCED_ONLY, $
            DESCRIPTION='Use the default color instead of the symbol color'

        self->RegisterProperty, 'SYM_COLOR', /COLOR, $
            NAME='Symbol color', $
            DESCRIPTION='Symbol color', /ADVANCED_ONLY

        self->RegisterProperty, 'SYM_THICK', /FLOAT, $
            NAME='Symbol thickness', $
            DESCRIPTION='Symbol thickness', $
            VALID_RANGE=[1.0,10.0, .1d], /ADVANCED_ONLY

        self->RegisterProperty, 'SYM_INCREMENT', /INTEGER, $
            DESCRIPTION='Symbol spacing increment', $
            NAME='Symbol increment', $
            VALID_RANGE=[1, 2147483646], $
            /HIDE, /ADVANCED_ONLY   ; only needed for certain classes

    endif

    if (registerAll || updateFromVersion lt 800) then begin
        self->RegisterProperty, 'SYM_FILLED', /BOOLEAN, $
            NAME='Symbol filled', /ADVANCED_ONLY, $
            DESCRIPTION='Fill the symbol'

        self->RegisterProperty, 'SYM_FILL_COLOR', /COLOR, $
            NAME='Symbol fill color', $
            DESCRIPTION='Symbol fill color', /ADVANCED_ONLY

        self->RegisterProperty, 'SYM_TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of the 3D Plot', $
            VALID_RANGE=[0, 100, 5]

    endif


    if (registerAll || updateFromVersion lt 640) then begin
        ; Need to register this so it can be set by the command line.
        self->RegisterProperty, 'SYM_OBJECT', /HIDE, $
            USERDEF='Symbol object', $
            NAME='Symbol object', $
            DESCRIPTION='Symbol object', /ADVANCED_ONLY
    endif

end

;----------------------------------------------------------------------------
; IDLitSymbol::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitSymbol::Restore
    compile_opt idl2, hidden

    ; Nothing to do by the superclass.
    ; self->IDLgrModel::Restore

    ; Register new properties.
    self->IDLitSymbol::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitSymbol::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitSymbol::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitSymbol::Init followed by the word "Get"
;      can be retrieved using IDLitSymbol::GetProperty.
;
;-
pro IDLitSymbol::GetProperty, $
    COLOR=color, $
    SYMBOL=symbolValue, $
    SYM_COLOR=symbolColor, $
    SYM_FILLED=symFilled, $
    SYM_FILL_COLOR=symFillColor, $
    SYM_INCREMENT=symIncrement, $
    SYM_INDEX=symbolIndex, $  ; keep for backwards compat
    SYM_OBJECT=symbolObject, $
    SYM_SIZE=symbolSize, $
    SYM_THICK=symbolThick, $
    SYM_TRANSPARENCY=symbolTransparency, $
    USE_DEFAULT_COLOR=useDefaultColor, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; Get my properties
    if ARG_PRESENT(symbolValue) then $
        symbolValue = self._symbolIndex

    if ARG_PRESENT(symbolIndex) then $
        symbolIndex = self._symbolIndex

    ; This gets handled by the IDLitVisPlot class.
    if ARG_PRESENT(symIncrement) then $
        symIncrement = 1

    if ARG_PRESENT(symbolSize) then begin
        symbolSize = self._symbolSize
    endif

    if ARG_PRESENT(useDefaultColor) then $
        useDefaultColor = self._useDefaultColor

    if ARG_PRESENT(symbolColor) then begin
        self._oSymbol->GetProperty, COLOR=color
        if (ARRAY_EQUAL(color, -1) && OBJ_VALID(self._oParent)) then begin
            ; retrieve the color from the parent
            ; the symbol's color is -1, indicating match the parent,
            ; but the property sheet needs a real color to display
            self._oParent->GetProperty, COLOR=symbolColor
        endif else begin
            symbolColor = color
        endelse
    endif

    if ARG_PRESENT(symFilled) then $
        self._oSymbol->GetProperty, FILLED=symFilled

    if ARG_PRESENT(symFillColor) then begin
        self._oSymbol->GetProperty, FILL_COLOR=symFillColor
        if (N_ELEMENTS(symFillColor) ne 3) then begin
          self->GetProperty, SYM_COLOR=symFillColor
        endif
    endif

    if ARG_PRESENT(color) then $
        self._oSymbol->GetProperty, COLOR=color

    if ARG_PRESENT(symbolObject) then $
        symbolObject = self._oUserSym

    if ARG_PRESENT(symbolThick) then $
        self._oSymbol->GetProperty, THICK=symbolThick

    if ARG_PRESENT(symbolTransparency) then begin
        self._oSymbol->GetProperty, ALPHA_CHANNEL=alpha
        symbolTransparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    ; Get superclass properties
    self->IDLgrModel::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitSymbol::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitSymbol::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitSymbol::Init followed by the word "Set"
;      can be set using IDLitSymbol::SetProperty.
;-

pro IDLitSymbol::SetProperty,  $
    COLOR=color, $
    SYMBOL=symbolValue, $
    SYM_FILLED=symFilled, $
    SYM_FILL_COLOR=symFillColor, $
    SYM_INCREMENT=swallow, $   ; don't handle in our class
    SYM_INDEX=symbolIndex, $  ; keep for backwards compat
    SYM_SIZE=symbolSize, $
    SYM_COLOR=symbolColor, $
    SYM_OBJECT=symbolObject, $
    SYM_THICK=symbolThick, $
    SYM_TRANSPARENCY=symbolTransparency, $
    USE_DEFAULT_COLOR=useDefaultColor, $
    _EXTRA=_extra

    compile_opt idl2, hidden


    ; SYM_INDEX - replaced in IDL80 by SYMBOL
    if (N_ELEMENTS(symbolIndex)) then $
      symbolValue = symbolIndex

    if (N_ELEMENTS(symbolValue)) then begin
        if (~Obj_Valid(self._oUserSym)) then begin
            self._symbolIndex = symbolValue
            self._oSymbol->SetProperty, DATA=self._symbolIndex
            ; (De)sensitize my symbol properties.
            isValid = self._symbolIndex gt 0 || Obj_Valid(self._oUserSym)
            self->SetPropertyAttribute, ['SYM_SIZE', 'USE_DEFAULT_COLOR', $
                'SYM_THICK', 'SYM_INCREMENT'], $
                SENSITIVE=isValid
            ; Need to handle separately since it depends upon use_default_color.
            self->SetPropertyAttribute, 'SYM_COLOR', $
                SENSITIVE=(~self._useDefaultColor) && isValid
        endif
    endif

    ; SYM_OBJECT
    if (N_ELEMENTS(symbolObject)) then begin
        self._oUserSym = Obj_Valid(symbolObject) ? symbolObject : Obj_New()
        isValid = self._symbolIndex gt 0 || Obj_Valid(self._oUserSym)
        self->SetPropertyAttribute, ['SYM_SIZE', 'USE_DEFAULT_COLOR', $
            'SYM_THICK', 'SYM_INCREMENT'], $
            SENSITIVE=isValid
        self->SetPropertyAttribute, 'SYMBOL', HIDE=Obj_Valid(self._oUserSym)
        ; Need to handle separately since it depends upon use_default_color.
        self->SetPropertyAttribute, 'SYM_COLOR', $
            SENSITIVE=(~self._useDefaultColor) && isValid
        self._oSymbol->SetProperty, $
            DATA=Obj_Valid(self._oUserSym) ? self._oUserSym : self._symbolIndex
    endif

    ; SYM_SIZE
    if ((N_ELEMENTS(symbolSize) gt 0) && $
        (OBJ_VALID(self._oParent))) then begin
        self._symbolSize = symbolSize
        ; determined experimentally to give a nice range to the
        ; symbol size given the initial symbol size of 1.
        symbolFactor = 0.015d
        if (OBJ_ISA(self._oParent, 'IDLgrPolyline')) then begin
            self._oSymbol->SetProperty, $
                        SIZE=self._symbolSize*symbolFactor*[1,1,1]
        endif else begin
            ; Construct a normalized symbol size.
            ; This does not take into account the window aspect ratio
            ; or any parent model scaling, so symbols may look squashed.
            oDataSpace = self._oParent->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDataSpace)) then begin
                if (oDataSpace->_GetXYZAxisRange(xr, yr, zr)) then begin
                    dx = xr[1] - xr[0]
                    dy = yr[1] - yr[0]
                    dz = (self._oParent->Is3D()) ? zr[1]-zr[0] : (dx < dy)
                    self._oSymbol->SetProperty, $
                        SIZE=self._symbolSize*symbolFactor*[dx,dy,dz]
                endif
            endif
        endelse
    endif


    ; COLOR
    ; Handle explicitly to allow following the aggregated color of the parent
    if (N_ELEMENTS(color) gt 0 && self._useDefaultColor) then $
      symbolColor = color


    ; USE_DEFAULT_COLOR
    if (N_ELEMENTS(useDefaultColor) gt 0) then begin
        ; after internal fix, this flag and setting should be unneccessary
        self._useDefaultColor = useDefaultColor
        isValid = self._symbolIndex gt 0 || Obj_Valid(self._oUserSym)
        self->SetPropertyAttribute, 'SYM_COLOR', $
            SENSITIVE=(~self._useDefaultColor) && isValid
        ; If going back to default, set our symbol color to the color
        ; of the parent
        if (KEYWORD_SET(useDefaultColor) && OBJ_VALID(self._oParent)) then begin
            ; match the color of the parent
            self._oParent->GetProperty, COLOR=color
            self->IDLitSymbol::SetProperty, SYM_COLOR=color
        endif

    endif


    ; SYM_COLOR
    if (N_ELEMENTS(symbolColor) gt 0) then begin
        self._oSymbol->GetProperty, COLOR=oldSymColor
        ; If this property is being set programmatically,
        ; then set the symbol color regardless of USE_DEFAULT_COLOR,
        ; but *do not* change the value of USE_DEFAULT_COLOR,
        ; otherwise Styles behave incorrectly.
        self._oSymbol->SetProperty, COLOR=symbolColor
        if (Obj_Valid(self._oUserSym)) then begin
            ; Attempt to pass on the property to our user sym.
            ; Use _EXTRA to hopefully avoid errors for unknown keywords.
            self._oUserSym->SetProperty, _EXTRA={COLOR:symbolColor}
        endif
        if (ISA(self._oParent)) then $
          self._oParent->GetProperty, COLOR=currentcolor $
        else currentcolor = [0,0,0]
        if ~array_equal(currentcolor, symbolColor) then begin
          self._useDefaultColor = 0b
          self->SetPropertyAttribute, 'SYM_COLOR', SENSITIVE=self._symbolIndex gt 0 || Obj_Valid(self._oUserSym)
        endif
        self._oSymbol->GetProperty, FILL_COLOR=oldFillColor
        if ARRAY_EQUAL(oldSymColor, oldFillColor) then $
          self._oSymbol->SetProperty, FILL_COLOR=symbolColor
    endif


    ; SYM_THICK
    if (N_ELEMENTS(symbolThick) gt 0) then begin
        self._oSymbol->SetProperty, THICK=symbolThick
        if (Obj_Valid(self._oUserSym)) then begin
            ; Attempt to pass on the property to our user sym.
            ; Use _EXTRA to hopefully avoid errors for unknown keywords.
            self._oUserSym->SetProperty, _EXTRA={THICK:symbolThick}
        endif
    endif


    ; SYM_TRANSPARENCY
    if (N_ELEMENTS(symbolTransparency)) then begin
        self._oSymbol->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-symbolTransparency)/100) < 1
    endif

    ; SYM_FILLED
    if (N_ELEMENTS(symFilled)) then begin
        self._oSymbol->SetProperty, FILLED=symFilled
    endif

    ; SYM_FILL_COLOR
    if (N_ELEMENTS(symFillColor)) then begin
        self._oSymbol->SetProperty, FILL_COLOR=symFillColor
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLgrModel::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
function IDLitSymbol::GetSymbol

    compile_opt idl2, hidden
    return, self._oSymbol

end

;-----------------------------------------------------------------------------
; Override IDLgrModel::Draw so we can
; automatically adjust for changes in aspect ratio.
;
pro IDLitSymbol::Draw, oDest, oLayer

    compile_opt idl2, hidden

    catch, iErr
    if (iErr ne 0) then begin
        ; Quietly return from errors so we don't crash IDL in the draw loop.
        catch, /cancel
        return
    endif

    ; Don't do extra work if we are in the lighting or selection pass.
    oDest->GetProperty, IS_BANDING=isBanding, $
        IS_LIGHTING=isLighting, IS_SELECTING=isSelecting

    if (~isLighting && ~isSelecting && ~isBanding) then begin
        oWorld = Obj_Valid(oLayer) ? oLayer->GetWorld() : Obj_New()
        if (Obj_Valid(self._oParent) && Obj_Valid(oWorld)) then begin
            matrix = self._oParent->GetCTM(TOP=oWorld)
            xpixel = Sqrt(Total(matrix[0,0:2]^2))
            ypixel = Sqrt(Total(matrix[1,0:2]^2))
            zpixel = Sqrt(Total(matrix[2,0:2]^2))
            if (xpixel eq 0) then xpixel = 1
            if (ypixel eq 0) then ypixel = 1
            if (zpixel eq 0) then zpixel = xpixel < ypixel
            oDest->GetProperty, DIMENSIONS=dim, RESOLUTION=res
            ; The factor out front was empirically determined to
            ; preserve approx the same symbol sizes as before IDL64.
            factor = 0.27d/(MIN(res)*MIN(dim))
            symSize = factor*self._symbolSize/[xpixel,ypixel,zpixel]
            self._oSymbol->SetProperty, SIZE=symSize
        endif
    endif

    self->IDLgrModel::Draw, oDest, oLayer

    ; Mac sometimes throws floating underflows...
    void = CHECK_MATH()
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitSymbol__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitSymbol object.
;
;-
pro IDLitSymbol__Define

    compile_opt idl2, hidden

    struct = { IDLitSymbol,           $
        inherits IDLgrModel, $
        _oSymbol: OBJ_NEW(), $
        _oParent: OBJ_NEW(), $
        _oUserSym: Obj_New(), $   ; do not clean up
        _symbolSize: 0d, $     ; the unscaled size
        _useDefaultColor: 0b, $
        _symbolIndex: 0b $
    }
end
