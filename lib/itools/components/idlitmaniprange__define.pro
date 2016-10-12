; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprange__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipRange
;
; PURPOSE:
;   The IDLitManipRange class represents a manipulator used to modify
;   the XYZ range of one or more target dataspace objects.
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipRange::Init
;
; PURPOSE:
;   The IDLitManipRange::Init function method initializes the
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oManipulator = OBJ_NEW('IDLitManipRange')
;
;-
function IDLitManipRange::Init, $
    TOOL=tool, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulatorContainer::Init( $
        VISUAL_TYPE="Range", $
        IDENTIFIER="MANIP_RANGE", $
        NAME="Data Range", $
        TOOL=tool, $
        TYPES=["DATASPACE_2D", "VISUALIZATION"], $
        /AUTO_SWITCH, $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    self._numberDS = '1'

    ; Add the rangebox manipulator.
    oRangeBoxManip = OBJ_NEW('IDLitManipRangeBox', TOOL=tool, /PRIVATE)
    if (OBJ_VALID(oRangeBoxManip) eq 0) then $
        return, 0
    self->Add, oRangeBoxManip

    ; Add the pan manipulator.
    oPanManip = OBJ_NEW('IDLitManipRangePan', TOOL=tool, /PRIVATE)
    if (OBJ_VALID(oPanManip) eq 0) then $
        return, 0
    self->Add, oPanManip

    ; Add the zoom manipulator.
    oZoomManip = OBJ_NEW('IDLitManipRangeZoom', TOOL=tool, /PRIVATE)
    if (OBJ_VALID(oZoomManip) eq 0) then $
        return, 0
    self->Add, oZoomManip

    self->SetCurrent, oRangeBoxManip

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipRange::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipRange::Cleanup
;   ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulatorContainer::Cleanup
;end

;--------------------------------------------------------------------------
; IDLitManipRange::_FindManipulatorTargets
;
; Purpose:
;   This function method determines the list of manipulator targets
;   (i.e., dataspaces) to be manipulated by this manipulator
;   (based upon the given list of visualizations current selected).
;
; Keywords:
;   MERGE
;     Note: this keyword is ignored for this manipulator because
;     we only want dataspaces to be considered manipulator targets.
;
function IDLitManipRange::_FindManipulatorTargets, oVisIn, $
    MERGE=merge

    compile_opt idl2, hidden

    nVis = N_ELEMENTS(oVisIn)
    if (nVis eq 0) then return, OBJ_NEW()
    if (OBJ_VALID(oVisIn[0]) eq 0) then $
        return, OBJ_NEW()

    oLayer = oVisIn[0]->_GetLayer()
    if (OBJ_VALID(oLayer) eq 0) then $
        return, OBJ_NEW()
    if (OBJ_ISA(oLayer, 'IDLitGrAnnotateLayer')) then $
        return, OBJ_NEW()

    oTool = self->GetTool()
    oWin = OBJ_VALID(oTool) ? oTool->GetCurrentWindow() : OBJ_NEW()
    oView = OBJ_VALID(oWin) ? oWin->GetCurrentView() : OBJ_NEW()
    oLayer = OBJ_VALID(oView) ? oView->GetCurrentLayer() : OBJ_NEW()
    oWorld = OBJ_VALID(oLayer) ? oLayer->GetWorld() : OBJ_NEW()
    oDataSpaces = OBJ_VALID(oWorld) ? oWorld->GetDataSpaces() : OBJ_NEW()

    return, oDataSpaces
end

;---------------------------------------------------------------------------
; IDLitManipRange::Define
;
; Purpose:
;   Define the object structure for the manipulator
;
pro IDLitManipRange__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipRange,                    $
            inherits IDLitManipulatorContainer  $ ; Superclass
    }
end
