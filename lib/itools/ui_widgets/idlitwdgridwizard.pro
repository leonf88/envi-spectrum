; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdgridwizard.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdGridWizard
;
; PURPOSE:
;   This function implements the Grid Wizard dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdGridWizard()
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
function itgw_print, x

    compile_opt idl2, hidden

    return, STRTRIM(STRING(x, FORMAT='(g20.4)'), 2)
end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_help, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    oTool = (*pState).oTool
    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return
    oHelp->HelpTopic, oTool, 'iToolsGridWizard'

end


;-------------------------------------------------------------------------
; Purpose:
;   Construct all object graphics and model/view.
;   Returns the newly created IDLgrView objref.
;
function idlitwdgridwizard_createobjects, pState

    compile_opt idl2, hidden

    ; Set up helper objects and store in container for cleanup.
    (*pState).oContainer = OBJ_NEW('IDL_Container')

    oFont = OBJ_NEW('IDLgrFont', 'Courier', SIZE=9)
    (*pState).oContainer->Add, oFont

    oPalette = OBJ_NEW('IDLgrPalette')
    oPalette->Loadct, 33
    (*pState).oContainer->Add, oPalette


    ; Create our view.
    (*pState).oWin->GetProperty, DIMENSIONS=dimensions
    ; Adjust viewplane_rect to account for non-isotropic window dims.
    ratio = dimensions[0]/dimensions[1]
    oView = OBJ_NEW('IDLgrView', VIEWPLANE_RECT=[-ratio,-1,2*ratio,2])
    (*pState).oWin->SetProperty, GRAPHICS_TREE=oView


    ; Create our model.
    oModel = OBJ_NEW('IDLgrModel', NAME='model')
    oView->Add, oModel


    ; X and Y axes.
    oXaxis = OBJ_NEW('IDLgrAxis', 0, /EXACT, NAME='xaxis', $
        MINOR=0, TICKDIR=1)
    oXaxis->GetProperty, TICKTEXT=oText
    oText->SetProperty, FONT=oFont
    oYaxis = OBJ_NEW('IDLgrAxis', 1, /EXACT, NAME='yaxis', $
        MINOR=0, TICKDIR=1)
    oYaxis->GetProperty, TICKTEXT=oText
    oText->SetProperty, FONT=oFont
    oModel->Add, oXaxis
    oModel->Add, oYaxis


    ; Data points (store in polygon so we can do nice points).
    oPoints = OBJ_NEW('IDLgrPolygon', $
        DATA=TRANSPOSE([[(*pState).xData], $
        [(*pState).yData], [(*pState).fData]]), $
        NAME='points', $
        PALETTE=oPalette, $
        STYLE=0, $
        THICK=3, $
        VERT_COLORS=(*pState).colors)
    oModel->Add, oPoints


    ; Data grid.
    oGrid = OBJ_NEW('IDLgrPolygon', $
        NAME='grid', $
        STYLE=0, $
        THICK=1)
    oModel->Add, oGrid


    ; Contour the resulting grid.
    oContour = OBJ_NEW('IDLgrContour', $
        NAME='contour', $
        PALETTE=oPalette)
    oModel->Add, oContour


    ; Search ellipse.
    oEllipse = OBJ_NEW('IDLgrPolyline', $
        NAME='ellipse', $
        THICK=2)
    oModel->Add, oEllipse


    ; Colobar.
    ncolor = N_ELEMENTS((*pState).colors)
    ; Compute a set of evenly spaced values and colors.
    nl = 10 < ncolor
    mn = (*pState).frange[0]
    mx = (*pState).frange[1]
    dz = (mx - mn)/(nl + 1)
    levels = (FINDGEN(nl) + 1)*dz + mn
    colors = BYTSCL(levels, MIN=mn, $
        MAX=mx, TOP=253) + 1b
    oColorbar = OBJ_NEW('IDLgrPolygon', $
        NAME='colorbar', $
        PALETTE=oPalette, $
        STYLE=0, $
        THICK=7, $
        VERT_COLORS=colors)
    oModel->Add, oColorbar


    ; Labels for the colorbar.
    labels = STRING(levels, FORMAT='(G10.2)')

    ; Replace any exponential notation with superscripts.
    for i=0,N_ELEMENTS(labels)-1 do begin
        pos = STRPOS(labels[i], 'E')
        if (pos eq -1) then $
            continue
        exponent = FIX(STRMID(labels[i], pos+1))
        labels[i] = STRMID(labels[i], 0, pos) + 'x10!U' + $
            STRTRIM(exponent, 2)
    endfor
    oLabels = OBJ_NEW('IDLgrText', $
        /ENABLE_FORMATTING, $
        FONT=oFont, $
        NAME='labels', $
        STRINGS=STRTRIM(labels,2), $
        VERTICAL_ALIGN=0.25)
    oModel->Add, oLabels

    return, oView
end


