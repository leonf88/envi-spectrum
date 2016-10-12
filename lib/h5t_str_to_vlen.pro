; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5t_str_to_vlen.pro#1 $
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5T_STR_TO_VLEN
;
; PURPOSE:
;   Converts an IDL string array to an IDL_H5_VLEN array of strings
;
; CALLING SEQUENCE:
;   result = H5T_STR_TO_VLEN(array)
;
; PARAMETERS:
;   ARRAY : A string array
;
; KEYWORD PARAMETERS:
;   NO_COPY : If set the original data will be lost after the routine
;   exits
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, July 2005
;   Modified:
;
;-

;-------------------------------------------------------------------------
FUNCTION h5t_str_to_vlen, array, no_copy=noCopy
  compile_opt idl2

  on_error, 2
  catch, err
  IF (err NE 0) THEN BEGIN
    catch, /cancel
    message, !error_state.msg
  ENDIF

  ;; verify proper array type
  IF (size(array, /type) NE 7) THEN $
    message, 'Incorrect input array'

  n = n_elements(array) 
  struct = replicate({IDL_H5_VLEN, pdata:ptr_new()},n)

  FOR i=0,n-1 DO $
    struct[i].pdata = ptr_new(array[i])

  IF keyword_set(noCopy) THEN void = temporary(array)

  return, struct

END
