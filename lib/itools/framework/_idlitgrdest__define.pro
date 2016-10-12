; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitgrdest__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;  _IDLitgrDest
;
; PURPOSE:
;    This class encapulsates the functionality of the
;    _IDLitgrDest.
;
; CATEGORY:
;   Components
;
; MODIFICATION HISTORY:
;   Written by:
;-


;----------------------------------------------------------------------------
; _IDLitgrDest::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[_IDLitgrDest::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro _IDLitgrDest::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'ZOOM_ON_RESIZE', /BOOLEAN, $
            NAME='Zoom on Resize', $
            DESCRIPTION='Zoom window contents if window is resized'

        self->RegisterProperty, 'VIRTUAL_WIDTH', /INTEGER, $
            NAME='Window width', $
            DESCRIPTION='Minimum canvas width in pixels', /ADVANCED_ONLY

        self->RegisterProperty, 'VIRTUAL_HEIGHT', /INTEGER, $
            NAME='Window height', $
            DESCRIPTION='Minimum canvas height in pixels', /ADVANCED_ONLY

        self->RegisterProperty, 'DRAG_QUALITY', $
                                ENUMLIST=['Low','Medium','High'], $
                                NAME="Drag quality", $
                                DESCRIPTION='Drag quality'
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'CURRENT_ZOOM', /FLOAT, /HIDE, /ADVANCED_ONLY

        ; Needs to be registered for Undo/Redo to work with View Pan.
        self->RegisterProperty, 'VISIBLE_LOCATION', USERDEF='', /HIDE, $
            NAME='Visible location', $
            DESCRIPTION='Location of visible portion of window', /ADVANCED_ONLY

        self->RegisterProperty, 'NAME', /STRING, /HIDE, /ADVANCED_ONLY
    endif
end

;----------------------------------------------------------------------------
; _IDLitgrDest::Init
;
; Purpose:
;   Used to create an instance of a _IDLitgrDest. When created, this
;   wil also get the associated IDLitgrScene and set it as the
;   container object for the _IDLitContainer class.
;

function _IDLitgrDest::Init, $
    NAME=name, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    HEAP_NOSAVE, self

    if (~self->IDLitiMessaging::Init(_EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitLayoutManager::Init())then $
      return, 0

    ; Register all properties.
    self->_IDLitgrDest::_RegisterProperties

    ; This is required...due to internal issues with class intialization
    if(n_elements(name) eq 0)then $
        name = "Window"
    self->IDLitComponent::SetProperty, NAME=name, ICON='window'

    ; The scene is what contains our children. Get the
    ; created scene and set it as the container for identifier
    ; operations.
    oScene = self->GetScene()
    if (~self->_IDLitContainer::Init(CLASSNAME='IDLitgrScene', $
        CONTAINER=oScene)) then $
        return, 0
    oScene->SetProperty, _PARENT=self

    self->RegisterLayout, 'IDLitLayoutFreeform', NAME='Freeform'
    self->RegisterLayout, 'IDLitLayoutGrid', NAME='Gridded'
    self->RegisterLayout, 'IDLitLayoutInset', NAME='Inset', /LOCKGRID
    self->RegisterLayout, $
        'IDLitLayoutTrio', NAME='Trio-Top', TRIO_TYPE=0, /LOCKGRID
    self->RegisterLayout, $
        'IDLitLayoutTrio', NAME='Trio-Bottom', TRIO_TYPE=1, /LOCKGRID
    self->RegisterLayout, $
        'IDLitLayoutTrio', NAME='Trio-Left', TRIO_TYPE=2, /LOCKGRID
    self->RegisterLayout, $
        'IDLitLayoutTrio', NAME='Trio-Right', TRIO_TYPE=3, /LOCKGRID

    ; Notifier for the selection state.
    self._oselNotifier =  obj_new('IDLitNotifier', 'OnSelectionChange')

    self._dragQuality = 2  ; high by default

    self._autoResize = 1b

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitgrDest::SetProperty, _EXTRA=_extra

    return, 1

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    _IDLitgrDest::Cleanup
;
; PURPOSE:
;    Performs all cleanup for the object.
;
;-
pro _IDLitgrDest::Cleanup

    compile_opt idl2, hidden

    ; Cleanup the superclasses.
    self->_IDLitLayoutManager::Cleanup

    self._oSelNotifier->Remove, /all
    obj_destroy, self._oSelNotifier
end


;----------------------------------------------------------------------------
; _IDLitgrDest::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro _IDLitgrDest::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    ; self->_IDLitContainer::Restore
    ; self->_IDLitLayoutManager::Restore
    ; self->IDLitIMessaging::Restore

    if (self.idlitcomponentversion lt 620) then $
        self._autoResize = 1b

    ; Register new properties.
    self->_IDLitgrDest::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;---------------------------------------------------------------------------
; _IDLitgrDest::Add
;
; Purpose:
;   Override the _IDLitContainer::Add for error checking.
;
;  _NO_CURRENT: If set, do not make the newly added view to be current.
;
pro _IDLitgrDest::Add, oitem, $
    SET_CURRENT=setCurrent, $    ; undocumented keyword
    _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (OBJ_ISA(oItem, 'IDLitgrScene')) then begin
        self->ErrorMessage, 'Window may only contain one scene.', SEVERITY=2
        return
    endif

    ; b/c of the "hot potato" method of passing the item to the
    ; desired location, prevent container from sending a notify. This
    ; is needed b/c of how the add will progress.

    ; Setting _bIsMessager will fool Add into not notifying,
    ; but still allow NO_NOTIFY to pass thru in _extra.
    self._bIsMessager = 0b
    self->_IDLitContainer::Add, oItem, _EXTRA=_extra
    self._bIsMessager = 1b

    ; Set new view as current.
    if (KEYWORD_SET(setCurrent) && OBJ_ISA(oItem, 'IDLitgrView')) then $
        self->SetCurrentView, oItem

end


;----------------------------------------------------------------------------
pro _IDLitgrDest::GetProperty, $
    AUTO_RESIZE=autoResize, $
    ZOOM_ON_RESIZE=zoomOnResize, $
    DRAG_QUALITY=dragQuality, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(zoomOnResize)) then $
        zoomOnResize = self._zoomOnResize

    IF ARG_PRESENT(dragQuality) THEN $
      dragQuality = self._dragQuality

    if (ARG_PRESENT(autoResize)) then $
        autoResize = self._autoResize

    ; Get our superclass properties.
    self->_IDLitLayoutManager::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro _IDLitgrDest::SetProperty, $
    AUTO_RESIZE=autoResize, $
    ZOOM_ON_RESIZE=zoomOnResize, $
    DRAG_QUALITY=dragQuality, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(autoResize) gt 0) then begin
        self._autoResize = KEYWORD_SET(autoResize)
        self->SetPropertyAttribute, ['VIRTUAL_HEIGHT', 'VIRTUAL_WIDTH'], $
            SENSITIVE=~self._autoResize
    endif

    IF n_elements(dragQuality) EQ 1 THEN $
      self._dragQuality = dragQuality

    IF n_elements(zoomOnResize) EQ 1 THEN $
        self._zoomOnResize = zoomOnResize

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitLayoutManager::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   Edit user-defined properties.
;   Called automatically from the Property Sheet.
;
; Result:
;   Returns 1 for success, 0 for failure.
;
; Arguments:
;   Tool: Objref for the tool.
;
;   PropertyIdentifier: Property name.
;
; Keywords:
;   None.
;
function _IDLitgrDest::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    ; Call my superclass. Right now this is the only superclass that
    ; has a userdef property.
    return, self->_IDLitLayoutManager::EditUserDefProperty(oTool, identifier)

