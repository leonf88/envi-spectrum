; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisplot3d__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisPlot3D
;
; PURPOSE:
;    The IDLitVisPlot class is the component that implements a 3D plot
;    using IDLgrPolyline.
;
; CATEGORY:
;    Components
;
; MODIFICATION HISTORY:
;     Written by:   AY, 02/2003
;-

;----------------------------------------------------------------------------
pro IDLitVisPlot3D::_RegisterParameters

    compile_opt idl2, hidden

    self->RegisterParameter, 'Z', DESCRIPTION='Z Plot Data', $
        /INPUT, TYPES=['IDLVECTOR'], /OPTARGET

    self->RegisterParameter, 'X', DESCRIPTION='X Plot Data', $
        /INPUT, TYPES=['IDLVECTOR'], /OPTARGET

    self->RegisterParameter, 'Y', DESCRIPTION='Y Plot Data', $
        /INPUT, TYPES=['IDLVECTOR'], /OPTARGET

    self->RegisterParameter, 'VERTICES', DESCRIPTION='Vertex Data', $
        /INPUT, TYPES=['IDLARRAY2D'], /OPTARGET, /OPTIONAL

    self->RegisterParameter, 'Y ERROR', DESCRIPTION='Y Error Data', $
        /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], /OPTIONAL

    self->RegisterParameter, 'X ERROR', DESCRIPTION='X Error Data', $
        /INPUT, TYPES=['IDLVECTOR', 'IDLARRAY2D'], /OPTIONAL

    self->RegisterParameter, 'Z ERROR', DESCRIPTION='Z Error Data', $
        /INPUT, TYPES=['IDLVECTOR', 'IDLARRAY2D'], /OPTIONAL

    self->RegisterParameter, 'PALETTE', DESCRIPTION='RGB Color Table', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTARGET, /OPTIONAL

    self->RegisterParameter, 'VERTEX_COLORS', DESCRIPTION='Vertex Colors', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

end

;----------------------------------------------------------------------------
pro IDLitVisPlot3d::_RegisterProperties

    compile_opt idl2, hidden

    ; Add general properties
    self->RegisterProperty, 'VISUALIZATION_PALETTE', $
        NAME='Vertex color table', $
        USERDEF='Edit color table', $
        DESCRIPTION='Edit RGB Color Table', $
        SENSITIVE=0, /ADVANCED_ONLY

    self->RegisterProperty, 'XY_SHADOW', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='XY Shadow', $
        NAME='XY shadow', /ADVANCED_ONLY
    self->RegisterProperty, 'YZ_SHADOW', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='YZ Shadow', $
        NAME='YZ shadow', /ADVANCED_ONLY
    self->RegisterProperty, 'XZ_SHADOW', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='XZ Shadow', $
        NAME='XZ shadow', /ADVANCED_ONLY
    self->RegisterProperty, 'SHADOW_COLOR', /COLOR, $
        DESCRIPTION='Shadow color', $
        NAME='Shadow color', /ADVANCED_ONLY

    self->RegisterProperty, 'X_ERRORBARS', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='X Error Bars', $
        NAME='X error bars', $
        /HIDE, /ADVANCED_ONLY

    self->RegisterProperty, 'Y_ERRORBARS', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='Y Error Bars', $
        NAME='Y error bars', $
        /HIDE, /ADVANCED_ONLY

    self->RegisterProperty, 'Z_ERRORBARS', $
        ENUMLIST=['Hide','Show'], $
        DESCRIPTION='Z Error Bars', $
        NAME='Z error bars', $
        /HIDE, /ADVANCED_ONLY

    self->RegisterProperty, 'ERRORBAR_COLOR', /COLOR, $
        DESCRIPTION='Error bar color', $
        NAME='Error bar color', $
        /HIDE, /ADVANCED_ONLY

    self->RegisterProperty, 'ERRORBAR_CAPSIZE', /FLOAT, $
        DESCRIPTION='Length of error bar end cap', $
        NAME='Error bar endcap size', $
        VALID_RANGE=[0, 1, .01d], $
        /HIDE, /ADVANCED_ONLY

    self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
        NAME='Transparency', $
        DESCRIPTION='Transparency of the 3D Plot', $
        VALID_RANGE=[0, 100, 5]

    ; Use TRANSPARENCY property instead.
    self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

    ; We can handle the SYM_INCREMENT property, so unhide it in
    ; our symbol object.
    self._oSymbol->SetPropertyAttribute, 'SYM_INCREMENT', HIDE=0

end


