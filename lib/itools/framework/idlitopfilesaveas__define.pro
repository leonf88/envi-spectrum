; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfilesaveas__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Save As operation.
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
; Keywords:
;   All superclass keywords.
;
function IDLitopFileSaveAs::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Default is to show the File Selection dialog,
    ; so set SHOW_EXECUTION_UI to true.
    success = self->IDLitopFileSave::Init(/SHOW_EXECUTION_UI, $
        _EXTRA=_extra)

    ; We always want the File Selection dialog to be shown,
    ; so don't allow the property to be turned on/off.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', /HIDE

    return, success
end


;---------------------------------------------------------------------------
; Purpose:
;   Used to save the iTool state.
;
; Parameters:
;   oTool   - The tool we are operating in.
;
; Return Value
;   Null object (not undoable).
;
; Keywords:
;   SUCCESS (1), Failure (0), or Cancel (-1).
;
function IDLitopFileSaveAs::DoAction, oTool, SUCCESS=success

    compile_opt idl2, hidden

    ; We always want to show the dialog.
    self->SetProperty, /SHOW_EXECUTION_UI

    success = self->_Save(oTool)

    if (success eq 1) then begin
        ; Be sure our File/Save and File/SaveAs are in sync.
        oDesc = oTool->GetByIdentifier('Operations/File/Save')
        if (OBJ_VALID(oDesc)) then $
            oDesc->SetProperty, FILENAME=self._filename
    endif

    return, OBJ_NEW()  ; not undoable

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitopFileSaveAs__define

    compile_opt idl2, hidden

    ; The only reason we inherit from FileSave is to pick up the
    ; filename property.
    struc = {IDLitopFileSaveAs, $
        inherits IDLitopFileSave }

end

