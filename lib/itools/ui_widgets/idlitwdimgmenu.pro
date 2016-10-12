; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdimgmenu.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdImgMenu
;
; PURPOSE:
;   This function creates the control panel that appears in image tool.
;
;-

;-------------------------------------------------------------------------
; IDLitImgMenu_ParsePixelString
;
; Purpose:
;   This internal function parses the given string and returns a
;   corresponding zoom factor.
;
; Return Value:
;   This function returns a 1 on success, or 0 if the string was
;     not valid.
;
; Arguments:
;   ZoomStr:    The string to be parsed.  An example would be: "200%".
;
;   InitialScale: The initial pixel scale.  This is used as the fallback
;     in case the string is invalid.
;
;   NewScale: The new pixel scale.
;
function IDLitwdImgMenu_ParsePixelString, zoomStr, initialScale, newScale

    compile_opt hidden, idl2

    ON_IOERROR, skipzoom
    val = LONG(zoomStr)

    ; Value was successfully retrieved.

    ; Disallow negative or zero values.
    if (val le 0) then begin
        newScale = initialScale
        return, 0
    endif

    ; Value is positive.
    newScale = 100. / DOUBLE(val)
    return, 1

skipzoom:
    ; Value was not successfully retrieved.  Revert to original.
    newScale = initialScale
    return, 0

end

;-------------------------------------------------------------------------
; IDLitwdImgMenu_GetImageTargets
;
; Purpose:
;   This function method returns a vector of references to currently
;   selected objects that either:
;      a) are instances of the IDLitVisImage class
;      b) are ROIs whose parents are instances of the IDLitVisImage class
;
; Return Value:
;   A vector of references to the objects that are determined to be
;   valid image targets.
;
function IDLitwdImgMenu_GetImageTargets, oView, $
    COUNT=count

    compile_opt idl2, hidden

    count = 0

    if (OBJ_VALID(oView)) then begin
        oSel = oView->GetSelectedItems(COUNT=nSel)
    endif else $
        nSel = 0

    if (nSel gt 0) then begin
        isImg = OBJ_ISA(oSel, 'IDLITVISIMAGE')
        ind = WHERE(isImg eq 1, nImg)

        if (nImg gt 0) then begin
            oTargets = (count eq 0) ? oSel[ind] : [oTargets, oSel[ind]]
            count += nImg
        endif

        ; Seek any ROIs whose parent is an image.
        ; Add the parent images to the list.
        isROI = OBJ_ISA(oSel, 'IDLITVISROI')
        ind = WHERE(isROI eq 1, nROI)
        for i=0,nROI-1 do begin
            (oSel[ind[i]])->GetProperty, PARENT=oParent
            if (OBJ_ISA(oParent, 'IDLITVISIMAGE')) then begin
                oTargets = (count eq 0) ? [oParent] : [oTargets, oParent]
                count++
            endif
        endfor
    endif

    ; Check for multiple dataspaces
    for i=0,nSel-1 do begin
      oObj = oSel[i]
      if (OBJ_ISA(oObj, 'IDLitVisROI')) then $
        oObj->GetProperty, PARENT=oObj
      oManip = oObj->GetManipulatorTarget()
      ;; Save normalizer dataspaces
      if (OBJ_ISA(oManip, 'IDLitVisNormalizer')) then $
        oDS = (N_ELEMENTS(oDS) eq 0) ? [oManip] : [oDS, oManip] 
    endfor
    ; Filter out reduntant dataspaces
    nDS = N_ELEMENTS(UNIQ(oDS, SORT(oDS)))
    ; Only work if all items are in the same dataspace
    if (nDS gt 1) then return, OBJ_NEW()
    
    return, ((count gt 0) ? oTargets : OBJ_NEW())
end

