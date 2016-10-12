; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopregiongrow__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopRegionGrow
;
; Purpose:
;   This class implements a region grow operation.  A region grow
;   operation replaces a selected ROI with a region that is grown
;   to contain all connected neighboring pixels that fall within
;   given constraints.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::Init
;
; Purpose:
;   The constructor of the IDLitopRegionGrow object.
;
; Arguments:
;   None.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.  In addition, the following keywords
;   are supported:
;
;   GROW_METHOD (Get, Set): Set this keyword to a scalar value indicating 
;     the requested method to be used for region growing.
;     Valid values include:
;         0 = By threshold (default)
;         1 = By standard deviation
;
;   NEIGHBOR_SEARCH (Get, Set): Set this keyword to a scalar value 
;     indicating the requested method to be used for pixel searches.  
;     Valid values include:
;         0 = 4-neighbor
;         1 = 8-neighbor
;
;   OVERRIDE_THRESHOLD (Get, Set): Set this keyword to a non-zero value
;     to indicate that the threshold minimum and maximum values 
;     provided via the THRESHOLD_MINIMUM and THRESHOLD_MAXIMUM keywords
;     should be used when the GROW_METHOD is 0 (i.e., by threshold).
;     By default, the THRESHOLD_MINIMUM and THRESHOLD_MAXIMUM keyword
;     values are ignored, and the threshold range is automatically computed
;     from the target image pixels that fall within the source ROI.
;
;   RGBA_TARGET (Get, Set): Set this keyword to a scalar that indicates
;     how a target image should be derived from RGB or RGBA images.
;     Valid values include:
;         0=Luminosity (default)
;         1=Red Channel
;         2=Green Channel
;         3=Blue Channel
;         4=Alpha Channel
;
;   STDDEV_MULTIPLIER (Get, Set): Set this keyword to a scalar value that
;     serves as the multiplier of the sample standard deviation of the 
;     target image pixel values that fall within the source ROI. The 
;     expanded region includes neighboring pixels that fall within the 
;     range of the mean of the region's pixel values plus or minus the 
;     given multiplier times the sample standard deviation:
;         Mean +/- StdDevMultiplier * StdDev 
;
;   THRESHOLD_MINIMUM (Get, Set): Set this keyword to a scalar value
;     representing the minimum threshold value to use if GROW_METHOD 
;     is 0 (i.e., by threshold) and the OVERRIDE_THRESHOLD keyword is 
;     non-zero.  The default is 0.
;   
;   THRESHOLD_MAXIMUM (Get, Set): Set this keyword to a scalar value
;     representing the maximum threshold value to use if GROW_METHOD 
;     is 0 (i.e., by threshold) and the OVERRIDE_THRESHOLD keyword is
;     non-zero.  The default is 255.
;
function IDLitopRegionGrow::Init, $
    GROW_METHOD=growMethod, $
    NEIGHBOR_SEARCH=neighborSearch, $
    OVERRIDE_THRESHOLD=overrideThreshold, $
    RGBA_TARGET=rgbaTarget, $
    STDDEV_MULTIPLIER=stddevMult, $
    THRESHOLD_MINIMUM=threshMin, $
    THRESHOLD_MAXIMUM=threshMax, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitDataOperation::Init(NAME="Region Grow", $
        DESCRIPTION='Grow the region by constraints', $
        TYPES=['IDLROI'], $
        _EXTRA=_extra) eq 0) then $
        return, 0

    ; Initialize default values.
    self._growMethod = 0          ; By threshold
    self._neighborSearch = 0      ; 4-neighbor
    self._threshMin = 0.0    
    self._threshMax = 256.0
    self._overrideThreshold = 0   ; Use threshold of target image pixels
                                  ; that fall within source ROI
    self._stddevMult = 1.0 
    self._rgbaTarget = 0          ; Luminosity

    ;; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    ; Register properties.
    self->RegisterProperty, 'GROW_METHOD', $
        NAME='Region grow method', $
        ENUMLIST=['By threshold','By standard deviation'], $
        DESCRIPTION='Type of constraint applied when growing the region'

    self->RegisterProperty, 'NEIGHBOR_SEARCH', $
        NAME='Pixel search method', $
        ENUMLIST=['4-neighbor','8-neighbor'], $
        DESCRIPTION='Method of selecting adjacent pixel neighbors'

    self->RegisterProperty, 'OVERRIDE_THRESHOLD', $
        NAME='Threshold to use', $
        ENUMLIST=['Source ROI/image threshold', 'Explicit'], $
        DESCRIPTION='Threshold values to use'

    self->RegisterProperty, 'THRESHOLD_MINIMUM', /FLOAT, $
        NAME='Threshold minimum', $
        DESCRIPTION='Minimum threshold value', SENSITIVE=0

    self->RegisterProperty, 'THRESHOLD_MAXIMUM', /FLOAT, $
        NAME='Threshold maximum', $
        DESCRIPTION='Maximum threshold value', SENSITIVE=0
  
    self->RegisterProperty, 'STDDEV_MULTIPLIER', /FLOAT, $
        NAME='Standard deviation multiplier', $
        DESCRIPTION='Standard deviation multiplier', SENSITIVE=0

    self->RegisterProperty, 'RGBA_TARGET', $
        NAME='For an RGB(A) image use:', $
        ENUMLIST=['Luminosity',$
                  'Red Channel',$
                  'Green Channel', $
                  'Blue Channel', $
                  'Alpha Channel'], $
        DESCRIPTION='Pixel values to use when the image is RGB or RGBA'

    self->SetProperty, $
        GROW_METHOD=growMethod, $
        NEIGHBOR_SEARCH=neighborSearch, $
        OVERRIDE_THRESHOLD=overrideThreshold, $
        RGBA_TARGET=rgbaTarget, $
        STDDEV_MULTIPLIER=stddevMult, $
        THRESHOLD_MINIMUM=threshMin, $
        THRESHOLD_MAXIMUM=threshMax, $
        _EXTRA=_extra

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::Cleanup
;
; Purpose:
;   The descructor for the IDLitopRegionGrow object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
;pro IDLitopRegionGrow::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitDataOperation::Cleanup
;end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::GetProperty
;
; Arguments:
;   <None>
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopRegionGrow::Init followed by the word "Get" can be retrieved
;   using this method.
;
pro IDLitopRegionGrow::GetProperty, $
    GROW_METHOD=growMethod, $
    NEIGHBOR_SEARCH=neighborSearch, $
    OVERRIDE_THRESHOLD=overrideThreshold, $
    RGBA_TARGET=rgbaTarget, $
    STDDEV_MULTIPLIER=stddevMult, $
    THRESHOLD_MINIMUM=threshMin, $
    THRESHOLD_MAXIMUM=threshMax, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(growMethod)) then $
        growMethod = self._growMethod

    if (ARG_PRESENT(neighborSearch)) then $
        neighborSearch = self._neighborSearch

    if (ARG_PRESENT(overrideThreshold)) then $
        overrideThreshold = self._overrideThreshold

    if (ARG_PRESENT(rgbaTarget)) then $
        rgbaTarget = self._rgbaTarget

    if (ARG_PRESENT(stddevMult)) then $
        stddevMult = self._stddevMult

    if (ARG_PRESENT(threshMin)) then $
        threshMin = self._threshMin

    if (ARG_PRESENT(threshMax)) then $
        threshMax = self._threshMax

    ; Call superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::SetProperty
