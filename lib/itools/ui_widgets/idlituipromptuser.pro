; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituipromptuser.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIPromptUser
;
; PURPOSE:
;   Provides the user interface for selecting an IDL command line
;   variable
;
; CALLING SEQUENCE:
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;
;-



;-------------------------------------------------------------------------
function IDLitUIPromptUser, oUI, oPrompt

   compile_opt idl2, hidden

   ;; Basically that the text in the error object and display an
   ;; dialog_message()

   if(obj_valid(oPrompt) eq 0)then $
     return, 0

   oPrompt->GetProperty, $
        TITLE=title, $
        PROMPT=prompt, $
        CANCEL=cancel, $
        DEFAULT_NO=defaultNo

   ; For group leader use the top-level base that has the focus.
   ; This is usually the current tool, but may be a modal widget.
   ; It may also be undefined if there are no top-level bases
   ; active.
   oUI->GetProperty, WIDGET_FOCUS=wLeader

   ; Make sure that the leader is not hidden behind the workbench.
   if (N_ELEMENTS(wLeader) && WIDGET_INFO(wLeader, /VALID)) then begin
      WIDGET_CONTROL, wLeader, /SHOW, ICONIFY=0
   endif
   
   status = DIALOG_MESSAGE(prompt, title=title, $
        /QUESTION, CANCEL=cancel, $
        DEFAULT_NO=defaultNo, $
        dialog_parent=wLeader)

   case status of
        'Yes': status = 1
        'No':  status = 0
        else:  status = -1   ; Cancel
   endcase

   oPrompt->SetProperty, ANSWER=status

   return, 1
end

