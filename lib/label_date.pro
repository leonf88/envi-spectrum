; $Id: //depot/idl/releases/IDL_80/idldir/lib/label_date.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	LABEL_DATE
;
; PURPOSE:
;	This function labels axes with dates and times.
;
; CATEGORY:
;	Plotting.
;
; CALLING SEQUENCE:
;	To set up:
;		dummy = LABEL_DATE(DATE_FORMAT='string')
;	To use:
;		PLOT, x, y, XTICKFORMAT='LABEL_DATE'
;
; INPUTS:
;	No explicit user defined inputs. When called from the plotting
;	routines, the input parameters are (Axis, Index, Value [, Level])
;
; KEYWORD PARAMETERS:
;	DATE_FORMAT: a format string which may contain the following:
;		       %M for month
;		       %N for month (2 digit abbr)
;		       %D for day of month,
;		       %Y for 4 digit year.
;		       %Z for last two digits of year.
;              %W for day of week
;	     For time:
;              %A for AM or PM
;		       %H for Hours, 2 digits.
;		       %I for mInutes, 2 digits.
;		       %S for Seconds, 2 digits.
;                 %0--%9 following %S, indicates digits after decimal point.
;		       %% is %.
;
;		If a time format string is specified, the time of day
;		will be rounded to the nearest least significant time format
;		specified.  E.g. if the format '%H:%I' is specified
;		(hours:minutes) the time is rounded to the nearest minute.
;
;		     Other characters are passed directly thru.
;		     For example, '%M %D, %Y' prints DEC 11, 1993
;		       '%M %2Y' yields DEC 93
;		       '%D-%M' yields 11-DEC
;		       '%D/%N/%Y' yields 11/12/1993
;		       '%M!C%Y' yields DEC on the top line, 1993 on
;		       the bottom (!C is the new line graphic command).
;
;   AM_PM: The names for AM or PM. The default is ["am","pm"]
;
;   DAYS_OF_WEEK: The names of the days, a seven-element string array.
;                 The default is [Sun, Mon, Tue, Wed, Thu, Fri, Sat].
;
;	MONTHS:  The names of the months, a twelve element string array.
;		     The default is [Jan, Feb,..., Dec].
;
;   OFFSET: Set this keyword to a value representing the offset to be added
;           to each tick value before conversion to a label. This keyword
;           is usually used when your axis values are measured relative to
;           a certain starting time. In this case, OFFSET should be set to
;           the Julian date of the starting time.
;
;   ROUND_UP: Set this keyword to force times to be rounded up to the
;           smallest time unit that is present in the DATE_FORMAT string.
;           The default is for times to be truncated to the
;           smallest time unit.
;
; OUTPUTS:
;	The date string to be plotted.
;
; COMMON BLOCKS:
;	LABEL_DATE_COM.
;
; RESTRICTIONS:
;	Uses a common block, so only one date axis may be simultaneously active.
;
; PROCEDURE:
;	Straightforward.
;
;       For an alternative way to label a plot axis with dates, refer to
;       the C() format code accepted within format strings (applicable via
;       the [XYZ]TICKFORMAT keywords).  This format code was
;       introduced in IDL 5.2.
;
; EXAMPLE:
;	For example, to plot from Jan 1, 1993, to July 12, 1994:
;	  Start_date = julday(1, 1, 1993)
;	  End_date = julday(7, 12, 1994)
;	  Dummy = LABEL_DATE(DATE_FORMAT='%N/%D')  ;Simple mm/dd
;	  x = findgen(end_date+1 - start_date) + start_date ;Time axis
;	  PLOT, x, sqrt(x), XTICKFORMAT = 'LABEL_DATE', XSTYLE=1
;	  (Plot with X axis style set to exact.)
;
; Example with times:
;	For example, to plot from 3PM, Jan 1, 1993, to 5AM, Jan 3,
;	1993:
;	Start_date = Julday(1,1,1993)   ;Also starting offset
;	Start_time = (3+12)/24.         ;Starting_time less offset
;	End_time = (Julday(1,3,1993) - Start_date) + 5./24. ;Ending
;       	;date/time - offset, note that the order of operations is
;               ; important to avoid loss of precision.
;	Dummy = LABEL_DATE(DATE_FORMAT='%D %M!C%H:%I', $
;		offset=Start_date)       ;MMM NN <new line> HH:MM format
;	x = findgen(20) * (End_time - Start_time) / 19 + start_time ;Time axis
;	PLOT, x, sqrt(x), XTICKFORMAT = 'LABEL_DATE', XSTYLE=1
;
; MODIFICATION HISTORY:
;	DMS, RSI.	April, 1993.	Written.
;	DMS, RSI.	March, 1997.	Added Time format.
;	DMS, RSI.	Jan, 1999.	Rounded least significant time unit
;   CT, RSI.    May 2000. Completely rewrote to use calendar format codes.
;                Added Level argument for new date/time TICKUNITS.
;                Added AM_PM and DAYS_OF_WEEK keywords, '%A' and '%W' codes.
;-


