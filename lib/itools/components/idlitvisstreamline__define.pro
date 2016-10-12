; $Id: IDLitVisStreamline__define.pro,v 1.15 2005/01/19 18:46:37 chris Exp $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   This class is the component for streamline visualization.
;
;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Syntax:
;
;    Obj = OBJ_NEW('IDLitVisStreamline')
;
; Result:
;   This function method returns 1 on success, or 0 on failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitVisStreamline::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses
    if (~self->IDLitVisualization::Init(TYPE="IDLVISSTREAMLINE", $
        ICON='fitwindow', $
        DESCRIPTION="A streamline visualization", $
        NAME="Streamline", _EXTRA=_extra)) then $
        RETURN, 0

    ; Register the parameters we are using for data
    self->RegisterParameter, 'U component', DESCRIPTION='U component', $
        /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], /OPTARGET
    self->RegisterParameter, 'V component', DESCRIPTION='V component', $
        /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], /OPTARGET

    self->RegisterParameter, 'X', DESCRIPTION='X Data', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR']
    self->RegisterParameter, 'Y', DESCRIPTION='Y Data', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR']

    self->RegisterParameter, 'Palette', $
        DESCRIPTION='Color Palette Data', $
        /INPUT, /OPTIONAL, /OPTARGET, TYPES=['IDLPALETTE','IDLARRAY2D']

    ; Register our special parameter for use with a colorbar.
    self->RegisterParameter, 'Visualization data', $
        DESCRIPTION='Vertex color min/max', $
        /OUTPUT, /OPTIONAL, /PRIVATE, TYPES=['IDLVECTOR']

    ; Register all properties.
    self->IDLitVisStreamline::_RegisterProperties

    self._oLine = OBJ_NEW('IDLgrPolyline', /ANTIALIAS, /PRIVATE)
    self->Add, self._oLine

    self._oPalette = OBJ_NEW('IDLgrPalette')
    self._oPalette->Loadct, 0
    self._oSymbol = OBJ_NEW('IDLgrSymbol', 8, /ANTIALIAS)

    self._pXdata = PTR_NEW(/ALLOCATE)
    self._pYdata = PTR_NEW(/ALLOCATE)
    self._pUdata = PTR_NEW(/ALLOCATE)
    self._pVdata = PTR_NEW(/ALLOCATE)

    self._headSize = 1
    self._xStreamParticles = 25
    self._yStreamParticles = 25
    self._streamStepsize = 0.2d
    self._streamNsteps = 100

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisStreamline::SetProperty, _EXTRA=_extra

    RETURN, 1                     ; Success

end


;----------------------------------------------------------------------------
; Purpose:
;    Cleanup this component
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitVisStreamline::Cleanup

    compile_opt idl2, hidden

    ; Cleanup our palette
    OBJ_DESTROY, self._oPalette
    OBJ_DESTROY, self._oSymbol
    PTR_FREE, self._pXdata, self._pYdata, self._pUdata, self._pVdata, self._pArrowOffset

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup

end


;----------------------------------------------------------------------------
; IDLitVisStreamline::_RegisterProperties
;
; Purpose:
;   Internal routine that will register all properties supported by
;   this object.
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisStreamline::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'GRID_UNITS', $
            DESCRIPTION='Grid units', $
            NAME='Grid units', $
            ENUMLIST=['Not applicable','Meters','Degrees'], /ADVANCED_ONLY

        self->RegisterProperty, 'ARROW_SIZE', /FLOAT, $
            NAME='Head size', $
            DESCRIPTION='Arrowhead or barb feather size'

        self->RegisterProperty, 'THICK', /THICK, $
            NAME='Line thickness', $
            DESCRIPTION='Line thickness'

        self->RegisterProperty, 'AUTO_COLOR', $
            NAME='Automatic color', $
            ENUMLIST=['None', 'Magnitude', 'Direction'], $
            DESCRIPTION='Vector color', /ADVANCED_ONLY

        self->RegisterProperty, 'Color', /COLOR, $
            DESCRIPTION='Vector color'

        ; Edit the current palette
        self->RegisterProperty, 'VISUALIZATION_PALETTE', $
            NAME='Color palette', $
            USERDEF='Edit color table', $
            DESCRIPTION='Color palette', $
            SENSITIVE=0, /ADVANCED_ONLY

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of vector visualization', $
            VALID_RANGE=[0,100,5]

        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for vectors', /ADVANCED_ONLY

        self->RegisterProperty, 'DIRECTION_CONVENTION', $
            NAME='Direction convention', $
            ENUMLIST=['Polar (counterclockwise from X axis)', $
            'Meteorological (from the wind)', $
            'Wind azimuths (towards the wind)'], $
            DESCRIPTION='Convention used for vector directions', /ADVANCED_ONLY

        self->RegisterProperty, 'X_STREAMPARTICLES', /INTEGER, $
            NAME='X stream particles', $
            DESCRIPTION='X stream particles', $
            VALID_RANGE=[2, 2e9], /ADVANCED_ONLY

        self->RegisterProperty, 'Y_STREAMPARTICLES', /INTEGER, $
            NAME='Y stream particles', $
            DESCRIPTION='Y stream particles', $
            VALID_RANGE=[2, 2e9], /ADVANCED_ONLY

        self->RegisterProperty, 'STREAMLINE_NSTEPS', /INTEGER, $
            NAME='Streamline steps', $
            DESCRIPTION='Streamline steps', $
            VALID_RANGE=[2,1e6], /ADVANCED_ONLY

        self->RegisterProperty, 'STREAMLINE_STEPSIZE', /FLOAT, $
            NAME='Streamline step size', $
            DESCRIPTION='Streamline step size', /ADVANCED_ONLY

        ; Need to register these so the symbol color dialog will
        ; be sensitized. But hide them from the regular property sheet.
        self->RegisterProperty, 'SYM_INDEX', /SYMBOL, /HIDE, $
            NAME='Symbol', $
            DESCRIPTION='Symbol'
        self->RegisterProperty, 'SYM_COLOR', /COLOR, /HIDE, $
            NAME='Arrow color', $
            DESCRIPTION='Arrow color'
        self->RegisterProperty, 'SYM_SIZE', /FLOAT, /HIDE, $
            NAME='Arrow size', $
            DESCRIPTION='Arrow size'
        self->RegisterProperty, 'SYM_TRANSPARENCY', /INTEGER, /HIDE, $
            NAME='Arrow transparency', $
            DESCRIPTION='Arrow transparency', $
            VALID_RANGE=[0,100,5]


    endif
