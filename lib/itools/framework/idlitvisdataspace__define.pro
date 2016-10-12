; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisdataspace__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisDataSpace
;
; PURPOSE:
;   The IDLitVisDataSpace class is a container for axes and visualizations
;   that share a common data space.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   _IDLitVisualization
;   IDLitVisIDataSpace
;
;-



;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::Init
;
; PURPOSE:
;   The IDLitVisDataSpace::Init function method initializes this
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
;   oDataSpace = OBJ_NEW('IDLitVisDataSpace')
;
;   or
;
;   Obj->[IDLitVisDataSpace::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-
FUNCTION IDLitVisDataSpace::Init, $
    DESCRIPTION=inDescription, $
    NAME=inName, $
    NO_AXES=noAxes, $
    NO_PROPERTIES=NO_PROPERTIES, $
    TOOL=TOOL, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name and description.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Data Space"
    description = (N_ELEMENTS(inDescription) ne 0) ? $
        inDescription : "Data Space Component"

    ; Initialize superclasses.
    if (~self->_IDLitVisualization::Init($;/MANIPULATOR_TARGET, $
        NAME=name, $
        TYPE="VOID_DATASPACE_2D", $
        ICON='dataspace', $
        DESCRIPTION=description, $
        TOOL=TOOL, $
        /REGISTER_PROPERTIES, $
        _EXTRA=_extra)) THEN $
        return, 0

    ; Initialize automatic updates.
    self._xAutoUpdate = 1b
    self._yAutoUpdate = 1b
    self._zAutoUpdate = 1b

    ; Create the Data Axes component.
    if (not KEYWORD_SET(noAxes)) then begin
        self.oAxes = OBJ_NEW('IDLitVisDataAxes', NAME='Axes', $
                             DESCRIPTION="Axes Container", TOOL=TOOL)
        self->_IDLitVisualization::Add, self.oAxes
    endif

    ; Note that we will need to change this to an OBJARR(6) if we want
    ; to have individual walls to be selectable/changeable.
    if (~OBJ_VALID(self.oWall)) then begin
        ; Create the new wall object.
        self.oWall = OBJ_NEW('IDLitVisBackground', $
            NAME=self->is3D() ? 'Walls' : 'Background', TOOL=TOOL)

        ; We need to implement transparency of dataspace walls by using
        ; a texture map with zero opacity skip, so that the dataspace
        ; walls (which are drawn early in the scene) do not cause depth
        ; buffer clipping when they are drawn completely transparent.
        ;
        ; Our texture is the smallest completely white texture you can
        ; imagine.  We'll let the object's base color and alpha channel
        ; modulate the texture values.  Also, no texture coords are
        ; required since our texture is single color.
        image = BYTARR(4,2,2)
        image[*] = 255
        self.oTexture = OBJ_NEW('IDLgrImage', image)
        self.oWall->SetProperty, $
            TEXTURE_MAP=self.oTexture, $
            /ZERO_OPACITY_SKIP

        ; Add the wall object to ourself.
        ; We need to use /NO_UPDATE so we don't call back into
        ; ::OnDataRangeChange, which will then recursively call into
        ; ::_UpdateWalls.
        self->_IDLitVisualization::Add, self.oWall, $
          /AGGREGATE, /NO_UPDATE, POSITION=0
    endif

    ; By default, auto-compute axes requests.
    self.axesRequest = 0
    self->SetAxesRequest, 0, /AUTO_COMPUTE

    ; Register properties.
    if (~keyword_set(NO_PROPERTIES)) then $
      self->IDLitVisDataSpace::_RegisterProperties

   ; Set any properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisDataSpace::SetProperty, _EXTRA=_extra

    RETURN, 1
END


;----------------------------------------------------------------------------
; PURPOSE:
;      The IDLitVisDataSpace::Cleanup procedure method preforms all cleanup
;      on the object.
;
pro IDLitVisDataSpace::Cleanup

    compile_opt idl2, hidden

    ; Lock my data range, so if we receive any OnDataCompletes while
    ; dying, we will ignore them. This is needed to avoid problems with
    ; the background wall being destroyed but still trying to update.
    self._bLockDataChange = 1b

    OBJ_DESTROY, self.oTexture

    ; Cleanup superclasses.
    self->_IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisDataSpace::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisDataSpace::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisDataSpace::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'MAP_PROJECTION', $
            NAME='Map projection', $
            DESCRIPTION='Map projection for dataspace', $
            USERDEF='No projection (click to edit)'
    endif

    if (registerAll) then begin
        self->RegisterProperty, 'X_MINIMUM', /FLOAT, $
            NAME='X minimum', $
            DESCRIPTION='Minimum x value'

        self->RegisterProperty, 'X_MAXIMUM', /FLOAT, $
            NAME='X maximum', $
            DESCRIPTION='Maximum x value'

        self->RegisterProperty, 'Y_MINIMUM', /FLOAT, $
            NAME='Y minimum', $
            DESCRIPTION='Minimum y value'

        self->RegisterProperty, 'Y_MAXIMUM', /FLOAT, $
            NAME='Y maximum', $
            DESCRIPTION='Maximum y value'

        self->RegisterProperty, 'Z_MINIMUM', /FLOAT, $
            NAME='Z minimum', $
            DESCRIPTION='Minimum z value', $
            /HIDE   ; unhidden in Set3D

        self->RegisterProperty, 'Z_MAXIMUM', /FLOAT, $
            NAME='Z maximum', $
            DESCRIPTION='Maximum z value', $
            /HIDE   ; unhidden in Set3D

        self->RegisterProperty, 'X_AUTO_UPDATE', /BOOLEAN, $
            Name='Automatic X range', $
            Description='Update the X range automatically', /ADVANCED_ONLY

        self->RegisterProperty, 'Y_AUTO_UPDATE', /BOOLEAN, $
            Name='Automatic Y range', $
            Description='Update the Y range automatically', /ADVANCED_ONLY

        self->RegisterProperty, 'Z_AUTO_UPDATE', /BOOLEAN, $
            Name='Automatic Z range', $
            Description='Update the Z range automatically', $
            /HIDE, /ADVANCED_ONLY   ; unhidden in Set3D

    endif

    if (registerAll || updateFromVersion lt 640) then begin
        self->RegisterProperty, 'XLOG', /BOOLEAN, SENSITIVE=0, $
            Name='X log', $
            Description='X Axes Logarithmic', /ADVANCED_ONLY

        self->RegisterProperty, 'YLOG', /BOOLEAN, SENSITIVE=0, $
            Name='Y log', $
            Description='Y Axes Logarithmic', /ADVANCED_ONLY

        self->RegisterProperty, 'ZLOG', /BOOLEAN, SENSITIVE=0, /HIDE, $
            Name='Z log', $
            Description='Z Axes Logarithmic', /ADVANCED_ONLY
    endif

    if (~registerAll && updateFromVersion lt 640) then begin
         ; Renamed in IDL64 to XLOG, YLOG, ZLOG
        self->SetPropertyAttribute, ['X_LOG', 'Y_LOG', 'Z_LOG'], /HIDE
    endif

end

;----------------------------------------------------------------------------
; IDLitVisDataSpace::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisDataSpace::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; If we had properties, then register new ones.
    if (self->QueryProperty('X_MINIMUM')) then begin
        self->IDLitVisDataSpace::_RegisterProperties, $
            UPDATE_FROM_VERSION=self.idlitcomponentversion
    endif

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Set current axes request according to whether or not the
        ; contained data axes style is set to 'None'.
        if (OBJ_VALID(self.oAxes)) then begin
            self.oAxes->GetProperty, STYLE=style
            self.axesRequest = (style eq 0) ? 0 : 1
        endif else $
            self.axesRequest = 0
        self.axesMethod = 2 ; Auto-compute.
    endif
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;   A few points about logarithmic plots and dataspace.
;
;   The log property for x,y, or z can be set via property sheets on the
;   IDLitVisDataSpace, IDLitVisDataAxes, or IDLitVisAxis objects.  The axes
;   set the property on the data space which manages the process.  It is
;   incorrect to set the property on the underlying IDLgrAxis without going
;   through the data space.
;
;   When going to log, the data space range is converted to log.  This flows
;   down through the dataaxes and axis objects via onDataRangeChange.  itAxis
;   computes axis range and scaling in the log space, but just prior to setting
;   the new range on the grAxis it must be converted back to linear so that
;   the grAxis ends up with the original linear range combined with the LOG
;   keyword.  Note that this routine does not make separate calls to set the
;   LOG property on the dataAxes group to pass down to the itAxis objects.
;   If the LOG setting is applied before  the range is changed then there
;   may be "floating illegal operand" or "infinite axis range" errors.  For
;   this reason, the range is changed with onDataRangeChange and then in
;   itAxis when the range is to be applied to the grAxis, itAxis queries the
;   data space to determine if the axis should be log or not and converts
;   the range to linear if necessary.
;
;   The visualizations in the log plot must have their data converted to
;   log.  This routine finds the visualizations and sets the appropriate
;   [XYZ]_VIS_LOG properties to signal the visualization to convert to/from
;   logarithmic.  The visualizations must retrieve their data, convert
;   it to log/linear and put it back into the visualization.  This is required
;   because the grPlot and grPolyline visualizations do not support [xyz]log
;   keywords.  Note that the [XYZ]_VIS_LOG keywords are used rather than
;   [XYZ]_LOG to prevent conflicts with keywords passed in through the
;   command line to the visualizations.  At present the command line
;   arguments to create a plot at init are processed but the log plot
;   is not created because the data range has not been established.  The
;   sequence needs to be modified to allow application of the log after
;   the data space has been completely set up.
;
;   The properties controlling log on the IDLitVisDataSpace, IDLitVisDataAxes,
;   and IDLitVisAxis objects are desensitized if the given dimension is linear
;   and the minimum of the dimension's range is less than or equal to zero.
;
;   Currently the dataspace minimum and maximum report the log values (exponents)
;   which looks poor.  Changing the values to their linear counterparts in the
;   set/get caused problems with the plot zoom.
;
;   Object                          Data Range for Logarithmic Plot
;
;   IDLitVisDataSpace               log
;   IDLitVisDataAxes                log
;   IDLitVisAxis                    log
;   IDLgrAxis                       linear (with LOG keyword)
;   IDLitVisPlot, Plot3D            log
;   IDLgrPlot                       log
;   IDLgrPolyline                   log
;
pro IDLitVisDataSpace::_SetLog, XLOG=xLog, YLOG=yLog, ZLOG=zLog

    compile_opt idl2, hidden

    ; Grab former XYZ range for reference.
    if (OBJ_VALID(self.oAxes)) then begin
        self.oAxes->GetProperty, $
            XRANGE=oldXrange, $
            YRANGE=oldYrange, $
            ZRANGE=oldZrange
    endif else begin
        oldXrange = [0d, 0d]
        oldYrange = [0d, 0d]
        oldZrange = [0d, 0d]
    endelse

    bChange = 0b

    newXrange = oldXrange
    if (n_elements(xLog) gt 0) then begin
        ; Only allow switch to log if the range minimum is > 0.
        if (xLog && ~self._xLog && $
            (oldXrange[0] le 0 || oldXrange[1] le 0)) then $
            xLog = 0  ; don't switch
        if (xLog ne self._xLog) then begin
            bChange = 1b
            self._xLog = xLog
            newXrange = xLog ? alog10(oldXrange) : 10 ^ oldXrange
        endif
    endif

    newYrange = oldYrange
    if (n_elements(yLog) gt 0) then begin
        ; Only allow switch to log if the range minimum is > 0.
        if (yLog && ~self._yLog && $
            (oldYrange[0] le 0 || oldYrange[1] le 0)) then $
            yLog = 0
        if (yLog ne self._yLog) then begin
            bChange = 1b
            self._yLog = yLog
            newYrange = yLog ? alog10(oldYrange) : 10 ^ oldYrange
        endif
    endif

    newZrange = oldZrange
    if (n_elements(zLog) gt 0) then begin
        ; Only allow switch to log if the range minimum is > 0.
        if (zLog && ~self._zLog && $
            (oldZrange[0] le 0 || oldZrange[1] le 0)) then $
            zLog = 0  ; don't switch
        if (zLog ne self._zLog) then begin
            bChange = 1b
            self._zLog = zLog
            newZrange = zLog ? alog10(oldZrange) : 10 ^ oldZrange
        endif
    endif

    ; If no log settings changed, then no updates are required.
    if (~bChange) then $
        return

    ; Lock data changes so that infinite update loops are avoided.
    self._bLockDataChange = 1b

    ; Update the backstop walls.
    self->_UpdateWalls, newXRange, newYRange, newZRange

    ; Notify the contained visualizations of the change.
    ; Log or inverse log the data in the visualizations
    visItems = self->GetVisualizations(COUNT=nVisItems, /FULL_TREE)
    for i=0, nVisItems-1 do begin
        visItems[i]->SetProperty, $
            X_VIS_LOG=xLog, Y_VIS_LOG=yLog, Z_VIS_LOG=zLog
    endfor

    ; The axes handle themselves when updated via OnDataRangeChange
    self->_IDLitVisualization::OnDataRangeChange, self, $
        newXRange, newYRange, newZRange

    ; Unlock.
    self._bLockDataChange = 0b

    self->IDLgrModel::GetProperty, PARENT=oParent
    if OBJ_VALID(oParent) then begin
        oParent->OnDataChange, self
        oParent->OnDataComplete, self
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisDataSpace::Init followed by the word "Get"
;      can be retrieved using IDLitVisDataSpace::GetProperty.
;-
pro IDLitVisDataSpace::GetProperty, $
    MAP_PROJECTION=mapProjection, $
    X_AUTO_UPDATE=xAutoUpdate, $
    X_MINIMUM=xMin, $
    X_MAXIMUM=xMax, $
    Y_AUTO_UPDATE=yAutoUpdate, $
    Y_MINIMUM=yMin, $
    Y_MAXIMUM=yMax, $
    Z_AUTO_UPDATE=zAutoUpdate, $
    Z_MINIMUM=zMin, $
    Z_MAXIMUM=zMax, $
    XLOG=xLog, $
    YLOG=yLog, $
    ZLOG=zLog, $
    X_LOG=x_Log, $ ; renamed in IDL64, keep for backwards compat
    Y_LOG=y_Log, $ ; renamed in IDL64, keep for backwards compat
    Z_LOG=z_Log, $ ; renamed in IDL64, keep for backwards compat
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (ARG_PRESENT(mapProjection)) then begin
        sMap = self->GetProjection()
        mapProjection = (N_TAGS(sMap) gt 0) ? sMap.up_name : 'No projection'
    endif

    if (ARG_PRESENT(xAutoUpdate)) then $
        xAutoUpdate = self._xAutoUpdate

    if (ARG_PRESENT(yAutoUpdate)) then begin
        yAutoUpdate = self._yAutoUpdate
    endif

    if (ARG_PRESENT(zAutoUpdate)) then $
        zAutoUpdate = self._zAutoUpdate

    if (ARG_PRESENT(xLog)) then $
        xLog = self._xLog

    if (ARG_PRESENT(yLog)) then $
        yLog = self._yLog

    if (ARG_PRESENT(zLog)) then $
        zLog = self._zLog

    if (ARG_PRESENT(x_Log)) then $
        x_Log = self._xLog

    if (ARG_PRESENT(y_Log)) then $
        y_Log = self._yLog

    if (ARG_PRESENT(z_Log)) then $
        z_Log = self._zLog

    getRange = ARG_PRESENT(xMin) || ARG_PRESENT(xMax) || $
               ARG_PRESENT(yMin) || ARG_PRESENT(yMax) || $
               ARG_PRESENT(zMin) || ARG_PRESENT(zMax)

    if (getRange) then begin
        axisRangeValid = self->_GetXYZAxisRange(xRange, yRange, zRange, $
            XREVERSE=xReverse, YREVERSE=yReverse, ZREVERSE=zReverse, $
            /NO_TRANSFORM)
        if (axisRangeValid eq 0) then begin
            xRange = DBLARR(2)
            yRange = DBLARR(2)
            zRange = DBLARR(2)
        endif

        ; translate the values that the user sees into linear if necessary
        if self._xLog then xRange = 10^xRange
        if self._yLog then yRange = 10^yRange
        if self._zLog then zRange = 10^zRange

        if (ARG_PRESENT(xMin)) then $
            xMin = (xReverse ? xRange[1] : xRange[0])

        if (ARG_PRESENT(xMax)) then $
            xMax = (xReverse ? xRange[0] : xRange[1])

        if (ARG_PRESENT(yMin)) then $
            yMin = (yReverse ? yRange[1] : yRange[0])

        if (ARG_PRESENT(yMax)) then $
            yMax = (yReverse ? yRange[0] : yRange[1])

        if (ARG_PRESENT(zMin)) then $
            zMin = (zReverse ? zRange[1] : zRange[0])

        if (ARG_PRESENT(zMax)) then $
            zMax = (zReverse ? zRange[0] : zRange[1])

    endif

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisDataSapce::Init followed by the word "Set"
;      can be set using IDLitVisDataSpace::SetProperty.
;-
pro IDLitVisDataSpace::SetProperty, $
    MAP_PROJECTION=mapProjection, $
    X_AUTO_UPDATE=xAutoUpdate, $
    X_MINIMUM=xMin, $
    X_MAXIMUM=xMax, $
    Y_AUTO_UPDATE=yAutoUpdate, $
    Y_MINIMUM=yMin, $
    Y_MAXIMUM=yMax, $
    Z_AUTO_UPDATE=zAutoUpdate, $
    Z_MINIMUM=zMin, $
    Z_MAXIMUM=zMax, $
    XLOG=xLog, $
    YLOG=yLog, $
    ZLOG=zLog, $
    X_LOG=x_Log, $ ; renamed in IDL64, keep for backwards compat
    Y_LOG=y_Log, $ ; renamed in IDL64, keep for backwards compat
    Z_LOG=z_Log, $ ; renamed in IDL64, keep for backwards compat
    XRANGE=xRangeCmdLine, $
    YRANGE=yRangeCmdLine, $
    ZRANGE=zRangeCmdLine, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(xRangeCmdLine) ne 0) then begin
      xMin = xRangeCmdLine[0]
      xMax = xRangeCmdLine[1]
    endif
    if (N_ELEMENTS(yRangeCmdLine) ne 0) then begin
      yMin = yRangeCmdLine[0]
      yMax = yRangeCmdLine[1]
    endif
    if (N_ELEMENTS(zRangeCmdLine) ne 0) then begin
      zMin = zRangeCmdLine[0]
      zMax = zRangeCmdLine[1]
    endif

    updateRange = N_ELEMENTS(xMin) || N_ELEMENTS(xMax) || $
                  N_ELEMENTS(yMin) || N_ELEMENTS(yMax) || $
                  N_ELEMENTS(zMin) || N_ELEMENTS(zMax)


    ; If a range update is required, get the former range for
    ; initial settings.
    if (updateRange) then begin

        axisRangeValid = self->_GetXYZAxisRange(xRange, yRange, zRange, $
            /NO_TRANSFORM)
        if (axisRangeValid eq 0) then begin
            xRange = DBLARR(2)
            yRange = DBLARR(2)
            zRange = DBLARR(2)
        endif

        ; If any range was reversed, reset it to its original
        ; reversed state before setting new min and max values.
        if (self._xReverse) then $
            xRange = REVERSE(xRange)
        if (self._yReverse) then $
            yRange = REVERSE(yRange)
        if (self._zReverse) then $
            zRange = REVERSE(zRange)

        ; translate the values that the user enters into log if necessary
        if (N_ELEMENTS(xMin) gt 0) then begin
            xRange[0] = self._xLog ? $
                (xMin gt 0 ? alog10(xMin) : xRange[0]) : xMin
        endif

        if (N_ELEMENTS(xMax) ne 0) then begin
            xRange[1] = self._xLog ? $
                (xMax gt 0 ? alog10(xMax) : xRange[1]) : xMax
        endif

        if (N_ELEMENTS(yMin) ne 0) then begin
            yRange[0] = self._yLog ? $
                (yMin gt 0 ? alog10(yMin) : yRange[0]) : yMin
        endif

        if (N_ELEMENTS(yMax) ne 0) then begin
            yRange[1] = self._yLog ? $
                (yMax gt 0 ? alog10(yMax) : yRange[1]) : yMax
        endif

        if (N_ELEMENTS(zMin) ne 0) then begin
            zRange[0] = self._zLog ? $
                (zMin gt 0 ? alog10(zMin) : zRange[0]) : zMin
        endif

        if (N_ELEMENTS(zMax) ne 0) then begin
            zRange[1] = self._zLog ? $
                (zMax gt 0 ? alog10(zMax) : zRange[1]) : zMax
        endif

        self->OnDataRangeChange, self, xRange, yRange, zRange

    endif

    if (N_ELEMENTS(xAutoUpdate) ne 0) then $
        self._xAutoUpdate = KEYWORD_SET(xAutoUpdate)

    if (N_ELEMENTS(yAutoUpdate) ne 0) then begin
        self._yAutoUpdate = KEYWORD_SET(yAutoUpdate)
    endif

    if (N_ELEMENTS(zAutoUpdate) ne 0) then $
        self._zAutoUpdate = KEYWORD_SET(zAutoUpdate)

    ; renamed in IDL64, keep for backwards compat
    if (N_Elements(x_Log)) then xLog = x_Log
    if (N_Elements(y_Log)) then yLog = y_Log
    if (N_Elements(z_Log)) then zLog = z_Log

    if N_ELEMENTS(xLog) || N_ELEMENTS(yLog) || N_ELEMENTS(zLog) then begin
        self->_SetLog, XLOG=xLog, YLOG=yLog, ZLOG=zLog
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra

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
function IDLitVisDataSpace::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'MAP_PROJECTION': begin
        ; This will also call _GetMapProjection, which will create
        ; our map projection object.
        void = oTool->DoAction('Operations/Operations/Map Projection')
        ; The Insert Map Projection operation will take care of adding the
        ; undo/redo buffer. So return 0 indicating "failure", so we don't
        ; add our own undo/redo. This assumes that our EditUserDefProperty
        ; operation doesn't actually undo any of our property settings.
        return, 0
        end

    else:

    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end


