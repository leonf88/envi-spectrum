; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisvolume__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisVolume
;
; PURPOSE:
;    The IDLitVisVolume class handles rendering volume data.  This class
;    is a "wrapper" around IDLgrVolume and renders volume data either
;    with the renderer in IDLgrVolume or with a "texture map stack".
;    Much of this class is devoted to implementing the texture map stack.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
; SUBCLASSES:
;
; METHODS:
;
; MODIFICATION HISTORY:
;     Written by:   kws
;-

;----------------------------------------------------------------------------
; IDLitVisVolume::_RegisterProperties
;
; Purpose:
;   Internal routine that will register all properties supported by
;   this object.
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisVolume::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        self->RegisterProperty, 'DISPLAY_SCALE', $
            NAME='Display scale', $
            USERDEF='Select display scale bottom/top', $
            DESCRIPTION='Select display scale bottom/top', /ADVANCED_ONLY

        self->RegisterProperty, 'RGB_OPAC_0', $
            NAME='Color & opacity table 0', $
            USERDEF='Edit color/opacity table', $
            DESCRIPTION='Edit RGB color and opacity table 0', /ADVANCED_ONLY

        self->RegisterProperty, 'RGB_OPAC_1', $
            NAME='Color & opacity table 1', $
            USERDEF='Edit color/opacity table', $
            DESCRIPTION='Edit RGB color and opacity table 1', /ADVANCED_ONLY

        self->RegisterProperty, 'SUBVOLUME', $
            NAME='Subvolume', $
            USERDEF='Edit Subvolume extents', $
            DESCRIPTION='Edit Subvolume extents', /ADVANCED_ONLY

        ; Aggregate the volume properties.
        self->Aggregate, self._oVolume

        ; HIDE these so that they don't show up in a style sheet.
        ; We unHIDE them later when we get volume data.
        self->SetPropertyAttribute, ['DISPLAY_SCALE', $
                                     'RGB_OPAC_0', $
                                     'RGB_OPAC_1', $
                                     'SUBVOLUME' $
                                    ], /HIDE

    endif

    if (registerAll || (updateFromVersion lt 610)) then begin

        self->RegisterProperty, 'AUTO_RENDER', /BOOLEAN, $
            NAME='Auto render', $
            DESCRIPTION='Automatically render volume on each update'

        ; Register a new render quality property that is zero-based,
        ; so we can use it in the property sheet. This will be converted
        ; within Get/SetProperty to the old one-based member value.
        self->RegisterProperty, '_RENDER_QUALITY', $
            ENUMLIST=['Low (texture maps)', 'High (volume)'], $
            NAME='Quality', $
            DESCRIPTION='Volume rendering quality', /ADVANCED_ONLY

        self->RegisterProperty, 'RENDER_EXTENTS', $
            ENUMLIST=['Off', 'Wire frame', 'Solid walls'], $
            NAME='Boundary', $
            DESCRIPTION='Render the volume boundary', /ADVANCED_ONLY

        self->RegisterProperty, 'EXTENTS_TRANSPARENCY', /INTEGER, $
            NAME='Boundary transparency', $
            DESCRIPTION='Transparency of volume boundary', $
            VALID_RANGE=[0,100,5], /ADVANCED_ONLY

        self->RegisterProperty, 'X_RENDER_STEP', /FLOAT, /ADVANCED_ONLY, $
            NAME='Render step X', $
            DESCRIPTION='X stepping factor through the voxel matrix'

        self->RegisterProperty, 'Y_RENDER_STEP', /FLOAT, /ADVANCED_ONLY, $
            NAME='Render step Y', $
            DESCRIPTION='Y stepping factor through the voxel matrix'

        self->RegisterProperty, 'Z_RENDER_STEP', /FLOAT, /ADVANCED_ONLY, $
            NAME='Render step Z', $
            DESCRIPTION='Z stepping factor through the voxel matrix'

        ; The color really only applies to the extents.
        self->SetPropertyAttribute, 'COLOR', NAME='Extents color'

        ; Use TRANSPARENCY property instead.
        self->SetPropertyAttribute, 'ALPHA_CHANNEL', /HIDE, /ADVANCED_ONLY

        ;; Needed so that Display scale changes are undoable.
        self->RegisterProperty, 'BYTESCALE_MIN', $
            NAME='Byte Scale Min', $
            USERDEF='Display scale bottom', $
            DESCRIPTION='Display scale bottom', /HIDE, /ADVANCED_ONLY

        self->RegisterProperty, 'BYTESCALE_MAX', $
            NAME='Byte Scale Max', $
            USERDEF='Display scale top', $
            DESCRIPTION='Display scale top', /HIDE, /ADVANCED_ONLY

    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisVolume')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
function IDLitVisVolume::Init, $
                         NAME=NAME, $
                         DESCRIPTION=DESCRIPTION, $
                         _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not KEYWORD_SET(name))then name ="Volume"
    if(not KEYWORD_SET(DESCRIPTION))then DESCRIPTION ="A Volume Visualization"

    ;; Initialize superclass
    if (self->IDLitVisualization::Init(TYPE="IDLVOLUME", $
                                       ICON='volume', $
                                       DESCRIPTION=DESCRIPTION, $
                                       NAME=NAME, $
                                       _EXTRA=_extra) ne 1) then $
        RETURN, 0

    ;; We are a 3D vis
    self->Set3D, /ALWAYS

    self->RegisterParameter, 'VOLUME0', DESCRIPTION='Volume Data', $
        /INPUT, TYPES='IDLARRAY3D', /OPTIONAL, /OPTARGET
    self->RegisterParameter, 'VOLUME1', DESCRIPTION='Volume Data', $
        /INPUT, TYPES='IDLARRAY3D', /OPTIONAL
    self->RegisterParameter, 'VOLUME2', DESCRIPTION='Volume Data', $
        /INPUT, TYPES='IDLARRAY3D', /OPTIONAL
    self->RegisterParameter, 'VOLUME3', DESCRIPTION='Volume Data', $
        /INPUT, TYPES='IDLARRAY3D', /OPTIONAL
    self->RegisterParameter, 'RGB_TABLE0', DESCRIPTION='RGB Color Table 0', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTIONAL, /OPTARGET
    self->RegisterParameter, 'RGB_TABLE1', DESCRIPTION='RGB Color Table 1', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D'], /OPTIONAL
    self->RegisterParameter, 'OPACITY_TABLE0', DESCRIPTION='Opacity Table 0', $
        /INPUT, TYPES=['IDLOPACITY_TABLE','IDLVECTOR'], /OPTIONAL
    self->RegisterParameter, 'OPACITY_TABLE1', DESCRIPTION='Opacity Table 1', $
        /INPUT, TYPES=['IDLOPACITY_TABLE','IDLVECTOR'], /OPTIONAL
    self->RegisterParameter, 'VOLUME_DIMENSIONS', DESCRIPTION='Volume Dimensions', $
        /INPUT, TYPES='IDLVECTOR', /OPTIONAL
    self->RegisterParameter, 'VOLUME_LOCATION', DESCRIPTION='Volume Location', $
        /INPUT, TYPES='IDLVECTOR', /OPTIONAL
    self->RegisterParameter, 'SUBVOLUME', DESCRIPTION='SubVolume', $
        /INPUT, TYPES='IDLVECTOR', /OPTIONAL

    ;; This object is used for the high-quality rendering.
    ; NOTE: The IDLgrVolume properties will be aggregated as part of
    ; the property registration process in an upcoming call to
    ; ::_RegisterProperties
    self._oVolume = OBJ_NEW('IDLgrVolume', /HIDE, /PRIVATE, $
        ALPHA_CHANNEL=0.1, $   ; 90% extents transparency
        /ZBUFFER, /ZERO_OPACITY_SKIP, /REGISTER_PROPERTIES)
    self->Add, self._oVolume

    ; Register all properties.
    self->IDLitVisVolume::_RegisterProperties

    ;; These objects hold the polygons
    ;; for the texture map stack display method.
    ;; There are a total of 6 polygon stacks, one
    ;; for each of +X, -X, +Y, -Y, +Z, -Z
    self._oPlaneContainer = OBJ_NEW('IDLgrModel', /PRIVATE)
    for i=0, 5 do self._oPlaneModels[i] = $
        OBJ_NEW('IDLgrModel', /HIDE, LIGHTING=0, /PRIVATE)
    self._oPlaneContainer->Add, self._oPlaneModels
    self->Add, self._oPlaneContainer

    ;; Textures for the texture map stacks.
    ;; Need one for each axis (X,Y,Z).  Each
    ;; texture is "tiled" with the textures for
    ;; each slice in the stack.
    for i=0, 2 do self._oTextures[i] = $
        OBJ_NEW('IDLgrImage', /HIDE, /PRIVATE)

    ;; Holds the geometry for drawing the volume extents.
    self._oBoxModel = $
        OBJ_NEW('IDLgrModel', LIGHTING=0, /PRIVATE)
    self->Add, self._oBoxModel

    ;; Init state
    self._dimensions = [1,1,1]
    self._subvolume = [-1,-1,-1,-1,-1,-1]
    self._renderExtents = 2
    self._renderQuality = 1

    ;; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisVolume::SetProperty, _EXTRA=_extra

    RETURN, 1                     ; Success

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::Cleanup
;
; PURPOSE:
;    Cleanup this component
;
; CALLING SEQUENCE:
;
;    OBJ_DESTROY, Obj
;
;
;-
pro IDLitVisVolume::Cleanup

    compile_opt idl2, hidden

    ;; These aren't stored in any models that get destroyed when we do..
    OBJ_DESTROY, self._oTextures

    ;; Cleanup superclass
    self->IDLitVisualization::Cleanup

