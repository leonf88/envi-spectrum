; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitlayoutgrid__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitLayoutGrid
;
; PURPOSE:
;    The IDLitLayoutGrid class represents the view layout of a scene.
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
function IDLitLayoutGrid::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitLayout::Init(_EXTRA=_extra, /GRIDDED) ne 1) then $
        return, 0

    return, 1
end


;---------------------------------------------------------------------------
function IDLitLayoutGrid::GetViewport, position, dimensions

    compile_opt idl2, hidden

    ; Return the freeform layout position
    if (position ge self._columns*self._rows) then $
        return, self->IDLitLayout::GetViewport(position, dimensions)


    ; X, Y position within grid.
    column = position mod self._columns
    row = position/self._columns

    width = LONG(dimensions[0]/self._columns)
    height = LONG(dimensions[1]/self._rows)
    return, [column*width, (self._rows - row - 1)*height, width, height]

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitLayoutGrid__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitLayoutGrid object.
;
;-
pro IDLitLayoutGrid__define

    compile_opt idl2, hidden

    struct = {IDLitLayoutGrid, $
        inherits IDLitLayout}

end

