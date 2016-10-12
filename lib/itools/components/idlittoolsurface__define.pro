; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolsurface__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Surface object.

; CREATION:
;   See IDLitToolSurface::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitToolSurface::Init
;
; INTERFACES:
; IIDLProperty
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitToolSurface::Init, _REF_EXTRA=_EXTRA

  compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, TYPE="IDLSURFACE")) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Surface')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Surface', 'IDLitVisSurface', $
        ICON='surface'

  return, 1

end

;---------------------------------------------------------------------------
; IDLitToolSurface__Define
;
; Purpose:
;   This method defines the IDLitToolSurface class.
;

pro IDLitToolSurface__Define
  ;; Pragmas
  compile_opt idl2, hidden

  void = {IDLitToolSurface, $
          inherits IDLitToolbase $ ; Provides iTool interface
         }

end
