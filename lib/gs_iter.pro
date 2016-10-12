;$Id: //depot/idl/releases/IDL_80/idldir/lib/gs_iter.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       GS_ITER
;
; PURPOSE:
;       This function solves an n by n linear system of equations
;       using Gauss-Seidel iteration.
;
; CATEGORY:
;       Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = GS_ITER(A, B)
;
; INPUTS:
;       A:      An N by N array of type: int, float, or double.
;
;       B:      An N-element vector of type: int, float, or double.
;
; KEYWORD PARAMETERS:
;       CHECK:    An integer value of 0 or 1 that denies or requests
;                 checking A for a diagonally dominant form.
;                 CHECK = 0 (the default) results in no checking.
;                 CHECK = 1  Checks A and reports if it does not
;                            meet the required condition. This is
;                            just a warning. The algorithm will
;                            proceed on the chance it may converge.
;
;       DOUBLE:   Set this keyword to force the computation to be done
;                 in double-precision arithmetic.
;
;       LAMBDA:   A scalar value in the range: [0.0, 2.0]
;                 This value determines the amount of 'RELAXATION'.
;                 Relaxation is a weighting technique that is used
;                 to enhance convergence.
;                 1) LAMBDA = 1.0 (the default) no weighting.
;                 2) A value in the range  0.0 <= LAMBDA < 1.0  improves
;                    convergence in oscillatory and non-convergent systems.
;                 3) A value in the range  1.0 < LAMBDA <= 2.0  improves
;                    convergence in systems known to converge.
;
;       MAX_ITER: The maximum number of iterations allowable for the
;                 algorithm to converge to the solution. The default
;                 is 30 iterations.
;
;       X_0:      An N-element vector that provides the algorithm's
;                 starting point. The default is [1.0, 1.0, ... , 1.0].
;
;       TOL:      The relative error tolerance between current and past
;                 iterates calculated as:  ABS( (current-past)/current )
;                 The default is 1.0e-4.
;
; SIDE EFFECTS:
;       Upon output A and B are divided by the diagonal elements of A.
;       Integer inputs are converted to floats.
;       Note: These SIDE EFFECTS have been removed for IDL v5.0.
;
; RESTRICTIONS:
;       The equations must be entered in a DIAGONALLY DOMINANT form
;       to guarantee convergence.
;       A system is diagonally dominant if it satisfies the condition:
;                   abs(A(row,row)) > SUM(abs(A(row,col)))
;       where SUM runs col=1,N excluding col = row and A is in row major.
;       This restriction on A is known as a sufficient condition. That is,
;       it is sometimes possible for the algorithm to converge without the
;       condition being satisfied. But, convergence is guaranteed if the
;       condition is satisfied.
;
; EXAMPLE:
;       Define an array (a) in a non-diagonally dominant form.
;         a = [[ 1.0,  7.0, -4.0], $
;              [ 4.0, -4.0,  9.0], $
;              [12.0, -1.0,  3.0]]
;       And right-side vector (b).
;         b = [12.0, 2.0, -9.0]
;       Compute the solution of the system, ax = b.
;         result = gs_iter(a, b)
;       Note: This example fails to converge, because A is not in
;             diagonally dominant form.
;
;       Reorder the array given above into diagonally dominant form.
;         a = [[12.0, -1.0,  3.0], $
;              [ 1.0,  7.0, -4.0], $
;              [ 4.0, -4.0,  9.0]]
;       Make corresponding changes in the ordering of b.
;         b = [-9.0, 12.0, 2.0]
;       Compute the solution of the system, ax = b.
;         result = gs_iter(a, b)
;
; PROCEDURE:
;       GS_ITER.PRO implements the Gauss-Seidel iterative method with
;       over- and under- relaxation to enhance convergence.
;
; REFERENCE:
;       ADVANCED ENGINEERING MATHEMATICS (seventh edition)
;       Erwin Kreyszig
;       ISBN 0-471-55380-8
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, April 1993
;       Modified:    GGS, RSI, February 1994
;                    1) Format keyword is no longer supported. The matrix
;                       should be supplied in a row major format.
;                    2) The input/output parameter X has been removed. The
;                       algorithm's initial starting point is an n-element
;                       vector of 1s. The keyword X_0 has been added to
;                       override the default.
;                    3) GS_ITER is now called as a function, x = gs_iter( ).
;       Modified:    GGS, RSI, April 1996
;                    The input arguments are no longer overwritten.
;                    Added DOUBLE keyword. Modified keyword checking and use
;                    of double precision.
;       Modified:    S. Lett, RSI, March 1998
;                    Modified stopping criteria.  Tol is used as an absolute
;                    tolerance when the iterates are very near zero.
;-

