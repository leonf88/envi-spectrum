; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadjpeg__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadJpeg class.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadJpeg object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadJpeg::Init, _EXTRA=_extra
  compile_opt idl2, hidden

  ; Init superclass
  if (self->IDLitReader::Init(['jpg','jpeg'], $
      NAME='Joint Photographic Experts Group', $
      DESCRIPTION="Joint Photographic Experts Group (jpeg)", $
      ICON='demo', $
      _EXTRA=_extra) eq 0) then $
      return, 0

  return, 1
end


;---------------------------------------------------------------------------
; IDLitReadJpeg::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadJpeg::GetData, oImageData
  compile_opt idl2, hidden
  
  strFilename = self->GetFilename()
  if (self->Isa(strFilename) eq 0) then $
    return, 0
    
  status = Query_JPEG(strFileName,sInfo)
  if(status eq 0)then return, status
  
  if(sInfo.channels eq 3)then  $
    READ_JPEG, strFilename, image $;, true=3 $
  else $
    READ_JPEG, strFilename, image, pal
  ; Store image data in Image Data object.
  oImageData = OBJ_NEW('IDLitDataIDLImage', $
    NAME=FILE_BASENAME(strFileName))
    
  result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)
  
  if (result eq 0) then $
    return, 0
    
  ; Store palette data in Image Data object.
  if (N_ELEMENTS(pal) gt 0) then begin
    ;; KDB - There is a bug in the image object that
    ;;       requires palettes to be 256. The following
    ;;       will work around this.
  
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
;; IDLitReadJPeg::Isa
;;
;; Purpose:
;;   Method that will return true if the given file a jpeg.
;;
;; Paramter:
;;   strFilename  - The file to check

function IDLitReadJpeg::Isa, strFilename
  compile_opt idl2, hidden

  return, query_jpeg(strFilename);
end

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadJpeg__Define
;
; Purpose:
; Class definition for the IDLitReadJpeg class
;

pro IDLitReadJpeg__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadJpeg, $
          inherits IDLitReader $
         }
end
