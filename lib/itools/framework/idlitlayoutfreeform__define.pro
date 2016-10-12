; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitlayoutfreeform__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitLayoutFreeform
;
; PURPOSE:
;    The IDLitLayoutFreeform class represents the view layout of a scene.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; METHODS:
;
; MODIFICATION HISTORY:
;    Written by:    CT, May 2002
;-


;----------------------------------------------------------------------------
function IDLitLayoutFreeform::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitLayout::Init(_EXTRA=_extra, ROWS=0, COLUMNS=0) ne 1) then $
        return, 0

    RETURN, 1
end


;---------------------------------------------------------------------------
;function IDLitLayoutFreeform::GetViewport, position
;    compile_opt idl2, hidden
    ; The superclass already does freeform.
;    return, self->IDLitLayout::GetViewport(position)
;end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitLayoutFreeform__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitLayoutFreeform object.
;
;-
pro IDLitLayoutFreeform__define

    compile_opt idl2, hidden

    struct = {IDLitLayoutFreeform, $
        inherits IDLitLayout}

end

