; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopredo__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRedo
;
; PURPOSE:
;   This file implements the redo operation for the IDL Tool system
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
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopRedo::Init
;;
;; Purpose:
;; The constructor of the IDLitopRedo object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;function IDLitopRedo::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end

;-------------------------------------------------------------------------
;; IDLitopRedo::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopRedo object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopRedo::Cleanup
;    self->IDLitComponent::Cleanup
;end

;;---------------------------------------------------------------------------
;; IDLitopRedo::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopRedo::DoAction, oTool
   ;; Pragmas
   compile_opt idl2, hidden

   ;; Ok, get the current command set from the tools undo buffer.
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
   iStatus = oTool->_DoRedoCommand()
   IF (~previouslyDisabled) THEN $
     oTool->EnableUpdates
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
function IDLitopRedo::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Call a helper method in our superclass.
    return, self->IDLitOperation::_CurrentAvailability(oTool)

end


;-------------------------------------------------------------------------
pro IDLitopRedo__define
   compile_opt idl2, hidden
    ;; This needs to Change. Need a base tool level operation
    ;; class.
    struc = {IDLitopRedo, inherits IDLitOperation}

end

