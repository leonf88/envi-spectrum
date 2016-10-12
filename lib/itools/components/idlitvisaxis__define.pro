; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisaxis__define.pro#2 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; PURPOSE:
;    The IDLitVisAxis class is the component wrapper for the axis.
;
; MODIFICATION HISTORY:


;----------------------------------------------------------------------------
; IDLitVisAxis::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisAxis::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisAxis::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    ;; get numeric formats
    result = IDLitGetResource(1, numericFormatNames, /NUMERICFORMAT, /NAMES)
    result = IDLitGetResource(1, numericFormatExamples, $
        /NUMERICFORMAT, /EXAMPLES)

    ;; get time formats
    ; to print examples of time formats
    ; result = IDLitGetResource(1, /TIMEFORMAT, /PRINT)
    result = IDLitGetResource(1, timeFormatNames, /TIMEFORMAT, /NAMES)
    result = IDLitGetResource(1, timeFormatExamples, /TIMEFORMAT, /EXAMPLES)

    if (registerAll) then begin
        self._oAxis->RegisterProperty, 'TICK_DEFINEDFORMAT', $
            DESCRIPTION='Predefined tick format', $
            ENUMLIST=['None', $
                      'Use Tick Format Code', $
                      numericFormatNames+' ('+numericFormatExamples+')', $
                      timeFormatNames+' ('+timeFormatExamples+')' $
                     ], $
            NAME='Tick format', /ADVANCED_ONLY

        ; Text properties. Register these on the axis (even though they
        ; belong to us) so they appear in the correct order.
        self._oAxis->RegisterProperty, 'AXIS_TITLE', /STRING, $
            DESCRIPTION='Axis title', $
            NAME='Title'

        self._oAxis->RegisterProperty, 'TEXT_COLOR', /COLOR, $
            DESCRIPTION='Text color', $
            NAME='Text color'

        ; Norm Location needs to be registered to allow copy/paste to work
        self._oAxis->RegisterProperty, 'NORM_LOCATION', USERDEF='', $
            DESCRIPTION='Normalized Location', $
            NAME='Normalized Location', $
            /HIDE, /ADVANCED_ONLY
        self._oAxis->RegisterProperty, 'LOCATION', USERDEF='', $
            DESCRIPTION='Location', $
            NAME='Location', $
            /HIDE, /ADVANCED_ONLY
        self._oAxis->RegisterProperty, 'RANGE', USERDEF='', $
            DESCRIPTION='Range', $
            NAME='Range', $
            /HIDE, /ADVANCED_ONLY
        self._oAxis->RegisterProperty, 'CRANGE', USERDEF='', $
            DESCRIPTION='CRange', $
            NAME='CRange', $
            /HIDE, /ADVANCED_ONLY
        self._oAxis->RegisterProperty, 'TICKFRMTDATA', USERDEF='', $
            DESCRIPTION='Tick Format Data', $
            NAME='Tick Format Data', $
            /HIDE, /ADVANCED_ONLY

        ; Change some property attributes.
        self._oAxis->SetPropertyAttribute, ['EXACT', 'EXTEND'], /HIDE
        self._oAxis->SetPropertyAttribute, 'TICKLEN', $
            DESCRIPTION='Major tick length relative to overall range', $
            VALID_RANGE=[0,1,0.01d]

        self._oAxis->SetPropertyAttribute, 'LOG', SENSITIVE=0

    endif else if (updateFromVersion lt 610) then begin
        ; Update enumerated list for the 'TICK_DEFINEDFORMAT' property.
        self->SetPropertyAttribute, 'TICK_DEFINEDFORMAT', $
            ENUMLIST=['None', $
                      'Use Tick Format Code', $
                      numericFormatNames+' ('+numericFormatExamples+')', $
                      timeFormatNames+' ('+timeFormatExamples+')' $
                     ]
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'DATA_POSITION', /BOOLEAN, $
            DESCRIPTION='Lock to Data Position', $
            NAME='Lock to Data', /ADVANCED_ONLY

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of axis', $
            VALID_RANGE=[0,100,5]

        if (registerAll) then begin
            ; Aggregate the axis and font properties.
            self->Aggregate, self._oAxis
            self->Aggregate, self._oFont
        endif

        ; Hide ALPHA_CHANNEL - use TRANSPARENCY property instead.
        self._oAxis->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, $
          /ADVANCED_ONLY

    endif

end

;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
function IDLitVisAxis::Init, $
                     NAME=NAME, $
                     DESCRIPTION=DESCRIPTION, $
                     _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not keyword_set(name))then name ="Axis"
    if(not keyword_set(DESCRIPTION))then DESCRIPTION ="Axis Visualization"

    ; Initialize superclass
    success = self->IDLitVisualization::Init( TYPE="IDLAXIS", $
                                              /REGISTER_PROPERTIES, $
                                              NAME=NAME, $
                                              DESCRIPTION=DESCRIPTION, $
                                              ICON='axis', $
                                              IMPACTS_RANGE=0, $
                                              /MANIPULATOR_TARGET, $
                                              _EXTRA=_extra)

    if (not success) then $
      return, 0

    self._ticklen = 0.05d

    ; Request no (additional) axes.
    self->SetAxesRequest, 0, /ALWAYS

    ; Create the Axis object.
    self._oAxis = OBJ_NEW('IDLgrAxis', $
        /ANTIALIAS, $
        /EXACT, $
        /REGISTER_PROPERTIES, $
        MAJOR=-1, MINOR=-1, /private)

    ; Create the Font object. Use the current zoom factor of the tool window
    ; as the initial font zoom factor.   Likewise for view zoom, and normalization
    ; factor.
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
    self._oFont = OBJ_NEW('IDLitFont', FONT_ZOOM=fontZoom, VIEW_ZOOM=viewZoom, $
        FONT_NORM=fontNorm)
    self._oAxis->GetProperty, TICKTEXT=oText
    oText->SetProperty, FONT=self._oFont->GetFont()

    ; Add our axis.
    ; NOTE: the IDLgrAxis and IDLitFont properties will be aggregated
    ; as part of the property registration process in an upcoming call
    ; to ::_RegisterProperties.
    self->Add, self._oAxis, /NO_NOTIFY, /NO_UPDATE

    ; Register all properties.
    self->IDLitVisAxis::_RegisterProperties

    ; Create and set our default selection visual.
    oSelectionVisual = OBJ_NEW('IDLitManipVisSelect', /HIDE)
    self._oAxisShadow = OBJ_NEW('IDLgrAxis', $
        COLOR=!COLOR.DODGER_BLUE, $
        ALPHA_CHANNEL=0.6, $
        /EXACT, $
        MINOR=0, $
        /NOTEXT, $
        THICK=3)
    oSelectionVisual->Add, self._oAxisShadow
    self->SetDefaultSelectionVisual, oSelectionVisual, POSITION=0
    self._oMySelectionVisual = oSelectionVisual

    self._dataPosition = 0b     ; by default, axes are locked to screen position
                                ; not data position

    ; Set any properties
    self->IDLitVisAxis::SetProperty, $
        _EXTRA=_extra

    RETURN, 1 ; Success
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
pro IDLitVisAxis::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oTitle
    OBJ_DESTROY, self._oFont
    Ptr_Free, self._pTicktext
    PTR_FREE, self._lastTickStrings

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisAxis::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisAxis::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oAxis)) then $
        self._oAxis->GetProperty
    if (OBJ_VALID(self._oFont)) then $
        self._oFont->GetProperty

    ; Register new properties.
    self->IDLitVisAxis::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no (additional) axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
        if (OBJ_VALID(self._oTitle)) then begin
            if (OBJ_VALID(self._oRevTitle)) then begin
                self->IDLgrModel::Remove, self._oRevTitle
                OBJ_DESTROY, self._oRevTitle
                self._oTitle->SetProperty, HIDE=0
            endif
            self->GetProperty, TEXTPOS=textpos
            self->SetProperty, TEXTPOS=textpos
        endif
    endif

    if (self.idlitcomponentversion lt 620) then begin
        self._oAxis->GetProperty, DIRECTION=mydirection, $
            TEXTPOS=oldpos, TICKDIR=olddir, $
            TEXTBASELINE=mybaseline, TEXTUPDIR=myupdir
        isBaseReversed = MIN(mybaseline) lt 0
        isUpReversed = MIN(myupdir) lt 0
        ; Need to update our new local TICKDIR and TEXTPOS properties.
        case mydirection of
        0: doReverse = isUpReversed
        1: doReverse = isBaseReversed
        2: doReverse = isBaseReversed
        endcase
        if (doReverse) then begin
            self->IDLitVisAxis::SetProperty, $
                TESTPOS=1-oldpos, TICKDIR=1-olddir
        endif
    endif
