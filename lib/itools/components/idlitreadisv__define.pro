; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadisv__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadISV class.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadISV object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitReadISV::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if( self->IDLitReader::Init("isv",$
        NAME="iTools State", $
        DESCRIPTION="iTools State (isv)", $
        ICON='save', $
        _EXTRA=_extra) ne 1)then $
      return, 0

    return,1
end


;---------------------------------------------------------------------------
; Purpose:
;   Read the image file and return the data in the data object.
;
;   Returns 1 for success, 0 otherwise.
;
; Arguments:
;   None.
;
; Keywords:
;   CREATE_TOOL: Undocumented keyword. Restores the isv file
;       and creates a new tool using the stored toolname and state.
;
function IDLitReadISV::GetData, oVoid, $
    CREATE_TOOL=createTool

    compile_opt idl2, hidden

    filename = self->GetFilename()

    if (~KEYWORD_SET(createTool)) then begin
        oTool = self->GetTool()
        if (~OBJ_VALID(oTool)) then $
            return, 0     ; Error

        ; If our current state has been modified, prompt to save first.
        ; If user hits cancel (or an error occurs), then do not open.
        success = oTool->_CheckForUnsaved()
        if (success ne 1) then $
            return, success
    endif


    ; Here we go!
    RESTORE, filename, RESTORED_OBJECTS=oObj, /RELAXED_STRUCTURE_ASSIGNMENT

    ; Ensure all component objects are updated for the current release.
    nObjs = N_ELEMENTS(oObj)
    nViews_60 = 0
    for i=0,nObjs-1 do begin
        if (OBJ_ISA(oObj[i], 'IDLitComponent')) then begin
            ; Capture all views whose component version is IDL 6.0.
            if (OBJ_ISA(oObj[i], 'IDLitgrView')) then begin
                oObj[i]->IDLitComponent::GetProperty, $
                    COMPONENT_VERSION=viewComponentVersion
                if (viewComponentVersion lt 610) then begin
                    oViews_60 = (nViews_60 gt 0) ? $
                        [oViews_60, oObj[i]] : oObj[i]
                    nViews_60++
                endif
            endif
            oObj[i]->Restore
            oObj[i]->UpdateComponentVersion
        endif
    endfor

    ; Do we need to create a new tool?
    if (KEYWORD_SET(createTool)) then begin
        if (N_ELEMENTS(toolName) lt 1) then $
            MESSAGE, IDLitLangCatQuery('Message:Framework:ToolNoExist')
        oSystem = _IDLitSys_GetSystem()
        ; Create the new tool using the original widget dimensions.
        oTool = oSystem->CreateTool(toolName, DIMENSIONS=dimensions, $
            VIRTUAL_DIMENSIONS=virtualDimensions)
        if (~OBJ_VALID(oTool)) then $
            MESSAGE, $
                IDLitLangCatQuery('Message:Framework:CannotCreateTool') + $
                toolName
        self->_SetTool, oTool
    endif

    ; Set the filename. This will also update the title bar.
    oTool->SetProperty, TOOL_FILENAME=filename

    ; Hook the tool objref back up to all the objects.
    imsg = WHERE(OBJ_ISA(oObj, 'IDLitIMessaging'), nmsg)
    for i=0,nmsg-1 do begin
        oObj[imsg[i]]->_SetTool, oTool
    endfor

    ; Find all visualizations with parameters.
    iparam = WHERE(OBJ_ISA(oObj, 'IDLitParameter'), nparam)
    for i=0,nparam-1 do begin
        ; Retrieve the data objects from the visualizations.
        oDataItems = oObj[iparam[i]]->GetParameter(/ALL, COUNT=ndata)
        for j=0,ndata-1 do begin
            oData = oDataItems[j]
            if (~OBJ_VALID(oData)) then $
                continue
            ; Find the top-level data container for each data item,
            ; so we can add the containers to the Data Manager.
            oData->IDLitComponent::GetProperty, _PARENT=oParent
            while (OBJ_ISA(oParent, 'IDLitDataContainer')) do begin
                oData = oParent
                oData->IDLitComponent::GetProperty, _PARENT=oParent
            endwhile
            oAllData = (N_ELEMENTS(oAllData) gt 0) ? $
                [oAllData, oData] : oData
        endfor
    endfor

    ; Add all of the new parameters to the data manager.
    if (N_ELEMENTS(oAllData) gt 0) then begin
        ; Avoid duplicate data items/containers in the Manager.
        oAllData = oAllData[UNIQ(oAllData, SORT(oAllData))]
        ; Assume we can safely add them all at once.
        oTool->AddByIdentifier, "/Data Manager", oAllData
    endif

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, 0   ; Error

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; Just for sanity, clear out the selection list
    ; and reset the zoom.
    oWin->ClearSelections
    oWin->SetProperty, CURRENT_ZOOM=1

    ; Reset the Undo/Redo buffer since it is now invalid.
    oBuffer = oTool->_GetCommandBuffer()
    oBuffer->ResetBuffer

    ; Set this scene in the tool
    oTool->Add, oScene

    oPrintOperation = oTool->GetByIdentifier('Operations/File/Print')
    if (OBJ_VALID(oPrintOperation)) then begin
        oPrintOperation->SetProperty, PRINT_ORIENTATION=print_orientation, $
            PRINT_XMARGIN=print_xmargin, PRINT_YMARGIN=print_ymargin, $
            PRINT_WIDTH=print_width, PRINT_HEIGHT=print_height, $
            PRINT_UNITS=print_units, PRINT_CENTER=print_center
    endif

    ; Hook up our new scene and restore some window properties.
    ; If AUTO_RESIZE wasn't defined (pre-IDL62) then turn it on by default.
    oWin->SetProperty, $
        AUTO_RESIZE=(N_ELEMENTS(autoResize) gt 0) ? autoResize : 1b, $
        MINIMUM_VIRTUAL_DIMENSIONS=minVirtualDims, $
        VIRTUAL_DIMENSIONS=virtualDimensions, $
        ZOOM_ON_RESIZE=zoomOnResize

    ; Restore the grid # of columns & rows. We may not actually
    ; be using gridded layout, but we need to restore the grid size.
    oGrid = oWin->GetLayout('Gridded', POSITION=gridPosition)
    if (OBJ_VALID(oGrid)) then $
        oGrid->SetProperty, COLUMNS=viewGrid[0] > 1, ROWS=viewGrid[1] > 1

    ; Now set the layout index.
    oWin->SetProperty, LAYOUT_INDEX=layoutIndex

    ; Reset our scrollbar location.
    oWin->SetProperty, VISIBLE_LOCATION=visibleLocation

    ; Call our OnScroll method to force a Set/CropViewPort
    ; on all of our new views. Otherwise, if the Window had scrollbars
    ; when the state was saved, the views will still be cropped
    ; to those scroll positions.
    oWin->OnScroll, 0, 0

    ; "currentZoom" should be in our save file.
    oWin->SetProperty, CURRENT_ZOOM=currentZoom

    ; For IDL 6.0 views, a transition needs to be made from old
    ; WINDOW_ZOOM to new margins.  Force this by simulating a viewport
    ; change.
    for i=0,nViews_60-1 do begin
        normVirtualDims = oViews_60[i]->GetViewport(LOCATION=normVirtualLoc, $
            /VIRTUAL, UNITS=3)
        oViews_60[i]->SetViewport, normVirtualLoc, normVirtualDims, UNITS=3, $
            /FORCE_UPDATE
    endfor

    IF (~previouslyDisabled) THEN $
      oTool->EnableUpdates


    ; Even though we are successful, return -1 (Cancel) since
    ; we don't have any data objects to return.
    return, -1

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
; Class definition for the IDLitReadISV class
;
pro IDLitReadISV__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadISV, $
          inherits IDLitReader $
         }
end
