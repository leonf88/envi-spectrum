; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipulatormanager__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipulatorManager
;
; PURPOSE:
;   This class acts as the root of the manipulation hiearchy,
;   providing a connection between the outside "world" and the
;   manipulator system.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulatorContainer
;
; CREATION:
;   See IDLitManipulatorManager::Init
;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::Init
;;
;; Purpose:
;;  The constructor of the manipulator manager object
;;
;; Parameters:
;;     none.
;;
;; Keywords:
;;  NAME      - The name for the manager. Used by the
;;              underlying Component. Default name is Manipulators
;;
;;  IDENTIFIER - The identifier for this manipulator. If not provided
;;               the upcased version of the name is used.
;
function IDLitManipulatorManager::Init, NAME=NAME, IDENTIFIER=IDENTIFIER, $
                                TOOL=TOOL, _EXTRA=_EXTRA

   compile_opt idl2, hidden

   self._currObs = obj_new('IDLitNotifier', 'OnManipulatorChange')

   if(not keyword_set(NAME))then $
     NAME="Tool Manipulators"

   if(not keyword_set(IDENTIFIER))then $
     IDENTIFIER = strupcase(NAME)

   return, self->IDLitManipulatorContainer::Init(IDENTIFIER=IDENTIFIER, $
                                                 NAME=NAME, $
                                                 AUTO_SWITCH=0, $
                                                 TOOL=TOOL, _extra=_extra)
end


;;--------------------------------------------------------------------------
;; IDLitManipulatorManager::Cleanup
;;
;; Purpose:
;;  The destructor of the component.
;;
;
pro IDLitManipulatorManager::Cleanup

   compile_opt idl2, hidden

   ;; Take care of the current manipulator observer list.
   self._currObs->Remove, /All
   obj_destroy, self._currObs ;; Cleanup

   self->IDLitManipulatorContainer::Cleanup

end


;;---------------------------------------------------------------------------
;; Observer section
;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::AddManipulatorObserver
;;
;; Purpose:
;;   Used to register a object as having interest in notification when
;;   the current manipulator is changed. Examples of this would be
;;   a menu or toolbar.
;;
;; Paramaters:
;;   oObserver   - The ManipulatorObserver. This must implement
;;                 the "OnManipulatorChange" method.
;;
pro IDLitManipulatorManager::AddManipulatorObserver, oObserver

   compile_opt idl2, hidden

   void = where(obj_hasmethod(oObserver, 'OnManipulatorChange'), count)
   if( count ne n_elements(oObserver))then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:Framework:NoOnManipChange')
       return
   endif

   self._currObs->Add, oObserver

   nObserv = N_ELEMENTS(oObserver)
   for i=0,nObserv-1 do $
     oObserver[i]->OnManipulatorChange, self

end


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::RemoveManipulatorObserver
;;
;; Purpose:
;;   Used to remove an observer object from the list of observers
;;
;; Paramaters:
;;   oObserver   - The ManipulatorObserver.
;;
pro IDLitManipulatorManager::RemoveManipulatorObserver, oObserver

   compile_opt idl2, hidden

   ;; Just  remove the bad boy.
   self._currObs->Remove, oObserver

end


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::NotifyManipulatorChange
;;
;; Purpose:
;;   Callback method for children (contained items) of this container
;;   to notify the container that the leaf type has changed in the
;;   manipulator tree.
;;
;; Parameter:
;;  oManipulator   - The new manipulator.
;;
pro IDLitManipulatorManager::NotifyManipulatorChange, oManipulator

    compile_opt idl2, hidden

    ;; KDB NOTE: There used to be locic here that would look for the
    ;; root, main parent, of the target manipulator and if it wasn't
    ;; this manipulator manager, would make some calls. This is
    ;; very incorrect. If the manipulator is not contained in this
    ;; manager, then it is no concern of this manager. Think about
    ;; scope.
   self->IDLitManipulatorContainer::SetCurrent, oManipulator

   ;; Send the you're a loser message. Note, by the time this
   ;; notification reaches this method, the current manipulator
   ;; has changed. As such, the old current is cached and called
   ;; if it is different than the new current.
   oCurrMan = self->GetCurrentManipulator()
   if (obj_valid(oCurrMan) && obj_valid(self._oOldCurr) && $
       oCurrMan ne self._oOldCurr) then $
     self._oOldCurr->OnLoseCurrentManipulator
   self._oOldCurr = oCurrMan ;; stash our current manipulator

   ;; We are the top of the tree (if not, we have a problem). Send a
   ;; notify event to all of our observers.
   self._currObs->Notify, self, CALLBACK='OnManipulatorChange'