;----------------------------------------------------------------------------
; IIDLitVisDataSpace Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::_GetXYZAxisRange
;
; PURPOSE:
;      The IDLitVisDataSpace::_GetXYZAxisRange procedure method gets the range
;      of the data space
;
; CALLING SEQUENCE:
;      result = Obj->[IDLitVisDataSpace::]_GetXYZAxisRange, xrange, yrange, zrange
;
; KEYWORDS:
;      NO_TRANSFORM - Set to not include the transform matrix.
;      XREVERSE - Set this keyword to a named variable that upon return
;              will contain a 1 if the X range needs to be reversed, or
;              a 0 otherwise.
;      YREVERSE - Set this keyword to a named variable that upon return
;              will contain a 1 if the Y range needs to be reversed, or
;              a 0 otherwise.
;      ZREVERSE - Set this keyword to a named variable that upon return
;              will contain a 1 if the Z range needs to be reversed, or
;              a 0 otherwise.
;
; OUTPUTS:
;      result: 0 if all of the axes have no range (low and high range values
;              are equal). 1 otherwise.
;      xrange: A two-element vector, [xmin, xmax], representing
;              the X-axis range.
;      yrange: A two-element vector, [ymin, ymax], representing
;              the Y-axis range.
;      zrange: A two-element vector, [zmin, zmax], representing
;              the Z-axis range.
;
; KEYWORD PARAMETERS:
;-
function IDLitVisDataSpace::_GetXYZAxisRange, xrange, yrange, zrange, $
    NO_TRANSFORM=noTransform, $
    XREVERSE=xReverse, $
    YREVERSE=yReverse, $
    ZREVERSE=zReverse

    compile_opt idl2, hidden

    xrange = [0d, 0d]
    yrange = [0d, 0d]
    zrange = [0d, 0d]

    if (ARG_PRESENT(xReverse)) then $
        xReverse = self._xReverse
    if (ARG_PRESENT(xReverse)) then $
        yReverse = self._yReverse
    if (ARG_PRESENT(xReverse)) then $
        zReverse = self._zReverse

    if (~OBJ_VALID(self.oAxes)) then $
        return, 0

    self.oAxes->GetProperty, XRANGE=xrange, YRANGE=yrange, $
        ZRANGE=zrange, NO_TRANSFORM=noTransform

    RETURN, (xrange[0] eq xrange[1]) and (yrange[0] eq yrange[1]) and $
             (zrange[0] eq zrange[1]) ? 0B : 1B
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::_GetXYZAxisReverseFlags
;
; PURPOSE:
;      The IDLitVisDataSpace::_GetXYZAxisReverseFlags procedure method
;      the boolean flags (one per axis direction) that indicate whether
;      the corresponding axis range is to be reversed.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]_GetXYZAxisReverseFlags, $
;          XReverse, YReverse, ZReverse
;
; INPUTS:
;      XReverse - A named variable that upon return will contain a 1
;              if the X range needs to be reversed, or a 0 otherwise.
;      YReverse - A named variable that upon return will contain a 1
;              if the Y range needs to be reversed, or a 0 otherwise.
;      zReverse - A named variable that upon return will contain a 1
;              if the Z range needs to be reversed, or a 0 otherwise.
;-
pro IDLitVisDataSpace::_GetXYZAxisReverseFlags, xReverse, yReverse, zReverse

    compile_opt idl2, hidden

    xReverse = self._xReverse
    yReverse = self._yReverse
    zReverse = self._zReverse

