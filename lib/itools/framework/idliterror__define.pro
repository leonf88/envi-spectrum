; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idliterror__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitError
;
; PURPOSE:
;    Generic error message object.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;    IDLitMessage
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitError::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitError::Init
;   IDLitError::Cleanup
;   IDLitError::GetProperty
;   IDLitError::SetProperty

;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitError::Init
;;
;; Purpose:
;; The constructor of the IDLitError object.
;;
;; Keywords
;;  Set the SetProperty Method.

;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitError::Init, _EXTRA=_SUPER

    ;; Pragmas
    compile_opt idl2, hidden

    ;; type of one = Error message.

    iStatus = self->IDLitMessage::Init(1, _EXTRA=_SUPER)
    if(iStatus ne 1)then $
      return, 0

    self._pstrDescription = ptr_new(/allocate_heap)
    self->IDLitError::SetProperty, _EXTRA=_SUPER
    return,1
end

;-------------------------------------------------------------------------
;; IDLitError::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitError object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitError::Cleanup

    ;; Pragmas
    compile_opt idl2, hidden

    if(ptr_valid(self._pstrDescription))then $
       ptr_free, self._pstrDescription

    self->IDLitMessage::Cleanup
end


;-------------------------------------------------------------------------
;; IDLitError::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitError::GetProperty, CODE=CODE, $
              DESCRIPTION=DESCRIPTION, $
              SEVERITY=SEVERITY,$
              _REF_EXTRA=_SUPER
    ;; Pragmas
    compile_opt idl2, hidden

    if(arg_present(code))then code = self._iCode
    if(arg_present(severity))then severity = self._Severity
    if(arg_present(description))then description = $
         (n_elements(*self._pstrDescription) gt 0 ? *self._pstrDescription : '')

    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::GetProperty, _EXTRA=_SUPER
end


;-------------------------------------------------------------------------
;; IDLitError::SetProperty
;;
;; Purpose:
;;   Set aspects of this error condition
;;
;; Keywords
;;   CODE         - An error code of type long
;;
;;   SEVERITY     - The severity of the error.
;;
;;   DESCRIPTION  - A long string message for the error condition
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitError::SetProperty, CODE=CODE, $
              DESCRIPTION=DESCRIPTION, $
              SEVERITY=SEVERITY, $
              _EXTRA=_SUPER

    ;; Pragmas
    compile_opt idl2, hidden

    if(n_elements(severity) gt 0)then self._severity = severity
    if(n_elements(code) gt 0)then self._iCode=code
    if(n_elements(description) gt 0)then $
       *self._pstrDescription = description


    if(n_elements(_SUPER) gt 0)then $
      self->IDLitMessage::SetProperty, _extra=_super
end
;-------------------------------------------------------------------------
;; IDLitError::GetTextMessage
;;
;; Purpose:
;;   Return a string version of this message
;;
function IDLitError::GetTextMessage
   compile_opt idl2, hidden

   strMess = self->IDLitMessage::GetTextMessage()

   strMess =  string( strMess, self._severity, self._iCode, $
                 FORMAT='(%"ERROR:\t%s, SEVERITY: %d, CODE: %d")')
   if(n_elements(*self._pstrDescription) gt 0)then $
       strMess = [strMess, $
                  string(*self._pstrDescription, format='(%"\t\t%s")')]

   return, strMess
end


;-------------------------------------------------------------------------
pro IDLitError__define

   compile_opt idl2, hidden
    struc = {IDLitError,            $
             inherits IDLitMessage,    $
             _pstrDescription : ptr_new(), $
             _iCode           : 0l, $
             _Severity        : 0 $
             }

end

