; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniproi__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipROI
;
; PURPOSE:
;   This class represents a manipulator for creating regions of interest.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROI::Init
;
; PURPOSE:
;   The IDLitManipROI::Init function method initializes the
;   manipulator object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitManipROI')
;
;    or
;
;   Obj->[IDLitManipROI::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.  In addition, the following keywords
;   are supported:
;
;   NO_SNAP_TO_GRID:    Set this keyword to a non-zero value to indicate
;     that ROI vertices should not be snapped to the grid (if any) associated
;     with the target visualization.  By default, the ROI vertices are
;     snapped to the grid.
;
;   SHIFT_CONSTRAINT: Set this keyword to enable <Shift> key constraints
;     when creating the ROI.
;
;   TARGET_CLASSNAMES:  Set this keyword to a string (or vector of
;     strings) representing the classname(s) of visualization objects
;     that can have an ROI.  The default is 'IDLitVisImage'.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function IDLitManipROI::Init, $
    IDENTIFIER=inIdentifier, $
    NAME=inName, $
    NO_SNAP_TO_GRID=noSnapToGrid, $
    ALLOW_CONSTRAINT=bAllowConstraint, $
    TARGET_CLASSNAMES=targetClassnames, $
    _REF_EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    identifier = N_ELEMENTS(inIdentifier) ne 0 ? inIdentifier : 'ROI'
    name = N_ELEMENTS(inName) ne 0 ? inName : 'ROI'

    ; Initialize our superclass.
    iStatus = self->IDLitManipAnnotation::Init( $
        IDENTIFIER=identifier, $
        NAME=name, $
        NUMBER_DS='1', $
        _EXTRA=_extra)

    if (iStatus eq 0) then $
        return, 0

    self._bAllowConstraint = KEYWORD_SET(bAllowConstraint)

    self->InitTargetClassnames, TARGET_CLASSNAMES=targetClassnames

    self._bSnapToGrid = (N_ELEMENTS(noSnapToGrid) ne 0) ? $
        (1 - KEYWORD_SET(noSnapToGrid)) : 1b

    ; Register the default cursor for this manipulator.
    self->_DoRegisterCursor, identifier

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROI::Cleanup
;
; PURPOSE:
;   This procedure method preforms all cleanup on the object.
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
;   Obj->[IDLitManipROI::]Cleanup
;
;-
pro IDLitManipROI::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    PTR_FREE, self._pTargetClassnames

    self->IDLitManipAnnotation::Cleanup
end

;--------------------------------------------------------------------------
; Manipulator Interface
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
; METHOD_NAME:
;   IDLitManipROI::OnMouseDown
;
; PURPOSE:
;   This procedure method handles a mouse down event for this manipulator.
;
; INPUTS:
;   oWin:   A reference to the IDLitWindow object in which the
;     mouse event occurred.
;   x:      X coordinate of the mouse event.
;   y:      Y coordinate of the mouse event.
;   iButton:    An integer representing a mask for which button pressed
;   KeyMods:    An integer representing the keyboard modifiers for button
;   nClicks:    The number of times the mouse was clicked.
;-
pro IDLitManipROI::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    if n_elements(noSelect) eq 0 then noSelect = 0

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    ; If a current ROI is already in progress, then presumably
    ; the following work has already been done on a previous
    ; mouse down, so simply return.
    if (OBJ_VALID(self._oCurrentROI)) then $
        return

    ; Proceed only if left mouse button pressed.
    if (iButton ne 1) then $
        return

    ; Identify the target visualization (for which the ROI is to be
    ; defined).
    self->IdentifyTargetVisualization, oWin

    if (~OBJ_VALID(self._oTargetVis)) then $
        return
    oTargetVis = self._oTargetVis
    IF (~OBJ_ISA(oTargetVis, 'IDLitVisImage')) THEN $
        return
    self._bTargetIs3D = oTargetVis->Is3D()

    ; Cache the XYZ range of the target visualization.
    ; ROI vertices will be constrained to fit within these ranges.
    oTargetVis->GetProperty, XRANGE=targetXRange, $
        YRANGE=targetYRange, ZRANGE=targetZRange

    self._targetXRange = targetXRange
    self._targetYRange = targetYRange
    self._targetZRange = targetZRange

    ; Determine if the target visualization is a 2D grid.
    self._bTargetIsGrid = OBJ_ISA(self._oTargetVis, '_IDLitVisGrid2D')

    ; If the target visualization is in a 3D dataspace, then PickData
    ; will be used to collect the hit visualization locations (so that
    ; Z values can be appropriately identified).
    ;
    ; If the target visualization is in a 2D dataspace, then the inverse
    ; model-view transform will be utilized to collect the hit visualization
    ; locations, and z values will be presumed to be zero.
    ;
    oDataSpace = oTargetVis->GetDataSpace()
    if (~OBJ_VALID(oDataSpace)) then begin
        self->ErrorMessage, IDLitLangCatQuery('Error:RoiError:Text'), $
            TITLE=IDLitLangCatQuery('Error:RoiError:Title'), SEVERITY=2
        return
    endif

    if (oDataSpace->Is3D()) then begin
        self._bIn3DSpace = 1b

        ; The PickData will will be used to map window coordinates
        ; to target visualization coordinates.  Retrieve the view
        ; and stash it now.
        self._oCurrView = oTargetVis->_GetLayer()
    endif else begin
        self._bIn3DSpace = 0b

        ; Prepare a transform to map window selection coordinates to
        ; target visualization coordinates.
        ;
        ; This is the same as calling:
        ;   oTargetVis->_IDLitVisualization::WindowToVis, x, y, 0.0, $
        ;     datax, visY, void
        ; ...but the work is done explicitly here instead because
        ; the transform information needs to be cached for faster
        ; processing within the MouseMotion handler.

        ; Construct composite transform, starting with
        ; viewport location translation.
        if (not oTargetVis->_GetWindowandViewG(oWin, oViewG)) then $
            MESSAGE, IDLitLangCatQuery('Message:Framework:InvalidGrHeiarchy')
        iDimensions = oViewG->GetViewport(oWin, LOCATION=iLocation)
        iMatrix = IDENTITY(4, /DOUBLE)
        iMatrix[3,0] = -iLocation[0]
        iMatrix[3,1] = -iLocation[1]

        ; Transform to [-1,1] space
        tmat = IDENTITY(4, /DOUBLE)
        tmat[0,0] = 2d / iDimensions[0]
        tmat[1,1] = 2d / iDimensions[1]
        tmat[3,0] = -1
        tmat[3,1] = -1
        tmat[3,2] = -1

        ; Combine [-1,1] transform and inverse CTM - cache result.
        self._winToVisMatrix = (iMatrix # tmat) # $
            INVERT(oTargetVis->GetCTM(DESTINATION=oWin))
    endelse

    ; Convert window selection coordinates to target visualization
    ; coordinates.
    self->WindowToVis, oWin, x, y, visX, visY, visZ

    ; Check to see if mouse is within range for the target visualization.
    oTargetVis->GetProperty, XRANGE=xrange, YRANGE=yrange
    if ((visX ge self._targetXRange[0]) && $
        (visX le self._targetXRange[1]) && $
        (visY ge self._targetYRange[0]) && $
        (visY le self._targetYRange[1])) then begin

        if (~OBJ_VALID(self._oCurrentROI)) then begin

            ; Create new ROI.
            oTool = self->GetTool()
            oDesc = oTool->GetAnnotation('ROI')
            if (~OBJ_VALID(oDesc)) then begin
                ; The name changed in IDL62 from Polygonal ROI, so look
                ; for the old name just in case.
                oDesc = oTool->GetAnnotation('Polygonal ROI')
                if (~OBJ_VALID(oDesc)) then $
                    return
            endif
            oROI = oDesc->GetObjectInstance()
            if (~OBJ_VALID(oROI)) then $
                return
            oROI->SetProperty, STYLE=1
            if (self._bTargetIs3D) then $
                oROI->Set3D
            self._oCurrentROI = oROI
        endif

        ; Store initial XYZ location.
        self._initialXYZ = [visX, visY, (self._bTargetIs3D ? visZ : 0d)]

        ; If appropriate, store corresponding grid location.
        if (self._bSnapToGrid && self._bTargetIsGrid) then begin
            ; Map geometry location to nearest grid location.
            self._oTargetVis->GeometryToGrid, visX, visY, $
                gridX0, gridY0

            ; Get geometry at that nearest grid location.
            self._oTargetVis->GridToGeometry, $
                gridX0, gridY0, $
                x0, y0, Z_VALUE=geomZ, /CENTER_ON_PIXEL

            ; Set the z value appropriately based upon 3D flag.
            z0 = (self._bTargetIs3D ? geomZ : 0.0)

            ; Overwrite initial XYZ location with snapped-to-grid
            ; values.
            self._initialXYZ = [x0,y0,z0]
            self._initialGridLoc = [gridX0, gridY0]
        endif

        ; NOTE: The ROI is not added to the target visualization
        ; at this time.  It is expected that a subclass will
        ; handle the addition:
        ;     oTargetVis->Add, oROI

    endif   ; in range

end

;--------------------------------------------------------------------------
; METHOD_NAME:
;   IDLitManipROI::OnMouseUp
;
; PURPOSE:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; PARAMETERS:
;   oWin:   Source of the event
;   x:      X coordinate
;   y:      Y coordinate
;   iButton:    Mask for which button released
;-
pro IDLitManipROI::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    ; Proceed only if left mouse button released.
    if (iButton eq 1) then begin
        if (self->ValidateROI() ne 0) then begin
            ; Create a data object to store the vertices, and
            ; set it as the VERTICES parameter on the ROI.
            oData = OBJ_NEW("IDLitData", NAME='Vertices', $
                TYPE='IDLVERTEX', ICON='segpoly')
            if (OBJ_VALID(oData) ne 0) then begin
                success = oData->GetData(pData, /POINTER)
                if (success) then begin
                    self._oCurrentROI->GetProperty, DATA=ROIData
                    *pData = ROIData
                    success = self._oCurrentROI->SetData(oData, $
                        PARAMETER_NAME='VERTICES', /NO_UPDATE)
                    if (success) then begin
                       oTool = self->GetTool()
                       oTool->AddByIdentifier, "/Data Manager", oData
                        self->CommitAnnotation, self._oCurrentROI
                    endif
                endif
            endif
        endif else begin
            ; Remove degenerate ROI.
            if (OBJ_VALID(self._oTargetVis) and $
                OBJ_VALID(self._oCurrentROI)) then $
                self._oTargetVis->Remove, self._oCurrentROI
            OBJ_DESTROY, self._oCurrentROI
            self->CancelAnnotation
        endelse

        ; Reset for next time.
        self._oCurrView = OBJ_NEW()
        self._oCurrentROI = OBJ_NEW()
        self._oTargetVis = OBJ_NEW()
    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROI::OnMouseMotion
;
; PURPOSE:
;   This procedure method handles a mouse motion event for this manipulator.
;
; INPUTS:
;   oWin:   A reference to the IDLitWindow object in which the
;     mouse event occurred.
;   x:      X coordinate of the mouse event.
;   y:      Y coordinate of the mouse event.
;   KeyMods:    An integer representing the keyboard modifiers
;
;-
pro IDLitManipROI::OnMouseMotion, oWin, x, y, KeyMods
    ; pragmas
    compile_opt idl2, hidden


    if (OBJ_VALID(self._oTargetVis) && $
        OBJ_VALID(self._oCurrentROI)) then begin

        ; Convert window selection coordinates to target visualization
        ; coordinates.
        self->WindowToVis, oWin, x, y, x1, y1, visZ

        ; Check for <Ctrl> key constraint.
        self._bIsSymmetric = self._bAllowConstraint && (KeyMods and 2)

        if (self._bIsSymmetric) then begin

            ; If symmetric about the starting point, we need to do the
            ; clamping such that the entire symmetric ROI will fit
            ; within the viz range.
            x0 = self._initialXYZ[0]
            y0 = self._initialXYZ[1]

            ; Total width & height.
            width = ABS(x1 - x0)
            height = ABS(y1 - y0)

            ; Clamp width & height so that the entire ROI will fit.
            width <= (x0 - self._targetXRange[0]) < $
                (self._targetXRange[1] - x0)
            height <= (y0 - self._targetYRange[0]) < $
                (self._targetYRange[1] - y0)

            ; New corner point.
            x1 = (x1 gt x0) ? x0 + width : x0 - width
            y1 = (y1 gt y0) ? y0 + height : y0 - height

        endif else begin
            ; Not symmetric.
            ; Clamp the vertex to the XY Range of the target visualization.
            x1 = (self._targetXRange[0] > x1) < self._targetXRange[1]
            y1 = (self._targetYRange[0] > y1) < self._targetYRange[1]
        endelse


        doGrid = self._bSnapToGrid && self._bTargetIsGrid

        ; Check for <Shift> key constraint.
        doShiftKey = self._bAllowConstraint && (KeyMods and 1)


        if (doShiftKey) then begin
            if (doGrid) then begin
                self._oTargetVis->_IDLitVisGrid2D::GetProperty, $
                    GRID_STEP=gridStep
            endif
            ; For non-gridded, we just want to handle the constraint here.
            ;
            ; For gridded, if the aspect ratio is not 1:1, we also want
            ; to handle the constraint here, before calling GeometryToGrid,
            ; so that we end up with a square (or circle).
            ;
            ; If the aspect ratio is 1:1, we *could* handle it here,
            ; but it is better to handle it after calling GeometryToGrid
            ; to avoid roundoff errors. Otherwise, we can end up with an
            ; extra row or column in the ROI.
            if (~doGrid || (gridStep[0] ne gridStep[1])) then begin
                x0 = self._initialXYZ[0]
                y0 = self._initialXYZ[1]
                dx = ABS(x1 - x0)
                dy = ABS(y1 - y0)
                ; Note that this constrains both X and Y dimensions to be the
                ; smaller of the two, instead of the larger
                ; (like the rectangle annotation). This is because we are
                ; clamping our vertices to the XY viz range, and we still
                ; want a square (or circle) after the clamping occurs.
                if (dx ge dy) then begin
                    x1 = x0 + ((x1 gt x0) ? dy : -dy)
                endif else begin
                    y1 = y0 + ((y1 gt y0) ? dx : -dx)
                endelse
                doShiftKey = 0b  ; We're done with the constraint.
            endif
        endif  ; <Shift> key


        gridLoc = [0,0]

        ; If appropriate, convert coordinates to grid location.
        if (doGrid) then begin
            geomX1 = x1
            geomY1 = y1
            self._oTargetVis->GeometryToGrid, x1, y1, $
                gridX, gridY

            ; <Shift> key creates a square. This is only called if the
            ; shift constraint is on, and we havn't already handled the
            ; constraint above. This is the case for grids with a
            ; 1:1 aspect ratio (see comments above for details).
            if (doShiftKey) then begin
                x0 = LONG(self._initialGridLoc[0])
                y0 = LONG(self._initialGridLoc[1])
                dx = ABS(LONG(gridX - x0))
                dy = ABS(LONG(gridY - y0))
                ; Note that this constrains both X and Y dimensions to be the
                ; smaller of the two, instead of the larger
                ; (like the rectangle annotation). This is because we are
                ; clamping our vertices to the XY viz range, and we still
                ; want a square (or circle) after the clamping occurs.
                if (dx ge dy) then begin
                    gridX = x0 + ((gridX gt x0) ? dy : -dy)
                endif else begin
                    gridY = y0 + ((gridY gt y0) ? dx : -dx)
                endelse
            endif

            gridLoc = [gridX, gridY]

            ; Get geometry at that nearest grid location.
            self._oTargetVis->GridToGeometry, gridX, gridY, $
                x1, y1, Z_VALUE=geomZ, /CENTER_ON_PIXEL

            ; Set the z value appropriately based upon 3D flag.
            z1 = (self._bTargetIs3D ? geomZ : 0.0)

        endif else z1 = (self._bTargetIs3D ? visZ : 0.0)

        ; Submit the resulting vertex
        self->SubmitTargetVertex, x1, y1, z1, GRID_LOCATION=gridLoc

        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;  IDLitManipROI::InitTargetClassnames
;
; PURPOSE:
;   This procedure method prepares the list of classnames of visualization
;   objects that can have ROIs.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManpROI::]InitTargetClassnames
;
; KEYWORD PARAMETERS:
;   TARGET_CLASSNAMES:  Set this keyword to a string (or vector of
;     strings) representing the classname(s) of visualization objects
;     that can have an ROI.  The default is 'IDLitVisImage'.
;-
pro IDLitManipROI::InitTargetClassnames, $
    TARGET_CLASSNAMES=targetClassnames

    compile_opt idl2, hidden

    if (N_ELEMENTS(targetClassnames) ne 0) then $
        self._pTargetClassnames = PTR_NEW(targetClassnames) $
    else $
        self._pTargetClassnames = PTR_NEW(["IDLitVisImage","IDLitVisSurface"])
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;  IDLitManipROI::IdentifyTargetVisualization
;
; PURPOSE:
;   This procedure method determines which visualization should
;   be treated as the target for ROI create.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManpROI::]IdentifyTargetVisualization, oWin
;
; INPUTS:
;   oWin:   A reference to the window object in which the
;      ROI manipulation is occurring.
;-
pro IDLitManipROI::IdentifyTargetVisualization, oWin

    compile_opt idl2, hidden

    ; Retrieve unfiltered list of selected items.
    oSelected = oWin->GetSelectedItems()
    nSel = N_ELEMENTS(oSelected)

    ; Ensure a list of target classnames is prepared.
    if (PTR_VALID(self._pTargetClassnames) ne 0) then begin
        targetClassnames = STRUPCASE(*self._pTargetClassnames)
        nTargetClassnames = N_ELEMENTS(targetClassnames)
    endif else $
        nTargetClassnames = 0

    if (nTargetClassnames eq 0) then begin
        targetClassnames = ['IDLITVISIMAGE']
        nTargetClassnames = 1
    endif

    ; Find the first visualization (among the selected items) that
    ; matches one of the requested target classnames.
    nMatch = 0
    for i=0,nSel-1 do begin
        selectedClassnames = OBJ_CLASS(oSelected[i])
        for j=0,nTargetClassnames-1 do begin
            ind = WHERE(selectedClassnames eq targetClassnames[j], count)
            if (count gt 0) then begin
               iSel = i
               nMatch = count
               break
            endif
        endfor
        if (nMatch gt 0) then $
            break
    endfor

    if (nMatch gt 0) then begin
        ; Choose the first matched target in the selection list.
        oTargetVis = oSelected[iSel]
        self._oTargetVis = oTargetVis
    endif else $
        self._oTargetVis = OBJ_NEW()
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROI::WindowToVis
;
; PURPOSE:
;   This procedure method converts the given window selection coordinate
;   to the corresponding target visualization coordinate.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROI::]WindowToVis, oWin, winX, winY, visX, visY, visZ
;
; INPUTS:
;   oWin:   A reference to the window object.
;   winX, winY: The [x,y] window location in device coordinates.
;   visX, visY, visZ:   Named variables that upon return will contain
;     the [x,y,z] target visualization coordinate corresponding to the
;     given window coordinate.
;-
pro IDLitManipROI::WindowToVis, oWin, winX, winY, visX, visY, visZ

    compile_opt idl2, hidden

    if (self._bIn3DSpace ne 0) then begin
        hit = oWin->PickData(self._oCurrView, self._oTargetVis, $
            [winX, winY], visLoc)
        visX = visLoc[0]
        visY = visLoc[1]
        visZ = visLoc[2]
    endif else begin
        ; Apply window-to-visualization transformation matrix.
        pt = [winX, winY, 0d, 1d] # self._winToVisMatrix
        if pt[3] NE 0.0 then $
            pt = pt / pt[3]
        visX = pt[0]
        visY = pt[1]
        visZ = 0.0
    endelse
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROI::SubmitTargetVertex
;
; PURPOSE:
;   This procedure method submits the given vertex (in the dataspace
;   of the target visualization) to the current ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROI::]SubmitTargetVertex, visX, visY, visZ
;
; INPUTS:
;   visX, visY, visZ:   The [x,y,z] location (in the dataspace of
;     the current target visualization) to be submitted to the
;     current ROI.
;
; KEYWORD PARAMETERS:
;   GRID_LOCATION:  A 2-element vector, [ix,iy], representing
;     the grid location that corresponds to the given visX,visY,visZ
;     values.  (Note: if the target visualization is not snapping to
;     a grid, this vector will be [0,0].)
;-
pro IDLitManipROI::SubmitTargetVertex, visX, visY, visZ, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    self._oCurrentROI->AppendData, visX, visY, visZ
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROI::ValidateROI
;
; PURPOSE:
;   This function method determines whether the current ROI is
;   valid.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitManipROI::]ValidateROI()
;
; OUTPUTS:
;   This function returns a 1 if the current ROI is valid (i.e.,
;   may be committed), or a 0 if the ROI is invalid.
;-
function IDLitManipROI::ValidateROI
    ; pragmas
    compile_opt idl2, hidden

    return, OBJ_VALID(self._oTargetVis) and OBJ_VALID(self._oCurrentROI)
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROI:_DoRegisterCursor
;
; PURPOSE:
;   This procedure method registers the cursor to be associated with
;   this manipulator.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROI::]_DoRegisterCursor, strName
;
; INPUTS:
;   strName:    A string representing the name to be associated
;     with the cursor.
;-
pro IDLitManipROI::_DoRegisterCursor, strName

    compile_opt idl2, hidden

    strArray = [ $
        '      ...       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '.......#....... ', $
        '.######$######. ', $
        '.......#....... ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      ...       ', $
        '                ']

    self->RegisterCursor, strArray, strName, /DEFAULT

