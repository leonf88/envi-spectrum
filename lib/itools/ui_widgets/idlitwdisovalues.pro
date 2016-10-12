; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdisovalues.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdIsovalues
;
; PURPOSE:
;   This function implements the widget dialog for allowing the user
;   to select isovalues associated with a volume.  These isovalues
;   are then used, for example, to create or modify isosurfaces.
;
; CALLING SEQUENCE:
;   IDLitwdIsovalues, oUI
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   OVOLVIS - an IDLitVisVolume object
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
; into a result structure to be returned to the isosurface UI object.
;
pro IDLitwdIsovalues_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    if state.wShowDialog ne 0 then $
        showdialog = WIDGET_INFO(state.wShowDialog, /BUTTON_SET) $
    else $
        showdialog = 0

    if state.wDecimate ne 0 then begin
        WIDGET_CONTROL, state.wDecimate, GET_VALUE=decimate
    endif else begin
        decimate = 100
    endelse

    ; Cache the results in the pointer so we can access them.
    *state.pResult = { $
        SELECTED_DATASET:state.selectedDataset, $
        ISO0:state.iso0, $
        ISO1:state.iso1, $
        ISO2:state.iso2, $
        ISO3:state.iso3, $
        DECIMATE: BYTE(decimate), $
        SHOW_DIALOG: BYTE(showdialog) $
        }

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
; Cancel dialog and don't return results.
;
pro IDLitwdIsovalues_cancel, event

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
pro IDLitwdIsovalues_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else: begin
            ; In the case that the event structure is unnamed, key off of
            ; widget id.
            if (event.id eq state.wDataLevel) then begin
                ;; Except for motion events, cache event values for
                ;; later return (i.e., when the OK button is pressed).
                if not event.motion then begin
                    if state.nData gt 0 then begin
                        state.iso0 = event.level_values[0:state.nlevels-1,0]
                        if state.nData gt 1 then begin
                            state.iso1 = event.level_values[0:state.nlevels-1,1]
                            if state.nData gt 2 then begin
                                state.iso2 = event.level_values[0:state.nlevels-1,2]
                                if state.nData gt 3 then $
                                    state.iso3 = event.level_values[0:state.nlevels-1,3]
                            endif
                        endif
                    endif
                    state.selectedDataset = event.data_id
                endif
                WIDGET_CONTROL, child, SET_UVALUE=state
            endif
        end
    endcase
end


;-------------------------------------------------------------------------
;
function IDLitwdIsovalues, oUI, $
        DATA_OBJECTS=oData, $
        PALETTE_OBJECTS=oPalettes, $
        DECIMATE=decimate, $
        NLEVELS=nlevels, $
        ISOVALUES=isovalues, $
        USE_ISOVALUES=useIsovalues, $
        GROUP_LEADER=groupLeaderIn, $
        SHOW_DIALOG=showdialogIn, $
        TITLE=titleIn, $
        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdIsovalues'

    ; Default for SHOW_DIALOG is "True"
    showdialog = (N_ELEMENTS(showdialogIn) gt 0) ? $
        KEYWORD_SET(showdialogIn) : 1

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdIsoVal:Title')

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

    ;; Prepare initial values if requested
    nData = N_ELEMENTS(oData)
    if ((nData gt 0) and useIsovalues) then $
        isovals = isovalues[*, 0:nData-1]

    ;; Create interactive data level compound widget.
    wDataLevel = CW_ITMULTIDATALEVEL(wBase, oUI, $
        DATA_OBJECTS=oData, $
        PALETTE_OBJECTS=oPalettes, $
        LEVEL_VALUES=isovals, $
        NLEVELS=nlevels)

    if wDataLevel eq 0 then return, 0
    ;; Decimate
    if N_ELEMENTS(decimate) gt 0 then begin
        wDecBase = WIDGET_BASE(wBase, /COL, /FRAME, /ALIGN_CENTER)
        wDecimate = WIDGET_SLIDER(wDecBase, VALUE=100, $
            TITLE=IDLitLangCatQuery('UI:wdIsoVal:Decimate'))
    endif $
    else wDecimate = 0

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
        EVENT_PRO=myname+'_cancel', VALUE=IDLitLangCatQuery('UI:CancelPad2'))

    WIDGET_CONTROL, wBase, /REALIZE

    ; Cache my state information within my child.
    state = { $
        wBase: wBase, $
        wShowDialog: wShowDialog, $
        wDataLevel: wDataLevel, $
        wDecimate: wDecimate, $
        selectedDataset: 0, $
        nlevels: nlevels, $
        nData: 0, $
        iso0: DBLARR(nlevels), $
        iso1: DBLARR(nlevels), $
        iso2: DBLARR(nlevels), $
        iso3: DBLARR(nlevels), $
        pResult: PTR_NEW(/ALLOC)}


    ; Store initial values.
    WIDGET_CONTROL, wDataLevel, GET_VALUE=datalevel
    nData = N_ELEMENTS(datalevel.data_objects)
    state.nData = nData
    if (nData) gt 0 then begin
        state.iso0 = datalevel.level_values[*,0]
        if (nData) gt 1 then begin
            state.iso1 = datalevel.level_values[*,1]
            if (nData) gt 2 then begin
               state.iso2 = datalevel.level_values[*,2]
               if (nData) gt 3 then $
                   state.iso3 = datalevel.level_values[*,3]
            endif
        endif
    endif

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

