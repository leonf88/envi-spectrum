; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitdata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitData class. This class is used to store
;   IDL core data types.
;

;;---------------------------------------------------------------------------
;; Lifecycle Routines

;;----------------------------------------------------------------------------
;; IDLitData::_RegisterProperties
;;
;; Purpose:
;;   Internal routine that will register all properties supported by
;;   this object.
;;
;; Keywords:
;;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;;     component version from which this object is being updated.  Only
;;     properties that need to be registered to update from this version
;;     will be registered.  By default, all properties associated with
;;     this class are registered.
;;
PRO IDLitData::_RegisterProperties, $
  UPDATE_FROM_VERSION=updateFromVersion

  compile_opt idl2, hidden

  registerAll = ~KEYWORD_SET(updateFromVersion)

  IF (registerAll) THEN BEGIN

    self->RegisterProperty, 'Hide', /BOOLEAN, $
                            DESCRIPTION='Hide data from Identifier searches', $
                            /HIDE

    self->RegisterProperty, 'READ_ONLY', /BOOLEAN, $
                            NAME='Read only', $
                            DESCRIPTION='Data is read-only'

    self->RegisterProperty, 'Type', /STRING, $
                            NAME='Type', $
                            DESCRIPTION='Parameter Type', $
                            SENSITIVE=0

  ENDIF

  IF (registerAll || (updateFromVersion LT 610)) THEN BEGIN

    self->RegisterProperty, 'DATA_TYPE', $
                            ENUMLIST=['UNDEFINED','BYTE','INT','LONG', $
                                      'FLOAT','DOUBLE','COMPLEX', $
                                      'STRING','STRUCT','DCOMPLEX', $
                                      'POINTER','OBJREF','UINT','ULONG', $
                                      'LONG64','ULONG64'], $
                            NAME='Data type', $
                            DESCRIPTION='Data Type', $
                            SENSITIVE=0

  ENDIF

  IF (registerAll) THEN BEGIN

    self->RegisterProperty, 'N_DIMENSIONS', /INTEGER, $
                            NAME='Number of dimensions', $
                            DESCRIPTION='Number of dimensions', $
                            SENSITIVE=0


  ENDIF

  IF (registerAll || (updateFromVersion LT 610)) THEN BEGIN

    self->RegisterProperty, 'DIMENSIONS', USERDEF='', $
        NAME='Dimensions', $
        DESCRIPTION='Number of elements in each dimension', $
        SENSITIVE=0

    IF ptr_valid(self._pData) THEN $
      self->SetPropertyAttribute,'DIMENSIONS', $
        USERDEF=strjoin(strtrim(size(*self._pData,/dim),2),', ')

    self->RegisterProperty, 'DATA_OBSERVERS', $
                            ENUMLIST=[''], $
                            NAME='Data used by', $
                            DESCRIPTION='Data observers', $
                            SENSITIVE=1
  ENDIF

END

;;---------------------------------------------------------------------------
;; Purpose:
;; The constructor of the IDLitData object.
;;
;; Parameters:
;; Data - The (optional) data to store in the object.
;;
;; Properties:
;;   TYPE - A string describing the type of the data.
;;          The default is "".
;;          At the user level this property can be set only at Init.
;;
;;   NO_COPY   - The original data is used: a copy is not made.
;;
;;   NAME      - The name to be associated with this data object.
;;
;;   See SetProperty for rest of the properties

function IDLitData::Init, Data, TYPE=type, NO_COPY=NO_COPY, $
                                NAME=NAME, _EXTRA=_extra


    compile_opt idl2, hidden

