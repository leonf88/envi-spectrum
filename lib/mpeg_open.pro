; $Id: //depot/idl/releases/IDL_80/idldir/lib/mpeg_open.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MPEG_OPEN
;
; PURPOSE:
;       This function initializes MPEG encoding.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = MPEG_OPEN(Dimensions)
;
; INPUTS:
;       Dimensions: A vector of the form [xsize,ysize] indicating the
;                   dimensions of each of the images to be used as
;                   frames for the MPEG file.
;
; KEYWORD PARAMETERS:
;       FILENAME: Set this keyword to a string representing the name of
;                 the file to which the encoded MPEG sequence is to be
;                 saved.  The default is 'idl.mpg'.
;
; OUTPUTS:
;       Result: The ID of the underlying MPEG object.
;
; EXAMPLE:
;       mpegID = MPEG_OPEN([100,100])
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, December, 1997
;-

function MPEG_OPEN, dimensions, FILENAME=filename, $
	QUALITY=quality, BITRATE=bitrate, IFRAME_GAP=iframe_gap, $
	MOTION_VEC_LENGTH=motion_vec_length

    ON_ERROR,2                    ;Return to caller if an error occurs

    if (N_ELEMENTS(dimensions) eq 0) then $
      MESSAGE,'Usage: Result = MPEG_OPEN(Dimensions)'
    if (SIZE(dimensions,/N_DIMENSIONS) ne 1) then $
      MESSAGE,'Argument must be a 2 element, 1D array.'
    if (N_ELEMENTS(dimensions) ne 2) then $
      MESSAGE,'Argument must be a 2 element, 1D array.'

    ; let user know about demo mode limitation.
    ; mpeg object is disabled in demo mode
    if (LMGR(/DEMO)) then begin
        MESSAGE, 'Feature disabled for demo mode.'
        return, OBJ_NEW()
    endif

    mpegID=OBJ_NEW('IDLgrMPEG', DIMENSIONS=dimensions, FILENAME=filename, $
		QUALITY=quality, BITRATE=bitrate, IFRAME_GAP=iframe_gap, $
		MOTION_VEC_LENGTH=motion_vec_length)
    return, mpegID
end
