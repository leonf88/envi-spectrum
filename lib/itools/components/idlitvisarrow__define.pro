; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisarrow__define.pro#26 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   The IDLitVisArrow class is the component for vector visualization.
;
;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Syntax:
;
;    Obj = OBJ_NEW('IDLitVisArrow')
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
function IDLitVisArrow::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses
    if (~self->IDLitVisualization::Init(TYPE="IDLVISARROW", $
        ICON='fitwindow', $
        DESCRIPTION="An arrow Visualization", $
        NAME="Arrow", IMPACTS_RANGE=0, _EXTRA=_extra)) then $
        RETURN, 0

    ; Register all properties.
    self->IDLitVisArrow::_RegisterProperties
    
    ; This will also register our X parameter.
    dummy = self->_IDLitVisVertex::Init(POINTS_NEEDED=2)

    ; Add in our special manipulator visual.
    if (~KEYWORD_SET(noVertexVisual)) then begin
        self->SetDefaultSelectionVisual, OBJ_NEW('IDLitManipVisVertex', $
            /HIDE, PREFIX='LINE')
    endif
    
    self._oPoly = OBJ_NEW('IDLgrPolygon', /PRIVATE)
    self->Add, self._oPoly
    self._oLine = OBJ_NEW('IDLgrPolyline', /ANTIALIAS, /PRIVATE)
    self->Add, self._oLine
   

    self._pXdata = PTR_NEW(/ALLOCATE)
    self._pYdata = PTR_NEW(/ALLOCATE)
    self._pZdata = PTR_NEW(/ALLOCATE)

    self._fillBackground = 1b
    self._arrowStyle = 1b
    self._headAngle = 30
    self._headIndent = 0.4d
    self._lengthX = 1
    self._lengthY = 1
    self._thick = 1b
    self._useColor=1d
    self._headSize = 1d

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisArrow::SetProperty, _EXTRA=_extra

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
pro IDLitVisArrow::Cleanup

    compile_opt idl2, hidden

    ; Cleanup our palette
    PTR_FREE, self._pXdata, self._pYdata, self._pZdata

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisArrow::_RegisterProperties
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
pro IDLitVisArrow::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'ARROW_STYLE', $
            DESCRIPTION='Arrow style', $
            ENUMLIST=[' --------', ' ------->', ' <-------', ' <------>', $
                ' >------>', ' <------<'], $
            NAME='Arrow style'
            
        self->RegisterProperty, 'THICK', /THICK, $
            NAME='Arrow thickness', $
            DESCRIPTION='Thickness of arrow shaft'

        self->RegisterProperty, 'LINE_THICK', /THICK, $
            NAME='Line thickness', $
            DESCRIPTION='Line thickness'

        self->RegisterProperty, 'HEAD_ANGLE', /FLOAT, $
            NAME='Arrowhead angle', $
            DESCRIPTION='Angle in degrees of arrowhead from shaft', $
            VALID_RANGE=[0,90,1], /ADVANCED_ONLY

        self->RegisterProperty, 'HEAD_INDENT', /FLOAT, $
            NAME='Arrowhead indentation', $
            DESCRIPTION='Indentation of arrowhead along shaft', $
            VALID_RANGE=[-1,1, 0.1d], /ADVANCED_ONLY
            
        self->RegisterProperty, 'HEAD_SIZE', /FLOAT, $
            NAME='Head size', $
            DESCRIPTION='Arrowhead size', $
            VALID_RANGE=[0.1d,4d, 0.1d], /ADVANCED_ONLY

        self->RegisterProperty, 'FILL_BACKGROUND', $
            NAME='Fill Background', $
            DESCRIPTION='Fill Background', $
            ENUMLIST=['Lines', 'Filled']

        self->RegisterProperty, 'COLOR', /COLOR, $
            NAME='Color', $
            DESCRIPTION='Arrow color'
            
        self->RegisterProperty, 'FILL_COLOR', /COLOR, $
            NAME='Fill Color', $
            DESCRIPTION='Arrow Fill color'

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of vector visualization', $
            VALID_RANGE=[0,100,5]
            
        self->RegisterProperty, 'FILL_TRANSPARENCY', /INTEGER, $
            NAME='Fill Transparency', $
            DESCRIPTION='Transparency of vector visualization', $
            VALID_RANGE=[0,100,5]

        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for vectors', /ADVANCED_ONLY

    endif
