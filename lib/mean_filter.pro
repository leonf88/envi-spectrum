; $Id: //depot/idl/releases/IDL_80/idldir/lib/mean_filter.pro#1 $
;
; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
FUNCTION _MF_NEIGHBOURS, d_x, d_y, neighbourhoodWidth, neighbourhoodHeight

  COMPILE_OPT IDL2, HIDDEN

  dimensions = [d_x, d_y]

  r_x = (neighbourhoodWidth-1)/2
  r_y = (neighbourhoodHeight-1)/2

  result = MAKE_ARRAY(d_x, d_y, VALUE=neighbourhoodWidth*neighbourhoodHeight)

  for x = 0, r_x-1 do begin
    result[x,*] -= (r_x-x)*neighbourhoodHeight
    result[d_x-1-x,*] -= (r_x-x)*neighbourhoodHeight
  endfor

  for y = 0, r_y-1 do begin
    result[*,y] -= (r_y-y)*neighbourhoodWidth
    result[*,d_y-1-y] -= (r_y-y)*neighbourhoodWidth
  endfor

  for x = 0, r_x-1 do begin
    for y = 0, r_y-1 do begin
      result[x,y] += (r_x-x)*(r_y-y)
      result[x,d_y-1-y] += (r_x-x)*(r_y-y)
      result[d_x-1-x,y] += (r_x-x)*(r_y-y)
      result[d_x-1-x,d_y-1-y] += (r_x-x)*(r_y-y)
    endfor
  endfor

  return, result
end

;-------------------------------------------------------------------------
FUNCTION _MF_ARITHMETIC_MEAN_FILTER, inputArray, neighbourhoodWidth, $
                                     neighbourhoodHeight, $
                                     _EXTRA=extra

  COMPILE_OPT IDL2, HIDDEN

  dimensions = SIZE(inputArray, /DIMENSIONS)

  d_x = dimensions[0]
  d_y = dimensions[1]  

  sampleSize = _MF_NEIGHBOURS(d_x, d_y, neighbourhoodWidth, neighbourhoodHeight)

  kernel = MAKE_ARRAY(neighbourhoodWidth, neighbourhoodHeight,VALUE=1)
  result = CONVOL(inputArray, kernel, /CENTER, /EDGE_ZERO, _EXTRA=extra) / $
    sampleSize

  return, result
end

;-------------------------------------------------------------------------
FUNCTION _MF_GEOMETRIC_MEAN_FILTER, inputArray, neighbourhoodWidth, neighbourhoodHeight, _EXTRA=extra

  COMPILE_OPT IDL2, HIDDEN 

  dimensions = SIZE(inputArray, /DIMENSIONS)

  d_x = dimensions[0]
  d_y = dimensions[1]

  sampleSize = _MF_NEIGHBOURS(d_x, d_y, neighbourhoodWidth, neighbourhoodHeight)

  kernel = MAKE_ARRAY(neighbourhoodWidth, neighbourhoodHeight,VALUE=1)

  logInput = (1D/sampleSize)*ALOG(inputArray)

  result = EXP(CONVOL(logInput, kernel, /CENTER, /EDGE_ZERO, /NAN, MISSING=0, _EXTRA=extra))

  ;result = EXP(CONVOL(ALOG(inputArray), kernel, /CENTER, /EDGE_ZERO, $
  ; _EXTRA=extra)) ^ (FLOAT(1)/sampleSize)
  void = CHECK_MATH(MASK=16)

  return, result
end