@idlit_on_error2
@idlit_catch
    ; Catch any errors, usually from the ::SetData.
    if(iErr ne 0)then begin
        CATCH,/cancel
        self->Cleanup
        MESSAGE, /REISSUE_LAST
        return, 0
    endif

    if(not keyword_set(NAME))then name="Data"
    ;; Init superclass
    if(self->IDLitComponent::Init(name=name, _EXTRA=_extra) eq 0)then $
        return, 0

    ;; Start up the Notifier
    self._oNotifier = obj_new('IDLitNotifier')

    ;; Initialize ourself
    self._pData = ptr_new(/ALLOC)

    ;; List of auto-desctruct observers
    self._pDestruct = ptr_new(/allocate)

    ;; Create the internal storage for the meta data.
    self._pMetaData = ptr_new(/allocate_heap)

    ;; Register properties
    self->IDLitData::_RegisterProperties

    ; Do not specify our classname when calling SetData, so that
    ; our subclass will get called.
    if(n_elements(Data) ne 0) then begin
        iStatus = self->SetData(Data, NO_COPY=keyword_set(NO_COPY))
        if(iStatus eq 0)then begin
            self->Cleanup
            return,0
        endif
    endif

    ;; Process properties
    ;; TYPE is only setable at init time
    if(n_elements(type) ne 0) then $
        self._type = type

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitData::SetProperty, _EXTRA=_EXTRA

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitData::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro IDLitData::Cleanup

    compile_opt idl2, hidden

    ;; get all visualization observers
    ;; We have to get the observers whilst the list still exists but
    ;; we do the notifications below after we have killed most of
    ;; ourself otherwise we still appear valid
    oObservers = self._oNotifier->GET(/ALL,ISA='IDLitVisualization')

    ;; Notify our observers this object is dying
    if (OBJ_VALID(self._oNotifier)) then begin
        self._oNotifier->Notify, self, CALLBACK="OnDataDelete"
        obj_destroy, self._oNotifier
    endif

    ;; Close down
    self->_FreeItem, *self._pData
    ptr_free, self._pData

    ptr_free ,self._pDestruct

    self->IDLitData::ClearMetaData
    ptr_free, self._pMetaData

    ;; now we can send messages to update vis trees
    IF obj_valid(oObservers[0]) THEN BEGIN
      ;; notify anything displaying the data that something has changed
      oSys = _IDLitSys_GetSystem(/NO_CREATE)
      IF obj_valid(oSys) THEN $
        FOR i=0,n_elements(oObservers)-1 DO $
        oSys->DoOnNotify,oObservers[i]->GetFullIdentifier(),'UPDATEITEM',''
    ENDIF

    ;; Cleanup superclass
    self->IDLitComponent::Cleanup

end

;;----------------------------------------------------------------------------
;; IDLitData::Restore
;;
;; Purpose:
;;   This procedure method performs any cleanup work required after
;;   an object of this class has been restored from a save file to
;;   ensure that its state is appropriate for the current revision.
;;
PRO IDLitData::Restore
  compile_opt idl2, hidden

  ;; Call superclass restore.
  self->IDLitComponent::Restore

  ;; Register new properties.
  Self->IDLitData::_RegisterProperties, $
    UPDATE_FROM_VERSION=self.idlitcomponentversion

END

;;---------------------------------------------------------------------------
;; IDLitData::_GetTypeDescription
;;
;; Purpose:
;;   Will return a string that describes the shape and type of the
;;   data contains in this object. If nothing is contained, a empty
;;   string is returned.
;;
;; Parameters:
;;   None.
;;
function IDLitData::_GetTypeDescription
   compile_opt hidden, idl2

   vInfo = size(*self._pData, /structure)

   if(vInfo.type eq 0)then return, ''

   if(vInfo.n_elements le 1)then $
     return, vInfo.type_name

    return, vInfo.type_name+"[" + string( vInfo.Dimensions[0:vInfo.n_dimensions-1], $
                                          format="(8( i0,:, ',' ))") + "]"
end

