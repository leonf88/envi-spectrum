; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacroeditor__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroEditor
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when an object browser is opened.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroEditor::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopMacroEditor::Init
;
; Purpose:
; The constructor of the IDLitopMacroEditor object.
;
; Parameters:
; None.
;
;function IDLitopMacroEditor::Init, _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    if ~self->IDLitOperation::Init(_EXTRA=_extra) then $
;        return, 0
;
;    return, 1
;
;end


;-------------------------------------------------------------------------
; IDLitopMacroEditor::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroEditor::GetProperty, TARGET=target, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(target)) then begin
        oTool = self->GetTool()
        target = OBJ_VALID(oTool) ? oTool->GetFullIdentifier() : ''
    endif

    if (N_ELEMENTS(_extra)) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitopMacroEditor::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopMacroEditor::DoAction, oTool

    compile_opt idl2, hidden

    success = oTool->DoUIService('/MacroEditor', self)
    return, obj_new()

end


;-------------------------------------------------------------------------
pro IDLitopMacroEditor__define

    compile_opt idl2, hidden

    struc = {IDLitopMacroEditor,     $
             inherits IDLitOperation }
end

