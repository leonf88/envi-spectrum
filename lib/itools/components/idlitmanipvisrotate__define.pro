; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisrotate__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRotate class is the rotate manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRotate')
;
;   or
;
;   Obj->[IDLitManipVisRotate::]Init
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
function IDLitManipVisRotate::Init, NAME=inName, $
    HIDE=hide, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Rotate Visual"

    ; Initialize superclasses.
    ; Default is to not be the Select Target.
    success = self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        HIDE=hide, $
        SELECT_TARGET=1, $
        VISUAL_TYPE='Rotate', $
        _EXTRA=_extra)

    if (not success) then $
        RETURN, 0

    self.oRotate2D = OBJ_NEW('IDLitManipVisRotate2D', _EXTRA=_extra)
    self->Add, self.oRotate2D, /NO_UPDATE

    ; Set any properties.
    self->IDLitManipVisRotate::SetProperty, _EXTRA=_extra
    RETURN, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   Overrides the superclass method.
;
; Arguments:
;   Is3D: Set to 1 to turn on 3D, 0 to turn off 3D.
;
; Keywords:
;   None.
;
pro IDLitManipVisRotate::Set3D, is3D

    compile_opt idl2, hidden


    if (is3D) then begin

        self->SetProperty, /UNIFORM_SCALE

        i = 100

        if (~OBJ_VALID(self.oRotateX)) then begin
            ; Rotate about the X axis
            self.oRotateX = OBJ_NEW('IDLitManipVisRotateAxis', $
                COLOR=[200,i,i], $
                VISUAL_TYPE='Rotate in X')
            self.oRotateX->Rotate, [0,1,0], 90
            self->Add, self.oRotateX, /NO_UPDATE
        endif else $
            self.oRotateX->SetProperty, HIDE=0

        if (~OBJ_VALID(self.oRotateY)) then begin
            ; Rotate about the Y axis
            self.oRotateY = OBJ_NEW('IDLitManipVisRotateAxis', $
                COLOR=[i,200,i], $
                VISUAL_TYPE='Rotate in Y')
            self.oRotateY->Rotate, [1,0,0], 90
            self->Add, self.oRotateY, /NO_UPDATE
        endif else $
            self.oRotateY->SetProperty, HIDE=0

        if (~OBJ_VALID(self.oRotateZ)) then begin
            ; Rotate about the Z axis
            self.oRotateZ = OBJ_NEW('IDLitManipVisRotateAxis', $
                COLOR=[i,i,200], $
                VISUAL_TYPE='Rotate in Z')
            self->Add, self.oRotateZ, /NO_UPDATE
        endif else $
            self.oRotateZ->SetProperty, HIDE=0

        self.oRotate2D->SetProperty, /HIDE

    endif else begin

        self->SetProperty, UNIFORM_SCALE=0

        if (OBJ_VALID(self.oRotateX)) then $
            self.oRotateX->SetProperty, /HIDE

        if (OBJ_VALID(self.oRotateY)) then $
            self.oRotateY->SetProperty, /HIDE

        if (OBJ_VALID(self.oRotateZ)) then $
            self.oRotateZ->SetProperty, /HIDE

        self.oRotate2D->SetProperty, HIDE=0

    endelse

    self->IDLitManipulatorVisual::Set3D, is3D
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitManipVisRotate object.
;
pro IDLitManipVisRotate__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRotate, $
        INHERITS IDLitManipulatorVisual, $
        oRotate2D: OBJ_NEW(), $
        oRotateX: OBJ_NEW(), $
        oRotateY: OBJ_NEW(), $
        oRotateZ: OBJ_NEW() $
        }
end
