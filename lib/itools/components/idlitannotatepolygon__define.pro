; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotatepolygon__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create a polygon annotation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotatePolygon::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotatePolygon::Init, _EXTRA=_extra
    ;; pragmas
    compile_opt idl2, hidden

    ;; Init our superclass
    status = self->IDLitManipAnnotation::Init(NAME='Polygon Manipulator',$
                                             KEYBOARD_EVENTS=1, $
                                              _EXTRA=_extra)
    if(status eq 0)then return, 0

    return, 1
end


;--------------------------------------------------------------------------
pro IDLitAnnotatePolygon::_StartPolygon, oWin, x, y

    compile_opt idl2, hidden

    ; Create our new annotation.
    oTool = self->GetTool()
    oDesc = oTool->GetAnnotation('Polygon')
    self._oPolygon = oDesc->GetObjectInstance()
    self._oPolygon->SetProperty, /TESSELLATE
    self._oPolygon->SetPropertyAttribute, $
        ['USE_BOTTOM_COLOR', 'BOTTOM'], /HIDE

    oWin->Add, self._oPolygon, layer='annotation'

    xydata = REBIN([x, y, self._normalizedZ], 3, 3)
    self._oPolygon->_IDLitVisualization::WindowToVis, xydata, xyout
    self._oPolygon->SetProperty, _DATA=xyout

    self._startXY = [x, y]

    self->StatusMessage, IDLitLangCatQuery('Status:AnnotatePoly:Text2') + $
        STRING(176b) + IDLitLangCatQuery('Status:AnnotatePoly:Text3')

end


;--------------------------------------------------------------------------
; IDLitAnnotatePolygon::_FinishPolygon
;
; Purpose:
;   Private method to finish up the polygon (either keep or destroy it).
;   Called from OnMouseUp and OnLoseCurrentManipulator.
;
pro IDLitAnnotatePolygon::_FinishPolygon, CANCEL=cancel

    compile_opt idl2, hidden

    self._mode = 0b  ; reset
    self._index = 0L

    if (self._oPolygon->CountVertex() lt 3) || KEYWORD_SET(cancel) then begin
        ; Rather a roundabout way to get to the oWin.
        ((self->GetTool())->GetCurrentWindow())->Remove, self._oPolygon
        OBJ_DESTROY, self._oPolygon
        self->CancelAnnotation
    endif else begin
        ;; Commit this annotation
         self->CommitAnnotation, self._oPolygon
    endelse

end


;--------------------------------------------------------------------------
; IIDLManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotatePolygon::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;      x       - X coordinate
;      y       - Y coordinate
;      iButton - Mask for which button pressed
;      KeyMods - Keyboard modifiers for button
;      nClicks - Number of clicks

pro IDLitAnnotatePolygon::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    ; pragmas
    compile_opt idl2, hidden

    ;; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    ; Double-click ends the polygon (or middle or right button).
    if (nClicks eq 2 || iButton ne 1) then $
        self._mode = 2

    oWin->SetCurrentCursor, 'CROSSHAIR'
end


;--------------------------------------------------------------------------
; IDLitAnnotatePolygon::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;      x       - X coordinate
;      y       - Y coordinate
;      iButton - Mask for which button released
;
; Mode flag:
;    _mode = 0: not currently drawing a polygon
;            1: in the middle of drawing
;            2: double-click, finish polygon
;            3: delete last vertex
;
pro IDLitAnnotatePolygon::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; See if we were deleted in the middle of our annotation.
    if (self._mode gt 0) then begin
        self._oPolygon->GetProperty, PARENT=oParent
        if (~OBJ_VALID(oParent)) then begin
            self->IDLitAnnotatePolygon::_FinishPolygon, /CANCEL
            return
        endif
    endif

    case self._mode of

        0: begin   ; First point
            self._mode = 1b
            self->IDLitAnnotatePolygon::_StartPolygon, oWin, x, y
            self._index = 1  ; we're now on the second point
           end

        1: begin   ; Middle point
            ; For the second point, we don't need to add another vertex,
            ; since we added it already in _StartPolygon.
            ; Otherwise, add the new vertex.
            if (self._index ge 2) then begin
                ; We've been changing the position of the last vertex in
                ; OnMouseMotion, so it's taken care of. Now, just add a new
                ; vertex to start moving. Might as well make it the same
                ; as the first vertex.
                self._oPolygon->AddVertex, $
                    [self._startXY, self._normalizedZ], /WINDOW
            endif
            self._index++
           end

        2: begin   ; Double-click, end polygon
            ; Because a double-click goes thru OnMouseUp twice,
            ; we've added an extra useless point, so remove it.
            self._oPolygon->RemoveVertex

            self->IDLitAnnotatePolygon::_FinishPolygon
            ; Call our superclass.
            self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton
           end

        3: begin   ; Delete last vertex
            self._mode = 1b   ; back to regular drawing
            case self._index of
                1: return
                2: begin
                    self._oPolygon->RemoveVertex, self._index - 1
                    self._index--
                    ; We need to add an extra vertex at the end,
                    ; to make a polygon with 3 vertices.
                    self._oPolygon->AddVertex, $
                        [self._startXY, self._normalizedZ], /WINDOW
                    end
                else: begin
                    ; Remove the previous point since that is the last
                    ; "true" vertex. Don't want to remove the "fake"
                    ; vertex at the current mouse location.
                    self._oPolygon->RemoveVertex, self._index - 1
                    self._index--
                    end
            endcase
           end

    endcase

