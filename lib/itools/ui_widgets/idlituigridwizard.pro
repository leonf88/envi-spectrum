; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituigridwizard.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIGridWizard
;
; PURPOSE:
;   This function implements the user interface for the gridding wizard.
;   The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIGridWizard(oUI, oRequester)
;
; INPUTS:
;   UI - UI objref.
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Jan 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
function IDLitUIGridWizard, oUI, oRequester
  compile_opt idl2, hidden

  ;; Retrieve widget ID of top-level base.
  oUI->GetProperty, GROUP_LEADER=groupLeader

  ;; Retrieve the irregular data.
  oRequester->GetProperty, DATA=oData


    ; Retrieve the first two vectors within the container.
    ; Assume these are the X and Y coordinates.
    oVector = oData->GetByType('IDLVECTOR')
    if (N_ELEMENTS(oVector) lt 2) then $
        return, 0
    if (~oVector[0]->GetData(x)) then $
        return, 0
    if (~oVector[1]->GetData(y)) then $
        return, 0

    ; Now retrieve either another vector or an array, for Z.
    if (N_ELEMENTS(oVector) ge 3) then begin
        if (~oVector[2]->GetData(z)) then $
            return, 0
    endif else begin
        oArray = (oData->GetByType('IDLARRAY2D'))[0]
        if (~OBJ_VALID(oArray) || ~oArray->GetData(z)) then $
            return, 0
    endelse

  oData->GetProperty, NAME=name

  ;; Fire off the wizard and wait for it to return.
  result = IDLitwdGridWizard(x, y, z, $
    UI_OBJECT=oUI, $
    GROUP_LEADER=groupLeader)

  ; We need to check if the user hit "cancel", or if the gridding
  ; failed and we got a scalar value back.
  if ((N_TAGS(result) eq 0) || (N_ELEMENTS(result.result) le 1)) then $
    return, 0

    ; Just add gridded results to our data container.
    oParamSet = oData

    oDataZ = OBJ_NEW('IDLitDataIDLArray2D', result.result, $
                   NAME='Z')
    oParamSet->Add, oDataZ, PARAMETER_NAME= "Z"

    if (N_ELEMENTS(result.xgrid) gt 0) then begin
        oDataX = OBJ_NEW('IDLitDataIDLVector', result.xgrid, $
                     NAME='X')
        oParamSet->Add, oDataX, PARAMETER_NAME= "X"
    endif

    if (N_ELEMENTS(result.ygrid) gt 0) then begin
        oDataY = OBJ_NEW('IDLitDataIDLVector', result.ygrid, $
                     NAME='Y')
        oParamSet->Add, oDataY, PARAMETER_NAME= "Y"
    endif

    oRequester->SetProperty, DATA=oParamSet

    return, 1

end

