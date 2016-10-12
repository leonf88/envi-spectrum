; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipcropbox__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipCropBox
;
; PURPOSE:
;   The IDLitManipCropBox class represents a manipulator used to select
;   the bounding box of a region to be cropped from a target.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
; IDLitManipCropBox::Init
;
; Purpose:
;   The IDLitManipCropBox::Init function method initializes the
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; Calling Sequence:
;   oManipulator = OBJ_NEW('IDLitManipCropBox')
;
function IDLitManipCropBox::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Initialize the superclass.
    iStatus = self->IDLitManipulator::Init( $
        IDENTIFIER="Crop Box", $
        NAME="Crop", $
        TYPES=['IDLIMAGE'], $
        NUMBER_DS='1', $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0



    ; Register the cursors for this manipulator.
    self->IDLitManipCropBox::_DoRegisterCursor

    ; Register properties.
    self->RegisterProperty, 'RECTANGLE', USERDEF='', $
        NAME='Crop Rectangle'

    ; Set properties.
    self->IDLitManipCropBox::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::Cleanup
;
; Purpose:
;   The IDLitManipCropBox::Cleanup procedure method cleans up the
;   component object.
;
pro IDLitManipCropBox::Cleanup
    ; pragmas
    compile_opt idl2, hidden

    ; Destroy the crop box visual.
    if (OBJ_VALID(self._oCropVis)) then begin
        self._oCropVis->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->Remove, self._oCropVis
        OBJ_DESTROY, self._oCropVis
    endif

    ; Clean up stored crop creation/translation/resize commands.
    OBJ_DESTROY, self._oCropCmds

    ; Cleanup the font used for resize handles.
    OBJ_DESTROY, self._oFont

    self->IDLitManipulator::Cleanup
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::GetProperty
;
; Purpose:
;   This procedure method returns the values of one or more properties.
;
pro IDLitManipCropBox::GetProperty, $
    RECTANGLE=rectangle, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(rectangle)) then begin
        if (OBJ_VALID(self._oCropOp)) then begin
            self._oCropOp->GetCropBox, x, y, w, h, UNITS=0
            rectangle = [x,y,w,h]
        endif else $
            rectangle = [0.0,0,0,0]
    endif

    ; Pass along to the superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitManipulator::GetProperty, _EXTRA=_extra
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::SetProperty
;
; Purpose:
;   This procedure method sets the values of one or more properties.
;
pro IDLitManipCropBox::SetProperty, $
    RECTANGLE=rectangle, $
    _EXTRA=_extra

    compile_opt idl2, hidden
    if (N_ELEMENTS(rectangle) gt 0) then begin
         if (OBJ_VALID(self._oCropOp)) then begin
            self._oCropOp->SetCropBox, rectangle[0], rectangle[1], $
                rectangle[2], rectangle[3], UNITS=0, $
                /ALLOW_ZERO_DIMENSIONS

            ; Update the crop box visual.
            self->_SetCropBox
        endif
    endif

    ; Pass along to the superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitManipulator::SetProperty, _EXTRA=_extra
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., images) to be manipulated by this manipulator
;   (based upon the given list of visualizations currently selected).
;
;   Note: This overrides the implementation of the same method provided
;   by the superclass.  This allows the crop manipulator to be active even
;   when a child of an image (such as an ROI) is currently selected.
;   Since ROIs are manipulator targets, the superclass implementation
;   will not walk up to the parent image as a potential manipulator
;   target.
;
function IDLitManipCropBox::_FindManipulatorTargets, oVisIn, $
    MERGE=merge

    compile_opt idl2, hidden

    if (not OBJ_VALID(oVisIn[0])) then $
        return, OBJ_NEW()

    if (KEYWORD_SET(merge)) then begin
        nTargets = N_ELEMENTS(oVisIn)
        oTargets = oVisIn
    endif else $
        nTargets = 0
    for i=0, N_ELEMENTS(oVisIn)-1 do begin
        oParent = oVisIn[i]
        while OBJ_VALID(oParent) do begin
            if (~OBJ_ISA(oParent, "_IDLitVisualization")) then $
                break

            ; Seek a visualization of type IDLIMAGE at this visualization
            ; or among any of its parentage.
            oParent->GetProperty, TYPE=type
            if (type eq 'IDLIMAGE') then begin
                oTargets = (nTargets eq 0) ? oParent : [oTargets, oParent]
                nTargets++
                break
            endif
            oParent->GetProperty, PARENT=oTmp
            oParent = oTmp
        endwhile
        if not OBJ_VALID(oParent) then $
          continue
    endfor

    if (nTargets eq 0) then $
        return, OBJ_NEW()

    ; Remove dups. Can't use UNIQ because we need to preserve the order.
    oUniqVis = oTargets[0]
    for i=1, nTargets-1 do begin
        if (TOTAL(oUniqVis eq oTargets[i]) eq 0) then $
            oUniqVis = [oUniqVis, oTargets[i]]
    endfor

    return, oUniqVis
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::_SetTarget
;
; Purpose:
;   This procedure method sets the current target of this manipulator.
;
; Arguments:
;   oTarget: A reference to the new target for this manipulator.
;
pro IDLitManipCropBox::_SetTarget, oTarget
    compile_opt idl2, hidden

    ; Store a reference to the target.
    self._oTarget = oTarget

    if (OBJ_VALID(oTarget)) then begin
        ; Cache the XY range of the target visualization.
        oTarget->_IDLitVisGrid2D::GetProperty, $
            GRID_DIMENSIONS=gridDimensions, GRID_STEP=gridStep
        oTarget->GridToGeometry, 0, 0, tx0, ty0, /CENTER_ON_PIXEL
        oTarget->GridToGeometry, gridDimensions[0]-1, gridDimensions[1]-1, $
            tx1, ty1, /CENTER_ON_PIXEL
        self._targetXRange = [tx0,tx1]
        self._targetYRange = [ty0,ty1]
        self._halfPixel = gridStep * 0.5
    endif

    ; If the crop box visual exists and was previously being displayed,
    ; remove it now from its former target.
    ; Otherwise, go ahead and create the crop box visual.
    if (OBJ_VALID(self._oCropVis)) then begin
        self._oCropVis->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->Remove, self._oCropVis, /NO_UPDATE
    endif else $
        self->_PrepareCropBoxVisual
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::_DoHitTest
;
; Purpose:
;   This procedure method performs a hit test, determines if any
;   manipulator visuals are hit, and updates the current subtype if so.
;
pro IDLitManipCropBox::_DoHitTest, oWin, x, y

    compile_opt idl2, hidden

    ; Do the hit test
    oVis = (oWin->DoHitTest(x, y, DIMENSIONS=[9,9], /ORDER, $
                              SUB_HIT=oSubHitList, $
                              VIEWGROUP=oHitViewGroup))[0]

    ; Check for a manipulator visual among the hit lists.
    oSubHitCopy = oSubHitList
    oManipVis = OBJ_NEW()
    if (OBJ_ISA(oVis, 'IDLitManipulatorVisual')) then begin
        oManipVis = oVis
    endif else begin
        n = N_ELEMENTS(oSubHitList)
        for i=0,n-1 do begin
            if OBJ_ISA(oSubHitList[i], 'IDLitManipulatorVisual') then begin
                ; Here is our manipulator visual.
                oManipVis = oSubHitList[i]
                ; Only keep the subvis's after the manip visual.
                oSubHitList = oSubHitList[(i+1)< (n-1):*]
                break        ; we're done
            endif
        endfor
    endelse

    ; If we hit a manipulator visual, change the current subtype.
    if (OBJ_VALID(oManipVis)) then begin
        type = oManipVis->GetSubHitType(oSubHitList)
        ; Set the manipulator using the type.
        self->SetCurrentManipulator, type
    endif else if (OBJ_VALID(oVis)) then $
        self->SetCurrentManipulator ;; do the default
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::RecordUndoValues
;
; Purpose:
;   This function method records initial values for the undo-redo buffer.
;
function IDLitManipCropBox::RecordUndoValues

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    if (~OBJ_VALID(self._oCropOp)) then $
        return, 0

    ; Destroy any previous command sets.
    if (OBJ_VALID(self._oCmdSet)) then $
        OBJ_DESTROY, self._oCmdSet

    ; Retrieve the SetProperty operation.
    oOperation = oTool->GetService("SET_PROPERTY")
    if (~OBJ_VALID(oOperation)) then begin
        self._oCmdSet = OBJ_NEW()
        return, 0
    endif

    ; Prepare a name for the command.
    case self._subtype of
        '' : cmdName = 'Create Crop Box'
        'Crop Box/Translate': cmdName = 'Translate Crop Box'
        else: begin
            if (STRPOS(self._subType, 'Crop Box/Resize') ge 0) then $
                cmdName = 'Resize Crop Box' $
            else $
                cmdName = 'Crop'
        end
    endcase

    ; Create the command set.
    self._oCmdSet = OBJ_NEW('IDLitCommandSet', NAME=cmdName, $
        OPERATION_IDENTIFIER=oOperation->GetFullIdentifier())

    if (~OBJ_VALID(self._oCmdSet)) then $
         return, 0

    ; Record initial values.
    iStatus = oOperation->RecordInitialValues(self._oCmdSet, $
        self, "RECTANGLE")
    if (iStatus eq 0) then begin
        OBJ_DESTROY, self._oCmdSet
        self._oCmdSet = OBJ_NEW()
        return, 0
    endif

    return, 1
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::CommitUndoValues
;
; Purpose
;   This function method records final values and commits them
;   to the undo-redo buffer.
;
function IDLitManipCropBox::CommitUndoValues, UNCOMMIT=uncommit
    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oCmdSet)) then $
        return, 0

    oTool = self->GetTool()
    if (KEYWORD_SET(uncommit) || $
        ~OBJ_VALID(oTool) || $
        ~OBJ_VALID(self._oCropOp)) then begin
        OBJ_DESTROY, self._oCmdSet
        self._oCmdSet = OBJ_NEW()
        return, 0
    endif

    ; Retrieve the SetProperty operation.
    oOperation = oTool->GetService("SET_PROPERTY")
    if (~OBJ_VALID(oOperation))then begin
        OBJ_DESTROY, self._oCmdSet
        self._oCmdSet = OBJ_NEW()
        return, 0
    endif

    ; Record final values.
    iStatus = oOperation->RecordFinalValues( self._oCmdSet, $
                                             self, $
                                             /SKIP_MACROHISTORY, $
                                             "RECTANGLE")

    if (iStatus ne 0) then begin
        ; Add to the command queue
        oTool->_TransactCommand, self._oCmdSet
        iStatus = 1

        ; Add to our own container so that any creation/translation/resize
        ; commands can be removed from the undo/redo buffer once the
        ; crop is actually performed.
        if (~OBJ_VALID(self._oCropCmds)) then $
            self._oCropCmds = OBJ_NEW('IDL_Container')
        self._oCropCmds->Add, self._oCmdSet
    endif else $
        OBJ_DESTROY, self._oCmdSet

    self._oCmdSet = OBJ_NEW() ; null it out

    return, iStatus
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
pro IDLitManipCropBox::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    oTool = self->GetTool()

    if (iButton ne 1) then begin

        ; Call our superclass.
        self->IDLitManipulator::OnMouseDown, $
            oWin, x, y, iButton, KeyMods, nClicks

        ; If the current selections do not match this manipulator,
        ; revert to the default manipulator.
        if (self.nSelectionList eq 0) then begin
            if (OBJ_VALID(oTool)) then $
                oTool->ActivateManipulator, /DEFAULT
        endif

        return
    endif

    ; Perform a hit test.
    ; Update subtype if any manipulator visuals are hit.
    self->_DoHitTest, oWin, x, y

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    if (~OBJ_VALID(self._oCropOp)) then begin
        if (OBJ_VALID(oTool)) then $
            oTool->ActivateManipulator, /DEFAULT
        return
    endif

    if ((nClicks eq 2) && OBJ_VALID(self._oTarget)) then begin
        self.ButtonPress = 0
        self->_DoCrop
        return
    endif

    if (self.nSelectionList eq 0) then begin
        if (OBJ_VALID(oTool)) then $
            oTool->ActivateManipulator, /DEFAULT
        return
    endif

    ; Use first selected image as the representative target.
    nImg = self.nSelectionList
    if (nImg gt 0) then begin
        oImg = (*self.pSelectionList)[0]
        self->_SetTarget, oImg
    endif

    case self._subtype of
        '': begin  ; No manipulator visuals hit - create a crop box

