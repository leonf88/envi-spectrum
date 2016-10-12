; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituipaletteeditor.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIPaletteEditor
;
; PURPOSE:
;   This function implements the user interface for the Palette Editor.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIPaletteEditor(UI, Requester [, UVALUE=uvalue])
;
; INPUTS:
;   UI object
;   Requester - An object that has parameter data of type IDLPalette
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIPaletteEditor, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    if (WIDGET_INFO(groupleader, /VALID)) then begin
        screensize = GET_SCREEN_SIZE(RESOLUTION=resolution)
        geom = WIDGET_INFO(groupLeader, /GEOM)
        xoffset = (geom.scr_xsize + geom.xoffset - 80) < (screensize[0] - 400)
        yoffset = geom.yoffset + (geom.ysize - 400)/2
    endif

    ; Get the palette information from the requester
    oRequester->GetProperty, VISUALIZATION_PALETTE=paletteData

    ; Launch the GUI
    result = IDLitwdPaletteEditor(oUI, $
        oRequester, $
        PALETTE=paletteData, $
        GROUP_LEADER=groupLeader, $
        SHOW_DIALOG=showUI, $
        XOFFSET=xoffset, $
        YOFFSET=yoffset)

    ; Failure.
    if (N_TAGS(result) lt 1) then $
        return, 0

    ; Note: We don't need to set our new palette since the
    ; PaletteEditor does it on the fly.

    return, 1
end

