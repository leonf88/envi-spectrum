; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisimageplane__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisImagePlane
;
; PURPOSE:
;    The IDLitVisImagePlane class implements image planes for volumes
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisImagePlane::Init
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
;   Obj = OBJ_NEW('IDLitVisImagePlane')
;
;    or
;
;   Obj->[IDLitVisImagePlane::]Init
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::Init methods
;   of this object's superclasses.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;-
function IDLitVisImagePlane::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    if (self->IDLitVisualization::Init(NAME="ImagePlane", $
        TYPE='IDLIMAGE PLANE', $
        ICON='image', $
        DESCRIPTION="An Image Plane", $
        /MANIPULATOR_TARGET, $
        _EXTRA=_extra) ne 1) then $
        return, 0

    self->RegisterParameter, 'VOLUME0', DESCRIPTION='Volume 0', $
        /INPUT, TYPES='IDLARRAY3D'

    self->RegisterParameter, 'VOLUME1', DESCRIPTION='Volume 1', $
        /INPUT, /OPTIONAL, TYPES='IDLARRAY3D'

    self->RegisterParameter, 'VOLUME2', DESCRIPTION='Volume 2', $
        /INPUT, /OPTIONAL, TYPES='IDLARRAY3D'

    self->RegisterParameter, 'VOLUME3', DESCRIPTION='Volume 3', $
        /INPUT, /OPTIONAL, TYPES='IDLARRAY3D'

    self->RegisterParameter, 'RGB_TABLE0', DESCRIPTION='RGB Table 0', $
        /INPUT, /OPTIONAL, TYPES=['IDLPALETTE','IDLARRAY2D']

    self->RegisterParameter, 'RGB_TABLE1', DESCRIPTION='RGB Table 1', $
        /INPUT, /OPTIONAL, TYPES=['IDLPALETTE','IDLARRAY2D']

    self->RegisterParameter, 'OPACITY_TABLE0', DESCRIPTION='Opacity Table 0', $
        /INPUT, /OPTIONAL, TYPES=['IDLOPACITY_TABLE','IDLVECTOR']

    self->RegisterParameter, 'OPACITY_TABLE1', DESCRIPTION='Opacity Table 1', $
        /INPUT, /OPTIONAL, TYPES=['IDLOPACITY_TABLE','IDLVECTOR']

    self->RegisterParameter, 'IMAGEPIXELS', DESCRIPTION='Image', $
        INPUT=0, /OUTPUT, /OPTARGET, TYPES='IDLIMAGEPIXELS'

    self._opacityValue = 50

    self->_IDLitVisualization::Set3D, /ALWAYS

    ;; Create graphics object now so that its properties can be registered
    ;; and aggregated.
    self._oImage = OBJ_NEW('IDLgrImage', /PRIVATE)
    self._oPolygon = OBJ_NEW('IDLgrPolygon', $
                              TEXTURE_MAP=self._oImage, $
                              /REGISTER_PROPERTIES, /PRIVATE, _EXTRA=_extra)
    verts = [[-0.5,-0.5,0],[0.5,-0.5,0],[0.5,0.5,0],[-0.5,0.5,0],[-0.5,-0.5,0]]
    self._oPolygon->SetProperty, DATA=verts, COLOR=[255,255,255], STYLE=2, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1],[0,0]], DEPTH_OFFSET=1

    self->_RegisterProperties

    ;; Hide these properties because we never want the user to see or change them
    self._oPolygon->SetPropertyAttribute, ['AMBIENT', 'DIFFUSE', $
        'EMISSION', 'HIDDEN_LINES', 'LINESTYLE', 'REJECT', $
        'SPECULAR', 'SHADING', 'SHININESS', 'STYLE', 'THICK'], $
        /HIDE, /ADVANCED_ONLY
    self._oPolygon->SetPropertyAttribute, 'TEXTURE_INTERP', ADVANCED_ONLY=0
    self->Aggregate, self._oPolygon

    ;; Create Selection Visual
    ;; We use a custom one for greater control over selection.
    if not OBJ_VALID(self._oSelectionVisual3D) then begin
        self._oSelectionVisual3D = OBJ_NEW('IDLitManipVisImagePlane', $
            VISUAL_TYPE='Select')
        if OBJ_VALID(self._oSelectionVisual3D) then begin
            self->SetDefaultSelectionVisual, self._oSelectionVisual3D
        endif
    endif

    ;; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisImagePlane::SetProperty, _EXTRA=_extra

    return, 1
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImagePlane::Cleanup
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
;   Obj->[IDLitVisImagePlane::]Cleanup
;
;-
pro IDLitVisImagePlane::Cleanup

    compile_opt idl2, hidden

    ;; stop getting notifications from the volvis
    self->RemoveOnNotifyObserver, self->GetFullIdentifier(), $
        self._strVolVis

    OBJ_DESTROY, [self._oPolygon, self._oImage, self._oSelectionVisual3D]

    ;; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisImagePlane::_RegisterProperties
