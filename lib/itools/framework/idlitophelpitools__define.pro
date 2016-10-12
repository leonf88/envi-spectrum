; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Display the help for the iTools system.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitopHelpiTools::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the operation.
;
; Arguments:
;   None.
;
function IDLitopHelpiTools::DoAction, oTool

    compile_opt idl2, hidden

    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return, OBJ_NEW()

    ; Set the HELP property manually.

    helpTopic = 'IT_ABOUT'

    oHelp->HelpTopic, oTool, helpTopic

    return, obj_new()   ; no undo/redo
end


;-------------------------------------------------------------------------
pro IDLitopHelpiTools__define

    compile_opt idl2, hidden

    struc = {IDLitopHelpiTools, $
        inherits IDLitOperation}

end

