; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/axis.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;

;----------------------------------------------------------------------------
;+
; :Description:
;    Create IDL Axis graphic.
;
; :Params:
;    direction - Axis direction
;    
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function axis, direction, _REF_EXTRA=_extra
  compile_opt idl2, hidden
@graphic_error

  err_direction = 'Value specified for axis direction is invalid.'

  nparams = n_params()
  if nparams ne 1 then $
     MESSAGE, 'Incorrect number of arguments.'

    ; Support the ability to specify direction as string X,Y,Z
    if SIZE(direction,/TYPE) eq 7 && $
        STRLEN(direction) eq 1 then begin
        case STRLOWCASE(direction) of
        'x': direction = 0
        'y': direction = 1
        'z': direction = 2
         ELSE: MESSAGE, err_direction
        endcase
    endif else begin
        if direction lt 0 || direction gt 2 then MESSAGE, err_direction
    endelse

  return, OBJ_NEW('Axis', DIRECTION=direction, _EXTRA=_extra)

end
