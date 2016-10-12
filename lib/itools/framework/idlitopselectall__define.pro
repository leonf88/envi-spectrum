; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopselectall__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSelectAll
;
; PURPOSE:
;   This file implements the operation that will select all visualizations
;   in the current windows current view.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopSelectAll::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopSelectAll::Init
;   IDLitopSelectAll::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopSelectAll::Init
;;
;; Purpose:
;; The constructor of the IDLitopSelectAll object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSelectAll::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    return, self->IDLitOperation::Init(NAME="Select All", $
                                       _EXTRA=_extra)

end

;-------------------------------------------------------------------------
;; IDLitopSelectAll::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopSelectAll object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopSelectAll::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopSelectAll::DoAction
;;
;; Purpose:
;;   Will cause All visualizations in the current view to be
;;   selected.
;;
;; Return Value:
;;   Since this is not transactional, a obj null is returned.
;;
function IDLitopSelectAll::DoAction, oTool
   compile_opt hidden, idl2

   ;; Make sure we have a tool.
   if not obj_valid(oTool) then $
      return, obj_new()
   ;; Get the Window
   oWin = oTool->GetCurrentWindow()
   if not obj_valid(oWin) then $
     return, obj_new()

  ;; Get the selected objects.
   oView = oWin->GetCurrentView()
   if(not obj_valid(oView))then return, obj_new()
   oLayers = oView->Get(/all, isa="IDLitgrLayer", count=nLayer)
   if(nLayer eq 0)then return, obj_new()
   nVis = 0
   ;; Disable tool updates during this process.
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
   for i=0, nLayer-1 do begin
       oDS = oLayers[i]->GetCurrentDataSpace()
       if(not obj_valid(oDS))then continue

       oTmp = oDS->GetVisualizations(count=count, /FULL_TREE)
       ;; Just select all items that were in the data space.
       if(count gt 0)then begin
           for j=0, count-1 do  $
               oTmp[j]->Select, /additive
       endif
       oTmp = oDS->GetAxes(count=count)
       if(count gt 0)then begin
           for j=0, count-1 do  $
               oTmp[j]->Select, /additive
       endif
       ;; only select the non annotatoin layer data space. Why? Thats
       ;; the way the drag box works.
       if(~obj_isa(oLayers[i], "IDLitgrAnnotateLayer"))then $
         oDS->select,/additive

   endfor

   IF (~previouslyDisabled) THEN $
     oTool->EnableUpdates ;; re-enable updates.
   ;; Send our notify
   return, obj_new()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopSelectAll__define

    compile_opt idl2, hidden

    void = {IDLitopSelectAll, $
            inherits IDLitOperation            }
end

