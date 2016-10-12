; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopunsharpmask__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopUnsharpMask
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a property sheet is used.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataOperation
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopUnsharpMask::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopUnsharpMask object.
;
; Arguments:
;   None.
;
function IDLitopUnsharpMask::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Unsharp Mask", $
        DESCRIPTION="IDL Unsharp Mask operation", $
        TYPES=['IDLARRAY2D','IDLROI'], $
        NUMBER_DS='1', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
        self->Cleanup
        return, 0
    endif

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self._amount = 100
    self._radius = 3.0
    self._threshold = 0b

    ; Register properties
    self->RegisterProperty, 'Amount', /INTEGER, $
        NAME='Amount of filter (%)', $
        DESCRIPTION='Amount of filtering to be applied (100% is default)', $
        VALID_RANGE=[0,500,10]
    self->RegisterProperty, 'Radius', /FLOAT, $
        NAME='Radius in pixels', $
        DESCRIPTION='Radius of Gaussian smoothing filter in pixels', $
        VALID_RANGE=[0.1d,100,0.1d]
    self->RegisterProperty, 'Threshold', /INTEGER, $
        NAME='Clipping threshold', $
        Description='Clipping threshold as a byte value', $
        VALID_RANGE=[0,255,1]

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopUnsharpMask::SetProperty, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor for the IDLitopUnsharpMask object.
;
pro IDLitopUnsharpMask::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;-------------------------------------------------------------------------
; Purpose: GetProperty
;
; Arguments:
;   None.
;
pro IDLitopUnsharpMask::GetProperty, $
    AMOUNT=amount, $
    MINIMUM_DIMENSION=minDim, $
    RADIUS=radius, $
    THRESHOLD=threshold, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(amount)) then $
        amount = self._amount

    if (ARG_PRESENT(radius)) then $
        radius = self._radius

    if (ARG_PRESENT(threshold)) then $
        threshold = self._threshold

    if (ARG_PRESENT(minDim)) then $
        minDim = CEIL(2*self._radius)/2*2 + 1

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose: SetProperty
;
; Arguments:
;   None.
;
pro IDLitopUnsharpMask::SetProperty, $
    AMOUNT=amount, $
    RADIUS=radius, $
    THRESHOLD=threshold, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(amount) eq 1) then $
        self._amount = amount

    if (N_ELEMENTS(radius) eq 1) then begin
        if (self._withinUI) then begin
            ; If we are displaying the UI, retrieve the data dimensions
            ; and restrict the property to be within the acceptable range.
            pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
            mx = MAX(dims)
            if (mx gt 0) then $
                radius <= mx/2 - 1
        endif
        self._radius = radius
    endif

    if (N_ELEMENTS(threshold) eq 1) then $
        self._threshold = threshold

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Purpose:
;   Display scalefactor UI before execution.
;
; Arguments
;   None
;
function IDLitopUnsharpMask::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; Display dialog.
    return, oTool->DoUIService('OperationPreview', self)

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on raw data.
;
; Arguments:
;   Data: The data on which the operation is to be performed.
;
function IDLitopUnsharpMask::Execute, data, MASK=mask

    compile_opt idl2, hidden

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (UNSHARP_MASK(data, $
                AMOUNT=self._amount/100.0, $
                RADIUS=self._radius, $
                THRESHOLD=self._threshold))[iMask]
    endif else $
        data = UNSHARP_MASK(TEMPORARY(data), $
            AMOUNT=self._amount/100.0, $
            RADIUS=self._radius, $
            THRESHOLD=self._threshold)

    return, 1
end

;-------------------------------------------------------------------------
pro IDLitopUnsharpMask__define

    compile_opt hidden

    struc = {IDLitopUnsharpMask, $
        inherits IDLitDataOperation, $
        inherits _IDLitROIPixelOperation, $
        _amount: 0, $
        _threshold: 0b, $
        _radius: 0d $
        }

end