end

;----------------------------------------------------------------------------
; IDLitVisVolume::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisVolume::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oVolume)) then $
        self._oVolume->GetProperty

    ; Register new properties.
    self->IDLitVisVolume::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_ReplicateRowsCols
;
; PURPOSE:
;    Internal utility function to add a border around a texture.
;    The border texels are replicated from the adjacent texels.
;
; CALLING SEQUENCE:
;
;    newTexture = self->_ReplicateRowsCols(inTexture)
;
; INPUTS:
;    inTexture - 2D array
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;    This function returns the new texture.
;
; SIDE EFFECTS:
;    The input texture memory is freed
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
function IDLitVisVolume::_ReplicateRowsCols, inTexture

    compile_opt idl2, hidden

    slicesize = SIZE(inTexture, /DIMENSIONS) + 2
    tmp = BYTARR(slicesize[0],slicesize[1])
    tmp[1:slicesize[0]-2,1:slicesize[1]-2] = TEMPORARY(inTexture)
    ; replicate the rows/cols
    tmp[1:slicesize[0]-2,0] = tmp[1:slicesize[0]-2,1]
    tmp[1:slicesize[0]-2,slicesize[1]-1] = tmp[1:slicesize[0]-2,slicesize[1]-2]
    tmp[0,1:slicesize[1]-2] = tmp[1,1:slicesize[1]-2]
    tmp[slicesize[0]-1,1:slicesize[1]-2] = tmp[slicesize[0]-2,1:slicesize[1]-2]
    ; and the corners
    tmp[0,0] = tmp[1,1]
    tmp[slicesize[0]-1,0] = tmp[slicesize[0]-2,1]
    tmp[slicesize[0]-1,slicesize[1]-1] = tmp[slicesize[0]-2,slicesize[1]-2]
    tmp[0,slicesize[1]-1] = tmp[1,slicesize[1]-2]
    return, tmp
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_BuildTexture
;
; PURPOSE:
;    Internal utility function to build a texture for the
;    texture map volume display method.
;
; CALLING SEQUENCE:
;
;    texture = self->_BuildTexture()
;
; INPUTS:
;    vol0 - 3D array
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;    This function returns the generated texture.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-

