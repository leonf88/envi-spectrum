; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitgeneralsettings__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitGeneralSettings class. This class is
;   used to control and manage undo-redo preferences.
;
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; Purpose:
;; The constructor of the IDLitGeneralSettings object.
;;
;; Parameters:
;;
;; Properties:
;;   See SetProperty for rest of the properties
;;
function IDLitGeneralSettings::Init, _REF_EXTRA=_extra


    compile_opt idl2, hidden

    if (~self->IDLitIMessaging::Init(_extra=_extra)) then $
        return,0

    ;; Init superclass
    if (~self->IDLitComponent::Init(NAME="General Settings", $
        DESCRIPTION="General iTool Settings", $
        ICON='prop',$
        _EXTRA=_extra)) then $
        return, 0

    self->SetPropertyAttribute, ['NAME', 'DESCRIPTION'], SENSITIVE=0

    ; Register properties

    self->RegisterProperty, 'Unlimited', /BOOLEAN, $
      NAME="Unlimited buffer", $
      DESCRIPTION='If enabled, no buffer limit is established'

    self->RegisterProperty, 'MEMORY_LIMIT', /INTEGER, $
      SENSITIVE=0, $  ; initially insensitive
      NAME='Memory limit (Mb)', $
      DESCRIPTION='Memory limit for each iTools Undo-Redo Buffer in megabytes', $
      VALID_RANGE=[1,1000,1]

    self->RegisterProperty, 'ZOOM_ON_RESIZE', /BOOLEAN, $
        NAME='Zoom on window resize', $
        DESCRIPTION='Zoom window contents if window is resized'

    self->RegisterProperty, 'CHANGE_DIRECTORY', /BOOLEAN, $
        NAME='Change directory on open', $
        DESCRIPTION='Change current working directory when a file is opened'

    self->RegisterProperty, 'WORKING_DIRECTORY', USERDEF='', $
        NAME='Default working directory', $
        DESCRIPTION='Default working directory used for file selection'

    self->RegisterProperty, 'DEFAULT_STYLE', ENUMLIST=['<None>'], $
      NAME="Default style", $
      DESCRIPTION='Default style for visualizations and annotations'

    self->RegisterProperty, 'LANGUAGE', ENUMLIST=['<Default>'], $
      NAME="Language", $
      DESCRIPTION='Possible language choices'

    self->RegisterProperty, 'DRAG_QUALITY', ENUMLIST=['Low','Medium','High'], $
      NAME="Default drag quality", $
      DESCRIPTION='Default drag quality'

    self->RegisterProperty, 'PRINTER_OUTPUT_FORMAT', $
                            ENUMLIST=['Bitmap','Vector'], $
                            NAME="Printer output format", $
                            DESCRIPTION='The format sent to the printer'

    self->RegisterProperty, 'CLIPBOARD_OUTPUT_FORMAT', $
                            ENUMLIST=['Bitmap','Vector'], $
                            NAME="Clipboard output format", $
                            DESCRIPTION='The format sent to the clipboard'

    self->RegisterProperty, 'RESOLUTION', $
        /INTEGER, $
        NAME="Output resolution (dpi)", $
        DESCRIPTION='The output resolution (dots-per-inch) when saving to an image file'

    ; Default values.
    self._isUnlimited= 1
    self._Limit= 100  ; Mb
    self._bChangeDirectory = 1b
    self._dragQual = 2
    self._printVec = 1
    self._clipVec = 0
    self._resolution = 600 ; dpi

    if (N_ELEMENTS(_extra) gt 0) then $
        self->SetProperty, _EXTRA=_extra

    return, 1
end

;;---------------------------------------------------------------------------
;; IDLitGeneralSettings::Cleanup
;;
;; Purpose:
;; The destructor for the class.
;;
;; Parameters:
;; None.
;;
;pro IDLitGeneralSettings::Cleanup
;
;    compile_opt idl2, hidden
;
;    ;; Cleanup superclass
;    self->IDLitComponent::Cleanup
;end


