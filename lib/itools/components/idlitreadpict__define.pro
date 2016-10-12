; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadpict__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadPICT class.
;
; Created by: CT, March 2003.

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitReadPICT::Init
;
; Purpose:
; The constructor of the IDLitReadPICT object.
;
; Parameters:
;
; Properties:
;
function IDLitReadPICT::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if (self->IDLitReader::Init(['pict', 'pct'], $
        NAME="Macintosh PICT", $
        DESCRIPTION="Macintosh PICT (Version 2)", $
        ICON='demo', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end


;---------------------------------------------------------------------------
; IDLitReadPICT::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadPICT::GetData, oImageData

    compile_opt idl2, hidden

    strFilename = self->GetFilename()
    if (~self->Isa(strFilename)) then $
        return, 0

    READ_PICT, strFilename, image, red, green, blue

    ; Store image data in Image Data object.
    oImageData = OBJ_NEW('IDLitDataIDLImage', $
                         NAME=FILE_BASENAME(strFileName))

    result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

    if (result eq 0) then $
        return, 0

    ; Store palette data in Image Data object.
    if (N_ELEMENTS(red) gt 0) then begin
        palette = TRANSPOSE([[red], [green], [blue]])
        result = oImageData->SetPalette(palette)
    endif

    return, result

end
;;---------------------------------------------------------------------------
;; IDLitReadPICT::Isa
;;
;; Purpose:
;;   Method that will return true if the given file a jpeg.
;;
;; Paramter:
;;   strFilename  - The file to check

function IDLitReadPICT::Isa, strFilename
   compile_opt idl2, hidden

   return, QUERY_PICT(strFilename)

end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadPICT__Define
;
; Purpose:
; Class definition for the IDLitReadPICT class
;

pro IDLitReadPICT__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadPICT, $
          inherits IDLitReader $
         }
end
