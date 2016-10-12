; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisrangepan__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRangePan class is the range pan manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRangePan')
;
;   or
;
;   Obj->[IDLitManipVisRangePan::]Init
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
function IDLitManipVisRangePan::Init, $
    COLOR=color, $
    NAME=inName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Range Pan Visual"

    ; Initialize superclasses.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Range Pan', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    self._axisOffsets = [0.1, 0.15]
    self._btnDim = 0.05

    ; X- pan.
    fname = FILEPATH('shift_left.bmp', SUBDIR=['resource','bitmaps'])
    img = self->_LoadBitmap(fname)
    x = -1.0
    y = -1.0 - self._axisOffsets[0] - self._btnDim
    z = -1.0
    self.oPanXMinus = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Pan/Left')
    oImage = OBJ_NEW('IDLgrImage', img, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oPanXMinusImg = oImage
    self.oPanXMinus->Add, oPoly
    self->Add, self.oPanXMinus

    ; X+ pan.
    x = 1.0 - self._btnDim
    y = -1.0 - self._axisOffsets[0] - self._btnDim
    z = -1.0
    fname = FILEPATH('shift_right.bmp', SUBDIR=['resource','bitmaps'])
    img = self->_LoadBitmap(fname)
    self.oPanXPlus = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Pan/Right')
    oImage = OBJ_NEW('IDLgrImage', img, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim, self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oPanXPlusImg = oImage
    self.oPanXPlus->Add, oPoly
    self->Add, self.oPanXPlus

    ; Y- pan.
    x = -1.0 - self._axisOffsets[1] - self._btnDim
    y = -1.0
    z = -1.0
    fname = FILEPATH('shift_down.bmp', SUBDIR=['resource','bitmaps'])
    img = self->_LoadBitmap(fname)
    self.oPanYMinus = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Pan/Down')
    oImage = OBJ_NEW('IDLgrImage', img, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oPanYMinusImg = oImage
    self.oPanYMinus->Add, oPoly
    self->Add, self.oPanYMinus

    ; Y+ pan.
    x = -1.0 - self._axisOffsets[1] - self._btnDim
    y = 1.0 - self._btnDim
    z = -1.0
    fname = FILEPATH('shift_up.bmp', SUBDIR=['resource','bitmaps'])
    img = self->_LoadBitmap(fname)
    self.oPanYPlus = OBJ_NEW('IDLitManipulatorVisual', $
        VISUAL_TYPE='Range Pan/Up')
    oImage = OBJ_NEW('IDLgrImage', img, LOCATION=[x,y,z], $
        BLEND_FUNCTION=[3,4], $
        DIMENSIONS=[self._btnDim,self._btnDim])
    pData = [[x,y,-1],$
             [x+self._btnDim,y,-1],$
             [x+self._btnDim,y+self._btnDim,-1], $
             [x,y+self._btnDim,-1]]
    oPoly = OBJ_NEW('IDLgrPolygon', pData, COLOR=[255,255,255], $
        TEXTURE_MAP=oImage, $
        TEXTURE_COORD=[[0,0],[1,0],[1,1],[0,1]])
    self.oPanYPlusImg = oImage
    self.oPanYPlus->Add, oPoly
    self->Add, self.oPanYPlus

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This procedure method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitManipVisRangePan::Cleanup

    compile_opt idl2, hidden

    ; Destroy texture maps.
    OBJ_DESTROY, [self.oPanXPlusImg, self.oPanXMinusImg, $
        self.oPanYPlusImg, self.oPanYMinusImg]

    ; Call my superclass.
    self->IDLitManipulatorVisual::Cleanup

end

;----------------------------------------------------------------------------
; IDLitManipVisRangePan::SetProperty
;
; Purpose:
;   This procedure method sets the value(s) of one or more properties.
;
pro IDLitManipVisRangePan::SetProperty, $
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
;   IDLitManipVisRangePan::_LoadBitmap
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
function IDLitManipVisRangePan::_LoadBitmap, filename, $
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
pro IDLitManipVisRangePan::_TransformToVisualization, oVis

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

    ; Retrieve the XYZ ranges of the target visualization.
    bValid = oVis->GetXYZRange(XRange, YRange, ZRange, /NO_TRANSFORM)
    if (bValid eq 0) then return
    xLen = XRange[1] - XRange[0]
    yLen = YRange[1] - YRange[0]
    maxLen = xLen > yLen
    midX = (XRange[0]+XRange[1]) * 0.5
    midY = (YRange[0]+YRange[1]) * 0.5

    isIsotropic = oVis->IsIsotropic()

    ; Recompute offsets and control dimensions based upon
    ; the current ranges and zoom factor.
    ; Note: self._axisOffsets are updated by the ::_SetAxisOffsets
    ; method of the parent IDLitManipVisRange object.
    axisOffsets = (self._axisOffsets * maxLen) / zoomFactor
    dim = (self._btnDim * maxLen) / zoomFactor

    ; X- pan.
    oPoly = self.oPanXMinus->Get()
    x = XRange[0]
    y = YRange[0] - axisOffsets[0] - dim
    z = ZRange[0]
    ; Prevent overlap.  If isotropic, only need to make sure
    ; current control is left of center.  If anisotropic, need
    ; to leave room for zoom buttons as well.
    maxx = isIsotropic ? (midX - dim) : (midX - (2.0*dim))
    x = x < maxx
    ; Make sure control falls within the viewplane rectangle.
    x = x > (vpRect[0] + 2*dim)  ; allow room for zoom in/out xy controls.
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; X+ pan.
    oPoly = self.oPanXPlus->Get()
    x = XRange[1] - dim
    y = YRange[0] - axisOffsets[0] - dim
    z = ZRange[0]
    ; Prevent overlap.  If isotropic, only need to make sure
    ; current control is right of center.  If anisotropic, need
    ; to leave room for zoom buttons as well.
    minx = isIsotropic ? midX : (midX + dim)
    x = x > minx
    ; Make sure control falls within the viewplane rectangle.
    x = x < (vpRect[0]+vpRect[2]-dim)
    y = y > vpRect[1]
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Y- pan.
    oPoly = self.oPanYMinus->Get()
    x = XRange[0] - axisOffsets[1] - dim
    y = YRange[0]
    z = ZRange[0]
    ; Prevent overlap.  If isotropic, only need to make sure
    ; current control is left of center.  If anisotropic, need
    ; to leave room for zoom buttons as well.
    maxy = isIsotropic ? (midY - dim) : (midY - (2.0*dim))
    y = y < maxy
    ; Make sure control falls within the viewplane rectangle.
    x = x > vpRect[0]
    y = y > (vpRect[1] + dim)  ; allow room for zoom out xy control.
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

    ; Y+ pan.
    oPoly = self.oPanYPlus->Get()
    x = XRange[0] - axisOffsets[1] - dim
    y = YRange[1] - dim
    z = ZRange[0]
    ; Prevent overlap.  If isotropic, only need to make sure
    ; current control is right of center.  If anisotropic, need
    ; to leave room for zoom buttons as well.
    miny = isIsotropic ? midY : (midY + dim)
    y = y > miny
    ; Make sure control falls within the viewplane rectangle.
    x = x > vpRect[0]
    y = y < (vpRect[1]+vpRect[3]-dim)
    pData = [[x,y,z],[x+dim,y,z],[x+dim,y+dim,z],[x,y+dim,z]]
    oPoly->SetProperty, DATA=pData

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisRangePan__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisRangePan object.
;-
pro IDLitManipVisRangePan__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRangePan,    $
        inherits IDLitManipulatorVisual, $ ; Superclass.
        _axisOffsets: FLTARR(2),         $ ; Normalized offset from axes,
                                         $ ;   [xoff,yoff], for controls
        _btnDim: 0.0,                    $ ; Normalized (X=Y) dimension of
                                         $ ;   each button
        oPanXPlus: OBJ_NEW(),            $ ; X+ pan visual
        oPanXPlusImg: OBJ_NEW(),         $ ;  (texture map)
        oPanXMinus: OBJ_NEW(),           $ ; X- pan visual
        oPanXMinusImg: OBJ_NEW(),        $ ;  (texture map)
        oPanYPlus: OBJ_NEW(),            $ ; Y+ pan visual
        oPanYPlusImg: OBJ_NEW(),         $ ;  (texture map)
        oPanYMinus: OBJ_NEW(),           $ ; Y- pan visual
        oPanYMinusImg: OBJ_NEW()         $ ;  (texture map)
    }
end