function IDLitVisVolume::_BuildTexture, vol0, vol1, vol2, vol3, $
                                        tbl0, tbl1, opa0, opa1, $
                                        axis, interp, coords
    compile_opt idl2, hidden

    ;; All vols should be the same size at this point
    dim = SIZE(vol0, /DIMENSIONS)

    ;; Find the number of slices and their size
    case axis of
        0: slicedims = [1,2]
        1: slicedims = [2,0]
        2: slicedims = [0,1]
    endcase
    nslices = dim[axis]
    slicesize = dim[slicedims]
    interp = interp gt 0 ? 1 : 0

    ;; If a subvolume is specified, prepare bounds data for later
    self._oVolume->GetProperty, BOUNDS=bounds
    case axis of
    0: begin
        xBounds = [bounds[1], bounds[4]]
        yBounds = [bounds[2], bounds[5]]
        zBounds = [bounds[0], bounds[3]]
    end
    1: begin
        xBounds = [bounds[2], bounds[5]]
        yBounds = [bounds[0], bounds[3]]
        zBounds = [bounds[1], bounds[4]]
    end
    2: begin
        xBounds = [bounds[0], bounds[3]]
        yBounds = [bounds[1], bounds[4]]
        zBounds = [bounds[2], bounds[5]]
    end
    endcase

    ;; If interpolation is on, we must replicate the borders
    if (interp) then slicesize = slicesize + 2

    ;; Lay out the tiles so that the entire texture map
    ;; is as square as possible.
    nx = nslices
    ny = 1
    while nx * slicesize[0] gt ny * slicesize[1] and $
          ny lt nslices do begin
        ny = ny + 1
        nx = CEIL(FLOAT(nslices) / FLOAT(ny))
    endwhile

    ;; Figure out the next higher power of two, so IDL
    ;; does not resample.
    xlen = 1L & ylen = 1L
    while xlen lt nx * slicesize[0] do xlen = xlen * 2
    while ylen lt ny * slicesize[1] do ylen = ylen * 2

    ;; Since we're only doing an approximate rendering that is
    ;; supposed to draw quickly, limit the maximum texture size.
    needCongrid = 0
    if (xlen > ylen) gt 1024 then begin
        factor = (nx * slicesize[0] > ny * slicesize[1]) / 1024.0
        slicesize = FLOOR(slicesize / factor)
        xlen = 1L & ylen = 1L
        while xlen lt nx * slicesize[0] do xlen = xlen * 2
        while ylen lt ny * slicesize[1] do ylen = ylen * 2
        needCongrid = 1
        xBounds = FLOOR(xBounds / factor)
        yBounds = FLOOR(yBounds / factor)
        xBounds[0] = xBounds[0] > 0
        xBounds[1] = xBounds[1] < (slicesize[0]-1)
        yBounds[0] = yBounds[0] > 0
        yBounds[1] = yBounds[1] < (slicesize[1]-1)
    endif

    ;; Cook up the return values
    tex = BYTARR(4,xlen,ylen)
    coords = FLTARR(nslices,2,4)

    ;; Fill in the texture chunks and the texture coords
    px = 0
    py = 0
    for islice=0, nslices-1 do begin
        case axis of
            0: begin
                if N_ELEMENTS(vol0) gt 0 then $
                    slice0 = REFORM(vol0[islice,*,*])
                if N_ELEMENTS(vol1) gt 0 then $
                    slice1 = REFORM(vol1[islice,*,*])
                if N_ELEMENTS(vol2) gt 0 then $
                    slice2 = REFORM(vol2[islice,*,*])
                if N_ELEMENTS(vol3) gt 0 then $
                    slice3 = REFORM(vol3[islice,*,*])
               end
            1: begin
                if N_ELEMENTS(vol0) gt 0 then $
                    slice0 = TRANSPOSE(REFORM(vol0[*,islice,*]),[1,0])
                if N_ELEMENTS(vol1) gt 0 then $
                    slice1 = TRANSPOSE(REFORM(vol1[*,islice,*]),[1,0])
                if N_ELEMENTS(vol2) gt 0 then $
                    slice2 = TRANSPOSE(REFORM(vol2[*,islice,*]),[1,0])
                if N_ELEMENTS(vol3) gt 0 then $
                    slice3 = TRANSPOSE(REFORM(vol3[*,islice,*]),[1,0])
               end
            2: begin
                if N_ELEMENTS(vol0) gt 0 then $
                    slice0 = REFORM(vol0[*,*,islice])
                if N_ELEMENTS(vol1) gt 0 then $
                    slice1 = REFORM(vol1[*,*,islice])
                if N_ELEMENTS(vol2) gt 0 then $
                    slice2 = REFORM(vol2[*,*,islice])
                if N_ELEMENTS(vol3) gt 0 then $
                    slice3 = REFORM(vol3[*,*,islice])
               end
        endcase
        if needCongrid then begin
            sz = interp ? slicesize-2 : slicesize
            if N_ELEMENTS(vol0) gt 0 then $
                slice0 = CONGRID(slice0, sz[0], sz[1])
            if N_ELEMENTS(vol1) gt 0 then $
                slice1 = CONGRID(slice1, sz[0], sz[1])
            if N_ELEMENTS(vol2) gt 0 then $
                slice2 = CONGRID(slice2, sz[0], sz[1])
            if N_ELEMENTS(vol3) gt 0 then $
                slice3 = CONGRID(slice3, sz[0], sz[1])
        endif
        ;; if interpolation is on, replicate the border rows/columns
        if (interp) then begin
            slice0 = self->_ReplicateRowsCols(slice0)
            if N_ELEMENTS(vol1) gt 0 then begin
               slice1 = self->_ReplicateRowsCols(slice1)
            endif
            if N_ELEMENTS(vol2) gt 0 && N_ELEMENTS(vol3) gt 0 then begin
               slice2 = self->_ReplicateRowsCols(slice2)
               slice3 = self->_ReplicateRowsCols(slice3)
            endif
        end
        if N_ELEMENTS(vol1) eq 0 then begin
            ;; VOLUME_SELECT = 0
            tex[0,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = tbl0[0,slice0]
            tex[1,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = tbl0[1,slice0]
            tex[2,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = tbl0[2,slice0]
            tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = opa0[slice0]
        endif
        if N_ELEMENTS(vol1) gt 0 && N_ELEMENTS(vol2) eq 0 then begin
            ;; VOLUME_SELECT = 1
            tex[0,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[0,slice0]) * tbl1[0,slice1] / 256
            tex[1,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[1,slice0]) * tbl1[1,slice1] / 256
            tex[2,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[2,slice0]) * tbl1[2,slice1] / 256
            tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(opa0[slice0]) * opa1[slice1] / 256
        endif
        if N_ELEMENTS(vol1) gt 0 && N_ELEMENTS(vol2) gt 0 && $
           N_ELEMENTS(vol3) gt 0 then begin
            ;; VOLUME_SELECT = 2
            tex[0,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[0,slice0]) * opa0[slice0] / 255
            tex[1,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[1,slice1]) * opa0[slice1] / 255
            tex[2,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = LONG(tbl0[2,slice2]) * opa0[slice2] / 255
            tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = opa0[slice3]
        endif
        ;; If interpolation, inset the texture coords into the padding bounds.
        half = FLOAT(interp)
        off = 0.0
        frac = [1.0/xlen,1.0/ylen]
        x0 = px*frac[0] + half*frac[0]
        x1 = (px+slicesize[0]-off)*frac[0] - half*frac[0]
        y0 = py*frac[1] + half*frac[1]
        y1 = (py+slicesize[1]-off)*frac[1] - half*frac[1]
        x0 = px*frac[0] + half*frac[0]
        x1 = (px+slicesize[0]-off)*frac[0] - half*frac[0]
        y0 = py*frac[1] + half*frac[1]
        y1 = (py+slicesize[1]-off)*frac[1] - half*frac[1]
        coords[islice,*,0] = [x0,y0]
        coords[islice,*,1] = [x1,y0]
        coords[islice,*,2] = [x1,y1]
        coords[islice,*,3] = [x0,y1]

        ;; Modify texture maps if we have a subvolume.
        ;; We simply set the opacity of the parts of the texture maps
        ;; outside the subvolume to zero to make that part of the volume
        ;; invisible.
        if MAX(bounds) gt 0 then begin
            if islice ge zBounds[0] and islice le zBounds[1] then begin
                ;; The slice is in the subvolume.
                ;; Create a mask that covers the subvolume.
                mask = BYTARR(slicesize[0], slicesize[1])
                mask[xBounds[0]:xBounds[1], yBounds[0]:yBounds[1]] = 1
                ;; Get the array indices for the area outside of the
                ;; subvolume.
                ind = WHERE(mask eq 0, count)
                mask = 0
                if count gt 0 then begin
                    ;; Set the opacity of the area outside the subvolume
                    ;; to zero.
                    op = tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1]
                    op[ind] = 0
                    ind = 0
                    tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = TEMPORARY(op)
                endif
            endif $
            else begin
                ;; Entire slice is outside of the subvolume.
                tex[3,px:px+slicesize[0]-1,py:py+slicesize[1]-1] = 0
            endelse
        endif

        ;; Next slice
        px = px + slicesize[0]
        if (px ge nx*slicesize[0]) then begin
            px = 0
            py = py + slicesize[1]
        endif

    endfor ; slice loop

    RETURN, tex
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_ClearTexturePlanesVis
;
; PURPOSE:
;    Internal utility function to remove the set of texture mapped polygons
;    for the texture planes volume display method.
;    This is important because the texture planes are created in a "lazy"
;    fashion - only when needed for drawing.  If the volume data changes
;    (made smaller), the old planes sitting in the model can make the
;    volume seem too large when the range is computed for this vis.
;
; CALLING SEQUENCE:
;
;    self->_ClearTexturePlanesVis
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
pro IDLitVisVolume::_ClearTexturePlanesVis

    compile_opt idl2, hidden

    for i=0,5 do begin
        tmp = self._oPlaneModels[i]->Get(/ALL)
        if (SIZE(tmp,/N_DIMENSIONS) ne 0) then begin
            self._oPlaneModels[i]->Remove,tmp
            OBJ_DESTROY, tmp
        endif
    endfor

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_SetTexturePlanesVis
;
; PURPOSE:
;    Internal utility function to build a set of texture mapped polygons
;    for the texture planes volume display method.
;
; CALLING SEQUENCE:
;
;    self->_SetTexturePlanesVis
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
PRO IDLitVisVolume::_SetTexturePlanesVis, REPLICATE = replicate

    compile_opt idl2, hidden

    ;; Get the repeat factor
    mult = [1,1,1]
    if (N_ELEMENTS(replicate) eq 3) then mult = replicate
    if (N_ELEMENTS(replicate) eq 1) then mult = REPLICATE(replicate,3)

    ;; Simulate [XYZ]COORD_CONV
    oVol = self._oVolume
    oVol->GetProperty, XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs
        mat = [[xs[1],  0,   0,  xs[0]],$
               [ 0,   ys[1], 0,  ys[0]],$
               [ 0,      0,zs[1],zs[0]],$
               [ 0,      0,  0,    1  ]]

    ;; Remove polygons from the models and set COORD_CONV transform
    for i=0,5 do begin
        self._oPlaneModels[i]->IDLgrModel::SetProperty, TRANSFORM=mat
        tmp = self._oPlaneModels[i]->Get(/ALL)
        if (SIZE(tmp,/N_DIMENSIONS) ne 0) then begin
            self._oPlaneModels[i]->Remove,tmp
            OBJ_DESTROY, tmp
        endif
    endfor

    ;; Get the volume - We use NO_COPY to save space, but must restore later
    oVol->GetProperty, INTERPOLATE=interp, $
        DATA0=data0, DATA1=data1, DATA2=data2, DATA3=data3, /NO_COPY, $
        RGB_TABLE0=rgb0, RGB_TABLE1=rgb1, $
        OPACITY_TABLE0=opa0, OPACITY_TABLE1=opa1, $
        ZBUFFER=zBuffer, $
        ZERO_OPACITY_SKIP=zeroOpacitySkip

    ;; There is nothing here, so leave.
    if N_ELEMENTS(data0) eq 0 then $
        RETURN

    dim = SIZE(data0, /DIMENSION)

    ;; Build the LUTs
    tbl0 = BYTARR(3,256)
    if N_ELEMENTS(rgb0) eq 256*3 then begin
        tbl0[0,*] = rgb0[*,0]
        tbl0[1,*] = rgb0[*,1]
        tbl0[2,*] = rgb0[*,2]
    endif

    tbl1 = BYTARR(3,256)
    if N_ELEMENTS(rgb1) eq 256*3 then begin
        tbl1[0,*] = rgb1[*,0]
        tbl1[1,*] = rgb1[*,1]
        tbl1[2,*] = rgb1[*,2]
    endif

    ;; Build the planes and textures
    for axis=0,2 do begin

        ;; Compute the tiled texture
        tex = self->_BuildTexture( data0, data1, data2, data3, $
            tbl0, tbl1, opa0, opa1, axis, interp, coords)
        self._oTextures[axis]->SetProperty, DATA=tex, /NO_COPY

        ;; Set up the vert coords
        x0 = 0.0 & y0 = 0.0 & z0 = 0.0
        x1 = dim[0] & y1 = dim[1] & z1 = dim[2]
        case axis of
            0: verts = [[0,y0,z0],[0,y1,z0],[0,y1,z1],[0,y0,z1]]
            1: verts = [[x0,0,z0],[x0,0,z1],[x1,0,z1],[x1,0,z0]]
            2: verts = [[x0,y0,0],[x1,y0,0],[x1,y1,0],[x0,y1,0]]
        endcase

        oCont = OBJ_NEW('IDLgrModel')
        ;; Create the + and - set of planes
        for dir=0,1 do begin
            for x=0.0,(dim[axis]-2)*mult[axis]+1.0 do begin
                i = FLOOR(x/mult[axis])
                tc = REFORM(coords[i,*,*])
                verts[axis,*] = x/mult[axis]
                oPoly = OBJ_NEW('IDLgrPolygon', COLOR=[255,255,255], $
                    TEXTURE_COORD = tc, DATA = verts, $
                    TEXTURE_INTERP = interp, $
                    TEXTURE_MAP = self._oTextures[axis], $
                    DEPTH_TEST_DISABLE=(zBuffer eq 0) ? 1 : 0, $
                    DEPTH_WRITE_DISABLE=(zBuffer eq 0) ? 1 : 0, $
                    ZERO_OPACITY_SKIP=zeroOpacitySkip)
                oCont->Add,oPoly
            endfor
            list = oCont->Get(/ALL)
            oCont->Remove, list
            if (dir) then list = REVERSE(list)
            self._oPlaneModels[(axis*2)+dir]->Add,list
        endfor
        OBJ_DESTROY, oCont
    endfor

    ;; restore the volume data
    oVol->SetProperty, DATA0=data0, DATA1=data1, DATA2=data2, DATA3=data3, /NO_COPY
    self._bTexturePlanesDirty = 0b
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_SetBoxVis
;
; PURPOSE:
;    Internal utility function to build a semi-transparent box for a very low
;    quality texture map volume display method.
;
; CALLING SEQUENCE:
;
;    self->_SetBoxVis
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
pro IDLitVisVolume::_SetBoxVis

    compile_opt idl2, hidden

    ;; Destroy any existing objects
    list = self._oBoxModel->Get(/ALL)
    if OBJ_VALID(list) then begin
        self._oBoxModel->Remove, list
        OBJ_DESTROY, list
    endif

    ;; Determine volume extents
    self._oVolume->GetProperty, DATA0=vol, /NO_COPY
    if N_ELEMENTS(vol) eq 0 then return
    dim = SIZE(vol, /DIMENSIONS)
    self._oVolume->SetProperty, DATA0=vol, /NO_COPY

    ;; Create Polygons
    x0 = 0.0 & y0 = 0.0 & z0 = 0.0
    x1 = dim[0] & y1 = dim[1] & z1 = dim[2]
    verts = [[x0,y0,z0],[x1,y0,z0],[x1,y1,z0],[x0,y1,z0],$
             [x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]]
    self._oVolume->GetProperty, COLOR=color, ALPHA_CHANNEL=alpha
    self._oBoxPoly = OBJ_NEW('IDLgrPolygon', $
        COLOR=color, $
        ALPHA_CHANNEL=alpha, $
        DATA=verts, $
        POLYGONS=[4,0,1,2,3, 4,1,5,6,2, 4,5,4,7,6, 4,0,3,7,4, $
                  4,3,2,6,7, 4,0,4,5,1], $
        DEPTH_TEST_DISABLE=1, REJECT=1, $
        STYLE=self._renderExtents, $
        HIDE=(self._renderExtents eq 0) ? 1 : 0)
    self._oBoxModel->Add, self._oBoxPoly
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::RenderVolume
;
; PURPOSE:
;    Method to draw the volume with the IDLgrVolume ray-casting method once.
;
; CALLING SEQUENCE:
;
;    self->RenderVolume()
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
pro IDLitVisVolume::RenderVolume

    compile_opt idl2, hidden

    self._renderByButton = 1
    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        oTool->RefreshCurrentWindow
    self._renderByButton = 0
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisVolume::_RescaleVolumeData
;
; PURPOSE:
;      This procedure method takes the original volume data
;      and recales it according to the property scale values.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisVolume::]_RescaleVolumeData
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;
;-
pro IDLitVisVolume::_RescaleVolumeData

    compile_opt idl2, hidden

    oData = self->GetParameter('volume0')
    if OBJ_VALID(oData) then begin
        success = oData->GetData(data)
        if(success) then begin
            data = BYTSCL(data, MIN=self._byteScaleMin[0], MAX=self._byteScaleMax[0])
            self._oVolume->SetProperty, DATA0=data, /NO_COPY
        endif
    endif
    oData = self->GetParameter('volume1')
    if OBJ_VALID(oData) then begin
        success = oData->GetData(data)
        if(success) then begin
            data = BYTSCL(data, MIN=self._byteScaleMin[1], MAX=self._byteScaleMax[1])
            self._oVolume->SetProperty, DATA1=data, /NO_COPY
        endif
    endif
    oData = self->GetParameter('volume2')
    if OBJ_VALID(oData) then begin
        success = oData->GetData(data)
        if(success) then begin
            data = BYTSCL(data, MIN=self._byteScaleMin[2], MAX=self._byteScaleMax[2])
            self._oVolume->SetProperty, DATA2=data, /NO_COPY
        endif
    endif
    oData = self->GetParameter('volume3')
    if OBJ_VALID(oData) then begin
        success = oData->GetData(data)
        if(success) then begin
            data = BYTSCL(data, MIN=self._byteScaleMin[3], MAX=self._byteScaleMax[3])
            self._oVolume->SetProperty, DATA3=data, /NO_COPY
        endif
    endif
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisVolume::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisVolume::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisVolume::Init followed by the word "Get"
;      can be retrieved using IDLitVisVolume::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisVolume::GetProperty, $
    VISUALIZATION_PALETTE=visPalette, $
    RGB_OPAC_0=rgbOpac0, $
    RGB_OPAC_1=rgbOpac1, $
    AUTO_RENDER=autoRender, $
    BOUNDS=bounds, $
    BYTESCALE_MIN=byteScaleMin, $
    BYTESCALE_MAX=byteScaleMax, $
    EXTENTS_TRANSPARENCY=extentsTransparency, $
    NVOLUMES=nVolumes, $
    ODATA=oData, $
    RENDER_EXTENTS=renderExtents, $
    _RENDER_QUALITY=_renderQuality, $
    RENDER_QUALITY=oldRenderQuality, $
    RENDER_STEP=renderStep, $
    SUBVOLUME=subvolume, $
    VOLUME_OBJECT=volumeObject, $
    VOLUME_SELECT=volumeSelect, $
    X_RENDER_STEP=xRenderStep, $
    Y_RENDER_STEP=yRenderStep, $
    Z_RENDER_STEP=zRenderStep, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

    ;; Handle our properties.

    if (ARG_PRESENT(visPalette)) then begin
        if self._paletteNum eq 1 then $
            self._oVolume->GetProperty, RGB_TABLE1=rgb, $
                                        OPACITY_TABLE1=opa $
        else $
            self._oVolume->GetProperty, RGB_TABLE0=rgb, $
                                        OPACITY_TABLE0=opa
        visPalette = TRANSPOSE([[rgb],[opa]])
    endif

    if (ARG_PRESENT(rgbOpac0)) then begin
        self._oVolume->GetProperty, RGB_TABLE0=rgb, $
                                    OPACITY_TABLE0=opa
        rgbOpac0 = TRANSPOSE([[rgb],[opa]])
    endif

    if (ARG_PRESENT(rgbOpac1)) then begin
        self._oVolume->GetProperty, RGB_TABLE1=rgb, $
                                    OPACITY_TABLE1=opa
        rgbOpac1 = TRANSPOSE([[rgb],[opa]])
    endif

    if (ARG_PRESENT(autoRender)) then $
        autoRender = self._autoRender

    if (ARG_PRESENT(bounds)) then $
        self._oVolume->GetProperty, BOUNDS=bounds

    if (ARG_PRESENT(byteScaleMin)) then $
        byteScaleMin = self._byteScaleMin

    if (ARG_PRESENT(byteScaleMax)) then $
        byteScaleMax = self._byteScaleMax

    if (ARG_PRESENT(nVolumes)) then begin
        oData = self->GetParameter(['VOLUME0','VOLUME1','VOLUME2','VOLUME3'])
        nVolumes = N_ELEMENTS(oData)
    endif

    if (ARG_PRESENT(oData)) then $
        oData = self->GetParameter(['VOLUME0','VOLUME1','VOLUME2','VOLUME3'])

    if (ARG_PRESENT(renderExtents)) then $
        renderExtents = self._renderExtents

    ; Our self._renderQuality is one-based,
    ; and can't be changed because of BC issues.
    if (ARG_PRESENT(_renderQuality)) then $
        _renderQuality = self._renderQuality - 1

    if (ARG_PRESENT(oldRenderQuality)) then $
        oldRenderQuality = self._renderQuality

    if (ARG_PRESENT(renderStep)) then $
        self._oVolume->GetProperty, RENDER_STEP=renderStep

    if (ARG_PRESENT(xRenderStep)) then begin
        self._oVolume->GetProperty, RENDER_STEP=renderStep
        xRenderStep = renderStep[0]
    endif

    if (ARG_PRESENT(yRenderStep)) then begin
        self._oVolume->GetProperty, RENDER_STEP=renderStep
        yRenderStep = renderStep[1]
    endif

    if (ARG_PRESENT(zRenderStep)) then begin
        self._oVolume->GetProperty, RENDER_STEP=renderStep
        zRenderStep = renderStep[2]
    endif

    if (ARG_PRESENT(subvolume)) then $
        self._oVolume->GetProperty, BOUNDS=subvolume

    if ARG_PRESENT(extentsTransparency) then begin
        self._oVolume->GetProperty, ALPHA_CHANNEL=alpha
        extentsTransparency = 0 > ROUND(100 - alpha*100) < 100
    endif

    if (ARG_PRESENT(volumeObject)) then $
        volumeObject = self._oVolume

    if (ARG_PRESENT(volumeSelect)) then $
        self._oVolume->GetProperty, VOLUME_SELECT=volumeSelect

    ;; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisVolume::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisVolume::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisVolume::Init followed by the word "Set"
;      can be set using IDLitVisVolume::SetProperty.
;-
pro IDLitVisVolume::SetProperty, $
    VISUALIZATION_PALETTE=visPalette, $
    RGB_OPAC_0=rgbOpac0, $
    RGB_OPAC_1=rgbOpac1, $
    AUTO_RENDER=autoRender, $
    BOUNDS=bounds, $
    BYTESCALE_MIN=byteScaleMin, $
    BYTESCALE_MAX=byteScaleMax, $
    EXTENTS_TRANSPARENCY=extentsTransparency, $
    INTERPOLATE=interp, $
    RENDER_EXTENTS=renderExtents, $
    _RENDER_QUALITY=_renderQuality, $
    RENDER_QUALITY=oldRenderQuality, $
    RENDER_STEP=renderStep, $
    SUBVOLUME=subvolume, $
    X_RENDER_STEP=xRenderStep, $
    Y_RENDER_STEP=yRenderStep, $
    Z_RENDER_STEP=zRenderStep, $
    _REF_EXTRA=_extra

  compile_opt idl2, hidden

    regen = 0

    ;; Handle our properties.

    if (N_ELEMENTS(visPalette) gt 0) then begin
        if self._paletteNum eq 1 then begin
            self._oVolume->SetProperty, $
                RGB_TABLE1=TRANSPOSE(visPalette[0:2,*]), $
                OPACITY_TABLE1=visPalette[3,*]
            oPal = self->GetParameter('RGB_TABLE1')
            if OBJ_VALID(oPal) then $
                success = oPal->SetData(visPalette[0:2,*])
            oOpac = self->GetParameter('OPACITY_TABLE1')
            if OBJ_VALID(oOpac) then $
                success = oOpac->SetData(visPalette[3,*])
        endif $
        else begin
            self._oVolume->SetProperty, $
                RGB_TABLE0=TRANSPOSE(visPalette[0:2,*]), $
                OPACITY_TABLE0=visPalette[3,*]
            oPal = self->GetParameter('RGB_TABLE0')
            if OBJ_VALID(oPal) then $
                success = oPal->SetData(visPalette[0:2,*])
            oOpac = self->GetParameter('OPACITY_TABLE0')
            if OBJ_VALID(oOpac) then $
                success = oOpac->SetData(visPalette[3,*])
        endelse
        regen=1
    endif

    if (N_ELEMENTS(rgbOpac0) gt 0) then begin
        self._oVolume->SetProperty, $
            RGB_TABLE0=TRANSPOSE(rgbOpac0[0:2,*]), $
            OPACITY_TABLE0=rgbOpac0[3,*]
        oPal = self->GetParameter('RGB_TABLE0')
        if OBJ_VALID(oPal) then $
            success = oPal->SetData(rgbOpac0[0:2,*])
        oOpac = self->GetParameter('OPACITY_TABLE0')
        if OBJ_VALID(oOpac) then $
            success = oOpac->SetData(rgbOpac0[3,*])
        regen=1
    endif

        if (N_ELEMENTS(rgbOpac1) gt 0) then begin
        self._oVolume->SetProperty, $
            RGB_TABLE1=TRANSPOSE(rgbOpac1[0:2,*]), $
            OPACITY_TABLE1=rgbOpac1[3,*]
        oPal = self->GetParameter('RGB_TABLE1')
        if OBJ_VALID(oPal) then $
            success = oPal->SetData(rgbOpac1[0:2,*])
        oOpac = self->GetParameter('OPACITY_TABLE1')
        if OBJ_VALID(oOpac) then $
            success = oOpac->SetData(rgbOpac1[3,*])
        regen=1
    endif

    if (N_ELEMENTS(autoRender) gt 0) then $
        self._autoRender = autoRender

    if (N_ELEMENTS(byteScaleMin) gt 0) then begin
        self._byteScaleMin = byteScaleMin
        self->_RescaleVolumeData
        regen = 1
    endif

    if (N_ELEMENTS(byteScaleMax) gt 0) then begin
        self._byteScaleMax = byteScaleMax
        self->_RescaleVolumeData
        regen = 1
    endif

    if (N_ELEMENTS(interp) gt 0) then begin
        ;; trap this property so we can send notification.
        self._oVolume->SetProperty, INTERPOLATE=interp
        self->DoOnNotify, self->GetFullIdentifier(), 'INTERPOLATE', ''
        regen = 1
    endif

    if (N_ELEMENTS(renderExtents) gt 0) then begin
        self._renderExtents = renderExtents
        regen = 1
    endif

    ; Our self._renderQuality is one-based,
    ; and can't be changed because of BC issues.
    if (N_ELEMENTS(_renderQuality) gt 0) then $
        oldRenderQuality = _renderQuality + 1

    if (N_ELEMENTS(oldRenderQuality) gt 0) then begin
        self._renderQuality = oldRenderQuality
        if (self._renderQuality le 1) then begin ; low
            self._oPlaneContainer->SetProperty, HIDE=0
            self._oVolume->SetProperty, HIDE=1
        endif else begin ; high
            self._oPlaneContainer->SetProperty, HIDE=1
            self._oVolume->SetProperty, HIDE=0
        endelse

        self->SetPropertyAttribute, $
            ['AMBIENT', $
             'COMPOSITE_FUNCTION', $
             'HINTS', $
             'LIGHTING_MODEL', $
             'TWO_SIDED', $
             'X_RENDER_STEP', $
             'Y_RENDER_STEP', $
             'Z_RENDER_STEP'], $
            SENSITIVE=(self._renderQuality eq 2)
    endif

    if (N_ELEMENTS(renderStep) gt 0) then $
        self._oVolume->SetProperty, RENDER_STEP=renderStep

    if (N_ELEMENTS(xRenderStep) || N_ELEMENTS(yRenderStep) || $
        N_ELEMENTS(zRenderStep)) then begin
        self._oVolume->GetProperty, RENDER_STEP=renderStep
        oldRenderStep = renderStep
        if (N_ELEMENTS(xRenderStep) && xRenderStep ge 1) then $
            renderStep[0] = xRenderStep
        if (N_ELEMENTS(yRenderStep) && yRenderStep ge 1) then $
            renderStep[1] = yRenderStep
        if (N_ELEMENTS(zRenderStep) && zRenderStep ge 1) then $
            renderStep[2] = zRenderStep
        if (~ARRAY_EQUAL(oldRenderStep, renderStep)) then $
            self._oVolume->SetProperty, RENDER_STEP=renderStep
    endif

    if (N_ELEMENTS(bounds) eq 6 && ~ARRAY_EQUAL(bounds, REPLICATE(0,6))) then begin
        self._subvolume = bounds
        self._oVolume->SetProperty, BOUNDS=bounds
        regen = 1
    endif
    if (N_ELEMENTS(subvolume) eq 6 && ~ARRAY_EQUAL(subvolume, REPLICATE(0,6))) then begin
        self._subvolume = subvolume
        self._oVolume->SetProperty, BOUNDS=subvolume
        regen = 1
    endif

    if (N_ELEMENTS(extentsTransparency)) then begin
        self._oVolume->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-extentsTransparency)/100) < 1
        regen = 1
    endif

    ;; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitVisualization::SetProperty, _EXTRA=_extra
        regen = 1
    endif

    ;; Regenerate texture maps to reflect any changes
    if regen gt 0 then begin
        self->_SetBoxVis
        self._bTexturePlanesDirty = 1b
        if self._autoRender ne 0 then begin
            oTool = self->GetTool()
            if (OBJ_VALID(oTool)) then $
                oTool->RefreshCurrentWindow
        endif
    endif
