; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdcontrolmacro.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the Control Macro dialog.
;
; Written by: AY, RSI, 2003.
; Modified:
;
;-


;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_pause, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; get the initial state of this property
    state.oRequestor->GetProperty, PAUSE_MACRO=previousPauseState

    ; flip the pause/continue state
    newPauseState = ~previousPauseState
    state.oRequestor->SetProperty, PAUSE_MACRO=newPauseState
    widget_control, state.wPause, set_value=(newPauseState ? $
        FILEPATH('shift_right.bmp', SUBDIR=['resource','bitmaps']) : $
        FILEPATH('pause.bmp', SUBDIR=['resource','bitmaps'])), $
        /BITMAP, $
        TOOLTIP=(newPauseState ? $
                 IDLitLangCatQuery('UI:wdCtrlMacro:Continue') : $
                 IDLitLangCatQuery('UI:wdCtrlMacro:Pause'))
    widget_control, state.wStep, sensitive=newPauseState

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end

;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_step, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state
    state.oRequestor->SetProperty, /STEP_MACRO

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end

;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_delay, event

    compile_opt idl2, hidden

    ; delay is in floating base, need to retrieve wBase first
    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=wBase
    child = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state
    state.oRequestor->SetProperty, STEP_DELAY=event.value

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end

;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_stop, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state
    ; don't destroy tlb here.  macro service will request it.
    state.oRequestor->SetProperty, /STOP_MACRO

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end


;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_displayButton, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; get the initial state of this property
    state.oRequestor->GetProperty, DISPLAY_STEPS=previousDisplaySteps

    ; flip the display steps state
    newDisplaySteps = ~previousDisplaySteps
    state.oRequestor->SetProperty, DISPLAY_STEPS=newDisplaySteps
    widget_control, state.wDisplayButton, set_value=(newDisplaySteps ? $
        FILEPATH('eye_closed.bmp', SUBDIR=['resource','bitmaps']) : $
        FILEPATH('image.bmp', SUBDIR=['resource','bitmaps'])), $
        /BITMAP, $
        TOOLTIP=(newDisplaySteps ? $
                 IDLitLangCatQuery('UI:wdCtrlMacro:HideSteps') : $
                 IDLitLangCatQuery('UI:wdCtrlMacro:DispSteps'))

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end


;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_delayButton, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state
    geomMainBase = WIDGET_INFO(state.wBase, /GEOM)
    geomDelayBase = WIDGET_INFO(state.wDelayBase, /GEOM)
    widget_control, state.wDelayBase, $
        TLB_SET_XOFFSET=geomMainBase.xoffset, $
        TLB_SET_YOFFSET=geomMainBase.yoffset - geomDelayBase.scr_ysize
    widget_control, state.wDelayBase, /MAP

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end


;-------------------------------------------------------------------------
; MUST be a function to return the event to widget_event
function IDLitwdControlMacro_showTree, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; get the initial state of this property
    state.oRequestor->GetProperty, PAUSE_MACRO=previousPauseState


    ; flip the show/hide state of the tree
    newTreeShown = ~state.treeShown
    widget_control, state.wShowTree, set_value=(newTreeShown ? $
        FILEPATH('shift_up.bmp', SUBDIR=['resource','bitmaps']) : $
        FILEPATH('shift_down.bmp', SUBDIR=['resource','bitmaps'])), $
        /BITMAP, $
        TOOLTIP=(newTreeShown ? $
                 IDLitLangCatQuery('UI:wdCtrlMacro:HideItems') : $
                 IDLitLangCatQuery('UI:wdCtrlMacro:ShowItems'))
    widget_control, state.wTree, MAP = newTreeShown
    widget_control, state.wBase, $
        SCR_XSIZE=(newTreeShown ? state.scrXsizeWithTree : $
            state.scrXsizeNoTree), $
        SCR_YSIZE=(newTreeShown ? state.scrYsizeWithTree : $
            state.scrYsizeNoTree)

    state.treeShown = newTreeShown
    WIDGET_CONTROL, child, SET_UVALUE=state

    ; we must return from this to the caller
    ; in order to break out of the loop over macro items
    return, event
end

;-------------------------------------------------------------------------

pro IDLitwdControlMacro_checkEvents, wBase

    if (~N_ELEMENTS(wBase) || ~widget_info(wBase, /VALID)) then return

    ; check for events on the control base
    child = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; clear the flag that initiated this action
    state.oRequestor->SetProperty, CHECK_EVENTS=0

    ; check for events on the controls base
    result = widget_event(state.wBase, /NOWAIT)
    ; check for events on the step delay base
    result = widget_event(state.wDelayBase, /NOWAIT)


end


;-------------------------------------------------------------------------

