; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopsetascurrenttool__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSetAsCurrentTool
;
; PURPOSE:
;   This file implements the SetAsCurrentTool service. When exectued,
;   the tool this operation belongs to will be set as current in the
;   system.
;
;   This operation is primarly intended to be a service, allowing UI
;   to have the tool be set as current when a tool is placed in focus.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopSetAsCurrentTool
;
; INTERFACES:
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopSetAsCurrentTool::Init
;;
;; Purpose:
;; The constructor of the IDLitopSetAsCurrentTool Operation
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSetAsCurrentTool::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end
;;---------------------------------------------------------------------------
function IDLitopSetAsCurrentTool::DoAction, oTool
   compile_opt hidden, idl2

   ;; Basically set this tool as the current in the system.
   oSystem = oTool->_GetSystem()

   oldToolID = oSystem->GetCurrentTool()
   oldTool = oSystem->GetByIdentifier(oldToolID)
   if ~obj_valid(oldTool) || oTool ne oldTool then begin
       ; add tool change operation to macro
       dummy=0
       oSrvMacro = oTool->GetService('MACROS')
       if OBJ_VALID(oSrvMacro) then begin
           oSrvMacro->AddToolChange, oTool
       endif
   endif

   if(obj_valid(oSystem))then $
     oSystem->_SetCurrentTool, oTool

   return, obj_new()

end
;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitopSetAsCurrentTool__define

    compile_opt idl2, hidden

    struc = {IDLitopSetAsCurrentTool,       $
             inherits IDLitOperation $
            }
end

