; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprotatebyangle__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRotateByAngle
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the RotateLeft operation.
;
;-
;-------------------------------------------------------------------------
function IDLitopRotateByAngle::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitopRotateAngle::Init(NAME='Rotate by Angle', $
        DESCRIPTION='Rotate visualization by a given angle', $
        _EXTRA=_extra)) then $
        return, 0

    self->RegisterProperty, 'ANGLE', /FLOAT, $
        NAME='Angle', $
        DESCRIPTION='Rotation angle', $
        VALID_RANGE=[-360, 360]

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitopRotateByAngle::GetProperty, $
    ANGLE=angle, $
    RELATIVE=relative, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(angle)) then $
        angle = self._angle

    if (ARG_PRESENT(relative)) then $
        relative = self._relative

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopRotateAngle::GetProperty, _EXTRA=_extra
end

;;---------------------------------------------------------------------------
pro IDLitopRotateByAngle::SetProperty, $
    ANGLE=angle, $
    RELATIVE=relative, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(N_ELEMENTS(angle) gt 0) then begin
        self._angle = angle
        self._angle = self._angle mod 360
        if (self._angle gt 180) then $
            self._angle -= 360
        if (self._angle lt -180) then $
            self._angle += 360
    endif

    if(N_ELEMENTS(relative) gt 0) then $
        self._relative = relative

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopRotateAngle::SetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
function IDLitopRotateByAngle::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oManipTargets = self->IDLitopRotateAngle::_Targets(oTool, COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()

    self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI
    if (showExecutionUI) then begin

        ; Default is to do an absolute angle.
        self._relative = 0b

        ; If we only have 1 selected item, and it is 2D, then
        ; retrieve its current rotation angle.
        if (count eq 1) && (~oManipTargets[0]->Is3d()) then begin

            ; Convert from the transform matrix back to a Z rotation.
            ; This takes into account translations and scaling,
            ; but assume no rotations have ever occurred about X or Y.
            ; Should this be a GetCTM instead, in case the parent is rotated?
            oManipTargets[0]->GetProperty, TRANSFORM=transform

            ; Rotate an x-unit vector, and find its angle relative
            ; to the X axis.
            xrotate = transform ## [1d,0,0,0]
            self._angle = (180/!DPI)*ATAN(xrotate[1], xrotate[0])

            ; Note: Do we want to restrict to integer values?
            self._angle = LONG(self._angle)

            self._relative = 1b

        endif

        if (~oTool->DoUIService('RotateByAngle', self)) then $
            return, OBJ_NEW()  ; will cause a roll back

    endif

    return, self->IDLitopRotateAngle::DoAction(oTool)
end


;-------------------------------------------------------------------------
pro IDLitopRotateByAngle__define
    compile_opt idl2, hidden
    struc = {IDLitopRotateByAngle, $
        inherits IDLitopRotateAngle, $
;        _angle: 0D, $
        _relative: 0b}
end

