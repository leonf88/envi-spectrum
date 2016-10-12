; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitpropertybag__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitPropertyBag
;
; PURPOSE:
;   This file implements the IDLitPropertyBag class. This class is
;   used to publish and manage a set of properties exposed by a give
;   object.
;
;   This object is used in the given way:
;     - Create the object.
;     - Provide an object for it to "mimic" or record
;       properties for.
;             * This object will publish those properties.
;             * This object will cache those properties values.
;     - At this point, this object can "proxy" the properities
;       that were recorded.
;     - Later in time, the property values can be reset to another
;       object
;
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   None
;
; CREATION:
;   See IDLitPropertyBag::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitProperyBag::Init
;
; Purpose:
; The constructor of the IDLitPropertyBag object.
;
; Parameters:
; NONE
;
function IDLitPropertyBag::Init

    compile_opt idl2, hidden

    return, 1
end


;---------------------------------------------------------------------------
; IDLitPropertyBag::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitPropertyBag::Cleanup

    compile_opt idl2, hidden

    if (PTR_VALID(self._pValues)) then $
        OBJ_DESTROY, *self._pValues

    PTR_FREE, self._pValues
    PTR_FREE, self._pNames
end


;---------------------------------------------------------------------------
; IDLitPropertyBag::PlaybackProperties
;
; Purpose:
;  This method will "playback" the stored properites it contains and
;  apply them to the given object.
;
; Parameter:
;   oDst   - The object whose values are being applied.
;
; Keywords:
;   SKIP_HIDDEN: If set then do not record hidden,
;       undefined, or userdef properties. This is needed for styles.
;
pro IDLitPropertyBag::PlaybackProperties, oDst, $
    SKIP_HIDDEN=skipHidden

   compile_opt hidden, idl2

    if (~PTR_VALID(self._pValues)) then $
        return

    skipHidden = KEYWORD_SET(skipHidden)

    ; Basically walk the property list and apply them to the source
    for i=0, N_ELEMENTS(*self._pValues)-1 do begin
        propName = (*self._pNames)[i]
        if (skipHidden) then begin
            self->GetPropertyAttribute, propName, $
                HIDE=hide, TYPE=type, UNDEFINED=undefined
            ; Skip hidden, undefined, or USERDEF properties.
            if (hide || undefined || (type eq 0)) then $
                continue
        endif
        if ((*self._pValues)[i]->GetPropertyByIdentifier( $
            propName, value)) then begin
            vartype = SIZE(value, /TYPE)
            ; Do not set objrefs or pointers. These can cause horrible
            ; problems if you set an objref to be the same across
            ; multiple objects. An example is the PALETTE property.
            if (vartype eq 11 || vartype eq 10) then $
                continue
           oDst->SetPropertyByIdentifier, propName, value
        endif
    endfor

end



;---------------------------------------------------------------------------
; IDLitPropertyBag::RecordProperty
;
; Purpose:
;   Record a single property for a given object. This includes
;   registering the property and storing its current value.
;
; Parameter:
;   oSrc - The object whose property is to be recorded.
;   Ident: The property identifier to be recorded.
;
; Keywords:
;   OVERWRITE: If set, then properties which are already registered with
;       ourself will be overwritten with the attributes of that property.
;       Note: The value itself is always overridden, this just controls
;       the attributes such as hide, sensitive, etc.
;
;   SKIP_HIDDEN: If set then do not record hidden,
;       undefined, or userdef properties. This is needed for styles.
;
pro IDLitPropertyBag::RecordProperty, oSrc, ident, $
    OVERWRITE=overwrite, $
    SKIP_HIDDEN=skipHidden

    compile_opt hidden, idl2

    self._bPropsInited  = 1b

    ; If this property is already registered, skip
    ; registering it here.
    isReg = self->QueryProperty(ident)

    oSrc->GetPropertyAttribute, ident, $
        DESCRIPTION=description, $
        ENUMLIST=enumlistIn, $
        HIDE=hide, $
        NAME=name, $
        SENSITIVE=sensitive, $
        TYPE=TYPE, $
        UNDEFINED=undefined, $
        USERDEF=userdef, $
        VALID_RANGE=valid_range

    if (KEYWORD_SET(skipHidden) && $
        (hide || undefined || (type eq 0))) then $
        return

    ; Only set enumlist if necessary. Avoids creating an internal heap id.
    if (type eq 9) then $
        enumlist = enumlistIn

    if (~isReg) then begin

        ; Note: We don't have a RegisterProperty method.
        ; This assumes our subclass also inherits from IDLitComponent.
        self->RegisterProperty, ident, TYPE, $
            DESCRIPTION=description, $
            ENUMLIST=enumlist, $
            HIDE=hide, $
            NAME=name, $
            SENSITIVE=sensitive,  $
            UNDEFINED=undefined, $
            USERDEF=userdef, $
            VALID_RANGE=valid_range

        oValue = OBJ_NEW('IDLitPropertyValue', IDENT)

        ; Add our new registered property to our internal list.
        if (~PTR_VALID(self._pNames)) then begin
            self._pNames = PTR_NEW(ident)
            self._pValues = PTR_NEW(oValue)
        endif else begin
            *self._pNames = [*self._pNames, ident]
            *self._pValues = [*self._pValues, oValue]
        endelse

    endif else begin   ; already registered, but overwrite anyway

        ; Note: We don't have a SetPropertyAttribute method.
        ; This assumes our subclass also inherits from IDLitComponent.
        if KEYWORD_SET(overwrite) then begin
            self->SetPropertyAttribute, ident, $
                DESCRIPTION=description, $
                ENUMLIST=enumlist, $
                HIDE=hide, $
                NAME=Name, $
                SENSITIVE=sensitive,  $
                UNDEFINED=undefined, $
                USERDEF=userdef, $
                VALID_RANGE=valid_range
        endif

        ; No new properties have been added yet.
        if (~PTR_VALID(self._pNames)) then $
            return
        ; Are we overwriting the old property value?
        match = (WHERE(*self._pNames eq ident))[0]
        if (match eq -1) then $
            return
        oValue = (*self._pValues)[match]

    endelse

    ; Record the current value
    if(oSrc->GetPropertybyIdentifier(IDENT, value) ne 0)then $
        oValue->SetPropertyByIdentifier, IDENT, Value

