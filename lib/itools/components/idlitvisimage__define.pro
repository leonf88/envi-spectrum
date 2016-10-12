; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisimage__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;   The IDLitVisImage class is the component wrapper for IDLgrImage
;

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisImage::Init
;
; PURPOSE:
;   This function method initializes the component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitVisImage')
;
;    or
;
;   Obj->[IDLitVisImage::]Init
;
; KEYWORD PARAMETERS:
;   This function method accepts all keywords accepted by the
;   ::Init methods of the superclasses.  In addition, the following
;   keywords are supported:
;
;   DATA (Set): Set this keyword to an array representing the data
;     to be associated with this image.  The array should be a 2D
;     or 3D array.
;
;   TRANSPARENCY (Get, Set):  Set this keyword to a value
;     between 0 and 100 indicating the percentage that this image
;     is to appear transparent.  The default is 0 (i.e. fully opaque).
;
; OUTPUTS:
;   This function method returns 1 on success, or 0 on failure.
;-
function IDLitVisImage::Init, $
                      NAME=NAME, $
                      DESCRIPTION=DESCRIPTION, $
                      _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not keyword_set(name))then name ="Image"
    if(not keyword_set(DESCRIPTION))then $
        DESCRIPTION ="An Image Visualization"
    ; Initialize superclass
    if(self->IDLitVisualization::Init(/ISOTROPIC, TYPE="IDLIMAGE", $
                                      NAME=NAME, ICON='demo', $
                                      DESCRIPTION=DESCRIPTION, $
                                      _EXTRA=_extra) ne 1) then $
      RETURN, 0


    if (self->_IDLitVisGrid2D::Init(_EXTRA=_extra, $
        X_DATA_ID='X', $
        Y_DATA_ID='Y', $
        Z_DATA_ID='IMAGEPIXELS', $
        GRID_UNIT_LABEL='pixels', $
        GEOMETRY_UNIT_LABEL='', $
        /PIXELATED, $
        PIXEL_CENTER=[0.5,0.5]) ne 1) then begin
        self->Cleanup
        RETURN, 0
    endif

    ; Register data parameters.
    self->RegisterParameter, 'IMAGEPIXELS', DESCRIPTION='Image Data', $
        /INPUT, TYPES=['IDLIMAGEPIXELS', 'IDLARRAY2D'], /OPTARGET

    self->RegisterParameter, 'PALETTE', DESCRIPTION='Palette', $
        /INPUT, /OPTIONAL, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTARGET

    self->RegisterParameter, 'X', DESCRIPTION='X Data', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

    self->RegisterParameter, 'Y', DESCRIPTION='Y Data', $
        /INPUT, /OPTIONAL, TYPES=['IDLVECTOR','IDLARRAY2D']

    ; Create Image object and add it to this Visualization.
    self._oImage = OBJ_NEW('IDLgrImage', /REGISTER_PROPERTIES, /PRIVATE, $
        DEPTH_TEST_DISABLE=0, TRANSFORM_MODE=1)

    ; Set dimensionality method to always be 2D.
    self->Set3D, 0, /ALWAYS

    ; Request no axes.
    self->SetAxesStyleRequest, 0 ; Request no axes by default.

    ; Note: the IDLgrImage properties will be aggregated as part
    ; of the property registration process in an upcoming call to
    ; ::_RegisterProperties.
    self->Add, self._oImage

    ; Register all properties.
    self->IDLitVisImage::_RegisterProperties

    self._bHaveImgData = 0b

    self._bWorldIs3D = 0b
    self._bSelfRotated = 0b
    self._bWorldRotated = 0b

    ramp = BINDGEN(256)
    self._oCurrPal = OBJ_NEW('IDLgrPalette', RED=ramp, GREEN=ramp, BLUE=ramp)

    ; Set any properties
    if(n_elements(_extra) gt 0)then $
      self->IDLitVisImage::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisImage::Cleanup
;
; PURPOSE:
;   This procedure method preforms all cleanup on the object.
;
;   NOTE: Cleanup methods are special lifecycle methods, and as such
;   cannot be called outside the context of object destruction.  This
;   means that in most cases, you cannot call the Cleanup method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Cleanup method
;   from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[IDLitVisImage::]Cleanup
;
;-
pro IDLitVisImage::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oImage
    OBJ_DESTROY, self._oCurrPal

    ; Cleanup superclasses
    self->IDLitVisualization::Cleanup
    self->_IDLitVisGrid2D::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisImage::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisImage::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisImage::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Aggregate the image properties.
        self->Aggregate, self._oImage

        self->RegisterProperty, 'VISUALIZATION_PALETTE', $
            NAME='Image palette', $
            USERDEF='Edit color table', $
            DESCRIPTION='Image palette', $
            SENSITIVE=0, /ADVANCED_ONLY

        self->RegisterProperty, 'INTERPOLATE', $
            ENUMLIST=['Nearest Neighbor','Bilinear'], $
            DESCRIPTION='Interpolation', $
            NAME='Interpolation', /ADVANCED_ONLY

        self->RegisterProperty, 'ZVALUE', /FLOAT, $
            NAME='Z value', $
            DESCRIPTION='Z value for image plane', /ADVANCED_ONLY

    endif

    if (registerAll || (updateFromVersion lt 610)) then begin

        self->RegisterProperty, 'GRID_UNITS', $
            DESCRIPTION='Grid units', $
            NAME='Grid units', $
            ENUMLIST=['Not applicable','Meters','Degrees'], $
            SENSITIVE=0, /ADVANCED_ONLY

    endif

    if (registerAll) then begin

        self->RegisterProperty, 'PIXEL_XSIZE', $
            DESCRIPTION='X size of a pixel in data units', $
            NAME='Pixel size (x)', /FLOAT, /ADVANCED_ONLY

        self->RegisterProperty, 'PIXEL_YSIZE', $
            DESCRIPTION='Y size of a pixel in data units', $
            NAME='Pixel size (y)', /FLOAT, /ADVANCED_ONLY

        self->RegisterProperty, 'XORIGIN', $
            DESCRIPTION='X location of image origin in data units', $
            NAME='Origin (x)', /FLOAT, /ADVANCED_ONLY

        self->RegisterProperty, 'YORIGIN', $
            DESCRIPTION='Y location of image origin in data units', $
            NAME='Origin (y)', /FLOAT, /ADVANCED_ONLY

        self->RegisterProperty, 'GEOMETRY_UNIT_LABEL', $
            DESCRIPTION='Label for image pixel data units', $
            NAME='Unit label', /STRING, /ADVANCED_ONLY

    endif

    ; IMAGE_TRANSPARENCY became TRANSPARENCY in IDL64.
    if (registerAll || (updateFromVersion lt 640)) then begin
        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            DESCRIPTION='Image transparency (%)', $
            NAME='Image transparency', $
            VALID_RANGE=[0,100,5]
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin

        ; CT, Jan 2004: These are new properties which need to be
        ; registered on existing IDL60 image objects.
        self->RegisterProperty, 'BYTESCALE_MIN', $
            NAME='Bytescale minimum', $
            USERDEF='Bytescale minimum', $
            DESCRIPTION='Minimum values for bytescale', $
            /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'BYTESCALE_MAX', $
            NAME='Bytescale maximum', $
            USERDEF='Bytescale maximum', $
            DESCRIPTION='Minimum values for bytescale', $
            /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'BYTESCALE_RANGE_APPLIES', $
            NAME='Bytescale range applies', $
            /BOOLEAN, $
            DESCRIPTION='Bytescale range applies', $
            /HIDE, /ADVANCED_ONLY
    endif

    if (~registerAll && updateFromVersion lt 640) then begin
        ; IMAGE_TRANSPARENCY became TRANSPARENCY in IDL64.
        self->SetPropertyAttribute, 'IMAGE_TRANSPARENCY', /HIDE
    endif

    self._oImage->SetPropertyAttribute, $
        ['ALPHA_CHANNEL', 'COLOR', 'DEPTH_OFFSET', 'GREYSCALE', $
        'INTERPOLATE', 'ORDER', 'TILING', 'TRANSFORM_MODE'], /HIDE, $
        /ADVANCED_ONLY

end

;----------------------------------------------------------------------------
; IDLitVisImage::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisImage::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore
    self->_IDLitVisGrid2D::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oImage)) then $
        self._oImage->GetProperty

    ; Register new properties.
    self->IDLitVisImage::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
    endif

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      to 6.2 or above:
    ;
    ; In IDL 6.2, the IDLgrImage object internal implementation was upgraded
    ; (for performance) to utilize texture maps for display.  As a result
    ; of these changes, the IDLitVisImage class no longer needs to switch
    ; back and forth between a texture-mapped polygon and a simple image
    ; depending upon rotations.  Now, in all cases, the IDLitVisImage will
    ; act like a texture mapped polygon.
    if (self.idlitcomponentversion lt 620) then begin
        ; If, in previous releases, the order property had been set,
        ; then re-set it now.  This means that a display-only order
        ; change will no longer occur, but such an order change
        ; did not make much sense anyway in the context of
        ; analysis-based iTools.  The user will simply have to go
        ; do the right thing: Operations->Flip Vertical.
        self._oImage->GetProperty, ORDER=order
        if (order ne 0) then $
            self._oImage->SetProperty, ORDER=0

        self._oImage->SetProperty, DEPTH_TEST_DISABLE=0, TRANSFORM_MODE=1, $
            DEPTH_OFFSET=self->Is3D() ? 1 : 0

        self->_IDLitVisGrid2D::OnDataChangeUpdate, $
            /UPDATE_XYPARAMS_FROM_USERVALS

        ; Update for new IDL 6.2 IDLgrImage features:
        ;   - Use ALPHA_CHANNEL property
        ;   - No need to have polygon data, but compute sub-rect data
        ;     coordinates for properly constrained ::GetDataString reports.
        self->_UpdateImageData, /RESTORE_ONLY

        ; Force the new alpha_channel property to be used.
        if (self._transparency ne 0) then $
            self->SetProperty, TRANSPARENCY=self._transparency

    endif

