; $Id: //depot/idl/releases/IDL_80/idldir/lib/write_csv.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;----------------------------------------------------------------------------
function write_csv_convert, data

  compile_opt idl2, hidden
  
  switch (SIZE(data, /TYPE)) of
  
  7: begin   ; string type
      ; Always surround all strings with quotes, to avoid problems with
      ; commas and whitespace.
      data1 = '"'+data+'"'
      ; Now look for double-quote chars, which need to be escaped.
      hasQuote = WHERE(STRPOS(data, '"') ge 0, nQuote)
      if (nQuote gt 0) then begin
        d = data[hasQuote]
        for i=0,nQuote-1 do d[i] = STRJOIN(STRTOK(d[i],'"',/EXTRACT),'""')
        data1[hasQuote] = '"' + d + '"'
      endif
      return, data1
     end
     
  6: ; complex and dcomplex (fall thru)
  9: return, '"' + STRCOMPRESS(data, /REMOVE_ALL) + '"'
  
  else: begin
      ; regular numeric types
      return, STRTRIM(data, 2)
     end
     
  endswitch
  
end

;----------------------------------------------------------------------------
;+
; :Description:
;    The WRITE_CSV procedure writes data to a "comma-separated value"
;    (comma-delimited) text file.
;
;    This routine writes CSV files consisting of an optional line of column
;    headers, followed by columnar data, with commas separating each field.
;    Each row is a new record.
;
;    This routine is written in the IDL language. Its source code can be
;    found in the file write_csv.pro in the lib subdirectory of the IDL
;    distribution. 
;
; :Syntax:
;    WRITE_CSV, Filename, Data1 [, Data2,..., Data8]
;      [, HEADER=value]
;    
; :Params:
;    Filename
;      A string containing the name of the CSV file to write.
;
;    Data1...Data8
;      The data values to be written out to the CSV file. The data arguments
;      can have the following forms:
;      * Data1 can be an IDL structure, where each field contains a
;        one-dimensional array (a vector) of data that corresponds
;        to a separate column. The vectors must all have the same
;        number of elements, but can have different data types. If Data1
;        is an IDL structure, then all other data arguments are ignored.
;      * Data1 can be a two-dimensional array, where each column in the array
;        corresponds to a separate column in the output file. If Data1 is
;        a two-dimensional array, then all other data arguments are ignored.
;      * Data1...Data8 are one-dimensional arrays (vectors), where each vector
;        corresponds to a separate column in the output file. Each vector
;        can have a different data type.
;
; :Keywords:
;    HEADER
;      Set this keyword equal to a string array containing the column header
;      names. The number of elements in HEADER must match the number of
;      columns provided in Data1...Data8. If HEADER is not present,
;      then no header row is written.
;      
;      TABLE_HEADER
;      Set this keyword to a scalar string or string array containing extra table lines 
;      to be written at the beginning of the file. 
;      
; :History:
;   Written, CT, ITTVIS, Nov 2008
;   MP, ITTVIS, Oct 2009:  Added keyword SKIP_HEADER
;   
;-
pro write_csv, Filename, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, $
  HEADER=header, TABLE_HEADER=tableHeader

  compile_opt idl2

  ON_ERROR, 2         ;Return on error

  ON_IOERROR, ioerr

  if (N_PARAMS() lt 2) then $
    MESSAGE, 'Incorrect number of arguments.'

  isStruct = SIZE(Data1, /TYPE) eq 8
  isArray = SIZE(Data1, /N_DIM) eq 2

  if (SIZE(Filename,/TYPE) ne 7) then $
    MESSAGE, 'Filename must be a string.'
    
  if (N_ELEMENTS(Data1) eq 0) then $
    MESSAGE, 'Data1 must contain data.'
   
  ; Verify that all columns have the same number of elements.

  msg = 'Data fields must all have the same number of elements.'
  
  if (isStruct) then begin
  
    nfields = N_TAGS(Data1)
    nrows = N_ELEMENTS(Data1.(0))
    for i=1,nfields-1 do begin
      if (N_ELEMENTS(Data1.(i)) ne nrows) then $
        MESSAGE, msg
    endfor
    
  endif else if (isArray) then begin
  
    d = SIZE(Data1, /DIM)
    nfields = d[0]
    nrows = d[1]
    
  endif else begin  ; Individual data arguments
  
    nfields = N_PARAMS() - 1
    nrows = N_ELEMENTS(Data1)
    
    switch (nfields) of
    8: if (N_ELEMENTS(Data8) ne nrows) then MESSAGE, msg
    7: if (N_ELEMENTS(Data7) ne nrows) then MESSAGE, msg
    6: if (N_ELEMENTS(Data6) ne nrows) then MESSAGE, msg
    5: if (N_ELEMENTS(Data5) ne nrows) then MESSAGE, msg
    4: if (N_ELEMENTS(Data4) ne nrows) then MESSAGE, msg
    3: if (N_ELEMENTS(Data3) ne nrows) then MESSAGE, msg
    2: if (N_ELEMENTS(Data2) ne nrows) then MESSAGE, msg
    else:
    endswitch
    
  endelse


  ; Verify that the header (if provided) has the correct number of elements.
  
  nheader = N_Elements(header)
  if (nheader gt 0) then begin
    ; Quietly ignore null strings.
    if (ARRAY_EQUAL(header,'')) then begin
      nheader = 0
    endif else begin
      if (nheader ne nfields || SIZE(header,/type) ne 7) then begin
        MESSAGE, 'HEADER must be a string array of length equal to the number of columns.'
      endif
    endelse
  endif


  ; Start writing the file.
  
  OPENW, lun, filename, /GET_LUN
