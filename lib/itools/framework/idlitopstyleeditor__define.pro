; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopstyleeditor__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopStyleEditor
;
; PURPOSE:
;   This file implements the IDL Tool object that
;   implements the actions performed when the Style Editor is opened.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopStyleEditor::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopStyleEditor::Init
;
; Purpose:
; The constructor of the IDLitopStyleEditor object.
;
; Parameters:
; None.
;
;function IDLitopStyleEditor::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;---------------------------------------------------------------------------
; IDLitopStyleEditor::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopStyleEditor::DoAction, oTool

    compile_opt idl2, hidden

    oSys = oTool->_GetSystem()
    oService = oSys->GetService('STYLES')
    if (~Obj_Valid(oService)) then return, Obj_New()
    oService->VerifyStyles
    success = oTool->DoUIService('/StyleEditor', self)
    return, obj_new()

end


;-------------------------------------------------------------------------
pro IDLitopStyleEditor__define

    compile_opt idl2, hidden

    struc = {IDLitopStyleEditor,     $
             inherits IDLitOperation }
end

