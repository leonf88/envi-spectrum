; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitregroutine__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitRegRoutine
;
; PURPOSE:
;   This file implements the IDLitRegRoutine class. This class provides
;   a method to register simple routines in a object registry.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitRegRoutine::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitRegRoutine::Init
;   IDLitRegRoutine::Cleanup
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitRegRoutine::Init
;;
;; Purpose:
;; The constructor of the IDLitObjDesc object.
;;
;; Parameters:
;;   Name        - The name for this item
;;
;;   strRoutine  - The name of the routine associated with this object
;;
;; Keywords:
;;   TYPES     - Types associated with this component
;;
;;   All other keywords are passed to IDLitComponent
;;
function IDLitRegRoutine::Init, strName, strRoutine, $
                        TYPES=TYPES
                       _EXTRA=_extra

  ;; Pragmas
  compile_opt idl2, hidden

  if(self->IDLitComponent::Init(_EXTRA=_extra, name=strName) eq 0)then $
    return, 0

  self._types = ptr_new((keyword_set(types) ? strupcase(types) : ''))

  self._Routine = strRoutine

  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitRegRoutine::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro IDLitRegRoutine::Cleanup
  ;; Pragmas
  compile_opt idl2, hidden

  ptr_free, self._types
  self->IDLitComponent::Cleanup

end

;;---------------------------------------------------------------------------
;; Property Interface
;;---------------------------------------------------------------------------
;; IDLitRegRoutine::GetProperty
;;
;; Purpose:
;;   This procedure method retrieves the value of a property or group of
;;   properties associated with this object.
;;
;; Keywords:
;;   NAME    - The name of this item
;;
;;   TYPES   - The types supported by this object.
;;
;;   ROUTINE - The routine associated with this item.
;;
;;   All other items are passed to the superclass

pro IDLitRegRoutine::GetProperty, TYPES=TYPES, ROUTINE=ROUTINE, $
                  _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(TYPES) ne 0) then $
        types = *self._types

    if(arg_present(routine) ne 0)then $
      routine=self._routine

    ; Call superclass.
    self->IDLitComponent::GetProperty, _EXTRA=_extra
end
;; No set property, since these are init only.

;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; IDLitRegRoutine__Define
;;
;; Purpose:
;; Class definition for the Registry Routine entry class
;;

pro IDLitRegRoutine__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitRegRoutine, $
          inherits   IDLitComponent,    $
          _Routine        : '', $        ;; The routine
          _types          : ptr_new() $ ;; associated types
         }

end
