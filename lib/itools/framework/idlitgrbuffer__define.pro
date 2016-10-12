; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrbuffer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;  IDLitgrBuffer
;
; PURPOSE:
;    This class encapulsates the functionality of the
;    IDLitgrBuffer. This window, a sub-class of IDLgrBuffer is
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
; IDLitgrBuffer::Init
;
; Purpose:
;   Used to create an instance of a IDLitgrBuffer. When created, this
;   wil also get the associated IDLitgrScene and set it as the
;   container object for the _IDLitContainer class.
;

function IDLitgrBuffer::Init, $
    NAME=name, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLgrBuffer::Init(_EXTRA=_extra))then $
      return, 0

    if (~self->_IDLitgrDest::Init(_EXTRA=_extra)) then $
        return, 0

    ; This is required...due to internal issues with class intialization
    if(n_elements(name) eq 0)then $
        name = "Window"
    self->IDLitComponent::SetProperty, NAME=name, ICON='window'


    return, 1

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrBuffer::Cleanup
;
; PURPOSE:
;    Performs all cleanup for the object.
;
;-
pro IDLitgrBuffer::Cleanup

    compile_opt idl2, hidden

    ; Cleanup the superclasses.
    self->IDLgrBuffer::Cleanup
    self->_IDLitgrDest::Cleanup

end


;----------------------------------------------------------------------------
pro IDLitgrBuffer::GetProperty, $
    CURRENT_ZOOM=currentZoom, $
    MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
    VIEWPORT_DIMENSIONS=viewportDims, $
    VIRTUAL_DIMENSIONS=virtualDimensions, $
    VIRTUAL_HEIGHT=virtualHeight, $
    VIRTUAL_WIDTH=virtualWidth, $
    VISIBLE_LOCATION=visibleLoc, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(currentZoom)) then $
        currentZoom = 1d

    if (ARG_PRESENT(minimumVirtualDims)) then $
        minimumVirtualDims = [0, 0]

    if (ARG_PRESENT(virtualHeight) || ARG_PRESENT(virtualWidth) || $
        ARG_PRESENT(virtualDimensions)) then begin
        self->IDLgrBuffer::GetProperty, DIMENSIONS=virtualDimensions
        virtualWidth = virtualDimensions[0]
        virtualHeight = virtualDimensions[1]
    endif

    if (ARG_PRESENT(viewportDims)) then begin
        self->IDLgrBuffer::GetProperty, DIMENSIONS=viewportDims
    endif

    if (ARG_PRESENT(visibleLoc)) then $
        visibleLoc = [0, 0]

    ; Get our superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->_IDLitgrDest::GetProperty, _EXTRA=_extra
        self->IDLgrBuffer::GetProperty, _EXTRA=_extra
    endif

end