end


;;--------------------------------------------------------------------------
;; IDLitManipulatorManager::OnMouseDown
;;
;; Purpose:
;;   Override the OnMouseDown method so that selection can be checked.
;;
;; Parameters
;;      oWin    - The source of the event
;;  x   - X coordinate
;;  y   - Y coordinate
;;  iButton - Mask for which button pressed
;;  KeyMods - Keyboard modifiers for button
;;  nClicks - Number of clicks
;
pro IDLitManipulatorManager::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

   compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        CATCH, /CANCEL
        self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], SEVERITY=2
        ; Reenable updates if necessary.
        if (OBJ_VALID(oTool) && $
            N_ELEMENTS(wasDisabled) && ~wasDisabled) then $
            oTool->EnableUpdates
        return
    endif

    oTool = self->GetTool()

    doPropSheet = (nClicks eq 2) && ~ISA(oTool, 'GraphicsTool') && $
        (OBJ_VALID((oCur=self->GetCurrent())) && (oCur eq self._oDefault))

    if (doPropSheet) then begin

        if (~OBJ_VALID(oTool)) then $
            return
        success = oTool[0]->DoAction('OPERATIONS/EDIT/PROPERTIES')

    endif else begin

        ; To avoid too many draws, disable updates until the end.
        if (OBJ_VALID(oTool)) then $
            oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

        self.ButtonPress = iButton

        ; Route the event to the currently active manipulator.
        oCurrManip = self.m_currManip
        if (OBJ_VALID(oCurrManip)) then begin
            oCurrManip->GetProperty, BUTTON_EVENTS=evButton
            if (evButton ne 0) then $
                oCurrManip->OnMouseDown, oWin, x, y, iButton, KeyMods, $
                    nClicks

            ; Just in case the current manipulator doesn't call its ::_Select,
            ; we will also remove the cached temporary hit lists.
            ; We only need to reset _HITSUBLIST, not _HITVIS or _HITVIEWGROUP.
            oCurrManip->SetProperty, _HITSUBLIST=-1
        endif

        if (OBJ_VALID(oTool) && ~wasDisabled) then $
            oTool->EnableUpdates

    endelse
    
    if (self._proMouseButtonHandler ne '') then begin
      oSel = oTool->GetSelectedItems()
      CALL_PROCEDURE, self._proMouseButtonHandler, 'DOWN', oWin, oSel[0], $
        x, y, iButton, nClicks, KeyMods
    endif

end


;;--------------------------------------------------------------------------
;; IDLitManipulatorManager::OnMouseMotion
;;
;; Purpose:
;;   Implements the OnMouseMotion method.
;;
;; Parameters
;;  oWin    - Event Window Component
;;  x   - X coordinate
;;  y   - Y coordinate
;;  KeyMods - Keyboard modifiers for button

pro IDLitManipulatorManager::OnMouseMotion, oWin, x, y, KeyMods

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        CATCH, /CANCEL
; If an error occurs doing MouseMotion too many dialogs can appear.
; Instead just quietly return. Hope this is okay.
        self->SignalError, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), $
            !error_state.msg], SEVERITY=2
        ; Reenable updates if necessary.
        if (OBJ_VALID(oTool) && $
            N_ELEMENTS(wasDisabled) && ~wasDisabled) then $
            oTool->EnableUpdates
        return
    endif

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Route the event to the currently active manipulator.
    oCurrManip = self.m_currManip
    if (OBJ_VALID(oCurrManip)) then begin
        oCurrManip->GetProperty, MOTION_EVENTS=evMotion
        if (evMotion ne 0) then $
            oCurrManip->OnMouseMotion, oWin, x, y, KeyMods
    endif

    if (OBJ_VALID(oTool)) then begin
        if (~wasDisabled) then $
            oTool->EnableUpdates
    endif else $
        oWin->Draw

    if (self._proMouseMotionHandler ne '') then $
      CALL_PROCEDURE, self._proMouseMotionHandler, oWin, x, y, KeyMods

end


