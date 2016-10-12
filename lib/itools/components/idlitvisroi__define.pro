; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisroi__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisROI
;
; PURPOSE:
;    The IDLitVisROI class is the component wrapper for IDLgrROI
;
;-

;----------------------------------------------------------------------------
; IDLitVisROI::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisROI::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisROI::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Aggregate ROI properties.
        self->Aggregate, self._oROI

        ; For styles, hide this property until we have data.
        ; We always want it to be insensitive.
        self->RegisterProperty, 'N_VERTS', $
            DESCRIPTION='Number of vertices', /ADVANCED_ONLY, $
            NAME='Number of vertices', /INTEGER, SENSITIVE=0, /HIDE
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of ROI', $
            VALID_RANGE=[0,100,5]

        ; Needs to be registered for Undo/Redo to work for manipulators
        ; acting on this ROI.
        self->RegisterProperty, '_VERTICES', USERDEF='', /HIDE, $
            NAME='Vertices', DESCRIPTION='Vertices', /ADVANCED_ONLY

        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY
    endif
end

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisROI::Init
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
;   Obj = OBJ_NEW('IDLitVisROI')
;
;    or
;
;   Obj->[IDLitVisROI::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.  In addition, the following
;   keywords are supported:
;
;   ROI_TYPE (Get):  Set this keyword to indicate the type of the
;   region.  Valid values include:
;       0 = points
;       1 = path
;       2 = closed polygon (the default)
;
;     [Note: this keyword is a wrapper for the TYPE property of
;      the contained IDLgrROI.  The intent is to avoid any conflict
;      with the TYPE property of an _IDLitVisualization.]
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;-
function IDLitVisROI::Init, $
    POINTS_NEEDED=inPointsNeeded, $
    ROI_TYPE=roiType, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    if (self->IDLitVisualization::Init(NAME="ROI", $
        TYPE='IDLROI', $
        /MANIPULATOR_TARGET, $
        IMPACTS_RANGE=0, $
        ICON='freeform', $
        DESCRIPTION="A Region of Interest", $
        _EXTRA=_extra) ne 1) then $
        return, 0

    ; Note: this will register the VERTICES parameter.
    pointsNeeded = (N_ELEMENTS(inPointsNeeded) ne 0) ? inPointsNeeded : 2
    if (self->_IDLitVisVertex::Init( $
        POINTS_NEEDED=pointsNeeded) ne 1) then begin
        self->Cleanup
        return, 0
    endif

    ; Change description of the 'VERTICES' parameter.
    self->SetParameterAttribute, 'VERTICES', DESCRIPTION='ROI Vertices'


    ; Create ROI object and add it to this visualization.
    ; NOTE: the IDLgrROI properties will be aggregated as part of
    ; the property registration process in an upcoming call to
    ; ::_RegisterProperties.
    self._oROI = OBJ_NEW('IDLgrROI', /REGISTER_PROPERTIES, $
        /PRIVATE, /DOUBLE, TYPE=roiType, COLOR=[255,0,0])
    if (OBJ_VALID(self._oROI) eq 0) then begin
         self->Cleanup
         return, 0
    endif
    self->Add, self._oROI

    self._bDisablePixelUpdate = 0b

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    ; Register all properties.
    self->IDLitVisROI::_RegisterProperties

    ; Raise the ROI off the image plane slightly.
;   self->IDLgrModel::Translate, 0, 0, 0.1

    ; Create selection visuals, and set the default.
    self._oSelectionVisual2D = OBJ_NEW('IDLitManipVisScale2D', $
        /HIDE, /NO_PADDING)
    if (OBJ_VALID(self._oSelectionVisual2D) eq 0) then begin
         self->Cleanup
         return, 0
    endif
    self._oSelectionVisual3D = OBJ_NEW('IDLitManipulatorVisual', /HIDE, $
        /NO_TRANSFORM, TYPE='Selection')
    if (OBJ_VALID(self._oSelectionVisual3D) eq 0) then begin
         self->Cleanup
         return, 0
    endif
    self._oSelectionVisual3D->Add, OBJ_NEW('IDLgrROI', $
        COLOR=[0,255,255], /DOUBLE, LINESTYLE=[1,'F0F0'X])
    self->SetDefaultSelectionVisual, self._oSelectionVisual2D

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisROI::SetProperty, _EXTRA=_extra $
    else $
        self->_UpdateSelectionVisual

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::Cleanup
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
;   OBJ_DESTROY, Obj
;
;    or
;
;   Obj->[IDLitVisROI::]Cleanup
;
;-
pro IDLitVisROI::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oROI
    OBJ_DESTROY, self._oROIPixels

    ; We need to destroy one of these, since it is lying around
    ; dormant. The other is in our container and will destroyed
    ; automatically but it won't hurt to call obj_destroy on it.
    OBJ_DESTROY, self._oSelectionVisual2D
    OBJ_DESTROY, self._oSelectionVisual3D

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisROI::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisROI::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oROI)) then $
        self._oROI->GetProperty

    ; Register new properties.
    self->IDLitVisROI::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
    endif
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI::]GetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::GetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisROI::Init followed by the word "Get" can be retrieved
;   using IDLitVisROIn::GetProperty.  In addition, the following keywords
;   are supported:
;
;   _VERTICES: Set this keyword to a named variable that upon return
;     will contain a [3,N] vector representing the vertices of the ROI
;     (or the scalar, -1L, if the ROI contains no vertices).
;
;-
pro IDLitVisROI::GetProperty, $
    ROI_TYPE=roiType, $
    TRANSPARENCY=transparency, $
    _VERTICES=_vertices, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get them all from here
    if (ARG_PRESENT(roiType)) then $
        self._oROI->GetProperty, TYPE=roiType

    if ARG_PRESENT(transparency) then begin
        self._oROI->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if (ARG_PRESENT(_vertices)) then begin
        oData = self->GetParameter('VERTICES')
        if (OBJ_VALID(oData)) then $
            success = oData->GetData(_vertices)
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self._oROI->GetProperty, _EXTRA=_extra

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisROI::Init followed by the word "Set" can be retrieved
;   using IDLitVisROI::SetProperty.  In addition, the following keywords
;   are supported:
;
;   _VERTICES: Set this keyword to a [3,N] vector representing the
;     vertices to be associated with the ROI (or a scalar if the ROI
;     is to contain no vertices).
;-
pro IDLitVisROI::SetProperty, $
    TRANSPARENCY=transparency, $
    TRANSFORM=transform, $
    _VERTICES=_vertices, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; TRANSFORM - Override this property so it can be applied
    ;; directly to the ROI data.
    if N_ELEMENTS(transform) gt 0 then begin
        ;; Get data and make it [4,n]
        self._oROI->GetProperty, DATA=data
        ;; Add a check for the availablity of data. Sometimes during
        ;; a property playback (paste, create), this can be called
        ;; with no data present.
        if(n_elements(data) eq 0)then return

        data = [data,transpose(replicate(1.0,n_elements(data[0,*])))]

        ;; Apply new transform
        newData = data ## transpose(transform)

        ;; If the ROI has a valid parent, check if rotation
        ;; keeps ROI within parent's range.
        bSetNewData = 1
        self->IDLitVisualization::GetProperty, PARENT=oParent
        if OBJ_ISA(oParent, '_IDLitVisualization') then begin
            ;; Check to see if new data still fits in the image
            if (oParent->GetXYZRange(xImage, yImage, zImage, /DATA, $
                /NO_TRANSFORM)) then begin
                xROIMax = MAX(newData[0,*], MIN=xROIMin)
                yROIMax = MAX(newData[1,*], MIN=yROIMin)
                ;; Keep the ROI inside the image
                if xROIMin lt xImage[0] or $
                   xROIMax gt xImage[1] or $
                   yROIMin lt yImage[0] or $
                   yROIMax gt yImage[1] then $
                       bSetNewData = 0b
            endif
        endif

        ;; Store data back into object
        if (bSetNewData) then begin
            self._oROI->SetProperty, DATA=newData[0:2,*]
            ; Update the data object, if any.
            oData = self->GetParameter('VERTICES')
            if (OBJ_VALID(oData)) then begin
                self._oROI->GetProperty, DATA=roiData
                success = oData->SetData(roiData, /NO_COPY)
            endif
        endif
    endif

    if (N_ELEMENTS(transparency)) then begin
        self._oROI->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-transparency)/100) < 1
    endif

    if (N_ELEMENTS(_vertices) ne 0) then begin
        oData = self->GetParameter('VERTICES')
        if (~OBJ_VALID(oData)) then begin
            oData = OBJ_NEW("IDLitData", _vertices, NAME='Vertices', $
                TYPE='IDLVERTEX', ICON='segpoly', /PRIVATE)
            void = self->SetData(oData, $
                PARAMETER_NAME= 'VERTICES', /BY_VALUE)
        endif else begin
            success = oData->SetData(_vertices, /NO_COPY)
        endelse
    endif

    ; Everything else goes to the object
    if (N_ELEMENTS(_extra) gt 0) then $
        self._oROI->SetProperty, _EXTRA=_extra

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

    self->_UpdateSelectionVisual
