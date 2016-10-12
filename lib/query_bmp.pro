; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_bmp.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

FUNCTION QUERY_BMP, FILE, INFO, IMAGE_INDEX=I
;
;+
; NAME:
;   QUERY_BMP
;
; PURPOSE:
;   Read the header of a BMP format image file and return a structure
;   containing information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_BMP(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the BMP file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_BMP this keyword is ignored.
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
;   To retrieve information from the BMP image file named "foo.bmp"
;   in the current directory, enter:
;
;       result = QUERY_BMP("foo.bmp", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'BMP file not found or file is not a valid BMP format.'
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
if errorStatus ne 0 then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if N_ELEMENTS(unit) GT 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0L
endif

; Define the BMP headers

fhdr = { BITMAPFILEHEADER, $
    bftype: bytarr(2), $        ;A two char string
    bfsize: 0L, $
    bfreserved1: 0, $
    bfreserved2: 0, $
    bfoffbits: 0L $
  }

OPENR, unit, file, /GET_LUN, /BLOCK

READU, unit, fhdr           ;Read the bitmapfileheader

; File is not in bitmap file format
if STRING(fhdr.bftype) ne "BM" then begin
    FREE_LUN, unit
    RETURN, 0L
endif

ihdr = { BITMAPINFOHEADER, $
    bisize: 0L, $
    biwidth: 0L, $
    biheight: 0L, $
    biplanes: 0, $
    bibitcount: 0, $
    bicompression: 0L, $
    bisizeimage: 0L, $
    bixpelspermeter: 0L, $
    biypelspermeter: 0L, $
    biclrused: 0L, $
    biclrimportant: 0L $
  }

READU, unit, ihdr

FREE_LUN, unit

big_endian = (BYTE(1,0,2))[0] eq 0b
if big_endian then begin        ;Big endian machine?
    fhdr = SWAP_ENDIAN(fhdr)        ;Yes, swap it
    ihdr = SWAP_ENDIAN(ihdr)
endif

; Can't handle monochrome images
if ihdr.bibitcount eq 1 then RETURN, 0L

; Can only handle 4,8,16 or 24 bit depth
case ihdr.bibitcount of         ;How many bits/pixel?
4: begin
    channels =     1
    has_palette =  1
    pixel_type =   1       ; byte data
    end

8:  begin
    channels =     1
    has_palette =  1
    pixel_type =   1       ; byte data
    end         ;8 bits/pixel

16: begin           ;16 bits/pixel
    channels =     3
    has_palette =  0
    pixel_type =   2       ; int data
    end         ;16 bits

24: begin                    ;24 bits / pixel....
    channels =     3
    has_palette =  0
    pixel_type =   1       ; byte data
    end         ;24bits
else: begin
    ; IDL cannot not handle bits/pixel other than [4,8,16,24]
    RETURN, 0L
    end
endcase

; Can't handle compressed images
if ihdr.bicompression ne 0 then RETURN, 0L

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
info.DIMENSIONS =   [ihdr.biwidth, ihdr.biheight]
info.HAS_PALETTE =  has_palette
info.NUM_IMAGES =   1
info.IMAGE_INDEX =  0
info.PIXEL_TYPE =   pixel_type
info.TYPE=          'BMP'

RETURN, 1L  ;success

end
