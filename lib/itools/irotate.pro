; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/irotate.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iRotate
;
; PURPOSE:
;   Rotates an object in the iTools
;
; CALLING SEQUENCE:
;   iRotate, ID, DEGREES
;
; INPUTS:
;   ID - The identifier of the object to rotate
;
;   DEGREES - The number of degress to rotate the object 
;
; KEYWORD PARAMETERS:
;   RESET - If set, reset the rotation transformation matrix before 
;           performing any rotations supplied via X,Y or Z.
;
;   XAXIS - If set, rotate around the X axis
;   
;   YAXIS - If set, rotate around the Y axis
;   
;   ZAXIS - If set, rotate around the Z axis (default)
;   
;   TOOL - The tool to use when finding ID.  If ID is a full identifier TOOL
;          is ignored.  If not supplied the current tool is used.
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iRotate, IDin, degreesIn, $
             RESET=resetIn, $
             DEFAULT=defaultIn, $
             TOOL=toolIDin, $
             XAXIS=xAxisIn, $
             YAXIS=yAxisIn, $
             ZAXIS=zAxisIn, $
             _EXTRA=_extra 
  compile_opt hidden, idl2

ON_ERROR, 2

  catch, iErr
  if (iErr ne 0) then begin
    catch, /cancel
    message, 'Unable to rotate' 
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
    fullID = iGetID(IDin, TOOL=toolIDin)
    if (fullID[0] eq '') then begin
      catch, /cancel
      message, 'Identifier not found: '+IDin
      return
    endif
  endelse

  ;; degrees is required
  if ((N_ELEMENTS(degreesIn) eq 0)) then begin
    if (~KEYWORD_SET(resetIn) && ~KEYWORD_SET(defaultIn)) then begin
      catch, /cancel
      message, 'Degrees must be supplied'
      return
    endif else begin
      degreesIn = 0.0
    endelse
  endif

  degrees = DOUBLE(degreesIn) mod 360
  
  if (~(KEYWORD_SET(resetIn) || KEYWORD_SET(defaultIn)) && $
      (degrees eq 0.0d)) then return

  axis = [KEYWORD_SET(xAxisIn), KEYWORD_SET(yAxisIn), $
          KEYWORD_SET(zAxisIn)]
  nAxes = TOTAL(axis)
  if (nAxes gt 1) then begin
    catch, /cancel
    message, 'Conflicting keywords: only one axis keyword may be specified'
    return
  endif
  ;; Z axis by default
  if (nAxes eq 0) then $
    axis = [0, 0, 1]
      
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
    if (not OBJ_VALID(oOperation)) then return

    ;; Only items in the annotation layer, or certain annotations in the
    ;; data space can be operated on individually.  All others must exist in
    ;; a data space, which will be the thing on which the operation will be
    ;; performed.
    pos = STRPOS(fullID, 'ANNOTATION LAYER')
    if (pos[0] eq -1) then begin
      ;; Is the object one of the allowable types?
      allow = 0b
      allow or= OBJ_ISA(oObj, 'IDLitVisText')
      allow or= OBJ_ISA(oObj, 'IDLitVisPolygon')
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
  
    ; Create our undo/redo command set, and record the initial values.
    oCmd = OBJ_NEW("IDLitCommandSet", NAME='Rotate', $
      OPERATION_IDENTIFIER=oOperation->GetFullIdentifier())
    iStatus = oOperation->RecordInitialValues(oCmd, oObj, 'TRANSFORM')
    if (~iStatus) then begin
      OBJ_DESTROY, oCmdSet
      message
    endif

    oObj->GetProperty, CENTER_OF_ROTATION=centerRotation, $
      TRANSFORM=currentTransform
      
    if (KEYWORD_SET(resetIn) || KEYWORD_SET(defaultIn)) then begin
      scale = REFORM((SQRT(TOTAL(currentTransform[0:2,0:2]^2,1)))[0:2])
      currentTransform[0:2,0:2] = [[scale[0],0,0], [0,scale[1],0], $
                                   [0,0,scale[2]]]
      oObj->SetProperty, TRANSFORM=currentTransform
      ;; If 3D then rotate back to default view
      if (KEYWORD_SET(defaultIn) && oObj->is3D()) then begin
        oObj->_IDLitVisualization::Rotate, [1, 0, 0], -90, $
          CENTER_OF_ROTATION=centerRotation, _EXTRA=_extra
        oObj->_IDLitVisualization::Rotate, [0, 1, 0], 30, $
          CENTER_OF_ROTATION=centerRotation, _EXTRA=_extra
        oObj->_IDLitVisualization::Rotate, [1, 0, 0], 30, $
          CENTER_OF_ROTATION=centerRotation, _EXTRA=_extra
      endif
    endif
      
    ;; Transform center of rotation by current transform
    if (degrees ne 0.0) then begin
      cr = [centerRotation, 1.0d] # currentTransform
      oObj->_IDLitVisualization::Rotate, axis, degrees, $
        CENTER_OF_ROTATION=cr, /PREMULTIPLY, _EXTRA=_extra
    endif
  
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
  oTool->_TransactCommand, oCmds
  
  ;; Remove redundancies
  oTools = oTools[UNIQ(oTools)]
  ;; Refresh tool windows
  for i=0,N_ELEMENTS(oTools)-1 do $
    if (OBJ_VALID(oTools[i])) then $
      oTools[i]->RefreshCurrentWindow
  
end
