; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlittool__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitTool
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   defines all interfaces and encapsulates the functionaltiy of
;   an IDL tool. This generic tool is used to implement all IDL
;   tools.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitContainer
;   IDLitIMessaging
;   _IDLitObjDescRegistry
;
; CREATION:
;   See IDLitTool::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitTool::Init
;
; Purpose:
; The constructor of the IDLitTool object.
;
; Parameters:
;   None.
;
; Keywords:
;    NAME   - The name that should be set for the tool.
;
;   UPDATE_BYTYPE - Set the current setting of the update by type
;                   mode of the tool. If enabled, functionality shall
;                   be added to the tool when new visualization types
;                   are added to it. By default this is enabled.
;
;   All other keywords are pass to the IDLitContainer superclass
;
function IDLitTool::Init, TYPES=TYPES, TOOL=oSys, $
                  UPDATE_BYTYPE=UPDATE_BYTYPE, _EXTRA=_EXTRA

   compile_opt idl2, hidden

   HEAP_NOSAVE, self

   ; Call our super class

   if( self->IDLitContainer::Init(_EXTRA=_extra) eq 0)then $
      return, 0

   ; Allocate any containers we need.
   self->CreateFolders, [ $
        "Operations", $
        "File Readers", $
        "File Writers", $
        "Services"], $
        NAME=["Tool Menus", '', '', '']

   ; We want a special folder bitmap on the style folder.
   self->CreateFolders, "Current Style", $
        FOLDER_ICON='style', $
        DESCRIPTION='Style items for the currently active iTool'
   self->CreateFolders, ["Current Style/Visualizations", $
        "Current Style/Annotations"]

   ; Add manipulator system.
   self._Manipulators = obj_new("IDLitManipulatorManager", $
                                NAME="Manipulators", TOOL=self)
   self._Manipulators->AddManipulatorObserver, self
   self->Add, self._Manipulators

   ; Create status bar, and prepare default status bar segments.
   self._StatusBar = OBJ_NEW('IDLitContainer', IDENTIFIER='STATUS_BAR')
   self->Add, self._StatusBar
   self->RegisterStatusBarSegment, "MESSAGE", NORMALIZED_WIDTH=0.65
   self->RegisterStatusBarSegment, "PROBE", NORMALIZED_WIDTH=0.35

   ; Command Buffer for undo-redo
   self._CommandBuffer  = obj_new("IDLitCommandBuffer", self)

   ; Init the messaging interface
   self->_SetTool, self

    if n_elements(oSys) then begin
        self->_SetSystem, oSys
    endif else begin
        ; Sanity check. If we have been created manually, we still
        ; need the system for LangCat queries.
        self->_SetSystem, _IDLitSys_GetSystem()
    endelse

   self->_InitializeServices


   self._types = ptr_new((keyword_set(types) ? types : ''))

   self._strFilename = 'Untitled' ; Initial setting

   ; Mark the initial location of the Undo/Redo buffer,
   ; needed for the dirty flag.
    self._iBufferLocation = -1

    ; Check type updates (default is on)
    self._bUpdateByType = (n_elements(UPDATE_BYTYPE) gt 0 ? $
                           keyword_set(UPDATE_BYTYPE) : 1)
                           
; Some version information.
@idlitconfig.pro
    self._strVersion = ITOOLS_STRING_VERSION + $
      "$Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlittool__define.pro#1 $"

    return, 1

end
;---------------------------------------------------------------------------
; IDLitTool::_InitializeServices
;
; Purpose:
;   Get the standard services for the tool up and running. This is an
;   internal routine.
;
; Parameters:
;    None.
;
; Keywords:
;    None.
;
pro IDLitTool::_InitializeServices
   ; Register Service Operations

   compile_opt idl2, hidden

   ; Make the service private so it is not visible in browsers.
   oService = self->GetByIdentifier("SERVICES")
   oService->Setproperty, /private

   ; Set the object for our last error.
   self._oLastError = obj_new("IDLitError", CODE=-1)

    oSys = self->_GetSystem()

    ; Proxy all file reader/writers from the System. That way the
    ; programmer can Unregister them in their Tool subclass ::Init
    ; method. Use a proxy so the file reader/writer properties are
    ; shared between all active iTools.
    if (OBJ_VALID(oSys)) then begin
        oSysItems = oSys->GetFileReader(/ALL, COUNT=count)
        for i=0,count-1 do begin
            if (~OBJ_VALID(oSysItems[i])) then $
                continue
            oSysItems[i]->GetProperty, NAME=name
            self->RegisterFileReader, name, $
                PROXY=oSysItems[i]->GetFullIdentifier()
        endfor
        oSysItems = oSys->GetFileWriter(/ALL, COUNT=count)
        for i=0,count-1 do begin
            if (~OBJ_VALID(oSysItems[i])) then $
                continue
            oSysItems[i]->GetProperty, NAME=name
            self->RegisterFileWriter, name, $
                PROXY=oSysItems[i]->GetFullIdentifier()
        endfor
    endif

end
;---------------------------------------------------------------------------
; IDLitTool::Cleanup
;
; Purpose:
;   Destructor of the Tool Class. When called, everything in this
;   tool heirarchy will be destroyed (just a side-effect of how
;   containers work)
;
; Parameters:
;   None.
;
; Keywords:
;   None.
;
pro IDLitTool::Cleanup

   compile_opt idl2, hidden

   self->DisableUpdates ; don't update during destruction.
                         ;without this a crash could happen

   ; Send a shutdown message.
   id = self->GetFullIdentifier()
   self->DoOnNotify, id, "SHUTDOWN",0

   ; Remove this tool from the system
   oSystem = self->_GetSystem()
   if(obj_valid(oSystem))then $
      oSystem->_RemoveTool, self

   ; Kill the undo-redo buffer
   obj_destroy, self._CommandBuffer

   ; Call our super class.
   self->IDLitContainer::Cleanup

   ; Free up our internal dispatch table.
   if(ptr_valid(self._pDispatchTable))then $
     ptr_free, self._pDispatchTable;

   ; And nuke the last error
   obj_destroy, self._oLastError

   ptr_free, self._types
   
   ; Send a shutdown message to non-IDL objects
   void = IDLNotify('IDLitShutdown', id)
   
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitTool::Create
;
; PURPOSE:
;   This function method initializes any heavyweight portions of this
;   visualization.  [Note: the bare essentials for the object are initialized
;   within the ::Init method.]
;
; CALLING SEQUENCE:
;   status = Obj->[IDLitTool::]Create()
;
; OUTPUTS:
;   This function returns a 1 on success, or 0 on failure.
;
;-
function IDLitTool::Create
    compile_opt idl2, hidden
    return, 1
end

;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------
; Registration Section
;
; This section contains methods that are used to register items
; that define the functionality of the tool.



;---------------------------------------------------------------------------
; Override our superclass Register so we can set the TOOL keyword.
;
pro IDLitTool::Register, strName, strClassName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->_IDLitObjDescRegistry::Register, strName, strClassName, $
        OBJ_DESC='IDLitObjDescTool', $   ; default for ourself
        TOOL=self, $ ; we must set this here (CT)
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; RegisterVisualization
;
; Purpose:
;   Register a visualization class with the tool object. The
;   classes registered are used to create visualizations in this
;   tool.
;
; Parameters:
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   IDENTIFIER  - The relative location of where to place the
;                 visualization discriptor. These are placed in the
;                 tools visualization folder.
;
pro IDLitTool::RegisterVisualization, strName, strClassName, $
    IDENTIFIER=IDENTIFIER, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; No identifier, just use the name
    if (~keyword_set(IDENTIFIER)) then $
        IDENTIFIER=strName

    self->Register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        IDENTIFIER="Current Style/Visualizations/"+Identifier, $
        _EXTRA=_extra
end


;---------------------------------------------------------------------------
; UnRegisterVisualization
;
; Purpose:
;   Remove a visulization that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registerd. This is
;                   the identiifer used during the registration process.
;
pro IDLitTool::UnRegisterVisualization, strItem

   compile_opt idl2, hidden

   self->UnRegister,"Current Style/Visualizations/"+strItem

end

;---------------------------------------------------------------------------
; RegisterAnnotation
;
; Purpose:
;   Register an annotation class with the tool object. The
;   classes registered are used to create annotations in this
;   tool.
;
; Parameters:
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   IDENTIFIER  - The relative location of where to place the
;                 annotation discriptor. These are placed in the
;                 tools annotations folder.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitTool::RegisterAnnotation, strName, strClassName, $
             IDENTIFIER=IDENTIFIER, $
             _EXTRA=_extra

    compile_opt idl2, hidden

    if (~keyword_set(IDENTIFIER)) then $
        IDENTIFIER=strName

    self->Register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        IDENTIFIER="Current Style/Annotations/"+Identifier, $
        _EXTRA=_extra
end


;---------------------------------------------------------------------------
; UnRegisterAnnotation
;
; Purpose:
;   Remove an annotation that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registerd. This is
;                   the identiifer used during the registration process.
;
;   Added, CT, Jan 2003.
;
pro IDLitTool::UnRegisterAnnotation, strItem

   compile_opt idl2, hidden

   self->UnRegister,"Current Style/Annotations/"+strItem

end


;---------------------------------------------------------------------------
; RegisterOperation
;
; Purpose:
;   Register a Operation class with the tool object.
;
; Parameters
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   PROXY   - Set this keyword to the identifier (full or relative)
;             to the operation that this item being registered
;             should proxy. When proxied, all calls made on the
;             object are vectored off to the target object which is
;             referenced by the provided identifier.
;
;   IDENTIFIER  - The relative location of where to place the
;                 operation discriptor. These are placed in the
;                 tools folder.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitTool::RegisterOperation, strName, strClassName, $
             PROXY=PROXY, $
             IDENTIFIER=IDENTIFIER,  _EXTRA=_extra


  compile_opt idl2, hidden

  if(not keyword_set(IDENTIFIER))then IDENTIFIER=strName

  self->register, strName, strClassName, $
        IDENTIFIER="Operations/"+IDENTIFIER, $
        /SINGLETON, PROXY=PROXY, _extra=_extra
end


;---------------------------------------------------------------------------
; UnRegisterOperation
;
; Purpose:
;   Remove an operation that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registered. This is
;                   the identiifer used during the registration process.
;
pro IDLitTool::UnRegisterOperation, strItem

   compile_opt idl2, hidden


   self->UnRegister, "Operations/"+strItem

end