end


;-------------------------------------------------------------------------
; IDLitManipROI::QueryAvailability
;
; Purpose:
;   This function method determines whether this object is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if the object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function IDLitManipROI::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Use our superclass as a first filter.
    ; If not available by matching types, then no need to continue.
    success = self->IDLitManipulator::QueryAvailability(oTool, selTypes)
    if (~success) then $
        return, 0

    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then $
        return, 0

    ; If our dataspace has a map projection, then we can't do ROIs.
    for i=0,nSelVis-1 do begin
        oDataSpace = oSelVis[i]->GetDataSpace()
        if (N_TAGS(oDataSpace->GetProjection()) gt 0) then $
            return, 0
    endfor

    return, 1

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; NAME:
;   IDLitManipROI::Define
;
; PURPOSE:
;   Defines the object structure for an IDLitManipROI object.
;-
pro IDLitManipROI__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipROI,         $
        INHERITS IDLitManipAnnotation, $ ; This is an annotation manipulator
        _oCurrView: OBJ_NEW(),         $ ; Reference to current view.
        _oCurrentROI: OBJ_NEW(),       $ ; ROI we are currently drawing
        _pTargetClassnames: PTR_NEW(), $ ; Ptr to vector of classnames of
                                       $ ;  visualization objects that can
                                       $ ;  have ROIs.
        _oTargetVis: OBJ_NEW(),        $ ; Reference to current target
                                       $ ;  visualization.
        _initialXYZ: DBLARR(3),        $ ; Target visualization's XYZ location
                                       $ ;  at initial mouse down
        _targetXRange: DBLARR(2),      $ ; X Range of target visualization
        _targetYRange: DBLARR(2),      $ ; Y Range of target visualization
        _targetZRange: DBLARR(2),      $ ; Z Range of target visualization
        _initialGridLoc: ULONARR(2),   $ ; Grid XY location of initial mouse
                                       $ ;  down
        _winToVisMatrix: DBLARR(4,4),  $ ; Cached window to image transform
        _bIn3DSpace: 0b,               $ ; Flag: is target dataspace 3D?
        _bTargetIs3D: 0b,              $ ; Flag: is target vis 3D?
        _bTargetIsGrid: 0b,            $ ; Flag: is target vis a grid?
        _bSnapToGrid: 0b,              $ ; Flag: snap vertices to grid?
        _bAllowConstraint: 0b,         $ ; Allow <Shift> constraint or not
        _bIsSymmetric: 0b              $ ; Use symmetric constraint
    }
end
