; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdcurvefitting.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdCurveFitting
;
; PURPOSE:
;   Curve fitting dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdCurveFitting()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
; Take user-supplied display equation and make prettier by changing
; variable names to italics, replacing hyphens with minus signs, etc.
;
; Assumes that all Hershey format codes in "str" are in lowercase.
;
function IDLitwdCurveFitting_ConvertEqn, str

    compile_opt idl2, hidden

    ; Replace x with italic x.
    str = STRJOIN(STRSPLIT(str, 'x', ESCAPE='\', $
        /EXTRACT, /PRESERVE_NULL), '!3x!x')

    ; Convert capital letters to italics.
    for i=0b, 10b do begin
        substr = STRSPLIT(str, STRING(65b + i), /EXTRACT, /PRESERVE_NULL)
        str = STRJOIN(substr, '!3' + STRING(65b + i) + '!x')
    endfor

    ; Remove redundant !x!5.
    str = STRJOIN(STRSPLIT(str, '(!x!3)', /EXTRACT, /REGEX))

    ; Replace - with math -sign.
    str = STRJOIN(STRSPLIT(str, '-', /EXTRACT), '!9-!x')

    return, str
end


;-------------------------------------------------------------------------
function IDLitwdCurveFitting_RetrieveParams, pState

    compile_opt idl2, hidden

    n = N_ELEMENTS((*pState).wParam)
    param = DBLARR(n)

    for i=0,n-1 do begin
        WIDGET_CONTROL, (*pState).wParam[i], GET_VALUE=param1
        param[i] = param1
    endfor

    return, param
end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_Refresh, pState

    compile_opt idl2, hidden

    WIDGET_CONTROL, (*pState).wModel, GET_UVALUE=models
    index = WIDGET_INFO((*pState).wModel, /DROPLIST_SELECT)


    ; Extract the model structure.
    model = models[index]


    ; New display equation.
    (*pState).oEquation->SetProperty, STRINGS=model.display_eqn
    (*pState).oEqnWin->Draw


    ; Retrieve the parameters.
    param = IDLitwdCurveFitting_RetrieveParams(pState)
    A = param[0]
    B = param[1]
    C = param[2]
    D = param[3]
    E = param[4]
    F = param[5]


    nx = N_ELEMENTS((*pState).xData)
    haveData = nx ge 2

    if (haveData) then begin

        x = (*pState).xData

        ; Perform curve fitting on our actual data.
        (*pState).oCurveFit->SetProperty, MODEL=index, PARAMETERS=param
        success = (*pState).oCurveFit->_CurveFit(x, $
            (*pState).yData, $
            (*pState).measureErrors, yfit, CHISQ=chisq)

        (*pState).oCurveFit->GetProperty, PARAMETERS=param
        ; Fill in the parameter results.
        for i=0,N_ELEMENTS((*pState).wPresult)-1 do begin
            WIDGET_CONTROL, (*pState).wPresult[i], $
                SET_VALUE=STRTRIM(param[i], 2)
        endfor

        y = yfit

        if (success) then begin
          chisqStr = IDLitLangCatQuery('UI:wdCurveFit:ChiSqr')+ $
            ' = ' + STRTRIM(chisq, 2) + ', '+ $
            IDLitLangCatQuery('UI:wdCurveFit:Signif')+' '
            math = CHECK_MATH(/NOCLEAR)
            pdfStr = IDLitLangCatQuery('UI:wdCurveFit:NA')
            CATCH, err
            if (~err && (N_ELEMENTS((*pState).measureErrors) gt 1)) then begin
                pdf = CHISQR_PDF(chisq, nx - (*pState).nparam)
                pdfStr = (pdf gt 0.99) ? $
                  IDLitLangCatQuery('UI:wdCurveFit:OutofRange') : $
                    ('= ' + STRTRIM(FLOAT(pdf*100), 2) + '%')
            endif
            CATCH, /CANCEL
            chisqStr += pdfStr
            ; If no prior exceptions, quietly swallow any here.
            if (math eq 0) then $
                dummy = CHECK_MATH()
        endif else begin
            chisqStr = IDLitLangCatQuery('UI:wdCurveFit:FitFail')
        endelse

    endif else begin

        ; Construct an example dataset.
        n = 1000
        xmin = (*pState).xmin
        xmax = (*pState).xmax
        dx = xmax - xmin
        dx *= 2d^(-(*pState).zoomfactor)
        xmid = (xmin + xmax)/2d
        xmin = xmid - dx/2
        xmax = xmid + dx/2
        x = DINDGEN(n)*(dx/(n-1)) + xmin

