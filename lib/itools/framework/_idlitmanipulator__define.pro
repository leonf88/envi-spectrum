; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitmanipulator__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   _IDLitManipulator
;
; PURPOSE:
;   Abstract class for the manipulator system of the IDL component framework.
;   The class will not be created directly, but defines the basic
;   structure for the manipulator system.
;
;   Due to class hierarchies required for the manipulation system,
;   this class was created. It implements the base manipulation
;   systems for the IDL Tools component system, but it doens't
;   sub-class from the IDLitComponent. It depends on the classes that
;   sub-class from it to also sub-class from the IDLitComponent
;   class.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   None.
;
; SUBCLASSES:
;
; CREATION:
;   See _IDLitManipulator::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; _IDLitManipulator::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;   None.
;
; Keywords:
;    TYPES - The types this manipulator works iwth
;
;    All other keywords are passed to the SetProperty method.
;
function _IDLitManipulator::Init, $
    TYPES=TYPES, $
    SKIP_MACROHISTORY=SKIP_MACROHISTORY, $
    VIEWS_ONLY=VIEWS_ONLY, $
    DRAG_QUALITY=DragQual, $  ;; DRAG_QUALITY does not do anything. BC issue
    _REF_EXTRA=_EXTRA

   compile_opt idl2, hidden

    if (~self->IDLitiMessaging::Init(_EXTRA=_extra)) then $
        return, 0

   self.pSelectionList = PTR_NEW(/Allocate_Heap)
   self._defaultCursor = 'ARROW'
   self._numberDS = '0+'

    self._types = ptr_new('')
    if (n_elements(types) gt 0) then $
        *self._types = types

    ; Set defaults for events
    self._uiEventMask = Make_Event_Mask(/BUTTON_EVENTS, $
        /MOTION_EVENTS, /KEYBOARD_EVENTS)

    if(keyword_Set(VIEWS_ONLY))then $
      self._viewMode = 1

    if(keyword_Set(SKIP_MACROHISTORY))then $
      self._skipMacroHistory = 1

    self._DraqQual = 2
    IF (keyword_Set(DragQual)) && (DragQual GE 0) && (DragQual LE 2) then $
      self._DraqQual = DragQual
    self._oldQuality = -1

    ; Initialize the normalized Z location to be almost (but not quite)
    ; on the near clipping plane.
    self._normalizedZ = -0.99d

    self._pSubHitList = PTR_NEW(/ALLOCATE)

    ; Anything to send to the SetProperty method?
    if (N_Elements(_extra) gt 0) then $
        self->_IDLitManipulator::SetProperty, _EXTRA=_extra

   return, 1
end


;--------------------------------------------------------------------------
; _IDLitManipulator::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro _IDLitManipulator::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oCmdSet
    PTR_FREE, self.pSelectionList
    PTR_FREE, self._types
    PTR_FREE, self._pSubHitList
end


;--------------------------------------------------------------------------
; _IDLitManipulator::_Select
;
; Purpose:
;   Implements the _Select method. This method will determine what was
;   selected given the provided parameters. The selected items are
;   marked as selected and selection visuals associated with them. If
;   nothing is selected, the selection state of the tool is cleared.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
pro _IDLitManipulator::_Select, oWin, x, y, iButton, KeyMods, nClicks, $
                                TARGET=oTarget

    compile_opt idl2, hidden

    ; First check if we already did a DoHit Test in
    ; IDLitManipulatorContainer::OnMouseDown. If so, use the cached
    ; values instead of repeating the expensive DoHitTest.
    if (SIZE(*self._pSubHitList, /TYPE) ne 11) then begin
        ; Check to see if we hit any visualizations.
        oVisList = oWin->DoHitTest(x, y, DIMENSIONS=[9,9], /ORDER, $
                                   SUB_HIT=oSubHitList, $
                                   VIEWGROUP=oHitViewGroup)
        void = CHECK_MATH()  ; swallow underflow errors
        oVis = oVisList[0]  ; Let's only use the first item hit
    endif else begin
        ; Retrieve our cached copies, as set by
        ; IDLitManipulatorContainer::OnMouseDown.
        oVis = self._oHitVis
        oSubHitList = *self._pSubHitList
        oHitViewGroup = self._oHitViewGroup

        ; Clear out the subhitlist and reset its flag so if we come
        ; thru here again we will call DoHitTest. This is just for extra
        ; safety, since presumably we will again go thru
        ; IDLitManipulatorContainer::OnMouseDown and the cache will be set.
        *self._pSubHitList = -1
    endelse

    if OBJ_ISA(oVis, 'IDLitManipVisScale') then begin
      oTarget=oVis->GetManipulatorTarget()
    endif

;    ; Handle axis select
;    if (OBJ_ISA(oVis, 'IDLitVisAxis') && (keyMods eq 0)) then begin
;      oDS = oVis->GetDataSpace()
;      oSelected = oWin->GetSelectedItems()
;      !NULL = where(oDS eq oSelected, cnt)
;      if (cnt eq 0) then begin
;        oVis = oDS
;        self->GetProperty, _PARENT=oP
;        if (OBJ_ISA(oP, '_IDLitManipulator')) then $ 
;          oP->SetCurrentManipulator, 'Translate'
;      endif
;    endif
    
    ; Note: All manipulator settings and redrawing is peformed
    ; outside this routine, allowing these resource intensive
    ; actions to be minimized and requests collapsed.

    ; If a viewgroup was hit, then set it as current.
    if (OBJ_VALID(oHitViewGroup)) then begin
        oHitViewGroup->GetProperty, PARENT=oParent
        if (~OBJ_VALID(oParent)) then $
            oHitViewGroup = OBJ_NEW()
    endif

    if (OBJ_VALID(oHitViewGroup)) then begin

        ; Setting the current view will also clear out old selections.
        if (oWin->GetCurrentView() ne oHitViewGroup) then $
            oWin->SetCurrentView, oHitViewGroup

        ; At the very least, set the selection to be the viewgroup.
        ; This will be reset in OnMouseDown if an actual viz was hit.
        *self.pSelectionList = oHitViewGroup
        self.nSelectionList = 1
    endif else begin

        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->ActivateManipulator, /DEFAULT
        oWin->ClearSelections

        ; Clear out the selection list.
        *self.pSelectionList = OBJ_NEW()
        self.nSelectionList = 0

    endelse


    if (OBJ_VALID(oVis) && ~self._viewMode && $
        OBJ_ISA(oVis, '_IDLitVisualization')) then begin

        ; Determine which item should be selected.
        oVis = oVis->GetHitVisualization(oSubHitList)

        ; Verify that we are allowed to use this manipulator for this vis.
        ; Do not allow manipulator visuals to be selected.
        if (~OBJ_ISA(oVis, 'IDLitManipulatorVisual')) then begin

            ; Match viz types to manip types.
            oTargets = self->_FindManipulatorTargets(oVis)
            if (~OBJ_VALID(oTargets[0])) then begin
                oTool = self->GetTool()
                if (OBJ_VALID(oTool)) then $
                    oTool->ActivateManipulator, /DEFAULT
                oWin->ClearSelections
            endif

            ; Select according to the key modifiers.
            wasSelected = oVis->IsSelected()
            oVis->Select, ADDITIVE=((KeyMods and 1) gt 0), $
                          TOGGLE=((KeyMods and 2) gt 0)
            ; Note: Selection visuals will be updated as part of the
            ; draw logic (by the tool).
        endif  ; not IDLitManipulatorVisual

    endif else begin
       ; If we hit nothing, just select the hit viewgroup (this will clear
       ; out old selections).
       if (OBJ_VALID(oHitViewGroup)) then $
            oHitViewGroup->Select, /SELECT
   endelse

