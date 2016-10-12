;
; $Id: //depot/idl/releases/IDL_80/idldir/lib/cw_palette_editor.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CW_PALETTE_EDITOR
;
; PURPOSE:
;   CW_PALETTE_EDITOR is a compound widget for the modification of color
;       palette vectors.
;
; CATEGORY:
;   Compound Widgets
;
; CALLING SEQUENCE:
;   Widget = CW_PALETTE_EDITOR(Parent)
;
; INPUTS:
;   Parent:       ID of the parent widget.
;
; KEYWORD PARAMETERS:
;   DATA:         A 3x256 byte array containing the initial color values
;                 for Red, Green and Blue channels.  The value supplied
;                 can also be a 4x256 byte array containing the initial
;                 color values and the optional Alpha channel.  The value
;                 supplied can also be an IDLgrPalette object reference.
;                 If an IDLgrPalette object reference is supplied it is
;                 used internally and is not destroyed on exit.  If an
;                 object reference is supplied the ALPHA keyword to the
;                 CW_PALETTE_EDITOR_SET routine can be used to supply
;                 the data for the optional Alpha channel.
;
;   FRAME:        If set, a frame will be drawn around the widget.
;
;   HISTOGRAM:    A 256 element byte vector containing the values for
;                 the optional histogram curve.
;
;   HORIZONTAL:   Set this keyword for a horizontal layout for the
;                 compound widget.  This consists of the controls
;                 to the right of the display area.  The default
;                 is a vertical layout with the controls below the
;                 display area.
;
;   SELECTION:    A two element vector defining the starting and ending
;                point of the selection region.  The default is [0,255].
;
;   UNAME:        Set this keyword to a string that can be used to identify
;                 the widget. You can associate a name with each widget in
;                 a specific hierarchy, and then use that name to query the
;                 widget hierarchy and get the correct widget ID.
;
;                 To query the widget hierarchy, use the WIDGET_INFO function
;                 with the FIND_BY_UNAME keyword. The UNAME should be unique
;                 to the widget hierarchy because the FIND_BY_UNAME keyword
;                 returns the ID of the first widget with the specified name.
;
;   UVALUE:       The "user value" to be assigned to the widget. Each widget
;                 can contain a user-specified value of any data type and
;                 organization. This value is not used by the widget in any
;                 way, but exists entirely for the convenience of the IDL
;                 programmer. This keyword allows you to set this value when
;                 the widget is first created. If UVALUE is not present, the
;                 widget's initial user value is undefined.
;
;   XSIZE:        The width of the drawable area in pixels. The default width
;                 is 256.
;
;   YSIZE:        The height of the drawable area in pixels. The default
;                 height is 256.
;
;
; OUTPUTS:
;   The ID of the created widget is returned.
;
;
; PROCEDURE:
;   Standard Compound widget.  Use WIDGET_CONTROL, SET_VALUE and GET_VALUE
;   to change/read the widget's value.  The value supplied to the SET_VALUE
;   keyword can be any of the three types described by the DATA keyword.
;   The value returned by the GET_VALUE keyword is a 3x256 or 4x256 array
;   containing the color vectors and the optional alpha channel if it is
;   in use.
;
; SIDE EFFECTS:
;   Palette Editor Events:
;
;   This widget generates several types of event structures.  There are
;   variations of the palette editor event structure depending on the
;   specific event being reported. All of these structures contain the
;   standard three fields (ID, TOP, and HANDLER).
;   The different palette editor event structures are described below.
;
;   Selection Moved
;
;   This is the type of structure returned when one of the drag handles
;   that define the selection region is moved by a user.
;
;   event = { CW_PALETTE_EDITOR_SM, $
;      ID: state.wCWPalEdTop, $
;      TOP: wAppTop, $
;      HANDLER: handler, $
;      SELECTION: [state.sel_x1, state.sel_x2] $
;   }
;
;   SELECTION indicates a two element vector defining the starting and
;   ending point of the selection region of color indexes.
;
;   Palette Edited
;
;   This is the type of structure returned when the user has modified the
;   color palette.
;
;   event = { CW_PALETTE_EDITOR_PM, $
;      ID: state.wCWPalEdTop, $
;      TOP: wAppTop, $
;      HANDLER: handler $
;   }
;
;   The value of the palette editor will need to be retrieved (i.e.,
;   WIDGET_CONTROL, GET_VALUE) in order to determine the extent of the
;   actual user modification.
;
;
;
; UTILITY ROUTINES
;
;
; CW_PALETTE_EDITOR_GET:     Get palette editor compound widget properties.
;
; CALLING SEQUENCE:
;   CW_PALETTE_EDITOR_GET, widgetID
;
; INPUTS:
;   widgetID:    The widget ID of the CW_PALETTE_EDITOR compound widget.
;
; KEYWORD PARAMETERS:
;   ALPHA:       A 256 element byte array containing the Alpha channel.
;   HISTOGRAM:   A 256 element byte array containing the histogram curve.
;
;
;
; CW_PALETTE_EDITOR_SET:     Set palette editor compound widget properties.
;
; CALLING SEQUENCE:
;   CW_PALETTE_EDITOR_SET, widgetID
;
; INPUTS:
;   widgetID:    The widget ID of the CW_PALETTE_EDITOR compound widget.
;
; KEYWORD PARAMETERS:
;   ALPHA:             A 256 element byte array containing the Alpha channel
;                      or the scalar value zero to remove the alpha curve
;                      from the display.
;   HISTOGRAM:   A 256 element byte array containing the histogram curve
;                      or the scalar value zero to remove the histogram from
;                      the display.
;
;
; EXAMPLE:
;   A = WIDGET_BASE(TITLE='Example', /COLUMN)
;   B = CW_PALETTE_EDITOR(A, ....
;
; MODIFICATION HISTORY:
;   ACY,    April, 1999.    Written.
;   CT, Nov 2006: Removed unneeded lights and polygon bottom color.
;
;-


; Utility and conversion routines

PRO cw_paledit_notImplemented, parent

    COMPILE_OPT HIDDEN, STRICTARR

   result = dialog_message('This operation is not yet implemented', $
      DIALOG_PARENT=parent)

end

function cw_paledit_getviewportsize, state

    COMPILE_OPT HIDDEN, STRICTARR

    geom = widget_info(state.wDraw, /GEOMETRY)
    return, [geom.xsize, geom.ysize]
end

FUNCTION cw_paledit_getDataCoordsfromViewport, state, viewportX, viewportY

    COMPILE_OPT HIDDEN, STRICTARR


    ; given the x and y coords from the viewport, return the
    ; x and y data coordinates
    Result = state.oWindow->Pickdata(state.oView, state.omTop, $
       [viewportX, viewportY], XYZLocation, DIMENSIONS=[1,1])

    if (Result lt 0) then begin
        location = [0,0]
    endif else begin
        location = [fix(XYZLocation[0]), fix(XYZLocation[1])]
    endelse

    return, location

end

FUNCTION cw_paledit_getXDataOfViewportMinMax, state

    COMPILE_OPT HIDDEN, STRICTARR


    ; get current viewport size
    viewportsize = cw_paledit_getviewportsize(state)

    dataCoordsLeft = cw_paledit_getDataCoordsFromViewport(state, 0, 0)
    dataCoordsRight = cw_paledit_getDataCoordsFromViewport(state, $
       viewportsize[0]-1, 0)
    return, [dataCoordsLeft[0], dataCoordsRight[0]]

end

FUNCTION cw_paledit_getXVirtSize, draw

    COMPILE_OPT HIDDEN, STRICTARR

    geom = widget_info(draw, /GEOMETRY)
    return, geom.draw_xsize
end

PRO cw_paledit_setYVirtSize, state, newy

    COMPILE_OPT HIDDEN, STRICTARR

    state.oView->GetProperty, DIMENSIONS=dims
    dims[1]=newy
    ; these should always be the same size
    state.oView->SetProperty, DIMENSIONS=dims
    widget_control, state.wDraw, DRAW_YSIZE=newy
end

PRO cw_paledit_setXVirtSize, state, newx

    COMPILE_OPT HIDDEN, STRICTARR

    newx = newx > state.xsize
    state.oView->GetProperty, DIMENSIONS=dims
    dims[0]=newx
    ; these should always be the same size
    state.oView->SetProperty, DIMENSIONS=dims
    widget_control, state.wDraw, DRAW_XSIZE=newx

    ; subtract the scrollbar height to reserve space for the
    ; horizontal scroll bar, to prevent the display of the
    ; vertical scroll bar
    scrollbarHeight = 20
    if (newx gt state.xsize) then begin
       cw_paledit_setYVirtSize, state, state.ysize-scrollbarHeight
    endif else begin
       cw_paledit_setYVirtSize, state, state.ysize
    endelse

end

FUNCTION cw_paledit_getXViewportLoc, view, draw

    COMPILE_OPT HIDDEN, STRICTARR

    ; view location should be the negative of the widget location
    view->GetProperty, LOCATION=loc
    widget_control, draw, get_draw_view=loc
    return, loc[0]
end

PRO cw_paledit_setXViewportLoc, view, draw, newvirtx

    COMPILE_OPT HIDDEN, STRICTARR

    ; these should always be set together
    ; the location property of the view should be the negative
    ; of widget viewport location
    view->SetProperty, LOCATION=[-newvirtx, 0]
    widget_control, draw, set_draw_view=[newvirtx, 0]
end

FUNCTION cw_paledit_curvesEditable, state

    COMPILE_OPT HIDDEN, STRICTARR

    ; return a vector indicating which of the curves are editable
    ; even indices are for Display, odd indices are for Modify
    return, state.displayModifySettings[(indgen(4)*2)+1]
end


FUNCTION cw_paledit_curvesDisplayed, state

    COMPILE_OPT HIDDEN, STRICTARR

    ; return a vector indicating which of the curves are displayed
    ; even indices are for Display, odd indices are for Modify
    return, state.displayModifySettings[indgen(4)*2]
end



FUNCTION cw_paledit_scaleToDataSpace, state, yData

    COMPILE_OPT HIDDEN, STRICTARR


    ; scale the values appropriately from the current color space
    ; to the data space of [0,255].
    ; HSV
    ;   h: [0,360]
    ;   s, v: [0,1]
    ; HLS
    ;   h: [0,360]
    ;   s, v: [0,1]
    dims = size(yData, /DIMENSIONS)
    case state.colorSpace of
       0: begin ; RGB - no scaling necessary
          yTemp = yData
       end
       1: begin ; HSV
          yTemp = bytarr(dims[0],256)
          yTemp[0,*] = byte((yData[0,*]/360.)*255.)
          yTemp[1:2,*] = byte(yData[1:2,*]*255.)
          if (dims[0] eq 4) then yTemp[3,*] = byte(yData[3,*])
       end
       2: begin ; HLS
          yTemp = bytarr(dims[0],256)
          yTemp[0,*] = byte((yData[0,*]/360.)*255.)
          yTemp[1:2,*] = byte(yData[1:2,*]*255.)
          if (dims[0] eq 4) then yTemp[3,*] = byte(yData[3,*])
       end
    else:
    endcase

    return, yTemp
end


FUNCTION cw_paledit_scaleFromDataSpace, state, yData

    COMPILE_OPT HIDDEN, STRICTARR


    ; scale the values appropriately based from the
    ; the data space of [0,255] to the current color space
    ; HSV
    ;   h: [0,360]
    ;   s, v: [0,1]
    ; HLS
    ;   h: [0,360]
    ;   s, v: [0,1]
    case state.colorSpace of
       0: begin ; RGB - no scaling necessary, just cast to byte
          yTemp = byte(yData)
       end
       1: begin ; HSV
          yTemp = float(yData)
          yTemp[0,*] = (yTemp[0,*]/255.)*360.
          yTemp[1:2,*] = yTemp[1:2,*]/255.
       end
       2: begin ; HLS
          yTemp = float(yData)
          yTemp[0,*] = (yTemp[0,*]/255.)*360.
          yTemp[1:2,*] = yTemp[1:2,*]/255.
       end
    else:
    endcase

    return, yTemp
end


FUNCTION cw_paledit_getPolylineData, state, index

    COMPILE_OPT HIDDEN, STRICTARR

    ; return a vector of the Y data for the requested curve
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; curve 3 is alpha (if applicable)
    state.oPolyline[index]->GetProperty, DATA=data
    data = cw_paledit_scaleFromDataSpace(state, index, data)
    return, data[1,*]
end


PRO cw_paledit_setPolylineData, state, yData

    COMPILE_OPT HIDDEN, STRICTARR

    ; In most cases this should not be called directly,
    ; since it is called by cw_paledit_setAllData
    ;
    ; given a vector of the Y data for the requested curve,
    ; update the corresponding polyline object
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; curve 3 is alpha (if applicable)

    state.oPolyline[0]->GetProperty, DATA=data
    data[1,*]=yData[0,*]
    state.oPolyline[0]->SetProperty, DATA=data

    state.oPolyline[1]->GetProperty, DATA=data
    data[1,*]=yData[1,*]
    state.oPolyline[1]->SetProperty, DATA=data

    state.oPolyline[2]->GetProperty, DATA=data
    data[1,*]=yData[2,*]
    state.oPolyline[2]->SetProperty, DATA=data

    dims = size(yData, /DIMENSIONS)
    if (dims[0] eq 4) then begin
       state.oPolyline[3]->GetProperty, DATA=data
       data[1,*]=yData[3,*]
       state.oPolyline[3]->SetProperty, DATA=data
    endif

end


PRO cw_paledit_setPaletteData, state, oPalette, yData

    COMPILE_OPT HIDDEN, STRICTARR

    ; In most cases this should not be called directly,
    ; since it is called by cw_paledit_setAllData
    ;
    ; given a vector of the Y data for a curve,
    ; update the palette
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; index value of 3 is not applicable (alpha)

    ; scale from the data space to the color space
    yData = cw_paledit_scaleFromDataSpace(state, yData)

    ; if not in rgb, get all three curves, convert to current
    ; system, update the vector that has been modified, then
    ; convert back to rgb and store
    case state.colorSpace of
       0: begin ; RGB
          aRed   = yData[0,*]
          aGreen = yData[1,*]
          aBlue  = yData[2,*]
       end
       1: begin ; HSV
          COLOR_CONVERT, yData[0,*], yData[1,*], yData[2,*], $
                         aRed, aGreen, aBlue, $
                         /HSV_RGB
       end
       2: begin ; HSV
          COLOR_CONVERT, yData[0,*], yData[1,*], yData[2,*], $
                         aRed, aGreen, aBlue, $
                         /HLS_RGB
       end
    endcase

    oPalette->SetProperty, RED_VALUES=aRed
    oPalette->SetProperty, GREEN_VALUES=aGreen
    oPalette->SetProperty, BLUE_VALUES=aBlue
end



FUNCTION cw_paledit_getPaletteData, oPalette, index

    COMPILE_OPT HIDDEN, STRICTARR

    ; given an index, extract the vector of the Y data for a curve
    ;
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; index value of 3 is not applicable (alpha)
    case (index) of
       0: oPalette->GetProperty, RED_VALUES=yData
       1: oPalette->GetProperty, GREEN_VALUES=yData
       2: oPalette->GetProperty, BLUE_VALUES=yData
    else:      ;skip alpha
    endcase

    return, yData
end



FUNCTION cw_paledit_getColorVectorData, state

    COMPILE_OPT HIDDEN, STRICTARR

    ; return a vector of the Y data for the requested curve
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; curve 3 is alpha (if applicable)
    yTemp = cw_paledit_scaleToDataSpace(state, state.colorVectors)
    return, yTemp
end


PRO cw_paledit_setColorVectorData, state, yData

    COMPILE_OPT HIDDEN, STRICTARR

    ; given a vector of the Y data for the requested curve,
    ; update the data for the specified curve.
    ; curves 0,1,2 are r,g,b (or curves for other color system)
    ; curve 3 is alpha (if applicable)

    dims = size(yData, /DIMENSIONS)
    if (dims[0] eq 4) then begin
       state.colorVectors = yData
    endif else begin
       state.colorVectors[0:2,*] = yData
    endelse
end


PRO cw_paledit_setAllData, state, yData

    COMPILE_OPT HIDDEN, STRICTARR


    ; scale from the data space to the color space
    yTemp = cw_paledit_scaleFromDataSpace(state, yData)
    cw_paledit_setColorVectorData, state, yTemp

    ; always use the data space (not color space) for polylines
    cw_paledit_setPolylineData, state, yData

    ; use the unscaled data since setPaletteData does the scaling
    cw_paledit_setPaletteData, state, state.oPaletteMain, yData
end


FUNCTION cw_paledit_buildEventPaletteModified, state, wAppTop, handler

    COMPILE_OPT HIDDEN, STRICTARR


    ; the palette was modified.  Build the event structure which
    ; should be returned by the event handler to the parent
    event = { CW_PALETTE_EDITOR_PM, $
       ID: state.wCWPalEdTop, $
       TOP: wAppTop, $
       HANDLER: handler $
    }
    return, event
end


FUNCTION cw_paledit_buildEventSelectionMoved, state, wAppTop, handler

    COMPILE_OPT HIDDEN, STRICTARR


    ; the palette was modified.  Build the event structure which
    ; should be returned by the event handler to the parent
    event = { CW_PALETTE_EDITOR_SM, $
       ID: state.wCWPalEdTop, $
       TOP: wAppTop, $
       HANDLER: handler, $
       SELECTION: [state.sel_x1, state.sel_x2] $
    }

    return, event
end


; Editing operations



PRO cw_paledit_modifyByIndex, state, xval, yval

    COMPILE_OPT HIDDEN, STRICTARR


    ; determine which curves are editable and then modify value
    ; in the data and then update the object with the new data
    ; only within the selection rectangle and the vertical range
    if ((xval lt state.sel_x1) or (xval gt state.sel_x2)) then return
    if ((yval lt 0) or (yval gt 255)) then return


    if (state.lastModX gt -1) then begin
       ; succeeding event of a freehand editing operation
       xdiff = ABS(state.lastModX - xval)
       if (xdiff gt 1) then begin
          ; the motion event skipped some pixels which need to be interpolated
          ; xstart is the proper starting index
          ; to update the data value with vector of interpolated values
          if (state.lastModX lt xval) then begin
             ; cursor motion increasing in x
             updateX = state.lastModX + 1
             updateY = bindgen(xdiff) * $
                (yval-state.lastModY)/float(xdiff) + state.lastModY
          endif else begin
             ; cursor motion decreasing in x
             updateX = xval
             updateY = bindgen(xdiff) * $
                (state.lastModY-yval)/float(xdiff) + yval
          endelse
          indexIncr = xdiff - 1
       endif else begin
          ; no movement or single pixel movement
          indexIncr = 0
          updateX = xval
          updateY = yval
       endelse
    endif else begin
       ; initial event of a freehand editing operation
       indexIncr = 0
       updateX = xval
       updateY = yval
    endelse
    state.lastModX = xval
    state.lastModY = yval

    modifySettings = cw_paledit_curvesEditable(state)
    data=cw_paledit_getColorVectorData(state)
    for i=0,3 do begin
       if (modifySettings[i] gt 0) then begin
          data[i, updateX : (updateX + indexIncr)]=updateY
       endif
    endfor
    cw_paledit_setAllData, state, data

end

PRO cw_paledit_modifyBySegment, state, xval, yval

    COMPILE_OPT HIDDEN, STRICTARR


    ; determine which curves are editable and then modify value
    ; in the data and then update the object with the new data
    ; only within the selection rectangle and the vertical range
    if ((xval lt state.sel_x1) or (xval gt state.sel_x2)) then return
    if ((yval lt 0) or (yval gt 255)) then return

    if (state.lastModX gt -1) then begin
       ; motion event, succeeding event of a line segment editing operation
       xdiff = ABS(state.lastModX - xval)
       if (xdiff gt 1) then begin
          ; the motion event skipped some pixels which need to be interpolated
          ; xstart is the proper starting index
          ; to update the data value with vector of interpolated values
          if (state.lastModX lt xval) then begin
             ; cursor motion increasing in x
             updateX = state.lastModX + 1
             updateY = bindgen(xdiff) * $
                (yval-state.lastModY)/float(xdiff) + state.lastModY
          endif else begin
             ; cursor motion decreasing in x
             updateX = xval
             updateY = bindgen(xdiff) * $
                (state.lastModY-yval)/float(xdiff) + yval
          endelse
          indexIncr = xdiff - 1
       endif else begin
          ; no movement or single pixel movement
          indexIncr = 0
          updateX = xval
          updateY = yval
       endelse
    endif else begin
       ; button press, initial event of a line segment editing operation
       indexIncr = 0
       updateX = xval
       updateY = yval
       ; use these for the line segment starting point
       ; only save them on the initial button down
       state.lastModX = xval
       state.lastModY = yval
       ; save the current vectors since they need to be refreshed
       ; if the cursor movement retreats
       state.colorVectorsTemp = state.colorVectors
    endelse

    modifySettings = cw_paledit_curvesEditable(state)
    ; use the temporary data to allow refreshing when cursor retreats
    data = state.colorVectorsTemp
    for i=0,3 do begin
       if (modifySettings[i] gt 0) then begin
          data[i, updateX : (updateX + indexIncr)]=updateY
       endif
    endfor
    ; refresh the curves with the values saved before cursor moved
    cw_paledit_setAllData, state, state.colorVectorsTemp
    cw_paledit_setAllData, state, data

end


PRO cw_paledit_modifyBySlide, state, xval, yval

    COMPILE_OPT HIDDEN, STRICTARR


    ; determine which curves are editable and then modify value
    ; in the data and then update the object with the new data
    ; only within the selection rectangle and the vertical range

    if (xval lt 0) then xval = 0
    if (xval gt 255) then xval = 0
    if (yval lt 0) then yval = 0
    if (yval gt 255) then yval = 0

    modifySettings = cw_paledit_curvesEditable(state)
    if (state.lastModX gt -1) then begin
       ; motion event, succeeding event of a slide editing operation
       xdiff = ABS(state.lastModX - xval)
       if (xdiff gt 0) then begin
          ; slide the selection right or left
          if (state.lastModX lt xval) then begin
             ; cursor motion increasing in x
             ; need to update complete width of selection
             updateX = state.sel_x1
             indexIncr = state.sel_x2 - state.sel_x1
             data=cw_paledit_getColorVectorData(state)
             for i=0,3 do begin
                if (modifySettings[i] gt 0) then begin
                   updateY = $
                      [replicate(data[i,state.sel_x1], xdiff), $
                      reform(data[i, state.sel_x1:state.sel_x2-xdiff])]
                   data[i, updateX : (updateX + indexIncr)]=updateY
                endif
             endfor
             cw_paledit_setAllData, state, data
          endif else begin
             ; cursor motion decreasing in x
             updateX = state.sel_x1
             indexIncr = state.sel_x2 - state.sel_x1
             data=cw_paledit_getColorVectorData(state)
             for i=0,3 do begin
                if (modifySettings[i] gt 0) then begin
                   updateY = $
                      [reform(data[i, state.sel_x1+xdiff:state.sel_x2]), $
                      replicate(data[i,state.sel_x2], xdiff)]
                   data[i, updateX : (updateX + indexIncr)]=updateY
                endif
             endfor
             cw_paledit_setAllData, state, data
          endelse
       endif else if (xdiff lt 0) then begin
       endif else begin
          ; no movement in x
          indexIncr = 0
          updateX = xval
          updateY = yval
       endelse
    endif else begin
       ; button press, initial event of a slide editing operation
       indexIncr = 0
       updateX = xval
       updateY = yval
       ; save the current vectors since they need to be refreshed
       ; if the cursor movement retreats
       state.colorVectorsTemp = state.colorVectors
    endelse
    ; current location, saved each time
    state.lastModX = xval
    state.lastModY = yval

end


PRO cw_paledit_modifyByBarrel, state, xval, yval

    COMPILE_OPT HIDDEN, STRICTARR


    ; determine which curves are editable and then modify value
    ; in the data and then update the object with the new data
    ; only within the selection rectangle and the vertical range

    if (xval lt 0) then xval = 0
    if (xval gt 255) then xval = 0
    if (yval lt 0) then yval = 0
    if (yval gt 255) then yval = 0

    modifySettings = cw_paledit_curvesEditable(state)
    if (state.lastModX gt -1) then begin
       ; motion event, succeeding event of a barrel editing operation
       if (ABS(state.lastModX - xval) gt 0) then begin
          xdiff = state.lastModX - xval
          ; barrel shift the selection right or left
          ; cursor motion increasing in x
          ; need to update complete width of selection
          updateX = state.sel_x1
          indexIncr = state.sel_x2 - state.sel_x1
          data=cw_paledit_getColorVectorData(state)
          for i=0,3 do begin
             if (modifySettings[i] gt 0) then begin
                updateY = $
                   shift(reform(data[i, state.sel_x1:state.sel_x2]), -xdiff)
                data[i, updateX : (updateX + indexIncr)]=updateY
             endif
          endfor
          cw_paledit_setAllData, state, data
       endif else begin
          ; no movement in x
          indexIncr = 0
          updateX = xval
          updateY = yval
       endelse
    endif else begin
       ; button press, initial event of a barrel editing operation
       indexIncr = 0
       updateX = xval
       updateY = yval
       ; save the current vectors since they need to be refreshed
       ; if the cursor movement retreats
       state.colorVectorsTemp = state.colorVectors
    endelse
    ; current location, saved each time
    state.lastModX = xval
    state.lastModY = yval

end


PRO cw_paledit_modifyByStretch, state, xval, yval

    COMPILE_OPT HIDDEN, STRICTARR


    ; determine which curves are editable and then modify value
    ; in the data and then update the object with the new data
    ; only within the selection rectangle and the vertical range

    if (xval lt 0) then xval = 0
    if (xval gt 255) then xval = 0
    if (yval lt 0) then yval = 0
    if (yval gt 255) then yval = 0

    modifySettings = cw_paledit_curvesEditable(state)
    if (state.lastModX gt -1) then begin
       ; motion event, succeeding event of a stretch editing operation
       xdiff = ABS(state.lastModX - xval)
       if (xdiff gt 0) then begin
          ; stretch (or compress) the selection
          if (state.lastModX lt xval) then begin
             ; cursor motion increasing in x
             ; need to update complete width of selection
             ; stretch
             updateX = state.sel_x1
             indexIncr = state.sel_x2 - state.sel_x1
             data=cw_paledit_getColorVectorData(state)
             for i=0,3 do begin
                if (modifySettings[i] gt 0) then begin
                   updateY = $
                      reform(data[i, state.sel_x1:state.sel_x2])
                   updateY = congrid(updateY, indexIncr+xdiff+1, /interp)
                   updateY = updateY[0:indexIncr]
                   data[i, updateX : (updateX + indexIncr)]=updateY
                endif
             endfor
             cw_paledit_setAllData, state, data
          endif else begin
             ; cursor motion decreasing in x
             ; need to update complete width of selection
             ; compress
             updateX = state.sel_x1
             indexIncr = state.sel_x2 - state.sel_x1
             data=cw_paledit_getColorVectorData(state)
             for i=0,3 do begin
                if (modifySettings[i] gt 0) then begin
                   if (state.sel_x2+xdiff gt 255) then begin
                      ; use the rest of the full width and
                      ; replicate for the remainder needed
                      updateY = $
                         [reform(data[i, state.sel_x1:255]), $
                          replicate(data[i,255], state.sel_x2+xdiff-255)]
                   endif else begin
                      updateY = $
                         reform(data[i, state.sel_x1:state.sel_x2+xdiff])
                   endelse
                   ;;;updateY = smooth(congrid(updateY, indexIncr+1), 3)
                   updateY = congrid(updateY, indexIncr+1, /interp)
                   data[i, updateX : (updateX + indexIncr)]=updateY
                endif
             endfor
             cw_paledit_setAllData, state, data
          endelse
       endif else if (xdiff lt 0) then begin
       endif else begin
          ; no movement in x
          indexIncr = 0
          updateX = xval
          updateY = yval
       endelse
    endif else begin
       ; button press, initial event of a stretch editing operation
       indexIncr = 0
       updateX = xval
       updateY = yval
       ; save the current vectors since they need to be refreshed
       ; if the cursor movement retreats
       state.colorVectorsTemp = state.colorVectors
    endelse
    ; current location, saved each time
    state.lastModX = xval
    state.lastModY = yval

end

PRO cw_paledit_modifyByCurveType, state, type

    COMPILE_OPT HIDDEN, STRICTARR


    xdiff = state.sel_x2 - state.sel_x1 + 1
    if (xdiff gt 1) then begin
       updateX = state.sel_x1
       modifySettings = cw_paledit_curvesEditable(state)
       data=cw_paledit_getColorVectorData(state)
       for i=0,3 do begin
          if (modifySettings[i] gt 0) then begin
             case type of
             'RAMP': begin
                 updateY = findgen(xdiff) * (256)/float(xdiff)
             end
             'SMOOTH': begin
                 updateY = smooth(reform( $
                              data[i, updateX : (updateX + xdiff - 1)]), 5)
             end
             'REVERSE': begin
                 updateY = reverse(reform( $
                              data[i, updateX : (updateX + xdiff - 1)]))
             end
             'INVERT': begin
                 updateY = 255 - reform( $
                              data[i, updateX : (updateX + xdiff - 1)])
             end
             'POSTERIZE': begin
                 origY = reform(data[i, updateX : (updateX + xdiff - 1)])
                 if (xdiff gt 5) then begin
                    tempLen = xdiff / 5
                    ; congrid data down
                    updateY = congrid(origY, tempLen)
                    ; and then back up to posterize
                    updateY = congrid(updateY, xdiff)
                 endif else updateY = origY
             end
             'DUPLICATE': begin
                 origY = reform(data[i, updateX : (updateX + xdiff - 1)])
                 tempLen = xdiff / 2
                 ; congrid data down
                 tempY = congrid(origY, tempLen)
                 updateY = bytarr(xdiff)
                 updateY[0] = tempY
                 updateY[xdiff/2] = tempY
                 ; fill in last pixel if necessary
                 updateY[xdiff-1] = tempY[(xdiff/2)-1]
             end
             else:
             endcase
             data[i, updateX : (updateX + xdiff - 1)]=updateY
          endif
       endfor
       cw_paledit_setAllData, state, data
    endif
end

PRO cw_paledit_EditPredefined, state, index

    COMPILE_OPT HIDDEN, STRICTARR

    if (index eq 0) then return   ;skip the first menu item "predefined"
    oPaletteTemp = OBJ_NEW('IDLgrPalette')
    ; skip the first menu item
    oPaletteTemp->LoadCT, index-1
    oPaletteTemp->GetProperty, RED_VALUES = aRed, $
                               GREEN_VALUES = aGreen, $
                               BLUE_VALUES = aBlue
    OBJ_DESTROY, oPaletteTemp

    ; test the existing color space setting
    ; and convert dataTemp to HSV or HSL if necessary
    case state.colorSpace of
    0: begin ; RGB, no change
       dataTemp = bytarr(3,256)
       dataTemp[0,*]=aRed
       dataTemp[1,*]=aGreen
       dataTemp[2,*]=aBlue
    end
    1: begin ; RGB to HSV
       COLOR_CONVERT, aRed, aGreen, aBlue, $
                      cVecOut0, cVecOut1, cVecOut2, $
                      /RGB_HSV
       ; convert back to data space which is expected below
       yTemp = fltarr(3,256)
       yTemp[0,*] = cVecOut0
       yTemp[1,*] = cVecOut1
       yTemp[2,*] = cVecOut2
       dataTemp = cw_paledit_scaleToDataSpace(state, yTemp)
    end
    2: begin ; RGB to HLS
       COLOR_CONVERT, aRed, aGreen, aBlue, $
                      cVecOut0, cVecOut1, cVecOut2, $
                      /RGB_HLS
       ; convert back to data space which is expected below
       yTemp = fltarr(3,256)
       yTemp[0,*] = cVecOut0
       yTemp[1,*] = cVecOut1
       yTemp[2,*] = cVecOut2
       dataTemp = cw_paledit_scaleToDataSpace(state, yTemp)
    end
    else:
    endcase


    ; only load the selected part of a predefined curve
    ; and only load the individual channels that are editable
    modifySettings = cw_paledit_curvesEditable(state)
    start = state.sel_x1
    xdiff = state.sel_x2 - state.sel_x1
    data = cw_paledit_getColorVectorData(state)
    for i=0,2 do begin
       if (modifySettings[i] gt 0) then begin
          data[i, start:start+xdiff] = $
             dataTemp[i, start:start+xdiff]
       endif
    endfor
    cw_paledit_setAllData, state, data
end



; Zooming operations

PRO cw_paledit_zoom_toselection, state

    COMPILE_OPT HIDDEN, STRICTARR


    ; get virtual size
    xsize_virt = cw_paledit_getXVirtSize(state.wDraw)

    ; get scale factor from current selection size (data coords)
    ; to current viewport size (screen coordinates) by converting
    ; viewport 0 and viewportsize-1 to data coordinates
    xDataOfViewportMinMax = cw_paledit_getXDataOfViewportMinMax(state)
    diff_viewport_data = xDataOfViewportMinMax[1]-xDataOfViewportMinMax[0]

    ; get scale factor from data size of current viewport
    ; to new data size of desired selection
    ; and set new virtual size (both draw widget and view dimensions)
    diffactor = float(diff_viewport_data) / (state.sel_x2 - state.sel_x1)
    xsize_virt_new = xsize_virt * diffactor
    cw_paledit_setXVirtSize, state, xsize_virt_new

    ; compute scale factor from data space to virtual space
    ; and scale left selection point to get new vieport location.
    ; set new viewport location
    scale_factor_new = xsize_virt_new / 256.
    x1sel_virt_new = state.sel_x1 * scale_factor_new
    cw_paledit_setXViewportLoc, state.oView, state.wDraw, x1sel_virt_new

    ; scale changed, scale the width of the drag handles
    cw_paledit_DragSetWidth, state, xsize_virt_new

end


PRO cw_paledit_zoom_byfactor, state, scale_factor

    COMPILE_OPT HIDDEN, STRICTARR


   ; get current viewport size
   viewportsize = cw_paledit_getviewportsize(state)

   ; get virtual size and viewport location
   xsize_virt = cw_paledit_getXVirtSize(state.wDraw)

   ; additional code for zoom_out, don't reduce past 1:1
   if xsize_virt * scale_factor LE 256 then begin
      cw_paledit_zoom_1to1, state
      return
   endif

   xviewportloc_virt = cw_paledit_getXViewportLoc(state.oView, state.wDraw)

   ; get center of viewport in data coords
   ; to current viewport size (screen coordinates) by converting
   ; viewport 0 and viewportsize-1 to data coordinates
   xDataOfViewportMinMax = cw_paledit_getXDataOfViewportMinMax(state)
   center_viewport_data = $
      (xDataOfViewportMinMax[1] + xDataOfViewportMinMax[0]) / 2.0

   ; compute the new virtual size
   xsize_virt_new = xsize_virt * scale_factor

   ; scale center point to virtual coords and
   ; compute the new viewport location
   center_viewport_virtual = center_viewport_data * xsize_virt_new / 256
   xviewport_width_data_new = $
      (xDataOfViewportMinMax[1] - xDataOfViewportMinMax[0]) / scale_factor
   xviewport_width_virtual_new = xviewport_width_data_new * $
      xsize_virt_new / 256
   xviewportloc_virt_new = center_viewport_virtual - $
      xviewport_width_virtual_new / 2.
   ; make sure new location is within appropriate range
   xviewportloc_virt_new = xviewportloc_virt_new > 0
   xviewportloc_virt_new = $
      xviewportloc_virt_new < (xsize_virt_new - xviewport_width_virtual_new)

   ; set the new size and location
   cw_paledit_setXVirtSize, state, xsize_virt_new
   cw_paledit_setXViewportLoc, state.oView, state.wDraw, xviewportloc_virt_new
   ; scale changed, scale the width of the drag handles
   cw_paledit_DragSetWidth, state, xsize_virt_new


end


PRO cw_paledit_zoom_1to1, state

    COMPILE_OPT HIDDEN, STRICTARR


    ; get current viewport size
    viewportsize = cw_paledit_getviewportsize(state)

    cw_paledit_setXVirtSize, state, viewportsize[0]
    xRescaled = 0
    cw_paledit_setXViewportLoc, state.oView, state.wDraw, xRescaled

    ; scale changed, scale the width of the drag handles
    cw_paledit_DragSetWidth, state, viewportsize[0]

end

; Routines to update display of data values

PRO cw_paledit_DisplayDataVals, state, xData, yData

    COMPILE_OPT HIDDEN, STRICTARR


    x = string(fix(xData), format='(I3)')
    y = string(fix(yData), format='(I3)')

    cursorLine = '(X,Y): ('+x+', '+y+')'

    case state.colorSpace of
    0: rgbaLine = '(R,G,B,A): ('
    1: rgbaLine = '(H,S,V,A): ('
    2: rgbaLine = '(H,L,S,A): ('
    else:
    endcase

    colorVectors = cw_paledit_getColorVectorData(state)
    yVals = colorVectors[*, fix(xData)]
    ; scale from the data space to the color space
    yScaled = cw_paledit_scaleFromDataSpace(state, yVals)
    for i=0,2 do begin
       if ((state.colorSpace ne 0) and (i gt 0)) then begin
          sTemp = string(yScaled[i], /PRINT, format='(F4.2)')
       endif else begin
          sTemp = string(yScaled[i], /PRINT, format='(I3)')
       endelse

       rgbaLine = $
          rgbaLine+sTemp + ', '
    endfor
    if (state.alphaInUse) then begin
       rgbaLine = $
          rgbaLine+strtrim(fix(yVals[3]), 2) + ')'
    endif else rgbaLine = rgbaLine + '---)'

    widget_control, state.wStatus, set_value = $
       [cursorLine, rgbaLine]
end

; Routines for updating display of Selection rectangle and drag handles

PRO cw_paledit_DragSetWidth, state, xsize_virt_new

    COMPILE_OPT HIDDEN, STRICTARR


   xyzDrag = fltarr(3,4, /nozero)
   ; constants, set via properties ?
   ytop = 266
   drag_width_data = 5

   ; scale the width of the drag handles down if zoomed in
   dw = drag_width_data / (xsize_virt_new / 256.)

   xyzDrag[1,*]=[ytop,ytop,ytop-10,ytop]
   xyzDrag[2,*]=0.5

   ; left drag handle
   xyzDrag[0,*]=[state.sel_x1-dw,state.sel_x1+dw,state.sel_x1,state.sel_x1-dw]
   state.oPolygonDragLeft->SetProperty, DATA=xyzDrag

   ; right drag handle (re-use y from above)
   xyzDrag[0,*]=[state.sel_x2-dw,state.sel_x2+dw,state.sel_x2,state.sel_x2-dw]
   state.oPolygonDragRight->SetProperty, DATA=xyzDrag

end

PRO cw_paledit_DragSetLoc, wDraw, oPolygon, newX

    COMPILE_OPT HIDDEN, STRICTARR


   xyzDrag = fltarr(3,4, /nozero)
   ; constants, set via properties ?
   ytop = 266
   drag_width_data = 5

   ; scale the width of the drag handles down if zoomed in
   xsize_virt = cw_paledit_getXVirtSize(wDraw)
   dw = drag_width_data / (xsize_virt / 256.)

   xyzDrag[0,*]=[newX-dw,newX+dw,newX,newX-dw]
   xyzDrag[1,*]=[ytop,ytop,ytop-10,ytop]
   xyzDrag[2,*]=0.5

   oPolygon->SetProperty, DATA=xyzDrag

end

PRO SelectionSetLoc, oPolygonSelection, $
   new_left, new_right

    COMPILE_OPT HIDDEN, STRICTARR


   xyzSelection = fltarr(3,5, /nozero)
   xyzSelection[0,*]=[new_left,new_right,new_right,new_left, new_left]
   xyzSelection[1,*]=[0,0,256,256,0]
   xyzSelection[2,*]=-.5
   oPolygonSelection->SetProperty, DATA=xyzSelection

end

; Init, cleanup and event handler routines



FUNCTION cw_paledit_getvalue, wId

    COMPILE_OPT HIDDEN, STRICTARR


    wCWPalEdMainBase = widget_info(wID, /child)
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        MESSAGE, /RESET
        RETURN, 0L
    endif


    colors = bytarr(3+state.alphaInUse, 256)
    colors[0,*] = cw_paledit_getPaletteData(state.oPaletteMain, 0)
    colors[1,*] = cw_paledit_getPaletteData(state.oPaletteMain, 1)
    colors[2,*] = cw_paledit_getPaletteData(state.oPaletteMain, 2)
    if (state.alphaInUse) then colors[3,*] = state.colorVectors[3,*]

    widget_control,wCWPalEdMainBase,set_uvalue=state

    return, colors

end

FUNCTION cw_paledit_CheckData, inData, $
                               outPalette, $
                               outPaletteSupplied, $
                               outValues, $
                               outAlphaInUse

    COMPILE_OPT HIDDEN, STRICTARR


    ; value should be a 3x256 or 4x256 element byte array or
    ; an IDLgrPalette object.  if the value argument is an
    ; IDLgrPalette then the palette should be used
    ; internally and not cleaned up on exit.
    ; if the data is not valid return 0.  if valid return 1

    result = 0L
    outPalette = OBJ_NEW()
    outPaletteSupplied = 0L
    outAlphaInUse = 0L

    sizeStruct = size(inData, /STRUCTURE)
    invalid = 0
    case sizeStruct.type OF
    1: begin    ; Byte Array
       if (sizeStruct.n_dimensions eq 2) then begin
          ; if correct number of dims, test the actual dims
          if (((sizeStruct.dimensions[0] eq 3) or $
               (sizeStruct.dimensions[0] eq 4)) and $
              (sizeStruct.dimensions[1] eq 256)) then begin
             outValues = inData
             outAlphaInUse = (sizeStruct.dimensions[0] eq 4)
             result = 1L
          endif
       endif
    end

    11: begin    ; Object Reference
       if (OBJ_ISA(inData, 'IDLgrPalette')) then begin
          outPalette = inData
          outPaletteSupplied = 1L
          outPalette->GetProperty, $
             RED_VALUES=aRed, GREEN_VALUES=aGreen, BLUE_VALUES=aBlue
          ; build the outValues variable for use by polylines
          outValues=bytarr(3,256)
          outValues[0,*] = aRed
          outValues[1,*] = aGreen
          outValues[2,*] = aBlue
          result = 1L
       endif
    end
    ELSE:
    ENDCASE

    return, result

end

PRO cw_paledit_setvalue, wId, value

    COMPILE_OPT HIDDEN, STRICTARR


    if (cw_paledit_CheckData(value, $
                             outPalette, $
                             outPaletteSupplied, $
                             outValues, $
                             outAlphaInUse) le 0) then begin
       message, 'cw_palette_editor: set_value: Invalid argument'
       return
    endif

    wCWPalEdMainBase = widget_info(wID, /child)
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


    if (outPaletteSupplied eq 1) then begin
       ; palette object supplied, delete previous and update image with new
       if (state.paletteNoCleanup le 0) then OBJ_DESTROY, state.oPaletteMain
       state.oPaletteMain = outPalette
       state.oImageColBarMain->SetProperty, PALETTE=outPalette
       state.paletteNoCleanup = 1L
    endif

    state.alphaInUse = outAlphaInUse

    cw_paledit_setAllData, state, outValues[0:2+state.alphaInUse,*]
    widget_control, state.wDispModAlphaButtons[0], SENSITIVE=state.alphaInUse
    widget_control, state.wDispModAlphaButtons[1], SENSITIVE=state.alphaInUse
    widget_control, state.wDispModAlphaButtons[0], SET_BUTTON=state.alphaInUse
    state.oPolyline[3]->SetProperty, HIDE=(state.alphaInUse ? 0 : 1)

    state.oWindow->Draw, state.oView

    widget_control,wCWPalEdMainBase,set_uvalue=state

end

FUNCTION cw_paledit_DrawHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    ; get the id of the wCWPalEdMainBase widget from user value
    ; and retrieve the state
    widget_control, ev.id, get_uvalue=wCWPalEdMainBase
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN, 0L
    endif



    if ((ev.type EQ 0) or (ev.type EQ 2)) then begin
       ; handle button press and motion events together

       ; if user drags out of window, limit the event to the viewport
       if (ev.type eq 2) then begin
          viewport_size = cw_paledit_getviewportsize(state)
          ev.x = ev.x > 0
          ev.x = ev.x < (viewport_size[0]-1)
          ev.y = ev.y > 0
          ev.y = ev.y < (viewport_size[1]-1)
       endif

       dataCoords = cw_paledit_getDataCoordsFromViewport(state, ev.x, ev.y)

       if (state.debug) then begin
          print, 'button press in viewport: ', ev.x, ev.y
          print, 'coords in model space: ', dataCoords[0], $
             dataCoords[1]
       endif

       ; test data coordinates to determine if in drag area or edit area
       ; to allow non-default size viewport when setting the initial
       ; button down flag for button press
       if (ev.type eq 0) then begin
          if (dataCoords[1] gt 255) then begin
             state.buttonDownDragArea=1
          endif else begin
             state.buttonDownEditArea=1
          endelse
       endif

       ; update display of cursor coords.  limit y value used
       ; for curve editing to 255, but allow setting of x data
       ; coordinates regardless of y
       dataCoords[1] = dataCoords[1] < 255
       dataCoords[1] = dataCoords[1] > 0

       cw_paledit_DisplayDataVals, state, $
          dataCoords[0], dataCoords[1]

       if (state.buttonDownDragArea eq 1) then begin
          ; use SIZE_EW cursor for drag handle area
          state.oWindow->SetCurrentCursor, 'SIZE_EW'
          if (ev.type eq 0) then begin
             ; determine which drag handle is closer
             if abs(dataCoords[0]-state.sel_x1) lt $
                abs(dataCoords[0]-state.sel_x2) then begin
                state.handle_in_use = 0
             endif else begin
                state.handle_in_use = 1
             endelse
          endif
          ; update the drag handle which was being moved
          if (state.handle_in_use eq 0) then begin
             ; make sure left selection is never greater than right
             ; and the selection width is always at least 1 pixel wide
             new_left = dataCoords[0] < (state.sel_x2-1)
             cw_paledit_DragSetLoc, state.wDraw, state.oPolygonDragLeft, $
                new_left
             state.sel_x1 = new_left
             new_right = state.sel_x2
          endif else begin
             ; make sure right selection is never less than left
             ; and the selection width is always at least 1 pixel wide
             new_left = state.sel_x1
             new_right = dataCoords[0] > (state.sel_x1+1)
             cw_paledit_DragSetLoc, state.wDraw, state.oPolygonDragRight, $
                new_right
             state.sel_x2 = new_right
          endelse

          SelectionSetLoc, state.oPolygonSelection, $
             new_left, new_right
          state.oWindow->Draw, state.oView
          event = cw_paledit_buildEventSelectionMoved(state, $
             ev.top, ev.handler)
          widget_control,wCWPalEdMainBase,set_uvalue=state
          return, event
       endif

       if (state.buttonDownEditArea eq 1) then begin
          ; modify curves if editable
          ; use CROSSHAIR cursor for curve data area
          state.oWindow->SetCurrentCursor, 'CROSSHAIR'

          if (TOTAL(cw_paledit_curvesEditable(state)) gt 0) then begin
             if (state.editMode eq 0) then begin
                ; freehand
                cw_paledit_modifyByIndex, state, $
                   dataCoords[0], dataCoords[1]
                state.oWindow->Draw, state.oView
                event = cw_paledit_buildEventPaletteModified(state, $
                   ev.top, ev.handler)
             endif
             if (state.editMode eq 1) then begin
                ; line segment
                cw_paledit_modifyBySegment, state, $
                   dataCoords[0], dataCoords[1]
                state.oWindow->Draw, state.oView
                event = cw_paledit_buildEventPaletteModified(state, $
                   ev.top, ev.handler)
             endif
             if (state.editMode eq 2) then begin
                ; stretch
                cw_paledit_modifyByBarrel, state, $
                   dataCoords[0], dataCoords[1]
                state.oWindow->Draw, state.oView
                event = cw_paledit_buildEventPaletteModified(state, $
                   ev.top, ev.handler)
             endif
             if (state.editMode eq 3) then begin
                ; slide
                cw_paledit_modifyBySlide, state, $
                   dataCoords[0], dataCoords[1]
                state.oWindow->Draw, state.oView
                event = cw_paledit_buildEventPaletteModified(state, $
                   ev.top, ev.handler)
             endif
             if (state.editMode eq 4) then begin
                ; stretch
                cw_paledit_modifyByStretch, state, $
                   dataCoords[0], dataCoords[1]
                state.oWindow->Draw, state.oView
                event = cw_paledit_buildEventPaletteModified(state, $
                   ev.top, ev.handler)
             endif
          endif else event=0
          widget_control,wCWPalEdMainBase,set_uvalue=state
          return, event
       endif ; button down

    endif ; button press and motion events

    if (ev.type eq 1) then begin
       ; button release event
       if (state.buttonDownDragArea eq 1) then begin
          state.oWindow->SetCurrentCursor, 'CROSSHAIR'
          state.oWindow->Draw, state.oView
       endif
       state.buttonDownDragArea=0
       state.buttonDownEditArea=0
       ; reset editing values for last cursor position
       state.lastModX = -1
       state.lastModY = -1
       widget_control,wCWPalEdMainBase,set_uvalue=state
    endif
    if (ev.type EQ 3) then begin
       ; viewport moved
       state.oView->SetProperty, LOCATION=[-ev.x, 0]
       state.oWindow->Draw, state.oView
       widget_control,wCWPalEdMainBase,set_uvalue=state
    endif
    if (ev.type eq 4) then begin
       ; expose event
       state.oWindow->Draw, state.oView
       widget_control,wCWPalEdMainBase,set_uvalue=state
    endif

end


PRO cw_paledit_displayModifyButtonHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    ; get the id of the wCWPalEdMainBase widget from user value
    ; and retrieve the state
    widget_control, ev.id, get_uvalue=wCWPalEdMainBase

    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


    displayChanged = 0
    for i = 0, 3 do begin
       if (ev.id eq state.wDispModButtons[i*2]) then begin
          state.displayModifySettings[i*2] = ev.select
          state.oPolyline[i]->SetProperty, HIDE=(ev.select?0:1)
          displayChanged = 1
       endif
       if (ev.id eq state.wDispModButtons[(i*2)+1]) then begin
          state.displayModifySettings[(i*2)+1] = ev.select
       endif
    endfor

    if displayChanged then state.oWindow->Draw, state.oView

    widget_control,wCWPalEdMainBase,set_uvalue=state

end

PRO cw_paledit_zoomButtonHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    ; get the id of the wCWPalEdMainBase widget from the user
    ; value of the parent
    ; (the base holding the zoom buttons) and retrieve the state
    parent = widget_info(ev.id, /parent)
    widget_control, parent, get_uvalue=wCWPalEdMainBase
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


    widget_control, ev.id, get_uvalue=uvalue
    case uvalue of
       'ZOOM_SEL': begin
          cw_paledit_zoom_toselection, state
          state.oWindow->Draw, state.oView
          widget_control,wCWPalEdMainBase,set_uvalue=state
       end
       'ZOOM_IN': begin
          scale_factor = 2.
          cw_paledit_zoom_byfactor, state, scale_factor
          state.oWindow->Draw, state.oView
          widget_control,wCWPalEdMainBase,set_uvalue=state
       end
       'ZOOM_OUT': begin
          scale_factor = 0.5
          cw_paledit_zoom_byfactor, state, scale_factor
          state.oWindow->Draw, state.oView
          widget_control,wCWPalEdMainBase,set_uvalue=state
       end
       'ZOOM_1TO1': begin
           cw_paledit_zoom_1to1, state
           state.oWindow->Draw, state.oView
           widget_control,wCWPalEdMainBase,set_uvalue=state
       end
       ELSE:
    endcase

end
PRO cw_paledit_colorSpaceHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    widget_control, ev.id, get_uvalue=wCWPalEdMainBase
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


    ; order is: [ 'RGB', 'HSV', 'HLS']
    cVecs = cw_paledit_getColorVectorData(state)

    cVecs = cw_paledit_scaleFromDataSpace(state, cVecs)
    case ev.index of
       0: begin ; RGB
          widget_control, state.wChannelLabels[0], set_value=' R'
          widget_control, state.wChannelLabels[1], set_value=' G'
          widget_control, state.wChannelLabels[2], set_value=' B'

          ; test the existing color space setting
          case state.colorSpace of
          0: return   ; no change
          1: begin ; HSV to RGB
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /HSV_RGB
          end
          2: begin ; HLS to RGB
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /HLS_RGB
          end
          else:
          endcase
       end
       1: begin ; HSV
          widget_control, state.wChannelLabels[0], set_value=' H'
          widget_control, state.wChannelLabels[1], set_value=' S'
          widget_control, state.wChannelLabels[2], set_value=' V'

          ; test the existing color space setting
          case state.colorSpace of
          0: begin ; RGB to HSV
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /RGB_HSV
          end
          1: return   ; no change
          2: begin ; HLS to HSV
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            tmp0, tmp1, tmp2, $
                            /HLS_RGB
             COLOR_CONVERT, tmp0, tmp1, tmp2, $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /RGB_HSV
          end
          else:
          endcase
       end
       2: begin ; HLS
          widget_control, state.wChannelLabels[0], set_value=' H'
          widget_control, state.wChannelLabels[1], set_value=' L'
          widget_control, state.wChannelLabels[2], set_value=' S'

          ; test the existing color space setting
          case state.colorSpace of
          0: begin ; RGB to HLS
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /RGB_HLS
          end
          1: begin ; HSV to HLS
             COLOR_CONVERT, reform(cVecs[0,*]), reform(cVecs[1,*]), $
                            reform(cVecs[2,*]), $
                            tmp0, tmp1, tmp2, $
                            /HSV_RGB
             COLOR_CONVERT, tmp0, tmp1, tmp2, $
                            cVecOut0, cVecOut1, cVecOut2, $
                            /RGB_HLS
          end
          2: return   ; no change
          else:
          endcase
       end
    else:
    endcase
    state.colorSpace = ev.index

    colorVectors = fltarr(3, 256)
    colorVectors[0,*] = cVecOut0
    colorVectors[1,*] = cVecOut1
    colorVectors[2,*] = cVecOut2

    ; scale from the color space to the data space for polylines
    cVectorsTemp = cw_paledit_scaleToDataSpace(state, colorVectors)
    cw_paledit_setPolylineData, state, cVectorsTemp
    cw_paledit_setColorVectorData, state, colorVectors

    state.oWindow->Draw, state.oView
    widget_control,wCWPalEdMainBase,set_uvalue=state

end

PRO cw_paledit_editModeHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    widget_control, ev.id, get_uvalue=wCWPalEdMainBase
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


    case ev.index of
       0:
       1:
       2:
       3:
       4: begin
             ;;;cw_paledit_notImplemented, state.wCWPalEdTop
             ;;;ev.index = 0
             ;;;widget_control, ev.id, SET_DROPLIST_SELECT=0
       end
       else:
    endcase

    state.editMode = ev.index
    widget_control,wCWPalEdMainBase,set_uvalue=state

end

FUNCTION cw_paledit_OperateButtonHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


    widget_control, ev.id, get_uvalue=wCWPalEdMainBase
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN, 0L
    endif


    case ev.id of
       state.wButtonRamp: cw_paledit_modifyByCurveType, state, 'RAMP'
       state.wButtonSmooth: cw_paledit_modifyByCurveType, state, 'SMOOTH'
       state.wComboboxPredefined: begin
          if ev.index ge 0 then $
             cw_paledit_editPredefined, state, ev.index
          if !version.arch eq 'alpha' && !version.os eq 'OSF' then $
             widget_control, state.wComboboxPredefined, set_droplist_select=0 $
          else $
             widget_control, state.wComboboxPredefined, set_combobox_select=0
       end
       state.wButtonReverse: cw_paledit_modifyByCurveType, state, 'REVERSE'
       state.wButtonInvert: cw_paledit_modifyByCurveType, state, 'INVERT'
       state.wButtonPosterize: cw_paledit_modifyByCurveType, state, 'POSTERIZE'
       state.wButtonDuplicate: cw_paledit_modifyByCurveType, state, 'DUPLICATE'
    else:
    endcase

    event = cw_paledit_buildEventPaletteModified(state, $
       ev.top, ev.handler)

    state.oWindow->Draw, state.oView
    widget_control,wCWPalEdMainBase,set_uvalue=state

    return, event

end


PRO cw_paledit_nullEventHandler, ev

    COMPILE_OPT HIDDEN, STRICTARR


end

FUNCTION cw_paledit_event, ev

    COMPILE_OPT HIDDEN, STRICTARR

    parent=ev.handler
    wCWPalEdMainBase = widget_info(parent, /child)
    widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN, 0L
    endif

    ; Most events are swallowed, except for the MODIFIED event
    RETURN, 0

end


PRO cw_paledit_cleanup, wCWPalEdMainBase

    COMPILE_OPT HIDDEN, STRICTARR

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=dialog_parent)
        RETURN   ; assume nothing needs to be cleaned up.
    endif

    ; this widget is the first child of the top palette editor base
    widget_control, wCWPalEdMainBase ,get_uvalue=state

    if (N_ELEMENTS(state) gt 0) then begin
        dialog_parent = state.wCWPalEdTop
        ; Delete any created objects.
        if (state.paletteNoCleanup ne 1) then $
            OBJ_DESTROY, state.oPaletteMain
        OBJ_DESTROY, state.oView
    endif