;----------------------------------------------------------------------------
pro IDLitgrBuffer::SetProperty, $
    DIMENSIONS=dimensions, $
    MINIMUM_VIRTUAL_DIMENSIONS=swallow1, $
    VIRTUAL_DIMENSIONS=virtualDimensions, $
    VIRTUAL_HEIGHT=virtualHeight, $
    VIRTUAL_WIDTH=virtualWidth, $
    VISIBLE_LOCATION=swallow2, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; VIRTUAL_HEIGHT and VIRTUAL_WIDTH are just different ways to
    ; set the VIRTUAL_DIMENSIONS. However, setting VIRTUAL_HEIGHT or
    ; VIRTUAL_WIDTH will also set the minimum_virtual_dims to the same values.
    if (N_ELEMENTS(virtualHeight) || N_ELEMENTS(virtualWidth)) then begin

        self->GetProperty, VIRTUAL_DIMENSIONS=virtualDimensions

        if (N_ELEMENTS(virtualWidth)) then begin
            virtualDimensions[0] = virtualWidth > 1
        endif
        if (N_ELEMENTS(virtualHeight)) then begin
            virtualDimensions[1] = virtualHeight > 1
        endif

        ; The VIRTUAL_DIMENSIONS will actually get set below.

    endif

    ; Set our superclass properties.
    if (N_ELEMENTS(virtualDimensions) || N_ELEMENTS(dimensions)) then begin
        dims = (N_ELEMENTS(virtualDimensions) gt 0) ? $
          virtualDimensions : dimensions
        self->IDLgrBuffer::GetProperty, SCREEN_DIMENSIONS=maxDim
        if (dims[0] gt maxDim[0]) then begin
          dims[1] *= DOUBLE(maxDim[0])/dims[0]
          dims[0] = maxDim[0]
        endif
        if (dims[1] gt maxDim[1]) then begin
          dims[0] *= DOUBLE(maxDim[1])/dims[1]
          dims[1] = maxDim[1]
        endif
        self->IDLgrBuffer::SetProperty, DIMENSIONS=dims
    endif

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLgrBuffer::SetProperty, _EXTRA=_extra
        self->_IDLitgrDest::SetProperty, _EXTRA=_extra
    endif

    if (N_ELEMENTS(virtualDimensions) eq 2) then begin
        ; Pass the dimensions on to our scene.
        oScene = self->GetScene()
        oScene->OnResize, self, virtualDimensions[0], virtualDimensions[1]
    endif
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::AddWindowEventObserver, Obs

    compile_opt idl2, hidden

    ; Do nothing

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::ClearSelections

    compile_opt idl2, hidden

    oScene = self->GetScene()
    oScene->ClearSelections

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrBuffer::GetCurrentView

    compile_opt idl2, hidden

    oScene = self->GetScene()
    return, oScene->GetCurrentView()

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrBuffer::GetDimensions, $
    VIRTUAL_DIMENSIONS=virtualDestDims, VISIBLE_LOCATION=visibleLoc

    compile_opt idl2, hidden

    self->IDLgrBuffer::GetProperty, DIMENSIONS=dimensions
    virtualDestDims = dimensions
    visibleLoc = [0,0]

    return, dimensions

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrBuffer::GetEventMask, BUTTON_EVENTS=buttonEvents, $
    KEYBOARD_EVENTS=keyEvents, MOTION_EVENTS=motionEvents, $
    TIMER_EVENTS=timerEvents, TRACKING_EVENTS=trackEvents

    compile_opt idl2, hidden

    ; No events are allowed for the buffer.
    if ARG_PRESENT(buttonEvents) then buttonEvents = 0
    if ARG_PRESENT(keyEvents) then keyEvents = 0
    if ARG_PRESENT(motionEvents) then motionEvents = 0
    if ARG_PRESENT(timerEvents) then timerEvents = 0
    if ARG_PRESENT(trackEvents) then trackEvents = 0

    return, 0
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrBuffer::GetScene

    compile_opt idl2, hidden

    self->IDLgrBuffer::GetProperty, GRAPHICS_TREE=oScene

    if (~OBJ_VALID(oScene)) then begin
        oScene = OBJ_NEW('IDLitgrScene', self)
        self->IDLgrBuffer::SetProperty, GRAPHICS_TREE=oScene
    endif

    return, oScene
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrBuffer::GetSelectedItems, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oScene = self->GetScene()
    return, oScene->GetSelectedItems(_EXTRA=_extra)

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::OnScroll, x, y

    compile_opt idl2, hidden

    oScene = self->GetScene()
    oScene->OnScroll, x, y

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::RemoveWindowEventObserver, Obs

    compile_opt idl2, hidden

    ; Do nothing

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::SetCurrentCursor, cursor, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Do nothing
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::SetCurrentZoom, zoom, RESET=reset

    compile_opt idl2, hidden

    ; For now do nothing. We should probably handle the zoom, but it
    ; is pretty complicated, and is based on a lot of IDLgrWindow code,
    ; not on a common superclass of grWindow and grBuffer.

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::SetManipulatorManager, oManipMgr

    compile_opt idl2, hidden

    ; Do nothing
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::SetEventMask, eventMask, _EXTRA=_extra

    compile_opt idl2, hidden

    ; No events are allowed for the buffer.
    ; Do nothing.

 end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::ZoomIn

    compile_opt idl2, hidden

;    self->SetCurrentZoom, zoom

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrBuffer::ZoomOut

    compile_opt idl2, hidden

;    self->SetCurrentZoom, zoom

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method used to hook the scene up to the buffer.
;
pro IDLitgrBuffer::_SetScene, oScene

    compile_opt idl2, hidden

    ; Call our superclass to set the container and fix the scene.
    self->_IDLitgrDest::_SetScene, oScene

    ; Set our own graphics tree.
    self->IDLgrBuffer::SetProperty, GRAPHICS_TREE=oScene

end


;---------------------------------------------------------------------------
; Class Definition
;---------------------------------------------------------------------------
pro IDLitgrBuffer__Define

    compile_opt idl2, hidden

   void = {IDLitgrBuffer, $
        inherits IDLgrBuffer, $
        inherits _IDLitgrDest $
        }

end
