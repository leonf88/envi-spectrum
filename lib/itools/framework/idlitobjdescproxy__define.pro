; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdescproxy__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitObjDesc
;
; PURPOSE:
;   This file implements the IDLitObjDesc class. This class provides
;   an object descriptor that allows object registration without the
;   need to instatiated an actual destination object.
;
;   The object also provides a method to create the target object.
;
;   This class also provides a method to emulate the property set of
;   the object it represents. This is done by using the property bag
;   class that is part of the framework. Using a lazying approach,
;   this class will create the object and record it's property
;   set. This is done in the following situations:
;        - The object instance is requested.
;        - When a property is retrieved or set and this class doesn't
;          know about that property.
;        - When the list of avaliable properties for this class is
;          requested.
;
;   After the property set has been recorded, this object can proxy
;   the property set. If this isn't a singleton class, this allows
;   for the setting of tool scoped values that are then applied
;   when a new object is requested. This provides a "style" like sytem.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;   IDLitPropertyBag
;
; CREATION:
;   See IDLitObjDesc::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitObjDesc::Init
;   IDLitObjDesc::Cleanup
;
; INTERFACES:
; IIDLProperty
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitObjDescProxy::Init
;
; Purpose:
; The constructor of the IDLitObjDescProxy object.
;
; Parameters:
; NONE
;
; Keywords
; CLASSNAME   - The class name that this object is describing.
;
; SINGLETON   - Recycle instances of objects?

function IDLitObjDescProxy::Init, oEnv, idProxy,$
                          IDENTIFIER=identifier,  _extra=_extra


  compile_opt idl2, hidden
  self._oEnv = oEnv
  self._idProxy = idProxy
  if(not keyword_set(identifier))then $
    identifier = IDLitBaseName(idProxy)
  return, self->IDLitObjDesc::Init(_extra=_extra, identifier=identifier)
end


;---------------------------------------------------------------------------
; IDLitObjDescProxy::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitObjDescProxy::Cleanup

    compile_opt idl2, hidden

    if (OBJ_VALID(self._oEnv)) then begin
        self._oEnv->RemoveOnNotifyObserver, $
            self->GetFullIdentifier(), self._idProxy
    endif

    self->IDLitObjDesc::Cleanup

end


;---------------------------------------------------------------------------
; IDLitObjDescProxy::_GetProxyTarget()
;
; Purpose:
;   Returns the target of our proxy operation.
;
function IDLitObjDescProxy::_GetProxyTarget

    compile_opt hidden, idl2

    if (~obj_valid(self._oEnv)) then $
        return, obj_new()

    oTarget = self._oEnv->GetByIdentifier(self._idProxy)

    if (~self._bPropsInited && OBJ_VALID(oTarget)) then begin
        self._bPropsInited = 1b
        ; Do not copy the _PARENT property since we want
        ; to remember who my proxy parent is.
        oTarget->IDLitComponent::GetProperty, $
            DESCRIPTION=description, $
            HELP=help, ICON=icon
        self->IDLitComponent::SetProperty, $
            DESCRIPTION=description, $
            HELP=help, ICON=icon
        ; Make sure that the target id is a full identifier.
        ; This avoids problems with string matching.
        self._idProxy = oTarget->GetFullIdentifier()
        ; Add myself as an observer of the target. That way we can
        ; pass on messages from the target to my own observers.
        self._oEnv->AddOnNotifyObserver, $
            self->GetFullIdentifier(), self._idProxy
    endif

    return, oTarget

end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitObjDescProxy::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Properties
;
pro IDLitObjDescProxy::GetProperty, $
                     _PARENT=_parent, $ ;
                     IDENTIFIER=IDENTIFIER, $
                     NAME=name, $
                     PRIVATE=private, $
                     PROXY=proxy, $
                     _REF_EXTRA=_super


  compile_opt idl2, hidden


  if(arg_present(_PARENT))then $
    self->IDLitComponent::GetProperty, _PARENT=_parent

  if(arg_present(IDENTIFIER))then $
    self->IDLitComponent::GetProperty, IDENTIFIER=IDENTIFIER

  if (arg_present(name)) then $
    self->IDLitComponent::GetProperty, NAME=name

    if (arg_present(private)) then $
        self->IDLitComponent::GetProperty, PRIVATE=private

  if (arg_present(proxy)) then $
      proxy = self._idProxy

  if(n_elements(_super) gt 0 )then begin
      oTarget = self->_GetProxyTarget()
      if(obj_valid(oTarget))then $
        oTarget->GetProperty, _EXTRA=_super
  endif

end

;---------------------------------------------------------------------------
pro IDLitObjDescProxy::SetProperty,  $
                     _PARENT=_parent, $
                     IDENTIFIER=IDENTIFIER, $
                     PRIVATE=private, $
                     NAME=name, $
                     _EXTRA=_EXTRA

  compile_opt idl2, hidden

  if(keyword_set(_PARENT))then $
    self->IDLitComponent::SetProperty, _PARENT=_parent

  if(keyword_set(IDENTIFIER))then $
    self->IDLitComponent::SetProperty, IDENTIFIER=IDENTIFIER

  if(keyword_set(name))then $
    self->IDLitComponent::SetProperty, NAME=name

  if(keyword_set(private))then $
    self->IDLitComponent::SetProperty, PRIVATE=private

  if(n_elements(_extra) gt 0)then begin
      oTarget = self->_GetProxyTarget()
      if(obj_valid(oTarget))then $
        oTarget->SetProperty, _EXTRA=_EXTRA
  end