;        if (~EXECUTE('y = ' + model.equation)) then $
            return

        chisqStr = ' '

    endelse


    ; Set the new chisq label.
    WIDGET_CONTROL, (*pState).wChisq, SET_VALUE=chisqStr

    ; Find example data range.
    xMin = MIN(x, MAX=xMax, /NAN)
    dx = xMax - xMin
    if (~dx) then dx = 1d

    yMin = MIN(y, MAX=yMax, /NAN)

    ; If no valid data, just use previous Y range.
    ; The plot will be empty, but at least there will be axes.
    if (haveData || ~FINITE(yMin)) then begin
        yMin = (*pState).ymin
        yMax = (*pState).ymax
    endif

    dy = yMax - yMin

    ; If all the same value, just pick a nice range.
    if (~dy) then begin
        yMin -= 0.5
        yMax += 0.5
        dy = 1d
    endif

    ; Cache our new Y range.
    (*pState).ymin = yMin
    (*pState).ymax = yMax

    (*pState).oPlotModel->SetProperty, DATAX=x, DATAY=y

    ; Adjust the view rect to match the data.
    width = 1.5d*dx
    height = 1.3d*dy
    xoffset = xMin - (width - dx)/2d - 0.05d*width
    yoffset = yMin - (height - dy)/2d - 0.04d*height
    (*pState).oView->SetProperty, $
        VIEWPLANE_RECT=[xoffset, yoffset, width, height]


    ; Adjust the plot axis.
    (*pState).oXaxis->SetProperty, $
        LOCATION=[xMin, yMin], $
        RANGE=[xMin, xMax], $
        TICKLEN=height*0.025d
    (*pState).oYaxis->SetProperty, $
        LOCATION=[xMin, yMin], $
        RANGE=[yMin, yMax], $
        TICKLEN=width*0.015d

    (*pState).oWindow->Draw

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_ok, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    (*pState).success = 1

    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_cancel, event

    compile_opt idl2, hidden

    ; Do not cache the results. Just destroy ourself.
    WIDGET_CONTROL, event.top, /DESTROY
end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_eqndraw, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    ; Handle expose events.
    if (event.type eq 4) then begin
        (*pState).oEqnwin->Draw
        return
    endif

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_draw, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    ; Handle expose events.
    if (event.type eq 4) then begin
        (*pState).oWindow->Draw
        return
    endif

