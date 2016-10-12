; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmorphopen__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Open operation.
;
; Written by: CT, RSI, April 2003
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopMorphOpen object.
;
; Arguments:
;   None.
;
; Keywords:
;
;   All superclass keywords are also allowed.
;
function IDLitopMorphOpen::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitopMorph::Init(NAME="Open operation", $
        DESCRIPTION="IDL Morphological Open operation", $
        _EXTRA=_extra) eq 0)then $
        return, 0

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopMorphOpen::SetProperty, _EXTRA=_extra

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the raw data.
;
; Arguments:
;   Data: The array of data to be operated on.
;
; Keywords:
;   MASK: An array (matching the dimensions of the data) that represents
;     a mask to be applied.  Only the data pixels for which the corresponding
;     mask pixel is non-zero will be operated upon.
;
function IDLitopMorphOpen::Execute, data, MASK=mask
    compile_opt idl2, hidden

    ndim = SIZE(data, /N_DIMENSIONS)
    if ((ndim lt 1) || (ndim gt 3)) then $
        return, 0

    structure = self->IDLitopMorph::_GetStructure(ndim)

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (MORPH_OPEN(data, structure, /GRAY))[iMask]
    endif else $
        data = MORPH_OPEN(data, structure, /GRAY)

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitopMorphOpen__define

    compile_opt idl2, hidden

    struc = {IDLitopMorphOpen, $
             inherits IDLitopMorph $
            }

end

