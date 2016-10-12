; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;------------------------------------------------------------------------
;+
; :Description:
;    Initialize the object.
;
; :Params:
;
; :Keywords:
;    _EXTRA
;
;-
function GraphicsBuffer::Init, _EXTRA=_extra
    
  compile_opt idl2, hidden
  
  if (~self->Graphic::Init(self)) then return, 0
  if (~self->IDLitgrBuffer::Init(_EXTRA=_extra)) then return, 0
  return, 1
end


;------------------------------------------------------------------------
pro GraphicsBuffer::Cleanup
  compile_opt idl2, hidden
  
  self->IDLitgrBuffer::Cleanup
end


;---------------------------------------------------------------------------
pro GraphicsBuffer::GetProperty, _REF_EXTRA=ex
  compile_opt idl2, hidden
  self->Graphic::GetProperty, _EXTRA=ex
  self->IDLitgrBuffer::GetProperty, _EXTRA=ex
end


;---------------------------------------------------------------------------
pro GraphicsBuffer::SetProperty, _EXTRA=ex
  compile_opt idl2, hidden
  self->Graphic::SetProperty, _EXTRA=ex
  self->IDLitgrBuffer::SetProperty, _EXTRA=ex
end


;------------------------------------------------------------------------
pro GraphicsBuffer__define
  compile_opt idl2, hidden
  
  void = {GraphicsBuffer, $
    inherits Graphic, $
    inherits IDLitgrBuffer $
    }
    
end

