; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitstatussegment__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Class Name:
;   IDLitStatusSegment
;
; Purpose:
;   This class represents a unique segment within a status bar.
;

;-------------------------------------------------------------------------
; Lifecycle Methods
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitStatusSegment::Init
;
; Purpose:
;   This function method initializes the status segment object.
;
; KEYWORDS:
;   NORMALIZED_WIDTH: Set this keyword to a value between 0.01 and 1.0
;     indicating the normalized width of this status bar segment.
;     the default is 1.0.

function IDLitStatusSegment::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass.
    if (self->IDLitComponent::Init(_EXTRA=_extra) ne 1) then $
        return, 0

    ; Initialize defaults.
    self._normalizedWidth = 1.0
    self._msgTypeCode = 10

    ; Set any properties.
    self->IDLitStatusSegment::SetProperty, _EXTRA=_extra

    return, 1
end

;-------------------------------------------------------------------------
; IDLitStatusSegment::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitStatusSegment::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitComponent::Cleanup
;end

;-------------------------------------------------------------------------
; Property Interface
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitStatusSegment::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
pro IDLitStatusSegment::GetProperty, $
    LAST_MESSAGE=lastMessage, $
    NORMALIZED_WIDTH=normalizedWidth, $
    MESSAGE_TYPE_CODE=msgTypeCode, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(lastMessage)) then $
        lastMessage = self._strLastMsg

    if (ARG_PRESENT(normalizedWidth)) then $
        normalizedWidth = self._normalizedWidth

    if (ARG_PRESENT(msgTypeCode)) then $
        msgTypeCode = self._msgTypeCode

    ; Get superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
       self->IDLitComponent::GetProperty, _EXTRA=_extra 
end

;-------------------------------------------------------------------------
; IDLitStatusSegment::SetProperty
;
; Purpose:
;   This procedure method sets the value of a property or group of
;   properties.
;
pro IDLitStatusSegment::SetProperty, $
    LAST_MESSAGE=lastMessage, $
    NORMALIZED_WIDTH=normalizedWidth, $
    MESSAGE_TYPE_CODE=msgTypeCode, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(lastMessage) gt 0) then $
        self._strLastMsg = lastMessage

    if (N_ELEMENTS(normalizedWidth) gt 0) then $
        self._normalizedWidth = (normalizedWidth[0] > 0.01) < 1.0


    if (N_ELEMENTS(msgTypeCode) gt 0) then $
        self._msgTypeCode = msgTypeCode

    ; Set superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
       self->IDLitComponent::SetProperty, _EXTRA=_extra 
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitStatusSegment__Define
;
; Purpose:
;   This procedure method defines the object structure for an
;   IDLitStatusSegment object.
;
pro IDLitStatusSegment__Define

    compile_opt idl2, hidden

    struc = {IDLitStatusSegment,    $
        inherits IDLitComponent,    $ ; Superclass: IDLitComponent
        _normalizedWidth: 0.0,      $ ; Normalized width (0.1 ... 1.0)
        _msgTypeCode: 0,            $ ; Type code associated with this
                                    $ ;   segment (for messaging).
        _strLastMsg: ''             $ ; Last set message.
    }
end
