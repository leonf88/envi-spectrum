; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopdifferenceofgaussians__define.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopDifferenceOfGaussians
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
;   See IDLitopDifferenceOfGaussians::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopDifferenceOfGaussians object.
;
; Arguments:
;   None.
;
function IDLitopDifferenceOfGaussians::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Difference of Gaussians", $
        DESCRIPTION="IDL Difference of Gaussians operation", $
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

    self._radius1 = 3.0
    self._radius2 = 5.0

    ; Register properties
    self->RegisterProperty, 'Radius1', /INTEGER, $
        NAME='Radius1 in pixels', $
        DESCRIPTION='Radius1 of Difference of Gaussians smoothing filter in pixels', $
        VALID_RANGE=[1,100,1]
    self->RegisterProperty, 'Radius2', /INTEGER, $
        NAME='Radius2 in pixels', $
        DESCRIPTION='Radius2 of Difference of Gaussians smoothing filter in pixels', $
        VALID_RANGE=[1,100,1]
    self->RegisterProperty, 'Threshold', /INTEGER, $
        NAME='Clipping threshold', $
        Description='Clipping threshold as a byte value', $
        VALID_RANGE=[0,255,1]
    self->RegisterProperty, 'UseZeroCrossings', /BOOLEAN, $
        NAME='Use Zero Crossings', $
        Description='Replace pixels with Zero Crossing Values', $
        VALID_RANGE=[0,255,1]
    self->RegisterProperty, 'ZeroCrossings1', /INTEGER, $
        NAME='Zero Crossing Low Pixel Value', $
        Description='Pixel Value for the negative side of a zero crossing', $
        VALID_RANGE=[0,255,1]
    self->RegisterProperty, 'ZeroCrossings2', /INTEGER, $
        NAME='Zero Crossing High Pixel Value', $
        Description='Pixel Value for the positive side of a zero crossing', $
        VALID_RANGE=[0,255,1]

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopDifferenceOfGaussians::SetProperty, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor for the IDLitopDifferenceOfGaussians object.
;
pro IDLitopDifferenceOfGaussians::Cleanup

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
pro IDLitopDifferenceOfGaussians::GetProperty, $
    MINIMUM_DIMENSION=minDim, $
    RADIUS1=radius1, $
    RADIUS2=radius2, $
    THRESHOLD=threshold, $
    USEZEROCROSSINGS=useZeroCrossings, $
    ZEROCROSSINGS1=zeroCrossings1, $
    ZEROCROSSINGS2=zeroCrossings2, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (ARG_PRESENT(radius1)) then $
        radius1 = self._radius1

    if (ARG_PRESENT(radius2)) then $
        radius2 = self._radius2

	if (ARG_PRESENT(threshold)) then $
        threshold = self._threshold

	if (ARG_PRESENT(useZeroCrossings)) then $
        useZeroCrossings = self._useZeroCrossings

	if (ARG_PRESENT(zeroCrossings1)) then $
        zeroCrossings1 = self._zeroCrossings[0]

	if (ARG_PRESENT(zeroCrossings2)) then $
        zeroCrossings2 = self._zeroCrossings[1]

    if (ARG_PRESENT(minDim)) then $
        minDim = CEIL(2*self._radius1)/2*2 + 1

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose: SetProperty
;
; Arguments:
;   None.
;
pro IDLitopDifferenceOfGaussians::SetProperty, $
    RADIUS1=radius1, $
    RADIUS2=radius2, $
    THRESHOLD=threshold, $
    USEZEROCROSSINGS=useZeroCrossings, $
    ZEROCROSSINGS1=zeroCrossings1, $
    ZEROCROSSINGS2=zeroCrossings2, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(radius1) eq 1) then begin
        if (self._withinUI) then begin
            ; If we are displaying the UI, retrieve the data dimensions
            ; and restrict the property to be within the acceptable range.
            pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
            mx = MAX(dims)
            if (mx gt 0) then $
                radius1 <= mx/2 - 1
        endif
        self._radius1 = radius1
    endif

    if (N_ELEMENTS(radius2) eq 1) then begin
        if (self._withinUI) then begin
            ; If we are displaying the UI, retrieve the data dimensions
            ; and restrict the property to be within the acceptable range.
            pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
            mx = MAX(dims)
            if (mx gt 0) then $
                radius2 <= mx/2 - 1
        endif
        self._radius2 = radius2
    endif

    if (N_ELEMENTS(threshold) eq 1) then $
        self._threshold = threshold

    if (N_ELEMENTS(useZeroCrossings) eq 1) then $
        self._useZeroCrossings = useZeroCrossings gt 0 ? 1 : 0

    if (N_ELEMENTS(zeroCrossings1) eq 1) then $
        self._zeroCrossings[0] = zeroCrossings1

    if (N_ELEMENTS(zeroCrossings2) eq 1) then $
        self._zeroCrossings[1] = zeroCrossings2

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
function IDLitopDifferenceOfGaussians::DoExecuteUI

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
function IDLitopDifferenceOfGaussians::Execute, data, MASK=mask

    compile_opt idl2, hidden

	if self._useZeroCrossings then begin
	    if (N_ELEMENTS(mask) ne 0) then begin
	        iMask = WHERE(mask ne 0, nMask)
	        if (nMask gt 0) then $
	            data[iMask] = (EDGE_DOG(data, $
	                RADIUS1=self._radius1, $
	                RADIUS2=self._radius2, $
	                THRESHOLD=self._threshold, $
	                ZERO_CROSSINGS=self._zeroCrossings))[iMask]
		endif else $
	        data = EDGE_DOG(TEMPORARY(data), $
	            RADIUS1=self._radius1, $
	            RADIUS2=self._radius2, $
	            THRESHOLD=self._threshold, $
	            ZERO_CROSSINGS=self._zeroCrossings)
	endif else begin
	    if (N_ELEMENTS(mask) ne 0) then begin
	        iMask = WHERE(mask ne 0, nMask)
	        if (nMask gt 0) then $
	            data[iMask] = (EDGE_DOG(data, $
	                RADIUS1=self._radius1, $
	                RADIUS2=self._radius2, $
	                THRESHOLD=self._threshold))[iMask]
	    endif else $
	        data = EDGE_DOG(TEMPORARY(data), $
	            RADIUS1=self._radius1, $
	            RADIUS2=self._radius2, $
	            THRESHOLD=self._threshold)
	endelse

    return, 1
end

;-------------------------------------------------------------------------
pro IDLitopDifferenceOfGaussians__define

    compile_opt hidden

    struc = {IDLitopDifferenceOfGaussians, $
        inherits IDLitDataOperation, $
        inherits _IDLitROIPixelOperation, $
        _radius1: 0b, $
        _radius2: 0b, $
        _threshold: 0b, $
        _useZeroCrossings: 0b, $
        _zeroCrossings: [0b, 0b] $
        }

end

