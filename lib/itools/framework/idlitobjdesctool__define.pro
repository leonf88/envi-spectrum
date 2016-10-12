; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdesctool__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitObjDescTool
;
; PURPOSE:
;   This file implements the IDLitObjDescTool class. This class provides
;   an object descriptor that allows object registration without the
;   need to instatiated an actual destination object.
;
;   The object also provides a method to create the target object.
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
;   See IDLitObjDescTool::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitObjDescTool::Init
;
; Purpose:
; The constructor of the IDLitObjDescTool object.
;
; Parameters:
; NONE
;
; Keywords
; CLASSNAME   - The class name that this object is describing.
;
; SINGLETON   - Recycle instances of objects?
;
function IDLitObjDescTool::Init, $
    ACCELERATOR=accelerator, $
    CHECKED=checked, $
    DISABLE=disable, $
    DROPLIST_EDIT=droplistEdit, $
    DROPLIST_INDEX=droplistIndex, $
    DROPLIST_ITEMS=droplistItems, $
    SEPARATOR=separator, $
    TOOL=oTool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitObjDesc::Init( _EXTRA=_extra)) then $
        return, 0

    if (KEYWORD_SET(oTool)) then $
        self->_SetTool, oTool

    self->IDLitObjDescTool::SetProperty, $
        ACCELERATOR=accelerator, $
        CHECKED=checked, $
        DISABLE=disable, $
        DROPLIST_EDIT=droplistEdit, $
        DROPLIST_INDEX=droplistIndex, $
        DROPLIST_ITEMS=droplistItems, $
        SEPARATOR=separator

    return, 1
end



;---------------------------------------------------------------------------
pro IDLitObjDescTool::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._pDroplistItems

    self->IDLitObjDesc::Cleanup
end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitObjDescTool::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Properties
;
pro IDLitObjDescTool::GetProperty, $
    ACCELERATOR=accelerator, $
    CHECKED=checked, $
    DISABLE=disable, $
    HAS_DROPLIST=hasDroplist, $
    DROPLIST_EDIT=droplistEdit, $
    DROPLIST_INDEX=droplistIndex, $
    DROPLIST_ITEMS=droplistItems, $
    SEPARATOR=separator, $
    _OBJDESCTOOL=_objdesctool, $
    _REF_EXTRA=_super

  compile_opt idl2, hidden


    ; This is an undocumented keyword which returns all properties
    ; needed to duplicate ourself. Needed for tool morphing from
    ; IDLitSystem::UpdateToolByType
    if (ARG_PRESENT(_objdesctool)) then begin
        self->IDLitComponent::GetProperty, $
            DESCRIPTION=description, $
            HELP=helpTopic, $
            ICON=icontype, $
            PRIVATE=private
        _objdesctool =  { $
            DESCRIPTION: description, $
            HELP: helpTopic, $
            ICON: icontype, $
            PRIVATE: private, $
            ACCELERATOR: self._accelerator, $
            CHECKED: self._checked, $
            DISABLE: self._disable, $
            SEPARATOR: self._separator, $
            DROPLIST_EDIT: self._droplistEdit, $
            DROPLIST_INDEX: self._droplistIndex, $
            DROPLIST_ITEMS: PTR_VALID(self._pDroplistItems) ? $
                *self._pDroplistItems : ''}
    endif


  if(arg_present(accelerator))then $
    accelerator =  self._accelerator

  if(arg_present(checked))then $
    checked =  self._checked

  if(arg_present(disable))then $
    disable =  self._disable

  if(arg_present(separator))then $
    separator =  self._separator

  if (ARG_PRESENT(hasDroplist)) then $
    hasDroplist = PTR_VALID(self._pDroplistItems)

  if (ARG_PRESENT(droplistEdit)) then $
      droplistEdit = self._droplistEdit

  if (ARG_PRESENT(droplistIndex)) then $
      droplistIndex = self._droplistIndex

  if (ARG_PRESENT(droplistItems)) then begin
      droplistItems = PTR_VALID(self._pDroplistItems) ? $
          *self._pDroplistItems : ''
  endif

  ; Get other properties
  if(n_elements(_super) gt 0)then $
      self->IDLitObjDesc::GetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
