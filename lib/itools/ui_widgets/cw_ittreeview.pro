; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_ittreeview.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   cw_ittreeview
;
; PURPOSE:
;   This function implements the compound widget for the IT treeview.
;
; CALLING SEQUENCE:
;   Result = cw_ittreeview(Parent)
;-

;;-------------------------------------------------------------------------
;; cw_ittreeview_Callback
;;
;; Purpose:
;;   Messaging callback from the UI object to this widget. This is the
;;   method used to relay messages from the object system to this
;;   widget.
;;
;; Parameters:
;;    wTree   - This widget
;;
;;    strID   - The id of the item changed
;;
;;    message - The message being sent
;;
;;    userdata - Message specific info.
;;
pro cw_ittreeview_callback, wTree, strID, message, userdata

  compile_opt idl2, hidden

@idlit_catch
  if (iErr ne 0) then begin
    catch, /cancel
    return
  end

  if (~WIDGET_INFO(wTree, /VALID)) then $
    return
  WIDGET_CONTROL, wTree, GET_UVALUE=state

  switch (message) of

    'SELECT': begin ;; Selection state of an item change?
        doSel = KEYWORD_SET(userdata)
        for i=0, n_elements(strID)-1 do begin
            wItem= WIDGET_INFO(state.wTree, $
                FIND_BY_UNAME=STRUPCASE(strID[i]))
            if (~wItem) then $
                continue
            if (WIDGET_INFO(wItem, /TREE_SELECT) ne doSel) then begin
                WIDGET_CONTROL, wItem, SET_TREE_SELECT=doSel, $
                    SET_TREE_VISIBLE=(i eq 0)
            endif
        endfor
        break
    END

    "UPDATEITEM":begin ;; update an item
        wItem = widget_info(state.wTree, find_by_uname=STRUPCASE(strID))
        if(wItem gt 0)then begin
            isSel = widget_info(wItem, /tree_select)
            Parent= widget_info(wItem, /parent)
            if(Parent eq 0 or Parent eq state.wTree)then Parent = wItem
            if (Parent ne wItem) then $
                isParentSel = widget_info(Parent, /tree_select)
            cw_itTreeView_RebuildLevel, state.wTree, $
              widget_info(Parent, /uname)
            ; Re-establish selections.
            if (isSel ne 0) then begin
                wItem = widget_info(state.wTree, $
                    find_by_uname=STRUPCASE(strID))
                if (widget_info(wItem, /valid_id)) then $
                    widget_control, wItem, /SET_TREE_SELECT
            endif
            if ((Parent ne wItem) && $
                widget_info(Parent, /valid_id)) then $
                widget_control, Parent, SET_TREE_SELECT=isParentSel
        end
        break
    end

    ;; Was an item added ?
    "ADDITEMS": begin
        oTool = state.oUI->GetTool()
        oDest = oTool->GetByIdentifier(strID)
        oItem = oTool->GetByIdentifier(userdata)
        if obj_valid(oDest) && obj_valid(oItem) then begin
            ; Need to rebuild the level if the item was not added at the end
            void = oDest->IsContained(oItem, POSITION=itemPos)
            wLevel = widget_info(state.wTree, find_by_uname=STRUPCASE(strID))
            if wLevel eq 0 || itemPos ne oDest->Count()-1 then begin
                cw_itTreeView_RebuildLevel, state.wTree, strID
            endif else begin
                cw_itTreeView_AddLevel, wLevel, oItem, state.wTree
            endelse
        endif
        break
    end

    ;; Was an item removed or moved?
    "MOVEITEMS":
    "REMOVEITEMS":begin
        ;; Basically we need to rebuild a level
        cw_itTreeView_RebuildLevel, state.wTree, strID
        break
    end

    ;; Did the name of the item change? We monitor for property changes.
    'SETPROPERTY': begin ;; The name might of changed.
        ;; Here, userdata is the property name.
        if (userdata ne 'NAME') then $
            break
        ;; Try to find the widget ID corresponding to the
        ;; changed component.
        wView = WIDGET_INFO(state.wTree, FIND_BY_UNAME=STRUPCASE(strID))

        if (wView eq 0L) then return

        oTool = state.oUI->GetTool()
        if (~OBJ_VALID(oTool)) then $
            break
        oComponent = oTool->GetByIdentifier(strID)
        if (~OBJ_VALID(oComponent)) then $
            break

        strName = cw_ittreeview_getNodeName(oComponent)
        WIDGET_CONTROL, wView, GET_VALUE=value
        if (strName ne value) then $
            WIDGET_CONTROL, wView, SET_VALUE=strName
        break
      end

  else:    break
  endswitch

