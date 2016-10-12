;+
; :Description:
;    Create IDL Surface graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
function surface, arg1, arg2, arg3, SKIRT=skirt, STYLE=styleIn, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'

  switch (nparams) of
  3: if ~ISA(arg3, /ARRAY) then MESSAGE, 'Input must be an array.'
  2: if ~ISA(arg2, /ARRAY) then MESSAGE, 'Input must be an array.'
  1: if ~ISA(arg1, /ARRAY) || (SIZE(arg1,/N_DIM) ne 2) then $
    MESSAGE, 'Input must be a two-dimensional array.'
  endswitch

  if (ISA(skirt)) then ss = 1

  if (ISA(styleIn)) then begin
    if (ISA(styleIn, 'STRING')) then begin
      case STRCOMPRESS(STRUPCASE(styleIn),/REMOVE) of
      'POINTS': style = 0
      'MESH': style = 1
      'FILLED': style = 2
      'RULEDXZ': style = 3
      'RULEDYZ': style = 4
      'LEGO': style = 5
      'LEGOFILLED': style = 6
      endcase
    endif else $
      style = LONG(styleIn)
  endif

  name = 'Surface'
  case nparams of
    0: Graphic, name, SHOW_SKIRT=ss, SKIRT=skirt, STYLE=style, $
      _EXTRA=ex, GRAPHIC=graphic
    1: Graphic, name, arg1, SHOW_SKIRT=ss, SKIRT=skirt, STYLE=style, $
      _EXTRA=ex, GRAPHIC=graphic
    2: Graphic, name, arg1, arg2, SHOW_SKIRT=ss, SKIRT=skirt, STYLE=style, $
      _EXTRA=ex, GRAPHIC=graphic
    3: Graphic, name, arg1, arg2, arg3, SHOW_SKIRT=ss, SKIRT=skirt, STYLE=style, $
      _EXTRA=ex, GRAPHIC=graphic
  endcase

  return, graphic
end
