; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituicropimage.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the user interface for the
;   crop image property sheet.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, August 2004
;   Modified:
;


;-------------------------------------------------------------------------
function IDLituiCropImage, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 600)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    oRequester->GetProperty, NAME=title
    ysize = (N_ELEMENTS(oRequester->QueryProperty()) + 2) < 18

    success = IDLitwdPropertySheet(oUI, $
        /CANCEL, $
        OK_STRING=title, $
        GROUP_LEADER=groupLeader, $
        TITLE=title, $
        /UI_CALLBACK, $
        VALUE=oRequester->GetFullIdentifier(), $
        XOFFSET=xoffset, $
        YOFFSET=yoffset, $
        SCR_XSIZE=300, $
        YSIZE=ysize)

    return, success
end

