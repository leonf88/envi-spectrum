; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopflipvertical__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Implements a data flip operation.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopFlipVertical object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitopFlipVertical::Init, _EXTRA=_extra
    ; Pragmas
    compile_opt idl2, hidden

    if (~self->IDLitDataOperation::Init(NAME="Veritical Flip", $
        DESCRIPTION="Flip data vertically", $
        TYPES=['IDLARRAY2D','IDLROI'], $
        NUMBER_DS='1', $
        _EXTRA=_extra)) then $
    return, 0

    if (~self->_IDLitROIVertexOperation::Init(_EXTRA=_extra)) then begin
        self->Cleanup
        return, 0
    endif

    return, 1
end

;---------------------------------------------------------------------------
; IDLitopFlipVertical::Cleanup
;
; Purpose:
;   This procedure method cleans up the flip vertical operation.
;
pro IDLitopFlipVertical::Cleanup
    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->_IDLitROIVertexOperation::Cleanup
    self->IDLitDataOperation::Cleanup
end

;---------------------------------------------------------------------------
; IDLitopFlipVertical::_ExecuteOnROI
;
; Purpose:
;   This function method executes the operation on the given ROI.
;
; Arguments:
;   oROI: A reference to the ROI visualization that is the target
;     of this operation.
;
; Keywords:
;   PARENT_IS_TARGET: Set this keyword to a non-zero value to indicate
;     that the parent is the actual target of the operation and that the
;     ROI should be handled accordingly.  By default (if this keyword is
;     not set), the ROI itself is the target of the operation.
;
function IDLitopFlipVertical::_ExecuteOnROI, oROI, $
    PARENT_IS_TARGET=parentIsTarget

    compile_opt idl2, hidden

    if (KEYWORD_SET(parentIsTarget)) then begin
        oROI->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->GetProperty, CENTER_OF_ROTATION=center
    endif

    oROI->_IDLitVisualization::Scale, 1, -1, 1, /PREMULTIPLY, $
        CENTER_OF_ROTATION=center

    return, 1
end

;---------------------------------------------------------------------------
; Purpose:
;   Execute the Image Flip operation
;
; Arguments:
;   Data: The array of data to flip.
;
; Keywords:
;   None.
;
function IDLitopFlipVertical::Execute, data

    compile_opt idl2, hidden

    data = rotate(temporary(data),7)
    return, 1

end


;-------------------------------------------------------------------------
pro IDLitopFlipVertical__define

    compile_opt idl2, hidden

    struc = {IDLitopFlipVertical,               $
             inherits IDLitDataOperation,       $
             inherits _IDLitROIVertexOperation  $
    }
end

