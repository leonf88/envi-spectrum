; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_pict_item.pro#1 $
;
; Copyright (c) 1990-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


pro read_pict_item, unit, data
; procedure reverse from big-endian to little endian or vis a versa.
; On entry:
;  DATA should be defined, and items are read from unit if it is > 0.
;  If Unit is < 0, DATA is already read.
;  The common block, write_pict_rev should already be set up.

COMPILE_OPT hidden
common write_pict_rev, rev

if unit ge 0 then readu, unit, data     ;Read it???
if rev eq 0 then return		;Nothing to do...
s = size(data)          	;What type of data?
case s[s[0]+1] of
2:  byteorder, data, /SSWAP ;Swap shorts
3:  byteorder, data, /LSWAP ;longs
4:  byteorder, data, /LSWAP ;Float
5:  begin           ;Double
    n = n_elements(data)
    data = byte(data, 0, n*8)
    for i=0L,8*(n-1),8 do for j=0L,7 do data[i+j] = data[i+7-j]
    data = DOUBLE(data, 0, n)
    endcase
6:  byteorder, data, /LSWAP ;Complex => floats
8:  begin           ;Structure...
    for i=0, N_TAGS(data)-1 do begin    ;Do each tag individually.
       tmp = data.(i)
       read_pict_item, -1, tmp
       data.(i) = tmp
       endfor
    endcase
else:               ;Do nothing for bytes & strings
endcase
end
