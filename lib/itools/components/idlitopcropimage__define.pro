; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopcropimage__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Class Name:
;   IDLitopCropImage
;
; Purpose:
;   This class implements an image cropping operation.
;
;----------------------------------------------------------------------------
; Lifecycle Routines
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; IDLitopCropImage::Init
;
; Purpose:
;   This function method initializes the crop operation object.
;
; Return Value:
;   This funtion returns a 1 on success, or 0 otherwise.
;
;-------------------------------------------------------------------------
function IDLitopCropImage::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    if (self->IDLitDataOperation::Init(NAME="Crop", $
        DESCRIPTION='IDL Crop operation', $
        TYPES=["IDLIMAGE"], $
        NUMBER_DS='1', $
        /SHOW_EXECUTION_UI, $
        /SKIP_MACRO, $
        _EXTRA=_extra) eq 0) then $
        return, 0

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ; Register properties.
    self->RegisterProperty, 'X', /FLOAT, $
        NAME='X', $
        Description='Crop box origin x'

    self->RegisterProperty, 'Y', /FLOAT, $
        NAME='Y', $
        Description='Crop box origin y'

    self->RegisterProperty, 'WIDTH', /FLOAT, $
        NAME='Width', $
        Description='Crop box width'

    self->RegisterProperty, 'HEIGHT', /FLOAT, $
        NAME='Height', $
        Description='Crop box height'

    self->RegisterProperty, 'UNITS', $
        ENUMLIST=['Data', 'Pixel'], $
        NAME='Units', $
        DESCRIPTION='Units of measure for crop box'

    return, 1
end

;-------------------------------------------------------------------------
; IDLitopCropImage::Cleanup
;
; Purpose:
;   The destructor of the IDLitopCropImage object.
;
;-------------------------------------------------------------------------
pro IDLitopCropImage::Cleanup
    compile_opt idl2, hidden

    ; Clear out any vestigal commands to crop dependents.
    if (OBJ_VALID(self._oSubCropCmds)) then begin
        oCmds = self._oSubCropCmds->Get(/ALL, COUNT=nCmds)
        if (nCmds gt 0) then begin
            self._oSubCropCmds->Remove, oCmds
            OBJ_DESTROY, oCmds
        endif
        OBJ_DESTROY, self._oSubCropCmds
    endif

    self->IDLitDataOperation::Cleanup
end


