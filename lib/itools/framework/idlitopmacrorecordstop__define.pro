; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrorecordstop__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroRecordStop
;
; PURPOSE:
;   This file implements the stop recording macro operation for the IDL Tool system
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
;   IDLitopMacroRecordStop::Init
;   IDLitopMacroRecordStop::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroRecordStop::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroRecordStop object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRecordStop::Init, _REF_EXTRA=_extra
   compile_opt idl2, hidden

    ; set to dummy type to desensitize on init
    ; the start operation will sensitize when needed
    success = self->IDLitOperation::Init(TYPES="FLOOB", _EXTRA=_extra);

    if (~success) then $
        return, 0

    return, 1

end

;-------------------------------------------------------------------------
;; IDLitopMacroRecordStop::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroRecordStop object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroRecordStop::Cleanup
;   self->IDLitComponent::Cleanup
;end

;-------------------------------------------------------------------------
;; IDLitopMacroRecordStop::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopMacroRecordStop::GetProperty, $
    _REF_EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroRecordStop::SetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopMacroRecordStop::SetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
END

;;---------------------------------------------------------------------------
;; IDLitopMacroRecordStop::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroRecordStop::DoAction, oTool
    ;; Pragmas
    compile_opt idl2, hidden

    ; make sure the default manipulator is current if we
    ; are stopping a macro recording.  this has the
    ; necessary side effect of committing an annotation
    ; if the the annotation was created but not yet committed
    ; prior to a menu selection or button click.
    oTool->ActivateManipulator, /DEFAULT

    oSrvMacro = oTool->GetService('MACROS')
    oSrvMacro->StopRecording, oTool

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
function IDLitopMacroRecordStop::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Call a helper method in our superclass.
    return, self->IDLitOperation::_CurrentAvailability(oTool)

end


;-------------------------------------------------------------------------
pro IDLitopMacroRecordStop__define

    compile_opt idl2, hidden

    struc = {IDLitopMacroRecordStop, $
        inherits IDLitOperation $
        }

end

