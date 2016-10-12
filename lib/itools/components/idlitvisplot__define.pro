; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisplot__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisPlot
;
; PURPOSE:
;    The IDLitVisPlot class is the component wrapper for IDLgrPlot
;
; CATEGORY:
;    Components
;
; MODIFICATION HISTORY:
;     Written by:   AY, 02/2003
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; Note that this discussion covers both 2D and 3D
; plots.  The IDLitVisplot object implements 2D plots, while the
; IDLitVisPlot3D object implements 3D plots.
;
; METHODNAMES:
;   IDLitVisPlot::Init
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
;   Obj = OBJ_NEW('IDLitVisPlot', [[X,] Y]])
;   Obj = OBJ_NEW('IDLitVisPlot3D', X, Y, Z)
;   Obj = OBJ_NEW('IDLitVisPlot', Vertices2D)
;   Obj = OBJ_NEW('IDLitVisPlot3D', Vertices3D)
;   Obj = OBJ_NEW('IDLitVisPlot', [R], Theta, /POLAR)
;
; INPUTS:
;   X: Vector of X coordinates
;   Y: Vector of Y coordinates
;   Z: Vector of Z coordinates
;   Vertices2D: 2xN array of X and Y coordinates
;   Vertices2D: 3xN array of X, Y and Z coordinates
;   R: Radius for Polar plot
;   Theta: Angle in radians for Polar plot
;
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrPlot in addition to
;   the following:
;
;   ERRORBAR_COLOR (Get, Set):
;       RGB value specifying the color for the error bar.
;       Default = [0,0,0] (black)
;   ERRORBAR_CAPSIZE (Get, Set):
;       Float value specifying the size of the error bar endcaps.
;       Value ranges from 0 to 1.0.  A value of 1.0 results
;       in an endcap that is 10% of the width/height of the plot.
;   FILL_BACKGROUND (Get, Set):
;       Boolean: True or False fill the area under the plot.
;       Default = False.
;   FILL_COLOR (Get, Set):
;       RGB value specifying the color for the filled area.
;       Default = [255,255,255] (white)
;   FILL_LEVEL (Get, Set):
;       Float value specifying the Y value for the lower boundary
;       of the fill region.
;   HISTOGRAM (Get, Set) (IDLgrPlot)
;       Set this keyword to force only horizontal and vertical lines
;       to be used to connect the plotted points. By default, the
;       points are connected using a single straight line. The
;       histogram property applies to 2D plots only.  The histogram
;       keyword is ignored for 3D plots.
;   TRANSPARENCY (Get, Set):
;       Integer value specifying the transparency of the plot lines.
;       Valid values range from 0 to 100.  Default is 0 (opaque).
;   POLAR (Get, Set)
;       Set this keyword to display the plot as a polar plot. If this is
;       set the arguments will be interpreted as R and Theta or simply
;       Theta for a single argument.  If R is not supplied the plot will
;       use a vector of indices for the R argument. Default = False
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
;   FILL_TRANSPARENCY (Get, Set):
;       Integer value specifying the transparency of the filled area.
;       Valid values range from 0 to 100.  Default is 0 (opaque).
;   USE_DEFAULT_COLOR (Get, Set) (IDLitSymbol):
;       Boolean: False to use the symbol color instead of matching the plot.
;   [XY]_ERRORBARS (Get, Set):
;       Boolean: Hide or Show the error bars. Default = Show
;   [XY]LOG (Get, Set):
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
function IDLitVisPlot::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(/REGISTER_PROPERTIES, $
        NAME='Plot', ICON='plot', TYPE='IDLPLOT',$
        DESCRIPTION='A Plot Visualization', $
        _EXTRA=_extra)) then return, 0

    self._oPalette = OBJ_NEW('IDLgrPalette')
    self._oSymbol = OBJ_NEW('IDLitSymbol', PARENT=self)
    self._oSymbolSpacer = OBJ_NEW('IDLgrSymbol', 0)     ; 0 for no symbol

    ; Create plot object and add it to this Visualization.
    self._oPlot = OBJ_NEW('IDLgrPlot', /REGISTER_PROPERTIES, $
        /ANTIALIAS, PALETTE=self._oPalette, $
        SYMBOL=self._oSymbol->GetSymbol(), /private)

    self->IDLgrModel::Add, self._oSymbol

    ; NOTE: the IDLgrPlot and IDLitSymbol properties will be aggregated
    ; as part of the property registration process in an upcoming call
    ; to ::_RegisterProperties.
    self->Add, self._oPlot

    self._fillColor = [128b,128b,128b]
    self._fillTransparency = 0
    self._fillLevel = 1d-300

    self->SetAxesStyleRequest, 2 ; Request box style axes by default.

   ; cap size of 1 covers approx. 10 % of the data range
    self._capSize = 0.2d ; reasonble default value

    ; Our own selection visual.
    oSelectionVisual = OBJ_NEW('IDLitManipVisSelect', /HIDE)
    ; Add a shadow plot. We will set the rest of the properties
    ; in _UpdateSelectionVisual.
    self._oPlotSelectionVisual = OBJ_NEW('IDLgrPlot', $
        ALPHA_CHANNEL=0.2, /ANTIALIAS, $
        LINESTYLE=0, $
        THICK=6, $
        COLOR=!COLOR.DODGER_BLUE)
    oSelectionVisual->Add, self._oPlotSelectionVisual
    self->SetDefaultSelectionVisual, oSelectionVisual

    ; Register Data Parameters
    self->_RegisterParameters

    ; Register all properties and set property attributes
    self->IDLitVisPlot::_RegisterProperties

    self->SetPropertyAttribute, ['SYMBOL', 'SYM_SIZE', 'SYM_COLOR'], $
      ADVANCED_ONLY=0
      
    ; Defaults.
    self._symIncrement = 1

    ; Set any properties
    if(n_elements(_extra) gt 0)then $
      self->IDLitVisPlot::SetProperty,  _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisPlot::Cleanup
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
;   Obj->[IDLitVisPlot::]Cleanup
;
;-
pro IDLitVisPlot::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oPalette
    OBJ_DESTROY, self._oSymbol
    OBJ_DESTROY, self._oSymbolSpacer

    OBJ_DESTROY, self._oItXErrorBarContainer
    OBJ_DESTROY, self._oXError
    OBJ_DESTROY, self._oXErrorPL
    OBJ_DESTROY, self._oXErrorSym

    OBJ_DESTROY, self._oItYErrorBarContainer
    OBJ_DESTROY, self._oYError
    OBJ_DESTROY, self._oYErrorPL
    OBJ_DESTROY, self._oYErrorSym

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
pro IDLitVisPlot::_RegisterParameters

    compile_opt idl2, hidden

    self->RegisterParameter, 'Y', DESCRIPTION='Y Plot Data', $
        /INPUT, TYPES=['IDLVECTOR'], /OPTARGET

    self->RegisterParameter, 'X', DESCRIPTION='X Plot Data', $
        /INPUT, TYPES=['IDLVECTOR'], /OPTIONAL

    self->RegisterParameter, 'VERTICES', DESCRIPTION='Vertex Data', $
        /INPUT, TYPES=['IDLARRAY2D'], /OPTARGET, /OPTIONAL

    self->RegisterParameter, 'Y ERROR', DESCRIPTION='Y Error Data', $
        /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], /OPTIONAL

    self->RegisterParameter, 'X ERROR', DESCRIPTION='X Error Data', $
        /INPUT, TYPES=['IDLVECTOR', 'IDLARRAY2D'], /OPTIONAL

    self->RegisterParameter, 'PALETTE', DESCRIPTION='RGB Color Table', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTARGET, /OPTIONAL

    self->RegisterParameter, 'VERTEX_COLORS', DESCRIPTION='Vertex Colors', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

end

