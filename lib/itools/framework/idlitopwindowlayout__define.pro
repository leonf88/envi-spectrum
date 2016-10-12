; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopwindowlayout__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the Window Layout operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopWindowLayout::Init
;
; Purpose:
; The constructor of the IDLitopWindowLayout object.
;
; Parameters:
; None.
;
;-------------------------------------------------------------------------
function IDLitopWindowLayout::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(_EXTRA=_extra)) then $
        return, 0

    self._autoResize = 1b

    self->IDLitopWindowLayout::_RegisterProperties

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1
end


;----------------------------------------------------------------------------
pro IDLitopWindowLayout::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        self->RegisterProperty, 'VIRTUAL_WIDTH', /INTEGER, $
            NAME='Window width', $
            DESCRIPTION='Minimum canvas width in pixels'

        self->RegisterProperty, 'VIRTUAL_HEIGHT', /INTEGER, $
            NAME='Window height', $
            DESCRIPTION='Minimum canvas height in pixels'

    endif

    ; This property was added for IDL62. Add right after width & height.
    if (registerAll || updateFromVersion lt 620) then begin

        self->RegisterProperty, 'AUTO_RESIZE', /BOOLEAN, $
            NAME='Automatic window resize', $
            DESCRIPTION='Automatically change window dimensions on resize'

    endif

    if (registerAll) then begin
        oTool = self->GetTool()
        if (OBJ_VALID(oTool)) then begin
            oWin = oTool->GetCurrentWindow()
            if (OBJ_VALID(oWin)) then $
                oWin->GetPropertyAttribute, 'LAYOUT_INDEX', ENUMLIST=enumlist
        endif

        self->RegisterProperty, 'LAYOUT_INDEX', $
            NAME='Layout', $
            DESCRIPTION='Layout name', $
            ENUMLIST=(N_ELEMENTS(enumlist) gt 0) ? enumlist : ''

        self->RegisterProperty, 'VIEW_COLUMNS', /INTEGER, $
            NAME='Grid columns', $
            DESCRIPTION='Number of view columns', $
            VALID_RANGE=[1, 2147483646]

        self->RegisterProperty, 'VIEW_ROWS', /INTEGER, $
            NAME='Grid rows', $
            DESCRIPTION='Number of view rows', $
            VALID_RANGE=[1, 2147483646]

    endif

end


;----------------------------------------------------------------------------
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitopWindowLayout::Restore

    compile_opt idl2, hidden

    ; Register new properties.
    self->IDLitopWindowLayout::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    if (self.idlitcomponentversion lt 620) then $
        self._autoResize = 1b

end


