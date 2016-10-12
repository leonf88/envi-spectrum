; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprotate__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Rotate manipulator container.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipRotate::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipRotate::Init, strType, TOOL=TOOL, _EXTRA=_extra

    compile_opt idl2, hidden

    types = ['DATASPACE_ROOT_3D', 'DATASPACE_ROOT_2D', $
            'IDLPOLYGON','IDLLIGHT', 'DATASPACE_2D', 'DATASPACE_3D', $
            'IDLTEXT', 'IDLROI']
    success = self->IDLitManipulatorContainer::Init( $
        DEFAULT_CURSOR='Rotate', $
        TYPES=types,$
        VISUAL_TYPE = 'Rotate', $
        _EXTRA=_extra, /AUTO_SWITCH, TOOL=TOOL)
    if (not success) then $
        return, 0

    ; First manipulator added to the container is the default.
    oRotate3D = OBJ_NEW('IDLitManipRotate3D', TOOL=TOOL, $
        TYPES=types, /private)
    if (~OBJ_VALID(oRotate3D)) then $
        return, 0
    self->Add, oRotate3D

    oRotateX = OBJ_NEW('IDLitManipRotateX', TOOL=TOOL, $
        TYPES=types, /private)
    if (~OBJ_VALID(oRotateX)) then $
        return, 0
    self->Add, oRotateX

    oRotateY = OBJ_NEW('IDLitManipRotateY', TOOL=TOOL, $
        TYPES=types, /private)
    if (~OBJ_VALID(oRotateY)) then $
        return, 0
    self->Add, oRotateY

    oRotateZ = OBJ_NEW('IDLitManipRotateZ', TOOL=TOOL, $
        TYPES=types, /private)
    if (~OBJ_VALID(oRotateZ)) then $
        return, 0
    self->Add, oRotateZ

    ; Set current manipulator to unconstrained rotation.
    self.m_currManip = oRotate3D
    return, 1
end


;---------------------------------------------------------------------------
; IDLitManipRotate__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitManipRotate__Define

    compile_opt idl2, hidden

    void = {IDLitManipRotate, $
        inherits IDLitManipulatorContainer $
        }

end
