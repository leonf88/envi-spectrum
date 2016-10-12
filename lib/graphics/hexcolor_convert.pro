; Copyright (c) 2009-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;       HEXCOLOR_CONVERT
;
; PURPOSE:
;       Convert hexadecimal RGB value to decimal RGB value
;
; CATEGORY:
;       Input/Output.
;
; CALLING SEQUENCE:
;      dec_rgb = HEXCOLOR_CONVERT( hex_rgb )
;
; INPUTS:
;       hex_rgb        - String of hex rgb starting with "#"
;                             ie: '#F0A578'
;
; OUTPUTS:
;       The function returns decimal RGB value
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       None.
;
; RESTRICTIONS:
;       See DESCRIPTION.
;
; DESCRIPTION:
;       This routine converts hexadecimal RGB values to decimal RGB values.
;
; EXAMPLES:
;      dec_rgb = hexcolor_convert(hex_rgb)
;
; DEVELOPMENT NOTES:
;
; MODIFICATION HISTORY:
;       MP 12/09 - written
;
;-
function hexcolor_convert,hex
  compile_opt idl2, hidden
  ON_ERROR, 2

  if (ISA(hex, /ARRAY)) then return, hex

  if (ISA(hex, 'STRING')) then begin
    if (~STRCMP(hex, '#', 1)) then $
      MESSAGE, 'Hex color value must start with a #'
    nb = STRLEN(hex)/2
    if (STRLEN(hex) mod 2 ne 1 || nb lt 3 || nb gt 4) then $
      MESSAGE, 'Incorrect length for Hex color value'
    b = BYTARR(nb)
    READS, hex, b, FORMAT='(1x,' + STRTRIM(nb,2) + 'Z2)'
    return, b
  endif

  if (ISA(hex, 'INT') || ISA(hex, 'LONG')) then begin
    ; Just bail if we have a negative number. Could be a "flag".
    if (hex lt 0) then return, hex
    b = BYTARR(3)
    b[0] = hex/65536L
    b[1] = (hex - b[0]*65536L)/256L
    b[2] = hex mod 256
    return, b
  endif
end