;
; Purpose:
;   This procedure method registers properties associated with this class.
;
; Calling sequence:
;   oObj->[IDLitVisPlot::]_RegisterProperties
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisImagePlane::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'OPACITY_CONTROL', $
            DESCRIPTION='Image plane opacity', $
            ENUMLIST=['Use opacity table', $
                      'Opaque', $
                      'Opacity value' $
                    ], $
            NAME='Opacity control', /ADVANCED_ONLY

        self->RegisterProperty, 'OPACITY_VALUE', /INTEGER, $
            NAME='Opacity value', $
            DESCRIPTION='Opacity of the Image Plane', $
            VALID_RANGE=[0, 100, 5]

        ; Make insensitive so it does not appear in styles.
        self->RegisterProperty, 'ORIENTATION', SENSITIVE=0, $
            DESCRIPTION='Image Plane Orientation', $
            ENUMLIST=['X', 'Y', 'Z'], $
            NAME='Orientation', /ADVANCED_ONLY

    endif

    if (registerAll || (updateFromVersion lt 640)) then begin
        ; PLANE_LOCATION was added in IDL64.
        ; Make insensitive so it does not appear in styles.
        self->RegisterProperty, 'PLANE_LOCATION', /FLOAT, SENSITIVE=0, $
            NAME='Location', $
            DESCRIPTION='Image plane location', $
            VALID_RANGE=[0,1]  ; this will be updated with the volume dimensions
        if (~registerAll && updateFromVersion lt 640) then begin
            ; If restoring then patch up the valid range.
            self->SetPropertyAttribute, 'PLANE_LOCATION', /SENSITIVE, $
                VALID_RANGE=[0,self._volDims[self._orientation]]
        endif
    endif


end

;----------------------------------------------------------------------------
; IDLitVisImagePlane::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisImagePlane::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oPolygon)) then self._oPolygon->GetProperty
    if (OBJ_VALID(self._oImage)) then self._oImage->GetProperty

    ; Register new properties.
    self->IDLitVisImagePlane::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImagePlane::GetProperty
;
; PURPOSE:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImagePlane::]GetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::GetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisImagePlane::Init followed by the word "Get" can be retrieved
;   using IDLitVisImagePlanen::GetProperty.
;
;-
pro IDLitVisImagePlane::GetProperty, $
    OPACITY_CONTROL=opacityControl, $
    OPACITY_VALUE=opacityValue, $
    ORIENTATION=orientation, $
    PLANE_CENTER=planeCenter, $
    PLANE_LOCATION=planeLocation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(opacityControl) then $
        opacityControl = self._opacityControl

    if ARG_PRESENT(opacityValue) then $
        opacityValue = self._opacityValue

    if ARG_PRESENT(orientation) then $
        orientation = self._orientation

    if ARG_PRESENT(planeCenter) then $
        planeCenter = self._center

    if ARG_PRESENT(planeLocation) then begin
        planeLocation = self._center[self._orientation]
    endif

    ; Get polygon props from here
    if (N_ELEMENTS(_extra) gt 0) then $
        if OBJ_VALID(self._oPolygon) then $
            self._oPolygon->GetProperty, _EXTRA=_extra

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImagePlane::SetProperty
;
; PURPOSE:
;   This procedure method sets the value of a property or group of
;   properties.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisImagePlane::]SetProperty
;
; KEYWORD PARAMETERS:
;   This method accepts all keywords supported by the ::SetProperty methods
;   of this object's superclasses.  Furthermore, any keyword to
;   IDLitVisImagePlane::Init followed by the word "Set" can be retrieved
;   using IDLitVisImagePlane::SetProperty.
;-

