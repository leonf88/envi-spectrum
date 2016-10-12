; $Id: //depot/idl/releases/IDL_80/idldir/lib/wiener_filter.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   WIENER_FILTER
;
; PURPOSE:
;   This function applies the Wiener filter to the supplied one-channel image.
;
; CALLING SEQUENCE:
;   result = WIENER_FILTER(ImageData, DegradationFunction, CleanPowerSpectrum,
;   NoisePowerSpectrum)
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
;   CleanPowerSpectrum:
;     The power spectrum of the clean image.
;
;   NoisePowerSpectrum:
;     The power spectrum of the noise.
;
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
FUNCTION WIENER_FILTER, inputArray, $
  degradationFunction, $
  cleanPowerSpectrum, $
  noisePowerSpectrum

  COMPILE_OPT IDL2

  ON_ERROR, 2

  numberOfDimensions = SIZE(inputArray, /N_DIMENSIONS)
  dimensions = SIZE(inputArray, /DIMENSIONS)
  typeOfInput = SIZE(inputArray, /TYPE)

  ;;;;;;;;;;;;;;;;;;
  ;; Error handling.
  ;;;;;;;;;;;;;;;;;;
  if numberOfDimensions ne 2 then $
  MESSAGE, 'Input must be a two dimensional array.'

  if N_ELEMENTS(inputArray) ne N_ELEMENTS(degradationFunction)  then $
  MESSAGE, 'Degradation function must be same size as input.'

  if	N_ELEMENTS(inputArray) ne N_ELEMENTS(cleanPowerSpectrum) && $
  N_ELEMENTS(cleanPowerSpectrum) ne 1 then $
  MESSAGE, 'Ideal power spectrum must be the same size as input or a scalar.'

  if	N_ELEMENTS(inputArray) ne N_ELEMENTS(noisePowerSpectrum) && $
  N_ELEMENTS(noisePowerSpectrum) ne 1 then $
  MESSAGE, 'Noise power spectrum must be the same size as input or a scalar.'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Here, we do the actual work.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ffTransform = FFT(inputArray, /CENTER)

  degradationConjugate = CONJ(degradationFunction)

  result = $
  degradationConjugate / $
  ( $
  degradationFunction*degradationConjugate + $
  noisePowerSpectrum/cleanPowerSpectrum $
  ) * $
  ffTransform

  result = REAL_PART(FFT(result, /INVERSE, /CENTER))

  ;; Hide any divide by zero errors
  void = CHECK_MATH(MASK=16)

  return, result
end