end


;----------------------------------------------------------------------------
; IDLitVisStreamline::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisStreamline::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisStreamline::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Purpose:
;   This procedure method retrieves the
;   value of a property or group of properties.
;
; Arguments:
;   None.
;
; Keywords:
;   Any keyword to IDLitVisStreamline::Init followed by the word "Get"
;   can be retrieved using this method.
;
pro IDLitVisStreamline::GetProperty, $
    ANTIALIAS=antialias, $
    ARROW_COLOR=arrowColor, $
    ARROW_OFFSET=arrowOffset, $
    ARROW_SIZE=arrowSize, $
    ARROW_THICK=arrowThick, $
    ARROW_TRANSPARENCY=arrowTransparency, $
    AUTO_COLOR=autoColor, $
    AUTO_RANGE=autoRange, $
    COLOR=color, $
    DIRECTION_CONVENTION=directionConvention, $
    GRID_UNITS=gridUnits, $
    HEAD_SIZE=headSize, $
    STREAMLINE_NSTEPS=streamNsteps, $
    STREAMLINE_STEPSIZE=streamStepsize, $
    SYM_COLOR=symColor, $
    SYM_INDEX=symIndex, $
    SYM_SIZE=symSize, $
    SYM_TRANSPARENCY=symTransparency, $
    VISUALIZATION_PALETTE=visPalette, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    X_STREAMPARTICLES=xStreamParticles, $
    Y_STREAMPARTICLES=yStreamParticles, $
    ZVALUE=zValue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(antialias)) then $
        self._oLine->GetProperty, ANTIALIAS=antialias

    if (ARG_PRESENT(autoColor)) then $
        autoColor = self._autoColor

    if (ARG_PRESENT(autoRange)) then $
        autoRange = self._autoRange

    if (ARG_PRESENT(color)) then $
        color = self._color

    if (ARG_PRESENT(directionConvention)) then $
        directionConvention = self._directionConvention

    if (ARG_PRESENT(gridUnits) ne 0) then $
        gridUnits = self._gridUnits

    if (ARG_PRESENT(arrowColor)) then $
      self._oSymbol->GetProperty, COLOR=arrowColor

    if (ARG_PRESENT(arrowOffset)) then begin
      if (~PTR_VALID(self._pArrowOffset)) then self._pArrowOffset = PTR_NEW(0.5)
      arrowOffset = *self._pArrowOffset
    endif

    if (ARG_PRESENT(arrowSize)) then $
        arrowSize = self._headSize

    if (ARG_PRESENT(arrowThick)) then $
        self._oSymbol->GetProperty, THICK=arrowThick

    if (ARG_PRESENT(headSize)) then $
        headSize = self._headSize

    if (ARG_PRESENT(headStyle)) then $
        headStyle = self._headStyle

    if (ARG_PRESENT(streamNsteps)) then $
        streamNsteps = self._streamNsteps

    if (ARG_PRESENT(streamStepsize)) then $
        streamStepsize = self._streamStepsize

    if (ARG_PRESENT(symColor)) then $
      self._oSymbol->GetProperty, COLOR=symColor

    if (ARG_PRESENT(symIndex)) then $
      self._oSymbol->GetProperty, DATA=symIndex

    if (ARG_PRESENT(symSize)) then $
      symSize = self._headSize

    if ARG_PRESENT(arrowTransparency) || ARG_PRESENT(symTransparency) then begin
        self._oSymbol->GetProperty, ALPHA_CHANNEL=alpha
        symTransparency = 0 > ROUND(100 - alpha*100) < 100
        arrowTransparency = symTransparency
    endif

    if (ARG_PRESENT(thick)) then $
        self._oLine->GetProperty, THICK=thick

    if (ARG_PRESENT(xStreamParticles)) then $
        xStreamParticles = self._xStreamParticles

    if (ARG_PRESENT(yStreamParticles)) then $
        yStreamParticles = self._yStreamParticles

    if ARG_PRESENT(transparency) then begin
        self._oLine->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if ARG_PRESENT(visPalette) && OBJ_VALID(self._oPalette) then begin
        self._oPalette->GetProperty, BLUE_VALUES=blue, $
            GREEN_VALUES=green, RED_VALUES=red
        visPalette = TRANSPOSE([[red], [green], [blue]])
    endif

    if (ARG_PRESENT(xSubsample)) then $
        xSubsample = self._xSubsample

    if (ARG_PRESENT(ySubsample)) then $
        ySubsample = self._ySubsample

    if (ARG_PRESENT(zValue)) then $
        zValue = self._zValue

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method sets the
;   value of a property or group of properties.
;
; Arguments:
;   None.
;
; Keywords:
;   Any keyword to IDLitVisStreamline::Init followed by the word "Set"
;   can be set using this method.
;
pro IDLitVisStreamline::SetProperty, $
    ANTIALIAS=antialias, $
    ARROW_COLOR=arrowColor, $
    ARROW_OFFSET=arrowOffset, $
    ARROW_SIZE=arrowSize, $
    ARROW_THICK=arrowThick, $
    ARROW_TRANSPARENCY=arrowTransparency, $
    AUTO_COLOR=autoColor, $
    AUTO_RANGE=autoRange, $
    COLOR=color, $
    DIRECTION_CONVENTION=directionConvention, $
    GRID_UNITS=gridUnits, $
    HEAD_SIZE=headSize, $  ; replaced by ARROW_SIZE, keep for backwards compat
    RGB_TABLE=rgbTable, $
    STREAMLINE_NSTEPS=streamNsteps, $
    STREAMLINE_STEPSIZE=streamStepsize, $
    SYM_COLOR=symColor, $
    SYM_INDEX=symIndex, $   ; ignore
    SYM_SIZE=symSize, $
    SYM_TRANSPARENCY=symTransparency, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    VISUALIZATION_PALETTE=visPalette, $
    X_STREAMPARTICLES=xStreamParticles, $
    Y_STREAMPARTICLES=yStreamParticles, $
    ZVALUE=zValue, $
    X_VIS_LOG=xVisLog, $
    Y_VIS_LOG=yVisLog, $
    Z_VIS_LOG=zVisLog, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(gridUnits) ne 0) then begin
        self._gridUnits = gridUnits
        ; Change to isotropic for units = meters or degrees.
        wasIsotropic = self->IsIsotropic()
        isIsotropic = self._gridUnits eq 1 || self._gridUnits eq 2
        if (wasIsotropic ne isIsotropic) then begin
            self->IDLitVisualization::SetProperty, ISOTROPIC=isIsotropic
        endif
        ; If units changed we may need to recalculate our streamlines.
        self->_UpdateData
        ; If isotropy changed then update our dataspace as well.
        if (wasIsotropic ne isIsotropic) then begin
            self->OnDataChange, self
            self->OnDataComplete, self
        endif
    endif

    if (N_ELEMENTS(antialias) gt 0) then begin
        self._oLine->SetProperty, ANTIALIAS=antialias
        self._oSymbol->SetProperty, ANTIALIAS=antialias
    endif

    if (N_ELEMENTS(autoColor) gt 0) then begin
        self._autoColor = autoColor
        self->_UpdateData
    endif

    if (N_ELEMENTS(autoRange) gt 0) then begin
        self._autoRange = autoRange
        self->_UpdateData
    endif

    IF (N_ELEMENTS(color) GT 0) THEN BEGIN
        self._color = color
        self._oLine->SetProperty, COLOR=color
    ENDIF

    if (N_ELEMENTS(arrowColor) gt 0) then $
      self._oSymbol->SetProperty, COLOR=arrowColor

    if (N_ELEMENTS(arrowOffset) gt 0) then begin
      if (~PTR_VALID(self._pArrowOffset)) then self._pArrowOffset = PTR_NEW(/ALLOC)
      *self._pArrowOffset = 0 > arrowOffset < 1
      self->_UpdateData
    endif

    if (N_ELEMENTS(directionConvention) gt 0) then begin
        self._directionConvention = directionConvention
        self->_UpdateData
    endif

    if (N_ELEMENTS(arrowSize) gt 0) then begin
        self._headSize = arrowSize
        self->_UpdateData
    endif

    if (N_ELEMENTS(arrowThick) gt 0) then $
        self._oSymbol->SetProperty, THICK=arrowThick

    if (N_ELEMENTS(arrowTransparency)) then begin
        alpha = 0 > ((100.-arrowTransparency)/100) < 1
        self._oSymbol->SetProperty, ALPHA_CHANNEL=alpha
    endif

    if (N_ELEMENTS(headSize) gt 0) then begin
        self._headSize = headSize
        self->_UpdateData
    endif

    if (N_ELEMENTS(streamNsteps) gt 0 && streamNsteps ge 2) then begin
        self._streamNsteps = streamNsteps
        self->_UpdateData
    endif

    if (N_ELEMENTS(streamStepsize) gt 0 && streamStepsize gt 0) then begin
        self._streamStepsize = streamStepsize
        self->_UpdateData
    endif

    ; Same as ARROW_COLOR, needed for symbol dialog.
    if (N_ELEMENTS(symColor) gt 0) then $
      self._oSymbol->SetProperty, COLOR=symColor

    ; Same as ARROW_SIZE, needed for symbol dialog.
    if (N_ELEMENTS(symSize) gt 0) then begin
        self._headSize = symSize
        self->_UpdateData
    endif

    ; Same as ARROW_TRANSPARENCY, needed for symbol dialog.
    if (N_ELEMENTS(symTransparency)) then begin
        alpha = 0 > ((100.-symTransparency)/100) < 1
        self._oSymbol->SetProperty, ALPHA_CHANNEL=alpha
    endif

    if (N_ELEMENTS(thick) gt 0) then begin
        self._oLine->SetProperty, THICK=thick
    endif

    if (N_ELEMENTS(transparency)) then begin
        alpha = 0 > ((100.-transparency)/100) < 1
        self._oLine->GetProperty, ALPHA_CHANNEL=oldAlphaLine
        self._oSymbol->GetProperty, ALPHA_CHANNEL=oldAlphaSym
        self._oLine->SetProperty, ALPHA_CHANNEL=alpha
        if (oldAlphaLine eq oldAlphaSym) then $
          self._oSymbol->SetProperty, ALPHA_CHANNEL=alpha
    endif

    if (N_ELEMENTS(xStreamParticles) gt 0 && xStreamParticles ge 2) then begin
        self._xStreamParticles = xStreamParticles
        self->_UpdateData
    endif

    if (N_ELEMENTS(yStreamParticles) gt 0 && yStreamParticles ge 2) then begin
        self._yStreamParticles = yStreamParticles
        self->_UpdateData
    endif

    if (N_ELEMENTS(zValue) gt 0) then begin
        self._zValue = zValue
        self->_UpdateData
        self->Set3D, (self._zValue ne 0), /ALWAYS
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (N_ELEMENTS(xVisLog) gt 0) then begin
        self._xVisLog = xVisLog
        self->_UpdateData
    endif

    if (N_ELEMENTS(yVisLog) gt 0) then begin
        self._yVisLog = yVisLog
        self->_UpdateData
    endif

    if (N_ELEMENTS(zVisLog) gt 0) then begin
        self._zVisLog = zVisLog
        self->_UpdateData
    endif

    if ((N_ELEMENTS(rgbTable) ne 0) && (N_ELEMENTS(visPalette) eq 0)) then begin
      if (N_ELEMENTS(rgbTable) eq 1) then begin
        Loadct, rgbTable[0], RGB_TABLE=visPalette
        visPalette = TRANSPOSE(visPalette)
      endif else begin
        visPalette = rgbTable
      endelse
    endif
    
    if (N_ELEMENTS(visPalette) gt 0 && OBJ_VALID(self._oPalette)) then begin
        self._oPalette->SetProperty, BLUE_VALUES=visPalette[2,*], $
            GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
        oPal = self->GetParameter('PALETTE')
        if OBJ_VALID(oPal) then $
            success = oPal->SetData(visPalette)
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty,_EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   Handle the editing of the user defined properties
;
; Arguments:
;   oTool - object reference to the current iTool
;
;   identifier - string denoting which property to edit
;
; Keywords:
;   None.
;
function IDLitVisStreamline::EditUserDefProperty, oTool, identifier
  compile_opt idl2, hidden

    case identifier of

    'VISUALIZATION_PALETTE': begin
        success = oTool->DoUIService('PaletteEditor', self)
        return, success
        end

    else:

    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