;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; The IDLitVisPlot3D object implements 3D plots.
;
; METHODNAMES:
;   IDLitVisPlot3D::Init
;
; PURPOSE:
;   Initialize this component
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;
;   Obj = OBJ_NEW('IDLitVisPlot3D')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;   ERRORBAR_COLOR (Get, Set):
;       RGB value specifying the color for the error bar.
;       Default = [0,0,0] (black)
;   ERRORBAR_CAPSIZE (Get, Set):
;       Float value specifying the size of the error bar endcaps.
;       Value ranges from 0 to 1.0.  A value of 1.0 results
;       in an endcap that is 10% of the width/height of the plot.
;   SYM_INCREMENT (Get, Set):
;       Integer value specifying the number of vertices to increment
;       between symbol instances.  Default is 1 for a symbol on
;       every vertex.
;   SYMBOL (Get, Set) (IDLitSymbol):
;       The symbol index that specifies the particular symbol (or no symbol)
;       to use.
;   SYM_SIZE (Get, Set) (IDLitSymbol):
;       Float value from 0.0 to 1.0 specifying the size of the plot symbol.
;       A value of 1.0 results in an symbol that is 10% of the width/height
;       of the plot.
;   SYM_COLOR (Get, Set) (IDLitSymbol):
;       RGB value speciying the color for the plot symbol.  Note this
;       color is applied to the symbol only if the USE_DEFAULT_COLOR
;       property is false.
;   SYM_THICK (Get, Set) (IDLitSymbol):
;       Float value from 1 to 10 specifying the thickness of the plot symbol.
;   TRANSPARENCY (Get, Set):
;       Integer value specifying the transparency of the filled area.
;       Valid values range from 0 to 100.  Default is 0 (opaque).
;   USE_DEFAULT_COLOR (Get, Set) (IDLitSymbol):
;       Boolean: False to use the symbol color instead of matching the plot.
;   [XYZ]_ERRORBARS (Get, Set):
;       Boolean: Hide or Show the error bars. Default = Show
;   [XYZ]_LOG (Get, Set):
;       Set this keyword to specify a logarithmic axis.  The minimum
;       value of the axis range must be greater than zero.
;   XY_SHADOW (Get, Set):
;   YZ_SHADOW (Get, Set):
;   XZ_SHADOW (Get, Set):
;       Set these keywords to display the shadow of the plot in a 3D plot.
;       The shadow lies in the plane specified by the first two letters of
;       the keyword, at the minimum value of the data
;
; OUTPUTS:
;   This function method returns 1 on success, or 0 on failure.
;
;
;-
function IDLitVisPlot3d::Init, $
                       NAME=NAME, $
                       DESCRIPTION=DESCRIPTION, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not keyword_set(name))then name ='Plot3D'
    if(not keyword_set(DESCRIPTION))then DESCRIPTION ="A 3D Plot Visualization"

    ; Initialize superclass
    if(self->IDLitVisualization::Init(/REGISTER_PROPERTIES, TYPE='IDLPLOT3D',$
                                      NAME=NAME, ICON='plot', $
                                      DESCRIPTION=DESCRIPTION, $
                                      _EXTRA=_extra) ne 1) then $
      RETURN, 0

    self._finiteMask = Ptr_New([0b])

    self->Set3D, /ALWAYS

    self._oSymbol = OBJ_NEW('IDLitSymbol', PARENT=self)
    self._oSymbolSpacer = OBJ_NEW('IDLgrSymbol', 0)     ; 0 for no symbol

    self._oPalette = OBJ_NEW('IDLgrPalette')

    self._oPolyline = OBJ_NEW('IDLgrPolyline', /REGISTER_PROPERTIES, $
        /ANTIALIAS, PALETTE=self._oPalette, $
        SYMBOL=self._oSymbol->GetSymbol(), /private)

    self->IDLgrModel::Add, self._oSymbol
    self->Add, self._oPolyline, /AGGREGATE
    self->Aggregate, self._oSymbol

    self._oPolyline->GetProperty, COLOR=color

    self._oItShadowContainer = OBJ_NEW('_IDLitVisualization', $
        IMPACTS_RANGE=0, $
        SELECT_TARGET=0, $
        /PRIVATE)

    self._oPolylineXYShadow = OBJ_NEW('IDLgrPolyline', $
        /ANTIALIAS, COLOR=[127,127,127], $
        /HIDE, /PRIVATE)
    self._oItShadowContainer->Add, self._oPolylineXYShadow  ; Don't Aggregate !

    self._oPolylineYZShadow = OBJ_NEW('IDLgrPolyline', $
        /ANTIALIAS, COLOR=[127,127,127], $
        /HIDE, /PRIVATE)
    self._oItShadowContainer->Add, self._oPolylineYZShadow  ; Don't Aggregate !

    self._oPolylineXZShadow = OBJ_NEW('IDLgrPolyline', $
        /ANTIALIAS, COLOR=[127,127,127], $
        /HIDE, /PRIVATE)
    self._oItShadowContainer->Add, self._oPolylineXZShadow  ; Don't Aggregate !

   self->Add, self._oItShadowContainer

    self._oItXErrorBarContainer = OBJ_NEW('_IDLitVisualization', $
        IMPACTS_RANGE=0, $
        SELECT_TARGET=0, $
        /PRIVATE)
    self->Add, self._oItXErrorBarContainer
    self._oItYErrorBarContainer = OBJ_NEW('_IDLitVisualization', $
        IMPACTS_RANGE=0, $
        SELECT_TARGET=0, $
        /PRIVATE)
    self->Add, self._oItYErrorBarContainer
    self._oItZErrorBarContainer = OBJ_NEW('_IDLitVisualization', $
        IMPACTS_RANGE=0, $
        SELECT_TARGET=0, $
        /PRIVATE)
    self->Add, self._oItZErrorBarContainer

    temp = fltarr(2, 2)
    temp[0,*]=[0,0]
    temp[1,*]=[-0.5, 0.5]
    self._oXErrorPL = OBJ_NEW('IDLgrPolyline', DATA=temp, /private)
    self._oXErrorSym = OBJ_NEW('IDLgrSymbol', DATA=self._oXErrorPL)
    self._oXError = OBJ_NEW('IDLgrPolyline', SYMBOL=[self._oXErrorSym], /private)
    self._oItXErrorBarContainer->Add, self._oXError

    temp[0,*]=[-0.5, 0.5]
    temp[1,*]=[0,0]
    self._oYErrorPL = OBJ_NEW('IDLgrPolyline', DATA=temp, /private)
    self._oYErrorSym = OBJ_NEW('IDLgrSymbol', DATA=self._oYErrorPL)
    self._oYError = OBJ_NEW('IDLgrPolyline', SYMBOL=[self._oYErrorSym], /private)
    self._oItYErrorBarContainer->Add, self._oYError

    ; z error endcaps are in xy plane
    temp[0,*]=[-0.5, 0.5]
    temp[1,*]=[0,0]
    self._oZErrorPL = OBJ_NEW('IDLgrPolyline', DATA=temp, /private)
    self._oZErrorSym = OBJ_NEW('IDLgrSymbol', DATA=self._oZErrorPL)
    self._oZError = OBJ_NEW('IDLgrPolyline', SYMBOL=[self._oZErrorSym], /private)
    self._oItZErrorBarContainer->Add, self._oZError

    ; cap size of 1 covers approx. 10 % of the data range
    self._capSize = 0.2d ; reasonble default value

    ; Register Data Parameters
    self->_RegisterParameters

    ; Register properties and set property attributes
    self->_RegisterProperties

    self->SetPropertyAttribute, 'SHADING', ADVANCED_ONLY=0
    ; Set any properties
    if(n_elements(_extra) gt 0)then $
      self->IDLitVisPlot3d::SetProperty,  _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisPlot3d::Cleanup
