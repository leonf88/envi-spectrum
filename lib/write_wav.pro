; $Id: //depot/idl/releases/IDL_80/idldir/lib/write_wav.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

PRO WRITE_WAV, file, data, rate
;+
; NAME:
;	WRITE_WAV
;
; PURPOSE:
; 	This function writes a Microsoft Windows .WAV (RIFF) file
;
; CATEGORY:
;   	Input/Output
;
; CALLING SEQUENCE:
;   	WRITE_WAV, File, data, rate
;
; INPUTS:
; 	File: The full path name of the file to write.
;	Data: Input data channels to be written (1 or 2D array,
;		 leading dimension is the number of channels).  Note:
;		 if not in BYTE or INT format, output data will be
;		 written in INT format.
;	Rate: Sampling rate (samples per second).
;
; OUTPUTS:
;	None
;
; OPTIONAL OUTPUTS:
;	None
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

ON_IOERROR, bad
ON_ERROR, 2         ;Return on error

; let user know about demo mode limitation.
; all write options disabled in demo mode
IF (LMGR(/DEMO)) THEN BEGIN
    MESSAGE, 'OPENW: Feature disabled for demo mode.'
    RETURN
ENDIF

fhdr = { WAVFILEHEADER, $
    friff: BYTARR(4), $        ;A four char string
    fsize: 0L, $
    fwave: BYTARR(4) $	    ;A four char string
  }
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

; init the fmt chunk
cfmt.tag = 1
cfmt.chan = 1
cfmt.rate = rate
cfmt.bits = 8
s = SIZE(data)
IF (s[0] GE 2) THEN cfmt.chan = s[1]
IF (SIZE(data,/TYPE) NE 1) THEN cfmt.bits = 16
bytes = (cfmt.bits/8)
cfmt.bps = cfmt.rate*cfmt.chan*bytes
cfmt.balign = bytes*cfmt.chan
big_endian = (BYTE(1,0,2))[0] EQ 0b

; init the header
fhdr.friff = BYTE("RIFF")
fhdr.fwave = BYTE("WAVE")
fhdr.fsize = 4 + 8 + 18 + 8 + N_ELEMENTS(data)*bytes

; write the file
IF (!version.os EQ 'MacOS') THEN BEGIN
	OPENW, unit, file, /GET_LUN, /BLOCK, MACTYPE='WAVE', MACCREATOR='TVOD'
END ELSE BEGIN
	OPENW, unit, file, /GET_LUN, /BLOCK
END
IF (big_endian) THEN fhdr = SWAP_ENDIAN(fhdr)
WRITEU, unit, fhdr           ;write the header
chdr.cid = BYTE('fmt ')
chdr.csize = 18
IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
WRITEU, unit, chdr		  ;write 'fmt ' hdr
IF (big_endian) THEN cfmt = SWAP_ENDIAN(cfmt)
WRITEU, unit, cfmt		  ;write 'fmt '
chdr.cid = BYTE('data')
chdr.csize = N_ELEMENTS(data)*bytes
IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
WRITEU, unit, chdr		  ;write 'data' hdr
; write the data
IF (SIZE(data,/TYPE) LE 2) THEN BEGIN
	IF (big_endian) THEN BEGIN
		WRITEU, unit, SWAP_ENDIAN(data)
	END ELSE BEGIN
		WRITEU, unit, data
	END
END ELSE BEGIN
	IF (big_endian) THEN BEGIN
		WRITEU, unit, SWAP_ENDIAN(FIX(data))
	END ELSE BEGIN
		WRITEU, unit, FIX(data)
	END
END
CLOSE, unit
FREE_LUN, unit
RETURN

bad:
if n_elements(unit) gt 0 then $
    if (unit ne 0) then free_lun, unit
MESSAGE, 'Cannot open (or write)' + file
RETURN

END
