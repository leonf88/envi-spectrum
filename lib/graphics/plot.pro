;+
; :Description:
;    Create IDL Plot graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
function plot, arg1, arg2, arg3, LAYOUT=layoutIn, TEST=test, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = KEYWORD_SET(test)
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'
  
  switch (nparams) of
  3: if ~ISA(arg3, 'STRING') then MESSAGE, 'Format argument must be a string.'
  2: if (~ISA(arg2, /ARRAY) && ~ISA(arg2, 'STRING')) then $
    MESSAGE, 'Input must be an array or a Format string.'
  1: if ~ISA(arg1, /ARRAY) && ~hasTestKW then MESSAGE, 'Input must be an array.'
  endswitch
  
  if (isa(arg1, 'STRING')) then begin
    if (~hasTestKW) then $
      MESSAGE, 'Format argument must be passed in after data.'
    style = arg1
    nparams--
  endif
  if (isa(arg2, 'STRING'))  then begin
    if (isa(arg3)) then $
      MESSAGE, 'Format argument must be passed in after data.'
    style = arg2
    nparams--
  endif
  if (isa(arg3, 'STRING')) then begin
    style = arg3
    nparams--
  endif
   
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=color, LINESTYLE=linestyle, SYMBOL=SYMBOL, THICK=thick
    
  endif
  
  layout = N_ELEMENTS(layoutIn) eq 3 ? layoutIn : [1,1,1]
  
  name = 'Plot'
  case nparams of
    0: Graphic, name, COLOR=color, LINESTYLE=linestyle, $
      SYMBOL=SYMBOL, THICK=thick, LAYOUT=layout, TEST=test, _EXTRA=ex, $
      GRAPHIC=graphic
    1: Graphic, name, arg1, COLOR=color, LINESTYLE=linestyle, $
      SYMBOL=SYMBOL, THICK=thick, LAYOUT=layout, TEST=test, _EXTRA=ex, $
      GRAPHIC=graphic
    2: Graphic, name, arg1, arg2, COLOR=color, LINESTYLE=linestyle, $
      SYMBOL=SYMBOL, THICK=thick, LAYOUT=layout, TEST=test, _EXTRA=ex, $
      GRAPHIC=graphic
    3: Graphic, name, arg1, arg2, arg3, COLOR=color, LINESTYLE=linestyle, $
      SYMBOL=SYMBOL, THICK=thick, LAYOUT=layout, TEST=test, _EXTRA=ex, $
      GRAPHIC=graphic
  endcase

  return, graphic
end