end


;--------------------------------------------------------------------------
; _IDLitManipulator::_FindManipulatorTargets
;
; Purpose:
; Internal method to retrieve the list of manipulator targets associated
; with a list of visualizations. Duplicates are removed.
; Most objects will allow the DataSpace they are contained in to be the
; Manipulator target.  But some, such as ROI's will be the manip target.
; All DataSpaces are assumed to be manipulator targets.
;
; Keywords
;    MERGE
;    If set, any found targets that are not in the provided vis list
;    are merged with the provided list. If not set, the parent will
;    override the given visualization.
;
function _IDLitManipulator::_FindManipulatorTargets, oVisIn, $
                            MERGE=MERGE
    compile_opt idl2, hidden

    if (~OBJ_VALID(oVisIn[0])) then $
        return, OBJ_NEW()

    ; If this manipulator has any valid type strings, check for type matches
    ; among the selected items (and their parents) .
    ; Otherwise, search for general manipulator targets among the selected
    ; items (and their parents).
    bCheckTypes = (MAX(*self._types eq '') ne 1)

    oVis = oVisIn   ; make a copy
    for i=0, N_ELEMENTS(oVis)-1 do begin
        oParent = oVis[i]
        while OBJ_VALID(oParent) do begin

            if (~OBJ_ISA(oParent, "_IDLitVisualization")) then begin
                oVis[i] = OBJ_NEW()
                break   ; done with while
            endif

            ; Depending upon the bCheckTypes flag, check for a type match
            ; or check if this vis is a manipulator target.
            if (bCheckTypes) then begin
                if (oParent->MatchesTypes(*self._types)) then begin
                    if(keyword_set(MERGE))then begin
                        if (oParent ne oVis[i]) then $
                            oVis = [oVis, oParent]
                    endif else begin
                       oVis[i] = oParent
                    endelse
                    break   ; done with while
                endif else if (oParent->IsManipulatorTarget()) then begin
                    ; If type-matching is to occur, and the visualization
                    ; does not match the type, then no target was found.
                    oVis[i] = OBJ_NEW()
                    break   ; done with while
                endif
            endif else begin
                ; No type matching is to occur.  Simply look for a
                ; manipulator target.
                if (oParent->IsManipulatorTarget()) then begin
                    if(keyword_set(MERGE))then begin
                        if (oParent ne oVis[i]) then $
                            oVis = [oVis, oParent]
                    endif else $
                       oVis[i] = oParent
                    break   ; done with while
                endif
            endelse

            oParent->IDLgrModel::GetProperty, PARENT=oTmp
            oParent = oTmp

        endwhile
        if ~OBJ_VALID(oParent) then $
            oVis[i] = OBJ_NEW()
    endfor

    good = WHERE(OBJ_VALID(oVis), ngood)
    if (ngood eq 0) then $
        return, OBJ_NEW()

    ; Remove dups. Can't use UNIQ because we need to preserve the order.
    oUniqVis = oVis[good[0]]
    for i=1, ngood-1 do begin
        if (TOTAL(oUniqVis eq oVis[good[i]]) eq 0) then $
            oUniqVis = [oUniqVis, oVis[good[i]]]
    endfor

    return, oUniqVis
end


;--------------------------------------------------------------------------
; _IDLitManipulator::_NotifyTargets
;
; Purpose:
;   Internal method to notify the list of manipulator targets that
;   they are about to be manipulated, or that manipulation is complete.
;
; Keywords:
;   COMPLETE: Set this keyword to a nonzero value to indicate that
;     the targets should be notified that manipulation is complete.
;     By default, targets are notified that manipulation is about to
;     commence.
;
pro _IDLitManipulator::_NotifyTargets, oTargets, $
    COMPLETE=complete

    compile_opt idl2, hidden

    nTargets = N_ELEMENTS(oTargets)
    if (nTargets eq 0) then $
        return

    if (KEYWORD_SET(complete)) then begin
        for i=0,nTargets-1 do begin
            if (OBJ_ISA(oTargets[i], '_IDLitVisualization')) then $
                oTargets[i]->EndManipulation, self
        endfor
    endif else begin
        for i=0,nTargets-1 do begin
            if (OBJ_ISA(oTargets[i], '_IDLitVisualization')) then $
                oTargets[i]->BeginManipulation, self
        endfor
    endelse
end


