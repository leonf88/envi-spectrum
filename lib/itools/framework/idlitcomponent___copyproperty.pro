; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitcomponent___copyproperty.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;----------------------------------------------------------------------------
; Purpose:
;   Internal method to copy a set of property descriptors from a
;   specified object to myself.
;
; Syntax:
;   Obj->[IDLitComponent::]_CopyProperty, Source [, PropIds]
;
; Arguments:
;   Source: The object which contains the registered properties to copy.
;
;   PropIds: Optional argument giving the property identifiers to copy.
;       If PropIds is not specified then all registered properties
;       are copied. If a property is already registered on myself
;       then it is not copied.
;
; Keywords:
;   None.
;
pro IDLitComponent::_CopyProperty, oSource, propnames

    compile_opt idl2, hidden

    if (N_PARAMS() eq 0) then $
        propnames = oSource->QueryProperty()

    if (propnames[0] eq '') then return

    myProps = self->QueryProperty()

    for i=0,N_ELEMENTS(propnames)-1 do begin

        ; Skip already registered properties.
        if (MAX(myProps eq propnames[i]) eq 1) then $
            continue

        oSource->GetPropertyAttribute, propnames[i], $
            DESCRIPTION=description, $
            ENUMLIST=enumlistSrc, $
            HIDE=hide, $
            NAME=name, $
            SENSITIVE=sensitive, $
            TYPE=type, $
            UNDEFINED=undefined, $
            VALID_RANGE=validrange

        ; Internally, ENUMLIST is a pointer to a string array.
        ; It is therefore wasteful to store a null string,
        ; so only set it if our type is indeed ENUMLIST.
        if (type eq 9) then $
            enumlist = enumlistSrc

        self->RegisterProperty, propnames[i], type, $
            DESCRIPTION=description, $
            ENUMLIST=enumlist, $
            HIDE=hide, $
            NAME=name, $
            SENSITIVE=sensitive, $
            UNDEFINED=undefined, $
            VALID_RANGE=validrange

    endfor

end

