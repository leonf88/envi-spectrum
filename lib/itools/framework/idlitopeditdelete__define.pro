; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopeditdelete__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Edit/Copy action.
;

;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopEditDelete::Init
;;
;; Purpose:
;; The constructor of the IDLitopEditDelete object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;function IDLitopEditDelete::Init, _REF_EXTRA=_extra
;    compile_opt idl2, hidden
;    return, self->IDLitOperation::Init(_EXTRA=_extra)
;end


;;---------------------------------------------------------------------------
;; IDLitopEditDelete::RedoOperation
;;
;; Purpose:
;;  Redo the deletion command
;;
function IDLitopEditDelete::RedoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0
   oCurrTool = (OBJ_ISA(oTool, 'IDLitSystem')) ? $
       oTool->_GetCurrentTool() : oTool

   oCmds = oCommandSet->Get(/all, count=nObjs)

   oCurrTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
   for i=nObjs-1, 0, -1 do begin
       ;; Get the object
       if(oCmds[i]->getItem("ID_VISUALIZATION", idVis) eq 1)then begin

           iStatus = oCmds[i]->getItem("_PARENT", idParent)
           oParent = oTool->GetByIdentifier(idParent) ;
           oVis = oTool->GetByIdentifier(idVis)
           if(not obj_valid(oVis))then begin
               self->ErrorMessage, [IDLitLangCatQuery('Error:Framework:InvalidIdentifier'), $
                                   self->GetFullIdentifier(), $
                                   "ID: "+idParent], severity=1
               continue         ;
           endif
           if(iStatus ne 1 or not obj_valid(oParent))then $
             oVis->GetProperty, _PARENT=oParent
           if(not obj_valid(oParent))then begin
               self->ErrorMessage, [IDLitLangCatQuery('Error:Framework:InvalidParent'), $
                                   self->GetFullIdentifier(), $
                                   "ID: "+idParent], severity=1
               continue         ;
           endif

           oParent->Remove, oVis
           oVis->SetProperty, _PARENT=obj_new()

           ; Send an undelete message
           oVis->OnNotify, idVis, 'DELETE', ''
           oVis->DoOnNotify, idVis, 'DELETE', ''

           ;; stop observing all contained data items of the vis
           IF obj_isa(oVis,'IDLitVisIDataSpace') THEN $
             oTarget = oVis->GetVisualizations() $
           ELSE $
             oTarget = oVis

           IF obj_isa(oTarget,'IDLitVisualization') THEN BEGIN
             oParams = oTarget->GetParameter(/ALL,COUNT=cnt)
             FOR k=0,cnt-1 DO $
               IF obj_isa(oParams[k],'IDLitData') THEN $
               oParams[k]->RemoveDataObserver,oTarget,/no_autodelete
           ENDIF

           ;; Restash our object in the command object
           iStatus = oCmds[i]->AddItem("O_VISUALIZATION", oVis, /overwrite)

       endif else begin
           self->ErrorMessage, [IDLitLangCatQuery('Error:Framework:InvalidUndoRedoState'), $
                               self->GetFullIdentifier()], severity=1
           continue
       end
   endfor
   IF (~previouslyDisabled) THEN $
     oCurrTool->EnableUpdates
   return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopEditDelete::UndoOperation
