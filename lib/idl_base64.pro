; $Id: //depot/idl/releases/IDL_80/idldir/lib/idl_base64.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;----------------------------------------------------------------------------
function idl_base64_decode, input

  compile_opt idl2, hidden

  ON_ERROR, 2
  
  slen = (Strlen(input))[0]
  if (slen eq 0) then return, 0b
  
  nGroups = slen/4
  if (4*nGroups ne slen) then begin
    MESSAGE, 'String length must be a multiple of 4.', /NONAME
  endif
  
  if (Strmid(input, slen-2, 2) eq "==") then begin
    nFullGroups = nGroups - 1
    missingBytesInLastGroup = 2
  endif else if (Strmid(input, slen-1, 1) eq "=") then begin
    nFullGroups = nGroups - 1
    missingBytesInLastGroup = 1
  endif else begin
    nFullGroups = nGroups
    missingBytesInLastGroup = 0
  endelse
  
  ; This array is a lookup table that translates unicode characters
  ; drawn from the "Base64 Alphabet" (as specified in Table 1 of RFC 2045)
  ; into their 6-bit positive integer equivalents.  Characters that
  ; are not in the Base64 alphabet but fall within the bounds of the
  ; array are translated to -1.
  base64toByte = Byte([ $
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, $
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, $
    -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63, 52, 53, 54, $
    55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -2, -1, -1, -1, 0, 1, 2, 3, 4, $
    5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, $
    24, 25, -1, -1, -1, -1, -1, -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, $
    35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -1 ])


  result = BYTARR(3*nGroups - missingBytesInLastGroup, /NOZERO)
  
  chars = base64toByte[[BYTE(input)]]

  if (Max(chars) eq 255) then begin
    MESSAGE, 'Out-of-range character in encoding string.', /NONAME
  endif

  chEnd = chars[slen-4:*]

  if (nFullGroups gt 0) then begin
    ch0 = chars[0:4*nFullGroups-1:4]
    ch1 = chars[1:4*nFullGroups-1:4]
    ch2 = chars[2:4*nFullGroups-1:4]
    ch3 = chars[3:4*nFullGroups-1:4]
    chars = 0
    result[0:3*nFullGroups-1:3] = ISHFT(TEMPORARY(ch0), 2) or ISHFT(ch1, -4)
    result[1:3*nFullGroups-1:3] = ISHFT(TEMPORARY(ch1), 4) or ISHFT(ch2, -2)
    result[2:3*nFullGroups-1:3] = ISHFT(TEMPORARY(ch2), 6) or TEMPORARY(ch3)
  endif
  
  if (missingBytesInLastGroup gt 0) then begin
    result[3*nFullGroups] = ISHFT(chEnd[0], 2) or ISHFT(chEnd[1], -4)
    if (missingBytesInLastGroup eq 1) then begin
      result[3*nFullGroups + 1] = ISHFT(chEnd[1], 4) or ISHFT(chEnd[2], -2)
    endif
  endif

  return, result
end


;----------------------------------------------------------------------------
function idl_base64_encode, input

  compile_opt idl2, hidden

  ON_ERROR, 2

  len = N_ELEMENTS(input)
  nFullGroups = len/3
  nBytesPartialGroup = len - 3*nFullGroups
  resultLen = 4*((len + 2)/3)
  
  ; This array is a lookup table that translates 6-bit positive integer
  ; index values into their "Base64 Alphabet" equivalents as specified
  ; in Table 1 of RFC 2045.
  byteToBase64 = $
    Byte(['ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' ])

  result = BYTARR(resultLen, /NOZERO)
  
  if (nFullGroups gt 0) then begin
    byte0 = input[0:nFullGroups*3-1:3]
    result[0:nFullGroups*4-1:4] = byteToBase64[ISHFT(byte0,-2)]
    byte1 = input[1:nFullGroups*3-1:3]
    result[1:nFullGroups*4-1:4] = $
      byteToBase64[ISHFT(TEMPORARY(byte0) and 3b, 4) or ISHFT(byte1,-4)]
    byte2 = input[2:nFullGroups*3-1:3]
    result[2:nFullGroups*4-1:4] = $
      byteToBase64[ISHFT(TEMPORARY(byte1) and 15b, 2) or ISHFT(byte2,-6)]
    result[3:nFullGroups*4-1:4] = byteToBase64[TEMPORARY(byte2) and 63b]
  endif
  
  if (nBytesPartialGroup gt 0) then begin
    byte0 = input[nFullGroups*3]
    result[nFullGroups*4] = byteToBase64[ISHFT(byte0,-2)]
    if (nBytesPartialGroup eq 1) then begin
      result[nFullGroups*4 + 1] = $
        byteToBase64[ISHFT(TEMPORARY(byte0) and 3b, 4)]
      result[nFullGroups*4 + 2] = Byte("==")
    endif else begin   ; nBytesPartialGroup == 2
      byte1 = input[nFullGroups*3 + 1]
      result[nFullGroups*4 + 1] = $
        byteToBase64[ISHFT(TEMPORARY(byte0) and 3b, 4) or ISHFT(byte1,-4)]
      result[nFullGroups*4 + 2] = $
        byteToBase64[ISHFT(TEMPORARY(byte1) and 15b, 2)]
      result[nFullGroups*4 + 3] = Byte("=")
    endelse
  endif

  return, STRING(result)
end

;----------------------------------------------------------------------------
;+
; :Description:
;    The IDL_Base64 function uses MIME Base64 encoding to convert a byte
;    array into a scalar string, or to convert a scalar string back into
;    a byte array.
;
;    The MIME Base64 encoding uses 64 characters, consisting of
;    "A-Z", "a-z", "0-9", "+", and "/".
;    Every 3 bytes of the original array are converted into 4 characters.
;    If the length of the final string is not a multiple of 4, then it
;    is padded with "=" characters. The 64 characters are chosen
;    because they are common to most encodings, are printable, and are
;    unlikely to be modified in transit through systems such as email.
;
; :Returns:
;      If *Input* is a byte array then the result is a scalar string
;      containing the encoded data. If *Input* is a string then the
;      result is a byte array containing the decoded data.
;      
;      *Note*: When decoding a string, the resulting byte array
;      will always be returned as a one-dimensional vector, regardless
;      of the dimensions of the original byte data.
;   
; :Params:
;    Input:
;      *Input* must be either an array of type byte or a scalar string.
;
; :Keywords:
;    None
; :
;
; :Author:
;   CT, ITTVIS, June 2008
;-
function IDL_Base64, input

  compile_opt idl2, hidden
  
  ON_ERROR, 2
  
  CATCH, iErr
  if (iErr ne 0) then begin
    CATCH, /CANCEL
    MESSAGE, !ERROR_STATE.msg
  endif

  if ((Size(input, /TYPE) eq 7) && (N_Elements(input) eq 1)) then begin
    return, IDL_Base64_Decode(input)
  endif
  
  if (Size(input, /TYPE) eq 1) then begin
    return, IDL_Base64_Encode(input)
  endif

  CATCH, /CANCEL
  MESSAGE, 'Input must be a byte array for encode or a scalar string for decode.'

end

