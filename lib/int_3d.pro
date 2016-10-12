;$Id: //depot/idl/releases/IDL_80/idldir/lib/int_3d.pro#1 $
;
; Copyright (c) 1997-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       INT_3D
;
; PURPOSE:
;       This function computes the triple integral of a trivariate
;       function F(x,y,z) with limits of integration from A to B
;       for X, from P(x) to Q(x) for Y and from U(x,y) to V(x,y)
;       for Z.
;
; CATEGORY:
;       Numerical Analysis.
;
; CALLING SEQUENCE:
;       Result = INT_3D(Fxyz, AB_Limits, PQ_Limits, UV_Limits, Pts)
;
; INPUTS:
;       Fxyz:  A scalar string specifying the name of a user-supplied
;              IDL function that defines the trivariate function to be
;              integrated. The function must accept x, y & z and return
;              a scalar result.
;       AB_Limits:  A two-element vector containing the lower, A, and
;                   upper, B,  limits of integration for x.
;       PQ_Limits:  A scalar string specifying the name of a user-
;                   supplied IDL function that defines the lower, P(x),
;                   and upper, Q(x), limits of integration for y. The
;                   function must accept x and return a two-element
;                   vector result.
;       UV_Limits:  A scalar string specifying the name of a user-
;                   supplied IDL function that defines the lower, U(x,y),
;                   and upper, V(x,y), limits of integration for z. The
;                   function must accept x & y and return a two-element
;                   vector result.
;        Pts:  The number of transformation points used in the
;              computation. Possible values are: 6, 10, 20, 48 or 96.
;
; KEYWORD PARAMETERS:
;       DOUBLE: If set to a non-zero value, computations are done in
;               double precision arithmetic.
;
; EXAMPLE:
;       Compute the triple integral of the trivariate function
;       F(x,y,z) = z * (x^2 + y^2 + z^2)^1.5 over the region:
;       A = -2, B = 2, Px = -sqrt(4 - x^2), Qx = sqrt(4 - x^2),
;       Uxy = 0, Vxy = sqrt(4 - x^2 - y^2).
;      
;       ;Define the trivariate function.
;         function Fxyz, x, y, z
;           return, z * (x^2 + y^2 + z^2)^1.5
;         end
;
;       ;Define the limits of integration for y.
;         function PQ_Limits, x
;           return, [-sqrt(4. - x^2), sqrt(4. - x^2)]
;         end
;
;       ;Define the limits of integration for z.
;         function UV_Limits, x, y
;           return, [0.0, sqrt(4. - x^2 - y^2)]
;         end
;
;       ;Define the limits of integration for x.
;         AB_Limits = [-2.0, 2.0]
;
;       ;Integrate with 10, 20, 48, and 96 point formulas using double-
;       ;precision arithmetic. Notice that it is possible to abbreviate
;       ;keywords.
;         print, INT_3D('Fxyz', AB_Limits, 'PQ_Limits', 'UV_Limits', 10, /d)
;         print, INT_3D('Fxyz', AB_Limits, 'PQ_Limits', 'UV_Limits', 20, /d)
;         print, INT_3D('Fxyz', AB_Limits, 'PQ_Limits', 'UV_Limits', 48, /d)
;         print, INT_3D('Fxyz', AB_Limits, 'PQ_Limits', 'UV_Limits', 96, /d)
;
;       INT_3D with 10 transformation points yields:    57.444248
;       INT_3D with 20 transformation points yields:    57.446201
;       INT_3D with 48 transformation points yields:    57.446265
;       INT_3D with 96 transformation points yields:    57.446266
;       The exact solution (6 decimal accuracy) yields: 57.446267
;
; PROCEDURE:
;       INT_3D.PRO computes the triple integral of a trivariate function
;       using iterated Gaussian Quadrature. The algorithm's transformation
;       data is provided in tabulated form with 15 decimal accuracy.
;
; REFERENCE:
;       Handbook of Mathematical Functions
;       U.S. Department of Commerce
;       Applied Mathematics Series 55
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, January 1994
;       Modified:    GGS, RSI, September 1994
;                    Added 96 point transformation data.
;                    Added DOUBLE keyword. Replaced nested FOR loop with
;                    vector operations resulting in faster execution.
;       Modified:    GGS, RSI, April 1996
;                    Modified keyword checking and use of double precision.
;-

