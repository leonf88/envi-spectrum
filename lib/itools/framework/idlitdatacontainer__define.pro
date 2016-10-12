; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitdatacontainer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataContainer
;
; PURPOSE:
;   This file implements the IDLitDataContainer class. This class provides
;   a data container that is aware of data objects stored in it.  It uses
;   data identifiers to locate data objects stored in a data container
;   tree heirarchy.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   _IDLitContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataContainer::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataContainer::Init
;
; Purpose:
;   The constructor of the IDLitDataContainer object.
;
; Parameters:
;   Data - Data that is stored in this object.
;
function IDLitDataContainer::Init, Data,  _EXTRA=_extra

    compile_opt idl2, hidden

@idlit_on_error2

    ; Init superclass
    if(self->IDLitData::Init(Data, _EXTRA=_extra) eq 0) then $
        return, 0
    if(self->IDL_Container::Init() eq 0) then begin
        self->IDLitData::Cleanup
        return, 0
    endif
    if(self->_IDLitContainer::Init(_EXTRA=_extra) eq 0) then begin
        self->IDLitData::Cleanup
        self->IDL_Container::Cleanup
        return, 0
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataContainer::SetProperty, _EXTRA=_EXTRA

   return, 1
end

;---------------------------------------------------------------------------
; IDLitDataContainer::Cleanup
;
; Purpose:
;    Destructor for the object.
;

pro IDLitDataContainer::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclass
    self->_IDLitContainer::Cleanup
    self->IDL_Container::Cleanup
    self->IDLitData::Cleanup

end

;---------------------------------------------------------------------------
; Properties
;---------------------------------------------------------------------------
; IDLitDataContainer::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;

pro IDLitDataContainer::GetProperty,  _REF_EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(_super) gt 0)then begin
        self->IDLitData::GetProperty, _EXTRA=_super
        self->_IDLitContainer::GetProperty, _EXTRA=_super
    endif
end

;---------------------------------------------------------------------------
; IDLitDataContainer::SetProperty
;
; Purpose:
;   Used to set the value of the properties associated with this class.
; Properties:
;   HIDE - A Boolean that when true prevents this object from being found
;          by an Identifier search.
;   READ_ONLY - A Boolean that when true prevents the SetData method from
;               modifying the data.
;

pro IDLitDataContainer::SetProperty, _EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(_super) gt 0)then begin
        self->IDLitData::SetProperty, _EXTRA=_super
        self->_IDLitContainer::SetProperty, _EXTRA=_super
    endif
end

;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; IDLitDataContainer::GetData
;
; Purpose:
;   This method returns the data contained in the object referenced
;   by the provided object identifier. If the object identifier is
;   not provided or set to '', the data for this object is returned.
;
; Parameters:
;   Data - A named variable that this function sets to the data or data
;          container object.
;
;   IdentPath - The data path name.
;
; Keywords:
;   None - All are passed to target GetData method
;
; Return value:
;   If successful, return 1 and sets the Data argument.
;
;   If not successful, return 0 and leave Data argument unchanged.
;
function IDLitDataContainer::GetData, Data, $
                           IdentPath, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Check if this is for this object.
    oObj = (not keyword_set(IdentPath) ? self : $
              self->_IDLitContainer::GetByIdentifier(IdentPath))

    result = 0
    if (obj_valid(oObj) && obj_isa(oObj, 'IDLitData')) then begin
        ; Don't get the data if it is hidden
        oObj->GetProperty, HIDE=hide
        if hide eq 0 then begin
            result = (oObj eq self) ? $
                oObj->IDLitData::GetData(Data, _EXTRA=_extra) : $
                oObj->GetData(Data, _EXTRA=_extra)
        endif
    endif
    return, result
end

;---------------------------------------------------------------------------
; IDLitDataContainer::SetData
;
; Purpose:
;   This function method stores data in a data object referred to by the
;   identifier path name.
;
; Parameters:
;   Data - A named variable containing the data to store.
;
;   IdentPath - The data path name.
;
; Keywords:
;   None
function IDLitDataContainer::SetData, Data, IdentPath, $
                           _EXTRA=_EXTRA


    compile_opt idl2, hidden

    ; Check if this is for this object.
    oObj = (not keyword_set(IdentPath) ? self : $
              self->_IDLitContainer::GetByIdentifier(IdentPath))

    result = 0
    if (obj_valid(oObj) && obj_isa(oObj, 'IDLitData')) then begin
        ; Don't get the data if it is hidden
        oObj->GetProperty, HIDE=hide
        if hide eq 0 then begin
            result = (oObj eq self) ? $
                oObj->IDLitData::SetData(Data, _EXTRA=_extra) : $
                oObj->SetData(Data, _EXTRA=_extra)
        endif
    endif
    return, result