FUNCTION GS_ITER, A, B, Check = Check, Lambda = Lambda, Max_Iter = Max_Iter, $
                        X_0 = X_0, Tol = Tol, Double = Double

  ON_ERROR, 2  ;Return to caller if error occurs.

  TypeA = SIZE(A)
  TypeB = SIZE(B)

  if TypeA[TypeA[0]+1] lt 2 or TypeA[TypeA[0]+1] gt 5 then $
    MESSAGE, "Input array (A) must be integer, float, or double."

  if TypeB[TypeB[0]+1] lt 2 or TypeB[TypeB[0]+1] gt 5 then $
    MESSAGE, "Input vector (B) must be integer, float, or double."

  if TypeA[TypeA[0]-1] ne TypeA[TypeA[0]] then $
    MESSAGE, "Input array must be square."

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are determined by the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeA[TypeA[0]+1] eq 5 or TypeB[TypeB[0]+1] eq 5)

  ;Set default values for keyword parameters
  if KEYWORD_SET(Lambda)   eq 0 then Lambda = 1.0
  if KEYWORD_SET(Max_Iter) eq 0 then Max_Iter = 30
  if KEYWORD_SET(X_0)      eq 0 then X_0 = REPLICATE(1.0, TypeA[1])
  if KEYWORD_SET(Tol)      eq 0 then Tol = 1.0e-4

  ;Diagonal elements of input matrix.
  Diag = A[LINDGEN(TypeA[1]) * (TypeA[1]+1)]

  if KEYWORD_SET(Check) ne 0 then begin
    Sum = TOTAL(ABS(A), 1, Double = Double) - ABS(diag)
    caution = WHERE(Sum ge ABS(Diag), Count)
    if Count ne 0 then begin
      PRINT, "Input matrix is not in Diagonally Dominant form." & $
      PRINT, "Algorithm may not converge."
    endif
  endif

  ;Precondition inputs.
  ;Divide the rows of A and B by the diagonal elements of A.
  if Double eq 0 then begin
    AA = A / (REPLICATE(1.0, TypeA[1]) # Diag)
    BB = B / (Diag + 0.0)
    X_0 = FLOAT(X_0)
  endif else begin
    AA = A / (REPLICATE(1.0d, TypeA[1]) # Diag)
    BB = B / (Diag + 0d)
    X_0 = DOUBLE(X_0)
  endelse

  Cond = 0
  Iter = 0

  epsilon = (machar( Double = double )).eps

  ;Begin the computational loop and continue WHILE
  ;the number of iterations is less than max_iter
  ;AND the relative error between iterations is
  ;greater than tol.
  while(Iter lt Max_Iter and Cond eq 0) do begin
    Cond = 1
    Iter = Iter + 1
    ;Formulate x_0 as the row vectors of A.
    for k = 0, TypeA[1]-1 do begin
        xLast = X_0[k]
        X_0[k] = Lambda * (BB[k] - (TOTAL(X_0*AA[*,k],1, Double = Double)) + $
                           (AA[k,k] * X_0[k])) + (1.0 - lambda) * xLast
        if Cond eq 1 then begin
            Error = ABS(X_0[k] - xLast)
            IF (X_0[k] GT epsilon/tol) AND (Error GT Tol*abs( X_0[k] )) THEN $
              Cond = 0
        endif
    ENDFOR
  ENDWHILE
  if Iter ge Max_Iter and Cond eq 0 then $
    MESSAGE, "Algorithm failed to converge within given parameters."

  RETURN, X_0

END