end


;----------------------------------------------------------------------------
; METHODNAME:
;    _IDLitgrDest::OnDataChange
;
; PURPOSE:
;    This procedure method handles
;    notification of pending data changes within the contained
;    visualization hierarchy.
;
; CALLING SEQUENCE:
;    oScene->[_IDLitgrDest::]OnDataChange, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
pro _IDLitgrDest::OnDataChange, oNotifier

    compile_opt idl2, hidden

    oScene = self->GetScene()
    if (OBJ_VALID(oScene)) then $
        oScene->OnDataChange, oNotifier

end


;----------------------------------------------------------------------------
; METHODNAME:
;    _IDLitgrDest::OnDataComplete
;
; PURPOSE:
;    This procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oScene->[_IDLitgrDest::]OnDataComplete, oNotifier
;
pro _IDLitgrDest::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    oScene = self->GetScene()
    if (OBJ_VALID(oScene)) then $
        oScene->OnDataComplete, oNotifier
end


;---------------------------------------------------------------------------
; Observer section
;---------------------------------------------------------------------------
; _IDLitgrDest::AddSelectionObserver
;
; Purpose:
;   Used to register a object as having interest in notification when
;   the selection state of the system changes
;
; Paramaters:
;   oObserver   - The SelectionObjserver. This must implement
;                 the "OnSelectionChange" method.
;
pro _IDLitgrDest::AddSelectionObserver, oObserver

   compile_opt idl2, hidden

   if( obj_hasmethod(oObserver, 'OnSelectionChange') eq 0)then begin
       self->ErrorMessage, SEVERITY=1, $
        IDLitLangCatQuery('Error:Framework:NoOnSelectionChange')
       return
   end

   self._oSelNotifier->Add, oObserver

