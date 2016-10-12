; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotateoval__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create an oval annotation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateOval::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateOval::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipAnnotation::Init( $
        NAME='Oval Manipulator', $
        ICON="ellipse", $
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
; IDLitAnnotateOval::OnMouseDown
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

pro IDLitAnnotateOval::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
                                         KeyMods, nClicks

    ; Ignore middle or right button clicks.
    if (iButton ne 1) then $
        return

    ; Create our new annotation.
    oTool = self->GetTool()
    oDesc = oTool->GetAnnotation('Oval')
    self._oEllipse = oDesc->GetObjectInstance()
    oWin->Add, self._oEllipse, layer='ANNOTATION'
    self._startPT = [x, y]

    oWin->SetCurrentCursor, 'CROSSHAIR'
end


;--------------------------------------------------------------------------
; IDLitAnnotateOval::OnMouseUp
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

pro IDLitAnnotateOval::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; If there was no change in coordinates between MouseDown and
    ; MouseUp, then do not commit the values.

    if ARRAY_EQUAL(self._startPT, [x, y]) then begin
        oWin->Remove, self._oEllipse
        OBJ_DESTROY, self._oEllipse
        self->CancelAnnotation
    endif else begin
        ;; Commit this to the system
        self->CommitAnnotation, self._oEllipse
    endelse

    oWin->SetCurrentCursor, 'ARROW'

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitAnnotateOval::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitAnnotateOval::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden


   if (self.ButtonPress gt 0) then begin
        x0 = self._startPt[0]
        y0 = self._startPt[1]
        ; Don't allow ovals of zero width/height.
        if (x eq x0) || (y eq y0) then $
            return
        x1 = x
        y1 = y

        ; <Shift> key creates a circle.
        if (KeyMods and 1) then begin
            dx = ABS(x1 - x0)
            dy = ABS(y1 - y0)
            if (dx ge dy) then begin
                y1 = y0 + ((y1 gt y0) ? dx : -dx)
            endif else begin
                x1 = x0 + ((x1 gt x0) ? dy : -dy)
            endelse
        endif

        ; <Ctrl> key creates an oval symmetric about the start pt.
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

        aa = (x1 - x0)/2d  ; semimajor axis
        bb = (y1 - y0)/2d  ; semiminor axis
        n = 181    ; this seems like an optimal # of points
        theta = DINDGEN(n)*(2*!DPI/(n-1))
        costheta = cos(theta)
        sintheta = sin(theta)
        rp = aa*bb/SQRT((bb^2)*costheta^2 + (aa^2)*sintheta^2)
        xx = rp*costheta + x0 + aa
        yy = rp*sintheta + y0 + bb
        xyzdata = TRANSPOSE([[xx], [yy], [REPLICATE(z, n)]])
        self._oEllipse->_IDLitVisualization::WindowToVis, xyzdata, xyzout

        self._oEllipse->SetProperty, _DATA=xyzout

   endif else $
     self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;---------------------------------------------------------------------------
; IDLitAnnotateOval__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateOval__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateOval, $
            inherits IDLitManipAnnotation, $
            _startPt: [0, 0], $
            _oEllipse: OBJ_NEW() $
           }

end
