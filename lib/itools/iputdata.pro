; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iputdata.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iPutData
;
; PURPOSE:
;   Sets data on a given iTools object
;
; CALLING SEQUENCE:
;   iPutData, ID, data1, data2, ...
;
; INPUTS:
;   ID - An identifier to an iTools object
;
;   ARGs - IDL variables to set on the object
;
; KEYWORD PARAMETERS:
;   NONE
;
; MODIFICATION HISTORY:
;   Written by: AGEH, RSI, Jun 2008
;
;-

;-------------------------------------------------------------------------
PRO iPutData, ID, arg1, arg2, arg3, arg4, arg5, arg6, arg7, $
              TOOL=tool, _EXTRA=_extra 
  compile_opt hidden, idl2

on_error, 2

  fullID = (iGetID(ID, TOOL=tool))[0]
  if (fullID[0] eq '') then begin
    message, 'Identifier not found: '+ID
    return
  endif

  catch, iErr
  if(iErr ne 0)then begin
    catch, /cancel
    message, 'Unable to set data: '+ID 
    return
  endif

  ;; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return

  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return
  
  case N_PARAMS() of
    1 : oObj->PutData, _EXTRA=_extra
    2 : oObj->PutData, arg1, _EXTRA=_extra
    3 : oObj->PutData, arg1, arg2, _EXTRA=_extra
    4 : oObj->PutData, arg1, arg2, arg3, _EXTRA=_extra
    5 : oObj->PutData, arg1, arg2, arg3, arg4, _EXTRA=_extra
    6 : oObj->PutData, arg1, arg2, arg3, arg4, arg5, _EXTRA=_extra
    7 : oObj->PutData, arg1, arg2, arg3, arg4, arg5, arg6, _EXTRA=_extra
    8 : oObj->PutData, arg1, arg2, arg3, arg4, arg5, arg6, arg7, _EXTRA=_extra
    else :
  endcase
  
end
