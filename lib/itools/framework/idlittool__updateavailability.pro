; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlittool__updateavailability.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopTool
;
; PURPOSE:
;   This file implements thie update availablity functionalty for the
;   tool object. This is only a portion of the tool class
;   functionality. A user should consult IDLitTool__define.pro for
;   more information.
;
; CATEGORY:
;   IDL Tools
;
;;---------------------------------------------------------------------------
;; IDLitTool::_CheckItemsAvailability
;;
;; Purpose:
;;   This routine will do the actual type checking for the update
;;   system and broadcast out updates if they are needed.
;;
;; Parameters:
;;    dtSelected   - The types that are available in the selection
;;
;;    oItems       - The items to check
;;
;; Keywords
;;  None.
;;
pro IDLitTool::_CheckItemsAvailability, dtSelected, oItems

   compile_opt idl2, hidden

   ;; Check for valid input.
   nItems = n_elements(oItems)
   if(nItems eq 0)then return
   if(not obj_valid(oItems[0]))then return

   nTypes = n_elements(dtSelected)
   for i=0, nItems-1 do begin
       ;; Not a valid target, skip
       if(~obj_valid(oItems[i]))then $
           continue

       if (obj_isa(oItems[i], "IDLitContainer")) then begin
           ;; If a container, recurse.
           oChildren = oItems[i]->IDLitContainer::Get(/all, /skip_private, COUNT=count)
           if (count gt 0) then begin
                self->IDLitTool::_CheckItemsAvailability, dtSelected, oChildren
                ; Assume that because we are checking our children, that we
                ; don't need to check ourself.
                continue
           endif
       endif

        ; Query the item to see if it is available.
        bAvailable = oItems[i]->QueryAvailability(self, dtSelected)

        ; This will also broadcast a SENSITIVE message if necessary.
        oItems[i]->SetProperty, DISABLE=~bAvailable

   endfor
end


;;---------------------------------------------------------------------------
;; IDLitTool::_CheckManipAvailabilityByVis
;;
;; Purpose:
;;   The routine will check the availablity of manipulators that depend on
;;   the type of the manipulator targets of the visualization being displayed.
;;
;;   When complete, this routine has determine what is enabled and
;;   what is not and sent update messages out for items whose state
;;   has changed.
;;
pro IDLitTool::_CheckManipAvailabilityByVis, oSelItems, oManips

    compile_opt idl2, hidden

    nManips = N_ELEMENTS(oManips)
    if (nManips eq 0) then $
        return
    if (~OBJ_VALID(oManips[0])) then $
        return

    ; Collect all non-hidden visualizations from the selected items.
    nShow = 0
    if (OBJ_VALID(oSelItems[0])) then begin
        ;; First step is to get the viz types in the selection list.
        idx =  WHERE(OBJ_ISA(oSelItems, "_IDLitVisualization"), nItems)
        if (nItems gt 0) then $
            oSelItems = oSelItems[idx]

        ;; Prune out all hidden selections.
        for i=0, nItems-1 do begin
            ;; Check if the item is hidden.
            oSelItems[i]->GetProperty, HIDE=hidden
            if (~hidden) then begin
                oShowVis = (nShow gt 0) ? $
                    [oShowVis, oSelItems[i]] : oSelItems[i]
                nShow++
            endif
        endfor
    endif

    ; For all manipulators, collect the visualization types of the
    ; corresponding manipulator targets.
    for iManip=0,nManips-1 do begin

        parentManip = OBJ_NEW()
        if (OBJ_ISA(oManips[iManip], 'IDLitContainer')) then begin
            oChildManips = oManips[iManip]->IDLitContainer::Get(/ALL, $
                /SKIP_PRIVATE, COUNT=count)
            if (count gt 0) then begin
                self->_CheckManipAvailabilityByVis, oSelItems, oChildManips
                continue
            endif else $
                parentManip = oManips[iManip]
        endif

        dtSelected='' ;; always have a null type

        ;; For the visible selections, get the manipulator targets
        ;; associated with the current manipulator being checked.
        if (nShow gt 0) then begin
            oManipVis = oManips[iManip]->_FindManipulatorTargets( $
                oShowVis)

            nManipVis = N_ELEMENTS(oManipVis)
            if (nManipVis gt 0) then begin
                ;; Check if the manipulator targets are hidden.
                for i=0,nManipVis-1 do begin
                    if (~OBJ_VALID(oManipVis[i])) then continue
                    oManipVis[i]->GetProperty, HIDE=hidden
                    ;; If not hidden, add the type to the list.
                    if (~hidden) then $
                        dtSelected = [dtSelected, oManipVis[i]->GetTypes()]
                endfor
            endif
        endif

        ;; Note for me: The compile of Uniq() add time to the first use of
        ;; this, but after that is is the same as a series of for
        ;; loops. In addition, for larger data type lists, this will be the
        ;; most efficent.
        ;; If an item is hidden, no operations should be available. If
        ;; this is the case, put in an invalid tag
        dtSelected = dtSelected[UNIQ(dtSelected, SORT(dtSelected))]

        self->IDLitTool::_CheckItemsAvailability, dtSelected, $
            (OBJ_VALID(parentManip) ? parentManip : oManips[iManip])
    endfor
end