;----------------------------------------------------------------------------
; IDLitVisPlot::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisPlot::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisPlot::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Aggregate the plot and symbol properties.
        self->Aggregate, self._oPlot
        self->Aggregate, self._oSymbol

        self->RegisterProperty, 'VISUALIZATION_PALETTE', $
            NAME='Vertex color table', $
            USERDEF='Edit color table', $
            DESCRIPTION='Edit RGB Color Table', $
            SENSITIVE=0, /ADVANCED_ONLY

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

        self->RegisterProperty, 'ERRORBAR_COLOR', /COLOR, $
            DESCRIPTION='Error bar color', $
            NAME='Error bar color', $
           /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'ERRORBAR_CAPSIZE', /FLOAT, $
            DESCRIPTION='Length of error bar end cap', $
            NAME='Error bar endcap size', $
            VALID_RANGE=[0, 1, .01d], $
            /HIDE, /ADVANCED_ONLY

        self._oPlot->RegisterProperty, 'FILL_BACKGROUND', /BOOLEAN, $
            DESCRIPTION='Fill background', $
            NAME='Fill background', /ADVANCED_ONLY

        self._oPlot->RegisterProperty, 'FILL_LEVEL', /FLOAT, $
            DESCRIPTION='Fill level', $
            NAME='Fill level', $
            /HIDE, /UNDEFINED, /ADVANCED_ONLY

        self._oPlot->RegisterProperty, 'FILL_COLOR', /COLOR, $
            DESCRIPTION='Fill color', $
            NAME='Fill color', /ADVANCED_ONLY

        ; Override registered property attributes.
        self->SetPropertyAttribute, 'SYM_INCREMENT', HIDE=0

        ; Do not show until Y data is present.
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], /HIDE, /UNDEFINED
    endif

    if (registerAll || (updateFromVersion lt 640)) then begin
        ; TRANSPARENCY became a new property FILL_TRANSPARENCY in IDL64.
        self._oPlot->RegisterProperty, 'FILL_TRANSPARENCY', /INTEGER, $
            NAME='Fill transparency', $
            DESCRIPTION='Fill transparency', $
            VALID_RANGE=[0, 100, 5], /ADVANCED_ONLY
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Plot transparency', $
            DESCRIPTION='Transparency of Plot', $
            VALID_RANGE=[0,100,5]

        ; Use TRANSPARENCY and FILL_TRANSPARENCY properties instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY
    endif

    if (registerAll || (updateFromVersion lt 620)) then begin
        self._oPlot->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value on which to project the plot', /ADVANCED_ONLY
    endif

    if (~registerAll && (updateFromVersion lt 640)) then begin
        ; Usage of TRANSPARENCY property changed from the fill to the plot.
        self->SetPropertyAttribute, 'TRANSPARENCY', $
            NAME='Plot transparency', DESCRIPTION='Transparency of Plot'
        ; PLOT_TRANSPARENCY became a new property TRANSPARENCY in IDL64
        self->RegisterProperty, 'PLOT_TRANSPARENCY', /INTEGER, $
            NAME='Plot transparency', $
            DESCRIPTION='Transparency of Plot', $
            VALID_RANGE=[0,100,5]
        self->SetPropertyAttribute, 'PLOT_TRANSPARENCY', /HIDE
    endif
end

;----------------------------------------------------------------------------
; IDLitVisPlot::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisPlot::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oPlot)) then $
        self._oPlot->GetProperty
    if (OBJ_VALID(self._oSymbol)) then $
        self._oSymbol->GetProperty

    ; Register new properties.
    self->IDLitVisPlot::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request crosshair axes if polar, box axes otherwise.
        self.axesStyleRequest = (self._polar) ? 3 : 2
        ; We used to use the self._min/maxSet value to keep track of
        ; whether min/max_value had been set. Now we just use the
        ; undefined attribute. So reset our min/max value to NaN
        ; if it was never set in the saved file.
        if (~self._maxSet) then begin
            self._oPlot->SetProperty, MAX_VALUE=!values.d_nan
            self->SetPropertyAttribute, 'MAX_VALUE', /UNDEFINED
        endif
        if (~self._minSet) then begin
            self._oPlot->SetProperty, MIN_VALUE=!values.d_nan
            self->SetPropertyAttribute, 'MIN_VALUE', /UNDEFINED
        endif
    endif

    ; In IDL62 we removed the symbol from the selection visual plot.
    if (self.idlitcomponentversion lt 620) then begin
        if (Obj_Valid(self._oPlotSelectionVisual)) then $
          self._oPlotSelectionVisual->SetProperty, SYMBOL=OBJ_NEW()
        OBJ_DESTROY, self._oSymbolSelection
        self->_UpdateSelectionVisual
    endif

end


