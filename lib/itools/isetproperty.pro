; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/isetproperty.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iSetProperty
;
; PURPOSE:
;   Set properties on a given iTools object
;
; CALLING SEQUENCE:
;   iSetProperty, ID, PROPERTY=value
;
; INPUTS:
;   ID - An identifier to an iTools object
;
; KEYWORD PARAMETERS:
;   All keywords are passed to the iTools object
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iSetProperty, IDin, TOOL=tool, _EXTRA=_extra
  compile_opt hidden, idl2

on_error,2

  ;; If an array of IDs was passed in then treat them as full IDs
  if (N_ELEMENTS(IDin) gt 1) then begin
    ;; Sort IDs to clump IDs within a tool together
    fullID = IDin[SORT(IDin)]
  endif else begin
    fullID = iGetID(IDin, TOOL=tool)
    if (fullID[0] eq '') then begin
      message, 'Identifier not found: '+IDin
      return
    endif
  endelse
  
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

  catch, iErr
  if(iErr ne 0)then begin
    catch, /cancel
    message, 'Unable to set property' 
    return
  endif

  propNames = TAG_NAMES(_extra)
  oPrevTool = OBJ_NEW()
  msgFlag = 0b
  
  for i=0,N_ELEMENTS(fullID)-1 do begin
    oObj = oSystem->GetByIdentifier(fullID[i])
    
    catch, iErr
    if (iErr ne 0) then begin
      continue
    endif

    ;; Get the tool
    oTool = oObj->GetTool()
    ;; Get the set property operation
    oProperty = oTool->GetService("SET_PROPERTY")
    
    if (oTool ne oPrevTool) then begin
      ;; The tool has changed, commit the previous actions
      if (N_ELEMENTS(oCmds) ne 0) then begin
        oPrevTool->_TransactCommand, oCmds
        ;; Erase previous commands from list
        void = TEMPORARY(oCmds)
      endif
      oPrevTool = oTool
    endif
  
    ;; Use the set property service to generate commands
    for j=0,N_ELEMENTS(propNames)-1 do begin
      catch, err
      if (err eq 0) then begin 
        message, /RESET
        oCmd = oProperty->DoAction(oTool, fullID[i], propNames[j], _extra.(j))
        oCmds = N_ELEMENTS(oCmds) eq 0 ? oCmd : [oCmds, oCmd]
      endif else begin
        catch, /cancel
        message, 'Unable to set property on '+fullID[i], /INFORMATIONAL
        msg = !error_state.msg
        ;; Strip off beginning part when appropriate
        if (STRUPCASE(STRMID(msg, 0, 8) eq STRMID(msg, 0, 8))) then begin
          space = STRPOS(msg, ' ')
          if (space ne -1) then $
            msg = STRMID(msg, space+1)
        endif
        message, '  '+msg, /INFORMATIONAL, /NONAME
        msgFlag = 1b
      endelse
    endfor
    
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
    if (~msgFlag) then $
      message, 'Unable to set property' 
    return
  endelse

end
