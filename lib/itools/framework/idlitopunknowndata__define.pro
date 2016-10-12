; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopunknowndata__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopUnknownData
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
;   See IDLitopUnknownData::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopUnknownData::Init
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopUnknownData::Init
;;
;; Purpose:
;; The constructor of the IDLitopUnknownData object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopUnknownData::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end


;-------------------------------------------------------------------------
pro IDLitopUnknownData::Cleanup
    ;; Pragmas
    compile_opt idl2, hidden

    self->IDLitOperation::Cleanup
end


;-------------------------------------------------------------------------
pro IDLitopUnknownData::GetProperty, $
    DATA=oData, $
    METHOD=method, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(oData) then $
        oData = self._oData

    if ARG_PRESENT(method) then $
        method = self._method

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

end


;-------------------------------------------------------------------------
pro IDLitopUnknownData::SetProperty, $
    DATA=oData, $
    METHOD=method, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if N_ELEMENTS(oData) then $
        self._oData = oData

    if N_ELEMENTS(method) then $
        self._method = method

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra

end


;-------------------------------------------------------------------------
function IDLitopUnknownData::_Handle, oData

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; Ask the UI service to present the dialog to the user.
    ; The caller sets my data property before returning.
    if (~oTool->DoUIService('UnknownData', self)) then $
        return, OBJ_NEW()

    self._oData = oData


    case self._method of

        0: self._oData = OBJ_NEW()

        1: begin
            ; Ask the UI service to present the dialog to the user.
            ; The caller sets my data property before returning.
            void = oTool->DoUIService("HourGlassCursor", self)
            if (~oTool->DoUIService('GridWizard', self)) then $
                return, OBJ_NEW()
           end

        2: begin
            ; Ask the UI service to present the dialog to the user.
            ; The caller sets my data property before returning.
            void = oTool->DoUIService("HourGlassCursor", self)
            dummy = oTool->DoAction('Operations/Insert/Visualization')
            return, OBJ_NEW()
           end

        3: self._oData = OBJ_NEW()

        else: ; do nothing

    endcase

    ;;if new data object is created, add to data manager
    if ((self._oData ne oData) && OBJ_VALID(self._oData)) then begin
        oTool->AddByIdentifier, "/Data Manager", self._oData
    endif

    return, self._oData

end


;---------------------------------------------------------------------------
; IDLitopUnknownData::Handle
;
; Purpose:
;  Given a data object, this method will handle it.
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
;    obj_new() or an objarr()
;
function IDLitopUnknownData::Handle, oData

    compile_opt idl2, hidden

    nData = N_ELEMENTS(oData)

    if (nData eq 0) then $
        return, OBJ_NEW() ;; nothing in, nothing out --> success.

    oNewData = (nData eq 1) ? OBJ_NEW() : OBJARR(nData)

    ; Ok, just loop over the data objects and handle each.
    for i=0, nData-1 do begin
        oNewData[i] = self->_Handle(oData[i])
    endfor

    return, oNewData
end


;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitopUnknownData__define

    compile_opt idl2, hidden

    struc = {IDLitopUnknownData,       $
             inherits IDLitOperation, $
             _method: 0b, $
             _oData: OBJ_NEW() $
            }
end