end


;---------------------------------------------------------------------------
; _IDLitgrDest::RemoveSelectionObserver
;
; Purpose:
;   Used to remove an observer object from the list of observers
;
; Paramaters:
;   oObserver   - The SelectionObserver.
;
pro _IDLitgrDest::RemoveSelectionObserver, oObserver

   compile_opt idl2, hidden

   self._oSelNotifier->Remove, oObserver

end


;---------------------------------------------------------------------------
; _IDLitgrDest::NotifySelectionChange
;
; Purpose:
;   This routine is called when the selection state of the items
;   contained in this window has changed. This will trigger a
;   notification, notifying all interested items that the state has
;   changed.
;
pro _IDLitgrDest::NotifySelectionChange

    compile_opt idl2, hidden

    self._oSelNotifier->Notify, self, CALLBACK='OnSelectionChange'

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method used to hook the scene up to the window.
;
pro _IDLitgrDest::_SetScene, oScene

    compile_opt idl2, hidden

    ; The scene is really our container.
    self->_IDLitContainer::SetProperty, CONTAINER=oScene

    ; Need to set both the scene's parent and the destination.
    oScene->SetProperty, _PARENT=self, DESTINATION=self

end


;-----------------------------------------------------------------------
; Override our superclass method.
;
; Arguments:
;   Pattern: An optional argument giving the string pattern to match.
;       All identifiers within the container that match this pattern
;       (case insensitive) will be returned. If Pattern is not supplied
;       then all identifiers within the container are returned.
;
; Keywords:
;   ANNOTATIONS: Set this keyword to only return identifiers
;       for items within the annotation layer of all views
;       within the graphics window. Setting this keyword
;       is equivalent to specifying the pattern as:
;           '*/ANNOTATION LAYER/' + Pattern
;
;   COUNT: Set this keyword to a named variable in which to return
;       the number of identifiers in Result.
;
;   LEAF_NODES: If this keyword is set then only leaf nodes will
;       be returned. The default is to return all identifiers that
;       match, including containers.
;
;   VISUALIZATIONS: Set this keyword to only return identifiers
;       for items within the visualization layer of all views
;       within the graphics window. Setting this keyword
;       is equivalent to specifying the pattern as:
;           '*/VISUALIZATION LAYER/' + Pattern
;
function _IDLitgrDest::FindIdentifiers, patternIn, $
    ANNOTATIONS=annotations, $
    VISUALIZATIONS=visualizations, $
    COUNT=count, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; If pattern not supplied find all matches.
    p = (N_ELEMENTS(patternIn) gt 0) ? patternIn : '*'

    ; Call our superclass to find all matches.
    matches = self->_IDLitContainer::FindIdentifiers(p, $
        COUNT=count, _EXTRA=_extra)

    IF KEYWORD_SET(visualizations) THEN BEGIN
      wh = WHERE(STRPOS(matches, '/VISUALIZATION LAYER/') NE -1, count)
      matches = (count gt 0) ? matches[wh] : ''
    ENDIF

    IF KEYWORD_SET(annotations) THEN BEGIN
      wh = WHERE(STRPOS(matches, '/ANNOTATION LAYER/') NE -1, count)
      matches = (count gt 0) ? matches[wh] : ''
    ENDIF

    return, matches

end


;---------------------------------------------------------------------------
; Class Definition
;---------------------------------------------------------------------------
pro _IDLitgrDest__Define

    compile_opt idl2, hidden

   void = {_IDLitgrDest, $
        inherits _IDLitContainer, $
        inherits _IDLitLayoutManager, $
        inherits IDLitIMessaging, $
        _oselNotifier : obj_new(), $    ; notifier for selection
        _dragQuality : 0l, $    ; drag quality
        _zoomOnResize: 0b, $           ; zoom contents on window resize
        _autoResize: 0b $
        }

end
