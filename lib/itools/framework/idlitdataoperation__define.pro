; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitdataoperation__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the data operation component.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitDataOperation object.
;
; Arguments:
;   None.
;
; Keywords:
;   RECORD_PROPERTIES (Init only): If this keyword is set, then all
;       properties will be recorded before and after the UI dialog
;       is displayed. If you are writing a custom UI dialog that may
;       change several operation properties, then set RECORD_PROPERTIES.
;       Otherwise, if you are using a simple PropertySheet UI dialog,
;       you don't need to set this property.
;
;   All keywords to superclass Init.
;
function IDLitDataOperation::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(_EXTRA=_extra)) then $
        return, 0

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitDataOperation::GetProperty, WITHIN_UI=withinUI, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(withinUI)) then $
       withinUI = self._withinUI

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitDataOperation::_UndoExecuteOnData
;
; Purpose:
;   Undo an execution using procesing. Execute the operation on the
;   given data object. This routine will extract the expected data
;   type and pass the value onto the actual operations UndoExecute() method.
;
; Arguments:
;   oData  - The data to operate on.
;
; Return Value:
;   0 - Error
;   1 - Success
;
function IDLitDataOperation::_UndoExecuteOnData, oData, $
    _EXTRA=_extra

   compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, 0                ;cause a roll-back
   endif

   ; Get the types this operation can operate on.
   self->IDLitOperation::GetProperty, TYPES=strTypes
   oDataItems = oData->GetByType(strTypes)
   if (~OBJ_VALID(oDataItems[0])) then $
     return, 0

   ; Loop through all the data we have.
   for i=0, n_elements(oDataItems)-1 do begin
       iStatus = oDataItems[i]->GetData(aData ,/NO_COPY, NAN=nan)

       ; Cache our NAN value for use by subclasses.
       self._nan = KEYWORD_SET(nan)

       if(iStatus eq 1)then begin

           if (N_ELEMENTS(_extra) gt 0) then $
               ret = self->UnDoExecute(aData, _EXTRA=_extra) $
           else $
               ret = self->UnDoExecute(aData)

           iStatus = oDataItems[i]->SetData( aData, /no_copy)
           if(iStatus eq 0)then begin
               return, 0 ; will ause a roll back
           endif
       endif else  $
         return, 0; do a roll back
   endfor

   return, 1
end


;---------------------------------------------------------------------------
; IDLitDataOperation::_DoUndoExecute
;
; Purpose:
;    This method is called to cause an undo operation to take place
;    using execution, not cached data.
;
; Arguments:
;   oCmds - Array of commands to undo
;
; Return Values:
;   0 - Error
;   1 - Success
;
function IDLitDataOperation::_DoUndoExecute, oCmds

  compile_opt idl2, hidden
   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, 0                ;cause a roll-back
   endif

  bROIPixelOp = OBJ_ISA(self,'_IDLitROIPixelOperation')
  oTool = self->GetTool()
  ; Redo with processing
  for i=n_elements(oCmds)-1, 0, -1 do begin
      ; Get the data object for this command.
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
      oData = oTool->GetByIdentifier(idTarget)
      if(not obj_valid(oData))then $
        continue                ;

      ; Perform the undo.
      if (bROIPixelOp) then begin
          if (~oCmds[i]->GetItem("MASK",mask)) then begin
              if (N_ELEMENTS(mask)) then $
                  void = TEMPORARY(mask)
          endif
          iStatus = self->_UndoExecuteOnData(oData, MASK=mask)
      endif else $
          iStatus = self->_UndoExecuteOnData(oData)

      if(iStatus ne 1)then $
          return, 0
  endfor

  return, 1
end



