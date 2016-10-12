; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdpaletteeditor.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdPaletteEditor
;
; PURPOSE:
;   This function implements the Palette Editor dialog.
;
; CALLING SEQUENCE:
;   IDLitwdPaletteEditor, oUI
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:
;   Modified:
;
;-
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
; The OK button says we're done and we need to return results.
;
; Get the palette data from the palette editor compound widget.
;
pro IDLitwdPaletteEditor_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Cache the results in the pointer so we can access them.
    WIDGET_CONTROL, state.wPaletteEditor, GET_VALUE=palette
    *state.pResult = { $
        PALETTE: palette $
        }

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
; Cancel dialog and don't return results.
;
pro IDLitwdPaletteEditor_cancel, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Restore original palette.
    state.oTarget->SetProperty, VISUALIZATION_PALETTE=state.origPalette
    
    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end

;-------------------------------------------------------------------------
; Palette Editor Event Handler
;
pro IDLitwdPaletteEditor_event, event

    compile_opt idl2, hidden

    ; Manually destroy our widget to prevents flashing on Windows platforms.
    if (TAG_NAMES(event, /STRUCT) eq 'WIDGET_KILL_REQUEST') then begin
        WIDGET_CONTROL, event.id, /DESTROY
        return
    endif

    if (TAG_NAMES(event, /STRUCT) eq 'CW_PALETTE_EDITOR_PM') then begin
        child = WIDGET_INFO(event.top, /CHILD)
        WIDGET_CONTROL, child, GET_UVALUE=state
        WIDGET_CONTROL, state.wPaletteEditor, GET_VALUE=palette
        state.oTarget->SetProperty, VISUALIZATION_PALETTE=palette
    endif

end


;-------------------------------------------------------------------------
;
function IDLitwdPaletteEditor, oUI, $
        oRequester, $
        PALETTE=palette, $
        GROUP_LEADER=groupLeaderIn, $
        SHOW_DIALOG=showdialogIn, $
        TITLE=titleIn, $
        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdPaletteEditor'

    ; Default for SHOW_DIALOG is "True"
    showdialog = (N_ELEMENTS(showdialogIn) gt 0) ? $
        KEYWORD_SET(showdialogIn) : 1

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdOpPalEdit:Title')

    ; Is there a group leader, or do we create our own?
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(groupLeader, /VALID)


    ; We are doing this modal for now.
    if (not hasLeader) then begin
        wDummy = WIDGET_BASE(MAP=0)
        groupLeader = wDummy
        hasLeader = 1
    endif

    ; Create our floating base.
    wBase = WIDGET_BASE( $
        /COLUMN, $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, /MODAL, $
        EVENT_PRO=myname+'_event', $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        /TLB_KILL_REQUEST_EVENTS, $
        _EXTRA=_extra)


    wPaletteEditor = CW_PALETTE_EDITOR(wBase, DATA=palette)


    wButtons = WIDGET_BASE(wBase, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    ;; OK button
    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    ;; Cancel Button
    wCancel = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_cancel', VALUE=IDLitLangCatQuery('UI:CancelPad2'))

    WIDGET_CONTROL, wBase, /REALIZE

    ; Cache my state information within my child.
    state = { $
        wBase: wBase, $
        wPaletteEditor: wPaletteEditor, $
        oTarget: oRequester, $
        origPalette: palette, $
        pResult: PTR_NEW(/ALLOC)}

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        NO_BLOCK=0

    ; Destroy fake top-level base if we created it.
    if (N_ELEMENTS(wDummy)) then $
        WIDGET_CONTROL, wDummy, /DESTROY

    result = (N_ELEMENTS(*state.pResult)) ? *state.pResult : 0
    PTR_FREE, state.pResult

    return, result
end