;---------------------------------------------------------------------------
; IDLitopCropImage::GetProperty
;
; Purpose:
;   This procedure method retrieves the value(s) of one or more properties.
;
pro IDLitopCropImage::GetProperty, $
    HEIGHT=height, $
    UNITS=units, $
    WIDTH=width, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(x) || $
        ARG_PRESENT(y) || $
        ARG_PRESENT(width) || $
        ARG_PRESENT(height)) then begin
        oTool = self->GetTool()
        oTarget = OBJ_NEW()
        if (OBJ_VALID(oTool)) then begin
            oSelVis = oTool->GetSelectedItems()
            oTarget = (self->_GetImageTargets(oSelVis))[0]
        endif
        if (OBJ_VALID(oTarget)) then $
            oTarget->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep $
        else $
            gridStep = [1.0,1.0]

        halfPixel = gridStep*0.5
    endif

    if (ARG_PRESENT(height)) then begin
        if (self._units eq 1) then begin
            ; Pixel units.
            height = (gridStep[1] eq 1.0) ? $
                self._height : (self._height / gridStep[1])
        endif else $
            height = self._height
    endif

    if (ARG_PRESENT(units)) then $
        units = self._units

    if (ARG_PRESENT(width)) then begin
        if (self._units eq 1) then begin
            ; Pixel units.
            width = (gridStep[0] eq 1.0) ? $
                self._width : (self._width / gridStep[0])
        endif else $
            width = self._width
    endif

    if (ARG_PRESENT(x)) then begin
        if (self._units eq 1) then begin
            ; Pixel units.
            if (OBJ_VALID(oTarget)) then begin
                oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                    self._x0+halfPixel[0], self._y0+halfPixel[1], $
                    x, unused
            endif else $
                x = self._x0
        endif else $
            x = self._x0
    endif

    if (ARG_PRESENT(y)) then begin
        if (self._units eq 1) then begin
            ; Pixel units.
            if (OBJ_VALID(oTarget)) then begin
                oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                    self._x0+halfPixel[0], self._y0+halfPixel[1], $
                    unused, y
            endif else $
                y = self._y0
        endif else $
            y = self._y0
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; IDLitopCropImage::SetProperty
;
; Purpose:
;   This procedure method sets the value(s) of one or more properties.
;
pro IDLitopCropImage::SetProperty, $
    ALLOW_ZERO_DIMS=allowZeroDims, $
    HEIGHT=height, $
    UNITS=inUnits, $
    WIDTH=width, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    units = (N_ELEMENTS(inUnits) ne 0) ? inUnits : self._units

    if ((N_ELEMENTS(height) gt 0) || $
        (N_ELEMENTS(width) gt 0) ||  $
        (N_ELEMENTS(x) gt 0) ||      $
        (N_ELEMENTS(y) gt 0)) then begin

        oTool = self->GetTool()
        oTarget = OBJ_NEW()
        if (OBJ_VALID(oTool)) then begin
            oSelVis = oTool->GetSelectedItems()
            oTarget = (self->_GetImageTargets(oSelVis))[0]
        endif

        if (OBJ_VALID(oTarget)) then begin
            oTarget->_IDLitVisGrid2D::GetProperty, $
                GRID_DIMENSIONS=gridDims, GRID_STEP=gridStep, $
                GRID_ORIGIN=gridOrigin
        endif else begin
            gridOrigin = [0.0,0.0]
            gridStep = [1.0,1.0]
        endelse

        halfPixel = gridStep*0.5
    endif

    bRectUpdate = 0b

    if (N_ELEMENTS(x) gt 0) then begin
        bSet = 1b
        if (units eq 1) then begin
            ; Pixel units.

            ; Constrain to first target.
            if (x lt 0) then $
                bSet = 0b
            if (OBJ_VALID(oTarget)) then begin
                if  (x ge gridDims[0]) then $
                    bSet = 0b
            endif

            if (bSet) then begin
                ; Convert to geometry units.
                if (OBJ_VALID(oTarget)) then begin
                    oTarget->_IDLitVisGrid2D::GridToGeometry, $
                        x, 0, geomX, unused, /CENTER_ON_PIXEL
                    geomX -= halfPixel[0]
                endif else $
                    geomX = x
            endif

        endif else begin
            geomX = x
            if (OBJ_VALID(oTarget)) then begin
                ; Constrain to first target.
                if (x lt gridOrigin[0]) then $
                    bSet = 0b
                if (x gt (gridOrigin[0]+(gridDims[0]*gridStep[0]))) then $
                    bSet = 0b

                if (bSet) then begin
                    ; Map to geometry centered on a pixel.
                    oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                        x+halfPixel[0], self._y0+halfPixel[1], $
                        pixelX, unused
                    oTarget->_IDLitVisGrid2D::GridToGeometry, $
                         pixelX, unused, geomX, unused2, /CENTER_ON_PIXEL

                    ; Set to lower-left corner of pixel.
                    geomX -= halfPixel[0]
                endif
            endif
        endelse

        if (bSet) then begin
            if (geomX ne self._x0) then begin
                self._x0 = geomX
                bRectUpdate = 1b
            endif
        endif
    endif

    if (N_ELEMENTS(y) gt 0) then begin
        bSet = 1b
        if (units eq 1) then begin
            ; Pixel units.

            ; Constrain to first target.
            if (y lt 0) then $
                bSet = 0b
            if (OBJ_VALID(oTarget)) then begin
                if  (y ge gridDims[1]) then $
                    bSet = 0b
            endif

            if (bSet) then begin
                ; Convert to geometry units.
                if (OBJ_VALID(oTarget)) then begin
                    oTarget->_IDLitVisGrid2D::GridToGeometry, $
                        0, y, unused, geomY, /CENTER_ON_PIXEL
                    geomY -= halfPixel[1]
                endif else $
                   geomY = y
            endif

        endif else begin
            geomY = y
            if (OBJ_VALID(oTarget)) then begin
                ; Constrain to target.
                if (y lt gridOrigin[1]) then $
                    bSet = 0b
                if (y gt (gridOrigin[1]+(gridDims[1]*gridStep[1]))) then $
                    bSet = 0b

                if (bSet) then begin
                     ; Map to geometry centered on a pixel.
                    oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                        self._x0+halfPixel[0], y+halfPixel[1], $
                       unused, pixelY
                    oTarget->_IDLitVisGrid2D::GridToGeometry, $
                         unused, pixelY, unused2, geomY, /CENTER_ON_PIXEL

                    ; Set to lower-left corner of pixel.
                    geomY -= halfPixel[1]
                endif
            endif

        endelse

        if (bSet) then begin
            if (geomY ne self._y0) then begin
                self._y0 = geomY
                bRectUpdate = 1b
            endif
        endif
    endif

    if (N_ELEMENTS(height) gt 0) then begin
        if (units eq 1) then begin
            ; Pixel units.
            geomH = height * gridStep[1]
        endif else begin
             ; Constrain to multiples of gridStep.
            iH = ULONG((height / gridStep[1]) + 0.5)
           geomH = iH * gridStep[1]
        endelse

        if (~KEYWORD_SET(allowZeroDims)) then begin
            ; Constrain to at least 2 pixels.
            pixelH = CEIL(geomH / gridStep[1])
            if (pixelH lt 2) then $
                geomH = 2 * gridStep[1]
        endif

        if ((geomH eq 0) || (geomH ne self._height)) then begin
            self._height = geomH
            bRectUpdate = 1b
        endif
    endif

    if (N_ELEMENTS(width) gt 0) then begin
        if (units eq 1) then begin
            ; Pixel units.
            geomW = width * gridStep[0]
        endif else begin
            ; Constrain to multiples of gridStep.
            iW = ULONG((width / gridStep[0]) + 0.5)
            geomW = iW * gridStep[0]
        endelse

        if (~KEYWORD_SET(allowZeroDims)) then begin
            ; Constrain to at least 2 pixels.
            pixelW = CEIL(geomW / gridStep[1])
            if (pixelW lt 2) then $
                geomW = 2 * gridStep[0]
        endif

        if ((geomW eq 0) || (geomW ne self._width)) then begin
            self._width = geomW
            bRectUpdate = 1b
        endif
    endif

    if (bRectUpdate) then begin
        geomW = self._width
        geomH = self._height
        pixelW = geomW / gridStep[0]
        pixelH = geomH / gridStep[1]

        geomX = self._x0
        geomY = self._y0

        if (OBJ_VALID(oTarget)) then begin
            oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                geomX+halfPixel[0], geomY+halfPixel[1], $
                pixelX, pixelY
        endif else begin
            pixelX = geomX
            pixelY = geomY
        endelse

        ; Constrain width and height to first target.
        if (OBJ_VALID(oTarget)) then begin
            if (~KEYWORD_SET(allowZeroDims)) then begin
                if (pixelW eq 0) then begin
                    pixelW = gridDims[0]
                    self._width = (pixelW * gridStep[0])
                endif
                if (pixelH eq 0) then begin
                    pixelH = gridDims[1]
                    self._height = (pixelH * gridStep[1])
                endif
            endif
            if ((pixelX+pixelW-1) ge gridDims[0]) then begin
                pixelW = gridDims[0] - pixelX
                self._width = pixelW * gridStep[0]
            endif
            if ((pixelY+pixelH-1) ge gridDims[1]) then begin
                pixelH = gridDims[1] - pixelY
                self._height = pixelH * gridStep[1]
            endif
        endif
        self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
    endif

    if (N_ELEMENTS(inUnits) ne 0) then $
        self._units = inUnits

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; IDLitopCropImage::GetCropBox
;
; Purpose:
;   This procedure method returns the current crop rectangle in the
;   requested units.  (Note that ::GetProperty always returns the
;   crop X, Y, WIDTH, and HEIGHT according to the current UNITS setting.
;   This method allows the caller to choose units.
;
; Keywords:
;   TARGET: Set this keyword to a reference to the IDLitVisImage
;     that is the requested crop target.  By default, the currently
;     selected image target within the tool is used (if available).
;
;   UNITS: Set this keyword to a scalar representing the requested
;     units of measure for the returned crop rectangle coordinates.
;     Valid values include:
;       0: data units (default)
;       1: pixel units
;
pro IDLitopCropImage::GetCropBox, x, y, width, height, $
    TARGET=oTarget, $
    UNITS=inUnits

    compile_opt idl2, hidden

    units = (N_ELEMENTS(inUnits) ne 0) ? inUnits : 0

    if (N_ELEMENTS(oTarget) eq 0) then begin
        oTool = self->GetTool()
        oTarget = OBJ_NEW()
        if (OBJ_VALID(oTool)) then begin
            oSelVis = oTool->GetSelectedItems()
            oTarget = (self->_GetImageTargets(oSelVis))[0]
        endif
    endif

    if (OBJ_VALID(oTarget)) then $
        oTarget->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep $
    else $
        gridStep = [1.0,1.0]

    halfPixel = gridStep*0.5

    if (units eq 1) then begin
        ; Pixel units.
        if (OBJ_VALID(oTarget)) then begin
            oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                self._x0+halfPixel[0], self._y0+halfPixel[1], $
                x, y
        endif else begin
            x = self._x0
            y = self._y0
        endelse

        width = (gridStep[1] eq 1.0) ? $
            self._width : (self._width / gridStep[0])
        height = (gridStep[1] eq 1.0) ? $
            self._height : (self._height / gridStep[1])
    endif else begin
        x = self._x0
        y = self._y0
        width = self._width
        height = self._height
    endelse
end

;---------------------------------------------------------------------------
; IDLitopCropImage::SetCropBox
;
; Purpose:
;   This procedure method sets the current crop rectangle to the given
;   values.  (Note that ::SetProperty always assumes the incoming values
;   for X, Y, WIDTH, and HEIGHT are specified according to the current
;   UNITS setting.  This method allows the caller to choose units.)
;
; Keywords:
;   ALLOW_ZERO_DIMENSIONS: Set this keyword to a non-zero value to
;     indicate that a width and/or height of zero is permissible.
;     By default, zero dimensions are translated to full target dimensions.
;
;   TARGET: Set this keyword to a reference to the IDLitVisImage
;     that is the requested crop target.  By default, the currently
;     selected image target within the tool is used (if available).
;
;   UNITS: Set this keyword to a scalar representing the units of
;     measure used by the given crop rectangle coordinates.
;     Valid values include:
;       0: data units (default)
;       1: pixel units
;
pro IDLitopCropImage::SetCropBox, x, y, width, height, $
    ALLOW_ZERO_DIMENSIONS=allowZeroDims, $
    TARGET=oTarget, $
    UNITS=inUnits

    compile_opt idl2, hidden

    units = (N_ELEMENTS(inUnits) ne 0) ? inUnits : 0

    if (N_ELEMENTS(oTarget) eq 0) then begin
        oTool = self->GetTool()
        oTarget = OBJ_NEW()
        if (OBJ_VALID(oTool)) then begin
            oSelVis = oTool->GetSelectedItems()
            oTarget = (self->_GetImageTargets(oSelVis))[0]
        endif
    endif

    if (OBJ_VALID(oTarget)) then begin
        oTarget->_IDLitVisGrid2D::GetProperty, $
            GRID_DIMENSIONS=gridDims, GRID_STEP=gridStep, $
            GRID_ORIGIN=gridOrigin
    endif else begin
        gridOrigin = [0.0,0.0]
        gridStep = [1.0,1.0]
    endelse

    halfPixel = gridStep*0.5

    bRectUpdate = 0b
    bSetX = 1b
    bSetY = 1b
    if (units eq 1) then begin
        ; Pixel units.

        ; Constrain X and Y to target.
        if (x lt 0) then $
            bSetX = 0b
        if (y lt 0) then $
            bSetY = 0b
        if (OBJ_VALID(oTarget)) then begin
            if  (x ge gridDims[0]) then $
                bSetX = 0b
            if  (y ge gridDims[1]) then $
                bSetY = 0b
        endif

        ; Proceed if X or Y within target.
        if (bSetX || bSetY) then begin
            ; Compute X,Y in geometry units.
            if (OBJ_VALID(oTarget)) then begin
                oTarget->_IDLitVisGrid2D::GridToGeometry, $
                    x, y, geomX, geomY, /CENTER_ON_PIXEL
                    geomX -= halfPixel[0]
                    geomY -= halfPixel[1]
            endif else begin
                geomX = x
                geomY = y
            endelse

            ; If X or Y within target, save any change.
            if (bSetX) then begin
                if (geomX ne self._x0) then begin
                    self._x0 = geomX
                    bRectUpdate = 1b
                endif
            endif
            if (bSetY) then begin
                if (geomY ne self._y0) then begin
                    self._y0 = geomY
                    bRectUpdate = 1b
                endif
            endif
        endif

        ; Handle zero dimensions appropriately.
        pixelW = width
        pixelH = height
        if (OBJ_VALID(oTarget)) then begin
            if (~KEYWORD_SET(allowZeroDims)) then begin
                pixelW = (width eq 0) ? gridDims[0] : width
                pixelH = (height eq 0) ? gridDims[1] : height
            endif
        endif

        ; Save any change to dimensions.
        newW = pixelW * gridStep[0]
        newH = pixelH * gridStep[1]
        if (self._width ne newW) then begin
            self._width = newW
            bRectUpdate = 1b
        endif
        if (self._height ne newH) then begin
            self._height = newH
            bRectUpdate = 1b
        endif

    endif else begin
        ; Data units.

        ; Constrain X and Y to target.
        if (x lt gridOrigin[0]) then $
            bSetX = 0b
        if (x gt (gridOrigin[0]+(gridDims[0]*gridStep[0]))) then $
            bSetX = 0b
        if (y lt gridOrigin[1]) then $
            bSetY = 0b
        if (Y gt (gridOrigin[1]+(gridDims[1]*gridStep[1]))) then $
            bSetY = 0b

        ; Proceed if X or Y within target.
        if (bSetX || bSetY) then begin
            geomX = x
            geomY = y
            if (OBJ_VALID(oTarget)) then begin
                ; Map to geometry centered on pixel.
                oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                    x+halfPixel[0], y+halfPixel[1], $
                    pixelX, pixelY
                oTarget->_IDLitVisGrid2D::GridToGeometry, $
                    pixelX, pixelY, geomX, geomY, /CENTER_ON_PIXEL

                ; Set to lower-left corner of pixel.
                geomX -= halfPixel[0]
                geomY -= halfPixel[1]
            endif

            ; If X or Y within target, save any change.
            if (bSetX) then begin
                if (geomX ne self._x0) then begin
                    self._x0 = geomX
                    bRectUpdate = 1b
                endif
            endif
            if (bSetY) then begin
                if (geomY ne self._y0) then begin
                    self._y0 = geomY
                    bRectUpdate = 1b
                endif
            endif
        endif

        ; Constrain dimensions to multiples of gridStep.
        pixelW = ULONG((width / gridStep[0]) + 0.5)
        geomW = pixelW * gridStep[0]
        pixelH = ULONG((height / gridStep[1]) + 0.5)
        geomH = pixelH * gridStep[1]

        ; Handle zero dimensions appropriately.
        if (OBJ_VALID(oTarget)) then begin
            if (~KEYWORD_SET(allowZeroDims)) then begin
                if (pixelW eq 0) then begin
                    pixelW = gridDims[0]
                    geomW = pixelW * gridStep[0]
                endif
                if (pixelH eq 0) then begin
                    pixelH = gridDims[1]
                    geomH = pixelH * gridStep[0]
                endif
            endif
        endif

        ; Save any change to dimensions.
        if (self._width ne geomW) then begin
            self._width = geomW
            bRectUpdate = 1b
        endif
        if (self._height ne geomH) then begin
            self._height = geomH
            bRectUpdate = 1b
        endif
    endelse

    if (bRectUpdate) then begin
        geomW = self._width
        geomH = self._height
        pixelW = geomW / gridStep[0]
        pixelH = geomH / gridStep[1]

        geomX = self._x0
        geomY = self._y0
        if (OBJ_VALID(oTarget)) then begin
            oTarget->_IDLitVisGrid2D::GeometryToGrid, $
                geomX+halfPixel[0], geomY+halfPixel[1], $
                pixelX, pixelY
        endif else begin
            pixelX = geomX
            pixelY = geomY
        endelse

        ; Constrain width and height to target.
        if (OBJ_VALID(oTarget)) then begin
            if (~KEYWORD_SET(allowZeroDims)) then begin
                if (pixelW eq 0) then begin
                    pixelW = gridDims[0]
                    self._width = (pixelW * gridStep[0])
                endif
                if (pixelH eq 0) then begin
                    pixelH = gridDims[1]
                    self._height = (pixelH * gridStep[1])
                endif
            endif
            if ((pixelX+pixelW-1) ge gridDims[0]) then begin
                pixelW = gridDims[0] - pixelX
                self._width = pixelW * gridStep[0]
            endif
            if ((pixelY+pixelH-1) ge gridDims[1]) then begin
                pixelH = gridDims[1] - pixelY
                self._height = pixelH * gridStep[1]
            endif
        endif
        self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
    endif
end

;---------------------------------------------------------------------------
; IDLitopCropImage::OnNotify
;
; Purpose:
;   Handles notification.
;
pro IDLitopCropImage::OnNotify, strID, message, userdata

    compile_opt idl2, hidden

    case STRUPCASE(message) of
        'SELECTIONCHANGED': begin
            oTool = self->GetTool()
            if (~OBJ_VALID(oTool)) then $
                return
            oSelVis = oTool->GetSelectedItems()
            oTargets = self->_GetImageTargets(oSelVis, COUNT=nTargets)

            ; Pixel units should only be valid if:
            ;   A) only one image target is being cropped, or
            ;   B) image targets have same origin and same
            ;      pixel size.
            bEnable = 1b
            if (nTargets eq 0) then begin
                bEnable = 0b
            endif else if (nTargets gt 1) then begin
                oTargets[0]->_IDLitVisGrid2D::GetProperty, $
                    GRID_ORIGIN=gridOrigin, GRID_STEP=gridStep
                for i=1,nTargets-1 do begin
                    oTargets[i]->_IDLitVisGrid2D::GetProperty, $
                        GRID_ORIGIN=tmpOrigin, GRID_STEP=tmpStep
                    if ((~ARRAY_EQUAL(gridOrigin, tmpOrigin)) || $
                        (~ARRAY_EQUAL(gridStep, tmpStep))) then begin

                        ; Mismatch found.  Disable pixel units.
                        bEnable = 0b
                        break

                        return
                    endif
                endfor
            endif

            if (bEnable) then begin
                self->SetPropertyAttribute, 'UNITS', SENSITIVE=1
            endif else begin
                self->SetPropertyAttribute, 'UNITS', SENSITIVE=0
                self._units = 0
            endelse

            ; Send notification so UI can update.
            self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
        end

        else: begin
        end
    endcase