oImg = self._oTarget
            if (OBJ_VALID(oImg)) then begin

                ; Transform the window location to the target's data
                ; coordinates.
                oView = oWin->GetCurrentView()
                oLayer = oView->GetCurrentLayer()
                if (oWin->Pickdata(oLayer, oImg, [x,y], xyVis) ne 1) then $
                    oImg = OBJ_NEW()
            endif

            if (OBJ_VALID(oImg)) then begin

                ; Map geometry location to nearest grid location
                oImg->GeometryToGrid, xyVis[0], xyVis[1], gridX0, gridY0
                self._gridXY0 = [gridX0, gridY0]
                self._gridXY1 = [gridX0, gridY0]

                ; Inform the operation of the current crop box.
                self._oCropOp->SetCropBox, gridX0, gridY0, 0, 0, $
                    TARGET=oImg, UNITS=1, /ALLOW_ZERO_DIMENSIONS

                ; Update the crop box visual.
                self->_SetCropBox, /ALLOW_SMALL
                if (OBJ_VALID(oTool)) then $
                    oTool->RefreshCurrentWindow

                ; Update the status message.
                self->StatusMessage, $
                    IDLitLangCatQuery('Status:CropBoxDefine:Text')

            endif else begin
                self._oTarget = OBJ_NEW()

                ; Remove display of the crop box.
                if (OBJ_VALID(self._oCropVis)) then begin
                    self._oCropVis->GetProperty, PARENT=oParent
                    if (OBJ_VALID(oParent)) then $
                        oParent->Remove, self._oCropVis
                endif

                ; Inform the operation of the current crop box.
                self._oCropOp->SetCropBox, 0, 0, 0, 0, $
                    TARGET=self._oTarget, UNITS=1, /ALLOW_ZERO_DIMENSIONS

                self._gridXY0 = [0,0]
                self._gridXY1 = [0,0]

                ; Update the crop box visual.
                self->_SetCropBox, /ALLOW_SMALL

                ; Restore status message.
                statusMsg = self->GetStatusMessage('', KeyMods)
                self->StatusMessage, statusMsg

            endelse
        end

        'Crop Box/Translate': begin

            if (OBJ_VALID(self._oTarget)) then begin
                ; Transform the window location to the target's data
                ; coordinates.
                oView = oWin->GetCurrentView()
                oLayer = oView->GetCurrentLayer()
                if (oWin->Pickdata(oLayer, self._oTarget, [x,y], xyVis) $
                    eq 1) then begin

                    ; Retrieve the current coordinates of the crop box.
                    self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
                        TARGET=self._oTarget, UNITS=0
                    cx1 = cx0 + cW
                    cy1 = cy0 + cH

                    ; Stash the original crop box coordinates.
                    self._initCropXY0 = [cx0,cy0]
                    self._initCropXY1 = [cx1,cy1]

                    ; Store the mouse down location.
                    self._startXY = xyVis[0:1]

                    ; Update the status message.
                    self->StatusMessage, $
                        IDLitLangCatQuery('Status:CropBoxTranslate:Text')
                endif
            endif
        end

        else: begin
            if (STRPOS(self._subType, 'Crop Box/Resize') ge 0) then begin
              if (OBJ_VALID(self._oTarget)) then begin

                ; Transform the window location to the target's data
                ; coordinates.
                oView = oWin->GetCurrentView()
                oLayer = oView->GetCurrentLayer()
                if (oWin->Pickdata(oLayer, self._oTarget, [x,y], xyVis) $
                    eq 1) then begin

                    ; Retrieve the current coordinates of the crop box.
                    self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
                        TARGET=self._oTarget, UNITS=0
                    cx1 = cx0 + cW
                    cy1 = cy0 + cH

                    ; Stash the original crop box coordinates.
                    self._initCropXY0 = [cx0,cy0]
                    self._initCropXY1 = [cx1,cy1]

                    ; Store the mouse down location.
                    self._startXY = xyVis[0:1]

                    ; Update the status message.
                    self->StatusMessage, $
                        IDLitLangCatQuery('Status:CropBoxResize:Text')
                endif
              endif
            endif
        end

    endcase

    iStatus = self->RecordUndoValues()

