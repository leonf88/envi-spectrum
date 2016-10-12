; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlittoolbase__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitToolbase
;
; PURPOSE:
;   This file implements the IDL Tool base object, from which all other
;   Tools are subclassed.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitTool
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitToolbase::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitToolbase::Init
;
; INTERFACES:
; IIDLProperty
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitToolbase::Init
;
; Purpose:
; The constructor of the IDLitToolbase object.
;
; Parameters:
; None.
;
function IDLitToolbase::Init, _REF_EXTRA=_EXTRA
  ;; Pragmas
  compile_opt idl2, hidden

  ;; Call our super class
  if (~self->IDLitTool::Init(_EXTRA=_extra)) then $
    return, 0

  oSystem = self->_GetSystem()

  ;;---------------------------------------------------------------------
  ;;*** File Menu

  ;; create folders
  self->createfolders,'Operations/File',NAME=IDLitLangCatQuery('Menu:File')
  self->createfolders,'Operations/File/New', $
                      NAME=IDLitLangCatQuery('Menu:File:New')

    self->RegisterOperation, 'iPlot', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Plot'

    self->RegisterOperation, 'iSurface', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Surface'

    self->RegisterOperation, 'iContour', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Contour'

    self->RegisterOperation, 'iImage', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Image'

    self->RegisterOperation, 'iVolume', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Volume'

    self->RegisterOperation, 'iMap', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Map'

    self->RegisterOperation, 'iVector', 'IDLitOpNewTool', $
        IDENTIFIER='File/New/Vector'

    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Open'), $
        'IDLitopFileOpen', $
        ACCELERATOR='Ctrl+O', $
        DESCRIPTION='Open an existing data or image file', $
        IDENTIFIER='File/Open', ICON='open'

    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Import'), $
        'IDLitopImportData', $
        IDENTIFIER='File/Import', $
        /SEPARATOR