end


;----------------------------------------------------------------------------
; Vector off the EditUserDefProperty call to our singleton object.
;
function IDLitObjDescProxy::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    oTarget = self->_GetProxyTarget()
    if(obj_valid(oTarget))then $
        oTarget->EditUserDefProperty, oTool, identifier

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; IDLitObjDescProxy::GetObjectInstance
;
; Purpose:
;   This routine is used to get an instance of the object
;   described by this descriptor. This process is abstracted
;   to allow for "singletons" ...etc.
;
; Return Value:
;   An object of the type that is described by this object.

function IDLitObjDescProxy::GetObjectInstance, _REF_EXTRA=_extra

  compile_opt idl2, hidden

    oTarget = self->_GetProxyTarget()
    return, (obj_valid(oTarget) ? oTarget->GetObjectInstance(_EXTRA=_extra) : obj_new())
end


;---------------------------------------------------------------------------
; IDLitObjDescProxy::ReturnObjectInstance
;
; Purpose:
;   This routine is used to return an object instance to the object
;   descriptor. The primary motivation for this is for singleton
;   objects, where the user cannot/should not destory the instance
;   given.
;
; Parameters
;  oInstance -  The object instance to return
;
; TODO: Should this change?
;

pro IDLitObjDescProxy::ReturnObjectInstance, oInstance

  compile_opt idl2, hidden
    oTarget = self->_GetProxyTarget()
    if(obj_valid(oTarget))then $
      oTarget->ReturnObjectInstance, oInstance $
    else $
      obj_destroy, oInstance
end

;---------------------------------------------------------------------------
; IDLitObjDescProxy::_GetAllPropertyDescriptors
;
; Purpose:
;   This method overrides the method on the IDLitComponent and allows
;   this object to determine when QueryProperties() is called on this
;   object. This allows this object to perform and needed property
;   recording of the object it contains. By trapping this call, this
;   object can perform a "lazying" initalization.
;
function IDLitObjDescProxy::_GetAllPropertyDescriptors
   compile_opt idl2, hidden

    oTarget = self->_GetProxyTarget()
    if(obj_valid(oTarget))then $
      return, oTarget->_GetAllPropertyDescriptors()
end


;---------------------------------------------------------------------------
; IDLitObjDescProxy::OnNotify
;
; Purpose:
;   If a OnNotify() mesage is triggered, route to managed object (if
;   it is managed)
;
; Parameters:
;   strID    - The identifier of the underlying tool
;
;   message  - The message that is being sent.
;
;   Userdata - anything
;
pro IDLitObjDescProxy::OnNotify, strID, messageIn, userdata

    compile_opt hidden, idl2

    ; If the message came from our target, then route on to our
    ; own observers.
    if (STRCMP(strID, self._idProxy, /FOLD_CASE)) then begin
        if (~OBJ_VALID(self._oEnv)) then $
            return
        ; Replace the identifier with my own, so it looks like the
        ; message came from me.
        self._oEnv->DoOnNotify, $
            self->GetFullIdentifier(), messageIn, userdata
        return
    endif

    ; Otherwise pass message thru to our target.
    oTarget = self->_GetProxyTarget()
    if (obj_valid(oTarget))then $
      oTarget->OnNotify, strID, messageIn, userdata

end


;---------------------------------------------------------------------------
; IDLitObjDescProxy::GetDataTypes
;
; Purpose:
;   Proxy of this method for the object descriptor
;
; Parameters:
;    None.
;
; Return Value:
;    String array of types.
;
function IDLitObjDescProxy::GetDataTypes, _REF_EXTRA=_EXTRA
   compile_opt idl2, hidden

    oTarget = self->_GetProxyTarget()
    if(obj_valid(oTarget) && obj_isa(oTarget, "IDLitObjDescVis"))then $
      return, oTarget->GetDataTypes( _extra=_extra) $
    else return, ''
end


;-------------------------------------------------------------------------
; IDLitObjDescProxy::QueryAvailability
;
; Purpose:
;   This function method determines whether this object described
;   by this desecriptor is applicable for the given data and/or
;   visualization types for the given proxy.
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
;   None
;
function IDLitObjDescProxy::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    oTarget = self->_GetProxyTarget()
    if (OBJ_ISA(oTarget, 'IDLitObjDescTool')) then $
        return, oTarget->QueryAvailability(oTool, selTypes)

    return, 0

end


;---------------------------------------------------------------------------
; Defintion
;---------------------------------------------------------------------------
; IDLitObjDescProxy__Define
;
; Purpose:
; Class definition for the IDLitObjDescProxy class
;
pro IDLitObjDescProxy__Define

  compile_opt idl2, hidden

  void = {IDLitObjDescProxy, $
          inherits IDLitObjDesc, $
          _oEnv          : obj_new(),  $ ; execution environemt
          _idProxy       : ''          $ ; proxy id
         }

end
