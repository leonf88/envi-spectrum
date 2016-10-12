; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertcolorbar__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertColorbar
;
; PURPOSE:
;   This operation creates a colorbar visualization for selected objects.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertColorbar::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopInsertColorbar::Init
;   IDLitopInsertColorbar::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopInsertColorbar::Init
;;
;; Purpose:
;; The constructor of the IDLitopInsertColorbar object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertColorbar::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init( $
        TYPES=["IDLPALETTE", "IDLOPACITY_TABLE"], $
        NUMBER_DS='1', $
        _EXTRA=_extra)
end


;;---------------------------------------------------------------------------
;; IDLitopInsertColorbar::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertColorbar::DoAction, oTool, $
    LOCATION=locationIn, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTargets)

    if (nTargets eq 0) then $
        return, OBJ_NEW()

    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if(not OBJ_VALID(oCreate))then $
        return, OBJ_NEW();

    oColorbarDesc = oTool->GetVisualization('COLORBAR')

    oVisCmdSet = OBJ_NEW()  ; list of undo/redo commands to return

    for i=0, nTargets-1 do begin

        if ~OBJ_ISA(oTargets[i], 'IDLitParameter') then $
          continue

        ; Skip colorbars even though they have palettes
        if (~OBJ_VALID(oTargets[i]) || $
            OBJ_ISA(oTargets[i], 'IDLitVisColorbar')) then $
            continue

        ; First look for a special parameter that gives the actual
        ; data used for the colorbar range.
        oData = oTargets[i]->GetParameter('VISUALIZATION DATA')
        ; If not found then get the first optarget parameter.
        if (~OBJ_VALID(oData)) then begin
            oTargetParams = oTargets[i]->QueryParameter(COUNT=nTargetParam)
            for j=0,nTargetParam-1 do begin
                oTargets[i]->GetParameterAttribute, oTargetParams[j], $
                    OPTARGET=isOpTarget
                if (isOpTarget) then begin
                    oData = oTargets[i]->GetParameter(oTargetParams[j])
                    break
                endif
            endfor
            if (~OBJ_VALID(oData)) then $
                continue
        endif

        nBars = oTargets[i]->GetParameterDataByType($
            ['IDLPALETTE','IDLOPACITY_TABLE'], oBarObj)
        if (~nBars) then continue

        nOpac = oTargets[i]->GetParameterDataByType($
            ['IDLOPACITY_TABLE'], oOpacObj)

        ;; Compute layout
        locations = FLTARR(3, nBars)
        locations[0,*] = (FINDGEN(nBars) - (nBars-1)/2.0) / (nBars*4) - 0.5
        locations[1,*] = (FINDGEN(nBars) - (nBars-1)/2.0) / (nBars*4) - 0.75
        locations[2,*] = 0.99d   ; above the Z plane so it doesn't get clipped

        ; Use user-provided locations.
        if (N_Elements(locationIn) gt 1) then begin
            ; Be nice and fill in only those elements which were provided.
            dims = Size(locationIn, /DIM)
            dim0 = dims[0] < 3
            dim1 = (N_Elements(dims) gt 1) ? (dims[1] < nBars) : 1
            locations[0:dim0-1, 0:dim1-1] = locationIn
        endif

        oTargets[i]->GetProperty, TRANSPARENCY=transparency

        for j=0, nBars-1 do begin

            oParmSet = OBJ_NEW('IDLitParameterSet', $
                NAME="ColorBarData", $
                DESCRIPTION="Color Bar Data")

            oParmSet->Add, oData[0], PARAMETER_NAME='VISUALIZATION DATA', $
                /PRESERVE_LOCATION

            ;; Decide between color and opacity.
            parmName = 'PALETTE'
            if nOpac gt 0 then begin
                if (WHERE(oBarObj[j] eq oOpacObj))[0] gt 0 then begin
                    parmName = 'OPACITY TABLE'
                endif
            endif
            oParmSet->Add, oBarObj[j], PARAMETER_NAME=parmName,/PRESERVE_LOCATION

            if nBars gt 1 then $
                oBarObj[j]->GetProperty, NAME=title

            ;; disable updates so that if the colorbar needs to change
            ;; the inital range it will not be seen onscreen
            oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

            ; Call _Create so we don't have to worry about type matching.
            ; We know we want to create a colorbar.
            oVisCmd = oCreate->_Create(oColorbarDesc, oParmSet, $
                ID_VISUALIZATION=visID, $
                LAYER='ANNOTATION', $
                AXIS_TITLE=title, $
                LOCATION=locations[*,j], $
                IMAGE_TRANSPARENCY=transparency, $
                _EXTRA=_extra)

            ;; wire up changes to the target vis
            oTool->AddOnNotifyObserver,visID,oTargets[i]->GetFullIdentifier()
            ;; ensure that the current range is correct
            IF obj_isa(oTargets[i],'IDLitVisImage') THEN BEGIN
              oTargets[i]->GetProperty,BYTESCALE_MIN=bMin,BYTESCALE_MAX=bMax
              oColorbar = oTool->GetByIdentifier(visID)
              oColorbar->SetProperty,BYTESCALE_RANGE=[bMin,bMax]
            ENDIF

            IF (~previouslyDisabled) THEN $
              oTool->EnableUpdates
            oTool->RefreshCurrentWindow

            oParmSet->Remove,/ALL
            obj_destroy,oParmSet

            oVisCmdSet = OBJ_VALID(oVisCmdSet[0]) ? $
                [oVisCmdSet, oVisCmd] : oVisCmd

        endfor
    endfor

    if ~OBJ_VALID(oVisCmdSet[0]) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:PaletteUnavailable:Text1'), $
          IDLitLangCatQuery('Error:PaletteUnavailable:Text2')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:PaletteUnavailable:Title')
        return, OBJ_NEW()
    endif

    ; Make a prettier undo/redo name.
    oVisCmdSet[0]->SetProperty, NAME='Insert colorbar'

    return, oVisCmdSet

end


;-------------------------------------------------------------------------
pro IDLitopInsertColorbar__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertColorbar, $
        inherits IDLitOperation}

end

