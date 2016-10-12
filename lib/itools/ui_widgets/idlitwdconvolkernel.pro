; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdconvolkernel.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdConvolKernel
;
; PURPOSE:
;   This function implements the convolution kernel dialog.
;
; CALLING SEQUENCE:
;   IDLitwdConvolKernel
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
pro IDLitwdConvolKernel_callback, wBase, strID, messageIn, component

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return
    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state

    IDLitwdConvolKernel_UpdateDraw, state
end


;-------------------------------------------------------------------------
function IDLitwdConvolKernel_GetKernel, wTable, minx, maxx, miny, maxy

    compile_opt idl2, hidden

    WIDGET_CONTROL, wTable, GET_VALUE=kernel

    mask = (kernel ne 0)
    xmask = WHERE(TOTAL(mask, 2) gt 0, nx)
    ymask = WHERE(TOTAL(TEMPORARY(mask), 1) gt 0, ny)
    minx = MIN(xmask,MAX=maxx)
    miny = MIN(ymask,MAX=maxy)

    if ((nx eq 0) or (ny eq 0)) then $
        return, [0]

    return, kernel[minx: maxx, miny: maxy]
end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_UpdateDraw, state

    compile_opt idl2, hidden

    ; Retrieve the operation properties.
    state.oOperation->GetProperty, CENTER=isCenter, KERNEL=kernel, $
        NCOLUMNS=nx, NROWS=ny
    tx = nx > state.tableSize
    ty = ny > state.tableSize
    kernelExpand = MAKE_ARRAY(tx, ty, TYPE=SIZE(kernel, /TYPE))
    kernelExpand[((tx - nx + 1)/2)>0, ((ty - ny + 1)/2)>0] = kernel

    ; Change to the new table size.
    WIDGET_CONTROL, state.wTable, TABLE_XSIZE=tx, TABLE_YSIZE=ty

    ; Insert the new kernel.
    WIDGET_CONTROL, state.wTable, /ALIGNMENT, $
        SET_VALUE=kernelExpand, /NO_COPY

    ; Update the table labels.
    isOneDim = WIDGET_INFO(state.wOneDim, /BUTTON_SET)

    kernel = IDLitwdConvolKernel_GetKernel(state.wTable, $
        minx, maxx, miny, maxy)
    nx = N_ELEMENTS(kernel[*,0])
    ny = N_ELEMENTS(kernel[0,*])

    WIDGET_CONTROL, state.wTable, GET_VALUE=table
    ncol = N_ELEMENTS(table[*,0])
    nrow = N_ELEMENTS(table[0,*])

    if (isOneDim) then begin
        ny = 1
        miny += (maxy - miny)/2
        maxy = miny
;        nrow = 1
    endif

    ; If centered, then subtract the offset from the labels.
    offset = [minx, miny]
    if (isCenter) then $
        offset += ([nx, ny] - 1)/2

    columnLabels = STRTRIM(LINDGEN(ncol) - offset[0], 2)
    rowLabels = STRTRIM(LINDGEN(nrow) - offset[1], 2)
    view = isCenter ? [ncol-state.tableSize,nrow-state.tableSize]/2 : [0,0]

    ; Set the new labels.
    WIDGET_CONTROL, state.wTable, $
        COLUMN_LABELS=columnLabels, ROW_LABELS=rowLabels

    ; If we don't need to reset selection then return.
    if KEYWORD_SET(noSelect) then $
        return

    ; Adjust the table selection and view to match the Center flag.
    ; This must be done in 2 stages because of a Motif bug.
    WIDGET_CONTROL, state.wTable, $
        SET_TABLE_SELECT=offset[[0,1,0,1]]

    WIDGET_CONTROL, state.wTable, $
        SET_TABLE_VIEW=isCenter ? [ncol-state.tableSize,nrow-state.tableSize]/2 : [0,0]


