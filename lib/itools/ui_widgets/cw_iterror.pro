; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_iterror.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   An include file that can be used for error handling in
;   iTool compound widgets. The compound widget code should
;   look like:
;
;       nparams = 3
;       @cw_iterror
;
;   where nparams is the minimum number of arguments that
;   must be supplied to the routine.
;


; Include our customizable error handling.
@idlit_on_error2
@idlit_catch

if (ierr ne 0) then begin
    catch, /cancel
    ; This will add our subroutine prefix.
    MESSAGE, !error_state.msg
endif

; Check arguments. Note that nparams must be defined
; by the including routine.
if (N_PARAMS() lt nparams) then $
  MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

if (~OBJ_VALID(oUI)) then $
  MESSAGE, IDLitLangCatQuery('UI:InvalidOUI')