end

;----------------------------------------------------------------------------
; IDLitVisArrow::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisArrow::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisArrow::_RegisterProperties, $
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
;   Any keyword to IDLitVisArrow::Init followed by the word "Get"
;   can be retrieved using this method.
;
pro IDLitVisArrow::GetProperty, $
    ANTIALIAS=antialias, $
    FILL_BACKGROUND=fillBackground, $
    ARROW_STYLE=arrowStyle, $
    THICK=thick, $
    COLOR=color, $
    DATA=data, $
    FILL_COLOR = fillColor, $
    FILL_TRANSPARENCY=fillTransparency, $
    GRID_UNITS=gridUnits, $
    HEAD_ANGLE=headAngle, $
    HEAD_INDENT=headIndent, $
    HEAD_SIZE=headSize, $
    LINE_THICK=lineThick, $
    TRANSPARENCY=transparency, $
    ZVALUE=zValue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(antialias)) then $
        self._oLine->GetProperty, ANTIALIAS=antialias

    if (ARG_PRESENT(arrowStyle)) then $
        arrowStyle = self._arrowStyle
        
    if (ARG_PRESENT(fillBackground)) then $
        fillBackground = self._fillBackground

    if (ARG_PRESENT(thick)) then $
        thick = self._thick

    if (ARG_PRESENT(color)) then $
        color = self._color
        
    if (ARG_PRESENT(data)) then $
        self._oPoly->GetProperty, DATA=data
        
    if (arg_present(fillColor)) then $
        fillColor = self._fillColor

    if (ARG_PRESENT(gridUnits) ne 0) then $
        gridUnits = self._gridUnits

    if (ARG_PRESENT(headAngle)) then $
        headAngle = self._headAngle

    if (ARG_PRESENT(headIndent)) then $
        headIndent = self._headIndent
        
    if (ARG_PRESENT(headSize)) then $
        headSize = self._headSize

    if (ARG_PRESENT(lineThick)) then $
        self._oLine->GetProperty, THICK=lineThick

    if ARG_PRESENT(transparency) then begin
        self._oLine->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif
    
    if ARG_PRESENT(fillTransparency) then begin
        self._oPoly->GetProperty, ALPHA_CHANNEL=alpha
        fillTransparency = 0 > ROUND(100 - alpha*100) < 100
    endif

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
;   Any keyword to IDLitVisArrow::Init followed by the word "Set"
;   can be set using this method.
;
pro IDLitVisArrow::SetProperty, $
    ANTIALIAS=antialias, $
    FILL_BACKGROUND=fillBackground, $
    FILL_TRANSPARENCY=fillTransparency, $
    ARROW_STYLE=arrowStyle, $
    THICK=thick, $
    COLOR=color, $
    FILL_COLOR=fillColor, $
    GRID_UNITS=gridUnits, $
    HEAD_ANGLE=headAngle, $
    HEAD_INDENT=headIndent, $
    HEAD_SIZE=headSize, $
    LINE_THICK=lineThick, $
    TRANSPARENCY=transparency, $
    ZVALUE=zValue, $
    DATA = data, $
    _DATA=_data, $
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

    if (N_ELEMENTS(fillBackground) gt 0) then begin
        if ((fillBackground lt 0) || (fillBackground gt 1)) then fillBackground = 1 
        self._fillBackground = fillBackground
        self._oPoly->SetProperty, HIDE=(self._fillBackground eq 0)
        if (self._fillBackground eq 1) then self._oPoly->SetProperty, COLOR=self._fillColor
        self->_UpdateData
    endif
        
    if (N_ELEMENTS(arrowStyle) gt 0) then begin
        if ((arrowStyle gt 5) || (arrowStyle lt 0)) then arrowStyle = 1
        self._arrowStyle = arrowStyle
        self->_UpdateData
    endif
  
    if (N_ELEMENTS(thick) gt 0) then begin
        self._thick = 1 > DOUBLE(thick) < 10
        self->_UpdateData
    endif

    IF (n_elements(color) GT 0) THEN BEGIN
        if (isa(color, 'STRING') || N_ELEMENTS(color) eq 1) then $
        style_convert, color, COLOR=color
        any_neg = where(color lt 0)
        if(isa(any_neg, /array)) then color = [0b,0b,0b]
        if (~isa(color, /array)) then color = [0b,0b,0b]
        self._color = color
        self._oLine->SetProperty, COLOR=color
        if (self._useColor) then begin
          self._oPoly->SetProperty, COLOR=color
          self._fillColor=color
        endif
    ENDIF
    
    IF (n_elements(fillColor) GT 0) THEN BEGIN
        if (isa(fillColor, 'STRING') || N_ELEMENTS(fillColor) eq 1) then $
        style_convert, fillColor, COLOR=fillColor
        any_neg = where(fillColor lt 0)
        if(isa(any_neg, /array)) then fillColor = [0b,0b,0b]
        if (~isa(fillColor, /array)) then fillColor = [0b,0b,0b]
        self._fillColor = fillColor
        self._useColor = 0
        if (self._fillBackground eq 1) then self._oPoly->SetProperty, COLOR=fillColor
        
    ENDIF

    if (N_ELEMENTS(headAngle) gt 0 && headAngle ge 0) then begin
        if(headAngle gt 90) then headAngle = 30
        self._headAngle = ABS(headAngle)
        self->_UpdateData
    endif

    if (N_ELEMENTS(headIndent) gt 0) then begin
        self._headIndent = -1 > DOUBLE(headIndent) < 1
        self->_UpdateData
    endif
    
    if (N_ELEMENTS(headSize) gt 0) then begin
        if DOUBLE(headSize) lt 0 then headSize = 1 
        self._headSize = headSize
        self->_UpdateData
    endif

    if (N_ELEMENTS(transparency)) then begin
        alpha = 0 > ((100.-transparency)/100) < 1
        self._oPoly->GetProperty, ALPHA=oldFillAlpha
        self._oLine->GetProperty, ALPHA=oldLineAlpha
        self._oLine->SetProperty, ALPHA_CHANNEL=alpha
        if (oldFillAlpha eq oldLineAlpha) then $
          self._oPoly->SetProperty, ALPHA_CHANNEL=alpha
    endif

    if (N_ELEMENTS(fillTransparency)) then begin
        alpha = 0 > ((100.-fillTransparency)/100) < 1
        self._oPoly->SetProperty, ALPHA_CHANNEL=alpha
    endif

    if (N_ELEMENTS(lineThick) gt 0) then begin
        self._oLine->SetProperty, THICK=1 > DOUBLE(lineThick) < 10
        self._oPoly->SetProperty, THICK=1 > DOUBLE(lineThick) < 10
    endif


    if (N_ELEMENTS(zValue) gt 0) then begin
        self._zValue = zValue
        self->_UpdateData
        ;self->Set3D, (self._zValue ne 0), /ALWAYS
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (N_ELEMENTS(data) gt 0) then begin
       *self._pXdata = data[0,*]
       *self._pYdata = data[1,*]
       *self._pZdata = data[2,*]
        oDataObj = self->GetParameter('VERTICES')
        if (~OBJ_VALID(oDataObj)) then begin
            oDataObj = OBJ_NEW("IDLitData", data, /NO_COPY, $
                NAME='Vertices', $
                TYPE='IDLVERTEX', ICON='segpoly', /PRIVATE)
