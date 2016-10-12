;$Id: //depot/idl/releases/IDL_80/idldir/lib/real_part.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   REAL_PART
;
; PURPOSE:
;   This function returns the real part of a complex number, in the same
;   precision (either single or double) as the input variable.
;
; CALLING SEQUENCE:
;   Result = REAL_PART(Z)
;
; INPUTS:
;   Z:  A scalar or array. Z may be of any numeric type.
;       If Z is not complex then the result is simply converted to
;       floating-point (single-precision for all integer types,
;   double precision for type double).
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, May 2001.
;-

function real_part, z

    ON_ERROR, 2
    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'
    type = SIZE(z, /TYPE)
    ;   is it type DOUBLE or DCOMPLEX?
    isDouble = (type eq 5L) or (type eq 9L)
    return, isDouble ? DOUBLE(z) : FLOAT(z)
end
