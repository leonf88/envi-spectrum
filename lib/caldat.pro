; $Id: //depot/idl/releases/IDL_80/idldir/lib/caldat.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;+
; NAME:
;	CALDAT
;
; PURPOSE:
;	Return the calendar date and time given julian date.
;	This is the inverse of the function JULDAY.
; CATEGORY:
;	Misc.
;
; CALLING SEQUENCE:
;	CALDAT, Julian, Month, Day, Year, Hour, Minute, Second
;	See also: julday, the inverse of this function.
;
; INPUTS:
;	JULIAN contains the Julian Day Number (which begins at noon) of the
;	specified calendar date.  It should be a long integer.
; OUTPUTS:
;	(Trailing parameters may be omitted if not required.)
;	MONTH:	Number of the desired month (1 = January, ..., 12 = December).
;
;	DAY:	Number of day of the month.
;
;	YEAR:	Number of the desired year.
;
;	HOUR:	Hour of the day
;	Minute: Minute of the day
;	Second: Second (and fractions) of the day.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;	Accuracy using IEEE double precision numbers is approximately
;	1/10000th of a second.
;
; MODIFICATION HISTORY:
;	Translated from "Numerical Recipies in C", by William H. Press,
;	Brian P. Flannery, Saul A. Teukolsky, and William T. Vetterling.
;	Cambridge University Press, 1988 (second printing).
;
;	DMS, July 1992.
;	DMS, April 1996, Added HOUR, MINUTE and SECOND keyword
;	AB, 7 December 1997, Generalized to handle array input.
;	AB, 3 January 2000, Make seconds output as DOUBLE in array output.
;   CT, Nov 2006: For Hour/Min/Sec, tweak the input to make sure hours
;       and minutes are correct. Restrict hours to 0-23 & min to 0-59.
;-
;
pro CALDAT, julian, month, day, year, hour, minute, second

COMPILE_OPT idl2

	ON_ERROR, 2		; Return to caller if errors

	nParam = N_PARAMS()
	IF (nParam LT 1) THEN MESSAGE,'Incorrect number of arguments.'

	min_julian = -1095
	max_julian = 1827933925
	minn = MIN(julian, MAX=maxx)
	IF (minn LT min_julian) OR (maxx GT max_julian) THEN MESSAGE, $
		'Value of Julian date is out of allowed range.'

	igreg = 2299161L    ;Beginning of Gregorian calendar
	julLong = FLOOR(julian + 0.5d)   ;Better be long
	minJul = MIN(julLong)

	IF (minJul GE igreg) THEN BEGIN  ; all are Gregorian
		jalpha = LONG(((julLong - 1867216L) - 0.25d) / 36524.25d)
		ja = julLong + 1L + jalpha - long(0.25d * jalpha)
	ENDIF ELSE BEGIN
		ja = julLong
		gregChange = WHERE(julLong ge igreg, ngreg)
		IF (ngreg GT 0) THEN BEGIN
    		jalpha = long(((julLong[gregChange] - 1867216L) - 0.25d) / 36524.25d)
    		ja[gregChange] = julLong[gregChange] + 1L + jalpha - long(0.25d * jalpha)
		ENDIF
	ENDELSE
	jalpha = -1  ; clear memory

	jb = TEMPORARY(ja) + 1524L
	jc = long(6680d + ((jb-2439870L)-122.1d0)/365.25d)
	jd = long(365d * jc + (0.25d * jc))
	je = long((jb - jd) / 30.6001d)

	day = TEMPORARY(jb) - TEMPORARY(jd) - long(30.6001d * je)
	month = TEMPORARY(je) - 1L
	month = ((TEMPORARY(month) - 1L) MOD 12L) + 1L
	year = TEMPORARY(jc) - 4715L
	year = TEMPORARY(year) - (month GT 2)
	year = year - (year LE 0)

; see if we need to do hours, minutes, seconds
	IF (nParam GT 4) THEN BEGIN
		fraction = julian + 0.5d - julLong
    	eps = 1d-12 > 1d-12*ABS(Temporary(julLong))
		hour = 0 > Floor(fraction * 24d + eps) < 23
		fraction -= hour/24d
		minute = 0 > Floor(fraction*1440d + eps) < 59
		second = 0 > (TEMPORARY(fraction) - minute/1440d)*86400d
	ENDIF

; if julian is an array, reform all output to correct dimensions
	IF (SIZE(julian,/N_DIMENSION) GT 0) THEN BEGIN
		dimensions = SIZE(julian,/DIMENSION)
		month = REFORM(month,dimensions)
		day = REFORM(day,dimensions)
		year = REFORM(year,dimensions)
		IF (nParam GT 4) THEN BEGIN
			hour = REFORM(hour,dimensions)
			minute = REFORM(minute,dimensions)
			second = REFORM(second,dimensions)
		ENDIF
	ENDIF

END
