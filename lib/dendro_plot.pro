; $Id: //depot/idl/releases/IDL_80/idldir/lib/dendro_plot.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   DENDRO_PLOT
;
; PURPOSE:
;   Given a hierarchical tree cluster, as created by CLUSTER_TREE,
;   the DENDRO_PLOT procedure draws a two-dimensional dendrite plot
;   on the current direct graphics device.
;
; CALLING SEQUENCE:
;   DENDRO_PLOT, Clusters, Linkdistance
;
; INPUTS:
;   Clusters: A 2-by-(m-1) input array containing the cluster indices,
;       where m is the number of items in the original dataset.
;       This array is usually the result of the CLUSTER_TREE function.
;
;   Linkdistance: An (m-1)-element input vector containing the distances
;       between cluster items, as returned by the Linkdistance argument
;       to the CLUSTER_TREE function.
;
; KEYWORD PARAMETERS:
;   See the IDL Reference Manual for a description of the keywords.
;
; EXAMPLE:
;    ; Given a set of points in two-dimensional space.
;    m = 20
;    data = 7*RANDOMN(-1, 2, m)
;
;    ; Compute the Euclidean distance between each point.
;    distance = DISTANCE_MEASURE(data)
;
;    ; Compute the cluster analysis.
;    clusters = CLUSTER_TREE(distance, linkdistance, LINKAGE=2)
;
;    DENDRO_PLOT, clusters, linkdistance, $
;        POSITION=[0.08, 0.1, 0.48, 0.9], $
;        XSTYLE=9, YSTYLE=9, $
;        XTITLE='Leaf', YTITLE='Distance'
;
;    DENDRO_PLOT, clusters, linkdistance, $
;        ORIENTATION=1, /NOERASE, $
;        POSITION=[0.56, 0.1, 0.96, 0.9], $
;        XSTYLE=9, YSTYLE=9, $
;        XTITLE='Distance', YTITLE='Leaf'
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Sept 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro dendro_plot, clusters, linkdistance, $
    CHARSIZE=charsizeIn, $
    CHARTHICK=charthick, $
    COLOR=colorIn, $
    FONT=font, $
    LABEL_CHARSIZE=labelCharsizeIn, $
    LABEL_CHARTHICK=labelCharthickIn, $
    LABEL_COLOR=labelColorIn, $
    LABEL_NAMES=labelNamesIn, $
    LABEL_ORIENTATION=labelOrientIn, $
    LINECOLOR=lineColorIn, $
    LINESTYLE=lineStyle, $
    ORIENTATION=orientationIn, $
    OVERPLOT=overplot, $
    THICK=lineThick, $
    XRANGE=xrangeIn, YRANGE=yrangeIn, $
    XSTYLE=xstyleIn, YSTYLE=ystyleIn, $
    XTICKLEN=xticklenIn, YTICKLEN=yticklenIn, $
    XTICKS=xticksIn, YTICKS=yticksIn, $
    XTICKV=xtickvIn, YTICKV=ytickvIn, $
    XTICKNAME=xticknameIn, YTICKNAME=yticknameIn, $
    XTITLE=xtitleIn, YTITLE=ytitleIn, $
    _REF_EXTRA=_extra


    compile_opt idl2

    ON_ERROR, 2

    if (N_PARAMS() ne 2) then $
        MESSAGE, 'Incorrect number of arguments.'

    ; Retrieve the vertex and connectivity for the dendrogram.
    DENDROGRAM, clusters, linkdistance, outverts, outconn, $
        LEAFNODES=leafnodes

    dimC = SIZE(clusters, /DIMENSIONS)
    m = dimC[1] + 1

    if (N_ELEMENTS(labelNamesIn) eq m) then begin
        ; Rearrange labels to match the new leaf node positions.
        labelNames = labelNamesIn[leafnodes]
    endif else begin
        if (N_ELEMENTS(labelNamesIn) ne 1) then $
            labelNames = STRTRIM(leafnodes, 2)
    endelse

    color = (N_ELEMENTS(colorIn) gt 0) ? colorIn : !P.color
    charsize = N_ELEMENTS(charsizeIn) ? charsizeIn : $
        (!P.CHARSIZE ne 0 ? !P.CHARSIZE : 1)
    lineColor = (N_ELEMENTS(lineColorIn) gt 0) ? lineColorIn : color


    orientation = (N_ELEMENTS(orientationIn) eq 1) ? orientationIn : 0

    xrange = (N_ELEMENTS(xrangeIn) eq 2) ? xrangeIn : [-1, m]
    maxx = MAX(outverts[1,*], MIN=minn)
    yrange = (N_ELEMENTS(yrangeIn) eq 2) ? yrangeIn : $
        [minn, maxx + 0.1*(maxx - minn)]


    if (orientation lt 0) || (orientation gt 3) || $
        (orientation ne FIX(orientation)) then $
        MESSAGE, 'Illegal keyword value for ORIENTATION.'

    if ((orientation eq 0) || (orientation eq 2)) then begin
        xx = REFORM(outverts[0,*], 4, m-1)
        yy = REFORM(outverts[1,*], 4, m-1)
        xticklen = 1e-5
        xticks = 1
        xtickname = [' ',' ']   ; suppress
        if (orientation eq 2) then $
            yrange = yrange[[1,0]]
        ; Allow these keywords for the Y axis.
        if (N_ELEMENTS(ytitleIn) eq 1) then $
            ytitle = ytitleIn
        if (N_ELEMENTS(yticklenIn) gt 0) then $
            yticklen = yticklenIn
        if (N_ELEMENTS(yticksIn) gt 0) then $
            yticks = yticksIn
        if (N_ELEMENTS(ytickvIn) gt 0) then $
            ytickv = ytickvIn
        if (N_ELEMENTS(yticknameIn) gt 0) then $
            ytickname = yticknameIn
    endif else begin
        xx = REFORM(outverts[1,*], 4, m-1)
        yy = REFORM(outverts[0,*], 4, m-1)
        tmp = xrange
        xrange = (orientation eq 1) ? yrange : yrange[[1,0]]
        yrange = tmp
        yticklen = 1e-5
        yticks = 1
        ytickname = [' ',' ']   ; suppress
        ; Allow these keywords for the X axis.
        if (N_ELEMENTS(xtitleIn) eq 1) then $
            xtitle = xtitleIn
        if (N_ELEMENTS(xticklenIn) gt 0) then $
            xticklen = xticklenIn
        if (N_ELEMENTS(xticksIn) gt 0) then $
            xticks = xticksIn
        if (N_ELEMENTS(xtickvIn) gt 0) then $
            xtickv = xtickvIn
        if (N_ELEMENTS(xticknameIn) gt 0) then $
            xtickname = xticknameIn
    endelse


    if (~KEYWORD_SET(overplot)) then begin
        xstyle = (N_ELEMENTS(xstyleIn) eq 1) ? xstyleIn : 1
        ystyle = (N_ELEMENTS(ystyleIn) eq 1) ? ystyleIn : 1

        PLOT, [0,1], /NODATA, $
            CHARSIZE=charsize, $
            CHARTHICK=charthick, $
            COLOR=color, $
            FONT=font, $
            XSTYLE=xstyle, $
            YSTYLE=ystyle, $
            XTICKLEN=xticklen, YTICKLEN=yticklen, $
            XRANGE=xrange, YRANGE=yrange, $
            XTICKS=xticks, YTICKS=yticks, $
            XTICKV=xtickv, YTICKV=ytickv, $
            XTICKNAME=xtickname, YTICKNAME=ytickname, $
            XTITLE=xtitle, YTITLE=ytitle, $
            _EXTRA=_extra
    endif


    for i=0,m-2 do begin
        PLOTS, xx[*,i], yy[*,i], $
            COLOR=lineColor, $
            LINESTYLE=lineStyle, $
            THICK=lineThick
    endfor


    if (N_ELEMENTS(labelNames) eq m) then begin

        ; Construct the labels. This is complicated because we can't use AXIS
        ; ticks (because there is a limit of 60), and so we need to compute
        ; the positions ourself. We also allow different label angles.

        labelColor = (N_ELEMENTS(labelColorIn) gt 0) ? $
            labelColorIn : color
        labelCharsize = (N_ELEMENTS(labelCharsizeIn) gt 0) ? $
            labelCharsizeIn : charsize
        if (labelCharsize le 0) then $
            labelCharsize = 1
        if (N_ELEMENTS(labelCharthickIn) gt 0) then $
            labelCharthick = labelCharthickIn $
        else if (N_ELEMENTS(charthick) gt 0) then $
            labelCharthick = charthick

        xdevice = labelCharsize*!D.x_ch_size
        char = CONVERT_COORD([[0,0], [xdevice, 0]], /DEVICE, /TO_DATA)
        width = char[0,1] - char[0,0]
        ydevice = labelCharsize*!D.y_ch_size
        char = CONVERT_COORD([[0,0], [0, ydevice]], /DEVICE, /TO_DATA)
        height = char[1,1] - char[1,0]
        char = CONVERT_COORD([[0,0], [ydevice, 0]], /DEVICE, /TO_DATA)
        sideways = char[0,1] - char[0,0]

        if ((orientation eq 0) || (orientation eq 2)) then begin
            xloc = LINDGEN(m)
            yloc = FLTARR(m)
            ; If label orient not provided, rotate by 90 deg if labels
            ; are too long. This is just a guess.
            labelOrient = N_ELEMENTS(labelOrientIn) ? labelOrientIn : $
                ((MAX(STRLEN(labelNames)) le 2) ? 0 : 90)
        endif else begin
            xloc = FLTARR(m)
            yloc = LINDGEN(m)
            labelOrient = N_ELEMENTS(labelOrientIn) ? labelOrientIn : 0
        endelse

        ; Reduce orientation to -180...+180
        labelOrient mod= 360
        if (labelOrient gt 180) then labelOrient -= 360 $
        else if (labelOrient lt -180) then labelOrient += 360
        angle = FLOAT(labelOrient)

        case orientation of

            0: begin      ; leafs at bottom
                if (angle eq 0) then begin
                    labelAlign = 0.5
                    yloc -= 1.5*height
                endif else begin
                    labelAlign = (angle gt 0) ? 1 : 0
                    ; Adjust baseline for pivoting about the bottom.
                    yloc -= (1.4 - ABS(angle)/90)*height
                    xloc += 0.4*sideways*(angle gt 0 ? 1 : -1)
                endelse
               end

            2: begin      ; leafs at top
                labelAlign = (angle eq 0) ? 0.5 : $
                    ((angle gt 0) ? 0 : 1)

                yloc += 0.4*height
                xloc += 0.4*sideways*angle/90 + $
                    0.4*width*(1-ABS(angle)/90)*(angle gt 0 ? -1 : 1)
               end

            1: begin      ; leafs at left
                if (ABS(angle) eq 90) then begin
                    labelAlign = 0.5
                    xloc -= 0.75*width
                    if (angle eq -90) then $
                        xloc -= 0.8*sideways
                endif else begin
                    labelAlign = 1
                    xloc -= width* $
                        (angle eq 0 ? 0.5 : (angle gt 0 ? 0.3 : 1))
                    yloc -= height* $
                        (angle eq 0 ? 0.4 : (angle gt 0 ? 0.1 : 0.5))
                endelse
               end

            3: begin      ; leafs at right
                if (ABS(angle) eq 90) then begin
                    labelAlign = 0.5
                    xloc += 0.75*width
                    if (angle eq 90) then $
                        xloc += 0.8*sideways
                endif else begin
                    labelAlign = 0
                    xloc += width* $
                        (angle eq 0 ? 0.5 : (angle gt 0 ? 1.1 : 0.3))
                    yloc -= height* $
                        (angle eq 0 ? 0.4 : (angle gt 0 ? 0.5 : 0.1))
                endelse
               end

        endcase

        XYOUTS, xloc, yloc, labelNames, $
            ALIGN=labelAlign, $
            CHARSIZE=labelCharsize, $
            CHARTHICK=labelCharthick, $
            COLOR=labelColor, $
            FONT=font, $
            ORIENTATION=labelOrient
    endif

    ; Add the title for the leaf axis.
    if ((orientation eq 0) || (orientation eq 2)) then begin
        if (N_ELEMENTS(xtitleIn) eq 1) then begin
            AXIS, XAXIS=(orientation eq 2), $
                CHARSIZE=charsize, $
                CHARTHICK=charthick, $
                COLOR=color, $
                FONT=font, $
                XSTYLE=xstyle, $
                XTICKLEN=1e-5, $
                XTICKS=1, XTICKNAME = [' ',' '], $
                XTITLE=xtitleIn
        endif
    endif else begin
        if (N_ELEMENTS(ytitleIn) eq 1) then begin
            AXIS, YAXIS=(orientation eq 3), $
                CHARSIZE=charsize, $
                CHARTHICK=charthick, $
                COLOR=color, $
                FONT=font, $
                YSTYLE=ystyle, $
                YTICKLEN=1e-5, $
                YTICKS=1, YTICKNAME = [' ',' '], $
                YTITLE=ytitleIn
        endif
    endelse

end

