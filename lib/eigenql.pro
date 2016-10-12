; $Id: //depot/idl/releases/IDL_80/idldir/lib/eigenql.pro#1 $
;
; Copyright (c) 1996-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       EIGENQL
;
; PURPOSE:
;       This function computes the eigenvalues and eigenvectors of an 
;       N by N real, symmetric array using Householder reductions and 
;       the QL method with implicit shifts. The result is a vector
;	containing the eigenvalues.  The eigenvectors are returned
;	in a separate keyword parameter.
;
; CATEGORY:
;       Linear Algebra / Eigensystems
;
; CALLING SEQUENCE:
;       Eigenvalues = Eigenql(A)
;
; INPUTS:
;       A:    An N by N symmetric array of type float or double.
;
; OUTPUTS:
;	Function value = Eigenvalues = the computed eigenvalues, ordered
;		as specified, stored in an N element vector.
;
; KEYWORD PARAMETERS:
;    ABSOLUTE:   If set, order eigenvalues by their absolute value (magnitude),
;		 otherwise sort by signed value.
;    ASCENDING:  If set to a non-zero value, eigenvalues are returned in
;                ascending order (smallest to largest). If not
;                set or set to zero, eigenvalues are returned in descending
;                order (largest to smallest). The eigenvectors are
;                correspondingly reordered. 
;
;       DOUBLE:  If set to a non-zero value, computations are done in
;                double precision arithmetic.
;
; EIGENVECTORS:  The computed eigenvectors, an N x N array.  The ith
;		 row, (*,i), corresponds to the ith eigenvalue. If this named
;                variable is not supplied, eigenvectors are not computed.
;
;    OVERWRITE:  If set to a non-zero value, the input array is used for
;                internal storage and its previous contents are overwritten,
;		 saving memory if the original array values are no longer
;		 required.
;
;     RESIDUAL:  Use this keyword to specify a named variable which returns
;                the residuals for each eigenvalue/eigenvector(lambda/x) pair.
;                The residual is based on the definition Ax - (lambda)x = 0
;                and is an array of the same size as A and the same type as 
;                RESULT. The rows of this array correspond to the residuals 
;                for each eigenvalue/eigenvector pair.
;                NOTE: If the OVERWRITE keyword is set to a non-zero value,
;                      this keyword has no effect.
;
; EXAMPLE:
;       Define an N by N real, symmetric array.
;         a = [[ 5.0,  4.0,  0.0, -3.0], $
;              [ 4.0,  5.0,  0.0, -3.0], $
;              [ 0.0,  0.0,  5.0, -3.0], $
;              [-3.0, -3.0, -3.0,  5.0]]
;
;       Compute the eigenvalue/eigenvector pairs. 
;       The resulting array has 5 columns and 4 rows. 
;         Eigenvalues = EIGENQL(a, EIGENVECTORS=evecs, RESIDUAL = residual)
;
;	  PRINT, Eigenvalues
;	12.0915       6.18661      1.0000       0.721870 
;	  PRINT, evecs
;        -0.554531    -0.554531    -0.241745     0.571446
;         0.342981     0.342981    -0.813186     0.321646
;         0.707107    -0.707107 -2.58096e-08      0.00000
;         0.273605     0.273605     0.529422     0.754979
;
;       The accuracy of each eigenvalue/eigenvector (lamda/x) pair may be 
;       checked by printing the residual array. This array is the same size 
;       as A and the same type as RESULT. All residual values should be 
;       floating-point zeros.
;         print, residual
;
; MODIFICATION HISTORY:
;           Written by:  GGS, RSI, January 1996
;	    Modified:    DMS, RSI, August 1996
;                        Added ABSOLUTE, and reorganized calling sequence.
;           
;-

FUNCTION EigenQL, Array, Eigenvectors=Eigenvecs, Absolute=absolute, $
		Ascending = Ascending, Double = Double, $
                Overwrite = Overwrite, Residual = Residual

  ;This function computes the eigenvalues and eigenvectors (optionally) of a 
  ;symmetric array. 
 
  ON_ERROR, 2

  Type = SIZE(Array)

  if Type[Type[0]+1] ne 4 and Type[Type[0]+1] ne 5 then $
    MESSAGE, "Input array must be float or double."

  if Type[1] ne Type[2] then $
    MESSAGE, "Input must be an N by N array."

  Symmetric = WHERE(Array ne TRANSPOSE(Array), nErrors)
  if nErrors ne 0 then $
    MESSAGE, "Input array must be symmetric."

  if N_ELEMENTS(Double) eq 0 then Double = (Type[Type[0]+1] eq 5)

  if KEYWORD_SET(Overwrite) then Eigenvecs = TEMPORARY(Array) $
  else Eigenvecs = Array

  ;Compute tridiagonal form.
  TRIRED, Eigenvecs, EigenValues, EigenIndex, Double = Double

  if ARG_PRESENT(Eigenvecs) then begin
    ;Compute the eigenvalues and eigenvectors(stored row-major).
    TRIQL, EigenValues, EigenIndex, Eigenvecs, Double = Double 
  endif else begin
    ;Compute the only the eigenvalues.
    TRIQL_NOVEC, EigenValues, EigenIndex, Double = Double
  endelse

  if KEYWORD_SET(absolute) then  EigenIndex = SORT(ABS(EigenValues)) $
  else EigenIndex = SORT(EigenValues)

  if KEYWORD_SET(Ascending) eq 0 then $	;Descending order?
    EigenIndex = ROTATE(EigenIndex, 5)	;Reverse the indices

  EigenValues = EigenValues[EigenIndex]	        ;Permute the eigenvalues

  if ARG_PRESENT(Eigenvecs) then begin
    Eigenvecs = Eigenvecs[*, EigenIndex]        ;and the eigenvectors.
    
    ;If input array is overwritten, then finish.
    if KEYWORD_SET(Overwrite) then RETURN, Eigenvalues 

    if ARG_PRESENT(Residual) then begin ;Compute eigenvalue/vector residuals.
      if Double eq 0 then Residual = FLTARR(Type[1], Type[2]) $
      else Residual = DBLARR(Type[1], Type[2])
      for k = 0, Type[2]-1 do $
        Residual[*,k] = Array ## Eigenvecs[*,k] - $
                        EigenValues[k] * Eigenvecs[*,k]
    endif
  endif

  RETURN, Eigenvalues

END