;    vertColors = BYTE(kernel/MAX(kernel)*255)
;    vertColors = REFORM(vertColors, 1, N_ELEMENTS(vertColors))

    ; If one-dimensional flag is set, then only keep the middle row of
    ; the kernel.
    isOneDim = WIDGET_INFO(state.wOneDim, /BUTTON_SET)
    if (WIDGET_INFO(state.wOneDim, /BUTTON_SET)) then $
        kernel = kernel[*, N_ELEMENTS(kernel[0,*])/2]

    nx = N_ELEMENTS(kernel[*,0])
    ny = N_ELEMENTS(kernel[0,*])


    ; Expand kernel from 1D into a 2D array so we can visualize it.
    if (nx eq 1) then begin
        kernel = REBIN(kernel, 2, ny)
        nx = 2
    endif
    if (ny eq 1) then begin
        kernel = REBIN(kernel, nx, 2)
        ny = 2
    endif


    ; Change the appropriate table cells to blank.
    if ((nx le state.tableSize) || (ny le state.tableSize)) then begin
        ; Note that for 1D kernels ny is 1, and so we will always
        ; end up inside this "if".
        WIDGET_CONTROL, state.wTable, /TABLE_BLANK
        y0 = miny
        y1 = maxy
        if (isOneDim) then begin
            y0 += (y1 - y0)/2
            y1 = y0
        endif
        WIDGET_CONTROL, state.wTable, TABLE_BLANK=0, $
            USE_TABLE_SELECT=[minx, y0, maxx, y1]
    endif else $
        WIDGET_CONTROL, state.wTable, TABLE_BLANK=0


    toobig = (nx*ny gt 400)
    xc = [-0.5, 1d/nx]
    yc = [-0.5, 1d/ny]
    mx = MAX(ABS(kernel))
    zc = [-0.15, (mx gt 0) ? 1d/mx : 1]
    maxkern = MAX(kernel, MIN=minkern)

    ; Reverse the Y dimension of the kernel view,
    ; to match how it looks in the table.
    kernel = REVERSE(kernel, 2)


    if (maxkern ge 0) then begin
        state.oSurface1->SetProperty, $
            DATAZ=(kernel > 0), $
;            DATAZ=(kernel > 0) + (kernel lt 0)*1d-5, $
            HIDE=0, $
            SHADING=toobig, $
            /SHOW_SKIRT, $
            STYLE=toobig ? 2 : 6, $
            XCOORD_CONV=xc, $
            YCOORD_CONV=yc, $
            ZCOORD_CONV=zc
    endif else begin
        state.oSurface1->SetProperty, /HIDE, DATAZ=FLTARR(2,2)
    endelse

    if (minkern lt 0) then begin
        state.oSurface2->SetProperty, $
            DATAZ=(-kernel > 0), $
;            DATAZ=((-kernel) > 0) + (kernel gt 0)*1d-5, $
            HIDE=0, $
            SHADING=toobig, $
            /SHOW_SKIRT, $
            STYLE=toobig ? 2 : 6, $
            XCOORD_CONV=xc, $
            YCOORD_CONV=yc, $
            ZCOORD_CONV=[zc[0], -zc[1]]
    endif else begin
        state.oSurface2->SetProperty, /HIDE, DATAZ=FLTARR(2,2)
    endelse

    state.oWindow->Draw

end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_draw, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Just an expose event.
    if (event.type eq 4) then begin
        state.oWindow->Draw
        return
    endif

    if (state.oTrackball->Update(event, TRANSFORM=transform)) then begin
        state.oModel->GetProperty, TRANSFORM=currentTransform
        state.oModel->SetProperty, TRANSFORM=currentTransform # transform
        state.oWindow->Draw
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; Retrieve all of our properties.
    isOneDim = WIDGET_INFO(state.wOneDim, /BUTTON_SET)
    state.oOperation->SetProperty, ONE_DIMENSIONAL=isOneDim

    ; Mark success.
    *state.pResult = 1

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_cancel, event

    compile_opt idl2, hidden

    ; Do not mark success. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_dimension, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ; If switching to 1D, reset the model transform.
    if (WIDGET_INFO(state.wOneDim, /BUTTON_SET)) then begin
        ; Cache our current transform matrix.
        state.oModel->GetProperty, TRANSFORM=transform
        state.oModel->SetProperty, UVALUE=transform
        state.oModel->Reset
        state.oModel->Rotate, [1, 0, 0], -90
    endif else begin
        state.oModel->GetProperty, UVALUE=transform
        state.oModel->SetProperty, TRANSFORM=transform
    endelse

    IDLitwdConvolKernel_UpdateDraw, state
