; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrview__define.pro#2 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; PURPOSE:
;    The IDLitgrView class represents a rectangular area (within a scene)
;    in which one or more layers of visualizations are to be drawn.
;
; MODIFICATION HISTORY:
;     Written by:    DLD, June 2001.
;-

;----------------------------------------------------------------------------
; IDLitgrView::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitgrView::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitgrView::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'LAYOUT_POSITION', /INTEGER, $
            NAME='Layout position', $
            DESCRIPTION='Position within the window container', /ADVANCED_ONLY
    endif
    
    if (registerAll || (updateFromVersion lt 710)) then begin
        self->RegisterProperty, 'STRETCH_TO_FIT', /BOOLEAN, $
            NAME='Stretch to fit', /ADVANCED_ONLY, $
            DESCRIPTION='Stretch visualization layer to fit viewport'
    endif
    
    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'XMARGIN', $
            NAME='X margin', $
            DESCRIPTION='Normalized width of margin', $
            /FLOAT, VALID_RANGE=[0d,0.49d], /ADVANCED_ONLY
            
        self->RegisterProperty, 'YMARGIN', $
            NAME='Y margin', $
            DESCRIPTION='Normalized height of margin', $
            /FLOAT, VALID_RANGE=[0d,0.49d], /ADVANCED_ONLY
    endif

    if (registerAll) then begin
        self->RegisterProperty, 'CURRENT_ZOOM', /FLOAT, $
            NAME='Zoom factor', $
            DESCRIPTION='Current zoom factor'
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'VIEWPORT_RECT', USERDEF='', /HIDE, $
            NAME='Viewport rectangle', $
            DESCRIPTION='Viewport rectangle', $
            SENSITIVE=0, /ADVANCED_ONLY

        self->RegisterProperty, 'COLOR', /COLOR, $
            NAME='Background color', $
            DESCRIPTION='Background color', /ADVANCED_ONLY

    endif

    if (~registerAll && (updateFromVersion ge 610) && $
        (updateFromVersion lt 710)) then begin
        ; MARGIN_2D_X became XMARGIN in IDL71.
        self->SetPropertyAttribute, 'MARGIN_2D_X', /HIDE
        ; MARGIN_2D_Y became YMARGIN in IDL71.
        self->SetPropertyAttribute, 'MARGIN_2D_Y', /HIDE
    endif

    if (registerAll || (updateFromVersion lt 710)) then begin
      self->RegisterProperty, 'VISIBLE_LOCATION', USERDEF=1, /HIDE, $
        NAME='Visible location', $
        DESCRIPTION='Visible location', /ADVANCED_ONLY
    endif

    self->SetPropertyAttribute, 'DESCRIPTION', /HIDE

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::Init
;
; PURPOSE:
;    Initializes an IDLitgrView object.
;
; CALLING SEQUENCE:
;    oView = OBJ_NEW('IDLitgrView')
;
;        or
;
;    Result = oView->[IDLitgrView::]Init()
;
; KEYWORD PARAMETERS:
;    <Accepts all keywords accepted by the superclasses.>
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 if initialization
;    fails.
;
;-
function IDLitgrView::Init, $
                    CURRENT_ZOOM=currentZoom, $
                    VIEWPORT_RECT=viewportRect, $
                    UNITS=units, $
                    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitiMessaging::Init(_EXTRA=_extra)) then $
        return, 0

    if(self->IDLitSelectContainer::Init() ne 1)then $
       return, 0

    if (self->IDLgrViewGroup::Init(/REGISTER_PROPERTIES, $
        NAME='View', $
        ICON="view", $
        DESCRIPTION='View', $
        _EXTRA=_extra) ne 1) then $
        RETURN, 0

   if(self->_IDLitContainer::Init(CLASSNAME='IDLgrViewGroup') eq 0)then $
     return, 0

    ; Create a single ViewLayer, add it, and make it current.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oDesc = oTool->GetVisualization('Visualization Layer')
        oViewLayer = oDesc->GetObjectInstance()
    endif else $
        oViewLayer = OBJ_NEW('IDLitgrLayer', NAME='VISUALIZATION LAYER')
    self->Add, oViewLayer
    self->SetCurrentLayer, oViewLayer

    ; Create an annotation ViewLayer, add it.
    oAnnotLayer = OBJ_NEW('IDLitgrAnnotateLayer', TOOL=self->GetTool())
    self->Add, oAnnotLayer

    ; Create a ViewLayer to hold the layer outline.
    ; Make it transparent so we can see the actual Viewlayers below it.
    self._oViewLayer = OBJ_NEW('IDLgrView', NAME='Outline', /TRANSPARENT, $
        VIEWPLANE_RECT=[0,0,1,1], /private)
    self._oOutline = OBJ_NEW('IDLitManipVisView')
    self._oViewLayer->Add, self._oOutline

    self->Add, self._oViewLayer

    ; -- Visible viewport -----------------------------------------------
    self.normVirtualDims = [1.0,1.0]  ; Fill virtual canvas
;   self.normVirtualLoc = [0,0]

;   self.normCropLoc = [0,0]          ; Not yet cropped; cropped
    self.normCropDims = [1.0,1.0]     ;   visible matches full visible.

    ; -- Virtual viewport -----------------------------------------------
;   self.virtualDims: [0,0]          ; Virtual viewport matches visible.
;   self.origVirtualDims: [0,0]
;   self.minVirtualDims: [0,0]
;   self.visibleLoc: [0,0]

    self.geomRefCount = 0UL
    self.zoomFactor = 1d
    self._windowZoom = 1d  ; Note: this field is phased out as of IDL 6.1,
                           ; but is maintained for restore issues.

    ; Register all properties.
    self->IDLitgrView::_RegisterProperties

    ; Pass along keyword values to the ::SetProperty method.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitgrView::SetProperty, _EXTRA=_extra

    RETURN, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::Cleanup
;
; PURPOSE:
;    Performs all cleanup for an IDLitgrView object.
;
; CALLING SEQUENCE:
;    OBJ_DESTROY, oView
;
;        or
;
;    oView->[IDLitgrView::]Cleanup
;
;-
pro IDLitgrView::Cleanup

    compile_opt idl2, hidden

    ; Cleanup the superclasses.
    self->_IDLitContainer::Cleanup
    self->IDLgrViewGroup::Cleanup

    self->IDLitSelectContainer::Cleanup

end

;----------------------------------------------------------------------------
; IDLitgrView::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitgrView::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    ; self->_IDLitContainer::Restore
    ; self->IDLgrViewGroup::Restore
    ; self->idlitSelectContainer::Restore
    ; self->IDLitMessaging::Restore

    ; Register new properties.
    self->IDLitgrView::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin

        ; Note: while it is tempting to restore each contained
        ; layer and recompute layer margins here,
        ; this is not a good place to perform these updates since
        ; the restore can occur before the visualization hierarchy
        ; has been added to the window.  Therefore, the updates
        ; will have to wait until a simulated viewport update occurs
        ; (after the visualization hierarchy is added to the window).

        ; IDL 6.1 phased out the use of the window zoom field.
        ; (ZoomOnResize handling is now accomplished in new code
        ; within the IDLitVisNormalizer::ComputePadding method.)
        ; Old window zoom settings need to be mapped to the new
        ; scheme.
        if (self._windowZoom ne 1.0) then begin

            ; Modify the default margin of each layer.
            oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)

            ; Map old default margin of 0.15 to a new margin so that:
            ;   (1-(2*oldMargin))*oldWinDim = (1-(2*newMargin))*newWinDim
            ; where:
            ;   newMargin = oldMargin * computedScale
            ;
            oldMargin = 0.15
            oldMargin2 = 2.0*0.15
            newMargin = 0.15 * ((1.0/oldMargin2) - $
                                (((1.0-oldMargin2)/oldMargin2) * $
                                self._windowZoom))
            for i=0,nLayers-1 do begin
                oViewLayerArr[i]->Restore
                oViewLayerArr[i]->UpdateComponentVersion
                if (~OBJ_ISA(oViewLayerArr[i], $
                    'IDLitgrAnnotateLayer')) then begin
                    oViewLayerArr[i]->SetProperty, MARGIN_2D_X=newMargin, $
                        MARGIN_2D_Y=newMargin, /NO_PADDING_UPDATES
                    oViewLayerArr[i]->GetProperty, MARGIN_2D_X=xm, $
                        MARGIN_2D_Y=ym
                endif
            endfor
            self._windowZoom = 1.0
        endif
    endif
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::GetProperty
;
; PURPOSE:
;    The IDLitgrView::GetProperty procedure method retrieves the
;    value of a property or group of properties.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]GetProperty
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitgrView::Init followed by the word "Get"
;    can be retrieved using IDLitgrView::GetProperty.
;
;-
pro IDLitgrView::GetProperty, $
    COLOR=color, $
    CURRENT_ZOOM=currentZoom, $
    DIMENSIONS=DIMENSIONS, $
    LAYOUT_POSITION=layoutPosition, $
    LOCATION=LOCATION, $
    XMARGIN=margin2DX, $
    YMARGIN=margin2DY, $
    MARGIN_2D_X=margin2DXOld, $  ; Keep for BC
    MARGIN_2D_Y=margin2DYOld, $  ; Keep for BC
    MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
    STRETCH_TO_FIT=stretchToFit, $
    UNITS=units, $
    VERTICAL_SCROLL=vertScroll, $
    VIEWPORT_RECT=viewportRect, $
    VIRTUAL_DIMENSIONS=virtualDims, $
    VISIBLE_LOCATION=visibleLocation, $
    WINDOW_ZOOM=windowZoom, $  ; Phased out for IDL 6.1, but kept for RESTORE.
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(color)) then $
        self.oCurrViewLayer->GetProperty, COLOR=color

    if (ARG_PRESENT(currentZoom)) then $
        currentZoom = self.zoomFactor
     
    if (ARG_PRESENT(margin2DX) || ARG_PRESENT(margin2DY) || $
        ARG_PRESENT(stretchToFit)) then begin
        ; Initialize to default values (in case no layers exist).
        margin2DX = [0.0,0.0]
        margin2DY = [0.0,0.0]
        stretchToFit = 0
        ; Retrieve margins from first non-annotation layer.
        oLayers = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
        for i=0,nLayers-1 do begin
            if (~OBJ_ISA(oLayers[i],'IDLitgrAnnotateLayer')) then begin
                oLayers[i]->GetProperty, $
                    XMARGIN=margin2DX, YMARGIN=margin2DY, STRETCH_TO_FIT=stretchToFit
                break
            endif
        endfor
    endif

    ; Keep for BC
    if (ARG_PRESENT(margin2DXOld) || ARG_PRESENT(margin2DYOld)) then $
      self->GetProperty, XMARGIN=margin2DXOld, YMARGIN=margin2DYOld

    ; Note: WINDOW_ZOOM was phased out in IDL 6.1, but is maintained for
    ; restore issues.
    if (ARG_PRESENT(windowZoom)) then $
        windowZoom = self._windowZoom

    if (ARG_PRESENT(minimumVirtualDims)) then $
        minimumVirtualDims = self.minVirtualDims

    if (ARG_PRESENT(virtualDims)) then $
        virtualDims = self.virtualDims

    if (ARG_PRESENT(visibleLocation)) then $
        visibleLocation = self.visibleLoc

    if (ARG_PRESENT(layoutPosition)) then begin
        layoutPosition = 0
        self->IDLgrViewGroup::GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent)) then begin
            dummy = oParent->IsContained(self, POSITION=layoutPosition)
            layoutPosition++   ; Adjust to one-based
        endif
    endif

    if (ARG_PRESENT(viewportRect)) then begin
        viewportDim = self->GetViewport( $
            LOCATION=viewportLoc, $
            UNITS=units)
        viewportRect = [viewportLoc, viewportDim]
    endif

    if(arg_present(dimensions) || arg_Present(location))then begin
        dimensions = self->GetViewport( $
            LOCATION=location, $
            UNITS=units)
    endif

    ; Retrieve property values from the superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLgrViewGroup::GetProperty, _EXTRA=_extra
