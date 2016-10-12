; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotaterectangle__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create a rectangle annotation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateRectangle::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateRectangle::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipAnnotation::Init( $
        NAME='Rectangle Manipulator', $
        ICON="rectangl", $
        KEYBOARD_EVENTS=0, $
        /TRANSIENT_DEFAULT, _EXTRA=_extra)

    return, status
end


;--------------------------------------------------------------------------
; IIDLRotateManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotateRectangle::OnMouseDown
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

pro IDLitAnnotateRectangle::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    ; Ignore middle or right button clicks.
    if (iButton ne 1) then $
        return

    ; Create our new annotation.
    oTool = self->GetTool()
    oDesc = oTool->GetAnnotation('Rectangle')
    self._oRectangle = oDesc->GetObjectInstance()

    oWin->Add, self._oRectangle, layer='ANNOTATION'
    self._startPT = [x, y]

    oWin->SetCurrentCursor, 'CROSSHAIR'
end


;--------------------------------------------------------------------------
; IDLitAnnotateRectangle::OnMouseUp
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

pro IDLitAnnotateRectangle::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; If there was no change in coordinates between MouseDown and
    ; MouseUp, then do not commit the values.

    if ARRAY_EQUAL(self._startPT, [x, y]) then begin
        oWin->Remove, self._oRectangle
        OBJ_DESTROY, self._oRectangle
        self->CancelAnnotation
    endif else begin
        ;; Commit this to the system
        self->CommitAnnotation, self._oRectangle
    endelse

    oWin->SetCurrentCursor, 'ARROW'

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitAnnotateRectangle::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitAnnotateRectangle::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden


   if (self.ButtonPress gt 0) then begin
        x0 = self._startPt[0]
        y0 = self._startPt[1]
        ; Don't allow rectangles of zero width/height.
        if (x eq x0) || (y eq y0) then $
            return
        x1 = x
        y1 = y

        ; <Shift> key creates a square.
        if (KeyMods and 1) then begin
            dx = ABS(x1 - x0)
            dy = ABS(y1 - y0)
            if (dx ge dy) then begin
                y1 = y0 + ((y1 gt y0) ? dx : -dx)
            endif else begin
                x1 = x0 + ((x1 gt x0) ? dy : -dy)
            endelse
        endif

        ; <Ctrl> key creates a square symmetric about the start pt.
        if ((KeyMods and 2) ne 0) then begin
            x0 = 2*x0 - x1
            y0 = 2*y0 - y1
        endif

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

        xydata = [[x0,y0,z], [x1,y0,z], [x1,y1,z], [x0,y1,z]]
        self._oRectangle->_IDLitVisualization::WindowToVis, xydata, xyout
        self._oRectangle->SetProperty, _DATA=xyout

   endif else $
     self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;---------------------------------------------------------------------------
; IDLitAnnotateRectangle__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateRectangle__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateRectangle, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _oRectangle: OBJ_NEW() $
           }

end