;--------------------------------------------------------------------------
;--------------------------------------------------------------------------
; IIDLManipulator Event Interface Section
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; _IDLitManipulator::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
;
pro _IDLitManipulator::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect, TARGET=oTarget

   compile_opt idl2, hidden

   ; Stash the button state for the users.
   ;
   ; Note: this button state setting should occur prior to the ::_Select
   ; call, since it may cause the ::OnLoseCurrentManipulator method to be
   ; called if no valid visualization targets for this manipulator are
   ; selected.  In this case, the button press state will be reset.
   self.ButtonPress = iButton

   ; Do a selection operation
   if (~KEYWORD_SET(noSelect)) then $
       self->_Select, oWin, x, y , iButton, KeyMods, nClicks, TARGET=oTarget

   if(not self._viewMode)then begin
       ; Retrieve the list of selected items, and the associated dataspace.
       oSelected = oWin->GetSelectedItems()
       oSelected = self->_FindManipulatorTargets(oSelected)

       ; Notify targets that they are about to be manipulated.
       self->_NotifyTargets, oSelected

       ; Stash for the users
       *self.pSelectionList = oSelected
       self.nSelectionList = (OBJ_VALID(oSelected[0])) ? $
         N_ELEMENTS(oSelected) : 0
   endif

   ; Handle transient motion. If set, make sure motion events are
   ; enabled between mouse down and mouse up. Also preserve if
   ; current events are enabled or not on the window and manipulator.
   if (self.nSelectionList && self._TransMotion) then begin
       ; Check current window settings
       eventMask = oWin->GetEventMask(MOTION_EVENTS=bMotionEvents)
       ; Store the old value so we can re-set it in OnMouseUp.
       if (bMotionEvents) then $
         self._InTransMotion or= 1b $
       else $ ; enable motion events
           oWin->SetEventMask, eventMask, /MOTION_EVENTS

       ; Check manipulator settings.
       ; Are motion events enabled by default?
       self->GetProperty, MOTION_EVENTS=motion
       if(motion)then $
         self._InTransMotion or= 2b $
       else $
         self->SetProperty, /MOTION_EVENTS
   endif
   ; Quality logic.
   IF ((~OBJ_ISA(self,'IDLitManipAnnotation')) && $
       (OBJ_ISA(oWin, '_IDLitgrDest'))) THEN BEGIN
         oWin->GetProperty, drag_quality=dragqual, quality=qual
     if(qual ne dragQual)then begin
       oWin->SetProperty, quality=dragQual
       self._oldQuality=qual
     endif else begin
       self._oldQuality =-1
     endelse
   ENDIF

end


;--------------------------------------------------------------------------
; _IDLitManipulator::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
;  Note: actions that occur within this method typically also occur
;   within the ::OnLoseCurrentManipulator  method.
;
; Parameters
;      oWin    - Source of the event
;      x       - X coordinate
;      y       - Y coordinate
;      iButton - Mask for which button released
;
pro _IDLitManipulator::OnMouseUp, oWin, x, y, iButton

   compile_opt idl2, hidden

   ; Restore settings modified by transient motion.
   ; Do we need to disable motion events?
   if (self.nSelectionList && self._TransMotion) then begin

       ; If motion events were not previously enabled,
       ; remove motion event sending.
       if (~(self._InTransMotion and 1b)) then begin
           eventMask = oWin->GetEventMask()
           oWin->SetEventMask, eventMask, MOTION_EVENTS=0
       endif

       ; Were motion events enabled for this manipulator
       if(~(self._InTransMotion and 2b))then $
         self->SetProperty, motion_events=0

       ; Clear out temp flags
       self._InTransMotion = 0b
   endif

   ; Clear out the current selection list reference.
   self.ButtonPress    = 0         ; button is up
   self.nSelectionList = 0
   if(n_elements(*self.pSelectionList) gt 0)then begin
      ; Notify targets that they are about to be manipulated.
      self->_NotifyTargets, *self.pSelectionList, /COMPLETE

      void = temporary(*self.pSelectionList) ; clear out list
   endif

   IF ~obj_isa(self,'IDLitManipAnnotation') THEN BEGIN
     if(self._oldQuality ne -1)then BEGIN
       oWin->SetProperty, quality=self._oldQuality
       oTool = self->GetTool()
       if (OBJ_VALID(oTool)) then $
           oTool->RefreshCurrentWindow
     endif
   ENDIF

end


