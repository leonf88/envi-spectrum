; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreaddicom__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadDicom class.
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
function IDLitReadDicom::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if (self->IDLitReader::Init("dcm", $
        NAME='DICOM Image', $
        DESCRIPTION="DICOM (dcm)", $
        ICON='demo', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end


;---------------------------------------------------------------------------
; IDLitReadDicom::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadDicom::GetData, oImageData

    compile_opt idl2, hidden

    strFilename = self->GetFilename()
    if (self->Isa(strFilename) eq 0) then $
        return, 0

    status = Query_DICOM(strFileName,sInfo)
    if(status eq 0)then return, status

    if(sInfo.channels eq 3) then  $
      image = READ_DICOM(strFilename, red, green, blue) $
    else $
      image = READ_DICOM(strFilename)

    ; Store image data in Image Data object.
    oImageData = OBJ_NEW('IDLitDataIDLImage', $
                         NAME=FILE_BASENAME(strFileName))

    result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

    if (result eq 0) then $
        return, 0

    ; Store palette data in Image Data object.
    if (N_ELEMENTS(pal) gt 0) then begin
        ;; KDB - There is a bug in the image object that
;;                       requires palettes to be 256. The following
;;                       will work around this.

        pal = transpose(pal)
        palette=bytarr(3,256)
        n=(size(pal,/dimensions))[1]-1
        palette[0,0:n]=pal[0,*]
        palette[1,0:n]=pal[1,*]
        palette[2,0:n]=pal[2,*]

        result = oImageData->SetPalette(palette)
    endif
    return, result

end
;;---------------------------------------------------------------------------
;; IDLitReadDICOM::Isa
;;
;; Purpose:
;;   Method that will return true if the given file is DICOM.
;;
;; Paramter:
;;   strFilename  - The file to check

function IDLitReadDICOM::Isa, strFilename
   compile_opt idl2, hidden

   return,query_dicom(strFilename);

end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadDicom__Define
;
; Purpose:
; Class definition for the IDLitReadDicom class
;

pro IDLitReadDicom__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadDicom, $
          inherits IDLitReader $
         }
end