;-------------------------------------------------------------------------
; Purpose:
;   Called each time the grid changes.
;   The first time it is called it will create all objects.
;
pro idlitwdgridwizard_drawsetup, pState, $
    XGRID=xgrid, YGRID=ygrid

    compile_opt idl2, hidden

    (*pState).oWin->SetCurrentCursor, 'ARROW'
    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView

    if (~OBJ_VALID(oView)) then $   ; Create all objects.
        oView = IDLitwdGridWizard_CreateObjects(pState)

    ; Retrieve our object references.
    oXaxis = oView->GetByName('model/xaxis')
    oYaxis = oView->GetByName('model/yaxis')
    oModel = oView->GetByName('model')
    oContour = oView->GetByName('model/contour')
    oColorbar = oView->GetByName('model/colorbar')
    oLabels = oView->GetByName('model/labels')
    oGrid = oView->GetByName('model/grid')


    xdelta = ((*pState).xend - (*pState).xstart)/((*pState).xdim - 1)
    ydelta = ((*pState).yend - (*pState).ystart)/((*pState).ydim - 1)

    xgrid = FINDGEN((*pState).xdim)*xdelta + (*pState).xstart
    ygrid = FINDGEN((*pState).ydim)*ydelta + (*pState).ystart
    x0 = MIN(xgrid, MAX=x1)
    y0 = MIN(ygrid, MAX=y1)


    ; X range
    xr = [x0 < (*pState).range[0], x1 > (*pState).range[2]]
    ; Expand range by a small percent.
    dx = (xr[1] - xr[0])/20.0
    xr = xr + [-dx, dx]

    ; Y range
    yr = [y0 < (*pState).range[1], y1 > (*pState).range[3]]
    ; Expand range by a small percent.
    dy = (yr[1] - yr[0])/20.0
    yr = yr + [-dy, dy]

    fac = 1.6
    dx = (xr[1] - xr[0])
    dy = (yr[1] - yr[0])
    dz = (*pState).frange[1] - (*pState).frange[0]
    xc = (dx eq 0) ? [0,1] : [-0.9 - fac*xr[0]/dx, fac/dx]
    yc = (dy eq 0) ? [0,1] : [-0.75 - fac*yr[0]/dy, fac/dy]
    zc = (dz eq 0) ? [0,1] : [-(*pState).frange[0]/dz, 1/dz]

    ; Set our axis properties.
    oXaxis->SetProperty, LOCATION=[0, yr[0], 0], RANGE=xr, $
        TICKLEN=dy/40
    oYaxis->SetProperty, LOCATION=[xr[0], 0, 0], RANGE=yr, $
        TICKLEN=dx/40

    ; Set the coordinate converts for all the objects.
    oGraphics = oModel->Get(/ALL, COUNT=count)

    for i=0,count-1 do $
        oGraphics[i]->SetProperty, XCOORD_CONV=xc, YCOORD_CONV=yc, $
            ZCOORD_CONV=zc

    oContour->SetProperty, $
        DATA=FLTARR((*pState).xdim, (*pState).ydim), $
        GEOMX=xgrid, GEOMY=ygrid, $
        GEOMZ=FLTARR((*pState).xdim, (*pState).ydim)

    ; Compute offsets for colorbar and labels.
    oColorbar->GetProperty, VERT_COLORS=vc
    nl = N_ELEMENTS(vc)
    xcoord = FLTARR(1,nl) + xr[1] + 0.05*dx
    ycoord = (FINDGEN(1,nl)+0.5)*((yr[1] - yr[0])/nl) + yr[0]
    oColorbar->SetProperty, DATA=[xcoord, ycoord]
    oLabels->SetProperty, $
        LOCATIONS=[xcoord+0.04*dx, ycoord]

    ; Draw the grid locations.
    xgrid2d = REBIN(xgrid, (*pState).xdim, (*pState).ydim)
    ygrid2d = REBIN(TRANSPOSE(ygrid), (*pState).xdim, (*pState).ydim)
    xgrid2d = REFORM(xgrid2d, 1, N_ELEMENTS(xgrid2d), /OVERWRITE)
    ygrid2d = REFORM(ygrid2d, 1, N_ELEMENTS(ygrid2d), /OVERWRITE)
    oGrid->SetProperty, DATA=[xgrid2d, ygrid2d]

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_draw_ellipse, pState

    compile_opt idl2, hidden

    wEllipseValues = WIDGET_INFO((*pState).wColumn3, $
        FIND_BY_UNAME='wEllipseValues')
    sensitive = WIDGET_INFO(wEllipseValues, /SENSITIVE)
    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView
    oEllipse = oView->GetByName('model/ellipse')

    if sensitive then begin
        ellipse = IDLITWDGRIDWIZARD_ELLIPSE( $
            (*pState).search_ellipse[0], $
            (*pState).search_ellipse[1], $
            (*pState).search_ellipse[2])
        meanx = ((*pState).range[0] + (*pState).range[2])/2
        meany = ((*pState).range[1] + (*pState).range[3])/2
        ellipse[0,*] = ellipse[0,*] + meanx
        ellipse[1,*] = ellipse[1,*] + meany
        oEllipse->SetProperty, DATA=ellipse
    endif

    oEllipse->SetProperty, HIDE=1-sensitive

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_draw_contours, pState

    compile_opt idl2, hidden

    ; Assume successful result if min not equal to max.
    mn = MIN(*(*pState).pResult, MAX=mx, /NAN)
    nl = 10
    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView
    oContour = oView->GetByName('model/contour')
    delta = (mx - mn)

    ; Make sure we have a valid data range.
    if (FINITE(delta) && delta) then begin
        dz = delta/(nl + 1)
        levels = (FINDGEN(nl) + 1)*dz + mn
        colors = BYTSCL(levels, MIN=(*pState).frange[0], $
            MAX=(*pState).frange[1], TOP=253) + 1b
        zc = [-mn/delta, 1/delta]
        oContour->SetProperty, $
            C_COLOR=colors, C_VALUE=levels, $
            DATA=*(*pState).pResult, $
            GEOMZ=*(*pState).pResult, $
            HIDE=0, $
            ZCOORD_CONV=zc
    endif else $   ; Invalid data range, hide the contour
        oContour->SetProperty, /HIDE

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_drawrefresh, pState

    compile_opt idl2, hidden

    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView

    if ((*pState).screen eq 3) then begin
        IDLITWDGRIDWIZARD_UPDATE_STATS, pState
        IDLITWDGRIDWIZARD_DRAW_CONTOURS, pState
        IDLITWDGRIDWIZARD_DRAW_ELLIPSE, pState
    endif else begin
        oContour = oView->GetByName('model/contour')
        oContour->SetProperty, /HIDE
    endelse

    oGrid = oView->GetByName('model/grid')
    oGrid->SetProperty, HIDE=((*pState).screen ne 2)

    (*pState).oWin->Draw

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_radians, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState

    (*pState).bRadians = event.select

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_sphere, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState

    (*pState).bSphere = event.select

    wRadians = WIDGET_INFO(event.top, FIND_BY_UNAME='wRadians')
    WIDGET_CONTROL, wRadians, MAP=event.select

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_drawevent, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState

    ; Just an expose event.
    if (event.type eq 4) then begin
        (*pState).oWin->Draw
        return
    endif

    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView
    oPoints = oView->GetByName('model/points')
    oGrid = oView->GetByName('model/grid')
    oContour = oView->GetByName('model/contour')

    result = 0
    oSelect = ((*pState).oWin->Select(oView, [event.x, event.y], $
        DIMENSION=[3,3]))[0]

    if (OBJ_VALID(oSelect)) then begin   ; hit something

        ; Ignore other objects.
        if ((oSelect eq oPoints) || (oSelect eq oGrid) || $
            (oSelect eq oContour)) then begin

            ; Try to pick from data points.
            result = (*pState).oWin->PickData(oView, oSelect, $
                [event.x, event.y], xyz, $
                DIMENSION=[3,3], $
                PICK_STATUS=pickArray)

            if (result eq 1) then begin

                ; First see if the middle selection pixel is set.
                if (pickArray[1,1] eq 1) then begin
                    xyz = xyz[*,1,1]
                endif else begin
                    ; Otherwise just pick the first pixel that was hit.
                    hit = (WHERE(pickArray eq 1))[0]
                    ; We should always get a hit,
                    ; but just in case, default to zero.
                    xyz = (hit ge 0) ? (REFORM(xyz,3,9))[*,hit] : [0,0,0]
                endelse

                x = xyz[0]
                y = xyz[1]

                ; Find the appropriate Z value.
                if (oSelect eq oPoints) then begin
                    name = IDLitLangCatQuery('UI:wdGridWiz:Data')
                    ; Find the x, y coordinates of the closest point.
                    mn = MIN(ABS((*pState).fData - xyz[2]), index)
                    x = (*pState).xData[index]
                    y = (*pState).yData[index]
                    z = (*pState).fData[index]
                endif else if (oSelect eq oContour) then begin
                    name = IDLitLangCatQuery('UI:wdGridWiz:Result')
                    z = xyz[2]
                endif else begin
                    name = IDLitLangCatQuery('UI:wdGridWiz:Grid')
                endelse

            endif
        endif

    endif


    if (result eq 1) then begin

        value = name + '[' + ITGW_PRINT(x) + ', ' + ITGW_PRINT(y)

        if (N_ELEMENTS(z) gt 0) then $
            value += ', ' + ITGW_PRINT(z)

        value += ']'

    endif else $
        value = ''

    WIDGET_CONTROL, (*pState).wXY, SET_VALUE=value + ' '

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_checkvalue, event, dimflag

    compile_opt idl2, hidden

    ; Ignore keyboard "gain focus" events. Just process "lose focus"
    ; or carriage return events.
    if (TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KBRD_FOCUS') then $
        if (event.enter eq 1) then return

    uname = WIDGET_INFO(event.id, /UNAME)
    WIDGET_CONTROL, event.id, GET_VALUE=newval, GET_UVALUE=pState

    isFloat = 1b

    ; Catch any errors converting the value to the appropriate type.
    ON_IOERROR, failed

    ; If this fails, value will be unchanged.
    case uname of

        'Xdim': begin
            isFloat = 0b
            preval = (*pState).xdim
            newval = 4 > LONG(newval)
            (*pState).xdim = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'Ydim': begin
            isFloat = 0b
            preval = (*pState).ydim
            newval = 4 > LONG(newval)
            (*pState).ydim = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'Xstart': begin
            preval = (*pState).xstart
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval <= (*pState).xend
            (*pState).xstart = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'Ystart': begin
            preval = (*pState).ystart
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval <= (*pState).yend
            (*pState).ystart = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'Xend': begin
            preval = (*pState).xend
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval >= (*pState).xstart
            (*pState).xend = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'Yend': begin
            preval = (*pState).yend
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval >= (*pState).ystart
            (*pState).yend = newval
            if (newval ne preval) then begin
                IDLitwdGridWizard_DrawSetup, pState
                IDLitwdGridWizard_DrawRefresh, pState
            endif
            end

        'aniso_ratio': begin
            preval = (*pState).aniso_ratio
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            if (newval le 0) then newval = 1
            newval >= 1e-15
            (*pState).aniso_ratio = newval
            if (newval ne preval) then begin
                IDLITWDGRIDWIZARD_ANISOELLIPSE, pState
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            endif
            end

        'aniso_theta': begin
            preval = (*pState).aniso_theta
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval = -90 > newval < 90
            (*pState).aniso_theta = newval
            if (newval ne preval) then begin
                IDLITWDGRIDWIZARD_ANISOELLIPSE, pState
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            endif
            end

        'search_major': begin
            preval = (*pState).search_ellipse[0]
            newval = FLOAT(newval)
            if (~FINITE(newval) || newval le 0.0) then $
                goto, failed
            (*pState).search_ellipse[0] = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'search_minor': begin
            preval = (*pState).search_ellipse[1]
            newval = FLOAT(newval)
            if (~FINITE(newval) || newval le 0.0) then $
                goto, failed
            (*pState).search_ellipse[1] = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'search_theta': begin
            preval = (*pState).search_ellipse[2]
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            newval = -90 > newval < 90
            (*pState).search_ellipse[2] = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'max_per_sector': begin
            isFloat = 0b
            preval = (*pState).max_per_sector
            newval = LONG(newval)
            ; Reset it if zero, otherwise restrict range.
            newval = (newval eq 0) ? (*pState).nElts : $
            1 > newval < (*pState).nElts
            (*pState).max_per_sector = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'min_points': begin
            isFloat = 0b
            preval = (*pState).min_points
            newval = LONG(newval)
            ; Restrict range.
            newval = 1 > newval < ((*pState).nElts-1)
            (*pState).min_points = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'power': begin
            if ((*pState).method eq 'Polynomial Regression') then $
                isFloat = 0b
            preval = (*pState).power
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            if ((*pState).method eq 'Polynomial Regression') then $
                newval = 1 > FIX(newval) < 3
            (*pState).power = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'smoothing': begin
            preval = (*pState).smoothing
            newval = FLOAT(newval)
            if (~FINITE(newval)) then $
                goto, failed
            if ((*pState).method eq 'Radial Basis Function') && $
                (newval eq 0) then goto, failed
            (*pState).smoothing = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

        'missing': begin
            preval = (*pState).missing
            newval = FLOAT(newval)
            ; Note: missing is allowed to be NaN or Inf, so don't check.
            (*pState).missing = newval
            if (newval ne preval) then $
                IDLITWDGRIDWIZARD_GRIDDATA, pState
            end

    endcase

    newval = isFloat ? ITGW_PRINT(newval) : $
        STRTRIM(STRING(newval, /PRINT), 2)
    WIDGET_CONTROL, event.id, SET_VALUE=newval


    return

failed:

    preval = isFloat ? ITGW_PRINT(preval) : $
        STRTRIM(STRING(preval, /PRINT), 2)
    ; Restore the previous value.
    WIDGET_CONTROL, event.id, SET_VALUE=STRTRIM(STRING(preval, /PRINT), 2)


end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_update_stats, pState

    compile_opt idl2, hidden

    wStat1 = WIDGET_INFO((*pState).wColumn3, $
        FIND_BY_UNAME='wStat1')
    wStat2 = WIDGET_INFO((*pState).wColumn3, $
        FIND_BY_UNAME='wStat2')

    cr = (!version.os_family eq 'Windows') ? STRING(13b) : STRING(10b)


    dmin = MIN((*pState).fData, MAX=dmax)
    dmoments = MOMENT((*pState).fData, MAXMOMENT=2, SDEV=dsdev)

    stats = [ $
        ['Data min',    ITGW_PRINT(dmin)], $
        ['Data max',    ITGW_PRINT(dmax)], $
        ['Mean',        ITGW_PRINT(dmoments[0])], $
        ['Std dev',     ITGW_PRINT(dsdev)], $
        ['','']]

    if (N_ELEMENTS(*(*pState).pResult) gt 1) then begin
        rmin = MIN(*(*pState).pResult, MAX=rmax, NAN=((*pState).nmiss gt 0))
        rmoments = MOMENT(*(*pState).pResult, MAXMOMENT=2, $
            NAN=((*pState).nmiss gt 0), SDEV=rsdev)

        stats = [[stats], $
            ['Result min',  ITGW_PRINT(rmin)], $
            ['Result max',  ITGW_PRINT(rmax)], $
            ['Mean',        ITGW_PRINT(rmoments[0])], $
            ['Std dev',     ITGW_PRINT(rsdev)], $
            ['',''], $
            ['Missing', STRING((*pState).nmiss) + '/' + $
                STRING(N_ELEMENTS(*(*pState).pResult))]]
    endif else begin
        stats = [[stats], $
            ['Press <Preview>', ''], $
            ['for grid results.', '']]
    endelse


    WIDGET_CONTROL, wStat1, SET_VALUE=STRJOIN(stats[0,*], cr, /SINGLE)
    WIDGET_CONTROL, wStat2, $
        SET_VALUE=STRJOIN(STRCOMPRESS(stats[1,*],/REM), cr, /SINGLE)
end



;-------------------------------------------------------------------------
function idlitwdgridwizard_sector, point

    compile_opt idl2, hidden

  nsectors = 4
  kSector = nsectors / (2 * !DPI)
  return, fix((atan(-point[1], -point[0]) + !DPI) * kSector)
end


;-------------------------------------------------------------------------
function idlitwdgridwizard_ellipse, a, b, tIn

    compile_opt idl2, hidden

    t = tIn*!DPI/180
    e = [-SIN(t)/a, a*COS(t), -b*SIN(t), b*COS(t)]
    angle = FINDGEN(101)*!PI/50
    x = a*COS(angle)
    y = b*SIN(angle)
    xp =  x*COS(t) - y*SIN(t)
    yp =  x*SIN(t) + y*COS(t)

    return, TRANSPOSE([[xp], [yp]])
end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_anisoellipse, pState

    compile_opt idl2, hidden

    ellipse = IDLITWDGRIDWIZARD_ELLIPSE((*pState).aniso_ratio, 1, $
        (*pState).aniso_theta)
;
    mn = MIN(ellipse, MAX=mx)
;    dr = (mx - mn)/10

    wAnisoDraw = WIDGET_INFO((*pState).wColumn3, $
        FIND_BY_UNAME='wAnisoDraw')
    WIDGET_CONTROL, wAnisoDraw, GET_VALUE=oWin, GET_UVALUE=oPoly

    oPoly->GetProperty, PARENT=oModel
    oModel->Reset
    oModel->Scale, 1.8/(mx - mn), 1.8/(mx - mn), 1
    oPoly->SetProperty, DATA=ellipse
    oWin->Draw

end


;-------------------------------------------------------------------------
; If FINISH is set, do the griddata, but not the preview.
;
; If PREVIEW is set, then do both the griddata and the preview.
; Otherwise, check if the AUTOPREVIEW flag is set.
;
pro idlitwdgridwizard_griddata, pState, $
    FINISH=finish, $
    PREVIEW=preview

    compile_opt idl2, hidden

    if (~KEYWORD_SET(preview) && ~KEYWORD_SET(finish)) then begin
        wAutoPreview = WIDGET_INFO((*pState).wTopRow3, $
            FIND_BY_UNAME='wAutoPreview')
        if (~WIDGET_INFO(wAutoPreview, /BUTTON_SET)) then begin
            *(*pState).pResult = 0
            IDLitwdGridWizard_DrawRefresh, pState
            ; We've come in here, but we're bailing, so mark as dirty.
            (*pState).isDirty = 1b
            return
        endif
    endif

    ; We're going to recalculate everything, so mark as clean.
    (*pState).isDirty = 0b

    WIDGET_CONTROL, /HOURGLASS

    switch (*pState).method of
        'Linear':
        'Natural Neighbor':
        'Nearest Neighbor':
        'Modified Shepards':
        'Quintic': begin
            needTriangles = 1
            break
            end
        else:  needTriangles = 0
    endswitch

    aniso_theta = (*pState).aniso_theta
    if (*pState).bRadians then $
        aniso_theta = aniso_theta*!PI/180

    ; Check for SEARCH_ELLIPSE.
    searchEllipse = (*pState).useEllipse ? (*pState).search_ellipse : 0
    if ((*pState).useEllipse) then $
        needTriangles = 1


    ; If MAX_PER_SECTOR is equal to # of points, don't bother to set it.
    max_per_sector = ((*pState).max_per_sector lt (*pState).nElts) ? $
        (*pState).max_per_sector : 0

    ; If MIN_POINTS is <= 1, then don't bother to set it.
    min_points = ((*pState).min_points gt 1) ? (*pState).min_points : 0

    ; Grid spacing.
    xdelta = ((*pState).xend - (*pState).xstart)/((*pState).xdim - 1)
    ydelta = ((*pState).yend - (*pState).ystart)/((*pState).ydim - 1)

    _extra = { $
        ANISOTROPY: [(*pState).aniso_ratio, 1, aniso_theta], $
        DEGREES: 1-(*pState).bRadians, $
        DELTA: [xdelta, ydelta], $
        DIMENSION: [(*pState).xdim, (*pState).ydim], $
        EMPTY_SECTORS: (*pState).empty_sectors, $
        FUNCTION_TYPE: (*pState).radialfunc, $
        MAX_PER_SECTOR: max_per_sector, $
        MIN_POINTS: min_points, $
        METHOD: STRCOMPRESS((*pState).method, /REMOVE), $
        MISSING: (*pState).missing, $
        POWER: (*pState).power, $
        SEARCH_ELLIPSE: searchEllipse, $
        SECTORS: (*pState).nsectors, $
        SMOOTHING: (*pState).smoothing, $
        SPHERE: (*pState).bSphere, $
        START: [(*pState).xstart, (*pState).ystart]}


    if (_extra.empty_sectors gt 0) || (_extra.max_per_sector gt 0) $
        || (_extra.min_points gt 0) then $
        needTriangles = 1


    quiet = !QUIET
    !QUIET = 1

@idlit_catch
    if (iErr ne 0) then begin

        CATCH, /CANCEL
        status = !error_state.msg
        result = FLTARR((*pState).xdim, (*pState).ydim)

    endif else begin

        ; Compute TRIANGULATION only if necessary.
        if (needTriangles) then begin

            WIDGET_CONTROL, (*pState).wXY, SET_VALUE='Triangulate...'

            fvalue = (*pState).fData

            if ((*pState).bSphere) then begin

                if ((*pState).bRadians) then begin
                    QHULL, (*pState).xData*180/!PI, $
                           (*pState).yData*180/!PI, triangles, SPHERE=sphere
                endif else begin
                    QHULL, (*pState).xData, $
                           (*pState).yData, triangles, SPHERE=sphere
                endelse

            endif else begin
                TRIANGULATE, (*pState).xData, (*pState).yData, triangles
            endelse

            *(*pState).pTriangles = triangles
        endif


        WIDGET_CONTROL, (*pState).wXY, SET_VALUE='Gridding...'

        pending = CHECK_MATH(/NOCLEAR)

        success = 0

        result = GRIDDATA((*pState).xData, (*pState).yData, $
            (*pState).fData, TRIANGLES=triangles, _EXTRA=_extra)

        if (N_ELEMENTS(result) eq (*pState).xdim*(*pState).ydim) then begin
            result = FLOAT(result)
            success = 1
            status = 'Ready'
        endif else begin
            result = 0.0
            success = 0
            status = 'Griddata failed'
        endelse

        if (pending eq 0) then $
            dummy = CHECK_MATH()

    endelse


    !QUIET = quiet


    if (FINITE((*pState).missing)) then begin

        miss = WHERE(result eq (*pState).missing, nmiss)

        ; Replace all missing values with NaNs,
        ; so our surface will filter them out.
        if (nmiss gt 0) then $
            result[miss] = !VALUES.F_NAN

    endif else begin

        nmiss = TOTAL(~FINITE(result))

    endelse

    (*pState).nmiss = nmiss

    *(*pState).pResult = result

    ; Refresh the graphics (unless FINISH is set).
    if (~KEYWORD_SET(finish)) then $
        IDLitwdGridWizard_DrawRefresh, pState


    WIDGET_CONTROL, (*pState).wXY, SET_VALUE=status

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_update_options, pState, INITIALIZE=initialize

    compile_opt idl2, hidden


    ; Radial basis functions are valid for both spherical and non-sphere.
    radialFunctions = [ $
            'Radial: Inverse quadric', $
            'Radial: Multilog', $
            'Radial: Multiquadric', $
            'Radial: Cubic spline', $
            'Radial: Thin plate']

    ; Fill in methods droplist.
    methods = (*pState).bSphere ? $
            [ $
            'Inverse Distance', $
            'Kriging', $
            'Natural Neighbor', $
            'Nearest Neighbor', $
            radialFunctions] : $
            [ $
            'Inverse Distance', $
            'Kriging', $
            'Natural Neighbor', $
            'Nearest Neighbor', $
            radialFunctions, $
        ; Add in non-spherical methods...
            'Linear', $
            'Minimum Curvature', $
            'Modified Shepards', $
            'Polynomial Regression', $
            'Quintic']
    *(*pState).pMethods = methods


    if (WIDGET_INFO((*pState).wMethod, /DROPLIST_NUMBER) eq 1) then begin
        ; If this is the first time we've been here, we need to set
        ; the default method.
        defaultMethod = 'Inverse Distance'
        ; For spherical this will just default to method=0.
        pos = (WHERE(methods eq defaultMethod))[0] > 0
    endif else begin
        ; Retrieve current value and make sure it is within range.
        pos = WIDGET_INFO((*pState).wMethod, /DROPLIST_SELECT)
    endelse

    ; Check for out of range index if we switched to spherical.
    if (pos ge N_ELEMENTS(methods)) then $
        pos = 0

    currentMethod = methods[pos]
    if (STRPOS(currentMethod, 'Radial:') ne -1) then begin
        currentMethod = 'Radial Basis Function'
        startRadial = MIN(WHERE(STRPOS(*(*pState).pMethods, 'Radial:') ge 0))
        (*pState).radialfunc = pos - startRadial

    endif

    (*pState).method = currentMethod


    WIDGET_CONTROL, (*pState).wMethod, SET_VALUE=methods
    WIDGET_CONTROL, (*pState).wMethod, $
        SET_DROPLIST_SELECT=pos


    ; Default is to turn off these options.
    anisoOn = 0
    powerOn = 0
    radialOn = 0
    searchOn = 0
    smoothOn = 0

    ; Default is to turn on.
    missingOn = 1

    switch (*pState).method of

        'Inverse Distance': begin

            anisoOn = 1
            powerOn = 1
            searchOn = 1
            smoothOn = 1

            ; Change the power label.
            wLabel = WIDGET_INFO((*pState).wColumn3, $
                FIND_BY_UNAME='powerLabel')
            WIDGET_CONTROL, wLabel, SET_VALUE='Weighting:'

            ; Reset the power value.
            if (~KEYWORD_SET(initialize)) then begin
                (*pState).power = 2
                wPower = WIDGET_INFO((*pState).wColumn3, $
                    FIND_BY_UNAME='power')
                WIDGET_CONTROL, wPower, SET_VALUE=ITGW_PRINT(2)
            endif

            break
            end

        'Polynomial Regression': begin

            powerOn = 1
            searchOn = 1

            ; Change the power label.
            wLabel = WIDGET_INFO((*pState).wColumn3, $
                FIND_BY_UNAME='powerLabel')
            WIDGET_CONTROL, wLabel, SET_VALUE='Polynomial:'

            ; Reset the power value.
            wPower = WIDGET_INFO((*pState).wColumn3, $
                FIND_BY_UNAME='power')
            ; If we have already been to Screen 3, and the method is still
            ; Polynomial Regression, don't reinitialize the polynomial.
            ; Otherwise, if the user is actually changing the method,
            ; initialize the polynomial to 2.
            if (~KEYWORD_SET(initialize)) then $
                (*pState).power = 2
            ; Convert to integer if we are doing polynomial,
            ; otherwise leave as float.
            value = ((*pState).method eq 'Inverse Distance') ? $
                ITGW_PRINT((*pState).power) : $
                STRTRIM(1 > FIX((*pState).power) < 3, 2)
            WIDGET_CONTROL, wPower, SET_VALUE=value

            break
            end

        'Minimum Curvature': begin
            ; Only one that doesn't allow MISSING keyword.
            missingOn = 0
            break
            end

        'Radial Basis Function': begin

            anisoOn = 1
            radialOn = 1
            searchOn = 1
            smoothOn = 1

            ; Reset the SMOOTHING to its default value.
            if ((*pState).smoothing eq 0) then begin
                r = (*pState).range
                ; Average point spacing = Grid area / number of points
                (*pState).smoothing = $
                    SQRT((r[2] - r[0])*(r[3] - r[1])/(*pState).nElts)
                WIDGET_CONTROL, WIDGET_INFO((*pState).wColumn3, $
                    FIND_BY_UNAME='smoothing'), $
                    SET_VALUE=ITGW_PRINT((*pState).smoothing)
            endif

            break
            end

        'Kriging':   ; fall thru
        'Modified Shepards': begin
            anisoOn = 1
            searchOn = 1
            break
            end

        else:

    endswitch


    if ((*pState).bSphere) then begin
        anisoOn = 0
        searchOn = 0
    endif

    ; Actually turn the widget bases on/off.

    wPower = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='wPower')
    WIDGET_CONTROL, wPower, SENSITIVE=powerOn

    wSmooth = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='wSmooth')
    WIDGET_CONTROL, wSmooth, SENSITIVE=smoothOn

    wMissing = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='wMissing')
    WIDGET_CONTROL, wMissing, SENSITIVE=missingOn

    wAniso = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='wAniso')
    WIDGET_CONTROL, wAniso, SENSITIVE=anisoOn

    wSearch = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='wSearch')
    WIDGET_CONTROL, wSearch, SENSITIVE=searchOn

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_method, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    IDLITWDGRIDWIZARD_UPDATE_OPTIONS, pState
    IDLITWDGRIDWIZARD_GRIDDATA, pState

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_preview, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    IDLITWDGRIDWIZARD_GRIDDATA, pState, /PREVIEW

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_autopreview, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    if (event.select) then $
        IDLITWDGRIDWIZARD_GRIDDATA, pState, /PREVIEW

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_searchellipse, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState

    ; Turn on or off our flag.
    (*pState).useEllipse = event.select

    ; Turn on or off the other search ellipse fields.
    wEllipseValues = WIDGET_INFO((*pState).wColumn3, $
        FIND_BY_UNAME='wEllipseValues')

    WIDGET_CONTROL, wEllipseValues, SENSITIVE=event.select

    IDLITWDGRIDWIZARD_GRIDDATA, pState

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_nsectors, event, NO_UPDATE=noUpdate

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    (*pState).nsectors = event.index + 1

    ; Reset the number of available empty_sectors choices.
    wEmpty = WIDGET_INFO((*pState).wColumn3, FIND_BY_UNAME='empty_sectors')
    WIDGET_CONTROL, wEmpty, SET_VALUE='  ' + $
        STRTRIM(INDGEN(event.index + 1), 2)

    ; Reset the empty value if necessary.
    (*pState).empty_sectors = 0 > (*pState).empty_sectors < event.index
    WIDGET_CONTROL, wEmpty, SENSITIVE=(event.index ge 1), $
        SET_DROPLIST_SELECT=(*pState).empty_sectors

    ; Make sure we are actually called from a real event.
    if (~KEYWORD_SET(noUpdate)) then $
        IDLITWDGRIDWIZARD_GRIDDATA, pState

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_empty_sectors, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    (*pState).empty_sectors = event.index
    IDLITWDGRIDWIZARD_GRIDDATA, pState

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_showpoints, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=pState
    (*pState).showpoints = event.select
    (*pState).oWin->GetProperty, GRAPHICS_TREE=oView
    oPoints = oView->GetByName('model/points')
    oPoints->SetProperty, HIDE=1-event.select
    IDLitwdGridWizard_DrawRefresh, pState

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_1_docreate, pState, id

    compile_opt idl2, hidden

    ; These will only get created once, and are used for all 3 screens.
    wBase = WIDGET_BASE(id, /BASE_ALIGN_LEFT, /COLUMN, $
        SPACE=10)
    wTopRow0 = WIDGET_BASE(wBase, $
        XSIZE=(*pState).xsize, YSIZE=35)
    wRow = WIDGET_BASE(wBase, /ROW)
    wColumn0 = WIDGET_BASE(wRow, $
        XSIZE=(*pState).xsize - (*pState).dwidth - 8)

    wDbase = WIDGET_BASE(wRow, /ALIGN_BOTTOM, /COLUMN, $
        XSIZE=(*pState).dwidth)

    wDraw = WIDGET_DRAW(wDbase, $
        EVENT_PRO='idlitwdgridwizard_drawevent', $
        /EXPOSE_EVENTS, $
        GRAPHICS_LEVEL=2, $
        /MOTION_EVENTS, $
        RETAIN=0, $
        UVALUE=pState, $
        XSIZE=(*pState).dwidth, YSIZE=(*pState).dheight)

    WIDGET_CONTROL, wDraw, GET_VALUE=oWin
    (*pState).oWin = oWin

    wRow1 = WIDGET_BASE(wDbase, /ROW, XPAD=0, YPAD=0, $
        XSIZE=(*pState).dwidth)
    wBut = WIDGET_BASE(wRow1, /NONEXC, XPAD=0, YPAD=0)
    wShowpts = WIDGET_BUTTON(wBut, $
        EVENT_PRO='idlitwdgridwizard_showpoints', $
        UVALUE=pState, $
        VALUE='Show points')
    if (*pState).showpoints then $
        WIDGET_CONTROL, wShowpts, /SET_BUTTON

    (*pState).wXY = WIDGET_LABEL(wRow1, /DYNAMIC, VALUE=' ')



    ; These are specific to screen 1.

    wTopRow = WIDGET_BASE(wTopRow0, MAP=0, /ROW, SPACE=5)
    (*pState).wTopRow1 = wTopRow

    text = 'This wizard helps you interpolate your scattered' + $
        ' data values and locations onto a regular grid.'
    wText = WIDGET_LABEL(wTopRow, VALUE=text, YSIZE=height)


    wCol = WIDGET_BASE(wColumn0, /BASE_ALIGN_LEFT, /COLUMN, $
        MAP=0, $
        SPACE=1, $
        XSIZE=(*pState).xsize - (*pState).dwidth - 8)
    (*pState).wColumn1 = wCol

    wText = WIDGET_LABEL(wCol, /ALIGN_LEFT, VALUE='You have entered ' + $
        STRTRIM((*pState).nElts, 2) + ' points.')


    wDummy = WIDGET_LABEL(wCol, VALUE=' ')

    wText = WIDGET_LABEL(wCol, VALUE='X coordinates:')
    mn = ITGW_PRINT((*pState).range[0])
    mx = ITGW_PRINT((*pState).range[2])
    wText = WIDGET_LABEL(wCol, VALUE=mn + ', ' + mx, /ALIGN_CENTER)


    wDummy = WIDGET_LABEL(wCol, VALUE=' ')
    wText = WIDGET_LABEL(wCol, VALUE='Y coordinates:')
    mn = ITGW_PRINT((*pState).range[1])
    mx = ITGW_PRINT((*pState).range[3])
    wText = WIDGET_LABEL(wCol, VALUE=mn + ', ' + mx, /ALIGN_CENTER)


    wDummy = WIDGET_LABEL(wCol, VALUE=' ')
    wText = WIDGET_LABEL(wCol, VALUE='Data values:')
    mn = MIN((*pState).fData, MAX=mx)
    mn = ITGW_PRINT(mn)
    mx = ITGW_PRINT(mx)
    wText = WIDGET_LABEL(wCol, VALUE=mn + ', ' + mx, /ALIGN_CENTER)


    wDummy = WIDGET_LABEL(wCol, VALUE=' ')

    wButtons = WIDGET_BASE(wCol, /ALIGN_LEFT, $
        /NONEXCLUSIVE, SPACE=0)

    wSphere = WIDGET_BUTTON(wButtons, $
        EVENT_PRO='idlitwdgridwizard_sphere', $
        UVALUE=pState, $
        TOOLTIP='Data values and locations lie on a sphere (instead of a plane)', $
        VALUE='Spherical data')

    if ((*pState).bSphere) then $
        WIDGET_CONTROL, wSphere, /SET_BUTTON


    wRadians = WIDGET_BASE(wCol, /ALIGN_LEFT, $
        MAP=(*pState).bSphere, $
        /NONEXCLUSIVE, $
        SPACE=0, $
        UNAME='wRadians')

    wRadbut = WIDGET_BUTTON(wRadians, $
        EVENT_PRO='idlitwdgridwizard_radians', $
        UVALUE=pState, $
        TOOLTIP='Locations are in radians (instead of degrees)', $
        VALUE='Radians')

    ; Make our best guess whether /RADIANS should be set or not.
    if (MAX((*pState).xData, MIN=mnx) lt 6.29) && $   ; < 2pi
        (mnx gt -6.29) && $
        (MAX((*pState).yData, MIN=mny) lt 1.58) && $  ; < pi/2
        (mny gt -1.58) then begin
            WIDGET_CONTROL, wRadbut, /SET_BUTTON
    endif