END


;----------------------------------------------------------------------------
; IDLitVisImage::EnsurePalette
;
; Purpose:
;   This procedure method verifies that valid palette parameter is
;   associated with this image.  If not, it creates one.
;
;   This method is only intended to be called if the image is a
;   single-channel image.
;
pro IDLitVisStreamline::EnsurePalette

    compile_opt idl2, hidden

    self->GetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=sens
    if (~sens) then begin
        self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', /SENSITIVE
        ; Notify our observers in case the prop sheet is visible.
        self->DoOnNotify, self->GetFullIdentifier(), $
            'SETPROPERTY', 'VISUALIZATION_PALETTE'
    endif

    oPalette = self->IDLitParameter::GetParameter('PALETTE')

    ; Do we have a valid palette?
    if (OBJ_VALID(oPalette) && oPalette->GetData(palette)) then begin
        red = REFORM(palette[0,*])
        green = REFORM(palette[1,*])
        blue = REFORM(palette[2,*])
        self._oPalette->SetProperty, RED=red, GREEN=green, BLUE=blue
        RETURN
    endif

    ; If no palette exists, create a gray scale palette
    red = BINDGEN(256)
    green = red
    blue = red
    oGrayPalette = OBJ_NEW('IDLitDataIDLPalette', $
                           TRANSPOSE([[red],[green],[blue]]), $
                           NAME='Palette')
    oGrayPalette->SetProperty, /AUTO_DELETE
    self->SetParameter, 'PALETTE', oGrayPalette, /NO_UPDATE

    ; Send a notification message to update UI
    self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''

    oPalette = self->GetParameter('PALETTE')

    ; Add to our data container.
    oData = self->GetParameter('U component')
    if (OBJ_VALID(oData)) then $
      oData->GetProperty, _PARENT=oParent

    if obj_valid(oParent) THEN BEGIN
        oParent->Add, oPalette
    endif else begin
        self->AddByIdentifier, '/DATA MANAGER', oPalette
    endelse

