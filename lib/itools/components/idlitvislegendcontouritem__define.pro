; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegendcontouritem__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendContourItem class is the component wrapper
;   for the surface item subcomponent of the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;


;----------------------------------------------------------------------------
pro IDLitVisLegendContourItem::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'SHOW_LEVELS', /BOOLEAN, $
            DESCRIPTION='Show Contour Levels', $
            NAME='Show Levels'

        self._showLevels = 1
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'LEVEL_LABELS', $
            ENUMLIST=['Individually defined', 'Level value', 'Level label'], $
            NAME='Level labels', $
            DESCRIPTION='Labels for the individual levels'
    endif

end


;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendContourItem::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisLegendItem::Init( $
        NAME="Contour Legend Item", $
        DESCRIPTION="A Contour Legend Entry", $
        _EXTRA=_extra)) then $
        return, 0

    self->IDLitVisLegendContourItem::_RegisterProperties

    return, 1 ; Success

end


;----------------------------------------------------------------------------
pro IDLitVisLegendContourItem::RecomputeLayout

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    nVisible = 0
    if nItems gt 0 then begin
        widths=FLTARR(nItems)
        heights=FLTARR(nItems)
        nVisible = 0
        for i=0, nItems-1 do begin
            oItems[i]->GetProperty, ITEM_RANGE=levelItemRange, HIDE=hide
            if (hide) then continue ;found hidden item, don't include in calculations
            oVisible = N_ELEMENTS(oVisible) eq 0 ? [oItems[i]] : [oVisible, oItems[i]]
            widths[nVisible] = levelItemRange[0]
            heights[nVisible] = levelItemRange[1]
            nVisible ++
        endfor
    endif

    if nItems gt 0 && nVisible gt 0 then begin
        yOffset = TOTAL(heights) + N_ELEMENTS(oVisible) * self._vertSpacing
    endif else yOffset = 0

    oTool = self->GetTool()
    self->GetProperty, PARENT=oParent
    if (~OBJ_VALID(oTool) || ~OBJ_VALID(oParent)) then return
    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return
    textDimensions = oWindow->GetTextDimensions(self._oText, DESCENT=descent)

    if (OBJ_VALID(self._oContour)) then begin
        ContourItemScaleFactor = 18.0
        self._oContour->SetProperty, $
            XCOORD_CONV=[0, self._sampleWidth/ContourItemScaleFactor], $
            YCOORD_CONV=[yOffset-descent, (textDimensions[1]+descent)/ContourItemScaleFactor]

        self._oText->SetProperty, $
            LOCATIONS=[[self._sampleWidth+self._horizSpacing, yOffset-descent]]
    endif
    yMax = yOffset + textDimensions[1] + self._vertSpacing/2.0

    itemRange = [self._sampleWidth+self._horizSpacing+textDimensions[0], $
                 textDimensions[1]]

    ; indent level items
    xOffset = self._sampleWidth / 2.0
    self->GetProperty, PARENT=oLegend
    maxWidth = 0
    for i=0, nVisible-1 do begin
        oVisible[i]->Reset
        yOffset = yOffset - heights[i] - self._vertSpacing
        oVisible[i]->Translate, xOffset, yOffset, 0
        itemRange = itemRange
        maxWidth = maxWidth > (xOffset + self._horizSpacing + widths[i])
    endfor
    itemRange[0] = itemRange[0] > maxWidth
    itemRange[1] = yMax

    self._itemRange = itemRange

    ; Draw required for UpdateSelectionVisual to get valid RANGE of text
    if (N_ELEMENTS(descent) gt 0) && (descent ne self._textDescent) then begin
        self->GetProperty, HIDE=hideOrig
        self->SetProperty, /HIDE
        oTool->RefreshCurrentWindow
        self._textDescent = descent
        self->SetProperty, HIDE=hideOrig
    endif
    self->UpdateSelectionVisual

    ; Update the upper level legend
    self->GetProperty, PARENT=oLegend
    if OBJ_VALID(oLegend) then oLegend->RecomputeLayout

end

;----------------------------------------------------------------------------
PRO IDLitVisLegendContourItem::UpdateLevels

    compile_opt idl2, hidden

    self->IDLitVisLegendItem::GetProperty, PARENT=oParent
    oParent->GetProperty, $
        SAMPLE_WIDTH=sampleWidth, $
        HORIZONTAL_SPACING=horizSpacing, $
        TEXT_COLOR=textColor

    ; destroy the old objects
    oLevelItems = self->Get(/ALL, ISA='IDLitVisLegendContourLevelItem', COUNT=count)
    if count gt 0 then OBJ_DESTROY, oLevelItems

    ; make the new objects
    self._oVisTarget->GetProperty, CONTOUR_LEVELS=oLevels, N_LEVELS=nLevels

    for i=0, nLevels-1 do begin
        ; Add objects if necessary
        oLevelItem = OBJ_NEW('IDLitVisLegendContourLevelItem', $
            HIDE=~self._showLevels, TOOL=self->GetTool())
        self->Add, oLevelItem
        ; Setting VIS_TARGET will automatically call ::BuildItem.
        oLevelItem->SetProperty, LEVEL_INDEX=i, $
            VIS_TARGET=self._oVisTarget->GetFullIdentifier()
    endfor

    self->RecomputeLayout

    oLevelItems = self->Get(/ALL, ISA='IDLitVisLegendContourLevelItem')

    FOR i=0, nLevels-1 DO BEGIN
      self->AddOnNotifyObserver, oLevelItems[i]->GetFullIdentifier(), $
        oLevels[i]->GetFullIdentifier()
    ENDFOR

