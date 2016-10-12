; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitviscontourlevel__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisContourLevel
;
; PURPOSE:
;    The IDLitVisContourLevel class is the wrapper for IDLgrContour levels.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
; MODIFICATION HISTORY:
;     Written by:   Karl, 06/29/2001
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisContourLevel::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisContourLevel'[, Z[, X, Y]])
;
; INPUTS:
;   Z: (see IDLgrContour)
;   X:
;   Y:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrContour
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;   Create just like an IDLgrContour.
;
;-
function IDLitVisContourLevel::Init, data, _REF_EXTRA=_extra

   compile_opt idl2, hidden

    ;; Initialize superclass
    if (self->_IDLitVisualization::Init(NAME='Level', $
        ICON='contour', DESCRIPTION='Contour level', $
        _EXTRA=_extra) ne 1) then $
     RETURN, 0

    self->_RegisterProperties

    self->_VerifyFont

    self._symbolsize = 0.1d

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisContourLevel::SetProperty, _EXTRA=_extra

    return, 1                    ; Success
end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oSymbol
    OBJ_DESTROY, self._oText
    OBJ_DESTROY, self._oFont

    ; Cleanup superclass
    self->_IDLitVisualization::Cleanup
end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::_RegisterProperties

   compile_opt idl2, hidden

    self->SetPropertyAttribute, ['NAME', 'DESCRIPTION', 'HIDE'], /HIDE

    self->RegisterProperty, 'VALUE', /FLOAT, $
        NAME='Value', $
        DESCRIPTION='Contour value', $
        /HIDE, /ADVANCED_ONLY  ; need to disable for styles, until we have data

    self->RegisterProperty, 'COLOR', /COLOR, $
        NAME='Color', $
        DESCRIPTION='Contour color'

    self->RegisterProperty, 'LINESTYLE', /LINESTYLE, $
        NAME='Line style', $
        DESCRIPTION='Contour linestyle'

    self->RegisterProperty, 'THICK', /THICKNESS, $
        NAME='Line thickness', $
        DESCRIPTION='Contour thickness'

    self->RegisterProperty, 'LABEL_TYPE', $
        ENUMLIST=['None', 'Value', 'Text', 'Symbol'], $
        NAME='Label', $
        DESCRIPTION='Contour labelling'

    self->RegisterProperty, 'LABEL_INTERVAL', /FLOAT, $
        NAME='Label interval', $
        DESCRIPTION='Normalized interval between labels', $
        VALID_RANGE=[0.05d,1d,0.05d], /ADVANCED_ONLY

    self->RegisterProperty, 'LABEL_NOGAPS', /BOOLEAN, $
        NAME='No label gaps', $
        DESCRIPTION='Do not have gaps for labels', /ADVANCED_ONLY

    self->RegisterProperty, 'USE_LABEL_COLOR', /BOOLEAN, $
        NAME='Use label color', $
        DESCRIPTION='Use provided label color instead of default', $
        /ADVANCED_ONLY

    self->RegisterProperty, 'LABEL_COLOR', /COLOR, $
        NAME='Label color', $
        DESCRIPTION='Color of labels'

    self->RegisterProperty, 'LABEL_SYMBOL', /SYMBOL, $
        NAME='Symbol label', $
        DESCRIPTION='Contour symbol label', /ADVANCED_ONLY

    self->RegisterProperty, 'SYMBOL_SIZE', /FLOAT, $
        NAME='Symbol size', $
        DESCRIPTION='Contour symbol size', $
        VALID_RANGE=[0,1,0.05d], /ADVANCED_ONLY

    self->RegisterProperty, 'LABEL_TEXT', /STRING, $
        NAME='Text label', $
        DESCRIPTION='Contour text label', $
        /HIDE, /ADVANCED_ONLY

    ;; get numeric formats
    result = IDLitGetResource(1, numericFormatNames, /NUMERICFORMAT, /NAMES)
    result = IDLitGetResource(1, numericFormatExamples, $
                              /NUMERICFORMAT, /EXAMPLES)

    ;; get time formats
    result = IDLitGetResource(1, timeFormatNames, /TIMEFORMAT, /NAMES)
    result = IDLitGetResource(1, timeFormatExamples, /TIMEFORMAT, /EXAMPLES)

    self->RegisterProperty, 'TICKFORMAT', /STRING, $
        NAME='Tick format code', $
        DESCRIPTION='IDL format string or function name', /ADVANCED_ONLY

    self->RegisterProperty, 'TICK_DEFINEDFORMAT', $
        DESCRIPTION='Predefined tick format', $
        ENUMLIST=['None', $
                  'Use Tick Format Code', $
                  numericFormatNames+' ('+numericFormatExamples+')', $
                  timeFormatNames+' ('+timeFormatExamples+')' $
                 ], $
        NAME='Tick format', /ADVANCED_ONLY

