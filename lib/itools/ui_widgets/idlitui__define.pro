; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitui__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitUI
;
; PURPOSE:
;   This file implements the generic IDL Tool User Interface object
;   manages the connection between the underlying tool object and
;   the elements that comprise the user interface.
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
;   See IDLitUI::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitUI::Init
;;
;; Purpose:
;; The constructor of the IDLitUI object.
;;
;; Parameters:
;; oTool    - The IDLitTool object this UI is assciated with
;;
function IDLitUI::Init, oTool,  _REF_EXTRA=_extra
   ;; Pragmas
   compile_opt idl2, hidden

   if(~obj_isa(oTool, "IDLitTool") && ~obj_isa(oTool, "IDLitSystem"))then begin
       Message, /continue, IDLitLangCatQuery('UI:UIdef:BadTool')
     return, 0
   endif

   ;; Call our super class
   if( self->IDLitContainer::Init(NAME="IDL Tools User Interface", $
                                  IDENTIFIER="") eq 0)then $
      return, 0

   ;; Allocate any containers we need.
;;;   self._oContainer = obj_new("IDLitContainer") ;main container for hierarchy.

   self._MenuBars = obj_new("IDLitContainer", NAME="Menubars")
   self->Add, self._MenuBars

   self._Toolbars  = obj_new("IDLitContainer", NAME="Toolbars")
   self->Add, self._Toolbars

   self._Statusbar = obj_new("IDLitContainer", NAME="Statusbar")
   self->Add, self._Statusbar

   self._UIServices = obj_new("IDLitContainer", NAME="UIServices")
   self->Add, self._UIServices

   self->Add, obj_new("IDLitContainer", NAME="Widgets")

   self._oTool = oTool

   self->SetProperty, _EXTRA=_extra

    ;*** Register the Error ui service.

   identifier = self->RegisterUIService('IDLitErrorObjDialog',  $
                                        'IDLitUIDisplayErrorObj')

   identifier = self->RegisterUIService('IDLitPromptUserYesNo',  $
                                        'IDLitUIPromptUser')
   identifier = self->RegisterUIService('IDLitPromptUserText',  $
                                        'IDLitUIPromptUserText')

   identifier = self->RegisterUIService('IDLitProgressBar',  $
                                        'IDLitUIProgressBar')

   ;; Register as the UI for the tool

   oTool->_RegisterUIConnection, self

   ;; Register this object as an observer of the tool object.
   self->AddOnNotifyObserver, self->GetFullIdentifier(), $
                              oTool->getFullIdentifier()
  return, 1

end
;;---------------------------------------------------------------------------
;; IDLitUI::Cleanup
;;
;; Purpose:
;;   Destructor of the UI Class
;;
pro IDLitUI::Cleanup
   ;; Pragmas
   compile_opt idl2, hidden

   if(obj_valid(self._oTool))then $
     self._oTool->_UnRegisterUIConnection, self

   ptr_free, self._pDispatchSubject
   ptr_free, self._pDispatchObserver

   ;; Cleanup any widgets registered with the system
   self->_CleanupWidgets

   ;; Call our super class.
   self->IDLitContainer::Cleanup

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro IDLitUI::GetProperty, $
    GROUP_LEADER=groupLeader, $
    WIDGET_FOCUS=widgetFocus, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    if ARG_PRESENT(groupLeader) then $
        groupLeader = self._wBase

    if ARG_PRESENT(widgetFocus) then begin
        if WIDGET_INFO(self._wBase, /VALID) then $
            widgetFocus = self._wBase
        ; Here is some "special" code to determine which widget has focus.
        ; Look thru all managed widgets (these are the top-level bases).
        ; Find the most recent (highest widget id) one that is modal,
        ; and use that for the focus widget.
        ; If there isn't a modal widget, then just use the group leader.
        ; Note that there might not be an active top-level base, so
        ; widgetFocus may remain undefined (wManaged = 0).
        wManaged = WIDGET_INFO(/MANAGED)
        for i=N_ELEMENTS(wManaged)-1,0,-1 do begin
            if (WIDGET_INFO(wManaged[i], /VALID) && $
                WIDGET_INFO(wManaged[i], /MODAL)) then begin

                widgetFocus = wManaged[i]
                break  ; we're done
            endif
        endfor
    endif

    ; get superclass properties
    if (N_ELEMENTS(super) gt 0) then $
        self->IDLitComponent::GetProperty, _EXTRA=super