;            void = self->SetData(oDataObj, $
;                PARAMETER_NAME= 'VERTICES', /BY_VALUE)
            status = self->IDLitParameter::SetData(oDataObj, PARAMETER_NAME= 'VERTICES', /BY_VALUE)

        endif else begin
            void = oDataObj->SetData(data, /NO_COPY)
        endelse
      self->_UpdateData
    endif

    if (N_ELEMENTS(_data) gt 0) then begin
      *self._pXdata = _data[0,*]
      *self._pYdata = _data[1,*]
      *self._pZdata = _data[2,*]
      self._oPoly->setProperty, HIDE=1
      self._oLine->setProperty, DATA=_data, POLYLINES=0
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty,_EXTRA=_extra
end

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to update the visualization.
;
pro IDLitVisArrow::_UpdateArrow, xRange, yRange

    compile_opt idl2, hidden

    if (*self._pXdata eq !null) then return
   
    sMap = self->GetProjection()
    if (N_TAGS(sMap) ne 0) then $
      points = [MAP_PROJ_FORWARD(*self._pXdata, *self._pYdata, MAP_STRUCTURE=sMap), *self._pZdata] $
      else points = [*self._pXdata, *self._pYdata, *self._pZdata]
 
 
    ; First determine the tip and end points.
    switch self._arrowStyle of
    0: ; fall through
    1: ; fall through
    3: ; fall through
    4: begin
      xEnd = points[0,0]
      yEnd = points[1,0]
      xTip = points[0,1]
      yTip = points[1,1]
      break
      end
    2: ; fall through
    5: begin
      ; arrowhead is at the first point instead of the second
      xEnd = points[0,1]
      yEnd = points[1,1]
      xTip = points[0,0]
      yTip = points[1,0]
      break
      end
    else: MESSAGE, 'Invalid arrow_style'
    endswitch


    hasZvalue = self._zValue ne 0
 
    headSize = 0.06d*self._headSize
    xyScale = self._lengthX/self._lengthY
    rCosTheta = (self._headAngle eq 90) ? 0 : headSize*COS(self._headAngle*!DPI/180)
    rSinTheta = (self._headAngle eq 0) ? 0 : headSize*SIN(self._headAngle*!DPI/180)
 
    odes = self->getdataspace(/unnormalized)
    isWithinDataspace = odes->getXYZRange(xDataRange, yDataRange, zDataRange)
 

    ; Compute some generic locations, regardless of arrow style.
    xdelta = xTip - xEnd
    ydelta = yTip - yEnd  

    if (isWithinDataspace) then begin
      ; If we are within the dataspace, convert our arrow length back to
      ; screen (pixel) coordinates, so we can normalize the arrow head size.
      self->VisToWindow, [xEnd, xTip], [yEnd, yTip], xPixels, yPixels
      pixelMag = SQRT((xPixels[1]-xPixels[0])^2 + (yPixels[1]-yPixels[0])^2)
      magnitude = pixelMag/280d
    endif else begin
      ; If we are in the annotation layer, just normalize the head size
      ; by our arrow length.
      magnitude = sqrt(xdelta * xdelta + ydelta * ydelta)
    endelse

    xdelta = xdelta/magnitude
    ydelta = ydelta/magnitude  

    ; Note that we need to apply the aspect ratio to the
    ; tips of the arrowhead, since they are off the shaft.
    dHeadX = (xyScale*rSinTheta)*ydelta
    dHeadY = ((1/xyScale)*rSinTheta)*xdelta
    
    ; These will already have the aspect ratio factor applied.
    fracThick = (self._thick-1)/9d
    xShaftThick = fracThick*dHeadX
    yShaftThick = fracThick*dHeadY

    ; Intersection of the back of the arrowhead with the middle of the shaft.
    xTipMid = xTip - (1 - self._headIndent)*rCosTheta*xdelta
    yTipMid = yTip - (1 - self._headIndent)*rCosTheta*ydelta
    
    ; The end of the barbs
    xTipBarb1 = xTip - dHeadX - rCosTheta*xdelta
    yTipBarb1 = yTip + dHeadY - rCosTheta*ydelta
    xTipBarb2 = xTip + dHeadX - rCosTheta*xdelta
    yTipBarb2 = yTip - dHeadY - rCosTheta*ydelta


    ; Should we clip the arrow?
    if (isa(xRange) && isa(yrange)) then begin
      hide_outofrange = (xTip gt xRange[1] && xEnd gt xRange[1]) || $
        (xTip lt xRange[0] && xEnd lt xRange[0]) || $
        (yTip gt yRange[1] && yEnd gt yRange[1]) || $
        (yTip lt yRange[0] && yEnd lt yRange[0])
    endif else begin
      hide_outofrange = 0
    endelse


    ; Now construct the actual polygon points.
    switch self._arrowStyle of
    0: begin
      p = 5
      polyvert = DBLARR(2 + hasZvalue, p, /NOZERO)
      if (hasZvalue) then polyvert[2, *] = self._zValue
      
      polyvert[0, 0] = xTip - xShaftThick
      polyvert[1, 0] = yTip + yShaftThick
      polyvert[0, 1] = xTip + xShaftThick
      polyvert[1, 1] = yTip - yShaftThick
      polyvert[0, 2] = xEnd + xShaftThick
      polyvert[1, 2] = yEnd - yShaftThick
      polyvert[0, 3] = xEnd - xShaftThick
      polyvert[1, 3] = yEnd + yShaftThick
      polyvert[0, 4] = xTip - xShaftThick
      polyvert[1, 4] = yTip + yShaftThick
      
      ; Construct array of nElts polygons, each with p vertices.
      polygons = [LONARR(1, 1)+p, LINDGEN(p, 1)]
      polygons = REFORM(polygons, (p+1))
      polylines = polygons
      break
    end

    1: ; opposite of arrow_style=2, with x/yTip and x/yEnd reversed, so fall through
    
    2: begin
      p = 8
      polyvert = DBLARR(2 + hasZvalue, p, /NOZERO)
      if (hasZvalue) then polyvert[2, *] = self._zValue
    
      polyvert[0, 0] = xTip
      polyvert[1, 0] = yTip
      polyvert[0, 1] = xTipBarb1
      polyvert[1, 1] = yTipBarb1
      polyvert[0, 2] = xTipMid*(1-fracThick) + fracThick*xTipBarb1
      polyvert[1, 2] = yTipMid*(1-fracThick) + fracThick*yTipBarb1
      polyvert[0, 3] = xEnd - xShaftThick
      polyvert[1, 3] = yEnd + yShaftThick
      polyvert[0, 4] = xEnd + xShaftThick
      polyvert[1, 4] = yEnd - yShaftThick
      polyvert[0, 5] = xTipMid*(1-fracThick) + fracThick*xTipBarb2
      polyvert[1, 5] = yTipMid*(1-fracThick) + fracThick*yTipBarb2
      polyvert[0, 6] = xTipBarb2
      polyvert[1, 6] = yTipBarb2
      polyvert[0, 7] = xTip
      polyvert[1, 7] = yTip
      
      ; Construct array of nElts polygons, each with p vertices.
      polygons = [LONARR(1, 1)+p, LINDGEN(p, 1)]
      polygons = REFORM(polygons, (p+1))
      polylines = [8,2,3,4,5,6,0,1,2]
      break
    end

    3: begin
      ; Compute the other arrowhead.
      xEndMid = xEnd + (1 - self._headIndent)*rCosTheta*xdelta
      yEndMid = yEnd + (1 - self._headIndent)*rCosTheta*ydelta
      xEndBarb1 = xEnd - dHeadX + rCosTheta*xdelta
      yEndBarb1 = yEnd + dHeadY + rCosTheta*ydelta
      xEndBarb2 = xEnd + dHeadX + rCosTheta*xdelta
      yEndBarb2 = yEnd - dHeadY + rCosTheta*ydelta
  
      p = 11
      polyvert = DBLARR(2 + hasZvalue, p, /NOZERO)
      if (hasZvalue) then polyvert[2, *] = self._zValue

      polyvert[0, 0] = xTip
      polyvert[1, 0] = yTip
      polyvert[0, 1] = xTipBarb1
      polyvert[1, 1] = yTipBarb1
      polyvert[0, 2] = xTipMid*(1-fracThick) + fracThick*xTipBarb1
      polyvert[1, 2] = yTipMid*(1-fracThick) + fracThick*yTipBarb1
      polyvert[0, 3] = xEndMid*(1-fracThick) + fracThick*xEndBarb1
      polyvert[1, 3] = yEndMid*(1-fracThick) + fracThick*yEndBarb1
      polyvert[0, 4] = xEndBarb1
      polyvert[1, 4] = yEndBarb1
      polyvert[0, 5] = xEnd
      polyvert[1, 5] = yEnd
      polyvert[0, 6] = xEndBarb2
      polyvert[1, 6] = yEndBarb2
      polyvert[0, 7] = xEndMid*(1-fracThick) + fracThick*xEndBarb2
      polyvert[1, 7] = yEndMid*(1-fracThick) + fracThick*yEndBarb2
      polyvert[0, 8] = xTipMid*(1-fracThick) + fracThick*xTipBarb2
      polyvert[1, 8] = yTipMid*(1-fracThick) + fracThick*yTipBarb2
      polyvert[0, 9] = xTipBarb2
      polyvert[1, 9] = yTipBarb2
      polyvert[0, 10] = xTip
      polyvert[1, 10] = yTip
      
      polylines = [11,2,3,4,5,6,7,8,9,0,1,2]
        
      if(self._fillBackground eq 0) then begin
        ; Construct array of nElts polygons, each with p vertices.
        polygons = [LONARR(1, 1)+p, LINDGEN(p, 1)]
        polygons = REFORM(polygons, (p+1))
      endif else begin
        polygons = [6, 0, 1, 2, 8, 9, 10, 4, 2, 3, 7, 8, 6, 5, 4, 3, 7, 6, 5]
      endelse
      break
    end

    4: ; opposite of arrow_style=5, with x/yTip and x/yEnd reversed, so fall through

    5: begin
      ; Compute the tail (the fletching) of the arrow
      xEndMid = xEnd + (1 - self._headIndent)*rCosTheta*xdelta
      yEndMid = yEnd + (1 - self._headIndent)*rCosTheta*ydelta
      xEndBarb1 = xEnd - dHeadX - self._headIndent*rCosTheta*xdelta
      yEndBarb1 = yEnd + dHeadY - self._headIndent*rCosTheta*ydelta
      xEndBarb2 = xEnd + dHeadX - self._headIndent*rCosTheta*xdelta
      yEndBarb2 = yEnd - dHeadY - self._headIndent*rCosTheta*ydelta

      p = 11
      polyvert = DBLARR(2 + hasZvalue, p, /NOZERO)
      if (hasZvalue) then polyvert[2, *] = self._zValue

      polyvert[0, 0] = xTip
      polyvert[1, 0] = yTip
      polyvert[0, 1] = xTipBarb1
      polyvert[1, 1] = yTipBarb1
      polyvert[0, 2] = xTipMid*(1-fracThick) + fracThick*xTipBarb1
      polyvert[1, 2] = yTipMid*(1-fracThick) + fracThick*yTipBarb1

      ; Compute the intersection of the shaft lines with the tail feather
      polyvert[0, 3] = xEndMid*(1 - fracThick) + fracThick*xEndBarb1
      polyvert[1, 3] = yEndMid*(1 - fracThick) + fracThick*yEndBarb1

      polyvert[0, 4] = xEndBarb1
      polyvert[1, 4] = yEndBarb1
      polyvert[0, 5] = xEnd
      polyvert[1, 5] = yEnd
      polyvert[0, 6] = xEndBarb2
      polyvert[1, 6] = yEndBarb2

      polyvert[0, 7] = xEndMid*(1 - fracThick) + fracThick*xEndBarb2
      polyvert[1, 7] = yEndMid*(1 - fracThick) + fracThick*yEndBarb2

      polyvert[0, 8] = xTipMid*(1-fracThick) + fracThick*xTipBarb2
      polyvert[1, 8] = yTipMid*(1-fracThick) + fracThick*yTipBarb2
      polyvert[0, 9] = xTipBarb2
      polyvert[1, 9] = yTipBarb2
      polyvert[0, 10] = xTip
      polyvert[1, 10] = yTip
      
      polylines = [11,2,3,4,5,6,7,8,9,0,1,2]
      
      if(self._fillBackground eq 0) then begin
        ; Construct array of nElts polygons, each with p vertices.
        polygons = [LONARR(1, 1)+p, LINDGEN(p, 1)]
        polygons = REFORM(polygons, (p+1))
      endif else begin
        polygons = [6, 0, 1, 2, 8, 9, 10, 6, 2, 3, 5, 7, 8, 2, 4, 3, 4, 5, 3, 4, 5, 6, 7, 5]
      endelse
      break
    end

    else:MESSAGE, 'Invalid arrow_style'
    endswitch

    self._oPoly->SetProperty, DATA=polyvert, $
        POLYGONS=polygons, $
        HIDE=(self._fillBackground eq 0) || (hide_outofrange eq 1), $
        STYLE=(self._fillBackground eq 0) ? 1 : 2

    self._oLine->SetProperty, DATA=polyvert, $
        LABEL_OBJECTS=OBJ_NEW(), $
        LABEL_POLYLINES=0, $
        POLYLINES=polylines, $
        HIDE=(hide_outofrange eq 1)
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
pro IDLitVisArrow::_UpdateData, $
    MAP_PROJECTION=sMap, $
    WITHIN_DRAW=withinDraw

    compile_opt idl2, hidden

    withinDraw = KEYWORD_SET(withinDraw)
 
    self->_UpdateArrow

    if (~withinDraw) then begin
        self->OnDataChange
        self->OnDataComplete
    endif
