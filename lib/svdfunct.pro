; $Id: //depot/idl/releases/IDL_80/idldir/lib/svdfunct.pro#1 $
;
; Distributed by ITT Visual Information Solutions.
;
;       Default function for SVDFIT
;
;       Accepts scalar X and M, returns
;       the basis functions for a polynomial series.
;
function svdfunct,X,M

compile_opt idl2

        XX=X[0]                 ; ensure scalar XX
	sz=reverse(size(XX))    ; use size to get the type
        IF sz[n_elements(sz)-2] EQ 5 THEN $
		basis=DBLARR(M) else basis=FLTARR(M)
;
;       Calculate and return the basis functions
;
        basis[0]=1.0
        FOR i=1,M-1 DO basis[i]=basis[i-1]*XX
	return,basis
end
