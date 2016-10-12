; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisnormalizer__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisNormalizer
;
; PURPOSE:
;   The IDLitVisNormalizer class is a visualization that applies (via
;   a transformation matrix) a normalization scale and translation.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormalizer::Init
;
; PURPOSE:
;   The IDLitVisNormalizer::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   oNormalizer = OBJ_NEW('IDLitVisNormalizer')
;
;   or
;
;   Obj->[IDLitVisNormalizer::]Init
;
;-
function IDLitVisNormalizer::Init, $
    DESCRIPTION=inDescription, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name and description.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "IDLitVisNormalizer"
    description = (N_ELEMENTS(inDescription) ne 0) ? $
        inDescription : "Visualization Normalizer"

    ; Initialize superclasses.
    if (self->_IDLitVisualization::Init($
        DESCRIPTION=description, $
        /MANIPULATOR_TARGET, $
        NAME=name, $
        /REGISTER_PROPERTIES, $
        _EXTRA=_extra) NE 1) then $
        return, 0

    ; Initialize properties.
    self._pad3D = 0.025d
    self._aspectRatio = 0d
    self._aspectZ = 0d
    self._anisotropicScale2D = 0.7d
    self._anisotropicScale3D = 0.7d
    self.xPos = !VALUES.D_INFINITY
    self.yPos = !VALUES.D_INFINITY
    self.xSize = !VALUES.D_INFINITY
    self.ySize = !VALUES.D_INFINITY

    ; Register all properties.
    self->IDLitVisNormalizer::_RegisterProperties

    ; Generate the normalization model.
    self._normalizeModel = OBJ_NEW('_IDLitVisualization', $
        NAME='Normalize Model')
    if (OBJ_VALID(self._normalizeModel) eq 0) then begin
        self->Cleanup
        return, 0
    endif
    self->IDLgrModel::Add, self._normalizeModel

    ; Change the target container for self so that added
    ; items are added to the contained normalization model.
    self->_IDLitContainer::SetProperty, $
        CLASSNAME='IDLgrModel', $
        CONTAINER=self._normalizeModel

    ; Set properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisNormalizer::SetProperty, _EXTRA=_extra

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormalizer::Cleanup
;
; PURPOSE:
;      The IDLitVisNormalizer::Cleanup procedure method preforms all cleanup
;      on the object.
;
;      NOTE: Cleanup methods are special lifecycle methods, and as such
;      cannot be called outside the context of object destruction.  This
;      means that in most cases, you cannot call the Cleanup method
;      directly.  There is one exception to this rule: If you write
;      your own subclass of this class, you can call the Cleanup method
;      from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;   OBJ_DESTROY, oNormalizer
;
;   or
;
;   Obj->[IDLitVisNormalizer::]Cleanup
;
;-
pro IDLitVisNormalizer::Cleanup

    compile_opt idl2, hidden

    ; Cleanup superclass.
    self->_IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisNormalizer::_RegisterProperties
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisNormalizer::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisNormalizer::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'POSITION', /USERDEF, $
            DESCRIPTION='Position of the plot', $
            NAME='Position', /HIDE, /ADVANCED_ONLY
    endif

    if (registerAll || (updateFromVersion lt 800)) then begin
      self->RegisterProperty, 'ANISOTROPIC_SCALE_2D', /FLOAT, $
            NAME='Anisotropic 2D scale', $
            DESCRIPTION='Presentation scale factor applied along Y axis'

      self->RegisterProperty, 'ANISOTROPIC_SCALE_3D', /FLOAT, $
            NAME='Anisotropic 3D scale', $
            DESCRIPTION='Presentation scale factor applied along Z axis'
            
      ; New properties for IDL80
      self->RegisterProperty, 'ASPECT_RATIO', /FLOAT, /ADVANCED_ONLY, $
          NAME='Aspect Ratio', $
          DESCRIPTION='Ratio of the Y dimension to the X dimension'
      self->RegisterProperty, 'ASPECT_Z', /FLOAT, /HIDE, /ADVANCED_ONLY, $
          NAME='Z Aspect Ratio', $
          DESCRIPTION='Ratio of the Z dimension to the X and Y dimensions'
    endif

    if (~registerAll && updateFromVersion lt 800) then begin
        ; Obsolete
        self->SetPropertyAttribute, 'ANISOTROPIC_SCALE_2D', VALID_RANGE=0, /HIDE
        self->SetPropertyAttribute, 'ANISOTROPIC_SCALE_3D', VALID_RANGE=0, /HIDE
        self->SetPropertyAttribute, 'SCALE_ISOTROPIC', /HIDE

    endif