; CT, Aug 2008: Removed old Export wizard
;    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Export'), $
;        'IDLitopExportData', $
;        IDENTIFIER='File/Export', ICON='export'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:ExportImage'), $
        'IDLitopExportImage', $
        IDENTIFIER='File/ExportImage', ICON='export'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Export'), $
        'IDLitopclExport', $
        DESCRIPTION='Export Visualization Parameters to IDL Variables. ', $
        IDENTIFIER='File/CLExport'


    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Save'), $
        'IDLitopFileSave', $
        ACCELERATOR='Ctrl+S', $
        IDENTIFIER='File/Save', ICON='save', /SEPARATOR

    self->RegisterOperation, IDLitLangCatQuery('Menu:File:SaveAs'), $
        'IDLitopFileSaveAs', $
        IDENTIFIER='File/SaveAs', ICON='save'

    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:PrintPreview'), $
        'IDLitopPrintPreview', $
        DESCRIPTION='Print the contents of the active window', $
        IDENTIFIER='File/PrintPreview', ICON='print1'

    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Print'), $
        'IDLitopFilePrint', $
        ACCELERATOR='Ctrl+P', $
        DESCRIPTION='Print the contents of the active window', $
        IDENTIFIER='File/Print', ICON='print1'


    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Preferences'), $
        'IDLitopBrowserPrefs', $
        IDENTIFIER='File/Preferences', /SEPARATOR

    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Exit'), $
        'IDLitopFileExit', $
        ACCELERATOR='Ctrl+Q', $
        IDENTIFIER='File/Exit', /SEPARATOR


    ;---------------------------------------------------------------------
    ; Create our File toolbar container.
    ;
    self->Register, IDLitLangCatQuery('Menu:File:New'), 'IDLitOpNewTool', $
        IDENTIFIER='Toolbar/File/NewTool', ICON='new'
    self->Register, IDLitLangCatQuery('Menu:File:Open'), $
        PROXY='Operations/File/Open', $
        IDENTIFIER='Toolbar/File/Open'
    self->Register, IDLitLangCatQuery('Menu:File:Save'), $
        PROXY='Operations/File/Save', $
        IDENTIFIER='Toolbar/File/Save'
    self->Register, IDLitLangCatQuery('Menu:File:Print'), $
        PROXY='Operations/File/Print', $
        IDENTIFIER='Toolbar/File/Print'


    ;---------------------------------------------------------------------
    ;*** Edit Menu

    self->createfolders,'Operations/Edit',NAME=IDLitLangCatQuery('Menu:Edit')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Undo'), $
        'IDLitopUndo', $
        ACCELERATOR='Ctrl+Z', $
        IDENTIFIER='Edit/Undo', ICON='undo', /disable

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Redo'), $
        'IDLitopRedo', $
        ACCELERATOR='Ctrl+Y', $
        IDENTIFIER='Edit/Redo', ICON='redo',/disable

    ;; Clipboard...note these are proxied from the system registry!

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Cut'), $
        PROXY="/REGISTRY/OPERATIONS/CUT",$
        IDENTIFIER='Edit/Cut'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Copy') , $
        PROXY='/REGISTRY/OPERATIONS/COPY', $
        IDENTIFIER='Edit/Copy'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Paste') , $
        PROXY='/REGISTRY/OPERATIONS/Paste', $
        IDENTIFIER='Edit/Paste'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:PasteSpecial') , $
        PROXY='/REGISTRY/OPERATIONS/PASTESPECIAL', $
        IDENTIFIER='Edit/PasteSpecial'

    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Delete') , $
        PROXY='/REGISTRY/OPERATIONS/Delete', $
        IDENTIFIER='Edit/Delete'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:SelectAll') , $
        'IDLitopSelectAll', $
        DESCRIPTION="Select all visualizations in the current view.", $
        IDENTIFIER='Edit/SelectAll', $
        ICON='select'


    ;-----------------
    self->createfolders,'Operations/Edit/Grouping', $
                        NAME=IDLitLangCatQuery('Menu:Edit:Grouping')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Group'), $
        'IDLitopGroup', $
        IDENTIFIER='Edit/Grouping/Group', $
        ICON='group', $
        /SEPARATOR

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Ungroup'), $
        'IDLitopUngroup', $
        IDENTIFIER='Edit/Grouping/Ungroup', $
        ICON='ungroup'

    self->createfolders,'Operations/Edit/Order', $
                        NAME=IDLitLangCatQuery('Menu:Edit:Order')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:BringToFront'), $
        'IDLitopBringToFront', $
        IDENTIFIER='Edit/Order/BringToFront', $
        ICON='front'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:SendToBack'), $
        'IDLitopSendToBack', $
        IDENTIFIER='Edit/Order/SendToBack', $
        ICON='back'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:BringForward'), $
        'IDLitopBringForward', $
        IDENTIFIER='Edit/Order/BringForward', $
        ICON='front'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:SendBackward'), $
        'IDLitopSendBackward', $
        IDENTIFIER='Edit/Order/SendBackward', $
        ICON='back'


    ;---------------------------------------------------------------------
    ;*** Format Menu

    self->createfolders,'Operations/Edit/Style', $
                        NAME=IDLitLangCatQuery('Menu:Style')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Style:ApplyStyle') , $
        PROXY='/REGISTRY/OPERATIONS/Apply Style', $
        IDENTIFIER='Edit/Style/Apply Style'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Style:CreateStylefromSelection'), $
        'IDLitopStyleCreate', $
        IDENTIFIER='Edit/Style/Create Style', $
        ICON='style'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Style:StyleEditor'), $
        'IDLitopStyleEditor', $
        IDENTIFIER='Edit/Style/StyleEditor', $
        ICON='style'


    ;-----------------
    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Parameters'), $
        'IDLitopEditParameters', $
        IDENTIFIER='Edit/EditParameters', $
        ICON='binary'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Properties'), $
        'IDLitopPropertySheet', $
        DESCRIPTION='Display the Property Sheet for the item', $
        IDENTIFIER='Edit/Properties', $
        ICON='propsheet'


    ;---------------------------------------------------------------------
    ; Create our Edit toolbar container.
    ;
    self->Register, IDLitLangCatQuery('Menu:Edit:Undo'), $
        PROXY='Operations/Edit/Undo', $
        IDENTIFIER='Toolbar/Edit/Undo'
    self->Register, IDLitLangCatQuery('Menu:Edit:Redo'), $
        PROXY='Operations/Edit/Redo', $
        IDENTIFIER='Toolbar/Edit/Redo'
    self->Register, IDLitLangCatQuery('Menu:Edit:Cut'), $
        PROXY="/REGISTRY/OPERATIONS/CUT",$
        IDENTIFIER='Toolbar/Edit/Cut'
    self->Register, IDLitLangCatQuery('Menu:Edit:Copy'), $
        PROXY='/REGISTRY/OPERATIONS/COPY', $
        IDENTIFIER='Toolbar/Edit/Copy'
    self->Register, IDLitLangCatQuery('Menu:Edit:Paste'), $
        PROXY='/REGISTRY/OPERATIONS/Paste', $
        IDENTIFIER='Toolbar/Edit/Paste'


    ;---------------------------------------------------------------------
    ;*** Insert menu

    self->createfolders,'Operations/Insert', $
                        NAME=IDLitLangCatQuery('Menu:Insert')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:Visualization'), $
        'IDLitopInsertVis', $
        IDENTIFIER='Insert/Visualization', ICON='view'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:View'), $
        'IDLitopInsertView', $
        IDENTIFIER='Insert/View', ICON='view'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:DataSpace'), $
        'IDLitopInsertDataSpace', $
        IDENTIFIER='Insert/Data Space', ICON='mcr'

    self->createfolders,'Operations/Insert/Axis', $
                        NAME=IDLitLangCatQuery('Menu:Insert:Axis')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:XAxis'), $
        'IDLitOpInsertAxisX', $
        IDENTIFIER='Insert/Axis/X Axis', ICON='mcr'
    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:YAxis'), $
        'IDLitOpInsertAxisY', $
        IDENTIFIER='Insert/Axis/Y Axis', ICON='mcr'
    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:ZAxis'), $
        'IDLitOpInsertAxisZ', $
        IDENTIFIER='Insert/Axis/Z Axis', ICON='mcr'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:Grid'), $
    'IDLitopInsertMapGrid', $
    IDENTIFIER='Insert/Map/Grid', $
    ICON='axis'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:Continents'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/Continents', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:CountriesLow'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/CountriesLow', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:CountriesHigh'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/CountriesHigh', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:Rivers'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/Rivers', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:Lakes'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/Lakes', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:States'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/States', $
    ICON='demo'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Insert:Map:Provinces'), $
    'IDLitopInsertMapShape', $
    IDENTIFIER='Insert/Map/Provinces', $
    ICON='demo'

    ;---------------------------------------------------------------------
    ;*** Operations Menu
    self->createfolders,'Operations/Operations', $
                        NAME=IDLitLangCatQuery('Menu:Operations')

    self->RegisterOperation, $
      IDLitLangCatQuery('Menu:Operations:OperationsBrowser'), $
      'IDLitopBrowserOperation', $
      IDENTIFIER='Operations/Operations Browser' ; ,ICON='mcr'

    self->createfolders,'Operations/Operations/Macros', $
      NAME=IDLitLangCatQuery('Menu:Operations:Macros')

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:RunMacro'), $
        PROXY='/Registry/MacroTools/Run Macro', $
        IDENTIFIER='Operations/Macros/Run Macro'
    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:StartRecording'), $
        PROXY='/Registry/MacroTools/Start Recording', $
        IDENTIFIER='Operations/Macros/Start Recording'
    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:StopRecording'), $
        PROXY='/Registry/MacroTools/Stop Recording', $
        IDENTIFIER='Operations/Macros/Stop Recording'
    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:MacroEditor'), $
        PROXY='/Registry/MacroTools/Macro Editor', $
        IDENTIFIER='Operations/Macros/Macro Editor'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:Statistics'), $
        'IDLitopStatistics', $
        DESCRIPTION='Display statistics for the selected item', $
        IDENTIFIER='Operations/Statistics', ICON='sum', /SEPARATOR

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:MapProjection'), $
        'IDLitopMapProjection', $
        IDENTIFIER='Operations/Map Projection', ICON='surface'

  self->RegisterOperation, $
    IDLitLangCatQuery('Menu:Operations:MapRegisterImage'), $
    'IDLitopMapRegisterImage', $
    IDENTIFIER='Operations/MapRegisterImage', $
    ICON='demo'


    self->RegisterOperation, 'Map Limit', 'IDLitopMapLimit', $
        DESCRIPTION='Map Limit', $
        ICON='surface', $
        /PRIVATE, $
        IDENTIFIER='Operations/Map Limit'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:Histogram'), $
        'IDLitopHistogram', $
        DESCRIPTION='Perform the histogram operation on the selected item', $
        IDENTIFIER='Operations/Histogram', ICON='hist'

    self->createfolders,'Operations/Operations/Filter', $
                        NAME=IDLitLangCatQuery('Menu:Operations:Filter')

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:Convolution'), $
        'IDLitopConvolution', $
        DESCRIPTION='Perform the convolution operation on the selected item', $
        IDENTIFIER='Operations/Filter/Convolution', ICON='sum'

    self->RegisterOperation, $
      IDLitLangCatQuery('Menu:Operations:Median'), $
      'IDLitopMedianFilter', $
      DESCRIPTION='Perform the median filter operation on the selected item', $
      IDENTIFIER='Operations/Filter/Median', ICON='sum'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:Smooth'), $
        'IDLitopSmooth', $
        DESCRIPTION='Perform the smooth operation on the selected item', $
        IDENTIFIER='Operations/Filter/Smooth', ICON='sum'

    self->createfolders,'Operations/Operations/Rotate', $
                        NAME=IDLitLangCatQuery('Menu:Operations:Rotate')

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:RotateLeft'), $
        'IDLitopRotateLeft', $
        DESCRIPTION='Rotate left by 90 degrees', $
        IDENTIFIER='Operations/Rotate/RotateLeft', $
        ICON='rotate'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:RotateRight'), $
        'IDLitopRotateRight', $
        DESCRIPTION='Rotate right by 90 degrees', $
        IDENTIFIER='Operations/Rotate/RotateRight', $
        ICON='rotate'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:RotateByAngle'), $
        'IDLitopRotateByAngle', $
        DESCRIPTION='Rotate by a specified angle', $
        IDENTIFIER='Operations/Rotate/RotateByAngle', $
        ICON='rotate'

    self->createfolders,'Operations/Operations/Transform', $
                        NAME=IDLitLangCatQuery('Menu:Operations:Transform')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:Resample'), $
        'IDLitopResample', $
        IDENTIFIER='Operations/Transform/Resample', ICON='sum'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Operations:RotateData'), $
        'IDLitopRotateData', $
        DESCRIPTION='Rotate the data by a specified angle', $
        IDENTIFIER='Operations/Transform/RotateData', $
        ICON='sum'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:ScaleData'), $
        'IDLitopScaleFactor', $
        DESCRIPTION='Scale the data by a given factor', $
        IDENTIFIER='Operations/Transform/ScaleFactor', ICON='sum'



    ;---------------------------------------------------------------------
    ;*** Window Menu

    self->createfolders,'Operations/Window', $
                        NAME=IDLitLangCatQuery('Menu:Window')

    ;  Note: temporarily disabling ICON settings for browsers.
    self->RegisterOperation, IDLitLangCatQuery('Menu:Window:DataManager'), $
        'IDLitopDataManager', $
        IDENTIFIER='Window/Data Manager', $
        ICON='prop'; , ICON='mcr'

