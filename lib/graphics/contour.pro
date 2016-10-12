;+
; :Description:
;    Create IDL Contour graphic.
;
; :Params:
;    Array :
;    X :
;    Y :
;
; :Keywords:
;    _REF_EXTRA
;    
; :Returns:
;    Object Reference
;
;-
function contour, arg1, arg2, arg3, LAYOUT=layoutIn, PLANAR=planar, _REF_EXTRA=ex

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

  if (ISA(layoutIn)) then begin
    if N_ELEMENTS(layoutIn) ne 3 then $
      MESSAGE, 'LAYOUT must have 3 elements.'
    layout = layoutIn
  endif else begin
    ; If LAYOUT was not specified, and PLANAR is not 0, then set default layout.
    if (~ISA(planar) || planar ne 0) then $
      layout = [1,1,1]
  endelse
  
  name = 'Contour'
  case nparams of
    0: Graphic, name, $
      _EXTRA=ex, LAYOUT=layout, PLANAR=planar, GRAPHIC=graphic
    1: Graphic, name, arg1, $
      _EXTRA=ex, LAYOUT=layout, PLANAR=planar, GRAPHIC=graphic
    2: Graphic, name, arg1, arg2, $
      _EXTRA=ex, LAYOUT=layout, PLANAR=planar, GRAPHIC=graphic
    3: Graphic, name, arg1, arg2, arg3, _EXTRA=ex, LAYOUT=layout, $
      PLANAR=planar, GRAPHIC=graphic
  endcase

  return, graphic
end