end

;----------------------------------------------------------------------------
; IDLitVisNormalizer::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisNormalizer::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisNormalizer::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
;2D padding should be computed as a result of the parent view restore.
;Restore will init these to zero anyway:
;        self._pad2DValid = 0
;        self._screenXSize = 0
;        self._screenYSize = 0
        self._pad3D = 0.025
        self._anisotropicScale2D = 0.7d
        self._anisotropicScale3D = 0.7d

        ; Note: while it is tempting to re-normalize here, this is
        ; not a good place to do so since the restore can occur before
        ; the visualization hierarchy has been added to the window
        ; (and normalization depends upon viewport dimensions and
        ; zoomOnResize settings).  Therefore, the normalization will
        ; have to wait until a simulated viewport update occurs
        ; (after the visualization hierarchy is added to the window).
    endif

end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;---------------------------------------------------------------------------
; IDLitVisNormalizer::GetProperty
;
; Purpose:
;  Retrieves the value of a property or group of properties for this object.
;
; TODO:
;   Verify which properties should be retrieved from where.
;
pro IDLitVisNormalizer::GetProperty, $
    ASPECT_RATIO=aspectRatio, $
    ASPECT_Z=aspectZ, $
    ANISOTROPIC_SCALE_2D=anisotropicScale2D, $
    ANISOTROPIC_SCALE_3D=anisotropicScale3D, $
    PAD_2D_VALID=pad2DValid, $
    PAD_2D_X=pad2DX, $
    PAD_2D_Y=pad2DY, $
    PAD_3D=pad3D, $
    SCREEN_XSIZE=screenXSize, $
    SCREEN_YSIZE=screenYSize, $
    SCALE_ISOTROPIC=scaleIsotropic, $
    POSITION=posIn, $
    DEVICE=deviceIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(aspectRatio)) then $
        aspectRatio = self._aspectRatio
    if (ARG_PRESENT(aspectZ)) then $
        aspectZ = self._aspectZ

    if (ARG_PRESENT(anisotropicScale2D)) then $
        anisotropicScale2D = self._anisotropicScale2D
    if (ARG_PRESENT(anisotropicScale3D)) then $
        anisotropicScale3D = self._anisotropicScale3D

    ; PAD_3D
    if (ARG_PRESENT(pad3D)) then $
        pad3D = self._pad3D

    ; PAD_2D_VALID
    if (ARG_PRESENT(pad2DValid)) then $
        pad2DValid = self._pad2DValid

    ; SCALE_ISOTROPIC should return:
    ;    0: Automatic
    ;    1: Isotropic
    ;    2: Anisotropic
    if (ARG_PRESENT(scaleIsotropic)) then $
        scaleIsotropic = self._hasIsotropic ? (self.isotropic ? 1 : 2) : 0

    ; SCREEN_XSIZE
    if (ARG_PRESENT(screenXSize)) then $
        screenXSize = self._screenXSize

    ; SCREEN_YSIZE
    if (ARG_PRESENT(screenYSize)) then $
        screenYSize = self._screenYSize

    ; PAD_2D_X
    if (ARG_PRESENT(pad2DX)) then $
        pad2DX = self._pad2DX

    ; PAD_2D_Y
    if (ARG_PRESENT(pad2DY)) then $
        pad2DY = self._pad2DY

    ; POSITION
    if (ARG_PRESENT(posIn)) then $
        posIn = [self.xPos, self.yPos, $
                 self.xSize+self.xPos, self.ySize+self.yPos]

    ; Device
    if (ARG_PRESENT(deviceIn)) then $
      deviceIn = self._deviceFlag
    
    ; Retrieve properties from superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=_extra

end

