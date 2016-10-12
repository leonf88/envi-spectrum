; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisshapepolygon__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisShapePolygon
;
; PURPOSE:
;    The IDLitVisShapePolygon class implements a a polygon visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisPolygon
;
;-


;----------------------------------------------------------------------------
; IDLitVisShapePolygon::Init
;
; Purpose:
;   Initialization routine of the object.
;
; Parameters:
;   None.
;
; Keywords:
;   NAME   - The name to associated with this item.
;
;   Description - Short string that will describe this object.
;
;   All other keywords are passed to th super class
;
function IDLitVisShapePolygon::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisPolygon::Init( $
        NAME="Shape Polygon", $
        DESCRIPTION="Polygon shapes", $
        TYPE='IDLSHAPEPOLYGON', $
        ICON='drawing', $
        FILL_BACKGROUND=0, $
        SELECTION_PAD=5, $
        /IMPACTS_RANGE, $
        /NO_CLOSE, $
        /ISOTROPIC, $
        /TESSELLATE, $
        _EXTRA=_extra))then $
        return, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    ; These were desensitized because we set fill background to 0.
    ; Resensitize them so they show up correctly in the Style Editor.
    ; When a new Shape is created, these will automatically
    ; be desensitized by PlaybackProperties.
    self->IDLitVisPolygon::SetPropertyAttribute, $
        ['FILL_COLOR', 'TRANSPARENCY'], $
        /SENSITIVE

    self->RegisterParameter, 'ATTRIBUTES', $
        DESCRIPTION='Shapefile attributes', $
        TYPES='IDLSHAPEATTRIBUTES', $
        /INPUT, /OPTIONAL

    ; The SHAPES parameter is a vector, each element of which
    ; is the starting index within the CONNECTIVITY of the
    ; next shape. This allows multiple shapes to be stored
    ; within a single parameter set, but still have the
    ; IDLitVisPolygon tessellate them separately.
    self->RegisterParameter, 'SHAPES', $
        DESCRIPTION='Shapefile shape list', $
        TYPES='IDLSHAPES', $
        /INPUT, /OPTIONAL

    self->SetParameterAttribute, 'VERTICES', $
        TYPES=['IDLVERTEX', 'IDLSHAPEPOLYGON']

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisShapePolygon::SetProperty, _EXTRA=_extra

    return, 1 ; Success
end


;----------------------------------------------------------------------------
pro IDLitVisShapePolygon::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisShapePolygon::SetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitVisShapePolygon::OnDataChangeUpdate
;
; Purpose:
;   This method is called by the framework when the data associated
;   with this object is modified or initially associated.
;
; Parameters:
;   oSubject   - The data object of the parameter that changed. if
;                parmName is "<PARAMETER SET>", this is an
;                IDLitParameterSet object
;
;   parmName   - The name of the parameter that changed.
;
; Keywords:
;   None.
;
pro IDLitVisShapePolygon::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    ; We don't need to do anything right now, other than
    ; call OnProjectionChange at the end.

    case STRUPCASE(parmName) of

    '<PARAMETER SET>': begin
        oSubject->IDLitComponent::GetProperty, $
            NAME=name, DESCRIPTION=description
        self->IDLitVisPolygon::SetProperty, NAME=name, $
            DESCRIPTION=description
        end

;    'ATTRIBUTES': begin
;        if (~oSubject->GetData(attr)) then $
;            break
;        end

    else:

    endcase

    self->OnProjectionChange, sMap

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
pro IDLitVisShapePolygon__Define

    compile_opt idl2, hidden

    struct = { IDLitVisShapePolygon,           $
               inherits IDLitVisPolygon $
             }
end
