; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrannotatelayer__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitgrAnnotateLayer
;
; PURPOSE:
;    The IDLitgrAnnoateLayer class represents a layer (within a View) in
;    which annotations are drawn. This is a 2d layer for "on-glass" annotations.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitGrLayer
;-

;----------------------------------------------------------------------------
; IDLitgrAnnotateLayer::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitgrAnnotateLayer::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitgrAnnotateLayer::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
      ; Hide properties that do not apply to the annotation layer.
      self->SetPropertyAttribute, ["PERSPECTIVE", "STRETCH_TO_FIT"], /HIDE
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        ; Hide properties that do not apply to the annotation layer.
        self->SetPropertyAttribute, ["DEPTHCUE_BRIGHT", "DEPTHCUE_DIM", $
            "XMARGIN", "YMARGIN"], $
            /HIDE
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrAnnotateLayer::Init
;
; PURPOSE:
;    Initializes an IDLitgrLayer object.
;
; KEYWORD PARAMETERS:
;    <Accepts all keywords accepted by the superclasses, plus the following:>
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 if initialization
;    fails.
;
;-
function IDLitgrAnnotateLayer::Init, $
                     _EXTRA=_extra

    compile_opt idl2, hidden

    ;; turn off lights and make this layer transparent.
    if( self->IDLitgrLayer::Init(/transparent, $
        NAME='Annotation Layer', $
        _extra=_extra) eq  0)then $
      return, 0

    ; Register all properties.
    self->IDLitgrAnnotateLayer::_RegisterProperties

    ;; We want to hide the data space, so the following is done to
    ;; jump over it.
    oDS = self->GetCurrentDataspace()
    if (OBJ_VALID(oDS) ne 0) then begin
        oDS->SetProperty, _PARENT=self
        success = self->_IDLitContainer::Init(CLASSNAME=obj_class(oDS), $
            container=oDS)
    endif else $
        success = self->_IDLitContainer::Init()
   return, 1
end

;----------------------------------------------------------------------------
; IDLitgrAnnotateLayer::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitgrAnnotateLayer::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitgrLayer::Restore

    ; Adjust property attributes.
    self->IDLitgrAnnotateLayer::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        self->IDLitComponent::SetProperty, IDENTIFIER='ANNOTATION LAYER'
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitgrAnnotateLayer::GetWorld
;
; PURPOSE:
;   Retrieves the World associated with this Layer.
;
; CALLING SEQUENCE:
;   oWorld = oLayer->[IDLitgrAnnotateLayer::]GetWorld()
;
; OUTPUTS:
;   This function method returns a reference to an IDLitgrWorld.
;
; NOTES:
;   This overrides the implementation of IDLitGrLayer::GetWorld so
;   that the containment skipping within the annotation layer can be
;   taken into account.
;-
function IDLitgrAnnotateLayer::GetWorld

    compile_opt idl2, hidden

    oObjs = self->IDLgrView::Get(/ALL, ISA='IDLitGrWorld', COUNT=nWorld)

    if (nWorld gt 0) then $
        return, oObjs[0] $
    else $
        return, OBJ_NEW()
end

;;---------------------------------------------------------------------------
;; IDLitGrAnnotateLayer::add
;;
;; Purpose:
;;   Override the add method to set some parameter/properties on the
;;   items being added to the layer.
;;
PRO IDLitGrAnnotateLayer::Add, oItem, _extra=_extra
   compile_opt hidden, idl2

   nItem = n_elements(oItem)
   if(nItem eq 0)then return

   for i=0, nItem-1 do $
       oItem[i]->SetProperty, IMPACTS_RANGE=0, /MANIPULATOR_TARGET

   ;; Note, we override the containers notification to handle the
   ;; _parent issue. Boy, I hate doing this, but in order to skip....
   self->_idlitContainer::Add, oItem, _extra=_extra, /no_notify

   ;; This is done post add to override what the data space does.
   ;; This step will allow use to visually skip over the data space.
   idItems = strarr(nItem)
   for i=0, n_elements(nItem)-1 do begin
       oItem[i]->SetProperty, _PARENT=self
       idItems[i] = oItem[i]->GetFullIdentifier()
   endfor
   ;; Notify that items were added
   self->DoOnNotify, self->GetFullIdentifier(), "ADDITEMS", idItems
end

;----------------------------------------------------------------------------
; IDLitgrAnnotateLayer::OnViewportChange
;
; Purpose:
;   This procedure method handles notfication of a change in viewport
;   dimensions.
;
; Arguments:
;   oView: A reference to the view sending notification.
;
;   oDestination: A reference to the destination in which the view appears.
;
;   virtualViewDims: A 2-element vector, [w,h], representing the new
;     dimensions (in pixels) of the virtual viewport.
;
;   normClipRect: A 4-element vector, [x,y,w,h], representing
;     the (un-canvas-zoomed) visible viewport rectangle (in
;     normalized coordinates relative to the virtual viewport)
;
;   normViewDims: A 2-element vector, [w,h], representing the
;     new dimensions (normalized to the virtual canvas) of the visible
;     viewport.
;
;   bVirtualChange: A boolean flag indicating whether the virtual
;     dimensions changed.
;
;   zoomOnResize: A boolean flag indicating whether data content should
;     zoom when the viewport resizes.
;
pro IDLitgrAnnotateLayer::OnViewportChange, oView, oDestination, $
    virtualViewDims, normClipRect, normViewDims, $
    bVirtualChange, zoomOnResize, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Update the virtual frustum rectangle (aspect ratio changes, and
    ; visible to virtual cropping).
    self.bFrustumDirty = 1b
    bChange = self->ComputeVirtualFrustumRect(virtualViewDims, normClipRect)

    ; Crop the frustum to the visible portion of the scrolling window.
    self->CropFrustum, oDestination

    ; Notify visualizations that the viewport has changed.
    oWorld = self->IDLgrView::Get()
    oDS = oWorld->GetDataSpaces(COUNT=nDS)
    for i=0,nDS-1 do $
        oDS[i]->OnViewportChange, oView, oDestination, virtualViewDims, $
            normViewDims
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrAnnotateLayer::OnDataComplete
;
; PURPOSE:
;    The IDLitgrAnnotateLayer::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]OnDataComplete, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data flush.
;
;-
pro IDLitgrAnnotateLayer::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    ; Notify my parent view.
    self->GetProperty, PARENT=oView
    if (OBJ_VALID(oView)) then begin
        ; Notify the parent View.
        oView->OnDataComplete, oNotifier
    endif
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitgrAnnotateLayer__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitgrAnnotateLayer object.
;
;-
pro IDLitgrAnnotateLayer__define

    compile_opt idl2, hidden

    struct = {IDLitgrAnnotateLayer,           $
              inherits IDLitgrLayer          $ ; Superclass: _IDLitgrLayer
             }
end
