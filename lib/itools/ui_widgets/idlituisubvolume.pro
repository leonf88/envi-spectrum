; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituisubvolume.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUISubVolume
;
; PURPOSE:
;   This function implements the user interface for the SubVolume
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUISubVolume(UI, Requester [, UVALUE=uvalue])
;
; INPUTS:
;   UI object
;   Requester - either a create or prop modify ooperation
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUISubVolume, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 400)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    ; Get the needed information from the requester
    oRequester->GetProperty, $
        ODATA=oData, $
        SUBVOLUME=subvolume

    ; Launch the GUI, to get the isovalue(s)
    result = IDLitwdSubVolume(oUI, $
        DATA_OBJECTS=oData, $
        NLEVELS=2, $
        SUBVOLUME=subvolume, $
        GROUP_LEADER=groupLeader, $
        TITLE=IDLitLangCatQuery('UI:UISubVol:Title'), $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    ; Failure.
    if (N_TAGS(result) lt 1) then $
        return, 0

    oRequester->SetProperty, $
        SUBVOLUME=result.subVolume
    return, 1
end

