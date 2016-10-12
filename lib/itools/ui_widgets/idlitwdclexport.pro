; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdclexport.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdCLExport
;
; PURPOSE:
;   Curve fitting dialog.
;
; CALLING SEQUENCE:
;   Result = IDLitwdCLExport()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, January 2003
;   Modified:
;
;-

;-------------------------------------------------------------------------
;toggles checkboxes, toggles the appropriate export variable, and
;toggles the editable state of the corresponding text widget
;
pro IDLitwdCLExport_checkbox, event
  compile_opt idl2, hidden

  widget_control,event.top,get_uvalue=state
  wh = where((*state).export EQ event.id)
  widget_control,(*state).output[wh],editable=(((*state).checked[wh] XOR= 1))
  void = widget_event(/nowait)

end

;-------------------------------------------------------------------------
;ensures that the name entered is a valid IDL variable name
;
pro IDLitwdCLExport_outname, event
  compile_opt idl2, hidden

  if TAG_NAMES(event,/STRUCTURE_NAME) EQ 'WIDGET_KBRD_FOCUS' THEN BEGIN
    widget_control,event.id,get_value=varName
    widget_control,event.id,set_value=IDL_ValidName(varName,/convert_all)
  ENDIF

end

;-------------------------------------------------------------------------
;creates a structure of data and variable names from the checked menu
;items
;
pro IDLitwdCLExport_ok, event
  compile_opt idl2, hidden

  widget_control,event.top,get_uvalue=state
  ok = where((*state).checked EQ 1)

  IF ok[0] ne -1 THEN BEGIN
    FOR i=0,n_elements(ok)-1 DO BEGIN
      widget_control,(*state).output[ok[i]],get_value=varName
      dataTmp = {variableName:varName[0], $
                 oData:(*(*state).dataIn)[ok[i]].oData}
      *(*state).result = (i EQ 0 ? dataTmp : [*(*state).result,dataTmp])
    ENDFOR
  ENDIF

  WIDGET_CONTROL, event.top, /DESTROY

end

;-------------------------------------------------------------------------
;clear results
;
pro IDLitwdCLExport_cancel, event
  compile_opt idl2, hidden

  WIDGET_CONTROL, event.top, /DESTROY

end

;-------------------------------------------------------------------------
;
pro IDLitwdCLExport_event, event
  compile_opt idl2, hidden

  case TAG_NAMES(event, /STRUCTURE_NAME) of
    'WIDGET_KILL_REQUEST': begin
      WIDGET_CONTROL, event.top, /DESTROY
    end
    else:
  endcase

end

;-------------------------------------------------------------------------
;
function IDLitwdCLExport, Data=Data, $
                          GROUP_LEADER=groupLeaderIn, $
                          TITLE=titleIn, $
                          _REF_EXTRA=_extra

  compile_opt idl2, hidden

  DataIn = Data

  myname = 'IDLitwdCLExport'

  ;; Default title.
  title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
    IDLitLangCatQuery('UI:wdCLExport:Title')

  ;; Is there a group leader, or do we create our own?
  groupLeader = (N_ELEMENTS(groupLeaderIn) gt 0) ? groupLeaderIn : 0L
  hasLeader =  WIDGET_INFO(groupLeader, /VALID)

    nData = n_elements(DataIn)
  state = {label:lonarr(nData),export:lonarr(nData), $
           output:lonarr(nData),checked:intarr(nData)+1, $
           result:ptr_new(/allocate_heap), $
           dataIn:ptr_new(dataIn)}

  ;; Create our floating base.
  wBaseMain = WIDGET_BASE( $
        /COLUMN, $
        FLOATING=hasLeader, $
        GROUP_LEADER=groupLeader, $
        MODAL=hasLeader, $
        EVENT_PRO=myname+'_event', $
        /TLB_KILL_REQUEST_EVENTS, $
        SPACE=5, $
        XPAD=5, YPAD=5, $
        TITLE=title, $
        TLB_FRAME_ATTR=1, $
        _EXTRA=_extra)

  wBL = widget_base(wBaseMain, /row, /align_left, $
        space=1, xpad=0, ypad=0)
  wT1 =widget_label(wBL, value=IDLitLangCatQuery('UI:wdCLExport:Param'))
  wT2 =widget_label(wBL, value=IDLitLangCatQuery('UI:wdCLExport:VarName'))

  ;; a base with optional scrollbars. Just hardcode some values
  wBase = widget_base(wBaseMain,x_scroll_size=400, $
                      y_scroll_size=400 < (25*nData+150),/column, $
        space=1, xpad=0, ypad=0)

  ;;Add in one line for each data element
  FOR i=0,nData-1 DO BEGIN
    base = widget_base(wBase,/row,/align_left, $
        space=1, xpad=0, ypad=0)
    subbase = widget_base(base,/nonexclusive, /align_left, $
        space=1, xpad=0, ypad=0)
    state.export[i] = widget_button(subbase,value= $
                                   dataIn[i].strParamName, $
                                    /align_left, $
                                    event_PRO=myname+'_checkbox')
    widget_control, state.export[i], /set_button
    state.output[i] = $
      widget_text(base,xsize=20, $
        value=IDL_ValidName(dataIn[i].strName,/convert_all), $
                  /editable,event_PRO=myname+'_outname',/kbrd_focus_events)
  ENDFOR

  ;;OK and Cancel buttons
  wButtonBase = widget_base(wBaseMain, /ALIGN_RIGHT, /GRID, /ROW, SPACE=5)
  wOk = WIDGET_BUTTON(wButtonBase, $
                      EVENT_PRO=myname+'_ok', $
                      VALUE=IDLitLangCatQuery('UI:wdCLExport:Export'))
  wCancel = WIDGET_BUTTON(wButtonBase, $
                          EVENT_PRO=myname+'_cancel', $
                          VALUE=IDLitLangCatQuery('UI:wdCLExport:Cancel'))

  sGeom = widget_info(wBase, /geometry)
  widget_control, wT1, scr_xsize=sGeom.scr_xsize/2
  for i=0, nData-1 do $
      widget_control, state.export[i], scr_xsize=sGeom.scr_xsize/2
  ;; Realize the widget.
  pState = ptr_new(state)
  WIDGET_CONTROL, wBaseMain, /REALIZE, set_uvalue=pState

  widget_control, wBaseMain, cancel_button=wCancel

  ;; Fire up the xmanager.
  XMANAGER, myname, wBaseMain, $
            NO_BLOCK=0, EVENT_HANDLER=myname+'_event'

  ;; See if we got any results.
  result = ~(N_ELEMENTS(*state.result)) ? 0 : *state.result
  PTR_FREE, [state.result, state.dataIn, pState]

  return, result

end

