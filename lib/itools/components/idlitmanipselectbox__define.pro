; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipselectbox__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create a selection box.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipSelectBox::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipSelectBox::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipAnnotation::Init( $
        NAME='Select Box Manipulator', $
        DESCRIPTION='Click on item to select, or click & drag selection box', $
        IDENTIFIER='SelectBox', $
        ICON="rectangl", $
        KEYBOARD_EVENTS=0, $
        /TRANSIENT_DEFAULT, _EXTRA=_extra)

    return, status
end


;--------------------------------------------------------------------------
; IDLitManipSelectBox::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro IDLitManipSelectBox::Cleanup

    compile_opt idl2, hidden

    ; Our rectangle gets removed from the Viz Hierarchy each time
    ; selection ends. So destroy it ourself.
    OBJ_DESTROY, self._oRectangle

    self->IDLitManipAnnotation::Cleanup

end


;--------------------------------------------------------------------------
; IIDLRotateManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitManipSelectBox::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks
;
pro IDLitManipSelectBox::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    ; For middle or right button clicks, cancel the annotation.
    if (iButton ne 1) then begin
        if OBJ_VALID(self._oRectangle) then begin
            self._oRectangle->GetProperty, PARENT=oParent
            if (OBJ_VALID(oParent)) then $
                oParent->IDLgrModel::Remove, self._oRectangle
            self->CancelAnnotation
            self.ButtonPress = 0
        endif
        return
    endif

    ; Create our new annotation.
    if (OBJ_VALID(self._oRectangle)) then begin
        ; If our select box was previously part of a model,
        ; remove it. This can happen when you switch views.
        self._oRectangle->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->IDLgrModel::Remove, self._oRectangle
    endif else begin
        self._oRectangle = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='SelectBox', /PRIVATE)
        oSubManipVis = OBJ_NEW('IDLitManipulatorVisual', $
            VISUAL_TYPE='SelectBox', /PRIVATE)
        self._oPolyline = OBJ_NEW('IDLgrPolyline', $
            LINESTYLE=[1, 'F0F0'x])
        oSubManipVis->Add, self._oPolyline
        self._oRectangle->Add, oSubManipVis
    endelse

    self._startPT = [x, y]

    oWin->SetCurrentCursor, 'CROSSHAIR'

    self->StatusMessage, IDLitLangCatQuery('Status:Manip:SelectBox')
end


;--------------------------------------------------------------------------
; IDLitManipSelectBox::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipSelectBox::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    ; Sanity check.
    if (~self.ButtonPress || ~OBJ_VALID(self._oRectangle)) then begin
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
        return
    endif

    x0 = self._startPt[0]
    y0 = self._startPt[1]
    ; Don't allow rectangles of zero width/height.
    if (x eq x0) || (y eq y0) then $
        return
    x1 = x
    y1 = y

    ;; Add the Z so that values are in the annotation layer and
    ;; not clipped by the Viz.
    z = self._normalizedZ

    ; Do the corner about which the shape is being scaled.
    ; We need to do this before the point reordering, otherwise
    ; we don't know which corner we were scaling about.
    self->ProbeStatusMessage, $
        STRING(x, y, ABS(x1-x0), ABS(y1-y0), $
        FORMAT='(%"[%d,%d]   %d x %d")')

    ; Reorder the points if necessary.
    if (x0 gt x1) then begin
        tmp = x0
        x0 = x1
        x1 = tmp
    endif
    if (y0 gt y1) then begin
        tmp = y0
        y0 = y1
        y1 = tmp
    endif


    ; If we havn't been added yet, then add ourself.
    self._oRectangle->GetProperty, PARENT=oParent
    if (~OBJ_VALID(oParent)) then $
        oWin->Add, self._oRectangle, layer='ANNOTATION'

    xydata = [[x0,y0,z], [x1,y0,z], [x1,y1,z], [x0,y1,z]]
    self._oRectangle->_IDLitVisualization::WindowToVis, xydata, xyout

    ; Update the rectangle.
    self._oPolyline->SetProperty, DATA=[[xyout], [xyout[*,0]]]

    ; Update the graphics hierarchy.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow


end


