; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisvector__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   The IDLitVisVector class is the component for vector visualization.
;
;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Syntax:
;
;    Obj = OBJ_NEW('IDLitVisVector')
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
function IDLitVisVector::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses
    if (~self->IDLitVisualization::Init(TYPE="IDLVISVECTOR", $
        ICON='fitwindow', $
        DESCRIPTION="A Vector Visualization", $
        NAME="Vector", _EXTRA=_extra)) then $
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

    self->RegisterParameter, 'Vector Colors', DESCRIPTION='Vector colors', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

    self->RegisterParameter, 'Palette', $
        DESCRIPTION='Color Palette Data', $
        /INPUT, /OPTIONAL, /OPTARGET, TYPES=['IDLPALETTE','IDLARRAY2D']

    ; Register our special parameter for use with a colorbar.
    self->RegisterParameter, 'Visualization data', $
        DESCRIPTION='Vertex color min/max', $
        /OUTPUT, /OPTIONAL, /PRIVATE, TYPES=['IDLVECTOR']

    self._oSymbol = OBJ_NEW('IDLitSymbol', PARENT=self)

    ; Register all properties.
    self->IDLitVisVector::_RegisterProperties

    self._oLine = OBJ_NEW('IDLgrPolyline', /ANTIALIAS, /PRIVATE)
    self->Add, self._oLine
    self._oPoly = OBJ_NEW('IDLgrPolygon', /PRIVATE)
    self->Add, self._oPoly

    self._oMiss = OBJ_NEW('IDLgrPolyline', /PRIVATE, $
        LINESTYLE=6, SYMBOL=self._oSymbol->GetSymbol())
    self->Add, self._oMiss

    self._oPalette = OBJ_NEW('IDLgrPalette')
    self._oPalette->Loadct, 0

    self._pXdata = PTR_NEW(/ALLOCATE)
    self._pYdata = PTR_NEW(/ALLOCATE)
    self._pUdata = PTR_NEW(/ALLOCATE)
    self._pVdata = PTR_NEW(/ALLOCATE)
    self._pSign = PTR_NEW(/ALLOCATE)

    self._arrowStyle = 1b
    self._autoSubsample = 0b
    self._headSize = 1
    self._lengthScale = 1
    self._headAngle = 30
    self._headIndent = 0.4d
    self._dataLocation = 1  ; center
    self._xSubsample = 1
    self._ySubsample = 1
    self._lengthX = 1
    self._lengthY = 1
    self._arrowThick = 2b

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisVector::SetProperty, _EXTRA=_extra

    return, 1                     ; Success
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
pro IDLitVisVector::Cleanup

    compile_opt idl2, hidden

    ; Cleanup our palette
    OBJ_DESTROY, self._oPalette
    OBJ_DESTROY, self._oSymbol
    PTR_FREE, self._pXdata, self._pYdata, $
        self._pUdata, self._pVdata, self._pSign

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisVector::_RegisterProperties
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
pro IDLitVisVector::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'GRID_UNITS', $
            DESCRIPTION='Grid units', $
            NAME='Grid units', $
            ENUMLIST=['Not applicable','Meters','Degrees'], /ADVANCED_ONLY

        self->RegisterProperty, 'VECTOR_STYLE', $
            NAME='Vector style', $
            DESCRIPTION='Vector style', $
            ENUMLIST=['Arrows', 'Wind barbs']

        self->RegisterProperty, 'LENGTH_SCALE', /FLOAT, $
            NAME='Length scale', $
            DESCRIPTION='Shaft scale factor', /ADVANCED_ONLY

        self->RegisterProperty, 'HEAD_SIZE', /FLOAT, $
            NAME='Head size', $
            DESCRIPTION='Arrowhead or barb feather size', /ADVANCED_ONLY

        self->RegisterProperty, 'ARROW_STYLE', $
            NAME='Arrow style', $
            DESCRIPTION='Arrow style', $
            ENUMLIST=['Lines', 'Filled']

        self->RegisterProperty, 'HEAD_PROPORTIONAL', /BOOLEAN, $
            NAME='Proportional heads', $
            DESCRIPTION='Arrowhead size proportional to magnitude', $
            /ADVANCED_ONLY

        self->RegisterProperty, 'HEAD_ANGLE', /FLOAT, $
            NAME='Arrowhead angle', $
            DESCRIPTION='Angle in degrees of arrowhead from shaft', $
            VALID_RANGE=[0,90], /ADVANCED_ONLY

        self->RegisterProperty, 'HEAD_INDENT', /FLOAT, $
            NAME='Arrowhead indentation', $
            DESCRIPTION='Indentation of arrowhead along shaft', $
            VALID_RANGE=[-1,1], /ADVANCED_ONLY

        self->RegisterProperty, 'ARROW_THICK', /THICK, $
            NAME='Arrow thickness', $
            DESCRIPTION='Thickness of arrow shaft'

        self->RegisterProperty, 'THICK', /THICK, $
            NAME='Line thickness', $
            DESCRIPTION='Line thickness'

        self->RegisterProperty, 'DATA_LOCATION', $
            NAME='Data location', $
            DESCRIPTION='Location of data sample on the arrow or barb', $
            ENUMLIST=['Tail', 'Center', 'Head'], /ADVANCED_ONLY

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

        self->RegisterProperty, 'MIN_VALUE', /FLOAT, $
            NAME='Minimum magnitude', $
            DESCRIPTION='Minimum magnitude to plot', /ADVANCED_ONLY

        self->RegisterProperty, 'MAX_VALUE', /FLOAT, $
            NAME='Maximum magnitude', $
            DESCRIPTION='Maximum magnitude to plot', /ADVANCED_ONLY

        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for vectors', /ADVANCED_ONLY

        self->RegisterProperty, 'AUTO_SUBSAMPLE', /BOOLEAN, $
            NAME='Automatic subsampling', $
            DESCRIPTION='Compute subsampling based upon view zoom', $
            /ADVANCED_ONLY

        self->RegisterProperty, 'SUBSAMPLE_METHOD', $
            NAME='Subsampling method', $
            DESCRIPTION='Method for computing subsamples', $
            ENUMLIST=['Nearest neighbor', 'Linear'], /ADVANCED_ONLY

        self->RegisterProperty, 'X_SUBSAMPLE', /INTEGER, $
            NAME='X subsample factor', $
            DESCRIPTION='X subsampling factor', $
            VALID_RANGE=[1, 2e9], /ADVANCED_ONLY

        self->RegisterProperty, 'Y_SUBSAMPLE', /INTEGER, $
            NAME='Y subsample factor', $
            DESCRIPTION='Y subsampling factor', $
            VALID_RANGE=[1, 2e9], /ADVANCED_ONLY

        self->RegisterProperty, 'DIRECTION_CONVENTION', $
            NAME='Direction convention', $
            ENUMLIST=['Polar (counterclockwise from X axis)', $
            'Meteorological (from the wind)', $
            'Wind azimuths (towards the wind)'], $
            DESCRIPTION='Convention used for vector directions', /ADVANCED_ONLY

        ; For styles, hide these properties until we have data.
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], /HIDE

    endif

    if (registerAll || updateFromVersion lt 640) then begin
        ; Aggregate the symbol properties.
        self->Aggregate, self._oSymbol
        self._oSymbol->SetPropertyAttribute, 'SYM_THICK', /HIDE
        self._oSymbol->SetPropertyAttribute, 'SYMBOL', NAME='Missing point symbol'
    endif

    if (~registerAll && updateFromVersion lt 640) then begin
        ; This property was replaced by SYM_INDEX.
        self->SetPropertyAttribute, 'MARK_POINTS', /HIDE
        ; If mark was set then switch symbol to points.
        if (self._markPoints) then self._oSymbol->SetProperty, SYM_INDEX=3
    endif
end