;     self->RegisterOperation,'Manipulator Browser','IDLitopBrowserManip', $
;         IDENTIFIER='Window/Manipulator Browser'; , ICON='mcr'

;     self->RegisterOperation, 'Tool Browser', 'IDLitopBrowserTool', $
;         IDENTIFIER='Window/Tool Browser'; , ICON='mcr'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Window:VisualizationBrowser'), $
        'IDLitopBrowserVis', $
        IDENTIFIER='Window/Visualization Browser'; , ICON='mcr'

    ;-----------------
    ; Keep canvas zoom identifiers, but do not expose them
    self->createfolders,'Operations/Window/Canvas Zoom', /PRIVATE, $
                        NAME=IDLitLangCatQuery('Menu:Window:CanvasZoom')

    self->RegisterOperation, '800%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/800%', $
        ICON='zoom', /SEPARATOR, /CHECKED
    self->RegisterOperation, '400%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/400%', $
        ICON='zoom', /CHECKED
    self->RegisterOperation, '200%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/200%', $
        ICON='zoom', /CHECKED
    self->RegisterOperation, '100%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/100%', $
        ICON='zoom', /CHECKED
    self->RegisterOperation, '75%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/75%', $
        ICON='zoom', /CHECKED
    self->RegisterOperation, '50%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/50%', $
        ICON='zoom', /CHECKED
    self->RegisterOperation, '25%', 'IDLitopCanvasZoom', $
        IDENTIFIER='Window/Canvas Zoom/25%', $
        ICON='zoom', /CHECKED


    self->RegisterOperation, IDLitLangCatQuery('Menu:Window:ZoomonResize'), $
        'IDLitopZoomResize', $
        ICON='zoom', $
        IDENTIFIER='Window/ZoomResize', /CHECKED

    self->RegisterOperation, IDLitLangCatQuery('Menu:Window:Layout'), $
        'IDLitopWindowLayout', $
        IDENTIFIER='Window/Layout'

    ;-----------------

    self->RegisterOperation, IDLitLangCatQuery('Menu:Window:FittoView'), $
        'IDLitopFitToView', $
        IDENTIFIER='Window/FitToView', $
        ICON='fitwindow', /SEPARATOR

    self->RegisterOperation, IDLitLangCatQuery('Menu:Window:IDLCommandLineFocus'), $
      'IDLitopCommandLineFocus', $
      IDENTIFIER='Window/IDLCommandLineFocus', $
      ACCELERATOR='Ctrl+I', $
      ICON='print', /SEPARATOR

    ;---------------------------------------------------------------------
    ;*** Help Menu
    self->createfolders,'Operations/Help', $
                        NAME=IDLitLangCatQuery('Menu:Help')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Help:HelponiTools'), $
        'IDLitopHelpiTools', $
        ACCELERATOR='F1', $
        IDENTIFIER='Help/HelpiTools'

    self->RegisterOperation, $
       IDLitLangCatQuery('Menu:Help:HelpontheiToolsDataManager'), $
       'IDLitopHelpDataManager', IDENTIFIER='Help/HelpDataManager'

    self->RegisterOperation, $
       IDLitLangCatQuery('Menu:Help:HelpontheiToolsParameterEditor'), $
       'IDLitopHelpParamEditor', IDENTIFIER='Help/HelpParamEditor'

    self->RegisterOperation, $
        IDLitLangCatQuery('Menu:Help:HelponSelectedItem'), $
        'IDLitopHelpSelection', $
        IDENTIFIER='Help/HelpSelection', /SEPARATOR

    self->RegisterOperation, IDLitLangCatQuery('Menu:Help:HelponthisiTool'), $
        'IDLitopHelpTool', $
        IDENTIFIER='Help/HelpTool'


    ;---------------------------------------------------------------------
    ;*** Manipulators
    self->RegisterManipulator, 'Arrow', 'IDLitManipArrow', $
        ICON='arrow', /DEFAULT, IDENTIFIER="ARROW", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Select')

    self->RegisterManipulator, 'Rotate', 'IDLitManipRotate', $
        ICON='rotate', IDENTIFIER="ROTATE", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Rotate')

    self->RegisterManipulator, 'View Pan', 'IDLitManipViewPan', $
        ICON='hand', IDENTIFIER="VIEWPAN", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Pan')

    ;---------------------------------------------------------------------
    ;*** View Zoom Manipulator
    self->RegisterManipulator, 'View Zoom', 'IDLitManipViewZoom', $
        IDENTIFIER='View/ViewZoom', ICON='zoom', $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:ViewZoom')

    ;---------------------------------------------------------------------
    ; *** View Zoom Combobox

    ; Combobox is not available on True64 (OSF Alpha)
    useCombobox = ~(!VERSION.os eq 'OSF')
    self->Register, 'View Zoom', 'IDLitopCanvasZoom', $
        IDENTIFIER='Toolbar/View/ViewZoom', $
        DROPLIST_EDIT=useCombobox, $
        DROPLIST_ITEMS=['800%', $
                        '400%', $
                        '200%', $
                        '100%', $
                        '75%',  $
                        '50%',  $
                        '25%'], $
        DROPLIST_INDEX=3, $
        /SINGLETON

    ;---------------------------------------------------------------------
    ;*** Annotation Manipulators
    self->RegisterManipulator, 'Text', 'IDLitAnnotateText', $
        ICON='text', IDENTIFIER="Annotation/Text", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateText')

    self->RegisterManipulator, 'Line', 'IDLitAnnotateLine', $
      ICON='line', IDENTIFIER="Annotation/Line", $
      DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateLine')

    self->RegisterManipulator, 'Rectangle', 'IDLitAnnotateRectangle', $
        ICON='rectangl', IDENTIFIER="Annotation/Rectangle", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateRectangle')

    self->RegisterManipulator, 'Oval', 'IDLitAnnotateOval', $
        ICON='ellipse', IDENTIFIER="Annotation/Oval", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateOval')

    self->RegisterManipulator, 'Polygon', 'IDLitAnnotatePolygon', $
        ICON='segpoly', IDENTIFIER="Annotation/Polygon", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotatePolygon')

    self->RegisterManipulator, 'Freehand', 'IDLitAnnotateFreehand', $
        ICON='freehand', IDENTIFIER="Annotation/Freehand", $
        DESCRIPTION='Click & drag to draw'



    ;---------------------------------------------------------------------
    ;*** DrawContext
    self->Register, 'Cut', $
        PROXY="/REGISTRY/OPERATIONS/CUT",$
        IDENTIFIER='ContextMenu/DrawContext/Cut'

    self->Register, 'Copy', $
        PROXY='/REGISTRY/OPERATIONS/COPY', $
        IDENTIFIER='ContextMenu/DrawContext/Copy'

    self->Register, 'Paste', $
        PROXY='/REGISTRY/OPERATIONS/Paste', $
        IDENTIFIER='ContextMenu/DrawContext/Paste'

    ;-----------------
    self->Register, 'Delete', $
        PROXY='/REGISTRY/OPERATIONS/Delete', $
        IDENTIFIER='ContextMenu/DrawContext/Delete'

    ;-----------------
    self->Register, 'Group', $
        PROXY='Operations/Edit/Grouping/Group', $
        IDENTIFIER='ContextMenu/DrawContext/Grouping/Group'

    self->Register, 'Ungroup', $
        PROXY='Operations/Edit/Grouping/Ungroup', $
        IDENTIFIER='ContextMenu/DrawContext/Grouping/Ungroup'

    self->Register, 'Bring To Front', $
        PROXY='Operations/Edit/Order/BringToFront', $
        IDENTIFIER='ContextMenu/DrawContext/Order/BringToFront'

    self->Register, 'Send To Back', $
        PROXY='Operations/Edit/Order/SendToBack', $
        IDENTIFIER='ContextMenu/DrawContext/Order/SendToBack'

    self->Register, 'Bring Forward', $
        PROXY='Operations/Edit/Order/BringForward', $
        IDENTIFIER='ContextMenu/DrawContext/Order/BringForward'

    self->Register, 'Send Backward', $
        PROXY='Operations/Edit/Order/SendBackward', $
        IDENTIFIER='ContextMenu/DrawContext/Order/SendBackward'

    ;-----------------
    self->Register, IDLitLangCatQuery('Menu:Edit:ExportImage'), $
        PROXY='Operations/File/ExportImage', $
        IDENTIFIER='ContextMenu/DrawContext/ExportImage'
        
    self->Register, IDLitLangCatQuery('Menu:Edit:Export'), $
        PROXY='Operations/File/CLExport', $
        IDENTIFIER='ContextMenu/DrawContext/CLExport'

    self->Register, 'Parameters...', $
        PROXY='Operations/Edit/EditParameters', $
        IDENTIFIER='ContextMenu/DrawContext/EditParameters'

    self->Register, 'Properties...', $
        PROXY='Operations/Edit/Properties', $
        IDENTIFIER='ContextMenu/DrawContext/Properties'

    ;---------------------------------------------------------------------
    ;*** CropContext
    self->Register, 'Crop...', 'IDLitopCropImage', $
        DESCRIPTION='Crop the selected image', $
        IDENTIFIER='ContextMenu/CropDrawContext/Crop', $
        ICON='crop', $
        /SINGLETON


    return, 1

end


;---------------------------------------------------------------------------
; IDLitToolBase__Define
;
; Purpose:
;   This method defines the IDLitTool class.
;

pro IDLitToolbase__Define
  ; Pragmas
  compile_opt idl2, hidden
  void = { IDLitToolbase,                     $
           inherits IDLitTool       $ ; Provides iTool interface
           }
end