end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImage::]GetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::GetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisImage::Init followed by the word "Get" can be retrieved
;   using IDLitVisImage::GetProperty.  In addition, the following keywords
;   are supported:
;
;   BYTESCALE_MIN: Set this keyword to a named variable that upon return
;     will contain a vector (one element per image plane) indicating the
;     minimum value used for bytescale display of this image.
;
;   BYTESCALE_MAX: Set this keyword to a named variable that upon return
;     will contain a vector (one element per image plane) indicating the
;     maximum value used for bytescale display of this image.
;
;   TRANSPARENCY: Set this keyword to a named variable that upon
;     return will contain a scalar representing the transparency factor
;     (in the range from 0 to 100) to be applied when displaying this image.
;
;   PIXEL_XSIZE:    Set this keyword to a named variable that upon return
;     will contain a scalar representing the size of an image pixel in X,
;     measured in data units.
;
;   PIXEL_YSIZE:    Set this keyword to a named variable that upon return
;     will contain a scalar representing the size of an image pixel in X,
;     measured in data units.
;
;-
pro IDLitVisImage::GetProperty, $
    BYTESCALE_MIN=byteScaleMin, $
    BYTESCALE_MAX=byteScaleMax, $
    BYTESCALE_RANGE_APPLIES=byteScaleRangeApplies, $
    GRID_UNITS=gridUnits, $
    GEOMETRY_UNIT_LABEL=geomUnitLabel, $
    GRID_DIMENSIONS=gridDimensions, $
    IMAGE_TRANSPARENCY=imageTransparencyOld, $  ; keep for backwards compat
    TRANSPARENCY=imageTransparency, $
    MAP_PROJECTION=mapProjection, $
    MIN_VALUE=minValue, $   ; Added in IDL 8.0
    MAX_VALUE=maxValue, $   ; Added in IDL 8.0
    N_IMAGE_PLANES=nImgPlanes, $
    ODATA=oData, $
    PIXEL_XSIZE=pixelXSize, $
    PIXEL_YSIZE=pixelYSize, $
    RGB_TABLE=rgbTable, $
    VISUALIZATION_PALETTE=visPalette, $
    XORIGIN=xOrigin, $
    YORIGIN=yOrigin, $
    ZVALUE=zValue, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(byteScaleRangeApplies)) then $
        byteScaleRangeApplies = self._bHaveImgData

    if (ARG_PRESENT(minValue) || ARG_PRESENT(maxValue) || $
      ARG_PRESENT(byteScaleMin) || ARG_PRESENT(byteScaleMax)) then begin
        if (self->DoApplyByteScale(N_PLANES=nPlanes)) then begin
            byteScaleMin = self._byteScaleMin[0:nPlanes-1]
            byteScaleMax = self._byteScaleMax[0:nPlanes-1]
        endif else begin
            ; if no image data, then reset nPlanes to 1.
            nPlanes = nPlanes > 1
            byteScaleMin = REPLICATE(0,nPlanes)
            byteScaleMax = REPLICATE(255,nPlanes)
        endelse
        minValue = byteScaleMin
        maxValue = byteScaleMax
    endif

    ; IMAGE_TRANSPARENCY became TRANSPARENCY in IDL64.
    ; Keep for backwards compat.
    if (ARG_PRESENT(imageTransparencyOld)) then $
        imageTransparencyOld = self._transparency

    if ARG_PRESENT(imageTransparency) then $
        imageTransparency = self._transparency

    if ARG_PRESENT(mapProjection) then begin
        if (OBJ_VALID(self._oMapProj)) then begin
            self._oMapProj->GetProperty, MAP_PROJECTION=mapProjection
        endif else $
            mapProjection = 'No projection'
    endif

    if ((ARG_PRESENT(nImgPlanes)) || (ARG_PRESENT(oData))) then begin
        oImgPixels = self->GetParameter('IMAGEPIXELS')
        if (OBJ_VALID(oImgPixels)) then begin
            if (ARG_PRESENT(oData)) then begin
                if (OBJ_ISA(oImgPixels,'IDLitDataIDLImagePixels')) then $
                   oData = oImgPixels->Get(/ALL) $
                else $
                   oData = oImgPixels
            endif

            if (ARG_PRESENT(nImgPlanes)) then begin
                if (oImgPixels->GetData(pImgData, /POINTER)) then $
                    nImgPlanes = PTR_VALID(pImgData[0]) ? $
                        (N_ELEMENTS(pImgData) < 4) : 0 $
                else $
                    nImgPlanes = 0
            endif
        endif else begin
            if (ARG_PRESENT(oData)) then $
                oData = OBJ_NEW()

            if (ARG_PRESENT(nImgPlanes)) then $
                nImgPlanes = 0
        endelse
    endif

    if ARG_PRESENT(_data) then $
        self._oImage->GetProperty, DATA=_data

    if (ARG_PRESENT(visPalette) || ARG_PRESENT(rgbTable)) then begin
        self._oCurrPal->GetProperty, BLUE_VALUES=blue, $
            GREEN_VALUES=green, RED_VALUES=red
        visPalette = TRANSPOSE([[red], [green], [blue]])
        rgbTable = visPalette
    endif

    if (ARG_PRESENT(pixelXSize)) then $
        pixelXSize = self._userStep[0]

    if (ARG_PRESENT(pixelYSize)) then $
        pixelYSize = self._userStep[1]

    if (ARG_PRESENT(xOrigin)) then $
        xOrigin = self._userOrigin[0]

    if (ARG_PRESENT(yOrigin)) then $
        yOrigin = self._userOrigin[1]

    if (ARG_PRESENT(gridUnits)) then $
        self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    if (ARG_PRESENT(geomUnitLabel)) then $
        self->_IDLitVisGrid2D::GetProperty, GEOMETRY_UNIT_LABEL=geomUnitLabel

    if (ARG_PRESENT(gridDimensions)) then $
        self->_IDLitVisGrid2D::GetProperty, GRID_DIMENSIONS=gridDimensions

    if (ARG_PRESENT(zValue)) then $
        zValue = self._zValue

    ; Get properties from superclass.
    if (N_ELEMENTS(_extra) gt 0) then begin
        if (OBJ_VALID(self._oMapProj)) then begin
            self._oMapProj->GetProperty, _EXTRA=_extra
        endif
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
    endif
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::EnsureXYParameters
;
; PURPOSE:
;   Ensure that X and Y parameters exist, based on the image dimensions,
;   origin and pixel size.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImage::]EnsureXYParameters
;
; KEYWORD PARAMETERS:
;   None.
;
; USAGE:
;   This is used by operations such as IDLitOpInsertContour, that need
;   the image parameter in order to create a contour based on the
;   image and to be notified of changes to the image.
;-
pro IDLitVisImage::EnsureXYParameters

    compile_opt idl2, hidden

    paramNames = ['X', 'Y']
    for i=0,1 do begin
        ; Check if parameter already exists.
        oParam = self->GetParameter(paramNames[i])
        if ~obj_valid(oParam) then begin
            ; Create and set the parameter.
            ; Be sure to use the original (user-defined) dims, step, & origin.
            data = DINDGEN(self._userDims[i])*self._userStep[i] + $
                self._userOrigin[i]
            oData = OBJ_NEW('IDLitDataIDLVector', data, NAME=paramNames[i])
            oData->SetProperty,/AUTO_DELETE
            self->SetParameter, paramNames[i], oData, /NO_UPDATE

            ; Add to data manager.
            oData = self->GetParameter(paramNames[i])

            ;; add to the same container in which the image pixels are
            ;; contained
            oImagePixels = self->GetParameter('IMAGEPIXELS')
            IF obj_valid(oImagePixels) THEN BEGIN
              oImagePixels->GetProperty,_PARENT=oParent

              ; Note: the X,Y data should not be added to an
              ; IDLitDataIDLImagePixels object.  Keep walking up the tree.
              if (OBJ_ISA(oParent, 'IDLitDataIDLImagePixels')) then begin
                oImagePixels = oParent
                oImagePixels->GetProperty,_PARENT=oParent
              endif

              IF obj_valid(oParent) THEN BEGIN
                oParent->Add,oData
                ;; check to see if we need to mangle the name
                ;; Get our base name and append the id number.
                oData->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
                ;; See if we have an id number at the end of our identifier.
                idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
                ;; Append the id number.
                IF (STRMATCH(idnum, '[0-9]*')) THEN BEGIN
                  name += ' ' + idnum
                  ;; set new name
                  oData->IDLitComponent::SetProperty, NAME=name
                  oTool = self->GetTool()
                  oTool->DoOnNotify,oData->GetFullIdentifier(), $
                                    'SETPROPERTY','NAME'
                ENDIF
              ENDIF ELSE BEGIN
                self->AddByIdentifier,'/DATA MANAGER',oData
              ENDELSE
            ENDIF

        endif
    endfor

    ; Send a notification message to update UI
    self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''