end


;----------------------------------------------------------------------------
; Purpose:
;   Internal method to compute the direction.
;
function IDLitVisStreamline::_ComputeDirection, udata, vdata

    compile_opt idl2, hidden

    case (self._directionConvention) of

    ; Polar angle, -180 to +180
    0: direction = (180/!PI)*ATAN(vdata, udata)

    ; Meteorological, from which the wind is blowing, 0 to 360
    1: begin
        direction = (180/!PI)*ATAN(-udata, -vdata)
        direction += 360*(direction lt 0)
       end

    ; Wind azimuths, towards which the wind is blowing, 0 to 360
    2: begin
        direction = (180/!PI)*ATAN(udata, vdata)
        direction += 360*(direction lt 0)
       end

    else: ; do nothing

    endcase

    return, direction

;    ; Convert from magnitude & direction to u & v, using the
;    ; appropriate DIRECTION_CONVENTION.
;    case (self._directionConvention) of
;    0: begin ; Polar angle
;        udata = magnitude*COS(direction*!PI/180)
;        vdata = magnitude*SIN(direction*!PI/180)
;       end
;    1: begin  ; Meteorological, from which the wind is blowing
;        udata = -magnitude*SIN(direction*!PI/180)
;        vdata = -magnitude*COS(direction*!PI/180)
;       end
;    2: begin  ; Wind azimuths, towards which the wind is blowing
;        udata = magnitude*SIN(direction*!PI/180)
;        vdata = magnitude*COS(direction*!PI/180)
;       end
;    endcase
end


