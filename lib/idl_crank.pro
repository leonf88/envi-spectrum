;$Id: //depot/idl/releases/IDL_80/idldir/lib/idl_crank.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

pro IDL_CRANK, w, s
;+
; NAME:
;    IDL_CRANK
;
;
; PURPOSE:
;    Replace elements of the sorted array "w" by their rank.
;    Identical observations ("ties") return the mean rank.
;
;    NOTE: This procedures is not a supported user-level routine.
;          It is a support routine for IDL statistics library functions.
;
;
; CATEGORY:
;    Analysis
;
;
; CALLING SEQUENCE:
;      IDL_CRANK, W
;
; 
; INPUTS:
;      W:  A sorted array
;
;
; OUTPUTS:
;      W: IDL_CRANK replaces the input array W with its floating point
;      rank.
;
; OPTIONAL OUTPUTS:
;    s = total(f^3 - f) 
;    (f is the number of elements in each set of identical observations.)
;  
; EXAMPLE:
;    X = [-1, 2, 3, 5, 6, 6, 9]
;    IDL_CRANK, X
; produces
;    X = [1.000, 2.000, 3.000, 4.000, 5.500, 5.500, 6.000 ]
; MODIFICATION HISTORY:
;
;       Tue Jan 27 16:50:31 1998, Scott Lett, RSI, Adapted from
;       earlier IDL library routines.
;
;-


n = n_elements(w)-1
s = 0.0
j = 0L
w = float(w)                    ;Ensure floating
while(j lt n) do begin
    if w[j+1] ne w[j] then begin
        w[j] = j+1
        j = j+1
    endif else begin
        for jt = j+1, n do $
          if (w[jt] ne w[j]) then goto, case2
        jt = n + 1
        case2:
        w[j:jt-1] = 0.5 * (j + jt +1)
        s = s + float(jt-j)^3 - (jt-j)
        j = jt
    endelse
endwhile

if (j eq n) then w[n] = n+1
end
