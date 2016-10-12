; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsystem__define.pro#2 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitSystem
;
; PURPOSE:
;   This file implements the overall tool system/enviroment that
;   is used to manage items that are outside the tool scope.
;
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitComponent
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitSystem::Init
;
; METHODS:
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; IDLitSystem::Init
;;
;; Purpose:
;;   Lifecycle routine for the system.
;;
;;
Function IDLitSystem::Init, _EXTRA=_EXTRA

  compile_opt hidden, idl2

   ;; Maintain the object in a common block!!
   common __IDLitSys$SystemCache$__, c_oSystem


  HEAP_NOSAVE, self

  if(self->IDLitContainer::Init(_EXTRA=_EXTRA, NAME="IDL Tools System", $
                        IDENTIFIER="") ne 1)then $
    return, 0

    ; In case any of our initialization code asks for the system from
    ; _IDLitSys_GetSystem() before we return from ::Init, be sure
    ; to set the common block variable here.
    ; Note: This *assumes* that the rest of ::Init will not fail.
    c_oSystem = self

  ;; The system is the root o a container hiearchy which is
  ;; managed by the the _IDLitObjDescRegistry super-class of the
  ;; system object. Create the folders used in the system.
  self->CreateFolders, ["Tools", "ClipBoard", "Services"]

   ;; create the root of the data manager
   oData = Obj_New("IDLitDataManagerFolder", NAME="Data Manager", TOOL=self)
   self->Add, oData


   ;; Make use of IMessaging
   self->IDLitIMessaging::_SetTool, self

   ;; Set the object for our last error.
   self._oLastError = obj_new("IDLitError", CODE=-1)

   self->_InitToolLayout

   ;; Initialize the system UI.
   IDLitUISystem, self

   self->IDLitSystem::_InitRegistry

   return, 1
end

;;---------------------------------------------------------------------------
;; IDLitSystem::_InitRegistry
;;
;; Purpose:
;;   Intializes and builds the internal "registry" for the values
;;   associated with the tool
;;
;;   This is an internal routine.
pro IDLitSystem::_InitRegistry
   compile_opt idl2, hidden

   ;; Create a storage container for the  descriptors
  self->CreateFolders, [ $
                         "Registry", $
                         "Registry/Tools", $
                         "Registry/Styles", $
                         "Registry/Operations", $
                         "Registry/Widgets", $
                         "Registry/Widgets/Interface", $
                         "Registry/Widgets/Services", $
                         "Registry/Widgets/Panels", $
                         "Registry/Macros", $
                         "Registry/History" $
                         ]

   oReg = self->GetByIdentifier("/Registry")
   heap_nosave, oReg

   oMacros = self->GetByIdentifier("/Registry/Macros")
   oMacros->SetProperty, DESCRIPTION='Existing Macros'

   oHistory = self->GetByIdentifier("/Registry/History")
   oHistory->SetProperty, DESCRIPTION='History of operations and property settings'

   ;; Do we have a saved reg file?
   didRestore = self->_RestoreSettings()
   if(~didRestore)then begin
       self->CreateFolders, [ $
                              "Registry/Settings/File Readers", $
                              "Registry/Settings/File Writers"]
   endif

   self->IDLitSystem::_RegisterDefaultItems

end


;;---------------------------------------------------------------------------
;; IDLitSystem::_GetAllSuperClasses
;;
;; Purpose:
;;   Used to get all the superclasses for a given class. Primarly used
;;   to restore a set of objects
;;
;; Parameters:
;;   strClass   - The class to search for
;;
;; Return Value
;;   The list of super-classes including strClass

function IDLitSystem::_GetAllSuperClasses, strClass

    compile_opt idl2, hidden

    classes = strClass
    for i=0,N_ELEMENTS(strClass)-1 do begin
        super = OBJ_CLASS(strClass[i], COUNT=nsuper, /SUPERCLASS)
        if (nsuper gt 0) then $
            classes = [classes, self->_GetAllSuperClasses(super)]
    endfor

    return, classes

end
;;---------------------------------------------------------------------------
;; IDLitSystem::_ResetSettings
;;
;; Purpose:
;;   If called, the preference settings are rolled back to the default
;;   settings. Also, the current prefs file is removed.
;;
;; Parameters:
;;   None.

pro IDLitSystem::_ResetSettings
   compile_opt hidden, idl2

   ;; delete prefrences from the registry
   OBJ_DESTROY, self->RemoveByIdentifier("/REGISTRY/SETTINGS")

   ;; Create our folders
   self->CreateFolders, [ $
                          "Registry/Settings/File Readers", $
                          "Registry/Settings/File Writers"]
   ;; Okay, restore the settings
   self->_RegisterPreferences

   ;; update styles and available languages properties
   oGeneral = self->GetByIdentifier('/REGISTRY/SETTINGS/GENERAL_SETTINGS')
   if (OBJ_VALID(oGeneral)) then oGeneral->VerifySettings

    ; Do we have a saved reg file? Delete it.
    if (IDLitGetResource('', strName, /USERDIR)) then begin
        strPrefs = file_expand_path(filepath("itools_prefs.sav", root_dir=strName))
        file_delete, strPrefs, /allow_nonexistent, /quiet
        if(file_test(strPrefs))then begin
            self->ErrorMessage, $
                [IDLitLangCatQuery('Error:ResetSettings:Text1'), $
                 strPrefs, IDLitLangCatQuery('Error:ResetSettings:Text2')], $
                title=IDLitLangCatQuery('Error:ResetSettings:Title'), severity=1
        endif
    endif

end


;---------------------------------------------------------------------------
; Make sure we can create an object, given its descriptor.
;
; Example: If a user has registered a file reader that no longer exists,
; but the preferences still contained that reader, we need
; to quietly remove that reader.
;
function IDLitSystem::VerifyDescriptor, oDesc

    compile_opt hidden, idl2

    if (~OBJ_ISA(oDesc, 'IDLitObjDesc')) then $
        return, 1 ; success (not a descriptor class)

    ; We do not want to use GetObjectInstance, because that will
    ; create an object instance, which for singletons, will
    ; persist in the object. But the System objdesc's should
    ; never need to have its singletons created. We wouldn't
    ; want them to be created, because then those singletons
    ; would be saved within the Preferences file.
    ; So...just check the classname to make sure it is valid.
    oDesc->GetProperty, CLASSNAME=classname

    CATCH, iErr
    if (iErr ne 0) then begin
        CATCH, /CANCEL
        return, 0 ; failure
    endif

    void = CREATE_STRUCT(NAME=classname)

    return, 1 ; success

end


;---------------------------------------------------------------------------
; Make sure all items within a container are valid ObjDesc objects.
; Used when restoring preferences.
;
pro IDLitSystem::VerifyContainer, oContainer

    compile_opt hidden, idl2

    if (~OBJ_ISA(oContainer, 'IDL_Container')) then $
        return

    oChildren = oContainer->Get(/ALL, COUNT=nChild)
    for i=0,nChild-1 do begin
        if OBJ_ISA(oChildren[i], 'IDL_Container') then begin
            self->VerifyContainer, oChildren[i]
            continue
        endif
        if (~self->VerifyDescriptor(oChildren[i])) then begin
            oContainer->Remove, oChildren[i]
            OBJ_DESTROY, oChildren[i]
        endif
    endfor

end


;;---------------------------------------------------------------------------
;; IDLitSystem::_RestoreSettings
;;
;; Purpose:
;;   Will restore a settings file if it exists, and insure that all
;;   object implementations are compiled.
;;
;; Parameters:
;;   None
;;
;; Return Value:
;;    1 - Success, 0 Failure
;;
function IDLitSystem::_RestoreSettings
   compile_opt hidden, idl2

    ; Do we have a saved reg file?
    if (~IDLitGetResource('', strName, /USERDIR)) then $
        return, 0
    strPrefs = file_expand_path(filepath("itools_prefs.sav", $
        root_dir=strName))

   if (~FILE_TEST(strPrefs)) then $
    return, 0

    ; First retrieve all structure/object classnames so we
    ; can instantiate the structures. This prevents the save file
    ; from restoring old object definitions, and also compiles all
    ; of the methods within the __define files.
    oSaveFile = OBJ_NEW('IDL_Savefile', strPrefs)
    structs = oSaveFile->Names(COUNT=nstruct, /STRUCTURE_DEFINITION)
    OBJ_DESTROY, oSaveFile
    for i=0,nstruct-1 do $
        void = CREATE_STRUCT(NAME=structs[i])

    RESTORE, strPrefs, restored_objects=oRestored, /RELAXED_STRUCTURE

; Retrieve the iTools version.
@idlitconfig.pro

    ; Check the restore version with the current version of the tools.
    ; See the save settings routine for reference
    if ((N_ELEMENTS(oSettings) eq 0) || $
        (PREFERENCES_VERSION ne ITOOLS_STRING_VERSION)) then begin
        ; Be sure to destroy all the objects that we couldn't use.
        if (N_ELEMENTS(oRestored) gt 0) then $
            OBJ_DESTROY, oRestored
        return, 0
    endif

    ; Make sure all our file reader/writers are still available.
    ; Throw away the unknown ones.
    self->VerifyContainer, oSettings

    OBJ_DESTROY, self->RemoveByIdentifier('/Registry/Settings')
    self->AddByIdentifier, "Registry", oSettings

    oGeneral = self->GetByIdentifier("/REGISTRY/SETTINGS/GENERAL_SETTINGS")
    oGeneral->_SetTool, self

    ;; reset language, if needed
    oGeneral->getProperty,_LANGUAGE=desiredLang
    oSrvLangCat = self->GetService('LANGCAT')
    IF obj_valid(oSrvLangCat) && $
      (strupcase(desiredLang) NE $
       strupcase(oSrvLangCat->GetLanguage())) THEN $
      oSrvLangCat->SetLanguage,desiredLang

    ; Hook the tool objref back up to all the objects.
    imsg = WHERE(OBJ_ISA(oRestored, 'IDLitIMessaging') or $
        OBJ_ISA(oRestored, 'IDLitObjDescTool'), nmsg)
    for i=0,nmsg-1 do begin
        oRestored[imsg[i]]->_SetTool, self
    endfor

   return, 1
end


;;---------------------------------------------------------------------------
;; IDLitSystem::_SaveSettings
;;
;; Purpose:
;;  Will save the current system preferences to the users .idl/itools
;;  directory
;;
;; Parameters:
;;   None.
;;
pro IDLitSystem::_SaveSettings
   compile_opt hidden, idl2


    if (LMGR(/DEMO)) then begin
        ; Only throw up a dialog once per session.
        if (~self._bThrewDemoErr) then begin
            self._bThrewDemoErr = 1b
            self->ErrorMessage, SEVERITY=2, $
                [IDLitLangCatQuery('Error:DemoModePrefs:Text1'), $
                IDLitLangCatQuery('Error:DemoModePrefs:Text2')]
        endif
        return
    endif

   ;; Save our settings
   ;; Make sure we can write to this directory
   if (~IDLitGetResource('', strName, /USERDIR, /WRITE)) then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:CannotWritePrefsDir:Text') +strName, $
         severity=1
       return
   endif

   strPrefs = file_expand_path(filepath("itools_prefs.sav", root_dir=strName))


   ;; Get the settings folder and just save it off.
   oSettings = self->GetByIdentifier("/REGISTRY/SETTINGS")

   ;; Set up a catch block to handle any errors save might throw at us.
@idlit_catch
   if(iErr ne 0)then begin
       catch,/cancel
       self->ErrorMessage, IDLitLangCatQuery('Error:CannotWritePrefs:Text') +strPrefs, $
         severity=1
       return
   endif
@idlitconfig.pro
   PREFERENCES_VERSION =  ITOOLS_STRING_VERSION
   save, file=strPrefs, oSettings, PREFERENCES_VERSION, /compress
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_InitToolLayout
;;
;; Purpose:
;;    Initalize the tool layout parameters
;;
pro IDLitSystem::_InitToolLayout
    compile_opt idl2, hidden

@idlit_catch.pro
    if(iErr ne 0)then begin ;; no X connection probably
        catch,/cancel
        return
    endif
    szScreen = get_screen_size()
    self._szScreen = szScreen/[2,5]
    self._nOffset = 30 ;; our delta for cascading
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_GetNextToolLocation
;;
;; Purpose:
;;   Return an X and Y offset for the next tool. This is used for
;;   a default cascading layout.
;;
;; Return Value:
;;   [x,y]   - Array that contains an x, y offset.

function IDLitSystem::_GetNextToolLocation
    compile_opt idl2, hidden

    if(self._szScreen[0] eq 0)then return,[0,0]

    INCREMENT=6
    self._iOffset = self._iOffset mod (2*INCREMENT)
    yLoc = (self._iOffset mod INCREMENT)*self._nOffset
    xLoc = yLoc + (self._iOffset/INCREMENT)*self._szScreen[1]
    self._iOffset++ ;; move to the next location
    return,[xLoc,yLoc]
end


;;---------------------------------------------------------------------------
;; IDLitSystem::_RegisterDefaultItems
;;
;; Purpose:
;;   This method is called during initialization to register the
;;   default items contained in the system registries.
;;
;; Parameters:
;;   None.
;
pro IDLitSystem::_RegisterDefaultItems, NO_DEFAULT_SETTINGS=no_defaults

    compile_opt idl2, hidden

;; An alternative method to load up the available tools will be
;; needed. Possibly an XML file.
    self->_RegisterTools

    self->RegisterUserInterface, "Default", "IDLitwdTool", $
        DESCRIPTION="IDL Core Default Tool Interface"

    self->RegisterUserInterface, "Graphic", "IDLitwdGraphicTool", $
        DESCRIPTION="IDL Graphics Tool"

; CT, Nov 2004.
    self->RegisterUserInterface, "None", "IDLituiBuffer", $
        DESCRIPTION="IDL Tool Window"
    self->RegisterUserInterface, "Buffer", "GraphicsBuffer", $
        DESCRIPTION="IDL Graphics Buffer"

    self->_RegisterUIPanels
    self->_RegisterVisualizations
    self->_RegisterOperations
    self->_RegisterUIServices
    self->_AddServices

   self->RegisterToolFunctionality

   ;; If we are not setting defaults, return
   if(keyword_set(no_defaults))then return

   self->_RegisterPreferences

