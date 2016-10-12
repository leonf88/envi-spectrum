; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisselect__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisSelect class is the select manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisSelect')
;
;   or
;
;   Obj->[IDLitManipVisSelect::]Init
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
function IDLitManipVisSelect::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Select Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init(NAME=name, $
        VISUAL_TYPE='Select', _EXTRA=_extra) ne 1) then $
        return, 0

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
;pro IDLitManipVisSelect::Cleanup
;    compile_opt idl2, hidden
    ; Cleanup superclasses.
;    self->IDLitManipulatorVisual::Cleanup
;end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisSelect__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisSelect object.
;-
pro IDLitManipVisSelect__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisSelect, $
        inherits IDLitManipulatorVisual $
        }
end