end


;----------------------------------------------------------------------------
pro IDLitVisDataSpace::_UpdateWalls, inXRange, inYRange, inZRange

    compile_opt idl2, hidden

    is3D = self->Is3D()

    ; If any range was reversed, reset it to its original
    ; reversed state before computing wall locations.
    XRange = (self._xReverse ? REVERSE(inXRange) : inXRange)
    YRange = (self._yReverse ? REVERSE(inYRange) : inYRange)
    ZRange = (self._zReverse ? REVERSE(inZRange) : inZRange)

    x0y0z0 = [XRange[0],YRange[0],ZRange[0]]
    x1y0z0 = [XRange[1],YRange[0],ZRange[0]]
    x1y1z0 = [XRange[1],YRange[1],ZRange[0]]
    x0y1z0 = [XRange[0],YRange[1],ZRange[0]]


    if (is3D) then begin

        x0y0z1 = [XRange[0],YRange[0],ZRange[1]]
        x1y0z1 = [XRange[1],YRange[0],ZRange[1]]
        x1y1z1 = [XRange[1],YRange[1],ZRange[1]]
        x0y1z1 = [XRange[0],YRange[1],ZRange[1]]

        ; Bottom, Top, Left, Right, Front, Back.
        ; These vertices are ordered so that the normals all point in towards
        ; the center of the dataspace. That way, when REJECT=1 is set, they
        ; are clipped if facing away from the viewer.
        self.oWall->SetProperty, $
            DATA=REFORM([x0y0z0,x1y0z0,x1y1z0,x0y1z0, $
                x0y0z1,x1y0z1,x1y1z1,x0y1z1],3,8), $
            POLYGONS=[4,0,1,2,3,  4,7,6,5,4,  4,0,3,7,4,  $
                4,1,5,6,2,  4,0,4,5,1,  4,3,2,6,7], $
            POLYLINES=[5,0,1,2,3,0,  5,4,5,6,7,4,  5,0,3,7,4,0,  $
                5,1,5,6,2,1,  5,0,4,5,1,0,  5,3,2,6,7,3]

    endif else begin

        ; Just a single polygon for the background.
        self.oWall->SetProperty, $
            DATA=REFORM([x0y0z0,x1y0z0,x1y1z0,x0y1z0,x0y0z0],3,5), $
            POLYGONS=[4,0,1,2,3], $
            POLYLINES=[5,0,1,2,3,0]

    endelse

