;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itdatamanager.pro#1 $
;; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;
;; Purpose:
;;   This file contains the logic that implements a compound widget
;;   that presents the data manager to the user. In also includes
;;   methods to import data into the data manager using either a file
;;   or IDL variables that exist at the command line level.
;;-----------------------------------------------------------------------------
;; cw_itDataManager_getValue
;;
;; Purpose:
;;   Returns the currently selected item in the tree
;;
;; Parameters:
;;   wSelf - This widget
;;
;; Return Value:
;;    Array of items selected in the data manager.
;;
function cw_itDataManager_getvalue, id
  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=pState

  return, cw_itTreeView_GetSelect((*pstate).wDM)

end

;;-----------------------------------------------------------------------------
;; cw_itDataManager_SetValue
;;
;; Purpose:
;;   Used to set the currently selected item in the data manager.
;;
;; Parameters:
;;   id  - The id of this widget
;;
;;   value - The Identifer of the item to select
;;
pro cw_itDataManager_setvalue, id, value

  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=pState
  cw_itTreeView_SetSelect,  (*pstate).wDM, value

end

;;-------------------------------------------------------------------------
;; cw_itDataManagerView_Resize
;;
;; Purpose:
;;   Handle resize requests.
;;
;; Parameters:
;;   id  - The widget id of this widget
;;
;;   X   - The new x value
;;
;;   Y   - The new y value

pro cw_itDataManager_resize, id, X, Y

  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=pState

  geomCW = Widget_Info(id, /geometry)
  ;; Change height of dm
  WIDGET_CONTROL, (*pState).wDM, SCR_XSIZE=X, SCR_YSIZE= Y

end
;;---------------------------------------------------------------------------
;; _cw_itDataManager_DeleteData
;;
;; Purpose:
;;   Encapsulates the functionality used to delete data.
;;
;; Parameters
;;    pState - The state pointer for this widget
;;
;;    wTLB   - The top of this widget tree.
;;
pro _cw_itDataManager_DeleteData, pState, wTLB
   compile_opt hidden, idl2
   ;; Get the item
   id = cw_itTreeView_getSelect((*pstate).wDM, count=count)
   if(count gt 0)then begin
       oTool = (*pstate).oUI->Gettool()
       oItem = oTool->GetByIdentifier(id[0])
       if(obj_valid(oItem))then begin
           idParent = cw_itTreeView_getParent((*pstate).wDM, id[0])
           oItem->GetProperty, name=name
           status = dialog_message(title= $
                                   IDLitLangCatQuery('UI:cwDM:deleteTitle'), $
                                   IDLitLangCatQuery('UI:cwDM:deleteMessage')+name,$
                                   /question, /default_no, dialog_parent=wTLB)
           if(status eq 'Yes')then begin
               oDM = oTool->GetService("DATA_MANAGER")
               status = oDM->DeleteData(id)
               if(status eq 0)then begin
                 void = dialog_message(IDLitLangCatQuery('UI:cwDM:deleteError'),/error, $
                          dialog_parent=wTLB, $
                          title=IDLitLangCatQuery('UI:cwDM:deleteErrorTitle'))
               endif else begin
                   ;; Fake a callback to rebuild the tree.
                   cw_itTreeView_Callback, (*pState).wDM, idParent, $
                     "UPDATEITEM", idParent
               endelse
           endif
       endif else $
         void = dialog_message(IDLitLangCatQuery('UI:cwDM:BadData'), $
                               /warning, $
                               dialog_parent=wTLB, $
                               title=IDLitLangCatQuery('UI:cwDM:BadDataTitle'))
   endif else $
     void = dialog_message(IDLitLangCatQuery('UI:cwDM:NoData'), $
                           /warning, $
                           dialog_parent=wTLB, $
                           title=IDLitLangCatQuery('UI:cwDM:NoDataTitle'))

