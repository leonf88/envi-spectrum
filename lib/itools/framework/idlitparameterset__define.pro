; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitparameterset__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitParameterSet
;
; PURPOSE:
;   This file implements the IDLitParameterSet class. This class provides
;   a data container that is aware of data objects stored in it.  It uses
;   data identifiers to locate data objects stored in a data container
;   tree heirarchy.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDlitDataContainer
;
;   See IDLitParameterSet::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitParameterSet::Init
;;
;; Purpose:
;;   The constructor of the IDLitParameterSet object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   All are passed to it's super-class
;;

function IDLitParameterSet::Init,  ICON=ICON,_EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Init superclass
    if(self->IDLitDataContainer::Init(void, ICON=ICON, _EXTRA=_extra) eq 0) then $
        return, 0

    ;; Create the container that is used to manage the names of the
    ;; items contained in this parameter set.
    self._pNames = ptr_new(/allocate)

   return, 1
end

;;---------------------------------------------------------------------------
;; IDLitParameterSet::Cleanup
;;
;; Purpose:
;;    Destructor for the object.
;;
;;
;; Parameters:
;;   None.
pro IDLitParameterSet::Cleanup
    ;; Pragmas
    compile_opt idl2, hidden
    
    ;; first remove all objects that do not belong to self, e.g., were
    ;; added with /preserve_location
    oObjs = self->Get(/ALL)
    FOR i=0,n_elements(oObjs)-1 DO BEGIN
      IF obj_valid(oObjs[i]) THEN BEGIN
        oObjs[i]->GetProperty, _PARENT=parent
        IF (obj_valid(parent) && (parent NE self)) THEN $
          self->remove, oObjs[i]
      ENDIF
    ENDFOR
    
    ;; Cleanup superclass
    self->IDLitDataContainer::Cleanup

    ptr_free, self._pNames
end
;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; IDLitParameterSet::Add
;;
;; Purpose:
;;   Override the add method of the super-class to allow for name
;;   registration when adding to the parameter set.
;;
;; Parameters:
;;    oData   - The data objects being added.
;;
;; Keywords:
;;    PARAMETER_NAME - The names of parameters that are associated
;;                     with the items being added.
;;
;;    PRESERVE_LOCATION - If set, the add will not change the location
;;                        in the tree of the item.
;;
PRO IDLitParameterSet::Add, oData, $
                     PARAMETER_NAME=parameter_name, $
                     PRESERVE_LOCATION=PRESERVE_LOCATION

   compile_opt hidden, idl2

@idlit_on_error2

    ; If no data, or a single null object, quietly return.
    nData = N_ELEMENTS(oData)
    if (~nData || (nData eq 1 && ~OBJ_VALID(oData[0]))) then $
        return

    ; Verify we are being passed data
    if (MIN(OBJ_ISA(oData, 'IDLitData')) eq 0) then $
        MESSAGE, IDLitLangCatQuery('Error:Data:WrongClass')
   ;; do not accept self as an argument. If passed in, just return.
   if (MAX(oData eq self) eq 1) then $
     MESSAGE, IDLitLangCatQuery('Error:Data:NoAddSelf')

   ;; Make a names array
   nNames = n_elements(parameter_name)
   strNames = strarr(nData)
   if(nNames gt 0)then $ ;; copy over the names we have.
       strNames[0] = parameter_name[0:(nData < nNames)-1]

   strNames  = strupcase(strNames)

   ;; Now check for existing names. If they exist, we replace the
   ;; current object at that location.
   for i=0, nData -1 do begin
       ;; collision? Note we skip empty names.
       if (keyword_set(strNames[i]) && n_elements(*self._pNames) gt 0) then $
           dex = where(strNames[i] eq *self._pNames, nMatch) $
       else nMatch=0

       ;; no match, add to the end of the list
       if (~nMatch) then begin
           *self._pNames = (n_elements(*self._pNames) gt 0 ? $
                            [temporary(*self._pNames), strNames[i]] : strNames[i])
            if (N_ELEMENTS(position) eq 1) then $
                void = TEMPORARY(position)
       endif else begin
           oOld = self->IDLitDataContainer::Get(position=dex[0])
           self->IDLitDataContainer::Remove, oOld
           position = dex[0]
       endelse

        ; For PRESERVE_LOCATION we don't want to change the _PARENT so we
        ; bypass all our containers. Unfortunately, this will also
        ; bypass the data observer code, but this is a parameter set
        ; so updates aren't necessary.
        if(keyword_set(PRESERVE_LOCATION))then begin
            self->IDL_Container::Add, oData[i], POSITION=position
        endif else begin
            self->IDLitDataContainer::Add, oData[i], POSITION=position, $
                /OBSERVE_ONLY
        endelse

   endfor

