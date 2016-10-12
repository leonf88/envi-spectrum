; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitroipixeloperation__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements an abstract class to support operations that
;   apply to ROI pixels.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; _IDLitROIPixelOperation::Init
;
; Purpose:
;   This function method initializes the ROI Pixel operation.
;
; Return Value:
;   This function method returns a 1 on success, or 0 on failure.
;
function _IDLitROIPixelOperation::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    self._pROIParents = PTR_NEW(/ALLOCATE_HEAP)
    self._pROIMasks = PTR_NEW(/ALLOCATE_HEAP)

    return, 1
end

;-------------------------------------------------------------------------
; _IDLitROIPixelOperation::Cleanup
;
; Purpose:
;   This procedure method cleans up a ROI pixel operation.
;
pro _IDLitROIPixelOperation::Cleanup
    compile_opt idl2, hidden

    ; Clean up pointers.
    nParents = N_ELEMENTS(*self._pROIParents)
    if (nParents gt 0) then $
        PTR_FREE, *(self._pROIMasks)
    PTR_FREE, self._pROIMasks
    PTR_FREE, self._pROIParents

end

;---------------------------------------------------------------------------
; _IDLitROIPixelOperation::_PrepareROIMask
;
; Purpose:
;   This function method prepares to execute the operation for parent of
;   a target ROI.   The ROI's mask is combined with any other ROIs that have 
;   the same parent.  This mask is cached, and processed later in 
;   ::DoDataOperation.
;
; Arguments:
;   oROI: A reference to the IDLitVisROI to which the operation is
;     to be applied.
;   oParent: A reference to the ROI's parent visualization.
;   oCommandSet: A reference to the command set for this operation execution.
;
; Return value:
;   This functoin returns 1 on success, or 0 on failure.
;
function _IDLitROIPixelOperation::_PrepareROIMask, oROI, oParent
    compile_opt idl2, hidden

    ; Return failure if parent has no parameters or is not a 2D grid.
    if (~OBJ_ISA(oParent, 'IDLitParameter')) then $
        return, 0
    if (~OBJ_ISA(oParent, '_IDLitVisGrid2D')) then $
        return, 0

    oParent->GetProperty, GRID_DIMENSIONS=parentDims
    
    ; Check the cache to see if this parent has been encountered yet.
    if (N_ELEMENTS(*self._pROIParents)) then $
        iMatch = WHERE(*(self._pROIParents) eq oParent, nMatch) $
    else $
        nMatch = 0
    if (nMatch eq 0) then begin
        ; If this parent has not yet been encountered, add it to the
        ; cache, and store the mask for this ROI.
        mask = oROI->ComputeMask(DIMENSIONS=parentDims)
        if (N_ELEMENTS(*self._pROIParents) eq 0) then begin
            *self._pROIParents = oParent
            *self._pROIMasks = PTR_NEW(mask, /NO_COPY)
        endif else begin
            *self._pROIParents = [*self._pROIParents, oParent]
            *self._pROIMasks = [*self._pROIMasks, PTR_NEW(mask, /NO_COPY)]
        endelse

    endif else begin
        ; If this parent has been encountered before (for this
        ; particular call to the data operation), then combine this
        ; ROI's mask with the previous mask.
        pMask = (*self._pROIMasks)[iMatch[0]]
        *pMask = oROI->ComputeMask(DIMENSIONS=parentDims, $
            MASK_IN=*pMask)
    endelse

    ; The parents and their ROIs will be processed later in the 
    ; ::_DoDataOperation method.

    return, 1
end

;-------------------------------------------------------------------------
; _IDLitROIPixelOperation::_ProcessROIs
;
; Purpose:
;   This function method applies the operation for each collected
;   parent using the collected ROI masks.
;
; Return Value:
;   This function returns a 1 on success, or 0 on failure.
;
; Arguments:
;   oTool: A reference to the current tool.
;
;   oCommandSet: A reference to the command set for this operation.
;
function _IDLitROIPixelOperation::_ProcessROIs, oTool, oCommandSet
    compile_opt idl2, hidden

    iStatus = 0

    nROIParents = N_ELEMENTS(*self._pROIParents)
    if (nROIParents gt 0) then begin
        for i=0,nROIParents-1 do begin
            nCurrent = oCommandSet->Count()

            iStatus1 = self->_ExecuteOnTarget( $
                (*self._pROIParents)[i], oCommandSet, $
                MASK=*((*self._pROIMasks)[i]))

            iStatus or= iStatus1

            PTR_FREE,(*self._pROIMasks)[i]

            if (~iStatus1) then begin
                ; If operation failed, retrieve the undo/redo objects
                ; for this particular target and undo them.
                nNewCount = oCommandSet->Count()
                oCmds = oCommandSet->Get(/ALL, COUNT=nNew)
                if (nNew gt nCurrent) then begin
                    oCommandSet->Remove, oCmds[nCurrent:*]
                    ; Create a temporary command set and add
                    ; our "bad" commands.
                    oUndoCmdSet = OBJ_NEW('IDLitCommandSet')
                    oUndoCmdSet->Add, oCmds[nCurrent:*]
                    void = self->UndoOperation(oUndoCmdSet)
                    OBJ_DESTROY, oUndoCmdSet
                endif
            endif
        endfor

        ; Clear out parent cache.
        void = TEMPORARY(*self._pROIParents)
        void = TEMPORARY(*self._pROIMasks)
    endif

    return, iStatus
end

;-------------------------------------------------------------------------
; Object Class Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
pro _IDLitROIPixelOperation__Define

    compile_opt idl2, hidden

    struc = {_IDLitROIPixelOperation, $
        _pROIParents: PTR_NEW(),      $ ; Parent cache.
        _pROIMasks: PTR_NEW()         $ ; ROI masks (one per parent).
    }
end

