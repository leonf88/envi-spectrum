; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegendplotitem__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendPlotItem class is the component wrapper
;   for the plot item subcomponent of the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;




;----------------------------------------------------------------------------
;pro IDLitVisLegendPlotItem::_RegisterProperties, $
;    UPDATE_FROM_VERSION=updateFromVersion
;
;    compile_opt idl2, hidden
;
;    registerAll = ~KEYWORD_SET(updateFromVersion)
;
;    if (registerAll) then begin
;
;
;    endif
;
;end


;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendPlotItem::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisLegendItem::Init( $
        NAME="Plot Legend Item", $
        DESCRIPTION="A Plot Legend Entry", $
        _EXTRA=_extra)) then $
        return, 0

;    self->IDLitVisLegendPlotItem::_RegisterProperties

    return, 1 ; Success
end




;----------------------------------------------------------------------------
; IDLitVisLegendPlotItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegendPlotItem::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitVisLegendItem::Restore

    ; Call ::Restore on each aggregated ItVis object
    ; to ensure any new properties are registered.  Also
    ; call its UpdateComponentVersion method so that this
    ; will not be attempted later
    if (OBJ_VALID(self._oItSymbol)) then begin
        self._oItSymbol->Restore
        self._oItSymbol->UpdateComponentVersion
    endif

;    ; Register new properties.
;    self->IDLitVisLegendPlotItem::_RegisterProperties, $
;        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
pro IDLitVisLegendPlotItem::RecomputeLayout

    compile_opt idl2, hidden

    oTool = self->GetTool()
    self->GetProperty, PARENT=oParent
    if (OBJ_VALID(oTool) && OBJ_VALID(oParent)) then begin
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
            return
        ; get dimensions without formatting to retrieve normal height only
        self._oText->SetProperty, ENABLE_FORMATTING=0
        textDimensions = oWindow->GetTextDimensions(self._oText, DESCENT=descent1)
        yOffset = textDimensions[1]/2.0     ; place line at half height of text.
        ; get dimensions with formatting to retrieve descent
        self._oText->SetProperty, /ENABLE_FORMATTING
        textDimensions = oWindow->GetTextDimensions(self._oText, DESCENT=descent2)
        if (OBJ_VALID(self._oPolyline)) then begin
            xdata = self._sampleWidth
            ydata = yOffset+descent1/2.0-descent2
            ; Add an extra point in the middle in case there is a plot symbol.
            self._oPolyline->SetProperty, $
                DATA=[[0, ydata], [xdata/2.0, ydata], [xdata, ydata]]

            self._oText->SetProperty, $
                LOCATIONS=[[self._sampleWidth+self._horizSpacing, -descent2]]
        endif
    endif

    ; Draw required for UpdateSelectionVisual to get valid RANGE of text
    if (N_ELEMENTS(descent2) gt 0) && (descent2 ne self._textDescent) then begin
        self->GetProperty, HIDE=hideOrig
        self->SetProperty, /HIDE
        oTool->RefreshCurrentWindow
        self._textDescent = descent2
        self->SetProperty, HIDE=hideOrig
    endif
    self->UpdateSelectionVisual

    ; Update the upper level legend
    self->GetProperty, PARENT=oLegend
    if OBJ_VALID(oLegend) then oLegend->RecomputeLayout

end


