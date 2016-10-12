; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopmacrozoom__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMacroZoom
;
; PURPOSE:
;   This file implements the operation that zooms visualizations
;   in the current window's current view.  It is for use in macros
;   and history when a user uses the view zoom manipulator.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMacroZoom::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopMacroZoom::Init
;   IDLitopMacroZoom::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopMacroZoom::Init
;;
;; Purpose:
;; The constructor of the IDLitopMacroZoom object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopMacroZoom::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="View Zoom", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0


    self->RegisterProperty, 'ZOOM_PERCENTAGE', /FLOAT, $
        NAME='Zoom percentage', $
        DESCRIPTION='Zoom percentage'

    ; default value
    self._zoomPercentage = 100.

    return, 1

end





;-------------------------------------------------------------------------
; IDLitopMacroZoom::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroZoom::GetProperty,        $
    ZOOM_PERCENTAGE=zoomPercentage, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if (ARG_PRESENT(zoomPercentage)) then $
        zoomPercentage = self._zoomPercentage

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopMacroZoom::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopMacroZoom::SetProperty,      $
    ZOOM_PERCENTAGE=zoomPercentage, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(zoomPercentage) ne 0) then begin
        self._zoomPercentage = zoomPercentage
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopMacroZoom::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopMacroZoom object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopMacroZoom::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopMacroZoom::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;
function IDLitopMacroZoom::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()
    idTool = oTool->GetFullIdentifier()

    oCurrView = oWin->GetCurrentView()
    oSetProp = oTool->GetService('SET_PROPERTY')
    if (OBJ_VALID(oSetProp)) then begin
        oCmd = oSetProp->DoAction(oTool, oCurrView->GetFullIdentifier(), $
            'CURRENT_ZOOM', self._zoomPercentage/100.)
        ; No need to change name of command, since commands from macro
        ; will be grouped and named with the name of the macro.
        if (OBJ_VALID(oCmd)) then $
            return, oCmd
    endif


    return, obj_new()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopMacroZoom__define

    compile_opt idl2, hidden

    void = {IDLitopMacroZoom, $
            inherits IDLitOperation, $
            _zoomPercentage: 0.0D    $
                        }
end

