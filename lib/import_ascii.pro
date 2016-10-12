; $Id: //depot/idl/releases/IDL_80/idldir/lib/import_ascii.pro#1 $
;
; Copyright (c) 1999-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;  		IMPORT_ASCII
;
; PURPOSE:
;       This routine is a macro allowing the user to read in an ASCII
;		file and have the contents placed in the current scope as a
;		structure variable.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       IMPORT_ASCII
;
; OUTPUTS:
;	This procedure creates a structure variable and places it in the current
;	scope.  The variable is named 'filename_ascii' where filename is the main
;	part of the file's name not using the extension.
;
; EXAMPLE:
;       IMPORT_ASCII
;
; MODIFICATION HISTORY:
; 	Written by:	Scott Lasica, July, 1999
;   Modified: CT, RSI, July 2000: moved varName out to IMPORT_CREATE_VARNAME
;-
;

PRO IMPORT_ASCII

	COMPILE_OPT hidden, strictarr

	catch,error_status
	if (error_status ne 0) then begin
		dummy = DIALOG_MESSAGE(!ERROR_STATE.msg, /ERROR, $
			TITLE='Import_Ascii Error')
		return
	endif

	filename=DIALOG_PICKFILE(TITLE='Select an ASCII file to read.',/READ,$
		FILTER='*.*',/MUST_EXIST, GET_PATH=gp)
	if (filename eq '') then return

	templ = ASCII_TEMPLATE(filename, CANCEL=cancel)
	if (cancel) then return

	tempStr = READ_ASCII(filename, TEMPLATE=templ)

	;; Store the return variable into a var for the user
	varName = IMPORT_CREATE_VARNAME(filename, gp, '_ascii')
	(SCOPE_VARFETCH(varName, /ENTER, LEVEL=-1)) = TEMPORARY(tempStr)

END