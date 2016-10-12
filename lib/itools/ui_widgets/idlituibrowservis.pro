; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlituibrowservis.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitUIBrowserVis
;
; PURPOSE:
;   This function implements the user interface for the Vis Browser
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; CALLING SEQUENCE:
;   Result = IDLitUIBrowserVis(Requester [, UVALUE=uvalue])
;
; INPUTS:
;   Requester - Set this argument to the object reference for the caller.
;
; KEYWORD PARAMETERS:
;
;   UVALUE: User value data.
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-

;-------------------------------------------------------------------------
function IDLitUIBrowserVis, oUI, oRequester

  compile_opt idl2, hidden

  ;; Retrieve widget ID of top-level base.
  oUI->GetProperty, GROUP_LEADER=groupLeader

  oTool = oUI->GetTool()

    isEditProperties = OBJ_ISA(oRequester,'IDLITOPPROPERTYSHEET')

  ;; Check if this is currently active
  name = 'Visualization Browser'
  oTool->getProperty,name=toolname
  browsername = toolname+':'+name
  wID = oUI->GetWidgetByName(browserName)

  IF widget_info(wID,/valid_id) THEN BEGIN
      widget_control,wID, map=1, iconify=0, get_uvalue=state
      ;; Now just show the vis size of the browser
      ;; This is incorrect, because this routine is depending on a
      ;; structure of an underlying widget. kdb
      widget_control, state.wBase, get_value=value
      ; Be sure to show either the props or the tree.
      value = value[0] or (isEditProperties ? 2 : 1)
      widget_control, state.wBase, set_value=value
    return,1
  ENDIF

    ; If there is a selection, then change the browser view to it.
  oTarget = oTool->GetSelectedItems(count=nTarg)

    ; If nothing selected, default to the Layer.
  if nTarg eq 0 then begin
    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0
    oViewGroup = oWin->GetCurrentView()
    oTarget = OBJ_VALID(oViewGroup) ? $
      oViewGroup : oWin
  endif

  IDs = strarr(n_elements(oTarget))
  FOR i=0,n_elements(oTarget)-1 DO $
    IDs[i] = oTarget[i]->GetFullIdentifier()

  oRequester->GetProperty, TOP=oTop

  IDLitwdBrowser, oUI, $
                  GROUP_LEADER=groupLeader, $
                  NAME=name, $
                  TITLE=name, $
                  /MULTIPLE, $
                  /COMMIT_PROPERTIES, $
                  /VISUALIZATION, $
                  TREETOP='WINDOW', $
                  VALUE=oTop, $
                  IDENTIFIER=IDs, $
                  VISIBLE=isEditProperties ? 2 : 1

    ; Notify our observers that selection has changed.
  oTool->DoOnNotify,'Visualization','Selected',IDs

  return, 1

end