;;---------------------------------------------------------------------------
;; Property Management
;;---------------------------------------------------------------------------
;; IDLitGeneralSettings::GetProperty
;;
;; Purpose:
;;   Used to get the value of the properties associated with this class.
;;
;; Keywords:
;;   MEMORY_LIMIT  - The memory limit of the object in MB
;;
;;   UNLIMITED     - True if the buffer is unlimited.
;;
pro IDLitGeneralSettings::GetProperty, $
    CHANGE_DIRECTORY=changeDirectory, $
    CLIPBOARD_OUTPUT_FORMAT=clipVec, $
    DEFAULT_STYLE=defaultStyleIndex, $
    DRAG_QUALITY=dragQual, $
    LANGUAGE=language, $
    MEMORY_LIMIT=memory_limit, $
    PRINTER_OUTPUT_FORMAT=printVec, $
    RESOLUTION=resolution, $
    UNLIMITED=unlimited, $
    UPDATE_CURRENTSTYLE=updateCurrentStyle, $
    WORKING_DIRECTORY=workingDirectory, $
    ZOOM_ON_RESIZE=zoomOnResize, $
    _DEFAULT_STYLE=defaultStyleName, $
    _LANGUAGE=languageName, $
    _REF_EXTRA=_super

    compile_opt idl2, hidden

    ; System settings.

    if (ARG_PRESENT(defaultStyleIndex)) then begin
        defaultStyleIndex = 0
        oSys = self->GetTool()
        if OBJ_VALID(oSys) then begin
            oService = oSys->GetService('STYLES')
            oStyles = oService->Get(/ALL, COUNT=nstyles)
            for i=0,nstyles-1 do begin
                oStyles[i]->IDLitComponent::GetProperty, $
                    NAME=styleName
                if STRCMP(styleName, self._defaultStyle) then $
                    break
            endfor
            ; Add 1 to defaultStyleIndex since first item is <None>.
            if (i lt nstyles) then $
                defaultStyleIndex = i+1
        endif
    endif

    ; Undocumented keyword to retrieve the actual style ID,
    ; rather than just the index.
    if (ARG_PRESENT(defaultStyleName)) then $
        defaultStyleName = self._defaultStyle


    ; Buffer settings.
    if(arg_present(memory_limit))then $
      memory_limit = self._Limit

    if (ARG_PRESENT(unlimited)) then $
      unlimited = self._isUnlimited


    if (ARG_PRESENT(updateCurrentStyle)) then $
        updateCurrentStyle = self._updateCurrentStyle

    ; Window settings.
    if (ARG_PRESENT(zoomOnResize)) then $
      zoomOnResize = self._zoomOnResize


    ; Tool settings.
    if (ARG_PRESENT(changeDirectory)) then $
        changeDirectory = self._bChangeDirectory

    if (ARG_PRESENT(workingDirectory)) then $
        workingDirectory = self._strWorkingDirectory

    if (ARG_PRESENT(language)) then BEGIN
      oSrvLangCat = (_IDLitSys_GetSystem())->GetService('LANGCAT')
      IF obj_valid(oSrvLangCat) THEN BEGIN
        langs = oSrvLangCat->GetAvailableLanguages()
        wh = where(self._language EQ strupcase(langs))
        IF wh[0] EQ -1 THEN $
          wh = where(strupcase(langs) EQ $
                     strupcase(oSrvLangCat->_GetDefaultLanguage()))
        language = wh[0] > 0
      ENDIF ELSE language=0
    ENDIF

    if (ARG_PRESENT(languageName)) then $
        languageName = self._language

    if (ARG_PRESENT(dragQual)) then $
        dragQual = self._dragQual

    if (ARG_PRESENT(printVec)) then $
        printVec = self._printVec

    if (ARG_PRESENT(clipVec)) then $
        clipVec = self._clipVec

    if (ARG_PRESENT(resolution)) then $
      resolution = self._resolution

    ;; Call the superclass
    if(n_elements(_super) gt 0)then $
        self->IDLitComponent::GetProperty, _EXTRA=_super

