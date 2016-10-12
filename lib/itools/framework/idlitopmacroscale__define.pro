; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacroscale__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroScale
;
; PURPOSE:
;   This file implements the operation that scales visualizations
;   in the current windows current view.  It is for use in macros
;   and history when a user uses the scale manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroScale::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroScale::Init
;   IDLitopMacroScale::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroScale::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroScale object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroScale::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Scale", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X', /FLOAT, $
        NAME='X Scale', $
        DESCRIPTION='X Scale'

    self->RegisterProperty, 'Y', /FLOAT, $
        NAME='Y Scale', $
        DESCRIPTION='Y Scale'

    self->RegisterProperty, 'Z', /FLOAT, $
        NAME='Z Scale', $
        DESCRIPTION='Z Scale'

    self->RegisterProperty, 'TYPE', /STRING, $
        NAME='Type', $
        DESCRIPTION='Type', $
        /HIDE

    self->RegisterProperty, 'KEYMODS', /INTEGER, $
        NAME='Keymods', $
        DESCRIPTION='Keymods', $
        /HIDE

    ; default values
    self._x = 1.0
    self._y = 1.0
    self._z = 1.0

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroScale::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroScale::GetProperty,        $
    X=x, $
    Y=y, $
    Z=z, $
    TYPE=type, $
    KEYMODS=keyMods, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(x)) then $
        x = self._x

    if (ARG_PRESENT(y)) then $
        y = self._y

    if (ARG_PRESENT(z)) then $
        z = self._z

    if (ARG_PRESENT(type)) then $
        type = self._type

    if (ARG_PRESENT(keyMods)) then $
        keyMods = self._keyMods

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroScale::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroScale::SetProperty,      $
    X=x, $
    Y=y, $
    Z=z, $
    TYPE=type, $
    KEYMODS=keyMods, $
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

    if (N_ELEMENTS(type) ne 0) then begin
        self._type = type
    endif

    if (N_ELEMENTS(keyMods) ne 0) then begin
        self._keyMods = keyMods
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroScale::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroScale object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroScale::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroScale::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroScale::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    idTool = oToolCurrent->GetFullIdentifier()

    oScale = oToolCurrent->GetByIdentifier(idTool+'/MANIPULATORS/ARROW/SCALE')
    oSelected = oToolCurrent->GetSelectedItems()
    if (~OBJ_VALID(oSelected[0]))then $
        return, obj_new()

    oSelected = oScale->_FindManipulatorTargets(oSelected)
    oScale->SetCurrentManipulator, self._type
    oSetPropOp = oToolCurrent->GetService('SET_PROPERTY')
    if (~OBJ_VALID(oSetPropOp))then begin
        return, obj_new()
    endif

    for i=0, n_elements(oSelected)-1 do begin
;        oSelected->GetProperty, CENTER_OF_ROTATION=scaleCenter
        scaleCenter = oScale->_ScaleCenter(oSelected[i], self._keyMods)
        oCmdSet = obj_new("IDLitCommandSet", NAME='Scale', $
                                OPERATION_IDENTIFIER= $
                                oSetPropOp->getFullIdentifier())
        iStatus = oSetPropOp ->RecordInitialValues(oCmdSet, $
                                            oSelected[i], $
                                            'TRANSFORM')

        oSelected[i]->Scale, self._x, self._y, self._z, /PREMULTIPLY, $
            CENTER_OF_ROTATION=scaleCenter
        oToolCurrent->RefreshCurrentWindow

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

pro IDLitopMacroScale__define

    compile_opt idl2, hidden

    void = {IDLitopMacroScale, $
            inherits IDLitOperation, $
            _x: 0.0D     , $
            _y: 0.0D     , $
            _z: 0.0D     , $
            _type: ''    , $
            _keyMods: 0L   $
                        }
end