;;
;; Purpose:
;;   Used to execute this operation on the given command set.
;;   Used with redo for the most part.
;;
function IDLitopEditDelete::UndoOperation, oCommandSet
   ;; Pragmas
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(not obj_valid(oTool))then $
     return, 0
   oCurrTool = (OBJ_ISA(oTool, 'IDLitSystem')) ? $
       oTool->_GetCurrentTool() : oTool

   oCmds = oCommandSet->Get(/all, count=nObjs)

   ;; Basically we are stashing the objects in the command sets.
   oCurrTool->DisableUpdates,PREVIOUSLY_DISABLED=previouslyDisabled
   for i=nObjs-1, 0, -1 do begin
        ;; Get the object
        if (oCmds[i]->getItem("O_VISUALIZATION", oVis) && $
            oCmds[i]->getItem("ID_VISUALIZATION", idVis)) then begin
           ;; Since we are dealing with live objects, when this item
           ;; is in the tree, remove it from the command object. Otherwise, it
           ;; will be destroyed when the command object is.
           iStatus = oCmds[i]->AddItem("O_VISUALIZATION", '', /overwrite)
           if(obj_valid(oVis))then begin
               iStatus = oCmds[i]->getItem("_PARENT", idParent)
               oParent = oTool->GetByIdentifier(idParent);
               if(iStatus eq 0 or not obj_valid(oParent))then $
                 oTool->Add, oVis $
               else BEGIN
                   iStatus = oCmds[i]->GetItem("POSITION", position)
                   if(iStatus eq 1 and position gt -1)then $
                     oParent->Add, oVis, POSITION=POSITION $
                   else $
                     oParent->Add, oVis
               ENDELSE

               ; Send an undelete message
               oVis->OnNotify, idVis, "UNDELETE", ''
               oVis->DoOnNotify, idVis, 'UNDELETE', ''

               ;; resume observing all contained data items of the vis
               IF obj_isa(oVis,'IDLitVisIDataSpace') THEN $
                 oTarget = oVis->GetVisualizations() $
               ELSE $
                 oTarget = oVis

                ; Loop over all contained viz, hook data
                ; back up and notify.
                for t=0, N_ELEMENTS(oTarget)-1 do begin
                    IF ~obj_isa(oTarget[t],'IDLitVisualization') THEN $
                        continue
                    oParams = oTarget[t]->GetParameter(/ALL,COUNT=cnt)
                    FOR k=0,cnt-1 DO begin
                        IF obj_isa(oParams[k],'IDLitData') THEN begin
                            oParams[k]->AddDataObserver,oTarget[t]

                            ; It is possible that the data has changed
                            ; since it was deleted (for example, via another
                            ; tool).  To be sure that the target has the
                            ; latest data, send an OnDataChangeUpdate
                            ; notification.
                            paramName = oTarget[t]->GetParameterName( $
                                oParams[k])
                            oTarget[t]->OnDataChangeUpdate, oParams[k], $
                                paramName
                        endif
                        idTarget = oTarget[t]->GetFullIdentifier()
                    endfor
                    ; Make sure we havn't already notified.
                    if (oTarget[t] ne oVis) then begin
                        oTarget[t]->OnNotify, idTarget, "UNDELETE", ''
                        oTarget[t]->DoOnNotify, idTarget, 'UNDELETE', ''
                    endif
               endfor

           endif

       endif else begin
         self->ErrorMessage, [IDLitLangCatQuery('Error:Framework:InvalidUndoRedoState'), $
                            self->GetFullIdentifier()], severity=1
         continue
       end
   endfor

   IF ~previouslyDisabled THEN $
     oCurrTool->EnableUpdates
   return, 1
end


