;+
; :Description:
;    Create IDL PolarPlot graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
function polarplot, arg1, arg2, arg3, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'
  
  switch (nparams) of
  3: if ~ISA(arg3, 'STRING') then MESSAGE, 'Format argument must be a string.'
  2: if (~ISA(arg2, /ARRAY) && ~ISA(arg2, 'STRING')) then $
    MESSAGE, 'Input must be an array or a Format string.'
  1: if ~ISA(arg1, /ARRAY) then MESSAGE, 'Input must be an array.'
  endswitch
  
  if (isa(arg1, 'STRING')) then begin
    if (~hasTestKW) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = arg1
    nparams--
  endif
  if (isa(arg2, 'STRING'))  then begin
    if (isa(arg3)) then $
      MESSAGE, 'Style argument must be passed in after data.'
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
  
  case nparams of
    0: p = plot(/POLAR, COLOR=color, LINESTYLE=linestyle, SYMBOL=SYMBOL, THICK=thick, _EXTRA=ex)
    1: p = plot(arg1,  /POLAR, COLOR=color, LINESTYLE=linestyle, SYMBOL=SYMBOL, THICK=thick, _EXTRA=ex)
    2: p = plot(arg1, arg2,  /POLAR, COLOR=color, LINESTYLE=linestyle, SYMBOL=SYMBOL, THICK=thick, _EXTRA=ex)
  endcase

  return, p
end
