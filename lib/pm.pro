; $Id: //depot/idl/releases/IDL_80/idldir/lib/pm.pro#1 $
;
; Copyright (c) 1991-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	PM
; PURPOSE:
;	Perform formatted output of matrices stored in the IMSL/IDL
;	linear algebra storage scheme to the standard output.
; CATEGORY:
;	Linear Algebra
; CALLING SEQUENCE:
;	PM, E1, ..., E10
; INPUTS:
;	E1, ... E10 - Expressions to be output. These can be scalar or
;		array and of any type.
; OUTPUTS:
;	Output is written to the standard output stream.
; COMMON BLOCKS:
;	None.
; RESTRICTIONS:
;	No more than 10 expressions can be output. This should be sufficient
;	for typical use.
; MODIFICATION HISTORY:
;	13, September 1991, Written by AB (RSI), Mike Pulverenti (IMSL)
;-

function pm_trans, v
if n_elements(v) lt 2 then return, v
return, transpose(v)
end





pro PM, E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, $
        E11, E12, E13, E14, E15, E16, E17, E18, E19, E20, format = fmt,$
        title=title

on_error, 2		; Return to caller on error

n = n_params()
if n_elements(title) then print, title


if keyword_set(fmt) then format = fmt else format = ''
case n of 
1:$
print, pm_trans(e1), $
       format = format

2:$
print, pm_trans(e1), pm_trans(e2), $
       format = format

3:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), $
       format = format

4:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), $
       format = format

5:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       format = format

6:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), $
       format = format
7:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), $
       format = format

8:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), $
       format = format

9:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), $
       format = format
10:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       format = format
11:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), $
       format = format
12:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), $
       format = format
13:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), $
       format = format
14:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), $
       format = format
15:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       format = format
16:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       pm_trans(e16), $
       format = format
17:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       pm_trans(e16), pm_trans(e17), $
       format = format
18:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       pm_trans(e16), pm_trans(e17), pm_trans(e18), $
       format = format
19:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       pm_trans(e16), pm_trans(e17), pm_trans(e18), pm_trans(e19), $
       format = format
20:$
print, pm_trans(e1), pm_trans(e2), pm_trans(e3), pm_trans(e4), pm_trans(e5), $
       pm_trans(e6), pm_trans(e7), pm_trans(e8), pm_trans(e9), pm_trans(e10), $
       pm_trans(e11), pm_trans(e12), pm_trans(e13), pm_trans(e14), pm_trans(e15), $
       pm_trans(e16), pm_trans(e17), pm_trans(e18), pm_trans(e19), pm_trans(e20), $
       format = format
else:$
      if (n gt 20) then $
          message, 'Too many arguments sent to PM.  Maximum allowed is twenty'
endcase


end
