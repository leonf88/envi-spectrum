; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituicurvefitting.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUICurveFitting
;
; PURPOSE:
;   This function implements the user interface for curve fitting
;   for the IDL iTool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUICurveFitting(oUI, Requester)
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
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUICurveFitting, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 600)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    oRequester->GetProperty, $
        MODEL=oldmodel, $
        PARAMETERS=oldparameters

    success = IDLitwdCurveFitting(oRequester, $
        GROUP_LEADER=groupLeader, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    ; Failure.
    if (~success) then begin
        ; Restore old values.
        oRequester->SetProperty, $
            MODEL=oldmodel, $
            PARAMETERS=oldparameters
        return, 0
    endif

    return, 1
end

