; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitprompttext__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitPromptText
;
; PURPOSE:
;    Generic user prompt object. Used to send messages to the UI
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitPromptText::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitPromptText::Init
;   IDLitPromptText::Cleanup
;   IDLitPromptText::GetProperty
;   IDLitPromptText::SetProperty

;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitPromptText::Init
;;
;; Purpose:
;; The constructor of the IDLitPromptText object.
;;
;; Keywords
;;  Set the SetProperty Method.

;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitPromptText::Init, _EXTRA=_SUPER

    ;; Pragmas
    compile_opt idl2, hidden

    iStatus = self->IDLitMessage::Init( 3, _EXTRA=_SUPER)
    if(iStatus ne 1)then $
      return, 0

    self._pstrPrompt = ptr_new(/allocate_heap)
    self->IDLitPromptText::SetProperty, _EXTRA=_SUPER
    return,1
end

;-------------------------------------------------------------------------
;; IDLitPromptText::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitPromptText object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitPromptText::Cleanup

    ;; Pragmas
    compile_opt idl2, hidden

    if(ptr_valid(self._pstrPrompt))then $
       ptr_free, self._pstrPrompt

    self->IDLitMessage::Cleanup
end


;-------------------------------------------------------------------------
;; IDLitPromptText::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitPromptText::GetProperty, TITLE=TITLE, PROMPT=PROMPT, ANSWER=ANSWER, $
               _REF_EXTRA=_SUPER
    ;; Pragmas
    compile_opt idl2, hidden

    if(arg_present(title))then title = self._strTitle
    if(arg_present(prompt))then prompt= $
         (n_elements(*self._pstrPrompt) gt 0 ? *self._pstrPrompt : '')
    if(arg_present(answer))then answer = self._strAnswer

    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::GetProperty, _EXTRA=_SUPER
end


;-------------------------------------------------------------------------
;; IDLitPromptText::SetProperty
;;
;; Purpose:
;;   Set aspects of this error condition
;;
;; Keywords
;;   TITLE   - Title for the prompt
;;
;;   PROMPT  - The prompt
;;
;;   ANSWER  - The answer recieved.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitPromptText::SetProperty, TITLE=TITLE, $
               PROMPT=PROMPT, ANSWER=ANSWER, $
              _EXTRA=_SUPER

   ;; Pragmas
   compile_opt idl2, hidden

   if(n_elements(title) gt 0)then self._strTitle = title
   if(n_elements(answer) gt 0)then self._strAnswer = answer

   if(n_elements(prompt) gt 0)then $
      *self._pstrprompt = prompt

    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::SetProperty, _extra=_super
end

;-------------------------------------------------------------------------
pro IDLitPromptText__define

    compile_opt idl2, hidden

    struc = {IDLitPromptText,            $
             inherits IDLitMessage,    $
             _strTitle : '', $
             _pstrPrompt : ptr_new(), $
             _strAnswer  : '' $
             }

end

