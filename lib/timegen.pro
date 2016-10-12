; $Id: //depot/idl/releases/IDL_80/idldir/lib/timegen.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   TIMEGEN
;
; PURPOSE:
;   The TIMEGEN function returns an array (with the specified dimensions)
;   of double-precision floating-point values that represent times
;   in terms of Julian dates.
;
; CALLING SEQUENCE:
;
;   Result = TIMEGEN([D1,...,D8]
;       [, START=value [, FINAL=value]]
;       [, STEP_SIZE=value] [, UNITS=string]
;       [, YEAR=value] [, MONTH=vector] [, DAY= vector]
;       [, HOUR= vector] [, MINUTE= vector] [, SECOND= vector])
;
; INPUTS:
;
;   Di   The dimensions of the result.
;
; KEYWORD PARAMETERS:
;
;   DAY    If UNITS is set to "Years" or "Months",
;          then set this keyword to a scalar or a vector giving the
;          day values that should be included within each month.
;          If UNITS is set to "Days", "Hours", "Minutes", or "Seconds",
;          then set this keyword to a scalar giving the starting day
;          (in this case the day from START is ignored).
;
;   FINAL  Set this keyword to a double-precision value representing the
;          Julian date/time to use as the last value in the returned array.
;          In this case, the dimension arguments are ignored and
;          Result is a one-dimensional array, with the number of elements
;          depending upon the step size. The FINAL time may be less than the
;          START time, in which case STEP_SIZE should be negative.
;
;      Note - If the step size is not an integer then the last element
;          may not be equal to the FINAL time. In this case, TIMEGEN will
;          return enough elements such that the last element
;          is less than or equal to FINAL.
;
;   HOUR   If UNITS is set to "Years", "Months", or "Days",
;          then set this keyword to a scalar or a vector giving the
;          hour values that should be included within each day.
;          If UNITS is set to "Hours", "Minutes", or "Seconds",
;          then set this keyword to a scalar giving the starting hour
;          (in this case the hour from START is ignored).
;
;   MINUTE If UNITS is set to "Years", "Months", "Days", or "Hours",
;          then set this keyword to a scalar or a vector giving the
;          minute values that should be included within each hour.
;          If UNITS is set to "Minutes", or "Seconds",
;          then set this keyword to a scalar giving the starting minute
;          (in this case the minute from START is ignored).
;
;   MONTH  If UNITS is set to "Years",
;          then set this keyword to a scalar or a vector giving the
;          month values that should be included within each year.
;          If UNITS is set to "Months", "Days", "Hours", "Minutes", or
;          "Seconds", then set this keyword to a scalar giving the starting
;          month (in this case the month from START is ignored).
;
;   SECOND If UNITS is set to "Years", "Months", "Days", "Hours",or "Minutes",
;          then set this keyword to a scalar or a vector giving the
;          second values that should be included within each minute.
;          If UNITS is set to "Seconds",
;          then set this keyword to a scalar giving the starting second
;          (in this case the second from START is ignored).
;
;   START  Set this keyword to a double-precision value representing the
;          Julian date/time to use as the first value in the returned array.
;          The default is 0.0d [January 1, 4713 B.C.E. at 12 pm (noon)].
;
;     Note - If subintervals are provided by MONTHS, DAYS, HOURS, MINUTES, or
;          SECONDS, then the first element may not be equal to the START time.
;          In this case the first element in the returned array will be
;          greater than or equal to START.
;
;   STEP_SIZE Set this keyword to a scalar value representing the step size
;          between the major intervals of the returned array.
;          The step size may be negative. The default step size is 1.
;          For UNITS="Years" or "Months", the STEP_SIZE value is rounded
;          to the nearest integer.
;
;   UNITS  Set this keyword to a scalar string indicating the time units
;          to be used for the major intervals for the generated array.
;          Valid values include:
;                "Years" or "Y"
;                "Months" or "M"
;                "Days" or "D"
;                "Hours" or "H"
;                "Minutes" or "I"
;                "Seconds" or "S"
;          The case (upper or lower) is ignored.
;          If this keyword is not specified, then the default for UNITS is
;          given by the next-largest time unit that is not specified
;          by a keyword. If none of the keywords are present then the
;          default is UNITS="Days".
;
;   YEAR   Set this keyword to a scalar giving the starting year.
;          If YEAR is specified then the year from START is ignored.
;
; OUTPUT:
;   The result returned by TIMEGEN is a double-precision array.
;
; PROCEDURE:
;   Uses CALDAT, JULDAY.
;
; EXAMPLE:
;
;  1. Generate an array of 366 time values that are one day apart:
;            MyDates = TIMEGEN(366, START=JULDAY(1,1,2000))
;
;  2. Generate an array of 20 time values that are 12 hours apart:
;            MyTimes = TIMEGEN(20, UNITS="Hours", STEP_SIZE=12, $
;                      START=SYSTIME(/JULIAN))
;
;  3. Generate an array of time values that are 1 hour apart from
;     1 January 2000 until the current time:
;            MyTimes = TIMEGEN(START=JULDAY(1,1,2000), $
;                      FINAL=SYSTIME(/JULIAN), UNITS="Hours")
;
;  4. Generate an array of time values composed of [seconds, minutes, hours]
;     that start from the current hour:
;            MyTimes = TIMEGEN(60, 60, 24, $
;                      START=FLOOR(SYSTIME(/JULIAN)*24)/24d, UNITS="S")
;
;  5. Generate an array of 24 time values with monthly intervals, but with
;     subintervals at 5 pm on the first and fifteenth of each month:
;            MyTimes = TIMEGEN(24, START=FLOOR(SYSTIME(/JULIAN)), $
;                      DAYS=[1,15],HOUR=17)
;
; MODIFICATION HISTORY:
;   Written by: CT, RSI, May 2000.
;
;-



