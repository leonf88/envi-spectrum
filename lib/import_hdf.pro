; $Id: //depot/idl/releases/IDL_80/idldir/lib/import_hdf.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;  		IMPORT_HDF
;
; PURPOSE:
;       This routine is a macro allowing the user to read in an HDF/EOS
;		file and have the contents placed in the current scope as a
;		structure variable.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       IMPORT_HDF
;
; OUTPUTS:
;	This procedure creates a structure variable and places it in the current
;	scope.  The variable is named 'filename_df' where filename is the main
;	part of the file's name not using the extension.
;
; EXAMPLE:
;       IMPORT_HDF
;
; MODIFICATION HISTORY:
; 	Written by:	Scott Lasica, July, 1999
;   Modified: CT, RSI, July 2000: moved varName out to IMPORT_CREATE_VARNAME
;-
;

PRO IMPORT_HDF

	COMPILE_OPT hidden, strictarr

	FORWARD_FUNCTION IS_HDF
    index=WHERE(ROUTINE_INFO(/UNRESOLVED,/FUNCTIONS) eq 'HDF_MAP',count)
    if (count eq 0) then RESOLVE_ROUTINE,'HDF_MAP',/is_function
    notHDF = ' is not a valid HDF, NETCDF or HDF-EOS file.'

	catch,error_status
	if (error_status ne 0) then begin
		;; This is because the only way to tell if you have a NetCDF file is to
		;; try and start the SD interface.  That throws the following error, which
		;; I want to swallow up.  After all, at this point IS_HDF has already checked
		;; if the file is HDF or HDF-EOS, so NetCDF is the last check.
		cannotStart = STRPOS(!ERROR_STATE.msg,'Unable to start the HDF-SD')
		mess = (cannotStart GE 0) ? ['"'+filename+'"',notHDF] : !ERROR_STATE.msg
		a=dialog_message(mess, /ERROR, $
			TITLE='Import_Hdf Error')
		return
	endif

	filename=DIALOG_PICKFILE(TITLE='Select a valid HDF, NETCDF or HDF-EOS file',/READ,$
		FILTER='*.*',/MUST_EXIST, GET_PATH=gp)
	if (filename eq '') then return

	file_ok=IS_HDF(filename,valid_hdf,valid_sds,valid_eos)

	if (not file_ok) then MESSAGE, 'Unable to start the HDF-SD'

	tempStr = HDF_READ(filename)

	;; Store the return variable into a var for the user
	varName = IMPORT_CREATE_VARNAME(filename, gp, '_df')
	(SCOPE_VARFETCH(varName, /ENTER, LEVEL=-1)) = TEMPORARY(tempStr)

END