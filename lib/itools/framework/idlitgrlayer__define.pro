; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgrlayer__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitgrLayer
;
; PURPOSE:
;    The IDLitgrLayer class represents a layer (within a View) in
;    which visualizations are drawn.
;
; MODIFICATION HISTORY:
;     Written by:    DLD, Mar. 2001.
;-

;----------------------------------------------------------------------------
; IDLitgrLayer::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitgrLayer::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitgrLayer::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll || (updateFromVersion lt 800)) then begin
      ; _PROJECTION was renamed to PERSPECTIVE in IDL80.
      self->RegisterProperty, 'PERSPECTIVE', $
        NAME='Perspective', $
        ENUMLIST=['Orthogonal', 'Perspective'], $
        DESCRIPTION='Perspective', /ADVANCED_ONLY
    endif

    if (registerAll) then begin
        ; Create and register property descriptors.
        self->RegisterProperty, 'STRETCH_TO_FIT', /BOOLEAN, $
            NAME='Stretch to fit', $
            DESCRIPTION='Stretch visualization layer to fit viewport', $
            /HIDE, /ADVANCED_ONLY

        ; Adjust property attributes.
        self->SetPropertyAttribute, /HIDE, $
           ['DEPTH_CUE', $
            'DIMENSIONS', $
            'DOUBLE', $
            'EYE', $
            'LOCATION', $
            'PROJECTION', $
            'UNITS', $
            'VIEWPLANE_RECT', $
            'ZCLIP']
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
    
        self->RegisterProperty, 'XMARGIN', $
            NAME='X margin', $
            DESCRIPTION='Normalized width of margin', $
            /FLOAT, VALID_RANGE=[0d,0.49d], $
            /HIDE, /ADVANCED_ONLY
            
        self->RegisterProperty, 'YMARGIN', $
            NAME='Y margin', $
            DESCRIPTION='Normalized height of margin', $
            /FLOAT, VALID_RANGE=[0d,0.49d], $
            /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'DEPTHCUE_BRIGHT', /FLOAT, $
            NAME='Depth cue bright', $
            DESCRIPTION='Depth cue distance for brightness', $
            VALID_RANGE=[-1,1,0.05d], /ADVANCED_ONLY

        self->RegisterProperty, 'DEPTHCUE_DIM', /FLOAT, $
            NAME='Depth cue dim', $
            DESCRIPTION='Depth cue distance for dimness', $
            VALID_RANGE=[-1,1,0.05d], /ADVANCED_ONLY
    endif

    if (~registerAll && (updateFromVersion ge 610) && $
        (updateFromVersion lt 710)) then begin
        ; MARGIN_2D_X became XMARGIN in IDL71.
        self->SetPropertyAttribute, 'MARGIN_2D_X', /HIDE
        ; MARGIN_2D_Y became YMARGIN in IDL71.
        self->SetPropertyAttribute, 'MARGIN_2D_Y', /HIDE
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::Init
;
; PURPOSE:
;    Initializes an IDLitgrLayer object.
;
; CALLING SEQUENCE:
;    oLayer = OBJ_NEW('IDLitgrLayer')
;
;        or
;
;    Result = oLayer->[IDLitgrLayer::]Init()
;
; KEYWORD PARAMETERS:
;    <Accepts all keywords accepted by the superclasses, plus the following:>
;
;    STRETCH_TO_FIT (Get,Set):  Set this keyword to indicate that the
;        visualization contents should be stretched to fill the viewport.
;        By default, the visualizations are scaled to fit the smallest
;        of the viewport dimensions, thereby maintaining aspect ratio.
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 if initialization
;    fails.
;
;-
function IDLitgrLayer::Init, $
    CURRENT_ZOOM=currentZoom, $
    STRETCH_TO_FIT=stretchToFit, $
    TOOL=tool, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitiMessaging::Init(TOOL=tool, _EXTRA=_extra)) then $
        return, 0

    if (~self->IDLgrView::Init(/REGISTER_PROPERTIES, $
        NAME='Layer', ICON='layer',$
        DESCRIPTION='View Layer', $
        _EXTRA=_extra)) then $
        return, 0

    oWorld = OBJ_NEW('IDLitgrWorld', TOOL=TOOL)
    if (OBJ_VALID(oWorld) eq 0) then begin
        self->Cleanup
        return, 0
    endif
    oWorld->SetProperty, _PARENT=SELF
    self->IDLgrView::Add, oWorld

    if (~self->_IDLitContainer::Init(CLASSNAME='IDLitVisDataSpaceRoot', $
        CONTAINER=oWorld->_GetDataSpaceRoot())) then begin
        self->Cleanup
        return, 0
    endif


    ; The origFrustumRect represents the rectangle before it is
    ; corrected for aspect ratio (if this is flagged to occur), and/or
    ; zooming.
    ;
    ; The virtual frustum settings reflect the corrected view frustum for
    ; the full virtual canvas.  If the window has no scrolling, this is
    ; the frustum used.  If the window has scrolling, this full frustum
    ; will be cropped to accommodate the displayed portion of the scrolled
    ; window.
    self.origFrustumRect = [-1, -1, 2, 2]
    self.aspectFrustumRect = [-1, -1, 2, 2]
    self.virtualFrustumRect = [-1, -1, 2, 2]

    ; Set the Z clipping planes.
    zclip = [1, -1]

    ; Ensure that the eye location is outside the new view volume.
    self->GetProperty, EYE=eye
    if eye le zclip[0] then $
        self->IDLgrView::SetProperty, EYE=zclip[0] + 0.1

    self.bAspect = 1b

    self.margin2DX = 0.05d
    self.margin2DY = 0.05d

    ; Mark the frustum rectangle as dirty for both aspect ratio
    ; correction and zoom correction.
    self.bFrustumDirty = 1b

    ; Register all properties.
    self->IDLitgrLayer::_RegisterProperties

    ; Pass along keyword values to the ::SetProperty method.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitgrLayer::SetProperty, _EXTRA=_extra

    RETURN, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::Cleanup
