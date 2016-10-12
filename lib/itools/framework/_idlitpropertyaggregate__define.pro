; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitpropertyaggregate__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitPropertyAggregate
;
; PURPOSE:
;   This class represents a collection of registered properties.
;
; MODIFICATION HISTORY:
;   Written by: CT, RSI, April 2002
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitPropertyAggregate::Init
;
; PURPOSE:
;   This function method initializes the object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('_IDLitPropertyAggregate')
;
;   or
;
;   Obj->[_IDLitPropertyAggregate::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;   PROPERTY_INTERSECTION (Init only): Set this keyword on Init to
;       create an aggregate container that uses the intersection
;       of all of its children's properties, instead of the union.
;       When a new child is added to the container, all of the
;       current aggregate properties are verified as also being
;       registered properties of the child. If not, the properties
;       are unregistered from the aggregate container.
;
;       Note: Properties of the _IDLitPropertyAggregate subclass
;       are not used when determining the intersection,
;       and are never unregistered.
;
; OUTPUTS:
;   1 for success, 0 for failure.
;
;-
function _IDLitPropertyAggregate::Init, $
    PROPERTY_INTERSECTION=intersection

    compile_opt idl2, hidden

    if (KEYWORD_SET(intersection)) then begin
        ; Create an empty component to hold intersected properties.
        self._oPropIntersection = OBJ_NEW('IDLitComponent', $
            REGISTER_PROPERTIES=0)
    endif

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform cleanup on the object, including removing all aggregated
;   children (but not destroying them), and cleaning up any
;   property descriptors.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro _IDLitPropertyAggregate::Cleanup

    compile_opt idl2, hidden

    ; This will also clean up any intersection property descriptors.
    OBJ_DESTROY, self._oPropIntersection

    if (OBJ_VALID(self._oAggChildren)) then begin
        ; Remove all my objrefs.
        ; We assume these get destroyed by someone else.
        self._oAggChildren->Remove, /ALL
        OBJ_DESTROY, self._oAggChildren
    endif

end


;---------------------------------------------------------------------------
; Purpose:
;   Return 1 if the container uses property intersection, or 0 if
;   the container uses property union.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function _IDLitPropertyAggregate::IsAggregateIntersection

    compile_opt idl2, hidden

    return, OBJ_VALID(self._oPropIntersection)
end


;---------------------------------------------------------------------------
; Purpose:
;   Add a child to the aggregate container.
;   If property intersection is being used, then also remove any
;   properties that aren't registered with the new child.
;
; Arguments:
;   Objects: An object instance or array of object instances to be
;       added to the container object.
;
; Keywords:
;   POSITION: Set this keyword equal to a scalar or array of zero-based
;       index values. The number of elements specified must be equal
;       to the number of object references specified by the Objects
;       argument. Each index value specifies the position within the
;       container at which a new object should be placed.
;       The default is to add new objects at the end of the list
;       of contained items.
;
pro _IDLitPropertyAggregate::AddAggregate, oChild, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Create my container if it isn't already created.
    if (~OBJ_VALID(self._oAggChildren)) then $
        self._oAggChildren = OBJ_NEW('IDL_Container')

    wasEmpty = (self._oAggChildren->Count() eq 0)

    ; Add an aggregated objref. We do this regardless of whether it
    ; has any properties (or whether the intersection has any properties),
    ; since presumably the user still wants to know that these
    ; objects are aggregated.
    self._oAggChildren->Add, oChild, _EXTRA=_extra

    if (self->IsAggregateIntersection()) then begin

        start = 0   ; Check all children

        ; If we only have one aggregated child
        ; then we need to copy all the properties of the
        ; first child into our intersection itComponent.
        if (wasEmpty) then begin

            strMyProps = self->QueryProperty()
            strChildProp = oChild[0]->QueryProperty()

            ; Make sure I don't already have a property,
            ; before registering it with my intersection.
            for i=0,N_ELEMENTS(strChildProp)-1 do begin
                if (MAX(strChildProp[i] eq strMyProps) eq 0) then begin
                    self._oPropIntersection->_CopyProperty, $
                        oChild[0], strChildProp[i]
                endif
            endfor

            start = 1   ; First child is done

        endif


        ; Check all of our new children (except maybe the first).
        for i=start,N_ELEMENTS(oChild)-1 do begin

            ; Identifiers for all intersected properties.
            ; We need to query this each time in case we threw some out.
            strIntersect = $
                self._oPropIntersection->QueryProperty()
            nIntersect = N_ELEMENTS(strIntersect)

            ; No intersected properties left?
            if (strIntersect[0] eq '') then $
                break

            ; Retrieve the child properties.
            strChildProp = oChild[i]->QueryProperty()
            nChild = N_ELEMENTS(strChildProp)
            oPropIntersection = self._oPropIntersection

            if (nChild eq 0) then begin   ; Remove all
                ; Access our private propertydescriptor container.
                oPropDesc = oPropIntersection.propertydescriptors->Get(/ALL)
                oPropIntersection.propertydescriptors->Remove, /ALL
                OBJ_DESTROY, oPropDesc   ; don't forget to destroy!
                break  ; we're done
            endif

            ; Loop thru our remaining intersected properties.
            ; This list is probably smaller than the child list.
            ; Loop thru backwards so we can throw out
            ; items from the intersect list that don't match.
            for j=nIntersect-1,0,-1 do begin
                ; If the property exists in both lists, continue.
                if (MAX(strChildProp eq strIntersect[j])) then $
                    continue
                ; Oh oh. Property doesn't exist in the child.
                ; We need to remove it from the intersection.
                ; Access our private propertydescriptor container.
                oPropDesc = oPropIntersection.propertydescriptors-> $
                    Get(POSITION=j)
                oPropIntersection.propertydescriptors->Remove, $
                    POSITION=j
                OBJ_DESTROY, oPropDesc   ; don't forget to destroy!
            endfor

        endfor   ; check children

    endif   ; intersection


end


;---------------------------------------------------------------------------
; Purpose:
;   Returns the number of children in the aggregate container.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function _IDLitPropertyAggregate::CountAggregate

    compile_opt idl2, hidden

    return, OBJ_VALID(self._oAggChildren) ? self._oAggChildren->Count() : 0

end


;---------------------------------------------------------------------------
; Purpose:
;   Retrieves object references for aggregate children.
;
; Keywords:
;   ALL: Set this keyword to return an array of object references
;       to all of the objects in the container.
;
;   COUNT: Set this keyword equal to a named variable that will contain
;       the number of objects selected by the function. If the ALL keyword
;       is also specified, specifying this keyword is the same as calling
;       the _IDLitPropertyAggregate::CountAggregate method.
;
;   ISA: Set this keyword equal to a class name or vector of class names.
;       This keyword is used in conjunction with the ALL keyword.
;       The ISA keyword filters the array returned by the ALL keyword,
;       returning only the objects that inherit from the class or
;       classes specified by the ISA keyword.
;
;       Note: This keyword is ignored if the ALL keyword is not provided.
;
;   POSITION: Set this keyword equal to a scalar or array containing the
;       zero-based indices of the positions of the objects to return.
;
function _IDLitPropertyAggregate::GetAggregate, $
    COUNT=nChildren, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    nChildren = 0

    ; Get all my aggregated objrefs.
    return, OBJ_VALID(self._oAggChildren) ? $
        self._oAggChildren->Get(COUNT=nChildren, _EXTRA=_extra) : -1

end


;---------------------------------------------------------------------------
; Purpose:
;   Returns true (1) if the specified object is in the container,
;   or false (0) otherwise.
;
; Arguments:
;   oObject: The object reference or vector of object references of
;       the object(s) to search for in the container
;
; Keywords:
;   POSITION: Set this keyword to a named variable that upon return will
;       contain the position(s) at which (each of) the argument(s) is
;       located within the container, or -1 if it is not contained.
;
function _IDLitPropertyAggregate::IsContainedAggregate, oObject, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if OBJ_VALID(self._oAggChildren) then begin
        return, self._oAggChildren->IsContained(oObject, $
            _EXTRA=_extra)
    endif

    return, LONARR(N_ELEMENTS(oObject))

end


;---------------------------------------------------------------------------
; Purpose:
;   Remove children from the aggregate container.
;
; Arguments:
;   Child_object: The object reference of the object to be removed
;       from the container. If Child_object is not provided
;       (and neither the ALL nor POSITION keyword are set),
;       the first object in the container will be removed.
;
; Keywords:
;   ALL: Set this keyword to remove all objects from the container.
;       If this keyword is set, the Child_object argument is not required.
;
;   POSITION: Set this keyword equal to the zero-based index of the
;       object to be removed. If the Child_object argument is supplied,
;       this keyword is ignored.
;
pro _IDLitPropertyAggregate::RemoveAggregate, oChild, $
    ALL=all, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oAggChildren)) then $
        return

    if (N_PARAMS() eq 1) then $
        self._oAggChildren->Remove, oChild, _EXTRA=_extra $
    else $
        self._oAggChildren->Remove, ALL=all, _EXTRA=_extra

    ; If we are using intersection, and our container is empty,
    ; then unregister all aggregate properties.
    ; Note: If just a single child is being removed, we don't
    ; try to determine if there are any properties that are
    ; now in common with the remaining children that weren't
    ; in the removed child. Typically you want to remove
    ; everything, so then it doesn't matter.
    if (self->IsAggregateIntersection() && $
        (self->CountAggregate() eq 0)) then begin
        oPropIntersection = self._oPropIntersection
        ; Access our private propertydescriptor container.
        oPropDesc = oPropIntersection.propertydescriptors->Get(/ALL)
        oPropIntersection.propertydescriptors->Remove, /ALL
        if (OBJ_VALID(oPropDesc[0])) then $
            OBJ_DESTROY, oPropDesc   ; don't forget to destroy!
    endif