; TIMEGEN_REBIN
;  This routine embeds time values of a certain unit (such as minutes)
;  within an array of smaller (seconds) and larger (hours) time units.
;
;  timeIn = Vector of time values of length nTime (months, days, hours, etc.).
;  nSmaller = Number of smaller time values to embed within timeIn.
;  nTotal = Expand timeIn (nTime+nSmaller) out to this larger size by
;          cyclically repeating the values.
;
FUNCTION timegen_rebin, timeIn, nSmaller, nTotal, $
	FACTOR=factor

	COMPILE_OPT hidden,idl2
	ON_ERROR, 2

	IF KEYWORD_SET(factor) THEN timeIn = TEMPORARY(timeIn)/factor
	nTime = N_ELEMENTS(timeIn)
	; if 1-element array or scalar, return a scalar
	IF (nTime EQ 1) THEN RETURN, timeIn[0]
	; if there are "smaller" units (e.g. seconds compared to minutes),
	; then repeat each timeIn element nSmaller number of times
	IF (nSmaller GT 1) THEN BEGIN
		timeIn = REBIN(REFORM(TEMPORARY(timeIn),1,nTime), nSmaller, nTime)
		nTime = nSmaller*nTime   ; new number of current times
	ENDIF
	; now embed the array within the larger time units by cyclically
	; repeating the set of timeIn (nTime+nSmaller) values to get
	; a total number nTotal
	IF (nTotal GT nTime) THEN BEGIN
		timeIn = REBIN(REFORM(TEMPORARY(timeIn),nTime), $
			nTime, (nTotal+nTime-1)/nTime)
		; we may have up to nTime-1 extra elements,
		; so strip them off before returning
		IF (N_ELEMENTS(timeIn) NE nTotal) THEN timeIn = timeIn[0:nTotal-1]
	ENDIF
	RETURN, timeIn
END


; TIMEGEN_DAY_CHECK
;  This routine truncates day values so they are within the day range
;  for each month.
;
;  monthArray = Vector of month values.
;  dayArray = Vector of day values.
;  yearArray = Vector of year values.
;
;  Returns dayArray truncated to be <= to max for each month.
;
FUNCTION timegen_day_check, monthArray, dayArray, yearArray

	COMPILE_OPT hidden,idl2
	ON_ERROR, 2
	dayArray = TEMPORARY(dayArray) > 1
	IF (MAX(dayArray) GT 28) THEN BEGIN
		; B.C.E. years are offset by 1
		yearArray1 = yearArray + (yearArray LT 0)
		; years divisible by 4 are leap years
		div4 = (yearArray1 MOD 4) EQ 0
		; years divisible by 100 are not leap years (except before 1582)
		notdiv100 = ((yearArray1 MOD 100) NE 0) OR (yearArray1 LT 1582)
		; except years divisible by 400, which are leap years
		div400 = (yearArray1 MOD 400) EQ 0
		leapYear = (monthArray EQ 2) AND ((div4 AND notdiv100) OR div400)
        ; day lengths for each month (29 February days for leap years)
        ;                Ja Fe Ma Ap Ma Ju Jy Au Se Oc No De
        monthLength = [0,31,28,31,30,31,30,31,31,30,31,30,31]
		monthCheck = monthLength[monthArray] + leapYear
		dayArray = TEMPORARY(dayArray) < monthCheck
	ENDIF
	RETURN, dayArray