;
; PURPOSE:
;   This procedure method performs all cleanup on the object.
;
;   NOTE: Cleanup methods are special lifecycle methods, and as such
;   cannot be called outside the context of object destruction.  This
;   means that in most cases, you cannot call the Cleanup method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Cleanup method
;   from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[IDLitVisPlot3d::]Cleanup
;
;-
pro IDLitVisPlot3d::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oPolyline
    OBJ_DESTROY, self._oPalette
    OBJ_DESTROY, self._oSymbol
    OBJ_DESTROY, self._oSymbolSpacer

    OBJ_DESTROY, self._oXErrorPL
    OBJ_DESTROY, self._oXErrorSym
    OBJ_DESTROY, self._oXError
    OBJ_DESTROY, self._oItXErrorBarContainer

    OBJ_DESTROY, self._oYErrorPL
    OBJ_DESTROY, self._oYErrorSym
    OBJ_DESTROY, self._oYError
    OBJ_DESTROY, self._oItYErrorBarContainer

    OBJ_DESTROY, self._oZErrorPL
    OBJ_DESTROY, self._oZErrorSym
    OBJ_DESTROY, self._oZError
    OBJ_DESTROY, self._oItZErrorBarContainer

    PTR_FREE, self._finiteMask

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot3d::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisPlot3d::Init followed by the word "Get"
;      can be retrieved using IDLitVisPlot3d::GetProperty.
;-
pro IDLitVisPlot3d::GetProperty, $
    ERRORBAR_COLOR=barColor, $
    ERRORBAR_CAPSIZE=capSize, $
    LINESTYLE=lineStyle, $
    SHADOW_COLOR=shadowColor, $
    SYMBOL=symValue, $
    SYM_INCREMENT=symIncrement, $
    TRANSPARENCY=transparency, $
    X_ERRORBARS=xErrorBars, $
    Y_ERRORBARS=yErrorBars, $
    Z_ERRORBARS=zErrorBars, $
    XY_SHADOW=XYShadow, $
    YZ_SHADOW=YZShadow, $
    XZ_SHADOW=XZShadow, $
    VISUALIZATION_PALETTE=visPalette, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(barColor) then begin
        ; get the color from one of the error bars.
        ; Both X, Y, and Z error bars are the same color for now.
        self._oXError->GetProperty, COLOR=barColor
    endif

    if ARG_PRESENT(capSize) then begin
        capSize = self._capSize
    endif

    if (ARG_PRESENT(lineStyle)) then begin
        self._oPolyline->GetProperty, LINESTYLE=lineStyle
    endif

    if (ARG_PRESENT(shadowColor)) then $
      self._oPolylineXYShadow->GetProperty, COLOR=shadowColor

    ; Handle SYMBOL manually so we don't return the IDLgrSymbol
    ; object by mistake.
    if ARG_PRESENT(symValue) then $
      self._oSymbol->GetProperty, SYMBOL=symValue

    if ARG_PRESENT(symIncrement) then $
        symIncrement = self._symIncrement

    if ARG_PRESENT(transparency) then begin
        self._oPolyline->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha * 100) < 100
    endif

    if ARG_PRESENT(xErrorBars) then begin
        self._oXError->GetProperty, HIDE=hide
        xErrorBars = ~hide
    endif

    if ARG_PRESENT(yErrorBars) then begin
        self._oYError->GetProperty, HIDE=hide
        yErrorBars = ~hide
    endif

    if ARG_PRESENT(zErrorBars) then begin
        self._oZError->GetProperty, HIDE=hide
        zErrorBars = ~hide
    endif

    if (ARG_PRESENT(XYShadow)) then begin
        self._oPolylineXYShadow->GetProperty, HIDE=hide
        XYShadow = ~hide
    endif
    if (ARG_PRESENT(YZShadow)) then begin
        self._oPolylineYZShadow->GetProperty, HIDE=hide
        YZShadow = ~hide
    endif
    if (ARG_PRESENT(XZShadow)) then begin
        self._oPolylineXZShadow->GetProperty, HIDE=hide
        XZShadow = ~hide
    endif

    if ARG_PRESENT(visPalette) then begin
        self._oPalette->GetProperty, BLUE_VALUES=blue, $
            GREEN_VALUES=green, RED_VALUES=red
        visPalette = TRANSPOSE([[red], [green], [blue]])
    endif

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot3d::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisPlot3d::Init followed by the word "Set"
;      can be set using IDLitVisPlot3d::SetProperty.
;-
pro IDLitVisPlot3d::SetProperty, $
    ERRORBAR_COLOR=barColor, $
    ERRORBAR_CAPSIZE=capSize, $
    COLOR=color, $
    LINESTYLE=lineStyle, $
    SHADOW_COLOR=shadowColor, $
    SYM_INCREMENT=symIncrement, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    X_ERRORBARS=xErrorBars, $
    Y_ERRORBARS=yErrorBars, $
    Z_ERRORBARS=zErrorBars, $
    X_VIS_LOG=xVisLog, $    ; Property not exposed, internal use only
    Y_VIS_LOG=yVisLog, $    ; Property not exposed, internal use only
    Z_VIS_LOG=zVisLog, $    ; Property not exposed, internal use only
    XY_SHADOW=XYShadow, $
    YZ_SHADOW=YZShadow, $
    XZ_SHADOW=XZShadow, $
    VISUALIZATION_PALETTE=visPalette, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(barColor) gt 0) then begin
        self._oXError->SetProperty, COLOR=barColor
        self._oYError->SetProperty, COLOR=barColor
        self._oZError->SetProperty, COLOR=barColor

        self._oXErrorPL->SetProperty, COLOR=barColor
        self._oYErrorPL->SetProperty, COLOR=barColor
        self._oZErrorPL->SetProperty, COLOR=barColor
    endif

    if (N_ELEMENTS(capSize) gt 0) then begin
        self->GetPropertyAttribute, 'ERRORBAR_CAPSIZE', $
            VALID_RANGE=validRange
        capSize >= validRange[0]
        capSize <= validRange[1]
        self._capSize = capSize
        self->_UpdateCapSize
    endif

    if (N_ELEMENTS(color) gt 0) then begin
        self._oPolyline->SetProperty, COLOR=color
        self._oSymbol->SetProperty, COLOR=color
    endif

    if (ISA(shadowColor)) then begin
      self._oPolylineXYShadow->SetProperty, COLOR=shadowColor
      self._oPolylineYZShadow->SetProperty, COLOR=shadowColor
      self._oPolylineXZShadow->SetProperty, COLOR=shadowColor
    endif

    if (N_ELEMENTS(lineStyle) gt 0) then begin
        self._oPolyline->SetProperty, LINESTYLE=lineStyle
;        self._oPolylineXYShadow->SetProperty, LINESTYLE=lineStyle
;        self._oPolylineYZShadow->SetProperty, LINESTYLE=lineStyle
;        self._oPolylineXZShadow->SetProperty, LINESTYLE=lineStyle
    endif

    if (N_ELEMENTS(symIncrement) gt 0) then begin
        self._symIncrement = symIncrement
        self->_UpdateSymIncrement
    endif

    if (N_ELEMENTS(thick) gt 0) then begin
        self._oPolyline->SetProperty, THICK=thick
