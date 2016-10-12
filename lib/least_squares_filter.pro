; $Id: //depot/idl/releases/IDL_80/idldir/lib/least_squares_filter.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   LEAST_SQUARES_FILTER
;
; PURPOSE:
;   This function applies the constrained least squares filter to the
;   supplied one-channel image.
;
; CALLING SEQUENCE:
;   result = LEAST_SQUARES_FILTER(ImageData, DegradationFunction, Gamma)
;
; PARAMETERS:
;   ImageData:
;     A two-dimensional array containing the pixel values of a one channel
;     image.
;
;   DegradationFunction:
;     A two-dimensional array representing the degradation function of
;     the image in the frequency domain.
;
;   Gamma:
;     Parameter such that the constrained least squares criterion is
;     satisfied.
;
; KEYWORDS:
;   None.
;
; RETURN VALUE:
;   An array of the same dimensions and type as ImageData containing the 
;   filtered image.
;
; MODIFICATION HISTORY:
;   Created by:  Turing Eret, December 2008
;-
FUNCTION LEAST_SQUARES_FILTER, inputArray, degradationFunction, gamma
  COMPILE_OPT IDL2

  ON_ERROR, 2

  numberOfDimensions = SIZE(inputArray, /N_DIMENSIONS)
  dimensions = SIZE(inputArray, /DIMENSIONS)
  typeOfInput = SIZE(inputArray, /TYPE)

  ;;;;;;;;;;;;;;;;;;
  ;; Error handling.
  ;;;;;;;;;;;;;;;;;;
  if(N_ELEMENTS(inputArray) eq 0) then $
  MESSAGE, 'Input must be supplied.'
  if(N_ELEMENTS(degradationFunction) eq 0) then $
  MESSAGE, 'Degradation function must be supplied.'
  if(N_ELEMENTS(gamma) eq 0) then $
  MESSAGE, 'Gamma must be supplied.'

  if (numberOfDimensions ne 2) then $
  MESSAGE, 'Input must be a two dimensional array.'

  if(N_ELEMENTS(inputArray) ne N_ELEMENTS(degradationFunction)) then $
  MESSAGE, 'Degradation function must be same size as input.'

  if(gamma lt 0) then $
  MESSAGE, 'Gamma must be zero or a positive value.'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Here, we do the actual work.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ffTransform = FFT(inputArray, /CENTER)

  degradationConjugate = CONJ(degradationFunction)

  laplacianKernel = [[0,-1,0],[-1,4,-1],[0,-1,0]]
  laplacianFFT = FFT(CONVOL(inputArray,laplacianKernel,/EDGE_ZERO), /CENTER)

  result = $
  ( $
  ( degradationConjugate ) / $
  ( $
  degradationFunction * degradationConjugate + $
  gamma * laplacianFFT $
  ) $
  ) * $
  ffTransform

  ;; Hide any divide by zero errors
  void = CHECK_MATH(MASK=16)

  return, REAL_PART(FFT(result, /INVERSE, /CENTER))

end