end
;;----------------------------------------------------------------------
;; cw_ittreeview_setselect
;;
;; Purpose:
;;   Called to set the selection state of the tree based on the
;;   identifiers of the items passed in.
;;
;; Parameters:
;;    wSelf   - This widget
;;
;;    idItem - The item to select. Optional if CLEAR is set.
;;
;; Keywords:
;;  CLEAR: If set, clear all selected items first. If this keyword
;;      is specified then idItem need not be supplied.
;;
;;  UNSELECT: Will unselect, not select
;;
pro cw_ittreeview_setSelect, wSelf, idItem, UNSELECT=unselect, CLEAR=clear

    compile_opt hidden, idl2

    WIDGET_CONTROL, wSelf, GET_UVALUE=state

    ; True or false.
    doSelect = ~KEYWORD_SET(unselect)
    doClear = KEYWORD_SET(clear)

    ; Retrieve current selection state of idItem before possibly clearing.
    wItem = 0
    if (N_ELEMENTS(idItem) gt 0) then begin
        wItem = WIDGET_INFO(state.wTree, FIND_BY_UNAME=STRUPCASE(idItem))
    endif

    ; No item (or invalid item).
    if (~wItem) then begin
        if (doClear) then $
            widget_control, state.wTree, SET_TREE_SELECT=0
        return ; we're done
    endif


    wasSelect = WIDGET_INFO(wItem, /TREE_SELECT)

    ; Is the item still selected?
    if (doSelect && wasSelect) then begin
        nSelect = N_ELEMENTS(WIDGET_INFO(state.wTree, /TREE_SELECT))
        ; We can return early if the item being selected
        ; is the only currently-selected item. No need to clear.
        if (nSelect eq 1) then $
            return
        ; We can also return if we aren't clearing other selections
        ; and our item is already selected.
        if (~doClear) then $
            return
    endif


    if (doClear) then $
        widget_control, state.wTree, SET_TREE_SELECT=0


    ; Did the selection state change?
    if ((wasSelect ne doSelect) || doClear) then $
        widget_control, wItem, SET_TREE_SELECT=doSelect

    ; Only set the "visible" if the item wasn't already selected.
    ; This assumes that if it was already selected, then it is
    ; either visible, or the user "remembers" that they did indeed
    ; select it. Prevents unwanted jumping around of the tree.
    if (~wasSelect && doSelect) then $
        widget_control, wItem, /SET_TREE_VISIBLE

end


;;----------------------------------------------------------------------
;; cw_ittreeview_getselect
;;
;; Purpose:
;;   Called to get the selection state of the tree based on the
;;   identifiers of the items passed in.
;;
;; Parameters:
;;    wSelf   - This widget
;;
;; Keywords:
;;    COUNT  - The number of items returned.
;;
;; Return Value
;;   An array of the identifiers for the items selected in the
;;   tree. Or '' if nothing was selected
;;
function cw_ittreeview_getSelect, wSelf, COUNT=COUNT
    compile_opt hidden, idl2

    widget_control, wSelf, get_uvalue=state

    wItem = widget_info(state.wTree, /tree_select)
    if(wItem[0] ne -1)then begin
        count = n_elements(wItem)
        idItems = strarr(count)
        for i=0, count-1 do $
          idItems[i] = widget_info(wItem[i], /uname)
    endif else begin
        idItems=''
        count=0
    end
    return, idItems
