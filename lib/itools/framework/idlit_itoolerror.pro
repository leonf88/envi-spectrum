; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlit_itoolerror.pro#1 $
;
; Purpose:
;   An include file that should be used at the top of every iTool.
;   Controls error handling and cleans up any parameter sets.
;
; Use:
;   To disable error handling, use /DEBUG from one of the iTools.
;
; First check for the DEBUG keyword.
if (N_Elements(debug)) then Defsysv, '!iTools_Debug', Keyword_Set(debug)
@idlit_on_error2.pro
@idlit_catch.pro
if (iErr ne 0) then begin
    Catch, /CANCEL
    if (N_Elements(oParmSet)) then Obj_Destroy, oParmSet
    ; Assume that if the first 4 letters start with "I" and are uppercase,
    ; then this is an iTool error and strip off the beginning.
    start = STRMID(!Error_State.msg,0,4)
    if (STRMID(start,0,1) eq 'I' && STRUPCASE(start) eq start) then begin
      semi = Strpos(!Error_State.msg, ':')
      if (semi gt 0) then !Error_State.msg = Strmid(!Error_State.msg, semi+2)
    endif
    Message, !Error_State.msg
    Return
endif
; end idlit_itoolerror
