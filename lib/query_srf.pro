; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_srf.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

FUNCTION QUERY_SRF, FILE, INFO, IMAGE_INDEX=I
;
;+
; NAME:
;   QUERY_SRF
;
; PURPOSE:
;   Read the header of a SRF format image file and return a structure
;   containing information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_SRF(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the SRF file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_SRF this keyword is ignored.
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
; EXAMPLE:
;   To retrieve information from the SRF image file named "foo.srf"
;   in the current directory, enter:
;
;       result = QUERY_SRF("foo.srf", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'SRF file not found or file is not a valid SRF format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written June 1998, ACY
;   CT, RSI, Aug 2003: Fix bug in error code if unable to open file.
;
;-
;

compile_opt hidden

; Set up error handling
CATCH, errorStatus
if errorStatus NE 0 then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if N_ELEMENTS(unit) GT 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0L
endif

; Define the Sun Raster File structure
header = {rasterfile, magic:0L, width:0L, height:0L, depth: 0L, $
    length:0L, type:0L, maptype:0L, maplength:0L}

OPENR, unit, file, /GET_LUN, /BLOCK

READU, unit, header

FREE_LUN, unit

; Check the magic number
if (header.magic eq '956aa659'XL) then begin
    BYTEORDER, header, /NTOHL        ;Back to our order
endif

; File is not a SUN rasterfile
if (header.magic ne '59a66a95'X) then RETURN, 0L

; Only know how to do RT_OLD and RT_STANDARD style rasterfiles.
if ((header.type ne 0) and (header.type ne 1)) then RETURN, 0L

; Only know how to handle 1 bit and 8 bit images
case header.depth of
'1' : channels = 1
'8' : channels = 1
'24': channels = 3
'32': channels = 3
else: begin
         ; Unsupported depth
         FREE_lun, unit
         RETURN, 0L
       end
endcase

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
info.CHANNELS =     channels
info.DIMENSIONS =   [header.width, header.height]
info.HAS_PALETTE =  ( (header.maptype eq 1) and (header.maplength ne 0) )
info.NUM_IMAGES =   1
info.IMAGE_INDEX =  0
info.PIXEL_TYPE =   1       ; byte data
info.TYPE=          'SRF'

RETURN, 1L  ; success

end


