; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowserdata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBrowserData
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
;   See IDLitopBrowserData::Init
;
;-


;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopBrowserData::Init
;
; Purpose:
; The constructor of the IDLitopBrowserData object.
;
; Parameters:
; None.
;
;function IDLitopBrowserData::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;-------------------------------------------------------------------------
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopBrowserData::GetProperty, TARGET=target, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(target)) then $
        target = '/DATA MANAGER'

    if (N_ELEMENTS(_extra)) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Purpose:
;
; Parameters:
; None.
;
function IDLitopBrowserData::DoAction, oTool

    compile_opt idl2, hidden

    success = oTool->DoUIService('Browser', self)
    return, obj_new()

end


;-------------------------------------------------------------------------
pro IDLitopBrowserData__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserData,     $
             inherits IDLitOperation }
end