;----------------------------------------------------------------------------
; IDLitVisVector::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisVector::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; We added the missing point symbol in IDL64.
    ; We also changed the computation of wind barbs,
    ; but _UpdateData will handle this for us.
    if (self.idlitcomponentversion lt 640) then begin
        self._pSign = PTR_NEW(/ALLOCATE)
        Obj_Destroy, self._oSymbol   ; unused IDLgrSymbol
        self->Remove, self._oMiss    ; old IDLgrPolygon
        Obj_Destroy, self._oMiss
        ; New IDLitSymbol and IDLgrPolyline
        self._oSymbol = OBJ_NEW('IDLitSymbol', PARENT=self)
        self._oMiss = OBJ_NEW('IDLgrPolyline', /PRIVATE, $
            LINESTYLE=6, SYMBOL=self._oSymbol->GetSymbol())
        self->Add, self._oMiss
        self->GetProperty, COLOR=color, THICK=thick, TRANSPARENCY=transparency
        self._oSymbol->SetProperty, COLOR=color, $
            SYM_THICK=thick, $
            SYM_TRANSPARENCY=transparency
    endif

    ; Register new properties.
    self->IDLitVisVector::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    self->_UpdateData
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
;   Any keyword to IDLitVisVector::Init followed by the word "Get"
;   can be retrieved using this method.
;
pro IDLitVisVector::GetProperty, $
    ANTIALIAS=antialias, $
    ARROW_STYLE=arrowStyle, $
    ARROW_THICK=arrowThick, $
    AUTO_COLOR=autoColor, $
    AUTO_RANGE=autoRange, $
    AUTO_SUBSAMPLE=autoSubsample, $
    COLOR=color, $
    DATA_LOCATION=dataLocation, $
    DIRECTION_CONVENTION=directionConvention, $
    GRID_UNITS=gridUnits, $
    HEAD_ANGLE=headAngle, $
    HEAD_INDENT=headIndent, $
    HEAD_PROPORTIONAL=headProportional, $
    HEAD_SIZE=headSize, $
    LENGTH_SCALE=lengthScale, $
    MARK_POINTS=markPoints, $  ; obsolete but keep for BC
    MIN_VALUE=minValue, $
    MAX_VALUE=maxValue, $
    SYM_SIZE=symSize, $
    SUBSAMPLE_METHOD=subsampleMethod, $
    VISUALIZATION_PALETTE=visPalette, $
    VECTOR_STYLE=vectorStyle, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    X_SUBSAMPLE=xSubsample, $
    Y_SUBSAMPLE=ySubsample, $
    ZVALUE=zValue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(antialias)) then $
        self._oLine->GetProperty, ANTIALIAS=antialias

    if (ARG_PRESENT(arrowStyle)) then $
        arrowStyle = self._arrowStyle

    if (ARG_PRESENT(arrowThick)) then $
        arrowThick = self._arrowThick

    if (ARG_PRESENT(autoColor)) then $
        autoColor = self._autoColor

    if (ARG_PRESENT(autoRange)) then $
        autoRange = self._autoRange

    if (ARG_PRESENT(autoSubsample)) then $
        autoSubsample = self._autoSubsample

    if (ARG_PRESENT(color)) then $
        color = self._color

    if (ARG_PRESENT(dataLocation)) then $
        dataLocation = self._dataLocation

    if (ARG_PRESENT(directionConvention)) then $
        directionConvention = self._directionConvention

    if (ARG_PRESENT(gridUnits) ne 0) then $
        gridUnits = self._gridUnits

    if (ARG_PRESENT(headAngle)) then $
        headAngle = self._headAngle

    if (ARG_PRESENT(headIndent)) then $
        headIndent = self._headIndent

    if (ARG_PRESENT(headProportional)) then $
        headProportional = self._headProportional

    if (ARG_PRESENT(headSize)) then $
        headSize = self._headSize

    if (ARG_PRESENT(lengthScale)) then $
        lengthScale = self._lengthScale

    if (ARG_PRESENT(minValue)) then $
        minValue = self._minValue

    if (ARG_PRESENT(markPoints)) then $
        markPoints = self._markPoints

    if (ARG_PRESENT(maxValue)) then $
        maxValue = self._maxValue

    if (ARG_PRESENT(subsampleMethod)) then $
        subsampleMethod = self._subsampleMethod

    if (ARG_PRESENT(symSize)) then $
        symSize = (self._oSymbol)._symbolSize

    if (ARG_PRESENT(thick)) then $
        self._oLine->GetProperty, THICK=thick

    if ARG_PRESENT(transparency) then begin
        self._oLine->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if (ARG_PRESENT(vectorStyle)) then $
        vectorStyle = self._vectorStyle

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
;   Any keyword to IDLitVisVector::Init followed by the word "Set"
;   can be set using this method.
;
pro IDLitVisVector::SetProperty, $
    ANTIALIAS=antialias, $
    ARROW_STYLE=arrowStyle, $
    ARROW_THICK=arrowThick, $
    AUTO_COLOR=autoColor, $
    AUTO_RANGE=autoRange, $
    AUTO_SUBSAMPLE=autoSubsample, $
    COLOR=color, $
    DATA_LOCATION=dataLocation, $
    DIRECTION_CONVENTION=directionConvention, $
    GRID_UNITS=gridUnits, $
    HEAD_ANGLE=headAngle, $
    HEAD_INDENT=headIndent, $
    HEAD_PROPORTIONAL=headProportional, $
    HEAD_SIZE=headSize, $
    LENGTH_SCALE=lengthScale, $
    MARK_POINTS=markPoints, $  ; obsolete but keep for BC
    MAX_VALUE=maxValue, $
    MIN_VALUE=minValue, $
    RGB_TABLE=rgbTable, $
    SYM_SIZE=symSize, $
    SUBSAMPLE_METHOD=subsampleMethod, $
    THICK=thick, $
    TRANSPARENCY=transparency, $
    VECTOR_STYLE=vectorStyle, $
    VISUALIZATION_PALETTE=visPalette, $
    X_SUBSAMPLE=xSubsample, $
    Y_SUBSAMPLE=ySubsample, $
    ZVALUE=zValue, $
    X_VIS_LOG=xVisLog, $
    Y_VIS_LOG=yVisLog, $
    Z_VIS_LOG=zVisLog, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(gridUnits) ne 0) then begin
        if (ISA(gridUnits, 'STRING')) then begin
          case (STRLOWCASE(gridUnits)) of
          'm': self._gridUnits = 1
          'meters': self._gridUnits = 1
          'deg': self._gridUnits = 2
          'degrees': self._gridUnits = 2
          else: self._gridUnits = 0
          endcase
        endif else begin
          self._gridUnits = gridUnits
        endelse
        ; Change to isotropic for units = meters or degrees.
        wasIsotropic = self->IsIsotropic()
        isIsotropic = self._gridUnits eq 1 || self._gridUnits eq 2
        if (wasIsotropic ne isIsotropic) then begin
            self->IDLitVisualization::SetProperty, ISOTROPIC=isIsotropic
        endif
        ; If units changed we may need to recalculate our vectors.
        self->_UpdateData
        ; If isotropy changed then update our dataspace as well.
        if (wasIsotropic ne isIsotropic) then begin
            self->OnDataChange, self
            self->OnDataComplete, self
        endif
    endif

    if (N_ELEMENTS(antialias) gt 0) then begin
        self._oLine->SetProperty, ANTIALIAS=antialias
    endif

    if (N_ELEMENTS(arrowStyle) gt 0) then begin
        self._arrowStyle = arrowStyle
        self._oPoly->SetProperty, HIDE=(self._arrowStyle eq 0)
