; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegendcontourlevelitem__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendContourLevelItem class is the component wrapper
;   for the contour item subcomponent of the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;




;----------------------------------------------------------------------------
pro IDLitVisLegendContourLevelItem::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll || (updateFromVersion lt 610)) then begin

        ;; replacing text label with the one below so that the order in
        ;; the propertysheet is more intuitive
        self->SetPropertyAttribute,'ITEM_TEXT',/HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'LABEL_VALUE', $
            DESCRIPTION='The source of the label value', $
            ENUMLIST=['Level value', $
                      'Level label', $
                      'User defined' $
                     ], $
            NAME='Use text from', $
            SENSITIVE=1

        self->RegisterProperty, 'LABEL_TEXT', /STRING, $
            NAME='Text label', $
            DESCRIPTION='Legend item text label', $
            SENSITIVE=0

        self->RegisterProperty, 'TEXTFORMAT', /STRING, $
            NAME='Text format code', $
            DESCRIPTION='IDL format string or function name', $
            SENSITIVE=0, /ADVANCED_ONLY

        ;; get numeric formats
        result = IDLitGetResource(1, numericFormatNames, /NUMERICFORMAT, /NAMES)
        result = IDLitGetResource(1, numericFormatExamples, $
                                  /NUMERICFORMAT, /EXAMPLES)
        ;; get time formats
        result = IDLitGetResource(1, timeFormatNames, /TIMEFORMAT, /NAMES)
        result = IDLitGetResource(1, timeFormatExamples, /TIMEFORMAT, /EXAMPLES)

        self->RegisterProperty, 'TEXT_DEFINEDFORMAT', $
            DESCRIPTION='Predefined text format', $
            ENUMLIST=['None', $
                      'Use Text Format Code', $
                      numericFormatNames+' ('+numericFormatExamples+')', $
                      timeFormatNames+' ('+timeFormatExamples+')' $
                     ], $
            NAME='Text format', $
            SENSITIVE=1, /ADVANCED_ONLY

        ;; scale factor needed to make symbols in legend more visible
        self._symbolScaleFactor = 2.0

    endif

end


;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendContourLevelItem::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisLegendItem::Init( $
        NAME="Contour Legend Level Item", $
        DESCRIPTION="A Contour Legend Level Entry", $
        /_CREATED_IN_INIT, $
        _EXTRA=_extra)) then $
        return, 0

    self->IDLitVisLegendContourLevelItem::_RegisterProperties

    return, 1 ; Success
end

;----------------------------------------------------------------------------
pro IDLitVisLegendContourLevelItem::Cleanup
  compile_opt idl2, hidden

  OBJ_DESTROY, self._oPolyline
  OBJ_DESTROY, self._oSymbol

  ;; Cleanup superclass
  self->IDLitVisLegendItem::Cleanup

end



;----------------------------------------------------------------------------
; IDLitVisLegendContourLevelItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegendContourLevelItem::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitVisLegendItem::Restore

    ; Register new properties.
    self->IDLitVisLegendContourLevelItem::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
pro IDLitVisLegendContourLevelItem::RecomputeLayout, NOCOMPUTEPARENT=noComputeParent

    compile_opt idl2, hidden

    oTool = self->GetTool()
    self->GetProperty, PARENT=oParent
    if (~OBJ_VALID(oTool) || ~OBJ_VALID(oParent)) then return

    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return
    textDimensions = oWindow->GetTextDimensions(self._oText, DESCENT=descent)

    yOffset = textDimensions[1]/2.0     ; place line at half height of text.
    if (OBJ_VALID(self._oPolyline)) then begin
        self._oPolyline->SetProperty, $
            DATA=[[0, yOffset-descent/2.0], [self._sampleWidth, yOffset-descent/2.0]]

        self._oText->SetProperty, $
            LOCATIONS=[[self._sampleWidth+self._horizSpacing, -descent]]
    endif

    self->UpdateSelectionVisual

    ; Update the upper level legend unless parent explicitly updates it
    if (~ keyword_set(noComputeParent)) then begin
        self->GetProperty, PARENT=oContourItem
        if OBJ_VALID(oContourItem) then oContourItem->RecomputeLayout
    endif

end


