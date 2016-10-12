; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvismapgridline__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisMapGridline
;
; PURPOSE:
;    The IDLitVisMapGridline class implements a gridline visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-


;----------------------------------------------------------------------------
function IDLitVisMapGridline::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(NAME="Gridline", $
        TYPE="IDLGRIDLINE", $
        IMPACTS_RANGE=1, $
        ICON='line', $
        DESCRIPTION="Grid line",$
        _EXTRA=_EXTRA))then $
        return, 0

    self._oLine = OBJ_NEW("IDLgrPolyline", /PRIVATE, $
        /ANTIALIAS, /REGISTER_PROPERTIES, $
        /USE_TEXT_ALIGNMENTS)
    self->Add, self._oLine, /AGGREGATE
    self->SetPropertyAttribute,['NAME', 'DESCRIPTION', 'SHADING'], /HIDE

    self._labelPosition = 0.5
    self._labelShow = 1
    self._labelAngle = -1

    self->IDLitVisMapGridline::_RegisterProperties

    ; Create the Font object. Use the current zoom factor of the tool window
    ; as the initial font zoom factor.  Likewise for the view zoom, and
    ; normalization factor.
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
    self._oFont = OBJ_NEW('IDLitFont', FONT_SIZE=9, FONT_ZOOM=fontZoom, $
        VIEW_ZOOM=viewZoom, FONT_NORM=fontNorm)
    self->Aggregate, self._oFont
    self._oText = OBJ_NEW('IDLgrText', $
        /ENABLE_FORMATTING, $
        ALIGNMENT=0.5, $
        VERTICAL_ALIGNMENT=0.5, $
        FONT=self._oFont->GetFont(), $
        RECOMPUTE_DIMENSIONS=2)

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisMapGridline::SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
pro IDLitVisMapGridline::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oText
    OBJ_DESTROY, self._oFont

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup

end

;----------------------------------------------------------------------------
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisMapGridline::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self._oLine->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of grid', $
            VALID_RANGE=[0,100,5]

        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_SHOW', /BOOLEAN, $
            NAME='Label', $
            DESCRIPTION='Label gridlines', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_POSITION', /FLOAT, $
            NAME='Label position', $
            DESCRIPTION='Normalized label position', $
            VALID_RANGE=[0d,1d,0.05d], /ADVANCED_ONLY

    ;    result = IDLitGetResource(1, formatNames, /DEGREESFORMAT, /NAMES)
    ;    result = IDLitGetResource(1, formatExamples, /DEGREESFORMAT, /EXAMPLES)
    ;
    ;    self._oLine->RegisterProperty, 'LABEL_FORMAT', $
    ;        NAME='Label format', $
    ;        DESCRIPTION='Predefined label format', $
    ;        ENUMLIST=['None', $
    ;                  'Use Tick Format Code', $
    ;                  formatNames+' ('+formatExamples+')']

        self._oLine->RegisterProperty, 'LABEL_USE_COLOR', /BOOLEAN, $
            NAME='Use label color', $
            DESCRIPTION='Use provided label color instead of default', $
            /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_COLOR', /COLOR, $
            NAME='Label color', $
            DESCRIPTION='Color of labels', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_FILL_BACKGROUND', $
            ENUMLIST=['None', 'View color', 'Fill color'], $
            NAME='Label fill background', $
            DESCRIPTION='Mode for label fill background', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_FILL_COLOR', /COLOR, $
            NAME='Label fill color', $
            DESCRIPTION='Fill color for label background', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_ANGLE', /FLOAT, $
            NAME='Label angle', $
            DESCRIPTION='Label angle', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_ALIGN', /FLOAT, $
            NAME='Label alignment', $
            DESCRIPTION='Label alignment', /ADVANCED_ONLY

        self._oLine->RegisterProperty, 'LABEL_VALIGN', /FLOAT, $
            NAME='Label vertical align', $
            DESCRIPTION='Label vertical align', /ADVANCED_ONLY


    endif

    ; Property added in IDL64.
    if (registerAll || (updateFromVersion lt 640)) then begin
        self._oLine->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for grid lines', /ADVANCED_ONLY
    endif