;---------------------------------------------------------------------------
; IDLitVisNormalizer::SetProperty
;
; Purpose:
;  Sets the value of a property or group of properties for this object.
;
; TODO:
;   Verify which properties should be passed where.
;
pro IDLitVisNormalizer::SetProperty, $
    ASPECT_RATIO=aspectRatio, $
    ASPECT_Z=aspectZ, $
    ANISOTROPIC_SCALE_2D=anisotropicScale2D, $
    ANISOTROPIC_SCALE_3D=anisotropicScale3D, $
    PAD_3D=pad3D, $
    SCALE_ISOTROPIC=scaleIsotropic, $
    POSITION=posIn, $
    DEVICE=devIn, $
    NO_UPDATE=noUpdate, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    bUpdate = 0b

    ; ASPECT_RATIO
    if ((N_ELEMENTS(aspectRatio) eq 1) && $
        (aspectRatio ne self._aspectRatio)) then begin
      self._aspectRatio = aspectRatio
      bUpdate = 1b
    endif
    
    ; ANISOTROPIC_SCALE_2D
    if (N_ELEMENTS(anisotropicScale2D) gt 0) then begin
        newScale = anisotropicScale2D[0]
        if (newScale ge 0 && self._anisotropicScale2D ne newScale) then begin
            self._anisotropicScale2D = newScale
            bUpdate = 1b
        endif
    endif

    ; ASPECT_Z
    if (N_ELEMENTS(aspectZ)) then begin
      ; Did we switch aspect ratio from 0 to nonzero, or vice versa?
      if ((aspectZ eq 0) ne (self._aspectZ eq 0)) then begin
        scaleIsotropic = (aspectZ ne 0) ? 1 : 0
      endif
      self._aspectZ = aspectZ
      bUpdate = 1b
    endif

    if (N_ELEMENTS(anisotropicScale3D) gt 0) then begin
        newScale = anisotropicScale3D[0]
        if (newScale ge 0 && self._anisotropicScale3D ne newScale) then begin
            self._anisotropicScale3D = newScale
            bUpdate = 1b
        endif
    endif

    ; PAD_3D
    if (N_ELEMENTS(pad3D) gt 0) then begin
        newPad = pad3D[0] > 0.0
        if (self._pad3D ne newPad) then begin
            self._pad3D = newPad
            bUpdate = 1b
        endif
    endif

    ; SCALE_ISOTROPIC should be set to:
    ;    0: Automatic
    ;    1: Isotropic
    ;    2: Anisotropic
    if (N_ELEMENTS(scaleIsotropic)) then begin
        ; Retrieve our old isotropic state.
        oldIsotropic = self->IsIsotropic()
        self._hasIsotropic = (scaleIsotropic gt 0)
        if (self._hasIsotropic) then begin
            ; Set our new flag value.
            self.isotropic = (scaleIsotropic eq 1)
        endif else begin
            ; Retrieve our current isotropic state.
            self.isotropic = self->IsIsotropic()
        endelse

        if (oldIsotropic ne self.isotropic) then begin
            ; Reset screen sizes.
            self._screenXSize = 0
            self._screenYSize = 0

            ; Notify.  Note: this will force a recompute of padding.
            self->OnDataChange, self
            self->OnDataComplete, self
        endif

    endif

    if (N_ELEMENTS(devIn)) then begin
      self._deviceFlag = KEYWORD_SET(devIn)
    endif
    
    if (N_ELEMENTS(posIn) eq 4) then begin
      if (self._deviceFlag) then begin
        pos = iConvertCoord([posIn[0],posIn[2]], [posIn[1], posIn[3]], $
                            /DEVICE, /TO_NORMAL)
        pos = [pos[0,0],pos[1,0],pos[0,1],pos[1,1]]
        self._deviceFlag = 0b
      endif else begin
        pos = posIn
      endelse
      if (FINITE(pos[0])) then begin
        self.xPos = pos[0]
        if (FINITE(pos[2])) then begin
          self.xSize = pos[2]-pos[0]
        endif
        bUpdate = 1b
        self._hasPosSize = 1b
      endif
      if (FINITE(pos[1])) then begin
        self.yPos = pos[1]
        if (FINITE(pos[3])) then begin
          self.ySize = pos[3]-pos[1]
        endif
        bUpdate = 1b
        self._hasPosSize = 1b
      endif
    endif
    
    if (bUpdate && ~KEYWORD_SET(noUpdate)) then $
        self->Normalize

    ; Pass along properties to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
;+
; METHODNAME:
;   _IDLitVisualization::IsIsotropic
;
; PURPOSE:
;   This function method returns a flag indicating whether this visualization
;   is isotropic.
;
; CALLING SEQUENCE:
;   Result = Obj->[_IDLitVisualization::]IsIsotropic()
;
; OUTPUTS:
;   This function returns a 1 if this visualization is isotropic,
;   or 0 otherwise.
;
;-
function IDLitVisNormalizer::IsIsotropic

    compile_opt idl2, hidden

    ; Shortcut.
    if (self._hasIsotropic) then $
        return, self.isotropic

    ; Get all my viz children.
    oVis = self->Get(/ALL, ISA='IDLitVisualization', COUNT=nChild)

    ; As soon as we find an isotropic viz, we are done.
    for i=0,nChild-1 do begin
        if (oVis[i]->IsIsotropic()) then $
            return, 1   ; We're done
    endfor

    ; If we reach this point, none of my children are isotropic,
    ; and therefore, neither am I.
    return, 0

