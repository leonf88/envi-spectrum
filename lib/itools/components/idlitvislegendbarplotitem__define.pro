; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvislegendbarplotitem__define.pro#1 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The IDLitVisLegendBarPlotItem class is the component wrapper
;   for the barplot item subcomponent of the legend.
;
;

;----------------------------------------------------------------------------
; Purpose:
;   Initialize this component
;
function IDLitVisLegendBarPlotItem::Init, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  
  ; Initialize superclass
  if (~self->IDLitVisLegendItem::Init( $
    NAME="Plot Legend Item", $
    DESCRIPTION="A Plot Legend Entry", $
    _EXTRA=_extra)) then $
    return, 0
    
  return, 1 ; Success
  
end


;----------------------------------------------------------------------------
; IDLitVisLegendBarPlotItem::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegendBarPlotItem::Restore
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
  
end


;----------------------------------------------------------------------------
pro IDLitVisLegendBarPlotItem::RecomputeLayout
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
    if (OBJ_VALID(self._oPolygon)) then begin
      xdata = self._sampleWidth
      ydata = yOffset+descent1/2.0-descent2
      yLow = textDimensions[1]*0.20
      yHigh = textDimensions[1]*0.80
      ; Add an extra point in the middle in case there is a plot symbol.
      self._oPolygon->SetProperty, $
        DATA=[[0, yLow], [0, yHigh], [xdata, yHigh], [xdata, yLow], [0, yLow]] 
      self._oPolyline->SetProperty, $
        DATA=[[0, yLow], [0, yHigh], [xdata, yHigh], [xdata, yLow], [0, yLow]]
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
PRO IDLitVisLegendBarPlotItem::BuildItem
  compile_opt idl2, hidden
  
  ; Call our superclass first to set our properties.
  self->IDLitVisLegendItem::BuildItem
  
  self->AddOnNotifyObserver, self->GetFullIdentifier(), $
    self._oVisTarget->GetFullIdentifier()
    
  self._oVisTarget->GetProperty, $
    ANTIALIAS=antialias, $
    FILL_COLOR=color, $
    BOTTOM_COLOR=bottomColor, $
    USE_BOTTOM_COLOR=useBottomColor, $
    COLOR=outlineColor, $
    THICK=outlineThick, $
    LINESTYLE=outlineStyle, $
    OUTLINE=showOutline, $
    TRANSPARENCY=transparency, $
    NAME=name
    
  if (n_elements(name) eq 0) then $
    name=''

  vertColors = useBottomColor ? [[bottomColor,255],[bottomColor,255], $
    [color,255],[color,255],[bottomColor,255]] : [color,255] # [1,1,1,1,1]
  self._oPolygon = OBJ_NEW('IDLgrPolygon', $
;    ANTIALIAS=antialias, $
    ALPHA_CHANNEL=1-transparency/100., $
    COLOR=color, $
    NAME=name, $
    VERT_COLORS=vertColors, $
    /SHADING, $
    POLYGONS=[5,0,1,2,3,4], $
    /PRIVATE)
  self->Add, self._oPolygon
  self._oPolyline = OBJ_NEW('IDLgrPolyline', $
;    ANTIALIAS=antialias, $
    ALPHA_CHANNEL=1-transparency/100., $
    COLOR=outlineColor, $
    NAME=name, $
    LINESTYLE=outlineStyle, $
    THICK=outlineThick, $
    HIDE=~showOutline, $
    /PRIVATE)
  self->Add, self._oPolyline
  
  self._oText->SetProperty, STRINGS=name
  
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
pro IDLitVisLegendBarPlotItem::OnNotify, strItem, StrMessage, strUser
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
  
  switch STRUPCASE(strUser) OF
  
    'FILL_COLOR' :
    'USE_BOTTOM_COLOR' :
    'BOTTOM_COLOR' : begin
      oSubject->GetProperty, FILL_COLOR=color, $
        BOTTOM_COLOR=bottomColor, USE_BOTTOM_COLOR=useBottomColor
      self._oPolygon->GetProperty, VERT_COLORS=vertColors
      if ((N_ELEMENTS(color) ne 0) && (N_ELEMENTS(bottomColor) ne 0) && $
          (N_ELEMENTS(useBottomColor) ne 0) && $
          (N_ELEMENTS(vertColors) ne 0)) then begin
        alpha = (N_ELEMENTS(vertColors) gt 1) ? vertColors[3,0] : 255b
        vertColors = useBottomColor ? [[bottomColor,alpha], $
                                       [bottomColor,alpha], $
                                       [color,alpha], $
                                       [color,alpha], $
                                       [bottomColor,alpha]] : $
                                    [color,alpha] # [1,1,1,1,1]
        self._oPolygon->SetProperty, COLOR=color, VERT_COLORS=vertColors   
      endif
      break
    end
    
    'COLOR': begin
      oSubject->GetProperty, COLOR=color
      if (N_ELEMENTS(color) gt 0) then begin
        self._oPolyline->SetProperty, COLOR=color
      endif
      break
    end
    
;    'ANTIALIAS': begin
;      oSubject->GetProperty, ANTIALIAS=antialias
;      if (N_ELEMENTS(antialias) gt 0) then begin
;        self._oPolygon->SetProperty, $
;          ANTIALIAS=antialias
;      endif
;      break
;    end
    
    'THICK': begin
      oSubject->GetProperty, THICK=thick
      if (N_ELEMENTS(thick) gt 0) then begin
        self._oPolyline->SetProperty, THICK=thick
      endif
      break
    end
    
    'TRANSPARENCY': begin
      oSubject->GetProperty, TRANSPARENCY=transparency
      if (N_ELEMENTS(transparency) gt 0) then begin
        alpha = 1-transparency/100.
        self._oPolygon->GetProperty, VERT_COLORS=vertColors
        vertColors[3,*] = alpha * 255b
        self._oPolygon->SetProperty, VERT_COLORS=vertColors
        self._oPolyline->SetProperty, ALPHA_CHANNEL=alpha
      endif
      break
    end
    
    'LINESTYLE': begin
      oSubject->GetProperty, LINESTYLE=linestyle
      if (N_ELEMENTS(linestyle) gt 0) then begin
        self._oPolyline->SetProperty, LINESTYLE=linestyle
      endif
      break
    end
    
    'OUTLINE': begin
      oSubject->GetProperty, OUTLINE=outline
      if (N_ELEMENTS(outline) gt 0) then begin
        self._oPolyline->SetProperty, HIDE=~outline 
      endif
      break
    end
    
    else : ; ignore unknown parameters
    
  endswitch
  
end


;----------------------------------------------------------------------------
;+
; IDLitVisLegendBarPlotItem__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegendBarPlotItem object.
;
;-
pro IDLitVisLegendBarPlotItem__Define
  compile_opt idl2, hidden
  
  struct = {IDLitVisLegendBarPlotItem, $
            inherits IDLitVisLegendItem, $
            _oPolygon: OBJ_NEW(), $
            _oPolyline: OBJ_NEW() $
           }
end
