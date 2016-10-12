; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitobjdescregistry__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitObjDescRegistry
;
; PURPOSE:
;   This object implements the logic needed to create and manage a
;   collection/heirarchy of object descriptors
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   None
;
; CREATION:
;   See IDLitObjDescRegistry::Init
;
; METHODS:
;   This class has the following methods:
;
;
; INTERFACES:
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; _IDLitObjDescRegistry::Init
;;
;; Purpose:
;; The constructor of the _IDLitObjDescRegistry object.
;;
;; Parameters:
;; NONE
;;
;; Keywords
;;  None

function _IDLitObjDescRegistry::Init

  compile_opt idl2, hidden
  ;; Place holder
  return, 1
end
;;---------------------------------------------------------------------------
;; _IDLitObjDescRegistry::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro _IDLitObjDescRegistry::Cleanup

  compile_opt idl2, hidden

end

;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; _IDLitObjDescRegistry::Register
;;
;; Purpose:
;;   Register an object in the registry
;;
;; Parameters
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strClassName  - The classname of the object
;;
;; Keywords
;;   DESCRIPTION   - The description of the object.
;;
;;  FOLDER_ICON: The name of an icon to use for the folder.
;;      The default is to use the standard tree folder icon.
;;
;;   IDENTIFIER    - The location or identifier for this object.
;;                   If a path is provided and that path doesn't
;;                   exist, containers are created to support this
;;                   path.
;;
;;   OBJ_DESCRIPTOR - Set to the name of the object descriptor class
;;                   to use. If not specified, IDLitObjDesc is used.

pro _IDLitObjDescRegistry::Register, strName, $
                         strClassName, $
                         DESCRIPTION=DESCRIPTION, $
                         FOLDER_CLASSNAME=folderClassname, $
                         FOLDER_ICON=folderIcon, $
                         IDENTIFIER=IDENTIFIER, $
                         OBJ_DESCRIPTOR=OBJ_DESCRIPTOR, $
                         DEFAULT=DEFAULT, $
                         POSITION=position, $
                         PROXY=PROXY, $
                         PRIVATE=private, $
                         FULL_IDENTIFIER=fullIdentifier, $
                         _REF_EXTRA=_extra


  compile_opt idl2, hidden

  if(n_elements(DESCRIPTION) eq 0)then $
    DESCRIPTION=strNAME

  if(n_elements(folderClassname) eq 0) then $
    folderClassname = 'IDLitContainer'

  if(n_elements(IDENTIFIER) eq 0) then $
    IDENTIFIER = strName

  if(n_elements(OBJ_DESCRIPTOR) eq 0)then $
     OBJ_DESCRIPTOR="IDLitObjDesc"

  ;; Ok, get the identifier of the item and validate it. If it doesn't
  ;; exist, create it.
  strItem = IDLitBasename(identifier, REMAINDER=strFolder)

    ; Automatically remove an existing item with same identifier,
    ; so we don't end up registering our new item using an
    ; arbitrary identifier.
    self->UnRegister, identifier

    ; Verify that the target folder exists.
    self->CreateFolders, strFolder, $
        CLASSNAME=folderClassname, $
        FOLDER_ICON=folderIcon, /NOTIFY

  if(keyword_set(PROXY))then  begin
      ;; If the proxy equals this, reject this.
      if(strcmp(identifier, proxy, /fold) eq 1)then begin
          Message, IDLitLangCatQuery('Message:Framework:InvalidProxy'),/continue
          return
      endif
      oDesc = obj_new("IDLitObjDescProxy", self, PROXY, $
                     NAME=strName, IDENTIFIER=strItem, $
                     PRIVATE=private)
  end else begin
      ;; Create the descriptor.
      oDesc = obj_new(OBJ_DESCRIPTOR, NAME=strName, $
                      CLASSNAME=strClassName, $
                      DESCRIPTION=DESCRIPTION, $
                      IDENTIFIER=strItem, $
                      PRIVATE=private, $
                      _STRICT_EXTRA=_extra)
      if (~OBJ_VALID(oDesc)) then $
        MESSAGE, IDLitLangCatQuery('Message:Framework:CannotCreateDescriptor') + $
        OBJ_DESCRIPTOR
  endelse
  ;;Add this to the system
  if(keyword_set(DEFAULT))then $
     self->AddByIdentifier, strFolder, oDesc, position=0 $
  else $
     self->AddByIdentifier, strFolder, oDesc, POSITION=position

  ;; Send the add message
  oDesc->IDLitComponent::GetProperty, _PARENT=parent

  fullIdentifier = oDesc->GetFullIdentifier()

  if (OBJ_VALID(parent)) then $
        self->DoOnNotify, parent->GetFullIdentifier(), "ADDITEMS", fullIdentifier

end
;;---------------------------------------------------------------------------
;; _IDLitObjDescRegistry::UnRegister
;;
;; Purpose:
;;   Remove an operation that was registered with the tool
;;
;; Parameters:
;;     strName     - The name of the operation that was registerd

