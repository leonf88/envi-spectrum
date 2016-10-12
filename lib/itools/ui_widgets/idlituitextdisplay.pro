; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituitextdisplay.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLituiTextDisplay
;
; PURPOSE:
;   This function implements the user interface for displaying text.
;
; CALLING SEQUENCE:
;   Result = IDLituiTextDisplay(oUI, oRequester)
;
; INPUTS:
;   oUI - Set this argument to the object reference for the UI.
;   oRequester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, September 2002
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLituiTextDisplay, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    oRequester->GetProperty, $
        TEXT=text, $
        DESCRIPTION=title

    IDLitwdTextDisplay, text, $
        FONT='Courier', $
        GROUP_LEADER=groupLeader, $
        TITLE=title

    return, 1
end

