; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfileexit__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopFileExit
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a property sheet is used.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopFileExit::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopFileExit::Init
;   IDLitopFileExit::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopFileExit::Init
;;
;; Purpose:
;; The constructor of the IDLitopFileExit object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopFileExit::Init, _extra=_extra
    compile_opt hidden, idl2

    return, self->IDLitOperation::Init(_extra=_extra)
end

;;---------------------------------------------------------------------------
;; IDLitopFileExit::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopFileExit::DoAction, oTool
    compile_opt hidden, idl2
    oShutdown = oTool->GetService("SHUTDOWN")

    oSrvMacro = oTool->GetService('MACROS')
    if OBJ_VALID(oSrvMacro) then begin
        ; need to explicitly add this operation since after shutdown
        ; the tool is invalid
        oSrvMacro->GetProperty, CURRENT_NAME=currentName
        oSrvMacro->PasteMacroOperation, self, currentName
    endif

    if(~obj_valid(oShutdown))then begin
        oTool->ErrorMessage, title=IDLitLangCatQuery('Error:InternalError:Title'), $
      [ IDLitLangCatQuery('Error:Framework:CannotAccessShutdown'), $
      IDLitLangCatQuery('Error:Framework:ForceShutdown')], severity=2
        obj_destroy,self
        return,obj_new()
    endif
    return, oTool->DoAction(oShutdown->GetFullIdentifier())

end


;;-------------------------------------------------------------------------
;; Definition
pro IDLitopFileExit__define
    compile_opt hidden, idl2
    struc = {IDLitopFileExit, inherits IDLitOperation}

end

