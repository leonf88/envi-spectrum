; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/framework/idlitmanipulatorvisual__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipulatorVisual
;
; PURPOSE:
;   The IDLitManipulatorVisual class represents a collection of graphics
;   and/or other visualizations that as a group serve as a visual
;   representation for data.
;
;-


;----------------------------------------------------------------------------
; Purpose:
;   The IDLitManipulatorVisual::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipulatorVisual')
;
;   or
;
;   Obj->[IDLitManipulatorVisual::]Init
;
; Arguments:
;   None.
;
; Keywords:
;   VISUAL_TYPE (Get, Set):
;
; OUTPUTS:
;
;-
function IDLitManipulatorVisual::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclasses.
    ; Default is to have this ManipulatorVisual be the Select Target.
    ; Hide ourself using private.
    success = self->_IDLitVisualization::Init(/SELECT_TARGET, $
        IMPACTS_RANGE=0, /PRIVATE, _EXTRA=_extra)

    if (not success) then $
        RETURN, 0

    ; Request no axes.
    self->SetAxesRequest, 0, /ALWAYS

    ; Set any properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitManipulatorVisual::SetProperty, _EXTRA=_extra

    RETURN, 1
end


;----------------------------------------------------------------------------
; PURPOSE:
;      The IDLitManipulatorVisual::Cleanup procedure method preforms all cleanup
;      on the object.
;
;pro IDLitManipulatorVisual::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclasses.
;    self->_IDLitVisualization::Cleanup
;end


;----------------------------------------------------------------------------
; IDLitManipulatorVisual::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitManipulatorVisual::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Request no axes.
        self.axesRequest = 0 ; No request for axes
        self.axesMethod = 0 ; Never request axes
    endif
end

;----------------------------------------------------------------------------
; Purpose:
;   This private procedure method transforms the selection visual
;   to the size and position of a visualization, not including
;   the visualization's model transform. (Since the manipulator visual
;   is being added to the visualization, it will pick up the model transform
;   for "free").
;
; Arguments:
;   Visualization: Set this argument to the object reference of the
;       IDLitVisualization that you wish to use when transforming
;       the scale and location of the selection visual.
;
; Keywords:
;   None.
;
pro IDLitManipulatorVisual::_TransformToVisualization, oVis

    compile_opt idl2, hidden

    if (not OBJ_ISA(oVis, '_IDLitVisualization')) then $
        return

    ; Use the private method to retrieve the center of rotation,
    ; and the view volume simultaneously.
    ; This avoids a separate call to GetXYZRange.
    centerRotation = oVis->GetCenterRotation(/NO_TRANSFORM, $
        /INCLUDE_AXES, $
        XRANGE=xRange, $
        YRANGE=yRange, $
        ZRANGE=zRange)

    ; Convert the viz range to window coordinates.
    vizIn = [ $
        [xRange[0], yRange[0], zRange[0]], $   ; X left corner
        [xRange[1], yRange[0], zRange[0]], $   ; X right corner
        [xRange[0], yRange[1], zRange[0]], $   ; Y top corner
        [xRange[0], yRange[0], zRange[1]] ]    ; Z top corner

    ; Do not use NO_TRANSFORM.
    oVis->_IDLitVisualization::VisToWindow, vizIn, winOut

    ; Find the Window dimensions.
    dx = ABS(winOut[0, 1] - winOut[0, 0])   ; X window range
    dy = ABS(winOut[1, 2] - winOut[1, 0])   ; Y window range
    dz = ABS(winOut[2, 3] - winOut[2, 0])   ; Z window range

    maxDx = MAX(winOut[0,*], MIN=mn) - mn   ; X window range
    maxDy = MAX(winOut[1,*], MIN=mn) - mn   ; Y window range

    if (maxDx ge 1 || maxDy ge 1) then begin
        ; Scale the selection visual to the size of the visualization.
        ; This assumes that the selection visual extends from -1 to +1.
        scaleX = ABS(xRange[1] - xRange[0])/2
        scaleY = ABS(yRange[1] - yRange[0])/2
        scaleZ = ABS(zRange[1] - zRange[0])/2
    endif else begin
        ; If our window dimensions are less than 1 pixel, then find
        ; the minimum scaling necessary to make them at least 1 pixel.
        dx = 1d
        dy = 1d
        maxDx = 1d
        maxDy = 1d
        x = winOut[0,0]
        y = winOut[1,0]
        z = winOut[2,0]
        ; Only bump up the Z coord if we had some Z depth.
        winIn = [ $
            [x, y, z], $
            [x+1, y, z], $
            [x, y+1, z], $
            [x, y, z + (dz ne 0)]]
        oVis->_IDLitVisualization::WindowToVis, winIn, vizOut
        scaleX = ABS(vizOut[0, 1] - vizOut[0, 0])
        scaleY = ABS(vizOut[1, 2] - vizOut[1, 0])
        scaleZ = ABS(vizOut[2, 3] - vizOut[2, 0])
    endelse



    ; Enforce a minimum size for the selection visuals, by finding the
    ; window size in pixels of the selected vis, and then scaling the
    ; selection visual up if it is smaller than the minimum.
    minSize = 20d  ; pixels

    oVis->GetProperty, SELECTION_PAD=selectionPad

    ; Make sure my 3D flag matches the selected visualizations flag.
    ; The call to Set3D must not be set to IDLitManipulatorVisual::Set3D.
    ; It is designed so that my subclasses can override Set3D, and take
    ; appropriate action, such as enabling constrained manipulations.
    is3D = oVis->Is3D()
    if (is3D ne self->Is3D()) then $
        self->Set3D, is3D


    if (self._uniformScale) then begin  ; uniform scaling (e.g. rotation ball)

        if (is3D) then begin

            ; For 3D, scale using the data coordinates.
            ; Scale equally in all 3 dimensions, up to the size of the
            ; largest dimension.
