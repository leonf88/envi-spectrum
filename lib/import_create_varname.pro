; $Id: //depot/idl/releases/IDL_80/idldir/lib/import_create_varname.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;  		IMPORT_CREATE_VARNAME
;
; PURPOSE:
;       This routine takes a string file name and constructs a valid
;       variable name. For use with the IMPORT_ routines.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;
;       IMPORT_CREATE_VARNAME, Name [, Path [, Suffix]]
;
; OUTPUTS:
;	A string with a valid variable name.
;
; ARGUMENTS:
;
;   Name = A string containing the file name, possibly including a file path.
;
;   Path = A string containing the file path to be removed from Name.
;          The default is '' (Null string).
;
;   Suffix = A string containing a suffix to be appended onto the variable
;            name. The default is '' (Null string).
;
; MODIFICATION HISTORY:
; 	Written by:	CT, RSI, July, 2000
;-

FUNCTION import_create_varname, file_nameIn, file_path, suffix

	COMPILE_OPT hidden, strictarr

	ON_ERROR, 2  ; return to caller


; strip off file_path if necessary
	IF (SIZE(file_path,/TNAME) NE 'STRING') THEN file_path = ''
	varName = (file_name = STRMID(file_nameIn, STRLEN(file_path)))


; strip off filetype suffix if necessary
	period = STRPOS(varName, '.', /REVERSE_SEARCH)  ; is there a filetype?
	IF (period GT 0) THEN $   ; strip off
		varName = STRMID(varName, 0, period) $
	ELSE $   ; or, for a "dot" file, strip off the period
		IF (period EQ 0) THEN varName = STRMID(varName, 1)


; remove illegal variable name characters
	; first character must be a A-Z,a-z letter
	firstLetter = STREGEX(varName, '[a-z]+', /FOLD_CASE)
	varName = (firstLetter LT 0) ? 'var'+varName : STRMID(varName, firstLetter)

	IF (STRLEN(varName) GT 0) THEN BEGIN
		varName = STRMID(varName,LINDGEN(STRLEN(varName)),1)   ; split into chars

		; Replace any spaces with underscores
		spaces = WHERE(varName EQ ' ',nspace)
		IF (nspace GT 0) THEN varName[spaces] = '_'

		; Remove illegal characters
		legalChars = '[a-z_$0-9]'
		good = WHERE(STRMATCH(varName, legalChars, /FOLD_CASE), nmatch)
		varName = (nmatch EQ 0) ? '' : STRJOIN(varName[good],/SINGLE)
	ENDIF


; If null name, throw an error...
	IF (STRLEN(varName) EQ 0) THEN MESSAGE, /NONAME, $
		'Unable to construct variable name from file name "' + file_name + '"'


; append the suffix (note that the suffix does not get checked!)
	IF (SIZE(suffix,/TNAME) EQ 'STRING') THEN varName = varName + suffix


	RETURN, varName
END