end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::SetProperty
;
; PURPOSE:
;    The IDLitgrView::SetProperty procedure method sets the
;    value of a property or group of properties.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]SetProperty
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitgrView::Init followed by the word "Set"
;    can be set using IDLitgrView::SetProperty.
;
;-
pro IDLitgrView::SetProperty, $
    COLOR=color, $
    CURRENT_ZOOM=currentZoom, $
    HIDE=hide, $
    LAYOUT_POSITION=layoutPositionIn, $
    XMARGIN=margin2DX, $
    YMARGIN=margin2DY, $
    MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
    STRETCH_TO_FIT=stretchToFit, $
    VIEWPORT_RECT=viewportRect, $
    VIRTUAL_DIMENSIONS=virtualDimensions, $
    VIRTUAL_HEIGHT=virtualHeight, $
    VIRTUAL_WIDTH=virtualWidth, $
    VISIBLE_LOCATION=visibleLocation, $
    UNITS=units, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    bReScroll = 0b

    if (N_ELEMENTS(color) gt 0) then begin
        self.oCurrViewLayer->SetProperty, COLOR=color
    endif

    if (N_ELEMENTS(viewportRect) gt 0) then begin
        self->SetViewport, viewportRect[0:1], viewportRect[2:3], $
            UNITS=units
    endif

    ; Margins get passed along to layers.
    if (N_ELEMENTS(margin2DX) || N_ELEMENTS(margin2DY) || $
        N_ELEMENTS(stretchToFit)) then begin
        oLayers = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
        for i=0,nLayers-1 do begin
            if (~OBJ_ISA(oLayers[i], 'IDLitgrAnnotateLayer')) then begin
                oLayers[i]->SetProperty, $
                    XMARGIN=margin2DX, YMARGIN=margin2DY, $
                    STRETCH_TO_FIT=stretchToFit
            endif
        endfor
    endif

    ; Note: The CURRENT_ZOOM factor is allowed to be a settable property
    ; so that it may be set explicitly via a property window interface.
    if (N_ELEMENTS(currentZoom) ne 0) then $
        self->SetCurrentZoom, currentZoom

    ; VIRTUAL_HEIGHT and VIRTUAL_WIDTH are just different ways to
    ; set the VIRTUAL_DIMENSIONS. However, setting VIRTUAL_HEIGHT or
    ; VIRTUAL_WIDTH will also set the minimum_virtual_dims to the same values.
    if (N_ELEMENTS(virtualHeight) || N_ELEMENTS(virtualWidth)) then begin

        self->GetProperty, MINIMUM_VIRTUAL_DIMENSIONS=minimumVirtualDims, $
            VIRTUAL_DIMENSIONS=virtualDimensions

        if (N_ELEMENTS(virtualWidth)) then begin
            virtualDimensions[0] = virtualWidth > 1
            minimumVirtualDims[0] = virtualDimensions[0] / self.zoomFactor
        endif
        if (N_ELEMENTS(virtualHeight)) then begin
            virtualDimensions[1] = virtualHeight > 1
            minimumVirtualDims[1] = virtualDimensions[1] / self.zoomFactor
        endif

        ; The MINIMUM_VIRTUAL_DIMENSIONS and VIRTUAL_DIMENSIONS will
        ; actually get set below.

    endif

    if (N_ELEMENTS(minimumVirtualDims) eq 2) then begin
        w = ULONG((minimumVirtualDims[0] > 0.0) + 0.5)
        h = ULONG((minimumVirtualDims[1] > 0.0) + 0.5)

        ; Change only if necessary.
        if (w ne self.minVirtualDims[0]) then begin
            self.minVirtualDims[0] = w

            ; Update virtual dimension to minimum if necessary.
            if (N_ELEMENTS(virtualDimensions ne 2)) then begin
                if (self.minVirtualDims[0] gt 0) then begin
                    if ((self.origVirtualDims[0] gt 0) && $
                        self.origVirtualDims[0] lt $
                        self.minVirtualDims[0]) then begin
                        self.origVirtualDims[0] = self.minVirtualDims[0]
                        self.virtualDims[0] = ULONG( $
                            (self.origVirtualDims[0] * self.zoomFactor) + 0.5)
                        bReScroll = 1b
                    endif
                endif
            endif
        endif
        if (h ne self.minVirtualDims[1]) then begin
            self.minVirtualDims[1] = h

            ; Update virtual dimension to minimum if necessary.
            if (N_ELEMENTS(virtualDimensions ne 2)) then begin
                if (self.minVirtualDims[1] gt 0) then begin
                    if ((self.origVirtualDims[1] gt 0) && $
                        self.origVirtualDims[1] lt $
                        self.minVirtualDims[1]) then begin
                        self.origVirtualDims[1] = self.minVirtualDims[1]
                        self.virtualDims[1] = ULONG( $
                            (self.origVirtualDims[1] * self.zoomFactor) + 0.5)
                        bReScroll = 1b
                    endif
                endif
            endif
        endif
    endif

    if (N_ELEMENTS(virtualDimensions) eq 2) then begin
        w = ULONG((virtualDimensions[0] > 0.0) + 0.5)
        h = ULONG((virtualDimensions[1] > 0.0) + 0.5)

        ; Clamp to minimum virtual dimensions.
        if (self.minVirtualDims[0] gt 0) then begin
            unzoomW = ULONG((w / self.zoomFactor) + 0.5)
            if ((w gt 0) && $
                (unzoomW < self.minVirtualDims[0])) then $
                w = ULONG((self.minVirtualDims[0] * self.zoomFactor) + 0.5)
        endif
        if (self.minVirtualDims[1] gt 0) then begin
            unzoomH = ULONG((h / self.zoomFactor) + 0.5)
            if ((h gt 0) && $
                (unzoomH < self.minVirtualDims[1])) then $
                h = ULONG((self.minVirtualDims[1] * self.zoomFactor) + 0.5)
        endif

        ; Change only if necessary.
        if (w ne self.virtualDims[0]) then begin
            self.virtualDims[0] = w
            self.origVirtualDims[0] = ULONG((w / self.zoomFactor) + 0.5)
            bReScroll = 1b
        endif
        if (h ne self.virtualDims[1]) then begin
            self.virtualDims[1] = h
            self.origVirtualDims[1] = ULONG((h / self.zoomFactor) + 0.5)
            bReScroll = 1b
        endif
    endif

    if (N_ELEMENTS(visibleLocation) eq 2) then begin
        if ((visibleLocation[0] ne self.visibleLoc[0]) || $
            (visibleLocation[1] ne self.visibleLoc[1])) then begin
            self.visibleLoc = visibleLocation
            bReScroll = 1b
            notifyViewPan = 1b
        endif
    endif

    if (bReScroll) then begin
        ; Walk up the hierarchy to retrieve the destination object.
        self->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene)) then $
            oScene->GetProperty, DESTINATION=oDestination $
        else $
            oDestination = OBJ_NEW()

        if (OBJ_VALID(oDestination)) then begin
            oDestination->GetProperty, CURRENT_ZOOM=canvasZoom
            visViewportDims = self->GetViewport(oDestination, /VIRTUAL) / $
                 canvasZoom
        endif else begin
            canvasZoom = 1.0
            visViewportDims = [0.0,0.0]
        endelse

        ; Constrain the visible location.
        if (visViewportDims[0] le self.virtualDims[0]) then begin
            if (self.visibleLoc[0] lt 0) then self.visibleLoc[0] = 0
            if ((self.visibleLoc[0] + visViewportDims[0]) gt $
                self.virtualDims[0]) then $
                self.visibleLoc[0] = $
                    (self.virtualDims[0] - visViewportDims[0]) > 0
        endif
        if (visViewportDims[1] le self.virtualDims[1]) then begin
            if (self.visibleLoc[1] lt 0) then self.visibleLoc[1] = 0
            if ((self.visibleLoc[1] + visViewportDims[1]) gt $
                self.virtualDims[1]) then $
                self.visibleLoc[1] = $
                    (self.virtualDims[1] - visViewportDims[1]) > 0
        endif

        ; Scroll each layer.  (Scrolling is handled in the zoom correction.)
        oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
        if (nLayers gt 0) then begin
            origVirtualDims = self->GetVirtualViewport(oDestination, /UNZOOMED)
            virtualDims = self->GetVirtualViewport(oDestination)
            if (OBJ_VALID(oDestination) && $
                OBJ_ISA(oDestination, '_IDLitgrDest')) then begin
                oDestination->GetProperty, ZOOM_ON_RESIZE=zoomOnResize
            endif else begin
                zoomOnResize = 0b
            endelse
            normClipLoc = self.visibleLoc / virtualDims
            normClipDims = visViewportDims / virtualDims
            for i=0,nLayers-1 do begin
                oViewLayerArr[i]->_RecomputeMargins, origVirtualDims, zoomOnResize
                oViewLayerArr[i]->ResetVirtualFrustumRect
                bChange = oViewLayerArr[i]->ComputeVirtualFrustumRect( $
                    virtualDims, [normClipLoc, normClipDims])
                oViewLayerArr[i]->CropFrustum, oDestination
            endfor
        endif

        ; We have waited to do the notification in case the visibleLoc
        ; was changed by any of the above clipping.
        if (KEYWORD_SET(notifyViewPan)) then begin
            self->DoOnNotify, $
                self->GetFullIdentifier(), 'VIEW_PAN', self.visibleLoc
        endif

    endif


    ; LAYOUT_POSITION.
    if (N_ELEMENTS(layoutPositionIn) gt 0) then begin

        ; Adjust from one-based to zero-based.
        layoutPosition = layoutPositionIn - 1

        self->IDLgrViewGroup::GetProperty, _PARENT=oWin

        if (OBJ_VALID(oWin) && $
            oWin->IsContained(self, POSITION=currentPosition)) then begin

            if (currentPosition ne layoutPosition) then begin
                oWin->Move, currentPosition, layoutPosition

                oLayout = oWin->GetLayout()
                oLayout->GetProperty, GRIDDED=gridded
                ; For gridded layout, recalculate geometry for all views.
                if (gridded) then $
                    oWin->UpdateView, oWin->Get(/ALL)

            endif   ; move

        endif   ; valid

    endif   ; layoutPosition

    ; Set our internal flag so we know the user changed hidden.
    if (N_ELEMENTS(hide) gt 0) then begin
        self.isHidden = KEYWORD_SET(hide)
        self->IDLgrViewGroup::SetProperty, HIDE=hide
    endif

    ; Pass along properties to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLgrViewGroup::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitgrView::RestoreMargins
