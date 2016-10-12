; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadpng__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadPNG class.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadPNG object.
;
function IDLitReadPNG::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    return, self->IDLitReader::Init("png", $
        NAME="Portable Network Graphics", $
        DESCRIPTION="Portable Network Graphics (png)", $
        ICON='demo', $
        _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; IDLitReadPNG::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadPNG::GetData, oImageData

    compile_opt idl2, hidden

    filename = self->GetFilename()

    if(query_png(filename, fInfo) eq 0)then $
        return, 0

    if(fInfo.has_palette)then $
      image = Read_PNG(filename, palRed, palGreen, palBlue) $
    else $
      image = Read_PNG(filename)

    ; Store image data in Image Data object.
    oImageData = OBJ_NEW('IDLitDataIDLImage', $
                         NAME=FILE_BASENAME(fileName))

    result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

    if (result eq 0) then $
        return, 0

    ; Store palette data in Image Data object.
    IF (fInfo.has_palette) THEN BEGIN
      oPal = oImageData->Get(/ALL,ISA='IDLitDataIDLPalette')
      IF obj_valid(oPal) THEN BEGIN
        result = oPal->SetData(TRANSPOSE([[palRed], [palGreen], [palBlue]]))
      ENDIF ELSE BEGIN
        oImageData->Add,obj_new('IDLitDataIDLPalette', $
                                TRANSPOSE([[palRed], [palGreen], [palBlue]]), $
                                NAME='Palette')
      ENDELSE
    ENDIF

    return, result

end
;;---------------------------------------------------------------------------
;; IDLitReadPNG::Isa
;;
;; Purpose:
;;   Return true if the given file is a PNG file
;;
;;
function IDLitReadPNG::Isa, strFilename
   compile_opt idl2, hidden

   return,query_png(strFilename);

end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadPNG__Define
;
; Purpose:
; Class definition for the IDLitReadPNG class
;

pro IDLitReadPNG__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadPNG, $
          inherits IDLitReader $
         }
end
