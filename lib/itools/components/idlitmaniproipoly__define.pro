; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniproipoly__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipROIPoly
;
; PURPOSE:
;   This class represents a manipulator for polygonal regions of interest.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROIPoly::Init
;
; PURPOSE:
;   The IDLitManipROIPoly::Init function method initializes the
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
;   Obj = OBJ_NEW('IDLitManipROIPoly')
;
;    or
;
;   Obj->[IDLitManipROIPoly::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function IDLitManipROIPoly::Init, $
    _REF_EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    ; Initialize our superclass.
    iStatus = self->IDLitManipROI::Init( $
        IDENTIFIER='ROI_POLYGON', $
        NAME='ROI Polygon', $
        /TRANSIENT_DEFAULT, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    self._oSegROI = OBJ_NEW('IDLanROI', TYPE=1)

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROIPoly::Cleanup
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
;   Obj->[IDLitManipROIPoly::]Cleanup
;
;-
pro IDLitManipROIPoly::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    OBJ_DESTROY, self._oSegROI

    self->IDLitManipROI::Cleanup
end

;--------------------------------------------------------------------------
; Manipulator Interface
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
; METHOD_NAME:
;   IDLitManipROIPoly::OnMouseDown
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
pro IDLitManipROIPoly::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    compile_opt idl2, hidden

    if n_elements(noSelect) eq 0 then noSelect = 0

    if (~self._bROIInitialized) then begin

        ; Call our superclass.
        self->IDLitManipROI::OnMouseDown, $
            oWin, x, y, iButton, KeyMods, nClicks, $
            NO_SELECT=noSelect

        ; Proceed only if left mouse button pressed.
        if (iButton ne 1) then $
            return

        if (OBJ_VALID(self._oTargetVis) && $
            OBJ_VALID(self._oCurrentROI)) then begin

            oROI = self._oCurrentROI

            ; Set a few properties on the newly created ROI.
            oROI->SetProperty, NAME="Polygon ROI", ICON='segpoly'

            self._oTargetVis->Add, oROI
            self._currSegment = [0, 1]

            visX = self._initialXYZ[0]
            visY = self._initialXYZ[1]
            visZ = (self._bTargetIs3D ? self._initialXYZ[2] : 0.0)

            ; Save this for use with 45deg constraint.
            self._currVisCoords = self._initialXYZ

            ; Add the first point.
            self._oCurrentROI->AppendData, visX, visY, visZ

            ; Now add a second "active" point on top of the first.
            self._oCurrentROI->AppendData, visX, visY, visZ
            self._bSegmentActive = 1b

        endif else $
            return
    endif else begin

        ; Proceed only if left mouse button pressed.
        if (iButton ne 1) then $
            return

        ; Convert window selection coordinates to target visualization
        ; coordinates.
        self->WindowToVis, oWin, x, y, visX, visY, visZ

        ; Check to see if mouse is within range for the target
        ; visualization.
        self._oTargetVis->GetProperty, XRANGE=xrange, YRANGE=yrange
        if (not ((visX ge xrange[0]) and (visX le xrange[1]) and $
                 (visY ge yrange[0]) and (visY le yrange[1]))) then $
            return

        ; Override initialXYZ with current point.
        self._initialXYZ = [visX, visY, visZ]

        ; If appropriate, snap to grid.
        if (self._bSnapToGrid and self._bTargetIsGrid) then begin
            ; Map geometry location to nearest grid location.
            self._oTargetVis->GeometryToGrid, visX, visY, $
                 gridX0, gridY0

            ; Get geometry at that nearest grid location.
            self._oTargetVis->GridToGeometry, $
                gridX0, gridY0, $
                visX, visY, Z_VALUE=geomZ, /CENTER_ON_PIXEL

            ; Set the z value appropriately based upon 3D flag.
            visZ = (self._bTargetIs3D ? geomZ : 0.0)

            ; Overwrite initial XYZ location with snapped-to-grid
            ; values.
            self._initialXYZ = [visX, visY, visZ]
            self._initialGridLoc = [gridX0, gridY0]

        endif

    endelse

    self._nClicks = nClicks

end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIPoly::OnMouseUp
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
pro IDLitManipROIPoly::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    ; Proceed only if left-mouse.
    if (iButton ne 1) then $
        return

    if (~self._bROIInitialized) then begin
        self->StatusMessage, IDLitLangCatQuery('Status:AnnotatePoly:Text2') + $
            STRING(176b) + IDLitLangCatQuery('Status:AnnotatePoly:Text3')
        self._bROIInitialized = 1b
        return
    endif

    ; If a segment is already active, mark it as no
    ; longer active. By doing this in OnMouseUp (instead of Down),
    ; we allow the user to start to click to complete a segment, and
    ; then drag the mouse. This matches the polygon annotation behavior.
    if (self._bSegmentActive) then begin
        self._bSegmentActive = 0
        self._currSegment[0] = self._currSegment[1]
    endif

    ; Proceed only if double-click.
    if (self._nClicks ne 2) then $
        return

    ; Call our superclass. This will commit the ROI object.
    self->IDLitManipROI::OnMouseUp, oWin, x, y, iButton

    ; Reset state.
    self._nClicks = 0
    self._bSegmentActive = 0
    self._bROIInitialized = 0
end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIPoly::OnMouseMotion
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
pro IDLitManipROIPoly::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden


    if (OBJ_VALID(self._oTargetVis) && $
        OBJ_VALID(self._oCurrentROI)) then begin

        ; Convert window selection coordinates to target visualization
        ; coordinates.
        self->WindowToVis, oWin, x, y, x1, y1, visZ

        x0 = self._currVisCoords[0]
        y0 = self._currVisCoords[1]


        ; <Shift> key constrains to 45 degree angles.
        if (KeyMods and 1) then begin
            xyDiff = [x1, y1] - [x0, y0]
            length = SQRT(xyDiff[0]^2 + xyDiff[1]^2)
            angle = (180/!DPI)*ATAN(xyDiff[1], xyDiff[0])
            angle = 45*ROUND(angle/45d)
            x1 = x0 + length*COS(angle*!DPI/180)
            y1 = y0 + length*SIN(angle*!DPI/180)
        endif


        ; Clamp the vertex to the XY Range of the target visualization.
        ; We do this clamping by clipping the intersection of the line
        ; with the edge. This is different from the other ROI's, which
        ; just truncate the X and Y separately. But we want our polygon
        ; lines to not change their angle when clipped.
        ;
        ; First clip the sides.
        offLeft = x1 lt self._targetXRange[0]
        if (offLeft || (x1 gt self._targetXRange[1])) then begin
            ratio = (self._targetXRange[offLeft ? 0 : 1] - x0)/(x1 - x0)
            x1 = self._targetXRange[offLeft ? 0 : 1]
            y1 = y0 + ratio*(y1 - y0)
        endif
        ; Now clip the top/bottom. These two clips could have been
        ; combined, but it's too tricky to figure out which side the
        ; line actually went thru, and this works fine.
        offBottom = y1 lt self._targetYRange[0]
        if (offBottom || (y1 gt self._targetYRange[1])) then begin
            ratio = (self._targetYRange[offBottom ? 0 : 1] - y0)/(y1 - y0)
            y1 = self._targetYRange[offBottom ? 0 : 1]
            x1 = x0 + ratio*(x1 - x0)
        endif

        ; Cache these for later, in case we need to save them.
        currVisCoords = [x1, y1]


        doGrid = self._bSnapToGrid && self._bTargetIsGrid

        gridLoc = [0,0]

        ; If appropriate, convert coordinates to grid location.
        if (doGrid) then begin
            geomX1 = x1
            geomY1 = y1
            self._oTargetVis->GeometryToGrid, x1, y1, $
                gridX, gridY

            gridLoc = [gridX, gridY]

            ; Get geometry at that nearest grid location.
            self._oTargetVis->GridToGeometry, gridX, gridY, $
                x1, y1, Z_VALUE=geomZ, /CENTER_ON_PIXEL

            ; Set the z value appropriately based upon 3D flag.
            z1 = (self._bTargetIs3D ? geomZ : 0.0)

        endif else z1 = (self._bTargetIs3D ? visZ : 0.0)

        ; Submit the resulting vertex
        self->IDLitManipROIPoly::SubmitTargetVertex, x1, y1, z1, $
            GRID_LOCATION=gridLoc, CURRENT_VISCOORDS=currVisCoords

        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; Purpose:
;   Implements the OnKeyBoard method.
;
; Arguments:
;   oWin        - Event Window Component
;   IsAlpha     - The the value a character or ASCII value?
;   Character   - The ASCII character of the key pressed.
;   KeyValue    - The value of the key pressed.
;                 1 - BS, 2 - Tab, 3 - Return
;
pro IDLitManipROIPoly::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

    compile_opt idl2, hidden

    if (~Release) then $
        return

    case Character of

        13: begin  ; <Return> finishes the polygon
            self._nClicks = 2
            self->IDLitManipROIPoly::OnMouseUp, oWin, x, y, 1
            end

        27: begin  ; <Esc> deletes the previous point
            ; Don't allow first vertex to be deleted.
            if (self._currSegment[0] eq 0) then $
                return
            ; Delete the previous vertex.
            count = self._currSegment[1]-self._currSegment[0]
            self._oCurrentROI->RemoveData, $
                START=self._currSegment[0]+1, $
                COUNT=count
            self._currSegment -= count
            ; Retrieve the previous point for use with 45deg constraint.
            self._oCurrentROI->GetProperty, DATA=data, N_VERTS=mycount
            self._currVisCoords = data[*, (mycount-2)>0]
            ; Call myself to update the ROI.
            self->IDLitManipROIPoly::OnMouseMotion, oWin, x, y, KeyMods
            end

        else: ; do nothing

    endcase

end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIPoly::_GetSegmentVerts
;
; PURPOSE:
;   This procedure method computes the vertices along the segment
;   from the stored XYZ point to the given point.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIPoly::]_GetSegmentVerts, x1, y1, z1, $
;       segX, segY, segZ
;
; INPUTS:
;   x1, y1, z1: The [x,y,z] location (in the dataspace of
;     the current target visualization) of the final vertex of
;     the segment.
;   segX, segY, segZ:   Named variables that upon return will
;     contain the the X, Y, and Z components of the vertices
;     along the segment.
;-
pro IDLitManipROIPoly::_GetSegmentVerts, x1, y1, z1, segX, segY, segZ, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    ; Note: Use existing technology to perform the XY line rasterization.
    ; Z values are retrieved for each XY vertex along the line.

    bDoGrid = self._bSnapToGrid and self._bTargetIsGrid
    if (bDoGrid) then begin
        ix0 = self._initialGridLoc[0]
        iy0 = self._initialGridLoc[1]

        ix1 = gridLoc[0]
        iy1 = gridLoc[1]
    endif else begin
        ix0 = self._initialXYZ[0]
        iy0 = self._initialXYZ[1]

        ix1 = x1
        iy1 = y1
    endelse

    ;; if ix[y]1 < ix[y]0 then swap values
    IF ix1 LT ix0 THEN ix1 XOR=(ix0 XOR=(ix1 XOR=ix0))
    IF iy1 LT iy0 THEN iy1 XOR=(iy0 XOR=(iy1 XOR=iy0))

    ; Translate to zero.
    shiftX1 = ix1 - ix0
    shiftY1 = iy1 - iy0
    nx = shiftX1 + 1
    ny = shiftY1 + 1

    self._oSegROI->SetProperty, DATA=[[0,0,0],[shiftX1,shiftY1,0]]
    mask = self._oSegROI->ComputeMask(DIMENSIONS=[nx,ny])

    ; Find where the mask is filled.
    indx = WHERE(mask ne 0, count)
    segX = (indx MOD nx) + ix0
    segY = (indx / nx) + iy0

    if (bDoGrid ne 0) then begin
        ; Translate back from grid index coordinates to geometry
        ; coordinates.
        segGridX = segX
        segGridY = segY
        self._oTargetVis->GridToGeometry, segGridX, segGridY, $
           segX, segY, Z_VALUE=segZ, /CENTER_ON_PIXEL
    endif else $
        segZ = FLTARR(N_ELEMENTS(segX))
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIPoly::SubmitTargetVertex
;
; PURPOSE:
;   This procedure method submits the given vertex (in the dataspace
;   of the target visualization) to the current ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIPoly::]SubmitTargetVertex, visX, visY, visZ
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
pro IDLitManipROIPoly::SubmitTargetVertex, visX, visY, visZ, $
    CURRENT_VISCOORDS=currVisCoords, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    x1 = visX
    y1 = visY
    z1 = visZ

    ; If a segment is currently active, replace its endpoint.
    ; Otherwise, append a vertex to create a segment.
    if (self._bSegmentActive) then begin

        ; Replace the endpoint of the currently active segment.
        if (self._bTargetIs3D) then begin
            ; In 3D case, vertices must be generated for each
            ; XY coordinate along the segment (since each may have
            ; a different Z value.
            self->_GetSegmentVerts, x1, y1, z1, segX, segY, segZ, $
                GRID_LOCATION=gridLoc
            self._oCurrentROI->ReplaceData, segX, segY, segZ, $
                START=self._currSegment[0], FINISH=self._currSegment[1]
            self._currSegment[1] = self._currSegment[0] + $
               N_ELEMENTS(segX) - 1

        endif else begin

            self._oCurrentROI->ReplaceData, x1, y1, z1

            ; Probe message.
            xyDiff = [x1, y1] - self._currVisCoords[0:1]
            length = SQRT(xyDiff[0]^2 + xyDiff[1]^2)
            angle = (180/!DPI)*ATAN(xyDiff[1], xyDiff[0])
            ; Round off to nice looking value.
            angle = LONG(((angle+360) mod 360)*100)/100d

            self->ProbeStatusMessage, $
                STRING(x1[0], y1[0], FLOAT(length), angle, $
                FORMAT='(%"[%g, %g]   %g   %g")') + STRING(176b)

        endelse

    endif else begin    ; not active, create new segment

        ; Set the final vertex of the (now-current) segment.
        if (self._bTargetIs3D) then begin

            ; In 3D case, vertices must be generated for each
            ; XY coordinate along the segment (since each may have
            ; a different Z value.
            self->_GetSegmentVerts, x1, y1, z1, segX, segY, segZ, $
                GRID_LOCATION=gridLoc
            self._currSegment[1] = self._currSegment[0] + $
               N_ELEMENTS(segX) - 1
            self._oCurrentROI->AppendData, segX, segY, segZ

        endif else begin

            self._currSegment[1] = self._currSegment[0] + 1
            self._oCurrentROI->AppendData, x1, y1, z1

        endelse

        ; Save this for use with 45deg constraint.
        self._currVisCoords = [x1, y1, z1]

        self._bSegmentActive = 1b

    endelse
end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIPoly::ValidateROI
;
; PURPOSE:
;   This function method determines whether the current ROI is
;   valid.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitManipROIPoly::]ValidateROI()
;
; OUTPUTS:
;   This function returns a 1 if the current ROI is valid (i.e.,
;   may be committed), or a 0 if the ROI is invalid.
;-
function IDLitManipROIPoly::ValidateROI
    ; pragmas
    compile_opt idl2, hidden

    if (OBJ_VALID(self._oTargetVis) and $
        OBJ_VALID(self._oCurrentROI)) then begin
        self._oCurrentROI->GetProperty, N_VERTS=nVerts
        if (nVerts ge 3) then begin
            ; Close the ROI, and return as valid.
            self._oCurrentROI->SetProperty, STYLE=2
            return, 1b
        endif
    endif

    return, 0b
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; NAME:
;   IDLitManipROIPoly::Define
;
; PURPOSE:
;   Defines the object structure for an IDLitManipROIPoly object.
;-
pro IDLitManipROIPoly__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipROIPoly,         $
        INHERITS IDLitManipROI,        $ ; Superclass.
        _nClicks: 0,                   $ ; Number of clicks on mouse down
        _bROIInitialized: 0b,          $ ; Flag; Has current ROI been init'd?
        _bSegmentActive: 0b,           $ ; Flag: is a segment active?
        _currVisCoords: DBLARR(3),      $ ; coords of previous vertex
        _currSegment: ULONARR(2),      $ ; Indices into ROI vertices
                                       $ ;   corresponding to the start and
                                       $ ;   finish of the current segment
        _oSegROI: OBJ_NEW()            $ ; ROI used to rasterize segments
    }
end