end

;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the vertices from the grROI
;
; Arguments:
;   DATA
;
; Keywords:
;   NONE
;
pro IDLitVisROI::GetData, data, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  
  self->GetProperty, _VERTICES=data, _EXTRA=_extra
    
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   DATA
;
; Keywords:
;   NONE
;
pro IDLitVisROI::PutData, DATA, _EXTRA=_extra
  compile_opt idl2, hidden
  
  ;; SetProperty does a /NO_COPY, thus destroying the original data
  tmp = data
  self->SetProperty, _VERTICES=data
  data = tmp

end


;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisROI::OnDataRangeChange
;
; PURPOSE:
;      This procedure method handles notification that the data range
;      has changed.
;
;      NOTE: This implementation currently assumes that no transformation
;      matrix is being applied between this ROI and the Subject sending
;      the notification.
;
; CALLING SEQUENCE:
;    Obj->[IDLitVisROI::]OnDataRangeChange, oSubject, $
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
pro IDLitVisROI::OnDataRangeChange, oSubject, XRange, YRange, ZRange

    compile_opt idl2, hidden

    ; Retrieve the data range of the ROI.
    self._oROI->GetProperty, XRANGE=roiXRange, YRANGE=roiYRange, $
        ZRANGE=roiZRange

    ; First check if the region is completely clipped.  If so,
    ; simply hide it.
    if ((roiXRange[1] lt XRange[0]) or $
        (roiXRange[0] gt XRange[1]) or $
        (roiYRange[1] lt YRange[0]) or $
        (roiYRange[0] gt YRange[1]) or $
        (roiZRange[1] lt ZRange[0]) or $
        (roiZRange[0] gt ZRange[1])) then begin
        self->IDLgrModel::SetProperty, CLIP_PLANES=0

        ; If not previously clipped, cache the hide flag setting
        ; so it can be restored properly later.
        if (self._bClipped eq 0) then begin
            self._bClipped = 1b
            self->GetProperty, HIDE=oldHide
            self._preClipHide = oldHide
        endif
        self->SetProperty, /HIDE
        self->SetPropertyAttribute, 'HIDE', SENSITIVE=0
    endif else begin
        ; If it was previously clipped, reset the hide flag to
        ; its old setting.
        if (self._bClipped) then begin
            self._bClipped = 0
            self->SetProperty, HIDE=self._preClipHide
            self->SetPropertyAttribute, 'HIDE', SENSITIVE=1
        endif

        ; Determine which, if any, clipping planes need to be enabled.
        nClip = 0
        clipPlanes = 0
        if (XRange[0] gt roiXRange[0]) then begin
            clipPlanes = [-1,0,0,XRange[0]]
            nClip++
        endif

        if (XRange[1] lt roiXRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[1,0,0,-XRange[1]]] : $
                [1,0,0,-XRange[1]]
            nClip++
        endif

        if (YRange[0] gt roiYRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,-1,0,YRange[0]]] : $
                [0,-1,0,YRange[0]]
            nClip++
        endif

        if (YRange[1] lt roiYRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,1,0,-YRange[1]]] : $
                [0,1,0,-YRange[1]]
            nClip++
        endif

        if (ZRange[0] gt roiZRange[0]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,-1,ZRange[0]]] : $
                [0,0,-1,ZRange[0]]
            nClip++
        endif

        if (ZRange[1] lt roiZRange[1]) then begin
            clipPlanes = (nClip gt 0) ? [[clipPlanes],[0,0,1,-ZRange[1]]] : $
                [0,0,1,-ZRange[1]]
            nClip++
        endif

        ; Enable any clip planes (or disable if none required).
        self->IDLgrModel::SetProperty, CLIP_PLANES=clipPlanes
    endelse
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::OnDataChangeUpdate
;
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisROI::]OnDataChangeUpdate, Subject
;
; INPUTS:
;   Subject:  A reference to the object sending notification
;     of the data change.
;-
pro IDLitVisROI::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmName) of
        '<PARAMETER SET>': begin
            oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
            for i=0,nParam-1 do begin
                oData = oSubject->GetByName(paramNames[i])
                if (OBJ_VALID(oData) ne 0) then $
                    self->OnDataChangeUpdate, oData, paramNames[i]
            endfor
            self->_UpdateSelectionVisual
            end

        'VERTICES': begin
            success = oSubject->GetData(Data)
            if (success ne 0) then $
                self._oROI->SetProperty, DATA=Data

            ; Clip to dataspace range if available.
            oDataSpace = self->GetDataSpace(/UNNORMALIZED)
            if (OBJ_VALID(oDataSpace)) then begin
                if (oDataSpace->_GetXYZAxisRange(xDSRange, yDSRange, $
                    zDSRange, /NO_TRANSFORM)) then $
                    self->OnDataRangeChange, oDataSpace, $
                        xDSRange, yDSRange, zDSRange
            endif

            self->_UpdatePixelData

            self->_UpdateSelectionVisual
            end
         else: ; ignore unknown parameters
    endcase

    self->SetPropertyAttribute, 'N_VERTS', HIDE=0

