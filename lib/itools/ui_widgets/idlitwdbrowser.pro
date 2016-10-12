; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwdbrowser.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IDLitwdBrowser
;
; PURPOSE:
;   This function implements the IT tree/property browser.
;
;   Note: This differs from the IDLitwdVizBrowser in that it doesn't
;         try to select the objects selected in the browser
;         tree. This simple widget just displays the items selected in
;         the property sheet, nothing else.
;
; CALLING SEQUENCE:
;   IDLitwdBrowser
;
; INPUTS:
;   oUI: (required) object reference for the tool user interface
;
; KEYWORD PARAMETERS:
;   GROUP_LEADER: widget ID of the group leader
;
;   TITLE: string title for the top level base
;
;   VALUE: object reference of the current selected item
;   IDENTIFIER: string identifier of the current selected item
;     Note: one of VALUE or IDENTIFIER must be supplied
;
;   TREETOP: string identifier of the position in the tool tree to be
;   the highest visible point in the tree browser
;
;   XSIZE: xsize of the two panes
;   YSIZE: ysize of the two panes
;
;   NAME: (required) string name of the browser
;
;   VISIBLE: initial visibility. 1-show left panel, 2-show right
;   panel, 3-show both panels (default)
;
;   MULTIPLE: allow multiple selections in the tree browser
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, April 2002
;   Modified to use CW_PANES browser templates:  AGEH, January 2003
;
;-


;---------------------------------------------------------------------------
; Purpose:
;   Used to get selection changed messages from the tool
;
PRO IDLitWdBrowser_CALLBACK, wTlb, strID, messageIn, userdata
    compile_opt idl2, hidden

    case STRUPCASE(messageIn) of
    'SELECTIONCHANGED': begin
        widget_control, wTlb, get_uvalue=state, /no_copy
        ;; If we have an old non standard lying around, unselect it
        if state.isVisBrowser then begin
            if(state.idSelNonVis ne '')then $
            cw_ittreeview_setSelect, state.wTree, state.idSelNonVis, /unselect
            state.idSelNonVis=''
        endif
        widget_control, wTlb, set_uvalue=state, /no_copy
    end
    'SENSITIVE': begin
        WIDGET_CONTROL, wTlb, SENSITIVE=userdata
    end
    else:  ; do nothing

    endcase
end


