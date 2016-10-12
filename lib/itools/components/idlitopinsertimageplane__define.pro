; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopinsertimageplane__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertImagePlane
;
; PURPOSE:
;   This file implements the generic IDL Tool object that
;   implements the Insert/ImagePlane action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertImagePlane::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitopInsertImagePlane::Init
;   IDLitopInsertImagePlane::DoAction
;
; INTERFACES:
; IIDLProperty
;-
;;---------------------------------------------------------------------------
;; Lifecycle Routines
;;---------------------------------------------------------------------------
;; IDLitopInsertImagePlane::Init
;;
;; Purpose:
;; The constructor of the IDLitopInsertImagePlane object.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertImagePlane::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    return, self->IDLitOperation::Init(TYPES=["IDLARRAY3D"], $
        _EXTRA=_extra)
end


;;---------------------------------------------------------------------------
;; IDLitopInsertImagePlane::DoAction
;;
;; Purpose: For each selected visualization, find all 3D data and
;;   create an image plane for each.
;;
;; Parameters:
;; None.
;;
;-------------------------------------------------------------------------
function IDLitopInsertImagePlane::DoAction, oTool

    compile_opt idl2, hidden

    ;; Get our Create Vis service.
    oCreateVis = oTool->GetService("CREATE_VISUALIZATION")
    if not OBJ_VALID(oCreateVis) then $
        return, OBJ_NEW()

    ;; Retrieve the current selected item(s).
    oSelVis = oTool->GetSelectedItems(count=nSelVis)

    if (nSelVis eq 0) then $
        return, OBJ_NEW()

    ;; For each selected visualization
    oCmdSet = OBJ_NEW()
    for iSelVis=0, nSelVis-1 do begin
        if not OBJ_VALID(oSelVis[iSelVis]) then $
            continue;
        if not OBJ_ISA(oSelVis[iSelVis], 'IDLitVisVolume') then $
            continue
        oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Volume Image Plane Data', $
            ICON='image')
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('VOLUME0'), PARAMETER_NAME='VOLUME0', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('VOLUME1'), PARAMETER_NAME='VOLUME1', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('VOLUME2'), PARAMETER_NAME='VOLUME2', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('VOLUME3'), PARAMETER_NAME='VOLUME3', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('RGB_TABLE0'), PARAMETER_NAME='RGB_TABLE0', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('RGB_TABLE1'), PARAMETER_NAME='RGB_TABLE1', $
                       /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('OPACITY_TABLE0'), $
                       PARAMETER_NAME='OPACITY_TABLE0', /PRESERVE_LOCATION
        oParmSet->Add, oSelVis[iSelVis]->GetParameter('OPACITY_TABLE1'), $
                       PARAMETER_NAME='OPACITY_TABLE1', /PRESERVE_LOCATION
        ;; We let the ImagePlane Visualization code actually fill in the
        ;; contents of the image; it is a lot of work.
        oParmSet->Add, OBJ_NEW('IDLitDataIDLImagePixels', $
            NAME='Image Planes'), PARAMETER_NAME='IMAGEPIXELS'
        ;; Create an image plane vis
        oCmd = oCreateVis->CreateVisualization(oParmSet, "IMAGE PLANE")

        ;; Remove duplicate data
        oParmSet->Remove,oParmSet->GetByName('VOLUME0')
        oParmSet->Remove,oParmSet->GetByName('VOLUME1')
        oParmSet->Remove,oParmSet->GetByName('VOLUME2')
        oParmSet->Remove,oParmSet->GetByName('VOLUME3')
        oParmSet->Remove,oParmSet->GetByName('RGB_TABLE0')
        oParmSet->Remove,oParmSet->GetByName('RGB_TABLE1')
        oParmSet->Remove,oParmSet->GetByName('OPACITY_TABLE0')
        oParmSet->Remove,oParmSet->GetByName('OPACITY_TABLE1')
        ;; Make the parmset visible in the Data Manager.
        oTool->AddByIdentifier, "/Data Manager", oParmSet

        oCmdSet = not OBJ_VALID(oCmdSet[0]) ? oCmd : [oCmdSet, oCmd]
    endfor

    return, oCmdSet
end


;-------------------------------------------------------------------------
pro IDLitopInsertImagePlane__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertImagePlane, $
        inherits IDLitOperation}

end

