; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitprompt__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitPrompt
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
;   See IDLitPrompt::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitPrompt::Init
;   IDLitPrompt::Cleanup
;   IDLitPrompt::GetProperty
;   IDLitPrompt::SetProperty

;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitPrompt::Init
;;
;; Purpose:
;; The constructor of the IDLitPrompt object.
;;
;; Keywords
;;  Set the SetProperty Method.

;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitPrompt::Init, _EXTRA=_SUPER

    ;; Pragmas
    compile_opt idl2, hidden

    iStatus = self->IDLitMessage::Init( 2, _EXTRA=_SUPER)
    if(iStatus ne 1)then $
      return, 0

    self._defaultNo = 1b

    self._pstrPrompt = ptr_new(/allocate_heap)
    self->IDLitPrompt::SetProperty, _EXTRA=_SUPER
    return,1
end

;-------------------------------------------------------------------------
;; IDLitPrompt::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitPrompt object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitPrompt::Cleanup

    ;; Pragmas
    compile_opt idl2, hidden

    if(ptr_valid(self._pstrPrompt))then $
       ptr_free, self._pstrPrompt

    self->IDLitMessage::Cleanup
end


;-------------------------------------------------------------------------
;; IDLitPrompt::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitPrompt::GetProperty, TITLE=TITLE, PROMPT=PROMPT, ANSWER=ANSWER, $
    CANCEL=cancel, $
    DEFAULT_NO=defaultNo, $
               _REF_EXTRA=_SUPER
    ;; Pragmas
    compile_opt idl2, hidden

    if (ARG_PRESENT(cancel)) then $
        cancel = self._cancel
    if (ARG_PRESENT(defaultNo)) then $
        defaultNo = self._defaultNo
    if(arg_present(title))then title = self._strTitle
    if(arg_present(prompt))then prompt= $
         (n_elements(*self._pstrPrompt) gt 0 ? *self._pstrPrompt : '')
    if(arg_present(answer))then answer = self._iAnswer

    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::GetProperty, _EXTRA=_SUPER
end


;-------------------------------------------------------------------------
;; IDLitPrompt::SetProperty
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
pro IDLitPrompt::SetProperty, TITLE=TITLE, $
    CANCEL=cancel, $
    DEFAULT_NO=defaultNo, $
               PROMPT=PROMPT, ANSWER=ANSWER, TYPE=TYPE,$
              _EXTRA=_SUPER

   ;; Pragmas
   compile_opt idl2, hidden

   if (N_ELEMENTS(cancel) gt 0) then $
        self._cancel = KEYWORD_SET(cancel)
   if (N_ELEMENTS(defaultNo) gt 0) then $
        self._defaultNo = KEYWORD_SET(defaultNo)

   if(n_elements(title) gt 0)then self._strTitle = title
   if(n_elements(answer) gt 0)then self._iAnswer = answer

   if(n_elements(prompt) gt 0)then $
      *self._pstrprompt = prompt

    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::SetProperty, _extra=_super
end

;-------------------------------------------------------------------------
pro IDLitPrompt__define
   compile_opt idl2, hidden
    struc = {IDLitPrompt,            $
             inherits IDLitMessage,    $
             _strTitle : '', $
             _pstrPrompt : ptr_new(), $
             _iAnswer    : 0, $
             _cancel     : 0b, $
             _defaultNo  : 0b $
             }

end