end

;----------------------------------------------------------------------------
pro IDLitVisAxis::Add, oTargets, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; an axis may be pasted when another axis is selected
    ; If so, it should be added to the axes group
    ; so that its tick length can be recomputed
    self->GetProperty, PARENT=oAxes
    for i=0, n_elements(oTargets)-1 do begin
        if (OBJ_ISA(oTargets[i], "IDLitVisAxis") && OBJ_VALID(oAxes)) then begin
            oAxes->Add, oTargets[i], _EXTRA=_extra
        endif else begin
            self->IDLitVisualization::Add, oTargets, _EXTRA=_extra
        endelse
    endfor


end

;----------------------------------------------------------------------------
; Internal method to ensure that if the user has input either their
; own ticktext object or strings, that the number of strings
; matches the number of major ticks. If the number matches then we
; use their values, otherwise we let the axis pick its own values.
;
pro IDLitVisAxis::_VerifyTicktext

    compile_opt idl2, hidden

    ; If user has switched the format, then disable
    ; the user's custom ticktext.
    if (self._tickDefinedFormat gt 0) then begin
        if (Obj_Valid(self._oUserText) || $
            Ptr_Valid(self._pTicktext)) then begin
            self._oAxis->SetProperty, TICKTEXT=Obj_New()
        endif
        return
    endif

    self._oAxis->GetProperty, MAJOR=major, TICKTEXT=oText

    ; User has input a ticktext object.
    if (Obj_Valid(self._oUserText)) then begin
        self._oUserText->GetProperty, STRINGS=ticknames
        if (N_Elements(ticknames) eq major) then begin
            if (oText ne self._oUserText) then $
                self._oAxis->SetProperty, TICKTEXT=self._oUserText
        endif else begin
            self._oAxis->SetProperty, TICKTEXT=Obj_New()
        endelse
        return
    endif

    if (~Obj_Valid(oText)) then return
    oText->GetProperty, STRINGS=strings

    ; User has input a string array.
    if (Ptr_Valid(self._pTicktext) && Ptr_Valid(self._lastTickStrings)) then begin
        ; Determine which values in the strings array must be replaced
        ; with values from *self._pTicktext. This keeps user specified labels
        ; connected with their proper axes as the graphic is scrolled/panned
        nstrings = N_ELEMENTS(*self._lastTickStrings)
        if (nstrings gt N_ELEMENTS(*self._pTicktext)) then $
          MESSAGE, 'Tick name array must have length equal to the number of major tick marks.'
        for tickIndex=0,nstrings - 1 do begin
            strings[WHERE( (*self._lastTickStrings)[tickIndex] eq strings, /NULL )] = $
                (*self._pTicktext)[tickIndex]
        endfor
        
        oText->SetProperty, STRINGS=strings
    endif
end

;----------------------------------------------------------------------------
pro IDLitVisAxis::_SetAxisScaledTicklen, scaledTicklen

    compile_opt idl2, hidden

    self._oAxis->SetProperty, TICKLEN=scaledTicklen
    self._oAxisShadow->SetProperty, TICKLEN=scaledTicklen
end


;---------------------------------------------------------------------------
; Purpose:
;   Internal routine to update the axis normalized location.
;
pro IDLitVisAxis::_UpdateNormLocation, location

    compile_opt idl2, hidden

    self->GetProperty, PARENT=oAxes
    if ~OBJ_VALID(oAxes) then begin
        ; colorbar axis is not part of an axes group
        xrange = [-1.0, 1.0]
        yrange = xrange
        zrange = [0.0, 0.0]
    endif else begin
        oAxes->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
    endelse

    dx = xRange[1] - xRange[0]
    dy = yRange[1] - yRange[0]
    dz = zRange[1] - zRange[0]

    ; save the normalized location so we can determine if this axis
    ; should be repositioned at the min or max of the range of one of the other axes.
    self._normLocation[0] = (dx gt 0) ? (location[0]-xRange[0])/dx : 0
    self._normLocation[1] = (dy gt 0) ? (location[1]-yRange[0])/dy : 0
    self._normLocation[2] = (dz gt 0) ? (location[2]-zRange[0])/dz : 0

end


