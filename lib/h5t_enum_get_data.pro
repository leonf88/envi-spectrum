; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5t_enum_get_data.pro#1 $
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5T_ENUM_GET_DATA
;
; PURPOSE:
;   Retrieves all the data from an enumeration datatype and bundles it
;   up into an array of structures.
;
; CALLING SEQUENCE:
;   result = H5T_ENUM_GET_DATA(datatype_id)
;
; PARAMETERS:
;   DATATYPE_ID : An integer giving the identifier of the enumeration
;   datatype.
;
; KEYWORD PARAMETERS:
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, June 2005
;   Modified:
;
;-

;-------------------------------------------------------------------------
FUNCTION h5t_enum_get_data, datatype_id
  compile_opt idl2

  on_error, 2
  catch, err
  IF (err NE 0) THEN BEGIN
    catch, /cancel
    message, strmid(!error_state.msg,strpos(!error_state.msg,':')+2)
  ENDIF

  ;; Build structure array for returning data
  nmem = H5T_GET_NMEMBERS(datatype_id)
  struct = {IDL_H5_ENUM, NAME:'', VALUE:0}
  result = replicate(struct, nmem)

  FOR i=0,nmem-1 DO BEGIN
    result[i].value = H5T_GET_MEMBER_VALUE(datatype_id, i)
    result[i].name = H5T_GET_MEMBER_NAME(datatype_id, i)
  ENDFOR

  return, result

END
