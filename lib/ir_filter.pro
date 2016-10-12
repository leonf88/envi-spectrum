; $Id: //depot/idl/releases/IDL_80/idldir/lib/ir_filter.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IR_FILTER
;
; PURPOSE:
;   This function filters data with an infinite impulse response (IIR)
;   or finite impulse response (FIR) filter.  If D is a scalar then
;   the filter is IIR, otherwise it is FIR.
;
; CATEGORY:
;   Signal processing.
;
; CALLING SEQUENCE:
;   Y = IR_FILTER(C [, D], X)
;
; PARAMETERS:
;   C - A vector defining the numerator coefficients.
;
;   D - A vector defining the scaling factor and denominator
;       coefficients.
;
;   X - Input data vector.
;
; KEYWORDS:
;   DOUBLE - If set, return Y as double, default is float.
;
; MODIFICATION HISTORY:
;   Created by:  AGEH, December 2005
;-
;
FUNCTION ir_filter, cin, din, xin, double=double
  on_error, 2

  ;; check inputs
  CASE n_params() OF
    2 : BEGIN
      c = cin
      d = 1
      x = din
    END
    3 : BEGIN
      c = cin
      d = din
      x = xin
    END
    ELSE : message, 'Must have 2 or 3 input variables'
  ENDCASE

  IF max([size(c, /n_dimensions),size(d, /n_dimensions), $
          size(x, /n_dimensions)]) GT 1 THEN $
    message, 'Inputs must be vectors'

  IF (d[0] EQ 0) THEN $
    message, 'The normalizing value, d[0], cannot be zero'

  ;; determine if filter will be FIR or IIR
  iir = n_elements(d) GT 1

  ;; normalize coefficients
  IF (d[0] NE 1) THEN BEGIN
    c /= double(d[0])
    d /= double(d[0])
  ENDIF

  tname = size(x, /tname)
  cplex = tname EQ 'COMPLEX'
  dcplex = tname EQ 'DCOMPLEX'
  dbl = tname eq 'DOUBLE'
  ;; determine type of output array, order of preference is:
  ;; dcomplex (9), complex (6), double (5), float (4)
  type = dcplex ? 9 : (cplex ? (keyword_set(double) ? 9 : 6) : $
                       (keyword_set(double) || dbl ? 5 : 4))
  ;; set up output array.
  y = make_array(size(x, /dimensions), type=type)

  ;; set up arrays needed for computation
  rc = reverse(c)
  nc = n_elements(rc)
  IF iir THEN BEGIN
    rd = reverse(d[1:*])
    nd = n_elements(rd)
  ENDIF

  ;; initial y value
  y[0] = c[0]*x[0]
  ;; fill in rest of y values
  FOR i=1l,n_elements(x)-1 DO BEGIN
    ;; FIR part
    y[i] = total(x[0 > (i-nc+1):i]*rc[(nc-i-1) > 0:nc-1])
    ;; IIR part
    IF iir THEN BEGIN
      y[i] += total(y[0 > (i-nd):i-1]*rd[(nd-i) > 0:nd-1])
    ENDIF
  ENDFOR

  return, y

END

