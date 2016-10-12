; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitviscontour__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   The IDLitVisContour class is the component wrapper for IDLgrContour
;

;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Syntax:
;
;    Obj = OBJ_NEW('IDLitVisContour'[, Z[, X, Y]])
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
function IDLitVisContour::Init, NAME=NAME,$
                        DESCRIPTION=desc,_REF_EXTRA=_extra

   compile_opt idl2, hidden

    ;; Initialize superclass
    if (self->IDLitVisualization::Init( $
        NAME=KEYWORD_SET(name) ? name : 'Contour', $
        DESCRIPTION=KEYWORD_SET(desc) ? desc :'Contour level visualization', $
        TYPE="IDLCONTOUR", $
        ICON='contour', $
        _EXTRA=_extra) ne 1) then $
     RETURN, 0


    self._oPalette = OBJ_NEW('IDLgrPalette')

   ; We assume that we are PLANAR initially.
    self._oContour = OBJ_NEW('IDLgrContour', /ANTIALIAS, /PLANAR, $
                        ; start with palette disconnected for default
                        ;PALETTE=self._oPalette, $
                        COLOR=[0,0,0], $
                        /HIDE, $
                        /REGISTER_PROPERTIES, /PRIVATE)

    ;; Expose the properties for the standard IDL gr surface
    self->Add, self._oContour, /AGGREGATE

    self._oLevels = OBJ_NEW('IDLitVisContourContainer', $
        NAME='Contours', /PROPERTY_INTERSECTION)
    self._oLevels->SetPropertyAttribute, $
        ['NAME', 'DESCRIPTION', 'HIDE'], /HIDE

    ; CT: We temporarily aggregate our Contour Level container,
    ; so styles will pick up all the CL properties. Once we have
    ; data, we will remove the CL container from the aggregate,
    ; so that these properties won't show up in the property sheet
    ; for the contour. That way, in the Style Editor you can access
    ; all the level properties directly from contour.
    ; In the Vis Browser you can only change the level props via
    ; the multicolumn prop sheet.
    self->Add, self._oLevels, /AGGREGATE, /NO_UPDATE

    ; Add a generic "first" level, to pick up all the properties.
    oLevel = OBJ_NEW('IDLitVisContourLevel', NAME='Level 0', ID='Level_0')

    ; Retrieve the registered props so we can filter them in Get/SetProperty.
    registered = oLevel->QueryProperty()
    keep = Bytarr(N_ELEMENTS(registered))
    for i=0,N_ELEMENTS(registered)-1 do begin
      oLevel->GetPropertyAttribute, registered[i], HIDE=hidden
      ;; Filter out hidden properties
      keep[i] = ~hidden
    endfor
    registered = registered[Where(keep)]
    
    self._pProps = PTR_NEW(registered)

    self._oLevels->Add, oLevel, /AGGREGATE, /NO_UPDATE, /INTERNAL
    
    self->IDLitVisContour::_RegisterParameters
    self->IDLitVisContour::_RegisterProperties

    ; set defaults
    self._palColor = 0
    self._defaultIndices = 1
    self._tickinterval = 0.2d
    self._ticklen = 0.1d


    if (N_ELEMENTS(_extra) gt 0) then $
      self->IDLitVisContour::SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
pro IDLitVisContour::_RegisterParameters

    compile_opt idl2, hidden

    self->RegisterParameter, 'Z', DESCRIPTION='Z Data', $
                            /INPUT, TYPES='IDLARRAY2D', /OPTARGET

    self->RegisterParameter, 'X', DESCRIPTION='X Data', $
                            /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], $
                            /OPTIONAL

    self->RegisterParameter, 'Y', DESCRIPTION='Y Data', $
                            /INPUT, TYPES=['IDLVECTOR','IDLARRAY2D'], $
                            /OPTIONAL

    self->RegisterParameter, 'PALETTE', DESCRIPTION='RGB Color Table', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTIONAL, /OPTARGET

    self->RegisterParameter, 'RGB_INDICES', DESCRIPTION='Color Table Indices', $
        /INPUT, TYPES='IDLVECTOR', /OPTIONAL

    self->RegisterParameter, 'VERTICES', DESCRIPTION='Contour Level Vertices', $
        INPUT=0, /OUTPUT, TYPES='IDLARRAY2D', /OPTIONAL

    self->RegisterParameter, 'CONNECTIVITY', DESCRIPTION='Contour Level Connectivity', $
        INPUT=0, /OUTPUT, TYPES='IDLVECTOR', /OPTIONAL

end


;----------------------------------------------------------------------------
; IDLitVisContour::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisContour::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisContour::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

   compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll || (updateFromVersion lt 610)) then begin

        self->RegisterProperty, 'GRID_UNITS', $
            DESCRIPTION='Grid units', $
            NAME='Grid units', $
            ENUMLIST=['Not applicable','Meters','Degrees'], $
            SENSITIVE=0, /ADVANCED_ONLY

    endif


    if (registerAll) then begin

        self->RegisterProperty, 'CONTOUR_LEVELS', $
            USERDEF='Click to edit', $
            NAME='Contour level properties', $
            DESCRIPTION='Edit properties of individual contour levels'

        self->RegisterProperty, 'PAL_COLOR', /BOOLEAN, $
            DESCRIPTION='Use palette for level colors', $
            NAME='Use palette color', /ADVANCED_ONLY

        self->RegisterProperty, 'VISUALIZATION_PALETTE', /HIDE, $
            NAME='Levels color table', $
            USERDEF='Edit color table', $
            DESCRIPTION='Edit Levels Color Table', /ADVANCED_ONLY

        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Planar Z value', $
            DESCRIPTION='Z value on which to project contours.', /ADVANCED_ONLY

        ;; Override the PropertyDescriptor attributes.
        self->SetPropertyAttribute, /HIDE, $
            ['COLOR', 'DEPTH_OFFSET', 'PALETTE']

        self->SetPropertyAttribute, ['TICKLEN', 'TICKINTERVAL'], $
            VALID_RANGE=[0.01d,1,0.01d]

            ; For styles, hide these properties until we have data.
        self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], /HIDE

        ; LABEL_COLOR, and FONT_* are needed for the new Graphics property buttons.
        self->RegisterProperty, 'LABEL_COLOR', /COLOR, /HIDE, $
            NAME='Label color', $
            DESCRIPTION='Color of labels'

        oFont = OBJ_NEW('IDLitFont')
        oFont->GetPropertyAttribute, 'FONT_INDEX', ENUMLIST=enumlist
        OBJ_DESTROY, oFont

        self->RegisterProperty, 'FONT_INDEX', /HIDE, $
            ENUMLIST=enumlist, $
            NAME='Text font', $
            DESCRIPTION='Font name'

        self->RegisterProperty, 'FONT_STYLE', /HIDE, $
            ENUMLIST=['Normal', 'Bold', 'Italic', 'Bold Italic'], $
            NAME='Text style', $
            DESCRIPTION='Font style'

        self->RegisterProperty, 'FONT_SIZE', /HIDE, /FLOAT, $
            NAME='Text font size', $
            DESCRIPTION='Font size in points'
    endif


    if (registerAll || (updateFromVersion lt 610)) then begin

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of contour', $
            VALID_RANGE=[0,100,5]
        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

    endif


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
pro IDLitVisContour::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oPalette

    ; Destroy any contained text/symbol objects.
    self._oContour->GetProperty, C_LABEL_OBJECTS=c_label_objects
    OBJ_DESTROY, c_label_objects

    ; Destroy our level objects.
    OBJ_DESTROY, self._oLevels

    PTR_FREE, self._pProps
    PTR_FREE, self._pShow
    
    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end


;----------------------------------------------------------------------------
; IDLitVisContour::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisContour::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oContour)) then $
        self._oContour->GetProperty

    ; Register new properties.
    self->IDLitVisContour::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

end


