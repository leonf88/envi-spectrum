; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrostepdelaychange__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroStepDelayChange
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
;   See IDLitopMacroStepDelayChange::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroStepDelayChange::Init
;   IDLitopMacroStepDelayChange::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroStepDelayChange::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroStepDelayChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroStepDelayChange::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Macro Step Delay Change", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'MODE', $
        NAME='Delay mode', $
        ENUMLIST=['Use specified delay', 'Use macro folder delay'], $
        DESCRIPTION='Delay Mode'

    self->RegisterProperty, 'STEP_DELAY', /FLOAT, $
        NAME='Step delay (seconds)', $
        DESCRIPTION='Step delay between macro steps (in seconds)', $
        VALID_RANGE=[0.D, 60.D, 0.01D]

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroStepDelayChange::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroStepDelayChange::GetProperty, $
    MODE=mode,   $
    STEP_DELAY=stepDelay, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(mode)) then $
        mode = self._mode

    if (arg_present(stepDelay)) then $
        stepDelay = self._stepDelay

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroStepDelayChange::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroStepDelayChange::SetProperty,      $
    MODE=mode,   $
    STEP_DELAY=stepDelay, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(mode) ne 0) then begin
        self._mode = mode
        self->SetPropertyAttribute, $
            'STEP_DELAY', SENSITIVE=~mode
    endif

    if (N_ELEMENTS(stepDelay) ne 0) then begin
        self._stepDelay = stepDelay
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroStepDelayChange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroStepDelayChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroStepDelayChange::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroStepDelayChange::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroStepDelayChange::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    oSrvMacro = oTool->GetService('MACROS')
    if ~obj_valid(oSrvMacro) then return, obj_new()

    if self._mode eq 0 then begin
        ; use specified delay value
        stepDelay = self._stepDelay
    endif else begin
        ; use macro folder default
        ; retrieve step delay value from macro
        oSrvMacro->GetProperty, $
            CURRENT_MACRO_ID=currentMacroID
        oMacro = oTool->GetByIdentifier(currentMacroID)
        if ~obj_valid(oMacro) then return, obj_new()
        oMacro->GetProperty, STEP_DELAY=stepDelay
    endelse
    oSrvMacro->SetProperty, STEP_DELAY=stepDelay

    oCmdSet = obj_new("IDLitCommandSet", NAME='Macro Step Delay Change', $
                            OPERATION_IDENTIFIER= $
                            self->getFullIdentifier())


    return, oCmdSet
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroStepDelayChange__define

    compile_opt idl2, hidden

    void = {IDLitopMacroStepDelayChange, $
            inherits IDLitOperation, $
            _mode: 0b, $
            _stepDelay: 0.0D      $
                        }
end