end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImage::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisImage::Init followed by the word "Set" can be retrieved
;   using IDLitVisImage::SetProperty.
;-
pro IDLitVisImage::SetProperty, $
    BYTESCALE_DATARANGE=byteScaleDataRange, $
    BYTESCALE_MIN=byteScaleMin, $
    BYTESCALE_MAX=byteScaleMax, $
    BYTESCALE_RANGE_APPLIES=byteScaleRangeApplies, $
    GRID_UNITS=gridUnitsIn, $
    GEOMETRY_UNIT_LABEL=geomUnitLabel, $
    IMAGE_TRANSPARENCY=imageTransparencyOld, $  ; keep for backwards compat
    TRANSPARENCY=imageTransparency, $
    INTERPOLATE=interpolate, $
    DATA=data, $
    DIMENSIONS=dimensions, $  ; Swallow [see Note below].
    LOCATION=location, $      ; Swallow [see Note below].
    MAP_PROJECTION=mapProjection, $
    MIN_VALUE=minValue, $   ; Added in IDL 8.0
    MAX_VALUE=maxValue, $   ; Added in IDL 8.0
    ORDER=order, $            ; Swallow.  Display-only order makes little sense.
    PIXEL_XSIZE=pixelXSize, $
    PIXEL_YSIZE=pixelYSize, $
    TRANSFORM=transform, $
    XORIGIN=xOrigin, $
    YORIGIN=yOrigin, $
    ZVALUE=zValue, $
    RGB_TABLE=rgbTable, $
    VISUALIZATION_PALETTE=visPalette, $
    _REF_EXTRA=_extra

    ; Note about LOCATION and DIMENSIONS keywords:  When a tool is started,
    ; the user may choose to set the LOCATION and/or DIMENSIONS keywords.
    ; In this case, the location and dimensions refer to the visualization
    ; window, not to the IDLitVisImage.  However, the DIMENSIONS keyword is
    ; passed along to both the window and the IDLitVisImage (via an _EXTRA
    ; mechanism).  Therefore, we choose to ignore the LOCATION and DIMENSIONS
    ; keyword setting on this class.  If the LOCATION or DIMENSIONS
    ; of the IDLgrImage need to be set, then that should be done directly via
    ; the IDLgrImage class (for the ._oImage member data).

    compile_opt idl2, hidden


    bNewData = 0b
    bUpdateData = 0b
    bUpdateByteScaleMin = 1b
    bUpdateByteScaleMax = 1b
    bUpdateGrid = [0b,0b]

    ; Is this object being initialized during creation by the prefs system?
    self->IDLitComponent::GetProperty, Initializing=isInit

    ; DATA.  We do this first so that later we can know if new
    ; data is ready to be set.
    dims = SIZE(data, /DIMENSIONS)
    nDims = N_ELEMENTS(dims)
    if (nDims ge 2) then begin
        bNewData = 1b
        bUpdateData = 1b
    endif

    if (ISA(minValue)) then byteScaleMin = minValue
    if (ISA(maxValue)) then byteScaleMax = maxValue

    if (N_ELEMENTS(byteScaleDataRange) eq 2) then begin
        if (byteScaleDataRange[0] lt byteScaleDataRange[1]) then begin
            self._haveBSDataRange = 1b
            self._BSDataRange = byteScaleDataRange

            ; Clamp the bytescale min and max to the given range.
            self._byteScaleMin = self._byteScaleMin > self._BSDataRange[0]
            self._byteScaleMax = self._byteScaleMax < self._BSDataRange[1]

            bUpdateData = 1b

            ; Only re-initialize the bytescale min/max if we have
            ; new data.
            bUpdateByteScaleMin = bNewData
            bUpdateByteScaleMax = bNewData
        endif
    endif

    if (N_ELEMENTS(byteScaleRangeApplies)) then begin
        ; If the image has data, the current bytescale range always
        ; applies (it has either been computed from the data, or preset).
        ; However, if the image has no data, then the range is considered
        ; applicable only if so flagged...if not, it needs to be computed
        ; from the data when the data gets hooked up.
        ; This flag is useful in the case that properties are played
        ; back from a propertybag (for example, when an image is copied,
        ; then pasted).
        if (~self._bHaveImgData && $
            KEYWORD_SET(byteScaleRangeApplies)) then $
            self._bHaveImgData = 1
        bUpdateData = 1b
    endif

    if (N_ELEMENTS(byteScaleMin) gt 0) then begin
        nval = N_ELEMENTS(byteScaleMin)
        self._byteScaleMin[0:nval-1] = byteScaleMin

        ; If the bytescale data range is explicitly provided, clamp
        ; the bytescale min to that range.
        if (self._haveBSDataRange) then $
            self._byteScaleMin = self._byteScaleMin > self._BSDataRange[0]

        bUpdateData = 1b
        bUpdateByteScaleMin = 0b
        bUpdateByteScaleMax = 0b
    endif

    if (N_ELEMENTS(byteScaleMax) gt 0) then begin
        nval = N_ELEMENTS(byteScaleMax)
        self._byteScaleMax[0:nval-1] = byteScaleMax

        ; If the bytescale data range is explicitly provided, clamp
        ; the bytescale max to that range.
        if (self._haveBSDataRange) then $
            self._byteScaleMax = self._byteScaleMax < self._BSDataRange[1]

        bUpdateData = 1b
        bUpdateByteScaleMin = 0b
        bUpdateByteScaleMax = 0b
    endif

    ;; Notify image panel menu
    if (N_ELEMENTS(byteScaleMin) gt 0) or $
       (N_ELEMENTS(byteScaleMax) gt 0) then begin
        self->DoOnNotify, self->GetFullIdentifier(), 'IMAGECHANGED', 0
    endif

    ; IMAGE_TRANSPARENCY became TRANSPARENCY in IDL64.
    ; Keep for backwards compat.
    if (N_ELEMENTS(imageTransparencyOld) eq 1) then $
        imageTransparency = imageTransparencyOld

    if (N_ELEMENTS(imageTransparency) eq 1) then begin
        oldTransparency = self._transparency
        self._transparency = 0 > imageTransparency < 100
        alphaValue = 0.0 > ((100 - self._transparency) * 0.01d) < 1.0
        blend = (alphaValue lt 1.0) || $
            (self._nImagePlanes eq 2) || (self._nImagePlanes ge 4) ? $
            [3,4] : [0,0]
        self._oImage->SetProperty, ALPHA_CHANNEL=alphaValue, $
            BLEND_FUNCTION=blend
        self->DoOnNotify, self->GetFullIdentifier(), 'IMAGECHANGED', 0
    endif

    ; Handle interpolation.
    if (N_ELEMENTS(interpolate) ne 0) then begin
        ; Simply set the interpolate property. Don't need to
        ; call UpdateImageData because it's all handled internally.
        self._oImage->SetProperty, INTERPOLATE=interpolate
        ; If we have a map projection, then we *do* need to call
        ; UpdateImageData to use the new interpolation scheme.
        bUpdateData = self._hasMapProjection
    endif

    ; Copy any command-line map projection properties to ourself.
    if (N_ELEMENTS(mapProjection) gt 0) then begin
        oMapProj = self->_GetMapProjection()
        self._oMapProj->SetProperty, MAP_PROJECTION=mapProjection
        bUpdateData = self._hasMapProjection
    endif

    if ((N_ELEMENTS(rgbTable) ne 0) && (N_ELEMENTS(visPalette) eq 0)) then begin
      if (N_ELEMENTS(rgbTable) eq 1) then begin
        Loadct, rgbTable[0], RGB_TABLE=visPalette
        visPalette = TRANSPOSE(visPalette)
      endif else begin
        visPalette = rgbTable
      endelse
    endif
    
    if (N_ELEMENTS(visPalette) gt 0 and ~isInit) then begin
        self._oCurrPal->SetProperty, BLUE_VALUES=visPalette[2,*], $
            GREEN_VALUES=visPalette[1,*], RED_VALUES=visPalette[0,*]
        self._oImage->SetProperty, PALETTE=self._oCurrPal
        ;; Update parameter
        oPal = self->GetParameter('PALETTE')
        if OBJ_VALID(oPal) then $
            success = oPal->SetData(visPalette)
    endif

    roiScale = [1.0,1.0]
    origOrigin = self._userOrigin
    origStep = self._userStep
    if (N_ELEMENTS(pixelXSize) ne 0) then begin
        if ((pixelXSize gt 0) && $
            (pixelXSize ne self._userStep[0])) then begin
                self._userStep[0] = pixelXSize
                bUpdateGrid[0] = 1b
        endif
    endif

    if (N_ELEMENTS(pixelYSize) ne 0) then begin
        if ((pixelYSize gt 0) && $
            (pixelYSize ne self._userStep[1])) then begin
            self._userStep[1] = pixelYSize
            bUpdateGrid[1] = 1b
        endif
    endif

    if (N_ELEMENTS(xOrigin) ne 0) then begin
        if (xOrigin[0] ne self._userOrigin[0]) then begin
            self._userOrigin[0] = xOrigin[0]
            bUpdateGrid[0] = 1b
        endif
    endif

    if (N_ELEMENTS(yOrigin) ne 0) then begin
        if (yOrigin[0] ne self._userOrigin[1]) then begin
            self._userOrigin[1] = yOrigin[0]
            bUpdateGrid[1] = 1b
        endif
    endif

    if (N_ELEMENTS(gridUnitsIn) ne 0) then begin
      self->_IDLitVisGrid2D::SetProperty, GRID_UNITS=gridUnitsIn
      self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits
      if (gridUnits gt 0) then begin
          self->_IDLitVisGrid2D::SetProperty, $
              GEOMETRY_UNIT_LABEL=(gridUnits eq 2) ? 'Degrees' : 'Meters'
      endif
      ; UpdateImageData if we have a map projection.
      bUpdateData = self._hasMapProjection
    endif

    if (N_ELEMENTS(geomUnitLabel) ne 0) then $
        self->_IDLitVisGrid2D::SetProperty, GEOMETRY_UNIT_LABEL=geomUnitLabel

    if (N_ELEMENTS(zValue) ne 0) then begin
        self._zValue = zValue
        self->IDLgrModel::Reset
        self->IDLgrModel::Translate, 0, 0, zValue
        ; put the visualization into 3D mode if necessary
        self->Set3D, (zvalue ne 0), /ALWAYS
        self->OnDataChange, self
        self->OnDataComplete, self
    endif

    if (bUpdateGrid[0] || bUpdateGrid[1]) then begin

        self->_IDLitVisGrid2D::OnDataChangeUpdate, $
            UPDATE_XYPARAMS_FROM_USERVALS=bUpdateGrid

        ; Reposition ROIs (but only if grid really changed.)
        scaleChange = ~ARRAY_EQUAL(self._userStep, origStep)
        roiScale= scaleChange ? (self._userStep / origStep) : [1.0d,1.0d]
        if (scaleChange || $
            (~ARRAY_EQUAL(origOrigin, self._userOrigin))) then $
            self->_RepositionRegions, roiScale, origOrigin, self._userOrigin

        ; This will also call setsubrect and update the dataspace.
        self->OnProjectionChange

    endif

    ; If necessary, update the image data.
    if (bUpdateData && ~isInit && $
        (self._bHaveImgData || bNewData)) then begin
        self->_UpdateImageData, $
            UPDATE_BYTSCL_MIN=bUpdateByteScaleMin, $
            UPDATE_BYTSCL_MAX=bUpdateByteScaleMax
    endif

    ; Determine if the transform causes a rotation or skew.
    ; If so, switch to a texture map representation.
    if (N_ELEMENTS(transform) eq 16) then begin
        ; If the transform only includes scales and/or translates,
        ; then:
        ;    transform = [sx  0  0  tx
        ;                  0 sy  0  ty
        ;                  0  0 sz  tz
        ;                  0  0  0   1]
        izero = [1,2,4,6,8,9,12,13,14]
        inonzero = WHERE(ABS(transform[izero]) ge 1e-10, count)

        if (count eq 0) then begin
            ; Also check if either (or both) of the x or y scale
            ; factors is negative.  If so, then claim a "rotation".
            iscale = [0,5]
            ineg = WHERE(transform[iscale] lt 0.0, count)
        endif

        isRotated = count gt 0
        if (self._bSelfRotated ne isRotated) then begin
            oldStatus = self->QueryPixelScaleStatus()

            self._bSelfRotated = isRotated

            ; Broadcast notification of pixel scale status change to
            ; any interested parties.
            newStatus = self->QueryPixelScaleStatus()
            if (newStatus ne oldStatus) then $
                self->DoOnNotify, self->GetFullIdentifier(), $
                    'PIXEL_SCALE_STATUS', newStatus
        endif
    endif

    ; Set superclass properties
    if ((N_ELEMENTS(_extra) gt 0) || $
        (N_ELEMENTS(transform) gt 0)) then begin
        if (OBJ_VALID(self._oMapProj)) then begin
            self._oMapProj->SetProperty, _EXTRA=_extra
        endif
        self->IDLitVisualization::SetProperty, TRANSFORM=transform, $
            _EXTRA=_extra
    endif
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data from the grImage
;
; Arguments:
;   DATA
;
; Keywords:
;   NONE
;
pro IDLitVisImage::GetData, data, _EXTRA=_extra
  compile_opt idl2, hidden
  
  oImagePixels = self->GetParameter("IMAGEPIXELS")
  if (OBJ_VALID(oImagePixels)) then begin
    if (oImagePixels->GetData(pImgData, /POINTER)) then begin
      if (PTR_VALID(pImgData[0])) then begin
        data = MAKE_ARRAY([N_ELEMENTS(pImgData), SIZE(*pImgData[0], $
                                                      /DIMENSIONS)], $
                          TYPE=SIZE(*pImgData[0], /TYPE))
        for i=0,N_ELEMENTS(pImgData)-1 do begin
          data[i,*,*] = *pImgData[i]
        endfor
        data = REFORM(data)
      endif
    endif
  endif
  
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   parm1, parm2, parm3
;
; Keywords:
;   NONE
;
pro IDLitVisImage::PutData, parm1, parm2, parm3, _EXTRA=_extra
  compile_opt idl2, hidden

  RESOLVE_ROUTINE, 'iImage', /NO_RECOMPILE

  void = iImage_GetParmSet(oParmSet, parm1, parm2, parm3, _EXTRA=_extra)
  
  ;; Get the data from the parameterset and set the properties
  oDataIP = oParmSet->GetByName('IMAGEPIXELS')
  if (OBJ_VALID(oDataIP)) then begin
    self->SetParameter, 'IMAGEPIXELS', oDataIP
    oDataIP->SetProperty, /AUTO_DELETE
  endif
  oDataX = oParmSet->GetByName('X')
  if (OBJ_VALID(oDataX)) then begin
    self->SetParameter, 'X', oDataX
    oDataX->SetProperty, /AUTO_DELETE
  endif
  oDataY = oParmSet->GetByName('Y')
  if (OBJ_VALID(oDataY)) then begin
    self->SetParameter, 'Y', oDataY
    oDataY->SetProperty, /AUTO_DELETE
  endif

  ;; Update the parameters
  self->OnDataChangeUpdate, oParmSet, '<PARAMETER SET>'

  ;; Clean up parameterset
  oParmSet->Remove, /ALL
  OBJ_DESTROY, oParmSet

  ; Send a notification message to update UI
  self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''
  self->OnDataComplete, self

  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow
  
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::DoApplyByteScale
;
; PURPOSE:
;   This function method determines whether bytescaling should be
;   applied or not.
;
; CALLING_SEQUENCE:
;   Result = Obj->[IDLitVisImage::]DoApplyByteScale()
;
; Keywords:
;   IMAGE_DATA: Set this keyword to a scalar or vector of pointers,
;      with each one pointing to a different image channel.
;      If not provided, the image data pointers will be retrieved
;      from this object's parameters.
;      (This keyword is provided primarily as an optimization so that if
;      the image data had already been retrieved, it can just be passed
;      along.)
;
;   N_PLANES:   Set this keyword to a named variable that upon return
;      will contain a scalar representing the number of planes in the
;      image data.

; OUTPUTS:
;   This function method returns 1 if bytescaling is to be applied,
;   or 0 if not.
;-
function IDLitVisImage::DoApplyByteScale, IMAGE_DATA=pImgData, $
    N_PLANES=nPlanes

    compile_opt idl2, hidden

    ; Start with assumption that bytescaling should be applied.
    bDoByteScale = 1b

    if (self->_GetImageDimensions(imgDims, N_PLANES=nPlanes, $
        IMAGE_DATA=pImgData)) then begin
        nPlanes <= 4
        if (self._isByteData) then begin
            ; If byte data, and the bytescale min and max is 0...255 for
            ; all planes, then do not apply bytescale.
            iNonZero = WHERE(self._byteScaleMin[0:nPlanes-1] ne 0, nNonZero)
            iNonMax = WHERE(self._byteScaleMax[0:nPlanes-1] ne 255, nNonMax)
            bDoByteScale = ((nNonZero + nNonMax) ne 0)
        endif else $
            bDoByteScale = 1b
    endif else begin
        pImgData = PTR_NEW()
        bDoByteScale = 0b
    endelse

    return, bDoByteScale
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::GetByteScaleDataRange
;
; PURPOSE:
;   This function method returns the full data range within which
;   the bytescale min/max for this image must fall.
;
;   The range is selected as follows:
;     - If the image data is type byte:
;           dataRange = [0,255]
;           return value = 1
;
;     - If the image data is any other type:
;        - If the data range was explicitly set (via the
;          BYTESCALE_DATARANGE keyword to ::SetProperty),
;           dataRange = BYTESCALE_DATARANGE
;           return value = 1
;
;        - Otherwise:
;          dataRange needs to be automatically computed
;          (based upon the min and max data value per channel).
;          In this case:
;           dataRange = [0.0,1.0] ; values are irrelevant
;           return value = 0
;
; CALLING_SEQUENCE:
;   Result = Obj->[IDLitVisImage::]GetByteScaleDataRange(dataRange)
;
; Arguments:
;   dataRange: Upon return, this argument will be set to a two-element
;      vector, [min,max], representing the data range (as described
;      in the above comments).
;
; Return value:
;   This function returns a 1 if the data range can be used as
;   provided, or a 0 if the dataRange needs to be automatically
;   computed per (based upon the min and max data value per
;   channel).
;
; OUTPUTS:
;   This function method returns 1 if a byte range is to be used,
;   or 0 if not.
;-
function IDLitVisImage::GetByteScaleDataRange, dataRange

    compile_opt idl2, hidden

    ; Cover the case of no data as if it was byte data,
    ; and explicitly set the range to 0...255.
    if (~self._bHaveImgData) then begin
        dataRange = [0b,255]
        return, 1
    endif

    ; Byte data always uses a data range of 0...255.
    if (self._isByteData) then begin
        dataRange = [0b,255]
        return, 1
    endif else begin
        if (self._haveBSDataRange) then begin
            ; If the data range was explicitly set, use it.
            dataRange = self._BSDataRange
            return, 1
        endif else begin
            ; Otherwise, the data range needs to be automatically
            ; computed.
            dataRange = [0.0,1.0]
            return, 0
        endelse
    endelse
