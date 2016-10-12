; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopfilterprewitt__define.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopFilterPrewitt
;
; PURPOSE:
;   Implements the Prewitt operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataOperation
;
; INTERFACES:
;   IIDLProperty
;-

;-------------------------------------------------------------------------
function IDLitopFilterPrewitt::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Prewitt", $
        DESCRIPTION="Prewitt Filter", TYPES=['IDLARRAY2D','IDLROI'], $
        NUMBER_DS='1', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
        self->Cleanup
        return, 0
    endif

    return, 1

end

;-------------------------------------------------------------------------
pro IDLitopFilterPrewitt::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;---------------------------------------------------------------------------
function IDLitopFilterPrewitt::Execute, data, MASK=mask

    compile_opt idl2, hidden

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (PREWITT(data))[iMask]
    endif else $
        data = PREWITT(TEMPORARY(data))
    return,1
end


;-------------------------------------------------------------------------
pro IDLitopFilterPrewitt__define

    compile_opt idl2, hidden

    struc = {IDLitopFilterPrewitt, $
             inherits IDLitDataOperation,     $
             inherits _IDLitROIPixelOperation $
            }

end