;---------------------------------------------------------------------------
; Purpose:
;   Internal method to turn off update messages on all data containers
;   within the oCmds undo/redo commands.
;   idContainer is a return argument which should be passed into
;   IDLitDataOperation::_EnableContainerUpdates without modification.
;
pro IDLitDataOperation::_DisableContainerUpdates, oCmds, idContainer

    compile_opt idl2, hidden

    oTool = self->GetTool()

    ; Disable notify on all data containers.
    for i=0, N_ELEMENTS(oCmds)-1 do begin
        if (~oCmds[i]->GetItem("DATACONTAINER", idContainer1)) then $
            continue

        ; Any data containers yet?
        if (N_ELEMENTS(idContainer) gt 0) then begin
            ; Have we already found this container?
            if (MAX(idContainer eq idContainer1) eq 1) then begin
                idContainer1 = ''   ; don't bother to cache
            endif else begin
                idContainer = [idContainer, idContainer1]
            endelse
        endif else begin
            ; Start our cache with our first container.
            idContainer = idContainer1
        endelse

        if (idContainer1 ne '') then begin
            ; Turn off notification for this container.
            oDataContainer = oTool->GetByIdentifier(idContainer1)
            if (OBJ_VALID(oDataContainer)) then $
                oDataContainer->DisableNotify
        endif

    endfor

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method to turn on update messages on all data containers
;   that were turned off in IDLitDataOperation::_DisableContainerUpdates.
;   idContainer is an input argument and is typically returned from
;   IDLitDataOperation::_DisableContainerUpdates.
;
pro IDLitDataOperation::_EnableContainerUpdates, idContainer

    compile_opt idl2, hidden

    oTool = self->GetTool()

    ; Re-enable notify on all data containers.
    for i=0,N_ELEMENTS(idContainer)-1 do begin
        oDataContainer = oTool->GetByIdentifier(idContainer[i])
        if (OBJ_VALID(oDataContainer)) then $
            oDataContainer->EnableNotify
    endfor

end


;---------------------------------------------------------------------------
; IDLitDataOperation::UndoOperation
;
; Purpose:
;  Undo the commands contained in the command set. This is done in
;  one of two ways. 1) Resetting the target object's data to the
;  saved original values or 2) executing the reverse of the command.
;
; Arguments:
;   oCommandSet  - The commands to undo
;
; Return Value:
;    0 - Error
;    1 - Success
;
function IDLitDataOperation::UndoOperation, oCommandSet

   compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, 0                ;cause a roll-back
   endif

  oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  oCmds = oCommandSet->Get(/all, count=nObjs)

  ; Quick return.
  if (nObjs eq 0) then $
    return, 0

  self->_DisableContainerUpdates, oCmds, idContainer
  void = oTool->DoUIService("HourGlassCursor", self)

  ; If this is a reversible function, just execute.
  if(self._reversible)then begin
        success = self->IDLitDataOperation::_DoUndoExecute(oCmds)
        self->_EnableContainerUpdates, idContainer
        return, success
  endif

  for i=0, nObjs-1 do begin
      ; Get the data object for this command.
      oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
      oData = oTool->GetByIdentifier(idTarget)
      if (~obj_valid(oData)) then $
        continue;
      if( oCmds[i]->getItem("DATA", Item) eq 1)then begin

          if (oData->SetData(Item, /no_copy) eq 0) then begin
            self->_EnableContainerUpdates, idContainer
            return, 0    ; Error with rollback.
          endif

      endif
  endfor

    self->_EnableContainerUpdates, idContainer

  return, 1
end


;---------------------------------------------------------------------------
; IDLitDataOperation::RedoOperation
;
; Purpose:
;   Used to "redo" an operation. One of two types of operations will
;   take place. 1) The operation is re-executed or 2) the cached
;   results from the original operation are stashed in the target
;   data objects. This is dependant on the settings of the operation.
;
; Arguments:
;   oCommandSet   - The commands to redo
;
; Return Values:
;     0 - Error
;     1 - Success.
;
function IDLitDataOperation::RedoOperation, oCommandSet

   compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
       catch, /cancel
       return, 0                ;cause a roll-back
   endif

  oTool = self->GetTool()
  if(not obj_valid(oTool))then $
    return, 0

  bROIPixelOp = OBJ_ISA(self,'_IDLitROIPixelOperation')

  oCmds = oCommandSet->Get(/all, count=nObjs)

  self->_DisableContainerUpdates, oCmds, idContainer
  void = oTool->DoUIService("HourGlassCursor", self)

  if (~self._bExpensive) then begin   ; not expensive, just re-execute

      ; Redo with processing
      for i=0, nObjs-1 do begin
          ; Get the data object for this command.
          oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
          oData = oTool->GetByIdentifier(idTarget)
          if(not obj_valid(oData))then $
            continue            ;

          ; Execute the operation again
          if (bROIPixelOp) then begin
              if (~oCmds[i]->GetItem("MASK",mask)) then begin
                 if (N_ELEMENTS(mask)) then $
                      void = TEMPORARY(mask)
              endif
              iStatus = self->_ExecuteOnData(oData, $
                  MASK=mask)
          endif else $
              iStatus = self->_ExecuteOnData(oData)

          if(iStatus ne 1)then begin
              void= self->UndoOperation(oCommandSet)
              self->_EnableContainerUpdates, idContainer
              return, 0
          endif
      endfor

  endif else begin              ;expensive op..use cached information

      for i=nObjs-1, 0, -1 do begin
          ; Get the target data
          oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
          oData = oTool->GetByIdentifier(idTarget)
          if(not obj_valid(oData))then $
            continue
          ; get the cached data
          if( oCmds[i]->getItem("REDO_DATA", Item) eq 1)then begin
              if(oData->SetData(Item, /no_copy) eq 0)then begin
                self->_EnableContainerUpdates, idContainer
                return, 0    ; Error with rollback.
              endif
          endif
      endfor
  endelse

  self->_EnableContainerUpdates, idContainer

  return, 1