;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
function IDLitVisStreamline::_GetData, udata, vdata, xdata, ydata

    compile_opt idl2, hidden

    ; Check for U & V.
    oDataU = self->GetParameter('U component')
    oDataV = self->GetParameter('V component')
    if (~OBJ_VALID(oDataU) || ~OBJ_VALID(oDataU)) then return, 0
    if (~oDataU->GetData(udata) || ~oDataV->GetData(vdata)) then $
        return, 0

    dims = SIZE(udata, /DIMENSIONS)
    ndim = N_ELEMENTS(dims)
    nElts = N_ELEMENTS(udata)
    if (nElts ne N_ELEMENTS(vdata)) then $
        return, 0

    ; Check for X and Y.
    oDataX = self->GetParameter('X')
    oDataY = self->GetParameter('Y')
    if (~OBJ_VALID(oDataX) || ~oDataX->GetData(xdata) || $
        ~OBJ_VALID(oDataY) || ~oDataY->GetData(ydata)) then begin
        ; If U & V are vectors then you must supply X & Y.
        if (N_ELEMENTS(dims) eq 1) then $
            return, 0
        xdata = FLOAT(LINDGEN(dims[0], dims[1]) mod dims[0])
        ydata = FLOAT(LINDGEN(dims[0], dims[1])/dims[0])
    endif else begin
        ; For 2D data make sure the X & Y dims agree with the data.
        if (N_ELEMENTS(dims) eq 2) then begin
            dimx = SIZE(xdata, /DIMENSIONS)
            if (N_ELEMENTS(xdata) ne dims[0] || $
                N_ELEMENTS(ydata) ne dims[1]) then $
                return, 0
            xdata = REBIN(xdata, dims[0], dims[1])
            ydata = REBIN(TRANSPOSE(ydata), dims[0], dims[1])
        endif else begin
            ; For 1D data make sure # of X & Y elements agrees with U & V.
            if (N_ELEMENTS(xdata) ne nElts || $
                N_ELEMENTS(ydata) ne nElts) then $
                return, 0
        endelse
    endelse

    ; We now want U, V, X, Y, all as vectors.
    udata = REFORM(udata, nElts, /OVERWRITE)
    vdata = REFORM(vdata, nElts, /OVERWRITE)
    xdata = REFORM(xdata, nElts, /OVERWRITE)
    ydata = REFORM(ydata, nElts, /OVERWRITE)

    return, nElts

end


