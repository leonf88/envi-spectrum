; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisdataaxes__define.pro#2 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisDataAxes
;
; PURPOSE:
;   The IDLitVisDataAxes class is a collection of axes
;   that as a group serve as a visual representation for a data space.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   _IDLitVisualization
;
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataAxes::Init
;
; PURPOSE:
;   The IDLitVisDataAxes::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   oDataAxes = OBJ_NEW('IDLitVisDataAxes')
;
;   or
;
;   Obj->[IDLitVisDataAxes::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-
function IDLitVisDataAxes::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    ; By default, the Data Axes will not impact axes or view vol.
    if (self->IDLitVisualization::Init( $
        NAME='IDLitVisDataAxes', $
        ICON='axis', $
        IMPACTS_RANGE=0, $
        /PROPERTY_INTERSECTION, $
        /REGISTER_PROPERTIES, $
        SELECT_TARGET=0, $ ; no need to interactively select this container
        TYPE="IDLAXES", $
        _EXTRA=_extra) ne 1) then $
        RETURN, 0

    ; Set my defaults.
    self.style = 0
    self.stylePrevious = 0
    self.xRange = [0.0, 0.0]
    self.yRange = [0.0, 0.0]
    self.zRange = [0.0, 0.0]

    ; Request no (additional) axes.
    self->SetAxesRequest, 0, /ALWAYS

    ; Register properties and set property attributes
    self->IDLitVisDataAxes::_RegisterProperties

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisDataAxes::SetProperty, _EXTRA=_extra

    RETURN, 1
end


;----------------------------------------------------------------------------
;pro IDLitVisDataAxes::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclasses.
;    self->IDLitVisualization::Cleanup
;end

;----------------------------------------------------------------------------
pro IDLitVisDataAxes::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Add new registered properties.
        self->IDLitComponent::RegisterProperty, 'AXIS_STYLE', $
            NAME='Axis Style', $
            ENUMLIST=['None', 'At Dataspace Minimum', 'Box Axes', 'Crosshairs'], $
            DESCRIPTION='Axis style'
    endif

    if (~registerAll && updateFromVersion lt 640) then begin
         ; No longer expose these on the Axes prop sheet.
        self->SetPropertyAttribute, ['X_LOG', 'Y_LOG', 'Z_LOG'], /HIDE
    endif

end

;----------------------------------------------------------------------------
; IDLitVisDataAxes::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisDataAxes::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisDataAxes::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes

        self->GetProperty, TYPE=oldTypes
        iValid = WHERE(oldTypes ne '', nValid)
        newTypes = (nValid ? ["IDLAXES", oldTypes[iValid]] : "IDLAXES")
        self->SetProperty, TYPE=newTypes
    endif
end

;----------------------------------------------------------------------------
pro IDLitVisDataAxes::Add, oTargets, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitVisualization::Add, oTargets, _EXTRA=_extra

    ; If we add an axis recompute the tick length
    for i=0, n_elements(oTargets)-1 do begin
        if (OBJ_ISA(oTargets[i], "IDLitVisAxis")) then $
            oTargets[i]->UpdateAxisTicklen
    endfor


end


;----------------------------------------------------------------------------
;+
; IDLitVisDataAxes::_UpdateAxesRanges
;
; Purpose:
;   Internal routine to configure the axes.
;-
pro IDLitVisDataAxes::_UpdateAxesRanges, XRange, YRange, ZRange

    compile_opt idl2, hidden

    if (N_ELEMENTS(XRange) eq 0) then begin
         XRange = self.xRange
         YRange = self.yRange
         ZRange = self.zRange
    endif

    ; Keep track of reversal change.
    xWasRev = self._xReverse
    yWasRev = self._yReverse
    zWasRev = self._zReverse

    ; Determine whether any axis ranges are reversed.
    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then $
        oDataSpace->_GetXYZAxisReverseFlags, xReverse, yReverse, zReverse $
    else begin
        xReverse = 0b
        yReverse = 0b
        zReverse = 0b
    endelse

    self._xReverse = xReverse
    self._yReverse = yReverse
    self._zReverse = zReverse

    oAxes = self->Get(/ALL, ISA='IDLitVisAxis', COUNT=count)

    for i=0, count-1 do begin
        oAxes[i]->GetProperty, DIRECTION=direction, $
            TEXTBASE=textbase, TEXTUPDIR=textupdir, $
            NOTEXT=notext
        case direction of
            0: begin
                range = xRange
                textbaseline = (xReverse ? [-1,0,0] : [1,0,0])
                textupdir = (yReverse ? [0,-1,0] : [0,1,0])
            end

            1: begin
                range = yRange
                textbaseline = (xReverse ? [-1,0,0] : [1,0,0])
                textupdir = (yReverse ? [0,-1,0] : [0,1,0])
            end

            2: begin
                range = zRange
                textbaseline = (xReverse ? [-1,0,0] : [1,0,0])
                textupdir = (zReverse ? [0,0,-1] : [0,0,1])
            end
        endcase
        oAxes[i]->SetProperty, RANGE=range, $
            TEXTBASELINE=textbaseline, TEXTUPDIR=textupdir, $
            NOTEXT=notext
        oAxes[i]->UpdateAxisLocation
        oAxes[i]->UpdateAxisTicklen, XRange, YRange, ZRange
    endfor

    ; Keep our selection box in sync with our new range, just in case
    ; we are currently selected.
    self->UpdateSelectionVisual

end


;----------------------------------------------------------------------------
;+
; IDLitVisDataAxes::_GetAxis
;
; Purpose:
;   Find an axis in the group matching the specified direction
;   and normLocation.  If no axis is found, create an axis with
;   the specified properties and add it to the container.
;
;   Return the axis with the specified properties.
;-
function IDLitVisDataAxes::_GetAxis, $
    CROSSHAIR=crosshair, $
    DIRECTION=direction, $
    NORM_LOCATION=normLocation

    compile_opt idl2, hidden

    if N_ELEMENTS(direction) eq 0 then direction = 0
    if N_ELEMENTS(normLocation) eq 0 then normLocation = [0d, 0d, 0d]

    oAxes = self->Get(/ALL, ISA='IDLitVisAxis', COUNT=count)

    oAxis = OBJ_NEW()
    eps = 0.01

    for i=0, count-1 do begin

        oAxes[i]->GetProperty, $
            DIRECTION=currentDirection, $
            NORM_LOCATION=currentNormLocation
        if (currentDirection ne direction) then $
            continue

        diff = ABS(currentNormLocation - normLocation)

        case direction of
            0: if ((diff[1] lt eps) && (diff[2] lt eps)) then $
                    oAxis = oAxes[i]
            1: if ((diff[0] lt eps) && (diff[2] lt eps)) then $
                    oAxis = oAxes[i]
            2: if ((diff[0] lt eps) && (diff[1] lt eps)) then $
                    oAxis = oAxes[i]
        endcase

        if (OBJ_VALID(oAxis)) then $
            break

    endfor

    if (~OBJ_VALID(oAxis)) then begin
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            oAxisDesc = oTool->GetVisualization("AXIS")
            oAxis = oAxisDesc->GetObjectInstance()
        endif else $
            oAxis = OBJ_NEW('IDLitVisAxis')

        if (~OBJ_VALID(oAxis)) then $
            return, OBJ_NEW()

        ; See if user has a name preference.
        oAxis->GetProperty, NAME=basename
        name = (basename ? basename : 'Axis') + ' ' + STRTRIM(self._index,2)

        oAxis->SetProperty, $
            /HIDE, $    ; hide until scaled and translated
            /EXACT, $
            NAME=name, $
            IDENTIFIER='Axis' + STRTRIM(self._index,2), $
            NORM_LOCATION=normLocation, $
            TOOL=oTool

        self->Add, oAxis, /AGGREGATE

        self._index++
    endif

    oAxis->SetProperty, $
        DIRECTION=direction

    if KEYWORD_SET(crosshair) then begin
        ; Set crosshair defaults.
        oAxis->SetProperty, NOTEXT=0, TEXTPOS=0, TICKDIR=2
    endif else begin
        ; Reset defaults.
        oAxis->SetProperty, TICKDIR=0
    endelse

    return, oAxis
end
;----------------------------------------------------------------------------
;+
; IDLitVisDataAxes::ConfigAxes
;
; Purpose:
;   Internal routine to configure the axes.
;-
pro IDLitVisDataAxes::_ConfigAxes

    compile_opt idl2, hidden

    oAxes = self->Get(/ALL, ISA='IDLitVisAxis', COUNT=count)

    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (~OBJ_VALID(oDataSpace)) then $
        return
    threeD = oDataSpace->_IDLitVisualization::Is3D()

    ; Hide axes
    for i=0, count-1 do begin
        oAxes[i]->GetProperty, NORM_LOCATION=normLocation, DIRECTION=direction
        ; If we are very close to either end (or in the middle if
        ; the previous style was crosshair), then we should be
        ; considered a "default" axis.  default axes are used to
        ; implement an axes style (box, dataspace minimum) and may
        ; be hidden.  axes at non-default locations are not hidden
        ; when switching styles.
        eps = 0.01
        if self.stylePrevious eq 3 then begin

            closeToMiddle = (ABS(0.5 - normLocation) lt eps)

            if threeD then begin
                case direction of
                    0: defaultLocation = closeToMiddle[1] && $
                        closeToMiddle[2]  ; Y & Z
                    1: defaultLocation = closeToMiddle[0] && $
                        closeToMiddle[2]  ; X & Z
                    2: defaultLocation = closeToMiddle[0] && $
                        closeToMiddle[1]  ; X & Y
                endcase
            endif else begin
                case direction of
                    0: defaultLocation = closeToMiddle[1]  ; Y
                    1: defaultLocation = closeToMiddle[0]  ; X
                    else:
                endcase
            endelse
        endif else begin
            closeToEnd = (ABS(normLocation) lt eps) or $
                (ABS(1 - normLocation) lt eps)
            case direction of
                0: defaultLocation = closeToEnd[1] && closeToEnd[2]  ; Y & Z
                1: defaultLocation = closeToEnd[0] && closeToEnd[2]  ; X & Z
                2: defaultLocation = closeToEnd[0] && closeToEnd[1]  ; X & Y
            endcase
        endelse
        if defaultLocation then $
            oAxes[i]->SetProperty, HIDE=1, PRIVATE=1
    endfor

    ; Handle supported axis styles
    case self.style of
        0: begin ; ignore call from init
        end
        1: begin
            ; Axes at origin only
            ;
            ; Axis assignments:
            ; 0 X direction
            ; 1 Y direction
            ; 2 Z direction
            ; 3-11 unused (hidden)
            ; Set Ranges

            oAxisX = self->_GetAxis( $
                    DIRECTION=0, $
                    NORM_LOCATION=[0d,0d,0d])
            oAxisX->SetProperty, $
                    NOTEXT=0, TICKDIR=0, TEXTPOS=0
            oAxesConfigured = [oAxisX]

            oAxisY = self->_GetAxis( $
                    DIRECTION=1, $
                    NORM_LOCATION=[0d,0d,0d])
            oAxisY->SetProperty, $
                    NOTEXT=0, TICKDIR=0, TEXTPOS=0
            oAxesConfigured = [oAxesConfigured, oAxisY]

            if (threeD) then begin
                oAxisZ = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[0d,0d,0d])
                oAxisZ->SetProperty, $
                    NOTEXT=0, TICKDIR=0, TEXTPOS=0
                oAxesConfigured = [oAxesConfigured, oAxisZ]
            endif

            ; After direction of axes is set we can set the ranges
            self->_UpdateAxesRanges

        end

        2: begin
            ; Box axes
            ;
            ; Axis assignments:
            ;     X Direction
            ;        0 - Y low Z low
            ;        1 - Y high Z low
            ;        2 - Y low Z high
            ;        3 - Y high Z high
            ;     Y Direction
            ;        4 - X low Z low
            ;        5 - X high Z low
            ;        6 - X low Z high
            ;        7 - X high Z high
            ;     Z Direction
            ;        8 - X low Y low
            ;        9 - X high Y low
            ;        10 - X low Y high
            ;        11 - X high Y high


            ; First add a single X, Y, Z axis so that the order in the
            ; container matches the AXIS_STYLE=1 order.

            oAxisX1 = self->_GetAxis( $
                DIRECTION=0, $
                NORM_LOCATION=[0d,0d,0d])   ; YLO, ZLO
            oAxesConfigured = [oAxisX1]

            ; Y axes.
            oAxisY1 = self->_GetAxis( $
                DIRECTION=1, $
                NORM_LOCATION=[0d,0d,0d])   ; XLO, ZLO
            oAxesConfigured = [oAxesConfigured, oAxisY1]

            if threeD then begin
                ; Z axes.
                oAxisZ1 = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[0d,0d,0d])   ; XLO, /YLO
                oAxisZ1->SetProperty, $
                    NOTEXT=0, TICKDIR=0, TEXTPOS=0
                oAxesConfigured = [oAxesConfigured, oAxisZ1]
            endif

            ; Now add the next set of X, Y, Z axes.
            oAxisX2 = self->_GetAxis( $
                DIRECTION=0, $
                NORM_LOCATION=[0d,1d,0d])   ; YHI, ZLO
            oAxisX2->SetProperty, $
                TICKDIR=1, TEXTPOS=1, /NOTEXT
            oAxesConfigured = [oAxesConfigured, oAxisX2]

            oAxisY2 = self->_GetAxis( $
                DIRECTION=1, $
                NORM_LOCATION=[1d,0d,0d])   ; XHI, ZL
            oAxisY2->SetProperty, $
                TICKDIR=1, TEXTPOS=1, /NOTEXT
            oAxesConfigured = [oAxesConfigured, oAxisY2]

            if threeD then begin
                oAxisZ2 = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[1d,0d,0d])   ; XHI, /YLO
                oAxisZ2->SetProperty, $
                    TICKDIR=1, TEXTPOS=1, /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisZ2]
            endif

            ; Finally, if 3D, add the rest of the box axes,
            ; making sure to do them in groups of X,Y,Z.
            if threeD then begin
                oAxisX3 = self->_GetAxis( $
                    DIRECTION=0, $
                    NORM_LOCATION=[0d,0d,1d])   ; YLO, /ZHI
                oAxisX3->SetProperty, $
                    /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisX3]

                oAxisY3 = self->_GetAxis( $
                    DIRECTION=1, $
                    NORM_LOCATION=[0d,0d,1d])   ; XLO, ZHI
                oAxisY3->SetProperty, $
                    /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisY3]

                oAxisZ3 = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[0d,1d,0d])   ; XLO, /YHI
                oAxisZ3->SetProperty, $
                        /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisZ3]

                oAxisX4 = self->_GetAxis( $
                    DIRECTION=0, $
                    NORM_LOCATION=[0d,1d,1d])   ; YHI, ZHI
                oAxisX4->SetProperty, $
                    TICKDIR=1, TEXTPOS=1, /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisX4]

                oAxisY4 = self->_GetAxis( $
                    DIRECTION=1, $
                    NORM_LOCATION=[1d,0d,1d])   ;XHI, ZHI
                oAxisY4->SetProperty, $
                    TICKDIR=1, TEXTPOS=1, /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisY4]

                oAxisZ4 = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[1d,1d,0d])   ;XHI, YHI
                oAxisZ4->SetProperty, $
                    TICKDIR=1, TEXTPOS=1, /NOTEXT
                oAxesConfigured = [oAxesConfigured, oAxisZ4]

            endif

            ; After direction of axes is set we can set the ranges
            self->_UpdateAxesRanges

        end
        3: begin
            ; Crosshairs
            ;
            ; Axis assignments:
            ; 0 X direction
            ; 1 Y direction
            ; 2 Z direction
            ; Set Ranges
            z = threeD ? 0.5 : 0

            oAxisX = self->_GetAxis( $
                DIRECTION=0, $
                NORM_LOCATION=[0d, 0.5d, z], /CROSSHAIR)
            oAxesConfigured = [oAxisX]

            oAxisY = self->_GetAxis( $
                DIRECTION=1, $
                NORM_LOCATION=[0.5d, 0d, z], /CROSSHAIR)
            oAxesConfigured = [oAxesConfigured, oAxisY]

            if (threeD) then begin
                oAxisZ = self->_GetAxis( $
                    DIRECTION=2, $
                    NORM_LOCATION=[0.5d, 0.5d, 0d], /CROSSHAIR)
                oAxesConfigured = [oAxesConfigured, oAxisZ]
            endif

            ; After direction of axes is set we can set the ranges
            self->_UpdateAxesRanges

        end

        else: begin
            MESSAGE, IDLitLangCatQuery('Message:Framework:InvalidStyle')
        end
    endcase

    n = N_ELEMENTS(oAxesConfigured)
    if (n gt 0) then begin
        for i=0,n-1 do $
            oAxesConfigured[i]->SetProperty, HIDE=0, PRIVATE=0

        ; Notify our observers to update their tree view, since we may have
        ; marked items as private=0.
        self->DoOnNotify, self->GetFullIdentifier(), 'UPDATEITEM', ''

        ; Save style for comparison on next style change
        self.stylePrevious = self.style
    endif

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataAxes::GetProperty
;
; PURPOSE:
;      The IDLitVisDataAxes::GetProperty procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataAxes::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisDataAxes::Init followed by the word "Get"
;      can be retrieved using IDLitVisDataAxes::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisDataAxes::GetProperty, $
    AXIS_STYLE=axisStyle, $
    XRANGE=xrange, $
    YRANGE=yrange, $
    ZRANGE=zrange, $
    STYLE=style, $   ; renamed in IDL72 to AXIS_STYLE
    XLOG=xLog, $
    YLOG=yLog, $
    ZLOG=zLog, $
    X_LOG=x_Log, $ ; renamed in IDL64, keep for backwards compat
    Y_LOG=y_Log, $ ; renamed in IDL64, keep for backwards compat
    Z_LOG=z_Log, $ ; renamed in IDL64, keep for backwards compat
    XREVERSE=xReverse, $
    YREVERSE=yReverse, $
    ZREVERSE=zReverse, $
    XCOLOR=xColor, YCOLOR=yColor, ZCOLOR=zColor, $
    XGRIDSTYLE=xGridStyle, YGRIDSTYLE=yGridStyle, ZGRIDSTYLE=zGridStyle, $
    XMAJOR=xMajor, YMAJOR=yMajor, ZMAJOR=zMajor, $
    XMINOR=xMinor, YMINOR=yMinor, ZMINOR=zMinor, $
    XTEXT_COLOR=xTextColor, YTEXT_COLOR=yTextColor, ZTEXT_COLOR=zTextColor, $
    XTEXTPOS=xTextPos, YTEXTPOS=yTextPos, ZTEXTPOS=zTextPos, $
    XTHICK=xThick, YTHICK=yThick, ZTHICK=zThick, $
    XTICKDIR=xTickdir, YTICKDIR=yTickdir, ZTICKDIR=zTickdir, $
    XTICKFONT_INDEX=xTickFontIndex, YTICKFONT_INDEX=yTickFontIndex, ZTICKFONT_INDEX=zTickFontIndex, $
    XTICKFONT_NAME=xTickFontName, YTICKFONT_NAME=yTickFontName, ZTICKFONT_NAME=zTickFontName, $
    XTICKFONT_SIZE=xTickFontSize, YTICKFONT_SIZE=yTickFontSize, ZTICKFONT_SIZE=zTickFontSize, $
    XTICKFONT_STYLE=xTickFontStyle, YTICKFONT_STYLE=yTickFontStyle, ZTICKFONT_STYLE=zTickFontStyle, $
    XTICKFORMAT=xTickFormat, YTICKFORMAT=yTickFormat, ZTICKFORMAT=zTickFormat, $
    XTICKINTERVAL=xTickInterval, YTICKINTERVAL=yTickInterval, ZTICKINTERVAL=zTickInterval, $
    XTICKLAYOUT=xTickLayout, YTICKLAYOUT=yTickLayout, ZTICKLAYOUT=zTickLayout, $
    XTICKLEN=xTickLen, YTICKLEN=yTickLen, ZTICKLEN=zTickLen, $
    XSUBTICKLEN=xSubTickLen, YSUBTICKLEN=ySubTickLen, ZSUBTICKLEN=zSubTickLen, $
    XTICKNAME=xTickName, YTICKNAME=yTickName, ZTICKNAME=zTickName, $
    XTICKUNITS=xTickUnits, YTICKUNITS=yTickUnits, ZTICKUNITS=zTickUnits, $
    XTICKVALUES=xTickValues, YTICKVALUES=yTickValues, ZTICKVALUES=zTickValues, $
    XTITLE=xTitle, YTITLE=yTitle, ZTITLE=zTitle, $
    XTRANSPARENCY=xTransparency, YTRANSPARENCY=yTransparency, $
    ZTRANSPARENCY=zTransparency, $ 
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(xrange) then $
        xrange = self.xRange

    if ARG_PRESENT(yrange) then $
        yrange = self.yRange

    if ARG_PRESENT(zrange) then $
        zrange = self.zRange

    if ARG_PRESENT(axisStyle) then $
        axisStyle = self.style
    if ARG_PRESENT(style) then $
        style = self.style

    if ARG_PRESENT(xReverse) then $
        xReverse = self._xReverse

    if ARG_PRESENT(yReverse) then $
        yReverse = self._yReverse

    if ARG_PRESENT(zReverse) then $
        zReverse = self._zReverse

    ; Ask the dataspace
    if (Arg_Present(xLog) || Arg_Present(yLog) || Arg_Present(zLog) || $
        Arg_Present(x_Log) || Arg_Present(y_Log) || Arg_Present(z_Log)) then begin
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->GetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
            x_Log = xLog
            y_Log = yLog
            z_Log = zLog
        endif else begin
            xLog=0
            yLog=0
            zLog=0
            x_Log=0
            y_Log=0
            z_Log=0
        endelse
    endif

    ; Get command line property settings from appropriate axes
    hasXkeywords = ARG_PRESENT(xColor) || $
      ARG_PRESENT(xGridStyle) || ARG_PRESENT(xMajor) || $
      ARG_PRESENT(xMinor) || ARG_PRESENT(xTextColor) || ARG_PRESENT(xTextPos) || $
      ARG_PRESENT(xTickdir) || ARG_PRESENT(xTickFontIndex) || $
      ARG_PRESENT(xTickFontName) || $
      ARG_PRESENT(xTickFontSize) || ARG_PRESENT(xTickFontStyle) || $
      ARG_PRESENT(xTickFormat) || ARG_PRESENT(xThick) || $
      ARG_PRESENT(xTickInterval) || ARG_PRESENT(xTickLayout) ||$
      ARG_PRESENT(xTickLen) || ARG_PRESENT(xSubTickLen) || $
      ARG_PRESENT(xTickName) || ARG_PRESENT(xTickUnits) || $
      ARG_PRESENT(xTickValues) || ARG_PRESENT(xTitle) || ARG_PRESENT(xTransparency)
    hasYkeywords = ARG_PRESENT(yColor) || $
      ARG_PRESENT(yGridStyle) || ARG_PRESENT(yMajor) || $
      ARG_PRESENT(yMinor) || ARG_PRESENT(yTextColor) || ARG_PRESENT(yTextPos) || $
      ARG_PRESENT(yTickdir) || ARG_PRESENT(yTickFontIndex) || $
      ARG_PRESENT(yTickFontName) || $
      ARG_PRESENT(yTickFontSize) || ARG_PRESENT(yTickFontStyle) || $
      ARG_PRESENT(yTickFormat) || ARG_PRESENT(yThick) || $
      ARG_PRESENT(yTickInterval) || ARG_PRESENT(yTickLayout) ||$
      ARG_PRESENT(yTickLen) || ARG_PRESENT(ySubTickLen) || $
      ARG_PRESENT(yTickName) || ARG_PRESENT(yTickUnits) || $
      ARG_PRESENT(yTickValues) || ARG_PRESENT(yTitle) || ARG_PRESENT(yTransparency)
    hasZkeywords = ARG_PRESENT(zColor) || $
      ARG_PRESENT(zGridStyle) || ARG_PRESENT(zMajor) || $
      ARG_PRESENT(zMinor) || ARG_PRESENT(zTextColor) || ARG_PRESENT(zTextPos) || $
      ARG_PRESENT(zTickdir) || ARG_PRESENT(zTickFontIndex) || $
      ARG_PRESENT(zTickFontSize) || ARG_PRESENT(zTickFontStyle) || $
      ARG_PRESENT(zTickFontName) || $
      ARG_PRESENT(zTickFormat) || ARG_PRESENT(zThick) || $
      ARG_PRESENT(zTickInterval) || ARG_PRESENT(zTickLayout) ||$
      ARG_PRESENT(zTickLen) || ARG_PRESENT(zSubTickLen) || $
      ARG_PRESENT(zTickName) || ARG_PRESENT(zTickUnits) || $
      ARG_PRESENT(zTickValues) || ARG_PRESENT(zTitle) || ARG_PRESENT(zTransparency)

    if (hasXkeywords || hasYkeywords || hasZkeywords) then begin
        oAxes = self->Get(/ALL, ISA='IDLitVisAxis', COUNT=count)
        xfound = 0
        yfound = 0
        zfound = 0
        for i=0, count-1 do begin
            ; When looking for properties from a particular axis,
            ; stop once the first axis in the specified direction
            ; is found
            oAxes[i]->GetProperty, DIRECTION=direction
            case direction of
            0: if (hasXkeywords && xfound eq 0) then begin
              xfound = 1 ; Only retrieve props from the first axis found
              oAxes[i]->GetProperty, COLOR=xColor, GRIDSTYLE=xGridStyle, $
                MAJOR=xMajor, MINOR=xMinor, $
                TEXT_COLOR=xTextColor, TEXTPOS=xTextPos, $
                FONT_INDEX=xTickFontIndex, FONT_SIZE=xTickFontSize, $
                FONT_NAME=xTickFontName, $
                FONT_STYLE=xTickFontStyle, TICKFORMAT=xTickFormat, $
                TICKINTERVAL=xTickInterval, TICKLAYOUT=xTickLayout, $
                TICKDIR=xTickdir, TICKLEN=xTickLen, SUBTICKLEN=xSubTickLen, $
                TICKNAME=xTickName, TICK_UNITS=xTickUnits, $
                TICKVALUES=xTickValues, AXIS_TITLE=xTitle, THICK=xThick, $
                TRANSPARENCY=xTransparency
              endif
            1: if (hasYkeywords && yfound eq 0) then begin
              yfound = 1 ; Only retrieve props from the first axis found
              oAxes[i]->GetProperty, COLOR=yColor, GRIDSTYLE=yGridStyle, $
                MAJOR=yMajor, MINOR=yMinor, $
                TEXT_COLOR=yTextColor, TEXTPOS=yTextPos, $
                FONT_INDEX=yTickFontIndex, FONT_SIZE=yTickFontSize, $
                FONT_NAME=yTickFontName, $
                FONT_STYLE=yTickFontStyle, TICKFORMAT=yTickFormat, $
                TICKINTERVAL=yTickInterval, TICKLAYOUT=yTickLayout, $
                TICKDIR=yTickdir, TICKLEN=yTickLen, SUBTICKLEN=ySubTickLen, $
                TICKNAME=yTickName, TICK_UNITS=yTickUnits, $
                TICKVALUES=yTickValues, AXIS_TITLE=yTitle, THICK=yThick, $
                TRANSPARENCY=yTransparency
              endif
            2: if (hasZkeywords && zfound eq 0) then begin
              zfound = 1 ; Only retrieve props from the first axis found
              oAxes[i]->GetProperty, COLOR=zColor, GRIDSTYLE=zGridStyle, $
                MAJOR=zMajor, MINOR=zMinor, $
                TEXT_COLOR=zTextColor, TEXTPOS=zTextPos, $
                FONT_INDEX=zTickFontIndex, FONT_SIZE=zTickFontSize, $
                FONT_NAME=zTickFontName, $
                FONT_STYLE=zTickFontStyle, TICKFORMAT=zTickFormat, $
                TICKINTERVAL=zTickInterval, TICKLAYOUT=zTickLayout, $
                TICKDIR=zTickdir, TICKLEN=zTickLen, SUBTICKLEN=zSubTickLen, $
                TICKNAME=zTickName, TICK_UNITS=zTickUnits, $
                TICKVALUES=zTickValues, AXIS_TITLE=zTitle, THICK=zThick, $
                TRANSPARENCY=zTransparency
              endif
            endcase
        endfor

    endif

    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra


end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataAxes::SetProperty
;
; PURPOSE:
;      The IDLitVisDataAxes::SetProperty procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataAxes::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisDataAxes::Init followed by the word "Set"
;      can be set using IDLitVisDataAxes::SetProperty.
;-
pro IDLitVisDataAxes::SetProperty, $
    AXIS_STYLE=axisStyle, $
    LOCATION=swallow, $  ; do not want to pass to the contained axes
    THICK=!NULL, $
    TRANSPARENCY=swallow2, $
    XRANGE=xrange, $
    YRANGE=yrange, $
    ZRANGE=zrange, $
    XLOG=xLog, $
    YLOG=yLog, $
    ZLOG=zLog, $
    X_LOG=x_Log, $ ; renamed in IDL64, keep for backwards compat
    Y_LOG=y_Log, $ ; renamed in IDL64, keep for backwards compat
    Z_LOG=z_Log, $ ; renamed in IDL64, keep for backwards compat
    XCOLOR=xColor, YCOLOR=yColor, ZCOLOR=zColor, $
    XGRIDSTYLE=xGridStyle, YGRIDSTYLE=yGridStyle, ZGRIDSTYLE=zGridStyle, $
    XMAJOR=xMajor, YMAJOR=yMajor, ZMAJOR=zMajor, $
    XMINOR=xMinor, YMINOR=yMinor, ZMINOR=zMinor, $
    XTEXT_COLOR=xTextColor, YTEXT_COLOR=yTextColor, ZTEXT_COLOR=zTextColor, $
    XTEXTPOS=xTextPos, YTEXTPOS=yTextPos, ZTEXTPOS=zTextPos, $
    XTHICK=xThick, YTHICK=yThick, ZTHICK=zThick, $
    XTICKDIR=xTickdir, YTICKDIR=yTickdir, ZTICKDIR=zTickdir, $
    XTICKFONT_INDEX=xTickFontIndex, YTICKFONT_INDEX=yTickFontIndex, ZTICKFONT_INDEX=zTickFontIndex, $
    XTICKFONT_NAME=xTickFontName, YTICKFONT_NAME=yTickFontName, ZTICKFONT_NAME=zTickFontName, $
    XTICKFONT_SIZE=xTickFontSize, YTICKFONT_SIZE=yTickFontSize, ZTICKFONT_SIZE=zTickFontSize, $
    XTICKFONT_STYLE=xTickFontStyle, YTICKFONT_STYLE=yTickFontStyle, ZTICKFONT_STYLE=zTickFontStyle, $
    XTICKFORMAT=xTickFormat, YTICKFORMAT=yTickFormat, ZTICKFORMAT=zTickFormat, $
    XTICKINTERVAL=xTickInterval, YTICKINTERVAL=yTickInterval, ZTICKINTERVAL=zTickInterval, $
    XTICKLAYOUT=xTickLayout, YTICKLAYOUT=yTickLayout, ZTICKLAYOUT=zTickLayout, $
    XTICKLEN=xTickLen, YTICKLEN=yTickLen, ZTICKLEN=zTickLen, $
    XSUBTICKLEN=xSubTickLen, YSUBTICKLEN=ySubTickLen, ZSUBTICKLEN=zSubTickLen, $
    XTICKNAME=xTickName, YTICKNAME=yTickName, ZTICKNAME=zTickName, $
    XTICKUNITS=xTickUnits, YTICKUNITS=yTickUnits, ZTICKUNITS=zTickUnits, $
    XTICKVALUES=xTickValues, YTICKVALUES=yTickValues, ZTICKVALUES=zTickValues, $
    XTITLE=xTitle, YTITLE=yTitle, ZTITLE=zTitle, $
    XTRANSPARENCY=xTransparency, YTRANSPARENCY=yTransparency, $
    ZTRANSPARENCY=zTransparency, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