end

;---------------------------------------------------------------------------
; IDLitopCropImage::UndoOperation
;
; Purpose:
;   This function method performs an undo of the crop operation.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oCommandSet: A reference to the command set containing the
;     information about the command to be undone.
;
function IDLitopCropImage::UndoOperation, oCommandSet
    compile_opt idl2, hidden

    oTool = self->GetTool()
    oCustomizeOp = oTool->IDLitContainer::GetByIdentifier( $
        "Operations/Customization")
    customizeOpID = OBJ_VALID(oCustomizeOp) ? $
        oCustomizeOp->GetFullIdentifier() : ''

    ; "Special" code to temporarily append "IDLARRAY2D" to the types
    ; supported by this operation. This allows the data operation to
    ; find the appropriate parameter to act upon.  After execution
    ; on the target, "IDLARRAY2D" then gets removed so that availability
    ; of this operation can be reported based upon the original types
    ; (i.e., the visualization type, "IDLIMAGE").
    oldTypes = *self._types
    *self._types = [oldTypes, "IDLARRAY2D"]

    ; Get the sub-command sets from the top-level command set,
    ; and perform undo on each in turn.
    oCmds = oCommandSet->Get(/ALL, COUNT=nCmds)
    for i=0,nCmds-1 do begin
        oCmds[i]->GetProperty, OPERATION_IDENTIFIER=opID
        if (opID eq customizeOpID) then begin
            if (OBJ_VALID(oCustomizeOp)) then begin
                iStatus = oCustomizeOp->UndoOperation(oCmds[i])
                if (~iStatus) then begin
                    ; Restore types.
                    *self._types = oldTypes
                    return, 0
                endif
            endif
        endif else begin
            iStatus = self->IDLitDataOperation::UndoOperation(oCmds[i])
            if (~iStatus) then begin
                ; Restore types.
                *self._types = oldTypes
                return, 0
            endif
        endelse
    endfor

    ; Restore types.
    *self._types = oldTypes

    return, 1