;;----------------------------------------------------------------------------
;; Purpose:
;;   This function method is used to cyclically fill in parameters if needed
;;
;; Arguments:
;;   PARAMETERNAME - String name of registered parameter
;;
;;   PARAMETER - Old value of parameter.  Values will be cyclically
;;               repeated as needed.
;;
;; Keywords:
;;   FORCE2D - set if the parameter is supposed to be a 2D array.  This
;;          allows for handling the case of one colour which seems to
;;          be a 3 element vector instead of a 3x1 array.
;;
PRO IDLitVisContour::_FillParameter, parameterName, parameter, FORCE2D=force2D
  compile_opt idl2, hidden

  IF (n_elements(parameterName) EQ 1) && (n_elements(parameter) NE 0) THEN BEGIN
    self._oContour->GetProperty,N_LEVELS=nLev
    IF nLev LE 1 THEN return

    ;; ensure that all parameters are arrays
    IF n_elements(parameter) EQ 1 THEN $
      parameter = reform(parameter,1)

    ;; ensure that what should be 2D is 2D
    twoD = KEYWORD_SET(force2D) || SIZE(parameter,/N_DIM) eq 2
    IF (twod) THEN begin
      IF size(parameter,/n_dimensions) LT 2 THEN $
        parameter = reform(parameter,n_elements(parameter),1)
    endif

    ;; if needed, make new array and fill in cyclically
    sz = size(parameter)
    oldSize = sz[sz[0]]
    IF oldSize LT nLev THEN BEGIN
      sz[sz[0]] = nLev
      ;; make new array
      newParameter = make_array(size=sz)
      ;; fill in new array
      IF (twod) THEN BEGIN
        FOR i=0,nLev-1 DO $
          newParameter[*,i] = parameter[*,i MOD oldSize]
      ENDIF ELSE BEGIN
        FOR i=0,nLev-1 DO $
          newParameter[i] = parameter[i MOD oldsize]
      ENDELSE

      ;; set the new values
      self->SetPropertyByIdentifier,parameterName,newParameter

    ENDIF

  ENDIF

END

;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to retrieve the contourLevel objects.
;
; Arguments:
;   None
;
; Keywords:
;   None.
;
function IDLitVisContour::_GetLevels, N_LEVELS=nlevels

    compile_opt idl2, hidden

    if (~N_ELEMENTS(nlevels) || nlevels le 0) then begin
        self._oContour->GetProperty, C_VALUE=c_value
        nlevels = N_ELEMENTS(c_value)
        if (~nlevels || ((nlevels eq 1) && (c_value[0] eq -1))) then $
            return, OBJ_NEW()
    endif

    oLevels = self._oLevels->Get(/ALL, ISA='IDLitVisContourLevel', $
        COUNT=ncontained)

    oTool = self->GetTool()

    ; Since we didn't set the tool in init.
    self._oLevels->_SetTool, oTool

    ; Retrieve only the first nlevels items from the container.
    if (ncontained gt 0) then begin
        n = (nlevels < ncontained)
        oLevels = oLevels[0:n-1]
        props = oLevels[0]->QueryProperty()
        for i=0,N_ELEMENTS(props)-1 do begin
            oLevels[0]->GetPropertyAttribute, props[i], HIDE=hide
            if (hide) then $
                props[i] = ''
        endfor
        for i=0,n-1 do begin
            ; We didn't set the tool in init on the first level.
            oLevels[i]->_SetTool, oTool
            oLevels[i]->GetProperty, _CONTOUR=oContour
            oLevels[i]->SetProperty, _CONTOUR=self._oContour, $
                INDEX=i, $
                NAME='Level ' + STRTRIM(i, 2)
            self->DoOnNotify, oLevels[i]->GetFullIdentifier(), 'SETPROPERTY', 'NAME'
        endfor
    endif

    if (ncontained lt nlevels) then begin
        ; Need to create some objects.
        for i=ncontained, nlevels-1 do begin
            oLevel = OBJ_NEW('IDLitVisContourLevel', $
                NAME='Level ' + STRTRIM(i,2), $
                ID='Level_' + STRTRIM(i,2), $
                INDEX=i, TOOL=oTool, $
                _CONTOUR=self._oContour)

            ; Concat onto list of levels to return.
            oLevels = (i gt 0) ? [oLevels, oLevel] : oLevel

            ; Copy properties from my first level over to the new one.
            for p=0,N_ELEMENTS(props)-1 do begin
                ; Do not copy the value, causes vertex problems.
                if (~props[p] || props[p] eq 'VALUE') then $
                    continue
                if (oLevels[0]->GetPropertyByIdentifier(props[p], value)) then $
                    oLevel->SetPropertyByIdentifier, props[p], value
            endfor

        endfor

        self._oLevels->Add, oLevels[ncontained:*], /AGGREGATE, /NO_UPDATE, /INTERNAL

    endif

    return, oLevels

end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method is used to create default indices into the
;   color table. Indices correspond to the location of the contour levels
;   within the data range scaled to the range of the color table.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;----------------------------------------------------------------------------
pro IDLitVisContour::_UpdateDefaultIndices

    compile_opt idl2, hidden

    if (~self._palColor || ~self._defaultIndices) then $
        return

    self._oContour->GetProperty, C_VALUE=cValue, DATA_VALUES=dataValues

    ; scale indices from location of contour levels within data range into
    ; byte range.
    oIndices = OBJ_NEW()
    if N_ELEMENTS(dataValues) gt 0 then begin
        dataMin = MIN(dataValues, MAX=dataMax, /NAN)
        indices = BYTSCL(cValue, MIN=dataMin, MAX=dataMax)
        oIndices = OBJ_NEW('IDLitDataIDLVector', indices, NAME='<DEFAULT INDICES>')
        self->OnDataChangeUpdate, oIndices, 'RGB_INDICES'
        obj_destroy, oIndices
    endif

end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method is used to load color values into the
;   color table. RGB values may come from a parameter defined
;   by the user or default values from a grayscale palette.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;----------------------------------------------------------------------------
pro IDLitVisContour::_LoadPalette

    compile_opt idl2, hidden

    oDataRGB = self->GetParameter('PALETTE')
    if ~OBJ_VALID(oDataRGB) then begin
      ; define default palette, allows editing color table
        ramp = BINDGEN(256)
        colors = transpose([[ramp],[ramp],[ramp]])
        oDataRGB = OBJ_NEW('IDLitDataIDLPalette', colors, NAME='RGB Table')
    endif else begin
        ; reset even if parameter already existed in order to reconnect palette
        ; and update parameter for export
        success = oDataRGB->GetData(colors)
        oDataRGB = OBJ_NEW('IDLitDataIDLPalette', colors, NAME='RGB Table')
    endelse
    ; connect palette
    result = self->SetData(oDataRGB, PARAMETER_NAME='PALETTE',/by_value)

end