end


;----------------------------------------------------------------------------
pro IDLitVisArrow::OnProjectionChange, sMap

    compile_opt idl2, hidden

    self->_UpdateData, MAP_PROJECTION=sMap

end

;----------------------------------------------------------------------------
pro IDLitVisArrow::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden
    
    self->_UpdateArrow, xRange, yRange
end


;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
pro IDLitVisArrow::OnWorldDimensionChange, oSubject, is3D

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
function IDLitVisArrow::_ComputeAspect

    compile_opt idl2, hidden

    ; Find out if aspect ratio is still correct
    self->WindowToVis, [[0,0], [1d,0]], onePixel
    lengthX = ABS(onePixel[0,1] - onePixel[0,0])
    if (lengthX lt 1d-9) then $
        return, 0
    self->WindowToVis, [[0,0], [0,1d]], onePixel
    lengthY = ABS(onePixel[1,1] - onePixel[1,0])
    if (lengthY lt 1d-9) then $
        return, 0
    xyScale = lengthX/lengthY
    prevScale = self._lengthX/self._lengthY
    newAspect = ABS(xyScale - prevScale) gt 1d-4*ABS(xyScale)
    self._lengthX = lengthX
    self._lengthY = lengthY
    
    return, newAspect
end

;-----------------------------------------------------------------------------
; Override IDLgrModel::Draw so we can
; automatically adjust for changes in aspect ratio.
;
pro IDLitVisArrow::Draw, oDest, oView

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