pro IDLitVisImagePlane::SetProperty, $
    OPACITY_CONTROL=opacityControl, $
    OPACITY_VALUE=opacityValue, $
    ORIENTATION=orientation, $
    PLANE_LOCATION=planeLocation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden


    if N_ELEMENTS(opacityValue) gt 0 then begin
        self._opacityValue = opacityValue
        self->_UpdateImagePlane
    endif

    if N_ELEMENTS(opacityControl) gt 0 then begin
        self._opacityControl = opacityControl
        self->_UpdateImagePlane
    endif

    if (N_ELEMENTS(orientation) && (self._orientation ne orientation)) then begin
        self._orientation = 0 > orientation < 2
        self->_InitImagePlane, /RESET
    endif

    if (N_ELEMENTS(planeLocation) gt 0) then begin
        prev = self._center[self._orientation]
        self._center[self._orientation] = $
            0 > planeLocation < self._volDims[self._orientation]
        diff = self._center[self._orientation] - prev
        if (diff ne 0) then begin
            case (self._orientation) of
            0: self->IDLgrModel::Translate, diff, 0, 0
            1: self->IDLgrModel::Translate, 0, diff, 0
            2: self->IDLgrModel::Translate, 0, 0, diff
            else:
            endcase
            self->_UpdateImagePlane
        endif
    endif

    ; Everything else goes to the object
    if (N_ELEMENTS(_extra) gt 0 && OBJ_VALID(self._oPolygon)) then $
        self._oPolygon->SetProperty, _EXTRA=_extra

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
; PURPOSE:
;   Heavyweight creation - make graphic objects if they do not exist.
;
pro IDLitVisImagePlane::_VerifyGraphics

    compile_opt idl2, hidden

    ;; Add the polygon to our container so that it will draw,
    ;; if it has not yet been added.
    if ~self->IsContained(self._oPolygon) then begin
        self->Add, self._oPolygon, /AGGREGATE
        ;; Make sensitive for property sheet use.
        self->SetPropertyAttribute, 'ORIENTATION', /SENSITIVE
    endif

    ;; Make an effort to find and cache a volume vis
    if self._strVolVis eq '' then begin
        ;; First try selected items.
        oTool = self->GetTool()
        if (~OBJ_VALID(oTool)) then $
            return
        oSelVis = oTool->GetSelectedItems()
        indVolVis = WHERE(OBJ_ISA(oSelVis, 'IDLitVisVolume'), nVolVis)
        if nVolVis gt 0 then begin
            oVolVis = oSelVis[indVolVis[0]] ; pick first selected
        endif $
        ;; Otherwise, look in our dataspace for a volume vis.
        else begin
            oDataSpace = self->GetDataspace()
            oAllList = oDataSpace->Get(/ALL)
            volPosition = WHERE(OBJ_ISA(oAllList, 'IDLITVISVOLUME'), nVolVis)
            if nVolVis gt 0 then $
                oVolVis = oAllList[volPosition[0]]
        endelse
        if not OBJ_VALID(oVolVis) then return
        self._strVolVis = oVolVis->GetFullIdentifier()
        ;; Subscribe to changes in the volume
        self->AddOnNotifyObserver, self->GetFullIdentifier(), $
            self._strVolVis
    endif

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImagePlane::_InitImagePlane
;
; PURPOSE:
;   This procedure method set the initial position of an image plane.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisImagePlane::]_InitImagePlane
;
; INPUTS:
;-
pro IDLitVisImagePlane::_InitImagePlane, RESET=resetIn

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then return

    self->_VerifyGraphics

    ;; Get a hold of the IDLgrVolume object used in the VolVis.
    oVolVis = oTool->GetByIdentifier(self._strVolVis)
    if (~OBJ_VALID(oVolVis)) then return
    oVolVis->GetProperty, VOLUME_OBJECT=oVolume
    self._oVolume = oVolume

    ;; Figure out which color/opac table to use
    oVolume->GetProperty, VOLUME_SELECT=volSel
    self._table = 0
    if volSel eq 1 then self._table = 1

    ;; Set up initial plane orientation
    if OBJ_VALID(self._oVolume) then begin
        self._oVolume->GetProperty, DATA0=data0
        dims = SIZE(data0, /DIMENSIONS)

        oVD = oVolVis->GetParameter("VOLUME_DIMENSIONS")
        if OBJ_VALID(oVD) then $
            success = oVD->GetData(displayDims) $
        else $
            displayDims = dims

        oVL = oVolVis->GetParameter("VOLUME_LOCATION")
        if OBJ_VALID(oVL) then $
            success = oVL->GetData(displayLoc) $
        else $
            displayLoc = [0,0,0]

        reset = Keyword_Set(resetIn) || $
            ~Array_Equal(self._volDims, dims) || $
            ~Array_Equal(self._displayDims, displayDims) || $
            ~Array_Equal(self._displayLoc, displayLoc)

        if (reset) then begin

            self._volDims = dims
            self._displayDims = displayDims
            self._displayLoc = displayLoc

            self->SetPropertyAttribute, 'PLANE_LOCATION', /SENSITIVE, $
                VALID_RANGE=[0,self._volDims[self._orientation]]

            ; Orient canonical plane (in XY plane) to be parallel
            ; to the requested orientation and move it to the middle of the volume.
            case self._orientation of
            0: begin
                self._xRot = 0
                self._yRot = 90
                self._zRot = 90
                self._xSize = self._volDims[1]
                self._ySize = self._volDims[2]
            end
            1: begin
                self._xRot = 90
                self._yRot = 0
                self._zRot = 0
                self._xSize = self._volDims[0]
                self._ySize = self._volDims[2]
            end
            2: begin
                self._xRot = 0
                self._yRot = 0
                self._zRot = 0
                self._xSize = self._volDims[0]
                self._ySize = self._volDims[1]
            end
            endcase
            self._center = self._volDims/2.0
            self->IDLgrModel::Reset
            self->IDLgrModel::Rotate, [0,0,1], self._zRot
            self->IDLgrModel::Rotate, [0,1,0], self._yRot
            self->IDLgrModel::Rotate, [1,0,0], self._xRot
            self->IDLgrModel::Scale, self._displayDims[0], $
                self._displayDims[1], self._displayDims[2]
            t = self._displayLoc + self._displayDims/2.0
            self->IDLgrModel::Translate, t[0], t[1], t[2]
            self->IDLgrModel::GetProperty, TRANSFORM=t
            self._normal = ([0,0,1,0] # t)[0:2]
            self._normal /= SQRT(TOTAL(self._normal^2))
        endif
    endif
    self->_UpdateImagePlane
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisImagePlane::_UpdateImagePlane
;
; PURPOSE:
;   This procedure method updates the image data for the
;   image plane.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisImagePlane::]_UpdateImagePlane
;
; INPUTS:
;-
pro IDLitVisImagePlane::_UpdateImagePlane

    compile_opt idl2, hidden

    ;; We use the volume data from the IDLgrVolume object because it has already
    ;; been BYTSCL'd appropriately and can be used as direct indicies into the
    ;; color and opacity tables.
    if OBJ_VALID(self._oVolume) then $
        self._oVolume->GetProperty, DATA0=data0, DATA1=data1, DATA2=data2, $
            DATA3=data3, VOLUME_SELECT=volumeSelect

    if N_ELEMENTS(data0) gt 0 then begin
        ;; Create RGBA image (will reform to dims later)
        im = BYTARR(4, self._xSize * self._ySize, /NOZERO)

        ;; Get color and opacity tables
        self._oVolume->GetProperty, RGB_TABLE0=rgb0, OPACITY_TABLE0=opacity0, $
            RGB_TABLE1=rgb1, OPACITY_TABLE1=opacity1, INTERPOLATE=interp
        rgb0 = TRANSPOSE(rgb0)
        rgb1 = TRANSPOSE(rgb1)

        ;; Make sure center is in the volume
        inVolume = Min(self._center ge 0 and self._center le self._volDims)
        center = 0 > self._center < (self._volDims-1)
        fdims = FLOAT(self._volDims)

        ;; Try to match the interpolation of IDLgrVolume.
        sample = interp ? 0 : 1
        self._oPolygon->SetProperty, TEXTURE_INTERP=interp

        ;; Grab the slices we need
        switch volumeSelect of
        2: begin
            if (inVolume) then begin
                image2 = EXTRACT_SLICE(data2, self._xSize, self._ySize, $
                                       center[0], center[1], center[2], $
                                       self._xRot, self._yRot, self._zRot,$
                                       SAMPLE=sample);
                image3 = EXTRACT_SLICE(data3, self._xSize, self._ySize, $
                                       center[0], center[1], center[2], $
                                       self._xRot, self._yRot, self._zRot, $
                                       SAMPLE=sample);
            endif else begin
                ;; Outside of volume - just fill with zero
                image2 = BYTARR(self._xSize, self._ySize)
                image3 = BYTARR(self._xSize, self._ySize)
            endelse
            ;; fall through
        end
        1: begin
            if (inVolume) then begin
                image1 = EXTRACT_SLICE(data1, self._xSize, self._ySize, $
                                       center[0], center[1], center[2], $
                                       self._xRot, self._yRot, self._zRot, $
                                       SAMPLE=sample);
            endif else begin
                ;; Outside of volume - just fill with zero
                image1 = BYTARR(self._xSize, self._ySize)
            endelse
            ;; fall through
        end
        0: begin
            if (inVolume) then begin
                image0 = EXTRACT_SLICE(data0, self._xSize, self._ySize, $
                                       center[0], center[1], center[2], $
                                       self._xRot, self._yRot, self._zRot, $
                                       SAMPLE=sample);
            endif else begin
                ;; Outside of volume - just fill with zero
                image0 = BYTARR(self._xSize, self._ySize)
            endelse
        end
        endswitch

        ;; Fill in the image according to volume select.
        case volumeSelect of
        0: begin
            image0 = REFORM(image0, self._xSize * self._ySize)
            im[0:2, *] = rgb0[*, image0]
            ;; Alpha channel comes from the opacity table
            case self._opacityControl of
            0: im[3, *] = opacity0[image0]
            1: im[3, *] = 255
            2: im[3, *] = self._opacityValue * 2.55
            else: im[3, *] = 255
            endcase
        end
        1: begin
            image0 = REFORM(image0, self._xSize * self._ySize)
            image1 = REFORM(image1, self._xSize * self._ySize)
            im[0:2, *] = BYTE((FIX(rgb0[*, image0]) * FIX(rgb1[*, image1]))/256)
            ;; Alpha channel comes from the opacity table
            case self._opacityControl of
            0: im[3, *] = BYTE((FIX(opacity0[image0]) * FIX(opacity1[image1]))/256)
            1: im[3, *] = 255
            2: im[3, *] = self._opacityValue * 2.55
            else: im[3, *] = 255
            endcase
        end
        2: begin
            image0 = REFORM(image0, self._xSize * self._ySize)
            image1 = REFORM(image1, self._xSize * self._ySize)
            image2 = REFORM(image2, self._xSize * self._ySize)
            image3 = REFORM(image3, self._xSize * self._ySize)
            im[0, *] = rgb0[0, image0]
            im[1, *] = rgb0[1, image1]
            im[2, *] = rgb0[2, image2]
            ;; Alpha channel comes from the opacity table
            case self._opacityControl of
            0: im[3, *] = opacity0[image3]
            1: im[3, *] = 255
            2: im[3, *] = self._opacityValue * 2.55
            else: im[3, *] = 255
            endcase
        end
        endcase

        im = Reform(im, 4, self._xSize, self._ySize, /OVERWRITE)

        ;; Update our IDLgrImage texture map with the new image.
        ;; Be sure to make the texture map a power of 2 in size.
        xpow2 = 1 & ypow2 = 1
        while (xpow2 lt self._xSize) do xpow2 *= 2
        while (ypow2 lt self._ySize) do ypow2 *= 2
        img = BYTARR(4, xpow2, ypow2)
        img[*, 0:self._xSize-1, 0:self._ySize-1] = im
        self._oImage->SetProperty, DATA=img
        xpow2 = FLOAT(xpow2) & ypow2 = FLOAT(ypow2)
        tc = [[0.0,0.0], [self._xSize/xpow2, 0], [self._xSize/xpow2, self._ySize/ypow2], $
            [0, self._ySize/ypow2], [0,0]]
        self._oPolygon->SetProperty, TEXTURE_MAP=self._oImage, TEXTURE_COORD=tc
        ;; Update the parameter data (no palette).
        if OBJ_VALID(self._oImageParm) then $
            success = self._oImageParm->SetData(im, 'IMAGEPIXELS', /NO_NOTIFY)
    endif
