; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituimapprojection.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiMapProjection
;
; PURPOSE:
;   This function implements the user interface for Map Projections
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiMapProjection(oUI, Requester)
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2004
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiMapProjection, oUI, oRequester, PROPERTY=property

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 600)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    success = IDLitwdPropertyPreview(oUI, $
        /CANCEL, $
        GROUP_LEADER=groupLeader, $
        /NO_COMMIT, $
        /NO_REGISTER_VIS, $
        TITLE=IDLitLangCatQuery('UI:UIMapProj:Title'), $
        VALUE=oRequester, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset, $
        SCR_XSIZE=350, $
        YSIZE=18)

    return, success
end

