; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprotatedata__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the rotate data operation.
;
; Written by: CT, RSI, April 2003
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopRotateData object.
;
; Arguments:
;   None.
;
; Keywords:
;   WIDTH (Get, Set): The width of the median filter.
;
function IDLitopRotateData::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(self->IDLitDataOperation::Init(NAME="Rotate Data", $
        DESCRIPTION="IDL Rotate Data operation", $
        TYPES=["IDLARRAY2D"], $
        NUMBER_DS='1', $
        _EXTRA=_extra) eq 0)then $
        return, 0

    ; Register properties
    self->RegisterProperty, 'Angle', /FLOAT, $
        Description='Rotation angle', $
        VALID_RANGE=[-360,360]

    self->RegisterProperty, 'XCENTER', /FLOAT, $
        NAME='X center offset', $
        DESCRIPTION='X offset for the center of rotation (0=center)'

    self->RegisterProperty, 'YCENTER', /FLOAT, $
        NAME='Y center offset', $
        DESCRIPTION='Y offset for the center of rotation (0=center)'

    self->RegisterProperty, 'Magnification', /FLOAT, $
        Description='Magnification factor'

    self->RegisterProperty, 'METHOD', $
        NAME='Interpolation method', $
        DESCRIPTION='Interpolation method for rotation', $
        ENUMLIST=['Nearest neighbor', 'Bilinear', 'Cubic']

    self->RegisterProperty, 'EXTRAPOLATE', /BOOLEAN, $
        NAME='Extrapolate missing', $
        DESCRIPTION='Extrapolate missing values from the nearest pixel'

    self->RegisterProperty, 'MISSING', /FLOAT, $
        NAME='Missing value', $
        DESCRIPTION='Missing value to assign to points outside the bounds'

    self->RegisterProperty, 'Pivot', /BOOLEAN, $
        DESCRIPTION='Pivot about rotation point instead of center'

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ; Default values.
    self._extrapolate = 1b
    self._magnification = 1d

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopRotateData::SetProperty, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   Retrieve property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Get.
;
pro IDLitopRotateData::GetProperty, $
    ANGLE=angle,   $
    EXTRAPOLATE=extrapolate, $
    MAGNIFICATION=magnification, $
    METHOD=method, $
    MINIMUM_DIMENSION=minDim, $
    MISSING=missing, $
    PIVOT=pivot, $
    RELATIVE=relative, $
    XCENTER=xcenter, $
    YCENTER=ycenter, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(angle)) then $
        angle = self._angle

    if (ARG_PRESENT(extrapolate)) then $
        extrapolate = self._extrapolate

    if (ARG_PRESENT(magnification)) then $
        magnification = self._magnification

    if (ARG_PRESENT(method)) then $
        method = self._method

    if (ARG_PRESENT(minDim)) then $
        minDim = -1  ; we need entire array

    if (ARG_PRESENT(missing)) then $
        missing = self._missing

    if (ARG_PRESENT(pivot)) then $
        pivot = self._pivot

    ; Assume we are never doing a "relative" angle, but are always
    ; rotating the data as if it didn't have the concept of a
    ; current rotation angle.
    if (ARG_PRESENT(relative)) then $
        relative = 0b

    if (ARG_PRESENT(xcenter)) then $
        xcenter = self._xcenter

    if (ARG_PRESENT(ycenter)) then $
        ycenter = self._ycenter

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose:
;   Set property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Set.
;
pro IDLitopRotateData::SetProperty, $
    ANGLE=angle, $
    EXTRAPOLATE=extrapolate, $
    MAGNIFICATION=magnification, $
    METHOD=method, $
    MISSING=missing, $
    PIVOT=pivot, $
    XCENTER=xcenter, $
    YCENTER=ycenter, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(angle)) then begin
        self._angle = angle
        self._angle = self._angle mod 360
        if (self._angle gt 180) then $
            self._angle -= 360
        if (self._angle lt -180) then $
            self._angle += 360
    endif

    if (N_ELEMENTS(extrapolate)) then $
        self._extrapolate = extrapolate

    if (N_ELEMENTS(magnification)) then $
        self._magnification = magnification

    if (N_ELEMENTS(method)) then $
        self._method = method

    if (N_ELEMENTS(missing)) then $
        self._missing = missing

    if (N_ELEMENTS(pivot)) then $
        self._pivot = pivot

    if (N_ELEMENTS(xcenter)) then $
        self._xcenter = xcenter

    if (N_ELEMENTS(ycenter)) then $
        self._ycenter = ycenter

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Purpose:
;   Display rotate data UI before execution.
;
; Result:
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
Function IDLitopRotateData::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    return, oTool->DoUIService('OperationPreview', self)

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the raw data.
;
; Arguments:
;   Data: The array of data to be operated on.
;
; Keywords:
;   None.
;
function IDLitopRotateData::Execute, data

    compile_opt idl2, hidden

    dims = SIZE(data, /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2) then $
        return, 0

    ; Convert from our METHOD property to the actual ROT keywords.
    case self._method of
        0: ; do nothing
        1: interp = 1   ; bilinear
        2: cubic = -0.5 ; cubic
    endcase

    ; Don't allow zero magnification.
    magnification = (self._magnification ne 0) ? self._magnification : 1

    ; Note that our XCENTER and YCENTER are relative to the center
    ; of the image.
    x0 = dims[0]/2 + self._xcenter
    y0 = dims[1]/2 + self._ycenter

    ; Only provide missing value if we aren't extrapolating nearby pixels.
    if (~self._extrapolate) then $
        missing = self._missing

    ; We will follow the other rotation conventions, and define the
    ; angle to be counterclockwise. So reverse the sign.
    data = ROT(data, -self._angle, magnification, x0, y0, $
        CUBIC=cubic, $
        INTERP=interp, $
        MISSING=missing, $
        PIVOT=pivot)

    return, 1   ; success

end


;-------------------------------------------------------------------------
pro IDLitopRotateData__define

    compile_opt idl2, hidden

    struc = {IDLitopRotateData, $
             inherits IDLitDataOperation,    $
             _angle:    0d, $
             _magnification: 0d, $
             _missing:  0d, $
             _xcenter:  0d, $
             _ycenter:  0d, $
             _extrapolate: 0b, $
             _method:   0b, $
             _pivot:    0b $
            }

end

