; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopbrowservis__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBrowserVis
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
;   See IDLitopBrowserVis::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopBrowserVis::Init
;;
;; Purpose:
;; The constructor of the IDLitopBrowserVis object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;function IDLitopBrowserVis::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;-------------------------------------------------------------------------
;; IDLitopBrowserVis::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopBrowserVis::GetProperty, $
    CURRENT_WINDOW=oWindow, $
    TOP=top, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(oWindow)) then $
        oWindow = self._oWindow

    if (arg_present(top)) then $
        top = self._oTop

     if(n_elements(_extra))then $
       self->IDLitOperation::GetProperty, _extra=_extra
end


;;---------------------------------------------------------------------------
;; IDLitopBrowserVis::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopBrowserVis::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the window to act upon and cache it.
    oWindow = oTool->GetCurrentWindow()
    self._oWindow = oWindow

    ; Get the vis container.
    self._oTop = oWindow

    success = oTool->DoUIService('BrowserVis', self)
    if not success then return, obj_new()

    return, obj_new()
end

;-------------------------------------------------------------------------
pro IDLitopBrowserVis__define

    compile_opt idl2, hidden

    struc = {IDLitopBrowserVis,     $
        inherits IDLitOperation, $
        _oWindow: OBJ_NEW(), $
        _oTop: OBJ_NEW() $
    }
end

