; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlittoolvolume__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool Volume object.
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
function IDLitToolVolume::Init, _REF_EXTRA=_EXTRA

    compile_opt idl2, hidden

    if (~self->IDLitToolbase::Init(_EXTRA=_extra, types="IDLVOLUME")) then $
        return, 0

    ;;*** File Menu

    oDesc = self->GetByIdentifier('Operations/File/New/Volume')
    if (OBJ_VALID(oDesc)) then $
        oDesc->SetProperty, ACCELERATOR='Ctrl+N'

    self->RegisterOperation, 'Open Image Stack...', 'IDLitopFileOpenImageStack', $
        DESCRIPTION='Read multiple image files into a volume', $
        IDENTIFIER='File/Open Image Stack', ICON='open'

    ;; Move the File Open Multi Operation in the container so that
    ;; it immediately follows File Open.
    oCont = self->IDLitContainer::GetByIdentifier("Operations/File/")
    oItems = oCont->Get(/all, count=count)
    FilePos = count
    FileMultiPos = count
    for i=0, count-1 do begin
        if ~OBJ_ISA(oItems[i], 'IDLitObjDescTool') then $
            continue
        oItems[i]->GetProperty, IDENTIFIER=id
        if STRUPCASE(id) eq 'OPEN' then FilePos = i
        if STRUPCASE(id) eq 'OPEN IMAGE STACK' then FileMultiPos = i
    endfor
    oCont->Move, FileMultiPos, FilePos+1

    ; Register our visualization. Since it is the first vis
    ; registered it will be the default.
    self->RegisterVisualization, 'Volume', 'IDLitVisVolume', ICON='volume'

  return, 1

end

;---------------------------------------------------------------------------
; IDLitToolVolume__Define
;
; Purpose:
;   This method defines the IDLitToolVolume class.
;

pro IDLitToolVolume__Define
    ;; Pragmas
    compile_opt idl2, hidden

    void = {IDLitToolVolume, $
          inherits IDLitToolbase $ ; Provides iTool interface
         }

end