;;---------------------------------------------------------------------------
;; IDLitTool::_CheckAvailabilityByVis
;;
;; Purpose:
;;   The routine will check the availablity of actions that depend on
;;   the type of visualization being displayed and not the underlying
;;   data. Good example is an ROI on an Image.
;;
;;   When complete, this routine has determine what is enabled and
;;   what is not and sent update messages out for items whose state
;;   has changed.
;;
pro IDLitTool::_CheckAvailabilityByVis, oItems

    compile_opt hidden, idl2

    dtSelected='' ;; always have a null type
    ;; if nothing is selected, skip test
    if(obj_valid(oItems[0]))then begin

        ;; First step is to get the viz types in the selection list.
        idx =  where(obj_isa(oItems, "_IDLitVisualization"), nItems)
        if(nItems gt 0)then $
          oItems = oItems[idx]
        hidden=0
        ;; Get the type of each item.
        for i =0, nItems-1 do begin
            if(obj_valid(oItems[i]))then begin
                ;; If an item is hidden, it is not available!
                oItems[i]->GetProperty, hide=hidden
                if(hidden ne 0)then break
                dtSelected = [dtSelected,oItems[i]->getTypes()]
            endif
        endfor
        ;; Note for me: The compile of Uniq() add time to the first use of
        ;; this, but after that is is the same as a series of for
        ;; loops. In addition, for larger data type lists, this will be the
        ;; most efficent.
        ;; If an item is hidden, no operations should be available. If
        ;; this is the case, put in an invalid tag
        dtSelected = (hidden ne 0 ? "" : dtSelected[UNIQ(dtSelected, SORT(dtSelected))])
    end

    ;; Check the manipulators.  This requires a special path
    ;; because the type matching needs to be relative to manipulator
    ;; targets (as opposed to the simple window selections).
    oOps = self->GetByIdentifier("Manipulators")
    IF obj_valid(oOps) THEN $
      self->IDLitTool::_CheckManipAvailabilityByVis, oItems, oOps

    oOps = self->GetByIdentifier("Operations/File")
    IF obj_valid(oOps) THEN begin
      self->IDLitTool::_CheckItemsAvailability, dtSelected, $
        oOps->IDL_Container::Get(/all)
    endif

    oOps = self->GetByIdentifier("Operations/Edit")
    IF obj_valid(oOps) THEN begin
      self->IDLitTool::_CheckItemsAvailability, dtSelected, $
        oOps->IDL_Container::Get(/all)
    endif

end


;;---------------------------------------------------------------------------
;; IDLitTool::_CheckAvailabilityByData
;;
;; Purpose:
;;   Using both the visualization types and the data items that underlay
;;   the items contained in oItems,
;;   this routine will determine what operations are available and
;;   what are not. Once determined, this disable/enable message is
;;   broadcast to those interested.
;;
;; Parameters
;;    oItems - Items to validate against
;;
pro IDLitTool::_CheckAvailabilityByData, oItems

     compile_opt hidden, idl2

    dtSelected='' ;; always have a null type

    ;; if nothing is selected, the null type is used.
    if(obj_valid(oItems[0]))then begin

        ;; First step is to get the data types in the selection list.
        idx =  where(obj_isa(oItems, "_IDLitVisualization"), nItems)
        if(nItems gt 0)then $
          oItems = oItems[idx]

        hidden=0
        for i =0, nItems-1 do begin

            oItems[i]->GetProperty, hide=hidden
            ; If any selected viz are hidden, don't allow any operations.
            if(hidden ne 0)then $
                break

            ; First retrieve our visualization types,
            ; and our manipulator target types (in case there are operations
            ; that operate only on the manipulator target).
            dtSelected = [dtSelected, oItems[i]->GetTypes()]
            oManipTarget = oItems[i]->GetManipulatorTarget()
            if ((oManipTarget ne oItems[i]) && OBJ_VALID(oManipTarget)) then $
                dtSelected = [dtSelected, oManipTarget->GetTypes()]

            ; Make sure we support the parameter interface.
            if (~OBJ_ISA(oItems[i], 'IDLitParameter')) then $
                continue

            ; Retrieve all of our data types (only for our optargets).
            oDataItems = oItems[i]->GetParameter(/OPTARGETS)
            if(not obj_valid(oDataItems[0]))then $
              continue
            for j=0, n_elements(oDataItems)-1 do begin
                if(obj_valid(oDataItems[j]))then $
                  dtSelected = [dtSelected,oDataItems[j]->getTypes()]
            endfor

        endfor
        ;; Note for me: The compile of Uniq() adds time to the first use of
        ;; this, but after that is is the same as a series of for
        ;; loops. In addition, for larger data type lists, this will be the
        ;; most efficent.
        ;;----
        ;; If an item is hidden, no operations should be available. If
        ;; this is the case, put in an invalid tag
        dtSelected = (hidden ne 0 ? "<invalid>" : dtSelected[UNIQ(dtSelected, SORT(dtSelected))])
    end

    ;; The types of the underlying data objects are now known and
    ;; contained in dtSelected. Now have those compaired with the operations

    oOps = self->GetByIdentifier("Operations/Operations")
    IF obj_valid(oOps) THEN $
      self->IDLitTool::_CheckItemsAvailability, dtSelected, $
      oOps->IDL_Container::Get(/all)

    oOps = self->GetByIdentifier("Operations/Insert")
    IF obj_valid(oOps) THEN $
      self->IDLitTool::_CheckItemsAvailability, dtSelected, $
      oOps->IDL_Container::Get(/all)

end


;;---------------------------------------------------------------------------
;; IDLitTool::UpdateAvailability
;;
;; Purpose:
;;   Using the currently selected items, determine what operations are
;;   valid for the current state of the tool and boadcast this to
;;   items interested in knowning this information (primarly the UI).
;;
;; Parameters:
;;   None
;;
PRO IDLitTool::UpdateAvailability

    compile_opt hidden, IDL2

    oItems= self->GetSelectedItems()

    self->IDLitTool::_CheckAvailabilityByData, oItems
    self->IDLitTool::_CheckAvailabilityByVis, oItems

end