;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
pro IDLitVisStreamline::_UpdateStreamlines, sMap, minX, minY, maxX, maxY

    compile_opt idl2, hidden

    hasZvalue = self._zValue ne 0
    xrange = maxX - minX
    yrange = maxY - minY

    xdata = *self._pXdata
    ydata = *self._pYdata
    udata = *self._pUdata
    vdata = *self._pVdata

    ; Regrid our original data to make the computation faster.
    xDim = self._xStreamParticles
    yDim = self._yStreamParticles
    xd = (xdata - minX)*(xDim/xrange)
    yd = (ydata - minY)*(yDim/yrange)
    uu = FLTARR(xDim, yDim)
    vv = FLTARR(xDim, yDim)
    uu[xd, yd] = udata
    vv[TEMPORARY(xd), TEMPORARY(yd)] = vdata
    uv = DBLARR(2, xDim, yDim, /NOZERO)
    uv[0, *, *] = TEMPORARY(uu)
    uv[1, *, *] = TEMPORARY(vv)

    xgrid = FINDGEN(xDim)*(xDim/(xDim-1))
    xgrid = REBIN(xgrid, xDim, yDim)
    ygrid = FINDGEN(1, yDim)*(yDim/(yDim-1))
    ygrid = REBIN(ygrid, xDim, yDim)
    pIn_xy = DBLARR(2, xDim*yDim, /NOZERO)
    pIn_xy[0, *] = TEMPORARY(xgrid)
    pIn_xy[1, *] = TEMPORARY(ygrid)

    PARTICLE_TRACE, uv, pIn_xy, linevert, polylines, $
        ANISOTROPY=[xrange/(xDim-1), yrange/(yDim-1)], $
        MAX_STEPSIZE=self._streamStepsize, $
        MAX_ITERATIONS=self._streamNsteps

    nvert = N_ELEMENTS(linevert)/2

    ; must interpolate in X and Y since PARTICLE_TRACE assumes
    ; X and Y to always lie between 0 and the dimension of the array.
    linevert[0,*] += minX
    linevert[1,*] += minY

    ; For grid units = none or meters, don't need to warp.
    ; Otherwise, for degrees, we need to warp.
    warpMap = self._gridUnits eq 2 && N_TAGS(sMap) gt 0
    if (warpMap) then begin
        ; Project the polylines.
        linevert = MAP_PROJ_FORWARD(linevert, MAP_STRUCTURE=sMap, $
            CONNECTIVITY=polylines, POLYLINES=polylinesOut)
        polylines = TEMPORARY(polylinesOut)
        minn = MIN(linevert, MAX=maxx, DIMENSION=2)
        xrange = maxx[0] - minn[0]
        yrange = maxx[1] - minn[1]
    endif

    if (self._xVisLog) then begin
        linevert[0,*] = ALOG10(linevert[0,*])
        xrange = ALOG10(xrange)
    endif
    if (self._yVisLog) then begin
        linevert[1,*] = ALOG10(linevert[1,*])
        yrange = ALOG10(yrange)
    endif

    ; No streamlines were found (or they were outside the map).
    if (N_ELEMENTS(linevert) lt 4 || polylines[0] eq -1) then begin
        linevert = FLTARR(2, 2)
        nvert = 2
        polylines = 0
    endif

    ; The Z value will be filled in later.
    if (hasZvalue) then $
        linevert = [linevert, FLTARR(1, nvert, /NOZERO)]

    if (self._autoColor gt 0) then begin
        delta = FLTARR(nvert)
        self->EnsurePalette
        self._oLine->SetProperty, PALETTE=self._oPalette
        ; For color by magnitude or direction, we need to warp back
        ; to lon/lat coordinates.
        linevertOrig = warpMap ? $
            MAP_PROJ_INVERSE(linevert, MAP_STRUCTURE=sMap) : linevert
    endif else begin
        self._oLine->SetProperty, PALETTE=OBJ_NEW()
    endelse

    ; Desensitize COLOR property if using vertex colors.
    self->SetPropertyAttribute, 'COLOR', SENSITIVE=self._autoColor eq 0
    ; Sensitize VISUALIZATION_PALETTE property if using vertex colors.
    self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', $
        SENSITIVE=self._autoColor gt 0

    ; Count up the number of streamlines.
    idx = 0L
    npoly = N_ELEMENTS(polylines)
    nlines = 0L
    while (idx lt npoly) do begin
        npoly1 = polylines[idx]
        if (npoly1 eq -1) then break
        if (npoly1 eq 0) then begin
            idx++
            continue
        endif
        ; Compute how far each particle moved in each step.
        if (self._autoColor gt 0) then begin
            diff = linevertOrig[*,polylines[idx+2:idx+npoly1]] - $
                linevertOrig[*,polylines[idx+1:idx+npoly1-1]]
            if (self._autoColor eq 1) then begin
                delta[polylines[idx+1]] = SQRT(TOTAL(diff^2, 1))
            endif else begin
                u = REFORM(diff[0,*])
                v = REFORM(diff[1,*])
                delta[polylines[idx+1]] = self->_ComputeDirection(u, v)
            endelse
            ; Just make the last two points be the same delta.
            delta[polylines[idx+1] + npoly1 - 1] = delta[polylines[idx+1] + npoly1 - 2]
        endif
        nlines++
        idx += npoly1 + 1
    endwhile

    lineColors = 0
    if (self._autoColor gt 0 && nlines gt 0) then begin
        ; Create our special parameter for use with a colorbar.
        oAuxData = self->GetParameter('VISUALIZATION DATA')
        if (~OBJ_VALID(oAuxData)) then begin
            oAuxData = OBJ_NEW('IDLitDataIDLVector', $
                NAME='Vertex color min/max')
            oAuxData->SetProperty, /AUTO_DELETE
            self->SetParameter, 'VISUALIZATION DATA', oAuxData, /NO_UPDATE
            oAuxData = self->GetParameter('VISUALIZATION DATA')
            ; Add to our data container.
            oData = self->GetParameter('U component')
            if (OBJ_VALID(oData)) then $
                oData->GetProperty, _PARENT=oParent
            if (OBJ_VALID(oParent)) then begin
                oParent->Add, oAuxData
            endif else begin
                self->AddByIdentifier, '/DATA MANAGER', oAuxData
            endelse
        endif

        ; Bytscl using either the user's range or the data min/max.
        if (self._autoRange[0] ne self._autoRange[1]) then begin
          mn = self._autoRange[0]
          mx = self._autoRange[1]
        endif else begin
          mn = MIN(delta, MAX=mx)
        endelse
        success = oAuxData->SetData([mn,mx])
        lineColors = BYTSCL(delta, MIN=mn, MAX=mx);HIST_EQUAL(delta)

    endif


    headSizeX = 0.02*self._headSize*xrange
    headSizeY = 0.02*self._headSize*yrange

    if (~PTR_VALID(self._pArrowOffset)) then self._pArrowOffset = PTR_NEW(0.5)
    labelOffset = *self._pArrowOffset
    noffset = N_ELEMENTS(labelOffset)
    if (noffset gt 1 && nlines gt 0) then $
      labelOffset = REBIN(labelOffset, noffset, nlines)

    self._oSymbol->SetProperty, SIZE=[headSizeX, headSizeY, 1]
    labelObject = (nlines gt 0) ? $
        REPLICATE(self._oSymbol, nlines*noffset) : self._oSymbol
    labelPolylines = (nlines gt 0) ? LINDGEN(nlines*noffset)/noffset : 0

    if (hasZvalue) then begin
        linevert[2,*] = self._zValue
    endif

    self._oLine->SetProperty, DATA=linevert, $
        POLYLINES=polylines, $
        /LABEL_NOGAPS, $
        LABEL_OBJECTS=labelObject, $
        LABEL_OFFSETS=labelOffset, $
        LABEL_POLYLINES=labelPolylines, $
        LABEL_USE_VERTEX_COLOR=N_ELEMENTS(lineColors) gt 1, $
        /USE_LABEL_COLOR, $
        VERT_COLORS=lineColors, $
        HIDE=(N_ELEMENTS(polylines) le 1)

