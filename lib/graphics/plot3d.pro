;+
; :Description:
;    Create a 3D plot.
;
; :Params:
;    X
;    Y
;    Z
;    Format
;
;-
function Plot3d, x, y, z, format, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams lt 3 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'
  
  if (hasTestKW) then begin
    ; Create some data.
    t = FINDGEN(4001)/100
    x = COS(t)*(1 + t/10)
    y = SIN(t)*(1 + t/10)
    z = SIN(2*t)
    format = 'b'
  endif

  switch (nparams) of
  4: if ~ISA(format, 'STRING') then MESSAGE, 'Format argument must be a string.'
  3: if ~ISA(z, /ARRAY) then MESSAGE, 'Z argument must be an array.'
  2: if ~ISA(y, /ARRAY) then MESSAGE, 'Y argument must be an array.'
  1: if ~ISA(x, /ARRAY) then MESSAGE, 'X argument must be an array.'
  endswitch
  
  if (isa(format, 'STRING')) then begin
    style = format
    nparams--
  endif
   
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=color, LINESTYLE=linestyle, SYMBOL=SYMBOL, THICK=thick
  endif
  
  Graphic, 'Plot', x, y, z, COLOR=color, LINESTYLE=linestyle, $
    SYMBOL=SYMBOL, THICK=thick, _EXTRA=ex, $
    GRAPHIC=graphic

  return, graphic
end