end

;---------------------------------------------------------------------------
; IDLitopCropImage::RedoOperation
;
; Purpose:
;   This function method performs an redo of the crop operation.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oCommandSet: A reference to the command set containing the
;     information about the command to be re-done.
;
function IDLitopCropImage::RedoOperation, oCommandSet
    compile_opt idl2, hidden

    oTool = self->GetTool()
    oCustomizeOp = oTool->IDLitContainer::GetByIdentifier( $
        "Operations/Customization")
    customizeOpID = OBJ_VALID(oCustomizeOp) ? $
        oCustomizeOp->GetFullIdentifier() : ''

    ; "Special" code to temporarily append "IDLARRAY2D" to the types
    ; supported by this operation. This allows the data operation to
    ; find the appropriate parameter to act upon.  After execution
    ; on the target, "IDLARRAY2D" then gets removed so that availability
    ; of this operation can be reported based upon the original types
    ; (i.e., the visualization type, "IDLIMAGE").
    oldTypes = *self._types
    *self._types = [oldTypes, "IDLARRAY2D"]

    ; Get the sub-command sets from the top-level command set,
    ; and perform redo on each in turn.
    oCmds = oCommandSet->Get(/ALL, COUNT=nCmds)
    for i=0,nCmds-1 do begin
        oCmds[i]->GetProperty, OPERATION_IDENTIFIER=opID

        if (opID eq customizeOpID) then begin
            if (OBJ_VALID(oCustomizeOp)) then begin
                iStatus = oCustomizeOp->RedoOperation(oCmds[i])
                if (~iStatus) then begin
                    ; Restore types.
                    *self._types = oldTypes
                    return, 0
                endif
            endif
        endif else begin

            ; Set the target.
            oFirstCmd = oCmds[i]->Get()
            if (OBJ_VALID(oFirstCmd)) then begin
                if (oFirstCmd->GetItem( $
                    "TARGET_VISUALIZATION_ID", targetID)) then begin
                    if (STRLEN(targetID) gt 0) then $
                        self._oCurrTarget = $
                            oTool->IDLitContainer::GetByIdentifier(targetID)
                endif
            endif
            iStatus = self->IDLitDataOperation::RedoOperation(oCmds[i])
            if (~iStatus) then begin
                ; Restore types.
                *self._types = oldTypes
                return, 0
            endif

            ; Re-establish view zoom.
            oWin = oTool->GetCurrentWindow()
            oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
            if (OBJ_VALID(oView)) then begin
                oCmd = oCmds[i]->Get()
                if (oCmd->GetItem("VIEW_ZOOM", viewZoom)) then $
                    oView->SetCurrentZoom, viewZoom, /NO_UPDATES
            endif
        endelse
    endfor

    ; Restore types.
    *self._types = oldTypes

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCropImage::_CropDependents
;
; Purpose:
;   This internal procedure method prepares a command set for cropping
;   all data items (such as ROIs) whose geometry is tied to the geometry
;   of the operation's current image target.
;
;   Note that this method gets called once for each image target.
;
pro IDLitopCropImage::_CropDependents
    compile_opt idl2, hidden

    oTool = self->GetTool()

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Delete ROIs that do not fit within the crop area.
    oRois = self._oCurrTarget->Get(/ALL, ISA='IDLitVisROI', COUNT=nROI)
    nDel = 0
    for i=0,nROI-1 do begin
        oROIs[i]->GetProperty, XRANGE=xrange, YRANGE=yrange
        if ((xrange[0] lt self._x0) || $
            (xrange[1] gt (self._x0+self._width)) || $
            (yrange[0] lt self._y0) || $
            (yrange[1] gt (self._y0+self._height))) then begin
            oDelROIs = (nDel gt 0) ? [oDelROIs, oROIs[i]] : [oROIs[i]]
            nDel++
        endif
    endfor
    if (nDel gt 0) then begin
        oDelDesc = oTool->GetByIdentifier("OPERATIONS/EDIT/DELETE")
        oDelOp = OBJ_VALID(oDelDesc) ? $
            oDelDesc->GetObjectInstance() : OBJ_NEW()
        if (OBJ_VALID(oDelOp)) then begin
            oDelCmdSet = oDelOp->_Delete(oTool, oDelROIs)

            oDelDesc->ReturnObjectInstance, oDelOp

            if (OBJ_VALID(oDelCmdSet[0])) then begin
                ; Add to our own container.  The collected
                ; commands will be added to the overall command
                ; set array later.
                if (~OBJ_VALID(self._oSubCropCmds)) then $
                    self._oSubCropCmds = OBJ_NEW('IDL_Container')
                self._oSubCropCmds->Add, oDelCmdSet
            endif
        endif
    endif

    ; Determine whether the target has X and/or Y parameters.
    self._oCurrTarget->_IDLitVisGrid2D::GetProperty, X_DATA_ID=xDataID, $
        Y_DATA_ID=yDataID
    oXDataObj = self._oCurrTarget->GetParameter(xDataID)
    haveXParam = OBJ_VALID(oXDataObj)
    oYDataObj = self._oCurrTarget->GetParameter(yDataID)
    haveYParam = OBJ_VALID(oYDataObj)

    if (haveXParam || haveYParam) then begin
        ; Crop image X and/or Y parameters.
        oCropGridDesc = oTool->GetByIdentifier($
            "OPERATIONS/OPERATIONS/CROPIMAGEGRID")
        oCropGridOp = OBJ_VALID(oCropGridDesc) ? $
            oCropGridDesc->GetObjectInstance() : OBJ_NEW()
        if (OBJ_VALID(oCropGridOp)) then begin
            oCropGridOp->SetProperty, X=self._x0, Y=self._y0, $
                WIDTH=self._width, HEIGHT=self._height, $
                TARGET=self._oCurrTarget
            oCropGridCmdSet = oCropGridOp->DoAction(oTool)

            if (OBJ_VALID(oCropGridCmdSet[0])) then begin
                ; Add to our own container.  The collected
                ; commands will be added to the overall command
                ; set array later.
                if (~OBJ_VALID(self._oSubCropCmds)) then $
                   self._oSubCropCmds = OBJ_NEW('IDL_Container')
                self._oSubCropCmds->Add, oCropGridCmdSet
            endif

            oCropGridDesc->ReturnObjectInstance, oCropGridOp
        endif
    endif

    ; If either X or Y parameter not present, set the appropriate
    ; origin.
    bSetOrig = 0b
    self._oCurrTarget->GetProperty, XORIGIN=xOrigin, YORIGIN=yOrigin
    if (~haveXParam) then begin
        xOrigin = self._x0
        bSetOrig = 1b
    endif
    if (~haveYParam) then begin
        yOrigin = self._y0
        bSetOrig = 1b
    endif

    if (bSetOrig) then begin
        oSetOrigDesc = oTool->GetByIdentifier( $
            "OPERATIONS/OPERATIONS/SETIMAGEORIGIN")
        oSetOrigOp = OBJ_VALID(oSetOrigDesc) ? $
            oSetOrigDesc->GetObjectInstance() : OBJ_NEW()
        if (OBJ_VALID(oSetOrigOp)) then begin
            oSetOrigOp->SetProperty, X=xOrigin, Y=yOrigin, $
                TARGET=self._oCurrTarget
            oSetOrigCmdSet = oSetOrigOp->DoAction(oTool)
            if (OBJ_VALID(oSetOrigCmdSet)) then begin
                ; Add to our own container.  The collected
                ; commands will be added to the overall command
                ; set array later.
                if (~OBJ_VALID(self._oSubCropCmds)) then $
                    self._oSubCropCmds = OBJ_NEW('IDL_Container')
                self._oSubCropCmds->Add, oSetOrigCmdSet
            endif
            oSetOrigDesc->ReturnObjectInstance, oSetOrigOp
        endif
    endif

    if (~wasDisabled) then $
        oTool->EnableUpdates