end

;----------------------------------------------------------------------------
function IDLitVisImage::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

        'VISUALIZATION_PALETTE': begin
            success = oTool->DoUIService('PaletteEditor', self)
            if success then begin
                return, 1
            endif
        end

        else:

    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;; IDLitVisImage::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the surface.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
PRO IDLitVisImage::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   ;; Just check the name and perform the desired action
   case ParmName of
       'IMAGEPIXELS': begin
           ;; You can't unset data, so we hide the texture mapped polygon.
           self->SetProperty, DATA=0
           self._bHaveImgData = 0b
           self._isByteData = 0b
           self._oImage->SetProperty, /HIDE

           ; Notify ROIs of change.
           self->_UpdateRegionPixels
       end
       'PALETTE': begin
            self._oImage->SetProperty, PALETTE=OBJ_NEW()
            self._oCurrPal->SetProperty, NAME="No Palette"
            self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=0
           end
       'X': begin
            self._userOrigin[0] = 0.0
            self._userStep[0] = 1.0
            self->_IDLitVisGrid2D::OnDataChangeUpdate
           end
       'Y': begin
            self._userOrigin[1] = 0.0
            self._userStep[1] = 1.0
            self->_IDLitVisGrid2D::OnDataChangeUpdate
           end
       else:
       endcase
end

;----------------------------------------------------------------------------
; IDLitVisImage::_GetImageDimensions
;
; Purpose:
;   This function method returns the dimensions of a single plane of
;   the image data associated with this object.
;
; Parameters:
;   imgDims:    A named variable that upon return will contain a 2-element
;       vector, [nx, ny], representing the dimensions of a single plane of
;       the image.
;
; Keywords:
;   IMAGE_DATA: Set this keyword to a scalar or vector of pointers,
;      with each one pointing to a different image channel.
;      If not provided, the image data pointers will be retrieved
;      from this object's parameters.
;      (This keyword is provided primarily as an optimization so that if
;      the image data had already been retrieved, it can just be passed
;      along.)
;
;   INTERLEAVE: Set this keyword to a named variable that upon return will
;      contain the interleave setting for the image data.
;
;   N_DIMENSIONS: Set this keyword to a named variable that upon return
;      will contain a scalar representing the number of dimensions of the
;      image data.
;
;   N_PLANES:   Set this keyword to a named variable that upon return
;      will contain a scalar representing the number of planes in the
;      image data.
;
; Outputs:
;   This function returns a 1 if able to successfully get the image
;   dimension, or a 0 otherwise (for example, if the data pointer is
;   invalid).
;
function IDLitVisImage::_GetImageDimensions, imgDims, $
    IMAGE_DATA=pImgData, $
    INTERLEAVE=interleave, $
    N_DIMENSIONS=nDims, $
    N_PLANES=nPlanes

    compile_opt idl2, hidden

    ; Make sure an (or more)image data pointer(s) is available and valid.
    bValidData = MIN(PTR_VALID(pImgData)) eq 1

    if (~bValidData) then begin
        ; Retrieve the original pixel data.
        oImagePixels = self->GetParameter("IMAGEPIXELS")
        if (OBJ_VALID(oImagePixels)) then begin
             if (oImagePixels->GetData(pImgData, /POINTER)) then begin
                bValidData = 1b
                oImagePixels->GetProperty, INTERLEAVE=interleave
            endif else $
                bValidData = 0b
        endif else $
            bValidData = 0b
    endif

    if (bValidData) then begin
        nPlanes = N_ELEMENTS(pImgData) < 4
        nDims = (nPlanes eq 1) ? 2 : 3

        ; Collect maximum dimensions.
        imgDims = SIZE(*(pImgData[0]),/DIMENSIONS)
        if (nPlanes gt 1) then begin
            for i=1,nPlanes-1 do begin
                pDims = SIZE(*(pImgData[i]),/DIMENSIONS)
                imgDims = pDims > imgDims
            endfor
        endif
    endif else begin
        imgDims = [0,0]
        pImgData = PTR_NEW()
        interleave = 0
        nDims = 0
        nPlanes = 0
    endelse

    return, bValidData
end

;----------------------------------------------------------------------------
; IDLitVisImage::_GetDataDimensions
;
; Purpose:
;   This procedure method returns the X and Y data ranges for this
;   object.
;
; Parameters:
;   dataXRange: A named variable that upon return will contain a 2-element
;       vector, [xmin, xmax], representing the X data range for the image.
;
;   dataYRange: A named variable that upon return will contain a 2-element
;       vector, [ymin, ymax], representing the Y data range for the image.
;
pro IDLitVisImage::_GetDataDimensions, dataXRange, dataYRange

    compile_opt idl2, hidden

    xMin = self._gridOrigin[0]
    xMax = xMin + (self._gridStep[0] * self._gridDims[0])

    yMin = self._gridOrigin[1]
    yMax = yMin + (self._gridStep[1] * self._gridDims[1])

    dataXRange = [xMin, xMax]
    dataYRange = [yMin, yMax]

end

;----------------------------------------------------------------------------
; IDLitVisImage::SetOrigin
;
; Purpose:
;   This procedure method sets the origin for the image.
;   Note: this is similar to calling ::SetProperty with the
;   XORIGIN and YORIGIN properties set, except that ROIs are
;   not automatically repositioned.
;
pro IDLitVisImage::SetOrigin, x, y
    compile_opt idl2, hidden

    bUpdateGrid = [0b,0b]
    if (x ne self._userOrigin[0]) then begin
        self._userOrigin[0] = x
        bUpdateGrid[0] = 1b
    endif
    if (y ne self._userOrigin[1]) then begin
        self._userOrigin[1] = y
        bUpdateGrid[1] = 1b
    endif

    if (bUpdateGrid[0] || bUpdateGrid[1]) then begin
        self->_IDLitVisGrid2D::OnDataChangeUpdate, $
            UPDATE_XYPARAMS_FROM_USERVALS=bUpdateGrid

        ; This will also call setsubrect and update the dataspace.
        self->OnProjectionChange
    endif

end

;----------------------------------------------------------------------------
; IDLitVisImage::_RepositionRegions
;
; Purpose:
;   This procedure method translates and/or scales all contained
;   regions of interest by the given factors.
;
;   Note: A typical use of this is when the pixel data dimensions
;   or image origin has been changed.
;
; Parameters:
;   roiScale: A two-element vector, [sx, sy], representing the X and Y
;     scale factors to be applied to all contained regions.
;
;   oldOrigin: A two-element vector, [x0, y0], representing the origin
;     of the grid before it was changed.
;
;   newOrigin: A two-element vector, [x1, y1], representing the origin
;     of the grid after it was changed.
;
pro IDLitVisImage::_RepositionRegions, roiScale, oldOrigin, newOrigin

    compile_opt idl2, hidden

    oChildren = self->Get(/ALL)

    isROI = OBJ_ISA(oChildren, 'IDLitVisROI')
    iROIs = WHERE(isROI ne 0, nROIs)
    if (nROIs gt 0) then begin
        for i=0,nROIs-1 do begin
            oROI = oChildren[iROIs[i]]
            oRoi->_RepositionToGrid, roiScale, oldOrigin, newOrigin
        endfor
    endif
end

;----------------------------------------------------------------------------
; IDLitVisImage::_UpdateRegionPixels
;
; Purpose:
;   This procedure method notifies each contained ROI of a change
;   in image pixel values.
;
; Parameters:
pro IDLitVisImage::_UpdateRegionPixels

    compile_opt idl2, hidden

    oChildren = self->Get(/ALL)

    isROI = OBJ_ISA(oChildren, 'IDLitVisROI')
    iROIs = WHERE(isROI ne 0, nROIs)
    if (nROIs gt 0) then begin
        for i=0,nROIs-1 do begin
            oROI = oChildren[iROIs[i]]
            oROI->_UpdatePixelData
        endfor
    endif
end

;----------------------------------------------------------------------------
; IDLitVisImage::_SetSubRect
;
; Purpose:
;   This procedure method modifies the sub-image boundaries for this
;   object.
;
; Parameters:
;   subXRange: A 2-element vector, [xmin, xmax], representing the
;       requested data X range for the sub-image.  (This will be clamped
;       to the actual data dimensions of the image.)
;
;   subYRange: A 2-element vector, [ymin, ymax], representing the
;       requested data Y range for the sub-image.  (This will be clamped
;       to the actual data dimensions of the image.)
;
; Keywords:
;   IMAGE_DATA: Set this keyword to a scalar or vector of pointers,
;      with each one pointing to a different image channel.
;      If not provided, the image data pointers will be retrieved
;      from this object's parameters.
;      (This keyword is provided primarily as an optimization so that if
;      the image data had already been retrieved, it can just be passed
;      along.)
;
;   RESTORE_ONLY: Set this keyword to a non-zero value to indicate that
;      the purpose of this call is simply to restore state properly.
;      In this case, tool notifications generally will not occur.
;
pro IDLitVisImage::_SetSubRect, subXRange, subYrange, $
    IMAGE_DATA=pImgData, $
    RESTORE_ONLY=restoreOnly

    compile_opt idl2, hidden

    self->_GetDataDimensions, dataXRange, dataYRange

    if (N_PARAMS() ne 2) then begin
        ; Reset sub-rectangle according to parent dataspace range
        ; (given a new data range).  If no parent dataspace, then
        ; just reset the sub-rectangle to the full data range.
        oDataSpace = self->GetDataSpace(/UNNORMALIZED)
        if (OBJ_VALID(oDataSpace) && $
            oDataSpace->GetXYZRange(xRange, yRange, zRange, $
                /INCLUDE_AXES, /NO_TRANSFORM)) then begin
            subXRange = xRange
            subYRange = yRange
        endif else begin
            subXRange = dataXRange
            subYRange = dataYRange
        endelse
    endif

    ; Constrain sub-image to actual data range.
    clipDataXMin = (dataXRange[0] > subXRange[0]) < dataXRange[1]
    clipDataXMax = (dataXRange[0] > subXRange[1]) < dataXRange[1]
    clipDataYMin = (dataYRange[0] > subYRange[0]) < dataYRange[1]
    clipDataYMax = (dataYRange[0] > subYRange[1]) < dataYRange[1]
    self._clipDataX = [clipDataXMin, clipDataXMax]
    self._clipDataY = [clipDataYMin, clipDataYMax]

    ; Convert sub-image coordinates to normalized units.
    dxLen = dataXRange[1]-dataXRange[0]
    dyLen = dataYRange[1]-dataYRange[0]
    x0 = (clipDataXMin-dataXRange[0])/dxLen
    x1 = (clipDataXMax-dataXRange[0])/dxLen
    y0 = (clipDataYMin-dataYRange[0])/dyLen
    y1 = (clipDataYMax-dataYRange[0])/dyLen

    imgDims = self._gridDims

    ; Convert sub-image coordinates to pixel units.
    iSubXMin = ULONG(x0 * (imgDims[0]-1))
    iSubXMax = ULONG(x1 * (imgDims[0]-1))
    iSubYMin = ULONG(y0 * (imgDims[1]-1))
    iSubYMax = ULONG(y1 * (imgDims[1]-1))

    if ((iSubXMin ge iSubXMax) || (iSubYMin ge iSubYMax)) then begin
        self._oImage->SetProperty, /HIDE
        if (~KEYWORD_SET(restoreOnly)) then $
            self->SetPropertyAttribute, 'HIDE', SENSITIVE=0
        return
    endif

    ; Be sure to unhide.
    self._oImage->SetProperty, HIDE=0
    if (~KEYWORD_SET(restoreOnly)) then $
        self->SetPropertyAttribute, 'HIDE', SENSITIVE=1

    subDims = [iSubXMax-iSubXMin+1, iSubYMax-iSubYMin+1]
    if ((subDims[0] lt imgDims[0]) || (subDims[1] lt imgDims[1])) then $
        subRect = [iSubXMin, iSubYMin, subDims[0], subDims[1]] $
    else $
        subRect = [0, 0, 0, 0]

    self._oImage->SetProperty, LOCATION=[clipDataXMin,clipDataYMin], $
         DIMENSIONS=[clipDataXMax-clipDataXMin, $
                     clipDataYMax-clipDataYMin], $
         SUB_RECT=subRect

    if (~KEYWORD_SET(restoreOnly)) then $
        self->UpdateSelectionVisual