end


;---------------------------------------------------------------------------
; IDLitDataOperation::_RetrieveDataPointers
;
; Purpose:
;   Retrieve the data pointers for the first selected visualization.
;   Used when we need to know the dimensions of the data we are
;   going to act upon, before the operation takes place (say for a UI).
;
function IDLitDataOperation::_RetrieveDataPointers, $
    BYTESCALE_MIN=bytsclMin, BYTESCALE_MAX=bytsclMax, $
    ISIMAGE=isImage, $
    DIMENSIONS=dims, $
    PALETTE=palette

    compile_opt idl2, hidden

    dims = 0
    palette = 0
    bytsclMin = 0b
    bytsclMax = 255b
    isImage = 0b

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, PTR_NEW()

    oTargets = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then $
        return, PTR_NEW()

    ; Step through targets until first successful data retrieval.
    n=0
    for iTarget=0,nSelVis-1 do begin
        oTarget = oTargets[iTarget]

        ; For ROI pixel operations, if the target is an ROI then reset the
        ; target to the ROI's parent.
        if (OBJ_ISA(self,'_IDLitROIPixelOperation')) then begin
            if (OBJ_ISA(oTarget,'IDLitVisROI')) then begin
                oROI = oTarget
                oROI->GetProperty, PARENT=oTarget
                if (~OBJ_VALID(oTarget)) then $
                    continue
            endif
        endif

        if (~OBJ_ISA(oTarget, 'IDLitParameter')) then $
            continue

        oParams = self->_GetOpTargets(oTarget, COUNT=count)
        if (count eq 0) then $
            continue

        for i=0,count-1 do begin
            oParams[i]->GetProperty, NAME=paramname
            oDataObj = oTarget->GetParameter(paramname)
            if (OBJ_VALID(oDataObj)) then $
                break
        endfor

        if (~OBJ_VALID(oDataObj)) then $
            continue

        self->IDLitOperation::GetProperty, TYPES=strTypes
        oDataItems = oDataObj->GetByType(strTypes)
        n = N_ELEMENTS(oDataItems)
        result = PTRARR(n)

        ; If the target parameter does not have data of the
        ; required type, move on to the next target.
        if (~OBJ_VALID(oDataItems[0])) then begin
            n=0
            continue
        endif

        ; At this point, data has been successfully retrieved.
        break
    endfor

    if (n eq 0) then $
        return, PTR_NEW()

    for i=0,n-1 do begin
        if (~oDataItems[i]->GetData(pData, /POINTER)) then $
            return, PTR_NEW()
        if (~PTR_VALID(pData) || ~N_ELEMENTS(*pData)) then $
            return, PTR_NEW()
        result[i] = pData
    endfor


    dims = SIZE(*pData[0], /DIMENSIONS)

    if (ARG_PRESENT(palette)) then begin
        oPalette = oTarget->GetParameter('PALETTE')
        if (OBJ_VALID(oPalette) && $
            oPalette->GetData(pPalette, /POINTER) && $
            PTR_VALID(pPalette)) then begin
                palette = *pPalette
        endif
    endif

    if (ARG_PRESENT(bytsclMin) || ARG_PRESENT(bytsclMax)) then begin
        if OBJ_ISA(oTarget, 'IDLitVisImage') then begin
            oTarget->GetProperty, BYTESCALE_MIN=bytsclMin, $
                BYTESCALE_MAX=bytsclMax
            isImage = 1b
        endif else begin
            bytsclMin = MIN(*pData[0], MAX=bytsclMax)
        endelse
    endif

    return, result
