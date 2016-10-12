; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvismapprojection__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisMapProjection
;
; PURPOSE:
;    The IDLitVisMapProjection class is a helper class for viz objects with
;    map projection data.
;
; MODIFICATION HISTORY:
;     Written by:   CT, May 2004
;-


;----------------------------------------------------------------------------
function IDLitVisMapProjection::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->_IDLitVisualization::Init(NAME='Map Projection', $
        IMPACTS_RANGE=0, $
        /ISOTROPIC, $
        ICON='surface', $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitMapProjection::Init(_EXTRA=_extra)) then $
        return, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->SetPropertyAttribute, ['NAME', 'DESCRIPTION', 'HIDE'], /HIDE

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisMapProjection::SetProperty, _EXTRA=_extra

    return, 1 ; Success
end


;----------------------------------------------------------------------------
; IDLitVisMapProjection::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisMapProjection::Restore
    compile_opt idl2, hidden

    self->_IDLitVisualization::SetProperty, PRIVATE=0

    self->_IDLitVisualization::Restore
    self->_IDLitMapProjection::Restore
end


;----------------------------------------------------------------------------
pro IDLitVisMapProjection::GetProperty, $
    ENABLE_UPDATES=enableUpdates, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (Arg_Present(enableUpdates)) then $
        enableUpdates = ~self._disableUpdates
        
    if (N_Elements(_extra) gt 0) then begin
        self->_IDLitVisualization::GetProperty, _EXTRA=_extra
        self->_IDLitMapProjection::GetProperty, _EXTRA=_extra
    endif

end


;----------------------------------------------------------------------------
pro IDLitVisMapProjection::SetProperty, $
    ENABLE_UPDATES=enableUpdates, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(enableUpdates) gt 0) then begin
        self._disableUpdates = ~Keyword_Set(enableUpdates)
    endif
    
    if (N_Elements(_extra) gt 0) then begin
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra
        self->_IDLitMapProjection::SetProperty, _EXTRA=_extra
    endif

    if (~self._disableUpdates) then begin
        self->_IDLitVisualization::GetProperty, PARENT=oParent
        if (Obj_Isa(oParent, 'IDLitVisDataspace')) then begin
            oParent->OnProjectionChange
        endif
    endif
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisMapProjection__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisMapProjection object.
;
;-
pro IDLitVisMapProjection__Define

    compile_opt idl2, hidden

    struct = { IDLitVisMapProjection, $
        inherits _IDLitVisualization, $
        inherits _IDLitMapProjection, $
        _disableUpdates: 0b $
        }
end
