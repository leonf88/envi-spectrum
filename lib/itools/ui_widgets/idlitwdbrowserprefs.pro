; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdbrowserprefs.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdBrowserPrefs
;
; PURPOSE:
;   This function implements the IT tree/property browser for preferences.
;
; CALLING SEQUENCE:
;   IDLitwdBrowserPrefs
;
; INPUTS:
;   oUI: (required) object reference for the tool user interface
;
; KEYWORD PARAMETERS:
;   GROUP_LEADER: widget ID of the group leader
;
;   TITLE: string title for the top level base
;
;   IDENTIFIER: string identifier of the tree
;
;   NAME: (required) string name of the browser
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, April 2002
;   Modified to use CW_PANES browser templates:  AGEH, January 2003
;   Modified: CT, RSI, May 2004: Removed CW_PANES because we are modal.
;
;-
;----------------------------------------
;+
; NAME:
;   IDLitwdBrowserPrefs_EVENT
;
; PURPOSE:
;       Event handler for the browser
;
; INPUTS:
;   EVENT: (required) a widget_event structure
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO IDLitwdBrowserPrefs_EVENT, event

    compile_opt idl2, hidden

    widget_control,event.top, GET_UVALUE=state

    CASE TAG_NAMES(event, /STRUCTURE_NAME) OF

    ; Needed to prevent flashing on Windows.
    'WIDGET_KILL_REQUEST': WIDGET_CONTROL, event.top, /DESTROY

    ; Event from the treeview compound widget. Just set the id in
    ; the property sheet
    'CW_ITCOMPONENT_TREE': begin
        widget_control, state.wProp, set_value=event.identifier
        end

    'WIDGET_BUTTON': begin      ; Close button
      WIDGET_CONTROL, event.id, GET_UVALUE=button
      oSys = state.oUI->GetTool()
      if (~OBJ_VALID(oSys)) then $
        break

      case button of

          'OK': begin
              WIDGET_CONTROL, event.top, /DESTROY
              oSys->_SaveSettings
            end

          'Cancel': begin
              WIDGET_CONTROL, event.top, /DESTROY
              void = oSys->_RestoreSettings()
            end

          'Help': begin
                oHelp = oSys->GetService('HELP')
                if (OBJ_VALID(oHelp)) then $
                    oHelp->HelpTopic, oSys, 'idlitgeneralsettings'
            end

          'Reset': begin
              oSys->_ResetSettings
              oRoot = oSys->GetByIdentifier(state.identifier)
              widget_control, state.wTree, get_value=idSel
              cw_itComponentTree_SetRoot, state.wTree, oRoot
              widget_control, state.wTree, set_value=idSel
              ; we need to reset the prop sheet to root so that it
              ; will update
              widget_control, state.wProp, set_value='/'
              widget_control, state.wProp, set_value=idSel
          end

      endcase

    end

    else:

    endcase

end


;-------------------------------------------------------------------------
pro IDLitwdBrowserPrefs, oUI, $
                    GROUP_LEADER=groupLeader, $
                    TITLE=titleIn, $
                    IDENTIFIER=identifier, $
                    NAME=name, $
                    _REF_EXTRA=_extra

    compile_opt idl2, hidden

  ; Check keywords.
  IF n_elements(NAME) EQ 0 THEN return

  IF n_elements(identifier) EQ 0 THEN return

  title = (N_ELEMENTS(titleIn) gt 0)? titleIn[0] : $
    IDLitLangCatQuery('UI:wdBrowsPref:Title')
  hasLeader = (N_ELEMENTS(groupLeader) gt 0) ? $
    WIDGET_INFO(groupLeader, /VALID) : 0
  if (~hasLeader) then $
    groupLeader = WIDGET_BASE(MAP=0)

  width = 600
  xsize = 250
  ysize = 300

    oSys = oUI->GetTool()

    ; Create top level base
    wBase = widget_base(/COLUMN, $
        /TLB_KILL_REQUEST_EVENTS, $
        TITLE=title, $
        XPAD=0, YPAD=0, SPACE=2, $
        GROUP_LEADER=groupLeader, $
        /MODAL)


    ; Create panes
    wRow = WIDGET_BASE(wBase, /ROW)
    oRoot = oSys->GetByIdentifier(identifier)
    wTree = CW_ITCOMPONENTTREE(wRow, oUI, oRoot, $
        uname=title, $
        xsize=xsize,ysize=ysize)

    wProp = CW_ITPROPERTYSHEET(wRow, oUI, $
        scr_xsize=width-xsize, $
        scr_ysize=ysize, $
        type=name, $
        /STATUS, $
        /SUNKEN_FRAME, $
        VALUE=Identifier)

    wReset = WIDGET_BASE(wBase, COLUMN=2, /GRID, SCR_XSIZE=width)
    wLeft = WIDGET_BASE(wReset, /ROW, /ALIGN_LEFT, SPACE=5)
    wButton = WIDGET_BUTTON(wLeft, value= $
                            IDLitLangCatQuery('UI:wdBrowsPref:RestDef'), $
                            uvalue='Reset')
    wRight = WIDGET_BASE(wReset, /ROW, /ALIGN_RIGHT, /GRID, SPACE=5)
    wButton = WIDGET_BUTTON(wRight, value= $
                            IDLitLangCatQuery('UI:wdBrowsPref:OK'), $
                            uvalue='OK')
    wButton = WIDGET_BUTTON(wRight, value= $
                            IDLitLangCatQuery('UI:wdBrowsPref:Cancel'), $
                            uvalue='Cancel')
    wButton = WIDGET_BUTTON(wRight, value= $
                            IDLitLangCatQuery('UI:wdBrowsPref:Help'), $
                            uvalue='Help')

    oSys->_SaveSettings

    state = { $
        oUI: oUI, $
        wTree: wTree, $
        wProp: wProp, $
        Identifier:identifier}
    WIDGET_CONTROL,wBase, SET_UVALUE=state

    initial = '/REGISTRY/SETTINGS/GENERAL_SETTINGS'
    widget_control, state.wTree, set_value=initial
    widget_control, state.wProp, set_value=initial

    WIDGET_CONTROL,wBase, /REALIZE
    XMANAGER, 'IDLitwdBrowserPrefs', wBase

    if (~hasLeader) then $
        WIDGET_CONTROL, groupLeader, /DESTROY

end

