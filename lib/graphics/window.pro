;+
; :Description:
;    Create an empty IDL graphics window.
;
; :Params:
;
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function window, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  Graphic, _EXTRA=ex, GRAPHIC=graphic

  return, graphic
end
