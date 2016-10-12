; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoplaplacian__define.pro#1 $
;
; Copyright (c) 2006-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopLaplacian
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
;   See IDLitopLaplacian::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopLaplacian object.
;
; Arguments:
;   None.
;
function IDLitopLaplacian::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Laplacian", $
        DESCRIPTION="IDL Laplacian Edge Detector operation", $
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

    ; Register properties
    self->RegisterProperty, 'ADD_BACK', /BOOLEAN, $
        NAME='Add back', $
        DESCRIPTION='Add difference results back into the image'

    self->RegisterProperty, 'KERNEL_SIZE', $
        NAME='Kernel Size', $
        DESCRIPTION='Convolution Kernel Size', $
        ENUMLIST=['3','5']

    self->RegisterProperty, 'CENTER', /BOOLEAN, $
        NAME='Center', $
        DESCRIPTION='Center the kernel over each pixel'

    self->RegisterProperty, 'EDGE_VALUE', $
        NAME='Edge Value', $
        DESCRIPTION='Value to use along the image edges', $
        ENUMLIST=['Zero', 'Truncate', 'Wrap']

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopLaplacian::SetProperty, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor for the IDLitopLaplacian object.
;
pro IDLitopLaplacian::Cleanup

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
pro IDLitopLaplacian::GetProperty, $
    ADD_BACK=addBack, $
    KERNEL_SIZE=kernelSize, $
    CENTER=center, $
    EDGE_VALUE=edgeValue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (ARG_PRESENT(addBack)) then $
        addBack = self._addBack

    if (ARG_PRESENT(kernelSize)) then $
        kernelSize = self._kernelSize

    if (ARG_PRESENT(center)) then $
        center = self._center

    if (ARG_PRESENT(edgeValue)) then $
        edgeValue = self._edgeValue

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose: SetProperty
;
; Arguments:
;   None.
;
pro IDLitopLaplacian::SetProperty, $
    ADD_BACK=addBack, $
    KERNEL_SIZE=kernelSize, $
    CENTER=center, $
    EDGE_VALUE=edgeValue, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(addBack) eq 1) then $
        self._addBack = addBack

    if (N_ELEMENTS(kernelSize) eq 1) then $
        self._kernelSize = kernelSize

    if (N_ELEMENTS(center) eq 1) then $
        self._center = center

    if (N_ELEMENTS(edgeValue) eq 1) then $
        self._edgeValue = edgeValue

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
function IDLitopLaplacian::DoExecuteUI

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
function IDLitopLaplacian::Execute, data, MASK=mask

    compile_opt idl2, hidden

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (LAPLACIAN(data, $
                ADD_BACK=self._addBack, $
                KERNEL_SIZE=([3,5])[self._kernelSize], $
                CENTER=self._center, $
                EDGE_ZERO=self._edgeValue eq 0, $
                EDGE_TRUNCATE=self._edgeValue eq 1, $
                EDGE_WRAP=self._edgeValue eq 2 $
                ))[iMask]
    endif else $
        data = LAPLACIAN(TEMPORARY(data), $
                ADD_BACK=self._addBack, $
                KERNEL_SIZE=([3,5])[self._kernelSize], $
                CENTER=self._center, $
                EDGE_ZERO=self._edgeValue eq 0, $
                EDGE_TRUNCATE=self._edgeValue eq 1, $
                EDGE_WRAP=self._edgeValue eq 2 $
                )

    return, 1
end

;-------------------------------------------------------------------------
pro IDLitopLaplacian__define

    compile_opt hidden

    struc = {IDLitopLaplacian, $
        inherits IDLitDataOperation, $
        inherits _IDLitROIPixelOperation, $
        _addBack: 0b, $
        _kernelSize: 0b, $
        _center: 0b, $
        _edgeValue: 0b $
        }

end