;---------------------------------------------------------------------------
pro IDLitopWindowLayout::GetProperty, $
    LAYOUT_INDEX=layoutIndex, $
    LAYOUTS=oLayouts, $
    AUTO_RESIZE=autoResize, $
    N_VIEWS=nViews, $
    VIEW_COLUMNS=viewColumns, $
    VIEW_ROWS=viewRows, $
    VIRTUAL_WIDTH=virtualWidth, $
    VIRTUAL_HEIGHT=virtualHeight, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(oLayouts) then begin
        oLayouts = OBJ_VALID(self._oWindow) ? $
            self._oWindow->GetLayout(/ALL) : OBJ_NEW()
    endif

    if ARG_PRESENT(nViews) then $
        nViews = OBJ_VALID(self._oWindow) ? self._oWindow->Count() : 0

    if ARG_PRESENT(layoutIndex) then $
        layoutIndex = self._layoutIndex

    if (ARG_PRESENT(autoResize)) then $
        autoResize = self._autoResize

    if ARG_PRESENT(viewColumns) then $
        viewColumns = self._viewColumns

    if ARG_PRESENT(viewRows) then $
        viewRows = self._viewRows

    if ARG_PRESENT(virtualWidth) then $
        virtualWidth = self._virtualWidth

    if ARG_PRESENT(virtualHeight) then $
        virtualHeight = self._virtualHeight

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::GetProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
pro IDLitopWindowLayout::SetProperty, $
    LAYOUT_INDEX=layoutIndex, $
    AUTO_RESIZE=autoResize, $
    SHOW_EXECUTION_UI=showExecutionUI, $
    VIEW_COLUMNS=viewColumns, $
    VIEW_ROWS=viewRows, $
    VIRTUAL_WIDTH=virtualWidth, $
    VIRTUAL_HEIGHT=virtualHeight, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(layoutIndex) eq 1) then $
        self._layoutIndex = layoutIndex

    if (N_ELEMENTS(showExecutionUI) eq 1) then begin
        self->SetPropertyAttribute, ['LAYOUT_INDEX', $
            'VIEW_COLUMNS', 'VIEW_ROWS', 'AUTO_RESIZE'], $
            SENSITIVE=~showExecutionUI
        self->SetPropertyAttribute, ['VIRTUAL_WIDTH', 'VIRTUAL_HEIGHT'], $
            SENSITIVE=~showExecutionUI && ~self._autoResize
        self->IDLitOperation::SetProperty, SHOW_EXECUTION_UI=showExecutionUI
    endif

    if (N_ELEMENTS(viewColumns) eq 1) then $
        self._viewColumns = viewColumns

    if (N_ELEMENTS(viewRows) eq 1) then $
        self._viewRows = viewRows

    if (N_ELEMENTS(virtualWidth) eq 1) then $
        self._virtualWidth = virtualWidth

    if (N_ELEMENTS(virtualHeight) eq 1) then $
        self._virtualHeight = virtualHeight

    ; Be sure to set this after we may have changed it above.
    if (N_ELEMENTS(autoResize) eq 1) then begin
        self._autoResize = KEYWORD_SET(autoResize)
        self->SetPropertyAttribute, ['VIRTUAL_HEIGHT', 'VIRTUAL_WIDTH'], $
            SENSITIVE=~self._autoResize
    endif

    if (N_ELEMENTS(_extra) gt 0) then begin
        self->IDLitOperation::SetProperty, _EXTRA=_extra
    endif

end


