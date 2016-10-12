; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolvector__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Vector object.
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
function IDLitToolVector::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, TYPE="IDLVISVECTOR")) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Vector')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Vector', 'IDLitVisVector', ICON='fitwindow'

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitToolVector__Define

    compile_opt idl2, hidden

    void = { IDLitToolVector, $
        inherits IDLitToolbase $
        }
end
