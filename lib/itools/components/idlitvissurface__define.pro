; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvissurface__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   The IDLitVisSurface class is the component wrapper for IDLgrSurface
;

;----------------------------------------------------------------------------
; IDLitVisSurface::_RegisterProperties
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
pro IDLitVisSurface::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Register our own COLOR property so it shows up before the
        ; USE_DEFAULT_COLOR in the property sheet.
        self->RegisterProperty, 'Color', /COLOR, $
            DESCRIPTION='Surface color'

        self->RegisterProperty, 'USE_DEFAULT_COLOR', /BOOLEAN, $
            NAME='Use color on bottom', $
            DESCRIPTION='Use the surface color for the bottom', /ADVANCED_ONLY
    endif

    ; Renamed BOTTOM to BOTTOM_COLOR in IDL80
    if (registerAll || updateFromVersion lt 800) then begin
      self->RegisterProperty, 'BOTTOM_COLOR', /COLOR, $
        NAME='Bottom color', DESCRIPTION='Bottom color'
    endif

    if (registerAll) then begin
        ; Now aggregate the surface properties.
        self->Aggregate, self._oSurface
    endif

    self->SetPropertyAttribute, 'BOTTOM', /HIDE

    if (registerAll) then begin

        ; Override some PropertyDescriptor attributes.
        self._oSurface->SetPropertyAttribute, /HIDE, $
            ['DEPTH_OFFSET', $
             'EXTENDED_LEGO', $
             'VERT_COLORS']
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of surface', $
            VALID_RANGE=[0,100,5]

        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

        ; Override some PropertyDescriptor attributes.
        self._oSurface->SetPropertyAttribute, /HIDE, $
            ['TEXTURE_MAP', $
             'AMBIENT', $
             'DIFFUSE', $
             'SPECULAR', $
             'EMISSION', $
             'SHININESS']
    endif

    if (registerAll) then begin
        ; Edit the current palette
        self->RegisterProperty, 'VISUALIZATION_PALETTE', $
            NAME='Image palette', $
            USERDEF='Edit color table', $
            DESCRIPTION='Image palette', $
            SENSITIVE=0, /ADVANCED_ONLY

        ; Byte-scale option for vertex colouring
        self._oSurface->RegisterProperty, 'SCALE_VERTEX_COLOR', $
            NAME='Vertex color scale', $
            USERDEF='Select vertex color scale bottom/top', $
            DESCRIPTION='Select vertex color scale bottom/top', $
            SENSITIVE=0, /ADVANCED_ONLY

        ; Byte-scale option for texture image
        self._oSurface->RegisterProperty, 'SCALE_TEXTURE_MAP_COLOR', $
            NAME='Texture map scale', $
            USERDEF='Select texture map scale bottom/top', $
            DESCRIPTION='Select texture map scale bottom/top', $
            SENSITIVE=0, /ADVANCED_ONLY

        ; For styles, hide these properties until we have data.
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], /HIDE

    endif
end

;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Syntax:
;
;    Obj = OBJ_NEW('IDLitVisSurface'[, Z[, X, Y]])
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
function IDLitVisSurface::Init, $
                                NAME=NAME, DESCRIPTION=DESCRIPTION,$
                                _REF_EXTRA=_extra

  compile_opt idl2, hidden

  if(not keyword_set(name))then name ="Surface"
  if(not keyword_set(DESCRIPTION))then DESCRIPTION ="A Surface Visualization"
  ;; Initialize superclasses
  if (self->IDLitVisualization::Init(TYPE="IDLSURFACE", $
                                     ICON='surface', $
                                     DESCRIPTION=DESCRIPTION, $
                                     NAME=NAME, _EXTRA=_extra) ne 1) then $
    RETURN, 0
  if (self->_IDLitVisGrid2D::Init(_EXTRA=_extra) ne 1) then $
    RETURN, 0

  self->Set3D, 1, /ALWAYS

  ;; Register the parameters we are using for data

  self->RegisterParameter, 'Z', DESCRIPTION='Z Data', $
    /INPUT, TYPES='IDLARRAY2D', /OPTARGET

  self->RegisterParameter, 'X', DESCRIPTION='X Data', $
    /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

  self->RegisterParameter, 'Y', DESCRIPTION='Y Data', $
    /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

  self->RegisterParameter, 'VERTEX COLORS', DESCRIPTION='Vertex colors', $
    /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

  self->RegisterParameter, 'TEXTURE', DESCRIPTION='Texture', $
    /INPUT, TYPES=['IDLARRAY3D','IDLARRAY2D', 'IDLIMAGEPIXELS'], /OPTIONAL

  self->RegisterParameter, 'PALETTE', $
    DESCRIPTION='Color Palette Data', $
    /INPUT, /OPTIONAL, /OPTARGET, TYPES=['IDLPALETTE','IDLARRAY2D']

  ;; Create Surface object and add it to this Visualization
  ;; What if this create fails?
  ;; NOTE: the IDLgrSurface properties will be aggregated as part
  ;; of the property registration process in an upcoming call to
  ;; ::_RegisterProperties.
  self._oSurface = OBJ_NEW('IDLgrSurface', $
                           /REGISTER_PROPERTIES, $
                           COLOR=[225,184,0], style=2,$
                           DEPTH_OFFSET=1, /EXTENDED_LEGO, /PRIVATE)
  self->Add, self._oSurface

  ;; Register all properties.
  self->IDLitVisSurface::_RegisterProperties

  ;; Set any properties
  if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisSurface::SetProperty, _EXTRA=_extra

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
pro IDLitVisSurface::Cleanup
  compile_opt idl2, hidden

  OBJ_DESTROY, self._oTexture

  ;; Cleanup superclass
  self->IDLitVisualization::Cleanup

  ;; Cleanup our palette
  if(obj_valid(self._oPalette))then $
    obj_destroy, self._oPalette
end