end
;;---------------------------------------------------------------------------
;; _cw_itDataManager_DeleteAllData
;;
;; Purpose:
;;   Encapsulates the functionality used to delete data.
;;
;; Parameters
;;    pState - The state pointer for this widget
;;
;;    wTLB   - The top of this widget tree.
;;
pro _cw_itDataManager_DeleteAllData, pState, wTLB
  compile_opt hidden, idl2

  ;; Get the items
  dmFolder = widget_info((*pState).wDM,/child)
  ;; get first data item
  data = widget_info(dmFolder,/child)

  IF (data EQ 0) THEN BEGIN
    void = dialog_message(IDLitLangCatQuery('UI:cwDM:NoAllData'), $
                          dialog_parent=wTLB, $
                          title=IDLitLangCatQuery('UI:cwDM:NoDataTitle'))
    return
  ENDIF

  status = dialog_message(title=IDLitLangCatQuery('UI:cwDM:deleteAllTitle'), $
                          IDLitLangCatQuery('UI:cwDM:deleteAllMessage'),$
                          /question, /default_no, dialog_parent=wTLB)
  IF (status NE 'Yes') THEN return

  WHILE (data NE 0) DO BEGIN
    id = widget_info(data,/uname)
    oTool = (*pstate).oUI->Gettool()
    oItem = oTool->GetByIdentifier(id[0])
    if(obj_valid(oItem))then begin
      idParent = cw_itTreeView_getParent((*pstate).wDM, id[0])
      oItem->GetProperty, name=name
      oDM = oTool->GetService("DATA_MANAGER")
      status = oDM->DeleteData(id)
      if(status eq 0)then begin
        void = dialog_message(IDLitLangCatQuery('UI:cwDM:deleteError'),/error, $
                              dialog_parent=wTLB, $
                              title=IDLitLangCatQuery('UI:cwDM:deleteErrorTitle'))
      ENDIF
    endif else $
      void = dialog_message(IDLitLangCatQuery('UI:cwDM:BadData'), $
                            /warning, $
                            dialog_parent=wTLB, $
                            title=IDLitLangCatQuery('UI:cwDM:BadDataTitle'))
    data = widget_info(dmFolder,/child)
  ENDWHILE
  ;; Fake a callback to rebuild the tree.
  cw_itTreeView_Callback, (*pState).wDM, idParent, $
                          "UPDATEITEM", idParent

end

;;---------------------------------------------------------------------------
;; _cw_itDataManager_DuplicateData
;;
;; Purpose:
;;   Encapsulates the functionality used to dup data.
;;
;; Parameters
;;    pState - The state pointer for this widget
;;
;;    wTLB   - The top of this widget tree.
;;
pro _cw_itDataManager_DuplicateData, pState, wTLB
   compile_opt hidden, idl2
   ;; Get the item
   id = cw_itTreeView_getSelect((*pstate).wDM, count=count)
   if(count gt 0)then begin
       oTool = (*pstate).oUI->Gettool()
       oItem = oTool->GetByIdentifier(id[0])
       if(obj_valid(oItem))then begin
           idParent = cw_ittreeView_GetParent((*pstate).wDM, id[0])

           oDM = oTool->GetService("DATA_MANAGER")	;; get DM service
           status = oDM->CopyData(id, parent=idparent)
           if(status eq 1)then begin
               ;; Success
               ;; Fake a callback to rebuild the tree.
               cw_itTreeView_Callback, (*pState).wDM, id[0], "UPDATEITEM",id[0]

           endif else $ ;; error
             void = dialog_message(IDLitLangCatQuery('UI:cwDM:dupError'), $
                                   /error, $
                                   dialog_parent=wTLB, $
                                   title=IDLitLangCatQuery('UI:cwDM:dupErrorTitle'))
       endif else $
         void = dialog_message(IDLitLangCatQuery('UI:cwDM:BadData'), $
                               /warning, $
                               dialog_parent=wTLB, $
                               title=IDLitLangCatQuery('UI:cwDM:BadDataTitle'))
     endif else $
       void = dialog_message(IDLitLangCatQuery('UI:cwDM:NoData'), $
                             /warning, $
                             dialog_parent=wTLB, $
                             title=IDLitLangCatQuery('UI:cwDM:NoDataTitle'))

end

;;-------------------------------------------------------------------------
;; cw_itDataManager_Event
;;
;; Purpose:
;;    The widget event handler for this widget. Pretty standard
;;
;; Parameters:
;;    sEvent   - The event that has been triggered

function cw_itDataManager_event, sEvent
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, 0
  end

  ;; Get our state
  widget_control, sEvent.handler, get_uvalue=pState
  case widget_info(sEvent.id, /uname) of
      "DATAMANAGER": begin
          ;; Context Menu?
          if(tag_names(/structure, sEvent) eq 'WIDGET_CONTEXT')then begin
          WIDGET_DISPLAYCONTEXTMENU, sEvent.id, $
                        sEvent.x, sEvent.y, (*pstate).wContext
          endif else begin
              id= (*sEvent.value)[0]
              heap_free, sEvent
              oTool = (*pstate).oUI->Gettool()
              oItem = oTool->GetByIdentifier(id)
              sensitive = obj_isa(oItem, "IDLitData")
              widget_control, (*pstate).wMenuDel, sensitive=sensitive
              widget_control, (*pstate).wDel, sensitive=sensitive
              widget_control, (*pstate).wDup, sensitive=sensitive
              return, {CW_ITDATAMANAGER, $
                       ID:sEvent.handler, $
                       TOP:sEvent.top, HANDLER:0, $
                       clicks:sEvent.clicks, $
                       identifier:id}
          endelse
      end
      "DELETE": _cw_itDataManager_DeleteData, pState, sEvent.top
      "DELETE_ALL": _cw_itDataManager_DeleteAllData, pState, sEvent.top
      "DUPLICATE":_cw_itDataManager_DuplicateData, pState, sEvent.top
      else:
  endcase
  return, 0