end


;----------------------------------------------------------------------------
; ROI Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
function IDLitVisROI::ComputeGeometry, $
    PIXEL_GEOMETRY=pixelGeometry, $
    _REF_EXTRA=_extra
    compile_opt idl2, hidden


    if (~OBJ_VALID(self._oROI)) then $
        return, 0

    if (KEYWORD_SET(pixelGeometry)) then begin
        self->GetProperty, PARENT=oParent
        if (~OBJ_VALID(oParent)) then $
            return, 0
        if (~OBJ_ISA(oParent, '_IDLitVisGrid2D')) then $
            return, 0

        oParent->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep, $
            GRID_ORIGIN=gridOrigin

        ; Temporarily translate the ROI by the origin (in data units), and
        ; scale by pixel scale to rever to 'pixel' units.
        self._oROI->GetProperty, DATA=oldROIData
        self._oROI->Translate, -gridOrigin[0], -gridOrigin[1], 0.0
        self._oROI->Scale, (1.0/gridStep[0]), (1.0/gridStep[1]), 1.0

        result = self._oROI->ComputeGeometry(_EXTRA=_extra)

        ; Restore original ROI data.
        self._oROI->SetProperty, DATA=oldROIData

    endif else $
        result = self._oROI->ComputeGeometry(_EXTRA=_extra)

    return, result
