; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itmenu.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   cw_itmenu
;
; PURPOSE:
;   This function implements the compound widget for an iTools menu.
;
; CALLING SEQUENCE:
;   Result = CW_ITMENU(Parent, UI, Target)
;
; INPUTS:
;   Parent: The widget ID of the parent for the new menu.
;       The parent must be either a base widget or a button widget.
;       If Parent is a button widget, then the parent button widget
;       must either:
;           1.	Have the MENU keyword set.
;           2.	Have as its parent a base widget with the MBAR keyword set.
;
;   UI: The object reference of the IDLitUI object associated with the iTool.
;
;   Target: Set this argument to a string containing the relative or full
;       identifier of the tool container from which to construct the menu.
;
; KEYWORD PARAMETERS:
;   CONTEXT_MENU: Set this keyword to create a context menu instead of a
;       standard pulldown menu. In this case the Parent must be one of
;       the following widget types: WIDGET_BASE, WIDGET_DRAW,
;       WIDGET_TEXT, WIDGET_LIST, WIDGET_PROPERTYSHEET, WIDGET_TABLE,
;       WIDGET_TEXT or WIDGET_TREE.
;   Note: If a context menu is created then the ACCELERATOR property is
;       ignored for all contained items.
;
;   All other keywords (such as UNAME, UVALUE, etc.) are passed
;   on to the menu.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified: CT, May 2004: Renamed.
;       Changed Target from keyword to argument.
;
;-

;-------------------------------------------------------------------------
pro cw_itmenu_callback, wBase, strID, messageIn, userdata

    compile_opt idl2, hidden

    idTmp = STRUPCASE(StrID)

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; Is the strID equal to ourself? Because we are a compound widget we
    ; aren't allowed to use our UNAME to store our ID.
    if (state.idContainer eq strID) then begin

        wID = wBase

    endif else begin   ; must be one of the children

        ;; Some identifiers will have "extra" sub-items that the toolbar
        ;; doesn't care about. So nip those off until we find a match.
        while (1) do begin
            wID = widget_info(wBase, find_by_uname=idTmp)
            if (wID gt 0) then $
                break
            void = IdlitBaseName(idTmp, remain=idTmp)
            if (void eq '') then $
                return ;; no match!
        endwhile
        if (~WIDGET_INFO(wID, /VALID)) then $
            return

    endelse


    case STRUPCASE(messageIn) of

        'SELECT': begin
            ; Turn ourselves on.
            newState = KEYWORD_SET(userdata)  ; 0 or 1
            if (WIDGET_INFO(wID, /BUTTON_SET) ne newState) then $
                WIDGET_CONTROL, wID, SET_BUTTON=newState
            end

        'SENSITIVE': widget_control, wID, sensitive=KEYWORD_SET(userdata)

        'SETPROPERTY': begin
            if (userdata ne 'NAME') then $
                break
            oTool=state.oUI->GetTool()
            oItem = oTool->GetByIdentifier(strID)
            if (~OBJ_VALID(oItem)) then $
                break
            oItem->IDLitComponent::GetProperty, NAME=name
            WIDGET_CONTROL, wID, SET_VALUE=name
            end

        'ADDITEMS': begin       ;add a menu entry to the widget
            oTool = state.oUI->GetTool()
            oItem = oTool->GetByIdentifier(userdata)
            if ~cw_itmenu_ADDITEM(wID, oItem, state.contextMenu) then $
                break
            state.oUI->AddOnNotifyObserver, state.idUIadaptor, userData
            end

        'REMOVEITEMS': begin
            wMenuItem = WIDGET_INFO(wBase, FIND_BY_UNAME=userdata)
            ; There is no need to check if my parent is empty, because
            ; the Unregister code should do this for us and automatically
            ; issue a callback.
            if WIDGET_INFO(wMenuItem, /VALID) then $
                WIDGET_CONTROL, wMenuItem, /DESTROY
            state.oUI->RemoveOnNotifyObserver, state.idUIadaptor, userData
            end

        else:
    endcase

end


;-------------------------------------------------------------------------
pro cw_itmenu_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of
        'WIDGET_BUTTON': begin

            ; Toggle the menu item. If it was on, turn it off, vice versa.
            strPath = WIDGET_INFO(event.id, /UNAME)
            toggle = WIDGET_INFO(event.id, /BUTTON_SET)
            WIDGET_CONTROL, event.id, SET_BUTTON=1-toggle
            WIDGET_CONTROL, /HOURGLASS
            success = state.oUI->DoAction(strPath)
            end
        else: message, IDLitLangCatQuery('UI:cwMenuBar:BadStruct')
    endcase

end


