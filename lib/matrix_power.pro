; $Id: //depot/idl/releases/IDL_80/idldir/lib/matrix_power.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   MATRIX_POWER
;
; PURPOSE:
;   This function computes the product of a matrix with itself.
;   For example, the fifth power of array A is A # A # A # A # A.
;   Negative powers are computed using the matrix inverse
;   of the positive power. A power of zero returns the identity matrix.
;
;
; CALLING SEQUENCE:
;   Result = MATRIX_POWER(Array, N)
;
;
; RETURN VALUE:
;   The result is the matrix power.
;
;
; INPUTS:
;   Array: A two-dimensional square array.
;          Array may be of any numeric type.
;
;   N: An integer giving the power.
;
;
; KEYWORD PARAMETERS:
;
;   DOUBLE = Set this keyword to 1 return a double-precision result,
;       or to 0 to return a single-precision result.
;       The default return type depends upon the precision of Array.
;       Computations are always performed using double precision.
;
;   STATUS = Set this keyword to a named variable in which to return
;       the status of the matrix inverse for negative powers.
;       Possible values are:
;         0 = Successful completion.
;         1 = Singular array (which indicates that the inversion is invalid).
;         2 = Warning that a small pivot element was used and that
;             significant accuracy was probably lost.
;       For nonnegative powers STATUS is always set to 0.
;
;
; EXAMPLE:
;
;    Print an array to the one millionth power:
;           Array = [ [0.401d, 0.600d], $
;                     [0.525d, 0.475d] ]
;           print, MATRIX_POWER(Array, 1e6)
;
;    IDL prints:
;           2.4487434e+202  2.7960773e+202
;           2.4465677e+202  2.7935929e+202
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, July 2002
;   Modified:
;
;-

function matrix_power, array, powerIn, DOUBLE=doubleIn, STATUS=status

    compile_opt idl2

    ON_ERROR, 2


    ; Error checking.
    if (N_PARAMS() ne 2) then $
        MESSAGE, 'Incorrect number of arguments.'

    dim = SIZE(array, /DIMENSIONS)
    if ((N_ELEMENTS(dim) ne 2) ? 1 : (dim[0] ne dim[1])) then $
        MESSAGE, 'Array must be a two-dimensional matrix.'

    power = LONG(powerIn)
    if (power ne powerIn) then $
        MESSAGE, 'Power must be an integer.'


    ; Check input types.
    type = SIZE(array, /TYPE)
    isCplx = (type eq 6) or (type eq 9)
    double = (N_ELEMENTS(doubleIn) gt 0) ? KEYWORD_SET(doubleIn) : $
        ((type eq 5) or (type eq 9))


    ; Negative power is just the matrix inverse of the power.
    if (power lt 0) then begin
        result = INVERT(MATRIX_POWER(array, ABS(power), /DOUBLE), status)
        ;--------------------- return
        return, double ? result : $
            (isCplx ? COMPLEX(result) : FLOAT(result))

    endif


    ; Make a double-precision copy.
    apower = isCplx ? DCOMPLEX(array) : DOUBLE(array)

    result = IDENTITY(dim[0], /DOUBLE)

    status = 0  ; success

    ; Return identity matrix.
    if (power eq 0) then begin
        ;--------------------- return
        return, double ? result : $
            (isCplx ? COMPLEX(result) : FLOAT(result))
    endif


    ; Right-to-left binary method for exponentiation. Very fast.
    ; Algorithm from Knuth, 1998, The Art of Computer Programming,
    ;    Vol 2, 3rd ed., sec 4.6.3.
restart:

    if (power mod 2) then begin
        ; If odd power, then multiply by the squares.
        result = result # apower
        ; Is the algorithm complete?
        if (power le 1) then begin
            ;--------------------- return
            return, double ? result : $
                (isCplx ? COMPLEX(result) : FLOAT(result))
        endif
    endif

    ; Next iteration.
    power = power/2

    ; Square the array.
    apower = apower # apower

    goto, restart

end