end


;---------------------------------------------------------------------------
; Purpose:
;   Calls the GetProperty method on all of the aggregated children.
;   This method should be called within the subclass' GetProperty method.
;
; Arguments:
;   None.
;
; Keywords:
;   Any keywords to the GetProperty method for any of the children
;   are allowed.
;
pro _IDLitPropertyAggregate::GetAggregateProperty, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Sanity checks.
    if (N_ELEMENTS(_extra) eq 0) then $
        return
    if (~OBJ_VALID(self._oAggChildren)) then $
        return

    ; For property intersection we assume we only need
    ; to query the first child to retrieve the current property
    ; value. If the property only belongs to one of the children
    ; we shouldn't be calling GetAggregateProperty anyway,
    ; and if the property belongs to all of the children
    ; then getting it from the first is just as good
    ; as any other.
    if (self->IsAggregateIntersection()) then begin
        ; Retrieve just the first child.
        oChild = self._oAggChildren->Get(COUNT=hasChild)
        if (~hasChild) then $
            return
        oChild->GetProperty, _EXTRA=_extra
        return
    endif


    ; For property union things are trickier since we don't know which
    ; child has a certain property. We could try to keep track of who
    ; has what property, but that is a lot of bookeeping.
    ; For now, just ask for the property from each child.

    ; Retrieve all children in the container.
    oChild = self._oAggChildren->Get(/ALL, COUNT=nChild)

    for i=nChild-1,0,-1 do begin
        if (OBJ_VALID(oChild[i])) then $
            oChild[i]->GetProperty, _EXTRA=_extra
    endfor

