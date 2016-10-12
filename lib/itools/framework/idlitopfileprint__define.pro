; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopfileprint__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopFilePrint
;
; PURPOSE:
;   This file implements the File/Print action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopFilePrint::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopFilePrint::Init
;;
;; Purpose:
;; The constructor of the IDLitopFilePrint object.
;;
;; Parameters:
;; None.
;;
;function IDLitopFilePrint::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;;---------------------------------------------------------------------------
;; IDLitopFilePrint::Init
;;
;; Purpose:
;; The constructor of the IDLitopFilePrint object.
;;
;; Parameters:
;; None.
;;
FUNCTION IDLitopFilePrint::Init, _EXTRA=_extra

  compile_opt idl2, hidden

  IF (~self->IDLitOperation::Init(_EXTRA=_extra)) THEN $
    return, 0

  self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

  self->RegisterProperty, 'PRINT_ORIENTATION', $
                          ENUMLIST=['Portrait','Landscape'], $
                          NAME='Window Orientation', $
                          DESCRIPTION='Orientation'
  self->RegisterProperty, 'PRINT_CENTER', /BOOLEAN, NAME='Center print', $
                          DESCRIPTION='Center print on paper'
  self->RegisterProperty, 'PRINT_XMARGIN', /FLOAT, $
                          NAME='X Margin', $
                          DESCRIPTION='X margin'
  self->RegisterProperty, 'PRINT_YMARGIN', /FLOAT, $
                          NAME='Y Margin', $
                          DESCRIPTION='Y margin'
  self->RegisterProperty, 'PRINT_WIDTH', /FLOAT, $
                          NAME='Width', $
                          DESCRIPTION='Width'
  self->RegisterProperty, 'PRINT_HEIGHT', /FLOAT, $
                          NAME='Height', $
                          DESCRIPTION='Height'
  self->RegisterProperty, 'PRINT_UNITS', ENUMLIST=['Inches','Centimeters'], $
                          NAME='Printer units', $
                          DESCRIPTION='Units for offsets and sizes'


  self._print_center = 1b

  return, 1

END


;;----------------------------------------------------------------------------
;; IDLitopFilePrint::GetProperty
;;
;; Purpose:
;;   This procedure method retrieves the
;;   value of a property or group of properties.
;;
;; Arguments:
;;   None.
;;
;; Keywords:
;;   Any registered property
;;
PRO IDLitopFilePrint::GetProperty, $
    PRINT_ORIENTATION=print_orientation, $
    PRINT_XMARGIN=print_xmargin, $
    PRINT_YMARGIN=print_ymargin, $
    PRINT_WIDTH=print_width, $
    PRINT_HEIGHT=print_height, $
    PRINT_UNITS=print_units, $
    PRINT_CENTER=print_center, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    IF (ARG_PRESENT(print_orientation)) THEN $
      print_orientation = self._print_orientation

    IF (ARG_PRESENT(print_xmargin)) THEN $
      print_xmargin = self._print_xmargin

    IF (ARG_PRESENT(print_ymargin)) THEN $
      print_ymargin = self._print_ymargin

    IF (ARG_PRESENT(print_width)) THEN $
      print_width = self._print_width

    IF (ARG_PRESENT(print_height)) THEN $
      print_height = self._print_height

    IF (ARG_PRESENT(print_units)) THEN $
      print_units = self._print_units

    IF (ARG_PRESENT(print_center)) THEN $
      print_center = self._print_center

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra

END


;;----------------------------------------------------------------------------
;; IDLitopFilePrint::SetProperty
;;
;; Purpose:
;;   This procedure method sets the
;;   value of a property or group of properties.
;;
;; Arguments:
;;   None.
;;
;; Keywords:
;;   Any registered property
;;
PRO IDLitopFilePrint::SetProperty, $
    PRINT_ORIENTATION=print_orientation, $
    PRINT_XMARGIN=print_xmargin, $
    PRINT_YMARGIN=print_ymargin, $
    PRINT_WIDTH=print_width, $
    PRINT_HEIGHT=print_height, $
    PRINT_UNITS=print_units, $
    PRINT_CENTER=print_center, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(print_orientation) gt 0) then $
        self._print_orientation = print_orientation

    if (N_ELEMENTS(print_xmargin) gt 0) then $
      self._print_xmargin = print_xmargin

    if (N_ELEMENTS(print_ymargin) gt 0) then $
      self._print_ymargin = print_ymargin

    if (N_ELEMENTS(print_width) gt 0) then $
      self._print_width = print_width

    if (N_ELEMENTS(print_height) gt 0) then $
      self._print_height = print_height

    if (N_ELEMENTS(print_units) gt 0) then $
      self._print_units = print_units

    if (N_ELEMENTS(print_center) gt 0) then begin
      self._print_center = print_center
      self->SetPropertyAttribute, ['PRINT_XMARGIN', 'PRINT_YMARGIN'], $
        SENSITIVE=~self._print_center
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra

END


;;---------------------------------------------------------------------------
;; IDLitopFilePrint::DoAction
;
; Purpose:
;
; Parameters:
;   oTool
;
function IDLitopFilePrint::DoAction, oTool

    compile_opt idl2, hidden

    ;; Get the printer
    oSysPrint = oTool->GetService("PRINTER")

    ;; Init the printer
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()
    ;; reset print service
    oSysPrint->SetProperty, /default_scale
    status = oSysPrint->_InitializeOutputDevice(oWin)

    if(status eq 0)then return, obj_new()

    self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI

    if (showExecutionUI) then BEGIN
      status = oTool->DoUIService("PrinterSetup", oSysPrint->GetDevice())
      if(status eq 0)then return, obj_new()
      ;; Redo the draw if it got mangled by the dialog.
      oTool->RefreshCurrentWindow
    ENDIF

    void = oSysPrint->DoAction(oTool, $
        PRINT_ORIENTATION=self._print_orientation, $
        PRINT_XMARGIN=self._print_xmargin, $
        PRINT_YMARGIN=self._print_ymargin, $
        PRINT_WIDTH=self._print_width, $
        PRINT_HEIGHT=self._print_height, $
        PRINT_UNITS=self._print_units, $
        PRINT_CENTER=self._print_center)

    return, OBJ_NEW()   ; Cannot undo a print.
end


;-------------------------------------------------------------------------
pro IDLitopFilePrint__define

    compile_opt idl2, hidden
    struc = {IDLitopFilePrint, $
        inherits IDLitOperation, $
        _print_orientation: 0b, $
        _print_units: 0b, $
        _print_center: 0b, $
        _print_xmargin: 0.0d, $
        _print_ymargin: 0.0d, $
        _print_width: 0.0d, $
        _print_height: 0.0d $
        }

end