;        self._oPoly->SetProperty, STYLE=(self._arrowStyle eq 0) ? 1 : 2
;        self._oLine->SetProperty, /HIDE
    endif

    if (N_ELEMENTS(arrowThick) gt 0) then begin
        self._arrowThick = arrowThick
        self->_UpdateData
    endif

    if (N_ELEMENTS(autoColor) gt 0) then begin
        self._autoColor = autoColor
        self->_UpdateData
    endif

    if (N_ELEMENTS(autoRange) gt 0) then begin
        self._autoRange = autoRange
        self->_UpdateData
    endif

    if (N_ELEMENTS(autoSubsample) gt 0) then begin
        self._autoSubsample = autoSubsample
        self->SetPropertyAttribute, 'X_SUBSAMPLE', $
            SENSITIVE=~self._autoSubsample
        self->SetPropertyAttribute, 'Y_SUBSAMPLE', $
            SENSITIVE=~self._autoSubsample
        if (self._autoSubsample) then $
            self->_UpdateData
    endif

    IF (n_elements(color) GT 0) THEN BEGIN
        self._color = color
        self._oLine->SetProperty, COLOR=color
        self._oPoly->SetProperty, COLOR=color
        ; Because we intercept COLOR, we need to manually send to the symbol.
        self._oSymbol->SetProperty, COLOR=color
    ENDIF

    if (N_ELEMENTS(dataLocation) gt 0) then begin
      if (ISA(dataLocation, 'STRING')) then begin
        case STRUPCASE(dataLocation) of
        'TAIL': self._dataLocation = 0
        'CENTER': self._dataLocation = 1
        'HEAD': self._dataLocation = 2
        endcase
      endif else begin
        self._dataLocation = dataLocation
      endelse
      self->_UpdateData
    endif

    if (N_ELEMENTS(directionConvention) gt 0) then begin
      if (ISA(directionConvention, 'STRING')) then begin
        case STRUPCASE(STRMID(directionConvention,0,3)) of
        'POL': self._directionConvention = 0  ; polar
        'MET': self._directionConvention = 1  ; meteorological
        'WIN': self._directionConvention = 2  ; wind azimuth
        endcase
      endif else begin
        self._directionConvention = directionConvention
      endelse
      self->_UpdateData
    endif

    if (N_ELEMENTS(headAngle) gt 0 && headAngle gt 0) then begin
        self._headAngle = ABS(headAngle)
        self->_UpdateData
    endif

    if (N_ELEMENTS(headIndent) gt 0) then begin
        self._headIndent = headIndent
        self->_UpdateData
    endif

    if (N_ELEMENTS(headProportional) gt 0) then begin
        self._headProportional = headProportional
        self->_UpdateData
    endif

    if (N_ELEMENTS(headSize) gt 0) then begin
        self._headSize = headSize
        self->_UpdateData
    endif

    if (N_ELEMENTS(lengthScale) gt 0) then begin
        self._lengthScale = lengthScale
        self->_UpdateData
    endif

    if (N_ELEMENTS(markPoints) gt 0) then begin
        self._markPoints = markPoints
        self._oSymbol->SetProperty, SYM_INDEX=3*self._markPoints
        self->_UpdateData
    endif

    if (N_ELEMENTS(minValue) gt 0 && minValue ge 0) then begin
        self._minValue = minValue
        self->GetPropertyAttribute, 'MIN_VALUE', $
            UNDEFINED=undef
        newUndef = self._minValue eq 0
        if (undef ne newUndef) then begin
            self->SetPropertyAttribute, 'MIN_VALUE', UNDEFINED=newUndef
            ; Notify our observers in case the prop sheet is visible.
            self->DoOnNotify, self->GetFullIdentifier(), $
                'SETPROPERTY', 'MIN_VALUE'
        endif
        self->_UpdateData
    endif

    if (N_ELEMENTS(maxValue) gt 0 && maxValue ge 0) then begin
        self._maxValue = maxValue
        self->GetPropertyAttribute, 'MIN_VALUE', $
            UNDEFINED=undef
        newUndef = self._maxValue eq 0
        if (undef ne newUndef) then begin
            self->SetPropertyAttribute, 'MAX_VALUE', UNDEFINED=newUndef
            ; Notify our observers in case the prop sheet is visible.
            self->DoOnNotify, self->GetFullIdentifier(), $
                'SETPROPERTY', 'MAX_VALUE'
        endif
        self->_UpdateData
    endif

    if (N_ELEMENTS(symSize) gt 0) then begin
        oSym = self._oSymbol
        oSym._symbolSize = symSize
        self->_UpdateData
    endif

    if (N_ELEMENTS(subsampleMethod) gt 0) then begin
        self._subsampleMethod = subsampleMethod
        self->_UpdateData
    endif

    if (N_ELEMENTS(transparency)) then begin
        alpha = 0 > ((100.-transparency)/100) < 1
        self._oLine->SetProperty, ALPHA_CHANNEL=alpha
        self._oPoly->SetProperty, ALPHA_CHANNEL=alpha
        self._oSymbol->SetProperty, SYM_TRANSPARENCY=transparency
    endif

    if (N_ELEMENTS(vectorStyle) gt 0) then begin
        self._vectorStyle = KEYWORD_SET(vectorStyle)
        self->SetPropertyAttribute, ['HEAD_ANGLE', 'HEAD_INDENT', $
            'ARROW_STYLE', 'HEAD_PROPORTIONAL', 'ARROW_THICK'], $
            SENSITIVE=vectorStyle eq 0
        ; Notify our observers in case the prop sheet is visible.
        self->DoOnNotify, self->GetFullIdentifier(), $
            'SETPROPERTY', ''
        self->_UpdateData
    endif

    if (N_ELEMENTS(thick) gt 0) then begin
        self._oLine->SetProperty, THICK=thick
        self._oPoly->SetProperty, THICK=thick
        self._oSymbol->SetProperty, SYM_THICK=thick
    endif

    if (N_ELEMENTS(xSubsample) gt 0 && xSubsample ge 1) then begin
        self._xSubsample = xSubsample
        self->_UpdateData
    endif

    if (N_ELEMENTS(ySubsample) gt 0 && ySubsample ge 1) then begin
        self._ySubsample = ySubsample
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
    
    if obj_valid(self._oPalette) && (N_ELEMENTS(visPalette) gt 0) then begin
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
;   This method is used to retrieve the data from the parameters
;
; Arguments:
;   U, V, X, Y
;
; Keywords:
;   NONE
;
pro IDLitVisVector::GetData, uData, vData, xData, yData, _EXTRA=_extra
  compile_opt idl2, hidden
  
  oDataU = self->GetParameter('U component')
  if (OBJ_VALID(oDataU)) then $
    void = oDataU->GetData(uData)
  oDataV = self->GetParameter('V component')
  if (OBJ_VALID(oDataV)) then $
    void = oDataV->GetData(vData)
  oDataX = self->GetParameter('X')
  if (OBJ_VALID(oDataX)) then $
    void = oDataX->GetData(xData)
  oDataY = self->GetParameter('Y')
  if (OBJ_VALID(oDataY)) then $
    void = oDataY->GetData(yData)
    
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   U, V, X, Y
;
; Keywords:
;   NONE
;
pro IDLitVisVector::PutData, uData, vData, xData, yData, _EXTRA=_extra
  compile_opt idl2, hidden
  
  n = N_PARAMS()
  
  if (n gt 0) then begin
    if ((n ne 2) && (n ne 4)) then return
    ndim = SIZE(uData, /N_DIMENSIONS)
    if (ndim ne 1 && ndim ne 2) then return
    dim = SIZE(uData, /DIMENSIONS)
    if (~ARRAY_EQUAL(dim, SIZE(vData, /DIMENSIONS))) then return
    if (ndim eq 1 && n ne 4) then return

    if (n eq 4) then begin
      if (SIZE(xData, /N_DIMENSIONS) ne 1) then return
      if (N_ELEMENTS(xData) ne dim[0]) then return
      if (SIZE(yData, /N_DIMENSIONS) ne 1) then return
      if ((ndim eq 2 && N_ELEMENTS(yData) ne dim[1]) || $
        (ndim eq 1 && N_ELEMENTS(yData) ne dim[0])) then return
        
      oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                         /AUTO_DELETE)

      oData3 = OBJ_NEW('IDLitDataIDLVector', xData, NAME='X', /AUTO_DELETE)
      oData4 = OBJ_NEW('IDLitDataIDLVector', yData, NAME='Y', /AUTO_DELETE)
      oParmSet->Add, oData3, PARAMETER_NAME='X'
      oParmSet->Add, oData4, PARAMETER_NAME='Y'
    endif

    if (~OBJ_VALID(oParmSet)) then $ 
      oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                         /AUTO_DELETE)
    
    class = ndim eq 2 ? 'IDLitDataIDLArray2d' : 'IDLitDataIDLVector'
    oData1 = OBJ_NEW(class, uData, NAME='U component', /AUTO_DELETE)
    oData2 = OBJ_NEW(class, vData, NAME='V component', /AUTO_DELETE)
    oParmSet->Add, oData1, PARAMETER_NAME='U component'
    oParmSet->Add, oData2, PARAMETER_NAME='V component'
  endif
  
  void = self->SetParameterSet(oParmSet)

