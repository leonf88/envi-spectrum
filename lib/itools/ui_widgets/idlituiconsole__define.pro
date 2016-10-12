; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiconsole__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitUIConsole
;
; PURPOSE:
;   This file implements a simple command line messaging interface
;   that can be called with standard message objects and will print
;   output to the command log.
;
;   This is mostly used with the system object, allowing messaging
;   interaction with the IDL command line and not relying on widgets.
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitUIConsole::Init
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitUIConsole::Init
;;
;; Purpose:
;; The constructor of the IDLitUIConsole object.
;;
;; Parameters:
;;   None.
;;
;  Keywords:
;;   All are passed to superclass
;;
function IDLitUIConsole::Init, _extra=_extra
   ;; Pragmas
   compile_opt idl2, hidden

   return, self->IDLitComponent::Init(_extra=_extra)

end
;;---------------------------------------------------------------------------
;; Messaging section
;;---------------------------------------------------------------------------
;; IDLitUIConsole::_ErrorMessage
;;
;; Purpose:
;;   Method used to display an error message to the user. For this
;;   command line UI, this is the output of text.
;;
;; Parameter:
;;  oError  - The message object for the error
;;
function IDLitUIConsole::_ErrorMessage, oError
   compile_opt hidden, idl2

   if(obj_valid(oError) eq 0)then $
     return,0

   oError->GetProperty, message=message, description=description, $
     severity=severity

   case severity of
       0:  msg = ""
       2:  msg = "ERROR"
       else: msg = "WARNING"
   endcase
   ;; outpout to IDL
   print,msg, message, description, format='(%"%%%s [%s]\t%s")'

   return,1
end
;;---------------------------------------------------------------------------
;; IDLitUIConsole::_PromptText
;;
;; Purpose:
;;   Displays a question the user.
;;
;; Parameter:
;;  oPrompt  - The prompt information
;;
function IDLitUIConsole::_PromptText, oPrompt
   compile_opt hidden, idl2

   if(obj_valid(oPrompt) eq 0)then $
     return,0

   oPrompt->GetProperty, prompt=prompt

   ;; Dump out all but the last line
   nLines = n_elements(prompt)
   for i=0, nLines-2 do $
     print, prompt[i]
   answer=''
   ;; Prompt
   read, prompt=prompt[nLines-1], answer

   oPrompt->SetProperty, answer=answer
   return,1
end
;;---------------------------------------------------------------------------
;; IDLitUIConsole::_PromptYesNo
;;
;; Purpose:
;;   Displays a yes-no question the user.
;;
;; Parameter:
;;   oPrompt - The prompt object
;;
function IDLitUIConsole::_PromptYesNo, oPrompt
   compile_opt hidden, idl2

   if(obj_valid(oPrompt) eq 0)then $
     return,0

   oPrompt->GetProperty, prompt=prompt

   ;; Dump out all but the last line
   nLines = n_elements(prompt)
   for i=0, nLines-2 do $
     print, prompt[i]
   answer=''
   ;; Prompt
   read, prompt=prompt[nLines-1]+"[Y/n]", answer
   answer = strupcase(answer)

   status = (answer eq '' or answer eq 'Y' or answer eq 'YES' ? 1 : 0)
   oPrompt->SetProperty, answer=status
   return, 1
end

;;---------------------------------------------------------------------------
;; Callback section
;;
;; The following methods implement the interface that the tool
;; uses to communicate with the user interface.
;;---------------------------------------------------------------------------
;; IDLitUIConsole::HandleMessage
;;
;; Purpose:
;;   Access point for sync messages.
;;
;; Parameters
;;   oMessage - The message
;;
;; Return Values:
;;    0  - Error
;;    1  - A Okay

function IDLitUIConsole::HandleMessage, oMessage
   ;; Pragmas
   compile_opt idl2, hidden

   if(not obj_valid(oMessage))then $
     return, 0

   iType = oMessage->GetType()
   case iType of
       1:  status = self->_ErrorMessage(oMessage)
       2:  status = self->_PromptYesNo(oMessage)
       3:  status = self->_PromptText(oMessage)
       else: return, 0
   endcase

   return, status

end


;;---------------------------------------------------------------------------
;; IDLitUIConsole__Define
;;
;; Purpose:
;;   This method defines the IDLitUIConsole class.
;;

pro IDLitUIConsole__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = { IDLitUIConsole,                     $
           inherits IDLitComponent        $
           }
end