;--------------------------------------------------------------------------
; Purpose:
;   Check for items within the selection box, and select them.
;
pro IDLitManipSelectBox::_SelectBox, oWin, xy1, xy2

    compile_opt idl2, hidden

    ; Overall selection box.
    boxCenter = (xy1 + xy2)/2
    boxDims = ABS(xy2 - xy1)

    ; First check if there are any visualizations within
    ; or straddling the box.
    oVisList = oWin->DoHitTest(boxCenter[0], boxCenter[1], $
        DIMENSIONS=boxDims, $
        VIEWGROUP=oHitViewGroup)

    ; Bail if nothing was within the box.
    if (~OBJ_VALID(oVisList[0])) then $
        return

    ; We only want to include visualizations that are fully contained
    ; within the box. So now do 4 new hit tests, just on the boundary,
    ; throwing away hit items. Whatever is left in the vis list
    ; was fully within the box.
    for i=0,3 do begin
        case i of
            ; Note: the "left/right & bottom/top" could actually be
            ; backwards, depending upon the position of the xy1 & xy2
            ; points. It doesn't matter which is which.
            ;         [X center, Y center, X size, Y size]
            0: box = [xy1[0], boxCenter[1], 1, boxDims[1]] ; left
            1: box = [xy2[0], boxCenter[1], 1, boxDims[1]] ; right
            2: box = [boxCenter[0], xy1[1], boxDims[0], 1] ; bottom
            3: box = [boxCenter[0], xy2[1], boxDims[0], 1] ; top
        endcase

        ; Find items hit on the edge.
        oVisEdge = oWin->DoHitTest(box[0], box[1], $
            DIMENSIONS=box[2:3], $
            /ORDER, $
            VIEWGROUP=oHitViewGroup)

        ; Nothing hit on the edge. Keep checking.
        if (~OBJ_VALID(oVisEdge[0])) then $
            continue

        ; Remove items on the edges from the overall list.
        for j=0,N_ELEMENTS(oVisEdge)-1 do begin
            good = WHERE(oVisList ne oVisEdge[j], ngood)
            ; There is nothing left in the overall viz list, so bail.
            if (ngood eq 0) then $
                return
            oVisList = oVisList[good]
        endfor

    endfor

    ; If we reach this point, then we should have some viz's left in
    ; the selection.

    oTool = self->GetTool()
    ; Disable tool updates during this process.
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; Clear all our old selections first.
    oWin->ClearSelections

    for i=0, N_ELEMENTS(oVisList)-1 do begin
        if (~OBJ_ISA(oVisList[i], '_IDLitVisualization')) then $
            continue
        ; This will almost always return the same objref, but some
        ; things (like the IDLitVisBackground), may return their
        ; parent instead.
        oVisHit = oVisList[i]->GetHitVisualization()
        oVisHit->Select, /ADDITIVE
    endfor
    IF (~previouslyDisabled) THEN $
      oTool->EnableUpdates      ; re-enable updates.

end


;--------------------------------------------------------------------------
; IDLitManipSelectBox::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button released
;
pro IDLitManipSelectBox::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; Sanity check.
    if (self.ButtonPress && OBJ_VALID(self._oRectangle)) then begin

        ; If our manip viz has a parent, assume this is a valid select box.
        self._oRectangle->GetProperty, PARENT=oParent

        haveBox = (self._startPT[0] ne x) && (self._startPT[1] ne y)

        if (OBJ_VALID(oParent)) then begin
            oParent->IDLgrModel::Remove, self._oRectangle
            ; Make sure we defined a valid region.
            if (haveBox) then $
                self->IDLitManipSelectBox::_SelectBox, oWin, self._startPT, [x, y]
        endif

        self->CancelAnnotation

        ; Only redraw if we defined a valid region.
        if (haveBox) then begin
            oTool = self->GetTool()
            oTool->RefreshCurrentWindow
        endif

    endif

    oWin->SetCurrentCursor, 'ARROW'

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

    ; Restore status message.
    statusMsg = self->GetStatusMessage('', 0)
    self->StatusMessage, statusMsg
end


;---------------------------------------------------------------------------
; IDLitManipSelectBox__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitManipSelectBox__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitManipSelectBox, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _oRectangle: OBJ_NEW(), $
            _oPolyline: OBJ_NEW() $
           }

end
