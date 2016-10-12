; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5t_vlen_to_str.pro#1 $
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5T_VLEN_TO_STR
;
; PURPOSE:
;   Converts an IDL_H5_VLEN array of strings to an IDL string array
;
; CALLING SEQUENCE:
;   result = H5T_VLEN_TO_STR(array)
;
; PARAMETERS:
;   ARRAY : An array of IDL_H5_VLEN structures pointing to strings
;
; KEYWORD PARAMETERS:
;   PTR_FREE : If set then free the pointers in the IDL_H5_VLEN array
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, July 2005
;   Modified:
;
;-

;-------------------------------------------------------------------------
FUNCTION h5t_vlen_to_str, array, ptr_free=ptrFree
  compile_opt idl2

  on_error, 2
  catch, err
  IF (err NE 0) THEN BEGIN
    catch, /cancel
    message, !error_state.msg
  ENDIF

  ;; verify proper structure type
  IF ((size(array, /type) NE 8) || $
      (tag_names(array, /structure_name) NE 'IDL_H5_VLEN')) THEN $
    message, 'Incorrect input array'

  n = n_elements(array) 
  str = strarr(n)
  FOR i=0,n-1 DO $
    str[i] = *array[i].pdata

  IF keyword_set(ptrFree) THEN ptr_free, array.pdata

  return, str

END
