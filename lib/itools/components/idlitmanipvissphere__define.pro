; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvissphere__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipVisSphere
;
; PURPOSE:
;   The IDLitManipVisSphere class is the sphere selection visual.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLgrModel
;
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipVisSphere::Init
;
; PURPOSE:
;   The IDLitManipVisSphere::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitManipVisSphere')
;
;   or
;
;   Obj->[IDLitManipVisSphere::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-
function IDLitManipVisSphere::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Sphere Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init(NAME=name, $
        VISUAL_TYPE='Rotate3D') ne 1) then $
        return, 0


    ; Construct a sphere.
    radius = SQRT(2)
    sphere = FLTARR(19,10) + radius
    MESH_OBJ, 4, vertices, polygons, sphere, /CLOSE
    tmp = MESH_VALIDATE(vertices, polygons, /COMBINE_VERTICES)
    n = N_ELEMENTS(vertices)/3


    image = BYTARR(2,2,2)
    image[0,*,*] = 255  ; color
    image[1,*,*] = 0    ; alpha value 0...255

    self.oImage = OBJ_NEW('IDLgrImage', image, $
        BLEND=[3,4], $
        INTERLEAVE=0)

    self.oSphere = OBJ_NEW('IDLgrPolygon', $
        COLOR=[255,255,255], $
        DATA=vertices, $
        POLYGONS=polygons, $
        TEXTURE_COORD=vertices[0:1,*], $
        TEXTURE_MAP=self.oImage)
    self->Add, self.oSphere

    ; Set any properties.
    self->SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisSphere::Cleanup
;
; PURPOSE:
;      The IDLitManipVisSphere::Cleanup procedure method preforms all cleanup
;      on the object.
;
;      NOTE: Cleanup methods are special lifecycle methods, and as such
;      cannot be called outside the context of object destruction.  This
;      means that in most cases, you cannot call the Cleanup method
;      directly.  There is one exception to this rule: If you write
;      your own subclass of this class, you can call the Cleanup method
;      from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, Obj
;
;   or
;
;   Obj->[IDLitManipVisSphere::]Cleanup
;
; INPUTS:
;   There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;   There are no keywords for this method.
;
;-
pro IDLitManipVisSphere::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self.oImage
    ; Cleanup superclasses.
    self->IDLitManipulatorVisual::Cleanup
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisSphere::GetProperty
;
; PURPOSE:
;      The IDLitManipVisSphere::GetProperty procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitManipVisSphere::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitManipVisSphere::Init followed by the word "Get"
;      can be retrieved using IDLitManipVisSphere::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
PRO IDLitManipVisSphere::GetProperty, $
    _REF_EXTRA=super


    compile_opt idl2, hidden

;    if ARG_PRESENT(select_target) then $
;        select_target = self.isSelectTarget

    ; get superclass properties
    self->IDLitManipulatorVisual::GetProperty, _EXTRA=super

END

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisSphere::SetProperty
;
; PURPOSE:
;      The IDLitManipVisSphere::SetProperty procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitManipVisSphere::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitManipVisSphere::Init followed by the word "Set"
;      can be set using IDLitManipVisSphere::SetProperty.
;-
PRO IDLitManipVisSphere::SetProperty, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

;    if (N_ELEMENTS(select_target) gt 0) then $
;        self.isSelectTarget = KEYWORD_SET(select_target)

    self.oSphere->SetProperty, _EXTRA=super

; Set superclass properties
    self->IDLitManipulatorVisual::SetProperty, _EXTRA=super

END


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisSphere__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisSphere object.
;-
pro IDLitManipVisSphere__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisSphere, $
        INHERITS IDLitManipulatorVisual, $
        oSphere: OBJ_NEW(), $
        oImage: OBJ_NEW() $
        }
end
