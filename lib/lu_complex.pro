;$Id: //depot/idl/releases/IDL_80/idldir/lib/lu_complex.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       LU_COMPLEX
;
; PURPOSE:
;       This function solves an N by N complex linear system using
;       LU decomposition. The result is an N-element complex vector.
;       Alternatively, this function computes the generalized inverse
;       of an N by N complex array using LU decomposition. The result
;       is an N by N complex array.
;
; CATEGORY:
;       Complex Linear Algebra.
;
; CALLING SEQUENCE:
;       Result = LU_COMPLEX(A, B)
;
; INPUTS:
;       A:    An N by N array (real or complex).
;
;       B:    An N-element right-side vector (real or complex).
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
;      INVERSE: If set to a non-zero value, the generalized inverse of A
;               is computed. In this case the input parameter B is ignored.
;
;       SPARSE: If set to a non-zero value, the input array is converted
;               to row-indexed sparse storage format. Computations are
;               done using the iterative biconjugate gradient method.
;               This keyword is effective only when solving complex linear
;               systems. This keyword has no effect when calculating the
;               generalized inverse.
;
; EXAMPLE:
;       1) Define a complex array (A) and right-side vector (B).
;            A = [[complex(1, 0), complex(2,-2), complex(-3,1)], $
;                 [complex(1,-2), complex(2, 2), complex(1, 0)], $
;                 [complex(1, 1), complex(0, 1), complex(1, 5)]]
;            B =  [complex(1, 1), complex(3,-2), complex(1,-2)]
;
;          Solve the complex linear system (Az = B) for z.
;            z = LU_COMPLEX(a, b)
;
;        2) Compute the generalized inverse of A.
;            inv = LU_COMPLEX(a, b, /inverse)
;
; PROCEDURE:
;       LU_COMPLEX solves the complex linear system Az = b using
;       LU decomposition. If the SPARSE keyword is set, the coefficient
;       array is converted to row-indexed sparse storage format and the
;       system is solved using the iterative biconjugate gradient method.
;       LU_COMPLEX computes the generalized inverse of the complex
;       array A using LU decomposition if B is supplied as an arbitrary
;       scalar value or if the INVERSE keyword is set.
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press
;       ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, October 1993
;       Modified:    GGS, RSI, February 1994
;                    Transposing the array prior to calling LU_COMPLEX
;                    is no longer necessary. LU_COMPLEX is now able to
;                    compute the generalized inverse of an N by N complex
;                    array using LU decomposition.
;       Modified:    GGS, RSI, June 1994
;                    Included support for sparse complex arrays using the
;                    Numerical Recipes functions NR_SPRSIN and NR_LINBCG.
;       Modified:    GGS, RSI, Decemberber 1994
;                    Added support for double-precision complex inputs.
;                    Reduced internal memory allocation requirements.
;                    Added INVERSE keyword. New documentation header.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;       Modified:    CT, RSI, February 2001
;                    If /INVERSE then ignore second argument. Allow real A.
;                    Use same code path for single & double precision.
;-

FUNCTION LU_Complex, A, B, Double = DoubleIn, Inverse = InverseIn, Sparse = Sparse

	ON_ERROR, 2  ;Return to caller if error occurs.

	Inverse = KEYWORD_SET(InverseIn) or (N_ELEMENTS(B) eq 1)
	notCorrectInverse = (N_PARAMS() eq 1) and (NOT Inverse)
	if ((N_PARAMS() lt 1) or notCorrectInverse) then $
		MESSAGE, "Incorrect number of input arguments."

	TypeA = SIZE(A)
	TypeB = Inverse ? SIZE(A[*,0]) : SIZE(B)

	dimA = SIZE(A,/DIMENSIONS)
	ndimA = SIZE(A,/N_DIMENSIONS)
	nA = dimA[0]
	if (ndimA ne 2) or (nA ne dimA[(ndimA lt 2) ? 0 : 1]) then $
		MESSAGE, "Input array must be a square matrix."

	dimB = SIZE(B,/DIMENSIONS)
	ndimB = SIZE(B,/N_DIMENSIONS)
	if (not Inverse) and ((ndimB ne 1) or (nA ne dimB[0])) then $
		MESSAGE, "Input array and right-side vector are of incompatible size."

	;If the DOUBLE keyword is not set then the internal precision and
	;result are determined by the type of input.
	typeA = SIZE(A,/TNAME)
	typeB = SIZE(B,/TNAME)
	isDouble = (typeA eq 'DOUBLE') or (typeA eq 'DCOMPLEX') or $
		(typeB eq 'DOUBLE') or (typeB eq 'DCOMPLEX')
	Double = (N_ELEMENTS(DoubleIn) gt 0) ? KEYWORD_SET(DoubleIn) : isDouble

	;Double-precision complex.
	if Double then begin
		Comp = [[DOUBLE(A), -IMAGINARY(A)], $
			[IMAGINARY(A), DOUBLE(A)]]
	endif else begin
		Comp = [[FLOAT(A), -FLOAT(IMAGINARY(A))], $
			[FLOAT(IMAGINARY(A)), FLOAT(A)]]
	endelse

	;Generalized inverse of A (does not depend upon SPARSE keyword).
	if Inverse then begin
		Vec = Double ? DBLARR(2L*nA) : FLTARR(2L*nA)
		Inv = Double ? $
		DCOMPLEXARR(nA, nA) : COMPLEXARR(nA, nA)
		;Compute the LU decomp only once and iterate on it!
		; Follows Numerical Recipes section 2.3
		LUDC, Comp, Index, Double = Double
		for k = 0L, nA-1 do begin
			Vec[k] = 1
			Sol = LUSOL(Comp, Index, Vec, Double = Double)
			Vec[k] = 0
			Inv[k, *] = Double ? $
				DCOMPLEX(Sol[0:nA-1], Sol[nA:*]) : $
				COMPLEX(Sol[0:nA-1], Sol[nA:*])
		endfor
		RETURN, Inv
	endif else begin ;Solve Az = b
		;Rhs complex?
		if (typeB ne 'COMPLEX') and (typeB ne 'DCOMPLEX') then begin ; No
			Vec = Double ? [B, DBLARR(dimB[0])] : $
				[B, FLTARR(dimB[0])]
		endif else begin ;Complex
			Vec = Double ? [DOUBLE(B), IMAGINARY(B)] : $
				[FLOAT(B), FLOAT(IMAGINARY(B))]
		endelse
		if keyword_set(SPARSE) eq 0 then begin ;Dense coefficient array.
			LUDC, Comp, Index, Double = Double
			Sol = LUSOL(Comp, Index, Vec, Double = Double)
		endif else begin ;Sparse coefficient array.
			Sol = LINBCG(SPRSIN(Comp, Double = Double), Vec, $
				REPLICATE(1, 2L*dimB[0]), Double = Double)
		endelse
		RETURN, Double ? DCOMPLEX(Sol[0:nA-1], Sol[nA:*]) : $
			COMPLEX(Sol[0:nA-1], Sol[nA:*])
	endelse

END