;  self->OnDataChangeUpdate, void, '<PARAMETER SET>'
;  oTool = self->GetTool()
;  if (OBJ_VALID(oTool)) then $
;    oTool->RefreshCurrentWindow
  
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
function IDLitVisVector::EditUserDefProperty, oTool, identifier
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
end

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
pro IDLitVisVector::EnsurePalette

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
        return
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

    if (OBJ_VALID(oParent)) then begin
        oParent->Add, oPalette
    endif else begin
        self->AddByIdentifier, '/DATA MANAGER', oPalette
    endelse
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to compute the direction.
;
function IDLitVisVector::_ComputeDirection, udata, vdata

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
;   Internal method to keep only good points.
;
function IDLitVisVector::_FilterArrays, good, udata, vdata, xdata, ydata, $
    magnitude, sign, vectorColors, udatawarp, vdatawarp

    compile_opt idl2, hidden

    nElts = N_Elements(magnitude)
    ngood = N_Elements(good)
    if (ngood eq nElts) then return, nElts

    ; Remove out-of-range points.
    magnitude = magnitude[good]
    xdata = xdata[good]
    ydata = ydata[good]
    udata = udata[good]
    vdata = vdata[good]
    if (N_Elements(sign) eq nElts) then sign = sign[good]
    if (N_Elements(udatawarp) eq nElts) then begin
        udatawarp = udatawarp[good]
        vdatawarp = vdatawarp[good]
    endif
    if (N_Elements(vectorColors) ge nElts) then begin
        ; RGB or indexed color?
        vectorColors = (Size(vectorColors, /N_DIM) eq 2) ? $
            vectorColors[*, good] : vectorColors[good]
    endif

    return, ngood
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
; Keywords:
;   MAP_PROJECTION: An optional input giving the map projection structure.
;       This is provided for calling convenience. If MAP_PROJECTION is not
;       provided it will be retrieved.
;   SUBSAMPLE: If set then this method is being called because
;       the View Zoom has changed. In this case much of the internals
;       can be skipped.
;
function IDLitVisVector::_GetData, udata, vdata, xdata, ydata, $
    magnitude, sign, vectorColors, udatawarp, vdatawarp, $
    MAP_PROJECTION=sMap, $
    SUBSAMPLE=subsample

    compile_opt idl2, hidden

    ; Check for U & V.
    oDataU = self->GetParameter('U component')
    oDataV = self->GetParameter('V component')
    if (~OBJ_VALID(oDataU) || ~OBJ_VALID(oDataV)) then return, 0
    if (~oDataU->GetData(udata) || ~oDataV->GetData(vdata)) then $
        return, 0

    dims = SIZE(udata, /DIMENSIONS)
    ndim = N_ELEMENTS(dims)
    nElts = N_ELEMENTS(udata)
    if (nElts ne N_ELEMENTS(vdata)) then $
        return, 0

    ; Disable subsampling for 1-dimensional inputs.
    if (ndim eq 1) then $
        self._autoSubsample = 0

    ; Enable subsampling for gridded data.
    self->SetPropertyAttribute, ['AUTO_SUBSAMPLE', 'SUBSAMPLE_METHOD'], $
        SENSITIVE=(ndim gt 1)
    self->SetPropertyAttribute, ['X_SUBSAMPLE', 'Y_SUBSAMPLE'], $
        SENSITIVE=(ndim gt 1) && ~self._autoSubsample

    ; Automatic subsampling?
    if (self._autoSubsample) then begin

        ; Retrieve window and view zoom factors.
        oTool = self->GetTool()
        oWin = OBJ_VALID(oTool) ? oTool->GetCurrentWindow() : OBJ_NEW()
        winZoom = 1.0
        viewZoom = 1.0
        if (OBJ_VALID(oWin)) then begin
            oWin->GetProperty, CURRENT_ZOOM=winZoom
            oView = oWin->GetCurrentView()
            if (OBJ_VALID(oView)) then begin
                oView->GetProperty, CURRENT_ZOOM=viewZoom
            endif
        endif

        zoomFactor = winZoom*viewZoom

        oldsubX = self._xSubsample
        oldsubY = self._ySubsample

        ; Arbitrarily choose a subsampling factor based
        ; upon the data dimensions.
        self._xSubsample = 1 > (dims[0]/40.0)/zoomFactor < dims[0]/4
        self._ySubsample = 1 > (dims[1]/40.0)/zoomFactor < dims[1]/4

        ; Notify my observers (like the property sheet).
        if (oldSubX ne self._xSubsample || $
            oldSubY ne self._ySubsample) then begin
            if (OBJ_VALID(oTool)) then begin
                oTool->DoOnNotify, self->GetFullIdentifier(), $
                    'SETPROPERTY', ''
            endif
        endif else begin
            ; If we are simply doing a view zoom and the subsampling
            ; hasn't changed, bail early.
            if KEYWORD_SET(subsample) then return, 0
        endelse

    endif

    ; Check for X and Y.
    oDataX = self->GetParameter('X')
    oDataY = self->GetParameter('Y')
    if (~OBJ_VALID(oDataX) || ~oDataX->GetData(xdata) || $
        ~OBJ_VALID(oDataY) || ~oDataY->GetData(ydata)) then begin
        ; If U & V are vectors then you must supply X & Y.
        if (N_ELEMENTS(dims) eq 1) then $
            return, 0
        xdata = LINDGEN(dims[0], dims[1]) mod dims[0]
        ydata = LINDGEN(dims[0], dims[1])/dims[0]
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

    oVectorColors = self->GetParameter('VECTOR COLORS')
    hasColors = OBJ_VALID(oVectorColors) && $
        oVectorColors->GetData(pVectorColors, /POINTER)
    if (hasColors) then begin
        vndim = SIZE(*pVectorColors, /N_DIMENSIONS)
        vdims = SIZE(*pVectorColors, /DIMENSIONS)
        ; If first dim is 3 or 4 then assume RGB(A).
        hasRGB = vndim eq 2 && (vdims[0] eq 3 || vdims[0] eq 4)
        nColors = hasRGB ? vdims[1] : N_ELEMENTS(*pVectorColors)
        ; Sanity check. Make sure we have enough colors.
        if (nColors ne N_ELEMENTS(udata)) then hasColors = 0b
    endif
    ; If we have vector colors, then change the AUTO_COLOR enumlist.
    enumlist = [(hasColors ? 'Vector colors' : 'None'), $
        'Magnitude', 'Direction']
    self->SetPropertyAttribute, 'AUTO_COLOR', ENUMLIST=enumlist

    useColors = self._autoColor eq 0 && hasColors
    if (useColors) then begin
        vectorColors = *pVectorColors
        ; Make sure we are either 3D (for RGB) or 2D.
        if (ndim gt 1) then begin
            if (hasRGB) then begin
                vectorColors = REFORM(vectorColors, $
                    vdims[0], dims[0], dims[1], /OVERWRITE)
            endif else begin
                vectorColors = REFORM(vectorColors, dims[0], dims[1], $
                    /OVERWRITE)
            endelse
        endif
    endif

    ; Apply subsampling?
    if (ndim gt 1) then begin
        nx = LONG(DOUBLE(dims[0])/(self._xSubsample>1))
        nx = 4 > nx < dims[0]
        ny = LONG(DOUBLE(dims[1])/(self._ySubsample>1))
        ny = 4 > ny < dims[1]
        if (nx ne dims[0] || ny ne dims[1]) then begin
            if (self._subsampleMethod eq 1) then begin ; linear
                udata = CONGRID(udata, nx, ny, /CENTER, /INTERP)
                vdata = CONGRID(vdata, nx, ny, /CENTER, /INTERP)
                xdata = CONGRID(xdata, nx, ny, /CENTER, /INTERP)
                ydata = CONGRID(ydata, nx, ny, /CENTER, /INTERP)
                if (useColors) then begin
                    if (hasRGB) then begin
                        vectorColors = CONGRID(vectorColors, vdims[0], nx, ny, $
                            /CENTER, INTERP=interp)
                    endif else begin
                        vectorColors = CONGRID(vectorColors, nx, ny, $
                            /CENTER, INTERP=interp)
                    endelse
                endif
            endif else begin  ; nearest neighbor
                ; Because of memory layout, it is faster
                ; to do the Y subsampling first.
                if (ny ne dims[1]) then begin
                    idx = LINDGEN(ny)*self._ySubsample + self._ySubsample/2
                    udata = udata[*, idx]
                    vdata = vdata[*, idx]
                    xdata = xdata[*, idx]
                    ydata = ydata[*, idx]
                    if (useColors) then begin
                        vectorColors = hasRGB ? $
                            vectorColors[*, *, idx] : vectorColors[*, idx]
                    endif
                endif
                if (nx ne dims[0]) then begin
                    idx = LINDGEN(nx)*self._xSubsample + self._xSubsample/2
                    udata = udata[idx, *]
                    vdata = vdata[idx, *]
                    xdata = xdata[idx, *]
                    ydata = ydata[idx, *]
                    if (useColors) then begin
                        vectorColors = hasRGB ? $
                            vectorColors[*, idx, *] : vectorColors[idx, *]
                    endif
                endif
            endelse
            nElts = N_ELEMENTS(udata)
        endif
    endif

    ; We now want U, V, X, Y, all as vectors.
    udata = REFORM(udata, nElts, /OVERWRITE)
    vdata = REFORM(vdata, nElts, /OVERWRITE)
    xdata = REFORM(xdata, nElts, /OVERWRITE)
    ydata = REFORM(ydata, nElts, /OVERWRITE)
    if (useColors) then begin
        vectorColors = hasRGB ? $
            REFORM(vectorColors, vdims[0], nElts, /OVERWRITE) : $
            REFORM(vectorColors, nElts, /OVERWRITE)
    endif

    magnitude = SQRT(udata*udata + vdata*vdata)

    ; Apply map projection
    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    ; Which hemisphere are we in? Only care for wind barbs.
    ; Also don't worry about hemisphere for no grid units.
    if (self._vectorStyle eq 1 && self._gridUnits ge 1) then begin
        ; If units are lat/lon (or we have no map projection)
        ; then just compute the hemisphere.
        if (self._gridUnits eq 2 || ~N_TAGS(sMap)) then begin
            sign = 2s*(ydata ge 0) - 1s
        endif else begin
            ; For grid units of meters, need to inverse project.
            lonlat = Map_Proj_Inverse(xdata, ydata, MAP_STRUCTURE=sMap)
            lats = Reform(lonlat[1,*])
            lonlat = 0
            ; Just naively set out-of-bounds values to zero.
            miss = Where(~Finite(lats), nmiss)
            if (nmiss gt 0) then lats[miss] = 0
            sign = 2s*(Temporary(lats) ge 0) - 1s
        endelse
    endif else begin
        ; Do not make a distinction between north/south
        sign = 1
    endelse

    ; For grid units = none or meters, don't need to warp.
    ; Otherwise, for degrees, we need to warp.
    if (self._gridUnits eq 2 && N_TAGS(sMap) gt 0) then begin
        ; We need to manually clip the out-of-bounds points.
        good = WHERE(xdata ge sMap.ll_box[1] and $
            xdata le sMap.ll_box[3] and $
            ydata ge sMap.ll_box[0] and $
            ydata le sMap.ll_box[2] and $
            magnitude gt 0, ngood)
        if (~ngood) then goto, clipAll
        nElts = self->_FilterArrays(good, udata, vdata, xdata, ydata, $
            magnitude, sign, vectorColors, 0, 0)

        ; Project the locations.
        ; First project the start of each vector.
        xystart = MAP_PROJ_FORWARD(xdata, ydata, MAP_STRUCTURE=sMap)

        ; Now project the endpoints, so we can determine if the
        ; projection changes the orientation of the vectors.
        ; We don't want to treat the U and V as distances on the map,
        ; so take a tiny step in the appropriate direction.
        xTip = sMap.ll_box[1] > $
            (xdata + 1d-4*udata/magnitude) < sMap.ll_box[3]
        yTip = sMap.ll_box[0] > $
            (ydata + 1d-4*vdata/magnitude) < sMap.ll_box[2]
        xyTipwarp = MAP_PROJ_FORWARD(TEMPORARY(xTip), TEMPORARY(yTip), $
            MAP_STRUCTURE=sMap)
        uwarp = REFORM(xyTipwarp[0, *] - xystart[0,*])
        vwarp = REFORM(xyTipwarp[1, *] - xystart[1,*])
        xyTipwarp = 0
        length = SQRT(uwarp^2 + vwarp^2)
        ; Find the new U and V components.
        udatawarp = magnitude*(TEMPORARY(uwarp)/length)
        vdatawarp = magnitude*(TEMPORARY(vwarp)/length)

        ; New warped locations.
        xdata = xystart[0, *]
        ydata = xystart[1, *]
        xystart = 0

        ; Now clip out all non-finite values.
        good = WHERE(FINITE(xdata) and FINITE(ydata) and $
            FINITE(udatawarp) and FINITE(vdatawarp), ngood)
        if (~ngood) then goto, clipAll
        nElts = self->_FilterArrays(good, udata, vdata, xdata, ydata, $
            magnitude, sign, vectorColors, udatawarp, vdatawarp)

    endif else begin
        udatawarp = udata
        vdatawarp = vdata
    endelse

    ; Clip to min/max values.
    ngood = nElts
    minValue = self._minValue

    ; Min value for wind barbs is at least 5.
    ; Make sure to filter out winds less than this value.
    if (self._vectorStyle eq 1) then minValue >= 0.5

    if (minValue gt 0) then begin
        if (self._maxValue gt 0) then begin
            good = WHERE(magnitude ge minValue and $
                magnitude le self._maxValue, ngood, COMPLEMENT=bad)
        endif else begin
            good = WHERE(magnitude ge minValue, ngood, COMPLEMENT=bad)
        endelse
    endif else if (self._maxValue gt 0) then begin
        good = WHERE(magnitude ne 0 and $
            magnitude le self._maxValue, ngood, COMPLEMENT=bad)
    endif else begin
        ; If min/max not set, just remove zeroes.
        if (self._vectorStyle eq 0) then begin
            good = WHERE(magnitude ne 0, ngood, COMPLEMENT=bad)
        endif else begin
            ngood = nElts
        endelse
    endelse

    ; Mark out-of-range points.
    if (ngood lt nElts) then begin
        nbad = nElts - ngood
        self._oMiss->SetProperty, HIDE=0, $
            DATA=[TRANSPOSE(xdata[bad]), TRANSPOSE(ydata[bad])]
    endif else begin
        self._oMiss->SetProperty, DATA=DBLARR(2,3), /HIDE
    endelse

    ; All points were clipped. Bail.
    if (ngood eq 0) then goto, clipAll

    ; Remove out-of-range points.
    if (ngood ne nElts) then begin
      nElts = self->_FilterArrays(good, udata, vdata, xdata, ydata, $
        magnitude, sign, vectorColors, udatawarp, vdatawarp)
    endif

    return, nElts

