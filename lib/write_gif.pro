; $Id: //depot/idl/releases/IDL_80/idldir/lib/write_gif.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;	WRITE_GIF
;
; PURPOSE:
;	Write an IDL image and color table vectors to a
;	GIF (graphics interchange format) file.
;
; CATEGORY:
;
; CALLING SEQUENCE:
;
;	WRITE_GIF, File, Image[, R, G, B]
;
; INPUTS:
;	Image: The 2D array to be output.
;
; OPTIONAL INPUT PARAMETERS:
;   R, G, B: The Red, Green, and Blue color vectors to be written
;       with Image. If MULTIPLE is set then the first call to WRITE_GIF
;       will write the R, G, B into the global color map. On subsequent
;       calls, if R, G, B are present then they will be written into
;       the local color map for the current image.
;
; Keyword Inputs:
;    BACKGROUND_COLOR = Set this keyword to a byte value giving the index
;        within the global color table to be designated as the background.
;        The default value is 0.
;
;    CLOSE = if set, closes any open file if the MULTIPLE images
;        per file mode was used.  If this keyword is present,
;        nothing is written, and all other parameters are ignored.
;
;    DELAY_TIME = for multiple images, set this keyword to an integer
;        giving the delay in hundredths (1/100) of a second after
;        the decoder displays the current image.
;        This keyword may be set to a different value for each image
;        within the file.
;
;    DISPOSAL_METHOD = for multiple images, set this keyword to an integer
;        giving the method that the decoder should use for disposing
;        the current image after display.
;        Possible values are:
;        0: No disposal specified. The decoder is not required
;           to take any action.
;        1: Do not dispose. The graphic is to be left in place.
;        2: Restore to background color. The area used by the
;           graphic must be restored to the background color.
;        3: Restore to previous. The decoder is required to
;           restore the area overwritten by the graphic with
;            what was there prior to rendering the graphic.
;        4-7: Not currently defined by the Gif89a spec.
;        This keyword may be set to a different value for each image
;        within the file.
;
;    MULTIPLE = if set, write files containing multiple images per
;        file.  Each call to WRITE_GIF writes the next image,
;        with the file remaining open between calls.  The File
;        parameter is ignored, but must be supplied,
;        after the first call.
;        All images written to a file must be the same size.
;
;    REPEAT_COUNT = for multiple images, set this keyword to an integer
;        giving the number of times that the decoder should repeat the
;        animation. Set this keyword to zero to repeat an infinite number
;        of times. This keyword is written using the Netscape application
;        extension and may not be recognized by some decoders.
;
;    TRANSPARENT = Set this keyword to a byte value giving the index
;        within the color table to be designated as the transparent color.
;        If this keyword is not present or is set to -1
;        (from READ_GIF for example) then no transparent index is written.
;        This keyword may be set to a different value for each image
;        within the file.
;
;    USER_INPUT = Set this keyword to a flag indicating whether the decoder
;        should require user input before continuing processing.
;        The nature of the user input is determined by the application
;        (Carriage Return, Mouse Button Click, etc.).
;        When DELAY_TIME is used and USER_INPUT is set, the decoder
;        should continue processing when user input is received or
;        when the delay time expires, whichever occurs first.
;        This keyword may be set to a different value for each image
;        within the file.
;
; OUTPUTS:
;	If R, G, B values are not provided, the last color table
;	established using LOADCT is saved. The table is padded to
;	256 entries. If LOADCT has never been called, we call it with
;	the gray scale entry.
;
;
; COMMON BLOCKS:
;	COLORS
;
; SIDE EFFECTS:
;	If R, G, and B aren't supplied and LOADCT hasn't been called yet,
;	this routine uses LOADCT to load the B/W tables.
;
; COMMON BLOCKS:
;	WRITE_GIF_COMMON.
;
; RESTRICTIONS:
;	This routine only writes 8-bit deep GIF files of the standard
;	type: (non-interlaced, global colormap, 1 image, no local colormap)
;
;	The Graphics Interchange Format(c) is the Copyright property
;	of CompuServ Incorporated.  GIF(sm) is a Service Mark property of
;	CompuServ Incorporated.
;
; MODIFICATION HISTORY:
;	Written 9 June 1992, JWG.
;	Added MULTIPLE and CLOSE, Aug, 1996.
;   May 2006, CT: Added BACKGROUND_COLOR, DELAY_TIME, DISPOSAL_METHOD,
;       REPEAT_COUNT, TRANSPARENT, USER_INPUT keywords.
;       Added support for local colormaps.
;-
;
pro write_gif, file, img, r, g, b, $
    BACKGROUND_COLOR=backgroundColorIn, $
    CLOSE=close, $
    DELAY_TIME=delayTimeIn, $
    DISPOSAL_METHOD=disposalMethodIn, $
    MULTIPLE=mult, $
    REPEAT_COUNT=repeatCount, $
    TRANSPARENT=transparentIn, $
    USER_INPUT=userInputIn