end

;---------------------------------------------------------------------------
; IDLitDataOperation::_ExecuteOnData
;
; Purpose:
;   Execute the operation on the given data object. This routine
;   will extract the expected data type and pass the value onto
;   the actual operation
;
; Parameters:
;   oData  - The data to operate on.
;
; Keywords:
;   COMMAND_SET   - This is set to the command set the execution
;                   state should be stashed in. If not present, no
;                   results are cached.
;
; Return value:
;   This function returns:
;     1 if successful,
;     0 if an error occurred
;    -1 if oData's type(s) do not match this operation's data types
;
function IDLitDataOperation::_ExecuteOnData, oData, $
    COMMAND_SET=oCommandSet, $
    MASK=mask, $
    TARGET_VISUALIZATION=oTarget

   compile_opt idl2, hidden

   ; Trap errors
@idlit_catch
   if(iErr ne 0)then begin
        catch, /cancel
        ; Be sure to put back the original data if necessary.
        if ((N_ELEMENTS(inExecute) gt 0) && inExecute) then $
            void = oDataItems[i]->SetData(bkData, /NO_COPY)

        ; Construct a nice error message.
        oData->IDLitComponent::GetProperty, NAME=dataName
        errMsg = IDLitLangCatQuery('Error:Framework:OpFailed') + dataName + "'"
        if (OBJ_VALID(oTarget)) then begin
            oTarget->IDLitComponent::GetProperty, NAME=vizName
            if (vizName) then $
                errMsg += IDLitLangCatQuery('Error:Framework:InTarget') + vizName + "'."
        endif

        self->ErrorMessage, [errMsg, !ERROR_STATE.msg], $
            SEVERITY=2

       return, 0                ;cause a roll-back
   endif


   ; Get the types this operation can operate on.

   self->IDLitOperation::GetProperty, TYPES=strTypes

   oDataItems = oData->GetByType(strTypes)
   if (~OBJ_VALID(oDataItems[0])) then $
     return, -1

   isContainer = OBJ_ISA(oData, 'IDLitDataContainer')
   if isContainer then $
       oData->DisableNotify

   bROIPixelOp = OBJ_ISA(self,'_IDLitROIPixelOperation')

   ; Loop through all the data we have.
   for i=0, n_elements(oDataItems)-1 do begin

       dataItemID = oDataItems[i]->GetFullIdentifier()

       ; If a command set is available, check if this data item
       ; has already been operated on.  If so, skip.
       bSkip = 0b
       if (OBJ_VALID(oCommandSet)) then begin
           nCmds = oCommandSet->Count()
           if (nCmds gt 0) then begin
               for j=0, nCmds-1 do begin
                   oCmd = oCommandSet->Get(POSITION=j)
                   oCmd->GetProperty, TARGET_IDENTIFIER=targetID
                   if (targetID eq dataItemID) then begin
                       bSkip = 1b
                       break
                   endif
               endfor
               if (bSkip ne 0) then $
                   continue
           endif
       endif

       iStatus = oDataItems[i]->GetData(aData, /NO_COPY, NAN=nan)
       if (iStatus ne 1) then begin
           if (isContainer) then $
               oData->EnableNotify
            return, 0; do a roll back
       endif

       ; Cache our NAN value for use by subclasses.
       self._nan = KEYWORD_SET(nan)

       ; If this operation fails, we need to restore the old data.
       bkData = aData

       ; Execute the operation
       inExecute = 1b
       if (bROIPixelOp) then $
           execStatus = self->Execute(aData, MASK=mask) $
       else $
           execStatus = self->Execute(aData)
       if (~execStatus) then begin
            void = oDataItems[i]->SetData(bkData, /NO_COPY)
            if (isContainer) then $
               oData->EnableNotify
            return, 0  ; failed, no need to continue
       endif
       inExecute = 0b

       ; Success in Execute. Stash results?
       if(keyword_set(oCommandSet))then begin
           oCmd = obj_new("idlitCommand", TARGET_IDENTIFIER=dataItemID)
           oCommandSet->Add, oCmd

           ; Also store our parent data container.
           if (isContainer) then $
                void = oCmd->AddItem("DATACONTAINER", oData->GetFullIdentifier())
           ; If not reversible, stash a copy of the original data
           if (~self._reversible) then $
               void = oCmd->AddItem("DATA", TEMPORARY(bkData))

           if (bROIPixelOp) then begin
               if (N_ELEMENTS(mask) ne 0) then $
                   void = oCmd->AddItem("MASK", mask)
           endif

           ; If this is a computational intense
           ; operation, stash the results in the
           ; command.
           if(self._bExpensive)then $
             void = oCmd->AddItem("REDO_DATA", aData)
       endif

       ; Replace data with new values
       iStatus = oDataItems[i]->SetData( aData, /no_copy)
       if(iStatus eq 0)then begin
            if (isContainer) then $
               oData->EnableNotify
            return, 0 ; will cause a roll back
       endif

   endfor

   if (isContainer) then $
       oData->EnableNotify

   return, 1
