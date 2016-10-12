; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_csv.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;----------------------------------------------------------------------------
function read_csv_fieldnames, fieldCount

  compile_opt idl2, hidden
  
  digits_str = STRTRIM(STRING(STRLEN(STRTRIM(STRING(fieldCount),2))),2)
  fstr = '(i' + digits_str + '.' + digits_str + ')'
  fieldNames   = 'field' + STRING(LINDGEN(fieldCount)+1, FORMAT=fstr)
  
  return, fieldNames
end

;----------------------------------------------------------------------------
;+
; :Description:
;    The READ_CSV function reads data from a "comma-separated value"
;    (comma-delimited) text file into an IDL structure variable.
;
;    This routine handles CSV files consisting of an optional line of column
;    headers, followed by columnar data, with commas separating each field.
;    Each row is assumed to be a new record.
;    
;    The READ_CSV routine will automatically return each column (or field)
;    in the correct IDL variable type using the following rules:
;    
;       * Long - All data within that column consists of integers,
;           all of which are smaller than the maximum 32-bit integer.
;       * Long64 - All data within that column consists of integers,
;           with at least one greater than the maximum 32-bit integer.
;       * Double - All data within that column consists of numbers, at least
;           one of which has either a decimal point or an exponent.
;       * String - All data which does not fit into one of the above types.
;       
;    This routine is written in the IDL language. Its source code can be
;    found in the file read_csv.pro in the lib subdirectory of the IDL
;    distribution. 
;
; :Syntax:
;    Result = READ_CSV( Filename
;      [, COUNT=variable] [, HEADER=variable] [, MISSING_VALUE=value]
;      [, NUM_RECORDS=value] [, RECORD_START=value]
;      [, N_TABLE_HEADER=value] [,TABLE_HEADER=variable]
;      )
;    
; :Params:
;    Filename
;      A string containing the name of a CSV file to read into an IDL variable.
;
; :Keywords:
;    COUNT
;      Set this keyword equal to a named variable that will contain the
;      number of records read.
;      
;    HEADER
;      Set this keyword equal to a named variable that will contain the
;      column headers as a vector of strings. If no header exists,
;      an empty scalar string is returned.
;      
;    MISSING_VALUE
;      Set this keyword equal to a value used to replace any missing
;      floating-point or integer data. The default value is 0.
;      
;    NUM_RECORDS
;      Set this keyword equal to the number of records to read.
;      The default is to read all records in the file.
;      
;    RECORD_START
;      Set this keyword equal to the index of the first record to read.
;      The default is the first record of the file (record 0).
;      
;    N_TABLE_HEADER    
;       Set this keyword to the number of lines to skip at the beginning of the file, 
;       not including the HEADER line. These extra lines may be retrieved by using the TABLE_HEADER keyword.
;       
;    TABLE_HEADER
;       Set this keyword to a named variable in which to return an array of strings 
;       containing the extra table headers at the beginning of the file, as specified by N_TABLE_HEADER.
;      
; :History:
;   Written, CT, ITTVIS, Oct 2008
;   MP, ITTVIS, Oct 2009: Added keyword NSKIP and SKIP_HEADER
;   
;-
function read_csv, Filename, $
  COUNT=count, $
  HEADER=header, $
  MISSING_VALUE=missingValue, $
  NUM_RECORDS=numRecordsIn, $
  RECORD_START=recordStart, $
  N_TABLE_HEADER=nTableHeader, $
  TABLE_HEADER=tableHeader, $
  _EXTRA=_extra  ; needed for iOpen

  compile_opt idl2, hidden

  ON_ERROR, 2         ;Return on error

  CATCH, err
  if (err ne 0) then begin
    CATCH, /CANCEL
    if (N_ELEMENTS(lun) gt 0) then $
      FREE_LUN, lun
    if (MAX(PTR_VALID(pData)) eq 1) then $
      PTR_FREE, pData
    MESSAGE, !ERROR_STATE.msg
  endif

  header = ''

  if (N_PARAMS() eq 0) then $
    MESSAGE, 'Incorrect number of arguments.'
  
  ; Empty file
  if (FILE_TEST(filename, /ZERO_LENGTH)) then $
    return, 0

