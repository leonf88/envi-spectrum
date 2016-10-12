; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdunknowndata.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdUnknownData
;
; PURPOSE:
;   This function implements the Unknown Data dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdUnknownData()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003.
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro IDLitwdUnknownData_help, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    oTool = (*pState).oTool
    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return
    oHelp->HelpTopic, oTool, 'iToolsUnknownData'

end


;-------------------------------------------------------------------------
pro IDLitwdUnknownData_method, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.handler, GET_UVALUE=pState

    w1 = WIDGET_INFO(event.handler, /CHILD)
    i = 1  ; first button

    while WIDGET_INFO(w1, /VALID) do begin
        if (WIDGET_INFO(w1, /BUTTON_SET)) then begin
            (*pState).method = i
            break
        endif
        i++
        w1 = WIDGET_INFO(w1, /SIBLING)
    endwhile

end


;-------------------------------------------------------------------------
pro IDLitwdUnknownData_1_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    wBase = WIDGET_BASE(id, /ROW, XPAD=0, YPAD=0, SPACE=0)

    status = IDLitGetResource("MENU", background, /COLOR)

    wMain = WIDGET_BASE(wBase, /COLUMN, XPAD=50, YPAD=50, SPACE=20)

    wText = WIDGET_BASE(wMain, /COLUMN)
    ; Cannot guarantee the existence of fonts on Motif.
    if (!version.os_family eq 'Windows') then $
        font = 'Helvetica*18'
    wLabel = WIDGET_LABEL(wText, /ALIGN_LEFT, $
        FONT=font, $
        VALUE=IDLitLangCatQuery('UI:wdUnknownData:Prompt1'))
    wLabel = WIDGET_LABEL(wText, /ALIGN_LEFT, $
        FONT=font, $
        VALUE=IDLitLangCatQuery('UI:wdUnknownData:Prompt2'))

    wButtonBase = WIDGET_BASE(wMain, /COLUMN, /EXCLUSIVE, $
        EVENT_PRO='IDLitwdUnknownData_method', $
        UVALUE=pState)

    nButton = 3
    wButtons = LONARR(nButton)
    wButtons[0] = WIDGET_BUTTON(wButtonBase, $
        FONT=font, $
        VALUE=IDLitLangCatQuery('UI:wdUnknownData:Opt1'))
    wButtons[1] = WIDGET_BUTTON(wButtonBase, $
        FONT=font, $
        VALUE=IDLitLangCatQuery('UI:wdUnknownData:Opt2'))
    wButtons[2] = WIDGET_BUTTON(wButtonBase, $
        FONT=font, $
        VALUE=IDLitLangCatQuery('UI:wdUnknownData:Opt3'))

    if ((*pState).method le nButton) then $
        WIDGET_CONTROL, wButtons[((*pState).method-1) > 0], /SET_BUTTON

end


;-------------------------------------------------------------------------
function IDLitwdUnknownData_1_destroy, id, bNext

    compile_opt idl2, hidden

    ; do nothing
    return,1
end


;-------------------------------------------------------------------------
function IDLitwdUnknownData, oUI, $
    GROUP_LEADER=groupLeader, $
    METHOD=methodIn

    compile_opt idl2, hidden

    ON_ERROR, 2

    xsize = 600
    ysize = 400
    method = N_ELEMENTS(methodIn) ? (methodIn[0] > 1) : 1
    pState = PTR_NEW( $
        {METHOD: method, $
        oTool: oUI->GetTool()} $
        )

    success = DIALOG_WIZARD('IDLitwdUnknownData_' + ['1'], $
        GROUP_LEADER=groupLeader, $
        HELP_PRO='IDLitwdUnknownData_help', $
        TITLE=IDLitLangCatQuery('UI:wdUnknownData:Title'), $
        UVALUE=pState, $
        SPACE=0, XPAD=0, YPAD=0, $
        XSIZE=xsize, YSIZE=ysize)

    result = success ? (*pState).method : 0
    PTR_FREE, pState

    return, result
end
