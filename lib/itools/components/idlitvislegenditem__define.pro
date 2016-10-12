; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegenditem__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendItem class is the component wrapper
;   for the plot item subcomponent of the legend.
;
; Modification history:
;     Written by: CT, June 2003.
;

;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendItem::Init, $
                               ITFONT=oItFont, $
                               ITEM=item, $
                               _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    success = self->IDLitVisualization::Init( $
        ICON='demo', $
        IMPACTS_RANGE=0, $   ; should not affect DataSpace range
        TYPE="IDLLEGENDITEM", $
        _EXTRA=_extra)

    if (not success) then $
        return, 0

    ; Register the parameters we are using for data
    self->RegisterParameter, 'VISUALIZATION', DESCRIPTION='Visualizations ', $
                            /INPUT, TYPES='VISUALIZATION',/optarget

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
    self._oItFont = OBJ_NEW('IDLitFont', FONT_ZOOM=fontZoom, VIEW_ZOOM=viewZoom, $
        FONT_NORM=fontNorm)
    ; NOTE: the IDLitFont  properties will be aggregated
    ; as part of the property registration process in an upcoming call
    ; to ::_RegisterProperties.

    ; Register all properties and set property attributes
    self->IDLitVisLegendItem::_RegisterProperties

    self._oText = OBJ_NEW('IDLgrText', $
        /ENABLE_FORMATTING, $
        RECOMPUTE_DIMENSIONS=2, $
        FONT=self._oItFont->GetFont(), $
        /KERNING, $
        /PRIVATE)
    self->Add, self._oText

    return, 1 ; Success
end

;----------------------------------------------------------------------------
; Purpose:
;    Cleanup this component
;
pro IDLitVisLegendItem::Cleanup

    compile_opt idl2, hidden

    ; These are the only objects that won't be destroyed automatically.
    OBJ_DESTROY, [self._oItFont, self._oItSymbol]

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
pro IDLitVisLegendItem::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'ITEM_TEXT', /STRING, $
            DESCRIPTION='Item text', $
            NAME='Text'

        self->RegisterProperty, 'TEXT_COLOR', /COLOR, $
            DESCRIPTION='Item text color', $
            NAME='Text color'

        self->Aggregate, self._oItFont

        self->SetPropertyAttribute,'FONT_INDEX', $
            DESCRIPTION='Item text font', /ADVANCED_ONLY
        self->SetPropertyAttribute,'FONT_STYLE', $
            DESCRIPTION='Item text style', /ADVANCED_ONLY
        self->SetPropertyAttribute,'FONT_SIZE', $
            DESCRIPTION='Item text size'
    endif

end

;----------------------------------------------------------------------------
; IDLitVisLegendItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegendItem::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::Restore on each aggregated ItVis object
    ; to ensure any new properties are registered.  Also
    ; call its UpdateComponentVersion method so that this
    ; will not be attempted later
    if (OBJ_VALID(self._oItFont)) then begin
        self._oItFont->Restore
        self._oItFont->UpdateComponentVersion
    endif

    ; Register new properties.
    self->IDLitVisLegendItem::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Use the current zoom factor of the tool window as the
        ; initial font zoom factor.
        fontZoom = 1.0
        oTool = self->GetTool()
        if (OBJ_VALID(oTool) && OBJ_ISA(oTool, 'IDLitTool')) then begin
            oWin = oTool->GetCurrentWindow()
            if (OBJ_VALID(oWin)) then $
                oWin->GetProperty, CURRENT_ZOOM=fontZoom
        endif

        if (OBJ_VALID(self._oItFont)) then $
            self._oItFont->SetProperty, FONT_ZOOM=fontZoom

        if (OBJ_VALID(self._oText)) then $
            self._oText->SetProperty, RECOMPUTE_DIMENSIONS=2
    endif
end


