; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itmultidatalevel.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;;-------------------------------------------------------------------------
;; This widget manages a single CW_ITDATALEVEL widget with multiple
;; datasets.  The parent widget supplies a list of data objects and a set
;; of data level values for each data object.  The user can manipulate the
;; data levels for each dataset.  The user selects a dataset from a widget
;; listing of the datasets and manipulates the levels with the
;; CW_ITDATALEVEL widget.

;;-------------------------------------------------------------------------
;; CW_itMultiDataLevel_KillNotify
;;
;; Purpose: Clean up dynamic storage

pro CW_itMultiDataLevel_KillNotify, wChild

    compile_opt idl2, hidden

    WIDGET_CONTROL, wChild, GET_UVALUE=state, /NO_COPY
    PTR_FREE, state.pDataObjects
    PTR_FREE, state.pDataNames
    PTR_FREE, state.pLevelNames
    PTR_FREE, state.pLevelData
    PTR_FREE, state.pPaletteObjects
end

;;-------------------------------------------------------------------------
;; CW_itMultiDataLevel_PrepEvent
;;
;; Purpose: Convenience routine to prepare a CW_ITMULTIDATALEVEL event.
;;
;; Parameters:
;;    state - CW_ITMULTIDATALEVEL widget state structure
;;    event - Incoming event structure for event that requires
;;      a corresponding CW_ITMULTIDATALEVEL event to be sent.
;;
;; Outputs:
;;    This function returns a CW_ITMULTIDATALEVEL event structure.
;;    Note that this event structure is unnamed so that it can
;;    accommodate a variable number of levels being reported.

function CW_itMultiDataLevel_PrepEvent, state, event

    compile_opt idl2, hidden

    ;; Propagate level values to all data sets if requested
    bApplyAll = WIDGET_INFO(state.wApplyAll, /BUTTON_SET)
    if bApplyAll then $
        for i=0, N_ELEMENTS(*state.pDataObjects)-1 do $
            (*state.pLevelData)[*, i] = event.level_values $
    else $
        (*state.pLevelData)[*, state.currentDataSet] = event.level_values

    state.minMax = event.min_max
    myEvent = { $
                ID: event.handler, TOP: event.top, HANDLER: 0L, $
                DATA_ID: state.currentDataSet, $
                APPLY_ALL: bApplyAll, $
                LEVEL_VALUES: *state.pLevelData, $
                MIN_MAX: event.min_max, $
                MOTION: event.motion, $
                TEXT: event.text }

    return, myEvent
end

;;-------------------------------------------------------------------------
;; CW_itMultiDataLevel_SetValue
;;
;; Purpose: Sets the value of this compound widget.
;;
;; Parameters:
;;     wid:  Widget id of this compound widget.
;;     value: A structure of the form:
;;        {DATA_OBJECTS: dataObjects, $
;;         LEVEL_VALUES: DBLARR(nLevels, N_ELEMENTS(dataObjects)), $
;;         PALETTE_OBJECTS: paletteObjects}
;;
;;       Optionally, the structure may also have the following
;;       fields:
;;         DATA_RANGE: [dmin, dMax]
;;         AUTO_COMPUTE_RANGE: autoComputeFlag
;;         PALETTE_OBJECTS: vector of palette objects.
;;
;;
pro CW_itMultiDataLevel_SetValue, wid, value

    compile_opt idl2, hidden