;---------------------------------------------------------------------------
; RegisterFileReader
;
; Purpose:
;   Register a File class with the tool object. The
;   classes registered are used to read file contents in this
;   tool.
;
; Parameter
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   PROXY   - Set this keyword to the identifier (full or relative)
;             to the reader that this item being registered
;             should proxy. When proxied, all calls made on the
;             object are vectored off to the target object which is
;             referenced by the provided identifier.
;
;   IDENTIFIER  - The relative location of where to place the
;                 reader discriptor. These are placed in the
;                 tools folder.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitTool::RegisterFileReader, strName, strClassName, $
             IDENTIFIER=IDENTIFIER, PROXY=PROXY, $
             _EXTRA=_extra


  compile_opt idl2, hidden

  if(not keyword_set(IDENTIFIER))then IDENTIFIER=strName

  self->register, strName, strClassName, $
        PROXY=PROXY, /SINGLETON, $
        IDENTIFIER="File Readers/"+IDENTIFIER, $
        _EXTRA=_extra
end


;---------------------------------------------------------------------------
; UnRegisterFileReader
;
; Purpose:
;   Remove a file reader that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registered. This is
;                   the identiifer used during the registration process.
;
pro IDLitTool::UnRegisterFileReader, strItem

   compile_opt idl2, hidden

   self->UnRegister,"File Readers/"+strItem

end


;---------------------------------------------------------------------------
; RegisterFileWriter
;
; Purpose:
;   Register a File class with the tool object. The
;   classes registered are used to read file contents in this
;   tool.
;
; Parameter
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   PROXY   - Set this keyword to the identifier (full or relative)
;             to the writer that this item being registered
;             should proxy. When proxied, all calls made on the
;             object are vectored off to the target object which is
;             referenced by the provided identifier.
;
;   IDENTIFIER  - The relative location of where to place the
;                 writer discriptor. These are placed in the
;                 tools folder.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitTool::RegisterFileWriter, strName, strClassName, $
             IDENTIFIER=IDENTIFIER, PROXY=PROXY, $
             _EXTRA=_extra


  compile_opt idl2, hidden

  if(not keyword_set(IDENTIFIER))then IDENTIFIER=strName

  self->register, strName, strClassName, $
        PROXY=PROXY, /SINGLETON,  $
        IDENTIFIER="File Writers/"+IDENTIFIER, $
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; UnRegisterFileWriter
;
; Purpose:
;   Remove a file Writer that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registered. This is
;                   the identiifer used during the registration process.
;
pro IDLitTool::UnRegisterFileWriter, strItem

   compile_opt idl2, hidden

   self->UnRegister, "File Writers/"+strItem

end


;---------------------------------------------------------------------------
; RegisterManipulator
;
; Purpose:
;   Register a Manipulator class with the tool object.
;
; Parameters
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords
;   DESCRIPTION   - The description of the object.
;
;   DEFAULT       - Mark this manipulator as default. The default
;                   manipulator, there can only be one, is set as
;                   current when a transient manipulator is executed.
;
;   GLOBAL      - Set this keyword to indicate that the registered
;                 manipulator should be active (via auto-switch mode)
;                 in combination with all other registered manipulators.
;
;   IDENTIFIER  - The relative location of where to place the
;                 manipulator.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitTool::RegisterManipulator, strName, strClassName, $
             DESCRIPTION=DESCRIPTION, IDENTIFIER=IDENTIFIER, $
             GLOBAL=GLOBAL, $
             DEFAULT=DEFAULT, _REF_EXTRA=_extra


  compile_opt idl2, hidden
  if(n_elements(DESCRIPTION) eq 0)then $
    DESCRIPTION=strNAME

  if(not keyword_set(IDENTIFIER))then $
    IDENTIFIER=strupcase(strName)

  IDENTIFIER="Manipulators/"+IDENTIFIER
  ; Ok, get the identifier of the item and validate it. If it doesn't
  ; exist, create it.
  strItem = IDLitBasename(identifier, REMAINDER=strID)

  strFolder = strID
  strPrev = ''
  ; Does this target folder exist?
  while (~OBJ_VALID(self->GetByIdentifier(strFolder)) and $
       strID ne '')do begin
      ; Ok, the folder doesn't exist, create a valid identifier
      strCurr = IDLitBasename(strID, REMAINDER=strID, /reverse)
      if (~OBJ_VALID(self->GetByIdentifier(strPrev+strCurr))) then begin
          oFolder = obj_new("IDLitManipulatorContainer", NAME=strCurr, TOOL=self)
          self->AddByIdentifier,strPrev, oFolder
      endif
      strPrev = strPrev + strCurr +'/'
  end

  ; Ok, with Manipulators, we just go and create the manipulator
  oManip = Obj_New(strClassName, NAME=strName, $
                   DESCRIPTION=DESCRIPTION,  $
                   IDENTIFIER=strItem, $
                   _EXTRA=_extra, TOOL=self)

  oParent=self->GetByIdentifier(strFolder)
  oParent->Add, oManip, DEFAULT=DEFAULT, GLOBAL=GLOBAL

end


;---------------------------------------------------------------------------
; UnRegisterManipulator
;
; Purpose:
;   Remove an manipulator that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registered. This is
;                   the identiifer used during the registration process.
;
pro IDLitTool::UnRegisterManipulator, strItem, _EXTRA=_extra

   compile_opt idl2, hidden

   if(n_elements(strItem) eq 0 || size(strItem,/type) ne 7)then $
     return
   oItem = self->RemoveByIdentifier("Manipulators/"+strItem, _EXTRA=_extra)
   ; Just eat any errors at this point
   if(obj_valid(oItem))then $
       obj_destroy, oItem

end


;---------------------------------------------------------------------------
; IDLitTool::RegisterStatusBarSegment
;
; Purpose:
;   This procedure method registers a status bar segment.
;
; Arguments:
;   strName: A string representing the human-readable name of the status
;     bar segment.
;
; Keywords:
;   IDENTIFIER: Set this keyword to a string representing the identifier
;     for the status bar segment being registered.  By default, the strName
;     argument is used as the identifier.
;
;   NORMALIZED_WIDTH: Set this keyword to a scalar (greater than 0, and
;     less than or equal to 1.0) indicating the normalized width of the
;     portion of the overall status bar that this segment should occupy.
;     The default is 1.0.
;
pro IDLitTool::RegisterStatusBarSegment, strName, $
    IDENTIFIER=identifier, $
    NORMALIZED_WIDTH=normalized_width

    compile_opt idl2, hidden

    if (~KEYWORD_SET(identifier)) then $
        identifier = STRUPCASE(strName)

    ; Verify that the status bar id is only one level deep.
    parentId = IDLitBasename(identifier, REMAINDER=parentPath)
    if (parentPath ne '') then begin
        self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:RegisterStatusBar:Title'), $
            IDLitLangCatQuery('Error:RegisterStatusBar:Text'), SEVERITY=2
        return
    endif

    ; Create and add the status bar segment.
    oStatusSegment = OBJ_NEW('IDLitStatusSegment', $
        NAME=strName, IDENTIFIER=identifier, $
        NORMALIZED_WIDTH=normalized_width, $
        MESSAGE_TYPE_CODE=10+self._currStatusSegmentId)

    self._StatusBar->Add, oStatusSegment

    self._currStatusSegmentId++
end


;---------------------------------------------------------------------------
; IDLitTool::UnRegisterStatusBarSegment
;
; Purpose:
;   This procedure method unregisters a status message bar segment.
;
; Parameters:
;     strId     - A string representing the identifier (used during the
;                 registration process) of the status bar segment to
;                 be unregistered.
;
pro IDLitTool::UnRegisterStatusBarSegment, strId

    compile_opt idl2, hidden

    ; Remove the corresponding status bar segment.
    oSegment = self._StatusBar->RemoveByIdentifier(strId)
    if (OBJ_VALID(oSegment)) then $
        OBJ_DESTROY, oSegment
end


;---------------------------------------------------------------------------
; IDLitTool::GetStatusBarSegments
;
; Purpose:
;   This function method returns status bar segments registered with
;   this tool.
;
; Return Value:
;   If the IDENTIFIER keyword is set, then the status bar segment matching
;   that identifier is returned.
;
;   If the IDENTIFIER keyword is not set, all status bar segments are
;   returned.
;
; Keywords:
;   COUNT: Set this keyword to a named variable that upon return will
;     contain the number of status bar segments returned.
;
function IDLitTool::GetStatusBarSegments, $
    COUNT=count, $
    IDENTIFIER=identifier

    compile_opt idl2, hidden

    count = 0

    if (KEYWORD_SET(identifier)) then begin
        oSegments = self._StatusBar->GetByIdentifier(identifier)
        if (OBJ_VALID(oSegments)) then $
            count = 1
    endif else $
        oSegments = self._StatusBar->Get(/ALL, COUNT=count)

    return, (count eq 0 ? OBJ_NEW() : oSegments)

end


;---------------------------------------------------------------------------
; IDLitTool::GetStatusMessageId
;
; Purpose:
;   This function method returns the identifier of the status bar
;   segment that corresponds to the given type code.
;
; Return Value:
;   This function returns a string representing the full identifier
;   of the status bar segment that matches the given type code, or
;   an empty string if none found.
;
; Arguments:
;   msgTypeCode: An scalar representing the type code.
;
function IDLitTool::GetStatusMessageId, msgTypeCode
    compile_opt idl2, hidden

    ; Walk through the status bar segments until a matching code
    ; is found.
    oSegments = self._StatusBar->Get(/ALL, COUNT=nSegments)
    for i=0,nSegments-1 do begin
        oSegments[i]->GetProperty, MESSAGE_TYPE_CODE=segTypeCode
        if (segTypeCode eq msgTypeCode) then $
             return, oSegments[i]->GetFullIdentifier()
    endfor

    return,''
end


;---------------------------------------------------------------------------
; IDLitTool::AddService
;
; Purpose:
;   Used to add a service to the system. An active object is expecte
;   to be passed into this routine.
;
; Parameters:
;   oService    - The service being added.
;
; Keywords:
;   None.
;
PRO IDLitTool::AddService, oService

   compile_opt idl2, hidden

   if(not obj_valid(oService))then begin
      self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:AddService:Title'), $
       IDLitLangCatQuery('Error:AddService:Text'), severity=2
       return
   endif

   oService->GetProperty, identifier=id

   ; Check if this service already exist in this tool
   if(keyword_set(id))then begin
       oCheck = self->GetByIdentifier("SERVICES/"+id)

       if(obj_valid(oCheck))then begin
           self->SignalError, IDLitLangCatQuery('Error:ServiceReg:Text1')+id  $
       + IDLitLangCatQuery('Error:ServiceReg:Text2')
          oCheck =self->RemoveByIdentifier("SERVICES/"+id)
          obj_destroy, oCheck
       endif
   endif
   oService->_setTool, self

   self->AddByIdentifier, "SERVICES", oService

end