;-----------------------------------------------------------------------------
pro IDLitVisArrow::MoveVertex, xyz, INDEX=index, WINDOW=WINDOW

    compile_opt hidden, idl2

    ; Retrieve the data pointer and check the indices.
    if (~self->_IDLitVisVertex::_CheckVertex(oDataObj, pData, index)) then $
        return

    ; Number of vertices.
    ptsStored = (SIZE(*pData, /N_DIM) eq 1) ? 1 : $
        (SIZE(*pData, /DIMENSIONS))[1]

    nDim = (SIZE(xyz, /DIMENSIONS))[0]

    if(keyword_set(WINDOW))then $
        self->_IDLitVisualization::WindowToVis, xyz, visXYZ $
    else $
        visXYZ = xyz

    ; Note that we are directly modifying the data pointer.
    (*pData)[0:nDim-1, index] = visXYZ

    ; If only 2D vertices, then zero out the Z values.
    if (nDim eq 2) then $
        (*pData)[2, index] = 0

    ; Notify our observers if we have enough points.
    if (ptsStored ge self._ptsNeeded) then begin
        oDataObj->NotifyDataChange
        oDataObj->NotifyDataComplete
    endif
    *self._pXdata = (*pData)[0,*]
    *self._pYdata = (*pData)[1,*]
    
    self->_UpdateData

end

;----------------------------------------------------------------------------
; IDLitVisArrow__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisArrow object.
;
pro IDLitVisArrow__Define

    compile_opt idl2, hidden

    struct = { IDLitVisArrow,              $
        inherits IDLitVisualization,  $ ; Superclass: _IDLitVisualization
        inherits _IDLitVisVertex, $
        _oLine: OBJ_NEW(), $
        _oPoly: OBJ_NEW(), $
        _pXdata: PTR_NEW(), $
        _pYdata: PTR_NEW(), $
        _pZdata: PTR_NEW(), $
        _color: [0b,0b,0b], $
        _fillColor: [0b,0b,0b], $
        _gridUnits: 0b, $
        _arrowStyle: 0b, $
        _fillBackground: 0b, $
        _useColor:0b, $
        _thick: 0d, $
        _lengthX: 0d, $
        _lengthY: 0d, $
        _headAngle: 0d, $
        _headIndent: 0d, $
        _headSize:0d, $
        _zValue: 0d $
    }
end