;---------------------------------------------------------------------------
; IDLitopEditDelete::_GetTargets
;
; Purpose:
;   This function method returns a vector of references to the
;   target objects to be deleted.
;
;   If visualizations are currently selected, then a check is
;   made to determine whether deletion of those visualizations would
;   cause a dataspace to become empty.  If so, and it is the only
;   dataspace in the dataspace root, then use that dataspace
;   as the target instead of each of its individual visualization
;   contents.
;
;   Otherwise, the selected visualizations become the targets.
;
;   If no visualizations are selected, then the current viewgroup
;   is used as the target (assuming it is not the only remaining
;   view).
;
; Arguments:
;   oTool - A reference to the tool object.
;
; Return Value:
;   This function returns a vector of references to the target objects
;   to be deleted.
;
function IDLitopEditDelete::_GetTargets, oTool

    compile_opt idl2, hidden

    oWindow=oTool->GetCurrentWindow()

    ; Retrieve the currently selected item(s).
    oSelVis = oTool->GetSelectedItems(count=nSelVis)

    if (nSelVis gt 0) then begin

        oTargets = oSelVis
        nTargets = nSelVis

        ; Retrieve the dataspaces for the window.
        oView = (OBJ_VALID(oWindow) ? oWindow->GetCurrentView() : OBJ_NEW())
        oLayer = (OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW())
        oWorld = (OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW())
        nDS = 0
        oDS = (OBJ_VALID(oWorld) ? oWorld->GetDataSpaces(COUNT=nDS) : $
            OBJ_NEW())

        ; If no dataspaces exist, then there are no dataspaces to delete.
        ; If one dataspace exists, and it is about to be emptied,
        ; choose to delete it instead of its individual contents.
        ; If more than one dataspace exists, then we do not want to
        ; auto-delete any of the dataspaces (even if one or more becomes
        ; empty).
        if (nDS eq 1) then begin
            ; Determine whether the dataspace can be deleted in lieu of
            ; deleting each of its individual contents.

            ; Temporarily maintain a list of targets from which
            ; visualizations contained by this dataspace
            ; can be removed one by one.
            oTmpTargets = oTargets

            oDSVis = oDS->GetVisualizations(COUNT=nDSVis)
            if (nDSVis gt 0) then begin
                ; Check if all of the visualizations within the
                ; dataspace are selected (for deletion).
                nTotalMatch = 0
                nRem = 0
                for i=0,nDSVis-1 do begin
                    ; If nothing is left in culled target list, but
                    ; items still remain in the dataspace visualization
                    ; list, then we cannot delete the dataspace.
                    if (~OBJ_VALID(oTmpTargets[0])) then $
                        break

                    ; Is the visualization selected?
                    iMatch = WHERE(oTmpTargets eq oDSVis[i], nMatch, $
                    COMPLEMENT=iNonMatch, NCOMPLEMENT=nNonMatch)

                    if (iMatch ge 0) then begin
                        nTotalMatch += nMatch
                        ; Temporarily remove the visualization from
                        ; the target list, and add to a hold list.
                        oTmpTargets = (nNonMatch gt 0) ? $
                            oTmpTargets[iNonMatch] : OBJ_NEW()

                        oRemTargets = (nRem gt 0) ? $
                            [oRemTargets, oDSVis[i]] : oDSVis[i]
                        nRem++
                    endif
                endfor

                if (nTotalMatch eq nDSVis) then begin
                    ; All of the visualizations in the dataspace
                    ; are selected (for deletion).  Replace the
                    ; target list with all selections that do not
                    ; include these visualizations.
                    oTargets = oTmpTargets

                    ; Unselect the items removed from the
                    ; target list.  (They would have been
                    ; unselected anyway if they had been
                    ; deleted directly.)
                    for i=0,nRem-1 do $
                        oRemTargets[i]->Select, /UNSELECT, /SKIP_MACRO

                    ; If the dataspace is not already in the
                    ; target list, add it now.
                    iMatch = WHERE(oTargets eq oDS, nMatch)
                    if (nMatch eq 0) then begin
                        if (OBJ_VALID(oTargets[0])) then $
                             oTargets = [oTargets, oDS] $
                        else $
                             oTargets = oDS
                    endif
                endif ; all visualizations in dataspace to be deleted.
            endif ; dataspace contains visualizations
        endif ; number of dataspaces eq 1

    endif else begin
        ; If nothing selected, then retrieve the current viewgroup.
        ; Do not allow view to be deleted if layout is not freeform.
        oLayout = oWindow->GetLayout(POSITION=newLayout)
        oLayout->GetProperty, GRIDDED=gridded
        if (gridded) then begin
            self->ErrorMessage, $
       [ IDLitLangCatQuery('Error:Framework:CannotDeleteViewInGrid'), $
       IDLitLangCatQuery('Error:Framework:SwitchToFreeForm')], $
                TITLE=IDLitLangCatQuery('Error:Delete:Title'), severity=2
            return, obj_new()
        endif

        ; Do not allow user to delete last viewgroup.
        if (oWindow->Count() le 1) then begin
            self->ErrorMessage, IDLitLangCatQuery('Error:Framework:CannotDeleteOnlyView'), $
                TITLE=IDLitLangCatQuery('Error:Delete:Title'), severity=2
            return, obj_new()
        endif

        ; Delete the current viewgroup.
        oTargets = oWindow->GetCurrentView()

    endelse

    return, oTargets