;    ; See if there was a translation.
;    if ((*pState).oTrackball->Update(event, $
;        TRANSFORM=transform, /TRANSLATE)) then begin
;
;        ; Convert from normalized window coords to data coords.
;        (*pState).oView->GetProperty, VIEWPLANE_RECT=viewplane
;        dx = transform[3,0]*viewplane[2]
;
;        ; Only allow horizontal translation.
;        if (dx eq 0) then $
;            return
;
;        ; Adjust the X range and redraw.
;        (*pState).xmin += dx
;        (*pState).xmax += dx
;        IDLitwdCurveFitting_Refresh, pState
;    endif

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_zoomin, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState
    (*pState).zoomfactor++
    IDLitwdCurveFitting_Refresh, pState

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_zoomout, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState
    (*pState).zoomfactor--
    IDLitwdCurveFitting_Refresh, pState

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_parameter, event

    compile_opt idl2, hidden

    ON_IOERROR, NULL

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState
    IDLitwdCurveFitting_Refresh, pState

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_model, event, REFRESH=refresh

    compile_opt idl2, hidden

    ; Verify that the current droplist select matches the event.
    index = WIDGET_INFO(event.id, /DROPLIST_SELECT)
    if (index ne event.index) then $
        WIDGET_CONTROL, event.id, SET_DROPLIST_SELECT=event.index

    child = WIDGET_INFO(event.top, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    WIDGET_CONTROL, (*pState).wModel, GET_UVALUE=models
    model = models[event.index]
    (*pState).nparam = model.nparam

    ; Sensitize/desensitize the parameter fields.
    for i=0,N_ELEMENTS((*pState).wParam)-1 do begin
        ; Sensitive or not?
        WIDGET_CONTROL, (*pState).wParam[i], $
            SENSITIVE=(i lt (*pState).nparam)
    endfor

    IDLitwdCurveFitting_Refresh, pState

end


;-------------------------------------------------------------------------
pro IDLitwdCurveFitting_event, event

    compile_opt idl2, hidden

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=pState

    case TAG_NAMES(event, /STRUCTURE_NAME) of

        'WIDGET_KILL_REQUEST': begin
            ; Need to kill manually to prevent flashing on Windows.
            WIDGET_CONTROL, event.top, /DESTROY
            end

        else: ; do nothing

    endcase

end


;-------------------------------------------------------------------------
function IDLitwdCurveFitting, oCurveFit, $
    GROUP_LEADER=groupLeaderIn, $
    MEASURE_ERRORS=measureErrors, $
    TITLE=titleIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    myname = 'IDLitwdCurveFitting'

    if (N_PARAMS() ne 1) then $
        MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

    oCurveFit->GetProperty, $
        DATAX=xData, $
        DATAY=yData, $
        MEASURE_ERRORS=measureErrors, $
        MODEL=model, $
        PARAMETERS=parameters

    ; Did the user input data?
    nx = N_ELEMENTS(xData)
    ny = N_ELEMENTS(yData)
    if (nx lt 2) || (nx ne ny) then $
        MESSAGE, IDLitLangCatQuery('UI:wdCurveFit:BadInput')

    haveData = (nx ge 2) && (nx eq ny)

    haveErrors = N_ELEMENTS(measureErrors) eq ny

    ; Default title.
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
        IDLitLangCatQuery('UI:wdCurveFit:Title')

    ; Is there a group leader, or do we create our own?
    groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
    hasLeader =  WIDGET_INFO(groupLeader, /VALID)

    ; We are doing this modal for now.
    if (not hasLeader) then begin
        wTopDummy = WIDGET_BASE(MAP=0)
        groupLeader = wTopDummy
        hasLeader = 1
    endif else $
        wTopDummy = 0L

    ; Create our floating base.
    wBase = WIDGET_BASE( $
        /COLUMN, $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, /MODAL, $
        EVENT_PRO=myname+'_event', $
        /TLB_KILL_REQUEST_EVENTS, $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        _EXTRA=_extra)


    wDrawRow = WIDGET_BASE(wBase, /ROW, SPACE=15, XPAD=0, MAP=0)
    wAllOptions = WIDGET_BASE(wDrawRow, /COLUMN, XPAD=0, YPAD=0)


    ; Retrieve all of our current models.
    models = oCurveFit->GetModels()


    wLabel = WIDGET_LABEL(wAllOptions, /ALIGN_LEFT, $
        VALUE=IDLitLangCatQuery('UI:wdCurveFit:Model'))
    wModel = WIDGET_DROPLIST(wAllOptions, $
        EVENT_PRO=myname+'_model', $
        VALUE=models.name, UVALUE=models, /FLAT)

    ; Default filter.
    setmodel = (N_ELEMENTS(model) eq 1) ? model : 0

    WIDGET_CONTROL, wModel, SET_DROPLIST_SELECT=setmodel


    ; Parameter fields.
    wDummy = WIDGET_LABEL(wAllOptions, VALUE=' ')
    wLabel = WIDGET_LABEL(wAllOptions, /ALIGN_LEFT, $
        VALUE=IDLitLangCatQuery('UI:wdCurveFit:InitParams'))

    nParam = 6
    param = [IDLitLangCatQuery('UI:wdCurveFit:Param1'), $
             IDLitLangCatQuery('UI:wdCurveFit:Param2'), $
             IDLitLangCatQuery('UI:wdCurveFit:Param3'), $
             IDLitLangCatQuery('UI:wdCurveFit:Param4'), $
             IDLitLangCatQuery('UI:wdCurveFit:Param5'), $
             IDLitLangCatQuery('UI:wdCurveFit:Param6')]

    ; Default parameter values.
    parameters = DBLARR(nParam) + 0.5d

    ; Check for PARAMETERS keyword. Allow fewer params than max.
    for i=0,N_ELEMENTS(parametersIn)-1 do $
        parameters[i] = parametersIn[i]

    wParam = LONARR(nParam)   ; Cache widget id's
    wPresult = LONARR(nParam)   ; Cache widget id's

    for i=0,nParam-1 do begin
        wRow = WIDGET_BASE(wAllOptions, /ROW, $
            EVENT_PRO=myname+'_model', $
            SPACE=5, XPAD=0, YPAD=0)
        wParam[i] = CW_ITUPDOWNFIELD(wRow, $
            EVENT_PRO=myname+'_parameter', $
            LABEL=param[i] + ':', $
            VALUE=parameters[i], $
            XLABELSIZE=20)  ; get alignment to work
        wPresult[i] = WIDGET_TEXT(wRow, XSIZE=10)
    endfor


    ; Draw widget.
    wDrawCol = WIDGET_BASE(wDrawRow, /COLUMN, XPAD=0, YPAD=0)
    xsize = 360
    ysize = 200
    wEqnDraw = WIDGET_DRAW(wDrawCol, $
        EVENT_PRO=myname+'_eqndraw', $
        /EXPOSE_EVENTS, $
        GRAPHICS=2, RETAIN=0, $
        XSIZE=xsize, YSIZE=40)
    wDraw = WIDGET_DRAW(wDrawCol, $
;        BUTTON_EVENTS=1-haveData, MOTION_EVENTS=1-haveData, $
        EVENT_PRO=myname+'_draw', $
        /EXPOSE_EVENTS, $
        GRAPHICS=2, $
        RETAIN=0, $
        XSIZE=xsize, YSIZE=ysize)


;    wDrawOptions = WIDGET_BASE(wDrawCol, /ROW, XPAD=0, YPAD=0)
;    wToolbar = WIDGET_BASE(wDrawOptions, /ROW, /TOOLBAR, SPACE=0)
;    bitmap = FILEPATH('zoom_in.bmp', SUBDIR=['resource','bitmaps'])
;    wZoomIn = WIDGET_BUTTON(wToolbar, /BITMAP, $
;        EVENT_PRO=myname+'_zoomin', $
;        TOOLTIP='Zoom in', $
;        VALUE=bitmap)
;    bitmap = FILEPATH('zoom_out.bmp', SUBDIR=['resource','bitmaps'])
;    wZoomOut = WIDGET_BUTTON(wToolbar, /BITMAP, $
;        EVENT_PRO=myname+'_zoomout', $
;        TOOLTIP='Zoom out', $
;        VALUE=bitmap)

    wChisq = WIDGET_LABEL(wDrawCol, /SUNKEN, XSIZE=xsize - 4)

    ; Button row
    wButtons = WIDGET_BASE(wDrawCol, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)

    wOk = WIDGET_BUTTON(wButtons, $
        EVENT_PRO=myname+'_ok', VALUE=IDLitLangCatQuery('UI:OK'))

    wCancel = WIDGET_BUTTON(wButtons, $
                            EVENT_PRO=myname+'_cancel', $
                            VALUE='  '+IDLitLangCatQuery('UI:Cancel')+'  ')
    WIDGET_CONTROL, wBase, CANCEL_BUTTON=wCancel


    ; Equation text object.
    oEquation = OBJ_NEW('IDLgrText', $
        ALIGN=0.5, $
        /ENABLE_FORMATTING, $
        LOCATION=[0d,0d,0d], $
        /ONGLASS, $
        VERTICAL_ALIGN=0.5)
    oEqnView = OBJ_NEW('IDLgrView', $
        COLOR=(WIDGET_INFO(wBase, /SYSTEM_COLOR)).face_3d)
    oModel = OBJ_NEW('IDLgrModel')
    oModel->Add, oEquation
    oEqnView->Add, oModel


    ; Example plot plus axes.
    oPlotModel = OBJ_NEW('IDLgrPlot', COLOR=[255,0,0], THICK=2)

    oFont = OBJ_NEW('IDLgrFont', SIZE=8)
    oXaxis = OBJ_NEW('IDLgrAxis', /EXACT, $
        MINOR=0, /TICKDIR)
    oXaxis->GetProperty, TICKTEXT=oText
    oText->SetProperty, FONT=oFont, RECOMPUTE_DIMENSIONS=2

    oYaxis = OBJ_NEW('IDLgrAxis', 1, /EXACT, $
        MINOR=0, /TICKDIR)
    oYaxis->GetProperty, TICKTEXT=oText
    oText->SetProperty, FONT=oFont, RECOMPUTE_DIMENSIONS=2

    oModel = OBJ_NEW('IDLgrModel')

    oModel->Add, oXaxis
    oModel->Add, oYaxis
    oModel->Add, oPlotModel


    ; Add in my plot if necessary.
    if (haveData) then begin
        oMyPlot = OBJ_NEW('IDLgrPlot', DATAX=xData, DATAY=yData)
        oModel->Add, oMyPlot
    endif


    oView = OBJ_NEW('IDLgrView', /DOUBLE, ZCLIP=[2,-2])
    oView->Add, oModel

;    oTrackball = OBJ_NEW('Trackball', [xsize/2d, ysize/2d], xsize/2d)


    ; Default y plot range.
    if (haveData) then begin
        ymin = MIN(yData, MAX=ymax)
    endif else begin
        ymin = -0.5d
        ymax = -0.5d
    endelse


    ; Realize the widget, retrieve the window objrefs, and erase them.
    WIDGET_CONTROL, wBase, /REALIZE
    WIDGET_CONTROL, wEqnDraw, GET_VALUE=oEqnWin
    oEqnWin->Erase, COLOR=(WIDGET_INFO(wBase, /SYSTEM_COLOR)).face_3d
    oEqnWin->SetCurrentCursor, 'Arrow'
    oEqnWin->SetProperty, GRAPHICS_TREE=oEqnView
    WIDGET_CONTROL, wDraw, GET_VALUE=oWindow
    oWindow->Erase
    oWindow->SetCurrentCursor, haveData ? 'Arrow' : 'SIZE_EW'
    oWindow->SetProperty, GRAPHICS_TREE=oView


    ; Cache my state information within my child.
    state = { $
        wBase: wBase, $
        wModel: wModel, $
        wParam: wParam, $
        wPresult: wPresult, $
        wChisq: wChisq, $
        oEqnWin: oEqnWin, $
        oWindow: oWindow, $
        oView: oView, $
        oEquation: oEquation, $
        oPlotModel: oPlotModel, $
        oXaxis: oXaxis, $
        oYaxis: oYaxis, $
;        oTrackball: oTrackball, $
        oCurveFit: oCurveFit, $
        xmin: -1d, $
        xmax: 1d, $
        ymin: ymin, $
        ymax: ymax, $
        zoomfactor: 0L, $
        xData: haveData ? xData : -1, $
        yData: haveData ? yData : -1, $
        measureErrors: haveErrors ? measureErrors : -1, $
        nparam: 0L, $
        success: 0b}

    wChild = WIDGET_INFO(wBase, /CHILD)
    pState = PTR_NEW(state)
    WIDGET_CONTROL, wChild, SET_UVALUE=pState

    WIDGET_CONTROL, wDrawRow, /MAP

    IDLitwdCurveFitting_model, $
        {ID: wModel, TOP: wBase, HANDLER: wModel, INDEX: setmodel}

    ; Fire up the xmanager.
    XMANAGER, myname, wBase, $
        NO_BLOCK=0, EVENT_HANDLER=myname+'_event'


    ; Destroy fake top-level base if we created it.
    if (WIDGET_INFO(wTopDummy, /VALID)) then $
        WIDGET_CONTROL, wTopDummy, /DESTROY

    OBJ_DESTROY, oFont
    success = (*pState).success
    PTR_FREE, pState

    return, success
end


