; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolplot__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Plot object.
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
function IDLitToolPlot::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, TYPE="IDLPLOT")) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Plot')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Plot', 'IDLitVisPlot', ICON='plot'

    return, 1

end


;---------------------------------------------------------------------------
; IDLitToolPlot__Define
;
; Purpose:
;   This method defines the IDLitToolPlot class.
;

pro IDLitToolPlot__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = { IDLitToolPlot,                     $
           inherits IDLitToolbase       $ ; Provides iTool interface
           }
end
