; $Id: //depot/idl/releases/IDL_80/idldir/lib/write_ppm.pro#1 $
;
; Copyright (c) 1994-2010. ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

PRO WRITE_PPM, FILE, Image, ASCII = ascii
;+
; NAME:
;	WRITE_PPM
;
; PURPOSE:
;	Write an image to a PPM (true-color) or PGM (gray scale) file.
;	PPM/PGM format is supported by the PMBPLUS and Netpbm packages.
;
;	PBMPLUS is a toolkit for converting various image formats to and from
;	portable formats, and therefore to and from each other.
;
; CATEGORY:
;	Input/Output.
;
; CALLING SEQUENCE:
;
;	WRITE_PPM, File, Image  ;Write a given array.
;
; INPUTS:
;	Image:	The 2D (gray scale) or 3D (true-color) array to be output.
;
; KEYWORD PARAMETERS:
;	ASCII = if set, formatted ASCII IO is used to write the image data.
;		If omitted, or set to zero, the far more efficient
;		binary IO (RAWBITS) format is used to write the image data.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A file is written.
;
; RESTRICTIONS:
;	This routine only writes 8-bit deep PGM/PPM files of the standard
;	type.
;	Images should be ordered so that the first row is the top row.
;	If your image is not, use WRITE_PPM, File, REVERSE(Image, 2)
;
; MODIFICATION HISTORY:
;	Written Nov, 1994, DMS.
;   CT, RSI, August 2000: Change PRINTF to WRITEU,
;            change output to match PPM spec, add "Created by..." comment.
;-
;

COMPILE_OPT idl2
; Check the arguments
ON_ERROR, 2

; Is the image a 2-D array of bytes?
img_size	= SIZE(image)
maxval = max(image, min=minval)
if (NOT keyword_set(ascii)) AND ((minval lt 0) OR (maxval gt 255)) then $
	message, 'For binary I/O, Image values must be in the range 0...255.'
IF img_size[0] eq 2 then begin
    cols = img_size[1]
    rows = img_size[2]
    type = keyword_set(ascii) ? 2 : 5
endif else if img_size[0] eq 3 then begin
    if img_size[1] ne 3 then MESSAGE, 'True-color images must be (3,n,m)'
    cols = img_size[2]
    rows = img_size[3]
    type = keyword_set(ascii) ? 3 : 6
endif else message, 'IMAGE parameter must be dimensioned (n,m) or (3,n,m)'

ch = STRING(10b)
OPENW, unit, file, /GET_LUN, /STREAM
WRITEU, unit, BYTE("P" + STRTRIM(type, 2) + ch)
creation = "# Created by IDL " + !VERSION.release + " " + SYSTIME()
WRITEU, unit, BYTE(creation + ch)
WRITEU, unit, BYTE(STRTRIM(STRCOMPRESS(STRING(cols, rows)),1) + ch)
WRITEU, unit, BYTE(STRTRIM(STRING(maxval,FORMAT='(I)'), 2) + ch)
if keyword_set(ascii) then begin
	WRITEU, unit, STRTRIM(STRCOMPRESS(STRING(image,FORMAT='(17I)')),1) + ch
endif else $
	writeu, unit, byte(image)
FREE_LUN, unit
return

end
