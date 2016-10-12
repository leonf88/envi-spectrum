; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotatearrow__define.pro#2 $
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
; IDLitAnnotateArrow::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateArrow::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipAnnotation::Init(NAME='Arrow Manipulator', $
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
; IDLitAnnotateArrow::OnMouseDown
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

pro IDLitAnnotateArrow::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

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
    oDescLine = oTool->GetAnnotation('Line')
    self._oLine = oDescLine->GetObjectInstance()
    oWin->Add, self._oLine, layer='ANNOTATION'

    self._startPT = [x, y]

end


;--------------------------------------------------------------------------
; IDLitAnnotateArrow::OnMouseUp
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

pro IDLitAnnotateArrow::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; If there was no change in coordinates between MouseDown and
    ; MouseUp, then do not commit the values.

    oWin->Remove, self._oLine
    obj_destroy, self._oLine
    if ARRAY_EQUAL(self._startPT, [x, y]) then begin
        self->CancelAnnotation
    endif else begin
        ;; Commit this to the system
        oTool = self->GetTool()
        oDesc = oTool->GetAnnotation('Arrow')
        self._oArrow = oDesc->GetObjectInstance()
        oWin->Add, self._oArrow, layer='ANNOTATION'
        self._oArrow->_IDLitVisualization::WindowToVis, [self._startPt, self._normalizedZ], xy0out
        self._oArrow->_IDLitVisualization::WindowToVis, [x,y, self._normalizedZ], xy1out
        self._oArrow->setProperty, DATA=[[xy0out],[xy1out]]
        self->CommitAnnotation, self._oArrow
    endelse
    ; Call our superclass.
    
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitAnnotateArrow::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitAnnotateArrow::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden

   if (self.ButtonPress gt 0) then begin
        xy0 = self._startPt
        xy1 = [x, y]
        xy0 = [xy0,self._normalizedZ]
        xy1 = [xy1,self._normalizedZ]
        self._oLine->_IDLitVisualization::WindowToVis, xy0, xy0out
        self._oLine->_IDLitVisualization::WindowToVis, xy1, xy1out
        self._oLine->SetProperty, _DATA=[[xy0out], [xy1out]], arrow_style=1, hide=0
    endif else self->idlitmanipulator::OnMouseMotion, oWin, x, y, KeyMods
end


;---------------------------------------------------------------------------
; IDLitAnnotateArrow__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateArrow__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateArrow, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _oLine: obj_new(), $
            _oArrow: OBJ_NEW() $
           }

end
