; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertsurface__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertSurface
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the Insert/Surface action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopInsertSurface::Init
;
; Purpose:
; The constructor of the IDLitopInsertSurface object.
;
; Parameters:
; None.
;
function IDLitopInsertSurface::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ~self->IDLitOperation::Init(TYPES=["IDLARRAY2D", "IDLIMAGE"], $
        NUMBER_DS='1', _EXTRA=_extra) then $
        return, 0

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopInsertSurface::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertSurface::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(COUNT=nTarg)
    if (nTarg eq 0) then $
        return, OBJ_NEW()

    ; Retrieve the service used to create visualizations.
    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreate)) then $
        return, OBJ_NEW()

    nData=0
    oCmdSetList = OBJ_NEW()
    for i=0, nTarg-1 do begin

        if (~OBJ_VALID(oTargets[i])) then $
            continue

        if (~OBJ_ISA(oTargets[i], 'IDLitParameter')) then $
            continue

        ; Look for data objects of the appropriate type.
        nData = oTargets[i]->GetParameterDataByType($
            ['IDLIMAGE','IDLIMAGEPIXELS','IDLARRAY2D'], oDataObj)
        if (nData eq 0) then $
            continue

        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME='Surface parameters', $
            ICON='surface', $
            DESCRIPTION='Surface parameters')

        ; Just use the first matching parameter that we found.
        oParmSet->Add, oDataObj[0], PARAMETER_NAME="Z", /PRESERVE_LOCATION

        ; Look for X and Y parameters.
        if obj_isa(oTargets[i], 'IDLitVisImage') then $
            oTargets[i]->EnsureXYParameters
        oX = oTargets[i]->GetParameter('X')
        if OBJ_VALID(oX) then $
            oParmSet->Add, oX, PARAMETER_NAME="X", /PRESERVE_LOCATION

        oY = oTargets[i]->GetParameter('Y')
        if OBJ_VALID(oY) then $
            oParmSet->Add, oY, PARAMETER_NAME="Y", /PRESERVE_LOCATION

        oCmdSet = oCreate->CreateVisualization( $
            oParmSet, $
            "SURFACE")

        oParmSet->Remove,/ALL
        obj_destroy,oParmSet

        oCmdSetList = OBJ_VALID(oCmdSetList[0]) ? $
            [oCmdSetList, oCmdSet] : oCmdSet
    endfor

    if (~OBJ_VALID(oCmdSetList[0])) then begin
        self->ErrorMessage, $
         [IDLitLangCatQuery('Error:InsertViz:IncorrectType'), $
          IDLitLangCatQuery('Error:InsertSurface:CannotCreate')], severity=0, $
         TITLE=IDLitLangCatQuery('Error:DataUnavailable:Title')
        return, OBJ_NEW()
    endif

    return, oCmdSetList
end


;-------------------------------------------------------------------------
; IDLitopInsertSurface::QueryAvailability
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
function IDLitopInsertSurface::QueryAvailability, oTool, selTypes

    compile_opt idl2, hidden

    ; Use our superclass as a first filter.
    ; If not available by matching types, then no need to continue.
    success = self->IDLitOperation::QueryAvailability(oTool, selTypes)
    if (~success) then $
        return, 0

    oSelVis = oTool->GetSelectedItems(COUNT=nSelVis)
    if (nSelVis eq 0) then $
        return, 0

    ; If our dataspace has a map projection, then we can't crop.
    for i=0,nSelVis-1 do begin
        oDataSpace = oSelVis[i]->GetDataSpace()
        if (N_TAGS(oDataSpace->GetProjection()) gt 0) then $
            return, 0
    endfor

    return, 1

end


;-------------------------------------------------------------------------
pro IDLitopInsertSurface__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertSurface, $
        inherits IDLitOperation}

end

