; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprotatez__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   Constrained rotation manipulator.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipRotateZ::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;
function IDLitManipRotateZ::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipRotate3D::Init(NAME='Rotate in Z', $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Rotations are constrained about the Z axis.
    self.constrainAxis = 2
    self->IDLitManipRotateZ::_DoRegisterCursor

    return, 1
end


;--------------------------------------------------------------------------
pro IDLitManipRotateZ::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '       .        ', $
        '      .#.       ', $
        '   .  .#.       ', $
        '  .#. .#.       ', $
        ' .##...#...     ', $
        '.$####.#.##.    ', $
        ' .##...#...#.   ', $
        '  .#. .#.  .#.  ', $
        '   .  .#.  .#.  ', $
        '  .   .#.  .#.  ', $
        ' .#.  .#.  .#.  ', $
        ' .#.   .   .#.  ', $
        '  .#.     .#.   ', $
        '   .#.....#.    ', $
        '    .#####.     ', $
        '     .....      ']
    self->RegisterCursor, strArray, 'Rotate in Z',/DEFAULT
end


;---------------------------------------------------------------------------
; Purpose:
;   Define the base object for the manipulator
;
pro IDLitManipRotateZ__Define

   compile_opt idl2, hidden

   void = {IDLitManipRotateZ, $
           INHERITS IDLitManipRotate3D $
      }
end
