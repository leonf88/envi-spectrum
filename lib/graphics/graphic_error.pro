; Error handling for new graphics
  if (ISA(debug)) then Defsysv, '!iTools_Debug', KEYWORD_SET(debug)
  Defsysv, '!iTools_Debug', EXISTS=hasDebug
  if (~hasDebug || ~!iTools_Debug) then on_error, 2
  iErr = 0
  if (~hasDebug || ~!iTools_Debug) then catch, iErr
  if (iErr ne 0) then begin
    catch, /cancel
    msg = !ERROR_STATE.MSG
    ; Look for Class::Method: Error... and strip off Class::Method:
    class = STRPOS(msg, '::', /REVERSE_SEARCH)
    method = class gt 0 ? STRPOS(msg, ':', class+2) : -1
    if (method gt 0) then begin
      msg = STRMID(msg, method+2)
    endif else begin
      ; Assume that if the first 4 letters start with "I" and are uppercase,
      ; then this is an iTool error and strip off the initial "I".
      start = STRMID(msg,0,4)
      if (STRMID(msg,0,1) eq 'I' && STRUPCASE(start) eq start) then $
        msg = STRMID(msg, 1)
    endelse
    MESSAGE, msg, /NONAME
  endif