end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to retrieve the data from the grVolume
;
; Arguments:
;   VOL1, VOL2, VOL3, VOL4
;
; Keywords:
;   NONE
;
pro IDLitVisVolume::GetData, vol1, vol2, vol3, vol4, _EXTRA=_extra
  compile_opt idl2, hidden
  
  oVol = self->GetParameter('VOLUME0')
  if (OBJ_VALID(oVol)) then $
    void = oVol->GetData(vol1)
  oVol = self->GetParameter('VOLUME1')
  if (OBJ_VALID(oVol)) then $
    void = oVol->GetData(vol2)
  oVol = self->GetParameter('VOLUME2')
  if (OBJ_VALID(oVol)) then $
    void = oVol->GetData(vol3)
  oVol = self->GetParameter('VOLUME3')
  if (OBJ_VALID(oVol)) then $
    void = oVol->GetData(vol4)

end


;----------------------------------------------------------------------------
; Purpose:
;   This method is used to directly set the data
;
; Arguments:
;   VOL1, VOL2, VOL3, VOL4
;
; Keywords:
;   NONE
;
pro IDLitVisVolume::PutData, vol1, vol2, vol3, vol4, _EXTRA=_extra
  compile_opt idl2, hidden
  
  switch N_PARAMS() of
    4 : begin
          oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol4, NAME='Volume3', $
                             /AUTO_DELETE)
          self->SetParameter, 'VOLUME3', oDataVol
          oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol3, NAME='Volume2', $
                             /AUTO_DELETE)
          self->SetParameter, 'VOLUME2', oDataVol
        end
    2 : begin
          oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol2, NAME='Volume1', $
                             /AUTO_DELETE)
          self->SetParameter, 'VOLUME1', oDataVol
        end
    1 : begin
          oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol1, NAME='Volume0', $
                             /AUTO_DELETE)
          self->SetParameter, 'VOLUME0', oDataVol
        end
    else :
  endswitch

  oTool = self->GetTool()
  if (OBJ_VALID(oTool)) then $
    oTool->RefreshCurrentWindow
  