end

;----------------------------------------------------------------------------
function IDLitVisROI::ComputeMask, $
    DIMENSIONS=inDimensions, $
    MASK_RULE=inMaskRule, $
    PIXEL_CENTER=inPixelCenter, $
    SUCCESS=success, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    success = 0
    defaultMask = BYTARR(100,100)
    maskRule = (N_ELEMENTS(inMaskRule) gt 0) ? inMaskRule[0] : 2
    pixelCenter = (N_ELEMENTS(pixelCenter) eq 2) ? inPixelCenter : [0.5,0.5]

    if (OBJ_VALID(self._oROI) eq 0) then $
        return, defaultMask

    ; The parent is a ROI target visualization.
    self->GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent) eq 0) then $
        return, defaultMask
    if (OBJ_ISA(oParent, '_IDLitVisGrid2D') eq 0) then $
        return, defaultMask

    oParent->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep, $
        GRID_DIMENSIONS=gridDimensions, GRID_ORIGIN=gridOrigin

    dimensions = (N_ELEMENTS(inDimensions) eq 2) ? $
        inDimensions : gridDimensions

    ; Temporarily translate the ROI by the origin (in data units), and
    ; scale by pixel scale to compute the mask.
    self._oROI->GetProperty, DATA=oldROIData
    self._oROI->Translate, -gridOrigin[0], -gridOrigin[1], 0.0
    self._oROI->Scale, (1.0/gridStep[0]), (1.0/gridStep[1]), 1.0

    mask = self._oROI->ComputeMask(DIMENSIONS=dimensions, $
        MASK_RULE=maskRule, PIXEL_CENTER=pixelCenter, _EXTRA=_extra)

    ; Restore original ROI data.
    self._oROI->SetProperty, DATA=oldROIData

    success = 1
    return, mask
