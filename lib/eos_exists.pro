; $Id: //depot/idl/releases/IDL_80/idldir/lib/eos_exists.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	EOS_EXISTS
;
; PURPOSE:
;	Test for the existence of the HDF EOS library
;
; CATEGORY:
;	File Formats
;
; CALLING SEQUENCE:
;	Result = EOS_EXISTS()
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	Returns TRUE (1) if the HDF EOS data format library is
;	supported. Returns FALSE(0) if it is not.
;
; EXAMPLE:
;	IF eos_exists() EQ 0 THEN Fail,"HDF not supported on this machine"
;
; MODIFICATION HISTORY
;	Written by:	Scott Lasica,  10/30/98
;-

FUNCTION eos_exists

	catch, no_eos_lib
	if (no_eos_lib ne 0) then begin
		return, 0
	endif
	a = EOS_PT_OPEN('exist_test',/READ)
	return, 1
END