;----------------------------------------
;+
; NAME:
;   IDLITWDBROWSER_EVENT
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
PRO IDLITWDBROWSER_EVENT, event
  compile_opt idl2, hidden
  widget_control,event.top,get_uvalue=state
  CASE TAG_NAMES(event, /STRUCTURE_NAME) OF
    'WIDGET_BASE': BEGIN        ; Resize
      IF ~state.x THEN BEGIN
        infotop = widget_info(event.top,/geometry)
        widget_control,state.wStatus,scr_xsize=infotop.xsize-10
        state.x = infotop.xsize
        state.y = infotop.ysize
        widget_control,event.top,set_uvalue=state
        return
      ENDIF
      deltaX = ((newX=event.x>50)) - state.x
      deltaY = ((newY=event.y>50)) - state.y
      IF deltaX NE 0 THEN BEGIN
        widget_control,event.top,xsize=newX+1
        widget_control,event.top,xsize=((state.x=newX))
      ENDIF
      IF deltaY NE 0 THEN BEGIN
        widget_control,event.top,ysize=newY+1
        widget_control,event.top,ysize=((state.y=newY))
      ENDIF
      infotop = widget_info(event.top,/geometry)
      widget_control,state.wStatus,scr_xsize=infotop.xsize-10
      evstruct = {CW_PANES_RESIZE, ID:state.wBase, TOP:event.top, $
                  HANDLER:event.id, deltaX:deltaX, deltaY:deltaY}
      void = cw_panes_event(evstruct)
      widget_control,event.top,set_uvalue=state
    END
    'CW_PANES_TOP_RESIZE' : BEGIN
      IF ~(widget_info(event.top,/map)) THEN return
      info = widget_info(event.top,/geometry)
      IF event.deltaX NE 0 THEN BEGIN
        widget_control,event.top, $
                       xsize=((state.x=info.xsize+event.deltaX))
      ENDIF
      IF event.deltaY NE 0 THEN BEGIN
        widget_control,event.top, $
                       ysize=((state.y=info.ysize+event.deltaY))
      ENDIF
      infotop = widget_info(event.top,/geometry)
      widget_control,state.wStatus,scr_xsize=infotop.xsize-10
      widget_control,event.top,set_uvalue=state
    END

    ;; Event from the component_tree compound widget. Just set the id in
    ;; the property sheet
    'CW_ITCOMPONENT_TREE': $
        widget_control, state.wProp, set_value=event.identifier

    ;; Event from the treeview compound widget (Vis Browser only).
    'CW_TREE_SEL': begin
      oTool = state.oUI->GetTool()
      if (~OBJ_VALID(oTool)) then $
        break

      ; For optimization, prepare two lists:
      ;   1) items that are newly selected but were not previously.
      ;   2) items that are no longer selected but were previously.
      ;
      visSelected = oTool->GetSelectedItems(COUNT=nSelVis, /ALL)

      selStr = *event.value
      if ((selStr[0] ne '') || $
          (nSelVis gt 0)) then begin

          visStr = ['']
          if (OBJ_VALID(visSelected[0])) then begin
              for i=0,N_ELEMENTS(visSelected)-1 do begin
                  visStr = visStr[0] EQ '' ? $
                      visSelected[i]->GetFullIdentifier() : $
                      [visStr,visSelected[i]->GetFullIdentifier()]
              endfor
          endif
          for i=0,N_ELEMENTS(selStr)-1 do $
              if (WHERE(selStr[i] EQ visStr) EQ -1) then $
                  newSelIDs = N_ELEMENTS(newSelIDs) EQ 0 ? $
                      selStr[i] : [newSelIDs,selStr[i]]

          for i=0,N_ELEMENTS(visStr)-1 do $
              if (WHERE(visStr[i] EQ selStr) EQ -1) then $
                  deSelIDs = N_ELEMENTS(deSelIDs) EQ 0 ? $
                      visStr[i] : [deSelIDs,visStr[i]]
      endif


      ;; KDB 2/03
      ;; It may seem strange, but to minimize on data space
      ;; recalculations, selects should take place before
      ;; unselects. Due ot the nature of the selection model, the
      ;; data space will recalculate if the overall selection state of
      ;; it's children change (child selected to child not selected).
      ;;
      ;; So by deleting selections first and then enabling the new
      ;; selections, the child state of the data space changes.
      ;; But if you do selections first and the delesections, the data-
      ;; space state doesn't change. This can also minimize the amount
      ;; of drawing going on.
      IF strpos(state.name,'Visualization') NE -1 THEN BEGIN
          idNonVis='' ;; flag for any non vis related items (data, window)
          oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
          FOR i=0,n_elements(newSelIDs)-1 DO BEGIN
              oSelect = oTool->GetByIdentifier(newSelIDs[i])
              IF obj_valid(oSelect) THEN BEGIN
                  IF i EQ 0 THEN BEGIN  ;; update the status bar.
                      oSelect->getProperty,desc=desc
                      IF ~desc THEN desc='  '
                      widget_control,state.wStatus,set_value=desc
                  ENDIF
                  ;; Check for Data
                  if(obj_isa(oSelect, "IDLitData") or $
                     obj_isa(oSelect, "IDLitWindow"))then begin
                      idNonVis=newSelIDs[i]
                      break
                  endif else if (OBJ_ISA(oSelect, '_IDLitVisualization') or $
                                 obj_isa(oSelect, "IDLitgrView") or $
                                 obj_isa(oSelect, "IDLitgrLayer"))then begin
                      IF ~oSelect->IsSelected() THEN oSelect->Select,/additive
                  ENDIF
              endif
          ENDFOR

          ;; Now clear out items that are not selected any more.
          FOR i=0,n_elements(deSelIDs)-1 DO BEGIN
              oSelect = oTool->GetByIdentifier(deSelIDs[i])
              IF obj_valid(oSelect) THEN BEGIN
                  if(obj_isa(oSelect, "IDLitGrView"))then begin
                      ;; Force a view to deselect
                      oSelect->Select,/unselect
                  endif else if (OBJ_ISA(oSelect, '_IDLitVisualization') or $
                                 obj_isa(oSelect, "IDLitgrLayer"))then begin
                      IF oSelect->IsSelected() THEN oSelect->Select,/unselect
                  endif
              ENDIF
          ENDFOR
          IF (~previouslyDisabled) THEN $
            oTool->EnableUpdates

          ;; Was any data selected?
          if(keyword_set(idNonVis))then begin
              cw_itTreeView_SetSelect, state.wTree, idNonVis, /clear
              widget_control, state.wProp, set_value=idNonVis
          endif
          state.idSelNonVis = idNonVis
          ;; KDB: State should be in a pointer....
          widget_control,event.top,set_uvalue=state
      ENDIF
    END

    'WIDGET_BUTTON': begin      ; Close button
      WIDGET_CONTROL, event.id, GET_UVALUE=button
      case button of
        'Close': begin
          WIDGET_CONTROL, event.top, /DESTROY
          return
        end
        'Advanced': begin
          set = WIDGET_INFO(event.id, /button_set)
          WIDGET_CONTROL, state.wProp, hide_advanced_only=~set
          WIDGET_CONTROL, event.id, TOOLTIP=$
            (set ? IDLitLangCatQuery('UI:cwPropSheet:ShowSimple') : $
             IDLitLangCatQuery('UI:cwPropSheet:ShowAdvanced'))
        end
      endcase
    end
    'WIDGET_KILL_REQUEST' : BEGIN
        ;; We don't die, we hide
        widget_control, event.top, map=0
    END
    ELSE :
  ENDCASE
