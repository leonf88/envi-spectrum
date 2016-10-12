; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisbackground__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisBackground
;
; PURPOSE:
;    The IDLitVisBackground class is used for the background walls.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisPolygon
;
; SUBCLASSES:
;
; METHODS:
;  Intrinisic Methods
;    IDLitVisBackground::Cleanup
;    IDLitVisBackground::Init
;
; MODIFICATION HISTORY:
;     Written by:   CT, Jan 2003
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisBackground::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisBackground')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLitVisPolygon
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitVisBackground::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    success = self->IDLitVisPolygon::Init(NAME='IDLitVisBackground', $
        FILL_COLOR=[255,255,200], $
        ICON='rectangl_active', $
        IMPACTS_RANGE=0, $
        LINESTYLE=6, $
        /PRIVATE, $
        TRANSPARENCY=100, $
        TYPE='IDLBACKGROUND', $
        DEPTH_OFFSET=1, REJECT=1, _EXTRA=_EXTRA)

    ; Request no (additional) axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->SetPropertyAttribute, ['USE_BOTTOM_COLOR', 'BOTTOM'], /HIDE
    return, success

end

;----------------------------------------------------------------------------
; IDLitVisBackground::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisBackground::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
    endif
end

;----------------------------------------------------------------------------
; METHODNAME:
;   IDLitVisBackground::GetHitVisualization
;
; PURPOSE:
;   Overrides the default method, and returns the dataspace associated
;   with this background.
;
function IDLitVisBackground::GetHitVisualization, oSubHitList

    compile_opt idl2, hidden

    return, self->GetDataSpace()
end


;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisBackground::GetDataString, xyz

    compile_opt idl2, hidden

    oDS = self->GetDataSpace(/UNNORMALIZED)

    if OBJ_VALID(oDS) then begin
        ; Our dataspace method knows whether it is 3D, logarithmic, etc.
        return, oDS->GetDataString(xyz)
    endif

    return, '' ; failure

end


;---------------------------------------------------------------------------
; Override SetProperty so we can cache our XY range,
; for use in GetDataString.
;
pro IDLitVisBackground::SetProperty, $
    DATA=data, $
    POLYGONS=polygons, $
    POLYLINES=polylines, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(data) gt 0) then begin
        bad = WHERE(~FINITE(data), nbad)
        if (nbad gt 0) then $
            data[bad] = 0
        xyzmin = MIN(data, DIMENSION=2, MAX=xyzmax)
        self._xrange = [xyzmin[0], xyzmax[0]]
        self._yrange = [xyzmin[1], xyzmax[1]]
    endif

    ; Manually handle the data keywords so we can pass them directly
    ; to our visualizations. That way we avoid creating data objects.
    if (N_ELEMENTS(data) || $
        N_ELEMENTS(polygons) || N_ELEMENTS(polylines)) then begin
        self._calcFill = 1b
        self._oPolygon->SetProperty, DATA=data, POLYGONS=polygons
        self._oLine->SetProperty, DATA=data, POLYLINES=polylines
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; Override the superclass so we can do nothing. We've already set
; the data in the SetProperty, and we don't want to be affected by
; map projections.
;
pro IDLitVisBackground::_UpdateData, sMap

    compile_opt idl2, hidden

;    do nothing

end


;----------------------------------------------------------------------------
; Override the superclass so we can do nothing. We've already set
; the data in the SetProperty, and we don't want to be affected by
; map projections.
;
pro IDLitVisBackground::OnProjectionChange, sMap

    compile_opt idl2, hidden

;    do nothing

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisBackground__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisBackground object.
;
;-
pro IDLitVisBackground__Define

    compile_opt idl2, hidden

    struct = { IDLitVisBackground,           $
               inherits IDLitVisPolygon, $
               _xrange: [0d, 0d], $
               _yrange: [0d, 0d] $
             }
end