;        self._oPolylineXYShadow->SetProperty, THICK=thick
;        self._oPolylineYZShadow->SetProperty, THICK=thick
;        self._oPolylineXZShadow->SetProperty, THICK=thick
    endif

    if (N_ELEMENTS(transparency)) then begin
        self._oPolyline->GetProperty, ALPHA_CHANNEL=alpha
        transOrig = 0 > ROUND(100 - alpha * 100) < 100
        self._oPolyline->SetProperty, $
            ALPHA_CHANNEL=0 > ((100. - transparency)/100) < 1
        self._oSymbol->GetProperty, SYM_TRANSPARENCY=symTrans
        if (transOrig eq symTrans) then $
          self._oSymbol->SetProperty, SYM_TRANSPARENCY=transparency
    endif

    if (N_ELEMENTS(xErrorBars) gt 0) then begin
        self._oXError->SetProperty, HIDE=~xErrorBars
        self._oXErrorPL->SetProperty, HIDE=~xErrorBars
    endif

    if (N_ELEMENTS(yErrorBars) gt 0) then begin
        self._oYError->SetProperty, HIDE=~yErrorBars
        self._oYErrorPL->SetProperty, HIDE=~yErrorBars
    endif

    if (N_ELEMENTS(zErrorBars) gt 0) then begin
        self._oZError->SetProperty, HIDE=~zErrorBars
        self._oZErrorPL->SetProperty, HIDE=~zErrorBars
    endif

    if (N_ELEMENTS(XYShadow) gt 0) then begin
        self._oPolylineXYShadow->SetProperty, HIDE=~XYShadow
    endif
    if (N_ELEMENTS(YZShadow) gt 0) then begin
        self._oPolylineYZShadow->SetProperty, HIDE=~YZShadow
    endif
    if (N_ELEMENTS(XZShadow) gt 0) then begin
        self._oPolylineXZShadow->SetProperty, HIDE=~XZShadow
    endif

    ; Internal use flag allowing the dataspace to
    ; control the state of the vis data
    if (N_ELEMENTS(xVisLog) gt 0 || $
        N_ELEMENTS(yVisLog) gt 0 || $
        N_ELEMENTS(zVisLog) gt 0) then begin
        self._oPolyline->GetProperty, DATA=data
        if N_ELEMENTS(data) gt 0 then begin
            if (N_ELEMENTS(xVisLog) gt 0 && xVisLog ne self._xVisLog) then begin
                self._xVisLog = xVisLog
                data[0,*] = (xVisLog gt 0) ? alog10(data[0,*]) : 10^data[0,*]
            endif
            if (N_ELEMENTS(yVisLog) gt 0 && yVisLog ne self._yVisLog) then begin
                self._yVisLog = yVisLog
                data[1,*] = (yVisLog gt 0) ? alog10(data[1,*]) : 10^data[1,*]
            endif
            if (N_ELEMENTS(zVisLog) gt 0 && zVisLog ne self._zVisLog) then begin
                self._zVisLog = zVisLog
                data[2,*] = (zVisLog gt 0) ? alog10(data[2,*]) : 10^data[2,*]
            endif
            self._oPolyline->SetProperty, DATA=data
            self->UpdateSelectionVisual
        endif
        self->_UpdateErrorBars, 0
        self->_UpdateErrorBars, 1
        self->_UpdateErrorBars, 2
        self->UpdateSelectionVisual
    endif

    if (N_ELEMENTS(visPalette) gt 0) then begin
        self._oPalette->SetProperty, BLUE_VALUES=visPalette[2,*], $
            GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
        oDataRGB = self->GetParameter('PALETTE')
        if OBJ_VALID(oDataRGB) then $
            success = oDataRGB->SetData(visPalette)
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data
;
; Arguments:
;   X, Y, Z
;
; Keywords:
;   NONE
;
pro IDLitVisPlot3D::GetData, x, y, z, _EXTRA=_extra
  compile_opt idl2, hidden

  self._oPolyline->GetProperty, DATA=data
  xx = REFORM(data[0,*])
  yy = REFORM(data[1,*])
  zz = REFORM(data[2,*])
  
  if (N_PARAMS() eq 1) then begin
    x = TRANSPOSE([[xx],[yy],[zz]])
  endif else begin
    x = TEMPORARY(xx)
    y = TEMPORARY(yy)
    z = TEMPORARY(zz)
  endelse
  
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   parm1, parm2, parm3
;
; Keywords:
;   NONE
;
pro IDLitVisPlot3D::PutData, arg1, arg2, arg3, _EXTRA=_extra
  compile_opt idl2, hidden
  
  RESOLVE_ROUTINE, 'iPlot', /NO_RECOMPILE

  case (N_Params()) of
    0: void = iPlot_GetParmSet(oParmSet, _EXTRA=_extra)
    1: void = iPlot_GetParmSet(oParmSet, arg1, _EXTRA=_extra)
    2: void = iPlot_GetParmSet(oParmSet, arg1, arg2, _EXTRA=_extra)
    3: void = iPlot_GetParmSet(oParmSet, arg1, arg2, arg3, _EXTRA=_extra)
  endcase
  
  ; Need to clear out the old data first, to avoid weird
  ; non-data-shrinking in _SetPolylineOneVector.
  self._oPolyline->SetProperty, DATA=[0,0]
  
  ;; Get the data from the parameterset and set the parameters
  oDataX = oParmSet->GetByName('X')
  if (OBJ_VALID(oDataX)) then begin
    self->SetParameter, 'X', oDataX
    oDataX->SetProperty, /AUTO_DELETE
  endif
  oDataY = oParmSet->GetByName('Y')
  if (OBJ_VALID(oDataY)) then begin
    self->SetParameter, 'Y', oDataY
    oDataY->SetProperty, /AUTO_DELETE
  endif
  oDataZ = oParmSet->GetByName('Z')
  if (OBJ_VALID(oDataZ)) then begin
    self->SetParameter, 'Z', oDataZ
    oDataZ->SetProperty, /AUTO_DELETE
  endif
  oDataV = oParmSet->GetByName('VERTICES')
  if (OBJ_VALID(oDataV)) then begin
    self->SetParameter, 'VERTICES', oDataV
    oDataV->SetProperty, /AUTO_DELETE
  endif

  ;; Notify of changed data
  self->OnDataChangeUpdate, oParmSet, '<PARAMETER SET>'

  ;; Clean up parameterset
  oParmSet->Remove, /ALL
  OBJ_DESTROY, oParmSet

  ; Send a notification message to update UI
  self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
  self->OnDataComplete, self
  
  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to edit a user-defined property.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   PropertyIdentifier: String giving the name of the userdef property.
;
; Keywords:
;   None.
;
function IDLitVisPlot3D::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

        'VISUALIZATION_PALETTE': begin
            success = oTool->DoUIService('PaletteEditor', self)
            if success then begin
                return, 1
            endif
        end

        else:

    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::_SetPolylineOneVector, dim, data
