; $Id: //depot/idl/releases/IDL_80/idldir/lib/hanning.pro#1 $
;
; Copyright (c) 1987-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;+
; NAME:
;   HANNING
;
; PURPOSE:
;   Window function for Fourier Transform filtering.  May be used
;       for both the Hanning and Hamming windows.
;
; CATEGORY:
;   Signal, image processing.
;
; CALLING SEQUENCE:
;   Result = HANNING(N1) ;For 1 dimension.
;
;   Result = HANNING(N1, N2) ;For 2 dimensions.
;
; INPUTS:
;   N1: The number of columns of the result.
;
;   N2: The number of rows of the result.
;
; Keyword Parameters:
;   ALPHA = width parameter of generalized Hamming window.  Alpha
;       must be in the range of 0.5 to 1.0.  If Alpha = 0.5,
;       the default, the function is called the "Hanning" window.
;       If Alpha = 0.54, the result is called the "Hamming" window.
;
;   DOUBLE = Set this keyword to force the computations to be done
;            in double-precision arithmetic.
;
; OUTPUTS:
;   Result(i) = 1/2 [1 - COS(2 PI i / N]
;
;   For two dimensions, the result is the same except that "i" is replaced
;   with "i*j", where i and j are the row and column subscripts.
;
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   None.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;   Straightforward.
;
; MODIFICATION HISTORY:
;   DMS, May, 1987.
;   DMS, Jan, 1994. Added generalized width parameter.
;   CT, RSI, May 2000: Added double-precision support.
;   CT, RSI, August 2001: Changed formula to divide by N rather than N-1.
;               This now agrees with Numerical Recipes in C, 2nd ed.
;-

function Hanning, n1In, n2In, $
    Alpha=alpha, $
    DOUBLE=double

    compile_opt IDL2

    on_error,2                              ;Return to caller if an error occurs
    tnames = [SIZE(n1In,/TNAME), SIZE(n2In,/TNAME), SIZE(alpha,/TNAME)]
    double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : $
        MAX(tnames EQ 'DOUBLE')
    if N_elements(alpha) le 0 then alpha = double ? 0.5d : 0.5
    pi = double ? !DPI : !PI
    one = double ? 1d : 1.0
    n1 = double ? DOUBLE(n1In[0]) : FLOAT(n1In[0])
    a = 2 * pi / N1           ;scale factor
    if n_params() lt 2 then n2In = 1  ;1D filter?
    n2 = double ? DOUBLE(n2In[0]) : FLOAT(n2In[0])

    index = double ? DINDGEN(n1) : FINDGEN(n1)
    If n2 eq 1 then begin       ;1d?
        return, (alpha-one) * cos(index*a) + alpha
    endif else begin                ;2d case
        b = 2 * pi / n2        ;dim 2 scale fact
        row = (alpha-one) * cos(index*a) + alpha ;One row
        index = double ? DINDGEN(n2) : FINDGEN(n2)
        col = (alpha-one) * cos(index*b) + alpha ;One column
        RETURN,(row # col)
    endelse
end
