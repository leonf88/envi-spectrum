; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itoperationpreview.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   cw_itoperationpreview
;
; PURPOSE:
;   This function implements the compound widget for a Preview window.
;
; CALLING SEQUENCE:
;   Result = cw_itoperationpreview(Parent, Tool)
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
;   Tool: Set this argument to the object reference for the IDL Tool.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro cw_itoperationpreview_callback, wBase, strID, messageIn, component

    compile_opt idl2, hidden

    if ~WIDGET_INFO(wBase, /VALID) then $
        return

    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), GET_UVALUE=pState
    cw_itoperationpreview_UPDATEDRAW, pState

end


;-------------------------------------------------------------------------
pro cw_itoperationpreview_event, event

    compile_opt idl2, hidden

@idlit_catch
    if (iErr ne 0) then begin
      CATCH, /CANCEL
      if (PTR_VALID(pState)) then begin
        if OBJ_VALID((*pState).oTool) then $
          (*pState).oTool->ErrorMessage, !ERROR_STATE.msg, $
          TITLE=IDLitLangCatQuery('UI:cwOpPrev:ErrTitle'), SEVERITY=2
      endif
      return
    endif

    wChild = WIDGET_INFO(event.handler, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=pState

    case TAG_NAMES(event, /STRUCTURE_NAME) of

    'WIDGET_DRAW': begin
        case event.type of
            0: begin ; button press
                if (event.press ne 1) then break ; left button only
                (*pState).pressed = 1b
                (*pState).mousedownposition = [event.x, event.y]
                (*pState).mousedowncenter = (*pState).center
                cw_itoperationpreview_UPDATEDRAW, pState, /NO_EXECUTE
               end
            1: begin ; button release
                if (event.release ne 1) then break ; left button only
                (*pState).pressed = 0b
                cw_itoperationpreview_UPDATEDRAW, pState
               end
            2: begin ; motion
                ; mouse button must be down
                if (~(*pState).pressed) then break
                delta = [event.x, event.y] - (*pState).mousedownposition
                zoom = ((*pState).zoomfactor ge 1) ? $
                    (*pState).zoomfactor : 1./(2-(*pState).zoomfactor)
                (*pState).center = (*pState).mousedowncenter - delta*zoom
                cw_itoperationpreview_UPDATEDRAW, pState, $
                    /MOTION, /NO_EXECUTE
               end
            else: ; do nothing
        endcase
       end

    'WIDGET_TRACKING': begin
        if event.enter then begin
            ; The CURSOR_MASK has the entire hand, including the outline.
            ; The CURSOR_IMAGE is just the black outline.
            DEVICE, CURSOR_MASK=[-32767, -10225, -993, -929, $
                -1793, -1793, -2305, -1, -129, -385, -897, $
                -961, -1985, -4065, -8161, 0], $
                CURSOR_IMAGE=[-32767, 22542, 25618, 25682, $
                    18610, 18578, 5776, 6528, 4416, 576, $
                    1088, 1056, 2080, 4112, 8208, 0]
        endif else $
            DEVICE, /CURSOR_ORIGINAL
        end

    'WIDGET_BUTTON': begin
        zoom = (*pState).zoomfactor
        case event.id of
            (*pState).wZoomIn:  (*pState).zoomfactor--
            (*pState).wZoomOut: (*pState).zoomfactor++
            else:
        endcase
        (*pState).zoomfactor = $
            -2 > (*pState).zoomfactor < 4
        if (zoom eq (*pState).zoomfactor) then $
            break
        zoom = ((*pState).zoomfactor ge 1) ? $
            (*pState).zoomfactor : 1./(2-(*pState).zoomfactor)
        WIDGET_CONTROL, (*pState).wZoomLabel, $
            SET_VALUE=STRTRIM(FIX(100./zoom), 2)+'%'
        WIDGET_CONTROL, (*pState).wZoomIn, $
            SENSITIVE=((*pState).zoomfactor gt -2)
        WIDGET_CONTROL, (*pState).wZoomOut, $
            SENSITIVE=((*pState).zoomfactor lt 4)
        cw_itoperationpreview_UPDATEDRAW, pState
       end

    else: ;help, event, /struc
    endcase

end


;-------------------------------------------------------------------------
; MOTION: If set then the position has been moved and the new
;   position should be cached. Used for initialization and mouse motion.
;
; NO_EXECUTE: If set then copy the original thumbnail into the result
;   and don't execute the operation. Needed for mouse down and motion.
;
; If neither of the above keywords are specified then the position
;   is not updated (to avoid drift) and the preview is updated with
;   the result of the operation on the thumbnail.
;
pro cw_itoperationpreview_updatedraw, pState, $
    MOTION=motion, $
    NO_EXECUTE=noExecute

    compile_opt idl2, hidden

    xPreview = (*pState).xsize
    yPreview = (*pState).ysize
    zoom = ((*pState).zoomfactor ge 1) ? $
        DOUBLE((*pState).zoomfactor) : 1./(2-(*pState).zoomfactor)
    xPreview *= zoom
    yPreview *= zoom
    center = (*pState).center
    dims = (*pState).dims

    minDim = 0   ; in case it's not defined by the operation
    (*pState).oOperation->GetProperty, MINIMUM_DIMENSION=minDim

    ; If minDim is negative, assume we need entire array.
    xNeeded = (minDim[0] ge 0) ? xPreview + minDim[0] : dims[0]
    n2 = N_ELEMENTS(minDim) ge 2
    yNeeded = (minDim[n2] ge 0) ? yPreview + minDim[n2] : dims[1]

    if (center[0] lt dims[0]/2) then begin  ; in left half
        x1oper = (center[0] - xNeeded/2d) > 0
        x2oper = (x1oper + xNeeded - 1) < (dims[0]-1)
        x1preview = (center[0] - xPreview/2d) > 0
        x2preview = (x1preview + xPreview - 1) < (dims[0]-1)
    endif else begin  ; in right half
        x2oper = (center[0] + xNeeded/2d) < (dims[0]-1)
        x1oper = (x2oper - xNeeded + 1) > 0
        x2preview = (center[0] + xPreview/2d) < (dims[0]-1)
        x1preview = (x2preview - xPreview + 1) > 0
    endelse

    if (center[1] lt dims[1]/2) then begin  ; in bottom half
        y1oper = (center[1] - yNeeded/2d) > 0
        y2oper = (y1oper + yNeeded - 1) < (dims[1]-1)
        y1preview = (center[1] - yPreview/2d) > 0
        y2preview = (y1preview + yPreview - 1) < (dims[1]-1)
    endif else begin  ; in top half
        y2oper = (center[1] + yNeeded/2d) < (dims[1]-1)
        y1oper = (y2oper - yNeeded + 1) > 0
        y2preview = (center[1] + yPreview/2d) < (dims[1]-1)
        y1preview = (y2preview - yPreview + 1) > 0
    endelse

    ; These are indices, so floor them. This is crucial to avoid
    ; jiggle between the result (with padding) and the original image.
    x1preview = FLOOR(x1preview+0.5)
    x2preview = FLOOR(x2preview+0.5)
    y1preview = FLOOR(y1preview+0.5)
    y2preview = FLOOR(y2preview+0.5)
    x1oper = FLOOR(x1oper+0.5)
    x2oper = FLOOR(x2oper+0.5)
    y1oper = FLOOR(y1oper+0.5)
    y2oper = FLOOR(y2oper+0.5)


    windraw = BYTARR((*pState).xsize, (*pState).ysize, (*pState).nchannel)

    dim1 = x2preview - x1preview + 1
    dim2 = y2preview - y1preview + 1

    dimZoom1 = dim1/zoom < (*pState).xsize
    dimZoom2 = dim2/zoom < (*pState).ysize

    ; First resize and display the original image preview.
    for i=0,(*pState).nChannel-1 do begin
        subset = (*(*pState).pData[i])[x1preview:x2preview, y1preview:y2preview]
        subset = CONGRID(TEMPORARY(subset), dimZoom1, dimZoom2)
        subset = BYTSCL(subset, $
            MIN=(*pState).bytescaleMin[i], MAX=(*pState).bytescaleMax[i])
        windraw[((*pState).xsize - dimZoom1)/2, $
            ((*pState).ysize - dimZoom2)/2, i] = TEMPORARY(subset)
    endfor

    wold = !D.WINDOW
    DEVICE, DECOMPOSED=0

    WIDGET_CONTROL, (*pState).wDraw1, GET_VALUE=win
    WSET, win

    TV, windraw, TRUE=((*pState).nChannel gt 1) ? 3 : 0

    ; Draw the original image into the result view, just in case the
    ; operation fails, and to avoid a delay in showing the new location.
    WIDGET_CONTROL, (*pState).wDraw2, GET_VALUE=win
    WSET, win
    TV, windraw, TRUE=((*pState).nChannel gt 1) ? 3 : 0

    ; Only cache the new values if our widget caused the change.
    ; Otherwise, roundoff errors can cause the image to drift
    ; as the user changes property values for the operation.
    if KEYWORD_SET(motion) then begin
        (*pState).start = [x1preview, y1preview]
        ; Recalculate the center in case we hit an edge.
        (*pState).center[0] = (x1preview + x2preview + 1)/2d
        (*pState).center[1] = (y1preview + y2preview + 1)/2d
    endif

    if (KEYWORD_SET(noExecute)) then $
        goto, done

    ; In case the operation is slow.
    WIDGET_CONTROL, /HOURGLASS

    winresult = BYTARR((*pState).xsize, (*pState).ysize, (*pState).nchannel)

    ; Now execute, resize and display the result image.
    for i=0,(*pState).nChannel-1 do begin
        subset = (*(*pState).pData[i])[x1oper:x2oper, y1oper:y2oper]

        if (~(*pState).oOperation->Execute(subset)) then $
            goto, done

        ; Remove the padding around the edges.
        xstart = x1preview - x1oper
        ystart = y1preview - y1oper
        subset = subset[xstart: xstart+dim1-1, ystart : ystart+dim2-1]

        subset = CONGRID(TEMPORARY(subset), dimZoom1, dimZoom2)
        ;; If data is not type byte, or the vis is not an image, then
        ;; bytescale the result.  For an image this is what will
        ;; happen when we actually perform the operation.
        if (SIZE(subset, /TYPE) ne 1) || ~(*pState).isImage then $
            subset = BYTSCL(subset)
        winresult[((*pState).xsize - dimZoom1)/2d, $
            ((*pState).ysize - dimZoom2)/2d, i] = TEMPORARY(subset)

    endfor

    WIDGET_CONTROL, (*pState).wDraw2, GET_VALUE=win
    WSET, win
    TV, winresult, TRUE=((*pState).nChannel gt 1) ? 3 : 0

done:
    if (wold ne win) then $
        WSET, wold

end


;-------------------------------------------------------------------------
pro cw_itoperationpreview_realize, wBase

    compile_opt idl2, hidden

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, GET_UVALUE=pState
    cw_itoperationpreview_UPDATEDRAW, pState, /MOTION

end


;-------------------------------------------------------------------------
pro cw_itoperationpreview_killnotify, wChild

    compile_opt idl2, hidden

    WIDGET_CONTROL, wChild, GET_UVALUE=pState

    ; Restore the original color table if necessary.
    if (PTR_VALID((*pState).pPalette)) then begin
        TVLCT, *(*pState).pPalette
        PTR_FREE, (*pState).pPalette
    endif

    ; This will also remove ourself as an observer for all subjects.
    (*pState).oUI->UnRegisterWidget, (*pState).idSelf

    PTR_FREE, pState

end


;-------------------------------------------------------------------------
function cw_itoperationpreview, parent, oUI, $
    XSIZE=xsizeIn, $
    YSIZE=ysizeIn, $
    VALUE=oOperation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

    oTool = oUI->getTool()

    pData = oOperation->_RetrieveDataPointers( $
        BYTESCALE_MIN=bytsclMin, BYTESCALE_MAX=bytsclMax, $
        ISIMAGE=isImage, $
        DIMENSIONS=dims, $
        PALETTE=palette)

    ; We must have a two-dimensional dataset, otherwise bail.
    if (~PTR_VALID(pData[0])) then $
        return, 0L
    if (N_ELEMENTS(dims) ne 2) then $
        return, 0L

    wBase = WIDGET_BASE(parent, $
        /ALIGN_CENTER, $
        EVENT_PRO='cw_itoperationpreview_event', $
        NOTIFY_REALIZE='cw_itoperationpreview_realize', $
        /ROW, $
        SPACE=5, XPAD=0, YPAD=0, $
        /TOOLBAR, $
        _EXTRA=_extra)

    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    idSelf = oUI->RegisterWidget(wBase,'PreviewWindow', $
        'cw_itoperationpreview_callback')

    ; Register for notification messages
    idOperation = oOperation->GetFullIdentifier()
    oUI->AddOnNotifyObserver, idSelf, idOperation

    xsize = N_ELEMENTS(xsizeIn) ? xsizeIn : 128
    ysize = N_ELEMENTS(ysizeIn) ? ysizeIn : 128
    wCol1 = WIDGET_BASE(wBase, /COLUMN)
    wDraw1 = WIDGET_DRAW(wCol1, $
        /BUTTON_EVENT, /MOTION_EVENTS, /TRACKING_EVENTS, $
        XSIZE=xsize, YSIZE=ysize)

    wRow2 = WIDGET_BASE(wCol1, /ROW, /ALIGN_CENTER, SPACE=3)
    bitmap = FILEPATH('zoom_in.bmp', SUBDIR=['resource','bitmaps'])
    wZoomIn = WIDGET_BUTTON(wRow2, VALUE=bitmap, /BITMAP, /FLAT)
    wZoomLabel = WIDGET_LABEL(wRow2, VALUE='100%')
    bitmap = FILEPATH('zoom_out.bmp', SUBDIR=['resource','bitmaps'])
    wZoomOut = WIDGET_BUTTON(wRow2, VALUE=bitmap, /BITMAP, /FLAT)

    wCol2 = WIDGET_BASE(wBase, /COLUMN)
    wDraw2 = WIDGET_DRAW(wCol2, $
        XSIZE=xsize, YSIZE=ysize)


    ; Cache my widget information.
    nchannel = N_ELEMENTS(pData) < 3
    pState = PTR_NEW({wBase: wBase, $
        oUI: oUI, $
        idSelf: idSelf, $
        idOperation: idOperation, $
        wDraw1: wDraw1, $
        wDraw2: wDraw2, $
        wZoomIn: wZoomIn, $
        wZoomLabel: wZoomLabel, $
        wZoomOut: wZoomOut, $
        pData: pData[0:nchannel-1], $
        pPalette: PTR_NEW(), $
        oTool: oTool, $
        oOperation: oOperation, $
        xsize: xsize, $
        ysize: ysize, $
        zoomfactor: 1L, $
        nchannel: nchannel, $
        isImage: isImage, $
        bytescaleMin: [0d, 0d, 0d], $
        bytescaleMax: [255d, 255d, 255d], $
        dims: dims, $
        mousedowncenter: [0d, 0d], $
        center: dims/2d, $
        start: [-1d, -1d], $
        mousedownposition: [0L, 0L], $
        pressed: 0b})

    n = N_ELEMENTS(bytsclMin) < 3
    (*pState).bytescaleMin[0:n-1] = bytsclMin[0:n-1]
    (*pState).bytescaleMax[0:n-1] = bytsclMax[0:n-1]

    if (nchannel eq 1) then begin
        TVLCT, r, g, b, /GET
        (*pState).pPalette = PTR_NEW([[r],[g],[b]])
        if (ARRAY_EQUAL(SIZE(palette, /DIMENSIONS), [3, 256])) then begin
            TVLCT, TRANSPOSE(palette)
        endif else begin
            LOADCT, 0, /SILENT
        endelse
    endif

    wChild = WIDGET_INFO(wBase, /CHILD)
    WIDGET_CONTROL, wChild, $
        KILL_NOTIFY='cw_itoperationpreview_killnotify', $
        SET_UVALUE=pState

    return, wBase
end

