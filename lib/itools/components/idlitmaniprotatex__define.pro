; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmaniprotatex__define.pro#1 $
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
; IDLitManipRotateX::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
; Parameters:
;
function IDLitManipRotateX::Init, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipRotate3D::Init(NAME='Rotate in X', $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    ; Rotations are constrained about the X axis.
    self.constrainAxis = 0

    self->IDLitManipRotateX::_DoRegisterCursor

    return, 1
end


;--------------------------------------------------------------------------
pro IDLitManipRotateX::_DoRegisterCursor

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
    self->RegisterCursor, strArray, 'Rotate in X', /DEFAULT

end


;---------------------------------------------------------------------------
; Purpose:
;   Define the base object for the manipulator
;
pro IDLitManipRotateX__Define

   compile_opt idl2, hidden

   void = {IDLitManipRotateX, $
           INHERITS IDLitManipRotate3D $
      }
end