end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_table, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case (event.type) of

        0: begin   ; WIDGET_TABLE_CH
            if (event.ch ne 13b) then $
                return
            ; Update the widgets.
            kernel = IDLitwdConvolKernel_GetKernel(state.wTable)
            state.oOperation->SetProperty, KERNEL=kernel
            WIDGET_CONTROL, state.wProp, /REFRESH
            IDLitwdConvolKernel_UpdateDraw, state

           end

        7: begin
            ; Set the width of the row-header column.
            WIDGET_CONTROL, state.wTable, COLUMN_WIDTHS=event.width, $
                USE_TABLE_SELECT=[-1,0,-1,0]
            ; Set the rest of the widths.
            WIDGET_CONTROL, state.wTable, COLUMN_WIDTHS=event.width
           end


        else:

    endcase
end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_killnotify, wChild

    compile_opt idl2, hidden

    WIDGET_CONTROL, wChild, GET_UVALUE=state

    ; This will also remove ourself as an observer for all subjects.
    state.oUI->UnRegisterWidget, state.idSelf

    OBJ_DESTROY, state.oTrackball

end


;-------------------------------------------------------------------------
pro IDLitwdConvolKernel_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        ; Needed to prevent flashing on Windows.
        'WIDGET_KILL_REQUEST': IDLitwdConvolKernel_cancel, event

        'WIDGET_BASE': begin     ; Resize event

            ; Compute the change in width and height of the base widget.
            deltaX = event.x - state.x
            deltaY = event.y - state.y

            ; Retrieve the new base size and cache it.
            geom = WIDGET_INFO(state.wBase, /GEOMETRY)
            state.x = geom.xsize
            state.y = geom.ysize
            WIDGET_CONTROL, child, SET_UVALUE=state

            end

        else:
    endcase

end