end

;--------------------------------------------------------------------------
; IDLitManipCropBox::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipCropBox::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    if (iButton ne 1) then begin
        ; Call our superclass.
        self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
        return
    endif

    if (~OBJ_VALID(self._oCropOp)) then begin
        ; Call our superclass.
        self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
        return
    endif

    self.ButtonPress = 0  ; button is up

    unCommit = 0b
    oImg = self._oTarget

    ; Retrieve the current crop box dimensions.
    self._oCropOp->GetCropBox, x, y, w, h, $
        TARGET=self._oTarget, UNITS=1

    if (OBJ_VALID(oImg)) then begin

        case self._subtype of

            '': begin  ; Creating a crop box.
                ; If the created crop box is too small, then do not
                ; commit the crop box creation.
                if ((w lt 2) || (h lt 2)) then $
                    unCommit = 1b
            end

            else: begin
            end
        endcase

        ; If the created crop box is too small, then do not
        ; display it.
        if ((w lt 2) || (h lt 2)) then begin
            if (OBJ_VALID(self._oCropVis)) then begin
                self._oCropVis->GetProperty, PARENT=oParent
                if (OBJ_VALID(oParent)) then begin
                    oParent->Remove, self._oCropVis
                    oTool = self->GetTool()
                    if (OBJ_VALID(oTool)) then $
                        oTool->RefreshCurrentWindow
                endif
            endif
        endif

        iStatus = self->CommitUndoValues(UNCOMMIT=unCommit)
    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    ; Restore status message.
    statusMsg = self->GetStatusMessage(self._subtype, 0)
    self->StatusMessage, statusMsg
end


