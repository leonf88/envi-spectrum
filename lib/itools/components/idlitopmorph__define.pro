; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopmorph__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file is a superclass for the morphological operations.
;
; Written by: CT, RSI, April 2003
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopMorph object.
;
; Arguments:
;   None.
;
; Keywords:
;   STRUCTURE_SHAPE: The shape of the morphological structure.
;
;   STRUCTURE_WIDTH: The width (or diameter) of the structure array.
;
function IDLitopMorph::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(self->IDLitDataOperation::Init(NAME="Morph operator", $
        DESCRIPTION="IDL Morphological operators", $
        TYPES=['IDLARRAY2D','IDLROI'], $
        NUMBER_DS='1', $
        /SHOW_EXECUTION_UI, $
        _EXTRA=_extra) eq 0)then $
        return, 0

    if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
        self->Cleanup
        return, 0
    endif

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ; Register properties
    self->RegisterProperty, 'STRUCTURE_SHAPE', $
        NAME='Structure shape', $
        DESCRIPTION='Shape of the morphological structure', $
        ENUMLIST=['Square', 'Circle']

    self->RegisterProperty, 'STRUCTURE_WIDTH', /INTEGER, $
        NAME='Structure width', $
        Description='Width (or diameter) of the structure array', $
        VALID_RANGE=[1, 2147483646]

    ; Default values.
    self._structureWidth = 3

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopMorph::SetProperty, _EXTRA=_extra

    return, 1
end

;-------------------------------------------------------------------------
; Purpose:
;   The destructor for the IDLitopMorph class.
;
pro IDLitopMorph::Cleanup

    compile_opt idl2, hidden

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup
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
pro IDLitopMorph::GetProperty, $
    MINIMUM_DIMENSION=minDim, $
    STRUCTURE_SHAPE=structureShape, $
    STRUCTURE_WIDTH=structureWidth, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(minDim)) then $
        minDim = self._structureWidth

    if (ARG_PRESENT(structureWidth)) then $
        structureWidth = self._structureWidth

    if (ARG_PRESENT(structureShape)) then $
        structureShape = self._structureShape

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
pro IDLitopMorph::SetProperty,      $
    STRUCTURE_SHAPE=structureShape, $
    STRUCTURE_WIDTH=structureWidthIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(structureShape)) then $
        self._structureShape = structureShape

    if (N_ELEMENTS(structureWidthIn) ne 0) then begin
        structureWidth = LONG(structureWidthIn)
        if structureWidth lt 0 then $
            self->ErrorMessage, IDLitLangCatQuery('Error:Morph:WidthNonNeg'), $
            SEVERITY=2
        if (self._withinUI) then begin
            ; If we are displaying the UI, retrieve the data dimensions
            ; and restrict the property to be within the acceptable range.
            pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
            mx = MAX(dims)
            if (mx gt 0) then $
                structureWidth <= mx
        endif
        self._structureWidth = structureWidth
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Purpose:
;   Retrieve the structure array.
;
; Result:
;   Returns a 1, 2, or 3-dimensional array containing the structure.
;
; Arguments:
;   NDIM: The number of dimensions of the data to be operated on.
;       NDIM must be 1, 2, or 3.
;
; Keywords:
;   None.
;
function IDLitopMorph::_GetStructure, ndim

    compile_opt idl2, hidden

    ns = self._structureWidth

    case self._structureShape of

        0: begin      ; Square
            case ndim of
                1: return, REPLICATE(1b, ns)
                2: return, REPLICATE(1b, ns, ns)
                3: return, REPLICATE(1b, ns, ns, ns)
                else: return, 0 ; failure
            endcase
           end

        1: begin      ; Circle/Sphere
            case ndim of
                1: return, REPLICATE(1b, ns)
                2: begin
                    structure = BYTARR(ns, ns)
                    x = REBIN(FINDGEN(ns) - (ns-1)/2.0, ns, ns)
                    y = TRANSPOSE(x)
                    r = SQRT(x^2 + y^2)
                    insideCircle = WHERE(r lt ns/2.0, nInside)
                    if (nInside gt 0) then $
                        structure[insideCircle] = 1b
                    return, structure
                   end
                3: begin
                    structure = BYTARR(ns, ns, ns)
                    xi = FINDGEN(ns) - (ns-1)/2.0
                    x = REBIN(xi, ns, ns, ns)
                    y = REBIN(TRANSPOSE(xi), ns, ns, ns)
                    z = REBIN(REFORM(xi,1,1,ns), ns, ns, ns)
                    r = SQRT(x^2 + y^2 + z^2)
                    insideCircle = WHERE(r lt ns/2.0, nInside)
                    if (nInside gt 0) then $
                        structure[insideCircle] = 1b
                    return, structure
                   end
                else: return, 0 ; failure
            endcase

           end

        else: return, 0 ; failure

    endcase

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the raw data.
;
; Arguments:
;   Data: The array of data to be operated on.
;
; Keywords:
;   MASK: An array (matching the dimensions of the data) that represents
;     a mask to be applied.  Only the data pixels for which the corresponding
;     mask pixel is non-zero will be operated upon.
;
function IDLitopMorph::Execute, data, MASK=mask
    compile_opt idl2, hidden
    ; This is a stub.
    return, 0
end


;---------------------------------------------------------------------------
; Purpose:
;   Display the propertysheet before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation
;
function IDLitopMorph::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; Display dialog.
    return, oTool->DoUIService('OperationPreview', self)

end


;-------------------------------------------------------------------------
pro IDLitopMorph__define

    compile_opt idl2, hidden

    struc = {IDLitopMorph, $
             inherits IDLitDataOperation,      $
             inherits _IDLitROIPixelOperation, $
             _structureShape: 0L, $
             _structureWidth: 0L $
            }

end

