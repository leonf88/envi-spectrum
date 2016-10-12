; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopcustomizeimagetool__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopCustomizeImageTool
;
; Purpose:
;   This class implements an operation that customizes the contents
;   of the image tool.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::Init
;
; Purpose:
;   This function method initializes the object.
;
; Return Value:
;   This method returns a 1 on success, or 0 on failure.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.
;
function IDLitopCustomizeImageTool::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(_EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopCustomizeImageTool::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitOperation::Cleanup
;end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::GetProperty
;
; Arguments:
;   <None>
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to
;   IDLitopCustomizeImageTool::Init followed by the word "Get" can be retrieved
;   using this method.
;
;pro IDLitopCustomizeImageTool::GetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::GetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Name:
;   IDLitopCustomizeImageTool::SetProperty
;
; Purpose:
;   This procedure method sets the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to
;   IDLitopCustomizeImageTool::Init followed by the word "Set" can be set
;   using this method.
;
;pro IDLitopCustomizeImageTool::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::UndoOperation
;
; Purpose:
;   This function performs an Undo of the commands contained in the
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopCustomizeImageTool::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=nObjs-1, 0, -1 do begin

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        ; Retrieve the appropriate values.
        if (OBJ_ISA(oTarget, 'IDLitVisNormDataSpace')) then begin
            iStatus = oCmds[i]->GetItem("INITIAL_ANISO_SCALE2D", $
                anisoScale2D)
            if (iStatus eq 0) then return, 0

            ; Apply the appropriate properties.
            oTarget->SetProperty, $
                ANISOTROPIC_SCALE_2D=anisoScale2D

        endif else if (OBJ_ISA(oTarget, 'IDLitWindow')) then begin
            iStatus = oCmds[i]->GetItem("INITIAL_VIRTUAL_DIMENSIONS", $
                virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem($
                "INITIAL_MINIMUM_VIRTUAL_DIMENSIONS", minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_VISIBLE_LOCATION", $
                visibleLoc)
            if (iStatus eq 0) then return, 0

            ; Apply the virtual dimensions.
            oTarget->SetProperty, VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc

        endif else if (OBJ_ISA(oTarget, 'IDLitgrView')) then begin
            iStatus = oCmds[i]->GetItem("INITIAL_ZOOM", zoom)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_VIRTUAL_DIMENSIONS", $
                virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem($
                "INITIAL_MINIMUM_VIRTUAL_DIMENSIONS", minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem($
                "INITIAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then return, 0

            ; Apply the appropriate properties.
            oTarget->SetCurrentZoom, zoom
            oTarget->SetProperty, $
                VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc
        endif
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::RedoOperation
;
; Purpose:
;   This function performs a Redo of the commands contained in the
;   given command set.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
function IDLitopCustomizeImageTool::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=0,nObjs-1 do begin

        ; Get the target object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        ; Retrieve the appropriate values.
        if (OBJ_ISA(oTarget, 'IDLitVisNormDataSpace')) then begin
            iStatus = oCmds[i]->GetItem("FINAL_ANISO_SCALE2D", $
                anisoScale2D)
            if (iStatus eq 0) then return, 0

            ; Apply the appropriate properties.
            oTarget->SetProperty, $
                ANISOTROPIC_SCALE_2D=anisoScale2D

        endif else if (OBJ_ISA(oTarget, 'IDLitWindow')) then begin
            iStatus = oCmds[i]->GetItem("FINAL_VIRTUAL_DIMENSIONS", $
                virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem($
                "FINAL_MINIMUM_VIRTUAL_DIMENSIONS", minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem($
                "FINAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then return, 0

            ; Apply the virtual dimensions.
            oTarget->SetProperty, VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc

        endif else if (OBJ_ISA(oTarget, 'IDLitgrView')) then begin
            iStatus = oCmds[i]->GetItem("FINAL_ZOOM", zoom)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_VIRTUAL_DIMENSIONS", $
                virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_MINIMUM_VIRTUAL_DIMENSIONS", $
                minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_VISIBLE_LOCATION", visibleLoc)
            if (iStatus eq 0) then return, 0

            ; Apply the appropriate properties.
            oTarget->SetCurrentZoom, zoom
            oTarget->SetProperty, $
                VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc
        endif
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::RecordInitialValues
;
; Purpose:
;   This function method records the initial values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
; Notes:
;   The oTargets argument must be one (or more) references to
;   (an) IDLitVisNormDataSpace object(s).
;
function IDLitopCustomizeImageTool::RecordInitialValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    ; Loop through and record zoom properties for each target.
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_VALID(oTargets[i]) eq 0) then $
            continue

        ; Retrieve the initial zoom property values.
        oTargets[i]->GetProperty, $
            ANISOTROPIC_SCALE_2D=anisoScale2D

        ; Create a command that stores the initial view properties.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oTargets[i]->GetFullIdentifier())

        iStatus = oCmd->AddItem("INITIAL_ANISO_SCALE2D", anisoScale2D)
        if (iStatus eq 0) then return, 0

        oCommandSet->Add, oCmd


        if (~oTargets[i]->_GetWindowandViewG(oWin, oView)) then $
            return, 0
        ; Create a command that stores the initial window virtual dimensions.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oWin->GetFullIdentifier())
        oWin->GetProperty, VIRTUAL_DIMENSIONS=virtualDims, $
            MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
            VISIBLE_LOCATION=visibleLoc

        iStatus = oCmd->AddItem("INITIAL_VIRTUAL_DIMENSIONS", virtualDims)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_MINIMUM_VIRTUAL_DIMENSIONS", $
            minVirtualDims)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_VISIBLE_LOCATION", $
            visibleLoc)
        if (iStatus eq 0) then return, 0

        oCommandSet->Add, oCmd

        ; Create a command that stores the initial view properties.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oView->GetFullIdentifier())

        oView->GetProperty, $
            CURRENT_ZOOM=zoom, $
            VIRTUAL_DIMENSIONS=virtualDims, $
            MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
            VISIBLE_LOCATION=visibleLoc

        iStatus = oCmd->AddItem("INITIAL_ZOOM", zoom)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_VIRTUAL_DIMENSIONS", virtualDims)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_MINIMUM_VIRTUAL_DIMENSIONS", $
            minVirtualDims)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_VISIBLE_LOCATION", $
            visibleLoc)
        if (iStatus eq 0) then return, 0

        oCommandSet->Add, oCmd

    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::RecordFinalValues