end


;----------------------------------------------------------------------------
pro IDLitVisImage::_UpdateMapProjection, data, nPlanes, red, green, blue

    compile_opt idl2, hidden

    if (~N_ELEMENTS(mapStruct)) then $
        mapStruct = self->GetProjection()
    self._hasMapProjection = N_TAGS(mapStruct) gt 0

    ; Recalculate the grid origin and step size, in case we
    ; changed our grid units.
    self->_IDLitVisGrid2D::OnDataChangeUpdate

    if (~self._hasMapProjection) then $
        return

    self->SetPropertyAttribute, 'GRID_UNITS', /SENSITIVE

    self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    ; Bail if we have no units.
    if (gridUnits eq 0) then $
        return

    ; Retrieve the latlon range.
    gridOrigin = self._userOrigin
    dims = (SIZE(data, /DIMENSIONS))[0:1]
    gridEnd = self._userStep*dims + self._userOrigin

    ; Sanity check for latlon range.
    if (gridUnits eq 2) then begin
        gridOrigin >= [-360, -90]
        gridEnd <= [720, 90]
    endif


    ; If we are in Meters, check if we have our own map projection.
    ; Don't do this for Degrees since presumably we are in geographic
    ; coordinates.
    if (gridUnits eq 1) then begin
        ; If we are in meters but don't have our own map projection,
        ; then assume we don't need to do a map projection.
        if (~OBJ_VALID(self._oMapProj)) then $
            return
        imageStruct = self._oMapProj->_GetMapStructure()
        if (N_TAGS(imageStruct) eq 0) then $
            return

        ; See if our image projection matches the map projection.
        ; If so, then we can bail early.
        uv = mapStruct.uv_box
        if (mapStruct.up_name eq imageStruct.up_name && $
            ARRAY_EQUAL(mapStruct.p, imageStruct.p) && $
            gridOrigin[0] ge uv[0] && gridOrigin[1] ge uv[1] && $
            gridEnd[0] le uv[2] && gridEnd[1] le uv[3]) then begin
            return
        endif

    endif

    self._oImage->GetProperty, INTERPOLATE=isBilinear

    ; For map projections to work with palettized images,
    ; we need to convert to RGB and do each plane separately,
    ; especially if bilinear interpolation is in effect.
    if (nPlanes eq 1) then begin
        ; We are guaranteed to have the palette from earlier.
        ; See if we have a simple grayscale ramp. If so we don't
        ; need to convert to RGB yet.
        gray = BINDGEN(256)
        isGray = ARRAY_EQUAL(red, gray) && $
          ARRAY_EQUAL(green, gray) && $
          ARRAY_EQUAL(blue, gray)
        if (~isGray) then begin
            data = [ $
                [[red[data]]], $
                [[green[data]]], $
                [[blue[data]]]]
            nPlanes = 3
        endif
    endif


    maxDims = [360,180] > (SIZE(data, /DIMENSIONS))[0:1] ;< [4096, 2048]


    if (nPlanes eq 1) then begin

        ; Make sure these keywords stay in sync with those below.
        data = MAP_PROJ_IMAGE(data, $
            [gridOrigin, gridEnd], $
            /AUTO_DIMENSIONS, $
            BILINEAR=isBilinear, $
            IMAGE_STRUCTURE=imageStruct, $
            MAP_STRUCTURE=mapStruct, $
            DIMENSIONS=maxDims, $
            UVRANGE=map_uvrange, $
            MASK=mapMask)

    endif else begin

        for i=0,nPlanes-1 do begin

            ; Make sure these keywords stay in sync with those above.
            warpedImage = MAP_PROJ_IMAGE(data[*, *, i], $
                [gridOrigin, gridEnd], $
                /AUTO_DIMENSIONS, $
                BILINEAR=isBilinear, $
                IMAGE_STRUCTURE=imageStruct, $
                MAP_STRUCTURE=mapStruct, $
                DIMENSIONS=maxDims, $
                UVRANGE=map_uvrange, $
                MASK=mapMask, $
                XINDEX=xindex, $
                YINDEX=yindex)

            newDims = SIZE(warpedImage, /DIMENSIONS)
            needTemp = ~ARRAY_EQUAL(newDims, SIZE(data, /DIMENSIONS))

            ; Only allocate a new array if necessary.
            if (needTemp) then begin
                if (i eq 0) then $
                    dataNew = BYTARR([newDims, nPlanes], /NOZERO)
                dataNew[0,0,i] = TEMPORARY(warpedImage)
            endif else begin
                data[0,0,i] = TEMPORARY(warpedImage)
            endelse

        endfor

        if (needTemp) then $
            data = TEMPORARY(dataNew)

    endelse

    imgDims = (SIZE(data, /DIMENSIONS))[0:1]

    ; If we had a grayscale ramp, expand to RGB.
    if (nPlanes eq 1 && isGray) then begin
        data = REBIN(data, imgDims[0], imgDims[1], 3)
        nPlanes = 3
    endif

    ; Are there any missing map values?
    if (~ARRAY_EQUAL(mapMask, 1b)) then begin
        if (nPlanes eq 3) then begin
            ; Add an alpha channel to the RGB.
            data = [[[TEMPORARY(data)]], $
                [[mapMask*255b]]]
            nPlanes = 4
        endif else begin
            ; Just multiply the alpha by the mask.
            data[*,*,nPlanes-1] *= mapMask
        endelse
    endif

    ; Change grid to UV coordinates.
    gridStep = (map_uvrange[[2,3]] - map_uvrange[[0,1]])/imgDims
    self->_IDLitVisGrid2D::SetProperty, $
        GRID_ORIGIN=map_uvrange[[0,1]], $
        GRID_STEP=gridStep

    self._gridDims = imgDims
end


;----------------------------------------------------------------------------
pro IDLitVisImage::_UpdateImageData, $
    UPDATE_BYTSCL_MIN=bUpdateByteScaleMin, $
    UPDATE_BYTSCL_MAX=bUpdateByteScaleMax, $
    RESTORE_ONLY=restoreOnly  ; Only perform work necessary for proper restore

    compile_opt idl2, hidden

    if (~(self->_GetImageDimensions(imgDims, IMAGE_DATA=pImgData, $
        N_PLANES=nPlanes, N_DIMENSIONS=nDims))) then begin
        self._oImage->SetProperty, /HIDE
        if (~KEYWORD_SET(restoreOnly)) then $
            self->SetPropertyAttribute, 'HIDE', SENSITIVE=0
        return
    endif

    nPlanes <= 4

    if (~KEYWORD_SET(restoreOnly)) then begin
        oTool = self->GetTool()
        void = oTool->DoUIService("HourGlassCursor", self)
    endif

    ; Initialize the bytescale top and bottom values.
    ; But only if the data is just getting connected, and the
    ; byteScaleMin/Max values have not been explicitly set to valid values
    ; via a previous call to ::SetProperty (as for a property bag playback
    ; during object instantiation).
    ; In this latter case, honor the requested Min/Max.
    bUpdateByteScaleMin = KEYWORD_SET(bUpdateByteScaleMin)
    bUpdateByteScaleMax = KEYWORD_SET(bUpdateByteScaleMax)
    bUpdateBSRange = (bUpdateByteScaleMin || bUpdateByteScaleMax)
    if (self._bHaveImgData) then $
        bUpdateBSRange = 0b ; already have image data - no update.

    if (bUpdateBSRange) then begin
        if (self._isByteData) then begin
            ; For byte data, initialize the bytescale range
            ; to 0...255.
            self._byteScaleMin[0:nPlanes-1] = 0
            self._byteScaleMax[0:nPlanes-1] = 255
        endif else begin
            ; For non-byte data:
            ;
            ;  If a bytescaling data range was explicitly
            ;  provided, then use that range as the
            ;  initial bytescale min and max for all planes.
            if (self._haveBSDataRange) then begin
                if (bUpdateByteScaleMin) then $
                    self._byteScaleMin[0:nPlanes-1] = self._bsDataRange[0]
                if (bUpdateByteScaleMax) then $
                    self._byteScaleMax[0:nPlanes-1] = self._bsDataRange[1]
            endif else begin
                ; Otherwise, initialize the bytescale range
                ; to dataMin...dataMax.
                for i=0,nPlanes-1 do begin
                    minn = MIN(*pImgData[i], MAX=maxx, /NAN)
                    if (bUpdateByteScaleMin) then $
                        self._byteScaleMin[i] = minn
                    if (bUpdateByteScaleMax) then $
                        self._byteScaleMax[i] = maxx
                endfor
            endelse
        endelse
    endif

    ; Check if the image has no data.  If so, un-hide it,
    ; initialize its data, and add any contained ROIs as
    ; observers.
    if (~self._bHaveImgData) then begin
        self._bHaveImgData = 1b
        self._oImage->SetProperty, HIDE=0
    endif

    ; Our new data array.
    data = MAKE_ARRAY(imgDims[0], imgDims[1], nPlanes, $
        TYPE=SIZE(*pImgData[0], /TYPE), /NOZERO)

    ; Copy data from the pointers into our data array.
    for i=0,nPlanes-1 do $
        data[0,0,i] = *pImgData[i]

    ; Bytescale the data.
    if (self->DoApplyByteScale(IMAGE_DATA=pImgData)) then begin

        ; If we have only one plane, or if bytscl mins are all equal
        ; and bytscl maxs are all equal, we don't need to loop.
        ; But, if one of the mins is equal to one of the maxs, then
        ; we can't do the bytscl all at once.
        bmin = self._byteScaleMin[0:nPlanes-1]
        bminSame = ARRAY_EQUAL(bmin, bmin[0])
        bmax = self._byteScaleMax[0:nPlanes-1]
        bmaxSame = ARRAY_EQUAL(bmax, bmax[0])
        minNEmax = ARRAY_EQUAL(bmin ne bmax, 1)

        if (nPlanes eq 1) || (bminSame && bmaxSame && minNEmax) then begin

            ; Note: If data is type byte, min=0, and max=255 then
            ; BYTSCL will return without doing any work, which is nice.
            data = BYTSCL(TEMPORARY(data), /NAN, $
                MIN=self._byteScaleMin[0], MAX=self._byteScaleMax[0])

        endif else begin

            ; Otherwise, loop over each channel.
            for i=0,nPlanes-1 do begin

                ; Handle special case of bytescale min being equal to bytescale max.
                if (self._byteScaleMin[i] eq self._byteScaleMax[i]) then begin
                    if (self._isByteData) then begin
                        ; If byte data, always use 0..255 as allowed data range
                        ; for bytescaling.
                        dmin = 0.0d
                        dmax = 255.0d
                    endif else if (self._haveBSDataRange) then begin
                        ; If provided, retrieve explicitly defined allowed data
                        ; range for bytescaling.
                        dmin = self._bsDataRange[0]
                        dmax = self._bsDataRange[1]
                    endif else begin
                        ; Otherwise, retrieve full data range.
                        dmin = DOUBLE(MIN(*pImgData[i], max=dmax, /NAN))
                        dmax = DOUBLE(dmax)
                    endelse

                    if (dmin ne dmax) then begin
                      ; Set all pixel values to 255 minus proportional location
                      ; of bytescale min/max to data range (mapped to 0 to 255).
                      data[*,*,i] = 255b - BYTE( (((self._byteScaleMin[i] - dmin) / $
                          (dmax-dmin)) * 255.0) + 0.5)
                    endif else begin
                      data[*,*,i] = 0b
                    endelse

                endif else begin
                    ; No special case - just bytescale.

                    data[0,0,i] = BYTSCL(data[*,*,i], /NAN, $
                        MIN=self._byteScaleMin[i], MAX=self._byteScaleMax[i])
                endelse
            endfor
        endelse
    endif

    ; Single-channel images must have a palette.
    ; This will also retrieve the red, green, blue values.
    if (nPlanes eq 1) then $
        self->EnsurePalette, red, green, blue


    ; Map projections. This may modify both the data and nPlanes.
    self->_UpdateMapProjection, data, nPlanes, red, green, blue
    imgDims = (SIZE(data, /DIMENSIONS))[0:1]


    self->_SetSubRect, IMAGE_DATA=pImgData, RESTORE_ONLY=restoreOnly

    data = REFORM(data, imgDims[0]*imgDims[1], nPlanes, /OVERWRITE)
    data = REFORM(TRANSPOSE(data), nPlanes, imgDims[0], imgDims[1])

    ;; Leading dimensions of 1 here can cause IDLgrImage to get confused over
    ;; whether the image is indexed or not.
    data = REFORM(data, /OVERWRITE)

    self._nImagePlanes = nPlanes

    self._oImage->SetProperty, DATA=data, /NO_COPY, $
        INTERLEAVE=0, $
        BLEND_FUNCTION=((self._transparency gt 0) || $
            (nPlanes eq 2) || (nPlanes ge 4) ? [3,4] : [0,0])
