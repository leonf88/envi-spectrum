; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertlegend__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert legend operation.
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
function IDLitopInsertLegend::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    ; don't init by type.  allow creation of legend if no items are
    ; selected.  filter by vis type below
    return, self->IDLitOperation::Init( $
        TYPES=['DATASPACE_2D','DATASPACE_3D', $
            'DATASPACE_ROOT_2D','DATASPACE_ROOT_3D', $
            'PLOT','PLOT3D','SURFACE','CONTOUR'], $
            NUMBER_DS='1', $
            _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertLegend::DoAction, oTool, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTarg)

    if( (nTarg eq  0) or $
    ((nTarg eq 1) AND $
         (OBJ_ISA(oTargets[0], 'IDLitVisIDataSpace')))) then begin
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
          return, OBJ_NEW()
        oView = oWindow->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
        oTargets = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
        if (count eq 0) then begin
            self->ErrorMessage, $
              [IDLitLangCatQuery('Error:InsertLegend:CannotFind')], $
                severity=0, $
              TITLE=IDLitLangCatQuery('Error:InsertLegend:Title')
            return, OBJ_NEW()
        endif
    endif

    ; filter to acceptable visualizations
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if ((OBJ_ISA(oTargets[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisPlot3D')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisContour')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisSurface'))) then begin
                if (N_ELEMENTS(oVisTargets) gt 0) then begin
                    oVisTargets = [oVisTargets, oTargets[i]]
                endif else begin
                    oVisTargets = [oTargets[i]]
                endelse
        endif
    endfor
    if (N_ELEMENTS(oVisTargets) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:InsertLegend:NotSelected')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:InsertLegend:Title')
        return, OBJ_NEW()
    endif

    nTargets = N_Elements(oVisTargets)
    idTargets = Strarr(nTargets)
    for i=0,nTargets-1 do idTargets[i] = oVisTargets[i]->GetFullIdentifier()

    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~Obj_Valid(oCreate)) then return, Obj_New()

    oVisDesc = oTool->GetAnnotation('LEGEND')

    ; Call _Create so we don't have to worry about type matching.
    ; We know we want to create a legend.
    oCmd = oCreate->_Create(oVisDesc, $
        LAYER='ANNOTATION', $
        VIS_TARGET=idTargets, $
        /MANIPULATOR_TARGET, $
        LOCATION=[0.6d,0.95d], $  ; initially in upper right corner
        _EXTRA=_extra)

    return, oCmd
end


;-------------------------------------------------------------------------
pro IDLitopInsertLegend__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertLegend, $
        inherits IDLitOperation $
        }

end

