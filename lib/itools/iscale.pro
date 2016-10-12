; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iscale.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iScale
;
; PURPOSE:
;   Scales an object in the iTools
;
; CALLING SEQUENCE:
;   iScale, ID, X, Y, Z
;
; INPUTS:
;   ID - The identifier of the object to scale
;   
;   X,Y,Z - The factor used to scale the object 
;
; KEYWORD PARAMETERS:
;   RESET - If set, reset the scale factors to 1.0 before performing any 
;           scaling supplied via X,Y or Z.
;           
;   X,Y,Z - The factor used to scale the object in X, Y or Z 
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iScale, IDin, xIn, yIn, zIn, $
            RESET=resetIn, $
            TOOL=toolIDin, $
            X=xIn2, $
            Y=yIn2, $
            Z=zIn2, $
            _EXTRA=_extra 
  compile_opt hidden, idl2

ON_ERROR, 2

  ;; Handle bad inputs and catch errors
  ON_IOERROR, invalidInput
  catch, iErr
  if (iErr ne 0) then begin
    invalidInput:
    catch, /cancel
    message, 'Unable to scale' 
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
       ((N_ELEMENTS(xIn) ne 0) ? DOUBLE(xIn[0]) : 1.0d)
  y = (N_ELEMENTS(yIn2) ne 0) ? DOUBLE(yIn2[0]) : $
       ((N_ELEMENTS(yIn) ne 0) ? DOUBLE(yIn[0]) : 1.0d)
  z = (N_ELEMENTS(zIn2) ne 0) ? DOUBLE(zIn2[0]) : $
       ((N_ELEMENTS(zIn) ne 0) ? DOUBLE(zIn[0]) : 1.0d)
  ;; Enforce a small minimum scale factor
  minScale = 0.0001
  x >= minScale
  y >= minScale
  z >= minScale
       
  if (~KEYWORD_SET(resetIn) && (x eq 1.0d) && (y eq 1.0d) && $
      (z eq 1.0d)) then return

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

    ; Retrieve our SetProperty service.
    oOperation = oTool->GetService('SET_PROPERTY')
    if (not OBJ_VALID(oOperation)) then return

    ;; Only items in the annotation layer, or certain annotations in the
    ;; data space can be operated on individually.  All others must exist in
    ;; a data space, which will be the thing on which the operation will be
    ;; performed.
    pos = STRPOS(fullID, 'ANNOTATION LAYER')
    if (pos[0] eq -1) then begin
      ;; Is the object one of the allowable types?
      allow = 0b
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
    oCmd = OBJ_NEW("IDLitCommandSet", NAME='Scale', $
      OPERATION_IDENTIFIER=oOperation->GetFullIdentifier())
    iStatus = oOperation->RecordInitialValues(oCmd, oObj, 'TRANSFORM')
    if (~iStatus) then begin
      OBJ_DESTROY, oCmd
      message
    endif
  
    if (KEYWORD_SET(resetIn)) then begin
      oObj->GetProperty, TRANSFORM=currentTransform
      scale = REFORM((SQRT(TOTAL(currentTransform[0:2,0:2]^2,1)))[0:2])
      rotation = currentTransform[0:2,0:2] / ([1,1,1] # scale)
      currentTransform[0:2,0:2] = rotation
      oObj->SetProperty, TRANSFORM=currentTransform
    endif
  
    oObj->_IDLitVisualization::Scale, x, y, z, _EXTRA=_extra
  
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