;----------------------------------------------------------------------------
; Param = 'X' or 'Y'
;
function IDLitVisContour::_GetXYdata, param

    compile_opt idl2, hidden

    oParamZ = self->GetParameter('Z')
    if (~OBJ_VALID(oParamZ) || ~oParamZ->GetData(pData, /POINTER)) then $
        return, 0

    dims = SIZE(*pData, /DIMENSIONS)
    dimWant = (param eq 'X') ? dims[0] : dims[1]

    oParamXY = self->GetParameter(param)
    if (~OBJ_VALID(oParamXY) || ~oParamXY->GetData(xyData)) then begin
        xyData = FINDGEN(dimWant)
    endif

    minn = MIN(xyData, MAX=maxx)
    ndimXY = SIZE(xyData, /N_DIMENSIONS)
    if ((ndimXY eq 1 && N_ELEMENTS(xyData) ne dimWant) || $
        (ndimXY eq 2 && ~ARRAY_EQUAL(SIZE(xyData, /DIM), dims)) || $
        (minn eq maxx)) then begin
        xyData = FINDGEN(dimWant)
    endif

    ; We have our X or Y data. Now check for logarithmic.

    isLog = (param eq 'X') ? self._xVisLog : self._yVisLog

    ; Turn off log if values are zero or negative.
    if (minn le 0) then $
        isLog = 0

    ; Take log if necessary.
    if (isLog) then $
        xyData = ALOG10(TEMPORARY(xyData))

    ; May need to disable log.
    if (param eq 'X') then begin
        self._xVisLog = isLog
    endif else begin
        self._yVisLog = isLog
    endelse

    return, xyData

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
;   Any keyword to IDLitVisContour::Init followed by the word "Get"
;   can be retrieved using this method.
;
pro IDLitVisContour::GetProperty, $
    CONTOUR_LEVELS=oLevels, $
    C_VALUE=c_value, $
    GRID_UNITS=gridUnits, $
    HIDE=hide, $
    FONT_INDEX=fontIndex, $
    FONT_NAME=fontName, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    LABEL_COLOR=labelColor, $
    MIN_VALUE=minValue, $
    MAX_VALUE=maxValue, $
    N_LEVELS=n_levels, $
    PAL_COLOR=palColor, $
    TICKINTERVAL=tickinterval, $
    TICKLEN=ticklen, $
    TRANSPARENCY=transparency, $
    VISUALIZATION_PALETTE=visPalette, $
    X_VIS_LOG=xVisLog, $
    Y_VIS_LOG=yVisLog, $
    Z_VIS_LOG=zVisLog, $
    ZVALUE=zvalue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(gridUnits) ne 0) then $
        gridUnits = self._gridUnits

    if (ARG_PRESENT(hide)) then self->IDLgrModel::GetProperty, HIDE=hide

    ; LABEL_COLOR, and FONT_* are needed for the new Graphics property buttons.
    if (ARG_PRESENT(fontIndex) || ARG_PRESENT(fontName) || $
      ARG_PRESENT(fontSize) || ARG_PRESENT(fontStyle)) then begin
      self._oLevels->GetProperty, FONT_INDEX=fontIndex, FONT_NAME=fontName, $
        FONT_SIZE=fontSize, FONT_STYLE=fontStyle
    endif

    if (ARG_PRESENT(labelColor)) then begin
      self._oLevels->GetProperty, LABEL_COLOR=labelColor
    endif

    if ARG_PRESENT(n_levels) then begin
        self._oContour->GetProperty, HIDE=isHidden, N_LEVELS=nlevelsTmp
        n_levels = isHidden ? 0 : nLevelsTmp
    endif

    if (Arg_Present(minValue) ne 0) then begin
        self._oContour->GetProperty, MIN_VALUE=minValue
        if (self._zVisLog) then minValue = 10^minValue
    endif

    if (Arg_Present(maxValue) ne 0) then begin
        self._oContour->GetProperty, MAX_VALUE=maxValue
        if (self._zVisLog) then maxValue = 10^maxValue
    endif

    if ARG_PRESENT(palColor) then begin
        palColor = self._palColor
    endif

    if ARG_PRESENT(transparency) then begin
        self._oContour->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if ARG_PRESENT(tickinterval) then $
        tickinterval = self._tickinterval

    if ARG_PRESENT(ticklen) then $
        ticklen = self._ticklen

    if ARG_PRESENT(zvalue) then $
        zvalue = self._zvalue

    if ARG_PRESENT(oLevels) then $
        oLevels = self->_GetLevels()

    IF ARG_PRESENT(c_value) THEN BEGIN
      c_value = 0
      IF self._cValSet THEN $
        self._oContour->GetProperty,C_VALUE=c_value
    ENDIF

    if ARG_PRESENT(visPalette) then begin
        self._oPalette->GetProperty, BLUE_VALUES=blue, $
            GREEN_VALUES=green, RED_VALUES=red
        visPalette = TRANSPOSE([[red], [green], [blue]])
    endif

    if (Arg_Present(xVisLog)) then $
        xVisLog = self._xVisLog

    if (Arg_Present(yVisLog)) then $
        yVisLog = self._yVisLog

    if (Arg_Present(zVisLog)) then $
        zVisLog = self._zVisLog

    if (N_ELEMENTS(_extra) gt 0) then begin

        ; Pass properties directly to Contour Level container.
        ; We want to treat the CL container as if it is aggregated, but
        ; we don't actually aggregate it because we don't want the props
        ; to show up in the Contour property sheet.
        ; See Note in ::Init.
        levelProps = WHERE(_extra eq *self._pProps, nProps, $
            COMPLEMENT=otherProps, NCOMP=nOther)
        if (nOther gt 0) then begin
            ; get superclass properties
            self->IDLitVisualization::GetProperty, _EXTRA=_extra[otherProps]
            if (nOther gt 1 || ~ISA(SCOPE_VARFETCH(_extra[otherProps], /REF_EXTRA))) then begin
              ; get IDLgrContour properties
              self._oContour->GetProperty, _EXTRA=_extra[otherProps]
            endif
        endif
        if (nProps gt 0) then begin
            self._oLevels->GetProperty, _EXTRA=_extra[levelProps]
        endif

    endif

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
pro IDLitVisContour::SetProperty, $
    GRID_UNITS=gridUnits, $
    TRANSPARENCY=transparency, $
    PAL_COLOR=palColor, $
    FILL=filled, $
    FONT_COLOR=fontColor, $  ; needed for command-line graphics
    FONT_INDEX=fontIndex, $
    FONT_NAME=fontName, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    LABEL_COLOR=labelColor, $
    MIN_VALUE=minValue, $
    MAX_VALUE=maxValue, $
    N_LEVELS=n_levels, $
    PLANAR=planar, $
    TICKINTERVAL=tickinterval, $
    TICKLEN=ticklen, $
    ZVALUE=zvalue, $
    C_COLOR=c_color, $
    C_FILL_PATTERN=c_fill_pattern, $
    C_LABEL_INTERVAL=c_label_interval, $
    C_LABEL_NOGAPS=c_label_nogaps, $
    C_LABEL_OBJECTS=c_label_objects, $
    C_LABEL_SHOW=c_label_show, $
    C_LINESTYLE=c_linestyle, $
    C_THICK=c_thick, $
    C_USE_LABEL_COLOR=c_use_label_color, $
    C_USE_LABEL_ORIENTATION=c_use_label_orientation, $
    C_VALUE=C_VALUE, $
    COLOR=color, $
    CLIP_PLANES=clipPlanes, $
    VISUALIZATION_PALETTE=visPalette, $
    X_VIS_LOG=xVisLog, $
    Y_VIS_LOG=yVisLog, $
    Z_VIS_LOG=zVisLog, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (N_ELEMENTS(gridUnits) ne 0) then begin

        self._gridUnits = gridUnits

        ; Change to isotropic for units = meters or degrees.
        ; Do this before the OnProjectionChange.
        wasIsotropic = self->IsIsotropic()
        isIsotropic = gridUnits eq 1 || gridUnits eq 2
        if (wasIsotropic ne isIsotropic) then begin
            self->IDLitVisualization::SetProperty, ISOTROPIC=isIsotropic
        endif

        ; If units changed we may need to recalculate our contours.
        self->OnProjectionChange

        ; If isotropy changed then update our dataspace as well.
        if (wasIsotropic ne isIsotropic) then begin
            self->OnDataChange, self
            self->OnDataComplete, self
        endif

    endif


    if (N_ELEMENTS(transparency)) then begin
        self._oContour->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-transparency)/100) < 1
        ; Notify observers like the colorbar.
        self->DoOnNotify, self->GetFullIdentifier(), 'IMAGECHANGED', 0
    endif

    if (N_ELEMENTS(clipPlanes) gt 0) then begin
        self._oContour->SetProperty, $
            CLIP_PLANES=clipPlanes
    endif

    if (N_ELEMENTS(palColor) gt 0) then begin
        self._palColor = palColor
        self->SetPropertyAttribute, HIDE=~palColor, 'VISUALIZATION_PALETTE'
        if keyword_set(palColor) then begin
            ; switch to palette colors, using current palette and indices
            ; create the default palette and indices if necessary
            self->_LoadPalette
            self->_UpdateDefaultIndices
        endif else begin
            ; extract current colors and load these triplets directly
            ; to allow individual modifications to individual levels
            self._oContour->GetProperty, C_COLOR=cColorOld, $
                N_LEVELS=nLevels, $
                PALETTE=oldPalette
            if (MIN(cColorOld) ge 0 && OBJ_VALID(oldPalette)) then begin
                nColors = N_ELEMENTS(cColorOld)
                newColors = BYTARR(3,nLevels)
                self->GetProperty, $
                    VISUALIZATION_PALETTE=visPaletteTmp
                for i=0, nLevels-1 do begin
                    newColors[*,i] = reform(visPaletteTmp[*,cColorOld[i mod nColors]])
                endfor
                ; disconnect self._oPalette from the contour
                ; to allow rgb values to be set through c_color
                ; it can be reconnected if pal_color is set
                self._oContour->SetProperty, PALETTE=OBJ_NEW()
                self._oContour->SetProperty, C_COLOR=newColors
            endif
        endelse
    endif


    ; TICKINVERVAL or TICKLEN
    if N_ELEMENTS(tickinterval) || N_ELEMENTS(ticklen) then begin
        ; Scale from normalized range to x/yrange.
        self._oContour->GetProperty, XRANGE=xr, YRANGE=yr
        maxrange = ABS(xr[1] - xr[0]) > ABS(yr[1] - yr[0])

        if (N_ELEMENTS(tickinterval)) then begin
            self._tickinterval = tickinterval
            scaledTickinterval = 0.5d*maxrange*tickinterval
        endif
        if (N_ELEMENTS(ticklen)) then begin
            self._ticklen = ticklen
            scaledTicklen = 0.5d*maxrange*ticklen
        endif
        self._oContour->SetProperty, $
            TICKINTERVAL=scaledTickinterval, $
            TICKLEN=scaledTicklen
    endif


    if (N_ELEMENTS(filled)) then begin
        self._oContour->SetProperty, FILL=filled
        self._oContour->SetPropertyAttribute, 'SHADING', $
            SENSITIVE=KEYWORD_SET(filled)
    endif

    ; LABEL_COLOR, and FONT_* are needed for the new Graphics property buttons.
    if (ISA(fontIndex) || ISA(fontName) || ISA(fontSize) || ISA(fontStyle)) then begin
      self._oLevels->SetProperty, FONT_INDEX=fontIndex, FONT_NAME=fontName, $
        FONT_SIZE=fontSize, FONT_STYLE=fontStyle
    endif

    if (ISA(fontColor)) then $
      labelColor = fontColor

    if (ISA(labelColor)) then begin
      self._oLevels->SetProperty, LABEL_COLOR=labelColor
      c_use_label_color = ISA(labelColor, /ARRAY)
    endif

    if (N_ELEMENTS(minValue) || N_ELEMENTS(maxValue)) then begin
        if (self._zVisLog) then begin
            oContour = self._oContour
            if (Ptr_Valid(oContour.data)) then begin
                minn = Min(*oContour.data, MAX=maxx)
            endif else begin
                minn = 0
                maxx = 1
            endelse
            if (N_Elements(minValue)) then $
                minV = (minValue gt 0) ? Alog10(minValue) : minn
            if (N_Elements(maxValue)) then $
                maxV = (maxValue gt 0) ? Alog10(maxValue) : maxx
        endif else begin
            if (N_Elements(minValue)) then minV = minValue
            if (N_Elements(maxValue)) then maxV = maxValue
        endelse
        self._oContour->SetProperty, MIN_VALUE=minV, MAX_VALUE=maxV
        self->_UpdateDefaultIndices
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if keyword_set(n_levels) then begin
        ; For N_LEVELS we need to reset the current C_VALUE.
        self._oContour->GetProperty, C_VALUE=c_valueTemp
        if (n_levels ne N_ELEMENTS(c_valueTemp)) then begin
          self._oContour->SetProperty, C_VALUE=0, N_LEVELS=n_levels
        endif

        self->_UpdateDefaultIndices

        self._oContour->GetProperty, C_COLOR=cColorOld, $
                                     C_LABEL_INTERVAL=cLabelIntOld, $
                                     C_LABEL_NOGAPS=cLabelGapsOld, $
                                     C_LABEL_SHOW=cLabelShowOld, $
                                     C_LINESTYLE=cLinestyleOld, $
                                     C_THICK=cThickOld, $
                                     C_USE_LABEL_COLOR=cLabelColorOld, $
                                     C_USE_LABEL_ORIENTATION=cLabelOriOld

        if ~PTR_VALID(self._pShow) then self._pShow = PTR_NEW(cLabelShowOld)
        cLabelShowOld = *self._pShow

        ;; ensure that all cyclical properties have the appropriate
        ;; number of elements
        IF (n_levels GT n_elements(c_valueTemp)) THEN BEGIN
          self->_FillParameter,'C_COLOR',cColorOld, $
            FORCE2D=~self._palColor && N_ELEMENTS(cColorOld) eq 3
          self->_FillParameter,'C_LABEL_INTERVAL',cLabelIntOld
          self->_FillParameter,'C_LABEL_NOGAPS',cLabelGapsOld
          self->_FillParameter,'C_LABEL_SHOW',cLabelShowOld
          IF (n_elements(cLinestyleOld) NE 1 || cLinestyleOld NE -1) THEN $
            self->_FillParameter,'C_LINESTYLE',cLinestyleOld
          IF (n_elements(cThickOld) NE 1 || cThickOld NE -1) THEN $
            self->_FillParameter,'C_THICK',cThickOld
          self->_FillParameter,'C_USE_LABEL_COLOR',cLabelColorOld
          self->_FillParameter,'C_USE_LABEL_ORIENTATION',cLabelOriOld
        ENDIF

        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (N_ELEMENTS(zvalue) gt 0) then begin
        oContour = self._oContour
        self._zvalue = zvalue
        ; IDLgrContour must have data to set GEOMZ.
        IF (Ptr_Valid(oContour.data)) THEN BEGIN
            zvalueSet = self._zvalue
            if (self._zVisLog) then $
                zvalueSet = (self._zvalue gt 0) ? Alog10(self._zvalue) : 0
            self._oContour->GetProperty, PLANAR=planar
            self._oContour->SetProperty, $
                GEOMZ=Keyword_Set(planar) ? zvalueSet : *oContour.data
            ; put the visualization into 3D mode if necessary
            self->Set3D, ~planar || (self._zvalue ne 0), /ALWAYS
            self->OnDataChange, self
            self->OnDataComplete, self
        ENDIF
    endif

    if (N_ELEMENTS(planar) gt 0) then begin
        self->SetPropertyAttribute, 'ZVALUE', SENSITIVE=Keyword_Set(planar)
        oContour = self._oContour
        ; IDLgrContour must have data to set GEOMZ.
        if (Ptr_Valid(oContour.data)) then begin
            zvalueSet = self._zvalue
            if (self._zVisLog) then $
                zvalueSet = (self._zvalue gt 0) ? Alog10(self._zvalue) : 0
            self._oContour->SetProperty, PLANAR=planar, $
                GEOMZ=Keyword_Set(planar) ? zvalueSet : *oContour.data
            ; put the visualization into 3D mode if necessary
            self->Set3D, ~planar || (self._zvalue ne 0), /ALWAYS
            self->OnDataChange, self
            self->OnDataComplete, self
        endif else begin
            self._oContour->SetProperty, PLANAR=planar
        endelse