end


;---------------------------------------------------------------------------
; Retrieve the Projection object from ourself.
;
function IDLitVisDataSpace::_GetMapProjection

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oMapProj)) then begin
        self._oMapProj = OBJ_NEW('IDLitVisMapProjection')
        self->Add, self._oMapProj, POSITION=1
    endif

    return, self._oMapProj

end


;---------------------------------------------------------------------------
; Retrieve the current Projection from ourself.
; Returns either a !MAP structure or a scalar 0.
;
function IDLitVisDataSpace::GetProjection

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oMapProj)) then $
        return, 0

    self._oMapProj->GetProperty, MAP_STRUCTURE=sMap

    return, sMap

end


;----------------------------------------------------------------------------
; The sMap argument is provided for consistency with _IDLitVisualization,
; but is ignored. The sMap is always retrieved from ourself.
;
pro IDLitVisDataSpace::OnProjectionChange, sMap

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        void = oTool->DoUIService("HourGlassCursor", self)

    sMap = self->GetProjection()
    self->_IDLitVisualization::OnProjectionChange, sMap

    ; Update our userdef string.
    name = (N_TAGS(sMap) gt 0) ? sMap.up_name : 'No projection'
    name += ' (click to edit)'
    if (self->QueryProperty('MAP_PROJECTION')) then begin
        self->SetPropertyAttribute, 'MAP_PROJECTION', USERDEF=name
    endif

    ; Notify our NormDataspace parent that a property changed.
    ; The parent should aggregate ourself and should be the one
    ; displayed in any property sheets.
    self->GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent)) then begin
        self->DoOnNotify, oParent->GetFullIdentifier(), $
            'SETPROPERTY', 'MAP_PROJECTION'
    endif

    self->OnDataChange, self
    self->OnDataComplete, self

end


;----------------------------------------------------------------------------
; +
; METHODNAME:
;   IDLitVisDataSpace::SetPixelDataSize
;
; PURPOSE:
;   This procedure method changes the current X and Y range of the
;   dataspace so that a single pixel will correspond to the given
;   data dimensions.
;
;   Note that this function assumes that the dataspace is currently
;   2D.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpace::]SetPixelDataSize, PixelXSize, PixelYSize
;
; INPUTS:
;   PixelXSize: A scalar representing the requested data dimensions of
;   a single pixel in X.
;
;   PixelYSize: A scalar representing the requested data dimensions of
;   a single pixel in Y.
;-
pro IDLitVisDataSpace::SetPixelDataSize, pixelXSize, pixelYSize

    compile_opt idl2, hidden

    axisRangeValid = self->_GetXYZAxisRange(xRange, yRange, zRange, $
        /NO_TRANSFORM)

    if (axisRangeValid eq 0) then $
        return

    ; Map corners to window locations.
    self->VisToWindow, xRange, yRange, [0,0], $
        winXRange, winYRange, winZRange

    ; Determine what the modified data range would need to be
    ; to map to the current window ranges.
    newXLen = pixelXSize * (winXRange[1]-winXRange[0])
    newYLen = pixelYSize * (winYRange[1]-winYRange[0])

    ; Update xy range (staying centered on current center).
    centerX = (xRange[0]+xRange[1])/2.0
    centerY = (yRange[0]+yRange[1])/2.0
    newXMin = centerX - (newXLen/2.0)
    newXMax = newXMin + newXLen
    newYMin = centerY - (newYLen/2.0)
    newYMax = newYMin + newYLen

    self->SetProperty, X_MINIMUM=newXMin, X_MAXIMUM=newXMax, $
        Y_MINIMUM=newYMin, Y_MAXIMUM=newYMax
end

;---------------------------------------------------------------------------
; Name:
;   IDLitVisDataSpace::_TestPrecision
;
; Purpose:
;   This internal function method determines whether double precision is
;   required for this data space.
;
; Arguments:
;   XRange: A two-element vector,[xmin,xmax], representing the new
;     xrange for the data space.
;   YRange: A two-element vector,[ymin,ymax], representing the new
;     yrange for the data space.
;   ZRange: A two-element vector,[zmin,zmax], representing the new
;     zrange for the data space.
;
; Return value:
;   This function method returns a 1 if the dataspace requires double
;   precision, or 0 otherwise.
;
function IDLitVisDataSpace::_TestPrecision, XRange, YRange, ZRange

    compile_opt idl2, hidden

    for i=0,2 do begin

        case i of
        0: range = xRange
        1: range = yRange
        2: range = zRange
        endcase

        ; Absolute min & max.
        minn = MIN(ABS(range), MAX=maxx)
        ; Range relative to maximum value.
        delta = ABS(range[1] - range[0])
        if (maxx ne 0) then delta /= maxx

        ; Choose a reasonably small epsilon for our single/double cutoff.
        ; This needs to be small enough so we aren't always using
        ; double precision. However, if you are using the Data Range
        ; zoom, we might need it to switch to double so that the
        ; zoom box appears to grow/shrink smoothly.
        if ((delta ne 0 && delta lt 1e-3) || $
            (minn gt 0 && minn lt 1e-30) || $
            (maxx gt 0 && maxx gt 1e30)) then begin
            return, 1b
        endif

    endfor

    return, 0b
end

;---------------------------------------------------------------------------
; Name:
;   IDLitVisDataSpace::RequiresDouble
;
; Purpose:
;   This function method reports whether this dataspace range requires
;   double precision.
;
; Return value:
;   This function method returns a 1 if the dataspace requires double
;   precision, or 0 otherwise.
;
function IDLitVisDataSpace::RequiresDouble
    compile_opt idl2, hidden

    return, self._requiresDouble
end