end


;----------------------------------------------------------------------------
pro IDLitUI::SetProperty, $
    GROUP_LEADER=groupLeader, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    if N_ELEMENTS(groupLeader) ne 0 then $
        self._wBase = groupLeader

    ; Set superclass properties
    if (N_ELEMENTS(super) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=super

end
;;---------------------------------------------------------------------------
;; IDLitUI::OnNotify
;;
;; Purpose:
;;   A notification callback that the UI object uses to monitor
;;   messages from the underlying tool object.
;;
;; Parameters:
;;   strID    - The identifier of the underlying tool
;;
;;   message  - The message that is being sent.

pro IDLitUI::OnNotify, strID, message, userdata
   compile_opt hidden, idl2

   case message of
     'SHUTDOWN' : begin
         ;; Retrieve all of the floating dialogs for this tool.
         oWidgets = self->GetByIdentifier("Widgets")
         if(obj_valid(oWidgets))then begin
             oWid=oWidgets->Get(/all, count=nWid)
             for i=0, nWid-1 do begin
                 oWid[i]->GetProperty, WIDGET_ID=wID, floating=floating, name=name
                 if(keyword_set(floating))then begin
                     if(widget_info(wID,/valid_id))then begin
                       widget_control, wID, map=0
                       widget_control, wID, /destroy
                     endif
                 endif
             endfor
         endif
         if(widget_info(self._wBase,/valid_id))then begin
           widget_control, self._wBase, map=0
           widget_control, self._wBase, /destroy
         endif
         obj_destroy, self
     end
     'FOCUS_CHANGE' : begin
         ;; Retrieve all of the floating dialogs for this tool.
         oWidgets = self->GetByIdentifier("Widgets")
         if(obj_valid(oWidgets))then begin
             oWid=oWidgets->Get(/all, count=nWid)
             for i=0, nWid-1 do begin
                 oWid[i]->GetProperty, WIDGET_ID=wID, floating=floating
                 ;; should we map or unmap the floating widgets?
                 if(keyword_set(floating) && $
                    widget_info(wID,/valid))then begin
                     ;; If this is loosing focus, save the current
                     ;; map state. This is done in bit 3 (value of 4
                     if(userdata eq 0)then begin
                         isMap = widget_info(wID, /map)
                         oWid[i]->SetProperty, floating=(isMap ? 5 : 1)
                         doMap=0
                     endif else $ ;; if this was mapped earlier, remap
                         doMap = ((floating and 4) ne 0 ? 1 : 0)
                     widget_control, wID, map=doMap
                 endif
             endfor
         endif
     end
     'SHOW' : begin
         widget_control, self._wBase, /SHOW, ICONIFY=0
     end
     else :
   endcase

end

;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; Callback section
;;
;; The following methods implement the interface that the tool
;; uses to communicate with the user interface.
;;---------------------------------------------------------------------------
;; IDLitUI::HandleOnNotify
;;
;; Purpose:
;;   Called by the underlying tool to send a notify message to the
;;   tool. This type of message is triggered when something in the
;;   underlying tool has changed.
;;
;;   This routine will take the message and then dispatch it to
;;   objects that have expressed interest in the message
;;
;; Parameters:
;;    strID      - ID of the tool item that had its state change.
;;
;;    message    - The type of message sent.
;;
;;    messparam  - A parameter that is assocaited with the message.

pro IDLitUI::HandleOnNotify, strID, message, userdata
  ;; Pragmas
  compile_opt idl2, hidden

  if (~ptr_valid(self._pDispatchSubject)) then $
    return;  ;; no need to continue

  ;; Find all the objects that are interested in the message that was
  ;; fired off.
  idx = where(*self._pDispatchSubject eq STRUPCASE(strID[0]), nItems)
  if(nItems eq 0)then $
    return

  ;; There is a possiblity that a OnNotify method will unregister in
  ;; the following dispatch loop. This can cause problems, since the
  ;; data structure is changing from underneath us. To prevent this,
  ;; take a snapshot of the table.
  observerTable = (*self._pDispatchObserver)[idx]

  ;; Just loop on all the items that were found and dispatch the
  ;; message.
  for i=0, nItems-1 do begin
    IF obj_valid(self) THEN BEGIN
      oTarget = self->GetByIdentifier(observerTable[i])
      if(obj_valid(oTarget))then $
        oTarget->OnNotify, strID[0], message, userdata
    ENDIF
  endfor

end
;;---------------------------------------------------------------------------
;; IDLitUI::DoUIService
;;
;; Purpose:
;;  Used to dispatch to a UI service
;;
;; Parameters:
;;   strService    - The service being requested. this not a path, but
;;                   a service name that is used to build a path.
;;
;;   oRequester    - The object/interface that is used by the service
;;                   to set values ...etc. This is service dependent.
;;
;; Return Value
;;    0   - Failure
;;
;;    1   - Success

function IDLitUI::DoUIService, strService, oRequester
  ;; Pragmas
  compile_opt idl2, hidden

  oTarget = self._UIServices->GetByIdentifier(strService)
  if(not obj_valid(oTarget))then $
     return, 0

  return, oTarget->DoUIService(self, oRequester)

end
;;---------------------------------------------------------------------------
;; IDLitUI::HandleMessage
;;
;; Purpose:
;;   Access point for sync messages.
;;
;; Parameters
;;   oMessage - The message
;;
;; Return Values:
;;    0  - Error
;;    1  - A Okay

function IDLitUI::HandleMessage, oMessage
   ;; Pragmas
   compile_opt idl2, hidden

   ON_ERROR, 2

   if(~obj_valid(oMessage))then $
     return, 0

   iType = oMessage->GetType()
   case iType of
       1:  strService =  "IDLitErrorObjDialog"
       2:  strService =  "IDLitPromptUserYesNo"
       3:  strService =  "IDLitPromptUserText"
       4 : strService =  "IDLitProgressBar"
       else: return, 0
   endcase

   return, self->DoUIService(strService, oMessage)

end


;---------------------------------------------------------------------------
; Internal method to register an item.
;
function IDLitUI::_RegisterItem, strName, strFolder, $
    DESCRIPTION=DESCRIPTION, $
    REPLACE=replace, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (~n_elements(DESCRIPTION)) then $
        DESCRIPTION=strNAME

    ; Do some name validation.
    strTmp = IDLitBasename(strName, remainder=strID, /reverse)

;    if(strLen(strID) gt 0)then $
;        Message, "Identifier nesting of toolbars  is not allowed"

    oAdapt = obj_new('IDLitUIAdaptor', $
        NAME=strName, $
        DESCRIPTION=DESCRIPTION, $
        _STRICT_EXTRA=_extra)

    if keyword_set(replace) then begin
        ; Quietly replace previously registered item.
        oAdapt->GetProperty, IDENTIFIER=idComponent
        fullID = strFolder
        if (STRMID(strFolder, 0, 1, /REVERSE) ne '/') then $
            fullID += '/'
        fullID += idComponent
        oOldComp = self->GetByIdentifier(fullID)
        if (OBJ_VALID(oOldComp)) then begin
            oOldComp = self->RemoveByIdentifier(fullID)
            OBJ_DESTROY, oOldComp
        endif
    endif

    ;Add this to the system
    self->AddByIdentifier,strFolder, oAdapt

    return, oAdapt->GetFullIdentifier()

end


;---------------------------------------------------------------------------
; IDLitUI::_UnRegisterItem
;
; Purpose:
;   Internal method to remove an item from the system.
;
; Parameters:
;   strID     - The ID of the toolbar to remove. This is not a
;               fully qualified ID. It is realitive to the toolbar
;               container.
;
pro IDLitUI::_UnRegisterItem, strID

    compile_opt idl2, hidden

    oItem = self->RemoveByIdentifier(strID)

    ; Just eat any errors at this point
    obj_destroy, oItem

    ; Ok, cleanup any callbacks that were registered.
    if (~ptr_valid(self._pDispatchSubject)) then $
        return

    ; Within the dispatch table, keep only those whose subject does
    ; not match the item being unregistered.
    idx = where(*self._pDispatchSubject ne strID, nItems)

    if (~nItems) then begin     ;empty the table
        ptr_free, self._pDispatchSubject
        ptr_free, self._pDispatchObserver
    endif else begin
        *self._pDispatchSubject = (*self._pDispatchSubject)[idx]
        *self._pDispatchObserver = (*self._pDispatchObserver)[idx]
    endelse

end


;;---------------------------------------------------------------------------
;; Registration Section
;;
;; This section contains methods that are used to register items
;; that define the functionality of the tool.
;;---------------------------------------------------------------------------
;; IDLitUI::RegisterToolBar
;;
;; Purpose:
;;   This is used to register a toolbar user interface element with
;;   the user interface object. The caller supplices the widget ID and
;;   the routien to call when a message is sent for this particular
;;   toolbar.
;;
;;   This method will create the adaptor object that is used to
;;   translate between the framework and the procedureal space of the
;;   widget system.
;;
;; Return Value
;;  The tool Identifier for the added item. This can be used later
;;  when the widget calls into the tool.
;;
;; Parameters:
;;   wID           - Target Widget ID
;;
;;   strName       - name of the toolbar.
;;
;;   strCallback   - The callback method for the OnNotify
;;                   message. This is a function that is called.
;;
;; Keywords:
;;   DESCRIPTION   - Description of the toolbar.

function IDLitUI::RegisterToolbar, wID, strName, strCallback, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->_RegisterItem(strName, "Toolbars", $
        ONNOTIFY_CALLBACK=strCallback, $
        WIDGET_ID=wID, $
        _EXTRA=_extra)

end


;;---------------------------------------------------------------------------
;; IDLitUI::UnRegisterToolbar
;;
;; Purpose:
;;   Remove a toolbar from the system.
;;
;; Parameters:
;   strID: The ID of the toolbar to remove. This may be either a
;       full identifier or relative to the container.
;
pro IDLitUI::UnRegisterToolbar, strIDin

    compile_opt idl2, hidden

    strID = STRUPCASE(strIDin)

    ; Not a full identifier?
    if (STRMID(strID, 0, 1) ne '/') then $
        strID = "TOOLBARS/" + strID

    self->_UnRegisterItem, strID

end


;;---------------------------------------------------------------------------
;; IDLitUI::RegisterMenubar
;;
;; Purpose:
;;   This is used to register a menubar user interface element with
;;   the user interface object. The caller supplices the widget ID and
;;   the routine to call when a message is sent for this particular
;;   toolbar.
;;
;;   This method will create the adaptor object that is used to
;;   translate between the framework and the procedural space of the
;;   widget system.
;;
;; Return Value
;;  The tool Identifier for the added item. This can be used later
;;  when the widget calls into the tool.

;; Parameters:
;;   wID           - Target Widget ID
;;
;;   strName       - name of the menubar.
;;
;;   strCallback   - The callback method for the OnNotify
;;                   message. This is a function that is called.
;;
;; Keywords:
;;   DESCRIPTION   - Description of the toolbar.

function IDLitUI::RegisterMenubar, wID, strName, strCallback, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->_RegisterItem(strName, "Menubars", $
        ONNOTIFY_CALLBACK=strCallback, $
        WIDGET_ID=wID, $
        _EXTRA=_extra)

end


;;---------------------------------------------------------------------------
;; IDLitUI::UnRegisterMenubar
;;
;; Purpose:
;;   Remove a menubar from the system.
;;
;; Parameters:
;   strID: The ID of the menu to remove. This may be either a
;       full identifier or relative to the container.
;
pro IDLitUI::UnRegisterMenubar, strIDin

    compile_opt idl2, hidden

    strID = STRUPCASE(strIDin)

    ; Not a full identifier?
    if (STRMID(strID, 0, 1) ne '/') then $
        strID = "MENUBARS/" + strID

    self->_UnRegisterItem, strID

end


;;---------------------------------------------------------------------------
;; IDLitUI::RegisterUIService
;;
;; Purpose:
;;   Used to register a UI service with the UI object.
;;
;;   This method will create the adaptor object that is used to
;;   translate between the framework and the procedureal space of the
;;   widget system.
;;
;; Return Value
;;  Th Identifier for the added item. This can be used later
;;  when the item calls into the UI.
;;
;; Parameters:
;;   strName       - name of the toolbar.
;;
;;   strCallback   - The callback method for the DoUIService
;;                   callback. This is a function that is called.
;;
;; Keywords:
;;   DESCRIPTION   - Description of the UI Service.

function IDLitUI::RegisterUIService, strName, strCallback, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    strTmp = IDLitBasename(strName, remainder=strID, /reverse)
    if (strLen(strID) gt 0) then $
        Message, IDLitLangCatQuery('UI:UIdef:NoUINesting')

    ; Use replace to avoid duplicate services
    ; Allows user added service to override default.
    return, self->_RegisterItem(strName, "UIServices", $
        DOUISERVICE_CALLBACK=strCallback, $
        /REPLACE, $
        _EXTRA=_extra)

end


;;---------------------------------------------------------------------------
;; IDLitUI::UnRegisterUIservice
;;
;; Purpose:
;;   Remove a UIService from the system.
;;
;; Parameters:
;   strID: The ID of the service to remove. This may be either a
;       full identifier or relative to the container.
;
pro IDLitUI::UnRegisterUIService, strIDin

    compile_opt idl2, hidden

    strID = STRUPCASE(strIDin)

    ; Not a full identifier?
    if (STRMID(strID, 0, 1) ne '/') then $
        strID = "UISERVICES/" + strID

    self->_UnRegisterItem, strID

end


;;---------------------------------------------------------------------------
;; IDLitUI::RegisterWidget
;;
;; Purpose:
;;   Register a basic UI element.
;;
;;   This method will create the adaptor object that is used to
;;   translate between the framework and the procedureal space of the
;;   widget system.
;;
;; Return Value
;;  The tool Identifier for the added item. This can be used later
;;  when the widget calls into the tool.
;;
;; Parameters:
;;   wID           - Target Widget ID
;;
;;   strName       - name of the ui
;;
;;   strCallback   - The callback method for the OnNotify
;;                   message. This is a function that is called.
;;
;; Keywords:
;;   DESCRIPTION   - Description of the toolbar.

function IDLitUI::RegisterWidget, wID, strName, strCallback, $
    FLOATING=FLOATING, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    return, self->_RegisterItem(strName, "Widgets", $
        FLOATING=keyword_set(FLOATING), $
        ONNOTIFY_CALLBACK=strCallback, $
        WIDGET_ID=wID, $
        _EXTRA=_extra)

end


;;---------------------------------------------------------------------------
;; IDLitUI::UnRegisterWidget
;;
;; Purpose:
;;   Remove a toolbar from the system.
;;
;; Parameters:
;   strID: The ID of the widget to remove. This may be either a
;       full identifier or relative to the container.
;
pro IDLitUI::UnRegisterWidget, strIDin

    compile_opt idl2, hidden

    strID = STRUPCASE(strIDin)

    ; Not a full identifier?
    if (STRMID(strID, 0, 1) ne '/') then $
        strID = "WIDGETS/" + strID

    self->_UnRegisterItem, strID

end


;;---------------------------------------------------------------------------
;; IDLitUI::GetWidgetByName
;;
;; Purpose:
;;   Used to retrieve the widget ID of a widget that has been
;;   registered with the system. The name that it was registred under
;;   is used to find this widget.
;;
;;   If the widget hasn't been registered, a 0 is returned.
;;
;; Parameters:
;;    strName    - The name of the widget. This is treated in a case
;;                 insenstive manner.
;;
;; Return Value:
;;    0 - Error, the requested item isn't contained, otherwise the
;;        widget id of the item.

function IDLitUI::GetWidgetByName, strName
   compile_opt hidden, idl2


   oItem = Self->GetByIdentifier("WIDGETS/"+strName)
   if(obj_valid(oItem))then $
     oItem->GetProperty, widget_id=wID $
   else $
     wID = 0

   return, wID
end
;;---------------------------------------------------------------------------
;; IDLitUI::_CleanupWidgets
;;
;; Purpose:
;;   Will destroy any floating widgets that have been registered with
;;   this object. This is called during UI shutdown.
;;
;; Parameters:
;;   None.

pro IDLitUI::_CleanupWidgets
   compile_opt hidden, idl2

   ;; Get all the reg. widgets
   oItems = Self->GetByIdentifier("WIDGETS")
   if(~obj_valid(oItems))then return
   oWidgets = oItems->Get(/all, count=nWid)
   ;; Delete the floating widgets.
   for i=0, nWid-1 do begin
       oWidgets[i]->getProperty, widget_id=wID, floating=floating
       if(widget_info(wID,/valid_id) && floating gt 0)then $
         widget_control, wID, /destroy
   endfor

end
;;---------------------------------------------------------------------------
;; IDLitUI::AddOnNotifyObserver
;;
;; Purpose:
;;   Used to register as being interested in receiving notifications
;;   from a specific identifier.
;;
;; Parameters:
;;    strObID       - Identifier of the observer object
;;
;;    strID         - The identifier of the object that it is
;;                    interested in.
;;
pro IDLitUI::AddOnNotifyObserver, idObserverIn, idSubjectIn, $
    NO_VERIFY=noVerify

   ;; Pragmas
   compile_opt idl2, hidden

   idSubject = STRUPCASE(idSubjectIn)
   idObserver = STRUPCASE(idObserverIn)

    if (ptr_valid(self._pDispatchSubject)) then begin
       ;; Is this entry already in the table?
       if (~KEYWORD_SET(noVerify) && $
            MAX(*self._pDispatchSubject eq idSubject and $
            *self._pDispatchObserver eq idObserver)) then $
            return
        nItem = N_ELEMENTS(*self._pDispatchSubject)
        ; Do we need to search for an empty dispatch slot?
        if (self._iDispatch ge nItem || $
            (*self._pDispatchSubject)[self._iDispatch] ne '') then begin
           iEmpty = (WHERE(~(*self._pDispatchSubject)))[0]
           if (iEmpty eq -1) then begin
                tmp = STRARR(nItem)
                *self._pDispatchSubject = [*self._pDispatchSubject, tmp]
                *self._pDispatchObserver = $
                    [*self._pDispatchObserver, TEMPORARY(tmp)]
                iEmpty = nItem
                self._iDispatch = iEmpty + 1 ; just filled one
           endif
        endif else begin
            iEmpty = self._iDispatch
            self._iDispatch++
        endelse
    endif else begin
        ; Start out with an adequate cache.
        tmp = STRARR(128)
        self._pDispatchSubject = PTR_NEW(tmp)
        self._pDispatchObserver = PTR_NEW(TEMPORARY(tmp))
        iEmpty = 0
        self._iDispatch = 1 ; just filled the zeroth one
    endelse

   (*self._pDispatchSubject)[iEmpty] = idSubject[0]
   (*self._pDispatchObserver)[iEmpty] = idObserver[0]

end


;;---------------------------------------------------------------------------
;; IDLitUI::RemoveOnNotifyObserver
;;
;; Purpose:
;;   Remove an entry from the OnNotify dispatch table.
;;
;; Parameters:
;;    strObID       - Id of the observer
;;
;;    strID         - The identifier of the object that it is
;;                    interested in.
;;
pro IDLitUI::RemoveOnNotifyObserver, idObserverIn, idSubjectIn
   ;; Pragmas
   compile_opt idl2, hidden

   idSubject = STRUPCASE(idSubjectIn)
   idObserver = STRUPCASE(idObserverIn)
   if(ptr_valid(self._pDispatchSubject))then begin
       ;; Is this entry already in the table? Find the entries that
       ;; don't match the given parameters (where at least one of the
       ;; ids don't match
       idx = where(*self._pDispatchSubject eq idSubject and  $
                   *self._pDispatchObserver eq idObserver, $
                    nItems)

       if (nItems gt 0) then begin
         (*self._pDispatchSubject)[idx] = ''
         (*self._pDispatchObserver)[idx] = ''
       endif
   endif
end

;;---------------------------------------------------------------------------
;; Internal routines
;;---------------------------------------------------------------------------
;; IDLitUI::DoAction
;;
;; Purpose:
;; Method to trigger an action in the system.
;;
;; Parameter
;;   ID - The ID to perform in the tool
function IDLitUI::DoAction, id
  ;; Pragmas
  compile_opt idl2, hidden

  if(not obj_valid(self._oTool))then return, 0
  return, self._oTool->DoAction(id)

end

;;---------------------------------------------------------------------------
;; Internal routines
;;---------------------------------------------------------------------------
;; IDLitUI::GetTool
;;
;; Purpose:
;;  Function to get the tool.
;;

FUNCTION IDLitUI::GetTool
  ;; Pragmas
  compile_opt idl2, hidden

  return, self._oTool
end
;;---------------------------------------------------------------------------
;; IDLitUI__Define
;;
;; Purpose:
;;   This method defines the IDLitUI class.
;;

pro IDLitUI__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = { IDLitUI,                     $
           inherits IDLitContainer,       $ ;; The root of the hierarchy
           _Menubars       : obj_new(),   $ ;; Menubars
           _Toolbars       : obj_new(),   $ ;; Toolbars
           _Statusbar      : obj_new(),   $ ;; Status bar elements
           _UIServices     : obj_new(),   $ ;; UI Services
           _pDispatchSubject : ptr_new(),   $ ;; Lookup table for dispatches
           _pDispatchObserver : ptr_new(),   $ ;; Lookup table for dispatches
           _oTool          : obj_new(),   $ ;; The tool itself
           _iDispatch      : 0L,          $ ; index for lookup table
           _wBase          : 0L           $ ;; Widget ID for the top-level
           }
end
