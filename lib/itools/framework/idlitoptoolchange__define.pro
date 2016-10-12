; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitoptoolchange__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopToolChange
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
;   See IDLitopToolChange::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopToolChange::Init
;   IDLitopToolChange::SetProperty
;
; INTERFACES:
;   IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopToolChange::Init
;;
;; Purpose:
;; The constructor of the IDLitopToolChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopToolChange::Init,  _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    ;; Just pass on up
    if (self->IDLitOperation::Init(NAME="Tool Change", $
                                       TYPES='', $
                                       _EXTRA=_extra) eq 0) then $
                                       return, 0

    self->RegisterProperty, 'CHANGE_TYPE', $
        NAME='Change type', $
        ENUMLIST=[ $
            'By Identifier', $
            'Position in Container', $
            'Next in Container', $
            'Previous in Container' $
            ], $
        DESCRIPTION='Change Type'

    self->RegisterProperty, 'TOOL_ID', /STRING, $
        NAME='Tool identifier', $
        DESCRIPTION='Tool identifier'

    self->RegisterProperty, 'POSITION', /INTEGER, $
        NAME='Position in container', $
        DESCRIPTION='Position in container'

    return, 1

end



;-------------------------------------------------------------------------
; IDLitopToolChange::ManagePropertySensitivity
;
; Purpose:
;
; Parameters: selectionType
; None.
;
pro IDLitopToolChange::ManagePropertySensitivity, changeType

    compile_opt idl2, hidden

    defaultName = 'Tool Change'
    switch changeType of
    0: begin    ;identifier
        self->SetPropertyAttribute, $
            ['POSITION'], SENSITIVE=0
        self->SetPropertyAttribute, $
            ['TOOL_ID'], SENSITIVE=1
    break
    end
    1: begin    ;position in container
        self->SetPropertyAttribute, $
            ['TOOL_ID'], SENSITIVE=0
        self->SetPropertyAttribute, $
            ['POSITION'], SENSITIVE=1
    break
    end
    2:  ;next in container
    3: begin    ;previous in container
        self->SetPropertyAttribute, $
            ['TOOL_ID', 'POSITION'], SENSITIVE=0
    break
    end
    endswitch


end



;-------------------------------------------------------------------------
; IDLitopToolChange::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopToolChange::GetProperty,        $
    CHANGE_TYPE=changeType,   $
    POSITION=position,   $
    TOOL_ID=toolID,   $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(changeType)) then $
        changeType = self._changeType

    if (ARG_PRESENT(position)) then $
        position = self._position

    if (ARG_PRESENT(toolID)) then $
        toolID = self._toolID

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end





;-------------------------------------------------------------------------
; IDLitopToolChange::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopToolChange::SetProperty,      $
    CHANGE_TYPE=changeType,   $
    POSITION=position,   $
    TOOL_ID=toolID,   $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(changeType) ne 0) then begin
        self._changeType = changeType
        self->ManagePropertySensitivity, changeType
    endif

    if (N_ELEMENTS(position) ne 0) then begin
        self._position = position
    endif

    if (N_ELEMENTS(toolID) ne 0) then begin
        self._toolID = toolID
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;-------------------------------------------------------------------------
;; IDLitopToolChange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopToolChange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopToolChange::Cleanup
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end
;;---------------------------------------------------------------------------
;; IDLitopToolChange::DoAction
;;
;; Purpose:
;;   Will cause visualizations in the current view to be
;;   selected/deselected based on the operation properties.
;;
;; Return Value:
;;   Since this is not transactional, a obj null is returned.
;;
function IDLitopToolChange::DoAction, oToolCurrent

    compile_opt hidden, idl2

    ;; Make sure we have a tool.
    if not obj_valid(oToolCurrent) then $
        return, obj_new()

    oSystem = oToolCurrent->_GetSystem()
    oToolCurrent->GetProperty, _PARENT=oToolsContainer
    void = oToolsContainer->IsContained(oToolCurrent, POSITION=currentPosition)
    toolCount = oToolsContainer->Count()

    case self._changeType of
    0: begin    ;by identifier
        if (strlen(self._toolID) gt 0) then $
            oNewTool = oSystem->GetByIdentifier("/TOOLS/"+self._toolID)
    end
    1: begin    ;position in container
        ; currently quiet if position out of range
        if self._position ge 0 && self._position lt toolCount then $
            oNewTool = oToolsContainer->Get(POSITION=self._position, COUNT=count)
    end
    2: begin    ;next in container
        ; allow wrap to beginning
        newPosition = currentPosition+1
        if newPosition ge toolCount then newPosition = 0
        oNewTool = oToolsContainer->Get(POSITION=newPosition, COUNT=count)
    end
    3: begin    ;previous in container
        ; allow wrap to end
        newPosition = currentPosition-1
        if newPosition lt 0 then newPosition = toolCount-1
        oNewTool = oToolsContainer->Get(POSITION=newPosition, COUNT=count)
    end
    endcase

    ; currently quiet if new tool not found
    if obj_valid(oNewTool) then begin
        oSystem->SetCurrentTool, oNewTool->GetFullIdentifier()
    endif

    return, obj_new()
end
;---------------------------------------------------------------------------
; Definition
;-------------------------------------------------------------------------
;; Just define the copy class

pro IDLitopToolChange__define

    compile_opt idl2, hidden

    void = {IDLitopToolChange, $
            inherits IDLitOperation, $
            _changeType: 0L     , $
            _position: ''       , $
            _toolID: ''           $
                        }
end

