; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/widget_window.pro#4 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create a draw widget.
;
; :Params:
;    wBase
;
; :Keywords:
;    
;
; :Author: ITTVIS, March 2010
;-

;-------------------------------------------------------------------------
pro widget_window_realize, wDraw

  compile_opt idl2, hidden
  on_error, 2

  ; Retrieve the draw window object reference.
  ; Temporarily turn off the func_get_value (if set) to avoid
  ; calling into the user's function.
  fGetValue = WIDGET_INFO(wDraw, /FUNC_GET_VALUE)
  WIDGET_CONTROL, wDraw, FUNC_GET_VALUE=''
  WIDGET_CONTROL, wDraw, GET_VALUE=oWindow
  if (fGetValue ne '') then $
    WIDGET_CONTROL, wDraw, FUNC_GET_VALUE=fGetValue

  geom = WIDGET_INFO(wDraw, /GEOMETRY)
  autoResize = geom.xsize eq geom.draw_xsize && geom.ysize eq geom.draw_ysize

  winDims = oWindow->GetDimensions(VIRTUAL_DIMENSIONS=virtualDims)

  ; Set the MINIMUM_VIRTUAL_DIMENSIONS to match the virtual dims.
  ; We also manually set the VIRTUAL_DIMENSIONS property, because if the
  ; X/Y_SCROLL_SIZE was the same as the X/YSIZE on the WIDGET_DRAW,
  ; then the VIRTUAL_DIMENSIONS are set to [0,0], which implies
  ; matching the dimensions.
  ; Set AUTO_RESIZE to true if VIRTUAL_DIMENSIONS was passed in.
  oWindow->SetProperty, $
    MINIMUM_VIRTUAL_DIMENSIONS=autoResize ? [0,0] : virtualDims, $
    VIRTUAL_DIMENSIONS=virtualDims, $
    AUTO_RESIZE=autoResize

  ;XXX Retrieve our cached state from the PRO_SET_VALUE string.
  state = WIDGET_INFO(wDraw, /PRO_SET_VALUE)
  state = STRTOK(state, ',', /EXTRACT, /PRESERVE_NULL)
  uiID = ULONG(state[0])
  wNotifyRealize = state[1]

  if (uiID ne 0) then oUI = OBJ_VALID(uiID, /CAST)

  ; Cache our UI object if it was passed in.
  if (ISA(oUI)) then begin
    oWindow->SetProperty, UI=oUI
  endif else begin
    oWindow->GetProperty, UI=oUI
    if (~ISA(oUI)) then $
      oWindow->_CreateTool
    oWindow->GetProperty, UI=oUI
  endelse

  if (ISA(oUI)) then begin
    oTool = oUI->GetTool()
    oTool->_SetCurrentWindow, oWindow
  
    ; Register ourself as a widget with the UI object.
    ; Returns a string containing our identifier.
    strObserverIdentifier = oUI->RegisterWidget(wDraw, 'ToolDraw')
  
    ; Start out with a 1x1 gridded layout.
    oWindow->SetProperty, LAYOUT_INDEX=1
  endif


  ; Call the user's NOTIFY_REALIZE, if it was provided.
  if (wNotifyRealize ne '') then begin
    CALL_PROCEDURE, wNotifyRealize, wDraw
  endif

end


;-------------------------------------------------------------------------
function widget_window, wParent, $
  FRAME=frame, $
  FUNC_GET_VALUE=swallow2, $
  NOTIFY_REALIZE=wNotifyRealize, $
  PRO_SET_VALUE=swallow3, $
  UI=oUI, $
  X_SCROLL_SIZE=xScrollIn, Y_SCROLL_SIZE=yScrollIn, $
  XSIZE=xsizeIn, YSIZE=ysizeIn, $
  _REF_EXTRA=_extra

  compile_opt idl2, hidden

  on_error, 2
  catch, iErr
  if (iErr ne 0) then begin
    catch, /cancel
    msg = !ERROR_STATE.MSG
    ; Replace mention of widget_draw with my own name.
    i = STRPOS(msg, 'WIDGET_DRAW')
    if (i ge 0) then $
      msg = STRMID(msg, 0, i) + 'WIDGET_WINDOW' + STRMID(msg, i+11)
    MESSAGE, msg, /NONAME
  endif

  if (ISA(wEventFunc)) then begin
    if (~ISA(wEventFunc, 'STRING')) then $
      MESSAGE, /NONAME, 'EVENT_FUNC must be a string.'
  endif else wEventFunc = ''

  if (ISA(wNotifyRealize)) then begin
    if (~ISA(wNotifyRealize, 'STRING')) then $
      MESSAGE, /NONAME, 'NOTIFY_REALIZE must be a string.'
  endif else wNotifyRealize = ''

  ; Retrieve the system object first - otherwise if we try to do this within
  ; the GraphicsWin::Init we get a crash on the Mac, because of the call
  ; to Get_ScreenSize within IDLitSystem::Init.
  void = _IDLitSys_GetSystem()
  
  xScroll = ISA(xScrollIn) ? xScrollIn[0] : (ISA(xsizeIn) ? xsizeIn[0] : 640)
  yScroll = ISA(yScrollIn) ? yScrollIn[0] : (ISA(ysizeIn) ? ysizeIn[0] : 512)
  xsize = ISA(xsizeIn) ? xsizeIn[0] : xScroll
  ysize = ISA(ysizeIn) ? ysizeIn[0] : yScroll

  appScroll = xScroll lt xsize || yScroll lt ysize

  isFrame = KEYWORD_SET(frame)
  if (isFrame) then begin
    xScroll += 2
    yScroll += 2
  endif

  if (~appScroll) then begin
    xScroll = !NULL
    yScroll = !NULL
  endif

  ;XXX This is awful, but we cannot use the UVALUE of the widget because
  ; the user might have set it. Instead, just shove it into the
  ; PRO_SET_VALUE field as a string.
  state = STRTRIM(OBJ_VALID(oUI, /GET_HEAP_ID),2) + ',' + wNotifyRealize

  ; Drawing area.
  wDraw = WIDGET_DRAW(wParent, $
      CLASSNAME='GraphicsWin', $  ; Component window
      FRAME=isFrame, $
      GRAPHICS_LEVEL=2, $         ; Object graphics
      NOTIFY_REALIZE='widget_window_realize', $
      APP_SCROLL=appScroll, $
      PRO_SET_VALUE=state, $
      X_SCROLL_SIZE=xScroll, Y_SCROLL_SIZE=yScroll, $
      SCR_XSIZE=xScroll, SCR_YSIZE=yScroll, $
      XSIZE=xsize, YSIZE=ysize, $
      _STRICT_EXTRA=_extra)

  return, wDraw

end