; Range keywords are read-only and should only get changed in OnDataRangeChange
;    rangeChange = 0
;    if N_ELEMENTS(xrange) ne 0 then begin
;        self.xRange = xrange
;        rangeChange = 1
;    endif
;    if N_ELEMENTS(yrange) ne 0 then begin
;        self.yRange = yrange
;        rangeChange = 1
;    endif
;    if N_ELEMENTS(zrange) ne 0 then begin
;        self.zRange = zrange
;        rangeChange = 1
;    endif

    if (N_ELEMENTS(axisStyle) ne 0) then begin
        self.style = axisStyle
        self->_ConfigAxes   ; change the style
    endif

    ; pass command line property settings on to appropriate axes
    hasXkeywords = N_ELEMENTS(xColor) || $
      N_ELEMENTS(xGridStyle) || N_ELEMENTS(xMajor) || $
      N_ELEMENTS(xMinor) || N_ELEMENTS(xTextColor) || N_ELEMENTS(xTextPos) || $
      N_ELEMENTS(xTickdir) || N_ELEMENTS(xTickFontIndex) || $
      N_ELEMENTS(xTickFontName) || $
      N_ELEMENTS(xTickFontSize) || N_ELEMENTS(xTickFontStyle) || $
      N_ELEMENTS(xTickFormat) || N_ELEMENTS(xThick) || $
      N_ELEMENTS(xTickInterval) || N_ELEMENTS(xTickLayout) ||$
      N_ELEMENTS(xTickLen) || N_ELEMENTS(xSubTickLen) || $
      N_ELEMENTS(xTickName) || N_ELEMENTS(xTickUnits) || $
      N_ELEMENTS(xTickValues) || N_ELEMENTS(xTitle) || N_ELEMENTS(xTransparency)
    hasYkeywords = N_ELEMENTS(yColor) || $
      N_ELEMENTS(yGridStyle) || N_ELEMENTS(yMajor) || $
      N_ELEMENTS(yMinor) || N_ELEMENTS(yTextColor) || N_ELEMENTS(yTextPos) || $
      N_ELEMENTS(yTickdir) || N_ELEMENTS(yTickFontIndex) || $
      N_ELEMENTS(yTickFontName) || $
      N_ELEMENTS(yTickFontSize) || N_ELEMENTS(yTickFontStyle) || $
      N_ELEMENTS(yTickFormat) || N_ELEMENTS(yThick) || $
      N_ELEMENTS(yTickInterval) || N_ELEMENTS(yTickLayout) ||$
      N_ELEMENTS(yTickLen) || N_ELEMENTS(ySubTickLen) || $
      N_ELEMENTS(yTickName) || N_ELEMENTS(yTickUnits) || $
      N_ELEMENTS(yTickValues) || N_ELEMENTS(yTitle) || N_ELEMENTS(yTransparency)
    hasZkeywords = N_ELEMENTS(zColor) || $
      N_ELEMENTS(zGridStyle) || N_ELEMENTS(zMajor) || $
      N_ELEMENTS(zMinor) || N_ELEMENTS(zTextColor) || N_ELEMENTS(zTextPos) || $
      N_ELEMENTS(zTickdir) || N_ELEMENTS(zTickFontIndex) || $
      N_ELEMENTS(zTickFontSize) || N_ELEMENTS(zTickFontStyle) || $
      N_ELEMENTS(zTickFontName) || $
      N_ELEMENTS(zTickFormat) || N_ELEMENTS(zThick) || $
      N_ELEMENTS(zTickInterval) || N_ELEMENTS(zTickLayout) ||$
      N_ELEMENTS(zTickLen) || N_ELEMENTS(zSubTickLen) || $
      N_ELEMENTS(zTickName) || N_ELEMENTS(zTickUnits) || $
      N_ELEMENTS(zTickValues) || N_ELEMENTS(zTitle) || N_ELEMENTS(zTransparency)

    if (hasXkeywords || hasYkeywords || hasZkeywords) then begin
        oAxes = self->Get(/ALL, ISA='IDLitVisAxis', COUNT=count)
        for i=0, count-1 do begin
            oAxes[i]->GetProperty, DIRECTION=direction
            case direction of
            0: if (hasXkeywords) then begin
              ; For box axis flip the directions for the other axis.
              if (N_ELEMENTS(xTickdir)) then $
                xTickdir1 = N_ELEMENTS(xTickdir1) ? ~xTickdir : xTickdir
              if (N_ELEMENTS(xTextPos)) then $
                xTextPos1 = N_ELEMENTS(xTextPos1) ? ~xTextPos : xTextPos
              oAxes[i]->SetProperty, COLOR=xColor, GRIDSTYLE=xGridStyle, $
                MAJOR=xMajor, MINOR=xMinor, $
                TEXT_COLOR=xTextColor, TEXTPOS=xTextPos1, $
                FONT_INDEX=xTickFontIndex, FONT_SIZE=xTickFontSize, $
                FONT_NAME=xTickFontName, $
                FONT_STYLE=xTickFontStyle, TICKFORMAT=xTickFormat, $
                TICKINTERVAL=xTickInterval, TICKLAYOUT=xTickLayout, $
                TICKDIR=xTickdir1, TICKLEN=xTickLen, SUBTICKLEN=xSubTickLen, $
                TICKNAME=xTickName, TICK_UNITS=xTickUnits, $
                TICKVALUES=xTickValues, AXIS_TITLE=xTitle, THICK=xThick, $
                TRANSPARENCY=xTransparency
              endif
            1: if (hasYkeywords) then begin
              ; For box axis flip the directions for the other axis.
              if (N_ELEMENTS(yTickdir)) then $
                yTickdir1 = N_ELEMENTS(yTickdir1) ? ~yTickdir : yTickdir
              if (N_ELEMENTS(yTextPos)) then $
                yTextPos1 = N_ELEMENTS(yTextPos1) ? ~yTextPos : yTextPos
              oAxes[i]->SetProperty, COLOR=yColor, GRIDSTYLE=yGridStyle, $
                MAJOR=yMajor, MINOR=yMinor, $
                TEXT_COLOR=yTextColor, TEXTPOS=yTextPos1, $
                FONT_INDEX=yTickFontIndex, FONT_SIZE=yTickFontSize, $
                FONT_NAME=yTickFontName, $
                FONT_STYLE=yTickFontStyle, TICKFORMAT=yTickFormat, $
                TICKINTERVAL=yTickInterval, TICKLAYOUT=yTickLayout, $
                TICKDIR=yTickdir1, TICKLEN=yTickLen, SUBTICKLEN=ySubTickLen, $
                TICKNAME=yTickName, TICK_UNITS=yTickUnits, $
                TICKVALUES=yTickValues, AXIS_TITLE=yTitle, THICK=yThick, $
                TRANSPARENCY=yTransparency
              endif
            2: if (hasZkeywords) then begin
              ; For box axis flip the directions for the other axis.
              if (N_ELEMENTS(zTickdir)) then $
                zTickdir1 = N_ELEMENTS(zTickdir1) ? ~zTickdir : zTickdir
              if (N_ELEMENTS(zTextPos)) then $
                zTextPos1 = N_ELEMENTS(zTextPos1) ? ~zTextPos : zTextPos
              oAxes[i]->SetProperty, COLOR=zColor, GRIDSTYLE=zGridStyle, $
                MAJOR=zMajor, MINOR=zMinor, $
                TEXT_COLOR=zTextColor, TEXTPOS=zTextPos, $
                FONT_INDEX=zTickFontIndex, FONT_SIZE=zTickFontSize, $
                FONT_NAME=zTickFontName, $
                FONT_STYLE=zTickFontStyle, TICKFORMAT=zTickFormat, $
                TICKINTERVAL=zTickInterval, TICKLAYOUT=zTickLayout, $
                TICKDIR=zTickdir, TICKLEN=zTickLen, SUBTICKLEN=zSubTickLen, $
                TICKNAME=zTickName, TICK_UNITS=zTickUnits, $
                TICKVALUES=zTickValues, AXIS_TITLE=zTitle, THICK=zThick, $
                TRANSPARENCY=zTransparency
              endif
            endcase
        endfor

    endif

    ; renamed in IDL64, keep for backwards compat
    if (N_Elements(x_Log)) then xLog = x_Log
    if (N_Elements(y_Log)) then yLog = y_Log
    if (N_Elements(z_Log)) then zLog = z_Log

    ; Tell the dataspace - it is in charge
    ; Do not set log on individual axes. IDLitVisAxis
    ; will set appropriately based on the dataspace setting
    if (N_Elements(xLog) || N_Elements(yLog) || N_Elements(zLog)) then begin
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace)) then begin
            oDataSpace->SetProperty, XLOG=xLog, YLOG=yLog, ZLOG=zLog
        endif
    endif

