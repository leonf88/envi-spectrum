; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitsys_createtool.pro#2 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;  IDLitsys_CreateTool
;
; PURPOSE:
;   Provides a procedural interface to create IDL tools.
;   This routine will also verify that the system is up and running.
;
; CALLING SEQUENCE:
;     id = IDLitSys_CreateTool(strTool)
;
; PARAMETERS
;   strTool   - The name of the tool to create
;
; KEYWORDS
;   All keywords are passsed to the system objects CreateTool method.
;
;   DEBUG: Set this keyword to disable error catching.
;
;   DISABLE_UPDATES: Set this keyword to disable updates on the
;       newly-created tool. If this keyword is set then the user
;       is responsible for calling EnableUpdates on the tool.
;       This keyword is useful when you want to do a subsequent overplot
;       or use DoAction to call an operation, but do not want to see the
;       intermediate steps.
;       Note: This keyword is ignored if the tool already exists.
;       In this case you should call DisableUpdates on the tool
;       before calling IDLitSys_CreateTool.
;
; RETURN VALUE
;   This routine will return the identifier of the created tool. If no
;   tool was created, then an empty '' string is returned.
;-

;-------------------------------------------------------------------------
; Purpose:
;   Helper routine to insert colorbar or legend.
;
pro IDLitSys_CreateTool_InsertAnnot, oTool, $
    COMMAND_NAME=cmdName, $
    INSERT_COLORBAR=insertColorbar, $
    INSERT_LEGEND=insertLegend, $
    OVERPLOT=overplot

    compile_opt idl2, hidden

    if (Keyword_Set(insertColorbar)) then begin
        oObjDesc = oTool->GetByIdentifier('Operations/Insert/Colorbar')
        if (N_Elements(insertColorbar) gt 1) then location = insertColorbar
    endif else if (Keyword_Set(insertLegend)) then begin
        insertLegendItem = 0b
        ; If we already have a legend, just add the new item to it.
        if (overplot) then begin
            oObjDesc = oTool->GetByIdentifier('Operations/Insert/LegendItem')
            if (Obj_Valid(oObjDesc)) then begin
                oAction = oObjDesc->GetObjectInstance()
                if (Obj_Valid(oAction)) then begin
                    insertLegendItem = oAction->QueryAvailability(oTool)
                endif
            endif
        endif
        ; Otherwise, create a new legend.
        if (~insertLegendItem) then begin
            oObjDesc = oTool->GetByIdentifier('Operations/Insert/Legend')
            if (N_Elements(insertLegend) gt 1) then location = insertLegend
        endif
    endif else begin
        return
    endelse

    if (~Obj_Valid(oObjDesc)) then return
    oAction = oObjDesc->GetObjectInstance()
    if (~Obj_Valid(oAction)) then return

    oSelect = oTool->GetSelectedItems(COUNT=count)

    oTmpCmd = (N_Elements(location) gt 0) ? $
        oAction->DoAction(oTool, LOCATION=location) : oAction->DoAction(oTool)

    if (Obj_Valid(oTmpCmd[0])) then begin
        ; For overplot, put the command into the undo/redo buffer.
        if (overplot) then begin
            oTmpCmd[N_Elements(oTmpCmd)-1]->SetProperty,NAME=cmdName
            oTool->_AddCommand, oTmpCmd
        endif else begin
            Obj_Destroy, oTmpCmd
        endelse
        for i=0,count-1 do oSelect[i]->Select
    endif
end