end


;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
pro IDLitVisStreamline::_UpdateData, $
    MAP_PROJECTION=sMap, $
    WITHIN_DRAW=withinDraw

    compile_opt idl2, hidden

    ; Bail if we aren't part of a hierarchy.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if (~OBJ_VALID(oParent)) then $
        return

    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog
        self._xVisLog = xLog
        self._yVisLog = yLog
    endif

    nElts = self->_GetData(udata, vdata, xdata, ydata)
    if (~nElts) then return

    ; Compute range before taking any logs.
    minX = MIN(xdata, MAX=maxX)
    minY = MIN(ydata, MAX=maxY)

    *self._pXdata = TEMPORARY(xdata)
    *self._pYdata = TEMPORARY(ydata)
    *self._pUdata = udata
    *self._pVdata = vdata

    ; Retrieve map projection
    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    self->_UpdateStreamlines, sMap, minX, minY, maxX, maxY

    if (~KEYWORD_SET(withinDraw)) then begin
        self->OnDataChange
        self->OnDataComplete
    endif

end

;----------------------------------------------------------------------------
pro IDLitVisStreamline::OnDataDisconnect, ParmName

    compile_opt hidden, idl2

    self->_UpdateData
end

;----------------------------------------------------------------------------
pro IDLitVisStreamline::_CheckGridUnits, sMap

    compile_opt idl2, hidden

    ; Assume user already set.
    if (self._gridUnits ne 0) then return

    ; Make sure we have a map projection.
    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()
    if (~N_TAGS(sMap)) then return

    oXdata = self->GetParameter('X')
    oYdata = self->GetParameter('Y')
    if (~OBJ_VALID(oXdata) || ~OBJ_VALID(oYdata) || $
        ~oXdata->GetData(x) || ~oYdata->GetData(y)) then return

    xmin = MIN(x, MAX=xmax)
    ymin = MIN(y, MAX=ymax)
    self._gridUnits = $
        (xmin ge -181 && xmax le 361 && ymin ge -91 && ymax le 91) ? 2 : 1
end

;----------------------------------------------------------------------------
; IDLitVisStreamline::OnDataChangeUpdate
;
; Purpose:
;   This method is called when the data associated with a parameter
;   has changed. When called, the visualization performs the
;   desired updates to reflect the change
;
; Parameters
;    oSubject    - The data item for the parameter that has changed.
;
;   parmName    - The name of the parameter that has changed.
;
;
pro IDLitVisStreamline::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case (parmName) of
    'PALETTE': return  ; don't need to update
    'VISUALIZATION DATA': return  ; don't need to update
    'X': self->_CheckGridUnits
    'Y': self->_CheckGridUnits
    '<PARAMETER SET>': self->_CheckGridUnits
    else:
    endcase

    self->_UpdateData
