; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrwinscene__define.pro#2 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;  IDLitgrWinScene
;
; PURPOSE:
;    This class encapulsates the functionality of the
;    IDLitgrWinScene. This window, a sub-class of IDLitWindow is
;    primarly used to collapse the window and scene into
;    a single object.
;
; CATEGORY:
;   Components
;
; MODIFICATION HISTORY:
;   Written by:
;-


;----------------------------------------------------------------------------
; IDLitgrWinScene::Init
;
; Purpose:
;   Used to create an instance of a IDLitgrWinScene. When created, this
;   wil also get the associated IDLitgrScene and set it as the
;   container object for the _IDLitContainer class.
;
;
function IDLitgrWinScene::Init, $
    NAME=name, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitWindow::Init(_EXTRA=_extra))then $
      return, 0

    if (~self->_IDLitgrDest::Init(_EXTRA=_extra)) then $
        return, 0

    self->IDLitgrWinScene::_RegisterProperties

    ; This is required...due to internal issues with class intialization
    if(n_elements(name) eq 0)then $
        name = "Window"
    self->IDLitComponent::SetProperty, NAME=name, ICON='window'

    return, 1

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrWinScene::Cleanup
;
; PURPOSE:
;    Performs all cleanup for the object.
;
;-
pro IDLitgrWinScene::Cleanup

    compile_opt idl2, hidden

    ; Cleanup the superclasses.
    self->IDLitWindow::Cleanup
    void = CHECK_MATH()  ; swallow arithmetic errors
    self->_IDLitgrDest::Cleanup

end


;----------------------------------------------------------------------------
pro IDLitgrWinScene::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    ; This property was added for IDL62.
    if (registerAll || updateFromVersion lt 620) then begin

        self->RegisterProperty, 'AUTO_RESIZE', /BOOLEAN, $
            NAME='Automatic window resize', $
            DESCRIPTION='Automatically change window dimensions on resize'

    endif

end


;----------------------------------------------------------------------------
; IDLitgrWinScene::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitgrWinScene::Restore

    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitWindow::Restore
    self->_IDLitgrDest::Restore

    ; Register new properties.
    self->IDLitopWindowLayout::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

end


;----------------------------------------------------------------------------
pro IDLitgrWinScene::GetProperty, $
    VIRTUAL_HEIGHT=virtualHeight, $
    VIRTUAL_WIDTH=virtualWidth, $
    MOUSE_MOTION_HANDLER=mMotionHandler, $
    MOUSE_BUTTON_HANDLER=mButtonHandler, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(virtualHeight) || ARG_PRESENT(virtualWidth)) then begin
        self->IDLitWindow::GetProperty, VIRTUAL_DIMENSIONS=virtualDimensions
        virtualWidth = virtualDimensions[0]
        virtualHeight = virtualDimensions[1]
    endif

    if (ARG_PRESENT(mMotionHandler)) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then begin
        oTool->GetProperty, MOUSE_MOTION_HANDLER=mMotionHandler
      endif
    endif

    if (ARG_PRESENT(mButtonHandler)) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then begin
        oTool->GetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler
      endif
    endif

    ; Get our superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->_IDLitgrDest::GetProperty, _EXTRA=_extra
        ; Most properties such as VIRTUAL_DIMENSIONS, VISIBLE_LOCATION
        ; will be retrieve directly from the IDLitWindow.
        self->IDLitWindow::GetProperty, _EXTRA=_extra
    endif

end