END


;***************************************************** start of main routine
FUNCTION timegen, d1, d2, d3, d4, d5, d6, d7, d8, $
	START=startIn, FINAL=finalIn, $
	STEP_SIZE=step_sizeIn, $
	UNITS=unitsIn, $
	YEAR=yearIn, MONTHS=monthIn, DAYS=dayIn, $
	HOURS=hourIn, MINUTES=minuteIn, SECONDS=secondIn

	COMPILE_OPT strictarr



;-----------------------------------------------------------------------------
; error & keyword checking
	ON_ERROR, 2

	finalSpecified = N_ELEMENTS(finalIn) GT 0
	nParam = N_PARAMS()
	IF (((nParam EQ 0) AND NOT finalSpecified)) THEN $
		MESSAGE, 'Incorrect number of arguments.'


	IF (N_ELEMENTS(startIn) LT 1) THEN startIn = 0d
	start = DOUBLE(startIn[0])  ; only use first element
	final= finalSpecified ? DOUBLE(finalIn[0]) : start

	; process keyword step_size
	IF (N_ELEMENTS(step_sizeIn) LT 1) THEN step_sizeIn = 1d
	step_size = DOUBLE(step_sizeIn[0])  ; only use first element



;-----------------------------------------------------------------------------
; Determine the default units
	n = {Second:N_ELEMENTS(secondIn), Minute:N_ELEMENTS(minuteIn), $
		Hour:N_ELEMENTS(hourIn), Day:N_ELEMENTS(dayIn), $
		Month:N_ELEMENTS(monthIn), Year:N_ELEMENTS(yearIn)}