;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisPlot::Init followed by the word "Get"
;      can be retrieved using IDLitVisPlot::GetProperty.
;
;-
pro IDLitVisPlot::GetProperty, $
    ERRORBAR_CAPSIZE=capSize, $
    ERRORBAR_COLOR=barColor, $
    FILL_BACKGROUND=fillBackground, $
    FILL_COLOR=fillColor, $
    FILL_LEVEL=fillLevel, $
    MIN_VALUE=minValue, $
    MAX_VALUE=maxValue, $
    SYMBOL=symValue, $
    SYM_INCREMENT=symIncrement, $
    FILL_TRANSPARENCY=fillTransparency, $
    PLOT_TRANSPARENCY=plotTransparencyOld, $  ; keep for backwards compat
    TRANSPARENCY=plotTransparency, $
    X_ERRORBARS=xErrorBars, $
    Y_ERRORBARS=yErrorBars, $
    VISUALIZATION_PALETTE=visPalette, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(barColor) then begin
        ; get the color from one of the error bars.
        ; Both X and Y error bars are the same color for now.
        if OBJ_VALID(self._oXError) then $
            self._oXError->GetProperty, COLOR=barColor $
        else $
            barColor = [0b,0b,0b]
    endif

    if ARG_PRESENT(capSize) then begin
        capSize = self._capSize
    endif

    if ARG_PRESENT(fillBackground) then begin
        if OBJ_VALID(self._oFill) then begin
            self._oFill->GetProperty, HIDE=fillHide
            fillBackground = ~fillHide
        endif else $
            fillBackground = 0
    endif

    if ARG_PRESENT(fillColor) then begin
        if OBJ_VALID(self._oFill) then $
            self._oFill->GetProperty, FILL_COLOR=fillColor $
        else $
            fillColor = self._fillColor
    endif

    if ARG_PRESENT(fillLevel) then $
        fillLevel = self._fillLevel

    if ARG_PRESENT(fillTransparency) then begin
        if OBJ_VALID(self._oFill) then $
            self._oFill->GetProperty, TRANSPARENCY=fillTransparency $
        else $
            fillTransparency = self._fillTransparency
    endif

    ; PLOT_TRANSPARENCY became TRANSPARENCY in IDL64.
    ; Keep for backwards compat.
    if ARG_PRESENT(plotTransparencyOld) then begin
        self._oPlot->GetProperty, ALPHA_CHANNEL=alpha
        plotTransparencyOld = 0 > ROUND(100 - alpha * 100) < 100
    endif

    if ARG_PRESENT(plotTransparency) then begin
        self._oPlot->GetProperty, ALPHA_CHANNEL=alpha
        plotTransparency = 0 > ROUND(100 - alpha * 100) < 100
    endif

    if ARG_PRESENT(symIncrement) then $
        symIncrement = self._symIncrement

    ; Handle SYMBOL manually so we don't return the IDLgrSymbol
    ; object by mistake.
    if ARG_PRESENT(symValue) then $
      self._oSymbol->GetProperty, SYMBOL=symValue

    if ARG_PRESENT(xErrorBars) then begin
        if OBJ_VALID(self._oXError) then begin
            self._oXError->GetProperty, HIDE=hide
            xErrorBars = ~hide
        endif else $
            xErrorBars = 1
    endif

    if ARG_PRESENT(yErrorBars) then begin
        if OBJ_VALID(self._oYError) then begin
            self._oYError->GetProperty, HIDE=hide
            yErrorBars = ~hide
        endif else $
            yErrorBars = 1
    endif

    if ARG_PRESENT(visPalette) then begin
        self._oPalette->GetProperty, BLUE_VALUES=blue, $
            GREEN_VALUES=green, RED_VALUES=red
        visPalette = TRANSPOSE([[red], [green], [blue]])
    endif

    if ARG_PRESENT(maxValue) then begin
        ; If logarithmic, never report MAX_VALUE as an exponent.
        self._oPlot->GetProperty, MAX_VALUE=plotMaxValue
        maxValue = (FINITE(plotMaxValue) && (self._yVisLog gt 0)) ? $
            10^plotMaxValue : plotMaxValue
    endif

    if ARG_PRESENT(minValue) then begin
        ; If logarithmic, never report MIN_VALUE as an exponent.
        self._oPlot->GetProperty, MIN_VALUE=plotMinValue
        minValue = (FINITE(plotMinValue) && (self._yVisLog gt 0)) ? $
            10^plotMinValue : plotMinValue
    endif

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisPlot::Init followed by the word "Set"
;      can be set using IDLitVisPlot::SetProperty.
;-
pro IDLitVisPlot::SetProperty, $
    COLOR=color, $
    ERRORBAR_CAPSIZE=capSize, $
    ERRORBAR_COLOR=barColor, $
    FILL_BACKGROUND=fillBackground, $
    FILL_COLOR=fillColor, $
    FILL_LEVEL=fillLevel, $
    HISTOGRAM=histogram, $
    MAX_VALUE=maxValue, $
    MIN_VALUE=minValue, $
    NSUM=nsum, $
    POLAR=polar, $
    SYM_INCREMENT=symIncrement, $
    FILL_TRANSPARENCY=fillTransparency, $
    PLOT_TRANSPARENCY=plotTransparencyOld, $  ; keep for backwards compat
    TRANSPARENCY=plotTransparency, $
    ZVALUE=zvalue, $
    X_ERRORBARS=xErrorBars, $
    Y_ERRORBARS=yErrorBars, $
    X_VIS_LOG=xVisLog, $    ; Property not exposed, internal use only
    Y_VIS_LOG=yVisLog, $    ; Property not exposed, internal use only
    VISUALIZATION_PALETTE=visPalette, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; This routine can be called during object creatation/
    ;; initializing, which can cause issues with properties that
    ;; have about any value (max/min values). Check the initializing property
    self->IDLitComponent::GetProperty, INITIALIZING=isInit

    if (N_ELEMENTS(barColor) gt 0) then begin
        self->_VerifyErrorBars, 0
        self->_VerifyErrorBars, 1
        self._oXError->SetProperty, COLOR=barColor
        self._oYError->SetProperty, COLOR=barColor
        self._oXErrorPL->SetProperty, COLOR=barColor
        self._oYErrorPL->SetProperty, COLOR=barColor
    endif

    if (N_ELEMENTS(capSize) gt 0) then begin
        self->GetPropertyAttribute, 'ERRORBAR_CAPSIZE', $
            VALID_RANGE=validRange
        capSize >= validRange[0]
        capSize <= validRange[1]
        self._capSize = capSize
        self->_UpdateCapSize
    endif

    if (N_ELEMENTS(zvalue) gt 0) then begin
        self._oPlot->SetProperty, USE_ZVALUE=(zvalue ne 0), ZVALUE=zvalue
        self->_UpdateFill
        self->_UpdateSelectionVisual
        ; put the visualization into 3D mode if necessary
        self->Set3D, (zvalue ne 0), /ALWAYS
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (N_ELEMENTS(histogram) gt 0) then begin
        ; Handle this explicitly in order to re-calculate fill.
        self._oPlot->SetProperty, HISTOGRAM=histogram
        ; Need to update our fill and selection visual manually.
        self->_UpdateFill
        self->_UpdateSelectionVisual
    endif

    if (N_ELEMENTS(maxValue) gt 0) then begin
        if (FINITE(maxValue)) then begin
            ; If logarithmic, translate given MAX_VALUE to an exponent.
            plotMaxValue = (self._yVisLog gt 0) ? alog10(maxValue) : maxValue
            self->SetPropertyAttribute, 'MAX_VALUE', UNDEFINED=0
            self._oPlot->SetProperty, MAX_VALUE=plotMaxValue
        endif else begin
            self->SetPropertyAttribute, 'MAX_VALUE', /UNDEFINED
            self._oPlot->SetProperty, MAX_VALUE=maxValue
        endelse
        self->_UpdateFill
        self->_UpdateSelectionVisual
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (N_ELEMENTS(minValue) gt 0) then begin
        if (FINITE(minValue)) then begin
            ; If logarithmic, translate given MIN_VALUE to an exponent.
            plotMinValue = (self._yVisLog gt 0) ? alog10(minValue) : minValue
            self->SetPropertyAttribute, 'MIN_VALUE', UNDEFINED=0
            self._oPlot->SetProperty, MIN_VALUE=plotMinValue
        endif else begin
            self->SetPropertyAttribute, 'MIN_VALUE', /UNDEFINED
            self._oPlot->SetProperty, MIN_VALUE=minValue
        endelse
        self->_UpdateFill
        self->_UpdateSelectionVisual
        self->OnDataChange, self
        self->OnDataComplete, self
    endif


    if (N_ELEMENTS(nsum) gt 0) then begin
        self._oPlot->GetProperty, NSUM=nsumOld
        if (nsum ne nsumOld) then begin
            oDataY = self->GetParameter('Y')
            if ((~OBJ_VALID(oDataY)) || (~oDataY->GetData(ydata))) then $
                return

            ndata = N_ELEMENTS(ydata)
            ; make sure there are at least two points for plot
            ; number to average must be one less than number of points
            nsum = nsum < (ndata-1)

            self._oPlot->SetProperty, NSUM=nsum
            self->_UpdateFill
            self->_UpdateSelectionVisual
            self->OnDataChange, self
            self->OnDataComplete, self
        endif
    endif


    ; POLAR plot.
    if (N_ELEMENTS(polar) gt 0) then begin

        self._polar = KEYWORD_SET(polar)

        self->IDLitVisualization::SetProperty, POLAR=self._polar
        self->OnDataChange, self
        self->OnDataComplete, self

        ; Do not allow polar plots to be filled.
        if (self._polar) then begin
            ; If POLAR has been turned on, we need to cache our old
            ; fill value and turn fill off.
            self->GetProperty, FILL_BACKGROUND=wasFilled
            self._wasFilled = wasFilled

            ; Turn fill off.
            ; Note: this assumes the fill code follows this code block.
            if (wasFilled) then fillBackground = 0

            self->SetPropertyAttribute, $
                'FILL_BACKGROUND', SENSITIVE=0

            ; Request crosshair axes.
            self->SetAxesStyleRequest, 3
        endif else begin
            ; Turn fill back on.
            ; Note: this assumes the fill code follows this code block.
            if (self._wasFilled) then $
                fillBackground = 1
            self->SetPropertyAttribute, $
                'FILL_BACKGROUND', /SENSITIVE

            ; Request box axes.
            self->SetAxesStyleRequest, 2
        endelse

    endif


    ; Fill properties. See if we need to create polygon.
    ; We need to do this regardless of whether POLAR is currently set
    ; or not, because we may need to change the fill props, say
    ; for preferences.
    IF (~OBJ_VALID(self._oFill) && KEYWORD_SET(fillBackground)) THEN BEGIN
      ;; Filled portion.
      self._oFill = OBJ_NEW('IDLitVisPolygon', $
        COLOR=self._fillColor, $
        FILL_COLOR=self._fillColor, $
        IMPACTS_RANGE=0, $
        TRANSPARENCY=self._fillTransparency, $
        /HIDE, /PRIVATE, $
        LINESTYLE=6, $
        /TESSELLATE)
      ;; Add to the beginning so it is in the background.
      ; Force NO_UPDATE so the data range doesn't suddenly change.
      self->Add, self._oFill, POSITION=0, /NO_UPDATE
    ENDIF

    ; Note: This code must follow the POLAR code above, because
    ; we may need to turn on/off FILL_BACKGROUND.
    if (N_ELEMENTS(fillBackground)) then begin
        ; Don't allow FILL_BACKGROUND if POLAR is also set.
        if (self._polar) then $
            fillBackground = 0

        if (OBJ_VALID(self._oFill)) then begin
          self._oFill->GetProperty, HIDE=fillHide
          wasFilled = ~fillHide
        endif else wasFilled = -1

        ; Only tweak this if the value changed.
        if (wasFilled ne KEYWORD_SET(fillBackground)) then begin
        
          if KEYWORD_SET(fillBackground) then begin
              self._oFill->SetProperty, HIDE=0
              self->_UpdateFill
          endif else begin
              IF obj_valid(self._oFill) THEN $
                self._oFill->SetProperty, /HIDE
          endelse
          self->SetPropertyAttribute, $
              ['FILL_COLOR', 'FILL_LEVEL', 'FILL_TRANSPARENCY'], $
              SENSITIVE=KEYWORD_SET(fillBackground), HIDE=0

        endif
    endif

    IF (N_ELEMENTS(fillColor) gt 0) THEN BEGIN
      self._fillColor = fillColor
      IF obj_valid(self._oFill) THEN $
        self._oFill->SetProperty, FILL_COLOR=fillColor
    ENDIF

    if (N_ELEMENTS(fillLevel)) then begin
        self._fillLevel = fillLevel
        ; Start showing the actual value.
        self->SetPropertyAttribute, 'FILL_LEVEL', UNDEFINED=0
        self->_UpdateFill
        ; recompute data range since fill impacts range
        oDataY = self->GetParameter('Y')
        if ((OBJ_VALID(oDataY)) && (oDataY->GetData(ydata))) then begin
            self->OnDataChange, self
            self->OnDataComplete, self
        endif
    endif

    IF (N_ELEMENTS(fillTransparency)) THEN BEGIN
      self._fillTransparency = fillTransparency
      IF obj_valid(self._oFill) THEN $
        self._oFill->SetProperty, TRANSPARENCY=fillTransparency
    ENDIF

    ; PLOT_TRANSPARENCY became TRANSPARENCY in IDL64.
    ; Keep for backwards compat.
    if (N_ELEMENTS(plotTransparencyOld)) then $
        plotTransparency = plotTransparencyOld

    if (N_ELEMENTS(plotTransparency)) then begin
        self._oPlot->GetProperty, ALPHA_CHANNEL=alpha
        plotTransparencyOrig = 0 > ROUND(100 - alpha * 100) < 100
        self._oSymbol->GetProperty, SYM_TRANSPARENCY=symTrans
        self._oPlot->SetProperty, $
            ALPHA_CHANNEL=0 > ((100. - plotTransparency)/100) < 1
        if (plotTransparencyOrig eq symTrans) then $
          self._oSymbol->SetProperty, SYM_TRANSPARENCY=plotTransparency
    endif

    if (N_ELEMENTS(symIncrement) gt 0) then begin
        self._symIncrement = symIncrement
        self->_UpdateSymIncrement
    endif

    if (N_ELEMENTS(xErrorBars) gt 0) then begin
        self->_VerifyErrorBars, 0
        self._oXError->SetProperty, HIDE=~xErrorBars
    endif

    if (N_ELEMENTS(yErrorBars) gt 0) then begin
        self->_VerifyErrorBars, 1
        self._oYError->SetProperty, HIDE=~yErrorBars
    endif

    ; Internal use flag allowing the dataspace to
    ; control the state of the vis data
    if (N_ELEMENTS(xVisLog) gt 0 && xVisLog ne self._xVisLog) then begin
        self._xVisLog = xVisLog
        self._oPlot->GetProperty, DATA=data
        if N_ELEMENTS(data) gt 0 then begin
            newX = (xVisLog gt 0) ? alog10(data[0,*]) : 10^data[0,*]
            self._oPlot->SetProperty, DATAX=newX
        endif
        self->_UpdateErrorBars, 0
        self->_UpdateErrorBars, 1
    endif

    ; Internal use flag allowing the dataspace to
    ; control the state of the vis data
    if (N_ELEMENTS(yVisLog) gt 0 && yVisLog ne self._yVisLog) then begin
        self._yVisLog = yVisLog
        self._oPlot->GetProperty, DATA=data, MIN_VALUE=oldMinVal, $
            MAX_VALUE=oldMaxVal
        if N_ELEMENTS(data) gt 0 then begin
            newY = (yVisLog gt 0) ? alog10(data[1,*]) : 10^data[1,*]
            minn = MIN(newY, MAX=maxx)
            ; If the MIN/MAX_VALUEs are not being explicitly set in
            ; this same call, then apply log to min/max values, too.
            if (FINITE(oldMinVal) && (N_ELEMENTS(minValue) eq 0)) then $
                newMinValue = (yVisLog gt 0) ? alog10(oldMinVal) : $
                    10^oldMinVal
            if (FINITE(oldMaxVal) && (N_ELEMENTS(maxValue) eq 0)) then $
                newMaxValue = (yVisLog gt 0) ? alog10(oldMaxVal) : $
                    10^oldMaxVal
            self._oPlot->SetProperty, DATAY=newY, $
                MIN_VALUE=newMinValue, MAX_VALUE=newMaxValue
        endif
        self->_UpdateErrorBars, 0
        self->_UpdateErrorBars, 1
    endif

    if (N_ELEMENTS(visPalette) gt 0) then begin
        self._oPalette->SetProperty, BLUE_VALUES=visPalette[2,*], $
            GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
        oDataRGB = self->GetParameter('PALETTE')
        if OBJ_VALID(oDataRGB) then $
            success = oDataRGB->SetData(visPalette)
    endif

    if ISA(color) then begin
      ; If COLOR is set, and error bar color matches the current line
      ; color, then also set the error bar color.
      if OBJ_VALID(self._oXError) then begin
        self._oPlot->GetProperty, COLOR=oldColor
        self._oXError->GetProperty, COLOR=barColor
        if ARRAY_EQUAL(oldColor, barColor) then begin
          self._oXError->SetProperty, COLOR=color
          self._oYError->SetProperty, COLOR=color
          self._oXErrorPL->SetProperty, COLOR=color
          self._oYErrorPL->SetProperty, COLOR=color
        endif
      endif
      self->IDLitVisualization::SetProperty, COLOR=color
    endif

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitVisualization::SetProperty, _EXTRA=_extra
    endif