;----------------------------------------------------------------------------
; IIDLDataRangeObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::OnDataRangeChange
;
; PURPOSE:
;      The IDLitVisDataSpace::OnDataRangeChange procedure method
;      handles notification of an XYZ range change by updating the
;      extents of the axes within this data space.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject: A reference to the object sending notification of
;                the range change.
;      XRange: A two-element vector, [xmin, xmax], representing
;              the X-axis range.
;      YRange: A two-element vector, [ymin, ymax], representing
;              the Y-axis range.
;      ZRange: A two-element vector, [zmin, zmax], representing
;              the Z-axis range.
;
; KEYWORDS:
;      DATA_UPDATE: Set this keyword to a non-zero value to
;              indicate that this is being called as a result of
;              a data change (for one of the contained visualizations).
;              In this case, the automatic update flags for the x, y,
;              and z ranges will be honored.  If this keyword is not
;              set, the ranges will be updated regarless of the automatic
;              update flags.
;
;      _WITHIN_DATA_COMPLETE: Internal keyword used to designate that
;              this method was called from this object's own
;              ::OnDataComplete method, in which case, parent notifcation
;              can be reduced to a single corresponding ::OnDataComplete
;              call (rather than the typical ::OnDataChange plus
;              ::OnDataComplete pair).
;-
pro IDLitVisDataSpace::OnDataRangeChange, oSubject, XRange, YRange, ZRange, $
    DATA_UPDATE=dataUpdateIn, $
    _WITHIN_DATA_COMPLETE=withinDataComplete, $
    NOTIFIER=oOrigNotifier

    compile_opt idl2, hidden

    if (self._bLockDataChange) then $
        return

    oTool = self->GetTool()

    if (ISA(self,'_IDLitVisualization') && $
        self->_GetWindowandViewG(oWin, oViewG)) then begin
      titleID = iGetId((self->GetDataspace()).identifier+'/title',TOOL=oTool)
    endif else begin
      titleID = ''
    endelse

    if (titleID ne '') then begin
      oTitle = oTool->GetByIdentifier(titleID)
    endif
         
    dataUpdate = KEYWORD_SET(dataUpdateIn)

    ; Grab former XYZ range for reference.
    if (OBJ_VALID(self.oAxes)) then begin
        self.oAxes->GetProperty, $
            XRANGE=oldXrange, $
            YRANGE=oldYrange, $
            ZRANGE=oldZrange
    endif else begin
        oldXrange = [0d, 0d]
        oldYrange = [0d, 0d]
        oldZrange = [0d, 0d]
    endelse


    newXrange= XRange
    newYrange= YRange
    newZrange= ZRange


    xWasReversed = self._xReverse
    yWasReversed = self._yReverse
    zWasReversed = self._zReverse

    ; Reverse the new ranges as necessary.
    ; Do not change the reverse if auto update is turned off
    ; and we only have a data change.
    if (self._xAutoUpdate || ~dataUpdate) then begin
        self._xReverse = newXrange[0] gt newXrange[1]
        if (self._xReverse) then $
            newXrange = REVERSE(newXrange)
    endif

    if (self._yAutoUpdate || ~dataUpdate) then begin
        self._yReverse = newYrange[0] gt newYrange[1]
        if (self._yReverse) then $
            newYrange = REVERSE(newYrange)
    endif

    if (self._zAutoUpdate || ~dataUpdate) then begin
        self._zReverse = newZrange[0] gt newZrange[1]
        if (self._zReverse) then $
            newZrange = REVERSE(newZrange)
    endif


    oNotifier = oSubject
    if (oNotifier ne self) then begin
        ; If the object sending notification of the range change is
        ; another data space (of which this one is a descendent), then this
        ; data space needs to be clipped to the new range if it is not
        ; already.

        ; Set the new range to the old range clipped to the
        ; range associated with this notification.
        newXrange[0] >= oldXrange[0]
        newXrange[1] <= oldXrange[1]
        newYrange[0] >= oldYrange[0]
        newYrange[1] <= oldYrange[1]
        newZrange[0] >= oldZrange[0]
        newZrange[1] <= oldZrange[1]

        ; Now change the notifier to self, and fall through
        ; to the following code.
        oNotifier = self
    endif

    ; If this range change is the result of a data change of one of
    ; the contained visualizations, only perform automatic range updates
    ; if requested.
    if (dataUpdate) then begin
        if (~self._xAutoUpdate && (oldXRange[0] ne oldXRange[1])) then $
            newXRange = oldXRange
        if (~self._yAutoUpdate && (oldYRange[0] ne oldYRange[1])) then $
            newYRange = oldYRange
        if (~self._zAutoUpdate && (oldZRange[0] ne oldZRange[1])) then $
            newZRange = oldZRange
    endif

    ; If this object is not in the process of being initialized
    ; (or, if the parent normalized dataspace is not in the process
    ; of being initialized), then perform a sanity check:
    ;   If ranges are zero-length, then pick an arbitrary range.
    self->IDLitComponent::GetProperty, INITIALIZING=initializing
    if (~initializing) then begin
        self->GetProperty, _PARENT=oParent
        if (OBJ_ISA(oParent, 'IDLitVisNormDataSpace')) then $
            oParent->GetProperty, INITIALIZING=initializing
    endif

    if (~initializing) then begin
        if (newXrange[0] eq newXrange[1]) then $
            newXrange = [-1, 1] + newXrange[0]

        if (newYrange[0] eq newYrange[1]) then $
            newYrange = [-1, 1] + newYrange[0]

        if (self->Is3D()) then begin
            if (newZrange[0] eq newZrange[1]) then $
                newZrange = [-1, 1] + newZrange[0]
        endif
    endif

    if (ISA(oTitle) && ~ISA(withinDataComplete)) then begin
      oTitle->GetProperty, TRANSFORM=tr
      self->VisToWindow, tr[3,0], tr[3,1], tr[3,2], xx, yy, zz
      titleLoc = [xx,yy,zz] 
    endif
    
    ; Update data space transform only if range changed.
    if (ARRAY_EQUAL([newXRange, newYRange, newZRange], $
        [oldXRange, oldYRange, oldZRange])) then begin
        ; If reversals have changed, continue with updates.  Otherwise,
        ; simply return.
        if (ARRAY_EQUAL([xWasReversed, yWasReversed, zWasReversed], $
           [self._xReverse, self._yReverse, self._zReverse])) then begin
            if (OBJ_VALID(oOrigNotifier) && $
                OBJ_ISA(oOrigNotifier, '_IDLitVisualization') && $
                (oOrigNotifier ne self)) then begin
                ; Lock data changes so that infinite update loops are avoided.
                self._bLockDataChange = 1b
                oOrigNotifier->OnDataRangeChange, self, $
                    newXRange, newYRange, newZRange
                ; Unlock.
                self._bLockDataChange = 0b
            endif
            return
        endif
    endif

    ; Update the flag regarding the need for double precision.
    self._requiresDouble = self->_TestPrecision( $
        newXRange, newYRange, newZRange)

    ; For an initial 3D view, rotate to a "nice" viewing angle.
    if (self->Is3D()) then begin ; 3D.
        oTarget = self->GetManipulatorTarget()
        if (OBJ_VALID(oTarget) ne 0) then begin
            oTarget->GetProperty, TRANSFORM=oldXform

            ; See if we need to set an initial "nice" viewing angle
            firstTime = ARRAY_EQUAL(oldXform, IDENTITY(4))
            if (firstTime ne 0) then begin
                oTarget->IDLgrModel::Rotate, [1, 0, 0], -90
                oTarget->IDLgrModel::Rotate, [0, 1, 0], 30
                oTarget->IDLgrModel::Rotate, [1, 0, 0], 30
            endif
        endif
    endif

    ; Lock data changes so that infinite update loops are avoided.
    self._bLockDataChange = 1b

    ; Update the backstop walls.
    self->_UpdateWalls, newXRange, newYRange, newZRange

    ; Notify the contained visualizations of the range change.
    ; Note that this handles the range change for the axes group
    ; as well; there is no need to set the [XYZ]Range properties
    ; on self.oAxes explicitly.
    self->_IDLitVisualization::OnDataRangeChange, self, $
        newXRange, newYRange, newZRange

    ; Unlock.
    self._bLockDataChange = 0b

    if (~KEYWORD_SET(withinDataComplete)) then begin
        self->IDLgrModel::GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then begin
            oParent->OnDataChange, self
            oParent->OnDataComplete, self
        endif
    endif

    if (ISA(oTitle) && ISA(titleLoc)) then begin
      oTitle->GetProperty, TRANSFORM=tr
      self->WindowToVis, titleLoc[0], titleLoc[1], titleLoc[2], xx,yy,zz
      tr[3,0:2] = [xx,yy,zz]                                 
      oTitle->SetProperty, TRANSFORM=tr
    endif

    ; Send an additional notification after the data change/complete
    ; to just our axes because the axes need to do some of their layout
    ; after the transforms have been updated.  Note that this is only
    ; required if there are any reversals currently or previously in effect.
    if (OBJ_VALID(self.oAxes) && $
        (xWasReversed || yWasReversed || zWasReversed || $
        self._xReverse || self._yReverse || self._zReverse)) then begin
        self.oAxes->OnDataRangeChange, self, $
            newXRange, newYRange, newZRange
    endif

    ; These settings are designed to prevent turning on Log mode
    ; unless the range minimum is greater than zero.
    oldSensitive = (oldXrange[0] gt 0 && oldXrange[1] gt 0)
    sensitive = (newXrange[0] gt 0 && newXrange[1] gt 0)
    if (self._xLog || sensitive ne oldSensitive) then $
      self->SetPropertyAttribute, 'XLOG', SENSITIVE=self._xLog || sensitive
    oldSensitive = (oldYrange[0] gt 0 && oldYrange[1] gt 0)
    sensitive = self._yLog || (newYrange[0] gt 0 && newYrange[1] gt 0)
    if (self._yLog || sensitive ne oldSensitive) then $
      self->SetPropertyAttribute, 'YLOG', SENSITIVE=self._yLog || sensitive
    oldSensitive = (oldZrange[0] gt 0 && oldZrange[1] gt 0)
    sensitive = (newZrange[0] gt 0 && newZrange[1] gt 0)
    if (self._zLog || sensitive ne oldSensitive) then $
      self->SetPropertyAttribute, 'ZLOG', SENSITIVE=self._zLog || sensitive

    ; Broadcast notification to any interested parties.
    myID = self->GetFullIdentifier()
    self->DoOnNotify, myID, 'RANGE_CHANGE', 1

    ; Note that we need to broadcast property changes to my parent
    ; NormDataSpace since the dataspace is just aggregated by
    ; the NormDataSpace.
    void = IDLitBasename(myID, REMAIN=parentID)
    self->DoOnNotify, parentID, 'SETPROPERTY', ''

end


