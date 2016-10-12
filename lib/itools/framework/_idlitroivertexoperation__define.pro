; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitroivertexoperation__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements an abstract class to support operations that
;   apply to ROI vertices.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; _IDLitROIVertexOperation::Init
;
; Purpose:
;   This function method initializes the ROI vertex operation.
;
; Return Value:
;   This function method returns a 1 on success, or 0 on failure.
;
function _IDLitROIVertexOperation::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    self._pROITargets = PTR_NEW(/ALLOCATE_HEAP)
    self._pROIChildren = PTR_NEW(/ALLOCATE_HEAP)

    return, 1
end

;-------------------------------------------------------------------------
; _IDLitROIVertexOperation::Cleanup
;
; Purpose:
;   This procedure method cleans up a ROI vertex operation.
;
pro _IDLitROIVertexOperation::Cleanup
    compile_opt idl2, hidden

    ; Clean up pointers.
    PTR_FREE, self._pROITargets
    PTR_FREE, self._pROIChildren

end

;---------------------------------------------------------------------------
; _IDLitROIVertexOperation::_CollectROIs
;
; Purpose:
;   This function method collects ROIs targets for the operation.
;   These ROIs will be operated upon at the end.
;
; Arguments:
;   oROIs: A reference (or vector of references) to the IDLitVisROI(s) to 
;     which the operation is to be applied.
;
; Keywords:
;    PARENT_IS_TARGET: Set this keyword to indicate that the oROIs
;      argument refers to ROIs whose parents are targets of the operation.
;      These ROIs will be stored in a separate list for special processing.
;      By default (if this keyword is not set), the ROI itself is the
;      target of operation.
;
; Return value:
;   This functoin returns 1 on success, or 0 on failure.
;
function _IDLitROIVertexOperation::_CollectROIs, oROIs, $
    PARENT_IS_TARGET=parentIsTarget

    compile_opt idl2, hidden

    pROICache = KEYWORD_SET(parentIsTarget) ? $
        self._pROIChildren : self._pROITargets

    if (N_ELEMENTS(*pROICache) eq 0) then $
        *pROICache = oROIs $
    else $
        *pROICache = [*pROICache, oROIs]

    ; The ROIs will be processed later in the ::_DoDataOperation method.

    return, 1
end

;---------------------------------------------------------------------------
; _IDLitROIVertexOperation::_ExecuteOnROI
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
function _IDLitROIVertexOperation::_ExecuteOnROI, oROI, oCmdSet, $
    PARENT_IS_TARGET=parentIsTarget

    compile_opt idl2, hidden

    ; This is merely the default implementation.  It is expected that
    ; subclasses will override.
    return, self->_ExecuteOnTarget(oROI, oCmdSet)
end

