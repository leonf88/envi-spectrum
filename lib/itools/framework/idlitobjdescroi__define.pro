; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitobjdescroi__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitObjDescROI
;
; PURPOSE:
;   This file implements the IDLitObjDescROI class. This class provides
;   an object descriptor that allows ROI object registration without the
;   need to instatiate an actual destination object.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitObjDescROI::Init
;
; PURPOSE:
;   This function method initializes the component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitObjDescROI')
;
;    or
;
;   Obj->[IDLitObjDescROI::]Init
;
; KEYWORD PARAMETERS:
;   ROI_TYPE:   Set this keyword to an integer that indicates the
;      type of ROI that this descriptor refers to.  Valid values include:
;          0 = Points
;          1 = Path
;          2 = Closed Polygon (default)
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
;-
function IDLitObjDescROI::Init, $
    ROI_TYPE=ROIType, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass.
    if (self->IDLitObjDescVis::Init( _EXTRA=_extra) eq 0) then $
        return, 0

    self._ROIType = 2L ; Closed polygon

    if (N_ELEMENTS(ROIType) ne 0) then $
        self._ROIType = ROIType[0]

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
;   Override our superclass method so we can also set the ROI_TYPE.
;
; Return Value:
;   An object of the type that is described by this object.
;
function IDLitObjDescROI::_InstantiateObject, _REF_EXTRA=_extra
    ; Pragmas.
    compile_opt idl2, hidden

    return, self->IDLitObjDescVis::_InstantiateObject( $
        ROI_TYPE=self._ROIType, _EXTRA=_extra)

end


;----------------------------------------------------------------------------
pro IDLitObjDescROI__Define
    ; Pragmas.
    compile_opt idl2, hidden

    void = {IDLitObjDescROI,           $
        inherits     IDLitObjDescVis,  $
        _ROIType   : 0L                $
    }
end
