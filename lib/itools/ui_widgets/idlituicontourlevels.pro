; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituicontourlevels.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIContourLevels
;
; PURPOSE:
;   This function implements the user interface for the ContourLevels
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIContourLevels(oUI, Requester)
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIContourLevels, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 600)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    oRequester->GetProperty, CONTOUR_LEVELS=oLevels
    nlevels = N_ELEMENTS(oLevels)
    if (~nlevels) then $
        return, 0
    idComponent = STRARR(nlevels)
    for i=0,nlevels-1 do $
        idComponent[i] = oLevels[i]->GetFullIdentifier()

    ; If we have multiple levels, prepend our container.
    if (nlevels gt 1) then begin
        oLevels[0]->GetProperty, PARENT=oContainer
        oLevels = [oContainer, oLevels]
        idComponent = [oContainer->GetFullIdentifier(), idComponent]
    endif

    success = IDLitwdPropertySheet(oUI, $
        GROUP_LEADER=groupLeader, $
        /MODAL, $
        TITLE=IDLitLangCatQuery('UI:UIContLev:Title'), $
        VALUE=idComponent, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset, $
        SCR_XSIZE=500, $
        YSIZE=18)

    return, success
end