;--------------------------------------------------------------------------
; _IDLitManipulator::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method. If no mouse button is down,
;   this routine will manage setting the cursor on the window.
;
; Parameters
;     oWin    - Event Window Component
;     x       - X coordinate
;     y       - Y coordinate
;     KeyMods - Keyboard modifiers for button
;
; NOTES:
;   A MouseDown and a MouseUp event bracket a manipulator
;   transaction. The selection list contents will not change between
;   these two operations.
;
;   The current selection list is contained in self.pSelectionList and
;   the number of items in the list are in self.nSelectionList.
;
pro _IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden

    ; If a button is held down, just see if the cursor has changed,
    ; due to different KeyMods. Then return.
    if (self.ButtonPress gt 0) then begin
        cursorName = self->GetCursorType(self._subtype, KeyMods)
        oWin->SetCurrentCursor, cursorName ne '' ? cursorName : $
            self._defaultCursor        ;default name.
        return
    endif

   ; The rest of this method is to change cursors if needed.
   if (ISA(self, 'IDLitManipAnnotation')) then begin
     oWin->SetCurrentCursor, 'CROSSHAIR'
     return
   endif
   
   cursorName = 'ARROW'

   ; Check to see if we hit any visuals
   oVisHitList = oWin->DoHitTest(x, y, DIMENSIONS=[9,9], /ORDER, $
                                  SUB_HIT=oSubHitList, VIEWGROUP=oView)
   void = CHECK_MATH()  ; swallow underflow errors
   oVisHit = oVisHitList[0]   ; just check first item
   statusLoc = ''
   statusMsg = ''

   if OBJ_VALID(oVisHit) && OBJ_ISA(oVisHit, '_IDLitVisualization') then begin
       ; Something got hit, so switch to a default/hit cursor cursor.
       cursorName = self._defaultCursor

       ; Check if a manipulator visual has been hit.
       ; This code is the same as that in
       ; IDLitManipulatorContainer::OnMouseDown.
       oManipVis = OBJ_NEW()
       if (OBJ_ISA(oVisHit, 'IDLitManipulatorVisual')) then begin
           oManipVis = oVisHit
       endif else begin
           n = N_ELEMENTS(oSubHitList)
           for i=0,n-1 do begin
               if OBJ_ISA(oSubHitList[i], 'IDLitManipulatorVisual') then begin
                   ; Here is our manipulator visual.
                   oManipVis = oSubHitList[i]
                   ; Only keep the subvis's after the manip visual.
                   oSubHitList = oSubHitList[(i+1)< (n-1):*]
                   break        ; we're done
               endif
           endfor
       endelse

       oDS = oVisHit->GetDataSpace()
       if (OBJ_VALID(oDS)) then begin
          oWin->GetProperty, VISIBLE_LOCATION=vLocation
          oVisHit->WindowToVis, x - vLocation[0], y - vLocation[1], 0, xdata, ydata, zdata
          statusLoc = oVisHit->GetDataString([xdata, ydata, zdata])
       endif else begin
         ; Do a pickdata to retrieve the data coordinates.
         oLayer = oView->GetCurrentLayer()
         ; Use a 9x9 pickbox to match our selection pickbox.
         result = oWin->Pickdata(oLayer, oVisHit, [x, y], xyz, $
             DIMENSIONS=[9,9], PICK_STATUS=pickStatus)
         if (result eq 1) then begin
             ; Start from middle of array and work outwards to find
             ; the hit closest to the center.
             for n=0,4 do begin
                 good = (WHERE(pickStatus[4-n:4+n,4-n:4+n] eq 1))[0]
                 if (good ge 0) then begin
                     ; index into the subrect of the original 9x9,
                     ; the width of the subrect is 2n+1.
                     indexX = 4 - n + (good mod (2*n+1))
                     indexY = 4 - n + (good /   (2*n+1))
                     statusLoc = oVisHit->GetDataString( $
                         xyz[*, indexX, indexY])
                     break
                 endif
              endfor
          endif
        endelse

        ; If we hit a manipulator visual, change the current
        ; manipulator.
        if (OBJ_VALID(oManipVis)) then begin

            ; Set the cursor using the manipulator type.
            ; Check for global manipulator first.
            type = oManipVis->GetSubHitType(oSubHitList)
            cursorName = self->GetCursorType(type, KeyMods)
            statusMsg = self->GetStatusMessage(type, KeyMods, $
                /FOR_SELECTION)

        endif else begin         ;we are over a selected item

            ; Are any items selected?
            oSelectedVis = (oWin->GetSelectedItems())[0]

            ; If the Manipulator Targets for the selected item and the
            ; hit item are the same, then assume we are allowed to manipulate
            ; the hit item, and change the cursor.
            if (OBJ_VALID(oSelectedVis) && $
                ARRAY_EQUAL(self->_FindManipulatorTargets(oSelectedVis), $
                    self->_FindManipulatorTargets(oVisHit))) then begin
                oSelectionVisual = $
                    oSelectedVis->GetCurrentSelectionVisual()
                if (OBJ_VALID(oSelectionVisual)) then begin
                    ; Set the cursor using the manipulator type.
                    type = oSelectionVisual->GetSubHitType(oSubHitList)
                    cursorName = self->GetCursorType(type, KeyMods)
                    statusMsg = self->GetStatusMessage(type, KeyMods, $
                        /FOR_SELECTION)
                endif
            endif else $
                statusMsg = self->GetStatusMessage('', KeyMods)

            ; If no status message yet, retrieve the hit viz name.
            if (statusMsg eq '') then begin
                oStatusVis = oVisHit->GetHitVisualization(oSubHitList)
                oStatusVis->IDLitComponent::GetProperty, NAME=statusMsg
            endif

       endelse                  ; look for selected items
   endif

    ; Display the location in the status area.
    if (statusLoc eq '') then begin
        oWin->GetProperty, VISIBLE_LOCATION=visibleLoc
        statusLoc = STRING(FORMAT='(%"[%d,%d]")', $
            visibleLoc[0]+x, visibleLoc[1]+y)
    endif
    self->ProbeStatusMessage, statusLoc

    ; If we don't have a status message, use our own description.
    if (statusMsg eq '') then $
        self->IDLitComponent::GetProperty, DESCRIPTION=statusMsg

    ; Update the status message.
    self->StatusMessage, statusMsg

    ; Finally, set the cursor.
    oWin->SetCurrentCursor, cursorName ne '' ? cursorName : 'ARROW'

end


;--------------------------------------------------------------------------
; _IDLitManipulator::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method. This is a no-op and only used
;   to support the Window event interface.
;
; Parameters
;      oWin        - Event Window Component
;      IsAscii     - The the value a character or ASCII value?
;      Character   - The ASCII character of the key pressed.
;      KeyValue    - The value of the key pressed.
;                    1 - BS, 2 - Tab, 3 - Return
;      X           - The location the keyboard entry began at (last
;                    mousedown)
;      Y           - The location the keyboard entry began at (last
;                    mousedown)
;      press       - 1 if keypress, 0 if not
;
;      release     - 1 if keypress, 0 if not
;
;      Keymods     - Set to values of any modifier keys.
;
pro _IDLitManipulator::OnKeyBoard, oWin, IsASCII, Character, $
                     KeyValue, X, Y, Press, Release, KeyMods

   compile_opt idl2, hidden
   ; Abstract method.
end

;--------------------------------------------------------------------------
; _IDLitManipulator::OnWheel
;
; Purpose:
;   Implements the OnWheel method. This is a no-op and only used
;   to support the Window event interface.
;
; Parameters
;   oWin: The source of the event
;   X: The location of the event
;   Y: The location of the event
;   delta: direction and distance that the wheel was rolled.
;       Forward movement gives a positive value,
;       backward movement gives a negative value.
;   keymods: Set to values of any modifier keys.
;
pro _IDLitManipulator::OnWheel, oWin, x, y, delta, keyMods

    compile_opt idl2, hidden
   ; Abstract method.
end

;---------------------------------------------------------------------------
; _IDLitManipulator::GetWindowEventMask
;
; Purpose:
;   Return our event mask. Required for IDLitManipulatorContainer.
;
function _IDLitManipulator::GetWindowEventMask

    compile_opt idl2, hidden

    return, self._uiEventMask
end