;-------------------------------------------------------------------------
; _IDLitROIVertexOperation::_ProcessROIs
;
; Purpose:
;   This function method applies the operation to each collected ROI.
;
; Return Value;
;   This function returns a 1 on success, or 0 on failure.
;
; Arguments:
;   oTool: A reference to the current tool.
;
;   oCommandSet: A reference to the command set for this operation.
;      [Note: On output, oCommandSet may change to an array with an
;       additional element (a separate command set for ROIs).]
;
function _IDLitROIVertexOperation::_ProcessROIs, oTool, oCommandSet
    compile_opt idl2, hidden

    ; If command set for non-ROI targets is empty, free it now.
    if (OBJ_VALID(oCommandSet) && $
        (oCommandSet->Count() eq 0)) then begin
        OBJ_DESTROY, oCommandSet
        oCommandSet = OBJ_NEW()
    endif

    nROITargets = N_ELEMENTS(*self._pROITargets)
    nROIChildren = N_ELEMENTS(*self._pROIChildren)
    nTotalROI = nROITargets + nROIChildren
    if (nTotalROI eq 0) then $
        return, 0

    ; Retrieve the SetProperty service, which will be used to
    ; manage ROI vertices.
    oSetPropOp = oTool->GetService('SET_PROPERTY')
    if (~OBJ_VALID(oSetPropOp)) then begin
        ; Clear out ROI caches.
        if (nROITargets gt 0) then $
            void = TEMPORARY(*self._pROITargets)
        if (nROIChildren gt 0) then $
            void = TEMPORARY(*self._pROIChildren)
        return, 0
    endif

    ; Prepare a new command set for ROIs.
    oROICmdSet = OBJ_NEW("IDLitCommandSet", NAME=self.name, $
        OPERATION_IDENTIFIER=oSetPropOp->GetFullIdentifier())
    if (~OBJ_VALID(oROICmdSet)) then begin
        ; Clear out ROI caches.
        if (nROITargets gt 0) then $
            void = TEMPORARY(*self._pROITargets)
        if (nROIChildren gt 0) then $
            void = TEMPORARY(*self._pROIChildren)
        return, 0
    endif

    ; Combine ROI lists.
    allROIs = (nROITargets gt 0) ? $
        ((nROIChildren gt 0) ? $
          [*self._pROITargets, *self._pROIChildren] : $
          [*self._pROITargets]) : $
        [*self._pROIChildren]

    if (~oSetPropOp->RecordInitialValues(oROICmdSet, $
        allROIs, '_VERTICES')) then begin
        OBJ_DESTROY, oROICmdSet
        ; Clear out ROI caches.
        if (nROITargets gt 0) then $
            void = TEMPORARY(*self._pROITargets)
        if (nROIChildren gt 0) then $
            void = TEMPORARY(*self._pROIChildren)
        return, 0
    endif

    iStatus = 0
    for i=0,nTotalROI-1 do begin
        if (i lt nROITargets) then begin
            oROI = (*self._pROITargets)[i]
            parentIsTarget = 0b
        endif else begin
            oROI = (*self._pROIChildren)[i-nROITargets]
            parentIsTarget = 1b
        endelse

        nCurrent = oROICmdSet->Count()

        iStatus1 = self->_ExecuteOnROI( oROI, PARENT_IS_TARGET=parentIsTarget)

        iStatus or= iStatus1
        if (~iStatus1) then begin
            ; If operation failed, retrieve the undo/redo objects
            ; for this particular target and undo them.
            nNewCount = oROICmdSet->Count()
            oCmds = oROICmdSet->Get(/ALL, COUNT=nNew)
            if (nNew gt nCurrent) then begin
                oROICmdSet->Remove, oCmds[nCurrent:*]
                ; Create a temporary command set and add
                ; our "bad" commands.
                oUndoCmdSet = OBJ_NEW('IDLitCommandSet')
                oUndoCmdSet->Add, oCmds[nCurrent:*]
                void = self->UndoOperation(oUndoCmdSet)
                OBJ_DESTROY, oUndoCmdSet
            endif
        endif
    endfor

    if (iStatus) then begin
        if (oSetPropOp->RecordFinalValues(oROICmdSet, $
            allROIs, '_VERTICES')) then begin
            oCommandSet = OBJ_VALID(oCommandSet[0]) ? $
                [oROICmdSet, oCommandSet] : oROICmdSet
        endif else begin
            OBJ_DESTROY, oROICmdSet
            iStatus = 0
        endelse
    endif else $
        OBJ_DESTROY, oROICmdSet

    ; Clear out ROI caches.
    if (nROITargets gt 0) then $
        void = TEMPORARY(*self._pROITargets)
    if (nROIChildren gt 0) then $
        void = TEMPORARY(*self._pROIChildren)

    return, iStatus
end

;-------------------------------------------------------------------------
; Object Class Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
pro _IDLitROIVertexOperation__Define

    compile_opt idl2, hidden

    struc = {_IDLitROIVertexOperation, $
        _pROITargets: PTR_NEW(),       $ ; Collection of ROI targets.
        _pROIChildren: PTR_NEW()       $ ; Collection of ROIs whose parents
                                       $ ;   are targets.
    }
end

