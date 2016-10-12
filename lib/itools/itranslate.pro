; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/itranslate.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iTranslate
;
; PURPOSE:
;   Translates an object in the iTools
;
; CALLING SEQUENCE:
;   iTranslate, ID, X, Y, Z
;
; INPUTS:
;   ID - The identifier of the object to translate
;   
;   X,Y,Z - The number of units to translate the object 
;
; KEYWORD PARAMETERS:
;   RESET - If set, reset the translation to zero before performing any 
;           translations supplied via X, Y or Z.
;
;   X,Y,Z - The number of units to translate the object in X, Y or Z 
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iTranslate, IDin, xIn, yIn, zIn, $
                DATA=dataIn, $
                NORMAL=normalIn, $
                DEVICE=deviceIn, $
                RESET=resetIn, $
                TOOL=toolIDin, $
                X=xIn2, $
                Y=yIn2, $
                Z=zIn2, $
                _EXTRA=_extra 
  compile_opt hidden, idl2

ON_ERROR, 2

  catch, iErr
  if (iErr ne 0) then begin
    catch, /cancel
    message, 'Unable to translate' 
    return
  endif

  ;; ID is required
  if (N_ELEMENTS(IDin) eq 0) then begin
    catch, /cancel
    message, 'An identifier must be supplied'
    return
  endif
  if (SIZE(IDin, /TYPE) ne 7) then begin
    catch, /cancel
    message, 'The identifier must be a string'
    return
  endif
  ;; If an array of IDs was passed in then treat them as full IDs
  if (N_ELEMENTS(IDin) gt 1) then begin
    ;; Sort IDs to clump IDs within a tool together
    fullID = IDin[SORT(IDin)]
  endif else begin
    fullID = iGetID(IDin, TOOL=tool)
    if (fullID[0] eq '') then begin
      catch, /cancel
      message, 'Identifier not found: '+IDin
      return
    endif
  endelse

  x = (N_ELEMENTS(xIn2) ne 0) ? DOUBLE(xIn2[0]) : $
       ((N_ELEMENTS(xIn) ne 0) ? DOUBLE(xIn[0]) : 0.0)
  y = (N_ELEMENTS(yIn2) ne 0) ? DOUBLE(yIn2[0]) : $
       ((N_ELEMENTS(yIn) ne 0) ? DOUBLE(yIn[0]) : 0.0)
  z = (N_ELEMENTS(zIn2) ne 0) ? DOUBLE(zIn2[0]) : $
       ((N_ELEMENTS(zIn) ne 0) ? DOUBLE(zIn[0]) : 0.0)
       
  if (~KEYWORD_SET(resetIn) && (x eq 0.0d) && (y eq 0.0d) && $
      (z eq 0.0d)) then return

  ;; Device is default
  if (~KEYWORD_SET(dataIn) && ~KEYWORD_SET(normalIn)) then $
    if (N_ELEMENTS(deviceIn) eq 0) then $
      deviceIn = 1b
    
  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  ;; Verify all identifiers
  for i=0,N_ELEMENTS(fullID)-1 do begin
    oObj = oSystem->GetByIdentifier(fullID[i])
    if (~OBJ_VALID(oObj)) then begin
      message, 'Identifier not found: '+fullID[i]
      return
    endif
  endfor

  oPrevTool = OBJ_NEW()
  
  for i=0,N_ELEMENTS(fullID)-1 do begin
    catch, iErr
    if (iErr ne 0) then begin
      continue
    endif

    oObj = oSystem->GetByIdentifier(fullID[i])
    if (~OBJ_VALID(oObj)) then continue
    
    ;; Get the tool
    oTool = oObj->GetTool()

    if (oTool ne oPrevTool) then begin
      ;; The tool has changed, commit the previous actions
      if (N_ELEMENTS(oCmds) ne 0) then begin
        oPrevTool->_TransactCommand, oCmds
        ;; Erase previous commands from list
        void = TEMPORARY(oCmds)
      endif
      oPrevTool = oTool
    endif

    ;; Get the set property operation
    oOperation = oTool->GetService("SET_PROPERTY")

    ;; Only items in the annotation layer, or certain annotations in the
    ;; data space can be operated on individually.  All others must exist in
    ;; a data space, which will be the thing on which the operation will be
    ;; performed.
    pos = STRPOS(fullID, 'ANNOTATION LAYER')
    if (pos[0] eq -1) then begin
      ;; Is the object one of the allowable types?
      allow = 0b
      allow or= OBJ_ISA(oObj, 'IDLitVisText')
      allow or= OBJ_ISA(oObj, 'IDLitVisPolyline')
      allow or= OBJ_ISA(oObj, 'IDLitVisPolygon')
      allow or= OBJ_ISA(oObj, 'IDLitVisLegend')
      if (~allow) then begin
        ;; Get dataspace
        if (OBJ_HASMETHOD(oObj, 'GetDataSpace')) then begin
          oDS = oObj->GetDataSpace()
        endif else begin
          ;; The view does not have a getdataspace method
          if (OBJ_ISA(oObj, 'IDLitgrView')) then begin
            dsID = (oObj->FindIdentifiers('*DATA SPACE*'))[0]
          endif else begin
            ;; Fall back to finding first data space in the window
            oWin = oTool->GetCurrentWindow()
            dsID = oWin->FindIdentifiers('*Data Space')
          endelse
          oDS = oSystem->GetByIdentifier(dsID)
        endelse
        if (~OBJ_VALID(oDS)) then message
        ;; Act on the dataspace
        oObj = oDS
      endif
    endif

    ;; Operate on the proper target
    oObj = oObj->GetManipulatorTarget()

    ;; Determine proper conversion type
    toNormal = OBJ_ISA(oObj, 'IDLitVisNormDataSpace') 
    toVisLayer = (STRPOS(fullID[i], 'ANNOTATION LAYER') eq -1) && (~toNormal)

    ;; Convert the points
    xyzStart = iConvertCoord(0, 0, 0, TO_ANNOTATION_DATA=(~toVisLayer), $
                             TO_DATA=toVisLayer, TO_NORMAL=toNormal, $
                             NORMAL=normalIn, DATA=dataIn, $
                             DEVICE=deviceIn, TARGET_IDENTIFIER=fullID[i], $
                             TOOL=toolIDin, _EXTRA=_extra)
    xyzEnd = iConvertCoord(x, y, z, TO_ANNOTATION_DATA=(~toVisLayer), $
                           TO_DATA=toVisLayer, TO_NORMAL=toNormal, $
                           NORMAL=normalIn, DATA=dataIn, $
                           DEVICE=deviceIn, TARGET_IDENTIFIER=fullID[i], $
                           TOOL=toolIDin, _EXTRA=_extra)
    ;; Calculate offset
    xx = xyzEnd[0] - xyzStart[0]
    yy = xyzEnd[1] - xyzStart[1]
    zz = xyzEnd[2] - xyzStart[2]

    ;; If using normal coordinates in a visualization adjust the values to
    ;; account for differences used internally by the ::Translate method
    if (toNormal && (STRPOS(fullID[i], 'ANNOTATION LAYER') eq -1)) then begin
      xx *= 2
      yy *= 2
      zz *= 2
    endif

    ;; Adjust for device coordinate internal translation mismatch if 
    ;; window aspect ratio is not 1
    ;; Be sure to account for window zoom
    oWin = oTool->GetCurrentWindow()
    oWin->GetProperty, CURRENT_ZOOM=curZoom
    xx /= curZoom
    yy /= curZoom
    
  ; If we are a dataspace, we need to adjust for the view aspect ratio.
  ; If we are an object *inside* a dataspace, the dataspace already
  ; handles the adjustment.
  if (OBJ_ISA(oObj, 'IDLitVisNormDataSpace')) then begin
    ;; If the view is not the same size as the window then adjustments
    ;; must be made

    ;; Get view
    pos1 = STRPOS(fullID[i], 'VIEW')
    if (pos1 ne -1) then begin
      pos2 = STRPOS(fullID[i], '/', pos1)
      if (pos2 ne -1) then begin
        viewID = STRMID(fullID[i], 0, pos2)
      endif else begin
        viewID = fullID[i]
      endelse 
      oView = oTool->GetByIdentifier(viewID)
    endif
    ;; If the ID'ed item did not include a view then try elsewhere
    if (~OBJ_VALID(oView)) then begin
      oView = oWin->GetCurrentView()
    endif

    oView->GetProperty, VIRTUAL_DIMENSIONS=viewDims
    visViewportDims = oView->GetViewport(/VIRTUAL)
    xx *= (visViewportDims[0]/viewDims[0])
    yy *= (visViewportDims[1]/viewDims[1])
    if (viewDims[0] gt viewDims[1]) then $
      xx *= (viewDims[0]/viewDims[1])
    if (viewDims[1] gt viewDims[0]) then $
      yy *= (viewDims[1]/viewDims[0])
  endif

    ;; Until IDL is running on holographic displays, translating Z units in
    ;; device coordinates make no sense.
    if (KEYWORD_SET(deviceIn)) then $
      zz[*] = 0.0d

    ; Create our undo/redo command set, and record the initial values.
    oCmd = OBJ_NEW("IDLitCommandSet", NAME='Translate', $
      OPERATION_IDENTIFIER=oOperation->GetFullIdentifier())
    iStatus = oOperation->RecordInitialValues(oCmd, oObj, 'TRANSFORM')
    if (~iStatus) then begin
      OBJ_DESTROY, oCmd
      message
    endif
    
    if (KEYWORD_SET(resetIn)) then begin
      oObj->GetProperty, TRANSFORM=tr
      tr[3, 0:2] = 0.0
      oObj->SetProperty, TRANSFORM=tr
    endif

    oObj->_IDLitVisualization::Translate, xx, yy, zz, _EXTRA=_extra
  
    ; Record the final values and return.
    iStatus = oOperation->RecordFinalValues(oCmd, oObj, 'TRANSFORM', $
                                            /SKIP_MACROHISTORY)
    if (~iStatus) then begin
      OBJ_DESTROY, oCmd
      message
    endif

    oCmds = N_ELEMENTS(oCmds) eq 0 ? oCmd : [oCmds, oCmd]

    ;; Cache the tool for refreshing
    oTools = N_ELEMENTS(oTools) eq 0 ? oTool : [oTools, oTool]

  endfor
  ;; Commit last set of actions
  if (N_ELEMENTS(oCmds) ne 0) then $
    oTool->_TransactCommand, oCmds
  
  ;; Remove redundancies
  if (N_ELEMENTS(oTools) ne 0) then begin
    oTools = oTools[UNIQ(oTools)]
    ;; Refresh tool windows
    for i=0,N_ELEMENTS(oTools)-1 do $
      if (OBJ_VALID(oTools[i])) then $
        oTools[i]->RefreshCurrentWindow
  endif else begin
    catch, /cancel
    message, 'Unable to translate' 
    return
  endelse

end
