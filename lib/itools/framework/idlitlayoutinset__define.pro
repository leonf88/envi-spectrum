; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitlayoutinset__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitLayoutInset
;
; PURPOSE:
;    The IDLitLayoutInset class represents the view layout of a scene.
;
; MODIFICATION HISTORY:
;    Written by:    CT, Jan 2002
;-


;----------------------------------------------------------------------------
function IDLitLayoutInset::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitLayout::Init(_EXTRA=_extra) ne 1) then $
        return, 0

    return, 1
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro IDLitLayoutInset::GetProperty, $
    MAXCOUNT=maxcount, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Always return 2.
    if (ARG_PRESENT(maxcount) ne 0) then $
        maxcount = 2

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitLayout::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Purpose: Returns the viewport locations for a given view position.
; Overrides the superclass method.
;
; Arguments:
;   Position: Gives the zero-based position within the container.
;   Dimensions: Gives the [width, height] of the window.
;
function IDLitLayoutInset::GetViewport, position, dimensions

    compile_opt idl2, hidden

    ; Return the freeform layout position
    if (position gt 1) then $
        return, self->IDLitLayout::GetViewport(position, dimensions)

    case position of
        0: viewport = [0d, 0, dimensions]
        1: viewport = [0.5d, 0.5d, 0.45d, 0.45d]*[dimensions, dimensions]
    endcase

    return, viewport

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitLayoutInset__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitLayoutInset object.
;
;-
pro IDLitLayoutInset__define

    compile_opt idl2, hidden

    struct = {IDLitLayoutInset, $
        inherits IDLitLayout}

end

