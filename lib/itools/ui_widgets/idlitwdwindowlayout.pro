; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdwindowlayout.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the Window Layout dialog.
;
; Written by: CT, RSI, 2002.
; Modified:
;
;-


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_update_dimensions, pState

    compile_opt idl2, hidden

    ; See if preview window needs to be resized.
    WIDGET_CONTROL, (*pState).wDim0, GET_VALUE=xDim
    xDim = LONG(xDim)
    WIDGET_CONTROL, (*pState).wDim1, GET_VALUE=yDim
    yDim = LONG(yDim)

    (*pState).oView->GetProperty, VIEWPLANE_RECT=viewPlane

    previewDim = DOUBLE([(*pState).drawSize, (*pState).drawSize])

    if (xDim ge yDim) then $
        previewDim[1] *= DOUBLE(yDim)/xDim $
    else $
        previewDim[0] *= DOUBLE(xDim)/yDim

    ; To avoid roundoff errors, dimensions should be integers.
    previewDim = CEIL(previewDim)

    if not ARRAY_EQUAL(previewDim, viewPlane[2:3]) then begin
        (*pState).oView->SetProperty, $
            DIMENSIONS=previewDim, $
            LOCATION = (*pState).drawPad + ((*pState).drawSize - previewDim)/2, $
            VIEWPLANE_RECT=[0, 0, previewDim+1]
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_preview, pState

    compile_opt idl2, hidden

    ; Retrieve all of our properties.
    newLayout = WIDGET_INFO((*pState).wLayout, /LIST_SELECT)

    ; Nothing selected in list.
    if (newLayout lt 0) then $
        return

    oLayout = (*pState).oLayouts[newLayout]
    oLayout->GetProperty, GRIDDED=gridded, LOCKGRID=lockGrid

    if (gridded && ~lockGrid) then begin

        ; Retrieve our new # of columns & rows.
        WIDGET_CONTROL, (*pState).wGridCol, GET_VALUE=nCol
        nCol = LONG(nCol)
        WIDGET_CONTROL, (*pState).wGridRow, GET_VALUE=nRow
        nRow = LONG(nRow)

        ; Cache the old # of columns, rows and set our new #.
        oLayout->GetProperty, COLUMNS=cacheCol, ROWS=cacheRow
        oLayout->SetProperty, COLUMNS=nCol, ROWS=nRow

    endif


    oLayout->GetProperty, MAXCOUNT=nViews

    if (nViews eq 0) then $
        nViews = (*pState).nViews



    ; Find the position of each view in the layout and update its viewport.
    data = DBLARR(2,nViews*5)
    textLoc = DBLARR(2, nViews)
    (*pState).oView->GetProperty, DIMENSIONS=previewDim

    for pos=0, nViews-1 do begin
        viewport = oLayout->GetViewport(pos, previewDim)
        x0 = viewport[0]
        x1 = x0 + viewport[2]
        y0 = viewport[1]
        y1 = y0 + viewport[3]
        data[*,pos*5:pos*5+4] = $
            TRANSPOSE([[x0, x1, x1, x0, x0], [y0, y0, y1, y1, y0]])
        textLoc[*,pos] = [x0 + x1, y0 + y1]/2
    endfor


    ; Restore the old # of columns, rows.
    if (gridded && ~lockGrid) then $
        oLayout->SetProperty, COLUMNS=cacheCol, ROWS=cacheRow

    ; Create the preview boxes.
    polylines = [LONARR(1,nViews)+5, LINDGEN(5, nViews)]
    (*pState).oPolygon->SetProperty, DATA=data, POLYGONS=polylines
    (*pState).oPolyline->SetProperty, DATA=data, POLYLINES=polylines
    (*pState).oText->SetProperty, LOCATIONS=textLoc, $
        STRINGS=STRTRIM(LINDGEN(nViews)+1, 2)

    (*pState).oDraw->Erase, COLOR=(*pState).faceColor
    (*pState).oDraw->Draw
