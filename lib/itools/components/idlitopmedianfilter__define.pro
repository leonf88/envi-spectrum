; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmedianfilter__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the median filter operation.
;
; Written by: CT, RSI, April 2003
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopMedianFilter object.
;
; Arguments:
;   None.
;
; Keywords:
;   WIDTH (Get, Set): The width of the median filter.
;
function IDLitopMedianFilter::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Median Filter", $
        DESCRIPTION="IDL Median filter operation", $
        /SHOW_EXECUTION_UI, $
        TYPES=["IDLVECTOR", "IDLARRAY2D", "IDLROI"], $
        NUMBER_DS='1', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
        self->Cleanup
        return, 0
    endif

    self._width = 3

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ; Register properties
    self->RegisterProperty, 'Width', /INTEGER, $
        Description='Median filter width', $
        VALID_RANGE=[2,2147483646]

    self->RegisterProperty, 'Even', /BOOLEAN, $
        NAME='Even average', $
        Description='Average together points in an even-sized filter'

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   Destructor for the operation.
;
pro IDLitopMedianFilter::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;-------------------------------------------------------------------------
; Purpose:
;   Retrieve property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Get.
;
pro IDLitopMedianFilter::GetProperty,        $
    EVEN=even, $
    MINIMUM_DIMENSION=minDim, $
    WIDTH=width,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(even)) then $
        even = self._even

    if (ARG_PRESENT(minDim)) then $
        minDim = self._width

    if (ARG_PRESENT(width)) then $
        width = self._width

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose:
;   Set property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Set.
;
pro IDLitopMedianFilter::SetProperty,      $
    EVEN=even, $
    WIDTH=widthIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(even)) then $
        self._even = even

    if (N_ELEMENTS(widthIn) ne 0) then begin
        width = LONG(widthIn)
        if width lt 0 then $
            self->ErrorMessage, IDLitLangCatQuery('Error:Filter:WidthNonNeg'), severity=2
        if (self._withinUI) then begin
            ; If we are displaying the UI, retrieve the data dimensions
            ; and restrict the property to be within the acceptable range.
            pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
            mx = MAX(dims)
            if (mx gt 0) then $
                width <= mx
        endif
        self._width = width
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
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
function IDLitopMedianFilter::Execute, data, MASK=mask

    compile_opt idl2, hidden

    ; Perform operation
    dims = SIZE(data, /DIMENSIONS)
    if (MIN(dims) LE self._width) then begin
        self->ErrorMessage, $
	  IDLitLangCatQuery('Error:MedianFilter:FilterWidthTooBig'), $
          SEVERITY=2
        return, 0
    endif

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (MEDIAN(data, self._width, EVEN=self._even))[iMask]
    endif else $
        data = MEDIAN(TEMPORARY(data), self._width, EVEN=self._even)

    return, 1   ; success

end


;---------------------------------------------------------------------------
; Purpose:
;   Display propertysheet before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation
;
function IDLitopMedianFilter::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; Display dialog.
    return, oTool->DoUIService('OperationPreview', self)

end


;-------------------------------------------------------------------------
pro IDLitopMedianFilter__define

    compile_opt idl2, hidden

    struc = {IDLitopMedianFilter, $
             inherits IDLitDataOperation,    $
             inherits _IDLitROIPixelOperation, $
             _width:    0L, $
             _even:     0b $
            }

end

