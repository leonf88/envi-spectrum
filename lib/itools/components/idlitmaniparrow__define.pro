; $Id:
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   The select manipulator.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;  The constructor of the manipulator object.
;
; Arguments:
;
; Keywords:
;
function IDLitManipArrow::Init, TOOL=TOOL, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitManipulatorContainer::Init( $
                           VISUAL_TYPE = 'Select', $
                          _EXTRA=_extra, /AUTO_SWITCH, TOOL=TOOL)
    if (not success) then $
        return, 0


    ; First manipulator added to the container is the default.
    oTrans = OBJ_NEW('IDLitManipTranslate', TOOL=tool, /PRIVATE)
    self->Add, oTrans

    ; Controls the scaling handles.
    self->Add, OBJ_NEW('IDLitManipScale', TOOL=tool, /PRIVATE)

    ; Needed for the line annotation. So you can move the vertices.
    self->Add, OBJ_NEW('IDLitManipLine', TOOL=tool, /PRIVATE)

    ; Needed for repositioning/translation/scaling of views.
    self->Add, OBJ_NEW('IDLitManipView', TOOL=tool, /PRIVATE)

    ; Needed for the volume tool image plane.
    self->Add, OBJ_NEW('IDLitManipImagePlane', TOOL=tool, /PRIVATE)

    ; Needed for drawing a selection box around multiple items.
    ; We cache this objref so we can manually switch to it if nothing was hit.
    self.oManipSelectBox = OBJ_NEW('IDLitManipSelectBox', $
        TOOL=tool, /PRIVATE)
    self->Add, self.oManipSelectBox

    ; Set current manipulator.
    self->SetCurrent, oTrans

    return, 1
end


;--------------------------------------------------------------------------
; IDLitManipArrow::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipArrow::Cleanup
;
;   compile_opt idl2, hidden
;
;   self->IDLitManipulatorContainer::Cleanup
;
;end


;---------------------------------------------------------------------------
; IDLitManipArrow::OnMouseDown
;
; Purpose:
;
pro IDLitManipArrow::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    if (self.nSelectionList eq 0) then $
        self->SetCurrentManipulator, self.oManipSelectBox

    ; Call our superclass.
    self->IDLitManipulatorContainer::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

end


;;--------------------------------------------------------------------------
;; IDLitManipArrow::OnKeyBoard
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

pro IDLitManipArrow::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ;; pragmas
   compile_opt idl2, hidden
   ;; Abstract method.

    if (IsASCII) then begin
        switch Character of
          127:   ; delete key fall thru
            8: begin   ; backspace
                if (Release) then begin
                    otool = self->GetTool()
                    result = oTool->DoAction('OPERATIONS/EDIT/DELETE')
                endif
                break
                end
            else:
        endswitch
    endif else begin
    endelse

    ; Call our superclass.
    self->IDLitManipulatorContainer::OnKeyBoard, oWin, $
        IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods

end


;--------------------------------------------------------------------------
; IDLitManipArrow::GetStatusMessage
;
; Purpose:
;   This function method returns the status message that is to be
;   associated with this manipulator for the given manipulator
;   identifier.
;
;   Note: this method overrides the implementation provided by
;   the IDLitManipulatorContainer superclass.
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
function IDLitManipArrow::GetStatusMessage, ident, KeyMods, $
    FOR_SELECTION=forSelection

    compile_opt idl2, hidden

    if (~self.m_bAutoSwitch) then $
        return, ''

    if (~KEYWORD_SET(ident)) then begin
        oManipOver = self->IDLitContainer::Get()  ;; first manip
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
            return, oManipOver->GetStatusMessage(type, KeyMods, $
                FOR_SELECTION=forSelection)
        endif else $
            return, ''
    endif else begin
        self->SignalError, IDLitLangCatQuery('Error:Framework:InvalidManipId') + ident + '"'
        return, ''
    endelse
end

;---------------------------------------------------------------------------
; IDLitManipArrow__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitManipArrow__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitManipArrow, $
        inherits IDLitManipulatorContainer, $
        oManipSelectBox : OBJ_NEW() $
        }

end