end


;;---------------------------------------------------------------------------
;; IDLitParameterSet::Get
;;
;; Purpose:
;;  Used to retrieve values from the parameter set along with the
;;  names associated with the parameter parameters.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;   ALL       - Return all the parameters and names contained
;;
;;   COUNT     - The number of items returned.
;;
;;   POSITION  - Position of the item to return
;;
;;   NAME[out] - Set to the names of the parameters returned
;;
function IDLitParameterSet::Get, ALL=ALL, POSITION=POSITION, $
                          COUNT=COUNT, NAME=NAME, _EXTRA=_EXTRA

   compile_opt hidden, idl2

   count = self->IDLitDataContainer::Count()
   if(count eq 0)then $
     return, -1

   ;; Handle the name array
   if(keyword_set(ALL))then begin
       NAME = *self._pNames
       return, self->IDLitDataContainer::Get(/all, _extra=_extra, $
                                            count=count)
   endif

   if(keyword_set(position))then begin
       dex = where(position gt -1 and position lt count, count)
       if(count eq 0)then $
           return, -1
       position = position[dex]
   endif else position=0
   NAME = (*self._pNames)[position]
   return, self->IDLitDataContainer::Get(POSITION=POSITION)
end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::GetByName
;;
;; Purpose:
;;  Used to retrieve the data values for parameters with the given
;;  names. This is the names they were registered with, not the names
;;  on the actual objects. This is an important distinction.
;;
;; Parameters:
;;    strNames   - The names of items to return.
;;
;; Keywords:
;;   COUNT[out]  - The number of items returned.
;;
;;   NAME[out]   - The names of the returned items
;;
;; Return Value
;;   Matching items or obj NULL.

function IDLitParameterSet::GetByName, strName, COUNT=COUNT, $
                          NAME=NAME, POSITION=iMatch

   compile_opt hidden, idl2

   count = self->IDLitDataContainer::Count()
   nNames = n_elements(strName)
   if(count eq 0 or nNames eq 0)then $
     return, obj_new()
   tmpNames =strupcase(strName)
   count=0
   for i=0, nNames-1 do begin
       dex = where(tmpNames[i] eq *self._pNames, n)
       if(n gt 0)then begin
           iMatch = (n_elements(iMatch) gt 0 ? [iMatch, dex] : dex)
           count += n
       endif
   endfor
   if(count gt 0) then begin
       NAME = (*self._pNames)[iMatch]
       return, self->IDLitDataContainer::Get(POSITION=iMatch)
   endif else $
     return, obj_new()

end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::GetParameterName
;;
;; Purpose:
;;   Used to get name of the given object.
;;
;; Parameters:
;;    oItems[in]   - The item to check.
;;
;;    strName[out] - The name found
;;
;; Return Value
;;    1 - Success
;;
;;    0 - Not contained
;;
function IDLitParameterSet::GetParameterName, oItem, strName
   compile_opt hidden, idl2

   strName = '' ;; default value

   nItems = n_elements(oItem)
   if(nItems eq 0)then return, 0

   oCon =self->IDL_Container::Get(/all, count=count)
   if(count eq 0)then return, 0

   retVal=0
   for i=0, nItems-1 do begin
       dex = where(oCon eq oItem[i], nMatch)

       if(nMatch gt 0)then begin
           strName = [strName, (*self._pNames)[dex]]
           retVal=1
       endif
   endfor

   if (retVal) then $
    strName = strName[1:*]

  return,retVal