end
;;----------------------------------------------------------------------
;; cw_ittreeview_getparent
;;
;; Purpose:
;;   Return the identifier of the parent in the tree
;;
;; Parameters:
;;    wSelf   - This widget
;;
;;    idITem  - identifier of the item
;;
;; Return Value
;;   parent identifier or ''
;;
function cw_ittreeview_getParent, wSelf, idItem
    compile_opt hidden, idl2

    widget_control, wSelf, get_uvalue=state

    wItem = widget_info(state.wTree, find_by_uname=STRUPCASE(idItem))
    if(wItem eq 0)then return, ''
    Parent = widget_info(wItem, /parent)
    if(Parent eq 0)then return, ''
    return, widget_info(Parent, /uname)
end
;;----------------------------------------------------------------------
;; cw_ittreeview_DestroyItem
;;
;; Purpose:
;;    Used to destroy an item and all children of the specified item
;;
;; Parameters:
;;    state          - widget state struct
;;
;;    wItem          - The item to be destroyed.
;;
;;    expanded[out]  - List of identifiers that are expanded.

PRO cw_ittreeview_DestroyItem, state, wItem, expanded
   compile_opt hidden, idl2

    wChild = WIDGET_INFO(wItem, /CHILD)
    if (wChild) then $
        ; DestroyLevel does not destroy the item itself
        cw_ittreeview_DestroyLevel, state, wItem, expanded

   ;; Nuke the item itself
   widget_control, wItem, /destroy

end
;;----------------------------------------------------------------------
;; cw_ittreeview_DestroyLevel
;;
;; Purpose:
;;    Used to destroy all children of the specified item, at this level and below.
;;
;; Parameters:
;;    state          - widget state struct
;;
;;    wItem          - The item whose children are to be destroyed.
;;
;;    expanded[out]  - List of identifiers that are expanded.

PRO cw_ittreeview_DestroyLevel, state, wItem, expanded
   compile_opt hidden, idl2

   ;; no children, no dice
    wChild = WIDGET_INFO(wItem, /CHILD)
    if (~wChild) then $
        return

    wParent = WIDGET_INFO(wChild, /PARENT)
    wasParentSelected = WIDGET_INFO(wParent, /TREE_SELECT)
    isParentSelected = wasParentSelected

   Repeat begin
       idChild = widget_info(wChild, /uname)
       ;; Check expansion
       if(widget_info(wChild,/tree_expanded) EQ 1) then $
           expanded = [expanded, idChild]
       ;; Unregister with the UI,
       state.oUI->RemoveOnNotifyObserver, state.idSelf, idChild

       ;; Recurse
       cw_ittreeview_destroyLevel, state, wChild, expanded

       wNext = widget_info(wChild,/sibling)

       ; If a child is selected then (on Windows) a select
       ; event for the parent is automatically sent, which can
       ; cause problems. To avoid this, select the parent manually.
       ; The parent will be deselected after the loop.
       if ~isParentSelected && WIDGET_INFO(wChild, /TREE_SELECT) then begin
            WIDGET_CONTROL, wParent, /SET_TREE_SELECT
            isParentSelected = 1
       endif

       ;; Nuke the widget
       widget_control, wChild, /destroy
       wChild = wNext
  endrep until( wChild EQ 0)

    if (~wasParentSelected && isParentSelected) then $
        WIDGET_CONTROL, wParent, SET_TREE_SELECT=0

end

;;---------------------------------------------------------------------------
;; cw_itTreeView_GetVisData
;;
;; Purpose:
;;   Routine to retreive the data of a visualization for display
;;
;; Keywords:
;;    Count - # of returned items
;;
;; Return Value:
;;   The children

function cw_itTreeView_GetVisData, oVis, count=count
   compile_opt hidden, idl2

   if(obj_isa(oVis, "IDLitVisualization"))then begin
       ;; if the vis has visible parameters, create a new level
       ;; that will hold it's data.
       oPSet = oVis->IDLitParameter::GetParameterSet()
       void = oPSet->Get(/skip_private, count=count,/all)
   endif else begin
       count =0
       oPSet = obj_new()
   endelse
   return, oPSet
end
;;---------------------------------------------------------------------------
;; cw_itTreeView_RebuildLevel
;;
;; Purpose:
;;    This routine is called to rebuild a level in the tree. This is
;;    normally used to resync a level when items have been added,
;;    removed or repositioned.
;;
;; Parameters:
;;    wTree  - This widget
;;
;;    state  - The widget state
;;
;;    idLevel - id of Level to rebuild