;----------------------------------------------------------------------------
; IDLitVisSurface::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisSurface::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oSurface)) then $
        self._oSurface->GetProperty

    ; Register new properties.
    self->IDLitVisSurface::_RegisterProperties, $
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
;   Any keyword to IDLitVisSurface::Init followed by the word "Get"
;   can be retrieved using this method.
;
pro IDLitVisSurface::GetProperty, $
  BOTTOM_COLOR=bottomColor, $
  VISUALIZATION_PALETTE=visPalette, $
  USE_DEFAULT_COLOR=useDefaultColor, $
  BYTESCALE_MIN=byteScaleMin, $
  BYTESCALE_MAX=byteScaleMax, $
  BYTESCALE_DATARANGE=byteScaleDataRange, $
  BYTESCALE_EXTENDRANGES=byteScaleExtendRanges, $
  ODATA=oData, $
  SCALE_VERTEX_COLOR=dispVertScale, $
  VERT_COLORS=vertColors, $
  SCALE_TEXTURE_MAP_COLOR=dispTextMapScale, $
  TRANSPARENCY=transparency, $
  _REF_EXTRA=_extra

  compile_opt idl2, hidden

  ; Renamed BOTTOM to BOTTOM_COLOR in IDL80
  if (ARG_PRESENT(bottomColor) || ARG_PRESENT(useDefaultColor)) then begin
    self._oSurface->GetProperty, BOTTOM=bottom
    bottomColor = bottom
    useDefaultColor = ARRAY_EQUAL(bottom, -1)
  endif

  if ARG_PRESENT(visPalette) && obj_valid(self._oPalette) then BEGIN
    self._oPalette->GetProperty, BLUE_VALUES=blue, $
      GREEN_VALUES=green, RED_VALUES=red
    visPalette = TRANSPOSE([[red], [green], [blue]])
  endif

  if (ARG_PRESENT(byteScaleMin)) then $
    byteScaleMin = self._byteScaleMin

  if (ARG_PRESENT(byteScaleMax)) then $
    byteScaleMax = self._byteScaleMax

  if (ARG_PRESENT(byteScaleDataRange)) then $
    byteScaleDataRange = self._byteScaleRange

  if (ARG_PRESENT(byteScaleExtendRanges)) then $
    byteScaleExtendRanges = self._byteScaleExtendRanges

  if (ARG_PRESENT(oData)) then $
    oData = *self._oData

  if (ARG_PRESENT(dispVertScale)) then $
    dispVertScale = [self._byteScaleMinVertColor,self._byteScaleMaxVertColor]

  if (ARG_PRESENT(vertColors)) then $
    vertColors = 0

  if (ARG_PRESENT(dispTextMapScale)) then $
    dispTextMapScale = [self._byteScaleMinTextMap,self._byteScaleMaxTextMap]

  if ARG_PRESENT(transparency) then begin
    self._oSurface->GetProperty, ALPHA_CHANNEL=alpha
    transparency = 0 > ROUND(100 - alpha*100) < 100
  endif

  ;; get superclass properties
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
;   Any keyword to IDLitVisSurface::Init followed by the word "Set"
;   can be set using this method.
;
pro IDLitVisSurface::SetProperty, $
  BOTTOM_COLOR=bottomColor, $
  USE_DEFAULT_COLOR=useDefaultColor, $
  SHOW_SKIRT=showSkirt, $
  STYLE=styleIn, $
  BYTESCALE_MIN=byteScaleMin, $
  BYTESCALE_MAX=byteScaleMax, $
  BYTESCALE_DATARANGE=byteScaleDataRange, $
  SCALE_VERTEX_COLOR=dispVertScale, $
  VERT_COLORS=swallow, $
  SCALE_TEXTURE_MAP_COLOR=dispTextMapScale, $
  COLOR=color, $
  TRANSPARENCY=transparency, $
  X_VIS_LOG=xVisLog, $
  Y_VIS_LOG=yVisLog, $
  Z_VIS_LOG=zVisLog, $
  VISUALIZATION_PALETTE=visPalette, $
  MIN_VALUE=minValue, $
  MAX_VALUE=maxValue, $
  _REF_EXTRA=_extra

  compile_opt idl2, hidden

  ;; Handle our properties.

  if (N_ELEMENTS(useDefaultColor)) then begin
    ;; Either set our bottom color to white (turning it on),
    ;; or reset it to -1 (turning it off).
    self._oSurface->SetProperty, $
      BOTTOM=KEYWORD_SET(useDefaultColor) ? -1 : [255,255,255]
    self->SetPropertyAttribute, 'BOTTOM_COLOR', $
      SENSITIVE=~KEYWORD_SET(useDefaultColor)
  endif

  if (ISA(bottomColor)) then begin
    self._oSurface->SetProperty, BOTTOM=bottomColor
  endif

  if (N_ELEMENTS(showSkirt)) then begin
    self._oSurface->SetPropertyAttribute, 'SKIRT', $
      SENSITIVE=KEYWORD_SET(showSkirt)
    self._oSurface->SetProperty, SHOW_SKIRT=showSkirt
  endif

  ; CT, RSI: Because of keyword conflict with STYLE_NAME,
  ; make sure our STYLE isn't a string. If it isn't,
  ; assume it is our surface style property.
  ; See IDLitSys_CreateTool code for details.
  if (ISA(styleIn)) then begin
    if (ISA(styleIn, 'STRING')) then begin
      case STRCOMPRESS(STRUPCASE(styleIn),/REMOVE) of
      'POINTS': style = 0
      'MESH': style = 1
      'FILLED': style = 2
      'RULEDXZ': style = 3
      'RULEDYZ': style = 4
      'LEGO': style = 5
      'LEGOFILLED': style = 6
      endcase
    endif else $
      style = LONG(styleIn)
  endif

  if (N_ELEMENTS(style)) then begin
    self._oSurface->SetPropertyAttribute, 'LINESTYLE', $
      SENSITIVE=(style eq 1) || (style eq 3) || (style eq 4) || (style eq 5)
    self._oSurface->SetPropertyAttribute, ['HIDDEN_LINES', 'THICK'], $
      SENSITIVE=(style ne 2) && (style ne 6)
    self._oSurface->SetPropertyAttribute, 'SHADING', $
      SENSITIVE=(style eq 2)
    self._oSurface->SetProperty, STYLE=style
    self->OnDataChange, self
    self->OnDataComplete, self
  endif

  if (N_ELEMENTS(byteScaleMin) gt 0) then begin
    self._byteScaleMin = byteScaleMin
  endif

  if (N_ELEMENTS(byteScaleMax) gt 0) then begin
    self._byteScaleMax = byteScaleMax
  endif

  if (N_ELEMENTS(byteScaleDataRange) gt 0) then begin
    self._byteScaleRange = byteScaleDataRange
  endif

  if (N_ELEMENTS(dispVertScale) gt 0) then begin
    self._byteScaleMinVertColor = dispVertScale[0:2]
    self._byteScaleMaxVertColor = dispVertScale[3:5]
    self->displayVertexColor
  endif

  if (N_ELEMENTS(transparency)) then begin
    self._oSurface->SetProperty, $
        ALPHA_CHANNEL=0 > ((100.-transparency)/100) < 1
  endif

  if (N_ELEMENTS(dispTextMapScale) gt 0) then begin
    self._byteScaleMinTextMap = dispTextMapScale[0:3]
    self._byteScaleMaxTextMap = dispTextMapScale[4:7]
    self->displayTextureMap
  endif

  IF (n_elements(color) GT 0) THEN BEGIN
    self._color=color
  ENDIF

  IF (n_elements(xVisLog) GT 0) && (xVisLog NE self._xVisLog) THEN BEGIN
    self._xVisLog = xVisLog
    self._oSurface->GetProperty, DATA=data
    xData = reform(data[0,*,*])
    if N_ELEMENTS(xData) GT 0 THEN BEGIN
      newX = (xVisLog GT 0) ? alog10(xData) : 10^xData
      self._oSurface->SetProperty, DATAX=newX
    ENDIF
  ENDIF

  IF (n_elements(yVisLog) GT 0) && (yVisLog NE self._yVisLog) THEN BEGIN
    self._yVisLog = yVisLog
    self._oSurface->GetProperty, DATA=data
    yData = reform(data[1,*,*])
    if N_ELEMENTS(yData) GT 0 THEN BEGIN
      newY = (yVisLog GT 0) ? alog10(yData) : 10^yData
      self._oSurface->SetProperty, DATAY=newY
    ENDIF
  ENDIF

  IF (n_elements(zVisLog) GT 0) && (zVisLog NE self._zVisLog) THEN BEGIN
    self._zVisLog = zVisLog
    self._oSurface->GetProperty, DATA=data
    zData = reform(data[2,*,*])
    if N_ELEMENTS(zData) GT 0 THEN BEGIN
      newZ = (zVisLog GT 0) ? alog10(zData) : 10^zData
      minn = min(newZ,max=maxx)
      self._oSurface->SetProperty, DATAZ=newZ, $
        MIN_VALUE=minn, MAX_VALUE=maxx
      ;; notify our observers in case the prop sheet is visible.
      self->DoOnNotify, self->GetFullIdentifier(), $
                        'SETPROPERTY', ''
    ENDIF
  ENDIF

  if obj_valid(self._oPalette) && (N_ELEMENTS(visPalette) gt 0) then begin
    self._oPalette->SetProperty, BLUE_VALUES=visPalette[2,*], $
      GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
    oPal = self->GetParameter('PALETTE')
    if OBJ_VALID(oPal) then $
      success = oPal->SetData(visPalette)
  endif

  IF (n_elements(minValue) EQ 1) THEN BEGIN
    self._oSurface->GetProperty, MAX_VALUE=maxSurf
    IF (minValue LT maxSurf) THEN $
      self._oSurface->SetProperty, MIN_VALUE=minValue
  ENDIF

  IF (n_elements(maxValue) EQ 1) THEN BEGIN
    self._oSurface->GetProperty, MIN_VALUE=minSurf
    IF (maxValue GT minSurf) THEN $
      self._oSurface->SetProperty, MAX_VALUE=maxValue
  ENDIF

  ;; Set superclass properties
  if (N_ELEMENTS(_extra) || n_elements(color)) then $
    self->IDLitVisualization::SetProperty, COLOR=color,_EXTRA=_extra
  
  ;; If min or max was changed, update the dataspace
  IF ((n_elements(minValue) EQ 1) || (n_elements(maxValue) EQ 1)) THEN BEGIN
    self->OnDataChange, self
    self->OnDataComplete, self
  ENDIF