end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::GetProperty, $
    _CONTOUR=oContour, $
    _VALUE=_value, $
    INDEX=index, $
    COLOR=mycolor, $
    LABEL_COLOR=myLabelColor, $
    LABEL_INTERVAL=myLabelInterval, $
    LABEL_NOGAPS=myLabelNogaps, $
    LABEL_SYMBOL=myLabelSymbol, $
    LABEL_TEXT=myLabelText, $
    LABEL_TYPE=myLabelType, $
    LINESTYLE=mylinestyle, $
    SYMBOL_SIZE=mySymbolSize, $
    THICK=mythick, $
    USE_LABEL_COLOR=myUseLabelColor, $
    VALUE=myvalue, $
    TICKFORMAT=tickFormat, $
    TICK_DEFINEDFORMAT=tickDefinedFormat, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; These properties are stored within myself.

    if ARG_PRESENT(oContour) then $
        oContour = self._oContour

    if (ARG_PRESENT(myLabelType)) then $
        myLabelType = self._labelType

    if (ARG_PRESENT(myLabelSymbol)) then begin
        myLabelSymbol = 0L
        if OBJ_VALID(self._oSymbol) then $
            self._oSymbol->GetProperty, DATA=myLabelSymbol
    endif

    if (ARG_PRESENT(mySymbolSize)) then $
        mySymbolSize = self._symbolsize


    if (ARG_PRESENT(myLabelColor)) then begin
        myLabelColor = [0b,0b,0b]
        if OBJ_VALID(self._oText) then begin
            self._oText->GetProperty, COLOR=textColor
            myLabelColor = textColor
        endif else if OBJ_VALID(self._oSymbol) then begin
            self._oSymbol->GetProperty, COLOR=symbolColor
            myLabelColor = symbolColor
        endif
    endif

    if (ARG_PRESENT(index)) then $
        index = self._index


    if (ARG_PRESENT(myLabelText)) then begin
        myLabelText = ''
        if OBJ_VALID(self._oText) then begin
            self._oText->GetProperty, STRINGS=str
            if (SIZE(str,/TYPE) eq 7) then $
                myLabelText = str[0]
        endif
    endif


    ; The rest need to be retrieved from my contour object.
    haveContour = OBJ_VALID(self._oContour)

    if (ARG_PRESENT(mycolor)) then begin
        mycolor = [0,0,0]
        if (haveContour) then begin
            self._oContour->GetProperty, C_COLOR=c_color, COLOR=color
            ; Take the color either from the individual color,
            ; or from the default contour colors.
            if (N_ELEMENTS(c_color) eq 1 && c_color eq -1) then begin
                ; C_COLOR not set, use basic COLOR property
                mycolor = color
            endif else if (SIZE(c_color,/n_dimensions) EQ 1) then begin

                ; C_COLOR was set to vector of indices into palette
                ; extract color from palette
                index = c_color[self._index mod ((SIZE(c_color,/dimensions))[0])]
                self._oContour->GetProperty, PALETTE=oPalette

                ; Sanity check.
                if (OBJ_VALID(oPalette)) then begin
                    oPalette->GetProperty, N_COLORS=nColors
                    index = index < (nColors-1)
                    mycolor = oPalette->GetRGB(index)
                endif else $  ; assume grayscale
                    mycolor = BYTE([index, index, index])

            endif else if (SIZE(c_color,/n_dimensions) EQ 2) then begin
                ; C_COLOR was set directly to 3xN array
                mycolor = c_color[*, (self._index mod (SIZE(c_color,/dimensions))[1])]
            endif
        endif
    endif

    if (ARG_PRESENT(myLabelInterval)) then begin
        myLabelInterval = 0.4d
        if haveContour then begin
            self._oContour->GetProperty, C_LABEL_INTERVAL=c_label_interval
            if (self._index lt N_ELEMENTS(c_label_interval)) then begin
                myLabelInterval = c_label_interval[self._index]
                ;; limit significant figures to 6 for display purposes
                myLabelInterval = ROUND(myLabelInterval*1d6)/1d6
            endif
        endif
    endif

    if (ARG_PRESENT(myLabelNogaps)) then begin
        myLabelNogaps = 0b
        if haveContour then begin
            self._oContour->GetProperty, C_LABEL_NOGAPS=c_label_nogaps
            if (self._index lt N_ELEMENTS(c_label_nogaps)) then $
                myLabelNogaps = c_label_nogaps[self._index]
        endif
    endif

    if (ARG_PRESENT(mylinestyle)) then begin
        mylinestyle = 0L
        if haveContour then begin
            self._oContour->GetProperty, C_LINESTYLE=c_lines
            if (self._index lt N_ELEMENTS(c_lines)) then $
                mylinestyle = c_lines[self._index] > 0
        endif
    endif

    if (ARG_PRESENT(mythick)) then begin
        mythick = 1L
        if haveContour then begin
            self._oContour->GetProperty, C_THICK=c_thick
            if (self._index lt N_ELEMENTS(c_thick)) then $
                mythick = c_thick[self._index] > 1
        endif
    endif

    if (ARG_PRESENT(myUseLabelColor)) then begin
        myUseLabelColor = 0b
        if haveContour then begin
            self._oContour->GetProperty, $
                C_USE_LABEL_COLOR=c_use_label_color
            if (self._index lt N_ELEMENTS(c_use_label_color)) then $
                myUseLabelColor = c_use_label_color[self._index]
        endif
    endif

    if (ARG_PRESENT(_value)) then $
        _value = self._value

    if (ARG_PRESENT(myvalue)) then begin
        myvalue = self._value
        if haveContour then begin
            self._oContour->GetProperty, C_VALUE=c_value
            if (self._index lt N_ELEMENTS(c_value)) then begin
                myvalue = c_value[self._index]
            endif
        endif
    endif

    if ARG_PRESENT(tickDefinedFormat) then $
        tickDefinedFormat = self._tickDefinedFormat

    if ARG_PRESENT(tickFormat) then $
        tickFormat = self._tickFormat

    ; Get superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; c_property is the array returned from IDLgrContour::GetProperty,
