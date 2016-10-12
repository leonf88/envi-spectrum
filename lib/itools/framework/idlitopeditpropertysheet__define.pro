;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopEditPropertySheet
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
;   See IDLitopEditPropertySheet::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopEditPropertySheet::Init
;   IDLitopEditPropertySheet::GetProperty
;   IDLitopEditPropertySheet::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopEditPropertySheet::Init
;;
;; Purpose:
;; The constructor of the IDLitopEditPropertySheet object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopEditPropertySheet::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(/SKIP_MACRO, _EXTRA=_extra)
end


;-------------------------------------------------------------------------
;; IDLitopEditPropertySheet::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopEditPropertySheet::GetProperty, SELECTED_ITEMS=select, $
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
;; IDLitopEditPropertySheet::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopEditPropertySheet::DoAction, oTool

    compile_opt idl2, hidden

    ; Ask the UI service to present the property sheet dialog to the user.
     oTarget = oTool->GetSelectedItems(count=nTarg)

    ; If nothing selected, default to the Layer.
  if nTarg eq 0 then begin
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    oViewGroup = oWin->GetCurrentView()
    oTarget = OBJ_VALID(oViewGroup) ? $
      oViewGroup : oWin
  endif
    success = oTool->DoUIService('PropertySheet', oTarget[0])
    return, obj_new()
end


;-------------------------------------------------------------------------
pro IDLitopEditPropertySheet__define

    compile_opt idl2, hidden
    struc = {IDLitopEditPropertySheet, $
        inherits IDLitOperation}

end

