; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitcontainer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitContainer
;
; PURPOSE:
;   This file implements the IDLitContainer class. This class provides
;   a container that is aware of identifiers and uses these ids to find
;   and traverse the contents of the containment tree.
;
;   This traversal is all built off of the identifier property provided by
;   the IDLitComponent object.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDL_Container
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitContainer::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitContainer::Init
;   IDLitContainer::Cleanup
;
; INTERFACES:
; IIDLProperty
; IIDLContainer
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitContainer::Init
;;
;; Purpose:
;; The constructor of the IDLitContainer object.
;;
;; Parameter

function IDLitContainer::Init, _EXTRA=_extra
   ;; Pragmas
   compile_opt idl2, hidden

   if(self->IDLitComponent::Init(_EXTRA=_extra) eq 0)then $
     return, 0

   if(self->IDL_Container::Init() eq 0)then begin
       self->IDLitComponent::Cleanup
       return, 0
   end
   if(self->_IDLitContainer::Init() eq 0)then begin
       self->IDLitComponent::Cleanup
       self->IDL_Container::Cleanup
       return, 0
   endif
   return, 1

end
;;---------------------------------------------------------------------------
;; IDLitContainer::Cleanup
;;
;; Purpose:
;;    Destructor for the object.
;;

pro IDLitContainer::Cleanup
   ;; Pragmas
   compile_opt idl2, hidden

   self->_IdlitContainer::Cleanup

   self->IDL_Container::Cleanup

   self->IDLitComponent::Cleanup

end


;-------------------------------------------------------------------------
; IDLitContainer::QueryAvailability
;
; Purpose:
;   This function method determines whether this container is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if this container is applicable for the
;   selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None.
;
function IDLitContainer::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    return, 1

end


;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitContainer__Define
;;
;; Purpose:
;; Class definition of the object
;;
pro IDLitContainer__Define
   ;; Pragmas
   compile_opt idl2, hidden

   void = {IDLitContainer,  $
           inherits   IDLitComponent, $
           inherits   _IDLitContainer, $
           inherits   IDL_Container }
end



