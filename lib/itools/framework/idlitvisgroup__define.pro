; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitvisgroup__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitVisGroup
;
; PURPOSE:
;   This class represents a group of IDLitVisualizations.
;
;-

;----------------------------------------------------------------------------
; Lifecycle Methods
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
; PURPOSE:
;   This function method initializes the component object.
;
; OUTPUTS:
;   This function returns a 1 if the initialization was successful,
;   or a 0 otherwise.
;
function IDLitVisGroup::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ;; Note: 3/03 - Took out the setting of manipulator target. This
    ;;              was causing issues with the clipboard and pasting groups
    status = self->IDLitVisualization::Init(NAME='Group', $
        ICON='group', $
        /PROPERTY_INTERSECTION, $
        TYPE='IDLPOLYGON', $
        _EXTRA=_extra)

    return, status
end


;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method preforms all cleanup on the object.
;
;pro IDLitVisGroup::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclasses.
;    self->IDLitVisualization::Cleanup
;end


;----------------------------------------------------------------------------
; PURPOSE:
;   Override the Add method so we can group and aggregate.
;   We need to do this here rather than in the Group operation, so that
;   copy/paste works correctly with groups.
;
pro IDLitVisGroup::Add, oVis, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~OBJ_ISA(oVis, 'IDLitManipulatorVisual')) then $
        self->IDLitVisualization::Add, oVis, /GROUP, /AGGREGATE, _EXTRA=_extra $
    else $
        self->IDLitVisualization::Add, oVis, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; Purpose:
;   This method overrides the IDLitVisualization::GetXYZRange function,
;   because we don't want to check the IMPACTS_RANGE property for our
;   children. We just get their range regardless.
;
function IDLitVisGroup::GetXYZRange, $
    outxRange, outyRange, outzRange, $
    DATA=bDataRange, $
    NO_TRANSFORM=noTransform

    compile_opt idl2, hidden

    ; Flags to indicate whether we have successfully retrieved ranges.
    success = 0

    ; Default return values.
    outxRange = [0.0d, 0.0d]
    outyRange = [0.0d, 0.0d]
    outzRange = [0.0d, 0.0d]

    ; Grab the transformation matrix.
    if (not KEYWORD_SET(noTransform)) then $
        self->IDLgrModel::GetProperty, TRANSFORM=transform

    ; Grab children.
    oObjList = self->IDL_Container::Get(/all, count=nObjs)

    ; Step through children, accumulating XYZ ranges.
    for i=0, nObjs-1 do begin
        oObj = oObjList[i]

        if (OBJ_ISA(oObj, 'IDLitManipulatorVisual')) then $
            continue

        impactsRange = oObj->GetXYZRange(xRange, yRange, zRange, $
            DATA=bDataRange)

        ; For each XYZRange, apply transform if requested and
        ; accumulate into overall XYZ range if this object has any impact.

        ; -- XYZ Range -----------------------------------------------
        if (impactsRange) then begin
            self->_AccumulateXYZRange, success, $
                outxRange, outyRange, outzRange, $
                xRange, yRange, zRange, $
                TRANSFORM=transform
        endif

    endfor  ; children loop

    return, success
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisGroup__Define
;
; PURPOSE:
;   Defines the object structure for an IDLitVisGroup object.
;-
pro IDLitVisGroup__Define

    compile_opt idl2, hidden

    struct = { IDLitVisGroup,       $
        inherits IDLitVisualization $ ; Superclass.
    }
end