end


;----------------------------------------------------------------------------
pro IDLitVisROI::AppendData, X, Y, Z, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Everything goes to the object
    case N_PARAMS() of
        1: self._oROI->AppendData, X, _EXTRA=_extra
        2: self._oROI->AppendData, X, Y, _EXTRA=_extra
        3: self._oROI->AppendData, X, Y, Z, _EXTRA=_extra
    endcase

    self->SetPropertyAttribute, 'N_VERTS', HIDE=0

    self->_UpdateSelectionVisual
end


;----------------------------------------------------------------------------
pro IDLitVisROI::ReplaceData, X, Y, Z, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Everything goes to the object
    nParams = N_PARAMS()
    case nParams of
        1: self._oROI->ReplaceData, X, _EXTRA=_extra
        2: self._oROI->ReplaceData, X, Y, _EXTRA=_extra
        3: self._oROI->ReplaceData, X, Y, Z, _EXTRA=_extra
    endcase

    self->_UpdateSelectionVisual
end


;----------------------------------------------------------------------------
pro IDLitVisROI::RemoveData, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Everything goes to the object
    self._oROI->RemoveData, _EXTRA=_extra
    self->_UpdateSelectionVisual

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::_UpdateSelectionVisual
;
; PURPOSE:
;   This procedure method updates the geometry of the selection visual
;   to match the geometry of the ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI::]_UpdateSelectionVisual
;
;-
pro IDLitVisROI::_UpdateSelectionVisual

    compile_opt idl2, hidden

    ; Collect information from self to pass along to the selection
    ; visual.
    self._oROI->GetProperty, STYLE=style, DATA=data

    ; Only the 3D selection visual needs to be updated.
    oSelVisual = self._oSelectionVisual3D
    oSelVROI = oSelVisual->Get(POSITION=0)
    oSelVROI->SetProperty, STYLE=style, DATA=data
end

;----------------------------------------------------------------------------
;+
; Name:
;   IDLitVisROI::EnablePixelUpdates
;
; Purpose:
;   This procedure method enables that automatic computation of
;   ROI pixel data values whenever the ROI or target visualization
;   data changes.
;
; Calling Sequence:
;   Obj->[IDLitVisROI::]EnablePixelUpdates
;-
pro IDLitVisROI::EnablePixelUpdates
    compile_opt idl2, hidden

    self._bDisablePixelUpdate = 0b

    ; Make sure the pixel data is now up-to-date.
    self->_UpdatePixelData
end

;----------------------------------------------------------------------------
;+
; Name:
;   IDLitVisROI::DisablePixelUpdates
;
; Purpose:
;   This procedure method disables that automatic computation of
;   ROI pixel data values whenever the ROI or target visualization
;   data changes.
;
; Calling Sequence:
;   Obj->[IDLitVisROI::]DisablePixelUpdates
;-
pro IDLitVisROI::DisablePixelUpdates

    compile_opt idl2, hidden

    self._bDisablePixelUpdate = 1b
end

