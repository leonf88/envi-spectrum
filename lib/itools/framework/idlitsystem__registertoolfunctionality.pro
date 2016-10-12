; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsystem__registertoolfunctionality.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;----------------------------------------------------------------------------
;; IDLitSystem::RegisterToolFunctionality
;;
;; Purpose:
;;    This routine contains all the tool related functionailty that is
;;    registered with the system. This is contained in a separate file
;;    to isolate this functionality as well as minimize the size of
;;    the system object definition.
;;
;; Parameters:
;;    None.
;;
pro IDLitSystem::RegisterToolFunctionality
  compile_opt hidden, idl2

;;-----Volume visualization operations

  ;; Operations Menu
  self->RegisterToolOperation,"IDLVOLUME", 'Image Plane', $
    'IDLitOpInsertImagePlane', $ $
    NAME=IDLitLangCatQuery('Menu:Operations:ImagePlane'), $
    IDENTIFIER='Operations/Volume/ImagePlane', ICON='image'

  self->RegisterToolOperation, "IDLVOLUME", 'Isosurface', $
    'IDLitopIsosurface', $
    NAME=IDLitLangCatQuery('Menu:Operations:Isosurface'), $
    IDENTIFIER='Operations/Volume/Isosurface', ICON='sum'

  self->RegisterToolOperation, "IDLVOLUME", 'Interval Volume', $
    'IDLitopIntVol', $
    NAME=IDLitLangCatQuery('Menu:Operations:IntVolume'), $
    IDENTIFIER='Operations/Volume/IntervalVolume', ICON='sum'

  self->RegisterToolOperation, "IDLVOLUME", 'Render Volume', $
    'IDLitopRenderVolume', $
    NAME=IDLitLangCatQuery('Menu:Operations:RenderVol'), $
    IDENTIFIER='Volume/Render', ICON='volume'

  self->RegisterToolOperation, "IDLVOLUME", 'Launch iImage', $
    'IDLitOpImagePlaneIImage', $
    NAME=IDLitLangCatQuery('Menu:Operations:LaunchiImage'), $
    IDENTIFIER='Operations/Image Plane/iImage', ICON='image'

  ;; Insert menu
  self->RegisterToolOperation, "IDLVOLUME", 'Light', 'IDLitopInsertLight', $
    NAME=IDLitLangCatQuery('Menu:Insert:Light'), $
    IDENTIFIER='Insert/Light', ICON='bulb'

  self->RegisterToolOperation, "IDLVOLUME", 'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; Window menu
  self->RegisterToolOperation, "IDLVOLUME", 'Reset Dataspace Ranges', $
    'IDLitopRangeReset', $
    NAME=IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
    IDENTIFIER='Window/ResetRanges'