END
;----------------------------------------
;+
; NAME:
;   IDLITWDBROWSER_SET_EVENT
;
; PURPOSE:
;       Set the value of the browser
;
; INPUTS:
;       ID: (required) widget ID of the top level base
;
;       VALUE: (required) integer value to be set
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO IDLITWDBROWSER_SET_EVENT,id,value
  compile_opt hidden
  widget_control,id,get_uvalue=state
  widget_control,state.wBase,set_value=value
END
;----------------------------------------
;+
; NAME:
;   CREATETREE
;
; PURPOSE:
;       Put the cw_ittreeview in the left panel
;
; INPUTS:
;       BASE: (required) widget ID of the left base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO idlitwdbrowser_CREATETREE, base

    compile_opt idl2, hidden

    topid = base

    WHILE ((temp=widget_info(topid,/parent))) NE 0l DO topid=temp

    widget_control,topid,get_uvalue=state
    if (state.isVisBrowser) then begin
        state.wTree = CW_ITTREEVIEW(base,state.oUI, $
            multiple=state.multiple, $
            xsize=state.left_xsize,ysize=state.left_ysize, $
            IDENTIFIER=state.treetop,uname=state.name, $
            context_menu="ContextMenu/DrawContext")
    endif else begin
        oTool = state.oUI->GetTool()
        oRoot = oTool->GetByIdentifier(state.identifier)
        ;; Create a simple component tree widget
        state.wTree = cw_itcomponenttree(base, state.oUI, oRoot, $
            uname=state.name, $
            xsize=state.left_xsize,ysize=state.left_ysize)
    endelse

    widget_control,topid,set_uvalue=state
end