end


;---------------------------------------------------------------------------
; IDLitDataOperation::_GetOpTargets
;
; Purpose:
;  Internal function to retrieve the parameter descriptors for the
;  op targets for a particular visualization.
;
; Arguments:
;   oTarget          - What to apply the operation on.
;
; Keywords:
;   COUNT: The number of returned parameter descriptor objects.
;
function IDLitDataOperation::_GetOpTargets, oTarget, COUNT=count

    compile_opt idl2, hidden

    return, oTarget->GetOpTargets(COUNT=count)

end


;---------------------------------------------------------------------------
; IDLitDataOperation::_ExecuteOnTarget
;
; Purpose:
;  Internal routine called to execute an operation
;  on a particular target.
;
; Parameter:
;   oTarget          - What to apply the operation on.
;
;   oCommandSet      - The command set for this operation execution.
;
function IDLitDataOperation::_ExecuteOnTarget, oTarget, oCommandSet, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (~OBJ_ISA(oTarget, 'IDLitParameter')) then $
        return, 0

    nDataExecutes = 0

; Get the parameters that this target accepts. This is the set of data
; that the target contains.
;
    oParams = self->_GetOpTargets(oTarget, COUNT=count)

   ; For each parameter, grab the data and execute the operation.
   for i=0, count-1 do begin
       oParams[i]->GetProperty, name=name
       oDataObj = oTarget->GetParameter(name)
       if(obj_valid(oDataObj))then begin
           if (~self->_ExecuteOnData(oDataObj, $
                COMMAND_SET=oCommandSet, $
                TARGET_VISUALIZATION=oTarget, _EXTRA=_extra)) then $
                return, 0
           nDataExecutes = nDataExecutes + 1
       endif
   endfor

   iStatus = (nDataExecutes gt 0)
   if (iStatus ne 0) then begin
       ; If this is a ROI vertex operation, and the parent contains
       ; any ROIs, then collect them for later processing.
       if (OBJ_ISA(self,'_IDLitROIVertexOperation')) then begin
           oROIs = oTarget->Get(/ALL, ISA='IDLitVisROI', COUNT=nROIs)
           if (nROIs gt 0) then $
               iStatus1 = self->_CollectROIs(oROIs, /PARENT_IS_TARGET)
       endif
   endif

   return, iStatus  ; success (1) or failure (0)
end


;---------------------------------------------------------------------------
; IDlitDataOperation::DoDataOperation
;
; Purpose:
;   This function method performs a data operation on all supported data
;   objects for the selected visualizations.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oTool:  A reference to the tool in which this operation is occurring.
;
;   oCommandSet: A reference to the command set object in which all commands
;     associated with this operation are to be collected.
;
;   oSelVis:    A vector of references to the currently selected
;     visualizations.
;
function IDLitDataOperation::DoDataOperation, oTool, oCommandSet, oSelVis

    compile_opt idl2, hidden

    nSelVis = N_ELEMENTS(oSelVis)

    iStatus = 0
    bROIPixelOp = OBJ_ISA(self,'_IDLitROIPixelOperation')
    bROIVertexOp = OBJ_ISA(self,'_IDLitROIVertexOperation')

    ; For each selected visualization...
    for iSelVis=0, nSelVis-1 do begin
        nCurrent = oCommandSet->Count()

        ; Execute the operation on the selected visualization.

        ; If this operation applies to ROIs, handle ROIs specially.
        if (bROIPixelOp || bROIVertexOp) then begin
            if (OBJ_ISA(oSelVis[iSelVis], 'IDLitVisROI')) then begin
                ; Check if the ROI's parent is also selected.  If so,
                ; skip this ROI (the operation will only be applied to
                ; the parent).
                oSelVis[iSelVis]->GetProperty, PARENT=oParent
                if (OBJ_VALID(oParent)) then $
                    iMatch = WHERE(oSelVis eq oParent, nMatch) $
                else $
                    nMatch = 0
                if (nMatch eq 0) then begin
                    if (bROIPixelOp) then $
                        iStatus1 = self->_PrepareROIMask( $
                            oSelVis[iSelVis], oParent) $
                    else $
                        iStatus1 = self->_CollectROIs( $
                            oSelVis[iSelVis])
                    execOnTarget = 0b
                endif else $
                    continue
            endif else $
                execOnTarget = 1b
        endif else $
           execOnTarget = 1b

        if (execOnTarget) then begin
            iStatus1 = self->_ExecuteOnTarget( $
                oSelVis[iSelVis], oCommandSet)

            iStatus or= iStatus1

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
        endif
    endfor   ; selected visualizations.

    ; If this operation applies to ROI pixels or vertices, process ROIs.
    if (bROIPixelOp || bROIVertexOp) then begin
        iStatus1 = self->_ProcessROIs(oTool, oCommandSet)
        iStatus or= iStatus1
    endif

    return, iStatus
