; $Id: //depot/idl/releases/IDL_80/idldir/lib/widget_tree_move.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   WIDGET_TREE_MOVE
;
; PURPOSE:
;   Moves or copies tree widget nodes from one tree to another.  The
;   source and destination trees can be the same tree.
;
; CALLING SEQUENCE:
;   WIDGET_TREE_MOVE, wMoveNodes, wDestFolder [, INDEX = index]
;     [, /COPY] [, /SELECT] [, UPDATE = value]
;     [, CALLBACK_FUNC = name] [, USERDATA = value]
;
; POSITIONAL PARAMETERS:
;   wMoveNodes: The set of nodes to move or copy.
;   wDestFolder: Folder (or root) to move (or copy) the wMoveNodes.
;
; KEYWORD PARAMETERS:
;   INDEX:    The relative position at which to insert wMoveNodes
;             into the wDestFolder.  The position is zero-based and
;             a value of -1 inserts at the tail.  This is the default.
;   COPY:     Set this keyword to make a copy of wMoveNodes.  If
;             not set then the original wMoveNodes will be destroyed.
;   SELECT:   Set this keyword to select the newly moved/copied nodes.
;   UPDATE:   Set this keyword to allow the trees to be visually
;             updated during the operation.  The default is to turn
;             updates off to prevent flickering.
;   CALLBACK_FUNC: Specifies the name of a function that provides
;             custom node duplication.  It is called by WIDGET_TREE_MOVE's
;             internal recursive copy routine immediately after each
;             node duplication for the full "wMoveNodes" hierarchies.
;             If the callback returns a non-zero value then current
;             node's children are also copied.
;   USERDATA: Provides a value to the callback.
;
; DESCRIPTION:
;   The WIDGET_TREE_MOVE procedure provides a convenient way to copy
;   and move nodes between or within trees.
;
;   The two parameters specifiy the widget IDs of the nodes to copy
;   and the folder (or root) in which to move (or copy) them.  If the
;   "wMoveNodes" contains nodes whose ancestors are also in the list,
;   then those nodes will be copied more than once.  This situation can
;   be avoided by using the TREE_DRAG_SELECT keyword to WIDGET_INFO,
;   which removes "duplicate" nodes from a tree's current selection.
;
;   The INDEX keyword can be used to insert the moved nodes into a
;   particular position within the destination folder.  This keyword
;   behaves the same as WIDGET_TREE's INDEX keyword.  The default is
;   to insert the moved nodes at the end of the current list of children.
;
;   The COPY keyword prevents deletion of the nodes specified in
;   wMoveNodes.
;
;   The SELECT keyword can be used to specify that the moved nodes
;   should be selected.  If this keyword is not set then the source
;   and destination trees' selection states are not altered (except a
;   move operation can deslect nodes by virtue of node destruction).
;
;   The UPDATE keyword can be used to intentionally allow tree widget
;   updates during the move/copy.  If this keyword is not set, then
;   the default is to turn updates off to prevent flickering.
;
;   The CALLBACK_FUNC keyword allows for customized node duplication.
;   This is possible because the internal node duplication procedure
;   invokes the callback immediately after each source node is duplicated.
;   The callback must be defined as follows:
;
;     FUNCTION Name, wOriginalNode, wNewNode, USERDATA = value
;
;   If user data was supplied to WIDGET_TREE_MOVE, then it will be
;   passed to the callback.  Before the callback is invoked, the new
;   node is created with all of the commonly used widget properties of
;   the original node.  The callback can be used to change these
;   values (e.g. UVALUE that references a significant amount of memory).
;   The callback's return value indicates whether or not copying should
;   continue for the current node.  A non-zero value means "continue"
;   and a value of zero means "stop".  Always returning zero produces a
;   "flat copy", with no recursive traversal to children.
;
;   The following properites are automatically inherited by new nodes:
;
;     FOLDER, EXPANDED
;     BITMAP, MASK
;     DRAGGABLE, DRAG_NOTIFY, DROP_EVENTS
;     VALUE, UVALUE, UNAME
;     EVENT_FUNC, EVENT_PRO
;
;   The NO_COPY keyword is set when moving, but not when copying.  This
;   allows for an efficient transfer of large data during a move.  The
;   following tree widget properties are not transfered:
;
;     FUNC_GET_VALUE, PRO_SET_VALUE
;     NOTIFY_REALIZE, KILL_NOTIFY
;
;   If these keywords must be set then the new node should be destroyed
;   and recreated in the callback (with the same parent and index).
;   An alternative is to write a fully custom version of WIDGET_TREE_MOVE.
;
; MODIFICATION HISTORY:
;   Written by:  DRE, RSI, November 2005
;   Modified:
;
;-

; widget_tree_duplicate_node
;
; Duplicates a node and inserts the copy into a specific position
; in the given parent (folder or root).  If a callback is provided
; then just after creation, the callback is invoked.  This allows
; the user to alter the newly created node (and the original!)

