; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisimageplane__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisImagePlane class displays a manip visual for the
;   Volume Image Plane.


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisImagePlane')
;
;   or
;
;   Obj->[IDLitManipVisImagePlane::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisImagePlane::Init, $
    COLOR=color, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Image Plane Manipulation Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    ; Make the selection visual slightly larger than the image plane to make
    ; it easier to select.
    verts = [[-1.,-1.,0],[1.,-1.,0],[1.,1.,0],[-1.,1.,0],[-1.,-1.,0]] * 1.07
    oBorder = OBJ_NEW('IDLgrPolyline', verts, $
        COLOR=[0,255,255], DEPTH_TEST_FUNCTION=4)
    self->Add, oBorder

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitManipVisImagePlane::Cleanup

    compile_opt idl2, hidden

    self->IDLitManipulatorVisual::Cleanup
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisImagePlane__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisImagePlane object.
;-
pro IDLitManipVisImagePlane__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisImagePlane, $
        inherits IDLitManipulatorVisual $
        }
end
