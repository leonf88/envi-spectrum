; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipulatorcontainer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipulatorContainer
;
; PURPOSE:
;   Abstract class for the manipulator system of the IDL component framework.
;   The class will not be created directly, but defines the basic
;   structure for the manipulator container.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   _IDLitManipulator
;   IDLitContainer
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitManipulatorContainer::Init
;
; METHODS:
;   Intrinsic Methods
;   This class has the following methods:
;
;   IDLitManipulatorContainer::Init
;   IDLitManipulatorContainer::Cleanup
;   IDLitManipulatorContainer::...
;
; INTERFACES:
; IIDLProperty
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;   None.
;
; Keywords:
;  AUTO_SWITCH    - If set, the current manipulator will be
;                   determined by selection and what was hit in the
;                   selection visual.
;
function IDLitManipulatorContainer::Init, AUTO_SWITCH=autoswitch, $
                                  _EXTRA=_extra

   compile_opt idl2, hidden

   if( self->IDLitContainer::Init(_EXTRA=_EXTRA) eq 0)then $
        return, 0

   if( self->_IDLitManipulator::Init(_EXTRA=_EXTRA) eq 0)then $
       return, 0

   self.m_bAutoSwitch = ( n_elements(autoswitch) gt 0 ? $
                             keyword_set(autoswitch) : 0) ; default off

   return, 1
end
;--------------------------------------------------------------------------
; IDLitManipulatorContainer::Cleanup
;
; Purpose:
;  The destructor of the component.
;
pro IDLitManipulatorContainer::Cleanup


   compile_opt idl2, hidden

   self->_IDLitManipulator::Cleanup

   self->IDLitContainer::Cleanup

end
;--------------------------------------------------------------------------
; IIDLManipulatorContainer Event Interface Section
;
; Overrides the manipulator routines and directs mouse events
; to the current manipulator (if one exits).
;--------------------------------------------------------------------------
; IDLitManipulatorContainer::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;  oWin    - The source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitManipulatorContainer::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; If we are in "auto-route" mode, see what sub-mode we should
    ; switch to.
    if (self.m_bAutoSwitch) then $
        self->_AutoSwitch, oWin, x, y

    self.ButtonPress = iButton

    ; Route the event to the current manipulator
    if (OBJ_VALID(self.m_currManip)) then begin
        ; Ensure that our current manipulator actually wants these events.
        Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
            BUTTON_EVENTS=wantEvent
        if (wantEvent) then $
            self.m_currManip->OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks
        ; Just in case the current manipulator doesn't call its ::_Select,
        ; we will also remove the cached temporary hit lists.
        ; We only need to reset _HITSUBLIST, not _HITVIS or _HITVIEWGROUP.
        self.m_currManip->SetProperty, _HITSUBLIST=-1
   endif

end


;--------------------------------------------------------------------------
; IDLitManipulatorContainer::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. Vectors event to current
;   contained manipulator
;
; Parameters
;      oWin    - The source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button released

pro IDLitManipulatorContainer::OnMouseUp, oWin, x, y, iButton

    compile_opt idl2, hidden

    ; Route the event to the current manipulator
    if( obj_valid(self.m_currManip))then begin
        ; Ensure that our current manipulator actually wants these events.
        Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
            BUTTON_EVENTS=wantEvent
        if (wantEvent) then $
            self.m_currManip->OnMouseUp, oWin, x, y, iButton
    endif
    self.ButtonPress = 0

end

;--------------------------------------------------------------------------
; IDLitManipulatorContainer::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipulatorContainer::OnMouseMotion, oWin, x, y, KeyMods

   compile_opt idl2, hidden

   ; If we are auto-switching and no mouse button is down,
   ; automatically change the cursor.
   if (self.m_bAutoSwitch && (self.ButtonPress eq 0)) then $
       self->_IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods $
   else if( obj_valid(self.m_currManip))then begin
        ; Ensure that our current manipulator actually wants these events.
        Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
            MOTION_EVENTS=wantEvent
        if (wantEvent) then $
            self.m_currManip->OnMouseMotion, oWin, x, y, KeyMods
   endif
end

