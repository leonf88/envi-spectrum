; $Id: //depot/idl/releases/IDL_80/idldir/lib/dl_dos.pro#1 $
;
; Copyright (c) 1990-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

pro dl_dos_doc_file, name, outunit     ; print documentation for file 'name'
    COMPILE_OPT hidden

    printf, outunit
    printf, outunit, '----- Documentation for ',name
    printf, outunit
    openr, unit, name, /GET_LUN
    line = ""
    outflag = 0
    readf, unit, line
    while not eof(unit) and strpos(line, ";-") ne 0 do begin
      if outflag then printf, outunit, strmid(line, 1, 132)
;
; output lines after line which starts with ";+"
;
      if strpos(line, ";+") eq 0 then outflag = 1
      readf, unit, line
    endwhile
    free_lun, unit
end

pro dl_dos, name, print=printflg, directory = direct
;+NODOCUMENT
; NAME:
;	DL_DOS
;
; PURPOSE:
;	Extract the documentation template of one or more procedures (DOS
;	version).
;
; CATEGORY:
;	Help, documentation.
;
; CALLING SEQUENCE:
;	DL_DOS		;For prompting.
;	DL_DOS, Name 	;Extract documentation for procedure Name using
;				the current !PATH.
;
; INPUTS:
;	Name:	A string containing the name of the procedure or "*" for all.
;
; OPTIONAL INPUT PARAMETERS:
;	PRINT:	A keyword parameter which, if set to 1, sends the output
;		of DL_DOS to PRN:.  If PRINT is a string, it specifies the
;		name of a file that will contain the documentation.
;
;   DIRECTORY:	The directory to search.  If omitted, the current directory
;		and !PATH are used.
;
; OUTPUTS:
;	No explicit outputs.  Documentation is output using 'more' format
;	unless /PRINT is specified.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	Output is produced on terminal or printer.  If the current directory
;	is also one of the directories specified in !PATH or DIRECTORY,
;	documentation will be output twice for the specified module(s).
;
; RESTRICTIONS:
;	??
;
; PROCEDURE:
;	Straightforward.
;
; MODIFICATION HISTORY:
;	SNG, Dec, 1990 - adapted from DOC_LIB_UNIX
;	AB, 21 September 1992, renamed from DOC_LIB_DOS to DL_DOS to
;		avoid DOS filename limitations.
;-

COMPILE_OPT hidden	; DOC_LIBRARY is the public entry point
on_error,2              ;Return to caller if an error occurs
if n_elements(name) eq 0 then begin	;Interactive query?
	name = ''
	printflg = 0
	read, 'Name of procedure or * for all: ',name
	read, 'Enter 1 for printer, 0 for terminal: ',printflg
	endif

name = strlowcase(name)		;make it always lower case

;
; if DIRECTORY not specified, use !path
;
if n_elements(direct) eq 0 then begin
  cd, current=curr
  curr = strlowcase(curr)       ; make lower case
;
;   add the current directory to the search path if it is not already there
;
  if strpos(!path, curr) eq -1 then path = ".;" + !path else path = !path
endif else path = direct    ; otherwise use DIRECTORY
;
; determine where output is going and open as a file
;
if n_elements(printflg) eq 0 then begin
  outunit=-1
endif else begin
  printflg = strtrim(printflg, 2)
  case printflg of
    '0':  outunit=-1                                            ; terminal
    '1':  openw, outunit, 'prn:', /GET_LUN                      ; printer
    else:   openw, outunit, printflg, /GET_LUN                  ; file
  endcase
endelse
;
; loop for every directory in path
;
while strlen(path) gt 0 do begin ; Find it
    i = strpos(path, ";")
    if i lt 0 then i = strlen(path)
    name_path = strmid(path, 0, i)
    cd, name_path
    name_path = name_path + '\'
;
;           file_list contains all file(s) to document
;
    file_list = FILE_SEARCH(name_path + name + '.pro',count=n_files)
    n_files = n_files - 1                       ; since indexed from zero
    for n = 0, n_files do begin                  ; document every file
        dl_dos_doc_file, file_list[n], outunit
        printf, outunit, ''     ; output form feed to start next at top of page
    endfor
    path = strmid(path, i + 1, strlen(path))
endwhile
if outunit ne -1 then begin
  FREE_LUN, outunit
endif
cd, curr
end