;;--------------------------------------------------------------------------
;; IDLitManipulatorManager::OnMouseUp
;;
;; Purpose:
;;   Implements the OnMouseUp method. Used to reset manipulators if needed.
;;
;; Parameters
;;  oWin    - The source of the event
;;  x       - X coordinate
;;  y       - Y coordinate
;;  iButton - Mask for which button released
;
pro IDLitManipulatorManager::OnMouseUp, oWin, x, y, iButton

   compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        CATCH, /CANCEL
        self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], SEVERITY=2
        ; Reenable updates if necessary.
        if (OBJ_VALID(oTool) && $
            N_ELEMENTS(wasDisabled) && ~wasDisabled) then $
            oTool->EnableUpdates
        return
    endif

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Route the event to the currently active manipulator.
    oCurrManip = self.m_currManip
    if (OBJ_VALID(oCurrManip)) then begin
        oCurrManip->GetProperty, BUTTON_EVENTS=evButton
        if (evButton ne 0) then $
            oCurrManip->OnMouseUp, oWin, x, y, iButton
    endif


    self.ButtonPress = 0

    ;; Do we need to reset to our default manipulator?
    oCurrent = self.m_currManip
    if (OBJ_VALID(oCurrent)) then begin
        oCurrent->GetProperty, TRANSIENT_DEFAULT=isTrans
        if (((isTrans and 1) ne 0) and obj_valid(self._oDefault)) then $
            self._oDefault->SetCurrentManipulator
    endif

    if (OBJ_VALID(oTool) && ~wasDisabled) then $
        oTool->EnableUpdates

    ; Right click, mouse up, display context menu.
    if (iButton eq 4) then begin
        self->DoOnNotify, oWin->GetFullIdentifier(), $
            'CONTEXTMENUDISPLAY', [x, y]
    endif

    if (self._proMouseButtonHandler ne '') then $
      CALL_PROCEDURE, self._proMouseButtonHandler, 'UP', oWin, !NULL, $
        x, y, iButton

end


;;--------------------------------------------------------------------------
;; IDLitManipulatorManager::OnKeyBoard
;;
;; Purpose:
;;   Implements the OnKeyBoard method.
;;
;; Parameters
;;      oWin        - Event Window Component
;;      IsAlpha     - The the value a character or ASCII value?
;;      Character   - The ASCII character of the key pressed.
;;      KeyValue    - The value of the key pressed.
;;                    1 - BS, 2 - Tab, 3 - Return
;;      X           - The location the keyboard entry began at (last
;;                    mousedown)
;;      Y           - The location the keyboard entry began at (last
;;                    mousedown)
;;      press       - 1 if keypress, 0 if not
;;
;;      release     - 1 if keypress, 0 if not
;;
;;      Keymods     - Set to values of any modifier keys.
;
pro IDLitManipulatorManager::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods


   compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        CATCH, /CANCEL
        self->ErrorMessage, TITLE=IDLitLangCatQuery('Error:InternalError:Title'), $
            [IDLitLangCatQuery('Error:Framework:UnknownSystemError'), !error_state.msg], SEVERITY=2
        return
    endif

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Route the event to the current manipulator.
    oCurrManip = self.m_currManip
    if (OBJ_VALID(oCurrManip)) then begin
        oCurrManip->GetProperty, KEYBOARD_EVENTS=evKeyboard
        if (evKeyboard ne 0) then $
            oCurrManip->OnKeyBoard, oWin, $
                IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
    endif

    if (Press) then begin

        ; <Return> is the same as <ESC>
        if (Character eq 13) then $
            Character = 27

        case Character of

            27: begin  ; Do we have a CR or ESC key
               ;; Do we need to reset to our default manipulator?
               oCurrent = self.m_currManip
               if (OBJ_VALID(oCurrent)) then begin
                   oCurrent->GetProperty, TRANSIENT_DEFAULT=isTrans
                   if (((isTrans and 2) eq 2) and $
                       obj_valid(self._oDefault)) then $
                       self._oDefault->SetCurrentManipulator
               endif
               end

            else: ; do nothing
        endcase

    endif

    if (OBJ_VALID(oTool) && ~wasDisabled) then $
        oTool->EnableUpdates

end


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::UpdateSelectionVisuals
;;
;; Purpose:
;;   This method will set the selection visuals on the selected
;;   visualizations for the given window to be appropriate for
;;   this manipulator container. The window calls this method in
;;   the tree when it is notified that the manipulator has changed.
;;
;;   This method just calls the same method on the current child.
;;   If the current child is undefined, the superclass is called.
;;
;; Parameter
;;    oWin   - The IDLitWindow that is to have the manipulator visuals
;;             changed.
PRO IDLitManipulatorManager::UpdateSelectionVisuals, oWin

    compile_opt idl2, hidden

    ; Route message
    oCurrManip = self.m_currManip
    if (OBJ_VALID(oCurrManip)) then $
        oCurrManip->UpdateSelectionVisuals, oWin