end

;----------------------------------------------------------------------------
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisMapGridline::Restore

    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisMapGridline::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

end

;----------------------------------------------------------------------------
function IDLitVisMapGridline::_GetLabel, $
    lonMin, lonMax, latMin, latMax, gridLon, gridLat

    compile_opt idl2, hidden

    ; Use Unicode for the degrees symbol, to avoid 8-bit ASCII problems.
    deg = '!Z(00B0)'
    format = '(g0,"' + deg + '")'
    suffix = [['E', 'W'], ['N', 'S']]
    suffix = suffix[self._location lt 0, self._orientation]

    ; If we are only covering a small region, use DMS format.
;    cutoff = 10
;    smallGrid = (latMax - latMin) lt cutoff || $
;        (lonMax - lonMin) lt cutoff
    smallGrid = lonMin ne FIX(lonMin) || lonMax ne FIX(lonMax) || $
      latMin ne FIX(latMin) || latMax ne FIX(latMax) || $
      gridLon ne FIX(gridLon) || gridLat ne FIX(gridLat)

    absloc = ABS(self._location)

    if (smallGrid) then begin
        degrees = FIX(absloc)
        minutes = FIX((absloc - degrees)*60)
        seconds = ROUND((absloc - degrees - minutes/60d)*3600)
        label = STRTRIM(degrees,2) + deg + $
            STRING(minutes, FORMAT='(I2.2)') + "'" + $
            STRING(seconds, FORMAT='(I2.2)') + "''"
        ; Only add suffix if crosses equator/prime meridian.
        if (latMin lt 0 && latMax gt 0) || $
            (lonMin lt 0 && lonMax gt 0) then begin
            label += suffix
        endif
    endif else begin
        location = ROUND(ABS(self._location)*10000)/10000d
        label = STRING(location, FORMAT=format) + suffix
    endelse

    return, label
end


;----------------------------------------------------------------------------
pro IDLitVisMapGridline::OnProjectionChange, sMap

    compile_opt idl2, hidden

    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()
    hasMap = N_TAGS(sMap) gt 0

    ; This assumes that the VisMapGrid is the grandparent of Gridline.
    self->IDLitComponent::GetProperty, _PARENT=oParent
    oParent->IDLitComponent::GetProperty, _PARENT=oParent
    oParent->GetProperty, $
        GRID_LONGITUDE=gridLon, GRID_LATITUDE=gridLat, $
        LONGITUDE_MIN=lonMin, $
        LONGITUDE_MAX=lonMax, $
        LATITUDE_MIN=latMin, $
        LATITUDE_MAX=latMax

    npts = (self._orientation) ? 180 : 90

    ; We must use the range of the opposite coordinate
    ; (latitude if lonlines, and vice versa) so that the gridlines
    ; don't extend past the ends of the other lines.
    range = (self._orientation) ? $
        [lonMin, lonMax] : [latMin, latMax]
    if (hasMap) then begin
      range[0] >= sMap.ll_box[self._orientation]
      range[1] <= sMap.ll_box[self._orientation+2]
    endif

