; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5t_enum_values_to_names.pro#1 $
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5T_ENUM_VALUES_TO_NAMES
;
; PURPOSE:
;   Converts values returned from H5D_READ to names
;
; CALLING SEQUENCE:
;   result = H5T_ENUM_VALUES_TO_NAMES(datatype_id, values)
;
; PARAMETERS:
;   DATATYPE_ID : An integer giving the identifier of the enumeration
;   datatype.
;
;   VALUES : A integer array of data returned from H5D_READ.
;
; KEYWORD PARAMETERS:
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, July 2005
;   Modified:
;
;-

;-------------------------------------------------------------------------
FUNCTION h5t_enum_values_to_names, datatype_id, values
  compile_opt idl2

  on_error, 2
  catch, err
  IF (err NE 0) THEN BEGIN
    catch, /cancel
    message, strmid(!error_state.msg,strpos(!error_state.msg,':')+2)
  ENDIF

  ;; Get datatype name/value pairs
  struct = H5T_ENUM_GET_DATA(datatype_id)

  names = strarr(n_elements(values))
  FOR i=0,n_elements(names)-1 DO BEGIN
    wh = where(values[i] EQ struct.value, c)
    IF (c GT 0) THEN names[i] = struct[wh[0]].name
  ENDFOR

  return, names

END