;-------------------------------------------------------------------------
; Add either a submenu (from a container) or a regular menu item.
;
function cw_itmenu_additem, Parent, oItem, contextMenu

    compile_opt idl2, hidden

    if (~OBJ_VALID(oItem)) then $
        return, 0L

    strPath = oItem->GetFullIdentifier()

    oItem->GetProperty, NAME=name, $
        PRIVATE=private
    if (~name || private) then $
        return, 0L

    ; Don't allow separator for first menu item, because either
    ; it's ugly, or it's already been added to the parent menu.
    parentHasChild = WIDGET_INFO(WIDGET_INFO(Parent, /CHILD), /VALID)

    if (OBJ_ISA(oItem, 'IDLitContainer')) then begin

        ; Don't allow separator for first menu item, because it's ugly.
        if parentHasChild then begin
            ; If my first child (or grandchild) has the separator
            ; keyword set, then we actually need to set it for ourself.
            ; Retrieve first non-container child.
            oSubItem = oItem->Get(POSITION=0)
            while (OBJ_VALID(oSubItem) && $
                OBJ_ISA(oSubItem, 'IDLitContainer')) do begin
                oSubItem = oSubItem[0]->Get(POSITION=0)
            endwhile
            ; See if separator property is set.
            if (OBJ_VALID(oSubItem)) then $
                oSubItem->GetProperty, SEPARATOR=separator
        endif

        wItem = WIDGET_BUTTON(Parent, $
            /MENU, $
            SEPARATOR=parentHasChild ? separator : 0, $
            UNAME=strPath, $
            VALUE=name)

    endif else begin

        oItem->GetProperty, $
            ACCELERATOR=accelerator, $
            CHECKED=checked, $
            DISABLE=disable, $
            SEPARATOR=separator

        ; Create the menu item.
        wItem = WIDGET_BUTTON(Parent, $
            ACCELERATOR=contextMenu ? '' : accelerator, $
            CHECKED=checked, $
            /DYNAMIC_RESIZE, $
            SENSITIVE=~KEYWORD_SET(disable), $
            SEPARATOR=parentHasChild ? separator : 0, $
            UNAME=strPath, $
            VALUE=name)

    endelse

    return, wItem
end


;-------------------------------------------------------------------------
; Recursively add menubar items from myself and my children.
;
pro cw_itmenu_addmenu, Parent, oContainer, contextMenu, oUI, idUIAdaptor

    compile_opt idl2, hidden

    oItems = oContainer->Get(/ALL, COUNT=nItems)

    ; Loop thru the current menu item object descriptors,
    ; retrieving the necessary information.
    for i=0,nItems-1 do begin
        wItem = cw_itmenu_ADDITEM(Parent, oItems[i], contextMenu)
        if (~wItem) then $
            continue
        ; Recursively add a container's submenus.
        if (OBJ_ISA(oItems[i], 'IDLitContainer')) then begin
            cw_itmenu_ADDMENU, wItem, oItems[i], contextMenu, $
                oUI, idUIAdaptor
        endif
        oUI->AddOnNotifyObserver, idUIadaptor, oItems[i]->GetFullIdentifier()
    endfor

end


;-------------------------------------------------------------------------
function cw_itmenu, Parent, oUI, identifier, $
    CONTEXT_MENU=contextMenu, $
    _EXTRA=_extra

    compile_opt idl2, hidden

nparams = 3  ; must be defined for cw_iterror
@cw_iterror

    oTool = oUI->GetTool()
    ; Retrieve the list of menu items within our tool container.
    ;
    oContainer = oTool->GetByIdentifier(identifier)
    if (~OBJ_VALID(oContainer) || $
        ~OBJ_ISA(oContainer, 'IDLitContainer')) then $
        return, -1L
    idContainer =  oContainer->GetFullIdentifier()
    oContainer->IDLitComponent::GetProperty, NAME=containername

    ; Create either a context menu base or a menubar button.
    contextMenu = KEYWORD_SET(contextMenu)
    if (contextMenu) then begin
        wMenubar = WIDGET_BASE(Parent, /CONTEXT_MENU, $
            EVENT_PRO="cw_itmenu_event", $
            _STRICT_EXTRA=_extra)
    endif else begin
        wMenubar = WIDGET_BUTTON(Parent, /MENU, $
            EVENT_PRO="cw_itmenu_event", $
            VALUE=containername, $
            _STRICT_EXTRA=_extra)
    endelse

    ; Register ourself as a menubar with the UI object.
    strTmp = IDLitBasename(identifier, remainder=strID)
    idUIadaptor = oUI->RegisterMenuBar(wMenubar, strTmp, $
                                       'cw_itmenu_callback')

    cw_itmenu_ADDMENU, wMenubar, oContainer, contextMenu, $
        oUI, idUIAdaptor

    ; Cache our member data within the first child widget, if we have one.
    state = { $
        oUI: oUI, $
        idContainer: idContainer, $
        idUIAdaptor: idUIAdaptor, $
        contextMenu: contextMenu $
        }

    wChild = WIDGET_INFO(wMenubar, /CHILD)
    if wChild ne 0 then $
        WIDGET_CONTROL, wChild, SET_UVALUE=state, /NO_COPY

    ; Register for notification messages
    oUI->AddOnNotifyObserver, idUIadaptor, idContainer

    return, wMenubar
end