;Set appropriate dataStart, where dataStart includes column header.
if ~keyword_set(nTableHeader) then dataStart=0 else dataStart=nTableHeader
  
  OPENR, lun, filename, /GET_LUN

  str = ''
  tableHeader=''
  for i=0L, dataStart do begin
    READF, lun, str
    if i ne dataStart then begin
      pos = stregex(str, '"') 
      if pos ne 0 then begin ; string not enclosed in quotes
        pos = stregex(str, ',+'); check for extra commas
        if pos ne -1 then str = strmid(str, 0, pos) 
      endif else begin
        ; string enclosed in commas
        pos = stregex(str, '",+') ; check for extra commas
        if pos ne -1 then str = strmid(str, 1, pos-1) else str = strjoin(strsplit(str, '"', /EXTRACT))
      endelse
      
      if i eq 0 then tableHeader = str else tableHeader = [tableHeader, str]
    endif
  endfor
  
  while (STRLEN(STRTRIM(str,2)) eq 0) do begin
    READF, lun, str
  endwhile
  
  FREE_LUN, lun
  
  ; We need to count the number of fields.
  ; First remove escaped quote characters, which look like "".
  str = STRJOIN(STRTOK(str, '""', /REGEX, /EXTRACT))
  ; Now remove quoted strings, which might contain bogus commas.
  str = STRJOIN(STRTOK(str,'"[^"]*"', /REGEX, /EXTRACT))
  ; Finally, count the number of commas.
  fieldCount = N_Elements(STRTOK(str, ',', /PRESERVE_NULL))

  fieldNames = Read_CSV_Fieldnames(fieldCount)

  template = { $
    version:         1.0, $
    dataStart:       dataStart, $  ; specified as a keyword below
    delimiter:       BYTE(','), $  ; comma-separated
    missingValue:    0, $
    commentSymbol:   '', $
    fieldCount:      fieldCount, $
    fieldTypes:      REPLICATE(7L, fieldCount), $
    fieldNames:      fieldNames, $
    fieldLocations:  LONARR(fieldCount), $  ; ignored for csv
    fieldGroups:     LINDGEN(fieldCount) $  ; ungrouped
  }

  if (N_Elements(numRecordsIn)) then $
    numRecords = numRecordsIn[0] + 1

  data = READ_ASCII(filename, /CSV, $
    COUNT=count, $
    DATA_START=dataStart, $
    NUM_RECORDS=numRecords, $
    RECORD_START=recordStart, $
    TEMPLATE=template)

  if (N_TAGS(data) eq 0) then $
    MESSAGE, 'File "' + filename + '" is not a valid CSV file.', /NONAME

  ; Eliminate empty columns
  columnLen = LONARR(fieldCount)
  firstNonEmptyRow = count - 1
  lastNonEmptyRow = 0L

  for i=0L,fieldCount-1 do begin
    data.(i) = STRTRIM(data.(i), 2)
    lengths = STRLEN(data.(i))
    good = WHERE(lengths gt 0, ngood)
    if (ngood gt 0) then begin
      firstNonEmptyRow = firstNonEmptyRow < MIN(good)
      lastNonEmptyRow = lastNonEmptyRow > MAX(good)
      columnLen[i] = MAX(lengths)
    endif
  endfor

  nColumns = LONG(TOTAL(columnLen gt 0))
  
  ; All of the fields were empty.
  if (nColumns eq 0) then begin
    return, 0
  endif
  
  count = lastNonEmptyRow - firstNonEmptyRow + 1

  ; Convert each field to a pointer, for easier manipulation.
  j = 0L
  pData = PTRARR(nColumns)
  for i=0L,fieldCount-1 do begin
    if (columnLen[i] eq 0) then continue
    columnLen[j] = columnLen[i]
    pData[j] = PTR_NEW((data.(i))[firstNonEmptyRow:lastNonEmptyRow])
    j++
  endfor
  
  data = 0
  columnLen = columnLen[0:nColumns-1]

  ; Attempt to determine the data types for each field.
  types = BYTARR(nColumns)
  if (count gt 1) then begin
  
    for j=0,nColumns-1 do begin
    
      subdata = (*pData[j])[1:(100 < (count-1))]
      
      ON_IOERROR, skip1

      tmpDouble = DOUBLE(subdata)
      tmpLong64 = LONG64(subdata)
      tmpLong = LONG(subdata)
      hasDecimal = MAX(STRPOS(subdata, '.')) ge 0

      if (hasDecimal || ~ARRAY_EQUAL(tmpLong64, tmpDouble)) then begin
        ; Double
        types[j] = 5
      endif else begin
        ; Long or Long64
        types[j] = ARRAY_EQUAL(tmpLong, tmpLong64) ? 3 : 14
      endelse
      
skip1:
      ON_IOERROR, null
      
    endfor
    
    ; Attempt to determine if the first line is a header line.
    isFirstLineText = 0
    for j=0,nColumns-1 do begin
      if (types[j] ne 0) then begin
        ON_IOERROR, skip2
        ; If we fail to convert the first item to the type for that column,
        ; then assume that it is a "string" column header.
        result = FIX((*pData[j])[0], TYPE=types[j])
        continue
skip2:
        ON_IOERROR, null
        isFirstLineText = 1
        break
      endif
    endfor
    
    nheader = isFirstLineText ? 1 : 0
    
    fieldNames = Read_CSV_Fieldnames(nColumns)
    
    if (nheader gt 0) then begin
      count -= nheader
      header = STRARR(nColumns, nheader)
      for j=0,nColumns-1 do begin
        header[j,*] = (*pData[j])[0:nheader-1]
      endfor
    endif else begin
      ; If NUM_RECORDS was specified, we needed to read one extra record,
      ; in case there was a header. Since there was no header, get rid
      ; of the extra record.
      if (N_Elements(numRecordsIn)) then count--
    endelse
    
    hasMissingValue = N_Elements(missingValue) eq 1 && $
      missingValue[0] ne 0
    
    ; Do the actual type conversion.
    
    for j=0,nColumns-1 do begin
    
      *pData[j] = (*pData[j])[nheader:nheader+count-1]
      
      if (types[j] ne 0) then begin
      
        if (hasMissingValue) then begin
          iMiss = WHERE(*pData[j] eq '', nmiss)
        endif
        
        ON_IOERROR, skip3
        ; Do the actual type conversion.
        *pData[j] = FIX(*pData[j], TYPE=types[j])
        
        if (hasMissingValue && nmiss gt 0) then begin
          (*pData[j])[iMiss] = missingValue[0]
        endif
skip3:
        ON_IOERROR, null
      endif
    endfor
    

  endif   ; count gt 1
  
  
  ; Create the final anonymous structure.
  data = READ_ASCII_CREATE_STRUCT(fieldNames, pData)
  
  PTR_FREE, pData
  
  return, data
end