end

;---------------------------------------------------------------------------
; IDLitopCropImage::_GetImageTargets
;
; Purpose:
;   This internal function identifies the image targets from among
;   the given selected visualizations.
;
; Return Value:
;   This function returns a vector of references to visualization objects,
;   or a NULL object reference if no valid target is found.
;
; Arguments:
;   oSelVis: A vector of references to the currently selected visualization
;     objects.
;
; Keywords:
;   COUNT: Set this keyword to a named variable that upon return will
;     contain the number of valid targets included in the return value,
;     or 0 if none found.
;
function IDLitopCropImage::_GetImageTargets, oSelVis, $
    COUNT=nTargets

    compile_opt idl2, hidden

    nSelVis = N_ELEMENTS(oSelVis)

    ; For each selected visualization...
    nTargets = 0
    for i=0, nSelVis-1 do begin

        oVis = oSelVis[i]
        while (OBJ_VALID(oVis)) do begin
            if (~OBJ_ISA(oVis, "_IDLitVisualization")) then $
                break

            ; Seek a visualization of type IDLIMAGE at this visualization
            ; or among any of its parentage.
            oVis->GetProperty, TYPE=type
            if (type eq 'IDLIMAGE') then begin

                oTargets = (nTargets eq 0) ? oVis : [oTargets, oVis]
                nTargets++
                break
            endif

            oVis->GetProperty, PARENT=oParent
            oVis = oParent
        endwhile
    endfor

    if (nTargets eq 0) then $
        return, OBJ_NEW()

    ; Remove dups. Can't use UNIQ because we need to preserve the order.
    oUniqVis = oTargets[0]
    for i=1, nTargets-1 do begin
        if (TOTAL(oUniqVis eq oTargets[i]) eq 0) then $
            oUniqVis = [oUniqVis, oTargets[i]]
    endfor

    nTargets = N_ELEMENTS(oUniqVis)
    return, oUniqVis