END


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
pro IDLitVisSurface::GetData, arg1, arg2, arg3, _EXTRA=_extra
  compile_opt idl2, hidden
  
  oDataZ = self->GetParameter('Z')
  if (OBJ_VALID(oDataZ)) then $
    void = oDataZ->GetData(zData)
  oDataX = self->GetParameter('X')
  if (OBJ_VALID(oDataX)) then $
    void = oDataX->GetData(xData)
  oDataY = self->GetParameter('Y')
  if (OBJ_VALID(oDataY)) then $
    void = oDataY->GetData(yData)

  switch (N_PARAMS()) of
    3 : begin
          if (N_ELEMENTS(xData) ne 0) then $
            arg2 = xData
          if (N_ELEMENTS(yData) ne 0) then $
            arg3 = yData
        end
    1 : arg1 = zData
    else :
  endswitch
    
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   Z, X, Y
;
; Keywords:
;   NONE
;
pro IDLitVisSurface::PutData, Z, X, Y, _EXTRA=_extra
  compile_opt idl2, hidden
  
  ;; SetParameter requires a data object
  switch (N_PARAMS()) of 
    3 : begin
          oData = OBJ_NEW('IDLitData', X, /AUTO_DELETE)
          self->SetParameter, 'X', oData
          oData = OBJ_NEW('IDLitData', Y, /AUTO_DELETE)
          self->SetParameter, 'Y', oData
        end
    1 : begin
          oData = OBJ_NEW('IDLitData', Z, /AUTO_DELETE)
          self->SetParameter, 'Z', oData
        end 
    else :
  endswitch
  
  ; Send a notification message to update UI
  self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
  self->OnDataComplete, self

  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow
  
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisSurface::EnsureXYParameters
;
; PURPOSE:
;   Ensure that X and Y parameters exist, based on the surface data
;   dimensions.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisSurface::]EnsureXYParameters
;
; KEYWORD PARAMETERS:
;   None.
;
; USAGE:
;   This is used by operations such as IDLitOpInsertImage, that need
;   the surface parameter in order to create an image based on the
;   surface and to be notified of changes to the surface.
;-
pro IDLitVisSurface::EnsureXYParameters

    ; Retrieve Z parameter first to get data dimensions.
    oZParam = self->GetParameter('Z')
    if (~OBJ_VALID(oZParam)) then $
        return
    if (~(oZParam->GetData(pData, /POINTER))) then $
        return
    dims = SIZE(*pData, /DIMENSIONS)

    paramNames = ['X', 'Y']
    for i=0,1 do begin
        ; Check if parameter already exists.
        oParam = self->GetParameter(paramNames[i])
        if ~obj_valid(oParam) then begin
            ; Create and set the parameter.
            data = DINDGEN(dims[i])
            oData = OBJ_NEW('IDLitDataIDLVector', data, NAME=paramNames[i])
            oData->SetProperty, /AUTO_DELETE
            self->SetParameter, paramNames[i], oData, /NO_UPDATE

            ; Add to data manager.
            oData = self->GetParameter(paramNames[i])

            ; Add to the same container in which the Z data is contained.
            oZParam->GetProperty,_PARENT=oParent

            ; Note: the X,Y data should not be added to an
            ; IDLitDataIDLImagePixels object.  Keep walking up the tree.
            if (OBJ_ISA(oParent, 'IDLitDataIDLImagePixels')) then begin
                oImagePixels = oParent
                oImagePixels->GetProperty,_PARENT=oParent
            endif

            if obj_valid(oParent) then begin
                oParent->Add,oData
                ;; check to see if we need to mangle the name
                ;; Get our base name and append the id number.
                oData->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
                ;; See if we have an id number at the end of our identifier.
                idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
                ;; Append the id number.
                if (STRMATCH(idnum, '[0-9]*')) then begin
                  name += ' ' + idnum
                  ;; set new name
                  oData->IDLitComponent::SetProperty, NAME=name
                  oTool = self->GetTool()
                  oTool->DoOnNotify,oData->GetFullIdentifier(), $
                                    'SETPROPERTY','NAME'
                endif
            endif else $
                self->AddByIdentifier,'/DATA MANAGER',oData
        endif
    endfor

    ; Send a notification message to update UI
    self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''