;;---------------------------------------------------------------------------
;; Property Management
;;---------------------------------------------------------------------------
;; IDLitData::GetProperty
;;
;; Purpose:
;;   Used to get the value of the properties associated with this class.
;;
;; Keywords:
;;    HIDE - Hide the data
;;
;;    N_DIMENSIONS - Get the number of the data dimensions
;;
;;    READ_ONLY    - Mark the data as read only
;;
;;    TYPE         - Set the type of the data object
;;
;;    DESCRIPTION  - Get the description of the data
;;
;;    AUTO_DELETE  - If set, this data object will delete itself if
;;                   the number of observers to this object
;;                   transisions from 1 to 0.
;;
pro IDLitData::GetProperty, HIDE=hide, $
                            N_DIMENSIONS=nDimensions, $
                            READ_ONLY=read_only, $
                            TYPE=type, $
                            DESCRIPTION=DESCRIPTION, $
                            AUTO_DELETE=AUTO_DELETE, $
                            DATA_TYPE=datatype, $
                            DIMENSIONS=dimensions, $
                            DATA_OBSERVERS=dataObs, $
                            _REF_EXTRA=_super

    compile_opt idl2, hidden

    ;; Hide this data
    if(arg_present(hide))then $
        hide =  self._hide

    ;; n Dims
    if (ARG_PRESENT(nDimensions)) then $
        nDimensions =  SIZE(*self._pData, /N_DIMENSIONS)

    ;; Read only
    if(arg_present(read_only))then $
        read_only =  self._read_only

    ;; parameter type
    if(arg_present(type))then $
        type =  self._type

    ;; data type
    if(arg_present(datatype))then $
        datatype =  size(*self._pData,/type)

    ;; dimensions
    if(arg_present(dimensions))then $
        dimensions =  size(*self._pData,/dimensions)

    ;; data observers
    if(arg_present(dataObs))then $
        dataObs = 0

    ;; If no description is present, make one that is based on the
    ;; objects contents.
    if(arg_present(DESCRIPTION))then begin
        self->IDLitComponent::GetProperty, DESCRIPTION=DESCRIPTION
;         if(not keyword_set(DESCRIPTION))then $
;           DESCRIPTION=self->_GetTypeDescription()
    endif

    ;; Current auto-delete settings
    if(arg_present(AUTO_DELETE))then $
      auto_delete = self._autoDelete

    ;; Call the superclass
    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::GetProperty, _EXTRA=_super

end

;;---------------------------------------------------------------------------
;; IDLitData::SetProperty
;;
;; Purpose:
;;   Used to set the value of the properties associated with this class.
;;
;; Properties:
;;   HIDE - A Boolean that when true prevents this object from being found
;;          by an Identifier search.
;;
;;   READ_ONLY - A Boolean that when true prevents the SetData method from
;;               modifying the data.
;;
;;   TYPE  - The type of this data
;;
;;   AUTO_DELETE  - If set, this data object will delete itself if
;;                   the number of observers to this object
;;                   transisions from 1 to 0.

pro IDLitData::SetProperty, HIDE=hide, $
                            READ_ONLY=read_only, $
                            TYPE=type, $
                            AUTO_DELETE=AUTO_DELETE, $
                            _EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(hide) ne 0)then $
        self._hide = hide

    if(n_elements(read_only) ne 0)then $
        self._read_only = read_only

    if(n_elements(type) gt 0)then $
        self._type = type

    if(n_elements(auto_delete) gt 0)then $
      self._autoDelete = keyword_set(auto_delete)

    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::SetProperty, _EXTRA=_super
end

;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; IDLitData::GetData
;;
;; Purpose:
;;   Copies the object's data to the caller.
;;
;;
;; Parameters:
;;    Data   - Output variable that will contain the target data.
;;
;;    Ident  - Not used. If set, this is an error and 0 is returned.
;;
;; Keywords:
;;     NAN: Set this keyword to a named variable in which to return
;;          a value of 1 if the Data contains any non-finite values
;;          (either NaN or Infinity) or a 0 otherwise.
;;
;;     NO_COPY    - If set, internal value is returned, not a copy
;;
;;     POINTER    - If set, the internal pointer used to store the
;;                  data contained in this object is returned by this
;;                  method. Use of this mode of operation is intended
;;                  for situations where it is undesirable to remove
;;                  the data from the object (via NO_COPY) and a copy
;;                  of the internal data is not desired.
;;
;;                  Use if this keyword should be limited do to
;;                  potential side-effects.
;;
;; Return Value:
;;   1 if successful, 0 if not.
;;   The operation fails of the Data argument is not supplied or if the object
;;   is empty.

function IDLitData::GetData, Data, Ident, $
    NAN=nan, $
    NO_COPY=NO_COPY, $
    POINTER=ptr

    compile_opt idl2, hidden