end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterTools

    compile_opt hidden, idl2

    self->RegisterTool, "Image Tool", "IDLitToolImage", $
        DESCRIPTION="IDL Image Tool"

    self->RegisterTool, "Plot Tool", "IDLitToolPlot", $
        DESCRIPTION="IDL Plot Tool"

    self->RegisterTool, "Surface Tool", "IDLitToolSurface", $
        DESCRIPTION="IDL Surface Tool"

    self->RegisterTool, "Volume Tool", "IDLitToolVolume", $
        DESCRIPTION="IDL Volume Tool"

    self->RegisterTool, "Contour Tool", "IDLitToolContour", $
        DESCRIPTION="IDL Contour Tool"

    self->RegisterTool, "Map Tool", "IDLitToolMap", $
        DESCRIPTION="IDL Map Tool"

    self->RegisterTool, "Vector Tool", "IDLitToolVector", $
        DESCRIPTION="IDL Vector Tool"

    self->RegisterTool, "Base Tool", "IDLitToolBase", $
        DESCRIPTION="IDL Base Tool"

    self->RegisterTool, "Graphic", "GraphicsTool", $
        DESCRIPTION="IDL Graphic Tool"

end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterUIPanels

    compile_opt hidden, idl2

    self->RegisterUIPanel, "Volume Panel", "IDLitwdVolMenu", $
        TYPE="IDLVOLUME"

    self->RegisterUIPanel, "Image Panel", "IDLitwdImgMenu", $
        TYPE="IDLIMAGE"

    self->RegisterUIPanel, "Map Panel", "IDLitwdMapPanel", $
        TYPE=['IDLMAP', 'IDLSHAPEPOLYGON', $
            'IDLSHAPEPOLYLINE', 'IDLSHAPEPOINT']

end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterVisualizations

    compile_opt hidden, idl2

    self->RegisterVisualization, 'Plot', 'IDLitVisPlot', $
        ICON='plot'
    self->RegisterVisualization, 'Plot3D', 'IDLitVisPlot3D', $
        ICON='plot'
    self->RegisterVisualization, 'Surface', 'IDLitVisSurface', $
        ICON='surface'
    self->RegisterVisualization, 'Image', 'IDLitVisImage', $
        ICON='demo'
    self->RegisterVisualization, 'Contour', 'IDLitVisContour', $
        ICON='contour'
    self->RegisterVisualization, 'Volume', 'IDLitVisVolume', $
        ICON='volume'
    self->RegisterVisualization, 'Isosurface', 'IDLitVisIsosurface', $
        ICON='volume'
    self->RegisterVisualization, 'Interval Volume', 'IDLitVisIntVol', $
        ICON='volume'
    self->RegisterVisualization, 'Image Plane', 'IDLitVisImagePlane', $
        ICON='image'
    self->RegisterVisualization, 'Plot Profile', 'IDLitVisPlotProfile', $
        ICON='profile'
    self->RegisterVisualization, 'Colorbar', 'IDLitVisColorbar', $
        ICON='colorbar'
    self->RegisterVisualization, 'Histogram', 'IDLitVisHistogram', $
        ICON='hist'
    self->RegisterVisualization, 'Light', 'IDLitVisLight', $
        ICON='bulb'
    self->RegisterVisualization, 'Data Space', 'IDLitVisNormDataSpace', $
        ICON='dataspace'
    self->RegisterVisualization, 'Axis', 'IDLitVisAxis', $
        ICON='axis'
    self->RegisterVisualization, 'IDL Graphics Object', 'IDLitVisGRObject', $
        ICON='demo', /PRIVATE
    self->RegisterVisualization, 'Visualization Layer', 'IDLitgrLayer', $
        ICON='layer'
    self->RegisterVisualization, 'Shape Polygon', 'IDLitVisShapePolygon', $
        ICON='drawing'
    self->RegisterVisualization, 'Shape Polyline', 'IDLitVisShapePolyline', $
        ICON='drawing'
    self->RegisterVisualization, 'Shape Point', 'IDLitVisShapePoint', $
        ICON='drawing'
    self->RegisterVisualization, 'Map Grid', 'IDLitVisMapGrid', $
        ICON='axis'
    self->RegisterVisualization, 'Vector', 'IDLitVisVector', $
        ICON='fitwindow'
    self->RegisterVisualization, 'Streamline', 'IDLitVisStreamline', $
        ICON='polar'
    self->RegisterVisualization, 'BarPlot', 'IDLBarPlot', $
        ICON='plot'

    ;-----------------
    self->RegisterAnnotation, 'Text', 'IDLitVisText', $
        DESCRIPTION='Text Annotation', $
        ICON='text', HELP="idlitannotatetext"
    self->RegisterAnnotation, 'Line', 'IDLitVisPolyline', $
        DESCRIPTION='Line Annotation', $
        ICON='line', HELP="idlitannotateline"
    self->RegisterAnnotation, 'Rectangle', 'IDLitVisPolygon', $
        DESCRIPTION='Rectangle Annotation', $
        ICON='rectangl', HELP="idlitannotaterectangle"
    self->RegisterAnnotation, 'Oval', 'IDLitVisPolygon', $
        DESCRIPTION='Oval Annotation', $
        ICON='ellipse', HELP="idlitannotateoval"
    self->RegisterAnnotation, 'Polygon', 'IDLitVisPolygon', $
        DESCRIPTION='Polygon Annotation', $
        ICON='segpoly', HELP="idlitannotatepolygon"
    self->RegisterAnnotation, 'FreeHand', 'IDLitVisPolygon', $
        DESCRIPTION='FreeHand Annotation', $
        ICON='freehand', HELP="idlitannotatefreehand"
    self->RegisterAnnotation, 'Legend', 'IDLitVisLegend', $
        DESCRIPTION='Legend Annotation', $
        ICON='vw-smlic'
    self->RegisterAnnotation, 'Line Profile', 'IDLitVisLineProfile', $
        DESCRIPTION='Line Profile Annotation', $
        ICON='profile'
    self->RegisterAnnotation, 'Line Profile 3D', 'IDLitVisLineProfile3D', $
        DESCRIPTION='3D Line Profile Annotation', $
        ICON='profile'
    self->RegisterAnnotation, 'ROI', 'IDLitVisROI', $
        DESCRIPTION='Region of interest annotation', $
        ICON='freeform', $
        ROI_TYPE=2, $       ; closed polygon
        OBJ_DESCRIPTOR="IDLitObjDescROI"   ; override default ObjDesc

end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterOperations

    compile_opt hidden, idl2

    ;; clipboard
    self->RegisterOperation, 'Cut', 'IDLitopClipCut', $
        ACCELERATOR='Ctrl+X', $
        IDENTIFIER='CUT', $
        DESCRIPTION='Cut the selection and put it on the clipboard', $
        ICON='cut', /SEPARATOR

    self->RegisterOperation, 'Copy', 'IDLitopClipCopy', $
        ACCELERATOR='Ctrl+C', $
        IDENTIFIER='COPY', $
        DESCRIPTION='Copy the selection and put it on the clipboard', $
        ICON='copy'

    self->RegisterOperation, 'Paste', 'IDLitopClipPaste', $
        ACCELERATOR='Ctrl+V', $
        IDENTIFIER='PASTE', $
        DESCRIPTION='Paste the contents of the clipboard.', $
        ICON='paste'

    self->RegisterOperation, 'Paste Special', $
        IDENTIFIER="PASTESPECIAL", $
        'IDLitopClipPasteSpecial', $
        DESCRIPTION='Paste the contents of the clipboard using the original data source.', $
        ICON='paste'

    self->RegisterOperation, 'Delete', 'IDLitopEditDelete', $
        IDENTIFIER="DELETE", $
        ; Do not apply the accelerator here
        ; Delete will be called by the manipulatormanager OnKeyBoard action
;        ACCELERATOR='Del', $
        DESCRIPTION='Delete the selection', $
        /SEPARATOR, $
        ICON='delete'

    self->RegisterOperation, 'Apply Style...', 'IDLitopStyleApply', $
        IDENTIFIER='APPLY STYLE', $
        DESCRIPTION='Apply a style', $
        ICON='style'

    ; register the following operations in the macro tools folder on
    ; the system instead of in the tool's operations folder.
    ; Register the operations with Register instead of
    ; RegisterOperation since the latter assumes
    ; it is a subfolder of operations.
    self->createfolders,'Registry/MacroTools', $
                        NAME='Macro Tools'

    self->Register, 'Selection Change', 'IDLitopSelectionChange', $
        DESCRIPTION='Selection Change', $
        ICON='select', $
        IDENTIFIER='/Registry/MacroTools/SelectionChange', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Tool Change', 'IDLitopToolChange', $
        DESCRIPTION='Tool Change', $
        IDENTIFIER='/Registry/MacroTools/ToolChange', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Scale', 'IDLitopMacroScale', $
        DESCRIPTION='Scale', $
        ICON='scale', $
        IDENTIFIER='/Registry/MacroTools/Scale', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Translate', 'IDLitopMacroTranslate', $
        DESCRIPTION='Translate', $
        ICON='scale', $ ; use scale for arrow manip, no translate bitmap
        IDENTIFIER='/Registry/MacroTools/Translate', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'View Pan', 'IDLitopMacroViewPan', $
        DESCRIPTION='View Pan', $
        ICON='pan', $ ; use scale for arrow manip, no translate bitmap
        IDENTIFIER='/Registry/MacroTools/ViewPan', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Data Pan', 'IDLitopMacroDataPan', $
        DESCRIPTION='Data Pan', $
        ICON='pan', $ ; use scale for arrow manip, no translate bitmap
        IDENTIFIER='/Registry/MacroTools/DataPan', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Rotate', 'IDLitopMacroRotate', $
        DESCRIPTION='Rotate', $
        ICON='rotate', $
        IDENTIFIER='/Registry/MacroTools/Rotate', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'View Zoom', 'IDLitopMacroZoom', $
        DESCRIPTION='Zoom', $
        ICON='zoom', $
        IDENTIFIER="/Registry/MacroTools/Zoom", $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Range Change', 'IDLitopMacroRangeChange', $
        DESCRIPTION='Range Change', $
        ICON='data_range', $
        IDENTIFIER="/Registry/MacroTools/Range Change", $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Delay', 'IDLitopMacroDelay', $
        DESCRIPTION='Macro Delay', $
        ICON='hourglass', $
        IDENTIFIER="/Registry/MacroTools/Delay", $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Step Delay Change', 'IDLitopMacroStepDelayChange', $
        DESCRIPTION='Change the macro step delay', $
        ICON='hourglass', $
        IDENTIFIER="/Registry/MacroTools/StepDelayChange", $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    self->Register, 'Step Display Change', 'IDLitopMacroStepDisplayChange', $
        DESCRIPTION='Change the macro step display', $
        ICON='image', $
        IDENTIFIER="/Registry/MacroTools/StepDisplayChange", $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)

    ; The following operations are registered on the system
    ; since the macro facility spans tools. They are registered
    ; in macro tools, hidden via the private keyword, and
    ; proxied in the operations menu.  This also allows them
    ; to be proxied in some other location if desired by an
    ; external tools developer.
    self->Register, 'Run Macro', $
        'IDLitopRunMacro', $
        ACCELERATOR='F5', $
        ICON='mcr', $
        IDENTIFIER='/Registry/MacroTools/Run Macro', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /PRIVATE, $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)
    self->Register, 'Start Recording', $
        'IDLitopMacroRecordStart', $
        ACCELERATOR='Shift+F5', $
        ICON='mcr', $
        IDENTIFIER='/Registry/MacroTools/Start Recording', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /PRIVATE, $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)
    self->Register, 'Stop Recording', $
        'IDLitopMacroRecordStop', $
        ACCELERATOR='Ctrl+F5', $
        ICON='mcr', $
        IDENTIFIER='/Registry/MacroTools/Stop Recording', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /DISABLE, $ ; initially desensitized
        /PRIVATE, $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)
    self->Register, 'Macro Editor...', $
        'IDLitopMacroEditor', $
        ACCELERATOR='Ctrl+M', $
        ICON='gears', $
        IDENTIFIER='/Registry/MacroTools/Macro Editor', $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        /PRIVATE, $
        /SINGLETON, $
        TOOL=self ; we must set this here (CT)
end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterUIServices

    compile_opt hidden, idl2

    ;; UI Services
    self->RegisterUIService, "FileOpen", "IDLitUIFileOpen"
    self->RegisterUIService,'FileExport', 'IDLitUIFileExport'
    self->RegisterUIService,'FileSaveAs', 'IDLitUIFileSaveAs'
    self->RegisterUIService,'FileExit', 'IDLitUIFileExit'
    self->RegisterUIService, 'AsciiTemplate','IDLitUIAsciiTemplate'
    self->RegisterUIService, 'BinaryTemplate', 'IDLitUIBinaryTemplate'

    self->RegisterUIService, 'UnknownData', 'IDLituiUnknownData'
    self->RegisterUIService, 'GridWizard', 'IDLitUIGridWizard'
    self->RegisterUIService, 'DataImportWizard', 'IDLitUIImportWizard'
    self->RegisterUIService, 'DataExportWizard', 'IDLitwdExportWizard'

    self->RegisterUIService, 'CommandLineExport', 'IDLitUICLExport'

    self->RegisterUIService, '/DataManagerBrowser', 'IDLitUIDataManager'
    self->RegisterUIService, '/EditParameters', 'IDLitUIDataManager'
    self->RegisterUIService, '/InsertVisualization', 'IDLitUIDataManager'

    self->RegisterUIService, 'DataBottomTop', 'IDLitUIDataBottomTop'
    self->RegisterUIService, 'HourGlassCursor', 'IDLitUIHourGlass'

    self->RegisterUIService, "Directory", "IDLitUIDirectory"

    ;*** Register Edit services
    ;
    self->RegisterUIService, 'EditProperties', 'IDLituiBrowserVis'


    ;*** Register View Browser services
    ;
