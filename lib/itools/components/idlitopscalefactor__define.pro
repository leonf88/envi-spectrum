; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopscalefactor__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopScalefactor
;
; PURPOSE:
;   This file implements the scalefactor action.
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopScalefactor::Init
;
; Purpose:
; The constructor of the IDLitopScalefactor object.
;
; Parameters:
; None.
;
function IDLitopScalefactor::Init, _EXTRA=_extra
  compile_opt idl2, hidden

  success = self->IDLitDAtaOperation::Init( $
    NAME="Scale Data", $
    DESCRIPTION="Scale the data by a given factor", $
    /SHOW_EXECUTION_UI, $
    TYPES=["IDLVECTOR", "IDLARRAY2D", "IDLARRAY3D", "IDLROI"], $
    NUMBER_DS='1', $
    _EXTRA=_extra)
  if (not success)then $
    return, 0

  if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
    self->Cleanup
    return, 0
  endif

  ;; Defaults
  self._factor = 2

  ;; Turn this property back on.
  self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

  ;; Register properties
  self->RegisterProperty, 'SCALE_FACTOR', /FLOAT, $
    NAME='Scale factor', $
    DESCRIPTION='Multiply data by this scale factor'

  return, 1

end


;-------------------------------------------------------------------------
; IDLitopScalefactor::Cleanup
;
; Purpose:
; The destructor of the IDLitopScalefactor object.
;
; Parameters:
; None.
;
pro IDLitopScalefactor::Cleanup
  compile_opt idl2, hidden

  self->_IDLitROIPixelOperation::Cleanup
  self->IDLitDataOperation::Cleanup
end


;-------------------------------------------------------------------------
; IDLitopScalefactor::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopScalefactor::GetProperty, $
                                     SCALE_FACTOR=factor, $
                                     _REF_EXTRA=_extra

  compile_opt idl2, hidden

  if (arg_present(factor)) then $
    factor = self._factor

  if (n_elements(_extra) gt 0) then $
    self->IDLitDataOperation::GetProperty, _EXTRA=_extra

end


;-------------------------------------------------------------------------
; IDLitopScalefactor::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopScalefactor::SetProperty, $
                                     SCALE_FACTOR=factor, $
                                     _EXTRA=_extra

  compile_opt idl2, hidden

  if (N_ELEMENTS(factor) ne 0) then $
    self._factor = factor

  if (n_elements(_extra) gt 0) then $
    self->IDLitDataOperation::SetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitopScaleFactor::DoExecuteUI
;
; Purpose:
;   Display scalefactor UI before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;
;    0 - Error, discontinue the operation
;
Function IDLitopScalefactor::DoExecuteUI
  compile_opt idl2, hidden

  oTool = self->GetTool()
  if (~oTool) then $
    return, 0

  ;; Display dialog as a propertysheet
  return, oTool->DoUIService('PropertySheet', self)

end


;---------------------------------------------------------------------------
; IDLitopScalefactor::Execute
;
; Purpose: Execute the operation on the raw data.
;
; Parameters:
;   data: The data on which the operation is to be performed.
;
function IDLitopScalefactor::Execute, data, MASK=mask
  compile_opt idl2, hidden

  if (N_ELEMENTS(mask) ne 0) then begin
      iMask = WHERE(mask ne 0, nMask)
      if (nMask gt 0) then $
          data[iMask] *= self._factor
  endif else $
      data *= self._factor

  return,1

end


;-------------------------------------------------------------------------
pro IDLitopScalefactor__define
   compile_opt idl2, hidden
    struc = {IDLitopScalefactor, $
             inherits IDLitDataOperation,      $
             inherits _IDLitROIPixelOperation, $
             _factor: 0d $
            }

end

