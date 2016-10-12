; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdsubvolume.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdSubVolume
;
; PURPOSE:
;   This function implements the widget dialog for allowing the user
;   to select a subvolume rendering range for a volume.
;
; CALLING SEQUENCE:
;   IDLitwdSubVolume, oUI
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
; into a result structure to be returned to the UI object.
;
pro IDLitwdSubVolume_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Cache the results in the pointer so we can access them.
    *state.pResult = { $
        SUBVOLUME: state.subvolume $
        }

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
; Cancel dialog and don't return results.
;
pro IDLitwdSubVolume_cancel, event

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
pro IDLitwdSubVolume_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else: begin
                case event.id of
                state.wXDataLevel: begin
                    state.subvolume[0] = event.level_values[0]
                    state.subvolume[3] = event.level_values[1]
                end
                state.wYDataLevel: begin
                    state.subvolume[1] = event.level_values[0]
                    state.subvolume[4] = event.level_values[1]
                end
                state.wZDataLevel: begin
                    state.subvolume[2] = event.level_values[0]
                    state.subvolume[5] = event.level_values[1]
                end
                endcase
                WIDGET_CONTROL, child, SET_UVALUE=state
        end
    endcase
end


;-------------------------------------------------------------------------
;
function IDLitwdSubVolume, oUI, $
        DATA_OBJECTS=oData, $
        NLEVELS=nlevels, $
        SUBVOLUME=subvolume, $
        GROUP_LEADER=groupLeaderIn, $
        TITLE=titleIn, $
        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdSubVolume'

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdSubVol:Title')

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


    ;; Prepare initial values.
    xInitialValues = [subvolume[0], subvolume[3]]
    yInitialValues = [subvolume[1], subvolume[4]]
    zInitialValues = [subvolume[2], subvolume[5]]

    ;; The data for the DATALEVEL widget is not the volume,
    ;; but instead is the volume extents.
    ;; Need to create three temp data objects for using the
    ;; DATALEVEL widget.
    if ~OBJ_VALID(oData[0]) then return, 0
    success = oData[0]->GetData(data)
    if success eq 0 then return, 0
    dims = SIZE(data, /DIMENSIONS)
    if N_ELEMENTS(dims) ne 3 then return, 0
    oXData = OBJ_NEW('IDLitDataIDLVector', [0,dims[0]-1])
    oYData = OBJ_NEW('IDLitDataIDLVector', [0,dims[1]-1])
    oZData = OBJ_NEW('IDLitDataIDLVector', [0,dims[2]-1])

    ;; Create interactive data level compound widgets.
    wBaseX = WIDGET_BASE(wBase, /COL, /FRAME)
    w = WIDGET_LABEL(wBaseX, VALUE=IDLitLangCatQuery('UI:wdSubVol:VolX'))
    wXDataLevel = CW_ITDATALEVEL(wBaseX, oUI, $
        DATA_OBJECT=oXData, $
        INITIAL_VALUES=xInitialValues, $
        NO_HISTOGRAM=1, $
        YSIZE=50, $
        NLEVELS=nlevels)

    wBaseY = WIDGET_BASE(wBase, /COL, /FRAME)
    w = WIDGET_LABEL(wBaseY, VALUE=IDLitLangCatQuery('UI:wdSubVol:VolY'))
    wYDataLevel = CW_ITDATALEVEL(wBaseY, oUI, $
        DATA_OBJECT=oYData, $
        INITIAL_VALUES=yInitialValues, $
        NO_HISTOGRAM=1, $
        YSIZE=50, $
        NLEVELS=nlevels)

    wBaseZ = WIDGET_BASE(wBase, /COL, /FRAME)
    w = WIDGET_LABEL(wBaseZ, VALUE=IDLitLangCatQuery('UI:wdSubVol:VolZ'))
    wZDataLevel = CW_ITDATALEVEL(wBaseZ, oUI, $
        DATA_OBJECT=oZData, $
        INITIAL_VALUES=zInitialValues, $
        NO_HISTOGRAM=1, $
        YSIZE=50, $
        NLEVELS=nlevels)

    wButtons = WIDGET_BASE(wBase, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    ;; OK button
    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    ;; Cancel Button
    wCancel = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_cancel', VALUE=IDLitLangCatQuery('UI:CancelPad2'))

    WIDGET_CONTROL, wBase, /REALIZE

    ;; Build state struct
    state = { $
        wBase: wBase, $
        wXDataLevel: wXDataLevel, $
        wYDataLevel: wYDataLevel, $
        wZDataLevel: wZDataLevel, $
        nlevels: nlevels, $
        subvolume: subvolume, $
        pResult: PTR_NEW(/ALLOC)}

    ;; Copy initial values to state in case the event
    ;; handler never fires.
    WIDGET_CONTROL, wXDataLevel, GET_VALUE=datalevel
    state.subvolume[0] = datalevel.level_values[0]
    state.subvolume[3] = datalevel.level_values[1]
    WIDGET_CONTROL, wYDataLevel, GET_VALUE=datalevel
    state.subvolume[1] = datalevel.level_values[0]
    state.subvolume[4] = datalevel.level_values[1]
    WIDGET_CONTROL, wZDataLevel, GET_VALUE=datalevel
    state.subvolume[2] = datalevel.level_values[0]
    state.subvolume[5] = datalevel.level_values[1]

    ;; Cache my state information within my child.
    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    ;; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        NO_BLOCK=0, EVENT_HANDLER=myname+'_event'

    ;; Destroy fake top-level base if we created it.
    if (N_ELEMENTS(wDummy)) then $
        WIDGET_CONTROL, wDummy, /DESTROY

    result = (N_ELEMENTS(*state.pResult)) ? *state.pResult : 0
    PTR_FREE, state.pResult
    OBJ_DESTROY, [oXData, oYData, oZData]
    return, result
end