end


;---------------------------------------------------------------------------
; IDLitPropertyBag::RecordProperties
;
; Purpose:
;   Record the properties for a given object. This includes
;   registering the properties and storing their current values.
;
; Parameter:
;   oSrc - The object whose properties are recorded by this object.
;
; Keywords:
;   OVERWRITE: If set, then properties which are already registered with
;       ourself will be overwritten with the attributes of that property.
;       Note: The value itself is always overridden, this just controls
;       the attributes such as hide, sensitive, etc.
;
;   SKIP_HIDDEN: If set then do not record hidden,
;       undefined, or userdef properties. This is needed for styles.
;
pro IDLitPropertyBag::RecordProperties, oSrc, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

    if (self._inRecord) then $
        return

    self._inRecord = 1b
    self._bPropsInited  = 1b

    idProps = oSrc->QueryProperty()
    if (idProps[0] eq '') then begin
        self._inRecord = 0b
        return
    endif

    for i=0, N_ELEMENTS(idProps)-1 do $
        self->RecordProperty, oSrc, idProps[i], _EXTRA=_extra

    self._inRecord = 0b

end


;---------------------------------------------------------------------------
; IDLitPropertyBag::GetProperty
;
; Purpose:
;   Used to get the value of a property that the bag contains.
;
;   This routine determines if the property is contained and then
;   vectors off the _REF_EXTRA value to the matching
;   IDLitPropertyValue object.
;
pro IDLitPropertyBag::GetProperty, _REF_EXTRA=_extra

    compile_opt hidden, idl2

    if (~PTR_VALID(self._pValues)) then $
        return

   ; Loop through the keywords passed in and query the value objects.
   for i=0, N_ELEMENTS(_extra)-1 do begin
       dex = where(_extra[i] eq *self._pNames, nMatch)
       if(nMatch eq 0)then $
          continue
       (*self._pValues)[dex[0]]->GetProperty, _EXTRA=_extra[i]
   endfor

end


;---------------------------------------------------------------------------
; IDLitPropertyBag::SetProperty
;
; Purpose:
;   Used to set the value of a property that the bag contains.
;
;   This method will determine which target property is being set and
;   vector off the SetProperty call to the Property Value object that
;   is managing the value for that object.
;
pro IDLitPropertyBag::SetProperty, _REF_EXTRA=_extra

    compile_opt hidden, idl2

    if (~PTR_VALID(self._pValues)) then $
        return

   ; Loop through the keywords passed in and query the value objects.
   for i=0, N_ELEMENTS(_extra)-1 do begin
       dex = where(_extra[i] eq *self._pNames, nMatch)
       if(nMatch eq 0)then $
          continue
       (*self._pValues)[dex[0]]->SetProperty, _EXTRA=_extra[i]
   endfor

end


;---------------------------------------------------------------------------
; Defintion
;---------------------------------------------------------------------------
; IDLitPropertyBag__Define
;
; Purpose:
; Class definition for the IDLitPropertyBag object
;
pro IDLitPropertyBag__Define

  compile_opt idl2, hidden

  void = {IDLitPropertyBag, $
          _inRecord     : 0b,        $
          _bPropsInited  : 0b,          $ ; Set if props have been rec.
          _pNames       : ptr_new(), $ ;names of the properties managed
          _pValues      : ptr_new()  $
         }

end
