; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitregtarget__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitRegTarget
;
; PURPOSE:
;   This file implements the IDLitRegTarget class. This class provides
;   a method to register target-based item information.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitRegTarget::Init
;
; Purpose:
;   This function method initializes the IDLitRegTarget object.
;
; Parameters:
;   strName      - The name for this item
;
;   strTargetId  - The identifier for the target.
;
; Keywords:
;   IDENTIFIER  - The identifier for this object. This can be a full path
;
function IDLitRegTarget::Init, strName, strTargetId, $
    IDENTIFIER=identifier, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitComponent::Init(IDENTIFIER=identifier, $
        NAME=strName, $
        _EXTRA=_extra) eq 0) then $
        return, 0

    self._targetId = strTargetId

    return, 1
end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
; IDLitRegTarget::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties associated with this object.
;
; Keywords:
;   TARGET_IDENTIFIER  - identifier of target
;
;   All other items are passed to the superclass.

pro IDLitRegTarget::GetProperty, TARGET_IDENTIFIER=targetID, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(targetId) ne 0) then $
        targetId = self._targetId

    ; Call superclass.
    self->IDLitComponent::GetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; Object Class Defintion
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitRegTarget__Define
;
; Purpose:
;   Defines the object structure for the IDLitRegTarget object class.
;
pro IDLitRegTarget__Define
    compile_opt idl2, hidden

    void = { IDLitRegTarget, $
        inherits IDLitComponent, $
        _targetId: ''            $ ; Identifier of target
    }
end
