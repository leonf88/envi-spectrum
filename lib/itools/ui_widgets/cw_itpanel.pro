; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itpanel.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_ITPANEL
;
; PURPOSE:
;   This function implements the compound widget for tool control panels
;
; CALLING SEQUENCE:
;   Result = CW_ITPANEL(Parent, UI)
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
;   oUI: User interface object.
;
; KEYWORD PARAMETERS:
;
;  ORIENTATION: The panel orientation.
;       0=on the left, 1=on the right.
;
; OUTPUT:
;   ID of the newly created widget
;
; MODIFICATION HISTORY:
;   Written by:  RSI, February 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
; cw_itpanel_callback
;
; Purpose:
;   Callback routine for the panel interface widget, allowing it to
;   receive update messages from the system.
;
; Parameters:
;   wBase     - Base id of this widget
;
;   strID     - ID of the message.
;
;   MessageIn - What is the message
;
;   userdata  - Data associated with the message
;
pro cw_itpanel_callback, wBase, strID, messageIn, userdata

    compile_opt idl2, hidden

    if (~WIDGET_INFO(wBase, /VALID)) then $
        return

    ; Grab the state of the widget
    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), GET_UVALUE=pState

    case STRUPCASE(messageIn) of

    ; Do we need to add panels to the UI?
    'ADDUIPANELS': begin
        void = cw_itpanel_addPanel(wBase, userData)
        end

    'SHOWUIPANELS': begin
        ; NOTE: By managing update, the tool seems to flash
        ; less on Windows.
        isUpdate = WIDGET_INFO(wBase, /UPDATE)
        if (isUpdate) then $
            widget_control, wBase, update=0
        (*pState).bShow = userdata ; change hide status

        if ((*pState).bShow) then begin ; show the panel

            widget_control, (*pState).wWrapper, map=1, $ ;map and resize out
               scr_xsize=(*pState).xsize, $
               scr_ysize=(*pState).ysize
            ; update button
            widget_control, (*pState).wButton, set_value=(*pState).bmClose, $
              /bitmap, tooltip=IDLitLangCatQuery('UI:cwPanel:ClosePanel')

        endif else begin           ;hide the panel

            ; stash the current size of the tab
            geom = Widget_Info((*pState).wWrapper,/geometry)
            (*pState).xsize = geom.scr_xsize
            (*pState).ysize = geom.scr_ysize
            widget_control, (*pState).wWrapper, map=0, $;shrink & unmap
                            scr_xsize=1, scr_ysize=1; 0 doesn't work on unix

            widget_control, (*pState).wButton, set_value=(*pState).bmOpen, $
              /bitmap, tooltip=IDLitLangCatQuery('UI:cwPanel:OpenPanel')

        endelse

        if (isUpdate && ~WIDGET_INFO(wBase, /UPDATE)) then $
            widget_control, wBase, /UPDATE

        end

    else:

    endcase

end


;---------------------------------------------------------------------------
; cw_itpanel_resize
;
; Purpose:
;   Called to resize the panel
;
; Parameters:
;   wPanel   - widget id for this panel
;
;   ysize    - the new ysize.
;
pro cw_itpanel_resize, wPanel, ysize
   compile_opt hidden, idl2

    wWrapper = WIDGET_INFO(wPanel, /CHILD)
    WIDGET_CONTROL, wWrapper, GET_UVALUE=pState
    if (~widget_info((*pState).wTab, /valid)) then $
        return

    if (ysize ne 0) then begin
        widget_control, (*pState).wTab, scr_ysize=ysize

        ; Wrapper is what is hidden all the time, so resize it also
        widget_control, (*pState).wWrapper, scr_ysize=ysize

        (*pState).ySize = ysize
    endif

    ; Retrieve parent (widget_tab) geometry.
    tabGeom = WIDGET_INFO((*pState).wTab, /GEOM)

    wTabChild = WIDGET_INFO((*pState).wTab, /CHILD)

    while WIDGET_INFO(wTabChild, /VALID) do begin

        ; Retrieve child geometry.
        panelGeom = WIDGET_INFO(wTabChild, /GEOM)

        ; Update the dimensions of the visible portion of the scroll base.
        ; Note that we use our cached value for the xsize, but the actual
        ; geometry value for the ysize. For the xsize this avoids problems
        ; if a scrollbar is added.
        WIDGET_CONTROL, wTabChild, SCR_YSIZE=tabGeom.ysize
        ; Always make the width equal to the largest panel.
        WIDGET_CONTROL, wTabChild, XSIZE=(*pState).xSize

        wTabChild = WIDGET_INFO(wTabChild, /SIBLING)
    endwhile