;
; PURPOSE:
;    Performs all cleanup for an IDLitgrLayer object.
;
; CALLING SEQUENCE:
;    OBJ_DESTROY, oLayer
;
;        or
;
;    oLayer->[IDLitgrLayer::]Cleanup
;
;-
pro IDLitgrLayer::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclasses.
    self->_IDLitContainer::Cleanup
    self->IDLgrView::Cleanup
    ; IDLitSelectParent has no Cleanup method

end

;----------------------------------------------------------------------------
; IDLitgrLayer::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitgrLayer::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    ; self->_IDLitContainer::Restore
    ; self->IDLgrView::Restore
    ; self->IDLitSelectParent::Restore
    ; self->IDLitIMessaging::Restore

    ; Register new properties.
    self->IDLitgrLayer::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; In IDL60 the World used to be our container "class".
        ; Now, the DataspaceRoot within the World is our container class.
        self->_IDLitContainer::GetProperty, CONTAINER=oOldWorld
        oWorld = self->GetWorld()
        ; Verify that our world was indeed our container class. This isn't
        ; true for the Annotation Layer, which we don't want to mess with.
        if (oWorld eq oOldWorld) then begin
            self->_IDLitContainer::SetProperty, $
                CLASSNAME='IDLitVisDataSpaceRoot', $
                CONTAINER=oWorld->_GetDataSpaceRoot()
        endif

        self.margin2DX = 0.05d
        self.margin2DY = 0.05d
        ; Note: while it is tempting to restore each contained
        ; dataspace and recompute padding and normalization here,
        ; this is not a good place to perform these updates since
        ; the restore can occur before the visualization hierarchy
        ; has been added to the window.  Therefore, the updates
        ; will have to wait until a simulated viewport update occurs
        ; (after the visualization hierarchy is added to the window).
    endif
end

;----------------------------------------------------------------------------
; PURPOSE:
;   This function method initializes any heavyweight portions of this
;   visualization.  [Note: the bare essentials for the object are initialized
;   within the ::Init method.]
;
function IDLitgrLayer::Create
    compile_opt idl2, hidden
    return, 1
end