; when the macro controls are displayed, all tools and non-modal
; dialogs must be desensitized to prevent menu actions
; from being queued.  when a macro completes execution and the
; control dialog is dismissed, all the widgets must be re-sensitized.
pro IDLitwdControlMacro_setAllToolSensitivity, oUI, value

    if obj_valid(oUI) then begin
        oTool = oUI->GetTool()
        oSys = oTool->_GetSystem()
    endif else begin
        oSys = _IDLitSys_GetSystem()
    endelse
    oSys->DoOnNotify, oSys->GetFullIdentifier(), $
        'SENSITIVE', value
end

;-------------------------------------------------------------------------

pro IDLitwdControlMacro_destroyControls, wBase

    if (~N_ELEMENTS(wBase) || ~widget_info(wBase, /VALID)) then begin
        IDLitwdControlMacro_setAllToolSensitivity, obj_new(), 1
        return
    endif

    child = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; clear the flag that initiated this action
    state.oRequestor->SetProperty, DESTROY_CONTROLS=0

    state.oRequestor->SetProperty, $
        DISPLAY_CONTROLS=0

    ; re-enable widgets prior to destroying controls to prevent
    ; IDE from being refreshed and causing flashing of the
    ; tool window
    IDLitwdControlMacro_setAllToolSensitivity, state.oUI, 1

    widget_control, wBase, /DESTROY

end


;-------------------------------------------------------------------------
forward_function cw_ittreeview_getSelect, cw_ittreeview_getParent

pro IDLitwdControlMacro_refreshTree, wBase

    if (~N_ELEMENTS(wBase) || ~widget_info(wBase, /VALID)) then return

    child = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; clear the flag that initiated this action
    state.oRequestor->SetProperty, REFRESH_TREE=0

    state.oRequestor->GetProperty, CURRENT_MACRO_ID=CurrentMacroID
    oSys = state.oUI->GetTool()

    idTop = cw_ittreeview_getSelect(state.wTree, COUNT=nSel)
    idCurrent = cw_ittreeview_getParent(state.wTree, idTop[0])
    while idCurrent ne '' do begin
        idTop = idCurrent
        idCurrent = cw_ittreeview_getParent(state.wTree, idCurrent)
    endwhile
    WIDGET_CONTROL, state.wTree, GET_UVALUE=treeState
    wLevel = widget_info(state.wTree, find_by_uname=STRUPCASE(idTop))
    idExpanded=''
    cw_ittreeview_DestroyItem, treeState, wLevel, idExpanded

    oCurrentMacro = oSys->GetByIdentifier(CurrentMacroID)
    cw_ittreeview_addLevel, state.wTree, oCurrentMacro, state.wTree, /EXPANDED

end
;-------------------------------------------------------------------------
pro IDLitwdControlMacro_setCurrentItem, wBase, currentItem

    if (~N_ELEMENTS(wBase) || ~widget_info(wBase, /VALID)) then return

    child = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; clear the flag that initiated this action
    state.oRequestor->SetProperty, SET_CURRENT_ITEM=0

    ; update the state of the display/hide steps button
    ; this could change because we may have processed a step
    ; display change operation.
    state.oRequestor->GetProperty, DISPLAY_STEPS=newDisplaySteps
    widget_control, state.wDisplayButton, set_value=(newDisplaySteps ? $
        FILEPATH('eye_closed.bmp', SUBDIR=['resource','bitmaps']) : $
        FILEPATH('image.bmp', SUBDIR=['resource','bitmaps'])), $
        /BITMAP, $
        TOOLTIP=(newDisplaySteps ? $
                 IDLitLangCatQuery('UI:wdCtrlMacro:HideSteps') : $
                 IDLitLangCatQuery('UI:wdCtrlMacro:DispSteps'))
    if (widget_info(state.wTree, /VALID)) then begin
        state.oRequestor->GetProperty, CURRENT_ITEM=currentItem
        cw_ittreeview_setSelect, state.wTree, currentItem;, /CLEAR
    endif

end



;-------------------------------------------------------------------------
pro IDLitwdControlMacroDelayBase_event, event

    compile_opt idl2, hidden

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': widget_control, event.top, MAP=0

        else:

    endcase

end


;-------------------------------------------------------------------------
pro IDLitwdControlMacro_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': ; NO-OP

        else:

    endcase

end