;----------------------------------------------------------------------------
PRO IDLitVisLegendContourLevelItem::BuildItem

    compile_opt idl2, hidden

    ; Call our superclass first to set our properties.
    self->IDLitVisLegendItem::BuildItem

    self._oVisTarget->GetProperty, $
        PALETTE=oPalette, $
        CONTOUR_LEVELS=oLevels, $
        C_COLOR=cColor, $
        C_LINESTYLE=cLinestyle, $
        C_THICK=cThick, $
        COLOR=color, $
        Z_VIS_LOG=zVisLog

    ;; If format code is '', set it G0 instead for 6.0 BC
    format = (self._textFormat EQ '' ? '(G0)' : self._textFormat)
    oLevels[self._levelIndex]->GetProperty, VALUE=cValue
    if (Keyword_Set(zVisLog)) then cValue = 10^cValue
    name = STRING(cValue, FORMAT=format)

    if (N_ELEMENTS(cColor) eq 1 && cColor eq -1) then begin
        ; C_COLOR not set, use basic COLOR property
        lineColor = color
    endif else if obj_valid(oPalette) && $
        (SIZE(cColor,/n_dimensions) EQ 1) then begin

        ; C_COLOR was set to vector of indices into palette
        index = cColor[self._levelIndex mod ((SIZE(cColor,/dimensions))[0])]
        oPalette->GetProperty, N_COLORS=nColors
        index = index < nColors
        lineColor = oPalette->GetRGB(index)
    endif else if (SIZE(cColor,/n_dimensions) EQ 2) || $
        (n_elements(cColor) eq 3) then begin

        ; C_COLOR was set directly to 3xN array
        lineColor = cColor[*, (self._levelIndex mod $
            (SIZE(cColor,/dimensions))[size(cColor, /n_dimensions)-1])]
    endif else lineColor = [0,0,0] ; fallback

    dims = SIZE(cColor, /DIMENSIONS)
    self._oPolyline = OBJ_NEW('IDLgrPolyline', $
         COLOR=lineColor, $
         LINESTYLE=(N_ELEMENTS(cLinestyle) eq 1 && cLinestyle eq -1) ? $
             0 : cLinestyle[self._levelIndex mod N_ELEMENTS(cLinestyle)], $
         THICK=(N_ELEMENTS(cThick) eq 1 && cThick eq -1) ? $
             1 : cThick[self._levelIndex mod N_ELEMENTS(cThick)], $
        /PRIVATE)


    self._oText->SetProperty, STRINGS=name

    self->Add, self._oPolyline

    ;; if there is a symbol on the line, create a similar one for the
    ;; legend
    self._oVisTarget->GetProperty,C_LABEL_OBJECTS=cObjs
    IF obj_valid(cObjs[0]) && $
      obj_isa(cObjs[self._levelIndex],'IDLGRSYMBOL') THEN BEGIN
      self._oSymbol = obj_new('IDLitSymbol', PARENT=self._oPolyline)
      cObjs[self._levelIndex]->GetProperty, $
        DATA=symIndex, $
        SIZE=symSize, $
        COLOR=symColor, $
        THICK=symThick, $
        UVALUE=range
      ;; divide by the range to remove scaling on the contour itself
      IF n_elements(range) NE 0 THEN range=1.0
      self._oSymbol->SetProperty, $
        SYM_INDEX=symIndex[0], $
        SYM_SIZE=symSize[0]/range[0], $
        SYM_COLOR=symColor[0], $
        SYM_THICK=symThick[0]
      self._oPolyline->SetProperty, SYMBOL=self._oSymbol->GetSymbol()
    ENDIF

    ; Caller of BuildItem will recompute layout of parent
    self->RecomputeLayout, /NOCOMPUTEPARENT

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegendContourLevelItem::GetProperty
;
; PURPOSE:
;      This procedure method gets the value of a property.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegendContourLevelItem::]GetProperty
;
; INPUTS:
;      NONE
;
; KEYWORD PARAMETERS:
;
pro IDLitVisLegendContourLevelItem::GetProperty, $
    LEVEL_INDEX=levelIndex, $
    LABEL_TEXT=mylabeltext, $
    LABEL_VALUE=mylabelvalue, $
    TEXTFORMAT=textformat, $
    TEXT_DEFINEDFORMAT=textDefinedFormat, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if Arg_Present(levelIndex) then $
        levelIndex = self._levelIndex

    IF ARG_PRESENT(mylabeltext) THEN $
      mylabeltext = self._myLabelText

    IF ARG_PRESENT(mylabelvalue) THEN $
      mylabelvalue = self._myLabelValue

    IF ARG_PRESENT(textformat) THEN $
      textformat = self._textFormat

    IF ARG_PRESENT(textDefinedFormat) THEN $
      textDefinedFormat = self._textDefinedFormat

    ; Get superclass properties
    if (N_Elements(_extra) gt 0) then $
        self->IDLitVisLegendItem::GetProperty, _EXTRA=_extra
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegendContourLevelItem::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegendContourLevelItem::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;
pro IDLitVisLegendContourLevelItem::SetProperty,  $
    LEVEL_INDEX=levelIndex, $
    LABEL_VALUE=mylabelvalue, $
    LABEL_TEXT=mylabeltext, $
    TEXTFORMAT=textformat, $
    TEXT_DEFINEDFORMAT=textDefinedFormat, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_Elements(levelIndex) gt 0) then $
        self._levelIndex = levelIndex

    ; This is needed for our IDLitVisLegendContourItem parent.
    if (OBJ_VALID(self._oPolyline) && N_ELEMENTS(_extra)) then $
        self._oPolyline->SetProperty, _EXTRA=_extra

    ;; get properties from the viscontour
    if (N_Elements(mylabelvalue) || N_Elements(textformat) || $
        N_Elements(textDefinedFormat)) then begin
        self._oVisTarget->GetProperty, CONTOUR_LEVELS=oLevels, $
            C_LABEL_OBJECTS=cLabelObjects, Z_VIS_LOG=zVisLog
        oLevels[self._levelIndex]->GetProperty, VALUE=cValue
        if (Keyword_Set(zVisLog)) then cValue = 10^cValue
    endif

    IF n_elements(mylabelvalue) NE 0 THEN BEGIN
      self._myLabelValue = mylabelvalue
      self->SetPropertyAttribute,'LABEL_TEXT', $
        SENSITIVE=(mylabelvalue EQ 2)
      self->SetPropertyAttribute,'TEXT_DEFINEDFORMAT', $
        SENSITIVE=(mylabelvalue EQ 0)
      self->SetPropertyAttribute,'TEXTFORMAT', $
        SENSITIVE=((mylabelvalue EQ 0) AND $
                   (self._textdefinedformat EQ 1))

      ;; set level labels property on contour legend item
      self->GetProperty, PARENT=oParent
      oParent->GetProperty,LEVEL_LABELS=levLab
      IF mylabelvalue NE levLab-1 THEN $
        oParent->SetProperty,LEVEL_LABELS=0

      CASE mylabelvalue OF
        ;; use value from contour level
        0 : BEGIN
          format = (self._textFormat EQ '' ? '(G0)' : self._textFormat)
          str = STRING(cValue,FORMAT=format)
          self._myLabelText = str
          self._oText->SetProperty,STRING=str
        END
        ;; use contour label
        1 : BEGIN
          str = ' '
          IF self._levelIndex LT n_elements(cLabelObjects) THEN BEGIN
            oObj = cLabelObjects[self._levelIndex]
            IF obj_isa(oObj,'IDLGRTEXT') THEN $
              oObj->GetProperty,STRING=str
          ENDIF
          self._mylabeltext = str
          self._oText->SetProperty,STRING=STR
        END
        ;; user defined text
        2 : BEGIN
          self._oText->SetProperty,STRING=self._mylabeltext
        END
      ENDCASE
      self->RecomputeLayout
    ENDIF

    IF N_ELEMENTS(mylabeltext) NE 0 THEN BEGIN
      IF mylabeltext EQ '' THEN mylabeltext=' '
      self._myLabelText = mylabeltext
      self._oText->SetProperty,STRING=mylabeltext
      self->RecomputeLayout
    ENDIF

    IF N_ELEMENTS(textformat) NE 0 THEN BEGIN
      ;; Tricky code to verify that text formats are legal
      ;; or the format is a valid function name.
      textFormatCheck = STRTRIM(textFormat, 2)
      IF textFormatCheck NE '' THEN BEGIN
        IF (STRMID(textFormatCheck, 0, 1) EQ '(') && $
          (STRMID(textFormatCheck, $
                  STRLEN(textFormatCheck)-1, 1) EQ ')') THEN BEGIN
          CATCH, err
          IF (err NE 0) THEN BEGIN
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            ;; If this fails we will skip over the next line.
            test = STRING(0, FORMAT=textFormatCheck)
            textFormatValid = textFormatCheck
          ENDELSE
        ENDIF ELSE BEGIN
          ;; it's not a format, verify that it is a textformat function
          CATCH, err
          IF (err NE 0) THEN BEGIN
            CATCH, /CANCEL
          ENDIF ELSE BEGIN
            ;; If this fails we will skip over the next line.
            resolve_routine, textFormatCheck, $
                             /IS_FUNCTION, /NO_RECOMPILE
            textFormatValid = textFormatCheck
          ENDELSE
        ENDELSE
      ENDIF

      IF n_elements(textFormatValid) NE 0 THEN BEGIN
        ;; apply formatting to value
        self._textFormat = textFormatValid
        format = (self._textFormat EQ '' ? '(G0)' : self._textFormat)
        str = STRING(cValue,FORMAT=format)
        self._myLabelText = str
        self._oText->SetProperty,STRING=str
      ENDIF
      self->RecomputeLayout
    ENDIF

    IF N_ELEMENTS(textDefinedFormat) NE 0 THEN BEGIN
      self._textDefinedFormat = textDefinedFormat
      self->SetPropertyAttribute,'TEXTFORMAT', $
        SENSITIVE=(textDefinedFormat EQ 1)
      result = IDLitGetResource(1, numericFormats, /NUMERICFORMAT, /FORMATS)
      result = IDLitGetResource(1, timeFormats, /TIMEFORMAT, /FORMATS)
      offset = (num = 2)        ; offset to account for first two formats
      CASE 1 OF
        ;; no format
        textDefinedFormat EQ 0 : textFormat=''
        ;; use custom TEXTFORMAT code already in place
        textDefinedFormat EQ 1 : textFormat = self._textFormat
        ;; numeric formats
        textDefinedFormat LT ((num+=n_elements(numericFormats))) : $
          textFormat = numericFormats[textDefinedFormat-offset]
        ;; time formats
        textDefinedFormat LT ((num+=n_elements(timeFormats))) : $
          textFormat = $
            timeFormats[textDefinedFormat-offset-n_elements(numericFormats)]
        ELSE :
      ENDCASE
      ;; apply formatting
      self._textformat=textFormat
      format = (self._textFormat EQ '' ? '(G0)' : self._textFormat)
      str = STRING(cValue,FORMAT=format)
      self._myLabelText = str
      self._oText->SetProperty,STRING=str
      self->RecomputeLayout
    ENDIF

    ; Set superclass properties
    if (N_Elements(_extra) gt 0) then $
        self->IDLitVisLegendItem::SetProperty, _EXTRA=_extra
