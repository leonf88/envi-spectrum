; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrorotate__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroRotate
;
; PURPOSE:
;   This file implements the operation that translates visualizations
;   in the current window's current view. It is for use in macros
;   and history when a user uses the rotate manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroRotate::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroRotate::Init
;   IDLitopMacroRotate::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroRotate::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroRotate object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRotate::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Rotate", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X', /FLOAT, $
        NAME='X Rotation', $
        DESCRIPTION='X Rotation', $
        SENSITIVE=0

    self->RegisterProperty, 'Y', /FLOAT, $
        NAME='Y Rotation', $
        DESCRIPTION='Y Rotation', $
        SENSITIVE=0

    self->RegisterProperty, 'Z', /FLOAT, $
        NAME='Z Rotation', $
        DESCRIPTION='Z Rotation'


    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroRotate::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroRotate::GetProperty,        $
    X=x, $
    Y=y, $
    Z=z, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(x)) then $
        x = self._x

    if (ARG_PRESENT(y)) then $
        y = self._y

    if (arg_present(z)) then $
        z = self._z

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroRotate::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroRotate::SetProperty,      $
    X=x, $
    Y=y, $
    Z=z, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(x) ne 0) then begin
        self._x = x
    endif

    if (N_ELEMENTS(y) ne 0) then begin
        self._y = y
    endif

    if (N_ELEMENTS(z) ne 0) then begin
        self._z = z
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroRotate::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroRotate object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroRotate::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroRotate::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroRotate::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    idTool = oToolCurrent->GetFullIdentifier()

    ;; get the rotate manipulator
    oRot = oToolCurrent->GetByIdentifier(idTool+'/MANIPULATORS/ROTATE')
    oSelected = oToolCurrent->GetSelectedItems()
    if (~OBJ_VALID(oSelected))then $
        return, obj_new()

    oSelected = oRot->_FindManipulatorTargets(oSelected)
    oSetPropOp = oToolCurrent->GetService('SET_PROPERTY')
    if (~OBJ_VALID(oSetPropOp))then begin
        return, obj_new()
    endif

    for i=0, n_elements(oSelected)-1 do begin
        oCmdSet = obj_new("IDLitCommandSet", NAME='Rotate', $
                                OPERATION_IDENTIFIER= $
                                oSetPropOp->getFullIdentifier())
        iStatus = oSetPropOp ->RecordInitialValues(oCmdSet, $
                                            oSelected[i], $
                                            'TRANSFORM')

        oSelected[i]->GetProperty, TRANSFORM=oldTransform, $
            CENTER_OF_ROTATION=centerRotation

        ; Temporarily use selected visualization's transformation matrix
        ; to compute the rotation matrix.
        oSelected[i]->IDLgrModel::Reset
        oSelected[i]->IDLgrModel::Rotate, [1, 0, 0], self._x
        oSelected[i]->IDLgrModel::Rotate, [0, 1, 0], self._y
        oSelected[i]->IDLgrModel::Rotate, [0, 0, 1], self._z
        oSelected[i]->IDLgrModel::GetProperty, TRANSFORM=rotateTransform

        ; Perform translate, rotate, translate back transform
        cr = [centerRotation, 1.0d] # oldTransform
        t1 = IDENTITY(4)
        t1[3,0] = -cr[0]
        t1[3,1] = -cr[1]
        t1[3,2] = -cr[2]
        t2 = IDENTITY(4)
        t2[3,0] = cr[0]
        t2[3,1] = cr[1]
        t2[3,2] = cr[2]

        transform = oldTransform # t1 # rotateTransform # t2
        oSelected[i]->SetProperty, TRANSFORM=transform

        iStatus = oSetPropOp->RecordFinalValues(oCmdSet, $
                                                oSelected[i], $
                                                'TRANSFORM', $
                                                /SKIP_MACROHISTORY)

        oCmdSets = (N_ELEMENTS(oCmdSets) gt 0) ? [oCmdSets, oCmdSet] : oCmdSet
    endfor

    return, (N_ELEMENTS(oCmdSets) gt 0) ? oCmdSets : OBJ_NEW()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroRotate__define

    compile_opt idl2, hidden

    void = {IDLitopMacroRotate, $
            inherits IDLitOperation, $
            _x: 0D     , $
            _y: 0D     , $
            _z: 0D       $
                        }
end

