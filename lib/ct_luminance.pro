; $Id: //depot/idl/releases/IDL_80/idldir/lib/ct_luminance.pro#1 $

; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;++NODOCUMENT
; NAME:
;	CT_LUMINANCE
;
; PURPOSE:
;	Calculate the luminance of colors.
;
; CATEGORY:
;	Color tables
;
; CALLING SEQUENCE:
;	L = CT_LUMINANCE(R, G, B)
;
; INPUTS:
;	R = Red color table.  If omitted, use the color values from
;		either the COLORS common block, or the current color table.
;	G = Green color table, optional parameter.
;	B = Blue color table, optional parameter.
;
; KEYWORD PARAMETERS:
;	BRIGHT=var - Stores the index of the brightest color in the current
;		colortable into var.
;	DARK=var - Stores the index of the darkest color in the current
;		colortable into var.
;	READ_TABLES = if set and parameters are not specified,
;		read directly from color tables, using
;		TVLCT, /GET.  Do not use the COLORS common block.
;
; OUTPUTS:
;   This function returns an array containing the luminance values
;	of the specified colors.  If the R,G,B parameters are not
;	specified, or if R is of integer, byte or long type, the
;	result is a longword array.  Otherwise, the result is a
;	floating point array.
;
; COMMON BLOCKS:
;	COLORS:	Contains the current RGB color tables.
;
; MODIFICATION HISTORY:
;	April 1, 1992, AB
;		When splitting XPALETTE into widget clusters, this code
;		became necessary in multiple places. This routine
;		encapsulates it.
;	May 15, 1994, DMS
;		Process colors from parameters or current color table.
;-

function CT_LUMINANCE, R, G, B, DARK=dark, BRIGHT=bright, READ_TABLES=read_it

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  ; This is the standard NTSC luminance equation

  on_error,2                      ;Return to caller if an error occurs
  if n_elements(r) gt 0 then begin	;Use params?
	lum = .3 * r + .59 * g + .11 * b
	s = size(r)		;Integer?
	if s[s[0]+1] le 3 then lum = round(lum) < 255  ;Integerize?
  endif else if keyword_set(read_it) then begin	;Use current color table?
	tvlct, r, g, b, /GET
	lum = ROUND(.3 * r + .59 * g + .11 * b) < 255
  endif else BEGIN			;Use common block?
	  ; Make sure the colors common block is initialized
	  if (n_elements(r_curr) eq 0) then begin
	    r_orig = bytscl(indgen(!d.table_size))
	    g_orig = r_orig & b_orig = r_orig
	    r_curr = r_orig & g_curr = r_orig & b_curr = r_orig
	  endif
	lum= ROUND(.3 * r_curr + .59 * g_curr + .11 * b_curr) < 255
  endelse

  junk = max(lum, bright)	;Return indices of brightest & darkest entries
  junk = min(lum, dark)
  return, lum
end
