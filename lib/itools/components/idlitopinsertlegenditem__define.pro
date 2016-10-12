; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertlegenditem__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert legend item operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitopInsertLegendItem::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    ; don't init by type.  allow creation of legend if no items are
    ; selected.  filter by vis type below
    return, self->IDLitOperation::Init( $
        TYPES=['DATASPACE_2D','DATASPACE_3D', $
            'DATASPACE_ROOT_2D','DATASPACE_ROOT_3D', $
            'PLOT','PLOT3D','SURFACE','CONTOUR'], $
            _EXTRA=_extra)
end
FUNCTION IDLitopInsertLegendItem::RecordFinalValues, oCmdSet, oLegend, $
    oVisTargets, oLegendItems

    compile_opt idl2, hidden

    oTool = self -> GetTool()
    FOR i = 0, N_ELEMENTS(oLegendItems)-1 DO BEGIN
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oLegendItems[i]->GetFullIdentifier())

        ; Add the other ids to the command object
        void = oCmd -> AddItem('LEGEND_IDENTIFIER', $
            oLegend->GetFullIdentifier())
        void = oCmd -> AddItem('VISTARGET_IDENTIFIER', $
            oVisTargets[i]->GetFullIdentifier())

        ; Add the command object to the command set
        oCmdSet -> Add, oCmd
    ENDFOR

    RETURN, 1

END


FUNCTION IDLitopInsertLegendItem::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    ; Retrieve the IDLitCommand objects stored in the
    ; command set object.
    oCmds = oCommandSet -> Get(/ALL, COUNT = nObjs)

    ; Get a reference to the iTool object.
    oTool = self -> GetTool()

    ; Loop through the IDLitCommand objects and remove the
    ; legend items.
    FOR i = 0, nObjs-1 DO BEGIN
        oCmds[i] -> GetProperty, TARGET_IDENTIFIER = idTarget
        oTarget = oTool -> GetByIdentifier(idTarget)

        IF (oCmds[i] -> GetItem('LEGEND_IDENTIFIER', idLegend) EQ 1) THEN begin
            oLegend = oTool -> GetByIdentifier(idLegend)
            if obj_valid(oTarget) && obj_valid(oLegend) then begin
                oLegend->Remove, oTarget
                obj_destroy, oTarget
            endif
        endif
    ENDFOR

END

FUNCTION IDLitopInsertLegendItem::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    ; Retrieve the IDLitCommand objects stored in the
    ; command set object.
    oCmds = oCommandSet -> Get(/ALL, COUNT = nObjs)

    ; Get a reference to the iTool object.
    oTool = self -> GetTool()

    ; Loop through the IDLitCommand objects and re-create the
    ; legend items.
    FOR i = 0, nObjs-1 DO BEGIN
        oCmds[i] -> GetProperty, TARGET_IDENTIFIER = idTarget
        oTarget = oTool -> GetByIdentifier(idTarget)

        IF (oCmds[i] -> GetItem('LEGEND_IDENTIFIER', idLegend) EQ 1) && $
            (oCmds[i] -> GetItem('VISTARGET_IDENTIFIER', idVisTarget) EQ 1) THEN begin

            oLegend = oTool -> GetByIdentifier(idLegend)
            oVisTarget = oTool -> GetByIdentifier(idVisTarget)
            if obj_valid(oLegend) && obj_valid(oVisTarget) then $
                oLegend->AddToLegend, oVisTarget
        endif
    ENDFOR
END