clipAll:

    self._oLine->SetProperty, DATA=DBLARR(2,2), POLYLINES=0, /HIDE, $
        LABEL_POLYLINES=0
    self._oPoly->SetProperty, DATA=DBLARR(2,3), POLYGONS=0, /HIDE
    return, 0
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
pro IDLitVisVector::_UpdateArrows, $
    udatawarp, vdatawarp, magnitude, vectorColors, $
    lengthScaleX, lengthScaleY

    compile_opt idl2, hidden

    nElts = N_ELEMENTS(udatawarp)
    hasZvalue = self._zValue ne 0
    useColors = N_ELEMENTS(vectorColors) gt 0
    hasRGB = SIZE(vectorColors, /N_DIM) eq 2 || N_ELEMENTS(vectorColors) eq 3
    lengthScale = (self._lengthScale ne 0) ? self._lengthScale : 1d-9
    headSize = 0.25*self._headSize/lengthScale
    ; For proportional heads, increase the average size. Looks better.
    if (self._headProportional) then headSize *= 2
    xyScale = self._lengthX/self._lengthY

    xdata = *self._pXdata
    ydata = *self._pYdata

    ; Compute the length of each vector.
    maxMagnitude = MAX(magnitude)
    xdelta = udatawarp*(lengthScaleX/maxMagnitude)
    ydelta = vdatawarp*(lengthScaleY/maxMagnitude)
    scaledMagSquared = xdelta^2 + ydelta^2

    ; set the end point vertices
    case (self._dataLocation) of
    0: begin  ; tail
        xTip = xdata + xdelta
        yTip = ydata + ydelta
       end
    1: begin  ; center
        xTip = xdata + xdelta/2
        yTip = ydata + ydelta/2
        xdata -= xdelta/2
        ydata -= ydelta/2
       end
    2: begin  ; head
        xTip = xdata
        yTip = ydata
        xdata -= xdelta
        ydata -= ydelta
       end
    endcase

    ; Make all arrowheads the same size?
    if (~self._headProportional) then begin
        xdelta = lengthScaleX*udatawarp/magnitude
        ydelta = lengthScaleY*vdatawarp/magnitude
    endif

    rCosTheta = headSize*COS(self._headAngle*!DPI/180)
    rSinTheta = headSize*SIN(self._headAngle*!DPI/180)

    ; Intersection of the arrowhead tips with the shaft.
    xMid = xTip - rCosTheta*xdelta
    yMid = yTip - rCosTheta*ydelta
    ; Note that we need to apply the aspect ratio to the
    ; tips of the arrowhead, since they are off the shaft.
    dHeadX = (xyScale*rSinTheta)*ydelta
    dHeadY = ((1/xyScale)*rSinTheta)*xdelta
    ; These will already have the aspect ratio factor applied.
    xShaftThick = ((self._arrowThick-1)/20d)*dHeadX
    yShaftThick = ((self._arrowThick-1)/20d)*dHeadY

    ; Back of the arrowhead.
    ; Head indent ranges from -1 (diamond) to +1 (thin edge).
    dHeadBackX = (1-self._headIndent)*rCosTheta*TEMPORARY(xdelta)
    dHeadBackY = (1-self._headIndent)*rCosTheta*TEMPORARY(ydelta)
    xHeadBack = xTip - dHeadBackX
    yHeadBack = yTip - dHeadBackY
    magHeadBackSq = TEMPORARY(dHeadBackX)^2 + TEMPORARY(dHeadBackY)^2
    ; Arrow length is less than the head indent. Need to clip.
    tooShort = TEMPORARY(scaledMagSquared) lt TEMPORARY(magHeadBackSq)

    ; End point for lines. Use tooShort mask to clip.
    xEnd = xdata + (xHeadBack - xdata)*tooShort
    yEnd = ydata + (yHeadBack - ydata)*TEMPORARY(tooShort)

    p = 8
    polyvert = DBLARR(2 + hasZvalue, p*nElts, /NOZERO)
    if (hasZvalue) then begin
        polyvert[2, *] = self._zValue
    endif
    polyvert[0, 0:*:p] = xTip
    polyvert[1, 0:*:p] = yTip
    polyvert[0, 1:*:p] = xMid - dHeadX
    polyvert[1, 1:*:p] = yMid + dHeadY
    polyvert[0, 2:*:p] = xHeadBack - xShaftThick
    polyvert[1, 2:*:p] = yHeadBack + yShaftThick
    polyvert[0, 3:*:p] = xEnd - xShaftThick
    polyvert[1, 3:*:p] = yEnd + yShaftThick
    ; Start clearing out these temp vars.
    polyvert[0, 4:*:p] = TEMPORARY(xEnd) + xShaftThick
    polyvert[1, 4:*:p] = TEMPORARY(yEnd) - yShaftThick
    polyvert[0, 5:*:p] = TEMPORARY(xHeadBack) + TEMPORARY(xShaftThick)
    polyvert[1, 5:*:p] = TEMPORARY(yHeadBack) - TEMPORARY(yShaftThick)
    polyvert[0, 6:*:p] = TEMPORARY(xMid) + TEMPORARY(dHeadX)
    polyvert[1, 6:*:p] = TEMPORARY(yMid) - TEMPORARY(dHeadY)
    polyvert[0, 7:*:p] = TEMPORARY(xTip)
    polyvert[1, 7:*:p] = TEMPORARY(yTip)

    ; Construct array of nElts polygons, each with p vertices.
    polygons = [LONARR(1, nElts)+p, LINDGEN(p, nElts)]
    polygons = REFORM(polygons, (p+1)*nElts)

    if (useColors) then begin
        if (hasRGB) then begin
            vdims = SIZE(vectorColors, /DIMENSIONS)
            vectorColors = REFORM(vectorColors, vdims[0], 1, nElts, /OVERWRITE)
            polyColors = REFORM(REBIN(vectorColors, vdims[0], p, nElts), $
                vdims[0], p*nElts)
        endif else begin
            vectorColors = REFORM(vectorColors, 1, nElts, /OVERWRITE)
            polyColors = REFORM(REBIN(vectorColors, p, nElts), p*nElts)
        endelse
    endif else begin
        polyColors = 0
    endelse

    self._oPoly->SetProperty, DATA=polyvert, $
        POLYGONS=polygons, $
        VERT_COLORS=polyColors, $
        HIDE=self._arrowStyle eq 0, $
        STYLE=(self._arrowStyle eq 0) ? 1 : 2

