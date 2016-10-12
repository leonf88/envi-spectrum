; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitregclass__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitRegClass
;
; PURPOSE:
;   This file implements the IDLitRegClass class. This class provides
;   a method to register class based item information.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitObjDescTool
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitRegClass::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitRegClass::Init
;   IDLitRegClass::Cleanup
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitRegClass::Init
;;
;; Purpose:
;; The constructor of the IDLitObjDesc object.
;;
;; Parameters:
;;   strName     - The name for this item
;;
;;   strClass    - The classname of the item
;;
;; Keywords:
;;   IDENTIFIER  - The identifier for this class. This can be a full path
;;
;;   All other keywords are passed to IDLitObjDescTool
;;
function IDLitRegClass::Init, strName, strClass, $
                      FINAL_IDENTIFIER=identifier, $
                       _EXTRA=_extra
  ;; Pragmas
  compile_opt idl2, hidden

  if(self->IDLitObjDescTool::Init(CLASSNAME=strClass, $
      _EXTRA=_extra, name=strName) eq 0)then $
    return, 0

  self._localident=(keyword_set(identifier) ? identifier : strName)
  return, 1
end
;;---------------------------------------------------------------------------
;; Property Interface
;;---------------------------------------------------------------------------
;; IDLitRegClass::GetProperty
;;
;; Purpose:
;;   This procedure method retrieves the value of a property or group of
;;   properties associated with this object.
;;
;; Keywords:
;;   IDENTIFIER  - identifier 
;;
;;   CLASSNAME - The class associated with this item.
;;
;;   All other items are passed to the superclass

pro IDLitRegClass::GetProperty, FINAL_IDENTIFIER=IDENTIFIER, $
                  _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(identifier) ne 0) then $
      identifier=self._localident

    ; Call superclass.
    self->IDLitObjDescTool::GetProperty, _EXTRA=_extra
end
;; No set property, since these are init only.

;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; IDLitRegClass__Define
;;
;; Purpose:
;; Class definition for the Registry Routine entry class
;;

pro IDLitRegClass__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitRegClass, $
          inherits   IDLitObjDescTool, $
          _localident   : ''  $        ;; saved identifier
         }

end
