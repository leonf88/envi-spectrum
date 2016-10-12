; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniproirect__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipROIRect
;
; PURPOSE:
;   This class represents a manipulator for rectangular regions of interest.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROIRect::Init
;
; PURPOSE:
;   The IDLitManipROIRect::Init function method initializes the
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
;   Obj = OBJ_NEW('IDLitManipROIRect')
;
;    or
;
;   Obj->[IDLitManipROIRect::]Init
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
function IDLitManipROIRect::Init, $
    _REF_EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    ; Initialize superclass.
    iStatus = self->IDLitManipROI::Init( $
        IDENTIFIER='ROI_RECTANGLE', $
        NAME='ROI Rectangle', $
        /ALLOW_CONSTRAINT, $    ; Enable <Shift> & <Ctrl>
        /TRANSIENT_DEFAULT, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    return, 1
end


;--------------------------------------------------------------------------
; Manipulator Interface
;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
; METHOD_NAME:
;   IDLitManipROIRect::OnMouseDown
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
pro IDLitManipROIRect::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    compile_opt idl2, hidden

    if n_elements(noSelect) eq 0 then noSelect = 0

    ; Call our superclass.
    self->IDLitManipROI::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    ; Proceed only if left mouse button pressed.
    if (iButton ne 1) then return

    if (OBJ_VALID(self._oTargetVis) && $
        OBJ_VALID(self._oCurrentROI)) then begin
        ; Set a few properties on the newly created ROI.
        oROI = self._oCurrentROI
        oROI->SetProperty, NAME="Rectangle ROI", ICON='rectangl'

         ; Initialize as a single point.
        oROI->AppendData, self._initialXYZ[0], $
            self._initialXYZ[1], $
            self._initialXYZ[2]

        self._oTargetVis->Add, oROI

    endif
end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIRect::SubmitTargetVertex
;
; PURPOSE:
;   This procedure method submits the given vertex (in the dataspace
;   of the target visualization) to the current ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIRect::]SubmitTargetVertex, visX, visY, visZ
;
; INPUTS:
;   visX, visY, visZ:   The [x,y,z] location (in the dataspace of
;     the current target visualization) to be submitted to the
;     current ROI.
;-
pro IDLitManipROIRect::SubmitTargetVertex, visX, visY, visZ, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    x1 = visX
    y1 = visY
    z1 = visZ

    stylePoint = 0
    styleLine = 1
    styleClosed = 2

    bDoGrid = self._bSnapToGrid && self._bTargetIsGrid

    if (bDoGrid) then begin
        ; Use grid coordinates rather than geometry coordinates.
        x0 = self._initialGridLoc[0]
        y0 = self._initialGridLoc[1]

        x1 = gridLoc[0]
        y1 = gridLoc[1]

        ; For 3D targets, the Zs will be computed at the end.
        ; For 2D targets, the Zs are constant.
        if (~self._bTargetIs3D) then begin
            z0 = 0.0
            z1 = 0.0
        endif

        self._oTargetVis->_IDLitVisGrid2D::GetProperty, $
            GRID_DIMENSIONS=gridDims
        xRange = [0, gridDims[0]-1]
        yRange = [0, gridDims[1]-1]

    endif else begin
        x0 = self._initialXYZ[0]
        y0 = self._initialXYZ[1]
        z0 = (self._bTargetIs3D ? self._initialXYZ[2] : 0.0)

        x1 = visX
        y1 = visY
        z1 = visZ

        xrange = self._targetXRange
        yrange = self._targetYRange
    endelse

    if (self._bIsSymmetric) then begin
        ; Cache these in case we swap the order below.
        xCenter = x0
        yCenter = y0
    endif

    ; Swap order as needed.
    if (x0 gt x1) then begin
        swapX = x0
        x0 = x1
        x1 = swapX
    endif

    if (y0 gt y1) then begin
        swapY = y0
        y0 = y1
        y1 = swapY
    endif

    ; Don't allow lines of zero width.
    if ((x0 eq x1) && (y0 ne y1)) || ((y0 eq y1) && (x0 ne x1)) then $
        return

    if ((x0 eq x1) && (y0 eq y1)) then begin
        ; X and Y components are the same; display as a single point.
        ; We allow this so that the user can change their mind, shrink
        ; the ROI to a single point, and it will go away.
        newX = [x0]
        newY = [y0]
        if (~self._bTargetIs3D) then $
            newZ = [0.0]  ; For (gridded) 3D, newZ will be computed later.
        style = stylePoint
    endif else begin
        ; Display as a rectangle.

        if (self._bTargetIs3D) then begin
            ; In 3D case, vertices must be generated for each
            ; XY coordinate (since each may have a different
            ; Z value)

            ; Generate vertex list in grid coordinates.
            nXVert = (x1-x0) + 1
            nYVert = (y1-y0) + 1
            newX = [(DINDGEN(nXVert)+ x0), $
                    REPLICATE(x1, nYVert), $
                    (x1 - DINDGEN(nXVert)), $
                    REPLICATE(x0, nYVert)]

            newY = [REPLICATE(y0, nXVert), $
                    (DINDGEN(nYVert)+ y0), $
                    REPLICATE(y1, nXVert), $
                    (y1 - DINDGEN(nYVert))]

            ; newZ will be computed at the end.
        endif else begin

            if (self._bIsSymmetric) then begin
                halfwidth = ABS(DOUBLE(x1) - x0)
                halfheight = ABS(DOUBLE(y1) - y0)
                ; Check the clamping to the range again,
                ; just in case it changed from the GeometryToGrid
                ; in the OnMouseMotion.
                halfwidth <= (xCenter - xrange[0]) < (xrange[1] - xCenter)
                halfheight <= (yCenter - yrange[0]) < (yrange[1] - yCenter)
                ; Compute our new vertices.
                x0 = xCenter - halfwidth
                x1 = xCenter + halfwidth
                y0 = yCenter - halfheight
                y1 = yCenter + halfheight
            endif

            newX = [x0, x1, x1, x0]
            newY = [y0, y0, y1, y1]
            newZ = [0.0, 0.0, 0.0, 0.0]
        endelse
        style = styleClosed
    endelse

    if (bDoGrid) then begin
        ; Transform back to geometry coordinates.
        gridX = newX
        gridY = newY
        self._oTargetVis->GridToGeometry, $
            gridX, gridY, newX, newY, Z_VALUE=geomZ, /CENTER_ON_PIXEL

        if (self._bTargetIs3D) then $
           newZ = geomZ
    endif


    self._oCurrentROI->GetProperty, N_VERTS=nVerts
    self._oCurrentROI->ReplaceData, newX, newY, newZ, START=0, FINISH=nVerts-1
    self._oCurrentROI->SetProperty, STYLE=style


    ; Update the probe message.
    if (self._bTargetIs3D) then begin
    endif else begin
        if (style eq stylePoint) then begin
            self->ProbeStatusMessage, $
                STRING(newX[0], newY[0], FORMAT='(%"[%g, %g]")')
        endif else begin
            if (self._bIsSymmetric) then begin
                ; Symmetric about the center point.
                x00 = (newX[0]+newX[1])/2.
                y00 = (newY[1]+newY[2])/2.
            endif else begin
                ; Use the presence of the swapX/Y to indicate which point
                ; was the original corner.
                x00 = newX[(N_ELEMENTS(swapX) gt 0)]
                y00 = newY[(N_ELEMENTS(swapY) gt 0)+1]
            endelse
            self->ProbeStatusMessage, $
                STRING(x00, y00, $
                ABS(newX[1]-newX[0]), ABS(newY[2]-newY[1]), $
                FORMAT='(%"[%g, %g]   %g x %g")')
        endelse
    endelse

end


;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIRect::ValidateROI
;
; PURPOSE:
;   This function method determines whether the current ROI is
;   valid.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitManipROIRect::]ValidateROI()
;
; OUTPUTS:
;   This function returns a 1 if the current ROI is valid (i.e.,
;   may be committed), or a 0 if the ROI is invalid.
;-
function IDLitManipROIRect::ValidateROI
    ; pragmas
    compile_opt idl2, hidden

    if (OBJ_VALID(self._oTargetVis) && $
        OBJ_VALID(self._oCurrentROI)) then begin
        self._oCurrentROI->GetProperty, N_VERTS=nVerts
        if (nVerts ge 4) then begin
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
;   IDLitManipROIRect::Define
;
; PURPOSE:
;   Defines the object structure for an IDLitManipROIRect object.
;-
pro IDLitManipROIRect__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipROIRect,         $
        inherits IDLitManipROI         $ ; Superclass.
    }
end
