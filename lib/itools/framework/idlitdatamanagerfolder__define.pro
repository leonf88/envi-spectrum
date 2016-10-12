; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitdatamanagerfolder__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitDataManagerFolder
;
; PURPOSE:
;   This file implements the IDLitDataManagerFolder class. This class provides
;
;   This traversal is all built off of the identifier property provided by
;   the IDLitComponent object.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitDataManagerFolder::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitDataManagerFolder::Init
;   IDLitDataManagerFolder::Cleanup
;
; INTERFACES:
; IIDLProperty
; IIDLContainer
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitDataManagerFolder::Init
;
; Purpose:
; The constructor of the IDLitDataManagerFolder object.
;
; Parameter
;
function IDLitDataManagerFolder::Init, _EXTRA=_extra

   compile_opt idl2, hidden

   HEAP_NOSAVE, self

   void = self->IDLitIMessaging::Init(_EXTRA=_extra)

   if(self->IDLitContainer::Init(_EXTRA=_extra) eq 0)then $
     return, 0

   self->SetPropertyAttribute,['NAME','DESCRIPTION'],sensitive=0

   return, 1
end


;---------------------------------------------------------------------------
; IDLitDataManagerFolder::Cleanup
;
; Purpose:
;    Destructor for the object.
;

pro IDLitDataManagerFolder::Cleanup

   compile_opt idl2, hidden

   self->IDLitContainer::Cleanup

end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; IDLitDataManagerFolder::AddByIdentifier
;
; Purpose:
;  Overrides the default method of an IDLitContainer to make sure
;  that the target folder exists. If not, a new folder is created.
;
;
pro IDLitDataManagerFolder::AddByIdentifier, strIdentifier, oAddee, $
                          _EXTRA=_extra


    compile_opt idl2, hidden

    ; Just call our superclass. This will automatically
    ; create subfolders of the same class as ourself.
    self->IDLitContainer::AddByIdentifier, strIdentifier, oAddee, $
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitDataManagerFolder::Add
;
; Purpose:
;   This method overrides the default add method and is used to
;   register this object as an observer of the object that it
;   contains.
;
; Parameters:
;   oItems  - The items being added
;
; Keywords:
;   All keywords are passed on
;
pro IDLitDataManagerFolder::Add, oItems, _extra=_extra
  compile_opt idl2, hidden

  oObjs = self->Get(/ALL,count=cnt)
  curNames = strarr(cnt > 1)
  IF (cnt NE 0) THEN BEGIN
    FOR i=0,cnt-1 DO BEGIN
      oObjs[i]->GetProperty,NAME=name
      curNames[i] = name
    ENDFOR
  ENDIF

  self->idlitcontainer::Add, oItems, _extra=_extra

  FOR i=0,n_elements(oItems)-1 DO BEGIN
    ; Get our base name and append the id number.
    oItems[i]->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
    ; See if we have an id number at the end of our identifier.
    idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
    ; Append the id number.
    IF (STRMATCH(idnum, '[0-9]*')) THEN BEGIN
      name += ' ' + idnum
      ; set new name
      oItems[i]->IDLitComponent::SetProperty, NAME=name
      oTool = self->GetTool()
      oTool->DoOnNotify,oItems[i]->GetFullIdentifier(),'SETPROPERTY','NAME'
    ENDIF
    if (~OBJ_ISA(oItems[i], 'IDLitContainer')) then $
        oItems[i]->AddDataObserver, self, /observe_only
  ENDFOR

END


;---------------------------------------------------------------------------
; IDLitDataManagerFolder::AddSubFolder
;
; Purpose:
;  Used to add a sub-folder to the data manager. This folder can be
;  as deep in the hiearchy ass needed.
;
; Parameters:
;   strName    - The name of the new folder
;
; Keywords
;   LOCATION   - The location of the new item. If this is deep, new
;                intermediate folders are created.
;
;   All other keywords are passed to the new folder init method.
;
; Return Value:
;    1 - Success
;    0 - False
;
function IDLitDataManagerFolder::AddSubFolder, strName, $
                               LOCATION=idLoc, $
                               _extra=_extra
   compile_opt idl2, hidden

   oFolder = obj_new("IDLitDataManagerFolder", $
                     NAME=strName, _extra=_extra)

   if(not keyword_set(idLoc))then idLoc = ''

   ; Add this, which will create the sub directory.
   self->AddByIdentifier, idLoc, oFolder

   ; Validate the add
   idTmp = oFolder->GetFullIdentifier()
   oTmp = self->GetByIdentifier(idTmp)

   return, (oTmp eq oFolder)
end


;---------------------------------------------------------------------------
; IDLitDataDataManagerFolder::GetSize
;
; Purpose:
;   Return the size in bytes of this folder and all its
;   contents.
;
; Return Value:
;   The size contained in this data object and it's sub items in bytes.
;
function IDLitDataManagerFolder::GetSize
   compile_opt hidden, idl2

   ; Now the contents of the container
   oData = self->IDL_Container::Get(/all, count=nData)
   nBytes=0
   for i=0, nData-1 do begin
       if(obj_valid(oData[i]))then $ ; bad object?
         nBytes += oData[i]->GetSize() $
       else self->IDL_Container::Remove, oData[i]
   endfor
   return, nBytes
end


;---------------------------------------------------------------------------
; IDLItDataManagerFolder::OnDataChange
;
; Purpose:
;    Used to trigger data change notifications
; Parameters:
;    oSubject - The item that triggered the message
;
pro IDLitDataManagerFolder::OnDataChange, oSubject
    compile_opt idl2, hidden
    ;stub
end


;---------------------------------------------------------------------------
; IDLitDataManagerFolder::OnDataComplete
;
; Purpose:
;    Used to trigger data complete notifications
;
; Parameters:
;    oSubject - The item that triggered the message
;
PRO IDLitDataManagerFolder::OnDataComplete, oSubject
  compile_opt idl2, hidden

  ; Send an update message to the system.
  self->DoOnNotify, oSubject->getFullIdentifier(), "UPDATEITEM", ''

END


;---------------------------------------------------------------------------
; IDLitDataMangerFolder::OnDataDelete
;
; Purpose:
;    Used to trigger data delete notifications
;
; Parameters:
;    oSubject - The item that triggered the message
;
pro IDLitDataManagerFolder::OnDataDelete, oSubject
    compile_opt idl2, hidden

    ; If this item is contained, remove it from this folder
    if(self->IsContained(oSubject))then $
      self->Remove, oSubject

    ; Broadcast an update message.
    self->DoOnNotify, self->getFullIdentifier(), "UPDATEITEM", $
      self->GetFullIdentifier()

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitDataManagerFolder__Define
;
; Purpose:
; Class definition of the object
;
pro IDLitDataManagerFolder__Define

   compile_opt idl2, hidden

   void = {IDLitDataManagerFolder,  $
           inherits   IDLitContainer, $
           inherits   IDLitIMessaging}

end