;        ; update clipping if necessary
;        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
;        if (OBJ_VALID(oDataSpace)) then begin
;            success = oDataSpace->GetXYZRange(xRange, yRange, zRange)
;            if success then self->OnDataRangeChange, self, XRange, YRange, ZRange
;        endif
    endif

    if (N_ELEMENTS(visPalette) gt 3) then begin
        oPal = self->GetParameter('PALETTE')
        if OBJ_VALID(oPal) then begin
            success = oPal->SetData(visPalette)
        endif else begin
            ; Set manually if we don't have a parameter.
            self._oPalette->SetProperty, BLUE_VALUES=visPalette[2,*], $
                GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
        endelse
    endif



    if (N_ELEMENTS(c_color) gt 0) then begin
        twoD = size(c_color, /n_dimensions) gt 1
        if (twoD) then begin
            ; supplied c_color is array of RGBs.
            self._palColor = 0
            self->SetPropertyAttribute, /HIDE, 'VISUALIZATION_PALETTE'
            ; disconnect self._oPalette from the contour
            ; to allow rgb values to be set through c_color
            ; it can be reconnected if pal_color is set
            self._oContour->SetProperty, PALETTE=OBJ_NEW()
        endif
        ; Make sure we create enough levels to hold our values.
        nvalues = (SIZE(c_color,/DIM))[twoD]
        if (nvalues gt 1) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        if (ARRAY_EQUAL(c_color, -1)) then c_color = -1
        self._oContour->SetProperty,C_COLOR=c_color
    endif

    if (N_ELEMENTS(c_fill_pattern) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_fill_pattern)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_FILL_PATTERN=c_fill_pattern
    endif

    if (N_ELEMENTS(c_label_interval) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_label_interval)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_LABEL_INTERVAL=c_label_interval
    endif

    if (N_ELEMENTS(c_label_nogaps) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_label_nogaps)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_LABEL_NOGAPS=c_label_nogaps
    endif

    if (N_ELEMENTS(c_label_objects) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_label_objects)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_LABEL_OBJECTS=c_label_objects
    endif

    if (N_ELEMENTS(c_label_show) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_label_show)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_LABEL_SHOW=c_label_show
        if ~PTR_VALID(self._pShow) then self._pShow = PTR_NEW(/ALLOC)
        *self._pShow = c_label_show

        ; Retrieve all the level objects so we can set properties on them.
        oLevels = self._oLevels->Get(/ALL, ISA='IDLitVisContourLevel', COUNT=nLevels)
        for i=0,nLevels-1 do begin
          ; Set LABEL_TYPE=1 (value labels) if c_label_show is true
          oLevels[i]->GetProperty, LABEL_TYPE=labelType
          if (labelType eq 0 && c_label_show[i mod nvalues]) then $
            oLevels[i]->SetProperty, LABEL_TYPE=1
        endfor
    endif

    if (N_ELEMENTS(c_linestyle) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_linestyle)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_LINESTYLE=c_linestyle
    endif

    if (N_ELEMENTS(c_thick) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_thick)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_THICK=c_thick
    endif

    if (N_ELEMENTS(c_use_label_color) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_use_label_color)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, C_USE_LABEL_COLOR=c_use_label_color
    endif

    if (N_ELEMENTS(c_use_label_orientation) gt 0) then begin
        ; Make sure we create enough levels to hold our values.
        nvalues = N_ELEMENTS(c_use_label_orientation)
        if (nvalues gt 0) then $
            void = self->_GetLevels(N_LEVELS=nvalues)
        self._oContour->SetProperty, $
            C_USE_LABEL_ORIENTATION=c_use_label_orientation
    endif

    if(n_elements(C_VALUE) gt 0)then begin
        ;; trap c_value and don't allow -1 values to be set. This is
        ;; needed b/c of the design of the contour object (n_levels
        ;; and c_value) and how the property bag works.
        if ((SIZE(c_value, /N_DIM) gt 0) || c_value ne -1) then begin
          self._oContour->GetProperty, C_VALUE=c_valueTemp
          self._oContour->SetProperty, c_value=c_value
          self->_UpdateDefaultIndices
          self._oContour->GetProperty, C_COLOR=cColorOld, $
                                       C_LABEL_INTERVAL=cLabelIntOld, $
                                       C_LABEL_NOGAPS=cLabelGapsOld, $
                                       C_LABEL_SHOW=cLabelShowOld, $
                                       C_LINESTYLE=cLinestyleOld, $
                                       C_THICK=cThickOld, $
                                       C_USE_LABEL_COLOR=cLabelColorOld, $
                                       C_USE_LABEL_ORIENTATION=cLabelOriOld
          IF ((SIZE(c_value, /N_DIMENSIONS) GT 0) || c_value NE 0) THEN BEGIN
            self._cValSet = 1b
          ENDIF ELSE BEGIN
            self._cValSet = 0b
          ENDELSE
          IF (n_elements(c_value) GT n_elements(c_valueTemp)) THEN BEGIN
            if ~PTR_VALID(self._pShow) then self._pShow = PTR_NEW(cLabelShowOld)
            cLabelShowOld = *self._pShow

            self->_FillParameter,'C_COLOR',cColorOld, $
              FORCE2D=~self._palColor && N_ELEMENTS(cColorOld) eq 3
            self->_FillParameter,'C_LABEL_INTERVAL',cLabelIntOld
            self->_FillParameter,'C_LABEL_NOGAPS',cLabelGapsOld
            self->_FillParameter,'C_LABEL_SHOW',cLabelShowOld
            IF (n_elements(cLinestyleOld) NE 1 || cLinestyleOld NE -1) THEN $
              self->_FillParameter,'C_LINESTYLE',cLinestyleOld
            IF (n_elements(cThickOld) NE 1 || cThickOld NE -1) THEN $
              self->_FillParameter,'C_THICK',cThickOld
            self->_FillParameter,'C_USE_LABEL_COLOR',cLabelColorOld
            self->_FillParameter,'C_USE_LABEL_ORIENTATION',cLabelOriOld
          ENDIF
        endif
    endif

    IF n_elements(color) EQ 3 THEN BEGIN
      self._oContour->SetProperty,COLOR=color
      self->_FillParameter,'C_COLOR',color,/FORCE2D
    ENDIF

    IF (n_elements(xVisLog) GT 0) && (xVisLog NE self._xVisLog) THEN BEGIN
        self._xVisLog = xVisLog
        xData = self->_GetXYdata('X')
        if (N_ELEMENTS(xData) gt 1) then begin
            self._oContour->SetProperty, GEOMX=xData
            ; Force a recalculation of the tick interval/length.
            self->IDLitVisContour::SetProperty, $
                TICKINTERVAL=self._tickinterval, $
                TICKLEN=self._ticklen
            self->UpdateSelectionVisual
        endif
    endif

    IF (n_elements(yVisLog) GT 0) && (yVisLog NE self._yVisLog) THEN BEGIN
        self._yVisLog = yVisLog
        yData = self->_GetXYdata('Y')
        if (N_ELEMENTS(yData) gt 1) then begin
            self._oContour->SetProperty, GEOMY=yData
            ; Force a recalculation of the tick interval/length.
            self->IDLitVisContour::SetProperty, $
                TICKINTERVAL=self._tickinterval, $
                TICKLEN=self._ticklen
            self->UpdateSelectionVisual
        endif
    endif

    if (N_Elements(zVisLog) gt 0) && (zVisLog ne self._zVisLog) then begin
        self._zVisLog = zVisLog
        oParamZ = self->GetParameter('Z')
        if (Obj_Valid(oParamZ) && oParamZ->GetData(pZ, /POINTER) && $
            N_Elements(*pZ) gt 0) then begin
            newZ = (zVisLog gt 0) ? Alog10(*pZ) : *pZ
            minn = Min(newZ, Max=maxx, /NAN)
            self._oContour->GetProperty, PLANAR=planar
            zvalueSet = self._zvalue
            if (self._zVisLog) then $
                zvalueSet = (self._zvalue gt 0) ? Alog10(self._zvalue) : 0
            self._oContour->SetProperty, DATA=newZ, $
                GEOMZ=KEYWORD_SET(planar) ? zvalueSet : newZ, $
                MIN_VALUE=minn, MAX_VALUE=maxx
            ; Notify our observers in case the prop sheet is visible.
            ; Use N_LEVELS as the property since the levels may have changed.
            self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', 'N_LEVELS'
        endif
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then begin

        ; Pass properties directly to Contour Level container.
        ; We want to treat the CL container as if it is aggregated, but
        ; we don't actually aggregate it because we don't want the props
        ; to show up in the Contour property sheet.
        ; See Note in ::Init.
        levelProps = WHERE(_extra eq *self._pProps, nProps, $
            COMPLEMENT=otherProps, NCOMP=nOther)
        if (nOther gt 0) then begin
            self._oContour->SetProperty, _EXTRA=_extra[otherProps]
            self->IDLitVisualization::SetProperty, _EXTRA=_extra[otherProps]
        endif
        if (nProps gt 0) then begin
            self._oLevels->SetProperty, _EXTRA=_extra[levelProps]
        endif

    endif