end


;;----------------------------------------------------------------------------
;; IDLitVisImage::SetData
;;
;; Purpose:
;;   This function method sets the data of one of the parameters of this
;;   parameter inteface to the data within the given data object.
;;
;;   If the incoming data object is an IDLitDataIDLImage object, then
;;   the image pixels and palette (if any) are passed along to the
;;   corresponding parameters of this image.
;;
;;   Otherwise, the information is passed along to the superclass to
;;   handle.
;;
;;   Parameters:
;;     oData   - The data object being associated with this.
;;
;;   Keywords:
;;     This method accepts all keywords accepted by the superclass.
;;
;;   Return Value
;;       This function returns a 1 on success, or 0 otherwise.
;;
function IDLitVisImage::SetData, oData, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~OBJ_VALID(oData)) then $
        return, 0

    if (OBJ_ISA(oData, 'IDLitDataIDLImage')) then begin

        oChild = oData->Get(/ALL, COUNT=nChild)

        ; Set the palette first (if there is one), so that we don't
        ; create an unnecessary grayscale one.
        index = (WHERE(OBJ_ISA(oChild, 'IDLitDataIDLPalette')))[0]
        if (index ne -1) then $
            self->SetParameter, 'PALETTE', oChild[index], _EXTRA=_extra

        ; Now set the image.
        index = (WHERE(OBJ_ISA(oChild, 'IDLitDataIDLImagePixels')))[0]
        if (index ne -1) then $
            self->SetParameter, 'IMAGEPIXELS', oChild[index], _EXTRA=_extra

        return, 1

    endif

    return, self->IDLitVisualization::SetData(oData, _EXTRA=_extra)

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisImage::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisImage::]OnDataRangeChange, oSubject, $
;          XRange, YRange, ZRange
;
; INPUTS:
;      oSubject:  A reference to the object sending notification
;                 of the data range change.
;      XRange:    The new xrange, [xmin, xmax].
;      YRange:    The new yrange, [ymin, ymax].
;      ZRange:    The new zrange, [zmin, zmax].
;
;-
pro IDLitVisImage::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    self->_SetSubRect, XRange, YRange

    ; Call superclass.
    self->_IDLitVisualization::OnDataRangeChange, oSubject, $
        XRange, YRange, ZRange
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisImage::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrImage object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisImage::]OnDataChangeUpdate, oSubject
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the image) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then, it puts the data in the IDLgrImage object.
;
; KEYWORD PARAMETERS:
;    NO_SUBRECT_UPDATE:    Set this keyword to a non-zero value to indicate
;      that the sub-image rectangle associated with this image should
;      not be updated.
;      [This keyword is provided primarily so that when the parameter set
;       is updated, it can call ::OnDataChange for each of the contained
;       data items without updating the sub-image rectangle on each call.]
;
;-
pro IDLitVisImage::OnDataChangeUpdate, oSubject, parmName, $
    NO_SUBRECT_UPDATE=noSubRectUpdate, $
    NO_GRID_UPDATE=noGridUpdate

    compile_opt idl2, hidden

    case STRUPCASE(parmName) of
    '<PARAMETER SET>': begin
        oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
        iImage = -1
        for i=0,nParam-1 do begin
            if (STRLEN(paramNames[i]) gt 0) then begin
                oData = oSubject->GetByName(paramNames[i])
                if (OBJ_VALID(oData) ne 0) then begin
                    ; Temporarily skip the image.  It will be
                    ; updated last.
                    if (paramNames[i] eq 'IMAGEPIXELS') then begin
                        iImage = i
                        oImgData = oData
                    endif else $
                        self->IDLitVisImage::OnDataChangeUpdate, $
                            oData, paramNames[i], $
                            /NO_SUBRECT_UPDATE, $
                            /NO_GRID_UPDATE
                endif

            endif
        endfor

        if (iImage ge 0) then begin
            ; The grid will be updated with the image.
            self->IDLitVisImage::OnDataChangeUpdate, $
                oImgData, paramNames[iImage]
        endif
    end

    'IMAGEPIXELS': begin
        types = oSubject->GetTypes()
        ;; Is this an image?
        dex = where(types eq "IDLIMAGEPIXELS", nImage)
        dex = where(types eq "IDLARRAY2D", nArray)


        ; Get pointer to the data.
        if (nImage gt 0) then begin
          status = oSubject->GetData(pData, /POINTER)
          if (ARG_PRESENT(imageIsArray)) then $
              imageIsArray = 0
        endif else if (nArray gt 0) then begin
          status = oSubject->GetData(pData, /POINTER)
          if (ARG_PRESENT(imageIsArray)) then $
              imageIsArray = 1
        endif else begin
          status = 0
          if (ARG_PRESENT(imageIsArray)) then $
              imageIsArray = 0
        endelse
        if(status eq 0 or n_elements(pData) eq 0)then begin
           self->ErrorMessage, $
             IDLitLangCatQuery('Error:Framework:InvalidDataType'), $
             SEVERITY=1
           return
        endif

        ; Update the grid.
        self->_IDLitVisGrid2D::OnDataChangeUpdate

        ; Notify ROIs of change.
        self->_UpdateRegionPixels

        ; Set a flag indicating if data is type BYTE.
        self._isByteData = (SIZE(*pData[0], /TYPE) eq 1)

        self._bHaveImgData = 0b

        self->_UpdateImageData, /UPDATE_BYTSCL_MIN, /UPDATE_BYTSCL_MAX

        ; Notify any observers that the image data has changed.
        ; A typical observer would be the image panel menu which may
        ; need to update information about the image.
        self->DoOnNotify, self->GetFullIdentifier(), 'IMAGECHANGED', 0
    end ;; Image parameter

    'PALETTE': begin
        success = oSubject->GetData(palette)
        if (success and N_ELEMENTS(palette) gt 0) then begin
            self._oCurrPal->SetProperty, RED=palette[0,*], $
                GREEN=palette[1,*],  BLUE=palette[2,*], $
                NAME="Image palette"
            self._oImage->SetProperty, PALETTE=self._oCurrPal
            self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=1
        endif else begin
            self._oImage->SetProperty, PALETTE=OBJ_NEW()
            self._oCurrPal->SetProperty, NAME="No Palette"
            self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=0
        endelse

        ; If we are transparent or we have a map projection,
        ; then we need to convert from palettized to RGBA.
        if (self._transparency || self._hasMapProjection) then $
            self->_UpdateImageData

    end ;; Palette parameter

    'X': begin

        ; Unless flagged not to, update the grid.
        if (~KEYWORD_SET(noGridUpdate)) then $
            self->_IDLitVisGrid2D::OnDataChangeUpdate

        ; Unless flagged not to, reset sub-rectangle according to
        ; dataspace range.
        if (~KEYWORD_SET(noSubRectUpdate)) then $
            self->_SetSubRect

        end ;; X parameter

    'Y': begin

        ; Unless flagged not to, update the grid.
        if (~KEYWORD_SET(noGridUpdate)) then $
            self->_IDLitVisGrid2D::OnDataChangeUpdate

        ; Unless flagged not to, reset sub-rectangle according to
        ; dataspace range.
        if (~KEYWORD_SET(noSubRectUpdate)) then $
            self->_SetSubRect

        end ;; Y parameter

    ELSE:
    endcase
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::OnWorldDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImage::]OnWorldDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro IDLitVisImage::OnWorldDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    ; If the world changes to 3D, the isotropic setting is
    ; not as relevant.  Turn it off in this case so that if
    ; it gets added to a 3D world (that is not isotropic), the
    ; scaling remains consistent.
    ; In a 2D world, ideally isotropic scaling is utilized.
    self->IDLitVisualization::SetProperty, ISOTROPIC=~is3D

    ; For 2D images we want depth offset = zero, so that the image
    ; honors its order in the container (so Bring to Front works).
    ; For 3D we want depth offset = 1, so that contours and ROI's
    ; won't be stitched if they are lying on top. Unfortunately,
    ; that means that in 3D the container order won't work correctly,
    ; and the image will always be on the bottom.
    self._oImage->SetProperty, DEPTH_OFFSET=is3D ? 1 : 0

    if (is3D ne self._bWorldIs3D) then begin
        oldStatus = self->QueryPixelScaleStatus()

        self._bWorldIs3D = is3D

        ; Broadcast notification of pixel scale status change to
        ; any interested parties.
        newStatus = self->QueryPixelScaleStatus()
        if (newStatus ne oldStatus) then $
            self->DoOnNotify, self->GetFullIdentifier(), $
                'PIXEL_SCALE_STATUS', newStatus
    endif

    ; Call superclass.
    self->_IDLitVisualization::OnWorldDimensionChange, oSubject, is3D
end


;----------------------------------------------------------------------------
pro IDLitVisImage::OnProjectionChange, sMap

    compile_opt idl2, hidden

    self->_UpdateImageData

    ; Update the dataspace.
    oDataSpace = self->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace) && $
        oDataSpace->GetXYZRange(xRange, yRange, zRange, $
            /NO_TRANSFORM)) then begin

        ; Update the dataspace ranges.
        oDataSpace->OnDataRangeChange, oDataSpace, $
            xRange, yRange, zRange, /DATA_UPDATE

    endif

end


;----------------------------------------------------------------------------
; IDLitVisImage::EnsurePalette
;
; Purpose:
;   This procedure method verifies that valid palette parameter is
;   associated with this image.  If not, it creates one.
;
;   This method is only intended to be called if the image is a
;   single-channel image.
;
pro IDLitVisImage::EnsurePalette, red, green, blue
    compile_opt idl2, hidden

    oPalette = self->IDLitParameter::GetParameter('PALETTE')
    ; Do we have a valid palette?
    if (OBJ_VALID(oPalette) && oPalette->GetData(palette)) then begin
        if (ARG_PRESENT(red)) then begin
            red = REFORM(palette[0,*])
            green = REFORM(palette[1,*])
            blue = REFORM(palette[2,*])
        endif
        return
    endif

    ;; if no palette exists, create a gray scale palette
    red = BINDGEN(256)
    green = red
    blue = red
    oGrayPalette = OBJ_NEW('IDLitDataIDLPalette', $
                           TRANSPOSE([[red],[green],[blue]]), $
                           NAME='Palette')
    oGrayPalette->SetProperty,/AUTO_DELETE
    success = self->IDLitParameter::SetData(oGrayPalette, $
        PARAMETER_NAME='PALETTE', /NO_UPDATE)
    ;; Send a notification message to update UI
    self->DoOnNotify, self->GetFullIdentifier(),"ADDITEMS", ''

    oPalette = self->GetParameter('PALETTE')

    ;; add to the same container in which the image pixels are
    ;; contained
    oImagePixels = self->GetParameter('IMAGEPIXELS')
    IF obj_valid(oImagePixels) THEN BEGIN
      oImagePixels->GetProperty,_PARENT=oParent

      ; Note: the palette should not be added to an IDLitDataIDLImagePixels
      ; object.  Keep walking up the tree.
      if (OBJ_ISA(oParent, 'IDLitDataIDLImagePixels')) then begin
          oImagePixels = oParent
          oImagePixels->GetProperty,_PARENT=oParent
      endif
      IF obj_valid(oParent) THEN BEGIN
        oParent->Add,oPalette
        ;; check to see if we need to mangle the name
        ;; Get our base name and append the id number.
        oPalette->IDLitComponent::GetProperty, IDENTIFIER=id, NAME=name
        ;; See if we have an id number at the end of our identifier.
        idnum = (STRSPLIT(id, '_', /EXTRACT, COUNT=count))[count>1 - 1]
        ;; Append the id number.
        IF (STRMATCH(idnum, '[0-9]*')) THEN BEGIN
          name += ' ' + idnum
          ;; set new name
          oPalette->IDLitComponent::SetProperty, NAME=name
          oTool = self->GetTool()
          oTool->DoOnNotify,oPalette->GetFullIdentifier(),'SETPROPERTY','NAME'
        ENDIF
      ENDIF ELSE BEGIN
        self->AddByIdentifier,'/DATA MANAGER',oPalette
      ENDELSE
    ENDIF

    self->SetPropertyAttribute, 'VISUALIZATION_PALETTE', SENSITIVE=1
