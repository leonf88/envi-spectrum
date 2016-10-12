; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itdatalevel.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


;;-------------------------------------------------------------------------
;; CW_itDataLevel_KillNotify
;;
;; Purpose: Clean up resources
pro CW_itDataLevel_KillNotify, wChild

    compile_opt idl2, hidden

    WIDGET_CONTROL, wChild, GET_UVALUE=state, /NO_COPY
    OBJ_DESTROY, [state.oView, state.oPalTexture]
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_TrimZeroes
;;
;; Purpose: Format string for widget display
function CW_itDataLevel_TrimZeroes, str

    compile_opt idl2, hidden

    return, STRING(str, FORMAT='(G0)')

end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_PrepEvent
;;
;; Purpose: Convenience routine to prepare a CW_ITDATALEVEL event
;;    that contains the results of the widget interaction with the user.
;;
;; Parameters:
;;    state - CW_ITDATALEVEL widget state structure
;;    event - Incoming event structure for event that requires
;;      a corresponding CW_ITDATALEVEL event to be prepared.
;;
;; Outputs:
;;    This function returns a CW_ITDATALEVEL event structure.
;;    Note that this event structure is unnamed so that it can
;;    accommodate a variable number of levels being reported.
;;
function CW_itDataLevel_PrepEvent, state, event, MOTION=motion, TEXT=text

    compile_opt idl2, hidden

    ;; Convert data from plot coords to data coords
    levelVals = state.positions / state.maxPosition
    levelVals = levelVals * (state.dataMax - state.dataMin) + state.dataMin

    ;; Build event structure
    myEvent = { $
                ID: event.handler, TOP: event.top, HANDLER: 0L, $
                LEVEL_VALUES: levelVals, $
                MIN_MAX: [state.dataMin,state.dataMax], $
                MOTION: KEYWORD_SET(motion), $
                TEXT: KEYWORD_SET(text) }

    return, myEvent
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_UpdatePlot
;;
;; Purpose: Convenience routine to update level lines and widgets.
;;
;; Parameters:
;;    state - CWITDATALEVEL widget state structure

pro CW_itDataLevel_UpdatePlot, state

    compile_opt idl2, hidden

    bValidData = OBJ_VALID(state.dataObject)

    ;; Update line position and text widget value for each data level
    for i=0, state.nLevels-1 do begin
        ;; Update level lines and their grips.
        state.oLineModels[i]->Reset
        if state.bVertical then $
            state.oLineModels[i]->Translate, 0, state.positions[i] / state.pixelsPerValue, 0 $
        else $
            state.oLineModels[i]->Translate, state.positions[i] / state.pixelsPerValue, 0, 0
        ;; Update text widgets.
        if (bValidData) then begin
        val = state.positions[i] / state.maxPosition
        val = val * (state.dataMax - state.dataMin) + state.dataMin
        val = CW_itDataLevel_TrimZeroes(STRING(val))
        endif else val = ' '
        WIDGET_CONTROL, state.wText[i], SET_VALUE=val
    endfor

    ;; Update position of lockbar and its grips.
    if state.nLevels gt 1 then begin
        low = state.positions[0] / state.pixelsPerValue
        high = state.positions[state.nLevels-1] / state.pixelsPerValue
        state.oLockModel->Reset
        if state.bVertical then $
            state.oLockModel->Translate, 0, (low+high)/2, 0 $
        else $
            state.oLockModel->Translate, (low+high)/2, 0, 0
    endif

    if state.bRedraw then begin
        state.bRedraw = 0b
        state = cw_itdatalevel_setplot(state)
    endif
    WIDGET_CONTROL, state.wDraw, GET_VALUE=oWindow
    if OBJ_VALID(oWindow) then $
        oWindow->Draw, state.oView
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_SetPlot
;;
;; Purpose: Convenience routine to set up the graphical data for the
;;    current dataset.
;;
;; Parameters:
;;    state - CW_ITDATALEVEL widget state structure

