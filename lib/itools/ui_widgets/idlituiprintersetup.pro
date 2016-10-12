; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiprintersetup.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIPrinterSetup
;
; PURPOSE:
;   Provides the user interface to modify printer settings. Basically
;   just calls dialog_printersetup
;
; Parameters;
;   oUI      - The UI object
;
;   oPrinter - The printer device
;
; Return Value:
;   1 - okay
;   0 - cancel


;-------------------------------------------------------------------------
function IDLitUIPrinterSetup, oUI, oPrinter

   compile_opt idl2, hidden

   ;; Basically that the text in the error object and display an
   ;; dialog_message()

   if(obj_valid(oPrinter) eq 0)then $
     return, 0

   oUI->GetProperty, GROUP_LEADER=wLeader

   status = dialog_printersetup(oPrinter, $
                                dialog_parent=wLeader)

   return, status
end