FUNCTION Int_3D, Fxyz, AB_Limits, PQ_Limits, UV_Limits, Pts, Double = Double

  ON_ERROR, 2

  if N_ELEMENTS(AB_Limits) ne 2 then $
    MESSAGE, "AB_Limits parameter must be a two-element vector."

; Tabulated transformation data with 15 decimal accuracy.
if Pts eq 6 then begin
  Ri    = DBLARR(Pts)          &   Wi    = DBLARR(Pts)
  Ri[0] = 0.932469514203152d   &   Wi[0] = 0.171324492379170d
  Ri[1] = 0.661209386466265d   &   Wi[1] = 0.360761573048139d
  Ri[2] = 0.238619186083197d   &   Wi[2] = 0.467913934572691d
  Ri[INDGEN(Pts/2) + (Pts/2)] = - Ri[(Pts/2) - INDGEN(Pts/2) -1]
  Wi[INDGEN(Pts/2) + (Pts/2)] =   Wi[(Pts/2) - INDGEN(Pts/2) -1]
endif else if Pts eq 10 then begin
  Ri    = DBLARR(Pts)          &   Wi    = DBLARR(Pts)
  Ri[0] = 0.973906528517172d   &   Wi[0] = 0.066671344308688d
  Ri[1] = 0.865063366688985d   &   Wi[1] = 0.149451349150581d
  Ri[2] = 0.679409568299024d   &   Wi[2] = 0.219086362515982d
  Ri[3] = 0.433395394129247d   &   Wi[3] = 0.269266719309996d
  Ri[4] = 0.148874338981631d   &   Wi[4] = 0.295524224714753d
  Ri[INDGEN(Pts/2) + (Pts/2)] = - Ri[(Pts/2) - INDGEN(Pts/2) -1]
  Wi[INDGEN(Pts/2) + (Pts/2)] =   Wi[(Pts/2) - INDGEN(Pts/2) -1]
endif else if Pts eq 20 then begin
  Ri     = DBLARR(Pts)         &   Wi     = DBLARR(Pts)
  Ri[0]  = 0.993128599185094d  &   Wi[0]  = 0.017614007139152d
  Ri[1]  = 0.963971927277913d  &   Wi[1]  = 0.040601429800386d
  Ri[2]  = 0.912234428251325d  &   Wi[2]  = 0.062672048334109d
  Ri[3]  = 0.839116971822218d  &   Wi[3]  = 0.083276741576704d
  Ri[4]  = 0.746331906460150d  &   Wi[4]  = 0.101930119817240d
  Ri[5]  = 0.636053680726515d  &   Wi[5]  = 0.118194531961518d
  Ri[6]  = 0.510867001950827d  &   Wi[6]  = 0.131688638449176d
  Ri[7]  = 0.373706088715419d  &   Wi[7]  = 0.142096109318382d
  Ri[8]  = 0.227785851141645d  &   Wi[8]  = 0.149172986472603d
  Ri[9]  = 0.076526521133497d  &   Wi[9]  = 0.152753387130725d
  Ri[INDGEN(Pts/2) + (Pts/2)] = - Ri[(Pts/2) - INDGEN(Pts/2) -1]
  Wi[INDGEN(Pts/2) + (Pts/2)] =   Wi[(Pts/2) - INDGEN(Pts/2) -1]