end


;----------------------------------------------------------------------------
pro IDLitVisStreamline::OnProjectionChange, sMap

    compile_opt idl2, hidden

    self->_CheckGridUnits, sMap
    self->_UpdateData, MAP_PROJECTION=sMap
end


;---------------------------------------------------------------------------
; Convert a location from decimal degrees to DDDdMM'SS", where "d" is
; the degrees symbol.
;
function IDLitVisStreamline::_DegToDMS, x

    compile_opt idl2, hidden

    eps = 0.5d/3600
    x = (x ge 0) ? x + eps : x - eps
    degrees = FIX(x)
    minutes = FIX((ABS(x) - ABS(degrees))*60)
    seconds = (ABS(x) - ABS(degrees) - minutes/60d)*3600
    format = '(I2)'

    dms = STRING(degrees, FORMAT='(I4)') + STRING(176b) + $
        STRING(minutes, FORMAT='(I2)') + "'" + $
        STRING(seconds, FORMAT=format) + '"'

    return, STRTRIM(dms, 2)

end


;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisStreamline::GetDataString, xyz

    compile_opt idl2, hidden

    ; No cached data. Just return our coordinates.
    if (~N_ELEMENTS(*self._pXdata)) then begin
        xy = STRCOMPRESS(STRING(xyz[0:1], FORMAT='(G11.4)'))
        return, STRING(xy, FORMAT='("X: ",A,"  Y: ",A)')
    endif

    ; Cached data. Find the closest vector.
    minn = MIN((*self._pXdata - xyz[0])^2 + $
        (*self._pYdata - xyz[1])^2, minLoc)
    x = (*self._pXdata)[minLoc]
    y = (*self._pYdata)[minLoc]
    u = (*self._pUdata)[minLoc]
    v = (*self._pVdata)[minLoc]

    if (self._gridUnits eq 2) then begin
        sMap = self->GetProjection()
        if (N_TAGS(sMap) gt 0) then begin
            lonlat = MAP_PROJ_INVERSE(x, y, MAP_STRUCTURE=sMap)
            x = lonlat[0]
            y = lonlat[1]
        endif
        ; Longitude & latitude.
        x = 'Lon: ' + self->_DegToDMS(x)
        y = '  Lat: ' + self->_DegToDMS(y)
    endif else begin
        x = 'X: ' + STRCOMPRESS(STRING(x, FORMAT='(G11.4)'), /REM)
        y = '  Y: ' + STRCOMPRESS(STRING(y, FORMAT='(G11.4)'), /REM)
    endelse

    ; Add magnitude & direction.
    mag = '  Mag: ' + $
        STRCOMPRESS(STRING(SQRT(u^2 + v^2), FORMAT='(G11.4)'), /REM)

    direction = self->_ComputeDirection(u, v)
    dir = '  Dir: ' + $
        STRCOMPRESS(STRING(direction, FORMAT='(I4)'), /REM) + $
        STRING(176b)

    return, x + y + mag + dir

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
pro IDLitVisStreamline::OnWorldDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    ; If the world changes to 3D, the isotropic setting is
    ; not as relevant.  Turn it off in this case so that if
    ; it gets added to a 3D world (that is not isotropic), the
    ; scaling remains consistent.
    ; In a 2D world, isotropic scaling is used for map data.
    wantIso = self._gridUnits eq 1 || self._gridUnits eq 2
    self->IDLitVisualization::SetProperty, ISOTROPIC=~is3D && wantIso

    ; Call superclass.
    self->IDLitVisualization::OnWorldDimensionChange, oSubject, is3D
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisStreamline__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisStreamline object.
;
;-
pro IDLitVisStreamline__Define

    compile_opt idl2, hidden

    struct = { IDLitVisStreamline,              $
        inherits IDLitVisualization,  $ ; Superclass: _IDLitVisualization
        _oLine: OBJ_NEW(), $
        _oPalette: OBJ_NEW(),         $ ; IDLgrPalette object
        _oSymbol: OBJ_NEW(), $
        _pXdata: PTR_NEW(), $
        _pYdata: PTR_NEW(), $
        _pUdata: PTR_NEW(), $
        _pVdata: PTR_NEW(), $
        _pArrowOffset: PTR_NEW(), $
        _color: [0b,0b,0b], $
        _gridUnits: 0b, $
        _autoColor: 0b, $
        _autoRange: [0d, 0d], $
        _xVisLog : 0b, $
        _yVisLog : 0b, $
        _zVisLog : 0b, $
        _directionConvention: 0b, $
        _headSize: 0d, $
        _zValue: 0d, $
        _xStreamParticles: 0L, $
        _yStreamParticles: 0L, $
        _streamNsteps: 0L, $
        _streamStepsize: 0d $
    }

end
