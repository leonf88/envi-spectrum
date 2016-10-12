; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituibrowser.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIBrowser
;
; PURPOSE:
;   This function implements the user interface for a simple Browser
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIBrowser(Requester [, UVALUE=uvalue])
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIBrowser, oUI, oRequester


  compile_opt idl2, hidden

  ;; Retrieve widget ID of top-level base.
  oUI->GetProperty, GROUP_LEADER=groupLeader

  oRequester->GetProperty, target=target,  name=name

  ;; Most of these names will end in ... Trim that off
  iPos = strpos(name, "...",/reverse_search)

  if(iPos gt -1)then $
    name = strmid(name, 0,iPos) 
  IDLitwdBrowser, oUI, GROUP_LEADER=groupLeader, $
                       TITLE=name, $
                       NAME=name, $
                       IDENTIFIER=target

  return, 1

end

