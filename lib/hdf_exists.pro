; $Id: //depot/idl/releases/IDL_80/idldir/lib/hdf_exists.pro#1 $
;
; Copyright (c) 1992-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;	HDF_EXISTS
;
; PURPOSE:
;	Test for the existence of the HDF library
;
; CATEGORY:
;	File Formats
;
; CALLING SEQUENCE:
;	Result = HDF_EXISTS()
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	Returns TRUE (1) if the HDF data format library is
;	supported. Returns FALSE(0) if it is not.
;
; EXAMPLE:
;	IF hdf_exists() EQ 0 THEN Fail,"HDF not supported on this machine"
;
; MODIFICATION HISTORY
;	Written by:	Joshua Goldstein,  12/21/92
;	Modified by:    Steve Penton,	   12/27/95
;					Scott Lasica	8/4/99
;-

;
FUNCTION hdf_exists

	catch, no_hdf_lib
	if (no_hdf_lib ne 0) then begin
		return, 0
	endif
	a = HDF_OPEN('exist_test',/READ)
	return, 1
END