;----------------------------------------------------------------------------
pro IDLitVisAxis::UpdateAxisTicklen, xr, yr, zr

    compile_opt idl2, hidden

    if (N_ELEMENTS(xr) eq 0) then begin
        layer = self->_GetLayer()
        if (OBJ_ISA(layer, 'IDLitgrAnnotateLayer')) then begin
            xr=[-1.0, 1.0]
            yr=xr
            zr=[0.0, 0.0]
        endif else begin
            self->GetProperty, PARENT=oAxes
            if ~OBJ_VALID(oAxes) then begin
                ; colorbar axis is not part of an axes group
                xr = [-1.0, 1.0]
                yr = xr
                zr = [0.0, 0.0]
            endif else begin
                oAxes->GetProperty, XRANGE=xr, YRANGE=yr, ZRANGE=zr
            endelse
        endelse
    endif

    self._oAxis->GetProperty, DIRECTION=direction

    ; For X axis the ticks extend in Y direction,
    ; for Y & Z axes the ticks extend in X direction.
    range = (direction eq 0) ? yr : xr

    ; Sanity check for NaNs or Infinities.
    isFinite = FINITE(range)
    if (~isFinite[0]) then $
        range[0] = isFinite[1] ? range[1] : 0
    if (~isFinite[1]) then $
        range[1] = isFinite[0] ? range[0] : 0

    self->_SetAxisScaledTicklen, ABS(range[1] - range[0]) * self._ticklen

end


;----------------------------------------------------------------------------
pro IDLitVisAxis::UpdateAxisLocation

    compile_opt idl2, hidden

    self._oAxis->GetProperty, DIRECTION=direction

    ; set the location based on the norm_location.
    self->GetProperty, PARENT=oAxes
    
    ; UpdateAxisLocation called only from axes group, so don't need
    ; alternate method of obtaining ranges
    oAxes->GetProperty, XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, $
        XREVERSE=xreverse, YREVERSE=yreverse, ZREVERSE=zreverse

    if (xReverse) then $
        xrange = REVERSE(xrange)
    if (yReverse) then $
        yrange = REVERSE(yrange)
    if (zReverse) then $
        zrange = REVERSE(zrange)

    if (self._dataPosition) then begin
        ; calc new norm location based on old current location
        ; and new range.  not changing location so return
        self->GetProperty, LOCATION=location
        self->_UpdateNormLocation, location
        return
    endif

    x = xrange[0] + self._normLocation[0] * (xrange[1] - xrange[0])
    y = yrange[0] + self._normLocation[1] * (yrange[1] - yrange[0])
    z = zrange[0] + self._normLocation[2] * (zrange[1] - zrange[0])
    case direction of
        0: location = [0, y, z]
        1: location = [x, 0, z]
        2: location = [x, y, 0]
    endcase

    ; Set the new location directly on the contained axis and its shadow.
    ; In this case, the normalized location should NOT change,
    ; so do NOT do this: self->SetProperty, LOCATION=location
    self._oAxis->SetProperty, LOCATION=location
    self._oAxisShadow->SetProperty, LOCATION=location

    ; Ensure that the major tick labels are accurate
    self->_VerifyTicktext

end


