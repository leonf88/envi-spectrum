; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisidataspace__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisIDataSpace
;
; PURPOSE:
;   The IDLitVisIDataSpace class represents an interface for visualization
;   data space functionality.
;
;   It is intended that other framework components will sub-class from
;   this class and thereby identify themselves as implementing the
;   data space interface.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   None.
;
; CREATION:
;   See IDLitVisIDataSpace::Init
;
; METHODS:
; Intrinsic Methods
;   IDLitVisIDataSpace::Init
;   IDLitVisIDataSpace::Cleanup
;
; IIDLDataRangeObserver Interface
;   _IDLitVisualization::OnDataRangeChange
;
; MODIFICATION HISTORY:
;   Written by:
;-


;----------------------------------------------------------------------------
; IIDLDataSpace Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; IIDLDataRangeObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisIDataSpace::OnDataRangeChange
;
; PURPOSE:
;      The IDLitVisIDataSpace::OnDataRangeChange procedure method handles
;      notification of an XYZ range change.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIDataSpace::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject: A reference to the object sending notification of
;                the range change.
;      XRange:   A two-element vector, [xmin, xmax], representing
;                the X-axis range.
;      YRange:   A two-element vector, [ymin, ymax], representing
;                the Y-axis range.
;      ZRange:   A two-element vector, [zmin, zmax], representing
;                the Z-axis range.
;
;-
;pro IDLitVisIDataSpace::OnDataRangeChange, oSubject, XRange, YRange, ZRange
;    compile_opt idl2, hidden
;
;    ;
;    ; To be implemented by subclass.
;    ;
;
;end

;---------------------------------------------------------------------------
; Name:
;   IDLitVisIDataSpace::RequiresDouble
;
; Purpose:
;   This function method reports whether this dataspace range requires
;   double precision.
;
; Return value:
;   This function method returns a 1 if the dataspace requires double
;   precision, or 0 otherwise.
;
;function IDLitVisIDataSpace::RequiresDouble
;    compile_opt idl2, hidden
;
;    ; To be implemented by subclass!
;
;    return, 0b
;end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisIDataSpace__Define
;
; Purpose:
;   Defines the object structure for an IDLitVisIDataSpace object.
;-
pro IDLitVisIDataSpace__Define

    compile_opt idl2, hidden

    struct = { IDLitVisIDataSpace,  $
        _isaIDLitVisIDataSpace: 0b  $   ; we need something here
    }
end