;----------------------------------------------------------------------------
; IIDLContainer Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PURPOSE:
;   Keep the background wall and axes at the beginning/end of the container.
;   Returns a two element vector giving the valid positions in which new
;   items can be inserted.
;
function IDLitVisDataSpace::_CheckPositions

    compile_opt idl2, hidden

    ; Make sure my wall is at the zero position.
    haveWall = self->IDLgrModel::IsContained(self.oWall, $
        POSITION=position)
    if (haveWall && (position ne 0)) then $
        self->IDLgrModel::Move, position, 0

    nContained = self->IDLgrModel::Count()

    ; Make sure my axes are last.
    haveAxes = self->IDLgrModel::IsContained(self.oAxes, $
        POSITION=position)
    if (haveAxes && (position ne (nContained-1))) then $
        self->IDLgrModel::Move, position, nContained-1

    return, [haveWall, nContained - haveAxes]
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::Add
;
; PURPOSE:
;      This procedure method adds a visualization to the data space
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]Add, visualization
;
; INPUTS:
;      visualization: the visualization to add to the Data Space
;
; KEYWORD PARAMETERS:
;    Passed to the underlying routine.
;-
PRO IDLitVisDataSpace::Add, oVis, $
    USE__PARENT=USE__PARENT, $   ; handle manually (ignore for axes)
    _EXTRA=_EXTRA

    compile_opt idl2, hidden

    ; Data axes are ignored.
    isAxes = OBJ_ISA(oVis, "IDLitVisDataAxes")
    iAxes = WHERE(isAxes, nAxes, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)

    ; If nothing else to add, then return.
    if (nOther eq 0) then $
        return
    oOther = oVis[iOther]

    ; Add each individual axis to the axes container.
    isAxis = OBJ_ISA(oOther, "IDLitVisAxis")
    iAxis = WHERE(isAxis, nAxis, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)
    if (nAxis gt 0) then begin
        if (OBJ_VALID(self.oAxes)) then begin
            ; Set USE__PARENT=0 to make sure we don't add the axis
            ; to the wrong parent.
            self.oAxes->Add, oOther[iAxis], USE__PARENT=0, $
                _EXTRA=_EXTRA
        endif
    endif

    ; If nothing else to add, then return.
    if (nOther eq 0) then $
        return
    oOther = oOther[iOther]

    ; Make sure my walls and axes are still at the beginning & end.
    validPositions = self->_CheckPositions()

    ; If we have a map grid, and it is still in the second-to-last
    ; position in the container, then keep it there and insert the new
    ; visualizations before it in the container. This way the grid will
    ; always be on top, unless the user has explicitly moved it behind.
    if (validPositions[1] gt 0 && ~ISA(oOther[0], 'IDLitVisMapGrid')) then begin
        oLast = self->_IDLitVisualization::Get(POSITION=validPositions[1]-1)
        if (OBJ_VALID(oLast) && OBJ_ISA(oLast, 'IDLitVisMapGrid')) then $
            validPositions[1] = (validPositions[1] - 1) > 0
    endif

    ; Add to the end, just before the axes.
    self->_IDLitVisualization::Add, oOther, POSITION=validPositions[1], $
        /USE__PARENT, _extra=_extra

    ; Notify the visualizations about the dimensionality of the
    ; world into which they have just been added.  (Some visualization
    ; classes, such as IDLitVisImage, need to know this information
    ; in order to display themselves correctly.)
    ; Note: if this notification happens before the above ::Add call,
    ; problems may be encountered due to lack of appropriate parentage.
    ; Furthermore, the self.is3D may change after the visualizations are
    ; added, so it is best to wait until after the add to ensure this
    ; field is properly set.
    isVis = OBJ_ISA(oOther, '_IDLitVisualization')
    iVis = WHERE(isVis eq 1, nVis)
    for i=0,nVis-1 do $
        oOther[iVis[i]]->OnWorldDimensionChange, self, self.is3D

END

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisDataSpace::Remove
;
; PURPOSE:
;      This procedure method removes a visualization to the data space
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisDataSpace::]Remove, visualization
;
; INPUTS:
;      visualization: the visualization to remove from the Data Space
;
; KEYWORD PARAMETERS:
;    Passed to the underlying routine.
;-
PRO IDLitVisDataSpace::Remove, oVis, _EXTRA=_EXTRA

    compile_opt idl2, hidden

    ; Remove each individual axis from the data axes container.
    isAxis = OBJ_ISA(oVis, "IDLitVisAxis")
    iAxis = WHERE(isAxis, nAxis, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)
    if (nAxis gt 0) then begin
        if (OBJ_VALID(self.oAxes)) then $
            self.oAxes->_IDLitVisualization::Remove, oVis[iAxis], $
                _EXTRA=_extra
    endif

    ; If nothing else to remove, then return.
    if (nOther eq 0) then $
        return
    oOther = oVis[iOther]

    ; Data axes are ignored.  The data axes object is intended to
    ; persist.
    isAxes = OBJ_ISA(oOther, "IDLitVisDataAxes")
    iAxes = WHERE(isAxes, nAxes, COMPLEMENT=iOther, $
        NCOMPLEMENT=nOther)
    if (nAxes gt 0) then begin
        self->ErrorMessage, IDLitLangCatQuery('Error:DeleteAxes:Text'), $
            SEVERITY=1, TITLE=IDLitLangCatQuery('Error:Delete:Title')
    endif

    ; Remove all others.
    if (nOther gt 0) then $
        self->_IDLitVisualization::Remove, oOther[iOther], $
            _EXTRA=_extra

END


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::Move
;
; PURPOSE:
;   Override the move method so we can keep the
;   background & axes at the beginning and end.
;
pro IDLitVisDataSpace::Move, oldPosition, newPositionIn

    compile_opt idl2, hidden

    ; Make sure my new position is between the walls and axes.
    ; (This will also move the walls & axes if necessary.)
    validPositions = self->_CheckPositions()
    newPosition = validPositions[0] > $
        (newPositionIn < (validPositions[1]-1))

    if (oldPosition eq newPosition) then $
        return

    ; Move within our container. This will also handle keeping the
    ; manipulator visuals at the end.
    self->_IDLitVisualization::Move, oldPosition, newPosition

end

;----------------------------------------------------------------------------
; METHODNAME:
;   IDLitVisDataSpace::_CheckDimensionChange
;
; PURPOSE:
;   This procedure method determines whether the dimensionality of
;   this dataspace needs to be changed.  If so, the ::Set3D
;   method will be called with the appropriate new 3D setting.
;
;   This overrides the _IDLitVisualization implementation of this
;   method.  Special handling is required to ignore the wall and
;   axes.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpace::]_CheckDimensionChange
;
; SIDE EFFECTS:
;   If the dimensionality has changed, the ::Set3D method will
;   be called, causing the self.is3D field to be modified.
;-
pro IDLitVisDataSpace::_CheckDimensionChange

    compile_opt idl2, hidden

    case self.dimMethod of
        0: begin
            is3D = 0   ; Always 2D.
        end

        1: begin
            is3D = 1   ; Always 3D.
        end

        2: begin      ; Auto-compute based on contents.
            ; Walk the hierarchy searching for 3-dimensionality.
            is3D = 0
            oChildren = self->Get(/ALL, COUNT=nChild)
            for i=0,nChild-1 do begin
                oChild = oChildren[i]
                if (OBJ_ISA(oChild, '_IDLitVisualization')) then begin
                    ; Do not allow manipulator visuals, the background,
                    ; or the axes to impact dimensionality.
                    if (OBJ_ISA(oChild, 'IDLitManipulatorVisual')) then $
                        childIs3D = 0 $
                    else if (oChild eq self.oWall) then $
                        childIs3D = 0 $
                    else if (oChild eq self.oAxes) then $
                        childIs3D = 0 $
                    else $
                        childIs3D = oChild->Is3D()
                endif else begin
                    if (OBJ_ISA(oChild, 'IDLgrModel')) then begin
                        success = oChild->GetXYZRange(xRange, yRange, zRange)
                        if (success) then $
                            childIs3D = (zRange[0] eq zRange[1]) ? 0 : 1
                    endif else begin
                        oChild->GetProperty, ZRANGE=zRange
                    childIs3D = (zRange[0] eq zRange[1]) ? 0 : 1
                    endelse
                endelse
                if (childIs3D) then begin
                    is3D = 1
                    break
                endif
            endfor
        end
    endcase

    ; If necessary, update dimensionality.
    if (is3D ne self.is3D) then $
        self->Set3D, is3D
end