end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data from the grPlot
;
; Arguments:
;   X, Y, and Z, although not necessarily in that order
;
; Keywords:
;   NONE
;
pro IDLitVisPlot::GetData, arg1, arg2, arg3, _EXTRA=_extra
  compile_opt idl2, hidden
  
  self._oPlot->GetProperty, DATA=data
  if (N_ELEMENTS(data) lt 3) then return
  
  switch (N_PARAMS()) of
    3 : arg3 = data[2,*]
    2 : begin
      arg1 = data[0,*]
      arg2 = data[1,*]
      break
    end
    1 : arg1 = data[1,*]
    else :
  endswitch
    
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   X, Y, and Z, although not necessarily in that order
;
; Keywords:
;   NONE
;
pro IDLitVisPlot::PutData, arg1, arg2, arg3, _EXTRA=_extra
  compile_opt idl2, hidden
  
  RESOLVE_ROUTINE, 'iPlot', /NO_RECOMPILE

  case (N_Params()) of
    0: void = iPlot_GetParmSet(oParmSet, _EXTRA=_extra)
    1: void = iPlot_GetParmSet(oParmSet, arg1, _EXTRA=_extra)
    2: void = iPlot_GetParmSet(oParmSet, arg1, arg2, _EXTRA=_extra)
    3: void = iPlot_GetParmSet(oParmSet, arg1, arg2, arg3, _EXTRA=_extra)
  endcase

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
function IDLitVisPlot::EditUserDefProperty, oTool, identifier

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
;      IDLitVisPlot::_UpdateSelectionVisual
;
; PURPOSE:
;      This procedure method updates the selection visual based
;      on the plot data.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateSelectionVisual
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot::_UpdateSelectionVisual

    compile_opt idl2, hidden

    ; Shadow plot.

    ; Retrieve all properties necessary to recreate the shadow plot.
    self._oPlot->GetProperty, DATA=data, $
        DOUBLE=double, $
        HISTOGRAM=histogram, $
        MIN_VALUE=minv, MAX_VALUE=maxv, $
        NSUM=nsum, $
        POLAR=polar, $
        XRANGE=xr, YRANGE=yr, $
        ZVALUE=zvalue

    ; Make sure we have data to share.
    ndata = N_ELEMENTS(data)
    if (ndata eq 0) then $
        return

    self._oPlotSelectionVisual->SetProperty, $
        DOUBLE=double, $
        HISTOGRAM=histogram, $
        MIN_VALUE=minv, MAX_VALUE=maxv, $
        NSUM=nsum, $
        POLAR=polar, $
        SHARE_DATA=self._oPlot, $
        XRANGE=xr, YRANGE=yr, $
        USE_ZVALUE=(zvalue ne 0), ZVALUE=zvalue

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::_VerifyErrorBars, dim
;
; PURPOSE:
;      This procedure method creates the error bar container
;      and visualizations.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_VerifyErrorBars
;
; INPUTS:
;      dim: 0 for X, 1 for Y
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot::_VerifyErrorBars, dim

    compile_opt idl2, hidden

    oErrorContainer = dim ? $
        self._oItYErrorBarContainer : self._oItXErrorBarContainer

    if (OBJ_VALID(oErrorContainer)) then $
        return

    oErrorContainer = OBJ_NEW('_IDLitVisualization', $
        IMPACTS_RANGE=0, $
        SELECT_TARGET=0, $
        /PRIVATE)
    self->Add, oErrorContainer

    data = dim ? [[-0.5,0],[0.5,0]] : [[0,-0.5],[0,0.5]]
    oErrorPL = OBJ_NEW('IDLgrPolyline', DATA=data)
    oErrorSym = OBJ_NEW('IDLgrSymbol', DATA=oErrorPL)
    oError = OBJ_NEW('IDLgrPolyline', SYMBOL=[oErrorSym])
    oErrorContainer->Add, oError

    if (dim) then begin
        self._oItYErrorBarContainer = oErrorContainer
        self._oYErrorPL = oErrorPL
        self._oYErrorSym = oErrorSym
        self._oYError = oError
    endif else begin
        self._oItXErrorBarContainer = oErrorContainer
        self._oXErrorPL = oErrorPL
        self._oXErrorSym = oErrorSym
        self._oXError = oError
    endelse