end


;----------------------------------------------------------------------------
; IIDLVisNormalizer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormalizer::Normalize
;
; PURPOSE:
;      The IDLitVisNormalizer::Normalize procedure method applies the
;      appropriate normalization factors based upon the XYZ range of its
;      contents.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormalizer::]Normalize
;
;-
pro IDLitVisNormalizer::Normalize
    compile_opt idl2, hidden

    bValidRange = self._normalizeModel->GetXYZRange( $
        XRange, YRange, ZRange, /NO_TRANSFORM)

    if (bValidRange ne 0) then $
        self->NormalizeToRange, XRange, YRange, ZRange
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormalizer::NormalizeToRange
;
; PURPOSE:
;      The IDLitVisNormalizer::NormalizeToRange
;      on the object.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisNormalizer::]NormalizeToRange, XRange, YRange, ZRange
;
;-
pro IDLitVisNormalizer::NormalizeToRange, XRange, YRange, ZRange
    compile_opt idl2, hidden

    oLayer = self->_GetLayer()
    if (OBJ_VALID(oLayer)) then $
        oLayer->GetProperty, STRETCH_TO_FIT=stretchToFit $
    else $
        stretchToFit = 0b

    ; Account for margins.
    if (self._normalizeModel->Is3D()) then begin
        xmargin = 2.0d * (self._pad2DX < self._pad2DY)
        ymargin = xmargin
        zmargin = xmargin

        normW = 2.0d
        normH = 2.0d
    endif else begin
        ; For 2D visualizations, take into account the aspect ratio
        ; of the target viewport when computing scale factors.
        haveView = self->_GetWindowandViewG(oWin, oView)
        normW = 2.0d
        normH = 2.0d
        if (haveView) then begin
            ; If the layer is set to stretch to fit, then do not
            ; correct for aspect ratio.  Otherwise, do.
            if (~stretchToFit) then begin
                vwDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
                if (vwDims[0] gt vwDims[1]) then $
                    normW *= (vwDims[0] / vwDims[1]) $
                else if (vwDims[0] lt vwDims[1]) then $
                    normH *= (vwDims[1] / vwDims[0])
            endif
        endif

        xmargin = 2.0*self._pad2DX
        ymargin = 2.0*self._pad2DY
        zmargin = 0.0
    endelse

    if (FINITE(self.xSize) && ~FINITE(self.xPos)) then begin
      xmargin = (1.0 - self.xSize)/2.0
      self.xPos = xmargin
    endif
    if (FINITE(self.ySize) && ~FINITE(self.xPos)) then begin
      ymargin = (1.0 - self.ySize)/2.0
      self.yPos = ymargin
    endif
    
    ; Compute scale factors to map into range of -1 to +1.
    sx = (XRange[0] ne XRange[1]) ? $
        (normW*(1.0 - xmargin))/(XRange[1] - XRange[0]) : !VALUES.D_INFINITY
    sy = (YRange[0] ne YRange[1]) ? $
        (normH*(1.0 - ymargin))/(YRange[1] - YRange[0]) : !VALUES.D_INFINITY
    sz = (ZRange[0] ne ZRange[1]) ? $
        (2d    - 2*zmargin)/(ZRange[1] - ZRange[0]) : !VALUES.D_INFINITY

    isIsotropic = self->IsIsotropic()
    if (isIsotropic || self._aspectRatio ne 0) then begin

        if (~stretchToFit) then begin

            ; Choose the smallest scale factor so it is isotropic.
            scale = ABS(sx) < ABS(sy)
            if (self._aspectRatio ne 0) then begin
              ; Decide whether to shrink X or Y
              if (self._aspectRatio gt 1 && ABS(sx) ge ABS(sy)) then begin
                ; Shrink X
                sx = ((sx ge 0) ? scale : -scale)/self._aspectRatio
                sy = (sy ge 0) ? scale : -scale
              endif else begin
                ; Shrink Y
                sx = (sx ge 0) ? scale : -scale
                sy = ((sy ge 0) ? scale : -scale)*self._aspectRatio
              endelse
            endif else begin
              sx = (sx ge 0) ? scale : -scale
              sy = (sy ge 0) ? scale : -scale
            endelse

            ; Now adjust the Z scaling.
            if (self._aspectZ ne 0) then begin
              ; Decide whether to shrink Z or X&Y
              if (scale*self._aspectZ gt sz) then begin
                ; Shrink X & Y
                sx *= sz/(scale*self._aspectZ)
                sy *= sz/(scale*self._aspectZ)
              endif else begin
                ; Shrink Z
                sz = ((sz ge 0) ? scale : -scale)*self._aspectZ
              endelse
            endif

        endif

    endif else begin
        if (Zrange[0] ne Zrange[1]) then begin
            sz = sz*self._anisotropicScale3D
        endif else if (Yrange[0] ne Yrange[1]) then begin
            sy = sy*self._anisotropicScale2D
        endif
    endelse

    if ~FINITE(sx) then sx = 1
    if ~FINITE(sy) then sy = 1
    if ~FINITE(sz) then sz = 1

    ; Translate to center.
    tx = -(XRange[0]+XRange[1])/2
    ty = -(YRange[0]+YRange[1])/2
    tz = -(ZRange[0]+ZRange[1])/2
    if ~FINITE(tx) then tx = 0
    if ~FINITE(ty) then ty = 0
    if ~FINITE(tz) then tz = 0

    ;; Apply position and size properties
    haveView = self->_GetWindowandViewG(oWin, oView)
    if (haveView && self._hasPosSize) then begin
      vwDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
      if (FINITE(self.xSize)) then begin
        sxW = 2*self.xSize
        if (vwDims[0] gt vwDims[1]) then $
          sxW *= (vwDims[0] / vwDims[1])
        sx = (XRange[0] ne XRange[1]) ? $
          sxW/(XRange[1] - XRange[0]) : !VALUES.D_INFINITY
        if (~FINITE(sx)) then sx = 1
      endif
      if (FINITE(self.ySize)) then begin
        syW = 2*self.ySize
        if (vwDims[1] gt vwDims[0]) then $
          syW *= (vwDims[1] / vwDims[0])
        sy = (YRange[1] ne YRange[0]) ? $
          syW/(YRange[1]-YRange[0]) : !VALUES.D_INFINITY
        if (~FINITE(sy)) then sy = 1
      endif
      ; Update scale if needed to account for aspect ratio
      scaleRatio = sy/sx

      ; Be sure to re-apply the ASPECT_RATIO if necessary.
      if (self._aspectRatio ne 0) then begin
        oldSx = sx
        oldSy = sy
        if (self._aspectRatio gt scaleRatio) then begin
          sx = sy / self._aspectRatio
        endif else begin
          sy = sx * self._aspectRatio
        endelse
      endif
      
      ; Be sure to re-apply the ASPECT_Z if necessary.
      if (self._aspectZ gt 1) then begin
        sx /= self._aspectZ
        sy /= self._aspectZ
      endif
      
      if (FINITE(self.xPos)) then begin
        txW = self.xPos * 2 - 1
        if (vwDims[0] gt vwDims[1]) then $
          txW *= (vwDims[0] / vwDims[1])
        tx = txW/sx
        tx += (-XRange[0])
      endif 
      if (FINITE(self.yPos)) then begin
        tyW = self.yPos * 2 - 1
        if (vwDims[1] gt vwDims[0]) then $
          tyW *= (vwDims[1] / vwDims[0])
        ty = tyW/sy
        ty += (-YRange[0])
      endif
      ; Update translation if needed to account for aspect ratio
      if (self._aspectRatio ne 0) then begin
        if (self._aspectRatio gt scaleRatio) then begin
          tx += (1-sx/oldSx)*(XRange[1]-XRange[0])/2*(oldSx/sx)
        endif else begin
          ty += (1-sy/oldSy)*(YRange[1]-YRange[0])/2*(oldSy/sy)
        endelse
      endif
    endif

    ; Reset normalization transform.
    self._normalizeModel->Reset

    ; Apply normalization translation
    self._normalizeModel->IDLgrModel::Translate, tx, ty, tz

    ; Apply normalization scale.
    self._normalizeModel->IDLgrModel::Scale, sx, sy, sz

    ; Sensitize appropriate anisotropic scaling properties.
    if (self->Is3D()) then $
      self->SetPropertyAttribute, 'ASPECT_Z', HIDE=0

    ; Update selection visuals.
    self->UpdateSelectionVisual
    oTarget = self->GetManipulatorTarget()
    if (oTarget ne self) then $
        oTarget->UpdateSelectionVisual

    ; Broadcast notification to any interested parties.
    self->DoOnNotify, self->GetFullIdentifier(), $
        'NORMALIZATION_CHANGE', 1

