; $Id: //depot/idl/releases/IDL_80/idldir/lib/define_msgblk_from_file.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;+
; NAME:
;       DEFINE_MSGBLK_FROM_FILE
;
; PURPOSE:
;       Read an IDL message file and use DEFINE_MSGBLK to
;       load the message block it defines into IDL. Once this
;       has been done, the errors can be issued via the MESSAGE procedure.
;
; CATEGORY:
;       Error Handling.
;
; CALLING SEQUENCE:
;       DEFINE_MSGBLK_FROM_FILE, filename
;
; INPUTS:
;    filename:  Name of the message file to read.
;
; KEYWORDS:
;    BLOCK: If present, specifies the name of the message block.
;       Normally, this keyword is not specified, and an @IDENT
;       line in the message file specifies the name of the block.
;
;    IGNORE_DUPLICATE: Attempts to define a given message block more than
;       once in the same IDL session usually cause DEFINE_MSGBLK to
;       issue an error and stop execution of the IDL program. Specify
;       IGNORE_DUPLICATE to cause DEFINE_MSGBLK to quietly ignore
;       attempts to redefine a message block. In this case, no
;       error is issued and execution continues. The original message
;       block remains installed and available for use.
;
;    PREFIX: If present, specifies a prefix string to be applied to
;       the beginning of each message name in the message block.
;       Normally, this keyword is not specified, and a @PREFIX
;       line in the message file specifies the prefix string.
;
;    VERBOSE: If set, causes DEFINE_MSGBLK_FROM_FILE to print
;       informational messages to stdout describing the message
;       block loaded.
;
; OUTPUTS:
;       None.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       The specified message block has been loaded into IDL, as can
;       be verified via the "HELP,/MESSAGE" command.
;
; MODIFICATION HISTORY:
;       1 August 2000, AB, RSI
;-



function DMFF_FIND_SPECIAL, text, special, required
  ; Find the special line in the message file text and return its value
  ;
  ; These lines have a syntax that looks like the following:
  ;
  ;     @IDENT IDL_MBLK_CORE
  ;     @PREFIX IDL_M_
  ;
  ; entry:
  ;     text - String array containing text of message file, one line
  ;             per element.
  ;     special - The name of the special token (e.g. 'IDENT').
  ;     required - TRUE if this item is required in the file, and
  ;             FALSE if it is not. If it is not required, and is not
  ;             present, it is defaulted to a NULL string.

  compile_opt HIDDEN, IDL2
  on_error, 2           ; Return to caller

  ws = '[ ' + string(9B) + ']'
  regex = '^' + ws + '*@' + special + ws + '+([a-z0-9_$]+)'

  idx = where(stregex(text, regex, /FOLD_CASE, /BOOLEAN) ne 0, cnt)
  case cnt of
    0: begin
         if (required ne 0) then $
           MESSAGE, 'Message definition file does not ' $
                    + 'contain required @' + special + ' line'
         r = ''
       end
    1: r = (stregex(text[idx], regex, /FOLD_CASE, /EXTRACT, /SUBEXPR))[1]
    else: MESSAGE, 'Message definition file contains multiple @' $
                   + special + ' lines'
  endcase

  return, r
end






pro DEFINE_MSGBLK_FROM_FILE, filename, BLOCK=block, $
        IGNORE_DUPLICATE=ignore_dup, PREFIX=prefix, VERBOSE=verbose

  compile_opt IDL2
;  on_error, 2           ; Return to caller

  l_verbose = keyword_set(verbose)
  if (l_verbose) then start_time = systime(1)
        
  ; Read the contents of the file into memory. For simplicity, a 2 pass
  ; approach is used, one to count lines and the other to actually read them
  openr, u, filename, /GET_LUN
  text = ''
  n = 0
  while (not eof(u)) do begin readf, u, text & n = n + 1 & end
  point_lun, u, 0       ; Rewind
  text = strarr(n)      ; Make text have enough elements for entire file
  readf, u, text        ; Read in entire file in one operation
  free_lun, u           ; Close file, release unit

  ; Check for @IDENT and @PREFIX lines. User specified keyword override
  ; the lines in the file.
  l_block = n_elements(block) eq 0 $
        ? dmff_find_special(text, 'IDENT', 1) : block
  l_prefix = n_elements(prefix) eq 0 $
        ? dmff_find_special(text, 'PREFIX', 0) : prefix

  ; Identify all lines that define a message. These lines start with
  ; 1 or 2 '@' characters, whitespace, a message name, whitespace, and
  ; a double quoted printf style string. Fortunately, the STREGEX will
  ; honor any backslash in the quoted string, so the following
  ; regular expression will correctly handle escaped double quotes inside
  ; the format string. The parens indicate the substrings we wish to
  ; extract.
  ws = '[ ' + string(9B) + ']'
  regex = '^' + ws + '*@@?' + ws + '+([a-z0-9_$]+)' + ws + '+"(.*)"'
  idx = where(stregex(text, regex, /FOLD_CASE, /BOOLEAN) ne 0, cnt)

  ; Extract the message names and format strings. Define the message block.
  if (cnt eq 0) then $
        MESSAGE, 'Message definition file defines no messages: ' + filename

  ; TAKE 1: Extract the names and format strings from the lines of text.
  ; This version is elegant and compact, but runs slowly due to the
  ; cost of using back-references (subexpressions).
  ;val = stregex(text[idx], regex, /FOLD_CASE, /EXTRACT, /SUBEXPR)
  ;define_msgblk, ignore_duplicate=ignore_dup, prefix=l_prefix, $
  ;     l_block, val[1,*], val[2,*]

  ; TAKE 2: Extract the names and format strings from the lines of text.
  ; Although using a loop, many function calls, and some additional
  ; arithmetic, this version is over an order of magnitute faster.
  ; That's the price one pays for the generality of regular expressions.
  ;
  ; Note that without the use of STREGEX above to locate the proper lines,
  ; this code would have to do alot of checking to ensure it only
  ; handles the proper lines. This checking is not needed here because
  ; the data is pre-validated.
  names = strarr(cnt)
  fmts = strarr(cnt)
  for i = 0, cnt-1 do begin
    str = text[idx[i]]
    val = strsplit(str, LENGTH=len)
    names[i] = strmid(str, val[1], len[1])
    start = val[2]+1
    fmts[i] = strmid(str, start, strpos(str, '"', /REVERSE_SEARCH)-start)
  endfor
  define_msgblk, ignore_duplicate=ignore_dup, prefix=l_prefix, $
        l_block, names, fmts

  if (l_verbose) then begin
    print, 'File          : ', filename
    print, format='(%"# Input Lines : %d")', n_elements(text)
    print, 'Block Name    : ', l_block
    print, 'Prefix        : ', l_prefix
    print, format='(%"# Messages    : %d")', cnt
    print, format='(%"Elapsed Time  : %f")', systime(1) - start_time
  endif

end
