; $Id: //depot/idl/releases/IDL_80/idldir/lib/bin_date.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

function bin_date, ascii_time
;+
; NAME:
;	BIN_DATE
;
; PURPOSE:
;	This function converts a standard form ascii date/time string
;	to a binary string.
;
; CATEGORY:
;	Date/time functions.
;
; CALLING SEQUENCE:
;	Result = BIN_DATE(Asc_time)
;
; INPUTS:
;	Asc_time: the date/time to convert in standard ascii format.
;		  If omitted, use the current date/time.  
;	  	  Standard form is a 24 character string:
;			DOW MON DD HH:MM:SS YYYY
;		  where: DOW = day of week, MON = month, DD=day of month,
;			HH:MM:SS = hour/minute/second, YYYY = year.
;
; OUTPUTS:
;	This function returns a 6 element integer array containing:
; 	Element 0 = year	e.g. 1992
;		1 = month	1-12
;		2 = day		1-31
;		3 = hour	0-23
;		4 = minute	0-59
;		5 = second	0-59
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	Straightforward.
;
; MODIFICATION HISTORY:
; 	Written by:	DMS /RSI, Jul, 1992.
;	Modified to use STR_SEP function, DMS, Dec. 1995.
;       Fixed bug when passed single digit dates
;			KDB, Nov, 01 1996
;	Replaced use of obsolete STR_SEP with STRTOK, AB, 23 Feb 1999
;-


if n_elements(ascii_time) eq 0 then $
   ascii_time = systime(0)	;Current time
s = strtok(ascii_time, /EXTRACT)	;Separate fields on whitespace
t = strtok(s[3], ':',  /EXTRACT)	;Time fields separated by colon
m = where(strupcase(s[1]) eq $	; = month  - 1
 ['JAN','FEB','MAR','APR', 'MAY', 'JUN', 'JUL', 'AUG','SEP','OCT','NOV','DEC'])
return, [ s[4], $			;year
	m[0] + 1, $			;Month
	s[2], $				;day
	t[0], $				;Hour
	t[1],$				;minute
	t[2]]				;second
end
