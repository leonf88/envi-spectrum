; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmsgprogress__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitMsgProgress
;
; PURPOSE:
;    Progress message object.
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
;   See IDLitMsgProgress::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitMsgProgress::Init
;   IDLitMsgProgress::Cleanup
;   IDLitMsgProgress::GetProperty
;   IDLitMsgProgress::SetProperty

;
; INTERFACES:
; IIDLProperty
;-

;-------------------------------------------------------------------------
function IDLitMsgProgress::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; type of four = Progress message.
    if (~self->IDLitMessage::Init(4)) then $
      return, 0

    self->IDLitMsgProgress::SetProperty, _EXTRA=_extra

    return,1
end


;-------------------------------------------------------------------------
;pro IDLitMsgProgress::Cleanup
;
;    compile_opt idl2, hidden
;
;    self->IDLitMessage::Cleanup
;end


;-------------------------------------------------------------------------
pro IDLitMsgProgress::Shutdown

    compile_opt idl2, hidden

    self._done = 1b
end


;-------------------------------------------------------------------------
function IDLitMsgProgress::IsDone

    compile_opt idl2, hidden

    return, self._done
end


;-------------------------------------------------------------------------
pro IDLitMsgProgress::Reset

    compile_opt idl2, hidden

    self._done = 0b
    self._cancel = ''
    self._time = 0b
    self._percent = 0
    self->IDLitMessage::SetProperty, MESSAGE=''

end


;-------------------------------------------------------------------------
pro IDLitMsgProgress::GetProperty, $
    CANCEL=cancel, $
    PERCENT=percent, $
    TIME=time, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(cancel) then $
        cancel = self._cancel

    if ARG_PRESENT(percent) then $
        percent = self._percent

    if (ARG_PRESENT(time)) then $
        time = self._time

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitMessage::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
pro IDLitMsgProgress::SetProperty, $
    CANCEL=cancel, $
    PERCENT=percent, $
    TIME=time, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(cancel)) then $
        self._cancel = cancel

    if (N_ELEMENTS(percent)) then begin
        self._percent = percent
        self._done = 0b
    endif

    if (N_ELEMENTS(time)) then $
        self._time = time

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitMessage::SetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
pro IDLitMsgProgress__define

    compile_opt idl2, hidden

    struc = {IDLitMsgProgress,            $
             inherits IDLitMessage,    $
             _percent: 0d, $
             _done: 0b, $
             _time: 0b, $
             _cancel: '' $
             }

end