;---------------------------------------------------------------------------
; IDLitTool::GetService
;
; Purpose:
;   Provides a direct method to get a service.
;
; Parameters:
;  idService   - The desired service ident/name
;
; Return Value:
;   The desired service or null object if it cannot be found.
;
function IDLitTool::GetService, idService

   compile_opt idl2, hidden
   if ((SIZE(idService, /TYPE) ne 7) || (idService eq '')) then $
    return, OBJ_NEW()
   oService = self->GetByIdentifier("SERVICES/"+idService)

   if(not obj_valid(oService))then begin ; Check system
       oSystem = self->_getSystem()
       if(obj_valid(oSystem))then begin
           oService = oSystem->GetService(idService)
           if(obj_valid(oService))then $
             oService->_SetTool, self
       endif
   endif
   return, oService
end


;---------------------------------------------------------------------------
; Item access routines.
;
; This section contains routines used to gain temporary access to
; items registered with the tool. The intent of these routines is to
; allow user interface systems the ability to construct the neccessary
; elements that represent the contents of the tool.
;---------------------------------------------------------------------------
; IDLitTool::GetOperations
;
; Purpose:
;  This routine is used to return the operation hierarchy contained
;  in the tool. This hierarchy is composed of object
;  descriptors. It is intended that the entity accessing these items
;  will use them to build the needed menu items in the user interface.
;
; Return Value
;    Requested object(s).
;
;    no ID      - The contents of our operation contianer.
;
;    ID         - The target object. If the target object
;                 is a container, the contents of that container
;                 are returned. If the target is a descriptor, that
;                 descriptor is returned.
;
;    If the item doesn't exist, a NULL object is returned.
;
; Parameters:
;    None.
;
; Keywords:
;  COUNT  - The number of elements returned.
;
;  IDENTIFIER - The operation relative operation to retrieve
;
FUNCTION IDLitTool::GetOperations, COUNT=count, IDENTIFIER=identifier

    compile_opt idl2, hidden

    count = 0

    oItem = KEYWORD_SET(identifier) ? $
        self->IDLitContainer::GetbyIdentifier("Operations/"+identifier) : $
        self->IDLitContainer::GetbyIdentifier("Operations")

    if (~OBJ_VALID(oItem)) then $
        return, OBJ_NEW()

    if (~OBJ_ISA(oItem, "IDLitContainer")) then begin
        count = 1
        return, oItem
    endif

    oOps = oItem->IDL_Container::Get(/ALL, COUNT=count)
    return, ((count eq 0) ? OBJ_NEW() : oOps)

end


;---------------------------------------------------------------------------
; IDLitTool::_GetReaderWriter
;
; Purpose:
;  Generic method called to retrieve the object descriptors for all
;  objects of a certain type registered with the tool.
;
; Parameters:
;  id - The items to get
;  Container - The name of an IDLitTool container.
;
; Keywords:
;  ALL    - Return all registered items.
;
;  COUNT  - The number of elements returned.
;
function IDLitTool::_GetReaderWriter, container, id, $
    COUNT=COUNT, ALL=all

    compile_opt idl2, hidden

    if (~KEYWORD_SET(all)) then begin
        ; Look for the Reader/Writer.
        oToolItem = $
            self->IDLitContainer::GetbyIdentifier(container + "/" + id)
        count = OBJ_VALID(oToolItem)
    endif else begin
        oContainer = self->IDLitContainer::GetbyIdentifier(container)
        if (OBJ_VALID(oContainer)) then begin
            oToolItem = oContainer->Get(/ALL, COUNT=count)
        endif else $
            count = 0
        if (count eq 0) then $
            return, OBJ_NEW()
    endelse


    ; Set the tool on our proxy objects.
    for i=0,count-1 do begin
        if (OBJ_ISA(oToolItem[i], 'IDLitObjDescProxy')) then begin
            oDesc = oToolItem[i]->_GetProxyTarget()
            if (OBJ_VALID(oDesc)) then $
                oDesc->_SetTool, self
        endif
    endfor

    return, oToolItem

end


;---------------------------------------------------------------------------
; Internal method to retrieve either visualizations or annotations.
;
function IDLitTool::_GetVisualization, folder, id, $
    ALL=all, COUNT=count, ISA=isa

    compile_opt idl2, hidden

    count = 0

    if (KEYWORD_SET(all)) then begin
        oContainer = self->IDLitContainer:: $
            GetbyIdentifier("Current Style/" + folder)
        if (~OBJ_VALID(oContainer)) then $
            return, OBJ_NEW()
        oVis = oContainer->IDL_Container::Get(/ALL, $
            COUNT=count, ISA=isa)
        return, ((count eq 0) ? OBJ_NEW() : oVis)
    endif

    if (N_ELEMENTS(id) eq 0) then $
        return, OBJ_NEW()

    oDesc = self->IDLitContainer::GetbyIdentifier("Current Style/" + $
        folder + '/' + id)
    count = OBJ_VALID(oDesc)

    return, oDesc

end


;---------------------------------------------------------------------------
; IDLitTool::GetVisualization
;
; Purpose:
;  Called to retrieve the object descriptors for all the
;  visualization objects registered with the tool.
;
; Parameters:
;  id - The visualization to get
;
; Keywords:
;  ALL    - Return all registered vis
;
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitTool::GetVisualization, id, COUNT=COUNT, ALL=ALL

    compile_opt idl2, hidden

    return, self->_GetVisualization('Visualizations', id, $
        ALL=all, COUNT=count)

end


;---------------------------------------------------------------------------
; IDLitTool::GetAnnotation
;
; Purpose:
;  Called to retrieve the object descriptors for all the
;  Annotation objects registered with the tool.
;
; Parameters:
;  Annotation - The annotation to retrieve
;
; Keywords:
;  ALL    - Return all annotations available. This is system and tool
;           scoped.
;
;  COUNT  - The number of elements returned.
;
function IDLitTool::GetAnnotation, id, ALL=all, COUNT=count

    compile_opt idl2, hidden

    return, self->_GetVisualization('Annotations', id, $
        ALL=all, COUNT=count)

end


