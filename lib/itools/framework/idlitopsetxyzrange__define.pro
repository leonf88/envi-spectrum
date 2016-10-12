; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitopsetxyzrange__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopSetXYZRange
;
; PURPOSE:
;   This file implements the operation for setting the XYZ range
;   on a target.
;
; CATEGORY:
;   IDL Tools
;
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::Init
;;
;; Purpose:
;; The constructor of the IDLitopSetXYZRange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopSetXYZRange::Init, _EXTRA=_extra
    compile_opt idl2, hidden

    ; Initialize superclass.
    return, self->IDLitOperation::Init(_EXTRA=_extra)
end

;-------------------------------------------------------------------------
;; IDLitopSetXYZRange::Cleanup
;;
;; Purpose:
;; The destructor of the IDLitopSetXYZRange object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
;pro IDLitopSetXYZRange::Cleanup
;    compile_opt idl2, hidden
;
;    self->IDLitOperation::Cleanup
;end


;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::_UndoRedo
;;
;; Purpose:
;;  Undo/Redo the commands contained in the command set.
;;
function IDLitopSetXYZRange::_UndoRedo, oCommandSet, REDO=redo

    ; Pragmas
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=nObjs-1, 0, -1 do begin

        ; Get the target (dataspace) object for this command.
        oCmds[i]->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        isNormalizer = OBJ_ISA(oTarget, 'IDLitVisNormalizer')

        ; Retrieve the appropriate zoom factor.
        if (KEYWORD_SET(redo)) then begin
            iStatus = oCmds[i]->GetItem("FINAL_XRANGE", xRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_YRANGE", yRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_ZRANGE", zRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_XAUTOUPDATE", xAutoUpdate)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_YAUTOUPDATE", yAutoUpdate)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("FINAL_ZAUTOUPDATE", zAutoUpdate)
            if (iStatus eq 0) then return, 0

            if (isNormalizer) then begin
                iStatus = oCmds[i]->GetItem("FINAL_SCALE_ISOTROPIC", $
                    scaleIsotropic)
                if (iStatus eq 0) then return, 0
            endif
        endif else begin
            iStatus = oCmds[i]->GetItem("INITIAL_XRANGE", xRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_YRANGE", yRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_ZRANGE", zRange)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_XAUTOUPDATE", xAutoUpdate)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_YAUTOUPDATE", yAutoUpdate)
            if (iStatus eq 0) then return, 0

            iStatus = oCmds[i]->GetItem("INITIAL_ZAUTOUPDATE", zAutoUpdate)
            if (iStatus eq 0) then return, 0

            if (isNormalizer) then begin
                iStatus = oCmds[i]->GetItem("INITIAL_SCALE_ISOTROPIC", $
                    scaleIsotropic)
                if (iStatus eq 0) then return, 0
            endif
        endelse

        ; If a normalizer, apply appropriate isotropy scale setting.
        if (isNormalizer) then $
            oTarget->SetProperty, SCALE_ISOTROPIC=scaleIsotropic

        ; Apply the appropriate zoom factor.
        oTarget->SetProperty, $
            X_MINIMUM=xRange[0], X_MAXIMUM=xRange[1], $
            Y_MINIMUM=yRange[0], Y_MAXIMUM=yRange[1], $
            Z_MINIMUM=zRange[0], Z_MAXIMUM=zRange[1], $
            X_AUTO_UPDATE=xAutoUpdate, $
            Y_AUTO_UPDATE=yAutoUpdate, $
            Z_AUTO_UPDATE=zAutoUpdate

    endfor

    return, 1
end

;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::UndoOperation
;;
;; Purpose:
;;  Undo the commands contained in the command set.
;;
function IDLitopSetXYZRange::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet)
end


;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::RedoOperation
;;
;; Purpose:
;;  Redo the commands contained in the command set.
;;
function IDLitopSetXYZRange::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet, /REDO)
end

