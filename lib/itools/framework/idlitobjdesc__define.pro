; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdesc__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
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
; IDLitObjDesc::Init
;
; Purpose:
; The constructor of the IDLitObjDesc object.
;
; Parameters:
; NONE
;
; Keywords
; CLASSNAME   - The class name that this object is describing.
;
; SINGLETON   - Recycle instances of objects?
;
function IDLitObjDesc::Init, $
                     CLASSNAME=CLASSNAME, $
                     SINGLETON=singleton, $
                     _EXTRA=_extra

  compile_opt idl2, hidden

  if(self->IDLitComponent::Init() eq 0)then $
    return, 0

  if(self->IDLitPropertyBag::Init() eq 0)then begin
      self->IDLitComponent::Cleanup
      return, 0
  endif

  ; Set our class name
  if (KEYWORD_SET(CLASSNAME)) then $
    self._classname = CLASSNAME

  self._singleton = KEYWORD_SET(singleton)

  self._bFactory=1b ; default, this acts like a class factory

  ; Ok, now we need to handle any properties this class implements
  self->IDLitObjDesc::SetProperty, _EXTRA=_EXTRA

  return, 1
end


;---------------------------------------------------------------------------
; IDLitObjDesc::Cleanup
;
; Purpose:
; The destructor for the class.
;
; Parameters:
; None.
;
pro IDLitObjDesc::Cleanup

  compile_opt idl2, hidden

  self->IDLitPropertyBag::Cleanup
  self->IDLitComponent::Cleanup

  ; If we have an object associated with

  if(obj_valid(self._oObject))then $
    obj_destroy, self._oObject

end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitObjDesc::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Properties
;   CLASSNAME    - The name of the class that is described by
;                  this object.
;
;   SINGLETON    - Is this a singleton object?
;
pro IDLitObjDesc::GetProperty, $
    CLASSNAME=Classname, $     ;------ these are my properties
    SINGLETON=singleton, $
    NAME=name, $               ;------ my superclass properties
    DESCRIPTION=description, $ ;
    HELP=helpTopic, $
    ICON=icontype, $      ;
    IDENTIFIER=identifier, $   ;
    PRIVATE=private, $
    UVALUE=uvalue, $           ;
    _PARENT=_parent, $         ;
    _REF_EXTRA=_super          ;------ my associated object properties

  compile_opt idl2, hidden

  if(arg_present(Classname))then $
    Classname =  self._classname

  if (ARG_PRESENT(singleton)) then $
    singleton =  self._singleton

  ; Get other properties
  if(n_elements(_super) gt 0)then begin
      self->_InitializePropertyBag
        ; If this is a singleton, vector off call to the contained object.
        if (self._singleton) then begin
            if OBJ_VALID(self._oObject) then $
                self._oObject->GetProperty, _EXTRA=_super
        endif else begin
            self->IDLitPropertyBag::GetProperty,_EXTRA=_super
        endelse
  endif

  ; Get props from superclass
  self->IDLitComponent::GetProperty, $
    NAME=name, $
    DESCRIPTION=description, $
    HELP=helpTopic, $
    ICON=iconType, $      ;
    IDENTIFIER=identifier, $
    PRIVATE=private, $
    UVALUE=uvalue, $
    _PARENT=_parent


end


;---------------------------------------------------------------------------
pro IDLitObjDesc::SetProperty,  $
                NAME=name, $
                DESCRIPTION=description, $
                HELP=helpTopic, $
                ICON=icontype, $
                IDENTIFIER=identifier, $
                UVALUE=uvalue, $
                CLASSNAME=CLASSNAME, $
                CLASS_FACTORY=CLASS_FACTORY, $
                PRIVATE=private, $
                SINGLETON=singleton, $
                _PARENT=_parent, $
                _REF_EXTRA=_super

  compile_opt idl2, hidden

  if (N_ELEMENTS(Classname) && ~OBJ_VALID(self._oObject)) then $
    self._classname = CLASSNAME

   ; Set other properties
   if(n_elements(_super) gt 0)then begin
       self->_InitializePropertyBag
        ; If this is a singleton, vector off call to the contained object.
        if (self._singleton) then begin
            if OBJ_VALID(self._oObject) then $
                self._oObject->SetProperty, _EXTRA=_super
        endif else begin
            self->IDLitPropertyBag::SetProperty,_EXTRA=_super
        endelse
   endif

   if(n_elements(class_factory) gt 0)then $
     self._bFactory = keyword_set(class_factory)

  ; Set props on superclass
  self->IDLitComponent::SetProperty, $
       NAME=name, $
       DESCRIPTION=description, $
       HELP=helpTopic, $
       ICON=iconType, $
       IDENTIFIER=identifier, $
       PRIVATE=private, $
       UVALUE=uvalue, $
       _PARENT=_parent

    ; If we have a singleton, and our objdesc properties changed, we also
    ; need to change our singleton properties to match.
    if (self._singleton && OBJ_VALID(self._oObject)) then begin
        self._oObject->IDLitComponent::SetProperty, $
            NAME=name, $
            DESCRIPTION=description, $
            HELP=helpTopic, $
            ICON=iconType, $
            IDENTIFIER=identifier, $
            PRIVATE=private, $
            _PARENT=_parent
    endif