end


;----------------------------------------------------------------------------
; View Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; IDLitVisNormalizer::Compute2DPadding
;
; Purpose:
;   This function method computes padding required to map current
;   data range into the given viewport dimensions.
;
; Arguments:
;   viewportDims: A 2-element vector, [w,h], representing the new
;     dimensions (in pixels) of the viewport.
;
;   margins: A 2-element vector, [xmargin, ymargin], representing the
;     most recent margin settings for the view.
;
;   stretchToFit: A scalar that is non-zero if the visualizations are
;     to be stretched to fit within the view.
;
;   zoomOnResize: A boolean flag indicating whether data content should
;     zoom when the viewport resizes.
;
; Return value:
;   This function returns a 1 if the padding could be successfully
;   computed, or 0 otherwise.
;
function IDLitVisNormalizer::Compute2DPadding, $
    viewportDims, margins, stretchToFit, zoomOnResize, $
    COMPUTED_PAD_X=pad2DX, $
    COMPUTED_PAD_Y=pad2DY, $
    NEW_MARGIN=newMargin, $
    RESET_SCREEN_SIZES=resetScreenSizes

    compile_opt idl2, hidden

    if (KEYWORD_SET(resetScreenSizes)) then begin
        self._screenXSize = 0
        self._screenYSize = 0
    endif

    ; Determine which of the margins should be honored:
    ;   - the x margin (NEW_MARGIN=[1,0], and isotropic scaling applies)
    ;   - the y margin (NEW_MARGIN=[0,1], and isotropic scaling applies)
    ;   - both margins (NEW_MARGIN set, and anisotropic scaling applies)
    ;   - the minimum margin (the default)
    bNewMargin = (N_ELEMENTS(newMargin) eq 2) ? (TOTAL(newMargin) eq 1) : 0

    minMargin = MIN(margins)

    ; Compute dimensions of 2D screen rectangle (in pixels) covered
    ; by the content of this dataspace.
    bValidRange = self._normalizeModel->GetXYZRange( $
        XRange, YRange, ZRange, /NO_TRANSFORM)

    oPixelatedObj = self->Is3D() ? $
        OBJ_NEW() : self._normalizeModel->SeekPixelatedVisualization()

    if (~bValidRange) then begin
        self._screenXSize = 0.0
        self._screenYSize = 0.0
        self._pad2DX = 0.0
        self._pad2DY = 0.0
        self._pad2DValid = 0b
        ; We are done.
        goto, skipToEnd
    endif
    
    dataXLen = XRange[1] - XRange[0]
    dataYLen = YRange[1] - YRange[0]

    if (self->Is3D()) then begin
        dataZLen = ZRange[1] - ZRange[0]
        ; Choose a square that can contain longest diagonal of
        ; 3D dataset.
        dataXLen = SQRT(dataXLen*dataXLen + dataYLen*dataYLen + $
            dataZLen*dataZLen)
        dataYLen = dataXLen
    endif

    viewXLen = viewportDims[0]
    viewYLen = viewportDims[1]

    if (OBJ_VALID(oPixelatedObj)) then begin
        ; Assume all children of this dataspace share the same
        ; data-to-pixel ratio as the first pixelated object.
        ; Divide the data dimensions by the pixelated object's
        ; horizontal pixel size.
        pixelXLen = dataXLen
        pixelYLen = dataYLen
        if (OBJ_ISA(oPixelatedObj, 'IDLitVisImage')) then begin
            oPixelatedObj->GetProperty, $
                PIXEL_XSIZE=pixelXSize, PIXEL_YSIZE=pixelYSize
        endif else begin
            pixelXSize = 1.0
            pixelYSize = 1.0
        endelse
        if (pixelXSize ne 1.0) then $
            pixelXLen /= pixelXSize
        if (pixelYSize ne 1.0) then $
            pixelYLen /= pixelYSize

        bDoCompute = zoomOnResize
        if (~bDoCompute) then begin
            self._screenXSize = ULONG(pixelXLen+0.5)
            self._screenYSize = ULONG(pixelYLen+0.5)
        endif
    endif else begin
        ; The dataspace is 3D or does not contain any pixelated
        ; visualizations.  Pixel dimensions have to be computed as a
        ; particular portion of the viewport.
        pixelXLen = dataXLen
        pixelYLen = dataYLen
        if ((self._screenXSize eq 0) || (self._screenYSize eq 0)) then $
            bDoCompute = 1b $
        else $
            bDoCompute = zoomOnResize
    endelse


    if (~bDoCompute) then begin

        ; Default to use stored data length.
        pixelXLen = self._screenXSize
        pixelYLen = self._screenYSize

    endif else begin

        if (stretchToFit) then begin

            if (self->IsIsotropic()) then begin
                ; Maintain data aspect ratio, then stretch within view margins.
                s = 1.0d / (pixelXLen > pixelYLen)
                vx = viewXLen * (1.0 - (2.0*margins[0]))
                vy = viewYLen * (1.0 - (2.0*margins[1]))
                vv = vx > vy
                pixelXLen = pixelXLen * s * vv
                pixelYLen = pixelYLen * s * vv
            endif else begin
                ; Fill within margins.
                pixelXLen = viewXLen * (1.0 - (2.0*margins[0]))
                pixelYLen = viewYLen * (1.0 - (2.0*margins[1]))
            endelse
            
        endif else begin   ; not stretchToFit
        
            if (self->IsIsotropic()) then begin
              if (~OBJ_VALID(oPixelatedObj)) then begin
                ; Maintain data aspect ratio without stretching within view margins.
                if (bNewMargin) then begin
                    if (newMargin[0]) then begin
                        ; Honor x margin.
                        sx = (viewXLen * (1.0 - (2.0*margins[0]))) / pixelXLen
                        pixelXLen *= sx
                        pixelYLen *= sx
                        ; Clamp y margin to zero.
                        if (pixelYLen gt viewYLen) then begin
                            s = viewYLen / pixelYLen
                            pixelXLen *= s
                            pixelYLen *= s
                        endif
                    endif else begin
                        ; Honor y margin.
                        sy = (viewYLen * (1.0 - (2.0*margins[1]))) / pixelYLen
                        pixelXLen *= sy
                        pixelYLen *= sy
                        ; Clamp x margin to zero.
                        if (pixelXLen gt viewXLen) then begin
                            s = viewXLen / pixelXLen
                            pixelXLen *= s
                            pixelYLen *= s
                        endif
                    endelse
                endif else begin
                    ; Honor minimum margin.
                    sx = (viewXLen * (1.0 - (2.0*minMargin))) / pixelXLen
                    sy = (viewYLen * (1.0 - (2.0*minMargin))) / pixelYLen
                    s = sx < sy
                    pixelXLen *= s
                    pixelYLen *= s
                endelse
              endif
            endif else begin  ; not isotropic
                ; Largest square within margins.
                if (bNewMargin) then begin
                    if (newMargin[0]) then begin
                        ; Honor x margin.
                        s = viewXLen * (1.0 - (2.0*margins[0]))
                        pixelXLen = s
                        pixelYLen = s
                        ; Clamp y margin to zero.
                        if (pixelYLen gt viewYLen) then begin
                            s = viewYLen / pixelYLen
                            pixelXLen *= s
                            pixelYLen *= s
                        endif
                    endif else begin
                        ; Honor y margin.
                        s = viewYLen * (1.0 - (2.0*margins[1]))
                        pixelXLen = s
                        pixelYLen = s
                        ; Clamp x margin to zero.
                        if (pixelXLen gt viewXLen) then begin
                            s = viewXLen / pixelXLen
                            pixelXLen *= s
                            pixelYLen *= s
                        endif
                    endelse
                endif else begin  ; not newMargin
                    ; Honor minimum margin.
                    sx = viewXLen * (1.0 - (2.0*minMargin))
                    sy = viewYLen * (1.0 - (2.0*minMargin))
                    s = sx < sy
                    pixelXLen = s
                    pixelYLen = s
                endelse  ; not newMargin
            endelse  ; not isotropic
            
        endelse      ; end not stretchToFit
        
        self._screenXSize = ULONG(pixelXLen+0.5)
        self._screenYSize = ULONG(pixelYlen+0.5)
        
    endelse   ; bDoCompute


    self._pad2DX = (viewXLen gt pixelXLen) ? $
        (viewXLen - pixelXLen) / (2.0 * viewXLen) : 0.0
    self._pad2DY = (viewYLen gt pixelYLen) ? $
        (viewYLen - pixelYLen) / (2.0 * viewYLen) : 0.0

    self._pad2DValid = 1b

