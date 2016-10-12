; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics_times.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	GRAPHICS_TIMES
;
; PURPOSE:
;	This is a wrapper on the procedure GRAPHICS_TIMES_INTERNAL contained
;	in the file time_test.pro. Please see that file for further
;	information. The reason for doing it this way is so that the
;	various time_test and graphics_test routines can stay in a single
;	file while still being easily callable.
;-


pro graphics_times, filename

  ; Get TIME_TEST.PRO compiled
  resolve_routine, 'time_test', /NO_RECOMPILE

  ; Run the test
  if (n_params() eq 1) then begin
      graphics_times_internal, filename
  endif else begin
      graphics_times_internal
  endelse
end
