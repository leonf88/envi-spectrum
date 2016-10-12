; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisrotateaxis__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRotateAxis class is the rotate axis manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRotateAxis')
;
;   or
;
;   Obj->[IDLitManipVisRotateAxis::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisRotateAxis::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? $
        inName : "Rotate Axis Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init(/SELECT_TARGET) ne 1) then $
        RETURN, 0

    ; Make the ribbon white so it obscures the circle.
    ; Reject polygons whose normals point towards the viewer.
    self.width = 0.01d
    self.oRibbon = OBJ_NEW('IDLgrPolygon', $
        BOTTOM=[255,255,255], $
        COLOR=[255,255,255], $
        REJECT=2, $
        /SHADING)
    self.oCircle = OBJ_NEW('IDLgrPolyline', $
        THICK=2)
    self->IDLitManipVisRotateAxis::_Update
    self->Add, self.oRibbon
    self->Add, self.oCircle

    ; Set any properties.
    self->IDLitManipVisRotateAxis::SetProperty, _EXTRA=_extra

    RETURN, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitManipVisRotateAxis::Cleanup
;    compile_opt idl2, hidden
    ; Cleanup superclasses.
;    self->IDLitManipulatorVisual::Cleanup
;end


;----------------------------------------------------------------------------
pro IDLitManipVisRotateAxis::_Show

    compile_opt idl2, hidden

    ; Find the layer in which this visual resides.
    oParent = self
    while (OBJ_VALID(oParent)) do begin
        oParent->GetProperty, _PARENT=_parent
        oParent = _parent
        if (OBJ_ISA(oParent, 'IDLitgrLayer')) then break
    endwhile

    ; Set the ribbon to be the background color of the layer.
    if OBJ_ISA(oParent, 'IDLitgrLayer') then begin

        oParent->GetProperty, COLOR=color, TRANSPARENT=transparent

        ; If the layer is transparent, change the color to white. We could
        ; change it to gray, but we're assuming that it is actually
        ; on top of another layer, which we hope is white.
        if (transparent) then $
            color = [255, 255, 255]

        self.oRibbon->SetProperty, COLOR=color, BOTTOM=color

    endif

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisRotateAxis::_Update
;
; PURPOSE:
;      This private procedure method updates the polygons and polylines.
;
; CALLING SEQUENCE:
;      Obj->[IDLitManipVisRotateAxis::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitManipVisRotateAxis::Init followed by the word "Get"
;      can be retrieved using IDLitManipVisRotateAxis::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
PRO IDLitManipVisRotateAxis::_Update

    compile_opt idl2, hidden

    ; Construct a circle.
    n = 100
    radius = 1;SQRT(2.0)
    t = FINDGEN(1,n)/n*2*!PI
    xcircle = radius*COS(t)
    ycircle = radius*SIN(t)

    ; Duplicate the coordinates, for the Z dimension.
    xData = REFORM([xcircle, xcircle], 1, 2*n)
    yData = REFORM([ycircle, ycircle], 1, 2*n)

    ; "Width" of the ribbon.
    dz = FLTARR(1, n) + self.width
    zData = REFORM([-dz, +dz], 1, 2*n)

    ; Construct the circular ribbon.
    index = LINDGEN(1,n-1)*2
    polygons = [LONARR(1,n-1)+4, index+2, index+3, index+1, index]
    polygons = [[polygons], $
        [4L, 0, 1, 2*(n-1)+1, 2*(n-1)]]
    polygons = REFORM(TEMPORARY(polygons), 5*n)

    ; Make the ribbon slightly smaller than the circle.
    ; This allows it to block the back of the circle, but not the front.
    self.oRibbon->SetProperty, $
        DATA=[xData*0.995, yData*0.995, zData], $
        POLYGONS=polygons

    ; Now construct the edge lines. These are needed for visibility
    ; when the ribbon is "edge on".
    polylines =[n+1, INDGEN(n), 0]
    self.oCircle->SetProperty, $
        DATA=[xcircle,ycircle], $
        POLYLINES=polylines

;    index = REFORM(index, n-1)
;    polylines =[n, index, 0, n, index + 1, 1]
;    self.oCircle->SetProperty, $
;        DATA=[xData, yData, zData], $
;        POLYLINES=polylines

END

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisRotateAxis::GetProperty
;
; PURPOSE:
;      The IDLitManipVisRotateAxis::GetProperty procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitManipVisRotateAxis::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitManipVisRotateAxis::Init followed by the word "Get"
;      can be retrieved using IDLitManipVisRotateAxis::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
PRO IDLitManipVisRotateAxis::GetProperty, $
    WIDTH=width, $
    _REF_EXTRA=super


    compile_opt idl2, hidden

    if ARG_PRESENT(width) then $
        width = self.width

    self.oCircle->GetProperty, _EXTRA=super

    ; get superclass properties
    self->IDLitManipulatorVisual::GetProperty, _EXTRA=super

END

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitManipVisRotateAxis::SetProperty
;
; PURPOSE:
;      The IDLitManipVisRotateAxis::SetProperty procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitManipVisRotateAxis::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitManipVisRotateAxis::Init followed by the word "Set"
;      can be set using IDLitManipVisRotateAxis::SetProperty.
;-
PRO IDLitManipVisRotateAxis::SetProperty, $
    HIDE=hide, $
    WIDTH=width, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    if (N_ELEMENTS(width) gt 0) then begin
        self.width = width
        self->_Update
    endif

;    self.oRibbon->SetProperty, _EXTRA=super
    self.oCircle->SetProperty, _EXTRA=super

; Set superclass properties
    self->IDLitManipulatorVisual::SetProperty, $
        HIDE=hide, $
        _EXTRA=super

    if (N_ELEMENTS(hide) gt 0) then if (hide eq 0) then $
        self->_Show

END


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisRotateAxis__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisRotateAxis object.
;-
pro IDLitManipVisRotateAxis__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRotateAxis, $
        INHERITS IDLitManipulatorVisual, $
        width: 0d, $
        oRibbon: OBJ_NEW(), $
        oCircle: OBJ_NEW() $
        }
end