;    if (range[0] eq -180 || range[0] eq -90) then range[0] += 1d-3
;    if (range[1] eq 180 || range[0] eq 90) then range[1] -= 1d-3

    points = DINDGEN(npts)*((range[1]-range[0])/(npts-1)) + $
        range[0]
    data = DBLARR(2, npts)
    location = self._location


    ; If our lat/lon line is on a map boundary,
    ; bump it slightly so it doesn't get clipped.
    if (self._orientation) then begin  ; latitude
        if ((hasMap && (location eq sMap.ll_box[0])) || location eq -90) then begin
            location += 1d-3
        endif
        if ((hasMap && (location eq sMap.ll_box[2])) || location eq 90) then begin
            location -= 1d-3
        endif
        data[0,*] = points
        data[1,*] = location
    endif else begin   ; longitude
        if (hasMap && (location eq sMap.ll_box[1])) then $
            location += 1d-3
        if (hasMap && (location eq sMap.ll_box[3])) then $
            location -= 1d-3
        data[0,*] = location
        data[1,*] = points
    endelse

    polylines = 0 ; clear out our polylines if no map proj


    if (hasMap) then begin
        data = MAP_PROJ_FORWARD(TEMPORARY(data), $
            MAP=sMap, $
            POLYLINES=polylines)
        ; If all of our line points collapse down to a tiny point,
        ; then remove the gridline. This happens for +/-90 for
        ; Polar Stereographic for example.
        mn = MIN(data, MAX=mx)
        if (ABS(mx - mn) lt 5) then data = 0

        if (N_ELEMENTS(data) lt 4) then begin
            self._oLine->SetProperty, /HIDE
            self->IDLitVisualization::SetProperty, IMPACTS_RANGE=0
            return
        endif
    endif

    label = self->_GetLabel(lonMin, lonMax, $
        latMin, latMax, gridLon, gridLat)
    self._oText->SetProperty, STRINGS=label

    self._oLine->SetProperty, HIDE=0, DATA=data, POLYLINES=polylines
    self->IDLitVisualization::SetProperty, /IMPACTS_RANGE

end


;---------------------------------------------------------------------------
; IDLitVisMapGridline::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport
;   has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     width and height of the viewport (in pixels).
;
;   normViewDims: A 2-element vector, [w,h], representing the new
;     width and height of the visibile view (normalized relative to
;     the virtual canvas).
;
pro IDLitVisMapGridline::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    ; Check if destination zoom factor or normalized viewport has changed.
    ; If so, update the corresponding font properties.
    self._oFont->GetProperty, FONT_ZOOM=fontZoom, FONT_NORM=fontNorm
    if (OBJ_VALID(oDestination)) then $
        oDestination->GetProperty, CURRENT_ZOOM=zoomFactor $
    else $
        zoomFactor = 1.0

    normFactor = MIN(normViewDims)

    if ((fontZoom ne zoomFactor) || $
        (fontNorm ne normFactor)) then $
        self._oFont->SetProperty, FONT_ZOOM=zoomFactor, FONT_NORM=normFactor

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewportChange, oSubject, oDestination, $
        viewportDims, normViewDims
end

;---------------------------------------------------------------------------
; IDLitVisMapGridline::OnViewZoom
;
; Purpose:
;   This procedure method handles notification that the view zoom factor
;   has changed
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom factor change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewZoom: The new zoom factor for the view.
;
pro IDLitVisMapGridline::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    ; Check if view zoom factor has changed.  If so, update the font.
    self._oFont->GetProperty, VIEW_ZOOM=fontViewZoom

    if (fontViewZoom ne viewZoom) then $
        self._oFont->SetProperty, VIEW_ZOOM=viewZoom

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewZoom, oSubject, oDestination, $
        viewZoom
end