end


;---------------------------------------------------------------------------
; Purpose:
;   Calls the SetProperty method on all of the aggregated children.
;   This method should be called within the subclass' SetProperty method.
;
; Arguments:
;   None.
;
; Keywords:
;   Any keywords to the SetProperty method for any of the children
;   are allowed.
;
pro _IDLitPropertyAggregate::SetAggregateProperty, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Sanity checks.
    if (N_ELEMENTS(_extra) eq 0) then $
        return
    if (~OBJ_VALID(self._oAggChildren)) then $
        return

    ; Retrieve all children in the container.
    oChild = self._oAggChildren->Get(/ALL, COUNT=nChild)

    ; Loop thru and set the properties on all of the children.
    for i=0,nChild-1 do begin
        ;; When aggregating properties, a strict naming match must be used
        ;; or IDL's partial name behavior can cause issues. A good
        ;; example is the contour FILL and polygon FILL_PATTERN
        ;;
        ;; To get around this, we exploit some of the behavior
        ;; of _REF_EXTRA and provide the names of the properties
        ;; supported by the child.
        ;
        ; Note: This has the side effect that you can only set
        ; the values of *registered* properties on your aggregated
        ; children.
        myClass = OBJ_CLASS(oChild[i])
        ; If the previous child class is the same, reuse the prop list.
        ; Otherwise do a new queryproperty.
        if (i eq 0 || myClass ne prevClass) then $
            props = oChild[i]->QueryProperty()
        oChild[i]->SetProperty, _EXTRA=props
        prevClass = myClass
    endfor