;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method cleans up the the heavyweight portion of the
;   object, leaving only the bare essential portions of the object
;   (that may be cleaned up via the ::Cleanup method).
;
pro IDLitgrLayer::Shutdown
    compile_opt idl2, hidden
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::GetProperty
;
; PURPOSE:
;    The IDLitgrLayer::GetProperty procedure method retrieves the
;    value of a property or group of properties.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]GetProperty
;
; KEYWORD PARAMETERS:
;    Any keyword to IDLitgrLayer::Init followed by the word "Get"
;    can be retrieved using IDLitgrLayer::GetProperty.
;
;-
pro IDLitgrLayer::GetProperty, $
    _PROJECTION=_projection, $   ; keep for backwards compat
    DEPTHCUE_BRIGHT=depthBright, $
    DEPTHCUE_DIM=depthDim, $
    PERSPECTIVE=perspective, $
    XMARGIN=margin2DX, $
    YMARGIN=margin2DY, $
    MARGIN_2D_X=margin2DXOld, $  ; Keep for BC
    MARGIN_2D_Y=margin2DYOld, $  ; Keep for BC
    STRETCH_TO_FIT=stretchToFit, $
    VIRTUAL_VIEWPLANE_RECT=virtualFrustumRect, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(stretchToFit) ne 0) then $
        stretchToFit = 1L - self.bAspect

    ; _PROJECTION was renamed to PERSPECTIVE in IDL80
    if (ARG_PRESENT(perspective) || ARG_PRESENT(_projection)) then begin
        self->IDLgrView::GetProperty, PROJECTION=projection
        perspective = (projection - 1) > 0
        _projection = perspective
    endif

    if (ARG_PRESENT(depthBright) || ARG_PRESENT(depthDim)) then begin
        self->IDLgrView::GetProperty, DEPTH_CUE=depthCue
        depthBright = depthCue[0]
        depthDim = depthCue[1]
    endif

    if (ARG_PRESENT(virtualFrustumRect)) then $
        virtualFrustumRect = self.virtualFrustumRect

    if (ARG_PRESENT(margin2DX)) then $
        margin2DX = self.margin2DX

    if (ARG_PRESENT(margin2DY)) then $
        margin2DY = self.margin2DY

    ; Keep for BC
    if (ARG_PRESENT(margin2DXOld)) then $
        margin2DXOld = self.margin2DX
    if (ARG_PRESENT(margin2DYOld)) then $
        margin2DYOld = self.margin2DY

    ; Retrieve property values from the superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLgrView::GetProperty, _EXTRA=_extra
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::SetProperty
;
; PURPOSE:
;    The IDLitgrLayer::SetProperty procedure method sets the
;    value of a property or group of properties.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]SetProperty
;
; KEYWORD PARAMETERS:
;    <Accepts any keyword accepted by the superclass ::SetProperty method.>
;
;-
pro IDLitgrLayer::SetProperty, $
    _PROJECTION=_projection, $   ; keep for backwards compat
    PERSPECTIVE=perspective, $
    DEPTHCUE_BRIGHT=depthBright, $
    DEPTHCUE_DIM=depthDim, $
    XMARGIN=margin2DX, $
    YMARGIN=margin2DY, $
    STRETCH_TO_FIT=stretchToFit, $
    NO_PADDING_UPDATES=noPaddingUpdates, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    bAspectChange = 0b
    bProjChange = 0b
    bRedraw = 0b
    bWinDimChange = 0b
    bRecomp2DPadding = 0b

    ; Some keyword settings require information about the view.
    ; In these cases, retrieve the view only once.
    if ((N_ELEMENTS(margin2DX) gt 0) || $
        (N_ELEMENTS(margin2DY) gt 0) || $
        (N_ELEMENTS(stretchToFit) gt 0)) then begin

        oldMargins = [self.margin2DX,self.margin2DY]

        self->GetProperty, PARENT=oView
        if (OBJ_VALID(oView)) then $
            oView->IDLgrViewGroup::GetProperty, _PARENT=oWin $
        else $
            oWin = OBJ_NEW()

        if (OBJ_VALID(oWin)) then begin
            oWin->GetProperty, ZOOM_ON_RESIZE=zoomOnResize, $
                CURRENT_ZOOM=canvasZoom
            origVirtualViewDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
        endif else begin
            canvasZoom = 1.0
            zoomOnResize = 0
            origVirtualViewDims = [10000,10000]
        endelse
    endif

    if (N_ELEMENTS(stretchToFit) ne 0) then begin
        bNewAspect = (stretchToFit eq 0)
        if (self.bAspect ne bNewAspect) then begin

            self.bAspect = bNewAspect
            self.bFrustumDirty = 1b

            ; Re-compute 2D padding for all dataspaces.
            resetScreenSizes = 1b
            if (~KEYWORD_SET(noPaddingUpdates)) then $
                bRecomp2DPadding = 1b
            bAspectChange = 1b
            bRedraw = 1b
        endif
    endif

    ; _PROJECTION was renamed to PERSPECTIVE in IDL80
    if (N_ELEMENTS(_projection) ne 0) then $
      perspective = _projection

    if (N_ELEMENTS(perspective) ne 0) then begin
        newProj = (perspective + 1) < 2
        if (self.projection ne newProj) then begin
            self->IDLgrView::SetProperty, PROJECTION=newProj
            bProjChange = 1b
            bRedraw = 1b
        endif
    endif

    if (N_ELEMENTS(depthBright) || N_ELEMENTS(depthDim)) then begin
        bChange = 0b
        self->IDLgrView::GetProperty, DEPTH_CUE=depthCue
        if (N_ELEMENTS(depthBright) eq 1) then begin
            if (depthBright ne depthCue[0]) then begin
                bChange = 1b
                depthCue[0] = depthBright
            endif
        endif
        if (N_ELEMENTS(depthDim) eq 1) then begin
            if (depthDim ne depthCue[1]) then begin
                bChange = 1b
                depthCue[1] = depthDim
            endif
        endif
        if (bChange) then begin
            self->IDLgrView::SetProperty, DEPTH_CUE=depthCue
            bRedraw = 1b
        endif
    endif

    bNewMargin = 0b

    if (N_ELEMENTS(margin2DX) gt 0) then begin
        newMargin = (0.0d > margin2DX) < 0.49d
        newMargin = self->_RoundMargin(newMargin)
        if (self.margin2DX ne newMargin) then begin
            self.margin2DX = newMargin
            newMargin = [1,0]
            bNewMargin = 1b
        endif
    endif

    if (N_ELEMENTS(margin2DY) gt 0) then begin
        newMargin = (0.0d > margin2DY) < 0.49d
        newMargin = self->_RoundMargin(newMargin)
        if (self.margin2DY ne newMargin) then begin
            self.margin2DY = newMargin
            newMargin = bNewMargin ? [1,1] : [0,1]
            bNewMargin = 1b
        endif
    endif

    if (bNewMargin) then begin

        ; If the margin changed, and this viewport fits within the
        ; window, then update the virtual dimensions.
        if ((~KEYWORD_SET(noPaddingUpdates)) && OBJ_VALID(oWin)) then begin
            if (~zoomOnResize) then begin
                ; Seek the dataspaces with the minimum padding.
                nDS = 0
                nValid = 0
                minXPad = 0.0d
                minYPad = 0.0d
                oWorld = self->GetWorld()
                oDS = OBJ_VALID(oWorld) ? $
                    oWorld->GetDataSpaces(COUNT=nDS) : OBJ_NEW()
                for i=0,nDS-1 do begin
                    if (OBJ_ISA(oDS[i], 'IDLitVisNormalizer')) then begin
                        oDS[i]->IDLitVisNormalizer::GetProperty, $
                            PAD_2D_X=xpad, PAD_2D_Y=ypad, $
                            PAD_2D_VALID=paddingValid
                        if (~paddingValid) then begin
                            paddingValid = $
                                oDS[i]->IDLitVisNormalizer::Compute2DPadding( $
                                    origVirtualViewDims, oldMargins, $
                                    (1-self.bAspect), zoomOnResize, $
                                    COMPUTED_PAD_X=xpad, COMPUTED_PAD_Y=ypad)
                        endif
                        if (~paddingValid) then $
                            continue

                        if (nValid eq 0) then begin
                            oMinXDS = oDS[i]
                            minXPad = xpad
                            oMinYDS = oDS[i]
                            minYPad = ypad
                        endif else begin
                            if (xpad lt minXPad) then begin
                                oMinXDS = oDS[i]
                                minXPad = xpad
                            endif
                            if (ypad lt minYPad) then begin
                                oMinYDS = oDS[i]
                                minYPad = ypad
                            endif
                        endelse
                        nValid++
                    endif
                endfor

                if (nValid gt 0) then begin
                    oMinXDS->IDLitVisNormalizer::GetProperty, $
                        SCREEN_XSIZE=pixelXLen
                    layerW = pixelXLen / (1.0d - (2.0*self.margin2DX))

                    oPixelatedObj = oMinXDS->Is3D() ? $
                        OBJ_NEW() : oMinXDS->SeekPixelatedVisualization()

                    oMinYDS->IDLitVisNormalizer::GetProperty, $
                        SCREEN_YSIZE=pixelYLen
                    layerH = pixelYLen / (1.0d - (2.0*self.margin2DY))

                    if (~OBJ_VALID(oPixelatedObj)) then $
                        oPixelatedObj = oMinYDS->Is3D() ? $
                            OBJ_NEW() : oMinYDS->SeekPixelatedVisualization()

                    bWinDimChange = 1b
                endif
            endif else begin
                bRecomp2DPadding = 1b
                bRedraw = 1b
            endelse
        endif
    endif

    ; Set properties on the superclass.
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLgrView::SetProperty, _EXTRA=_extra

        ; We'll assume that any property settings on the
        ; IDLgrView cause a redraw.
        bRedraw = 1b
    endif

    if (bWinDimChange) then begin
        ; This will force a redraw.
        viewportDims = oView->GetViewport(oWin, /VIRTUAL)
        destDims = oWin->GetDimensions(VIRTUAL_DIMENSIONS=virtualDestDims)
        if ((viewportDims[0] eq virtualDestDims[0]) && $
            (viewportDims[1] eq virtualDestDims[1])) then begin
            oWin->SetProperty, VIRTUAL_WIDTH=layerW, VIRTUAL_HEIGHT=layerH

            ; Also set the minimum virtual dimensions on the
            ; view, so that if a viewport change occurs later
            ; (as for a layout change), the minimum will be honored.
            if (OBJ_VALID(oPixelatedObj)) then begin
                oWin->GetProperty, CURRENT_ZOOM=canvasZoom
                newViewDims = [layerW,layerH] / canvasZoom
                oView->GetProperty, CURRENT_ZOOM=viewZoom
                oView->SetProperty, $
                    VIRTUAL_WIDTH=newViewDims[0]*viewZoom, $
                    VIRTUAL_HEIGHT=newViewDims[1]*viewZoom
            endif

        endif else begin
            oView->GetProperty, CURRENT_ZOOM=viewZoom
            oView->SetProperty, $
                VIRTUAL_WIDTH=layerW*viewZoom, VIRTUAL_HEIGHT=layerH*viewZoom
        endelse
    endif else if (bRedraw) then begin
        if (bRecomp2DPadding) then begin
            ; Re-compute padding for all dataspaces to match new
            ; margins and/or stretch-to-fit settings.
            origVirtualViewDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
            self->_RecomputeMargins,  origVirtualViewDims, zoomOnResize, $
                RESET_SCREEN_SIZES=resetScreenSizes, NEW_MARGIN=newMargin
        endif
        if (Obj_Valid(oView)) then oView->OnResize, oWin

        ; Redraw.
        self->OnDataChange, self
        self->OnDataComplete
    endif

    if (bAspectChange) then begin
        ; Broadcast notification to any interested parties.
        self->DoOnNotify, self->GetFullIdentifier(), $
            'ASPECT_RATIO_CHANGE', 1
    endif

    if (bProjChange) then begin
        ; Broadcast notification to any interested parties.
        self->DoOnNotify, self->GetFullIdentifier(), $
            'PROJECTION_CHANGE', 1
    endif

