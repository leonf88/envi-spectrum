; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopshutdown__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopShutdown
;
; PURPOSE:
;   This file implements the tool shutdown operation. This is called
;   when it is desired to shutdown the tool in a graceful manner.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopShutdown
;
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopShutdown::Init
;;
;; Purpose:
;; The constructor of the IDLitopShutdown Operation
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopShutdown::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    return, self->IDLitOperation::Init(_EXTRA=_extra)

end
;;---------------------------------------------------------------------------
;; IDLitopShutdown::DoAction
;;
;; Purpose:
;;   Generic operation entry point. Allows this operation to be called
;;   using the normal tool methodology.
;;
;; Parameter:
;;    oTool   - The tool
function IDLitopShutdown::DoAction, oTool
   compile_opt hidden, idl2

   ;; Just call the main shutdown routine.
   self->IDLitopShutdown::DoShutdown

   return, obj_new()
end
;;---------------------------------------------------------------------------
;; IDLitopShutdown::DoShutdown
;;
;; Purpose:
;;   When called, will shutdown this tool gracefully.
;;
;; Parameters:
;;   None.

pro IDLitopShutdown::DoShutdown, NO_PROMPT=noPrompt, RESET=reset
   compile_opt hidden, idl2

    oTool = self->GetTool()

    ; If our current state has been modified, prompt to save first.
    ; If user hits cancel, then don't exit.
    if (~KEYWORD_SET(noPrompt) && (oTool->_CheckForUnsaved() eq -1)) then $
        return

    ; Don't attempt to update history folder if the system is going down
    if ~keyword_set(reset) then begin
        ; rename history folder; must be done before obj_destroy of tool
        oSrvMacro = oTool->GetService('MACROS')
        if OBJ_VALID(oSrvMacro) then $
            oSrvMacro->RenameHistoryFolder
    endif

    obj_destroy, oTool ;; time to die

   ; Make sure we have a current tool. This will also have the side effect
   ; of notifying the workbench that the current tool has changed.
   void = iGetCurrent()

end
;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitopShutdown__define

    compile_opt idl2, hidden

    struc = {IDLitopShutdown,       $
             inherits IDLitOperation $
            }
end

