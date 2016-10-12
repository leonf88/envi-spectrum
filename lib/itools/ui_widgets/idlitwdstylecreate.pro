; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdstylecreate.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdStyleCreate
;
; PURPOSE:
;   This function implements a simple text dialog.
;
; CALLING SEQUENCE:
;   IDLitwdStyleCreate
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2004
;   Modified:
;
;-

pro IDLitwdStyleCreate_Okay, pState, wTop

    compile_opt idl2, hidden

    wText = WIDGET_INFO(wTop, FIND_BY_UNAME='TEXT')
    WIDGET_CONTROL, wText, GET_VALUE=text
    (*pState).text = text

    wCreateAll = WIDGET_INFO(wTop, FIND_BY_UNAME='CREATE_ALL')
    (*pState).createAll = WIDGET_INFO(wCreateAll, /BUTTON_SET)

    WIDGET_CONTROL, wTop, /DESTROY

end


;-------------------------------------------------------------------------
; IDLitwdStyleCreate_event
;
; Purpose:
;   Event handler for this widget. It only really handles the ok
;   button.
;
; Parameters:
;   event   = The widget event.
;
pro IDLitwdStyleCreate_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState

    ; Manually destroy our widget to prevents flashing on Windows platforms.
    if (TAG_NAMES(event, /STRUCT) eq 'WIDGET_KILL_REQUEST') then begin
        (*pState).text = ''   ; cancelled
        WIDGET_CONTROL, event.id, /DESTROY
        return
    endif

    case widget_info(event.id, /uname) of

    'OK': IDLitwdStyleCreate_Okay, pState, event.top

    'CANCEL': WIDGET_CONTROL, event.top, /DESTROY

    'HELP': begin
        oTool = (*pState).oUI->GetTool()
        oSys = oTool->_GetSystem()
        oHelp = oSys->GetService('HELP')
        if (OBJ_VALID(oHelp)) then $
            oHelp->HelpTopic, oSys, 'iToolsCreateStyle'
        end

    'TEXT': begin
        if (event.type eq 0 && $
            (event.ch eq 13b || event.ch eq 10b)) then begin
            IDLitwdStyleCreate_Okay, pState, event.top
        endif else begin
            wText = WIDGET_INFO(event.top, FIND_BY_UNAME='TEXT')
            WIDGET_CONTROL, wText, GET_VALUE=text
            wOK = WIDGET_INFO(event.top, FIND_BY_UNAME='OK')
            WIDGET_CONTROL, wOK, SENSITIVE=STRLEN(text) gt 0
            WIDGET_CONTROL, event.top, DEFAULT_BUTTON=wOK
        endelse
        end

    else:

    endcase

end


;-------------------------------------------------------------------------
; IDLitwdStyleCreate
;
; Purpose:
;   This is a simple modal widget that will display a text widget.
;
; Parameters:
;    oUI     - The UI object
;
; Keywords:
;
function IDLitwdStyleCreate, oUI, $
    CREATE_ALL=createAll, $
    GROUP_LEADER=groupLeaderIn, $
    VALUE=text, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Check keywords.
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L

    pState = PTR_NEW({oUI: oUI, text: '', createAll: 0b})

    ; Create our floating base.
    wTLB = WIDGET_BASE( /COLUMN, $
        /FLOATING, /MODAL, $
        GROUP_LEADER=groupLeader, $
        TITLE=IDLitLangCatQuery('UI:wdStyleCreate:Title'), $
        SPACE=5, XPAD=5, YPAD=5, $
        /TLB_KILL_REQUEST_EVENTS, $
        UVALUE=pState, $
        _EXTRA=_extra)

    wLabel = WIDGET_LABEL(wTLB, VALUE= $
                          IDLitLangCatQuery('UI:wdStyleCreate:EnterName'), $
                          /ALIGN_LEFT)

    slen = (N_ELEMENTS(text) eq 1) ? STRLEN(text) : 0
    wText = WIDGET_TEXT(wTLB, UNAME='TEXT', $
        /ALL_EVENTS, /EDITABLE, $
        VALUE=text, $
        XSIZE=(35 > slen < 80))

    oTool = oUI->GetTool()
    void = oTool->GetSelectedItems(COUNT=nsel)
    if (nsel eq 0) then begin
        nsel = OBJ_VALID(oTool->GetCurrentWindow()) ? -1 : 0
    endif

    wExc = WIDGET_BASE(wTLB, /EXCLUSIVE, $
        SPACE=0, XPAD=2, YPAD=0)
    wSelected = WIDGET_BUTTON(wExc, VALUE=IDLitLangCatQuery('UI:wdStyleCreate:CreateSel'), $
        SENSITIVE=(nsel ne 0))
    wCreateAll = WIDGET_BUTTON(wExc, VALUE=IDLitLangCatQuery('UI:wdStyleCreate:CreateAll'), $
        UNAME='CREATE_ALL')

    WIDGET_CONTROL, (nsel gt 0) ? wSelected : wCreateAll, /SET_BUTTON

    xsize = 250 > (WIDGET_INFO(wTLB, /GEOM)).scr_xsize
    wButtons = WIDGET_BASE(wTLB, COLUMN=2, /GRID, $
        SPACE=0, XPAD=2, YPAD=2, $
        SCR_XSIZE=xsize - 5)

    w1 = WIDGET_BASE(wButtons, /ALIGN_LEFT, XPAD=0, YPAD=0)

    wHelp = WIDGET_BUTTON(w1, $
                          VALUE=IDLitLangCatQuery('UI:wdStyleCreate:Help'), $
                          UNAME='HELP')

    w2 = WIDGET_BASE(wButtons, /ALIGN_RIGHT, /ROW, /GRID, $
        SPACE=5, XPAD=0, YPAD=0)

    wOK = WIDGET_BUTTON(w2, VALUE=IDLitLangCatQuery('UI:OK'), $
                        UNAME='OK', SENSITIVE=(slen gt 0))

    wCancel = WIDGET_BUTTON(w2, VALUE=IDLitLangCatQuery('UI:CancelPad'), $
                            UNAME='CANCEL')

    WIDGET_CONTROL, wTLB, CANCEL_BUTTON=wCancel, $
        DEFAULT_BUTTON=wOK

    WIDGET_CONTROL, wTLB, /REALIZE
    WIDGET_CONTROL, wText, /INPUT_FOCUS

    ; Fire up the xmanager.
    XMANAGER, "IDLitwdStyleCreate", wTLB,  NO_BLOCK=0

    createAll = (*pState).createAll
    result = (*pState).text
    PTR_FREE, pState

    return, result
end