pro _IDLitObjDescRegistry::UnRegister, strName

   compile_opt idl2, hidden

   if(n_elements(strName) eq 0 || size(strName,/type) ne 7)then $
     return

    oItem = self->GetByIdentifier(strName)
    if (~OBJ_VALID(oItem)) then $
        return
    oItem->GetProperty, _PARENT=oParent
    id = oItem->GetFullIdentifier()

    oItem = self->RemoveByIdentifier(strName)

    ; Send the remove message
    if (OBJ_VALID(oParent)) then begin
        idParent = oParent->GetFullIdentifier()
        self->DoOnNotify, idParent, "REMOVEITEMS", id
        ; If our parent no longer contains any items, remove it as well.
        ; This will recurse up the tree, and will also cause notifications
        ; for each folder removed.
        if (oParent->Count() eq 0) then begin
            self->UnRegister, idParent
        endif
    endif

   ;; Just eat any errors at this point
   if(obj_valid(oItem))then $
       obj_destroy, oItem

end

;---------------------------------------------------------------------------
; _IDLitObjDescRegistry::RegisterComponent
;
; Purpose:
;   Allows a component to be placed in the registry. The provided
;   object is placed in the location described by the given
;   identifier. The only restriction is that the given object isa
;   IDLitComponent.
;
;   Once an object is registered, it is owned by the registry.
;
;   If an object with the same identifier is already present, it is
;   replaced with the new object.
;
; Parameters
;   oComp         - The component to register
;
; Keywords
;  FOLDER_ICON: The name of an icon to use for the folder.
;      The default is to use the standard tree folder icon.
;
;   IDENTIFIER    - The folder location for this object.
;                   If a path is provided and that path doesn't
;                   exist, containers are created to support this
;                   path.
;
pro _IDLitObjDescRegistry::RegisterComponent, oComp, $
    FOLDER_ICON=folderIcon, $
    IDENTIFIER=IDENTIFIER


  compile_opt idl2, hidden

  if(not obj_isa(oComp, "IDLitComponent"))then return

  if(n_elements(IDENTIFIER) eq 0) then $
    IDENTIFIER = ''

    ; Verify that the target folder exists.
    self->CreateFolders, identifier, $
        FOLDER_ICON=folderIcon

    ; Quietly replace previously registered item.
    oComp->GetProperty, IDENTIFIER=idComponent
    fullID = identifier
    if (STRMID(identifier, 0, 1, /REVERSE) ne '/') then $
        fullID += '/'
    fullID += idComponent
    oOldComp = self->GetByIdentifier(fullID)
    if (OBJ_VALID(oOldComp)) then begin
        oOldComp = self->RemoveByIdentifier(fullID)
        OBJ_DESTROY, oOldComp
    endif

    self->AddByIdentifier, identifier, oComp

end


;---------------------------------------------------------------------------
; _IDLitObjDescRegistry::CreateFolders
;
; Purpose:
;   Used to put into place a folder in the registry.
;
; Parameters
;   Folders: The folder. This can contain mulitple levels,
;      (ie /cow/pig) and containers will be created for
;      each level. Also this can be a string array of values.
;
; Keywords:
;  DESCRIPTION: A description to be used for the folder.
;      If Folders is an array then the same description will
;      be used for each folder.
;
;  FOLDER_ICON: The name of an icon to use for the folder.
;      The default is to use the standard tree folder icon.
;      If Folders is an array then the same icon will
;      be used for each folder.
;
;  NOTIFY: If set, then for each parent folder
;       send notification that a child was added.
;
pro _IDLitObjDescRegistry::CreateFolders, strFolders, $
    CLASSNAME=classname, $
    FOLDER_ICON=folderIcon, DESCRIPTION=description, NAME=names, $
    PRIVATE=private, $
    NOTIFY=notify

    compile_opt idl2, hidden

    if n_elements(classname) eq 0 then $
        classname = 'IDLitContainer'
    notify = KEYWORD_SET(notify)
    for i=0, N_ELEMENTS(strFolders)-1 do begin

        ; Does this target folder exist?
        strID = strFolders[i]
        if (OBJ_VALID(self->GetByIdentifier(strID))) then $
            continue
        strPrev = ''
        while (strID ne '') do begin
            ; Ok, the folder doesn't exist, create a valid identifier
            strCurr = IDLitBasename(strID, REMAINDER=strID, /REVERSE)
            ;; use names if passed in, otherwise use the itBasename
            IF (n_elements(names) EQ n_elements(strFolders)) && $
              (names[i] NE '') THEN $
                name=names[i] ELSE name=strCurr
            if (~self->GetByIdentifier(strPrev+strCurr)) then begin
              oFolder = OBJ_NEW(classname, NAME=name, $
                                PRIVATE=private, $
                                IDENTIFIER=strCurr, $
                                ICON=folderIcon, DESCRIPTION=description)
                oFolder->SetPropertyAttribute, $
                    ['NAME', 'DESCRIPTION'], SENSITIVE=0
                self->AddByIdentifier,strPrev, oFolder
                if (notify) then begin
                    oFolder->GetProperty, _PARENT=oParent
                    if(obj_valid(oParent))then begin
                        self->DoOnNotify, oParent->GetFullIdentifier(), $
                            "ADDITEMS", oFolder->GetFullIdentifier()
                    endif
                endif
            endif
            strPrev = strPrev + strCurr +'/'
        endwhile

    endfor

end

;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; _IDLitObjDescRegistry__Define
;;
;; Purpose:
;; Class definition for the _IDLitObjDescRegistry class. This class is
;; assumbed to be part of another subclass that is an
;; IDLitContainer. As such, this object contains no valid instance data.
;;

pro _IDLitObjDescRegistry__Define

  compile_opt idl2, hidden

  void = {_IDLitObjDescRegistry, __void:0b }
end
