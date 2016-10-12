; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopfilterroberts__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopFilterRoberts
;
; PURPOSE:
;   Implements the Roberts operation.
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
function IDLitopFilterRoberts::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Roberts", $
        DESCRIPTION="Roberts Filter", TYPES=['IDLARRAY2D','IDLROI'], $
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
pro IDLitopFilterRoberts::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;---------------------------------------------------------------------------
function IDLitopFilterRoberts::Execute, data, MASK=mask

    compile_opt idl2, hidden

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (ROBERTS(data))[iMask]
    endif else $
        data = ROBERTS(TEMPORARY(data))
    return,1
end


;-------------------------------------------------------------------------
pro IDLitopFilterRoberts__define

    compile_opt idl2, hidden

    struc = {IDLitopFilterRoberts, $
             inherits IDLitDataOperation,     $
             inherits _IDLitROIPixelOperation $
            }

end

