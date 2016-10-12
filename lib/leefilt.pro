; $Id: //depot/idl/releases/IDL_80/idldir/lib/leefilt.pro#1 $
;
; Distributed by ITT Visual Information Solutions.
;

Function Lee_filter_exact,A,N,SIG, $
	DOUBLE=double
;
; Slow, but accurate Lee filter. Derived from
; Jong-Sen Lee, Optical Engineering 25(5), 636-643 (May 1986)
;

COMPILE_OPT hidden

on_error,2

Delta = (LONG(N)-1L)/2L         ;Width of window
SZ=size(A)
N_SAMPLES=SZ[1]                 ;# of columns
;
mean=smooth(a, N, /EDGE_TRUNCATE)
mean2=mean^2
;
IF SZ[0] eq 1 THEN BEGIN        ;Vector?
    z = double ? dblarr(n_samples) : fltarr(n_samples)
    FOR S=Delta,N_SAMPLES-Delta-1 DO $
      Z[S]=TOTAL((A[S-Delta:S+Delta] - mean[S])^2)
    z = z / (n-1)               ;Variance

ENDIF ELSE BEGIN                ;***** 2D case *****

    N_LINES=SZ[2]
;
; Compute Variance of Z
;
    z = double ? dblarr(n_samples, n_lines) : fltarr(n_samples, n_lines)
    FOR L=Delta, N_LINES-Delta-1 DO $
      FOR S=Delta, N_SAMPLES-Delta-1 DO $
      Z[S,L]=TOTAL((A[S-Delta:S+Delta,L-Delta:L+Delta] - mean[S,L])^2)
    z = z / (n^2-1)             ;Variance
ENDELSE

;
; Upon starting the next equation,  Z = Var(Z). Upon exit, Z = Var(X)
; of equation 19 of Lee, Optical Engineering 25(5), 636-643 (May 1986)
;
; VAR_X = (VAR_Z + Mean^2 )/(Sigma^2 +1) - Mean^2   (19)
;
; Here we constrain to >= 0, because Var(x) can't be negative:
Z=((TEMPORARY(Z) +mean2) /(1 + Sig^2)) - mean2 > 0
;
; return value from equation 21,22 of Lee, 1986.
; K = ( VAR_X/(mean^2 * Sigma^2 + VAR_X) )          (22)
; Filtered_Image = Mean + K * ( Input_Image - Mean) (21)
;
return, mean + (A-mean) * ( Z/(mean2*Sig^2 + Z) )
END




; Faster, but less accurate Lee filter. Only recomended when N < 7.
Function Lee_filter_fast,A,N,SIG, $
	DOUBLE=double

COMPILE_OPT hidden

on_error,2

Xmean = SMOOTH(a, N, /EDGE_TRUNCATE) ;Ensure floating
Xmean2 = Xmean^2
AA = A - Xmean

; Here we VAR_X to be >= 0, because the variance can't be < 0.
VAR_X=((SMOOTH(AA^2, N, /EDGE_TRUNCATE)+Xmean2)/(1+Sig^2)) - Xmean2 > 0

; return value from equation 21,22 of Lee, 1986.
; K = ( VAR_X/(Xmean^2 * Sigma^2 + VAR_X) )          (22)
; Filtered_Image = Xmean + K * ( Input_Image - Xmean) (21)
;

RETURN, Xmean + AA * (VAR_X / ( Xmean2 * Sig^2 + VAR_X))
END

;+
; NAME:
;	LEEFILT
;
; PURPOSE:
;	Performs the Lee filter algorithm on an image array using a
;	box of size 2N+1.  This function can also be used on vectors.
;
; CATEGORY:
;	E3 Smoothing (image).
;
; CALLING SEQUENCE:
;	Result = LEEFILT(A [, N, Sig])
;
; INPUTS:
;	A:	The input image array or one-dimensional vector.
;
; OPTIONAL INPUT PARAMETERS:
;	N:	The size of the filter box is 2N+1.  The default value is 5.
;
;	Sig:	Estimate of the standard deviation.  The default is 5.
;		If Sig is negative the procedure requests a value to be
;		entered, and displays the resulting image or vector.  This
;               cycle continues until a zero value of Sig is entered.
;
; KEYWORDS:
;
;	EXACT:  Use this keyword to use a more accurate, but much slower
;		Lee filter algorithm. Recommended when N > ~7.
;
;   DOUBLE = Set this keyword to force the computations to be done
;            in double-precision arithmetic.
;
; OUTPUTS:
;	The filtered image or vector is returned.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	Displays the filtered image in an IDL window using TVSCL or PLOT if
;       Sig is negative.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	The LEE (Optical Engineering, Vol 25, No 5, Pg 636-643, May 1986)
;       technique smooths additive image noise by generating statistics in
;       a local neighborhood and comparing them to the expected values.
;
; MODIFICATION HISTORY:
;	Written, 24-Nov-1982, by R. A. Howard, Naval Research Lab,
;				 Washington, DC 20375
;       Modified, 30-May-1996, SVP. Modifed to match 1986 algorithm &
;                              Added /EXACT at user suggestion.
;                              Added PLOT for vector support.
;   CT, RSI, May 2000: Added double-precision support.
;-
;
Function Leefilt, aIn, nIn, sigIn, $
	DOUBLE=double, $
	EXACT=EXACT
ON_ERROR,2                      ;Return to caller if an error occurs

tnames = [SIZE(aIn,/TNAME), SIZE(nIn,/TNAME), SIZE(sigIn,/TNAME)]
double = (N_ELEMENTS(double) GT 0) ? KEYWORD_SET(double) : $
	MAX(tnames EQ 'DOUBLE')

NP = N_params(0)
IF np lt 3 THEN sigIn = 5 ;supply defaults
sig = double ? DOUBLE(sigIn) : FLOAT(sigIn)


IF np lt 2 THEN nIn = 5
dim = SIZE(aIn,/DIMENSIONS)
n = FLOOR(nIn)
IF ((n LT 1) OR (n GE MIN(dim)/2)) THEN MESSAGE, $
	'Filter width 2N+1 must be > 2 and smaller than array dimensions.'


a = double ? DOUBLE(aIn) : FLOAT(aIn)
pl = sig LE 0.			;true if interactive mode
loop:
	IF pl THEN read,'Type in Sigma (0 to quit) :  ',sig
	IF sig EQ 0 THEN goto,endp
        IF keyword_set(EXACT) THEN $
          f=lee_filter_exact(a,2*n+1,Sig, DOUBLE=double)  $
        ELSE f=lee_filter_fast(a,2*n+1,Sig, DOUBLE=double)
	IF pl THEN BEGIN
           IF (size(f))[0] eq 1 then $
           PLOT,f,xtitle='Element of A',ytitle='Value of A',$
                title='Lee Filtered A, N ='+string(N,FORMAT='(I3)')+', Sigma = '+$
                string(Sig,FORMAT='(F5.2)') else TVSCL,f
	   GOTO , loop
	ENDIF
endp:	RETURN,f
END