;--------------------------------------------------------------------------
; IDLitManipCropBox::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipCropBox::OnMouseMotion, oWin, x, y, KeyMods
    ; pragmas
    compile_opt idl2, hidden

    if (self.ButtonPress ne 1) then begin
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
        return
    endif

    oImg = self._oTarget
    if (OBJ_VALID(oImg)) then begin
        ; Do a hit test to make sure the cursor is still over the target.
        oVisHitList = oWin->DoHitTest(x, y, /ORDER, VIEWGROUP=oView)
        if (oImg eq oVisHitList[0]) then begin
            ; Transform the window location to the target's data
            ; coordinates.
            oLayer = oView->GetCurrentLayer()
            if (oWin->Pickdata(oLayer, oImg, [x,y], xyVis) $
                ne 1) then $
                oImg = OBJ_NEW()
        endif else $
            oImg = OBJ_NEW()
    endif

    if (OBJ_VALID(oImg)) then begin

        case self._subtype of
            '': begin  ; Creating a crop box.
                x1 = (xyVis[0] > self._targetXRange[0]) < self._targetXRange[1]
                y1 = (xyVis[1] > self._targetYRange[0]) < self._targetYRange[1]

                ; Map geometry location to nearest grid location
                oImg->GeometryToGrid, x1, y1, gridX1, gridY1
                self._gridXY1 = [gridX1, gridY1]

                gx0 = MIN([self._gridXY0[0],gridX1], MAX=gx1)
                gy0 = MIN([self._gridXY0[1],gridY1], MAX=gy1)

                ; Inform the crop operation of the current crop box.
                self._oCropOp->SetCropBox, gx0, gy0, gx1-gx0+1, gy1-gy0+1, $
                    TARGET=oImg, UNITS=1

                ; Update the crop box visual.
                self->_SetCropBox, /ALLOW_SMALL

                ; Update the status message.
                self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
                    TARGET=self._oTarget, UNITS=0
                probeMsg = STRING(FORMAT='(%"[%g,%g] %gx%g")', $
                    cx0, cy0, cw, ch)
                self->ProbeStatusMessage, probeMsg
            end

            'Crop Box/Translate': begin

                ; Compute the delta relative to the original
                ; mouse down location.
                deltaXY = xyVis[0:1] - self._startXY

                ; Translate.
                self->_TranslateCropBox, deltaXY

            end

            else: begin
                if (STRPOS(self._subType, 'Crop Box/Resize') ge 0) then begin

                    ; Compute the delta relative to the original
                    ; mouse down location.
                    deltaXY = xyVis[0:1] - self._startXY

                    ; Resize.
                    self->_ResizeCropBox, deltaXY
                endif
            end
        endcase
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif else begin
        ; Call our superclass.
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
    endelse
end

;--------------------------------------------------------------------------
; IDLitManipCropBox::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Parameters
;      oWin        - Event Window Component
;      IsAlpha     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
pro IDLitManipCropBox::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oCropOp)) then $
        return

    ; Keyboard events only honored for translation.
    self->_DoHitTest, oWin, x, y
    if (self._subtype ne 'Crop Box/Translate') then $
        return

    if (~OBJ_VALID(self._oTarget)) then $
        return

    ; Check for arrow keys.
    if (~IsASCII) then begin
        if ((KeyValue ge 5) and (KeyValue le 8)) then begin
            if (Press) then begin

                self._oTarget->_IDLitVisGrid2D::GetProperty, $
                    GRID_STEP=gridStep

                ; Set offset according to key modifiers.
                case KeyMods of
                    1: offset = 10
                    else: offset = 1
                endcase
                case KeyValue of
                    5: deltaXY = [-(offset * gridStep[0]), 0.0]
                    6: deltaXY = [(offset * gridStep[0]), 0.0]
                    7: deltaXY = [0.0, (offset * gridStep[0])]
                    8: deltaXY = [0.0, -(offset * gridStep[0])]
                endcase

                ; Transform the window location to the target's data
                ; coordinates.
                oView = oWin->GetCurrentView()
                oLayer = oView->GetCurrentLayer()
                if (oWin->Pickdata(oLayer, self._oTarget, [x,y], xyVis) $
                    eq 1) then begin

                    ; Retrieve the current coordinates of the crop box.
                    self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
                        TARGET=self._oTarget, UNITS=0
                    cx1 = cx0 + cW
                    cy1 = cy0 + cH

                    ; Stash the original crop box coordinates.
                    self._initCropXY0 = [cx0,cy0]
                    self._initCropXY1 = [cx1,cy1]

                    ; Store the mouse down location.
                    self._startXY = xyVis[0:1]

                    ; Translate.
                    self->_TranslateCropBox, deltaXY
                    oTool = self->GetTool()
                    if (OBJ_VALID(oTool)) then $
                        oTool->RefreshCurrentWindow

                    self->StatusMessage, $
                        IDLitLangCatQuery('Status:CropBox:Text')
                endif

            endif

            ; Note: to avoid message flashing, the status message should
            ; not be restored on a key release.

        endif ; appropriate keys
    endif ; not ASCII

end