end


PRO cw_paledit_init, id

    COMPILE_OPT HIDDEN, STRICTARR


   wCWPalEdMainBase = widget_info(id, /child)
   widget_control,wCWPalEdMainBase,get_uvalue=state

    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL

        void = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
            DIALOG_PARENT=state.wCWPalEdTop)
        RETURN
    endif


   WIDGET_CONTROL, state.wDraw, GET_VALUE=oWindow
   state.oWindow = oWindow

   cw_paledit_DisplayDataVals, state, 0, 0

   SelectionSetLoc, state.oPolygonSelection, state.sel_x1, state.sel_x2
   cw_paledit_DragSetLoc, state.wDraw, state.oPolygonDragLeft, state.sel_x1
   cw_paledit_DragSetLoc, state.wDraw, state.oPolygonDragRight, state.sel_x2
   cw_paledit_DragSetWidth, state, cw_paledit_getXVirtSize(state.wDraw)

   oWindow->Draw, state.oView

   widget_control, wCWPalEdMainBase, set_uvalue=state

end

PRO CW_PALETTE_EDITOR_SET, id, $
    ALPHA=alpha, $                    ; IN: Alpha vector to display or
                                      ;     scalar value zero to remove
                                      ;     alpha from the display
    HISTOGRAM=histogram               ; IN: Histogram vector to display or
                                      ;     scalar value zero to remove
                                      ;     histogram from the display

    ; This is an external api and should not be HIDDEN
    COMPILE_OPT STRICTARR

    ON_ERROR, 2                     ;return to caller

    wBase = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=state

    if (N_ELEMENTS(alpha) ne 0) then begin
       ndims = size(alpha, /N_DIMENSIONS)
       case ndims of
       0: begin   ; Alpha set to scalar, remove from display
          state.alphaInUse = 0

          widget_control, state.wDispModAlphaButtons[0], $
             SENSITIVE = 0, $
             SET_BUTTON = 0
          widget_control, state.wDispModAlphaButtons[1], $
             SENSITIVE = 0, $
             SET_BUTTON = 0

          state.oPolyline[3]->SetProperty, /HIDE
       end
       1: begin   ; Alpha set to vector, add to display
          dims =  size(alpha, /DIMENSIONS)
          if (dims[0] ne 256) then $
             message, 'cw_palette_editor: ALPHA: Invalid argument'

          state.alphaInUse = 1

          widget_control, state.wDispModAlphaButtons[0], $
             /SENSITIVE, $
             /SET_BUTTON
          widget_control, state.wDispModAlphaButtons[1], $
             /SENSITIVE, $
             /SET_BUTTON

          data = cw_paledit_getColorVectorData(state)
          data[3,*] = alpha
          cw_paledit_setAllData, state, data
          state.oPolyline[3]->SetProperty, HIDE=0
       end
       else: message, 'cw_palette_editor: ALPHA: Invalid argument'
       endcase
    endif

    if (N_ELEMENTS(histogram) ne 0) then begin
       ndims = size(histogram, /N_DIMENSIONS)
       case ndims of
       0: begin   ; Histogram set to scalar, remove from display
          state.histogramInUse = 0
          state.oPolylineHist->SetProperty, /HIDE
       end
       1: begin   ; Histogram set to vector, add to display
          dims =  size(histogram, /DIMENSIONS)
          if (dims[0] ne 256) then $
             message, 'cw_palette_editor: HISTOGRAM: Invalid argument'

          state.histogramInUse = 1
          state.oPolylineHist->GetProperty, data=data
          data[1,*] = histogram
          state.oPolylineHist->SetProperty, data=data, HIDE=0
       end
       else: message, 'cw_palette_editor: HISTOGRAM: Invalid argument'
       endcase
    endif

    state.oWindow->Draw, state.oView
    WIDGET_CONTROL, wBase, SET_UVALUE=state