end


;----------------------------------------------------------------------------
function IDLitVisVolume::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'RGB_OPAC_0': begin
        self._paletteNum=0
        success = oTool->DoUIService('PaletteEditor', self)
        if success then $
            return, 1
    end

    'RGB_OPAC_1': begin
        self._paletteNum=1
        success = oTool->DoUIService('PaletteEditor', self)
        if success then $
            return, 1
    end

    'DISPLAY_SCALE': begin
        success = oTool->DoUIService('DataBottomTop', self)
        if success then $
            return, 1
    end

    'SUBVOLUME': begin
        success = oTool->DoUIService('Subvolume', self)
        if success then $
            return, 1
    end

    else:

    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end

;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;; IDLitVisVolume::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the volume.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
pro IDLitVisVolume::OnDataDisconnect, ParmName

    compile_opt hidden, idl2

    switch STRUPCASE(parmname) of
    'VOLUME0':
    'VOLUME1':
    'VOLUME2':
    'VOLUME3': begin

        ;; Get our "good" data out of the volume
        ;; This is a disconnect, so we'll put some of it back
        self._oVolume->GetProperty, DATA0=data0, DATA1=data1, $
                                    DATA2=data2, DATA3=data3, /NO_COPY

        ;; Figure out what parms are still connected.
        ;; Those are the parms we'll put back.
        oData = OBJARR(4)
        oData[0] = self->GetParameter(['VOLUME0'])
        oData[1] = self->GetParameter(['VOLUME1'])
        oData[2] = self->GetParameter(['VOLUME2'])
        oData[3] = self->GetParameter(['VOLUME3'])

        ;; Mark the parm being disconnected as invalid.
        case STRUPCASE(parmname) of
        'VOLUME0': oData[0] = OBJ_NEW()
        'VOLUME1': oData[1] = OBJ_NEW()
        'VOLUME2': oData[2] = OBJ_NEW()
        'VOLUME3': oData[3] = OBJ_NEW()
        endcase

        valid = OBJ_VALID(oData)

        ;; Put back the data just for the connected parms.
        case 1 of
        ARRAY_EQUAL(valid, [0,0,0,0]): begin
            ;; All volume data has been disconnected.
            volumeSelect = 0
        end
        ARRAY_EQUAL(valid, [1,0,0,0]): begin
            volumeSelect = 0
            self._oVolume->SetProperty, DATA0=data0, /NO_COPY
        end
        ARRAY_EQUAL(valid, [1,1,0,0]): begin
            volumeSelect = 1
            self._oVolume->SetProperty, DATA0=data0, DATA1=data1, /NO_COPY
        end
        ARRAY_EQUAL(valid, [1,1,1,1]): begin
            volumeSelect = 2
            self._oVolume->SetProperty, DATA0=data0, DATA1=data1, $
                                        DATA2=data2, DATA3=data3, /NO_COPY
        end
        else: begin
            ;; Invalid combination.  Just put the data back the way it was and
            ;; hope things will sort out.  We can't throw an error here because
            ;; this may be one of of several disconnects and we may get to a valid state
            ;; after the last disconnect.
            self._oVolume->GetProperty, VOLUME_SELECT=volumeSelect
            self._oVolume->SetProperty, DATA0=data0, DATA1=data1, DATA2=data2, DATA3=data3, /NO_COPY
        end
        endcase

        ;; Update volume and misc other items
        self._oVolume->SetProperty, VOLUME_SELECT=volumeSelect
        self->DoOnNotify, self->GetFullIdentifier(), 'VOLUMESELECT', volumeSelect
        self._oVolume->ComputeBounds, /RESET
        self->SetPropertyAttribute, 'RGB_OPAC_1', SENSITIVE=(volumeSelect eq 1)
        self->_ClearTexturePlanesVis
        break
    end
    'RGB_TABLE0': begin
        self._oVolume->SetProperty, RGB_TABLE0=$
            [[BINDGEN(256)],[BINDGEN(256)],[BINDGEN(256)]]
        break
    end
    'RGB_TABLE1': begin
        self._oVolume->SetProperty, RGB_TABLE1=$
            [[BINDGEN(256)],[BINDGEN(256)],[BINDGEN(256)]]
        break
    end
    'OPACITY_TABLE0': begin
        self._oVolume->SetProperty, OPACITY_TABLE0=BINDGEN(256)
        break
    end
    'OPACITY_TABLE1': begin
        self._oVolume->SetProperty, OPACITY_TABLE1=BINDGEN(256)
        break
    end
    'VOLUME_DIMENSIONS': begin
        self->Scale, 1/self._dimensions[0], 1/self._dimensions[1], $
            1/self._dimensions[2], CENTER_OF_ROTATION=[0,0,0]
        self._dimensions = [1,1,1]
        break
    end
    'VOLUME_LOCATION': begin
        self->Translate, -self._location[0], -self._location[1], -self._location[2]
        self._location = [0,0,0]
        break
    end
    'SUBVOLUME': begin
        self._oVolume->ComputeBounds, /RESET
        self->_ClearTexturePlanesVis
    end
    else:
    endswitch

    ;; Update default very low quality visualization
    self->_SetBoxVis

    ;; Mark Texture Planes visualization as dirty
    self._bTexturePlanesDirty = 1b
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_ProcessVolumeParameters
;
; PURPOSE:
;    Internal utility routine to process volume parms
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisVolume::]_ProcessVolumeParameters
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;    QUIET - don't throw a message.  This is useful when processing
;    single (not in a parm set) vol parms because a series of parm
;    data changes may be in progress and we may be in a temporary
;    invalid state.
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-

