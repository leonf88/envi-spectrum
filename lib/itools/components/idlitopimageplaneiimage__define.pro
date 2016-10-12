; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopimageplaneiimage__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopImagePlaneIImage
;
; PURPOSE:
;   This operation launches an instance of the iImage tool
;   using a currently selected image plane.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopImagePlaneIImage::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopImagePlaneIImage::Init
;
; Purpose:
; The constructor of the IDLitopInsertImagePlane object.
;
; Parameters:
; None.
;
function IDLitopImagePlaneIImage::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ~self->IDLitOperation::Init(TYPES=['IDLIMAGEPIXELS'], NUMBER_DS='1', $
        _EXTRA=_extra) then $
        return, 0

    return, 1

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
function IDLitopImagePlaneIImage::DoAction, oTool

    compile_opt idl2, hidden

    oTool = self->GetTool()

    ;; Retrieve the current selected item(s).
    oSelVis = oTool->GetSelectedItems(count=nSelVis)
    if (nSelVis eq 0) then $
        return, OBJ_NEW()

    ;; For each selected visualization
    for iSelVis=0, nSelVis-1 do begin
        if ~OBJ_VALID(oSelVis[iSelVis]) then $
            continue;
        if ~OBJ_ISA(oSelVis[iSelVis], 'IDLitVisImagePlane') then $
            continue

        ;; Create an instance of the image tool.
        strToolID = IDLitSys_CreateTool("Image Tool", $
            NAME="Image",$
            TITLE='IDL Volume Image Plane')
        oNewTool = oTool->GetByIdentifier(strToolID)
        if ~OBJ_VALID(oNewTool) then break

        ;; Get the create viz service.
        oCreateVis = oNewTool->GetService("CREATE_VISUALIZATION")
        if ~OBJ_VALID(oCreateVis) then break

        ;; Create a parmset
        oParmSet = OBJ_NEW('IDLitParameterSet', $
            DESCRIPTION='Image Plane', NAME='Image Plane',$
            TYPE='Image', ICON='image')

        ;; Wire up Image parm
        oData = oSelVis->GetParameter('IMAGEPIXELS')
        oParmSet->Add, oData, PARAMETER_NAME='IMAGEPIXELS', /PRESERVE_LOCATION

        ;; Create the image visualization
        oCommandSet = oCreateVis->CreateVisualization(oParmSet, $
            "IMAGE")
        OBJ_DESTROY, oCommandSet   ; not undoable
        oParmSet->Remove,/ALL
        OBJ_DESTROY, oParmSet
    endfor

    return, OBJ_NEW()
end


;-------------------------------------------------------------------------
pro IDLitopImagePlaneIImage__define

    compile_opt idl2, hidden
    struc = {IDLitopImagePlaneIImage, $
        inherits IDLitOperation}

end