;---------------------------------------------------------------------------
; IDLitManipCropBox::UpdateToMatchOperation
;
; Purpose:
;   This procedure method does the following to ensure that this manipulator
;   is in synch with the crop operation:
;     - Remove the crop box visual from any old targets.
;     - If the operation's UI is currently active, display the
;       crop box visual (matching the crop operation's crop rectangle)
;     - If the operation's UI is not current active, then check if the
;       current crop rectangle is both large enough and fits within the
;       current target.  If so, then show the crop box visual.  Otherwise,
;       do not.
;
pro IDLitManipCropBox::UpdateToMatchOperation
    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oCropOp)) then $
        return

    ; Determine whether the crop box is currently being displayed.
    ; If so, its parent will be valid.
    self._oCropVis->GetProperty, PARENT=oParent

    ; If the new target is different from the old parent, then
    ; remove the crop box from the old parent.
    if (OBJ_VALID(oParent)) then begin
        if (self._oTarget ne oParent) then begin
            oParent->Remove, self._oCropVis, /NO_UPDATE
            oParent = OBJ_NEW()
        endif
    endif

    ; If the UI for the crop operation is active, then
    ; display the crop box visual (with bounds that match the
    ; operation's current state).
    self._oCropOp->GetProperty, WITHIN_UI=withinUI
    if (withinUI) then begin
        ; Update the crop box visual.
        self->_SetCropBox
    endif else begin
        ; If the current crop box has a non-zero width and
        ; height, and fits within the current target, then
        ; display the crop box visual as is.
        bShowBox = 0b
        self._oCropOp->GetCropBox, gx0, gy0, w, h, $
            TARGET=self._oTarget, UNITS=1
        if ((w ne 0) && (h ne 0)) then begin
            gx1 = gx0+w-1
            gy1 = gy0+h-1

            if (OBJ_VALID(self._oTarget)) then begin
                self._oTarget->_IDLitVisGrid2D::GetProperty, $
                    GRID_DIMENSIONS=gridDims

                if ((gx1 lt gridDims[0]) && $
                    (gx0 lt gridDims[1])) then $
                    bShowBox = 1b
            endif else $
                bShowBox = 0b
        endif
        if (bShowBox) then begin
            ; Update the crop box visual.  (This call will add to the
            ; target if appropriate.)
            self->_SetCropBox
        endif else begin
            if (OBJ_VALID(oParent)) then $
                oParent->Remove, self._oCropVis, /NO_UPDATE

            ; Inform the operation of the current crop box.
            self._oCropOp->SetCropBox, 0, 0, 0, 0, $
                TARGET=self._oTarget, UNITS=1, /ALLOW_ZERO_DIMENSIONS
        endelse
    endelse

end


;---------------------------------------------------------------------------
; IDLitManipCropBox::DoAction
;
; Purpose:
;   Override the DoAction so we can retrieve the Crop Operation.
;
; Arguments:
;   oTool
;
function IDLitManipCropBox::DoAction, oTool

    compile_opt idl2, hidden

    self._oCropOp = OBJ_NEW()

    if (OBJ_VALID(oTool)) then begin

        ; Reset the draw context menu.
        oWin = oTool->GetCurrentWindow()
        if (OBJ_VALID(oWin)) then begin
            self->DoOnNotify, oWin->GetFullIdentifier(), $
                'CONTEXTMENU', 'CropDrawContext'
        endif

        ; Retrieve the associated crop operation.
        oOp = oTool->GetByIdentifier('Operations/Operations/Crop')
        if (OBJ_VALID(oOp)) then begin
            if (OBJ_ISA(oOp, 'IDLitObjDesc')) then begin
                oDesc = oOp
                oOp = oDesc->GetObjectInstance()
            endif
            self._oCropOp = oOp

            ; Add this manipulator as an observer of the crop operation
            ; (so that when the crop operation's box changes, the
            ; manipulator visual can be updated).
            oTool->AddOnNotifyObserver, self->GetFullIdentifier(), $
                oOp->GetFullIdentifier()

            ; Set the current representative target.
            oSelVis = oTool->GetSelectedItems()
            self->_SetTarget, (self._oCropOp->_GetImageTargets(oSelVis))[0]

            self->UpdateToMatchOperation

        endif
    endif

    ; Pass control to superclass.
    return, self->_IDLitManipulator::DoAction(oTool)
end


;---------------------------------------------------------------------------
; IDLitManipCropBox::OnLoseCurrentManipulator
;
; Purpose:
;
pro IDLitManipCropBox::OnLoseCurrentManipulator
    compile_opt idl2, hidden

    if (OBJ_VALID(self._oCropVis)) then begin
        self._oCropVis->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->Remove, self._oCropVis
    endif

    oTool = self->GetTool()
    if (OBJ_VALID(oTool) && OBJ_VALID(self._oCropOp)) then begin
        ; Remove this manipulator as an observer of the crop operation.
        oTool->RemoveOnNotifyObserver, self->GetFullIdentifier(), $
            self._oCropOp->GetFullIdentifier()

        self._oCropOp->DismissUI
    endif

    ; Remove any crop box creation/translation/resize commands from
    ; the undo/redo buffer.
    if (OBJ_VALID(self._oCropCmds)) then begin
        oCmds = self._oCropCmds->Get(/ALL, COUNT=nCmds)
        if (nCmds gt 0) then $
            oTool->_RemoveCommand, oCmds
        OBJ_DESTROY, self._oCropCmds
        self._oCropCmds = OBJ_NEW()
    endif

    ; Reset the draw context menu.
    oWin = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWin)) then begin
        self->DoOnNotify, oWin->GetFullIdentifier(), $
            'CONTEXTMENU', ''
    endif

    self._oTarget = OBJ_NEW()

    ; Call superclass.
    self->_IDLitManipulator::OnLoseCurrentManipulator
end


;---------------------------------------------------------------------------
; IDLitManipCropBox::OnNotify
;
; Purpose:
;   Handle message notification from observed objects.
;
pro IDLitManipCropBox::OnNotify, strID, message, userdata
    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oCropOp)) then $
        return

    if (strID eq self._oCropOp->GetFullIdentifier()) then begin
        case message of
            'SETPROPERTY': begin
                bUpdate = 0b
                case userdata of
                    'X': bUpdate = 1b
                    'Y': bUpdate = 1b
                    'WIDTH': bUpdate = 1b
                    'HEIGHT': bUpdate = 1b
                    else: ; do nothing.
                endcase

                if (bUpdate ne 0) then begin
                    ; Update the crop box visual.
                    self->_SetCropBox
                    oTool = self->GetTool()

                    if (OBJ_VALID(oTool)) then $
                        oTool->RefreshCurrentWindow
                endif
            end

            else: begin
            end
        endcase
    endif
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_PrepareCropBoxVisual
;
; Purpose:
;   This procedure method prepares the crop box manipulator visual.
;
pro IDLitManipCropBox::_PrepareCropBoxVisual
    compile_opt idl2, hidden

    self._oCropVis = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Crop Box', /PRIVATE)

    self._oBox = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Crop Box/Translate', $
        DESCRIPTION='Double-click to crop', /PRIVATE )
    self._oBoxFill = OBJ_NEW('IDLgrPolygon', /PRIVATE, $
        ALPHA_CHANNEL=0.0)
    self._oBoxOutline = OBJ_NEW('IDLgrPolyline', /PRIVATE, $
        COLOR=[0,255,255], $
        LINESTYLE=3, $
        POLYLINE=[5,0,1,2,3,0])

    self._oBox->Add, self._oBoxFill
    self._oBox->Add, self._oBoxOutline

    self._oCropVis->Add, self._oBox

    ; Add resize handles.
    self->_PrepareResizeHandles

    ; Add grey out area.
    self->_PrepareGreyOut

