; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/_idlitlayoutmanager__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; Purpose:
;    The _IDLitLayoutManager class represents the view layout of a scene.
;
; Written by: CT, May 2002
;


;----------------------------------------------------------------------------
function _IDLitLayoutManager::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    self._oLayouts = OBJ_NEW('IDL_Container')

    ; First layout manager is the default.
    self._layoutIndex = 0

    self->RegisterProperty, 'LAYOUT_INDEX', /HIDE, $
        NAME='Layout', $
        DESCRIPTION='Layout name', $
        ENUMLIST='', /ADVANCED_ONLY

    self->RegisterProperty, 'VIEW_COLUMNS', /INTEGER, /HIDE, $
        NAME='Grid columns', $
        DESCRIPTION='Number of view columns', $
        VALID_RANGE=[1, 2147483646], /ADVANCED_ONLY

    self->RegisterProperty, 'VIEW_ROWS', /INTEGER, /HIDE, $
        NAME='Grid rows', $
        DESCRIPTION='Number of view rows', $
        VALID_RANGE=[1, 2147483646], /ADVANCED_ONLY

    RETURN, 1
end


;----------------------------------------------------------------------------
; Purpose:
;    Performs all cleanup for an _IDLitLayoutManager object.
;
pro _IDLitLayoutManager::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oLayouts

end


;----------------------------------------------------------------------------
; Purpose:
;   Create a new layout object and register it with the layout manager.
;
; Arguments:
;   Classname: The classname of the new layout.
;
; Keywords:
;
pro _IDLitLayoutManager::RegisterLayout, classname, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Create the new layout object (pass thru properties).
    oLayout = OBJ_NEW(classname, _EXTRA=_extra)

    if (~OBJ_VALID(oLayout)) then $
        return

    oLayout->GetProperty, NAME=name
    self->GetPropertyAttribute, 'LAYOUT_INDEX', ENUMLIST=enumlist
    if n_elements(enumlist) eq 1 && enumlist eq '' then $
        self->SetPropertyAttribute, 'LAYOUT_INDEX', ENUMLIST=name $
    else $
        self->SetPropertyAttribute, 'LAYOUT_INDEX', ENUMLIST=[enumlist, name]

    ; Add to the layout manager.
    self._oLayouts->Add, oLayout

end


;----------------------------------------------------------------------------
; Purpose:
;   Return object references to registered layouts.
;
; Arguments:
;   Name: Optional argument giving the name(s) of the layout(s) to return.
;       Name is ignored if ALL or POSITION are specified.
;
; Keywords:
;   ALL: Set this keyword to return all layouts.
;
;   COUNT: Set this keyword to a named variable in which to return the
;      number of registered layouts.
;
;   POSITION: If Name is not specified, then set this keyword to the
;      zero-based index of the layout to return.
;      If Name is specified, then set this to a named variable in which
;      to return the position(s) of the requested layout(s).
;
;   If no arguments or keywords (except COUNT) are specified, then
;   the current layout is returned.
;
function _IDLitLayoutManager::GetLayout, name, $
    ALL=all, $
    COUNT=nLayouts, $
    POSITION=position

    compile_opt idl2, hidden

    ; First fill in the COUNT.
    nLayouts = self._oLayouts->Count()

    ; Done?
    if (nLayouts eq 0) then $
        return, OBJ_NEW()


    ; Return all layouts.
    if (KEYWORD_SET(all)) then $
        return, self._oLayouts->Get(/ALL)


    ; Retrieve layout by name.
    nName = N_ELEMENTS(name)
    if (nName gt 0) then begin

        names = STRUPCASE(name)
        oReturn = (nName gt 1) ? OBJARR(nName) : OBJ_NEW()
        position = (nName gt 1) ? LONARR(nName) : 0L

        ; Loop thru all registered layouts.
        for i=0,nLayouts-1 do begin

            oLayout = self._oLayouts->Get(POSITION=i)
            if (~OBJ_VALID(oLayout)) then $
                continue

            oLayout->GetProperty, NAME=layoutName
            match = (WHERE(names eq STRUPCASE(layoutName)))[0]
            if (match lt 0) then $
                continue

            ; Fill in objref and position in container.
            oReturn[match] = oLayout
            position[match] = i

            ; Have we found all matches?
            if (MIN(OBJ_VALID(oReturn)) eq 1) then $
                break
        endfor

        return, oReturn

    endif


    ; Retrieve a specific layout or the current layout.
    positionGet = (N_ELEMENTS(position) eq 1) ? $
        position[0] : self._layoutIndex
    if ((positionGet ge 0) && (positionGet lt nLayouts)) then $
        return, self._oLayouts->Get(POSITION=positionGet)


    ; If we reach here, then the supplied position was wrong.
    return, OBJ_NEW()