end


;----------------------------------------------------------------------------
; Vector off the EditUserDefProperty call to our singleton object.
;
function IDLitObjDesc::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    ; Set other properties
    self->_InitializePropertyBag

    ; If this is a singleton, vector off the call to the contained object.
    ; Otherwise, return failure since we really need a specific objref.
    return, (self._singleton && OBJ_VALID(self._oObject)) ? $
        self._oObject->EditUserDefProperty(oTool, identifier) : 0

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
;
; IDLitObjDesc::_InstantiateObject
;
; Purpose:
;   This function method does the actual instantiation of the
;   object associated with this descriptor.
;
; Return Value:
;   An object of the type that is described by this object.
;
function IDLitObjDesc::_InstantiateObject, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; It might happen that someone's class didn't handle keywords in ::Init.
    ; So catch the error and try again without keywords.
    ; In this case, someone else (like GetObjectInstance) had better set
    ; these keywords again.
    CATCH, err
    if (err ne 0) then begin
        CATCH, /cancel
        MESSAGE, /RESET
        return, OBJ_NEW(self._classname)
    endif

    oObject = OBJ_NEW(self._classname, _EXTRA=_extra)

    ; Retrieve our own properties. These aren't part of the
    ; property bag so we need to pass them on explicitely.
    self->IDLitComponent::GetProperty, NAME=name, $
        DESCRIPTION=descriptionIn, $
        HELP=helpIn, $
        ICON=iconIn, $
        IDENTIFIER=identifier, $
        PRIVATE=private, $
        _PARENT=_parentIn

    ; Don't stomp on the component values if ours are null.
    if (descriptionIn ne '') then $
        descriptionOut = descriptionIn
    if (helpIn ne '') then $
        helpOut = helpIn
    if (iconIn ne '') then $
        iconOut = iconIn

    ; Only set _PARENT if we are a singleton. Otherwise assume our
    ; new object is getting added to some other parent.
    if (self._singleton) then $
        _parentOut = _parentIn

    ; Now set our keywords.
    oObject->IDLitComponent::SetProperty, NAME=name, $
        DESCRIPTION=descriptionOut, $
        HELP=helpOut, $
        ICON=iconOut, $
        IDENTIFIER=identifier, $
        PRIVATE=private, $
        _PARENT=_parentOut

    return, oObject

end


;---------------------------------------------------------------------------
;
; IDLitObjDesc::GetObjectInstance
;
; Purpose:
;   This routine is used to get an instance of the object
;   described by this descriptor. This process is abstracted
;   to allow for "singletons" ...etc.
;
; Return Value:
;   An object of the type that is described by this object.
;
function IDLitObjDesc::GetObjectInstance, _REF_EXTRA=_extra

  compile_opt idl2, hidden

  if (self._bInInstance) then $
    return, obj_new()
  ; Set our instance flag.
  self._bInInstance =1

  ; Create an instance of the object if needed.
  if (~OBJ_VALID(self._oObject)) then begin

        ; Set up a catch to trap errors on obj_new()