end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_PrepareResizeHandles
;
; Purpose:
;   This procedure method prepares resize handles for the crop box
;   manipulator visual.
;
pro IDLitManipCropBox::_PrepareResizeHandles
    compile_opt idl2, hidden

    self._oResize = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Crop Box/Resize', /PRIVATE)

    if (~OBJ_VALID(self._oFont)) then $
        self._oFont = OBJ_NEW('IDLgrFont', 'Hershey*9', SIZE=6)
    textex = {ALIGN: 0.45, $
        VERTICAL_ALIGN: 0.45, $
        COLOR: [0,255,255], $
        FONT: self._oFont, $
        RECOMPUTE_DIM: 2, $
        RENDER: 1}

    data = [ $
        [-1,-1], $
        [1,-1], $
        [1,1], $
        [-1,1]]

    ; Corners.
    types = ['-X-Y','+X-Y','+X+Y','-X+Y']

    for i=0,3 do begin
        xyposition = [data[0:1,i], 0]
        oText = OBJ_NEW('IDLgrText', 'B', $
            LOCATION=xyposition, $
            _EXTRA=textex)
        oCorner = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Crop Box/Resize/'+types[i])
        oCorner->Add, oText
        self._oResize->Add, oCorner
    endfor

    char2 = 'B'

    ; Edges.
    types = ['-X','+X','-Y','+Y']

    for i=0,3 do begin

        oEdge = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='Crop Box/Resize/'+types[i])

        case i of
            0: data = [[-1,-1],[-1,1]] ; left
            1: data = [[ 1,-1],[1, 1]] ; right
            2: data = [[-1,-1],[1,-1]] ; bottom
            3: data = [[-1, 1],[1, 1]] ; top
        endcase

        ; For non-padded selection boxes (like for rectangles)
        ; we put little boxes in the middle of each side.
        oEdge->Add, OBJ_NEW('IDLgrText', char2, $
            LOCATION=TOTAL(data,2)/2, _EXTRA=textex)

        self._oResize->Add, oEdge

    endfor

    self._oCropVis->Add, self._oResize
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_PrepareGreyOut
;
; Purpose:
;   This procedure method prepares a grey out area for the crop box
;   manipulator visual.
;
pro IDLitManipCropBox::_PrepareGreyOut
    compile_opt idl2, hidden

    oGrey = OBJ_NEW('_IDLitVisualization', $
        /PRIVATE)

    self._oGreyLeft = OBJ_NEW('IDLgrPolygon', $
        COLOR=[0,0,0], ALPHA_CHANNEL=0.5, /PRIVATE)
    oGrey->Add, self._oGreyLeft

    self._oGreyRight = OBJ_NEW('IDLgrPolygon', $
        COLOR=[0,0,0], ALPHA_CHANNEL=0.5, /PRIVATE)
    oGrey->Add, self._oGreyRight

    self._oGreyTop = OBJ_NEW('IDLgrPolygon', $
        COLOR=[0,0,0], ALPHA_CHANNEL=0.5, /PRIVATE)
    oGrey->Add, self._oGreyTop

    self._oGreyBtm = OBJ_NEW('IDLgrPolygon', $
        COLOR=[0,0,0], ALPHA_CHANNEL=0.5, /PRIVATE)
    oGrey->Add, self._oGreyBtm

    self._oCropVis->Add, oGrey
end


;---------------------------------------------------------------------------
; IDLitManipCropBox::_UpdateGreyOut
;
; Purpose:
;   This procedure method updates the grey out area of the crop box
;   manipulator visual to match the current crop rectangle.
;
pro IDLitManipCropBox::_UpdateGreyOut
    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oTarget)) then $
        return

    self._oTarget->_IDLitVisGrid2D::GetProperty, GRID_DIMENSIONS=gridDims, $
        GRID_STEP=gridStep, GRID_ORIGIN=gridOrigin

    tx0 = gridOrigin[0]
    ty0 = gridOrigin[1]
    tx1 = tx0 + (gridDims[0] * gridStep[0])
    ty1 = ty0 + (gridDims[1] * gridStep[1])

    ; Retrieve the current crop box coordinates.
    self._oCropOp->GetCropBox, cx0, cy0, cW, cH, $
        TARGET=self._oTarget, UNITS=0

    cx1 = cx0 + cW
    cy1 = cy0 + cH

    if ((cx0 eq cx1) || (cy0 eq cy1)) then begin
        self._oGreyLeft->SetProperty, HIDE=0, DATA=[ $
            [tx0,ty0], $
            [tx1,ty0], $
            [tx1,ty1], $
            [tx0,ty1] ]

        self._oGreyRight->SetProperty, /HIDE
        self._oGreyBtm->SetProperty, /HIDE
        self._oGreyTop->SetProperty, /HIDE
    endif else begin
        self._oGreyLeft->SetProperty, HIDE=0, DATA=[ $
            [tx0,ty0], $
            [cx0,ty0], $
            [cx0,ty1], $
            [tx0,ty1] ]

        self._oGreyRight->SetProperty, HIDE=0, DATA=[ $
            [cx1,ty0], $
            [tx1,ty0], $
            [tx1,ty1], $
            [cx1,ty1]]

        self._oGreyBtm->SetProperty, HIDE=0, DATA=[ $
            [cx0,ty0], $
            [cx1,ty0], $
            [cx1,cy0], $
            [cx0,cy0]]

        self._oGreyTop->SetProperty, HIDE=0, DATA=[ $
            [cx0,cy1], $
            [cx1,cy1], $
            [cx1,ty1], $
            [cx0,ty1]]
    endelse
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_SetCropBox
;
; Purpose:
;   Update the crop box manipulator visual to match the current crop
;   rectangle (as stored in the crop operation).
;
; Keywords:
;   ALLOW_SMALL: Set this keyword to a non-zero value to indicate that
;     if the crop box visual gets too small, it should continue to be
;     displayed.  By default (or if this keyword is not set), the crop
;     box visual will no longer be displayed if the crop rectangle gets
;     too small.
;
pro IDLitManipCropBox::_SetCropBox, $
    ALLOW_SMALL=allowSmall

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oCropOp)) then $
        return

    if (~OBJ_VALID(self._oCropVis)) then $
        return

    ; Retrieve the current crop box rectangle.
    self._oCropOp->GetCropBox, gx0, gy0, w, h, $
        TARGET=self._oTarget, UNITS=1
    self._oCropOp->GetCropBox, geomX0, geomY0, geomW, geomH, $
        TARGET=self._oTarget, UNITS=0

    self._oCropVis->GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent)) then begin
        ; If the crop box was previously being displayed,
        ; and now the width or height are too small,
        ; and the ALLOW_SMALL keyword is not set, then quit displaying
        ; the crop box.
        if ((~KEYWORD_SET(allowSmall)) && $
            ((w lt 2) || (h lt 2))) then begin
            oParent->Remove, self._oCropVis, /NO_UPDATE
            oParent = OBJ_NEW()
        endif
    endif else begin
        ; If the crop box was not previously being displayed,
        ; and width and height are now large enough, then display the
        ; box.
        if ((w ge 2) && (h ge 2) && $
            OBJ_VALID(self._oTarget)) then begin
            self._oTarget->Add, self._oCropVis, /NO_UPDATE
            oParent = self._oTarget
        endif
    endelse

    ; If the crop box visual still has no parent, then it is not
    ; being displayed, so no action needs to be taken.
    if (~OBJ_VALID(oParent)) then $
        return

    geomX1 = geomX0 + geomW
    geomY1 = geomY0 + geomH
    data = [[geomX0, geomY0], [geomX1, geomY0], $
            [geomX1, geomY1], [geomX0, geomY1]]
    self._oBoxFill->SetProperty, DATA=data
    self._oBoxOutline->SetProperty, DATA=[[data], [data[*,0]]]

    self._oResize->IDLitManipulatorVisual::_TransformToVisualization, $
        self._oBox

    self->_UpdateGreyOut

