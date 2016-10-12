; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_ppm.pro#1 $
;
; Copyright (c) 1994-2010. ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;


PRO READ_PPM, FILE, IMAGE, MAXVAL = maxval
;
;+
; NAME:
;	READ_PPM
;
; PURPOSE:
;	Read the contents of a PGM (gray scale) or PPM (portable pixmap
;	for color) format image file and return the image in the form
;	of an IDL variable.
;	PPM/PGM format is supported by the PMBPLUS and Netpbm packages.
;
;	PBMPLUS is a toolkit for converting various image formats to and from
;	portable formats, and therefore to and from each other.
;
; CATEGORY:
;	Input/Output.
;
; CALLING SEQUENCE:
;	READ_PPM, File, Image
;
; INPUTS:
;	File:	Scalar string giving the name of the PGM or PPM file.
;
; OUTPUTS:
;	Image:	The 2D byte array to contain the image.  In the case
;		of a PPM file, a [3, n, m] array is returned.
;
; KEYWORD Parameters:
;	MAXVAL = returned maximum pixel value.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	Should adhere to the PGM/PPM "standard".
;	Accepts: P2 = graymap ASCII, P5 graymap RAWBITS, P3 true-color
;	ASCII pixmaps, and P6 true-color RAWBITS pixmaps.
;	Maximum pixel values are limited to 255.
;	Images are always stored with the top row first. (ORDER=1)
;
; EXAMPLE:
;	To open and read the PGM image file named "foo.pgm" in the current
;	directory, store the image in the variable IMAGE1 enter:
;
;		READ_PPM, "foo.pgm", IMAGE1
;
; MODIFICATION HISTORY:
;	Written Nov, 1994, DMS.
;-
;
compile_opt hidden

ON_IOERROR, bad_io
ON_ERROR, 2  ;; Changed from 1 to 2 - matches other read routines - SJL

OPENR, unit, file, /GET_LUN, /STREAM
image = 0
buffer = ''		;Read using strings
magic = READ_PPM_NEXT_TOKEN(unit, buffer)
if strmid(magic,0,1) ne 'P' then begin
Not_pgm: MESSAGE, 'File "'+file+'" is not a PGM/PPM file.'
    return
    endif

type = strmid(magic,1,1)

width = long(READ_PPM_NEXT_TOKEN(unit, buffer))
height = long(READ_PPM_NEXT_TOKEN(unit, buffer))
maxval = long(READ_PPM_NEXT_TOKEN(unit, buffer))
case type of
'2' : BEGIN
	image = bytarr(width, height, /nozero)
	readf, unit, image
      ENDCASE
'3' : BEGIN
	image = bytarr(3, width, height, /nozero)
	readf, unit, image
      ENDCASE
'5' : BEGIN
	image = bytarr(width, height, /nozero)
	readu, unit, image
      ENDCASE
'6' : BEGIN
	image = bytarr(3, width, height, /nozero)
	readu, unit, image
      ENDCASE
else :	goto, Not_pgm
ENDCASE

free_lun, unit
return
BAD_IO: Message, 'Error occured accessing PGM/PPM file:' + file
end

