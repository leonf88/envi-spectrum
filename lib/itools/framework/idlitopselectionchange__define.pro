; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopselectionchange__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSelectionChange
;
; PURPOSE:
;   This file implements the operation that will select all visualizations
;   in the current windows current view.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopSelectionChange::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopSelectionChange::Init
;   IDLitopSelectionChange::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopSelectionChange::Init
;;
;; Purpose:
;; The constructor of the IDLitopSelectionChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSelectionChange::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Selection Change", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=1

    self->RegisterProperty, 'SELECTION_TYPE', $
        NAME='Selection type', $
        ENUMLIST=[ $
            'Existing Selection', $
            'Position in Container', $
            'All in Container', $
            'Next in Container', $
            'Previous in Container', $
            'By Identifier', $
            'All Items', $
            'No Items (De-select All)' $
            ], $
        DESCRIPTION='Selection Type'

    ; Register properties
    self->RegisterProperty, 'MODE', $
        NAME='Selection mode', $
        ENUMLIST=['New Selection', 'Add to Selection', 'Remove from Selection'], $
        DESCRIPTION='Selection Mode'

    self->RegisterProperty, 'CONTAINER', /STRING, $
        NAME='Container', $
        DESCRIPTION='Selection Container'

    self->RegisterProperty, 'ITEM_ID', /STRING, $
        NAME='Item identifier', $
        DESCRIPTION='Item Identifier'

    self->RegisterProperty, 'POSITION', /INTEGER, $
        NAME='Position in container', $
        Description='Position of item to select'

    return, 1

end



;-------------------------------------------------------------------------
; IDLitopSelectionChange::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopSelectionChange::GetProperty,        $
    CONTAINER=container,   $
    ITEM_ID=itemID, $
    MODE=mode,   $
    POSITION=position,   $
    SELECTION_TYPE=selectionType,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(container)) then $
        container = self._container

    if (ARG_PRESENT(itemID)) then $
        itemID = self._itemID

    if (ARG_PRESENT(mode)) then $
        mode = self._mode

    if (ARG_PRESENT(position)) then $
        position = self._position

    if (arg_present(selectionType)) then $
        selectionType = self._selectionType

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopSelectionChange::ManagePropertySensitivity
;
; Purpose:
;
; Parameters: selectionType
; None.
;
pro IDLitopSelectionChange::ManagePropertySensitivity, selectionType

    compile_opt idl2, hidden

    switch selectionType of
    0:          ;current selection
    6:          ;all items
    7: begin    ;no items (deselect all)
        self->SetPropertyAttribute, $
            ['MODE', 'POSITION', 'CONTAINER', 'ITEM_ID'], SENSITIVE=0
    break
    end
    1: begin    ;position in container
        self->SetPropertyAttribute, $
            ['ITEM_ID'], SENSITIVE=0
        self->SetPropertyAttribute, $
            ['MODE', 'CONTAINER', 'POSITION'], SENSITIVE=1
    break
    end
    2:  ;all in container
    3:  ;next in container
    4: begin    ;previous in container
        self->SetPropertyAttribute, $
            ['POSITION', 'ITEM_ID'], SENSITIVE=0
        self->SetPropertyAttribute, $
            ['MODE', 'CONTAINER'], SENSITIVE=1
    break
    end
    5: begin    ;identifier
        self->SetPropertyAttribute, $
            ['POSITION'], SENSITIVE=0
        self->SetPropertyAttribute, $
            ['MODE', 'CONTAINER', 'ITEM_ID'], SENSITIVE=1
    break
    end
    endswitch


end