PRO cw_itTreeView_RebuildLevel, wTree, idLevel
    compile_opt hidden, idl2

    WIDGET_CONTROL, wTree, GET_UVALUE=state

    ;; Does the tree have this level?
    wLevel = widget_info(wTree, find_by_uname=STRUPCASE(idLevel))
    if(not widget_info(wLevel, /valid_id))then begin
        ;; If we are hiding an item, we will want its parent.
        ;; Pop the id.
        void = IDLitBaseName(idLevel, remainder=idTarget)
        wLevel = widget_info(wTree, find_by_uname=STRUPCASE(idTarget))
        if(not widget_info(wLevel, /valid_id))then $
          return; no go
    endif else $
      idTarget = idLevel

    ; Don't turn update off/on if someone else already has.
    hasUpdate = WIDGET_INFO(wTree, /UPDATE)
    ; Turn update off to prevent flashing & flickering.
    if (hasUpdate) then $
        widget_control, wTree, update=0

    ;; If we have children clear out current contents
    if((wChild = Widget_Info(wLevel, /child)) gt 0)then begin
        ;; Destroy the contents of this level, recording expansion
        ;; state as we go
        idExpanded=''
        cw_ittreeview_DestroyLevel, state, wLevel, idExpanded
    endif

    ;; Okay, now add the level back. This will take into account any
    ;; new/changed/deleted items
    oTool = state.oUI->GetTool()
    oItem = oTool->GetByIdentifier(idTarget)
    ;; Get the sub-items that need to be created. This is a little ugly
    bIsITContainer = obj_isa(oItem, "_IDLitContainer")
    if(bIsITContainer || obj_isa(oItem, "IDL_Container"))then begin
        ;; If this is an itContainer, we want to not retrieve the
        ;; private items
        oChildren = bIsITContainer ? $
          oItem->Get(/all, count=cnt, /skip_private) : $
          oItem->Get(/all, count=cnt)
        bDirty=0b
        ;; Children to add?
        if(cnt gt 0)then begin
            cw_itTreeView_AddLevelInternal, wLevel, oChildren, wTree
            bDirty++
        endif
        ;; Check for Vis data
        if(obj_isa(oItem, "IDLitVisualization"))then begin
            oPSet = cw_itTreeView_GetVisData(oItem, count=count)
            if(count gt 0)then begin
                cw_itTreeView_AddLevelInternal, wLevel, oPSet, wTree
                bDirty++
            endif
        endif
        if(bDirty ne 0)then begin
            ;; Now, if we have some expansion to apply, do that
            for i=1, n_elements(idExpanded)-1 do begin
                wItem = widget_info(wLevel, $
                    find_by_uname=STRUPCASE(idExpanded[i]))
                if(wItem gt 0)then $
                  widget_control, wItem, /set_tree_expanded
            endfor
        endif
    endif

    if (hasUpdate) then $
        widget_control, wTree, update=1

end


;;-------------------------------------------------------------------------
;; cw_ittreeview_getNodeName
;;
;; Purpose:
;;   Method to get a name for the given item. The name property is
;;   attempted, but if that doesnt work, the class name is used.
;;
;; Parameters:
;;   oItem - The item to get the name from
;;
;; Return Value:
;;    the name to use
function cw_ittreeview_getNodeName, oItem

  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, obj_class(oItem)
  end

  oItem->IDLitComponent::GetProperty, NAME=name
  return, (name ne '' ? name : obj_class(oItem))
end


