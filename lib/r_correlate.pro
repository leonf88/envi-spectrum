;$Id: //depot/idl/releases/IDL_80/idldir/lib/r_correlate.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       R_CORRELATE
;
; PURPOSE:
;       This function computes Spearman's (rho) or Kendalls's (tau) rank
;       correlation of two n-element vectors. The result is a two-element
;       vector containing the rank correlation coefficient and the two-sided
;       significance level of its deviation from zero.
;
; CATEGORY:
;       Statistics.
;
; CALLING SEQUENCE:
;       Result = R_correlate(X, Y)
;
; INPUTS:
;       X:    An n-element vector of type integer, float or double.
;
;       Y:    An n-element vector of type integer, float or double.
;
; KEYWORD PARAMETERS:
; KENDALL:    If set to a nonzero value, Kendalls's (tau) rank correlation
;             is computed. By default, Spearman's (rho) rank correlation is
;             computed.
;
;       D:    Use this keyword to specify a named variable which returns the
;             sum-squared difference of ranks. If the KENDALL keyword is set
;             to a nonzero value, this parameter is returned as zero.
;
;      ZD:    Use this keyword to specify a named variable which returns the
;             number of standard deviations by which D deviates from its null-
;             hypothesis expected value. If the KENDALL keyword is set to a
;             nonzero value, this parameter is returned as zero.
;
;   PROBD:    Use this keyword to specify a named variable which returns the
;             two-sided significance level of ZD. If the KENDALL keyword is
;             set to a nonzero value, this parameter is returned as zero.
;
; EXAMPLE
;       Define two n-element vectors of tabulated data.
;         x = [257, 208, 296, 324, 240, 246, 267, 311, 324, 323, 263, 305, $
;              270, 260, 251, 275, 288, 242, 304, 267]
;         y = [201, 56, 185, 221, 165, 161, 182, 239, 278, 243, 197, 271, $
;              214, 216, 175, 192, 208, 150, 281, 196]
;
;       Compute Spearman's (rho) rank correlation of x and y.
;         result = r_correlate(x, y, d = d, zd = zd, probd = probd)
;       The result should be the two-element vector:
;         [0.835967, 4.42899e-06]
;       The keyword parameters should be returned as:
;         d = 218.000, zd = -3.64390, probd = 0.000268542
;
;       Compute Kendalls's (tau) rank correlation of x and y.
;         result = r_correlate(x, y, /kendall)
;       The result should be the two-element vector:
;         [0.624347  0.000118732]
;
; REFERENCE:
;       Numerical Recipes, The Art of Scientific Computing (Second Edition)
;       Cambridge University Press
;       ISBN 0-521-43108-5
;
; MODIFICATION HISTORY:
;       Written by:  GGS, RSI, Aug 1994
;                    R_CORRELATE is based on the routines spear.c and kendl1.c
;                    described in section 14.6 of Numerical Recipes, The Art
;                    of Scientific Computing (Second Edition), and is used by
;                    permission.
;       CT, RSI, March 2000: removed redundant betacf, ibeta functions
;-


function r_correlate, x, y, kendall = kendall, d = d, zd = zd, probd = probd

  on_error, 2
  nx = n_elements(x)
  if nx le 1 or n_elements(y) le 1 then $
    message, 'x and y must be n-element vectors.'
  if nx ne n_elements(y) then $
    message, 'x and y must be vectors of equal length.'

  if keyword_set(kendall) eq 0 then begin ;Spearman's (rho)
    type = size(x)
    wrkx = x
    wrky = y
    ixy  = sort(wrkx) ;Indexes of "wrkx" in ascending order.
    wrkx = wrkx[ixy]  ;Rearrangement of "wrkx" according to ixy.
    wrky = wrky[ixy]  ;Rearrangement of "wrky" according to ixy.
    idl_crank, wrkx, sf   ;Replace elements of "wrkx" by their rank.
    ixy  = sort(wrky) ;Indexes of "wrky" in ascending order.
    wrkx = wrkx[ixy]  ;Rearrangement of "wrkx" according to ixy.
    wrky = wrky[ixy]  ;Rearrangement of "wrky" according to ixy.
    idl_crank, wrky, sg   ;Replace elements of "wrky" by their rank.
    d = total((wrkx-wrky)^2)
    ;Free intermediate variables.
    wrkx = 0
    wrky = 0
    ixy = 0
    en = nx + 0.0
    en3n = en^3 - en
    aved = en3n/6.0 - (sf + sg)/12.0
    fac = (1.0 - sf/en3n) * (1.0 - sg/en3n)
    vard = ((en - 1.0) * en^2 * (en + 1.0)^2 / 36.0) * fac
    zd = (d - aved) / sqrt(vard)
    probd = 1.0-errorf(abs(zd)/1.4142136)
    rs = (1.0 - (6.0/en3n) * (d+(sf+sg)/12.0))/sqrt(fac)
    fac = (1.0 + rs) * (1.0 - rs)
    if (fac gt 0.0) then begin
      t = rs * sqrt((en - 2.0)/fac)
      df = en - 2
      probrs = ibeta(0.5*df, 0.5, df/(df+t^2))
    endif else probrs = 0.0
    ;Return a vector of rank-correlation parameters.
    if type[2] eq 5 then begin
      d = d+0d & zd = zd+0d & probd = probd+0d
      return, [rs, probrs]
    endif else begin
      d = float(d) & zd = float(zd) & probd = float(probd)
      return, float([rs, probrs])
    endelse
  endif else begin ;Kendall's (tau)
    nnx = 0.0
    nny = 0.0
    is  = 0.0
    ;There seems to be no efficient method of avoiding this nested
    ;FOR loop structure. An alternate method is possible, but requires
    ;about (1/2 * nx^2) storage and one FOR loop.
    for j = 0, nx-2 do begin
      for k = j+1, nx-1 do begin
        dx = x[j] - x[k]
        dy = y[j] - y[k]
        aa = dx * dy
        if aa ne 0 then begin
          nnx = nnx + 1
          nny = nny + 1
          if aa gt 0 then is = is + 1 $
            else is = is - 1
        endif else begin
          if dx ne 0 then nnx = nnx + 1 $
          else if dy ne 0 then nny = nny + 1
        endelse
      endfor
    endfor
    d = 0 & zd = 0 & probd = 0 ;Keyword parameters of Spearman's (rho).
    tau = is / sqrt(nnx * nny)
    var = (4.0 * nx + 10.0) / (9.0 * nx * (nx-1.0))
      z = tau / sqrt(var)
    prob = 1.0-errorf(abs(z) / 1.4142136)
    return, [tau, prob]
  endelse
end