;
; Purpose:
;   This procedure method restores the view margins to the given values.
;   [This is useful for handling the undo of some operations.]
;
pro IDLitgrView::RestoreMargins, margins
    compile_opt idl2, hidden

    oLayers = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
    for i=0,nLayers-1 do begin
        if (~OBJ_ISA(oLayers[i], 'IDLitgrAnnotateLayer')) then $
            oLayers[i]->RestoreMargins, margins
    endfor
end

;;---------------------------------------------------------------------------
;; IDLitgrView::Add
;;
;; Purpose:
;;   Used to manage the parent and _parent properties of the View.
;;   This helps with the tree abstraction used in the tool system.
;;
;;
pro IDLitgrView::Add, oVis, LAYER=layer, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    isView = WHERE(OBJ_ISA(oVis, 'IDLgrView'), nView, $
        COMPLEMENT=nonView, NCOMP=nNon)
    ; This will add the IDLgrViews to ourself, and set the _PARENT.
    if (nView gt 0) then $
        self->_IDLitContainer::Add, oVis[isView], _EXTRA=_extra

    if (nNon eq 0) then $
        return

    ;; The user is targeting a specific layer
    if (KEYWORD_SET(layer)) then begin
        if (STRCMP(layer, 'ANNOTATION', /FOLD)) then begin
            ; The Annotation Layer id changed from 'ANNOTATION' in IDL60
            ; to 'ANNOTATION LAYER' in IDL61. So get the object directly.
            oLayer = (self->Get(/ALL, ISA='IDLitgrAnnotateLayer'))[0]
        endif else begin
            oLayer = self->GetByIdentifier(layer)
        endelse
    endif else begin
        oLayer = self.oCurrViewLayer
    endelse

    if(obj_valid(oLayer))then $
        oLayer->Add, oVis[nonView], _EXTRA=_extra

end


;----------------------------------------------------------------------------
; IIDLResizeObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::OnResize
;
; PURPOSE:
;    Handles notification of a resize of the destination.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]OnResize, oNotifier, width, height
;
; INPUTS:
;    oNotifier: A reference to the destination object that has been resized.
;    width: The new width of the destination.
;    height: The new height of the destination.
;
;-
pro IDLitgrView::OnResize, oNotifier, width, height

    compile_opt idl2, hidden

    ; Reset the viewport so that it is proportionally the same size
    ; relative to the destination dimensions.
    self->SetViewport, self.normVirtualLoc, self.normVirtualDims, $
        UNITS=3

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::OnCanvasZoom
;
; PURPOSE:
;    Handles notification of a zoom of the destination.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]OnCanvasZoom, oNotifier, width, height
;
; INPUTS:
;    oNotifier: A reference to the destination object that has been zoomed.
;    width: The new width of the destination.
;    height: The new height of the destination.
;
;-
pro IDLitgrView::OnCanvasZoom, oNotifier, width, height

    compile_opt idl2, hidden

    ; Reset the viewport so that it is proportionally the same size
    ; relative to the destination dimensions.
    normUnits = 3
    self->SetViewport, self.normVirtualLoc, self.normVirtualDims, $
        UNITS=normUnits

end