;    self->RegisterUIService, 'BrowserManip', 'IDLitUIBrowserManip'
    self->RegisterUIService, 'Browser', 'IDLitUIBrowser'
    self->RegisterUIService, '/Preferences', 'IDLitUIPrefs'
    self->RegisterUIService, 'BrowserVis', 'IDLitUIBrowserVis'
    self->RegisterUIService, '/StyleEditor', 'IDLituiStyleEditor'
    self->RegisterUIService, '/MacroEditor', 'IDLituiMacroEditor'
    self->RegisterUIService, 'RunMacro', 'IDLitUIRunMacro'
    self->RegisterUIService, 'ControlMacro', 'IDLitUIControlMacro'


    ;*** Register Operation services
    ;
    self->RegisterUIService, 'TextDisplay', 'IDLituiTextDisplay'


    ;*** Register User-defined PropertySheet services
    ;
    self->RegisterUIService, 'PropertySheet', 'IDLituiPropertySheet'
    self->RegisterUIService, 'ConvolKernel',  'IDLitUIConvolKernel'
    self->RegisterUIService, 'CurveFitting', 'IDLitUICurveFitting'
    self->RegisterUIService, 'RotateByAngle', 'IDLitUIRotateByAngle'
    self->RegisterUIService, 'ContourLevels', 'IDLitUIContourLevels'
    self->RegisterUIService, 'Isosurface', 'IDLitUIIsosurface'
    self->RegisterUIService, 'IntervalVolume', 'IDLitUIIntVol'
    self->RegisterUIService, 'PaletteEditor', 'IDLitUIPaletteEditor'
    self->RegisterUIService, 'SubVolume', 'IDLitUISubVolume'
    self->RegisterUIService, 'OperationPreview', 'IDLituiOperationPreview'
    self->RegisterUIService, 'MapGridlines', 'IDLituiMapGridlines'
    self->RegisterUIService, 'MapProjection', 'IDLituiMapProjection'
    self->RegisterUIService, 'MapRegisterImage', 'IDLituiMapRegisterImage'
    self->RegisterUIService, 'CropImage', 'IDLituiCropImage'

    ;*** Register Format services
    self->RegisterUIService, 'StyleApply', 'IDLitUIStyleApply'
    self->RegisterUIService, 'StyleCreate', 'IDLitUIStyleCreate'

    ;*** Register Window services
    ;
    self->RegisterUIService, 'WindowLayout', 'IDLitUIWindowLayout'

    ;*** Register (floating) Toolbar services
    ;
    self->RegisterUIService, 'FloatingToolbar', 'IDLituiFloatingToolbar'

    ;; printer setup
    self->RegisterUIService, 'PrinterSetup',  'IDLitUIPrinterSetup'

    self->RegisterUIService, 'PrintPreview',  'IDLitwdPrintPreview'

    ; Help
    self->RegisterUIService, 'Help', 'IDLitUIHelp'

end


;---------------------------------------------------------------------------
pro IDLitSystem::_AddServices

    compile_opt hidden, idl2

  ;; Create some system level services
  self._oSrvLangCat = OBJ_NEW("IDLitsrvLangCat", NAME="LANGCAT")
  self->AddService, self._oSrvLangCat
  self._oSrvLangCat->SetLanguage,'English'

  self->AddService, obj_new("IDLitsrvSystemClipCopy", $
                            NAME="SYSTEM_CLIPBOARD_COPY")

  self->AddService, obj_new("IDLitsrvPrinter", $
                            NAME="PRINTER")

  self->AddService, obj_new("IDLitsrvPDF", $
                            NAME="PDF")

  self->AddService, obj_new("IDLitsrvRasterBuffer", $
                            NAME="RASTER_BUFFER")


   ;; Add the scale service. This is used to undo-redo scale ops
   self->addService, obj_new("IDLitopScale", NAME="Scale")

   ;; The annotation service. This is used to undo-redo annotations
   self->AddService, obj_new("IDLitopAnnotation", $
                             NAME="Annotation")

   ;; Add the create visualization service. This service is used to
   ;; create new visualisations in the system.
   self->addService, $
        obj_new("IDLitsrvCreateVisualization", $
                NAME="Create Visualization", $
                IDENTIFIER='CREATE_VISUALIZATION')

   ;; Add the create dataspace service.
   self->AddService, $
        obj_new("IDLitsrvCreateDataSpace", $
            NAME="Create Dataspace", $
            IDENTIFIER="CREATE_DATASPACE")

   ;; Create the service that is called when data is unknown.
   self->AddService, obj_new("IDLitopUnknownData", $
                             NAME="UnknownData")

   ;; This Add must be done after creating the above objects.
   ;; Add a service that is used to set properties on a item.
   ;; This service allows these actions to be undoable.
   self->addService, $
        obj_new("IDLitopSetProperty", NAME="Set Property", $
                IDENTIFIER="SET_PROPERTY")

    ; Add a service to manager user-defined properties.
    self->AddService, OBJ_NEW("IDLitopEditUserdefProperty", $
        NAME="EditUserdefProperty", $
        IDENTIFIER="EDITUSERDEFPROPERTY")

   ;; Add a service to manage the IDL command line.
   self->AddService, $
     obj_new("IDLitsrvCommandLine",NAME="COMMAND_LINE")

   ;; Create the set data parameter service
   self->addService,  obj_new("IDLitsrvSetParameter", $
                              NAME="Set Parameter", $
                              IDENTIFIER='SET_PARAMETER')

   ;; Service that is called when we are made the current tool
   self->addService, obj_new("IDLitopSetAsCurrentTool", $
                                NAME="Set As Current Tool", $
                                IDENT="SET_AS_CURRENT_TOOL")

   ;; The tool shutdown service.
   self->addService, obj_new("IDLitopShutdown", $
                             NAME="Shutdown", $
                             IDENT="SHUTDOWN")

   ;; And the services that are called to read/write files.
   self->addService, obj_new("IDLitsrvReadFile", $
                             NAME="READ_FILE")

   self->AddService, OBJ_NEW("IDLitsrvWriteFile", $
                             NAME="WRITE_FILE")

   self->AddService, OBJ_NEW("IDLitsrvDatamanager", $
                             NAME="DATA_MANAGER")

    ;*** Services
    self->AddService, OBJ_NEW('IDLitopSetXYZRange', NAME='Set XYZ Range', $
        IDENTIFIER='SET_XYZRANGE')

    self->AddService, OBJ_NEW('IDLitopSetSubView', NAME='Set Sub View', $
        IDENTIFIER='SET_SUBVIEW')

    self->AddService, OBJ_NEW("IDLitsrvHelp", NAME="HELP")

    oSrvStyle = OBJ_NEW("IDLitsrvStyles", NAME="STYLES")
    self->AddService, oSrvStyle

    oSrvMacro = OBJ_NEW("IDLitsrvMacros", NAME="MACROS")
    self->AddService, oSrvMacro
    oSrvMacro->RestoreMacros

    self->AddService, OBJ_NEW('IDLitsrvGeoTIFF', NAME='GEOTIFF')

end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterReaderWriters

    compile_opt hidden, idl2

    self->RegisterFileReader, 'iTools State', 'IDLitReadISV'
    self->RegisterFileReader, 'Windows Bitmap', 'IDLitReadBmp'
    self->RegisterFileReader, 'Joint Photographic Experts Group', 'IDLitReadJPEG'
    self->RegisterFileReader, 'JPEG2000', 'IDLitReadJPEG2000'
    self->RegisterFileReader, 'Graphics Interchange Format', 'IDLitReadGif'
    self->RegisterFileReader, 'Macintosh PICT', 'IDLitReadPICT'
    self->RegisterFileReader, 'Portable Network Graphics', 'IDLitReadPNG'
    self->RegisterFileReader, 'Tag Image File Format', 'IDLitReadTIFF'

    allowDICOM = 1b
    ;; Do not allow DICOM on certain machines
    if (!version.MEMORY_BITS eq 64) then begin
      ;; Only on Mac 64 if licensed
      if (!version.OS eq 'darwin') then begin
        if (~LMGR('idl_dicomex_rw')) then allowDICOM = 0b
      endif
      ;; Only on Windows 64 if licensed
      if (!version.OS eq 'Win32') then begin
        if (~LMGR('idl_dicomex_rw')) then allowDICOM = 0b
      endif
    endif
    ;; Not on Solaris x86
    if ((!version.OS_NAME eq 'Solaris') && $
        (!version.ARCH ne 'sparc')) then allowDICOM = 0b
    if (allowDICOM) then $
      self->RegisterFileReader, 'DICOM Image', 'IDLitReadDICOM'

    self->RegisterFileReader, 'Windows Waveform Audio Stream', 'IDLitReadWav'
    self->RegisterFileReader, 'ESRI Shapefile', 'IDLitReadShapefile'
    ;; Keep ascii and binary last or the ISA tests will fail.
    self->RegisterFileReader, 'ASCII text', 'IDLitReadASCII'
    self->RegisterFileReader, 'Binary data', 'IDLitReadBinary

    self->RegisterFileWriter, 'iTools State', 'IDLitWriteISV', $
        ICON='save'
    self->RegisterFileWriter, 'Windows Bitmap', 'IDLitWriteBMP', $
        ICON='demo'
    self->RegisterFileWriter, 'Encapsulated Postscript', 'IDLitWriteEPS', $
        ICON='demo'
    self->RegisterFileWriter, 'Portable Document Format', 'IDLitWritePDF', $
        ICON='demo'
    if !VERSION.os_family eq 'Windows' then $
      self->RegisterFileWriter, 'Windows Enhanced Metafile', 'IDLitWriteEMF', $
        ICON='demo'
    self->RegisterFileWriter, 'Joint Photographic Experts Group', 'IDLitWriteJPEG', $
        ICON='demo'
    self->RegisterFileWriter, 'JPEG2000', 'IDLitWriteJPEG2000', $
        ICON='demo'
    self->RegisterFileWriter, 'Graphics Interchange Format', 'IDLitWriteGif', $
        ICON='demo'
    self->RegisterFileWriter, 'Macintosh PICT', 'IDLitWritePICT', $
        ICON='demo'
    self->RegisterFileWriter, 'Portable Network Graphics', 'IDLitWritePNG', $
        ICON='demo'
    self->RegisterFileWriter, 'Tag Image File Format', 'IDLitWriteTIFF', $
        ICON='demo'
    self->RegisterFileWriter, 'ASCII text', 'IDLitWriteASCII', $
        ICON='ascii'
    self->RegisterFileWriter, 'Binary data', 'IDLitWriteBinary',$
      ICON='binary'

end


;----------------------------------------------------------------------------
; IDLitSystem::_RegisterPreferences
;
; Purpose:
;    This routine contains all the preferences for the system.
;
; Parameters:
;    None.
;
pro IDLitSystem::_RegisterPreferences

    compile_opt hidden, idl2

    ; Add our general settings
    oGeneral= OBJ_NEW('IDLitGeneralSettings', TOOL=self, $
        IDENTIFIER="GENERAL_SETTINGS")
    self->AddSetting, oGeneral, POSITION=0

    self->_RegisterReaderWriters

end