end


;----------------------------------------------------------------------------
; IDLitgrLayer::RestoreMargins
;
; Purpose:
;   This procedure method restores the layer margins to the given values.
;   [This is useful for handling the undo of some operations.]
;
pro IDLitgrLayer::RestoreMargins, margins
    compile_opt idl2, hidden

    self->GetProperty, PARENT=oView
    if (OBJ_VALID(oView)) then $
        oView->IDLgrViewGroup::GetProperty, _PARENT=oWin $
    else $
        oWin = OBJ_NEW()

    if (OBJ_VALID(oWin)) then begin
        oWin->GetProperty, ZOOM_ON_RESIZE=zoomOnResize, $
            CURRENT_ZOOM=canvasZoom
        origVirtualViewDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
    endif else begin
        canvasZoom = 1.0
        zoomOnResize = 0
        origVirtualViewDims = [10000,10000]  ; used for rounding margins
    endelse

    self.margin2DX = margins[0]
    self.margin2DY = margins[1]

    self->_RecomputeMargins, origVirtualViewDims, zoomOnResize, $
        /RESET_SCREEN_SIZES
end

;----------------------------------------------------------------------------
; IIDLLayer Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::_CorrectForAspectRatio
;
; PURPOSE:
;    Computes appropriate viewplane rectangle to maintain aspect ratio
;    of the view volume XYZ range relative to the destination device's
;    dimensions.
;
;    Returns 1 if the frustum rectangle corrected for aspect ratio
;    has changed, or 0 if no change was required.
;
; CALLING SEQUENCE:
;    bChange = oLayer->[IDLitgrLayer::]_CorrectForAspectRatio(virtualViewDims)
;
; INPUTS:
;    virtualViewDims: A two-element vector, [width, height], specifying the
;        dimensions (in device units) of the (virtual, un-cropped) viewport
;        in which the aspect ratio of the visualization data is to be
;        maintained.
;
;-
pro IDLitgrLayer::_CorrectForAspectRatio, virtualViewDims

    compile_opt idl2, hidden

    ; If aspect ratio is not intended to be maintained, then
    ; no correction needs to be applied.
    if (self.bAspect eq 0) then begin
        self.aspectFrustumRect = self.origFrustumRect
        return
    endif

    ; Grab original (un-corrected) frustum.
    viewplaneRect = self.origFrustumRect

    ; Compute the aspect ratio of the viewport.
    aspect = virtualViewDims[0] / virtualViewDims[1]

    ; Apply correction to the frustum.
    if (aspect gt 1) then begin
        viewplaneRect[0] = viewplaneRect[0] - $
            ((aspect*viewplaneRect[2] - viewplaneRect[2]) / 2.0)
        viewplaneRect[2] = viewplaneRect[2] * aspect
    endif else begin
        viewplaneRect[1] = viewplaneRect[1] - $
            (((1.0/aspect)*viewplaneRect[3] - viewplaneRect[3]) / 2.0)
        viewplaneRect[3] = viewplaneRect[3] / aspect
    endelse

    ; Store corrected viewplane rectangle.
    self.aspectFrustumRect = viewplaneRect

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::_CorrectForZoom
;
; PURPOSE:
;    Updates the virtual frustum rectangle to account for current zooming
;    factors.
;
;    Returns 1 if the frustum rectangle corrected for zoom
;    has changed, or 0 if no change was required.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]_CorrectForZoom, normClipRect
;
; INPUTS:
;    normClipRect: A 4-element vector, [x,y,w,h], representing
;      the (un-canvas-zoomed) visible viewport rectangle (in
;      normalized coordinates relative to the virtual viewport)
;
;-
pro IDLitgrLayer::_CorrectForZoom, normClipRect

    compile_opt idl2, hidden

    ; Re-compute the viewplane rectangle based on the current zoom.
    newVirtualW =  normClipRect[2] * self.aspectFrustumRect[2]
    newVirtualH =  normClipRect[3] * self.aspectFrustumRect[3]
    newVirtualX =  (normClipRect[0] * self.aspectFrustumRect[2]) + $
        self.aspectFrustumRect[0]
    newVirtualY =  (normClipRect[1] * self.aspectFrustumRect[3]) + $
        self.aspectFrustumRect[1]

    self.virtualFrustumRect = [newVirtualX, newVirtualY, $
        newVirtualW, newVirtualH]
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::ResetVirtualFrustumRect
;
; PURPOSE:
;    Marks the virtual frustum rectangle as being dirty and requiring
;    recomputation.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]ResetVirtualFrustumRect
;
;-
pro IDLitgrLayer::ResetVirtualFrustumRect

    compile_opt idl2, hidden

    self.bFrustumDirty = 1b
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::ComputeVirtualFrustumRect
;
; PURPOSE:
;    Computes the virtual frustum rectangle from the original frustum
;    rectangle by correcting for aspect ratio and zooming according
;    to current factors.
;
;    Returns 1 if the frustum rectangle has changed, or 0 if no change
;    was required.
;
; CALLING SEQUENCE:
;    bChange = oLayer->[IDLitgrLayer::]ComputeVirtualFrustumRect( $
;        virtualViewDims, normClipRect)
;
; INPUTS:
;    virtualViewDims: A two-element vector, [width, height], specifying the
;        dimensions (in device units) of the (virtual, un-cropped) viewport
;        in which the aspect ratio of the visualization data is to be
;        maintained.
;
;    normClipRect: A 4-element vector, [x,y,w,h], representing
;      the (un-canvas-zoomed) visible viewport rectangle (in
;      normalized coordinates relative to the virtual viewport)
;
;-
function IDLitgrLayer::ComputeVirtualFrustumRect, virtualViewDims, normClipRect

    compile_opt idl2, hidden

    isDirty = self.bFrustumDirty

    if (isDirty) then begin

        ; Correct for aspect ratio as needed.
        self->_CorrectForAspectRatio, virtualViewDims

        ; Correct for current zoom factors.
        self->_CorrectForZoom, normClipRect

        ; Clear the dirty flag.
        self.bFrustumDirty = 0

    endif

    return, isDirty

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::GetViewPlaneRect
;
; PURPOSE:
;    The IDLitgrLayer::GetViewPlaneRect procedure method retrieves
;    the requested viewplane rectangle(s) associated with this layer.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]GetViewPlaneRect, $
;        ASPECT_RATIO_CORRECTED=namedVar, $
;        ORIGINAL=namedVar, $
;        ZOOM_CORRECTED=namedVar
;
; KEYWORDS:
;    ASPECT_RATIO_CORRECTED: Set this keyword to a named variable that
;      upon return will contain the 4-element vector, [x,y,w,h],
;      representing the viewplane rectangle of this layer after it
;      has been corrected for aspect ratio.
;
;    ORIGINAL: Set this keyword to a named variable that
;      upon return will contain the 4-element vector, [x,y,w,h],
;      representing the original viewplane rectangle of this layer
;      (before aspect ratio or zoom corrections have been applied).
;
;    ZOOM_CORRECTED: Set this keyword to a named variable that
;      upon return will contain the 4-element vector, [x,y,w,h],
;      representing the viewplane rectangle of this layer after it
;      has been corrected for both aspect ratio and zooming.
;
;-
pro IDLitgrLayer::GetViewPlaneRect, $
    ASPECT_RATIO_CORRECTED=aspectRect, $
    ORIGINAL=origRect, $
    ZOOM_CORRECTED=zoomRect

    compile_opt idl2, hidden

    if (ARG_PRESENT(aspectRect)) then $
        aspectRect = self.aspectFrustumRect

    if (ARG_PRESENT(origRect)) then $
        origRect = self.origFrustumRect

    if (ARG_PRESENT(zoomRect)) then $
        zoomRect = self.virtualFrustumRect
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::CropFrustum
;
; PURPOSE:
;    The IDLitgrLayer::CropFrustum procedure method crops the
;    virtual viewplane rectangle of the frustum to the visible portion
;    of the scrolling destination.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]CropFrustum, oDestination
;
; INPUTS:
;    oDestination: A reference to the (scrolling) destination object.
;
;-
pro IDLitgrLayer::CropFrustum, oDestination

    compile_opt idl2, hidden

    ; Walk up the tree to get the parent View.
    self->GetProperty, PARENT=oView
    if (OBJ_VALID(oView) eq 0) then $
        RETURN

    ; Propagate the parent View's cropped viewport to this layer.
    viewDims = oView->GetViewport(oDestination, LOCATION=viewLoc)
    self->IDLgrView::SetProperty, LOCATION=viewLoc, DIMENSIONS=viewDims, $
        UNITS=0

    ; Crop the frustum proportionally with the View's cropping.
    normCropDims = oView->GetViewport(LOCATION=normCropLoc, $
        /NORMALIZED_VISIBLE)

    cropFrustumRect = DBLARR(4)
    cropFrustumRect[0] = self.virtualFrustumRect[0] + $
        (normCropLoc[0] * self.virtualFrustumRect[2])
    cropFrustumRect[1] = self.virtualFrustumRect[1] + $
        (normCropLoc[1] * self.virtualFrustumRect[3])
    cropFrustumRect[2] = normCropDims[0] * self.virtualFrustumRect[2]
    cropFrustumRect[3] = normCropDims[1] * self.virtualFrustumRect[3]

    ; For non-annotation layers, adjust Z clip planes to enclose any
    ; rotation of the view rect.
    if (~OBJ_ISA(self, 'IDLitgrAnnotateLayer')) then begin
        zDepth = ((cropFrustumRect[2] > cropFrustumRect[3]) * 1.73205)

        ; Account for view and canvas zoom.
        oView->GetProperty, CURRENT_ZOOM=viewZoom
        if (viewZoom gt 1.0) then $
            zDepth *= viewZoom

        oView->GetProperty, PARENT=oScene
        if (OBJ_VALID(oScene)) then $
            oScene->GetProperty, DESTINATION=oDest $
        else $
            oDest = OBJ_NEW()
        if (OBJ_VALID(oDest)) then $
            oDest->GetProperty, CURRENT_ZOOM=canvasZoom $
        else $
            canvasZoom = 1.0
        if (canvasZoom gt 1.0) then $
            zDepth *= canvasZoom

        zClip = zDepth eq 0 ? [1, -1] : [zDepth/2, -zDepth/2]
        eye = zClip[0]+.1
    endif

    ; Commit the cropped frustum.
    self->IDLgrView::SetProperty, VIEWPLANE_RECT=cropFrustumRect, $
        ZCLIP=zClip, EYE=eye