skipToEnd:

    if (ARG_PRESENT(pad2DX)) then $
        pad2DX = self._pad2DX

    if (ARG_PRESENT(pad2DY)) then $
        pad2DY = self._pad2DY

    ; Note: the caller of this method is responsible for
    ; calling the ::Normalize method on this object to ensure
    ; re-normalization occurs.

    return, self._pad2DValid
end

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisNormalizer::OnDataComplete
;
; PURPOSE:
;   This procedure method handles notification that
;   recently changed data is ready to be flushed.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisNormalizer::]OnDataComplete, oSubject
;
; INPUTS:
;   oSubject:  A reference to the object sending notification
;       of the data flush.
;-
pro IDLitVisNormalizer::OnDataComplete, oSubject

    compile_opt idl2, hidden

    ; Decrement reference count.
    if (self.geomRefCount gt 0) then $
        self.geomRefCount = self.geomRefCount - 1

    ; If all children have reported in that they are ready to flush,
    ; then the reference count should be zero and the parent
    ; can be notified.
    if (self.geomRefCount eq 0) then begin

        ; Get parent layer.
        self->IDLgrComponent::GetProperty, PARENT=oParent
        while (~OBJ_ISA(oParent, "IDLitgrLayer")) do begin
            if (~OBJ_VALID(oParent)) then $
                 break

            ; use [0] to force temp
            oParent[0]->IDLgrComponent::GetProperty, PARENT=oParent
        endwhile
        oLayer = oParent

        ; Get parent view.
        if (OBJ_VALID(oLayer)) then $
            oLayer->GetProperty, PARENT=oView $
        else $
            oView = OBJ_NEW()

        ; Get window.
        if (OBJ_VALID(oView)) then $
            oView->IDLgrViewGroup::GetProperty, _PARENT=oWin $
        else $
            oWin = OBJ_NEW()

        ; Update padding required to map new data ranges to
        ; viewport.
        self._screenXSize = 0.0
        self._screenYSize = 0.0
        if (OBJ_VALID(oWin)) then begin
            virtualViewDims = oView->GetVirtualViewport(oWin, /UNZOOMED)
            ; "Special" code to only get ZOOM_ON_RESIZE if we can.
            if OBJ_ISA(oWin, 'IDLitgrWinScene') then begin
                oWin->GetProperty, ZOOM_ON_RESIZE=zoomOnResize
            endif else zoomOnResize = 1
            oLayer->GetProperty, STRETCH_TO_FIT=stretchToFit, $
                XMARGIN=margin2DX, YMARGIN=margin2DY
            void = self->IDLitVisNormalizer::Compute2DPadding( $
                virtualViewDims, [margin2DX, margin2DY], $
                stretchToFit, zoomOnResize)
        endif else begin
            self._pad2DValid = 0b
            self._pad2DX = 0.0
            self._pad2DY = 0.0
        endelse

        ; Recompute normalization factors.
        self->Normalize

        ; Notify parent.
        self->IDLgrModel::GetProperty, PARENT=oParent
        if OBJ_VALID(oParent) then $
            oParent->OnDataComplete, oSubject
    endif