;-------------------------------------------------------------------------
; Internal routine to add a new level to the tree base on the items being
;   passed to it. This will recurse on container objects.
;
pro cw_ittreeview_AddLevelInternal, Parent, oItems, wTree, oUI, idSelf, $
    EXPANDED=EXPANDED, $
    NO_NOTIFY=noNotify

  compile_opt idl2, hidden

    WIDGET_CONTROL, wTree, GET_UVALUE=state

    ; See if we need to cache our oUI and idSelf. Just for performance.
    if (N_ELEMENTS(oUI) eq 0) then begin
        oUI = state.oUI
        idSelf = state.idSelf
    endif

  ;; Check validity
  iValid = where(obj_valid(oItems), nValid)
  if(nValid eq 0)then return
  oValid = oItems[iValid]

    previousIcon = ''

    ; Loop through the items and build the tree.
    for i=0, nValid-1 do begin
        ; Get the id for this item
        id=oValid[i]->GetFullIdentifier()
        strName = cw_ittreeview_getNodeName(oValid[i])

        ; Check for icons
        oValid[i]->IDLitComponent::GetProperty, $
            ICON=iconType, PRIVATE=isPrivate

        ; Sanity check. On a recursive call private children will already
        ; have been filtered, but someone (like our AddItems callback)
        ; might have called us directly.
        if (isPrivate) then $
            continue

        ; Can we reuse the most recent icon? Saves time when
        ; adding multiple items of the same type.
        if (icontype ne previousIcon) then begin
            previousIcon = iconType
            if (iconType ne '') then begin
                ; Get the bitmap from the resource pool
                if (~IDLitGetResource(iconType, bitmap, $
                    /bitmap, background=state.background)) then begin
                    if (N_ELEMENTS(bitmap) gt 0) then $
                        void = TEMPORARY(bitmap)
                endif
            endif else begin
                if (N_ELEMENTS(bitmap) gt 0) then $
                    void = TEMPORARY(bitmap)
            endelse
        endif


        ; Recurse if this item is a container or itContainer
        bIsITContainer = obj_isa(oValid[i], "_IDLitContainer")

        if (bIsITContainer || obj_isa(oValid[i], "IDL_Container")) then begin

          ;; Create a folder to represent the container
          wTmp = Widget_Tree(Parent, value=strName, /folder, $
            BITMAP=bitmap, $
            UNAME=id, expanded=expanded)

          ;; If this is an itContainer, we want to not retrieve the
          ;; private items
          oChildren = bIsITContainer ? $
                   oValid[i]->Get(/all, count=cnt, /skip_private) : $
                   oValid[i]->Get(/all, count=cnt)

          ;; if we have children, add new level ->Recurse
          if (cnt gt 0)then begin
            cw_ittreeview_AddLevelInternal, wTmp, oChildren, wTree, oUI, idSelf, $
                NO_NOTIFY=noNotify
          endif

          ;; KDB 3/1/03
          ;; It's desired to display the data that is associated with
          ;; a particular visualization. To do this, the visualization
          ;; must be queried to get the parameter set it
          ;; contains. While non-generic, you cannot add non-gr objs
          ;; to a visualization tree, so a separate call is needed.
          ;; This is the reason for the following section.
          if(obj_isa(oValid[i], "IDLitVisualization"))then begin
              oPSet = cw_itTreeView_GetVisData(oValid[i], count=count)
              if(count gt 0)then begin
                  cw_ittreeview_AddLevelInternal, wTmp, oPSet, wTree, oUI, idSelf, $
                    NO_NOTIFY=noNotify
              endif
          endif
        endif else begin
            wTmp = Widget_Tree(Parent, value=strName, UNAME=id, $
                BITMAP=bitmap)
        endelse

        ; Register for notification messages on this item.
        if (~KEYWORD_SET(noNotify)) then $
            oUI->AddOnNotifyObserver, idSelf, id, /NO_VERIFY

  endfor

end


;;-------------------------------------------------------------------------
;; cw_itTreeView_AddLevel
;;
;; Purpose:
;;   Used to add a new level to the tree base on the items being
;;   passed to it. This will recurse on container objects.
;;
;; Parameters:
;;   Parent  - Parent of this widget.
;;
;;   oItems   - The items to make tree entires for
;;
;;   oUI      - The UI object for this item
;;
;; Keywords:
;;   EXPANDED - The folder should be expaned
;
pro cw_ittreeview_AddLevel, Parent, oItems, wTree, oUI, idSelf, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Don't turn update off/on if someone else already has.
    hasUpdate = WIDGET_INFO(wTree, /UPDATE)
    ; Turn update off to prevent flashing & flickering.
    if (hasUpdate) then $
        widget_control, wTree, UPDATE=0

    cw_ittreeview_AddLevelInternal, Parent, oItems, wTree, oUI, idSelf, $
        _EXTRA=_extra

    if (hasUpdate) then $
        widget_control, wTree, UPDATE=1

