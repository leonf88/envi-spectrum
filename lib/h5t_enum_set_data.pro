; $Id: //depot/idl/releases/IDL_80/idldir/lib/h5t_enum_set_data.pro#1 $
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   H5T_ENUM_SET_DATA
;
; PURPOSE:
;   Sets multiple name/value data pairs on an enumeration datatype.
;
; CALLING SEQUENCE:
;   H5T_ENUM_SET_DATA, datatype_id, data, values
;
; PARAMETERS:
;   DATATYPE_ID - An integer giving the identifier of the enumeration
;                 datatype.
;
;   DATA - If Data is a string array then Data gives the names of the
;          corresponding members and Values is required. If Data is an
;          array of structures, each with two fields, NAME, a string,
;          and VALUE, an integer, then Data supplies all the needed
;          information and Values is ignored.
;
;   VALUES - An integer array giving the values of the corresponding
;            members.  This is needed only if Data is a string array.

; KEYWORD PARAMETERS:
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, June 2005
;   Modified:
;
;-

;-------------------------------------------------------------------------
PRO h5t_enum_set_data, datatype_id, data, values
  compile_opt idl2

  on_error, 2
  catch, err
  IF (err NE 0) THEN BEGIN
    catch, /cancel
    message, strmid(!error_state.msg,strpos(!error_state.msg,':')+2)
  ENDIF

  ;; If data is a structure of proper type, get names/values from it,
  ;; otherwise get names from data and values from values
  IF ((size(data,/type) EQ 8) && $
      array_equal(tag_names(data),['NAME','VALUE'])) THEN BEGIN
    names = data.name
    values = data.value
  ENDIF ELSE BEGIN
    names = data
    values = values
  ENDELSE

  ;; throw error if number of names and values do not match
  IF (n_elements(names) NE n_elements(values)) THEN $
    message, 'Number of elements in Data and Values do not match'

  FOR i=0,n_elements(names)-1 DO $
    H5T_ENUM_INSERT, datatype_id, names[i], values[i]

END
