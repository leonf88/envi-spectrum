; $Id: //depot/idl/releases/IDL_80/idldir/lib/vel.pro#1 $
;
; Distributed by ITT Visual Information Solutions.
;

function vel__mybi,a,x,y

COMPILE_OPT idl2, hidden
on_error,2                      ;Return to caller if an error occurs

sizea=size(a)
nx=sizea[1]
i=long(x)+nx*long(y)
q=y-long(y)
p=x-long(x)
q1 = 1.-q
p1 = 1.-p

; Weighting factors were wrong for a(i+1) & a(i+nx), switched them.

aint=p1*q1*a[i] + p*q1*a[i+1] + q*p1*a[i+nx] + p*q*a[i+nx+1]
return,aint
end

PRO VEL__ARRHEAD,X

COMPILE_OPT idl2, hidden
ON_ERROR,2                      ;Return to caller if an error occurs

theta = 30 * !radeg
TANT = TAN(THETA)
NP=3.0
SCAL=8.

SX=SIZE(X)
N=SX[2]


BIGL=SQRT((X[*,N-4,0]-X[*,N-5,0])^2+(X[*,N-4,1]-X[*,N-5,1])^2)
wbigl=where(BIGL ne 0.0)
wnbigl=where(bigl eq 0.0, count)
LL  = SCAL*TANT*BIGL[wbigl]/NP

DX = LL*(X[wbigl,N-4,1]-X[wbigl,N-5,1])/BIGL[wbigl]
DY = LL*(X[wbigl,N-4,0]-X[wbigl,N-5,0])/BIGL[wbigl]

XM = X[wbigl,N-4,0]-(SCAL-1)*(X[wbigl,N-4,0]-X[wbigl,N-5,0])/NP
YM = X[wbigl,N-4,1]-(SCAL-1)*(X[wbigl,N-4,1]-X[wbigl,N-5,1])/NP

X[wbigl,N-3,0] = XM-DX
X[wbigl,N-2,0] = X[wbigl,N-4,0]
X[wbigl,N-1,0] = XM+DX

X[wbigl,N-3,1] = YM+DY
X[wbigl,N-2,1] = X[wbigl,N-4,1]
X[wbigl,N-1,1] = YM-DY

if count ge 1 then begin  ;No head for 0 length
	X[wnbigl,N-3,0] = x[wnbigl,n-4,0]
	X[wnbigl,N-2,0] = X[wnbigl,n-4,0]
	X[wnbigl,N-1,0] = X[wnbigl,n-4,0]

	X[wnbigl,N-3,1] = X[wnbigl,N-4,1]
	X[wnbigl,N-2,1] = X[wnbigl,N-4,1]
	X[wnbigl,N-1,1] = X[wnbigl,N-4,1]
	endif

return
END

function vel__arrows,u,v,n,length,nsteps=nsteps

COMPILE_OPT idl2, hidden
on_error,2                      ;Return to caller if an error occurs

su=size(u)
nx=su[1]
ny=su[2]

lmax=sqrt(max(u^2+v^2, /NAN))		;Max vector length
lth=1.*length/lmax/nsteps
xt=randomu(seed,n)		;Starting position
yt=randomu(seed,n)
x=fltarr(n,nsteps+3,2)
x[0,0,0]=xt
x[0,0,1]=yt
for i=1,nsteps-1 do begin
 xt[0]=(nx-1)*x[*,i-1,0]
 yt[0]=(ny-1)*x[*,i-1,1]
 ut=vel__mybi(u,xt,yt)
 vt=vel__mybi(v,xt,yt)
 x[0,i,0]=x[*,i-1,0]+ut*lth
 x[0,i,1]=x[*,i-1,1]+vt*lth
end
VEL__ARRHEAD,X
return,x<1.0>0.0
end


;+
; NAME:
;	VEL
;
; PURPOSE:
;	Draw a velocity (flow) field with arrows following the field
;	proportional in length to the field strength.  Arrows are composed
;	of a number of small segments that follow the streamlines.
;
; CATEGORY:
;	Graphics, two-dimensional.
;
; CALLING SEQUENCE:
;	VEL, U, V
;
; INPUTS:
;	U:	The X component at each point of the vector field.  This
;		parameter must be a 2D array.
;
;	V:	The Y component at each point of the vector field.  This
;		parameter must have the same dimensions as U.
;
; KEYWORD PARAMETERS:
;	NVECS:	The number of vectors (arrows) to draw.  If this keyword is
;		omitted, 200 vectors are drawn.
;
;	XMAX:	X axis size as a fraction of Y axis size.  The default is 1.0.
;		This argument is ignored when !p.multi is set.
;
;	LENGTH:	The length of each arrow line segment expressed as a fraction
;		of the longest vector divided by the number of steps.  The
;		default is 0.1.
;
;	NSTEPS:	The number of shoots or line segments for each arrow.  The
;		default is 10.
;
;	TITLE:	A string containing the title for the plot.
;
; OUTPUTS:
;	No explicit outputs.  A velocity field graph is drawn on the current
;	graphics device.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A plot is drawn on the current graphics device.
;
; RESTRICTIONS:
;	none
;
; PROCEDURE:
;	NVECS random points within the (u,v) arrays are selected.
;	For each "shot" the field (as bilinearly interpolated) at each
;	point is followed using a vector of LENGTH length, tracing
;	a line with NSTEPS segments.  An arrow head is drawn at the end.
;
; MODIFICATION HISTORY:
;	Neal Hurlburt, April, 1988.
;	12/2/92	- modified to handle !p.multi (jiy-RSI)
;       7/12/94 HJM - Fixed error in weighting factors in function
;                     vel_mybi() which produced incorrect velocity vectors.
;	2/18/99 - SJL - Added check of input array dims
;
;-
PRO VEL,U,W,LENGTH=length,XMAX=xmax, nvecs = nvecs, nsteps = nsteps, $
	title = title

compile_opt idl2

on_error,2                      ;Return to caller if an error occurs

if n_elements(Nvecs) le 0 then nvecs=200
if n_elements(nsteps) le 0 then nsteps = 10
if n_elements(length) le 0 then length=.1
if n_elements(title) le 0 then title='Velocity Field'

sx = SIZE(u,/n_dimensions)
sw = SIZE(w,/n_dimensions)
if ((sx ne 2) or (sw ne 2)) then begin
	message,'U,W must be 2 dimensional arrays.'
	return
endif

X=VEL__ARROWS(U,W,Nvecs,LENGTH, nsteps = nsteps)

if (!p.multi[1] eq 0 and !p.multi[1] eq 0) then begin
   if (n_elements(xmax) eq 0) then xmax = 1.0
   IF XMAX GT 1. THEN position=[0.20,(0.5-0.30/XMAX),0.90,(0.5+0.40/XMAX)]$
      else position=[(0.5-0.30*XMAX),0.20,(0.5+0.40*XMAX),0.90]
   plot,[0,1,1,0,0],[0,0,1,1,0],title=title,pos=position
endif else begin
   plot,[0,1,1,0,0],[0,0,1,1,0],title=title
endelse

FOR I=0,Nvecs-1 DO PLOTS,X[I,*,0],X[I,*,1]

end
