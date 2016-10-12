; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgetuniquename.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; IDLitGetUniqueName
;
; Purpose:
;   Returns a unqiue name for a given list of names and a template.
;   If a name collides, the routine will do the following:
;       - Determine if the given template has a number appended to
;         it or not. If so the number is stripped off. If no
;         number exists, a value of 0 is set as the start point.
;       - A new name is generated using the base name and
;         an incremented value of the number. This name
;         has the format of <basename>_<number>
;       - The routine will continue to increment the number
;         until a unique name is found.
;
; Return Value:
;   A unique name
;
; Parameters:
;    strExisting     - Existing set of names
;
;    strTemplate     - Proposed name.
;
function IDLitGetUniqueName, strExisting, strTemplateIn
   ; Pragmas
   compile_opt idl2, hidden

@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, ''
   end

    ; If no match then return successfully. ID's are case insensitive.
    strTemplate = STRUPCASE(strTemplateIn)
    if (ARRAY_EQUAL(strExisting eq strTemplate, 0b)) then $
        return, strTemplate

   ; At this point we have  a name collision
    iCount = 1

   ; The name template is NAME_<number>. See if this name has a
   ; number and if so, use it to generate a unique name
   iScore = strpos(strTemplate, "_", /reverse_search)
   if (iScore gt 0) then begin
       strBase = strmid(strTemplate, 0, iScore)
       strNum = strtrim(strmid(strTemplate, iScore+1),2)
       on_ioerror, convert_err
       iCount = fix(strNum)
   endif else begin
       strBase = strTemplate
       ; See if our last item has a number on the end, and if so,
       ; use it to generate the next number.
       strTmp = strExisting[N_ELEMENTS(strExisting)-1]
       iScore = strpos(strTmp, "_", /reverse_search)
       if (iScore gt 0 && strmid(strTmp,0,iScore) eq strBase) then begin
           strNum = strtrim(strmid(strTmp, iScore+1),2)
           on_ioerror, convert_err
           iCount = fix(strNum) + 1
       endif
   endelse

convert_err:

   ; Okay, now we have the basename and start number, get name
    while (1) do begin
        sName = strBase + "_" + strtrim(iCount,2)
        ; If no match then we're done. ID's are case insensitive.
        if (ARRAY_EQUAL(strExisting eq sName, 0b)) then $
            break
        iCount++
    endwhile

   return, sName
end
