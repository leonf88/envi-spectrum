; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiclexport.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiCLExport
;
; PURPOSE:
;   This function implements the user interface for export of
;   variables to the IDL command line for the IDL iTool. The Result is
;   a success flag, either 0 or 1. 
;
; CALLING SEQUENCE:
;   Result = IDLituiCLExport(oUI, Requester)
;
; INPUTS:
;
;   oUI - Objref to the UI.
;
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, January 2003
;   Modified:
;

;-------------------------------------------------------------------------
function IDLituiCLExport, oUI, oRequester

  compile_opt idl2, hidden

  ;; Retrieve widget ID of top-level base.
  oUI->GetProperty, GROUP_LEADER=groupLeader

  if (WIDGET_INFO(groupleader, /VALID)) then begin
    screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
    geom = WIDGET_INFO(groupLeader, /GEOM)
    xoffset = geom.scr_xsize + geom.xoffset - 80
    yoffset = geom.yoffset + (geom.ysize - 400)/2
  endif

  oRequester->GetProperty,pData=pData

  result = IDLitwdCLExport( $
                            GROUP_LEADER=groupLeader, $
                            Data=pData, $
                            XOFFSET=xoffset, $
                            YOFFSET=yoffset)

  ;; Failure.
  if (size(result,/type) ne 8) then $
    return, 0

  oRequester->SetProperty,pData=result

  return, 1

end
