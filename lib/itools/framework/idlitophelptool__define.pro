; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitophelptool__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Display the help for the current tool.
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
function IDLitopHelpTool::Init, _REF_EXTRA=_extra

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
function IDLitopHelpTool::DoAction, oTool

    compile_opt idl2, hidden

    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return, OBJ_NEW()

    ; Retrieve the HELP property.
    oTool->GetProperty, HELP=helpTopic

    ; If HELP is undefined, try to use the classname.
    if (helpTopic eq '') then $
        helpTopic = OBJ_CLASS(oTool)

    oHelp->HelpTopic, oTool, helpTopic

    return, obj_new()   ; no undo/redo
end


;-------------------------------------------------------------------------
pro IDLitopHelpTool__define

    compile_opt idl2, hidden

    struc = {IDLitopHelpTool, $
        inherits IDLitOperation}

end