end

;;---------------------------------------------------------------------------
;; cw_itDataManager_Realize
;;
;; Purpose:
;;   The notify realize callback for this widget. Used to verify that
;;   the widget geometry is good when the item is show.
;;
;; Parameters:
;;    wWidget - This widget

pro cw_itDataManager_REALIZE, wWidget
   compile_opt hidden, idl2

;    widget_control, wWidget, get_uvalue=pState

   ;; Make sure the geometry is all right.
;    sGeom = widget_info(wWidget, /geometry)
;    cw_itDataManager_Resize, wWidget, sGeom.xsize, (*pState).ySize0

end
;;---------------------------------------------------------------------------
;; cw_itDataManager_Cleanup
;;
;; Purpose:
;;   The kill notifycallback for this widget. Used to cleanup any state
;;
;; Parameters:
;;    wWidget - This widget

pro cw_itDataManager_Cleanup, wWidget
   compile_opt hidden, idl2

   widget_control, wWidget, get_uvalue=pState
   ptr_free,pState

end

;;-------------------------------------------------------------------------
;; cw_itDataManager
;;
;; Purpose:
;;   The purpose of this compound widget is to provide a view into the
;;   data manager
;;
;; Parameters:
;;    Parent   - Widget id of the parent widget for this widget
;;
;;    oUI     - The root of the component
;;
;; Keywords:
;;    UVALUE    - The user value for this widget
;;
;;    UNAME     - The uname for this widge
;;
;;    XSIZE     - xSize of this widget
;;
;;    YSIZE     - The ysize for this widget
;;
;;   _EXTRA        - All other keywords are passed to the underlying
;;                   tree widget.

function cw_itDataManager, Parent, oUI, $
    UNAME=UNAME, $
    XSIZE=XSIZE, YSIZE=YSIZE, $
    _EXTRA=_extra

  compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

  if(not keyword_set(YSIZE))then YSIZE=150

  wWrapper = widget_base(Parent, EVENT_FUNC= 'cw_itDataManager_event', $
                         PRO_SET_VALUE= 'cw_itDataManager_setvalue', $
                         FUNC_GET_VALUE= 'cw_itDataManager_getvalue', $
                         uname=uname, XPAD=0, YPAD=0, SPACE=0, $
                         NOTIFY_REALIZE='cw_itDataManager_realize', $
                         KILL_NOTIFY='cw_itDataManager_cleanup', $
                         /base_align_center, /column)

  ;; Now create the Datamanager
  wDM = cw_ittreeview(wWrapper, oUI, $
                      IDENTIFIER="/DATA MANAGER", $
                      UNAME="DATAMANAGER", $
                      xsize = xsize)

  ;; Wedge in our own context menu
  widget_control, wDM, /context_events
  wContext = WIDGET_BASE(wWrapper, /CONTEXT_MENU, $
            event_func="cw_itdatamanager_event")

    ; Use a tiny menu button to allow the <Del> accelerator
    ; to be used for the Delete context menu item. Needed because
    ; Motif only allows accelerators on menu items, not toolbar buttons.
    wEdit = Widget_Button(wWrapper, /MENU, VALUE='', $
        SCR_XSIZE=1, SCR_YSIZE=1)
    wMenuDel = widget_button(wEdit, VALUE='', $
        ACCELERATOR='Del', $
        uname="DELETE", SCR_XSIZE=1, SCR_YSIZE=1)

  wDel = widget_button(wContext, $
                       value=IDLitLangCatQuery('UI:cwDM:buttonDelete') + $
                       '         Del', $   ; fake the Accelerator text
                       uname="DELETE")
  wDup = widget_button(wContext, $
                       value=IDLitLangCatQuery('UI:cwDM:buttonDup'), $
                       uname="DUPLICATE")
  wDelAll = widget_button(wContext, $
                          value=IDLitLangCatQuery('UI:cwDM:buttonDeleteAll'), $
                          uname="DELETE_ALL")

  state = { oUI     :  oUI, $
            wDM     :  wDM, $
            ysize0  :  ysize, $ ;initial Y size used in realize notify
            wContext: wContext, $
            wMenuDel : wMenuDel, $
            wDel    : wDel, $
            wDelAll : wDelAll, $
            wDup    : wDup $
          }

  ;; Normally, this would be the first child on the widget, but the
  ;; tree view widget is just a tree, and not wrapped and changes
  ;; could cause issues.
  pState = ptr_new(State,/no_copy)
  WIDGET_CONTROL, wWrapper, SET_UVALUE=pstate
  ;; Due to how the context menu is created, we place the state in the
  ;; context menu also
  WIDGET_CONTROL, wContext, SET_UVALUE=pstate

  return, wWrapper

END