;----------------------------------------------------------------------------
pro IDLitgrWinScene::SetProperty, $
    ZOOM_ON_RESIZE=zoomOnResize, $
    CURRENT_ZOOM=currentZoom, $
    MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
    VIRTUAL_DIMENSIONS=virtualDimensions, $
    VIRTUAL_HEIGHT=virtualHeight, $
    VIRTUAL_WIDTH=virtualWidth, $
    VISIBLE_LOCATION=visibleLocation, $
    MOUSE_MOTION_HANDLER=mMotionHandler, $
    MOUSE_BUTTON_HANDLER=mButtonHandler, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    ; ZOOM_ON_RESIZE
    if (N_ELEMENTS(zoomOnResize) eq 1) then begin
        self._zoomOnResize = KEYWORD_SET(zoomOnResize)
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            ; Notify our checked menu item.
            id = oTool->GetFullIdentifier()+"/OPERATIONS/WINDOW/ZOOMRESIZE"
            oTool->DoOnNotify, id, 'SELECT', self._zoomOnResize
        endif
    endif


    ; Intercept our CURRENT_ZOOM so we can do a UI update.
    if (N_ELEMENTS(currentZoom) eq 1) then begin
        oTool = self->GetTool()
        self->IDLitWindow::GetProperty, CURRENT_ZOOM=oldZoom
        if (oldZoom ne currentZoom) then begin
            self->SetCurrentZoom, currentZoom
            ;; Send out notification.  If scroll bars are added or
            ;; removed during a zoom factor change this will change
            ;; the overall size of the window.  To counter that, the
            ;; IDLitwdTool listens for these notifications and sets
            ;; the window size back to what it was.
            self->DoOnNotify, oTool->GetFullIdentifier(), 'CANVAS_ZOOM', 0b
          endif
        if (OBJ_VALID(oTool)) then begin
          ; Update the view zoom control in the toolbar.
          id = oTool->GetFullIdentifier() + "/TOOLBAR/VIEW/VIEWZOOM"
          oTool->DoOnNotify, id, 'SETVALUE', $
            STRTRIM(ULONG((currentZoom*100)+0.5),2)+'%'
        endif
    endif


    ; VIRTUAL_HEIGHT and VIRTUAL_WIDTH are just different ways to
    ; set the VIRTUAL_DIMENSIONS. However, setting VIRTUAL_HEIGHT or
    ; VIRTUAL_WIDTH will also set the minimum_virtual_dims to the same values.
    if (N_ELEMENTS(virtualHeight) || N_ELEMENTS(virtualWidth)) then begin

        self->GetProperty, MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
            VIRTUAL_DIMENSIONS=virtualDimensions

        if (N_ELEMENTS(virtualWidth)) then begin
            virtualDimensions[0] = virtualWidth > 1
            minimumVirtualDims[0] = virtualDimensions[0]
        endif
        if (N_ELEMENTS(virtualHeight)) then begin
            virtualDimensions[1] = virtualHeight > 1
            minimumVirtualDims[1] = virtualDimensions[1]
        endif

        ; The MINIMUM_VIRTUAL_DIMENSIONS and VIRTUAL_DIMENSIONS will
        ; actually get set below.

    endif

    ; Set our superclass properties.
    if ((N_ELEMENTS(virtualDimensions) gt 0) || $
        (N_ELEMENTS(minimumVirtualDims) gt 0) || $
        (N_ELEMENTS(visibleLocation) gt 0) || $
        (N_ELEMENTS(_extra) gt 0)) then begin
        self->IDLitWindow::SetProperty, $
            MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
            VISIBLE_LOCATION=visibleLocation, $
            VIRTUAL_DIMENSIONS=virtualDimensions, $
            _EXTRA=_extra
; CT, RSI: Disable notification for now. Otherwise the base widget
; will be automatically resized. We may want this behavior in the future.
;        oTool = self->GetTool()
;        if (N_ELEMENTS(virtualDimensions) gt 0) && obj_valid(oTool) then begin
;            oTool->DoOnNotify, oTool->GetFullIdentifier(), $
;                'VIRTUAL_DIMENSIONS', virtualDimensions
;        endif
    endif

    if (N_ELEMENTS(virtualDimensions) eq 2) then begin
        ; We really care about the change in virtual dims,
        ; but OnResize expects the visible dimensions,
        ; so retrieve this from the window and pass it in.
        self->IDLgrWindow::GetProperty, DIMENSIONS=dimensions, $
            VISIBLE_LOCATION=destScrollLoc
        oScene = self->GetScene()
        oScene->OnResize, self, dimensions[0], dimensions[1]
        ; Force the scroll location to be updated.
        self->OnScroll, destScrollLoc[0], destScrollLoc[1]
    endif else if (N_ELEMENTS(visibleLocation) eq 2) then begin
        self->IDLgrWindow::GetProperty, VISIBLE_LOCATION=destScrollLoc

        ; Force the scroll location to be updated.
        oScene = self->GetScene()
        oScene->OnScroll, destScrollLoc[0], destScrollLoc[1]
    endif

    if (N_ELEMENTS(mMotionHandler) eq 1) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then begin
        oTool->SetProperty, MOUSE_MOTION_HANDLER=mMotionHandler
      endif
    endif

    if (N_ELEMENTS(mButtonHandler) eq 1) then begin
      oTool = self->GetTool()
      if (OBJ_VALID(oTool)) then begin
        oTool->SetProperty, MOUSE_BUTTON_HANDLER=mButtonHandler
      endif
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitgrDest::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method used to hook the scene up to the window.
;
pro IDLitgrWinScene::_SetScene, oScene

    compile_opt idl2, hidden

    ; Call our superclass to set the container and fix the scene.
    self->_IDLitgrDest::_SetScene, oScene

    ; Set our own graphics tree.
    self->IDLgrWindow::SetProperty, GRAPHICS_TREE=oScene

    ; Set our IDLitWindow field.
    self.scene = oScene

end


;---------------------------------------------------------------------------
; Class Definition
;---------------------------------------------------------------------------
pro IDLitgrWinScene__Define

    compile_opt idl2, hidden

   void = {IDLitgrWinScene, $
           inherits IDLitWindow, $
           inherits _IDLitgrDest $
          }

end