end

;----------------------------------------------------------------------------
; Purpose:
;    Bytescale and display vertex colors
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
PRO IDLitVisSurface::displayVertexColor
  compile_opt idl2,hidden

  oVertColor = self->getParameter('VERTEX COLORS')
  success = (obj_valid(oVertColor) ? oVertColor->getData(vData) : 0)
  IF ~success THEN $
    return

    vTempData = vData
    ndim = size(vData,/n_dimensions)
    dims = size(vData,/dimensions)

    ;; if data is an array of RGB(A) values, scale each channel separately
    ; Handle either RGB or RGBA.
    IF ((ndim EQ 2) && (dims[0] EQ 3 || dims[0] eq 4)) THEN BEGIN
      vTempData[0,*] = bytscl(vData[0,*],MIN=self._byteScaleMinVertColor[0], $
                              MAX=self._byteScaleMaxVertColor[0])
      vTempData[1,*] = bytscl(vData[1,*],MIN=self._byteScaleMinVertColor[1], $
                              MAX=self._byteScaleMaxVertColor[1])
      vTempData[2,*] = bytscl(vData[2,*],MIN=self._byteScaleMinVertColor[2], $
                              MAX=self._byteScaleMaxVertColor[2])
    ENDIF

    ;; if not RGB values then scale entire set and reform to a vector
    IF ((ndim EQ 1) || (ndim eq 2 && dims[0] gt 4)) THEN BEGIN
      vTempData = reform(bytscl(vData,MIN=self._byteScaleMinVertColor[0], $
                                MAX=self._byteScaleMaxVertColor[0]), $
                         n_elements(vTempData))
    ENDIF

    self._oSurface->setProperty,vert_colors=vTempData
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

END


;----------------------------------------------------------------------------
; Purpose:
;    Bytescale and display texture map
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
PRO IDLitVisSurface::displayTextureMap
  compile_opt idl2,hidden

  oTextMap = self->getParameter('TEXTURE')
  success = (obj_valid(oTextMap) ? oTextMap->getData(tData) : 0)
  IF ~success THEN $
    return

    tTempData = tData

    ;; if data is an array of RGB[A] values, scale each channel separately
    IF (size(tData,/n_dimensions) EQ 3) THEN BEGIN
      tTempData[0,*,*]=bytscl(tData[0,*,*],MIN=self._byteScaleMinTextMap[0], $
                              MAX=self._byteScaleMaxTextMap[0])
      tTempData[1,*,*]=bytscl(tData[1,*,*],MIN=self._byteScaleMinTextMap[1], $
                              MAX=self._byteScaleMaxTextMap[1])
      tTempData[2,*,*]=bytscl(tData[2,*,*],MIN=self._byteScaleMinTextMap[2], $
                              MAX=self._byteScaleMaxTextMap[2])
      ;; if an alpha channel exists scale it
      IF ((size(tData,/dimensions))[0] EQ 4) THEN $
        tTempData[3,*,*] = $
        bytscl(tData[3,*,*],MIN=self._byteScaleMinTextMap[3], $
               MAX=self._byteScaleMaxTextMap[3])
    ENDIF

    ;; if not RGB values then scale entire set
    IF (size(tData,/n_dimensions) EQ 2) THEN BEGIN
      tTempData = bytscl(tData,MIN=self._byteScaleMinTextMap[0], $
                         MAX=self._byteScaleMaxTextMap[0])
    ENDIF

    self._oSurface->getProperty,texture_map=oTextMap
    oTextMap->setProperty,data=tTempData
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