; What about handling COMMAS or QUOTES?!

  format = (nfields ge 2) ? '(' + STRTRIM(nfields-1,2)+'(A,","),A)' : '(A)'
  
  ; Printing out extra headers to csv file
  if n_elements(tableHeader) gt 0 then begin
    for i=0, n_elements(tableHeader)-1 do begin
      ;check if there is comma in the string
      posComma = stregex(tableHeader[i], ',')
      posQuote = stregex(tableHeader[i], '"')
      if (posComma eq -1) && (posQuote eq -1) then printf, lun, tableHeader[i], FORMAT=format else printf, lun, '"' + tableHeader[i] + '"', FORMAT=format
    endfor
  endif
  
  if (nheader gt 0) then begin
    PRINTF, lun, header, FORMAT=format
  endif
  
  
  if (isStruct) then begin  ; Structure fields
  
    strCopy = STRARR(nfields, nrows)

    for i=0,nfields-1 do begin
      strCopy[i,*] = WRITE_CSV_CONVERT(Data1.(i))
    endfor
    
    PRINTF, lun, strCopy, FORMAT=format
    
  endif else if (isArray) then begin  ; Two-dimensional array
  
    PRINTF, lun, WRITE_CSV_CONVERT(Data1), FORMAT=format
    
  endif else begin  ; Individual data arguments
  
    strCopy = STRARR(nfields, nrows)
    
    switch (nfields) of
    8: strCopy[7,*] = WRITE_CSV_CONVERT(Data8)
    7: strCopy[6,*] = WRITE_CSV_CONVERT(Data7)
    6: strCopy[5,*] = WRITE_CSV_CONVERT(Data6)
    5: strCopy[4,*] = WRITE_CSV_CONVERT(Data5)
    4: strCopy[3,*] = WRITE_CSV_CONVERT(Data4)
    3: strCopy[2,*] = WRITE_CSV_CONVERT(Data3)
    2: strCopy[1,*] = WRITE_CSV_CONVERT(Data2)
    1: strCopy[0,*] = WRITE_CSV_CONVERT(Data1)
    endswitch
    
    PRINTF, lun, strCopy, FORMAT=format

  endelse
  
  FREE_LUN, lun

  return
  
ioerr:
  ON_IOERROR, null
  if (N_ELEMENTS(lun) gt 0) then $
    FREE_LUN, lun
  MESSAGE, !ERROR_STATE.msg

end

