; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolmap__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Map object.
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
;   See IDLitToolMap::Init
;
; METHODS:
;   This class has the following methods:
;
;   IDLitToolMap::Init
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitToolMap::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, $
        TYPES=["IDLMAP"])) then $
        return, 0

    oDesc = self->GetByIdentifier('Operations/File/New/Map')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Image', 'IDLitVisImage', ICON='demo'

    return, 1

end


;---------------------------------------------------------------------------
; IDLitToolMap__Define
;
; Purpose:
;   This method defines the IDLitToolMap class.
;
pro IDLitToolMap__Define

    compile_opt idl2, hidden

    void = { IDLitToolMap,                     $
           inherits IDLitToolbase       $ ; Provides iTool interface
           }
end
