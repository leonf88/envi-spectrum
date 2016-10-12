; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_ppm.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


FUNCTION QUERY_PPM, FILE, INFO, IMAGE_INDEX=I, MAXVAL=maxval
;
;+
; NAME:
;   QUERY_PPM
;
; PURPOSE:
;   Read the header of a PPM format image file and return a structure
;   containing information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_PPM(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the PPM file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_PPM this keyword is ignored.
;
; Keyword Outputs:
;   MAXVAL: Set this keyword to a named variable to retrieve the
;        maximum pixel value in the image.
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
;       In addition, QUERY_PPM has the additional field:
;
;           MAXVAL      Long            The maximum pixel value in the image.
;
; EXAMPLE:
;   To retrieve information from the PPM image file named "foo.ppm"
;   in the current directory, enter:
;
;       result = QUERY_PPM("foo.ppm", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'PPM file not found or file is not a valid PPM format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written June 1998, ACY
;   CT, RSI, July 2000: Make "magic" binary to avoid buffer overflow.
;   CT, RSI, Aug 2003: Fix bug in error code if unable to open file.
;
;-
;

compile_opt hidden

; Set up error handling
CATCH, errorStatus
if errorStatus ne 0 then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if N_ELEMENTS(unit) GT 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0L
endif


OPENR, unit, file, /GET_LUN, /STREAM
; read first 2 chars as binary to avoid exceeding input buffer for
; non-PPM binary files
magic = BYTARR(2)
READU, unit, magic
magic = STRING(magic)

if STRMID(magic,0,1) ne 'P' then begin
   ;File is not a PGM/PPM file.
   FREE_lun, unit
   RETURN, 0L
endif

type = STRMID(magic,1,1)
case type of
'2' : channels = 1
'3' : channels = 3
'5' : channels = 1
'6' : channels = 3
else : begin
         ; Unsupported type or invalid PPM file
         FREE_lun, unit
         RETURN, 0L
       end
endcase

buffer = ''     ;Read using strings
READF, unit, buffer  ; read the rest of the first line
width = LONG(READ_PPM_NEXT_TOKEN(unit, buffer))
height = LONG(READ_PPM_NEXT_TOKEN(unit, buffer))
maxval = LONG(READ_PPM_NEXT_TOKEN(unit, buffer))

FREE_LUN, unit

; Define the info structure after error returns so that
; info argument stays undefined in error cases.
info = {CHANNELS:       0L, $
        DIMENSIONS:     [0L,0], $
        HAS_PALETTE:    0, $
        NUM_IMAGES:     0L, $
        IMAGE_INDEX:    0L, $
        PIXEL_TYPE:     0, $
        TYPE:           '', $
        MAXVAL:         0L $
        }

;   Fill in the info structure
info.CHANNELS =     channels
info.DIMENSIONS =   [width, height]
info.HAS_PALETTE =  0
info.NUM_IMAGES =   1
info.IMAGE_INDEX =  0
info.PIXEL_TYPE =   1       ; byte data
info.TYPE=          'PPM'
info.MAXVAL=        maxval

RETURN, 1L  ; success

end