end


;--------------------------------------------------------------------------
; IDLitAnnotatePolygon::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;   oWin    - Event Window Component
;   x       - X coordinate
;   y       - Y coordinate
;   KeyMods - Keyboard modifiers for button

pro IDLitAnnotatePolygon::OnMouseMotion, oWin, x, y, KeyMods
    ;; pragmas
    compile_opt idl2, hidden

    ; No polygon.
    if (self._index eq 0) then $
        return

    ; See if we were deleted in the middle of our annotation.
    self._oPolygon->GetProperty, PARENT=oParent
    if (~OBJ_VALID(oParent)) then begin
        self->IDLitAnnotatePolygon::_FinishPolygon, /CANCEL
        return
    endif

    ; Find length and angle from previous vertex.
    xyzPrev = self._oPolygon->GetVertex(self._index - 1, /WINDOW)
    xyDiff = [x, y] - xyzPrev[0:1]
    length = SQRT(xyDiff[0]^2 + xyDiff[1]^2)
    angle = (180/!DPI)*ATAN(xyDiff[1], xyDiff[0])

    ; If <Shift>, round off to nearest 45 degree angle.
    if (KeyMods and 1) then begin
        angle = 45*ROUND(angle/45d)
        x1 = xyzPrev[0] + length*COS(angle*!DPI/180)
        y1 = xyzPrev[1] + length*SIN(angle*!DPI/180)
    endif else begin
        x1 = x
        y1 = y
    endelse

    ; Round off to nice looking value.
    angle = LONG(((angle+360) mod 360)*100)/100d
    self->ProbeStatusMessage, STRING(x, y, length, angle, $
        FORMAT='(%"[%d,%d]   %d   %g")') + STRING(176b)

    self._oPolygon->MoveVertex, $
        [x1, y1, self._normalizedZ], INDEX=self._index, /WINDOW


end


;--------------------------------------------------------------------------
; IDLitAnnotatePolygon::OnKeyBoard
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
;
pro IDLitAnnotatePolygon::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

    compile_opt idl2, hidden

    if (self._mode eq 0) || (self._index eq 0) then $
        return

    if (Release) then begin

        case Character of

            13: begin  ; <Return>
                self->IDLitAnnotatePolygon::_FinishPolygon
                end

            27: begin  ; <Esc>
                ; Delete the previous vertex.
                self._mode = 3
                self->IDLitAnnotatePolygon::OnMouseUp, oWin, x, y, 0
                end

            else: ; do nothing

        endcase
    endif
end


;---------------------------------------------------------------------------
; IDLitAnnotatePolygon::OnLoseCurrentManipulator
;
; Purpose:
;   This routine is called by the manipulator system when this
;   manipulator is made "not current". If called, this routine will
;   make sure any pending annotations are completed
;
pro IDLitAnnotatePolygon::OnLoseCurrentManipulator

    compile_opt  idl2, hidden

    if (self._mode ne 0) then $
        self->IDLitAnnotatePolygon::_FinishPolygon

    ; Call our superclass.
    self->_IDLitManipulator::OnLoseCurrentManipulator
end


;---------------------------------------------------------------------------
; IDLitAnnotatePolygon__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotatePolygon__Define

    compile_opt idl2, hidden

    ;; Class structure definition
    void = {IDLitAnnotatePolygon, $
            inherits IDLitManipAnnotation, $
            _startXY: [0, 0],   $   ; First mouse down in window coords
            _index: 0L, $           ; index of current vertex
            _mode: 0b, $            ; flag for current mode
            _oPolygon: OBJ_NEW() $  ; Graphic for the annotation
        }

end