pro IDLitVisVolume::_ProcessVolumeParameters, QUIET=quiet

    compile_opt idl2, hidden

    ;; Figure out what parms are provided.
    oVols = OBJARR(4)
    oVols[0] = self->GetParameter(['VOLUME0'])
    oVols[1] = self->GetParameter(['VOLUME1'])
    oVols[2] = self->GetParameter(['VOLUME2'])
    oVols[3] = self->GetParameter(['VOLUME3'])
    valid = OBJ_VALID(oVols)

    byteScaleMin = DBLARR(4)
    byteScaleMax = DBLARR(4)
    volumeSelect = 0
    bOK = 0

    case 1 of
    ARRAY_EQUAL(valid, [0,0,0,0]): begin
        ;; No data is a valid condition
        ;; But we don't need to do anything
        bOK = 1
    end
    ARRAY_EQUAL(valid, [1,0,0,0]): begin
        success0 = oVols[0]->GetData(pData0, /POINTER, NAN=nan)
        if success0 and $
           WHERE(SIZE(*pData0, /TYPE) eq [7,8,10,11]) eq -1 then begin
            byteScaleMin[0] = MIN(*pData0, MAX=m, NAN=nan)
            byteScaleMax[0] = m
            self._byteScaleMin[*] = byteScaleMin[0]
            self._byteScaleMax[*] = byteScaleMax[0]
            data0 = BYTSCL(*pData0, MIN=self._byteScaleMin[0], $
                MAX=self._byteScaleMax[0], NAN=nan)
            q = !QUIET
            !QUIET = 1
            self._oVolume->SetProperty, DATA0=data0, /NO_COPY
            !QUIET = q
            volumeSelect = 0
            bOK = 1
        endif
    end
    ARRAY_EQUAL(valid, [1,1,0,0]): begin
        success0 = oVols[0]->GetData(pData0, /POINTER, NAN=nan0)
        success1 = oVols[1]->GetData(pData1, /POINTER, NAN=nan1)
        dims0 = SIZE(*pData0, /DIMENSIONS)
        dims1 = SIZE(*pData1, /DIMENSIONS)
        if success0 and success1 and $
           ARRAY_EQUAL(dims0, dims1) and $
           WHERE(SIZE(*pData0, /TYPE) eq [7,8,10,11]) eq -1 and $
           WHERE(SIZE(*pData1, /TYPE) eq [7,8,10,11]) eq -1 then begin
            byteScaleMin[0] = MIN(*pData0, MAX=m, NAN=nan0)
            byteScaleMax[0] = m
            byteScaleMin[1] = MIN(*pData1, MAX=m, NAN=nan1)
            byteScaleMax[1] = m
            self._byteScaleMin[*] = MIN(byteScaleMin[0:1])
            self._byteScaleMax[*] = MAX(byteScaleMax[0:1])
            data0 = BYTSCL(*pData0, MIN=self._byteScaleMin[0], $
                MAX=self._byteScaleMax[0], NAN=nan0)
            data1 = BYTSCL(*pData1, MIN=self._byteScaleMin[1], $
                MAX=self._byteScaleMax[1], NAN=nan1)
            q = !QUIET
            !QUIET = 1
            self._oVolume->SetProperty, DATA0=data0, DATA1=data1, /NO_COPY
            !QUIET = q
            volumeSelect = 1
            bOK = 1
        endif
    end
    ARRAY_EQUAL(valid, [1,1,1,1]): begin
        success0 = oVols[0]->GetData(pData0, /POINTER, NAN=nan0)
        success1 = oVols[1]->GetData(pData1, /POINTER, NAN=nan1)
        success2 = oVols[2]->GetData(pData2, /POINTER, NAN=nan2)
        success3 = oVols[3]->GetData(pData3, /POINTER, NAN=nan3)
        dims0 = SIZE(*pData0, /DIMENSIONS)
        dims1 = SIZE(*pData1, /DIMENSIONS)
        dims2 = SIZE(*pData2, /DIMENSIONS)
        dims3 = SIZE(*pData3, /DIMENSIONS)
        if success0 and success1 and success2 and success3 and $
           ARRAY_EQUAL(dims0, dims1) and $
           ARRAY_EQUAL(dims0, dims2) and $
           ARRAY_EQUAL(dims0, dims3) and $
           WHERE(SIZE(*pData0, /TYPE) eq [7,8,10,11]) eq -1 and $
           WHERE(SIZE(*pData1, /TYPE) eq [7,8,10,11]) eq -1 and $
           WHERE(SIZE(*pData2, /TYPE) eq [7,8,10,11]) eq -1 and $
           WHERE(SIZE(*pData3, /TYPE) eq [7,8,10,11]) eq -1 then begin
            byteScaleMin[0] = MIN(*pData0, MAX=m, NAN=nan0)
            byteScaleMax[0] = m
            byteScaleMin[1] = MIN(*pData1, MAX=m, NAN=nan1)
            byteScaleMax[1] = m
            byteScaleMin[2] = MIN(*pData2, MAX=m, NAN=nan2)
            byteScaleMax[2] = m
            byteScaleMin[3] = MIN(*pData3, MAX=m, NAN=nan3)
            byteScaleMax[3] = m
            self._byteScaleMin[*] = MIN(byteScaleMin[0:3])
            self._byteScaleMax[*] = MAX(byteScaleMax[0:3])
            data0 = BYTSCL(*pData0, MIN=self._byteScaleMin[0], $
                MAX=self._byteScaleMax[0], NAN=nan0)
            data1 = BYTSCL(*pData1, MIN=self._byteScaleMin[1], $
                MAX=self._byteScaleMax[1], NAN=nan1)
            data2 = BYTSCL(*pData2, MIN=self._byteScaleMin[2], $
                MAX=self._byteScaleMax[2], NAN=nan2)
            data3 = BYTSCL(*pData3, MIN=self._byteScaleMin[3], $
                MAX=self._byteScaleMax[3], NAN=nan3)
            q = !QUIET
            !QUIET = 1
            self._oVolume->SetProperty, DATA0=data0, DATA1=data1, $
                DATA2=data2, DATA3=data3, /NO_COPY
            !QUIET = q
            volumeSelect = 2
            bOK = 1
        endif
    end
    else: begin
    end
    endcase

    if (~bOK && ~KEYWORD_SET(quiet)) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Message:InvalidVolDataParms:Text')], $
            severity=0, $
            TITLE=IDLitLangCatQuery('Message:InvalidVolDataParms:Title')
        self._oVolume->SetProperty, COMPOSITE_FUNCTION=0
    endif

    self._oVolume->ComputeBounds, /RESET
    if self._subvolume[0] ne -1 then $
        self._oVolume->SetProperty, BOUNDS=self._subvolume
    self._oVolume->GetProperty, VOLUME_SELECT=oldVolumeSelect
    if oldVolumeSelect ne volumeSelect then begin
        self._oVolume->SetProperty, VOLUME_SELECT=volumeSelect
        self->DoOnNotify, self->GetFullIdentifier(), 'VOLUMESELECT', volumeSelect
    endif

    ;; Sensitize 2nd color/opacity table only if in 2-channel mode
    self->SetPropertyAttribute, 'RGB_OPAC_1', SENSITIVE=ARRAY_EQUAL(valid, [1,1,0,0])
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_CreateDefaultTables
;
; PURPOSE:
;    Internal utility routine to create color and opacity tables
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisVolume::]_CreateDefaultTables
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-