@idlit_catch
        if(iErr ne 0)then begin ; did the create fail?
            CATCH, /CANCEL
            self._bInInstance = 0
            MESSAGE, /REISSUE_LAST
            ; Depending upon whether the error jumped, we may not reach here.
            return, obj_new()
        endif


        self._oObject = self->_InstantiateObject(_EXTRA=_extra)

        CATCH, /CANCEL

        if (~OBJ_VALID(self._oObject)) then begin
            self._bInInstance=0
            return, OBJ_NEW()
        endif


        if (~self._singleton) then begin

            ; If necessary record the object property settings.
            if (~self._bPropsInited) then $
                self->IDLitPropertyBag::RecordProperties, self._oObject

            ; Playback the object property settings. We do this even in the
            ; case where we've just recorded them, just in case setting
            ; properties causes other properties or their attributes
            ; to change.
            if (self._bFactory) then $
                self._oObject->IDLitComponent::SetProperty, /INITIALIZING
            self->IDLitPropertyBag::PlaybackProperties, self._oObject
            if (self._bFactory) then $
                self._oObject->IDLitComponent::SetProperty, INITIALIZING=0

        endif

    endif

  ; Make a copy.
  oObj = self._oObject

  ; Remove object so that we create another on the next call
  ; if not a singleton.
  if (~self._singleton) then $
    self._oObject = obj_new()

  self._bInInstance=0
  return, oObj
end


;---------------------------------------------------------------------------
; IDLitObjDesc::ReturnObjectInstance
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
pro IDLitObjDesc::ReturnObjectInstance, oInstance

    compile_opt idl2, hidden

    if (~OBJ_ISA(oInstance, self._classname)) then begin
        Message, IDLitLangCatQuery('Message:Framework:InvalidClass') + self._classname, $
            /CONTINUE
        return
    endif

    ; Only destroy non-singletons
    if (~self._singleton && OBJ_VALID(oInstance)) then $
        OBJ_DESTROY, oInstance

end


;---------------------------------------------------------------------------
; IDLitObjDesc::InitalizePropertyBag
;
; Purpose:
;    This class internal routine is a central location that allows
;    for the property bag information to be initalized. It will
;    retieve an object instance and record the properties for the
;    object the descriptor represents.
;
;    If the properties have already been recorded, they are not
;    recorded again.
;
; Parameters:
;   None
;
; Keywords:
;   None
;
pro IDLitObjDesc::_InitializePropertyBag

    compile_opt idl2, hidden

    if (self._bPropsInited || self._bInInstance) then $
        return

    ; Get an object instance
    oObj = self->GetObjectInstance()
    if (OBJ_VALID(oObj)) then begin
        self->ReturnObjectInstance, oObj
    endif

end


;---------------------------------------------------------------------------
; IDLitObjDesc::_GetAllPropertyDescriptors
;
; Purpose:
;   This method overrides the method on the IDLitComponent and allows
;   this object to determine when QueryProperties() is called on this
;   object. This allows this object to perform and needed property
;   recording of the object it contains. By trapping this call, this
;   object can perform a "lazying" initalization.
;
function IDLitObjDesc::_GetAllPropertyDescriptors, _REF_EXTRA=_extra
   compile_opt idl2, hidden

    self->_InitializePropertyBag

    if (self._singleton && OBJ_VALID(self._oObject)) then $
        return, self._oObject->_GetAllPropertyDescriptors(_EXTRA=_extra)

   return, self->IDLitComponent::_GetAllPropertyDescriptors(_EXTRA=_extra)
end


;---------------------------------------------------------------------------
; IDLitObjDesc::OnNotify
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
pro IDLitObjDesc::OnNotify, strID, message, userdata

    compile_opt hidden, idl2

    if (obj_valid(self._oObject) && $
        obj_hasmethod(self._oObject, "ONNOTIFY")) then $
        self._oObject->OnNotify, strID, message, userdata

end


;---------------------------------------------------------------------------
; Defintion
;---------------------------------------------------------------------------
; IDLitObjDesc__Define
;
; Purpose:
; Class definition for the IDLitObjDesc class
;
pro IDLitObjDesc__Define

  compile_opt idl2, hidden

  void = {IDLitObjDesc, $
          inherits   IDLitComponent,    $
          inherits   IDLitPropertyBag,  $
          _bFactory     : 0b,           $ ; This is a class factory
          _bInInstance   : 0b,          $ ; Creating instance
          _singleton    : 0b,           $ ; is this a singleton?
          _classname    : '',           $ ; The class name
          _oObject      : obj_new()     $ ; Object storage
         }

end
