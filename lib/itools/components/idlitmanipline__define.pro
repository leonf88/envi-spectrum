; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipline__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipLine
;
; PURPOSE:
;   The line manipulator.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulator
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipLine::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipLine::Init
;   IDLitManipLine::Cleanup
;   IDLitManipLine::
;
; INTERFACES:
; IIDLProperty
; IIDLWindowEvent
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipLine::Init
;
; PURPOSE:
;       The IDLitManipLine::Init function method initializes the
;       Line Manipulator component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipLine', <manipulator type>)
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipLine::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;  strType     - The type of the manipulator. This is immutable.
;

function IDLitManipLine::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init(_EXTRA=_extra, $
        VISUAL_TYPE ='Select', $
        OPERATION_IDENTIFIER="SET_PROPERTY", $
        PARAMETER_IDENTIFIER="_DATA", $
        IDENTIFIER="LINE", $
        NAME='Line')
    if (iStatus eq 0) then $
        return, 0

    self->IDLitManipLine::SetProperty, _EXTRA=_extra

    return, 1
end


;--------------------------------------------------------------------------
; IDLitManipLine::Cleanup
;
; Purpose:
;  The destructor of the component.
;

;pro IDLitManipLine::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipLine Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
; TODO: How does the current Visualization...etc fit into these
;       method calls?
;--------------------------------------------------------------------------
; IDLitManipLine::OnMouseDown
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

pro IDLitManipLine::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    if (self.nSelectionList gt 0) then begin
        self.startXY = [x,y]
        self.prevXY = [x, y]
        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()
        self->StatusMessage, $
       IDLitLangCatQuery('Status:LineManip:Text')
    endif

end


;--------------------------------------------------------------------------
; IDLitManipLine::OnMouseUp
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
pro IDLitManipLine::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    if (self.nSelectionList gt 0) then begin
        ;; Commit this transaction
        iStatus = self->CommitUndoValues( $
            UNCOMMIT=ARRAY_EQUAL(self.startXY, [x,y]))
    endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end

;--------------------------------------------------------------------------
; IDLitManipLine::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button
;
pro IDLitManipLine::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

    if (self.nSelectionList gt 0) && (self.point le 1) then begin

        oVis = (*self.pSelectionList)[0]

        newXY = [x, y]   ; Default is to simply move to new point.

        ; Retrieve both starting & end point.
        points = oVis->GetVertex([0,1], /WINDOW)
        zvalue = (points[2,0] ne 0) ? self._normalizedZ : 0
        ; If the line is in the dataspace instead of the annotation layer
        ; then a super small, but non-zero value for z changes the display
        ; to 3D.  Check for that condition.
        if (ABS(zvalue) lt (MACHAR()).EPS) then $
          zvalue = 0
        ptClick = points[0:1,self.point]
        ptOther = points[0:1,1 - self.point]

        ; <Shift> key forces constrained scaling along the line.
        if (KeyMods and 1) then begin

            ; Distance from start XY to the further point.
            lineXYother = self.prevXY - ptOther
            distOther = SQRT(TOTAL(lineXYother^2))

            if (distOther) then begin
                ; Project the line from the further pt to the current XY
                ; down onto the line connecting the two points,
                ; using the dot product.
                projection = $
                    TOTAL((newXY - ptOther)*lineXYother) / distOther
                newXY = ptOther + (projection/distOther)*lineXYother
            endif

        endif

        newPoints = [newXY, zvalue]
        pointIndex = self.point

        ; <Ctrl> key forces constrained scaling about the center.
        if ((KeyMods and 2) ne 0) then begin
            otherXY = ptOther + (ptClick - newXY)
            newPoints = [[newPoints], [otherXY, zvalue]]
            pointIndex = [pointIndex, 1 - self.point]
        endif

        ; Move vertex location(s). This will also update the graphics.
        oVis->MoveVertex, newPoints, INDEX=pointIndex, /WINDOW

        ; Find length and angle and report in status area.
        xy1 = newPoints[*,0]
        xy0 = (N_ELEMENTS(pointIndex) eq 2) ? $
            newPoints[*,1] : ptOther
        length = LONG(SQRT(TOTAL((xy1[0:1] - xy0[0:1])^2)))
        angle = (180/!DPI)*ATAN(xy1[1]-xy0[1], xy1[0]-xy0[0])
        angle = LONG(((angle+360) mod 360)*100)/100d
        self->ProbeStatusMessage, STRING(x, y, length, angle, $
            FORMAT='(%"[%d,%d]   %d   %g")') + STRING(176b)

        ; Cache our new starting location.
        self.prevXY = newXY

   endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end


;--------------------------------------------------------------------------
; IDLitManipLine::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitManipLine::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    return, 'SIZE_SE'

end


;---------------------------------------------------------------------------
; IDLitManipLine::SetCurrentManipulator
;
; Purpose:
;    Used to set the active type for the IDLitManipulator.
;
pro IDLitManipLine::SetCurrentManipulator, type, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Just strip off the letters "VERT" and cache the point number.
    if (N_ELEMENTS(type) gt 0) then $
        self.point = LONG(STRMID(type, 4))

    ; Call our superclass.
    self->IDLitManipulator::SetCurrentManipulator, type, _EXTRA=_extra
end


;--------------------------------------------------------------------------
; IDLitManipLine::GetStatusMesssage
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
function IDLitManipLine::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    return, IDLitLangCatQuery('Status:LineManip:Text')
end


;---------------------------------------------------------------------------
; IDLitManipLine::Define
;
; Purpose:
;   Define the base object for the manipulator
;

pro IDLitManipLine__Define
   ; pragmas
   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitManipLine, $
           INHERITS IDLitManipulator,       $ ; I AM A COMPONENT
           startXY: [0d, 0d], $
           prevXY: [0d, 0d], $
           point: 0L $
      }
end