end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_TranslateCropBox
;
; Purpose:
;   This procedure method translates the crop box manipulator visual.
;
pro IDLitManipCropBox::_TranslateCropBox, deltaXY
    compile_opt idl2, hidden

    ; Retrieve the original crop box coordinates.
    startx = self._initCropXY0[0]
    starty = self._initCropXY0[1]
    endx = self._initCropXY1[0]
    endy = self._initCropXY1[1]

    ; Apply the delta.
    startx += deltaXY[0]
    starty += deltaXY[1]
    endx += deltaXY[0]
    endy += deltaXY[1]

    ; Relocate from outside corners of pixels to center of pixels.
    startx += self._halfPixel[0]
    starty += self._halfPixel[1]
    endx -= self._halfPixel[0]
    endy -= self._halfPixel[1]

    ; Contrain to target.
    if (startx lt self._targetXRange[0]) then begin
        cx = self._targetXRange[0] - startx
        startx += cx
        endx += cx
    endif
    if (starty lt self._targetYRange[0]) then begin
        cy = self._targetYRange[0] - starty
        starty += cy
        endy += cy
    endif
    if (endx gt self._targetXRange[1]) then begin
        cx = endx - self._targetXRange[1]
        startx -= cx
        endx -= cx
    endif
    if (endy gt self._targetYRange[1]) then begin
        cy = endy - self._targetYRange[1]
        starty -= cy
        endy -= cy
    endif

    ; Map back to grid coordinates.
    self._oTarget->GeometryToGrid, startx, starty, gx0, gy0
    self._oTarget->GeometryToGrid, endx, endy, gx1, gy1

    ; Inform the operation of the current crop box.
    self._oCropOp->SetCropBox, gx0, gy0, gx1-gx0+1, gy1-gy0+1, $
        TARGET=self._oTarget, UNITS=1

    ; Report the new crop box coordinates.
    self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
        TARGET=self._oTarget, UNITS=0
    probeMsg = STRING(FORMAT='(%"[%g,%g] %gx%g")', $
        cx0, cy0, cw, ch)
    self->ProbeStatusMessage, probeMsg

    ; Update the crop box visual.
    self->_SetCropBox

end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_ResizeCropBox
;
; Purpose:
;   This procedure method resizes the crop box manipulator visual.
;
pro IDLitManipCropBox::_ResizeCropBox, deltaXY
    compile_opt idl2, hidden

    ; Retrieve the original crop box coordinates.
    startx = self._initCropXY0[0]
    starty = self._initCropXY0[1]
    endx = self._initCropXY1[0]
    endy = self._initCropXY1[1]

    ; Apply the delta.
    case self._subtype of
        'Crop Box/Resize/-X': begin
            startx += deltaXY[0]
        end

        'Crop Box/Resize/+X': begin
            endx += deltaXY[0]
        end

        'Crop Box/Resize/-Y': begin
            starty += deltaXY[1]
        end

        'Crop Box/Resize/+Y': begin
            endy += deltaXY[1]
        end

        'Crop Box/Resize/-X-Y': begin
            startx += deltaXY[0]
            starty += deltaXY[1]
        end

        'Crop Box/Resize/-X+Y': begin
            startx += deltaXY[0]
            endy += deltaXY[1]
        end

        'Crop Box/Resize/+X-Y': begin
            endx += deltaXY[0]
            starty += deltaXY[1]
        end

        'Crop Box/Resize/+X+Y': begin
            endx += deltaXY[0]
            endy += deltaXY[1]
        end
    endcase

    ; Relocate from outside corners of pixels to center of pixels.
    startx += self._halfPixel[0]
    starty += self._halfPixel[1]
    endx -= self._halfPixel[0]
    endy -= self._halfPixel[1]

    ; Contrain to target.
    if (startx lt self._targetXRange[0]) then $
        startx = self._targetXRange[0]

    if (endx lt self._targetXRange[0]) then $
        endx = self._targetXRange[0]

    if (startx gt self._targetXRange[1]) then $
        startx = self._targetXRange[1]

    if (endx gt self._targetXRange[1]) then $
        endx = self._targetXRange[1]

    if (starty lt self._targetYRange[0]) then $
        starty = self._targetYRange[0]

    if (endy lt self._targetYRange[0]) then $
        endy = self._targetYRange[0]

    if (starty gt self._targetYRange[1]) then $
        starty = self._targetYRange[1]

    if (endy gt self._targetYRange[1]) then $
        endy = self._targetYRange[1]

    ; Map back to grid coordinates.
    self._oTarget->GeometryToGrid, startx, starty, gridX0, gridY0
    self._oTarget->GeometryToGrid, endx, endy, gridX1, gridY1

    ; Inform the crop operation of the current crop box.
    gx0 = MIN([gridX0,gridX1], MAX=gx1)
    gy0 = MIN([gridY0,gridY1], MAX=gy1)
    self._oCropOp->SetCropBox, gx0, gy0, gx1-gx0+1, gy1-gy0+1, $
        TARGET=self._oTarget, UNITS=1, /ALLOW_ZERO_DIMENSIONS

    ; Report the new crop box coordinates.
    self._oCropOp->GetCropBox, cx0, cy0, cw, ch, $
        TARGET=self._oTarget, UNITS=0
    probeMsg = STRING(FORMAT='(%"[%g,%g] %gx%g")', $
        cx0, cy0, cw, ch)
    self->ProbeStatusMessage, probeMsg

    ; Update the crop box visual.
    self->_SetCropBox, /ALLOW_SMALL
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::_DoCrop
;
; Purpose:
;   This procedure method crops the current target(s).
;
pro IDLitManipCropBox::_DoCrop

    compile_opt idl2, hidden

    ; Remove the crop visualization, since it will no longer apply
    ; for the cropped image.
    if (OBJ_VALID(self._oCropVis)) then begin
        self._oCropVis->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->Remove, self._oCropVis, /NO_UPDATE
    endif

    oTool = self->GetTool()
    if (OBJ_VALID(oTool) && OBJ_VALID(self._oCropOp)) then begin
        ; Disable UI for the operation.
        self._oCropOp->GetProperty, SHOW_EXECUTION_UI=origShowUI
        self._oCropOp->SetProperty, SHOW_EXECUTION_UI=0

        opID = self._oCropOp->GetFullIdentifier()
        success = oTool->DoAction(opID)
;        success = OBJ_VALID(oCmdSet[0])

        if success then begin
            oSrvMacro = oTool->GetService('MACROS')
            if obj_valid(oSrvMacro) then begin
                oSrvMacro->GetProperty, CURRENT_NAME=currentName
                oSrvMacro->PasteMacroOperation, self._oCropOp, currentName
            endif
        endif

        ; Restore UI to original setting.
        self._oCropOp->SetProperty, SHOW_EXECUTION_UI=origShowUI

        ; Dismiss the UI if displayed.
        if (success) then $
            self._oCropOp->DismissUI
    endif