@idlit_on_error2

    nan = 0

    if (~arg_present(Data) || keyword_set(Ident)) then $
        return, 0

    ; If NAN keyword is present, see if we have any non-finite values.
    if (ARG_PRESENT(nan)) then begin
        switch SIZE(*self._pData, /TYPE) of
            4: ; float, fall thru
            5: ; double, fall thru
            6: ; complex, fall thru
            9: begin  ; double complex
                ; Using ARRAY_EQUAL with a scalar will immediately bail
                ; if a non-finite value is found, which is nice.
                nan = ~ARRAY_EQUAL(FINITE(*self._pData), 1)
                break
               end
            else: begin
                nan = 0b
                break
               end
        endswitch
    endif

    if (keyword_set(ptr)) then begin
        data = self._pData
    endif else begin
        if (~N_ELEMENTS(*self._pData)) then $
          return, 0
        Data = (KEYWORD_SET(NO_COPY) && ~self._read_only) ? $
            TEMPORARY(*self._pData) : *self._pData
    endelse

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitData::SetData
;;
;; Purpose:
;;   Stores the caller's data into the object
;;
;; Parameters:
;;    Data      - The data item to store.
;;
;;    Ident     - This is not used, but part of the set data
;;                inteface.
;;
;; Keywords:
;;    NO_COPY   - The original data is used: a copy is not made.
;;
;;    NULL      - If set, the value of the data object is clear out
;;                and set to "NULL"
;;
;; Return Value:
;;   1 if successful, 0 if not.
;;   The operation fails if the data is read-only

function IDLitData::SetData, Data, Ident,  NO_COPY=no_copy, NULL=null, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

@idlit_on_error2

    if(keyword_set(Ident))then return, 0
    if(self._read_only) then begin
      Message, IDLitLangCatQuery('Message:Framework:DataReadOnly'), $
               /CONTINUE
      return, 0
    endif

    ;; If null is set, just zero out everything.
    if(keyword_set(null) ne 0) then begin
        if (N_ELEMENTS(*self._pData) gt 0) then begin
            self->_freeItem, *self._pData
            void = temporary(*self._pData)
            void = 0
        endif
        self->SetPropertyAttribute, 'DIMENSIONS', USERDEF=''
    endif else if(n_elements(Data) ne 0) then BEGIN
        ;; If data is an object and equal to self return
        if(size(data, /type) eq 11)then begin
            dx = where(data eq self, nSelf)
            if(nSelf gt 0)then return,0
        endif
        ;; Set the data
        self->_freeItem, *self._pData ;; clear out old item
        self->SetPropertyAttribute,'DIMENSIONS', $
          USERDEF=strjoin(strtrim(size(Data,/dim),2),', ')
        *self._pData = keyword_set(no_copy) ? temporary(Data) : Data
    endif else begin
        MESSAGE, 'Incorrect number of arguments.'
    endelse

    if (~KEYWORD_SET(noNotify)) then begin
        self->NotifyDataChange
        self->NotifyDataComplete
    endif

    ;; notify anything displaying the data that something has changed
    oSys = _IDLitSys_GetSystem(/NO_CREATE)
    myid = self->GetFullIdentifier()
    ; Make sure we're part of the hierarchy.
    IF (obj_valid(oSys) && STRLEN(myid) gt 1) THEN $
      oSys->DoOnNotify, myid, 'SETPROPERTY', ''

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitData::GetByType
;;
;; Purpose:
;;   Return the object if it matches the given type

function IDLitData::GetByType, strTypes, COUNT=COUNT


    compile_opt idl2, hidden

    COUNT=0

    if(not keyword_set(strTypes))then $
      return, obj_new()
    self->GetProperty, TYPE=myType
    void = where(strcmp(strTypes, myType, /FOLD_CASE) gt 0, count)
    return, (count gt 0 ? self : obj_new())
end

;;---------------------------------------------------------------------------
;; IDLitData::GetTypes
;;
;; Purpose:
;;   Return the types supported by this object. This includes any
;;   base types and specializations.
;;
function IDLitData::GetTypes


    compile_opt idl2, hidden

    return, ['DATA', self._type]

end

;----------------------------------------------------------------------------
; IIDLDataNotifier Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitData::AddDataObserver
;
; PURPOSE:
;       The IDLitData::AddDataObserver procedure method adds the specified
;       observer object to this object's list of observers
;
; CALLING SEQUENCE:
;       oData->[IDLitData::]AddDataObserver, oObserver
;
; INPUTS:
;       oObserver - An IDL Component Data object that implements
;       the IIDLDataObserver interface
;
; KEYWORD PARAMETERS:
;    OBSERVE_ONLY  - If set, this object is just observing the state
;                    of the object and should not be taken into
;                    account as part of the auto_delete mechanism
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-

