; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwddatabottomtop.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdDataBottomTop
;
; PURPOSE:
;   This function implements the data bottom/top dialog.
;
; CALLING SEQUENCE:
;   IDLitwdDataBottomTop, oUI
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
; Copy the results we've accumulated from the CW_DATALEVEL events
; into a result structure to be returned to the caller UI object.
;
pro IDLitwdDataBottomTop_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Cache the results in the pointer so we can access them.
    *state.pResult = { $
                       DATA_BOTTOM: ((state.nData gt 1)   ? $
                                     REFORM(state.dataBotTop[0, *]) : $
                                     state.dataBotTop[0,0]), $
                       DATA_TOP: ((state.nData gt 1)      ? $
                                  REFORM(state.dataBotTop[1, *]) : $
                                  state.dataBotTop[1,0]), $
                       DATA_RANGE: state.dataMinMax $
                     }

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
; Cancel dialog and don't return results.
;
pro IDLitwdDataBottomTop_cancel, event

    compile_opt idl2, hidden

    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end

;-------------------------------------------------------------------------
; Handle CW_ITDATALEVEL events by copying data from the event into
; our state.
;
; Eventually, we'll pass this back to the caller when the OK button
; is pressed.
;
pro IDLitwdDataBottomTop_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else: begin
            ; In the case that the event structure is unnamed, key off of
            ; widget id.
            if (event.id eq state.wDataLevel) then begin
                ;; Except for motion events, cache event values for later
                ;; return (i.e., when the OK button is pressed).
                if not event.motion then begin
                    state.dataBotTop = event.level_values
                    state.dataMinMax = event.min_max
                    WIDGET_CONTROL, child, SET_UVALUE=state
                endif
            endif
        end
    endcase

end


;-------------------------------------------------------------------------
;
function IDLitwdDataBottomTop, oUI, $
                               DATA_BOTTOM=dataBottom, $
                               DATA_TOP=dataTop, $
                               DATA_RANGE=dataRange, $
                               ODATA=oData, $
                               EXTENDABLE_RANGES=extendRanges, $
                               GROUP_LEADER=groupLeaderIn, $
                               SHOW_DIALOG=showdialogIn, $
                               TITLE=titleIn, $
                               _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdDataBottomTop'

    ; Default for SHOW_DIALOG is "True"
    showdialog = (N_ELEMENTS(showdialogIn) gt 0) ? $
        KEYWORD_SET(showdialogIn) : 1

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdDataBT:Title')

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

    ;; Prepare initial values
    nData = N_ELEMENTS(oData)
    initialValues = DBLARR(2, nData)
    for iData=0, nData-1 do begin
        initialValues[0, iData] = dataBottom[iData]
        initialValues[1, iData] = dataTop[iData]
    endfor

    ;; Create interactive data level compound widget.
    wDataLevel = CW_ITMULTIDATALEVEL(wBase, oUI, $
                                     DATA_OBJECTS=oData, $
                                     LEVEL_VALUES=initialValues, $
                                     DATA_RANGE=dataRange, $
                                     EXTENDABLE_RANGES= $
                                     keyword_set(extendRanges), $
                                     LEVEL_NAMES=levelNames, $
                                     NLEVELS=2)

    if wDataLevel eq 0 then return, 0
    ;; Show next time.
    if N_ELEMENTS(showdialogIn) gt 0 then begin
        wNonexc = WIDGET_BASE(wBase, /NONEXCLUSIVE, $
            SPACE=0, XPAD=0, YPAD=0)
        wShowDialog = WIDGET_BUTTON(wNonexc, $
                                    VALUE=IDLitLangCatQuery('UI:ShowDialog'))
        if (KEYWORD_SET(showdialog)) then $
            WIDGET_CONTROL, wShowDialog, /SET_BUTTON
    endif else $
        wShowDialog = 0

    wButtons = WIDGET_BASE(wBase, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    ;; OK button
    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    ;; Cancel Button
    wCancel = WIDGET_BUTTON(wButtons, $
                            EVENT_PRO=myname+'_cancel', $
                            VALUE=IDLitLangCatQuery('UI:CancelPad2'))

    WIDGET_CONTROL, wBase, /REALIZE

    ; Cache my state information within my child.
    state = { $
        wBase: wBase, $
        wShowDialog: wShowDialog, $
        wDataLevel: wDataLevel, $
        nData: nData, $
        dataBotTop: initialValues, $
        dataMinMax: [0.0d,0], $
        pResult: PTR_NEW(/ALLOC)}

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        NO_BLOCK=0, EVENT_HANDLER=myname+'_event'

    ; Destroy fake top-level base if we created it.
    if (N_ELEMENTS(wDummy)) then $
        WIDGET_CONTROL, wDummy, /DESTROY

    result = (N_ELEMENTS(*state.pResult)) ? *state.pResult : 0
    PTR_FREE, state.pResult

    return, result
end

