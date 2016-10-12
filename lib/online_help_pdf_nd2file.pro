; $Id: //depot/idl/releases/IDL_80/idldir/lib/online_help_pdf_nd2file.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;       ONLINE_HELP_PDF_ND2FILE
;
; PURPOSE:
;       Given a pdf named destination, this function returns the name
;       of the IDL documentation pdf file from !HELP_PATH in which the
;       named destination is expected to be found.
;
;       This function is called by the IDL builtin ONLINE_HELP procedure
;       when pdf files are being used, and the IDL user specifies a
;       search topic without also giving the name of the pdf file. It uses
;       RSI supplied .pdf_nd files to determine the file to use, returning
;       the name of the file if found, and a NULL string otherwise.
;
;        -------------------------------------------------------------
;       | THIS ROUTINE IS NOT INTENDED FOR GENERAL USE. IT MAY CHANGE |
;       | OR EVEN BE REMOVED FROM FUTURE IDL RELEASES WITHOUT NOTICE. |
;        -------------------------------------------------------------
;
;       The public interface to the functionality contained in this routine
;       is via the "?" command, or the ONLINE_HELP procedure.
;
; CATEGORY:
;       Help, documentation.
;
; CALLING SEQUENCE:
;       ONLINE_HELP_PDF_ND2FILE, NamedDestination
;
; INPUTS:
;     NamedDestination: A scalar string containing the item about which
;     help is desired.
;
; OUTPUTS:
;       Returns a string giving the name of the pdf file to use, or
;       NULL if no file is found,
;
; COMMON BLOCKS:
;       ONLINE_HELP_PDF_ND2FILE - This block is private to this module, and
;               not to be used by other routines.
;
; MODIFICATION HISTORY:
;       13 March 2003, AB
;
;-
;




function online_help_pdf_nd2file, target_nd

  COMPILE_OPT idl2, hidden

  ; Suppress compiled module messages
  quiet_save = !quiet
  !quiet = 1
  resolve_routine,['path_sep', 'strsplit','uniq'], /IS_FUNCTION
  !quiet = quiet_save

  ; This common block is used to maintain information about which named
  ; destinations correspond to which PDF files.
  ;	nd_files - Names of the PDF files for which named
  ;		destination information is known.
  ;	nd_files_nelts - # of entries in nd_files.
  ;	nd - Vector of all the named destination strings. Should be sorted
  ;		lexically, with no duplicates.
  ;	nd_to_pdf_idx - For each item in nd, the corresponding item in
  ;		this vector is an index into nd_files giving the PDF
  ;		file that it corresponds to.
  ;	nd_nelts - # of entries in nd_files and nd_to_pdf_idx.
  COMMON online_help_pdf_nd2file, nd_files, nd_files_nelts, $
	nd, nd_to_pdf_idx, nd_nelts

  ; Make sure the nelts
  if (n_elements(nd_files_nelts) eq 0) then nd_files_nelts = 0
  if (n_elements(nd_nelts) eq 0) then nd_nelts = 0

  ; On the first call, we read the .pdf_nd files and build an in-memory
  ; representation of their contents. On subsequent calls, we skip this
  ; step and go directly to the lookup.
  if (nd_files_nelts eq 0) then begin
    ; Locate all of the named destination files from !HELP_PATH
    help_path = strsplit(!help_path, path_sep(/SEARCH_PATH), /EXTRACT) $
                + path_sep()
    nd_files = file_search(help_path + '*.pdf_nd', count=nd_files_nelts)
    if (nd_files_nelts eq 0) then return, ''

    ; Count the number of lines in all of the named destination files
    nd_lines = FILE_LINES(nd_files)
    total_nd_lines = 0L
    for i=0, n_elements(nd_lines)-1 do total_nd_lines += nd_lines[i]

    ; nd holds all of the named destination strings, and nd_to_file
    ; maps the name to the index of the book. Note the assumption that
    ; there will not be more than 255
    nd = strarr(total_nd_lines)
    nd_to_pdf_idx = intarr(total_nd_lines)

    base = 0L
    GET_LUN, u
    for i=0, nd_files_nelts-1 do begin
      tmp_n = nd_lines[i]
      tmp = strarr(tmp_n)
      OPENR, u, nd_files[i]
      READF, u, tmp      
      nd[base] = tmp
      nd_to_pdf_idx[base] = bytarr(tmp_n)+i
      base += tmp_n
      CLOSE, u
    endfor
    FREE_LUN, u

    ; Remove surrounding whitespace in names, make uppercase, sort, and toss dups
    nd = strupcase(strtrim(temporary(nd), 2))
    final_idx = uniq(nd, sort(nd))
    nd = nd[final_idx]
    nd_to_pdf_idx = nd_to_pdf_idx[final_idx]
    nd_nelts = n_elements(nd)

    ; Strip the _nd off the file names, turning them into PDF names
    for i=0, nd_files_nelts-1 do $
      nd_files[i] = strmid(nd_files[i], 0, strlen(nd_files[i])-3)
  endif


  ; Look for the target_nd in the nd array. If found, return the
  ; name of the book it corresponds to.
  if (nd_nelts gt 0) then begin
    uc_target = strupcase(target_nd)
    tmp = VALUE_LOCATE(nd, uc_target)
    if ((tmp gt -1) && (tmp le nd_nelts) && (nd[tmp] eq uc_target)) then $
      return, nd_files[nd_to_pdf_idx[tmp]]
  endif

  ; If we get here, the named destination is not recognised. Return NULL string
  return, ''

end