pro IDLitData::AddDataObserver, oObserver, OBSERVE_ONLY=OBSERVE_ONLY, $
             _REF_EXTRA=super

    compile_opt idl2, hidden

    ; Simply return if arg not specified.
    if N_ELEMENTS(oObserver) eq 0 then RETURN

    ; Cannot add ourself to the observer list.
    if oObserver eq self then $
        return

    ; Check to see if observer implements IIDLDataObserver interface.
    if( OBJ_HASMETHOD(oObserver, ["OnDataChange", $
                                  "OnDataComplete", "OnDataDelete"]) eq 0)then $
      return

    ; Add the observer to the Notifier's list
    self._oNotifier->Add, oObserver
    if(~keyword_set(OBSERVE_ONLY))then begin
        ;; The object maintains a list of the items that are part of
        ;; the auto-destruct list. Add this new observer to this.
        *self._pDestruct = (self._nRef eq 0 ? oObserver : $
                            [*self._pDestruct, oObserver])
        self._nRef++
    endif

    ;; update data observer property
    self->_SetDataObservers

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitData::RemoveDataObserver
;
; PURPOSE:
;       The IDLitData::RemoveDataObserver procedure method removes the specified
;       observer object from this object's list of observers
;
; CALLING SEQUENCE:
;       oData->[IDLitData::]RemoveDataObserver, oObserver
;
; INPUTS:
;       oObserver - An IDL Component Data object that implements
;       the IIDLDataObserver interface
;
; KEYWORD PARAMETERS:
;       NO_AUTODELETE - If set, remove the observer from the notifier list
;       without performing the autodelete.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-

pro IDLitData::RemoveDataObserver, oObserver, $
    NO_AUTODELETE=noAutodelete, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    ;; Simply return if observer is not specified or invalid.
    if(N_ELEMENTS(oObserver) eq 0 || $
        ~OBJ_VALID(oObserver))then return

    ;; Remove the observer from the Notifier's list
    self._oNotifier->Remove, oObserver

    if(~KEYWORD_SET(noAutodelete))then begin
        ;; Auto delete logic
        if(self._nRef gt 0)then begin
            ;; Is this observer in the Delete list?
            ; Only remove the first instance of it.
            iDel = (WHERE(oObserver eq *self._pDestruct))[0]
            if (iDel ge 0) then begin ;; Yep, it's in the list
                if(self._nRef eq 1 && self._autoDelete)then begin;; die
                    OBJ_DESTROY, self
                    return
                endif
                if (self._nRef gt 1) then begin
                    *self._pDestruct = $
                        (*self._pDestruct)[WHERE(LINDGEN(self._nRef) ne iDel)]
                endif else   $
                    void = TEMPORARY(*self._pDestruct)
                self._nRef--
            endif
        endif
    endif

    ;; update data observer property
    self->_SetDataObservers

end

;----------------------------------------------------------------------------
;; IDLitData::GetDataObservers
;;
;; Purpose:
;;    The IDLitData::NotifyDataChange procedure method returns all the
;;    observers currently watching this data item
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;    None.

FUNCTION IDLitData::GetDataObservers,  _REF_EXTRA=super
  compile_opt idl2, hidden

  ;; get from the notifier
  return, self._oNotifier->GET(_EXTRA=super)

END

