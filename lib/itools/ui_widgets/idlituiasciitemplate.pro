; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiasciitemplate.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIAsciiTemplate
;
; PURPOSE:
;   This function implements the user interface for ASCII_TEMPLATE.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIAsciiTemplate(oUI, oRequester)
;
; INPUTS:
;   oUI - Set this argument to the object reference for the UI.
;   oRequester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIAsciiTemplate, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Filename should already have been chosen.
    filename = oRequester->GetFilename()
    if (filename eq '') then $
        return, 0

    template = ASCII_TEMPLATE(filename, $
        GROUP=groupLeader)

    ; User hit cancel.
    if (N_TAGS(template) eq 0) then $
        return, 0

    oRequester->SetProperty, TEMPLATE=template

    return, 1
end

