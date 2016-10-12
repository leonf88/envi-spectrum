; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmessage__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitMessage
;
; PURPOSE:
;    Generic message object. Fairly abstract, only providing a base
;    class for messaging operations between elements of the
;    tool. Primarly intended for the communication between the Tool
;    and external intities.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitMessage::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitMessage::Init
;   IDLitMessage::Cleanup
;   IDLitMessage::GetProperty
;   IDLitMessage::SetProperty

;
; INTERFACES:
;    IDLitMessage
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitMessage::Init
;;
;; Purpose:
;; The constructor of the IDLitMessage object.
;;
;; Keywords
;;  Set the SetProperty Method.

;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitMessage::Init, type, message = message

    ;; Pragmas
    compile_opt idl2, hidden

    self._msgType = type

    if(n_elements(message) gt 0)then $
      self._strMessage = message[0]
    return,1
end

;-------------------------------------------------------------------------
;; IDLitMessage::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitMessage object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitMessage::Cleanup

    ;; Pragmas
    compile_opt idl2, hidden
end

;-------------------------------------------------------------------------
;; IDLitMessage::GetPrintMessage
;;
;; Purpose:
;;   Returns a "text" version of this message. The intent is to have
;;   sub-classes override this for messaging
;;
;; Return Value
;;   String version of this message

function IDLitMessage::GetTextMessage

    compile_opt idl2, hidden

    return, self._strMessage
end
;-------------------------------------------------------------------------
;; IDLitMessage::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;; Keywords:
;;
;;
;-------------------------------------------------------------------------
pro IDLitMessage::GetProperty, MESSAGE=strMessage


    ;; Pragmas
    compile_opt idl2, hidden

    if(arg_present(strMessage))then strMessage = self._strMessage

end


;-------------------------------------------------------------------------
;; IDLitMessage::SetProperty
;;
;; Purpose:
;;   Set aspects of this error condition
;;
;; Keywords
;;   MESSAGE - Short message relating to this message.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitMessage::SetProperty, MESSAGE=MESSAGE
    ;; Pragmas
    compile_opt idl2, hidden

    if(n_elements(message) gt 0)then self._strMessage = message[0]
end

;-------------------------------------------------------------------------
function IDLitMessage::GetType
    ;; Pragmas
    compile_opt idl2, hidden

    return, self._msgType
end
;-------------------------------------------------------------------------
pro IDLitMessage__define

    compile_opt idl2, hidden

    struc = {IDLitMessage,            $
             _strMessage   : '', $
             _msgType        : 0 $
             }

end