;    self._oLine->SetProperty, DATA=DBLARR(2,2), POLYLINES=0, /HIDE, $
;        LABEL_POLYLINES=0
    self._oLine->SetProperty, DATA=polyvert, $
        LABEL_OBJECTS=OBJ_NEW(), $
        LABEL_POLYLINES=0, $
        POLYLINES=polygons, $
        VERT_COLORS=polyColors, $
        HIDE=0
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
pro IDLitVisVector::_UpdateWindBarbs, $
    udatawarp, vdatawarp, magnitude, vectorColors, $
    lengthScaleX, lengthScaleY

    compile_opt idl2, hidden

    nElts = N_ELEMENTS(udatawarp)
    hasZvalue = self._zValue ne 0
    useColors = N_ELEMENTS(vectorColors) gt 0
    hasRGB = SIZE(vectorColors, /N_DIM) eq 2
    lengthScale = (self._lengthScale ne 0) ? self._lengthScale : 1d-9
    headSize = 0.5*self._headSize/lengthScale
    xyScale = self._lengthX/self._lengthY

    xdata = *self._pXdata
    ydata = *self._pYdata
    xdelta = 0.5*lengthScaleX*udatawarp/(magnitude + 1e10*(magnitude lt 0.5))
    ydelta = 0.5*lengthScaleY*vdatawarp/(magnitude + 1e10*(magnitude lt 0.5))

    lineColors = 0
    polyColors = 0

    case (self._dataLocation) of
    0: begin  ; tail
        xTip = xdata + xdelta
        yTip = ydata + ydelta
       end
    1: begin  ; center
        xTip = xdata + xdelta/2
        yTip = ydata + ydelta/2
        xdata -= xdelta/2
        ydata -= ydelta/2
       end
    2: begin  ; head
        xTip = xdata
        yTip = ydata
        xdata -= xdelta
        ydata -= ydelta
       end
    endcase

    ; Initialize barbs.

    ; Number of flags. Add 2.5 so we get the midpoint of each "5" interval.
    lMagnitude = LONG(magnitude + 2.5)
    flags = lMagnitude/50

    ; Number of full barbs.
    fullFeather = (lMagnitude - 50*flags)/10

    ; Do we need a half barb?
    halfFeather = (TEMPORARY(lMagnitude) mod 10) ge 5

    ; Total number of polylines.
    totalNumLines = nElts + $
        TOTAL(fullFeather, /INTEGER) + $
        TOTAL(halfFeather, /INTEGER)
    linevert = DBLARR(2 + hasZvalue, 2 * totalNumLines, /NOZERO)

    ; Start & end point
    linevert[0, 0:2*nElts-2:2] = xdata
    linevert[1, 0:2*nElts-2:2] = ydata
    linevert[0, 1:2*nElts-1:2] = xTip
    linevert[1, 1:2*nElts-1:2] = yTip

    ; Advance to the end of the barb vertices.
    idx = 2*nElts

    ; How far off the barb to go for each feather/flag.
    xOffset = -xdelta * (0.2 * headSize) - $
        (*self._pSign)*ydelta*(xyScale*0.5*headSize)
    yOffset = -ydelta * (0.2 * headSize) + $
        (*self._pSign)*xdelta*(1/xyScale*0.5*headSize)

    ; Spacing between feathers/flags along the barb.
    xSpacing = TEMPORARY(xdelta)/10.
    ySpacing = TEMPORARY(ydelta)/10.

    ; Where to start the feathers.
    xFeather = xdata + (flags + (flags gt 0))*xSpacing
    yFeather = ydata + (flags + (flags gt 0))*ySpacing

    if (useColors) then begin
        if (hasRGB) then begin
            vdim0 = (SIZE(vectorColors, /DIMENSIONS))[0]
            lineColors = BYTARR(vdim0, 2*totalNumLines, /NOZERO)
            vc = REFORM(vectorColors, vdim0, 1, nElts)
            vc = REBIN(vc, vdim0, 2, nElts)
            vc = REFORM(vc, vdim0, 2*nElts, /OVERWRITE)
            lineColors[0,0] = TEMPORARY(vc)
        endif else begin
            lineColors = BYTARR(2 * totalNumLines, /NOZERO)
            vc = REFORM(vectorColors, 1, nElts)
            vc = REBIN(vc, 2, nElts)
            vc = REFORM(vc, 2*nElts, /OVERWRITE)
            lineColors[0] = TEMPORARY(vc)
        endelse
    endif

    ; Add feathers?
    maxFeather = MAX(fullFeather)

    if (maxFeather gt 0) then begin
        for i=1,maxFeather do begin
            ; Where do we need "i" or more feathers.
            loc = WHERE(fullFeather ge i, nloc)
            nMax = idx + 2*nloc - 1
            ; First vertex.
            x = xFeather[loc] + (i-1)*xSpacing[loc]
            y = yFeather[loc] + (i-1)*ySpacing[loc]
            linevert[0, idx:nMax:2] = x
            linevert[1, idx:nMax:2] = y
            ; Last vertex.
            linevert[0, idx+1:nMax:2] = x + xOffset[loc]
            linevert[1, idx+1:nMax:2] = y + yOffset[loc]
            if (useColors) then begin
                if (hasRGB) then begin
                    vc = REFORM(vectorColors[*, loc], vdim0, 1, nloc)
                    vc = REBIN(vc, vdim0, 2, nloc)
                    vc = REFORM(vc, vdim0, 2*nloc, /OVERWRITE)
                    lineColors[*, idx:nMax] = TEMPORARY(vc)
                endif else begin
                    lineColors[idx:nMax] = REBIN( $
                        REFORM(vectorColors[loc], 1, nloc), 2, nloc)
                endelse
            endif

            idx = nMax + 1
        endfor
    endif

    ; Add half feathers?
    loc = WHERE(halfFeather, nloc)
    if (nloc gt 0) then begin
        nMax = idx + 2*nloc - 1
        j = fullFeather[loc] + (fullFeather[loc] eq 0)*(~flags[loc])
        ; First vertex.
        x = xFeather[loc] + j*xSpacing[loc]
        y = yFeather[loc] + j*ySpacing[loc]
        linevert[0, idx:nMax:2] = x
        linevert[1, idx:nMax:2] = y
        ; Last vertex.
        linevert[0, idx+1:nMax:2] = x + 0.5*xOffset[loc]
        linevert[1, idx+1:nMax:2] = y + 0.5*yOffset[loc]
        if (useColors) then begin
            if (hasRGB) then begin
                vc = REFORM(vectorColors[*, loc], vdim0, 1, nloc)
                vc = REBIN(vc, vdim0, 2, nloc)
                vc = REFORM(vc, vdim0, 2*nloc, /OVERWRITE)
                lineColors[*, idx:nMax] = TEMPORARY(vc)
            endif else begin
                lineColors[idx:nMax] = REBIN( $
                    REFORM(vectorColors[loc], 1, nloc), 2, nloc)
            endelse
        endif
    endif

    ; Construct the connectivity array. Just a bunch of lines.
    idx = 2*LINDGEN(totalNumLines)
    polylines = LONARR(3*totalNumLines, /NOZERO)
    polylines[0:*:3] = 2
    polylines[1:*:3] = idx
    polylines[2:*:3] = idx + 1

    ; Add flag polygons?
    maxFlag = MAX(flags)

    if (maxFlag gt 0) then begin

        ; Number of separate flags (triangles) needed.
        totalNumPoly = TOTAL(flags, /INTEGER)
        polyvert = DBLARR(2 + hasZvalue, 3*totalNumPoly, /NOZERO)
        idx = 0L

        if (useColors) then begin
            polyColors = hasRGB ? BYTARR(vdim0, 3*totalNumPoly, /NOZERO) : $
                BYTARR(3*totalNumPoly, /NOZERO)
        endif

        for i=1,maxFlag do begin

            ; Where do we need "i" or more flags.
            loc = WHERE(flags ge i, nloc)

            ; Offsets of the flags along the barb.
            x = xdata[loc] + $
                ((i eq 1) ? 0 : (i - 1)*xSpacing[loc])
            y = ydata[loc] + $
                ((i eq 1) ? 0 : (i - 1)*ySpacing[loc])

            nMax = idx + 3*nloc - 1

            ; First flag vertex.
            polyvert[0, idx:nMax:3] = x
            polyvert[1, idx:nMax:3] = y
            ; Go along the barb for the next vertex.
            x += xSpacing[loc]
            y += ySpacing[loc]
            polyvert[0, idx+1:nMax:3] = x
            polyvert[1, idx+1:nMax:3] = y
            ; Last vertex is the tip of the flag.
            polyvert[0, idx+2:nMax:3] = x + xOffset[loc]
            polyvert[1, idx+2:nMax:3] = y + yOffset[loc]

            ; Make all 3 vertices the same color as the barb.
            if (useColors) then begin
                if (hasRGB) then begin
                    vc = REFORM(vectorColors[*, loc], vdim0, 1, nloc)
                    vc = REBIN(vc, vdim0, 3, nloc)
                    vc = REFORM(vc, vdim0, 3*nloc, /OVERWRITE)
                    polyColors[*, idx:nMax] = TEMPORARY(vc)
                endif else begin
                    polyColors[idx:nMax] = REBIN( $
                        REFORM(vectorColors[loc], 1, nloc), 3, nloc)
                endelse
            endif

            idx += 3*nloc

        endfor

        ; Construct the connectivity array. Just a bunch of triangles.
        idx = 3*LINDGEN(totalNumPoly)
        polygons = LONARR(4*totalNumPoly, /NOZERO)
        polygons[0:*:4] = 3
        polygons[1:*:4] = idx
        polygons[2:*:4] = idx + 1
        polygons[3:*:4] = idx + 2

    endif else begin
        ; No flags. Clear out the polygons.
        polyvert = DBLARR(2 + hasZvalue,3)
        polygons = 0
    endelse

    if (hasZvalue) then begin
        linevert[2,*] = self._zValue
        polyvert[2,*] = self._zValue
    endif

    self._oLine->SetProperty, DATA=linevert, $
        LABEL_OBJECTS=OBJ_NEW(), $
        LABEL_POLYLINES=0, $
        POLYLINES=polylines, $
        VERT_COLORS=lineColors, $
        HIDE=(N_ELEMENTS(polylines) le 1)

    self._oPoly->SetProperty, DATA=polyvert, $
        POLYGONS=polygons, $
        VERT_COLORS=polyColors, $
        HIDE=(N_ELEMENTS(polygons) le 1)
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
; Keywords:
;   MAP_PROJECTION: An optional input giving the map projection structure.
;       This is provided for calling convenience. If MAP_PROJECTION is not
;       provided it will be retrieved.
;   SUBSAMPLE: If set then this method is being called because
;       the View Zoom has changed. In this case much of the internals
;       can be skipped.
;   WITHIN_DRAW: If set then this method is being called from ::Draw,
;       and we don't want to do any special data notification.
;
pro IDLitVisVector::_UpdateData, $
    MAP_PROJECTION=sMap, $
    SUBSAMPLE=subsample, $
    WITHIN_DRAW=withinDraw

    compile_opt idl2, hidden

    ; Bail if we aren't part of a hierarchy.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if (~OBJ_VALID(oParent)) then $
        return

    withinDraw = KEYWORD_SET(withinDraw)

    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog
        self._xVisLog = xLog
        self._yVisLog = yLog
    endif

    nElts = self->_GetData(udata, vdata, xdata, ydata, $
        magnitude, sign, vectorColors, udatawarp, vdatawarp, $
        SUBSAMPLE=subsample, $
        MAP_PROJECTION=sMap)
    if (~nElts) then $
        return

    if (self._xVisLog) then begin
        xdata = ALOG10(xdata > 1d-10)
    endif
    if (self._yVisLog) then begin
        ydata = ALOG10(ydata > 1d-10)
    endif

    ; Compute range after taking logs.
    minX = MIN(xdata, MAX=maxX)
    minY = MIN(ydata, MAX=maxY)
    xrange = maxX - minX
    if (xrange eq 0) then xrange = 1
    yrange = maxY - minY
    if (yrange eq 0) then yrange = 1

    *self._pXdata = TEMPORARY(xdata)
    *self._pYdata = TEMPORARY(ydata)
    *self._pSign = TEMPORARY(sign)
    *self._pUdata = udata
    *self._pVdata = vdata

    ; Compute the current X/Y scale factors.
    lengthScale = (self._lengthScale ne 0) ? self._lengthScale : 1d-9
    xyScale = self._lengthX/self._lengthY
    xPixelRange = xrange/self._lengthX
    yPixelRange = yrange/self._lengthY
    symSize = 2*(self._oSymbol)._symbolSize/lengthScale

    if (yPixelRange gt xPixelRange) then begin
        lengthScaleX = 3*lengthScale/SQRT(nElts)*xrange
        lengthScaleY = lengthScaleX/xyScale
        symX = symSize
        symY = symSize/xyScale
    endif else begin
        lengthScaleY = 3*lengthScale/SQRT(nElts)*yrange
        lengthScaleX = lengthScaleY*xyScale
        symX = symSize*xyScale
        symY = symSize
    endelse

    (self._oSymbol->GetSymbol())->SetProperty, SIZE=[symX,symY]

    ; Set up the vectorColors array if necessary.
    case (self._autoColor) of
        1: vectorColors = magnitude
        2: vectorColors = self->_ComputeDirection(udata, vdata)
        else: ; vectorColors is either undefined or has been passed in
    endcase

    ; Are we coloring individual vectors?
    useColors = N_ELEMENTS(vectorColors) gt 0
    if (useColors) then begin
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
          mn = MIN(vectorColors, MAX=mx)
        endelse
        minmax = [mn, mx]
        if (~oAuxData->GetData(minmaxOld) || $
            ~ARRAY_EQUAL(minmax, minmaxOld)) then begin
            success = oAuxData->SetData([mn,mx], NO_NOTIFY=withinDraw)
        endif
        ; Be sure to bytescale non-byte data so we can use
        ; an auxiliary dataset for vector colors.
        if (SIZE(vectorColors, /TYPE) ne 1 || (self._autoRange[0] ne self._autoRange[1])) then $
            vectorColors = BYTSCL(vectorColors, MIN=mn, MAX=mx)
        self->EnsurePalette
    endif

    ; Sensitize VISUALIZATION_PALETTE property if using vector colors.
    self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', $
        SENSITIVE=useColors

    pal = useColors ? self._oPalette : OBJ_NEW()
    self._oLine->SetProperty, PALETTE=pal
    self._oPoly->SetProperty, PALETTE=pal

    ; Populate vertices
    case (self._vectorStyle) of
    0: begin    ; Arrows
        self->_UpdateArrows, udatawarp, vdatawarp, magnitude, vectorColors, $
            lengthScaleX, lengthScaleY
       end
    1: begin    ; wind barbs
        self->_UpdateWindBarbs, udatawarp, vdatawarp, magnitude, vectorColors, $
            lengthScaleX, lengthScaleY
       end
    else: return
    endcase

    if (~withinDraw) then begin
        self->OnDataChange
        self->OnDataComplete
    endif