;----------------------------------------------------------------------------
; IIDLScrollObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::OnCanvasScroll
;
; PURPOSE:
;    The IDLitgrView::OnCanvasScroll procedure method crops the View
;    to the visible portion of the scrolling canvas.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]OnCanvasScroll, oNotifier, ScrollX, ScrollY
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the scroll.
;    ScrollX, ScrollY:    The coordinates (in device units, relative
;        to the virtual canvas) of the lower-left corner of the
;        visible area of the scrolled destination
;
;-
pro IDLitgrView::OnCanvasScroll, oNotifier, ScrollX, ScrollY

    compile_opt idl2, hidden

    ; Crop the viewport.
    self->CropViewport, oNotifier

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::Scroll
;
; PURPOSE:
;    The IDLitgrView::Scroll procedure method scrolls the view
;    by the given amount relative to the default center.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]Scroll, hScroll, vScroll
;
; INPUTS:
;    hScroll:  A scalar representing the horizontal scroll to be
;      applied (measured in device pixel units).  This factor can
;      be positive (scroll right) or negative (scroll left).
;
;    vScroll:  A scalar representing the vertical scroll to be
;      applied (measured in device pixel units).  This factor can
;      be positive (scroll up) or negative (scroll down).
;
; KEYWORDS:
;    NO_UPDATE: Set this keyword to a non-zero value to indicate
;      that the window should not be redrawn following the scroll.
;      By default, the window is redrawn.
;-
pro IDLitgrView::Scroll, hScroll, vScroll, $
    NO_UPDATE=noUpdate

    compile_opt idl2, hidden

    ; Walk up the hierarchy to retrieve the destination object.
    self->GetProperty, PARENT=oScene
    if (OBJ_VALID(oScene)) then $
        oScene->GetProperty, DESTINATION=oDestination $
    else $
        oDestination = OBJ_NEW()

    if (OBJ_VALID(oDestination)) then begin
        oDestination->GetProperty, CURRENT_ZOOM=canvasZoom
        visViewportDims = self->GetViewport(oDestination, /VIRTUAL) / $
            canvasZoom
    endif else begin
        canvasZoom = 1.0
        visViewportDims = [0.0,0.0]
    endelse

    ; Factor out the current destination zoom factor.
    baseScroll = [hScroll, vScroll]
    if (canvasZoom ne 1.0) then $
        baseScroll /= canvasZoom

    if (visViewportDims[0] ge self.virtualDims[0]) then $
        baseScroll[0] = 0
    if (visViewportDims[1] ge self.virtualDims[1]) then $
        baseScroll[1] = 0
    if ((baseScroll[0] eq 0) && (baseScroll[1] eq 0)) then $
        return

    ; Move the visible location.
    self.visibleLoc = self.visibleLoc + baseScroll

    ; Constrain to virtual dims.
    if (visViewportDims[0] le self.virtualDims[0]) then begin
        if (self.visibleLoc[0] lt 0) then self.visibleLoc[0] = 0
        if ((self.visibleLoc[0] + visViewportDims[0]) gt $
            self.virtualDims[0]) then $
            self.visibleLoc[0] = (self.virtualDims[0] - visViewportDims[0]) > 0
    endif
    if (visViewportDims[1] le self.virtualDims[1]) then begin
        if (self.visibleLoc[1] lt 0) then self.visibleLoc[1] = 0
        if ((self.visibleLoc[1] + visViewportDims[1]) gt $
            self.virtualDims[1]) then $
            self.visibleLoc[1] = (self.virtualDims[1] - visViewportDims[1]) > 0
    endif

    ; Scroll each layer.  (Scrolling is handled in the zoom correction.)
    oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
    if (nLayers gt 0) then begin
        virtualDims = self->GetVirtualViewport(oDestination)
        normClipLoc = self.visibleLoc / virtualDims
        normClipDims = visViewportDims / virtualDims
        for i=0,nLayers-1 do begin
            oViewLayerArr[i]->_CorrectForZoom, [normClipLoc, normClipdims]
            oViewLayerArr[i]->CropFrustum, oDestination
        endfor
    endif

    self->DoOnNotify, self->GetFullIdentifier(), 'VIEW_PAN', self.visibleLoc

    if (~KEYWORD_SET(noUpdate)) then begin
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then $
            oTool->RefreshCurrentWindow
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::ZoomToFit
;
; PURPOSE:
;    The IDLitgrView::ZoomToFit procedure method zooms and/or scrolls
;    the view to fit the given items within its visible portion.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]ZoomToFit, oTargets
;
; INPUTS:
;    oTargets: A vector of references to the visualizations that
;      are to be fit within the visible portion of the view.
;-
pro IDLitgrView::ZoomToFit, oTargets

    compile_opt idl2, hidden

    nTargets = N_ELEMENTS(oTargets)
    if (nTargets eq 0) then $
        return

    self->IDLgrViewGroup::GetProperty, _PARENT=oWin

    if (OBJ_VALID(oWin)) then begin
        oWin->GetProperty, CURRENT_ZOOM=canvasZoom
        destScrollDims = oWin->GetDimensions( $
            VISIBLE_LOCATION=destScrollLoc, $
            VIRTUAL_DIMENSIONS=destVirtualDims)
    endif else begin
        destScrollLoc = [0,0]
        destScrollDims = viewportDims
    endelse

    nValidRange = 0
    for i=0,nTargets-1 do begin
        if (oTargets[i]->GetXYZRange(xr,yr,zr, /NO_TRANSFORM)) then begin
            ; Prepare x,y,z values of 8 corners of bounding box.
            px = [xr[0], xr[1], xr[1], xr[0], $
                  xr[0], xr[1], xr[1], xr[0]]
            py = [yr[0], yr[0], yr[1], yr[1], $
                  yr[0], yr[0], yr[1], yr[1]]
            pz = [zr[0], zr[0], zr[0], zr[0], $
                  zr[0], zr[1], zr[1], zr[1]]
            oTargets[i]->VisToWindow, px, py, pz, wx, wy, wz
            xmin = MIN(wx, MAX=xmax)
            ymin = MIN(wy, MAX=ymax)
            if (nValidRange eq 0) then begin
               fullwx = [xmin,xmax]
               fullwy = [ymin,ymax]
            endif else begin
               fullwx[0] = fullwx[0] < xmin
               fullwx[1] = fullwx[1] > xmax
               fullwy[0] = fullwy[0] < ymin
               fullwy[1] = fullwy[1] > ymax
            endelse
            nValidRange++
        endif
    endfor

    if (nValidRange eq 0) then $
        return

    ; Store original values.
    oldZoom = self.zoomFactor
    oldVisLoc = self.visibleLoc

    ; Determine scale factor required to fit overall bbox within
    ; view.
    viewportDims = self->GetViewport(oWin)
    fullViewportDims = self->GetViewport(oWin, /VIRTUAL, $
        LOCATION=fullViewportLoc)
    dwx = fullwx[1] - fullwx[0]
    dwy = fullwy[1] - fullwy[0]
    sx = viewportDims[0]/dwx
    sy = viewportDims[1]/dwy
    newZoom = self.zoomFactor * (sx < sy)

    ; Temporarily disable window draws.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled
        reEnableUpdates = ~wasDisabled
    endif else $
        reEnableUpdates = 0b

    ; Compute center in visible window coordinates.
    cx = fullwx[0] + (dwx*0.5)
    cy = fullwy[0] + (dwy*0.5)

    ; Transform from visible window to virtual window coordinates.
    cx = cx + destScrollLoc[0]
    cy = cy + destScrollLoc[1]

    vwcx = cx
    vwcy = cy

    ; Transform from virtual window to visible viewport coordinates.
    cx = cx - fullViewportLoc[0]
    cy = cy - fullViewportLoc[1]

    ; Transform from visible viewport to virtual viewport coordinates.
    cx = (cx / canvasZoom) + self.visibleLoc[0]
    cy = (cy / canvasZoom) + self.visibleLoc[1]

    self->SetCurrentZoom, newZoom, CENTER=[cx,cy]

    ; If the view completely fills the window, scroll the window so that
    ; the center of the zoom is centered in the visible portion of the
    ; window.
    if (Obj_Valid(oWin)) then begin
        viewportDims = self->GetViewport(oWin, /VIRTUAL, $
            LOCATION=viewportLoc)
        if ((viewportLoc[0] eq 0) && $
            (viewportLoc[1] eq 0) && $
            (viewportDims[0] eq destVirtualDims[0]) && $
            (viewportDims[0] eq destVirtualDims[0])) then begin

            scrollX = vwcx - (destScrollDims[0]*0.5)
            scrollY = vwcy - (destScrollDims[1]*0.5)

            oWin->SetProperty, VISIBLE_LOCATION=[scrollX, scrollY]
        endif
    endif

    ; Renable window draws.
    if (reEnableUpdates) then $
        oTool->EnableUpdates
end

