; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/idlitwddatamanager.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;-

;;---------------------------------------------------------------------------
;; IDLitwdDataManager_callback
;;
;; Purpose:
;;   callback routine
;;
PRO IDLitwdDataManager_callback, wTLB, strID, message, component
  compile_opt idl2, hidden

  ;; get state
  widget_control,wTLB,get_uvalue=pState

  ;; if the widget is unmapped do not bother with updates
  IF ~(*pState).isVisible THEN return

  CASE message OF
    'SELECTIONCHANGED' : BEGIN
      ;; get system
      oSys = (*pState).oUI->GetTool()
      ;; stop observing current object
      oSys->RemoveOnNotifyObserver,(*pState).idSelf,(*pState).idValue
      ;; if we are in parameter editor mode, get new selection and
      ;; pass it to the parameter table widget
      IF (*pState).isParmEdit THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; get selected item
        oItem = oSys->GetByIdentifier(component[0])
        ;; update parm table with current item
        cw_itParameterPropertysheet_SetValue,wParm,oItem
        ;; desensitize Apply button
        widget_control,(*pState).wDoAction,sensitive=0
        ;; observe current object
        oSys->AddOnNotifyObserver,(*pState).idSelf,component[0]
      ENDIF
      IF (*pState).isInsVis THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; ensure that all selected data does indeed exist
        cw_itParameterPropertysheet_UpdateSensitivity,wID=wParm,/PARAMS_EXIST
        ;; set sensitivity of Insert button
        widget_control, (*pState).wDoAction, sensitive= $
                        cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
      ENDIF
    END

    'SETPROPERTY' : BEGIN
      IF ((*pState).isParmEdit || (*pState).isInsVis) THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        IF (component EQ 'NAME') THEN BEGIN
          ;; update the names of all the data items in the propertysheet
          cw_itParameterPropertysheet_UpdateSensitivity,wID=wParm,/PARAM_DATA
        ENDIF ELSE BEGIN
          ;; get system
          oSys = (*pState).oUI->GetTool()
          ;; get selected item
          oItem = oSys->GetByIdentifier(strid)
          ;; update parm table with current item
          IF obj_isa(oItem,'IDLitParameter') THEN $
            cw_itParameterPropertysheet_SetValue,wParm,oItem
        ENDELSE
      ENDIF
      IF (*pState).isParmEdit THEN BEGIN
        ;; desensitize Apply button
        widget_control,(*pState).wDoAction,sensitive=0
      ENDIF
      IF (*pState).isInsVis THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; ensure that all selected data does indeed exist
        cw_itParameterPropertysheet_UpdateSensitivity,wID=wParm,/PARAMS_EXIST
        ;; set sensitivity of Insert button
        widget_control, (*pState).wDoAction, sensitive= $
                        cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
      ENDIF
    END

    'FOCUS_GAIN' : BEGIN
      ;; get system
      oSys = (*pState).oUI->GetTool()
      ;; a different tool was selected
      IF (*pState).isParmEdit THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; get current item from DM and update table
        widget_control,(*pState).wDM,get_value=oItem
        cw_itParameterPropertysheet_SetDataSelect,wParm,oItem
        ;; get current tool
        oTool = oSys->_GetCurrentTool()
        ;; get current selected item
        oItem = (oTool->GetSelectedItems())[0]
        ;; update table
        cw_itParameterPropertysheet_SetValue,wParm,oItem
        ;; desensitize Apply button
        widget_control,(*pState).wDoAction,sensitive=0
        ;; observe current object
        IF obj_valid(oItem) THEN $
          oSys->AddOnNotifyObserver,(*pState).idSelf,oItem->GetFullIdentifier()
      ENDIF
    END

    'FOCUS_LOSS' : BEGIN
      ;; get system
      oSys = (*pState).oUI->GetTool()
      ;; stop observing current object
      oSys->RemoveOnNotifyObserver,(*pState).idSelf,(*pState).idValue
      ;; clear parm edit table
      IF (*pState).isParmEdit THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; clear table
        cw_itParameterPropertysheet_SetValue,wParm,0
        cw_itParameterPropertysheet_SetDataSelect,wParm,0
        ;; desensitize Apply button
        widget_control,(*pState).wDoAction,sensitive=0
      ENDIF
      IF (*pState).isInsVis THEN BEGIN
        ;; get parm table
        wParm = widget_info((*pState).wParamEditBase,/child)
        ;; get current item from DM and update table
        widget_control,(*pState).wDM,get_value=oItem
        cw_itParameterPropertysheet_SetDataSelect,wParm,oItem
        ;; ensure that all selected data does indeed exist
        cw_itParameterPropertysheet_UpdateSensitivity, $
          wID=wParm,/REMOVE,/PARAMS_EXIST
        ;; set sensitivity of Insert button
        widget_control, (*pState).wDoAction, sensitive= $
                        cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
      ENDIF
    END
    ; The sensitivity is to be changed
    'SENSITIVE': begin
        WIDGET_CONTROL, (*pState).wTLB, SENSITIVE=component
    end
    ELSE :

  ENDCASE