;----------------------------------------------------------------------------
PRO IDLitVisLegendPlotItem::BuildItem

    compile_opt idl2, hidden

    ; Call our superclass first to set our properties.
    self->IDLitVisLegendItem::BuildItem

    self->AddOnNotifyObserver, self->GetFullIdentifier(), $
        self._oVisTarget->GetFullIdentifier()

    self._oVisTarget->GetProperty, $
        ANTIALIAS=antialias, $
        COLOR=color, $
        LINESTYLE=linestyle, $
        NAME=name, $
        THICK=thick

    if (n_elements(name) eq 0) then $
        name=''

    self._oPolyline = OBJ_NEW('IDLgrPolyline', $
        ANTIALIAS=antialias, $
        COLOR=color, $
        LINESTYLE=linestyle, $
        NAME=name, $
        THICK=thick, $
        /PRIVATE)

    self->Add, self._oPolyline

    self._oText->SetProperty, STRINGS=name

    oItSymbolTarget = self._oVisTarget->GetSymbol()
    self._oItSymbol = OBJ_NEW('IDLitSymbol', PARENT=self._oPolyline)

    ; don't use propertybag, it aggregates the itSymbol properties
    ; that causes the property sheet to complain that can't retrieve
    ; the properties since they are not handled in GetProperty
    ; retrieve the properties manually
    oItSymbolTarget->GetProperty, $
        SYM_INDEX=symIndex, $
        SYM_OBJECT=symObject, $
        SYM_SIZE=symSize, $
        USE_DEFAULT_COLOR=useDefaultColor, $
        SYM_COLOR=symColor, $
        SYM_FILLED=symFilled, $
        SYM_THICK=symThick
    self._oItSymbol->SetProperty, $
        SYM_INDEX=symIndex, $
        SYM_OBJECT=symObject, $
        SYM_SIZE=symSize, $
        USE_DEFAULT_COLOR=useDefaultColor, $
        SYM_COLOR=symColor, $
        SYM_FILLED=symFilled, $
        SYM_THICK=symThick
    self._oPolyline->SetProperty, SYMBOL=self._oItSymbol->GetSymbol()

    self->RecomputeLayout

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
pro IDLitVisLegendPlotItem::OnNotify, strItem, StrMessage, strUser

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
                if (OBJ_VALID(self._oVisTarget)) then begin
                    self._oVisTarget->GetProperty, $
                        USE_DEFAULT_COLOR=useDefaultColor
                    if (useDefaultColor) then $
                        self._oItSymbol->SetProperty, $
                            SYM_COLOR=color
                endif
            endif
            end

        'LINESTYLE': begin
            oSubject->GetProperty, LINESTYLE=linestyle
            if (N_ELEMENTS(linestyle) gt 0) then begin
                self._oPolyline->SetProperty, $
                    LINESTYLE=linestyle
            endif
            end

;        'NAME': ;Note that the ITEM_TEXT property of the legend item
;                ;is set on creation to the NAME of the visualization,
;                ;but this is not updated if the vis name is changed
;                ;after creation.  Users may change the text property
;                ;in the legend and this should not be overwritten.

        'ANTIALIAS': begin
            oSubject->GetProperty, ANTIALIAS=antialias
            if (N_ELEMENTS(antialias) gt 0) then begin
                self._oPolyline->SetProperty, $
                    ANTIALIAS=antialias
            endif
            end

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
                self._oItSymbol->SetProperty, $
                    SYM_INDEX=symIndex
            endif
            end

        'SYM_SIZE': begin
            oSubject->GetProperty, SYM_SIZE=symSize
            if (N_ELEMENTS(symSize) gt 0) then begin
                self._oItSymbol->SetProperty, $
                    SYM_SIZE=symSize
            endif
            end

        'USE_DEFAULT_COLOR': begin
            oSubject->GetProperty, USE_DEFAULT_COLOR=useDefaultColor
            if (N_ELEMENTS(useDefaultColor) gt 0) then begin
                self._oItSymbol->SetProperty, $
                    USE_DEFAULT_COLOR=useDefaultColor
            endif
            end

        'SYM_COLOR': begin
            oSubject->GetProperty, SYM_COLOR=symColor
            if (N_ELEMENTS(symColor) gt 0) then begin
                self._oItSymbol->SetProperty, $
                    SYM_COLOR=symColor
            endif
            end

        'SYM_THICK': begin
            oSubject->GetProperty, SYM_THICK=symThick
            if (N_ELEMENTS(symThick) gt 0) then begin
                self._oItSymbol->SetProperty, $
                    SYM_THICK=symThick
            endif
            end

        'SYM_FILLED': begin
            oSubject->GetProperty, SYM_FILLED=symFilled
            if (N_ELEMENTS(symFilled) gt 0) then begin
                self._oItSymbol->SetProperty, $
                    SYM_FILLED=symFilled
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
; IDLitVisLegendPlotItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendPlotItem object.
;
;-
pro IDLitVisLegendPlotItem__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegendPlotItem,           $
        inherits IDLitVisLegendItem, $
        _oPolyline: OBJ_NEW() $
    }
end