end


;;-----------------------------------------------------------------------------
;; cw_itTreeeView_getValue
;;
;; Purpose:
;;   Returns the value of this tree widget: the identifier
;;
;; Parameters:
;;   wTree - the tree widget (this widget)
;;
;; Return Value:
;;    The identifier of the root of this widget.
function cw_ittreeview_getvalue, wTree

  compile_opt idl2, hidden
  WIDGET_CONTROL, wTree, GET_UVALUE=state
  return, state.idTop

end

;;-----------------------------------------------------------------------------
;; cw_itTreeView_SetValue
;;
;; Purpose:
;;   Used to set the value the tree. This is the compound widget
;;   routine
;;
;; Parameters:
;;   wTree  - The id of this tree
;;
;;   idTop  - The identifer of the top element
pro cw_ittreeview_setvalue, wTree, idTop

  compile_opt idl2, hidden

  WIDGET_CONTROL, wTree, GET_UVALUE=state
  state.idTop = idTop
  WIDGET_CONTROL, wTree, SET_UVALUE=state

  cw_itTreeView_RebuildLevel, state.wTree, idTop

end

;;-------------------------------------------------------------------------
;; cw_itTreeView_Resize
;;
;; Purpose:
;;   Handle resize requests.
;;   deltaX and deltaY are the relative changes to the base size.
;;
;;
pro cw_ittreeview_resize, id, deltaX, deltaY

  compile_opt idl2, hidden

  WIDGET_CONTROL, id, GET_UVALUE=state

  ;; Retrieve the current treeview size.
  geom = WIDGET_INFO(state.wTree, /GEOMETRY)
  newXsize = (geom.xsize + deltaX) > 0
  newYsize = (geom.ysize + deltaY) > 0

  ;; Change width of treeview.
  WIDGET_CONTROL, state.wTree, XSIZE=newXsize, $
                  YSIZE=newYsize

end

;-------------------------------------------------------------------------
function cw_ittreeview_event, event

  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, 0
  end

  WIDGET_CONTROL, ((root=widget_info(event.id,/tree_root))), GET_UVALUE=state

  ret_event = 0

  case TAG_NAMES(event, /STRUCTURE_NAME) OF
      'WIDGET_CONTEXT' : if(state.wContext gt 0)then $
        WIDGET_DISPLAYCONTEXTMENU, event.id, $
        event.x, event.y, state.wContext $
      else return, event

    'WIDGET_TREE_SEL': BEGIN
      wTree = widget_info(event.id,/tree_root)
      selected = widget_info(wTree,/tree_select)

      ; Collect full identifiers of selected items.
      selStr = ['']
      IF widget_info(selected[0],/valid_id) THEN BEGIN
        FOR i=0,n_elements(selected)-1 DO BEGIN
          name=widget_info(selected[i],/uname)
          selStr = selStr[0] EQ '' ? name : [selStr,name]
        ENDFOR
      ENDIF

      ; Make sure someone didn't free our event pointers.
      if (~PTR_VALID(state.event.value)) then $
          state.event.value = PTR_NEW(/ALLOC)
      ret_event = state.event
      ret_event.id = root
      ret_event.top = event.top
      ret_event.handler = event.handler
      ret_event.clicks = event.clicks
      ret_event.selected = widget_info(event.id,/uname)
      *ret_event.value = selStr

      WIDGET_CONTROL, root, SET_UVALUE=state
    END

    'CW_PANES_RESIZE' : cw_ittreeview_resize, event.id, $
                              event.deltaX, event.deltaY

    ELSE :
  ENDCASE

  return, ret_event

END


;-------------------------------------------------------------------------
; Free up our state pointers.
;
pro cw_ittreeview_killnotify, wTree

    compile_opt idl2, hidden

    WIDGET_CONTROL, wTree, GET_UVALUE=state
    event = state.event
    PTR_FREE, event.value

    ; This will also remove ourself as an observer for all subjects.
    state.oUI->UnRegisterWidget, state.idSelf

end