end

;----------------------------------------------------------------------------
pro IDLitVisVector::OnDataDisconnect, ParmName

    compile_opt hidden, idl2

    self->_UpdateData
end

;----------------------------------------------------------------------------
pro IDLitVisVector::_CheckGridUnits, sMap

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
; IDLitVisVector::OnDataChangeUpdate
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
pro IDLitVisVector::OnDataChangeUpdate, oSubject, parmName

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

    self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], HIDE=0
    self->SetPropertyAttribute, 'MIN_VALUE', UNDEFINED=self._minValue eq 0
    self->SetPropertyAttribute, 'MAX_VALUE', UNDEFINED=self._maxValue eq 0

    ; Notify our observers in case the prop sheet is visible.
    self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

end

;----------------------------------------------------------------------------
pro IDLitVisVector::OnProjectionChange, sMap

    compile_opt idl2, hidden

    self->_CheckGridUnits, sMap
    self->_UpdateData, MAP_PROJECTION=sMap

end

;---------------------------------------------------------------------------
; Convert a location from decimal degrees to DDDdMM'SS", where "d" is
; the degrees symbol.
;
function IDLitVisVector::_DegToDMS, x

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
function IDLitVisVector::GetDataString, xyz

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
pro IDLitVisVector::OnWorldDimensionChange, oSubject, is3D

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

