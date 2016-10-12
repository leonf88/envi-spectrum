; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitlayouttrio__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitLayoutTrio
;
; PURPOSE:
;    The IDLitLayoutTrio class represents the view layout of a scene.
;
; MODIFICATION HISTORY:
;    Written by:    CT, Jan 2002
;-


;----------------------------------------------------------------------------
function IDLitLayoutTrio::Init, $
    TRIO_TYPE=triotype, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitLayout::Init(_EXTRA=_extra) ne 1) then $
        return, 0

    ; Default is zero.
    if (N_ELEMENTS(triotype) eq 1) then $
        self._triotype = triotype

    return, 1
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro IDLitLayoutTrio::GetProperty, $
    MAXCOUNT=maxcount, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Always return 2.
    if (ARG_PRESENT(maxcount) ne 0) then $
        maxcount = 3

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
function IDLitLayoutTrio::GetViewport, position, dimensions

    compile_opt idl2, hidden

    ; Return the freeform layout position
    if (position gt 2) then $
        return, self->IDLitLayout::GetViewport(position, dimensions)


    ; self._triotype:
    ;   0 = Top is big
    ;   1 = Bottom
    ;   2 = Left
    ;   3 = Right

    ; Round off to nearest even numbers.
    nx2 = DOUBLE(LONG(dimensions[0]/2))
    ny2 = DOUBLE(LONG(dimensions[1]/2))
    nx = nx2*2d
    ny = ny2*2d


    case position of

        ; Position=0 is always the big view.
        0: case self._triotype of
            0: viewport = [0, ny2, nx, ny2]
            1: viewport = [0, 0, nx, ny2]
            2: viewport = [0, 0, nx2, ny]
            3: viewport = [nx2, 0, nx2, ny]
           endcase

        ; Position=1 is always the first small view.
        1: case self._triotype of
            0: viewport = [0, 0, nx2, ny2]
            1: viewport = [0, ny2, nx2, ny2]
            2: viewport = [nx2, 0, nx2, ny2]
            3: viewport = [0, 0, nx2, ny2]
           endcase

        ; Position=2 is always the second small view.
        2: case self._triotype of
            0: viewport = [nx2, 0, nx2, ny2]
            1: viewport = [nx2, ny2, nx2, ny2]
            2: viewport = [nx2, ny2, nx2, ny2]
            3: viewport = [0, ny2, nx2, ny2]
           endcase

    endcase

    return, viewport

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitLayoutTrio__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitLayoutTrio object.
;
;-
pro IDLitLayoutTrio__define

    compile_opt idl2, hidden

    struct = {IDLitLayoutTrio, $
        inherits IDLitLayout, $
        _triotype: 0}

end