;
; PURPOSE:
;      This procedure method updates the error bar geometry based
;      on the plot data.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_SetPolylineOneVector
;
; INPUTS:
;      dim: dimension to operate on, 0 for X, 1 for Y, 2 for Z
;      data: data to load into the polyline
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot3d::_SetPolylineOneVector, dim, data

    compile_opt idl2, hidden

    self._oPolyline->GetProperty, DATA=temp

    if (N_ELEMENTS(temp) le 2) then begin
        type=SIZE(data, /TYPE)
        temp = MAKE_ARRAY(3, N_ELEMENTS(data), TYPE=type)
        (*self._finiteMask) = Make_Array(N_Elements(data), TYPE=1)+7b
    endif else begin
        oldLen = (Size(temp, /N_DIM) gt 1) ? (size(temp, /dimensions))[1] : 1
        if n_elements(data) gt oldLen then begin
            temp2 = temp
            type=SIZE(data, /TYPE)
            temp = MAKE_ARRAY(3, N_ELEMENTS(data), TYPE=type)
            temp[0,0:oldLen-1]=temp2[0,*]
            temp[1,0:oldLen-1]=temp2[1,*]
            temp[2,0:oldLen-1]=temp2[2,*]
            ;; Update finite mask
            finiteMask = Make_Array(N_Elements(data), TYPE=1)+7b
            finiteMask[0:oldLen-1] = *self._finiteMask
            *self._finiteMask = temporary(finiteMask)
        endif
    endelse

    temp[dim,0:n_elements(data)-1]=data

    ;; Filter out non-finite values
    if (min(finite(data)) eq 0) then begin

      ;; Note: the finite mask is stored as a single byte array.
      ;; The 0 bit is used for X, 1 for Y, 2 for Z.  A set bit (1)
      ;; means the value is finite, an unset bit (0) means the value
      ;; is Inf or NaN.  Example: 7 is good data for all 3 dimensions,
      ;; a 5 indicates bad data in the Y dimension.
      ;; The following line sets or unsets single bits on the
      ;; finitemask bytarr based on the dimension and the current
      ;; finite state of each data element.

      ;; Save finite mask for this dimension
      *self._finiteMask xor= (-finite(data) xor *self._finiteMask) and $
                             ishft(bytarr(n_elements(*self._finiteMask))+1b, $
                                   dim)

      ;; Determine triplets of all finite values
      fin = *self._finiteMask eq 7b

      ;; If no good data exist, bail
      if (max(fin) eq 0) then begin
        temp = [0,0,0]
        self._oPolyline->SetProperty, DATA=temp
        return
      endif

      ;; Replace bad values
      if (min(finite(data)) eq 0) then begin
        temp2 = data
        temp2[where(finite(data) eq 0)] = temp2[(where(finite(data)))[0]]
        temp[dim,0:n_elements(data)-1] = temporary(temp2)
      endif

      ;; Create connectivity array using binary fin (finite) array

      ;; Force the first element to always be a zero
      temp2 = [0,fin]

      ;; Get length of runs and indices of good values
      lengths = (u=[uniq(temp2),n_elements(fin)])-shift([u,-1],1)
      indices = where(temp2)

      ;; Create output array
      polylines = lonarr(n_elements(fin)+1)
      ;; Put in lengths (+1 to match indices)
      polylines[u[0:n_elements(u)-2:2]] = lengths[1:*:2]+1
      ;; Put in indices (+1 so that zero will not get filtered out)
      polylines[indices] = (indgen(n_elements(polylines)))[indices]
      ;; Remove zeros
      polylines = polylines[where(polylines ne 0)]
      ;; Remove +1 added previously
      polylines--

      self._oPolyline->SetProperty, DATA=temp, POLYLINES=polylines
    endif else begin
      self._oPolyline->SetProperty, DATA=temp
    end
    ; must process all dims at least once in order for ranges to
    ; be valid before adding shadows
    if (self._dimsProcessed LT 3) then self._dimsProcessed++

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::_UpdateShadows
;
; PURPOSE:
;      Update the geometry of the plot shadows
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateShadows
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot3d::_UpdateShadows

    compile_opt idl2, hidden

    self._oPolyline->GetProperty, DATA=temp
    if (N_ELEMENTS(temp) gt 0) then begin
        gotRanges = 0
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        x = 0.0
        y = 0.0
        z = 0.0
        if (OBJ_VALID(oDataSpace)) then begin
          oDataSpace->GetProperty, $
            X_MINIMUM=xMin, X_MAXIMUM=xMax, $
            Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
            Z_MINIMUM=zMin, Z_MAXIMUM=zMax
          x = xMax
          y = yMax
          z = zMin
        endif
        ; update XY shadow, flatten Z
        temp2=temp
        temp2[2,*]=z
        self._oPolylineXYShadow->SetProperty, DATA=temp2
        ; update XZ shadow, flatten Y
        temp2=temp
        temp2[1,*]=y
        self._oPolylineXZShadow->SetProperty, DATA=temp2
        ; update YZ shadow, flatten X
        temp2=temp
        temp2[0,*]=x
        self._oPolylineYZShadow->SetProperty, DATA=temp2
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::_UpdateSymIncrement
;
; PURPOSE:
;      Update the spacing of the symbols on the plot.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateSymIncrement
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot3D::_UpdateSymIncrement

    compile_opt idl2, hidden

    oSymArray = [self._oSymbol->GetSymbol()]
    ; Symbol increment of 1 means every point, don't insert spacer
    for i = 1, self._symIncrement-1 do begin
        oSymArray = [oSymArray, self._oSymbolSpacer]
    endfor
    self._oPolyline->SetProperty, SYMBOL=oSymArray
;    self._oPolylineXYShadow->SetProperty, SYMBOL=oSymArray
;    self._oPolylineXZShadow->SetProperty, SYMBOL=oSymArray
;    self._oPolylineYZShadow->SetProperty, SYMBOL=oSymArray
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::_UpdateSymSize
;
; PURPOSE:
;      Update the size of the symbols on the plot.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateSymSize
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot3d::_UpdateSymSize

    compile_opt idl2, hidden

    ; Setting the symbol size causes internal scaling to the data range
    ; Retrieve it's normalized value, and reset it to the same value
    ; to trigger the internal scaling.
    self._oSymbol->GetProperty, SYM_SIZE=symSize
    self._oSymbol->SetProperty, SYM_SIZE=symSize