end


;---------------------------------------------------------------------------
; IDLitDataOperation
;
; Purpose:
;   This function method performs a data operation on all supported data
;   objects for the selected visualizations within the given tool.
;
; Return Value:
;   This function returns a 1 on success, or 0 otherwise.
;
; Arguments:
;   oTool:  A reference to the tool in which this operation is occurring.
;
function IDLitDataOperation::DoAction, oTool

   compile_opt idl2, hidden

   ; Make sure we have a tool.
   if not obj_valid(oTool) then $
      return, obj_new()

   ; Get the selected objects.  (this will usually mean DataSpaces)
   oSelVis = oTool->GetSelectedItems(count=nSelVis)
   if (nSelVis eq 0) then $
     return, obj_new()

   ; Is some UI needed prior to execution?
   self->GetProperty, show_execution_ui=doUI

    if (doUI) then begin

        ; Perform our UI.
        ; The self._withinUI can be used internally to indicate that we
        ; are currently displaying the UI.
        self._withinUI = 1b
        ret = self->DoExecuteUI()
        self._withinUI = 0b

        if (~ret) then begin
            ; If user hit Cancel then undo the pending transaction.
            oCommandBuffer = oTool->_GetCommandBuffer()
            oCommandBuffer->Rollback
            return, obj_new()
        endif

        ; The hourglass will have been cleared by the dialog.
        ; So turn it back on.
        void = oTool->DoUIService("HourGlassCursor", self)

    endif


    ; Get a commmand set for this operation from the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    oVisPropSet = self->IDLitOperation::RecordInitialProperties(oSelVis)

    ; Perform the actual data operation.
    iStatus = self->DoDataOperation(oTool, oCommandSet, oSelVis)

    ; Did the operation fail for all selected viz?
    if (iStatus eq 0) then begin
        ; We should already have performed an UndoOperation (in the loop),
        ; so just destroy our command set.
        obj_destroy, oCommandSet
        if (~wasDisabled) then $
            oTool->EnableUpdates
        return, obj_new()
    endif

    if (~wasDisabled) then $
        oTool->EnableUpdates

    if (OBJ_VALID(oVisPropSet)) then begin
        self->IDLitOperation::RecordFinalProperties, oVisPropSet
        oCommandSet = [oVisPropSet, oCommandSet]
    endif

    oTool->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''

    return, oCommandSet

end


;---------------------------------------------------------------------------
; IDLitDataOperation::DoExecuteUI
;
; Purpose:
;   This is an abstract method that is intended to be implemented by
;   the user. The goal of this method is to provide the developer the
;   chance to display some UI prior to the execution of an
;   operation. This allows the user to dynamically change
;   properties. ..ect.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;
;    0 - Error, discontinue the operation

Function IDLitDataOperation::DoExecuteUI

    compile_opt idl2, hidden

    ; This is a stub.
;    success = oTool->DoUIService('<uiservice>', self)

    return, 1
end


;-------------------------------------------------------------------------
pro IDLitDataOperation__define

    compile_opt idl2, hidden

    struc = {IDLitDataOperation,     $
             inherits IDLitOperation, $
             _nan: 0b, $
             _withinUI: 0b $
            }
end