end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_2_docreate, pState, id

    compile_opt idl2, hidden

    ; Retrieve my top level bases.
    wTopRow0 = WIDGET_INFO((*pState).wTopRow1, /PARENT)
    wColumn0 = WIDGET_INFO((*pState).wColumn1, /PARENT)

    wTopRow = WIDGET_BASE(wTopRow0, MAP=0, /ROW, SPACE=5)
    (*pState).wTopRow2 = wTopRow

    wText = WIDGET_LABEL(wTopRow, /ALIGN_LEFT, $
        VALUE='Choose your grid dimensions, start, and spacing.')


    wCol = WIDGET_BASE(wColumn0, /COLUMN, $
        MAP=0, $
        SPACE=10)
    (*pState).wColumn2 = wCol


    xs = 10

    wCoord = WIDGET_BASE(wCol, /BASE_ALIGN_RIGHT, /COLUMN)

    wText = WIDGET_LABEL(wCoord, /ALIGN_LEFT, VALUE='X coordinates: ')

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='Dimension: ')
    wXdim = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Xdim', $
        UVALUE=pState, $
        VALUE=STRTRIM(STRING((*pState).xdim, /PRINT), 2), $
        XSIZE=xs)

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='Start: ')
    wXstart = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Xstart', $
        UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).xstart), $
        XSIZE=xs)

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='End: ')
    wXend = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Xend', $
        UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).xend), $
        XSIZE=xs)



    wCoord = WIDGET_BASE(wCol, /BASE_ALIGN_RIGHT, /COLUMN)

    wText = WIDGET_LABEL(wCoord, /ALIGN_LEFT, VALUE='Y coordinates: ')

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='Dimension: ')
    wYdim = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Ydim', $
        UVALUE=pState, $
        VALUE=STRTRIM(STRING((*pState).ydim, /PRINT), 2), $
        XSIZE=xs)

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='Start: ')
    wYstart = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Ystart', $
        UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).ystart), $
        XSIZE=xs)

    w1 = WIDGET_BASE(wCoord, /ROW, XPAD=10, YPAD=0)
    wText = WIDGET_LABEL(w1, /ALIGN_RIGHT, VALUE='End: ')
    wYend = WIDGET_TEXT(w1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='Yend', $
        UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).yend), $
        XSIZE=xs)