;;---------------------------------------------------------------------------
;; IDLitData::_SetDataObservers
;;
;; Purpose:
;;   Updates the DATA OBSERVER property when observers are added or
;;   removed
;;
PRO IDLitData::_SetDataObservers
  compile_opt idl2, hidden

  oObservers = self._oNotifier->GET(/ALL,ISA='IDLitVisualization')
  textStr = ''
  IF obj_valid(oObservers[0]) THEN BEGIN
    FOR i=0,n_elements(oObservers)-1 DO BEGIN
      oObservers[i]->GetProperty,NAME=visName
      oTool = oObservers[i]->GetTool()
      if (~OBJ_VALID(oTool)) then $
        continue
      oTool->IDLitComponent::GetProperty, NAME=toolName
      obsIDstr = '   ('+oObservers[i]->GetFullIdentifier()+')'
      textStr = $
        i EQ 0 ? [toolName+' : '+visName+obsIDstr] : $
        [textStr,toolName+' : '+visName+obsIDstr]
    ENDFOR
  ENDIF
  self->SetPropertyAttribute,'DATA_OBSERVERS',ENUMLIST=textStr, $
                             SENSITIVE=textStr[0] NE ''

  ;; notify anything displaying the data that something has changed
    oSys = _IDLitSys_GetSystem(/NO_CREATE)
    myid = self->GetFullIdentifier()
    ; Make sure we're part of the hierarchy.
    IF (obj_valid(oSys) && STRLEN(myid) gt 1) THEN $
        oSys->DoOnNotify, myid, 'SETPROPERTY', 'DATA_OBSERVERS'

END

;----------------------------------------------------------------------------
;; IDLitData::NotifyDataChange
;;
;; Purpose:
;;    The IDLitData::NotifyDataChange procedure method notifies all observers
;;     in this object's observer list that they need to update their data.
;;
;; Parameters:
;;    None.
;;
;; Keywords:
;;    None.

pro IDLitData::NotifyDataChange,  _REF_EXTRA=super

    compile_opt idl2, hidden

    ;; Send OnDataChange message to all observers
    self._oNotifier->Notify, self, CALLBACK="OnDataChange"
end

;;----------------------------------------------------------------------------
;; IDLitData::NotifyDataComplete
;;
;; Purpose
;;     The IDLitData::NotifyDataComplete procedure method notifies all
;;     observers in this object's observer list that the data change
;;     has been completed.
;;
;; Parameters:
;;     None.
;;
;; Keywords:
;;     None.
pro IDLitData::NotifyDataComplete, _REF_EXTRA=super

    compile_opt idl2, hidden

    ;; Send OnDataComplete message to all observers
    self._oNotifier->Notify, self, CALLBACK="OnDataComplete"

end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method notifies all observers
;   in this object's observer list that they need to delete their data.
;
; Parameters:
;   None.
;
; Keywords:
;   None.
;
pro IDLitData::NotifyDataDelete,  _REF_EXTRA=super

    compile_opt idl2, hidden

    ; Send message to all observers.
    self._oNotifier->Notify, self, CALLBACK="OnDataDelete"
end


;;---------------------------------------------------------------------------
;; Meta Data Implementation
;;
;; Purpose:
;; This section implements a meta-data dictionary that can be used by
;; the system. This simple system is in place to allow items that
;; describe the data that is contained be associated with this object.
;;
;; Meta data is a name-value pair.
;;---------------------------------------------------------------------------
;; IDLitData::AddMetaData
;;
;; Purpose:
;;    Used to add a meta-data item to this data object. If the item
;;    already exists, it is over written.
;;
;; Parameters:
;;    strItem  - The string identifier/key for this item. This is
;;               case insensitive.
;;    Item     - The value of the meta data. This can be anything.
;;

PRO IDLitData::AddMetaData, strItem, Item
   ;; Pragmas
   compile_opt idl2, hidden

   ;; check for a blank name
   if(~keyword_set(strItem) || n_elements(Item) eq 0)then $
     return

   ;; Cannot place self in the meta data.
   if(size(Item, /type) eq 11)then begin
       dex = where(Item eq self, nSelf)
       if(nSelf gt 0)then return
   endif

   upName = STRUPCASE(strItem)
   ;; Do we have items already? If so, check for an exising
   ;; item of the same name.
   if(n_elements(*self._pMetaData) gt 0)then begin
       idx = where((*self._pMetaData).strName eq upName)
       if(idx[0] gt -1)then begin ;; replace values
           *((*self._pMetaData)[idx[0]].pData) = Item
           return
       endif
   endif

   ;; Ok, create the data record

   sData = {_IDLitMetaDataRec_t, upName, ptr_new(Item)}

  if(n_elements(*self._pMetaData) eq 0)then $
     *self._pMetaData = temporary(sData) $
  else $
     *self._pMetaData = [temporary(*self._pMetaData), temporary(sData)]