;----------------------------------------------------------------------------
; IIDLView Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::CropViewport
;
; PURPOSE:
;    The IDLitgrView::CropViewport procedure method crops the viewport
;    to the visible portion of the scrolling destination.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]CropViewport, oDestination
;
; INPUTS:
;    oDestination: A reference to the (scrolling) destination object.
;
; KEYWORDS:
;    NO_NOTIFY: Set this keyword to a non-zero value to indicate that
;      the contained layers should not be notified of the crop.  By default,
;      the contained layers are notified.
;-
pro IDLitgrView::CropViewport, oDestination, NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    ; Retrieve the device coordinates of the virtual viewport.
    viewportDims = self->GetViewport( oDestination, LOCATION=viewportLoc, $
        /VIRTUAL)

    ; Get the visible portion of the scrolling destination.
    destScrollDims = oDestination->GetDimensions( $
        VIRTUAL_DIMENSIONS=virtualDestDims, $
        VISIBLE_LOCATION=destScrollLoc)
    self.winDims = virtualDestDims

    ; Compute the portion of the viewport that falls within the visible
    ; portion of the scrolling destination.
    viewRightPos = viewportLoc[0] + viewportDims[0] - 1
    destRightPos = destScrollLoc[0] + destScrollDims[0] - 1
    viewTopPos = viewportLoc[1] + viewportDims[1] - 1
    destTopPos = destScrollLoc[1] + destScrollDims[1] - 1

    ; Make sure that some portion of the viewgroup viewport is within the
    ; visible portion of the scrolling destination.
    if ((viewRightPos ge destScrollLoc[0]) and $
        (viewportLoc[0] lt destRightPos)) and $
        ((viewTopPos ge destScrollLoc[1]) and $
        (viewportLoc[1] lt destTopPos)) then begin

        cropX0 = viewportLoc[0] > destScrollLoc[0]
        cropX1 = viewRightPos < destRightPos
        cropY0 = viewportLoc[1] > destScrollLoc[1]
        cropY1 = viewTopPos < destTopPos

        cropCanvasDims = [cropX1-cropX0+1, cropY1-cropY0+1]

        ; Only make visible if user really wants it visible.
        isVisible = ~self.isHidden
        if (isVisible) then $
            self->IDLgrViewGroup::SetProperty, HIDE=0

        ; Keep track of the normalized crop coordinates (relative to
        ; the full visible viewport).
        self.normCropLoc = [(cropX0-viewportLoc[0])/viewportDims[0], $
            (cropY0-viewportLoc[1])/viewportDims[1]]
        self.normCropDims = cropCanvasDims / viewportDims
    endif else begin
        self->IDLgrViewGroup::SetProperty, HIDE=1
        isVisible = 0b
    endelse

    if (~KEYWORD_SET(noNotify) && isVisible) then begin
        ; Crop each view layer.
        oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, $
            COUNT=nLayers)
        if (nLayers gt 0) then begin
            for i=0,nLayers-1 do $
                oViewLayerArr[i]->CropFrustum, oDestination
        endif
    endif

    ; Update the outline box around the view.
    self->_UpdateOutline, oDestination

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::SetCurrentZoom
;
; PURPOSE:
;    The IDLitgrView::SetCurrentZoom procedure modifies the dimensions of
;    the XY portion of the view frustum of each of its view layers.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]SetCurrentZoom, ZoomFactor[, CENTER=[x,y]]
;
; INPUTS:
;    ZoomFactor:    A positive floating point value representing the new
;   zoom factor.  A value less than 1.0 will cause the contents of the
;   view to visually appear smaller; a value greater than 1.0 will
;   cause the contents to appear larger.
;
; KEYWORD PARAMETERS:
;    CENTER:    Set this keyword to a two-element vector, [x,y], indicating
;        the location (in un-canvas-zoomed device units relative to the
;        virtual viewport prior to the new zoom) about which the zoom is to
;        be centered.  The default is the center of the visible viewport.
;
;    NO_NOTIFY: Set this keyword to a non-zero value to indicate that
;        notification to registered objects should not occur.
;
;    NO_UPDATES: Set this keyword to a non-zero value to indicate that
;        the parent scene should not be notified.
;-
pro IDLitgrView::SetCurrentZoom, zoomFactor, $
    CENTER=inCenter, $
    NO_NOTIFY=noNotify, $
    NO_UPDATES=noUpdates

    compile_opt idl2, hidden

    ; Walk up the hierarchy to retrieve the destination object.
    self->GetProperty, PARENT=oScene
    if (OBJ_VALID(oScene)) then $
       oScene->GetProperty, DESTINATION=oDestination $
    else $
       oDestination = OBJ_NEW()

    if (OBJ_VALID(oDestination)) then begin
        oDestination->GetProperty, CURRENT_ZOOM=canvasZoom
        visViewportDims = self->GetViewport(oDestination, /VIRTUAL) / $
            canvasZoom
    endif else begin
        canvasZoom = 1.0
        visViewportDims = [0.0,0.0]
    endelse

    ; If the given zoom factor is very near to 1.0, set it to 1.0.
    fpInfo = MACHAR()
    if (ABS(zoomFactor - 1.0) le fpInfo.eps) then $
        zoomFactor = 1.0d

    ; Perform updates only if zoom factor changed.
    if (self.zoomFactor eq zoomFactor) then $
        return

    self.zoomFactor = zoomFactor

    oldVirtualDims = DBLARR(2)
    oldVirtualDims[0] = (self.virtualDims[0] eq 0) ? $
        visViewportDims[0] : self.virtualDims[0]
    oldVirtualDims[1] = (self.virtualDims[1] eq 0) ? $
        visViewportDims[1] : self.virtualDims[1]

    ; Compute normalized center.
    center = (N_ELEMENTS(inCenter) eq 2) ? $
        inCenter : $
        self.visibleLoc + (visViewportDims *0.5)
    normCenter = center / oldVirtualDims

    ; Adjust virtual dimensions.
    origVirtualDims = self.origVirtualDims
    if (origVirtualDims[0] eq 0) then $
        origVirtualDims = visViewportDims

    self.virtualDims = (self.zoomFactor eq 1.0) ? $
        origVirtualDims : (origVirtualDims * self.zoomFactor)

    ; Adjust visible location so center is honored.
    self.visibleLoc = (self.virtualDims * normCenter) - $
        (visViewportDims*0.5)

    ; Constrain to virtual dims.
    if (visViewportDims[0] le self.virtualDims[0]) then begin
        if (self.visibleLoc[0] lt 0) then self.visibleLoc[0] = 0
        if ((self.visibleLoc[0] + visViewportDims[0]) gt $
            self.virtualDims[0]) then $
            self.visibleLoc[0] = (self.virtualDims[0] - visViewportDims[0]) > 0
    endif
    if (visViewportDims[1] le self.virtualDims[1]) then begin
        if (self.visibleLoc[1] lt 0) then self.visibleLoc[1] = 0
        if ((self.visibleLoc[1] + visViewportDims[1]) gt $
            self.virtualDims[1]) then $
            self.visibleLoc[1] = (self.virtualDims[1] - visViewportDims[1]) > 0
    endif

    ; Update each layer.
    oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
    if (nLayers gt 0) then begin
        virtualDims = self->GetVirtualViewport(oDestination)
        normClipLoc = self.visibleLoc / virtualDims
        normClipDims = visViewportDims / virtualDims
        for i=0,nLayers-1 do $
            oViewLayerArr[i]->OnViewZoom, self, oDestination, zoomFactor, $
                [normClipLoc, normClipDims], NO_NOTIFY=noNotify
    endif

    if (~KEYWORD_SET(noNotify)) then begin
        ; Broadcast notification to any interested parties.
        self->DoOnNotify, self->GetFullIdentifier(), 'VIEW_ZOOM', $
            self.zoomFactor

        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            ; Update the view zoom control in the toolbar.
            id = oTool->GetFullIdentifier() + "/TOOLBAR/VIEW/VIEWZOOM"
            oTool->DoOnNotify, id, 'SETVALUE', $
                STRTRIM(ULONG((self.zoomFactor*100)+0.5),2)+'%'
        endif

    endif

    if (~KEYWORD_SET(noUpdates)) then begin
        ; Notify parent.
        self->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene) ne 0) then begin
            oScene->OnDataChange, self
            oScene->OnDataComplete, self
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::GetCurrentLayer
;
; PURPOSE:
;    Retrieves the current layer within the View.
;
; CALLING SEQUENCE:
;    oViewLayer = oView->[IDLitgrView::]GetCurrentLayer()
;
; OUTPUTS:
;    This function method returns a reference to an IDLitgrLayer.
;
;-
function IDLitgrView::GetCurrentLayer

    compile_opt idl2, hidden

    RETURN, self.oCurrViewLayer
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::SetCurrentLayer
;
; PURPOSE:
;    Sets the current Layer within the View.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]SetCurrentLayer, oViewLayer
;
; INPUTS:
;    oViewLayer:    A reference to an IDLitgrLayer that is to
;        become the current ViewLayer within the View.
;
;-
pro IDLitgrView::SetCurrentLayer, oViewLayer

    compile_opt idl2, hidden

    ; Verify that the given layer is contained within the View.
    if (self->IsContained(oViewLayer) eq 0) then $
        MESSAGE, 'The Layer must be contained by the View.'

    self.oCurrViewLayer = oViewLayer
end


;----------------------------------------------------------------------------
; IDLitgrView::GetPixelScaleTargets
;
; Purpose:
;   This function method returns a vector of references to the selected items
;   that are valid pixel scale targets.
;
function IDLitgrView::GetPixelScaleTargets, $
    COUNT=count

    compile_opt idl2, hidden

    count = 0

    oSel = self->GetSelectedItems(COUNT=nSel)
    if (nSel gt 0) then begin
        isImg = OBJ_ISA(oSel, 'IDLITVISIMAGE')
        ind = WHERE(isImg eq 1, nImg)

        ; Seek all images with a valid pixel scale status.
        for i=0,nImg-1 do begin
            oSelImage = oSel[ind[i]]
            if (oSelImage->QueryPixelScaleStatus() eq 1) then begin
                oTargets = (count eq 0) ? [oSelImage] : [oTargets, oSelImage]
                count++
            endif
        endfor

        ; Seek any ROIs whose parent is an image with a valid
        ; pixel scale status.  Add the parent images to the list.
        isROI = OBJ_ISA(oSel, 'IDLITVISROI')
        ind = WHERE(isROI eq 1, nROI)
        for i=0,nROI-1 do begin
            (oSel[ind[i]])->GetProperty, PARENT=oParent
            if (OBJ_ISA(oParent, 'IDLITVISIMAGE')) then begin
                if (oParent->QueryPixelScaleStatus() eq 1) then begin
                    oTargets = (count eq 0) ? $
                        [oParent] : [oTargets, oParent]
                    count++
                endif
            endif
        endfor
        return, ((count gt 0) ? oTargets : OBJ_NEW())
    endif else $
        return, OBJ_NEW()
end

