; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_pict.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


FUNCTION QUERY_PICT, FILE, INFO, IMAGE_INDEX=I
;
;+
; NAME:
;   QUERY_PICT
;
; PURPOSE:
;   Read the header of a PICT format image file and return a structure
;   containing information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_PICT(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the PICT file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_PICT this keyword is ignored.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the query was successful (and the
;   file type was correct) or 0 on failure.  The return status will indicate
;   failure for files that contain formats that are not supported by the
;   corresponding READ_ routine, even though the file may be valid outside
;   the IDL environment.
;
;   Info:   An anonymous structure containing information about the image.
;       This structure is valid only when the return value of the function
;       is 1.  The Info structure for all query routines has the following
;       fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;           CHANNELS    Long            Number of samples per pixel
;           DIMENSIONS  2-D long array  Size of the image in pixels
;           HAS_PALETTE Integer         True if a palette is present
;           NUM_IMAGES  Long            Number of images in the file
;           IMAGE_INDEX Long            Image number for this struct
;           PIXEL_TYPE  Integer         IDL basic type code for a pixel sample
;           TYPE        String          String identifying the file format
;
; COMMON BLOCKS:
;   write_pict_rev
;
; EXAMPLE:
;   To retrieve information from the PICT image file named "foo.pict"
;   in the current directory, enter:
;
;       result = QUERY_PICT("foo.pict", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'PICT file not found or file is not a valid PICT format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written June 1998, ACY
;   CT, RSI, Aug 2003: Fix bug in error code if unable to open file.
;
;-
;

compile_opt hidden

common write_pict_rev, rev

; Set up error handling
CATCH, errorStatus
if errorStatus ne 0 then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if N_ELEMENTS(unit) GT 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0L
endif

i  = BYTE(1,0,2)        ;Test byte ordering of this machine
rev = i[0] eq 1b        ;TRUE to reverse for little endian

hdr = BYTARR(512)
imagesize = 0
rect = {rect, top:0, left:0, bottom:0, right:0}

OPENR, unit, file, /GET_LUN
READU, unit, hdr
read_pict_item, unit, imagesize
read_pict_item, unit, rect

opcode = 0
read_pict_item, unit, opcode

if opcode eq 17 then begin                  ;version number (---Version Opcode)
   versionnumber = 0b
   lowbyte = 0b
   READU, unit, versionnumber
   if versionnumber ne 2B then begin
      FREE_LUN, unit
      RETURN, 0L
   endif
   READU, unit, lowbyte
endif else begin
   FREE_LUN, unit
   RETURN, 0L
endelse

read_pict_item, unit, opcode
if opcode eq 3072 then begin                    ;header (---HeaderOp Opcode)
   headerdata = BYTARR(24)
   READU, unit, headerdata
   if headerdata[0] ne 255B or headerdata[4] ne 0B then begin
      FREE_LUN, unit
      RETURN, 0L
   endif
endif else begin
   FREE_LUN, unit
   RETURN, 0L
endelse

read_pict_item, unit, opcode
if opcode ne 30 then begin           ;default highlight (---DefHilite Opcode)
   FREE_LUN, unit
   RETURN, 0L
endif

read_pict_item, unit, opcode
if opcode eq 1 then begin                   ;clip (---Clip Opcode)
   regionsize = 0
   read_pict_item, unit, regionsize
   if regionsize ne 10 then begin
      ;Non rectangular regions not supported
      FREE_lun, unit
      RETURN, 0L
   endif else begin
      clipregion = rect
      read_pict_item, unit, clipregion
   endelse
endif else begin
   FREE_LUN, unit
   RETURN, 0L
endelse

; simply test for this opcode, but don't read the data associated with
; the opcode.  by this time we can be fairly certain that this is an
; IDL PICT file which can be read by READ_PICT.
read_pict_item, unit, opcode
if opcode ne 152 then begin                 ;(---PackBitsRect Opcode)
   FREE_LUN, unit
   RETURN, 0L
endif

FREE_LUN, unit

; Define the info structure after error returns so that
; info argument stays undefined in error cases.
info = {CHANNELS:       0L, $
        DIMENSIONS:     [0L,0], $
        HAS_PALETTE:    0, $
        NUM_IMAGES:     0L, $
        IMAGE_INDEX:    0L, $
        PIXEL_TYPE:     0, $
        TYPE:           '' $
        }

;   Fill in the info structure
info.CHANNELS =     1       ; IDL PICT files are always 8-bit
info.DIMENSIONS =   [rect.right - rect.left, rect.bottom - rect.top]
info.HAS_PALETTE =  1       ; IDL PICT files always have palettes
info.NUM_IMAGES =   1
info.IMAGE_INDEX =  0
info.PIXEL_TYPE =   1       ; byte data
info.TYPE=          'PICT'

RETURN, 1L  ; success

end