end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_3_docreate, pState, id

    compile_opt idl2, hidden

    ; Retrieve my top level bases.
    wTopRow0 = WIDGET_INFO((*pState).wTopRow1, /PARENT)
    wColumn0 = WIDGET_INFO((*pState).wColumn1, /PARENT)

    wTopRow = WIDGET_BASE(wTopRow0, MAP=0, /ROW, SPACE=5)
    (*pState).wTopRow3 = wTopRow

    wText = WIDGET_LABEL(wTopRow, VALUE='Please choose a gridding method:')

    ; The actual list of methods will be filled in during Create.
    (*pState).wMethod = WIDGET_DROPLIST(wTopRow, $
        /DYNAMIC_RESIZE, /FLAT, $
        EVENT_PRO='idlitwdgridwizard_method', $
        VALUE=['           '], $
        UVALUE=pState)

    wPreview = WIDGET_BUTTON(wTopRow, $
        EVENT_PRO='idlitwdgridwizard_preview', $
        VALUE='Preview', $
        UVALUE=pState)

    wNonexc = WIDGET_BASE(wTopRow, /NONEXCLUSIVE, $
        SPACE=0, XPAD=0, YPAD=0)
    wAutoPreview = WIDGET_BUTTON(wNonexc, $
        EVENT_PRO='idlitwdgridwizard_autopreview', $
        VALUE='Auto preview', $
        UNAME='wAutoPreview', $
        UVALUE=pState)



    wCol = WIDGET_BASE(wColumn0, /COLUMN, $
;        MAP=0, $
        SPACE=0, XPAD=0, YPAD=0)
    (*pState).wColumn3 = wCol

    xsize = (*pState).xsize - (*pState).dwidth - 12
    wTabBase = WIDGET_TAB(wCol, $
        SCR_XSIZE=xsize)
    xs = 8


    ;---------- STATISTICS

    wStats = WIDGET_BASE(wTabBase, COLUMN=2, $
        SPACE=0, XPAD=5, YPAD=10, TITLE='Statistics')

    ysize = (*pState).dheight - 60

    wStat1 = WIDGET_LABEL(wStats, $
        /ALIGN_RIGHT, $
        UNAME='wStat1', $
        VALUE='Press', $
        XSIZE=xsize/2 - 10, $
        YSIZE=ysize)
    wStat2 = WIDGET_LABEL(wStats, $
        /ALIGN_CENTER, $
        UNAME='wStat2', $
        VALUE='<Preview> ', $
        XSIZE=xsize/2 - 10, $
        YSIZE=ysize)



    ;---------- OPTIONS

    wOptions = WIDGET_BASE(wTabBase, /COLUMN, $
        SPACE=10, XPAD=5, YPAD=10, TITLE='Options')


    wOption1 = WIDGET_BASE(wOptions, /BASE_ALIGN_RIGHT, $
        /COLUMN, XPAD=0, YPAD=0)

    ; MISSING
    wMissing = WIDGET_BASE(wOption1, $
        /ROW, $
        UNAME='wMissing', $
        XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wMissing, VALUE='Missing value: ')
    wDummy = WIDGET_TEXT(wMissing, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='missing', $
        UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).missing), $
        XSIZE=xs)

    ; SMOOTHING
    wSmooth = WIDGET_BASE(wOption1, $
        /ROW, $
        UNAME='wSmooth', $
        XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wSmooth, VALUE='Smoothing:')
    wDummy = WIDGET_TEXT(wSmooth, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='smoothing', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).smoothing), $
        XSIZE=xs)


    ; POWER
    wPower = WIDGET_BASE(wOption1, $
        /ROW, $
        UNAME='wPower', $
        XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wPower, $
        /DYNAMIC_RESIZE, $
        UNAME='powerLabel', $
        VALUE='Polynomial:')
    wDummy = WIDGET_TEXT(wPower, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='power', UVALUE=pState, $
        VALUE=ITGW_PRINT(2), $
        XSIZE=xs)


    ; ANISOTROPY ELLIPSE
    wAniso = WIDGET_BASE(wOptions, $
        /BASE_ALIGN_RIGHT, $
        /COLUMN, $
        UNAME='wAniso', $
        XPAD=0, YPAD=0)

    wText = WIDGET_LABEL(wAniso, /ALIGN_LEFT, $
        VALUE='Anisotropy between axes:')

    wOption2 = WIDGET_BASE(wAniso, /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption2, VALUE='Ratio of X to Y:')
    wDummy = WIDGET_TEXT(wOption2, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='aniso_ratio', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).aniso_ratio), $
        XSIZE=xs)

    wOption2 = WIDGET_BASE(wAniso, /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption2, VALUE='Angle (deg):')
    wDummy = WIDGET_TEXT(wOption2, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='aniso_theta', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).aniso_theta), $
        XSIZE=xs)


    wAnisoDraw = WIDGET_DRAW(wAniso, /ALIGN_CENTER, $
        GRAPHICS_LEVEL=2, $
        RETAIN=2, $
        UNAME='wAnisoDraw', $
        XSIZE=75, YSIZE=75)
    WIDGET_CONTROL, wAnisoDraw, GET_VALUE=oWin
    oPoly = OBJ_NEW('IDLgrPolyline')
    WIDGET_CONTROL, wAnisoDraw, SET_UVALUE=oPoly
    oModel = OBJ_NEW('IDLgrModel')
    oModel->Add, oPoly

    oView = OBJ_NEW('IDLgrView', $
        COLOR=(WIDGET_INFO(wAnisoDraw, /SYSTEM_COLORS)).face_3d)
    oView->Add, oModel
    oWin->SetProperty, GRAPHICS_TREE=oView


    ;---------- SEARCH

    wSearch = WIDGET_BASE(wTabBase, /COLUMN, $
        UNAME='wSearch', $
        SPACE=15, XPAD=5, YPAD=10, TITLE='Search')


    ; SEARCH_ELLIPSE
    wEllipse = WIDGET_BASE(wSearch, /COLUMN, $
        SPACE=0, XPAD=0, YPAD=0)

    w1 = WIDGET_BASE(wEllipse, /NONEXCLUSIVE, $
        SPACE=0, XPAD=0, YPAD=0)
    wBut = WIDGET_BUTTON(w1, $
        EVENT_PRO='idlitwdgridwizard_searchellipse', $
        TOOLTIP='For each grid location only consider ' + $
            'points within this ellipse', $
        UVALUE=pState, $
        VALUE='Use search ellipse')
    if (*pState).useEllipse then $
        WIDGET_CONTROL, wBut, /SET_BUTTON

    wEllipseValues = WIDGET_BASE(wEllipse, /GRID, ROW=3, $
        SENSITIVE=(*pState).useEllipse, $
        UNAME='wEllipseValues', $
        XPAD=0, YPAD=0)

    wText = WIDGET_LABEL(wEllipseValues, /ALIGN_RIGHT, VALUE='Semimajor:')
    wDummy = WIDGET_TEXT(wEllipseValues, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='search_major', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).search_ellipse[0]), $
        XSIZE=xs)

    wText = WIDGET_LABEL(wEllipseValues, /ALIGN_RIGHT, VALUE='Semiminor:')
    wDummy = WIDGET_TEXT(wEllipseValues, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='search_minor', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).search_ellipse[1]), $
        XSIZE=xs)

    wText = WIDGET_LABEL(wEllipseValues, /ALIGN_RIGHT, VALUE='Angle (deg):')
    wDummy = WIDGET_TEXT(wEllipseValues, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='search_theta', UVALUE=pState, $
        VALUE=ITGW_PRINT((*pState).search_ellipse[2]), $
        XSIZE=xs)



    wSector = WIDGET_BASE(wSearch, /BASE_ALIGN_RIGHT, /COLUMN, $
        XPAD=0, YPAD=0)


    ; SECTORS
    wOption1 = WIDGET_BASE(wSector, $
        /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption1, VALUE='Sectors to use: ')
    wNsectors = WIDGET_DROPLIST(wOption1, /FLAT, $
        EVENT_PRO='idlitwdgridwizard_nsectors', $
        UVALUE=pState, $
        VALUE='  ' + STRTRIM(INDGEN(8)+1,2))



    ; EMPTY_SECTORS
    wOption1 = WIDGET_BASE(wSector, /BASE_ALIGN_RIGHT, $
        /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption1, VALUE='Empty sectors: ')

    wDummy = WIDGET_DROPLIST(wOption1, /FLAT, $
        EVENT_PRO='idlitwdgridwizard_empty_sectors', $
        UNAME='empty_sectors', $
        UVALUE=pState, $
        VALUE='  ' + STRTRIM(INDGEN((*pState).nsectors > 1),2))


    ; Set the widget state for # sectors.
    WIDGET_CONTROL, wNsectors, SET_DROPLIST_SELECT=(*pState).nsectors - 1
    IDLITWDGRIDWIZARD_NSECTORS, {ID: wNsectors, TOP: wNsectors, $
        HANDLER: wNsectors, INDEX: (*pState).nsectors - 1}, $
        /NO_UPDATE


    ; MAX_PER_SECTOR
    wOption1 = WIDGET_BASE(wSector, /BASE_ALIGN_RIGHT, $
        /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption1, VALUE='Max pts/sector: ')
    wDummy = WIDGET_TEXT(wOption1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='max_per_sector', UVALUE=pState, $
        VALUE=STRTRIM((*pState).max_per_sector, 2), $
        XSIZE=5)


    ; MIN_POINTS
    wOption1 = WIDGET_BASE(wSector, /BASE_ALIGN_RIGHT, $
        /ROW, XPAD=0, YPAD=0)
    wText = WIDGET_LABEL(wOption1, VALUE='Min points: ')
    wDummy = WIDGET_TEXT(wOption1, /EDITABLE, $
        EVENT_PRO='idlitwdgridwizard_checkvalue', $
        /KBRD_FOCUS_EVENTS, $
        UNAME='min_points', UVALUE=pState, $
        VALUE=STRTRIM((*pState).min_points, 2), $
        XSIZE=5)