;
; Purpose:
;   This function method records the final values needed to
;   perform undo/redo of the operation.
;
; Return Value:
;   This function returns a 1 on success, or a 0 on failure.
;
; Notes:
;   The oTargets argument must be one (or more) references to
;   (an) IDLitVisNormDataSpace object(s).
;
function IDLitopCustomizeImageTool::RecordFinalValues, oCommandSet, $
    oTargets, idProperty

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    ; Loop through and record current ranges for each target.
    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=0, nObjs-1 do begin
        oCmd = oCmds[i]
        oCmd->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        if (OBJ_ISA(oTarget, 'IDLitVisNormDataSpace')) then begin
            ; Retrieve the final dataspace property values.
            oTarget->GetProperty, $
                ANISOTROPIC_SCALE_2D=anisoScale2D

            iStatus = oCmd->AddItem("FINAL_ANISO_SCALE2D", anisoScale2D)
            if (iStatus eq 0) then return, 0

        endif else if (OBJ_ISA(oTarget, 'IDLitWindow')) then begin
            ; Retrieve the final window virtual dimensions.
            oTarget->GetProperty, VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc

            iStatus = oCmd->AddItem("FINAL_VIRTUAL_DIMENSIONS", virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmd->AddItem("FINAL_MINIMUM_VIRTUAL_DIMENSIONS", $
                minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmd->AddItem("FINAL_VISIBLE_LOCATION", $
                visibleLoc)
            if (iStatus eq 0) then return, 0

        endif else if (OBJ_ISA(oTarget, 'IDLitgrView')) then begin
            ; Retrieve the final view property values.
            oTarget->GetProperty, $
                CURRENT_ZOOM=zoom, $
                VIRTUAL_DIMENSIONS=virtualDims, $
                MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
                VISIBLE_LOCATION=visibleLoc

            iStatus = oCmd->AddItem("FINAL_ZOOM", zoom)
            if (iStatus eq 0) then return, 0

            iStatus = oCmd->AddItem("FINAL_VIRTUAL_DIMENSIONS", virtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmd->AddItem("FINAL_MINIMUM_VIRTUAL_DIMENSIONS", $
                minVirtualDims)
            if (iStatus eq 0) then return, 0

            iStatus = oCmd->AddItem("FINAL_VISIBLE_LOCATION", $
                visibleLoc)
            if (iStatus eq 0) then return, 0

        endif
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::DoAction
;
; Purpose:
;   This function method performs the primary action associated with
;   this operation, namely to customize the image tool.
;
; Return Value:
;   This function returns a reference to the command set object
;   corresponding to the act of performing this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this operation
;     is to be performed.
;
function IDLitopCustomizeImageTool::DoAction, oTool

    compile_opt idl2, hidden

    self->_SetTool, oTool

    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()

    ; Retrieve the dataspace.
    oView = oWin->GetCurrentView()
    oLayer = (OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW())
    oWorld = (OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW())
    oAllDS = (OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW())
    if (~OBJ_VALID(oAllDS[0])) then $
        return, OBJ_NEW()

    oTargets = oAllDS

    ; Create command set.
    oCmdSet = OBJ_NEW('IDLitCommandSet', $
        NAME='Customize image tool', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier())

    ; Record initial values for undo.
    iStatus = self->RecordInitialValues(oCmdSet, oTargets, '')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    self->Customize, TARGETS=oTargets

    ; Record final values for redo.
    iStatus = self->RecordFinalValues( oCmdSet, oTargets, '')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    return, oCmdSet
end

;-------------------------------------------------------------------------
; Customize Operation Interface
;-------------------------------------------------------------------------

;---------------------------------------------------------------------------
; IDLitopCustomizeImageTool::Customize
;
; Purpose:
;   This procedure method performs the necessary customization
;   of the targets.
;
; Keywords:
;   TARGETS: Set this keyword to a vector of reference to the dataspaces
;     that are to be to be customized.  By default, the dataspaces in
;     the current view are customized.
;
pro IDLitopCustomizeImageTool::Customize, $
    TARGETS=oTargets

    compile_opt idl2, hidden

    oTool = self->GetTool()

    if (N_ELEMENTS(oTargets) eq 0) then begin
        ; Targets not provided by the caller.  Use current
        ; dataspace in tool's current window/view.
        bDefaultTargets = 1b
        oWin = (OBJ_VALID(oTool) ? oTool->GetCurrentWindow() : OBJ_NEW())
        oView = (OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW())
        oLayer = (OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW())
        oWorld = (OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW())
        oTargets = (OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW())
        if (~OBJ_VALID(oTargets[0])) then $
            return
    endif else $
        bDefaultTargets = 0b

    nTargets = N_ELEMENTS(oTargets)
    for i=0,nTargets-1 do begin
        oDS = oTargets[i]

        ; If not already done before, get the corresponding window and view.
        if (~bDefaultTargets) then begin
            if (~oDS->_GetWindowandViewG(oWin, oView)) then $
                return
        endif

        ; Set anisotropic 2D scale factor to 1.0.
        oDS->SetProperty, $
            ANISOTROPIC_SCALE_2D=1.0

        oScaleTargets = oView->GetPixelScaleTargets(COUNT=nTargets)
        if (nTargets gt 0) then begin
            oTarget = oScaleTargets[0]

            viewportDims = oView->GetViewport(oWin, /VIRTUAL, $
                LOCATION=viewportLoc)

            if (oTarget->_GetImageDimensions(imgDims)) then begin
                visDims = oWin->GetDimensions(VIRTUAL_DIMENSIONS=virtualDims)

                ; If the viewport is intended to fill the window, then
                ; update the window virtual dimensions to match target image
                ; dimensions (allowing a bit extra padding).
                newDims = LONARR(2)
                pad = 0.15d
                newDims = ULONG((DOUBLE(imgDims) / $
                                (2.0 * (0.5-pad))) + 0.5)
                maxMargin = 0.49d

                if ((viewportLoc[0] eq 0) && $
                    (viewportLoc[1] eq 0) && $
                    (viewportDims[0] eq virtualDims[0]) && $
                    (viewportDims[1] eq virtualDims[1])) then begin

                    ; Viewport fills destination.  Adjust virtual canvas to
                    ; be larger of:
                    ;   - image plus margins
                    ;   - visible window dimensions (but constrain so that
                    ;     margins do not exceed maximum)
                    newWinDims = newDims
                    if (newDims[0] lt visDims[0]) then begin
                        bExceedMargin = ((1.0d - (imgDims[0]/visDims[0])) * $
                            0.5) gt maxMargin
                        newWinDims[0] = bExceedMargin ? $
                            imgDims[0] / (1.0d - (2*maxMargin)) : visDims[0]
                    endif
                    if (newDims[1] lt visDims[1]) then begin
                        bExceedMargin = ((1.0d - (imgDims[1]/visDims[1])) * $
                            0.5) gt maxMargin
                        newWinDims[1] = bExceedMargin ? $
                            imgDims[1] / (1.0d - (2*maxMargin)) : visDims[1]
                    endif

                    ; Set the virtual dimensions.
                    oWin->SetProperty, VIRTUAL_DIMENSIONS=newWinDims, $
                        MINIMUM_VIRTUAL_DIMENSIONS=newWinDims
                    if (OBJ_ISA(oWin, '_IDLitgrDest')) then $
                        oWin->SetProperty, WINDOW_ZOOM=1.0

                    ; Also set the minimum virtual dimensions on the
                    ; view, so that if a viewport change occurs later
                    ; (as for a layout change), the minimum will be honored.
                    oWin->GetProperty, CURRENT_ZOOM=canvasZoom
                    visViewDims = newWinDims / canvasZoom
                    newViewDims = newDims > visViewDims
                    oView->GetProperty, CURRENT_ZOOM=viewZoom
                    oView->SetProperty, $
                        VIRTUAL_WIDTH=newViewDims[0]*viewZoom, $
                        VIRTUAL_HEIGHT=newViewDims[1]*viewZoom

                    ; Scroll the window so that the top-left corner of
                    ; the target is at the top-left of the viewport.
                    destScrollDims = oWin->GetDimensions( $
                        VISIBLE_LOCATION=destScrollLoc, $
                        VIRTUAL_DIMENSIONS=virtualDims)
                    if (oTarget->GetXYZRange(xr,yr,zr, $
                        /NO_TRANSFORM)) then begin
                        oTarget->VisToWindow, xr, yr, zr, wx, wy, wz

                        scrollX = destScrollLoc[0]
                        scrollY = destScrollLoc[1]
                        if (destScrollDims[0] le virtualDims[0]) then begin
                            if (imgDims[0] le destScrollDims[0]) then begin
                                ; Center the image!
                                scrollX = $
                                    (virtualDims[0] - destScrollDims[0]) * 0.5
                            endif else begin
                                ; Position left edge of image at left edge
                                ; of visible viewport.
                                scrollX += wx[0]
                            endelse
                        endif

                        if (destScrollDims[1] le virtualDims[1]) then begin
                            if (imgDims[1] le destScrollDims[1]) then begin
                                ; Center the image!
                                scrollY = $
                                    (virtualDims[1] - destScrollDims[1]) * 0.5
                            endif else begin
                                ; Position upper edge of image at upper edge
                                ; of visible viewport.
                                scrollY += wy[1]
                                scrollY -= destScrollDims[1]
                            endelse
                        endif

                        if ((scrollX ne destScrollLoc[0]) || $
                            (scrollY ne destScrollLoc[1])) then $
                            oWin->SetProperty, $
                                VISIBLE_LOCATION=[scrollX,scrollY]
                    endif
                endif else begin
                    ; Viewport does not fill the destination.
                    ;
                    ; Set view virtual dimensions equal to the larger
                    ; of:
                    ;   - image plus margins
                    ;   - visible viewport (but constrain so that
                    ;     margins do not exceed maximum)
                    fullViewDims = oView->GetViewport(oWin, /VIRTUAL, $
                        LOCATION=fullViewLoc)
                    oWin->GetProperty, CURRENT_ZOOM=canvasZoom
                    visViewDims = fullViewDims / canvasZoom

                    if (newDims[0] lt visViewDims[0]) then begin
                        bExceedMargin = $
                            ((1.0d - (imgDims[0]/visViewDims[0])) * $
                            0.5) gt maxMargin
                        newDims[0] = bExceedMargin ? $
                            imgDims[0] / (1.0d - (2*maxMargin)) : $
                            visViewDims[0]
                    endif
                    if (newDims[1] lt visViewDims[1]) then begin
                        bExceedMargin = $
                            ((1.0d - (imgDims[1]/visViewDims[1])) * $
                            0.5) gt maxMargin
                        newDims[1] = bExceedMargin ? $
                            imgDims[1] / (1.0d - (2*maxMargin)) : $
                            visViewDims[1]
                    endif

                    ; Set the virtual dimensions.
                    oView->GetProperty, CURRENT_ZOOM=viewZoom
                    oView->SetProperty, VIRTUAL_WIDTH=newDims[0]*viewZoom, $
                        VIRTUAL_HEIGHT=newDims[1]*viewZoom

                    ; Scroll the virtual view so that the top-left corner of
                    ; the target is at the top-left of the visible viewport.
                    destScrollDims = oWin->GetDimensions( $
                        VISIBLE_LOCATION=destScrollLoc)
                    virtViewDims = oView->GetVirtualViewport(oWin)
                    oView->GetProperty, VISIBLE_LOCATION=visibleLoc

                    scrollX = visibleLoc[0]
                    scrollY = visibleLoc[1]
                    if (oTarget->GetXYZRange(xr,yr,zr, $
                        /NO_TRANSFORM)) then begin
                        oTarget->VisToWindow, xr, yr, zr, wx, wy, wz
                        oView->GetProperty, VISIBLE_LOCATION=visibleLoc
                        if (visViewDims[0] le virtViewDims[0]) then begin
                            if (imgDims[0] le visViewDims[0]) then begin
                                ; Center the image!
                                scrollX = $
                                    (virtViewDims[0] - visViewDims[0]) * 0.5
                            endif else begin
                                ; Position left edge of image at left edge
                                ; of visible viewport.

                                ; Transform from visible window to virtual
                                ; window coordinates.
                                ulx = wx[0] + destScrollLoc[0]

                                ; Transform from virtual window to visible
                                ; viewport coordinates.
                                ulx = ulx - fullViewLoc[0]

                                ; Transform from visible viewport to virtual
                                ; viewport coordinates.
                                ulx = (ulx / canvasZoom) + visibleLoc[0]

                                scrollX = ulx
                            endelse
                        endif
                        if (visViewDims[1] le virtViewDims[1]) then begin
                            if (imgDims[1] le visViewDims[1]) then begin
                                ; Center the image!
                                scrollY = $
                                    (virtViewDims[1] - visViewDims[1]) * 0.5
                            endif else begin
                                ; Position top edge of image at top edge
                                ; of visible viewport.

                                ; Transform from visible window to virtual
                                ; window coordinates.
                                uly = wy[1] + destScrollLoc[1]

                                ; Transform from virtual window to visible
                                ; viewport coordinates.
                                uly = uly - fullViewLoc[1]

                                ; Transform from visible viewport to virtual
                                ; viewport coordinates.
                                uly = (uly / canvasZoom) + visibleLoc[1]
                                uly -= visViewDims[1]

                                scrollY = uly
                            endelse
                        endif

                        if ((scrollX ne 0) || (scrollY ne 0)) then begin
                            oView->SetProperty, $
                                VISIBLE_LOCATION=[scrollX, scrollY]
                        endif
                    endif
                endelse

                ; Activate the pan manipulator if appropriate.
                bDoPan = 0b
                oManipPan = oTool->IDLitContainer::GetByIdentifier( $
                    "MANIPULATORS/VIEWPAN")
                if (OBJ_VALID(oManipPan)) then $
                    bDoPan = oManipPan->QueryAvailability(oTool, oView)
                if (bDoPan) then $
                    oTool->ActivateManipulator, "VIEWPAN"

            endif
        endif
    endfor
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
; IDLitopCustomizeImageTool__Define
;
; Purpose:
;   Define the object structure for the IDLitopCustomizeImageTool class.
;
pro IDLitopCustomizeImageTool__define

    compile_opt idl2, hidden

    struc = {IDLitopCustomizeImageTool,   $
        inherits IDLitOperation           $
    }

end

