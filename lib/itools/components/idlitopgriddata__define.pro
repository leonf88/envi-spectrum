; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopgriddata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopGridData
;
; PURPOSE:
;   This file implements the operation object that is used to grid data.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopGridData::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopGridData::Init
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopGridData::Init
;;
;; Purpose:
;; The constructor of the IDLitopGridData object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopGridData::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
;pro IDLitopGridData::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;    self->IDLitOperation::Cleanup
;end


;-------------------------------------------------------------------------
pro IDLitopGridData::GetProperty, $
    DATA=oData, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(oData) then $
        oData = self._oData

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end


;-------------------------------------------------------------------------
pro IDLitopGridData::SetProperty, $
    DATA=oData, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if N_ELEMENTS(oData) then $
        self._oData = oData

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitopGridData::Grid
;
; Purpose:
;  Given a data object, this method will grid it.
;
;  When this routine returns succesfully, the following will be done:
;    * Data object created and added to the Data Manager.
;
; Arguments:
;   oData   - Data objects. If multiple data objects are provided,
;             then multiple visualizations will be created.
;
;  The oData argument will contain the new data objects, although
;  the original data objects are not destroyed.
;
; Keywords:
;
; Return Values:
;    0   - Error
;    1   - Success
;
function IDLitopGridData::Grid, oData

    compile_opt idl2, hidden

    nData = N_ELEMENTS(oData)

    if (nData eq 0) then $
        return, OBJ_NEW() ;; nothing in, nothing out --> success.

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; Ok, just loop over the data objects and create visualizations
    oTargDesc = OBJARR(nData)
    iTarg=0

    for i=0, nData-1 do begin

        self._oData = oData[i]

        ; Ask the UI service to present the dialog to the user.
        ; The caller sets my data property before returning.
        if (~oTool->DoUIService('GridWizard', self)) then begin
            PTR_FREE, self._pData
            return, OBJ_NEW()
        endif

        ; Just replace our objref with the new gridded data.
        ; Note that this doesn't destroy the old data object.
        oData[i] = self._oData
        oTool->AddByIdentifier, "/Data Manager", oData[i]

    endfor ; data

    return, oData
end


;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitopGridData__define

    compile_opt idl2, hidden

    struc = {IDLitopGridData,       $
             inherits IDLitOperation, $
             _oData: OBJ_NEW() $
            }
end