;----------------------------------------------------------------------------
; IDLitgrView::GetPixelDataSize
;
; Purpose:
;   This function method computes the size (in a target's data units)
;   of one device pixel for this view.
;
; Arguments:
;   A reference to the target visualization (in whose data units the
;   result will be computed).
;
function IDLitgrView::GetPixelDataSize, oTarget

    compile_opt idl2, hidden

    ; Pick the pixel in the center of the view.
    cxy = LONG(self.normVirtualLoc + (0.5*self.normVirtualDims)) * $
        self.winDims

    ; Convert to the target's data space.
    oTarget->WindowToVis, [cxy[0],cxy[0]+1], $
        [cxy[1],cxy[1]+1], [0,0], vx, vy, vz

    ; Return the width in target data space.
    w = (vx[1] - vx[0]) * self.zoomFactor
    h = (vy[1] - vy[0]) * self.zoomFactor

    return, [w,h]
end

;----------------------------------------------------------------------------
; IDLitgrView::DisablePixelScale
;
; Purpose:
;   This procedure method disables pixel scale enforcement.
;
pro IDLitgrView::DisablePixelScale

   compile_opt idl2, hidden

    self._bDisablePixelScale = 1b
end

;----------------------------------------------------------------------------
; IDLitgrView::EnablePixelScale
;
; Purpose:
;   This procedure method enables pixel scale enforcement.
;
pro IDLitgrView::EnablePixelScale
    compile_opt idl2, hidden

    self._bDisablePixelScale = 0b
end

;----------------------------------------------------------------------------
; IDLitgrView::EnforcePixelScale
;
; Purpose:
;   This procedure method sets the view zoom factor to honor the
;   current pixel scale for the first selected pixel scale target
;   (if any).
;
; Keywords:
;   NO_NOTIFY: Set this keyword to a non-zero value to indicate that
;     notification to registered objects should not occur.

;   PIXEL_SCALE: Set this keyword to a scalar representing the
;     requested pixel scale to be applied.  The default is 1.0.
;
;   TARGET: Set this keyword to a reference to the visualization
;     for which the pixel scale is to apply.  By default, the first
;     pixel scale target contained within the currently selected
;     view is used as the target.
;
pro IDLitgrView::EnforcePixelScale, $
    NO_NOTIFY=noNotify, $
    PIXEL_SCALE=reqPixelScale, $
    TARGET=oInTarget

    compile_opt idl2, hidden

    ; If pixel scaling has been disabled, do nothing.
    if (self._bDisablePixelScale) then $
        return

    pixelScale = (N_ELEMENTS(reqPixelScale) gt 0) ? $
        reqPixelScale[0] : 1.0

    ; If not provided, seek the target visualization.
    oTarget = (N_ELEMENTS(oInTarget) gt 0) ? oInTarget[0] : OBJ_NEW()
    if (~OBJ_VALID(oTarget)) then begin
        ; Seek the first pixel scale target among selected items.
        oScaleTargets = self->GetPixelScaleTargets(COUNT=nTargets)
        if (nTargets gt 0) then $
            oTarget = oScaleTargets[0]
    endif

    if (OBJ_VALID(oTarget)) then begin
        ; Determine size of one device pixel (in target's data units)
        ; when the view scale factor is 1.0.
        winDataPixel = self->GetPixelDataSize(oTarget)

        ; Determine size of one image pixel (in data units).
        oTarget->GetProperty, PIXEL_XSIZE=imgDataPixel

        ; Update the view zoom factor to accommodate the requested
        ; pixel scale factor.
        ;
        ; Note that NO_UPDATES is set because ::EnforcePixelScale is
        ; only ever called from operations that have updates disabled.
        zoomFactor = winDataPixel[0] / (imgDataPixel * pixelScale)
        self->SetCurrentZoom, zoomFactor, NO_NOTIFY=noNotify, /NO_UPDATES
    endif
end


;----------------------------------------------------------------------------
; IDLitgrView::_UpdateOutline
;
; Purpose:
;   This procedure method updates the outline box around the view.
;
pro IDLitgrView::_UpdateOutline, oDestination

    compile_opt idl2, hidden

    ; Propagate cropped viewport to the outline layer.
    viewDims = self->GetViewport(oDestination, LOCATION=viewLoc)
    self._oViewLayer->SetProperty, $
        DIMENSIONS=viewDims, LOCATION=viewLoc, UNITS=0

    ; Crop the view layer's frustum proportionally.
    cropFrustumRect = DBLARR(4)
    cropFrustumRect[0] = -1.0 + (self.normCropLoc[0] * 2.0)
    cropFrustumRect[1] = -1.0 + (self.normCropLoc[1] * 2.0)
    cropFrustumRect[2] = self.normCropDims[0] * 2.0
    cropFrustumRect[3] = self.normCropDims[1] * 2.0
    self._oViewLayer->SetProperty, VIEWPLANE_RECT=cropFrustumRect

    ; Retrieve the device coordinates of the virtual viewport.
    ; We need to use the "virtual" viewport to redraw the actual outline,
    ; since part of it may not be visible within the window.
    viewportDims = self->GetViewport(oDestination, /VIRTUAL)

    ; Since our outline has a thickness of 1, we need to subtract that
    ; off so it doesn't get clipped. Since we are using normalized coords,
    ; subtract almost 2 pixels to avoid roundoff issues.
    s = 2.0d - (2d/viewportDims)
    t = -1d + 1d/viewportDims

    ; Scale and translate the outline so it fits the view boundary.
    self._oOutline->Reset
    self._oOutline->Scale, s[0], s[1], 1.0
    self._oOutline->Translate, t[0], t[1], 0.0

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::SetViewport
;
; PURPOSE:
;    Sets the visible viewport for the View (relative to the virtual
;    canvas).
;
; CALLING SEQUENCE:
;       oView->[IDLitgrView::]SetViewport, Location, Dimensions
;
; INPUTS:
;    Location:    A two-element vector, [x,y], specifying the location
;        of the lower lefthand corner of the viewport (relative to
;        the lower lefthand corner of the window).
;    Dimensions:    A two-element vector, [width, height], specifying the
;        dimensions of the viewport.
;
; KEYWORD PARAMETERS:
;    FORCE_UPDATE: Set this keyword to a non-zero value to indicate that
;        viewport updates should be forced.  By default, updates only
;        occur if the viewport has actually changed from previous values.
;
;    RESET_SCREEN_SIZES: Set this keyword to a non-zero value to indicate
;        that the screen sizes associated with visualizations (used to
;        honor zoomOnResize=0) should be reset.  By default, the screen
;        sizes remain untouched.
;
;    UNITS:    Set this keyword to a scalar indicating the units in
;        which the viewport location and dimensions are specified.
;        Valid values include:
;            0 = Device (the default)
;            1 = Inches
;            2 = Centimeters
;            3 = Normalized
;
;-
pro IDLitgrView::SetViewport, inLocation, inDimensions, $
    FORCE_UPDATE=forceUpdate, $
    RESET_SCREEN_SIZES=resetScreenSizes, $
    UNITS=inUnits

    compile_opt idl2, hidden

    bVirtualChange = 0b

    viewUnits = (N_ELEMENTS(inUnits) ne 0) ? inUnits : 0 ; Device units.

    ; Walk up the hierarchy to retrieve the destination object.
    self->GetProperty, PARENT=oScene
    if (~OBJ_VALID(oScene)) then $
        RETURN
    oScene->GetProperty, DESTINATION=oDestination
    if (~OBJ_VALID(oDestination)) then $
        RETURN

    ; Get the destination's resolution.
    oDestination->GetProperty, RESOLUTION=destRes

    ; Get the destination's zoom properties.
    ; Note that ZOOM_ON_RESIZE is available only in the _IDLitgrDest class hierarchy.
    if OBJ_ISA(oDestination, '_IDLitgrDest') then begin
        oDestination->GetProperty, $
            ZOOM_ON_RESIZE=zoomOnResize, CURRENT_ZOOM=canvasZoom
    endif else begin
        oDestination->GetProperty, CURRENT_ZOOM=canvasZoom
        zoomOnResize = 0
    endelse

    ; Get the destination's dimensions in device units.
    destDims = oDestination->GetDimensions(VIRTUAL_DIMENSIONS=virtualDestDims)

    if (~ARRAY_EQUAL(self.winDims, virtualDestDims)) then begin
        winDimChange = 1b
    endif else $
        winDimChange = 0b

    ; If either viewport dimension is zero, then it is intended to
    ; match the destination dimension.
    viewportLoc = inLocation
    viewportDims = inDimensions
    if ((viewportDims[0] eq 0) or (viewportDims[1] EQ 0)) then begin
        viewportDims = virtualDestDims
        viewportLoc = [0,0]
        viewUnits = 0
    endif

    ; Conversion factor.
    case viewUnits of
        0 : factor = 1d              ; Device
        1 : factor = 2.54d/destRes   ; Pixels/inch
        2 : factor = 1d/destRes      ; Pixels/centimeter
        3 : factor = virtualDestDims ; Pixels/normalized
    endcase

    ; Convert viewport from input units to device units.
    ; [Visible viewport relative to virtual canvas]
    viewportLoc = viewportLoc * factor
    viewportDims = viewportDims * factor

    ; Don't allow views to be moved outside of the window.
    if (MIN(viewportLoc) lt 0) || $
        MAX((viewportLoc+viewportDims) gt virtualDestDims) then $
        return

    ; [Visible viewport normalized relative to virtual canvas]
    normVirtualDims = viewportDims / virtualDestDims
    normVirtualLoc = viewportLoc / virtualDestDims

    ; [Visible viewport, un-canvas-zoomed]
    visViewportDims = (viewportDims / canvasZoom)

    ; Perform updates only if anything really changed, or a forced
    ; update is requested.
    if ((~ARRAY_EQUAL(normVirtualDims, self.normVirtualDims)) || $
        (~ARRAY_EQUAL(normVirtualLoc, self.normVirtualLoc)) || $
        winDimChange || $
        KEYWORD_SET(forceUpdate)) then begin

	; Compute the center of the previous viewport.
        if ((self.winDims[0] eq 0) || (self.winDims[1] eq 0)) then $
            normCenter = [0.5,0.5] $
        else begin
            ; [Old visible viewport, un-canvas-zoomed]
            oldCanvasZoom = (self.winZoom eq 0.0) ? canvasZoom : self.winZoom
            oldVisViewportDims = (self.normVirtualDims * self.winDims) / $
                oldCanvasZoom

            ; [Old virtual viewport, un-canvas-zoomed]
            oldVirtualDims = DBLARR(2)
            oldVirtualDims[0] = (self.virtualDims[0] eq 0) ? $
                oldVisViewportDims[0] : self.virtualDims[0]
            oldVirtualDims[1] = (self.virtualDims[1] eq 0) ? $
                oldVisViewportDims[1] : self.virtualDims[1]

            ; [Normalized center of old visible relative to old virtual]
            normCenter = (self.visibleLoc + (oldVisViewportDims*0.5)) / $
                oldVirtualDims
        endelse

        ; Cache our new [virtual canvas] window dimensions.
        self.winDims = virtualDestDims

        ; [Visible viewport, normalized to virtual canvas]
        self.normVirtualDims = normVirtualDims
        self.normVirtualLoc = normVirtualLoc

        ; Update virtual viewport dimensions if necessary.
        ; [Virtual viewport, un-canvas-zoomed]
        origVirtualDims = (visViewportDims > self.minVirtualDims)
        if (~ARRAY_EQUAL(origVirtualDims, self.origVirtualDims)) then begin
            self.origVirtualDims = origVirtualDims
            self.virtualDims = self.zoomFactor * origVirtualDims
            bVirtualChange = 1b
        endif

        ; Update visible location [relative to un-canvas-zoomed
        ; virtual viewport]
        self.visibleLoc = (self.virtualDims * normCenter) - $
            (visViewportDims*0.5)

        ; Constrain the visible location.
        if (visViewportDims[0] le self.virtualDims[0]) then begin
            if (self.visibleLoc[0] lt 0) then self.visibleLoc[0] = 0
            if ((self.visibleLoc[0] + visViewportDims[0]) gt $
                self.virtualDims[0]) then $
                self.visibleLoc[0] = $
                    (self.virtualDims[0] - visViewportDims[0]) > 0
        endif
        if (visViewportDims[1] le self.virtualDims[1]) then begin
            if (self.visibleLoc[1] lt 0) then self.visibleLoc[1] = 0
            if ((self.visibleLoc[1] + visViewportDims[1]) gt $
                self.virtualDims[1]) then $
                self.visibleLoc[1] = $
                    (self.virtualDims[1] - visViewportDims[1]) > 0
        endif
    endif

    ; Cache canvas zoom.
    self.winZoom = canvasZoom

    ; Crop the viewport to the scrolled destination.
    self->CropViewport, oDestination, /NO_NOTIFY

    ; Notify each layer of the viewport change.
    virtualDims = self->GetVirtualViewport(oDestination)
    normClipLoc = self.visibleLoc / virtualDims
    normClipDims = visViewportDims / virtualDims
    oViewLayerArr = self->Get(ISA='IDLitgrLayer', /ALL, COUNT=nLayers)
    for i=0,nLayers-1 do $
        oViewLayerArr[i]->OnViewportChange, self, oDestination, $
            virtualDims, [normClipLoc, normClipDims], $
            self.normVirtualDims, $
            bVirtualChange, zoomOnResize, $
            RESET_SCREEN_SIZES=resetScreenSizes

    ; Broadcast notification to any interested parties.
    self->DoOnNotify, self->GetFullIdentifier(), 'VIEWPORT_CHANGE', 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;     IDLitgrView::GetViewport
;
; PURPOSE:
;     Retrieves the viewport for the View.
;
; CALLING SEQUENCE:
;       Result = oView->[IDLitgrView::]GetViewport(oDestination)
;
; INPUTS:
;    oDestination:    A reference to an IDLitWindow or IDLitBuffer whose
;        device resolution is to be taken into account when computing
;        viewport dimensions.
;
; KEYWORD PARAMETERS:
;    LOCATION:    Set this keyword to a named variable that upon
;        return will contain a two-element vector, [x,y], representing
;        the location of the lower-left corner of the viewport.
;    UNITS:    Set this keyword to a scalar indicating the units in
;        which the viewport dimensions and location should be returned.
;        Valid values include:
;            0 = Device (the default)
;            1 = Inches
;            2 = Centimeters
;            3 = Normalized
;    VIRTUAL:    Set this keyword to indicate that the returned
;        viewport should represent the full visible viewport (with location
;        and dimensions relative to the overall virtual canvas of the
;        destination device).  By default, the returned viewport represents
;        the cropped visible viewport (with location and dimensions relative
;        to the visible portion of the scrolled destination).
;        This keyword is mutually exclusive of NORMALIZED_VISIBLE.
;    NORMALIZED_VISIBLE:    Set this keyword to indicate that the returned
;        viewport should represent the full visible portion of the viewport
;        (with location and dimension in normalized units relative to the
;        virtual viewport).  By default, the returned viewport represents the
;        cropped visible portion (with location and dimensions relative to the
;        visible portion of the scrolled destination).  If this keyword is
;        set, the UNITS keyword is ignored (normalized units are assumed).
;        This keyword is mutually exclusive of VIRTUAL.
;
; OUTPUTS:
;    This function method returns a two-element vector, [width,height],
;    representing the dimensions of the viewport.
;
;-
function IDLitgrView::GetViewport, oDestination, $
    LOCATION=viewportLoc, $
    NORMALIZED_VISIBLE=normVisible, $
    UNITS=inUnits, $
    VIRTUAL=virtual

    compile_opt idl2, hidden

    ; Handle special case of NORMALIZED_VISIBLE.
    if (KEYWORD_SET(normVisible)) then begin

        ; Do not allow in conjunction with VIRTUAL keyword.
        if (KEYWORD_SET(virtual)) then $
            MESSAGE, IDLitLangCatQuery('Message:Framework:MutuallyExclusive') + $
              'NORMALIZED_VISIBLE and VIRTUAL'

        ; Return requested normalized visible viewport.
        if (ARG_PRESENT(viewportLoc)) then $
            viewportLoc=self.normCropLoc
        RETURN, self.normCropDims
    endif

    ; Determine requested units (default: device units).
    reqUnits = (N_ELEMENTS(inUnits) ne 0) ? inUnits : 0 ; Device units.

    if (not OBJ_VALID(oDestination)) then begin
        ; Walk up the hierarchy to retrieve the destination object.
        self->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene) eq 0) then $
            RETURN, [0.0, 0.0]

        oScene->GetProperty, DESTINATION=oDestination
        if (OBJ_VALID(oDestination) eq 0) then $
            RETURN, [0.0, 0.0]
    endif

    ; Get the window's resolution.
    oDestination->GetProperty, RESOLUTION=destRes

    ; Get the destination's dimensions in device units.
    destDims = oDestination->GetDimensions($
        VIRTUAL_DIMENSIONS=virtualDestDims, VISIBLE_LOCATION=destScrollLoc)

    viewportLoc = self.normVirtualLoc * virtualDestDims
    viewportDims = self.normVirtualDims * virtualDestDims
    if (KEYWORD_SET(virtual)) then begin
        destDims = virtualDestDims
    endif else begin
        viewportDims *= self.normCropDims
        viewportLoc = (viewportLoc - destScrollLoc) > 0
    endelse

    ; If either viewport dimension is zero, then it is intended to
    ; match the destination dimension.
    if ((viewportDims[0] eq 0) or (viewportDims[1] eq 0)) then begin
        viewportDims = destDims
        viewportLoc = [0,0]
    endif

    ; Conversion factor from Device to requested units.
    case reqUnits of
        1: factor = destRes/2.54d         ; Inches/pixel
        2: factor = destRes               ; Centimeters/pixel
        3: factor = 1d/(destDims)         ; Normalized
        else: factor = 1d                  ; default is Device
    endcase

    ; Convert viewport to requested units.
    viewportLoc *= factor
    viewportDims *= factor

    RETURN, viewportDims
