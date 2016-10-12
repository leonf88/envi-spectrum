; $Id: //depot/idl/releases/IDL_80/idldir/lib/showfont.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

PRO SHOWFONT, FONT, NAME, ENCAPSULATED = encapsulated, TT_FONT = tt_font
;+
; NAME:
;	SHOWFONT
;
; PURPOSE:
;	This procedure displays a vector-drawn font on the current
;	graphics device.
;
; CATEGORY:
;	Fonts.
;
; CALLING SEQUENCE:
;	SHOWFONT, Font, Name
;
; INPUTS:
;	Font:	 The index number of the font (may range from 3 to 29)
;		 or, if the TT_FONT keyword is set, a string representing
;                the name of the TrueType font to display.
;	Name:	 Title text to appear at top of display.
;
; KEYWORD PARAMETERS:
;	ENCAPSULATED:	If this keyword is set, and if the current graphics
;			device is "PS", makes encapsulated PostScript output.
;	TT_FONT:	If this keyword is set, the Font argument is 
;			interpreted as the name of a TrueType font.
;
; OUTPUTS:
;	No explicit outputs.
;
; SIDE EFFECTS:
;	A display is made.
;
; RESTRICTIONS:
;	Not very flexible.
;
; PROCEDURE:
;	Straightforward.
;
; EXAMPLE:
;	To create a display of Font 3 for PostScript:
;		SET_PLOT, 'PS'
;		SHOWFONT, 3, "Simplex Roman"
;
;	To create a display of the Times Roman TrueType font:
;		SHOWFONT, 'Times', 'Times Roman', /TT_FONT
;
; MODIFICATION HISTORY:
; 	Written by:
;	DMS, Nov, 1992
;	WSO, 1/95, Updated for new directory structure
;	DD, 12/97, Updated to handle TrueType fonts
;-

if !d.name eq 'PS' then begin
	device, encap=KEYWORD_SET(encapsulated)	;Set encapsulated PS attribute
endif

erase
y0 = 0.87		;Top line
y1 = 0.03		;Bottom
x0 = 0.03		;Left
x1 = .97		;Right
dx = (x1-x0) / 17

oldpfont = !p.font

if KEYWORD_SET(tt_font) then begin
	sesc = ''
	!P.FONT = 1

	DEVICE, SET_FONT='helvetica', /TT_FONT
	xyouts,0.5,.95,'Font '+name, siz=2.5, alig=0.5, /norm
	for ix=0,16 do begin	;Each column
           x = x0 + ix * dx
  	   y = y0 + 0.01
           xx = x + dx/2
           if ix eq 0 then s = 'Octal' else $   ;Column header
              s = string((ix-1) and 15, format='(O2.2)')
           xyouts, xx, y, s, /NORM, ALIGN=0.5
           plots, [x,x],[y0,y1], /norm
        endfor
	DEVICE, SET_FONT=font, /TT_FONT

	nchars = 224

endif else begin

	sesc = '!'+strtrim(font,2)	; Font selecting string
	!P.FONT = -1

	openr, unit, /GET_LUN, /SWAP_IF_LITTLE_ENDIAN, $
           filepath('hersh1.chr', subdir=['resource', 'fonts'])

	;Peek into font file
	hdr = lonarr(2,40)
	readu, unit, hdr

	;Determine # of chars in font:
	if hdr[1,font] lt 0 then nchars = 224 else nchars = 96  ;8 or 7 bits?
	FREE_LUN, unit

	;Title line:
	xyouts,0.5,.95,'!3Font '+strtrim(font,2)+', '+name,siz=2.5,$
	   alig=0.5,/norm

	for ix=0,16 do begin	;Each column
	   x = x0 + ix * dx
	   y = y0 + 0.01
	   xx = x + dx/2
	   if ix eq 0 then s = '!3Octal' else $   ;Column header
	      s = string((ix-1) and 15, format='(O2.2)')
	   xyouts, xx, y, s, /NORM, ALIGN=0.5
	   plots, [x,x],[y0,y1], /norm
	endfor
endelse

nrows = nchars / 16
dy = (y1-y0) / nrows

plots, [x1, x1], [y0, y1], /NORM 
plots, [x0, x1], [y0, y0], /NORM

for iy=0, nrows-1 do begin
	y = y0 + (iy+1) * dy
	plots, [x0, x1], [y, y], /NORM
	xyouts, x0+dx/2, y-dy/5, /NORM, ALIGN=0.5, $
		"!3"+string((iy*16+32)/8, format="(O2.2,'!3x!X')")+"!X"
	for ix=0,15 do begin		;Each character
	    X = (ix+1) * dx + x0
	    k = iy*16 + ix + 32
	    s = string(byte(k))
	    if s eq '!' then s = '!!'
	    xyouts,x+.0225,y+.01,sesc+s,size=2.0,/norm
	endfor
ENDFOR
!p.font = oldpfont
RETURN
END
