; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdvolmenu.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdVolMenu
;
; PURPOSE:
;   This function creates the Volume Rendering control panel that
;   appears in volume tool.
;   The event handler for the menu appears here also.
;
; CALLING SEQUENCE:
;   IDLitwdVolMenu
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:
;   Modified:
;
;-


;-------------------------------------------------------------------------
; Handle events for the Volume Control Panel Widgets
;
pro idlitwdvolmenu_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state
    WIDGET_CONTROL, event.id, GET_UVALUE=uvalue

    ;; Now do the work for each menu item
    case STRUPCASE(uvalue) of

    'RENDER': begin
        WIDGET_CONTROL, /HOURGLASS
        success = state.oUI->DoAction("Operations/Volume/Render")
        return
        end

    'QUALITY': begin
        oSel = state.oTool->GetSelectedItems(count=nTarg)
        if (~nTarg) then $
            break
        index = WHERE(OBJ_ISA(oSel, 'IDLITVISVOLUME'), nTarg)
        success = 0
        for i=0,nTarg-1 do begin
            success or= state.oTool->DoSetProperty(oSel[i]->GetFullIdentifier(), $
                "_RENDER_QUALITY", event.index)
        endfor
        if (success) then $
            state.oTool->CommitActions
        end

    'EXTENTS': begin
        oSel = state.oTool->GetSelectedItems(count=nTarg)
        if (~nTarg) then $
            break
        index = WHERE(OBJ_ISA(oSel, 'IDLITVISVOLUME'), nTarg)
        success = 0
        for i=0,nTarg-1 do begin
            success or= state.oTool->DoSetProperty(oSel[i]->GetFullIdentifier(), $
                "RENDER_EXTENTS", event.index)
        endfor
        if (success) then $
            state.oTool->CommitActions
        end

    'AUTORENDER': begin
        oSel = state.oTool->GetSelectedItems(count=nTarg)
        if (~nTarg) then $
            break
        index = WHERE(OBJ_ISA(oSel, 'IDLITVISVOLUME'), nTarg)
        success = 0
        for i=0,nTarg-1 do begin
            success or= state.oTool->DoSetProperty(oSel[i]->GetFullIdentifier(), $
                "AUTO_RENDER", event.select)
        endfor
        ; Use the undocumented _TransactCommand instead of CommitActions,
        ; so that we don't automatically update the window.
        if (success) then $
            state.oTool->_TransactCommand, OBJ_NEW()

        ; Don't update the window if turning auto-render off.
        ; This will let the volume rendering stay on the screen.
        if (~event.select) then $
            return
        end

    'RENDERSTEP': begin
        ;; Read values from widget
        WIDGET_CONTROL, state.wRSX, GET_VALUE=rsX
        WIDGET_CONTROL, state.wRSY, GET_VALUE=rsY
        WIDGET_CONTROL, state.wRSZ, GET_VALUE=rsZ
        ;; Verify legal input
        ON_IOERROR, io_error
        rsX = STRING(rsX, FORMAT='(G0)')
        rsY = STRING(rsY, FORMAT='(G0)')
        rsZ = STRING(rsZ, FORMAT='(G0)')
        ON_IOERROR, NULL
        ;; Render Step cannot be smaller than 1
        val = DOUBLE([rsX, rsY, rsZ]) > 1.0

        ;; Nothing changed, leave without refreshing.
        if ARRAY_EQUAL(state.renderStep, val) then $
            return

        ;; Let's keep these values
        state.renderStep = val
        WIDGET_CONTROL, child, SET_UVALUE=state
        ;; Convert back to strings for widget
        s = STRCOMPRESS(STRING(state.renderStep, FORMAT='(G0)'))
        WIDGET_CONTROL, state.wRSX, SET_VALUE=s[0]
        WIDGET_CONTROL, state.wRSY, SET_VALUE=s[1]
        WIDGET_CONTROL, state.wRSZ, SET_VALUE=s[2]

        ;; Now set the property on selected items
        oSel = state.oTool->GetSelectedItems(count=nTarg)
        if (~nTarg) then $
            break
        index = WHERE(OBJ_ISA(oSel, 'IDLITVISVOLUME'), nTarg)
        success = 0
        for i=0,nTarg-1 do begin
            success or= state.oTool->DoSetProperty(oSel[i]->GetFullIdentifier(), $
                "RENDER_STEP", state.renderStep)
        endfor
        ; Use the undocumented _TransactCommand instead of CommitActions,
        ; so that we don't automatically update the window.
        if (success) then $
            state.oTool->_TransactCommand, OBJ_NEW()

        break

        io_error:
        ;; Put back the values we had
        s = STRCOMPRESS(STRING(state.renderStep, FORMAT='(G0)'))
        WIDGET_CONTROL, state.wRSX, SET_VALUE=s[0]
        WIDGET_CONTROL, state.wRSY, SET_VALUE=s[1]
        WIDGET_CONTROL, state.wRSZ, SET_VALUE=s[2]
        return
        end

    else:

    endcase

    state.oTool->RefreshCurrentWindow