;-------------------------------------------------------------------------
; Purpose:
;   Helper routine to empty all visualizations out of a view.
;
pro IDLitSys_CreateTool_EmptyView, oView
    compile_opt idl2, hidden

    ; Sanity check.
    if (~OBJ_VALID(oView)) then $
        return

    oLayer = oView->Get(/ALL, ISA='IDLitgrLayer', COUNT=nLayer)
    for i=0,nLayer-1 do begin

        ; Don't destroy the annotation layer.
        if (~OBJ_VALID(oLayer[i]) || $
            OBJ_ISA(oLayer[i], 'IDLitgrAnnotateLayer')) then $
            continue

        oWorld = oLayer[i]->GetWorld()
        if (~OBJ_VALID(oWorld)) then $
            continue

        ; Retrieve all dataspaces.
        oDataspaces = oWorld->GetDataSpaces(COUNT=ndataspace)

        if (~ndataspace) then $
            continue

        for d=0,ndataspace-1 do begin
            ; Must notify the visualizations before the dataspace is removed
            oVisualizations = oDataSpaces[d]->GetVisualizations( $
                COUNT=count, /FULL_TREE)
            for j=0,count-1 do begin
                ; Send a delete message
                idVis = oVisualizations[j]->GetFullIdentifier()
                oVisualizations[j]->OnNotify, idVis, "DELETE", ''
                oVisualizations[j]->DoOnNotify, idVis, 'DELETE', ''
            endfor
        endfor

        ; We can just destroy the dataspaces since new ones
        ; will be created automatically.
        oLayer[i]->Remove, oDataSpaces
        OBJ_DESTROY, oDataSpaces

    endfor


end