end

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitVisLegend::OnNotify
;;
;;
;;  strItem - The item being observed
;;
;;  strMessage - What happend. For properties this would be
;;               "SETPROPERTY"
;;
;;  strUser    - Message related data. For SETPROPERTY, this is the
;;               property that changed.
;;
;;
pro IDLitVisLegendContourLevelItem::OnNotify, strItem, StrMessage, strUser

   compile_opt idl2, hidden

    ; Let superclass handle other messages.
    if (strMessage ne 'SETPROPERTY') then begin
        ; Call our superclass.
        self->IDLitVisLegendItem::OnNotify, $
            strItem, StrMessage, strUser
        return
    endif

    oTool = self->GetTool()
    oSubject=oTool->GetByIdentifier(strItem)

    case STRUPCASE(strUser) OF

        'COLOR': begin
            oSubject->GetProperty, COLOR=color
            if (N_ELEMENTS(color) gt 0) then begin
                self._oPolyline->SetProperty, $
                    COLOR=color
            endif
            end

        'LINESTYLE': BEGIN
            oSubject->GetProperty, LINESTYLE=linestyle
            if (N_ELEMENTS(linestyle) gt 0) then begin
                self._oPolyline->SetProperty, $
                    LINESTYLE=linestyle
            endif
            end

        ;; from contour level:  none, value, text, or symbol
        'LABEL_TYPE' : BEGIN
          oSubject->GetProperty, LABEL_TYPE=labelType
          IF self._mylabelvalue EQ 1 THEN BEGIN
            ;; set legend labels
            SWITCH labelType OF
              0:& 3: BEGIN
                self._oText->SetProperty,STRING=' '
                BREAK
              END
              1:& 2: BEGIN
                oSubject->GetProperty, LABEL_TEXT=str
                IF str EQ '' THEN str=' '
                self._oText->SetProperty,STRINGS=str
                BREAK
              END
              ELSE :
            ENDSWITCH
            self->RecomputeLayout
          ENDIF

          ;; set legend symbols
          CASE labelType EQ 3 OF

            ;; no symbols on line
            0 : BEGIN
              IF obj_valid(self._oSymbol) THEN BEGIN
                self._oSymbol->SetProperty,SYM_INDEX=0
                self._oPolyline->SetProperty, $
                  SYMBOL=self._oSymbol->GetSymbol()
              ENDIF
            END

            ;; put symbols on line
            1 : BEGIN
              self._oVisTarget->GetProperty, C_LABEL_OBJECTS=cObjs

              IF ~obj_valid(self._oSymbol) THEN BEGIN
                IF (n_elements(cObjs) GT self._levelIndex) && $
                  obj_isa(cObjs[self._levelIndex],'IDLGRSYMBOL') THEN BEGIN
                  self._oSymbol = obj_new('IDLitSymbol', $
                                          PARENT=self._oPolyline)
                ENDIF
              ENDIF

              IF obj_valid(self._oSymbol) THEN BEGIN
                ;; get symbol properties and apply them here
                oSubject->GetProperty, $
                  LABEL_SYMBOL=symIndex, $
                  SYMBOL_SIZE=symSize
                self._oSymbol->SetProperty, $
                  SYM_INDEX=symIndex, $
                  SYM_SIZE=symSize*self._symbolScaleFactor
                self._oPolyline->SetProperty, $
                  SYMBOL=self._oSymbol->GetSymbol()
              ENDIF
            END
          ENDCASE
        END

        'VALUE': BEGIN
          IF self._mylabelvalue EQ 0 THEN BEGIN
            oSubject->GetProperty, VALUE=value
            if (N_ELEMENTS(value) gt 0) then begin
              format = (self._textFormat EQ '' ? '(G0)' : $
                        self._textFormat)
              self._oText->SetProperty, $
                STRINGS=STRING(value, FORMAT=format)
            endif
          ENDIF
        END

        'LABEL_TEXT': BEGIN
          IF self._mylabelvalue EQ 1 THEN BEGIN
            oSubject->GetProperty, LABEL_TYPE=labelType
            SWITCH labelType OF
              0:& 3: BEGIN
                self._oText->SetProperty,STRING=' '
                BREAK
              END
              1:& 2: BEGIN
                oSubject->GetProperty, LABEL_TEXT=str
                IF str EQ '' THEN str=' '
                self._oText->SetProperty,STRINGS=str
                BREAK
              END
              ELSE :
            ENDSWITCH
            self->RecomputeLayout
          ENDIF
        END

        'THICK': begin
            oSubject->GetProperty, THICK=thick
            if (N_ELEMENTS(thick) gt 0) then begin
                self._oPolyline->SetProperty, $
                    THICK=thick
            endif
            end

        'SYMBOL': begin
            oSubject->GetProperty, SYM_INDEX=symIndex
            if (N_ELEMENTS(symIndex) gt 0) then begin
                self._oSymbol->SetProperty, $
                    SYM_INDEX=symIndex
            endif
            end

        'SYM_SIZE': begin
            oSubject->GetProperty, SYM_SIZE=symSize
            if (N_ELEMENTS(symSize) gt 0) then begin
                self._oSymbol->SetProperty, $
                    SYM_SIZE=symSize
            endif
            end

        ;; symbol index
        'LABEL_SYMBOL': BEGIN
          oSubject->GetProperty, LABEL_SYMBOL=symIndex
          IF (N_ELEMENTS(symIndex) GT 0) THEN BEGIN
            self._oSymbol->SetProperty, $
              SYM_INDEX=symIndex
          ENDIF
        END

        ;; symbol size
        'SYMBOL_SIZE': BEGIN
          oSubject->GetProperty, SYMBOL_SIZE=symSize
          IF (N_ELEMENTS(symSize) GT 0) THEN BEGIN
            self._oSymbol->SetProperty, $
              SYM_SIZE=symSize*self._symbolScaleFactor
          ENDIF
        END

        'USE_DEFAULT_COLOR': begin
            oSubject->GetProperty, USE_DEFAULT_COLOR=useDefaultColor
            if (N_ELEMENTS(useDefaultColor) gt 0) then begin
                self._oSymbol->SetProperty, $
                    USE_DEFAULT_COLOR=useDefaultColor
            endif
            end

        'SYM_COLOR': begin
            oSubject->GetProperty, SYM_COLOR=symColor
            if (N_ELEMENTS(symColor) gt 0) then begin
                self._oSymbol->SetProperty, $
                    SYM_COLOR=symColor
            endif
            end

        'SYM_THICK': begin
            oSubject->GetProperty, SYM_THICK=symThick
            if (N_ELEMENTS(symThick) gt 0) then begin
                self._oSymbol->SetProperty, $
                    SYM_THICK=symThick
            endif
            end


        else: ; ignore unknown parameters

    endcase

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegendContourLevelItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendContourLevelItem object.
;
;-
pro IDLitVisLegendContourLevelItem__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegendContourLevelItem, $
               inherits IDLitVisLegendItem,    $
               _oPolyline: OBJ_NEW(),          $
               _oSymbol: OBJ_NEW(),            $
               _symbolScaleFactor: 0.0,        $
               _levelIndex: 0L,                $
               _myLabelValue: 0L,              $
               _myLabelText: '',               $
               _textFormat: '',                $
               _textDefinedFormat: 0L          $
             }
end