;--------------------------------------------------------------------------
; IDLitManipulatorContainer::OnKeyBoard
;
; Purpose:
;   Implements the OnKeyBoard method and vectors events to
;   the current manipulator
;
; Parameters
;      oWin            - The source of the event
;  IsAlpha     - The the value a character or ASCII value?
;  Character   - The ASCII character of the key pressed.
;  KeyValue    - The value of the key pressed.
;              1 - BS, 2 - Tab, 3 - Return
;      X           - The location the keyboard entry began at (last
;                    mousedown)
;      Y           - The location the keyboard entry began at (last
;                    mousedown)
;      press       - 1 if keypress, 0 if not
;
;      release     - 1 if keypress, 0 if not
;
;      Keymods     - Set to values of any modifier keys.

pro IDLitManipulatorContainer::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

    compile_opt idl2, hidden

    ; Route the event to the current manipulator
    if( obj_valid(self.m_currManip))then begin
        ; Ensure that our current manipulator actually wants these events.
        Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
            KEYBOARD_EVENTS=wantEvent
        if (wantEvent) then begin
            self.m_currManip->OnKeyBoard, oWin, $
                IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
        endif
        ; Remove the cached temporary hit lists.
        ; We only need to reset _HITSUBLIST, not _HITVIS or _HITVIEWGROUP.
        self.m_currManip->SetProperty, _HITSUBLIST=-1
    endif
end

;--------------------------------------------------------------------------
; IDLitManipulatorContainer::OnWheel
;
; Purpose:
;   Routes OnWheel events to the current manipulator.
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
pro IDLitManipulatorContainer::OnWheel, oWin, x, y, delta, keyMods

    compile_opt idl2, hidden

    ; Route the event to the current manipulator
    if (Obj_Valid(self.m_currManip)) then begin
        ; Ensure that our current manipulator actually wants these events.
        Query_Event_Mask, self.m_currManip->GetWindowEventMask(), $
            WHEEL_EVENTS=wantEvent
        if (wantEvent) then $
            self.m_currManip->OnWheel, oWin, x, y, delta, keyMods
    endif
end

;---------------------------------------------------------------------------
; UpdateSelectionVisuals
;
; Purpose:
;   This method will set the selection visuals on the selected
;   visualizations for the given window to be appropriate for
;   this manipulator container. The window calls this method in
;   the tree when it is notified that the manipulator has changed.
;
;   This method just calls the same method on the current child.
;   If the current child is undefined, the superclass is called.
;
; Parameter
;    oWin   - The IDLitWindow that is to have the manipulator visuals
;             changed.
PRO IDLitManipulatorContainer::UpdateSelectionVisuals, oWin

   compile_opt idl2, hidden

   ; Route message
   if( obj_valid(self.m_currManip))then $
     self.m_currManip->UpdateSelectionVisuals, oWin $
   else $
     self->_IDLitManipulator::UpdateSelectionVisuals, oWin

END

;---------------------------------------------------------------------------
; ResizeSelectionVisuals
;
; Purpose:
;   This procedure method will resize the selection visuals (associated
;   with this manipulator container) on the selected visualizations for
;   the given window. This method is called whenever an operation has
;   occurred that may require a re-scaling.
;
;   This method just calls the same method on the current child.
;   If the current child is undefined, the superclass is called.
;
; Parameter
;    oWin   - The IDLitWindow that is to have the manipulator visuals
;             changed.
pro IDLitManipulatorContainer::ResizeSelectionVisuals, oWin

   compile_opt idl2, hidden

   ; Route message
   if( obj_valid(self.m_currManip))then $
     self.m_currManip->ResizeSelectionVisuals, oWin $
   else $
     self->_IDLitManipulator::ResizeSelectionVisuals, oWin
end

;---------------------------------------------------------------------------
; Container Section
;
; Override some of the container methods to validate values
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::Add
;
; Purpose:
;   Validate input to the container and add the new object if it
;   is a manipulator. Also set the new manipulator to "current".

pro IDLitManipulatorContainer::Add, oNewManip, _EXTRA=_SUPER

   compile_opt idl2, hidden

   if(Obj_Isa(oNewManip, '_IDLitManipulator') eq 0)then begin
        Message, IDLitLangCatQuery('Message:Framework:NotManipType'),/continue
        return
    endif
   self->IDLitContainer::Add, oNewManip, _EXTRA=_SUPER

   oNewManip->_SetTool, self->GetTool()
   oNewManip[0]->SetCurrentManipulator


