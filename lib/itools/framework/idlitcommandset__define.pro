; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitcommandset__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitCommandSet
;
; PURPOSE:
;   This file defines and implements the generic IDL tool command
;   object which is used to manage and store undo-redo
;   information. This object is primarly abstract, defining the
;   interfaces and workflow used in the tool command system.
;
;   For each action that is to be placed in the command system, a
;   specialized version of this object is needed. This is neccessary
;   so that the information/state that is needed for the particular
;   action is properly stored.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;   IDLitCommand
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitCommandSet::Init
;
; METHODS:
;
; INTERFACES:
; IIDLProperty
; IDL_Container
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitCommandSet::Init
;;
;; Purpose:
;;   Constructor for this object.
;;
;; Keywords:
;;   All keywords are pass to it's superclass, IDLitCommand 
;;
function IDLitCommandSet::Init, _Extra=_super
   ;; Pragmas
   compile_opt idl2, hidden

   iStatus = self->IDLitCommand::Init(_extra=_super)

   if(iStatus eq 0)then $
      return, 0

   return, self->IDL_Container::Init()
end

;;---------------------------------------------------------------------------
;; IDLitCommandSet::Cleanup
;;
;; Purpose:
;;   Destructor for this class.
;;
pro IDLitCommandSet::Cleanup
   ;; Pragmas
   compile_opt idl2, hidden

    self->IDLitCommand::Cleanup
    self->IDL_Container::Cleanup
end

;;
;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;; IDLitCommandSet::Add
;;
;; Purpose:
;;   Override the container add command, only placing new items at the
;;   end of the command list.
;;
;; Parameter
;;   oObjects - The objects to add to this command set. These objects
;;              must be a IDLitcommand
;;

pro IDLitCommandSet::Add, oObjects
   ;; Pragmas
   compile_opt idl2, hidden

   idx = where(obj_isa(oObjects, "IDLitCommand"), cnt)
   if(cnt eq 0)then return

   self->IDL_Container::Add, oObjects[idx] ;easy.

end
;;---------------------------------------------------------------------------
;; IDLitCommandSet::GetSize
;;
;; Purpose:
;;   Returns the approximate size of the data that is contained in
;;   this command set. Returns bytes by default
;;
;; Keywords:
;;   KILOBYTES    - If set, the value in kilobytes

function IDLitCommandSet::GetSize, KILOBYTES=KILOBYTES
    compile_opt hidden, idl2

    oItems = self->IDL_Container::Get(/all, COUNT=nItems)
    nBytes =0.
    for i=0, nItems-1 do $
      nBytes += oItems[i]->GetSize()

    if(keyword_set(KILOBYTES))then $
      nBytes = ceil(float(nBytes)/1000., /L64)

    return, nBytes
end
;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitCommandSet__define
;;
;; Purpose:
;;  This routine is used to define the command set object class.
;;
pro IDLitCommandSet__define
   ;; Pragmas
   compile_opt idl2, hidden

   void = {IDLitCommandSet, $
           inherits IDLitCommand, $
           inherits IDL_Container $
          }                     ;not much too this component.

end