COMMON WRITE_GIF_COMMON, unit, width, height, position, globalColorMap
COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

; Check the arguments
ON_ERROR, 2			;Return to caller if error
n_params = N_PARAMS();

;; Fix case where passing through undefined r,g,b variables
;; SJL - 2/99
if ((n_params eq 5) && (N_ELEMENTS(r) eq 0)) then n_params = 2

; let user know about demo mode limitation.
; encode_gif is disabled in demo mode
if (LMGR(/DEMO)) then begin
    MESSAGE, 'Feature disabled for demo mode.'
    return
endif

if n_elements(unit) le 0 then unit = -1

if KEYWORD_SET(close) then begin
  if unit ge 0 then FREE_LUN, unit
  unit = -1
  return
endif

IF ((n_params NE 2) && (n_params NE 5))THEN $
  message, "usage: WRITE_GIF, file, image, [r, g, b]'

; Is the image a 2-D array of bytes?

img_size	= SIZE(img)
IF img_size[0] NE 2 || img_size[3] NE 1 THEN	$
	message, 'Image must be a byte matrix.'


; If any color vectors are supplied, do they have right attributes ?
  IF (n_params EQ 2) THEN BEGIN
	IF (n_elements(r_curr) EQ 0) THEN LOADCT, 0, /SILENT ; Load B/W tables
	r	= r_curr
	g	= g_curr
	b	= b_curr
  ENDIF

  r_size = SIZE(r)
  g_size = SIZE(g)
  b_size = SIZE(b)
  IF ((r_size[0] + g_size[0] + b_size[0]) NE 3) THEN $
	message, "R, G, & B must all be 1D vectors."
  IF ((r_size[1] NE g_size[1]) || (r_size[1] NE b_size[1]) ) THEN $
	message, "R, G, & B must all have the same length."

  ;	Pad color arrays

  clrmap = BYTARR(3,256)

  tbl_size		= r_size[1]-1
  clrmap[0,0:tbl_size]	= r
  clrmap[0,tbl_size:*]	= r[tbl_size]
  clrmap[1,0:tbl_size]	= g
  clrmap[1,tbl_size:*]	= g[tbl_size]
  clrmap[2,0:tbl_size]	= b
  clrmap[2,tbl_size:*]	= b[tbl_size]

hasLocalColormap = 0b

if keyword_set(mult) && unit ge 0 then begin
  if width ne img_size[1] || height ne img_size[2] then $
	message,'Image size incompatible'
  point_lun, unit, position-1	;Back up before terminator mark
  hasLocalColormap = (n_params eq 5) && ~Array_Equal(clrmap, globalColorMap)
