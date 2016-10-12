; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiwindowlayout.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiWindowLayout
;
; PURPOSE:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLituiWindowLayout(Requester [, UVALUE=uvalue])
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
;   Written by:  CT, RSI, Dec 2002
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiWindowLayout, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    oRequester->GetProperty, $
        AUTO_RESIZE=autoResize, $
        N_VIEWS=nViews, $
        LAYOUTS=oLayouts, $
        LAYOUT_INDEX=layoutIndex, $
        VIEW_COLUMNS=viewColumns, $
        VIEW_ROWS=viewRows, $
        VIRTUAL_WIDTH=virtualWidth, $
        VIRTUAL_HEIGHT=virtualHeight

    success = IDLitwdWindowLayout( $
        AUTO_RESIZE=autoResize, $
        N_VIEWS=nViews, $
        GROUP_LEADER=groupLeader, $
        LAYOUTS=oLayouts, $
        LAYOUT_INDEX=layoutIndex, $
        VIEW_COLUMNS=viewColumns, $
        VIEW_ROWS=viewRows, $
        VIRTUAL_WIDTH=virtualWidth, $
        VIRTUAL_HEIGHT=virtualHeight)

    if (~success) then $
        return, 0

    oRequester->SetProperty, $
        AUTO_RESIZE=autoResize, $
        LAYOUT_INDEX=layoutIndex, $
        VIEW_COLUMNS=viewColumns, $
        VIEW_ROWS=viewRows, $
        VIRTUAL_WIDTH=virtualWidth, $
        VIRTUAL_HEIGHT=virtualHeight

    return, 1
end

