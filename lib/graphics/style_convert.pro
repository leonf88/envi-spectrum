; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/style_convert.pro#1 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; :Description:
;    Convert from human-readable style strings into
;    COLOR, LINESTYLE, SYMBOL, and THICK property values.
;
; :Params:
;    input
;
; :Keywords:
;    COLOR
;    LINESTYLE
;    SYMBOL
;    THICK
;
; :Author: ITTVIS
;-
pro style_convert, input, COLOR=color, LINESTYLE=linestyle, $
                          SYMBOL=symbol, THICK=thick
  compile_opt idl2, hidden
  ON_ERROR, 2

  ; Sanity check - return indexed color arrays or RGB array unchanged.
  if (ISA(input,'BYTE') || ISA(input,'INT') || SIZE(input,/N_DIM) ge 2) then begin
    color = input
    return
  endif

  ; Look for arrays of color names - used for contour levels for example.
  n = N_ELEMENTS(input)
  if (ISA(input,'STRING') && n gt 1) then begin
    color = BYTARR(3, n)
    for i=0,n-1 do begin
      STYLE_CONVERT, input[i], COLOR=c
      color[*,i] = c
    endfor
    return
  endif

  ; Check for 24-bit integer color or a Hex RGB color string.
  if (~ISA(input, 'STRING') || STRCMP(input, '#', 1)) then begin
    ; color is hex, convert to rgb array
    color = hexcolor_convert(input)
    return
  endif

  ; Check to see if input contains a color name, e.g., medium_aquamarine
  colors = TAG_NAMES(!COLOR)
  input1 = STRUPCASE(input[0])
  input1 = STRJOIN(STRTOK(input1, ' ', /EXTRACT), '_')
  ind = where(STRUPCASE(input1) eq colors, cnt)
  if (cnt ne 0) then begin
    color = !COLOR.(ind[-1])
    return
  endif
  
  for i=0, strlen(input)-1 do begin
    input_char = strmid(input, i, 1)
    ;check the ascii value for numbers
    if((byte(input_char) ge 48) && (byte(input_char) le 57)) then begin
      precision = 0
      while ((byte(strmid(input, i+1+precision, 1)) ge 48) && $
             (byte(strmid(input, i+1+precision, 1)) le 57)) do precision++
      thick = float(strmid(input, i, i+1+precision))
      i = i+precision
    endif else begin
      case input_char of
        ; color
        'b': color = !color.blue 
        'g': color = !color.green 
        'r': color = !color.red 
        'c': color = !color.cyan 
        'm': color = !color.magenta 
        'y': color = !color.yellow 
        'k': color = !color.black 
        'w': color = !color.white 
        
        ; symbols
        '+': symbol = 1 
        '*': symbol = 2 
        '.': symbol = 3 
        'D': symbol = 4 
        't': begin
          if ((strmid(input, i+1, 1) eq 'u') || $
              (strmid(input, i+1, 1) eq 'd') || $
              (strmid(input, i+1, 1) eq 'l') || $
              (strmid(input, i+1, 1) eq 'i')) then begin
            i = i+1
            if (strmid(input, i, 1) eq 'u') then symbol = 5 
            if (strmid(input, i, 1) eq 'd') then  symbol = 10 
            if (strmid(input, i, 1) eq 'l') then  symbol = 11 
            if (strmid(input, i, 1) eq 'i') then  symbol = 12 
          endif else begin
            MESSAGE, /INFO, 'Illegal symbol character: ' + input
            return
          endelse
        end
        's': symbol = 6 
        'X': symbol = 7 
        '>': symbol = 8 
        '<': symbol = 9 
        'T': begin
          if ((strmid(input, i+1, 1) eq 'u') || $
              (strmid(input, i+1, 1) eq 'd') || $
              (strmid(input, i+1, 1) eq 'l') || $
              (strmid(input, i+1, 1) eq 'i')) then begin
            i = i+1
            if (strmid(input, i, 1) eq 'u') then  symbol = 13 
            if (strmid(input, i, 1) eq 'd') then  symbol = 14 
            if (strmid(input, i, 1) eq 'l') then  symbol = 15 
            if (strmid(input, i, 1) eq 'i') then  symbol = 16 
          endif else begin
            MESSAGE, /INFO, 'Illegal symbol character: ' + input
            return
          endelse
        end
        'd': symbol = 17 
        'p': symbol = 18 
        'h': symbol = 19 
        'H': symbol = 20 
        '|': symbol = 21 
        '_': begin
          if(strmid(input, i+1, 1) eq '_') then begin
            i = i+1
            linestyle = 5 
          endif else begin
            symbol = 22 
          endelse
        end
        'S': symbol = 23
        'o': symbol = 24 
        
        ;line
        '-': begin
          if ((strmid(input, i+1, 1) eq '-') || $
              (strmid(input, i+1, 1) eq '.') || $
              (strmid(input, i+1, 1) eq ':')) then begin
            i = i+1
            if (strmid(input, i, 1) eq '-') then  linestyle = 2 
            if (strmid(input, i, 1) eq '.') then  linestyle = 3 
            if (strmid(input, i, 1) eq ':') then  linestyle = 4 
          endif else begin
            linestyle = 0 
          endelse
        end
        ':': linestyle = 1 
        ' ': linestyle = 6 
        else: begin
          MESSAGE, /INFO, 'Illegal symbol, linestyle or color: ' + input
          return
          end
      endcase
    endelse
  endfor

  ; if marker is specified, but linestyle is not, only markers are plotted.
  if (ISA(symbol) && ~ISA(linestyle)) then linestyle = 6
  
end