end


;---------------------------------------------------------------------------
; Purpose:
;   Create a new view and add it.
;
; Arguments:
;   None.
;
; Keywords:
;  _NO_CURRENT: If set, do not make the newly added view to be current.
;
pro _IDLitLayoutManager::CreateView, SET_CURRENT=setCurrent

    compile_opt idl2, hidden

    ncontained = self->Count()

    ; Create the new view and add it.
    oNewView = OBJ_NEW('IDLitgrView', NAME='View_'+STRTRIM(ncontained+1,2), $
                      TOOL=self->GetTool())

    ; This will cause ::UpdateView to be called for this view.
    ; This will also verify that the NAME is unique.
    self->Add, oNewView, SET_CURRENT=setCurrent
    self->UpdateView, oNewView

end


;---------------------------------------------------------------------------
; _IDLitLayoutManager::UpdateView
;
; Purpose:
;   Used to update the location and dimensions of view(s).
;
pro _IDLitLayoutManager::UpdateView, oView

    compile_opt idl2, hidden

    ; Current layout.
    oCurrentLayout = self._oLayouts->Get(POSITION=self._layoutIndex)

    ; Find the position of each view in the layout and update its viewport.
    destDims = self->GetDimensions(VIRTUAL_DIMENSIONS=virtualDestDims)
    for i=0, N_ELEMENTS(oView)-1 do begin
        if (not OBJ_VALID(oView[i])) then $
            continue
        if self->IsContained(oView[i], POSITION=position) then begin
            viewport = (OBJ_VALID(oCurrentLayout) ? $
                oCurrentLayout->GetViewport(position, virtualDestDims) : $
                [0,0,virtualDestDims[0],virtualDestDims[1]])

            ; Set the viewport locations, dimensions.
            ; Note: when a viewport size changes due to a layout change,
            ; screen sizes (which are used to honor the zoomOnResize=0
            ; setting) are reinitialized for the new viewport.
            oView[i]->SetViewport, viewport[0:1], viewport[2:3], $
                /RESET_SCREEN_SIZES
        endif
    endfor

end


;----------------------------------------------------------------------------
pro _IDLitLayoutManager::_UpdateLayout, VIEW_GRID=viewGrid

    compile_opt idl2, hidden

    ; Retrieve the new layout manager.
    oCurrentLayout = self._oLayouts->Get(POSITION=self._layoutIndex)
    oCurrentLayout->GetProperty, $
        GRIDDED=gridded, $
        MAXCOUNT=nlayout

    ; See if the current number of views agrees with the layout.
    ncontained = self->Count()

    ; Update all views up to the maximum for the layout.
    if ((nlayout gt 0) && (ncontained gt 0)) then $
        self->UpdateView, self->Get(POSITION=LINDGEN(nlayout<ncontained))

    ; Create the new views and add them, but only if VIEW_GRID
    ; was passed in (usually from the command line).
    ; Don't bother to make the new views current (except the first).
    if (ncontained lt nlayout && N_ELEMENTS(viewGrid) eq 2) then begin
        for i=ncontained,nlayout-1 do begin
            self->_IDLitLayoutManager::CreateView, $
                SET_CURRENT=(ncontained eq 0)
        endfor
    endif


    ; Update the selection visual in case we switched from gridded
    ; to freeform or vice versa.
    oCurrentView = self->GetCurrentView()
    if (self->IsContained(oCurrentView)) then begin
        oCurrentView->SetSelectVisual
    endif else begin
        ; If our current view is no longer contained,
        ; switch current view to the first contained view.
        oView0 = self->Get()
        if (OBJ_VALID(oView0)) then $
            self->SetCurrentView, oView0
    endelse

    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oTool->RefreshCurrentWindow

        id = oTool->GetFullIdentifier()+"/OPERATIONS/INSERT/VIEW"
        oTool->DoOnNotify, id, "SENSITIVE", ~gridded
    endif

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
pro _IDLitLayoutManager::GetProperty, $
    LAYOUT_INDEX=layoutIndex, $
    VIEW_COLUMNS=viewColumns, $
    VIEW_ROWS=viewRows, $
    VIEW_GRID=viewGrid

    compile_opt idl2, hidden

    if (ARG_PRESENT(layoutIndex)) then $
        layoutIndex = self._layoutIndex

    if (ARG_PRESENT(viewGrid) || $
        ARG_PRESENT(viewColumns) || ARG_PRESENT(viewRows)) then begin
        oGrid = self->GetLayout('Gridded', POSITION=gridPosition)
        ; If no one has registered the gridded, do it ourself.
        if (OBJ_VALID(oGrid)) then begin
            oGrid->GetProperty, COLUMNS=viewColumns, ROWS=viewRows
        endif else begin
            viewColumns = 0
            viewRows = 0
        endelse
        viewGrid = [viewColumns, viewRows]
    endif