;----------------------------------------------------------------------------
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
;   Any keyword to IDLitVisAxis::Init followed by the word "Get"
;   can be retrieved using IDLitVisAxis::GetProperty.  In addition
;   the following keywords are available:
;
;   Note: While SetProperty must not set the log property of the grAxis
;         directly, GetProperty uses the aggregated property to retrieve
;         the value.
;
pro IDLitVisAxis::GetProperty, $
    TICK_DEFINEDFORMAT=tickDefinedFormat, $
    TICKLEN=axisTicklen, $
    AXIS_TITLE=axisTitle, $
    CRANGE=crange, $
    LOCATION=location, $
    MAJOR=major, $
    MINOR=minor, $
    NORM_LOCATION=normLocation, $  ; not registered, need to pass directly
    TEXT_COLOR=textColor, $
    TRANSPARENCY=transparency, $
    TRANSFORM=transform, $
    DATA_POSITION=dataPosition, $
    TICKDIR=tickdir, $
    TEXTPOS=textpos, $
    TICKNAME=tickName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; Get my properties

    if ARG_PRESENT(crange) then $
        self._oAxis->GetProperty, CRANGE=crange

    if ARG_PRESENT(location) then $
        self._oAxis->GetProperty, LOCATION=location

    if ARG_PRESENT(axisTicklen) then $
        axisTicklen = self._ticklen

    if ARG_PRESENT(tickDefinedFormat) then $
        tickDefinedFormat = self._tickDefinedFormat

    if ARG_PRESENT(transparency) then begin
        self._oAxis->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if ARG_PRESENT(axisTitle) then begin
        ; Only return title if object exists.
        if (OBJ_VALID(self._oTitle)) then begin
            self._oTitle->GetProperty, STRINGS=dispAxisTitle, UVALUE=axisTitle
            if (~ISA(axisTitle, 'STRING')) then begin
              self._oTitle->SetProperty, UVALUE=dispAxisTitle
              axisTitle = dispAxisTitle
            endif
        endif else axisTitle = ''
    endif

    ; Retrieve the text color from either the axis or the text.
    if ARG_PRESENT(textColor) then begin

        ; Default is to use the axis color.
        self._oAxis->GetProperty, COLOR=textColor, $
            USE_TEXT_COLOR=useColor

        ; Retrieve from one of the actual text objects.
        if (useColor) then begin
            self._oAxis->GetProperty, TICKTEXT=oText
            if (OBJ_VALID(oText)) then $
                oText->GetProperty, COLOR=textColor
        endif
    endif

    if ARG_PRESENT(normLocation) then $
        normLocation = self._normLocation

    if ARG_PRESENT(dataPosition) then $
        dataPosition = self._dataPosition

    ; Override our TRANSFORM property and return the LOCATION
    ; inside the TRANSFORM. Needed for Undo/Redo.
    if ARG_PRESENT(transform) then begin
        self._oAxis->GetProperty, LOCATION=location
        transform = IDENTITY(4)
        transform[3,0:2] = location
    endif

    ; See note in SetProperty about MAJOR/MINOR values.
    if ARG_PRESENT(major) then begin
        if ((self._majorminor and 1b) ne 0b) then $
            self._oAxis->GetProperty, MAJOR=major $
        else $
            major = -1
    endif

    if ARG_PRESENT(minor) then begin
        if ((self._majorminor and 2b) ne 0b) then $
            self._oAxis->GetProperty, MINOR=minor $
        else $
            minor = -1
    endif

    if ARG_PRESENT(textpos) then $
        textpos = self._textpos

    if ARG_PRESENT(tickdir) then $
        tickdir = self._tickdir

    if ARG_PRESENT(tickName) then begin
      self._oAxis->GetProperty, TICKTEXT=oText
      if Obj_Valid(oText) then $
        oText->GetProperty, STRINGS=tickName
    endif

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
;   Any keyword to IDLitVisAxis::Init followed by the word "Set"
;   can be retrieved using IDLitVisAxis::GetProperty.  In addition
;   the following keywords are available:
;
;   Note: While SetProperty must not set the log property of the grAxis
;         directly, GetProperty uses the aggregated property to retrieve
;         the value.
;
pro IDLitVisAxis::SetProperty,  $
    AXIS_TITLE=axisTitle, $
    COLOR=color, $
    DATA_POSITION=dataPosition, $  ; this needs to go away
    DIRECTION=direction, $
    LOCATION=location, $  ; not registered, need to pass directly
    LOG=log, $
    MAJOR=major, $
    MINOR=minor, $
    NORM_LOCATION=normLocation, $  ; not registered, need to pass directly
    NOTEXT=notext, $
    PRIVATE=PRIVATE, $
    RANGE=rangeIn, $
    TEXT_COLOR=textColor, $
    TEXTALIGNMENTS=textAlignments, $
    TEXTBASELINE=textbaseline, $
    TEXTPOS=textPos, $
    TEXTUPDIR=textupdir, $
    THICK=thick, $
    TICK_DEFINEDFORMAT=tickDefinedFormat, $
    TICK_UNITS=tickUnits, $  ; need to set on shadow plot as well
    TICKDIR=tickdir, $
    TICKFORMAT=tickFormatIn, $
    TICKFRMTDATA=tickFrmtData, $
    TICKLAYOUT=tickLayout, $
    TICKLEN=axisTicklen, $
    TICKNAME=tickName, $
    TICKTEXT=tickText, $
    TICKVALUES=tickValues, $  ; not registered, need to pass directly
    TRANSFORM=transform, $
    TRANSPARENCY=transparency, $
    XCOORD_CONV=xcoordconv, $  ; not registered, need to pass directly
    YCOORD_CONV=ycoordconv, $  ; not registered, need to pass directly
    ZCOORD_CONV=zcoordconv, $  ; not registered, need to pass directly
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    updateAlignment = 0b

    ; Tricky code to verify that tick formats are legal
    ; or the format is a valid function name.
    if (N_ELEMENTS(tickFormatIn) eq 1) then begin
        tickFormatCheck = STRTRIM(tickFormatIn, 2)
        if (tickFormatCheck ne '') then begin
            if (STRMID(tickFormatCheck, 0, 1) eq '(') && $
               (STRMID(tickFormatCheck, $
                   STRLEN(tickFormatCheck)-1, 1) eq ')') then begin

                CATCH, err
                if (err ne 0) then begin
                    CATCH, /CANCEL
                endif else begin
                    ; If this fails we will skip over the next line.
                    test = STRING(0, FORMAT=tickFormatCheck)
                    tickFormat = tickFormatCheck
                endelse

            endif else begin
                ; it's not a format, verify that it is a tickformat function

                CATCH, err
                if (err ne 0) then begin
                    CATCH, /CANCEL
                endif else begin
                    ; If this fails we will skip over the next line.
                    resolve_routine, tickFormatCheck, $
                       /IS_FUNCTION, /NO_RECOMPILE
                    tickFormat = tickFormatCheck
                endelse

            endelse

        endif else $   ; null string just resets the format or function name
            tickFormat = tickFormatCheck

        ; We will actually set the TICKFORMAT below.
    endif


    if (N_ELEMENTS(tickDefinedFormat) eq 1) then begin
        self._tickDefinedFormat = tickDefinedFormat
        ; unhide the custom format property if tickDefinedFormat
        ; is set to 'Use Tick Format Code'
        self._oAxis->SetPropertyAttribute, 'TICKFORMAT', $
            SENSITIVE=(tickDefinedFormat eq 1)

        result = IDLitGetResource(1, numericFormats, /NUMERICFORMAT, /FORMATS)
        result = IDLitGetResource(1, timeFormats, /TIMEFORMAT, /FORMATS)
        offset = (num = 2)      ; offset to account for first two formats
        case 1 OF
          ;; no format
          tickDefinedFormat EQ 0 : tickFormat=''
          ;; use custom TICKFORMAT code already in place
          tickDefinedFormat EQ 1 : $
            if (strlen(self._lastTickFormat) gt 0) then tickFormat=self._lastTickFormat
          ;; numeric formats
          tickDefinedFormat LT ((num+=n_elements(numericFormats))) : $
            tickFormat = numericFormats[tickDefinedFormat-offset]
          ;; time formats
          tickDefinedFormat LT ((num+=n_elements(timeFormats))) : $
            tickFormat = $
            timeFormats[tickDefinedFormat-offset-n_elements(numericFormats)]
          else:
        endcase

        ; We will actually set the TICKFORMAT below.
    endif


    ; Set the TICKFORMAT now.
    ; if TICKFRMTDATA is defined it must be passed in through
    ; the same setproperty call with TICKFORMAT
    if (N_ELEMENTS(tickFormat) || N_ELEMENTS(tickFrmtData)) then begin
        if ((n_elements(tickFormat) gt 0) && $
            (strlen(tickFormat) gt 0)) then self._lastTickFormat = tickFormat
        self._oAxis->SetProperty, TICKFORMAT=tickFormat, $
            TICKFRMTDATA=tickFrmtData
        ; If TICKFORMAT starts with a (C( then assume it is a time format,
        ; and change the TICKUNITS.
        if (N_ELEMENTS(tickFormat)) then begin
            ; Either time or null string (same as type 'Numeric').
          if (N_ELEMENTS(tickUnits) eq 0) then $
            tickUnits = STRCMP(tickFormat, '(C(', 3, /FOLD_CASE) ? $
                'Time' : ''
            ; We will actually set the TICKUNITS below.
        endif
    endif

    ; TRANSPARENCY
    if (N_ELEMENTS(transparency)) then begin
        alpha = 0 > ((100.-transparency)/100) < 1
        
        self._oAxis->SetProperty, ALPHA_CHANNEL=alpha

       ; Set all the tick text.
        self._oAxis->GetProperty, TICKTEXT=oText
        for i=0,N_ELEMENTS(oText)-1 do $
            oText[i]->SetProperty, ALPHA_CHANNEL=alpha

        ; Set the title text.
        if (OBJ_VALID(self._oTitle)) then $
            self._oTitle->SetProperty, ALPHA_CHANNEL=alpha
    endif


    ; TICKUNITS needs to be set on both axis and shadow.
    if (N_ELEMENTS(tickUnits) gt 0) then begin
        self._oAxis->SetProperty, TICKUNITS=tickUnits
        self._oAxisShadow->SetProperty, TICKUNITS=tickUnits
    endif


    ; TICKDIR needs to be set on both axis and shadow.
    ; We need to handle this here rather than using the aggregate property
    ; since we could be setting TICKDIR to our internal TICKDIR=2 flag,
    ; which isn't part of the enumerated list (for now). In this case
    ; we disable the TICKDIR property.
    if (N_ELEMENTS(tickdir) gt 0) then begin
        self._tickdir = tickdir
        self->SetPropertyAttribute, 'TICKDIR', $
            SENSITIVE=(tickdir ne 2), UNDEFINED=(tickdir eq 2)
        ; We will set the property below, depending upon axes reversal.
        updateAlignment = 1b
    endif


    ; Override our TRANSFORM property and set the LOCATION instead.
    ; Needed for Undo/Redo.
    if (N_ELEMENTS(transform) gt 0) then $
        location = transform[3,0:2]

    if (N_ELEMENTS(dataPosition)) then $
        self._dataPosition = KEYWORD_SET(dataPosition)

    ; For location, call our internal method.
    if (N_ELEMENTS(location) gt 0) then begin
        self._oAxis->SetProperty, LOCATION=location
        self._oAxisShadow->SetProperty, LOCATION=location
        self->IDLitVisAxis::_UpdateNormLocation, location
    endif


    if (N_ELEMENTS(direction) gt 0) then begin
        
        ; Support the ability to specify direction as string X,Y,Z
        if SIZE(direction,/TYPE) eq 7 && $
            STRLEN(direction) eq 1 then begin
            case STRLOWCASE(direction) of
            'y': direction = 1
            'z': direction = 2
             ELSE: direction = 0
            endcase
        endif
        
        self._oAxis->SetProperty, DIRECTION=direction
        self._oAxisShadow->SetProperty, DIRECTION=direction
        updateAlignment = 1b
    endif

    if (N_ELEMENTS(thick) gt 0) then begin
        self._oAxis->SetProperty, THICK=thick
        self._oAxisShadow->SetProperty, THICK=(thick + 2) < 10 ; slightly fatter
    endif

    if (N_ELEMENTS(tickLayout) gt 0) then begin
        self._oAxis->SetProperty, TICKLAYOUT=tickLayout
        ; Convert TICKLAYOUT=1 (only labels) into TICKLAYOUT=0.
        self._oAxisShadow->SetProperty, TICKLAYOUT=2*(tickLayout eq 2)
    endif

    if (N_ELEMENTS(tickValues) ne 0) then begin
      self._oAxis->SetProperty,TICKVALUES=tickValues
      self._oAxisShadow->SetProperty,TICKVALUES=tickValues
    endif
    
    ; The TICKNAME keyword has precedence over TICKTEXT although
    ; they are otherwise identical
    if (N_ELEMENTS(tickName) gt 0) then tickText=tickName

    if (N_ELEMENTS(tickText) gt 0) then begin
    
        self._oAxis->GetProperty, TICKTEXT=oAxisText
        self->GetProperty, MAJOR=nmajor
        
        if (nmajor eq -1) then begin
          self._oAxis->SetProperty, MAJOR=N_ELEMENTS(tickText)
          nmajor = N_ELEMENTS(tickText)
        endif

        if n_elements(tickText) ne nmajor then $
            message, 'Tick name array must have length equal to the number of major tick marks.'
   
        if obj_valid(oAxisText) then begin
            if OBJ_VALID(oAxisText) then begin
                oAxisText->GetProperty, STRINGS=strings
                PTR_FREE, self._lastTickStrings
                self._lastTickStrings = PTR_NEW(strings)
            endif
        endif
    
        ; We will update the ticktext in _VerifyTicktext below.
        type = Size(tickText,/TYPE)
        if (type eq 7) then begin  ; string array
            Ptr_Free, self._pTicktext
            self._pTicktext = Ptr_New(tickText)
        endif else if (type eq 11) then begin  ; IDLgrText objref
            self._oUserText = tickText
        endif
        
    endif

    ; If the color was set on the axis lines, and the user hasn't set
    ; the text color manually, then also update the text color on the
    ; property sheet.
    if (N_ELEMENTS(color) gt 0) then begin        
        if (ISA(color, 'STRING') || N_ELEMENTS(color) eq 1) then $
            style_convert, color[0], COLOR=color
        
        ; Set the new axis color
        self->IDLitVisualization::SetProperty, COLOR=color
        
        ; Keep the text color and the axis color synchronized
        ; if necessary.
        self->GetProperty, TEXT_COLOR=txtColor
        self._oAxis->GetProperty, $
            USE_TEXT_COLOR=useColor
        if (~useColor) then $
            self->SetProperty, TEXT_COLOR=color
        
        ; if we have set color equal to text_color
        ; then synch up color and text_color
        if ARRAY_EQUAL(txtColor,color) then $
            self._oAxis->SetProperty, $
                USE_TEXT_COLOR=0
    endif

    ; TEXTBASELINE
    if (N_ELEMENTS(textbaseline) gt 0) then begin
        self._oAxis->SetProperty, TEXTBASELINE=textbaseline
        updateAlignment = 1b
    endif

    ; TEXTALIGNMENTS
    if (N_ELEMENTS(textAlignments) gt 0) then begin
        self._oAxis->SetProperty, TEXTALIGNMENTS=textAlignments
        updateAlignment = 1b
    endif

    ; TEXTUPDIR.
    if (N_ELEMENTS(textupdir) gt 0) then begin
        self._oAxis->SetProperty, TEXTUPDIR=textupdir
        updateAlignment = 1b
    endif

    ; TEXTPOS.
    if (N_ELEMENTS(textPos) gt 0) then begin
        self._textpos = textpos
        ; We will set the property below, depending upon axes reversal.
        updateAlignment = 1b
    endif


    if (updateAlignment) then begin
        ; Reset text alignment so it reverts to default.
        self._oAxis->SetProperty, TEXTALIGNMENTS=-1

        self._oAxis->GetProperty, DIRECTION=mydirection, $
            TEXTALIGNMENT=myalignment, $
            TEXTBASELINE=mybaseline, TEXTUPDIR=myupdir
        isBaseReversed = MIN(mybaseline) lt 0
        isUpReversed = MIN(myupdir) lt 0
        ; This is tricky. We want to change the text alignment depending
        ; upon both the text position and whether reversed or not.
        ; Normally, if you never set text alignment, then setting TEXTPOS
        ; will automatically change the alignment. However, since our axis
        ; may be reversed, we need to calculate the alignment manually.
        case mydirection of
        0: begin
            mytextpos = isUpReversed ? 1-self._textpos : self._textpos
            newalignment = mytextpos xor isUpReversed ? [0.5, 0] : [0.5, 1]
            if (self._tickdir ne 2) then $
                mytickdir = isUpReversed ? 1-self._tickdir : self._tickdir
           end
        1: begin
            mytextpos = isBaseReversed ? 1-self._textpos : self._textpos
            newalignment = mytextpos xor isBaseReversed ? [0, 0.5] : [1, 0.5]
            if (self._tickdir ne 2) then $
                mytickdir = isBaseReversed ? 1-self._tickdir : self._tickdir
           end
        2: begin
            mytextpos = isBaseReversed ? 1-self._textpos : self._textpos
            newalignment = mytextpos xor isBaseReversed ? [0, 0.5] : [1, 0.5]
            if (self._tickdir ne 2) then $
                mytickdir = isBaseReversed ? 1-self._tickdir : self._tickdir
           end
        endcase
        self._oAxis->SetProperty, TEXTALIGNMENT=newalignment, $
            TEXTPOS=mytextpos, TICKDIR=mytickdir
        self._oAxisShadow->SetProperty, TEXTALIGNMENT=newalignment, $
            TEXTPOS=mytextpos, TICKDIR=mytickdir

        ; Keep my TITLE in sync with my TEXTBASELINE, TEXTUPDIR, and TEXTPOS.
        if (OBJ_VALID(self._oTitle)) then begin
            case mydirection of
            0: self._oTitle->SetProperty, BASELINE=mybaseline, UPDIR=myupdir, $
                VERTICAL_ALIGNMENT=newalignment[1]
            1: self._oTitle->SetProperty, UPDIR=-mybaseline, BASELINE=myupdir, $
                VERTICAL_ALIGNMENT=1-newalignment[0]
            2: self._oTitle->SetProperty, UPDIR=-mybaseline, BASELINE=myupdir, $
                VERTICAL_ALIGNMENT=1-newalignment[0]
            endcase
        endif

    endif

    ; If text gets turned off, disable the properties.
    if (N_ELEMENTS(notext) gt 0) then begin
        self._oAxis->GetProperty, NOTEXT=notextOld
        self._oAxis->SetProperty, NOTEXT=notext
        if (notext ne notextOld) then begin
          self->IDLitComponent::SetPropertyAttribute, $
            ['TEXT_COLOR','TEXTPOS'], SENSITIVE=1-KEYWORD_SET(notext)
        endif
    endif

    if (N_ELEMENTS(axisTicklen)) then begin
        self._oAxis->GetPropertyAttribute, 'TICKLEN', VALID_RANGE=validRange
        axisTicklen >= validRange[0]
        axisTicklen <= validRange[1]
        self._ticklen = axisTicklen
        self->UpdateAxisTicklen
    endif

    if N_ELEMENTS(rangeIn) gt 0 then begin

       ; Retrieve properties necessary for computations.
        self._oAxis->GetProperty, RANGE=range
        oldrange = range

        ; Fill in the values that have changed.
        if (N_ELEMENTS(rangeIn) eq 2) then $
            range = rangeIn

        ; Sanity check for NaNs or Infinities.
        isFinite = FINITE(range)
        if (~isFinite[0]) then $
            range[0] = isFinite[1] ? range[1] : 0
        if (~isFinite[1]) then $
            range[1] = isFinite[0] ? range[0] : 0

        ; Don't allow zero length axis.
        if (range[1] eq range[0]) then $
            range[1] = (range[0] ne 0) ? range[0]*(1.000001d) : 1e-12

        ; For a log axis, the grAxis needs the range to be set to the
        ; original linear range.  Take the inverse log if necessary.
        ; Check the dataspace to determine if this axis should be
        ; log or not, rather than counting on the properties of this
        ; axis itself since we might be called from onDataRangeChange
        ; and our log property might not be updated yet.
        if N_ELEMENTS(direction) eq 0 then self._oAxis->GetProperty, DIRECTION=direction
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
            case direction of
            0: islogarithmic = xLog
            1: islogarithmic = yLog
            2: islogarithmic = zLog
            endcase
        endif else islogarithmic=0

        self._oAxis->GetProperty, LOG=wasLog
        self._oAxis->SetProperty, $
            LOG=isLogarithmic, $
            RANGE=islogarithmic ? 10^range : range

        self._oAxisShadow->SetProperty, $
            LOG=isLogarithmic, $
            RANGE=islogarithmic ? 10^range : range

        ; Enable Log property if we are already logarithmic,
        ; or if our range minimum is > 0.
        oldsensitive = wasLog || (oldrange[0] gt 0 && oldrange[1] gt 0)
        sensitive = islogarithmic || (range[0] gt 0 && range[1] gt 0)
        if (oldsensitive ne sensitive) then begin
          self->SetPropertyAttribute, 'LOG', SENSITIVE=sensitive
        endif
    endif


    ; Change the axis title.
    if (N_ELEMENTS(axisTitle) ge 1) then begin
        ; Create object if it doesn't already exist.
        if (~OBJ_VALID(self._oTitle)) then begin
            ; Retrieve current text color so we can set the title color.
            self->GetProperty, TEXT_COLOR=textColor
            self._oTitle = OBJ_NEW('IDLgrText', /ENABLE_FORMAT, $
                COLOR=textColor, $
                RECOMPUTE_DIMENSIONS=2, $
                FONT=self._oFont->GetFont())
            self._oAxis->SetProperty, TITLE=self._oTitle
        endif
        self._oTitle->SetProperty, STRINGS=Tex2IDL(axisTitle), UVALUE=axisTitle
    endif



    ; Retrieve the text color from either the axis or the text.
    if (N_ELEMENTS(textColor) gt 0) then begin

        if (ISA(textColor, 'STRING') || N_ELEMENTS(textColor) eq 1) then $
            style_convert, textColor[0], COLOR=textColor

        ; Get the axisColor
        self->IDLitVisualization::GetProperty, COLOR=axisColor

        ; If the axis color does not match the text color
        ; we are now no longer using the axis color.
        if (~ARRAY_EQUAL(axisColor, textColor)) THEN $
            self._oAxis->SetProperty, /USE_TEXT_COLOR ELSE $
            self._oAxis->SetProperty, USE_TEXT_COLOR=0

        ; First set all the tick text.
        self._oAxis->GetProperty, TICKTEXT=oText
        for i=0,N_ELEMENTS(oText)-1 do $
            oText[i]->SetProperty, COLOR=textColor

        ; Now set the title text.
        if (OBJ_VALID(self._oTitle)) then $
            self._oTitle->SetProperty, COLOR=textColor
    endif


    ; Recompute text dimensions.
    if (N_ELEMENTS(rangeIn) gt 0) then begin

        self._oAxis->GetProperty, TICKTEXT=oText

        for i=0,N_ELEMENTS(oText)-1 do begin
             oText[i]->SetProperty, CHAR_DIMENSIONS=[0,0], RECOMPUTE=2
        endfor

        if (OBJ_VALID(self._oTitle)) then $
            self._oTitle->SetProperty, CHAR_DIMENSIONS=[0,0], RECOMPUTE=2

    endif

    if(n_elements(PRIVATE) gt 0)then $
        self->IDLitComponent::SetProperty, PRIVATE=PRIVATE


    ; Turn off recompute dims on all the text, so it scales.
    if (KEYWORD_SET(recompute)) then begin
        for i=0,N_ELEMENTS(oText)-1 do $
            oText[i]->SetProperty, /ENABLE_FORMAT, RECOMPUTE=0
        if (OBJ_VALID(self._oTitle)) then $
            self._oTitle->SetProperty, RECOMPUTE=0
    endif

    if (N_ELEMENTS(log) gt 0) then begin
        ; don't allow the aggregated property exposed to the
        ; user to directly set log on the underlying grAxis
        ; Go through the dataspace first to start the process
        self._oAxis->GetProperty, DIRECTION=direction
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        logtmp = log
        if (OBJ_VALID(oDataSpace)) then begin
            case direction of
            0: oDataSpace->SetProperty, XLOG=log
            1: oDataSpace->SetProperty, YLOG=log
            2: oDataSpace->SetProperty, ZLOG=log
            else:
            endcase
            ; If setting the LOG failed, just set it directly on ourself.
            ; This can happen for axes within annotations like colorbars.
            if (logtmp ne log) then self._oAxis->SetProperty, LOG=logtmp
        endif
    endif

    if(N_ELEMENTS(normLocation) gt 0) then begin
        self._normLocation = normLocation
    end

    ; We need to handle MAJOR/MINOR manually, because they have
    ; a special "-1" value which forces IDL to compute defaults.
    ; Unfortunately, IDLgrAxis::GetProperty just returns the actual
    ; number of major (or minor) ticks, regardless of whether it
    ; computed them or the user set the number. So keep a flag
    ; indicating whether they have been set by the user or not.
    if (N_ELEMENTS(major) gt 0) then begin
        ; If user has their own ticktext, temporarily disable it
        ; to avoid warnings. We will call _VerifyTicktext later.
        if (Obj_Valid(self._oUserText)) then begin
            self._oAxis->SetProperty, TICKTEXT=Obj_New()
        endif
        self._oAxis->SetProperty, MAJOR=major
        self._oAxisShadow->SetProperty, MAJOR=major
        ; Turn off/on MAJOR-has-been-set flag.
        if (major eq -1) then $
            self._majorminor and= (not 1b) $  ; MAJOR was reset
        else $
            self._majorminor or= 1b   ; MAJOR set to a value
    endif

    if (N_ELEMENTS(minor) gt 0) then begin
        self._oAxis->SetProperty, MINOR=minor
        ; Turn off/on MINOR-has-been-set flag.
        if (minor eq -1) then $
            self._majorminor and= (not 2b) $  ; MINOR was reset
        else $
            self._majorminor or= 2b   ; MINOR set to a value
    endif

    IF n_elements(xcoordconv) NE 0 THEN BEGIN
      self._oAxis->SetProperty,XCOORD_CONV=xcoordconv
    ENDIF

    IF n_elements(ycoordconv) NE 0 THEN BEGIN
      self._oAxis->SetProperty,YCOORD_CONV=ycoordconv
    ENDIF

    IF n_elements(zcoordconv) NE 0 THEN BEGIN
      self._oAxis->SetProperty,ZCOORD_CONV=zcoordconv
    ENDIF

    self->_VerifyTicktext

    ; Only pass on those properties which affect the "shadow" axis.
    if (N_ELEMENTS(_extra) gt 0) then $
        self._oAxisShadow->SetProperty, $
            _EXTRA=['EXACT', 'EXTEND', 'GRIDSTYLE', $
                'LOCATION', 'TICKINTERVAL']


    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra


end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisAxis::GetXYZRange
;
; PURPOSE:
;   This function method overrides the _IDLitVisualization::GetXYZRange
;   function, taking into the tick labels.
;
; CALLING SEQUENCE:
;   Success = Obj->[_IDLitVisualization::]GetXYZRange( $
;    xRange, yRange, zRange [, /NO_TRANSFORM])
;
; ARGUMENTS
;    xRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [xmin, xmax], representing the
;       X range of the objects that impact the ranges.
;    yRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [ymin, ymax], representing the
;       Y range of the objects that impact the ranges.
;    zRange:   Set this argument to a named variable that upon return
;       will contain a two-element vector, [zmin, zmax], representing the
;       Z range of the objects that impact the ranges.
;
; KEYWORD PARAMETERS:
;    NO_TRANSFORM:  Set this keyword to indicate that this Visualization's
;       model transform should not be applied when computing the XYZ ranges.
;       By default, the transform is applied.
;
;    DATA:
;       Handle the DATA keyword of the superclass.  No change in behavior
;       is required in this method.
;
;
;-
function IDLitVisAxis::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=data, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    ; Grab the transformation matrix.
    if (not KEYWORD_SET(noTransform)) then $
        self->IDLgrModel::GetProperty, TRANSFORM=transform

    self._oAxis->GetProperty, TICKTEXT=oText, $
        XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange, $
        XCOORD_CONV=xcc, YCOORD_CONV=ycc, ZCOORD_CONV=zcc

    ; Apply coordinate conversion.
    xRange = xRange * xcc[1] + xcc[0]
    yRange = yRange * ycc[1] + ycc[0]
    zRange = zRange * zcc[1] + zcc[0]

    ; Apply coordinate conversion.
    self->_IDLitVisualization::_AccumulateXYZRange, 0, $
        outxRange, outyRange, outzRange, $
        xRange, yRange, zRange, $
        TRANSFORM=transform

    for i=0,N_ELEMENTS(oText)-1 do begin

        oText[i]->GetProperty, $
            XRANGE=xRange, YRANGE=yRange, ZRANGE=zRange

        ; Apply coordinate conversion.
        xRange = xRange * xcc[1] + xcc[0]
        yRange = yRange * ycc[1] + ycc[0]
        zRange = zRange * zcc[1] + zcc[0]

        self->_IDLitVisualization::_AccumulateXYZRange, 1, $
            outxRange, outyRange, outzRange, $
            xRange, yRange, zRange, $
            TRANSFORM=transform

    endfor

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   Override the superclass' method. We keep our selection visual in sync
;   with our visualization using SetProperty, so we don't need to
;   do any updates here.
;
pro IDLitVisAxis::UpdateSelectionVisual
    compile_opt idl2, hidden
    ; Do nothing.
end


;----------------------------------------------------------------------------
;pro IDLitVisAxis::OnDataRangeChange, oSubject, XRange, YRange, ZRange
;    compile_opt idl2, hidden
;    No need to override.
;end


;---------------------------------------------------------------------------
; IDLitVisAxis::OnViewportChange
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
;     width and height of the visible view (normalized relative to
;     the virtual canvas).
;
pro IDLitVisAxis::OnViewportChange, oSubject, oDestination, $
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
; IDLitVisAxis::OnViewZoom
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
pro IDLitVisAxis::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    ; Check if view zoom factor has changed.  If so, update the font.
    self._oFont->GetProperty, VIEW_ZOOM=fontViewZoom

    if (fontViewZoom ne viewZoom) then $
        self._oFont->SetProperty, VIEW_ZOOM=viewZoom

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewZoom, oSubject, oDestination, $
        viewZoom
end

;---------------------------------------------------------------------------
pro IDLitVisAxis::Translate, tx, ty, tz, $
    KEYMODS=keymods, $        ; undocumented keyword
    KEYVALUE=KeyValue, $      ; undocumented keyword
    PROBE_MESSAGE=probeMsg, $ ; undocumented keyword
    _REF_EXTRA=_extra

    compile_opt idl2, hidden, logical_predicate

    ; We weren't called with our special KEYMODS keyword
    ; probably being called from a macro - just provide
    ; default values
    if (N_ELEMENTS(keymods) eq 0) then $
        keymods=0
    if (N_ELEMENTS(KeyValue) eq 0) then $
        KeyValue=0

    self._oAxis->GetProperty, $
        DIRECTION=direction, $
        LOCATION=location

    oDataSpace = self->GetDataspace()
    is3D = oDataSpace->Is3D()

    ; <Ctrl+Shift> key changes the translation direction,
    ; or if the up-down arrow keys are used.
    switchdir = (KeyMods eq 3) || (KeyValue eq 7) || (KeyValue eq 8)

    case direction of
        0: tr = is3D && switchdir ? [0, 0, tz] : [0, ty, 0]
        1: tr = is3D && switchdir ? [0, 0, tz] : [tx, 0, 0]
        2: tr = switchdir ? [0, ty, 0] : [tx, 0, 0]
    endcase

    location += tr

    ; Call our method to actually set the location.
    self->IDLitVisAxis::SetProperty, LOCATION=location

    ; Fill in our probe message.
    case direction of
        0: probeMsg = is3D ? $
            STRING(location[1:2], FORMAT='(%"Y=%g, Z=%g")') : $
            STRING(location[1], FORMAT='(%"Y=%g")')
        1: probeMsg = is3D ? $
            STRING(location[0:2:2], FORMAT='(%"X=%g, Z=%g")') : $
            STRING(location[0], FORMAT='(%"X=%g")')
        2: probeMsg = STRING(location[0:1], FORMAT='(%"X=%g, Y=%g")')
    endcase

end


;---------------------------------------------------------------------------
pro IDLitVisAxis::Scale, sx, sy, sz, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden, logical_predicate

    ; Swallow scale calls. We don't want to allow user to scale axes.
    ; Normally, the scale would be disabled if an axis is selected.
    ; However, if it is part of a multiple selection, then the scale
    ; can get called on all selected items, including axes.

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Override IDLgrModel::Draw so we can
; automatically adjust for changes in aspect ratio.
;
pro IDLitVisAxis::Draw, oDest, oLayer

    compile_opt idl2, hidden

    catch, iErr
    if (iErr ne 0) then begin
        ; Quietly return from errors so we don't crash IDL in the draw loop.
        catch, /cancel
        return
    endif

    ; Don't do extra work if we are in the lighting or selection pass.
    oDest->GetProperty, IS_BANDING=isBanding, $
        IS_LIGHTING=isLighting, IS_SELECTING=isSelecting

    if (~isLighting && ~isSelecting && ~isBanding) then begin
      ; If axis tick length is < 0.25 then assume we want "fixed" width
      ; tick marks that do not stretch with the plot.
      ; Otherwise, assume tick lengths are relative to the plot width.
      if (self._ticklen lt 0.25) then begin
        oWorld = Obj_Valid(oLayer) ? oLayer->GetWorld() : Obj_New()
        if (Obj_Valid(self.parent) && Obj_Valid(oWorld)) then begin
            matrix = self.parent->GetCTM(TOP=oWorld)
            xpixel = Sqrt(Total(matrix[0,0:2]^2))
            ypixel = Sqrt(Total(matrix[1,0:2]^2))
            zpixel = Sqrt(Total(matrix[2,0:2]^2))
            if (xpixel eq 0) then xpixel = 1
            if (ypixel eq 0) then ypixel = 1
            if (zpixel eq 0) then zpixel = xpixel < ypixel
            oDest->GetProperty, DIMENSIONS=dim, RESOLUTION=res
            ; The factor out front was empirically determined.
            factor = 15d/(MIN(res)*MIN(dim))
            self._oAxis->GetProperty, RANGE=range, DIRECTION=direction
            case (direction) of
            0: factor /= ypixel
            1: factor /= xpixel
            2: factor /= xpixel
            endcase
            ticklen = factor*self._ticklen;*(range[1]-range[0])
            self._oAxis->SetProperty, TICKLEN=ticklen
        endif
      endif
    endif

    self->IDLgrModel::Draw, oDest, oLayer
    void = CHECK_MATH()  ; swallow underflow errors
end


;----------------------------------------------------------------------------
;+
; IDLitVisAxis__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisAxis object.
;
;-
pro IDLitVisAxis__Define

    compile_opt idl2, hidden

    struct = { IDLitVisAxis,           $
        inherits IDLitVisualization, $
        _normLocation: [0d, 0d, 0d], $
        _dataPosition: 0b, $
        _majorminor: 0b, $
        _ticklen: 0d, $
        _textpos: 0, $
        _tickdir: 0, $
        _tickDefinedFormat: 0L, $
        _lastTickFormat: '', $
        _lastTickStrings:PTR_NEW(), $
        _oAxis: OBJ_NEW(),           $
        _oAxisShadow: OBJ_NEW(),     $
        _oMySelectionVisual: OBJ_NEW(), $
        _oTitle: OBJ_NEW(),          $
        _oRevTitle: OBJ_NEW(),       $
        _oFont: OBJ_NEW(), $
        _pTicktext: Ptr_New(), $
        _oUserText: Obj_New() $   ; not ours, do not destroy in Cleanup
    }
end