end


;----------------------------------------------------------------------------
; Purpose:
;   Override our subclass' method, so we can edit userdef properties
;   on our aggregated children.
;
; Result:
;   Returns 1 if the property was successfully changed for one or more
;   of the children, 0 otherwise.
;
; Argumemts:
;   Tool: Object reference for the current tool.
;
;   PropertyIdentifier: A string giving the keyword name of the
;       userdef property.
;
; Keywords:
;   None.
;
function _IDLitPropertyAggregate::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    ; Sanity check.
    if (~OBJ_VALID(self._oAggChildren)) then $
        return, 0

    ; Retrieve all children in the container.
    oChild = self._oAggChildren->Get(/ALL, COUNT=nChild)
    if (nChild eq 0) then $
        return, 0

    ; For property intersection, we assume that the first child
    ; can handle the EditUserDefProperty. Once we get the new value,
    ; we just set it on the rest of our intersected children.
    if (self->IsAggregateIntersection()) then begin

        ; Call our child's method.
        success = oChild[0]->EditUserDefProperty(oTool, identifier)

        ; User hit cancel on some dialog, or property wasn't found.
        if (~success) then $
            return, 0

        ; Get the new value.
        success = oChild[0]-> $
            GetPropertyByIdentifier(identifier, newvalue)

        if (~success) then $
            return, 0

        for i=1, nChild-1 do begin
            ; In case one of our children can't handle the property
            ; for some reason (shouldn't happen for intersection),
            ; we catch any errors and swallow them.
            CATCH, err
            if (err eq 0) then $
                oChild[i]->SetPropertyByIdentifier, identifier, newvalue
            CATCH, /CANCEL
        endfor

        return, 1  ; success
    endif

    ; For union, presumably only one child actually has a particular
    ; userdef property, but we don't know which one.
    ; For simplicity, just call the method on all of them.
    for i=nChild-1,0,-1 do begin
        ; If we have success on any one child, then assume we
        ; can stop calling the rest.
        success = oChild[i]->EditUserDefProperty(oTool, identifier)
        if (success) then $
            return, 1
    endfor

    ; If we reach here, we didn't successfully change the property.
    return, 0

end


;---------------------------------------------------------------------------
; Purpose:
;   Filters properties: Order, Hidden
;
function _IDLitPropertyAggregate::_FilterProperties, oMyProps, $
                                  INCLUDE_NAME=incName, $
                                  INCLUDE_DESCRIPTION=incDesc
  compile_opt hidden, idl2

  n = N_ELEMENTS(oMyProps)
  
  ; Possibly adjust visibility of name and description
  found = 0
  for i=0,n-1 do begin
    oMyProps[i]->GetProperty, NAME=name
    void = where(STRUPCASE(name) eq 'NAME', cnt)
    if (cnt ne 0) then begin
      oMyProps[i]->SetProperty, HIDE=(~KEYWORD_SET(incName))
      found++
    endif
    void = where(STRUPCASE(name) eq 'DESCRIPTION', cnt)
    if (cnt ne 0) then begin
      oMyProps[i]->SetProperty, HIDE=(~KEYWORD_SET(incDesc))
      found++
    endif
    if (found eq 2) then break
  endfor

  ; Order properties
  if ((N_ELEMENTS(orderProps) ne 0) && (orderProps[0] ne '')) then begin
    orderProps = STRUPCASE(orderProps)
    ; Ensure NAME and DESCRIPTION remain up top, if shown
    if (((where(orderProps eq 'DESCRIPTION'))[0] eq -1) && $
        KEYWORD_SET(incDesc)) then $
      orderProps = ['DESCRIPTION', orderProps]
    if (((where(orderProps eq 'NAME'))[0] eq -1) && $
        KEYWORD_SET(incName)) then $
      orderProps = ['NAME', orderProps]
    index = indgen(n)
    newIndex = REPLICATE(-1, N_ELEMENTS(orderProps))
    for i=0,n-1 do begin
      oMyProps[i]->GetProperty, NAME=name
      wh = where(STRUPCASE(name) eq orderProps, cnt)
      if (cnt ne 0) then begin
        newIndex[wh] = i
        index[i] = -1
      endif
    endfor
    ; Filter out -1s
    wh = where(index ne -1, cnt)
    if (cnt ne 0) then $
      index = index[wh]
    wh = where(newIndex ne -1, cnt)
    if (cnt ne 0) then $
      newIndex = newIndex[wh]
    oMyProps = oMyProps[[newIndex, index]]
  endif
  
  return, oMyProps
  
end

;---------------------------------------------------------------------------
; Purpose:
;   Override the IDLitComponent method. Returns all property descriptors
;   object references, including those from the aggregated children.
;
; Keywords:
;   COUNT: Set this keyword to a named variable in which to return
;       the number of returned properties.
;
function _IDLitPropertyAggregate::_GetAllPropertyDescriptors, $
    COUNT=count, _EXTRA=_extra

    compile_opt hidden, idl2


    ; Get just my own registered property descriptors.
    ; Default value for COUNT is just my own # of properties.
    oMyProp = self->IDLitComponent:: $
        _GetAllPropertyDescriptors(COUNT=count)


    ; Intersection of child properties.
    if (self->IsAggregateIntersection()) then begin

        ; Retrieve property descriptors for my intersect component.
        oPropIntersectDesc = self._oPropIntersection-> $
            _GetAllPropertyDescriptors(COUNT=nIntersect)

        count += nIntersect

        ; Concat my own and my intersect children properties.
        oMyProp = (nIntersect gt 0) ? $
            [oMyProp, TEMPORARY(oPropIntersectDesc)] : oMyProp
        return, self->_FilterProperties(oMyProp, _EXTRA=_extra)

    endif

    ; union of myself + child properties

    ; Get aggregated children.
    oChildren = self->GetAggregate(/ALL, COUNT=nChildren)

    ; If no aggregated children, we are done.
    if (nChildren eq 0) then $
        return, self->_FilterProperties(oMyProp, _EXTRA=_extra)


    ; Retrieve property identifiers for myself.
    myPropID = STRARR(count)
    for j=0,count-1 do begin
        oMyProp[j]->GetProperty, PROPERTY_IDENTIFIER=id
        myPropID[j] = id
    endfor

    for i=0,nChildren-1 do begin

        ; For each child, retrieve the registered properties
        ; and aggregate them.
        oAgg = oChildren[i]->_GetAllPropertyDescriptors(COUNT=nProp)
        if (nProp eq 0) then $
            continue   ; skip to next

        ; Retrieve property identifiers.
        propID = STRARR(nProp)
        for j=0,nProp-1 do begin
            oAgg[j]->GetProperty, PROPERTY_IDENTIFIER=id
            ; If I don't have this property yet, then add it.
            if (MAX(myPropID eq id) eq 0) then $
                propID[j] = id
        endfor

        ; If there are any new properties, add them to the overall list.
        keep = WHERE(propid ne '', nkeep)
        if (nkeep gt 0) then begin
            oMyProp = [oMyProp, oAgg[keep]]
            myPropID = [myPropID, propid[keep]]
        endif

    endfor

    ; Fill in the final count.
    count = N_ELEMENTS(oMyProp)

    return, self->_FilterProperties(oMyProp, _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method to set the property attributes for our
;   intersected properties, depending upon the children
;   property attributes and values.
;
;   Rules:
;       If one of the child's properties is hidden, our intersected
;       property is also hidden.
;       If one of the child's properties is insensitive, our intersected
;       property is also insensitive.
;       If a property value is different among the children, then our
;       intersected property is set to undefined.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro _IDLitPropertyAggregate::_CheckIntersectAttributes

    compile_opt idl2, hidden

    ; Get aggregated children.
    oChildren = self->GetAggregate(/ALL, COUNT=nChildren)

    ; Sanity checks.
    if (nChildren eq 0) then $
        return
    if (~OBJ_VALID(self._oPropIntersection)) then $
        return

    strIntersect = self._oPropIntersection->QueryProperty()
    if (strIntersect[0] eq '') then $
        return

    for i=0,N_ELEMENTS(strIntersect)-1 do begin

        ; Default attributes.
        myhide = 0b
        mysensitive = 1b
        myundefined = 0b

        for j=0,nChildren-1 do begin

            oChildren[j]->GetPropertyAttribute, strIntersect[i], $
                HIDE=hide, SENSITIVE=sensitive, TYPE=propType, $
                UNDEFINED=undefined

            ; Hidden if any child is hidden,
            ; sensitive if all children are sensitive,
            ; undefined if any child is undefined, or if my type is userdef.
            myhide = myhide || hide
            mysensitive = mysensitive && sensitive
            myundefined = myundefined || undefined || (propType eq 0)

            ; No point in checking this property further.
            if (myhide) then $
                break

            ; If undefined or type is user-defined, just keep going.
            if (myundefined) then $
                continue

            ; If not undefined, start checking the child property values.
            if (j eq 0) then begin

                ; First time we just cache the value
                success = oChildren[j]-> $
                    GetPropertyByIdentifier(strIntersect[i], myvalue)

                ; If not a numeric/string type, then set to undefined.
                ; These are probably USERDEF properties anyway, and will
                ; have gotten filtered out earlier.
                switch SIZE(myvalue, /TYPE) of
                    0:   ; undefined
                    8:   ; structure
                    10:  ; pointer
                    11: begin  ; objref
                        myundefined = 1b
                        break
                        end
                    else:
                endswitch

            endif else begin
                if (N_ELEMENTS(myvalue) eq 0) then $
                    continue
                ; Check the cached value against the other children.
                success = oChildren[j]-> $
                    GetPropertyByIdentifier(strIntersect[i], value)
                if (~ARRAY_EQUAL(myvalue, value, /NO_TYPECONV)) then $
                    myundefined = 1b
            endelse

        endfor

        ; Set my intersected property attributes.
        self._oPropIntersection->SetPropertyAttribute, strIntersect[i], $
            HIDE=myhide, SENSITIVE=mysensitive, UNDEFINED=myundefined

    endfor   ; intersect properties

end


;---------------------------------------------------------------------------
;; Definition
;----------------------------------------------------------------------------
;+
; _IDLitPropertyAggregate__Define
;
; Purpose:
;   Defines the object structure for an _IDLitPropertyAggregate object.
;-
pro _IDLitPropertyAggregate__Define

    compile_opt idl2, hidden

    struct = { _IDLitPropertyAggregate, $
        _oPropIntersection: OBJ_NEW(), $
        _oAggChildren: OBJ_NEW() $
        }
end

