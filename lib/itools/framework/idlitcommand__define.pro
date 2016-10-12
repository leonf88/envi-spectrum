; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitcommand__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitCommand
;
; PURPOSE:
;   This file defines and implements the generic IDL tool command
;   object which is used to manage and store undo-redo
;   information.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitCommand::Init
;
; METHODS:
;
; INTERFACES:
; IIDLProperty
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitCommand::Init
;
; Purpose:
;   Constructor for the command object
;
; Parameters:
;   None.
;
; Keywords:
;   All keywords are passed to the superclass and to SetProperty.
;
function IDLitCommand::Init, _REF_EXTRA=_extra

   compile_opt idl2, hidden

    if (~self->IDLitComponent::Init(_EXTRA=_extra)) then $
        return, 0

    ; Create the internal data dictionary...just a pointer
    self._pDataDictionary = ptr_new(/allocate_heap)

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitCommand::SetProperty, _EXTRA=_extra

    return,1
end


;---------------------------------------------------------------------------
; IDLitCommand::Cleanup
;
; Purpose:
;  Destructor. Will release any data associated with this object.
;
PRO IDLitCommand::Cleanup

   compile_opt idl2, hidden

   self->IDLitComponent::Cleanup

   ; Cleanup our data list.
   if (ptr_valid(self._pDataDictionary)) then begin
       self->IDLitCommand::_ResetDataList
       ptr_free, self._pDataDictionary
   endif

end


;---------------------------------------------------------------------------
; IDLitCommand::_ResetDataList
;
; Purpose:
;  Internal routine to wipe out the current data list. Just nuke
;  it. The pointer that holds this list is not released.
;
; Parameters:
;   None.
;
; Keywords:
;   None.
;
pro IDLitCommand::_ResetDataList

    compile_opt idl2, hidden

    ; Do not bother to free the DataDictionary itself,
    ; just the contents.
    for i=0,n_elements(*self._pDataDictionary)-1 do begin
        pData = (*self._pDataDictionary)[i].pData
        case SIZE(*pData, /TYPE) of
        8: HEAP_FREE, *pData    ; struct
        10: HEAP_FREE, *pData   ; pointer
        11: OBJ_DESTROY, *pData ; object
        else: ; do nothing
        endcase
        PTR_FREE, pData
    endfor

end


;---------------------------------------------------------------------------
; IDLitCommand::GetProperty
;
; Purpose:
;   Used to access property values for the object.
;
; Keywords
;   TARGET_IDENTIFIER   - The identifier to the object that is the
;                         target for this command object. This is the
;                         item that was acted upon and as a result,
;                         information was stored in this object.
;
;   OPERATION_IDENTIFIER - The identifier to the operation that was
;                          used to store information in this object.
;
;   SKIP_UNDO
;       If this property is set to true (1), then this command object will
;       be skipped when performing an Undo operation on the command set
;       that contains this command. The default is false (0),
;       which includes this command during the Undo operation.
;
;   SKIP_REDO
;       If this property is set to true (1), then this command object will
;       be skipped when performing a Redo operation on the command set
;       that contains this command. The default is false (0),
;       which includes this command during the Redo operation.
;
;   All other keywords are passed to the superclass.
;
pro IDLitCommand::GetProperty, $
    OPERATION_IDENTIFIER=OPERATION_ID, $
    SKIP_REDO=skipRedo, $
    SKIP_UNDO=skipUndo, $
    TARGET_IDENTIFIER=TARGET_ID, $
    _REF_EXTRA=_super

   compile_opt idl2, hidden

    if(arg_present(OPERATION_ID))then $
        OPERATION_ID = self._strIDOperation

    if (ARG_PRESENT(skipRedo) gt 0) then $
        skipRedo = self._skipRedo

    if (ARG_PRESENT(skipUndo) gt 0) then $
        skipUndo = self._skipUndo

    if(arg_present(TARGET_ID))then $
        TARGET_ID = self._strIDTarget

    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::GetProperty, _EXTRA=_super

end