;;-------------------------------------------------------------------------
;; cw_itTreeView
;;
;; Purpose:
;;    This function will build a tree widget that is based of the
;;    contents of a folder that the provided identifier points to.
;;
;; Parameters:
;;    Parent   - Widget id of the parent widget for this widget
;;
;;    oUI       - UI object for this interface.
;;
;;    IDENTIFIER - The folder to use for content
;;
;; Keywords:
;;   MULTIPLE      - The tree should allow multiple selection
;;
;;   CONTEXT_MENU  - The identifier of the folder in the tool that needs
;;                   to be used as a context menu
;;
;;   _EXTRA        - All other keywords are passed to the underlying
;;                   tree widget.
;;
function cw_ittreeview, Parent, oUI, $
                        IDENTIFIER=IDENTIFIER, $
                        MULTIPLE=multiple, $
                        CONTEXT_MENU=CONTEXT_MENU, $
                        _EXTRA=_extra

  compile_opt idl2, hidden

nparams = 2  ; must be defined for cw_iterror
@cw_iterror

  wTree = WIDGET_TREE( Parent, $
                       multiple=keyword_set(multiple), $
                       EVENT_FUNC= 'cw_ittreeview_event', $
                       KILL_NOTIFY='cw_ittreeview_killnotify', $
                       PRO_SET_VALUE= 'cw_ittreeview_setvalue', $
                       FUNC_GET_VALUE= 'cw_ittreeview_getvalue', $
                       _EXTRA=_extra)

;; KDB: 3/2/03
;; This used to key of browser name and type. This was too focused on
;; the underlying structure of the UI and system. This should be done
;; with a context menu keyword that is set to the identifier.
;;
;; Also this was destroying content after creation, which was also
;; wrong. It should just use what is being provided. Or if an item is
;; not desired, either have it removed from the target container or
;; make a new one for the tree view that only contains the desired
;; items (proxy anything needed)

    if(keyword_set(CONTEXT_MENU))then begin
        widget_control,wTree,/context_events
        if (SIZE(context_menu, /TYPE) eq 7) then begin
            wContext = CW_ITMENU(Parent, oUI, CONTEXT_MENU, $
                /CONTEXT_MENU)
        endif else if WIDGET_INFO(context_menu, /VALID) then begin
            wContext = context_menu
        endif
    endif else $
        wContext = 0l

  ;; Register ourself as a widget with the UI object.
  ;; Returns a string containing our identifier.
  idSelf = oUI->RegisterWidget(wTree,'MyTree','cw_ittreeview_callback')

  oTool = oUI->getTool()

    event = {CW_TREE_SEL, $
        ID: 0L, $
        TOP: 0L, $
        HANDLER: 0L, $
        CLICKS  : 0, $
        VALUE: PTR_NEW(), $  ; these will be allocated in the event handler
        SELECTED: ''}

    ;; Get the background color we will use.
    if (~IDLitGetResource("WINDOW_BK", background, /COLOR)) then $
        background = [255b,255b,255b]

  state = { idTop : (N_ELEMENTS(identifier) gt 0) ? identifier : '', $
            oUI : oUI, $
            idSelf : idSelf, $
            wContext : wContext, $
            isTool : obj_isa(oTool, "IDLitTool"), $
            wTree : wTree, $
            event : event, $
            background : background}

  WIDGET_CONTROL, wTree, SET_UVALUE=state

  if (N_ELEMENTS(identifier) gt 0) then begin
      ;; set our initial values
      oItem = oTool->GetByIdentifier(identifier)
      if(obj_valid(oItem))then begin
          cw_ittreeview_addLevel, wTree, oItem, wTree, /EXPANDED
          ;; Update our selection state.
          if(state.isTool)then begin
              oItems = oTool->GetSelectedItems(count=nItems)
              for i=0, nItems-1 do begin
                  idItem= WIDGET_INFO(wTree, $
                    FIND_BY_UNAME=oItems[i]->GetfullIdentifier())
                  if(idItem gt 0)then $
                    WIDGET_CONTROL,idItem, /SET_TREE_SELECT, set_tree_visible=(i eq 0)
              endfor
          endif
      endif
  endif

  return, wTree

END
