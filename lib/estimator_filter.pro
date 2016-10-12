; $Id: //depot/idl/releases/IDL_80/idldir/lib/estimator_filter.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
FUNCTION _EF_TRUNCATED_MEAN_FILTER, inputArray, truncationPercentile, $
  neighbourhoodWidth, neighbourhoodHeight

  COMPILE_OPT IDL2, HIDDEN 

  if truncationPercentile eq 100 then $
    return, ESTIMATOR_FILTER(inputArray, neighbourhoodWidth, $
    neighbourhoodHeight, /MEDIAN)
  if truncationPercentile eq 0 then $
    return, MEAN_FILTER(inputARray, neighbourhoodWidth, neighbourhoodHeight)

  result = MAKE_ARRAY(SIZE(inputArray, /DIMENSIONS), $
  TYPE=SIZE(inputArray, /TYPE))

  dimensions = SIZE(inputArray, /DIMENSIONS)

  d_x = dimensions[0]
  d_y = dimensions[1]
  r_x = (neighbourhoodWidth-1)/2
  r_y = (neighbourhoodHeight-1)/2

  for x=0,d_x-1 do begin
    for y=0,d_y-1 do begin
      x_min = x-r_x ge 0 ? x-r_x : 0
      x_max = x+r_x le d_x-1 ? x+r_x : d_x-1

      y_min = y-r_y ge 0 ? y-r_y : 0
      y_max = y+r_y le d_y-1 ? y+r_y : d_y-1

      neighbourhoodArray = inputArray[x_min:x_max,y_min:y_max]

      n = (truncationPercentile/100.)*(N_ELEMENTS(neighbourhoodArray)-1)+1
      n = FIX(n/2)

      truncatedIndices = SORT(neighbourhoodArray)
      truncatedIndices = truncatedIndices[n:N_ELEMENTS(truncatedIndices)-1-n]

      truncatedMean = MEAN(neighbourhoodArray[truncatedIndices])

      result[x,y] = truncatedMean

    end
  end

  return, result
end

;-------------------------------------------------------------------------
FUNCTION _EF_MEDIAN_FILTER, inputArray, neighbourhoodWidth, $
  neighbourhoodHeight

  COMPILE_OPT IDL2, HIDDEN 

  dimensions = SIZE(inputArray, /DIMENSIONS)

  d_x = dimensions[0]
  d_y = dimensions[1]
  r_x = (neighbourhoodWidth-1)/2
  r_y = (neighbourhoodHeight-1)/2

  workingInput = MAKE_ARRAY(d_x,d_y,neighbourhoodWidth*neighbourhoodHeight, $
  TYPE=4)

  for x = -r_x, r_x do begin
    for y = -r_y, r_y do begin			
      shiftedInput = FIX(shift(inputArray, x, y), TYPE=4)

      if x lt 0 then begin
        shiftedInput[d_x+x:d_x-1,*] = !VALUES.F_NAN
      endif else if x gt 0 then begin
        shiftedInput[0:x-1,*] = !VALUES.F_NAN
      end

      if y lt 0 then begin
        shiftedInput[*,d_y+y:d_y-1] = !VALUES.F_NAN
      endif else if y gt 0 then begin
        shiftedInput[*,0:y-1] = !VALUES.F_NAN
      end

      workingInput[*,*,(y+r_y)*neighbourhoodWidth+(x+r_x)] = shiftedInput
    end
  end

  result = MEDIAN(workingInput, DIMENSION=3, /EVEN)

  return, result
end


;-------------------------------------------------------------------------
FUNCTION _EF_MIDPOINT_FILTER, inputArray, neighbourhoodWidth, $
  neighbourhoodHeight

  COMPILE_OPT IDL2, HIDDEN 

  dimensions = SIZE(inputArray, /DIMENSIONS)

  d_x = dimensions[0]
  d_y = dimensions[1]
  r_x = (neighbourhoodWidth-1)/2
  r_y = (neighbourhoodHeight-1)/2

  min = inputArray
  max = inputArray

  for x = -r_x, r_x do begin
    for y = -r_y, r_y do begin
      shiftedInput = shift(inputArray, x, y)


      if x lt 0 then begin
        shiftedInput[d_x+x:d_x-1,*] = inputArray[d_x+x:d_x-1,*]
      endif else if x gt 0 then begin
        shiftedInput[0:x-1,*] = inputArray[0:x-1,*]
      end

      if y lt 0 then begin
        shiftedInput[*,d_y+y:d_y-1] = inputArray[*,d_y+y:d_y-1]
      endif else if y gt 0 then begin
        shiftedInput[*,0:y-1] = inputArray[*,0:y-1]
      end

      min = min < shiftedInput
      max = max > shiftedInput	
    end
  end

  return, (min+max)/2
end

