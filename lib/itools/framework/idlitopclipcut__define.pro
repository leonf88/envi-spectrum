; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopclipcut__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitClipCut
;
; PURPOSE:
;   This file implements the operation that will cut the currently
;   selected items to the local clipboard.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitClipCut::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitClipCut::Init
;   IDLitClipCut::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitClipCut::Init
;;
;; Purpose:
;; The constructor of the IDLitClipCut object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopClipCut::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    return, self->IDLitOperation::Init(TYPES="VISUALIZATION",_EXTRA=_extra)

end

;-------------------------------------------------------------------------
;; IDLitClipCut::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitClipCut object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitClipCut::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitClipCut::DoAction
;;
;; Purpose:
;;   Will cause the currently selected items to be cut to the
;;   local clipboard of the system.
;;
;; Return Value:
;;  The command objects from the delete operation.
;;
function IDLitopClipCut::DoAction, oTool
   compile_opt hidden, idl2

   ;; Make sure we have a tool.
   if not obj_valid(oTool) then $
      return, obj_new()

   oCopyDesc = oTool->GetByIdentifier("/REGISTRY/OPERATIONS/COPY")
   if(not obj_valid(oCopyDesc))then return, obj_new()

   ;; Get the delete operation
   oDeleteDesc = oTool->GetByIdentifier("/REGISTRY/OPERATIONS/DELETE")
   if(not obj_valid(oDeleteDesc))then return, obj_new()

   oCp = oCopyDesc->GetObjectInstance()
   ;; Copy and then delete
   void = oCp->DoAction(oTool)
   oCopyDesc->ReturnObjectInstance, oCp

   oDel = oDeleteDesc->GetObjectInstance()
   oCmds = oDel->DoAction(oTool)
   oDeleteDesc->ReturnObjectInstance, oDel
   if (~OBJ_VALID(oCmds[0])) then $
    return, OBJ_NEW()
   oCmds[0]->SetProperty, NAME='Cut'
   return,oCmds

end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitOPClipCut__define

    compile_opt idl2, hidden

    struc = {IDLitopClipCut,       $
             inherits IDLitOperation            }
end

