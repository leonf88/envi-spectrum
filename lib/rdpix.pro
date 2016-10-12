; $Id: //depot/idl/releases/IDL_80/idldir/lib/rdpix.pro#1 $
;
; Copyright (c) 1989-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

Pro Rdpix, Image,X0, Y0	;Read the value of the pixel under the cursor
			;Display x,y and the pixel value under the cursor
;+
; NAME:
;	RDPIX
;
; PURPOSE:
;	Interactively display the X position, Y position, and pixel value
;	of the cursor.
;
; CATEGORY:
;	Image display.
;
; CALLING SEQUENCE:
;	RDPIX, Image [, X0, Y0]
;
; INPUTS:
;	Image:	The array that represents the image being displayed.  This
;		array may be of any type.  Rather reading pixel values from
;		the display, they are taken from this parameter, avoiding
;		scaling difficulties.
;
; OPTIONAL INPUT PARAMETERS:
;	X0, Y0:	The location of the lower-left corner of the image area on
;		screen.  If these parameters are not supplied, they are
;		assumed to be zero.
;
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	The X, Y, and value of the pixel under the cursor are continuously
;	displayed.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	Instructions are printed and the pixel values are printed as the
;	cursor is moved over the image.
;
;	Press the left or center mouse button to create a new line of output,
;	saving the previous line.
;
;	Press the right mouse button to exit the procedure.
;
; MODIFICATION HISTORY:
;	DMS, Dec, 1987.
;	Rob Montgomery (rob@hao.ucar.edu), 9/21/92;
;		Correct indices for case of !order = 1
;
;-

COMPILE_OPT strictarr
on_error,2              ;Return to caller if an error occurs
print,'Press left or center mouse button for new output line."
print,'... right mouse button to exit.'
s = size(image)
if s[0] ne 2 then message, 'Image parameter not 2d.'
s[1] = s[1]-1		;To n-1
s[2] = s[2]-1
!mouse.button=0
if n_elements(x0) le 0 then x0 = 0
if n_elements(y0) le 0 then y0 = 0
if s[s[0]+1] ge 4 then form = 'F' else form = 'I'
case !version.os_family of
        'Windows': cr = string("15b)+string("12b)	; carriage and new line
        'MacOS': cr = string("15b)			; carriage return
        'unix': cr = string("15b)			; carriage (for BC on
							; UNIX use CR rather
							; than CR/LF)
        else: cr = string("15b)				; carriage return
endcase
form="($,'x=',i4,', y=',i4,', value=',"+form+",a)"
while !mouse.button ne 4 do begin
	CURSOR,x,y,2,/dev
	if (!mouse.button and 3) ne 0 then begin	;New line?
	   print,form="($,a)",string("12b)
	   while (!mouse.button ne 0) do begin wait,.1 & CURSOR,x,y,0,/dev & end
	  endif

	x = x-x0 & y = y - y0
	if (x le s[1]) and (y le s[2]) and (x ge 0) and (y ge 0) then begin
	   if (!order eq 1) then yy = s[2] - y else yy = y
	   print,form = form, x,y,Image[x,yy],cr
	endif
endwhile
print,form="(/)"
end