end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data from the grContour
;
; Arguments:
;   Z, X, Y
;
; Keywords:
;   NONE
;
pro IDLitVisContour::GetData, zData, xData, yData, _EXTRA=_extra
  compile_opt idl2, hidden
  
  oDataZ = self->GetParameter('Z')
  if (OBJ_VALID(oDataZ)) then $
    void = oDataZ->GetData(zData)
  xData = self->_GetXYdata('X')
  yData = self->_GetXYdata('Y')

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
pro IDLitVisContour::PutData, Z, X, Y, _EXTRA=_extra
  compile_opt idl2, hidden
  
  RESOLVE_ROUTINE, 'iContour', /NO_RECOMPILE

  void = iContour_GetParmSet(oParmSet, z, x, y, _EXTRA=_extra)

  ;; SetParameter requires a data object, so we will give it one
  ;; Needed if Z changes size, forces a recalculation of X and Y
  oData = OBJ_NEW('IDLitData', z, /AUTO_DELETE)
  self->SetParameter, 'Z', oData
  
  self->OnDataChangeUpdate, oParmSet, '<PARAMETER SET>'
  ;; Clean up
  OBJ_DESTROY, oParmSet
  
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
;   IDLitVisContour::EnsureXYParameters
;
; PURPOSE:
;   Ensure that X and Y parameters exist, based on the contour data
;   dimensions.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisContour::]EnsureXYParameters
;
; KEYWORD PARAMETERS:
;   None.
;
; USAGE:
;   This is used by operations such as IDLitOpInsertImage, that need
;   the contour parameter in order to create an image based on the
;   contour and to be notified of changes to the contour.
;-
pro IDLitVisContour::EnsureXYParameters

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
function IDLitVisContour::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

        'CONTOUR_LEVELS': begin
            oTargets = oTool->GetSelectedItems(count=nTargets)
            self->GetProperty, PARENT=parent
            if (nTargets gt 1) || (OBJ_ISA(parent, 'IDLitVisGroup')) then begin
                self->ErrorMessage, $
                    [IDLitLangCatQuery('Message:EditContourLevels:Text')], $
                    title=IDLitLangCatQuery('Message:EditContourLevels:Title'), severity=1
                return, 0
            endif

            ; Make sure label color is in sync with PAL_COLOR.
            self->IDLitVisContour::GetProperty, $
                CONTOUR_LEVELS=oLevels, PAL_COLOR=palColor
            for i=0,N_ELEMENTS(oLevels)-1 do begin
                oLevels[i]->SetPropertyAttribute, 'COLOR', $
                    SENSITIVE=~palColor
            endfor

            ; Sanity check.
            self._oLevels->_CheckIntersectAttributes

            success = oTool->DoUIService('ContourLevels', self)

            ; We want to return "failure" to avoid committing the Userdef
            ; property changes. But we need to commit our individual
            ; SetProperty actions. Note that hitting the "Close" (X) button
            ; still commits the actions.
            oTool->CommitActions

            return, 0
            end

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
; IIDLDataObserver Interface
;----------------------------------------------------------------------------