;-------------------------------------------------------------------------
; IDLitwdImgMenu_UpdateObserveTargets
;
; Purpose:
;   This internal procedure updates the observation targets for this
;   panel.
;
;   -----------------------------------------------
;    Observed Item          Notification Message
;   -----------------------------------------------
;    image                  IMAGEPROBE and PIXEL_SCALE_STATUS
;    dataspace              RANGE_CHANGE
;    normalized dataspace   NORMALIZATION_CHANGE
;    dataspace root         SCALE2D
;    layer                  PROJECTION_CHANGE and
;                              ASPECT_RATIO_CHANGE
;    view                   VIEW_ZOOM and VIEWPORT_CHANGE
;
; Arguments:
;   state: A structure that represents the current state of this panel.
;
pro IDLitwdImgMenu_UpdateObserveTargets, state

    compile_opt idl2, hidden

    oImage = state.oImage
    oView = state.oView

    oDataSpace = (OBJ_VALID(oImage) ? $
        oImage->GetDataSpace(/UNNORMALIZED) : OBJ_NEW())
    oNormDS = (OBJ_VALID(oDataSpace) ? oDataSpace->GetDataSpace() : OBJ_NEW())
    if (OBJ_VALID(oNormDS)) then begin
        oNormDS->GetProperty, PARENT=oParent
        while (OBJ_ISA(oParent, '_IDLitVisualization')) do begin
            if (OBJ_ISA(oParent, 'IDLitVisDataSpaceRoot')) then $
                break
            oChild = oParent
            oChild->GetProperty, PARENT=oParent
        endwhile
        oDSRoot = oParent
    endif else $
        oDSRoot = OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()

    ;----------------------------------------------------------------------
    ; Prepare new selection IDs, and set flags indicating whether new
    ; selections should be observed.
    ;----------------------------------------------------------------------
    if (OBJ_VALID(oImage)) then begin
        newImgID = oImage->GetFullIdentifier()
        bAddImg = 1b
    endif else begin
        newImgID = ''
        bAddImg = 0b
    endelse

    if (OBJ_VALID(oDataSpace)) then begin
        newDSID = oDataSpace->GetFullIdentifier()
        bAddDS = 1b
    endif else begin
        newDSID = ''
        bAddDS = 0b
    endelse

    if (OBJ_VALID(oNormDS)) then begin
        newNormDSID = oNormDS->GetFullIdentifier()
        bAddNormDS = 1b
    endif else begin
        newNormDSID = ''
        bAddNormDS = 0
    endelse

    if (OBJ_VALID(oDSRoot)) then begin
        newDSRootID = oDSRoot->GetFullIdentifier()
        bAddDSRoot = 1b
    endif else begin
        newDSRootID = ''
        bAddDSRoot = 0
    endelse

    if (OBJ_VALID(oLayer)) then begin
        newLayerID = oLayer->GetFullIdentifier()
        bAddLayer = 1b
    endif else begin
        newLayerID = ''
        bAddLayer = 0b
    endelse

    if (OBJ_VALID(oView)) then begin
        newViewID = oView->GetFullIdentifier()
        bAddView = 1b
    endif else begin
        newViewID = ''
        bAddView = 0b
    endelse

    ;----------------------------------------------------------------------
    ; If new selection targets match old observation targets, turn off
    ; flags to add new ones.  Otherwise, remove self from old observation
    ; targets.
    ;----------------------------------------------------------------------
    if (state.imageID ne '') then begin
        if (state.imageID eq newImgID) then $
            bAdd = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.imageID
    endif
    if (state.dataspaceID ne '') then begin
        if (state.dataspaceID eq newDSID) then $
            bAddDS = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.dataspaceID
    endif
    if (state.normDSID ne '') then begin
        if (state.normDSID eq newNormDSID) then $
            bAddNormDS = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.normDSID
    endif
    if (state.DSRootID ne '') then begin
        if (state.DSRootID eq newDSRootID) then $
            bAddDSRoot = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.DSRootID
    endif
    if (state.layerID ne '') then begin
        if (state.layerID eq newLayerID) then $
            bAddLayer = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.layerID
    endif
    if (state.viewID ne '') then begin
        if (state.viewID eq newViewID) then $
            bAddView = 0b $
        else $
            state.oUI->RemoveOnNotifyObserver, state.idSelf, $
                state.viewID
    endif

    ;----------------------------------------------------------------------
    ; Store the new ids.
    ;----------------------------------------------------------------------
    state.imageID = newImgID
    state.dataspaceID = newDSID
    state.normDSID = newNormDSID
    state.DSRootID = newDSRootID
    state.layerID = newLayerID
    state.viewID = newViewID

    ;----------------------------------------------------------------------
    ; If appropriate, add self as an observer of new targets.
    ;----------------------------------------------------------------------
    if (bAddImg) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newImgID
    if (bAddDS) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newDSID
    if (bAddNormDS) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newNormDSID
    if (bAddDSRoot) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newDSRootID
    if (bAddLayer) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newLayerID
    if (bAddView) then $
        state.oUI->AddOnNotifyObserver, state.idSelf, newViewID
