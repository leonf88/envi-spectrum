; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisrange__define.pro#1 $
;
; Copyright (c) 2001-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisRange class is the range pan/zoom manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisRange')
;
;   or
;
;   Obj->[IDLitManipVisRange::]Init
;
; Result:
;   1 for success, 0 for failure.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
function IDLitManipVisRange::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Range Visual"

    ; Initialize superclasses.
    ; Default is to not be the Select Target.
    if (self->IDLitManipulatorVisual::Init( $
        NAME=name, $
        VISUAL_TYPE='Range', $
        SELECT_TARGET=1) eq 0) then $
        return, 0

    ; Pan visual.
    self.oPan = OBJ_NEW('IDLitManipVisRangePan', TYPE='Pan')
    self->Add, self.oPan

    ; Zoom visual.
    self.oZoom = OBJ_NEW('IDLitManipVisRangeZoom', TYPE='Pan')
    self->Add, self.oZoom

    ; Set any properties.
    self->IDLitManipVisRange::SetProperty, _EXTRA=_extra

    return , 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method cleans up the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitManipVisRange::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclasses.
;    self->IDLitManipulatorVisual::Cleanup
;end


;----------------------------------------------------------------------------
; Purpose:
;   This private procedure method computes the offsets from the axes
;   to be used for positioning the range zoom & pan controls.
;
; Arguments:
;   oVis: Set this argument to the object reference of the
;       IDLitVisualization around which the range zoom & pan controls
;       are to be positioned.
;
pro IDLitManipVisRange::_SetAxisOffsets, oVis
    compile_opt idl2, hidden

    axisOffsets = [0.1, 0.15]

    if (~oVis->_GetWindowandViewG(oWin, oView)) then begin
        self.oPan->SetProperty, AXIS_OFFSETS=axisOffsets
        self.oZoom->SetProperty, AXIS_OFFSETS=axisOffsets
        return
    endif

    ; Collect the target data space.
    if (OBJ_ISA(oVis, 'IDLitVisDataSpaceRoot')) then begin
        oDS = oVis->Get(/ALL, ISA='IDLitVisIDataSpace',COUNT=nDS)
        ; Sanity check if we are removing the dataspace.
        if (nDS eq 0) then return
        oDS = (oDS)[0]->GetDataSpace(/UNNORMALIZED)
        nDS = 1
    endif else begin
        oDS = oVis->GetDataSpace(/UNNORMALIZED)
        nDS = 1
    endelse

    ; Determine where text labels of pertinent axes are, and attempt
    ; to offset the range controls beyond these text labels.
    bValid = oDS->GetXYZRange(axisXRange, axisYRange, axisZRange, /INCLUDE_AXES)
    weeBit = 0.05
    if (bValid && (nDS gt 0)) then begin
        axisXLen = axisXRange[1]-axisXRange[0]
        axisYLen = axisYRange[1]-axisYRange[0]
        for iDS=0,nDS-1 do begin
            oAxes = oDS[iDS]->GetAxes(COUNT=nAxes)
            for i=0,nAxes-1 do begin
                oAxes[i]->GetProperty, DIRECTION=axisDir, NORM_LOCATION=normLoc
                case axisDir of
                  0: begin
                    if (normLoc[1] le 0.1) then begin
                        oAxis = oAxes[i]->Get(/ALL, ISA='IDLgrAxis')
                        if (OBJ_VALID(oAxis[0])) then begin
                             textDims = oWin->GetTextDimensions(oAxis[0])
                             offst = (textDims[1] / axisYLen) + weeBit
                             if (offst gt axisOffsets[0]) then $
                                 axisOffsets[0] = offst
                        endif
                    endif
                  end
                  1: begin
                    if (normLoc[0] le 0.1) then begin
                        oAxis = oAxes[i]->Get(/ALL, ISA='IDLgrAxis')
                        if (OBJ_VALID(oAxis[0])) then begin
                             textDims = oWin->GetTextDimensions(oAxis[0])
                             offst = (textDims[0] / axisXLen) + weeBit
                             if (offst gt axisOffsets[1]) then $
                                 axisOffsets[1] = offst
                        endif
                    endif
                  end
                  else: begin
                  end
                endcase
            endfor
        endfor
    endif

    ; Pass along results to both pan and zoom visuals.
    self.oPan->SetProperty, AXIS_OFFSETS=axisOffsets
    self.oZoom->SetProperty, AXIS_OFFSETS=axisOffsets

end

;----------------------------------------------------------------------------
; Purpose:
;   This private procedure method transforms the selection visual
;   to the size and position of the given visualization.  Furthermore,
;   it hides/shows portions of the selection visual based upon the
;   isotropy setting for the visualization.
;
; Arguments:
;   Visualization: Set this argument to the object reference of the
;       IDLitVisualization that you wish to use when transforming
;       the scale and location of the selection visual.
;
pro IDLitManipVisRange::_TransformToVisualization, oVis
    compile_opt idl2, hidden

    if (not OBJ_ISA(oVis, '_IDLitVisualization')) then $
        return

    self->_SetAxisOffsets, oVis

    ; Pass along request to the contained manipulator visuals.
    self.oPan->_TransformToVisualization, oVis
    self.oZoom->_TransformToVisualization, oVis

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisRange__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisRange object.
;-
pro IDLitManipVisRange__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisRange,       $
        inherits IDLitManipulatorVisual, $ Superclass.
        oPan: OBJ_NEW(),                 $ Pan visual
        oZoom: OBJ_NEW()                 $ Zoom visual
    }
end