end


;;---------------------------------------------------------------------------
;; IDLitDataContainer::GetIdentifiers
;;
;; Purpose:
;;   This function method returns a string array of all data identifiers
;;   that reference data containers or objects contained in the container.
;;
;; Parameters:
;;   Pattern - A string-matching pattern filter
;;
;; Keywords:
;;   LEAF - return only the paths that terminiate in a non-container object.

;; Recursive part
pro IDLitDataContainer::_GetId, strArray, currString, LEAF=leaf
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Check for recusive data structures
    if(self._bInSearch ne 0)then return
    self._bInSearch=1;

    oItems = self->IDL_Container::Get(/ALL, COUNT=nItems)
    for i=0, nItems-1 do begin
        ;; Skip if hidden
        if obj_isa(oItems[i], 'IDLitData') then begin
            oItems[i]->GetProperty, HIDE=hide
            if hide ne 0 then continue
        endif
        oItems[i]->GetProperty, IDENTIFIER=identifier
        newString = currString + $
          (currString eq '' ? '' : '/') + identifier
        if obj_isa(oItems[i], 'IDLitDataContainer') then begin
            if not keyword_set(leaf) then begin
                strArray = [strArray, newString]
            endif
            oItems[i]->_GetId, strArray, newString, LEAF=leaf
        endif else begin
            strArray = [strArray, newString]
        endelse
    endfor
    self._bInSearch=0
end


;;----------------------------------------------
;; Non-recursive part
;
; CT Note: It would be nice to rip this code out and use
; FindIdentifiers instead. Unfortunately, we need to keep this
; so we can look at the HIDE property. This also returns
; relative identifiers instead of full identifiers.
;
function IDLitDataContainer::GetIdentifiers, Pattern, $
    LEAF_NODES=leaf
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Do recursive part.
    strArray = ['']
    self->_GetId, strArray, '', LEAF=leaf
    ;; Filter returned strings
    ;; Yes, this could have been done in the recursive part - it is
    ;; debatable which is better.
    if n_elements(Pattern) ne 0 then begin
        matches = where(strmatch(strArray, Pattern, /FOLD_CASE) eq 1, count)
        if count ne 0 then strArray = strArray[matches]
    endif else begin
        if n_elements(strArray) gt 1 then strArray = strArray[1:*]
    endelse
    return, strArray
end


;---------------------------------------------------------------------------
; IDLitDataContainer::GetByType
;
; Purpose:
;   Return all objects in the container that are of the specified type(s),
;   including those in containers within the container.
;   The objects are returned in an array of object references.  If there
;   are no matches, an array with a single null object reference is returned.
;
; Parameters:
;   Types - a string or array of strings that are used to search for data
;   objects that are one of these types.
;
; Keywords:
;   COUNT[out] - The nubmer of valid items returned

function IDLitDataContainer::GetByType, Types, COUNT=count

    compile_opt idl2, hidden

    ; Get self
    ret = self->IDLitData::GetByType(types)

    oItems = self->IDL_Container::Get(/ALL, COUNT=nItems)
    for i=0, nItems-1 do begin
        if (obj_isa(oItems[i], "IDLitDataContainer")) then begin
            new = oItems[i]->IDLitDataContainer::GetByType(Types)
            ret = [ret, new]
        endif else begin
            oItems[i]->GetProperty, TYPE=objType
            void = where(strcmp(types, objType, /FOLD_CASE) gt 0, count)
            if (count gt 0) then begin
                ret = [ret, oItems[i]]
            endif
        endelse
    endfor

    ind = where(obj_valid(ret), count)
    ; Be sure to return a scalar if only one match.
    return, count eq 0 ? obj_new() : ((count eq 1) ? ret[ind[0]] : ret[ind])
end
;---------------------------------------------------------------------------
; IDLitDataContainer::GetTypes
;
; Purpose:
;   Return the types supported by this object. This includes any
;   base types and specializations.
;
function IDLitDataContainer::GetTypes


    compile_opt idl2, hidden

    type = ['DATA', self._type]

    ; Recursively retrieve the types of the contents of this container.
    oItems = self->IDL_Container::Get(/ALL, COUNT=nItems)
    for i=0, nItems-1 do begin
        type = [type, oItems[i]->GetTypes()]
    endfor

    return, type[UNIQ(type, SORT(type))]

end


