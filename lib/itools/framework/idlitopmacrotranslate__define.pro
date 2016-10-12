; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrotranslate__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroTranslate
;
; PURPOSE:
;   This file implements the operation that translates visualizations
;   in the current windows current view.  It is for use in macros
;   and history when a user uses the translate manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroTranslate::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroTranslate::Init
;   IDLitopMacroTranslate::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroTranslate::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroTranslate object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroTranslate::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Translate", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'X', /FLOAT, $
        NAME='X Translation', $
        DESCRIPTION='X Translation (Pixels)'

    self->RegisterProperty, 'Y', /FLOAT, $
        NAME='Y Translation', $
        DESCRIPTION='Y Translation (Pixels)'

    self->RegisterProperty, 'KEYMODS', /INTEGER, $
        NAME='Keymods', $
        DESCRIPTION='Keymods', $
        /HIDE

    self->RegisterProperty, 'KEYVALUE', /INTEGER, $
        NAME='KeyValue', $
        DESCRIPTION='KeyValue', $
        /HIDE

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroTranslate::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroTranslate::GetProperty,        $
    KEYMODS=keyMods, $
    KEYVALUE=keyValue, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(keyMods)) then $
        keyMods = self._keyMods

    if (ARG_PRESENT(keyValue)) then $
        keyValue = self._keyValue

    if (arg_present(x)) then $
        x = self._x

    if (ARG_PRESENT(y)) then $
        y = self._y

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroTranslate::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroTranslate::SetProperty,      $
    KEYMODS=keyMods, $
    KEYVALUE=keyValue, $
    X=x, $
    Y=y, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(keyMods) ne 0) then begin
        self._keyMods = keyMods
    endif

    if (N_ELEMENTS(keyValue) ne 0) then begin
        self._keyValue = keyValue
    endif

    if (N_ELEMENTS(x) ne 0) then begin
        self._x = x
    endif

    if (N_ELEMENTS(y) ne 0) then begin
        self._y = y
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroTranslate::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroTranslate object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroTranslate::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroTranslate::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroTranslate::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    idTool = oToolCurrent->GetFullIdentifier()

    ;; get the translate manipulator
    oTrans = oToolCurrent->getByIdentifier(idTool+'/MANIPULATORS/ARROW/TRANSLATE')

    oSelected = oToolCurrent->GetSelectedItems()
    if (~OBJ_VALID(oSelected))then $
        return, obj_new()

    oSelected = oTrans->_FindManipulatorTargets(oSelected)
    oSetPropOp = oToolCurrent->GetService('SET_PROPERTY')
    if (~OBJ_VALID(oSetPropOp))then begin
        return, obj_new()
    endif

    for i=0, n_elements(oSelected)-1 do begin
        ;; Transform data space origin to screen space.
        oSelected[i]->VisToWindow, [0.0d, 0.0d, 0.0d], scrOrig

        ;; Add one pixel in X to the screen origin, and revert back to
        ;; screen space.
        oSelected[i]->WindowToVis, scrOrig + [1.,0.,0.], dxVec

        ;; Add one pixel in Y to the screen origin, and revert back to
        ;; screen space.
        oSelected[i]->WindowToVis, scrOrig + [0.,1.,0.], dyVec

        ;; The translation in data space equals the screen space delta
        ;; multiplied by the unit data space vectors.
        dVec =  ( self._x * dxVec) $
                     + (self._y * dyVec)

        oCmdSet = obj_new("IDLitCommandSet", NAME='Translate', $
                                OPERATION_IDENTIFIER= $
                                oSetPropOp->getFullIdentifier())
        iStatus = oSetPropOp ->RecordInitialValues(oCmdSet, $
                                            oSelected[i], $
                                            'TRANSFORM')

        ;; Translate to the new coordinates.
        if obj_isa(oSelected[i], 'IDLitVisAxis') then begin
            oSelected[i]->Translate, dVec[0], dVec[1], dVec[2], $
                KEYMODS=self._keyMods, $
                KEYVALUE=self._keyValue, $
                /PREMULTIPLY
        endif else begin
            oSelected[i]->Translate, dVec[0], dVec[1], dVec[2], $
                /PREMULTIPLY
        endelse

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

pro IDLitopMacroTranslate__define

    compile_opt idl2, hidden

    void = {IDLitopMacroTranslate, $
            inherits IDLitOperation, $
            _keyMods: 0L,$
            _keyValue:0L,$
            _x: 0L     , $
            _y: 0L       $
                        }
end

