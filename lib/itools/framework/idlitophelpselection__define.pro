; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitophelpselection__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Display the help for a selected item.
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
function IDLitopHelpSelection::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(NUMBER_DS='1', _EXTRA=_extra)

end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the operation.
;
; Arguments:
;   None.
;
function IDLitopHelpSelection::DoAction, oTool

    compile_opt idl2, hidden

    oHelp = oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then $
        return, OBJ_NEW()

    ; Retrieve the first selected item.
    oSelected = (oTool->GetSelectedItems(/ALL))[0]

    ; If nothing selected, use our tool.
    if (~OBJ_VALID(oSelected)) then $
        oSelected = oTool

    ; Retrieve the HELP property.
    oSelected->GetProperty, HELP=helpTopic

    ; If HELP is undefined, try to use the classname.
    if (helpTopic eq '') then $
        helpTopic = OBJ_CLASS(oSelected)

    oHelp->HelpTopic, oTool, helpTopic

    return, obj_new()   ; no undo/redo
end


;-------------------------------------------------------------------------
pro IDLitopHelpSelection__define

    compile_opt idl2, hidden

    struc = {IDLitopHelpSelection, $
        inherits IDLitOperation}

end

