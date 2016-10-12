; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitregproxy__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; PROXY_NAME:
;   IDLitRegProxy
;
; PURPOSE:
;   This file implements the IDLitRegProxy class. This class provides
;   a method to register proxy-based item information.
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitRegProxy::Init
;
; Purpose:
;   This function method initializes the IDLitRegProxy object.
;
; Parameters:
;   strName     - The name for this item
;
;   idProxy    - The identifier of the proxied item.
;
; Keywords:
;   IDENTIFIER  - The identifier for the registered item.
;
;   All other keywords are passed to IDLitObjDescTool
;
function IDLitRegProxy::Init, strName, oEnv, idProxy, $
                      FINAL_IDENTIFIER=identifier, $
                       _EXTRA=_extra
    compile_opt idl2, hidden

    if (self->IDLitObjDescProxy::Init(oEnv, idProxy, $
        NAME=strName, _EXTRA=_extra) eq 0) then $
        return, 0

    self._localident=(KEYWORD_SET(identifier) ? identifier : strName)

    return, 1
end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
; IDLitRegProxy::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties associated with this object.
;
; Keywords:
;   FINAL_IDENTIFIER  - identifier 
;
;   All other items are passed to the superclass.
;
pro IDLitRegProxy::GetProperty, $
    FINAL_IDENTIFIER=identifier, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(identifier) ne 0) then $
        identifier=self._localident

    ; Call superclass.
    self->IDLitObjDescProxy::GetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; Object Class Defintion
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitRegProxy__Define
;
; Purpose:
;   Defines the object structure for the IDLitRegProxy object class.
;
pro IDLitRegProxy__Define
    compile_opt idl2, hidden

    void = {IDLitRegProxy, $
        inherits   IDLitObjDescProxy, $
        _localident   : ''  $        ;; saved identifier
    }

end
