;$Id: //depot/idl/releases/IDL_80/idldir/lib/eigenvec.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       EIGENVEC
;
; PURPOSE:
;       This function computes the eigenvectors of an N by N real, non-
;       symmetric array using inverse subspace iteration. The result is 
;       a complex array with a column dimension equal to N and a row 
;       dimension equal to the number of eigenvalues.
;
; CATEGORY:
;       Linear Algebra / Eigensystems
;
; CALLING SEQUENCE:
;       Result = Eigenvec(A, Eval)
;
; INPUTS:
;       A:    An N by N nonsymmetric array of type float or double.
;
;    EVAL:    An N-element complex vector of eigenvalues.
;
; KEYWORD PARAMETERS:
;       DOUBLE:  If set to a non-zero value, computations are done in
;                double precision arithmetic.
;
;        ITMAX:  The number of iterations performed in the computation
;                of each eigenvector. The default value is 4.
;
;     RESIDUAL:  Use this keyword to specify a named variable which returns
;                the residuals for each eigenvalue/eigenvector(lambda/x) pair.
;                The residual is based on the definition Ax - (lambda)x = 0
;                and is an array of the same size and type as RESULT. The rows
;                this array correspond to the residuals for each eigenvalue/
;                eigenvector pair. 
;
; EXAMPLE:
;       Define an N by N real, nonsymmetric array.
;         a = [[1.0, -2.0, -4.0,  1.0], $
;              [0.0, -2.0,  3.0,  4.0], $
;              [2.0, -6.0, -1.0,  4.0], $
;              [3.0, -3.0,  1.0, -2.0]]
;
;       Compute the eigenvalues of A using double-precision complex arithmetic.
;         eval = HQR(ELMHES(a), /double)
;
;       Print the eigenvalues. The correct solution should be:
;       (0.26366259, -6.1925899), (0.26366259, 6.1925899), $
;       (-4.9384492,  0.0000000), (0.41112397, 0.0000000)
;         print, eval
;
;       Compute the eigenvectors of A. The eigenvectors are returned in the 
;       rows of EVEC.
;         result = EIGENVEC(a, eval, residual = residual)
;
;       Print the eigenvectors.
;         print, evec(*,0), evec(*,1), evec(*,2), evec(*,3)
;
;       The accuracy of each eigenvalue/eigenvector (lamda/x) 
;       pair may be checked by printing the residual array. This array is the
;       same size and type as RESULT and returns the residuals as its rows.
;       The residual is based on the mathematical definition of an eigenvector,
;       Ax - (lambda)x = 0.
;
; PROCEDURE:
;       EIGENVEC computes the set of eigenvectors that correspond to a given 
;       set of eigenvalues using Inverse Subspace Iteration. The eigenvectors 
;       are computed up to a scale factor and are of Euclidean length. The
;       existence and uniqueness of eigenvectors are not guaranteed.
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, December 1994
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision. 
;-

