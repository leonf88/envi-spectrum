; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisshapepolyline__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisShapePolyline
;
; PURPOSE:
;    The IDLitVisShapePolyline class implements a a polygon visualization
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
; IDLitVisShapePolyline::Init
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
function IDLitVisShapePolyline::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisPolyline::Init( $
        NAME="Shape Polyline", $
        DESCRIPTION="Polyline shapes", $
        TYPE='IDLSHAPEPOLYLINE', $
        ICON='drawing', $
        /IMPACTS_RANGE, $
        /ISOTROPIC, $
        /_NO_VERTEX_VISUAL, $
        SELECTION_PAD=5, $
        _EXTRA=_extra))then $
        return, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    self->RegisterParameter, 'ATTRIBUTES', $
        DESCRIPTION='Shapefile attributes', $
        TYPES='IDLSHAPEATTRIBUTES', $
        /INPUT, /OPTIONAL

    self->SetParameterAttribute, 'VERTICES', $
        TYPES=['IDLVERTEX', 'IDLSHAPEPOLYLINE']

    self->SetPropertyAttribute, ['ARROW_STYLE', 'ARROW_SIZE'], /HIDE, $
      ADVANCED_ONLY=0

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisShapePolyline::SetProperty, _EXTRA=_extra

    return, 1 ; Success
end


;----------------------------------------------------------------------------
pro IDLitVisShapePolyline::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolyline::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisShapePolyline::SetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolyline::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitVisShapePolyline::OnDataChangeUpdate
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
pro IDLitVisShapePolyline::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    ; We don't need to do anything right now, other than
    ; call OnProjectionChange at the end.

    case STRUPCASE(parmName) of

    '<PARAMETER SET>': begin
        oSubject->IDLitComponent::GetProperty, $
            NAME=name, DESCRIPTION=description
        self->IDLitComponent::SetProperty, NAME=name, $
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
pro IDLitVisShapePolyline__Define

    compile_opt idl2, hidden

    struct = { IDLitVisShapePolyline,    $
               inherits IDLitVisPolyline $
             }
end