pro IDLitVisVolume::_CreateDefaultTables

    compile_opt idl2, hidden

    ;; Create default color and opacity tables for user if none were provided.
    oData = self->GetParameter('RGB_TABLE0')
    if not OBJ_VALID(oData) then begin
        pal = TRANSPOSE([[BINDGEN(256)], [BINDGEN(256)], [BINDGEN(256)]])
        oData = OBJ_NEW('IDLitDataIDLPalette', pal, NAME="RGB Table 0")
        success = self->SetData(oData, PARAMETER_NAME='RGB_TABLE0', /BY_VALUE)
    endif

    oData = self->GetParameter('OPACITY_TABLE0')
    if not OBJ_VALID(oData) then begin
        oData = OBJ_NEW('IDLitData', TYPE='IDLOPACITY_TABLE', BINDGEN(256), $
            NAME='Opacity Table 0', ICON='layer')
        success = self->SetData(oData, PARAMETER_NAME='OPACITY_TABLE0', $
            /BY_VALUE)
    endif

    self._oVolume->GetProperty, VOLUME_SELECT=volumeSelect
    if volumeSelect eq 1 then begin
        oData = self->GetParameter('RGB_TABLE1')
        if not OBJ_VALID(oData) then begin
            pal = TRANSPOSE([[BINDGEN(256)], [BINDGEN(256)], [BINDGEN(256)]])
            oData = OBJ_NEW('IDLitDataIDLPalette', pal, NAME="RGB Table 1")
            success = self->SetData(oData, PARAMETER_NAME='RGB_TABLE1', $
                /BY_VALUE)
        endif

        oData = self->GetParameter('OPACITY_TABLE1')
        if not OBJ_VALID(oData) then begin
            oData = OBJ_NEW('IDLitData', TYPE='IDLOPACITY_TABLE', BINDGEN(256), $
                NAME='Opacity Table 1', ICON='layer')
            success = self->SetData(oData, PARAMETER_NAME='OPACITY_TABLE1', $
                /BY_VALUE)
        endif
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrVolume object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisVolume::]OnDataChangeUpdate, oSubject
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the volume) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then, it puts the data in the IDLgrVolume object.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-

pro IDLitVisVolume::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmName) of

        '<PARAMETER SET>':begin

            ;; It is a little more efficient to handle the volume datasets as a group
            self->_ProcessVolumeParameters

            ;; Process non-volume parms
            parmNames = ['RGB_TABLE0','RGB_TABLE1','OPACITY_TABLE0','OPACITY_TABLE1',$
                         'VOLUME_DIMENSIONS', 'VOLUME_LOCATION', 'SUBVOLUME']
            for i=0,N_ELEMENTS(parmNames)-1 do begin
                oData = oSubject->GetByName(parmNames[i], count=nCount)
                if ncount ne 0 then self->OnDataChangeUpdate,oData,parmNames[i]
            endfor

            ;; Create any needed color and opacity tables.
            self->_CreateDefaultTables
        end

        'VOLUME0': begin
            self->_ProcessVolumeParameters, /QUIET
            self->_CreateDefaultTables
        end

        'VOLUME1': begin
            self->_ProcessVolumeParameters, /QUIET
            self->_CreateDefaultTables
        end

        'VOLUME2': begin
            self->_ProcessVolumeParameters, /QUIET
            self->_CreateDefaultTables
        end

        'VOLUME3': begin
            self->_ProcessVolumeParameters, /QUIET
            self->_CreateDefaultTables
        end

        'RGB_TABLE0': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [3,256]) then begin
                self._oVolume->SetProperty, RGB_TABLE0=TRANSPOSE(data)
            end
        end

        'RGB_TABLE1': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [3,256]) then begin
                self._oVolume->SetProperty, RGB_TABLE1=TRANSPOSE(data)
            end
        end

        'OPACITY_TABLE0': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [256]) then begin
                self._oVolume->SetProperty, OPACITY_TABLE0=data
            end
        end

        'OPACITY_TABLE1': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [256]) then begin
                self._oVolume->SetProperty, OPACITY_TABLE1=data
            end
        end

        'VOLUME_DIMENSIONS': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [3]) then begin
                oVolData = self->GetParameter('VOLUME0')
                if WHERE(data eq 0) eq -1 and OBJ_VALID(oVolData) then begin
                    success = oVolData->GetData(pVol, /POINTER)
                    volDims = SIZE(*pVol, /DIMENSIONS)
                    data = DOUBLE(data)
                    self->Scale, 1/self._dimensions[0], 1/self._dimensions[1], $
                        1/self._dimensions[2], CENTER_OF_ROTATION=[0,0,0]
                    data[0] /= volDims[0]
                    data[1] /= volDims[1]
                    data[2] /= volDims[2]
                    self._dimensions=data
                    self->Scale, self._dimensions[0], self._dimensions[1], $
                        self._dimensions[2], CENTER_OF_ROTATION=[0,0,0]
                endif
            end
        end

        'VOLUME_LOCATION': begin
            success = oSubject->GetData(data)
            dims = SIZE(data, /DIMENSIONS)
            if success and ARRAY_EQUAL(dims, [3]) then begin
                self->Translate, -self._location[0], -self._location[1], -self._location[2]
                self._location=data
                self->Translate, self._location[0], self._location[1], self._location[2]
            end
        end

        'SUBVOLUME': begin
            success = oSubject->GetData(data)
            if success ne 0 and N_ELEMENTS(data) eq 6 then begin
                self._oVolume->SetProperty, BOUNDS=data
            end
        end

        else:
    endcase

    ;; Update default very low quality visualization
    self->_SetBoxVis

    ;; Mark Texture Planes visualization as dirty
    self->_ClearTexturePlanesVis
    self._bTexturePlanesDirty = 1b

    ; Let these show up again in the property sheet.
    ; They were hidden at startup so that they would not
    ; show up in the style sheet.
    self->SetPropertyAttribute, ['DISPLAY_SCALE', $
                                 'RGB_OPAC_0', $
                                 'RGB_OPAC_1', $
                                 'SUBVOLUME' $
                                ], HIDE=0

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::_isGrayscale
;
; PURPOSE:
;    Internal utility routine to determine if a palette is greyscale
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisVolume::]_isGrayscale
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-
function IDLitVisVolume::_isGrayscale, pal

    compile_opt idl2, hidden

    return, ARRAY_EQUAL(pal[*,0], pal[*,1]) and ARRAY_EQUAL(pal[*,0], pal[*,2])
