; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrostepdisplaychange__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroStepDisplayChange
;
; PURPOSE:
;   This file implements the operation that changes the range
;   of the current data spaces.  It is for use in macros
;   and history when a user uses the range box, range pan or
;   range zoom manipulators.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroStepDisplayChange::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroStepDisplayChange::Init
;   IDLitopMacroStepDisplayChange::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroStepDisplayChange::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroStepDisplayChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroStepDisplayChange::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Macro Step Display Change", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'DISPLAY_STEPS', /BOOLEAN, $
        Name='Display intermediate steps', $
        Description='Display intermediate steps during macro execution'


    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroStepDisplayChange::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroStepDisplayChange::GetProperty, $
    DISPLAY_STEPS=displaySteps,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(displaySteps)) then $
        displaySteps = self._displaySteps

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroStepDisplayChange::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroStepDisplayChange::SetProperty,      $
    DISPLAY_STEPS=displaySteps,   $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(displaySteps) gt 0) then $
        self._displaySteps = KEYWORD_SET(displaySteps)

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroStepDisplayChange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroStepDisplayChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroStepDisplayChange::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroStepDisplayChange::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroStepDisplayChange::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    oSrvMacro = oTool->GetService('MACROS')
    if ~obj_valid(oSrvMacro) then return, obj_new()

    oSrvMacro->SetProperty, $
            DISPLAY_STEPS=self._displaySteps

    oCmdSet = obj_new("IDLitCommandSet", NAME='Macro Step Display Change', $
                            OPERATION_IDENTIFIER= $
                            self->getFullIdentifier())


    return, oCmdSet
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroStepDisplayChange__define

    compile_opt idl2, hidden

    void = {IDLitopMacroStepDisplayChange, $
            inherits IDLitOperation, $
            _displaySteps: 0b $
                        }
end