FUNCTION EigenVec, A, Eval, Double = Double, ItMax = ItMax, $
                                             Residual = Residual

  ON_ERROR, 2  ;Return to caller if error occurs.

  if N_PARAMS() ne 2 then $
    MESSAGE, "Incorrect number of input arguments."
    
  TypeA = SIZE(A)
  TypeEval = SIZE(Eval)

  if TypeA[1] ne TypeA[2] then $
    MESSAGE, "Input array must be square."

  if TypeA[3] ne 4 and TypeA[3] ne 5 then $
    MESSAGE, "Input array must be float or double."

  if TypeEval[TypeEval[0]+1] ne 6 and TypeEval[TypeEval[0]+1] ne 9 then $
    MESSAGE, "Eigenvalues must be complex or double-complex."

  Enum = TypeEval[TypeEval[0]+2] ;Number of eigenvalues.
  if TypeA[2] ne Enum then $
    MESSAGE, "Input array and eigenvalues are of incompatible size."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are determined by the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeA[TypeA[0]+1] eq 5 or TypeEval[TypeEval[0]+1] eq 9)

  if N_ELEMENTS(ItMax) eq 0 then ItMax = 4

  Diag = LINDGEN(TypeA[1]) * (TypeA[1]+1) ;Diagonal indices.

  ;Double Precision.
  if Double ne 0 then begin
    Evec = DCOMPLEXARR(TypeA[1], Enum) ;Eigenvector storage array with number
                                    ;of rows equal to number of eigenvalues.
    for k = 0, Enum - 1 do begin
      Alud = A  ;Create a copy of the array for next eigenvalue computation.
      if IMAGINARY(Eval[k]) ne 0 then begin ;Complex eigenvalue.
        Alud = DCOMPLEX(Alud)
        Alud[Diag] = Alud[Diag] - Eval[k]
        ;Avoid intermediate variables. re = DOUBLE(Alud) im = IMAGINARY(Alud)
        Comp = [[DOUBLE(Alud), -IMAGINARY(Alud)], $
                [IMAGINARY(Alud), DOUBLE(Alud)]]
        ;Initial eigenvector.
        B = REPLICATE(1.0d, 2*TypeA[1]) / SQRT(2.0d * TypeA[1])
        LUDC, Comp, Index, DOUBLE = DOUBLE
        it = 0
        while it lt ItMax do begin ;Iteratively compute the eigenvector.
          X = LUSOL(Comp, Index, B, DOUBLE = DOUBLE)
          B = X / SQRT(TOTAL(X^2, 1, DOUBLE = DOUBLE)) ;Normalize eigenvector.
          it = it + 1
        endwhile
        ;Row vector storage.
        Evec[*, k] = DCOMPLEX(B[0:TypeA[1]-1], B[TypeA[1]:*])
      endif else begin ;Real eigenvalue
        Alud[Diag] = Alud[Diag] - DOUBLE(Eval[k])
        B = REPLICATE(1.0d, TypeA[1]) / SQRT(TypeA[1]+0.0d)
        LUDC, Alud, Index, DOUBLE = DOUBLE
        it = 0
        while it lt ItMax do begin
          X = LUSOL(Alud, Index, B, DOUBLE = DOUBLE)
          B = X / SQRT(TOTAL(X^2, 1, DOUBLE = DOUBLE)) ;Normalize eigenvector.
          it = it + 1
        endwhile
        Evec[*, k] = DCOMPLEX(B, 0.0d0) ;Row vector storage.
      endelse
    endfor
    if ARG_PRESENT(Residual) then begin ;Compute eigenvalue/vector residuals.
      Residual = DCOMPLEXARR(TypeA[1], Enum) ;Dimensioned the same as Evec.
        for k = 0, Enum - 1 do $
          Residual[*,k] = (A##Evec[*,k]) - (Eval[k] * Evec[*,k])
    endif
  endif else begin ;Single Precision.
    Evec = COMPLEXARR(TypeA[1], Enum) ;Eigenvector storage array.
    for k = 0, Enum - 1 do begin
      Alud = A  ;Create a copy of the array for next eigenvalue computation.
      if IMAGINARY(Eval[k]) ne 0 then begin ;Complex eigenvalue.
        Alud = COMPLEX(Alud)
        Alud[Diag] = Alud[Diag] - Eval[k]
        ;Avoid intermediate variables. re = FLOAT(Alud) im = IMAGINARY(Alud)
        Comp = [[FLOAT(Alud), -IMAGINARY(Alud)], $
                [IMAGINARY(Alud), FLOAT(Alud)]]
        ;Initial eigenvector.
        B = REPLICATE(1.0, 2*TypeA[1]) / SQRT(2.0 * TypeA[1])
        LUDC, Comp, Index, DOUBLE = DOUBLE
        it = 0
        while it lt ItMax do begin ;Iteratively compute the eigenvector. 
          X = LUSOL(Comp, Index, B, DOUBLE = DOUBLE)
          B = X / SQRT(TOTAL(X^2, 1)) ;Normalize eigenvector.
          it = it + 1
        endwhile
        ;Row vector storage.
        Evec[*, k] = COMPLEX(B[0:TypeA[1]-1], B[TypeA[1]:*])
      endif else begin ;Real eigenvalue 
        Alud[Diag] = Alud[Diag] - FLOAT(Eval[k])
        B = REPLICATE(1.0, TypeA[1]) / SQRT(TypeA[1])
        LUDC, Alud, Index, DOUBLE = DOUBLE
        it = 0
        while it lt ItMax do begin
          X = LUSOL(Alud, Index, B, DOUBLE = DOUBLE)
          B = X / SQRT(TOTAL(X^2, 1))  ;Normalize eigenvector.
          it = it + 1
        endwhile
        Evec[*, k] = COMPLEX(B, 0.0) ;Row vector storage.
      endelse
    endfor
    if ARG_PRESENT(Residual) then begin ;Compute eigenvalue/vector residuals.
      Residual = COMPLEXARR(TypeA[1], Enum) ;Dimensioned the same as Evec.
        for k = 0, Enum - 1 do $
          Residual[*,k] = (A##Evec[*,k]) - (Eval[k] * Evec[*,k])
    endif
  endelse
  
  if Double eq 0 then RETURN, COMPLEX(Evec) else RETURN, Evec

END
