; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitoprotateangle__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRotateAngle
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the RotateAngle operation.
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopRotateAngle::Init
;
; Purpose:
; The constructor of the IDLitopRotateAngle object.
;
; Parameters:
; None.
;
function IDLitopRotateAngle::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden

    ; We need to have the DATASPACE_ROOTs and IDLTEXT in here since
    ; they don't have any data.
    if (~self->IDLitOperation::Init( $
        TYPES=['IDLVECTOR', 'IDLARRAY2D', 'IDLARRAY3D', 'IDLIMAGE', $
            'IDLVERTEX', $
            'DATASPACE_3D', 'DATASPACE_2D', $
            'DATASPACE_ROOT_3D', 'DATASPACE_ROOT_2D', $
            'IDLLIGHT', 'IDLTEXT', 'IDLROI'], $
        _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitROIVertexOperation::Init(_EXTRA=_extra)) then begin
        self->Cleanup
        return, 0
    endif

    return, 1
end


;---------------------------------------------------------------------------
; IDLitopRotateAngle::Cleanup
;
; Purpose:
;   This procedure method cleans up the rotation operation.
;
pro IDLitopRotateAngle::Cleanup
    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->_IDLitROIVertexOperation::Cleanup
    self->IDLitOperation::Cleanup

end

;---------------------------------------------------------------------------
pro IDLitopRotateAngle::GetProperty, $
    ANGLE=angle, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(angle) then $
        angle = self._angle

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopRotateAngle::SetProperty, $
    ANGLE=angle, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if N_ELEMENTS(angle) then $
        self._angle = angle

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Internal function to retrieve the list of manipulator targets.
;
function IDLitopRotateAngle::_Targets, oTool, COUNT=count

    compile_opt idl2, hidden

    count = 0

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTargets)

    if (nTargets eq 0) then $
      return, OBJ_NEW()

    oManipTargets = OBJARR(nTargets)

    for i=0, nTargets-1 do begin
        if OBJ_VALID(oTargets[i]) then $
            oManipTargets[i] = oTargets[i]->GetManipulatorTarget()
        ; We need to filter out axes since they are a manipulator target
        ; but should not be rotated.
        if (OBJ_ISA(oManipTargets[i], 'IDLitVisAxis')) then $
            oManipTargets[i] = OBJ_NEW()
    endfor

    oManipTargets = oManipTargets[UNIQ(oManipTargets, SORT(oManipTargets))]
    good = WHERE(OBJ_VALID(oManipTargets), count)
    if (~count) then $
        return, OBJ_NEW()
    oManipTargets = oManipTargets[good]

    return, oManipTargets

end

;---------------------------------------------------------------------------
; Internal function to perform the rotation.
; Should be called from subclass ::DoAction with "angle" in degrees.
; Returns an Undo/Redo Command object.
;
function IDLitopRotateAngle::_Rotate, oTool, oManipTargets

    compile_opt idl2, hidden

    count = N_ELEMENTS(oManipTargets)
    if (count eq 0) then $
        return, OBJ_NEW()

    ; Retrieve our SetProperty service.
    oOperation = oTool->GetService('SET_PROPERTY')
    if (not OBJ_VALID(oOperation)) then $
        return, OBJ_NEW()

    ; Create our undo/redo command set, and record the initial values.
    oCmdSet = OBJ_NEW("IDLitCommandSet", $
        NAME=self.name, $
        OPERATION_IDENTIFIER=oOperation->GetFullIdentifier())
    iStatus = oOperation->RecordInitialValues(oCmdSet, $
        oManipTargets, 'TRANSFORM')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    for i=0,count-1 do begin
        oManipTargets[i]->GetProperty, $
            CENTER_OF_ROTATION=centerRotation, TRANSFORM=currentTransform
        ; Transform center of rotation by current transform
        cr = [centerRotation, 1.0d] # currentTransform
        oManipTargets[i]->_IDLitVisualization::Rotate, $
            [0, 0, 1], self._angle, CENTER_OF_ROTATION=cr
    endfor

    ; Record the final values and return.
    iStatus = oOperation->RecordFinalValues(oCmdSet, $
        oManipTargets, 'TRANSFORM', $
        /SKIP_MACROHISTORY)
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    return, oCmdSet

end

;---------------------------------------------------------------------------
; IDLitopRotateAngle::_ExecuteOnROI
;
; Purpose:
;   This function method executes the operation on the given ROI.
;
; Arguments:
;   oROI: A reference to the ROI visualization that is the target
;     of this operation.
;
;   oCmdSet: A reference to the command set in which operations commands
;     are to be collected.
;
; Keywords:
;   PARENT_IS_TARGET: Set this keyword to a non-zero value to indicate
;     that the parent is the actual target of the operation and that the
;     ROI should be handled accordingly.  By default (if this keyword is
;     not set), the ROI itself is the target of the operation.
;
function IDLitopRotateAngle::_ExecuteOnROI, oROI, $
    PARENT_IS_TARGET=parentIsTarget

    compile_opt idl2, hidden

    if (KEYWORD_SET(parentIsTarget)) then begin
        oROI->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then $
            oParent->GetProperty, CENTER_OF_ROTATION=center
    endif

    oROI->_IDLitVisualization::Rotate, $
        [0,0,1], self._angle, CENTER_OF_ROTATION=center

    return, 1
end

;---------------------------------------------------------------------------
function IDLitopRotateAngle::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the targets from among the currently selected item(s).
    oTargets = self->IDLitopRotateAngle::_Targets(oTool, COUNT=nTargets)
    if (nTargets eq 0) then $
        return, OBJ_NEW()

    ; For each target...
    nNonROI = 0
    nROI = 0
    nonROITargets = OBJ_NEW()
    for i=0, nTargets-1 do begin
        ; Handle ROIs specially.
        if (OBJ_ISA(oTargets[i], 'IDLitVisROI')) then begin
            ; Check if the ROI's parent manipulator target is also targeted.
            ; If so, skip this ROI (the operation will only be applied to
            ; the manipulator target).
            oTargets[i]->GetProperty, PARENT=oParent
            oParManipTarget = OBJ_VALID(oParent) ? $
                oParent->GetManipulatorTarget() : OBJ_NEW()
            if (OBJ_VALID(oParManipTarget)) then $
                iMatch = WHERE(oTargets eq oParManipTarget, nMatch) $
            else $
                nMatch = 0
            if (nMatch eq 0) then begin
                iStatus1 = self->_CollectROIs(oTargets[i])
                nROI++
            endif else $
                continue
        endif else begin
            nonROITargets = ((nNonROI gt 0) ? $
                [nonROITargets, oTargets[i]] : oTargets[i])
            nNonROI++
        endelse
    endfor

    ; Apply the rotation to all non-ROI targets.
    oCmdSet = (nNonROI gt 0) ? $
       self->_Rotate(oTool, nonROITargets) : OBJ_NEW()

    ; Apply the rotation to any ROIs.
    if (nROI gt 0) then $
        iStatus1 = self->_ProcessROIs(oTool, oCmdSet)

    oTool->RefreshCurrentWindow

    return, oCmdSet
end


;-------------------------------------------------------------------------
pro IDLitopRotateAngle__define

    compile_opt idl2, hidden
    struc = {IDLitopRotateAngle,           $
        inherits IDLitOperation,           $
        inherits _IDLitROIVertexOperation, $
        _angle: 0.0                        $
    }

end