;+
; NAME:
;   MEAN_FILTER
;
; PURPOSE:
;   This function applies an arithmetic or geometric mean filter to
;   the input.
;
; CALLING SEQUENCE:
;   result = MEAN_FILTER(inputArray, width)
;
; PARAMETERS:
;   ImageData:
;     A two-dimensional or three-dimensional array containing the pixel values 
;     of the input image.
;
;   Width:
;     The width of the two-dimensional neighbourhood to be used
;     
;   Height:
;     The height of the two-dimensional neighbourhood to be used
;     
; KEYWORDS:
;   Arithmetic:
;     Set this keyword to calculate the arithmetic mean on each neighbourhood.
;     
;   Geometric:
;     Set this keyword to calculate the geometric mean on each neighbourhood.
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
FUNCTION MEAN_FILTER, inputArray, neighbourhoodWidth, neighbourhoodHeight, $
                      ARITHMETIC=arithmeticFlag, $
                      GEOMETRIC=geometricFlag, $
                      TRUE=true, $
                      _EXTRA=extra

  COMPILE_OPT IDL2

  ON_ERROR, 2

  numberOfDimensions = SIZE(inputArray, /N_DIMENSIONS)
  dimensions = SIZE(inputArray, /DIMENSIONS)
  typeOfInput = SIZE(inputArray, /TYPE)

  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Handle all the flags.
  ;;;;;;;;;;;;;;;;;;;;;;;;
  
  arithmeticFlag = KEYWORD_SET(arithmeticFlag)
  geometricFlag = KEYWORD_SET(geometricFlag)

  if N_ELEMENTS(true) eq 0 then true = 1 else true = 1 > FIX(true[0]) < 3

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Respond to flag input or make changes.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if N_ELEMENTS(neighbourhoodWidth) eq 0 then $
    MESSAGE, 'Width must be set.'
  
  if N_ELEMENTS(neighbourhoodHeight) eq 0 then $
    neighbourhoodHeight = neighbourhoodWidth

  if arithmeticFlag && geometricFlag then $
    MESSAGE, 'Set only one of ARITHMETIC or GEOMETRIC.'
  
  if ~(arithmeticFlag || geometricFlag) then $
    arithmeticFlag = 1

  if (neighbourhoodHeight mod 2 eq 0) || $
    (neighbourhoodWidth mod 2 eq 0) then $
    MESSAGE, 'Height and width must be odd.'

  if (neighbourhoodHeight lt 0) || (neighbourhoodWidth lt 0) then $
    MESSAGE, 'Height and width must be positive.'
  
  wDim = (numberOfDimensions mod 2) * (true eq 1)
  hDim = (numberOfDimensions mod 2) * (true ne 3) + 1
  if (neighbourhoodHeight gt dimensions[hDim]) || $
     (neighbourhoodWidth gt dimensions[wDim]) then $
    MESSAGE, 'Height and width must be less than the input size.'

  if (numberOfDimensions ne 2) && (numberOfDimensions ne 3) then $
    MESSAGE, 'Input must be a two or three dimensional array.'

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Perform any setup of data.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  case typeOfInput of
    1: calculationType = 2    ; byte --> int
    2: calculationType = 3    ; int --> long
    12: calculationType = 3   ; uint --> long
    13: calculationType = 14  ; ulong --> long64
    15: calculationType = 14  ; ulong64 --> long64
    else: calculationType = typeOfInput
  endcase

  fixedInput = FIX(inputArray, TYPE=calculationType)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Here, we do the actual work.
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if numberOfDimensions eq 2 then begin ; 2D one channel image.

    if arithmeticFlag then begin
      result = FIX(_MF_ARITHMETIC_MEAN_FILTER(fixedInput, $
                          neighbourhoodWidth, $
                          neighbourhoodHeight, $
                          _EXTRA=extra), $
            TYPE=typeOfInput)
      
      ;; Hide any divide by zero errors
      void = CHECK_MATH(MASK=16)
      
      return, result

    endif else if geometricFlag then begin
      result = FIX(_MF_GEOMETRIC_MEAN_FILTER(  fixedInput, $
                          neighbourhoodWidth, $
                          neighbourhoodHeight, $
                          _EXTRA=extra), $
            TYPE=typeOfInput)
      
      ;; Hide any divide by zero errors
      void = CHECK_MATH(MASK=16)
      
      return, result
    endif

  endif else if numberOfDimensions eq 3 then begin ; 3D TrueColor Image

    transposedInput = true eq 3 ? fixedInput : $
      TRANSPOSE(fixedInput, (true eq 1) ? [1,2,0] : [0,2,1])
    result = MAKE_ARRAY(SIZE(transposedInput, /DIMENSIONS), TYPE=typeOfInput)

    for channelIndex=0, dimensions[true-1]-1 do begin
      channel = REFORM(transposedInput[*,*,channelIndex])
      result[0,0,channelIndex] = MEAN_FILTER(  channel, $
                          neighbourhoodWidth, $
                          neighbourhoodHeight, $
                          ARITHMETIC=arithmeticFlag, $
                          GEOMETRIC=geometricFlag, $
                          TRUE=true, $
                          _EXTRA=extra)
    endfor

    return, true eq 3 ? result : $
      TRANSPOSE(result, (true eq 1) ? [2,0,1] : [0,2,1])
    
  endif
  
end