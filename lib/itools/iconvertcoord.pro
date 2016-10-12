; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iconvertcoord.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iConvertCoord
;
; PURPOSE:
;   Converts coordinate systems in the iTools
;
; CALLING SEQUENCE:
;   xyz = iConvertCoord(X, Y, Z 
;                       [, /DATA | , /DEVICE | , /NORMAL] 
;                       [, /TO_DATA | , /TO_DEVICE | , /TO_NORMAL] 
;                       [, TARGET_IDENTIFIER=ID] [, TOOL=toolID]) 
;
; INPUTS:
;   X - A vector or scalar argument providing the X components of the input
;       coordinates. If only one argument is specified, X must be an array
;       of either two or three vectors (i.e., [2,*] or [3,*]). In this
;       special case, X[0,*] are taken as the X values, X[1,*] are taken as
;       the Y values, and, if present, X[2,*] are taken as the Z values. 
;
;   Y - An optional argument providing the Y input coordinate(s)
;
;   Z - An optional argument providing the Z input coordinate(s)
;   
; KEYWORD PARAMETERS:
;   DATA - Set this keyword if the input coordinates are in data space
;   
;   DEVICE - Set this keyword if the input coordinates are in device space
;   
;   NORMAL - Set this keyword if the input coordinates are in normalized
;            [0, 1] space (the default)
;
;   TO_DATA - Set this keyword if the output coordinates are to be in data
;             space
;
;   TO_DEVICE - Set this keyword if the output coordinates are to be in
;               device space
;
;   TO_NORMAL - Set this keyword if the output coordinates are to be in
;               normalized [0, 1] space (the default)
;               
;   TARGET_IDENTIFIER - The identifier of the object that is contained in the
;                       desired data space.  If not supplied the first data
;                       space in the first view will be used.
;
;   TOOL - The identifer of the tool in which TARGET_IDENTIFIER is found.  If
;          not supplied the current tool will be used.
;          
; RETURN:
;   A [3xN] vector containing the [x,y,z] components of the output coordinates
;   
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Aug 2008
;
;-

;-------------------------------------------------------------------------
FUNCTION iConvertCoord, Xin, Yin, Zin, $
                        TARGET_IDENTIFIER=ID, $
                        TOOL=toolIDin, $
                        ANNOTATION_DATA=annoIn, $
                        DATA=dataIn, $
                        DEVICE=deviceIn, $
                        NORMAL=normalIn, $
                        TRANSFORMED_DATA=transDataIn, $
                        TO_ANNOTATION_DATA=toAnnoIn, $
                        TO_DATA=toDataIn, $
                        TO_DEVICE=toDeviceIn, $
                        TO_NORMAL=toNormalIn, $
                        _EXTRA=_extra 
  compile_opt hidden, idl2

