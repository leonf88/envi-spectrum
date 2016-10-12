;; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ui_widgets/cw_itcomponenttree.pro#1 $
;; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;
;; Purpose:
;;   This compound widget implements a tree view that uses the
;;   structure provided by a IDLitComponent hierarchy to build a
;;   simple tree widget that represents the tree view. This differs
;;   from the cw_ittreeview, in that it is simple and makes no
;;   assumptions on the structure or layout of the tree. The goal is
;;   to be as close to a widget_tree() as possible
;;
;;-------------------------------------------------------------------------
;; cw_itComponenttree_AddLevel
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
;; Keywords:
;;   EXPANDED - The folder is expanded

pro cw_itComponentTree_AddLevel, Parent, oItems, expanded=expanded
  compile_opt idl2, hidden

  ;; Check validity
  iValid = where(obj_valid(oItems), nValid)
  if(nValid eq 0)then return
  oValid = oItems[iValid]

  ;; Loop through the items and build the tree.
  for i=0, nValid-1 do begin
      ;; Get the id for this item
      id=oValid[i]->GetFullIdentifier()
      oValid[i]->GetProperty, name=strName, icon=iconType

      ;; Recurse if this item is a container or itContainer
      if(obj_isa(oValid[i], "_IDLitContainer"))then begin
          ;; Create a folder to represent the container
          wTmp = Widget_Tree(Parent, value=strName, /folder, $
                             UNAME=id, expanded=expanded)

          ;; If this is an itContainer, we want to not retrieve the
          ;; private items
          oChildren =oValid[i]->Get(/all, count=cnt, /skip_private)
          ;; if we have children, add new level ->Recurse
          if (cnt gt 0)then $
            cw_itComponenttree_AddLevel, wTmp, oChildren

      endif else $
        wTmp = Widget_Tree(Parent, value=strName, UNAME=id)

      if(iconType ne '') then begin
          ;; Get the background color we will use.
          status = IDLitGetResource("WINDOW_BK", background, /COLOR)

          ;; Get the bitmap from the resource pool
          status = IDLitGetResource(iconType, bm, $
                                    /bitmap, background=background)

          if(status eq 0)then $
            status = IDLitGetResource("default", bm, $
                                      /bitmap, background=background)
          if(status gt 0)then $
            WIDGET_CONTROL, wTmp, SET_TREE_BITMAP=bm
      endif
  endfor
end

;;-----------------------------------------------------------------------------
;; cw_itComponentTree_SetRoot
;;
;; Purpose:
;;   When called, the tree resets itself, using the new root value
;;
;; Parameters:
;;   wTree - the tree widget (this widget)
;;
;;   oRoot  - The new root value
;;
pro cw_itcomponenttree_SetRoot, wTree, oRoot
   compile_opt hidden, idl2

   if(~obj_valid(oRoot))then return

   WIDGET_CONTROL, widget_info(wTree,/child), GET_UVALUE=state

   wNode = widget_info(state.wTree,/child)
   while(widget_info(wNode, /valid))do begin
       widget_control, wNode,/destroy
       wNode = widget_info(state.wTree,/child)
   endwhile

   ;; Just build the tree at the root.
   cw_itcomponenttree_addLevel, state.wTree, oRoot, /expanded
   state.oRoot = oRoot
   WIDGET_CONTROL, widget_info(wTree,/child), SET_UVALUE=state   ,/no_copy
end
;;-----------------------------------------------------------------------------
;; cw_itComponentTree_getValue
;;
;; Purpose:
;;   Returns the currently selected item in the tree
;;
;; Parameters:
;;   wTree - the tree widget (this widget)
;;
;; Return Value:
;;  The identifier of the currently selected items in the tree.

function cw_itComponenttree_getvalue, wTree

  compile_opt idl2, hidden
  WIDGET_CONTROL, widget_info(wTree,/child), GET_UVALUE=state

  wSel = widget_info(state.wTree, /tree_select)
  if(wSel[0] eq -1 )then return, ''

  nSel = n_elements(wSel)
  strRet = strarr(nSel)
  for i=0, nSel-1 do $
      strRet[i] = widget_info(wSel[i], /uname)

  return, strRet

end
;;-----------------------------------------------------------------------------
;; cw_itComponentTree_SetValue
;;
;; Purpose:
;;   Used to set the value the tree. This is the compound widget
;;   routine
;;
;; Parameters:
;;   wTree  - The id of this tree
;;
;;   idTop  - The identifier to select
;;
pro cw_itComponentTree_setvalue, wTree, idTop

  compile_opt idl2, hidden

  WIDGET_CONTROL, widget_info(wTree,/child), GET_UVALUE=state

  wItem = widget_info(state.wTree, find_by_uname=idTop)
  if(wItem ne 0)then $
    widget_control, wItem, /set_tree_select,/set_tree_visible
end

;;-------------------------------------------------------------------------
;; cw_itComponentTree_Resize
;;
;; Purpose:
;;   Handle resize requests.
;;
;; Parameters:
;;   id    - This widget
;;
;;    X    - The new xsize
;;
;;    Y    - The new Ysize
pro cw_itComponentTree_resize, id, deltaX, deltaY

  compile_opt idl2, hidden

  WIDGET_CONTROL, widget_info(id,/child), GET_UVALUE=state

  ;; Retrieve the current treeview size.
  geom = WIDGET_INFO(state.wTree, /GEOMETRY)
  newXsize = (geom.xsize + deltaX) > 0
  newYsize = (geom.ysize + deltaY) > 0

  ;; Change width of treeview.
  WIDGET_CONTROL, state.wTree, XSIZE=newXsize, $
                  YSIZE=newYsize