;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisContour::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
;      NOTE: This implementation currently assumes that no transformation
;      matrix is being applied between this Contour and the Subject sending
;      the notification.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisContour::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
;-
pro IDLitVisContour::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; Retrieve the data range of the Contour.
    self._oContour->GetProperty, XRANGE=contourXRange, YRANGE=contourYRange, $
        ZRANGE=contourZRange

    ; First check if the region is completely clipped.  If so,
    ; simply hide it.
    if ((contourXRange[1] lt XRange[0]) or $
        (contourXRange[0] gt XRange[1]) or $
        (contourYRange[1] lt YRange[0]) or $
        (contourYRange[0] gt YRange[1]) or $
        (contourZRange[1] lt ZRange[0]) or $
        (contourZRange[0] gt ZRange[1])) then begin
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
        if (XRange[0] gt contourXRange[0]) then begin
            clipPlanes = [-1,0,0,XRange[0]]
            nClip++
        endif

        if (XRange[1] lt contourXRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[1,0,0,-XRange[1]]] : $
                [1,0,0,-XRange[1]]
            nClip++
        endif

        if (YRange[0] gt contourYRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,-1,0,YRange[0]]] : $
                [0,-1,0,YRange[0]]
            nClip++
        endif

        if (YRange[1] lt contourYRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,1,0,-YRange[1]]] : $
                [0,1,0,-YRange[1]]
            nClip++
        endif

        if (ZRange[0] gt contourZRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,-1,ZRange[0]]] : $
                [0,0,-1,ZRange[0]]
            nClip++
        endif

        if (ZRange[1] lt contourZRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,1,-ZRange[1]]] : $
                [0,0,1,-ZRange[1]]
            nClip++
        endif

        ; Enable any clip planes (or disable if none required).
        self->IDLgrModel::SetProperty, CLIP_PLANES=clipPlanes
    endelse
end


;----------------------------------------------------------------------------
PRO IDLitVisContour::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   ;; Just check the name and perform the desired action
   case ParmName of
       'Z': begin
           ;; You can't unset data, so we hide the contour.
           self._oContour->SetProperty, DATA_VALUES=[[0,0],[0,0]], $
             GEOMZ=[[0,0],[0,0]]
           self._oContour->SetProperty, /HIDE
       end

       'X': begin
           self._oContour->GetProperty, DATA_VALUES=data
           szDims = size(data,/dimensions)
           data=0b
           self._oContour->SetProperty, GEOMX=indgen(szDims[0])
          ; Force a recalculation of the tick interval/length.
          self->IDLitVisContour::SetProperty, $
            TICKINTERVAL=self._tickinterval, TICKLEN=self._ticklen
       end
       'Y': begin
           self._oContour->GetProperty, DATA_VALUES=data
           szDims = size(data,/dimensions)
           data=0b
           self._oContour->SetProperty, GEOMY=indgen(szDims[1])
          ; Force a recalculation of the tick interval/length.
          self->IDLitVisContour::SetProperty, $
            TICKINTERVAL=self._tickinterval, TICKLEN=self._ticklen
       end
       else:
       endcase
end


;----------------------------------------------------------------------------
; Purpose:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrContour object.
;
; Arguments:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the surface) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then, it puts the data in the IDLgrContour object.
;
;   ParmName: The name of the parameter that was changed.
;
; Keywords:
;   None.
;
pro IDLitVisContour::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden


    case STRUPCASE(parmName) of

        '<PARAMETER SET>':begin
            ;; Get our data
            position = oSubject->Get(/ALL, count=nCount, NAME=names)
            for i=0, nCount-1 do begin
                oData = oSubject->GetByName(names[i],count=nCount)
                IF nCount NE 0 THEN self->OnDataChangeUpdate,oData,names[i]
            endfor
            ; Might have palette but no indices, so load default if necessary
            self->_UpdateDefaultIndices
            self->OnProjectionChange
        END
        'Z': BEGIN
          success = oSubject->GetData(zData, NAN=nan)

          zDims = SIZE(zData, /DIMENSIONS)

          oDataSpace = self->GetDataSpace(/UNNORMALIZED)
          if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
            self._xVisLog = xLog
            self._yVisLog = yLog
            self._zVisLog = zLog
          endif

          ; Reset the X and Y along with the Z so that all are up-to-date
          ; simultaneously.
          xData = self->_GetXYdata('X')
          yData = self->_GetXYdata('Y')

          if (self._zVisLog gt 0) then zData =  Alog10(Temporary(zData))
          mn = MIN(zData, MAX=mx, NAN=nan)
          self._oContour->GetProperty, PLANAR=planar
          self->Set3D, ~planar || (self._zvalue ne 0), /ALWAYS
          zvalueSet = self._zvalue
          if (self._zVisLog) then $
            zvalueSet = (self._zvalue gt 0) ? Alog10(self._zvalue) : 0

          self._oContour->SetProperty, DATA_VALUES=zData, $
              HIDE=0, $
              MIN_VALUE=mn, MAX_VALUE=mx, $
              GEOMX=xData, $
              GEOMY=yData, $
              GEOMZ=KEYWORD_SET(planar) ? zvalueSet : zData


          ; These properties were disabled for styles. Reenable them.
          self->SetPropertyAttribute, ['MIN_VALUE', 'MAX_VALUE'], HIDE=0

          self->IDLitVisContour::GetProperty, LABEL_TYPE=labelType

          ; Force a recalculation of the tick interval/length and the labels.
          self->IDLitVisContour::SetProperty, $
            LABEL_TYPE=labelType, $
            TICKINTERVAL=self._tickinterval, TICKLEN=self._ticklen

          oLevels = self->_GetLevels()

          ; load up the vertices and connectivity for export
          self->IDLitVisContour::UpdateOutputParameters
        END

        'X': BEGIN
            oDataSpace = self->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDataSpace)) then begin
                oDataSpace->GetProperty, XLOG=xLog
                self._xVisLog = xLog
            endif
            xData = self->_GetXYdata('X')
            if (N_ELEMENTS(xData) gt 1) then begin
                self._oContour->SetProperty, GEOMX=temporary(xData)
                ; Force a recalculation of the tick interval/length.
                self->IDLitVisContour::SetProperty, $
                    TICKINTERVAL=self._tickinterval, $
                    TICKLEN=self._ticklen
                self->UpdateSelectionVisual
            endif
            END

        'Y': BEGIN
            oDataSpace = self->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDataSpace)) then begin
                oDataSpace->GetProperty, YLOG=yLog
                self._yVisLog = yLog
            endif
            yData = self->_GetXYdata('Y')
            if (N_ELEMENTS(yData) gt 1) then begin
                self._oContour->SetProperty, GEOMY=temporary(yData)
                ; Force a recalculation of the tick interval/length.
                self->IDLitVisContour::SetProperty, $
                    TICKINTERVAL=self._tickinterval, $
                    TICKLEN=self._ticklen
                self->UpdateSelectionVisual
            endif
            END

         'PALETTE': begin
            if(oSubject->GetData(data)) then begin
                if (size(data, /TYPE) ne 1) then $
                    data=bytscl(data)
                self._oPalette->SetProperty, $
                    RED_VALUES=data[0,*], $
                    GREEN_VALUES=data[1,*], $
                    BLUE_VALUES=data[2,*]
                self._oContour->SetProperty, PALETTE=self._oPalette
                self._palColor = 1
                self->GetProperty, CONTOUR_LEVELS=oLevels
                nLevels = N_ELEMENTS(oLevels)
                self->SetPropertyAttribute, HIDE=0, 'VISUALIZATION_PALETTE'
                if OBJ_VALID(oLevels[0]) then begin
                    for i=0, nLevels-1 do begin
                        oLevels[i]->SetPropertyAttribute, SENSITIVE=0, 'COLOR'
                    endfor
                endif
            end
         end

        'RGB_INDICES': begin
            if(oSubject->GetData(data)) then begin
                oSubject->GetProperty, NAME=name
                self._defaultIndices = (name eq '<DEFAULT INDICES>')
                self->IDLitVisContour::SetProperty, C_COLOR=data
            end
        end
        'VERTICES': begin ; this is a read only parameter - for export only
            dummy=5
        end
        'CONNECTIVITY': begin ; this is a read only parameter - for export only
            dummy=5
        end

       ELSE: ; ignore unknown parameters

    endcase

    ; Remove the Contour Level container from the aggregate, so that
    ; all of these properties won't show up in the Contour prop sheet.
    ; See Note in ::Init.
    if (self->IsContainedAggregate(self._oLevels)) then $
        self->RemoveAggregate, self._oLevels