end

;---------------------------------------------------------------------------
; IDLitopCropImage::_GetOpTargets
;
; Purpose:
;   This internal function retrieves the parameter descriptors for
;   the operation targets for the given seleced visualization.
;
; Return Value:
;   A vector of references to the parameter descriptors for the
;   operation targets, or a NULL object reference if no valid targets
;   are found.
;
; Arguments:
;   oSelVis: A vector of references to the currently selected visualization
;     objects.
;
function IDLitopCropImage::_GetOpTargets, oSelVis, $
    COUNT=count

    compile_opt idl2, hidden

    oSelVis->GetProperty, TYPE=type

    ; Only allow visualizations whose type is IDLIMAGE.
    if (type ne 'IDLIMAGE') then begin
        count = 0
        return, OBJ_NEW()
    endif

    ; If the crop box falls outside of the image, disregard it.
    oSelVis->_IDLitVisGrid2D::GetProperty, GRID_DIMENSIONS=gridDims, $
        GRID_STEP=gridStep, GRID_ORIGIN=gridOrigin
    dataDims = gridDims * gridStep
    if ((self._x0 lt gridOrigin[0]) || $
        (self._y0 lt gridOrigin[1]) || $
        ((self._x0+self._width)  gt (gridOrigin[0]+dataDims[0])) || $
        ((self._y0+self._height) gt (gridOrigin[1]+dataDims[1]))) then begin
        count = 0
        return, OBJ_NEW()
    endif

    oOpTargets = oSelVis->GetOpTargets(COUNT=nOpTargets)
    count = 0
    for i=0,nOpTargets-1 do begin
        ; Prune out any palette operation targets.
        oOpTargets[i]->GetProperty, NAME=name
        if (STRUPCASE(name) eq 'PALETTE') then $
            continue

        ; Collect remaining operation targets.
        oTargets = (count gt 0) ? $
           [oTargets, oOpTargets[i]] : oOpTargets[i]
        count++
    endfor

    return, (count gt 0) ? oTargets : OBJ_NEW()
end

;---------------------------------------------------------------------------
; IDLitopCropImage::_ExecuteOnTarget
;
; Purpose:
;   This function method executes the crop operation on a given target.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
; Arguments:
;   oTarget: A reference to the target visualization object(s).
;
;   oCommandSet: A reference to the command set in which commands for
;     this operation are being collected.
;
function IDLitopCropImage::_ExecuteOnTarget, oTarget, oCommandSet
    compile_opt idl2, hidden

    self._oCurrTarget = oTarget

    ; "Special" code to temporarily append "IDLARRAY2D" to the types
    ; supported by this operation. This allows the data operation to
    ; find the appropriate parameter to act upon.  After execution
    ; on the target, "IDLARRAY2D" then gets removed so that availability
    ; of this operation can be reported based upon the original types
    ; (i.e., the visualization type, "IDLIMAGE").
    oldTypes = *self._types
    *self._types = [oldTypes, "IDLARRAY2D"]

    nOldCommands = oCommandSet->Count()
    success = self->IDLitDataOperation::_ExecuteOnTarget(oTarget, oCommandSet)
    if (success ne 0) then begin
        ; Store the target visualization so that redo can apply
        ; the appropriate geometry
        nNewCommands = oCommandSet->Count()
        for i=nOldCommands,nNewCommands-1 do begin
            oCmd = oCommandSet->Get(POSITION=i)
            iStatus = oCmd->AddItem("TARGET_VISUALIZATION_ID", $
                self._oCurrTarget->GetFullIdentifier())
        endfor

        self->_CropDependents
    endif

    ; Restore types.
    *self._types = oldTypes

    self._oCurrTarget = OBJ_NEW()


    return, success