endif else if Pts eq 48 then begin
  Ri     = DBLARR(Pts)         &   Wi     = DBLARR(Pts)
  Ri[0]  = 0.998771007252426d  &   Wi[0]  = 0.003153346052305d
  Ri[1]  = 0.993530172266350d  &   Wi[1]  = 0.007327553901276d
  Ri[2]  = 0.984124583722826d  &   Wi[2]  = 0.011477234579234d
  Ri[3]  = 0.970591592546247d  &   Wi[3]  = 0.015579315722943d
  Ri[4]  = 0.952987703160430d  &   Wi[4]  = 0.019616160457355d
  Ri[5]  = 0.931386690706554d  &   Wi[5]  = 0.023570760839324d
  Ri[6]  = 0.905879136715569d  &   Wi[6]  = 0.027426509708356d
  Ri[7]  = 0.876572020274247d  &   Wi[7]  = 0.031167227832798d
  Ri[8]  = 0.843588261624393d  &   Wi[8]  = 0.034777222564770d
  Ri[9]  = 0.807066204029442d  &   Wi[9]  = 0.038241351065830d
  Ri[10] = 0.767159032515740d  &   Wi[10] = 0.041545082943464d
  Ri[11] = 0.724034130923814d  &   Wi[11] = 0.044674560856694d
  Ri[12] = 0.677872379632663d  &   Wi[12] = 0.047616658492490d
  Ri[13] = 0.628867396776513d  &   Wi[13] = 0.050359035553854d
  Ri[14] = 0.577224726083972d  &   Wi[14] = 0.052890189485193d
  Ri[15] = 0.523160974722233d  &   Wi[15] = 0.055199503699984d
  Ri[16] = 0.466902904750958d  &   Wi[16] = 0.057277292100403d
  Ri[17] = 0.408686481990716d  &   Wi[17] = 0.059114839698395d
  Ri[18] = 0.348755886292160d  &   Wi[18] = 0.060704439165893d
  Ri[19] = 0.287362487355455d  &   Wi[19] = 0.062039423159892d
  Ri[20] = 0.224763790394689d  &   Wi[20] = 0.063114192286254d
  Ri[21] = 0.161222356068891d  &   Wi[21] = 0.063924238584648d
  Ri[22] = 0.097004699209462d  &   Wi[22] = 0.064466164435950d
  Ri[23] = 0.032380170962869d  &   Wi[23] = 0.064737696812683d
  Ri[INDGEN(Pts/2) + (Pts/2)] = - Ri[(Pts/2) - INDGEN(Pts/2) -1]
  Wi[INDGEN(Pts/2) + (Pts/2)] =   Wi[(Pts/2) - INDGEN(Pts/2) -1]