end



;----------------------------------------------------------------------------
PRO IDLitVisLegendContourItem::BuildItem

    compile_opt idl2, hidden

    ; Call our superclass first to set our properties.
    self->IDLitVisLegendItem::BuildItem

    self->AddOnNotifyObserver, self->GetFullIdentifier(), $
        self._oVisTarget->GetFullIdentifier()

    self._oVisTarget->GetProperty, $
        ANTIALIAS=antialias, $
        COLOR=color, $
        C_COLOR=c_color, $
        CONTOUR_LEVELS=oLevels, $
        PALETTE=oPalette, $
        FILL=fill, $
;        STYLE=style, $
        NAME=name

    ; add notifier to track changes to level colors
    nLevels = N_ELEMENTS(oLevels)
    if OBJ_VALID(oLevels[0]) then begin
        for i=0, nLevels-1 do begin
            self->AddOnNotifyObserver, self->GetFullIdentifier(), $
                oLevels[i]->GetFullIdentifier()
        endfor
    endif

    if (~OBJ_VALID(oPalette)) then oPalette = OBJ_NEW()
    if (n_elements(name) eq 0) then name=''

    nVerts = 20.
    verts = FLTARR(nVerts,nVerts,/NOZERO)   ;Make array
    for i=0L, nVerts-1 do begin ;Row loop
        for j=0L, nVerts-1 do begin
            verts[i,j] = exp(-((i-nVerts/2+1)^2/(2*nVerts) + (j-nVerts/2+1)^2/(2*nVerts)))
        endfor
    endfor

    self._oContour = OBJ_NEW('IDLgrContour', $
        verts, $
        c_value=[.135, .4, .8, .999], $
        intarr(5,5), $
        ANTIALIAS=antialias, $
        COLOR=color, $
        C_COLOR=c_color, $
        FILL=fill, $
        GEOMZ=0.0, $
        PALETTE=oPalette, $
        /PLANAR, $
        NAME=name, $
        /PRIVATE)

    self->Add, self._oContour

    self._oText->SetProperty, STRINGS=name

    self->UpdateLevels

end