;;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::RecordInitialValues
;;
;; Purpose:
;;   This routine is used to record the initial values needed to
;;   perform undo/redo for the view zoom operation.
;;
function IDLitopSetXYZRange::RecordInitialValues, oCommandSet, $
    oTargets, idProperty

    ;; Pragmas
    compile_opt idl2, hidden

    ; Loop through and record current ranges for each target.
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_VALID(oTargets[i]) eq 0) then $
            continue

        isNormalizer = OBJ_ISA(oTargets[i], 'IDLitVisNormalizer')

        ; Retrieve the initial ranges.
        oTargets[i]->GetProperty, $
            X_MINIMUM=xMin, X_MAXIMUM=xMax, $
            Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
            Z_MINIMUM=zMin, Z_MAXIMUM=zMax, $
            X_AUTO_UPDATE=xAutoUpdate, $
            Y_AUTO_UPDATE=yAutoUpdate, $
            Z_AUTO_UPDATE=zAutoUpdate

        ; If a normalizer, retrieve initial isotropy scale setting.
        if (isNormalizer) then $
            oTargets[i]->GetProperty, SCALE_ISOTROPIC=scaleIsotropic

        ; Create a command that stores the initial ranges.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oTargets[i]->GetFullIdentifier())

        iStatus = oCmd->AddItem("INITIAL_XRANGE", [xMin,xMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_YRANGE", [yMin,yMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_ZRANGE", [zMin,zMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_XAUTOUPDATE", xAutoUpdate)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_YAUTOUPDATE", yAutoUpdate)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("INITIAL_ZAUTOUPDATE", zAutoUpdate)
        if (iStatus eq 0) then return, 0

        if (isNormalizer) then begin
            iStatus = oCmd->AddItem("INITIAL_SCALE_ISOTROPIC", scaleIsotropic)
            if (iStatus eq 0) then return, 0
        endif

        oCommandSet->Add, oCmd
    endfor

    return, 1
end


;;---------------------------------------------------------------------------
;; IDLitopSetXYZRange::RecordFinalValues
;;
;; Purpose:
;;   This routine is used to record the final values needed to
;;   perform undo/redo for the view zoom operation.
;;
function IDLitopSetXYZRange::RecordFinalValues, oCommandSet, $
    oTargets, idProperty, $
    SKIP_MACROHISTORY=skipMacroHistory

    ;; Pragmas
    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (not obj_valid(oTool))then $
        return, 0

    ; Loop through and record current ranges for each target.
    oCmds = oCommandSet->Get(/ALL, COUNT=nObjs)
    for i=0, nObjs-1 do begin
        oCmd = oCmds[i]
        oCmd->GetProperty, TARGET_IDENTIFIER=idTarget
        oTarget = oTool->GetByIdentifier(idTarget)
        if (OBJ_VALID(oTarget) eq 0) then $
            continue

        isNormalizer = OBJ_ISA(oTarget, 'IDLitVisNormalizer')

        ; Retrieve the final ranges.
        oTarget->GetProperty, $
            X_MINIMUM=xMin, X_MAXIMUM=xMax, $
            Y_MINIMUM=yMin, Y_MAXIMUM=yMax, $
            Z_MINIMUM=zMin, Z_MAXIMUM=zMax, $
            X_AUTO_UPDATE=xAutoUpdate, $
            Y_AUTO_UPDATE=yAutoUpdate, $
            Z_AUTO_UPDATE=zAutoUpdate

        ; If a normalizer, retrieve final isotropy scale setting.
        if (isNormalizer) then $
            oTargets[i]->GetProperty, SCALE_ISOTROPIC=scaleIsotropic

        iStatus = oCmd->AddItem("FINAL_XRANGE", [xMin,xMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_YRANGE", [yMin,yMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_ZRANGE", [zMin,zMax])
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_XAUTOUPDATE", xAutoUpdate)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_YAUTOUPDATE", yAutoUpdate)
        if (iStatus eq 0) then return, 0

        iStatus = oCmd->AddItem("FINAL_ZAUTOUPDATE", zAutoUpdate)
        if (iStatus eq 0) then return, 0

           oTool = self->GetTool()
           oSrvMacro = oTool->GetService('MACROS')
           if ~keyword_set(skipMacroHistory) && OBJ_VALID(oSrvMacro) then begin
               oDesc = OBJ_NEW('IDLitObjDescTool', CLASSNAME='IDLitOpSetProperty', $
                    IDENTIFIER='SetXYZRange')
               idProperties = [ $
                    "X_MINIMUM", "X_MAXIMUM", $
                    "Y_MINIMUM", "Y_MAXIMUM", $
                    "Z_MINIMUM", "Z_MAXIMUM", $
                    "X_AUTO_UPDATE", "Y_AUTO_UPDATE", "Z_AUTO_UPDATE" $
                    ]
               for j=0, n_elements(idProperties)-1 do begin
                    oDesc->RecordProperty, oTarget, idProperties[j]
               endfor
               oSrvMacro->GetProperty, CURRENT_NAME=currentName
               oSrvMacro->PasteMacroSetProperty, oDesc, currentName, idResult, idProperties
               obj_destroy,oDesc
           endif
        if (isNormalizer) then begin
            iStatus = oCmd->AddItem("FINAL_SCALE_ISOTROPIC", scaleIsotropic)
            if (iStatus eq 0) then return, 0
        endif

    endfor

    return, 1
end

;---------------------------------------------------------------------------
; DEFINITION
;-------------------------------------------------------------------------
pro IDLitopSetXYZRange__define

    compile_opt idl2, hidden

    struc = {IDLitopSetXYZRange,       $
             inherits IDLitOperation   $
    }
end