end


;---------------------------------------------------------------------------
; cw_itpanel_addpanel
;
; Purpose:
;   Method to add a panel to a tool.
;   Returns 1 if panels were added, returns 0 if all the desired panels
;   already exist.
;
; Parameters:
;   wPanel   - widget ID to this widget
;
;   panel_callbacks  - The routines to create the panels
;
function cw_itpanel_addpanel, wPanel, panel_callbacks

    compile_opt idl2, hidden

    npanel = N_ELEMENTS(panel_callbacks)
    if (~npanel) then $
        return, 0

    WIDGET_CONTROL, widget_info(wPanel,/child), GET_UVALUE=pstate

    ; See if we already have panels.
    hasPanel = WIDGET_INFO((*pstate).wTab, /VALID)
    hasCallbacks = 0b

    if (hasPanel) then begin
        WIDGET_CONTROL, (*pstate).wTab, GET_UVALUE=previous_callbacks
        hasCallbacks = N_ELEMENTS(previous_callbacks) gt 0
    endif else begin
        widget_control, wPanel, update=0
        wTab = WIDGET_TAB((*pState).wWrapper, LOCATION=0)
        (*pstate).wTab = wTab
        ; make the hide/close button
        (*pState).wButton = cw_itPanel_makebutton((*pState).wBBase, $
            (*pState).bmClose)
    endelse

    ; Retrieve parent (widget_tab) geometry.
    tabGeom = WIDGET_INFO((*pState).wTab, /GEOM)

    ; Add the panels
    addedPanel = 0b
    for i=0, npanel-1 do begin
        ; Skip panels that already exist.
        if (hasCallbacks && MAX(STRCMP(previous_callbacks, $
            panel_callbacks[i], /FOLD_CASE)) eq 1) then $
            continue
        if (~panel_callbacks[i]) then $
            continue
        addedPanel = 1b
        widget_control, wPanel, update=0
        wTabChild = WIDGET_BASE((*pstate).wTab, XPAD=0, YPAD=0, /SCROLL)
        CALL_PROCEDURE, panel_callbacks[i], wTabChild, (*pstate).oUI

        ; Note: on some platforms (Irix), the widget geometry of the
        ; scroll base does not fully reflect its content geometry.
        ; Explicitly set it here to get around this problem.
        wTabSubChild = WIDGET_INFO(wTabChild, /CHILD)
        if (WIDGET_INFO(wTabSubChild, /VALID_ID)) then begin
            contentGeom = WIDGET_INFO(wTabSubChild, /GEOM)
            WIDGET_CONTROL, wTabChild, $
                XSIZE=contentGeom.xsize
            ; Cache the largest width.
            (*pState).xSize >= contentGeom.scr_xsize
        endif

    endfor

    ; All the panels already existed.
    if (~addedPanel) then $
        return, 0

    callbacks = hasCallbacks ? $
        [previous_callbacks, panel_callbacks] : panel_callbacks

    ; Set the new panel to being current
    iTab = widget_info((*pstate).wTab, /tab_number)
    widget_control, (*pstate).wTab, set_tab_current=iTab-1, $
        SET_UVALUE=callbacks

    if (~WIDGET_INFO(wPanel, /UPDATE)) then $
        widget_control, wPanel, /UPDATE

    return, 1
end


;---------------------------------------------------------------------------
; cw_itpanel_makebutton
;
; Purpose:
;   Routine to encapsulate the making of the button for the
;   hide/show. This is needed since the button can be added post realize
;
; Parameters:
;   Parent   - The parent of the button
;
;   bmClose   - The name of the image to use.
;
; Return Value:
;   Returns the button widget id
function cw_itpanel_makebutton, Parent, bmClose
    compile_opt hidden, idl2

    ; Resize the button to fit the bitmap
    bmTmp = file_basename(bmClose)
    status = IDLitGetResource(strmid(bmTmp, 0, strpos(bmTmp,'.')), value, /bitmap)
    if(status eq 1)then begin
        rec = size(value, /dimensions) +2; add some padding for display
        wButton = widget_button(Parent, $
                                value=bmClose, /bitmap, /FLAT, $
                                uname="HIDE", $
                                tooltip=IDLitLangCatQuery('UI:cwPanel:ClosePanel'), $
                                scr_xsize=rec[0], scr_ysize=rec[1])
    endif else $
      wButton = widget_button(Parent, $
                              value=bmClose, /bitmap, /FLAT, $
                              uname="HIDE", $
                              tooltip=IDLitLangCatQuery('UI:cwPanel:ClosePanel'))
    return, wButton
