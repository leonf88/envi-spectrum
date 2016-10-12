; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituiservice__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitUIService
;
; PURPOSE:
;   This class implements the user-interface service connection
;   between the IDL Tool object and the UI tools.
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; METHODS:
;   This class has the following methods:
;
;   IDLitUIService::Init
;   IDLitUIService::Cleanup
;   IDLitUIService::Register
;   IDLitUIService::DoUIService
;
; INTERFACES:
;
;-


;-------------------------------------------------------------------------
; Init
;
; Purpose:
;   Create a new instance.
;
; Syntax:
;   obj = OBJ_NEW('IDLitUIService')
;  or
;   Result = self->IDLitUIService::Init() [from superclass]
;
; Arguments:
;
; Keywords:
;
function IDLitUIService::Init

    compile_opt idl2, hidden

    return, 1

end


;-------------------------------------------------------------------------
; Cleanup
;
; Purpose:
;   Cleanup all instance data before destroying object.
;
; Syntax:
;   OBJ_DESTROY, obj
;  or
;   self->IDLitUIService::Cleanup  [from superclass]
;
; Arguments:
;
; Keywords:
;
pro IDLitUIService::Cleanup

    compile_opt idl2, hidden

    if PTR_VALID(self._service) then begin
        for i=0,N_ELEMENTS(*self._service)-1 do begin
            PTR_FREE, (*self._service)[i].uvalue
        endfor
        PTR_FREE, self._service
    endif

end


;-------------------------------------------------------------------------
; Register
;
; Purpose:
;   Register a user-interface service.
;
; Syntax:
;   obj->Register, Service, Function [, UVALUE=uvalue]
;
; Arguments:
;
;   Service - A string giving the service name.
;
;   Function - A string giving the function to call.
;
; Keywords:
;
;   UVALUE - An optional variable of any IDL type. If UVALUE
;            is present, then it will be passed on to the
;            service function when it is called.
;
pro IDLitUIService::Register, strService, strFunction, $
    UVALUE=uvalue

    compile_opt idl2, hidden

    newService = {_IDLITUISERVICE, $
        SERVICE: strService, $
        FUNCNAME: strFunction, $
        UVALUE: PTR_NEW()}

    if (N_ELEMENTS(uvalue) gt 0) then $
        newService.uvalue = PTR_NEW(uvalue)

    if not PTR_VALID(self._service) then begin
        self._service = PTR_NEW(newService)
    endif else begin
        *self._service = [*self._service, newService]
    endelse

end


;-------------------------------------------------------------------------
; DoUIService
;
; Purpose:
;   Perform a user-interface service.
;
; Syntax:
;   Result = obj->DoUIService(Service, Requester)
;
; Arguments:
;
;   Service - A string giving the service name to perform.
;
;   Requester - The object reference for the caller.
;
; Keywords:
;
function IDLitUIService::DoUIService, strService, oRequester

    compile_opt idl2, hidden

    ; No registered services.
    if not PTR_VALID(self._service) then $
        return, 0

    ; Check arguments.
    if (N_PARAMS() ne 2) then return, 0
    if (SIZE(strService, /TYPE) ne 7) then return, 0
    if not OBJ_VALID(oRequester) then return, 0

    ; Loop up requested service name.
    iService = (WHERE((*self._service).service eq strService))[0]
    if (iService eq -1) then return, 0

    service = (*self._service)[iService].service
    funcname = (*self._service)[iService].funcname
    uvalue = (*self._service)[iService].uvalue

    success = PTR_VALID(uvalue) ? $
        CALL_FUNCTION(funcname, oRequester, UVALUE=*uvalue) : $
        CALL_FUNCTION(funcname, oRequester)

    return, success
end


;-------------------------------------------------------------------------
pro IDLitUIService__define

    compile_opt idl2, hidden

    struc = {IDLitUIService, $
        _service: PTR_NEW()}

end