function CW_itDataLevel_SetPlot, state

    compile_opt idl2, hidden

    ;; Invoke HISTOGRAM carefully
    bValidData = 0b
    if (OBJ_VALID(state.dataObject) ne 0) then $
        bValidData = state.dataObject->GetData(pData, /POINTER)

    if (bValidData) then begin
        type = SIZE(*pData, /TYPE)

        ; Either use NBINS for float data, or BINSIZE for integers.
        if (type eq 4) || (type eq 5) then $  ; Float or double precision.
            nbins = 256 $
        else $
            binSize = ((state.dataMax - state.dataMin) / 255.0) > 1

        plot = HISTOGRAM(*pData, $
            BINSIZE=binSize, $
            NBINS=nbins, $
            MIN=state.dataMin, MAX=state.dataMax, /NAN)

        hidePlot = 0b
        if N_ELEMENTS(plot) lt 2 then begin
            plot = [0.0,1.0]
            hidePlot = 1b
        endif
    endif else begin
        plot = [0.0,1.0]
        hidePlot = 1b
    endelse

    ;; Get the extents that we'll need to do the layout.
    if state.bVertical then begin
        yExtent = N_ELEMENTS(plot)
        xExtent = MAX(plot) * 1.05  ; provides some space at the right
    endif else begin
        xExtent = N_ELEMENTS(plot)
        yExtent = MAX(plot) * 1.05  ; provides some space at the top
    endelse

    ;; Init the palette polygon texture and position the polygon in the view.
    ;; The view layout is as follows:  (Extent is the histogram plot maximum)
    ;; - Histogram plot: [0 : Extent]
    ;; Left/Bottom grip area: [ -gripSize*Extent : 0]
    ;; Palette Area (optional): [Extent : Extent+Extent*palSize]
    ;; Right/Top grip area: [Extent+Extent*palSize : Extent+Extent*palSize+gripSize]
    state.oPalPoly->SetProperty, HIDE=1
    palSize = 0  ;; fraction of extent
    if OBJ_VALID(state.paletteObject) then begin
        success = state.paletteObject->GetData(data)
        if success then begin
            palSize = 0.2
            state.oPalTexture->SetProperty, DATA=[ [[data]], [[data]] ]
            state.oPalPoly->SetProperty, HIDE=0
            if state.bVertical then begin
                state.oPalPoly->SetProperty, XCOORD_CONV=[xExtent, xExtent*palSize], YCOORD_CONV=[0, yExtent], $
                    TEXTURE_COORD=[[0,0],[0,1],[1,1],[1,0]]
            endif else begin
                state.oPalPoly->SetProperty, XCOORD_CONV=[0, xExtent], YCOORD_CONV=[yExtent, yExtent*palSize], $
                    TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]]
            endelse
        endif
    endif

    ;; Init and layout the plot, lines, and grips.
    gripSize = 0.07 ;; fraction of extent

    ; Convert the histogram data into a line chart, with narrow spikes
    ; at each bin.
    n = N_ELEMENTS(plot)
    xdata = LINDGEN(3*n)/3         ; 0,0,0, 1,1,1, 2,2,2,...
    ydata = LONARR(3,n)
    ydata[1,0] = REFORM(TEMPORARY(plot),1,n)   ; 0,y0,0, 0,y1,0, 0,y2,0, ...
    ydata = REFORM(ydata, 3*n, /OVERWRITE)

    if state.bVertical then begin
        state.pixelsPerValue = DOUBLE(state.ySize) / yExtent
        state.oView->SetProperty, VIEWPLANE_RECT=[-xExtent * gripSize, 0, $
                                                  xExtent*(1+2*gripSize+palSize), yExtent], $
            COLOR=(hidePlot ? [128,128,128] : [255,255,255])
        ; Note that xdata and ydata are reversed for the vertical plot.
        state.oPlot->SetProperty, DATAX=ydata, DATAY=xdata, $
            HIDE=hidePlot or state.bHideHistogram
        state.oGripBackground1->SetProperty, YCOORD_CONV=[0, yExtent], $
            XCOORD_CONV=[-xExtent*gripSize, xExtent*gripSize]
        state.oGripBackground2->SetProperty, YCOORD_CONV=[0, yExtent], $
            XCOORD_CONV=[xExtent+xExtent*palSize, xExtent*gripSize]
        for i=0, state.nLevels-1 do begin
            state.oLines[i]->SetProperty, XCOORD_CONV=[0.0, xExtent+xExtent*palSize], $
                HIDE=hidePlot
            ;; Scale grip and position it along the level line.
            state.oGrips1[i]->SetProperty, YCOORD_CONV=[0.0,  (xExtent*gripSize)* $
                                            (yExtent/xExtent)*(FLOAT(state.xSize)/state.ySize)], $
                                           XCOORD_CONV=[-xExtent*gripSize, xExtent*gripSize], $
                                           HIDE=hidePlot
            state.oGrips2[i]->SetProperty, YCOORD_CONV=[0.0,  (xExtent*gripSize)* $
                                            (yExtent/xExtent)*(FLOAT(state.xSize)/state.ySize)], $
                                           XCOORD_CONV=[xExtent*(1+palSize), xExtent*gripSize], $
                                           HIDE=hidePlot
        endfor
        ;; Set dimensions of lock bar
        if state.nLevels gt 1 then begin
            state.oLockGrip1->SetProperty, YCOORD_CONV=[0.0,  (xExtent*gripSize)* $
                                            (yExtent/xExtent)*(FLOAT(state.xSize)/state.ySize)], $
                                         XCOORD_CONV=[-xExtent*gripSize, xExtent*gripSize], $
                                         HIDE=hidePlot
            state.oLockGrip2->SetProperty, YCOORD_CONV=[0.0,  (xExtent*gripSize)* $
                                            (yExtent/xExtent)*(FLOAT(state.xSize)/state.ySize)], $
                                         XCOORD_CONV=[xExtent*(1+palSize+gripSize), xExtent*gripSize], $
                                         HIDE=hidePlot
            state.oLockLine->SetProperty, XCOORD_CONV=[0.0, xExtent*(1+palSize)], $
                HIDE=hidePlot
        endif
    endif $
    ;; Horizontal
    else begin
        state.pixelsPerValue = DOUBLE(state.xSize) / xExtent
        state.oView->SetProperty, VIEWPLANE_RECT=[0, -yExtent * gripSize, $
                                                  xExtent, yExtent*(1+2*gripSize+palSize)], $
            COLOR=(hidePlot ? [128,128,128] : [255,255,255])
        state.oPlot->SetProperty, DATAX=xdata, DATAY=ydata, $
            HIDE=hidePlot or state.bHideHistogram
        state.oGripBackground1->SetProperty, XCOORD_CONV=[0, xExtent], $
            YCOORD_CONV=[-yExtent*gripSize, yExtent*gripSize]
        state.oGripBackground2->SetProperty, XCOORD_CONV=[0, xExtent], $
            YCOORD_CONV=[yExtent+yExtent*palSize, yExtent*gripSize]
        for i=0, state.nLevels-1 do begin
            state.oLines[i]->SetProperty, YCOORD_CONV=[0.0, yExtent+yExtent*palSize], $
                HIDE=hidePlot
            ;; Scale grip and position it along the level line.
            state.oGrips1[i]->SetProperty, XCOORD_CONV=[0.0, (yExtent*gripSize)* $
                                            (xExtent/yExtent)*(FLOAT(state.ySize)/state.xSize)], $
                                           YCOORD_CONV=[-yExtent*gripSize, yExtent*gripSize], $
                                           HIDE=hidePlot
            state.oGrips2[i]->SetProperty, XCOORD_CONV=[0.0, (yExtent*gripSize)* $
                                            (xExtent/yExtent)*(FLOAT(state.ySize)/state.xSize)], $
                                           YCOORD_CONV=[yExtent*(1+palSize), yExtent*gripSize], $
                                           HIDE=hidePlot
        endfor
        ;; Set dimensions of lock bar
        if state.nLevels gt 1 then begin
            state.oLockGrip1->SetProperty, XCOORD_CONV=[0.0, (yExtent*gripSize)* $
                                            (xExtent/yExtent)*(FLOAT(state.ySize)/state.xSize)], $
                                         YCOORD_CONV=[-yExtent*gripSize, yExtent*gripSize], $
                                         HIDE=hidePlot
            state.oLockGrip2->SetProperty, XCOORD_CONV=[0.0, (yExtent*gripSize)* $
                                            (xExtent/yExtent)*(FLOAT(state.ySize)/state.xSize)], $
                                         YCOORD_CONV=[yExtent*(1+palSize+gripSize), yExtent*gripSize], $
                                         HIDE=hidePlot
            state.oLockLine->SetProperty, YCOORD_CONV=[0.0, yExtent*(1+palSize)], $
                HIDE=hidePlot
        endif
    endelse

    CW_itDataLevel_UpdatePlot, state
    return, state
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_SetData
;;
;; Purpose: Set the data object, and computes the data min and max.
;;
;; Parameters:
;;    state - CW_ITDATALEVEL widget state structure
;;    dataObject - A reference to the data object to be associated
;;        with this compound widget.
;;
function CW_itDataLevel_SetData, state, dataObject

    compile_opt idl2, hidden

    bValidData = 0b
    if (OBJ_VALID(dataObject) ne 0) then $
        bValidData = dataObject->GetData(pData, /POINTER)

    if (bValidData) then begin
        state.dataObject = dataObject

        if (state.bAutoRange) then begin
            dataMin = MIN(*pData, MAX=dataMax, /NAN)
            state.dataMin = dataMin
            state.dataMax = dataMax
        endif

        ;; Sensitize the text widgets.
        for i=0,state.nLevels-1 do $
            WIDGET_CONTROL, state.wText[i], SENSITIVE=1
    endif else begin
        state.dataObject = OBJ_NEW()
        if (state.bAutoRange) then begin
            state.dataMin = 0.0
            state.dataMax = 1.0
        endif

        ;; De-sensitize the text widgets.
        for i=0,state.nLevels-1 do $
            WIDGET_CONTROL, state.wText[i], SENSITIVE=0
    endelse

    return, state
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_SetPositions
;;
;; Purpose: Set the positions of the data levels for the state's
;;    data object based on the given initial values (or, if no
;;    initial values are provided, evenly distribute along the
;;    data range).
;;
;; Parameters:
;;    state - CW_ITDATALEVEL widget state structure
;;    initialValues - The initial values (optional).
;;
function CW_itDataLevel_SetPositions, state, initialValues

    compile_opt idl2, hidden

    bHavePositions = 0b
    if (N_ELEMENTS(initialValues) gt 0) then begin
        if (N_ELEMENTS(initialValues) ne state.nLevels) then begin
            oTool = state.oUI->GetTool()
            if (OBJ_VALID(oTool)) then $
              oTool->SignalError, $
              IDLitLangCatQuery('UI:cwDataLevel:InitValsNENLevels')
            return, state
        endif

        if (OBJ_VALID(state.dataObject)) then begin
            if state.dataMax eq state.dataMin then begin
                state.positions[*] = 0
            endif $
            else begin
                vals = (initialValues - state.dataMin) / $
                    (state.dataMax-state.dataMin)
                state.positions = (0 > vals < 1) * state.maxPosition
            endelse
            bHavePositions = 1b
        endif
    endif

    if (bHavePositions eq 0) then begin
        ;; Spread lines out nicely
        vals = (FINDGEN(state.nLevels)+0.5)/state.nLevels
        state.positions = vals * state.maxPosition
    endif

    return, state
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_SetValue
;;
;; Purpose: Sets the value of this compound widget.
;;
;; Parameters:
;;     wid:  Widget id of this compound widget.
;;     value: A structure of the form:
;;        {DATA_OBJECT: dataObj, $
;;         LEVEL_VALUES: DBLARR(nLevels)}
;;
;;     If LEVEL_VALUES are not supplied, they are generated by SetPositions.
;;
;;       Optionally, the structure may also have the following
;;       fields:
;;         DATA_RANGE: [dmin, dMax]
;;         AUTO_COMPUTE_RANGE: autoComputeFlag
;;         PALETTE_OBJECT: paletteObject
;;
pro CW_itDataLevel_SetValue, wid, value
    compile_opt idl2, hidden

    tags = TAG_NAMES(value)

    child = WIDGET_INFO(wid, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ;; DATA_OBJECT must be supplied
    if WHERE(tags eq 'DATA_OBJECT') eq -1 then begin
        oTool = state.oUI->GetTool()
        if (OBJ_VALID(oTool)) then $
          oTool->SignalError, $
          IDLitLangCatQuery('UI:cwDataLevel:BadSetVal')
        return
    endif

    bAutoRangeSet = 0b
    if (WHERE(tags eq 'AUTO_COMPUTE_RANGE') ne -1) then begin
       state.bAutoRange = (value.auto_compute_range[0] ne 0) ? 1b : 0b
       if (state.bAutoRange) then begin
            bAutoRangeSet = 1b
            state.dataMin = 0.0d
            state.dataMax = 1.0d
       endif
    endif

    if (WHERE(tags eq 'DATA_RANGE') ne -1) then begin
        if (bAutoRangeSet eq 0) then begin
            state.bAutoRange = 0b
            state.dataMin = value.data_Range[0]
            state.dataMax = value.data_Range[1]
        endif
    endif

    ; Set the data.
    state = CW_itDataLevel_SetData(state, value.data_object)
    if (WHERE(tags eq 'PALETTE_OBJECT') ne -1) then begin
        state.paletteObject = value.palette_object
    endif else begin
        state.paletteObject = OBJ_NEW()
    endelse

    ; Update the positions.
    if ((WHERE(tags eq 'LEVEL_VALUES') eq -1) || $
        (~OBJ_VALID(state.dataObject))) then $
        state = CW_itDataLevel_SetPositions(state) $
    else $
        state = CW_itDataLevel_SetPositions(state, value.level_values)

    ; Update the histogram plot.
    state = CW_itDataLevel_SetPlot(state)

    WIDGET_CONTROL, child, SET_UVALUE=state
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_GetValue
;;
;; Purpose: Gets the value of this compound widget.
;;
;; Parameters:
;;     wid:  Widget id of this compound widget.
;;
;; Outputs:
;;     A structure of the form:
;;        {DATA_OBJECT: dataObj, $
;;         LEVEL_VALUES: DBLARR(nLevels)}
;;
function CW_itDataLevel_GetValue, wid
    compile_opt idl2, hidden

    child = WIDGET_INFO(wid, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    levelVals = state.positions / state.maxPosition
    levelVals = levelVals * (state.dataMax - state.dataMin) + state.dataMin

    myVal = {DATA_OBJECT: state.dataObject, $
             LEVEL_VALUES: levelVals }

    return, myVal
end

;;-------------------------------------------------------------------------
;; CW_itDataLevel_Event
;;
;; Purpose: Main event handler
;;
;; Parameters:
;;    event - Incoming event structure.
function CW_itDataLevel_Event, event

    compile_opt idl2, hidden

    ON_IOERROR, NULL

    retEvent = 0

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    switch TAG_NAMES(event, /STRUCTURE_NAME) of

    'WIDGET_DRAW' : begin

        switch event.type of
        ;------------------------------------------------------
        0:  begin ;; button press
            if (event.press ne 1) then $  ; only allow left button
                return, 0
            ; Return quickly if no data currently loaded.
            if (OBJ_VALID(state.dataObject) eq 0) then $
                return, 0
            ;; Do an Object Graphics Select to see if user clicked on
            ;; lock bar.
            if state.nLevels gt 1 then begin
                WIDGET_CONTROL, state.wDraw, GET_VALUE=oWindow
                if OBJ_VALID(oWindow) then begin
                    oSel = oWindow->Select(state.oView, [event.x, event.y])
                    if OBJ_VALID(oSel[0]) then begin
                        if oSel[0] eq state.oLockModel then begin
                            ;; User picked the lock bar
                            state.currLevel = -2  ;; means tracking the lock bar
                            ;; remember for delta calc
                            state.deltaXY = [event.x, event.y]
                            WIDGET_CONTROL, child, SET_UVALUE=state
                            break
                        endif
                    endif
                endif
            endif

            ;; Start tracking a single level bar
            state.currLevel = 0
            ;; Determine which line to track
            eventPos = state.bVertical ? event.y : event.x
            if state.nLevels gt 1 then begin
                ;; Find the line closest to the cursor.
                ;; If there is a tie, use the lower-numbered line
                ;; if the cursor is to left/bot and the higher one if
                ;; it is to the right/top.
                pos = state.positions
                dist = ABS(eventPos - pos)
                mindist = MIN(dist)
                ind = WHERE(dist eq mindist, count)
                if count eq 1 then $
                    state.currLevel = ind[0] $
                else if eventPos le pos[ind[0]] then $
                    state.currLevel = ind[0] $
                else $
                    state.currLevel = ind[count-1]
            endif
            if state.positions[state.currLevel] ne eventPos then begin
                state.positions[state.currLevel] = eventPos
                ;; Send event and update visual
                retEvent = CW_itDataLevel_PrepEvent(state, event, /MOTION)
                CW_itDataLevel_UpdatePlot, state
            endif
            WIDGET_CONTROL, child, SET_UVALUE=state
            break
            end
        ;------------------------------------------------------
        1:  ;; button release - fall through
        2:  begin ;; motion
            ; Return quickly if no data currently loaded.
            if (OBJ_VALID(state.dataObject) eq 0) then $
                return, 0

            ;; If tracking, update visual and send event
            if state.currLevel gt -1 then begin
                eventPos = state.bVertical ? event.y : event.x
                ;; See if position actually changed
                new = (eventPos > 0) < state.maxPosition ; clamp to viewport
                bChanged = new ne state.positions[state.currLevel]
                ;; Update visual if value has changed
                if bChanged then begin
                    ;; update line we are tracking
                    state.positions[state.currLevel] = new
                    ;; move lines we bumped into on the left
                    for i=0, state.currLevel-1 do $
                        state.positions[i] = state.positions[i] < new
                    ;; move lines we bumped into on the right
                    for i=state.currLevel+1, state.nLevels-1 do $
                        state.positions[i] = state.positions[i] > new
                endif
                ;; Send event if we had a change caused by motion or
                ;;  we had a button release.
                ;; Also update the displays.
                if (bChanged || (event.release eq 1)) then begin
                    retEvent = CW_itDataLevel_PrepEvent(state, event, $
                        MOTION=event.type-1)
                    CW_itDataLevel_UpdatePlot, state
                    ;; Done tracking if button was released
                    if (event.release eq 1) then $
                        state.currLevel = -1
                endif
                WIDGET_CONTROL, child, SET_UVALUE=state
            endif

            ;; User is dragging the lock bar
            if state.currLevel eq -2 then begin
                ;; calc movement delta
                delta = [event.x, event.y] - state.deltaXY
                eventDelta = state.bVertical ? delta[1] : delta[0]
                ;; constrain movement to window
                if state.positions[0] + eventDelta lt 0 then $
                    eventDelta = -state.positions[0]
                if state.positions[state.nLevels-1] + eventDelta gt state.maxPosition then $
                    eventDelta = state.maxPosition - state.positions[state.nLevels-1]
                ;; Apply delta to all the lines
                if eventDelta ne 0 then begin
                    state.positions += eventDelta
                endif
                ;; Update for next delta calc
                state.deltaXY = [event.x, event.y]
                ;; Send event if we had a change caused by motion or
                ;;  we had a button release.
                ;; Also update the displays.
                if (eventDelta || (event.release eq 1)) then begin
                    retEvent = CW_itDataLevel_PrepEvent(state, event, $
                        MOTION=event.type-1)
                    CW_itDataLevel_UpdatePlot, state
                    ;; Done tracking if button was released
                    if (event.release eq 1) then $
                        state.currLevel = -1
                endif
                WIDGET_CONTROL, child, SET_UVALUE=state
            endif

            break
            end
        ;------------------------------------------------------
        4: begin ;; expose
            WIDGET_CONTROL, state.wDraw, GET_VALUE=oWindow
            oWindow->SetCurrentCursor, 'ARROW'
            oWindow->Draw, state.oView
           end
        else:
        endswitch
        break
    end ; widget_draw
    ;------------------------------------------------------
    'WIDGET_TEXT_CH':
    'WIDGET_KBRD_FOCUS': begin
        ;; Get index of text widget causing event.
        iLevel = (WHERE(state.wText eq event.id))[0]

        ;; Only watch leave events for our widgets
        if TAG_NAMES(event, /STRUCTURE_NAME) eq 'WIDGET_KBRD_FOCUS' then begin

            if event.enter or (iLevel eq -1) then $
                break
        endif

        ;; Save current values in case user typed in invalid data.
        ON_IOERROR, io_error
        old_values = state.positions

        ;; Read all the text widgets
        values = DBLARR(state.nLevels)
        for i=0, state.nLevels-1 do begin
            WIDGET_CONTROL, state.wText[i], GET_VALUE=val
            values[i] = val
        endfor

        ON_IOERROR, NULL

        ;; Simulate what we do with the interactive lines by
        ;; bumping the values so that values below the changed
        ;; value are less or equal and the values above the
        ;; changed value are greater or equal
        for i=0, iLevel-1 do $
            values[i] = values[i] < values[iLevel]
        for i=iLevel+1, state.nLevels-1 do $
            values[i] = values[i] > values[iLevel]

        ;; If allowed, update data min and max values
        IF state.bExtendableRanges THEN BEGIN
          tempArray = [state.dataMin,state.dataMax]
          FOR i=0,state.nLevels-1 DO BEGIN
            state.dataMin <= (values[i] > 0.0)
            state.dataMax >= values[i]
          ENDFOR
          IF ~ARRAY_EQUAL(tempArray,[state.dataMin,state.dataMax]) THEN $
            state.bRedraw=1b
        ENDIF

        ;; Convert modified value from data to plot coords
        levPos = (values - state.dataMin) / (state.dataMax - state.dataMin)
        levPos = ((levPos * state.maxPosition) > 0.0) < (state.maxPosition)
        if not ARRAY_EQUAL(state.positions, levPos) then begin
            state.positions = levPos
            retEvent = CW_itDataLevel_PrepEvent(state, event, /TEXT)
        endif
        CW_itDataLevel_UpdatePlot, state
        WIDGET_CONTROL, child, SET_UVALUE=state
        return, retEvent

        io_error:
        state.positions = old_values
        CW_itDataLevel_UpdatePlot, state
        WIDGET_CONTROL, child, SET_UVALUE=state
        break
    end ; widget_text_ch
    else:
    endswitch

    return, retEvent
end

;-------------------------------------------------------------------------
;+
; NAME:
;   cw_itDataLevel
;
; PURPOSE:
;   This function implements a compound widget that allows the
;   user to select data "levels" against a density plot background
;   for the given data object.
;
;   An example of typical usage is to select an iso value from a
;   volume to generate an isosurface.
;
; CALLING SEQUENCE:
;   Result = CW_ITDATALEVEL(Parent, ToolUI)
;
; INPUTS:
;   Parent: The widget ID of the parent base.
;
;   ToolUI: The UI Object for the tool
;
; KEYWORD PARAMETERS
;   COLORS - A 3xn array of RGB colors.  This specifies the color used to
;     draw each of the NLEVELS data level lines in the widget.  If there
;     are fewer colors than levels, the colors are reused.  If COLORS is
;     not specified, the colors Red, Green, Blue, Yellow, Magenta, and Cyan
;     are used.
;
;   COLUMN - Set this keyword to a nonzero value to indicate that
;     the text fields (representing the editable data level values) are
;     to be organized in a column.  By default, they are organized in
;     a row.
;
;   DATA_OBJECT - A reference to the data object for which data level values
;     are to be editable.
;
;   DATA_RANGE - A two-element vector representing the range for the
;     data.  If this keyword is not provided, the data range is automatically
;     computed from the data object.
;
;   INITIAL_VALUES - A vector of NLEVELS data values representing
;     the intial level values.  By default, the initial values are
;     evenly distributed within the range of values of the given data object.
;
;   LEVEL_NAMES - A vector of strings representing the names to be
;     assicated with each level.  The default is the empty string
;     for each level.
;
;   NLEVELS - The number of data level values to be editable.
;
;   NO_HISTOGRAM - Turn on to keep the data histogram from showing.
;
;   PALETTE_OBJECT - Palette data to display. (optional)
;
;   TITLE - A string representing the title for the compound widget.
;     (This is useful if the compound widget is to appear within a parent
;     tab base.)
;
;   UVALUE - User value.
;
;   VERTICAL - If set, the level lines move along the Y axis instead of X.
;
;   XSIZE, YSIZE - The size in pixels of the density plot window.  The default
;     is 256x128.
;
; SIDE EFFECTS:
;   This compound widget generates events.
;
;   The CW_ITDATALEVEL event structure has the following form:
;        { CW_ITDATALEVEL, ID: id, TOP: top, HANDLER: handler,
;          LEVEL_VALUES: levelValues, MOTION: motion, TEXT: text }
;
;     LEVEL_VALUE: - A vector of NLEVELS data values (representing the
;       data values at each level).
;     MOTION - True if event is triggered while user is currently manipulating
;       the interface.  Useful for parent widgets that do not
;       need to analyze these intermediate events.
;     TEXT - True if event is trigger by user text entry
;-
function CW_itDataLevel, Parent, oUI, $
    COLORS=inColors, $
    COLUMN=column, $
    DATA_OBJECT=dataObject, $
    DATA_RANGE=dataRange, $
    EXTENDABLE_RANGES=extendRanges, $
    INITIAL_VALUES=initialValues, $
    LEVEL_NAMES=inLevelNames, $
    NLEVELS=nLevels, $
    NO_HISTOGRAM=bNoHistogram, $
    PALETTE_OBJECT=paletteObject, $
    TITLE=title, $
    UVALUE=uvalue, $
    VERTICAL=vertical, $
    XSIZE=xSize, $
    YSIZE=ySize, $
    _EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

    if N_ELEMENTS(xSize) eq 0 then $
        xSize = 256
    if N_ELEMENTS(ySize) eq 0 then $
        ySize = 128

    ;; Make sure that there is at least one level
    nLevels = N_ELEMENTS(nLevels) eq 0 ? 1 : nLevels

    ;; The slider max position is one less than the size of the axis
    ;; that the slider moves along.
    ;; The min position is always zero.
    maxPosition = (KEYWORD_SET(vertical) ? ySize : xSize) - 1

    ; Prepare level names.
    levelNames = STRARR(nLevels)
    nInNames = N_ELEMENTS(inLevelNames) < nLevels
    if (nInNames ne 0) then $
        levelNames[0:nInNames-1] = inLevelNames[0:nInNames-1]

    ;; Set up colors
    defaultColors=[[255,0,0],[0,255,0],[0,0,255],[255,255,0],[255,0,255],[0,255,255]]
    colors = ((SIZE(inColors, /N_DIMENSIONS) eq 2) and $
        ((SIZE(inColors, /DIMENSIONS))[0] eq 3)) ? inColors : defaultColors
    nColors = N_ELEMENTS(colors[0,*])

    ;; main base
    wBase = WIDGET_BASE(Parent, /ROW, $
        EVENT_FUNC='CW_itDataLevel_Event', $
        PRO_SET_VALUE='CW_itDataLevel_SetValue', $
        FUNC_GET_VALUE='CW_itDataLevel_GetValue', $
        TITLE=title, UVALUE=uvalue, _EXTRA=_extra)

    ;; Create the density plot (histogram) widget
    wPlotBase = WIDGET_BASE(wBase, /COLUMN, YPAD=0)

    wDraw = WIDGET_DRAW(wPlotBase, GRAPHICS_LEVEL=2, RETAIN=0, $
        /EXPOSE_EVENTS, $
        /BUTTON_EVENTS, $
        /MOTION_EVENTS, $
        IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
        XSIZE=xSize, $
        YSIZE=ySize)

    ;; Object Graphics objects
    oView = OBJ_NEW('IDLgrView')
    oModel = OBJ_NEW('IDLgrModel', DEPTH_TEST_FUNCTION=4)
    oPlot = OBJ_NEW('IDLgrPlot', HISTOGRAM=0, ALPHA=0.3)
    oView->Add, oModel
    oLines = OBJARR(nLevels)
    oGrips1 = OBJARR(nLevels)
    oGrips2 = OBJARR(nLevels)
    oLineModels = OBJARR(nLevels)
    oPalTexture = OBJ_NEW('IDLgrImage')
    oPalPoly = OBJ_NEW('IDLgrPolygon', [[0,0],[1,0],[1,1],[0,1]], $
        COLOR=[255,255,255], $
        TEXTURE_MAP=oPalTexture, ZCOORD_CONV=[-0.5,1], HIDE=1)

    ;; Get widget color
    status = IDLitGetResource("FACE_3D", background, /COLOR)

    ;; Create lock bar
    if nLevels gt 1 then begin
        ;; start with black
        color = BYTARR(3)
        ;; if background is very dark, then use white
        if MAX(background) lt 32 then $
            color = [255,255,255]
        ; Make the box slightly narrower.
        verts = KEYWORD_SET(vertical) ? $
            [[-1,-.75],[1,-.75],[1,.75],[-1,.75]] : $
            [[-.75,-1],[.75,-1],[.75,1],[-.75,1]]
        oLockGrip1 = OBJ_NEW('IDLgrPolygon', verts, COLOR=color)
        oLockGrip2 = OBJ_NEW('IDLgrPolygon', verts, COLOR=color)
        oLockLine = OBJ_NEW('IDLgrPolyline', $
            KEYWORD_SET(vertical) ? [[0,0],[1,0]] : [[0,0],[0,1]], $
            LINESTYLE=[1, 'CCCC'X])
        oLockModel = OBJ_NEW('IDLgrModel', /SELECT_TARGET)
        oLockModel->Add, [oLockGrip1, oLockGrip2, oLockLine]
        oModel->Add, oLockModel
    endif $
    else begin
        oLockGrip1 = OBJ_NEW()
        oLockGrip2 = OBJ_NEW()
        oLockLine = OBJ_NEW()
        oLockModel = OBJ_NEW()
    endelse

    ;; Create unit triangle for grips
    gripVerts1 = KEYWORD_SET(vertical) ? [[0,1], [0,-1], [1,0]] : $
                                         [[-1,0], [1,0], [0,1]]
    gripVerts2 = KEYWORD_SET(vertical) ? [[1,-1], [1,1], [0,0]] : $
                                         [[-1,1], [0,0], [1,1]]

    ;; Create lines and grips
    for i=0, nLevels-1 do begin
        oLines[i] = OBJ_NEW('IDLgrPolyline', $
            KEYWORD_SET(vertical) ? [[0,0],[1,0]] : [[0,0],[0,1]], $
            COLOR=colors[*,i mod nColors])
        oGrips1[i] = OBJ_NEW('IDLgrPolygon', gripVerts1, $
            COLOR=colors[*,i mod nColors])
        oGrips2[i] = OBJ_NEW('IDLgrPolygon', gripVerts2, $
            COLOR=colors[*,i mod nColors])
        oLineModels[i] = OBJ_NEW('IDLgrModel')
        oLineModels[i]->Add, oLines[i]
        oLineModels[i]->Add, oGrips1[i]
        oLineModels[i]->Add, oGrips2[i]
        oModel->Add, oLineModels[i]
    endfor

    ;; Background polygons for grips - match the widget color.
    oGripBackground1 = OBJ_NEW('IDLgrPolygon', [[0,0], [1,0], [1,1], [0,1]], $
        COLOR=background, ZCOORD_CONV=[-0.5,1])
    oGripBackground2 = OBJ_NEW('IDLgrPolygon', [[0,0], [1,0], [1,1], [0,1]], $
        COLOR=background, ZCOORD_CONV=[-0.5,1])
    oModel->Add, [oGripBackground1, oGripBackground2, oPalPoly, oPlot]

    ;; Build Text widgets
    wTextBase = KEYWORD_SET(column) ? $
        WIDGET_BASE(wPlotBase, /COLUMN, YPAD=0, SPACE=0) : $
        WIDGET_BASE(wPlotBase, /ROW, YPAD=0, SPACE=0)
    wText = LONARR(nLevels)
    ;; Order the text widgets vertically from bottom to top if the
    ;; main widget is vertical and the text widgets are in a column base.
    if KEYWORD_SET(vertical) and KEYWORD_SET(column) then begin
        start = nLevels-1
        stop = 0
        inc = -1
    endif else begin
        start = 0
        stop = nLevels-1
        inc = 1
    endelse
    lMax = 0 ;; for label resizing
    wLabel = wText ;; for resizeing
    for i=start, stop, inc do begin
        if (STRLEN(levelNames[i]) gt 0) then begin
            wTextParent = KEYWORD_SET(column) ? $
                WIDGET_BASE(wTextBase, /ROW, SPACE=0) : wTextBase
            wLabel[i] = WIDGET_LABEL(wTextParent, VALUE=levelNames[i])
            ;; If we are vertical, get the max width of the text
            if(keyword_set(vertical))then begin
                geom = widget_info(wLabel[i],/geometry)
                lmax = max([lMax, geom.scr_xsize])
            endif
        endif else $
            wTextParent = wTextBase
        wText[i] = WIDGET_TEXT(wTextParent, XSIZE=8, $
            /EDITABLE, $
            IGNORE_ACCELERATORS=['Ctrl+C','Ctrl+V','Ctrl+X','Del'], $
            /KBRD_FOCUS_EVENTS)
    endfor
    ;; IN vertical mode, resize labels so they are aligned. Polish the
    ;; UI a little.
    if(keyword_set(vertical))then begin
        iValid = widget_info(wLabel, /valid)
        dex = where(iValid, nValid)
        if(nValid gt 0)then begin
            for i=0, nValid-1 do $
              widget_control, wLabel[dex[i]], scr_xsize=lMax
        endif
    endif

    if (N_ELEMENTS(dataRange) eq 2) then begin
        dataMin = dataRange[0]
        dataMax = dataRange[1]
        if (dataMin gt dataMax) then begin
          dtmp = dataMin
          dataMin = dataMax
          dataMax = dtmp
        endif
        bAutoRange = 0b
    endif else begin
        dataMin = 0.0d
        dataMax = 0.0d
        bAutoRange = 1b
    endelse

    ;; Stash our state
    state = { $
        oUI: oUI, $
        nLevels: nLevels, $
        maxPosition: maxPosition, $
        dataObject: OBJ_NEW(), $
        paletteObject : OBJ_NEW(), $
        positions: DBLARR(nLevels), $
        pixelsPerValue: 0d, $
        bAutoRange: bAutoRange, $
        bExtendableRanges: KEYWORD_SET(extendRanges), $
        bHideHistogram: KEYWORD_SET(bNoHistogram), $
        bVertical: KEYWORD_SET(vertical), $
        bRedraw: 0b, $
        deltaXY: LONARR(2), $
        dataMin: dataMin, $
        dataMax: dataMax, $
        currLevel: -1, $
        xSize: xSize, $
        ySize: ySize, $
        wDraw: wDraw, $
        wText: wText, $
        oPlot: oPlot, $
        oLines: oLines, $
        oGrips1: oGrips1, $
        oGrips2: oGrips2, $
        oLineModels: oLineModels, $
        oGripBackground1: oGripBackground1, $
        oGripBackground2: oGripBackground2, $
        oLockGrip1: oLockGrip1, $
        oLockGrip2: oLockGrip2, $
        oLockLine: oLockLine, $
        oLockModel: oLockModel, $
        oPalPoly: oPalPoly, $
        oPalTexture: oPalTexture, $
        oView: oView $
    }

    ;; Set the data.
    state = CW_itDataLevel_SetData(state, dataObject)
    if OBJ_VALID(paletteObject) then state.paletteObject = paletteObject

    ;; Initialize data level positions.
    state = CW_itDataLevel_SetPositions(state, initialValues)

    ;; Initialize visual
    state = CW_itDataLevel_SetPlot(state)

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state, /NO_COPY
    WIDGET_CONTROL, wChild, KILL_NOTIFY='CW_itDataLevel_KillNotify'
    return, wBase

end