end

;----------------------------------------------------------------------------
; IDLitgrView::GetVirtualViewport
;
; Purpose:
;   This function method retrieves the virtual viewport associated with
;   this view.
;
; Return Value:
;   This function method returns a 2-element vector, [w,h], representing
;   the dimensions (in pixels) of the virtual viewport.
;
; Keywords:
;   UNZOOMED: Set this keyword to a non-zero value to indicate that the
;     returned virtual viewport dimensions should not have the current
;     view zoom factor applied.  By default, the current view zoom factor
;     is applied.
;
function IDLitgrView::GetVirtualViewport, oDestination, UNZOOMED=unzoomed
    compile_opt idl2, hidden

    origVirtualDims = self.origVirtualDims
    if ((origVirtualDims[0] eq 0) || (origVirtualDims[1] eq 0)) then $
        origVirtualDims = self->GetViewport(oDestination, /VIRTUAL)

    return, (KEYWORD_SET(unzoomed) ? $
        origVirtualDims : $
        (origVirtualDims * self.zoomFactor))
end

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::OnDataChange
;
; PURPOSE:
;    The IDLitgrView::OnDataChange procedure method handles
;    notification of pending data changes within the contained
;    visualization hierarchy.
;
; CALLING SEQUENCE:
;    oView->[IDLitgrView::]OnDataChange, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
;-
pro IDLitgrView::OnDataChange, oNotifier

    compile_opt idl2, hidden

    ; Increment the reference count.
    self.geomRefCount = self.geomRefCount + 1

    ; If this is the first notification, notify the parent scene.
    if (self.geomRefCount eq 1) then begin
        self->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene) ne 0) then $
            oScene->OnDataChange, oNotifier
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrView::OnDataComplete
;
; PURPOSE:
;    The IDLitgrView::OnDataComplete procedure method handles
;    notification that recent data changes are complete.
;
; CALLING SEQUENCE:
;       oView->[IDLitgrView::]OnDataComplete, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
;-
pro IDLitgrView::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    ; Decrement reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount = self.geomRefCount - 1

    ; If all children have reported in that they are ready to flush,
    ; then the reference count should be zero and the parent scene
    ; can be notified.
    if (self.geomRefCount eq 0) then begin

        self->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene) ne 0) then $
            oScene->OnDataComplete, oNotifier
    endif
end


;;---------------------------------------------------------------------------
;; IDLitgrView::SetSelectVisual
;;
;; Purpose:
;;   Selection Visual for the View.
;;
pro IDLitgrView::SetSelectVisual, UNSELECT=UNSELECT, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self._oOutline->_Select, _EXTRA=_extra, unselect=unselect
    if (KEYWORD_SET(unselect)) then $
        self->ClearSelections