;
; Arguments:
;   <None>
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopRegionGrow::Init followed by the word "Set" can be set
;   using this method.
;
pro IDLitopRegionGrow::SetProperty, $
    GROW_METHOD=growMethod, $
    NEIGHBOR_SEARCH=neighborSearch, $
    OVERRIDE_THRESHOLD=overrideThreshold, $
    RGBA_TARGET=rgbaTarget, $
    STDDEV_MULTIPLIER=stddevMult, $
    THRESHOLD_MINIMUM=threshMin, $
    THRESHOLD_MAXIMUM=threshMax, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(growMethod) gt 0) then begin
        self._growMethod = growMethod
        if (self._growMethod eq 0) then begin
            ; By threshold enabled.
            self->SetPropertyAttribute, "OVERRIDE_THRESHOLD", $
                /SENSITIVE
            self->SetPropertyAttribute, "THRESHOLD_MINIMUM", $
                SENSITIVE=self._overrideThreshold
            self->SetPropertyAttribute, "THRESHOLD_MAXIMUM", $
                SENSITIVE=self._overrideThreshold
            self->SetPropertyAttribute, "STDDEV_MULTIPLIER", $
                SENSITIVE=0
        endif else begin
            ; By standard deviation enabled.
            self->SetPropertyAttribute, "OVERRIDE_THRESHOLD", $
                SENSITIVE=0
            self->SetPropertyAttribute, "THRESHOLD_MINIMUM", $
                SENSITIVE=0
            self->SetPropertyAttribute, "THRESHOLD_MAXIMUM", $
                SENSITIVE=0
            self->SetPropertyAttribute, "STDDEV_MULTIPLIER", $
                /SENSITIVE
        endelse
    endif

    if (N_ELEMENTS(neighborSearch) gt 0) then $
        self._neighborSearch = neighborSearch

    if (N_ELEMENTS(overrideThreshold) gt 0) then begin
        self._overrideThreshold = overrideThreshold
        if (self._growMethod eq 0) then begin
            self->SetPropertyAttribute, "THRESHOLD_MINIMUM", $
                SENSITIVE=self._overrideThreshold
            self->SetPropertyAttribute, "THRESHOLD_MAXIMUM", $
                SENSITIVE=self._overrideThreshold
        endif
    endif

    if (N_ELEMENTS(rgbaTarget) gt 0) then $
        self._rgbaTarget = rgbaTarget

    if (N_ELEMENTS(stddevMult) gt 0) then $
        self._stddevMult = stddevMult

    if (N_ELEMENTS(threshMin) gt 0) then $
        self._threshMin = threshMin

    if (N_ELEMENTS(threshMax) gt 0) then $
        self._threshMax = threshMax

    ; Call superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end

