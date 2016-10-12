
; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitoprendervolume__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopRenderVolume
;
; PURPOSE:
;   Implements a high-quality render volume operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitOperation
;
; INTERFACES:
;   IIDLProperty
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitopRenderVolume::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitOpRenderVolume')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
function IDLitopRenderVolume::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitOperation::Init( $
        NAME="Render Volume", $
        TYPE="", $
        DESCRIPTION="", $
        /MACRO_SUPPRESSREFRESH)

    if (not success)then $
        return, 0

    return, success

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitopRenderVolume::DoAction
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    self->DoAction
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-
function IDLitopRenderVolume::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if not OBJ_VALID(oTool) then $
        return, OBJ_NEW()

    ; Get the selected objects.
    oSelVis = oTool->GetSelectedItems(count=nSel)

    ; If we have nothing selected, or just the dataspace, then retrieve
    ; all of the contained visualizations. The exact same code exists
    ; in IDLitOpInsertLegend. Perhaps we should encapsulate it in
    ; IDLitgrScene::GetSelectedItems()?
    if (nSel eq 0 || ((nSel eq 1) && $
        OBJ_ISA(oSelVis[0], 'IDLitVisIDataSpace'))) then begin
        oWin = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, OBJ_NEW()
        oView = oWin->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
        oSelVis = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
        if (count eq 0) then $
            return, OBJ_NEW()
    endif


    ; For each selected Visual
    for iSelVis=0, N_ELEMENTS(oSelVis)-1 do begin

        oSelVis1 = oSelVis[iSelVis]

        if not OBJ_VALID(oSelVis1) then $
            continue
        if not OBJ_ISA(oSelVis1, 'IDLitVisVolume') then $
            continue
        ;; Draw it!
        oSelVis1->RenderVolume

    endfor  ; selected items

    return, OBJ_NEW()   ; no undo/redo command

end


;-------------------------------------------------------------------------
pro IDLitopRenderVolume__define

    compile_opt idl2, hidden

    struc = {IDLitopRenderVolume, $
             inherits IDLitOperation    $
            }

end

