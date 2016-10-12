; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphicstool__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   GraphicsTool
;
; PURPOSE:
;   This file implements the IDL Tool base object for the graphics system, 
;   from which all other graphics tools are subclassed.
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
;   See GraphicsTool::Init
;
; METHODS:
;   This class has the following methods:
;
;   GraphicsTool::Init
;
; INTERFACES:
; IIDLProperty
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; GraphicsTool::Init
;
; Purpose:
; The constructor of the GraphicsTool object.
;
; Parameters:
; None.
;
function GraphicsTool::Init, _REF_EXTRA=_EXTRA
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

   self->RegisterOperation, IDLitLangCatQuery('Menu:File:Print'), $
        'IDLitopFilePrint', $
        ACCELERATOR='Ctrl+P', $
        DESCRIPTION='Print the contents of the active window', $
        IDENTIFIER='File/Print', ICON='print_24'
    ; Need both Save and Save As operations.
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Save'), $
        'IDLitopFileSave', $
        IDENTIFIER='File/Save', ICON='Save_24'
    self->RegisterOperation, IDLitLangCatQuery('Menu:File:SaveAs'), $
        'IDLitopFileSaveAs', $
        ACCELERATOR='Ctrl+S', $
        IDENTIFIER='File/SaveAs', ICON='Save_24', /SEPARATOR
;    self->RegisterOperation, IDLitLangCatQuery('Menu:File:Open'), $
;        'IDLitopFileOpen', $
;        ACCELERATOR='Ctrl+O', $
;        DESCRIPTION='Open an existing data or image file', $
;        IDENTIFIER='File/Open', ICON='open'
   
    ;---------------------------------------------------------------------
    ; Create our File toolbar container.
    ;
;    self->Register, IDLitLangCatQuery('Menu:File:Open'), $
;        PROXY='Operations/File/Open', $
;        IDENTIFIER='Toolbar/File/Open'
  self->Register, IDLitLangCatQuery('Menu:File:Print'), $
        PROXY='Operations/File/Print', $
        IDENTIFIER='Toolbar/File/Print'
    self->Register, IDLitLangCatQuery('Menu:File:SaveAs'), $
        PROXY='Operations/File/SaveAs', $
        IDENTIFIER='Toolbar/File/SaveAs'
    

 ;---------------------------------------------------------------------
    ; Need this for double click to work to bring up the property sheet.
    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Properties'), $
        'IDLitopEditPropertySheet', $
        DESCRIPTION='Display the Property Sheet for the item', $
        IDENTIFIER='Edit/Properties', $
        ICON='Properties_24'

    self->RegisterOperation, 'Reset Axis Range', $
        'IDLitopDataspaceReset', $
        DESCRIPTION='Reset dataspace ranges', $
        IDENTIFIER='Edit/DataspaceReset', $
        ICON='ResetRange_24', /PRIVATE

    self->Register, IDLitLangCatQuery('Menu:Window:ResetDataspaceRanges'), $
        PROXY='Operations/Edit/DataspaceReset', $
        IDENTIFIER='Toolbar/Edit/DataspaceReset'
        

    ;---------------------------------------------------------------------
    ;*** Edit Menu

    self->createfolders,'Operations/Edit',NAME=IDLitLangCatQuery('Menu:Edit')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Undo'), $
        'IDLitopUndo', $
        ACCELERATOR='Ctrl+Z', $
        IDENTIFIER='Edit/Undo', ICON='Undo_24', /disable

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Redo'), $
        'IDLitopRedo', $
        ACCELERATOR='Ctrl+Y', $
        IDENTIFIER='Edit/Redo', ICON='Redo_24', /disable

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:Delete') , $
        PROXY='/REGISTRY/OPERATIONS/Delete', $
        IDENTIFIER='Edit/Delete'

    ;---------------------------------------------------------------------
    ; Create our Edit toolbar container.
    ;
    self->Register, IDLitLangCatQuery('Menu:Edit:Undo'), $
        PROXY='Operations/Edit/Undo', $
        IDENTIFIER='Toolbar/Edit/Undo'
    self->Register, IDLitLangCatQuery('Menu:Edit:Redo'), $
        PROXY='Operations/Edit/Redo', $
        IDENTIFIER='Toolbar/Edit/Redo'

  self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:BringToFront'), $
        'IDLitopBringToFront', $
        IDENTIFIER='Edit/Order/BringToFront', $
        ICON='bringtofront24'

    self->RegisterOperation, IDLitLangCatQuery('Menu:Edit:SendToBack'), $
        'IDLitopSendToBack', $
        IDENTIFIER='Edit/Order/SendToBack', $
        ICON='sendtoback24'

    self->RegisterOperation, 'Order', $
        'IDLitopOrder', $
        IDENTIFIER='Edit/Order/Order', $
        ICON='back', /PRIVATE
        
    self->Register, IDLitLangCatQuery('Menu:Edit:BringToFront'), $
        PROXY='Operations/Edit/Order/BringToFront', $
        IDENTIFIER='Toolbar/Edit/BringToFront'
        
    self->Register, IDLitLangCatQuery('Menu:Edit:SendToBack'), $
        PROXY='Operations/Edit/Order/SendToBack', $
        IDENTIFIER='Toolbar/Edit/SendToBack'
        
    self->RegisterOperation, 'Copy Window', $
        'IDLitopclipcopy', $
        ACCELERATOR='Ctrl+Insert', $
        IDENTIFIER='Edit/Copy', ICON='copy_24'
        
    self->Register, 'Copy Window', $
        PROXY='Operations/Edit/Copy', $
        IDENTIFIER='Toolbar/Edit/Copy'

    

    ;---------------------------------------------------------------------
    ;*** Insert menu

    self->createfolders,'Operations/Insert', $
                        NAME=IDLitLangCatQuery('Menu:Insert')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Insert:Visualization'), $
        'IDLitopInsertVis', $
        IDENTIFIER='Insert/Visualization', ICON='view'

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
    IDLitLangCatQuery('Menu:Operations:MapRegisterImage'), $
    'IDLitopMapRegisterImage', $
    IDENTIFIER='Operations/MapRegisterImage', $
    ICON='demo'

    ;---------------------------------------------------------------------
    ;*** Operations Menu
    self->createfolders,'Operations/Operations', $
                        NAME=IDLitLangCatQuery('Menu:Operations')

    self->RegisterOperation, IDLitLangCatQuery('Menu:Operations:MapProjection'), $
        'IDLitopMapProjection', $
        IDENTIFIER='Operations/Map Projection', ICON='surface'


    ;-----------------
    ;*** Manipulators
    self->RegisterManipulator, 'Arrow', 'GraphicsManip', $
        ICON='arrow', /DEFAULT, IDENTIFIER="ARROW", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Select')