end

;----------------------------------------------------------------------------
; IDLitgrLayer::_RoundMargin
;
function IDLitgrLayer::_RoundMargin, inMargin
    compile_opt idl2, hidden

    ; Round to three decimal places.
    outMargin = ROUND(inMargin*1000.0d)/1000.0d

    return, outMargin
end


;----------------------------------------------------------------------------
; IDLitgrLayer::_RecomputeMargins
;
; Purpose:
;   This procedure method recomputes the margins for the layer.
;
; Arguments:
;   virtualViewDims: A 2-element vector, [w,h], representing the
;     dimensions of the uncropped, unzoomed virtual viewport.
;
;   zoomOnResize: A boolean flag indicating whether data content
;     should zoom when the viewport resizes.
;
pro IDLitgrLayer::_RecomputeMargins, virtualViewDims, zoomOnResize, $
    NEW_MARGIN=newMargin, $
    RESET_SCREEN_SIZES=resetScreenSizes

    compile_opt idl2, hidden

    nDS = 0
    margins = [self.margin2DX, self.margin2DY]
    oWorld = self->GetWorld()
    oDS = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces(COUNT=nDS) : $
        OBJ_NEW()
        
    for i=0,nDS-1 do begin
        if (~OBJ_ISA(oDS[i], 'IDLitVisNormalizer')) then continue
        isValid = oDS[i]->IDLitVisNormalizer::Compute2DPadding( $
            virtualViewDims, margins, (1-self.bAspect), $
            zoomOnResize, $
            NEW_MARGIN=newMargin, $
            RESET_SCREEN_SIZES=resetScreenSizes)
    endfor

    self->_UpdateMargins