;----------------------------------------------------------------------------
;+
; Name:
;   IDLitVisROI::_UpdatePixelData
;
; Purpose:
;   This internal procedure method updates the values within the stored
;   pixel data (if currently being used).
;
; Calling Sequence:
;   Obj->[IDLitVisROI::]_UpdatePixelData
;
; Keywords:
;   CREATE: Set this keyword to indicate that the pixel data should be
;     created if it does not already exist.  By default, if the pixel
;     data does not already exist, then no action is taken.
;-
pro IDLitVisROI::_UpdatePixelData, $
    CREATE=create

    compile_opt idl2, hidden

    ; If updates are disabled, simply return.
    if (self._bDisablePixelUpdate) then $
        return

    ; If no data to update, and the data is not to be created,
    ; then simply return.
    if (~OBJ_VALID(self._oROIPixels) and ~KEYWORD_SET(create)) then $
        return

    ; Get number of currently contained pixel data items (one per channel).
    nOld = OBJ_VALID(self._oROIPixels) ? self._oROIPixels->Count() : 0

    nChannels = 0
    parentName = ''

    ; Retrieve the target visualization (i.e., the parent).
    self->GetProperty, PARENT=oParent
    if (OBJ_VALID(oParent)) then begin
        oParent->GetProperty, NAME=parentName
        ; Retrieve the parent data.
        if (OBJ_ISA(oParent, 'IDLitVisImage')) then begin
            oImagePixels = oParent->GetParameter('IMAGEPIXELS')
            if (OBJ_VALID(oImagePixels) && $
                oImagePixels->GetData(pParentData, /POINTER)) then begin
                    nChannels = N_ELEMENTS(pParentData)
            endif
        endif
    endif

    ; If no valid parent data, then clear out the ROI pixel data.
    if (nChannels eq 0) then begin
        if (OBJ_VALID(self._oROIPixels)) then $
            OBJ_DESTROY, self._oROIPixels
        self._oROIPixels = OBJ_NEW()
        return
    endif

    ; Create the data container if need be.
    if (~OBJ_VALID(self._oROIPixels)) then $
        self._oROIPixels = OBJ_NEW('IDLitDataContainer', NAME='ROI Pixels', $
            /AUTO_DELETE)

    ; If number of old channels does not match number of
    ; new channels, create/destroy as necessary.
    if (nChannels gt nOld) then begin
        for i=nOld,nChannels-1 do begin
            ; Allocate a vector data object for the ROI pixel data.
            channelName = (nChannels gt 1) ? $
                ' channel '+ STRTRIM(STRING(i),2) : ''
            name = parentName+channelName+' ROI'
            oPixelData = OBJ_NEW('IDLitDataIDLVector', NAME=name, $
                /AUTO_DELETE)
            self._oROIPixels->Add, oPixelData, /OBSERVE_ONLY
        endfor
    endif
    if (nChannels lt nOld) then begin
        pos = nOld-1
        for i=nChannels,nOld-1 do begin
            oPixelData = self._oROIPixels->Get(POSITION=pos)
            self._oROIPixels->Remove, POSITION=pos
            OBJ_DESTROY, oPixelData
            pos = pos - 1
        endfor

        if (nChannels eq 1) then begin
            ; Reset name (no need to include 'channel 0').
            name = parentName+' ROI'
            oPixelData = self._oROIPixels->Get(POSITION=0)
            oPixelData->SetProperty, NAME=name
        endif
    endif

    ; Compute the ROI pixel mask.
    mask = self->ComputeMask()

    ; Determine how many pixels fall within the ROI.
    valid = WHERE(mask, nValid)

    ; Set ROI pixel data for each channel of parent data.
    oChannelPixelData = self._oROIPixels->Get(/ALL)
    for i=0,nChannels-1 do begin

        oPixelData = oChannelPixelData[i]
        if (OBJ_VALID(oPixelData) eq 0) then $
            continue

        if (nvalid gt 0) then begin
            ; Extract the ROI pixels from the parent.
            roiPixels = (*pParentData[i])[valid]

            ; Store the results.
            iStatus = oPixelData->SetData(roiPixels, /NO_COPY)
        endif else $
            iStatus = oPixelData->SetData(/NULL)
    endfor
