; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolcontour__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Contour object.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitToolContour::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, TYPE="IDLCONTOUR")) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Contour')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

   ; Change the name of our Rotate container to "Rotate or Flip".
   oRotate = self->GetByIdentifier('Operations/Operations/Rotate')
   oRotate->SetProperty, NAME='Rotate or Flip'

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Contour', 'IDLitVisContour', ICON='contour'

    return, 1

end


;---------------------------------------------------------------------------
; IDLitToolContour__Define
;
; Purpose:
;   This method defines the IDLitToolContour class.
;

pro IDLitToolContour__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = { IDLitToolContour,                     $
           inherits IDLitToolbase       $ ; Provides iTool interface
           }
end