ON_ERROR, 2

  catch, iErr
  if (iErr ne 0) then begin
    catch, /CANCEL
    message, 'Unable to convert coordinates' 
    return, -1
  endif

  case (N_PARAMS()) of
    1 : begin
      n_dims = SIZE(Xin, /N_DIMENSIONS)
      ;; Vector of 2 or 3 elements
      if (n_dims eq 1) then begin
        switch N_ELEMENTS(Xin) of
          3 : Z = Xin[2]
          2 : begin
            Y = Xin[1]
            X = Xin[0]
            if (N_ELEMENTS(Z) eq 0) then Z = 0.0
          end
          else :
        endswitch
      endif
      if (n_dims eq 2) then begin
        dms = SIZE(Xin, /DIMENSIONS)
        ;; [2xM] array
        if (dms[0] eq 2) then begin
          X = Xin[0,*]
          Y = Xin[1,*]
          Z = REPLICATE(0.0, N_ELEMENTS(X))
        endif
        ;; [3xM] array 
        if (dms[0] eq 3) then begin
          X = Xin[0,*]
          Y = Xin[1,*]
          Z = Xin[2,*]
        endif
      endif
    end
    2 : begin
      if (N_ELEMENTS(Xin) ne N_ELEMENTS(Yin)) then break
      X = Xin[*]
      Y = Yin[*]
      Z = REPLICATE(0.0, N_ELEMENTS(X))
    end
    3 : begin
      if ((N_ELEMENTS(Xin) ne N_ELEMENTS(Yin)) || $
          (N_ELEMENTS(Xin) ne N_ELEMENTS(Zin))) then break
      X = Xin[*]
      Y = Yin[*]
      Z = Zin[*]
    end
    else :
  endcase
  
  if (N_ELEMENTS(Z) eq 0) then begin
    catch, /CANCEL
    message, 'Incorrect input data'
    return, -1
  endif

  ;; Remove array dims of 1
  X = DOUBLE(REFORM(X))
  Y = DOUBLE(REFORM(Y))
  Z = DOUBLE(REFORM(Z))
  
  ;; Determine to and from
  convTo = KEYWORD_SET(toNormalIn) ? 'normal' : $
             (KEYWORD_SET(toDataIn) ? 'data' : $
               (KEYWORD_SET(toDeviceIn) ? 'device' : $
                 (KEYWORD_SET(toAnnoIn) ? 'annoData' : 'normal')))
  convFrom = KEYWORD_SET(normalIn) ? 'normal' : $
               (KEYWORD_SET(dataIn) ? 'data' : $
                 (KEYWORD_SET(annoIn) ? 'annoData' : $
                   (KEYWORD_SET(deviceIn) ? 'device' : $
                     (KEYWORD_SET(transDataIn) ? 'trData' : 'normal'))))

  if (convTo eq convFrom) then begin
    ; Z coordinates do not make sence in device space
    if ((convTo eq 'device') || (convFrom eq 'device')) then $
      Z *= 0
    return, TRANSPOSE([[REFORM(X)],[REFORM(Y)],[REFORM(Z)]])
  endif
  
  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then begin
    catch, /CANCEL
    message, 'iTools system not available'
    return, -1
  endif

  ;; Set up parameters and get tool
  fullID = (iGetID(ID, TOOL=toolIDin))[0]
  if (fullID ne '') then begin
    oObj = oSystem->GetByIdentifier(fullID)
    oTool = oObj->GetTool()
  endif else begin
    toolID = (N_ELEMENTS(toolIDin) eq 0) ? $
             iGetCurrent() : (iGetID(TOOL=toolIDin))[0]
    oTool = oSystem->GetByIdentifier(toolID[0])
  endelse
  if (~OBJ_VALID(oTool)) then begin
    catch, /CANCEL
    message, 'No valid iTool found'
    return, -1
  endif
  
  ;; Get window
  oWin = oTool->GetCurrentWindow()
  if (~OBJ_VALID(oWin)) then begin
    catch, /CANCEL
    message, 'Unable to obtain window'
    return, -1
  endif

  ;; Get view
  if (N_ELEMENTS(ID) ne 0) then begin
    pos1 = STRPOS(fullID, 'VIEW')
    if (pos1 ne -1) then begin
      pos2 = STRPOS(fullID, '/', pos1)
      if (pos2 ne -1) then begin
        viewID = STRMID(fullID, 0, pos2)
      endif else begin
        viewID = fullID
      endelse 
      oView = oTool->GetByIdentifier(viewID)
    endif
  endif 
    ;; If the ID'ed item did not include a view then try elsewhere
  if (~OBJ_VALID(oView)) then begin
    oView = oWin->GetCurrentView()
  endif
  if (~OBJ_VALID(oView)) then begin
    catch, /CANCEL
    message, 'Unable to obtain view'
    return, -1
  endif

  ;; Get dataspace
  if ((convTo eq 'data') || (convFrom eq 'data') || $
      (convFrom eq 'trData')) then begin
    ;; Get it from ID if one exists
    if (N_ELEMENTS(ID) ne 0) then begin
      pos1 = STRPOS(fullID, 'DATA SPACE')
      if (pos1 ne -1) then begin
        pos2 = STRPOS(fullID, '/', pos1)
        if (pos2 ne -1) then begin
          dsID = STRMID(fullID, 0, pos2)
        endif else begin
          dsID = fullID
        endelse 
        oDS = oTool->GetByIdentifier(dsID)
      endif
    endif
    ;; If the ID'ed item did not include a data space then try elsewhere
    if (~OBJ_VALID(oDS)) then begin
      ;; Get first data space
      dsID = (oView->FindIdentifiers('*DATA SPACE*'))[0]
      oDS = oTool->GetByIdentifier(dsID)
    endif
    if (~OBJ_VALID(oDS)) then begin
      catch, /CANCEL
      message, 'Data coordinate system not established'
      return, -1
    endif
    ;; Get any object contained in the data space; needed for conversions
    if (OBJ_VALID(oObj)) then begin
      oDSObjs = oDS->Get(/ALL)
      index = where(oObj eq oDSObjs, cnt)
      if (cnt ne 0) then $
        oDSObj = oObj
    endif
    if (~OBJ_VALID(oDSObj)) then $
      oDSObj = (oDS->Get())[0]
  endif

  ;; Get window and view dimensions and locations  
  oWin->GetProperty, DIMENSIONS=dims, VISIBLE_LOCATION=vLocation, $
                     VIRTUAL_WIDTH=vWidth, VIRTUAL_HEIGHT=vHeight, $
                     CURRENT_ZOOM=curZoom
  oView->GetProperty, CURRENT_ZOOM=viewZoom, VIRTUAL_DIMENSIONS=viewDims, $
                      VISIBLE_LOCATION=viewLoc
  ;; Handle case where view is larger than the window, but should not be
  if ((viewZoom le curZoom) && (total(viewDims gt dims) ne 0)) then begin
    newViewDims = viewDims
    newViewDims <= dims
    diff = viewDims - newViewDims
    viewLoc -= diff/2.
    viewDims = newViewDims
  endif
  
  visViewportDims = oView->GetViewport(LOCATION=viewportLoc, /VIRTUAL)
  halfVVDims = visViewportDims/2.0
  
  ;; Actually do the conversions

  if (convFrom eq 'annoData') then begin
    ;; Annotation Data to View Normal
    if (N_ELEMENTS(annoIn) eq 16) then begin
      ;; Get transformation matrix
      trans = annoIn
      ;; Apply transformation
      for i=0,N_ELEMENTS(X)-1 do begin
        point = [X[i], Y[i], Z[i], 1]
        newPoint = reform(point#trans)
        X[i] = newPoint[0]
        Y[i] = newPoint[1]
        Z[i] = newPoint[2]
      endfor
    endif
    ;; Convert from annotation data to virtual view normal
    X /= (viewDims[0] gt viewDims[1] ? $
          viewDims[0]/viewDims[1] : 1)
    Y /= (viewDims[1] gt viewDims[0] ? $
          viewDims[1]/viewDims[0] : 1)
    ;; Virtual view normal to virtual view device
    X = X*(viewDims[0]/2.) + (viewDims[0]/2.)
    Y = Y*(viewDims[1]/2.) + (viewDims[1]/2.)
    ;; Account for shifting of virtual view
    X -= viewLoc[0]
    Y -= viewLoc[1]
    ;; Account for window zoom
    X *= curZoom
    Y *= curZoom
    ;; Convert to view normal [0,1]
    X = X/visViewportDims[0]
    Y = Y/visViewportDims[1]
;Old way, convert to wide normal: [-1,1]
;    X = X/halfVVDims[0]-1.
;    Y = Y/halfVVDims[1]-1.
    ;; The next block will handle window zoom
    convFrom = 'normal'
  endif

  if ((convFrom eq 'trData') && (N_ELEMENTS(transDataIn) eq 16)) then begin
    ;; Transformed data to View Normal

    ;; Get transformation matrix
    trans = transDataIn
    ;; Apply transformation
    for i=0,N_ELEMENTS(X)-1 do begin
      point = [X[i], Y[i], Z[i], 1]
      newPoint = reform(point#trans)
      X[i] = newPoint[0]
      Y[i] = newPoint[1]
      Z[i] = newPoint[2]
    endfor
    
    ;; Data to Window Device
    oDSObj->VisToWindow, X, Y, Z, X, Y, Z
    X += vLocation[0]
    Y += vLocation[1]
  endif

  if (convFrom eq 'normal') then begin
    ;; View Normal [0,1] to Window Device
    X = X*visViewportDims[0] + viewportLoc[0]
    Y = Y*visViewportDims[1] + viewportLoc[1]
;Old way, convert from wide normal: [-1,1]
;    X = X*halfVVDims[0] + halfVVDims[0] + $
;        viewportLoc[0]
;    Y = Y*halfVVDims[1] + halfVVDims[1] + $
;        viewportLoc[1]
  endif

  if (convFrom eq 'data') then begin
    ;; Data to Window Device
    
    ;; Save Z values as the original values are needed for the VisToWindow call 
    Zorig = Z
    
    ;; Apply transformation directly for Z values
    ;; For some reason Z needs the full CTM, not using the window as the
    ;; destination object, which is what happens when using VisToWindow.
    trans = oDSObj->GetCTM()
    for i=0,N_ELEMENTS(X)-1 do begin
      point = [X[i], Y[i], Z[i], 1]

      newPoint = reform(point#trans)

      if (newPoint[3] ne 0.0) then $
        newPoint /= newPoint[3]

      Z[i] = newPoint[2]/2
    endfor

    ;; Call VisToWindow for X and Y values
    oDSObj->VisToWindow, X, Y, Zorig, X, Y, void
    ;; Adjust for window location
    X += vLocation[0]
    Y += vLocation[1]

  endif

  if (convTo eq 'normal') then begin
    ;; Window Device to View Normal [0,1]
    X = (X - viewportLoc[0]) / visViewportDims[0] 
    Y = (Y - viewportLoc[1]) / visViewportDims[1] 
;Old way, convert to wide normal: [-1,1]
;    X = (X - viewportLoc[0] - halfVVDims[0]) / halfVVDims[0] 
;    Y = (Y - viewportLoc[1] - halfVVDims[1]) / halfVVDims[1] 
  endif
  
  if (convTo eq 'data') then begin
    ;; Window Device to Data
    X -= vLocation[0]
    Y -= vLocation[1]
    oDSObj->WindowToVis, X, Y, Z, X, Y, Z
  endif

  if (convTo eq 'annoData') then begin
    ;; Window Device to Annotation Data
    ;; Account for window zoom
    X /= curZoom
    Y /= curZoom
    ;; Adjust for view location
    X += viewLoc[0]
    Y += viewLoc[1]
    ;; Adjust for virtual view location
    X -= viewportLoc[0]/curZoom
    Y -= viewportLoc[1]/curZoom
    ;; Convert to Annotation data
    minDims = min(viewDims)/2.0
    halfDims = viewDims/2.0
    X = (X - halfDims[0]) / minDims 
    Y = (Y - halfDims[1]) / minDims
  endif
  
  ; Z coordinates do not make sence in device space
  if ((convTo eq 'device') || (convFrom eq 'device')) then $
    Z *= 0

  return, TRANSPOSE([[REFORM(X)],[REFORM(Y)],[REFORM(Z)]])
  
end
