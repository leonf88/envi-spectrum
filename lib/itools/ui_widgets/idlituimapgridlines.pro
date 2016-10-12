; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituimapgridlines.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiMapGridLines
;
; PURPOSE:
;   This function implements the user interface for the Gridlines
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiMapGridLines(oUI, Requester)
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
function IDLituiMapGridLines, oUI, oRequester, PROPERTY=property

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 600)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    oLines = oRequester->_GetGridlines()
    nlines = N_ELEMENTS(oLines)
    if (~nlines) then $
        return, 0

    idComponent = STRARR(nlines)
    for i=0,nlines-1 do begin
        idComponent[i] = oLines[i]->GetFullIdentifier()
    endfor

    success = IDLitwdPropertySheet(oUI, $
        GROUP_LEADER=groupLeader, $
        /MODAL, $
        TITLE=IDLitLangCatQuery('UI:UIMapGridLines:Title'), $
        VALUE=idComponent, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset, $
        SCR_XSIZE=600, $
        YSIZE=18)

    return, success
end

