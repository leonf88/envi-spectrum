; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitannotatetext__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitAnnotateText
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
;   IDLitManipulator
;
; SUBCLASSES:
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateText::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateText::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status =self->IDLitManipAnnotation::Init( TRANSIENT_DEFAULT=2,$
                                              NAME='Text Annotation', $
                                              DEFAULT_CURSOR='IBEAM', $
                                              _EXTRA=_extra)
    if(status eq 0)then return,0

    self._dragStart = -1

    return,1
end


;--------------------------------------------------------------------------
;; IDLitAnnotateText::Cleanup
;;
;; Purpose:
;;   Cleanup method for this object.
;;
;pro IDLitAnnotateText::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitManipAnnotation::Cleanup
;end


;;---------------------------------------------------------------------------
;; IDLitAnnotateText::FinishAnnotate
;;
;; Purpose:
;;   When called, any pending annotation is completed.
;;
pro IDLitAnnotateText::FinishAnnotate
    compile_opt idl2, hidden

    if (~self.inAnnotate) then $
        return

    self.inAnnotate = 0b
    oTool = self->GetTool()
    oWin = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWin)) then begin
        ; Turn keyboard accelerators back on.
        self->DoOnNotify, oWin->GetFullIdentifier(), $
            'IGNOREACCELERATORS', 0
    endif

    if (~obj_valid(self._oText)) then $
        return

    self._oText->GetProperty, STRINGS=text

    if (text ne '') then begin
        self._oText->EndEditing
        self->CommitAnnotation, self._oText
    endif else begin  ; No text, delete
        self._oText->getProperty, _PARENT=oParent
        oParent->remove, self._oText
        obj_destroy, self._oText
        self->CancelAnnotation
    endelse

    self._oText = obj_new()

end


;;---------------------------------------------------------------------------
;; IDLitAnnotateText::OnLoseCurrentManipulator
;;
;; Purpose:
;;   This routine is called by the manipualtor system when this
;;   manipulator is made "not current". If called, this routine will
;;   make sure any pending annotations are completed
;;
pro IDLitAnnotateText::OnLoseCurrentManipulator
    compile_opt  idl2, hidden

    self->FinishAnnotate

    ; Call our superclass.
    self->_IDLitManipulator::OnLoseCurrentManipulator
end


;--------------------------------------------------------------------------
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotateText::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitAnnotateText::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    ; If we previously had a valid annotation object, with a valid
    ; cursor line, then we should remove it. This can occur if the user
    ; doesn't hit Return or ESC but just clicks somewhere else.
    ; Note: We return here. If you don't, the text annotation manipulator
    ;       becomes very confused. Related to how annotation is committed.
    if(self.inAnnotate)then begin
        self->FinishAnnotate
        if (~wasDisabled) then $
            oTool->EnableUpdates
        return
    endif

    oItems = oWin->GetSelectedItems()
    dex = where(obj_isa(oItems, "IDLitVisText"), nText)

    if(nText gt 0)then begin

        self._oText = oItems[dex[0]]
        self._oText->Select,0
        self._oText->BeginEditing,oWin ;start edit mode
        strIndex = self._oText->WindowPositionToOffset(oWin, x, y)
        self._oText->SetSelection, strIndex
        self._dragStart = strIndex  ; Dragging from here
        self._dragOffset = 0

        ; If we are editing a current text item, then we want
        ; to use SetProperty for our Undo/Redo operation.
        self->SetProperty, OPERATION_IDENTIFIER='SET_PROPERTY', $
            PARAMETER_IDENTIFIER='STRING'

    endif else begin

        ;; Create our new annotation.
        oDesc = oTool->GetAnnotation('Text')
        self._oText = oDesc->GetObjectInstance()

        ;; Add a data object.
        oData = obj_new("IDLitData", type="IDLPOINT", name='Location',/private)
        void=    self._oText->SetData(oData, parameter_name= 'LOCATION',/by_value)

        self._oText->SetProperty, HIDE=1 ;; TODO: FIX this/prevent from flashing
        ;; Add this text to the annotation layer.
        oWin->Add, self._oText, LAYER='ANNOTATION', /NO_UPDATE, /NO_NOTIFY

        ;; Set the text at the down location. This must be done after the
        ;; item is in the scene graph.
        self._oText->SetLocation, x, y, self._normalizedZ, /WINDOW
        self._oText->SetProperty, HIDE=0 ;; can show now.
        self._oText->BeginEditing,oWin ;start edit mode

        ; We are creating a new text item, so use our standard
        ; annotation operation for Undo/Redo.
        self->SetProperty, OPERATION_IDENTIFIER='ANNOTATION', $
            PARAMETER_IDENTIFIER=''

    endelse


    oTool->RefreshCurrentWindow

    ; Add a helpful message.
    self->StatusMessage, IDLitLangCatQuery('Status:AnnotateText:Text2')

    ; We need to turn off keyboard accelerators on the draw window,
    ; so that keyboard events get routed here rather than intercepted
    ; by the top-level menus.
    self->DoOnNotify, oWin->GetFullIdentifier(), 'IGNOREACCELERATORS', 1

    self.inAnnotate = 1b        ;we are annotating

    iStatus = self->RecordUndoValues()

