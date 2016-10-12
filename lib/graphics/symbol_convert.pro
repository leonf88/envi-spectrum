function symbol_convert, symbol_string
  compile_opt idl2, hidden
  ON_ERROR, 2

  ; If input is a number then pass it back  
  numberTypes = [1,2,3,4,5,12,13,14,15]  void = where(SIZE(symbol_string, /TYPE) eq numberTypes, cnt)  if (cnt eq 1) then $    return, fix(symbol_string[0])  if(~isa(symbol_string, 'string')) then $    MESSAGE, 'linestyle is not the correct type.'
  symbol_string = strmid(symbol_string, 0, strlen(symbol_string))
  ; if the length of the string is greater than 2 then it is a full length name of symbol instead of characters representing symbols.
  if (strlen(symbol_string) gt 2) then symbol_string = strupcase(symbol_string)
  retval = 0
  case 1 of
  (strcmp(symbol_string, 'NONE')): retval = 0
  (strcmp(symbol_string, 'PLUS')) || (strcmp(symbol_string, '+')): retval = 1
  (strcmp(symbol_string, 'ASTERISK')) || (strcmp(symbol_string, '*')): retval = 2
  (strcmp(symbol_string, 'PERIOD')) || (strcmp(symbol_string, 'DOT')) || (strcmp(symbol_string, '.')): retval = 3
  (strcmp(symbol_string, 'DIAMOND'))  || (strcmp(symbol_string, 'D')): retval = 4
  (strcmp(symbol_string, 'TRIANGLE'))  || (strcmp(symbol_string, 'tu')): retval = 5
  (strcmp(symbol_string, 'SQUARE')) || (strcmp(symbol_string, 's')): retval = 6
  (strcmp(symbol_string, 'X')): retval = 7
  (strcmp(symbol_string, 'GREATER_THAN')) || (strcmp(symbol_string, '>')): retval = 8
  (strcmp(symbol_string, 'LESS_THAN')) || (strcmp(symbol_string, '<')): retval = 9
  (strcmp(symbol_string, 'TRIANGLE_DOWN')) || (strcmp(symbol_string, 'td')): retval = 10
  (strcmp(symbol_string, 'TRIANGLE_LEFT')) || (strcmp(symbol_string, 'tl')): retval = 11
  (strcmp(symbol_string, 'TRIANGLE_RIGHT')) || (strcmp(symbol_string, 'ti')): retval = 12
  (strcmp(symbol_string, 'TRI_UP')) || (strcmp(symbol_string, 'Tu')): retval = 13
  (strcmp(symbol_string, 'TRI_DOWN')) || (strcmp(symbol_string, 'Td')): retval = 14
  (strcmp(symbol_string, 'TRI_LEFT')) || (strcmp(symbol_string, 'Tl')): retval = 15
  (strcmp(symbol_string, 'TRI_RIGHT')) || (strcmp(symbol_string, 'Ti')): retval = 16
  (strcmp(symbol_string, 'THIN_DIAMOND')) || (strcmp(symbol_string, 'd')): retval = 17
  (strcmp(symbol_string, 'PENTAGON')) || (strcmp(symbol_string, 'p')): retval = 18
  (strcmp(symbol_string, 'HEXAGON_1')) || (strcmp(symbol_string, 'h')): retval = 19
  (strcmp(symbol_string, 'HEXAGON_2')) || (strcmp(symbol_string, 'H')): retval = 20
  (strcmp(symbol_string, 'VLINE')) || (strcmp(symbol_string, '|')): retval = 21
  (strcmp(symbol_string, 'HLINE')) || (strcmp(symbol_string, '_')): retval = 22
  (strcmp(symbol_string, 'STAR')) || (strcmp(symbol_string, 'S')): retval = 23
  (strcmp(symbol_string, 'CIRCLE')) || (strcmp(symbol_string, 'o')): retval = 24
  
  else: MESSAGE, "not a valid symbol name string '"+symbol_string+"'"
  endcase

  return, retval
  
end