; Not needed: See note above about Range keywords.
;    if (rangeChange) then begin
;        self->_UpdateAxesRanges
;    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; IIDLitVisDataAxes Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataAxes::GetXYZRange
;
; Purpose:
;   Override the GetXYZRange to add some padding for the tick labels.
;-
function IDLitVisDataAxes::GetXYZRange, xRange, yRange, zRange, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

;    success = self->IDLgrModel::GetXYZRange(xRange, yRange, zRange, $
;        NO_TRANSFORM=noTransform)
;
;    if (success) then begin
;        dx = xRange[1] - xRange[0]
;        dy = yRange[1] - yRange[0]
;        dz = zRange[1] - zRange[0]
;        factor = 0.05
;        xRange = xRange + factor*dx*[-1,1]
;        yRange = yRange + factor*dy*[-1,1]
;        zRange = zRange + factor*dz*[-1,1]
;    endif

    xRange = self.xRange
    yRange = self.yRange
    zRange = self.zRange

    return, 1 - ARRAY_EQUAL([xRange[0], yRange[0], zRange[0]], $
        [xRange[1], yRange[1], zRange[1]])

end

;----------------------------------------------------------------------------
; IIDLDataRangeObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      _IDLitVisDataAxes::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data
;      range has changed.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataAxes::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new xrange, [ymin, ymax].
;      ZRange:    The new xrange, [zmin, zmax].
;-
pro IDLitVisDataAxes::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    self.xRange = XRange
    self.yRange = YRange
    changedTo3D = ((self.zRange[1]-self.zRange[0] eq 0.0d) && $
            (ZRange[1]-ZRange[0] gt 0.0d))
    self.zRange = ZRange

    if ((~self._initRangeChange) || $
        (changedTo3D)) then begin
        self->_ConfigAxes
        self._initRangeChange = 1
    endif else begin
        self->_UpdateAxesRanges, XRange, YRange, ZRange
    endelse

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataAxes__Define
;
; Purpose:
;   Defines the object structure for an IDLitVisDataAxes object.
;-
pro IDLitVisDataAxes__Define

    compile_opt idl2, hidden

    struct = { IDLitVisDataAxes, $
        inherits IDLitVisualization, $
        xRange: DBLARR(2), $
        yRange: DBLARR(2), $
        zRange: DBLARR(2), $
        _xReverse: 0b, $
        _yReverse: 0b, $
        _zReverse: 0b, $
        _index: 0L, $
        style: 0L, $
        stylePrevious: 0L, $
        _initRangeChange: 0b $
        }
end