;---------------------------------------------------------------------------
; Region Grow Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::_Targets
;
; Purpose:
;   This internal function method retrieves the list of targets
;   for this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this
;     operation is being performed.
;
; Keywords:
;   COUNT:	Set this keyword to a named variable that upon
;     return will contain the number of returned targets.
;
; Outputs:
;   This function returns a vector of object references to
;   the targets found for this operation.
;
function IDLitopRegionGrow::_Targets, oTool, COUNT=count

    compile_opt idl2, hidden

    ; Retrieve the currently selected item(s) in the tool.
    oTargets = oTool->GetSelectedItems(count=nTargets)
    if (nTargets eq 0) then $
      return, OBJ_NEW()

    ; Prune out any invalid objects.
    good = WHERE(OBJ_VALID(oTargets), count)
    if (~count) then $
        return, OBJ_NEW()
    oTargets = oTargets[good]

    ; Select all ROIs.
    good = WHERE(OBJ_ISA(oTargets, 'IDLitVisROI'), count)
    if (~count) then $
        return, OBJ_NEW()
    oTargets = oTargets[good]

    return, oTargets
end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;; IDLitopRegionGrow::_UndoRedo
;;
;; Purpose:
;;  Undo/Redo the commands contained in the command set.
;;
function IDLitopRegionGrow::_UndoRedo, oCommandSet, REDO=redo

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

        oROIData = oTarget->GetParameter('VERTICES')
        if (~OBJ_VALID(oROIData)) then $
            continue

        haveROI = oROIData->GetData(pROIData, /POINTER)
        if (~haveROI) then $
            continue

        if (KEYWORD_SET(redo)) then begin
            iStatus = oCmds[i]->GetItem('FINAL_DATA', roiData)
            if (iStatus eq 0) then $
                return, 0
        endif else begin
            iStatus = oCmds[i]->GetItem('INITIAL_DATA', roiData)
            if (iStatus eq 0) then $
                return, 0
        endelse

        ; Replace the ROI data.
        *pROIData = roiData
        oROIData->NotifyDataChange
        oROIData->NotifyDataComplete
    endfor

    return, 1
end

;--------------------------------------------------------------------------
; IDLitopRegionGrow::UndoOperation
;
; Purpose:
;  Undo the commands contained in the command set.
;
function IDLitopRegionGrow::UndoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet)
end

