;$Id: //depot/idl/releases/IDL_80/idldir/lib/read_spr.pro#1 $
;
; Copyright (c) 1994-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       READ_SPR
;
; PURPOSE:
;       This function reads a row-indexed sparse matrix from a specified
;	file and returns it as the result.    Row-indexed sparse matrices
;	are created by using the Numerical Recipes routine SPRSIN.
;
; CATEGORY:
;      	Sparse Matrix File I/O
;
; CALLING SEQUENCE:
;       result = READ_SPR('Filename')
;
; INPUTS:
;	Filename:  Name of file containing a row-indexed sparse matrix
;
; KEYWORD PARAMETERS;
;	NONE
;
; OUTPUTS:
;	result:  Row-indexed sparse matrix
;
;
; MODIFICATION HISTORY:
;       Written by:     BMH, 1/94.
;-

FUNCTION  READ_SPR, filename

COMPILE_OPT idl2, hidden

; result format = {sa:FLTARR(nmax) or sa:DBLARR(nmax), ija:LONARR(nmax)}
;
nmax = 0L
type = 0L

ON_IOERROR, BADFILE


OPENR, fileLUN, filename, /GET_LUN

;Read type and size information
READU, fileLUN, nmax, type

;Define resulting structure based on the data size and type
IF (type EQ 4) THEN $ ; Value array is single precision
  result = {sa:FLTARR(nmax, /NOZERO),ija:LONARR(nmax, /NOZERO)} $
else  $               ; Value array is double precision
  result = {sa:DBLARR(nmax, /NOZERO),ija:LONARR(nmax, /NOZERO)}

;Read sparse matrix
READU, fileLUN, result

FREE_LUN, fileLUN

RETURN, result


BADFILE:
IF (N_Elements(fileLUN) GT 0L) THEN $
   FREE_LUN, fileLUN
MESSAGE, 'Error reading sparse matrix file: ' + filename

END