;----------------------------------------------------------------------------
pro IDLitVisLegendItem::Add, oTargets, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; We allow a legend item to be a target for a legend item paste
    ; If so, we need to add it to the parent legend instead of ourself.
    if (OBJ_ISA(oTargets[0], 'IDLitVisLegendPlotItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendSurfaceItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendContourItem')) then begin
        self->GetProperty, PARENT=oLegend
        oLegend->Add, oTargets, _EXTRA=_extra
    endif else self->IDLitVisualization::Add, oTargets, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisLegendItem::BuildItem

    compile_opt idl2, hidden

    self->GetProperty, PARENT=oParent
    while (~OBJ_ISA(oParent, 'IDLitVisLegend')) do begin
        oParent[0]->IDLitComponent::GetProperty, _PARENT=oParent
        if ~OBJ_VALID(oParent) then $
            return
    endwhile

    oParent->GetProperty, $
        FONT_INDEX=fontIndex, $
        FONT_SIZE=fontSize, $
        FONT_STYLE=fontStyle, $
        TEXT_COLOR=textColor, $
        SAMPLE_WIDTH=sampleWidth, $
        HORIZONTAL_SPACING=horizSpacing, $
        VERTICAL_SPACING=vertSpacing

    ; Set these properties directly on our member data, to avoid
    ; going thru our own SetProperty and possibly causing
    ; a recomputelayout.
    self._oItFont->SetProperty, $
        FONT_INDEX=fontIndex, $
        FONT_SIZE=fontSize, $
        FONT_STYLE=fontStyle

    self._oText->SetProperty, $
        COLOR=textColor

    self._sampleWidth = sampleWidth
    self._horizSpacing = horizSpacing
    self._vertSpacing = vertSpacing

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegendItem::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegendItem::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegendItem::Init followed by the word "Get"
;      can be retrieved using IDLitVisLegendItem::GetProperty.  In addition
;      the following keywords are available:
;
pro IDLitVisLegendItem::GetProperty, $
    TEXT_COLOR=textColor, $
    ITEM_TEXT=itemText, $
    ORIENTATION=orientation, $
    ITEM_RANGE=itemRange, $
    VIS_TARGET=visTarget, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get my properties
    if (ARG_PRESENT(itemText)) then $
        self._oText->GetProperty, STRINGS=itemText

    if (ARG_PRESENT(textColor)) then $
        self._oText->GetProperty, COLOR=textColor

    if (ARG_PRESENT(itemRange)) then begin
        oTool = self->GetTool()
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
            return
        textDimensions = oWindow->GetTextDimensions(self._oText)
        itemRange = [self._sampleWidth+self._horizSpacing+textDimensions[0], $
                 textDimensions[1]]
    endif

    if (ARG_PRESENT(visTarget)) then begin
        visTarget = Obj_Valid(self._oVisTarget) ? $
            self._oVisTarget->GetFullIdentifier() : ''
    endif

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegendItem::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegendItem::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegendItem::Init followed by the word "Set"
;      can be set using IDLitVisLegendItem::SetProperty.
;-
pro IDLitVisLegendItem::SetProperty,  $
    TEXT_COLOR=textColor, $
    HIDE=hide, $
    HORIZONTAL_SPACING=horizSpacing, $
    ITEM_TEXT=itemText, $
    SAMPLE_WIDTH=sampleWidth, $
    ORIENTATION=orientation, $
    FONT_INDEX=fontIndex, $
    FONT_NORM=fontNorm, $
    FONT_STYLE=fontStyle, $
    FONT_SIZE=fontSize, $
    FONT_ZOOM=fontZoom, $
    VIEW_ZOOM=viewZoom, $
    VIS_TARGET=visTarget, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    bRecompLayout = 0b

    if (N_ELEMENTS(itemText) gt 0) then begin
        self._oText->SetProperty, STRINGS=itemText
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(textColor) gt 0) then begin
        self._oText->SetProperty, COLOR=textColor
    endif

    if (N_ELEMENTS(hide) gt 0) then begin
        self->IDLitVisualization::SetProperty, HIDE=hide
        ; no need to recompute our layout, but legend must recompute
        self->GetProperty, PARENT=oLegend
        if (OBJ_VALID(oLegend)) then $
            oLegend->RecomputeLayout
    endif

    if (N_ELEMENTS(horizSpacing) gt 0) then begin
        self._horizSpacing = horizSpacing
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(sampleWidth) gt 0) then begin
        self._sampleWidth = sampleWidth
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontIndex) gt 0) then begin
        self._oItFont->SetProperty, FONT_INDEX=fontIndex
        bRecompLayout = 1b
    endif
    if (N_ELEMENTS(fontNorm) gt 0) then begin
        self._oItFont->SetProperty, FONT_NORM=fontNorm
        bRecompLayout = 1b
    endif
    if (N_ELEMENTS(fontStyle) gt 0) then begin
        self._oItFont->SetProperty, FONT_STYLE=fontStyle
        bRecompLayout = 1b
    endif
    if (N_ELEMENTS(fontSize) gt 0) then begin
        self._oItFont->SetProperty, FONT_SIZE=fontSize
        bRecompLayout = 1b
    endif
    if (N_ELEMENTS(fontZoom) gt 0) then begin
        self._oItFont->SetProperty, FONT_ZOOM=fontZoom
        bRecompLayout = 1b
    endif
    if (N_ELEMENTS(viewZoom) gt 0) then begin
        self._oItFont->SetProperty, VIEW_ZOOM=viewZoom
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(visTarget) gt 0) then begin
        oTool = self->GetTool()
        if (Obj_Valid(oTool)) then begin
            oVis = oTool->GetByIdentifier(visTarget)
            if (Obj_Valid(oVis)) then begin
                self._oVisTarget = oVis
                self->BuildItem
            endif
        endif
    endif

    ; Set superclass properties
    if (N_ELEMENTS(orientation) || N_ELEMENTS(_extra)) then begin
        self->IDLitVisualization::SetProperty, DIRECTION=orientation, $
            _EXTRA=_extra
    endif

    if (bRecompLayout) then $
        self->RecomputeLayout
end

;---------------------------------------------------------------------------
; IDLitVisLegend::OnNotify
;
;
;  strItem - The item being observed
;
;  strMessage - What happend. For properties this would be
;               "SETPROPERTY"
;
;  strUser    - Message related data. For SETPROPERTY, this is the
;               property that changed.
;
pro IDLitVisLegendItem::OnNotify, strItem, StrMessage, strUser

   compile_opt idl2, hidden

    case strMessage of

        ; Setting our hide property will also call a RecomputeLayout.
        'DELETE': begin
            self->GetProperty, PARENT=oLegend
            if (OBJ_VALID(oLegend)) then begin
                oLegend->Remove, self
                oLegend->RecomputeLayout
            endif
            end

        'UNDELETE': begin
            self._oVisTarget->GetProperty, HIDE=hide
            self->SetProperty, HIDE=hide
            end

        else: ; ignore unknown messages
    endcase

end

;---------------------------------------------------------------------------
function IDLitVisLegendItem::GetVis

    compile_opt idl2, hidden

    return, self._oVisTarget
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegendItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendItem object.
;
;-
pro IDLitVisLegendItem__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegendItem, $
        inherits IDLitVisualization, $
        inherits IDLitPropertyBag, $
        _oVisTarget: OBJ_NEW(), $
        _oText: OBJ_NEW(), $
        _oItFont: OBJ_NEW(), $
        _oItSymbol: OBJ_NEW(), $
        _textInitted: 0L, $
        _textDescent: 0.0d, $
        _sampleWidth: 0.0, $
        _horizSpacing: 0.0, $
        _vertSpacing: 0.0 $
    }
end