end


;----------------------------------------------------------------------------
; IDLitgrLayer::_UpdateMargins
;
; Purpose:
;   This procedure method updates the margins for the layer.
;
; Arguments:
;   None
;
pro IDLitgrLayer::_UpdateMargins, oNotifier

    compile_opt idl2, hidden

    ; Update margins.
    nDS = 0
    nValid = 0
    minXPad = 0.0d
    minYPad = 0.0d
    oWorld = self->GetWorld()
    oDS = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces(COUNT=nDS) : $
        OBJ_NEW()
    if (OBJ_VALID(oNotifier)) then begin
      oDS = oNotifier
      nDS = N_ELEMENTS(oDS)
    endif
    for i=0,nDS-1 do begin
        if (OBJ_ISA(oDS[i], 'IDLitVisNormalizer')) then begin
            oDS[i]->IDLitVisNormalizer::GetProperty, $
                PAD_2D_X=xpad, PAD_2D_Y=ypad, $
                PAD_2D_VALID=paddingValid
            if (paddingValid) then begin
                if (nValid eq 0) then begin
                    minXPad = xpad
                    minYPad = ypad
                endif else begin
                    minXPad = xpad < minXPad
                    minYPad = ypad < minYPad
                endelse
                nValid++
            endif
        endif
    endfor

    bMarginChange = 0b
    if (nValid gt 0) then begin
        minXPad = self->_RoundMargin(minXPad)
        minYPad = self->_RoundMargin(minYPad)

        ; Store minimum padding.
        if (minXPad ne self.margin2DX) then begin
            self.margin2DX = minXPad
            bMarginChange = 1b
        endif
        if (minYPad ne self.margin2DY) then begin
            self.margin2DY = minYPad
            bMarginChange = 1b
        endif

        ; Allow UI to update to reflect new margins.
        if (bMarginChange) then begin
            self->GetProperty, PARENT=oView
            self->DoOnNotify, oView->GetFullIdentifier(), 'SETPROPERTY', ''
        endif

        ; Renormalize dataspaces.
        for i=0,nDS-1 do begin
            if (OBJ_ISA(oDS[i], 'IDLitVisNormalizer')) then $
                oDS[i]->Normalize
        endfor

    endif

end

;----------------------------------------------------------------------------
; IDLitgrLayer::OnViewportChange
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
;   zoomOnResize: A boolean flag indicating whether visualization content 
;     should zoom when the viewport resizes.
;
; Keywords:
;    RESET_SCREEN_SIZES: Set this keyword to a non-zero value to indicate
;        that the screen sizes associated with visualizations (used to
;        honor zoomOnResize=0) should be reset.  By default, the screen
;        sizes remain untouched.
;
pro IDLitgrLayer::OnViewportChange, oView, oDestination, $
    virtualViewDims, normClipRect, normViewDims, $
    bVirtualChange, zoomOnResize, $
    RESET_SCREEN_SIZES=resetScreenSizes

    compile_opt idl2, hidden

    if (bVirtualChange ne 0) then begin
        ; Recompute margins.
        origVirtualViewDims = oView->GetVirtualViewport(oDestination, $
            /UNZOOMED)
        self->_RecomputeMargins, origVirtualViewDims, zoomOnResize, $
            RESET_SCREEN_SIZES=resetScreenSizes
    endif

    ; Update the virtual frustum rectangle (aspect ratio changes, and
    ; visible to virtual cropping).
    self.bFrustumDirty = 1b
    bChange = self->ComputeVirtualFrustumRect(virtualViewDims, normClipRect)

    ; Crop the frustum to the visible portion of the scrolling window.
    self->CropFrustum, oDestination

    ; Notify contained visualizations (so they can update text sizing,
    ; selection visuals, etc.)
    oWorld = self->GetWorld()
    nDS = 0
    oDS = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces(COUNT=nDS) : $
        OBJ_NEW()
    for i=0,nDS-1 do $
        oDS[i]->OnViewportChange, oView, oDestination, virtualViewDims, $
            normViewDims
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::GetWorld
;
; PURPOSE:
;    Retrieves the World associated with this Layer.
;
; CALLING SEQUENCE:
;    oWorld = oLayer->[IDLitgrLayer::]GetWorld()
;
; OUTPUTS:
;    This function method returns a reference to an IDLitgrWorld.
;
;-
function IDLitgrLayer::GetWorld

    compile_opt idl2, hidden

    return, self->IDLgrView::Get()