end
;;---------------------------------------------------------------------------
;; IDLitData::GetMetaData
;;
;; Purpose:
;;   Used to get a meta data item to this data object.
;;
;; Parameters:
;;   strItem[in]  - The item name to retrieve
;;
;;   Item[out]    - The retreived item.
;;
;; Return Value:
;;    0 - Error
;;    1 - Success
;;
function IDLitData::GetMetaData, strItem, Item
   ;; Pragmas
   compile_opt idl2, hidden

   ;; check for a blank name
   if(not keyword_set(strItem))then $
     return, 0

   ;; Is the dictionary empty
   if(n_elements(*self._pMetaData) eq 0)then $
     return, 0

   idx = where((*self._pMetaData).strName eq strupcase(strItem))
   if(idx[0] eq -1)then $ ;;
     return, 0

   Item = *(*self._pMetaData)[idx[0]].pData
   return, 1
end
;;---------------------------------------------------------------------------
;; IDLitData::GetMetaDataCount()
;;
;; Purpose:
;;   Returns the number of meta data items associated with this data
;;   object.
;;
;; Parameters
;;     None.
;;
;; Return Value
;;    The number of Meta Data items contained.
;;
function IDLitData::GetMetaDataCount
   compile_opt hidden, idl2

   return, n_elements(*self._pMetaData)
end
;;---------------------------------------------------------------------------
;; IDLitData::GetMetaDataNames
;;
;; Purpose:
;;    Use this function to retireve the names of the meta data items
;;    contained.
;;
;; Parameters
;;    none
;;
;; Keywords:
;;   COUNT [out] - The number of names returned
;;
;; Return Value
;;  The names of the meta data contained in this object.
;;  or '' if nothing is contained.
function IDLitData::GetMetaDataNames, COUNT=COUNT
   ;; pragmas.
   compile_opt hidden, idl2

   COUNT = n_elements(*self._pMetaData)
   return, (COUNT gt 0 ? (*self._pMetaData).strName: '')

end
;;---------------------------------------------------------------------------
;; IDLitData::ClearMetaData
;;
;; Purpose:
;;   Use this method to reset or clear out all meta data associated
;;   with this data object.
;;
;; Parameters
;;    none
;;
;; Keywords:
;;    none.
;;
pro IDLitData::ClearMetaData
   ;; pragmas.
   compile_opt hidden, idl2

   ;; Is the dictionary empty
   if(n_elements(*self._pMetaData) eq 0)then $
     return

   recMeta = temporary(*self._pMetaData)

   ptr_free, recMeta.pData

end
;;---------------------------------------------------------------------------
;; IDLitData::_FreeData
;;
;; Purpose:
;;   Private routine used to release all resources related to the
;;   given data item, traversing structs and chasing pointers.
;;
;;   Note: objects are not destroyed.
;;
;; Parameters:
;;    Item      - The item to free
;;

pro IDLitData::_FreeItem, Item
   compile_opt hidden, idl2

   ;; Get the type of the item
   case size(Item, /type) of

       8: begin                                 ; struct
            ; Don't need to loop over struct arrays since
            ; IDL will pull out arrays over tags.
            for j=0, N_TAGS(Item[0])-1 do $ ;free fields
                self->_FreeItem, Item.(j)
          end

       10: begin                                ; pointer
            ; Loop thru pointer array
            for i=0,N_ELEMENTS(Item)-1 do begin
                if (ptr_valid(Item[i])) then $
                    self->_FreeItem,  *Item[i]
            endfor
            ptr_free, Item   ; free array of ptrs all at once
           end

       else:  ; do nothing

   endcase

end


