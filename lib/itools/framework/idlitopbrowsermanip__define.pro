; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowsermanip__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBrowserManip
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
;   See IDLitopBrowserManip::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopBrowserManip::Init
;
; Purpose:
; The constructor of the IDLitopBrowserManip object.
;
; Parameters:
; None.
;
;function IDLitopBrowserManip::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;-------------------------------------------------------------------------
; IDLitopBrowserManip::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopBrowserManip::GetProperty, TARGET=target, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(target)) then $
        target="MANIPULATORS"

    if (N_ELEMENTS(_extra)) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitopBrowserManip::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
function IDLitopBrowserManip::DoAction, oTool

    compile_opt idl2, hidden

    success = oTool->DoUIService('Browser', self)
    return, obj_new()

end


;-------------------------------------------------------------------------
pro IDLitopBrowserManip__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserManip,     $
             inherits IDLitOperation }
end

