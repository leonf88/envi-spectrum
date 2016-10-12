; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrclipboard__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;  IDLitgrClipboard
;
; PURPOSE:
;    This class encapulsates the functionality of the
;    IDLitgrClipboard.
;
; CATEGORY:
;   Components
;
; MODIFICATION HISTORY:
;   Written by:  AGEH  April 2005
;-


;----------------------------------------------------------------------------
; IDLitgrClipboard::Init
;
; Purpose:
;   Used to create an instance of a IDLitgrClipboard.
;

function IDLitgrClipboard::Init, $
    NAME=name, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLgrClipboard::Init(_EXTRA=_extra))then $
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
;    IDLitgrClipboard::Cleanup
;
; PURPOSE:
;    Performs all cleanup for the object.
;
;-
pro IDLitgrClipboard::Cleanup

    compile_opt idl2, hidden

    ; Cleanup the superclasses.
    self->IDLgrClipboard::Cleanup

end


;----------------------------------------------------------------------------
pro IDLitgrClipboard::GetProperty, $
    CURRENT_ZOOM=currentZoom, $
    MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
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
        self->IDLgrClipboard::GetProperty, DIMENSIONS=virtualDimensions
        virtualWidth = virtualDimensions[0]
        virtualHeight = virtualDimensions[1]
    endif

    if (ARG_PRESENT(visibleLoc)) then $
        visibleLoc = [0, 0]

    ; Get our superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLgrClipboard::GetProperty, _EXTRA=_extra
    endif

end


;----------------------------------------------------------------------------
pro IDLitgrClipboard::SetProperty, $
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
        self->IDLgrClipboard::GetProperty, SCREEN_DIMENSIONS=maxDim
        if (dims[0] gt maxDim[0]) then begin
          dims[1] *= DOUBLE(maxDim[0])/dims[0]
          dims[0] = maxDim[0]
        endif
        if (dims[1] gt maxDim[1]) then begin
          dims[0] *= DOUBLE(maxDim[1])/dims[1]
          dims[1] = maxDim[1]
        endif
        self->IDLgrClipboard::SetProperty, DIMENSIONS=dims
    endif
    
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLgrClipboard::SetProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method used to hook the scene up to the clipboard.
;
pro IDLitgrClipboard::_SetScene, oScene

    compile_opt idl2, hidden

    ; Set our own graphics tree.
    self->IDLgrClipboard::SetProperty, GRAPHICS_TREE=oScene

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrClipboard::GetScene

    compile_opt idl2, hidden

    self->IDLgrClipboard::GetProperty, GRAPHICS_TREE=oScene

    if (~OBJ_VALID(oScene)) then begin
        oScene = OBJ_NEW('IDLitgrScene', self)
        self->IDLgrClipboard::SetProperty, GRAPHICS_TREE=oScene
    endif

    return, oScene
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrClipboard::GetCurrentView

    compile_opt idl2, hidden

    oScene = self->GetScene()
    return, oScene->GetCurrentView()

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrClipboard::GetDimensions, $
    VIRTUAL_DIMENSIONS=virtualDestDims, VISIBLE_LOCATION=visibleLoc

    compile_opt idl2, hidden

    self->IDLgrClipboard::GetProperty, DIMENSIONS=dimensions
    virtualDestDims = dimensions
    visibleLoc = [0,0]

    return, dimensions

end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrClipboard::SetManipulatorManager, oManipMgr

    compile_opt idl2, hidden

    ; Do nothing
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
pro IDLitgrClipboard::SetCurrentCursor, cursor, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Do nothing
end


;---------------------------------------------------------------------------
; This has the same interface as the IDLitWindow method.
;
function IDLitgrClipboard::GetSelectedItems, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oScene = self->GetScene()
    return, oScene->GetSelectedItems(_EXTRA=_extra)

end

;---------------------------------------------------------------------------
; Class Definition
;---------------------------------------------------------------------------
pro IDLitgrClipboard__Define

    compile_opt idl2, hidden

   void = {IDLitgrClipboard, $
        inherits IDLgrClipboard $
        }

end
