; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotatefreehand__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Create a freehand annotation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateFreehand::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateFreehand::Init, _EXTRA=_extra
    ;; pragmas
    compile_opt idl2, hidden

    ;; Init our superclass
    status = self->IDLitManipAnnotation::Init(NAME='Freehand Manipulator',$
                                             KEYBOARD_EVENTS=0, $
                                              ICON="freehand", $
                                             /TRANSIENT_DEFAULT, $
                                              _EXTRA=_extra)
    if(status eq 0)then return, 0

    self->IDLitAnnotateFreehand::_DoRegisterCursor, 'FREEHAND'

    return, 1
end


;--------------------------------------------------------------------------
; IIDLManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotateFreehand::OnMouseDown
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

pro IDLitAnnotateFreehand::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    ; pragmas
    compile_opt idl2, hidden

    ;; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    ; Ignore middle or right button clicks.
    if (iButton ne 1) then $
        return

    oWin->SetCurrentCursor, 'FREEHAND'

    ; Create our new annotation.
    oTool = self->GetTool()
    oDesc = oTool->GetAnnotation('freehand')
    self._oPolygon = oDesc->GetObjectInstance()
    self._oPolygon->SetProperty, /NO_CLOSE, /TESSELLATE
    self._oPolygon->SetPropertyAttribute, $
        ['USE_BOTTOM_COLOR', 'BOTTOM'], /HIDE

    oWin->Add, self._oPolygon, layer='annotation'

    xydata = [x, y, self._normalizedZ]
    self._oPolygon->_IDLitVisualization::WindowToVis, xydata, xyout
    self._oPolygon->SetProperty, _DATA=xyout

    self._startXY = [x, y]
    self._minXY = [x, y]
    self._maxXY = [x, y]
end


;--------------------------------------------------------------------------
; IDLitAnnotateFreehand::OnMouseUp
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

pro IDLitAnnotateFreehand::OnMouseUp, oWin, x, y, iButton
    ;; pragmas
    compile_opt idl2, hidden

    self._oPolygon->GetProperty, DATA=data
    if ((N_ELEMENTS(data) lt 6) || $
        ((max(data,min=min) EQ 0) && (min EQ 0))) then begin
        oWin->Remove, self._oPolygon
        OBJ_DESTROY, self._oPolygon
        self->CancelAnnotation
    endif else begin
        ;; Commit this annotation
         self->CommitAnnotation, self._oPolygon
    endelse
    ;; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitAnnotateFreehand::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;   oWin    - Event Window Component
;   x       - X coordinate
;   y       - Y coordinate
;   KeyMods - Keyboard modifiers for button

pro IDLitAnnotateFreehand::OnMouseMotion, oWin, x, y, KeyMods
    ;; pragmas
    compile_opt idl2, hidden

    if (self.ButtonPress gt 0) then begin

        ; Determine the greatest extent of the polygon.
        self._minXY = self._minXY < [x, y]
        self._maxXY = self._maxXY > [x, y]

        ;; Append new point to the polygon
        self._oPolygon->AddVertex, [x, y, self._normalizedZ], /WINDOW

        ; Display current mouse location and polygon width/height.
        self->ProbeStatusMessage, $
            STRING(x, y, ABS(self._maxXY - self._minXY), $
            FORMAT='(%"[%d,%d]   %d x %d")')

    endif else $
      self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; Purpose:
;   This procedure method registers the cursor to be associated with
;   this manipulator.
;
; Arguments:
;   strName:    A string representing the name to be associated
;     with the cursor.
;
pro IDLitAnnotateFreehand::_DoRegisterCursor, strName

    compile_opt idl2, hidden

    strArray = [ $
        '          ...   ', $
        '         .###.  ', $
        '         .#..#. ', $
        '        .##..#. ', $
        '       .#..##.  ', $
        '       .#...#.  ', $
        '      .#...#.   ', $
        '      .#...#.   ', $
        '     .#...#.    ', $
        '     .#...#.    ', $
        '    .#...#.     ', $
        '    .##..#.     ', $
        '    .####.      ', $
        '    .###.       ', $
        '    .##.        ', $
        '     $          ']

    self->RegisterCursor, strArray, strName, /DEFAULT

end


;---------------------------------------------------------------------------
; IDLitAnnotateFreehand__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateFreehand__Define

    compile_opt idl2, hidden

    ;; Class structure definition
    void = {IDLitAnnotateFreehand, $
            inherits IDLitManipAnnotation, $
            _startXY: [0, 0],   $ ; First mouse down in window coords
            _minXY: [0, 0], $     ; greatest extent of the polygon
            _maxXY: [0, 0], $     ; greatest extent of the polygon
            _oPolygon: OBJ_NEW() $ ; Graphic for the annotation
        }

end
