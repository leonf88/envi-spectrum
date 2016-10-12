; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdrunmacro.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the Run Macro dialog.
;
; Written by: AY, RSI, 2003.
; Modified:
;
;-


;-------------------------------------------------------------------------
pro IDLitwdRunMacro_help, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    oTool = state.oUI->GetTool()
    oHelp = oTool->GetService('HELP')
    if (OBJ_VALID(oHelp)) then $
        oHelp->HelpTopic, oTool, 'iToolsRunMacro'

end


;-------------------------------------------------------------------------
pro IDLitwdRunMacro_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; pass these properties back to the operation, allowing the
    ; macro to maintain its original values without having them
    ; modified by the values selected in the UI
    WIDGET_CONTROL, state.wStepDelay, get_value=stepDelay
    state.oRequestor->SetProperty, $
        DISPLAY_STEPS=WIDGET_INFO(state.wDisplaySteps, /BUTTON_SET), $
        MACRO_NAME=state.macroNameSelected, $
        STEP_DELAY=stepDelay

    WIDGET_CONTROL, event.top, /DESTROY

end


;-------------------------------------------------------------------------
pro IDLitwdRunMacro_cancel, event

    compile_opt idl2, hidden

    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdRunMacro_select, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    newMacroIndex = WIDGET_INFO(state.wMacroNames, /LIST_SELECT)

    ; Something selected in list.
    if (newMacroIndex ge 0) then begin
        oTool = state.oUI->GetTool()
        oSrvMacro = oTool->GetService('MACROS')
        oMacro = oSrvMacro->GetMacroByName(state.macroNames[newMacroIndex])
        if obj_valid(oMacro) then begin
            oMacro->GetProperty, DESCRIPTION=description, $
                DISPLAY_STEPS=displaySteps, $
                STEP_DELAY=stepDelay
            WIDGET_CONTROL, state.wMacroDescription, SET_VALUE=description
            WIDGET_CONTROL, state.wDisplaySteps, SET_BUTTON=displaySteps
            WIDGET_CONTROL, state.wStepDelay, SET_VALUE=stepDelay

        endif

        state.macroNameSelected = state.macroNames[newMacroIndex]
        WIDGET_CONTROL, child, SET_UVALUE=state

        ; for double click, run the selected widget
        if event.clicks eq 2 then IDLitwdRunMacro_ok, event
    endif
end


;-------------------------------------------------------------------------
pro IDLitwdRunMacro_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        ; needed to avoid flashing on Windows
        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else:

    endcase

end


;-------------------------------------------------------------------------
; Purpose:
;   Create the Run Macro widget.
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
pro IDLitwdRunMacro, oUI, oRequestor, $
    GROUP_LEADER=groupLeaderIn, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdRunMacro'

    ; Existing macro names.
    oTool = oUI->GetTool()
    oSrvMacro = oTool->GetService('MACROS')
    oMacros = oSrvMacro->GetMacro(/ALL, COUNT=nmacro)
    macroIDs = STRARR(nmacro > 1)
    macroNames = STRARR(nmacro > 1)
    for i=0,nmacro-1 do begin
        oMacros[i]->GetProperty, IDENTIFIER=id, NAME=name
        macroIDs[i] = id
        macroNames[i] = name
    endfor

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdRunMacro:Title')


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
        GROUP_LEADER=groupLeader, $
        /MODAL, $
        EVENT_PRO=myname+'_event', $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        /TLB_KILL_REQUEST, $  ; needed to avoid flashing on Windows
        _EXTRA=_extra)

    wBase1 = WIDGET_BASE(wBase, /ROW, XPAD=0, YPAD=0, SPACE=20)
    wLeft = WIDGET_BASE(wBase1, /COLUMN, SPACE=2)
    wDummy = WIDGET_BASE(wLeft, YSIZE=10)
    wLabel = WIDGET_LABEL(wLeft, $
                          VALUE=IDLitLangCatQuery('UI:wdRunMacro:SelMacro'), $
                          /ALIGN_LEFT)

    ; Macro Names list.
    wMacroNames = WIDGET_LIST(wLeft, $
        EVENT_PRO=myname+'_select', $
        VALUE=macroNames, $
        ; space for at least 5, no more than 20
        YSIZE=(n_elements(macroNames)>5) < 20)
    WIDGET_CONTROL, wMacroNames, SET_LIST_SELECT=0

    xsize = 250 > (WIDGET_INFO(wBase, /GEOM)).scr_xsize
    wLabel = WIDGET_LABEL(wLeft, $
                          VALUE=IDLitLangCatQuery('UI:wdRunMacro:MacroDesc'), $
                          /ALIGN_LEFT)
    wMacroDescription = WIDGET_TEXT(wLeft, $
        SCR_XSIZE=xsize-5, $
        YSIZE=1)


    wNonExc = WIDGET_BASE(wBase, /NONEXCLUSIVE, $
        SPACE=0, XPAD=1, YPAD=0)
    wDisplaySteps = WIDGET_BUTTON(wNonExc, VALUE= $
                                  IDLitLangCatQuery('UI:wdRunMacro:DispSteps'))

    wRow = WIDGET_BASE(wBase, /ROW, $
        SPACE=0, XPAD=0, YPAD=0)
    wStepDelay = CW_FIELD(wRow, /FLOATING, TITLE='')
    wLabel = WIDGET_LABEL(wRow, $
                          VALUE=IDLitLangCatQuery('UI:wdRunMacro:StepDelay'))

    wButtons = WIDGET_BASE(wBase, COLUMN=2, /GRID, $
        SCR_XSIZE=xsize)

    w1 = WIDGET_BASE(wButtons, /ALIGN_LEFT, XPAD=0, YPAD=0)

    wHelp = WIDGET_BUTTON(w1, VALUE=IDLitLangCatQuery('UI:wdRunMacro:Help'), $
                          EVENT_PRO=myname+'_help')

    w2 = WIDGET_BASE(wButtons, /ALIGN_RIGHT, /ROW, /GRID, $
        SPACE=5, XPAD=0, YPAD=0)

    wOk = WIDGET_BUTTON(w2, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    wCancel = WIDGET_BUTTON(w2, $
        EVENT_PRO=myname+'_cancel', VALUE=IDLitLangCatQuery('UI:CancelPad2'))

    WIDGET_CONTROL, wBase, /REALIZE

    ; Cache my state information within my child.
    state = { $
        oUI: oUI, $
        oRequestor: oRequestor, $
        wBase: wBase, $
        wMacroNames: wMacroNames, $
        macroNames: macroNames, $
        macroNameSelected: macroNames[0], $     ; initial selection
        wMacroDescription: wMacroDescription, $
        wDisplaySteps:wDisplaySteps, $
        wStepDelay: wStepDelay $
        }

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state

    IDLitwdRunMacro_select, $
        {ID: wMacroNames, TOP: wBase, HANDLER: wMacroNames, $
        INDEX: 0, CLICKS: 1}

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        /NO_BLOCK, EVENT_HANDLER=myname+'_event'

end

