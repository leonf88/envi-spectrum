;$Id: //depot/idl/releases/IDL_80/idldir/lib/meanabsdev.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       MeanAbsDev
;
; PURPOSE:
;       MeanAbsDev computes the mean absolute deviation (average
;       deviation) of a vector or array.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = MeanAbsDev(X)
;
; INPUTS:
;       X:      A vector or array of type integer, float or double.
;
; KEYWORD PARAMETERS:
;
;       DOUBLE: If set to a non-zero value, MEANABSDEV performs its
;               computations in double precision arithmetic and returns
;               a double precision result. If not set to a non-zero value,
;               the computations and result depend upon the type of the
;               input data (integer and float data return float results,
;               while double data returns double results). This has no
;               effect if the Median keyword is set.
;
;       MEDIAN: If set to a non-zero value, meanabsdev will return
;               the average deviation from the median, rather than
;               the mean.  If Median is not set, meanabsdev will return
;               the average deviation from the mean.
;
;       NAN:    If set, treat NaN data as missing.
;
; EXAMPLES:
;       Define the N-element vector of sample data.
;         x = [1, 1, 1, 2, 5]
;       Compute the average deviation from the mean.
;         result = MeanAbsDev( x )
;       The result should be:
;       1.20000
;
;       Compute the average deviation from the median.
;         result = MeanAbsDev( x, /median )
;       The result should be:
;       1.00000
;
; PROCEDURE:
;       MeanAbsDev calls the IDL function MEAN.
;
;       MeanAbsDev calls the IDL function MEDIAN if the Median
;       keyword is set to a nonzero value.
;
; REFERENCE:
;       APPLIED STATISTICS (third edition)
;       J. Neter, W. Wasserman, G.A. Whitmore
;       ISBN 0-205-10328-6
;
; MODIFICATION HISTORY:
;       Written by:  GSL, RSI, August 1997
;		     RJF, RSI, Sep 1998, Removed NaN keyword from Median call
;				         as NaN is not currently supported by
;					 the Median routine.
;   CT, RSI, July 2004: Better handling for NAN keyword, to avoid
;       overflow errors in the ABS call. Also faster & uses less memory.
;
;-
FUNCTION MeanAbsDev, x, Double = dbl, Median = useMedian, NaN = NaN

    compile_opt idl2

    ON_ERROR, 2

    dbl = KEYWORD_SET(dbl)

    ; Filter out NaN values if desired. We do this manually since
    ; neither Median nor Abs can handle NaNs.
    if (KEYWORD_SET(nan)) then begin
        good = where( finite(x), ngood)
        if (ngood gt 0 && ngood lt N_ELEMENTS(x)) then begin
            ; Save a copy of original data.
            xtmp = TEMPORARY(x)
            x = xtmp[TEMPORARY(good)]
        endif
    endif

    n = N_ELEMENTS(x)

    ; Middle will be either single or double precision.
    middle = KEYWORD_SET(useMedian) ? $
        MEDIAN(x, /even, DOUBLE=dbl) : TOTAL(x, DOUBLE=dbl)/n

    if (N_ELEMENTS(xtmp) gt 0) then begin
        ; We can use temporary on x.
        result = TOTAL(ABS(TEMPORARY(x) - middle), DOUBLE=dbl)/n
        ; Restore original data.
        x = TEMPORARY(xtmp)
    endif else begin
        ; Cannot use temporary on x since this is the orig data.
        result = TOTAL(ABS(x - middle), DOUBLE=dbl)/n
    endelse

    return, result
end