;----------------------------------------
;+
; NAME:
;   CREATEPROPSHEET
;
; PURPOSE:
;       Put the cw_itpropertysheet in the right panel
;
; INPUTS:
;       BASE: (required) widget ID of the left base
;
; KEYWORD PARAMETERS:
;       None
;
; OUTPUTS:
;       None
;-
PRO IDlitwdBrowser_CREATEPROPSHEET, base
  compile_opt idl2, hidden
  topid = base
  WHILE ((temp=widget_info(topid,/parent))) NE 0l DO topid=temp
  widget_control,topid,get_uvalue=state
  wBase = WIDGET_BASE(base, /COLUMN, /ALIGN_LEFT, XPAD=0)
  wRow = WIDGET_BASE(wBase, /ROW, /ALIGN_RIGHT, XPAD=4, YPAD=0, /NONEXCLUSIVE)
  wButton = WIDGET_BUTTON(wRow, $
              TOOLTIP=IDLitLangCatQuery('UI:cwPropSheet:ShowAdvanced'), $
              VALUE=FILEPATH('advanced.bmp', $
                             SUBDIRECTORY=['resource','bitmaps']), $
              /BITMAP, UVALUE='Advanced', /FLAT)
  geom = WIDGET_INFO(wBase, /GEOMETRY)              
  state.wProp = CW_ITPROPERTYSHEET(wBase, state.oUI, $
                                   scr_xsize=state.right_xsize, $
                                   scr_ysize=state.right_ysize-geom.scr_ysize, $
                                   type=state.type, $
                                   COMMIT=state.commit, $
                                   /STATUS, $
                                   /HIDE_ADVANCED_ONLY, $
                                   VALUE=state.Identifier)
  ; Copy pState to child of the incoming base                                   
  WIDGET_CONTROL, state.wProp, GET_UVALUE=pState
  WIDGET_CONTROL, wBase, SET_UVALUE=pState
  widget_control,topid,set_uvalue=state