;----------------------------------------------------------------------------
pro IDLitVisMapGridline::_GetAlignment, align, valign

  compile_opt idl2, hidden

  angle = self._labelAngle
  lpos = self._labelPosition

  ; If angle < 0 then we are ignoring the angle.
  if (angle lt 0) then begin
    valign = 0.5
    align = (lpos le 0) ? 1.1 : (lpos ge 1 ? -0.15 : 0.5)
    return
  endif

  if (lpos gt 0 && lpos lt 1) then begin  ; 0 > label position < 1
    align = 0.5
    valign = 0.5
    return
  endif
  
  ; Label position is exactly 0 or 1.

  if (self._orientation) then begin  ; latitude
    if (angle lt 20 || angle gt 340) then begin
      align = 1.1
      valign = 0.5
    endif else if (angle le 70 || angle ge 290) then begin
      align = 1.1
      valign = angle le 70 ? 0.25 : 0.75
    endif else if (angle lt 110 || angle ge 250) then begin
      align = 0.5
      valign = angle lt 110 ? -0.2 : 1.1
    endif else if (angle lt 160 || angle gt 200) then begin
      align = 0
      valign = angle lt 160 ? -0.2 : 1.1
    endif else begin   ; around 180 degrees
      align = -0.1
      valign = 0.5
    endelse
  endif else begin
    if (angle lt 20 || angle gt 340) then begin
      align = 0.5
      valign = 1.1
    endif else if (angle le 70 || angle ge 290) then begin
      align = angle le 70 ? 1.1 : -0.1
      valign = 0.75
    endif else if (angle lt 110 || angle ge 250) then begin
      align = angle lt 110 ? 1.1 : -0.1
      valign = 0.5
    endif else if (angle lt 160 || angle gt 200) then begin
      align = angle lt 160 ? 1.1 : -0.1
      valign = -0.2
    endif else begin   ; around 180 degrees
      align = 0.5
      valign = -0.2
    endelse
  endelse

  ; If labels are on the right then flip the alignments.
  if (lpos eq 1) then begin
    align = 1 - align
    valign = 0.9 - valign
  endif

end


