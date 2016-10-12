; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolimage__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Image object.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitToolbase
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitToolImage::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitToolImage::Init
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitToolImage::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, TYPES="IDLIMAGE")) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Image')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    ; Register graphics customization operation.
    self->RegisterCustomization, 'Image Tool Customization', $
        /PRIVATE, $ ; hide in macro editor tree view
        'IDLitopCustomizeImageTool'

    ; Operations Menu

    ; Change the name of our Rotate container to "Rotate or Flip".
    oRotate = self->GetByIdentifier('Operations/Operations/Rotate')
    oRotate->SetProperty, NAME='Rotate or Flip'

    ;-----------------

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Image', 'IDLitVisImage', ICON='demo'

    return, 1

end


;---------------------------------------------------------------------------
; IDLitToolImage__Define
;
; Purpose:
;   This method defines the IDLitToolImage class.
;

pro IDLitToolImage__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = { IDLitToolImage,                     $
           inherits IDLitToolbase       $ ; Provides iTool interface
           }
end
