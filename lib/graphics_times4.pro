; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics_times4.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
; GRAPHICS_TIMES4
;
; PURPOSE:
; This is a wrapper on the procedure GRAPHICS_TIMES4_INTERNAL contained
; in the file time_test.pro. Please see that file for further
; information. The reason for doing it this way is so that the
; various time_test and graphics_test routines can stay in a single
; file while still being easily callable.
;---
PRO GRAPHICS_TIMES4, filename

  ; Get TIME_TEST.PRO compiled
  RESOLVE_ROUTINE, 'time_test', /NO_RECOMPILE
  
  ; Run the test
  IF (N_PARAMS() EQ 1) THEN BEGIN
    GRAPHICS_TIMES4_INTERNAL, filename
  ENDIF ELSE BEGIN
    GRAPHICS_TIMES4_INTERNAL
  ENDELSE
  
END
;---