;---------------------------------------------------------------------------
; Properties
;---------------------------------------------------------------------------
;  IDLitCommand::SetProperty
;
;  Purpose:
;     Used to set properties on the command object.
;
;  Keywords:
;   TARGET_IDENTIFIER   - The identifier to the object that is the
;                         target for this command object. This is the
;                         item that was acted upon and as a result,
;                         information was stored in this object.
;
;   OPERATION_IDENTIFIER - The identifier to the operation that was
;                          used to store information in this object.
;
;   SKIP_UNDO
;       If this property is set to true (1), then this command object will
;       be skipped when performing an Undo operation on the command set
;       that contains this command. The default is false (0),
;       which includes this command during the Undo operation.
;
;   SKIP_REDO
;       If this property is set to true (1), then this command object will
;       be skipped when performing a Redo operation on the command set
;       that contains this command. The default is false (0),
;       which includes this command during the Redo operation.
;
;   All other keywords are passed to the superclass.
;
pro IDLitCommand::SetProperty,  $
    OPERATION_IDENTIFIER=OPERATION_ID, $
    SKIP_REDO=skipRedo, $
    SKIP_UNDO=skipUndo, $
    TARGET_IDENTIFIER=TARGET_ID, $
    _EXTRA=_super

   compile_opt idl2, hidden

    if(n_elements(OPERATION_ID) gt 0)then $
        self._strIDOperation = OPERATION_ID;

    if (N_ELEMENTS(skipRedo) gt 0) then $
        self._skipRedo = skipRedo

    if (N_ELEMENTS(skipUndo) gt 0) then $
        self._skipUndo = skipUndo

    if(n_elements(TARGET_ID) gt 0)then $
        self._strIDTarget = TARGET_ID

    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::SetProperty, _EXTRA=_super

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitCommand::GetSize
;
; Purpose:
;   This method will return the approximate size of the data that
;   this object contains.
;
; Keywords:
;   KILOBYTES    - If set, the value in kilobytes
;
function IDLitCommand::GetSize, KILOBYTES=KILOBYTES
   compile_opt idl2, hidden

   return, keyword_set(KILOBYTES) ? $
              ceil(float(self._sizeItems)/1000., /L64)  : $
              self._sizeItems ; our store item.
end


;---------------------------------------------------------------------------
; IDLitCommand::AddItem
;
; Purpose:
;    Used to add an item to the internal data list.
;
; Parameters:
;   strItem     - The name to be associated with this item.
;
;   Item        - The item to add. This can be any IDL type.
;
; Keywords:
;   OVERWRITE   - Normally, if an item already exists in the data
;                 dictionary, it is not overwritten. If this keyword
;                 is set, the original value is replaced with the new
;                 one.
;
function IDLitCommand::AddItem, strItem, Item, OVERWRITE=OVERWRITE

   compile_opt idl2, hidden

   ; check for a blank name
   if(not keyword_set(strItem))then $
     return, 0

   upName = STRUPCASE(strItem)
   ; Do we have items already? If so, check for an exising
   ; item of the same name.
   if(n_elements(*self._pDataDictionary) gt 0)then begin
       idx = where((*self._pDataDictionary).strName eq upName)
       if(idx[0] ne -1 and not keyword_set(OVERWRITE))then $ ; duplicate
             return, 0
   endif else idx=-1
   ; Get the size of the item being added. Note, we only check the
   ; size of an item when it is added. This should not be an issues
   ; since the size should not change.
   self._sizeItems += IDLitGetItemSize(Item)

   ; Ok, create the data record
   if(idx[0] eq  -1)then begin
       sData = {_IDLitCommandRec_t, upName, ptr_new(Item)}

       if(n_elements(*self._pDataDictionary) eq 0)then $
         *self._pDataDictionary = temporary(sData) $
       else $
         *self._pDataDictionary = [temporary(*self._pDataDictionary), temporary(sData)]
   endif else begin                 ;jam in the new value
       ; Delete the current size value.
       self._sizeItems -=IDLitGetItemSize(*(((*self._pDataDictionary)[idx[0]]).pData))
       *(((*self._pDataDictionary)[idx[0]]).pData) = Item
   endelse


  return, 1

end


;---------------------------------------------------------------------------
; IDLitCommand::GetItem
;
; Purpose:
;   Used to reteive a given item from the internal data dictionary of
;   this object.
;
; Parameters:
;     strItem[in] -  The name of the item to return. This is case
;                    insensitive.
;
;     Item[out] -    The item retireved. This is only valid if this
;                 function returns 1.
;
; Return Value:
;     0 - The value was not retrieved and Item is invalid
;     1 - The value was retrieved and Item is valid.
;
function IDLitCommand::GetItem, strItem, Item

   compile_opt idl2, hidden

   ; check for a blank name
   if(not keyword_set(strItem))then $
     return, 0

   ; Is the dictionary empty
   if(n_elements(*self._pDataDictionary) eq 0)then $
     return, 0

   idx = where((*self._pDataDictionary).strName eq strupcase(strItem))
   if(idx[0] eq -1)then $ ;
     return, 0

   Item = *(*self._pDataDictionary)[idx[0]].pData
   return, 1
end


;---------------------------------------------------------------------------
; IDLitCommand::
;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitCommand__define
;
; Purpose:
;  This routine is used to define the command object class.
;
pro IDLitCommand__define

   compile_opt idl2, hidden

   void = {IDLitCommand, $
           inherits IDLitComponent, $
           _pDataDictionary  : ptr_new(), $ ; list of stored items
           _sizeItems        : 0ULL,$ ; total size of items contained
           _strIDTarget      : "",  $ ; ID of the target object
           _strIDOperation   : "",   $ ; ID of the operation used.
           _skipUndo         : 0b, $  ; 1=skip during Undo execution
           _skipRedo         : 0b $  ; 1=skip during Redo execution
          }

   ; Define our internal dictionary structure
   void = {_IDLitCommandRec_t, $
           strName    : "",  $
           pData      : ptr_new() }
end
