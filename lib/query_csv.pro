; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_csv.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;----------------------------------------------------------------------------
;+
; :Description:
;    The QUERY_CSV function tests a file for compatibility with READ_CSV
;    and returns an optional structure containing information about the file.
;       
;    This routine is written in the IDL language. Its source code can be
;    found in the file query_csv.pro in the lib subdirectory of the IDL
;    distribution. 
;
; :Params:
;    Filename
;      A scalar string containing the full pathname of the file to query. 
;
;    Info
;      Set this optional argument to a named variable in which to return
;      an anonymous structure containing information about the file.
;      This structure is valid only when the return value of the function
;      is 1. The structure has the following fields:
;      
;         * NAME - String - File name, including full path 
;         * TYPE - String - File format (always 'CSV')
;         * LINES - Long64 - Number of lines
;         * NFIELDS - Long - Number of columns
;         
; :Keywords:
;      
; :History:
;   Written, CT, ITTVIS, Oct 2008
;   
;-
function QUERY_CSV, Filename, Info

  compile_opt idl2, hidden

  ON_ERROR, 2         ;Return on error

  CATCH, err
  if (err ne 0) then begin
    CATCH, /CANCEL
    ; Always quietly return from a query.
    return, 0
  endif

  info = FILE_INFO(filename)
  
  ; Empty file
  if (info.size eq 0) then $
    return, 0
  
  data = READ_CSV(filename, NUM_RECORDS=100)

  info = { $
    NAME: info.name, $
    TYPE: 'CSV', $
    LINES: FILE_LINES(filename), $
    NFIELDS: N_TAGS(data) $
    }
  
  return, 1
end