;;-----Image visualization Operations--------------------

  self->RegisterToolOperation, "IDLIMAGE", 'Flip Horizontal', $
    'IDLitopFlipHorizontal', $
    NAME=IDLitLangCatQuery('Menu:Operations:FlipHoriz'), $
    IDENTIFIER='Operations/Rotate/FlipHorizontal', $
    ICON='fliphoriz'

  self->RegisterToolOperation, "IDLIMAGE", 'Flip Vertical', $
    'IDLitopFlipVertical', $
    NAME=IDLitLangCatQuery('Menu:Operations:FlipVert'), $
    IDENTIFIER='Operations/Rotate/FlipVertical', $
    ICON='flipvert'

  self->RegisterToolOperation, "IDLIMAGE", 'Invert Image', 'IDLitopInvert', $
    NAME=IDLitLangCatQuery('Menu:Operations:InvertImage'), $
    IDENTIFIER='Operations/Transform/Invert', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Byte Scale', 'IDLitopBytscl', $
    NAME=IDLitLangCatQuery('Menu:Operations:ByteScale'), $
    IDENTIFIER='Operations/Transform/Bytscl', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Difference of Gaussians', $
    'IDLitopDifferenceOfGaussians', $
    NAME=IDLitLangCatQuery('Menu:Operations:DifferenceOfGaussians'), $
    IDENTIFIER='Operations/Filter/Difference Of Gaussians', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Emboss', $
    'IDLitopEmboss', $
    NAME=IDLitLangCatQuery('Menu:Operations:Emboss'), $
    IDENTIFIER='Operations/Filter/Emboss', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Laplacian', $
    'IDLitopLaplacian', $
    NAME=IDLitLangCatQuery('Menu:Operations:Laplacian'), $
    IDENTIFIER='Operations/Filter/Laplacian', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Prewitt Filter', $
    'IDLitopFilterPrewitt', $
    NAME=IDLitLangCatQuery('Menu:Operations:Prewitt'), $
    IDENTIFIER='Operations/Filter/Prewitt', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Roberts Filter', $
    'IDLitopFilterRoberts', $
    NAME=IDLitLangCatQuery('Menu:Operations:Roberts'), $
    IDENTIFIER='Operations/Filter/Roberts', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Sobel Filter', $
    'IDLitopFilterSobel', $
    NAME=IDLitLangCatQuery('Menu:Operations:Sobel'), $
    IDENTIFIER='Operations/Filter/Sobel', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Unsharp Mask', $
    'IDLitopUnsharpMask', $
    NAME=IDLitLangCatQuery('Menu:Operations:UnsharpMask'), $
    IDENTIFIER='Operations/Filter/Unsharp Mask', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Dilate', 'IDLitopMorphDilate', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:DilateDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Dilate'), $
    IDENTIFIER='Operations/Morph/Dilate', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Erode', 'IDLitopMorphErode', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:ErodeDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Erode'), $
    IDENTIFIER='Operations/Morph/Erode', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Morph Open', 'IDLitopMorphOpen', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphOpenDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphOpen'), $
    IDENTIFIER='Operations/Morph/MorphOpen', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Morph Close', $
    'IDLitopMorphClose', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphCloseDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphClose'), $
    IDENTIFIER='Operations/Morph/MorphClose', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Morph Gradient', $
    'IDLitopMorphGradient', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphGradientDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphGradient'), $
    IDENTIFIER='Operations/Morph/MorphGradient', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Morph Tophat', $
    'IDLitopMorphTophat', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphTophatDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphTophat'), $
    IDENTIFIER='Operations/Morph/MorphTophat', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Crop', $
    PROXY='ContextMenu/CropDrawContext/Crop', $
    NAME=IDLitLangCatQuery('Menu:Operations:Crop'), $
    IDENTIFIER='Operations/Crop'

  ;; Note: these operations do not have icons, as they should not appear
  ;; in the menu; they serve as support operations.
  self->RegisterToolOperation, 'IDLIMAGE', 'Set Image Origin', $
    'IDLitopSetImageOrigin', $
    /PRIVATE, $                 ; hide in macro editor tree view
    DESCRIPTION='Set image origin', $
    IDENTIFIER='Operations/SetImageOrigin'

  self->RegisterToolOperation, 'IDLIMAGE', 'Crop Image Grid', $
    'IDLitopCropImageGrid', $
    /PRIVATE, $                 ; hide in macro editor tree view
    DESCRIPTION='Crop the image X and Y grid', $
    IDENTIFIER='Operations/CropImageGrid'

  self->RegisterToolOperation, 'IDLIMAGE', 'Region Grow', $
    'IDLitOpRegionGrow', $
    NAME=IDLitLangCatQuery('Menu:Operations:RegionGrow'), $
    IDENTIFIER='Operations/Region Grow', ICON='sum'

  self->RegisterToolOperation, 'IDLIMAGE', 'Surface', 'IDLitOpInsertSurface', $
    NAME=IDLitLangCatQuery('Menu:Operations:Surface'), $
    IDENTIFIER='Operations/Surface', ICON='surface'

  self->RegisterToolOperation, 'IDLIMAGE', 'Contour', 'IDLitOpInsertContour', $
    NAME=IDLitLangCatQuery('Menu:Operations:Contour'), $
    IDENTIFIER='Operations/Contour', ICON='contour'

  ;; private since the manipulator is available
  self->RegisterToolOperation, 'IDLIMAGE', 'Line Profile', $
    'IDLitOpLineProfile', $
    IDENTIFIER='Operations/Line Profile', ICON='profile', /PRIVATE

  self->RegisterToolOperation, 'IDLIMAGE', 'Plot Profile', $
    'IDLitOpPlotProfile', $
    NAME=IDLitLangCatQuery('Menu:Operations:PlotProfile'), $
    IDENTIFIER='Operations/Plot Profile', ICON='profile'

  ;;-----------------
  ;; Insert menu
  self->RegisterToolOperation, "IDLIMAGE",'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; Image manipulators
  self->RegisterToolManipulator, "IDLIMAGE", 'Crop', 'IDLitManipCropBox', $
    ICON='crop', IDENTIFIER="CROP BOX", $
    NAME=IDLitLangCatQuery('Menu:Operations:Crop'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:CropDesc')

  self->RegisterToolManipulator, "IDLIMAGE", 'Line Profile', $
    'IDLitManipLineProfile', $
    ICON='profile', IDENTIFIER="PROFILE", $
    NAME=IDLitLangCatQuery('Menu:Operations:LineProfile'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:LineProfileDesc')

  self->RegisterToolManipulator, 'IDLIMAGE', 'ROI Rectangle', $
    'IDLitManipROIRect', $
    ICON='rectangl', IDENTIFIER="ROI/RECTANGLE", $
    NAME=IDLitLangCatQuery('Menu:ROI:Rectangle'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:ROI:RectangleDesc')

  self->RegisterTOolManipulator, 'IDLIMAGE', 'ROI Oval', $
    'IDLitManipROIOval', $
    ICON='ellipse', IDENTIFIER='ROI/OVAL', $
    NAME=IDLitLangCatQuery('Menu:ROI:Oval'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:ROI:OvalDesc')

  self->RegisterToolManipulator, 'IDLIMAGE', 'ROI Polygon', $
    'IDLitManipROIPoly', $
    ICON='segpoly', IDENTIFIER='ROI/POLYGON', $
    NAME=IDLitLangCatQuery('Menu:ROI:Polygon'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:ROI:PolygonDesc')

  self->RegisterToolManipulator, 'IDLIMAGE', 'ROI Freehand', $
    'IDLitManipROIFree', $
    ICON='freehand', IDENTIFIER='ROI/FREEHAND', $
    NAME=IDLitLangCatQuery('Menu:ROI:Freehand'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:ROI:FreehandDesc')

;; ----------Plot visualization operations ----------------

  ;; Operations Menu
  self->RegisterToolOperation, "IDLPLOT", 'Curve Fitting', $
    'IDLitopCurveFitting', $
    NAME=IDLitLangCatQuery('Menu:Operations:CurveFit'), $
    IDENTIFIER='Operations/Filter/Curve Fitting', ICON='sum'

  ;; Insert menu
  self->RegisterToolOperation, "IDLPLOT", 'New Legend', $
    'IDLitOpInsertLegend', $
    NAME=IDLitLangCatQuery('Menu:Insert:NewLegend'), $
    IDENTIFIER='Insert/Legend', ICON='legend'

  self->RegisterToolOperation, "IDLPLOT", 'Legend Item', $
    'IDLitOpInsertLegendItem', $
    NAME=IDLitLangCatQuery('Menu:Insert:LegendItem'), $
    IDENTIFIER='Insert/LegendItem', ICON='legend'

  self->RegisterToolOperation, "IDLPLOT", 'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; Window menu
  self->RegisterToolOperation, "IDLPLOT", 'Reset Dataspace Ranges', $
    'IDLitopRangeReset', $
    NAME=IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
    IDENTIFIER='Window/ResetRanges'

  ;; Manipulators
  self->RegisterToolManipulator, 'IDLPLOT', 'Data Range', 'IDLitManipRange', $
    ICON='data_range', $
    NAME=IDLitLangCatQuery('Menu:Operations:DataRange'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:DataRangeDesc')

;; ----------Plot3D visualization operations ----------------

  ;; Operations Menu
  self->RegisterToolOperation, "IDLPLOT3D", 'Curve Fitting', $
    'IDLitopCurveFitting', $
    NAME=IDLitLangCatQuery('Menu:Operations:CurveFit'), $
    IDENTIFIER='Operations/Filter/Curve Fitting', ICON='sum'

  ;; Insert menu
  self->RegisterToolOperation, "IDLPLOT3D", 'Light', 'IDLitopInsertLight', $
    NAME=IDLitLangCatQuery('Menu:Insert:Light'), $
    IDENTIFIER='Insert/Light', ICON='bulb'

  self->RegisterToolOperation, "IDLPLOT3D", 'New Legend', $
    'IDLitOpInsertLegend', $
    NAME=IDLitLangCatQuery('Menu:Insert:NewLegend'), $
    IDENTIFIER='Insert/Legend', ICON='legend'

  self->RegisterToolOperation, "IDLPLOT3D", 'Legend Item', $
    'IDLitOpInsertLegendItem', $
    NAME=IDLitLangCatQuery('Menu:Insert:LegendItem'), $
    IDENTIFIER='Insert/LegendItem', ICON='legend'

  self->RegisterToolOperation, "IDLPLOT3D", 'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; Window menu
  self->RegisterToolOperation, "IDLPLOT3D", 'Reset Dataspace Ranges', $
    'IDLitopRangeReset', $
    NAME=IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
    IDENTIFIER='Window/ResetRanges'

  ;; Manipulators
  self->RegisterToolManipulator, 'IDLPLOT3D', 'Data Range', $
    'IDLitManipRange', $
    ICON='data_range', $
    NAME=IDLitLangCatQuery('Menu:Operations:DataRange'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:DataRangeDesc')

;; ------------Contour visualization operations--------------

  self->RegisterToolOperation, "IDLCONTOUR", 'Flip Horizontal', $
    'IDLitopFlipHorizontal', $
    IDENTIFIER='Operations/Rotate/FlipHorizontal', $
    NAME=IDLitLangCatQuery('Menu:Operations:FlipHoriz'), $
    ICON='fliphoriz'

  self->RegisterToolOperation, "IDLCONTOUR", 'Flip Vertical', $
    'IDLitopFlipVertical', $
    IDENTIFIER='Operations/Rotate/FlipVertical', $
    NAME=IDLitLangCatQuery('Menu:Operations:FlipVert'), $
    ICON='flipvert'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Dilate', 'IDLitopMorphDilate', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:DilateDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Dilate'), $
    IDENTIFIER='Operations/Morph/Dilate', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Erode', 'IDLitopMorphErode', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:ErodeDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Erode'), $
    IDENTIFIER='Operations/Morph/Erode', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Morph Open', $
    'IDLitopMorphOpen', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphOpenDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphOpen'), $
    IDENTIFIER='Operations/Morph/MorphOpen', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Morph Close', $
    'IDLitopMorphClose', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphCloseDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphClose'), $
    IDENTIFIER='Operations/Morph/MorphClose', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Morph Gradient', $
    'IDLitopMorphGradient', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphGradientDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphGradient'), $
    IDENTIFIER='Operations/Morph/MorphGradient', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Morph Tophat', $
    'IDLitopMorphTophat', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphTophatDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphTophat'), $
    IDENTIFIER='Operations/Morph/MorphTophat', ICON='sum'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Surface', $
    'IDLitOpInsertSurface', $
    NAME=IDLitLangCatQuery('Menu:Operations:Surface'), $
    IDENTIFIER='Operations/Surface', ICON='surface'

  self->RegisterToolOperation, 'IDLCONTOUR', 'Image', 'IDLitOpInsertImage', $
    NAME=IDLitLangCatQuery('Menu:Operations:Image'), $
    IDENTIFIER='Operations/Image', ICON='image'

  ;; Insert menu
  self->RegisterToolOperation, "IDLCONTOUR", 'New Legend', $
    'IDLitOpInsertLegend', $
    NAME=IDLitLangCatQuery('Menu:Insert:NewLegend'), $
    IDENTIFIER='Insert/Legend', ICON='legend'

  self->RegisterToolOperation, "IDLCONTOUR", 'Legend Item', $
    'IDLitOpInsertLegendItem', $
    NAME=IDLitLangCatQuery('Menu:Insert:LegendItem'), $
    IDENTIFIER='Insert/LegendItem', ICON='legend'

  self->RegisterToolOperation, "IDLCONTOUR", 'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; Window menu
  self->RegisterToolOperation, "IDLCONTOUR", 'Reset Dataspace Ranges', $
    'IDLitopRangeReset', $
    NAME=IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
    IDENTIFIER='Window/ResetRanges'

  ;; Manipulators
  self->RegisterToolManipulator, "IDLCONTOUR", 'Data Range', $
    'IDLitManipRange', $
    NAME=IDLitLangCatQuery('Menu:Operations:DataRange'), $
    ICON='data_range'

;; --------------- Surface visualization operations ----------------

  ;; Operations Menu
  self->RegisterToolOperation, 'IDLSURFACE', 'Dilate', 'IDLitopMorphDilate', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:DilateDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Dilate'), $
    IDENTIFIER='Operations/Morph/Dilate', ICON='sum'

  self->RegisterToolOperation, 'IDLSURFACE', 'Erode', $
    'IDLitopMorphErode', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:ErodeDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:Erode'), $
    IDENTIFIER='Operations/Morph/Erode', ICON='sum'

  self->RegisterToolOperation, 'IDLSURFACE', 'Morph Open', $
    'IDLitopMorphOpen', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphOpenDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphOpen'), $
    IDENTIFIER='Operations/Morph/MorphOpen', ICON='sum'

  self->RegisterToolOperation, 'IDLSURFACE', 'Morph Close', $
    'IDLitopMorphClose', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphCloseDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphClose'), $
    IDENTIFIER='Operations/Morph/MorphClose', ICON='sum'

  self->RegisterToolOperation, 'IDLSURFACE', 'Morph Gradient', $
    'IDLitopMorphGradient', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphGradientDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphGradient'), $
    IDENTIFIER='Operations/Morph/MorphGradient', ICON='sum'

  self->RegisterToolOperation, 'IDLSURFACE', 'Morph Tophat', $
    'IDLitopMorphTophat', $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:MorphTophatDesc'), $
    NAME=IDLitLangCatQuery('Menu:Operations:MorphTophat'), $
    IDENTIFIER='Operations/Morph/MorphTophat', ICON='sum'

  self->RegisterToolOperation, "IDLSURFACE", 'Contour', $
    'IDLitOpInsertContour', $
    NAME=IDLitLangCatQuery('Menu:Operations:Contour'), $
    IDENTIFIER='Operations/Contour', ICON='mcr'

  self->RegisterToolOperation, 'IDLSURFACE', 'Image', 'IDLitOpInsertImage', $
    NAME=IDLitLangCatQuery('Menu:Operations:Image'), $
    IDENTIFIER='Operations/Image', ICON='image'

  ;; private since the manipulator is available
  self->RegisterToolOperation, 'IDLSURFACE', 'Line Profile', $
    'IDLitOpLineProfile', $
    IDENTIFIER='Operations/Line Profile', ICON='profile', /PRIVATE

  self->RegisterToolOperation, 'IDLSURFACE', 'Plot Profile', $
    'IDLitOpPlotProfile', $
    NAME=IDLitLangCatQuery('Menu:Operations:PlotProfile'), $
    IDENTIFIER='Operations/Plot Profile', ICON='profile'

  ;; Insert menu
  self->RegisterToolOperation, "IDLSURFACE", 'Light', 'IDLitopInsertLight', $
    NAME=IDLitLangCatQuery('Menu:Insert:Light'), $
    IDENTIFIER='Insert/Light', ICON='bulb'

  self->RegisterToolOperation, "IDLSURFACE", 'New Legend', $
    'IDLitOpInsertLegend', $
    NAME=IDLitLangCatQuery('Menu:Insert:NewLegend'), $
    IDENTIFIER='Insert/Legend', ICON='legend'

  self->RegisterToolOperation, "IDLSURFACE", 'Legend Item', $
    'IDLitOpInsertLegendItem', $
    NAME=IDLitLangCatQuery('Menu:Insert:LegendItem'), $
    IDENTIFIER='Insert/LegendItem', ICON='legend'

  self->RegisterToolOperation, "IDLSURFACE", 'Colorbar', $
    'IDLitOpInsertColorbar', $
    NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
    IDENTIFIER='Insert/Colorbar', ICON='colorbar'

  ;; View menu
  self->RegisterToolOperation, "IDLSURFACE", 'Reset Dataspace Ranges', $
    'IDLitopRangeReset', $
    NAME=IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
    IDENTIFIER='Window/ResetRanges'

  ;; Manipulators
  ;; Reg the surface contour routine
  self->RegisterToolManipulator, "IDLSURFACE", 'Surface Contour', $
    'IDLitManipSurfContour',  $
    NAME=IDLitLangCatQuery('Menu:Operations:SurfContour'), $
    ICON='contour'

  self->RegisterToolManipulator, "IDLSURFACE", 'Line Profile', $
    'IDLitManipLineProfile', $
    ICON='profile', IDENTIFIER="PROFILE", $
    NAME=IDLitLangCatQuery('Menu:Operations:LineProfile'), $
    DESCRIPTION=IDLitLangCatQuery('Menu:Operations:LineProfileDesc')

;; --------------- Map operations ----------------

; --------------- Vector & Streamline operations ----------------

    for i=0,1 do begin
        vis = i ? 'IDLVISSTREAMLINE' : 'IDLVISVECTOR'
        self->RegisterToolOperation, vis, 'Colorbar', $
            'IDLitOpInsertColorbar', $
            NAME=IDLitLangCatQuery('Menu:Insert:Colorbar'), $
            IDENTIFIER='Insert/Colorbar', ICON='colorbar'

        self->RegisterToolOperation, vis, 'Streamlines', $
            'IDLitopVectorStreamline', $
            NAME=IDLitLangCatQuery('Menu:Operations:Vector:Streamlines') + '...', $
            IDENTIFIER='Operations/Vector/Streamlines', ICON='polar'

        self->RegisterToolOperation, vis, 'Contour Magnitude', $
            'IDLitopVectorContour', $
            NAME=IDLitLangCatQuery('Menu:Operations:Vector:ContourMagnitude'), $
            IDENTIFIER='Operations/Vector/ContourMagnitude', ICON='contour'

        self->RegisterToolOperation, vis, 'Contour Direction', $
            'IDLitopVectorContour', $
            NAME=IDLitLangCatQuery('Menu:Operations:Vector:ContourDirection'), $
            IDENTIFIER='Operations/Vector/ContourDirection', ICON='contour'
    endfor

end