end


;---------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::GetCurrentDataSpace
;
; PURPOSE:
;    Retrieves the Dataspace associated with this Layer.
;
; CALLING SEQUENCE:
;    oDS = oLayer->[IDLitgrLayer::]GetCurrentDataspace()
;
; OUTPUTS:
;    This function method returns a reference to an Data Space or
;    a null object if one doesn't exist.
;
;-
;
function IDLitGrLayer::GetCurrentDataSpace

    compile_opt idl2, hidden

    ;; Pretty simple
    oWorld = self->GetWorld()
    return, (obj_valid(oWorld) ? oWorld->GetCurrentDataSpace() : obj_new())
end

;---------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::SetCurrentDataSpace
;
; PURPOSE:
;    Sets the given dataspace as the currently active dataspace associated
;    with this Layer.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]SetCurrentDataspace, DataSpace
;
; INPUTS:
;    DataSpace: A reference to an IDLitVisIDataSpace that is to become
;      the current dataspace within this layer.
;-
pro IDLitGrLayer::SetCurrentDataSpace, oDataSpace

    compile_opt idl2, hidden

    oWorld = self->GetWorld()
    if (OBJ_VALId(oWorld)) then $
        oWorld->SetCurrentDataSpace, oDataSpace
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::OnViewZoom
;
; PURPOSE:
;    The IDLitgrLayer::OnViewZoom procedure handles notification of a change
;    in the view zoom factor.  The view frustum is updated accordingly.
;
; CALLING SEQUENCE:
;    oObj->[IDLitgrLayer::]OnViewZoom, oView, oDestination
;
; INPUTS:
;    oView: A reference to this layer's parent view.
;
;    oDestination: A reference to the destination within which the view
;      appears.
;
;    zoomFactor: The new zoom factor for the view.
;
;    normClipRect: A 4-element vector, [x,y,w,h], representing
;      the (un-canvas-zoomed) visible viewport rectangle (in
;      normalized coordinates relative to the virtual viewport)
;
; KEYWORD PARAMETERS:
;    NO_NOTIFY: Set this keyword to a non-zero value to indicate that
;      contained visualizations should not be notified of the zoom factor
;      change.  By default, contained visualizations are notfied.
;
;-
pro IDLitgrLayer::OnViewZoom, oView, oDestination, zoomFactor, normClipRect, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    ; Update virtual frustum rectangle.
    self->_CorrectForZoom, normClipRect

    ; Crop to visible portion of scrolling destination.
    self->CropFrustum, oDestination

    ; Unless otherwise specified, notify children of the zoom.
    if (~KEYWORD_SET(noNotify)) then begin
        oView->GetProperty, CURRENT_ZOOM=zoomFactor
        oWorld = self->IDLgrView::Get()
        oDS = oWorld->GetDataSpaces(COUNT=nDS)
        for i=0,nDS-1 do $
            oDS[i]->OnViewZoom, oView, oDestination, zoomFactor
    endif

    ; Allow parent IDLitgrView::SetCurrentZoom to do the redraw.
end

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::OnDataChange
;
; PURPOSE:
;    The IDLitgrLayer::OnDataChange procedure method handles
;    notification of pending data changes within the contained
;    visualization hierarchy.
;
; CALLING SEQUENCE:
;    oLayer->[IDLitgrLayer::]OnDataChange, oNotifier
;
; INPUTS:
;    oNotifier:    A reference to the object sending notification
;        of the data change.
;
;-
pro IDLitgrLayer::OnDataChange, oNotifier

    compile_opt idl2, hidden

    ; Notify the parent View.
    self->GetProperty, PARENT=oView
    if (OBJ_VALID(oView) eq 0) then $
        RETURN

    oView->OnDataChange, oNotifier
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitgrLayer::OnDataComplete
;
; PURPOSE:
;    The IDLitgrLayer::OnDataComplete procedure method handles
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
pro IDLitgrLayer::OnDataComplete, oNotifier

    compile_opt idl2, hidden

    self->_UpdateMargins, oNotifier

    ; Notify my parent view.
    self->GetProperty, PARENT=oView
    if (OBJ_VALID(oView)) then begin
        ; Notify the parent View.
        oView->OnDataComplete, oNotifier
    endif

end
;---------------------------------------------------------------------------
; Selection management.
; Override to manage current data space
;---------------------------------------------------------------------------
; +
; IDLitGrLayer::AddSelectedItem
;
; PURPOSE:
;   Override the SelectParent method so the current data space can be
;   kept up to date
;
; INPUTS:
;   oItem   - The item to select
;-
pro IDLitGrLayer::AddSelectedItem, oItem

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitSelectParent::AddSelectedItem, oItem

    self->SetCurrentDataSpace, oItem->GetDataSpace()
end

;---------------------------------------------------------------------------
; +
; IDLitGrLayer::SetSelectedItem
;
; PURPOSE:
;   Override the SelectParent method so the current data space can be
;   kept up to date
;
; INPUTS:
;   oItem   - The item to select.
;-
pro IDLitGrLayer::SetSelectedItem, oItem

    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitSelectParent::SetSelectedItem, oItem

    self->SetCurrentDataSpace, oItem->GetDataSpace()

end