pro IDLitObjDescTool::SetProperty, $
    ACCELERATOR=accelerator, $
    CHECKED=checked, $
    DISABLE=disable, $
    DROPLIST_EDIT=droplistEdit, $
    DROPLIST_INDEX=droplistIndex, $
    DROPLIST_ITEMS=droplistItems, $
    SEPARATOR=separator, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if (N_ELEMENTS(accelerator) eq 1) then $
        self._accelerator = accelerator

    if (N_ELEMENTS(checked) eq 1) then $
        self._checked = KEYWORD_SET(checked)

    if (N_ELEMENTS(disable) && self._disable ne disable) then begin
        self._disable = KEYWORD_SET(disable)
        self._oTool->DoOnNotify, self->GetFullIdentifier(), $
            'SENSITIVE', ~self._disable
    endif

    if (N_ELEMENTS(separator) eq 1) then $
        self._separator = KEYWORD_SET(separator)

    if (N_ELEMENTS(droplistEdit) eq 1) then $
        self._droplistEdit = KEYWORD_SET(droplistEdit)

    if (N_ELEMENTS(droplistIndex) ne 0) then $
        self._droplistIndex = droplistIndex

    if (N_ELEMENTS(droplistItems) && droplistItems[0] ne '') then begin
        if PTR_VALID(self._pDroplistItems) then $
            PTR_FREE, self._pDroplistItems
        self._pDroplistItems = PTR_NEW(droplistItems)
    endif

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitObjDesc::SetProperty, _extra=_super
end


;---------------------------------------------------------------------------
; Purpose:
;   Override our superclass method so we can also set the tool.
;
; Return Value:
;   An object of the type that is described by this object.
;
function IDLitObjDescTool::_InstantiateObject, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDlitObjDesc::_InstantiateObject(TOOL=self._oTool, $
        _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; IDLitObjDescTool::GetObjectInstance
;
; Purpose:
;   This routine is used to get an instance of the object
;   described by this descriptor. This process is abstracted
;   to allow for "singletons" ...etc.
;
; Return Value:
;   An object of the type that is described by this object.

function IDLitObjDescTool::GetObjectInstance, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oObj = self->IDLitObjDesc::GetObjectInstance(_EXTRA=_extra)

    ; Do heavyweight part of creation
    if (obj_valid(oObj)) then begin
        ; Just in case our class' Init method didn't handle the
        ; TOOL keyword, set it again. We also *must* set it for
        ; singletons, because we might still have an old tool objref
        ; or the system objref.
        ; CT Note: Leave this as an "eq OBJ_NEW".
        if (self._singleton || oObj->GetTool() eq OBJ_NEW()) then $
            oObj->_SetTool, self._oTool
        if (~oObj->Create()) then begin
            self->IDLitObjDesc::ReturnObjectInstance, oObj
            oObj = obj_new()
        endif
    endif

    return, oObj
end


;---------------------------------------------------------------------------
; IDLitObjDescTool::ReturnObjectInstance
;
; Purpose:
;   This routine is used to return an object instance to the object
;   descriptor. The primary motivation for this is for singleton
;   objects, where the user cannot/should not destroy the instance
;   given.
;
; Parameters
;  oInstance -  The object instance to return
;
pro IDLitObjDescTool::ReturnObjectInstance, oInstance

  compile_opt idl2, hidden

  if(not obj_isa(oInstance, self._classname))then begin
      Message, IDLitLangCatQuery('Message:Framework:InvalidClass') + self._classname,/continue
      return
  endif

  ; Issue shutdown so object can clean up but still remain in a "light"
  ; state if it is a singleton.
  if(obj_valid(oInstance))then begin
    oInstance->Shutdown
  endif

  self->IDLitObjDesc::ReturnObjectInstance, oInstance
end


;---------------------------------------------------------------------------
; IDLitObjDescTool::_Settool
;
; Purpose:
;   Used to set the current tool on the object when it's created.
;
pro IDLitObjDescTool::_SetTool, oTool
   compile_opt hidden, idl2

   self._oTool = oTool
end


;-------------------------------------------------------------------------
; IDLitObjDescTool::QueryAvailability
;
; Purpose:
;   This function method determines whether this object described
;   by this desecriptor is applicable for the given data and/or
;   visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if the described object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None.
;
function IDLitObjDescTool::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; If this is a singleton, vector off call to the contained object.
    if (self._singleton) then begin
        self->_InitializePropertyBag
        if OBJ_VALID(self._oObject) then $
            return, self._oObject->QueryAvailability(oTool, selTypes)
    endif

    return, ~self._disable

end


;---------------------------------------------------------------------------
; Defintion
;---------------------------------------------------------------------------
; IDLitObjDescTool__Define
;
; Purpose:
; Class definition for the IDLitObjDescTool class
;
pro IDLitObjDescTool__Define

  compile_opt idl2, hidden

  void = {IDLitObjDescTool,              $
          inherits   IDLitObjDesc,       $
          _oTool          : obj_new(),   $ ; Used to keep link to tool
          _accelerator    : '',          $ ; accelerator key e.g. 'Ctrl+X'
          _checked        : 0b,          $ ; flag for menu items
          _disable        : 0b,          $ ; flag for menu/button items
          _separator      : 0b,          $ ; flag for possible menu items
          _droplistEdit   : 0b,          $ ; droplist is editable
          _droplistIndex  : 0L,          $ ; current droplist index
          _pDroplistItems : PTR_NEW()   $ ; Ptr to droplist items, or NULL.
         }

end
