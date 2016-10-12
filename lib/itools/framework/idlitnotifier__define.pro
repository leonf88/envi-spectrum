; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitnotifier__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitNotifier
;
; PURPOSE:
;   Implements the subject-observer methods.
;
; SUPERCLASSES:
;   IDLitComponent
;   IDL_Container
;
; INTERFACES:
;   This component exposes the following interfaces:
;     IIDLProperty
;     IIDLNotifier
;     IIDLContainer
;
; METHODS:
;   This class has the following intrinsic methods:
;     IDLitNotifier::Cleanup
;     IDLitNotifier::Init
;     IDLitNotifier::GetProperty
;     IDLitNotifier::Notify
;     IDLitNotifier::SetProperty
;     IDLitNotifier::Add
;
;   This class inherits the following methods:
;     IDL_Container::Count
;     IDL_Container::Get
;     IDL_Container::IsContained
;     IDL_Container::Move
;     IDLitComponent::QueryProperty
;     IDLitComponent::RegisterProperty
;     IDL_Container::Remove
;
; PROPERTIES:
;   This class has the following properties:
;     CALLBACK
;     NOTIFY
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2001.
;-


;----------------------------------------------------------------------------
; IDLitNotifier::Init
;   This function method initializes the IDLitNotifier object.
;
; CALLING SEQUENCE:
;   oNotify = OBJ_NEW('IDLitNotifier')
;       or
;   Result = oNotify->[IDLitNotifier::]Init()
;
; INPUTS:
;   Callback: Set this argument to a string giving the name of the
;      callback method to be called by IDLitNotifier::Notify
;
function IDLitNotifier::Init, CallbackArg, $
    CALLBACK=callbackIn, NOTIFY=notify, $
    _REF_EXTRA=_ref_extra

    compile_opt idl2, hidden

; Initialize the superclasses.
    success = self->IDLitComponent::Init()
    if (success eq 0) then return, 0   ; failure

    success = self->IDL_Container::Init()
    if (success eq 0) then return, 0   ; failure

; The Callback argument takes precedence over the keyword...
    if (N_ELEMENTS(callbackIn) gt 0) then self.callback = callbackIn
    if (N_ELEMENTS(CallbackArg) gt 0) then self.callback = CallbackArg

; Set default properties.
    self.notify = 1  ; Default is On.

; Pass on all properties.
    self->IDLitNotifier::SetProperty, NOTIFY=notify, $
        _EXTRA=_ref_extra

    void = CHECK_MATH()  ; swallow arithmetic errors

    return, 1  ; success
end


;----------------------------------------------------------------------------
; IDLitNotifier::Cleanup
;   This procedure method performs all cleanup on the object.
;
; CALLING SEQUENCE:
;   oNotify->[IDLitNotifier::]Cleanup
;
pro IDLitNotifier::Cleanup
    compile_opt idl2, hidden

; We don't want to actually destroy objrefs within the observer list,
; so remove everything before calling superclass destroy.
    self->IDL_Container::Remove, /ALL

; Cleanup the superclasses.
    self->IDL_Container::Cleanup
    self->IDLitComponent::Cleanup

end


;----------------------------------------------------------------------------
; IDLitNotifier::GetProperty
;   This procedure method retrieves properties from an IDLitNotifier object.
;
; CALLING SEQUENCE:
;   oNotify->[IDLitNotifier::]GetProperty
;
pro IDLitNotifier::GetProperty, $
    CALLBACK=callback, NOTIFY=notify, $
    _REF_EXTRA=_ref_extra

    compile_opt idl2, hidden

; CALLBACK property
    if ARG_PRESENT(callback) then $
        callback = self.callback

; NOTIFY property
    if ARG_PRESENT(notify) then $
        notify = self.notify

; Retrieve superclass properties.
    if (N_ELEMENTS(_ref_extra) gt 0) then begin
        self->IDLitComponent::GetProperty, _EXTRA=_ref_extra
    endif
end


;----------------------------------------------------------------------------
; IDLitNotifier::SetProperty
;   This procedure method sets properties for an IDLitNotifier object.
;
; CALLING SEQUENCE:
;   oNotify->[IDLitNotifier::]SetProperty
;
pro IDLitNotifier::SetProperty, $
    NOTIFY=notify, $
    _REF_EXTRA=_ref_extra

    compile_opt idl2, hidden