end


;-------------------------------------------------------------------------
; Update control panel menu state.
;
pro idlitwdvolmenu_updatemenu, state, oVis

    compile_opt idl2, hidden

    oVis->GetProperty, AUTO_RENDER=autorender, $
        _RENDER_QUALITY=renderQuality, RENDER_STEP=renderStep, $
        RENDER_EXTENTS=renderExtents, NAME=name, VOLUME_SELECT=volumeSelect
    WIDGET_CONTROL, state.wBase, SENSITIVE=1
    WIDGET_CONTROL, state.wName, SET_VALUE=name
    WIDGET_CONTROL, state.wAuto, SET_VALUE=autorender
    WIDGET_CONTROL, state.wQuality, SET_DROPLIST_SELECT=renderQuality
    WIDGET_CONTROL, state.wExtents, SET_DROPLIST_SELECT=renderExtents
    WIDGET_CONTROL, state.wRenderStep, SENSITIVE=renderQuality
    s = STRCOMPRESS(STRING(renderStep, FORMAT='(G0)'))
    WIDGET_CONTROL, state.wRSX, SET_VALUE=s[0]
    WIDGET_CONTROL, state.wRSY, SET_VALUE=s[1]
    WIDGET_CONTROL, state.wRSZ, SET_VALUE=s[2]
    WIDGET_CONTROL, state.wVolumeSelect, $
        SET_VALUE=(['1','2','4'])[volumeSelect]

end