;----------------------------------------------------------------------------
; IIDLGraphicModel Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataSpace::GetXYZRange
;
; Purpose:
;   Override the GetXYZRange to retrieve the range either from
;   the viz group, or from the axes if the viz group is empty.
;-
function IDLitVisDataSpace::GetXYZRange, xRange, yRange, zRange, $
    NO_TRANSFORM=noTransform, INCLUDE_AXES=includeAxes, _EXTRA=_extra

    compile_opt idl2, hidden

    ; If we have anything within our viz group, then assume it has
    ; a valid range. Note: We don't want to include axes
    limit = 0
    if obj_valid(self.oAxes) then limit++
    if obj_valid(self.oWall) then limit++
    if (~KEYWORD_SET(includeAxes) && (self->count() gt limit)) then begin
        ; Get the range from our viz group.
        ; Note: we could also call our superclass. This is more efficient,
        ; but assumes that the DataSpace model only contains viz that
        ; do not impact the range (such as ManipulatorVisuals or Axes).
        success = self->_IDLitVisualization::GetXYZRange( $
            xRange, yRange, zRange, /DATA, NO_TRANSFORM=noTransform)
        if (success) then return, success
    endif

    ; If nothing within viz group, then force the range to come
    ; from the axes, even though they aren't supposed to impact range.
    return, self->_GetXYZAxisRange( $
        xRange, yRange, zRange, NO_TRANSFORM=noTransform)

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitvisDataSpace::OnDataChange
;
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
; CALLING SEQUENCE:
;      Obj->[IDLitvisDataSpace::]OnDataChange, oSubject
;
; INPUTS:
;   oSubject:  A reference to the object sending notification
;       of the data change.
;-
pro IDLitvisDataSpace::OnDataChange, oSubject

    compile_opt idl2, hidden

    ; Avoid recording data changes if locked.
    if (self._bLockDataChange eq 0) then $
        self->_IDLitVisualization::OnDataChange, oSubject
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitvisDataSpace::OnDataComplete
;
; PURPOSE:
;    The IDLitvisDataSpace::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oDataSpace->[IDLitvisDataSpace::]OnDataComplete, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data flush.
;
;-
pro IDLitvisDataSpace::OnDataComplete, oNotifier
    compile_opt idl2, hidden

    ; If data changes are locked, simply return.
    if (self._bLockDataChange ne 0) then $
        return

    ; Decrement the reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount--

    ; Return if more children have yet to report in.
    if (self.geomRefCount gt 0) then $
        return

    ; Walk the hierarchy to determine the original data XYZ ranges
    ; of objects according to how they impact axes.
    axisRangeValid = self->GetXYZRange( $
        axisXRange, axisYRange, axisZRange, /NO_TRANSFORM)

    oTool = self->GetTool()

    if (ISA(self,'_IDLitVisualization') && $
        self->_GetWindowandViewG(oWin, oViewG)) then begin
      titleID = iGetId((self->GetDataspace()).identifier+'/title',TOOL=oTool)
    endif else begin
      titleID = ''
    endelse

    if (ISA(oTool)) then $
      oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    if (titleID ne '') then begin
      oTitle = oTool->GetByIdentifier(titleID)
      if (ISA(oTitle)) then begin
        oTitle->GetProperty, TRANSFORM=tr
        self->VisToWindow, tr[3,0], tr[3,1], tr[3,2], xx, yy, zz
        titleLoc = [xx,yy,zz] 
      endif
    endif
         
    ; Update the XYZ ranges.
    if (axisRangeValid) then begin
        self->OnDataRangeChange, self, $
            axisXRange, axisYRange, axisZRange, /DATA_UPDATE, $
            /_WITHIN_DATA_COMPLETE, NOTIFIER=oNotifier
    endif

    ; Notify parent.
    self->IDLgrModel::GetProperty, PARENT=oParent
    if OBJ_VALID(oParent) then $
        oParent->OnDataComplete, oNotifier

    if (ISA(oTitle) && ISA(titleLoc)) then begin
      oTitle->GetProperty, TRANSFORM=tr
      self->WindowToVis, titleLoc[0], titleLoc[1], titleLoc[2], xx,yy,zz
      tr[3,0:2] = [xx,yy,zz]                                 
      oTitle->SetProperty, TRANSFORM=tr
    endif

    if (ISA(oTool) && ~wasDisabled) then $
      oTool->EnableUpdates
      
end

;---------------------------------------------------------------------------
; IIDLVisualization Interface
;---------------------------------------------------------------------------

;----------------------------------------------------------------------------
; IDLitVisDataSpace::Set3D
;
; Purpose:
;   This procedure method marks this visualization as being either 3D
;   or not 3D.
;
; Arguments:
;   Is3D: A boolean indicating whether this visualization should be marked
;     as being 3D. If this argument is not present, the visualization will
;     be marked as 3D.
; Keywords:
;   ALWAYS: Set this keyword to a non-zero value to indicate
;     that the given 3D setting always applies (as opposed to being
;     temporary).
;   AUTO_COMPUTE: Set this keyword to a non-zero value to
;     indicate that the 3D value for this visualization should be
;     auto-computed based upon the dimensionality of its contents.
;     This keyword is mutually exclusive of the ALWAYS keyword, and
;     if set, the Is3D argument is ignored.
pro IDLitVisDataSpace::Set3D, is3D, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute

    compile_opt idl2, hidden

    old3D = self.is3D

    new3D = (N_ELEMENTS(is3D) eq 0) ? 1b : is3D

    ; Call superclass.
    self->_IDLitVisualization::Set3D, new3D, $
             ALWAYS=always, AUTO_COMPUTE=autoCompute

    if (self.is3D ne old3D) then begin
        ; Change our type! Is this dangerous?
        self->IDLitVisDataSpace::SetProperty, $
            TYPE=self.is3D ? 'VOID_DATASPACE_3D' : 'VOID_DATASPACE_2D'

        ; Hide/Show registered properties for Z_* according
        ; to dimensionality.
        if (self->QueryProperty('Z_MINIMUM')) then begin
            self->SetPropertyAttribute, $
                ['Z_MINIMUM', 'Z_MAXIMUM', 'Z_AUTO_UPDATE', 'ZLOG'], $
                HIDE=~(self.is3D)
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::SetAxesRequest
;
; PURPOSE:
;   This procedure method marks this dataspace as either requesting
;   axes, or not.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpace::]SetAxesRequest[, axesRequest]
;
; INPUTS:
;   axesRequest:   A boolean indicating whether this visualization should
;     be marked as requesting axes.  If this argument is not present, the
;     visualization will be marked as requesting axes.
;
; KEYWORDS:
;   ALWAYS: Set this keyword to a non-zero value to indicate
;     that the given axes request always applies (as opposed to being
;     temporary).
;
;   AUTO_COMPUTE:   Set this keyword to a non-zero value to
;     indicate that the axes request for this visualization should be
;     auto-computed based upon the axes requests of its contents.
;     This keyword is mutually exclusive of the ALWAYS keyword, and
;     if set, the axesRequest argument is ignored.
;-
pro IDLitVisDataSpace::SetAxesRequest, axesRequest, $
    ALWAYS=always, $
    AUTO_COMPUTE=autoCompute

    compile_opt idl2, hidden

    ; Keep a copy of original setting.
    oldAxesRequest = self.axesRequest

    ; Call superclass, but add NO_NOTIFY keyword.
    self->_IDLitVisualization::SetAxesRequest, axesRequest, $
        ALWAYS=always, AUTO_COMPUTE=autoCompute, /NO_NOTIFY

    ; Check for change in axes request.
    if (OBJ_VALID(self.oAxes) && $
       (self.axesRequest ne oldAxesRequest)) then begin
        self.oAxes->GetProperty, STYLE=oldStyle
        if (self.axesRequest) then begin
            ; If the axes style was 'None', reset to the
            ; style requested by the visualization hierarchy.
            if (oldStyle eq 0) then begin
                style = self->GetRequestedAxesStyle()
                ; If no particular style requested, then use default=1.
                if (style lt 0) then $
                    style = 1
                self.oAxes->SetProperty, AXIS_STYLE=style
                self->DoOnNotify, self.oAxes->GetFullIdentifier(), $
                    "SETPROPERTY", "STYLE"
            endif
        endif else begin
            ; If the dataspace is now empty, leave the axes style
            ; unchanged.  Either:
            ;    a) the dataspace is the only one in the dataspace
            ;       root, in which case, it will most likely be
            ;       deleted; or,
            ;    b) another dataspace is present, so we do not
            ;       want to hide the axes associated with this one.
            oVis = self->GetVisualizations(COUNT=nVis)
            if (nVis ne 0) then begin
                ; If the axes style was anything other than 'None',
                ; reset to no axes.
                if (oldStyle ne 0) then begin
                    self.oAxes->SetProperty, AXIS_STYLE=0
                    self->DoOnNotify, self.oAxes->GetFullIdentifier(), $
                        "SETPROPERTY", "STYLE"
                endif
            endif
        endelse
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormSpace::SetAxesStyleRequest
;
; PURPOSE:
;   This procedure method sets the axes style request for this
;   dataspace.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataspace:]SetAxesStyleRequest[, styleRequest]
;
; INPUTS:
;   styleRequest:   A scalar representing the requested axes style.
;     Valid values include:
;       -1: this visualization no longer requests a particular axes style.
;       0-N: this visualization requests the corresponding style supported
;          by the IDLitVisDataAxes class.
;
; KEYWORDS:
;   NO_NOTIFY: Set this keyword to a non-zero value to indicate
;     that the parent should not be notified of a change in axes
;     style request.  By default, the parent is notified.
;-
pro IDLitVisDataSpace::SetAxesStyleRequest, styleRequest, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    ; Allow superclass to do most of the work, but do not notify
    ; the parent.
    self->_IDLitVisualization::SetAxesStyleRequest, styleRequest, $
        /NO_NOTIFY

    ; Handle notification of the change.
    self->OnAxesStyleRequestChange, self, styleRequest
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSapce::OnAxesStyleRequestChange
;
; PURPOSE:
;   This procedure method handles notification that the axes style request
;   of a contained object has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisDataSpace::]OnAxesRequestStyleChange, Subject, styleRequest
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the axes style request change.
;   styleRequest: new style request setting of Subject.
;-
pro IDLitVisDataSpace::OnAxesStyleRequestChange, oSubject, styleRequest

    compile_opt idl2, hidden

    if (self.axesRequest ne 0) then begin
        ; If axes are requested, then update the style if neccessary.
        newStyle = self->GetRequestedAxesStyle()
        ; If no particular style requested, then use default=1.
        if (newStyle lt 0) then $
          newStyle = 1
        self.oAxes->GetProperty, STYLE=oldStyle
        ; If more than one visualization exists, ignore requests to turn
        ; off axes  
        void = self->GetVisualizations(COUNT=cnt)
        if ((cnt gt 1) && (newStyle eq 0)) then $
          newStyle = oldStyle
        if (newStyle ne oldStyle) then begin
            self.oAxes->SetProperty, AXIS_STYLE=newStyle
            self->DoOnNotify, self.oAxes->GetFullIdentifier(), $
                "SETPROPERTY", "STYLE"
        endif
    endif

    ; Do not pass along to parent.
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::GetRequestedAxesStyle
;
; PURPOSE:
;   This function method returns a scalar indicating the style
;   requested by this visualization.  If none of the visualizations
;   in the hierarchy rooted at this visualization requested a particular
;   style, then -1 is returned.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]GetRequestedAxesStyle()
;
; OUTPUTS:
;   This function returns a scalar representing any of the non-zero
;   values supported by the IDLitVisDataAxes STYLE property, or
;   -1 to indicate that no specific request has been made.
;
;-
function IDLitVisDataSpace::GetRequestedAxesStyle

    compile_opt idl2, hidden

    if (self.doRequestAxesStyle) then $
        return, self.axesStyleRequest

    axesStyleRequest = -1
    oChildren = self->GetVisualizations(COUNT=nChild)
    for i=0,nChild-1 do begin
        oChild = oChildren[i]
        ; The children are known to be IDLitVisualizations, so
        ; no need to check before calling ::GetRequestedAxesStyle.
        childRequest = oChild->GetRequestedAxesStyle()

        ; Stop at first child with a request.
        if (childRequest ge 0) then begin
            axesStyleRequest = childRequest
            break
        endif
    endfor

    return, axesStyleRequest

