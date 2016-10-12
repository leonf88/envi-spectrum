; $Id: //depot/idl/releases/IDL_80/idldir/lib/la_linear_equation.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   LA_LINEAR_EQUATION
;
; PURPOSE:
;   This function uses LU decomposition to solve a system of
;   linear equations, Ax = B, and provides optional error bounds and backward
;   error estimate.
;
;   The LA_LINEAR_EQUATION function may also be used to solve for
;   multiple systems of linear equations, with each column of B representing a
;   different set of equations. In this case, the result is a k-by-n array
;   where each of the k columns represents the improved
;   solution vector for that set of equations
;
; CALLING SEQUENCE:
;
;   Result = LA_LINEAR_EQUATION(Array, B)
;
; INPUTS:
;   Array: An n-by-n array.
;
;   B: An n-element vector, or a k-by-n array.
;
; KEYWORD PARAMETERS:
;   BACKWARD_ERROR: On output, will contain the estimated backward error
;     bound for each linear system.
;
;   DOUBLE: Set this keyword to force the computation to be done in
;     double-precision arithmetic.
;
;   FORWARD_ERROR: On output, will contain the estimated forward error
;     bound for each linear system.
;
;   STATUS: Set this keyword to return the status of the LU decomposition.
;     Otherwise, error messages are output to the screen.
;     Possible values are:
;          STATUS = 0: The computation was successful.
;          STATUS > 0: One of the diagonal elements of U was zero.
;                      The STATUS value specifies which diagonal was zero.
;          If STATUS > 0 then the Result will be a scalar zero.
;
; OUTPUT:
;   The result is an n-element vector (or a k-by-n array)
;   whose type is identical to A.
;
; PROCEDURE:
;   Uses LA_LUDC, LA_LUSOL, LA_LUMPROVE.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by: CT, RSI, October 2001.
;
;-

FUNCTION la_linear_equation, Array, Brhs, $
    _REF_EXTRA=_extra, $
    STATUS=status

    COMPILE_OPT idl2

    ON_ERROR, 2  ; return to caller

    ; Catch error messages so we can print our own routine name.
    CATCH, errorStatus
    if (errorStatus ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, !ERROR_STATE.msg
    endif

    if (N_PARAMS() ne 2) then $
        MESSAGE, 'Incorrect number of arguments.'

    ; Make a copy so we don't destroy user's data.
    Aludc = Array

    ; LU decomposition.
    if ARG_PRESENT(status) then begin  ; Return STATUS flag
        LA_LUDC, Aludc, Index, STATUS=status, _EXTRA=_extra
        ; No point in going further if the LU failed.
        if (status ne 0) then $
            return, 0
    endif else begin  ; Throw error messages.
        LA_LUDC, Aludc, Index, _EXTRA=_extra
    endelse

    ; Solve the equation.
    result = LA_LUSOL(Aludc, Index, Brhs, _EXTRA=_extra)

    ; Improve the solution and find optional error estimates.
    mproveResult = LA_LUMPROVE(Array, Aludc, Index, Brhs, TEMPORARY(result), $
        _EXTRA=_extra)

    return, mproveResult

end
