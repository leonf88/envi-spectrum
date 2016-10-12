; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipannotation__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipAnnotation
;
; PURPOSE:
;   Abstract class for the manipulator system of the IDL component framework.
;   Indentend to manage the goemetry of an annoation
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulator
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipAnnotation::Init
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipAnnotation::Init
;
; PURPOSE:
;       The IDLitManipAnnotation::Init function method initializes the
;       annotation manipulator.
;
; CALLING SEQUENCE:
;       oData = OBJ_NEW('IDLitManipAnnotation')
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
function IDLitManipAnnotation::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status = self->IDLitManipulator::Init(_EXTRA=_extra, $
        VISUAL_TYPE='Select', $
        OPERATION_IDENTIFIER="ANNOTATION")
    if (status eq 0) then return, 0

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitManipAnnotation
;;
;; Purpose:
;;   Used to commit an annotation with the the tool
;;
;; Arguments:
;;  oAnnotation   - The annotation objects to record for the
;;                  transaction.

PRO IDLitManipAnnotation::CommitAnnotation, oAnnotation

    compile_opt hidden, idl2

    if(not obj_valid(oAnnotation))then return
    *self.pSelectionList = oAnnotation
    self.nSelectionList = N_ELEMENTS(oAnnotation)
    if (~OBJ_VALID(self._oCmdSet)) then $
        void = self->RecordUndoValues()
    void = self->CommitUndoValues()
    oAnnotation->Select,1, /SKIP_MACRO
    oTool = self->getTool()
    ;; If the current manipulator equals self, then
    ;; switch to arrow mode. This check will prevent any
    ;; un-neccisary mode switches that could cause visual display
    ;; (ie toolbar) to get out of sync.
    if(oTool->GetCurrentManipulator() eq self) then $
        oTool->ActivateManipulator, /DEFAULT
end


;---------------------------------------------------------------------------
; IDLitManipAnnotation::CancelAnnotation
;
; Purpose:
;   Used to cancel an annotation with the tool
;
PRO IDLitManipAnnotation::CancelAnnotation
    compile_opt hidden, idl2

    void = self->CommitUndoValues(/UNCOMMIT)
    oTool = self->GetTool()
    oTool->ActivateManipulator, /DEFAULT

end

;---------------------------------------------------------------------------
; IDLitManipAnnotation__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitManipAnnotation__Define
    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitManipAnnotation,      $
            inherits IDLitManipulator $
        }

end