; process keyword units
; If no units are specified, then units is equal to the unit that is
; greater than the "largest" keyword. The default is days.
	IF (N_ELEMENTS(unitsIn) LT 1) THEN BEGIN
		; the CASE will match the FIRST (largest) keyword
		CASE 1 OF
		;   (n.Year doesn't count because YEAR just specifies starting year)
			(n.Month GT 0):  unitsIn = 'y'
			(n.Day GT 0):    unitsIn = 'm'
			(n.Hour GT 0):   unitsIn = 'd'
			(n.Minute GT 0): unitsIn = 'h'
			(n.Second GT 0): unitsIn = 'i'
			ELSE: unitsIn = 'd'  ; default is days
		ENDCASE
	ENDIF

	units = STRLOWCASE(STRTRIM(unitsIn[0],2))  ; only use first element
	; units for minutes is "i", otherwise just use first character
	; (only use first 3 chars so "minute" & "minutes" both become "min")
	units = (STRMID(units,0,3) EQ 'min') ? 'i' : STRMID(units,0,1)



;-----------------------------------------------------------------------------
; find the starting time, either from START or from the YEAR, MONTH keywords
	CALDAT, start, monthStart, dayStart, yearStart, $
		hourStart, minuteStart, secondStart
	; defaults
	secondArray = (n.Second EQ 0) ? secondStart : secondIn
	minuteArray = (n.Minute EQ 0) ? minuteStart : minuteIn
	hourArray = (n.Hour EQ 0) ? hourStart : hourIn
	dayArray = (n.Day EQ 0) ? dayStart : dayIn
	monthArray = (n.Month EQ 0) ? monthStart : monthIn
	yearArray = (n.Year EQ 0) ? yearStart : yearIn
	; we should now have at least 1 of each unit
	n.Second = n.Second > 1
	n.Minute = n.Minute > 1
	n.Hour = n.Hour > 1
	n.Day = n.Day > 1
	n.Month = n.Month > 1

	; throw an error for invalid month number...
	IF (TOTAL((monthArray LT 1) OR (monthArray GT 12)) NE 0) THEN $
		MESSAGE, 'Value is out of range (1<=MONTH<=12).'

	; restrict day range to be >0 and <=last day of month
	dayStart = TIMEGEN_DAY_CHECK(monthArray[0],dayArray[0],yearArray[0])

	; make sure to get the correct START in case it changed...
	start = JULDAY(monthArray[0], dayStart, yearArray[0], $
		hourArray[0], minuteArray[0], secondArray[0])



;-----------------------------------------------------------------------------
; Determine the number of elements and subintervals,
; reset the higher intervals to have only 1 element.
	CASE units OF
		'y': BEGIN  ; years
			nSub = n.Month*n.Day*n.Hour*n.Minute*n.Second
			step_size = ROUND(step_size)
			END
		'm': BEGIN  ; months
			nSub = n.Day*n.Hour*n.Minute*n.Second
			step_size = ROUND(step_size)
			END
		'd': BEGIN  ; days
			nSub = n.Hour*n.Minute*n.Second
			n.Month = 1  ; ignore larger units
			END
		'h': BEGIN  ; hours
			nSub = n.Minute*n.Second
			n.Day = (n.Month = 1)  ; ignore larger units
			END
		'i': BEGIN  ; minutes
			nSub = n.Second
			n.Hour = (n.Day = (n.Month = 1))  ; ignore larger units
			END
		's': BEGIN  ; seconds
			nSub = 1
			n.Minute = (n.Hour = (n.Day = (n.Month = 1)))  ; ignore larger
			END
		ELSE: MESSAGE,'Illegal value for keyword UNITS.'
	ENDCASE



;-----------------------------------------------------------------------------
; Find the output dimensions
	IF (finalSpecified) THEN BEGIN  ; vector result
		; only return "nSub" elements if start, final, step_size conflict
		IF ((start LT final) AND (step_size LE 0)) OR $
			((start GT final) AND (step_size GE 0)) THEN final = start
		CASE units OF
			'y': stepFactor = 365d
			'm': stepFactor = 28d
			'd': stepFactor = 1d
			'h': stepFactor = 1d/24d
			'i': stepFactor = 1d/1440d
			's': stepFactor = 1d/86400d
		ENDCASE
		diff = ABS(final - start)
		nDaysPerStep = stepFactor*ABS(step_size) $
			+ (diff EQ 0) ; avoid divide by zero
		; add extra nSub, in case FINAL is in the middle of subintervals
		nElements = CEIL(diff/nDaysPerStep*nSub) + nSub
	ENDIF ELSE BEGIN  ; (multi)dimensional result.
		; construct vector with list of dimensions
		dimensions = ULON64ARR(nParam) + 1
		SWITCH nParam OF
			8: dimensions[7] = d8
			7: dimensions[6] = d7
			6: dimensions[5] = d6
			5: dimensions[4] = d5
			4: dimensions[3] = d4
			3: dimensions[2] = d3
			2: dimensions[1] = d2
			1: dimensions[0] = d1
		ENDSWITCH
		; find total number of elements
		nElements = dimensions[0]
		FOR i=1L,nParam-1 DO nElements = nElements*dimensions[i]
		IF (nElements EQ 0) THEN MESSAGE, $
			'Array dimensions must be greater than 0.'
	ENDELSE
	; add extra nSub, in case START is in the middle of subintervals
	nExpandedSize = nElements + nSub



;-----------------------------------------------------------------------------
; Construct the appropriate unit array
	dayGen = 0d
	nMajorInterval = (nExpandedSize + nSub - 1)/nSub
	CASE units OF
		'y': BEGIN  ; years
			n.Year = nMajorInterval
			yearArray = yearArray[0] + step_size*LINDGEN(nMajorInterval)
			END
		'm': BEGIN  ; months
			n.Month = nMajorInterval
			monthArray = monthArray[0] - 1 + step_size*LINDGEN(nMajorInterval)
			yearArray = yearArray[0] + FLOOR(monthArray/12d)
			if (step_size ge 0) then begin
			  monthArray = (monthArray mod 12) + 1
			endif else begin
			  monthArray = (((monthArray mod 12) + 12) mod 12) + 1
			endelse
			END
		'd': BEGIN  ; days
			n.Day = nMajorInterval
			dayGen = step_size*DINDGEN(nMajorInterval)   ; special case
			END
		'h': BEGIN  ; hours
			n.Hour = nMajorInterval
			hourArray = hourArray[0] + step_size*DINDGEN(nMajorInterval)
			END
		'i': BEGIN  ; minutes
			n.Minute = nMajorInterval
			minuteArray = minuteArray[0] + step_size*DINDGEN(nMajorInterval)
			END
		's': BEGIN  ; seconds
			n.Second = nMajorInterval
			secondArray = secondArray[0] + step_size*DINDGEN(nMajorInterval)
			END
		ELSE: MESSAGE,'Internal error in CASE statement.'
	ENDCASE



;-----------------------------------------------------------------------------
; Construct day fraction array
	nHourMinuteSecond = n.Hour*n.Minute*n.Second
	hourArray = TIMEGEN_REBIN(TEMPORARY(hourArray)-12, $
		n.Second*n.Minute, nHourMinuteSecond, FACTOR=24d)
	time = TEMPORARY(hourArray)
	minuteArray = TIMEGEN_REBIN(TEMPORARY(minuteArray), $
		n.Second, nHourMinuteSecond, FACTOR=1440d)
	time = TEMPORARY(time) + TEMPORARY(minuteArray)
	secondArray = TIMEGEN_REBIN(TEMPORARY(secondArray), $
		1, nHourMinuteSecond, FACTOR=86400d)
	time = TEMPORARY(time) + TEMPORARY(secondArray)



;-----------------------------------------------------------------------------
; Construct Julian dates
; For months or years we need to check if months & days are valid,
; then call JULDAY to convert to Julian dates.
	IF ((units EQ 'y') OR (units EQ 'm')) THEN BEGIN
		; construct day, month, year arrays
		nDates = (nExpandedSize+nHourMinuteSecond-1)/nHourMinuteSecond

		; are we crossing the "zero AD" line?
		IF ((MAX(yearArray) GE 0) AND (MIN(yearArray) LE 0)) THEN BEGIN
			; if step_size positive, add 1 to positive years
			; if step_size negative, subtract 1 from negative years
			yearArray = yearArray + $
				((step_size GE 0) ? (yearArray GE 0) : -1*(yearArray LE 0))
		ENDIF

		; embed subintervals for day, month, year
		dayArray = TIMEGEN_REBIN(TEMPORARY(dayArray), 1, nDates)
		monthArray = TIMEGEN_REBIN(TEMPORARY(monthArray), n.Day, nDates)
		nDayMonthSub = (units EQ 'y') ? n.Day*n.Month : n.Day
		yearArray = TIMEGEN_REBIN(TEMPORARY(yearArray), nDayMonthSub, nDates)

	ENDIF ELSE BEGIN
		; just take the first month, day, year as starting date
		monthArray = monthArray[0]
		dayArray = dayArray[0]
		yearArray = yearArray[0]
	ENDELSE

	; make sure maximum day number is within range for each month
	dayArray = TIMEGEN_DAY_CHECK( monthArray, dayArray, yearArray)

	; find the Julian date values
	date = TEMPORARY(dayGen) + $
		JULDAY(TEMPORARY(monthArray),TEMPORARY(dayArray),TEMPORARY(yearArray))


; combine dates & times by expanding each of them to correct size
	time = TIMEGEN_REBIN(TEMPORARY(time), 1, nExpandedSize)
	date = TIMEGEN_REBIN(TEMPORARY(date), nHourMinuteSecond, nExpandedSize)

; Add a small offset so we get the hours, minutes, & seconds back correctly
; if we convert the Julian dates back. This offset is proportional to the
; Julian date, so small dates (a long, long time ago) will be "more" accurate.
	eps = (MACHAR(/DOUBLE)).eps
	epsArray = date*eps > eps    ; if date=0 then just use eps
	times = TEMPORARY(date) + TEMPORARY(time) + TEMPORARY(epsArray)



;-----------------------------------------------------------------------------
; Restrict range to lie between START and FINAL
	epsStart = start*eps > eps  ; avoid roundoff errors...
	timeStart = times[0:nSub]
	; depends upon whether you are stepping forward in time or backwards.
	startIndex = (step_size GE 0) ? $
		MIN(WHERE(timeStart GE (start-epsStart))) : $
		MIN(WHERE(timeStart LE (start+epsStart)))
	startIndex = startIndex > 0
	finalIndex = startIndex + nElements - 1

	IF (finalSpecified) THEN BEGIN
		epsFinal = final*eps > eps
		; depends upon whether you are stepping forward in time or backwards.
		CASE 1 OF
			(step_size EQ 0): finalIndex = startIndex
			(step_size GT 0): finalIndex = $
				MAX(WHERE(times LE (final+epsFinal)))
			ELSE: finalIndex = MAX(WHERE(times GE (final-epsFinal)))
		ENDCASE
		finalIndex = finalIndex > startindex
		dimensions = finalIndex - startIndex + 1
	ENDIF

	times = times[startIndex:finalIndex]
	IF (nParam GT 1) THEN times = REFORM(TEMPORARY(times), dimensions)

	RETURN, times

END
