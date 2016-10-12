; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiconvolkernel.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIConvolKernel
;
; PURPOSE:
;   This function implements the user interface for the Operation Browser
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIConvolKernel(Requester [, UVALUE=uvalue])
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
function IDLitUIConvolKernel, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 400)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    success = IDLitwdConvolKernel(oUI, oRequester, $
        GROUP_LEADER=groupLeader, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    return, success

end