;;---------------------------------------------------------------------------
;; IDLitSystem::Cleanup
;;
;; Purpose:
;;   Lifecycle routine of the tool. For this most part (besides IDL
;;   shutdown or reset, this will never be called in a production
;;   environment.
;;
PRO IDLitSystem::Cleanup

   compile_opt hidden, idl2

   OBJ_DESTROY, self._oUIConnection
   OBJ_DESTROY, self._oLastError
   OBJ_DESTROY, self._oProgress

   self->IDLitContainer::Cleanup
end

;;---------------------------------------------------------------------------
;; Callback routines access to support IMessaging
;;
;;---------------------------------------------------------------------------
;; IDLitSystem::SendMessageToUI
;;
;; Purpose:
;;   Send a synchronous message to the UI.

function IDLitSystem::SendMessageToUI, oMessage

   compile_opt idl2, hidden

   return, self._oUIConnection->HandleMessage(oMessage)
end


;---------------------------------------------------------------------------
; Purpose:
;   Used to cause the system to display and update a progress bar.
;   Called from the IDLitiMessaging method.
;
; Parameters:
;   strMsg: The message to be displayed in the progress bar.
;
; Keywords:
;   PERCENT: The amount of progress to show in the bar.
;
;   SHUTDOWN: If set, the progress bar is shutdown (or destroyed)
;       if it is present.
;
;   TOOL: Undocumented keyword. Indicates we were called from a tool
;       rather than ourself.
;
function IDLitSystem::ProgressBar, strMsg, $
    PERCENT=percentIn, $
    SHUTDOWN=shutdown, $
    TOOL=oTool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

@idlit_catch
    if (iErr ne 0) then begin
        catch, /cancel
        return, 0
    end

    shutdown = KEYWORD_SET(shutdown) || self._disableProgress

    if (~OBJ_VALID(self._oProgress)) then $
        self._oProgress = OBJ_NEW('IDLitMsgProgress')

    ; Sanity check, to see if we are already done.
    if (shutdown && self._oProgress->IsDone()) then $
        return, 1

    self._oProgress->GetProperty, PERCENT=oldpercent
    percent = oldpercent
    if (N_ELEMENTS(percentIn) eq 1) then $
        percent = FIX(0 > percentIn < 100)

    ; To avoid too many UI messages, only update when
    ; the percent actually changes.
    if (percent gt 0 && percent lt 100 && $
        percent eq oldpercent && ~shutdown) then $
        return, 1

    ; fill in a prompt object and send it to the UI
    self._oProgress->SetProperty, MESSAGE=strMsg, $
        PERCENT=percent, $
        _EXTRA=_extra

    if (shutdown) then $
      self._oProgress->Shutdown

    if (~OBJ_VALID(oTool)) then $
        oTool = self

    iStatus = oTool->SendMessageToUI(self._oProgress)

    if (shutdown) then $
        self._oProgress->Reset

    return, iStatus

end


;;---------------------------------------------------------------------------
;; IDLitSystem::DoOnNotify
;;
;; Purpose:
;;   This routine will take the message and then dispatch it to
;;   all tools that are current
;;
;; Parameters:
;;    strID      - ID of the tool item that had its state change.
;;
;;    message    - The type of message sent.
;;
;;    messparam  - A parameter that is assocaited with the message.

pro IDLitSystem::DoOnNotify, strID, messageIn, userdata, $
    NO_TOOLS=noTools

    compile_opt idl2, hidden

    if (~KEYWORD_SET(noTools)) then begin
        oToolsCon = self->GetByIdentifier("TOOLS")
        if (OBJ_VALID(oToolsCon)) then begin
            oTools = oToolsCon->Get(/ALL, COUNT=nTools)
            for i=0, nTools-1 do $
                oTools[i]->DoOnNotify, strID, messageIn, userdata, /NO_SYSTEM
        endif
    endif

    if (OBJ_VALID(self._oUIConnection)) then $
        self._oUIConnection->HandleOnNotify, strID, messageIn, userdata

end


;;---------------------------------------------------------------------------
;; IDLitSystem::AddOnNotifyObserver
;;
;; Purpose:
;;   Used to register as being interested in receiving notifications
;;   from a specific identifier.
;;
;; Parameters:
;;    strObID       - Identifier of the observer object
;;
;;    strID         - The identifier of the object that it is
;;                    interested in.
;;
pro IDLitSystem::AddOnNotifyObserver, strObID, strID

   compile_opt idl2, hidden

   ;; Add this observer to all tools
   oToolsCon = self->GetByIdentifier("TOOLS")
   if(not obj_valid(oToolsCon))then return

   oTools = oToolsCon->Get(/all, count= nTools)
    for i=0, nTools-1 do $
      oTools[i]->AddOnNotifyObserver, strObID, strID


end
;;---------------------------------------------------------------------------
;; IDLitSystem::RemoveOnNotifyObserver
;;
;; Purpose:
;;   Remove an entry from the OnNotify dispatch table.
;;
;; Parameters:
;;    strObID       - Id of the observer
;;
;;    strID         - The identifier of the object that it is
;;                    interested in.
;;
pro IDLitSystem::RemoveOnNotifyObserver, strObID, strID

   compile_opt idl2, hidden

   ;; Remove this observer to all tools
   oToolsCon = self->GetByIdentifier("TOOLS")
   if(not obj_valid(oToolsCon))then return

   oTools = oToolsCon->Get(/all, count= nTools)
   for i=0, nTools-1 do $
     oTools[i]->RemoveOnNotifyObserver, strObID, strID
end

;;---------------------------------------------------------------------------
;; Registration Section
;;
;; This section contains the routines that are used to register
;; available tools and available user interfaces for the tool
;; system. This allows an "name" to be associated with a particular
;; tool interface, which decouples the class name from the object or
;; tool implementation.
;;
;; This decoupling allows default tools to be easily replaced by
;; registring a new tool over the default value.
;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterTool
;;
;; Purpose:
;;   This method is used to register a tool "class" with
;;   the system.
;;
;;
;; Parameters:
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strClassName  - The classname of the object
;;
;; Keywords
;;
pro IDLitSystem::RegisterTool, strName, strClassName, $
                               _EXTRA=_extra


  compile_opt idl2, hidden

  if(strName eq '' or strClassName eq '')then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:RegisterTool:Text')], $
            title=IDLitLangCatQuery('Error:RegisterTool:Title'), severity=2
        return
  endif

  ;; Register
  self->register, strName, strClassName, $
                  OBJ_DESCRIPTOR='IDLitObjDescTool', $
                  TOOL=self, $ ; we must set this here (CT)
                  identifier="/REGISTRY/TOOLS/"+strName, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterToolOperation
;;
;; Purpose:
;;   Used to register an operation for use by a tool. When registered,
;;   a tool type is provided that is used to add functionality to a
;;   tool.
;;
;; Parameters:
;;   strTYPE    - The type to associated this with
;;
;;   strName    - The name of the operation.
;;
;;   strClass   - Operation Class
;;
;; Keywords:
;;   PROXY      - Set this keyword to the identifier (full or relative)
;;     to the operation that this item being registered should proxy.
;;     When proxied, all calls made on the object are vectored off to
;;     the target object identified by this keyword.
;;
;;   Everything else is passed to the underlying registration service
;;
pro IDLitSystem::RegisterToolOperation, strType, strName, strClass,  $
    IDENTIFIER=identifier, $
    PRIVATE=private, $
    PROXY=proxy, $
    _REF_EXTRA=_extra


  compile_opt idl2, hidden

  if (strName eq '') then begin
      self->ErrorMessage, $
          [IDLitLangCatQuery('Error:RegisterToolOp:Text')], $
          TITLE=IDLitLangCatQuery('Error:RegisterToolOp:Title'), SEVERITY=2
      return
  end

  if (N_ELEMENTS(identifier) eq 0) then $
      identifier = strName

  if (KEYWORD_SET(proxy)) then begin
      ; Avoid self-referential proxy.
      if (STRCMP(identifier, proxy, /FOLD) eq 1) then begin
          MESSAGE, IDLitLangCatQuery('Message:Framework:SelfRefProxy'), /CONTINUE
          return
      endif
      oComp = OBJ_NEW("IDLitRegProxy", strName, self, proxy, $
          NAME=strName, FINAL_IDENTIFIER=identifier, $
          _EXTRA=_extra)
  endif else begin
      if (strClass eq '') then begin
          self->ErrorMessage, $
              [IDLitLangCatQuery('Error:RegisterToolOp:Text2')], $
              TITLE=IDLitLangCatQuery('Error:RegisterToolOp:Title'), SEVERITY=2
          return
      endif

      oComp = OBJ_NEW("IDLitRegClass", strName, strClass, $
          FINAL_IDENTIFIER=identifier, $
          PRIVATE=private, $
          _EXTRA=_extra)
  endelse

  self->registerComponent, oComp, $
             identifier="/REGISTRY/OPERATIONS/"+strTYPE

end
;;---------------------------------------------------------------------------
function IDLitSystem::_GetToolOperationsByType, strType, count=count
   compile_opt hidden, idl2

   oFolder = self->GetByIdentifier("/REGISTRY/OPERATIONS/"+strType)
   count=0
   if(~obj_valid(oFolder))then return, obj_new()

   return, oFolder->Get(/all, count=count)
end
;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterToolManipulator
;;
;; Purpose:
;;   Used to register a manipulator for use by a tool. When registered,
;;   a tool type is provided that is used to add functionality to a
;;   tool.
;;
;; Parameters:
;;   strTYPE    - The type to associated this with
;;
;;   strName    - The name of the operation.
;;
;;   strClass   - Operation Class
;;
;; Keywords:
;;   Everything else is passed to the underlying registration service
;;
pro IDLitSystem::RegisterToolManipulator, strType, strName, $
               strClass,  identifier=identifier, _EXTRA=_extra


  compile_opt idl2, hidden

  if(strName eq '' or strClass eq '')then begin
      self->ErrorMessage, $
        [IDLitLangCatQuery('Error:RegisterToolManip:Text1')], $
        title=IDLitLangCatQuery('Error:REgisterToolManip:Title'), severity=2
      return
  end
  oComp=obj_new("IDLitRegClass", strName, strClass, $
                final_identifier=identifier, _extra=_extra)
  self->registerComponent, oComp, $
             identifier="/REGISTRY/MANIPULATORS/"+strTYPE

end
;;---------------------------------------------------------------------------
function IDLitSystem::_GetToolManipulatorsByType, strType, count=count
   compile_opt hidden, idl2

   oFolder = self->GetByIdentifier("/REGISTRY/MANIPULATORS/"+strType)

   count=0
   if(~obj_valid(oFolder))then return, obj_new()

   return, oFolder->Get(/all, count=count)
end


;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterUserInterface
;;
;; Purpose:
;;   This method is used to register a tool "UI" with
;;   the system.
;;
;;
;; Parameters:
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strRoutine    - Routine called to create the widget UI
;;
;; Keywords:
;;   Everything is passed to the underlying registration service
;;
pro IDLitSystem::RegisterUserInterface, strName, strRoutine, $
               _EXTRA=_extra


  compile_opt idl2, hidden

  if(strName eq '' or strRoutine eq '')then begin
      self->ErrorMessage, $
        [IDLitLangCatQuery('Error:RegisterUI:Text')], $
        title=IDLitLangCatQuery('Error:RegisterUI:Title'), severity=2
      return
  end
  oComp=obj_new("IDLitRegRoutine", strName, strRoutine, _extra=_extra)
  self->registerComponent, oComp, $
             identifier="/REGISTRY/WIDGETS/INTERFACE/"

end
;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterUIPanel
;;
;; Purpose:
;;   Used to register a UI panel with the system. This is used with
;;   the user interface system to allow users to register their own
;;   panels.
;;
;; Parameters:
;;   strName    - The name of the panel
;;
;;   strRoutine - The panel routine to be called.
;;
;; Keywords:
;;   TYPES    - The type of tools that this panel should be used
;;              with. This is set to the type of tools that this panel
;;              should be associated with.
;;
;;   Everything else is passed to the underlying registration service
;;
pro IDLitSystem::RegisterUIPanel, strName, strRoutine, $
               _EXTRA=_extra


  compile_opt idl2, hidden

  if(strName eq '' or strRoutine eq '')then begin
      self->ErrorMessage, $
        [IDLitLangCatQuery('Error:RegisterUIPanel:Text')], $
        title=IDLitLangCatQuery('Error:RegisterUIPanel:Title'), severity=2
      return
  end
  oComp=obj_new("IDLitRegRoutine", strName, strRoutine, _extra=_extra)
  self->registerComponent, oComp, $
             identifier="/REGISTRY/WIDGETS/PANELS/"

end
;;---------------------------------------------------------------------------
;; IDLitSystem::RegisterUIService
;;
;; Purpose:
;;   Used to register a UI service with the system. This is used with
;;   the user interface system to allow users to register their own
;;   services
;;
;; Parameters:
;;   strName    - The name of the service
;;
;;   strRoutine - The panel routine to be called.
;;
;; Keywords:
;;   Everything else is passed to the underlying registration service
;;
pro IDLitSystem::RegisterUIService, strName, strRoutine, $
               _EXTRA=_extra


  compile_opt idl2, hidden

  if(strName eq '' or strRoutine eq '')then begin
      self->ErrorMessage, $
        [IDLitLangCatQuery('Error:RegisterUIService:Text')], $
        title=IDLitLangCatQuery('Error:RegisterUIService:Title'), severity=2
      return
  end
  oComp=obj_new("IDLitRegRoutine", strName, strRoutine, _extra=_extra)
  self->registerComponent, oComp, $
             identifier="/REGISTRY/WIDGETS/SERVICES/"

  if(obj_valid(self._oUIConnection))then begin
      if(strmid(strName, 0,1) eq '/')then $
        void = self._oUIConnection->RegisterUIService(strmid(strName,1), strRoutine)
  endif
end


;---------------------------------------------------------------------------
; RegisterVisualization
;
; Purpose:
;   Register a visualization class with the system object. The
;   classes registered are used to create visualizations in this
;   tool.
;
;   This is primarily done at the tool level, but the system
;   provides visualization for two primary reason:
;      - Support "overplotting" at the command line.
;      - Global scope of visualizations.
;
; Parameters:
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
pro IDLitSystem::RegisterVisualization, strName, strClassName, $
             _EXTRA=_extra

    compile_opt idl2, hidden

    self->Register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        IDENTIFIER="/REGISTRY/Visualizations/"+strName, $
        TOOL=self, $ ; we must set this here (CT)
        _EXTRA=_extra

end


;---------------------------------------------------------------------------
; UnRegisterVisualization
;
; Purpose:
;   Remove a visulization that was registered with the system
;
; Parameters:
;     strClass     - The name of the class that was registerd.
;
pro IDLitSystem::UnRegisterVisualization, strClass

    compile_opt idl2, hidden

    self->UnRegister, "/REGISTRY/Visualizations/"+strClass

end


;---------------------------------------------------------------------------
; RegisterAnnotation
;
; Purpose:
;   Register an annotation class with the tool object. The
;   classes registered are used to create annotations in this
;   tool.
;
; Parameters:
;   strName       - The name for this object. This is "HUMAN"
;
;   strClassName  - The classname of the object
;
; Keywords:
;   PROXY   - Set this keyword to the identifier (full or relative)
;             to the annotation that this item being registered
;             should proxy. When proxied, all calls made on the
;             object are vectored off to the target object which is
;             referenced by the provided identifier.
;
;   IDENTIFIER  - The realitive location of where to place the
;                 annotation discriptor. These are placed in the
;                 tools annotations folder.
;
;   All other keywords are passed to the underlying registration
;   function.
;
pro IDLitSystem::RegisterAnnotation, strName, strClassName, $
             PROXY=PROXY, IDENTIFIER=IDENTIFIER, $
             _EXTRA=_extra

    compile_opt idl2, hidden

    self->Register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescVis', $
        IDENTIFIER="/Registry/Annotations/"+strName, $
        TOOL=self, $ ; we must set this here (CT)
        _EXTRA=_extra
end


;---------------------------------------------------------------------------
; UnRegisterAnnotation
;
; Purpose:
;   Remove an annotation that was registered with the tool
;
; Parameters:
;     strItem     - The name of the item that was registerd. This is
;                   the identiifer used during the registration process.
;
;   Added, CT, Jan 2003.
;
pro IDLitSystem::UnRegisterAnnotation, strItem

    compile_opt idl2, hidden

    self->UnRegister,"/registry/Annotations/"+strItem

end


;---------------------------------------------------------------------------
; IDLitSystem::GetVisualizations
;
; Purpose:
;  Called to retrieve the object descriptors for all the
;  visualization objects registered with the system.
;
; Parameters:
;  None.
;
; Keywords:
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitSystem::GetVisualization, ID, ALL=ALL, COUNT=COUNT

    compile_opt idl2, hidden

    count=0
    ; User requested a specific item?
    if(keyword_set(all))then begin
       oVisDesc = self->IDLitContainer::GetbyIdentifier($
                          "/REGISTRY/Visualizations")
       oVis = OBJ_VALID(oVisDesc) ? $
         oVisDesc->IDL_Container::Get(/ALL, COUNT=COUNT, $
            ISA='IDLitObjDescVis') : OBJ_NEW()
   endif else  begin
       oVis = self->IDLitContainer::GetbyIdentifier( $
                "/Registry/Visualizations/"+id)
       count=obj_valid(oVis)
   endelse
   return, oVis
end


;---------------------------------------------------------------------------
; IDLitSystem::GetAnnotation
;
; Purpose:
;  Called to retrieve the object descriptors for all the
;  annotation objects registered with the system.
;
; Parameters:
;   Annotation - the identifier (local) of the annotation to retrieve
;
; Keywords:
;  COUNT  - The number of elements returned.
;
FUNCTION IDLitSystem::GetAnnotation, annotation, COUNT=COUNT, All=All

   compile_opt idl2, hidden

    count = 0
   ;; User requested a specific item?
   if(keyword_set(all))then begin
       oVis = self->IDLitContainer::GetbyIdentifier($
                          "/Registry/Annotations")
       oAnn = OBJ_VALID(oVis) ? $
            oVis->IDL_Container::Get(/ALL, COUNT=COUNT) : OBJ_NEW()
   endif else if(keyword_set(Annotation))then begin
       oAnn = self->IDLitContainer::GetbyIdentifier( $
                "/Registry/Annotations/"+annotation)
       count=obj_valid(oAnn)
   endif else begin
       count=0
       oAnn=obj_new()
   endelse
   return, oAnn
end


;---------------------------------------------------------------------------
pro IDLitSystem::_RegisterReaderWriter, strName, strClassName, folder, $
             IDENTIFIER=IDENTIFIER, PROXY=PROXY, $
             _EXTRA=_extra

    compile_opt idl2, hidden

    if (~keyword_set(IDENTIFIER)) then $
        IDENTIFIER = strName

    fullID = '/Registry/Settings/' + folder + '/' + IDENTIFIER

    ; Has this already be registered or restored? Just skip
    if (OBJ_VALID(self->GetByIdentifier(fullID))) then $
        return

    self->Register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        PROXY=PROXY, $
        /SINGLETON, $
        IDENTIFIER=fullID, $
        TOOL=self, $ ; we must set this here (CT)
        _extra=_extra

    ; Proxy all file reader/writers from the System. That way the
    ; programmer can Unregister them in their Tool subclass ::Init
    ; method. Use a proxy so the file reader/writer properties are
    ; shared between all active iTools.
    oToolsCon = self->GetByIdentifier("/TOOLS")
    if (~OBJ_VALID(oToolsCon)) then $
        return

    oTools = oToolsCon->Get(/ALL, COUNT=nTools)
    if (~nTools) then $
        return

    oSysDesc = self->GetByIdentifier(fullID)
    oSysDesc->GetProperty, NAME=name

    for i=0, nTools-1 do begin
        if (folder eq 'File Readers') then begin
            if (OBJ_VALID(oTools[i]->GetFileReader(name))) then $
                continue
            oTools[i]->RegisterFileReader, name, PROXY=fullID, $
                _EXTRA=_extra
        endif else begin
            if (OBJ_VALID(oTools[i]->GetFileWriter(name))) then $
                continue
            oTools[i]->RegisterFileWriter, name, PROXY=fullID, $
                _EXTRA=_extra
        endelse
    endfor

end


;;---------------------------------------------------------------------------
;; RegisterFileReader
;;
;; Purpose:
;;   Register a File class with the tool object. The
;;   classes registered are used to read file contents in this
;;   tool.
;;
;; Parameter
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strClassName  - The classname of the object
;;
;; Keywords:
;;   PROXY   - Set this keyword to the identifier (full or relative)
;;             to the reader that this item being registered
;;             should proxy. When proxied, all calls made on the
;;             object are vectored off to the target object which is
;;             referenced by the provided identifier.
;;
;;   IDENTIFIER  - The realitive location of where to place the
;;                 reader discriptor. These are placed in the
;;                 tools annotations folder.
;;
;;   All other keywords are passed to the underlying registration
;;   function.

pro IDLitSystem::RegisterFileReader, strName, strClassName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->_RegisterReaderWriter, strName, strClassName, 'File Readers', $
        _EXTRA=_extra

end


;;---------------------------------------------------------------------------
;; UnRegisterFileReader
;;
;; Purpose:
;;   Remove a file reader that was registered with the tool
;;
;; Parameters:
;;     strItem     - The name of the item that was registered. This is
;;                   the identiifer used during the registration process.

pro IDLitSystem::UnRegisterFileReader, strItem

   compile_opt idl2, hidden

   if(n_elements(strItem) eq 0 || size(strItem,/type) ne 7)then $
     return
   self->UnRegister,"/Registry/Settings/File Readers/"+strItem

end
;;---------------------------------------------------------------------------
;; RegisterFileWriter
;;
;; Purpose:
;;   Register a File class with the tool object. The
;;   classes registered are used to read file contents in this
;;   tool.
;;
;; Parameter
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strClassName  - The classname of the object
;;
;; Keywords:
;;   PROXY   - Set this keyword to the identifier (full or relative)
;;             to the writer that this item being registered
;;             should proxy. When proxied, all calls made on the
;;             object are vectored off to the target object which is
;;             referenced by the provided identifier.
;;
;;   IDENTIFIER  - The realitive location of where to place the
;;                 writer discriptor. These are placed in the
;;                 tools annotations folder.
;;
;;   All other keywords are passed to the underlying registration
;;   function.

pro IDLitSystem::RegisterFileWriter, strName, strClassName, $
             IDENTIFIER=IDENTIFIER, PROXY=PROXY, $
             _EXTRA=_extra


    compile_opt idl2, hidden

    self->_RegisterReaderWriter, strName, strClassName, 'File Writers', $
        _EXTRA=_extra

end


;;---------------------------------------------------------------------------
;; UnRegisterFileWriter
;;
;; Purpose:
;;   Remove a file Writer that was registered with the tool
;;
;; Parameters:
;;     strItem     - The name of the item that was registered. This is
;;                   the identiifer used during the registration process.

pro IDLitSystem::UnRegisterFileWriter, strItem

   compile_opt idl2, hidden

   if(n_elements(strItem) eq 0 || size(strItem,/type) ne 7)then $
     return
   self->UnRegister, "/Registry/Settings/File Writers/"+strItem

end
;;---------------------------------------------------------------------------
;; IDLitSystem::GetFileReader
;;
;; Purpose:
;;   Used to gain external access to the File Reader object
;;   descriptors contained in the system.
;;
;; Parameters:
;;   id   - ID of the particular reader being requested
;;
;; Keywords:
;;  ALL    - Return All
;;  COUNT  - The number of elements returned
FUNCTION IDLitSystem::GetFileReader, ID, COUNT=COUNT, ALL=ALL

   compile_opt idl2, hidden

   if(~keyword_set(ALL))then begin
       oReader = self->IDLitContainer::GetbyIdentifier($
                        "/Registry/Settings/File Readers/"+id)
       count = obj_valid(oReader)
       return, oReader
   endif
   ;; Okay, return, all
   oFR = self->IDLitContainer::GetbyIdentifier($
                        "/Registry/Settings/File Readers")

   count = 0
   if ~obj_valid(oFR) then $
    return, OBJ_NEW()

   return, oFR->IDL_Container::Get(/ALL, COUNT=COUNT)

end

;;---------------------------------------------------------------------------
;; IDLitSystem::GetFileWriter
;;
;; Purpose:
;;   Used to gain external access to the File writer object
;;   descriptors contained in the system.
;;
;; Parameters:
;;  ID  - The id of the target item
;;
;; Keywords:
;;  ALL    - If set, return all items.
;;
;;  COUNT  - The number of elements returned.
;;
FUNCTION IDLitSystem::GetFileWriter,ID, ALL=ALL, COUNT=COUNT

   compile_opt idl2, hidden

   if(~keyword_set(ALL))then begin
       oWriter = self->IDLitContainer::GetbyIdentifier($
                        "/Registry/Settings/File Writers/"+id)
       count = obj_valid(oWriter)
       return, oWriter
   endif

   oFW = self->IDLitContainer::GetbyIdentifier($
                            "/Registry/Settings/File Writers")

   return, (obj_valid(oFW) ? $
            oFW->IDL_Container::Get(/ALL, COUNT=COUNT) : obj_new())
end
;;---------------------------------------------------------------------------
;; RegisterOperation
;;
;; Purpose:
;;   Register a Operation class with the tool object.
;;
;; Parameters
;;   strName       - The name for this object. This is "HUMAN"
;;
;;   strClassName  - The classname of the object
;;
;;   DESCRIPTION   - The description of the object.

pro IDLitSystem::RegisterOperation, strName, strClassName, $
             IDENTIFIER=IDENTIFIER,  _EXTRA=_extra


  compile_opt idl2, hidden

  if(not keyword_set(IDENTIFIER))then IDENTIFIER=strName

  self->register, strName, strClassName, $
        OBJ_DESCRIPTOR='IDLitObjDescTool', $
        IDENTIFIER="/REGISTRY/Operations/"+IDENTIFIER, $
        TOOL=self, $ ; we must set this here (CT)
        /SINGLETON, _extra=_extra
end
;;---------------------------------------------------------------------------
;; IDLitSystem::AddService
;;
;; Purpose:
;;   Used to add a service to the system. An active object is expecte
;;   to be passed into this routine.
;;
;; Parameters:
;;   oService    - The service being added.
;;
;; Keywords:
;;   None.
;;
PRO IDLitSystem::AddService, oService
   compile_opt hidden, idl2

   if(not obj_valid(oService))then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:AddService:Text'), $
         title=IDLitLangCatQuery('Error:AddService:Title'), severity=2
       return
   endif

   oService->GetProperty, identifier=id

   ;; Check if this service already exist
   if(keyword_set(id))then begin
       oCheck = self->GetService(id)
       if(obj_valid(oCheck))then begin
           ; Just send out an informational message.
           self->SignalError, IDLitLangCatQuery('Error:ServiceReg:Text1')+id  $
              + IDLitLangCatQuery('Error:ServiceReg:Text2')
          oCheck =self->RemoveByIdentifier("SERVICES/"+id)
          obj_destroy, oCheck
       endif
   endif
   oService->_setTool, self
   self->AddByIdentifier, "/SERVICES", oService

end

;;---------------------------------------------------------------------------
;; IDLitSystem::GetService
;;
;; Purpose:
;;   Provides a direct method to get a service.
;;
;; Parameters:
;;  idService   - The desired service ident/name
;;
;; Return Value:
;;   The desired service or null object if it cannot be found.

function IDLitSystem::GetService, idService
   compile_opt hidden, idl2

   oService= self->GetByIdentifier("/SERVICES/"+idService)
   if(obj_valid(oService))then $
     oService->_SetTool, self

   return, oService
end

;;---------------------------------------------------------------------------
;; IDLitSystem::AddSetting
;;
;; Purpose:
;;   Used to add a setting or prefs object to the system. An active object is expected
;;   to be passed into this routine. If this setting already exists,
;;   the provided object is deleted.
;;
;; Parameters:
;;   oSetting    - The oSetting being added.
;;
;; Keywords:
;;   None.
;;
PRO IDLitSystem::AddSetting, oSetting, _REF_EXTRA=_extra
   compile_opt hidden, idl2

   if(not obj_valid(oSetting))then begin
       self->ErrorMessage, IDLitLangCatQuery('Error:AddSetting:Text'), $
         title=IDLitLangCatQuery('Error:AddSetting:Title'), severity=2
       return
   endif

   oSetting->GetProperty, identifier=id

   ;; Check if this service already exist
   if(keyword_set(id))then begin
       oCheck = self->GetSetting(id)
       if(obj_valid(oCheck))then begin
           obj_destroy, oSetting
           return
       endif
   endif
   oSetting->_setTool, self
   self->AddByIdentifier, "/REGISTRY/SETTINGS", oSetting, _EXTRA=_extra

end

;;---------------------------------------------------------------------------
;; IDLitSystem::GetSetting
;;
;; Purpose:
;;   Provides a direct method to get a setting/prefs object
;;
;; Parameters:
;;  idSetting   - The desired service ident/name
;;
;; Return Value:
;;   The desired setting object or null object if it cannot be found.

function IDLitSystem::GetSetting, idSetting
   compile_opt hidden, idl2

   return, self->GetByIdentifier("/REGISTRY/SETTINGS/"+idSetting)
end


;;---------------------------------------------------------------------------
;; IDLitSystem::_GetUIPanelRoutines
;;
;; Purpose:
;;  Internal routine to retrive any UI panel routines registered with
;;  the system.
;;
;; Parameters:
;;   toolTypes[in]    - The types to look for
;;
;; Keywords:
;;    COUNT - the number of items returned.
;;
;; Return Value:
;;   Array of panel routine names or ''
;;
function IDLitSystem::_GetUIPanelRoutines, toolTypes, count=count
   compile_opt hidden, idl2

   ;; Will there need to be any special panels?
   oCon = self->GetByIdentifier("/registry/widgets/panels")
   if(not obj_valid(oCon))then begin
       count=0
       return, ''
   endif
   oPanels = oCon->Get(/all, count=nPanels)
   nTooltypes = n_elements(toolTypes)
   for i=0, nPanels-1 do begin
       oPanels[i]->Getproperty, types=types, routine=PanelRoutine
       ;; wildcard on the panel list
       dex = where(types eq '', nMatch)
       if(nMatch eq  0)then begin
           ;; Check with tools
           for j=0, nToolTypes-1 do begin
               dex = where(strcmp(toolTypes[j], types, /fold_case), nMatch)
               if(nMatch gt 0)then break
           endfor
       endif
       if(nMatch gt 0)then $
         panels = (n_elements(panels) gt 0 ? [panels, PanelRoutine]: PanelRoutine)
   endfor
   count = n_elements(panels)
   return, (count gt 0 ? panels : '')
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_InitializeUserInterface
;;
;; Purpose:
;;   This internal routine is called with a tool and the user
;;   interface for that tool is created and initialized.
;;
;; Parameters:
;;    oTool    - The tool to associate a UI with
;;
;;    oUIDesc  - The descriptor of the User interface to use.
;;
;; Keywords:
;;    LOCATION - The location to place the user interface.
;;
;;    _EXTRA   - Anything else is passed to the user interface
;;               creation routine.
;;
;; Return Value:
;;    0 - Error
;;    1 - Okay

function IDLitSystem::_InitializeUserInterface, oTool, oUIDesc, $
    location=location, $
    _EXTRA=_EXTRA

   compile_opt hidden, idl2

   ;; What types does this tool support
   oTool->GetProperty, types=ToolTypes

   ;; Okay, now it's time to build the UI for this tool.
   ;; Get the location for the tool
   if(not keyword_set(location))then $
     location = self->_GetNextToolLocation()
   ;; Get our UI routine
   oUIDesc->GetProperty, routine=routine
   ;; Build the ui.
   call_procedure, routine, oTool, _EXTRA=_EXTRA, $
                   LOCATION=LOCATION, $
                   USER_INTERFACE=oUI

   ;; If we have a valid UI object, check if any system UI services
   ;; need to be registered.
   oCon = self->GetByIdentifier("/registry/widgets/services")
   if(obj_valid(oCon) && obj_valid(oUI))then begin
       oServices = oCon->Get(/all, count=nServices)
       for i=0, nServices-1 do begin
           oServices[i]->GetProperty, name=name, routine=UIRoutine
           if(strmid(name, 0,1) ne '/')then $ ;; filter out syste UI services
             void = oUI->RegisterUIService(name, UIRoutine)

       endfor
   endif
   return,1
end
;;---------------------------------------------------------------------------
;; IDLitSystem::CreateTool
;;
;; Purpose:
;;  This method is called to create a new tool in the IDL
;;  system. During the creation process, the tool object is created
;;  and registered with the system, associated with a user interface
;;  and associated the system with the tool.
;;
;;  When a tool is creted, it is set to be the current tool.
;;
;; Parameters
;;    strToolName     - The name of the desired tool.
;;
;; Keywords:
;
;   DISABLE_UPDATES: Set this keyword to disable updates on the
;       newly-created tool. If this keyword is set then the user
;       is responsible for calling EnableUpdates on the tool.
;       This keyword is useful when you want to do a subsequent overplot
;       or use DoAction to call an operation, but do not want to see the
;       intermediate steps.
;
;;   USER_INTERFACE: The user interface for this tool.
;;      If nothing is provided, the default interface is used.
;;
;;   INITIAL_DATA     - Any initial data that is assocated with this
;;                      tool.
;;
;;   GROUP_LEADER     - This routine eats this if passed in.
;;
function IDLitSystem::CreateTool, strToolName, $
    USER_INTERFACE=userInterface, $
    WINDOW_TITLE=winTitle, $
    INITIAL_DATA = INITIAL_DATA, $
    DISABLE_UPDATES=disableUpdates, $
    UPDATE=update, $
    VIEW_GRID=viewGrid, $
    NAME=visName, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

@idlit_catch.pro
   if(iErr ne 0)then begin
       catch, /cancel
       if (strToolName eq 'Graphic') then begin
        MESSAGE, !error_state.msg, /NONAME
      endif else begin
        self->ErrorMessage, $
        [IDLitLangCatQuery('Error:System:Text1'), $
         !error_state.msg], $
        title=IDLitLangCatQuery('Error:System:Title'), severity=2
       return, oResult  ; either obj_new or oTool
       endelse
   endif

    ; Result if there is an error.
    oResult = OBJ_NEW()

   ;; Give this tool a default name
   toolName = KEYWORD_SET(winTitle) ? winTitle : "IDL iTool"

   ;; Now get the UI Descriptor
   if (~KEYWORD_SET(userInterface)) then $
     userInterface = "Default"

   ;; Do we have this tool
   oDesc = self->IDLitContainer::GetByIdentifier("/registry/tools/"+strToolName)
   if (~OBJ_VALID(oDesc)) then begin
        MESSAGE, /NONAME, $
           IDLitLangCatQuery('Message:Framework:ToolNotRegistered')
   endif

   ; Setting the USER_INTERFACE to ITWINDOW will produce just a bare itWindow
   ; without a user interface. This is useful for embedding an iTools
   ; window within a Java or COM application.
   if (~STRCMP(userInterface, 'ITWINDOW', /FOLD_CASE)) then begin
       oUIDesc = self->IDLitContainer::GetByIdentifier( $
                 "/Registry/Widgets/Interface/" + userInterface)

       if (~OBJ_VALID(oUIDesc)) then begin
         MESSAGE, /NONAME, $
            IDLitLangCatQuery('Message:Framework:ToolUINotRegistered') + $
            '"' + userInterface + '"' + $
            IDLitLangCatQuery('Message:Framework:ToolUINotRegistered2')
       endif
   endif

   oGeneral = self->GetByIdentifier("/REGISTRY/SETTINGS/GENERAL_SETTINGS")

   ;; get current language settings from oGeneral and update the
   ;; langcat service if needed
   oSrvLangCat = self->GetService('LANGCAT')
   IF obj_valid(oSrvLangCat) THEN BEGIN
     oGeneral->getProperty,_LANGUAGE=langName
     IF strupcase(langName) NE 'ENGLISH' THEN BEGIN
       langs = oSrvLangCat->GetAvailableLanguages()
       wh = where(strupcase(langs) EQ strupcase(langName))
       IF wh[0] NE -1 THEN BEGIN
         oSrvLangCat->SetLanguage,langName
       ENDIF ELSE BEGIN
         wh = (where(strupcase(langs) EQ 'ENGLISH'))[0] > 0
         oGeneral->SetProperty,LANGUAGE=wh
       ENDELSE
     ENDIF
   ENDIF

   ;; Create this tool.
   oTool = oDesc->GetObjectInstance()

   oTool->setProperty, NAME=toolName, IDENTIFER=NAME, $
    _TOOL_NAME=strToolName, _EXTRA=_extra
   oTool->_SetSystem, self
   ;; Make sure the tool is registered in the system
   self->AddByIdentifier, "TOOLS", oTool

   oTool->DisableUpdates, PREVIOUSLY_DISABLE=wasDisabled

   oTool->GetProperty, TYPES=types
   self->UpdateToolByType, oTool, types

    oSysDesc = self->GetVisualization(/ALL, COUNT=count)
    for i=0,count-1 do begin
        oSysDesc[i]->GetProperty, NAME=name, CLASSNAME=classname, $
            ICON=icon, PRIVATE=private
        ; Avoid registering our visualization twice. This allows
        ; a subclass to register its own visualization and override
        ; the system's visualizations.
        oToolDesc = oTool->GetVisualization(name)
        if (~OBJ_VALID(oToolDesc)) then begin
            oTool->RegisterVisualization, name, classname, $
                ICON=icon, PRIVATE=private
            oToolDesc = oTool->GetVisualization(name)
        endif
        ; We want to hide our NAME and DESCRIPTION properties,
        ; but we don't want to simply call SetPropertyAttribute since
        ; that would actually instantiate an object of each vis type, which
        ; is slow. Instead, get the PropertyDescriptor objects directly from
        ; the IDLitComponent class, and set the HIDE property.
        oProps = oToolDesc->IDLitComponent::_GetAllPropertyDescriptors()
        oProps[0]->SetProperty, /HIDE
        oProps[1]->SetProperty, /HIDE
    endfor

    oSysDesc = self->GetAnnotation(/ALL, COUNT=count)
    for i=0,count-1 do begin
        oSysDesc[i]->GetProperty, $
            NAME=name, CLASSNAME=classname, ICON=icon
        ; Avoid registering our annotation twice.
        oToolDesc = oTool->GetAnnotation(name)
        if (~OBJ_VALID(oToolDesc)) then begin
            oTool->RegisterAnnotation, name, classname, ICON=icon
            oToolDesc = oTool->GetAnnotation(name)
        endif
        ; See note above about why we are doing this.
        oProps = oToolDesc->IDLitComponent::_GetAllPropertyDescriptors()
        oProps[0]->SetProperty, /HIDE
        oProps[1]->SetProperty, /HIDE
    endfor

    ; Are we changing to a default style?
    oGeneral->GetProperty, _DEFAULT_STYLE=defaultStyle
    if (defaultStyle ne '') then begin
        oSrvStyle = self->GetService('STYLES')
        oSrvStyle->VerifyStyles, TOOL=oTool
        ; This will quietly return if failure.
        void = oSrvStyle->UpdateCurrentStyle(defaultStyle, $
            TOOL=oTool, /NO_TRANSACT)
    endif

   ;; Build the user interface
   if (OBJ_VALID(oUIDesc)) then begin
        status = self->_InitializeUserInterface( oTool, oUIDesc, $
            TITLE=winTitle, _extra=_extra)
        if (~status) then begin
            OBJ_DESTROY, oTool
            MESSAGE, /NONAME, $
                IDLitLangCatQuery('Message:Framework:CannotCreateToolInterface') + $
                '"' + userInterface + '"'
        endif
    endif else begin
      oTool->SetProperty, _HAS_UI=0
    endelse
    
    ;; Set our current manipulator
    oTool->ActivateManipulator, /DEFAULT

    ; Set the general settings on the tool after the UI has been
    ; created, so that we have a window objref.
    oGeneral->_InitialToolSettings, oTool

    ; If a view grid is requested, set that up now.
    ; Also pass along other window props, like ZOOM_ON_RESIZE, CURRENT_ZOOM, etc.
    if (N_Elements(viewGrid) || N_ELEMENTS(_extra)) then begin
        oWin = oTool->GetCurrentWindow()
        if (OBJ_VALID(oWin)) then begin
            strProps = oWin->QueryProperty()
            oWin->SetProperty, VIEW_GRID=viewGrid, _EXTRA=strProps
        endif
    endif

    idTool = oTool->GetFullIdentifier()

   ;; At this point, if any data was provided, it would be
   ;; placed into the tool
   IF (n_elements(initial_data) GT 0) then begin
       oCmds = self->IDLitSystem::CreateVisualization(idTool, $
                                                      initial_data, $
                                                      NAME=visName, $
                                                      _extra=_extra, /NO_TRANSACT)
   endif else begin
       void = oTool->CustomizeGraphics(/NO_TRANSACT)
   endelse

    self->_SetCurrentTool, oTool

   ; If we reach this point it is safe to return the tool.
   oResult = oTool

   if (ISA(update) && update eq 0) then disableUpdates = 1b

   if (~wasDisabled && ~KEYWORD_SET(disableUpdates)) then $
     oTool->EnableUpdates

   self->_UpdateClipboardStatus ;; make sure the new tool is updated

   return, oTool
end
;;---------------------------------------------------------------------------
;; IDLitSystem::CreateVisualization
;;
;; Purpose:
;;
;;
;; TODO: This will need to change once the DM is up
;;
function IDLitSystem::CreateVisualization, idTool, oData, $
    AUTO_DELETE=autoDelete, $   ; delete the data after the vis is destroyed
    COLOR=color, $   ; handle manually so we don't pass to axes
    CURRENT=current, $
    DEVICE=device, $
    FONT_COLOR=fontColor, $
    FONT_SIZE=fontSize, $
    LAYOUT=layout, $
    MARGIN=margin, $
    NAME=name, $
    NODATA=noData, $
    NO_TRANSACT=noTransact, $
    POSITION=position, $
    TITLE=dataspaceTitle, $
    VISUALIZATION_TYPE=VISUALIZATION_TYPE, $
    OVERPLOT=overplot, $
    AXIS_STYLE=axisStyle, $
    XTICKFONT_SIZE=xticksize, $
    YTICKFONT_SIZE=yticksize, $
    ZTICKFONT_SIZE=zticksize, $
    XTICKLEN=xticklen, $
    YTICKLEN=yticklen, $
    ZTICKLEN=zticklen, $
    XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange, $
    _REF_EXTRA=_extra
    
  compile_opt idl2, hidden
  
  oTool = self->IDLitContainer::GetByIdentifier(idTool)
  if(~obj_valid(oTool))then $
    return, obj_new()
    
  oCreate = oTool->GetService("CREATE_VISUALIZATION")
  if (~OBJ_VALID(oCreate))then $
    return, obj_new()
    
  ; Modify the View and Layer properties before we create the vis
  if (N_ELEMENTS(_extra) gt 0) then begin
    oWin = oTool->GetCurrentWindow()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()
    if (OBJ_VALID(oView)) then begin
      oView->SetProperty, _EXTRA=['LAYOUT_POSITION','STRETCH_TO_FIT', $
                                  'XMARGIN','YMARGIN','CURRENT_ZOOM']
    endif
    if (OBJ_VALID(oLayer)) then begin
      oLayer->SetProperty, _EXTRA=['DEPTH_CUE','DEPTHCUE_BRIGHT','DEPTHCUE_DIM','PERSPECTIVE']
    endif
  endif
  
  if ((N_ELEMENTS(visualization_type) ne 0) && $
      PRODUCT(STRMATCH(visualization_type, 'IMAGE', /fold_case)) && $
      ~KEYWORD_SET(overplot)) then begin
    ; Need view dimensions
    hasViewDims = 0b
    oWin = oTool->GetCurrentWindow()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    if (OBJ_VALID(oView)) then begin
      oView->GetProperty, VIRTUAL_DIMENSIONS=viewDims
      hasViewDims = 1b
    endif 
    ; and image dimensions
    hasImgDims = 0b
    if (OBJ_VALID(oData)) then begin
      oParams = oData->Get(/ALL, NAME=paramNames)
      foreach paramName,paramNames,i do begin
        if (paramName eq 'IMAGEPIXELS') then begin
          success = oParams[i]->GetData(pData, /POINTER)
          if (success) then begin
            imgDims = SIZE(*pData[0], /DIMENSIONS)
            hasImgDims = 1b
          endif
        endif
      endforeach
    endif
    ; Change margins to something appropriate for an image 
    if (hasViewDims && hasImgDims) then begin
      if (MAX(imgDims gt (viewDims*0.90))) then begin
        ; Was AXIS_STYLE set?
        hasAxes = KEYWORD_SET(axisStyle)
        ; If we don't have axes, pick a suitable margin.
        ; Otherwise, if we have axes, fall through to the plot margins below.
        if (~ISA(margin) && ~hasAxes) then begin
          top = ISA(dataspaceTitle,'STRING') ? 0.1d : 0.05d
          margin = [0.05d, 0.05d, 0.05d, top]
        endif
        ; Ensure a layout exists for proper location calculation
        if (N_ELEMENTS(layout) ne 3) then $
          layout = [1,1,1]
      endif
    endif
  endif

  ; Get position
  oTool->_CalculatePosition, POSITION=position, $
                             MARGIN=margin, $
                             DEVICE=device, $
                             LAYOUT=layout, $
                             OVERPLOT=overplot, $
                             TITLE=dataspaceTitle, $
                             XTICKFONT_SIZE=xticksize, $
                             YTICKFONT_SIZE=yticksize, $ 
                             ZTICKFONT_SIZE=zticksize, $
                             XTICKLEN=xticklen, $
                             YTICKLEN=yticklen, $
                             ZTICKLEN=zticklen, $
                             FONT_SIZE=fontSize
  
  if (KEYWORD_SET(current) && ~KEYWORD_SET(overplot)) then begin
    ; Prepare the service that will create the axis visualization.
    oCreateDS = oTool->GetService("CREATE_DATASPACE")
    if (not OBJ_VALID(oCreate)) then $
      return, OBJ_NEW();
      
    ; Create the dataspace
    ; Pass in keywords here and also down below.  Here is needed for inclusion
    ; in the undo/redo buffer, whilst the actual application does not occur
    ; until later
    oCmdDS = oCreateDS->CreateDataSpace("DATA SPACE", POSITION=position, DEVICE=device)
    
    ; Get the new dataspace ID for destination purposes
    oWin = oTool->GetCurrentWindow()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()
    oDS = OBJ_VALID(oLayer) ? oLayer->GetCurrentDataspace() : OBJ_NEW()
    idDS = OBJ_VALID(oDS) ? oDS->GetFullIdentifier() : ''
  endif else if (KEYWORD_SET(overplot)) then begin
    if (ISA(overplot, 'Graphic')) then begin
      overplot = oTool->GetByIdentifier(overplot->GetFullIdentifier())
    endif
    if (ISA(overplot, '_IDLitVisualization')) then begin
      oDS = overplot->GetDataspace()
      idDS = OBJ_VALID(oDS) ? oDS->GetFullIdentifier() : ''
    endif
  endif
  
  idVis = ''
  nVisType = N_ELEMENTS(visualization_type)
  if (nVisType gt 0) then begin
    if (nVisType gt 1) then $
      idVis = STRARR(nVisType)
    for i=0,nVisType-1 do begin
      ; get the abs id of this desired visualization.
      oVis = oTool->GetVisualization(visualization_type[i])
      if (~obj_valid(oVis)) then $
        continue
      idVis[i] = oVis->GetFullIdentifier()
    endfor
  endif
  
  ; These properties need to be set after the visualization
  ; is created, and they need to be set on either the dataspace
  ; or the axes.
  normDSProps = ['SCALE_ISOTROPIC', 'ANISOTROPIC_SCALE_2D', $
                  'ANISOTROPIC_SCALE_3D', $
                  'ASPECT_RATIO', 'ASPECT_Z', $
                  'POSITION', 'DEVICE']
  ; We don't want to pass in the above properties, otherwise
  ; they might be set twice. So filter them out.
  nextra = N_ELEMENTS(_extra)
  if (nextra gt 0) then begin
    for i=0,nextra-1 do begin
      ; Only keep keywords that don't match the above list.
      if (MAX(_extra[i] eq normDSProps) eq 0) then begin
        ; extrakeep will be undefined if there are no
        ; matching keywords. This is okay.
        extrakeep = (N_ELEMENTS(extrakeep) gt 0) ? $
          [extrakeep, _extra[i]] : _extra[i]
      endif
    endfor
  endif
  
  IF obj_valid(oData) THEN BEGIN
    if (~KEYWORD_SET(noData)) then begin
      if (KEYWORD_SET(autoDelete)) then begin
        if (ISA(oData, 'IDLitData')) then begin
          oData->SetProperty, /AUTO_DELETE
        endif
        if (ISA(oData, 'IDLitDataContainer')) then begin
          oChild = oData->Get(/ALL)
          foreach obj, oChild do obj->SetProperty, /AUTO_DELETE
        endif
      endif
      self->AddByIdentifier, "/Data Manager", oData
    endif
    
    oCmds=oCreate->CreateVisualization(oData, idVis, $
      COLOR=color, $
      ID_VISUALIZATION=visNewID, $
      NAME=name, $
      DESTINATION=idDS, $
      FONT_COLOR=fontColor, $
      FONT_SIZE=fontSize, $
      NODATA=noData, $
      NO_TRANSACT=noTransact, $
      AXIS_STYLE=axisStyle, $
      _EXTRA=extrakeep)
    if (MIN(OBJ_VALID(oCmdDS)) ne 0) then $
      oCmds = [oCmdDS, oCmds]

    if KEYWORD_SET(noData) then OBJ_DESTROY, oData
  ENDIF else begin
    oCmds = Obj_New()
  endelse
  
  if (N_ELEMENTS(visNewID) && visNewID ne '' && $
    N_ELEMENTS(_extra)) then begin
    oVis = self->IDLitContainer::GetByIdentifier(visNewID)
    oDataSpace = OBJ_VALID(oVis) ? $
      oVis->GetDataSpace(/UNNORMALIZED) : OBJ_NEW()
    if (OBJ_VALID(oDataSpace)) then begin
      ; When starting from the command line, disable
      ; automatic updates for any ranges explicitly
      ; set via the command line.  This will allow
      ; overplots to use the same range (unless the
      ; automatic updates are explicitly re-enabled
      ; by the user first).
      oDataSpace->GetProperty, $
        X_AUTO_UPDATE=xAutoUpdate, $
        Y_AUTO_UPDATE=yAutoUpdate, $
        Z_AUTO_UPDATE=zAutoUpdate
      if (ISA(xrange)) then xAutoUpdate = 0
      if (ISA(yrange)) then yAutoUpdate = 0
      if (ISA(zrange)) then zAutoUpdate = 0
      oDataSpace->SetProperty, $
        X_AUTO_UPDATE=xAutoUpdate, $
        Y_AUTO_UPDATE=yAutoUpdate, $
        Z_AUTO_UPDATE=zAutoUpdate, $
        XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
        
      oAxes = oDataSpace->GetAxes(/CONTAINER)
      
      if (OBJ_VALID(oAxes)) then begin
        if ISA(_extra) then begin
          first = STRMID(_extra,0,1)
          axisProps = _extra[WHERE(first eq 'X' or first eq 'Y' or first eq 'Z', /NULL)]
          fontProps = _extra[WHERE(STRCMP(_extra, 'FONT_', 5), /NULL)]
        endif

        ; Pass the FONT_* properties first. Then pass the X/Y/Z* properties.
        ; That way things like XTICKFONT_NAME will override just FONT_NAME.
        oAxes->SetProperty, TEXT_COLOR=fontColor, $
          FONT_SIZE=fontSize, _EXTRA=fontProps
        oAxes->SetProperty, _EXTRA=axisProps, $
          AXIS_STYLE=axisStyle, $
          XTICKFONT_SIZE=xticksize, YTICKFONT_SIZE=yticksize, $
          ZTICKFONT_SIZE=zticksize, $
          XTICKLEN=xticklen, YTICKLEN=yticklen, ZTICKLEN=zticklen, $
          XRANGE=xrange, YRANGE=yrange, ZRANGE=zrange
      endif
    endif
    
    ; Set POSITION and data space related values
    oNormDataSpace = OBJ_VALID(oVis) ? oVis->GetDataSpace() : OBJ_NEW()
    if (OBJ_VALID(oNormDataSpace)) then begin
      oNormDataSpace->SetProperty, POSITION=position, DEVICE=device, $
          _EXTRA=normDSProps
    endif
    
  endif
  
  return, oCmds
  
end


;;---------------------------------------------------------------------------
;; IDLitSystem::_SetCurrentTool
;;
;; Purpose:
;;   Used to set the current tool in the system.
;;
;; Parameter
;;    oTool    - The tool to set as current. This tool, must
;;               exist, be valid and part of the system.
;;
; KEYWORD PARAMETERS:
;   SHOW: If set then also ensure that the tool is visible
;   and raised (not iconified).
;;

PRO IDLitSystem::_SetCurrentTool, oTool, SHOW=show

    compile_opt idl2, hidden

    ; Assume all error checking on oTool has been done by caller.

    if (self._oCurrentTool ne oTool) then begin

      ; Send the "I'm not in focus message"
      ; Make sure we havn't been deleted before sending message.
      ; This could happen if the user just killed the old window.
      oldTool = self._oCurrentTool
      self._oCurrentTool = oTool
  
      if OBJ_VALID(oldTool) then begin
          id = oldTool->GetFullIdentifier()
          oldTool->DoOnNotify, id, "FOCUS_CHANGE", 0
          if (obj_valid(self._oUIConnection)) then begin
              self._oUIConnection->HandleOnNotify, $
                  self->GetFullIdentifier(), "FOCUS_LOSS", id
          endif
      endif

      ; Make sure we havn't been deleted before sending message.
      ; This shouldn't really happen since this is now the current
      ; tool, but just in case.
      if (~OBJ_VALID(oTool)) then $
          return
  
      ; Send the "I'm in focus message"
      id = oTool->GetFullIdentifier()
      oTool->DoOnNotify, id, "FOCUS_CHANGE", 1
      if (obj_valid(self._oUIConnection)) then begin
          self._oUIConnection->HandleOnNotify, $
              self->GetFullIdentifier(), "FOCUS_GAIN", id
  
      endif

      ; Access the group leader of the tool's UI object,
      ; and set it on ourself. That way, if a UIService is fired
      ; off on the System, the current tool is the group leader.
      if (OBJ_VALID(oTool._oUIConnection)) then begin
          oTool._oUIConnection->GetProperty, GROUP_LEADER=groupLeader
          self._oUIConnection->SetProperty, GROUP_LEADER=groupLeader
      endif

    endif
    
    if (Keyword_Set(show)) then begin
      id = oTool->GetFullIdentifier()
      oTool->DoOnNotify, id, "SHOW", 1
    endif

    ; Let the Workbench know that our current tool has changed.
    void = IDLNotify('IDLitSetCurrent', id)

end


;;---------------------------------------------------------------------------
;; IDLitSystem::_GetCurrentTool
;;
;; Purpose:
;;   Returns the current tool object.
;;
;; Return Value:
;;   The current tool object or NULL if no tool is current.
;;
function IDLitSystem::_GetCurrentTool
   compile_opt idl2, hidden


   if (~obj_valid(self._oCurrentTool)) then begin
       ;; No current tool. This should only be the case when no tools
       ;; exist. See if this is the case
       conTools = self->IDLitContainer::GetByIdentifier("TOOLS")

       ;; See if the current tool is actually a bad obj ref.
       ; CT Note: Leave this as a "ne obj_new".
       if(self._oCurrentTool ne obj_new())then $
           conTools->IDL_Container::Remove, self._oCurrentTool

        ; This will also perform any notification.
        self->_SetCurrentTool, conTools->Count() eq 0 ? obj_new() : $
                             conTools->Get() ;; just get the first one
   endif
   return, self._oCurrentTool
end
;;---------------------------------------------------------------------------
;; Public Tool access
;;---------------------------------------------------------------------------
;; IDLitSystem::SetCurrentTool
;;
;; Purpose:
;;   Used to set the current tool in the system.
;;
;; Parameter
;;    idTool    - The tool to set as current. This tool, must
;;                exist, be valid and part of the system.
; KEYWORD PARAMETERS:
;   SHOW: If set then also ensure that the tool is visible
;   and raised (not iconified).
;;
PRO IDLitSystem::SetCurrentTool, idTool, SHOW=show

   compile_opt idl2, hidden

   oTool = self->IDLitContainer::GetByIdentifier(idTool)
   if(~obj_valid(oTool))then begin
      self->ErrorMessage, $
        IDLitLangCatQuery('Error:SetCurrentTool:Text1')+idTool , $
        title=IDLitLangCatQuery('Error:SetCurrentTool:Title'), severity=2
      return
  endif

   if (~obj_isa(oTool, "IDLitTool")) then begin
       self->ErrorMessage, $
         [IDLitLangCatQuery('Error:SetCurrentTool:Text2'), $
          obj_class(oTool)], $
         title=IDLitLangCatQuery('Error:SetCurrentTool:Title'), severity=2
       return
   endif

   id = oTool->getFullIdentifier()
   oTmp = self->IDLitContainer::GetByIdentifier(id)
   if(oTmp ne oTool)then begin
       self->ErrorMessage, $
         [IDLitLangCatQuery('Error:SetCurrentTool:Text3'), $
          obj_class(oTool)], $
         title=IDLitLangCatQuery('Error:SetCurrentTool:Title'), severity=2
       return
   endif

   self->IDLitSystem::_SetCurrentTool, oTool, SHOW=show

end
;;---------------------------------------------------------------------------
;; IDLitSystem::GetCurrentTool
;;
;; Purpose:
;;   Returns the current tool object.
;;
;; Return Value:
;;   The current tool identifier or an empty string in not tool is
;;   current.
;;
function IDLitSystem::GetCurrentTool
   compile_opt idl2, hidden

   oTool = self->IDLitSystem::_GetCurrentTool()

   return, obj_valid(oTool) ? oTool->GetFullIdentifier() : ''
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_RemoveTool
;;
;; Purpose:
;;   This routine is used to remove a tool from the internal list of
;;   active tools in the sytem.
;;
;; Parameter
;;   oTool  - The tool to remove

PRO IDLitSystem::_RemoveTool, oTool
   compile_opt hidden, idl2

   if( not obj_valid(oTool))then $
     return
   if(not obj_isa(oTool, "IDLitTool"))then $
     return

   oTool->IDLitComponent::GetProperty, IDENTIFIER=id
   if (id ne '') then $
       void = self->IDLitContainer::RemoveByIdentifier('TOOLS/' + id)

   if (self._oCurrentTool eq oTool) then begin
        ; Just clear out our current tool. The next call to _GetCurrentTool
        ; will set this to the appropriate value.
        self._oCurrentTool = OBJ_NEW()
        if (obj_valid(self._oUIConnection)) then begin
            self._oUIConnection->HandleOnNotify, $
                self->GetFullIdentifier(), "FOCUS_LOSS", $
                oTool->GetFullIdentifier()

            ; Just clear out our group leader.  The next call to
            ; _GetCurrentTool will call _SetCurrentTool, which will
            ; reset this appropriately.
            self._oUIConnection->SetProperty, GROUP_LEADER=0
        endif
   endif

end

;;---------------------------------------------------------------------------
;; IDLitSystem::__ResetSystem
;;
;; Purpose:
;;   When called, this routine will destroy everything in the tools
;;   system. All tools are shutdown and the system object destroys
;;   itself. This is a very private method.
;;
;; Keywords:
;;   NO_PROMPT - If set, the user is not prompted and the reset is
;;               just performed.
;;
pro IDLItSystem::__ResetSystem, NO_PROMPT=NO_PROMPT
    compile_opt hidden, idl2
    common __IDLitSys$Initialize$__, c_isInitialized

    if(not keyword_set(NO_PROMPT))then begin
        status  = self->PromptUserYesNo($
           IDLitLangCatQuery('Message:Framework:ShutdownRestartSystem'), answer)
        if (status eq 0 || answer eq 0)then return
    endif
    ;; okay, grab our tools and fire the shutdown service.

    oToolsCon = self->GetByIdentifier("TOOLS")
    if(not obj_valid(oToolsCon))then return

    oTools = oToolsCon->Get(/all, count= nTools)
    for i=0, nTools-1 do begin
        if(obj_valid(oTools[i]))then $
          self->deleteTool, oTools[i]->GetFullIdentifier(), $
            /NO_PROMPT, /RESET
    endfor
    ;; Reset the internal common block flag for the system
    if(n_elements(c_isIntialized) gt 0)then $
      void  = temporary(c_isInitialized)

    ;; bye bye
    obj_destroy, self
end

;;---------------------------------------------------------------------------
;; IDLitSystem::DeleteTool
;;
;; Purpose:
;;   This routine is called to delete a given tool
;;
;; Parameter
;;   idTool   - The identifier of the tool to delete
;;
PRO IDLitSystem::DeleteTool, idTool, _EXTRA=_extra
   compile_opt idl2, hidden

   ;; Basically get the tool, grab it's shutdown services and shutdown
   ;; the tool.
   oTool = not  keyword_set(idTool) ? obj_new() : $
                    self->IDLitContainer::GetByIdentifier(idTool)
   if(not obj_valid(oTool))then return

   oShutdown = oTool->GetService("SHUTDOWN")

   if(not obj_valid(oShutdown))then $
     obj_destroy, oTool $   ;; Be forceful.
   else $
     oShutdown->DoShutdown, _EXTRA=_extra

end
;;---------------------------------------------------------------------------
;; Clipboard Interface
;;---------------------------------------------------------------------------
;; IDLitSystem::ClearClipboard
;;
;; Purpose:
;;   Used to remove and destroy all items contained in the local
;;   clipboard.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   None.
pro IDLitsystem::ClearClipboard
   compile_opt idl2, hidden

   oClip = self->GetbyIdentifier("/CLIPBOARD")

   oItems = oClip->Get(/all, count=nItems)
   if(nItems eq 0)then return

   oClip->Remove, oItems

   obj_destroy, oItems

end
;;---------------------------------------------------------------------------
;; IDLitSystem::GetClipboardItemCount
;;
;; Purpose:
;;   Return the number of items contained in the clipboard.
;;
;; Parameters:
;;  None.
;;
;; Keyword:
;;  None.
;;
;; Return value: Number of items in the clibboard
;;
function IDLitSystem::GetClipboardItemCount
   compile_opt hidden, idl2

   oClip = self->GetbyIdentifier("/CLIPBOARD")

   return, (obj_valid(oClip) ? oClip->Count() : 0)
end
;;---------------------------------------------------------------------------
;; IDLitSystem::BeginClipboardInteraction
;;
;; Purpose:
;;   Used to bracket operations on the clipboard.
;;
;;
pro IDLitSystem::BeginClipboardInteraction
    compile_opt hidden, idl2

    nClip = self->GetclipboardItemCount()
    self._bClipState = (nClip gt 0)
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_UpdateClipboardStatus
;;
;; Purpose:
;;   Used to send the current active/inactive status for the
;;   clipboard to all tools. This will update UI elements primarily.
;;
pro IDLitSystem::_UpdateClipboardStatus

   compile_opt hidden, idl2

   ;; Anything valid in the clipboard
   oClip = self->GetByIdentifier("/CLIPBOARD")
   ;; Get the items on the clipboard.
   oItems = oClip->Get(/all, count=nItems)

   ;; Get the by value status. This is used to manage paste special
   isAllbyValue=0
   ;; Get the list of parent types for this item. This is the
   ;; type of vis that the item can have as its parent. A type of ''
   ;; is anything.
   dTypes = ''
   for i=0, nItems-1 do begin
       by_value = oItems[i]->ContainsByValue(IS_ALL=IS_ALL)
       if(by_value && keyword_set(IS_ALL))then $
         isAllByValue++
       dTypes = [dTypes, oItems[i]->GetParentTypes()]
   endfor
   ;; Validate and uniq. the types.
   dTypes = dTypes[uniq(dtypes, sort(dTypes))]
   nDtypes = n_elements(dTypes)
   noTypes = (nDtypes eq 1 && dTypes[0] eq '')

   oToolCon = self->GetbyIdentifier("/Tools")
   oTools = oToolCon->Get(/all)
   id = "/REGISTRY/OPERATIONS/PASTE"
   ;; If there are not target parent types for this item,
   ;; update all tools menus generically
   if(noTypes ne 0)then begin
       ;; Loop through the tools and broadcast
       for i=0, n_elements(oTools)-1 do begin
           oTools[i]->DoOnNotify, id, "SENSITIVE", nItems gt 0

           oTools[i]->DoOnNotify,id+"SPECIAL" , "SENSITIVE", $
                nItems gt 0 && isAllByValue lt nItems
       endfor
   endif else begin
       ;; Make sure that the currently selected, primary item is
       ;; of the correct type for the given tool
       for i=0, n_elements(oTools)-1 do begin
          oSel = oTools[i]->GetSelectedItems(count=nSel)
          if(nSel gt 0)then begin
              selTypes = oSel[0]->GetTypes()
              for j=0, nDTypes-1 do begin
                  dex = where(dTypes[j] eq selTypes, nMatch)
                  if(nMatch gt 0)then break
              endfor
          endif else nMatch =0
           oTools[i]->DoOnNotify, id, "SENSITIVE", nMatch gt 0
           oTools[i]->DoOnNotify,id+"SPECIAL" , "SENSITIVE", 0
       endfor
   endelse
end
;;---------------------------------------------------------------------------
;; IDLitSystem::EndClipboardInteraction
;;
;; Purpose:
;;   Called when access to the clipboard is complete. Will check to
;;   see if the status of the clipboard has changed.
pro IDLitSystem::EndClipboardInteraction
    compile_opt hidden, idl2

 ;   nClip = self->GetclipboardItemCount()
;    if( (nClip gt 0) xor self._bClipState)then $
        self->_UpdateClipboardStatus
end

;;---------------------------------------------------------------------------
;; Dynamic functionality update section
;;---------------------------------------------------------------------------
;; IDLitSystem::UpdateToolByType
;;
;; Purpose:
;;   This routine will update any tool functionalty that has been
;;   registered in the system to the tool based on the given type.
;;
;; Parameters:
;;     oTool    - Target Tool
;;
;;     types     - The types to check.
;;
PRO IDLitSystem::UpdateToolByType, oTool, types
   compile_opt idl2, hidden

   ; Hack to prevent tool morphing on the new graphics.
   if (ISA(oTool, 'IDLitToolbaseGraphic')) then return
   
   ;;Loop on types
   for iType=0, n_elements(types)-1 do begin
       if(~keyword_set(types[iType]))then continue

       ;; Check for operations.
       oOps = self->_GetToolOperationsByType(types[iType], count=nOps)

       for i=0, nOps-1 do begin
           if (OBJ_ISA(oOps[i], 'IDLitRegProxy')) then begin
               oOps[i]->GetProperty, NAME=name, FINAL_IDENTIFIER=identifier, $
                   PROXY=proxy, DISABLE=disable, PRIVATE=private

               ;; Check if this operation already exists
               oMatch = oTool->GetOperations(IDENTIFIER=identifier, $
                   COUNT=count)
               if (count gt 0) then begin
                   ; If the operation already exists, but was disabled, and
                   ; the current operation is not disabled, then enable it.
                   oMatch->GetProperty, DISABLE=wasDisabled
                   if (wasDisabled && (~disable)) then begin
                       oMatch->SetProperty, DISABLE=0
                       matchId = oMatch->GetFullIdentifier()
                       oTool->DoOnNotify, matchId, "SENSITIVE", matchId
                   endif
               endif else begin
                   ; Register
                   oTool->RegisterOperation, name, PROXY=proxy, $
                       IDENTIFIER=identifier, PRIVATE=private
               endelse

           endif else begin
                oOps[i]->GetProperty, NAME=name, CLASSNAME=classname, $
                    FINAL_IDENTIFIER=identifier, DISABLE=disable, $
                     _OBJDESCTOOL=_objdesctool  ; contains all other keywords
               ;; Check if this operation already exists
               oMatch = oTool->GetOperations(IDENTIFIER=identifier, $
                   COUNT=count)
               if (count gt 0) then begin
                   ; If the operation already exists, but was disabled, and
                   ; the current operation is not disabled, then enable it.
                   oMatch->GetProperty, DISABLE=wasDisabled
                   if (wasDisabled && (~disable)) then begin
                       oMatch->SetProperty, DISABLE=0
                       matchId = oMatch->GetFullIdentifier()
                       oTool->DoOnNotify, matchId, "SENSITIVE", matchId
                   endif
               endif else begin
                   ;; Register
                   oTool->RegisterOperation, name, classname, $
                        IDENTIFIER=identifier, DISABLE=disable, $
                        _EXTRA=_objdesctool
               endelse
           endelse
       endfor

       ;; Check for manipulators.
       oMan = self->_GetToolManipulatorsByType(types[iType], count=nMan)
       for i=0, nMan-1 do begin
           oMan[i]->GetProperty, name=name, classname=classname, $
             final_identifier=identifier, description=description, $
             icon=icon
           ;; Check if this operation already exists
           ovoid = oTool->GetByIdentifier("manipulators/"+identifier)
           if(~obj_valid(oVoid))then begin
               ;; Register
               oTool->RegisterManipulator, name, classname, $
                 identifier=identifier, icon=icon, description=description
           endif
       endfor

       ;; Check the panels.  Note that panels may include manipulators,
       ;; so they should be added after the manipulators are registered.
       panels = self->_GetUIPanelRoutines(types[itype], count=nPanels)
       if(nPanels gt 0)then begin
           ;; Just send a update message to the target tool, with the
           ;; panels as the data
           oTool->DoOnNotify, oTool->GetFullIdentifier(), $
             "ADDUIPANELS", panels
       endif

   endfor
end
;;---------------------------------------------------------------------------
;; IDLitSystem::_RegisterUIConnection
;;
;; Purpose:
;;   Allows an external entity to register the UI callback
;;   object. This object is called when a UI service or notification
;;   is fired..
;;
;; Parameter:
;;   oConnection  - The UI connection
;;
;; Note: This method is "Protected" and only intented to be accessed
;; by "friend" classes.
;;
pro IDLitSystem::_RegisterUIConnection, oConnection


   compile_opt idl2, hidden

   self._oUIConnection = oConnection

end
;;---------------------------------------------------------------------------
;; IDLitTool::_UnRegisterUIConnection
;;
;; Purpose:
;;   Allows an external entity to unregister the UI callback
;;   object.
;;
;; Parameter:
;;   oConnection  - The UI connection to removed
;;
;; Note: This method is "Protected" and only intented to be accessed
;; by "friend" classes.
;;
pro IDLitSystem::_UnRegisterUIConnection, oConnection


   compile_opt idl2, hidden

   if(self._oUIConnection eq oConnection)then $
     self._oUIConnection = obj_new()

end


;;---------------------------------------------------------------------------
;; IDLitSystem::_SetError
;;
;; Purpose:
;;   Used to set the error state of the system. This just sets the
;;   state or information. Nothing else.
;;
;; Keywords
;;   CODE         - An error code of type long
;;
;;   SEVERITY     - The severity of the error.
;;
;;   DESCRIPTION  - A long string message for the error condition
;;

pro IDLitSystem::_SetError, _EXTRA=_EXTRA
    compile_opt idl2, hidden

    self._oLastError->SetProperty, _EXTRA=_EXTRA

end
;;---------------------------------------------------------------------------
;; IDLitSystem::GetLastErrorInfo
;;
;; Purpose:
;;   Used to get error information for the last error set in the
;;   system.
;;
;; Keywords:
;;   CODE         - An error code of type long
;;
;;   SEVERITY     - The severity of the error.
;;
;;   DESCRIPTION  - A long string message for the error condition

pro IDLitSystem::GetLastErrorInfo, _REF_EXTRA=_EXTRA
    compile_opt idl2, hidden
    self._oLastError->GetProperty, _EXTRA=_EXTRA
end


;;---------------------------------------------------------------------------
;; IDLitSystem::DoUIService
;;
;; Purpose:
;;  Public tool method used to request the peformance of a UI Service
;;
;; Return Value
;;   1    Success
;;   0    Error
;;
;; Parameters
;;   strService   - Name of the service
;;
;;   oRequester   - Object making the request
;;
function IDLitSystem::DoUIService, strService, oRequester

    compile_opt idl2, hidden

    if (~obj_valid(self._oUIConnection)) then $
        return, 0

    ; This is a system service if it starts with a /
    if (STRMID(strService, 0, 1) eq '/') then $
        return, self._oUIConnection->DoUIService( $
            STRMID(strService, 1), oRequester)

    ; Otherwise assume it is a tool-specific service. This allows
    ; tool-specific services such as AsciiTemplate to be called
    ; from the system, and have them called on the current tool.
    oTool = self->_GetCurrentTool()
    return, OBJ_VALID(oTool) ? $
        oTool->DoUIService(strService, oRequester) : 0

end

;;---------------------------------------------------------------------------
;; IDLitSystem::LangCatQuery
;;
;; Purpose:
;;   Queries the langcat service
;;
;; Parameters:
;;   KEY - String(s) key(s) for querying into the language catalog
;;
FUNCTION IDLitSystem::LangCatQuery, key
  compile_opt idl2, hidden

  return, self._oSrvLangCat->Query(key)

END


;;---------------------------------------------------------------------------
;; IDLitSystem::DoSetProperty
;;
;; Purpose:
;;   Interface routine used to set a property using the
;;   identification system of the tool. Also this allows
;;   property setting to be placed in the command buffer (undo-redo).
;;
;; Parameters:
;;  idTargets   - The targets that will have this property set.
;;
;;  idProperty  - The PROPERTY ID for the property to be set.
;;
;;  Value       - The new value of the property.

function IDLitSystem::DoSetProperty, idTargets, idProperty, Value

   compile_opt idl2, hidden

   oProperty = self->GetService("SET_PROPERTY")
   oCmd = oProperty->DoAction(self, idTargets, idProperty, Value)

   obj_destroy,oCmd
   return, 1
end


;---------------------------------------------------------------------------
function IDLitSystem::_GetSystem

   compile_opt hidden, idl2

   return, self
end


;---------------------------------------------------------------------------
pro IDLitSystem::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitContainer::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
pro IDLitSystem::DisableProgressBar

    compile_opt hidden, idl2

    if (~self._disableProgress) then begin
        self._disableProgress = 1b
        void = self->ProgressBar(/SHUTDOWN)
    endif

end


;---------------------------------------------------------------------------
pro IDLitSystem::EnableProgressBar

    compile_opt hidden, idl2

    self._disableProgress = 0b

end


;;---------------------------------------------------------------------------
;; IDLitSystem__Define
;;
;; Purpose:
;;   Object definition for the system object.
;;
PRO IDLitSystem__Define

   compile_opt idl2, hidden
   void = {IDLitSystem, $
           inherits IDLitContainer, $
           inherits _IDLitObjDescRegistry, $ ; Manages registry.
           inherits IDLitIMessaging,       $
           _szScreen      :     intarr(2), $ ; Size of the screen
           _iOffset      :      0,        $ ; Current offset position
           _nOffset      :      0,         $ ; Offset delta to use.
           _bClipState   :      0b,        $ ; Used for clipboard lockingo
           _bVerbose     :      0b,        $
           _bThrewDemoErr :      0b,        $ ; We already threw demo error
           _disableProgress : 0b, $
           _oUIConnection:      obj_new(),$ ; For the system UI
           _oLastError   :      obj_new(),$ ;; The last error message
           _oSrvLangCat  :      obj_new(),$ ; langcat service object
           _oProgress    :      obj_new(),$ ; progress bar message
           _oCurrentTool :      obj_new() $ ;the current tool
       }

end