endif else if Pts eq 96 then begin
  Ri     = DBLARR(Pts)         &   Wi     = DBLARR(Pts)
  Ri[0]  = 0.999689503883230d  &   Wi[0]  = 0.000796792065552d
  Ri[1]  = 0.998364375863181d  &   Wi[1]  = 0.001853960788946d
  Ri[2]  = 0.995981842987209d  &   Wi[2]  = 0.002910731817934d
  Ri[3]  = 0.992543900323762d  &   Wi[3]  = 0.003964554338444d
  Ri[4]  = 0.988054126329623d  &   Wi[4]  = 0.005014202742927d
  Ri[5]  = 0.982517263563014d  &   Wi[5]  = 0.006058545504235d
  Ri[6]  = 0.975939174585136d  &   Wi[6]  = 0.007096470791153d
  Ri[7]  = 0.968326828463264d  &   Wi[7]  = 0.008126876925698d
  Ri[8]  = 0.959688291448742d  &   Wi[8]  = 0.009148671230783d
  Ri[9]  = 0.950032717784437d  &   Wi[9]  = 0.010160770535008d
  Ri[10] = 0.939370339752755d  &   Wi[10] = 0.011162102099838d
  Ri[11] = 0.927712456722308d  &   Wi[11] = 0.012151604671088d
  Ri[12] = 0.915071423120898d  &   Wi[12] = 0.013128229566961d
  Ri[13] = 0.901460635315852d  &   Wi[13] = 0.014090941772314d
  Ri[14] = 0.886894517402420d  &   Wi[14] = 0.015038721026994d
  Ri[15] = 0.871388505909296d  &   Wi[15] = 0.015970562902562d
  Ri[16] = 0.854959033434601d  &   Wi[16] = 0.016885479864245d
  Ri[17] = 0.837623511228187d  &   Wi[17] = 0.017782502316045d
  Ri[18] = 0.819400310737931d  &   Wi[18] = 0.018660679627411d
  Ri[19] = 0.800308744139140d  &   Wi[19] = 0.019519081140145d
  Ri[20] = 0.780369043867433d  &   Wi[20] = 0.020356797154333d
  Ri[21] = 0.759602341176647d  &   Wi[21] = 0.021172939892191d
  Ri[22] = 0.738030643744400d  &   Wi[22] = 0.021966644438744d
  Ri[23] = 0.715676812348967d  &   Wi[23] = 0.022737069658329d
  Ri[24] = 0.692564536642171d  &   Wi[24] = 0.023483399085926d
  Ri[25] = 0.668718310043916d  &   Wi[25] = 0.024204841792364d
  Ri[26] = 0.644163403784967d  &   Wi[26] = 0.024900633222483d
  Ri[27] = 0.618925840125468d  &   Wi[27] = 0.025570036005349d
  Ri[28] = 0.593032364777572d  &   Wi[28] = 0.026212340735672d
  Ri[29] = 0.566510418561397d  &   Wi[29] = 0.026826866725591d
  Ri[30] = 0.539388108324357d  &   Wi[30] = 0.027412962726029d
  Ri[31] = 0.511694177154667d  &   Wi[31] = 0.027970007616848d
  Ri[32] = 0.483457973920596d  &   Wi[32] = 0.028497411065085d
  Ri[33] = 0.454709422167743d  &   Wi[33] = 0.028994614150555d
  Ri[34] = 0.425478988407300d  &   Wi[34] = 0.029461089958167d
  Ri[35] = 0.395797649828908d  &   Wi[35] = 0.029896344136328d
  Ri[36] = 0.365696861472313d  &   Wi[36] = 0.030299915420827d
  Ri[37] = 0.335208522892625d  &   Wi[37] = 0.030671376123669d
  Ri[38] = 0.304364944354496d  &   Wi[38] = 0.031010332586313d
  Ri[39] = 0.273198812591049d  &   Wi[39] = 0.031316425596861d
  Ri[40] = 0.241743156163840d  &   Wi[40] = 0.031589330770727d
  Ri[41] = 0.210031310460567d  &   Wi[41] = 0.031828758894411d
  Ri[42] = 0.178096882367618d  &   Wi[42] = 0.032034456231992d
  Ri[43] = 0.145973714654896d  &   Wi[43] = 0.032206204794030d
  Ri[44] = 0.113695850110665d  &   Wi[44] = 0.032343822568575d
  Ri[45] = 0.081297495464425d  &   Wi[45] = 0.032447163714064d
  Ri[46] = 0.048812985136049d  &   Wi[46] = 0.032516118713868d
  Ri[47] = 0.016276744849602d  &   Wi[47] = 0.032550614492363d
  Ri[INDGEN(Pts/2) + (Pts/2)] = - Ri[(Pts/2) - INDGEN(Pts/2) -1]
  Wi[INDGEN(Pts/2) + (Pts/2)] =   Wi[(Pts/2) - INDGEN(Pts/2) -1]
endif else MESSAGE, "Pts parameter must be 6, 10, 20, 48 or 96."

  TypeAB = SIZE(AB_Limits)

  ;If the DOUBLE keyword is not set then the internal precision and
  ;result are identical to the type of input.
  if N_ELEMENTS(Double) eq 0 then $
    Double = (TypeAB[TypeAB[0]+1] eq 5) 

  if Double eq 0 then begin
    Ri = FLOAT(Ri) & Wi = FLOAT(Wi)
  endif

  H1 = (AB_Limits[1] - AB_Limits[0])/2.0
  H2 = (AB_Limits[1] + AB_Limits[0])/2.0
  Aj = 0.0
  for i = 0, Pts-1 do begin
    X  = H1 * Ri[i] + H2
    jX = 0.0
    CF = CALL_FUNCTION(PQ_Limits, X)
    k1 = (CF[1] - CF[0])/2.0
    k2 = (CF[1] + CF[0])/2.0
    for j = 0, Pts-1 do begin
      Y  = k1 * Ri[j] + k2
      CF = CALL_FUNCTION(UV_Limits, X, Y)
      l1 = (CF[1] - CF[0]) / 2.0
      l2 = (CF[1] + CF[0]) / 2.0
      jY = TOTAL(Wi * CALL_FUNCTION(Fxyz, X, Y, l1*Ri+l2), Double = Double)
      jX = jX + Wi[j] * l1 * jY
    endfor
    Aj = Aj + Wi[i] * k1 * jX
  endfor

  if Double eq 0 then RETURN, FLOAT(Aj * H1) else $
    RETURN, (Aj * H1)

end
