; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdmappanel.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdMapPanel
;
; PURPOSE:
;   This function creates the control panel that appears in the iMap tool.
;
;-


;-------------------------------------------------------------------------
; Handle events for the Image Control Panel widget.
;
pro IDLitwdMapPanel_event, event

    compile_opt idl2, hidden

    ; Ignore keyboard "gain focus" events. Just process "lose focus"
    ; or carriage return events.
    if (TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KBRD_FOCUS') then $
        if (event.enter eq 1) then return

    WIDGET_CONTROL, event.id, GET_UVALUE=uval
    uname = WIDGET_INFO(event.id, /UNAME)

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    switch uname of

    'EDIT_PROJECTION': begin
        void = (*pState).oTool->DoAction('Operations/Operations/Map Projection')
        break
        end

    'LONGITUDE_MIN': ; fall thru
    'LONGITUDE_MAX': ; fall thru
    'LATITUDE_MIN': ; fall thru
    'LATITUDE_MAX': begin
        WIDGET_CONTROL, event.id, GET_VALUE=value, GET_UVALUE=oldvalue
        if (value eq oldvalue) then $
            break
        ; Catch any conversion errors.
        ON_IOERROR, skip
        value = DOUBLE(value)
        ON_IOERROR, null

        ; Fire up the Map Limit operation to actually change the value.
        ; This is because the Map Limit operation needs
        ; to be careful how it does its Undo/Redo command set,
        ; and it's easier to let the operation handle the details.
        op = 'Operations/Operations/Map Limit'
        oDesc = (*pState).oTool->GetByIdentifier(op)
        case uname of
        'LONGITUDE_MIN': oDesc->SetProperty, LONGITUDE_MIN=value, SET_LIMIT=0
        'LONGITUDE_MAX': oDesc->SetProperty, LONGITUDE_MAX=value, SET_LIMIT=1
        'LATITUDE_MIN': oDesc->SetProperty, LATITUDE_MIN=value, SET_LIMIT=2
        'LATITUDE_MAX': oDesc->SetProperty, LATITUDE_MAX=value, SET_LIMIT=3
        endcase
        void = (*pState).oTool->DoAction(op)
        break

skip:
        WIDGET_CONTROL, event.id, SET_VALUE=oldvalue
        break
        end

    else:

    endswitch

end


;-------------------------------------------------------------------------
pro IDLitwdMapPanel_ObserveProjection, pState

    compile_opt idl2, hidden

    if (~OBJ_VALID((*pState).oNormDataspace)) then $
        goto, invalid

    oDataspace = (*pState).oNormDataspace->GetDataspace(/UNNORMALIZED)

    if (~OBJ_VALID(oDataspace)) then $
        goto, invalid

    ; Do we have a valid map projection?
    if (N_TAGS(oDataspace->GetProjection()) eq 0) then $
        goto, invalid

    WIDGET_CONTROL, (*pState).wProjection, /SENSITIVE

    ; Retrieve the map projection object and cache its id.
    oMapProj = oDataspace->_GetMapProjection()

    ; Update our widget values with the new limits.
    oMapProj->GetProperty, $
        LONGITUDE_MIN=longitudeMin, $
        LONGITUDE_MAX=longitudeMax, $
        LATITUDE_MIN=latitudeMin, $
        LATITUDE_MAX=latitudeMax
    f = '(g0.15)'
    WIDGET_CONTROL, (*pState).wLon1, $
        SET_VALUE=STRING(longitudeMin, FORMAT=f), $
        SET_UVALUE=STRING(longitudeMin, FORMAT=f)
    WIDGET_CONTROL, (*pState).wLon2, $
        SET_VALUE=STRING(longitudeMax, FORMAT=f), $
        SET_UVALUE=STRING(longitudeMax, FORMAT=f)
    WIDGET_CONTROL, (*pState).wLat1, $
        SET_VALUE=STRING(latitudeMin, FORMAT=f), $
        SET_UVALUE=STRING(latitudeMin, FORMAT=f)
    WIDGET_CONTROL, (*pState).wLat2, $
        SET_VALUE=STRING(latitudeMax, FORMAT=f), $
        SET_UVALUE=STRING(latitudeMax, FORMAT=f)

    return ; success


invalid:
    ; If we reach here then no valid map projection.
    WIDGET_CONTROL, (*pState).wProjection, SENSITIVE=0

end


;-------------------------------------------------------------------------
; Handle notifications from the tool.
; Update control panel menu state in response to selections.
;
pro IDLitwdMapPanel_callback, wPanel, strID, messageIn, userData

    compile_opt idl2, hidden

    if not WIDGET_INFO(wPanel, /VALID) then return

    wChild = WIDGET_INFO(wPanel, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=pState

    switch STRUPCASE(messageIn) of

    'SELECTIONCHANGED': begin
        oSel = ((*pState).oTool->GetSelectedItems())[0]
        hasProjection = 0b

        if (OBJ_ISA(oSel, '_IDLitVisualization')) then begin

            ; Only observe visualizations which have the probe.
            hasProbe = OBJ_ISA(oSel, 'IDLitVisContour') || $
                OBJ_ISA(oSel, 'IDLitVisImage')
            WIDGET_CONTROL, (*pState).wLocation, SENSITIVE=hasProbe

            idSel = oSel->GetFullIdentifier()
            if ((*pState).idSel ne idSel) then begin
                if ((*pState).idSel ne '') then begin
                    (*pState).oUI->RemoveOnNotifyObserver, $
                        (*pState).idSelf, (*pState).idSel
                    (*pState).idSel = ''
                    (*pState).oSel = OBJ_NEW()
                endif
                if (hasProbe) then begin
                    (*pState).oUI->AddOnNotifyObserver, (*pState).idSelf, idSel
                    (*pState).idSel = idSel
                    (*pState).oSel = oSel
                endif
            endif

            ; Observe the visualization's dataspace, so we know if
            ; a map projection was added.
            oNormDataspace = oSel->GetDataspace()
            idDataspace = OBJ_VALID(oNormDataspace) ? $
                oNormDataspace->GetFullIdentifier() : ''
            if ((*pState).idDataspace ne idDataspace) then begin
                if ((*pState).idDataspace ne '') then begin
                    (*pState).oUI->RemoveOnNotifyObserver, $
                        (*pState).idSelf, (*pState).idDataspace
                    (*pState).idDataspace = ''
                    (*pState).oNormDataspace = OBJ_NEW()
                endif
                if (idDataspace ne '') then begin
                    (*pState).oUI->AddOnNotifyObserver, $
                        (*pState).idSelf, idDataspace
                    (*pState).idDataspace = idDataspace
                    (*pState).oNormDataspace = oNormDataspace
                endif
            endif

            IDLitwdMapPanel_ObserveProjection, pState

        endif else begin

            WIDGET_CONTROL, (*pState).wLocation, SENSITIVE=0

            ; No selections, remove ourself as an observer.
            if ((*pState).idSel ne '') then begin
                (*pState).oUI->RemoveOnNotifyObserver, (*pState).idSelf, (*pState).idSel
                (*pState).idSel = ''
                (*pState).oSel = OBJ_NEW()
            endif

            if ((*pState).idDataspace ne '') then begin
                (*pState).oUI->RemoveOnNotifyObserver, $
                    (*pState).idSelf, (*pState).idDataspace
                (*pState).idDataspace = ''
                (*pState).oNormDataspace = OBJ_NEW()
            endif

            IDLitwdMapPanel_ObserveProjection, pState
        endelse

        break
        end

    'CONTOURPROBE': ; fall thru
    'IMAGEPROBE': begin
        if (OBJ_VALID((*pState).oSel)) then begin
            ; The userData contains the current probe location.
            (*pState).oSel->GetExtendedDataStrings, userData, $
                MAP_LOCATION=mapLocation, $
                PIXEL_VALUE=pixelValues

            WIDGET_CONTROL, (*pState).wMapLocation1, SET_VALUE=mapLocation[0]
            WIDGET_CONTROL, (*pState).wMapLocation2, SET_VALUE=mapLocation[1]
            WIDGET_CONTROL, (*pState).wImageLocation1, SET_VALUE=mapLocation[2]
            WIDGET_CONTROL, (*pState).wImageLocation2, SET_VALUE=mapLocation[3]

            for i=0,N_ELEMENTS(pixelValues)-1 do $
                WIDGET_CONTROL, (*pState).wPixelValLabels[i], SET_VALUE=pixelValues[i]
            for i=N_ELEMENTS(pixelValues),(*pState).nPixelValLabels-1 do $
                WIDGET_CONTROL, (*pState).wPixelValLabels[i], SET_VALUE=' '
        endif
        break
    end

    'SETPROPERTY': ; fall thru
    'ADDITEMS': begin
        if (strID ne (*pState).idDataspace) then $
            break
        if (STRPOS(userData, 'PROJECTION') ge 0) then begin
            IDLitwdMapPanel_ObserveProjection, pState
        endif
        break
        end

    else:

    endswitch

end


;-------------------------------------------------------------------------
pro IDLitwdMapPanel_killnotify, wChild

    compile_opt idl2, hidden

    WIDGET_CONTROL, wChild, GET_UVALUE=pState
    PTR_FREE, pState

end


;-------------------------------------------------------------------------
pro IDLitwdMapPanel, wPanel, oUI

    compile_opt idl2, hidden

    WIDGET_CONTROL, wPanel, BASE_SET_TITLE=IDLitLangCatQuery('UI:wdMapPanel:Title')

    ; Specify event handler
    WIDGET_CONTROL, wPanel, event_pro="IDLitwdMapPanel_event"

    ; Register and observe selection events on Visualizations
    idSelf = oUI->RegisterWidget(wPanel, "Map Panel", $
        'IDLitwdMapPanel_callback')

    oUI->AddOnNotifyObserver, idSelf, 'Visualization'
    oUI->AddOnNotifyObserver, idSelf, 'StatusBar'

    wBase = WIDGET_BASE(wPanel, /COLUMN, /TAB_MODE)


    ; --Labels--------------------------------------------------------
    ; Pixel Location.
    wLocation = WIDGET_BASE(wBase, /COLUMN, XPAD=0, YPAD=0)
    wLabel = WIDGET_LABEL(wLocation, $
                          VALUE=IDLitLangCatQuery('UI:wdMapPanel:Loc'), $
                          /ALIGN_LEFT)

    wLocation2 = WIDGET_BASE(wLocation, /COLUMN, XPAD=4, YPAD=2)
    ;; Note fake value for sizing
    value = "Lon: -0.0001234d  "
    wMapLocation1 = WIDGET_LABEL(wLocation2, VALUE=value, $
        /ALIGN_LEFT)
    wImageLocation1 = WIDGET_LABEL(wLocation2, VALUE=value, $
        /ALIGN_LEFT)
    wMapLocation2 = WIDGET_LABEL(wLocation2, VALUE=value, $
        /ALIGN_LEFT)
    wImageLocation2 = WIDGET_LABEL(wLocation2, VALUE=value, $
        /ALIGN_LEFT)

    ;; Fix sizing or the tab base will/can shift during update
    geom = WIDGET_INFO(wImageLocation1, /GEOMETRY)
    xsize = geom.scr_xsize > 100
    WIDGET_CONTROL, wImageLocation1, SCR_XSIZE=xsize, $
        SCR_YSIZE=geom.scr_ysize, SET_VALUE=""
    WIDGET_CONTROL, wImageLocation2, SCR_XSIZE=xsize, $
        SCR_YSIZE=geom.scr_ysize, SET_VALUE=""
    geom = WIDGET_INFO(wMapLocation1, /GEOMETRY)
    WIDGET_CONTROL, wMapLocation1, SCR_XSIZE=xsize, $
        SCR_YSIZE=geom.scr_ysize, SET_VALUE=""
    WIDGET_CONTROL, wMapLocation2, SCR_XSIZE=xsize, $
        SCR_YSIZE=geom.scr_ysize, SET_VALUE=""

    wDummy = WIDGET_LABEL(wLocation, VALUE=" ", /ALIGN_LEFT)

    ; Pixel Value.
    wLabel = WIDGET_LABEL(wLocation, $
                          VALUE=IDLitLangCatQuery('UI:wdMapPanel:DataVal'), $
                          /ALIGN_LEFT)
    nPixelValLabels = 4
    wPixelValLabels = LONARR(nPixelValLabels)
    wTmp = WIDGET_BASE(wLocation, XPAD=10, YPAD=0, SPACE=0, /COLUMN)
    for i=0,nPixelValLabels-1 do $
        wPixelValLabels[i] = WIDGET_LABEL(wTmp, VALUE=" ", $
            SCR_XSIZE=xsize, /ALIGN_LEFT)

    wProjection = WIDGET_BASE(wBase, /COLUMN, SPACE=4, XPAD=0)
    wPbase0 = WIDGET_BASE(wProjection, /COLUMN, SPACE=1, XPAD=0)
    wLabel = WIDGET_LABEL(wPbase0, $
                          VALUE=IDLitLangCatQuery('UI:wdMapPanel:LongLimit'), $
                          /ALIGN_LEFT)

    wPbase = WIDGET_BASE(wPbase0, /ROW, /ALIGN_RIGHT, YPAD=0)
    wVoid = WIDGET_LABEL(wPbase, $
                         VALUE=IDLitLangCatQuery('UI:wdMapPanel:Min'), $
                         /ALIGN_RIGHT)
    wLon1 = WIDGET_TEXT(wPbase, VALUE='-180', /EDITABLE, XSIZE=8, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /KBRD_FOCUS_EVENTS, $
        UNAME='LONGITUDE_MIN', UVALUE='-180')

    wPbase = WIDGET_BASE(wPbase0, /ROW, /ALIGN_RIGHT, YPAD=0)
    wVoid = WIDGET_LABEL(wPbase, $
                         VALUE=IDLitLangCatQuery('UI:wdMapPanel:Max'), $
                         /ALIGN_RIGHT)
    wLon2 = WIDGET_TEXT(wPbase, VALUE='180', /EDITABLE, XSIZE=8, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /KBRD_FOCUS_EVENTS, $
        UNAME='LONGITUDE_MAX', UVALUE='180')

    wPbase0 = WIDGET_BASE(wProjection, /COLUMN, SPACE=1, XPAD=0)
    wLabel = WIDGET_LABEL(wPbase0, $
                          VALUE=IDLitLangCatQuery('UI:wdMapPanel:LatLimit'), $
                          /ALIGN_LEFT)

    wPbase = WIDGET_BASE(wPbase0, /ROW, /ALIGN_RIGHT, YPAD=0)
    wVoid = WIDGET_LABEL(wPbase, $
                         VALUE=IDLitLangCatQuery('UI:wdMapPanel:Min'), $
                         /ALIGN_RIGHT)
    wLat1 = WIDGET_TEXT(wPbase, VALUE='-90', /EDITABLE, XSIZE=8, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /KBRD_FOCUS_EVENTS, $
        UNAME='LATITUDE_MIN', UVALUE='-90')

    wPbase = WIDGET_BASE(wPbase0, /ROW, /ALIGN_RIGHT, YPAD=0)
    wVoid = WIDGET_LABEL(wPbase, $
                         VALUE=IDLitLangCatQuery('UI:wdMapPanel:Max'), $
                         /ALIGN_RIGHT)
    wLat2 = WIDGET_TEXT(wPbase, VALUE='90', /EDITABLE, XSIZE=8, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        /KBRD_FOCUS_EVENTS, $
        UNAME='LATITUDE_MAX', UVALUE='90')

    ; Edit Projection Button.
    wRow = WIDGET_BASE(wBase, /ALIGN_LEFT, /ROW, XPAD=0, YPAD=0)
    wEditProjection = WIDGET_BUTTON(wRow, $
        VALUE=IDLitLangCatQuery('UI:wdMapPanel:EditProj'), $
        UNAME='EDIT_PROJECTION', /ALIGN_CENTER)

    oTool = oUI->GetTool()

    ; Store (*pState).
    state = {oTool: oTool, $
        oUI: oUI, $
        idSelf: idSelf, $
        wBase: wBase, $
        wLocation: wLocation, $
        wImageLocation1: wImageLocation1, $
        wImageLocation2: wImageLocation2, $
        wMapLocation1: wMapLocation1, $
        wMapLocation2: wMapLocation2, $
        wPixelValLabels: wPixelValLabels, $
        nPixelValLabels: nPixelValLabels, $
        wProjection: wProjection, $
        wLon1: wLon1, $
        wLon2: wLon2, $
        wLat1: wLat1, $
        wLat2: wLat2, $
        wEditProjection: wEditProjection, $
        idSel: '', $
        oSel: OBJ_NEW(), $
        idDataspace: '', $
        oNormDataspace: OBJ_NEW() $
    }

    wChild = WIDGET_INFO(wPanel, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=PTR_NEW(state), $
        KILL_NOTIFY='IDLitwdMapPanel_killnotify'


   ; Emulate a SELECTIONCHANGED event to force proper setup.
    IDLitwdMapPanel_callback, wPanel, 'Visualization', 'SELECTIONCHANGED', $
        OBJ_NEW()
end
