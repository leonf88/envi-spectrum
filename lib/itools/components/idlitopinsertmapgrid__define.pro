; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertmapgrid__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertMapGrid
;
; PURPOSE:
;   This operation creates a map grid visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertMapGrid::Init
;
;-

;-------------------------------------------------------------------------
function IDLitopInsertMapGrid::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    return, self->IDLitOperation::Init( $
        TYPES=[""], NUMBER_DS='1', $
        _EXTRA=_extra)

end


;---------------------------------------------------------------------------
function IDLitopInsertMapGrid::RedoOperation, oCommand

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    oCommand->GetProperty, TARGET_IDENTIFIER=idGrid
    oGrid = oTool->GetByIdentifier(idGrid)
    if (~OBJ_VALID(oGrid)) then $
        return, 0

    oGrid->OnProjectionChange

    return, 1
end


;---------------------------------------------------------------------------
function IDLitopInsertMapGrid::DoAction, oTool

    compile_opt idl2, hidden

    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreate)) then $
        return, OBJ_NEW()

    oVisDesc = oTool->GetVisualization('Map Grid')

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    ; Call _Create so we don't have to worry about type matching.
    oVisCmd = oCreate->_Create(oVisDesc, ID_VISUALIZATION=idVis)

    if (~OBJ_VALID(oVisCmd[0])) then $
        goto, skipover

    oGrid = oTool->GetByIdentifier(idVis)

    ; If we have axes, then hide them. Use SET_PROPERTY service
    ; so it is undoable.
    oDataSpace = oGrid->GetDataSpace(/UNNORMALIZED)
    if (OBJ_VALID(oDataSpace)) then begin
        oAxes = oDataSpace->GetAxes(/CONTAINER)
        if (OBJ_VALID(oAxes)) then begin
            oSetProp = oTool->GetService('SET_PROPERTY')
            oCmd = oSetProp->DoAction(oTool, oAxes->GetFullIdentifier(), $
                'HIDE', 1, /SKIP_MACROHISTORY)
            if (OBJ_VALID(oCmd)) then $
                oVisCmd = [oVisCmd, oCmd]
        endif
    endif

    oCmd = OBJ_NEW('IDLitCommand', $
        NAME='Insert Map Grid', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier(), $
        TARGET_IDENTIFIER=idVis)

    oGrid->OnProjectionChange

    oVisCmd = [oVisCmd, oCmd]

skipover:

    if (~previouslyDisabled) then $
        oTool->EnableUpdates

    return, oVisCmd

end


;-------------------------------------------------------------------------
pro IDLitopInsertMapGrid__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertMapGrid, $
        inherits IDLitOperation}

end