end

;----------------------------------------------------------------------------
; IDLitAnnotateText::OnMouseUp
;
; Purpose:
;   Implements the mouse up event.
;
; Arguments:
;   oWin [in]: A reference to the window in which the event occurred.
;   x, y [in]: The device coordinate of the mouse up event.
;   buttonMask [in]: The mask indicating which button was released.
;
pro IDLitAnnotateText::OnMouseUp, oWin, x, y, buttonMask
  compile_opt idl2, hidden

  self._dragStart  = -1  ; Not dragging
  self._dragOffset = 0
end

;----------------------------------------------------------------------------
; IDLitAnnotateText::OnMouseMotion
;
; Purpose:
;   Implements the mouse motion event.
;
; Arguments:
;   oWin [in]: A reference to the window in which the event occurred.
;   x, y [in]: The device coordinate of the mouse motion event.
;   keyMods [in]: A long integer indicating which modifier keys were active.
;
pro IDLitAnnotateText::OnMouseMotion, oWin, x, y, keyMods
  compile_opt idl2, hidden

  if (self._dragStart ge 0) then begin
      offset = self._oText->WindowPositionToOffset(oWin, x, y) - self._dragStart
      if (offset eq self._dragOffset) then return
      self._dragOffset = offset

      self._oText->SetSelection, self._dragStart, offset

      oTool = self->GetTool()
      oTool->RefreshCurrentWindow
  endif
end

;;--------------------------------------------------------------------------
;; IDLitAnnotateText::OnKeyBoard
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

pro IDLitAnnotateText::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ;; pragmas
   compile_opt idl2, hidden

   if (OBJ_VALID(self._oText) eq 0) then return

   if(release)then return

   ; To avoid too many draws, disable updates until the end.
   oTool = self->GetTool()
   oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

   self._oText->GetProperty, STRING=text
   ; First check for non-Ascii text. Like Arrow keys.
   if(IsASCII eq 0)then begin
       case KeyValue of
           5: self._oText->MoveCursor, oWin, DIRECTION=0, SELECT=(KeyMods AND 1)  ; Left,  +shift selects
           6: self._oText->MoveCursor, oWin, DIRECTION=1, SELECT=(KeyMods AND 1)  ; Right, +shift selects
           7: self._oText->MoveCursor, oWin, DIRECTION=2, SELECT=(KeyMods AND 1)  ; Up,    +shift selects
           8: self._oText->MoveCursor, oWin, DIRECTION=3, SELECT=(KeyMods AND 1)  ; Down,  +shift selects
           else:                                                                  ; Do nothing
       endcase
   endif else begin
       switch KeyMods of
           0:        ; 0 = No modifiers
           1:begin   ; 1 = Shift
               case Character of
                   13:   self->FinishAnnotate                    ; <CR> Accept
                   27:   self->FinishAnnotate                    ; <ESC> Abort
                   8:    self._oText->Delete                     ; Backspace - remove from prev slot
                   127:  self._oText->Delete, /AFTER             ; Delete - remove from next slot
                   33:   self._oText->Insert, '!!'               ; Bang (!)
                   else: self._oText->Insert, STRING(Character)  ; Just good old text!
               endcase
               break
           end
           2: begin  ; 2 = Ctrl
               case Character of
                   4:  self._oText->Insert, '!D'  ; <Ctrl>D Subscript
                   10: self._oText->Insert, '!C'  ; <Ctrl> Line feed
                   13: self._oText->Insert, '!C'  ; <Ctrl> Carriage return
                   14: self._oText->Insert, '!N'  ; <Ctrl>N Normal
                   21: self._oText->Insert, '!U'  ; <Ctrl>U Superscript
                   else:                          ; Do nothing
               endcase
           end
           else:     ; Do nothing
       endswitch
   endelse

    oTool->RefreshCurrentWindow

    if (~wasDisabled) then $
        oTool->EnableUpdates

end

;--------------------------------------------------------------------------
; IDLitAnnotateText__Define::GetCursorType
;
; Purpose:
;   This function method gets the cursor type for the item that was
;   hit during a mouse motion. For this manipulator, we enable IBEAM
;   for everything.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitAnnotateText::GetCursorType, typeIn, KeyMods
    compile_opt idl2, hidden
    return, '';; always use the default
end


;---------------------------------------------------------------------------
; IDLitAnnotateText__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateText__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateText, $
            inherits IDLitManipAnnotation, $ ; super class
            inAnnotate       : 0b,         $ ; performing an annotation
            _oText           : OBJ_NEW(),  $ ; The text
            _dragStart       : 0,          $ ; Start point of drag-selecting text
            _dragOffset      : 0           $ ; Last drag offset
        }

end
