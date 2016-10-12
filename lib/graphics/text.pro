;+
; :Description:
;    Create IDL Text graphic.
;
; :Params:
;    X : X coordinate
;    Y : Y coordinate
;    Arg3 : String (for 2D) or Z coordinate (for 3D)
;    Arg4 : String (for 3D)
;
; :Keywords:
;    _REF_EXTRA
;
;-
function text, x, y, arg3, arg4, style, DATA=data, VISUALIZATION=add2vis, $
  COLOR=color, _REF_EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  nparams = n_params()

  if (nparams lt 3) then MESSAGE, 'Incorrect number of arguments.'
  if (KEYWORD_SET(data) && ~ISA(add2vis)) then add2vis = 1b
  
  nx = N_ELEMENTS(x)
  ny = N_ELEMENTS(y)
  n3 = N_ELEMENTS(arg3)
  n4 = N_ELEMENTS(arg4)
  
  ; Check for style string
  case nparams of
    4: begin
      if (ISA(arg3, 'STRING') && ISA(arg4, 'STRING')) then begin
        style_convert, arg4, COLOR=color
        nparams--
      endif
    end
    5: begin
      if (ISA(style, 'STRING')) then begin
        style_convert, style, COLOR=color
        nparams--
      endif
    end
    else:
  endcase

  case nparams of
    3: begin
      if (~ISA(arg3, 'STRING')) then MESSAGE, 'Argument must be a string.'
      n = nx < ny < n3
      scalarLocation = (nx eq 1 && ny eq 1)
      oText = (n eq 1) ? OBJ_NEW() : OBJARR(n)
      for i=0,n-1 do begin
        ; For a single X/Y location, pass in the full string argument,
        ; not just a single item. This allows multi-line strings to work.
        iText, scalarLocation ? arg3 : arg3[i], x[i], y[i], OBJECT=obj, $
          DATA=data, VISUALIZATION=add2vis, FONT_COLOR=color, _EXTRA=ex
        oText[i] = obj
      endfor
      end
    4: begin
      if (~ISA(arg4, 'STRING')) then MESSAGE, 'Argument must be a string.'
      n = nx < ny < n3 < n4
      scalarLocation = (nx eq 1 && ny eq 1 && n3 eq 1)
      oText = (n eq 1) ? OBJ_NEW() : OBJARR(n)
      for i=0,n-1 do begin
        ; For a single X/Y/Z location, pass in the full string argument,
        ; not just a single item. This allows multi-line strings to work.
        iText, scalarLocation ? arg4 : arg4[i], x[i], y[i], arg3[[i]], OBJECT=obj, $
          DATA=data, VISUALIZATION=add2vis, FONT_COLOR=color, _EXTRA=ex
        oText[i] = obj
      endfor
      end
  endcase

  ; Ensure that all class definitions are available.
  Graphic__define
  ; Replace each text object with its proxy.
  for i=0,n-1 do oText[i] = OBJ_NEW('Text', oText[i])
  return, oText
end