;    self->RegisterManipulator, 'Arrow', 'IDLitManipArrow', $
;        ICON='arrow', /DEFAULT, IDENTIFIER="ARROW", $
;        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Select')
;
;    self->RegisterManipulator, 'Rotate', 'IDLitManipRotate', $
;        ICON='rotate', IDENTIFIER="ROTATE", $
;        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Rotate')
;
;    ;---------------------------------------------------------------------
;    ;*** Data range Manipulators
;    self->RegisterManipulator, 'Pan', 'IDLitManipDataPan', $
;        ICON='hand', IDENTIFIER="DATAPAN", $
;        DESCRIPTION=IDLitLangCatQuery('Status:Framework:Pan')
;
;    self->RegisterManipulator, 'Zoom', 'IDLitManipDataRangeZoom', $
;        IDENTIFIER='DATAZOOM', ICON='zoom', $
;        DESCRIPTION=IDLitLangCatQuery('Status:Framework:ViewZoom')

    ;---------------------------------------------------------------------
    ;*** Annotation Manipulators
    self->RegisterManipulator, 'Text', 'IDLitAnnotateText', $
        ICON='text24', IDENTIFIER="Annotation/Text", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateText')

    self->RegisterManipulator, 'Line', 'IDLitAnnotateLine', $
      ICON='line24', IDENTIFIER="Annotation/Line", $
      DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateLine')

    self->RegisterManipulator, 'Rectangle', 'IDLitAnnotateRectangle', $
        ICON='rectangle24', IDENTIFIER="Annotation/Rectangle", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateRectangle')

    self->RegisterManipulator, 'Oval', 'IDLitAnnotateOval', $
        ICON='oval24', IDENTIFIER="Annotation/Oval", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotateOval')

    self->RegisterManipulator, 'Polygon', 'IDLitAnnotatePolygon', $
        ICON='polygon24', IDENTIFIER="Annotation/Polygon", $
        DESCRIPTION=IDLitLangCatQuery('Status:Framework:AnnotatePolygon')

    self->RegisterManipulator, 'Freehand', 'IDLitAnnotateFreehand', $
        ICON='freehand24', IDENTIFIER="Annotation/Freehand", $
        DESCRIPTION='Click & drag to draw'

    self->Register, IDLitLangCatQuery('Menu:Edit:Properties'), $
        PROXY='Operations/Edit/Properties', $
        IDENTIFIER='Toolbar/Edit/Properties'


    return, 1

end


;---------------------------------------------------------------------------
; GraphicsTool__Define
;
; Purpose:
;   This method defines the IDLitTool class.
;

pro GraphicsTool__Define
  ; Pragmas
  compile_opt idl2, hidden
  void = { GraphicsTool,                     $
           inherits IDLitTool       $ ; Provides iTool interface
           }
end
