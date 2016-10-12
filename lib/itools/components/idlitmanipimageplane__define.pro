; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipimageplane__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipImagePlane
;
; PURPOSE:
;   The Volume Image Plane manipulator.  This class provides the user with
;   a way to select the image plane by its selection visual and move it.
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
;   See IDLitManipImagePlane::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipImagePlane::Init
;   IDLitManipImagePlane::Cleanup
;
; INTERFACES:
; IIDLProperty
; IIDLWindowEvent
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipImagePlane::Init
;
; PURPOSE:
;       The IDLitManipImagePlane::Init function method initializes the
;       Image Plane Manipulator component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipImagePlane', <manipulator type>)
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
; IDLitManipImagePlane::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;  strType     - The type of the manipulator. This is immutable.
;

function IDLitManipImagePlane::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init(_EXTRA=_extra, $
                                  VISUAL_TYPE ='Select', $
                                  IDENTIFIER="IMAGE PLANE", $
                              OPERATION_IDENTIFIER="SET_PROPERTY", $
                              PARAMETER_IDENTIFIER="TRANSFORM", $
                                  NAME='Image Plane')
    if (iStatus eq 0) then $
        return, 0

    self->IDLitManipImagePlane::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipImagePlane::Cleanup
;
; Purpose:
;  The destructor of the component.
;

; Nothing to clean up



;--------------------------------------------------------------------------
; IDLitManipImagePlane Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitManipImagePlane::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;  oWin    - Source of the event
;  x       - X coordinate
;  y       - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitManipImagePlane::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
    ; pragmas
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    self.is3D = 0b

    if (self.nSelectionList gt 0) then begin

        ; See if any of the selected viz are 3d.
        ; Assume that we only need to check this on a mouse down.
        for i=0,self.nSelectionList-1 do begin
            if (*self.pSelectionList)[i]->Is3D() then begin
                self.is3D = 1b
                break   ; no need to continue checking.
            endif
        endfor

        ;; Record the current values for the target objects
        iStatus = self->RecordUndoValues()

        self.startXY = [x,y]
        self.prevXY = self.startXY

        ;; Cache the amount of change in Vis space per one unit of change
        ;; in both X and Y.  We use this later to translate the image plane
        ;; as the mouse moves in X and Y.

        ;; Transform data space origin to screen space.
        oVis = ((self->GetTool())->GetSelectedItems())[0]
        oDataSpace = oVis->GetDataSpace()
        oDataSpace->_IDLitVisualization::VisToWindow, [0.0d, 0.0d, 0.0d], scrOrig

        ;; Add one pixel in X to the screen origin, and transform back to data space
        oDataSpace->_IDLitVisualization::WindowToVis, scrOrig + [1.,0.,0.], dataPt
        self.dx = dataPt

        ;; Add one pixel in Y to the screen origin, and transform back to data space
        oDataSpace->_IDLitVisualization::WindowToVis, scrOrig + [0.,1.,0.], dataPt
        self.dy = dataPt

        self->StatusMessage, $
       IDLitLangCatQuery('Status:ImagePlane:DragToMove')

    endif

end
;--------------------------------------------------------------------------
; IDLitManipImagePlane::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;  oWin    - Source of the event
;  x       - X coordinate
;  y       - Y coordinate
;  iButton - Mask for which button released

pro IDLitManipImagePlane::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    if(self.nSelectionList gt 0)then begin
        ;; Commit this transaction
        iStatus = self->CommitUndoValues( $
            UNCOMMIT=ARRAY_EQUAL(self.startXY, [x,y]))
    endif
    ; Call our superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end

;--------------------------------------------------------------------------
; IDLitManipImagePlane::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x       - X coordinate
;  y       - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipImagePlane::OnMouseMotion, oWin, x, y, KeyMods
    ; pragmas
    compile_opt idl2, hidden

    if (self.nSelectionList gt 0) then begin
        oVis = ((self->GetTool())->GetSelectedItems())[0]

        ;; Compute movement in vis space, using the change in screen space
        ;; times the screen-to-vis factors.
        delta = self.dx * (x-self.prevXY[0]) + self.dy * (y-self.prevXY[1])
        ;; Apply transform to image plane.
        oVis->Translate, delta[0], delta[1], delta[2], /PREMULTIPLY
        ;; Update the graphics hierarchy.
        (self->GetTool())->RefreshCurrentWindow
        ;; Save new screen position for next time.
        self.prevXY=[x,y]

        oVis->GetProperty, PLANE_CENTER=center
        msg = IDLitLangCatQuery('Status:ImagePlane:Center') + STRING(center, FORMAT='(%"[%d,%d,%d]")')
        self->ProbeStatusMessage, msg
   endif

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

end



;---------------------------------------------------------------------------
; IDLitManipImagePlane::Define
;
; Purpose:
;   Define the base object for the manipulator
;

pro IDLitManipImagePlane__Define
   ; pragmas
   compile_opt idl2, hidden

   void = {IDLitManipImagePlane, $
           INHERITS IDLitManipulator,       $
           startXY: DBLARR(2),              $
           prevXY: DBLARR(2),               $
           dx: DBLARR(3),                   $
           dy: DBLARR(3),                   $
           is3D: 0b $
      }
end