end
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::Remove
;
; Purpose:
;   Used to remove a manipulator from this manipulator container
;

pro IDLitManipulatorContainer::Remove, oManip, _EXTRA=_SUPER

   compile_opt idl2, hidden

   self->IDLitContainer::Remove, oManip, _EXTRA=_SUPER

    ; If removed manipulator was the current, switch back to the first.
    if (oManip eq self.m_currManip) then begin
        self.m_currManip = (self->IDL_Container::Count() gt 0) ? $
            self->IDL_Container::Get() : OBJ_NEW()
    endif
end
;---------------------------------------------------------------------------
; Manipulator Hierarchy Management routines.
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::SetCurrent
;
; Purpose:
;    Used to set the current manipulator for this container.
;
; Parameter:
;   oCurrent   - The contained manipulator that is set to current.
;
; Keywords:
;
pro IDLitManipulatorContainer::SetCurrent, oCurrent


   compile_opt idl2, hidden

   ; Is this object contained?

   if(~OBJ_VALID(oCurrent) || ~self->IDL_Container::IsContained(oCurrent))then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:Framework:NotManipContainer')
       return
   endif

   self.m_currManip = oCurrent

end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::GetCurrent
;
; Purpose:
;    Used to get the current manipulator for this container.
;
; Return Value
;  The current object for this container. If there is not current
;  object null will be returned.
;
function IDLitManipulatorContainer::GetCurrent

   compile_opt idl2, hidden

   return, self.m_currManip
end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::GetCurrentManipulator
;
; Purpose:
;  Used to get the current manipulator object in the manipulator
;  tree. This method will traverse the tree until a leaf if found.
;
;  Return Value:
;    The current manipulator. If the IDENTIFIER keyword is set, the
;    IDENTIFIER of the current manipulator is returned.
;  Parameters:
;       none.
;
;  Keywords:
;    IDENTIFIER  - Will return the identifier for the current manipulator.