end

;----------------------------------------------------------------------------
; IDLitVisImage::GetParameter
;
; Purpose:
;   This function method retrieves the requested paramter(s).
;
;   Note: this overrides the implementation in the IDLitParameter
;   superclass.  This allows the image to ensure its palette is valid
;   before parameters are retrieved.
;
function IDLitVisImage::GetParameter, ParamName, $
    ALL=all, $
    OPTARGETS=opTargets, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (KEYWORD_SET(all) || $
        KEYWORD_SET(opTargets) || $
        (STRUPCASE(ParamName) eq "PALETTE")) then begin
        ; Ensure that single-channel images have a palette.
        oImagePixels = self->IDLitParameter::GetParameter("IMAGEPIXELS")
        if (OBJ_VALID(oImagePixels)) then begin
            if (oImagePixels->GetData(pImgData, /POINTER)) then begin
                nPlanes = N_ELEMENTS(pImgData) < 4
                if (nPlanes eq 1) then $
                    self->EnsurePalette
            endif
        endif
    endif

    return, (N_ELEMENTS(ParamName) gt 0) ? $
        self->IDLitParameter::GetParameter(ParamName, $
            ALL=all, OPTARGETS=opTargets, _EXTRA=_extra) : $
        self->IDLitParameter::GetParameter( $
            ALL=all, OPTARGETS=opTargets, _EXTRA=_extra)
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::QueryPixelScaleStatus()
;
; PURPOSE:
;   This function method reports whether it is a good candidate
;   for a pixel scale operation.
;
;   An image is considered a good candidate if:
;     - it has not been rotated
;     - it's parent "world" has not been rotated
;     - it is contained within a 2D dataspace.
;
; CALLING SEQUENCE:
;   Result = Obj->[IDLitVisImage::]QueryPixelScaleStatus()
;
; OUTPUTS:
;   This function method returns:
;     0 if this image is not a good candidate for pixel scaling
;     1 if this image is a good candidate for pixel scaling
;    -1 if this image is currently not a good candidate for
;       pixel scaling, but this status could change by simply
;       resetting the transform of the dataspace root to identity.
;-
function IDLitVisImage::QueryPixelScaleStatus

    compile_opt idl2, hidden

    if (~OBJ_VALID(self.parent)) then $
        return, 0

    if (self._bWorldIs3D) then $
        return, 0

    if (self._bSelfRotated) then $
        return, 0

    if (self._bWorldRotated) then $
        return, 0

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::On2DRotate
;
; PURPOSE:
;   This procedure method handles notification that a parent
;   dataspace's rotation status has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImage::]On2DRotate, Subject, isRotated
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the rotation change.
;   isRotated: new flag indicating whether the subject is rotated or not.
;-
pro IDLitVisImage::On2DRotate, oSubject, isRotated, $
    NO_NOTIFY=noNotify

    compile_opt idl2, hidden

    if (isRotated ne self._bWorldRotated) then begin
        oldStatus = self->QueryPixelScaleStatus()

        self._bWorldRotated = isRotated

        if (~KEYWORD_SET(noNotify)) then begin
            ; Broadcast notification of pixel scale status change to
            ; any interested parties.
            newStatus = self->QueryPixelScaleStatus()
            if (newStatus ne oldStatus) then $
                self->DoOnNotify, self->GetFullIdentifier(), $
                    'PIXEL_SCALE_STATUS', newStatus
        endif
    endif

    ; Call superclass.
    self->_IDLitVisualization::On2DRotate, oSubject, isRotated, $
        NO_NOTIFY=noNotify
end


;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisImage::GetDataString, xyz
    compile_opt idl2, hidden

    x = xyz[0]
    y = xyz[1]

    if ((x lt self._clipDataX[0]) || (x gt self._clipDataX[1]) || $
        (y lt self._clipDataY[0]) || (y gt self._clipDataY[1])) then $
        return, ''

    ; Notify any observers that someone is probing us.
    ; This is usually the image panel, and will probably
    ; call right back into our GetExtendedDataStrings method below.
    self->DoOnNotify, self->GetFullIdentifier(), $
        'IMAGEPROBE', [x,y]

    xyLoc = [x, y]

    ; gridUnits=1 is meters, 2 is degrees
    self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    if (self._hasMapProjection) then begin

        ; If we have a map projection, then xyLoc is already in meters, and
        ; needs to be converted back to degrees.
        mapStruct = self->GetProjection()
        lonlat = MAP_PROJ_INVERSE(xyLoc[0], xyLoc[1], $
            MAP_STRUCTURE=mapStruct)
        ; Longitude & latitude.
        loc0 = self->_DegToDMS(lonlat[0], 0, gridUnits)
        loc1 = self->_DegToDMS(lonlat[1], 1, gridUnits)
;        mapLocation = [loc0, loc1]
;        ; X and Y location.
;        loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
;        loc0 = '     (' + loc0 + ' m' + ')'
;        loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
;        loc1 = '     (' + loc1 + ' m' + ')'
;        mapLocation = [mapLocation, loc0, loc1]

    endif else begin

        ; If we don't have a map projection, then xyLoc is in either
        ; degrees or meters or none.

        if (gridUnits eq 2) then begin
            ; Longitude & latitude.
            loc0 = self->_DegToDMS(xyLoc[0], 0, gridUnits)
            loc1 = self->_DegToDMS(xyLoc[1], 1, gridUnits)
        endif else begin
            ; X and Y location.
            loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
            loc0 = 'X: ' + loc0
            loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
            loc1 = 'Y: ' + loc1
            if (gridUnits eq 1) then begin
                loc0 += ' m'
                loc1 += ' m'
            endif
        endelse

    endelse

    value = loc0 + '  ' + loc1
    return, value
end


;---------------------------------------------------------------------------
; Convert a location from decimal degrees to DDDdMM'SS", where "d" is
; the degrees symbol.
;
function IDLitVisImage::_DegToDMS, x, isLat, gridUnits

    compile_opt idl2, hidden

    if (~FINITE(x)) then $
        return, '---'

    eps = 1d-9
    x = (x ge 0) ? x + eps : x - eps
    degrees = ABS(FIX(x))
    minutes = FIX((ABS(x) - degrees)*60)
    seconds = (ABS(x) - degrees - minutes/60d)*3600

    dms = STRING(degrees, FORMAT='(I4)') + STRING(176b) + $
        STRING(minutes, FORMAT='(I2.2)') + "'" + $
        STRING(seconds, FORMAT='(I2.2)')

    ; If grid spacing is less than 10 arcseconds (~280 meters),
    ; then also output the fractional arcseconds.
    eps = (gridUnits eq 2) ? 0.0028 : 280
    if (MIN(self._userStep) lt eps) then $
      dms += STRMID(STRING(seconds mod 1, FORMAT='(f4.2)'),1)

    dms += '"' + (isLat ? (x lt 0 ? 'S' : 'N') : (x lt 0 ? 'W' : 'E'))

    return, dms

end


;---------------------------------------------------------------------------
; Retrieve extended data information strings (computed in the
;   most recent IDLitVisImage::GetDataString call).
;
; xyLoc should contain the [x,y] as computed by GetDataString.
;
pro IDLitVisImage::GetExtendedDataStrings, xyLoc, $
    MAP_LOCATION=mapLocation, $
    PROBE_LOCATION=probeLocation, $
    PIXEL_VALUES=pixelValues

    compile_opt idl2, hidden

    probeLocation = ''
    pixelValues = ''

    self->GeometryToGrid, xyLoc[0], xyLoc[1], ix, iy
    if (ix lt 0) then $
        return

    ; Map location:
    if (ARG_PRESENT(mapLocation)) then begin

        ; gridUnits=1 is meters, 2 is degrees
        self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

        if (self._hasMapProjection) then begin

            ; If we have a map projection, then xyLoc is already in meters, and
            ; needs to be converted back to degrees.
            mapStruct = self->GetProjection()
            lonlat = MAP_PROJ_INVERSE(xyLoc[0], xyLoc[1], $
                MAP_STRUCTURE=mapStruct)
            ; Longitude & latitude.
            loc0 = 'Lon: ' + self->_DegToDMS(lonlat[0], 0, gridUnits)
            loc1 = 'Lat: ' + self->_DegToDMS(lonlat[1], 1, gridUnits)
            mapLocation = [loc0, loc1]
            ; X and Y location.
            loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
            loc0 = '     (' + loc0 + ' m' + ')'
            loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
            loc1 = '     (' + loc1 + ' m' + ')'
            mapLocation = [mapLocation, loc0, loc1]

        endif else begin

            ; If we don't have a map projection, then xyLoc is in either
            ; degrees or meters.

            if (gridUnits eq 2) then begin
                ; Longitude & latitude.
                loc0 = 'Lon: ' + self->_DegToDMS(xyLoc[0], 0, gridUnits)
                loc1 = 'Lat: ' + self->_DegToDMS(xyLoc[1], 1, gridUnits)
            endif else begin
                ; X and Y location.
                loc0 = STRTRIM(STRING(xyLoc[0],FORMAT='(g0.8)'),2)
                loc0 = 'X: ' + loc0
                loc1 = STRTRIM(STRING(xyLoc[1],FORMAT='(g0.8)'),2)
                loc1 = 'Y: ' + loc1
                if (gridUnits eq 1) then begin
                    loc0 += ' m'
                    loc1 += ' m'
                endif
            endelse

            ; Since we don't have a map projection, append null strings.
            mapLocation = [loc0, loc1, '', '']

        endelse
    endif


    ; Probe location:
    if (ARG_PRESENT(probeLocation)) then begin
        probeLocation = '['+   STRTRIM(STRING(ix),2) + $
                 ', ' + STRTRIM(STRING(iy),2) + $
                 ']'
    endif

    if (~ARG_PRESENT(pixelValues)) then $
        return

    ; Pixel values:
    if (~(self->_GetImageDimensions(imgDims, IMAGE_DATA=pImgData, $
        N_PLANES=nPlanes))) then $
        return

    nPlanes <= 4

    ; Clamp to grid.
    gx = (ULONG(ix + 0.5) > 0) < (imgDims[0]-1)
    gy = (ULONG(iy + 0.5) > 0) < (imgDims[1]-1)

    ; Retrieve data values at that location.
    dataValues = MAKE_ARRAY(nPlanes, TYPE=SIZE(*pImgData[0], /TYPE))
    for i=0,nPlanes-1 do $
        dataValues[i] = (*pImgData[i])[gx,gy]

    ; Construct appropriate value strings.
    switch nPlanes of

        2: pixelValues = 'A: ' + STRTRIM(STRING(dataValues[1], /PRINT), 2)
            ; Fall thru...

        1: begin
            gray = STRTRIM(STRING(dataValues[0], /PRINT), 2)
            pixelValues = (pixelValues[0] ne '') ? $
                [gray, pixelValues] : gray
            break
           end

        4: pixelValues = "A: " + STRTRIM(STRING(dataValues[3], /PRINT), 2)
            ; Fall thru...

        3: begin
            rStr = "R: " + STRTRIM(STRING(dataValues[0], /PRINT), 2)
            gStr = "G: " + STRTRIM(STRING(dataValues[1], /PRINT), 2)
            bStr = "B: " + STRTRIM(STRING(dataValues[2], /PRINT), 2)
            pixelValues = (pixelValues[0] ne '') ? $
                [rStr, gStr, bStr, pixelValues] : [rStr, gStr, bStr]
            break
           end

        else:
    endswitch

    ; Add strings for the bytescaled values if necessary.
    if (self->DoApplyByteScale(IMAGE_DATA=pImgData)) then begin
        for i=0,nPlanes-1 do begin
            byteData = BYTSCL(dataValues[i], /NAN, $
                MIN=self._byteScaleMin[0], MAX=self._byteScaleMax[0])
            pixelValues[i] += ' (' + $
                STRTRIM(STRING(byteData, /PRINT), 2) + ')'
        endfor
    endif


