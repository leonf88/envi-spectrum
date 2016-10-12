; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertaxisx__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert X Axis operation.
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
function IDLitopInsertAxisX::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Allow this operation to work on 2D or 3D dataspaces.
    return, self->IDLitopInsertAxis::Init( $
        TYPE='DATASPACE_' + ['2D','ROOT_2D','3D','ROOT_3D'], _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertAxisX::DoAction, oTool

    compile_opt idl2, hidden

    return, self->IDLitOpInsertAxis::DoAction(oTool, DIRECTION=0)   ; X axis

end


;-------------------------------------------------------------------------
pro IDLitopInsertAxisX__define

    compile_opt idl2, hidden

    struc = {IDLitopInsertAxisX, $
        inherits IDLitopInsertAxis}

end