;---------------------------------------------------------------------------
; Data sub-element notification managment section
;
; The following section is used to manage notifications that take
; place with the sub-data elements of this container. Often an
; operation will modify a sub-element and trigger it's notifcation
; process. However, the items interested in this change are
; registered with a top container. As such, a connection is needed
; between the sub-data elements and the container. This is done using
; the data notifcation system.
;---------------------------------------------------------------------------
; IDLitDataContainer::Add
;
; Purpose:
;    Override the add method so that the notification system can be
;    'wired-up'.
;
pro IDLitDataContainer::Add, oData, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    dex = where(obj_isa(oData, "IDLitData"), nValid)
    if (nValid eq 0) then return
    oItems = oData[dex]

    for i =0, nValid-1 do $;wire up notification
      oItems[i]->AddDataObserver, self, _EXTRA='OBSERVE_ONLY'

    self->_IDLitContainer::Add, oItems, _EXTRA=_extra

    ; If updates are disabled, mark a pending udpate
    if(self._iDisable gt 0)then begin
        self._iUpdates or= 3 ; change and complete
        return
    end
    ; Send a notification message
    self->NotifyDataChange
    self->NotifyDataComplete
end


;---------------------------------------------------------------------------
; IDLitDataContainer::Remove
;
; Purpose:
;    Override the remove method so that the notification system can be
;    'wired-up'.
;
pro IDLitDataContainer::Remove, oData, ALL=ALL, _EXTRA=_EXTRA
    compile_opt idl2, hidden

    if (self->Count() eq 0) then $
        return

    if(keyword_set(ALL))then $
      oData = self->_IDLitContainer::Get(/all)

    if (~MAX(self->_IDLitContainer::IsContained(oData))) then $
        return

    for i=0, n_elements(oData)-1 do begin
      if (OBJ_VALID(oData[i])) then $
        oData[i]->RemoveDataObserver, self ;remove notification
    endfor

    self->_IDLitContainer::Remove,oData, _EXTRA=_EXTRA

    ; If updates are disabled, mark a pending udpate
    if(self._iDisable gt 0)then begin
        self._iUpdates or= 3 ; change and complete
        return
    end
    ; Send a notification message
    self->NotifyDataChange
    self->NotifyDataComplete
end

;---------------------------------------------------------------------------
; IDLitDataContainer::AddByIdentifer
;
; Purpose:
;    Override the method so that the notification system can be
;    'wired-up'.

pro IDLitDataContainer::AddByIdentifier, ID, oData, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oData->AddDataObserver, self

    self->_IDLitContainer::AddByIdentifier, ID, oData, _REF_EXTRA=_extra

end
;---------------------------------------------------------------------------
; IDLitDataContainer::RemoveByIdentifer
;
; Purpose:
;    Override the method so that the notification system can be
;    'wired-up'.

function IDLitDataContainer::RemoveByIdentifier, ID

    compile_opt idl2, hidden


    oData = self->_IDLitContainer::RemoveByIdentifier(ID)

    if(obj_valid(oData))then $
      oData->RemoveDataObserver, self

    return, oData
end
;---------------------------------------------------------------------------
; IDLitDataContainer::OnDataChange
;
; Purpose:
;    called when a change message was triggered by a contained object.
;
; Parameters:
;    oSubject  - The item that triggered the message
pro IDLitDataContainer::OnDataChange, oSubject
    compile_opt idl2, hidden

    ; If updates are disabled, mark a pending udpate
    if(self._iDisable gt 0)then begin
        self._iUpdates or= 1
        return
    end
    self->IDLitData::NotifyDataChange
end

;---------------------------------------------------------------------------
; IDLitDataContainer::OnDataComplete
;
; Purpose:
;    Called when this message was sent by the subject.
;
; Parameters:
;    oSubject  - The item that triggered the message

pro IDLitDataContainer::OnDataComplete, oSubject
    compile_opt idl2, hidden

    ; If updates are disabled, mark a pending udpate
    if(self._iDisable gt 0)then begin
        self._iUpdates or= 2
        return
    end
    self->IDLitData::NotifyDataComplete
end


;---------------------------------------------------------------------------
; IDLitDataContainer::OnDataDelete
;
; Purpose:
;    Callback for when a item was deleted and was contained by this
;    container
;
; Parameters:
;    oSubject  - The item that was deleted.

