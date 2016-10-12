; $Id: //depot/idl/releases/IDL_80/idldir/lib/standardize.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       STANDARDIZE
;
; PURPOSE:
;       This function computes standardized variables from an array 
;       of M variables (columns) and N observations (rows). The result
;       is an M-column, N-row array where all columns have a mean of
;       zero and a variance of one.
;
; CATEGORY:
;       Statistics
;
; CALLING SEQUENCE:
;       Result = Standardize(A)
;
; INPUTS:
;       A:    An M-column, N-row array of type float or double.
;
; KEYWORD PARAMETERS:
;       DOUBLE:  If set to a non-zero value, computations are done in
;                double precision arithmetic.
;
; EXAMPLE:
;       Define an array with 4 variables and 20 observations.
;         array = $
;           [[19.5, 43.1, 29.1, 11.9], $
;            [24.7, 49.8, 28.2, 22.8], $
;            [30.7, 51.9, 37.0, 18.7], $
;            [29.8, 54.3, 31.1, 20.1], $
;            [19.1, 42.2, 30.9, 12.9], $
;            [25.6, 53.9, 23.7, 21.7], $
;            [31.4, 58.5, 27.6, 27.1], $
;            [27.9, 52.1, 30.6, 25.4], $
;            [22.1, 49.9, 23.2, 21.3], $
;            [25.5, 53.5, 24.8, 19.3], $
;            [31.1, 56.6, 30.0, 25.4], $
;            [30.4, 56.7, 28.3, 27.2], $
;            [18.7, 46.5, 23.0, 11.7], $
;            [19.7, 44.2, 28.6, 17.8], $
;            [14.6, 42.7, 21.3, 12.8], $
;            [29.5, 54.4, 30.1, 23.9], $
;            [27.7, 55.3, 25.7, 22.6], $
;            [30.2, 58.6, 24.6, 25.4], $
;            [22.7, 48.2, 27.1, 14.8], $
;            [25.2, 51.0, 27.5, 21.1]]
;
;       Compute the mean and variance of each variable using the MOMENT 
;       function. Note: The skewness and kurtosis are also computed.
;         IDL> for k = 0, 3 do print, MOMENT(array[k,*])
;               25.3050      25.2331    -0.454763     -1.10028
;               51.1700      27.4012    -0.356958     -1.19516
;               27.6200      13.3017     0.420289     0.104912
;               20.1950      26.0731    -0.363277     -1.24886
;
;       Compute the standardized variables.
;         IDL> result = STANDARDIZE(array)
;
;       Compute the mean and variance of each standardized variable using 
;       the MOMENT function. Note: The skewness and kurtosis are also computed.
;         IDL> for k = 0, 3 do print, MOMENT(result[k,*])
;                -7.67130e-07      1.00000    -0.454761     -1.10028
;                -3.65451e-07      1.00000    -0.356958     -1.19516
;                -1.66707e-07      1.00000     0.420290     0.104913
;                 4.21703e-07      1.00000    -0.363278     -1.24886
;
; MODIFICATION HISTORY:
;           Written by:  GGS, RSI, February 1996
;-

FUNCTION Standardize, X, Double = Double

  ON_ERROR, 2

  Sx = SIZE(X)

  if Sx[Sx[0]+1] ne 4 and Sx[Sx[0]+1] ne 5 then $
    MESSAGE, "Input array must be float or double."

  if N_ELEMENTS(Double) eq 0 then Double = (Sx[Sx[0]+1] eq 5)

  if Sx[0] eq 2 then begin ;Standardize the columns of X.
    xSTD = FLTARR(Sx[1], Sx[2], /nozero) ;Output array.
    if Double ne 0 then xSTD = DOUBLE(xSTD)
    no = Sx[2]            ;# of observations
    mean = TOTAL(X, 2, DOUBLE = Double) / no ;Vector of Means
    xstd = X - (mean # REPLICATE(1, No))     ;Deviations from means
    stdev = SQRT(TOTAL(xstd^2, 2, Double = Double) / (No-1)) ;Vector of Stdevs
    if Double eq 0 then RETURN, FLOAT(xstd * ((1./stdev) # replicate(1, No))) $
    else RETURN, xstd * ((1./stdev) # replicate(1, No)) ;Normalize by 1./Stdev
  endif $
  else MESSAGE, "Input array must be two-dimensional."

END