end

;---------------------------------------------------------------------------
; IDLitopCropImage::UICallback
;
; Purpose:
;   This function method handles notification from this operation's UI.
;
; Return Value:
;   This function returns a 1 if handling of the notification was
;   successful, or 0 otherwise.
;
; Arguments:
;   dialogResult: A boolean that will be 1 if the OK button was pressed,
;     or 0 if the Cancel button was pressed.
;
function IDLitopCropImage::UICallback, dialogResult

    compile_opt idl2, hidden

    oTool = self->GetTool()
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; User hit "Okay"?
    if (dialogResult) then begin

        ; The hourglass will have been cleared by the dialog.
        ; So turn it back on.
        void = oTool->DoUIService("HourGlassCursor", self)
        self->IDLitDataOperation::GetProperty, SHOW_EXECUTION_UI=showUI
        self->IDLitDataOperation::SetProperty, SHOW_EXECUTION_UI=0
        oCommand = self->DoAction(oTool)
        success = OBJ_VALID(oCommand[0])
        if (success) then $
           oTool->_TransactCommand, oCommand
        self->IDLitDataOperation::SetProperty, SHOW_EXECUTION_UI=showUI

    endif else begin
        ; Undo all of our set properties.
        if (OBJ_VALID(self._oPropSet)) then begin
            void = self->UndoOperation(self._oPropSet)
            OBJ_DESTROY, self._oPropSet
            self._oPropSet = OBJ_NEW()
        endif
        ; if user hit Cancel then allow dialog to die.
        success = 1
    endelse

    ; Zero out the flag that indicates that the UI is active.
    if (success) then begin
        self._withinUI = 0b
        ; Remove self as an observer of the tool's visualizations.
        self->RemoveOnNotifyObserver, self->GetFullIdentifier(), $
            'Visualization'
        ; Activate the appropriate manipulator.
        bDoPan = 0b
        oManipPan = oTool->IDLitContainer::GetByIdentifier( $
            "MANIPULATORS/VIEWPAN")
        if (OBJ_VALID(oManipPan)) then $
            bDoPan = oManipPan->QueryAvailability(oTool, oView)
        if (bDoPan) then $
            oTool->ActivateManipulator, "VIEWPAN" $
        else $
            oTool->ActivateManipulator, /DEFAULT
    endif


    if (~previouslyDisabled) then $
        oTool->EnableUpdates

    ; Only allow dialog to die if operation was successful.
    return, success

end

;---------------------------------------------------------------------------
; IDLitopCropImage::DoExecuteUI
;
; Purpose:
;   This function method displays the UI associated with this crop
;   operation.
;
; Return Value
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation
;
function IDLitopCropImage::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; If the dialog is already being displayed, return success.
    if (self._withinUI) then $
        return, 1

    ; Display dialog. This will return immediately since nonmodal.
    success = oTool->DoUIService('CropImage', self)
    if (~success) then $
        return, 0

    self._withinUI = 1b

    ; Add self as observer of tool visualizations so that selection
    ; changes can be handled.
    oTool->AddOnNotifyObserver, self->GetFullIdentifier(), $
        'Visualization'

    ; Activate the crop manipulator.
    oCurrManip = oTool->GetCurrentManipulator()
    bAlreadyActive = 0b
    if (OBJ_VALID(oCurrManip)) then begin
        currManipID = oCurrManip->GetFullIdentifier()
        if (STRUPCASE(currManipID) eq $
            STRUPCASE(oTool->GetfullIdentifier()+ $
                '/MANIPULATORS/CROP BOX')) then begin
            bAlreadyActive = 1b
        endif
    endif

    if (bAlreadyActive) then begin
        oCurrManip->UpdateToMatchOperation
    endif else $
        oTool->ActivateManipulator, 'CROP BOX'


    return, 1  ; success
end


;-------------------------------------------------------------------------
; IDLitopCropImage::DismissUI
;
; Purpose:
;   This procedure method dismisses the UI associated with this operation.
;
pro IDLitopCropImage::DismissUI
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return

    if (self._withinUI) then begin
        oTool->DoOnNotify, self->GetFullIdentifier(), 'DISMISS', ''
        ; Zero out the flag that indicates that the UI is active.
        self._withinUI = 0b
        ; Remove self as an observer of the tool's visualizations.
        self->RemoveOnNotifyObserver, self->GetFullIdentifier(), $
            'Visualization'
    endif
end


