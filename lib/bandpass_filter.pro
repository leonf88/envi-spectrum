; $Id: //depot/idl/releases/IDL_80/idldir/lib/bandpass_filter.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   BANDPASS_FILTER
;
; PURPOSE:
;   The BANDPASS_FILTER function performs a bandpass filtering on a 
;   one-channel image 
;
; CALLING SEQUENCE:
;   result = BANDPASS_FILTER(imageData, lowFreq, highFreq)
;
; PARAMETERS:
;   ImageData:
;     A two-dimensional array containing the pixel values of the input image.
;
;   lowFreq:
;     The lower bound of the frequency band to pass through.
;     
;   highFreq:
;     The upper bound of the frequency band to pass through.
;     
; KEYWORDS:
;   Butterworth:
;     Set this keyword to the dimension of the Butterworth filter to apply to 
;     the frequency domain.
;
;   Gaussian:
;     Set this keyword to use a Gaussian bandpass filter.
;     
;   Ideal:
;     Set this keyword to use an ideal bandpass filter.
;     
; RETURN VALUE:
;   An array of the same dimensions and type as ImageData containing the 
;   filtered image.
;
; MODIFICATION HISTORY:
;   Created by:  Turing Eret, December 2008
;-
FUNCTION BANDPASS_FILTER, inputArray, lowFreq, highFreq, $
  IDEAL=idealFlag, $
  BUTTERWORTH=butterworthDimension, $
  GAUSSIAN=gaussianFlag

  COMPILE_OPT IDL2

  ON_ERROR, 2

  numberOfDimensions = SIZE(inputArray, /N_DIMENSIONS)
  dimensions = SIZE(inputArray, /DIMENSIONS)

  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Handle all the flags.
  ;;;;;;;;;;;;;;;;;;;;;;;;
  idealFlag = KEYWORD_SET(idealFlag)
  gaussianFlag = KEYWORD_SET(gaussianFlag)
  if N_ELEMENTS(butterworthDimension) eq 0 then butterworthFlag = 0 $
  else butterworthFlag = 1

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Respond to flag input or make changes.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if (numberOfDimensions ne 2) then $
  MESSAGE, 'Input must be a two dimensional array.'

  if TOTAL([idealFlag, butterworthFlag, gaussianFlag] ne 0) gt 1 then $
  MESSAGE, 'Only set one of IDEAL, BUTTERWORTH, or GAUSSIAN.'

  if TOTAL([idealFlag, butterworthFlag, gaussianFlag] ne 0) eq 0 then begin
    butterworthFlag = 1
    butterworthDimension = 1
  endif

  if N_ELEMENTS(lowFreq) eq 0 then $
  MESSAGE, 'Flow and Fhigh must be supplied.'
  if N_ELEMENTS(highFreq) eq 0 then $
  MESSAGE, 'Fhigh must be supplied.'
  if lowFreq gt 1 || lowFreq lt 0 then $
  MESSAGE, 'Flow is out of range ([0,1]).'
  if highFreq gt 1 || highFreq lt 0 then $
  MESSAGE, 'Fhigh is out of range ([0,1]).'
  if highFreq lt lowFreq then $
  MESSAGE, 'Fhigh must be greater than Flow.'

  if butterworthFlag ne 0 && butterworthDimension le 0 then $
  MESSAGE, 'Butterworth dimension must be a positive value.'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Here, we do the actual work.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  fourierTransform = FFT(inputArray, /CENTER)

  D = DOUBLE(SHIFT(DIST(dimensions[0], dimensions[1]), dimensions[0]/2+1, dimensions[1]/2+1))
  
  D /= MAX(D)

  W = DOUBLE(highFreq - lowFreq)
  D0 = DOUBLE(highFreq+lowFreq)/2.0d

  if idealFlag eq 1 then begin
    H = MAKE_ARRAY(dimensions, VALUE=1)	
    H[WHERE(lowFreq gt D or highFreq lt D)] = 0
  endif else if butterworthFlag ne 0 then begin
    if lowFreq ne 0 && highFreq ne 1 then begin
      H = 1.0d - (1.0 / (1 + ( (D*W) / (D^2-D0^2) ) ^ (2*butterworthDimension)))
    endif else if lowFreq eq 0 then begin
      H = 1.0d / (1 + ( D / highFreq ) ^ (2*butterworthDimension))
    endif else begin
      H = 1.0d / (1 + ( lowFreq / D ) ^ (2*butterworthDimension))
    endelse
  endif else begin
    if lowFreq ne 0 && highFreq ne 1 then begin
      H = exp(-(( (D^2 - D0^2) / (D*W) )^2))
    endif else if lowFreq eq 0 then begin
      H = exp(-( D^2 / (2*highFreq^2) ) )
    endif else begin
      H = 1.0d - exp(-( D^2 / (2*lowFreq^2) ) )
    endelse
  endelse
  ;; Hide any divide by zero errors
  void = CHECK_MATH(MASK=16)

  resultFourier = H * fourierTransform

  return, REAL_PART(FFT(resultFourier, /INVERSE, /CENTER))

end