END


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
function IDLitVisSurface::EditUserDefProperty, oTool, identifier
  compile_opt idl2, hidden

  CASE identifier OF

    'SCALE_VERTEX_COLOR': BEGIN
      IF ptr_valid(self._oData) && obj_valid((*self._oData)[0]) THEN BEGIN
        obj_destroy, *self._oData
        ptr_free,self._oData
      ENDIF
      oVert = self->getparameter('VERTEX COLORS')
      success = oVert->getData(vData)

      ;;if RGB then create vector of separate colours
      ;; and do not allow ranges to be extended
      ndim = size(vData,/n_dimensions)
      dims = size(vData,/dimensions)

      ; Handle either RGB or RGBA.
      IF ((ndim EQ 2) && (dims[0] EQ 3 || dims[0] eq 4)) THEN BEGIN
        self._oData = ptr_new([obj_new('IDLitData', NAME='VERTEX RED', $
                               reform(vData[0,*])), $
                       obj_new('IDLitData', NAME='VERTEX GREEN', $
                               reform(vData[1,*])), $
                       obj_new('IDLitData', NAME='VERTEX BLUE', $
                               reform(vData[2,*]))])
        self._byteScaleExtendRanges = 0b
      ENDIF

      ;;if vector or 2D array, pass on as is and allow extended ranges
      IF ((ndim EQ 1) || (ndim EQ 2 && dims[0] gt 4)) THEN BEGIN
        self._oData = ptr_new(obj_new('IDLitData',NAME='VERTEX COLORS',vData))
        self._byteScaleExtendRanges = 1b
      ENDIF

      IF ~obj_valid((*self._oData)[0]) THEN return,0
      ;;set values for Vertex colour
      self._byteScaleMin = self._byteScaleMinVertColor
      self._byteScaleMax = self._byteScaleMaxVertColor
      self._byteScaleRange = self._byteScaleRangeVertColor
      success = oTool->DoUIService('DataBottomTop', self)

      ;;destroy IDLitData objects used herein
      IF ptr_valid(self._oData) && obj_valid((*self._oData)[0]) THEN BEGIN
        obj_destroy, *self._oData
        ptr_free,self._oData
      ENDIF

      ;;save results and update display
      IF success THEN BEGIN
        self._byteScaleMinVertColor = self._byteScaleMin[0:2]
        self._byteScaleMaxVertColor = self._byteScaleMax[0:2]
        self._byteScaleRangeVertColor = self._byteScaleRange
        self->displayVertexColor
        return, 1
      ENDIF
    END

    'SCALE_TEXTURE_MAP_COLOR': BEGIN
      IF ptr_valid(self._oData) && obj_valid((*self._oData)[0]) THEN BEGIN
        obj_destroy, *self._oData
        ptr_free,self._oData
      ENDIF
      oTextMap = self->getparameter('TEXTURE')
      success = oTextMap->getData(tData)

      IF success THEN BEGIN
        ;;if RGB[A] then create vector of separate colours
        ;; and do not allow ranges to be extended
        IF (size(tData,/n_dimensions) EQ 3) THEN BEGIN
          self._oData = ptr_new([obj_new('IDLitData', NAME='TEXTURE RED', $
                                         reform(tData[0,*])), $
                                 obj_new('IDLitData', NAME='TEXTURE GREEN', $
                                         reform(tData[1,*])), $
                                 obj_new('IDLitData', NAME='TEXTURE BLUE', $
                                         reform(tData[2,*]))])
          IF ((size(tData,/dimensions))[0] EQ 4) THEN $
            *self._oData = [*self._oData, $
                            obj_new('IDLitData', NAME='TEXTURE ALPHA', $
                                    reform(tData[3,*]))]
          self._byteScaleExtendRanges = 0b
        ENDIF

        ;;2D array, pass on as is and allow extended ranges
        IF ((size(tData,/n_dimensions))[0] EQ 2) THEN BEGIN
          self._oData=ptr_new(obj_new('IDLitData',NAME='TEXTURE IMAGE',tData))
          self._byteScaleExtendRanges = 1b
        ENDIF

        IF ~obj_valid((*self._oData)[0]) THEN return,0
        ;;set values for Texture map
        self._byteScaleMin = self._byteScaleMinTextMap
        self._byteScaleMax = self._byteScaleMaxTextMap
        self._byteScaleRange = self._byteScaleRangeTextMap
        success = oTool->DoUIService('DataBottomTop', self)

        ;;destroy IDLitData objects used herein
        IF ptr_valid(self._oData) && obj_valid((*self._oData)[0]) THEN BEGIN
          obj_destroy, *self._oData
          ptr_free,self._oData
        ENDIF

        ;;save results and update display
        IF success THEN BEGIN
          self._byteScaleMinTextMap = self._byteScaleMin
          self._byteScaleMaxTextMap = self._byteScaleMax
          self._byteScaleRangeTextMap = self._byteScaleRange
          self->displayTextureMap
          return, 1
        ENDIF
      ENDIF

    END

    'VISUALIZATION_PALETTE': BEGIN
      success = oTool->DoUIService('PaletteEditor', self)
      IF success THEN BEGIN
        self._myPalette = 0
        self._myPaletteID = ''
        return, 1
      ENDIF
    END

    ELSE:

  ENDCASE

  ;; Call our superclass.
  return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

END