end

PRO CW_PALETTE_EDITOR_GET, id, $
    ALPHA=alpha, $                    ; OUT: Alpha vector
    HISTOGRAM=histogram               ; OUT: Histogram vector

    ; This is an external api and should not be HIDDEN
    COMPILE_OPT STRICTARR

    ON_ERROR, 2                     ;return to caller

    wBase = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, wBase, GET_UVALUE=state

    if ((ARG_PRESENT(alpha) ne 0) and (state.alphaInUse eq 1)) then begin
       state.oPolyline[3]->GetProperty, data=data
       alpha = reform(data[1,*])
    endif

    if ((ARG_PRESENT(histogram) ne 0) and $
        (state.histogramInUse eq 1)) then begin
       state.oPolylineHist->GetProperty, data=data
       histogram = reform(data[1,*])
    endif

    WIDGET_CONTROL, wBase, SET_UVALUE=state

end

FUNCTION CW_PALETTE_EDITOR, parent, $
        DATA=data, $
        FRAME = frame, $
        HISTOGRAM=histogram, $
        HORIZONTAL = horizontal, $
        SELECTION = selection, $
        UNAME = uname, $
        UVALUE = uvalue, $
        XSIZE = xsize, $
        YSIZE = ysize, $
        DEBUG = debug, $
        TAB_MODE = tab_mode

    ON_ERROR, 2                     ;return to caller
    ; Error handling. Needed to clean up any object or pointers.
    CATCH, error
    if (error ne 0) then begin
        CATCH, /CANCEL
        ; Clean up any created objects.
        if (N_ELEMENTS(paletteNoCleanup) gt 0) then begin
            if ((paletteNoCleanup eq 0) and OBJ_VALID(oPaletteMain)) then $
                OBJ_DESTROY, oPaletteMain
        endif
        if OBJ_VALID(oView) then OBJ_DESTROY, oView
        MESSAGE, !ERROR_STATE.MSG
        return, 0L
    endif

    if n_elements(frame) eq 0 then frame = 0
    if n_elements(histogram) le 0 then histogramInUse=0 else histogramInUse=1
    if n_elements(horizontal) eq 0 then horizontal = 0
    if n_elements(label) eq 0 then label = ''
    if (not keyword_set(uname)) then uname = 'CW_PALETTE_EDITOR_UNAME'
    ; n_elements test of palette done below
    if (n_elements(selection) eq 0) then begin
       sel_x1=0
       sel_x2=255
    endif else begin
       ndims = size(selection, /N_DIMENSIONS)
       dims =  size(selection, /DIMENSIONS)
       if ((ndims ne 1) or (dims[0] ne 2)) then $
          message, 'cw_palette_editor: SELECTION: Invalid argument'
       sel_x1=fix(selection[0] > 0)
       sel_x2=fix(selection[1] < 255)
    endelse
    ; n_elements test of uvalue done below
    if n_elements(xsize) eq 0 then xsize = 256
    if n_elements(ysize) eq 0 then ysize = 310
    ; minimum xsize and ysize is 150
    xsize = xsize > 150
    ysize = ysize > 150
    if n_elements(debug) eq 0 then debug = 0

    validData = cw_paledit_CheckData(data, $
                                     outPalette, $
                                     outPaletteSupplied, $
                                     outValues, $
                                     outAlphaInUse)

    colorVectors = fltarr(4,256)
    if (outPaletteSupplied eq 0) then begin
       paletteNoCleanup = 0L
       ; no palette object supplied, create new palette object
       if (validData le 0) then begin
          colorVectors[0,*] = bindgen(256)
          colorVectors[1,*] = colorVectors[0,*]
          colorVectors[2,*] = colorVectors[0,*]
          alphaInUse=0L
       endif else begin
          alphaInUse = outAlphaInUse
          colorVectors[0:2+alphaInUse, *] = outValues
       endelse
       oPaletteMain=OBJ_NEW('IDLgrPalette', $
          colorVectors[0,*], colorVectors[1,*], colorVectors[2,*])
       oPaletteMain->SetProperty, RED_VALUES=colorVectors[0,*], $
                                  GREEN_VALUES=colorVectors[1,*], $
                                  BLUE_VALUES=colorVectors[2,*]
    endif else begin
       paletteNoCleanup = 1L
       ; palette object supplied, use it internally, and don't clean it up
       ; extract its color vectors for use by polylines
       oPaletteMain = outPalette
       oPaletteMain->GetProperty, $
          RED_VALUES=aRed, GREEN_VALUES=aGreen, BLUE_VALUES=aBlue
       colorVectors[0,*] = aRed
       colorVectors[1,*] = aGreen
       colorVectors[2,*] = aBlue
       alphaInUse=0L
    endelse

    ; may want to check validity of parent here
    wCWPalEdTop=widget_base(parent, $
        /COLUMN, $
        FRAME=frame, $
        UNAME=uname, $
        FUNC_GET_VALUE = 'CW_PALEDIT_GETVALUE', $
        NOTIFY_REALIZE = 'CW_PALEDIT_INIT', $
        PRO_SET_VALUE  = 'CW_PALEDIT_SETVALUE')

    if n_elements(uvalue) gt 0 then $
       widget_control, wCWPalEdTop, set_uvalue=uvalue

    if ( n_elements(tab_mode) ne 0 ) then $
       widget_control, wCWPalEdTop, tab_mode = tab_mode

    ; cleanup must be done on the wCWPalEdMainBase widget which has
    ; the state in uval
    if horizontal then begin
       wCWPalEdMainBase = widget_base(wCWPalEdTop, $
          KILL_NOTIFY = 'CW_PALEDIT_CLEANUP', $
          /ROW, UNAME=uname+'_MAINBASE')
    endif else begin
       wCWPalEdMainBase = widget_base(wCWPalEdTop, $
          /COLUMN, UNAME=uname+'_MAINBASE', $
          KILL_NOTIFY = 'CW_PALEDIT_CLEANUP')
    endelse

    drawbase=widget_base(wCWPalEdMainBase, /column, UNAME=uname+'_DRAWBASE')
    cntrlbase=widget_base(wCWPalEdMainBase, /column, UNAME=uname+'_CNTRLBASE')

    wDraw=widget_draw(drawbase, graphics=2, $
       /button_events, $
       EVENT_FUNC='cw_paledit_DrawHandler', $
       /motion_events, $
       /app_scroll, $
       retain=0, $
       UVALUE = wCWPalEdMainBase, $
       x_scroll=xsize, $
       y_scroll=ysize, $
       xsize=xsize, $
       ysize=ysize, $
       UNAME=uname+'_WDRAW')

    wStatus=widget_text(drawbase, $
       val='', $
       scr_xsize=xsize, $
       ysize=2, $
       UNAME=uname+'_WSTATUS')

    zmpos_bm = $
           [['00'xb, '00'xb], $
            ['00'xb, '00'xb], $
            ['F0'xb, '01'xb], $
            ['08'xb, '02'xb], $
            ['44'xb, '04'xb], $
            ['44'xb, '04'xb], $
            ['F4'xb, '05'xb], $
            ['44'xb, '04'xb], $
            ['44'xb, '04'xb], $
            ['08'xb, '06'xb], $
            ['F0'xb, '0F'xb], $
            ['00'xb, '1C'xb], $
            ['00'xb, '38'xb], $
            ['00'xb, '70'xb], $
            ['00'xb, '60'xb], $
            ['00'xb, '00'xb]]

    zmneg_bm = $
           [['00'xb, '00'xb], $
            ['00'xb, '00'xb], $
            ['F0'xb, '01'xb], $
            ['08'xb, '02'xb], $
            ['04'xb, '04'xb], $
            ['04'xb, '04'xb], $
            ['E4'xb, '04'xb], $
            ['04'xb, '04'xb], $
            ['04'xb, '04'xb], $
            ['08'xb, '06'xb], $
            ['F0'xb, '0F'xb], $
            ['00'xb, '1C'xb], $
            ['00'xb, '38'xb], $
            ['00'xb, '70'xb], $
            ['00'xb, '60'xb], $
            ['00'xb, '00'xb]]


    zm1to1_bm_old = $
            [[000B, 000B], $
             [000B, 000B], $
             [000B, 000B], $
             [012B, 012B], $
             [014B, 014B], $
             [012B, 012B], $
             [204B, 012B], $
             [204B, 012B], $
             [012B, 012B], $
             [012B, 012B], $
             [204B, 012B], $
             [204B, 012B], $
             [012B, 012B], $
             [030B, 030B], $
             [000B, 000B], $
             [000B, 000B]]

    zmsel_bm_old = $
            [[255B, 255B], $
             [255B, 255B], $
             [193B, 193B], $
             [227B, 227B], $
             [247B, 247B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [007B, 240B], $
             [255B, 255B], $
             [255B, 255B]]

    zm1to1_bm = $
            [['00'xb, '00'xb], $
             ['00'xb, '00'xb], $
             ['00'xb, '00'xb], $
             ['0c'xb, '0c'xb], $
             ['0e'xb, '0e'xb], $
             ['0c'xb, '0c'xb], $
             ['cc'xb, '0c'xb], $
             ['cc'xb, '0c'xb], $
             ['0c'xb, '0c'xb], $
             ['0c'xb, '0c'xb], $
             ['cc'xb, '0c'xb], $
             ['cc'xb, '0c'xb], $
             ['0c'xb, '0c'xb], $
             ['1e'xb, '1e'xb], $
             ['00'xb, '00'xb], $
             ['00'xb, '00'xb]]


    zmsel_bm = $
            [['ff'xb, 'ff'xb], $
             ['ff'xb, 'ff'xb], $
             ['c1'xb, 'c1'xb], $
             ['e3'xb, 'e3'xb], $
             ['f7'xb, 'f7'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['07'xb, 'f0'xb], $
             ['ff'xb, 'ff'xb], $
             ['ff'xb, 'ff'xb]]


    zoomrow = widget_base(cntrlbase, $
       EVENT_PRO = 'CW_PALEDIT_ZOOMBUTTONHANDLER', $
       UVALUE=wCWPalEdMainBase, $
       /ROW, UNAME=uname+'_ZOOMROW')
    zoomlbl = Widget_label(zoomrow, $
       /ALIGN_BOTTOM, $
       value='Zoom: ', $
       UNAME=uname+'_ZOOMLBL')
    wButton = Widget_Button(zoomrow, $
       /ALIGN_BOTTOM, $
       UVALUE='ZOOM_SEL', $
       VALUE=zmsel_bm, $
       UNAME=uname+'_ZOOM_SEL')
    wButton = Widget_Button(zoomrow, $
       /ALIGN_BOTTOM, $
       UVALUE='ZOOM_IN', $
       VALUE=zmpos_bm, $
       UNAME=uname+'_ZOOM_IN')
    wButton = Widget_Button(zoomrow, $
       /ALIGN_BOTTOM, $
       UVALUE='ZOOM_OUT', $
       VALUE=zmneg_bm, $
       UNAME=uname+'ZOOM_OUT')
    wButton = Widget_Button(zoomrow, $
       /ALIGN_BOTTOM, $
       UVALUE='ZOOM_1TO1', $
       VALUE=zm1to1_bm, $
       UNAME=uname+'_ZOOM_1TO1')

    case !version.os_family of
        'MacOS': $
           value = [ $
              'Red Green Blue', $
              'Hue Saturation Value', $
              'Hue Lightness Saturation' $
              ]
        'Windows': $
            value = [ $
              'Red Green Blue', $
              'Hue Saturation Value', $
              'Hue Lightness Saturation' $
              ]
        else: $
            value = [ $
              'RGB', $
              'HSV', $
              'HLS' $
              ]
    endcase

    wColorSpace = Widget_Droplist(cntrlbase, $
       EVENT_PRO='cw_paledit_ColorSpaceHandler', $
       UVALUE=wCWPalEdMainBase, $
       VALUE=value, $
       TITLE='Color Space' ,$
       UNAME=uname+'_COLORSPACE')

    wEditMode = Widget_Droplist(cntrlbase, $
       TITLE='Edit Mode', $
       EVENT_PRO='cw_paledit_EditModeHandler', $
       UVALUE=wCWPalEdMainBase, $
       VALUE=[ 'Freehand', 'Line Segment', $
          'Barrel Shift', 'Slide', 'Stretch'], $
       UNAME=uname+'_EDITMODE')

    operaterow = widget_base(cntrlbase, $
       EVENT_FUNC = 'CW_PALEDIT_OPERATEBUTTONHANDLER', $
       UVALUE=wCWPalEdMainBase, $
       COLUMN=3, $
       GRID=!version.os_family eq 'Windows', $
       UNAME=uname+'_OPERATEROW')

    wButtonRamp = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Ramp', $
       UNAME=uname+'_RAMP')
    wButtonSmooth = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Smooth', $
       UNAME=uname+'_SMOOTH')

    wButtonPosterize = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Posterize', $
       UNAME=uname+'_POSTERIZE')

    wButtonReverse = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Reverse', $
       UNAME=uname+'_REVERSE')

    wButtonInvert = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Invert', $
       UNAME=uname+'_INVERT')

    wButtonDuplicate = Widget_Button(operaterow, $
       UVALUE=wCWPalEdMainBase, $
       VALUE='Duplicate', $
       UNAME=uname+'_DUPLICATE')

   operaterow3 = widget_base(cntrlbase, $
       EVENT_FUNC = 'CW_PALEDIT_OPERATEBUTTONHANDLER', $
       UVALUE=wCWPalEdMainBase, $
       UNAME=uname+'_OPERATEROW3')

    LOADCT, GET_NAMES = paletteNames
    nNames = n_elements(paletteNames)

    if !version.arch eq 'alpha' && !version.os eq 'OSF' then $
       wComboboxPredefined = widget_droplist(operaterow3, $
          VALUE=['Load Predefined...', paletteNames], $
          UVALUE=wCWPalEdMainBase, $
          UNAME=uname+'_DROPLISTPREDEFINED') $
    else $
       wComboboxPredefined = widget_combobox(operaterow3, $
          VALUE=['Load Predefined...', paletteNames], $
          UVALUE=wCWPalEdMainBase, $
          UNAME=uname+'_DROPLISTPREDEFINED')

    ; individual layout of items
    wDisplayModifyBase = widget_base(cntrlbase, $
       EVENT_PRO='cw_paledit_DisplayModifyButtonHandler', $
       COLUMN=4, $
       SPACE=1, $
       XPAD=1, $
       YPAD=1, $
       UNAME=uname+'_DISPLAYMODIFY')

    wLabelRed = Widget_label(wDisplayModifyBase, value=' R', /ALIGN_LEFT)
    base = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wDisplayRed = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_DISPLAYRED')
    wBase = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wModifyRed = widget_button(wBase, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_MODIFYRED')

    wLabelGreen = Widget_label(wDisplayModifyBase, value=' G', /ALIGN_LEFT)
    base = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wDisplayGreen = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_DISPLAYGREEN')
    base = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wModifyGreen = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_MODIFYGREEN')

    wLabelBlue = Widget_label(wDisplayModifyBase, value=' B', /ALIGN_LEFT)
    base = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wDisplayBlue = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_DISPLAYBLUE')
    base = widget_base(wDisplayModifyBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wModifyBlue = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_MODIFYBLUE')

    lbl = Widget_label(wDisplayModifyBase, value=' A', /ALIGN_LEFT)
    wRowBase = widget_base(wDisplayModifyBase, /ROW, XPAD=0, YPAD=0)
    base = widget_base(wRowBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wDisplayAlpha = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_DISPLAYALPHA')
    void = widget_label(wRowBase, value=' Display')

    wRowBase =widget_base(wDisplayModifyBase, /ROW, XPAD=0, YPAD=0)
    base = widget_base(wRowBase, /nonexclusive, $
       SPACE=0, XPAD=0, YPAD=0)
    wModifyAlpha = widget_button(base, UVALUE = wCWPalEdMainBase, $
       value=!version.os_family eq 'unix' ? ' ' : '', $
       UNAME=uname+'_MODIFYALPHA')
    void = widget_label(wRowBase, value=' Modify')

    wChannelLabels = [wLabelRed, wLabelGreen, wLabelBlue]
    wDispModButtons = [wDisplayRed, wModifyRed, $
                       wDisplayGreen, wModifyGreen, $
                       wDisplayBlue, wModifyBlue, $
                       wDisplayAlpha, wModifyAlpha]

    displayModifySettings = [1, 1, 1, 1, 1, 1, alphaInUse, alphaInUse]
    for i=0, n_elements(wDispModButtons)-1 do begin
       widget_control, wDispModButtons[i], SET_BUTTON=displayModifySettings[i]
    endfor
    wDispModAlphaButtons = [wDisplayAlpha, wModifyAlpha]
    if (alphaInUse eq 0) then begin
       widget_control, wDisplayAlpha, SENSITIVE=0
       widget_control, wModifyAlpha, SENSITIVE=0
    endif

    ; Create a view.
    ; use hardcoded viewplane rect so data space is always
    ; 256x310 (additional y space for color bars)
    myview = [0,0,256,310]
    oView = OBJ_NEW('IDLgrView', $
       COLOR=[180,180,180], $
       ;PROJECTION=2, $
       EYE=4, $
       DIMENSIONS=[xsize, ysize], $
       VIEWPLANE_RECT=myview, $
       ZCLIP=[2.0,-2.0])

    ; Create the top level model.
    omTop = OBJ_NEW('IDLgrModel')

    colorbar = bindgen(256) # (bytarr(20)+1)
    oImageColBarRef = obj_new('IDLgrImage', $
       colorbar, $
       loc=[0,290])
    omTop->Add,oImageColBarRef

    oImageColBarMain = obj_new('IDLgrImage', $
       colorbar, $
       palette=oPaletteMain, $
       loc=[0,266])
    omTop->Add,oImageColBarMain

    ;create polyline objects
    x=indgen(256)
    oPolylineRed = OBJ_NEW('IDLgrPolyline',x, colorVectors[0,*], $
       color=[200,0,0])
    oPolylineGreen = OBJ_NEW('IDLgrPolyline',x, colorVectors[1,*], $
       color=[0,200,0])
    oPolylineBlue = OBJ_NEW('IDLgrPolyline',x, colorVectors[2,*], $
       color=[0,0,200])
    oPolylineAlpha = OBJ_NEW('IDLgrPolyline',x, colorVectors[3,*], $
       color=[100,0,100], $
       HIDE=(alphaInUse eq 0))
    oPolyline = [oPolylineRed, oPolylineGreen, oPolylineBlue, oPolylineAlpha]

    if (histogramInUse eq 0) then histogram=x   ; dummy value
    oPolylineHist = OBJ_NEW('IDLgrPolyline',x, histogram, color=[0,150,150], $
                            HIDE=1-histogramInUse)

    omTop->Add,oPolylineRed
    omTop->Add,oPolylineGreen
    omTop->Add,oPolylineBlue
    ; always add alpha since a set_value statement may add it after init
    omTop->Add,oPolylineAlpha
    omTop->Add,oPolylineHist

    ; create polygon object for selection rectangle
    oPolygonSelection = OBJ_NEW('IDLgrPolygon', color=[255,255,255])

    omTop->Add,oPolygonSelection

    ; create polygon object for selection drag handles
    oPolygonDragLeft = OBJ_NEW('IDLgrPolygon', $
       style=2, $
       color=[240,240,0])
    oPolygonDragRight = OBJ_NEW('IDLgrPolygon', $
       style=2, $
       color=[240,240,0])


    omTop->Add,oPolygonDragLeft
    omTop->Add,oPolygonDragRight

    ; Add the model tree to the view.
    oView->Add, omTop

    ;;;state = { CW_PALEDIT_STATE, $
    state = {  $
       ; parameters
       colorVectors: colorVectors, $
       colorVectorsTemp: colorVectors, $
       debug: debug, $

       ; widgets
       wCWPalEdTop: wCWPalEdTop, $
       wDraw: wDraw, $
       wStatus: wStatus, $
       xsize: xsize, $
       ysize: ysize, $

       wChannelLabels: wChannelLabels, $
       wDispModButtons: wDispModButtons, $
       wDispModAlphaButtons: wDispModAlphaButtons, $

       wButtonRamp: wButtonRamp, $
       wButtonSmooth: wButtonSmooth, $
       wComboboxPredefined: wComboboxPredefined, $
       wButtonReverse: wButtonReverse, $
       wButtonInvert: wButtonInvert, $
       wButtonPosterize: wButtonPosterize, $
       wButtonDuplicate: wButtonDuplicate, $

       ; objects
       omTop: omTop, $
       oImageColBarMain: oImageColBarMain, $
       oPaletteMain: oPaletteMain, $
       oPolyline:oPolyline, $
       oPolylineHist: oPolylineHist, $
       oPolygonSelection: oPolygonSelection, $
       oPolygonDragLeft: oPolygonDragLeft, $
       oPolygonDragRight: oPolygonDragRight, $
       oWindow: OBJ_NEW(), $
       oView: oView, $

       ; configuration values
       alphaInUse: alphaInUse, $
       buttonDownDragArea: 0L, $
       buttonDownEditArea: 0L, $
       colorSpace: 0L, $          ; default is 0 for RGB
       displayModifySettings: displayModifySettings, $
       editMode: 0L, $            ; default is freehand
       handle_in_use: 0L, $
       histogramInUse: histogramInUse, $
       lastModX: -1L, $
       lastModY: -1L, $
       paletteNoCleanup: paletteNoCleanup, $
       sel_x1: sel_x1, $
       sel_x2: sel_x2 $

       }

    widget_control,wCWPalEdMainBase,set_uvalue=state

    return, wCWPalEdTop

end