@idlit_on_error2

    tags = TAG_NAMES(value)

    child = WIDGET_INFO(wid, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    if (WHERE(tags eq 'DATA_OBJECTS') eq -1) then begin
        oTool = state.oUI->GetTool()
        if (OBJ_VALID(oTool)) then $
          oTool->SignalError, $
          IDLitLangCatQuery('UI:cwMultDataLevel:BadSetVal')
        return
    endif

    bAutoRangeSet = 0b
    bDoAutoRange = 0b
    if (WHERE(tags eq 'AUTO_COMPUTE_RANGE') ne -1) then begin
       bDoAutoRange = 1b
       bAutoRangeSet = (value.auto_compute_range[0] ne 0) ? 1b : 0b
       if (bAutoRangeSet) then $
           dataRange = [0.0,1.0]
    endif

    bDoDataRange = 0b
    if (WHERE(tags eq 'DATA_RANGE') ne -1) then begin
        bDoDataRange = 1b
        dataRange = value.data_Range[0:1]
    endif

    nDataSets = N_ELEMENTS(value.data_objects)

    ;; Grab and keep the data
    *state.pDataObjects = value.data_objects

    hasLevelData = WHERE(tags eq 'LEVEL_VALUES') ne -1
    if (hasLevelData) then begin
        *state.pLevelData = value.level_values
    endif else begin
        for i=0, nDataSets-1 do begin
            ;; This trick lets the DataLevel widget do the work
            ;; of setting initial values for us.
            WIDGET_CONTROL, state.wDataLevel, SET_VALUE={DATA_OBJECT:value.data_objects[i]}
            WIDGET_CONTROL, state.wDataLevel, GET_VALUE=tmpvalue
            if (i eq 0) then begin
                nLevels = N_Elements(tmpvalue.level_Values)
                *state.pLevelData = DBLARR(nLevels, nDataSets)
            endif
            (*state.pLevelData)[*, i] = tmpvalue.level_Values
        endfor
    endelse

    if WHERE(tags eq 'PALETTE_OBJECTS') ne -1 then $
        *state.pPaletteObjects = value.palette_objects $
    else $
        *state.pPaletteObjects = OBJARR(nDataSets)

    ;; This is important, especially if the previous user of the widget
    ;; had more data sets.
    if (state.currentDataSet ge nDataSets) then state.currentDataSet = 0


    ;; Update the DataLevel widget with the data.
    obj = (*state.pDataObjects)[state.currentDataSet]
    val = (*state.pLevelData)[*, state.currentDataSet]
    pal = (*state.pPaletteObjects)[state.currentDataSet]
    if (bDoAutoRange or bDoDataRange) then begin
        setValue = {DATA_OBJECT:obj, $
            LEVEL_VALUES:val, $
            AUTO_COMPUTE_RANGE:bAutoRangeSet, $
            DATA_RANGE:dataRange, $
            PALETTE_OBJECT:pal}
    endif else begin
        setValue = {DATA_OBJECT:obj, $
            LEVEL_VALUES:val, $
            PALETTE_OBJECT:pal}
    endelse
    WIDGET_CONTROL, state.wDataLevel, SET_VALUE=setValue
    WIDGET_CONTROL, state.wDataLevel, GET_VALUE=getValue
    m = N_ELEMENTS((*state.pLevelData)[*, state.currentDataSet])
    n = N_ELEMENTS(getValue.level_Values)
    (*state.pLevelData)[0, state.currentDataSet] = $
        getValue.level_Values[0:(m < n)-1]

    ;; Get all the data names that we can.
    ;; and update the drop list widget.
    if nDataSets gt 0 then begin
        dataNames = STRARR(nDataSets)
        for i=0, nDataSets-1 do begin
            if (Obj_Valid(value.data_objects[i])) then begin
                value.data_objects[i]->GetProperty, NAME=dataName
                dataNames[i] = dataName
            endif
        endfor
        WIDGET_CONTROL, state.wDropList, SET_VALUE=dataNames, $
            SET_DROPLIST_SELECT=state.currentDataSet
    endif else $
        WIDGET_CONTROL, state.wDropList, SET_VALUE=''

    ;; Let the user choose when there is more than 1 choice.
    WIDGET_CONTROL, state.wDropList, SENSITIVE=nDataSets gt 1
    WIDGET_CONTROL, state.wApplyAll, SENSITIVE=nDataSets gt 1

    WIDGET_CONTROL, child, SET_UVALUE=state
end

;;-------------------------------------------------------------------------
;; CW_itMultiDataLevel_GetValue
;;
;; Purpose: Gets the value of this compound widget.
;;
;; Parameters:
;;     wid:  Widget id of this compound widget.
;;
;; Outputs:
;;     A structure of the form:
;;        {DATA_OBJECTS: dataObjects, $
;;         LEVEL_VALUES: DBLARR(nLevels, N_ELEMENTS(dataObjects)), $
;;         PALETTE_OBJECTS: paletteObjects}
;;
;;
function CW_itMultiDataLevel_GetValue, wid
    compile_opt idl2, hidden

    child = WIDGET_INFO(wid, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    myValue = {DATA_OBJECTS: *state.pDataObjects, $
               LEVEL_VALUES: *state.pLevelData, $
               PALETTE_OBJECTS: *state.pPaletteObjects }

    return, myValue
end

;;-------------------------------------------------------------------------
;; CW_itMultiDataLevel_Event
;;
;; Purpose: Main event handler
;;
;; Parameters:
;;    event
function CW_itMultiDataLevel_Event, event

    compile_opt idl2, hidden

@idlit_on_error2
@idlit_catch

    retEvent = 0

    ON_IOERROR, NULL

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    ;; Handle events from our embedded DataLevel widget.
    if (event.id eq state.wDataLevel) then begin
        if (OBJ_VALID((*state.pDataObjects)[0])) then $
            retEvent = CW_itMultiDataLevel_PrepEvent(state, event)
    endif $

    ;; Other widget events
    else case TAG_NAMES(event, /STRUCTURE_NAME) of
        'WIDGET_DROPLIST': begin
            ;; New dataset !
            state.currentDataSet = event.index

            ;; Update the DataLevel widget with the new data the user
            ;; just selected.
            value = {DATA_OBJECT:(*state.pDataObjects)[event.index], $
                     LEVEL_VALUES:(*state.pLevelData)[*, event.index], $
                     PALETTE_OBJECT:(*state.pPaletteObjects)[event.index]}
            WIDGET_CONTROL, state.wDataLevel, SET_VALUE=value
            WIDGET_CONTROL, state.wDataLevel, GET_VALUE=getValue
            m = N_ELEMENTS((*state.pLevelData)[*, event.index])
            n = N_ELEMENTS(getValue.level_Values)
            (*state.pLevelData)[0, event.index] = $
                getValue.level_Values[0:(m < n)-1]

            ;; We need to send an event when the user selects a new dataset
            ;; so that the program watching the events get the data for the
            ;; new dataset.
            retEvent = { $
                ID: event.handler, TOP: event.top, HANDLER: 0L, $
                DATA_ID: state.currentDataSet, $
                APPLY_ALL: WIDGET_INFO(state.wApplyAll, /BUTTON_SET), $
                LEVEL_VALUES: *state.pLevelData, $
                MIN_MAX: state.minMax, $
                MOTION: 0, TEXT:0}
        end
        else:
    endcase

    WIDGET_CONTROL, child, SET_UVALUE=state

    return, retEvent
end

;-------------------------------------------------------------------------
;+
; NAME:
;   cw_itMultiDataLevel
;
; PURPOSE:
;   This function implements a compound widget that allows the
;   user to select data levels against a density plot background
;   for each of the multiple data objects provided.
;
; CALLING SEQUENCE:
;   Result = CW_ITMULTIDATALEVEL(Parent, ToolUI)
;
; INPUTS:
;   Parent: The widget ID of the parent base.
;
;   oUI: The UI Object for the tool
;
; KEYWORD PARAMETERS:
;   COLORS - A 3xn array of RGB colors.  This specifies the color used to
;     draw each of the NLEVELS data level lines in the widget.  If there
;     are fewer colors than levels, the colors are reused.  By default,
;     the colors Red, Green, Blue, Yellow, Magenta, and Cyan are used.
;
;   COLUMN - Set this keyword to a nonzero value to indicate that
;     the text fields (representing the editable data level values) are
;     to be organized in a column.  By default, they are organized in
;     a row.
;
;   DATA_LABEL - A string representing the label to be used next to
;     the droplist that lists the data objects.  By default, no label
;     is used.
;
;   DATA_OBJECTS - An array of IDLitData objects representing the data
;     objects for which data level values are to be editable.
;
;   DATA_RANGE - A vector representing the range for to be used for
;     each of the data objects.  If this keyword is not provided, the data
;     range is automatically computed for each data objects.
;
;   LEVEL_VALUES - An array of [NLEVELS, N_ELEMENTS(DATA_OBJECTS)]
;     data values representing the initial level values per data
;     object.  By default, the initial values are evenly distributed
;     within the range of values per given data object.
;
;   LEVEL_NAMES - A vector of strings representing the names to be
;     assicated with each level.  The default is the empty string
;     for each level.
;
;   NLEVELS - The number of data level values to be editable per data object.
;
;   PALETTE_OBJECTS  An array of IDLitData objects containing palette data.
;     If provided, there should be a palette object for each data object.
;
;   UVALUE - User value.
;
;   XSIZE, YSIZE - The size in pixels of the density plot window.  The default
;     is 256x128.
;
; SIDE EFFECTS:
;   This compound widget generates events.
;
;   The CW_ITMULTIDATALEVEL event structure has the following form:
;        { CW_ITMULTIDATALEVEL, ID: id, TOP: top, HANDLER: handler,
;         DATA_ID: dataID, APPLY_ALL: applyAll, LEVEL_VALUES: levelValues, $
;         MOTION: motion }
;
;     DATA_ID: - the index of the data object for which the data level
;       values have changed.  The index corresponds to the array of data
;       objects passed in the DATA_OBJECTS parameter for this widget.
;       If only one data object was passed in, this field will
;       always be zero.  It is also the index of the data object
;       currently selected in the drop down menu.
;     APPLY_ALL: - True if the user has the "Apply All" checkbox checked.
;       In this situation, all of the values in LEVEL_VALUES possibly have
;       changed.
;     LEVEL_VALUES: - An array of [NLEVELS, N_ELEMENTS(DATA_OBJECTS)] data values
;       (representing the data values at each level for each data object).
;       If APPLY_ALL is false, then the level data at [*, DATA_ID] are the values
;       that have changed.
;     MOTION - True if event is triggered while user is currently manipulating
;       the interface.  Useful for parent widgets that do not
;       need to analyze these intermediate events.
;     TEXT - True if event is triggered by user entering data in the text
;       widgets.
;-
function CW_itMultiDataLevel, Parent, oUI, $
    COLORS=colors, $
    COLUMN=column, $
    DATA_LABEL=dataLabel, $
    DATA_OBJECTS=dataObjects, $
    DATA_RANGE=dataRange, $
    EXTENDABLE_RANGES=extendRanges, $
    LEVEL_VALUES=levelValues, $
    LEVEL_NAMES=levelNames, $
    NLEVELS=nLevels, $
    PALETTE_OBJECTS=paletteObjects, $
    UVALUE=uvalue, $
    VERTICAL=vertical, $
    XSIZE=xSize, $
    YSIZE=ySize

    ;; Pragmas
    compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

    if N_ELEMENTS(xSize) eq 0 then xSize = 256
    if N_ELEMENTS(ySize) eq 0 then ySize = 128

    ;; Make sure that there is at least one level
    nLevels = N_ELEMENTS(nLevels) eq 0 ? 1 : nLevels

    if (N_ELEMENTS(dataObjects) gt 0) then begin
        setValue = {DATA_OBJECTS: dataObjects}
        if (N_ELEMENTS(levelValues) gt 0) then $
            setValue = Create_Struct(setValue, 'LEVEL_VALUES', levelValues)
        if (N_ELEMENTS(dataRange) gt 0) then $
            setValue = Create_Struct(setValue, 'DATA_RANGE', dataRange)
        if (N_ELEMENTS(paletteObjects) gt 0) then $
            setValue = Create_Struct(setValue, 'PALETTE_OBJECTS', paletteObjects)
    endif

    ;; main base
    wBase = WIDGET_BASE(Parent, /COLUMN, /FRAME, SPACE=0, $
        EVENT_FUNC='CW_itMultiDataLevel_Event', UVALUE=uvalue, $
        PRO_SET_VALUE='CW_itMultiDataLevel_SetValue', $
        FUNC_GET_VALUE='CW_itMultiDataLevel_GetValue')

    ;; Prepare selection drop list
    wRow = WIDGET_BASE(wBase, /ROW, YPAD=0)
    if (N_ELEMENTS(dataLabel) ne 0) then $
        wLabel = WIDGET_LABEL(wRow, VALUE=dataLabel)
    wDropList = WIDGET_DROPLIST(wRow, VALUE='?????', /FLAT, /DYNAMIC_RESIZE, SENSITIVE=0)

    ;; Apply all button
    wApplyBase = WIDGET_BASE(wBase, /NONEXCLUSIVE, YPAD=0, SPACE=0)
    wApplyAll = WIDGET_BUTTON(wApplyBase, $
                              VALUE=IDLitLangCatQuery('UI:cwMultDataLevel:ApplyAll'), $
                              SENSITIVE = 0)

    ;; Now the data level widget.
    wDataLevel = CW_ITDATALEVEL(wBase, oUI, $
                                COLORS=colors, $
                                COLUMN=column, $
                                DATA_RANGE=dataRange, $
                                EXTENDABLE_RANGES=KEYWORD_SET(extendRanges), $
                                LEVEL_NAMES=levelNames, $
                                NLEVELS=nLevels, $
                                VERTICAL=vertical, $
                                XSIZE=xsize, $
                                YSIZE=ysize, YPAD=0)


    ;; Build our state structure
    state = { $
              oUI: oUI, $
              pDataObjects: PTR_NEW(), $
              pDataNames: PTR_NEW(), $
              pLevelNames: PTR_NEW(), $
              pLevelData: PTR_NEW(), $
              pPaletteObjects: PTR_NEW(), $
              currentDataset: 0, $
              wDropList: wDropList, $
              wDataLevel: wDataLevel, $
              wApplyAll: wApplyAll, $
              minMax: [0.0d, 0] $
            }

    ;; Create dynamic state data
    if (N_ELEMENTS(levelNames) ne 0) then $
        state.pLevelNames = PTR_NEW(levelNames) $
    else $
        state.pLevelNames = PTR_NEW(/ALLOC)

        state.pDataObjects = PTR_NEW(/ALLOC)
        state.pDataNames = PTR_NEW(/ALLOC)
        state.pLevelData = PTR_NEW(/ALLOC)
        state.pPaletteObjects = PTR_NEW(/ALLOC)

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, SET_UVALUE=state, /NO_COPY
    WIDGET_CONTROL, wChild, KILL_NOTIFY='CW_itMultiDataLevel_KillNotify'

    ; Set initial data.
    if (N_Tags(setValue) gt 0) then begin
        CW_itMultiDataLevel_SetValue, wBase, setValue
    endif

    return, wBase
end