end


;----------------------------------------------------------------------------
; IDLitVisContour::UpdateOutputParameters
;
; Purpose:
;   This procedure method updates the values of the output parameters
;   for this contour.  The output parameters (used for export) include:
;
;     VERTICES
;     CONNECTIVITY
;
pro IDLitVisContour::UpdateOutputParameters
    compile_opt idl2, hidden

    ; Retrieve new vertex and connectivity.
    result = self._oContour->GetVertexData(Outverts, Outconn)
    if (~result) then $
        return

    if (SIZE(Outverts, /N_DIMENSIONS) ne 2) then $
        Outverts = DBLARR(3,2)

    ; Update VERTICES.
    oVertObj = self->GetParameter('VERTICES')
    if (OBJ_VALID(oVertObj)) then begin
        ; We don't need to receive notification, so use NO_NOTIFY.
        result = oVertObj->SetData(Outverts, /NO_COPY, /NO_NOTIFY)
    endif else begin
        oVertices = OBJ_NEW('IDLitDataIDLArray2D', Outverts, NAME='VERTICES')
        result = self->SetData(oVertices, PARAMETER_NAME='VERTICES', $
            /BY_VALUE)
    endelse

    ; Update CONNECTIVITY.
    oConnObj = self->GetParameter('CONNECTIVITY')
    if (OBJ_VALID(oConnObj)) then begin
        ; We don't need to receive notification, so use NO_NOTIFY.
        result = oConnObj->SetData(Outconn, /NO_COPY, /NO_NOTIFY)
    endif else begin
        oConnectivity = OBJ_NEW('IDLitDataIDLVector', Outconn, $
            NAME='CONNECTIVITY')
        result = self->SetData(oConnectivity, PARAMETER_NAME='CONNECTIVITY',$
            /BY_VALUE)
    endelse

end

;----------------------------------------------------------------------------
pro IDLitVisContour::OnProjectionChange, sMap

    compile_opt idl2, hidden

    if (~N_ELEMENTS(sMap)) then $
        sMap = self->GetProjection()

    hasMapProjection = N_TAGS(sMap) gt 0
    if (hasMapProjection) then $
        self->SetPropertyAttribute, 'GRID_UNITS', /SENSITIVE

    if (self._gridUnits ne 2) then begin
        ; Remove the map projection from the contour.
        if (self._hasMapProjection) then begin
            self._oContour->SetProperty, MAP_STRUCTURE=0
            self._hasMapProjection = 0b
            ; Update output parameters.
            self->IDLitVisContour::UpdateOutputParameters
        endif
        return
    endif

    self._hasMapProjection = hasMapProjection

    self._oContour->SetProperty, MAP_STRUCTURE=sMap

    ; Update tick intervals and lengths.
    ; Scale from normalized range to x/yrange.
    self._oContour->GetProperty, XRANGE=xr, YRANGE=yr
    maxrange = ABS(xr[1] - xr[0]) > ABS(yr[1] - yr[0])
    scaledTickinterval = 0.5d*maxrange*self._tickinterval
    scaledTicklen = 0.5d*maxrange*self._ticklen
    self._oContour->SetProperty, $
        TICKINTERVAL=scaledTickinterval, $
        TICKLEN=scaledTicklen

    ; Update output parameters.
    self->IDLitVisContour::UpdateOutputParameters
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisContour::SetParameter
;
; PURPOSE;
;   This procedure method associates a data object with the given
;   parameter.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisContour::]SetParameter, ParamName, oItem
;
; INPUTS:
;   ParamName:  The name of the parameter to set.
;   oItem:  The IDLitData object to be associated with the
;     given parameter.
;-
pro IDLitVisContour::SetParameter, ParamName, oItem, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (STRUPCASE(ParamName) eq 'Z') then begin
        oItem->GetProperty, NAME=name
        if (STRLEN(name) gt 0) then $
            self->StatusMessage, 'Contour target: '+name
    endif

    ; Pass along to the superclass.
    self->IDLitParameter::SetParameter, ParamName, oItem, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisContour::_GetDataLocation, x, y

    compile_opt idl2, hidden

    oDataObj = self->GetParameter('Z')

    if (~oDataObj->GetData(pData, /POINTER)) || $
        (~N_ELEMENTS(pData)) then $
        return, ''

    dims = SIZE(*pdata, /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2) then $
        return, ''

    ; If we have X and Y parameters, convert from X and Y data coordinates
    ; back to indices.
    oX = self->GetParameter('X')
    if (obj_valid(oX) && $
        oX->GetData(xdata) && N_ELEMENTS(xdata) eq dims[0]) then begin
        ; Find the closest X index to our X data value.
        minn = MIN(ABS(xdata - x), loc)
        x = loc
    endif

    oY = self->GetParameter('Y')
    if (obj_valid(oY) && $
        oY->GetData(ydata) && N_ELEMENTS(ydata) eq dims[1]) then begin
        ; Find the closest Y index to our Y data value.
        minn = MIN(ABS(ydata - y), loc)
        y = loc
    endif

    ; Out of bounds. Failure.
    if ((x lt 0) || (x ge dims[0]) || (y lt 0) || (y ge dims[1])) then $
        return, ''

    return, STRING((*pdata)[x, y], FORMAT='(g0.4)')

end


;---------------------------------------------------------------------------
; Report X, Y, and possibly Z location.
;
function IDLitVisContour::GetDataString, xyz

    compile_opt idl2, hidden

    if (self._xVisLog) then $
        xyz[0] = 10d^xyz[0]
    if (self._yVisLog) then $
        xyz[1] = 10d^xyz[1]

    ; Notify any observers that someone is probing us.
    ; This is usually the image panel, and will probably
    ; call right back into our GetExtendedDataStrings method below.
    self->DoOnNotify, self->GetFullIdentifier(), $
        'CONTOURPROBE', xyz[0:1]

    value = STRING(xyz[0:1], FORMAT='("X: ",g0.4,"  Y: ",g0.4)')

    if (self._hasMapProjection) then $
        return, value

    zStr = self->_GetDataLocation(xyz[0], xyz[1])
    if (zStr ne '') then $
        value += '  Z: ' + zStr

    return, value

end

;---------------------------------------------------------------------------
; Convert a location from decimal degrees to DDDdMM'SS", where "d" is
; the degrees symbol.
;
function IDLitVisContour::_DegToDMS, x

    compile_opt idl2, hidden

    eps = 0.5d/3600
    x = (x ge 0) ? x + eps : x - eps
    degrees = FIX(x)
    minutes = FIX((ABS(x) - ABS(degrees))*60)

    ; Arcseconds are trickier. We need to determine whether we should
    ; output integers or floats.
    seconds = (ABS(x) - ABS(degrees) - minutes/60d)*3600
    format = '(I2)'

    ; If grid spacing is less than 10 arcseconds (~280 meters).
;    eps = (self._gridUnits eq 2) ? 0.0028 : 280
;    if (MIN(self._userStep) lt eps) then $
;        format = '(g0.4)'

    dms = STRING(degrees, FORMAT='(I4)') + STRING(176b) + $
        STRING(minutes, FORMAT='(I2)') + "'" + $
        STRING(seconds, FORMAT=format) + '"'

    return, dms

end


