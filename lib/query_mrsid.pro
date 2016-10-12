; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_mrsid.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.


FUNCTION QUERY_MRSID, FILE, info, LEVEL = iLevelin
;
;+
; NAME:
;   QUERY_MRSID
;
; PURPOSE:
;   Create an IDLffMrSID object and query it for info. Return a structure
;   containing this information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_MRSID(File, Info [,LEVEL=lvl])
;
; INPUTS:
;   File:   Scalar string giving the name of the MrSID file to query.
;
; Keyword Inputs:
;   LEVEL:    Set this keyword to an integer that specifies the level to
;      which the DIMENSIONS field of the info structure corresponds.
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
;      LEVELS   2-D long array  Min and Max levels supported by this image
;      GEO_VALID   Long       Set to 1 if MrSID image contains valid
;                         Georeferencing data
;      GEO_PROJTYPE UINT      Projected Coordinate System type
;      GEO_ORIGIN  2-D double array Location of centre of upper-left pixel
;      GEO_RESOLUTION 2-D double array Pixel resolution
;
; EXAMPLE:
;   To retrieve information from the MrSID image file named "foo.sid"
;   in the current directory, enter:
;
;       result = QUERY_MRSID("foo.sid", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'MrSID file not found or file is not a valid MrSID format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written May 2001, SAH
;
;-
;

compile_opt hidden

; There is very little error handling in this function as the IDLffMrSID object takes care of
; this, e.g. checking param/keyword types and values.
; If there is a problem we catch it, report it and return.

on_error, 2 ; return on error

if n_params() eq 0 then Message, "Incorrect number of arguments."
if n_elements(file) ne 1 then Message, "Filename must be a scalar or one element array."

; Set up CATCH routine to destroy the MrSID object
; if we don't reach the end of the function.
CATCH, errorStatus
if errorStatus ne 0 then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if (OBJ_VALID(oMrSID)) then OBJ_DESTROY, oMrSID
    return, 0L
endif

oMrSID = OBJ_NEW('IDLffMrSID', file[0], /QUIET)

if (OBJ_VALID(oMrSID) eq 0) then return, 0L

iLevel = (N_ELEMENTS(iLevelin) GT 0) ? iLevelin:0

; Define the info structure after error returns so that
; info argument stays undefined in error cases.
info = {CHANNELS:       0L, $
        DIMENSIONS:     [0L,0], $
        HAS_PALETTE:    0, $
        NUM_IMAGES:     0L, $
        IMAGE_INDEX:    0L, $
        PIXEL_TYPE:     0, $
        TYPE:           '', $
        LEVELS:        [0L,0], $
        GEO_VALID:   0L, $
        GEO_PROJTYPE:   0U, $
        GEO_ORIGIN:     [0D,0], $
        GEO_RESOLUTION: [0D,0] $
        }

oMrSID->GetProperty, CHANNELS=nChan,      $
               LEVELS=lvls,         $
               PIXEL_TYPE=pixelType, $
               TYPE=type,          $
               GEO_VALID=geoValid,   $
               GEO_PROJTYPE=geoProj,  $
               GEO_ORIGIN=geoOrigin,     $
               GEO_RESOLUTION=geoRes

dims = oMrSID->GetDimsAtLevel(iLevel)

info.CHANNELS = nChan
info.DIMENSIONS = dims
info.NUM_IMAGES = 1
info.PIXEL_TYPE = pixelType
info.TYPE = type
info.LEVELS = lvls
info.GEO_VALID = geoValid

; If the georeference data isn't valid (possibly a format
; unsupported by this version of the MrSID dlm) then reset the
; projection type, origin and res.
if (geoValid eq 0) then begin
    geoOrigin = [0,0]
    geoRes = [0,0]
    geoProj = 0
endif

info.GEO_PROJTYPE = geoProj
info.GEO_ORIGIN = geoOrigin
info.GEO_RESOLUTION = geoRes

OBJ_DESTROY, oMrSID

RETURN, 1L  ; success

end