end

;--------------------------------------------------------------------------
; IDLitManipCropBox::_DoRegisterCursor
;
; Purpose:
;   This procedure method registers the cursors used with this manipulator.
;
pro IDLitManipCropBox::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '      ...       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#. .#.     ', $
        '....#.   .#.... ', $
        '.####. $ .####. ', $
        '....#.   .#.... ', $
        '    .#. .#.     ', $
        '     .###.      ', $
        '      .#.       ', $
        '      .#.       ', $
        '      .#.       ', $
        '      ...       ', $
        '                ']

    self->RegisterCursor, strArray, 'Crop Box', /DEFAULT

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '     .###.      ', $
        '    .#####.     ', $
        '   ....#....    ', $
        '  .#. .#. .#.   ', $
        ' .##...#...##.  ', $
        '.######$######. ', $
        ' .##...#...##.  ', $
        '  .#. .#. .#.   ', $
        '   ....#....    ', $
        '    .#####.     ', $
        '     .###.      ', $
        '      .#.       ', $
        '       .        ', $
        '                ']

    self->RegisterCursor, strArray, 'Crop Box/Translate'

    strArray = [ $
        '                ', $
        '  .....   ..... ', $
        '  .###.   .###. ', $
        '  .##.     .##. ', $
        '  .#.#.   .#.#. ', $
        '  .. .#. .#. .. ', $
        '      .#.#.     ', $
        '       .$.      ', $
        '      .#.#.     ', $
        '  .. .#. .#. .. ', $
        '  .#.#.   .#.#. ', $
        '  .##.     .##. ', $
        '  .###.   .###. ', $
        '  .....   ..... ', $
        '                ', $
        '                ']

    self->RegisterCursor, strArray, 'Crop Box/Resize/+X-Y'
    self->RegisterCursor, strArray, 'Crop Box/Resize/+X+Y'
    self->RegisterCursor, strArray, 'Crop Box/Resize/-X-Y'
    self->RegisterCursor, strArray, 'Crop Box/Resize/-X+Y'

end

;---------------------------------------------------------------------------
; IDLitManipCropBox::GetCursorType
;
; Purpose:
;   This function method returns the type of the cursor associated with
;   the given manipulator visual type.
;
function IDLitManipCropBox::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    ; If a particular type is passed in, then it is probably
    ; associated with a manipulator other than this one.  In this case,
    ; revert to the arrow cursor.  Otherwise, just use the default cursor.
    if (STRLEN(typeIn) eq 0) then $
        return, self._defaultCursor

    case typeIn of
        'Crop Box/Translate': return,  typeIn
        'Crop Box/Resize/+X': return, 'SIZE_EW'
        'Crop Box/Resize/-X': return, 'SIZE_EW'
        'Crop Box/Resize/+Y': return, 'SIZE_NS'
        'Crop Box/Resize/-Y': return, 'SIZE_NS'
        'Crop Box/Resize/+X+Y': return, typeIn
        'Crop Box/Resize/+X-Y': return, typeIn
        'Crop Box/Resize/-X+Y': return, typeIn
        'Crop Box/Resize/-X-Y': return, typeIn
        else: return, ''
    endcase
end

;---------------------------------------------------------------------------
; IDLitManipCropBox::GetStatusMessage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given type.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   typeIn <Optional> - String representing the current type.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
function IDLitManipCropBox::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    case typeIn of
        'Crop Box/Translate': $
            return, IDLitLangCatQuery('Status:CropBox:CnDTranslate')
        'Crop Box/Resize/+X': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/-X': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/+Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/-Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/+X+Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/+X-Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/-X+Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        'Crop Box/Resize/-X-Y': return, IDLitLangCatQuery('Status:CropBox:CnDResize')
        else: return, IDLitLangCatQuery('Status:CropBox:CnDDefine')
    endcase
end


;-------------------------------------------------------------------------
; IDLitManipCropBox::QueryAvailability
;
; Purpose:
;   This function method determines whether this manipulator is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if this manipulator is applicable for the
;   selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None.
;
function IDLitManipCropBox::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Use our superclass as a first filter.
    ; If not available by matching types, then no need to continue.
    success = self->IDLitManipulator::QueryAvailability(oTool, selTypes)
    if (~success) then $
        return, 0

    ; Note: Use IDLitopCropImage::QueryAvailability so we don't
    ; have duplicate code.
    oOp = oTool->GetByIdentifier('Operations/Operations/Crop')
    return, OBJ_VALID(oOp) ? oOp->QueryAvailability(oTool, selTypes) : 0

end


;---------------------------------------------------------------------------
; IDLitManipCropBox::Define
;
; Purpose:
;   Define the object structure for the manipulator
;
pro IDLitManipCropBox__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipCropBox,            $
            inherits IDLitManipulator,    $ ; Superclass
            _gridXY0: ULONARR(2),         $ ; Initial grid loc of crop rect
            _gridXY1: ULONARR(2),         $ ; Final grid loc of crop rect
            _startXY: DBLARR(2),          $ ; Initial mouse down position
            _initCropXY0: DBLARR(2),      $ ; Initial crop box coordinates
            _initCropXY1: DBLARR(2),      $ ;   (in data units).
            _oCropVis: OBJ_NEW(),         $ ; Overall manipulator visual
            _oBox: OBJ_NEW(),             $ ; Box manipulator visual
            _oBoxFill: OBJ_NEW(),         $ ;   Box fill
            _oBoxOutline: OBJ_NEW(),      $ ;   Box outline
            _oFont: OBJ_NEW(),            $ ; Font used for resize handles
            _oResize: OBJ_NEW(),          $ ; Resize manipulator visual
            _oGreyLeft: OBJ_NEW(),        $ ; Grey out visual sections.
            _oGreyRight: OBJ_NEW(),       $ ;
            _oGreyBtm: OBJ_NEW(),         $ ;
            _oGreyTop: OBJ_NEW(),         $ ;
            _oCropOp: OBJ_NEW(),          $ ; Reference to crop operation
            _oTarget: OBJ_NEW(),          $ ; Reference to target
            _targetXRange: DBLARR(2),     $ ; X range of target
            _targetYRange: DBLARR(2),     $ ; Y range of target
            _halfPixel: DBLARR(2),        $ ; Size of a half pixel (in data
                                          $ ;   units for target)
            _oCropCmds: OBJ_NEW()         $ ; Container for commands generated
                                          $ ;   while this manip is active
    }
end
