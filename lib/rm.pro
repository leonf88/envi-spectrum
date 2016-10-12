; $Id: //depot/idl/releases/IDL_80/idldir/lib/rm.pro#1 $
;
; Copyright (c) 1991-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	RM
; PURPOSE:
;	Perform formatted input of matrices stored in the IMSL/IDL
;	linear algebra storage scheme from the standard input stream.
; CATEGORY:
;	Linear Algebra
; CALLING SEQUENCE:
;	RM, A [, Rows, Columns]
; INPUTS:
;       A    - The named variable into which data will be stored.
;       Rows - The number of 'rows' in A.
;       Columns - The number of 'columns' in A.
; OUTPUTS:
;	None.
; COMMON BLOCKS:
;	None.
; MODIFICATION HISTORY:
;	13, September 1991, Written by AB (RSI), Mike Pulverenti (IMSL)
;	31, October   1991,                      Mike Pulverenti (IMSL)
;-

pro RM, A, rows, columns, double=dbl, complex=cmplx

on_error, 2		; Return to caller on error

n = n_params()
if (n ne 1) and (n ne 3) then message, 'Wrong number of arguments."

;  	If Rows and Columns were not given, then make sure a is 
;	defined.
s = size(a)
if ((n eq 1) and (s(0) eq 0))  then message, 'Argument must be defined as a an array if Rows and Columns are not supplied.'
if ((n eq 1) and (s(0) gt 2)) then message, 'Array has too many dimensions.'
;
if (n eq 1) then begin
    a = transpose(a)
    s = size(a)
    l_columns = s(1)
    if (s(0) eq 1) then l_rows=1 else l_rows=s(2)
    type = s(s(0)+1)
endif else begin
    l_rows = rows
    l_columns = columns
    if keyword_set(cmplx) then $
	type = 6 $
	else if keyword_set(dbl) then type = 5 else type = 4
    dbl = keyword_set(dbl)
    cmplx = keyword_set(cmplx)
    a = make_array(l_columns, l_rows, type=type)
endelse

scratch = make_array(l_columns, 1, type=type)
for i = 0, l_rows-1 do begin
    read, string(i, format='("row ", I0, ": ")'), scratch
    a(0, i) = scratch
endfor
a = transpose(a)

end