;---------------------------------------------------------------------------
; Retrieve extended data information strings (computed in the
;   most recent IDLitVisContour::GetDataString call).
;
; xyLoc should contain the [x,y] as computed by GetDataString.
;
pro IDLitVisContour::GetExtendedDataStrings, xyLoc, $
    MAP_LOCATION=mapLocation, $
    PROBE_LOCATION=probeLocation, $
    PIXEL_VALUES=pixelValues

    compile_opt idl2, hidden

    probeLocation = ''
    pixelValues = ''

    ; Map location:
    if (ARG_PRESENT(mapLocation)) then begin

        if (self._hasMapProjection) then begin
            ; If we have a map projection, then xyLoc is already in meters, and
            ; needs to be converted back to degrees.
            mapStruct = self->GetProjection()
            lonlat = MAP_PROJ_INVERSE(xyLoc[0], xyLoc[1], $
                MAP_STRUCTURE=mapStruct)
            ; Longitude & latitude.
            loc0 = 'Lon: ' + self->_DegToDMS(lonlat[0])
            loc1 = 'Lat: ' + self->_DegToDMS(lonlat[1])
            mapLocation = [loc0, loc1]
            ; X and Y location.
            loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
            loc0 = '     (' + loc0 + ' m' + ')'
            loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
            loc1 = '     (' + loc1 + ' m' + ')'
            mapLocation = [mapLocation, loc0, loc1]

            pixelValues = self->_GetDataLocation(lonlat[0], lonlat[1])

        endif else begin

            ; If we don't have a map projection, then xyLoc is in either
            ; degrees or meters.
            ; geomUnits=1 is meters, 2 is degrees
            if (self._gridUnits eq 2) then begin
                ; Longitude & latitude.
                loc0 = 'Lon: ' + self->_DegToDMS(xyLoc[0])
                loc1 = 'Lat: ' + self->_DegToDMS(xyLoc[1])
            endif else begin
                ; X and Y location.
                loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
                loc0 = 'X: ' + loc0
                loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
                loc1 = 'Y: ' + loc1
                if (self._gridUnits eq 1) then begin
                    loc0 += ' m'
                    loc1 += ' m'
                endif
            endelse

            ; Since we don't have a map projection, append null strings.
            mapLocation = [loc0, loc1, '', '']

            pixelValues = self->_GetDataLocation(xyLoc[0], xyLoc[1])

        endelse
    endif

    ; Probe location:
    if (ARG_PRESENT(probeLocation)) then begin
        probeLocation = '['+   STRTRIM(STRING(xyLoc[0]),2) + $
                 ', ' + STRTRIM(STRING(xyLoc[1]),2) + $
                 ']'
    endif

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This function method retrieves the LonLat range of
;   contained visualizations. Override the _Visualization method
;   so we can retrieve the correct range.
;
function IDLitVisContour::GetLonLatRange, lonRange, latRange, $
    MAP_STRUCTURE=sMap

    compile_opt idl2, hidden

    ; No units, failure.
    if (self._gridUnits ne 1 && self._gridUnits ne 2) then $
        return, 0

    xData = self->_GetXYdata('X')
    yData = self->_GetXYdata('Y')

    xmin = MIN(xData, MAX=xmax)
    ymin = MIN(yData, MAX=ymax)

    ; Units in degrees. Just return the range.
    if (self._gridUnits eq 2) then begin

        lonRange = [xmin, xmax]
        latRange = [ymin, ymax]

        return, 1
    endif

    ; Units must be in meters.

    if (N_TAGS(sMap) eq 0) then begin
        sMap = self->GetProjection()
    endif

    ; If our dataspace is actually in meters, failure.
    if (N_TAGS(sMap) eq 0) then $
        return, 0

    ; If the dataspace has a map projection,
    ; then convert the four corners back to degrees.
    lonlat = MAP_PROJ_INVERSE([xmin, xmax, xmax, xmin], $
        [ymin, ymin, ymax, ymax], $
        MAP_STRUCTURE=sMap)

    minn = MIN(lonlat, DIMENSION=2, MAX=maxx)
    lonRange = [minn[0], maxx[0]]
    latRange = [minn[1], maxx[1]]

    return, 1

end


;----------------------------------------------------------------------------
;+
; :Description:
;    Override the <i>_IDLitVisualization::Add</i> method, so we can change
;    our contour level values if a new contour level is added.
;
; :Params:
;    oVis
;
; :Keywords:
;    _REF_EXTRA
;
; :Author: chris
;-
pro IDLitVisContourContainer::Add, oVis, INTERNAL=internal, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Loop thru one-by-one, to simplify the code below.
    if (N_Elements(oVis) gt 1) then begin
        for i=0,N_Elements(oVis)-1 do begin
            self->Add, oVis[i], INTERNAL=internal, _EXTRA=_extra
        endfor
        return
    endif
    
    if (~Obj_Valid(oVis) || ~Obj_Isa(oVis, 'IDLitVisContourLevel')) then return
    self->GetProperty, PARENT=oParent
    if (~Obj_Valid(oParent) || ~Obj_Isa(oParent, 'IDLitVisContour') || $
        ~Obj_Valid(oParent._oContour)) then return


    if (~Keyword_Set(internal)) then begin
        ; Retrieve our cached contour value.
        oVis->GetProperty, _VALUE=value

        ; Retrieve the current contour values and insert the new one.
        oParent._oContour->GetProperty, C_VALUE=c_value
        n = N_Elements(c_value)
        if (n ge 1) then begin
            ; Insert into the sorted position.
            index = MAX(WHERE(c_value lt value)) + 1
            c_value = [c_value, 0]
            if (index lt n) then c_value[index+1:*] = c_value[index:n-1]
            c_value[index] = value
        endif else begin
        endelse
    endif


    self->_IDLitVisualization::Add, oVis, POSITION=index, _EXTRA=_extra

    
    if (~Keyword_Set(internal)) then begin
        oParent->SetProperty, C_VALUE=c_value
        void = oParent->_GetLevels()
    endif

end


;----------------------------------------------------------------------------
;+
; :Description:
;    Override the <i>_IDLitVisualization::Remove</i> method, so we can change
;    our contour level values if a contour level is deleted.
;
; :Params:
;    oVis
;
; :Keywords:
;    _REF_EXTRA
;
; :Author: chris
;-
pro IDLitVisContourContainer::Remove, oVis, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Loop thru one-by-one, to simplify the code below.
    if (N_Elements(oVis) gt 1) then begin
        for i=0,N_Elements(oVis)-1 do begin
            self->Remove, oVis[i], _REF_EXTRA=_extra
        endfor
        return
    endif
    
    if (~Obj_Valid(oVis) || ~Obj_Isa(oVis, 'IDLitVisContourLevel')) then $
        return

    ; Determine which contour level is being removed.
    void = self->IsContained(oVis, POSITION=index)

    ; Cache our current contour value back onto ourself.
    oVis->GetProperty, VALUE=oldValue
    oVis->SetProperty, _VALUE=oldValue

    self->_IDLitVisualization::Remove, oVis, _REF_EXTRA=_extra

    if (index lt 0) then return
    
    self->GetProperty, PARENT=oParent
    if (~Obj_Valid(oParent) || ~Obj_Isa(oParent, 'IDLitVisContour') || $
        ~Obj_Valid(oParent._oContour)) then return
    
    ; Retrieve the current contour values and remove the dead one.
    oParent._oContour->GetProperty, C_VALUE=c_value
    n = N_Elements(c_value)
    if (n ge 2) then begin
        c_value = c_value[WHERE(LINDGEN(n) ne index)]
    endif else begin
    endelse
    oParent->SetProperty, C_VALUE=c_value
    void = oParent->_GetLevels()

end


;----------------------------------------------------------------------------
pro IDLitVisContourContainer__Define
    compile_opt idl2, hidden
    struct = { IDLitVisContourContainer, $
        inherits _IDLitVisualization }
end



;----------------------------------------------------------------------------
;+
; IDLitVisContour__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisContour object.
;
;-
pro IDLitVisContour__Define

    compile_opt idl2, hidden

    struct = { IDLitVisContour,         $
        inherits IDLitVisualization, $   ; Superclass: _IDLitVisualization
        _oContour: OBJ_NEW(),        $   ; IDLgrContour object
        _oPalette: OBJ_NEW(),        $
        _oLevels: OBJ_NEW(),         $   ; CONTOUR_LEVELS container
        _pProps: PTR_NEW(),          $   ; contour level registered properties
        _pShow: PTR_NEW(),           $   ; C_LABEL_SHOW cache
        _gridUnits: 0b,              $ ; List of possible units
        _xVisLog : 0, $
        _yVisLog : 0, $
        _zVisLog : 0, $
        _zvalue: 0d,                 $
        _cValSet: 0b,                $
        _bClipped: 0b,               $ ; Flag: does contour lie entirely
                                          ;   outside of current data range?
        _preClipHide: 0b,            $ ; HIDE setting prior to clip.
        _palColor: 0b,               $
        _defaultIndices: 0b,         $
        _hasMapProjection: 0b,       $   ; map projection in effect?
        _tickinterval: 0d,           $
        _ticklen: 0d                 $
    }
end