;-------------------------------------------------------------------------
; IDLitopSelectionChange::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopSelectionChange::SetProperty,      $
    CONTAINER=container,   $
    ITEM_ID=itemID, $
    MODE=mode,   $
    POSITION=position,   $
    SELECTION_TYPE=selectionType,   $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(container) ne 0) then begin
        self._container = container
    endif

    if (N_ELEMENTS(itemID) ne 0) then begin
        self._itemID = itemID
    endif

    if (N_ELEMENTS(mode) ne 0) then begin
        self._mode = mode
    endif

    if (N_ELEMENTS(position) ne 0) then begin
        self._position = position
    endif

    if (N_ELEMENTS(selectionType) ne 0) then begin
        self._selectionType = selectionType
        self->ManagePropertySensitivity, selectionType
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopSelectionChange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopSelectionChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopSelectionChange::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopSelectionChange::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;   Since this is not transactional, a obj null is returned.
;;
function IDLitopSelectionChange::DoAction, oTool

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ;; Get the Window
    oWin = oTool->GetCurrentWindow()
    if not obj_valid(oWin) then $
        return, obj_new()

    oView = oWin->GetCurrentView()
    if(not obj_valid(oView))then return, obj_new()

    ;; Disable tool updates during this process.
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    idTool = oTool->GetFullIdentifier()
    void = oTool->DoUIService("HourGlassCursor", self)

    switch self._selectionType of
    0: break ; current selection, no-op

    1: begin    ;position in container
        if strlen(self._container) eq 0 then goto, finish
        idContainerFull=idTool + '/' + self._container
        oContainer = oTool->GetByIdentifier(idContainerFull)
        if obj_valid(oContainer) then begin
            ; provide effective-zero-based indexing to the user by
            ; skipping privates.  Must consider only privates when
            ; setting the position in idlitsrvmacros::addselectionchange.
            oObjs = oContainer->Get(/ALL, /SKIP_PRIVATE, COUNT=count)
            if (self._position ge 0 && $
                self._position lt count) then begin
                oTemp = oObjs[self._position]
                if obj_valid(oTemp) then begin
                    oTemp->Select, $
                        ADDITIVE=(self._mode eq 1), $
                        UNSELECT=(self._mode eq 2)
                endif
            endif
        endif
    break
    end
    2: begin    ;all in container
        if strlen(self._container) eq 0 then goto, finish
        idContainerFull=idTool + '/' + self._container
        oContainer = oTool->GetByIdentifier(idContainerFull)
        if obj_valid(oContainer) then begin
            oItems = oContainer->Get(/ALL, /SKIP_PRIVATE, COUNT=count)
            for i=0, n_elements(oItems)-1 do begin
                oItems[i]->Select, $
                    ; first may be additive
                    ; succeeding must be additive
                    ADDITIVE=(i eq 0) ? self._mode eq 1 : $
                        (self._mode eq 0 || self._mode eq 1), $
                    UNSELECT=(self._mode eq 2)
            endfor
        endif
    break
    end
    3:          ;next in container
    4: begin    ;previous in container
        if strlen(self._container) eq 0 then goto, finish
        idContainerFull=idTool + '/' + self._container
        oContainer = oTool->GetByIdentifier(idContainerFull)
        if obj_valid(oContainer) then begin
            oObjs = oContainer->Get(/ALL, /SKIP_PRIVATE, COUNT=count)
            ; get position of highest selected item
            ; start at highest to leave default result at first item
            positionNonPrivate = 0
            for i=0, count-1 do begin
                if oObjs[i]->IsSelected() then begin
                    positionNonPrivate=i
                    if self._selectionType eq 4 then break  ;previous in container
                endif
            endfor
            if self._selectionType eq 3 then begin
                ; next in container
                newPos = positionNonPrivate lt count-1 ? positionNonPrivate + 1 : 0
            endif else begin
                ; previous in container
                newPos = positionNonPrivate gt 0 ? positionNonPrivate - 1 : count-1
            endelse
            ; in some cases the new item to be selected might be currently selected
            ; if selecting, clear previous selection so new selection occurs
            if self._mode eq 0 then begin
                for i=0, count-1 do begin
                    oObjs[i]->Select, /UNSELECT
                endfor
            endif

            oObjs[newPos]->Select, $
                        ADDITIVE=(self._mode eq 1), $
                        UNSELECT=(self._mode eq 2)
        endif
    break
    end
    5: begin    ;by identifier
        ; example:
;            /TOOLS/PLOT TOOL_0/WINDOW/VIEW_1/VISUALIZATION LAYER/DATA SPACE ROOT/DATA SPACE/PLOT
        ; use a relative id starting from the window
        ; and add on the tool id
        if strlen(self._container) eq 0 || $
            strlen(self._itemID) eq 0 then goto, finish
        identifier = self._container
        if strmid(identifier, 0, 1, /reverse_offset) ne '/' then $
            identifier=identifier+'/'
        identifier=idTool + '/' + identifier + self._itemID
        oTemp = oTool->GetByIdentifier(identifier)
        if obj_valid(oTemp) then begin
            oTemp->Select, $
                ADDITIVE=(self._mode eq 1), $
                UNSELECT=(self._mode eq 2)
        endif
    break
    end
    6: begin    ;all items
        dummy = oTool->DoAction('Operations/Edit/SelectAll')
    break
    end
    7: begin    ;no items (de-select all)
        oView->ClearSelections, /NO_NOTIFY
    break
    end

    else:

    endswitch


finish:
   if (~wasDisabled) then $
       oTool->EnableUpdates ;; re-enable updates.
   ;; Send our notify
   return, obj_new()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopSelectionChange__define

    compile_opt idl2, hidden

    void = {IDLitopSelectionChange, $
            inherits IDLitOperation, $
            _mode:          0L, $
            _selectionType:          0L, $
            _position:      0L, $
            _container:     '', $
            _itemID:        '' $

                        }
end