;----------------------------------------------------------------------------
; Purpose:
;   un/set the palette property
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
PRO IDLitVisSurface::SetPaletteAttribute
  compile_opt hidden, idl2

  ;; determine if a palette is currently useful or needed
  oVertColor = self->getParameter('VERTEX COLORS')
  vSuccess = (obj_valid(oVertColor) ? oVertColor->getData(vData) : 0)
  vDims = (vSuccess ? size(vData,/n_dimensions) : 0)
  dataDims = SIZE(vData, /DIMENSIONS)
  oTextMap = self->getParameter('TEXTURE')
  tSuccess = (obj_valid(oTextMap) ? oTextMap->getData(tData) : 0)
  tDims = (tSuccess ? size(tData,/n_dimensions) : 0)
  needPalette = (tDims EQ 2) || (vDims EQ 1) || $
    ((vDims eq 2) && (dataDims[0] gt 4))

  ;; do we have a valid palette?
  oPalette = self->getParameter('PALETTE')
  pSuccess = (obj_valid(oPalette) ? oPalette->getData(pData) : 0)

  IF needPalette THEN BEGIN
    self->setPropertyAttribute,'VISUALIZATION_PALETTE',SENSITIVE=1
    ;; if we have a valid palette just return
    IF pSuccess THEN return

    ;; if no palette exists, create a gray scale palette
    ;; first check to see if we have one lying around
    oTool = self->GetTool()
    oPalette = oTool->getByIdentifier(self._myPaletteID)
    IF obj_valid(oPalette) THEN BEGIN
      success = self->setData(oPalette,PARAMETER_NAME='PALETTE')
      self._myPalette = 1
    ENDIF ELSE BEGIN
      ramp = BINDGEN(256)
      oGrayPalette = OBJ_NEW('IDLitDataIDLPalette', $
                             TRANSPOSE([[ramp],[ramp],[ramp]]), $
                             NAME='PALETTE')
      oGrayPalette->SetProperty,/AUTO_DELETE
      success = self->setData(oGrayPalette,PARAMETER_NAME='PALETTE')
      oPalette = self->getParameter('PALETTE')

      ;; add to the same container in which the primary surface data
      ;; is contained
      oZ = self->GetParameter('Z')
      IF obj_valid(oZ) THEN BEGIN
        oZ->GetProperty,_PARENT=oParent
        IF obj_valid(oParent) THEN BEGIN
          oParent->Add,oPalette
          ;; check to see if we need to mangle the name
          ;; Get our base name and append the id number.
          oPalette->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
          ;; See if we have an id number at the end of our identifier.
          idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
          ;; Append the id number.
          IF (STRMATCH(idnum, '[0-9]*')) THEN BEGIN
            name += ' ' + idnum
            ;; set new name
            oPalette->IDLitComponent::SetProperty, NAME=name
            oTool = self->GetTool()
            oTool->DoOnNotify,oPalette->GetFullIdentifier(), $
                              'SETPROPERTY','NAME'
          ENDIF
        ENDIF ELSE BEGIN
          self->AddByIdentifier,'/DATA MANAGER',oPalette
        ENDELSE
      ENDIF

      self._myPalette = 1
      self._myPaletteID = oPalette->getFullIdentifier()
    ENDELSE
  ENDIF ELSE BEGIN
    ;; if the palette was the default gray scale, delete it
    IF pSuccess && self._myPalette THEN BEGIN
      self->unSetParameter,'PALETTE'
      obj_destroy,oPalette
      self._myPaletteID = ''
    ENDIF
    self._myPalette = 0
    ;; do we still have a valid palette?
    oPalette = self->getParameter('PALETTE')
    pSuccess = (obj_valid(oPalette) ? oPalette->getData(pData) : 0)
    self->setPropertyAttribute,'VISUALIZATION_PALETTE',SENSITIVE=pSuccess
  ENDELSE

END

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;;----------------------------------------------------------------------------
;; IDLitVisSurface::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the surface.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLitVisSurface::OnDataDisconnect, ParmName
  compile_opt hidden, idl2

  ;; Just check the name and perform the desired action
  case ParmName of

    'Z': begin
      ;; You can't unset data, so we hide the surface.
      self._oSurface->SetProperty, DATAZ=[[0,0],[0,0]]
      self._oSurface->SetProperty, /hide
    end

    'X': begin
      ;; Switch to an indgen for dims.
      self._oSurface->GetProperty, data=dataz
      szDims = size(dataz,/dimensions)
      dataz=0b
      self._oSurface->Setproperty, datax=indgen(szDims[1])
    end

    'Y':begin
      ;; Switch to an indgen
      self._oSurface->GetProperty, data=dataz
      szDims = size(dataz,/dimensions)
      dataz=0b
      self._oSurface->Setproperty, datay=indgen(szDims[2])
    end

    'VERTEX COLORS':begin
      self._oSurface->SetProperty, VERT_COLORS=0
      self->SetPropertyAttribute, SENSITIVE=0, 'SCALE_VERTEX_COLOR'
      self->SetPropertyAttribute, SENSITIVE=1, 'COLOR'
      self->SetPropertyAttribute, SENSITIVE=1, 'USE_DEFAULT_COLOR'
      self->getProperty,USE_DEFAULT_COLOR=useDefault
      self->SetPropertyAttribute, SENSITIVE=~useDefault, 'BOTTOM_COLOR'
      self->SetPaletteAttribute
    end

    'PALETTE': if(obj_valid(self._oPalette) ne 0)then begin
      self._oSurface->SetProperty, PALETTE=obj_new()
      if(obj_valid(self._oTexture))then $
        self._oTexture->SetProperty, PALETTE=obj_new()
      obj_destroy, self._oPalette
      self->SetPaletteAttribute
    end

    'TEXTURE':if(obj_valid(self._oTexture) ne 0)then BEGIN
      self._oSurface->SetProperty, TEXTURE_MAP=obj_new(), COLOR=self._color
      obj_destroy, self._oTexture

      self->SetPropertyAttribute, 'TEXTURE_MAP', USERDEF=''
      self->SetPropertyAttribute, SENSITIVE=0, $
        ['TEXTURE_HIGHRES', 'TEXTURE_INTERP', 'ZERO_OPACITY_SKIP', $
         'SCALE_TEXTURE_MAP_COLOR']
      self->GetPropertyAttribute, 'STYLE', $
        ENUMLIST=enumlist
      if (N_ELEMENTS(enumlist) eq 5) then begin
        self->SetPropertyAttribute, 'STYLE', $
          ENUMLIST=[enumlist, 'Lego', 'Lego filled']
      endif
      self->SetPaletteAttribute
    end

    else:

  endcase

  ;; Since we are changing a bunch of attributes, notify
  ;; our observers in case the prop sheet is visible.
  self->DoOnNotify, self->GetFullIdentifier(), $
    'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
