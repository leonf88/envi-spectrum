;+
; :Description:
;    Create IDL Vector graphic.
;
; :Params:
;    arg1 : optional generic argument
;    arg2 : optional generic argument
;
; :Keywords:
;    _REF_EXTRA
;
;-
function streamline, arg1, arg2, arg3, arg4, LAYOUT=layoutIn, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2

  nparams = n_params()
  hasTestKW = ISA(ex) && MAX(ex eq 'TEST') eq 1
  if (nparams eq 0 && ~hasTestKW) then $
    MESSAGE, 'Incorrect number of arguments.'

  switch (nparams) of
  4: if ~ISA(arg4, /ARRAY) then MESSAGE, 'Input must be an array.'
  3: if ~ISA(arg3, /ARRAY) then MESSAGE, 'Input must be an array.'
  2: if ~ISA(arg2, /ARRAY) then MESSAGE, 'Input must be an array.'
  1: if ~ISA(arg1, /ARRAY) then MESSAGE, 'Input must be an array.'
  endswitch

  layout = N_ELEMENTS(layoutIn) eq 3 ? layoutIn : [1,1,1]
  
  name = 'Vector'
  case nparams of
    0: Graphic, name, /STREAMLINE, _EXTRA=ex, $
      LAYOUT=layout, GRAPHIC=graphic, WINDOW_TITLE='Streamline'
    1: Graphic, name, arg1, /STREAMLINE, _EXTRA=ex, $
      LAYOUT=layout, GRAPHIC=graphic, WINDOW_TITLE='Streamline'
    2: Graphic, name, arg1, arg2, /STREAMLINE, _EXTRA=ex, $
      LAYOUT=layout, GRAPHIC=graphic, WINDOW_TITLE='Streamline'
    3: Graphic, name, arg1, arg2, arg3, /STREAMLINE, _EXTRA=ex, $\
      LAYOUT=layout, GRAPHIC=graphic, WINDOW_TITLE='Streamline'
    4: Graphic, name, arg1, arg2, arg3, arg4, /STREAMLINE, _EXTRA=ex, $
      LAYOUT=layout, GRAPHIC=graphic, WINDOW_TITLE='Streamline'
  endcase

  return, graphic
end


;--------------------------------------------------------------------------
; This is the old STREAMLINE procedure. We need to define its call here,
; and route the call to our internal .pro routine. Otherwise IDL will never
; find the old procedure name.
;
pro streamline,inverts,conn,normals,outverts,outconn, _REF_EXTRA=ex
  compile_opt hidden
  on_error, 2
  streamline_internal,inverts,conn,normals,outverts,outconn, _EXTRA=ex
end