end

;---------------------------------------------------------------------------
; IDLitopEditDelete::_DeleteTargets
;
; Purpose:
;   This procedure method deletes the given targets and adds
;   corresponding commands to the given command set.
;
; Arguments:
;   oTool - A reference to the tool object.
;
;   oCommandSet - A reference to the command set object.
;
;   oTargets - A vector of references to the target objects to be
;     deleted.
;
pro IDLitopEditDelete::_DeleteTargets, oTool, oCommandSet, oTargets, $
    oPropCmds

    compile_opt idl2, hidden

    nTarget = N_ELEMENTS(oTargets)
    idTarget = STRARR(nTarget)

    ; Unselect all of the targets before deleting any of them.
    ; This avoids problems where we delete a parent but
    ; its child was selected.
    for i=0,nTarget-1 do begin
        ; Cache the identifier so we can use it below.
        idTarget[i] = oTargets[i]->GetFullIdentifier()
        if (OBJ_VALID(oTargets[i])) then $
            oTargets[i]->Select, /UNSELECT, /SKIP_MACRO
    endfor

    for i=0,nTarget-1 do begin

        ; This may seem wasteful to do a GetByIdentifier again, but
        ; it has the benefit of returning a null obj for items
        ; whose (grand)parent has just been deleted, and therefore avoids
        ; needlessly deleting these items. This only works if the targets
        ; are sorted so that the items deeper in the tree are at the end.
        oTarget1 = oTool->GetByIdentifier(idTarget[i])

        ; Object may already be dead if its parent was just deleted.
        if (~OBJ_VALID(oTarget1)) then $
            continue

        ;; Remove target from its parent.
        oTarget1->GetProperty, _PARENT=oParent, PARENT=oRealParent
        if (~OBJ_VALID(oParent)) then $
            continue

        idParent = oParent->GetFullIdentifier()

        ; Retrieve the current position. Also sanity check to make
        ; sure object is indeed contained.
        if (~oParent->IsContained(oTarget1, position=position)) then $
            continue

        ; Must notify the visualizations before the dataspace is removed
        if (OBJ_ISA(oTarget1, 'IDLitVisIDataSpace')) then begin
            oVisualizations = oTarget1->GetVisualizations(COUNT=count, $
                /FULL_TREE)
            for j=0,count-1 do begin

              ;; Send a delete message
              oVisualizations[j]->OnNotify, $
                oVisualizations[j]->GetFullIdentifier(), "DELETE", ''
              oVisualizations[j]->DoOnNotify, $
                oVisualizations[j]->GetFullIdentifier(), 'DELETE', ''

              ;; stop observing all contained data items of the vis
              oParams = oVisualizations[j]->GetParameter(/ALL,COUNT=cnt)
              FOR k=0,cnt-1 DO $
                IF obj_isa(oParams[k],'IDLitData') THEN $
                oParams[k]->RemoveDataObserver,oVisualizations[j], $
                  /no_autodelete

            endfor
        endif

        ;; stop observing all contained data items of the vis
        IF obj_isa(oTarget1,'IDLitVisualization') THEN BEGIN
          oParams = oTarget1->GetParameter(/ALL,COUNT=cnt)
          FOR k=0,cnt-1 DO $
            IF obj_isa(oParams[k],'IDLitData') THEN $
            oParams[k]->RemoveDataObserver,oTarget1,/no_autodelete
        ENDIF

        ;; Tricky code. If we are deleting a dataspace, and our root
        ;; dataspace will have no other dataspaces, then reset the
        ;; model transform so that new dataspaces don't inherit the
        ;; old root transform.
        if (OBJ_ISA(oRealParent, 'IDLitVisDataSpaceRoot')) then begin
            oDS = oRealParent->IDLgrModel::Get(/ALL, COUNT=count, $
                ISA="IDLitVisIDataSpace")
            if (count eq 1) && (oDS EQ oTarget1) then begin
                ; Use Set prop service so that the transform gets restored
                ; if we undo our deletion.
                oProperty = oTool->GetService("SET_PROPERTY")
                ; Reset TRANSFORM to identity matrix.
                oPropCmd1 = oProperty->DoAction(oTool, $
                    oRealParent->GetFullIdentifier(), $
                    'TRANSFORM', IDENTITY(4))
                if (OBJ_VALID(oPropCmd1)) then begin
                    oPropCmds = (N_ELEMENTS(oPropCmds) gt 0) ? $
                        [oPropCmds, oPropCmd1] : oPropCmd1
                endif
            endif
        endif

        oParent->Remove, oTarget1

        ; Another sanity check to make sure the object is no longer
        ; contained. The parent may be unable to remove the target
        ; (such as a Light Container for example).
        if (oParent->IsContained(oTarget1)) then $
            continue

        ; Send a delete message
        oTarget1->OnNotify, idTarget[i], "DELETE", ''
        oTarget1->DoOnNotify, idTarget[i], 'DELETE', ''

        ; Now that we know the deletion was successful,
        ; record Undo-Redo information.
        oCmd = OBJ_NEW('IDLitCommand', TARGET_IDENTIFIER=idTarget[i])

        ; Add the values to the command object.
        iStatus = oCmd->AddItem("O_VISUALIZATION", oTarget1)
        iStatus = oCmd->AddItem("ID_VISUALIZATION", idTarget[i])
        iStatus = oCmd->AddItem("_PARENT", idParent)
        iStatus = oCmd->AddItem("POSITION", position)
        oCommandSet->Add, oCmd

    endfor
