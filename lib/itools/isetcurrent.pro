; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/isetcurrent.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;-------------------------------------------------------------------------
;+
; :Description:
;    Used to set the current tool in the iTools system.
;
; :Params:
;    idTool:
;        The identifier for the tool to set current. If idTool is
;        not present and /SHOW is set, then the current tool
;        is made visible.
;
; :Keywords:
;    SHOW 
;       If set then also ensure that the tool is visible
;       and raised (not iconified).
;
; :Author: KDB, RSI, Novemember 2002
;  Modified: AGEH, RSI, August 2008: Rename it->i
;-
PRO iSetCurrent, idTool, SHOW=show

   compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       MESSAGE, /REISSUE_LAST
       return
   endif

   if (size(/type, idTool) ne 7) then begin
     if (N_Elements(idTool) eq 0 && Keyword_Set(show)) then begin
       idTool = iGETCURRENT()
     endif else begin
       message, "Provided argument must be a valid iTool identifier"
     endelse
   endif

   if (Strcmp(idTool,'/Window/',8,/FOLD_CASE)) then begin
      WSet, Long(Strmid(idTool, 8))
      WShow, Long(Strmid(idTool, 8))
      return
   endif
   
   ;; Basically Get the system object and return the current tool
   ;; identifier.
   oSystem = _IDLitSys_GetSystem(/NO_CREATE)

   ;; validate the id
   if(~obj_valid(oSystem) || ~obj_valid(oSystem->GetByIdentifier(idTool)))then $
     message, "Invalid iTool identifier provided. No such iTool."
   oSystem->SetCurrentTool, idTool, SHOW=show
end