;-----------------------------------------------------------------------------
; Calculate the X/Y aspect ratio.
; Returns 1 if the aspect ratio has changed, 0 otherwise.
;
function IDLitVisVector::_ComputeAspect

    compile_opt idl2, hidden

    ; Find out if aspect ratio is still correct
    self->WindowToVis, [[0,0], [1d,0]], onePixel
    lengthX = ABS(onePixel[0,1] - onePixel[0,0])
    if (lengthX lt 1d-9) then $
        lengthX = ABS(onePixel[1,1] - onePixel[1,0])
    self->WindowToVis, [[0,0], [0,1d]], onePixel
    lengthY = ABS(onePixel[1,1] - onePixel[1,0])
    if (lengthY lt 1d-9) then $
        lengthY = ABS(onePixel[0,1] - onePixel[0,0])
    xyScale = lengthX/lengthY
    prevScale = self._lengthX/self._lengthY
    newAspect = ABS(xyScale - prevScale) gt 1d-4*ABS(xyScale)
    self._lengthX = lengthX
    self._lengthY = lengthY

    return, newAspect
end

;---------------------------------------------------------------------------
; Purpose:
;   This procedure method handles notification that the view zoom factor
;   has changed
;
pro IDLitVisVector::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    if (self._autoSubsample) then begin
        void = self->_ComputeAspect()
        self->_UpdateData, /SUBSAMPLE
    endif
end

;-----------------------------------------------------------------------------
; Override IDLgrModel::Draw so we can
; automatically adjust for changes in aspect ratio.
;
pro IDLitVisVector::Draw, oDest, oView

    compile_opt idl2, hidden

    ; Don't do extra work if we are in the lighting or selection pass.
    oDest->GetProperty, IS_BANDING=isBanding, $
        IS_LIGHTING=isLighting, IS_SELECTING=isSelecting

    if (~isLighting && ~isSelecting && ~isBanding) then begin
        if (self->_ComputeAspect()) then begin
            self->_UpdateData, /WITHIN_DRAW
        endif
    endif

    self->IDLitVisualization::Draw, oDest, oView
end

;----------------------------------------------------------------------------
; IDLitVisVector__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisVector object.
;
pro IDLitVisVector__Define

    compile_opt idl2, hidden

    struct = { IDLitVisVector,              $
        inherits IDLitVisualization,  $ ; Superclass: _IDLitVisualization
        _oLine: OBJ_NEW(), $
        _oPoly: OBJ_NEW(), $
        _oMiss: OBJ_NEW(), $
        _oPalette: OBJ_NEW(),         $ ; IDLgrPalette object
        _oSymbol: OBJ_NEW(), $
        _pXdata: PTR_NEW(), $
        _pYdata: PTR_NEW(), $
        _pUdata: PTR_NEW(), $
        _pVdata: PTR_NEW(), $
        _pSign: PTR_NEW(), $
        _color: [0b,0b,0b], $
        _gridUnits: 0b, $
        _vectorStyle: 0b, $
        _arrowStyle: 0b, $
        _headProportional: 0b, $
        _dataLocation: 0b, $
        _markPoints: 0b, $  ; unused but keep for backwards compat
        _autoColor: 0b, $
        _autoRange: [0d, 0d], $
        _autoSubsample: 0b, $
        _subsampleMethod: 0b, $
        _xVisLog : 0b, $
        _yVisLog : 0b, $
        _zVisLog : 0b, $
        _directionConvention: 0b, $
        _arrowThick: 0b, $
        _lengthX: 0d, $
        _lengthY: 0d, $
        _headSize: 0d, $
        _lengthScale: 0d, $
        _headAngle: 0d, $
        _headIndent: 0d, $
        _maxValue: 0d, $
        _minValue: 0d, $
        _zValue: 0d, $
        _xSubsample: 0L, $
        _ySubsample: 0L $
    }
end