end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::Remove
;;
;; Purpose:
;;  Used to remove values from the parameter set along with the
;;  names associated with the parameter parameters.
;;
;; Parameters:
;;    oItems   - The items to remove
;;
;; Keywords:
;;   ALL       - Remove all items
;;
;;   POSITION  - Position of the item to return
;;
pro IDLitParameterSet::Remove, oItems, ALL=ALL, POSITION=POSITION

   compile_opt hidden, idl2

   count = self->IDLitDataContainer::Count()
   if (~count) then $
     return

   ;; Handle the name array
   if(keyword_set(ALL))then begin
       position = LINDGEN(count)
   endif else begin
       nItems = n_elements(oItems)
       if(nItems eq 0)then begin
           if(keyword_set(position))then begin
               dex = where(position gt -1 and position lt count, count)
               if(count eq 0)then $
                 return
               position = position[dex]
           endif else position=0
       endif else begin
           oContained = self->IDLitDataContainer::get(/all)
           for i=0, nItems-1 do begin
               match = where(oItems[i] eq oContained, nMatch)
               if(nMatch ne 0)then $
                 position = (n_elements(position) gt 0 ? $
                             [position, match[0]] : match[0])
           endfor
           if(n_elements(position) eq 0)then return ;; nothing
       endelse
   endelse


    position = position[SORT(position)]

    ; Must loop in reverse order to retrieve by position.
    for i=N_ELEMENTS(position)-1,0,-1 do begin
        oItem = self->IDL_Container::Get(POSITION=position[i])
        if (OBJ_VALID(oItem)) then begin
            ; If _PARENT is ourself, then PRESERVE_LOCATION was not
            ; set when item was added. In this case, null out the _PARENT.
            oItem->GetProperty, _PARENT=oParent
            if (oParent eq self) then $
                oItem->SetProperty, _PARENT=OBJ_NEW()
        endif
        self->IDL_Container::Remove, POSITION=position[i]
    endfor

   ;; Fix the name array.
   nNames = n_elements(*self._pNames)
   nPos = n_elements(position)
   if(nNames eq nPos)then $
       void = temporary(*self._pNames) $
   else begin
       pos = indgen(nNames)
       pos[position] = -1
       ;; Filter out our names
       *self._pNames  = (*self._pNames)[where(pos ne -1)]
   endelse

end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::AddAuxiliaryData
;;
;; Purpose:
;;   This method is used to add auxiliary data to the parameter
;;   set. Auxiliary data is data that doesn't have a parameter name
;;   associated with it, but is desired to be associated with the
;;   parameter set.
;;
;;   Auxiliary data is stored in the parameter set with other data
;;   values, but with the name associated with it set to ''.
;;
;; Parameters:
;;    oData   - The data objects being added.
;;
;; Keywords:
;;
;;    PRESERVE_LOCATION - If set, the add will not change the location
;;                        in the tree of the item.
;;
PRO IDLitParameterSet::AddAuxiliaryData, oData, $
                     PRESERVE_LOCATION=PRESERVE_LOCATION

   compile_opt hidden, idl2

   ;; Just call the add method with name = ''

   self->IDLitParameterSet::Add, oData, $
                            PRESERVE_LOCATION=PRESERVE_LOCATION
end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::GetAuxiliaryData
;;
;; Purpose:
;;   This method will return auxiliary data that is contained in this
;;   parameter set. Auxiliary data is determined by those items with
;;   names marked as ''.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   COUNT[out]  - The number of items returned.
;;
;; Return Value
;;   The auxiliary data items  or obj NULL if none are contained

function IDLitParameterSet::GetAuxiliaryData, COUNT=COUNT
   compile_opt hidden, idl2

   return, self->IDLitParameterSet::GetByName('', count=count)
end
;;---------------------------------------------------------------------------
;;  IDLitParameterSet::Copy
;;
;; Purpose:
;;   When called, this routine will return a copy this object and it's
;;   contents.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   None.
;;
;; Return Value:
;;   The
function IDLitParameterSet::Copy
   compile_opt hidden, idl2

   ;; First, copy self using the superclass.

    oCopy = self->IDLitDataContainer::Copy()

    ;; Now we need to copy over the names.
    oCopy->_CopyDataNames, self

    return, oCopy
end
;;---------------------------------------------------------------------------
;; IDLitParameterSet::_SetDataNames
;;
;; Purpose:
;;    Internal routine used to set the names of the parameters
;;    contained in this object. Primarly used during a copy action
;;
;; Parameters:
;;    oSource   - the parameter set to take the names from
;;
PRO IDLitParameterSet::_CopyDataNames, oSource
    compile_opt hidden, idl2

    if(not obj_isa(oSource, "IDLitParameterSet"))then return

    oVoid = oSource->get(/all, name=names, count=count)

    if(count gt 0)then $
      *self._pNames = Names

end
;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitParameterSet__Define
;;
;; Purpose:
;; Class definition of the object
;;
pro IDLitParameterSet__Define
    ;; Pragmas
    compile_opt idl2, hidden

    void = {IDLitParameterSet,  $
            inherits      IDLitDataContainer,       $
            _pNames     : ptr_new() $ ;used to store names.
           }

end