end


;-------------------------------------------------------------------------
pro cw_itComponentTree_help, event

    compile_opt idl2, hidden

    WIDGET_CONTROL, event.id, GET_UVALUE=wMyTop
    WIDGET_CONTROL, WIDGET_INFO(wMyTop, /CHILD), GET_UVALUE=state
    ; Just take the first item.
    wSelect = (WIDGET_INFO(state.wTree, /TREE_SELECT))[0]
    if (wSelect le 0L) then $
        return
    identifier = WIDGET_INFO(wSelect, /UNAME)

    oHelp = state.oTool->GetService("HELP")
    if (~OBJ_VALID(oHelp)) then begin
        errorMsg = IDLitLangCatQuery('UI:cwCompTree:NoHelp')
        goto, failed
    endif

    ; Retrieve the selected item.
    oSelected = state.oTool->GetByIdentifier(identifier)

    ; If not valid, return.
    if (~OBJ_VALID(oSelected)) then begin
      errorMsg = [IDLitLangCatQuery('UI:cwCompTree:NoObjFromID'), $
                  identifier]
      goto, failed
    endif

    ; Retrieve the HELP property.
    oSelected->GetProperty, HELP=helpTopic

    ; If HELP is undefined, try to use the classname.
    if (helpTopic eq '') then begin
      if (OBJ_ISA(oSelected, 'IDLitObjDesc')) then begin
        oSelected->GetProperty, CLASSNAME=helpTopic
        if (helpTopic eq '') then begin
          errorMsg = IDLitLangCatQuery('UI:cwCompTree:UndefClassname')
          goto, failed
        endif
      endif else $
        helpTopic = OBJ_CLASS(oSelected)
    endif

    oHelp->HelpTopic, state.oTool, helpTopic

    return

failed:
    state.oTool->ErrorMessage, errorMsg, SEVERITY=2

end


;;-------------------------------------------------------------------------
;; cw_itComponentTree_event
;;
;; Purpose:
;;   The standard event handler for this compound widget.
;;
;; Parameters:
;;    sEvent  - The event being sent
;;
function cw_itComponentTree_event, sEvent

  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, 0
  end

  widget_control, widget_info(sEvent.handler, /child), get_uvalue=state
  ;; Just pass the events up to the parent if it is a selection event.
  case TAG_NAMES(sEvent, /STRUCTURE_NAME) OF

        'WIDGET_CONTEXT' : begin
            ; Only display context menu for leaf nodes.
            wSelect = WIDGET_INFO(state.wTree, /TREE_SELECT)
            if (WIDGET_INFO(wSelect, /CHILD) eq 0L) then $
                WIDGET_DISPLAYCONTEXTMENU, sEvent.id, $
                    sEvent.x, sEvent.y, state.wContext
            end

    'WIDGET_TREE_SEL': BEGIN
        identifier = $
            WIDGET_INFO(WIDGET_INFO(state.wTree, /tree_select), /UNAME)
        return, {CW_ITCOMPONENT_TREE, $
                 ID:sEvent.handler, $
                 TOP:sEvent.top, HANDLER:0L, $
                 IDENTIFIER:identifier, CLICKS:sEvent.clicks}
    end

    ;; Just incase this is placed in a panes widget.....
    'CW_PANES_RESIZE': $
      cw_itComponentTree_resize, sEvent.handler, sEvent.deltaX, sEvent.deltaY
    else:
  endcase

  return, 0

end


;;-------------------------------------------------------------------------
;; cw_itComponentTree
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
;;    oRoot     - The root of the component
;;
;; Keywords:
;;   CONTEXT_MENU  - The identifier of the folder in the tool that needs
;;                   to be used as a context menu
;;
;;   UVALUE     - The uvalue of the widget
;;
;;   UNAME      - Uname for this widget
;;
;;   _EXTRA        - All other keywords are passed to the underlying
;;                   tree widget.
;;
function cw_itComponentTree, Parent, oUI, oRoot, $
    NO_CONTEXT=noContext, $
    UVALUE=UVALUE, UNAME=UNAME, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

nparams = 3  ; must be defined for cw_iterror
@cw_iterror

  ;; Build the CW base
  wWrapper = widget_base(Parent, EVENT_FUNC= 'cw_itComponentTree_event', $
                         PRO_SET_VALUE= 'cw_itComponentTree_setvalue', $
                         FUNC_GET_VALUE= 'cw_itComponentTree_getvalue', $
                         uname=uname, uvalue=uvalue)

  ;; our tree
  useContext = ~KEYWORD_SET(noContext)
  wTree = WIDGET_TREE( wWrapper, CONTEXT_EVENTS=useContext, $
    _EXTRA=_extra)

    if (useContext) then begin
        wContext = WIDGET_BASE(wWrapper, /CONTEXT_MENU)
        wHelp = WIDGET_BUTTON(wContext, $
                              VALUE=IDLitLangCatQuery('UI:cwCompTree:Help'), $
                              EVENT_PRO='cw_itComponentTree_help', UVALUE=wWrapper)
    endif else $
        wContext = 0L

  state = { oRoot       : oRoot, $
            oUI         : oUI, $
            oTool       : oUI->GetTool(), $
            wTree       : wTree, $
            wContext    : wContext }

  ;; stash our state
  WIDGET_CONTROL, wTree, SET_UVALUE=state, /no_copy

  ;; Just build the tree at the root.
  cw_itcomponenttree_addLevel, wTree, oRoot, /expanded

  return, wWrapper

END