;---------------------------------------------------------------------------
; +
; IDLitgrLayer::SetPrimarySelectedItem
;
; PURPOSE:
;   Override the select parent method so that the current data space
;   can be kept up to date.
;
; INPUTS:
;    oItem    - The item to set as primary
;-
PRO IDLitLayer::SetPrimarySelectedItem, oItem
    compile_opt idl2, hidden

    ; Call our superclass.
    self->IDLitSelectParent::SetPrimarySelectedItem, oItem

    self->SetCurrentDataSpace, oItem->GetDataSpace()
END

;;---------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrLayer::Select
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
;   Obj->[IDLitGrLayer::]Select, Mode
;
; INPUTS:
;    Mode     - An integer representing the type of selection to perform.
;      Valid values include:
;                    0 - Unselect
;                    1 - Select
;                    2 - Toggle    (control key)
;                    3 - Additive  (shift key)
;
; KEYWORD PARAMETERS:
;   ADDITIVE:   Set this keyword to a nonzero value to indicate that
;     this layer should be selected as an addition to the
;     current selection list.  Setting this keyword is equivalent to
;     setting the mode argument to 3.
;
;   NO_NOTIFY:  Set this keyword to a nonzero value to indicate that
;     this layer's parent should not be notified of the selection.
;     By default, the parent is notified.
;
;   SELECT: Set this keyword to a nonzero value to indicate that
;     this layer should be selected (in isolation).  Setting this
;     keyword is equivalent to setting the mode argument to 1.
;
;   TOGGLE: Set this keyword to a nonzero value to indicate that
;     the selection status of this layer should be toggled.
;     Setting this keyword is equivalent to setting the mode argument to 2.
;
;   UNSELECT:   Set this keyword to a nonzero value to indicate that
;     this layer should be unselected. Setting this keyword is
;     equivalent to setting the mode argument to 0.
;

pro IDLitgrLayer::Select, iMode, $
    ADDITIVE=ADDITIVE, $
    NO_NOTIFY=NO_NOTIFY, $
    SELECT=SELECT, $
    TOGGLE=TOGGLE, $
    UNSELECT=UNSELECT

    ; pragmas
    compile_opt idl2, hidden

    ; Convert keywords to a mode parameter.
    if (N_PARAMS() ne 1) then begin
        case 1 of
            KEYWORD_SET(UNSELECT) : iMode = 0
            KEYWORD_SET(SELECT)   : iMode = 1
            KEYWORD_SET(ADDITIVE) : iMode = 3
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
    self->IDLgrView::GetProperty, _PARENT=oparent
    ; If notification is enabled, notify the parent.
    if (not KEYWORD_SET(NO_NOTIFY))then begin
        case iMode of
            0: oParent->RemoveSelectedItem, self
            1: oParent->SetSelectedItem, self
            3: oParent->AddSelectedItem, self
        endcase
    endif
end
;;---------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitGrLayer::IsSelected
;
; PURPOSE:
;   This function method reports whether this layer is currently
;   selected.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitGrLayer::]IsSelected()
;
; OUTPUTS:
;   This function returns a 1 if this layer is currently
;   selected, or 0 otherwise.

function IDLitGrLayer::IsSelected

    compile_opt idl2, hidden

    return, self.isSelected
end


;---------------------------------------------------------------------------
; Need to override our _IDLitContainer::Add method so we can send things
; directly to our world. Otherwise, if a Light is added, it will end up
; in our _IDLitContainer's container, which is the DataspaceRoot.
;
pro IDLitgrLayer::Add, oObjects, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oWorld = self->GetWorld()
    oWorld->Add, oObjects, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; Need to override our _IDLitContainer::Get method so we can retrieve
; the Light container from the World. Otherwise, we won't be able to
; find it, since we'll be looking in the DataspaceRoot.
;
function IDLitgrLayer::Get, ALL=all, $
    COUNT=count, $
    _REF_EXTRA=_EXTRA

   compile_opt idl2, hidden

    oObjs = self->_IDLitContainer::Get(ALL=all, $
        COUNT=count, _EXTRA=_EXTRA)
    if (~KEYWORD_SET(all)) then $
        return, oObjs

    oWorld = self->GetWorld()
    oLights = oWorld->GetByIdentifier('LIGHTS')

    if (OBJ_VALID(oLights)) then begin
        oObjs = (count gt 0) ? [oObjs, oLights] : oLights
        count++
    endif

    return, (count gt 0 ? oObjs : -1)
end


;----------------------------------------------------------------------------
; IDLitgrLayer::OnDimensionChange
;
; Purpose:
;   This procedure method handles notification from the contained world
;   that the dimensionality has changed.
;
pro IDLitgrLayer::OnDimensionChange, oSubject, is3D
    compile_opt idl2, hidden

    if (is3D) then begin
        self.margin2DX = 0.2
        self.margin2DY = 0.2
    endif else begin
        self.margin2DX = 0.05d
        self.margin2DY = 0.05d
    endelse
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitgrLayer__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitgrLayer object.
;
;-
pro IDLitgrLayer__define

    compile_opt idl2, hidden

    struct = {IDLitgrLayer,           $
        inherits _IDLitContainer,       $ ; Superclass: _IDLitContainer
        inherits IDLgrView,             $ ; Superclass: IDLgrView
        INHERITS IDLitSelectParent,     $ ; Superclass
        inherits IDLitIMessaging,       $
        isSelected : 0b,                $
        bAspect: 0b,                    $ ; Maintain aspect ratio?
        bFrustumDirty: 0b,              $ ; 1= aspect or zoom dirty
        origFrustumRect: DBLARR(4),     $ ; Original Frustum
        aspectFrustumRect: DBLARR(4),   $ ; Virtual viewplane rect
                                        $ ;   corrected for aspect ratio
        virtualFrustumRect: DBLARR(4),  $ ; Virtual viewplane rect (scrolling)
                                        $ ;   corrected for aspect & zoom
        margin2DX: 0.0d,                $ ; Reported 2D margin (normalized
        margin2DY: 0.0d                 $ ;   relative to view layer)
    }
end