end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_1_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    (*pState).screen = 1

    if ~WIDGET_INFO((*pState).wTopRow1, /VALID) then begin
        IDLitwdGridWizard_1_docreate, pState, id
        IDLitwdGridWizard_DrawSetup, pState
    endif

    WIDGET_CONTROL, (*pState).wTopRow1, /MAP
    WIDGET_CONTROL, (*pState).wColumn1, /MAP

    IDLitwdGridWizard_DrawRefresh, pState

end


;-------------------------------------------------------------------------
function idlitwdgridwizard_1_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wTopRow1, MAP=0
    WIDGET_CONTROL, (*pState).wColumn1, MAP=0

    return, 1
end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_2_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    (*pState).screen = 2

    if ~WIDGET_INFO((*pState).wTopRow2, /VALID) then $
        IDLitwdGridWizard_2_docreate, pState, id

    WIDGET_CONTROL, (*pState).wTopRow2, /MAP
    WIDGET_CONTROL, (*pState).wColumn2, /MAP
    IDLitwdGridWizard_DrawRefresh, pState

end


;-------------------------------------------------------------------------
function idlitwdgridwizard_2_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wTopRow2, MAP=0
    WIDGET_CONTROL, (*pState).wColumn2, MAP=0
    return,1
end


;-------------------------------------------------------------------------
pro idlitwdgridwizard_3_create, id

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState
    (*pState).screen = 3

    if ~WIDGET_INFO((*pState).wTopRow3, /VALID) then $
        IDLitwdGridWizard_3_docreate, pState, id

    IDLITWDGRIDWIZARD_UPDATE_OPTIONS, pState, /INITIALIZE

    WIDGET_CONTROL, (*pState).wTopRow3, /MAP
    WIDGET_CONTROL, (*pState).wColumn3, /MAP

    IDLITWDGRIDWIZARD_ANISOELLIPSE, pState

    wAutoPreview = WIDGET_INFO((*pState).wTopRow3, $
        FIND_BY_UNAME='wAutoPreview')
    if (WIDGET_INFO(wAutoPreview, /BUTTON_SET)) then $
        IDLITWDGRIDWIZARD_GRIDDATA, pState, /PREVIEW