;---------------------------------------------------------------------------
; IDLitTool::GetCurrentManipulator
;
; Purpose:
;   Used to gain external access to the current manipulator.
;
; Parameters:
;   None:
;
; Return Value:
;  The reference to the current manipulator.
;
function IDLitTool::GetCurrentManipulator, _REF_EXTRA=_extra

   compile_opt idl2, hidden

   return, self._Manipulators->GetCurrentManipulator(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; IDLitTool::GetManipulators
;
; Purpose:
;   Used to gain external access to the manipulators
;   managed/contained in this tool.
;
; Parameters:
;   None:
;
; Keywords:
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitTool::GetManipulators, COUNT=COUNT

   compile_opt idl2, hidden

   oItem = self._Manipulators->IDL_Container::Get(/All, COUNT=COUNT)
   return, (count eq 0 ? obj_new() : oItem)

end


;---------------------------------------------------------------------------
; IDLitTool::GetFileReader
;
; Purpose:
;   Used to gain external access to the File Reader object
;   descriptors contained in this tool.
;
; Parameters:
;   id  - The reader to return
;
; Keywords:
;  ALL    - Return All readers
;
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitTool::GetFileReader, id, COUNT=COUNT, ALL=ALL

    compile_opt idl2, hidden

    if (N_PARAMS() eq 0) then begin
        return, self->IDLitTool::_GetReaderWriter('File Readers', $
            COUNT=count, ALL=all)
    endif

    return, self->IDLitTool::_GetReaderWriter('File Readers', id, $
        COUNT=count, ALL=all)

end


;---------------------------------------------------------------------------
; IDLitTool::GetFileWriter
;
; Purpose:
;   Used to gain external access to the File writer object
;   descriptors contained in this tool.
;
; Parameters:
;   ID - The id of the desired writer
;
; Keywords:
;  ALL    - Return all
;
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitTool::GetFileWriter, ID, COUNT=COUNT, ALL=ALL

    compile_opt idl2, hidden

    if (N_PARAMS() eq 0) then begin
        return, self->IDLitTool::_GetReaderWriter('File Writers', $
            COUNT=count, ALL=all)
    endif

    return, self->IDLitTool::_GetReaderWriter('File Writers', id, $
        COUNT=count, ALL=all)

end


;---------------------------------------------------------------------------
; IDLitTool::GetThumbnail
;
; Purpose:
;   Returns a 3xMxM thumbnail image of the tool.
;
; Parameters:
;   NONE
;
; Keywords:
;   THUMBSIZE : The size of the thumbnail to return.  The thumbnail is always
;               returned as a square image.  If not supplied a default value
;               of 32 is used.  THUMBSIZE must be greather than 3 and must 
;               shrink the tool window.
;
;   THUMBBACKGROUND : The colour of the excess background to use in the 
;                     thumbnail.  This only has effect if the aspect ratio of
;                     the tool window is not equal to 1.  If set to a scalar
;                     value the colour of the lower left pixel of the window
;                     is used as the background colour.  If set to an RGB
;                     triplet the supplied colour will be used.  If not
;                     specified a value of [255,255,255] (white) is used.
;
;   THUMBORDER : Set this keyword to return the thumbnail in top-to-bottom order
;            rather than the IDL default of bottom-to-top order.
;
FUNCTION IDLitTool::GetThumbnail, _EXTRA=_extra

  compile_opt idl2, hidden

  ;; Return a scalar if something fails
  thumb = 0b
  
  oWinSrc = self->GetCurrentWindow()
  if (~OBJ_VALID(oWinSrc)) then $
    return, thumb
    
  oRaster = self->GetService("RASTER_BUFFER")
  if (~OBJ_VALID(oRaster)) then $
    return, thumb
    
  status = oRaster->DoWindowCopy(oWinSrc, oWinSrc->GetScene())
  if (status ne 1) then $
    return, thumb

  status = oRaster->GetData(bits)
  if (status ne 1) then $
    return, thumb

  return, _IDLitThumbResize(bits, _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Public "Action" routines.
;
; Purpose:
; The routines in this section are called to perform actions in the
; tool. An example of the use of these routines would be the in
; response to some action or event that took place in a user
; interface exposed for this tool
;---------------------------------------------------------------------------
; IDLitTool::DoAction
;
; Purpose:
;   This public routine is used to instigate the performance of an
;   action by the target object. This is the main point used to start
;   actions performed by the tool. The path or identifier for the
;   target object is provided to this method, which then locates
;   the object and calls the DoAction method on the target object.
;
;   The method also manages any interactions with the command buffer
;   and commands (or command sets) generated by the operation.
;
; Return Value:
;   0 - Failure   - Error messages shall be propagated up via the
;                   error messaging system.
;   1 - Success
;
; Parameter:
;   strID - ID to the target operation.
;
function IDLitTool::DoAction, strID, _REF_EXTRA=_extra

   compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch,/cancel
      self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
        [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], severity=2
       return, 0
   endif

   ; Locate the target operation descriptor
   oTargetDesc = self->IDLitContainer::GetByIdentifier(strID)
   if (not OBJ_VALID(oTargetDesc)) then begin
      self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
        IDLitLangCatQuery('Error:Framework:CannotFindTargetDescriptor')+strID, severity=2
      return, 0
   endif

   ; If this target is an object descriptor, get an object instance
   if(obj_isa(oTargetDesc, "IDLitObjDesc"))then begin
       ; Get the object instance.
       oTarget = oTargetDesc->GetObjectInstance() ;
   endif else $
     oTarget = oTargetDesc

   if (not OBJ_VALID(oTarget)) then begin
      self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
        IDLitLangCatQuery('Error:Framework:CannotGetObjInstance') +strID
       return, 0
   endif

   ; Update the status message.
   oTargetDesc->GetProperty, NAME=name, DESCRIPTION=desc

   ; Use the description unless it is null, in which case
   ; use the name, unless it is null, otherwise use the strID.
   msg = (desc ne '') ? desc : ((name ne '') ? name : strID)
   if (desc ne '') then $
     self->StatusMessage, msg

   ; Set the operating env for this execution
   oTarget->_SetTool, self
   ; Ok perform the target action on the operation
   ; The operation will return the resulting command object
   ; for what was performed.
   if (N_ELEMENTS(_extra) ne 0) then $
       oCommand = oTarget->DoAction(self, _STRICT_EXTRA=_extra) $
   else $
       oCommand = oTarget->DoAction(self)

   ; for macros and history add only registered operations (objDescs)
   if obj_isa(oTargetDesc, 'IDLitObjDesc') && obj_valid(self) then begin
        oTarget->GetProperty, MACRO_SHOWUIIFNULLCMD=MacroShowUIifNullCmd
        ; some operations need to be forced to display UI if command null
        ; (File/Open, for example).
        ; leave showUI undefined for default operations
        if ~obj_valid(oCommand[0]) && MacroShowUIifNullCmd then showUI=1

        oSrvMacro = self->GetService('MACROS')
        if OBJ_VALID(oSrvMacro) then begin
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            idTool = self->GetFullIdentifier()
            oTarget->GetProperty, SKIP_MACRO=skipMacro
            oSrvMacro->PasteMacroOperation, oTargetDesc, currentName, $
                IDTOOL=idTool, $
                SHOW_EXECUTION_UI=showUI, $
                SKIP_MACRO=skipMacro
        endif
   endif

   ; If this is a tool object descriptor, return the object instance.
   if(obj_isa(oTargetDesc, "IDLitObjDescTool"))then $
     oTargetDesc->ReturnObjectInstance, oTarget ; return object.

   ; Did this command execute correctly? If so, transact the data.
   if(obj_valid(oCommand[0]))then begin ; executed correctly
       ;Add the command object to the command buffer
       if (OBJ_VALID(self)) then begin
           self->_TransactCommand, oCommand
           self->_ClearLastError
       endif else begin
           OBJ_DESTROY, oCommand
       endelse
   endif else begin
        ; See if the Undo/Redo names changed. This is really only needed
        ; for the Undo/Redo operations, but could be useful with other
        ; operations that change the command buffer.
        if (OBJ_VALID(self)) then $
            self._CommandBuffer->IDLitCommandBuffer::_NotifyUIUpdates
   endelse

   return, 1
end

;---------------------------------------------------------------------------
; IDLitTool::_ClearLastError
;
; Purpose:
;   Clear out the last error stored for this tool.
;
pro IDLitTool::_ClearLastError
    compile_opt idl2, hidden

    self._oLastError->SetProperty, code=0, description='', $
        severity='', message=''

end

;---------------------------------------------------------------------------
; IDLitTool::ActivateManipulator
;
; Purpose:
;  This procedure method activates a manipulator.
;
; Arguments:
;  Identifier: A string representing the relative or full identifier
;   of the manipulator to activate.
;
; Keywords:
;  DEFAULT: Set this keyword to a nonzero value to indicate that the
;    default manipulator registered with the tool should be activated.
;    If this keyword is set, the Identifier argument is ignored.
;
pro IDLitTool::ActivateManipulator, Identifier, $
    DEFAULT=default

    compile_opt idl2, hidden

    if (KEYWORD_SET(default)) then begin

       oManip = self._Manipulators->GetDefaultManipulator()
       if (~OBJ_VALID(oManip)) then begin
           oManip = self._Manipulators->IDL_Container::Get()
           if (~OBJ_VALID(oManip)) then $
               return
       endif

       fullID = oManip->GetFullIdentifier()

    endif else begin

        ; Construct full identifier of input.
        fullID = STRUPCASE(identifier)

        ; If relative identifier, prepend manipulator folder.
        if (~STRCMP(identifier, '/', 1)) then $
            fullID = self->GetFullIdentifier() + '/MANIPULATORS/' + fullID

    endelse

    ; If the requested manipulator is the same as the current
    ; maniplator, then no action required.
    oCurrManip = self->GetCurrentManipulator()
    if (OBJ_VALID(oCurrManip)) then begin
        currID = oCurrManip->GetFullIdentifier()
        if (currID eq fullID) then $
            return
    endif

    result = self->DoAction(fullID)
end


;---------------------------------------------------------------------------
; Purpose:
;  Check if the current state needs to be saved.
;
; Result:
;  Returns a 1 if the caller can continue with their operation,
;  returns a 0 if an error occurs (caller needs to decide what to do)
;  returns a -1 if the user hit cancel from the file selection dialog,
;  and the caller should therefore cancel their own operation.
;
; Arguments:
;  None.
;
; Keywords:
;  None.
;
function IDLitTool::_CheckForUnsaved, bDirty

    compile_opt idl2, hidden

    ; If we aren't dirty, return success.
    if (~self._bDirty || self._noSavePrompt) then $
        return, 1

    ; Bring tool to front to ensure that save prompt dialog is visible
    iSetCurrent, self->GetFullIdentifier(), /SHOW
    
    ; If our current state is dirty, prompt to save first.
    status = self->PromptUserYesNo( $
        "Save changes to " + self._strFilename + "?", $
        answer, $
        DEFAULT_NO=0, $
        TITLE='Save', $
        /CANCEL)

    ; An error occurred.
    if (status eq 0) then $
        return, 0

    ; User hit "No", just return success.
    if (answer eq 0) then $
        return, 1

    ; User hit "Cancel", return cancel flag.
    if (answer eq -1) then $
        return, -1

    ; User indicated they want to save,
    ; so fire up the Save operation.
    if (~self->DoAction("OPERATIONS/FILE/SAVE", $
        SUCCESS=success)) then $
        return, 0  ; error

    ; Return the success flag from the Save operation.
    ; This could be 1 for success, 0 for an error, or -1 if the
    ; user hit cancel on a file selection dialog.
    return, success

end


;---------------------------------------------------------------------------
; Purpose:
;  Calculate position for a new dataspace
;
pro IDLitTool::_CalculatePosition, POSITION=position, $
                                   MARGIN=margin, $
                                   DEVICE=device, $
                                   LAYOUT=layout, $
                                   OVERPLOT=overplot, $
                                   TITLE=dataspaceTitle, $
                                   XTICKFONT_SIZE=xticksize, $
                                   YTICKFONT_SIZE=yticksize, $ 
                                   ZTICKFONT_SIZE=zticksize, $
                                   XTICKLEN=xticklen, $
                                   YTICKLEN=yticklen, $
                                   ZTICKLEN=zticklen, $
                                   FONT_SIZE=fontSize
    compile_opt idl2, hidden

  ; Get position
  if ((N_ELEMENTS(layout) gt 0) && $
    ~KEYWORD_SET(overplot) && (N_ELEMENTS(position) lt 2)) then begin
    if (N_ELEMENTS(layout) ne 3) then $
      MESSAGE, 'LAYOUT must have 3 elements.'
    if (MIN(layout) lt 1) then $
      MESSAGE, 'Illegal value for LAYOUT.'
    ncol = LONG(layout[0])
    nrow = LONG(layout[1])
    n = nrow > ncol
    index = (LONG(layout[2])-1) mod (ncol*nrow)

    nm = N_ELEMENTS(margin)
    if (nm gt 0) then begin
      if (nm ne 1 && nm ne 4) then $
        MESSAGE, 'MARGIN must have 1 or 4 elements.'
      margin = DOUBLE((nm eq 4) ? margin : REPLICATE(margin[0], 4))
      if (KEYWORD_SET(device)) then begin
        oWin = self->GetCurrentWindow()
        if (ISA(oWin)) then begin
          oWin->GetProperty, DIMENSIONS=winDims
          margin /= [winDims,winDims]
          ; Cancel the device keyword, it has been taken into account here
          device = 0
        endif
      endif
      if (MIN(margin, MAX=mx) lt 0 || mx gt 0.5) then $
        MESSAGE, 'Illegal value for MARGIN.'
    endif else begin
      top = ISA(dataspaceTitle,'STRING') ? 0.11d : 0.1d
      margin = [0.15d,0.13d,0.08d,top]
      if (n eq 1) then begin
        margin = [0.13d,0.13d,0.08d,0.11]
      endif else if (n eq 2) then begin
        margin = [0.17d,0.14d,0.08d,0.11]
      endif else if (n gt 2) then begin
        margin = [0.17d,0.15d,0.08d,0.11]
      endif
    endelse

    ; Width and height of a single cell.
    baseWidth = 1d/ncol
    baseHeight = 1d/nrow
    width = (baseWidth - margin[0]*baseWidth - margin[2]*baseWidth) > 0.05
    height = (baseHeight - margin[1]*baseHeight - margin[3]*baseHeight) > 0.05
    col = index mod ncol
    row = index/ncol
    x1 = col*(baseWidth) + margin[0]*baseWidth
    y1 = (nrow-row-1)*(baseHeight) + margin[1]*baseHeight
    position=[x1,y1,x1+width,y1+height]

    ; For 3 or more columns/rows, decrease the font size
    if (~ISA(fontSize) && ~ISA(xticksize) && ~ISA(yticksize) && ~ISA(zticksize)) then begin
      xticksize = (n gt 2) ? 9 : ((n eq 2) ? 12 : 16)
      yticksize = xticksize
      zticksize = xticksize
    endif
    
    ; For 3 or more columns/rows, decrease the tick length
    if (~ISA(xticklen) && ~ISA(yticklen) && ~ISA(zticklen)) then begin
      xticklen = (n gt 2) ? 0.015d : ((n eq 2) ? 0.025d : 0.05d)
      yticklen = xticklen
      zticklen = xticklen
    endif
    
  endif

end


;---------------------------------------------------------------------------
; Purpose:
;  Set/unset the dirty flag and notify.
;
; Arguments:
;  Dirty: Set to a 0 or a 1.
;
; Keywords:
;  None.
;
pro IDLitTool::_SetDirty, bDirty

    compile_opt idl2, hidden

    if (bDirty eq self._bDirty) then $
        return

    self._bDirty = bDirty

;    void = IDLNotify('ItoolDirty',self->GetFullIdentifier(),bDirty)
        
    if (~self._noSavePrompt) then begin

        self->DoOnNotify, self->GetFullIdentifier(), $
            'Filename', self._strFilename + (bDirty ? '*' : '')
    endif

    if (~bDirty) then begin
        ; Save the current undo/redo position, so we can determine
        ; if we ever reach this clean state again.
        self._CommandBuffer->GetProperty, CURRENT_LOCATION=bufferLocation
        self._iBufferLocation = bufferLocation
    endif

end


;---------------------------------------------------------------------------
; IDLitTool::RefreshThumbnail
;
; Purpose:
;  Refresh the tool thumbnail.
;
pro IDLitTool::RefreshThumbnail

  compile_opt idl2, hidden

;    thumb = self->GetThumbnail(/THUMBORDER)
;    id = self->GetFullIdentifier()
;    void = IDLNotify('IDLitThumbnail', self.name + '::' + id, IDL_Base64(thumb))
  
end


;---------------------------------------------------------------------------
; IDLitTool::_TransactCommand
;
; Purpose:
;  Called to add the given command to the command buffer
;  and commit it.
;
; Prameter
;  oCommands    - The command sets to commit
;
pro IDLitTool::_TransactCommand, oCommands

   compile_opt idl2, hidden

  self._CommandBuffer->Add, oCommands
  self._CommandBuffer->Commit

  self->_SetDirty, 1b
  
  self->RefreshThumbnail

end


;---------------------------------------------------------------------------
; IDLitTool::AddCommand
;
; Purpose:
;   This method adds the given commands to the command buffer, without
;   committing them.
;
; Arguments:
;   oCommands: A vector of refrences to the command objects to be removed
;     and destroyed.
;
pro IDLitTool::_AddCommand, oCommands

    compile_opt idl2, hidden

    self._CommandBuffer->Add, oCommands

end


;---------------------------------------------------------------------------
; IDLitTool::_RemoveCommand
;
; Purpose:
;   This method removes the given commands from the command buffer, and
;   destroys them.  Removal of one or more commands makes sense when a
;   particular operation causes previously transacted commands to no longer
;   apply.
;
;   An example is when a crop operation occurs.  In this case, previously
;   transacted commands to position or resize the crop box no longer apply,
;   and should be removed from the buffer.
;
; Arguments:
;   oCommands: A vector of refrences to the command objects to be removed
;     and destroyed.
;
pro IDLitTool::_RemoveCommand, oCommands

    compile_opt idl2, hidden

    self._CommandBuffer->Remove, oCommands

end


;---------------------------------------------------------------------------
; Callback routines access
;---------------------------------------------------------------------------
; IDLitTool::SendMessageToUI
;
; Purpose:
;   Send a synchronous message to the UI.
;
; Parameter:
;   oMessage   - The message object ot send
;
function IDLitTool::SendMessageToUI, oMessage

   compile_opt idl2, hidden

   ; Okay, send the message if we have a connection
   if (~obj_valid(self._oUIConnection)) then return, 0

   ; Send to the UI!
   return, self._oUIConnection->HandleMessage(oMessage)
end


;---------------------------------------------------------------------------
; IDLitTool::ProgressBar
;
; Purpose:
;   Used to cause the system to display and update a progress bar.
;   Pass keywords directly to the same method on system.
;
; Parameters:
;   strMsg   - The message to be displayed in the progress bar.
;
function IDLitTool::ProgressBar, strMsg, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oSystem = self->_GetSystem()
    if (~OBJ_VALID(oSystem)) then $
        return, 0

    return, oSystem->ProgressBar(strMsg, $
        TOOL=self, $   ; indicate we are coming from a tool
        _EXTRA=_extra)

end


;---------------------------------------------------------------------------
pro IDLitTool::DisableProgressBar

    compile_opt hidden, idl2

    oSystem = self->_GetSystem()
    if (OBJ_VALID(oSystem)) then $
        oSystem->DisableProgressBar

end


;---------------------------------------------------------------------------
pro IDLitTool::EnableProgressBar

    compile_opt hidden, idl2

    oSystem = self->_GetSystem()
    if (OBJ_VALID(oSystem)) then $
        oSystem->EnableProgressBar

end


;---------------------------------------------------------------------------
; IDLitTool::_RegisterUIConnection
;
; Purpose:
;   Allows an external entity to register the UI callback
;   object. This object is called when a UI service or notification
;   is fired..
;
; Parameter:
;   oConnection  - The UI connection
;
; Note: This method is "Protected" and only intented to be accessed
; by "friend" classes.
;
pro IDLitTool::_RegisterUIConnection, oConnection


   compile_opt idl2, hidden

   self._oUIConnection = oConnection

end


;---------------------------------------------------------------------------
; IDLitTool::_UnRegisterUIConnection
;
; Purpose:
;   Allows an external entity to unregister the UI callback
;   object.
;
; Parameter:
;   oConnection  - The UI connection to removed
;
; Note: This method is "Protected" and only intented to be accessed
; by "friend" classes.
;
pro IDLitTool::_UnRegisterUIConnection, oConnection


   compile_opt idl2, hidden

   if(self._oUIConnection eq oConnection)then $
     self._oUIConnection = obj_new()

end


;---------------------------------------------------------------------------
; IDLitTool::DoUIService
;
; Purpose:
;  Public tool method used to request the peformance of a UI Service
;
; Return Value
;   1    Success
;   0    Error
;
; Parameters
;   strService   - Name of the service
;
;   oRequester   - Object making the request
;
function IDLitTool::DoUIService, strService, oRequester

  compile_opt idl2, hidden

  if(not obj_valid(self._oUIConnection))then $
     return, 0

   if (N_PARAMS() ne 2) then $
    MESSAGE, 'Incorrect number of arguments.'

   if(strmid(strService, 0,1) eq '/')then begin
       oSystem = self->_GetSystem()
       if(obj_valid(oSystem))then $
         status = oSystem->DoUIService(strService, oRequester)
   endif else $
     status = self._oUIConnection->DoUIService(strService, oRequester)
   return, status

end


;---------------------------------------------------------------------------
; IDLitTool::GetCurrentWindow
;
; Purpose:
;   Retrieves the current window object reference.
;
; Return Value:
;    The current windows object reference or obj_new()
;
function IDLitTool::GetCurrentWindow


    compile_opt idl2, hidden

    return, self._oWindow

end


;---------------------------------------------------------------------------
; IDLitTool::HasVisualizations
;
; Purpose:
;   This function method returns a 1 if the current window for the tool
;   currently contains visualizations (other than the dataspace and axes),
;   or a 0 otherwise.
;
function IDLitTool::HasVisualizations


    compile_opt idl2, hidden

    oWin = self->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0

    oView = oWin->GetCurrentView()
    oLayer = (OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW())
    oWorld = (OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW())
    oDS = (OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW())

    nDS = N_ELEMENTS(oDS)
    for i=0,nDS-1 do begin
        if (OBJ_VALID(oDS[i])) then begin
            oItems = oDS[i]->GetVisualizations(COUNT=nVis)
            if (nVis gt 0) then $
                return, 1
        endif
    endfor

    ; No visualizations found.
    return, 0
end


;---------------------------------------------------------------------------
; IDLitTool::RegisterCustomization
;
; Purpose:
;   This procedure method registers an operation class that
;   represents the graphics customization operation to be associated
;   with this tool.
;
; Arguments:
;   strName: A string representing the human-readable name of
;     the customization operation.
;
;   strClassName: A string representing the classname of the
;     customization operation to be registered.
;
pro IDLitTool::RegisterCustomization, strName, strClassName, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Check if a customization had been previously registered.
    ; If so, remove it.
    id = "Customization"
    oCheck = self->GetByIdentifier("Operations/"+id)
    if (OBJ_VALID(oCheck)) then begin
        oCheck = self->RemoveByIdentifier("Operations/"+id)
        OBJ_DESTROY, oCheck
    endif

    ; Instantiate the new customization operation, and add it.
    oCustomOp = OBJ_NEW(strClassName, NAME=strName, $
        IDENTIFIER=id, $
        TOOL=self, _EXTRA=_extra)
    self->AddByIdentifier, "Operations", oCustomOp
end


;---------------------------------------------------------------------------
; IDLitTool::UnRegisterCustomization
;
; Purpose:
;   This procedure method unregisters an operation class (that
;   was previously registered as the graphics customization operation
;   to be associated with this tool).
;
pro IDLitTool::UnRegisterCustomization

    compile_opt idl2, hidden

    ; Check if a customization had been previously registered.
    ; If so, remove it.
    oCheck = self->GetByIdentifier("Operations/Customization")
    if (OBJ_VALID(oCheck)) then begin
        oCheck = self->RemoveByIdentifier("Operations/Customization")
        OBJ_DESTROY, oCheck
    endif
end

;---------------------------------------------------------------------------
; IDLitTool::CustomizeGraphics
;
; Purpose:
;   This function method customizes the graphics hierarchy associated
;   with this tool.
;
; Return Value:
;   This funtion method returns a reference to a command set object,
;   or a NULL object reference if either the NO_TRANSACT keyword was
;   set or no customization was performed.
;
; Keywords:
;   NO_TRANSACT: Set this keyword to a non-zero value to indicate
;     that the customization operation should not be added to the
;     undo/redo buffer.
;
function IDLitTool::CustomizeGraphics, $
    NO_TRANSACT=noTransact

    compile_opt idl2, hidden

    ; Retrieve the customization operation for this tool, if any.
    oCustomize = self->IDLitContainer::GetByIdentifier( $
        "Operations/Customization")
    if (~OBJ_VALID(oCustomize)) then $
        return, OBJ_NEW()

    if (KEYWORD_SET(noTransact)) then begin
        ; Customization is not to be included in undo/redo buffer.
        oCustomize->Customize
        return, OBJ_NEW()
    endif else begin
        ; Customization is to be recorded for undo/redo.
        oCmdSet = oCustomize->DoAction(self)
        return, oCmdSet
    endelse
end


;---------------------------------------------------------------------------
; IDLitTool::GetSelectedItems
;
; Purpose:
;   Return the currently selected visualizations for the current
;   window.
;
; Keywords:
;   The count of valid items return.
;
function IDLitTool::GetSelectedItems, COUNT=COUNT, ALL=ALL

   compile_opt idl2, hidden

    oWin = self->GetCurrentWindow()

    if (obj_valid(oWin)) then $
        return, oWin->GetSelectedItems(COUNT=count, ALL=ALL)

    COUNT=0
    return, obj_new()

end


;---------------------------------------------------------------------------
; IDLitTool::_SetCurrentWindow
;
; Purpose:
;   Sets the current window object reference.
;
; Parameters:
;   oWindow   - The window that is made current.
;
; Note: This method is "Protected" and only intented to be accessed
; by "friend" classes.
;
pro IDLitTool::_SetCurrentWindow, oWindow


    compile_opt idl2, hidden

    self._oWindow = oWindow

    ; Register the Manipulator manager with the Window. This will
    ; initiate the relay of mouse events to the manipulation system.

    if(obj_valid(self._Manipulators))then $
      oWindow->SetManipulatorManager, self._Manipulators

    if (~self->IsContained(oWindow)) then begin
        self->Add, oWindow
        if OBJ_ISA(oWindow, '_IDLitgrDest') then $
            oWindow->AddSelectionObserver, self
    endif

    ; Cache my objref in the window.
    if OBJ_ISA(oWindow, 'IDLitIMessaging') then $
        oWindow->_SetTool, self


    ; Update tool menu availablity...
    ; Are updates blocked? If so, just increment our updates counter
    if(self._iDisableUpdates gt 0)then begin
        self._iDisableUpdates++
        return
    endif
    self->IDLitTool::UpdateAvailability
end


;---------------------------------------------------------------------------
; IDLitCommand::_DoUndoCommand
;
; Purpose:
;   Called to start/perform an undo of the current command.
;
function IDLitTool::_DoUndoCommand

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch,/cancel
        return, 0
    endif

    self._CommandBuffer->DoUndo
    self->RefreshCurrentWindow

    ; If this undo brings us back to a "clean" state, then reset
    ; the dirty flag.
    if (self._bDirty) then begin
        self._CommandBuffer->GetProperty, CURRENT_LOCATION=bufferLocation
        ; Are we back to where we were when last marked clean?
        if (bufferLocation eq self._iBufferLocation) then $
            self->_SetDirty, 0b
    endif else $
        self->_SetDirty, 1b

    return, 1
end


;---------------------------------------------------------------------------
; IDLitCommand::_DoRedoCommand
;
; Purpose:
;   Called to start/perform an redo of the current command.
;
function IDLitTool::_DoReDoCommand

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch,/cancel
        return, 0
    endif
    self._CommandBuffer->DoRedo

    self->RefreshCurrentWindow

    ; If this redo brings us back to a "clean" state, then reset
    ; the dirty flag.
    if (self._bDirty) then begin
        self._CommandBuffer->GetProperty, CURRENT_LOCATION=bufferLocation
        ; Are we back to where we were when last marked clean?
        if (bufferLocation eq self._iBufferLocation) then $
            self->_SetDirty, 0b
    endif else $
        self->_SetDirty, 1b

    return,1
end


;---------------------------------------------------------------------------
; IDLitTool::_SetScene
;
; Purpose:
;   Internal routine used to update the tool functionality based on
;   the contents of a scene.
;
; Parameters:
;    oScene  - The new scene
;
pro IDLitTool::_SetScene, oScene
   compile_opt hidden, idl2

    if (~obj_valid(oScene)) then $
        return

   ; Get all the visualizations that exist in this scene
   ; and update the tool to needed functionalty (morph
   ; the tool time).
   ntypes =0
   ; views
   oViews = oScene->Get(/all, isa="IDLitgrView",count=nViews)
   for iView=0, nViews-1 do begin
        ; layers
        oLayer = oViews[iView]->_IDLitContainer::Get(/ALL, count=nLayer, /skip)
        for j=0, nLayer-1 do begin
            if (obj_isa(oLayer[j], "IDLitGrAnnotateLayer"))then $
                continue
            ; data spaces
            oDS = oLayer[j]->_IDLitContainer::Get(/all, count=nDS, /skip)
            ; data spaces
            for iDS=0, nDS-1 do begin
                if (~obj_isa(oDS[iDS], "IDLitVisNormDataSpace")) then $
                    continue
                ; visualizations
                oVis = oDS[iDS]->GetVisualizations(count=nVis)
                for l=0, nVis-1 do begin
                    vTypes = ovis[l]->GetTypes()
                    types = (nTypes eq 0 ? vTypes : [vTypes, types])
                    nTypes++
                endfor
            endfor
       endfor
   endfor

   ; if we have types, mod the tool.
   if(nTypes gt 0)then begin
       types = types[uniq(types, sort(types))]
       self->_UpdateToolByType, types
   endif

   ; Set the current scene in the current window.
   oWin=self->GetCurrentwindow()
   oOldScene = oWin->GetScene()
   OBJ_DESTROY, oOldScene
   oWin->_SetScene, oScene

   self->DoOnNotify, oWin->GetFullIdentifier(), 'REMOVEITEMS', ''

end


;---------------------------------------------------------------------------
; IDLitTool::Add
;
; Purpose:
;   Add objects to the Tool in the appropriate container:
;
;     Data objects are added to the Data Manager
;     Visualization objects are added to the current window.
;     Other objects are added to the tool container.
;
; Paramters:
;     oObj   - Items to be added to this tool.
;
; Keywords:
;    All keywords are passed to the target add method.
;
pro IDLitTool::Add, oObj, _EXTRA=_extra

    compile_opt idl2, hidden
    for i=0,N_ELEMENTS(oObj)-1 do begin
        case (1) of
          (OBJ_ISA(oObj[i], '_IDLitVisualization')): begin
            oWin = self->GetCurrentWindow()
            if (OBJ_VALID(oWin)) then begin
              oWin->Add, oObj[i], _EXTRA=_extra
              self->_UpdateToolByType, oObj[i]->GetTypes()
            endif
          end
          (OBJ_ISA(oObj[i], "IDLitgrScene")): self->_SetScene, oObj[i]

          (OBJ_ISA(oObj[i], 'IDLitData')): $
              self->AddByIdentifier, "/Data Manager", oObj[i]
          else: $
              self->IDLitContainer::Add, oObj[i], _EXTRA=_EXTRA
        endcase

    endfor
end


;---------------------------------------------------------------------------
; IDLitTool::DoOnNotify
;
; Purpose:
;   This routine will take the message and then dispatch it to
;   objects that have expressed interest in the message
;
; Parameters:
;    strID      - ID of the tool item that had its state change.
;
;    message    - The type of message sent.
;
;    messparam  - A parameter that is assocaited with the message.
;
pro IDLitTool::DoOnNotify, strID, message, userdata, $
    NO_SYSTEM=noSystem

  compile_opt idl2, hidden

  ; First broadcast to the uI
  
  if (OBJ_VALID(self._oUIConnection)) then $
    self._oUIConnection->HandleOnNotify, strID, message, userdata

    if (~KEYWORD_SET(noSystem)) then begin
        ; Now broadcast to the system object.
        oSys = self->_GetSystem()
        ; Use NO_TOOLS so we don't broadcast back to ourself.
        if (OBJ_VALID(oSys)) then $
            oSys->DoOnNotify, strID, message, userdata, /NO_TOOLS
    endif

  ; Now for the tool
  if(not ptr_valid(self._pDispatchTable))then $
    return;  ; no need to continue

  ; Find all the objects that are interested in the message that was
  ; fired off.
  idx = where((*self._pDispatchTable).idSubject eq strupcase(strID[0]), nItems)
  if(nItems eq 0)then $
    return

  ; There is a possiblity that a OnNotify method will unregister in
  ; the following dispatch loop. This can cause problems, since the
  ; data structure is changing from underneath us. To prevent this,
  ; take a snapshot of the table.

  disTable = *self._pDispatchTable

  ; Just loop on all the items that were found and dispatch the
  ; message.
  for i=0, nItems-1 do begin
      oTarget = self->GetByIdentifier( $
                  disTable[idx[i]].idObserver)

      if(obj_valid(oTarget))then $
        oTarget->OnNotify, strID[0], message, userdata
  endfor

end


;---------------------------------------------------------------------------
; IDLitTool::AddOnNotifyObserver
;
; Purpose:
;   Used to register as being interested in receiving notifications
;   from a specific identifier.
;
; Parameters:
;    strObID       - Identifier of the observer object
;
;    strID         - The identifier of the object that it is
;                    interested in.
;
pro IDLitTool::AddOnNotifyObserver, strObID, strID

   compile_opt idl2, hidden

   tmpStrObID = strupcase(strObID[0])
   tmpStrID = strupcase(strID[0])
   sEntry = {_IDLitDispatchTable, idSubject : tmpstrID,$
             idObserver: tmpstrObID}
   if(ptr_valid(self._pDispatchTable))then begin
       ; Is this entry already in the table?
       idx = where((*self._pDispatchTable).idSubject eq tmpstrID and  $
                   (*self._pDispatchTable).idObserver eq tmpstrObID, $
                    nItems)

       if(nItems gt 0)then $
         return
       *self._pDispatchTable = [*self._pDispatchTable, sEntry]
   endif else $
       self._pDispatchTable = ptr_new(sEntry,/no_copy)

end


;---------------------------------------------------------------------------
; IDLitTool::RemoveOnNotifyObserver
;
; Purpose:
;   Remove an entry from the OnNotify dispatch table.
;
; Parameters:
;    strObID       - Id of the observer
;
;    strID         - The identifier of the object that it is
;                    interested in.
;
pro IDLitTool::RemoveOnNotifyObserver, strObID, strID

   compile_opt idl2, hidden

   if(ptr_valid(self._pDispatchTable))then begin
       ; Is this entry already in the table?
       idx = where((*self._pDispatchTable).idSubject ne strupcase(strID[0]) or  $
                   (*self._pDispatchTable).idObserver ne strupcase(strObID[0]), $
                    nItems)

       if(nItems eq 0)then $    ;empty the table
         ptr_free, self._pDispatchTable $
       else $
         *self._pDispatchTable = (*self._pDispatchTable)[idx]
   endif
end


;---------------------------------------------------------------------------
; IDLitTool::OnManipulatorChange
;
; Purpose:
;   Notification when the current manipulator is changed.
;
; Parameters:
;    oSubject  - The item that changed.
;
;
pro IDLitTool::OnManipulatorChange, oSubject

    compile_opt idl2, hidden

    if(not obj_valid(self._oUIConnection))then $
        return

    ; Get the current manipulator.
    idCurrent = oSubject->GetCurrentManipulator(/IDENTIFIER)
    if(self._idCurrent ne '')then $
      self->DoOnNotify, self._idCurrent, 'SELECT', 0

    self->DoOnNotify, idCurrent, 'SELECT', 1
    self._idCurrent = idCurrent

end


;---------------------------------------------------------------------------
; IDLitTool::CommitActions
;
; Purpose:
;   Called to force a commit of all actions in the pending
;   transaction.
;
PRO IDLitTool::CommitActions

    compile_opt idl2, hidden

   self._CommandBuffer->Commit

   self->_SetDirty, 1b

   ; commiting changes will require any to be displayed on
   ; the screen. Issue a draw to the Window.
   self->RefreshCurrentWindow

end


;---------------------------------------------------------------------------
; IDLitTool::DoSetProperty
;
; Purpose:
;   Interface routine used to set a property using the
;   identification system of the tool. Also this allows
;   property setting to be placed in the command buffer (undo-redo).
;
; Parameters:
;  idTargets   - The targets that will have this property set.
;
;  idProperty  - The PROPERTY ID for the property to be set.
;
;  Value       - The new value of the property.
;
function IDLitTool::DoSetProperty, idTargets, idProperty, Value

   compile_opt idl2, hidden

@idlit_catch
    if (iErr ne 0) then begin
        CATCH, /CANCEL
        self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], SEVERITY=2
        return, 0
    endif

    ; Temporarily disable redraws so that a single redraw can occur when
    ; ::CommitActions is called.
    ; [Note that calling ::DisableUpdates here is inappropriate, because
    ; we do not want a subsequent call to ::EnableUpdates to cause a redraw,
    ; followed by a second redraw when ::CommitActions is called.
    self._bNoRedraw = 1b

   oProperty = self->GetService("SET_PROPERTY")
   oCmd = oProperty->DoAction(self, idTargets, idProperty, Value)

   if (~OBJ_VALID(oCmd)) then begin
       self._bNoRedraw = 0b
       return, 0
   endif

   ;Add the command object to the command buffer
   self._CommandBuffer->Add, oCmd

   ; Properties can affect what is available. Check
   self->IDLitTool::UpdateAvailability

   self._bNoRedraw = 0b

   return, 1
end


;---------------------------------------------------------------------------
; IDLitTool::RefreshCurrentWindow
;
; Purpose:
;  Generic entry point used to update the current visualization of
;  the tool.
;
;  The window will be updated immediatly unless updates are currently
;  disabled.
;
pro IDLitTool::RefreshCurrentWindow
    compile_opt idl2, hidden

    if(self._iDisableUpdates gt 0)then begin
        self._iDisableUpdates++
        return ; updates disabled, increment and return.
    endif
    ; Simple
    oWin = self->GetCurrentWindow()

    if (not OBJ_VALID(oWin)) then $
        return

    if (~self._bNoRedraw) then $
        oWin->Draw

end


;---------------------------------------------------------------------------
;  IDLitTool::DisableUpdates
;
; Purpose:
;   If called, all window refreshes  and menu updates are disabled
;   until EnableUpdates is called.
;
; Parameters:
;   None.
;
PRO IDLitTool::DisableUpdates, $
    PREVIOUSLY_DISABLED=previouslyDisabled

    compile_opt idl2, hidden

    if (ARG_PRESENT(previouslyDisabled)) then $
        previouslyDisabled = (self._iDisableUpdates gt 0)

    if (self._iDisableUpdates eq 0) then begin
        self._iDisableUpdates=1
        self._nSelChange=0
    endif
end


;--------------------------------------------------------------------------
; IDLitTool::EnableUpdates
;
; Purpose:
;   Used to re-enable updates in the tool. If any pending updates
;   exist, a redraw and menu update is issued.
;
; Parameters:
;   None.
;
PRO IDLitTool::EnableUpdates

    compile_opt idl2, hidden

    DoUpdate = (self._iDisableUpdates gt 1)

    self._iDisableUpdates=0
    if(DoUpdate)then begin
        ; If we had any selection changes, just trigger a selection
        ; change update. This will call _PerformDisplayUpdates
        if(self._nSelChange gt 0)then $
          self->OnSelectionChange, self->GetCurrentWindow() $
        else $
          self->IDLitTool::_PerformDisplayUpdates
        self._nSelChange=0
    endif
end


;---------------------------------------------------------------------------
; IDLitTool::_PerformDisplayUpdates
;
; Purpose:
;   This internal routine is called to update the following items related to
;   the tool:
;         - The window
;         - The selection visuals
;         - Tool option availability.
;
;   This will verify updates are not disabled.
;
pro IDLitTool::_PerformDisplayUpdates

    compile_opt idl2, hidden

    ; Are updates blocked? If so, just increment our updates counter
    if(self._iDisableUpdates gt 0)then begin
        self._iDisableUpdates++
        return
    endif
    ; Grab the window
    oWin = self->GetCurrentWindow()
    if (not OBJ_VALID(oWin)) then $
      return
    ; Do the window first (it's more visible)
    ; Verify manipulators are correct.
    self._Manipulators->UpdateSelectionVisuals, oWin

    ; Perform the redraw last or visuals will not update.
    self->RefreshCurrentWindow

end


;---------------------------------------------------------------------------
; IDLitTool::OnSelectionChange
;
; Purpose:
;  Called when the selection state of the items in the window is
;  changed.
;
pro IDLitTool::OnSelectionChange, oWin
    compile_opt idl2, hidden

    if (~OBJ_VALID(oWin)) then $
        return

    if(self._iDisableUpdates gt 0)then begin
        self._iDisableUpdates++
        self._nSelChange++ ; will need selection change updates
        return
    endif

    ; Just call the update routine for the tool
    self->IDLitTool::_PerformDisplayUpdates
    self->IDLitTool::UpdateAvailability

    ; propagate our Selection change, sending the ID of the current
    ; primary item
    oSel = oWin->GetSelectedItems(count=count,/all)
    if(count eq 0)then begin
        oSel = oWin->GetCurrentView()
        if (~OBJ_VALID(oSel)) then return
        count=1
    endif
    ids = strarr(count)
    for i=0, count-1 do begin
      if (Obj_Valid(oSel[i])) then ids[i] = oSel[i]->GetFullIdentifier()
    endfor
    self->DoOnNotify, 'Visualization', 'SELECTIONCHANGED', ids

    ; Now update our clipboard status
    self->_UpdateClipboardStatus
end


;---------------------------------------------------------------------------
; IDLitTool::_SetError
;
; Purpose:
;   Used to set the error state of the system. This just sets the
;   state or information. Nothing else.
;
; Keywords
;   CODE         - An error code of type long
;
;   SEVERITY     - The severity of the error.
;
;   DESCRIPTION  - A long string message for the error condition
;
pro IDLitTool::_SetError, _EXTRA=_EXTRA
    compile_opt idl2, hidden

    self._oLastError->SetProperty, _EXTRA=_EXTRA

end


;---------------------------------------------------------------------------
; IDLitTool::GetLastErrorInfo
;
; Purpose:
;   Used to get error information for the last error set in the
;   system.
;
; Keywords:
;   CODE         - An error code of type long
;
;   SEVERITY     - The severity of the error.
;
;   DESCRIPTION  - A long string message for the error condition
;
pro IDLitTool::GetLastErrorInfo, _REF_EXTRA=_EXTRA
    compile_opt idl2, hidden
    self._oLastError->GetProperty, _EXTRA=_EXTRA
end


;---------------------------------------------------------------------------
; IDLitTool::SetProperty
;
; Purpose:
;  Method to set properties on the tool object.
;
; Keywords:
;   _TOOL_NAME - Internal property used to register the the name of
;                the name of the system registered tool
;                 that was used to create this tool
;
;   UPDATE_BYTYPE - Set the current setting of the update by type
;                   mode of the tool. If enabled, functionality shall
;                   be added to the tool when new visualization types
;                   are added to it.
;
pro IDLitTool::SetProperty, $
             TOOL_FILENAME=toolFilename, $
             NO_SAVEPROMPT=noSavePrompt, $
             _TOOL_NAME=_TOOL_NAME, $
             UPDATE_BYTYPE=UPDATE_BYTYPE, $
             CHANGE_DIRECTORY=changeDirectory, $
             WORKING_DIRECTORY=workingDirectory, $
             MOUSE_MOTION_HANDLER=mMotionHandler, $
             MOUSE_BUTTON_HANDLER=mButtonHandler, $
             _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(toolFilename)) then begin
        self._strFilename = toolFilename
        ; Set filename on file/save operation, otherwise the operation might
        ; retain the name of the previous file
        oDesc = self->GetByIdentifier('Operations/File/Save')
        if (OBJ_VALID(oDesc)) then begin
          oOp = oDesc->GetObjectInstance()
          if (OBJ_VALID(oOp)) then $
            oOp->SetProperty, FILENAME=toolFilename
        endif 
        ; This will also do notification.
        self._bDirty = 1b   ; Just in case we weren't dirty.
        self->_SetDirty, 0b
    endif

    if (N_ELEMENTS(noSavePrompt) gt 0) then $
      self._noSavePrompt = KEYWORD_SET(noSavePrompt)

    if(n_elements(_TOOL_NAME) gt 0)then $
      self._strToolName =_TOOL_NAME

    if(n_elements(UPDATE_BYTYPE) gt 0)then $
      self._bUpdateByType = keyword_set(UPDATE_BYTYPE)

    if (N_ELEMENTS(changeDirectory) gt 0) then $
      self._bChangeDirectory = KEYWORD_SET(changeDirectory)

    if (N_ELEMENTS(workingDirectory) gt 0) then begin
        dir = workingDirectory
        isWin = !VERSION.os_family eq 'Windows'
        ; In case the directory name was saved on a different platform,
        ; convert / to \ or vice versa.
        self._strWorkingDirectory = STRJOIN(STRSPLIT(dir, $
            isWin ? '/' : '\', /EXTRACT, /PRESERVE_NULL), isWin ? '\' : '/')
    endif

    if (N_ELEMENTS(mMotionHandler) eq 1) then $
      self._Manipulators->SetProperty, MOUSE_MOTION_HANDLER=mMotionHandler

    if (N_ELEMENTS(mButtonHandler) eq 1) then $
      self._Manipulators->SetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler

    if(n_elements(_extra) gt 0)then $
      self->IDLitContainer::setProperty, _extra=_extra
end


;---------------------------------------------------------------------------
; IDLitTool::GetProperty
;
; Purpose:
;   Method to get the values of tool properties.
;
; KEYWORDS
;   VERSION   - Returns the version of the tool framework
;
;   _TOOL_NAME - Internal property used to register the the name of
;                the name of the system registered tool
;                 that was used to create this tool
;
;   TYPES    - The tool types this tool supports
;
;   UPDATE_BYTYPE - Return the current setting of the update by type
;                   mode of the tool. If enabled, functionality shall
;                   be added to the tool when new visualization types
;                   are added to it.
;
pro IDLitTool::GetProperty, VERSION=VERSION, $
             TOOL_FILENAME=toolFilename, $
             _TOOL_NAME=_TOOL_NAME, $
             TYPES=TYPES, $
             UPDATE_BYTYPE=UPDATE_BYTYPE, $
             CHANGE_DIRECTORY=changeDirectory, $
             WORKING_DIRECTORY=workingDirectory, $
             MOUSE_MOTION_HANDLER=mMotionHandler, $
             MOUSE_BUTTON_HANDLER=mButtonHandler, $
             _REF_EXTRA=_extra

@idlitconfig.pro

    compile_opt idl2, hidden

    if(arg_present(version))then $
      version = ITOOLS_STRING_VERSION

    if (ARG_PRESENT(toolFilename)) then $
        toolFilename = self._strFilename

    if(arg_present(_TOOL_NAME))then $
      _TOOL_NAME = self._strToolName

    if (ARG_PRESENT(TYPES)) then $
        types = *self._types

    if(ARG_PRESENT(UPDATE_BYTYPE))then $
      UPDATE_BYTYPE = self._bUpdatebyType

    if (ARG_PRESENT(changeDirectory)) then $
        changeDirectory = self._bChangeDirectory

    if (ARG_PRESENT(workingDirectory)) then $
        workingDirectory = self._strWorkingDirectory

    if (ARG_PRESENT(mMotionHandler)) then $
        self._Manipulators->GetProperty, MOUSE_MOTION_HANDLER=mMotionHandler

    if (ARG_PRESENT(mButtonHandler)) then $
        self._Manipulators->GetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler

    if(n_elements(_extra) gt 0)then $
      self->IDLitContainer::GetProperty, _extra=_extra
end


;---------------------------------------------------------------------------
; IDLitTool::_AddFunctionaityByType
;
; Purpose:
;   CAlled to add functionatliy to a tool based on the provided type.
;
; Parameters:
;   strType   - Type type that identifies the functionaity being
;               added. This can be a scalar or array
;
pro IDLitTool::_UpdateToolByType, strType
   compile_opt hidden, idl2

   ; If type updates are disabled, return.
   if(~self._bUpdateByType)then return

   newTypes = strupcase(strtype)
   nType =0
   ; Has this type been used before?
   for i=0, n_elements(newTypes)-1 do begin
       if(~keyword_set(newTypes[i]))then continue;skip empty types
       dex = where(*self._types eq newTypes[i], nMatch)
       if(nMatch eq 0)then begin
           newTypes[nType]=newTypes[i]
           nType++
       endif
   endfor
   if(nType eq 0)then return ; no match

   ; Save the current manipulator
   idCurrManip = self._Manipulators->GetCurrentManipulator()
   ; Okay, call into the system to update this tool based on the new
   ; type
   oSystem = self->_GetSystem()

   newTypes = newTypes[0:nType-1]
   oSystem->UpdateToolByType, self, newTypes

   *self._types = (keyword_set(*self._types) ? $
                   [*self._types, newTypes]: newTypes)

   ; Reset the current manipulator.
   if(keyword_set(idCurrManip))then $
     self._Manipulators->SetCurrentManipulator, idCurr
end


;---------------------------------------------------------------------------
; Internal routines
;---------------------------------------------------------------------------
PRO idlitTool::_UpdateClipboardStatus
   compile_opt hidden, idl2

   ; Anything valid in the clipboard
   oClip = self->GetByIdentifier("/CLIPBOARD")
   if (~OBJ_VALID(oClip)) then $
    return
   ; Get the items on the clipboard.
   oItems = oClip->Get(/all, count=nItems)

   ; Get the by value status. This is used to manage paste special
   isAllbyValue=0
   ndTypes = 0
   for i=0, nItems-1 do begin
       by_value = oItems[i]->ContainsByValue(IS_ALL=IS_ALL)
       if(by_value && keyword_set(IS_ALL))then $
         isAllByValue++
       dTypes = (ndTypes gt 0) ? $
           [dTypes, oItems[i]->GetParentTypes()] : $
           [oItems[i]->GetParentTypes()]
       nDtypes = N_ELEMENTS(dTypes)
   endfor

   if (nDTypes gt 1) then begin
       dTypes = [dTypes[uniq(dtypes, sort(dTypes))]]
       nDtypes = N_ELEMENTS(dTypes)
   endif

   oToolCon = self->GetbyIdentifier("/Tools")
   oTools = oToolCon->Get(/all)
   id = "/REGISTRY/OPERATIONS/PASTE"
   if (nDtypes eq 0) || (nDtypes eq 1 && dTypes[0] eq '') then begin
       ; Loop through the tools and broadcast
       self->DoOnNotify, id, "SENSITIVE", nItems gt 0

       self->DoOnNotify,id+"SPECIAL" , "SENSITIVE", $
            nItems gt 0 && isAllByValue lt nItems
   endif else begin
       ; Make sure that the currently selected, primary item is
       ; of the correct type for the given tool
       oSel = self->GetSelectedItems(count=nSel)
       if(nSel gt 0)then begin
           selTypes = oSel[0]->GetTypes()
           for j=0, nDTypes-1 do begin
               dex = where(dTypes[j] eq selTypes, nMatch)
               if(nMatch gt 0)then break
           endfor
       endif else nMatch =0
       self->DoOnNotify, id, "SENSITIVE", nMatch gt 0
       self->DoOnNotify, id + "SPECIAL", "SENSITIVE", 0
   endelse
end


;---------------------------------------------------------------------------
; IDLitTool::_SetSystem
;
; Purpose:
;   Called during the construction process to associate the system
;   object with this tool.
;
; Parameters:
;    oSystem      - The system enviroment object.
;
pro IDLitTool::_SetSystem, oSystem

   compile_opt hidden, idl2

   if(not obj_valid(oSystem))then return

   self._oSystem = oSystem

end


;---------------------------------------------------------------------------
; IDLitTool::_GetSystem()
;
; Purpose:
;   Returns the system object to the caller of this method. Primary
;   used internally and to access system resources.
;
; Parameters:
;  None.
;
; Return Value:
;    The system object or null if no system object exists
;
function IDLitTool::_GetSystem

   compile_opt hidden, idl2

   return, self._oSystem
end


;---------------------------------------------------------------------------
; IDLitTool::_GetCommandBuffer()
;
; Purpose:
;   Internal routine to return an object reference to the internal
;   command buffer object. This is intended for test use only.
;
; Parameters:
;  None.
;
; Return Value:
;   The Command Buffer object or NULL if one doesn't exist.
;
function IDLitTool::_GetCommandBuffer

   compile_opt hidden, idl2

   return, self._CommandBuffer
end


;-----------------------------------------------------------------------
; Override our superclass method.
;
; Arguments:
;   Pattern: An optional argument giving the string pattern to match.
;       All identifiers within the container that match this pattern
;       (case insensitive) will be returned. If Pattern is not supplied
;       then all identifiers within the container are returned.
;
; Keywords:
;   ANNOTATIONS: Set this keyword to only return identifiers
;       for items within the annotation layer of all views
;       within the graphics window. Setting this keyword
;       is equivalent to specifying the pattern as:
;           '*/ANNOTATION LAYER/*' + Pattern
;
;   COUNT: Set this keyword to a named variable in which to return
;       the number of identifiers in Result.
;
;   FILE_READERS: Set this keyword to only return identifiers
;       within the File Readers container that match the pattern.
;
;   FILE_WRITERS: Set this keyword to only return identifiers
;       within the File Writers container that match the pattern.
;
;   LEAF_NODES: If this keyword is set then only leaf nodes will
;       be returned. The default is to return all identifiers that
;       match, including containers.
;
;   MANIPULATORS: Set this keyword to only return identifiers
;       within the Manipulators container that match the pattern.
;
;   OPERATIONS: Set this keyword to only return identifiers
;       within the Operations container that match the pattern.
;
;   VISUALIZATIONS: Set this keyword to only return identifiers
;       for items within the visualization layer of all views
;       within the graphics window. Setting this keyword
;       is equivalent to specifying the pattern as:
;           '*/VISUALIZATION LAYER/*' + Pattern
;
function IDLitTool::FindIdentifiers, Pattern, $
    ANNOTATIONS=annotations, $
    DATA_MANAGER=data_manager, $
    FILE_READERS=file_readers, $
    FILE_WRITERS=file_writers, $
    MANIPULATORS=manipulators, $
    OPERATIONS=operations, $
    VISUALIZATIONS=visualizations, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (KEYWORD_SET(visualizations)) then begin
        oWin = self->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, ''
        return, oWin->FindIdentifiers(Pattern, $
            /VISUALIZATIONS, $
            _EXTRA=_extra)
    endif

    if (KEYWORD_SET(annotations)) then begin
        oWin = self->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, ''
        return, oWin->FindIdentifiers(Pattern, $
            /ANNOTATIONS, $
            _EXTRA=_extra)
    endif

    ; Handle specific keywords (folders).

    if (KEYWORD_SET(manipulators)) then $
        folder = 'Manipulators'

    if (KEYWORD_SET(operations)) then $
        folder = 'Operations'

    if (KEYWORD_SET(data_manager)) then $
        folder = '/DATA MANAGER'

    if (KEYWORD_SET(file_readers)) then $
        folder = 'FILE READERS'

    if (KEYWORD_SET(file_writers)) then $
        folder = 'FILE WRITERS'

    ; See if we have a specific folder from above.
    if (KEYWORD_SET(folder)) then begin
        oContainer = self->GetByIdentifier(folder)
        if (~OBJ_VALID(oContainer)) then $
            return, ''
        return, oContainer->FindIdentifiers(Pattern, _EXTRA=_extra)
    endif

    ; Default is to call our superclass.
    return, self->_IDLitContainer::FindIdentifiers(Pattern, _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; IDLitTool__Define
;
; Purpose:
;   This method defines the IDLitTool class.
;
pro IDLitTool__Define

  compile_opt idl2, hidden

  void = { IDLitTool,                     $
           inherits IDLitContainer,       $ ;
           inherits _IDLitObjDescRegistry,$ ;
           inherits IDLitIMessaging,      $ ; Messaging interface
           _strToolName    : '',          $ ; The name of this tool reg. with the system
           _strFilename    : '',          $ ; Filename for this tool instance
           _idCurrent      : '',          $ ; Identifier of the current manpulator
           _strVersion     : '',          $ ; Hold version info
           _strWorkingDirectory: '',      $ ; Current working directory
           _oSystem        : obj_new(),   $ ; The system environement object.
           _Manipulators   : obj_new(),   $ ; Manipuator Manager
           _oUIServiceConn : obj_new(),   $ ; UI Service connection:REMOVE
           _oUIConnection  : obj_new(),   $ ; callback inteface to UI.
           _oWindow        : obj_new(),   $ ; Active Window object
           _CommandBuffer  : obj_new(),   $ ; Command Buffer/list
           _oLastError     : obj_new(),   $ ; The last error message
           _pDispatchTable : ptr_new(),   $ ; Lookup table for dispatches
           _types          : ptr_new(),   $ ; The types this tool supports
           _StatusBar      : obj_new(),   $ ; Container for status bar
                                          $ ;   segments
           _iBufferLocation: 0,           $ ; Undo/redo current location
           _iDisableUpdates: 0,           $ ; Disable window updates
           _nSelChange     : 0,           $ ; Count selection change notifications
           _currStatusSegmentId: 0,       $ ; Current status bar segment id
           _bNoRedraw      : 0b,          $ ; Flag to temporarilty disable
                                            ;   redraws.
           _bDirty         : 0b,          $ ; Tool state has changed
           _noSavePrompt   : 0b,          $ ; Don't keep track of dirty bit
           _bUpdateByType  : 0b,          $ ; Update tool by type
           _bChangeDirectory: 0b          $ ; Change directory on file open
    }
end