end

;----------------------------------------------------------------------------
; Name:
;   IDLitVisROI::GetPixelData
;
; Purpose:
;   Retrieves a reference to a data object that represents the image pixel
;   values that fall within this ROI.  The pixel values are collected
;   from this ROI's parent.
;
;   A reference count to the ROI pixel data is incremented as a result
;   of this method call.  When the caller no longer requires access to
;   the ROI pixel data, the ::ReleasePixelData method should be called.
;
; Calling Sequence:
;   Result = Obj->[IDLitVisROI::]GetPixelData()
;
; Outputs:
;   Returns a reference to an IDLitDataContainer object that contains
;   one or more IDLitDataIDLVector data objects that represent the
;   pixel values (per channel) that fall within this ROI.
;
;-
function IDLitVisROI::GetPixelData

    compile_opt idl2, hidden

    bWasDisabled = self._bDisablePixelUpdate
    if (bWasDisabled) then begin
        self._bDisablePixelUpdate = 0b
        self->_UpdatePixelData, /CREATE
        self._bDisablePixelUpdate = 1b
    endif else begin
        if (OBJ_VALID(self._oROIPixels) eq 0) then $
            self->_UpdatePixelData, /CREATE
    endelse

    return, self._oROIPixels
end

;----------------------------------------------------------------------------
; Name:
;   IDLitVisROI::_RepositionToGrid
;
; Purpose:
;   This procedure method translates and/or scales this ROI to
;   account for a change in the target grid.
;
; Calling Sequence:
;   Obj->[IDLitVisROI::]_RepositionToGrid, gridScale, oldOrigin, newOrigin
;
; Arguments:
;   gridScale:  A 2-element vector, [sx, sy], representing the
;     scale factor applied to each grid geometry unit.
;
;   oldOrigin: A two-element vector, [x0, y0], representing the origin
;     of the grid before it was changed.
;
;   newOrigin: A two-element vector, [x1, y1], representing the origin
;     of the grid after it was changed.
;-
pro IDLitVisROI::_RepositionToGrid, gridScale, oldOrigin, newOrigin

    compile_opt idl2, hidden

    if (~OBJ_VALID(self._oROI)) then $
        return

    ; Retrieve original center of rotation.
    cr = self->GetCenterRotation()

    ; Apply scale (about center of rotation).
    self._oROI->Translate, -cr[0], -cr[1], -cr[2]
    self._oROI->Scale, gridScale[0], gridScale[1], 1.0

    ; Translate to new center of rotation and account for
    ; new origin.
    tcx = (cr[0] - oldOrigin[0]) * gridScale[0] + newOrigin[0]
    tcy = (cr[1] - oldOrigin[1]) * gridScale[1] + newOrigin[1]

    self._oROI->Translate, tcx, tcy, cr[2]

    ; Store the result in the data object, if any.
    oData = self->GetParameter('VERTICES')
    if (OBJ_VALID(oData)) then begin
        self._oROI->GetProperty, DATA=roiData
        success = oData->SetData(roiData, /NO_COPY)
    endif
end
;----------------------------------------------------------------------------
; _Visualization Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::OnWorldDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI:]OnDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject:    A reference to the object sending notification
;     of the dimensionality change.
;   is3D: new 3D setting of Subject.
;-
pro IDLitVisROI::OnWorldDimensionChange, oSubject, is3D

    compile_opt idl2, hidden

    ; Call superclass.
    self->_IDLitVisualization::OnDimensionChange, oSubject, is3D

    self->SetDefaultSelectionVisual, (is3D ? $
        self._oSelectionVisual3D : self._oSelectionVisual2D)
end

