; $Id: //depot/idl/releases/IDL_80/idldir/lib/idlgrtextedit__define.pro#1 $
;
; Copyright (c) 2008-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLgrTextEdit
;
; PURPOSE:
;    The IDLitVisText class is a subclass of IDLgrText that adds cursor-
;    and selection-aware text editing functionality.
;
; CATEGORY:
;    Utilities
;
; SUPERCLASSES:
;    IDLgrText
;
;-


;----------------------------------------------------------------------------
; IDLgrTextEdit::Init
;
; Purpose:
;    Initialize this component
;
; CALLING SEQUENCE:
;    Obj = OBJ_NEW('IDLgrTextEdit')
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrText
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
function IDLgrTextEdit::Init, string, _REF_EXTRA=_extra
  compile_opt idl2, hidden

  ; Initialize superclass. IDLgrText doesn't like 'string' passed undefined
  if (N_Elements(string) eq 0) then $
    result = self->IDLgrText::Init(_EXTRA=_extra) $
  else $
    result = self->IDLgrText::Init(string, _EXTRA=_extra)

  return, result
end

;----------------------------------------------------------------------------
; IDLgrTextEdit::Cleanup
;
; Purpose:
;    Cleanup method for the text object.
;
pro IDLgrTextEdit::Cleanup
  compile_opt idl2, hidden
  
  ; Cleanup superclass
  self->IDLgrText::Cleanup
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::Insert
;
; Purpose:
;   Inserts text into the string at the current cursor position.  If text
;   is selected, it overwrites the selected text and sets the selection
;   length to zero.
;
; Parameters:
;   text - text to insert
pro IDLgrTextEdit::Insert, text
  compile_opt idl2, hidden
  On_Error, 2 

  if (N_Params() lt 1) then Message, 'Incorrect number of arguments.'
  
  ; Get the latest string and cursor variables
  self->IDLgrText::GetProperty, STRINGS=string, $
    SELECTION_START=selStart, SELECTION_LENGTH=selLength
  ; If the string is empty, it comes back as -1L.
  if (Size(string, /TYPE) ne 7) then string = ''

  insMin = min([selStart, selStart + selLength])
  insMax = max([selStart, selStart + selLength])
  
  if ((text eq '!U') or (text eq '!D') or (text eq '!N')) then begin
    mode = (strlen(text) gt selStart ? $
      self->_GetCurrentHersheyMode(selStart, string) : '')
    string = strmid(string, 0, selStart) + $
      text + mode + STRMID(string, selStart)
    selStart += 2
  endif else begin
    string = strmid(string, 0, insMin) + text + strmid(string, insMax)
    selStart = insMin + strlen(text)
    selLength = 0
  endelse

  self->IDLgrText::SetProperty, STRINGS=string, $
    SELECTION_START=selStart, SELECTION_LENGTH=selLength
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::Delete
;
; Purpose:
;   Deletes text.  If text is selected, deletes the selected region and 
;   sets selection length to zero.  Otherwise, deletes a single character 
;   in the direction indicated by DELETE.
;
; Parameters:
;   AFTER  - If set, deletes the character after the cursor.  (e.g. delete key)
;            Otherwise, the character before.  (e.g. backspace key)
;   TEXT   - If present, is set to the text that was removed from the string.
pro IDLgrTextEdit::Delete, AFTER=after, TEXT=text
  compile_opt idl2, hidden
  On_Error, 2 

  ; Get the latest string and cursor variables
  self->IDLgrText::GetProperty, STRINGS=string, $
    SELECTION_START=selStart, SELECTION_LENGTH=selLength

  ; Reposition the cursor and determine the length of the deletion
  if (selLength ne 0) then begin
    ; Need fix it so the selection isn't 'backwards'
    selStart = min([selStart, selStart + selLength])
    delChar = abs(selLength)
  endif else if KEYWORD_SET(after) then begin
    ; Are we at the end of the string?
    if(selStart eq strlen(string)) then return
    ; Skip over any pure Hershey formatting codes. This is needed to preserve
    ; formatting when editing between codes.
    delChar=1
    while(self->_IsNextHershey(selStart, string, Hershey)) do begin
      if(hershey eq "!C" or hershey eq "!!")then begin
        delChar=2
        break
      endif
      selStart+=2
    endwhile
  endif else begin
    ; Are we at the begining of the string?
    if (selStart eq 0) then return
    ; Skip over any pure Hershey formatting codes. This is needed to preserve
    ; formatting when editing between codes.
    delChar=1
    while(self->_IsPreviousHershey(selStart, string, Hershey)) do begin
      if(hershey eq "!C" or hershey eq "!!")then begin
        delChar=2
        break
      endif
      selStart-=2
    endwhile
    selStart -= delChar
  endelse

  ; Return the deleted text, on request
  if arg_present(text) then $
    text = strmid(string, selStart, delChar)
  ; Update the string
  string = strmid(string, 0, selStart) + $
    strmid(string, selStart + delChar)
    
  ; Push the update to the view
  selLength = 0
  self->IDLgrText::SetProperty, STRINGS=string, $
    SELECTION_START=selStart, SELECTION_LENGTH=selLength
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::MoveCursor
;
; Purpose:
;  Moves the insertion cursor in the specified direction.
;
; Parameters:
;  direction - 0=left, 1=right, 2=up, 3=down
;  select    - If true, moves the end of the selection region in the given
;              direction. Otherwise moves the cursor and sets selection 
;              length to zero.
;  window    - Handle to the window in which the text appears.
;
pro IDLgrTextEdit::MoveCursor, window, DIRECTION=direction, SELECT=select
  compile_opt idl2, hidden
  On_Error, 2 

  if (N_Elements(direction) eq 0) then direction = 0
  if (direction ne 0 && direction ne 1 && direction ne 2 && direction ne 3) then $
    Message, 'DIRECTION must be 0 (left), 1 (right), 2 (up), or 3 (down).'
  if (N_Elements(window) eq 0) then $
    Message, 'The WINDOW parameter is required.'
  if (~Obj_Isa(window, 'IDLgrWindow')) then $
    Message, 'WINDOW must be an IDLgrWindow object'

  ; Get the latest string and cursor variables
  self->IDLgrText::GetProperty, STRINGS=string, $
    SELECTION_START=selStart, SELECTION_LENGTH=selLength

  if (~keyword_set(select) and selLength ne 0) then begin
    ; Clearing a selection.  Just move cursor to the
    ; edge of the selection in the direction pressed.
    if (direction eq 0) then $  ; Left 
      selStart = min([selStart, selStart+selLength])
    if (direction eq 1) then $  ; Right
      selStart = max([selStart, selStart+selLength])
    selLength = 0
    self->IDLgrText::SetProperty, SELECTION_START=selStart, SELECTION_LENGTH=selLength
    return
  endif
  
  ; If we're selecting, we need to move the END of the selection, not the beginning.
  if keyword_set(select) then $
    pos = selStart + selLength $
  else $
    pos = selStart

  ; Get the index of the nearest character in the specified direction
  move = self->GetIndexRelativeTo(window, pos, direction) - pos
  
  ; Pressing up anywhere on the top line should move to the beginning
  if (direction eq 2 && move eq 0) then $
    move = -pos
  
  ; Pressing down anywhere on the bottom line should move to the end
  if (direction eq 3 && move eq 0) then $
    move = StrLen(string) - pos

  ; If we're selecting, we need to move the END of the selection, not the beginning.
  if keyword_set(select) then $
    selLength += move $
  else $
    selStart += move

  self->IDLgrText::SetProperty, SELECTION_START=selStart, SELECTION_LENGTH=selLength
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::_IsPreviousHershey
;
; Purpose:
;  Used to determine if the previous charater is a hershey formatting code.
function IDLgrTextEdit::_IsPreviousHershey, iPoint, text,  Hershey
  compile_opt hidden, idl2

  ; If the insertion point is le 1, there can be no hershey chars.
  if(iPoint lt 2)then return, 0

  ; The only way to be sure is to walk from the beginning and see
  ; if we come across one in the right place.
  iChar = 0
  while (iChar le iPoint-2) do begin
    if (self->_IsNextHershey(iChar, text, Hershey)) then begin
      iChar += 2
      if (iChar eq iPoint) then return, 1
    endif else $
      iChar++
  end
  
  Hershey = ''
  return, 0
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::_IsNextHershey
;
; Purpose:
;  Used to determine if the next charater is a hershey formatting code.
function IDLgrTextEdit::_IsNextHershey, iPoint, text,  Hershey
   compile_opt idl2, hidden

   Hershey = StrUpCase(StrMid(text, iPoint, 2))
   if (Hershey eq '!A' || Hershey eq '!B' || Hershey eq '!C' || $
       Hershey eq '!D' || Hershey eq '!E' || Hershey eq '!G' || $
       Hershey eq '!I' || Hershey eq '!L' || Hershey eq '!M' || $
       Hershey eq '!N' || Hershey eq '!R' || Hershey eq '!S' || $
       Hershey eq '!U' || Hershey eq '!X' || Hershey eq '!Z' || $
       Hershey eq '!!') then $
     return, 1

   Hershey = ''
   return, 0
