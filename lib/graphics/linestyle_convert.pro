function linestyle_convert, style
  compile_opt idl2, hidden
  ON_ERROR, 2

  ; If input is a number then pass it back
  numberTypes = [1,2,3,4,5,12,13,14,15]
  void = where(SIZE(style, /TYPE) eq numberTypes, cnt)
  if (cnt eq 1) then $
    return, fix(style[0])

  if(~isa(style, 'string')) then $
    MESSAGE, 'Linestyle must be of type integer or string.'

  n = N_ELEMENTS(style)
  if (n gt 1) then begin
    result = INTARR(n)
    for i=0,n-1 do result[i] = LINESTYLE_CONVERT(style[i])
    return, result
  endif

  s = STRUPCASE(style)
  ; Remove underscores from names (but only for the "long" names).
  if (STRLEN(s) ge 3) then s = STRJOIN(STRTOK(s, '_', /EXTRACT))
  s = STRCOMPRESS(s, /REMOVE)

  case 1 of
  (STRCMP(s, 'SOLID', 5) || (s eq '-') || (s eq '0')): retval = 0
  (STRCMP(s, 'DOT', 3) || (s eq ':') || (s eq '1')): retval = 1
  (STRCMP(s, 'DASHDOTDOT', 10) || (s eq '-:') || (s eq '4')): retval = 4
  (STRCMP(s, 'DASHDOT', 7) || (s eq '-.') || (s eq '3')): retval = 3
  (STRCMP(s, 'DASH', 4) || (s eq '--') || (s eq '2')): retval = 2
  (STRCMP(s, 'LONG', 4) || (s eq '__') || (s eq '5')): retval = 5
  (STRCMP(s, 'NO', 2) || (s eq '') || (s eq '6')): retval = 6
  else: MESSAGE, "Illegal value for Linestyle: "+style
  endcase
  
  return, retval
  
end