end


;-------------------------------------------------------------------------
function idlitwdgridwizard_3_destroy, id, bNext

    compile_opt idl2, hidden

    WIDGET_CONTROL, id, GET_UVALUE=pState

    ; User hit the "Finish" button.
    if (bNext) then begin
        ; Do we need to do a recalculation before we're done?
        if ((*pState).isDirty) then $
            IDLITWDGRIDWIZARD_GRIDDATA, pState, /FINISH
        if (N_ELEMENTS(*(*pState).pResult) le 1) then begin
            dummy = DIALOG_MESSAGE(['Griddata failed.', $
                'Try using a different gridding method.'], $
                /ERROR, $
                DIALOG_PARENT=id, TITLE='Grid Wizard')
            (*pState).isDirty = 1b  ; still dirty
            return, 0   ; don't destroy the wizard
        endif
    endif

    WIDGET_CONTROL, (*pState).wTopRow3, MAP=0
    WIDGET_CONTROL, (*pState).wColumn3, MAP=0

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   Create the Grid Wizard.
;
; Arguments:
;   X: A vector representing the X components corresponding
;       to the sample values.  The length of this vector
;       must match either the number of elements in Z,
;       or the first dimension of Z if Z is a 2D array.
;   Y: A vector representing the Y components corresponding
;       to the sample values.  The length of this vector
;       must match either the number of elements in Z,
;       or the second dimension of Z if Z is a 2D array.
;   Z: A vector or 2D array representing the sample values.
;
; Keywords:
;   GROUP_LEADER: Set this to the widget ID of the group leader.
;
;   TEST: Set this keyword to use a default dataset for testing purposes.
;
; Notes:
;   To convert from X, Y, Z on a unit sphere to lat/lon coordinates:
;
;    longitude = ATAN(y, x)
;    latitude  = !PI/2 - ATAN(SQRT(x^2 + y^2), z)
;
function IDLitwdGridWizard, $
    xData, yData, fData, $
    UI_OBJECT=oUI, $
    GROUP_LEADER=groupLeader, $
    TEST=test

    compile_opt idl2, hidden

    ON_ERROR, 2

    ; Test data.
    if (KEYWORD_SET(test)) then begin
        np = 3
        n = 200
        seed = 12321
        xData = RANDOMU(seed, n) - 0.5
        yData = RANDOMU(seed, n) - 0.5
        fData = 1e5*EXP(-8*(xData^2 + yData^2))
        xData = 50*xData + 11
        yData = 400000*yData + 7
    endif else begin
        np = N_PARAMS()
        if (np ne 3) then $
            MESSAGE, 'Incorrect number of arguments.'

        nZDims = SIZE(fData, /N_DIMENSIONS)
        nX = N_ELEMENTS(xData)
        nY = N_ELEMENTS(yData)

        ; If Z is a 2D array, we allow X and/or Y to be vectors whose
        ; lengths match the corresponding dimension of Z.
        ;
        ; Otherwise, X and Y must have the same number of elements
        ; as Z.
        if (nZDims eq 2) then begin
            zDims = SIZE(fData, /DIMENSIONS)
            nZ = N_ELEMENTS(fData)
            if (nX eq zDims[0]) then begin
                newXData = MAKE_ARRAY(zDims, TYPE=SIZE(xData, /TYPE))
                for i=0,zDims[1]-1 do $
                    newXData[*,i] = xData
                xData = REFORM(newXData, nZ)
            endif else if (nX eq nZ) then begin
                xData = REFORM(xData, nZ)
            endif else $
                MESSAGE, 'X argument does not correspond to Z dimensions.'

            if (nY eq zDims[1]) then begin
                newYData = MAKE_ARRAY(zDims, TYPE=SIZE(yData, /TYPE))
                for i=0,zDims[0]-1 do $
                    newYData[i,*] = yData
                yData = REFORM(newYData, nZ)
            endif else if (nY eq nZ) then begin
                yData = REFORM(yData, nZ)
            endif else $
                MESSAGE, 'Y argument does not correspond to Z dimensions.'

            fData = REFORM(fData, nZ)
        endif else begin
            if ((nX ne N_ELEMENTS(fData)) || $
                (nY ne N_ELEMENTS(fData))) then $
                MESSAGE, 'Arguments must have same number of elements.'
        endelse
    endelse

    myname = 'IDLitwdGridWizard'

    xsize=600
    ysize=400

    hasNan = ~ARRAY_EQUAL(FINITE(fData), 1) || $
        ~ARRAY_EQUAL(FINITE(xData), 1) || $
        ~ARRAY_EQUAL(FINITE(yData), 1)

    xmin = MIN(xData, MAX=xmax, NAN=hasNan)
    ymin = MIN(yData, MAX=ymax, NAN=hasNan)
    fmin = MIN(fData, MAX=fmax, NAN=hasNan)

    if (hasNan) then begin
        good = WHERE(FINITE(xData) and FINITE(yData) and $
            FINITE(fData), nElts)
        if (nElts eq 0) then $
            MESSAGE, 'No valid points in X, Y, or Z.'
    endif else begin
        nElts = N_ELEMENTS(xData)
    endelse

    colors = BYTSCL(hasNan ? fData[good] : fData, $
        TOP=253, NAN=hasNan) + 1b

    x = 2*!PI*FINDGEN(19)/18
    USERSYM, COS(x), SIN(x)
    nElts = N_ELEMENTS(xData)
    oTool = OBJ_VALID(oUI) ? oUI->GetTool() : OBJ_NEW()

    state = { $
    ; These are needed for gridding.
        method: '', $
        xData: FLOAT(hasNan ? xData[good] : xData), $
        yData: FLOAT(hasNan ? yData[good] : yData), $
        fData: FLOAT(hasNan ? fData[good] : fData), $
        nElts: nElts, $
        range: FLOAT([xmin, ymin, xmax, ymax]), $
        pResult: PTR_NEW(0), $
        bSphere: 0b, $
        bRadians: 0b, $
        xdim: 25L, $                  ; Defaults
        ydim: 25L, $
        xstart: FLOAT(xmin), $        ; Defaults
        ystart: FLOAT(ymin), $
        xend: FLOAT(xmax), $
        yend: FLOAT(ymax), $
        missing: 0.0, $
        nmiss: 0L, $
        radialfunc: 0L, $
        aniso_ratio: 1.0, $
        aniso_theta: 0.0, $
        search_ellipse: [(xmax-xmin)/2.0, (ymax-ymin)/2.0, 0.0], $
        nsectors: 1, $
        empty_sectors: 0, $
        max_per_sector: nElts, $
        min_points: 1L, $
        power: 2.0, $
        smoothing: 0.0, $
   ; These are needed by widgets.
        screen: 0b, $
        frange: FLOAT([fmin, fmax]), $
        pMethods: PTR_NEW(0), $
        pTriangles: PTR_NEW(0), $
        colors: colors, $
        xsize: xsize, $
        ysize: ysize, $
        dwidth: 400, $   ; width of draw window
        dheight: 300, $  ; height of draw window
        wTopRow1: 0L, $
        wTopRow2: 0L, $
        wTopRow3: 0L, $
        wColumn1: 0L, $
        wColumn2: 0L, $
        wColumn3: 0L, $
        wXY: 0L, $
        wMethod: 0L, $
        useEllipse: 0b, $
        isDirty: 1b, $
        showpoints: (nElts lt 1000), $
        oTool: oTool, $
        oWin: OBJ_NEW(), $
        oContainer: OBJ_NEW()}

    pState = PTR_NEW(state)

    ; Only put the Help button on if we have a valid tool.
    if (OBJ_VALID(oTool)) then $
        helpPro = 'IDLitwdGridWizard_help'

    success = DIALOG_WIZARD('IDLitwdGridWizard_' + ['1', '2', '3'], $
        GROUP_LEADER=groupLeader, $
        HELP_PRO=helpPro, $
        TITLE='IDL Gridding Wizard', $
        UVALUE=pState, $
        SPACE=0, XPAD=0, YPAD=0, $
        XSIZE=xsize, YSIZE=ysize)



    ; Construct the Result.
    if (success) then begin

        output = *(*pState).pResult

        ; If our desired missing value isn't NaN,
        ; we need to replace all NaN's with the missing value.
        if (FINITE((*pState).missing)) then begin
            miss = WHERE(~FINITE(output), nmiss)
            if (nmiss gt 0) then $
                output[miss] = (*pState).missing
        endif

        xdelta = ((*pState).xend - (*pState).xstart)/((*pState).xdim - 1)
        ydelta = ((*pState).yend - (*pState).ystart)/((*pState).ydim - 1)

        xgrid = FINDGEN((*pState).xdim)*xdelta + (*pState).xstart
        ygrid = FINDGEN((*pState).ydim)*ydelta + (*pState).ystart

        result = { $
            method:(*pState).method, $
            result: output, $
            xgrid: xgrid, $
            ygrid: ygrid, $
            missing: (*pState).missing}

    endif else begin
        result = 0
    endelse

    ; Cleanup all my state variables.
    OBJ_DESTROY, (*pState).oContainer
    PTR_FREE, (*pState).pResult
    PTR_FREE, (*pState).pMethods
    PTR_FREE, (*pState).pTriangles
    PTR_FREE, pState

    return, result
end

