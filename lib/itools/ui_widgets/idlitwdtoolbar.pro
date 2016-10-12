; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdtoolbar.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdToolbar
;
; PURPOSE:
;   This function implements a floating IT toolbar.
;
; CALLING SEQUENCE:
;   IDLitwdToolbar, Tool
;
; INPUTS:
;   Tool: Set this argument to the object reference for the IDL Tool.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-


;;-------------------------------------------------------------------------
;+
;; IDLitwdToolbar_callback
;;
;; Purpose:
;;   Callback routine for the tool interface widget, allowing it to
;;   receive update messages from the system.
;;
;; Parameters:
;;   wBase     - Base id of this widget
;;
;;   strID     - ID of the message.
;;
;;   MessageIn - What is the message
;;
;;   userdata  - Data associated with the message
;-
;
pro IDLitwdToolbar_callback, wBase, strID, messageIn, userdata
    compile_opt idl2, hidden

    if (~WIDGET_INFO(wBase, /VALID)) then $
        return

    ;; Grab the state of the widget
    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), GET_UVALUE=state

    case STRUPCASE(messageIn) of

    ; The sensitivity is to be changed
    'SENSITIVE': begin
        WIDGET_CONTROL, wBase, SENSITIVE=userdata
    end

    else:  ; do nothing

    endcase

end

;-------------------------------------------------------------------------
;+
; NAME:
;   IDLitwdToolbar_Destroy
;
; PURPOSE:
;   This procedure destroys the identified toolbar.
;
; CALLING SEQUENCE:
;   IDLitwdToolbar_Destroy, oUI, identifier
;
; INPUTS:
;   oUI:    A reference to the user interface object.
;   identifier: A string representing the (relative) identifier of the
;     toolbar to be destroyed.
;
;-
pro IDLitwdToolbar_Destroy, oUI, identifier

    compile_opt idl2, hidden

    oToolbarAdaptor = oUI->GetByIdentifier('Toolbars/'+identifier)
    if (OBJ_VALID(oToolbarAdaptor) eq 0) then return

    oToolbarAdaptor->GetProperty, WIDGET_ID=wID

    ; Seek the top level parent and destroy it.
    wParent = wID
    while (WIDGET_INFO(wParent, /VALID) ne 0) do begin
        wTLB = wParent
        wParent = WIDGET_INFO(wTLB, /PARENT)
    endwhile
    WIDGET_CONTROL, wTLB, /DESTROY

    oUI->UnRegisterToolBar, identifier
end


;-------------------------------------------------------------------------
; Purpose:
;   Handle our kill request events.
;
pro IDLitwdToolbar_event, event

    compile_opt idl2, hidden

    if (~(TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KILL_REQUEST')) $
        then return

    WIDGET_CONTROL, WIDGET_INFO(event.id, /CHILD), GET_UVALUE=state
    if (state.toolbar_id ne '') then begin
        success = state.tool->DoAction(state.toolbar_id)
        state.tool->DoOnNotify, state.toolbar_id, 'CHANGE', 0
    endif

end


;-------------------------------------------------------------------------
function IDLitwdToolbar, oUI, $
                         GROUP_LEADER=groupLeader, $
                         TARGET_IDENTIFIER=identifier, $
                         TOOLBAR_IDENTIFIER=toolId, $
                         TITLE=titleIn, $
                         UVALUE=uvalue, $
                         _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdToolbar'

    ; Check arguments.
    if (N_PARAMS() ne 1) then $
        MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

    if not OBJ_VALID(oUI) then $
        MESSAGE, IDLitLangCatQuery('UI:InvalidUI')

    ; Defaults for keywords.
    oTool = oUI->GetTool()
    oContainer = oTool->GetByIdentifier(identifier)
    if (OBJ_VALID(oContainer) eq 0) then $
        return, 0

    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
      IDLitLangCatQuery('UI:wdToolBar:Title')
    hasLeader = (N_ELEMENTS(groupLeader) gt 0) ? $
        WIDGET_INFO(groupLeader, /VALID) : 0

    ; Create the floating base.
    tlb_noResize = 1
    tlb_noSysMenu = 2
    tlb_noClose = 8
    wBase = WIDGET_BASE( $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, $
        TITLE=title, $
        /TLB_KILL_REQUEST_EVENTS, $
        TLB_FRAME_ATTR=tlb_noResize, $
        /TOOLBAR, $
        XPAD=0, YPAD=0, SPACE=0, $
        UVALUE=uvalue, $
        _EXTRA=_extra)

    state = {TOOL: oTool, $
            TOOLBAR_ID: N_ELEMENTS(toolId) ? toolId : ''}

    ; Create the toolbar button base.
    ; This does all the event handling for the buttons.
    wToolbar = CW_ITTOOLBAR(wBase, oUI, identifier, $
        /EXCLUSIVE, $
        _EXTRA=_extra)

    ;; Register ourself as a widget with the UI object.
    ;; Returns a string containing our identifier.
    ; Observe the system so that we can be desensitized when a macro is running
    myID = oUI->RegisterWidget(wBase, identifier, 'idlitwdtoolbar_callback')
    oSys = oTool->_GetSystem()
    oUI->AddOnNotifyObserver, myID, oSys->GetFullIdentifier()

    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), SET_UVALUE=state

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, /NO_BLOCK
    WIDGET_CONTROL, wBase, /REALIZE

    return, wBase
end

