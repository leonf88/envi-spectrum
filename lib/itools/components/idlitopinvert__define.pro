; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinvert__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInvert
;
; PURPOSE:
;   Implements an image invert operation.
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
function IDLitopInvert::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Invert", $
        DESCRIPTION="Invert Image", $
        TYPES=["IDLIMAGE","IDLARRAY2D","IDLROI"], $
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
pro IDLitopInvert::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;---------------------------------------------------------------------------
function IDLitopInvert::Execute, data, MASK=mask

    compile_opt idl2, hidden

    ; If byte data then offsets are 0 and 255, otherwise use data min and max.
    offsetMax = (SIZE(data, /TYPE) eq 1) ? 255b : MAX(data)
    offsetMin = (SIZE(data, /TYPE) eq 1) ? 0b : MIN(data)
    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (offsetMax - data + offsetMin)[iMask]
    endif else $
        data = offsetMax - TEMPORARY(data) + offsetMin

    return,1
end


;-------------------------------------------------------------------------
pro IDLitopInvert__define

    compile_opt idl2, hidden

    struc = {IDLitopInvert, $
             inherits IDLitDataOperation,   $
             inherits _IDLitROIPixelOperation $
            }

end