;--------------------------------------------------------------------------
; IDLitopRegionGrow::RedoOperation
;
; Purpose:
;  Redo the commands contained in the command set.
;
function IDLitopRegionGrow::RedoOperation, oCommandSet

    compile_opt idl2, hidden

    return, self->_UndoRedo(oCommandSet, /REDO)
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::RecordInitialValues
;
; Purpose:
;   This routine is used to record the initial values needed to
;   perform undo/redo for the region grow operation.
;
function IDLitopRegionGrow::RecordInitialValues, oCommandSet, $
    oTargets, idProperty

    ;; Pragmas
    compile_opt idl2, hidden

    ; Loop through and record current ranges for each target.
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if (OBJ_VALID(oTargets[i]) eq 0) then $
            continue

        ; Retrieve the initial data.
        oROIData = oTargets[i]->GetParameter('VERTICES')
        if (~OBJ_VALID(oROIData)) then $
            continue
        haveData = oROIData->GetData(pROIData, /POINTER)
        if (~haveData) then $
            continue

        ; Create a command that stores the initial data.
        oCmd = OBJ_NEW('IDLitCommand', $
            TARGET_IDENTIFIER=oTargets[i]->GetFullIdentifier())

        iStatus = oCmd->AddItem("INITIAL_DATA", *pROIData)
        if (iStatus eq 0) then $ 
            return, 0

        oCommandSet->Add, oCmd
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::RecordFinalValues
;
; Purpose:
;   This routine is used to record the final values needed to
;   perform undo/redo for the region grow operation.
;
function IDLitopRegionGrow::RecordFinalValues, oCommandSet, $
    oTargets, idProperty

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
        if (OBJ_VALID(oTargets[i]) eq 0) then $
            continue

        ; Retrieve the initial data.
        oROIData = oTargets[i]->GetParameter('VERTICES')
        if (~OBJ_VALID(oROIData)) then $
            continue
        haveData = oROIData->GetData(pROIData, /POINTER)
        if (~haveData) then $
            continue

        iStatus = oCmd->AddItem("FINAL_DATA", *pROIData)
        if (iStatus eq 0) then $ 
            return, 0
    endfor

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopRegionGrow::DoAction
;
; Purpose:
;   This function method performs the primary action associated with
;   thie operation, namely to apply the region grow.
;
; Arguments:
;   oTool:	A reference to the tool object in which this operation
;     is to be performed.
;
; Outputs:
;   This function returns a reference to the command set object
;   corresponding to the act of performing this operation.
;
function IDLitopRegionGrow::DoAction, oTool
    ;; Pragmas
    compile_opt idl2, hidden

    self->_SetTool, oTool

    ;; Display dialog as a propertysheet
    IF self._bShowExecutionUI THEN BEGIN
      success = oTool->DoUIService('PropertySheet', self)
      IF success EQ 0 THEN $
        return,obj_new()
    ENDIF

    ; Retrieve the current selected item(s).
    oManipTargets = self->IDLitopRegionGrow::_Targets(oTool, COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()

    oCmdSet = OBJ_NEW('IDLitCommandSet', $
        NAME='Region Grow', $
        OPERATION_IDENTIFIER=self->GetFullIdentifier())

    iStatus = self->RecordInitialValues(oCmdSet, oManipTargets, '')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    for i=0,count-1 do begin
        oROI = oManipTargets[i]
        oROI->GetProperty, PARENT=oParent
        if (OBJ_VALID(oParent) eq 0) then $
            continue

        haveImg = 0
        if (OBJ_ISA(oParent, 'IDLitVisImage')) then begin
            oImageData = oParent->GetParameter('IMAGEPIXELS')
            if (OBJ_VALID(oImageData)) then $
                haveImg = oImageData->GetData(pImgData, /POINTER)

            if (haveImg) then begin
                imgDims = SIZE(*(pImgData[0]),/DIMENSIONS)

                ; Determine if parent image is an indexed image.  
                nChannel = N_ELEMENTS(pImgData)
                if (nChannel eq 2) then begin
                    ; Image is luminance alpha.  Use luminance.
                    pImgData = pImgData[0]
                endif else if (nChannel gt 2) then begin
                    ; Image is RGB or RGBA.  Prepare a target image.

                    ; Revert to luminosity if alpha channel is requested but
                    ; not available.
                    rgbaTarget = ((self._rgbaTarget eq 4) and $
                                  (nChannel lt 4)) ? 0 : self._rgbaTarget

                    case rgbaTarget of 
                        0: begin ; Luminosity

                            targetImg = MAKE_ARRAY(imgDims[0], imgDims[1], $
                                TYPE=SIZE(*pImgData[0], /TYPE), /NOZERO)
                            targetImg = BYTE((0.3  * (*pImgData[0])) + $
                                             (0.59 * (*pImgData[1])) + $
                                             (0.11 * (*pImgData[2])))
                            pImgData = PTR_NEW(targetImg)
                        end
                        1: begin ; Red Channel
                            pImgData = pImgData[0]
                        end
                        2: begin ; Green Channel
                            pImgData = pImgData[1]
                        end
                        3: begin ; Blue Channel
                            pImgData = pImgData[2]
                        end
                        4: begin ; Alpha Channel
                            pImgData = pImgData[3]
                        end
                    endcase
                endif
            endif
        endif

        if (~haveImg) then $
            continue

        ; Get the ROI vertices.
        haveROI = 0
        oROIData = oROI->GetParameter('VERTICES')
        if (OBJ_VALID(oROIData)) then $
            haveROI = oROIData->GetData(pROIData, /POINTER)
        if (~haveROI) then $
            continue

        ; Compute a mask for the region.
        roiMask = oROI->ComputeMask(DIMENSIONS=imgDims)
        roiPixels = WHERE(roiMask ne 0, count)
        if (count eq 0) then $
            continue

        ; Apply region grow.
        if (self._growMethod eq 0) then begin
            ; By threshold.
            if (self._overrideThreshold) then $
                thresh = [self._threshMin, self._threshMax]
            growPixels = REGION_GROW(*pImgData, roiPixels, $
                THRESHOLD=thresh, $
                ALL_NEIGHBORS=self._neighborSearch)
        endif else begin
            ; By standard deviation.
            growPixels = REGION_GROW(*pImgData, roiPixels, $
                STDDEV_MULTIPLIER=self._stddevMult, $
                ALL_NEIGHBORS=self._neighborSearch)
        endelse

        if ((N_ELEMENTS(growPixels) eq 1) and $
            (growPixels[0] eq -1)) then $
            continue

        ; Create a mask for the grown region.
        growMask = BYTARR(imgDims[0], imgDims[1])
        growMask[growPixels] = 255

        ; Contour the grown region's mask.
        CONTOUR, growMask, LEVELS=255, PATH_INFO=pathInfo, PATH_XY=pathXY, $
            /PATH_DATA_COORD
        if (N_ELEMENTS(pathInfo) eq 0) then $
            continue

        ; Select first exterior contour.
        iids = WHERE(pathInfo[*].high_low eq 1, nContours)
        if (nContours eq  0) then $
            continue

        contId = iids[0]
        iStart = pathInfo[contId].offset
        iFinish = iStart + pathInfo[contId].n - 1

        newROIVerts = FLTARR(3,pathInfo[contId].n)
        newROIVerts[0,*] = pathXY[0, iStart:iFinish]
        newROIVerts[1,*] = pathXY[1, iStart:iFinish]

        ; Replace the ROI data.
        *pROIData = newROIVerts
        oROIData->NotifyDataChange
        oROIData->NotifyDataComplete

    endfor

    ; Make sure at least one item was successfully added to
    ; the command set.
    nCmds = oCmdSet->Count()
    if (nCmds eq 0) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    ; Record final values.
    iStatus = self->RecordFinalValues(oCmdSet, oManipTargets, '')

    return, oCmdSet
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
pro IDLitopRegionGrow__define

    compile_opt idl2, hidden

    struc = {IDLitopRegionGrow,      $
        inherits IDLitDataOperation, $
        _growMethod: 0,              $ ; Method to use for growing a region:
                                     $ ;  (by threshold, or by stddev)
        _neighborSearch: 0,          $ ; Neighbor pixel search method:
                                     $ ;  (4-neighbor or 8-neighbor)
        _threshMin: 0.0d,            $ ; Threshold minimum value
        _threshMax: 0.0d,            $ ; Threshold maximum value
        _overrideThreshold: 0b,      $ ; Flag: use _threshMin and _threshMax
                                     $ ;  (vs. compute from  source ROI)?
        _stddevMult: 0.0,            $ ; Standard deviation multiplier
        _rgbaTarget: 0               $ ; Target image used for region growing
                                     $ ;  for RGB(A) images:
                                     $ ;  (luminosity, r, g, b, or alpha)
    }
end

