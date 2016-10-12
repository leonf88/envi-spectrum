; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_jpeg2000.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-----------------------------------------------------------------------
;
;+
; NAME:
;   QUERY_JPEG2000
;
; PURPOSE:
;   Query a JPEG2000 file. Return a structure
;   containing the information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_JPEG2000(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_JPEG2000 this keyword is ignored.
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
;           N_LAYERS    Integer         Number of quality layers
;           N_LEVELS    Integer         Wavelet decomposition levels.
;           OFFSET      2-element vec   X and Y offsets of image components
;
; EXAMPLE:
;   See READ_JPEG2000.
;
; MODIFICATION HISTORY:
;   Written: CT, RSI, Feb 2004
;
;-
;
function query_jpeg2000, file, info, $
    IMAGE_INDEX=swallow

    compile_opt idl2, hidden

    ON_ERROR, 2 ; return on error

    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'
    if (SIZE(file, /TYPE) ne 7) then $
        MESSAGE, 'File must be a string.'

    ; Set up CATCH routine to destroy the object if an error occurs.
    CATCH, errorStatus
    if errorStatus ne 0 then begin
        CATCH, /CANCEL
        MESSAGE, /RESET
        if (OBJ_VALID(oJPEG2000)) then $
            OBJ_DESTROY, oJPEG2000
        return, 0L
    endif

    oJPEG2000 = OBJ_NEW('IDLffJPEG2000', file, /QUIET)

    if (~OBJ_VALID(oJPEG2000)) then $
        return, 0L


    oJPEG2000->GetProperty, $
        BIT_DEPTH=bitDepth, $
        DIMENSIONS=dimensions, $
        N_COMPONENTS=nComponents, $
        N_LAYERS=nLayers, $
        N_LEVELS=nLevels, $
        OFFSET=offset, $
        PALETTE=palette, $
        SIGNED=signed

    OBJ_DESTROY, oJPEG2000

    bitDepth = MAX(bitDepth)
    signed = MAX(signed)

    pixelType = 1  ; default is type byte
    if (bitDepth gt 8) then begin
        ; Long/uLong or Short/uShort
        pixelType = (bitDepth gt 16) ? $
            (signed ? 3 : 13) : (signed ? 2 : 12)
    endif

    ; Only return 64-bit integers if necessary.
    if (MAX(dimensions) lt 2147483646) then $
        dimensions = LONG(dimensions)
    if (MAX(offset) lt 2147483646) then $
        offset = LONG(offset)

    ; Define the info structure after error returns so that
    ; info argument stays undefined in error cases.
    info = {CHANNELS: LONG(nComponents), $
            DIMENSIONS: dimensions, $
            HAS_PALETTE: (N_ELEMENTS(palette) gt 1), $
            NUM_IMAGES: 1L, $
            IMAGE_INDEX: 0L, $
            PIXEL_TYPE: pixelType, $
            TYPE: 'JPEG2000', $
            N_LAYERS: nLayers, $
            N_LEVELS: nLevels, $
            OFFSET: offset}

    return, 1L  ; success

end
