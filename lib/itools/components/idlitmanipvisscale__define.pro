; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisscale__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;
; Purpose:
;   The IDLitManipVisScale class is the scale manipulator visual.
;


;----------------------------------------------------------------------------
; Purpose:
;   This function method initializes the object.
;
; Syntax:
;   Obj = OBJ_NEW('IDLitManipVisScale')
;
;   or
;
;   Obj->[IDLitManipVisScale::]Init
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
function IDLitManipVisScale::Init, NAME=inName, TOOL=tool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "Scale Visual"

    ; Initialize superclasses.
    if (self->IDLitManipVisSelect::Init( $
        NAME=name, $
        VISUAL_TYPE='Select', $
        _EXTRA=_extra) ne 1) then $
        return, 0

    ; Scale in two dimensions.
    self.oVis2D = OBJ_NEW('IDLitManipVisScale2D', TOOL=tool)
    ; Scale in three dimensions.
    self.oVis3D = OBJ_NEW('IDLitManipVisScale3D', TOOL=tool)
    ; Default
    self.oVis = self.oVis2D
    self->Add, self.oVis

    ; Set any properties.
    self->IDLitManipVisScale::SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   This function method returns the type of the sub-element of this
;   visual hit in the provided selection list.
;
;   This specialized implementation of this method maps the standard
;   manipulator visual type to a specialized type in the case that the
;   target manipulator has been rotated.  In this case, an appropriate
;   cursor may be appropriate (see IDLitManipScale::GetCursorType).
;
; Arguments:
;   oSubHitList - The sub-selection list returned from a call to
;                 DoHitTest
;
function IDLitManipVisScale::GetSubHitType, oSubHitList

    compile_opt idl2, hidden

    type = self->IDLitManipulatorVisual::GetSubHitType(oSubHitList)
    switch type of
         'Scale/+X':
         'Scale/-X':
         'Scale/+Y':
         'Scale/-Y':
       'Scale/+X+Y':
       'Scale/-X-Y':
       'Scale/-X+Y':
       'Scale/+X-Y': begin & bHandleRot = 1b & break & end
         else: bHandleRot = 0b
    endswitch

    ; Only handle rotation for 2D scale visuals.
    if (bHandleRot ne 0b) then begin
        ; Target visualization has been rotated in 2D.
        ; Map the type to an appropriate cursor for the current rotation.

        ; Get the manipulator target.
        oVis = OBJ_ISA(oSubHitList[0], '_IDLitvisualization') ? $
            oSubHitList[0]->GetManipulatorTarget() : OBJ_NEW()
        if (OBJ_VALID(oVis)) then begin
            ; Convert from the transform matrix back to a Z rotation.
            ; This takes into account translations and scaling,
            ; but assume no rotations have ever occurred about X or Y.
            ; Should this be a GetCTM instead, in case the parent is rotated?
            oVis->GetProperty, TRANSFORM=transform
            ; Rotate an x-unit vector, and find its angle relative
            ; to the X axis.
            xrotate = transform ## [1d,0,0,0]
            angle = (180/!DPI)*ATAN(xrotate[1], xrotate[0])
            angle = ROUND(angle)

            if (((angle gt 45) && (angle lt 135)) || $
                ((angle lt -45) && (angle gt -135))) then $
                type = type+'_ROT'
        endif
    endif

    return, type
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
;-
pro IDLitManipVisScale::Cleanup
    compile_opt idl2, hidden

    OBJ_DESTROY, [self.oVis2d, self.oVis3d]
    
    ; Cleanup superclasses.
    self->IDLitManipVisSelect::Cleanup

end


;---------------------------------------------------------------------------
pro IDLitManipVisScale::Set3D, is3D
    compile_opt idl2, hidden


    oVis = OBJ_NEW()

    if is3D then begin
        if (OBJ_ISA(self.oVis, 'IDLitManipVisScale2D')) then $
            oVis = self.oVis3D  ;OBJ_NEW('IDLitManipVisScale3D')
    endif else begin
      self.oVis = self.oVis2d
        if (OBJ_ISA(self.oVis, 'IDLitManipVisScale3D')) then $
            oVis = self.oVis2D  ;OBJ_NEW('IDLitManipVisScale2D')
    endelse

    ; Remove the old and add the new vis.
    if (OBJ_VALID(oVis)) then begin
        OBJ_DESTROY, self.oVis
        self->Remove, self.oVis
        self->Add, oVis
        self.oVis = oVis
    endif

    ; Turn on/off manipulators for Z if necessary.
    ; Call superclass.
    self->IDLitManipVisSelect::Set3D, is3D

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisScale__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisScale object.
;-
pro IDLitManipVisScale__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisScale, $
        inherits IDLitManipVisSelect, $
        oVis: OBJ_NEW(), $
        oVis2D: OBJ_NEW(), $
        oVis3D: OBJ_NEW() $
        }
end