; To avoid errors, make sure the number of elements in X or Y matches
; up with Z data.
;
; Returns 1 for success, 0 otherwise. If success then the X or Y data
; is contained in the data argument, otherwise it is undefined.
;
; Input:
;   Param: 'X' or 'Y'
;
; Output:
;   Data: Array containing the X or Y data, or undefined if not successful.
;
function IDLitVisSurface::_ValidateXYParameter, param, data

    compile_opt idl2, hidden

    ; First retrieve Z dimensions.
    oZ = self->GetParameter('Z')
    if (~OBJ_VALID(oZ) || ~oZ->GetData(pZ, /POINTER)) then $
        return, 0
    zdim = SIZE(*pZ, /DIMENSIONS)

    oParam = self->GetParameter(param)
    if (~OBJ_VALID(oParam) || ~oParam->GetData(mydata)) then $
        return, 0

    if (min(mydata, MAX=maxx) eq maxx) then $
        return, 0

    ndim = SIZE(mydata, /N_DIM)

    ; Vector X/Y?
    if (ndim eq 1) then begin
        ; Which dimension to check.
        zdim1 = (param eq 'X') ? zdim[0] : zdim[1]
        if (N_ELEMENTS(mydata) ne zdim1) then $
            return, 0
    endif else begin
        ; 2D X/Y
        dims = SIZE(mydata, /DIM)
        if (~ARRAY_EQUAL(dims, zdim)) then $
            return, 0
    endelse

    ; If we reach here then success.
    data = TEMPORARY(mydata)
    return, 1
end


;;----------------------------------------------------------------------------
;; IDLitVisSurface::OnDataChangeUpdate
;;
;; Purpose:
;;   This method is called when the data associated with a parameter
;;   has changed. When called, the visualization performs the
;;   desired updates to reflect the change
;;
;; Parameters
;    oSubject    - The data item for the parameter that has changed.
;;
;;   parmName    - The name of the parameter that has changed.
;;
;;

pro IDLitVisSurface::OnDataChangeUpdate, oSubject, parmName
  compile_opt idl2, hidden
  CASE STRUPCASE(parmName) OF

    '<PARAMETER SET>' : BEGIN
        dataNames = ['PALETTE','VERTEX COLORS','TEXTURE']
        oData = oSubject->GetByName('Z',count=nCount)
        if (ncount ne 0) then begin
            self->OnDataChangeUpdate,oData,'Z'
        endif else begin
            ; If Z was present then X and Y have already been set.
            ; Otherwise if Z wasn't present then include them here.
            dataNames = ['X', 'Y', dataNames]
        endelse
      FOR i=0,n_elements(dataNames)-1 DO BEGIN
        oData = oSubject->GetByName(dataNames[i],count=nCount)
        IF nCount NE 0 THEN self->OnDataChangeUpdate,oData,dataNames[i]
      ENDFOR
      self->_IDLitVisGrid2D::OnDataChangeUpdate, oSubject, parmName
    END

    'Z': BEGIN
      if (~oSubject->GetData(zData, NAN=nan)) then $
        break

        zDims = SIZE(zData, /DIMENSIONS)

        ; Reset the X and Y along with the Z so that all are up-to-date
        ; simultaneously.
        success = self->_ValidateXYParameter('X', xData)
        success = self->_ValidateXYParameter('Y', yData)

        mn = MIN(zData, MAX=mx, NAN=nan)
        self._oSurface->SetProperty, DATAZ=temporary(zData), $
           DATAX=xData, $
           DATAY=yData, $
           MIN_VALUE=mn, MAX_VALUE=mx, HIDE=0

        ; These properties were disabled for styles. Reenable them.
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], HIDE=0
    END

    'X': BEGIN
        if (self->_ValidateXYParameter('X', xData)) then begin
            self._oSurface->SetProperty, DATAX=temporary(xData)
        endif
        END

    'Y': BEGIN
        if (self->_ValidateXYParameter('Y', yData)) then begin
            self._oSurface->SetProperty, DATAY=temporary(yData)
        endif
        END

    'VERTEX COLORS': BEGIN
      success = oSubject->GetData(vData)
      IF (success) THEN BEGIN
        ndim = size(vData,/n_dimensions)
        dims = size(vData, /dimensions)
        ; Handle either RGB or RGBA.
        IF ((ndim EQ 2) && (dims[0] EQ 3 || dims[0] eq 4)) THEN BEGIN
          self._byteScaleMinVertColor = [0,0,0]
          self._byteScaleMaxVertColor = [255,255,255]
          self._byteScaleRangeVertColor = [0,255]
        ENDIF

        IF ((ndim EQ 1) || (ndim EQ 2 && dims[0] gt 4)) THEN BEGIN
          IF (max(size(vData,/type) EQ [4,5,6,7,8,9,10,11]) EQ 0) $
            THEN BEGIN
            self._byteScaleMinVertColor[0] = 0
            self._byteScaleMaxVertColor[0] = MAX(vData) > 255
          ENDIF ELSE BEGIN
            self._byteScaleMinVertColor[0] = MIN(vData, MAX=maxx)
            self._byteScaleMaxVertColor[0] = maxx
          ENDELSE
          self._byteScaleRangeVertColor = $
            [min(self._byteScaleMinVertColor),max(self._byteScaleMaxVertColor)]
        ENDIF

        self->displayVertexColor
        self->SetPropertyAttribute, SENSITIVE=1, 'SCALE_VERTEX_COLOR'
        self->SetPropertyAttribute, SENSITIVE=0, 'COLOR'
        self->SetPropertyAttribute, SENSITIVE=0, 'USE_DEFAULT_COLOR'
        self->SetPropertyAttribute, SENSITIVE=0, 'BOTTOM_COLOR'
        self->SetPaletteAttribute

      ENDIF ELSE BEGIN
        oPSet = self->getParameterSet()
        oPset->remove,oSubject
      ENDELSE
    END

    'PALETTE': BEGIN
      success = oSubject->GetData(pData)
      IF (success) THEN BEGIN
        obj_destroy, self._oPalette
        self._oPalette = obj_new('IDLgrPalette',pData[0,*],pData[1,*], $
                                 pData[2,*])
        self._oSurface->SetProperty, PALETTE=self._oPalette
        IF (obj_valid(self._oTexture)) then $
          self._oTexture->setproperty, palette=self._oPalette

        self._myPalette = 0
        self->SetPaletteAttribute

      ENDIF
    END

    'TEXTURE': BEGIN
      success = oSubject->GetData(tObj)
      IF success THEN BEGIN
        ;; check to see if a current texture map exits
        curTexture = obj_valid(self._oTexture)
        OBJ_DESTROY, self._oTexture

        ;; if data is 3D move channel dimension to the first position
        ;; Note: if array dimensions contain more than one 3 or 4 use
        ;; the first occurrence as the channel dimension
        IF (size(tObj,/n_dimensions))[0] EQ 3 THEN BEGIN
          sz = size(tObj,/dimensions)
          IF ((((wh=where(sz EQ 3, complement=comp)))[0] NE -1) || $
              (((wh=where(sz EQ 4, complement=comp)))[0] NE -1)) && $
            (comp[0] NE -1) THEN $
            tObj = byte(transpose(tObj,[wh,comp]))
          ;; set min, max, and ranges
          self._byteScaleMinTextMap = [0,0,0,0]
          self._byteScaleMaxTextMap = [255,255,255,255]
          self._byteScaleRangeTextMap = [0,255]
        ENDIF ELSE BEGIN
          IF ((where(size(tObj,/type) EQ [0l,4,5,6,7,8,9,10,11]))[0] EQ -1) $
            THEN BEGIN
            self._byteScaleMinTextMap[0] = 0
            self._byteScaleMaxTextMap[0] = $
              (max(tObj) LE 255) ? 255 : max(tObj)
          ENDIF ELSE BEGIN
            self._byteScaleMinTextMap[0] = 0
            self._byteScaleMaxTextMap[0] = max(tObj)
          ENDELSE
          self._byteScaleRangeTextMap = $
            [min(self._byteScaleMinTextMap),max(self._byteScaleMaxTextMap)]
        ENDELSE

        self._oTexture = obj_new('IDLgrImage',tObj)
        IF (obj_valid(self._oPalette)) THEN $
          self._oTexture->setproperty, palette=self._oPalette

        self._oSurface->SetProperty, TEXTURE_MAP=self._oTexture

        self->SetPaletteAttribute

        self->displayTextureMap

        self._oSurface->GetProperty, STYLE=style
        IF ((style EQ 5) || (style EQ 6)) THEN $
          self->SetProperty, STYLE=2
        self->GetPropertyAttribute, 'STYLE', $
          ENUMLIST=enumlist
        IF (N_ELEMENTS(enumlist) GT 5) THEN BEGIN
          self->SetPropertyAttribute, 'STYLE', $
            ENUMLIST=enumlist[0:4]
        ENDIF

        IF ~curTexture THEN BEGIN
          ;; For the texturemap to display properly, set the surface
          ;; to white.

          ;; store current color
          self._oSurface->GetProperty, COLOR=sColor
          self._color = sColor
          ;; set surface to white
          self._oSurface->setproperty,color=[255,255,255]
        ENDIF
      ENDIF
    END

    ELSE:

  ENDCASE

    self->SetPropertyAttribute, SENSITIVE=OBJ_VALID(self._oTexture), $
        ['TEXTURE_HIGHRES', 'TEXTURE_INTERP', 'ZERO_OPACITY_SKIP', $
        'SCALE_TEXTURE_MAP_COLOR']

    ; Since we are changing a bunch of attributes, notify
    ; our observers in case the prop sheet is visible.
    self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