;---------------------------------------------------------------------------
; UpdateSelectionVisuals
;
; Purpose:
;   This method will update the selection visuals on the selected
;   visualizations for the given window to be appropriate for
;   this manipulator.  The window calls this method in the tree
;   when it is notified that the manipulator has changed.
;
; Parameter
;    oWin   - The IDLitWindow that is to have the manipulator visuals
;             changed.
;
PRO _IDLitManipulator::UpdateSelectionVisuals, oWin

   compile_opt idl2, hidden

   if(not obj_valid(oWin[0]))then return

    ; Get the list of currently selected items in the window.
    oVis = oWin->GetSelectedItems()

    oTargets = self->_FindManipulatorTargets(oVis, /merge)
    for i=0,N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_VALID(oTargets[i])) then $
            oTargets[i]->SetCurrentSelectionVisual, self
    endfor

END


;---------------------------------------------------------------------------
; ResizeSelectionVisuals
;
; Purpose:
;   This method will resize the selection visuals (associated with
;   this manipulator) on the selected visualizations for the given window.
;   This method is called whenever an operation has occurred that
;   may require a re-scaling.
;
; Parameter
;    oWin   - The IDLitWindow that is to have the manipulator visuals
;             updated.
;
PRO _IDLitManipulator::ResizeSelectionVisuals, oWin

   compile_opt idl2, hidden

   if (~OBJ_VALID(oWin)) then return

    ; Get the list of currently selected items in the window.
    oVis = oWin->GetSelectedItems()

    oTargets = self->_FindManipulatorTargets(oVis, /MERGE)
    for i=0,N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_ISA(oTargets[i],'_IDLitVisualization')) then begin
            oTargets[i]->UpdateSelectionVisual

            oManipTarget = oTargets[i]->GetManipulatorTarget()
            if (OBJ_VALID(oManipTarget) && $
               (oManipTarget ne oTargets[i])) then begin
                oManipTarget->UpdateSelectionVisual
            endif
        endif
    endfor

END


;---------------------------------------------------------------------------
; Properties
;---------------------------------------------------------------------------
; _IDLitManipulator::GetProperty
;
; Purpose:
;    Used to get _IDLitManipulator specific properties.
;
; Arguments:
;  None
;
; Keywords:
;    VISUAL_TYPE   -  The type of the selection visual
;                     associated with this manipulator
;
;    TRANSIENT_DEFAULT
;                   - Used to indicated that the manipulation is
;                     "transient", which is used to indicated that a
;                     manipulator should operate once and then have
;                     the manipulator manager switch back to it's
;                     default mode.
;
;    TRANSIENT_MOTION
;                   - If set, the manipulator is operating in a
;                     transient motion event mode. In this mode, the
;                     manpulator will enable motion events on mouse
;                     down and disable them on mouse up.
;
;    TYPES          - The visualization types this manipulator
;                     supports.
;
;    OPERATION_IDENTIFIER
;                   - The identifier of the operation this
;                     manipulator uses.
;
;    PARAMETER_IDENTIFIER
;                   - If a parameter is used (property) as part of
;                     this manipulators actions, this is the name of
;                     that parameter.
;
;    BUTTON_EVENTS  - Will contain a true value if button events are
;                     enabled and a false value if they are not.
;
;    MOTION_EVENTS  - Will contain a true value if motion events are
;                     enabled and a false value if they are not.
;
;    KEYBOARD_EVENTS - Will contain a true value if keyboard events are
;                     enabled and a false value if they are not.
;
pro _IDLitManipulator::GetProperty, $
    NORMALIZED_Z=normalizedZ, $
    VISUAL_TYPE=visualType, $
    OPERATION_IDENTIFIER=OPERATION_IDENTIFIER, $
    PARAMETER_IDENTIFIER=PARAMETER_IDENTIFIER, $
    TRANSIENT_DEFAULT=TRANSIENT, $
    TRANSIENT_MOTION=TRANSIENT_MOTION, $
    TYPES=TYPES, $
    DISABLE=disable, $
    BUTTON_EVENTS=buttonEvents, $
    MOTION_EVENTS=motionEvents, $
    KEYBOARD_EVENTS=keyEvents, $
    WHEEL_EVENTS=wheelEvents, $
    DRAG_QUALITY=DragQual


   compile_opt idl2, hidden

   if(ARG_PRESENT(visualType)) then $
     visualType = self._strVisualType

   if(arg_present(OPERATION_IDENTIFIER))then $
     OPERATION_IDENTIFIER = self._idOperation

   if (arg_present(PARAMETER_IDENTIFIER))then $
     PARAMETER_IDENTIFIER = self._idParameter

   if(arg_present(TRANSIENT))then $
     TRANSIENT = self._Transient

   if (arg_present(TYPES)) then $
     TYPES = *self._types

   if(arg_present(DISABLE))then $
     DISABLE =  self._disable

   if(arg_present(TRANSIENT_MOTION))then $
     TRANSIENT_MOTION = self._TransMotion

    if (ARG_PRESENT(normalizedZ)) then $
        normalizedZ = self._normalizedZ

   if (Arg_Present(buttonEvents) || $
        Arg_Present(motionEvents) || $
        Arg_Present(keyEvents) || $
        Arg_Present(wheelEvents))then begin
        QUERY_EVENT_MASK, self._uiEventMask, $
            BUTTON_EVENTS=buttonEvents, $
            MOTION_EVENTS=motionEvents, $
            KEYBOARD_EVENTS=keyEvents, $
            WHEEL_EVENTS=wheelEvents
   endif

   if(arg_present(DragQual))then $
     DragQual = self._DraqQual

end