end


;----------------------------------------------------------------------------
; Data Observer Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method handles notification of changes from a Subject
;   we have subscribed to.
;   In this case, we are watching the volume object that this image plane
;   belongs to.
;
pro IDLitVisImagePlane::OnNotify, strItem, strMsg, strUser

    compile_opt idl2, hidden

    case STRUPCASE(strMsg) of
    ;; Interpolate image plane the same way the volume is.
    "INTERPOLATE": self->_UpdateImagePlane
    else:
    endcase
end

;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method handles notification that the data has changed.
;
pro IDLitVisImagePlane::OnDataChangeUpdate, oSubject, parmName, $
    NO_UPDATE=noUpdate

    compile_opt idl2, hidden

    case STRUPCASE(parmName) of
        '<PARAMETER SET>': begin
            oParams = oSubject->Get(/ALL, COUNT=nParam, NAME=paramNames)
            for i=0,nParam-1 do begin
                oData = oSubject->GetByName(paramNames[i])
                if (OBJ_VALID(oData[0]) ne 0) then $
                    self->OnDataChangeUpdate, oData, paramNames[i], /NO_UPDATE
            endfor
            doInit = 1b
            end

        'IMAGEPIXELS': begin
            ;; When this parm gets set for the first time,
            ;; remember it and copy the image into it.
            if ~OBJ_VALID(self._oImageParm) then begin
                self._oImageParm = oSubject
                doUpdate = 1b
            endif
            end
         'VOLUME0': doInit = 1b
         'VOLUME1': doInit = 1b
         'VOLUME2': doInit = 1b
         'VOLUME3': doInit = 1b
         'RGB_TABLE0': doUpdate = 1b
         'RGB_TABLE1': doUpdate = 1b
         'OPACITY_TABLE0': doUpdate = 1b
         'OPACITY_TABLE1': doUpdate = 1b
         else: ; ignore unknown parameters
    endcase

    if (~Keyword_Set(noUpdate)) then begin
        if (Keyword_Set(doInit)) then self->_InitImagePlane $
        else if (Keyword_Set(doUpdate)) then self->_UpdateImagePlane
    endif