end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImage::GetXYZRange
;
; PURPOSE:
;   This function method overrides the _IDLitVisualization::GetXYZRange
;   function so that the /DATA keyword is handled properly for
;   images.
;
; CALLING SEQUENCE:
;   Success = Obj->[IDLitVisImage::]GetXYZRange( $
;    xRange, yRange, zRange [, /DATA] [, /NO_TRANSFORM])
;
; INPUTS:
;   xRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [xmin, xmax], representing the
;     X range of the objects that impact the ranges.
;   yRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [ymin, ymax], representing the
;     Y range of the objects that impact the ranges.
;   zRange:   Set this argument to a named variable that upon return
;     will contain a two-element vector, [zmin, zmax], representing the
;     Z range of the objects that impact the ranges.
;
; KEYWORD PARAMETERS:
;    DATA:  Set this keyword to a nonzero value to indicate that
;     the ranges should be computed for the full datasets of the
;     contents of this visualization.  By default (if the keyword is
;     not set), the ranges are computed for the visualized portions
;     of the data sets.
;    NO_TRANSFORM:  Set this keyword to indicate that this Visualization's
;     model transform should not be applied when computing the XYZ ranges.
;     By default, the transform is applied.
;
; OUTPUTS:
;   This function returns a 1 if retrieval of the XYZ ranges was
;   successful, or 0 otherwise.
;-
function IDLitVisImage::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=bDataRange, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    ; Default return values.
    outxRange = [0.0d, 0.0d]
    outyRange = [0.0d, 0.0d]
    outzRange = [0.0d, 0.0d]

    ; Grab the transformation matrix.
    if (not KEYWORD_SET(noTransform)) then $
        self->IDLgrModel::GetProperty, TRANSFORM=transform

    if (KEYWORD_SET(bDataRange)) then begin

        xMin = self._gridOrigin[0]
        xMax = xMin + (self._gridStep[0] * self._gridDims[0])

        yMin = self._gridOrigin[1]
        yMax = yMin + (self._gridStep[1] * self._gridDims[1])

        xrange = [xmin, xmax]
        yrange = [ymin, ymax]
        zrange = [0.0, 0.0]
    endif else begin
        self._oImage->GetProperty, XRANGE=xrange, YRANGE=yrange, $
            ZRANGE=zrange
    endelse

    ; Allow superclass to apply the transform.
    self->_IDLitVisualization::_AccumulateXYZRange, 0, $
        outxRange, outyRange, outzRange, $
        xRange, yRange, zRange, TRANSFORM=transform

    return, 1
end


;---------------------------------------------------------------------------
; Retrieve the Projection object from myself.
;
function IDLitVisImage::_GetMapProjection

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oMapProj)) then begin
        self._oMapProj = OBJ_NEW('IDLitVisMapProjection')
        self._oMapProj->SetPropertyAttribute, $
            ['LONGITUDE_MIN', 'LONGITUDE_MAX', $
            'LATITUDE_MIN', 'LATITUDE_MAX'], /HIDE
        self->Add, self._oMapProj
    endif

    return, self._oMapProj

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This function method retrieves the LonLat range of
;   contained visualizations. Override the _Visualization method
;   so we can retrieve the correct range.
;
function IDLitVisImage::GetLonLatRange, lonRange, latRange, $
    MAP_STRUCTURE=sMap

    compile_opt idl2, hidden

    self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    ; No units, failure.
    if (gridUnits ne 1 && gridUnits ne 2) then $
        return, 0

    ; Units in degrees.
    if (gridUnits eq 2) then begin

        lonMin = self._userOrigin[0]
        lonMax = lonMin + (self._userStep[0] * self._userDims[0])

        latMin = self._userOrigin[1]
        latMax = latMin + (self._userStep[1] * self._userDims[1])

        lonRange = [lonMin, lonMax]
        latRange = [latMin, latMax]

        return, 1
    endif

    ; Units must be in meters.

    if (N_TAGS(sMap) eq 0) then begin
        sMap = self->GetProjection()
    endif

    ; If our dataspace is actually in meters, failure.
    if (N_TAGS(sMap) eq 0) then $
        return, 0

    self._oImage->GetProperty, XRANGE=xrange, YRANGE=yrange

    ; If the dataspace has a map projection,
    ; then convert the four corners back to degrees.
    ; Note that we don't care what our image map projection is, just
    ; the dataspace, since that determines the U/V extent.
    lonlat = MAP_PROJ_INVERSE(xrange[[0,1,1,0]], yrange[[0,0,1,1]], $
        MAP_STRUCTURE=sMap)

    minn = MIN(lonlat, DIMENSION=2, MAX=maxx)
    lonRange = [minn[0], maxx[0]]
    latRange = [minn[1], maxx[1]]

    return, 1

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This function method converts from coordinates in the dataspace,
;   back to image units, taking into consideration any map projections.
;   If the dataspace has a map projection and the image units are degrees,
;   then the result will be in degrees.
;   If the dataspace has a map projection and the image units are in meters
;   then the inputs will be converted first from the dataspace U/V, into
;   degrees, then into the image U/V.
;
;   Arguments:
;   xDS, yDS: Arrays containing the X and Y coordinates in
;       dataspace units. If the dataspace has a map projection then these
;       are assumed to be in meters. If not, then these are assumed
;       to be in degrees (or no units).
;
;   Result is a 2xN array.
;
function IDLitVisImage::DataspaceToVis, xDS, yDS

    compile_opt idl2, hidden

    ; Retrieve dataspace map projection.
    sMapDataspace = self._hasMapProjection ? self->GetProjection() : 0
    sMapSelf = OBJ_VALID(self._oMapProj) ? $
        self._oMapProj->_GetMapStructure() : 0

    ; gridUnits=1 is meters, 2 is degrees
    self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    ; Sanity check. Don't use our map projection if not in meters.
    if (gridUnits ne 1) then $
        sMapSelf = 0

    hasMapDataspace = N_TAGS(sMapDataspace) gt 0
    hasMapSelf = N_TAGS(sMapSelf) gt 0

    n = N_ELEMENTS(xDS)
    xy = [REFORM(xDS, 1, n), REFORM(yDS, 1, n)]

    ; Convert first from dataspace U/V into lon/lat.
    if (hasMapDataspace) then begin

        ; See if our image projection matches the map projection.
        ; If so, then we can bail early.
        if (hasMapSelf && $
            (sMapDataspace.up_name eq sMapSelf.up_name && $
            ARRAY_EQUAL(sMapDataspace.p, sMapSelf.p))) then begin
            return, xy
        endif

        ; Convert from U/V back to Lon/Lat.
        lonlat = MAP_PROJ_INVERSE(TEMPORARY(xy), $
            MAP_STRUCTURE=sMapDataspace)

    endif else begin

        ; Dataspace has no projection, assume already in lonlat.
        lonlat = TEMPORARY(xy)

    endelse

    ; If image has its own map projection, convert from
    ; lonlat to image U/V.
    if (hasMapSelf) then begin
        uv = MAP_PROJ_FORWARD(lonlat, MAP_STRUCTURE=sMapSelf)
        return, uv
    endif

    return, lonlat

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This function method converts from coordinates in the image,
;   to dataspace units, taking into consideration any map projections.
;   If the dataspace has a map projection and the image units are degrees,
;   then the result will be converted into the dataspace U/V.
;   If the dataspace has a map projection and the image units are in meters
;   then the inputs will be converted first from the image U/V, into
;   degrees, then into the dataspace U/V.
;
;   Arguments:
;   xVis, yVis: Arrays containing the X and Y coordinates in
;       image units. If the image has a map projection then these
;       are assumed to be in meters. If not, then these are assumed
;       to be in degrees (or no units).
;
;   Result is a 2xN array.
;
function IDLitVisImage::VisToDataspace, xVis, yVis

    compile_opt idl2, hidden

    ; Retrieve dataspace map projection.
    sMapDataspace = self._hasMapProjection ? self->GetProjection() : 0
    sMapSelf = OBJ_VALID(self._oMapProj) ? $
        self._oMapProj->_GetMapStructure() : 0

    ; gridUnits=1 is meters, 2 is degrees
    self->_IDLitVisGrid2D::GetProperty, GRID_UNITS=gridUnits

    ; Sanity check. Don't use our map projection if not in meters.
    if (gridUnits ne 1) then $
        sMapSelf = 0

    hasMapDataspace = N_TAGS(sMapDataspace) gt 0
    hasMapSelf = N_TAGS(sMapSelf) gt 0

    n = N_ELEMENTS(xVis)
    xy = [REFORM(xVis, 1, n), REFORM(yVis, 1, n)]

    ; Convert first from image U/V into lon/lat.
    if (hasMapSelf) then begin

        ; See if our image projection matches the map projection.
        ; If so, then we can bail early.
        if (hasMapDataspace && $
            (sMapDataspace.up_name eq sMapSelf.up_name && $
            ARRAY_EQUAL(sMapDataspace.p, sMapSelf.p))) then begin
            return, xy
        endif

        ; Convert from U/V back to Lon/Lat.
        lonlat = MAP_PROJ_INVERSE(TEMPORARY(xy), $
            MAP_STRUCTURE=sMapSelf)

    endif else begin

        ; Image has no projection, assume already in lonlat.
        lonlat = TEMPORARY(xy)

    endelse

    ; If dataspace has its own map projection, convert from
    ; lonlat to dataspace U/V.
    if (hasMapDataspace) then begin
        uv = MAP_PROJ_FORWARD(lonlat, MAP_STRUCTURE=sMapDataspace)
        return, uv
    endif

    return, lonlat

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisImage__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisImage object.
;
;-
pro IDLitVisImage__Define

    compile_opt idl2, hidden

    struct = { IDLitVisImage,        $
        inherits IDLitVisualization, $   ; Superclass
        inherits _IDLitVisGrid2D,    $   ; Superclass
        _transparency: 0b,           $   ; transparency percent (0-100)
        _isByteData: 0b,             $   ; Flag: is data of type byte?
        _nImagePlanes: 0b,           $   ; Number of planes within grImage
        _haveBSDataRange: 0b,        $   ; Flag: has the bytescale data
                                     $   ;  range been explicitly set?
        _hasMapProjection: 0b,       $   ; dataspace map projection?
        _oMapProj: OBJ_NEW(),        $   ; my map proj object
        _BSDataRange: DBLARR(2),     $   ; If set: the min and max data
                                     $   ;  range within which the bytescale
                                     $   ;  min and max values must fall.
        _byteScaleMin: DBLARR(4),    $   ; min data value for bytscale
                                     $   ;  per plane
        _byteScaleMax: DBLARR(4),    $   ; max data value for bytscale
                                     $   ;  per plane
        _bWorldIs3D: 0b,             $   ; Flag: is world 3d?
        _bSelfRotated: 0b,           $   ; Flag: does the current transform
                                     $   ;  require 3D?
        _bWorldRotated: 0b,          $   ; Flag: has the parent world
                                     $   ;  been rotated?
        _oImage: OBJ_NEW(),          $   ; IDLgrImage object
        _oCurrPal: OBJ_NEW(),        $   ; IDLgrPalette object
        _bHaveImgData: 0b,           $   ; Flag: is image data connected?
        _clipDataX: DBLARR(2),       $   ; Sub-image data coordinates [Xmin, Xmax]
        _clipDataY: DBLARR(2),       $   ; Sub-image data coordinates [Ymin, Ymax]
        _zValue: 0d                  $   ; Z value when in 3D space
    }

end