end

;---------------------------------------------------------------------------
; Purpose:
;   Perform the delete operation and return a command set.
;
; Result:
;   Returns a command set containing the undo/redo buffer.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   Target: An object reference (or array of objrefs) to delete.
;
; Keywords:
;   None.
;
function IDLitopEditDelete::_Delete, oTool, oTargets

    compile_opt idl2, hidden

    oWindow = oTool->GetCurrentWindow()

    ; Get a commmand set for this operation from the super-class.
    oCommandSet = self->IDLitOperation::DoAction(oTool)

    ; Turn off updates so each delete won't cause a draw.
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Delete the targets, and collect the corresponding commands.
    self->_DeleteTargets, oTool, oCommandSet, oTargets, oPropCmds

    ; Turn updates back on.
    if (~wasDisabled) then $
        oTool->EnableUpdates

    ;; Did anything happen?
    if(oCommandSet->Count() eq 0)then begin
        OBJ_DESTROY, oCommandSet
        return, OBJ_NEW()
    endif

    oTool->RefreshCurrentWindow

    if (OBJ_VALID(oWindow)) then $
      oTool->DoOnNotify, oWindow->GetFullIdentifier(), 'Added', 0

    return, (N_ELEMENTS(oPropCmds) gt 0) ? $
        [oPropCmds, oCommandSet] : oCommandSet

end


;;---------------------------------------------------------------------------
;; IDLitopEditDelete::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopEditDelete::DoAction, oTool
    compile_opt idl2, hidden

    oTargets = self->_GetTargets(oTool)

    if (~OBJ_VALID(oTargets[0])) then $
        return, OBJ_NEW()

    oCommandSet = self->IDLitopEditDelete::_Delete(oTool, oTargets)

    return, oCommandSet

end


;-------------------------------------------------------------------------
pro IDLitopEditDelete__define

    compile_opt idl2, hidden
    struc = {IDLitopEditDelete, $
        inherits IDLitOperation}

end

