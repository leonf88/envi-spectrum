; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdstyleapply.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdStyleApply
;
; PURPOSE:
;   This function implements an Apply Style dialog
;
; CALLING SEQUENCE:
;   IDLitwdStyleApply
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Dec 2003
;   Modified:
;
;-

;-------------------------------------------------------------------------
pro IDLitwdStyleApply_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.top, GET_UVALUE=pState

    ; Manually destroy widget to prevents flashing on Windows platforms.
    if (TAG_NAMES(event, /STRUCT) eq 'WIDGET_KILL_REQUEST') then begin
        WIDGET_CONTROL, event.id, /DESTROY
        return
    endif

    case WIDGET_INFO(event.id, /UNAME) of
    'OK': begin
        (*pState).select = WIDGET_INFO((*pState).wList, /LIST_SELECT)
        case (1) of
        WIDGET_INFO((*pState).wSelected, /BUTTON_SET): (*pState).apply = 1
        WIDGET_INFO((*pState).wApplyView, /BUTTON_SET): (*pState).apply = 2
        WIDGET_INFO((*pState).wApplyAll, /BUTTON_SET): (*pState).apply = 3
        else:
        endcase
        (*pState).UpdateCurrent = $
            WIDGET_INFO((*pState).wCurrent, /BUTTON_SET)
        WIDGET_CONTROL, event.top, /DESTROY
        end

    'CANCEL': begin
        WIDGET_CONTROL, event.top, /DESTROY
        end

    'HELP': begin
        oHelp = (*pState).oSys->GetService('HELP')
        if (OBJ_VALID(oHelp)) then $
            oHelp->HelpTopic, (*pState).oSys, 'iToolsApplyStyle'
        break
        end

    else:

    endcase
end


;-------------------------------------------------------------------------
; IDLitwdStyleApply
;
; Purpose:
;   This is a simple modal widget that allows the user to choose
;   a style to apply.
;
; Return value:
;   0 if the dialog was cancelled, 1 if OK was pressed.
;
; Parameters:
;    oUI     - The UI object
;
; Keywords:
;
;   APPLY: Input/output keyword containing one of the following values:
;       1: Apply to selected items.
;       2: Apply to all items in view.
;       3: Apply to all items in all views.
;
;   GROUP_LEADER: Set to the widget ID of the group leader.
;
;   STYLE_NAME: Input/output keyword containing the style name to apply.
;
;   UPDATE_CURRENT: On input, set this keyword to enable the
;       Update Current checkbox. On output, this keyword will contain
;       the final state of the Update Current checkbox (either 0 or 1).
;
function IDLitwdStyleApply, oUI, $
    GROUP_LEADER=groupleader, $
    APPLY=apply, $
    STYLE_NAME=styleName, $
    UPDATE_CURRENT=updateCurrent, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oTool = oUI->GetTool()
    oSys = oTool->_GetSystem()
    oService = oSys->GetService('STYLES')
    oStyles = oService->Get(/ALL, COUNT=nstyles)
    void = oTool->GetSelectedItems(COUNT=nsel)
    if (nsel eq 0) then begin
        nsel = OBJ_VALID(oTool->GetCurrentWindow()) ? -1 : 0
    endif

    stylenames = STRARR(nstyles)
    styleInit = (N_ELEMENTS(styleName) gt 0) ? styleName[0] : ''
    for i=0,nstyles-1 do begin
        oStyles[i]->GetProperty, NAME=name
        stylenames[i] = name
    endfor

    stylenames = stylenames[SORT(STRUPCASE(stylenames))]
    match = (WHERE(stylenames eq styleInit))[0] > 0

    wBase = WIDGET_BASE( /COLUMN, $
        /FLOATING, /MODAL, $
        GROUP_LEADER=groupleader, $
        SPACE=5, $
        TITLE=IDLitLangCatQuery('UI:wdStyleApply:Title'), $
        /TLB_KILL_REQUEST_EVENTS, $
        _EXTRA=_extra)

    wList = WIDGET_LIST(wBase, $
        VALUE=stylenames, $
        YSIZE=(nstyles+2)<20)

    wExc = WIDGET_BASE(wBase, /EXCLUSIVE, $
        SPACE=0, XPAD=2, YPAD=0)
    wSelected = WIDGET_BUTTON(wExc, VALUE=IDLitLangCatQuery('UI:wdStyleApply:ApSelected'), $
        SENSITIVE=(nsel ne 0))
    wApplyView = WIDGET_BUTTON(wExc, VALUE=IDLitLangCatQuery('UI:wdStyleApply:ApView'))
    wApplyAll = WIDGET_BUTTON(wExc, VALUE=IDLitLangCatQuery('UI:wdStyleApply:ApAll'))

    WIDGET_CONTROL, (nsel gt 0) ? wSelected : wApplyView, /SET_BUTTON

    wNonExc = WIDGET_BASE(wBase, /NONEXCLUSIVE, $
        SPACE=0, XPAD=2, YPAD=0)
    wCurrent = WIDGET_BUTTON(wNonExc, VALUE=IDLitLangCatQuery('UI:wdStyleApply:UpdateTool'))
    if (KEYWORD_SET(updateCurrent)) then $
        WIDGET_CONTROL, wCurrent, /SET_BUTTON

    xsize = 250 > (WIDGET_INFO(wBase, /GEOM)).scr_xsize
    wButtons = WIDGET_BASE(wBase, COLUMN=2, /GRID, $
        SPACE=0, XPAD=2, YPAD=2, $
        SCR_XSIZE=xsize - 5)

    w1 = WIDGET_BASE(wButtons, /ALIGN_LEFT, XPAD=0, YPAD=0)

    wHelp = WIDGET_BUTTON(w1, $
                          VALUE=IDLitLangCatQuery('UI:wdStyleApply:Help'), $
                          UNAME='HELP')

    w2 = WIDGET_BASE(wButtons, /ALIGN_RIGHT, /ROW, /GRID, $
        SPACE=5, XPAD=0, YPAD=0)

    wOK = WIDGET_BUTTON(w2, VALUE=IDLitLangCatQuery('UI:OK'), uname='OK')

    wCancel = WIDGET_BUTTON(w2, VALUE=IDLitLangCatQuery('UI:CancelPad'), $
        UNAME='CANCEL')

    WIDGET_CONTROL, wBase, CANCEL_BUTTON=wCancel, $
        DEFAULT_BUTTON=wOK


    state = { $
        oSys: oSys, $
        wList: wList, $
        wExc: wExc, $
        wSelected: wSelected, $
        wApplyView: wApplyView, $
        wApplyAll: wApplyAll, $
        wCurrent: wCurrent, $
        select: -1, $
        apply: 0b, $
        updateCurrent: 0b $
        }
    pState = PTR_NEW(state)
    WIDGET_CONTROL, wBase, /REALIZE, SET_UVALUE=pState
    WIDGET_CONTROL, wList, SET_LIST_SELECT=match

    ; Fire up the xmanager.
    XMANAGER, "IDLitwdStyleApply", wBase,  /NO_BLOCK

    styleName = ((*pState).select ge 0) ? $
        stylenames[(*pState).select] : ''
    apply = (*pState).apply
    updateCurrent = (*pState).updateCurrent

    PTR_FREE, pState

    return, (styleName ne '')

end