;-------------------------------------------------- LABEL_DATE_CONVERT_FORMAT
; Given a LABEL_DATE input string, convert codes to Calendar format codes.
FUNCTION label_date_convert_format, format, cMonths, cAmpm, cDaysWeek

	COMPILE_OPT idl2, hidden

	ON_ERROR, 2

	n = strlen(format)
	newFormat = ''
	for i=0L, n-1 do begin           ;Each format character...
		add = strmid(format, i, 1)       ;The character.
		if add eq '%' then begin
			i = i + 1  ; skip to next character
			c = STRUPCASE(strmid(format, i, 1))
			; if format character, then convert to calendar format code
			case c of
				; if user specified months, then width=zero to use "natural"
				; month length, otherwise use the default month length (3)
                'M': add = (N_ELEMENTS(cMonths) EQ 12) ? 'CMoA0' : 'CMoA'
                'N': add = 'CMOI2.2'
                'D': add = 'CDI2.2'
                'Y': add = 'CYI4'
                'Z': add = 'CYI2.2'
                'H': add = 'CHI2.2'
                'I': add = 'CMI2.2'
				'S': BEGIN
					add = 'CSI2.2'  ; default format for seconds
					; check for additional %n code
					IF (STRMID(format,i+1,1) EQ '%') THEN BEGIN
						numberChar = STRMID(format,i+2,1)
						number = STRPOS('0123456789',numberChar)
						IF (number GE 0) THEN BEGIN
							i = i + 2  ; skip format characters
							width = STRTRIM(3+number,2) ;tens+ones+decimal
							add = 'CSF' + width + '.' + numberChar
							; add TLn,CSI2.2 to include leading zero
							add = add + ',TL' + width + ',CSI2.2'
						ENDIF
					ENDIF
					END
				'W' : add = (N_ELEMENTS(cDaysWeek) EQ 7) ? 'CDwA0' : 'CDwA'
				'A' : add = (N_ELEMENTS(cAmpm) EQ 2) ? 'CapA0' : 'CapA'
				'%' : add = '"%"'
				ELSE: add = '""'  ; if unknown, add null string
			endcase
		endif else add = '"' + add + '"'   ; just output the character
		newFormat = (newFormat EQ '') ? add : newFormat + ',' + add
	endfor
	IF (STRPOS(newFormat,'CapA') GE 0) THEN BEGIN
		hourPos = STRPOS(newFormat,'CHI')
		IF (hourPos GE 0) THEN newFormat = STRMID(newFormat,0,hourPos+1) + $
			'hI' + STRMID(newFormat,hourPos+6)
	ENDIF
	RETURN, '(C(' + newFormat + '))'
END


;----------------------------------------------------------------- LABEL_DATE
FUNCTION LABEL_DATE, axisIn, indexIn, valueIn, levelIn, $
	AM_PM = am_pm, $
	DATE_FORMAT = dateFormat, $
	DAYS_OF_WEEK = days_of_week, $
	MONTHS = months, $
	OFFSET = offs, $
	ROUND_UP = round_up

	COMPILE_OPT idl2
	COMMON label_date_com, cFormatArray, cMonths, cOffset, $
		cRoundup, cAmpm, cDaysWeek
	ON_ERROR, 2


	IF (N_PARAMS() LT 3) THEN $  ; use default for no inputs
		IF NOT KEYWORD_SET(dateFormat) THEN dateFormat=''


; process a new months vector?
	; if months is undefined, then make cMonths undefined
	IF ARG_PRESENT(months) OR (N_ELEMENTS(months) GT 0) THEN BEGIN
		cMonths = -1
		dummy = TEMPORARY(cMonths)
	ENDIF
	; if months has 12 elements, then copy it to cMonths
	if (N_ELEMENTS(months) EQ 12) then cMonths = months


