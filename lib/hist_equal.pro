; $Id: //depot/idl/releases/IDL_80/idldir/lib/hist_equal.pro#1 $
;
; Copyright (c) 1982-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

PRO HIST_EQUAL_PCT, hist, pct, low, high
; Given a cumulative histogram and a percent [0-100], return the low and high
; limits for a percentage stretch.
COMPILE_OPT idl2, hidden
ON_ERROR, 2
if pct le 0 or pct ge 100 then $
  message, 'PERCENT must be between 0 and 100.'

; Get bins that contain the pct and (100-pct) cumulative values.
r = VALUE_LOCATE(hist, hist[n_elements(hist)-1] / 100.0 * [pct, 100-pct])
low = r[0]+1                    ;Add one to get top of interval.
high = r[1]                     ;Use bottom of interval for high
end


;
;+
; NAME:
;	HIST_EQUAL
;
; PURPOSE:
;	Return a histogramequalized or modified image or vector.
;
; CATEGORY:
;	Z1 - Image processing, spatially invariant.
;
; CALLING SEQUENCE:
;	Result = HIST_EQUAL(A [, BINSIZE=value] [, /HISTOGRAM_ONLY]
;        [, MAXV=value] [, MINV=value] [, OMAX=variable] [, OMIN=variable]
;        [, PERCENT=value] [, TOP=value] [, FCN=vector])
;
; INPUTS:
;	A:	The array to be histogram-equalized.
;
; KEYWORD PARAMETERS:
;
;   BINSIZE: Size of the bin to use. The default is BINSIZE=1 if A is a byte
;       array, or, for other input types, the default is (MAXV-MINV)/5000.
;
;	HISTOGRAM_ONLY: If set, then return a vector of type LONG containing
;       the cumulative distribution histogram, rather than the histogram
;       equalized array.  Not valid if FCN is specified.
;
;	MAXV: The maximum value to consider. The default is 255 if A is a
;       byte array, otherwise the maximum data value is used.
;       Input elements greater than or equal to MAXV are output as 255.
;
;	MINV: The minimum value to consider. The default is 0 if A is a
;       byte array, otherwise the minimum data value is used.
;       Input elements less than or equal to MINV are output as 0.
;
;   OMAX: Set this keyword to a named variable that, upon exit,
;       contains the maximum data value used in constructing the histogram.
;
;   OMIN: Set this keyword to a named variable that, upon exit,
;       contains the minimum data value used in constructing the histogram.
;
;   PERCENT:	Set this keyword to a value between 0 and 100 to
;       stretch the image histogram. The histogram will be stretched
;       linearly between the limits that exclude the PERCENT fraction
;       of the lowest values, and the PERCENT fraction of the highest
;       values. This is an automatic, semi-robust method of contrast
;       enahncement.
;
;   TOP: 	  The maximum value of the scaled result. If TOP is
;       not specified, 255 is used. Note that the minimum value of the
;       scaled result is always 0.
;
;   FCN:	The desired cumulative probability distribution
;   	function in the form of a 256 element vector.  If
;   	omitted, a linear ramp, which yields equal probability
;   	bins results.  This function is later normalized, so
;   	its magnitude doesn't matter, although it should be
;   	monotonically increasing.