end

;-------------------------------------------------------------------------
; IDLitwdImgMenu_UpdatePixelScale
;
; Purpose:
;   This internal procedure updates the currently reported pixel
;   scale value to reflect the current view/layer/normalization
;   settings.
pro IDLitwdImgMenu_UpdatePixelScale, state

    compile_opt idl2, hidden

    if (OBJ_VALID(state.oImage)) then begin

        if (state.oImage->QueryPixelScaleStatus() ne 1) then begin
            WIDGET_CONTROL, state.wPixelScaleX, SET_VALUE='--- '
            WIDGET_CONTROL, state.wPixelScaleY, SET_VALUE='--- '
            WIDGET_CONTROL, state.wPixelScaleBase, SENSITIVE=0
            return
        endif

        WIDGET_CONTROL, state.wPixelScaleBase, /SENSITIVE

        ; Determine size of one device pixel (in target's data units)
        ; when the view scale factor is 1.0.
        winDataPixel = state.oView->GetPixelDataSize(state.oImage)

        ; Determine size of one image pixel (in data units).
        state.oImage->GetProperty, $
            PIXEL_XSIZE=imgDataXPixel, PIXEL_YSIZE=imgDataYPixel

        ; Update the pixel scale factor to reflect the current
        ; view zoom factor.
        state.oView->GetProperty, CURRENT_ZOOM=zoomFactor
        pixelXScale = winDataPixel[0] / (imgDataXPixel * zoomFactor)
        pixelYScale = winDataPixel[1] / (imgDataYPixel * zoomFactor)

        ; Convert to an integral percentage.
        newXPerc = UINT((100. / DOUBLE(pixelXScale)) + 0.5)
        newXStr = STRTRIM(STRING(newXPerc),2) + "%"
        newYPerc = UINT((100. / DOUBLE(pixelYScale)) + 0.5)
        newYStr = STRTRIM(STRING(newYPerc),2) + "%"

        ; Set the labels.
        WIDGET_CONTROL, state.wPixelScaleX, SET_VALUE=newXStr
        WIDGET_CONTROL, state.wPixelScaleY, SET_VALUE=newYStr
    endif
end

;-------------------------------------------------------------------------
; Handle events for the Image Control Panel widget.
;
pro idlitwdimgmenu_event, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=uval
    if (N_ELEMENTS(uval) eq 0) then $
        return

    child = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=state

    case uval of

        'EDIT_PALETTE': begin
            if (OBJ_VALID(state.oImage)) then begin
                oEditUserdef = state.oTool->GetService('EditUserdefProperty')
                if (OBJ_VALID(oEditUserdef)) then begin
                    void = oEdituserdef->DoAction(state.oTool, $
                        state.oImage, 'VISUALIZATION_PALETTE')
                endif
            endif
        end

        'MULTI_DATALEVEL': begin
            if ((state.nChannel eq 0) || ~OBJ_VALID(state.oImage)) then $
                break
            ;; Update our bytescale values.
            if event.apply_all then begin
                state.byteScaleMin[0:state.nChannel-1] = $
                    event.level_values[0,*]
                state.byteScaleMax[0:state.nChannel-1] = $
                    event.level_values[1,*]
            endif else begin
                state.byteScaleMin[event.data_id] = $
                    event.level_values[0,event.data_id]
                state.byteScaleMax[event.data_id] = $
                    event.level_values[1,event.data_id]
            endelse

            ;; This section enables undo/redo for window leveling.
            ;;
            ;; User entered data via the text - no motion to worry about.
            if event.text then begin
                state.oImage->GetProperty, $
                    BYTESCALE_MIN=byteScaleMinSave, $
                    BYTESCALE_MAX=byteScaleMaxSave
                state.bIgnoreUpdates = 1
                WIDGET_CONTROL, child, SET_UVALUE=state

                doCommit = 0b

                if (~ARRAY_EQUAL(byteScaleMinSave[0:state.nChannel-1], $
                    state.byteScaleMin[0:state.nChannel-1])) then begin
                    ret = state.oTool->doSetProperty(state.oImage->GetFullIdentifier(), $
                        'BYTESCALE_MIN',state.byteScaleMin[0:state.nChannel-1])
                    doCommit = 1b
                endif

                ;; Now we want the see the new values.
                state.bIgnoreUpdates = 0
                WIDGET_CONTROL, child, SET_UVALUE=state

                if (~ARRAY_EQUAL(byteScaleMaxSave[0:state.nChannel-1], $
                    state.byteScaleMax[0:state.nChannel-1])) then begin
                    ret = state.oTool->doSetProperty(state.oImage->GetFullIdentifier(), $
                        'BYTESCALE_MAX',state.byteScaleMax[0:state.nChannel-1])
                    doCommit = 1b
                endif

                if (doCommit) then $
                    state.oTool->CommitActions

                break
            endif

            if event.motion then begin

                ;; This part is tricky because we don't want to record all
                ;; changes made while the GUI is in motion.
                ;; We just want to keep track of the values before and
                ;; after the motion started, while updating everything
                ;; in the meantime.

                ;; Save bytescale values on the first mousedown/movement.
                ;; We'll need these values later.
                if ~state.bInMotion then begin
                    state.oImage->GetProperty, $
                        BYTESCALE_MIN=byteScaleMinSave, $
                        BYTESCALE_MAX=byteScaleMaxSave
                    state.byteScaleMinSave = byteScaleMinSave
                    state.byteScaleMaxSave = byteScaleMaxSave
                    ;; We are in motion now.
                    state.bInMotion = 1
                endif
                ;; Tell our IMAGECHANGED callback to not update the DataLevel
                ;; widget, since we are responding to an update of that widget.
                state.bIgnoreUpdates = 1
                WIDGET_CONTROL, child, SET_UVALUE=state
                ;; Update the image bytescale props without recording the
                ;; change in the undo/redo buffer, since we are in motion.
                state.oImage->SetProperty, $
                    BYTESCALE_MIN=state.byteScaleMin[0:state.nChannel-1], $
                    BYTESCALE_MAX=state.byteScaleMax[0:state.nChannel-1]
                state.bIgnoreUpdates = 0
                WIDGET_CONTROL, child, SET_UVALUE=state
                ;; Main image needs updating
                state.oTool->RefreshCurrentWindow

                break

            endif

            if (event.data_id ne state.currDataLevelPlane) then begin
                ;; Channel change.
                state.currDataLevelPlane = event.data_id
                WIDGET_CONTROL, child, SET_UVALUE=state
                break
            endif

            ;; Button up!
            state.bInMotion = 0

            ;; Now we need to set the image bytescale values back to
            ;; the values they had before this interaction started.
            ;; Ignore the updates, because we don't want to see the
            ;; DataLevel widget snap back to the original values, even
            ;; if only for a moment.
            state.bIgnoreUpdates = 1
            WIDGET_CONTROL, child, SET_UVALUE=state

            minChange = ~ARRAY_EQUAL(state.byteScaleMinSave[0:state.nChannel-1], $
                state.byteScaleMin[0:state.nChannel-1])
            maxChange = ~ARRAY_EQUAL(state.byteScaleMaxSave[0:state.nChannel-1], $
                state.byteScaleMax[0:state.nChannel-1])

            ; Tricky. Set a flag indicating that we don't want to update
            ; the actual image data. We should have already updated the bytscl
            ; min/max in the motion code above. Now we just need to record
            ; the initial/final values for the undo/redo command buffer.
            state.oImage->GetProperty, INITIALIZING=isInit
            if (~isInit) then $
                state.oImage->SetProperty, INITIALIZING=1

            ;; Set old values without recording.
            if (minChange || maxChange) then begin
                state.oImage->SetProperty, $
                    BYTESCALE_MIN=state.byteScaleMinSave, $
                    BYTESCALE_MAX=state.byteScaleMaxSave
            endif

            ;; Set new values and record the action.
            doCommit = 0b
            if (minChange) then begin
                ret = state.oTool->doSetProperty( $
                    state.oImage->GetFullIdentifier(), $
                    'BYTESCALE_MIN',state.byteScaleMin[0:state.nChannel-1])
                doCommit = 1b
            endif

            ;; Now we want the see the new values.
            state.bIgnoreUpdates = 0
            WIDGET_CONTROL, child, SET_UVALUE=state

            if (maxChange) then begin
                ret = state.oTool->doSetProperty( $
                    state.oImage->GetFullIdentifier(), $
                    'BYTESCALE_MAX',state.byteScaleMax[0:state.nChannel-1])
                doCommit = 1b
            endif

            ; Set our initializing flag back.
            if (~isInit) then $
                state.oImage->SetProperty, INITIALIZING=0

            if (doCommit) then begin
                ; Use the undoc'd _TransactCommand instead of CommitActions,
                ; to avoid an unnecessary RefreshCurrentWindow. We will have
                ; already refreshed the window in motion events above.
                state.oTool->_TransactCommand, OBJ_NEW()
            endif
        end

        else: begin
        end
    endcase

    WIDGET_CONTROL, child, SET_UVALUE=state
end


;-------------------------------------------------------------------------
pro idlitwdimgmenu_updateimage, state

    compile_opt idl2, hidden

    ; Update whether full byte range is to be used.
    bValidRange = state.oImage->GetByteScaleDataRange( $
        dataRange)
    bAutoRange = ~bValidRange

    state.oImage->GetProperty, BYTESCALE_MIN=byteScaleMin, $
        BYTESCALE_MAX=byteScaleMax, ODATA=oData

    ; We can only handle 4 channels.
    nChannel = N_ELEMENTS(oData) < 4
    oData = oData[0:nChannel-1]
    state.byteScaleMin[0:nChannel-1] = byteScaleMin
    state.byteScaleMax[0:nChannel-1] = byteScaleMax
    state.nChannel = nChannel

    dlVal = {DATA_OBJECTS:oData, $
        LEVEL_VALUES: $
          TRANSPOSE([[byteScaleMin],[byteScaleMax]]), $
        DATA_RANGE:dataRange, $
        AUTO_COMPUTE_RANGE:bAutoRange}
    WIDGET_CONTROL, state.wDataLevel, SET_VALUE=dlVal

end


;-------------------------------------------------------------------------
; Handle notifications from the tool.
; Update control panel menu state in response to selections.
;
pro idlitwdimgmenu_callback, wPanel, strID, messageIn, userData
    compile_opt idl2, hidden

    if not WIDGET_INFO(wPanel, /VALID) then return

    wChild = WIDGET_INFO(wPanel, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=state
    case STRUPCASE(messageIn) of
        'SELECTIONCHANGED': begin
            oWin = state.oTool->GetCurrentWindow()
            oScene = OBJ_VALID(oWin) ? oWin->GetScene() : OBJ_NEW()
            oView = OBJ_VALID(oScene) ? oScene->GetCurrentView() : OBJ_NEW()
            oSelTargets = IDLitwdImgMenu_GetImageTargets(oView, COUNT=nSel)
            oSelImage = (nSel ? oSelTargets[0] : OBJ_NEW())

            haveImg = OBJ_VALID(oSelImage)

            if (haveImg) then begin
                WIDGET_CONTROL, state.wBase, SENSITIVE=1

                haveImg = oSelImage->_GetImageDimensions(imgDims, $
                    N_PLANES=nPlanes, IMAGE_DATA=imgData)

                if (haveImg) then begin

                    state.oImage = oSelImage
                    state.oView = oView

                    IDLitwdImgMenu_UpdateImage, state

                    ; This panel needs to be an observer of a few
                    ; items so it can appropriately update individual
                    ; controls.  Update the targets of observation.
                    IDLitwdImgMenu_UpdateObserveTargets, state

                    ; Update the currently reported pixel scale.
                    IDLitwdImgMenu_UpdatePixelScale, state

                    ; Set sensitivity of palette editor button.
                    WIDGET_CONTROL, state.wEditPalBtn, $
                        SENSITIVE=(state.nChannel eq 1)

                endif

            endif

            if (~haveImg) then begin
                ; No images selected, then gray out the panel.
                WIDGET_CONTROL, state.wBase, SENSITIVE=0

                ; This will make the datalevel widget go blank.
                dlVal = {DATA_OBJECTS:OBJ_NEW(), LEVEL_VALUES:[0]}
                WIDGET_CONTROL, state.wDataLevel, SET_VALUE=dlVal
                state.oImage = OBJ_NEW()
                state.byteScaleMin[*] = 0.0
                state.byteScaleMax[*] = 1.0
                state.nChannel = 0

                ; Remove self as observer of previous targets.
                IDLitwdImgMenu_UpdateObserveTargets, state

                WIDGET_CONTROL, state.wPixelScaleX, SET_VALUE='--- '
                WIDGET_CONTROL, state.wPixelScaleY, SET_VALUE='--- '
            endif

            ;; Clean these up for new image.
            WIDGET_CONTROL, state.wPixelLocLabel, SET_VALUE="                "
            for i=0,state.nPixelValLabels-1 do $
                WIDGET_CONTROL, state.wPixelValLabels[i], $
                    SET_VALUE="                "
        end

        'IMAGEPROBE': begin
            if (OBJ_VALID(state.oImage)) then begin
                ; The userData contains the current probe location.
                state.oImage->GetExtendedDataStrings, userData, $
                    PROBE_LOCATION=probeLocation, $
                    PIXEL_VALUE=pixelValues

                WIDGET_CONTROL, state.wPixelLocLabel, SET_VALUE=probeLocation

                for i=0,(state.nPixelValLabels < N_ELEMENTS(pixelValues))-1 do $
                    WIDGET_CONTROL, state.wPixelValLabels[i], SET_VALUE=pixelValues[i]
            endif
        end

        ;; Update the DataLevel widget with new image/palette data
        'IMAGECHANGED': begin
            ;; The image menu may disable updates in the DATALEVEL handler
            if (~state.bIgnoreUpdates && OBJ_VALID(state.oImage)) then begin
                IDLitwdImgMenu_UpdateImage, state
            endif
        end

        'PIXEL_SCALE_STATUS': begin
            if (state.imageID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state
        end

        'RANGE_CHANGE': begin
            if (state.dataspaceID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state
        end

        'VIEW_ZOOM': begin
            if (state.viewID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state

        end

        'VIEWPORT_CHANGE': begin
            if (state.viewID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state
        end

        'SCALE2D': begin
            if (state.DSRootID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state
        end

        'NORMALIZATION_CHANGE': begin
            if (state.normDSID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state

        end

        'PROJECTION_CHANGE': begin
            if (state.layerID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state

        end

        'ASPECT_RATIO_CHANGE': begin
            if (state.layerID eq strID) then $
                IDLitwdImgMenu_UpdatePixelScale, state

        end

        else:
    endcase

    WIDGET_CONTROL, wChild, SET_UVALUE=state
end

;-------------------------------------------------------------------------
pro idlitwdimgmenu, wPanel, oUI

    compile_opt idl2, hidden

    WIDGET_CONTROL, wPanel, $
                    BASE_SET_TITLE=IDLitLangCatQuery('UI:wdImgMenu:Title')

    ; Specify event handler
    WIDGET_CONTROL, wPanel, event_pro="idlitwdimgmenu_event"

    ; Register and observe selection events on Visualizations
    strObserverIdentifier = oUI->RegisterWidget(wPanel, "Panel", $
        'idlitwdimgmenu_callback')

    oUI->AddOnNotifyObserver, strObserverIdentifier, 'Visualization'
    oUI->AddOnNotifyObserver, strObserverIdentifier, 'StatusBar'

    wBase = WIDGET_BASE(wPanel, /COLUMN, /TAB_MODE)

    ; --ROI Manipulator toolbar---------------------------------------
    wRow = WIDGET_BASE(wBase,/ROW, YPAD=0)
    wLabel = WIDGET_LABEL(wRow, VALUE=IDLitLangCatQuery('UI:wdImgMenu:ROIs'))
    wROIToolbar = CW_ITTOOLBAR(wROW, oUI, 'Manipulators/ROI', $
        /EXCLUSIVE, $
        Y_PAD=0)

    ; --Labels--------------------------------------------------------
    ; Pixel Location.
    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdImgMenu:PixLoc'), $
                          /ALIGN_LEFT)
    wTmp = WIDGET_BASE(wBase, XPAD=10, YPAD=0, SPACE=0, /COLUMN)
    ;; Note fake value for sizing
    wPixelLocLabel = WIDGET_LABEL(wTmp, VALUE="[000,000](000)", $
        /ALIGN_LEFT)

    ;; Fix sizing or the tab base will/can shift during update
    geom = WIDGET_INFO(wPixelLocLabel, /GEOMETRY)
    xsize = geom.scr_xsize > 120
    WIDGET_CONTROL, wPixelLocLabel, SCR_XSIZE=xsize, $
        SCR_YSIZE=geom.scr_ysize, SET_VALUE=""

    ; Pixel Value.
    wLabel = WIDGET_LABEL(wBase, $
                          VALUE=IDLitLangCatQuery('UI:wdImgMenu:PixVal'), $
                          /ALIGN_LEFT)
    nPixelValLabels = 4
    wPixelValLabels = LONARR(nPixelValLabels)
    wTmp = WIDGET_BASE(wBase, XPAD=10, YPAD=0, SPACE=0, /COLUMN)
    for i=0,nPixelValLabels-1 do $
        wPixelValLabels[i] = WIDGET_LABEL(wTmp, VALUE=" ", $
            SCR_XSIZE=xsize, /ALIGN_LEFT)

    ; Pixel Scale.
    wPixelScaleBase = WIDGET_BASE(wBase, XPAD=0, YPAD=0, /COLUMN)
    wLabel = WIDGET_LABEL(wPixelScaleBase, $
                          VALUE=IDLitLangCatQuery('UI:wdImgMenu:PixScale'), $
                          /ALIGN_LEFT)
    wRow = WIDGET_BASE(wPixelScaleBase, XPAD=10, YPAD=0, SPACE=0, /ROW)
    wXRow = WIDGET_BASE(wRow, XPAD=0, YPAD=0, SPACE=0, /ROW)
    wLabel = WIDGET_LABEL(wXRow, $
                          VALUE=IDLitLangCatQuery('UI:wdImgMenu:X'), $
                          /ALIGN_LEFT, $
        /DYNAMIC_RESIZE)
    wPixelScaleX = WIDGET_LABEL(wXRow, VALUE='--- ', /ALIGN_LEFT)
    wYRow = WIDGET_BASE(wRow, XPAD=5, YPAD=0, SPACE=0, /ROW)
    wLabel = WIDGET_LABEL(wYRow, $
                          VALUE=IDLitLangCatQuery('UI:wdImgMenu:Y'), $
                          /ALIGN_LEFT)
    wPixelScaleY = WIDGET_LABEL(wYRow, VALUE='--- ', /ALIGN_LEFT, $
        /DYNAMIC_RESIZE)

    ; Edit Palette Button.
    wRow = WIDGET_BASE(wBase, /ALIGN_LEFT, /ROW, XPAD=0, YPAD=0)
    wEditPalBtn = WIDGET_BUTTON(wRow, $
                                VALUE=IDLitLangCatQuery('UI:wdImgMenu:EditPal'), $
        UVALUE='EDIT_PALETTE', /ALIGN_CENTER)

    ; --Data level (bytescale) compound widget------------------------
    wDLBase = WIDGET_BASE(wBase, /COLUMN)
    wDataLevel = CW_ITMULTIDATALEVEL(wDLBase, oUI, $
        /COLUMN, $
        DATA_LABEL=IDLitLangCatQuery('UI:wdImgMenu:Channel'), $
        LEVEL_NAMES=[IDLitLangCatQuery('UI:wdImgMenu:Min'), $
                     IDLitLangCatQuery('UI:wdImgMenu:Max')], $
        NLEVELS=2, $
        /VERTICAL, $
        XSIZE=78, $
        YSIZE=128, $
        UVALUE='MULTI_DATALEVEL')

    oTool = oUI->GetTool()

    ; Store state.
    state = {oTool: oTool, $
        oUI: oUI, $
        idSelf: strObserverIdentifier, $
        wBase: wBase, $
        wDataLevel: wDataLevel, $
        wPixelLocLabel: wPixelLocLabel, $
        wPixelValLabels: wPixelValLabels, $
        nPixelValLabels: nPixelValLabels, $
        wPixelScaleBase: wPixelScaleBase, $
        wPixelScaleX: wPixelScaleX, $
        wPixelScaleY: wPixelScaleY, $
        wEditPalBtn: wEditPalBtn, $
        oImage: OBJ_NEW(), $
        imageID: '', $
        dataspaceID: '', $
        normDSID: '', $
        DSRootID: '', $
        layerID: '', $
        oView: OBJ_NEW(), $
        viewID: '', $
        nChannel: 0, $
        bInMotion: 0b, $
        bIgnoreUpdates: 0b, $
        currDataLevelPlane: 0, $
        byteScaleMinSave: DBLARR(4), $
        byteScaleMaxSave: DBLARR(4), $
        byteScaleMin: DBLARR(4), $
        byteScaleMax: DBLARR(4) $
    }

    wChild = WIDGET_INFO(wPanel, /CHILD)
    if (WIDGET_INFO(wChild,/VALID_ID)) then $
        WIDGET_CONTROL, wChild, SET_UVALUE=state, /NO_COPY

    ; Emulate a SELECTIONCHANGED event to force proper setup.
    idlitwdimgmenu_callback, wPanel, 'Visualization', 'SELECTIONCHANGED', $
        OBJ_NEW()
end