end


;---------------------------------------------------------------------------
; cw_itpanel_cleanup
;
; Purpose:
;   cleanup routine called with this widget dies. Used to free
;   the state structure pointer.
;
; Parameters:
;    wID  - The widget that contains the stat struct

pro cw_itpanel_cleanup, wID
    compile_opt hidden, idl2

    widget_control, wID, get_uvalue=pState
    if(ptr_valid(pState))then ptr_free, pState

end


;---------------------------------------------------------------------------
; cw_itpanel_event
;
; Purpose:
;   Event handler for this compound widget.
;
; Parameters:
;   sEvent   - The event that was triggered.
;
function cw_itpanel_event, sEvent

    compile_opt hidden, idl2

    widget_control, widget_info(sEvent.handler, /child), get_uvalue=pState
    name = widget_info(sEvent.id, /uname)

    ; Was the hide/show button pushed?
    if (name eq 'HIDE') then begin
        (*pState).bShow = ~(*pState).bShow ; change hide status
        oTool = (*pState).oUI->GetTool()
        ; NOTE: By managing update, the tool seems to flash
        ; less on Windows.
        isUpdate = WIDGET_INFO(sEvent.top, /UPDATE)
        if (isUpdate) then $
            widget_control, sEvent.top, UPDATE=0
        ; This will notify both ourself (see _callback) and our top base.
        oTool->DoOnNotify, oTool->GetFullIdentifier(), $
            'SHOWUIPANELS', (*pState).bShow
        if (isUpdate && ~WIDGET_INFO(sEvent.top, /UPDATE)) then $
            widget_control, sEvent.top, /UPDATE
    endif

    return, 0                   ;eat the event
end


;-------------------------------------------------------------------------
function cw_itpanel, Parent, oUI, $
                     ORIENTATION=orientation, $
                     _REF_EXTRA=_extra

    compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

    ; Default sizes.
    if N_ELEMENTS(orientation) eq 0 then $
        orientation = 1

    column = orientation gt 1

    ; Make the main base
    wBase = WIDGET_BASE(Parent, space=0, xpad=0, ypad=0, $
        EVENT_FUNC='cw_itpanel_event', $
        COLUMN=column, ROW=~column, $
        BASE_ALIGN_TOP=~column, $
        BASE_ALIGN_RIGHT=column, $
        _EXTRA=_extra)

    ; Which buttons.
    buttons = ["spinright.bmp", "spinleft.bmp"]

    wWrapper = widget_base(wBase, xpad=0, ypad=0, space=0)
    wBBase = WIDGET_BASE(wBase, space=0, xpad=0, ypad=0)

    ; Panel on the right. Switch the bases and buttons.
    if (orientation eq 1) then begin
        wTmp = wBBase
        wBBase = wWrapper
        wWrapper = wTmp
        buttons = buttons[[1,0]]
    endif

    bmClose = FILEPATH(buttons[0], SUBDIR=['resource','bitmaps'])
    bmOpen = FILEPATH(buttons[1], SUBDIR=['resource','bitmaps'])

    ; Make our state
    state = { $
              oUI     : oUI,     $
              wTab    : 0L,    $
              wWrapper: wWrapper,$
              bShow   : 1b,      $ ; hidden panel or not
              bmOpen  : bmOpen,  $
              bmClose : bmClose, $
              wButton : 0L, $
              xsize   : 0,       $
              ysize   : 0,       $
              wBBase  : wBBase,  $
              orientation: orientation $
          }

    WIDGET_CONTROL, widget_info(wBase, /child), $
        SET_UVALUE=ptr_new(State, /no_copy), $
        kill_notify="cw_itpanel_cleanup"

    ; See if we have any panels that need to be created.
    ; It is better to do this here rather than in UpdateToolByType
    ; (which will happen automatically) since at this point the
    ; widgets havn't been realized and startup will be faster.
    oTool = oUI->GetTool()
    oTool->GetProperty, TYPES=ToolTypes
    oSys = oTool->_GetSystem()

    panels = oSys->_GetUIPanelRoutines(ToolTypes, COUNT=nPanels)
    if (nPanels gt 0) then $
        void = CW_ITPANEL_ADDPANEL(wBase, panels)

    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    myID = oUI->RegisterWidget(wBase, 'PanelBase', 'cw_itpanel_callback')

    ; Register for our messages.
    oUI->AddOnNotifyObserver, myID, oTool->GetFullIdentifier()

    return, wBase
end

