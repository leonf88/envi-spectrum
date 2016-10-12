; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotateline__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create a line annotation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateLine::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateLine::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipAnnotation::Init(NAME='Line Manipulator', $
        KEYBOARD_EVENTS=0, $
        /TRANSIENT_DEFAULT, _EXTRA=_extra)

    if (status eq 0)then return, 0

    return, 1
end


;--------------------------------------------------------------------------
; IIDLRotateManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotateLine::OnMouseDown
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

pro IDLitAnnotateLine::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    ; Ignore middle or right button clicks.
    if (iButton ne 1) then $
        return

    oWin->SetCurrentCursor, 'CROSSHAIR'

    ; Create our new annotation.
    oTool = self->GetTool()
    oDesc = oTool->GetAnnotation('Line')
    self._oLine = oDesc->GetObjectInstance()

    oWin->Add, self._oLine, layer='ANNOTATION'
    self._startPT = [x, y]

end


;--------------------------------------------------------------------------
; IDLitAnnotateLine::OnMouseUp
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

pro IDLitAnnotateLine::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; If there was no change in coordinates between MouseDown and
    ; MouseUp, then do not commit the values.

    if ARRAY_EQUAL(self._startPT, [x, y]) then begin
        oWin->Remove, self._oLine
        OBJ_DESTROY, self._oLine
        self->CancelAnnotation
    endif else begin
        ;; Commit this to the system
        self->CommitAnnotation, self._oLine
    endelse
    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitAnnotateLine::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitAnnotateLine::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden


   if (self.ButtonPress gt 0) then begin
        xy0 = self._startPt
        xy1 = [x, y]

        ; <Shift> key creates a line constrained along the start line.
        if (KeyMods and 1) then begin
            ; Retrieve the current line endpoint.
            xyEnd = self._oLine->GetVertex(1, /WINDOW)
            if (N_ELEMENTS(xyEnd) eq 3) then begin
                lineXY = xyEnd - xy0
                ; Project the line from the further pt to the current XY
                ; down onto the line connecting the two points,
                ; using the dot product.
                factor = TOTAL((xy1 - xy0)*lineXY)/TOTAL(lineXY^2)
                xy1 = xy0 + factor*lineXY
            endif
        endif

        ; <Ctrl> key creates a line symmetric about the start pt.
        if ((KeyMods and 2) ne 0) then $
            xy0 = 2*xy0 - xy1

        ;; Add the Z so that values are in the annotation layer and
        ;; not clipped by the Viz.
        xy0 = [xy0,self._normalizedZ]
        xy1 = [xy1,self._normalizedZ]
        if (self._oLine->CountVertex() eq 0) then begin
            self._oLine->_IDLitVisualization::WindowToVis, xy0, xy0out
            self._oLine->_IDLitVisualization::WindowToVis, xy1, xy1out
            self._oLine->SetProperty, _DATA=[[xy0out], [xy1out]]
        endif else begin
            self._oLine->MoveVertex, [[xy0], [xy1]], INDEX=[0,1], /WINDOW
        endelse

        ; Find length and angle and report in status area.
        length = LONG(SQRT(TOTAL((xy1[0:1] - xy0[0:1])^2)))
        angle = (180/!DPI)*ATAN(xy1[1]-xy0[1], xy1[0]-xy0[0])
        angle = LONG(((angle+360) mod 360)*100)/100d
        self->ProbeStatusMessage, STRING(x, y, length, angle, $
            FORMAT='(%"[%d,%d]   %d   %g")') + STRING(176b)

   endif else $
     self->idlitmanipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;---------------------------------------------------------------------------
; IDLitAnnotateLine__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateLine__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateLine, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _oLine: OBJ_NEW() $
           }

end