end

;;---------------------------------------------------------------------------
;; IDLitGeneralSettings::SetProperty
;;
;; Purpose:
;;   Used to set the value of the properties associated with this class.
;;
;; Properties:
;;   MEMORY_LIMIT  - The memory limit of the object in MB
;;
;;   UNLIMITED     - True if the buffer is unlimited.
pro IDLitGeneralSettings::SetProperty, $
    CHANGE_DIRECTORY=changeDirectory, $
    CLIPBOARD_OUTPUT_FORMAT=clipVec, $
    DEFAULT_STYLE=defaultStyleIndex, $
    DRAG_QUALITY=dragQual, $
    LANGUAGE=language, $
    MEMORY_LIMIT=memory_limit, $
    PRINTER_OUTPUT_FORMAT=printVec, $
    RESOLUTION=resolution, $
    UNLIMITED=unlimited, $
    UPDATE_CURRENTSTYLE=updateCurrentStyle, $
    WORKING_DIRECTORY=workingDirectoryIn, $
    ZOOM_ON_RESIZE=zoomOnResize, $
    _EXTRA=_super

    compile_opt idl2, hidden

    ; System settings.
    if (N_ELEMENTS(defaultStyleIndex) eq 1) then begin
        self._defaultStyle = ''
        oSys = self->GetTool()
        if OBJ_VALID(oSys) then begin
            oService = oSys->GetService('STYLES')
            oStyles = oService->Get(/ALL, COUNT=nstyles)
            ; Subtract 1 from defaultStyleIndex since first item is <None>.
            if (defaultStyleIndex && defaultStyleIndex le nstyles) then begin
                oStyles[defaultStyleIndex-1]->IDLitComponent::GetProperty, $
                    NAME=styleName
                self._defaultStyle = styleName
            endif
        endif
    endif

    ; Buffer settings.
    if (N_ELEMENTS(memory_limit) && memory_limit gt 0) then begin
        self._Limit = memory_limit
        updateBuffer = 1b
    endif

    if(N_ELEMENTS(unlimited) ne 0)then begin
        self._isUnlimited = KEYWORD_SET(unlimited)
        self->SetPropertyAttribute, "MEMORY_LIMIT", $
            SENSITIVE=~self._isUnlimited
        updateBuffer = 1b
    endif


    if (N_ELEMENTS(updateCurrentStyle) ne 0) then $
        self._updateCurrentStyle = KEYWORD_SET(updateCurrentStyle)

    ; Window settings.
    if (N_ELEMENTS(zoomOnResize) ne 0) then begin
        self._zoomOnResize = KEYWORD_SET(zoomOnResize)
        updateWindow = 1b
    endif


    ; Tool settings.
    if (N_ELEMENTS(changeDirectory) gt 0) then begin
        self._bChangeDirectory = KEYWORD_SET(changeDirectory)
        updateTool = 1b
    endif

    if (N_ELEMENTS(workingDirectoryIn) gt 0) then begin
        self._strWorkingDirectory = workingDirectoryIn
        self->SetPropertyAttribute, 'WORKING_DIRECTORY', $
            USERDEF=self._strWorkingDirectory
        ; If we don't automatically change directory on open,
        ; then we need to keep our tool directory in sync with
        ; the new working directory.
        if (~self._bChangeDirectory) then begin
            updateTool = 1b
            workingDirectory = workingDirectoryIn
        endif
    endif


    if (N_ELEMENTS(language) gt 0) then begin
      oSrvLangCat = (_IDLitSys_GetSystem())->GetService('LANGCAT')
      IF obj_valid(oSrvLangCat) THEN BEGIN
        langs = oSrvLangCat->GetAvailableLanguages()
        IF language LT n_elements(langs) THEN $
          self._language = strupcase(langs[language]) $
        ELSE $
          self._language = strupcase(oSrvLangCat->_GetDefaultLanguage())
        oSrvLangCat->SetLanguage,self._language
      ENDIF
    endif

    IF n_elements(dragQual) GT 0 THEN $
      self._dragQual = dragQual

    IF n_elements(printVec) GT 0 THEN $
      self._printVec = printVec

    IF n_elements(clipVec) GT 0 THEN $
      self._clipVec = clipVec

    if (N_ELEMENTS(resolution) gt 0) then $
      self._resolution = resolution

    self->_UpdateCurrentTools, $
        UPDATE_BUFFER=KEYWORD_SET(updateBuffer), $
        UPDATE_WINDOW=KEYWORD_SET(updateWindow), $
        UPDATE_TOOL=KEYWORD_SET(updateTool), $
        WORKING_DIRECTORY=workingDirectory

    if (N_ELEMENTS(_super) gt 0) then $
        self->IDLitComponent::SetProperty, _EXTRA=_super