; NOTIFY property
    if (N_ELEMENTS(notify) gt 0) then begin
        self.notify = KEYWORD_SET(notify)
    endif

; Set superclass properties.
    if (N_ELEMENTS(_ref_extra) gt 0) then begin
        self->IDLitComponent::SetProperty, _EXTRA=_ref_extra
    endif
end


;----------------------------------------------------------------------------
; IDLitNotifier::Add
;   This procedure method adds an object to the notifier list, but only
;   if it is not already there, thus preventing duplicates.
;
; CALLING SEQUENCE:
;   oNotify->[IDLitNotifier::]Add, objref
;
; INPUTS:
;   objref - an object reference for the object to add to the notifer list.
;
; KEYWORDS:
;   POSITION - same as for IDL_Container
;
pro IDLitNotifier::Add, objref, $
    _REF_EXTRA=_ref_extra

    compile_opt idl2, hidden

    ; Do the actual add in the superclass, but only if not already there
    ind = WHERE(self->IsContained(objref) eq 0, count)
    if count gt 0 then begin
        self->IDL_Container::Add, objref[ind], _EXTRA=_ref_extra
    endif
end

;----------------------------------------------------------------------------
; IDLitNotifier::Notify
;   This procedure method notifies all observers that
;   the Subject has changed.
;
; CALLING SEQUENCE:
;   oNotify->[IDLitNotifier::]Notify, Subject [, P1 [, P2 [,...[, P8]]]]
;
; INPUTS:
;   Subject: Set this argument to the object reference of the subject
;      whose property has changed.
;   Pi: The parameters to be passed to the observers' callback method.
;      These are the positional arguments documented for the called
;      method.
;
; KEYWORD PARAMETERS:
;   CALLBACK:  Set this keyword to a string giving the name of the
;              callback method to be called.  If not provided, the
;              callback provided via IDLitNotifier::Init (if any)
;              is used.
;
pro IDLitNotifier::Notify, Subject, P1, P2, P3, P4, P5, P6, P7, P8, $
    CALLBACK=callbackIn

    compile_opt idl2, hidden

    nObservers = self->Count()
    if (nObservers lt 1) then $
        return

    callback = (N_ELEMENTS(callbackIn) gt 0) ? callbackIn : $
        self.callback

    if ((callback eq '') or (not self.notify)) then $
        return

; Notify all observers, using the correct number of arguments.
; For CALL_METHOD:
;   Argument1 is the notification callback method name.
;   Argument2 is the Observer (the object being notified, and whose
;             callback method is to be called).
;   Argument3 is the Subject issuing the notification, always passed as
;             the first argument to the callback method.  Typically,
;             Subject=self.
;   All subsequent arguments are the Pi arguments passed in (the arguments
;             that apply to the given callback method).
;

    ; Subtract 1 from N_PARAMS so this gives the number of actual
    ; parameters that are being passed to the method.
    nParams = N_PARAMS()-1
    oObservers = self->Get(/ALL)

    ;; Validate our observers. Resoration of this object can lead to
    ;; invalid references
    inValid = where(~obj_valid(oObservers), nInValid)
    if(nInValid gt 0)then begin
        self->Remove, oObservers[inValid]
        oObservers = self->Get(/ALL, COUNT=nObservers)
    endif
;    self.lock = self.lock + 1

    case (nParams) of
        0: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject
        1: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1
        2: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2
        3: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3
        4: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3, P4
        5: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3, P4, P5
        6: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3, P4, P5, P6
        7: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3, P4, P5, P6, P7
        8: for i=0, nObservers-1 do $
                CALL_METHOD, callback, oObservers[i], Subject, $
                    P1, P2, P3, P4, P5, P6, P7, P8
        else: MESSAGE, 'Incorrect number of arguments.'
    endcase

;    self.lock = self.lock - 1

;    if (self.lock ne 0) then begin
;        print, 'Lock='+STRTRIM(self.lock,2)+' CALLBACK='+callback
;        RETURN
;    endif
end


;----------------------------------------------------------------------------
; IDLitNotifier__define
;   This private procedure creates the IDLitNotifier structure.
;
; CALLING SEQUENCE:
;   Called automatically when the user creates an IDLitNotifier object.
;
pro IDLitNotifier__define

    compile_opt idl2, hidden

    struct = {IDLitNotifier, $
        inherits IDLitComponent, $
        inherits IDL_Container, $
        callback: '', $
        notify: 1L, $
        lock: 0}
end