end


;---------------------------------------------------------------------------
; IDLitgrView::_InsertHighlight
;
; Purpose:
;   Selection for the View.
;
pro IDLitgrView::_InsertHighlight, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self._oOutline->_InsertHighlight, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Select Container Interface
;----------------------------------------------------------------------------

;---------------------------------------------------------------------------
; +
; IDLitGrView::RemoveSelectedItem
;
; PURPOSE:
;  This procedure method removes a selected item from the selection list.
;
; INPUTS:
;   oItem    - The item to remove
;-
pro IDLitGrView::RemoveSelectedItem, oItem

    compile_opt idl2, hidden

    ; Retrieve the first item in the list prior to the removal.
    oFirst = self.m_oSelected->Get(count=count)

    ; If the item to be removed is the first in the list, then
    ; set a flag indicating that the current dataspace needs to
    ; be reset.
    bResetDS = (count eq 0 ? 0 : (oFirst eq oItem) ? 1b : 0b)

    ; Call our superclass.
    self->IDLitSelectContainer::RemoveSelectedItem, oItem

    ; If necessary, reset the current dataspace.
    if (bResetDS ne 0) then begin
        oFirst = self.m_oSelected->Get()
        if(obj_valid(oFirst) && obj_isa(oFirst, "_IdlitVisualization"))then begin
            ;; If the new first item is in the annotation layer, then
            ;; the layer and dataspace need not change.
            ;;
            ;; Otherwise, set the current layer and dataspace to be the
            ;; layer and dataspace that contains the new first item.
            oDS = (OBJ_VALID(oFirst)) ? oFirst->GetDataSpace() : OBJ_NEW()
            oLayer = OBJ_VALID(oDS) ? oDS->_GetLayer() : OBJ_NEW()
            if (OBJ_VALID(oLayer) and $
                ~OBJ_ISA(oLayer, 'IDLitgrAnnotateLayer')) then begin
                self->SetCurrentLayer, oLayer
                oLayer->SetCurrentDataSpace, oDS
            endif
        endif
    endif
end
;;---------------------------------------------------------------------------
;; IDLitGrView::AddSelectedItem
;;
;; Purpose:
;;   Override the method fromt the select container so that this view
;;   is set as current if an item in it is selected.
;;
;; Parameter:
;;    oItem   - The item being added

pro IDLitGRView::AddSelectedItem, oItem
   compile_opt hidden, idl2

   ;; Make sure this view is the current view
   self->getproperty, parent=oscene
   oScene->SetcurrentView,self

   self->IDLitSelectcontainer::AddSelectedItem,oItem

end
;;---------------------------------------------------------------------------
;; IDLitGrView::SetSelectedItem
;;
;; Purpose:
;;   Override the method fromt the select container so that this view
;;   is set as current if an item in it is selected.
;; Parameter:
;;    oItem   - The item being selected

pro IDLitGRView::SetSelectedItem, oItem
   compile_opt hidden, idl2

   ;; Make sure this view is the current view
   self->getproperty, parent=oscene
   if (~OBJ_VALID(oScene)) then $
    return
   oScene->SetcurrentView,self

   self->IDLitSelectcontainer::SetSelectedItem,oItem

end
;;---------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrView::Select
;
; PURPOSE:
;   This procedure method handles notification that this object
;   has been selected.
;
;   If a parameter is not passed in, the mode is determined by
;   the keyword values.
;
;   If no keywords are set, a select operation is used.
;
; CALLING SEQUENCE:
;   Obj->[IDLitGrView::]Select, Mode
;
; INPUTS:
;    Mode     - An integer representing the type of selection to perform.
;      Valid values include:
;                    0 - Unselect
;                    1 - Select
;                    2 - Toggle    (control key)
;
; KEYWORD PARAMETERS:
;   ADDITIVE:   If set, this will just cause a select. You cannot have
;   muliplte views selected at a time
;
;   NO_NOTIFY:  Set this keyword to a nonzero value to indicate that
;     this views's parent should not be notified of the selection.
;     By default, the parent is notified.
;
;   SELECT: Set this keyword to a nonzero value to indicate that
;     this view should be selected (in isolation).  Setting this
;     keyword is equivalent to setting the mode argument to 1.
;
;   TOGGLE: Set this keyword to a nonzero value to indicate that
;     the selection status of this view should be toggled.
;     Setting this keyword is equivalent to setting the mode argument to 2.
;
;   UNSELECT:   Set this keyword to a nonzero value to indicate that
;     this view should be unselected. Setting this keyword is
;     equivalent to setting the mode argument to 0.
;
;
pro IDLitgrView::Select, iMode, $
    ADDITIVE=ADDITIVE, $
    NO_NOTIFY=NO_NOTIFY, $
    SELECT=SELECT, $
    SKIP_MACRO=skipMacro, $
    TOGGLE=TOGGLE, $
    UNSELECT=UNSELECT

    ; pragmas
    compile_opt idl2, hidden

    ; Convert keywords to a mode parameter.
    if (N_PARAMS() ne 1) then begin
        case 1 of
            KEYWORD_SET(UNSELECT) : iMode = 0
            KEYWORD_SET(SELECT)   : iMode = 1
            KEYWORD_SET(ADDITIVE) : iMode = 1
            KEYWORD_SET(TOGGLE)   : iMode = 2
            else                  : iMode = 1  ;; default SELECT
        endcase
    endif else if (iMode lt 0 or iMode gt 3) then $
        return

    ; Check our toggle.
    if (iMode eq 2) then $
        iMode = (self.isSelected ? 0 : 3)

    isSelected = iMode and 1     ; first bit set, we are going to select

    wasSelected = self.isSelected
    self.isSelected = isSelected
    ; If notification is enabled, notify the parent.
    if (not KEYWORD_SET(NO_NOTIFY))then begin
        case iMode of
            0: self->RemoveSelectedItem, self
            1: self->SetSelectedItem, self
        endcase

        if ~keyword_set(skipMacro) then begin
            oTool = self->GetTool()
            if (OBJ_VALID(oTool)) then begin
                oSrvMacro = oTool->GetService('MACROS')
                if OBJ_VALID(oSrvMacro) then begin
                    case iMode of
                       0: macroMode = 2
                       1: macroMode = 0
                    endcase
                    ; SELECTION_TYPE=1, position in container
                    oSrvMacro->AddSelectionChange, self, $
                        MODE=macroMode,   $
                        SELECTION_TYPE=1
                endif
            endif
        endif

    endif
    ;; Now make sure we are the current view
    if(self.isSelected ne 0)then begin
        self->getproperty, parent=oScene
        oScene->SetcurrentView, self
    endif
end
;;---------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrView::IsSelected
;
; PURPOSE:
;   This function method reports whether this view is currently
;   selected.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitGrView::]IsSelected()
;
; OUTPUTS:
;   This function returns a 1 if this view is currently
;   selected, or 0 otherwise.

function IDLitGrView::IsSelected

    compile_opt idl2, hidden

    return, self.isSelected
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitgrView__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitgrView object.
;
;-
pro IDLitgrView__define

    compile_opt idl2, hidden

    void = {IDLitgrView,              $
        inherits _IDLitContainer,     $ ; for indentification
        inherits IDLgrViewGroup,      $ ; Superclass
        inherits IDLitSelectContainer,$ ; Superclass
        inherits IDLitIMessaging,     $ ; Superclass for messaging
        isSelected: 0,                $ ; for selection
                                      $ ; -- Visible Viewport: -------------
        normVirtualDims: DBLARR(2),   $ ; Visible: (normalized relative to
        normVirtualLoc: DBLARR(2 ),   $ ;   virtual device canvas)
        normCropDims: DBLARR(2),      $ ; Cropped Visible: (normalized
        normCropLoc: DBLARR(2),       $ ;   relative to full visible viewport)
        winDims: LONARR(2),           $ ; Window virtual dimensions.
        winZoom: 0.0d,                $ ; Canvas zoom factor.  (Zero means
                                      $ ;   retrieve from parent window.)
        isHidden: 0b,                 $ ; User set hidden?
                                      $ ; --Virtual Viewport: --------------
                                      $ ; Note: all pixel dimensions for
                                      $ ;   the virtual viewport do NOT account
                                      $ ;   for canvas zoom.
        virtualDims: DBLARR(2),       $ ; Virtual: (pixels, view-zoomed)
        origVirtualDims: DBLARR(2),   $ ; Virtual: (pixels, un-view-zoomed)
        minVirtualDims: DBLARR(2),    $ ; Virtual minimum: (pixels,
                                      $ ;   un-view-zoomed)
        visibleLoc: DBLARR(2),        $ ; Visible: (pixels relative to
                                      $ ;   virtual viewport)
                                      $ ; ---------------------------------
        oCurrViewLayer: OBJ_NEW(),    $ ; Current ViewLayer
        _oOutline: OBJ_NEW(),         $ ; Selection box
        _oViewLayer: OBJ_NEW(),       $
        geomRefCount: 0UL,            $ ; Reference count for data changes
        zoomFactor: 1.0d,             $ ; Current zoom factor
        _windowZoom: 1.0d,            $ ; Correction for window dims
                                        ; (Phased out in IDL 6.1, but kept
                                        ; for restore issues.)
        _bDisablePixelScale: 0b       $ ; Pixel scale enforcement disabled?
    }
end