end


;----------------------------------------------------------------------------
; _Visualization Interface
;----------------------------------------------------------------------------

; override
pro IDLitVisImagePlane::WindowToVis, arg1, arg2, arg3, arg4, arg5, arg6

    compile_opt idl2, hidden

    oDataspace = self->GetDataspace()
    case N_PARAMS() of
    2: oDataspace->WindowToVis, arg1, arg2
    4: oDataspace->WindowToVis, arg1, arg2, arg3, arg4
    6: oDataspace->WindowToVis, arg1, arg2, arg3, arg4, arg5, arg6
    else:
    endcase

end

pro IDLitVisImagePlane::VisToWindow, arg1, arg2, arg3, arg4, arg5, arg6, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    oDataspace = self->GetDataspace()
    case N_PARAMS() of
    2: oDataspace->VisToWindow, arg1, arg2, _EXTRA=_extra
    4: oDataspace->VisToWindow, arg1, arg2, arg3, arg4, _EXTRA=_extra
    6: oDataspace->VisToWindow, arg1, arg2, arg3, arg4, arg5, arg6, $
        _EXTRA=_extra
    else:
    endcase

end

;----------------------------------------------------------------------------
; Override this method from the containing IDLgrModel so that we can
; constrain the translation along the image plane normal.
;
pro IDLitVisImagePlane::Translate, x, y, z, _REF_EXTRA=_extra

     compile_opt idl2, hidden

    ;; Figure out the correct amount to translate the image plane
    ;; by projecting the dataspace translation vector (passed in
    ;; as x, y, z) onto the image plane normal.
    dot = (TRANSPOSE([x,y,z]) # self._normal)[0]
    mag = TOTAL(self._normal^2)
    moveVector = self._normal * dot / mag

    ;; Compute the amount of motion in terms of the original volume.
    moveVectorVol = moveVector * self._volDims / self._displayDims

    ;; Constrain motion to volume boundaries.
    ;; Just return if the center of the image plane is beyond the
    ;; volume extents.
    tempCenter = self._center + moveVectorVol
    if MIN(tempCenter) lt 0.0 then return
    if not ARRAY_EQUAL(tempCenter < self._volDims, tempCenter) then return

    ;; Apply modified translation to model.
    self->IDLgrModel::Translate, moveVector[0], moveVector[1], $
        moveVector[2]

    ;; Update the center so the new image slice can be extracted
    self._center += moveVectorVol
    self->_UpdateImagePlane
end

;----------------------------------------------------------------------------
; Override this method from the containing IDLgrModel so that we can
; suppress scaling completely
;
pro IDLitVisImagePlane::Scale, x, y, z, _REF_EXTRA=_extra
    compile_opt idl2, hidden
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisImagePlane__Define
;
; PURPOSE:
;    Defines the object structure.
;
;-
pro IDLitVisImagePlane__Define

    compile_opt idl2, hidden

    struct = { IDLitVisImagePlane,          $
        inherits IDLitVisualization,    $ ; Superclass
        _oSelectionVisual3D: OBJ_NEW(), $ ; 3D selection visual
        _center: DBLARR(3),             $ ; Center of image plane in vol
        _normal: DBLARR(3),             $ ; Image plane normal
        _xRot: 0.0,                     $
        _yRot: 0.0,                     $
        _zRot: 0.0,                     $
        _xSize: 0L,                     $
        _ySize: 0L,                     $
        _strVolVis: '',                 $ ; Volume Visualization object ID
        _volDims: LONARR(3),            $ ; Dimensions of Volume
        _displayDims: DBLARR(3),        $ ; Volume display dimensions
        _displayLoc: DBLARR(3),         $ ; Volume display location
        _table: 0b,                     $ ; Which color/opacity tables to use
        _opacityControl: 0b,            $ ; 0=use table, 1=opaque, 2=constant
        _opacityValue: 0b,              $ ; Opacity Constant Value 0-100
        _orientation: 0b,               $ ; Plane orientation (X=0, Y=1, Z=2)
        _oImage: OBJ_NEW(),             $ ; IDLgrImage object for texture map
        _oImageParm: OBJ_NEW(),         $ ; Image data (do not clean up)
        _oPolygon: OBJ_NEW(),           $ ; IDLgrPolygon object
        _oVolume: OBJ_NEW()             $ ; IDLgrVolume object (do not clean up)
    }
end


