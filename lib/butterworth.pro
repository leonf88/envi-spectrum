;; $Id: //depot/idl/releases/IDL_80/idldir/lib/butterworth.pro#1 $
;;
;; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
;; NAME:
;;   Butterworth
;;
;; PURPOSE:
;;   This function returns an array which contains the Butterworth
;;   kernel for a given input order and cutoff.
;;
;; PARAMETERS:
;;   XIN - (required) Either a scalar containing the number of
;;         elements in the X direction or a vector up to 3 elements
;;         long giving the number of elements in the X, Y, and Z
;;         directions, respectively.
;;
;;   YIN - The number of elements in the Y direction.  
;;   
;;   ZIN - The number of elements in the Z direction.
;;   
;; KEYWORDS:
;;   CUTOFF - The cutoff frequency.
;;
;;   ORDER - The order of the filter.
;;
;;   ORIGIN - IF set, center the return array at the corners of the
;;            array.
;;
;;   XDIM - The X spacing of the columns.
;;
;;   YDIM - The Y spacing of the rows.
;;
;;   ZDIM - The Z spacing of the planes.
;;
;; MODIFICATION HISTORY:
;;   Created by:  AGEH, November 2005
;-

FUNCTION butterworth, xin, yin, zin, $
                      CUTOFF=cutoffin, ORDER=orderin, $
                      XDIM=xdimin, YDIM=ydimin, ZDIM=zdimin, $
                      ORIGIN=origin

  on_error, 2

  ;; Get number of elements in each dimension
  IF (n_elements(xin) GT 1) THEN BEGIN
    SWITCH n_elements(xin) OF
      3 : z = real_part(xin[2])
      2 : y = real_part(xin[1])
      1 : x = real_part(xin[0])
      ELSE :
    ENDSWITCH
  ENDIF ELSE BEGIN
    SWITCH n_params() OF
      3 : z = real_part(zin[0])
      2 : y = real_part(yin[0])
      1 : x = real_part(xin[0])
      ELSE :
    ENDSWITCH
  ENDELSE

  ;; If the inputs were not valid then return 0
  IF ~n_elements(x) THEN return, 0

  ;; Set default values
  IF (n_elements(xdimin) NE 1) THEN xdim = 1 ELSE xdim = xdimin
  IF (n_elements(ydimin) NE 1) THEN ydim = 1 ELSE ydim = ydimin
  IF (n_elements(zdimin) NE 1) THEN zdim = 1 ELSE zdim = zdimin
  IF (n_elements(cutoffin) NE 1) THEN cutoff = 9 ELSE cutoff = cutoffin
  IF (n_elements(orderin) NE 1) THEN order = 1 ELSE order = orderin

  ;; Create distance frequency array
  n = n_elements(x)+n_elements(y)+n_elements(z)
  SWITCH n OF
    1 : BEGIN
      distarr = fltarr(x)
      FOR i=0,x-1 DO $
        distarr[i] = sqrt(((i-x/2)*xdim)^2)
      BREAK
    END
    2 : BEGIN
      distarr = fltarr(x, y)
      FOR j=0,y-1 DO $
        FOR i=0,x-1 DO $
        distarr[i,j] = sqrt(((i-x/2)*xdim)^2 + ((j-y/2)*ydim)^2)
      BREAK
    END
    3 : BEGIN
      distarr = fltarr(x, y, z)
      FOR k=0,z-1 DO $
        FOR j=0,y-1 DO $
          FOR i=0,x-1 DO $
            distarr[i,j,k] = sqrt(((i-x/2)*xdim)^2 + ((j-y/2)*ydim)^2 + ((k-z/2)*zdim)^2)
      BREAK
    END
    ELSE :
  ENDSWITCH

  ;; Create butterworth filter from distance array
  bFilter = 1.0 / sqrt((1 + (distarr/cutoff)^(2*order)))

  ;; Shift values if requested
  IF ~keyword_set(origin) THEN BEGIN
    CASE n OF
      1 : BEGIN
        bFilter = shift(bFilter, ceil(x/2.0))
      END
      2 : BEGIN
        ;; Creation of bFilter can drop trailing dimensions of 1.  We must
        ;; have the proper number of dimensions for the potential subsequent
        ;; shift operation
        IF (y EQ 1) THEN bFilter = reform(bFilter, x, y)
        bFilter = shift(bFilter, ceil(x/2.0), ceil(y/2.0))
      END
      3 : BEGIN
        ;; Creation of bFilter can drop trailing dimensions of 1.  We must
        ;; have the proper number of dimensions for the potential subsequent
        ;; shift operation
        IF (z EQ 1) THEN bFilter = reform(bFilter, x, y, z)
        bFilter = shift(bFilter, ceil(x/2.0), ceil(y/2.0), ceil(z/2.0))
      END
      ELSE :
    ENDCASE
  ENDIF

  return, bFilter

END
