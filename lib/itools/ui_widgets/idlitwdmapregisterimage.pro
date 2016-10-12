; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdmapregisterimage.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdMapRegisterImage
;
; PURPOSE:
;   This function implements the Grid Wizard dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdMapRegisterImage()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, September 2002.
;   Modified:
;
;-

;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_callback, wBase, strID, messageIn, component

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return

    WIDGET_CONTROL, wBase, GET_UVALUE=pState

    (*pState).oMapProj->GetProperty, PROJECTION=mapProjection
    dialog_wizard_setNext, wBase, (mapProjection gt 0)

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_help, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    oTool = (*pState).oTool
    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return
    oHelp->HelpTopic, oTool, 'iToolsMapRegisterImage'

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_geotiff, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState

    ; Let our data object handle firing up the text box with the tags.
    void = (*pState).oGeoData->EditUserDefProperty( $
        (*pState).oTool, 'GEOTIFF_TAGS')

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_3_docreate, pState, id

    compile_opt idl2, hidden

    wCol = WIDGET_BASE((*pState).wBase0, /BASE_ALIGN_LEFT, /COLUMN, $
        MAP=0, $
        SPACE=10)
    (*pState).wBase3 = wCol


    wText = WIDGET_LABEL(wCol, $
        VALUE=IDLitLangCatQuery('UI:MapRegImage:ChooseProj'), /ALIGN_LEFT)

    oTool = (*pState).oTool
    oDesc = oTool->GetByIdentifier((*pState).idComponent)
    oOper = oDesc->GetObjectInstance()
    oMapProj = oOper->_GetMapProjection()
    if (~OBJ_VALID(oMapProj)) then $
        return
    (*pState).oMapProj = oMapProj

    idMapProj = oMapProj->GetFullIdentifier()

    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    idSelf = (*pState).oUI->RegisterWidget(id, 'MapRegisterImage', $
        'IDLitwdMapRegisterImage_callback')

    ; Register for notification messages
    (*pState).oUI->AddOnNotifyObserver, idSelf, idMapProj


    wRow = WIDGET_BASE(wCol, /ROW, SPACE=10)

    (*pState).wProp3 = CW_ITPROPERTYSHEET(wRow, (*pState).oUI, $
        /SUNKEN_FRAME, $
        VALUE=idMapProj, $
        SCR_XSIZE=350, YSIZE=13, $
        COMMIT_CHANGES=0)

    (*pState).wPreview = CW_ITPROPERTYPREVIEW(wRow, (*pState).oUI, $
        VALUE=oMapProj)

    wButBase = WIDGET_BASE(wCol, /NONEXCLUSIVE)
    (*pState).wUpdateDataspace = WIDGET_BUTTON(wButBase, $
        VALUE=IDLitLangCatQuery('UI:MapRegImage:Dataspace'))
    WIDGET_CONTROL, (*pState).wUpdateDataspace, /SET_BUTTON

    ; If we have GeoTIFF data associated with this image, then
    ; add a button to allow viewing the GeoTIFF tags.
    ; Should have already retrieved the data object on Screen 2.
    if (OBJ_VALID((*pState).oGeoData)) then begin
        wBut = WIDGET_BUTTON(wCol, $
            EVENT_PRO='IDLitwdMapRegisterImage_geotiff', $
            VALUE='Show GeoTIFF tags', UVALUE=pState)
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_3_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    if ~WIDGET_INFO((*pState).wBase3, /VALID) then begin
        IDLitwdMapRegisterImage_3_docreate, pState, id
    endif

    (*pState).oMapProj->GetProperty, PROJECTION=mapProjection
    dialog_wizard_setNext, id, (mapProjection gt 0)

    WIDGET_CONTROL, (*pState).wBase3, /MAP

end


;-------------------------------------------------------------------------
function IDLitwdMapRegisterImage_3_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    WIDGET_CONTROL, (*pState).wBase3, MAP=0

    if (bNext) then begin
        oTool = (*pState).oTool
        oDesc = oTool->GetByIdentifier((*pState).idComponent)
        oDesc->SetProperty, UPDATE_DATASPACE= $
            WIDGET_INFO((*pState).wUpdateDataspace, /BUTTON_SET)
    endif

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_2_docreate, pState, id

    compile_opt idl2, hidden

    wCol = WIDGET_BASE((*pState).wBase0, /BASE_ALIGN_LEFT, /COLUMN, $
        MAP=0, $
        SPACE=4)
    (*pState).wBase2 = wCol

    wText = WIDGET_LABEL(wCol, $
        VALUE=IDLitLangCatQuery('UI:MapRegImage:GridLabel'))

    wRow = WIDGET_BASE(wCol, /ROW)

    ; Construct the actual property sheet.
    (*pState).wProp2 = CW_ITPROPERTYSHEET(wRow, (*pState).oUI, $
        /SUNKEN_FRAME, $
        VALUE=(*pState).idComponent, $
        SCR_XSIZE=350, YSIZE=7, $
        COMMIT_CHANGES=0)

    ; If we have GeoTIFF data associated with this image, then
    ; add a button to allow viewing the GeoTIFF tags.
    oDesc = (*pState).oTool->GetByIdentifier((*pState).idComponent)
    oOper = oDesc->GetObjectInstance()
    (*pState).oGeoData = oOper->_GetGeoTIFFobj()
    if (OBJ_VALID((*pState).oGeoData)) then begin
        wBut = WIDGET_BUTTON(wCol, $
            EVENT_PRO='IDLitwdMapRegisterImage_geotiff', $
            VALUE='Show GeoTIFF tags', UVALUE=pState)
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_2_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    if ~WIDGET_INFO((*pState).wBase2, /VALID) then begin
        IDLitwdMapRegisterImage_2_docreate, pState, id
    endif

    ; Make sure our Next button is sensitized.
    dialog_wizard_setNext, id, 1

    WIDGET_CONTROL, (*pState).wProp2, /REFRESH
    WIDGET_CONTROL, (*pState).wBase2, /MAP