;---------------------------------------------------------------------------
; _IDLitManipualtor::SetProperty
;
; Purpose:
;    Used to set various properties on the manipulator.
;
; Keywords
;   OPERATION_IDENTIFIER     - The ID of the operation associated
;                              with this manipulator.
;
;   PARAMETER_IDENTIFER      - ID of the prarameter to set during a
;                              property based operation.
;
;    VISUAL_TYPE   -  The type of the selection visual
;                     associated with this manipulator
;
;   TRANSIENT_DEFAULT        - Determine if control should be set
;                              back to the default manipulator when
;                              this manipulator is completed. Set to
;                              1 for mouse based, 2 for keyboard
;                              based.
;
;   TRANSIENT_MOTION         - If set, the manipulator is operating in a
;                              transient motion event mode. In this mode,
;                              the manpulator will enable motion events
;                              on mouse down and disable them on mouse up.
;
;   DISABLE                  - Disable this manipulator.
;
;   BUTTON_EVENTS            - If set, will enable button events for
;                              this maniplator. If set to 0, will
;                              disable button events for this
;                              manipulator.
;
;   MOTION_EVENTS            - If set, will enable motion events for
;                              this maniplator. If set to 0, will
;                              disable motion events for this
;                              manipulator.
;
;   KEYBOARD_EVENTS          - If set, will enable keyboard events for
;                              this maniplator. If set to 0, will
;                              disable keyboard events for this
;                              manipulator.
;
pro _IDLitManipulator::SetProperty, $
    NORMALIZED_Z=normalizedZ, $
    VISUAL_TYPE=visualType, $
    OPERATION_IDENTIFIER=OPERATION_IDENTIFIER, $
    PARAMETER_IDENTIFIER=PARAMETER_IDENTIFIER, $
    TRANSIENT_DEFAULT=transientDefault, $
    TRANSIENT_MOTION=TRANSIENT_MOTION, $
    DISABLE=DISABLE, $
    DEFAULT_CURSOR=DEFAULT_CURSOR, $
    BUTTON_EVENTS=buttonEvents, $
    MOTION_EVENTS=motionEvents, $
    KEYBOARD_EVENTS=keyEvents, $
    WHEEL_EVENTS=wheelEvents, $
    DRAG_QUALITY=DragQual, $
    _HITVIS=oHitVis, $         ; Private
    _HITSUBLIST=oSubHitList, $     ; Private
    _HITVIEWGROUP=oHitViewGroup    ; Private


   compile_opt idl2, hidden

   if (n_elements(OPERATION_IDENTIFIER))then $
       self._idOperation = OPERATION_IDENTIFIER

   if (n_elements(PARAMETER_IDENTIFIER))then $
       self._idParameter = PARAMETER_IDENTIFIER

   if(n_elements(transientDefault))then begin
       if(transientDefault gt -1 and transientDefault lt 4)then $
         self._transient =  transientDefault
   endif

   if(n_elements(visualType))then $
     self._strVisualType = visualType

    if (N_ELEMENTS(disable) && self._disable ne disable) then begin
        self._disable = KEYWORD_SET(disable)
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            oTool->DoOnNotify, self->GetFullIdentifier(), $
                'SENSITIVE', ~self._disable
        endif
    endif

   if(n_elements(DEFAULT_CURSOR))then $
     self._defaultCursor = DEFAULT_CURSOR

    if (N_ELEMENTS(normalizedZ)) then $
        self._normalizedZ = normalizedZ[0]

    if (N_Elements(buttonEvents)) then begin
        mask = Make_Event_Mask(/BUTTON_EVENTS)
        self._uiEventMask = (Keyword_Set(buttonEvents)) ? $
            (self._uiEventMask or mask) : (self._uiEventMask and not mask)
    endif

    if (N_Elements(motionEvents)) then begin
        mask = Make_Event_Mask(/MOTION_EVENTS)
        self._uiEventMask = (Keyword_Set(motionEvents)) ? $
            (self._uiEventMask or mask) : (self._uiEventMask and not mask)
    endif

    if (N_Elements(keyEvents)) then begin
        mask = Make_Event_Mask(/KEYBOARD_EVENTS)
        self._uiEventMask = (Keyword_Set(keyEvents)) ? $
            (self._uiEventMask or mask) : (self._uiEventMask and not mask)
    endif

    if (N_Elements(wheelEvents)) then begin
        mask = Make_Event_Mask(/WHEEL_EVENTS)
        self._uiEventMask = (Keyword_Set(wheelEvents)) ? $
            (self._uiEventMask or mask) : (self._uiEventMask and not mask)
    endif

   ;; Needed for BC
   IF (n_elements(DragQual)) THEN $
     self._DraqQual = ((DragQual GE 0) && (DragQual LT 3) ? DragQual : 2)

   ; Transient motion
   if(n_elements(TRANSIENT_MOTION))then $
     self._TransMotion = KEYWORD_SET(TRANSIENT_MOTION)

    ; Cache temporary copies so we don't need to call DoHitTest
    ; again in our _IDLitManipulator::_Select method.
    ; This should only be called by IDLitManipulatorContainer::OnMouseDown.
    if (N_ELEMENTS(oHitVis)) then $
        self._oHitVis = oHitVis
    if (N_ELEMENTS(oSubHitList) gt 0) then $
        *self._pSubHitList = oSubHitList
    if (N_ELEMENTS(oHitViewGroup)) then $
        self._oHitViewGroup = oHitViewGroup

end


;---------------------------------------------------------------------------
; _IDLitManipulator::RecordUndoValues
;
; Purpose
;    The user calls this method to record the initial values
;    of an undo operation. This call is normally made in a
;    mouse down operation.
;
function _IDLitManipulator::RecordUndoValues

    compile_opt idl2, hidden

    if(self._idOperation eq '')then $
      return, 0

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    if (N_ELEMENTS(*self.pSelectionList) eq 0) then $
        return, 0

    ; Get my own name (presumably set by my subclass to the operation name)
    ; and set it on the command object.
    self->IDLitComponent::GetProperty, NAME=myname
    ; Verify a command set is not pending

    oOperation = oTool->GetService(self._idOperation) ;

    if(obj_valid(self._oCmdSet))then obj_destroy, self._oCmdSet
    self._oCmdSet = obj_new("IDLitCommandSet", NAME=myname, $
                            OPERATION_IDENTIFIER= $
                            oOperation->getFullIdentifier())

    if(not obj_valid(oOperation))then begin
        obj_destroy, self._oCmdSet
        self._oCmdSet = obj_new() ;
        return, 0
    endif

    iStatus = oOperation->RecordInitialValues( self._oCmdSet, $
                                               *self.pSelectionList, $
                                           self._idParameter)
    if(iStatus eq 0)then begin
        obj_destroy, self._oCmdSet
        self._oCmdSet = obj_new() ; null it out
        return, 0
    endif

    return,1
end


