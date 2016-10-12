; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrorecordstart__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroRecordStart
;
; PURPOSE:
;   This file implements the start recording macro operation for the IDL Tool system
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroRecordStart::Init
;   IDLitopMacroRecordStart::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroRecordStart::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroRecordStart object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRecordStart::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden

    success = self->IDLitOperation::Init(/SKIP_MACRO, _EXTRA=_extra);

    if (~success) then $
        return, 0

    self->RegisterProperty, 'MANIPULATOR_STEPS', /BOOLEAN, $
        DESCRIPTION='Record individual manipulator steps', $
        NAME='Record manipulator steps'

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1

end

;-------------------------------------------------------------------------
;; IDLitopMacroRecordStart::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroRecordStart object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroRecordStart::Cleanup
;   self->IDLitComponent::Cleanup
;end

;-------------------------------------------------------------------------
; IDLitopMacroRecordStart::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
pro IDLitopMacroRecordStart::GetProperty, $
    MANIPULATOR_STEPS=manipulatorSteps, $
    _REF_EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

    if (ARG_PRESENT(manipulatorSteps)) then $
        manipulatorSteps = self._manipulatorSteps

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
; IDLitopMacroRecordStart::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
pro IDLitopMacroRecordStart::SetProperty, $
    MANIPULATOR_STEPS=manipulatorSteps, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(manipulatorSteps) gt 0) then begin
        self._manipulatorSteps = manipulatorSteps
    endif

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
END

;;---------------------------------------------------------------------------
;; IDLitopMacroRecordStart::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRecordStart::DoAction, oTool
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Display dialog as a propertysheet
    IF self._bShowExecutionUI THEN BEGIN
      success = oTool->DoUIService('PropertySheet', self)
      IF success EQ 0 THEN $
        return,obj_new()
    ENDIF

    oSrvMacro = oTool->GetService('MACROS')
    oSrvMacro->SetProperty, MANIPULATOR_STEPS=self._manipulatorSteps

    oSrvMacro->StartRecording, oTool

    return,  obj_new()
end


;-------------------------------------------------------------------------
; Purpose:
;   Override our superclass method, because we don't key off types.
;
; Return Value:
;   This function returns a 1 if the object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function IDLitopMacroRecordStart::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Call a helper method in our superclass.
    return, self->IDLitOperation::_CurrentAvailability(oTool)

end


;-------------------------------------------------------------------------
pro IDLitopMacroRecordStart__define

    compile_opt idl2, hidden

    struc = {IDLitopMacroRecordStart, $
        inherits IDLitOperation, $
        _manipulatorSteps: 0b $
        }

end

