; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrodelay__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroDelay
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
;   See IDLitopMacroDelay::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroDelay::Init
;   IDLitopMacroDelay::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroDelay::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroDelay object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroDelay::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Macro Delay", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'DELAY', /FLOAT, $
        NAME='Delay (seconds)', $
        DESCRIPTION='Delay (in seconds)'

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroDelay::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroDelay::GetProperty, $
    DELAY=delay, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(delay)) then $
        delay = self._delay

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroDelay::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroDelay::SetProperty,      $
    DELAY=delay, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(delay) ne 0) then begin
        ; enforce minimum of 0
        self._delay = 0 > delay
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroDelay::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroDelay object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroDelay::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroDelay::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroDelay::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    WAIT, ABS(self._delay)

    oCmdSet = obj_new("IDLitCommandSet", NAME='Macro Delay', $
                            OPERATION_IDENTIFIER= $
                            self->getFullIdentifier())


    return, oCmdSet
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroDelay__define

    compile_opt idl2, hidden

    void = {IDLitopMacroDelay, $
            inherits IDLitOperation, $
            _delay: 0D      $
                        }
end