end

;----------------------------------------------------------------------------
; Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisNormalizer__Define
;
; PURPOSE:
;   Defines the object structure for an IDLitVisNormalizer object.
;-
pro IDLitVisNormalizer__Define
    compile_opt idl2, hidden

    struct = { IDLitVisNormalizer,    $
        inherits _IDLitVisualization, $ ; Superclass: _IDLitVisualization
        _normalizeModel: OBJ_NEW(),   $ ; Normalization model.
        _aspectRatio: 0d, $
        _aspectZ: 0d, $
        _anisotropicScale2D: 0.0d,    $ ; Scale applied to the Y axis when
                                      $ ;   target visualization is 2D and
                                      $ ;   anisotropic scaling is in effect.
        _anisotropicScale3D: 0.0d,    $ ; Scale applied to the Z axis when
                                      $ ;   target visualization is 3D and
                                      $ ;   anisotropic scaling is in effect.
        _hasIsotropic: 0b,            $ ; has the user set ISOTROPIC?
        _pad3D: 0.0d,                 $ ; Additional 3D padding (normalized)
        _pad2DX: 0.0d,                $ ; Padding for 2D (normalized)
        _pad2DY: 0.0d,                $ ;
        _pad2DValid: 0b,              $ ; Flag: is 2D padding currently valid?
        xPos: 0d,                     $ ; Normalized X position
        yPos: 0d,                     $ ; Normalized Y position
        zPos: 0d,                     $ ; Normalized Z position
        xSize: 0d,                    $ ; Normalized width
        ySize: 0d,                    $ ; Normalized height
        zSize: 0d,                    $ ; Normalized depth
        _hasPosSize: 0b,              $ ; Flag - has any SIZE|POSITION been set?
        _deviceFlag: 0b,              $ ; Flag - has DEVICE keyword been set?
        _screenXSize: 0.0d,           $ ; Pixel dimensions covered by
        _screenYSize: 0.0d            $ ;   visualization contents.
    }

end