end


;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to edit a user-defined property.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   PropertyIdentifier: String giving the name of the userdef property.
;
; Keywords:
;   None.
;
function IDLitGeneralSettings::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'WORKING_DIRECTORY': begin
        void = oTool->DoUIService('Directory', self)
        return, 0   ; don't need to undo/redo
        end

    else:

    endcase

    return, 0

end


;----------------------------------------------------------------------------
; Purpose:
;   Internal routine to sync up the current System styles with
;   the Default Style list in the General Settings.
;
pro IDLitGeneralSettings::_VerifyStyleNames

    compile_opt hidden, idl2

    oSys = self->GetTool()
    if (~OBJ_VALID(oSys)) then $
        return

    oService = oSys->GetService('STYLES')
    oService->VerifyStyles
    oStyles = oService->Get(/ALL, COUNT=nstyle)
    styleNames = STRARR(nstyle + 1)
    styleNames[0] = '<None>'
    match = 0

    ; Retrieve all of our new style names.
    for i=0,nstyle-1 do begin
        oStyles[i]->IDLitComponent::GetProperty, NAME=styleName
        styleNames[i+1] = styleName
        ; See if we have a match between the new names and the old.
        ; If so, we will reset the property value below.
        if (STRCMP(styleName, self._defaultStyle, /FOLD_CASE)) then $
            match = 1
    endfor

    self->SetPropertyAttribute, 'DEFAULT_STYLE', ENUMLIST=styleNames
    if ~match then $
        self._defaultStyle = ''

end


;----------------------------------------------------------------------------
; Purpose:
;   Internal routine to sync up the current available languages with
;   the list in the General Settings.
;
pro IDLitGeneralSettings::_VerifyLanguages
  compile_opt hidden, idl2

  oSys = self->GetTool()
  if (~OBJ_VALID(oSys)) then $
    return

  oSrvLangCat = oSys->GetService('LANGCAT')
  IF obj_valid(oSrvLangCat) THEN BEGIN
    langs = oSrvLangCat->GetAvailableLanguages()
    self->SetPropertyAttribute, 'LANGUAGE', ENUMLIST=langs, $
                                HIDE=(n_elements(langs) EQ 1)
  ENDIF

END

;---------------------------------------------------------------------------
; Purpose:
;   Internal method to update our settings
;   with the available styles, language, etc.
;
pro IDLitGeneralSettings::VerifySettings

    compile_opt hidden, idl2

    self->_VerifyStyleNames
    self->_VerifyLanguages
end

;---------------------------------------------------------------------------
; Purpose:
;   Internal method to update a single tool with the buffer settings.
;
pro IDLitGeneralSettings::_UpdateBufferSettings, oTool

    compile_opt hidden, idl2

    ; Buffer settings.
    oBuffer = oTool->_GetCommandBuffer()
    oBuffer->SetProperty, MEMORY_LIMIT= $
        (self._isUnlimited ? -1 : self._Limit * 1000.)

