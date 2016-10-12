; $Id: //depot/idl/releases/IDL_80/idldir/lib/printd.pro#1 $
;
; Copyright (c) 1989-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	PRINTD
;
; PURPOSE:
;	Display the contents of the directory stack maintained by the
;	PUSHD and POPD User Library procedures.
;
; CALLING SEQUENCE:
;	PRINTD
;
; OUTPUTS:
;	PRINTD lists the contents of the directory stack on the default
;	output device.
;
; COMMON BLOCKS:
;	DIR_STACK:  Contains the stack.
;
; MODIFICATION HISTORY:
;	17, July, 1989, Written by AB, RSI.
;-
;
;
pro printd

COMMON DIR_STACK, DEPTH, STACK

on_error,2                      ;Return to caller if an error occurs
if (n_elements(DEPTH) eq 0) then depth = 0

CD, CURRENT=current
print, 'Current Directory: ', current

if (DEPTH eq 0) then begin
  message, 'Directory stack is empty.'
endif else begin
  print, 'Directory Stack Contents:'
  for i = 0, DEPTH-1 do print,format='(I3,") ", A)', I, STACK[I]
endelse

end