END


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::ResizeSelectionVisuals
;;
;; Purpose:
;;   This procedure method will resize the selection visuals (associated
;;   with this manipulator container) on the selected visualizations for
;;   the given window. This method is called whenever an operation has
;;   occurred that may require a re-scaling.
;;
;;   This method just calls the same method on the current child.
;;   If the current child is undefined, the superclass is called.
;;
;; Parameter
;;    oWin   - The IDLitWindow that is to have the manipulator visuals
;;             changed.
;
pro IDLitManipulatorManager::ResizeSelectionVisuals, oWin

   compile_opt idl2, hidden

    ; Route message
    oCurrManip = self.m_currManip
    if (OBJ_VALID(oCurrManip)) then $
        oCurrManip->ResizeSelectionVisuals, oWin
end


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::Add
;;
;; Purpose:
;;  Used to trap the default flag. Everything else goes to the super
;;
;; Parameters:
;;  oNewManip   - The item being added
;;
;; Keywords:
;;    DEFAULT   - Used to set this manipulator as the default.
;;
pro IDLitManipulatorManager::Add, oNewManip, $
    DEFAULT=DEFAULT, $
    _EXTRA=_SUPER

   compile_opt idl2, hidden

   self->IDLitManipulatorContainer::Add, oNewManip, _EXTRA=_SUPER

   if(keyword_set(default))then $
     self._oDefault = oNewManip

end


;;---------------------------------------------------------------------------
;; IDLitManipulatorManager::GetDefaultManipulator
;;
;; Purpose:
;;  This function method returns a reference to the manipulator that
;;  was most recently added as the default manipulator.
;;
function IDLitManipulatorManager::GetDefaultManipulator

    compile_opt idl2, hidden

    return, self._oDefault
end


;---------------------------------------------------------------------------
; Properties
;---------------------------------------------------------------------------
pro IDLitManipulatorManager::GetProperty, MOUSE_MOTION_HANDLER=mMotion, $
                                          MOUSE_BUTTON_HANDLER=mButton, $
                                          _REF_EXTRA=_SUPER
  compile_opt idl2, hidden

  if (ARG_PRESENT(mMotion)) then $
    mMotion = self._proMouseMotionHandler
    
  if (ARG_PRESENT(mButton)) then $
    mButton = self._proMouseButtonHandler
    
  ; If we have "extra" properties, pass them up the chain.
  if( n_elements(_SUPER) gt 0)then begin
    self->IDLitManipulatorContainer::GetProperty, _EXTRA=_SUPER
  endif
  
end

;---------------------------------------------------------------------------
pro IDLitManipulatorManager::SetProperty, MOUSE_MOTION_HANDLER=mMotion, $
                                          MOUSE_BUTTON_HANDLER=mButton, $
                                          _EXTRA=_SUPER
  compile_opt idl2, hidden

  if (N_ELEMENTS(mMotion) eq 1) then begin
    catch, err
    if (err ne 0) then begin
on_error, 1    
      catch, /cancel
      message, 'Incorrect specifications for mouse handler routine.'
      self._proMouseMotionHandler = ''
    endif else begin
      name = STRING(mMotion[0])
      RESOLVE_ROUTINE, name, /NO_RECOMPILE
      info = ROUTINE_INFO(name, /PARAMETERS)
      if (info.num_args ge 4) then $
        self._proMouseMotionHandler = name
    endelse
  endif
    
  if (N_ELEMENTS(mButton) eq 1) then begin
    catch, err
    if (err ne 0) then begin
on_error, 1    
      catch, /cancel
      message, 'Incorrect specifications for mouse handler routine.'
      self._proMouseButtonHandler = ''
    endif else begin
      name = STRING(mButton[0])
      RESOLVE_ROUTINE, name, /NO_RECOMPILE
      info = ROUTINE_INFO(name, /PARAMETERS)
      if (info.num_args ge 8) then $
        self._proMouseButtonHandler = name
    endelse
  endif
    
  if(n_elements(_SUPER) gt 0)then begin
    self->IDLitManipulatorContainer::SetProperty, _EXTRA=_SUPER
  endif

end

;;---------------------------------------------------------------------------
;; Class Definition
;;---------------------------------------------------------------------------
;; IDLitManipulatorManager__Define
;;
;; Purpose:
;;   Define the base object for the manipulator Manager.
;;

pro IDLitManipulatorManager__Define

   compile_opt idl2, hidden

   void = {IDLitManipulatorManager, $
             inherits IDLitManipulatorContainer, $ ;; I am a manipulator
             _oOldCurr : obj_new(), $ ;;
             _oDefault : obj_new(), $ ;;
             _currObs : obj_new(),   $ ;; Current manipulator observers
             _proMouseMotionHandler : '', $
             _proMouseButtonHandler : '' $
          }

end