pro IDLitDataContainer::OnDataDelete, oSubject
    compile_opt idl2, hidden

    ; If updates are disabled, mark a pending update
    if(self._iDisable gt 0)then begin
        self._iUpdates or= 4
        return
    end

    ; If we contained the item being destroyed, remove it from the
    ; ourselves. This will also do notification.
    if(self->IsContained(oSubject))then $
      self->Remove, oSubject

    ; If this object is in auto_delete mode? If it is, check the
    ; current status of the items the container contains. If
    ; the container is empty, self-destruct.
    self->getproperty, auto_delete=autoDelete
    if(autoDelete ne 0)then begin
        if(self->Count() eq 0 && self._nRef eq 0)then $
          obj_destroy, self
    endif
end
;---------------------------------------------------------------------------
; IDLitDataContainer::SetAutoDeleteMode
;
; Purpose:
;   When called, this routine will traverse the data hierachy
;   contained in this container and set the Auto_Delete property on
;   all items.
;
; Parameters:
;   bAuto   - The value to set the property.
;

pro IDLitDataContainer::SetAutoDeleteMode, bAuto
   compile_opt hidden, idl2

   self->setproperty, auto_delete=bAuto

   oChild = self->Get(/all, count=nChild)
   for i=0, nChild-1 do begin
       if(obj_isa(oChild[i], "IDLitDataContainer"))then $
         oChild[i]->SetAutoDeleteMode, bAuto $
       else $
         oChild[i]->Setproperty, auto_delete=bAuto
   endfor
end


;---------------------------------------------------------------------------
; IDLitDataContainer::Copy
;
; Purpose:
;  Return a copy of this data container. This includes what this
;  container includes as well as what any of it's children contain.
;
; Return Value:
;   A copy of this data object. If a copy failure occurs, the
;   a null object is returned.

function IDLitDataContainer::Copy
   compile_opt hidden, idl2

   ; Copy thyself.
   oSelfCopy = self->IDLitData::Copy()
   if(not obj_valid(oSelfCopy))then $
     return, obj_new()

   ; Now the contents of the container
   oData = self->IDL_Container::Get(/all, count=nData)

   for i=0, nData-1 do begin
       oDataCopy = oData[i]->Copy()
       if(not obj_valid(oDataCopy))then begin
           obj_destroy, oSelfCopy ;will free the entire copy
           return, obj_new()
       end
       oDataCopy->GetProperty, IDENTIFIER=id
       ; Check to see if the self copy made this sub item during
       ; construction
       oFind = oSelfCopy->Getbyidentifier(id)
       if(obj_valid(oFind))then begin
           oSelfCopy->Remove, oFind
           obj_destroy, oFind
       endif
       oSelfCopy->Add, oDataCopy

   end

   return, oSelfCopy

end
;---------------------------------------------------------------------------
; IDLitDataContainer::GetSize
;
; Purpose:
;   Return the size in bytes of this data container and all its
;   contents.
;
; Return Value:
;   The size contained in this data object and it's sub items in bytes.

function IDLitDataContainer::GetSize
   compile_opt hidden, idl2

   nBytes = self->IDLitData::GetSize(); my size

   ; Now the contents of the container
   oData = self->IDL_Container::Get(/all, count=nData)

   for i=0, nData-1 do begin
       if(obj_valid(oData[i]))then $ ; bad object?
         nBytes += oData[i]->GetSize() $
       else self->IDL_Container::Remove, oData[i]
   endfor
   return, nBytes
end
;---------------------------------------------------------------------------
; IDLitDataContainer::DisableNotify
;
; Purpose:
;   Prevent any notifications from taking place. Any detected
;   notify messages that would be triggered are noted and triggered
;   when EnableNotify is called.
;
pro IDLitDAtaContainer::DisableNotify
    compile_opt hidden, idl2

    self._iDisable++;

end
;---------------------------------------------------------------------------
pro IDLitDataContainer::EnableNotify
   compile_opt hidden

   ; Were we disabled?
   ; Has any data change mesages?

   self._iDisable--
   if(self._iDisable eq 0)then begin ; pending messages?
       if((self._iUpdates and 1) ne 0)then $
         self->IDLitData::NotifyDataChange

       if((self._iUpdates and 2) ne 0)then $
         self->IDLitData::NotifyDataComplete

       if((self._iUpdates and 4) ne 0)then $
         self->IDLitData::NotifyDataDelete
       self._iUpdates =0
   endif
end
;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataContainer__Define
;
; Purpose:
; Class definition of the object
;
pro IDLitDataContainer__Define

    compile_opt idl2, hidden

    void = {IDLitDataContainer,  $
            inherits      IDLitData,       $
            inherits      _IDLitContainer, $
            inherits      IDL_Container,    $
            _iDisable  : 0, $  ; > 0 if we are disabled.
            _iUpdates  : 0, $  ; Used to manage updates
            _bInSearch : 0b $  ; prevent issue with recursion
           }

end