END
;-------------------------------------------------------------------------
pro IDLitwdBrowser, oUI, $
                    GROUP_LEADER=groupLeader, $
                    TITLE=titleIn, $
                    VALUE=oTree, $
                    IDENTIFIER=identifier, $
                    TREETOP=treetop, $
                    XSIZE=xsizeIn, $
                    YSIZE=ysizeIn, $
                    NAME=name, $
                    VISIBLE=visible, $
                    MULTIPLE=multiple, $
                    COMMIT_PROPERTIES=COMMIT_PROPERTIES, $
                    VISUALIZATION=isVisBrowser

  compile_opt idl2, hidden
  ;; Check keywords.
  IF n_elements(NAME) EQ 0 THEN return
  IF n_elements(oTree) EQ 0 THEN oTree=obj_new()
  IF n_elements(identifier) EQ 0 THEN $
    IF obj_valid(oTree) THEN identifier=oTree->GetFullIdentifier()
  IF n_elements(identifier) EQ 0 THEN return

  isVisBrowser = KEYWORD_SET(isVisBrowser)

  if(n_elements(commit_properties) eq 0)then $
    commit_properties=1
  oTool = oUI->getTool()
  oTool->getProperty,name=toolname
  title = (N_ELEMENTS(titleIn) gt 0)? toolname+': '+titleIn[0] : $
    'IDL iTool Browser'
  hasLeader = (N_ELEMENTS(groupLeader) gt 0) ? $
    WIDGET_INFO(groupLeader, /VALID) : 0
  IF n_elements(visible) eq 0 THEN visible=3
  xsize = (N_ELEMENTS(xsizeIn) gt 0) ? xsizeIn[0] : 300
  ysize = (N_ELEMENTS(ysizeIn) gt 0) ? ysizeIn[0] : 300

  IF n_elements(treetop) EQ 0 THEN treetop=identifier[0] $
  ELSE treetop=((oTool->getbyidentifier(treetop)))->getfullidentifier()

  ;; Has this already been created?
  browsername = toolname+':'+name
  wID = oUI->GetWidgetByName(browserName)

  ;;if browser exists pull it to the front and return
  IF wID NE 0 THEN BEGIN
      WIDGET_CONTROL,wID,map=1,iconify=0,get_uvalue=state
      WIDGET_CONTROL, state.wTree, GET_VALUE=idSel
      WIDGET_CONTROL, state.wProp, GET_VALUE=idProp
        ; Make sure the property sheet contains what
        ; is selected in the tree.
      if (idSel[0] ne '') then begin
        if (idSel[0] ne idProp[0]) then $
            WIDGET_CONTROL, state.wProp, SET_VALUE=idSel[0]
      endif else begin
        ; Nothing selected in tree?
        WIDGET_CONTROL, state.wProp, SET_VALUE=identifier[0]
      endelse
      return
  endif

  myname = 'IDLitwdBrowser'
  state = {wBase: 0l, $
           wTree: 0l, $
           wProp: 0l, $
           wStatus: 0l, $
           oUI: oUI, $
           treeTop:treetop, $
           Identifier:identifier, $
           type:name, $
           commit:commit_properties, $ ;; commit mode on the propsheet
           left_xsize:xsize,left_ysize:ysize, $
           right_xsize:xsize,right_ysize:ysize, $
           multiple:keyword_set(multiple), $
           name:browsername,x:0l,y:0l, $
           idSelNonVis: '', $ ; a selected, non-vis item (data, window)
           isVisBrowser: isVisBrowser, $
           idSelf:''}
  ;; Create top level base
  tlb = widget_base(PRO_SET_VALUE=myname+'_set_event',/col,uvalue=state, $
                    /tlb_size_events, $
                    map=0, title=title, xpad=0, ypad=0, space=2, $
                    /tlb_kill_request_events, group_leader=groupLeader)
  widget_control,tlb,/realize
  ;; Create panes
  wBase = cw_panes(tlb, $
        left_xsize=xsize, $
        right_xsize=xsize,left_ysize=ysize, $
        right_ysize=ysize, $
        left_create_pro='idlitwdbrowser_createtree', $
        left_event_func=isVisBrowser ? $
            'cw_ittreeview_event' : 'cw_itComponentTree_event', $
        right_create_pro='idlitwdbrowser_createpropsheet', $
        right_event_func='cw_itpropertysheet_event', $
        top_event_PRO='idlitwdbrowser_event', $
        visible=visible)

  info = widget_info(tlb,/geometry)
  widget_control,tlb,get_uvalue=state
  state.wBase = wBase
  ;;create status bar
  state.wStatus = widget_label(tlb,/sunken_frame,xsize=info.xsize-4, $
                               value=' ',/align_left)
  ;;copy wStatus ID into state structure of cw_itpropertysheet
  widget_control,wBase,get_value=val
  widget_control,widget_info(val[2],/child),get_uvalue=pState
  (*pState).wStatus = state.wStatus

  ;;add browser to the UI
  state.idSelf=oUI->RegisterWidget(tlb, BrowserName, $
        "idlitwdbrowser_callback", $
        DESCRIPTION=Title, /floating)

  ; Want notifications to cleanup non-standard selections in the tree.
  if isvisBrowser then $
      oUI->AddOnNotifyObserver, state.idSelf, 'Visualization'

  ; Observe the system so that we can be desensitized when a macro is running
  oSys = oTool->_GetSystem()
  oUI->AddOnNotifyObserver, state.idSelf, oSys->GetFullIdentifier()

  widget_control,tlb,/map
  ;;draw slider bars and arrows
  CW_PANES_DRAW_SLIDER_BAR,tlb

  ;;cache tlb size
  info = widget_info(tlb,/geometry)
  state.x = info.xsize
  state.y = info.ysize
  widget_control,tlb,set_uvalue=state
  widget_control,tlb,/clear_events
  xmanager,'idlitwdbrowser',tlb,/no_block,event_handler=myname+'_event'
end

