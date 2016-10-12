; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/getwindows.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Returns all the current graphics windows
;
; :Params:
;    NAME - the name of the window to return
;
; :Keywords:
;    CURRENT - return the current window
;    
;    NAMES [Out] - Returns the names of all the windows
;
;-
;-------------------------------------------------------------------------
function getwindows, name, CURRENT=current, NAMES=namesOut, _REF_EXTRA=ex
  compile_opt idl2, hidden
  ON_ERROR, 2

  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then $
    return, !NULL
  
  windows = []  
  namesOut = []

  if (KEYWORD_SET(current)) then begin
    oTool = oSystem->_GetCurrentTool()
    oWin = oTool->GetCurrentWindow()
    if (OBJ_ISA(oWin, 'GraphicsWin')) then begin
      windows = oWin
      oTool->GetProperty, NAME=namesOut
    endif
  endif else begin
    oTools = (oSystem->Get(/TOOLS))->Get(/ALL)
    for i=0,N_ELEMENTS(oTools)-1 do begin
      oTools[i]->GetProperty, NAME=toolName
      oWin = oTools[i]->GetCurrentWindow()
      ; Only return graphics windows, not iTools
      if (~OBJ_ISA(oWin, 'GraphicsWin')) then continue
      ; Match name if supplied
      if (N_ELEMENTS(name) ne 0) then begin
        if (STRMATCH(toolName, name[0], /FOLD_CASE)) then begin
          windows = [windows, oWin]
          namesOut = [namesOut, toolName]
          break ;; Only return first item found with matching name
        endif
      endif else begin
        windows = [windows, oWin]
        namesOut = [namesOut, toolName]
      endelse
    endfor
  endelse
  
  return, ISA(windows) ? windows : OBJ_NEW() 
  
end
