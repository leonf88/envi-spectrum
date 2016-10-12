; $Id: //depot/idl/releases/IDL_80/idldir/lib/cmyk_convert.pro#1 $
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   CMYK_CONVERT
;
; PURPOSE:
;   Convert from CMYK to RGB and vice versa.
;
;   The CMYK_CONVERT procedure uses the following method to convert
;   from CMYK to RGB:
;       R = (255 - C) (1 - K/255)
;       G = (255 - M) (1 - K/255)
;       B = (255 - Y) (1 - K/255)
;   To convert from RGB to CMYK the following method is used:
;       K = minimum of (R, G, B)
;       C = 255 [1 - R/(255 - K)]   (if K=255 then C=0)
;       M = 255 [1 - G/(255 - K)]  (if K=255 then M=0)
;       Y = 255 [1 - B/(255 - K)]  (if K=255 then Y=0)
;   In both cases the CMYK and RGB values are assumed to be in
;   the range 0 to 255.
;
;   Note: There is no single method that is used for CMYK/RGB conversion.
;       The method used by CMYK_CONVERT is the simplest, and, depending
;       upon printing inks and screen colors, may not be optimal in
;       all situations.
;
; CALLING SEQUENCE:
;   CMYK_CONVERT, C, M, Y, K, R, G, B [, /TO_CMYK]
;
; INPUTS:
;   C,M,Y,K: To convert from CMYK to RGB, set these arguments to scalars
;       or arrays containing the CMYK values in the range 0-255.
;       To convert from RGB to CMYK (with /TO_CMYK set) set these arguments
;       to named variables which will contain the converted values.
;
;   R,G,B: To convert from CMYK to RGB, set these arguments to named
;       variables which will contain the converted values.
;       To convert from RGB to CMYK (with /TO_CMYK set) set these
;       arguments to scalars or arrays containing the RGB values.
;
; KEYWORD PARAMETERS:
;   TO_CMYK: If this keyword is set, then the values contained within
;       the RGB arguments will be converted to CMYK.
;       The default is to convert from CMYK to RGB.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, August 2004
;   Modified:
;
;-

;-------------------------------------------------------------------------
pro cmyk_convert, c, m, y, k, r, g, b, TO_CMYK=to_cmyk

    compile_opt hidden, idl2

    ON_ERROR, 2

    if (N_PARAMS() ne 7) then $
        MESSAGE, 'Incorrect number of arguments.'

    if (KEYWORD_SET(to_cmyk)) then begin
        bright = BYTE(R > G > B)
        K = 255b - bright  ; blackest
        zero = bright eq 0
        ; Avoid divide by zero.
        bright += zero
        ; Multiply by ~zero to force black (K=255) values to C=M=Y=255.
        fraction = (255.0/TEMPORARY(bright))*(~TEMPORARY(zero))
        C = 255b - BYTE(R*fraction)
        M = 255b - BYTE(G*fraction)
        Y = 255b - BYTE(B*fraction)
        return
    endif

    kinv = 1 - K/255.0
    R = BYTE((255b - C)*kinv)
    G = BYTE((255b - M)*kinv)
    B = BYTE((255b - Y)*kinv)

end

