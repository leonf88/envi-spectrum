; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdescmacro__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitObjDescTool
;
; PURPOSE:
;   This file implements the IDLitObjDescMacro class. This class provides
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
function IDLitObjDescMacro::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitObjDescTool::Init( _EXTRA=_extra)) then $
        return, 0

    ; to the user, looks a lot like the name property, but it
    ; is not.  this is to be used for an actual name property
    ; setting within macros which does not collide with the name
    ; property of the objdesc which is hidden
    self->RegisterProperty, 'OBJ_NAME', /STRING, $
      NAME='Name', $
      DESCRIPTION='Name', $
      /HIDE
    self->RegisterProperty, 'USE_OBJ_NAME', /BOOLEAN, $
      NAME='Use Name Override', $
      DESCRIPTION='Use Name Override', $
      /HIDE
    self->RegisterProperty, 'OBJ_DESCRIPTION', /STRING, $
      NAME='Description', $
      DESCRIPTION='Description', $
      /HIDE
    self->RegisterProperty, 'USE_OBJ_DESCRIPTION', /BOOLEAN, $
      NAME='Use Override Description', $
      DESCRIPTION='Use Override Description', $
      /HIDE


    return, 1
end



;---------------------------------------------------------------------------
;pro IDLitObjDescMacro::Cleanup
;
;    compile_opt idl2, hidden
;
;end


;---------------------------------------------------------------------------
; Property Management
;---------------------------------------------------------------------------
; IDLitObjDescMacro::GetProperty
;
; Purpose:
;   Used to get the value of the properties associated with this class.
;
; Properties
;
pro IDLitObjDescMacro::GetProperty, $
    OBJ_NAME=objName, $
    USE_OBJ_NAME=useObjName, $
    OBJ_DESCRIPTION=objDescription, $
    USE_OBJ_DESCRIPTION=useObjDescription, $
    _REF_EXTRA=_super

  compile_opt idl2, hidden

  if (ARG_PRESENT(objName)) then $
    objName =  self._objName
  if (ARG_PRESENT(useObjName)) then $
    useObjName =  self._useObjName
  if (ARG_PRESENT(objDescription)) then $
    objDescription =  self._objDescription
  if (ARG_PRESENT(useObjDescription)) then $
    useObjDescription =  self._useObjDescription

  ; Get other properties
  if(n_elements(_super) gt 0)then $
      self->IDLitObjDescTool::GetProperty, _EXTRA=_super
end


;---------------------------------------------------------------------------
pro IDLitObjDescMacro::SetProperty, $
    OBJ_NAME=objName, $
    USE_OBJ_NAME=useObjName, $
    OBJ_DESCRIPTION=objDescription, $
    USE_OBJ_DESCRIPTION=useObjDescription, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    if(n_elements(objName) gt 0) then $
        self._objName = objName
    if(n_elements(useObjName) gt 0) then $
        self._useObjName = useObjName
    if(n_elements(objDescription) gt 0) then $
        self._objDescription = objDescription
    if(n_elements(useObjDescription) gt 0) then $
        self._useObjDescription = useObjDescription

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitObjDescTool::SetProperty, _extra=_super
end





;---------------------------------------------------------------------------
; Defintion
;---------------------------------------------------------------------------
; IDLitObjDescMacro__Define
;
; Purpose:
; Class definition for the IDLitObjDescMacro class
;
pro IDLitObjDescMacro__Define

  compile_opt idl2, hidden

  void = {IDLitObjDescMacro,              $
          inherits   IDLitObjDescTool,    $
          _objName           : '',   $ ; For use in macros
          _useObjName        : 0b,   $ ; For use in macros
          _objDescription    : '',   $ ; For use in macros
          _useObjDescription : 0b    $ ; For use in macros
         }

end