;-------------------------------------------------------------------------
; Purpose:
;   Create the Control Macro widget.
;
; Result:
;
; Arguments:
;   oRequestor - The requesting object.
;
; Keywords:
;   GROUP_LEADER: Set this to the widget ID of the group leader.
;
;   TITLE: Set this to a string giving the window title.
;
;   All other keywords are passed to the top-level widget base.
;
pro IDLitwdControlMacro, oUI, oRequestor, $
    GROUP_LEADER=groupLeaderIn, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    common IDLitwdControlMacro_common, wBase

    myname = 'IDLitwdControlMacro'

    ; check for events
    oRequestor->GetProperty, $
        CHECK_EVENTS=checkEvents, $
        DISPLAY_STEPS=displaySteps, $
        SET_CURRENT_ITEM=setCurrentItem, $
        DESTROY_CONTROLS=destroyControls, $
        REFRESH_TREE=refreshTree, $
        PAUSE_MACRO=currentPauseState, $
        STEP_DELAY=stepDelay

    if checkEvents then begin
        IDLitwdControlMacro_checkEvents, wBase
        return
    endif

    if setCurrentItem then begin
        IDLitwdControlMacro_setCurrentItem, wBase
        return
    endif

    if destroyControls then begin
        IDLitwdControlMacro_destroyControls, wBase
        return
    endif

    if refreshTree then begin
        IDLitwdControlMacro_refreshTree, wBase
        return
    endif

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        'Macro Controls'


    ; Is there a group leader, or do we create our own?
    wGroupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(wGroupLeader, /VALID)


    if (not hasLeader) then begin
        wDummy = WIDGET_BASE(MAP=0)
        wGroupLeader = wDummy
        hasLeader = 1
    endif

    if n_elements(wBase) gt 0 && $
        widget_info(wBase, /VALID) then begin
        child = WIDGET_INFO(wBase, /CHILD)
        WIDGET_CONTROL, child, GET_UVALUE=state
        widget_control, state.wDelay, set_value=stepDelay
        widget_control, state.wPause, set_value=(currentPauseState ? $
            FILEPATH('shift_right.bmp', SUBDIR=['resource','bitmaps']) : $
            FILEPATH('pause.bmp', SUBDIR=['resource','bitmaps'])), $
            /BITMAP, $
            TOOLTIP=(currentPauseState ? $
                     IDLitLangCatQuery('UI:wdCtrlMacro:Continue') : $
                     IDLitLangCatQuery('UI:wdCtrlMacro:Pause'))
        widget_control, state.wStep, sensitive=currentPauseState

        IDLitwdControlMacro_refreshTree, wBase
        return
    endif


    ; Create our floating base.
    tlb_noResize = 1
    tlb_noSysMenu = 2
    tlb_noTitleBar = 4
    tlb_noClose = 8
    wBase = WIDGET_BASE( $
        MAP=0, $
        /COLUMN, $
        /TOOLBAR, $
        FLOATING=hasLeader, $
        GROUP_LEADER=wGroupLeader, $
        EVENT_PRO=myname+'_event', $
        SPACE=0, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=tlb_noResize + tlb_noSysMenu + tlb_noClose, $
        /TLB_KILL_REQUEST, $
        _EXTRA=_extra)

    wButtonBase = widget_base(wBase, /ROW, $
        SPACE=0, $
        XPAD=0, YPAD=0, $
        /TOOLBAR)

    wPause = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_pause', $
            TOOLTIP=IDLitLangCatQuery('UI:wdCtrlMacro:Pause'), $
            VALUE=FILEPATH('pause.bmp', SUBDIR=['resource','bitmaps']), $
            /BITMAP, /FLAT, $
            ACCELERATOR='F5')

    wStep = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_step', $
            TOOLTIP=IDLitLangCatQuery('UI:wdCtrlMacro:Step'), $
            VALUE=FILEPATH('step.bmp', SUBDIR=['resource','bitmaps']), $
            /BITMAP, /FLAT, $
            ACCELERATOR='Right', $
            SENSITIVE=currentPauseState)

    wStop = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_stop', $
        TOOLTIP=IDLitLangCatQuery('UI:wdCtrlMacro:Stop'), $
        VALUE=FILEPATH('stop.bmp', SUBDIR=['resource','bitmaps']), $
        /BITMAP, /FLAT)

    wDisplayButton = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_displayButton', $
        TOOLTIP=(displaySteps ? $
                 IDLitLangCatQuery('UI:wdCtrlMacro:HideSteps') : $
                 IDLitLangCatQuery('UI:wdCtrlMacro:DispSteps')), $
        VALUE=(displaySteps ? $
            FILEPATH('eye_closed.bmp', SUBDIR=['resource','bitmaps']) : $
            FILEPATH('image.bmp', SUBDIR=['resource','bitmaps'])), $
        /BITMAP, /FLAT)

    wDelayButton = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_delayButton', $
        TOOLTIP=IDLitLangCatQuery('UI:wdCtrlMacro:SetStepDelay'), $
        VALUE=FILEPATH('hourglass.bmp', SUBDIR=['resource','bitmaps']), $
        /BITMAP, /FLAT)

    treeShown = 0b
    ; put showTree button in its own base so it stays small
    wShowTree = WIDGET_BUTTON(wButtonBase, $
        EVENT_FUNC=myname+'_showTree', $
        TOOLTIP=IDLitLangCatQuery('UI:wdCtrlMacro:ShowItems'), $; treeShown=0b
        VALUE=FILEPATH('shift_down.bmp', SUBDIR=['resource','bitmaps']), $
        /BITMAP, /FLAT)                            ; treeShown = 0b

    ; realize and cache size before adding tree
    WIDGET_CONTROL, wBase, /REALIZE
    geomTop = widget_info(wBase, /GEOMETRY)
    scrXsizeNoTree = geomTop.scr_xsize
    scrYsizeNoTree = geomTop.scr_ysize

    ; floating base for delay
    wDelayBase = WIDGET_BASE( $
        MAP=0, $
        /COLUMN, $
        /TOOLBAR, $
        /FLOATING, $
        GROUP_LEADER=wBase, $
        EVENT_PRO=myname+'DelayBase_event', $
        SPACE=0, $
        XPAD=0, YPAD=0, $
        TITLE=IDLitLangCatQuery('UI:wdCtrlMacro:StepDelay'), $
        TLB_FRAME_ATTR=tlb_noResize, $
        /TLB_KILL_REQUEST)

    wDelay = CW_FSLIDER(wDelayBase, $
        /EDIT, $
        EVENT_FUNC=myname+'_delay', $
        UNAME='DELAY', $
        VALUE=stepDelay, $
        MINIMUM=0.0, $
        MAXIMUM=60.0, $
        SCROLL=0.01)
    WIDGET_CONTROL, wDelayBase, /REALIZE
    ; allow wDelayBase events to retrieve state
    wChild = WIDGET_INFO(wDelayBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=wBase


    oRequestor->GetProperty, CURRENT_MACRO_ID=CurrentMacroID
    ; need a base wrapping tree so that tree can be mapped/unmapped
    ; without unmapping the top level base
    wTreeBase = widget_base(wBase, $
        SPACE=0, $
        XPAD=0, YPAD=0)
    wTree = CW_ITTREEVIEW(wTreeBase, oUI, $
        IDENTIFIER=CurrentMacroID)
    ; since added after realize, set sizes to default
    if !version.os_family eq 'unix' then $
        WIDGET_CONTROL, wTree, XSIZE=200, YSIZE=200

    ; cache size after adding tree
    geomTop = widget_info(wBase, /GEOMETRY)
    scrXsizeWithTree = geomTop.scr_xsize
    scrYsizeWithTree = geomTop.scr_ysize
    if hasLeader then begin
        geomGroupLeader = WIDGET_INFO(wGroupLeader, /GEOM)
        ; base offsets on collapsed dialog
        xoffsetFromLeader = 0 > (geomGroupLeader.scr_xsize - scrXsizeNoTree)
        yoffsetFromLeader = 0 > (geomGroupLeader.scr_ysize - scrYsizeNoTree)
        widget_control, wBase, $
            TLB_SET_XOFFSET=geomGroupLeader.xoffset + xoffsetFromLeader, $
            TLB_SET_YOFFSET=geomGroupLeader.yoffset + yoffsetFromLeader
        geomDelayBase = WIDGET_INFO(wDelayBase, /GEOM)
        widget_control, wDelayBase, $
            TLB_SET_XOFFSET=geomGroupLeader.xoffset + xoffsetFromLeader, $
            TLB_SET_YOFFSET=geomGroupLeader.yoffset + yoffsetFromLeader - geomDelayBase.scr_ysize

        ; desensitize widgets to prevent menu actions during playback
        IDLitwdControlMacro_setAllToolSensitivity, oUI, 0

    endif

    ; start out with tree hidden
    widget_control, wBase, $
        SCR_XSIZE=(treeShown ? scrXsizeWithTree : scrXsizeNoTree), $
        SCR_YSIZE=(treeShown ? scrYsizeWithTree : scrYsizeNoTree)
    widget_control, wTree, MAP=0

    ; now can map tlb
    widget_control, wBase, /MAP

    ; Cache my state information within my child.
    state = { $
        oUI: oUI, $
        oRequestor: oRequestor, $
        wGroupLeader: wGroupLeader, $
        wBase: wBase, $
        wPause:wPause, $
        wStep:wStep, $
        wDelayBase:wDelayBase, $
        wDelay:wDelay, $
        wStop:wStop, $
        wDisplayButton:wDisplayButton, $
        wTree:wTree, $
        wShowTree:wShowTree, $
        treeShown: treeShown, $
        scrXsizeNoTree:scrXsizeNoTree, $
        scrXsizeWithTree:scrXsizeWithTree, $
        scrYsizeNoTree:scrYsizeNoTree, $
        scrYsizeWithTree:scrYsizeWithTree $
        }

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        /NO_BLOCK, EVENT_HANDLER=myname+'_event'

end