;---------------------------------------------------------------------------
; IDLitopWindowLayout::DoAction
;
; Purpose:
;
; Parameters:
; None.
;
function IDLitopWindowLayout::DoAction, oTool

    compile_opt idl2, hidden

    oWin = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWin)) then $
        return, OBJ_NEW()

    self._oWindow = oWin

    ; Retrieve our SetProperty service.
    oSetProp = oTool->GetService('SET_PROPERTY')
    if (~OBJ_VALID(oSetProp)) then $
        return, OBJ_NEW()

    ; Dimensions
    oCmds = OBJ_NEW("IDLitCommandSet", $
        NAME='Window Layout', $
        OPERATION_IDENTIFIER=oSetProp->GetFullIdentifier())

    ; Record our initial view positions and sizes in case changing
    ; the layout resets some of these.
    oViews = oWin->Get(/ALL, COUNT=nViews)
    for i=0,nViews-1 do begin
        void = oSetProp->RecordInitialValues(oCmds, oViews[i], 'VIEWPORT_RECT')
    endfor

    void = oSetProp->RecordInitialValues(oCmds, oWin, 'VIRTUAL_WIDTH')
    void = oSetProp->RecordInitialValues(oCmds, oWin, 'VIRTUAL_HEIGHT')
    void = oSetProp->RecordInitialValues(oCmds, oWin, 'LAYOUT_INDEX')
    void = oSetProp->RecordInitialValues(oCmds, oWin, 'VIEW_COLUMNS')
    void = oSetProp->RecordInitialValues(oCmds, oWin, 'VIEW_ROWS')
    void = oSetProp->RecordInitialValues(oCmds, oWin, 'AUTO_RESIZE')

    ; Record our initial property values.
    oWin->GetProperty, LAYOUT_INDEX=layoutIndex, $
        AUTO_RESIZE=autoResize, $
        VIEW_COLUMNS=viewColumns, $
        VIEW_ROWS=viewRows, $
        VIRTUAL_WIDTH=virtualWidth, $
        VIRTUAL_HEIGHT=virtualHeight

    self->GetProperty, SHOW_EXECUTION_UI=showExecutionUI
    if (showExecutionUI) then begin

        self._layoutIndex = layoutIndex
        self._viewColumns = viewColumns
        self._viewRows = viewRows
        self._virtualWidth = virtualWidth
        self._virtualHeight = virtualHeight
        self._autoResize = autoResize

        ; Ask the UI service to present the dialog to the user.
        if (~oTool->DoUIService('WindowLayout', self)) then $
            goto, failed

    endif

    ; Set our new property values.
    if (self._virtualWidth ne virtualWidth || $
        self._virtualHeight ne virtualHeight) then begin
        oWin->SetProperty, VIRTUAL_WIDTH=self._virtualWidth, $
            VIRTUAL_HEIGHT=self._virtualHeight
    endif

    oWin->SetProperty, LAYOUT_INDEX=self._layoutIndex, $
        VIEW_COLUMNS=self._viewColumns, $
        VIEW_ROWS=self._viewRows, $
        AUTO_RESIZE=self._autoResize


    ; Record our final property values.
    success = oSetProp->RecordFinalValues(oCmds, /SKIP_MACROHISTORY)


    ; Retrieve our new maximum # of views.
    oLayout = oWin->GetLayout()
    oLayout->GetProperty, MAXCOUNT=newMaxLayout


    ; See if we have a maximum # of views for our new layout.
    if (newMaxLayout gt 0) then begin

        ; Retrieve our current # of views.
        oViews = oWin->Get(/ALL, COUNT=nViews)
        newViewIndex = 0
        
        if (newMaxLayout gt nViews) then begin

            ; Create the new views and add them.
            ; Don't bother to make the new views current (except the first).
            ; Retrieve our Delete operation.
            oDesc = oTool->GetByIdentifier("OPERATIONS/INSERT/VIEW")
            if (~OBJ_VALID(oDesc)) then $
                goto, failed
            oInsertOp = oDesc->GetObjectInstance()
            if (~OBJ_VALID(oInsertOp)) then $
                goto, failed

            for i=nViews,newMaxLayout-1 do begin
                oCmd1 = oInsertOp->DoAction(oTool, /NO_DRAW)
                if (OBJ_VALID(oCmd1)) then $
                    oCmds = [oCmds, oCmd1]
            endfor
            newViewIndex = nViews-1

        endif else if (newMaxLayout lt nViews) then begin

            ; If our new maximum is smaller than the current # of views,
            ; then we need to delete some views.

            ; Retrieve our Delete operation.
            oDesc = oTool->GetByIdentifier("OPERATIONS/EDIT/DELETE")
            if (~OBJ_VALID(oDesc)) then $
                goto, failed
            oDeleteOp = oDesc->GetObjectInstance()
            if (~OBJ_VALID(oDeleteOp)) then $
                goto, failed

            oCmd1 = oDeleteOp->_Delete(oTool, oViews[newMaxLayout:*])
            if (OBJ_VALID(oCmd1)) then $
                oCmds = [oCmds, oCmd1]
                
        endif
        if n_elements(oCmds) gt 1 then $
                oCmds[n_elements(oCmds)-1]->SetProperty, NAME='Window Layout'

        ; Retrieve our current views.
        oNewViews = oWin->Get(/ALL, COUNT=nViews)
        ; Unselect all
        for i=0,nViews-1 do $
          oNewViews[i]->SetSelectVisual, /UNSELECT
        ; Select a view
        oWin->SetCurrentView, oNewViews[newViewIndex] 
        oNewViews[newViewIndex]->SetSelectVisual
        oTool->RefreshCurrentWindow

    endif


    self._oWindow = OBJ_NEW()
    return, oCmds


failed:

    self._oWindow = OBJ_NEW()
    OBJ_DESTROY, oCmds
    return, OBJ_NEW()

end


;-------------------------------------------------------------------------
pro IDLitopWindowLayout__define

    compile_opt idl2, hidden
    struc = {IDLitopWindowLayout, $
        inherits IDLitOperation, $
        _oWindow: OBJ_NEW(), $
        _virtualWidth: 0, $
        _virtualHeight: 0, $
        _layoutIndex: 0, $
        _autoResize: 0b, $
        _viewColumns: 0, $
        _viewRows: 0 $
        }

end

