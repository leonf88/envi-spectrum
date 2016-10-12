;+
; :Description:
;    Create IDL ErrorPlot graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;    arg3 : optional generic argument
;    arg4 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
function errorplot, arg1, arg2, arg3, arg4, arg5, TEST=test, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()

  if (KEYWORD_SET(test)) then begin
    n = 20
    arg1 = FINDGEN(n)
    arg2 = RANDOMU(s,n)
    arg3 = RANDOMU(s,n)
    arg4 = RANDOMU(s,n)/5
    nparams = 4
    style = '2o-'
  endif else begin
    if (nparams lt 2) then $
      MESSAGE, 'Incorrect number of arguments.'

    switch (nparams) of
    5: if ~ISA(arg5, 'STRING') then MESSAGE, 'Format argument must be a string.'
    4: if (~ISA(arg4, /ARRAY) && ~ISA(arg4, 'STRING')) then $
      MESSAGE, 'Input must be an array or a Format string.'
    3: if (~ISA(arg3, /ARRAY) && ~ISA(arg3, 'STRING')) then $
      MESSAGE, 'Input must be an array or a Format string.'
    2: if ~ISA(arg2, /ARRAY) then MESSAGE, 'Input must be an array.'
    1: if ~ISA(arg1, /ARRAY) then MESSAGE, 'Input must be an array.'
    endswitch
  
    err = 'Style argument must be passed in after data.'
    if (isa(arg2, 'STRING'))  then begin
      if (isa(arg3)) then MESSAGE, err
      style = arg2
      nparams--
    endif else if (isa(arg3, 'STRING')) then begin
      if (isa(arg4)) then MESSAGE, err
      style = arg3
      nparams--
    endif else if (isa(arg4, 'STRING')) then begin
      if (isa(arg5)) then MESSAGE, err
      style = arg4
      nparams--
    endif else if (isa(arg5, 'STRING')) then begin
      style = arg5
      nparams--
    endif 
  endelse
  
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=c, LINESTYLE=l, SYMBOL=s, THICK=t
  endif

    case nparams of
    1: p = plot(arg1, $
      COLOR=c, LINESTYLE=l, SYMBOL=s, THICK=t, _EXTRA=ex)
    2: p = plot(arg1, YERROR=arg2, $
      COLOR=c, LINESTYLE=l, SYMBOL=s, THICK=t, _EXTRA=ex)
    3: p = plot(arg1, arg2, YERROR=arg3, $
      COLOR=c, LINESTYLE=l, SYMBOL=s, THICK=t, _EXTRA=ex)
    4: p = plot(arg1, arg2, XERROR=arg3, YERROR=arg4, $
      COLOR=c, LINESTYLE=l, SYMBOL=s, THICK=t, _EXTRA=ex)
  endcase

  return, p
  
end
