; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprotatey__define.pro#1 $
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
; IDLitManipRotateY::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;
function IDLitManipRotateY::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipRotate3D::Init(NAME='Rotate in Y', $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Rotations are constrained about the Y axis.
    self.constrainAxis = 1
    self->IDLitManipRotateY::_DoRegisterCursor

    return, 1
end


;--------------------------------------------------------------------------
pro IDLitManipRotateY::_DoRegisterCursor

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
    self->RegisterCursor, strArray, 'Rotate in Y', /DEFAULT
end


;---------------------------------------------------------------------------
; Purpose:
;   Define the base object for the manipulator
;
pro IDLitManipRotateY__Define

   compile_opt idl2, hidden

   void = {IDLitManipRotateY, $
           INHERITS IDLitManipRotate3D $
      }
end