;----------------------------------------------------------------------------
pro IDLitVisMapGridline::GetProperty, $
    LABEL_ALIGN=labelAlign, $
    LABEL_VALIGN=labelValign, $
    LABEL_ANGLE=labelAngle, $
    LABEL_COLOR=labelColor, $
    LABEL_FILL_BACKGROUND=labelFillBackground, $
    LABEL_FILL_COLOR=labelFillColor, $
    LABEL_FORMAT=labelFormat, $
    LABEL_POSITION=labelPosition, $
    LABEL_SHOW=labelShow, $
    LABEL_USE_COLOR=labelUseColor, $
    LOCATION=location, $
    ORIENTATION=orientation, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(labelAlign)) then $
        self._oText->GetProperty, ALIGNMENT=labelAlign

    if (ARG_PRESENT(labelValign)) then $
        self._oText->GetProperty, VERTICAL_ALIGNMENT=labelValign

    if (ARG_PRESENT(labelAngle)) then $
        labelAngle = self._labelAngle

    if (ARG_PRESENT(labelColor)) then $
        self._oText->GetProperty, COLOR=labelColor

    if (ARG_PRESENT(labelFillBackground)) then $
        self._oText->GetProperty, FILL_BACKGROUND=labelFillBackground

    ; Note: -1 will automatically be converted by a PropSheet into
    if (ARG_PRESENT(labelFillColor)) then $
        self._oText->GetProperty, FILL_COLOR=labelFillColor

    if (ARG_PRESENT(labelFormat)) then $
        labelFormat = self._labelFormat

    if (ARG_PRESENT(labelPosition)) then $
        labelPosition = self._labelPosition

    if (ARG_PRESENT(labelShow)) then $
        labelShow = self._labelShow

    if (ARG_PRESENT(labelUseColor)) then begin
        self._oLine->GetProperty, USE_LABEL_COLOR=labelUseColor
        labelUseColor = labelUseColor[0]
    endif

    if ARG_PRESENT(location) then $
        location = self._location

    if ARG_PRESENT(orientation) then $
        orientation = self._orientation

    if ARG_PRESENT(transparency) then begin
        self._oLine->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 100.0 - alpha * 100.0
    endif

    if (ARG_PRESENT(zvalue)) then $
        zvalue = self._zvalue

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
pro IDLitVisMapGridline::SetProperty, $
    COLOR=colorIn, $
    DATA=data, $
    LABEL_ALIGN=labelAlign, $
    LABEL_VALIGN=labelValign, $
    LABEL_ANGLE=labelAngle, $
    LABEL_COLOR=labelColorIn, $
    LABEL_FILL_BACKGROUND=labelFillBackground, $
    LABEL_FILL_COLOR=labelFillColorIn, $
    LABEL_FORMAT=labelFormat, $
    LABEL_POSITION=labelPosition, $
    LABEL_SHOW=labelShow, $
    LABEL_USE_COLOR=labelUseColor, $
    LINESTYLE=linestyleIn, $
    LOCATION=location, $
    ORIENTATION=orientation, $
    POLYLINES=polylines, $
    RANGE=range, $
    TRANSPARENCY=transparency, $
    ZVALUE=zvalue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    updateGrid = 0b

    if (N_ELEMENTS(location)) then begin
        self._location = location
        updateGrid = 1b
    endif

    if (N_ELEMENTS(orientation)) then begin
        self._orientation = KEYWORD_SET(orientation)
        updateGrid = 1b
    endif

    if (N_ELEMENTS(transparency)) then begin
        transparency = 0 > transparency < 100
        self._oLine->SetProperty, ALPHA_CHANNEL=(100.-transparency)/100
    endif


    if (N_ELEMENTS(labelFormat)) then begin
        self._labelFormat = labelFormat
        updateGrid = 1b
    endif

    if (N_ELEMENTS(labelPosition)) then begin
        self._labelPosition = labelPosition
        self._oLine->SetProperty, LABEL_OFFSETS=0 > labelPosition < 1
        ; Use the code in LABEL_ANGLE to fix the text alignment.
        labelAngle = self._labelAngle
    endif

    if (N_ELEMENTS(labelUseColor)) then begin
        self->SetPropertyAttribute, 'LABEL_COLOR', $
            SENSITIVE=self._labelShow && KEYWORD_SET(labelUseColor)
        self._oLine->SetProperty, $
            USE_LABEL_COLOR=KEYWORD_SET(labelUseColor)
    endif

    if (N_ELEMENTS(labelFillColorIn)) then begin
        labelFillColor = labelFillColorIn
        if (ISA(labelFillColorIn, 'STRING') || N_ELEMENTS(labelFillColorIn) eq 1) then $
          style_convert, labelFillColorIn, COLOR=labelFillColor
        self._oText->SetProperty, FILL_COLOR=labelFillColor
    endif

    if (N_ELEMENTS(labelFillBackground)) then begin
        self->SetPropertyAttribute, 'LABEL_FILL_COLOR', $
            SENSITIVE=self._labelShow && (labelFillBackground ge 1)
        if (labelFillBackground eq 1) then begin
            ; If fill is 1, then change the fillcolor to -1 (match view).
            labelFillColor = -1
        endif else if (labelFillBackground eq 2) then begin
            ; If fill is 2 and the fillcolor was -1 (match view), make it white.
            self._oText->GetProperty, FILL_COLOR=oldLabelFillColor
            if (N_ELEMENTS(oldLabelFillColor) ne 3) then $
                labelFillColor = [255b, 255b, 255b]
        endif
        self._oText->SetProperty, $
            FILL_BACKGROUND=(labelFillBackground gt 0), $
            FILL_COLOR=labelFillColor
    endif


    if (N_ELEMENTS(labelShow)) then begin

        self._labelShow = KEYWORD_SET(labelShow)

        self._oLine->SetProperty, $
            LABEL_OBJECTS=self._labelShow ? self._oText: OBJ_NEW()

        ; Turn on/off labelling properties.
        self->SetPropertyAttribute, $
            ['LABEL_USE_COLOR', 'LABEL_POSITION', $
            'LABEL_FILL_BACKGROUND', $
            'FONT_INDEX', 'FONT_STYLE', 'FONT_SIZE'], $
            SENSITIVE=self._labelShow

        ; Only turn on label color prop if LABEL_USE_COLOR is also set.
        self._oLine->GetProperty, USE_LABEL_COLOR=labelUseColor
        self->SetPropertyAttribute, 'LABEL_COLOR', $
            SENSITIVE=self._labelShow && labelUseColor

        ; Only turn on label fill color if LABEL_FILL_BACKGROUND=2.
        self->IDLitVisMapGridline::GetProperty, $
            LABEL_FILL_BACKGROUND=labelFillBackground
        self->SetPropertyAttribute, 'LABEL_FILL_COLOR', $
            SENSITIVE=self._labelShow && (labelFillBackground eq 2)
    endif


    if (ISA(labelAngle)) then begin
      self._labelAngle = labelAngle

      self->_GetAlignment, align, valign

      if (labelAngle ge 0) then begin
        a = labelAngle*!DtoR
        baseline = [cos(a),sin(a),0]
        updir = [-sin(a),cos(a),0]
      endif

      self._oText->SetProperty, ALIGNMENT=align, VERTICAL_ALIGNMENT=valign, $
        BASELINE=baseline, UPDIR=updir
      self._oLine->SetProperty, USE_LABEL_ORIENTATION=labelAngle ge 0
    endif

    if (ISA(labelAlign)) then $
      self._oText->SetProperty, ALIGNMENT=labelAlign

    if (ISA(labelValign)) then $
      self._oText->SetProperty, VERTICAL_ALIGNMENT=labelValign

    if (ISA(linestyleIn)) then begin
      linestyle = ISA(linestyleIn, 'STRING') ? $
        LINESTYLE_CONVERT(linestyleIn) : linestyleIn
      self._oLine->SetProperty, LINESTYLE=linestyle
    endif

    if (ISA(labelColorIn)) then begin
      labelColor = labelColorIn
      if (isa(labelColorIn, 'STRING') || N_ELEMENTS(labelColorIn) eq 1) then $
        style_convert, labelColorIn, COLOR=labelColor
      self._oLine->GetProperty, COLOR=lineColor, USE_LABEL_COLOR=labelUseColor
      if (~ARRAY_EQUAL(labelColor, lineColor)) then begin
        labelUseColor = 1
        self._oLine->SetProperty, /USE_LABEL_COLOR
      endif
      if (labelUseColor) then $
        self._oText->SetProperty, COLOR=labelColor
    endif

    if (ISA(colorIn)) then begin
        color = colorIn
        if (ISA(colorIn, 'STRING') || N_ELEMENTS(colorIn) eq 1) then $
          style_convert, colorIn, COLOR=color
        self._oLine->SetProperty, COLOR=color
        self._oLine->GetProperty, USE_LABEL_COLOR=labelUseColor
        if (~labelUseColor) then $
            self._oText->SetProperty, COLOR=color
    endif

    if (N_ELEMENTS(zvalue) ne 0) then begin
        self._zvalue = zvalue
        self->IDLgrModel::GetProperty, TRANSFORM=transform
        transform[2,3] = zvalue
        self->IDLgrModel::SetProperty, TRANSFORM=transform
        ; put the visualization into 3D mode if necessary
        self->Set3D, (zvalue ne 0), /ALWAYS
    endif

    if (N_ELEMENTS(data) || N_ELEMENTS(polylines)) then $
        self._oLine->SetProperty, DATA=data, POLYLINES=polylines

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

    if (updateGrid) then $
        self->OnProjectionChange

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisMapGridline__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisMapGridline object.
;
;-
pro IDLitVisMapGridline__Define

    compile_opt idl2, hidden

    struct = { IDLitVisMapGridline,           $
        inherits IDLitVisualization,       $
        _oLine: OBJ_NEW(), $
        _oText: OBJ_NEW(), $
        _oFont: OBJ_NEW(), $
        _location: 0d, $
        _labelFormat: 0, $
        _labelPosition: 0d, $
        _labelShow: 0b, $
        _orientation: 0b, $
        _labelAngle: 0d, $
        _zvalue: 0d $
        }
end