;---------------------------------------------------------------------------
; _IDLitManipulator::CommitUndoValues
;
; Purpose
;    The user calls this method to record the final values
;    of the transaction and commit the to the undo-redo buffer.
;
function _IDLitManipulator::CommitUndoValues, UNCOMMIT=uncommit

    compile_opt idl2, hidden

    if(self._idOperation eq '')then $
      return, 0

    if (KEYWORD_SET(uncommit)) then begin
        OBJ_DESTROY, self._oCmdSet
        self._oCmdSet = OBJ_NEW()
        return, 0
    endif
    if (~OBJ_VALID(self._oCmdSet)) then $
        return, 0

    oTool = self->getTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    if (N_ELEMENTS(*self.pSelectionList) eq 0) then $
        return, 0

    oOperation = oTool->GetService(self._idOperation)

    if(not obj_valid(oOperation))then begin
        obj_destroy, self._oCmdSet
        self._oCmdSet = obj_new() ;
        return, 0
    endif

    ; use information from routine_info to determine if the RecordFinalValues
    ; routine accepts keywords.  Some objects may need to receive the
    ; skip_macrohistory keyword, but RecordFinalValues was documented for
    ; IDL 6.0 as not accepting keywords.  Using this info prevents users
    ; from having to add _extra to their implementations.  Pass the
    ; value through _extra since a routine can accept keywords but
    ; might not the accept the SKIP_MACROHISTORY keyword.
    paramStruct = routine_info(obj_class(oOperation)+"::RecordFinalValues", $
        /function,/param)
    if paramStruct.num_kw_args gt 0 then begin
        iStatus = oOperation->RecordFinalValues( self._oCmdSet, $
                                 *self.pSelectionList, $
                                 self._idParameter, $
                                 _EXTRA={SKIP_MACROHISTORY:self._skipMacroHistory})
    endif else begin
        iStatus = oOperation->RecordFinalValues( self._oCmdSet, $
                                 *self.pSelectionList, $
                                 self._idParameter)
    endelse

    if(iStatus eq 0)then begin
        obj_destroy, self._oCmdSet
        iStatus = 0
    endif else begin
        ; Add to the command queue
        oTool->_TransactCommand, self._oCmdSet
        iStatus = 1

    endelse
    self._oCmdSet = obj_new() ; null it out

    return, iStatus
end


;---------------------------------------------------------------------------
; _IDLitManipulator::BuildDefaultVisual
;
; Purpose:
;   Instantiates and returns the default selection visual for this
;   manipulator. This is basically a factory method used to construct
;   and return the selection visual object to the caller.
;
;   Note: Always returns a vis that is hidden.
;
function _IDLitManipulator::BuildDefaultVisual
    compile_opt idl2, hidden

    ; If we have a classname, use it, otherwise try to construct a
    ; default name from the VISUAL_TYPE.
    className = (self._strVisualType ne '') ? $
        'IDLitManipVis' + self._strVisualType : ''

    return, className ? OBJ_NEW(className, /HIDE) : OBJ_NEW()

end


;---------------------------------------------------------------------------
; _IDLitManipulator::RegisterCursor
;
; Purpose:
;   Method that will register a cursor with the system. This
;   input values are expected to be formatted the same as
;   expected by the CREATE_CURSOR IDL function.
;
; Parameters:
;    arrCursor -  A string array that is in a format acceptable
;                 to CREATE_CURSOR.
;
;    strName   -  The name to map this cursor to.
;
; Keywords:
;   DEFAULT    -  If set, this cursor is also set at the default for
;                 this manipulator
;
pro _IDLitManipulator::RegisterCursor, arrCursor, strName, $
                     DEFAULT=DEFAULT
    compile_opt hidden, idl2

    image = Create_Cursor(arrCursor, hotspot=hotspot, mask=mask)
    Register_Cursor, strName, image, hotspot=hotspot, mask=mask

    if(keyword_set(DEFAULT))then $
       self._defaultCursor = strName
end


;--------------------------------------------------------------------------
; _IDLitManipulator::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
;   The intent is for user-manipulators to override for specific
;   visual class cursors. If not overridden, the default cursor type
;   is returned.
;
; Parameters
;  type: Optional string representing the current type.
;
;  KeyMods - Passed in to help determine what should be returned
;
function _IDLitManipulator::GetCursorType, typeIn, KeyMods

    compile_opt idl2, hidden

    ; If a particular (selection visual) type is passed in, then it is
    ; probably associated with a manipulator other than this one.
    ; In this case, return an empty string to indicate no match.
    ; Otherwise, just use the default cursor.
    return, (STRLEN(typeIn) eq 0) ? self._defaultCursor : ''
end

;--------------------------------------------------------------------------
; _IDLitManipulator::GetStatusMessage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given type.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   typeIn - String representing the current type.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
; Keywords:
;   FOR_SELECTION: Set this keyword to a non-zero value to indicate
;     that the mouse is currently over an already selected item
;     whose manipulator target can be manipulated by this manipulator.
;
function _IDLitManipulator::GetStatusMessage, typeIn, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    ; If a type is provided, use it, but replace any '/' with spaces
    ; for readability.
    ; Otherwise, simply return this manipulator's description.
    if (STRLEN(typeIn) ne 0) then $
        statusMsg = STRJOIN(STRSPLIT(typeIn, '/', /EXTRACT), ' ') $
    else $
        self->IDLitComponent::GetProperty, DESCRIPTION=statusMsg

    return, statusMsg
end


;---------------------------------------------------------------------------
; IDLitManipulator::SetCurrentManipulator
;
; Purpose:
;   Default method. If called, will set itself as current.
;
pro _IDLitManipulator::SetCurrentManipulator, Item, _EXTRA=_extra

   compile_opt idl2, hidden

   self._subtype = (N_ELEMENTS(Item) gt 0) ? Item : ''

   ; Grab our parent, which should be a IDLitManipulatorContainer,
   ; and call the SetCurrentByObject  method.

   self->GetProperty, _PARENT=oParent
   if (~obj_valid(oParent)) then begin
       Message, IDLitLangCatQuery('Message:Framework:NoManipParent'), /continue
       return
   endif

   oParent->NotifyManipulatorChange, self

end


