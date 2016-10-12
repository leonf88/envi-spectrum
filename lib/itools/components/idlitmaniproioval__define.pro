; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniproioval__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipROIOval
;
; PURPOSE:
;   This class represents a manipulator for oval regions of interest.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipROIOval::Init
;
; PURPOSE:
;   The IDLitManipROIOval::Init function method initializes the
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
;   Obj = OBJ_NEW('IDLitManipROIOval')
;
;    or
;
;   Obj->[IDLitManipROIOval::]Init
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
function IDLitManipROIOval::Init, $
    _REF_EXTRA=_extra

    ; pragmas
    compile_opt idl2, hidden

    ; Initialize superclass.
    iStatus = self->IDLitManipROI::Init( $
        IDENTIFIER='ROI_OVAL', $
        NAME='ROI Oval', $
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
;   IDLitManipROIOval::OnMouseDown
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
pro IDLitManipROIOval::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    compile_opt idl2, hidden

    if n_elements(noSelect) eq 0 then noSelect = 0

    ; Call our superclass.
    self->IDLitManipROI::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks, $
        NO_SELECT=noSelect

    ; Proceed only if left mouse button pressed.
    if (iButton ne 1) then return

    if (OBJ_VALID(self._oTargetVis) and $
        OBJ_VALID(self._oCurrentROI)) then begin
        ; Set a few properties on the newly created ROI.
        oROI = self._oCurrentROI
        oROI->SetProperty, NAME="Oval ROI", ICON='ellipse'

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
;   IDLitManipROIOval::SubmitTargetVertex
;
; PURPOSE:
;   This procedure method submits the given vertex (in the dataspace
;   of the target visualization) to the current ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitManipROIOval::]SubmitTargetVertex, visX, visY, visZ
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
pro IDLitManipROIOval::SubmitTargetVertex, visX, visY, visZ, $
    GRID_LOCATION=gridLoc

    ; pragmas
    compile_opt idl2, hidden

    stylePoint = 0
    styleLine = 1
    styleClosed = 2

    bDoGrid = self._bSnapToGrid and self._bTargetIsGrid

    if (bDoGrid ne 0) then begin
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
        z0 = self._initialXYZ[2]

        x1 = visX
        y1 = visY
        z1 = (self._bTargetIs3D ? visZ : 0.0)

        xrange = self._targetXRange
        yrange = self._targetYRange
    endelse

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

        ; Display as an oval.
        horizRad = ABS(DOUBLE(x1)-x0)
        vertRad = ABS(DOUBLE(y1)-y0)

        if (self._bIsSymmetric) then begin
            ; The oval is symmetric about the starting location.
            xCenter = x0
            yCenter = y0
            ; Check the clamping to the range again,
            ; just in case it changed from the GeometryToGrid
            ; in the OnMouseMotion.
            horizRad <= (x0 - xrange[0]) < (xrange[1] - x0)
            vertRad <= (y0 - yrange[0]) < (yrange[1] - y0)
        endif else begin
            ; If we are fitting the oval within our (x0,y0),(x1,y1) box,
            ; we need to divide the radius by 2, and adjust the center.
            horizRad /= 2
            vertRad /= 2
            xCenter = (DOUBLE(x0) + x1)/2
            yCenter = (DOUBLE(y0) + y1)/2
        endelse

        ; Number of vertices is dependent upon the greater
        ; of the two radii.
        nPts = (horizRad > vertRad) * 4
        ; For plot roi, data coordinates could result in only single point
        ; add some more so the small circle looks better
        if (bDoGrid eq 0) then $
            nPts = npts > 10

        a = DINDGEN(nPts) * ( (2 * !PI) / nPts )
        newX = COS(a) * horizRad + xCenter
        newY = SIN(a) * vertRad + yCenter
        if (~self._bTargetIs3D) then $
            newZ = REPLICATE(0.0, nPts)
        ; if (bTargetis3D) then:  newZ will be computed at the end.
        style = styleClosed

    endelse

    if (bDoGrid ne 0) then begin
        ; Transform back to geometry coordinates.
        gridX = newX
        gridY = newY
        self._oTargetVis->GridToGeometry, $
            gridX, gridY, newX, newY, Z_VALUE=geomZ, /CENTER_ON_PIXEL

        if (self._bTargetIs3D) then $
           newZ = geomZ
    endif

    self._oCurrentROI->GetProperty, N_VERTS=nVerts
    self._oCurrentROI->ReplaceData, newX, newY, newZ, $
        START=0, FINISH=nVerts-1
    self._oCurrentROI->SetProperty, STYLE=style


    ; Update the probe message.
    if (self._bTargetIs3D) then begin
    endif else begin
        if (style eq stylePoint) then begin
            self->ProbeStatusMessage, $
                STRING(newX[0], newY[0], FORMAT='(%"[%g, %g]")')
        endif else begin
            minX = MIN(newX, MAX=maxX)
            minY = MIN(newY, MAX=maxY)
            x00 = (x0 le x1) ? minX : maxX
            y00 = (y0 le y1) ? minY : maxY
            self->ProbeStatusMessage, $
                STRING(x00, y00, maxX-minX, maxY-minY, $
                FORMAT='(%"[%g, %g]   %g x %g")')
        endelse
    endelse

end

;--------------------------------------------------------------------------
;+
; METHOD_NAME:
;   IDLitManipROIOval::ValidateROI
;
; PURPOSE:
;   This function method determines whether the current ROI is
;   valid.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitManipROIOval::]ValidateROI()
;
; OUTPUTS:
;   This function returns a 1 if the current ROI is valid (i.e.,
;   may be committed), or a 0 if the ROI is invalid.
;-
function IDLitManipROIOval::ValidateROI
    ; pragmas
    compile_opt idl2, hidden

    if (OBJ_VALID(self._oTargetVis) and $
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
;   IDLitManipROIOval::Define
;
; PURPOSE:
;   Defines the object structure for an IDLitManipROIOval object.
;-
pro IDLitManipROIOval__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipROIOval,         $
        inherits IDLitManipROI         $ ; Superclass.
    }
end