;-------------------------------------------------------------------------
;
; CENTER: Set this keyword to zero to turn off convolution centering.
;     The default is /CENTER.
;
; EDGE: This keyword specified edge-handling for the convolution.
;     Possible values are:
;         0: Zero result at the array edge.
;         1: Wrap the array edges   (this is the default).
;         2: Repeat values at the array edge.
;         3: Zero pad at the array edge.
;
; FILTER_NAME: Set this keyword to one of the possible kernel types.
;     This keyword is ignored if VALUE is passed in.
;
; NX: If FILTER_NAME is set to a valid kernel type, then set this keyword
;     to the number of columns in the filter.
;
; NY: If FILTER_NAME is set to a valid kernel type, then set this keyword
;     to the number of rows in the filter.
;
; SCALE: Set this keyword to the scale factor for the convolution.
;     If this keyword is not specified or is zero, then automatic scaling
;     will be enabled.
;
; SHOW_DIALOG: Set this keyword to zero to turn off the "Show Dialog" button.
;     The default is /SHOW_DIALOG.
;
; VALUE: Set this keyword to the kernel array. If this keyword is set,
;     then FILTER_NAME, NX, and NY are ignored, and the type is set
;     to "User-defined".
;
function IDLitwdConvolKernel, oUI, oOperation, $
    GROUP_LEADER=groupLeaderIn, $
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdConvKern:Title')


    ; Is there a group leader, or do we create our own?
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(groupLeader, /VALID)


    ; We are doing this modal for now.
    if (~hasLeader) then begin
        wDummy = WIDGET_BASE(MAP=0)
        groupLeader = wDummy
        hasLeader = 1
    endif

    ; Create our floating base.
    wBase = WIDGET_BASE( $
        /COLUMN, $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, /MODAL, $
        EVENT_PRO='IDLitwdConvolKernel_event', $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        /TLB_KILL_REQUEST_EVENTS, $
        _EXTRA=_extra)


    oOperation->GetProperty, $
        AUTOSCALE=autoscale, $
        CENTER=center, $
        EDGE=edge, $
        FILTER_NAME=filtername, $
        KERNEL=kernel,   $
        ONE_DIMENSIONAL=oneDimensional, $
        SCALE_FACTOR=scale, $
        WITHIN_UI=withinUI

    dims = SIZE(kernel, /DIMENSIONS)
    nx = dims[0]
    ny = (N_ELEMENTS(dims) gt 1) ? dims[1] : 0
    isOneDim = KEYWORD_SET(oneDimensional)

    wRow = WIDGET_BASE(wBase, /ROW)

    wProp = CW_ITPROPERTYSHEET(wRow, oUI, $
        /SUNKEN_FRAME, $
        VALUE=oOperation->GetFullIdentifier(), $
;        SCR_XSIZE=scrXsize, SCR_YSIZE=scrYsize, $
;        XSIZE=xsize, YSIZE=ysize, $
        COMMIT_CHANGES=0)

    ; If we are within a data operation (we have data)
    ; then retrieve the data and see if it is 1D or 2D.
    if (withinUI) then begin
        pData = oOperation->_RetrieveDataPointers( $
            BYTESCALE_MIN=bytsclMin, BYTESCALE_MAX=bytsclMax, $
            ISIMAGE=isImage, $
            DIMENSIONS=dims, $
            PALETTE=palette)
        isOneDim = PTR_VALID(pData[0]) && SIZE(*pData[0], /N_DIM) eq 1
    endif

    wCol = WIDGET_BASE(wRow, /COLUMN, /BASE_ALIGN_CENTER)

    ; Kernel
    wTable = WIDGET_TABLE(wCol, $
        /ALIGNMENT, $
        /ALL_EVENTS, $
        COLUMN_LABELS='', $
        COLUMN_WIDTHS=40, $
        /EDITABLE, $
        EVENT_PRO='IDLitwdConvolKernel_table', $
        /RESIZEABLE_COLUMNS, $
        /SCROLL, $
        ROW_LABELS='', $
        X_SCROLL_SIZE=7, Y_SCROLL_SIZE=7)
    ; Set the width of the row-header column.
    WIDGET_CONTROL, wTable, COLUMN_WIDTHS=40, $
        USE_TABLE_SELECT=[-1,0,-1,0]


    ; One/two dimensional preview.
    wDimRow = WIDGET_BASE(wCol, /ROW, $
        SPACE=1, XPAD=0, YPAD=0, /NONEXCLUSIVE, $
        EVENT_PRO='IDLitwdConvolKernel_dimension')
    wOneDim = WIDGET_BUTTON(wDimRow, VALUE='View 1D slice', $
        SENSITIVE=~withinUI)

    ; Set the appropriate dimension button.
    if isOneDim then $
        WIDGET_CONTROL, wOneDim, /SET_BUTTON


    ; Draw widget.
    xsize = 200
    ysize = 150
    wDraw = WIDGET_DRAW(wCol, GRAPHICS=2, RETAIN=0, $
        EVENT_PRO='IDLitwdConvolKernel_draw', $
        /BUTTON_EVENTS, $
        /EXPOSE_EVENTS, $
        /MOTION_EVENTS, $
        XSIZE=xsize, YSIZE=ysize)

    if (withinUI) then begin
        wPreview = CW_ITOPERATIONPREVIEW(wCol, oUI, VALUE=oOperation)
    endif

    ; Button row
    wButtons = WIDGET_BASE(wBase, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    wOk = WIDGET_BUTTON(wButtons, $
                        EVENT_PRO='IDLitwdConvolKernel_ok', $
                        VALUE=IDLitLangCatQuery('UI:wdConvKern:OK'))

    wCancel = WIDGET_BUTTON(wButtons, $
                            EVENT_PRO='IDLitwdConvolKernel_cancel', $
                            VALUE=IDLitLangCatQuery('UI:wdConvKern:Cancel'))


; Can't do this on Motif because we never get Returns in text widgets.
; Always goes straight to the OK button.
;    WIDGET_CONTROL, wBase, CANCEL_BUTTON=wCancel, DEFAULT_BUTTON=wOk



    oSurface1 = OBJ_NEW('IDLgrSurface', $
        COLOR=[200, 0, 0], $
;        MIN_VALUE=1d-6, $
;        /SHOW_SKIRT, $
        /EXTENDED, STYLE=6)
    oSurface2 = OBJ_NEW('IDLgrSurface', $
        COLOR=[200, 0, 0], $
;        MIN_VALUE=1d-6, $
;        /SHOW_SKIRT, $
        /EXTENDED, STYLE=6)
    oModel = OBJ_NEW('IDLgrModel')
    oModel->Add, oSurface1
    oModel->Add, oSurface2
    ; Rotate to a nice view.
    oModel->Rotate, [1, 0, 0], -90
    oModel->Rotate, [0, 1, 0], 30
    oModel->Rotate, [1, 0, 0], 60
    oModel->GetProperty, TRANSFORM=transform
    oModel->SetProperty, UVALUE=transform
    if (isOneDim) then begin
        oModel->Reset
        oModel->Rotate, [1, 0, 0], -90
    endif
    oView = OBJ_NEW('IDLgrView', ZCLIP=[2,-2])
    oView->Add, oModel
    oLights = OBJ_NEW('IDLgrModel')
    oLights->Add, OBJ_NEW('IDLgrLight', INTENSITY=0.5, TYPE=0)
    oLights->Add, OBJ_NEW('IDLgrLight', LOCATION=[-1, 1, 1], TYPE=1)
    oLights->Add, OBJ_NEW('IDLgrLight', LOCATION=[ 1,-1,-1], TYPE=1)
    oView->Add, oLights
    oTrackball = OBJ_NEW('Trackball', [xsize/2d, ysize/2d], xsize/2d)


    WIDGET_CONTROL, wBase, /REALIZE
    WIDGET_CONTROL, wDraw, GET_VALUE=oWindow
    oWindow->Erase
    oWindow->SetProperty, GRAPHICS_TREE=oView

    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    idSelf = oUI->RegisterWidget(wBase,'ConvolKernel', $
        'idlitwdconvolkernel_callback')

    ; Register for notification messages
    idOperation = oOperation->GetFullIdentifier()
    oUI->AddOnNotifyObserver, idSelf, idOperation


    ; Cache my state information within my child.
    state = { $
        oUI: oUI, $
        idSelf: idSelf, $
        idOperation: idOperation, $
        wBase: wBase, $
        wProp: wProp, $
        wOneDim: wOneDim, $
        wTable: wTable, $
        oOperation: oOperation, $
        oWindow: oWindow, $
        oModel: oModel, $
        oTrackball: oTrackball, $
        oSurface1: oSurface1, $
        oSurface2: oSurface2, $
        tableSize: 7, $
        pResult: PTR_NEW(0)}

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state, $
        KILL_NOTIFY='IDLitwdConvolKernel_killnotify'


    ; Update the widgets.
    IDLitwdConvolKernel_UpdateDraw, state


    ; Fire up the xmanager.
    XMANAGER, 'IDLitwdConvolKernel', wBase, NO_BLOCK=0

    ; Destroy fake top-level base if we created it.
    if (N_ELEMENTS(wDummy)) then $
        WIDGET_CONTROL, wDummy, /DESTROY

    success = *state.pResult
    PTR_FREE, state.pResult

    return, success
end

