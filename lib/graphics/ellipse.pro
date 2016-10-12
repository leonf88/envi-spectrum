; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/ellipse.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create an Ellipse graphic.
;
; :Params:
;    X
;    Y
;    Z
;    Style
;
; :Keywords:
;    DATA
;    VISUALIZATION
;    All other keywords are passed through to the ellipse.
;
; :Author: ITTVIS, March 2010
;-
function Ellipse, x, y, z, styleIn, $
  DATA=data, VISUALIZATION=add2vis, $
  _REF_EXTRA=ex

  compile_opt idl2, hidden
@graphic_error

  nparams = n_params()
  if (isa(X, 'STRING'))  then $
    MESSAGE, 'Style argument must be passed in after data.'
  if (isa(Y, 'STRING'))  then begin
    if (nparams gt 2) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Y
    Y = !NULL
    nparams--  
  endif
  if (isa(Z, 'STRING')) then begin
    if (nparams gt 3) then $
      MESSAGE, 'Style argument must be passed in after data.'
    style = Z
    Z = !NULL
    nparams--
  endif
  if (isa(styleIn, 'STRING')) then begin
    style = styleIn
    nparams--
  endif
  
  if (n_elements(style)) then begin
    style_convert, style, COLOR=color, LINESTYLE=linestyle, THICK=thick
  endif

  if (KEYWORD_SET(data) && ~ISA(add2vis)) then add2vis = 1b
  iEllipse, 0, x, y, z, DATA=data, VISUALIZATION=add2vis, $
    COLOR=color, LINESTYLE=linestyle, THICK=thick, $
    NAME='Ellipse', $
    OBJECT=oEllipse, $
    _EXTRA=ex

  ; Ensure that all class definitions are available.
  Graphic__define
  return, OBJ_NEW('Ellipse', oEllipse)
  return, 1
end

