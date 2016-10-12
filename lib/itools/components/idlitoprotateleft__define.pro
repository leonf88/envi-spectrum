; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprotateleft__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRotateLeft
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the RotateLeft operation.
;
;-
;-------------------------------------------------------------------------
function IDLitopRotateLeft::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden

    return, self->IDLitopRotateAngle::Init(NAME='Rotate Left', $
        DESCRIPTION='Rotate visualization counter-clockwise', $
        _EXTRA=_extra)
end


;---------------------------------------------------------------------------
function IDLitopRotateLeft::DoAction, oTool
    compile_opt idl2, hidden

    ; This is a mathematical rotation, so 90 rotates counterclockwise.
    self._angle = 90
    return, self->IDLitopRotateAngle::DoAction(oTool)
end


;-------------------------------------------------------------------------
pro IDLitopRotateLeft__define
    compile_opt idl2, hidden
    struc = {IDLitopRotateLeft, $
        inherits IDLitopRotateAngle}
end

