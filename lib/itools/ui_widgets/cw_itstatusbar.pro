; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itstatusbar.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   cw_itStatusBar
;
; PURPOSE:
;   This function implements the status bar compound widget for the
;   IT window.
;
; CALLING SEQUENCE:
;   Result = CW_ITSTATUS(Parent, ToolUI)
;
; INPUTS:
;   Parent: Set this argument to the widget ID of the parent base.
;
;   ToolUI: The UI Object for the tool
;
; KEYWORD PARAMETERS:
;   XSIZE: Width of the widget.
;
;
; MODIFICATION HISTORY:
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro cw_itstatusbar_callback, wID, strID, messageIn, userdata

    compile_opt idl2, hidden

    if (~WIDGET_INFO(wID, /VALID)) then $
        return

    value = (STRLEN(userdata) gt 0) ? userdata : ' '

    case messageIn of

        'MESSAGE': begin
            WIDGET_CONTROL, wId, GET_VALUE=oldvalue
            if (oldvalue ne value) then $
                WIDGET_CONTROL, wId, SET_VALUE=value
            end

        else:
    endcase

end


;-------------------------------------------------------------------------
; cw_idStatusBar_Resize
;
; Purpose:
;   Called to resize the status bar. Only the xSize
;   is resized.
;
; Parameters
;   wStatus    - The widget id of this widget
;
;   xSize      - The new xsize
;
pro cw_itStatusBar_Resize, wStatus, xSize

    compile_opt idl2, hidden

    stash = WIDGET_INFO(wStatus, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=sState

    ; Compute size of status bar segment minus frame widths and
    ; spacing between segments.
    xsize1 = xsize - sState.padding

    ; Resize each status bar segment.
    for i=0,N_ELEMENTS(sState.segIds)-1 do begin
        wID = WIDGET_INFO(wStatus, FIND_BY_UNAME=sState.segIds[i])
        if (~WIDGET_INFO(wID, /VALID)) then $
            continue
        WIDGET_CONTROL, wID, GET_UVALUE=normalized_width
        WIDGET_CONTROL, wID, XSIZE=(xsize1*normalized_width)
    endfor

end


;-------------------------------------------------------------------------
function CW_itStatusBar, Parent, oUI, $
    XSIZE=xsize, $
    _REF_EXTRA=_extra


  compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

  oTool = oUI->GetTool()

  ; Retrieve the status bar segments registered with the tool.
  oSegments = oTool->GetStatusBarSegments(COUNT=nSegments)
  if (nSegments eq 0) then $
      MESSAGE, IDLitLangCatQuery('UI:cwStatusBar:NoBar')

  ; Create the base.
  wBase = WIDGET_BASE(Parent, /COLUMN, $
      XPAD=0, SPACE=2, YPAD=2, _EXTRA=_extra)

  ; Basically this is a base that then contains several
  ; label widgets.
  wRow = Widget_Base(wBase, /row, xpad=0, ypad=0)

  ; Calculate some geometry info up front so that it can
  ; be used for proper sizing.
  wDummyRow = WIDGET_BASE(wBase, /ROW, XPAD=0, MAP=0)
  geom = WIDGET_INFO(wDummyRow, /GEOMETRY)
  space = geom.space
  ; Create a dummy label so that the size of the margins
  ; can be computed.
  wDummyLbl = WIDGET_LABEL(wDummyRow, /SUNKEN_FRAME, /ALIGN_LEFT, $
      XSIZE=10, VALUE=' ' )
  geom = WIDGET_INFO(wDummyLbl, /GEOMETRY)
  frameWidth = geom.margin
  WIDGET_CONTROL, wDummyRow, /DESTROY

  ; Compute the amount of un-usable padding (including the frame around
  ; each segment plus the space between segments).
  padding = (nSegments*(2*frameWidth)) + ((nSegments-1)*space)

  ; Compute the amount of usable space for segments.
  xsize1 = ((N_ELEMENTS(xsize) eq 1) ? xsize : 640) - padding

  for i=0,nSegments-1 do begin
      oSegments[i]->GetProperty, NORMALIZED_WIDTH=normalized_width
      segId = oSegments[i]->GetFullIdentifier()
      wLabel = WIDGET_LABEL(wRow, /SUNKEN_FRAME, /ALIGN_LEFT, $
          XSIZE=xsize1*normalized_width, VALUE=' ', $
          UNAME=segId, UVALUE=normalized_width)

      ; Register for notification messages.
      idUIadaptor = oUI->RegisterToolBar(wLabel, segId, $
         'cw_itstatusbar_callback')
      oUI->AddOnNotifyObserver, idUIadaptor, segId
      segIds = (i gt 0) ? [segIds, segId] : segId
  endfor

  ; Stash our state
  sState = { $
      segIds: segIds,   $
      padding: padding  $   ; Number of pixels of un-usable padding
  }


  WIDGET_CONTROL, Widget_Info(wBase,/child), SET_UVALUE=sState, /NO_COPY

  return, wBase

end

