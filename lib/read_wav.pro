; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_wav.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

FUNCTION READ_WAV, file, rate, _EXTRA=_extra
;+
; NAME:
;   READ_WAV
;
; PURPOSE:
;   This function reads a Microsoft Windows .WAV (RIFF) file
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = READ_WAV(File [,Rate])
;
; INPUTS:
;   File: The full path name of the file to read.
;
; OUTPUTS:
;   This function returns an array containing the audio data
;   from the file. The data can be 8 or 16 bit.  The leading
;   dimension of the returned array is the channel selection
;   (data is returned in channel interleaved format).
;
; OPTIONAL OUTPUTS:
;   Rate : the sampling rate of the sequence in samples/second.
;
; KEYWORDS:
;   None
;
; SIDE EFFECTS:
;       IO is performed.
;
; RESTRICTIONS:
;   Only the PCM (uncompressed) data only format is supported.
;
; PROCEDURE:
;       Straightforward. Will work on both big endian and little endian
;   machines.
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
    fwave: BYTARR(4) $      ;A four char string
  }
READU, unit, fhdr           ;Read the header
IF (STRING(fhdr.friff) NE "RIFF") OR  $
    (STRING(fhdr.fwave) NE "WAVE") THEN BEGIN
    FREE_LUN, unit
    MESSAGE, 'File '+file+' is not in WAV file format'
ENDIF

big_endian = (BYTE(1,0,2))[0] EQ 0b

chdr = { WAVCHUNKHEADER, $
    cid:   BYTARR(4), $
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
    MESSAGE, 'Non-PCM format WAV files not supported'
END
rate = cfmt.rate

; Find the 'data' chunk
READU, unit, chdr
IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
WHILE (STRING(chdr.cid) NE 'data') DO BEGIN
    POINT_LUN, -unit, pos
    POINT_LUN, unit, pos+chdr.csize
    READU, unit, chdr
    IF (big_endian) THEN chdr = SWAP_ENDIAN(chdr)
END
; allocate output array
IF (cfmt.bits LE 8) THEN BEGIN
    a = BYTARR(cfmt.chan, chdr.csize/(1*cfmt.chan))
END ELSE IF (cfmt.bits LE 16) THEN BEGIN
    a = INTARR(cfmt.chan, chdr.csize/(2*cfmt.chan))
END ELSE BEGIN
    FREE_LUN, unit
    MESSAGE, 'Unsupported number of bits per sample:'+STRING(cfmt.bits)
END
; read the samples
a = REFORM(a,/OVERWRITE)
READU, unit, a
IF (big_endian) THEN a = SWAP_ENDIAN(a)

CLOSE, unit
FREE_LUN, unit
RETURN, a

bad:
if n_elements(unit) gt 0 then $
    if (unit ne 0) then free_lun, unit
MESSAGE, 'Cannot open (or read) input file.'
RETURN, 0
END

