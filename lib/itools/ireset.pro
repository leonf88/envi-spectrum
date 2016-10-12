; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ireset.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iReset
;
; PURPOSE:
;   A command line routine used to reset the entire tools system in
;   the current IDL session. It will call the _ResetSystem method on
;   the underlying system object.
;
; PARAMETERS:
;   None.
;
; KEYWORDS:
;   NO_PROMPT - If set, the user is not prompted to verify the reset action.
;-

;-------------------------------------------------------------------------
PRO iReset, NO_PROMPT=NO_PROMPT

   compile_opt hidden, idl2

    common __IDLitTools$SystemResourceCache$_, $
        c_sysColors, c_strNames, c_Userdir, c_bitmapNames, c_bitmapValues

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return
   endif

    ; Basically Get the system object and reset the system.
    ; Set the NO_CREATE flag so if the system isn't up, don't
    ; create it so it can be destroyed!
    oSystem = _IDLitSys_GetSystem(/NO_CREATE)
    if(obj_valid(oSystem))then $
        oSystem->__ResetSystem, NO_PROMPT=NO_PROMPT

    ; Free up our cached resources.
    if (N_ELEMENTS(c_bitmapValues) gt 0) then begin
        PTR_FREE, c_bitmapValues
        void = TEMPORARY(c_bitmapValues)
    endif

    if (N_ELEMENTS(c_bitmapNames) gt 0) then $
        void = TEMPORARY(c_bitmapNames)

end