;;---------------------------------------------------------------------------
;; IDLitData::_CopyItem
;;
;; Purpose:
;;   Private routine used to copy the contents of the data object,
;;   traversing structs and chasing pointers.
;;
;;   Note: objects are not copied, the references are just assigned to
;;   the copy value
;; Parameters:
;;    Item      - The item to copy
;;
;;    ItemCopy  - The copy of the item
;;
;; Return Value:
;;   1 - Success
;;   0 - Unable to copy
;;
function IDLitData::_CopyItem, Item, ItemCopy
   compile_opt hidden, idl2

   ;; Get the type of the item
   case size(Item, /type) of

       0 : return, 0  ;; undefined

       8 : begin ;; struct
           ItemCopy = Item ;; copy over the struct
           for i=0, n_tags(ItemCopy)-1 do begin ;copy fields
                if (~self->_CopyItem( ItemCopy.(i), tmpCopy)) then begin
                    ;; cleanup any data allocated in this loop
                    self->_FreeItem, ItemCopy
                    return, 0
                endif
                ItemCopy.(i) = TEMPORARY(tmpCopy)
           endfor
           end

       10: begin  ;; pointer
            ItemCopy = Item  ; make a copy to get the dimensions correct
            for i=0,N_ELEMENTS(Item)-1 do begin
                if (PTR_VALID(Item[i]) && N_ELEMENTS(*Item[i])) then begin
                    if (~self->_CopyItem(*Item[i], tmpCopy)) then begin
                        ;; cleanup any data allocated in this loop
                        self->_FreeItem, ItemCopy
                        return,0
                    endif
                    ItemCopy[i] = PTR_NEW(tmpCopy, /NO_COPY)
                endif else $
                    ItemCopy[i] = PTR_NEW()
            endfor
           end

       else: ItemCopy = Item ;; just copy the item over

   endcase

   return,1

end


;;---------------------------------------------------------------------------
;; IDLitData::Copy
;;
;; Purpose:
;;   This routine will build and return a copy of the data
;;   object. This includes a copy of the data contained in the object
;;   and the meta data associted with the object.
;;
;;   The copy doesn't preserve any notification relationships
;;
;; Return Value:
;;   A copy of the data object.

function IDLitData::Copy
   compile_opt hidden, idl2

@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       ;; roll back the object copy
       if(obj_valid(oCopy))then $
         obj_destroy, oCopy
       return, obj_new()
   endif

   oCopy = obj_new(obj_class(self))

   if(n_elements(*self._pData) gt 0)then begin
       status = self->_CopyItem(*self._pData, data_copy)
       if(status eq 0)then begin
           obj_destroy,oCopy
           return, obj_new()
       endif
       status = oCopy->SetData( data_copy, /no_copy) ;; copy data
   endif
   ;; Okay, now copy over properties

   strProps = oCopy->QueryProperty()
   for i=0, n_elements(strProps)-1 do begin
       if(self->GetPropertyByIdentifier(strProps[i], value))then $
           oCopy->SetPropertyByIdentifier, strProps[i], value
   endfor
   ;; copy over the identifier
   self->GetProperty, identifier=identifier, icon=icon, private=private
   oCopy->SetProperty, identifier=identifier, icon=icon, private=private

   nMeta = n_elements(*self._pMetaData)
   for i=0, nMeta-1 do begin
       oCopy->AddMetaData, (*self._pMetaData)[i].strName, $
         *((*self._pMetaData)[i].pData)
   end

   return, oCopy
end
;;---------------------------------------------------------------------------
;; IDLitData::GetSize
;;
;; Purpose:
;;   Return the size in bytes of the data contained in this
;;   object. This will includes the meta data stored in the system.
;;
;; Return Value:
;;   The size contained in this data object in bytes.

function IDLitData::GetSize
   compile_opt hidden, idl2

   nBytes = (n_elements(*self._pData) gt 0 ? $
             IDLitGetItemSize(*self._pData) : 0)
   nMeta = n_elements(*self._pMetaData)
   for i=0, nMeta-1 do begin
       if(n_elements((*self._pMetaData)[i].pData) gt 0)then $
         nBytes  +=  IDLitGetItemSize(*(*self._pMetaData)[i].pData)
   endfor
   return, nBytes
end
;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitData__Define
;;
;; Purpose:
;; Class definition for the IDLitData class
;;

pro IDLitData__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitData, $
          inherits   IDLitComponent,    $
          _oNotifier    : obj_new(),    $
          _pData        : ptr_new(),    $
          _pMetaData    : ptr_new(),    $
          _type         : '',           $
          _autoDelete   : 0b,           $
          _nRef         : 0,            $
          _pDestruct    : ptr_new(),    $
          _hide         : 0b,           $
          _read_only    : 0b            $
         }

   ;; Define our internal dictionary structure
   void = {_IDLitMetaDataRec_t, $
           strName : "", $
           pData   : ptr_new() }

end
