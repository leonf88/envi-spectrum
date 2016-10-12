; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiadaptor__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitUIAdaptor
;
; PURPOSE:
;   This file implements the IDLitUIAdaptor class. This class provides
;   an object adaptor that allows object methodology to be dispatch to
;   IDL widget elements that comprise the user interface.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitUIAdaptor::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitUIAdaptor::Init
;   IDLitUIAdaptor::Cleanup
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::Init
;;
;; Purpose:
;; The constructor of the IDLitObjDesc object.
;;
;; Parameters:
;;   wID    - Widget ID of the target widget
;;
;; Keywords
;;   ONNOTIFY_CALLBACK   - Set to the procedure name that should be
;;                         called when the OnNotify method is called.
;;
;;   DOUISERVICE_CALLBACK - Set to the function name that should be
;;                          called when the DoUIService method is called.

function IDLitUIAdaptor::Init, WIDGET_ID=wID, $
                       ONNOTIFY_CALLBACK = onNotifyCB, $
                       DOUISERVICE_CALLBACK = onUIServiceCB, $
                       FLOATING=FLOATING, $
                       _EXTRA=_extra

  ;; Pragmas
  compile_opt idl2, hidden
  
 

  if(self->IDLitComponent::Init(_EXTRA=_extra) eq 0)then $
    return, 0

  ;; Set the widget id
  if(keyword_set(wID))then $
    self._wID = wID

  self._floating = keyword_set(floating)

  if(keyword_set(onNotifyCB))then $
    self._OnNotifyCB = onNotifyCB

  if(keyword_set(onUIServiceCB))then $
    self._OnUIServiceCB = onUIServiceCB

;  print, 'IDLitUIAdaptor Constructor: '+self.IDENTIFIER
;  if (keyword_set(onNotifyCB)) then $
;    print, '   onNotifyCB = '+self._OnNotifyCB
  
  return, 1
end
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
pro IDLitUIAdaptor::Cleanup
  ;; Pragmas
  compile_opt idl2, hidden

  self->IDLitComponent::Cleanup

;  if (widget_info(self._wID, /valid_id))then $
;    widget_control, self._wID, /destroy ;; KDB - Will this cause  issues

end

;;---------------------------------------------------------------------------
;; Property Interface
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::GetProperty
;;
;; Purpose:
;;   This procedure method retrieves the value of a property or group of
;;   properties associated with this object.
;;
;; Keywords:
;;   WIDGET_ID:	Set this keyword to a named variable that upon return will
;;     contain the widget ID of the target widget.
;;
pro IDLitUIAdaptor::GetProperty, WIDGET_ID=wID, floating=floating, $
                  _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(wID) ne 0) then $
        wID = self._wID

    if(arg_present(floating) ne 0)then $
      floating=self._floating

    ; Call superclass.
    self->IDLitComponent::GetProperty, _EXTRA=_extra
end
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::SetProperty
;;
;; Purpose:
;;   Allows properties to be set on the ui adaptor.
;;
;; Keywords:
;;  floating   - Used to set the floating state of the widget.
;; 
pro IDLitUIAdaptor::SetProperty, floating=floating, $
                  _REF_EXTRA=_extra
    compile_opt hidden, idl2
    if(n_elements(floating) gt 0)then $
      self._floating = floating

    ; Call superclass.
    self->IDLitComponent::GetProperty, _EXTRA=_extra
end

;;---------------------------------------------------------------------------
;; Implementation
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::OnNotify
;;
;; Purpose:
;;   Called by the framework when a Notification message is sent to
;;   this object. This message is then transferred to our target
;;   Widget.
;;
;; Parameters:
;;    strID      - ID of the tool item that had its state change
;;
;;    message    - The type of message sent
;;
;;    messparam  - A parameter that is associated with the message.

PRO IDLitUIAdaptor::OnNotify, strID, messageIn, userdata

  ;; Pragmas
  compile_opt idl2, hidden

    if (self._OnNotifyCB eq '') then return

    ;; if the widget id is invalid, return.
    if(widget_info(self._wID,/valid) eq 0)then return

    myStrID = strID
    myMessageIn = messageIn
    myUserData = userdata
    ; We will use the [0] to force temporary variables to be created,
    ; so that the user can't mess up the arguments.
    call_procedure, self._OnNotifyCB, (self._wID)[0], myStrID, $
        myMessageIn, myUserData

end

;;---------------------------------------------------------------------------
;; IDLitUIAdaptor::DoUIService
;;
;; Purpose:
;;  Called by the framework when a UI service is requested.
;;
;; Parameters:
;;   oUI           - The UI object that interfaces with the tool
;;
;;   oRequester    - The object/interface that is used by the service
;;                   to set values ...etc. This is service dependent.
;;
;; Return Value
;;    0   - Failure
;;
;;    1   - Success

FUNCTION IDLitUIAdaptor::DoUIService, oUI, oRequestor

  ;; Pragmas
  compile_opt idl2, hidden

  if(self._OnUIServiceCB eq '')then return, 0

  self->GetProperty, UVALUE=uvalue

  return, (N_ELEMENTS(uvalue) gt 0) ? $
    call_function( self._OnUIServiceCB, oUI, oRequestor, UVALUE=uvalue) : $
    call_function( self._OnUIServiceCB, oUI, oRequestor)

end

;;---------------------------------------------------------------------------
;; Defintion
;;---------------------------------------------------------------------------
;; IDLitUIAdaptor__Define
;;
;; Purpose:
;; Class definition for the IDLitObjDesc class
;;

pro IDLitUIAdaptor__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitUIAdaptor, $
          inherits   IDLitComponent,    $
          _wID               : 0l, $  ;; The target widget
          _floating          : 0b, $  ;; Does this float
          _OnNotifyCB        : '', $  ;; Notify callback
          _OnUIServiceCB     : ''  $  ;; UI Service callback
         }

end
