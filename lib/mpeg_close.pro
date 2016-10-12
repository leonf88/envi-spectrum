; $Id: //depot/idl/releases/IDL_80/idldir/lib/mpeg_close.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	MPEG_CLOSE
;
; PURPOSE:
;       Frees all information associated with the given MPEG sequence.
;       The given MPEG identifier will no longer be valid after this call.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       MPEG_CLOSE, mpegID
;
; INPUTS:
;       mpegID: The unique identifier of the MPEG sequence (as returned
;               from MPEG_OPEN) to be stored.
;
; EXAMPLE:
;       MPEG_CLOSE, mpegID
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, December, 1997
;-

pro MPEG_CLOSE, mpegID

    if (not OBJ_ISA(mpegID, 'IDLgrMPEG')) then $
      MESSAGE,'Argument must be an IDLgrMPEG object reference.'

    OBJ_DESTROY, mpegID

end