;-------------------------------------------------------------------------
FUNCTION IDLitSys_CreateTool, strTool, $
    ASPECT_RATIO=aspectRatio, $
    BACKGROUND_COLOR=backgroundColorIn, $
    BUFFER=buffer, $
    CURRENT=currentIn, $
    DEBUG=debug, $
    DISABLE_UPDATES=disableUpdates, $
    FIT_TO_VIEW=fitToView, $
    FONT_NAME=fontName, $
    GEOTIFF=geotiff, $
    INITIAL_DATA=initial_data, $
    INSERT_COLORBAR=insertColorbar, $
    INSERT_LEGEND=insertLegend, $
    LAYOUT=layout, $
    MARGIN=margin, $
    POSITION=position, $
    DEVICE=device, $
    MACRO_NAMES=macroNames, $
    MAP_PROJECTION=mapProjection, $
    OVERPLOT=overplotIn, $
    STYLE_NAME=styleName, $
    TITLE=dataspaceTitle, $
    TOOLNAME=toolname, $
    UPDATE=update, $
    USER_INTERFACE=userInterface, $
    VIEW_GRID=viewGrid, $
    VIEW_NEXT=viewNext, $
    VIEW_NUMBER=viewNumber, $
    VIEW_TITLE=viewTitle, $
    VIEW_ZOOM=viewZoom, $
    WINDOW_TITLE=winTitle, $
    _REF_EXTRA=_extra

   compile_opt idl2, hidden

  
  if keyword_set(_extra) then begin
    foreach tagname, _extra, index do begin
      if (strmatch(tagname, "*COLOR*") && $
        (tagname ne "USE_DEFAULT_COLOR") && (tagname ne "AUTO_COLOR")) || $
        (tagname eq "BOTTOM") || (tagname eq "AMBIENT") then begin
        colorIn = SCOPE_VARFETCH(tagname, /REF_EXTRA)
        style_convert, colorIn, COLOR=color
        (SCOPE_VARFETCH(tagname, /REF_EXTRA)) = color
      endif
      
      if (((tagname eq "LINESTYLE") || (tagname eq "C_LINESTYLE") || $
        (tagname eq "XGRIDSTYLE") || (tagname eq "YGRIDSTYLE") || $
        (tagname eq "ZGRIDSTYLE")) && $
        ISA(SCOPE_VARFETCH(tagname, /REF_EXTRA), 'STRING'))  then begin
        (SCOPE_VARFETCH(tagname, /REF_EXTRA))  = $
          linestyle_convert(SCOPE_VARFETCH(tagname, /REF_EXTRA))
      endif
      
       if (((tagname eq "SYM_INDEX") || (tagname eq "SYMBOL")) && $
        ISA(SCOPE_VARFETCH(tagname, /REF_EXTRA), 'STRING'))  then begin
        (SCOPE_VARFETCH(tagname, /REF_EXTRA))  = $
          symbol_convert(SCOPE_VARFETCH(tagname, /REF_EXTRA))
      endif
  
      if ((tagname eq "NAME") && ISA(SCOPE_VARFETCH(tagname, /REF_EXTRA), 'STRING')) then $
        (SCOPE_VARFETCH(tagname, /REF_EXTRA))  = Tex2IDL(SCOPE_VARFETCH(tagname, /REF_EXTRA))
    
    endforeach
    
  endif
  
    ; see if FONT_NAME is set
    if (~ISA(fontName) && (!version.os_family eq "Windows") && $
        (CALL_FUNCTION('language_get') eq 1041)) then begin
      fontName = 'MS PGothic' 
    endif

    if (N_Elements(debug) gt 0) then begin
        Defsysv, '!iTools_Debug', Keyword_Set(debug)
    endif
   ;; Get the System tool
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
       Message, "SYSTEM ERROR: The iTools system cannot initialize"

    if (KEYWORD_SET(buffer)) then $
      userInterface = "Buffer"

    ; Check if a valid overplot situation was provided
    idTool = ''
    overplot = (N_ELEMENTS(overplotIn) eq 1) ? overplotIn[0] : 0
    current = (N_ELEMENTS(currentIn) eq 1) ? KEYWORD_SET(currentIn[0]) : 0

    if (overplot || $
        current || $
        N_ELEMENTS(viewNext) || $
        N_ELEMENTS(viewNumber)) then begin
        if (SIZE(overplot, /TYPE) eq 7 || SIZE(overplot, /TYPE) eq 11) then begin
          ; If the user gave us an ID or an objref, then retrieve the tool.
          obj = (SIZE(overplot, /TYPE) eq 7) ? $
            oSystem->GetByIdentifier(overplot) : overplot
          if (ISA(obj, 'Graphic')) then begin
            oTool = obj.tool
          endif else begin
            oTool = obj->GetTool()
          endelse
          idTool = oTool->GetFullIdentifier()
        endif else begin
          idTool = oSystem->GetCurrentTool()
        endelse
    endif

    ; If MACRO_NAMES, make sure each macro exists.
    if (N_ELEMENTS(macroNames) gt 0) then begin
        oSrvMacro = oSystem->GetService('MACROS')
        if (~OBJ_VALID(oSrvMacro)) then $
            MESSAGE, 'Macro service has not been registered.'
        for i=0, n_elements(macroNames)-1 do begin
            if (~OBJ_VALID(oSrvMacro->GetMacroByName(macroNames[i]))) then $
                MESSAGE, 'Macro "' + macroNames[i] + '" does not exist.'
        endfor
    endif

   if (idTool) then begin

        oTool = oSystem->GetByIdentifier(idTool)
        
        if (overplot) then begin
          if (SIZE(overplot, /TYPE) eq 7 || $
              SIZE(overplot, /TYPE) eq 11) then begin
            opID = (SIZE(overplot, /TYPE) eq 7) ? $
              opID : overplot->GetFullIdentifier()
          endif
          if (N_ELEMENTS(opID) ne 0) then begin
            pos1 = STRPOS(opID, 'DATA SPACE')
            if (pos1 ne -1) then begin
              pos2 = STRPOS(opID, '/', pos1)
              if (pos2 ne -1) then begin
                dsID = STRMID(opID, 0, pos2)
              endif else begin
                dsID = opID
              endelse 
              oDS = oTool->GetByIdentifier(dsID)
            endif
          endif
          ;; Try selected items
          if (~OBJ_VALID(oDS)) then begin
            oWin = ISA(oTool) ? oTool->GetCurrentWindow() : !NULL
            oView = ISA(oWin) ? oWin->GetCurrentView() : !NULL
            oLayer = ISA(oView) ? oView->GetCurrentLayer() : !NULL
            oDS = ISA(oLayer) ? oLayer->GetCurrentDataspace() : !NULL
            dsID = oDS->GetFullIdentifier()
          endif
          ;; If the ID'ed item did not include a data space then try elsewhere
          if (~OBJ_VALID(oDS)) then begin
            ;; Get first data space
            oWin = ISA(oTool) ? oTool->GetCurrentWindow() : !NULL
            oView = ISA(oWin) ? oWin->GetCurrentView() : !NULL
            dsID = ISA(oView) ? (oView->FindIdentifiers('*DATA SPACE*'))[0] : ''
            oDS = oTool->GetByIdentifier(dsID)
          endif
          if (ISA(oDS,'_IDLitVisualization') && $
              oDS->_GetWindowandViewG(oWin, oViewG)) then begin
            titleID = iGetId(dsID+'/title', DATASPACE=dsID)
          endif else begin
            titleID = ''
          endelse
          if (titleID ne '') then begin
            oTitle = oTool->GetByIdentifier(titleID)
            if (ISA(oTitle)) then begin
              oTitle->GetProperty, TRANSFORM=tr
              if (oDS->Is3D()) then begin
                oDS->VisToWindow, REFORM(tr[3,0:2]), titleLoc
              endif else begin
                titleLoc = iConvertCoord(REFORM(tr[3,0:2]), /DATA, /TO_DEVICE, $
                                         TARGET=oDS)
              endelse
            endif
          endif
        endif

        oTool->DisableUpdates, PREVIOUSLY_DISABLE=wasDisabled
        reEnableUpdates = ~wasDisabled
        if (ISA(update) && (update eq 0)) then reEnableUpdates = 0
        
        ; Handle the case where the caller is changing the WINDOW_TITLE
        ; whilst using the /OVERPLOT keyword
        if (N_ELEMENTS(winTitle) gt 0) then begin
            oTool->SetProperty, NAME=winTitle
        endif

        ; Handle my special view keywords.
        if (N_ELEMENTS(viewNext) || N_ELEMENTS(viewNumber)) then begin

            if OBJ_VALID(oTool) then begin
                oWin = oTool->GetCurrentWindow()

                if (OBJ_VALID(oWin)) then begin

                    ; Set my view keywords.
                    oWin->SetProperty, VIEW_NEXT=viewNext, $
                        VIEW_NUMBER=viewNumber

                    if (~overplot) then begin
                        IDLitSys_CreateTool_EmptyView, $
                            oWin->GetCurrentView()
                        ; Need to force a refresh if nothing changed.
                        oTool->RefreshCurrentWindow
                    endif

                endif  ; oWin
           endif  ; oTool

       endif  ; view keywords

       if (N_ELEMENTS(initial_data)) then BEGIN
         ;; Include MAP_PROJECTION so if we are creating an image, we pass
         ;; on the properties to the image's projection.
         oCmd = oSystem->CreateVisualization(idTool, initial_data, $
           MAP_PROJECTION=mapProjection, $
           STYLE=styleName, $  ; conflict between STYLE_NAME and STYLE property
           CURRENT=current, $
           TITLE=dataspaceTitle, $
           WINDOW_TITLE=winTitle, $
           OVERPLOT=overplot, $
           LAYOUT=layout, $
           MARGIN=margin, $
           POSITION=position, $
           DEVICE=device, $
           FONT_NAME=fontName,  $
           ASPECT_RATIO=aspectRatio, $
           _extra=_extra)
       ENDIF

       IF (n_elements(oCmd) gt 0) THEN BEGIN
          if (MIN(OBJ_VALID(oCmd)) eq 1) then begin
            oTool->_AddCommand, oCmd
            oCmd[n_elements(oCmd)-1]->GetProperty, NAME=cmdName
          endif else begin
            OBJ_DESTROY, oCmd
            oCmd = 0
          endelse
       ENDIF

   endif else begin

        ; Ignore the overplot setting since we didn't have a tool.
        overplot = 0

        toolname = (N_ELEMENTS(toolname) eq 1) ? toolname : strTool
        ; Include MAP_PROJECTION so if we are creating an image, we pass
        ; on the properties to the image's projection.
        oTool = oSystem->CreateTool(toolname, $
            INITIAL_DATA=initial_data, $
            /DISABLE_UPDATES, $
            LAYOUT=layout, $
            MARGIN=margin, $
            POSITION=position, $
            DEVICE=device, $
            MAP_PROJECTION=mapProjection, $
            VIEW_GRID=viewGrid, $
            USER_INTERFACE=userInterface, $
            STYLE=styleName, $  ; conflict between STYLE_NAME and STYLE property
            WINDOW_TITLE=winTitle, $
            FONT_NAME=fontName, $
            ASPECT_RATIO=aspectRatio, $
            _EXTRA=_extra)

        ; Make sure to re-enable updates, unless the user has forced
        ; them to remain off.
        reEnableUpdates = ~KEYWORD_SET(disableUpdates)
        if (ISA(update) && (update eq 0)) then reEnableUpdates = 0

   endelse

   if (~OBJ_VALID(oTool)) then $
     return, ''

   ;; add view title text annotation
   IF keyword_set(viewTitle) THEN BEGIN
     oManip = oTool->GetCurrentManipulator()
     oDesc = oTool->GetAnnotation('Text')
     oText = oDesc->GetObjectInstance()
     oText->SetProperty, $
       STRING=viewTitle[0], $
       ALIGNMENT=0.5, $
       LOCATIONS=[0,0.9,0.99], NAME='View Title'
     oTool->Add, oText, LAYER='ANNOTATION LAYER'
     IF obj_isa(oManip, 'IDLitManipViewPan') THEN $
       oTool->ActivateManipulator, 'VIEWPAN'

     IF overplot THEN BEGIN
       ;; record transaction
       oOperation = oTool->GetService('ANNOTATION') ;
       oCmd = obj_new("IDLitCommandSet", $
                      OPERATION_IDENTIFIER= $
                      oOperation->getFullIdentifier())
       iStatus = oOperation->RecordFinalValues( oCmd, oText, "")
       oCmd->SetProperty, $
         NAME=((n_elements(cmdName) GT 0) ? cmdName : "Text Annotation")
       oTool->_AddCommand, oCmd
     ENDIF
   ENDIF

   ; See if we have any map projection properties.
   ; The user must specify the MAP_PROJECTION keyword for the
   ; other keywords to take effect. If OVERPLOT then ignore.
   if (N_Elements(mapProjection) || N_Elements(geotiff)) then begin
        ; Fire up the Map Proj operation to actually change the value.
        ; This is a bit weird, but we pass in the keywords directly
        ; to DoAction. This is because the Map Projection operation needs
        ; to be very careful how it does its Undo/Redo command set,
        ; and it's easier to let the operation handle the details.
        oMapDesc = oTool->GetByIdentifier('Operations/Operations/Map Projection')
        if (OBJ_VALID(oMapDesc)) then begin
            oOp = oMapDesc->GetObjectInstance()
            oOp->GetProperty, SHOW_EXECUTION_UI=showUI
            ; Set all the map projection properties on our operation,
            ; then fire it up.
            oOp->SetProperty, SHOW_EXECUTION_UI=0, $
                MAP_PROJECTION=mapProjection, FONT_NAME=fontName, _EXTRA=_extra

            ; If the map proj operation creates a map grid, it will become
            ; the selected item, which we don't want for later operations
            ; like "insert colorbar". So save the current selected
            ; and restore it afterwards.
            oSelect = oTool->GetSelectedItems()

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
            oCmd = oOp->DoAction(oTool, POSITION=position, DEVICE=device, $
                                 CURRENT=current, ASPECT_RATIO=aspectRatio)
            oMap = (oTool->GetSelectedItems())[0]
            oMap->SetProperty, FONT_NAME=fontName, _EXTRA=_extra
            
            ; Restore the selected item.
            if (OBJ_VALID(oSelect[0])) then begin
              oSelect[0]->Select
            endif
            ; no undo
            obj_destroy, oCmd
            if (showUI) then $
                oOp->SetProperty, SHOW_EXECUTION_UI=showUI
        endif
    endif

  ; Add dataspace title annotation to the dataspace
  if (KEYWORD_SET(dataspacetitle)) then begin
    hasTitle = 0b
    if (KEYWORD_SET(overplot)) then begin
      ; Check to see if a title already exists
      titleID = KEYWORD_SET(dsID) ? iGetId(dsID+'/title', DATASPACE=dsID) : ''
      if (titleID ne '') then begin
        oTitle = oTool->GetByIdentifier(titleID)
        oTitle->SetProperty, STRING=dataspacetitle
        hasTitle = 1b
      endif
    endif
    if (~hasTitle) then begin
      if (N_ELEMENTS(layout) eq 3) then begin
        n = layout[0] > layout[1]
        fontSize = (n gt 2) ? 9 : ((n eq 2) ? 12 : 16)
      endif
      ; Pull out fonts from the extra keywords
      if (N_ELEMENTS(_extra) ne 0) then begin
        index = WHERE(STRCMP(_extra, 'FONT_', 5), nfound)
        if (nfound gt 0) then textKeywords = _extra[index]
      endif
      iText, dataspacetitle, /TITLE, FONT_SIZE=fontSize, FONT_NAME=fontName, $
        TARGET=(oTool->GetSelectedItems())[0], _EXTRA=textKeywords
    endif
  endif

   if n_elements(backgroundColorIn) gt 0 then begin
     Style_Convert, backgroundColorIn, COLOR=backgroundColor
     oWin = oTool->GetCurrentWindow()
     if (OBJ_VALID(oWin)) then begin
       oView = oWin->GetCurrentView()
       if obj_valid(oView) then begin
         oLayerVisualization = oView->GetCurrentLayer()
         if OBJ_VALID(oLayerVisualization) then BEGIN
           IF overplot THEN BEGIN
             oProperty = oTool->GetService("SET_PROPERTY")
             ;; Do not use oCmd here.  If the SetProperty fails, i.e., the new
             ;; colour is the same as the old colour then oCmd is null
             ;; and the creation of the overplot data would not get committed.
             oCmdTmp = oProperty->DoAction(oTool, oLayerVisualization->GetFullIdentifier(), $
                                        'COLOR', backgroundColor)
             if (Obj_Valid(oCmdTmp)) then begin
               oCmdTmp->SetProperty,NAME=cmdName
               oTool->_AddCommand, oCmdTmp
             endif
           ENDIF ELSE BEGIN
             oLayerVisualization->SetProperty, COLOR=backgroundColor
           ENDELSE
         ENDIF
       endif
     endif
   endif

    if (Keyword_Set(insertColorbar)) then begin
        IDLitSys_CreateTool_InsertAnnot, oTool, COMMAND_NAME=cmdName, $
            INSERT_COLORBAR=insertColorbar, OVERPLOT=overplot
    endif

    if (Keyword_Set(insertLegend)) then begin
        IDLitSys_CreateTool_InsertAnnot, oTool, COMMAND_NAME=cmdName, $
            INSERT_LEGEND=insertLegend, OVERPLOT=overplot
    endif

    if (N_ELEMENTS(styleName) && SIZE(styleName,/TYPE) eq 7) then begin
        ; If style name, make sure we have that style.
        oStyleService = oSystem->GetService('STYLES')
        if (~OBJ_VALID(oStyleService)) then $
            MESSAGE, 'Style service has not been registered.'
        oStyleService->VerifyStyles
        if (~OBJ_VALID(oStyleService->GetByName(styleName[0]))) then $
            MESSAGE, 'Style "' + styleName[0] + '" does not exist.'
        oDesc = oTool->GetByIdentifier('/Registry/Operations/Apply Style')
        oStyleOp = oDesc->GetObjectInstance()
        oStyleOp->GetProperty, SHOW_EXECUTION_UI=showUI
        oStyleOp->SetProperty, SHOW_EXECUTION_UI=0, $
            STYLE_NAME=styleName[0], $
            APPLY=overplot ? 1 : (idTool ? 2 : 3), $
            UPDATE_CURRENT=~overplot
        void = oStyleOp->DoAction(oTool, /NO_TRANSACT)
        if (showUI) then $
            oStyleOp->SetProperty, /SHOW_EXECUTION_UI
    endif

    ; Re-enable tool updates. This will cause a refresh.
    if (reEnableUpdates) then begin
        oTool->EnableUpdates
        ; If we have an empty tool then we need to manually update menus.
        if (N_ELEMENTS(initial_data) eq 0) then oTool->UpdateAvailability
        ; Process the initial iTool expose event.
        if ((WIDGET_INFO(/MANAGED))[0] gt 0) then void = WIDGET_EVENT(/NOWAIT)
        ; Ensure that we are indeed the current tool.
        if (~idTool) then begin
          oSystem->SetCurrentTool, oTool->GetFullIdentifier()
        endif
    endif

    if (Keyword_Set(fitToView)) then begin
        oDesc = oTool->GetByIdentifier('Operations/Window/FitToView')
        oAction = Obj_Valid(oDesc) ? oDesc->GetObjectInstance() : Obj_New()
        if (Obj_Valid(oAction)) then begin
            oCmd = oAction->DoAction(oTool)
            Obj_Destroy, oCmd
        endif
    endif

    if (Keyword_Set(viewZoom)) then begin
        oDesc = oTool->GetByIdentifier('Toolbar/View/ViewZoom')
        oAction = Obj_Valid(oDesc) ? oDesc->GetObjectInstance() : Obj_New()
        if (Obj_Valid(oAction)) then begin
            ; Convert from zoom fraction to percent zoom.
            oCmd = oAction->DoAction(oTool, OPTION=Double(viewZoom)*100)
            Obj_Destroy, oCmd
        endif
    endif

   if n_elements(macroNames) gt 0 then begin
        oDesc = oTool->GetByIdentifier('/Registry/MacroTools/Run Macro')
        oOpRunMacro = oDesc->GetObjectInstance()
        oOpRunMacro->GetProperty, $
            SHOW_EXECUTION_UI=showUIOrig, $
            MACRO_NAME=macroNameOrig
        ; Hide macro controls if using an IDLgrBuffer user interface.
        hideControls = N_ELEMENTS(userInterface) eq 1 && $
            STRCMP(userInterface, 'NONE', /FOLD)
        for i=0, n_elements(macroNames)-1 do begin
            oOpRunMacro->SetProperty, $
                SHOW_EXECUTION_UI=0, $
                MACRO_NAME=macroNames[i]
            oCmd = oOpRunMacro->DoAction(oTool, HIDE_CONTROLS=hideControls)
            ; no undo
            obj_destroy, oCmd
        endfor
        ; restore original values on the singleton
        oOpRunMacro->SetProperty, $
            SHOW_EXECUTION_UI=showUIOrig, $
            MACRO_NAME=macroNameOrig
   endif

    if (ISA(oTitle) && ISA(titleLoc)) then begin
      if (oDS->Is3D()) then begin
        oDS->WindowToVis, titleLoc, newLoc
      endif else begin
        newLoc = iConvertCoord(titleLoc, /DEVICE, /TO_DATA, TARGET=oDS)
      endelse
      tr[3,0:2] = newLoc
      oTitle->SetProperty, TRANSFORM=tr
    endif

   if (MAX(OBJ_VALID(oCmd)) gt 0) then $
        oTool->CommitActions

   oTool->RefreshThumbnail
   
   return, idTool ? idTool : oTool->GetFullIdentifier()
end