; process a new days_of_week vector?
	; if days_of_week is undefined, then make cDaysWeek undefined
	IF ARG_PRESENT(days_of_week) OR (N_ELEMENTS(days_of_week) GT 0) THEN BEGIN
		cDaysWeek = -1
		dummy = TEMPORARY(cDaysWeek)
	ENDIF
	; if days_of_week has 2 elements, then copy it to cDaysWeek
	if (N_ELEMENTS(days_of_week) EQ 7) then cDaysWeek = days_of_week


; process a new AM_PM vector?
	; if AM_PM is undefined, then make cAmpm undefined
	IF ARG_PRESENT(am_pm) OR (N_ELEMENTS(am_pm) GT 0) THEN BEGIN
		cAmpm = -1
		dummy = TEMPORARY(cAmpm)
	ENDIF
	; if AM_PM has 2 elements, then copy it to cAmpm
	if (N_ELEMENTS(am_pm) EQ 2) then cAmpm = am_pm


; process a new cOffset?
	IF ARG_PRESENT(offs) THEN cOffset = 0
	IF (N_ELEMENTS(offs) GT 0) THEN cOffset = offs[0]
	; make sure we have an cOffset
	IF (N_ELEMENTS(cOffset) EQ 0) THEN cOffset = 0d


; process a new cRoundup?
	IF (N_ELEMENTS(round_up) GT 0) THEN cRoundup = KEYWORD_SET(round_up)


; process a new date_format string?
	nNewFormat = N_ELEMENTS(dateFormat)
	IF (nNewFormat GT 0) THEN BEGIN
		cFormatArray = STRARR(nNewFormat)
		FOR a=0L,nNewFormat-1 DO cFormatArray[a] = $
			LABEL_DATE_CONVERT_FORMAT(dateFormat[a],cMonths,cAmpm,cDaysWeek)
	ENDIF
	IF (N_ELEMENTS(cFormatArray) EQ 0) THEN cFormatArray = '(C())'


	IF (N_PARAMS() LT 3) THEN RETURN, 0


;------------------------------------------------------ Process an axis value
	value1 = valueIn + cOffset   ; convert to Julian
	date = LONG(value1)   ; Julian date
	time = value1 - date  ; Julian time


	IF (N_ELEMENTS(levelIn) LT 1) THEN levelIn = 0
	nFormat = N_ELEMENTS(cFormatArray)
	formatLevel = cFormatArray[levelIn MOD nFormat]    ; repeat cyclically


; Round subseconds to the desired precision
	secPos = STRPOS(formatLevel, 'CSF')
	; for fractional seconds, need to manually round because the "float"
	; format codes do rounding rather than truncation.
	IF (secPos GE 0) THEN BEGIN
		decimalPoint = STRPOS(formatLevel,'.',secPos)
		sigdigits = 10d^STRMID(formatLevel, decimalPoint + 1, 1)
		time = (ROUND(time*86400d*sigdigits,/L64)+0.1d)/(86400d*sigdigits)
		value1 = date + time
	ENDIF


; Round fractional time to the least significant format specified.
	IF KEYWORD_SET(cRoundup) THEN BEGIN
		; Because the "integer" format codes automatically truncate,
		; just add 1/2 of smallest desired time increment to do rounding.
		; The CASE selections must be in order from smallest units to largest,
		; so that rounding occurs to the least-significant unit.
		CASE 1 OF
			(secPos GE 0):  ; should have already done rounding
			(STRPOS(formatLevel, 'CSI') GE 0): time = time + 0.5d/86400d
			(STRPOS(formatLevel, 'CMI') GE 0): time = time + 0.5d/1440d
			(STRPOS(formatLevel, 'CHI') GE 0): time = time + 0.5/24d
			ELSE:
		ENDCASE
		value1 = date + time
	ENDIF


; check for negative (B.C.E.) years
	jan1_1ad = 1721424L   ; Julian date for 1 Jan, 1 C.E.
	IF (date LT jan1_1ad) THEN BEGIN
		yearPos = STRPOS(formatLevel,'CYI')
		; if there is a year code, then increase width by one for minus sign
		IF (yearPos GE 0) THEN BEGIN
			yearPos = yearPos + 3
			width = STRTRIM(FIX(STRMID(formatLevel,yearPos,1))+1,2)
			formatLevel = STRMID(formatLevel, 0, yearPos) + $
				width + STRMID(formatLevel, yearPos+1)
		ENDIF
	ENDIF

	RETURN, STRING(value1,FORMAT=formatLevel, $
		MONTHS=cMonths,AM_PM=cAmpm,DAYS_OF_WEEK=cDaysWeek)
END