end
;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::Draw
;
; PURPOSE:
;    Overrides the Draw method so that we can draw the volume with
;    either the texture map method or the IDLgrVolume volume rendering method.
;
; CALLING SEQUENCE:
;    Don't call this; let the destination object (window) call it.
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-
pro IDLitVisVolume::Draw, dest, view

    compile_opt idl2, hidden

    dest->GetProperty, IS_LIGHTING=isLighting, $
        IS_SELECTING=is_selecting, $
        IS_BANDING=is_banding

    if (isLighting) then begin
        self->IDLitVisualization::Draw, dest, view
        return
    endif

    ;; If we are selecting we need to hide the planes and draw the
    ;; volume so that the volume gets hit.
    if (is_selecting) then begin
        self._oVolume->GetProperty, HIDE=hide
        self._oPlaneContainer->GetProperty, HIDE=hidePlanes
        self._oVolume->SetProperty, HIDE=0
        self._oPlaneContainer->SetProperty, HIDE=1
        self->IDLitVisualization::Draw, dest, view
        self._oVolume->SetProperty, HIDE=hide
        self._oPlaneContainer->SetProperty, HIDE=hidePlanes
        return
    endif

    ;; If we're told to not render or print the volume, then we must still
    ;; render our visualization, to draw the extents.
    ;; Hide our volume representations, draw, and then put things back.
    ; If we are not a Window then assume that we always want to render,
    ; say to export to a file or to print.
    if (~self._renderByButton && ~self._autoRender && $
        ~is_banding && OBJ_ISA(dest, 'IDLgrWindow')) then begin
        self._oPlaneContainer->GetProperty, HIDE=hidePlanes
        self._oVolume->GetProperty, HIDE=hideVol
        self._oPlaneContainer->SetProperty, HIDE=1
        self._oVolume->SetProperty, HIDE=1
        self->IDLitVisualization::Draw, dest, view
        self._oPlaneContainer->SetProperty, HIDE=hidePlanes
        self._oVolume->SetProperty, HIDE=hideVol
        return
    endif

    ;; Draw/Print Volume with stacked textures.
    if (self._renderQuality le 1) then begin

        ;; Update/Create texture map rendition of the volume
        if self._bTexturePlanesDirty then begin
            self->_SetTexturePlanesVis
        endif

        ;; Hide all the planes until we figure out which ones we want.
        for idx=0, 5 do $
            self._oPlaneModels[idx]->SetProperty, HIDE=1
        ;; Figure out which set of planes to unhide based on vector to the screen
        tm = self->GetCTM()
        tm = TRANSPOSE(INVERT(tm, status))  ; To transform a normal
        pt = FLTARR(3)
        n = FLTARR(4)
        n = [1,0,0,0]
        n = n # tm
        if (n[3] ne 0.0) then begin
            sign = n[3] gt 0 ? 1 : -1
            n = n / n[3] * sign
        end
        n = n / SQRT(TOTAL(n * n))
        pt[0] = n[2]

        n = [0,1,0,0]
        n = n # tm
        if (n[3] ne 0.0) then begin
            sign = n[3] gt 0 ? 1 : -1
            n = n / n[3] * sign
        end
        n = n / SQRT(TOTAL(n * n))
        pt[1] = n[2]

        n = [0,0,1,0]
        n = n # tm
        if (n[3] ne 0.0) then begin
            sign = n[3] gt 0 ? 1 : -1
            n = n / n[3] * sign
        end
        n = n / SQRT(TOTAL(n * n))
        pt[2] = n[2]

        ; Based on sign, pick between the + and - cases
        if (pt[2] lt 0.0) then idx = 5 else idx = 4
        if ((ABS(pt[0]) gt ABS(pt[1])) and (ABS(pt[0]) gt ABS(pt[2]))) then begin
            if (pt[0] lt 0.0) then idx = 1 else idx = 0
        endif
        if ((ABS(pt[1]) gt ABS(pt[0])) and (ABS(pt[1]) gt ABS(pt[2]))) then begin
            if (pt[1] lt 0.0) then idx = 3 else idx = 2
        endif
        ;; Enable the desired planes
        self._oPlaneModels[idx]->SetProperty,HIDE=0
        self->IDLitVisualization::Draw, dest, view
        return
    endif

    ;; Draw/Print Volume using IDLgrVolume
    if (self._renderQuality eq 2) then begin

        ;; Need to check for invalid IDLgrVolume cases
        bOK = 1b
        self._oVolume->GetProperty, COMPOSITE_FUNCTION=cf, $
            VOLUME_SELECT=volumeSelect, RGB_TABLE0=rgb0, $
            RGB_TABLE1=rgb1
        ;; Can't have Average Intensity and colors in the LUTs
        if cf eq 3 then begin
            case volumeSelect of
            0: if ~self->_isGrayscale(rgb0) then bOK=0
            1: if (~self->_isGrayscale(rgb0)) || (~self->_isGrayscale(rgb1)) then bOK = 0
            2: bOK = 0
            endcase
            if ~bOK then begin
              self->ErrorMessage, $
                IDLitLangCatQuery(['Error:InvalidVolRendParms:Text1', $
                                   'Error:InvalidVolRendParms:Text2', $
                                   'Error:InvalidVolRendParms:Text3']), $
                severity=0, $
                TITLE=IDLitLangCatQuery('Error:InvalidVolRendParms:Title')
              self._oVolume->SetProperty, COMPOSITE_FUNCTION=0
              ;; Reflect change in property sheet.
              self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
            endif
        endif

        ;; Draw if OK
        if bOK then $
            self->IDLitVisualization::Draw, dest, view
    endif
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisVolume::GetDataString
;
; PURPOSE:
;    Convert XYZ dataspace coordinates into display string.
;    Also probe for voxel value(s) and place into string.
;
; CALLING SEQUENCE:
;    Called by mouse motion manipulator
;
; INPUTS:
;    3 element XYZ dataspace vector
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;    Returns string to display
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:

; EXAMPLE:
;
;-
;---------------------------------------------------------------------------
; Convert XYZ dataspace coordinates into actual data values.
;
function IDLitVisVolume::GetDataString, xyz

    compile_opt idl2, hidden

    ;; ZBUFFER must be on in the volume for this to work.
    self._oVolume->GetProperty, ZBUFFER=Zon
    if not Zon then begin
        value = "Voxel:(<no Z buffer data>)"
    endif $
    else begin
        ;; Get mouse window coords, window and view
        self->VisToWindow, xyz, w
        oTool = self->GetTool()
        oWin = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, ''
        oView = oWin->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        ;; Get volume voxel index of picked voxel
        voxelIndex = self._oVolume->PickVoxel(oWin, oLayer, w[0:1])
        ;; Didn't hit a non-zero voxel
        if ARRAY_EQUAL(voxelIndex, [-1,-1,-1]) then begin
            value = "Voxel:(<transparent>)"
        endif $
        ;; Proceed if we hit a voxel
        else begin
            sxyz = STRTRIM(STRING(xyz, FORMAT='(I6)'),2)
            value = STRING(sxyz, FORMAT='("Voxel:(",A,",",A,",",A,")")')
            ;; Handle volume data channel combinations
            oVols = OBJARR(4)
            oVols[0] = self->GetParameter('VOLUME0')
            oVols[1] = self->GetParameter('VOLUME1')
            oVols[2] = self->GetParameter('VOLUME2')
            oVols[3] = self->GetParameter('VOLUME3')
            valid = OBJ_VALID(oVols)
            case 1 of
                ARRAY_EQUAL(valid, [1,0,0,0]): begin
                    success = oVols[0]->GetData(pData, /POINTER)
                    if success then begin
                        voxel = (*pData)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        svoxel = STRING(voxel, FORMAT='(G0)')
                        value = value + STRING(svoxel, FORMAT='("  Value:",A)')
                    endif
                end
                ARRAY_EQUAL(valid, [1,1,0,0]): begin
                    success0 = oVols[0]->GetData(pData0, /POINTER)
                    success1 = oVols[1]->GetData(pData1, /POINTER)
                    dims0 = SIZE(*pData0, /DIMENSIONS)
                    dims1 = SIZE(*pData1, /DIMENSIONS)
                    if success0 and success1 and $
                       ARRAY_EQUAL(dims0, dims1) then begin
                        voxel0 = (*pData0)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        voxel1 = (*pData1)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        svoxel = STRING(voxel0, voxel1, FORMAT='(G0,",",G0)')
                        value = value + STRING(svoxel, FORMAT='("  Value:(",A,")")')
                    endif
                end
                ARRAY_EQUAL(valid, [1,1,1,1]): begin
                    success0 = oVols[0]->GetData(pData0, /POINTER)
                    success1 = oVols[1]->GetData(pData1, /POINTER)
                    success2 = oVols[2]->GetData(pData2, /POINTER)
                    success3 = oVols[3]->GetData(pData3, /POINTER)
                    dims0 = SIZE(*pData0, /DIMENSIONS)
                    dims1 = SIZE(*pData1, /DIMENSIONS)
                    dims2 = SIZE(*pData2, /DIMENSIONS)
                    dims3 = SIZE(*pData3, /DIMENSIONS)
                    if success0 and success1 and success2 and success3 and $
                       ARRAY_EQUAL(dims0, dims1) and $
                       ARRAY_EQUAL(dims0, dims2) and $
                       ARRAY_EQUAL(dims0, dims3) then begin
                        voxel0 = (*pData0)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        voxel1 = (*pData1)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        voxel2 = (*pData2)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        voxel3 = (*pData3)[voxelIndex[0], voxelIndex[1], voxelIndex[2]]
                        svoxel = STRING(voxel0, voxel1, voxel2, voxel3, $
                            FORMAT='(G0,",",G0,",",G0,",",G0)')
                        value = value + STRING(svoxel, FORMAT='("  Value:(",A,")")')
                    endif
                end
            else:
            endcase
        endelse
    endelse
    return, value

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisVolume__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisVolume object.
;
;-
pro IDLitVisVolume__Define

    compile_opt idl2, hidden

    struct = { IDLitVisVolume,            $
            inherits IDLitVisualization,  $
            _autoRender: 0b,              $     ; 1 = render volume in Draw method
            _bTexturePlanesDirty: 0b,     $     ; dirty flag for updating texture planes
            _byteScaleMin: DBLARR(4),     $     ; byte scale values - one for each volume
            _byteScaleMax: DBLARR(4),     $     ; byte scale values - one for each volume
            _dimensions: DBLARR(3),       $     ; volume dimensions in user coords
            _location: DBLARR(3),         $     ; volume location in user coords
            _oBoxModel: OBJ_NEW(),        $     ; contains extent graphics
            _oBoxPoly: OBJ_NEW(),         $     ; extent polygon
            _oPlaneContainer: OBJ_NEW(),  $     ; contains low-qual texture planes
            _oPlaneModels: OBJARR(6),     $     ; contains polygons for low-qual rendering
                                                ; textures - 2 for each major axis
            _oTextures: OBJARR(3),        $     ; texture for each major axis
                                                ; (the slices are tiled onto each texture)
            _oVolume: OBJ_NEW(),          $     ; IDLgrVolume
            _paletteNum: 0b,              $     ; Current palette - used by Get/SetProperty
                                                ; and EditUserDefProperty to communicate which
                                                ; palette is to be editted.
            _renderExtents: 0b,           $     ; 0 = no extents, 1 = wire, 2 = solid
            _renderByButton: 0b,          $     ; 1 to indicate "one-shot" render
            _renderQuality: 0b,           $     ; 1 = low, 2 = high
            _subvolume: LONARR(6)         $     ; subvolume
            }
end