;-------------------------------------------------------------------------
; IDLitopCropImage::Execute
;
; Purpose:
;   This function method executes the operation on the raw image data.
;
; Parameters:
;   Data: The image data to be cropped.
;
function IDLitopCropImage::Execute, data
    compile_opt idl2, hidden

    if (OBJ_VALID(self._oCurrTarget)) then begin
        self._oCurrTarget->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep
        halfPixel = gridStep*0.5
        self._oCurrTarget->_IDLitVisGrid2D::GeometryToGrid, $
            self._x0+halfPixel[0], self._y0+halfPixel[1], $
            pixelX, pixelY
    endif else begin
        gridStep = [1.0,1.0]
        pixelX = self._x0
        pixelY = self._y0
    endelse

    pixelW = CEIL(self._width / gridStep[0])
    pixelH = CEIL(self._height / gridStep[1])
    if ((pixelW lt 2) || (pixelH lt 2)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:CropError:Text')], $
            TITLE=IDLitLangCatQuery('Error:CropError:Title'), SEVERITY=2
        return, 0
    endif

    dType = size(data, /TYPE)
    x0 = pixelX
    y0 = pixelY
    x1 = x0 + pixelW - 1
    y1 = y0 + pixelH - 1
    cropData = MAKE_ARRAY(pixelW, pixelH, TYPE=dType, /NOZERO)
    cropData[*,*] = data[x0:x1,y0:y1]

    data = cropData

    return, 1
end

;-------------------------------------------------------------------------
; IDLitopCropImage::DoAction
;
; Purpose:
;   This function method performs the crop operation.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
function IDLitopCropImage::DoAction, oTool
    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; Get the selected objects.
    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then $
        return, OBJ_NEW()

    ; Clear out any vestigal commands to crop dependents.
    if (OBJ_VALID(self._oSubCropCmds)) then begin
        oCmds = self._oSubCropCmds->Get(/ALL, COUNT=nCmds)
        if (nCmds gt 0) then begin
            self._oSubCropCmds->Remove, oCmds
            OBJ_DESTROY, oCmds
        endif
    endif

    ; Emulate a SELECTIONCHANGED event to force proper setup.
    self->OnNotify, oTool->GetFullIdentifier(), 'SELECTIONCHANGED', $
        OBJ_NEW()

    ; Verify that current crop rectangle is appropriate for
    ; the first target.  If not, reset it to match entire target.
    oTarget = (self->_GetImageTargets(oSelVis))[0]
    if (OBJ_VALID(oTarget)) then begin
        oTarget->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep, $
            GRID_DIMENSIONS=gridDims
        halfPixel = gridStep*0.5
        oTarget->_IDLitVisGrid2D::GeometryToGrid, $
            self._x0+halfPixel[0], self._y0+halfPixel[1], $
            pixelX, pixelY

        pixelW = self._width / gridStep[0]
        pixelH = self._height / gridStep[1]

        if ((pixelW eq 0) || (pixelH eq 0) || $
            ((pixelX + pixelW - 1) ge gridDims[0]) || $
            ((pixelY + pixelH - 1) ge gridDims[1])) then begin
            oTarget->_IDLitVisGrid2D::GridToGeometry, 0, 0, $
                geomX, geomY, /CENTER_ON_PIXEL
            self._x0 = geomX - halfPixel[0]
            self._y0 = geomY - halfPixel[1]
            self._width = gridDims[0] * gridStep[0]
            self._height = gridDims[1] * gridStep[1]
            self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
        endif
    endif


    ; Check if UI is requested prior to execution.
    self->GetProperty, SHOW_EXECUTION_UI=doUI


    if (doUI) then begin

        ; Perform our UI.
        success = self->DoExecuteUI()

        if (~success) then begin
            if (OBJ_VALID(self._oPropSet)) then begin
                ; Undo all of our set properties.
                void = self->UndoOperation(self._oPropSet)
                OBJ_DESTROY, self._oPropSet
                self._oPropSet = OBJ_NEW()
            endif
        endif

        ; Because UI is non-modal, no command set is returned now.
        ; It will be transacted (as appropriate) within the UI callback.
        return, obj_new()
    endif


;**************************** DoAction

    ; Get current view zoom factor.
    oWin = oTool->GetCurrentWindow()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    if (OBJ_VALID(oView)) then $
        oView->GetProperty, CURRENT_ZOOM=origViewZoom

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; Get a commmand set for this operation from the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)

    ; Get a commmand set for the data operation.
    oDataOpCmdSet = self->IDLitOperation::DoAction(oTool)

    ; Perform the actual data operation.
    iStatus = self->IDLitDataOperation::DoDataOperation(oTool, $
        oDataOpCmdSet, oSelVis)

    ; Did the operation fail for all selected viz?
    if (~iStatus) then begin
        ; We should already have performed an UndoOperation (in the loop),
        ; so just destroy our command set.
        OBJ_DESTROY, [oCommandSet, oDataOpCmdSet]
        if (~previouslyDisabled) then $
            oTool->EnableUpdates
        return, OBJ_NEW()
    endif


    oCommandSet->Add, oDataOpCmdSet

    ; Get a commmand set for the customization.
    oCustomizeOp = oTool->IDLitContainer::GetByIdentifier( $
        "Operations/Customization")

    if (OBJ_VALID(oCustomizeOp)) then begin
        ; Prepare a command set for customizing the tool.
        oCustomCmdSet = oCustomizeOp->DoAction(oTool)

        if (OBJ_VALID(oCustomCmdSet[0])) then $
            oCommandSet->Add, oCustomCmdSet
    endif

    if (OBJ_VALID(oView)) then begin
        ; Record initial view zoom factor.
        oCmd = oDataOpCmdSet->Get()
        iStatus = oCmd->AddItem("VIEW_ZOOM", origViewZoom)

        ; Re-establish view zoom factor.
        oView->SetCurrentZoom, origViewZoom, /NO_UPDATES
    endif

    ; Collect all commands to crop dependents.
    if (OBJ_VALID(self._oSubCropCmds)) then begin
        oSubCropCmds = self._oSubCropCmds->Get(/ALL, COUNT=nSubCmds)
        if (nSubCmds gt 0) then $
            self._oSubCropCmds->Remove, oSubCropCmds
    endif else $
        nSubCmds = 0
    oCmdSetArr = (nSubCmds gt 0) ? $
        [oCommandSet, oSubCropCmds] : [oCommandSet]


    oSrvMacro = oTool->GetService('MACROS')
    if obj_valid(oSrvMacro) then begin
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, self, currentName
    endif

    if (~previouslyDisabled) then $
        oTool->EnableUpdates

    self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

    ; Ensure that the name of the last command reflects the
    ; overall operation name.
    nCmds = N_ELEMENTS(oCmdSetArr)
    if (nCmds gt 0) then $
        oCmdSetArr[nCmds-1]->SetProperty, NAME=self.name

    return, oCmdSetArr

end


;-------------------------------------------------------------------------
; IDLitopCropImage::QueryAvailability
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
function IDLitopCropImage::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Use our superclass as a first filter.
    ; If not available by matching types, then no need to continue.
    success = self->IDLitDataOperation::QueryAvailability(oTool, selTypes)
    if (~success) then $
        return, 0

    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then $
        return, 0

    ; If our dataspace has a map projection, then we can't crop.
    for i=0,nSelVis-1 do begin
        oDataSpace = oSelVis[i]->GetDataSpace()
        if (N_TAGS(oDataSpace->GetProjection()) gt 0) then $
            return, 0
    endfor

    return, 1

end


;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitopCropImage__Define
;
; Purpose:
;   This procedure defines the object structure for the IDLitopCropImage
;   object class.
;
pro IDLitopCropImage__Define

    compile_opt idl2, hidden

    struc = {IDLitopCropImage,         $
        inherits IDLitDataOperation,   $
        _x0: 0.0d,                     $ ; Lower left corner of crop box
        _y0: 0.0d,                     $ ;   in data coordinates.
        _width: 0.0d,                  $ ; Dimensions of crop box
        _height: 0.0d,                 $ ;   in data coordinates.
        _units: 0,                     $ ; Units of measure to use
                                       $ ;   when reporting crop box
        _oCurrTarget: OBJ_NEW(),       $ ; Current target of execution.
        _oSubCropCmds: OBJ_NEW(),      $ ; Collection of commands for
                                       $ ;   cropping dependents.
        _oPropSet: OBJ_NEW()          $
    }
end

