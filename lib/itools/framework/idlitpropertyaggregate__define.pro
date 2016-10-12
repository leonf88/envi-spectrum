; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitpropertyaggregate__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This class represents an IDLitComponent that can also aggregate the
;   properties of other objects.

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the component object.
;
; Result:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
; Keywords:
;   PROPERTY_INTERSECTION (Init only): Set this keyword on Init to
;       create an aggregate container that uses the intersection
;       of all of its children's properties, instead of the union.
;       When a new child is added to the container, all of the
;       current aggregate properties are verified as also being
;       registered properties of the child. If not, the properties
;       are unregistered from the aggregate container.
;
;       Note: Properties of the IDLitComponent superclass
;       are not used when determining the intersection,
;       and are never unregistered.
;
function IDLitPropertyAggregate::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitComponent::Init(_EXTRA=_extra)) then $
        return, 0
    if (~self->_IDLitPropertyAggregate::Init(_EXTRA=_extra)) then $
        return, 0

    return, 1
end


;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method preforms all cleanup on the object.
;
pro IDLitPropertyAggregate::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->_IDLitPropertyAggregate::Cleanup
    self->IDLitComponent::Cleanup

end


;----------------------------------------------------------------------------
; Purpose:
;   Override the GetProperty so we can also retrieve properties
;   from our aggregated children.
;
; Keywords:
;   All keywords to IDLitComponent, plus all keywords of our aggregated
;   children.
;
pro IDLitPropertyAggregate::GetProperty, $
    NAME=name, $   ; specify explicitely so we get from ourself only
    DESCRIPTION=description, $
    ICON=icon, $
    IDENTIFIER=identifier, $
    PRIVATE=private, $
    _PARENT=_parent, $
    UVALUE=uvalue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve properties from our aggregated children.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->GetAggregateProperty, _EXTRA=_extra

    if ARG_PRESENT(name) then $
        self->IDLitComponent::GetProperty, NAME=name

    if ARG_PRESENT(description) then $
        self->IDLitComponent::GetProperty, DESCRIPTION=description

    if ARG_PRESENT(icon) then $
        self->IDLitComponent::GetProperty, ICON=icon

    if ARG_PRESENT(identifier) then $
        self->IDLitComponent::GetProperty, IDENTIFIER=identifier

    if ARG_PRESENT(private) then $
        self->IDLitComponent::GetProperty, PRIVATE=private

    if ARG_PRESENT(_parent) then $
        self->IDLitComponent::GetProperty, _PARENT=_parent

    if ARG_PRESENT(uvalue) then $
        self->IDLitComponent::GetProperty, UVALUE=uvalue

end


;----------------------------------------------------------------------------
; Purpose:
;   Override the SetProperty to implement our own properties.
;
; Keywords:
;   All keywords to IDLitComponent, plus all keywords of our aggregated
;   children.
;
pro IDLitPropertyAggregate::SetProperty, $
    NAME=name, $   ; specify explicitely so we set on ourself only
    DESCRIPTION=description, $
    ICON=icon, $
    IDENTIFIER=identifier, $
    PRIVATE=private, $
    _PARENT=_parent, $
    UVALUE=uvalue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitComponent::SetProperty, $
        NAME=name, $
        DESCRIPTION=description, $
        ICON=icon, $
        IDENTIFIER=identifier, $
        PRIVATE=private, $
        _PARENT=_parent, $
        UVALUE=uvalue

    ; Set properties on our aggregated children.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->SetAggregateProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitPropertyAggregate__Define
;
; PURPOSE:
;   Defines the object structure for an IDLitPropertyAggregate object.
;-
pro IDLitPropertyAggregate__Define

    compile_opt idl2, hidden

    struct = { IDLitPropertyAggregate,       $
        inherits _IDLitPropertyAggregate, $  ; must come before itComponent
        inherits IDLitComponent $ ; Superclass.
    }
end
