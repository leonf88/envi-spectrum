; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprotateright__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRotateRight
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the RotateRight operation.
;
;-
;-------------------------------------------------------------------------
function IDLitopRotateRight::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitopRotateAngle::Init(NAME='Rotate Right', $
        DESCRIPTION='Rotate visualization clockwise', $
        EXTRA=_extra)
end


;---------------------------------------------------------------------------
function IDLitopRotateRight::DoAction, oTool
    compile_opt idl2, hidden

    ; This is a mathematical rotation, so -90 rotates clockwise.
    self._angle = -90
    return, self->IDLitopRotateAngle::DoAction(oTool)
end


;-------------------------------------------------------------------------
pro IDLitopRotateRight__define
    compile_opt idl2, hidden
    struc = {IDLitopRotateRight, $
        inherits IDLitopRotateAngle}
end