end


;---------------------------------------------------------------------------
; IDLitVisDataSpace::GetVisualizations
;
; Purpose:
;   Override our superclass method so we can filter out the axes and walls.
;
; Keywords:
;    COUNT   - The number of items returned.
;
; Return Value:
;   An array of the visualizations contained in this container. If no
;   visualizations are contained, a null is returned.
;
function IDLitVisDataSpace::GetVisualizations, $
    COUNT=count, $
    FULL_TREE=fullTree

    compile_opt idl2, hidden

    oItems = self->_IDLitVisualization::GetVisualizations(COUNT=count, $
        FULL_TREE=fullTree)
    if (~count) then $
        return, oItems

    dex = where(oItems ne self.oAxes and $
                oItems ne self.oWall, count)

    ; Return all except the axes and the wall.
    return,(count gt 0 ? oItems[dex] : obj_new())

end


;;---------------------------------------------------------------------------
;; IDLitVisDataSpace::GetAxes
;;
;; Purpose:
;;   This routine will return all Axes contained in this
;;   axes container
;;
;; Keywords:
;;    CONTAINER - Set this keyword to a non-zero value to indicate
;;       that the axes container should be returned.  By default,
;;       the axes within the container are returned.
;;
;;    COUNT   - The number of items returned.
;;
;; Return Value:
;;   An array of the Axes contained in this container. If no
;;   axes are contained, a null is returned.
;;
function IDLitVisDataSpace::GetAxes, CONTAINER=container, COUNT=COUNT

    compile_opt idl2, hidden

    if(~obj_valid(self.oAxes))then begin
        count =0
        return, obj_new()
    endif

    if (KEYWORD_SET(container)) then begin
        count = 1
        return, self.oAxes
    endif

    oItems = self.oAxes->Get(/all, count=count)
    return, (count eq 0 ?  obj_new() : oItems)
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::GetDataSpace
;
; PURPOSE:
;   This function method retrieves the dataspace associated with
;   this object.  [Note: this implementation overrides the implementation
;   within the _IDLitVisualization class.]
;
; CALLING SEQUENCE:
;   oDataSpace = Obj->[IDLitVisDataSpace::]GetDataSpace()
;
; INPUTS:
;   None.
;
; KEYWORDS:
;   UNNORMALIZED:   Set this keyword to a non-zero value to indicate
;     that the returned dataspace should subclass from 'IDLitVisDataSpace'
;     rather than 'IDLitVisNormDataSpace'.
;
; OUTPUTS:
;   This function returns a reference to the dataspace associated
;   with this object, or a null object reference if no dataspace
;   is found.
;-
function IDLitVisDataSpace::GetDataSpace, $
    UNNORMALIZED=unNormalized

    compile_opt idl2, hidden

    if (KEYWORD_SET(unNormalized)) then $
        return, self $
    else begin
        ; Check if my parent is a normalize model.  If so,
        ; return my _PARENT (which should be an 'IDLitVisNormDataSpace').
        self->GetProperty, PARENT=oParent, _PARENT=my__parent
        if (OBJ_VALID(oParent) ne 0) then begin
            oParent->GetProperty, NAME=name
            if (name eq 'Normalize Model') then begin
                if (OBJ_ISA(my__Parent, 'IDLitVisNormDataSpace')) then $
                    return, my__parent
            endif
        endif

        ; Evidently, this dataspace is not contained by a
        ; normalizer, so just return myself.
        return, self
    endelse

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisDataSpace::GetDataSpaceRoot
;
; PURPOSE:
;   This function method retrieves the dataspace root that contains
;   this dataspace.
;
; CALLING SEQUENCE:
;   oDataSpaceRoot = Obj->[IDLitVisDataSpace::]GetDataSpaceRoot()
;
; INPUTS:
;   None.
;
; OUTPUTS:
;   This function returns a reference to the dataspace root associated
;   with this object, or a null object reference if no dataspace root
;   is found.
;-
function IDLitVisDataSpace::GetDataSpaceRoot

    compile_opt idl2, hidden

    ; Check if my parent is a normalize model.  If so, then my
    ; _PARENT should be an 'IDLitVisNormDataSpace'.  In this case,
    ; check the PARENT of the normalized dataspace to see if it is a
    ; dataspace root.
    self->GetProperty, PARENT=oParent, _PARENT=my__parent
    if (OBJ_VALID(oParent)) then begin
        oParent->GetProperty, NAME=name
        if (name eq 'Normalize Model') then begin
            if (OBJ_ISA(my__Parent, 'IDLitVisNormDataSpace')) then begin
                my__Parent->GetProperty, PARENT=oGrandParent
                if (OBJ_ISA(oGrandParent,'IDLitVisDataSpaceRoot')) then $
                    return, oGrandParent
            endif
        endif
        ; My parent is not a normalize model;  check if it is a dataspace
        ; root.
        if (OBJ_ISA(oParent, 'IDLitVisDataSpaceRoot')) then $
            return, oParent
    endif

    ; Evidently this dataspace (or its normalized parent) is not
    ; immediately contained within a dataspace root.
    return, OBJ_NEW()
end


;----------------------------------------------------------------------------
; PURPOSE:
;      Convert XY dataspace coordinates into actual data values.
;
; CALLING SEQUENCE:
;      strDataValue = Obj->GetDataString(xyz)
;
; RETURN VALUE:
;      String value representing the specified data values.
;
; INPUTS:
;      3 element vector containing X,Y and Z data coordinates.
;
; OUTPUTS:
;      A scalar string.
;
; KEYWORD PARAMETERS:
;      None.
;
function IDLitVisDataSpace::GetDataString, xyz

    compile_opt idl2, hidden

    if self._xLog then xyz[0] = 10^xyz[0]
    if self._yLog then xyz[1] = 10^xyz[1]
    if self._zLog then xyz[2] = 10^xyz[2]

    if (self->Is3D()) then begin
      xyz = STRCOMPRESS(STRING(xyz, FORMAT='(G11.4)'))
      return, STRING(xyz, FORMAT='("X: ", A, "  Y: ", A, "  Z: ", A)')
    endif

    xy = STRCOMPRESS(STRING(xyz[0:1], FORMAT='(G11.4)'))
    return, STRING(xy, FORMAT='("X: ",A,"  Y: ",A)')

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisDataSpace__Define
;
; Purpose:
;   Defines the object structure for an IDLitVisDataSpace object.
;-
PRO IDLitVisDataSpace__Define

    compile_opt idl2, hidden

    struct = { IDLitVisDataSpace,     $
        inherits _IDLitVisualization, $ ; Superclass: _IDLitVisualization
        inherits IDLitVisIDataSpace,  $ ; Interface: IDLitVisIDataSpace
        oWall: OBJ_NEW(),             $ ; Container for wall visualizations
        oTexture: OBJ_NEW(),          $ ; Texture for wall visualizations
        oAxes: OBJ_NEW(),             $ ; Container for axes visualizations
        _oMapProj: OBJ_NEW(),         $
        _xAutoUpdate: 0b,             $ ; Flag: auto-update x axis?
        _yAutoUpdate: 0b,             $ ; Flag: auto-update y axis?
        _zAutoUpdate: 0b,             $ ; Flag: auto-update z axis?
        _xLog: 0L,                    $ ; Flag: x axes log
        _yLog: 0L,                    $ ; Flag: y axes log
        _zLog: 0L,                    $ ; Flag: z axes log
        _xReverse: 0b,                $ ; Flag: reverse x axis?
        _yReverse: 0b,                $ ; Flag: reverse y axis?
        _zReverse: 0b,                $ ; Flag: reverse z axis?
        _bLockDataChange: 0b,         $ ; Flag: lock data changes
        _requiresDouble: 0b           $ ; Flag: requires double precision?
    }
END
