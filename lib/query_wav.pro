; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_wav.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

FUNCTION QUERY_WAV, file, info
;+
; NAME:
;	QUERY_WAV
;
; PURPOSE:
; 	This function queries information from a Microsoft Windows .WAV
;	(RIFF) file
;
; CATEGORY:
;   	Input/Output
;
; CALLING SEQUENCE:
;   	Result = QUERY_WAV(File[, info])
;
; INPUTS:
; 	File: The full path name of the file to read.
;
; OUTPUTS:
;	This function returns 1 if the file can be read as a .WAV file
;	and 0 otherwise
;
; OPTIONAL OUTPUTS:
;	Info : Anonymous structure containing file information.
;
; KEYWORDS:
;	None
;
; SIDE EFFECTS:
;   	IO is performed.
;
; RESTRICTIONS:
;	Only the PCM (uncompressed) data only format is supported.
;
; PROCEDURE:
;   	Straightforward. Will work on both big endian and little endian
;	machines.
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   RJF, RSI.   Sep, 1998. Original version.
;   CT, RSI, Aug 2003: Fix bug in error code if unable to open file.
;-

compile_opt hidden
ON_IOERROR, bad
ON_ERROR, 2         ;Return on error

OPENR, unit, file, /GET_LUN, /BLOCK
fhdr = { WAVFILEHEADER, $
    friff: BYTARR(4), $        ;A four char string
    fsize: 0L, $
    fwave: BYTARR(4) $	    ;A four char string
  }
READU, unit, fhdr           ;Read the header
IF (STRING(fhdr.friff) NE "RIFF") OR  $
	(STRING(fhdr.fwave) NE "WAVE") THEN BEGIN
    FREE_LUN, unit
    RETURN, 0
ENDIF

big_endian = (BYTE(1,0,2))[0] EQ 0b

chdr = { WAVCHUNKHEADER, $
	cid:	BYTARR(4), $
	csize: 0L $
}
cfmt = { WAVFMTCHUNK, $
	tag: 0, $
	chan: 0, $
	rate: 0L, $
	bps: 0L, $
	balign: 0, $
	bits: 0, $
	bextra: 0 $
}

; Find the 'fmt ' chunk
READU, unit, chdr
IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
WHILE (STRING(chdr.cid) NE 'fmt ') DO BEGIN
	POINT_LUN, -unit, pos
	POINT_LUN, unit, pos+chdr.csize
	READU, unit, chdr
	IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
END

; Use the header size to move past fmt chunk in case
; struct size does not match.
POINT_LUN, -unit, pos
READU, unit, cfmt
POINT_LUN, unit, pos+chdr.csize
IF (big_endian) THEN cfmt = SWAP_ENDIAN(cfmt)
IF (cfmt.tag NE 1) THEN BEGIN
	FREE_LUN, unit
	RETURN, 0
END

; Find the 'data' chunk
READU, unit, chdr
IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
WHILE (STRING(chdr.cid) NE 'data') DO BEGIN
	POINT_LUN, -unit, pos
	POINT_LUN, unit, pos+chdr.csize
	READU, unit, chdr
	IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
END

; info struct
info = { $
	CHANNELS: cfmt.chan, $
	SAMPLES_PER_SEC: cfmt.rate, $
	BITS_PER_SAMPLE: cfmt.bits $
}

CLOSE, unit
FREE_LUN, unit
RETURN, 1

bad:
    MESSAGE, /RESET
    if N_ELEMENTS(unit) GT 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0
END