function IDLitManipulatorContainer::GetCurrentManipulator, $
                                  IDENTIFIER=IDENTIFIER

   compile_opt idl2, hidden

   ; Do we have any children If not, return self?

   if (~obj_valid(self.m_currManip)) then $
      oManip = self $; I'm a manipulator.
   else begin
       oManip= (obj_isa(self.m_currManip, 'IDLitManipulatorContainer') eq 1 ? $
                self.m_currManip->GetCurrentManipulator() : $
                self.m_currManip)
       ; If the child is private (which is the case for compound
       ; manipulators, just provide self.
       oManip->GetProperty,private=private
       if(private ne 0)then oManip = self ;
   endelse
   return, (keyword_set(IDENTIFIER) ? oManip->GetFullIdentifier() : oManip)
end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::SetCurrentManpulator
;
; Purpose:
;   Used to set the current manipulator in the manipulator
;   hierarchy.
;
;   A manipulator object or a relative IDENTIFER to a manipulator is
;   provided to identify the target object.
;
; Paramaters:
;    Manipulator String - Relative ID to the target manipulator
;                object - Target manpulator. Must be
;                         isa(_IDLitManipulator)
;
; Keywords:
;   None.

pro IDLitManipulatorContainer::SetCurrentManipulator, Manipulator, _EXTRA=_extra


   compile_opt idl2, hidden

    if(OBJ_VALID(Manipulator)) then begin
       ; Assume argument is a valid manipulator object.
       Manipulator->SetCurrentManipulator, _EXTRA=_extra
    endif else begin
       ; If this string is '', just get the first element and
       ; set it as current
       if(not keyword_set(Manipulator))then begin
          oManip = self->IDLitContainer::Get(count=nItems)
          if(nItems eq 0)then return ; no reason to continue
          ; Only change manipulator if necessary.
          ; Helps prevent flashing of selection visuals.
          if (oManip ne self->GetCurrentManipulator()) then $
              oManip->SetCurrentManipulator, _EXTRA=_extra
      endif else begin
          ; pop off the next string
          strItem = IDLitBasename(Manipulator, remainder=strRemain, $
                                  /reverse)
          oManip = self->IDLitContainer::GetByIdentifier(strItem)
          if(obj_valid(oManip))then $
            oManip->SetCurrentManipulator, strRemain, _EXTRA=_extra

      endelse
  endelse
end
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::_CycleCurrentType
;
; Purpose:
;   Cycles to the next manipulator, in the order that they were added
;   to the container.
;
; Return value: Success (1) or failure (0).
;
function IDLitManipulatorContainer::_CycleCurrentType, oWin

   compile_opt idl2, hidden

   count = self->IDLitManipulatorContainer::Count()
   ; If we have only one manipulator (or none) then we don't
   ; need to do any cycling.
   if (count le 1) then $
     return, 0

   ; Find position of currently active manipulator.
   ; Position will be -1 if the object is not contained (that would be bad).
   isContained = self->IDLitManipulatorContainer::IsContained( $
                                  self.m_currManip, POSITION=position)
   if(not isContained)then $
     return, 0

   ; Next manipulator on the list, or back to zero if we've reached the end.
   newPosition = (position + 1) mod count

   oNewManip = self->IDLitManipulatorContainer::Get(POSITION=newPosition)
   if (not OBJ_VALID(oNewManip)) then $
     return, 0

   ; Set the current manipulator. This will trigger the needed
   ; updates in the system
   self->NotifyManipulatorChange, oNewManip

   return, 1
end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::_AutoSwitch
;
; Purpose:
;   This internal procedure method automatically switches the current
;   manipulator according to the visual over which the mouse is located.
pro IDLitManipulatorContainer::_AutoSwitch, oWin, x, y

    compile_opt idl2, hidden

    ; Do the hit test
    oVis = (oWin->DoHitTest(x, y, DIMENSIONS=[9,9], /ORDER, $
                                  SUB_HIT=oSubHitList, $
                                  VIEWGROUP=oHitViewGroup))[0]
    void = CHECK_MATH()  ; swallow underflow errors

    ; Check for a manipulator visual among the hit lists.
    oSubHitCopy = oSubHitList
    oManipVis = OBJ_NEW()
    if (OBJ_ISA(oVis, 'IDLitManipulatorVisual')) then begin
        oManipVis = oVis
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
    ; If we hit a manipulator visual, change the current
    ; manipulator.
    if (OBJ_VALID(oManipVis)) then begin
        type = oManipVis->GetSubHitType(oSubHitList)
        ; Set the manipulator using the type.
        self->SetCurrentManipulator, type
    endif else if (OBJ_VALID(oVis)) then $
        self->SetCurrentManipulator, VISUALIZATION=oVis ; do the default

    if (OBJ_VALID(self.m_currManip)) then begin
        ; Cache temporary copies so we don't need to call DoHitTest
        ; again in our _IDLitManipulator::_Select method.
        self.m_currManip->SetProperty, $
            _HITVIS=oVis, _HITSUBLIST=oSubHitCopy, $
            _HITVIEWGROUP=oHitViewGroup
    endif
end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::NotifyManipulatorChange
;
; Purpose:
;   Callback method for children (contained items) of this container
;   to notify the container that the leaf type has changed in the
;   manipulator tree.
;
pro IDLitManipulatorContainer::NotifyManipulatorChange, oManipulator

    compile_opt idl2, hidden

   ; Set the given manipulator as the current in this container
   self->IDLitManipulatorContainer::SetCurrent, oManipulator

   ; Now pass this message up the tree. This will stop at the
   ; manipulator manager.
   self->GetProperty, _PARENT=oParent
   if(obj_valid(oParent) ne 0)then $
      oParent->NotifyManipulatorChange, self

end

;--------------------------------------------------------------------------
; IDLitManipulatorContainer::GetCursorType
;
; Purpose:
;   This function method gets the cursor type.
;
; Parameters
;  ident   - Optional string representing the current identifier.
;
function IDLitManipulatorContainer::GetCursorType, ident, KeyMods

    compile_opt idl2, hidden

    if (not self.m_bAutoSwitch) then $
        return, ''

    if(not keyword_set(ident))then begin
      oManipOver = self->IDLitContainer::Get()  ; first manip
      type =''
    endif else begin
        ; pop off the next string
        strItem = IDLitBasename(ident, remainder=type, $
                                /reverse)
        oManipOver = self->IDLitContainer::GetByIdentifier(strItem)

        ; If we failed to get the manipulator by type, try to just
        ; get the first manipulator in the container (the default).
        if (not obj_valid(oManipOver)) then $
            oManipOver = self->IDLitContainer::Get()
    endelse
    if (OBJ_VALID(oManipOver)) then begin
        ; Call the method on the appropriate manipulator.
        return, oManipOver->GetCursorType(type, KeyMods)
    endif else begin
       self->SignalError, IDLitLangCatQuery('Error:Framework:InvalidManipId') + ident + '"'
        return, ''
    endelse

end

;--------------------------------------------------------------------------
; IDLitManipulatorContainer::GetStatusMessage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given manipulator
;   identifier.
;
; Return value:
;   This function returns a string representing the status message.
;
; Parameters
;   ident   - Optional string representing the current identifier.
;
;   KeyMods - The keyboard modifiers that are active at the time
;     of this query.
;
; Keywords:
;   FOR_SELECTION: Set this keyword to a non-zero value to indicate
;     that the mouse is currently over an already selected item
;     whose manipulator target can be manipulated by this manipulator.
;
function IDLitManipulatorContainer::GetStatusMessage, ident, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    if (~self.m_bAutoSwitch) then $
        return, ''

    if (~KEYWORD_SET(ident)) then begin
        oManipOver = self->IDLitContainer::Get()  ; first manip
        type =''
    endif else begin
        ; Pop off the next string
        strItem = IDLitBasename(ident, REMAINDER=type, /REVERSE)
        oManipOver = self->IDLitContainer::GetByIdentifier(strItem)

        ; If we failed to get the manipulator by type, try to just
        ; get the first manipulator in the container (the default).
        if (~OBJ_VALID(oManipOver)) then $
            oManipOver = self->IDLitContainer::Get()
    endelse

    if (OBJ_VALID(oManipOver)) then begin
        if (KEYWORD_SET(forSelection)) then begin
            ; Call the method on the appropriate manipulator.
            return, oManipOver->GetStatusMessage(type, KeyMods, /FOR_SELECTION)
        endif else begin
            ; Simply use this container's description.
            return, self.description
        endelse
    endif else begin
        self->SignalError, IDLitLangCatQuery('Error:Framework:InvalidManipId') + ident + '"'
        return, ''
    endelse
end

;---------------------------------------------------------------------------
; IDLitManipulatorContainer::GetWindowEventMask
;
; Purpose:
;   Used to walk the manip tree to get the current
;   event mask for the system. The mask is cumulative.
;
function IDLitManipulatorContainer::GetWindowEventMask

    compile_opt idl2, hidden

    mask = self->_IDLitManipulator::GetWindowEventMask()

    if (Obj_Valid(self.m_currManip)) then begin
        mask or= self.m_currManip->GetWindowEventMask()
    endif

    return, mask
end

;---------------------------------------------------------------------------
; Properties
;---------------------------------------------------------------------------
; IDLitManipulatorContainer::GetProperty
;
; Purpose:
;    Used to get IDLitManipulatorContainer specific properties.
;
; Arguments:
;  None
;
; Keywords:
;  None.
pro IDLitManipulatorContainer::GetProperty, _REF_EXTRA=_SUPER

   compile_opt idl2, hidden

   ; If we have "extra" properties, pass them up the chain.
   if( n_elements(_SUPER) gt 0)then begin
       self->IDLitComponent::GetProperty, _EXTRA=_SUPER
       self->_IDLitManipulator::GetProperty, _EXTRA=_SUPER
   endif
end

;---------------------------------------------------------------------------
pro IDLitManipulatorContainer::SetProperty, _EXTRA=_SUPER

   compile_opt idl2, hidden

   if(n_elements(_SUPER) gt 0)then begin
       self->_IDLitManipulator::SetProperty, _EXTRA=_SUPER
       self->IDLitComponent::SetProperty, _EXTRA=_SUPER
   endif

end
;---------------------------------------------------------------------------
; IDLitManipulatorContainer__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;

pro IDLitManipulatorContainer__Define

   compile_opt idl2, hidden

   ; Just define this bad boy.
   void = {IDLitManipulatorContainer, $
             inherits _IDLitManipulator, $ ; I am a manipulator
             inherits IDLitContainer, $  ; I hold things
             m_bAutoSwitch : 0b,  $ ; Are we in a automode?
             m_currManip: obj_new()  $ ; Current Manipulator
      }

end
