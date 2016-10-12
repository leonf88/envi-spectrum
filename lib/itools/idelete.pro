; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/idelete.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iDelete
;
; PURPOSE:
;   Used to delete a tool in the system from the command line
;
; CALLING SEQUENCE:
;   iDelete[, idTool]
;
; INPUTS:
;   idTool  - The identifier for the tool to delete. If not provided,
;             the current tool is used.
;
; KEYWORD PARAMETERS:
;   None
;
; MODIFICATION HISTORY:
;   Written by:  KDB, RSI, Novemember 2002
;   Modified: AGEH, RSI, August 2008: Rename it->i
;
;-

;-------------------------------------------------------------------------
PRO iDelete, idTool, _EXTRA=_extra

   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return
   endif

   if (N_Elements(idTool) eq 1 && Strcmp(idTool,'/Window/',8,/FOLD_CASE)) then begin
      WDelete, Long(Strmid(idTool, 8))
      return
   endif
   
   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem(/NO_CREATE)
   if(not obj_valid(oSystem))then $
     return

   if(n_elements(idTool) eq 0)then $
     idTool = oSystem->GetCurrentTool()

   oSystem->DeleteTool, idTool, _EXTRA=_extra
end


