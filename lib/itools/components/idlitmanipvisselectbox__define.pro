; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitmanipvisselectbox__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipVisSelectBox
;
; PURPOSE:
;   The IDLitManipVisSelectBox class is the selection visual.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLgrModel
;
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitManipVisSelectBox::Init
;
; PURPOSE:
;   The IDLitManipVisSelectBox::Init function method initializes this
;   component object.
;
;   NOTE: Init methods are special lifecycle methods, and as such
;   cannot be called outside the context of object creation.  This
;   means that in most cases, you cannot call the Init method
;   directly.  There is one exception to this rule: If you write
;   your own subclass of this class, you can call the Init method
;   from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;   Obj = OBJ_NEW('IDLitManipVisSelectBox')
;
;   or
;
;   Obj->[IDLitManipVisSelectBox::]Init
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
;-
function IDLitManipVisSelectBox::Init, NAME=inName, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Prepare default name.
    name = (N_ELEMENTS(inName) ne 0) ? inName : "SelectBox Visual"

    ; Initialize superclasses.
    if (self->IDLitManipVisSelect::Init( $
        NAME=name, $
        VISUAL_TYPE='Select') ne 1) then $
        return, 0

    self->Add, OBJ_NEW('IDLgrPolyline', $
        DATA=[[-1,-1],[1,-1],[1,1],[-1,1],[-1,-1]], $
        POLYLINE=[5, 0, 1, 2, 3, 4], $
        ALPHA_CHANNEL=0.2, $
        COLOR=!COLOR.DODGER_BLUE, $
        _EXTRA=_extra)

    ; Set any properties.
    self->IDLitManipVisSelectBox::SetProperty, _EXTRA=_extra

    return, 1
end


;----------------------------------------------------------------------------
; Purpose:
;   The IDLitManipVisSelectBox::Cleanup procedure method preforms all cleanup
;   on the object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitManipVisSelectBox::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclasses.
;    self->IDLitManipVisSelect::Cleanup
;end


;----------------------------------------------------------------------------
; Purpose:
;   Overrides the superclass' method.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to IDLgrPolyline and to our superclass.
;
pro IDLitManipVisSelectBox::GetProperty, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Retrieve our polyline properties.
    oPolyline = self->Get()
    oPolyline->GetProperty, _EXTRA=_extra

    ; Pass on to superclass.
    self->IDLitManipVisSelect::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Purpose:
;   Overrides the superclass' method.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to IDLgrPolyline and to our superclass.
;
pro IDLitManipVisSelectBox::SetProperty, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Modify our polyline properties.
    oPolyline = self->Get()
    oPolyline->SetProperty, _EXTRA=_extra

    ; Pass on to superclass.
    self->IDLitManipVisSelect::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
pro IDLitManipVisSelectBox::Set3D, is3D

    compile_opt idl2, hidden

    oPolyline = self->Get()

    case is3D of

        0: begin
            data = [[-1,-1],[1,-1],[1,1],[-1,1],[-1,-1]]
            polyline = [5, 0, 1, 2, 3, 4]
           end

        1: begin
            data = [ $
                ; Bottom edges
                [-1,-1,-1], $
                [ 1,-1,-1], $
                [ 1, 1,-1], $
                [-1, 1,-1], $
                [-1,-1,-1], $
                ; Top edges
                [-1,-1, 1], $
                [ 1,-1, 1], $
                [ 1, 1, 1], $
                [-1, 1, 1], $
                [-1,-1, 1], $
                ; Side edges
                [-1,-1,-1], $
                [-1,-1, 1], $
                [ 1,-1,-1], $
                [ 1,-1, 1], $
                [-1, 1,-1], $
                [-1, 1, 1], $
                [ 1, 1,-1], $
                [ 1, 1, 1]]

            polyline = [ $
                5, 0, 1, 2, 3, 4, $
                5, 5, 6, 7, 8, 9, $
                2, 10, 11, $
                2, 12, 13, $
                2, 14, 15, $
                2, 16, 17]
            end

        else: return
    endcase

    oPolyline->SetProperty, DATA=data, POLYLINE=polyline

    ; Call superclass.
    self->IDLitManipVisSelect::Set3D, is3D

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitManipVisSelectBox__Define
;
; Purpose:
;   Defines the object structure for an IDLitManipVisSelectBox object.
;-
pro IDLitManipVisSelectBox__Define

    compile_opt idl2, hidden

    struct = { IDLitManipVisSelectBox, $
        inherits IDLitManipVisSelect $
        }
end