end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot3d::_UpdateErrorBars, data, dim
;
; PURPOSE:
;      This procedure method updates the error bar geometry based
;      on the plot data.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot3d::]_UpdateErrorBars
;
; INPUTS:
;      data: A vector of plot data.
;      dim: 0 for X, 1 for Y, 2 for Z
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisPlot3d::_UpdateErrorBars, dim

    compile_opt idl2, hidden

    dimName = (['X','Y','Z'])[dim]
    oErrData = self->GetParameter(dimName + ' ERROR')
    if (~OBJ_VALID(oErrData)) then $
        return
    if (~oErrData->GetData(errdata)) then $
        return

    ; Retrieve plot data.
    oDataX = self->GetParameter('X')
    if (~OBJ_VALID(oDataX) || ~oDataX->GetData(xdata)) then $
        return
    oDataY = self->GetParameter('Y')
    if (~OBJ_VALID(oDataY) || ~oDataY->GetData(ydata)) then $
        return
    oDataZ = self->GetParameter('Z')
    if (~OBJ_VALID(oDataZ) || ~oDataZ->GetData(zdata)) then $
        return

    ndata = N_ELEMENTS(xdata)


    self._oPolyline->GetProperty, DATA=plotData

    ErrorData = fltarr(3, 2*ndata)
    ; set the other dimension's coordinates of polyline data
    ; same coordinate for both values of the specified dimension
    case dim of
    0: begin
        oError = self._oXerror
        plotdata = xdata
        ErrorData[1,0:*:2] = ydata
        ErrorData[1,1:*:2] = ydata
        ErrorData[2,0:*:2] = zdata
        ErrorData[2,1:*:2] = zdata
       end
    1: begin
        oError = self._oYerror
        plotdata = ydata
        ErrorData[0,0:*:2] = xdata
        ErrorData[0,1:*:2] = xdata
        ErrorData[2,0:*:2] = zdata
        ErrorData[2,1:*:2] = zdata
       end
    2: begin
        oError = self._oZerror
        plotdata = zdata
        ErrorData[0,0:*:2] = xdata
        ErrorData[0,1:*:2] = xdata
        ErrorData[1,0:*:2] = ydata
        ErrorData[1,1:*:2] = ydata
       end
    endcase

    case size(errdata, /n_dimensions) of
    1: begin
        ; vector of error values applied as both + and - error
        ErrorData[dim, 0:*:2] = plotdata - errdata
        ErrorData[dim, 1:*:2] = plotdata + errdata
    end
    2: begin
        ; 2xN array, [0,*] is negative error, [1,*] is positive error
        ErrorData[dim, 0:*:2] = plotdata - errdata[0,*]
        ErrorData[dim, 1:*:2] = plotdata + errdata[1,*]
    end
    else:
    endcase

    ; Handle logarithmic axes.
    if (self._xVisLog) then begin
        ErrorData[0, *] = alog10(ErrorData[0, *])
    endif
    if (self._yVisLog) then begin
        ErrorData[1, *] = alog10(ErrorData[1, *])
    endif
    if (self._zVisLog) then begin
        ErrorData[2, *] = alog10(ErrorData[2, *])
    endif


    polylineDescript = LONARR(3*ndata)
    polylineDescript[0:*:3]=2
    polylineDescript[1:*:3]=lindgen(ndata)*2
    polylineDescript[2:*:3]=lindgen(ndata)*2+1


    ; display the properties, even if the error bars themselves are hidden
    self->SetPropertyAttribute, [dimName + '_ERRORBARS', $
        'ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], HIDE=0

    ; Retrieve HIDE property - it may be specified on command line
    ; and set prior to processing of the parameter
    oError->GetProperty, HIDE=hide
    oError->SetProperty, DATA=temporary(ErrorData), $
        HIDE=hide, $   ; may be hid from dataDisconnect
        POLYLINES=polylineDescript

    self->_UpdateCapSize

end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot3d::_UpdateCapSize
;
; PURPOSE:
;      This procedure method scales the error bar geometry
;      to the dataspace data range.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateCapSize
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisPlot3d::_UpdateCapSize

    compile_opt idl2, hidden

    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        success = oDataSpace->GetXYZRange(xRange, yRange, zRange)
        if (success) then begin
            self._oXErrorSym->SetProperty, $
                SIZE=self._capSize*(yRange[1]-yRange[0])/10.0

            self._oYErrorSym->SetProperty, $
                SIZE=self._capSize*(xRange[1]-xRange[0])/10.0

            self._oZErrorSym->SetProperty, $
                SIZE=self._capSize*(xRange[1]-xRange[0])/10.0

        endif
    endif
end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;; IDLitVisPlot3D::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the plot.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLitVisPlot3d::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   ;; Just check the name and perform the desired action
   case ParmName of
       'X': begin
           self._oPolyline->GetProperty, data=data
           szDims = size(data,/dimensions)
           ;; Handle case of data being only [0,0]
           if (N_ELEMENTS(szDims) eq 1) then $
             data = TRANSPOSE(data)
           data[0,*] = indgen(szDims[[1]])
           if (N_ELEMENTS(szDims) eq 1) then $
             data = TRANSPOSE(data)
           self._oPolyline->SetProperty, data=data
       end
       'Y': begin
           self._oPolyline->GetProperty, data=data
           szDims = size(data,/dimensions)
           data[1,*] = indgen(szDims[1])
           self._oPolyline->SetProperty, data=data
       end
       'Z': begin
           self._oPolyline->GetProperty, data=data
           szDims = size(data,/dimensions)
           data[2,*] = indgen(szDims[1])
           self._oPolyline->SetProperty, data=data
       end
       'X ERROR': begin
           ; hide the error bars and their properties
           self._oXError->Setproperty, /HIDE
           self->SetPropertyAttribute, 'X_ERRORBARS', /HIDE
           self->GetPropertyAttribute, 'Y_ERRORBARS', HIDE=hideY
           self->GetPropertyAttribute, 'Z_ERRORBARS', HIDE=hideZ
           if (hideY && hideZ) then begin
           self->SetPropertyAttribute, $
               ['ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], /HIDE
           endif

           ; recompute data range to eliminate effect of errorbars
           self._oItXErrorBarContainer->SetProperty, IMPACTS_RANGE=0
           self->OnDataChange, self
           self->OnDataComplete, self
       end
       'Y ERROR': begin
           ; hide the error bars and their properties
           self._oYError->Setproperty, /HIDE
           self->SetPropertyAttribute, 'Y_ERRORBARS', /HIDE
           self->GetPropertyAttribute, 'X_ERRORBARS', HIDE=hideX
           self->GetPropertyAttribute, 'Z_ERRORBARS', HIDE=hideZ
           if (hideX && hideZ) then begin
           self->SetPropertyAttribute, $
               ['ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], /HIDE
           endif

           ; recompute data range to eliminate effect of errorbars
           self._oItYErrorBarContainer->SetProperty, IMPACTS_RANGE=0
           self->OnDataChange, self
           self->OnDataComplete, self
       end
       'Z ERROR': begin
           ; hide the error bars and their properties
           self._oZError->Setproperty, /HIDE
           self->SetPropertyAttribute, 'Z_ERRORBARS', /HIDE
           self->GetPropertyAttribute, 'X_ERRORBARS', HIDE=hideX
           self->GetPropertyAttribute, 'Y_ERRORBARS', HIDE=hideY
           if (hideX && hideY) then begin
           self->SetPropertyAttribute, $
               ['ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], /HIDE
           endif

           ; recompute data range to eliminate effect of errorbars
           self._oItZErrorBarContainer->SetProperty, IMPACTS_RANGE=0
           self->OnDataChange, self
           self->OnDataComplete, self
       end
       'VERTEX_COLORS':begin
           self._oPolyline->SetProperty, VERT_COLORS=0
       end

       'PALETTE': begin
            self._oPalette->SetProperty, $
                RED_VALUES=BINDGEN(256), $
                GREEN_VALUES=BINDGEN(256), $
                BLUE_VALUES=BINDGEN(256)
            self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=0
           end

       else:
       endcase
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisPlot3d::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the
;    subject and updates the internal IDLgrPolyline object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisPlot3d::]OnDataChange, oSubject, parmName
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the plot) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then it puts the data in the IDLgrPolyline object.
;
;    parmName: The name of the registered parameter.
;
;
;-
pro IDLitVisPlot3d::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden


    case strupcase(parmName) of
    '<PARAMETER SET>':begin
        ;; Get our data
        position = oSubject->Get(/ALL, count=nCount, NAME=names)
        for i=0, nCount-1 do begin
            oData = oSubject->GetByName(names[i],count=nCount)
            IF nCount NE 0 THEN self->OnDataChangeUpdate,oData,names[i]
        endfor
    END

    'X': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            dim=0   ; X
            self->_SetPolylineOneVector, dim, data

            ; We might get an X by itself through the import dialog.
            ; Add dummy Y and Z parameters so that a valid plot is
            ; produced.  If this is normal processing of a
            ; parameter_set these will get overwritten by the desired
            ; data.  We will not set these as parameters so as not to
            ; confuse the user who imported only a single vector and
            ; does not expect to see dummy parameters in the parameter
            ; editor.
            lenX = n_elements(data)
            oDataY = self->GetParameter('Y')
            if ~OBJ_VALID(oDataY) then begin
                self->_SetPolylineOneVector, 1, indgen(lenX)
            endif
            oDataZ = self->GetParameter('Z')
            if ~OBJ_VALID(oDataZ) then begin
                self->_SetPolylineOneVector, 2, indgen(lenX)
            endif

            ; must process all dims at least once in order for ranges to
            ; be valid before adding shadows
            if (self._dimsProcessed GE 3) then self->_UpdateShadows
        endif
    END

    'Y': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            dim=1   ; Y
            self->_SetPolylineOneVector, dim, data
            if (self._dimsProcessed GE 3) then  self->_UpdateShadows
        endif
    END

    'Z': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            dim=2   ; Z
            self->_SetPolylineOneVector, dim, data
            if (self._dimsProcessed GE 3) then self->_UpdateShadows
            self->_UpdateSymSize        ; handle the case for an overplot with no range change
        endif
    END

    'VERTICES': BEGIN
        if OBJ_ISA(oSubject, 'IDLitDataContainer') then begin
            oData = oSubject->Get(/ALL)
            success = oData[0]->GetData(dataX)
            type=SIZE(dataX, /TYPE)
            data = MAKE_ARRAY(3, N_ELEMENTS(dataX), TYPE=type)
            data[0,*]=dataX
            success = oData[1]->GetData(dataY)
            data[1,*]=dataY
            success = oData[2]->GetData(dataZ)
            data[2,*]=dataZ
        endif else success = oSubject->GetData(data)
        if (success) then begin
            ;; Check for valid vertex data
            dims = SIZE(data, /DIMENSIONS)
            nDims = SIZE(data, /N_DIMENSIONS)
            if nDims ne 2 or (dims[0] ne 2 and dims[0] ne 3) then begin
                self->ErrorMessage, $
                  [IDLitLangCatQuery('Message:InvalidVertex:Text')], $
                    severity=0, $
                    TITLE=IDLitLangCatQuery('Message:InvalidVertex:Title')
            endif else begin
                oDataSpace = self->GetDataSpace(/UNNORMALIZED)
                if (OBJ_VALID(oDataSpace)) then begin
                    oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
                    if (n_elements(xLog) gt 0) && (xLog gt 0) then data[0,*] = alog10(data[0,*])
                    if (n_elements(yLog) gt 0) && (yLog gt 0) then data[1,*] = alog10(data[1,*])
                    if (n_elements(zLog) gt 0) && (zLog gt 0) then data[2,*] = alog10(data[2,*])
                endif
                self._oPolyline->SetProperty, DATA=data
                self->_UpdateShadows
                self->_UpdateSymSize        ; handle the case for an overplot with no range change
            endelse
        endif
    END

    'X ERROR': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            self->_UpdateErrorBars, 0
            self->SetPropertyAttribute, 'ERRORBAR_COLOR', /SENSITIVE
            self->SetPropertyAttribute, 'ERRORBAR_CAPSIZE', /SENSITIVE
            self->SetPropertyAttribute, 'X_ERRORBARS', /SENSITIVE
            self._oItXErrorBarContainer->SetProperty, /IMPACTS_RANGE

        endif
    END

    'Y ERROR': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            self->_UpdateErrorBars, 1
            self->SetPropertyAttribute, 'ERRORBAR_COLOR', /SENSITIVE
            self->SetPropertyAttribute, 'ERRORBAR_CAPSIZE', /SENSITIVE
            self->SetPropertyAttribute, 'Y_ERRORBARS', /SENSITIVE
            self._oItYErrorBarContainer->SetProperty, /IMPACTS_RANGE

        endif
    END

    'Z ERROR': BEGIN
        success = oSubject->GetData(data)
        if (success) then begin
            self->_UpdateErrorBars, 2
            self->SetPropertyAttribute, 'ERRORBAR_COLOR', /SENSITIVE
            self->SetPropertyAttribute, 'ERRORBAR_CAPSIZE', /SENSITIVE
            self->SetPropertyAttribute, 'Z_ERRORBARS', /SENSITIVE
            self._oItZErrorBarContainer->SetProperty, /IMPACTS_RANGE

        endif
    END

    'PALETTE': begin
        if(oSubject->GetData(data)) then begin
            if (size(data, /TYPE) ne 1) then data=bytscl(temporary(data))
            self._oPalette->SetProperty, $
                RED_VALUES=data[0,*], $
                GREEN_VALUES=data[1,*], $
                BLUE_VALUES=data[2,*]
            oVertColors = self->GetParameter('VERTEX_COLORS')
            self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', /SENSITIVE
            if OBJ_VALID(oVertColors) then begin
                success = oVertColors->GetData(colors)
            endif
            if ~OBJ_VALID(oVertColors) || $
                (size(colors, /n_dimensions) gt 1) then begin
                ; define default indices
                oVertColorsDefault = OBJ_NEW('IDLitDataIDLVector', BINDGEN(256), $
                    NAME='<DEFAULT INDICES>')
                result = self->SetData(oVertColorsDefault, $
                    PARAMETER_NAME='VERTEX_COLORS',/by_value)
            endif
        endif
     end

    'VERTEX_COLORS': begin
        if(oSubject->GetData(data)) then begin
            if (size(data, /TYPE) ne 1) then data=bytscl(temporary(data))
            self._oPolyline->SetProperty, VERT_COLORS=data

            oRgbTable = self->GetParameter('PALETTE')
            if ~OBJ_VALID(oRgbTable) && $
                (size(data, /n_dimensions) eq 1) then begin
                ; define default palette, allows editing colors
                ; only used if vertex colors parameter is supplied
                ; and vertex colors are indices not colors.
                ramp = BINDGEN(256)
                colors = transpose([[ramp],[ramp],[ramp]])
                oColorTable = OBJ_NEW('IDLitDataIDLPalette', colors, NAME='RGB Table')

                ;; Set the data as by_value, so the parameter interface
                ;; will manage it.
                result = self->SetData(oColorTable, PARAMETER_NAME='PALETTE',/by_value)
            endif
        endif
    end

    ELSE: ; ignore unknown parameters
    ENDCASE

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::GetSymbol
;
; PURPOSE:
;      This function method returns the symbol associated with
;      the plot.  This allows the legend to retrieve the object
;      reference to obtain symbol properties directly.
;
; CALLING SEQUENCE:
;      oSymbol = Obj->[IDLitVisPlot3d::]GetSymbol
;
; RETURN VALUE:
;      Object reference to the symbol associated with the plot.
;
; INPUTS:
;      There are no inputs for this method.
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
function IDLitVisPlot3d::GetSymbol

    compile_opt idl2, hidden
    return, self._oSymbol

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot3d::GetDataString
;
; PURPOSE:
;      Convert XY dataspace coordinates into actual data values.
;
; CALLING SEQUENCE:
;      strDataValue = Obj->[IDLitVisPlot3d::]GetDataString
;
; RETURN VALUE:
;      String value representing the specified data values.
;
; INPUTS:
;      3 element vector containing X,Y and Z data coordinates.
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
function IDLitVisPlot3d::GetDataString, xyz
    compile_opt idl2, hidden

    if self._xVisLog then xyz[0] = 10^xyz[0]
    if self._yVisLog then xyz[1] = 10^xyz[1]
    if self._zVisLog then xyz[1] = 10^xyz[1]
    xyz = STRCOMPRESS(STRING(xyz, FORMAT='(G11.4)'))
    return, STRING(xyz, FORMAT='("X: ", A, "  Y: ", A, "  Z: ", A)')
end


pro IDLitVisPlot3d::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; Keep the shadows on the walls
    self->_UpdateShadows
    self->_UpdateSymSize

    ; Retrieve the data range of the plot.
    self._oPolyline->GetProperty, XRANGE=polylineXRange, YRANGE=polylineYRange, $
        ZRANGE=polylineZRange

    ; First check if the region is completely clipped.  If so,
    ; simply hide it.
    if ((polylineXRange[1] lt XRange[0]) or $
        (polylineXRange[0] gt XRange[1]) or $
        (polylineYRange[1] lt YRange[0]) or $
        (polylineYRange[0] gt YRange[1]) or $
        (polylineZRange[1] lt ZRange[0]) or $
        (polylineZRange[0] gt ZRange[1])) then begin
        self->IDLgrModel::SetProperty, CLIP_PLANES=0

        ; If not previously clipped, cache the hide flag setting
        ; so it can be restored properly later.
        if (self._bClipped eq 0) then begin
            self._bClipped = 1b
            self->GetProperty, HIDE=oldHide
            self._preClipHide = oldHide
        endif
        self->SetProperty, /HIDE
        self->SetPropertyAttribute, 'HIDE', SENSITIVE=0
    endif else begin
        ; If it was previously clipped, reset the hide flag to
        ; its old setting.
        if (self._bClipped) then begin
            self._bClipped = 0
            self->SetProperty, HIDE=self._preClipHide
            self->SetPropertyAttribute, 'HIDE', SENSITIVE=1
        endif

        ; Determine which, if any, clipping planes need to be enabled.
        nClip = 0
        clipPlanes = 0
        if (XRange[0] gt polylineXRange[0]) then begin
            clipPlanes = [-1,0,0,XRange[0]]
            nClip++
        endif

        if (XRange[1] lt polylineXRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[1,0,0,-XRange[1]]] : $
                [1,0,0,-XRange[1]]
            nClip++
        endif

        if (YRange[0] gt polylineYRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,-1,0,YRange[0]]] : $
                [0,-1,0,YRange[0]]
            nClip++
        endif

        if (YRange[1] lt polylineYRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,1,0,-YRange[1]]] : $
                [0,1,0,-YRange[1]]
            nClip++
        endif

        if (ZRange[0] gt polylineZRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,-1,ZRange[0]]] : $
                [0,0,-1,ZRange[0]]
            nClip++
        endif

        if (ZRange[1] lt polylineZRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,1,-ZRange[1]]] : $
                [0,0,1,-ZRange[1]]
            nClip++
        endif

        ; Enable any clip planes (or disable if none required).
        self->IDLgrModel::SetProperty, CLIP_PLANES=clipPlanes
    endelse
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisPlot3d__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisPlot3d object.
;
; INPUTS:
;      There are no inputs for this method.
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot3d__Define

    compile_opt idl2, hidden

    struct = { IDLitVisPlot3d,           $
        inherits IDLitVisualization, $   ; Superclass: _IDLitVisualization
        _oPolyline: OBJ_NEW(),          $   ; IDLgrPolyline object
        _oPalette: OBJ_NEW(), $
        _oItShadowContainer: OBJ_NEW(), $
        _oPolylineXYShadow: OBJ_NEW(), $
        _oPolylineYZShadow: OBJ_NEW(), $
        _oPolylineXZShadow: OBJ_NEW(), $
        _oSymbol: OBJ_NEW(),    $
        _oSymbolSpacer: OBJ_NEW(),    $
        _oItXErrorBarContainer: OBJ_NEW(),    $
        _oXErrorPL: OBJ_NEW(),    $
        _oXErrorSym: OBJ_NEW(),    $
        _oXError: OBJ_NEW(),    $
        _oItYErrorBarContainer: OBJ_NEW(),    $
        _oYErrorPL: OBJ_NEW(),    $
        _oYErrorSym: OBJ_NEW(),    $
        _oYError: OBJ_NEW(),    $
        _oItZErrorBarContainer: OBJ_NEW(),    $
        _oZErrorPL: OBJ_NEW(),    $
        _oZErrorSym: OBJ_NEW(),    $
        _oZError: OBJ_NEW(),    $
        _capSize: 0d,   $
        _symIncrement: 1L,  $ ;default is 1 for every vertex
        _xVisLog: 0L,  $
        _yVisLog: 0L,  $
        _zVisLog: 0L,  $
        _bClipped: 0b, $ ; plot lies entirely outside of current data range?
        _preClipHide: 0b,            $ ; HIDE setting prior to clip.
        _finiteMask: Ptr_New(), $
        _dimsProcessed: 0L $
    }
end