end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_checkvalue, event

    compile_opt idl2, hidden

    if (TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KBRD_FOCUS') then $
        if (event.enter eq 1) then return

    ; Retrieve all of our properties.
    WIDGET_CONTROL, event.id, GET_VALUE=newVal, GET_UVALUE=valueState

    minVal = valueState.min_val
    prevVal = valueState.curr_val

    ; Make sure it is a valid number, and is within range.
    ON_IOERROR, illegal
    newVal = LONG(newVal)
    if (newVal lt minVal) || (newVal eq prevVal) then $
        goto, illegal

    valueState.curr_val = newVal
    WIDGET_CONTROL, event.id, $
        SET_VALUE=STRTRIM(newVal,2), SET_UVALUE=valueState

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    IDLitwdWindowLayout_update_dimensions, pState
    IDLitwdWindowLayout_preview, pState

    ; We're done.
    return

illegal:
    WIDGET_CONTROL, event.id, $
        SET_VALUE=STRTRIM(prevVal,2)

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_autoResize, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    ; If auto resize is turned on, desensitize the dims.
    autoResize = WIDGET_INFO((*pState).wAutoResize, /BUTTON_SET)

    WIDGET_CONTROL, (*pState).wDim0, SENSITIVE=~autoResize
    WIDGET_CONTROL, (*pState).wDim1, SENSITIVE=~autoResize

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_apply, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    (*pState).success = 1

    WIDGET_CONTROL, (*pState).wDim0, GET_VALUE=xDim
    WIDGET_CONTROL, (*pState).wDim1, GET_VALUE=yDim
    autoResize = WIDGET_INFO((*pState).wAutoResize, /BUTTON_SET)
    WIDGET_CONTROL, (*pState).wGridCol, GET_VALUE=setColumn
    WIDGET_CONTROL, (*pState).wGridRow, GET_VALUE=setRow
    newLayout = WIDGET_INFO((*pState).wLayout, /LIST_SELECT) > 0

    (*pState).layoutIndex = newLayout
    (*pState).viewColumns = LONG(setColumn)
    (*pState).viewRows = LONG(setRow)
    (*pState).virtualWidth = xDim
    (*pState).virtualHeight = yDim
    (*pState).autoResize = autoResize

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_draw, event

    compile_opt idl2, hidden

    ; Just an expose event.
    if (event.type ne 4) then $
        return

    ; For some reason just doing a simple redraw doesn't work properly,
    ; and you get slight shifting of the View. So instead, just refresh
    ; the entire preview.
    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState
    IDLitwdWindowLayout_preview, pState

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_ok, event

    compile_opt idl2, hidden

    IDLitwdWindowLayout_apply, event
    WIDGET_CONTROL, event.top, /DESTROY

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_cancel, event

    compile_opt idl2, hidden

    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_layout, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    ; Retrieve all of our properties.
    newLayout = WIDGET_INFO((*pState).wLayout, /LIST_SELECT)

    if (newLayout ge 0) then begin
        oLayout = (*pState).oLayouts[newLayout]
        oLayout->GetProperty, GRIDDED=gridded, LOCKGRID=lockGrid

        WIDGET_CONTROL, (*pState).wGridBox, $
            SENSITIVE=(gridded and (lockGrid ne 1))

        if (gridded) then begin
            ; Cache the old # of columns, rows and set our new #.
            oLayout->GetProperty, COLUMNS=nCol, ROWS=nRow
            ; Set our new # of columns & rows in the widget.
            WIDGET_CONTROL, (*pState).wGridCol, GET_UVALUE=valueState
            valueState.curr_val = nCol
            WIDGET_CONTROL, (*pState).wGridCol, SET_VALUE=STRTRIM(nCol, 2), $
                SET_UVALUE=valueState
            WIDGET_CONTROL, (*pState).wGridRow, GET_UVALUE=valueState
            valueState.curr_val = nRow
            WIDGET_CONTROL, (*pState).wGridRow, SET_VALUE=STRTRIM(nRow, 2), $
                SET_UVALUE=valueState

        endif
    endif

    IDLitwdWindowLayout_preview, pState

end


;-------------------------------------------------------------------------
pro IDLitwdWindowLayout_event, event

    compile_opt idl2, hidden

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        ; needed to avoid flashing on Windows
        'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

        else:

    endcase

end


;-------------------------------------------------------------------------
; Purpose:
;   Create the window layout widget.
;
; Result:
;   Returns 1 if the layout or dimensions were changed.
;   Returns 0 if nothing was changed, or the dialog was cancelled.
;
; Arguments:
;   None.
;
; Keywords:
;   GROUP_LEADER: Set this to the widget ID of the group leader.
;
;   TITLE: Set this to a string giving the window title.
;
;   VALUE: Set this keyword to the Window object reference.
;
;   All other keywords are passed to the top-level widget base.
;
function IDLitwdWindowLayout, $
    N_VIEWS=nViews, $
    GROUP_LEADER=groupLeader, $
    LAYOUT_INDEX=layoutIndex, $
    LAYOUTS=oLayouts, $
    AUTO_RESIZE=autoResize, $
    VIEW_COLUMNS=viewColumns, $
    VIEW_ROWS=viewRows, $
    VIRTUAL_WIDTH=virtualWidth, $
    VIRTUAL_HEIGHT=virtualHeight, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    nLayouts = N_ELEMENTS(oLayouts)
    ; Retrieve the names of all the layouts to create droplist.
    layoutNames = STRARR(nLayouts)
    for i=0,nLayouts-1 do begin
        if (OBJ_VALID(oLayouts[i])) then begin
            oLayouts[i]->GetProperty, NAME=name
            layoutNames[i] = name
        endif
    endfor


    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdWinLayout:Title')


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
        EVENT_PRO='IDLitwdWindowLayout_event', $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        /TAB_MODE, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        /TLB_KILL_REQUEST, $  ; needed to avoid flashing on Windows
        _EXTRA=_extra)


    wBase1 = WIDGET_BASE(wBase, /ROW, XPAD=0, YPAD=0, SPACE=20)
    wLeft = WIDGET_BASE(wBase1, /COLUMN, SPACE=2)
    wRight = WIDGET_BASE(wBase1, /COLUMN)


    ; Window dimensions.
    wLabel = WIDGET_LABEL(wLeft, VALUE= $
                          IDLitLangCatQuery('UI:wdWinLayout:Dims'), $
                          /ALIGN_LEFT)

    wBaseDim = WIDGET_BASE(wLeft, SPACE=2, XPAD=0, YPAD=0, ROW=2, /GRID)
    wLabel = WIDGET_LABEL(wBaseDim, $
                          VALUE=IDLitLangCatQuery('UI:wdWinLayout:Width'))
    wDim0 = WIDGET_TEXT(wBaseDim, $
        /EDITABLE, $
        EVENT_PRO='IDLitwdWindowLayout_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UVALUE={MIN_VAL: 1, $
            CURR_VAL: LONG(virtualWidth)}, $
        VALUE=STRTRIM(LONG(virtualWidth),2), $
        XSIZE=8)
    wLabel = WIDGET_LABEL(wBaseDim, $
                          VALUE=IDLitLangCatQuery('UI:wdWinLayout:Height'))
    wDim1 = WIDGET_TEXT(wBaseDim, $
        /EDITABLE, $
        EVENT_PRO='IDLitwdWindowLayout_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UVALUE={MIN_VAL: 1, $
            CURR_VAL: LONG(virtualHeight)}, $
        VALUE=STRTRIM(LONG(virtualHeight),2), $
        XSIZE=8)

    if (autoResize) then begin
        WIDGET_CONTROL, wDim0, SENSITIVE=0
        WIDGET_CONTROL, wDim1, SENSITIVE=0
    endif

    wButBase = WIDGET_BASE(wLeft, /NONEXCLUSIVE, XPAD=0, YPAD=0)
    wAutoResize = WIDGET_BUTTON(wButBase, $
                                VALUE=IDLitLangCatQuery('UI:wdWinLayout:WinResize'), $
        EVENT_PRO='IDLitwdWindowLayout_autoResize')
    if (autoResize) then $
        WIDGET_CONTROL, wAutoResize, /SET_BUTTON

    wDummy = WIDGET_BASE(wLeft, YSIZE=10)
    wLabel = WIDGET_LABEL(wLeft, VALUE= $
                          IDLitLangCatQuery('UI:wdWinLayout:Layout'), $
                          /ALIGN_LEFT)


    ; Layout list.

    wLayout = WIDGET_LIST(wLeft, $
        EVENT_PRO='IDLitwdWindowLayout_layout', $
        VALUE=layoutNames, $
        YSIZE=4)

    WIDGET_CONTROL, wLayout, SET_LIST_SELECT=layoutIndex

    ; Layout grid.
    wDummy = WIDGET_BASE(wLeft, YSIZE=10)

    wGridBox = WIDGET_BASE(wLeft, SPACE=2, XPAD=0, YPAD=0, ROW=2, /GRID)
    wLabel = WIDGET_LABEL(wGridBox, $
                          VALUE=IDLitLangCatQuery('UI:wdWinLayout:Cols'))
    wGridCol = WIDGET_TEXT(wGridBox, $
        /EDITABLE, $
        EVENT_PRO='IDLitwdWindowLayout_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UVALUE={MIN_VAL: 1, $
            CURR_VAL: 1L}, $
        VALUE=STRTRIM(1,2), $
        XSIZE=4)
    wLabel = WIDGET_LABEL(wGridBox, $
                          VALUE=IDLitLangCatQuery('UI:wdWinLayout:Rows'))
    wGridRow = WIDGET_TEXT(wGridBox, $
        /EDITABLE, $
        EVENT_PRO='IDLitwdWindowLayout_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UVALUE={MIN_VAL: 1, $
            CURR_VAL: 1L}, $
        VALUE=STRTRIM(1,2), $
        XSIZE=4)


    ; Draw widget.
    drawSize = 160
    drawPad = 10
    wLabel = WIDGET_LABEL(wRight, $
                          VALUE=IDLitLangCatQuery('UI:wdWinLayout:Preview'), $
                          /ALIGN_LEFT)
    wDraw = WIDGET_DRAW(wRight, GRAPHICS=2, RETAIN=0, $
        EVENT_PRO='IDLitwdWindowLayout_draw', $
        /EXPOSE_EVENTS, $
;        /FRAME, $
        XSIZE=drawSize+2*drawPad, $
        YSIZE=drawSize+2*drawPad)


    ; Button row
    wButtons = WIDGET_BASE(wBase, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO='IDLitwdWindowLayout_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    wCancel = WIDGET_BUTTON(wButtons, $
                            EVENT_PRO='IDLitwdWindowLayout_cancel', $
                            VALUE=IDLitLangCatQuery('UI:CancelPad2'))

