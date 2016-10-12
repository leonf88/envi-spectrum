; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituibinarytemplate.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIBinaryTemplate
;
; PURPOSE:
;   This function implements the user interface for BINARY_TEMPLATE.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIBinaryTemplate(oUI, oRequester)
;
; INPUTS:
;   oUI - Set this argument to the object reference for the UI.
;   oRequester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Feb 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIBinaryTemplate, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Filename should already have been chosen.
    filename = oRequester->GetFilename()
    if (filename eq '') then $
        return, 0

    oRequester->GetProperty, TEMPLATE=iTemplate

    ; Returns a scalar if no initial template.
    if (N_TAGS(iTemplate) gt 0) then $
        initialTemplate = iTemplate

    ; Note: BINARY_TEMPLATE allows you to pass in an initial template
    ; as a first guess. In this case, if the User hits Cancel, it returns
    ; this initial template as the result. Therefore, we must check
    ; the CANCEL keyword rather than relying on the Result to contain
    ; no tags.
    template = BINARY_TEMPLATE(filename, $
        CANCEL=cancel, $
        GROUP=groupLeader, $
        TEMPLATE=initialTemplate)

    ; User hit cancel.
    if (cancel) then $
        return, 0

    oRequester->SetProperty, TEMPLATE=template

    return, 1
end

