; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopedituserdefproperty__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the EditUserdefProperty operation.
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
function IDLitopEditUserdefProperty::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Calls the EditUserdefProperty method on all incoming targets.
;
; Result:
;   Returns a command object containing the SetProperty undo/redo for all
;   registered properties.
;
; Arguments:
;   Tool: Object reference to the tool.
;
; Keywords:
;   PROPERTY_IDENTIFIER: A string giving the Userdef property identifier.
;
;   TARGET: The object reference on which to call EditUserdefProperty.
;
function IDLitopEditUserdefProperty::DoAction, oTool, oTarget, propID

    compile_opt idl2, hidden

    ; Sanity check.
    if (~OBJ_VALID(oTool) || ~OBJ_VALID(oTarget)) then $
        return, 0

    ; Record all of our initial registered property values.
    ; If oTool is the system, as occurs when editing a userdef
    ; property in the macro editor, don't bother to record.
    if (~OBJ_ISA(oTool, 'IDLitSystem')) then $
        oPropSet = self->IDLitOperation::RecordInitialProperties(oTarget)

    ; Fire up our EditUserdefProperty on our target.
    if (~oTarget->EditUserDefProperty(oTool, propID)) then begin
        ; If user hit Cancel then undo the pending transaction.
        if (~OBJ_ISA(oTool, 'IDLitSystem')) then begin
            oCommandBuffer = oTool->_GetCommandBuffer()
            oCommandBuffer->Rollback
        endif
        if (OBJ_VALID(oPropSet)) then $
            OBJ_DESTROY, oPropSet
        return, 0
    endif

    ; Record all of our final registered property values.
    if (OBJ_VALID(oPropSet)) then $
        self->IDLitOperation::RecordFinalProperties, oPropSet

    if (OBJ_VALID(oPropSet)) then begin
        ; Create a pretty name from the property ID.
        ; Replace underscores with spaces.
        name = STRSPLIT(propID, '_', /EXTRACT)
        ; Mixed case.
        for i=0,N_ELEMENTS(name)-1 do name[i] = $
            STRUPCASE(STRMID(name[i],0,1)) + STRLOWCASE(STRMID(name[i],1))
        name = STRJOIN(name, ' ')
        oPropSet->IDLitComponent::SetProperty, NAME=name
        self->IDLitOperation::RecordFinalProperties, oPropSet
        oTool->_TransactCommand, oPropSet
    endif

    return, 1

end


;-------------------------------------------------------------------------
pro IDLitopEditUserdefProperty__define

    compile_opt idl2, hidden

    struc = {IDLitopEditUserdefProperty, $
        inherits IDLitOperation $
        }
end

