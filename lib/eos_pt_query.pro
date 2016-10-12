; $Id: //depot/idl/releases/IDL_80/idldir/lib/eos_pt_query.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; NAME:
;   EOS_PT_QUERY
;
; PURPOSE:
;   Read the point header of an HDF file and report on the EOS point
;   extensions.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   Result = EOS_PT_QUERY(Filename, PointName [, Info])
;
; INPUTS:
;	Filename:  The filename of the HDF-EOS file.
;
;   PointName:   The EOS Point Name.
;
; Keyword Inputs:
;   None.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the file contains point extentions,
;	0 otherwise.
;
;   Info: (optional)  An anonymous structure containing information about
;		the file.  This structure is valid only when the return value of
;       the function is 1.  The Info structure has the following fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;           ATTRIBUTES	String Array	Array of attribute names
;			NUM_ATTRIBUTES	Long		Number of attributes
;			NUM_LEVELS	Long			Number of levels
;
; RESTRICTIONS:
;   None.
;
; EXAMPLE:
;   To retrieve information from the HDF-EOS point name myPoint enter:
;
;       result = EOS_PT_QUERY("foo.hdf", 'myPoint', info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'HDF file not found or file does not contain EOS PT extensions.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written December 1998, Scott J. Lasica
;
;-
;

function EOS_PT_QUERY, Filename, PointName, info

	;; Swallow all errors since we return status
	CATCH, errorStatus
	if errorStatus ne 0 then begin
    	RETURN, 0L
	endif

	;; First verify that the file contains points
	status = EOS_QUERY(Filename, info_general)
	if ((status eq 0) or (info_general.num_points eq 0)) then return, 0L

	;; Now open it up and try to find the given point ID
	file_id=EOS_PT_OPEN(filename,/read)

	if (file_id ne -1) then begin
		point_id=EOS_PT_ATTACH(file_id,PointName)
		num_levels=EOS_PT_NLEVELS(point_id)
		num_attributes = EOS_PT_INQATTRS(point_id, attributes)
		status=EOS_PT_DETACH(point_id)
 		status=EOS_PT_close(file_id)
	endif else return, 0L

	info = {ATTRIBUTES: attributes, $
			NUM_ATTRIBUTES: num_attributes, $
			NUM_LEVELS: num_levels $
			}

	return, 1L  ;success

end
