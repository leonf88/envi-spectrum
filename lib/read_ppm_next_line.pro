; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_ppm_next_line.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


Function READ_PPM_NEXT_LINE, unit
COMPILE_OPT hidden

cr = string(13b)
repeat begin
    a = ''
    readf, unit, a
    l = strpos(a, '#')   ;Strip comments
    if l ge 0 then a = strmid(a,0,l)
    if strmid(a,0,1) eq cr then a = strmid(a,1,1000)  ;Leading <CR>
    if strmid(a,strlen(a)-1,1) eq cr then a = strmid(a,0,strlen(a)-1)
    a = strtrim(a,2)        ;Remove leading & trailing blanks.
    a = strcompress(a)      ;Compress white space.
endrep until strlen(a) gt 0
return, a
end