;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertLegendItem::DoAction, oTool, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTarg)

    ; We need the window and view in some conditionals
    ; and to redraws after the insert operation
    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
      return, OBJ_NEW()
    oView = oWindow->GetCurrentView()

    if( (nTarg eq  0) or $
    ((nTarg eq 1) AND $
         (OBJ_ISA(oTargets[0], 'IDLitVisIDataSpace')))) then begin
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
        oTargets = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
        if (count eq 0) then begin
            self->ErrorMessage, $
              [IDLitLangCatQuery('Error:InsertLegend:CannotFind')], $
                severity=0, $
              TITLE=IDLitLangCatQuery('Error:InsertLegendItem:Title')
            return, OBJ_NEW()
        endif
    endif

    ; filter to acceptable visualizations
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if ((OBJ_ISA(oTargets[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisPlot3D')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisContour')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisSurface'))) then begin
                oVisTargets = (N_ELEMENTS(oVisTargets) gt 0) ? $
                    [oVisTargets, oTargets[i]] : [oTargets[i]]
        endif

        ; if we get a legend or legend item in the selection,
        ; hang on to it as it is needed if there are more than
        ; one existing legends
        if (OBJ_ISA(oTargets[i], 'IDLitVisLegend')) then begin
            oLegendsSelected = (N_ELEMENTS(oLegendsSelected) gt 0) ? $
                [oLegendsSelected, oTargets[i]] : [oTargets[i]]
        endif
        if (OBJ_ISA(oTargets[i], 'IDLitVisLegendContourLevelItem')) then begin
            oTargets[i]->GetProperty, PARENT=oParentContourItem
            ; use the next block to get to the actual parent legend
            oTargets[i] = oParentContourItem
        endif
        if (OBJ_ISA(oTargets[i], 'IDLitVisLegendItem')) then begin
            oTargets[i]->GetProperty, PARENT=oParentLegend
            oLegendsSelected = (N_ELEMENTS(oLegendsSelected) gt 0) ? $
                [oLegendsSelected, oParentLegend] : [oParentLegend]
        endif
    endfor

    if (N_ELEMENTS(oVisTargets) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:InsertLegend:NotSelected')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:InsertLegendItem:Title')
        return, OBJ_NEW()
    endif

    ; get the existing legend(s)
    id = oView->GetFullIdentifier()+"/ANNOTATION LAYER"
    layerAnnotation = oTool->GetByIdentifier(id)
    annotations =  layerAnnotation->Get(/ALL, COUNT=nAnnotations)
    for i=0, nAnnotations-1 do begin
        if (OBJ_ISA(annotations[i], "IDLITVISLEGEND")) then begin
            oLegendsExisting = (N_ELEMENTS(oLegendsExisting) gt 0) ? $
                [oLegendsExisting, annotations[i]] : [annotations[i]]
        endif
    endfor

    ; need to end up with one legend as a destination
    ; if multiple legends exist, user must include ONE legend in selection
    ; if there is only one legend, use it and don't complain if it was
    ; in the selection or not.
    nLegendsExisting = N_ELEMENTS(oLegendsExisting)
    nLegendsSelected = N_ELEMENTS(oLegendsSelected)
    if (nLegendsExisting gt 1) then begin
        if ((nLegendsSelected eq 0) || (nLegendsSelected gt 1)) then begin
            msg = [IDLitLangCatQuery('Error:InsertLegendItem:Text1') $
          + strtrim(nLegendsSelected, 2) $
          + IDLitLangCatQuery('Error:InsertLegendItem:Text2'), $
            IDLitLangCatQuery('Error:BlankLine'), $
            IDLitLangCatQuery('Error:InsertLegendItem:Text3'), $
            IDLitLangCatQuery('Error:InsertLegendItem:Text4')]
            self->ErrorMessage, $
              msg, $
              severity=0, $
              TITLE=IDLitLangCatQuery('Error:InsertLegendItem:Title')
            return, OBJ_NEW()
        endif else begin
            oLegend = oLegendsSelected[0]
        endelse
    endif else begin
        ; have to have at least one to even have operation enabled
        ; so we can count on this one existing
        oLegend = oLegendsExisting[0]
    endelse

    ; filter out targets already represented in legend
    oLegendItems = oLegend->Get(/ALL, COUNT=count)
    for i=0, N_ELEMENTS(oVisTargets)-1 do begin
        targetRepresented = 0
        for j=0, count-1 do begin
            if ~OBJ_ISA(oLegendItems[j], 'IDLitVisLegendItem') then begin
                ; we don't want to look at the other parts of the legend
                ; such as the polygon, text
                continue
            endif
            if (oLegendItems[j]->GetVis() eq oVisTargets[i]) then begin
                targetRepresented = 1
                break
            endif
        endfor
        if ~targetRepresented then begin
            oVisTargetsNew = (N_ELEMENTS(oVisTargetsNew) gt 0) ? $
                [oVisTargetsNew, oVisTargets[i]] : [oVisTargets[i]]
        endif
    endfor

    ; complain only if ALL visualizations are already represented
    ; if some are represented, go ahead and insert the others
    if (N_ELEMENTS(oVisTargetsNew) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:InsertLegendItem:Text5'), $
           IDLitLangCatQuery('Error:BlankLine'), $
           IDLitLangCatQuery('Error:InsertLegendItem:Text6')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:InsertLegendItem:Title')
        return, OBJ_NEW()
    endif

    if (OBJ_VALID(oLegend)) then begin
        oLegend->AddToLegend, oVisTargetsNew, oNewLegendItems
        ; Update the graphics hierarchy.
        oTool->RefreshCurrentWindow
    endif

    ; Create command set.
    oCmdSet = OBJ_NEW('IDLitCommandSet', $
        NAME='Insert Legend Item', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier())

    ; Record final values for undo/redo.
    iStatus = self->RecordFinalValues( oCmdSet, oLegend, $
        oVisTargetsNew, oNewLegendItems)
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    return, oCmdSet
end

;-------------------------------------------------------------------------
; IDLitopInsertLegendItem::QueryAvailability
;
; Purpose:
;   This function method determines whether this object is applicable
;   for the given data and/or visualization types for the given tool.
;
; Return Value:
;   This function returns a 1 if the object is applicable for
;   the selected items, or a 0 otherwise.
;
; Parameters:
;   oTool - A reference to the tool object for which this query is
;     being issued.
;
;   selTypes - A vector of strings representing the visualization
;     and/or data types of the selected items.
;
; Keywords:
;   None
;
function IDLitopInsertLegendItem::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    if (~Obj_Valid(oTool)) then return, 0
    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then return, 0

    ; First see if we have any legends to insert into.
    oWin = oTool->GetCurrentWindow()
    if (~Obj_Valid(oWin)) then return, 0
    oView = oWin->GetCurrentView()
    if (~Obj_Valid(oView)) then return, 0
    oAnnotLayer = oView->GetByIdentifier("ANNOTATION LAYER")
    if (~Obj_Valid(oAnnotLayer)) then return, 0
    void =  oAnnotLayer->Get(/ALL, ISA="IDLITVISLEGEND", COUNT=nLegends)
    if (nLegends eq 0) then return, 0

    ; See if any of my selected items can be inserted into a legend
    allowInsertLegendItem = 0b
    for i=0,nSelVis-1 do begin
        ; It's ok if there are some selected items that legend does not
        ; support as these will be filtered out in the insert op.
        if ((OBJ_ISA(oSelVis[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oSelVis[i], 'IDLitVisPlot3D')) || $
            (OBJ_ISA(oSelVis[i], 'IDLitVisContour')) || $
            (OBJ_ISA(oSelVis[i], 'IDLitVisSurface'))) then begin
            allowInsertLegendItem = 1b
            break
        endif
    endfor

    return, allowInsertLegendItem
end

;-------------------------------------------------------------------------
pro IDLitopInsertLegendItem__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertLegendItem, $
        inherits IDLitOperation, $
        _oLegend: obj_new() $ ; existing legend
        }

end