;+
; NAME:
;   ESTIMATOR_FILTER
;
; PURPOSE:
;   Performs a mean filter noisereduction on a 2D array
;
; CALLING SEQUENCE:
;   result = ESTIMATOR_FILTER(inputArray, width)
;
; PARAMETERS:
;   ImageData:
;     A two-dimensional array containing the pixel values of the input image.
;
;   Width:
;     The width of the two-dimensional neighbourhood to be used
;     
;   Height:
;     The height of the two-dimensional neighbourhood to be used
;     
; KEYWORDS:
;   Median:
;     Set this keyword to calculate the median on each neighbourhood.
;
;   Midpoint:
;     Set this keyword to calculate the midpoint on each neighbourhood.
;     
;   Truncate:
;     Set this keyword to a value between 0 and 100, representing the
;     percentage of total data to be trimmed from the truncated, or 
;     alphatrimmed, mean on each neighbourhood.
;     
;   NAN:
;     Set this keyword to cause the routine to check for occurrences of the
;     IEEE floating-point values NaN or Infinity in the input data. Pixels
;     with the value NaN or Infinity are treated as missing data.
;     
;   Invalid:
;     Set this keyword to a scalar value of the same type as ImageData that
;     should be used to indicate missing or invalid data
;     
;   Missing:
;     Set this keyword to a numeric value to return for elements which
;     contain missing data.
;     
; RETURN VALUE:
;   An array of the same dimensions and type as ImageData containing the 
;   filtered image.
;
; MODIFICATION HISTORY:
;   Created by:  Turing Eret, December 2008
;-
FUNCTION ESTIMATOR_FILTER, inputArray, neighbourhoodWidth, $
  neighbourhoodHeight, $
  MEDIAN=medianFlag, $
  MIDPOINT=midpointFlag, $
  TRUNCATE=truncationPercentile, $
  NAN=nanFlag, $
  INVALID=invalidValue, $
  MISSING=missingValue

  COMPILE_OPT IDL2

  ON_ERROR, 2

  numberOfDimensions = SIZE(inputArray, /N_DIMENSIONS)
  dimensions = SIZE(inputArray, /DIMENSIONS)
  typeOfInput = SIZE(inputArray, /TYPE)

  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Handle all the flags.
  ;;;;;;;;;;;;;;;;;;;;;;;;
  
  nanFlag = KEYWORD_SET(nanFlag)
  if N_ELEMENTS(invalidValue) eq 0 then invalidFlag = 0 else invalidFlag = 1
  if N_ELEMENTS(missingValue) eq 0 then missingFlag = 0 else missingFlag = 1

  medianFlag = KEYWORD_SET(medianFlag)
  midpointFlag = KEYWORD_SET(midpointFlag)
  if N_ELEMENTS(truncationPercentile) eq 0 then $
    truncationFlag = 0 else truncationFlag = 1

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Respond to flag input or make changes.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if N_ELEMENTS(neighbourhoodWidth) eq 0 then $
  MESSAGE, 'Width must be set.'

  if N_ELEMENTS(neighbourhoodHeight) eq 0 then $
  neighbourhoodHeight = neighbourhoodWidth

  if TOTAL([medianFlag, midPointFlag, truncationFlag] ne 0) gt 1 then $
  MESSAGE, 'Set only one of MEDIAN, MIDPOINT, or TRUNCATE.'

  if TOTAL([medianFlag, midPointFlag, truncationFlag] ne 0) eq 0 then $
  medianFlag = 1

  if (neighbourhoodHeight mod 2 eq 0) || (neighbourhoodWidth mod 2 eq 0) then $
  MESSAGE, 'Height and width must be odd.'

  if (neighbourhoodHeight lt 3) || (neighbourhoodWidth lt 3) then $
  MESSAGE, 'Height and width must be greater than or equal to 3.'

  if (neighbourhoodHeight gt 2*dimensions[0]) || $
  (neighbourhoodWidth gt 2*dimensions[1]) then $
  MESSAGE, 'Height and width must be less than twice the input size.'

  if (numberOfDimensions ne 2) then $
  MESSAGE, 'Input must be a two dimensional array.'

  if (truncationFlag eq 1) && $
  (truncationPercentile gt 100 || truncationPercentile lt 0) then $
  MESSAGE, 'TRUNCATE value should be between 0 and 100.'

  if missingFlag eq 1 && ~(nanFlag eq 1 || invalidFlag eq 1) then $
  MESSAGE, 'MISSING keyword only works if NAN and/or INVALID is also set.'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Perform any setup of data.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if typeOfInput eq 4 || typeOfInput eq 5 then begin
    calculationType = typeOfInput
  endif else begin
    calculationType = 4
  end

  fixedInput = FIX(inputArray, TYPE=calculationType)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Here, we do the actual work.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Change all invalid/NaN values to NaN for the sake of consistency.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if invalidFlag eq 1 then $
  invalidIndices = WHERE(fixedInput eq invalidValue, invalidCount) $
  else invalidCount = 0
  if nanFlag eq 1 then $
  nanIndices = WHERE(FINITE(fixedInput, /NAN) OR $
  FINITE(fixedInput, /INFINITY), nanCount) $
  else nanCount = 0

  if missingFlag eq 1 then begin
    if invalidCount ne 0 then begin
      fixedInput[invalidIndices] = missingValue
    endif
    if nanCount ne 0 then begin
      fixedInput[nanIndices] = missingValue
    endif

    nanFlag = 0
  endif else begin
    if invalidCount ne 0 then begin
      fixedInput[invalidIndices] = !VALUES.F_NAN
    endif

    nanFlag = 1
  endelse

  ;; Call the appropriate filter function depending on the flags.
  if midpointFlag ne 0 then begin
    return, FIX(_EF_MIDPOINT_FILTER(fixedInput, neighbourhoodWidth, $
    neighbourhoodHeight), TYPE=typeOfInput)
  endif else if medianFlag ne 0 then begin
    return, FIX(_EF_MEDIAN_FILTER(fixedInput, neighbourhoodWidth, $
    neighbourhoodHeight), TYPE=typeOfInput)
  endif else begin
    return, FIX(_EF_TRUNCATED_MEAN_FILTER(fixedInput, truncationPercentile, $
    neighbourhoodWidth, neighbourhoodHeight),$
    TYPE=typeOfInput)
  endelse
end