;----------------------------------------------------------------------------
; IDLitVisLegendContourItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegendContourItem::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisLegendContourItem::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Purpose:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
pro IDLitVisLegendContourItem::GetProperty, $
    ITEM_RANGE=itemRange, $
    SHOW_LEVELS=showLevels, $
    LEVEL_LABELS=levelLabels, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get my properties
    if (ARG_PRESENT(itemRange)) then $
        itemRange = self._itemRange

    if (ARG_PRESENT(showLevels)) then $
        showLevels = self._showLevels

    if (ARG_PRESENT(levelLabels)) then $
        levelLabels = self._levelLabels

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisLegendItem::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
; Purpose:
;      This procedure method sets the value
;      of a property or group of properties.
;
pro IDLitVisLegendContourItem::SetProperty,  $
    SHOW_LEVELS=showLevels, $
    LEVEL_LABELS=levelLabels, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(showLevels) gt 0) then begin
        self._showLevels = showLevels
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
          oItems[i]->SetProperty, HIDE=~showLevels
        endfor
        self->SetPropertyAttribute,'LEVEL_LABELS',SENSITIVE=self._showLevels
        self->RecomputeLayout
    endif

    IF n_elements(levelLabels) NE 0 THEN BEGIN
      self._levelLabels = levelLabels
      ;; set values of all legend level items
      IF levelLabels GT 0 THEN BEGIN
        oItems = self->Get(/ALL,ISA='IDLitVisLegendContourLevelItem', COUNT=nItem)
        FOR i=0,nItem-1 DO oItems[i]->SetProperty, LABEL_VALUE=levelLabels-1
      ENDIF
    ENDIF

    ; Set superclass properties
    if (N_Elements(_extra) gt 0) then begin
        ; Pass font properties on to our contour level items.
        fProps = Where(Strpos(_extra, 'FONT_') eq 0, nFont)
        if (nFont gt 0) then begin
            oItems = self->Get(/ALL,ISA='IDLitVisLegendContourLevelItem', COUNT=nItem)
            for i=0,nItem-1 do oItems[i]->SetProperty, _EXTRA=_extra[fProps]
        endif
        self->IDLitVisLegendItem::SetProperty, _EXTRA=_extra
    endif

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
pro IDLitVisLegendContourItem::OnNotify, strItem, StrMessage, strUser

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

        'C_COLOR': begin
            oSubject->GetProperty, C_COLOR=c_color
            if (N_ELEMENTS(c_color) gt 0) then begin
                self._oContour->SetProperty, $
                    C_COLOR=c_color
            endif
            end

        'PAL_COLOR': begin
            oSubject->GetProperty, PAL_COLOR=palColor
            if (N_ELEMENTS(palColor) gt 0) then begin
                self._oVisTarget->GetProperty, $
                    C_COLOR=c_color, $
                    PALETTE=oPalette
                if palColor gt 0 then begin
                    self._oContour->SetProperty, $
                        C_COLOR=c_color, $
                        PALETTE=oPalette
                    oPalette->GetProperty, BLUE_VALUES=blue, $
                            GREEN_VALUES=green, RED_VALUES=red
                    nIndices = N_ELEMENTS(c_color)
                    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
                    for i=0, nItems-1 do begin
                        oItems[i]->SetProperty, $
                            COLOR=[red[c_color[i mod nIndices]], $
                                green[c_color[i mod nIndices]], $
                                blue[c_color[i mod nIndices]]]
                    endfor
                endif else begin
                    self._oContour->SetProperty, $
                        C_COLOR=c_color, $
                        PALETTE=OBJ_NEW()
                endelse
            endif
            end

        'VISUALIZATION_PALETTE': begin
            self._oVisTarget->GetProperty, $
                C_COLOR=c_color, $
                PALETTE=oPalette
            oPalette->GetProperty, BLUE_VALUES=blue, $
                    GREEN_VALUES=green, RED_VALUES=red
            nIndices = N_ELEMENTS(c_color)
            oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
            for i=0, nItems-1 do begin
                oItems[i]->SetProperty, $
                    COLOR=[red[c_color[i mod nIndices]], $
                        green[c_color[i mod nIndices]], $
                        blue[c_color[i mod nIndices]]]
            endfor
        end

        'ANTIALIAS': begin
            oSubject->GetProperty, ANTIALIAS=antialias
            if (N_ELEMENTS(antialias) gt 0) then begin
                self._oContour->SetProperty, ANTIALIAS=antialias
            endif
            end

        'FILL': begin
            oSubject->GetProperty, FILL=filled
            if (N_ELEMENTS(filled) gt 0) then begin
                self._oContour->SetProperty, $
                    FILL=filled
            endif
            end

        'N_LEVELS': begin
            oSubject->GetProperty, N_LEVELS=nLevels
            if (N_ELEMENTS(nLevels) gt 0) then begin
                self->GetProperty, PARENT=oParent
                oParent->GetProperty, HIDE=hideOrig
                oParent->SetProperty, /HIDE
                self->UpdateLevels
                oParent->SetProperty, HIDE=hideOrig
            endif
            end

;        'NAME': ;Note that the ITEM_TEXT property of the legend item
;                ;is set on creation to the NAME of the visualization,
;                ;but this is not updated if the vis name is changed
;                ;after creation.  Users may change the text property
;                ;in the legend and this should not be overwritten.

        ; notification from contourlevel object
        'COLOR': begin
            oSubject->GetProperty, COLOR=myColor, $
                PARENT=oParent, $   ; get the container
                INDEX=index
            self._oContour->GetProperty, $
                C_COLOR=c_color
            oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
            if OBJ_ISA(oSubject, 'IDLitVisContourLevel') then begin
                if (N_ELEMENTS(myColor) gt 0) then begin
                    if size(c_color, /n_dimensions) eq 2 && $
                        (size(c_color, /dimensions))[1] ge index then begin
                        c_color[*,index] = myColor
                        self._oContour->SetProperty, $
                            C_COLOR=c_color
                    endif
                    oItems[index]->SetProperty, COLOR=myColor
                endif
            endif else begin
                ; got the container, set all colors
                if size(c_color, /n_dimensions) eq 2 && $
                    (size(c_color, /dimensions))[0] eq 3 then begin
                    for i=0, (size(c_color, /dimensions))[1]-1 do begin
                        c_color[*,i] = myColor
                    endfor
                    self._oContour->SetProperty, $
                        C_COLOR=c_color
                endif
                for i=0, nItems-1 do begin
                    oItems[i]->SetProperty, COLOR=myColor
                endfor
            endelse
            end

        else: ; ignore unknown parameters

    endcase

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegendContourItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendContourItem object.
;
;-
pro IDLitVisLegendContourItem__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegendContourItem,           $
        inherits IDLitVisLegendItem, $
        _oContour: OBJ_NEW(),        $
        _showLevels: 0b, $
        _levelLabels: 0b, $
        _itemRange: [0.0, 0.0, 0.0] $
    }
end