END

;;-------------------------------------------------------------------------
;; IDLitwdDataManager_SetWidget
;;
;; Purpose:
;;   Sets or destroys the subwidgets needed for the parameter editor
;;   and the insert visualization dialogs.
;;
;; Parameter:
;;   sEvent  - The widget event.
;;
pro IDLitwdDataManager_SetWidget,wID, $
                                 PARAMETER_EDITOR=parametereditor, $
                                 INSERT_VISUALIZATION=insertvisualization, $
                                 TITLE=title, $
                                 VALUE=oValue, REQUESTOR=oRequestor
  compile_opt idl2, hidden

  on_error, 2

  ;; get state
  widget_control,wID,get_uvalue=pState

  ;; turn off updates
  widget_control,wID,update=0

  ;; save requesting operation
  IF n_elements(oRequestor) THEN (*pState).oRequestor = oRequestor

  (*pState).isInsVis = keyword_set(insertvisualization)
  (*pState).isParmEdit = keyword_set(parametereditor) && ~(*pState).isInsVis
  (*pState).isVisible = 1b
  ;; observe visualizations for selection changes
  (*pState).oUI->AddOnNotifyObserver, (*pState).idSelf, 'Visualization'

  ;; get parameter and ins vis widgets
  wParm = widget_info((*pState).wParamEditBase,/child)

  IF keyword_set(insertvisualization) || $
    keyword_set(parametereditor) THEN BEGIN
    IF ~widget_info(wParm,/valid_id) THEN begin
      wParm = cw_itParameterPropertySheet((*pState).wParamEditBase, $
                                          (*pState).oUI, $
                                          value=oValue, $
                                          L_XSIZE=(*pState).l_xsize, $
                                          R_XSIZE=(*pState).r_xsize, $
                                          YSIZE=(*pState).b_ysize, $
                                          INSERT_VISUALIZATION= $
                                          insertvisualization)
      widgetAdded = 1b
    endif

    ;; let table know which data item is current selected
    oSys = (*pState).oUI->GetTool()
    oItem = oSys->GetByIdentifier((*pState).itemID)
    cw_itParameterPropertysheet_setDataSelect,wParm,oItem

    IF (*pState).isParmEdit THEN BEGIN
      ;; observe current item
      (*pState).idValue = oValue->GetFullIdentifier()
      (*pState).oUI->AddOnNotifyObserver, (*pState).idSelf, (*pState).idValue
    ENDIF

    ;; update table with current value
    cw_itParameterPropertySheet_SetValue,wParm,oValue, $
                                         PARAMETER_EDITOR=parametereditor, $
                                         INSERT_VISUALIZATION= $
                                         insertvisualization

    ;; if title was specified, save it for future use
    IF (keyword_set(TITLE)) THEN BEGIN
      CASE 1 OF
        keyword_set(parametereditor) : (*pState).PEtitle = title
        keyword_set(insertvisualization) : (*pState).IVtitle = title
        ELSE : (*pState).DMtitle = title
      ENDCASE
    ENDIF

    ;; use appropriate title
    CASE 1 OF
      keyword_set(title) : title=title
      keyword_set(parametereditor) : title=(*pState).PEtitle
      keyword_set(insertvisualization) : title=(*pState).IVtitle
      ELSE : title=(*pState).DMtitle
    ENDCASE
    widget_control,wID,base_set_title=title

    ;; set value of DOACTION button
    ;; desensitise button because nothing has yet changed
    IF keyword_set(parametereditor) THEN BEGIN
      widget_control,(*pState).wDoAction,/map,set_value=(*pState).apply, $
                     set_uname='APPLY',sensitive=0
      widget_control,(*pState).wCancel,set_value=(*pState).dismiss
    ENDIF ELSE BEGIN
      widget_control,(*pState).wDoAction,/map,set_value=(*pState).ok, $
                     set_uname='INSERT',sensitive=0
      widget_control,(*pState).wCancel,set_value=(*pState).cancel
    ENDELSE

    ;; If Insert Vis or Param Editor was added to previous small DM
    ;; then the new widget will be bigger than the old one, the lower
    ;; portion could potentially now be off the screen.  Check size
    ;; and postion of widget and adjust if needed.
    if (N_Elements(widgetAdded) ne 0) then begin
      ;; Get current widget information
      Widget_Control, wID, TLB_GET_OFFSET=tlbOffset, TLB_GET_SIZE=tlbSize
      tlb_xoffset = tlbOffset[0]
      tlb_yoffset = tlbOffset[1]
      ;; Account for differences between Windows and UNIX offset
      ;; reporting
      geo = Widget_Info(wID, /GEOMETRY)
      ydiff = geo.scr_ysize - geo.ysize - ((geo.scr_xsize-geo.xsize)/2) - $
              geo.space > 0
      tlbSize[1] += ydiff
      ;; Get monitor information
      oMon = Obj_New('IDLsysMonitorInfo')
      nMons = oMon->GetNumberOfMonitors()
      rects = oMon->GetRectangles(/EXCLUDE_TASKBAR)
      primary = oMon->GetPrimaryMonitorIndex()
      obj_destroy, oMon
      ;; Create arrays of minimum and maximum positions for each monitor
      xmins = rects[0,*]
      xmaxs = rects[0,*]+rects[2,*]
      ymins = rects[1,*]
      ymaxs = rects[1,*]+rects[3,*]
      ;; Determine possible monitors based on horizontal position
      xpos = Bytarr(nMons)
      wh = Where((tlb_xoffset ge xmins) and (tlb_xoffset lt xmaxs))
      if (wh[0] eq -1) then begin
        xpos[primary] ++
      endif else begin
        xpos[wh]++
      endelse
      ;; Determine possible monitors based on vertical position
      ypos = Bytarr(nMons)
      wh = Where((tlb_yoffset ge ymins) and (tlb_yoffset lt ymaxs))
      if (wh[0] eq -1) then begin
        ypos[primary]++
      endif else begin
        ypos[wh]++
      endelse
      ;; Determine which monitor contains the button
      monitor = Where(xpos and ypos)
      if ((monitor[0] eq -1) || (n_elements(monitor) ne 1)) then $
        monitor = primary
      ;; Change size, if needed, to ensure entire widget fits on the
      ;; screen.  Changing widget only changes the height of the
      ;; widget.
      if (tlbSize[1] gt (rects[3,monitor] - rects[1,monitor])) then begin
        ;; Calculate how much we need to shrink DM widgets
        dec = tlbSize[1] - rects[3,monitor] + 10

        ;; Get current size
        geo = Widget_Info((*pState).wDM, /GEOMETRY)
        ;; Calculate new y sizes
        newY = (geo.scr_ysize - dec) > (*pState).minY
        ;; Datamanager
        cw_itdatamanager_resize, (*pState).wDM, geo.scr_xsize, newY
        ;; Propertysheet
        Widget_Control, (*pState).wProp, SCR_YSIZE=newY
        
      endif

      ;; Change offsets, if needed, to ensure entire widget is on
      ;; the screen
      tlb_xoffset <= (xmaxs[monitor]-tlbSize[0]) > 0
      tlb_yoffset <= (ymaxs[monitor]-tlbSize[1]) > 0
      

      Widget_Control, wID, TLB_SET_XOFFSET=tlb_xoffset, $
                      TLB_SET_YOFFSET=(tlb_yoffset-15 > ymins[monitor])
      
    endif

  ENDIF ELSE BEGIN
    ;; destroy parameter table and insert vis droplist
    IF widget_info(wParm,/valid_id) THEN BEGIN
      widget_control,wParm,/destroy
    ENDIF
    ;; reset title and buttons
    widget_control,wID,base_set_title=(keyword_set(title) ? $
                                       title : (*pState).DMtitle)
    widget_control,(*pState).wDoAction,map=0,set_uname='DOACTION'
    widget_control,(*pState).wCancel,set_value=(*pState).dismiss
  ENDELSE

  widget_control,wID,update=1

  ;; Cache new TLB size
  Widget_Control, (*pState).wTLB, TLB_GET_SIZE=basesize
  (*pState).basesize = basesize