;---------------------------------------------------------------------------
; _IDLitManipulator::OnLoseCurrentManipulator
;
; Purpose:
;  Called when the manpulator is losing "current".
;
;  Note: actions that occur within this method typically also occur
;   within the ::OnMouseUp method.
;
pro _IDLitManipulator::OnLoseCurrentManipulator
   compile_opt idl2, hidden

   oTool = self->GetTool()
   if(obj_valid(oTool))then begin
       oWin = oTool->GetCurrentWindow()
       if (OBJ_VALID(oWin)) then begin
         oWin->SetCurrentCursor, 'ARROW'

         ; Restore settings modified by transient motion.
         if (self.nSelectionList && self._TransMotion) then begin
             ; If motion events were not previously enabled,
             ; remove motion event sending.
             if (~(self._InTransMotion and 1b)) then begin
                 eventMask = oWin->GetEventMask()
                 oWin->SetEventMask, eventMask, MOTION_EVENTS=0
             endif

             ; Were motion events enabled for this manipulator
             if(~(self._InTransMotion and 2b))then $
                 self->SetProperty, motion_events=0

             ; Clear out temp flags
             self._InTransMotion = 0b
         endif
       endif
   endif

   ; Button is no longer pressed.
   self.ButtonPress = 0

   ; Clear out the current selection list reference.
   self.nSelectionList = 0
   if(n_elements(*self.pSelectionList) gt 0)then begin
      ; Notify targets that they are about to be manipulated.
      self->_NotifyTargets, *self.pSelectionList, /COMPLETE

      void = temporary(*self.pSelectionList) ; clear out list
   endif

   ; Reset drag quality if necessary.
   IF ~obj_isa(self,'IDLitManipAnnotation') THEN BEGIN
     if(self._oldQuality ne -1)then $
       oWin->SetProperty, quality=self._oldQuality
   ENDIF

    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow

end


;---------------------------------------------------------------------------
; _IDLitManipulator::DoAction
;
; Purpose:
;   Interface call for the tool system.
;
;   For a manipulator, the action is to set itself as current in the
;   manipualtor tree.
;
; Parameter
;   iTool   - The tool object.
;
function _IDLitManipulator::DoAction, oTool

   compile_opt idl2, hidden

   ; Basically, when called to do an action, just set
   ; ourself as current. This will also update visuals.
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
   self->SetCurrentManipulator
    if (~wasDisabled) then $
        oTool->EnableUpdates
;   oTool->RefreshCurrentWindow ; update the drawing area
   return, obj_new()
end


;-------------------------------------------------------------------------
; _IDLitManipulator::QueryAvailability
;
; Purpose:
;   This function method determines whether this manipulator is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if this manipulator is applicable for the
;   selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function _IDLitManipulator::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; check for multiple dataspaces
    oSel = oTool->GetSelectedItems(COUNT=ct)
    for i=0,ct-1 do begin
      oManip = oSel[i]->GetManipulatorTarget()
      ;; Save normalizer dataspaces
      if (OBJ_ISA(oManip, 'IDLitVisNormalizer')) then $
        oDS = (N_ELEMENTS(oDS) eq 0) ? [oManip] : [oDS, oManip] 
    endfor
    ; Filter out reduntant dataspaces
    nDS = N_ELEMENTS(UNIQ(oDS, SORT(oDS)))
    case self._numberDS of
      '0+' :
      '1' : if (nDS ne 1) then return, 0
      '1+' : if (nDS eq 0) then return, 0
      '2+' : if (nDS lt 2) then return, 0
      else :
    endcase

    ; If I have no types, or none were passed in.
    nSelected = N_ELEMENTS(selTypes)
    if (~N_ELEMENTS(*self._types) || ~nSelected) then $
        return, 1

    ; Search for a match between the selected item types and the
    ; described object's types.
    for i=0, nSelected-1 do begin
        hasMatch = MAX(selTypes[i] eq *self._types)
        ; Match found. We're done.
        if (hasMatch) then $
            break
    endfor

    return, (hasMatch gt 0)

end


;---------------------------------------------------------------------------
; _IDLitManipulator::Define
;
; Purpose:
;   Define the base object for the manipulator
;
pro _IDLitManipulator__Define

   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {_IDLitManipulator, $
           inherits IDLitIMessaging,      $ ; Messaging interface.
        ; Public Instance Data
           pSelectionList   : ptr_new(),  $ ; Selection caching
           nSelectionList   : 0,          $ ; Count of items in sel list
           ButtonPress      : 0b,         $ ; flag: 1,2,4 = button is down
        ; Private
           _oCmdSet         : obj_new(),  $ ; command set storage
           _types           : ptr_new(),  $ ; store types
           _oHitVis         : OBJ_NEW(),  $ ; temporary objref from DoHitTest
           _oHitViewGroup   : OBJ_NEW(),  $ ; temporary objref from DoHitTest
           _pSubHitList     : PTR_NEW(),  $ ; temporary subhits from DoHitTest
           _strVisualType   : '',         $ ; Selection visual type.
           _idOperation     : '',         $ ; ID of associated operation
           _idParameter     : '',         $ ; id of associated op parameter.
           _defaultCursor   : '',         $ ; default cursor for the manip
           _subtype         : '',         $ ; Current manipulator subtype
           _strTmpMsg       : '',         $ ; Previous status message
           _skipMacroHistory: 0b,         $ ; skip macro/history
           _TransMotion     : 0b,         $ ; Motion events only when mouse down
           _InTransMotion   : 0b,         $ ; Temporary flags for motion events
           _Transient       : 0b,         $ ; A Transient manipulator
           _KeyTransient    : 0b,         $ ; A Transient manipulator
           _disable         : 0b,         $ ; used to disable a manip
           _viewMode        : 0b,         $ ; Only work with views
           _uiEventMask     : 0u,         $ ; Event Mask for manipulator
           _oldQuality      : 0,          $ ; the original drag quality
           _DraqQual        : 0,          $ ; unused drag quality
           _numberDS        : '', $ ; number of data spaces that can be manip'ed
           _normalizedZ     : 0d       $ ; Z value at which annotation is
                                       $ ; to be initially placed.  This value
                                       $ ; is in [-1,1] view volume range,
                                       $ ; where:  -1 = near,  +1 = far
      }

end