END


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisSurface::SetParameter
;
; PURPOSE;
;   This procedure method associates a data object with the given
;   parameter.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisSurface::]SetParameter, ParamName, oItem
;
; INPUTS:
;   ParamName:  The name of the parameter to set.
;   oItem:  The IDLitData object to be associated with the
;     given parameter.
;-
pro IDLitVisSurface::SetParameter, ParamName, oItem, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (STRUPCASE(ParamName) eq 'Z') then begin
        oItem->GetProperty, NAME=name
        if (STRLEN(name) gt 0) then $
            self->StatusMessage, 'Surface target: '+name
    endif

    ; Pass along to the superclass.
    self->IDLitParameter::SetParameter, ParamName, oItem, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisSurface::GetDataString, xyz
  compile_opt idl2, hidden

  xyz = STRCOMPRESS(STRING(xyz, FORMAT='(G11.4)'))
  value = STRING(xyz, FORMAT='("X: ",A,"  Y: ",A,"  Z: ",A)')

  return, value

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisSurface__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisSurface object.
;
;-
pro IDLitVisSurface__Define
  compile_opt idl2, hidden

  struct = { IDLitVisSurface,              $
             inherits IDLitVisualization,  $ ; Superclass: _IDLitVisualization
             inherits _IDLitVisGrid2D,     $ ; Superclass
             _color: [0b,0b,0b],           $
             _oData: PTR_NEW(),            $
             _byteScaleMin: [0.0d,0,0,0],  $
             _byteScaleMax: [0.0d,0,0,0],  $
             _byteScaleRange: [0.0d,0],    $
             _byteScaleExtendRanges: 0b,   $
             _byteScaleMinVertColor: [0.0d,0,0], $
             _byteScaleMaxVertColor: [0.0d,0,0], $
             _byteScaleRangeVertColor: [0.0d,0], $
             _byteScaleMinTextMap: [0.0d,0,0,0], $
             _byteScaleMaxTextMap: [0.0d,0,0,0], $
             _byteScaleRangeTextMap: [0.0d,0], $
             _xVisLog : 0, $
             _yVisLog : 0, $
             _zVisLog : 0, $
             _oSurface: OBJ_NEW(),         $ ; IDLgrSurface object
             _oTexture: OBJ_NEW(),         $ ; IDLgrImage object
             _oPalette: OBJ_NEW(),         $ ; IDLgrPalette object
             _myPalette: 0,                $
             _myPaletteID: ''              $
           }

end
