;$Id: //depot/idl/releases/IDL_80/idldir/lib/complexround.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       COMPLEXROUND
;
; PURPOSE:
;       This function rounds a complex scalar or array.
;
; CATEGORY:
;       Numerical Analysis.
;
; CALLING SEQUENCE:
;       Result = Complexround(z)
;
; INPUTS:
;       Z: A complex scalar or array.
;
; RESTRICTIONS:
;       The input argument must be complex.
;
; PROCEDURE:
;       This function rounds the real and imaginary components of the
;       complex input argument. If Z is double-precision complex then
;       the result is also double-precision complex.
;
; EXAMPLE:
;       ;Define a complex array.
; 	  z = [[complex(1.245, 3.880), complex( 1.245, -3.880)], $
;              [complex(1.499, 5.501), complex(-1.355, -2.115)]]
;       ;Round it.
;         result = complexround(z)
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, September 1992
;       Modified:    GGS, RSI, September 1994
;                    Added support for double-precision complex inputs.
;                    Uses IDL's intrinsic ROUND function.
;                    CT, RSI, March 2000: Fixed double-precision.
;-

function complexround, z

  ;dimension = size(input)  ;Size of input array.
  ;output = complexarr(dimension(1), dimension(2))
  ;real = float(input) ;Separate into real and imaginary.
  ;imag = imaginary(input)

  ;z1 = real + 0.5 ;Round real components.
  ;neg1 = where(real lt 0, count1)
  ;if count1 ne 0 then z1(neg1) = z1(neg1) - 1
  ;z1 = fix(z1)

  ;z2 = imag + 0.5 ;Round imaginary components.
  ;neg2 = where(imag lt 0, count2)
  ;if count2 ne 0 then z2(neg2) = z2(neg2) - 1
  ;z2 = fix(z2)

  ;output = complex(z1,z2)
  ;return, complex(z1,z2)

  on_error, 2

  tname = SIZE(z, /TNAME)

  if tname eq 'COMPLEX' then begin
    return, complex(round(float(z)), round(imaginary(z)))
  endif else if tname eq 'DCOMPLEX' then $
    return, dcomplex(round(double(z)), round(imaginary(z))) $
  else message, 'Input must be of complex type.'

end