end

;---------------------------------------------------------------------------
; Purpose:
;   Internal method to update a single tool with the window settings.
;
pro IDLitGeneralSettings::_UpdateWindowSettings, oTool

    compile_opt hidden, idl2

    ; Window settings.
    oWin = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWin)) then begin
        oWin->SetProperty, DRAG_QUALITY=self._dragQual, $
          ZOOM_ON_RESIZE=self._zoomOnResize
    endif

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method to update a single tool with the tool settings.
;
;   WORKING_DIRECTORY will either come in as the current member value,
;   either from _UpdateToolSettings or SetProperty, or it will come
;   in undefined if it wasn't set in SetProperty.
;
pro IDLitGeneralSettings::_UpdateMyToolSettings, oTool, $
    WORKING_DIRECTORY=workingDirectory

    compile_opt hidden, idl2

    ; Tool settings.
    oTool->SetProperty, $
        CHANGE_DIRECTORY=self._bChangeDirectory, $
        WORKING_DIRECTORY=workingDirectory

end


;---------------------------------------------------------------------------
; Purpose:
;   Internal method to update a single tool with the current settings.
;   Called only from the System object on tool creation.
;
pro IDLitGeneralSettings::_InitialToolSettings, oTool

    compile_opt hidden, idl2

    self->_UpdateBufferSettings, oTool
    self->_UpdateWindowSettings, oTool
    self->_UpdateMyToolSettings, oTool, $
        WORKING_DIRECTORY=self._strWorkingDirectory
end


;;---------------------------------------------------------------------------
;; IDLitGeneralSettings::_UpdateCurrentTools
;;
;; Purpose:
;;   This routine will update the buffersettings on all currently
;;   active tools with the current settings in this system.
;;
pro IDLitGeneralSettings::_UpdateCurrentTools, $
        UPDATE_BUFFER=updateBuffer, $
        UPDATE_WINDOW=updateWindow, $
        UPDATE_TOOL=updateTool, $
        WORKING_DIRECTORY=workingDirectory

    compile_opt hidden, idl2

    ; Get the current set of tools and loop over them.
    oSystem = self->GetTool()
    if (~OBJ_VALID(oSystem)) then $
        return

    oToolsCon = oSystem->GetByIdentifier("/TOOLS")
    if (~OBJ_VALID(oToolsCon)) then $
        return
    oTools = oToolsCon->Get(/ALL, COUNT=nTools)

    for i=0, nTools-1 do begin
        if (KEYWORD_SET(updateBuffer)) then $
            self->_UpdateBufferSettings, oTools[i]
        if (KEYWORD_SET(updateWindow)) then $
            self->_UpdateWindowSettings, oTools[i]
        if (KEYWORD_SET(updateTool)) then $
            self->_UpdateMyToolSettings, oTools[i], $
                WORKING_DIRECTORY=workingDirectory
    endfor

end


;;---------------------------------------------------------------------------
;; Definition
;;---------------------------------------------------------------------------
;; IDLitGeneralSettings__Define
;;
;; Purpose:
;; Class definition for the IDLitGeneralSettings class
;;

pro IDLitGeneralSettings__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitGeneralSettings, $
          inherits   IDLitComponent,    $
          inherits   IDLitIMessaging,   $
          _Limit       : 0L,  $         ; what is the limit in Mb
          _isUnlimited : 0b, $          ; unlimited buffer
          _zoomOnResize : 0b, $         ; zoom window contents on window resize
          _bChangeDirectory: 0b,   $    ; Change directory on file open
          _updateCurrentStyle: 0b, $
          _strWorkingDirectory: '', $   ; Current working directory
          _language : '', $
          _dragQual : 0l, $
          _printVec : 0, $
          _clipVec : 0, $
          _resolution: 0, $
          _defaultStyle: '' $
         }
end
