; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipview__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Manipulator for Views. Does translation and scaling.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the manipulator object.
;
function IDLitManipView::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass.
    ; The operation and parameter are used for undo/redo.
    iStatus = self->IDLitManipulator::Init(IDENTIFIER="View", $
        OPERATION_IDENTIFIER='SET_PROPERTY', $
        VISUAL_TYPE= 'Select', $
        NAME="View Translate/Scale", _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitManipView::SetProperty, _EXTRA=_extra

    return, 1
end


;--------------------------------------------------------------------------
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipView::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipView::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Arguments:
;   oWin    - Source of the event
;   x   - X coordinate
;   y   - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
pro IDLitManipView::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Do a selection operation.
    if (not KEYWORD_SET(noSelect)) then $
        self->_IDLitManipulator::_Select, $
        oWin, x, y , iButton, KeyMods, nClick

    ; See if we actually hit a view. This should have been set in _Select.
    if (self.nSelectionList eq 0) then $
        return

    ; Set button down flag.
    self.ButtonPress = iButton

    self.startXY = [x,y]
    self.previousXY = [x,y]

    ; See if we are modifying the viewplane or the position.
    self.isGridded = 0

    oLayout = oWin->GetLayout()
    oLayout->GetProperty, GRIDDED=gridded, $
        MAXCOUNT=nlayout

    ; For gridded layout, we don't allow translation, but we do allow
    ; the views to be rearranged.
    if (gridded) then begin
        oView = *self.pSelectionList
        oView->GetProperty, PARENT=oParent
        dummy = oParent->IsContained(oView, POSITION=position)
        ; Only set the gridded flag if we are gridded, and the # of views
        ; is less than or equal to the number within the grid.
        ; We allow "extra" views to be translated & scaled freely.
        self.isGridded = (position lt nlayout)
    endif

    ; Change our name so the Undo/Redo command has the correct name.
    isTranslate = (self._subtype eq 'Translate')
    name = 'View ' + (self.isGridded ? 'Position' : $
        (isTranslate ? 'Translate' : 'Scale'))
    ; Depending upon which mode, we need to cache a different property
    ; for undo/redo.
    self->SetProperty, NAME=name, $
        PARAMETER_IDENTIFIER= $
        self.isGridded ? 'LAYOUT_POSITION' : 'VIEWPORT_RECT'



    ; Record the current values for the target objects
    iStatus = self->RecordUndoValues()

end


;--------------------------------------------------------------------------
; Purpose:
;   Undocumented method to compute a new viewport_rect for translation.
;
; Arguments:
;   viewportRect: The current viewport_rect.
;   x,y: The new mouse position
;   KeyMods: The keyboard modifiers.
;
function IDLitManipView::_Translate, viewportRect, x, y, KeyMods

    compile_opt idl2, hidden

    location = viewportRect[0:1]
    newloc = location

    ; Amount of mouse motion.
    dx = (x - self.previousXY[0])
    dy = (y - self.previousXY[1])

    ; Check for <Shift> key.
    if ((KeyMods and 1) ne 0) then begin

        ; See if we need to initialize the constraint.
        ; The biggest delta (x or y) wins, until <Shift> is released.
        if (self.xyConstrain eq 0) then $
            self.xyConstrain = (ABS(dx) gt ABS(dy)) ? 1 : 2

        ; Apply the constraint.
        if (self.xyConstrain eq 1) then dy = 0 else dx = 0

    endif else $
        self.xyConstrain = 0   ; turn off constraint

    newloc = newloc + [dx, dy]

    ; New viewport rect. Dimensions didn't change.
    return, [newloc, viewportRect[2:3]]

end


;--------------------------------------------------------------------------
; Purpose:
;   Undocumented method to compute a new viewport_rect for scaling.
;
; Arguments:
;   viewportRect: The current viewport_rect.
;   x,y: The new mouse position
;   KeyMods: The keyboard modifiers.
;
function IDLitManipView::_Scale, viewportRect, x, y, KeyMods

    compile_opt idl2, hidden

    location = viewportRect[0:1]
    newloc = location
    dimensions = viewportRect[2:3]
    newdim = dimensions

    ; Amount of mouse motion.
    dx = (x - self.previousXY[0])
    dy = (y - self.previousXY[1])

    ; Check for <Shift> key.
    ShiftKey = (KeyMods and 1) ne 0
    CtrlKey = (KeyMods and 2) ne 0

    ; The following code assumes types such as BOTTOM, BOTTOMLEFT, etc.
    min_d = 2   ; minimum size


    case STRUPCASE(self._subtype) of
        'TOPRIGHT': corner = [1,1]
        'TOPLEFT':  corner = [0,1]
        'BOTTOMRIGHT': corner = [1,0]
        'BOTTOMLEFT':  corner = [0,0]
        else: return, viewportRect
    endcase

    dxy = [dx, dy]

    ; If <Ctrl> (scale about center) is held, then double the scaling
    ; since we need to give half to each side.
    if CtrlKey then dxy *= 2

    ; Constrained scaling if one of the corners is hit.
    if (ShiftKey and (MIN(corner) ge 0)) then begin

        ; What would the dimensions be if <Shift> wasn't pressed?
        newdim[0] += (corner[0] ? dxy[0] : -dxy[0])
        newdim[1] += (corner[1] ? dxy[1] : -dxy[1])

        ; Average scale factor for constrained scaling.
        scale = SQRT(TOTAL(newdim^2)/TOTAL(dimensions^2))

        ; Apply the scale factor equally to each dimension.
        dxy = dimensions*(1 - scale)
        if (corner[0] eq 1) then dxy[0] = -dxy[0]
        if (corner[1] eq 1) then dxy[1] = -dxy[1]

        ; Reset for further computations.
        newdim = dimensions

    endif

    ; Loop over X and Y dimensions.
    for i=0,1 do begin

        ; Skip if not scaling this dimension.
        if (corner[i] eq -1) then $
            continue

        ; New dimensions size, either smaller or larger.
        newdim[i] += (corner[i] ? dxy[i] : -dxy[i])

        ; Enforce minimum size.
        newdim[i] >= min_d

        ; Recompute the delta, in case we hit the minimum.
        delta = (dimensions[i] - newdim[i])

        ; Split the difference if <Ctrl>.
        if CtrlKey then delta /= 2.0

        ; Shift the view if scaling about center or bottom/left.
        if (CtrlKey or (corner[i] eq 0)) then $
            newloc[i] += delta
    endfor


    ; New viewport rect.
    return, [newloc, newdim]

end


;--------------------------------------------------------------------------
; Purpose:
;   Implements the OnMouseMotion method.
;
; Arguments:
;   oWin    - Event Window Component
;   x   - X coordinate
;   y   - Y coordinate
;   KeyMods - Keyboard modifiers for button
;
pro IDLitManipView::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    ; Get the destination's dimensions in device units.
    dummy = oWin->GetDimensions(VIRTUAL_DIMENSIONS=winDims)

    ; Restrict our X and Y range to be within the window.
    x = 0 > x < (winDims[0]-1)
    y = 0 > y < (winDims[1]-1)

    oView = *self.pSelectionList
    if (~OBJ_VALID(oView)) then $
        return

    ; Retrieve the previous viewport dimensions.
    viewportDim = oView->GetViewport(LOCATION=viewportLoc, /VIRTUAL)
    viewportRect = [viewportLoc, viewportDim]

    ; Calculate the new viewport location and dimensions.
    if (self._subtype eq 'Translate') then begin

        ; For gridded layout, we don't allow translation, but we do allow
        ; the views to be rearranged.
        if (self.isGridded) then begin

            oVisList = oWin->DoHitTest(x, y, VIEWGROUP=oHitView)

            ; See if we've moved our mouse far enough to hit another view.
            if (OBJ_VALID(oHitView) && (oHitView ne oView)) then begin
                    dummy = oWin->IsContained(oHitView, POS=newPos)
                    dummy = oWin->IsContained(oView, POS=oldPos)

                    if (self._oHitView ne oHitView) then begin
                        ; Highlight the new view location.
                        oHitView->_InsertHighlight, RIGHT=(newPos gt oldPos)
                        if (OBJ_VALID(self._oHitView)) then $
                            self._oHitView->_InsertHighlight, /OFF
                        self._oHitView = oHitView
                        ; Update the graphics hierarchy.
                        oTool = self->GetTool()
                        if (OBJ_VALID(oTool)) then $
                            oTool->RefreshCurrentWindow
                    endif

            endif else begin

                ; Didn't hit a different view. Be sure to turn off
                ; our old highlighting.
                if (OBJ_VALID(self._oHitView)) then begin
                    self._oHitView->_InsertHighlight, /OFF
                    self._oHitView = OBJ_NEW()
                    ; Update the graphics hierarchy.
                    oTool = self->GetTool()
                    if (OBJ_VALID(oTool)) then $
                        oTool->RefreshCurrentWindow
                endif

            endelse

            return

        endif  ; gridded

        newViewportRect = self->_Translate(viewportRect, x, y, KeyMods)

    endif else begin

        ; Cannot scale a gridded view.
        if (self.isGridded) then $
            return

        newViewportRect = self->_Scale(viewportRect, x, y, KeyMods)

    endelse


    self.previousXY = [x, y]

    ; Restrict our new viewport to be within the window.
    newViewportRect[0:1] = $
        0 > newViewportRect[0:1] < (winDims-newViewportRect[2:3])


    ; No changes.
    if (ARRAY_EQUAL(newViewportRect, viewportRect)) then $
        return

    ; Set new viewport and update the graphics hierarchy.
    oView->SetProperty, VIEWPORT_RECT=newViewportRect

    ; Update the graphics hierarchy.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

    ; Call our superclass (needed to update cursor).
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; IDLitManipView::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Arguments:
;   oWin    - Source of the event
;   x   - X coordinate
;   y   - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipView::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    self.ButtonPress = 0  ; button is up

    ; If there was no change in coordinates between MouseDown and
    ; MouseUp, then do not commit the values.
    noChange = ARRAY_EQUAL([x,y], self.startXY)

    ; See if we are actually moving a view.
    oView = *self.pSelectionList
    if (OBJ_VALID(oView) && OBJ_VALID(self._oHitView)) then begin
        ; Turn off our selection visual and retrieve container positions.
        self._oHitView->_InsertHighlight, /OFF
        oView->GetProperty, LAYOUT_POSITION=oldPos
        self._oHitView->GetProperty, LAYOUT_POSITION=newPos
        noChange = oldPos eq newPos
        if (~noChange) then $
            oView->SetProperty, LAYOUT_POSITION=newPos
        ; Update the graphics hierarchy.
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif

    self._oHitView = OBJ_NEW()


    ; Commit this transaction
    if (self.nSelectionList gt 0) then $
        iStatus = self->CommitUndoValues(UNCOMMIT=noChange)

end


;--------------------------------------------------------------------------
; IDLitManipView::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method.
;
; Arguments:
;   oWin        - Event Window Component
;   IsAlpha     - The the value a character or ASCII value?
;   Character   - The ASCII character of the key pressed.
;   KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
;
pro IDLitManipView::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ; pragmas
   compile_opt idl2, hidden
   ; Abstract method.

    ; Ignore keyboard events if the button is down.
    if (self.ButtonPress ne 0) then $
        return

    ; Sanity check. Only allow translation.
    self._subtype = 'Translate'

    if (not IsASCII) then begin
        if ((KeyValue ge 5) and (KeyValue le 8) and Press) then begin

            case KeyMods of
                1: offset = 40
                2: offset = 1
                else: offset = 5
            endcase

            ; Call our method.
            self->OnMouseDown, oWin, x, y, 1, 0, 1, $
                /NO_SELECT

            ; Do the translation.
            case KeyValue of
                5: x = x - offset
                6: x = x + offset
                7: y = y + offset
                8: y = y - offset
            endcase

            ; Perform the motion, then reset everything.
            self->OnMouseMotion, oWin, x, y, 0
            self->OnMouseUp, oWin, x, y, 1

        endif
    endif

end


;--------------------------------------------------------------------------
; IDLitManipView::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitManipView::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    switch strupcase(typeIn) of

        ; The <Shift> key does constrained scaling.
        'TOPLEFT':
        'BOTTOMRIGHT': return, ((KeyMods and 1) ne 0) ? 'SIZE_SE' : 'Scale2D'

        ; The <Shift> key does constrained scaling.
        'TOPRIGHT':
        'BOTTOMLEFT': return, ((KeyMods and 1) ne 0) ? 'SIZE_NE' : 'Scale2D'

        ; The edges just do translation.
        'TRANSLATE': return, 'Translate'

        else: return, ''

    endswitch

end


;---------------------------------------------------------------------------
; IDLitManipView::Define
;
; Purpose:
;   Define the base object for the manipulator
;
pro IDLitManipView__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitManipView, $
           inherits IDLitManipulator,       $ ; I AM A COMPONENT
           xyConstrain: 0b, $      ; am I constrained in the X or Y dir?
           startXY: [0L, 0L], $    ; initial X/Y mouse position
           previousXY: [0L, 0L], $ ; previous X/Y mouse position
           isGridded: 0b, $        ; selected view is part of a grid
           _oHitView: OBJ_NEW() $
      }
end
