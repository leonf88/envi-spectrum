; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_mrsid.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

FUNCTION READ_MRSID, File, SUB_RECT=sub_rect, LEVEL=Level

;+
; NAME:
;   READ_MRSID
;
; PURPOSE:
;   This function reads a MrSID image at a specified level and location
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = READ_MRSID(File [,LEVEL=lvl] [,SUB_RECT=rect])
;
; INPUTS:
;   File: The full path name of the MrSID file to read.
;
; OUTPUTS:
;   This function returns an n x w x h array containing the image
;   data where n is 1 for grayscale or 3 for RGB images, w is the
;   width and h is the height.
;
;
; KEYWORDS:
;   LEVEL:    Set this keyword to an integer that specifies the level at
;      which to read the image. If this is not set, the maximum
;      level is used, which returns the minumum resolution.
;
;   SUB_RECT: Set this keyword to a four-element vector [x,y,xdim,ydim]
;      specifying the position of the lower left-hand corner and
;      the dimensions of the sub-rectange of the MrSID image to
;      return.
;
; MODIFICATION HISTORY:
;   SAH, RSI.   May 2001.       Original version.
;-

; There is very little error handling in this function as the IDLffMrSID object takes care of
; this, e.g. checking param/keyword types and values.
; If there is a problem we catch it, report it and return.

compile_opt hidden

on_error, 2 ; return on error


if n_params() eq 0 then Message, "Incorrect number of arguments."

if n_elements(file) ne 1 then Message, "Filename must be a scalar or one element array."

; Set up CATCH routine to destroy the MrSID object
; if we don't reach the end of the function.
CATCH, errorStatus
if errorStatus ne 0 then begin
    CATCH, /CANCEL
    if (OBJ_VALID(oMrSID)) then OBJ_DESTROY, oMrSID
    Message, /Reissue_Last
    return, 0L
endif

oMrSID = OBJ_NEW('IDLffMrSID', file[0])

if (OBJ_VALID(oMrSID) eq 0) then message,'Unable to read MrSID image '+ File

image = oMrSID->GetImageData(SUB_RECT=sub_rect, LEVEL=Level)

OBJ_DESTROY, oMrSID

return, image

END
