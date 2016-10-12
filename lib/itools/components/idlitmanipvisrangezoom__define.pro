; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisrangezoom__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRangeZoom class is the range zoom manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRangeZoom')
;
;   or
;
;   Obj->[IDLitManipVisRangeZoom::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisRangeZoom::Init, $
    COLOR=color, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Range Zoom Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Range Zoom', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    self._axisOffsets = [0.1, 0.15]
    self._btnDim = 0.05

    fname = FILEPATH('minus.bmp', SUBDIR=['resource','bitmaps'])
    minusImg = self->_LoadBitmap(fname, XSIZE=baseXSize, YSIZE=baseYSize)
    fname = FILEPATH('plus.bmp', SUBDIR=['resource','bitmaps'])
    plusImg = self->_LoadBitmap(fname, XSIZE=baseXSize, YSIZE=baseYSize)

    ; Zoom out - X.
    x = 0.0 - self._btnDim
    y = -1.0 - self._axisOffsets[0] - self._btnDim
    z = -1.0
    self.oZoomOutX = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/Out X')
    oImage = OBJ_NEW('IDLgrImage', minusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomOutXImg = oImage
    self.oZoomOutX->Add, oPoly
    self->Add, self.oZoomOutX

    ; Zoom in - X.
    x = 0.0
    y = -1.0 - self._axisOffsets[0] - self._btnDim
    z = -1.0
    self.oZoomInX = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/In X')
    oImage = OBJ_NEW('IDLgrImage', plusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomInXImg = oImage
    self.oZoomInX->Add, oPoly
    self->Add, self.oZoomInX

    ; Zoom out - Y.
    x = -1.0 - self._axisOffsets[1] - self._btnDim
    y = 0.0 - self._btnDim
    z = -1.0
    self.oZoomOutY = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/Out Y')
    oImage = OBJ_NEW('IDLgrImage', minusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomOutYImg = oImage
    self.oZoomOutY->Add, oPoly
    self->Add, self.oZoomOutY

    ; Zoom in - Y.
    x = -1.0 - self._axisOffsets[1] - self._btnDim
    y = 0.0
    z = -1.0
    self.oZoomInY = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/In Y')
    oImage = OBJ_NEW('IDLgrImage', plusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomInYImg = oImage
    self.oZoomInY->Add, oPoly
    self->Add, self.oZoomInY

    ; For isotropic dataspaces:
    ; Zoom out - XY.
    minOffset = MIN(self._axisOffsets)
    x = -1.0 - minOffset - (1.5*self._btnDim)
    y = -1.0 - minOffset - (0.5*self._btnDim)
    z = -1.0
    self.oZoomOutXY = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/Out XY')
    oImage = OBJ_NEW('IDLgrImage', minusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomOutXYImg = oImage
    self.oZoomOutXY->Add, oPoly
    self->Add, self.oZoomOutXY

    ; Zoom in - XY.
    x = -1.0 - minOffset - (0.5*self._btnDim)
    y = -1.0 - minOffset - (0.5*self._btnDim)
    z = -1.0
    self.oZoomInXY = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Zoom/In XY')
    oImage = OBJ_NEW('IDLgrImage', plusImg, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oZoomInXYImg = oImage
    self.oZoomInXY->Add, oPoly
    self->Add, self.oZoomInXY

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitManipVisRangeZoom::Cleanup

    compile_opt idl2, hidden

    ; Destroy texture maps.
    OBJ_DESTROY, [self.oZoomInXImg, self.oZoomOutXImg, $
        self.oZoomInYImg, self.oZoomOutYImg, $
        self.oZoomInXYImg, self.oZoomOutXYImg]

    ; Call my superclass.
    self->IDLitManipulatorVisual::Cleanup

end


;----------------------------------------------------------------------------
; IDLitManipVisRangeZoom::SetProperty
;
; Purpose:
;   This procedure method sets the value(s) of one or more properties.
;
pro IDLitManipVisRangeZoom::SetProperty, $
    AXIS_OFFSETS=axisOffsets, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(axisOffsets) eq 2) then $
        self._axisOffsets = axisOffsets

    if (N_ELEMENTS(_EXTRA) gt 0) then $
        self->IDLitManipulatorVisual::SetProperty, _EXTRA=_extra
end
;----------------------------------------------------------------------------
; Name:
;   IDLitManipVisRangeZoom::_LoadBitmap
;
; Purpose:
;   This internal function loads a bitmap from the given file and
;   places the results in an RGBA image.
;
; Arguments:
;   Filename: A string representing the name of the bitmap file
;     to read.
;
; Keywords:
;   XSIZE:  Set this keyword to a named variable that upon return
;     will contain the X dimension of the loaded bitmap.
;
;   YSIZE:  Set this keyword to a named variable that upon return
;     will contain the Y dimension of the loaded bitmap.
;
; Outputs:
;   This function returns an array, [4,n,m], representing the
;   image loaded from the file.  The alpha channel is the inverse
;   of the red channel. [Note: it is presumed that the RGB values
;   for these bitmaps are either white or black.]
;
function IDLitManipVisRangeZoom::_LoadBitmap, filename, $
    XSIZE=xsize, YSIZE=ysize

    compile_opt idl2, hidden

    ; Trap errors
@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        return, BYTARR(4,16,16)
    endif

    img = READ_BMP(filename, r, g, b)
    iDims = SIZE(img, /DIMENSIONS)

    if (ARG_PRESENT(xsize)) then $
        xsize = iDims[0]

    if (ARG_PRESENT(ysize)) then $
        ysize = iDims[1]

    ; Switch black pixels to a given color.
    color = [0,128,0]
    iblack = WHERE(r[img] eq 0)
    channel = r[img]

    rgbImg = BYTARR(4,iDims[0], iDims[1])
    channel[iblack] = color[0]
    rgbImg[0,*,*] = channel
    channel[iblack] = color[1]
    rgbImg[1,*,*] = channel
    channel[iblack] = color[2]
    rgbImg[2,*,*] = channel
    rgbImg[3,*,*] = 255-r[img]

    return, rgbImg
end

;----------------------------------------------------------------------------
; Purpose:
;   This private procedure method transforms the selection visual
;   to the size and position of the given visualization.  Furthermore,
;   it hides/shows portions of the selection visual based upon the
;   isotropy setting for the visualization.
;
; Arguments:
;   Visualization: Set this argument to the object reference of the
;       IDLitVisualization that you wish to use when transforming
;       the scale and location of the selection visual.
;
pro IDLitManipVisRangeZoom::_TransformToVisualization, oVis

    compile_opt idl2, hidden

    if (not OBJ_ISA(oVis, '_IDLitVisualization')) then $
        return

    ; Retrieve the current view zoom factor.
    zoomFactor = 1.0
    vpRect = [-1.0,-1.0,2.0,2.0]
    oLayer = oVis->_GetLayer()
    if (OBJ_VALID(oLayer)) then begin
        oLayer->IDLgrView::GetProperty, PARENT=oView, $
            VIEWPLANE_RECT=vpRect
        if (OBJ_VALID(oView)) then $
            oView->GetProperty, CURRENT_ZOOM=zoomFactor
    endif

    ; Hide/show appropriate controls based upon target's isotropy
    ; setting.
    isIsotropic = oVis->IsIsotropic()
    if (isIsotropic) then begin
        self.oZoomInX->SetProperty, /HIDE
        self.oZoomOutX->SetProperty, /HIDE
        self.oZoomInY->SetProperty, /HIDE
        self.oZoomOutY->SetProperty, /HIDE
    endif else begin
        self.oZoomInX->SetProperty, HIDE=0
        self.oZoomOutX->SetProperty, HIDE=0
        self.oZoomInY->SetProperty, HIDE=0
        self.oZoomOutY->SetProperty, HIDE=0
    endelse

    ; Retrieve the XYZ ranges of the target visualization.
    bValid = oVis->GetXYZRange(XRange, YRange, ZRange, /NO_TRANSFORM)
    if (bValid eq 0) then return
    xLen = XRange[1] - XRange[0]
    yLen = YRange[1] - YRange[0]
    maxLen = xLen > yLen
    midX = (XRange[0]+XRange[1]) / 2.0
    midY = (YRange[0]+YRange[1]) / 2.0

    ; Recompute offsets and control dimensions based upon
    ; the current ranges and zoom factor.
    ; Note: self._axisOffsets are updated by the ::_SetAxisOffsets
    ; method of the parent IDLitManipVisRange object.
    axisOffsets = (self._axisOffsets * maxLen) / zoomFactor
    dim = (self._btnDim * maxLen) / zoomFactor

    ; Zoom out - X.
    oPoly = self.oZoomOutX->Get()
    x = midX - dim
    y = YRange[0] - axisOffsets[0] - dim
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Zoom in - X.
    oPoly = self.oZoomInX->Get()
    x = midX
    y = YRange[0] - axisOffsets[0] - dim
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Zoom out - Y.
    oPoly = self.oZoomOutY->Get()
    x = XRange[0] - axisOffsets[1] - dim
    y = midY - dim
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    x = x > vpRect[0]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Zoom in - Y.
    oPoly = self.oZoomInY->Get()
    x = XRange[0] - axisOffsets[1] - dim
    y = midY
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    x = x > vpRect[0]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Zoom out - XY.
    oPoly = self.oZoomOutXY->Get()
    minOffset = MIN(axisOffsets)
    x = XRange[0] - minOffset - (1.5 * dim)
    y = YRange[0] - minOffset - (0.5 * dim)
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    x = x > vpRect[0]
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Zoom in - XY.
    oPoly = self.oZoomInXY->Get()
    x = XRange[0] - minOffset - (0.5 * dim)
    y = YRange[0] - minOffset - (0.5 * dim)
    z = ZRange[0]
    ; Make sure control falls within the viewplane rectangle.
    x = x > (vpRect[0]+dim) ; allow room for zoom out xy control.
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisRangeZoom__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisRangeZoom object.
;-
pro IDLitManipVisRangeZoom__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRangeZoom,   $
        inherits IDLitManipulatorVisual, $
        _axisOffsets: FLTARR(2),         $ ; Normalized offset from axes,
                                         $ ;   [xoff,yoff], for controls
        _btnDim: 0.0,                    $ ; Normalized (X=Y) dimension of
                                         $ ;   each button
        oZoomInX: OBJ_NEW(),             $ ; X+ zoom visual
    oZoomInXImg: OBJ_NEW(),          $ ;  (texture map)
        oZoomOutX: OBJ_NEW(),            $ ; X- zoom visual
    oZoomOutXImg: OBJ_NEW(),         $ ;  (texture map)
        oZoomInY: OBJ_NEW(),             $ ; Y+ zoom visual
    oZoomInYImg: OBJ_NEW(),          $ ;  (texture map)
        oZoomOutY: OBJ_NEW(),            $ ; Y- zoom visual
    oZoomOutYImg: OBJ_NEW(),         $ ;  (texture map)
        oZoomInXY: OBJ_NEW(),            $ ; XY+ zoom visual
    oZoomInXYImg: OBJ_NEW(),         $ ;  (texture map)
        oZoomOutXY: OBJ_NEW(),           $ ; XY- zoom visual
    oZoomOutXYImg: OBJ_NEW()         $ ;  (texture map)
    }
end