END

;;---------------------------------------------------------------------------
;; IDLitwdDataManager_Kill
;;
;; Purpose:
;;   Cleanup routine
;;
pro IDLitwdDataManager_CLEANUP, wWidget
  compile_opt idl2, hidden

  widget_control, wWidget, get_uvalue=pState

  (*pState).oUI->UnregisterWidget, (*pState).idSelf

  ptr_Free, pState

end

;;-------------------------------------------------------------------------
;; IDLitwdDataManager_EVENT
;;
;; Purpose:
;;   Event handler for the data manager browser.  It also handles the
;;   events that percolate up from the cw_itparameterpropertysheet.
;;
;; Parameter:
;;   sEvent  - The widget event.
;;
PRO  IDLitwdDataManager_EVENT, sEvent
  compile_opt idl2, hidden

@idlit_catch
  IF (iErr ne 0) THEN BEGIN
    catch, /cancel
    return
  ENDIF
  widget_control, sEvent.top, get_uvalue=pState
  message = widget_info(sEvent.id, /uname)

  wParm = widget_info((*pState).wParamEditBase,/child)

  CASE message OF

    'TLB': begin
      if (Tag_Names(sEvent, /STRUCTURE_NAME) eq $
          "WIDGET_KILL_REQUEST") then begin
        Widget_Control, sEvent.top, MAP=0
        (*pState).isVisible = 0b
      endif
      if (Tag_Names(sEvent, /STRUCTURE_NAME) eq "WIDGET_BASE") then begin
        ;; Resize events

        ;; Compute the size change of the base relative to its stored
        ;; former size.
        Widget_Control, sEvent.top, TLB_GET_SIZE=newSize
        deltaW = newSize[0] - (*pState).basesize[0]
        deltaH = newSize[1] - (*pState).basesize[1]

        ;; Bail if no change.
        if ((deltaW eq 0) && (deltaH eq 0)) then $
            break
        leftDeltaW = Ceil(deltaW/2.0)
        rightDeltaW = deltaW/2

        ;; Datamanager
        ;; Get current size
        geo = Widget_Info((*pState).wDM, /GEOMETRY)
        ;; Calculate new x and y sizes
        newXleft = (geo.scr_xsize + leftDeltaW) > (*pState).minX
        newY = (geo.scr_ysize + deltaH) > (*pState).minY
        cw_itdatamanager_resize, (*pState).wDM, newXleft, newY

        ;; Propertysheet
        ;; Get current size
        geo = Widget_Info((*pState).wProp, /GEOMETRY)
        ;; Calculate new x and y sizes
        newXright = (geo.scr_xsize + rightDeltaW) > (*pState).minX
        Widget_Control, (*pState).wProp, SCR_XSIZE=newXright, SCR_YSIZE=newY

        ;; Status bar
        geo = Widget_Info((*pState).wDataBase, /GEOMETRY)
        newX = geo.xsize
        ;; Handle resizing madness on Unix.  If TLB is getting larger
        ;; then widget geometry of inner base returns the correct
        ;; size, if TLB is getting smaller than widget geometry will
        ;; return the old value instead of the proper new value.  Must
        ;; offset using TLB size difference to compensate.
        if ((!VERSION.OS_FAMILY ne 'Windows') && (deltaW lt 0)) then $
          newX += deltaW
        Widget_Control, (*pState).wButtonBase, SCR_XSIZE=newX

        ;; Lower items
        wParm = Widget_Info((*pState).wParamEditBase, /CHILD)
        if (Widget_Info(wParm, /VALID_ID)) then $
          cw_itparameterpropertysheet_resize, wParm, newXleft, newXright

        ;; Cache new TLB size
        Widget_Control, sEvent.top, TLB_GET_SIZE=basesize
        (*pState).basesize = basesize

      endif
    end

    "DATAMANAGER": BEGIN
      ;; stop observing old data item
      (*pState).oUI->RemoveOnNotifyObserver,(*pState).idSelf,(*pState).itemID
      ;; save ID of new item
      (*pState).itemID = sEvent.identifier
      ;; display properties in property sheet
      widget_control,(*pState).wProp, $
                     set_value=(*pState).itemID

      oSys = (*pState).oUI->GetTool()
      oItem =  oSys->GetByIdentifier(sEvent.identifier)

      IF obj_isa(oItem, 'IDLitData') THEN BEGIN
        ;; observe the data item
        (*pState).oUI->AddOnNotifyObserver,(*pState).idSelf,(*pState).itemID
        ;; let table know which data item is currently selected
        IF widget_info(wParm,/valid_id) THEN $
          cw_itParameterPropertySheet_SetDataSelect,wParm,oItem

        ;; if item was double clicked then add data to parm table
        IF (sEvent.clicks EQ 2) && widget_info(wParm,/valid_id) THEN BEGIN
          success = cw_itParameterPropertysheet_AddData(wParm)
          IF success THEN BEGIN
            widget_control, $
              (*pState).wDoAction, $
              sensitive=cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
            ;; do not allow DM to change insVis droplist
            cw_itParameterPropertysheet_LockList,wParm
          ENDIF
        ENDIF
      ENDIF ELSE BEGIN
        ;; let table know which data item is currently selected
        IF widget_info(wParm,/valid_id) THEN $
          cw_itParameterPropertySheet_SetDataSelect,wParm,0
      ENDELSE

    END

    'DISMISS': BEGIN
      widget_control, sEvent.top, map=0
      (*pState).isVisible = 0b
      ;; no need to bother receiving selection notifications
      (*pState).oUI->RemoveOnNotifyObserver, (*pState).idSelf, 'Visualization'
    END

    'VARIABLE' : BEGIN
      ;; launch import variable dialog
      void = IDLitwdCommandLineImport((*pState).oUI, $
                                      group_leader=sEvent.top)
    END

    'FILE' : BEGIN
      ;; launch import from file dialog
      void = IDLitwdFileImport((*pstate).oUI, $
                               group_leader=sEvent.top)
    END

    'APPLY': BEGIN  ; edit parameters
      IF obj_isa((*pState).oRequestor,'IDLitOpEditParameters') THEN BEGIN
        ;; get parameters from table
        cw_itParameterPropertysheet_GetParameters,wParm, strParms, $
                                                  idParms, count=count
        IF (count GT 0) THEN BEGIN
          (*pState).oRequestor->SetProperty, $
            PARAMETER_NAMES=strParms,DATA_IDS=idParms
          ;; get tool
          oSys = (*pState).oUI->GetTool()
          oTool = oSys->_GetCurrentTool()
          (*pState).oRequestor->_SetTool,oTool
          ;; get macro service
          oSrvMacros = oTool->GetService('MACROS')
          ;; save current value and set show_ui to zero
          (*pState).oRequestor->GetProperty,SHOW_EXECUTION_UI=showUIOrig
          (*pState).oRequestor->SetProperty,SHOW_EXECUTION_UI=0
          ;; call doaction, which performs the operation and generates
          ;; the needed commands
          oCmd = (*pState).oRequestor->DoAction(oTool)
          ;; Add this to history explicitly
          IF obj_valid(oCmd[0]) THEN BEGIN
            oSrvMacros->GetProperty, CURRENT_NAME=currentName
            oSrvMacros->PasteMacroOperation, (*pState).oRequestor, currentName
          ENDIF
          ;; Add this to undo/redo explicitly
          oTool->_TransactCommand, oCmd
          ;; restore original values on the operation
          (*pState).oRequestor->SetProperty,SHOW_EXECUTION_UI=showUIOrig
          ;; notify in case something changed
          oTool->DoOnNotify, (*pState).idValue, "ADDITEMS", idParms[0]
        ENDIF
        widget_control,(*pState).wDoAction,sensitive=0
      ENDIF
    END

    'INSERT': BEGIN  ; insert visualization
      ;; get tool
      oSys = (*pState).oUI->GetTool()
      oTool = oSys->_GetCurrentTool()
      ;; create new tool if needed
      IF ~obj_valid(oTool) THEN $
        oTool = oSys->GetByIdentifier(IDLitSys_CreateTool("Base Tool"))
      ;; if the insVis requestor object has been lost, e.g., if the
      ;; calling tool was destroyed, then create another
      IF ~obj_valid((*pState).oRequestor) THEN $
        (*pState).oRequestor = $
          (oTool->GetByIdentifier('Operations/Insert/Visualization')) $
          ->GetObjectInstance()

      ;; if everything is valid then proceed with operation
      IF obj_isa((*pState).oRequestor,'IDLitOpInsertVis') THEN BEGIN
        ;; get parameters from table
        cw_itParameterPropertysheet_GetParameters,wParm, strParms, $
                                                  idParms, count=count
        ;; get ID of current vis descriptor
        visID = cw_itParameterPropertysheet_GetVisDesc(wParm)
        IF (count GT 0) THEN BEGIN
          (*pState).oRequestor->SetProperty, $
            PARAMETER_NAMES=strParms,DATA_IDS=idParms,VISUALIZATION_ID=visID
          (*pState).oRequestor->_SetTool,oTool
          ;; get macro service
          oSrvMacros = oTool->GetService('MACROS')
          ;; save current value and set show_ui to zero
          (*pState).oRequestor->GetProperty,SHOW_EXECUTION_UI=showUIOrig
          (*pState).oRequestor->SetProperty,SHOW_EXECUTION_UI=0
          ;; call doaction, which performs the operation and generates
          ;; the needed commands
          oCmd = (*pState).oRequestor->DoAction(oTool)
          ;; Add this to history explicitly
          IF obj_valid(oCmd[0]) THEN BEGIN
            oSrvMacros->GetProperty, CURRENT_NAME=currentName
            oSrvMacros->PasteMacroOperation, (*pState).oRequestor, currentName
          ENDIF
          ;; Add this to undo/redo explicitly
          oTool->_TransactCommand, oCmd
          ;; restore original values on the operation
          (*pState).oRequestor->SetProperty,SHOW_EXECUTION_UI=showUIOrig
        ENDIF

        ;; dismiss widget
        widget_control, sEvent.top, map=0
        (*pState).isVisible = 0b

      ENDIF
    END

    'HELP': BEGIN
      oSys = (*pState).oUI->GetTool()
      oHelp = oSys->GetService('HELP')
      IF obj_valid(oHelp) THEN BEGIN
        CASE 1 OF
          (*pState).isInsVis : oHelp->HelpTopic,oSys,'IDLitOpInsertVis'
          (*pState).isParmEdit : oHelp->HelpTopic,oSys,'IDLitOpEditParameters'
          ELSE : oHelp->HelpTopic,oSys,'IDLitOpBrowserData'
        ENDCASE
      ENDIF
    END

    'ADD': BEGIN  ; add item to parameter table
      widget_control, $
        (*pState).wDoAction, $
        sensitive=cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
      ;; do not allow DM to change insVis droplist
      cw_itParameterPropertysheet_LockList,wParm
    END

    'REMOVE': BEGIN  ; remove item from parameter table
      widget_control, $
        (*pState).wDoAction, $
        sensitive=cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
    END

    'REMOVE_ALL': BEGIN  ; remove all items from parameter table
      widget_control, $
        (*pState).wDoAction, $
        sensitive=cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
    END

    'PROP_SHEET' : BEGIN
      IF (TAG_NAMES(sEvent,/STRUCTURE_NAME) EQ 'WIDGET_CONTEXT') THEN return
      IF (sEvent.identifier EQ 'VIS_TYPE') && (sEvent.type EQ 0) THEN $
        widget_control, $
        (*pState).wDoAction, $
        sensitive=cw_itParameterPropertysheet_IsRequiredFullfilled(wParm)
    END

    ELSE:

  ENDCASE

