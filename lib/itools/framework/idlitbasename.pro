; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitbasename.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
;;IDLitBasename
;;
;; Purpose:
;;   Parsing routine that mimicks the basename command in unix. The
;;   routine will return the last section of the expresion pass into
;;   the function. If the reverse keyword is set, the parsing begins
;;   at the head of the passed in string.
;;
;; Parameter:
;;    strPathIn   - The path expression to chop
;;    strRemain   - The remaining portion of the string
;;
;; Keywords
;;  REMAINDER - Returns the remainder of the operation.
;;
;;  REVERSE   - will take the next token off the end of the string.
;;
;; Return Value
;;  The result of the operation.
;;
;; Paths come in the form of
;;    /type/sub-type/sub-type/...
;;
;;
;;
function IDLitBasename, strPathIn, REMAINDER=strRemain, $
                        REVERSE=reverse
   ;; pragmas
   compile_opt idl2, hidden

   ;; Check input
   if(n_elements(strPathIn) eq 0)then begin
      strRemain=''
      return, ''
   endif

   ;; Take the inverse of the reverse keyword. From end is used to
   ;; indicated we are taking off the end of the string
   fromEnd =  (keyword_set(reverse) ? 0 : 1)

   ;; Get the current level
   ; If first character is a "/", then remove it.
   iStart = (STRMID(strPathIn, 0, 1, reverse_offset=fromEnd) eq '/')
   iEnd = strlen(strPathIn)

   ;; Should we chop from the end of the string?
   if(fromEnd)then begin
      iEnd = iEnd - iStart
      iStart =0
   endif

   ;; Remove trailing or beginning "/"
   strPathEx = STRMID(strPathIn, iStart, iEnd);

   ;; Location of first "/" which is used to delimit the item
   iChop = STRPOS(strPathEx, '/', REVERSE_SEARCH=fromEND)

   ;; Ok, now chop into two parts.

   strPath = (iChop eq -1) ? strPathEx : $
                 STRMID(strPathEx, 0, iChop)

   ;; Get the remainder
   strRemain = (iChop ne -1) ? STRMID(strPathEx, iChop+1) : ''

   ;; If we are chopping from the end of the string, reverse the
   ;; values

   if(fromEnd and strRemain ne '')then begin
      strPathEx = strPath
      strPath = strRemain
      strRemain = strPathEx
   endif

   return, strPath
end