;----------------------------------------------------------------------------
; Override this method from the contaiing IDLgrModel so that we can
; apply the transform directly to the ROI data.
;
; Note: the ::Scale and ::Rotate methods do not need to be
; implemented specially, because the _IDLitVisualization superclass
; has its own specialized implementation that calls ::SetProperty
; with the TRANFORM property.  The IDLitVisROI::SetProperty handles
; the TRANSFORM property so that the ROI data is transformed
; directly.
;
pro IDLitVisROI::Translate, x, y, z, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; If the ROI has a valid parent, constrain the translation
    ;; so that it stays within the parent's range.
    self->IDLitVisualization::GetProperty, PARENT=oParent
    if OBJ_ISA(oParent, '_IDLitVisualization') then begin
        ;; Get ranges of image and ROI
        if (oParent->GetXYZRange(xImage, yImage, zImage, /DATA, $
            /NO_TRANSFORM)) then begin

            self._oROI->GetProperty, XRANGE=xROI, YRANGE=yROI
            xROIMax = MAX(xROI+x, MIN=xROIMin)
            yROIMax = MAX(yROI+y, MIN=yROIMin)
            ;; Keep the ROI inside the parent.
            if xROIMin lt xImage[0] then x = x + (xImage[0]-xROIMin)
            if xROIMax gt xImage[1] then x = x - (xROIMax-xImage[1])
            if yROIMin lt yImage[0] then y = y + (yImage[0]-yROIMin)
            if yROIMax gt yImage[1] then y = y - (yROIMax-yImage[1])
        endif
    endif

    self._oROI->Translate, x, y, 0

    ; Update the data object, if any.
    oData = self->GetParameter('VERTICES')
    if (OBJ_VALID(oData)) then begin
        self._oROI->GetProperty, DATA=roiData
        success = oData->SetData(roiData, /NO_COPY)
    endif else $
        self->_UpdateSelectionVisual
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::BeginManipulation
;
; PURPOSE:
;   This procedure method handles notification that a manipulator
;   is about to modify this ROI.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI::]BeginManipulator, Manipulator
;
; INPUTS:
;   Manipulator:    A reference to the manipulator object sending
;     notification.
;-
pro IDLitVisROI::BeginManipulation, oManipulator

    compile_opt idl2, hidden

    ; Do not re-compute ROI pixels during manipulation.
    self->DisablePixelUpdates

    oManipulator->GetProperty, OPERATION_IDENTIFIER=opID, $
        PARAMETER_IDENTIFIER=paramID

    if ((opID eq "SET_PROPERTY") and $
        (paramID eq "TRANSFORM")) then $
        oManipulator->SetProperty, PARAMETER_IDENTIFIER="_VERTICES"
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisROI::EndManipulation
;
; PURPOSE:
;   This procedure method handles notification that a manipulator
;   is finished modifying this visualization.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisROI::]EndManipulator, Manipulator
;
; INPUTS:
;   Manipulator:    A reference to the manipulator object sending
;     notification.
;-
pro IDLitVisROI::EndManipulation, oManipulator

    compile_opt idl2, hidden

    ; Re-enable ROI pixels computations.
    self->EnablePixelUpdates

    oManipulator->GetProperty, OPERATION_IDENTIFIER=opID, $
        PARAMETER_IDENTIFIER=paramID
    if ((opID eq "SET_PROPERTY") and $
        (paramID eq "_VERTICES")) then $
        oManipulator->SetProperty, PARAMETER_IDENTIFIER="TRANSFORM"
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisROI__Define
;
; PURPOSE:
;    Defines the object structure.
;
;-
pro IDLitVisROI__Define

    compile_opt idl2, hidden

    struct = { IDLitVisROI,          $
        inherits IDLitVisualization,    $ ; Superclass
        inherits _IDLitVisVertex,       $ ; Superclass
        _oSelectionVisual2D: OBJ_NEW(), $ ; 2D selection visual
        _oSelectionVisual3D: OBJ_NEW(), $ ; 3D selection visual
        _oROI: OBJ_NEW(),               $ ; IDLgrROI object
        _oROIPixels: OBJ_NEW(),         $ ; ROI pixel data container
                                        $ ;   (if needed).
        _bClipped: 0b,                  $ ; Flag: does ROI lie entirely
                                          ;   outside of current data range?
        _preClipHide: 0b,               $ ; HIDE setting prior to clip.
        _bDisablePixelUpdate: 0b        $ ; Flag: disable pixel updates?
    }
end


