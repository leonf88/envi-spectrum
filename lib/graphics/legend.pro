; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/legend.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;----------------------------------------------------------------------------
;+
; :Description:
;    Create IDL Legend graphic.
;
; :Params:
;    
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function legend, _REF_EXTRA=_extra
  compile_opt idl2, hidden
@graphic_error

  return, OBJ_NEW('Legend', _EXTRA=_extra)

end
