; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_ascii.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   QUERY_ASCII
;
; PURPOSE:
;   Query an ASCII format file and return a structure
;   containing information about the file.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_ASCII(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the file to query.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the query was successful (and the
;   file type was correct) or 0 on failure.  The return status will indicate
;   failure for files that contain formats that are not supported by the
;   corresponding READ_ routine, even though the file may be valid outside
;   the IDL environment. A file is considered to be a valid ASCII file
;   if 80% of the first 32768 characters have byte values in the range
;   7-13 or 32-127. If there is a byte-order marker (BOM) at the beginning
;   of the file, and it is marked as UTF-8 or UTF-16, then this is also
;   considered to be a valid ASCII file.
;
;   Info:   An anonymous structure containing information about the file.
;       This structure is valid only when the return value of the function
;       is 1.  The Info structure has the following fields:
;
;       Field       IDL type    Description
;       -----       --------    -----------
;       NAME        String      File name (including full path)
;       TYPE        String      File format (always 'ASCII')
;       BYTES       Long64      File length in bytes
;       LINES       Long64      Number of lines
;       WORDS       Long64      Number of words
;
;   WORDS are assumed to be separated by whitespace, including
;   carriage returns, line feeds, tabs, and spaces.
;
;   Tip: If you have a data file that contains only columns of data
;       (without any header lines), then the number of LINES divided
;       by the number of WORDS should give you the number of columns.
;
; EXAMPLE:
;   To retrieve information from a text file, enter:
;
;       file = FILEPATH("irreg_grid1.txt", SUBDIR=['examples', 'data'])
;       result = QUERY_ASCII(file, info)
;       if (result) then HELP, info, /STRUCT $
;       else PRINT, 'File not found or file is not a valid ASCII file.'
;
;
; MODIFICATION HISTORY:
;   Written: CT, RSI, Dec 2004
;   Modified:
;
;-
;

;--------------------------------------------------------------------
function query_ascii_verify, filename

    compile_opt idl2, hidden

    ; Set up error handling
    CATCH, errorStatus
    if (errorStatus ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, /RESET
        if (N_ELEMENTS(unit) GT 0 && unit ne 0) then $
            FREE_LUN, unit
        RETURN, 0  ; failure
    endif

    OPENR, unit, filename, /GET_LUN
    finfo = FSTAT(unit)

    if (finfo.size eq 0) then begin
        if (N_ELEMENTS(unit) GT 0 && unit ne 0) then $
            FREE_LUN, unit
        RETURN, 0  ; failure
    endif

    ; Read the first few characters.
    n = 32768 < finfo.size
    data = BYTARR(n, /NOZERO)

    READU, unit, data
    FREE_LUN, unit

    ; Look for a byte-order marker (an encoding marker).
    ; If we see a BOM, then assume we have a text file with UTF characters.
    ; We cannot check for non-ASCII characters in this case, since most
    ; UTF-8 or UTF-16 bytes will be > 127. So just return "success".
    if (n gt 3) then begin
      isBOM = $
        ARRAY_EQUAL(data[0:2], [239b, 187b, 191b]) || $  ; UTF-8
        ARRAY_EQUAL(data[0:1], [254b, 255b]) || $        ; UTF-16 (big endian)
        ARRAY_EQUAL(data[0:1], [255b, 254b])             ; UTF-16 (little endian)
      if (isBOM) then return, 1
    endif

    ; Set non-ASCII values in lookup table.
    lut = BYTARR(256)
    ; Assume these are valid ASCII chars.
    lut[7:13]   = 1b
    lut[32:127] = 1b

    n = N_ELEMENTS(data)
    return, (TOTAL(lut[data])/n ge 0.8) ? 1 : 0

end


;--------------------------------------------------------------------
function query_ascii_words, filename

    compile_opt idl2, hidden

    ON_ERROR, 2

    OPENR, unit, filename, /GET_LUN
    finfo = FSTAT(unit)

    ; It is about twice as fast to read in chunks of lines,
    ; instead of a single line.
    bytes = 0ll
    words = 0ll
    prev_white = 1b

    ; Find CR/LF, tabs, and spaces.
    white_lut = BYTARR(256)
    white_lut[[9, 10, 11, 13, 32]] = 1b

    while (~EOF(unit)) do begin

        ; Just read to the end.
        n = 32768 < (finfo.size - bytes)
        if (N_ELEMENTS(data) ne n) then $
            data = BYTARR(n, /NOZERO)

        READU, unit, data

        bytes += n

        ; Find CR/LF, tabs, and spaces.
        is_whitespace = white_lut[data]
        diff = is_whitespace - [prev_white, is_whitespace[0:n-2]]

        words += TOTAL(diff eq 1b, /INTEGER)

        ; Cache the last character of the current chunk.
        prev_white = is_whitespace[n-1]

    endwhile

    FREE_LUN, unit

    return, words
end


;--------------------------------------------------------------------
function query_ascii, filename, info

    compile_opt idl2, hidden

    ; Set up error handling
    CATCH, errorStatus
    if (errorStatus ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, /RESET
        RETURN, 0  ; failure
    endif

    ; Filename isn't a string
    if (SIZE(filename, /TYPE) ne 7) then $
        return, 0  ; failure

    finfo = FILE_INFO(filename)
    if (~finfo.exists || ~finfo.read) then $
        return, 0

    if (~QUERY_ASCII_VERIFY(filename)) then $
        return, 0  ; failure

    ; No need to keep going if we aren't returning Info.
    if (~ARG_PRESENT(info)) then $
        return, 1  ; success

    info = { $
        NAME: finfo.name, $
        TYPE: 'ASCII', $
        BYTES: finfo.size, $
        LINES: FILE_LINES(filename), $
        WORDS: QUERY_ASCII_WORDS(filename) $
        }

    return, 1  ; success

end

