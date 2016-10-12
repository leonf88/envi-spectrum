; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadbmp__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadBmp class.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadTIFF object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadBmp::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if (self->IDLitReader::Init('bmp', $
        NAME='Windows Bitmap', $
        DESCRIPTION="Windows Bitmap (bmp)", $
        ICON='demo', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end


;---------------------------------------------------------------------------
; IDLitReadBmp::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadBmp::GetData, oImageData

    compile_opt idl2, hidden

    strFilename = self->GetFilename()
    if (self->Isa(strFilename) eq 0) then $
        return, 0

    image = READ_BMP(strFilename, palRed, palGreen, palBlue, /RGB)

    ; Store image data in Image Data object.
    oImageData = OBJ_NEW('IDLitDataIDLImage', $
                         NAME=FILE_BASENAME(strFilename))

    result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

    if (result eq 0) then begin
        obj_destroy,oImageData
        return, 0
    endif

    ; Store palette data in Image Data object.
    if (N_ELEMENTS(palRed) gt 0) then $
        result = oImageData->SetPalette( $
            TRANSPOSE([[palRed], [palGreen], [palBlue]]))

    return, result

end
;;---------------------------------------------------------------------------
;; IDLitReadBMP::Isa
;;
;; Purpose:
;;   Return true if the give file is a BMP
;;
;; Paramter:
;;   strFilename  - The file to check

function IDLitReadBmp::Isa, strFilename
   compile_opt idl2, hidden

   return,query_bmp(strFilename);

end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadBmp__Define
;
; Purpose:
; Class definition for the IDLitReadBmp class
;

pro IDLitReadBmp__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadBmp, $
          inherits IDLitReader $
         }
end