;-------------------------------------------------------------------------
; Handle notifications from the tool.
; Update control panel menu state in response to selections.
;
pro idlitwdvolmenu_callback, wPanel, strID, messageIn, component

    compile_opt idl2, hidden

    if not WIDGET_INFO(wPanel, /VALID) then return

    wChild = WIDGET_INFO(wPanel, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    case STRUPCASE(messageIn) of

    'VOLUMESELECT': begin
        WIDGET_CONTROL, state.wVolumeSelect, $
            SET_VALUE=(['1','2','4'])[component]
    end

    'SETPROPERTY': begin
        ;; Find selected item
        if (strID eq state.strSelectedVol) then begin
            oVol = state.oTool->GetByIdentifier(state.strSelectedVol)
            IDLITWDVOLMENU_UpdateMenu, state, oVol
        endif
        end

    'SELECTIONCHANGED': begin
        oSel = state.oTool->GetSelectedItems(COUNT=nSel)
        ;; if nothing is selected, then gray out the panel
        ;; and leave early
        if nSel eq 0 then begin
            WIDGET_CONTROL, state.wBase, SENSITIVE=0
            WIDGET_CONTROL, state.wName, SET_VALUE=" "
            WIDGET_CONTROL, state.wVolumeSelect, SET_VALUE=" "
            state.oUI->RemoveOnNotifyObserver, state.strObserverId, $
                state.strSelectedVol
            break
        endif

        ;; Handle selections
        index = (WHERE(OBJ_ISA(oSel, 'IDLITVISVOLUME')))[0]
        if (index eq -1) then begin
            ;; Grey out the panel if there are no volumes selected.
            WIDGET_CONTROL, state.wBase, SENSITIVE=0
            WIDGET_CONTROL, state.wName, SET_VALUE=" "
            WIDGET_CONTROL, state.wVolumeSelect, SET_VALUE=" "
            state.oUI->RemoveOnNotifyObserver, state.strObserverId, $
                state.strSelectedVol
            break
        endif

        ;; Check for multiple dataspaces
        for i=0,nSel-1 do begin
          oManip = oSel[i]->GetManipulatorTarget()
          ;; Save normalizer dataspaces
          if (OBJ_ISA(oManip, 'IDLitVisNormalizer')) then $
            oDS = (N_ELEMENTS(oDS) eq 0) ? [oManip] : [oDS, oManip] 
        endfor
        ; Filter out reduntant dataspaces
        nDS = N_ELEMENTS(UNIQ(oDS, SORT(oDS)))
        ; Only work if all items are in the same dataspace
        if (nDS gt 1) then begin
            ;; Grey out the panel if more than one dataspace is selected
            WIDGET_CONTROL, state.wBase, SENSITIVE=0
            WIDGET_CONTROL, state.wName, SET_VALUE=" "
            WIDGET_CONTROL, state.wVolumeSelect, SET_VALUE=" "
            state.oUI->RemoveOnNotifyObserver, state.strObserverId, $
                state.strSelectedVol
            break
        endif

        ;; Otherwise update widget state
        IDLITWDVOLMENU_UpdateMenu, state, oSel[index]

        ;; Watch for property changes.
        if state.strObserverId eq '' then $
            state.strObserverId = state.oUI->RegisterWidget(state.wPanel, $
                "Panel Name", 'idlitwdvolmenu_callback')
        state.strSelectedVol = oSel[index]->GetFullIdentifier()
        state.oUI->AddOnNotifyObserver, state.strObserverId, $
            state.strSelectedVol
        WIDGET_CONTROL, wChild, SET_UVALUE=state
        end

    else:
    endcase

end

;-------------------------------------------------------------------------
pro idlitwdvolmenu, wPanel, oUI

    compile_opt idl2, hidden

    WIDGET_CONTROL, wPanel, $
                    BASE_SET_TITLE=IDLitLangCatQuery('UI:wdVolMenu:Title')

    ;; Specify event handler
    WIDGET_CONTROL, wPanel, event_pro="idlitwdvolmenu_event"

    ;; Register and observe selection events on Visualizations
    strObserverIdentifier = oUI->RegisterWidget(wPanel, "Panel", $
        'idlitwdvolmenu_callback')
    oUI->AddOnNotifyObserver, strObserverIdentifier, 'Visualization'

    wBase = WIDGET_BASE(wPanel, /COLUMN, XPAD=2, SPACE=2, /TAB_MODE)

    ;; Build Menu
    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:Name'), $
                          /align_left)
    wTmp=widget_base(wBase, xpad=10, /row)
    wName=widget_label(wTmp, /align_left, value="My Volume 1234", $
        /DYNAMIC_RESIZE)

    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:Channels'), $
                          /align_left)
    wTmp = WIDGET_BASE(wBase, /ROW, XPAD=10)
    wVolumeSelect = widget_label(wTmp, XSIZE=8, VALUE=' ')

    wRender = WIDGET_BUTTON(wBase, $
                            VALUE=IDLitLangCatQuery('UI:wdVolMenu:Render'), $
                            UVALUE="Render")
    wAuto = CW_BGROUP(wBase, [IDLitLangCatQuery('UI:wdVolMenu:AutoRender')], $
                      /NONEXCLUSIVE, UVALUE="AUTORENDER")

    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:Quality'), $
                          /ALIGN_LEFT)
    wQuality = WIDGET_DROPLIST(wBase, /FLAT, $
        VALUE=[IDLitLangCatQuery('UI:wdVolMenu:QualLow'), $
               IDLitLangCatQuery('UI:wdVolMenu:QualHigh')], $
        UVALUE="QUALITY")
    WIDGET_CONTROL, wQuality, SET_DROPLIST_SELECT=0

    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:Boundary'), $
                          /ALIGN_LEFT)
    wExtents = WIDGET_DROPLIST(wBase, /FLAT, $
        VALUE=[IDLitLangCatQuery('UI:wdVolMenu:BoundaryNone'), $
               IDLitLangCatQuery('UI:wdVolMenu:BoundaryWire'), $
               IDLitLangCatQuery('UI:wdVolMenu:BoundarySolid')], $
        UVALUE="EXTENTS")
    WIDGET_CONTROL, wExtents, SET_DROPLIST_SELECT=1

    ;; align the droplists
    geomQ = widget_info(wQuality, /geometry)
    geomE = widget_info(wExtents, /geometry)

    xsize = geomQ.scr_xsize > geomE.scr_xsize
    widget_control, wQuality, scr_xsize=xsize
    widget_control, wExtents, scr_xsize=xsize


    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:RenderStep'), $
                          /align_left)
    wRenderStep = WIDGET_BASE(wBase, /COL, /BASE_ALIGN_CENTER, SENSITIVE=0, $
        SPACE=1, YPAD=0)

    wX = WIDGET_BASE(wRenderStep, /ROW, XPAD=10, YPAD=0)
    wRSLab = WIDGET_LABEL(wX, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:RenderStepX'))
    wRSX = WIDGET_TEXT(wX, XSIZE=8, $
        /EDITABLE, /KBRD_FOCUS_EVENTS, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        VALUE='1', UVALUE='RENDERSTEP')

    wY = WIDGET_BASE(wRenderStep, /ROW, XPAD=10, YPAD=0)
    wRSLab = WIDGET_LABEL(wY, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:RenderStepY'))
    wRSY = WIDGET_TEXT(wY, XSIZE=8, $
        /EDITABLE, /KBRD_FOCUS_EVENTS, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        VALUE='1', UVALUE='RENDERSTEP')

    wZ = WIDGET_BASE(wRenderStep, /ROW, XPAD=10, YPAD=0)
    wRSLab = WIDGET_LABEL(wZ, $
                          VALUE=IDLitLangCatQuery('UI:wdVolMenu:RenderStepZ'))
    wRSZ = WIDGET_TEXT(wZ, XSIZE=8, $
        /EDITABLE, /KBRD_FOCUS_EVENTS, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        VALUE='1', UVALUE='RENDERSTEP')

    ;; Start off un-selected
    WIDGET_CONTROL, wBase, SENSITIVE=0
    WIDGET_CONTROL, wName, SET_VALUE=" "

    oTool = oUI->GetTool()
    ;; Pack up the state and store in first child.
    state = {oTool:oTool, $
             oUI:oUI, $
             wPanel:wPanel, $
             wBase:wBase, $
             wName:wName, $
             wRender:wRender, $
             wAuto:wAuto, $
             wQuality:wQuality, $
             wExtents:wExtents, $
             wRenderStep:wRenderStep, $
             wRSX: wRSX, $
             wRSY: wRSY, $
             wRSZ: wRSZ, $
             renderStep: [1.0d, 1.0d, 1.0d], $
             wVolumeSelect: wVolumeSelect, $
             strSelectedVol: '', $
             strObserverId: '' $
             }

    wChild = WIDGET_INFO(wPanel, /CHILD)
    if wChild ne 0 then $
        WIDGET_CONTROL, wChild, SET_UVALUE=state, /NO_COPY

end

