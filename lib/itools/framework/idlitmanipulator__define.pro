; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipulator__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipulator
;
; PURPOSE:
;   Abstract class for the manipulator system of the IDL component framework.
;   The class will not be created directly, but defines the basic
;   structure for the manipulator system.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitComponent
;   _IDLitManipulator
;
; CREATION:
;   See IDLitManipulator::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipulator::Init
;   IDLitManipulator::Cleanup
;   IDLitManipulator::
;
;-

;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitManipulator::Init
;;
;; Purpose:
;;  The constructor of the manipulator object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   IDENTIFIER    - Provided by IDLitComponent. Used as the type of
;;                   the manipulator.
;;

function IDLitManipulator::Init, NAME=name, TOOL=TOOL, $
                         _REF_EXTRA=_super
   ;; pragmas
   compile_opt idl2, hidden

   ;; Init our superclass
   iStatus = self->IDLitComponent::Init(_EXTRA=_super, $
    NAME=(N_ELEMENTS(name) eq 0) ? 'Manipulator' : name)
   if(iStatus eq 0)then $
      return, 0

   return, self->_IDLitManipulator::Init(TOOL=TOOL, _EXTRA=_super)

end

;;--------------------------------------------------------------------------
;; IDLitManipulator::Cleanup
;;
;; Purpose:
;;  The destructor of the component.
;;

pro IDLitManipulator::Cleanup

   ;; pragmas
   compile_opt idl2, hidden

   self->_IDLitManipulator::Cleanup
   self->IDLitComponent::Cleanup

end

;;---------------------------------------------------------------------------
;; Properties
;;---------------------------------------------------------------------------
;; IDLitManipulator::GetProperty
;;
;; Purpose:
;;    Used to get IDLitManipulator specific properties.
;;
;; Arguments:
;;  None
;;
;; Keywords:
;;    Everything is passed up to our superclasses

pro IDLitManipulator::GetProperty, _REF_EXTRA=_SUPER
   ;; pragmas
   compile_opt idl2, hidden

   ;; If we have "extra" properties, pass them up the chain.
   if( n_elements(_SUPER) gt 0)then begin
       self->IDLitComponent::GetProperty, _EXTRA=_SUPER
       self->_IDLitManipulator::GetProperty, _EXTRA=_SUPER
   endif
end
;;---------------------------------------------------------------------------
;; IDLitManipulator::SetProperty
;;
;; Purpose:
;;    Used to set IDLitManipulator specific properties.
;;
;; Arguments:
;;  None
;;
;; Keywords:
;;    Everything is passed down to our superclasses

pro IDLitManipulator::SetProperty, _EXTRA=_SUPER
   ;; pragmas
   compile_opt idl2, hidden

   if(n_elements(_SUPER) gt 0)then begin
       self->_IDLitManipulator::SetProperty, _EXTRA=_SUPER
       self->IDLitComponent::SetProperty, _EXTRA=_SUPER
   endif

end
;;---------------------------------------------------------------------------
;; IDLitManipulator::Define
;;
;; Purpose:
;;   Define the base object for the manipulator
;;

pro IDLitManipulator__Define
   ;; pragmas
   compile_opt idl2, hidden

   ;; Just define this bad boy.
   void = {IDLitManipulator, $
           inherits IDLitComponent,       $ ;; I AM A COMPONENT
           inherits _IDLitManipulator    $ ;; provides core manipulator functionality.
      }

end
