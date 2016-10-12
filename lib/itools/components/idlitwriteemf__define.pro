; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitwriteemf__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteEMF class.
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
; Keywords:
;   All superclass keywords.
;
function IDLitWriteEMF::Init, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    ; Init superclass
    ; The only properties that can be set at INIT time can be set
    ; in the superclass Init method.
    if(self->IDLitWriter::Init('emf', $
        NAME='Windows Enhanced Metafile', $
        TYPES=["IDLDEST"], $
        DESCRIPTION="Windows enhanced metafile", $
        ICON='demo', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    self->RegisterProperty, 'GRAPHICS_FORMAT', $
        NAME='Graphics format', $
        DESCRIPTION='Render graphics using bitmap or vector output', $
        ENUMLIST=['Bitmap','Vector']

    return, 1
end


;---------------------------------------------------------------------------
; Purpose:
; The destructor for the class.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
;pro IDLitWriteEMF::Cleanup
;    compile_opt idl2, hidden
;    ; Cleanup superclass
;    self->IDLitWriter::Cleanup
;end


;---------------------------------------------------------------------------
; Implementation
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   ImageData: An object reference to the data to be written.
;
; Keywords:
;   None.
;
function IDLitWriteEMF::SetData, oItemIn

    compile_opt idl2, hidden

    strFilename = self->GetFilename()

    ; If we are a winscene, get the scene
    oItem = OBJ_ISA(oItemIn, "_IDLitgrDest") ? $
        oItemIn->GetScene() : oItemIn

    ; Do we have to rasterize this ?
    if (OBJ_ISA(oItem, "IDLitgrScene") || $
        OBJ_ISA(oItem, "IDLitgrView")) then begin

        oTool = self->GetTool()

        ; Get the system rastor service.
        oClipCopy = oTool->GetService("SYSTEM_CLIPBOARD_COPY")
        oClipCopy->SetProperty, SCALE_FACTOR=self._scaleFactor

        ; Do the draw
        status = oClipCopy->DoWindowCopy(oTool->GetCurrentWindow(), oItem, $
            FILENAME=strFilename, POSTSCRIPT=0, VECTOR=self._graphicsFormat)
        return, status

    endif

    return, 0  ; failure
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitWriteEMF__Define

    compile_opt idl2, hidden

    void = {IDLitWriteEMF, $
        inherits IDLitWriter $
        }
end
