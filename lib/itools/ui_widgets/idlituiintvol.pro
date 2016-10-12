; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiintvol.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIIntVol
;
; PURPOSE:
;   This function implements the user interface for the Interval Volume
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIIntVol(UI, Requester [, UVALUE=uvalue])
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
function IDLitUIIntVol, oUI, oRequester

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
        DATA_OBJECTS=oData, $
        PALETTE_OBJECTS=oPalette, $
        DECIMATE=decimate, $
        _ISOVALUE0=isovalue0, $
        _ISOVALUE1=isovalue1, $
        SHOW_EXECUTION_UI=showUI, $
        USE_ISOVALUES=useIsovalues
    isovalues = [isovalue0, isovalue1]

    ; Launch the GUI, to get the isovalue(s)
    result = IDLitwdIsoValues(oUI, $
        DATA_OBJECTS=oData, $
        PALETTE_OBJECTS=oPalette, $
        DECIMATE=decimate, $
        NLEVELS=2, $
        ISOVALUES=isovalues, $
        USE_ISOVALUES=useIsovalues, $
        GROUP_LEADER=groupLeader, $
        SHOW_DIALOG=showUI, $
        TITLE=IDLitLangCatQuery('UI:UIIntVol:Title'), $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    ; Failure.
    if (N_TAGS(result) lt 1) then $
        return, 0

    ; Fetch the isovalues from the result and store in the requester
    ; so that they can be used to create/modify the Interval Volumes.
    case result.selected_dataset of
    0: isovalues = DOUBLE(result.iso0)
    1: isovalues = DOUBLE(result.iso1)
    2: isovalues = DOUBLE(result.iso2)
    3: isovalues = DOUBLE(result.iso3)
    endcase
    oRequester->SetProperty, $
        SHOW_EXECUTION_UI=result.show_dialog, $
        _ISOVALUE0=isovalues[0], $
        _ISOVALUE1=isovalues[1], $
        DECIMATE=result.decimate, $
        SELECTED_DATASET=result.selected_dataset
    return, 1
end

