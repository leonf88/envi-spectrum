;+
; :Description:
;    Create IDL Image graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function image, arg1, arg2, arg3, ASPECT_RATIO=aspectIn, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'

  switch (nparams) of
  3: if ~ISA(arg3, /ARRAY) then MESSAGE, 'Input must be an array.'
  2: if ~ISA(arg2, /ARRAY) then MESSAGE, 'Input must be an array.'
  1: if ~(ISA(arg1, /ARRAY) || ISA(arg1, 'string')) $
       then MESSAGE, 'Input must be an array or a string.'
  endswitch
  
  aspect = N_ELEMENTS(aspectIn) eq 1 ? aspectIn : 1
    
  name = 'Image'
  case nparams of
    0: Graphic, name, _EXTRA=ex, GRAPHIC=graphic, $
      ASPECT_RATIO=aspect
    1: Graphic, name, arg1, _EXTRA=ex, GRAPHIC=graphic, $
      ASPECT_RATIO=aspect
    2: Graphic, name, arg1, arg2, _EXTRA=ex, GRAPHIC=graphic, $
      ASPECT_RATIO=aspect
    3: Graphic, name, arg1, arg2, arg3, _EXTRA=ex, GRAPHIC=graphic, $
      ASPECT_RATIO=aspect
  endcase

  return, graphic
end