endif else begin		;First call
  width = img_size[1]
  height = img_size[2]
  globalColorMap = clrmap

    backgroundColor = (N_Elements(backgroundColorIn) gt 0) ? $
        Long(backgroundColorIn[0]) : 0


  ; Write the result
  ; MACTYPE find me
  if (!version.os EQ 'MacOS') then begin
  OPENW, unit, file, /STREAM, /GET_LUN, MACTYPE = "GIFf"
  endif else begin
  OPENW, unit, file, /STREAM, /GET_LUN
  endelse

  hdr	=  { giffile, $		;Make the header
      magic:'GIF89a', 		$
      width_lo:Byte(width and 255), $
      width_hi:Byte(width / 256),	$
      height_lo:Byte(height and 255), $
      height_hi:Byte(height / 256),	$
      global_info: BYTE('F7'X),	$	; global map, 8 bits color
      background:Byte(backgroundColor), $
      reserved:0b }		; 8 bits/pixel

  WRITEU, unit, hdr				;Write header
  WRITEU, unit, clrmap				;Write color map

    if (N_Elements(repeatCount) gt 0) then begin
        appExt = {imagic1: BYTE('21'X), $  ; extension introducer
            imagic2: BYTE('FF'X), $   ; Application Extension
            blockSize: 11b, $
            name: Byte('NETSCAPE'), $
            code: Byte('2.0'), $
            length: 3b, $
            flag: 1b, $
            repeatCountLo: Byte(LONG(repeatCount[0]) AND 255), $
            repeatCountHi: Byte(LONG(repeatCount[0])/256), $
            terminator: 0b}
        WRITEU, unit, appExt
    endif

endelse				;Not Multiple


writeGCE = 0b   ; Graphic Control Extension

delayTime = (N_Elements(delayTimeIn) gt 0) ? Long(delayTimeIn[0]) : 0
if (delayTime lt 0 || delayTime gt 65535) then $
    MESSAGE, 'Illegal value for keyword DELAY_TIME.'
if (delayTime ne 0) then writeGCE = 1b

transparent = (N_Elements(transparentIn) gt 0) ? Long(transparentIn[0]) : -1
; Ignore values of TRANSPARENT=-1 which might have come from READ_GIF.
hasTransparent = transparent ne -1
transparent = 0 > transparent < 255  ; be sure to clip to byte range
if (hasTransparent) then writeGCE = 1b

disposalMethod = (N_Elements(disposalMethodIn) gt 0) ? $
    Long(disposalMethodIn[0]) : 0
disposalMethod = 0 > disposalMethod < 7  ; be sure to clip to correct range
if (disposalMethod gt 0) then writeGCE = 1b

userInput = (N_Elements(userInputIn) gt 0) ? Keyword_Set(userInputIn) : 0
if (userInput) then writeGCE = 1b

if (writeGCE) then begin
    flags = hasTransparent + IShft(userInput,1) + IShft(disposalMethod,2)
    gce = {imagic1: BYTE('21'X), $  ; extension introducer
        imagic2: BYTE('F9'X), $   ; Graphic Control Extension
        blockSize: 4b, $
        flags: Byte(flags), $
        delayTimeLo: Byte(delayTime and 255), $
        delayTimeHi: Byte(delayTime/256), $
        transparent: Byte(transparent), $
        terminator: 0b $
    }
    WRITEU, unit, gce
endif

ihdr	= { 	imagic: BYTE('2C'X),		$	; BYTE(',')
	left:0, top: 0,			$
	width_lo:0b, width_hi:0b,	$
	height_lo:0b, height_hi:0b,	$
	image_info:hasLocalColormap ? Byte('87'x) : 0b}
ihdr.width_lo	= width AND 255
ihdr.width_hi	= width / 256
ihdr.height_lo	= height AND 255
ihdr.height_hi	= height / 256
WRITEU, unit, ihdr

if (hasLocalColormap) then begin
    WRITEU, unit, clrmap
endif

ENCODE_GIF, unit, img

if keyword_set(mult) then begin ;Multiple image mode?
  POINT_LUN, -unit, position	;Get the position
endif else begin		;Single image/file
  FREE_LUN, unit		; Close file and free unit
  unit = -1
endelse
END