function widget_tree_duplicate_node, wParent, wOriginalNode, $
  copyChildren, INDEX = index, COPY = cp, $
  CALLBACK_FUNC = cb, USERDATA = ud

  compile_opt hidden, idl2
  ON_ERROR, 2


  WIDGET_CONTROL, wOriginalNode, $
    GET_VALUE = value, GET_UVALUE = uvalue, $
    NO_COPY = ~KEYWORD_SET( cp )

  temp = WIDGET_INFO( wOriginalNode, /UNAME )
  if ( STRLEN( temp ) gt 0 ) then $
    uname = temp

  temp = WIDGET_INFO( wOriginalNode, /EVENT_FUNC )
  if ( STRLEN( temp ) gt 0 ) then $
    eventFunc = temp

  temp = WIDGET_INFO( wOriginalNode, /EVENT_PRO )
  if ( STRLEN( temp ) gt 0 ) then $
    eventPro = temp

  wNewNode = WIDGET_TREE( wParent, $
    INDEX = index, $
    FOLDER = WIDGET_INFO( wOriginalNode, /TREE_FOLDER ), $
    EXPANDED = WIDGET_INFO( wOriginalNode, /TREE_EXPANDED ), $
    BITMAP = WIDGET_INFO( wOriginalNode, /TREE_BITMAP ), $
    MASK = WIDGET_INFO( wOriginalNode, /MASK ), $
    DRAGGABLE = WIDGET_INFO( wOriginalNode, /DRAGGABLE ), $
    DRAG_NOTIFY = WIDGET_INFO( wOriginalNode, /DRAG_NOTIFY ), $
    DROP_EVENTS = WIDGET_INFO( wOriginalNode, /DROP_EVENTS ), $
    VALUE = value, $
    UVALUE = uvalue, $
      NO_COPY = ~KEYWORD_SET( cp ), $
    UNAME = uname, $
    EVENT_FUNC = eventFunc, $
    EVENT_PRO = eventPro )

  if ( N_ELEMENTS( cb ) ne 0 ) then $
    copyChildren = $
      CALL_FUNCTION( cb, wOriginalNode, wNewNode, USERDATA = ud ) $
  else $
    copyChildren = 1

  RETURN, wNewNode

end

; widget_tree_copy_tree
;
; Copies a node and its entire hierarchy to the given parent at
; the given position.  This procedure recursively copies folders.

function widget_tree_copy_tree, wParent, wOriginalNode, $
  INDEX = index, COPY = cp, CALLBACK_FUNC = cb, USERDATA = ud

  compile_opt hidden, idl2
  ON_ERROR, 2

  newNode = widget_tree_duplicate_node( wParent, wOriginalNode, $
    copyChildren, INDEX = index, COPY = cp, $
    CALLBACK_FUNC = cb, USERDATA = ud )

  if ( N_ELEMENTS( copyChildren ) gt 0 && $
       copyChildren ne 0 ) then begin

    children = WIDGET_INFO( wOriginalNode, /ALL_CHILDREN )
    for i = 0, WIDGET_INFO( wOriginalNode, /N_CHILDREN ) - 1 do $
      newChild = widget_tree_copy_tree( newNode, children[i], $
        COPY = cp, CALLBACK_FUNC = cb, USERDATA = ud )

  endif

  RETURN, newNode

end

; widget_tree_set_updating
;
; Turns tree widget updates on or off.  If many, many nodes are
; being copied then flickering can occur.

function widget_tree_set_updating, wRoot, update

  compile_opt idl2
  ON_ERROR, 2

  prevUpdate = WIDGET_INFO( wRoot, /UPDATE )
  WIDGET_CONTROL, wRoot, UPDATE = update

  return, prevUpdate

end

; widget_tree_move
;
; Moves or copies tree widget nodes from one tree to another.  The
; source and destination trees can be the same tree.

pro widget_tree_move, wMoveNodes, wDestFolder, INDEX = index, $
  COPY = copy, SELECT = select, UPDATE = update, $
  CALLBACK_FUNC = cb, USERDATA = ud

  compile_opt idl2
  ON_ERROR, 2


  if ( N_PARAMS() ne 2 ) then $
    MESSAGE, 'Incorrect number of arguments.'

  ; pre-process the keywords
  ;
  ; If inserting at a specific position then copy them in reverse
  ; order so that they end up inserted in a more expected, top-down
  ; order.

  x = ( N_ELEMENTS( index ) eq 0 ) ? -1 : index

  wNodes = ( x ge 0 ) ? REVERSE( wMoveNodes ) : wMoveNodes

  if ( ~KEYWORD_SET( update ) ) then $
    update = 0

  ; temporarily turn drawing off to prevent flickering

  if ( ~update ) then begin

    wSourceRoot = WIDGET_INFO( wMoveNodes[0], /TREE_ROOT )
    wDestRoot   = WIDGET_INFO( wDestFolder, /TREE_ROOT )

    prevSourceUpdate = widget_tree_set_updating( wSourceRoot, 0 )
    prevDestUpdate = widget_tree_set_updating( wDestRoot, 0 )

  endif

  ; copy each of the nodes (and the hierarchy it roots)

  for i = 0, N_ELEMENTS( wNodes ) - 1 do begin

    newNode = widget_tree_copy_tree( wDestFolder, wNodes[i], $
      INDEX = x, COPY = copy, CALLBACK_FUNC = cb, USERDATA = ud )

    if ( KEYWORD_SET( select ) ) then $
      WIDGET_CONTROL, newNode, /SET_TREE_SELECT

  endfor

  ; turn the copy into a move?

  if ( ~KEYWORD_SET( copy ) ) then begin

    for i = N_ELEMENTS( wNodes ) - 1, 0, -1 do $
      WIDGET_CONTROL, wNodes[i], /DESTROY

  endif

  ; restore original update settings

  if ( ~update ) then begin

    temp = widget_tree_set_updating( wDestRoot, prevDestUpdate )
    temp = widget_tree_set_updating( wSourceRoot, prevSourceUpdate )

  end

end