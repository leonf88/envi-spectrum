; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowseroperation__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBrowserOperation
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
;   See IDLitopBrowserOperation::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopBrowserOperation::Init
;   IDLitopBrowserOperation::GetProperty
;   IDLitopBrowserOperation::SetProperty
;   IDLitopBrowserOperation::DoAction
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopBrowserOperation::Init
;;
;; Purpose:
;; The constructor of the IDLitopBrowserOperation object.
;;
;; Parameters:
;; None.
;;
;;---------------------------------------------------------------------------
;; IDLitopBrowserPrefs::Init
;;
;; Purpose:
;;   Init method for this op
function IDLitopBrowserOperation::Init, _REF_EXTRA=_extra

    compile_opt hidden, idl2

    if ~self->IDLitOperation::Init(_EXTRA=_extra) then $
        return, 0

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopBrowserOperation::GetPropeerty
;;
;; Purpose:
;;   Used to provide the identifier that the browser should use.
;;
pro IDLitopBrowserOperation::GetProperty, Target=target, _ref_extra=_extra
     compile_opt hidden, idl2

     if(arg_present(target))then $
       target="operations/operations"
     if(n_elements(_extra))then $
       self->IDLitOperation::GetProperty, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitopBrowserOperation::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopBrowserOperation::DoAction, oTool

    compile_opt idl2, hidden

    success = oTool->DoUIService('Browser', self)
    return, obj_new()
end

;-------------------------------------------------------------------------
pro IDLitopBrowserOperation__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserOperation,     $
             inherits IDLitOperation}
end

