; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitlayout__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitLayout
;
; PURPOSE:
;    The IDLitLayout class represents the view layout of a scene.
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
;    Written by:    CT, Jan 2003
;-


;----------------------------------------------------------------------------
function IDLitLayout::Init, $
    COLUMNS=columns, $
    ROWS=rows, $
    GRIDDED=gridded, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Set defaults.
    self._rows = (N_ELEMENTS(columns) eq 1) ? columns : 1L
    self._columns = (N_ELEMENTS(rows) eq 1) ? rows : 1L
    self._gridded = KEYWORD_SET(gridded)

    if (self->IDLitComponent::Init(_EXTRA=_extra) ne 1) then $
        return, 0

    self->IDLitLayout::SetProperty, _EXTRA=_extra

    RETURN, 1
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro IDLitLayout::GetProperty, $
    COLUMNS=columns, $
    GRIDDED=gridded, $
    LOCKGRID=lockgrid, $
    ROWS=rows, $
    MAXCOUNT=maxcount, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(columns) ne 0) then $
        columns = self._columns

    if (ARG_PRESENT(gridded) ne 0) then $
        gridded = self._gridded

    if (ARG_PRESENT(lockgrid) ne 0) then $
        lockgrid = self._lockgrid

    if (ARG_PRESENT(rows) ne 0) then $
        rows = self._rows

    if (ARG_PRESENT(maxcount) ne 0) then $
        maxcount = self._columns*self._rows

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Cannot set MAXCOUNT or GRIDDED.
;
pro IDLitLayout::SetProperty, $
    COLUMNS=columns, $
    LOCKGRID=lockgrid, $
    ROWS=rows, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(lockgrid) ne 0) then $
        self._lockgrid = lockgrid

    if ((N_ELEMENTS(columns) ne 0) and (not self._lockgrid)) then $
        self._columns = columns

    if ((N_ELEMENTS(rows) ne 0) and (not self._lockgrid)) then $
        self._rows = rows

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; This method should be overridden by the subclass.
;
function IDLitLayout::GetViewport, position, dimensions

    compile_opt idl2, hidden

    ; Always make the view 1/2 the screen.
    ; Stagger the views diagonally, then across.
    offset = (position mod 11)/20d
    pos = [offset + LONG(position/11d)/20d, 0.5 - offset]*dimensions
    dims = [0.5, 0.5]*dimensions
    return, [pos, dims]

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitLayout__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitLayout object.
;
;-
pro IDLitLayout__define

    compile_opt idl2, hidden

    struct = {IDLitLayout, $
        inherits IDLitComponent, $
        _columns: 0L, $   ; number of columns
        _rows: 0L, $      ; number of rows
        _gridded: 0b, $   ; true if gridded or not
        _lockgrid: 0b $   ; true if grid cannot be changed
        }

end