;            scale = (scaleX > scaleY > scaleZ)
;            scaleX = scale
;            scaleY = scale
;            if (scaleZ ne 0) then $
;                scaleZ = scale

        endif else begin

            ; For 2D, scale using the window coordinates.
            if (dx ge dy) then $
                scaleY *= (dx/dy) $
            else $
                scaleX *= (dy/dx)

        endelse

        ; Find the largest dimensions in X and Y.
        maxx = maxDx < maxDy

        ; If necessary, scale the 3 dimensions up to the minimum size.
        if (maxx lt minSize) && (maxx ne 0) then begin
            scale = (minSize/maxx) > 1
            scaleX *= scale
            scaleY *= scale
            scaleZ *= scale
        endif

        if (selectionPad gt 0) then begin
            scaleX = scaleX*1.15
            scaleY = scaleY*1.15
            scaleZ = scaleZ*1.15
        endif

    endif else begin   ; non-uniform scaling (e.g. selection box)


        if (is3D) then begin

            ; If necessary, scale the dimensions up to the minimum size.
            if (maxDx lt minSize) && (maxDx ne 0) then $
                scaleX *= (minSize/maxDx)
            if (maxDy lt minSize) && (maxDy ne 0) then $
                scaleY *= (minSize/maxDy)
            if (selectionPad gt 0) then begin
                scaleX = scaleX*1.15
                scaleY = scaleY*1.15
                scaleZ = scaleZ*1.15
            endif

        endif else begin

            ; If 2D, just add a pixel border all around the viz.
            if (selectionPad gt 0) then begin
                if (maxDx ne 0) then $
                    scaleX *= (maxDx + 2*selectionPad)/maxDx
                if (maxDy ne 0) then $
                    scaleY *= (maxDy + 2*selectionPad)/maxDy
            endif

        endelse


    endelse



    ; Cannot allow zero scaling.
    if (scaleX eq 0) then scaleX = 1
    if (scaleY eq 0) then scaleY = 1
    if (scaleZ eq 0) then scaleZ = 1


    ; Reset the transform matrix for the selection visual to identity.
    self->Reset

    self->Scale, scaleX, scaleY, scaleZ

    ; Translate the selection visual to the location of ourself.
    ; This assumes that the center of the selection visual is at [0,0,0].
    self->Translate, $
        centerRotation[0], centerRotation[1], centerRotation[2]

end


;---------------------------------------------------------------------------
; Purpose:
;    Return the type of the sub-element of this visual hit in the
;    provided selection list.
;
;    Note: assumes that the given selection list is only for one selected
;    visualization "tree".
;
; Syntax:
;    type = obj->GetSubHitType(oSubHitList)
;
; Result:
;   The type (string) of the hit sub-selection visual item.
;   '' if nothing was hit or the provided arguements are invalid.
;
; Arguments:
;   oSubHitList - The sub-selection list returned from a call to
;                 DoHitTest
;
; Keywords:
;   None.
;
function IDLitManipulatorVisual::GetSubHitType, oSubHitList

    compile_opt idl2, hidden

    ;; Check intput validity.
    if(n_elements(oSubHitList) eq 0)then $
      return ,''

    ;; If this selection visual is not in the list. Return no type
;    if (TOTAL(self eq oSubHitList) eq 0) then $
;        return, ''

    ;; Ok , this selection visual is in the sub-hit list. Walk up the
    ;; list from the end and grab the type of the first selection
    ;; visual that is hit.
    for i=n_elements(oSubHitList)-1, 0, -1 do begin
        if (OBJ_ISA(oSubHitList[i], "IDLitManipulatorVisual")) then begin
            oSubHitList[i]->GetProperty, VISUAL_TYPE=type
            return, type
        endif
    endfor

    return, '' ;; Should never get here.
end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Purpose:
;   Overrides the superclass GetProperty method and retrieve properties
;   of the IDLitManipulatorVisual.
;
; Arguments:
;   None.
;
; Keywords:
;
PRO IDLitManipulatorVisual::GetProperty, $
    VISUAL_TYPE=strVisualType, $
    UNIFORM_SCALE=uniformScale, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    if (ARG_PRESENT(strVisualType)) then $
        strVisualType = self._strVisualType

    if (ARG_PRESENT(uniformScale)) then $
        uniformScale = self._uniformScale

    ; get superclass properties
    if (N_ELEMENTS(super) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=super

END


;----------------------------------------------------------------------------
; Purpose:
;   Overrides the superclass SetProperty method and sets properties
;   of the IDLitManipulatorVisual.
;
; Arguments:
;   None.
;
; Keywords:
;
PRO IDLitManipulatorVisual::SetProperty, $
    VISUAL_TYPE=strVisualType, $
    UNIFORM_SCALE=uniformScale, $
    _REF_EXTRA=super

    compile_opt idl2, hidden

    if (N_ELEMENTS(strVisualType) gt 0) then $
        self._strVisualType = strVisualType

    if (N_ELEMENTS(uniformScale) gt 0) then $
        self._uniformScale = uniformScale

; Set superclass properties
    if (N_ELEMENTS(super) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=super

END


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; Purpose:
;   Defines the object structure for an IDLitManipulatorVisual object.
;
pro IDLitManipulatorVisual__Define

    compile_opt idl2, hidden

    struct = { IDLitManipulatorVisual, $
        INHERITS _IDLitVisualization, $
        _strVisualType: '', $
        _uniformScale: 0b $
        }
end