;    wApply = WIDGET_BUTTON(wButtons, $
;        EVENT_PRO='IDLitwdWindowLayout_apply', VALUE='Apply')


; Can't do this on Motif because we never get Returns in text widgets.
; Always goes straight to the OK button.
;    WIDGET_CONTROL, wBase, CANCEL_BUTTON=wCancel, DEFAULT_BUTTON=wOk

    faceColor = (WIDGET_INFO(wBase, /SYSTEM_COLORS)).shadow_3d

    WIDGET_CONTROL, wBase, /REALIZE
    WIDGET_CONTROL, wDraw, GET_VALUE=oDraw
    oDraw->Erase, COLOR=faceColor


;    oImage->GetProperty, DIMENSIONS=dimensions

    oPolygon = OBJ_NEW('IDLgrPolygon', COLOR=255+[0,0,0], $
        DEPTH_OFFSET=1)
    oPolyline = OBJ_NEW('IDLgrPolyline', COLOR=[0, 0, 0])
    oText = OBJ_NEW('IDLgrText', $
        ALIGNMENT=0.5, $
        COLOR=faceColor+[0,0,0], $
        /ONGLASS, $
        VERTICAL_ALIGN=0.5)
    oModel = OBJ_NEW('IDLgrModel')
    oModel->Add, oPolyline
    oModel->Add, oPolygon
    oModel->Add, oText

    oView = OBJ_NEW('IDLgrView', $
        COLOR=(WIDGET_INFO(wBase, /SYSTEM_COLORS)).face_3d)
    oView->Add, oModel
    oDraw->SetProperty, GRAPHICS_TREE=oView


    ; Cache my state information within my child.
    pState = PTR_NEW({ $
        wBase: wBase, $
        wLayout: wLayout, $
        wDim0: wDim0, $
        wDim1: wDim1, $
        wAutoResize: wAutoResize, $
        wGridBox: wGridBox, $
        wGridCol: wGridCol, $
        wGridRow: wGridRow, $
        drawSize: drawSize, $
        drawPad: drawPad, $
        faceColor: faceColor, $
        success: 0, $
        oLayouts: oLayouts, $
        oDraw: oDraw, $
        oView: oView, $
        oText: oText, $
        oPolygon: oPolygon, $
        oPolyline: oPolyline, $
        nViews: nViews, $
        layoutIndex: layoutIndex, $
        viewColumns: viewColumns, $
        viewRows: viewRows, $
        autoResize: autoResize, $
        virtualWidth: virtualWidth, $
        virtualHeight: virtualHeight})

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=pState

    IDLitwdWindowLayout_update_dimensions, pState
    IDLitwdWindowLayout_layout, $
        {ID: wLayout, TOP: wBase, HANDLER: wLayout, $
        INDEX: layoutIndex, CLICKS: 1}

    ; Fire up the xmanager.
    XMANAGER, 'IDLitwdWindowLayout', wBase, $
        NO_BLOCK=0, EVENT_HANDLER='IDLitwdWindowLayout_event'

    OBJ_DESTROY, oView

    success = (*pState).success

    if (success) then begin
        layoutIndex = (*pState).layoutIndex
        viewColumns = (*pState).viewColumns
        viewRows = (*pState).viewRows
        autoResize = (*pState).autoResize
        virtualWidth = (*pState).virtualWidth
        virtualHeight = (*pState).virtualHeight
    endif

    PTR_FREE, pState

    return, success
end