end

;---------------------------------------------------------------------------
; IDLgrTextEdit::_GetCurrentHersheyMode
;
; Purpose:
;  Used to determine the current hershey mode for a given point in a
;  string. This is needed when inserting a new hershey mode, to
;  preserve formatting for chars. For example the following string:
;
;    !Ncow!Upig moo!N
;
; Would be the following if a !D was put between "pig" and "moo"
;
;    !Ncow!upig!D!U moo!N
;
; Parameters:
;  iPoint - Current insertion ponit in the string
;
;  text   - The string
;
; Return Value:
;    The Hershey mode
;
function IDLgrTextEdit::_GetCurrentHersheyMode, iPoint, text

    compile_opt idl2, hidden

   ; Basically, the string must be traversed until hitting the given
   ; point. This required since hershey formatting is forward direction
   ; dependent
   iChar = strpos(text,"!")
   iHershey=-1
   while(iChar ge 0 and iChar lt  iPoint-2) do begin
       Hershey = strmid(text, iChar,2)
       if(Hershey ne "!!" and Hershey ne "!C")then $
         iHershey = iChar
       iChar = strpos(text, "!", iChar+2)
   endwhile
   if(iHershey eq -1)then $
     Hershey="!N"
   return, Hershey
end

;----------------------------------------------------------------------------
; IDLgrTextEdit__Define
;
; PURPOSE:
;    Defines the object structure for an IDLgrTextEdit object.
pro IDLgrTextEdit__Define
  compile_opt idl2, hidden
  
  struct = { IDLgrTextEdit,      $
             inherits IDLgrText  }
end