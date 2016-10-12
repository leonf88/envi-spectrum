; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowserprefs__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitBrowserPrefs
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
;   See IDLitBrowserPrefs::Init
;
;-
;;---------------------------------------------------------------------------
;; IDLitopBrowserPrefs::Init
;;
;; Purpose:
;;   Init method for this op
;function IDLitopBrowserPrefs::init, _REF_EXTRA=_extra
;    compile_opt hidden, idl2
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;;---------------------------------------------------------------------------
;; IDLitopBrowserPrefs::GetPropeerty
;;
;; Purpose:
;;   Used to provide the identifier that the browser should use.
;;
pro IDLitopBrowserPrefs::GetProperty, Target=target, _ref_extra=_extra
     compile_opt hidden, idl2
     if(arg_present(target))then $
       target="/registry/Settings"
     if(n_elements(_extra))then $
       self->IDLitOperation::GetProperty, _extra=_extra

end


;;---------------------------------------------------------------------------
;; IDLitBrowserPrefs::DoAction
;;
;; Purpose:
;;   Just call the ui service
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopBrowserPrefs::DoAction, oTool

    compile_opt idl2, hidden

    oGeneral = oTool->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
    if (OBJ_VALID(oGeneral)) then oGeneral->VerifySettings

    success = oTool->DoUIService('/Preferences', self)
    return, obj_new()
end


;-------------------------------------------------------------------------
pro IDLitopBrowserPrefs__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserPrefs,     $
             inherits IDLitOperation}
end