end




;----------------------------------------------------------------------------
pro _IDLitLayoutManager::SetProperty, $
    LAYOUT_INDEX=layoutIndex, $
    VIEW_COLUMNS=viewColumns, $
    VIEW_ROWS=viewRows, $
    VIEW_GRID=viewGrid, $
    VIEW_NEXT=viewNext, $
    VIEW_NUMBER=viewNumber


    compile_opt idl2, hidden

    updateLayout = 0

    ; Typically, VIEW_GRID will only be passed in once from
    ; the command line. But this should work whenever it is called.
    if ((N_ELEMENTS(viewGrid) eq 2) || $
        N_ELEMENTS(viewColumns) || N_ELEMENTS(viewRows)) then begin

        oGrid = self->GetLayout('Gridded', POSITION=gridPosition)

        ; If no one has registered the gridded, do it ourself.
        if (~OBJ_VALID(oGrid)) then begin
            self->RegisterLayout, 'IDLitLayoutGrid', NAME='Gridded'
            oGrid = self->GetLayout('Gridded', POSITION=gridPosition)
        endif

        if (OBJ_VALID(oGrid)) then begin  ; Sanity check
            if (N_ELEMENTS(viewGrid) eq 2) then begin
                viewColumns = viewGrid[0] > 1
                viewRows = viewGrid[1] > 1
            endif
            oGrid->GetProperty, COLUMNS=oldViewColumns, ROWS=oldViewRows
            if (N_ELEMENTS(viewColumns) && viewColumns ne oldViewColumns) || $
                (N_ELEMENTS(viewRows) && viewRows ne oldViewRows) then begin
                oGrid->SetProperty, COLUMNS=viewColumns, ROWS=viewRows
                updateLayout = 1
            endif
        endif

    endif


    if (N_ELEMENTS(layoutIndex) && (layoutIndex ge 0) && $
        (layoutIndex ne self._layoutIndex) && $
        (layoutIndex lt self._oLayouts->Count())) then begin
        self._layoutIndex = layoutIndex
        updateLayout = 1
    endif


    if (KEYWORD_SET(viewNext)) then begin
        nView = self->Count()
        oCurrentView = self->GetCurrentView()
        if (self->IsContained(oCurrentView, POSITION=iCurrent)) then $
            viewNumber = ((iCurrent + 1) mod nView) + 1
    endif


    if (N_ELEMENTS(viewNumber) gt 0) then begin
        nView = self->Count()
        if ((viewNumber ge 1) && (viewNumber le nView)) then $
            self->SetCurrentView, self->Get(POSITION=viewNumber-1)
    endif

    if (updateLayout) then $
        self->_UpdateLayout, VIEW_GRID=viewGrid
end


;----------------------------------------------------------------------------
; Purpose:
;   Edit user-defined properties.
;   Called automatically from the Property Sheet.
;
; Result:
;   Returns 1 for success, 0 for failure.
;
; Arguments:
;   Tool: Objref for the tool.
;
;   PropertyIdentifier: Property name.
;
; Keywords:
;   None.
;
function _IDLitLayoutManager::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

        'LAYOUT': return, oTool->DoUIService('WindowLayout', oTool)

        else:

    endcase

    return, 0
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; _IDLitLayoutManager__Define
;
; PURPOSE:
;    Defines the object structure for an _IDLitLayoutManager object.
;
;-
pro _IDLitLayoutManager__define

    compile_opt idl2, hidden

    struct = {_IDLitLayoutManager, $
        _oLayouts: OBJ_NEW(), $
        _layoutIndex: 0}
end