end


;-------------------------------------------------------------------------
function IDLitwdMapRegisterImage_2_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    WIDGET_CONTROL, (*pState).wBase2, MAP=0

    return, 1
end


;-------------------------------------------------------------------------
function IDLitwdMapRegisterImage_event1, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_VALUE=gridUnits, GET_UVALUE=pState

    screens = 'IDLitwdMapRegisterImage_'

    screens += (gridUnits eq 1) ? ['1', '2'] : ['1', '2', '3']

    dialog_wizard_setscreens, WIDGET_INFO((*pState).wBase0, /PARENT), $
        SCREENS=screens

    return, event

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_1_docreate, pState, id

    compile_opt idl2, hidden

    (*pState).wBase0 = WIDGET_BASE(id)

    wRow = WIDGET_BASE((*pState).wBase0, /ROW, $
        MAP=0, $
        SPACE=10)
    (*pState).wBase1 = wRow


    status = IDLitGetResource("MENU", background, /COLOR)

    wCol = WIDGET_BASE(wRow, /BASE_ALIGN_LEFT, /COLUMN, SPACE=10)


    wText = WIDGET_TEXT(wCol, $
        VALUE=IDLitLangCatQuery('UI:MapRegImage:Description'), $
        /ALIGN_LEFT, SCR_XSIZE=400, YSIZE=4, /WRAP)

    wText = WIDGET_LABEL(wCol, $
        VALUE=IDLitLangCatQuery('UI:MapRegImage:ChooseUnits'))

    units = [IDLitLangCatQuery('UI:MapRegImage:Meters'), $
        IDLitLangCatQuery('UI:MapRegImage:Degrees')]
    (*pState).wUnits = CW_BGROUP(wCol, units, /EXCLUSIVE, $
        EVENT_FUNC='IDLitwdMapRegisterImage_event1', UVALUE=pState)

end


;-------------------------------------------------------------------------
pro IDLitwdMapRegisterImage_1_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    if ~WIDGET_INFO((*pState).wBase1, /VALID) then begin
        IDLitwdMapRegisterImage_1_docreate, pState, id
    endif

    oTool = (*pState).oTool
    oDesc = oTool->GetByIdentifier((*pState).idComponent)
    oDesc->GetProperty, GRID_UNITS=gridUnits
    WIDGET_CONTROL, (*pState).wUnits, SET_VALUE=gridUnits

    void = IDLitwdMapRegisterImage_event1({ID: (*pState).wUnits})

    WIDGET_CONTROL, (*pState).wBase1, /MAP

end


;-------------------------------------------------------------------------
function IDLitwdMapRegisterImage_1_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    WIDGET_CONTROL, (*pState).wBase1, MAP=0

    oTool = (*pState).oTool
    oDesc = oTool->GetByIdentifier((*pState).idComponent)
    WIDGET_CONTROL, (*pState).wUnits, GET_VALUE=gridUnits
    oDesc->GetProperty, GRID_UNITS=oldGridUnits
    if (oldGridUnits ne gridUnits) then $
        oDesc->SetProperty, GRID_UNITS=gridUnits

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   Create the Grid Wizard.
;
; Arguments:
;
; Keywords:
;   GROUP_LEADER: Set this to the widget ID of the group leader.
;
function IDLitwdMapRegisterImage, oUI, $
    GROUP_LEADER=groupLeader, $
    VALUE=idComponent

    compile_opt idl2, hidden

    ON_ERROR, 2

    myname = 'IDLitwdMapRegisterImage'

    xsize=600
    ysize=400

    oTool = OBJ_VALID(oUI) ? oUI->GetTool() : OBJ_NEW()

    state = { $
   ; These are needed by widgets.
        xsize: xsize, $
        ysize: ysize, $
        idComponent: idComponent, $
        oUI: oUI, $
        oTool: oTool, $
        oMapProj: OBJ_NEW(), $
        oGeoData: OBJ_NEW(), $
        wBase0: 0L, $
        wBase1: 0L, $
        wBase2: 0L, $
        wBase3: 0L, $
        wProp2: 0L, $
        wProp3: 0L, $
        wPreview: 0L, $
        wUpdateDataspace: 0L, $
        wUnits: 0L}

    pState = PTR_NEW(state)

    ; Only put the Help button on if we have a valid tool.
    if (OBJ_VALID(oTool)) then $
        helpPro = 'IDLitwdMapRegisterImage_help'

    success = DIALOG_WIZARD( $
        'IDLitwdMapRegisterImage_' + ['1', '2'], $
        GROUP_LEADER=groupLeader, $
        HELP_PRO=helpPro, $
        TITLE=IDLitLangCatQuery('UI:MapRegImage:Title'), $
        UVALUE=pState, $
        SPACE=0, XPAD=0, YPAD=0, $
        XSIZE=xsize, YSIZE=ysize)

    ; Cleanup all my state variables.
    PTR_FREE, pState

    return, success
end

