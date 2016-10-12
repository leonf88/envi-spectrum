; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/igetproperty.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iGetProperty
;
; PURPOSE:
;   Get properties from a given iTools object
;
; CALLING SEQUENCE:
;   iGetProperty, ID, PROPERTY=value
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
PRO iGetProperty, ID, TOOL=tool, _REGISTERED=registered, _REF_EXTRA=_extra
  compile_opt hidden, idl2

on_error, 2

  fullID = (iGetID(ID, TOOL=tool))[0]
  if (fullID eq '') then begin
    message, 'Identifier not found: '+ID
    return
  endif

  catch, iErr
  if(iErr ne 0)then begin
    catch, /cancel
    message, 'Unable to get property' 
    return
  endif

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  ;; Get the requested object
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  ;; Get the property
  oObj->GetProperty, _EXTRA=_extra
  
  ;; Get all registered properties
  if (ARG_PRESENT(registered)) then begin
    reg = oObj->QueryProperty()
    keep = bytarr(N_ELEMENTS(reg))
    for i=0,N_ELEMENTS(reg)-1 do begin
      oObj->GetPropertyAttribute, reg[i], HIDE=hidden, TYPE=type
      ;; Filter out hidden properties and USERDEFs
      keep[i] = ~hidden && (type ne 0)
    endfor
    if (total(keep) ne 0) then $
      registered = reg[where(keep)]
  endif
    
end
