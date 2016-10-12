; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertcontour__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertContour
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the Insert/Contour action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertContour::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopInsertContour::Init
;
; Purpose:
; The constructor of the IDLitopInsertContour object.
;
; Parameters:
; None.
;
function IDLitopInsertContour::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=["IDLARRAY2D", "IDLIMAGE"], $
        NUMBER_DS='1', $
        _EXTRA=_extra)) then $
        return, 0

    self._nLevels = 5

    ;; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ;; Register properties
    self->RegisterProperty, 'N_LEVELS', /INTEGER, $
        NAME='Number of levels', $
        Description='Number of Levels'

    self->RegisterProperty, 'VALUE', /FLOAT, $
        NAME='Value', $
        DESCRIPTION='Contour value', $
        SENSITIVE=0

    self->RegisterProperty, 'PLANAR', $
        DESCRIPTION='Project onto plane', $
        NAME='Projection', $
        ENUMLIST=['Three-D','Planar']
    self._planar=1

    return, 1
end


;-------------------------------------------------------------------------
;; IDLitopInsertContour::GetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopInsertContour::GetProperty,        $
                        PLANAR=planar, $
                        VALUE=value, $
                        N_LEVELS=nLevels,   $
                        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (arg_present(planar)) then $
        planar = self._planar

    if (arg_present(value)) then $
        value = self._value

    if (arg_present(nLevels)) then $
        nLevels = self._nLevels

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
;; IDLitopInsertContour::SetProperty
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
pro IDLitopInsertContour::SetProperty,      $
                        PLANAR=planar, $
                        VALUE=value, $
                        N_LEVELS=nLevels,   $
                        _EXTRA=_extra

    compile_opt idl2, hidden

    if (n_elements(planar) ne 0) then begin
        self._planar=planar
    endif

    if (n_elements(value) ne 0) then begin
        self._value=value
    endif

    if (n_elements(nLevels) ne 0) then begin
        if nLevels lt 0 then $
            self->ErrorMessage, IDLitLangCatQuery('Error:InsertContour:Text'), severity=2
        self._nLevels = nLevels

        ; this value is used only when n_levels = 1
        self->SetPropertyAttribute, 'VALUE', $
            SENSITIVE=(nLevels eq 1)
    endif

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end

;;---------------------------------------------------------------------------
;; IDLitopInsertContour::DoAction
;;
;; Purpose:
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertContour::DoAction, oTool

    compile_opt idl2, hidden

    ;; Display dialog as a propertysheet
    IF self._bShowExecutionUI THEN BEGIN
      success = oTool->DoUIService('PropertySheet', self)
      IF success EQ 0 THEN $
        return,obj_new()
    ENDIF

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
    for i=0, nTarg -1 do begin

        if (~OBJ_VALID(oTargets[i])) then $
            continue

        if (~OBJ_ISA(oTargets[i], 'IDLitParameter')) then $
            continue

        ; Must look for the data in order of most specific (e.g. SURFACE)
        ; to least (e.g. ARRAY2D).
        nData = oTargets[i]->GetParameterDataByType($
            ['SURFACE', 'IDLIMAGE', 'CONTOUR', 'IDLARRAY2D'], oDataObj)

        if (nData eq 0) then $
            continue

        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME='Contour parameters', $
            ICON='contour', $
            DESCRIPTION='Contour parameters')

        ; Just use the first matching parameter that we found.
        oParmSet->Add, oDataObj[0], PARAMETER_NAME="Z", /PRESERVE_LOCATION

        ; Look for X and Y parameters.
        if obj_isa(oTargets[i], 'IDLitVisImage') then begin
            oTargets[i]->EnsureXYParameters
            oTargets[i]->GetProperty, GRID_UNITS=gridUnits
        endif

        oX = oTargets[i]->GetParameter('X')
        if OBJ_VALID(oX) then begin
            oParmSet->Add, oX, PARAMETER_NAME="X", /PRESERVE_LOCATION
            xFlag = 1
        endif
        oY = oTargets[i]->GetParameter('Y')
        if OBJ_VALID(oY) then begin
            oParmSet->Add, oY, PARAMETER_NAME="Y", /PRESERVE_LOCATION
            yFlag = 1
        endif

        ; Only assign value if 1 level.
        if (self._nLevels eq 1) then $
            cValue = [self._value]

        oCmdSet = oCreate->CreateVisualization( $
            ID_VISUALIZATION=idVis, $
            oParmSet, $
            C_VALUE=cValue, $
            GRID_UNITS=gridUnits, $
            N_LEVELS=self._nLevels, $
            PLANAR=self._planar, $
            "CONTOUR")

        ;; update labels if necessary
        oContour = oTool->GetByIdentifier(idVis)
        if OBJ_VALID(oContour) then begin
            oContourLevels = (oContour->_GetLevels())[0]
            oContourLevels[0]->GetProperty,LABEL_TYPE=labelType
            if (labelType eq 1) then begin
                oContourLevels[0]->SetProperty,LABEL_TYPE=1
                oTool->RefreshCurrentWindow
            endif
        endif

        ;; remove duplicate items
        oParmSet->Remove,oParmSet->GetByName('Z')
        IF n_elements(xFlag) THEN $
          oParmSet->Remove,oParmSet->GetByName('X')
        IF n_elements(yFlag) THEN $
          oParmSet->Remove,oParmSet->GetByName('Y')

        ;; if we have anything new, add it to DM, otherwise
        IF obj_valid(oParmSet->Get(POSITION=0))THEN BEGIN
          oTool->AddByIdentifier, "/DATA MANAGER", oParmSet
        ENDIF ELSE BEGIN
          obj_destroy,oParmSet
        ENDELSE

        oCmdSetList = OBJ_VALID(oCmdSetList[0]) ? $
            [oCmdSetList, oCmdSet] : oCmdSet
    endfor

    if (~OBJ_VALID(oCmdSetList[0])) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:InsertViz:IncorrectType'), $
                IDLitLangCatQuery('Error:InsertContour:CannotCreate')], $
                severity=0, $
            TITLE=IDLitLangCatQuery('Error:DataUnavailable:Title')
        return, OBJ_NEW()
    endif

    return, oCmdSetList
end


;-------------------------------------------------------------------------
pro IDLitopInsertContour__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertContour, $
        inherits IDLitOperation, $
        _planar: 0b, $
        _value: 0D, $   ; level value if n_levels = 1
        _nLevels: 0L }

end