; such as C_THICK, C_LINESTYLE, etc.
; nlevels is the total # of levels needed.
; newvalue is the new property to be inserted within the array.
;
pro IDLitVisContourLevel::_InsertProperty, c_property, nlevelsIn, newvalue, $
    ALLOW_SCALAR=allowScalar

    compile_opt idl2, hidden

    ; Expand the array to include our own level if necessary.
    ; This is needed for initialization from the property bag.
    nlevels = nLevelsIn > (self._index + 1)

    ; Current number of values within the property.
    nvalues = N_ELEMENTS(c_property)
    if (nvalues eq 1 && ~KEYWORD_SET(allowScalar)) then $
        c_property = [c_property]

    ; Expand the array if necessary.
    if (nlevels gt nvalues) then begin
        type = SIZE(newvalue, /TYPE)
        append = MAKE_ARRAY(nlevels - nvalues, TYPE=type)
        c_property = (nvalues gt 0) ? [c_property, append] : append
    endif

    ; Insert the new value.
    c_property[self._index] = newvalue

end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::_VerifyFont

  compile_opt idl2, hidden

  if (OBJ_VALID(self._oFont)) then return

  ; Use the current zoom factor of the tool window as the
  ; initial font zoom factor.  Likewise for view zoom, and normalization
  ; factor.
  oTool = self->GetTool()
  if (OBJ_VALID(oTool) && OBJ_ISA(oTool, 'IDLitTool')) then begin
      oWin = oTool->GetCurrentWindow()
      if (OBJ_VALID(oWin)) then begin
          oWin->GetProperty, CURRENT_ZOOM=fontZoom
          oView = oWin->GetCurrentView()
          if (OBJ_VALID(oView)) then begin
              oView->GetProperty, CURRENT_ZOOM=viewZoom
              normViewDims = oView->GetViewport(UNITS=3,/VIRTUAL)
              fontNorm = MIN(normViewDims)
          endif
      endif
  endif
  self._oFont = OBJ_NEW('IDLitFont', FONT_SIZE=16, FONT_ZOOM=fontZoom, $
      VIEW_ZOOM=viewZoom, FONT_NORM=fontNorm)
  self->Aggregate, self._oFont