end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot::_UpdateErrorBars, data, dim
;
; PURPOSE:
;      This procedure method updates the error bar geometry based
;      on the plot data.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateErrorBars
;
; INPUTS:
;      data: A vector of plot data.
;      dim: 0 for X, 1 for Y
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisPlot::_UpdateErrorBars, dim

    compile_opt idl2, hidden

    oErrData = self->GetParameter((dim ? 'Y' : 'X') + ' ERROR')
    if (~OBJ_VALID(oErrData)) then $
        return
    if (~oErrData->GetData(errdata)) then $
        return

    ; Retrieve X and Y data.
    oDataY = self->GetParameter('Y')
    if (~OBJ_VALID(oDataY) || ~oDataY->GetData(ydata)) then $
        return

    self._oPlot->GetProperty, DOUBLE=isDouble

    ndata = N_ELEMENTS(ydata)

    oDataX = self->GetParameter('X')
    ; Construct a findgen X vector if necessary.
    if (~OBJ_VALID(oDataX) || ~oDataX->GetData(xdata) || $
        (N_ELEMENTS(xdata) ne ndata)) then $
        xdata = isDouble ? DINDGEN(ndata) : FINDGEN(ndata)

    self->_VerifyErrorBars, dim

    ErrorData = isDouble ? DBLARR(2, 2*ndata) : FLTARR(2, 2*ndata)

    ; set the other dimension's coordinates of polyline data
    ; same coordinate for both values of the specified dimension
    ErrorData[~dim, 0:*:2] = dim ? xdata : ydata
    ErrorData[~dim, 1:*:2] = dim ? xdata : ydata

    case size(errdata, /n_dimensions) of
    1: begin
        ; vector of error values applied as both + and - error
        ErrorData[dim, 0:*:2] = (dim ? ydata : xdata) - errdata
        ErrorData[dim, 1:*:2] = (dim ? ydata : xdata) + errdata
    end
    2: begin
        ; 2xN array, [0,*] is negative error, [1,*] is positive error
        ErrorData[dim, 0:*:2] = (dim ? ydata : xdata) - errdata[0,*]
        ErrorData[dim, 1:*:2] = (dim ? ydata : xdata) + errdata[1,*]
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

    polylineDescript = LONARR(3*ndata)
    polylineDescript[0:*:3] = 2
    polylineDescript[1:*:3] = lindgen(ndata)*2
    polylineDescript[2:*:3] = lindgen(ndata)*2+1

    ;; filter out non-finite values
    infY = where(~finite(ErrorData[1,0:*:2]))
    IF (infY[0] NE -1) THEN BEGIN
      ;; determine a valid data point to set the unneeded error bar
      ;; data.  This has to be done as the error bar data impacts the
      ;; range so using a generic value like 0 or 1d300 could change
      ;; the plot range
      validY = where(finite(ydata))
      validY = (validY[0] EQ -1) ? 0 : ydata[validY[0]]
      ErrorData[1,where(~finite(ErrorData[1,*]))] = validY
      nInf = n_elements(infY)
      polylineDescript[reform(infY*3##replicate(1,3),3*nInf)+ $
                       reform([0,1,2]#replicate(1,nInf),3*nInf)] = 0
    ENDIF
    infX = where(~finite(ErrorData[0,0:*:2]))
    IF (infX[0] NE -1) THEN BEGIN
      ;; determine a valid data point to set the unneeded error bar
      ;; data.  This has to be done as the error bar data impacts the
      ;; range so using a generic value like 0 or 1d300 could change
      ;; the plot range
      validX = where(finite(xdata))
      validX = (validX[0] EQ -1) ? 0 : xdata[validX[0]]
      ErrorData[0,where(~finite(ErrorData[0,*]))] = validX
      nInf = n_elements(infX)
      polylineDescript[reform(infX*3##replicate(1,3),3*nInf)+ $
                       reform([0,1,2]#replicate(1,nInf),3*nInf)] = 0
    ENDIF

    oError = dim ? self._oYerror : self._oXerror

    ; We save an extra copy of the polylines in the UVALUE,
    ; for use in clipping to the plot range.
    ; Retrieve HIDE property - it may be specified on command line
    ; and set prior to processing of the parameter
    oError->GetProperty, HIDE=hide
    oError->SetProperty, DATA=temporary(ErrorData), $
        HIDE=hide, $   ; may be hid from dataDisconnect
        POLYLINES=polylineDescript, UVALUE=polylineDescript

    oErrorContainer = dim ? $
        self._oItYErrorBarContainer : self._oItXErrorBarContainer
    oErrorContainer->SetProperty, /IMPACTS_RANGE

    ; display the properties, even if the error bars themselves are hidden
    self->SetPropertyAttribute, [(dim ? 'Y' : 'X') + '_ERRORBARS', $
        'ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], HIDE=0

    self->_UpdateCapSize

end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot::_UpdateCapSize
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
pro IDLitVisPlot::_UpdateCapSize

    compile_opt idl2, hidden

    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        success = oDataSpace->GetXYZRange(xRange, yRange, zRange)
        if (success) then begin
            if (OBJ_VALID(self._oXErrorSym)) then $
                self._oXErrorSym->SetProperty, $
                    SIZE=self._capSize*(yRange[1]-yRange[0])/10.0

            if (OBJ_VALID(self._oYErrorSym)) then $
                self._oYErrorSym->SetProperty, $
                    SIZE=self._capSize*(xRange[1]-xRange[0])/10.0

        endif
    endif
end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot::_UpdateSymIncrement
;
; PURPOSE:
;      This procedure method updates the plot, spacing
;      symbols at the desired symbol increment.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateSymIncrement
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisPlot::_UpdateSymIncrement

    compile_opt idl2, hidden

    oSymArray = [self._oSymbol->GetSymbol()]

    ; Symbol increment of 1 means every point, don't insert spacer
    if (self._symIncrement gt 1) then begin
        oSymArray = [oSymArray, $
            REPLICATE(self._oSymbolSpacer, self._symIncrement-1)]
    endif

    self._oPlot->SetProperty, SYMBOL=oSymArray

    self->_UpdateSelectionVisual
end


;----------------------------------------------------------------------------
; METHODNAME:
;      IDLitVisPlot::_UpdateSymSize
;
; PURPOSE:
;      This procedure method updates the symbol size
;      to the dataspace range by retrieving and then
;      setting the symbol size.  The IDLitSymbol object
;      scales the symbol to the dataspace when the size
;      is set.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateSymSize
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;
pro IDLitVisPlot::_UpdateSymSize

    compile_opt idl2, hidden

    ; Setting the symbol size causes internal scaling to the data range
    ; Retrieve it's normalized value, and reset it to the same value
    ; to trigger the internal scaling.
    self._oSymbol->GetProperty, SYM_SIZE=symSize
    self._oSymbol->SetProperty, SYM_SIZE=symSize

end


;----------------------------------------------------------------------------
; Purpose:
;   Perform any X clipping needed on the fill polygon.
;
; Result:
;   Returns the number of data points that are in the clipped plot.
;
function IDLitVisPlot::_FillClipX, xrange, xdata, data, $
    HISTOGRAM=doHist

    compile_opt idl2, hidden

    good = WHERE((xdata ge xrange[0]) and (xdata le xrange[1]), ngood)

    if (ngood eq 0) then begin   ; Clip everything
        ; Remove all the data if no points are valid.
        data = 0
        ; Setting the fill to a scalar will cause it to be hidden.
        self._oFill->SetProperty, DATA=0
        return, 0   ; no data points survived
    endif

    ndata = N_ELEMENTS(data)

    if (ngood eq ndata) then $
        return, ndata   ; Nothing to clip

    clipLeft = good[0] gt 0
    clipRight = good[ngood-1] lt (ndata-1)

    ; Save the first points off the edges.
    if (clipLeft) then $
        ptOff1 = [xdata[good[0]-1], data[good[0]-1]]
    if (clipRight) then $
        ptOff2 = [xdata[good[ngood-1]+1], data[good[ngood-1]+1]]

    xdata = xdata[good]
    data = data[good]
    ndata = ngood

    if (clipLeft) then begin
        clipFraction = DOUBLE(xdata[0] - xrange[0])/(xdata[0] - ptOff1[0])
        ; Make sure we didn't exactly hit the edge point.
        if (clipFraction gt 0) then begin
            ; Add another data point, interpolated to the edge point.
            xdata = [xrange[0], xdata]
;            newY = KEYWORD_SET(doHist) ? $
;                ((clipFraction gt 0.5) ? ptOff1[1] : data[0]) : $
;                clipFraction*(ptOff1[1] - data[0]) + data[0]
            newY = clipFraction*(ptOff1[1] - data[0]) + data[0]
            data = [newY, data]
            ndata++
        endif
    endif

    if (clipRight) then begin
        clipFraction = DOUBLE(xrange[1] - xdata[ndata-1])/ $
            (ptOff2[0] - xdata[ndata-1])
        ; Make sure we didn't exactly hit the edge point.
        if (clipFraction gt 0) then begin
            ; Add another data point, interpolated to the edge point.
            xdata = [xdata, xrange[1]]
;            newY = KEYWORD_SET(doHist) ? $
;                ((clipFraction gt 0.5) ? ptOff2[1] : data[ndata-1]) : $
;                clipFraction*(ptOff2[1] - data[ndata-1]) + data[ndata-1]
                newY = clipFraction*(ptOff2[1] - data[ndata-1]) + data[ndata-1]
            data = [data, newY]
            ndata++
        endif
    endif

    return, ndata

end


;----------------------------------------------------------------------------
; Purpose:
;   Perform any Y clipping needed on the fill polygon.
;
; Result:
;   Returns the number of data points that are in the clipped plot.
;
function IDLitVisPlot::_FillClipY, yrange, xdata, data

    compile_opt idl2, hidden

    isGood = (data ge yrange[0]) and (data le yrange[1])
    good = WHERE(isGood, ngood, $
        COMPLEMENT=bad, NCOMPLEMENT=nbad)

    ndata = N_ELEMENTS(data)

    if (ngood eq ndata) then $
        return, ndata   ; Nothing to clip

    self._oPlot->GetProperty, DOUBLE=isDouble

    offTop = data gt yrange[1]
    nguess = ngood + 2*nbad
    yClip = isDouble ? DBLARR(nguess) : FLTARR(nguess)
    xClip = isDouble ? DBLARR(nguess) : FLTARR(nguess)
    j = 0
    for i=0,ndata-1 do begin
        if (isGood[i]) then begin
            xClip[j] = xdata[i]
            yClip[j] = data[i]
            j++
            continue
        endif

        if (i eq 0) then begin
            xClip[j] = xdata[0]
            yClip[j] = yrange[offTop[i]]
            j++
        endif else begin
            dy = (data[i] - data[i-1])
            clipFraction = (~dy) ? 1 : (yrange[offTop[i]] - data[i-1])/dy
            xClip[j] = xdata[i-1] > (xdata[i-1] + clipFraction*(xdata[i] - xdata[i-1])) < xdata[i]
            yClip[j] = yrange[offTop[i]]
            j++
        endelse

        if (i eq (ndata-1)) then begin
            xClip[j] = xdata[i]
            yClip[j] = yrange[offTop[i]]
            j++
        endif else begin
            dy = (data[i] - data[i+1])
            clipFraction = (~dy) ? 1 : (yrange[offTop[i]] - data[i+1])/dy
            xClip[j] = xdata[i] > (xdata[i+1] + clipFraction*(xdata[i] - xdata[i+1])) < xdata[i+1]
            yClip[j] = yrange[offTop[i]]
            j++
        endelse
    endfor

    xdata = xClip[0:j-1]
    data = yClip[0:j-1]

    return, j

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::_UpdateFill
;
; PURPOSE:
;      This procedure method updates the polygon representing
;      the filled area under the plot.  It must be updated when
;      the fill level (the lower boundary) changes or when going
;      into or out of histogram mode, for example.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisPlot::]_UpdateFill
;
; INPUTS:
;      DataspaceX/Yrange: Optional args giving the dataspace ranges.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot::_UpdateFill, $
    dataspaceXrange, dataspaceYrange, dataspaceZrange

    compile_opt idl2, hidden

    ; Don't bother to update if we havn't turned on filling.
    if (~OBJ_VALID(self._oFill)) then $
        return

    ; Retrieve X and Y data.
    oDataY = self->GetParameter('Y')
    if ((~OBJ_VALID(oDataY)) || (~oDataY->GetData(ydata))) then $
        return

    ndata = N_ELEMENTS(ydata)

    oDataX = self->GetParameter('X')
    ; Construct a findgen X vector if necessary.
    if ((~OBJ_VALID(oDataX)) || (~oDataX->GetData(xdata)) || $
        (N_ELEMENTS(xdata) ne ndata)) then $
        xdata = FINDGEN(ndata)

    self._oPlot->GetProperty, $
        DOUBLE=isDouble, $
        HISTOGRAM=doHist, $
        MIN_VALUE=minValue, $
        MAX_VALUE=maxValue, $
        NSUM=nsum, $
        XRANGE=xrange, YRANGE=yrange


    ; Check if we need to average points together.
    if (nsum gt 1) then begin

        ; If nsum is >= to the # of points, bail.
        if (nsum ge ndata) then begin
            ; Setting the fill to a scalar will cause it to be hidden.
            self._oFill->SetProperty, DATA=0
            return   ; we're done
        endif

        xdata = isDouble ? DOUBLE(xdata) : FLOAT(xdata)
        ydata = isDouble ? DOUBLE(ydata) : FLOAT(ydata)

        ; Remove degen dimensions for REBIN
        xdata = REFORM(xdata, /OVERWRITE)
        ydata = REFORM(ydata, /OVERWRITE)

        if ((ndata mod nsum) eq 0) then begin
            xdata = REBIN(xdata, (ndata + nsum - 1)/nsum)
            ydata = REBIN(ydata, (ndata + nsum - 1)/nsum)
        endif else begin
            nint = (ndata/nsum)*nsum
            xdata = [REBIN(xdata[0:nint-1], ndata/nsum), $
                TOTAL(xdata[nint:*])/(ndata-nint)]
            ydata = [REBIN(ydata[0:nint-1], ndata/nsum), $
                TOTAL(ydata[nint:*])/(ndata-nint)]
        endelse

        ; New number of data values.
        ndata = N_ELEMENTS(ydata)
    endif


    ; Create default FILL_LEVEL if necessary.
    ; We use a tiny number as a flag to indicate it is currently undefined.
    if (self._fillLevel eq 1d-300) then begin
        self._fillLevel = MIN(ydata)
        ; Start showing the actual value.
        self->SetPropertyAttribute, 'FILL_LEVEL', UNDEFINED=0
    endif


    ; For a histogram style, duplicate the X and Y points.
    if (doHist) then begin

        ; Duplicate the X points, but subtract/add an offset
        ; equal to half the distance between neighboring points.
        dx = (ndata gt 1) ? (xdata[1:*] - xdata[0:ndata-2])/2d : 1
        dx = [0, dx, 0]
        xdata1 = isDouble ? DBLARR(2*ndata) : FLTARR(2*ndata)
        xdata1[0:*:2] = xdata - dx[0:ndata-1]
        xdata1[1:*:2] = xdata + dx[1:*]
        xdata = TEMPORARY(xdata1)

        ; Duplicate all of the y data.
        ydata = REFORM(REBIN(REFORM(ydata, 1, ndata), 2, ndata), 2*ndata)

    endif

    fillLevel = self._fillLevel

    ; Convert data to logarithmic if necessary.
    if (self._xVisLog) then begin
        xdata = alog10(xdata)
    endif
    if (self._yVisLog) then begin
        ydata = alog10(ydata)
        fillLevel = alog10(fillLevel)
    endif

    ; Clip the yrange at the min/max value. This isn't perfect,
    ; because it still shows the fill in regions where the data has all
    ; been set to NaN.
    if (FINITE(minValue)) then $
        yrange[0] >= minValue
    if (FINITE(maxValue)) then $
        yrange[1] <= maxValue

    ; Restrict fill level to be within dataspace range.
    if (N_ELEMENTS(dataspaceYrange) ne 2) then begin
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, Y_AUTO_UPDATE=yAutoUpdate, $
                Y_MINIMUM=yMin, Y_MAXIMUM=yMax
            ; If y_auto_update is false then our fill needs
            ; to match the dataspace. If y_auto_update is true then
            ; because impacts_range=1 for our fill, the dataspace
            ; y range should change to match our fill range.
            dataspaceYrange = [yMin, yMax]
        endif
    endif

    if (N_ELEMENTS(dataspaceYrange) eq 2) then begin
        fillLevel = dataspaceYrange[0] > fillLevel < dataspaceYrange[1]
    endif

    ndata = self->_FillClipX(xrange, xdata, ydata, HISTOGRAM=doHist)

    if (ndata gt 1) then $
        ndata = self->_FillClipY(yrange, xdata, ydata)

    ; If no points survived the clipping, bail early.
    if (ndata eq 0) then begin   ; Clip everything
        ; Setting the fill to a scalar will cause it to be hidden.
        self._oFill->SetProperty, DATA=0
        return   ; we're done
    endif


    ; Construct our (2xN) data array.
    self._oPlot->GetProperty, ZVALUE=zvalue
    useZvalue = (zvalue ne 0)

    filldata = isDouble ? DBLARR(2+useZvalue, ndata + 3) : $
        FLTARR(2+useZvalue, ndata + 3)

    ; Fill in all the data points.
    filldata[0,1:ndata] = xdata
    filldata[1,1:ndata] = ydata

    ; Fill in the first and last points.
    filldata[0:1,0] = [xdata[0], fillLevel]
    filldata[0:1,ndata+1] = [xdata[ndata-1], fillLevel]
    filldata[0:1,ndata+2] = [xdata[0], fillLevel]

    if (useZvalue) then $
        filldata[2,*] = zvalue

    self._oFill->SetProperty, DATA=filldata

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;; IDLitVisPlot::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the plot.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLitVisPlot::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   ;; Just check the name and perform the desired action
   case ParmName of
       'X': begin
           self._oPlot->GetProperty, data=data
           szDims = size(data,/dimensions)
           data=0b
           self._oPlot->SetProperty, datax=indgen(szDims[1])
           self->_UpdateSelectionVisual
       end
       'Y': begin
           self._oPlot->SetProperty, datax=[0,1], datay=[0,1], $
                MIN_VALUE=!values.d_nan, MAX_VALUE=!values.d_nan
           self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], /UNDEFINED
           self->_UpdateSelectionVisual
           self._oPlot->SetProperty, /HIDE
       end
       'X ERROR': begin
           ; hide the error bars and their properties
           self._oXError->Setproperty, /HIDE
           self->SetPropertyAttribute, 'X_ERRORBARS', /HIDE
           self->GetPropertyAttribute, 'Y_ERRORBARS', HIDE=hideY
           if (hideY) then begin
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
           if (hideX) then begin
           self->SetPropertyAttribute, $
               ['ERRORBAR_CAPSIZE', 'ERRORBAR_COLOR'], /HIDE
           endif

           ; recompute data range to eliminate effect of errorbars
           self._oItYErrorBarContainer->SetProperty, IMPACTS_RANGE=0
           self->OnDataChange, self
           self->OnDataComplete, self
       end
       'VERTEX_COLORS':begin
           self._oPlot->SetProperty, VERT_COLORS=0
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

    ; Since we are changing a bunch of attributes, notify
    ; our observers in case the prop sheet is visible.
    self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
; METHODNAME:
;    IDLitVisPlot::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the
;    subject and updates the internal IDLgrPlot object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisPlot::]OnDataChangeUpdate, oSubject, parmName
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the plot) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then it puts the data in the IDLgrPlot object.
;
;    parmName: The name of the registered parameter.
;
; KEYWORDS:
;   NO_UPDATE: Undocumented keyword to suppress updates when adding
;       multiple data objects within a parameter set.
;
pro IDLitVisPlot::OnDataChangeUpdate, oSubject, parmName, $
    NO_UPDATE=noUpdate

    compile_opt idl2, hidden

    case strupcase(parmName) of
    '<PARAMETER SET>':begin
        ;; Get our data
        position = oSubject->Get(/ALL, count=nCount, NAME=name)
        for i=0, nCount-1 do begin
            if (name[i] eq '') then $
                continue
            oData = (oSubject->GetByName(name[i]))[0]
            if (~OBJ_VALID(oData)) then $
                continue
            if (oData->GetData(data, NAN=nan) le 0) then $
                continue

            case name[i] of

            'Y': begin
                self->IDLitVisPlot::OnDataChangeUpdate, oData, 'Y', /NO_UPDATE

                oData = oSubject->GetByName('X')
                if (OBJ_VALID(oData)) then begin
                    self->IDLitVisPlot::OnDataChangeUpdate, oData, 'X', /NO_UPDATE
                endif

                self->_UpdateFill
                self->_UpdateSymSize        ; handle the case for an overplot with no range change

            end

            'X':  ; X is handled in the Y branch to control order

            ; Pass all other parameters on to ourself.
            else: self->IDLitVisPlot::OnDataChangeUpdate, oData, name[i]

            endcase

        endfor
        end

    'X': BEGIN
        if (~oSubject->GetData(data)) then $
            break
        ;; Retrieve the range of the plot data in case dataspace does
        ;; not exist
        void = self._oPlot->GetDataXYZRange(xRange, yRange, zRange)
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, $
                                     XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange
            if (xLog gt 0) then $
                data=alog10(data)
        endif
        self._oPlot->SetProperty, DATAX=data
        if (~KEYWORD_SET(noUpdate)) then begin
          ;; Call OnDataChangeUpdate to update the visual stuff
          self->OnDataRangeChange, self, xRange, yRange, zRange
        endif
    END

    'Y': BEGIN
        if (~oSubject->GetData(data, NAN=nan)) then $
            break
        ;; Retrieve the range of the plot data in case dataspace does
        ;; not exist
        void = self._oPlot->GetDataXYZRange(xRange, yRange, zRange)
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, $
                                     XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange
            if (yLog gt 0) then $
                data=alog10(data)
        endif
        self._oPlot->SetProperty, DATAY=data, HIDE=0
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], HIDE=0
        if (~KEYWORD_SET(noUpdate)) then begin
          ;; Call OnDataChangeUpdate to update the visual stuff
          self->OnDataRangeChange, self, xRange, yRange, zRange
        endif
    END

    'VERTICES': BEGIN
        if (~oSubject->GetData(data)) then $
            break
        ; Sanity check.
        if ((SIZE(data, /DIM))[0] gt 3) then $
            break
        ;; Retrieve the range of the plot data in case dataspace does
        ;; not exist
        void = self._oPlot->GetDataXYZRange(xRange, yRange, zRange)
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then $
            oDataSpace->GetProperty, XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange
        self._oPlot->SetProperty, DATAY=data[1,*]
        self._oPlot->SetProperty, DATAX=data[0,*]
        if (~KEYWORD_SET(noUpdate)) then begin
          ;; Call OnDataChangeUpdate to update the visual stuff
          self->OnDataRangeChange, self, xRange, yRange, zRange
        endif
    END

    'X ERROR': self->_UpdateErrorBars, 0

    'Y ERROR': self->_UpdateErrorBars, 1

    'PALETTE': begin
        if (~oSubject->GetData(data)) then $
            break
        ; Sanity check.
        if ((SIZE(data, /DIM))[0] gt 3) then $
            break
        if (size(data, /TYPE) ne 1) then data=bytscl(temporary(data))
        self._oPalette->SetProperty, $
            RED_VALUES=data[0,*], $
            GREEN_VALUES=data[1,*], $
            BLUE_VALUES=data[2,*]
        self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', /SENSITIVE
        oVertColors = self->GetParameter('VERTEX_COLORS')
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
        end

    'VERTEX_COLORS': begin
        if (~oSubject->GetData(data)) then $
            break
        if (size(data, /TYPE) ne 1) then data=bytscl(temporary(data))
        self._oPlot->SetProperty, VERT_COLORS=data

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
        end

    else: ; ignore unknown parameters

    endcase


    self->_UpdateSelectionVisual

    ; Since we are changing a bunch of attributes, notify
    ; our observers in case the prop sheet is visible.
    self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::GetSymbol
;
; PURPOSE:
;      This function method returns the symbol associated with
;      the plot.  This allows the legend to retrieve the object
;      reference to obtain symbol properties directly.
;
; CALLING SEQUENCE:
;      oSymbol = Obj->[IDLitVisPlot::]GetSymbol
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
function IDLitVisPlot::GetSymbol

    compile_opt idl2, hidden

    return, self._oSymbol

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::GetDataString
;
; PURPOSE:
;      Convert XY dataspace coordinates into actual data values.
;
; CALLING SEQUENCE:
;      strDataValue = Obj->[IDLitVisPlot::]GetDataString
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
function IDLitVisPlot::GetDataString, xyz

    compile_opt idl2, hidden

    if self._xVisLog then xyz[0] = 10^xyz[0]
    if self._yVisLog then xyz[1] = 10^xyz[1]
    xy = STRCOMPRESS(STRING(xyz[0:1], FORMAT='(G11.4)'))
    return, STRING(xy, FORMAT='("X: ",A,"  Y: ",A)')

end


;----------------------------------------------------------------------------
; IIDLDataRangeObserver Interface
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
; Purpose:
;   Internal routine to clip the error bars to the plot range.
;
pro IDLitVisPlot::_UpdateErrorBarRange, XRange, YRange, ZRange

    compile_opt idl2, hidden

    self._oPlot->GetProperty, DATA=plotData, DOUBLE=double

    for dim=0,1 do begin

        ; See if we have X or Y error bars.
        oError = dim ? self._oYerror : self._oXerror
        if (~OBJ_VALID(oError)) then $
            continue

        ; Retrieve the errorbar initial polylines.
        oError->GetProperty, UVALUE=polylines
        n = N_ELEMENTS(polylines)/3
        if (n eq 0) then $
            continue

        ;; filter out non-finite values
        inf = where(~finite(plotData[0,*]))
        IF (inf[0] NE -1) THEN $
          plotData[0,inf] = XRange[0]-1
        inf = where(~finite(plotData[1,*]))
        IF (inf[0] NE -1) THEN $
          plotData[1,inf] = YRange[0]-1

        ; See if the point is out of bounds in the X or Y direction.
        badX = (plotData[0,*] lt XRange[0]) or (plotData[0,*] gt XRange[1])
        badY = (plotData[1,*] lt YRange[0]) or (plotData[1,*] gt YRange[1])
        bad = WHERE(badX or badY, nbad)

        if (nbad gt 0) then begin
            ; Zero out the connectivity for out-of-range errorbars.
            polylines = REFORM(polylines, 3, n, /OVERWRITE)
            polylines[*,bad] = 0
            polylines = REFORM(polylines, 3*n, /OVERWRITE)
        endif

        oError->SetProperty, POLYLINES=polylines, DOUBLE=double

    endfor

end


;----------------------------------------------------------------------------
; Override this method so we can take the FILL_LEVEL into account.
;
function IDLitVisPlot::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=bDataRange, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    success = self->_IDLitVisualization::GetXYZRange(outxRange, outyRange, outzRange, $
      DATA=bDataRange, NO_TRANSFORM=noTransform)

    ; If our fill level has been set, and fill is turned on, then extend
    ; the Y range to include the fill level if necessary.
    if (success && self._fillLevel ne 1d-300 && ISA(self._oFill)) then begin
      self._oFill->GetProperty, HIDE=fillHide
      if (~fillHide) then begin
        if (self._fillLevel lt outyRange[0]) then outyRange[0] = self._fillLevel $
        else if (self._fillLevel gt outyRange[1]) then outyRange[1] = self._fillLevel
      endif
    endif

    return, success
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisPlot::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
pro IDLitVisPlot::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; Determine if the dataspace range requires double precision.
    ; If so, set the plot data to double precision.
    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        if (oDataSpace->RequiresDouble()) then $
            self._oPlot->SetProperty, /DOUBLE
    endif

    ; Retrieve the range of the plot data (before clipping).
    isok = self._oPlot->GetDataXYZRange(dataXRange, dataYRange, dataZRange)

    dataXRange[0] = dataXRange[0] > xrange[0]
    dataXRange[1] = dataXRange[1] < xrange[1]
    dataYRange[0] = dataYRange[0] > yrange[0]
    dataYRange[1] = dataYRange[1] < yrange[1]

    self._oPlot->SetProperty, XRANGE=dataXRange, YRANGE=dataYRange

    self->_UpdateSymSize

    self->_UpdateCapSize

    self->_UpdateSelectionVisual

    self->_UpdateFill, XRange, YRange, ZRange

    self->_UpdateErrorBarRange, XRange, YRange, ZRange

end


;----------------------------------------------------------------------------
; METHODNAME:
;   IDLitVisPlot::GetHitVisualization
;
; PURPOSE:
;   Overrides the default method, and always returns myself. Therefore, if
;   you click on the filled portion, you get the plot instead.
;
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisPlot::GetHitVisualization
;
; PURPOSE:
;      This procedure method overrides the default method, and
;      always returns the self object reference. Therefore, if
;      a click occurs on the filled portion, you get the plot.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisPlot::]GetHitVisualization, oSubHitList
;
; INPUTS:
;      oSubHitList:  A reference to the object hit
;
; OUTPUTS:
;      There are no outputs for this method.
;
; KEYWORD PARAMETERS:
;      There are no keywords for this method.
;-
;----------------------------------------------------------------------------
function IDLitVisPlot::GetHitVisualization, oSubHitList
    compile_opt idl2, hidden
    return, self
end


;----------------------------------------------------------------------------
; Purpose:
;   Override the superclass' method. We keep our selection visual in sync
;   with our visualization using SetProperty, so we don't need to
;   do any updates here.
;
pro IDLitVisPlot::UpdateSelectionVisual
    compile_opt idl2, hidden
    ; Do nothing.
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisPlot__Define
;
; PURPOSE:
;      Defines the object structure for an IDLitVisPlot object.
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
pro IDLitVisPlot__Define

    compile_opt idl2, hidden

    struct = { IDLitVisPlot,           $
        inherits IDLitVisualization, $   ; Superclass: _IDLitVisualization
        _oPlot: OBJ_NEW(),          $   ; IDLgrPlot object
        _oPlotSelectionVisual: OBJ_NEW(),          $   ; IDLgrPlot object
        _oPalette: OBJ_NEW(), $
        _oSymbol: OBJ_NEW(),    $
        _oSymbolSelection: OBJ_NEW(),    $  ; left in for IDL61 BC
        _oSymbolSpacer: OBJ_NEW(),    $
        _oItXErrorBarContainer: OBJ_NEW(),    $
        _oXErrorPL: OBJ_NEW(),    $
        _oXErrorSym: OBJ_NEW(),    $
        _oXError: OBJ_NEW(),    $
        _oItYErrorBarContainer: OBJ_NEW(),    $
        _oYErrorPL: OBJ_NEW(),    $
        _oYErrorSym: OBJ_NEW(),    $
        _oYError: OBJ_NEW(),    $
        _oFill: OBJ_NEW(), $
        _xVisLog: 0L,  $
        _yVisLog: 0L,  $
        _symIncrement: 1L,  $ ;default is 1 for every vertex
        _capSize: 0d,   $
        _maxSet: 0b,   $   ; needed for IDL60 backwards compat
        _minSet: 0b,   $   ; needed for IDL60 backwards compat
        _polar: 0b, $
        _wasFilled: 0b, $
        _fillColor: bytarr(3), $
        _fillTransparency: 0, $
        _fillLevel: 0.0d $
    }
end

