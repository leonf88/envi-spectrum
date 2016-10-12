; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopsmooth__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSmooth
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
;   See IDLitopSmooth::Init
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopSmooth::Init
;
; Purpose:
; The constructor of the IDLitopSmooth object.
;
; Parameters:
;   None.
;
function IDLitopSmooth::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if(self->IDLitDataOperation::Init(NAME="Smooth", $
        DESCRIPTION="IDL Smooth operation", $
        TYPES=["IDLVECTOR", "IDLARRAY2D", "IDLARRAY3D", "IDLROI"], $
        NUMBER_DS='1', $
        /SHOW_EXECUTION_UI, $
        _EXTRA=_extra) eq 0)then $
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
        Description='Smooth Filter Width.'

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitopSmooth::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup

end

;-------------------------------------------------------------------------
; IDLitopSmooth::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopSmooth::GetProperty,        $
    MINIMUM_DIMENSION=minDim, $
    WIDTH=width,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(minDim)) then $
        minDim = self._width

    if (arg_present(width)) then $
        width = self._width

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopSmooth::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopSmooth::SetProperty,      $
                        WIDTH=widthIn, $
                        _EXTRA=_extra

    compile_opt idl2, hidden

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
                width <= (mx - 2)
        endif
        ; Width must be odd.
        width = width/2*2 + 1
        self._width = width
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopSmooth::Execute
;
; Purpose: 
;   This function method executes a smooth operation to the given data.
;
; Parameters:
;   data: The data on which the operation is to be performed.
;
function IDLitopSmooth::Execute, data, MASK=mask

    compile_opt idl2, hidden

    ; Perform operation
    dims = SIZE(data, /DIMENSIONS)
    if (MIN(dims) LE self._width) then begin
        self->ErrorMessage, $
          IDLitLangCatQuery('Error:Smooth:WindowWidthTooBig') , $
          SEVERITY=2
        return, 0
    endif

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask gt 0) then $
            data[iMask] = (SMOOTH(data, self._width, NAN=self._nan))[iMask]
    endif else $
        data = SMOOTH(temporary(data), self._width, NAN=self._nan)

    return,1
end


;---------------------------------------------------------------------------
; IDLitopSmooth::DoExecuteUI
;
; Purpose:
;   Display smooth propertysheet before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation
;
function IDLitopSmooth::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; Display dialog.
    return, oTool->DoUIService('OperationPreview', self)

end

;-------------------------------------------------------------------------
pro IDLitopSmooth__define
   compile_opt idl2, hidden
    struc = {IDLitopSmooth, $
             inherits IDLitDataOperation,    $
             inherits _IDLitROIPixelOperation, $
             _width:    0L   $
            }

end