end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::_CreateText

    compile_opt idl2, hidden

    self._oText = OBJ_NEW('IDLgrText', $
        /ENABLE_FORMATTING, $
        RECOMPUTE_DIMENSIONS=2, $
        FONT=self._oFont->GetFont())

end


;----------------------------------------------------------------------------
pro IDLitVisContourLevel::SetProperty, $
    _CONTOUR=oContour, $
    _VALUE=_value, $
    COLOR=mycolor, $
    LABEL_COLOR=myLabelColor, $
    LABEL_INTERVAL=myLabelInterval, $
    LABEL_NOGAPS=myLabelNogaps, $
    LABEL_SYMBOL=myLabelSymbol, $
    LABEL_TEXT=myLabelText, $
    LABEL_TYPE=myLabelType, $
    LINESTYLE=mylinestyle, $
    SYMBOL_SIZE=mySymbolSize, $
    THICK=mythick, $
    USE_LABEL_COLOR=myUseLabelColor, $
    VALUE=myvalue, $
    INDEX=index, $
    TICKFORMAT=tickformat, $
    TICK_DEFINEDFORMAT=tickDefinedFormat, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; Set superclass properties. We do this first so we can check below
    ; if we have a Contour object, and bail quickly.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra


    if (N_ELEMENTS(oContour)) then begin
        self._oContour = oContour
        ; Reenable property hidden for styles.
        self->SetPropertyAttribute, 'VALUE', HIDE=0
    endif

    if (~self._oContour) then $
        return

    if (N_ELEMENTS(index)) then $
        self._index = index


    ; Retrieve the total number of levels.
    self._oContour->GetProperty, C_VALUE=c_value
    nlevels = N_ELEMENTS(c_value)

    if (N_ELEMENTS(mycolor) gt 0) then begin

        self._oContour->GetProperty, C_COLOR=c_color, COLOR=color, N_LEVELS=nLevels

      if (nLevels gt 0 && self._index lt nLevels) then begin

        ; Note: If C_COLOR was set to a vector of indices,
        ; then ignore the COLOR property.

        if (N_ELEMENTS(c_color) eq 1 && c_color eq -1) then begin
            ; changing a single level, but no independent level colors yet.
            ; we must create them from the color value
            ; prevent dropping trailing dimension of 1
            c_colorNew = BYTARR(3,(nLevels>2))
            for i=0, nLevels-1 do begin
                ; set original value
                c_colorNew[*,i]=color
            endfor
            ; now set new value
            c_colorNew[*,self._index]=mycolor
            self._oContour->SetProperty, C_COLOR=c_colorNew
        endif else if (SIZE(c_color,/n_dimensions) EQ 2) then begin
            ; C_COLOR was set directly to 3xN array
            c_color[*, (self._index mod (SIZE(c_color,/dimensions))[1])]=mycolor
            self._oContour->SetProperty, C_COLOR=c_color
        endif
        
      endif
    endif


    if (N_ELEMENTS(myLabelType)) then BEGIN
        wasLabelling = self._labelType
        self._labelType = 0 > myLabelType < 3

        ; First turn the C_LABEL_SHOW on or off.
        self._oContour->GetProperty, C_LABEL_SHOW=c_label_show, $
            C_LABEL_OBJECTS=c_label_objects
        self->_InsertProperty, c_label_show, nlevels, (myLabelType < 1)
        self._oContour->SetProperty, C_LABEL_SHOW=c_label_show

        ; Turn on/off labelling properties.
        self->SetPropertyAttribute, $
            ['USE_LABEL_COLOR', $
            'LABEL_INTERVAL', 'LABEL_NOGAPS'], $
            SENSITIVE=(self._labelType gt 0)
        self->SetPropertyAttribute, $
          ['TICK_DEFINEDFORMAT'], $
          SENSITIVE=(self._labelType EQ 1)
        self->GetProperty,TICK_DEFINEDFORMAT=tickdef
        self->SetPropertyAttribute,['TICKFORMAT'], $
          SENSITIVE=((tickdef EQ 1) AND (self._labelType EQ 1))

        ; This is a tricky one. Only turn on label color prop
        ; if USE_LABEL_COLOR is also set.
        if (~wasLabelling && self._labelType) then begin
            self->GetProperty, USE_LABEL_COLOR=myCurrentUseLabelColor
            self->SetPropertyAttribute, $
                'LABEL_COLOR', SENSITIVE=myCurrentUseLabelColor
        endif else if (~self._labelType) then begin
            self->SetPropertyAttribute, $
                'LABEL_COLOR', SENSITIVE=0
        endif

        ; Turn on/off text-only properties.
        self->SetPropertyAttribute, 'LABEL_TEXT', $
            SENSITIVE=(self._labelType eq 2), HIDE=0

        ; Turn on/off symbol-only properties.
        self->SetPropertyAttribute, ['LABEL_SYMBOL', 'SYMBOL_SIZE'], $
            SENSITIVE=(self._labelType eq 3)

        switch self._labelType of

            0: break

            1: ; Value (fall thru)
            2: begin   ; Text
                if (self._index ge nlevels) then $
                    break
                if (~self._oText) then begin
                    self->_VerifyFont
                    ; See if someone else has created our object.
                    if ((self._index lt N_ELEMENTS(c_label_objects)) && $
                        OBJ_ISA(c_label_objects[self._index], 'IDLgrText')) then begin
                        ; If so, then steal it and set our font.
                        self._oText = c_label_objects[self._index]
                        ; Set our default properties.
                        self._oText->SetProperty, FONT=self._oFont->GetFont(), $
                            RECOMPUTE_DIMENSIONS=2, $
                            /ENABLE_FORMATTING
                    endif else begin
                        ; Create our own.
                        self->_CreateText
                    endelse
                    ; Set our default properties.
                    self._oText->SetProperty, $
                        STRING=STRING(c_value[self._index], FORMAT='(G0)')
                endif

                ; If switching to "Value", then fill it in.
                if (self._labelType eq 1) then BEGIN
                  ;; If format code is '', set it G0 instead for BC
                  format = (self._tickFormat EQ '' ? '(G0)' : self._tickFormat)
                    self._oText->SetProperty, $
                        STR=STRING(c_value[self._index], FORMAT=format)
                endif

                ; Insert myself into the list.
                self->_InsertProperty, $
                    c_label_objects, nlevels, self._oText
                self._oContour->SetProperty, $
                    C_LABEL_OBJECTS=c_label_objects

                break
               end

            3: begin   ; Symbol

                if (~self._oSymbol) then begin
                    ; See if someone else has created our object.
                    if ((self._index lt N_ELEMENTS(c_label_objects)) && $
                        OBJ_ISA(c_label_objects[self._index], 'IDLgrSymbol')) then begin
                        ; If so, then steal it.
                        self._oSymbol = c_label_objects[self._index]
                    endif else begin
                        ; Create our own.
                        self._oSymbol = OBJ_NEW('IDLgrSymbol', 8)
                    endelse
                endif

                ; We want to scale our symbol size by the total contour range,
                ; so that we can use normalized units for the size.
                self._oContour->GetProperty, $
                    XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
                range = [ $
                    ABS(xrange[1] - xrange[0]), $
                    ABS(yrange[1] - yrange[0]), $
                    ABS(zrange[1] - zrange[0]) ]
                range = 0.1d*range + (range eq 0)
                self._oSymbol->SetProperty, $
                    SIZE=self._symbolsize*range, UVALUE=range

                ; Insert myself into the list.
                self->_InsertProperty, $
                    c_label_objects, nlevels, self._oSymbol
                self._oContour->SetProperty, $
                    C_LABEL_OBJECTS=c_label_objects

                break
               end

        endswitch

        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            oTool->DoOnNotify, $
                self->GetFullIdentifier(),'SETPROPERTY','LABEL_TYPE'
        endif

    endif


    ; Do we need to notify the contour to recompute the labels?
    recomputeLabels = 0


    if (N_ELEMENTS(myLabelColor)) then begin
        notBlack = ~ARRAY_EQUAL(myLabelColor, [0,0,0])
        if (~self._oText && notBlack) then $
            self->_CreateText
        if (~self._oSymbol && notBlack) then $
            self._oSymbol = OBJ_NEW('IDLgrSymbol', UVALUE=[1,1,1])
        ; Both the symbol and text have the same color.
        if (OBJ_VALID(self._oSymbol)) then begin
            self._oSymbol->SetProperty, COLOR=myLabelColor
            recomputeLabels = 1
        endif
        if (OBJ_VALID(self._oText)) then begin
            self._oText->SetProperty, COLOR=myLabelColor
            recomputeLabels = 1
        endif
    endif


    if (N_ELEMENTS(myLabelSymbol)) then begin
        if (~self._oSymbol && (myLabelSymbol ne 0)) then $
            self._oSymbol = OBJ_NEW('IDLgrSymbol', UVALUE=[1,1,1])
        if (OBJ_VALID(self._oSymbol)) then begin
            self._oSymbol->SetProperty, DATA=myLabelSymbol[0]
            recomputeLabels = 1
            self->DoOnNotify, $
              self->GetFullIdentifier(),'SETPROPERTY','LABEL_SYMBOL'
        endif
    endif


    if (N_ELEMENTS(mySymbolSize)) then begin
        if (~self._oSymbol && (mySymbolSize ne 0.1d)) then $
            self._oSymbol = OBJ_NEW('IDLgrSymbol', UVALUE=[1,1,1])

        if (OBJ_VALID(self._oSymbol)) then begin
            self._symbolsize = mySymbolSize > 0
            ; We guaranteed the symbol's existence above.
            self._oSymbol->GetProperty, UVALUE=defaultSizes

            ; Make all three dimensions the same size.
            symbolSizes = defaultSizes*self._symbolsize
            self._oSymbol->SetProperty, SIZE=symbolSizes
            recomputeLabels = 1
            self->DoOnNotify, $
              self->GetFullIdentifier(),'SETPROPERTY','SYMBOL_SIZE'
        endif
    endif


    if (N_ELEMENTS(myLabelText)) then begin
        if (~self._oText && myLabelText[0]) then $
            self->_CreateText
        if (OBJ_VALID(self._oText)) then begin
            self._oText->SetProperty, STRINGS=myLabelText[0]
            self->DoOnNotify, $
              self->GetFullIdentifier(),'SETPROPERTY','LABEL_TEXT'
            recomputeLabels = 1
        endif
    endif

    if (N_ELEMENTS(myLabelInterval)) then begin
        self._oContour->GetProperty, C_LABEL_INTERVAL=c_label_interval
        self->_InsertProperty, c_label_interval, nlevels, myLabelInterval
        self._oContour->SetProperty, C_LABEL_INTERVAL=c_label_interval
    endif

    if (N_ELEMENTS(myLabelNogaps)) then begin
        self._oContour->GetProperty, C_LABEL_NOGAPS=c_label_nogaps
        self->_InsertProperty, c_label_nogaps, nlevels, myLabelNogaps
        self._oContour->SetProperty, C_LABEL_NOGAPS=c_label_nogaps
        recomputeLabels = 1
    endif

    if (N_ELEMENTS(mylinestyle)) then begin
        self._oContour->GetProperty, C_LINESTYLE=c_linestyle
        self->_InsertProperty, c_linestyle, nlevels, mylinestyle
        self._oContour->SetProperty, C_LINESTYLE=c_linestyle > 0
    endif

    if (N_ELEMENTS(mythick)) then begin
        self._oContour->GetProperty, C_THICK=c_thick
        self->_InsertProperty, c_thick, nlevels, mythick
        self._oContour->SetProperty, C_THICK=c_thick > 1
    endif

    if (N_ELEMENTS(myUseLabelColor)) then begin
        self._oContour->GetProperty, C_USE_LABEL_COLOR=c_use_label_color
        self->_InsertProperty, c_use_label_color, nlevels, myUseLabelColor
        self._oContour->SetProperty, C_USE_LABEL_COLOR=c_use_label_color
        ; Assume if USE_LABEL_COLOR is sensitive, then it is okay
        ; to sensitize LABEL_COLOR also.
        ; Desensitize is okay no matter what.
        self->SetPropertyAttribute, 'LABEL_COLOR', $
            SENSITIVE=myUseLabelColor

    endif

    ; Hidden variable to cache the current value (in case level is deleted).
    if (N_Elements(_value)) then $
        self._value = _value
        
    ; Only set value if we are actually a valid level
    ; (don't bother if just initializing).
    if (N_ELEMENTS(myvalue) && self._index lt nlevels) then begin
        self._oContour->GetProperty, C_VALUE=c_value
        self->_InsertProperty, c_value, nlevels, myvalue, /ALLOW_SCALAR
        ; Trap c_value and don't allow -1 values to be set. This is
        ; needed b/c of the design of the contour object.
        if ((SIZE(c_value, /N_DIM) gt 0) || c_value ne -1) then begin
            self._oContour->SetProperty, C_VALUE=c_value
            ; If we are labelling by value, then change it also.
            if (self._labelType eq 1) then begin
                self._oText->SetProperty, $
                    STR=STRING(c_value[self._index], FORMAT='(G0)')
                self->DoOnNotify, self->GetFullIdentifier(), $
                    'SETPROPERTY', 'LABEL_TEXT'
            endif
        endif
    endif

    IF ARG_PRESENT(tickformat) THEN BEGIN

      ;; Tricky code to verify that tick formats are legal
      ;; or the format is a valid function name.
      tickFormatCheck = STRTRIM(tickFormat, 2)
      IF tickFormatCheck NE '' THEN BEGIN
        IF (STRMID(tickFormatCheck, 0, 1) EQ '(') && $
          (STRMID(tickFormatCheck, $
                  STRLEN(tickFormatCheck)-1, 1) EQ ')') THEN BEGIN
          CATCH, err
          IF (err NE 0) THEN BEGIN
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            ;; If this fails we will skip over the next line.
            test = STRING(0, FORMAT=tickFormatCheck)
            tickFormatValid = tickFormatCheck
          ENDELSE
        ENDIF ELSE BEGIN
          ;; it's not a format, verify that it is a tickformat function
          CATCH, err
          IF (err NE 0) THEN BEGIN
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            ;; If this fails we will skip over the next line.
            resolve_routine, tickFormatCheck, $
                             /IS_FUNCTION, /NO_RECOMPILE
            tickFormatValid = tickFormatCheck
          ENDELSE
        ENDELSE
      ENDIF

      IF n_elements(tickFormatValid) NE 0 THEN BEGIN
        self._tickFormat = tickFormatValid
        setText = 1
      ENDIF
    ENDIF

    IF ARG_PRESENT(tickDefinedFormat) THEN BEGIN
      self._tickDefinedFormat = tickDefinedFormat
      self->SetPropertyAttribute,'TICKFORMAT', $
        SENSITIVE=(tickDefinedFormat EQ 1)
      result = IDLitGetResource(1, numericFormats, /NUMERICFORMAT, /FORMATS)
      result = IDLitGetResource(1, timeFormats, /TIMEFORMAT, /FORMATS)
      offset = (num = 2)        ; offset to account for first two formats
      CASE 1 OF
        ;; no format
        tickDefinedFormat EQ 0 : tickFormat=''
        ;; use custom TICKFORMAT code already in place
        tickDefinedFormat EQ 1 : tickFormat = self._tickFormat
        ;; numeric formats
        tickDefinedFormat LT ((num+=n_elements(numericFormats))) : $
          tickFormat = numericFormats[tickDefinedFormat-offset]
        ;; time formats
        tickDefinedFormat LT ((num+=n_elements(timeFormats))) : $
          tickFormat = $
            timeFormats[tickDefinedFormat-offset-n_elements(numericFormats)]
        ELSE :
      ENDCASE
      self._tickformat=tickFormat
      setText = 1
    ENDIF

    ;; apply tick format to label. Only do this if we are actually
    ; a valid level (don't bother if just initializing).
    IF (n_elements(setText) NE 0  && self._index lt nlevels) THEN BEGIN
        if (~self._oText && self._tickFormat) then $
            self->_CreateText
      ;; Set the value
      ;; We guaranteed the self._oText existence above.
      ;; If format code is '', set it G0 instead for 6.0 BC
        if (OBJ_VALID(self._oText)) then begin
            format = (self._tickFormat EQ '' ? '(G0)' : self._tickFormat)
            self._oText->SetProperty, $
                STRING=STRING(c_value[self._index], FORMAT=format)
            self->DoOnNotify, $
                self->GetFullIdentifier(),'SETPROPERTY','LABEL_TEXT'
            recomputeLabels =1
        endif
    ENDIF

    ; We need to notify the Contour object to recompute labels.
    if (recomputeLabels) then begin
        self._oContour->GetProperty, C_LABEL_SHOW=c_label_show
        self._oContour->SetProperty, C_LABEL_SHOW=c_label_show
    endif

end


;---------------------------------------------------------------------------
; IDLitVisContourLevel::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport
;   has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     width and height of the viewport (in pixels).
;
;   normViewDims: A 2-element vector, [w,h], representing the new 
;     width and height of the visibile view (normalized relative to 
;     the virtual canvas).
;
pro IDLitVisContourLevel::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    if (OBJ_VALID(self._oFont)) then begin
      ; Check if destination zoom factor or normalized viewport has changed.  
      ; If so, update the corresponding font properties.
      self._oFont->GetProperty, FONT_ZOOM=fontZoom, FONT_NORM=fontNorm
      if (OBJ_VALID(oDestination)) then $
          oDestination->GetProperty, CURRENT_ZOOM=zoomFactor $
      else $
          zoomFactor = 1.0
  
      normFactor = MIN(normViewDims)
      if ((fontZoom ne zoomFactor) || (fontNorm ne normFactor)) then begin
          self._oFont->SetProperty, FONT_ZOOM=zoomFactor, FONT_NORM=normFactor
      endif
    endif

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewportChange, oSubject, oDestination, $
        viewportDims, normViewDims
end

;---------------------------------------------------------------------------
; IDLitVisContourLevel::OnViewZoom
;
; Purpose:
;   This procedure method handles notification that the view zoom factor
;   has changed
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom factor change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewZoom: The new zoom factor for the view.
;
pro IDLitVisContourLevel::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    if (OBJ_VALID(self._oFont)) then begin
      ; Check if view zoom factor has changed.  If so, update the font.
      self._oFont->GetProperty, VIEW_ZOOM=fontViewZoom
  
      if (fontViewZoom ne viewZoom) then $
          self._oFont->SetProperty, VIEW_ZOOM=viewZoom
    endif

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewZoom, oSubject, oDestination, $
        viewZoom
end

;----------------------------------------------------------------------------
pro IDLitVisContourLevel__Define

    compile_opt idl2, hidden

    struct = { IDLitVisContourLevel,         $
        inherits _IDLitVisualization, $   ; Superclass: _IDLitVisualization
        _index: 0L,              $   ; my contour level index
        _labelType: 0b,          $
        _symbolsize: 0d,         $
        _tickFormat: '',         $
        _tickDefinedFormat: 0L,  $
        _value: 0d,              $
        _oContour: OBJ_NEW(),    $   ; my parent contour object
        _oSymbol: OBJ_NEW(),     $
        _oText: OBJ_NEW(),       $
        _oFont: OBJ_NEW()        $
    }
end
