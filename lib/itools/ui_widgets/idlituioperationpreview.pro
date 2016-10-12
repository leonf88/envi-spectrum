; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituioperationpreview.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-------------------------------------------------------------------------
; Purpose:
;   This function implements the user interface for the
;   operation preview.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2003
;   Modified:
;


;-------------------------------------------------------------------------
function IDLituiOperationPreview, oUI, oRequester

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

    success = IDLitwdOperationPreview(oUI, $
        /CANCEL, $
        GROUP_LEADER=groupLeader, $
        /NO_COMMIT, $
        /NO_REGISTER_VIS, $
        TITLE=title, $
        VALUE=oRequester, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset, $
        SCR_XSIZE=300, $
        YSIZE=ysize)

    return, success
end

