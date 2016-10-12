; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_ppm_next_token.pro#1 $
;
; Copyright (c) 1994-2010. ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;


Function READ_PPM_NEXT_TOKEN, unit, buffer

COMPILE_OPT hidden

if strlen(buffer) le 0 then buffer = READ_PPM_NEXT_LINE(unit)
white = strpos(buffer, ' ')
if white eq -1 then begin   ;No blanks?
    result = buffer
    buffer = ''
endif else begin        ;Strip leading token.
    result = strmid(buffer, 0, white)
    buffer = strmid(buffer, white+1, 1000)
endelse
return, result
end
