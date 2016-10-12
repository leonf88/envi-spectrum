; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitoppropertysheet__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopPropertySheet
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a property sheet is used.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopPropertySheet::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopPropertySheet::Init
;   IDLitopPropertySheet::GetProperty
;   IDLitopPropertySheet::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopPropertySheet::Init
;;
;; Purpose:
;; The constructor of the IDLitopPropertySheet object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopPropertySheet::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(/SKIP_MACRO, _EXTRA=_extra)
end


;-------------------------------------------------------------------------
;; IDLitopPropertySheet::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopPropertySheet::GetProperty, SELECTED_ITEMS=select, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(select)) then begin
        oTool = self->GetTool()
        oTarget = oTool->GetSelectedItems()

        if ~OBJ_VALID(oTarget[0]) then begin
            oWindow = oTool->GetCurrentWindow()
            if (~OBJ_VALID(oWindow)) then $
                return
            oViewGroup = oWindow->GetCurrentView()
            oTarget = OBJ_VALID(oViewGroup) ? $
              oViewGroup->GetCurrentLayer() : oWindow
        endif

        ntarget = N_ELEMENTS(oTarget)
        select = STRARR(ntarget)
        for i=0,ntarget-1 do begin
            if (OBJ_VALID(oTarget[i])) then $
                select[i] = oTarget[i]->GetFullIdentifier()
        endfor

    endif
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;;---------------------------------------------------------------------------
;; IDLitopPropertySheet::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopPropertySheet::DoAction, oTool

    compile_opt idl2, hidden

    ; Ask the UI service to present the property sheet dialog to the user.
    success = oTool->DoUIService('EditProperties', self)
    return, obj_new()
end


;-------------------------------------------------------------------------
pro IDLitopPropertySheet__define

    compile_opt idl2, hidden
    struc = {IDLitopPropertySheet, $
        inherits IDLitOperation}

end