; OUTPUTS:
;	A histogram modified array of type byte is returned, of the
;	same dimensions as the input array. If the HISTOGRAM_ONLY
;	keyword is set, then the output will be a vector of type LONG.
;
; PROCEDURE:
;	The HISTOGRAM function is used to obtain the density distribution of
;	the input array.  The histogram is integrated to obtain the
;	cumulative density-propability function and finally the lookup
;	function is used to transform to the output image.
;
;  Note:
;	The first element of the histogram is always zeroed to remove
;	the background.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None.
;
; RESTRICTIONS:
;   None.
;
; EXAMPLE:
;
;	Create a sample image using the IDL DIST function and display it by
;	entering:
;
;		image = DIST(100)
;		TV, image
;
;	Create a histogram-equalized version of the byte array, IMAGE, and
;	display the new version.  Use a minumum input value of 10, a maximum
;	input value of 200, and limit the top value of the output array to
;	220.  Enter:
;
;		new = HIST_EQUAL(image, MINV = 10, MAXV = 200, TOP = 220)
;		TV, new
;
;	Perform a linear stretch on the input array between the limits
;	determined by excluding 5% of the lowest values, and 5% of the
;	highest	values:
;		NEW = HIST_EQUAL(IMAGE, PERCENT=5)
;
;  To modify the output histogram to a logarithmic cumulative
;  distribution (i.e. more pixels with lower values):
;       y = alog(findgen(256)+1)   ;a log shaped curve
;       TV, Hist_Equal(A, FCN = y)
;
;  The following example modifies the histogram to a gaussian
;  probability (not cumulative) distribution.  This results in most of
;  the pixels having an intensity near the midrange:
;	x = findgen(256)/255.	   ;Ramp from 0 to 1.
;	y=exp(-((x-.5)/.2)^2)      ;Gaussian centered at middle, full
;				   ;width at 1/2 max ~ 0.4
;		;Form cumulative distribution, transform and display:
;       TVSCL, Hist_Equal(A, FCN = TOTAL(y, /CUMULATIVE))
;
; MODIFICATION HISTORY:
;
;	August, 1982. Written by DMS, RSI.
;	Feb, 1988, Revised for Sun, DMS.
;	Dec, 1994. DMS. Improved handling offloating/double images with
;			large or small ranges.  Default value for MINV is
;			computed, rather than set to 0.
;	Oct, 1996. DMS. Made the handling of MIN=, and MAX= consistent
;			for all data types.
;   July 2000, CT, RSI: Completely rewrote.
;           Now handles new integer types;
;           can use BINSIZE with byte input;
;           added OMAX, OMIN;
;           HISTOGRAM_ONLY now returns LONG array.
;   Aug 2003, CT, RSI: Better error handling. Fix problem with unsigned ints.
;-
;
FUNCTION HIST_EQUAL, array, BINSIZE = binsize, $
	MAXV = maxv, MINV = minv, OMAX=omax, OMIN=omin, $
	TOP = topIn, HISTOGRAM_ONLY=histogram_only, PERCENT=pct, $
        FCN=fcn_in

	compile_opt idl2

	ON_ERROR, 2                      ;Return to caller if an error occurs

	type = SIZE(array, /TYPE)                     ;Type of var?
	if (type eq 0) then $
	    MESSAGE, 'Input argument is undefined.'
	if ((type ge 6) && (type le 11)) then $
	    MESSAGE, 'Illegal type for input argument.'

    top = (N_ELEMENTS(topIn) eq 1) ? topIn[0] : 255
	dmin = 0     ; defaults for byte input
	dmax = 255
	no_max = N_ELEMENTS(maxv) EQ 0
	no_min = N_ELEMENTS(minv) EQ 0
	IF (type ne 1) && (no_min || no_max) THEN $
		dmin = MIN(array, MAX=dmax, /NAN)   ;Get data range

	omax = no_max ? dmax : maxv
	omin = no_min ? dmin : minv
	if (omax le omin) then $
		message,'MINV must be less than MAXV.'

    if n_elements(binsize) eq 0 then begin ;Calc binsize?
    	factor = 5000d
    	nan = 0   ; default is not to search for NaN
       	switch type of
        	1: begin & binsize = 1 & break & end
        	4: ; Float or double
        	5: begin
        		binsize = (omax-omin) / factor
        		nan = 1
        		break
        		end
        	2:  ; int or uint
        	12: begin  ; promote to larger type
        		binsize = CEIL((long(omax)-long(omin)) / factor) > 1
        		break
        		end
        	3:  ; long, ulong, long64
        	13:
        	14: begin  ; promote to larger type
        		binsize = CEIL((LONG64(omax)-LONG64(omin)) / factor, /L64) > 1
        		break
        		end
        	15: begin  ; ulong64
        		binsize = CEIL((omax-omin) / factor) > 1  ; can't promote
        		break
        		end
        	else: MESSAGE, 'Internal error.'
    	endswitch
    endif                       ;Binsize

	if (binsize LE 0) then $
		message,'BINSIZE must be greater than zero.'

    hist = HISTOGRAM(array, MIN=omin, MAX = omax, BINSIZE=binsize, NAN=nan)
    hist[0] = 0
    hist = TOTAL(TEMPORARY(hist), /CUMULATIVE, /DOUBLE)   ;Cumul. integral
    if keyword_set(histogram_only) then return, LONG(hist)
    if keyword_set(pct) then begin ;Percentage stretch?
        HIST_EQUAL_PCT, hist, pct, bottom, top
        return, BYTSCL(array, TOP=top, MIN=omin + binsize * bottom, $
                       MAX = omin + binsize * top)
    endif

    if keyword_set(fcn_in) then begin
        y2 = bytscl(total(histogram(bytscl(fcn_in)), /CUM), TOP=top)
        hist = y2[bytscl(hist)]
    endif else begin
        hist = BYTSCL(TEMPORARY(hist), TOP = top)
    endelse

    ; Be sure to clip to values >= omin to avoid unsigned int overflow.
    if binsize eq 1 then $
      return, (omin EQ 0) ? hist[array] : hist[(array > omin) - omin]
    return, (omin EQ 0) ? hist[array/binsize] : $
        hist[((array > omin) - omin)/binsize]
end
