; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopcropimagegrid__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Class Name:
;   IDLitopCropImageGrid
;
; Purpose:
;   This class implements an ImageGrid cropping operation.
;

;----------------------------------------------------------------------------
; Lifecycle Routines
;----------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitopCropImageGrid::Init
;
; Purpose:
;   This function method initializes the component object.
;
; Return Value:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
function IDLitopCropImageGrid::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitDataOperation::Init(NAME="Crop Image Grid", $
        DESCRIPTION="Crop Image Grid", $
        TYPES=['IDLVECTOR'], $
        SHOW_EXECUTION_UI=0, $
        _EXTRA=_extra)

    return, success

end

;-------------------------------------------------------------------------
; IDLitopCropImageGrid::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopCropImageGrid::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitDataOperation::Cleanup
;end

;----------------------------------------------------------------------------
; Property Interface
;----------------------------------------------------------------------------
;---------------------------------------------------------------------------
; IDLitopCropImageGrid::GetProperty
;
; Purpose:
;   This procedure method retrieves the value(s) of one or more properties.
;
pro IDLitopCropImageGrid::GetProperty, $
    HEIGHT=height, $
    TARGET=target, $
    WIDTH=width, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(height)) then $
        height = self._height

    if (ARG_PRESENT(width)) then $
        width = self._width

    if (ARG_PRESENT(x)) then $
        x = self._x0

    if (ARG_PRESENT(y)) then $
        y = self._y0

    if (ARG_PRESENT(target)) then $
        target = self._oTarget

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitopCropImageGrid::SetProperty
;
; Purpose:
;   This procedure method sets the value(s) of one or more properties.
;
pro IDLitopCropImageGrid::SetProperty, $
    HEIGHT=height, $
    TARGET=target, $
    WIDTH=width, $
    X=x, $
    Y=y, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Note: presume that contraining to target is handled elsewhere.
    if (N_ELEMENTS(x) gt 0) then $
        self._x0 = x

    if (N_ELEMENTS(y) gt 0) then $
        self._y0 = y

    if (N_ELEMENTS(height) gt 0) then $
        self._height = height

    if (N_ELEMENTS(width) gt 0) then $
        self._width = width

    if (N_ELEMENTS(target) gt 0) then $
        self._oTarget = target

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; IDLitopCropImageGrid::_ExecuteOnTarget
;
; Purpose:
;  Internal routine called to execute a crop ImageGrid operation
;  on a particular target.
;
; Parameter:
;   oTarget          - What to apply the operation on.
;
;   oCommandSet      - The command set for this operation execution.
;
function IDLitopCropImageGrid::_ExecuteOnTarget, oTarget, oCommandSet

    compile_opt idl2, hidden

    if (~OBJ_ISA(oTarget, 'IDLitParameter')) then $
        return, 0
    if (~OBJ_ISA(oTarget, '_IDLitVisGrid2D')) then $
        return, 0

    nDataExecutes = 0

    ; Do the X and Y parameters in turn as available.
    oTarget->_IDLitVisGrid2D::GetProperty, X_DATA_ID=xDataID, $
        Y_DATA_ID=yDataID

    oXDataObj = oTarget->GetParameter(xDataID)
    if (OBJ_VALID(oXDataObj)) then begin
        self._cropIndex = 0

        if (~self->_ExecuteOnData(oXDataObj, $
            COMMAND_SET=oCommandSet, $
            TARGET_VISUALIZATION=oTarget)) then $
            return, 0
        nDataExecutes = nDataExecutes + 1
    endif

    oYDataObj = oTarget->GetParameter(yDataID)
    if (OBJ_VALID(oYDataObj)) then begin
        self._cropIndex = 1

        if (~self->_ExecuteOnData(oYDataObj, $
            COMMAND_SET=oCommandSet, $
            TARGET_VISUALIZATION=oTarget)) then $
            return, 0
        nDataExecutes = nDataExecutes + 1
    endif

    return, (nDataExecutes gt 0)  ; success (1) or failure (0)
end


;---------------------------------------------------------------------------
; IDLitopCropImageGrid::DoAction
;
; Purpose:
;   This function method performs a Crop ImageGrid operation on all supported data
;   objects for the selected visualizations within the given tool.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oTool:	A reference to the tool in which this operation is occurring.
;
function IDLitopCropImageGrid::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if (~OBJ_VALID(oTool)) then $
        return, OBJ_NEW()

    ; This operation is a bit unique in that it depends upon
    ; another operation (crop image) to set its target.  If
    ; this has not occurred, then bail.
    if (~OBJ_VALID(self._oTarget)) then $
        return, OBJ_NEW()

    ; Get a commmand set for this operation from the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Perform the actual data operation.
    iStatus = self->DoDataOperation(oTool, oCommandSet, self._oTarget)

    ; Did the operation fail for the target?
    if (iStatus eq 0) then begin
        ; We should already have performed an UndoOperation (in the loop),
        ; so just destroy our command set.
        OBJ_DESTROY, oCommandSet
        oCommandSet = OBJ_NEW()
    endif

    if (~wasDisabled) then $
        oTool->EnableUpdates

    ; Return command set.
    return, oCommandSet

end

;---------------------------------------------------------------------------
function IDLitopCropImageGrid::_ExecuteOnData, oData, $
    COMMAND_SET=oCommandSet, $
    MASK=mask, $
    TARGET_VISUALIZATION=oTarget

    compile_opt idl2, hidden

    if (OBJ_VALID(self._oTarget)) then begin
        self._oTarget->_IDLitVisGrid2D::GetProperty, X_DATA_ID=xDataID, $
            Y_DATA_ID=yDataID

        oXDataObj = self._oTarget->GetParameter(xDataID)
        if (OBJ_VALID(oXDataObj) && $
            (oXDataObj eq oData)) then $
            self._cropIndex = 0

        oYDataObj = self._oTarget->GetParameter(yDataID)
        if (OBJ_VALID(oYDataObj) && $
            (oYDataObj eq oData)) then $
            self._cropIndex = 1
    endif

    return, self->IDLitDataOperation::_ExecuteOnData(oData, $
        COMMAND_SET=oCommandSet, $
        MASK=mask, $
        TARGET_VISUALIZATION=oTarget)
end

;---------------------------------------------------------------------------
function IDLitopCropImageGrid::Execute, data

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oTarget)) then $
        return, 0

    self._oTarget->_IDLitVisGrid2D::GetProperty, $
        GRID_DIMENSIONS=gridDims

    case self._cropIndex of
        0: begin
            xStep = (data[1] - data[0])
            data = self._x0 + (xStep * FINDGEN(gridDims[0]))
        end
        1: begin
            yStep = (data[1] - data[0])
            data = self._y0 + (yStep * FINDGEN(gridDims[1]))
        end
        else: return, 0
    endcase

    return,1
end


;-------------------------------------------------------------------------
pro IDLitopCropImageGrid__define

    compile_opt idl2, hidden

    struc = {IDLitopCropImageGrid, $
        inherits IDLitDataOperation,  $
        _x0: 0UL,                     $
        _y0: 0UL,                     $
        _width: 0UL,                  $
        _height: 0UL,                 $ 
        _oTarget: OBJ_NEW(),          $  
        _cropIndex: 0                 $ ; 0: crop x, 1: crop y
    }

end