END

;-------------------------------------------------------------------------
;
FUNCTION IDLitwdDataManager, oUI, oRequestor, $
                             TITLE=TITLE, $
                             LEFT_XSIZE=LXSIZE, $  ;; pixels
                             RIGHT_XSIZE=RXSIZE, $  ;; pixels
                             TOP_YSIZE=TYSIZE, $  ;; propertysheet rows
                             BOTTOM_YSIZE=BYSIZE, $  ;; propertysheet rows
                             PARAMETER_EDITOR=PARAMETEREDITOR, $
                             INSERT_VISUALIZATION=INSERTVISUALIZATION, $
                             VALUE=oValue, $
                             _EXTRA=_extra

  compile_opt idl2, hidden

  on_error, 2

  regName = "IDLitwdDataManager"

  ;;has this already been registered and is up and running?
  wID = oUI->GetWidgetByName(regName)
  IF (wID NE 0) THEN BEGIN
    IDLitwdDataManager_SetWidget,wID, $
                                 PARAMETER_EDITOR=parametereditor, $
                                 INSERT_VISUALIZATION=insertvisualization, $
                                 TITLE=title, VALUE=oValue, $
                                 REQUESTOR=oRequestor
    widget_control, wID, /map, iconify=0
    return,0
  ENDIF

  IF (~keyword_set(LXSIZE)) THEN $
    LXSIZE = 300
  IF (~keyword_set(RXSIZE)) THEN $
    RXSIZE = 300
  IF (~keyword_set(TYSIZE)) THEN $
    TYSIZE = 8
  IF (~keyword_set(BYSIZE)) THEN $
    BYSIZE = 8

  DMtitle = IDLitLangCatQuery('UI:DM:DMtitle')
  PEtitle = IDLitLangCatQuery('UI:DM:PEtitle')
  IVtitle = IDLitLangCatQuery('UI:DM:IVtitle')

  ;; Build our widget.
  wTLB = Widget_Base(/column, $
                     title=title, /TLB_SIZE_EVENTS, $
                     UNAME="TLB", $
                     /TLB_KILL_REQUEST_EVENTS, $;TLB_FRAME_ATTR=1, $
                     _extra=_extra)

  ;; The System UI object (which we assume has called us)
  ;; doesn't have a top-level base (unlike Tools). Therefore, for now, set
  ;; the System top-level base to be the Data Manager.
  ;; That way, progress bars will appear directly on top of us.
  oUI->SetProperty, GROUP_LEADER=wTLB

  wDataBase = widget_base(wTLB, /row)

  ;; The data manager
  wDM = cw_itDataManager(wDataBase, oUI, $
                         xsize=lxsize, $
                         uname="DATAMANAGER")

  wCol = widget_base(wDataBase,/column, XPAD=0, YPAD=0, SPACE=0)

  wProp = CW_ITPROPERTYSHEET(wCol, oUI, $
                             scr_xsize=rxsize, $
                             ysize=8,/sunken_frame)

  ;; make DM the same height as the propertysheet
  geo = widget_info(wProp,/geometry)
  cw_itdatamanager_resize,wDM,lxsize,geo.scr_ysize

  ;; base for the possible parameter editor / insert vis widget
  wParamEditBase = widget_base(wTLB)

  geo = Widget_Info(wDataBase, /GEOMETRY)
  wButtonBase = Widget_Base(wTLB, column=2, /grid, scr_xsize=geo.scr_xsize)

  wLeftBase = widget_base(wButtonBase,/align_left,/row,space=5)
  wVoid = widget_button(wLeftBase,VALUE=IDLitLangCatQuery('UI:DM:Help'), $
                        uname='HELP')
  wVoid = widget_button(wLeftBase, $
                        value=IDLitLangCatQuery('UI:DM:buttonImportVar'), $
                        uname="VARIABLE")
  wVoid = widget_button(wLeftBase, $
                        value=IDLitLangCatQuery('UI:DM:buttonImportFile'), $
                        uname="FILE")

  wRightBase = widget_base(wButtonBase,/align_right,/row,space=5)
  wOKBase = widget_base(wRightBase,map=0)
  wDoAction = Widget_Button(wOKBase, VALUE='DISMISS', uname='DOACTION')
  wCancel = widget_button(wRightBase, $
                          VALUE=IDLitLangCatQuery('UI:DM:Dismiss'), $
                          uname='DISMISS')

  idSelf = oUI->RegisterWidget(wTLB, regName, regName+'_callback', $
                               DESCRIPTION="IDL Data Manager Browser",$
                               /floating)

  ;; get system and observe
  oSys = oUI->GetTool()
  ; Observe the system so that we can be desensitized when a macro is running
  oUI->AddOnNotifyObserver, idSelf, oSys->GetFullIdentifier()
  ;; observe visualizations for selection changes
  oUI->AddOnNotifyObserver, idSelf, 'Visualization'

  ;; create dummy data object to put in the property sheet if a
  ;; non-data item is selected in the data manager
  nullData = obj_new('IDLitData',NAME=' ',/PRIVATE)
  nullData->setPropertyAttribute, $
    ['NAME','DESCRIPTION','READ_ONLY', 'Type', 'N_DIMENSIONS', $
     'DATA_OBSERVERS'], $
    sensitive=0
  nullDataTemp = nullData
  widget_control,wProp,set_value=nullDataTemp

  state = {wTLB           : wTLB, $  ; top level base
           oUI            : oUI, $   ; user interface object
           idSelf         : idSelf, $  ; id as registered with oUI
           idValue        : '', $  ; the id of the passed in ovalue
           isParmEdit     : 0b, $  ; boolean flag
           isInsVis       : 0b, $  ; boolean flag
           isVisible      : 1b, $  ; is widget mapped?
           wDataBase      : wDataBase, $ ; widest row in the widget
           wDM            : wDM, $   ; base for datamanager
           wParamEditBase : wParamEditBase, $  ; parameter table base
           wButtonBase    : wButtonBase, $ ; bottom button base
           wProp          : wProp, $  ; property sheet in DM
           wDoAction      : wDoAction, $  ; morphable do something button
           wCancel        : wCancel, $  ; dismiss/cancel button
           oRequestor     : oRequestor, $  ; operation that requested this
           DMtitle        : DMtitle, $  ; title if datamanager
           PEtitle        : PEtitle, $  ; title if parameter editor
           IVtitle        : IVtitle, $  ; title if insert vis dialog
           itemID         : '', $  ; selected item in DM
           basesize       : [0L, 0L], $
           minX           : 200l, $
           minY           : 200l, $
           l_xsize        : lxsize, $
           r_xsize        : rxsize, $
           t_ysize        : tysize, $
           b_ysize        : bysize, $
           apply          : IDLitLangCatQuery('UI:DM:Apply'), $
           dismiss        : IDLitLangCatQuery('UI:DM:Dismiss'), $
           ok             : IDLitLangCatQuery('UI:DM:OK'), $
           cancel         : IDLitLangCatQuery('UI:DM:Cancel') $
          }

  pState = ptr_new(state, /no_copy)
  widget_control, wTLB, set_uvalue=pState

  Widget_Control, wTLB, MAP=0
  Widget_Control, wTLB, /REALIZE

  IDLitwdDataManager_SetWidget,wTLB, $
                               PARAMETER_EDITOR=parametereditor, $
                               INSERT_VISUALIZATION=insertvisualization, $
                               TITLE=title, $
                               REQUESTOR=oRequestor, $
                               VALUE=oValue

  Widget_Control, wTLB, /MAP

  ;; Retrieve the starting dimensions and store them.  Used for window
  ;; resizing in event processing.
  Widget_Control, wTLB, TLB_GET_SIZE=basesize
  (*pState).basesize = basesize

  xmanager, 'IDLitwdDataManager', wTLB, /no_block,$
            CLEANUP="idlitwdDataManager_CLEANUP"

  obj_destroy,nullData

  return,0

end

