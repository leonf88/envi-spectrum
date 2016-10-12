; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopprintpreview__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopPrintPreview
;
; PURPOSE:
;   This file implements the File/Print Preview action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopPrintPreview::Init
;
;-;;---------------------------------------------------------------------------
;; IDLitopPrintPreview::Init
;;
;; Purpose:
;; The constructor of the IDLitopPrintPreview object.
;;
;; Parameters:
;; None.
;;
FUNCTION IDLitopPrintPreview::Init, _EXTRA=_extra
  compile_opt idl2, hidden

  IF (~self->IDLitOperation::Init(_EXTRA=_extra)) THEN $
    return, 0

  return, 1

END


;;---------------------------------------------------------------------------
;; IDLitopPrintPreviewer::DoAction
;
; Purpose:
;
; Parameters:
;   oTool
;
function IDLitopPrintPreview::DoAction, oTool

    compile_opt idl2, hidden

    status = oTool->DoUIService("PrintPreview",self)

    ;; Redo the draw if it got mangled by the dialog.
    oTool->RefreshCurrentWindow
    ; Cannot "undo" a print.
    return, obj_new() ;obj_new('IDLitCommand')

end


;-------------------------------------------------------------------------
pro IDLitopPrintPreview__define

    compile_opt idl2, hidden
    struc = {IDLitopPrintPreview, $
        inherits IDLitOperation}

end

