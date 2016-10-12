; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituirotatebyangle.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiRotateByAngle
;
; PURPOSE:
;   This function implements the user interface for angle rotation
;   for the IDL iTool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiRotateByAngle(oUI, Requester)
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
function IDLituiRotateByAngle, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 100)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    ; Retrieve initial angle setting.
    oRequester->GetProperty, ANGLE=angle, RELATIVE=relative

    result = IDLitwdRotateByAngle(oUI, $
        GROUP_LEADER=groupLeader, $
        ANGLE=angle, $
        CANCEL=cancel, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    if (cancel) then $
        return, 0

    ; Convert from absolute to relative angle.
    if (KEYWORD_SET(relative)) then $
        result -= angle

    ; Set desired angle setting.
    oRequester->SetProperty, ANGLE=result

    return, 1
end

