; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowsertool__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBrowserTool
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
;   See IDLitopBrowserTool::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopBrowserTool::Init
;
; Purpose:
; The constructor of the IDLitopBrowserTool object.
;
; Parameters:
; None.
;
;function IDLitopBrowserTool::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;-------------------------------------------------------------------------
; IDLitopBrowserTool::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopBrowserTool::GetProperty, TARGET=target, $
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
; IDLitopBrowserTool::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopBrowserTool::DoAction, oTool

    compile_opt idl2, hidden

    success = oTool->DoUIService('Browser', self)
    return, obj_new()

end


;-------------------------------------------------------------------------
pro IDLitopBrowserTool__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserTool,     $
             inherits IDLitOperation }
end

