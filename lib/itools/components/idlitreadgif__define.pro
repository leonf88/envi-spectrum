; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadgif__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadGif class.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadGif object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
FUNCTION IDLitReadGif::Init, _EXTRA=_extra
  compile_opt idl2, hidden

  ;; Init superclass
  IF (self->IDLitReader::Init(["gif"], $
                              NAME='Graphics Interchange Format', $
                              DESCRIPTION="Graphics Interchange Format (gif)", $
                              ICON='demo', $
                              _EXTRA=_extra) EQ 0) THEN $
    return, 0

  self._index=0
  ;; Register the index property
  self->RegisterProperty, 'IMAGE_INDEX', /INTEGER, $
                          NAME='Image index', $
                          Description='The index of the image to ' + $
                          'read from the GIF file (if multiple images exist)'
  
  return, 1

END

;;---------------------------------------------------------------------------
;; IDLitReadGif::GetProperty
;;
;; Purpose:
;;   Property method for the reader.
;;
;; Keywords:
;;   IMAGE_INDEX   - The index of the image to retrieve
;;
;;   All other keywords are passed to the super class
;;
PRO IDLItReadGif::GetProperty, $
  IMAGE_INDEX=image_index, $
  _REF_EXTRA=_extra

  compile_opt idl2, hidden

  if(arg_present(image_index))then $
    image_index= self._index

  if(n_elements(_extra) gt 0)then $
    self->IDLitReader::GetProperty, _extra=_extra

END

;;---------------------------------------------------------------------------
;; IDLitReadGif::SetProperty
;;
;; Purpose:
;;   Property method for the reader.
;;
;; Keywords:
;;   IMAGE_INDEX   - The index of the image to retrieve
;;
;;   All other keywords are passed to the super class
;;
PRO IDLItReadGif::SetProperty, $
  IMAGE_INDEX=image_index, $
  _EXTRA=_extra

  compile_opt idl2, hidden

  if(n_elements(image_index) gt 0)then $
    self._index = image_index

  if(n_elements(_extra) gt 0)then $
    self->IDLitReader::SetProperty, _extra=_extra

END

;---------------------------------------------------------------------------
; IDLitReadGif::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
FUNCTION IDLitReadGif::GetData, oImageData
  compile_opt idl2, hidden

  strFilename = self->GetFilename()
  if (self->Isa(strFilename) eq 0) then $
    return, 0

  status = Query_GIF(strFileName,sInfo)
  IF (status EQ 0) THEN return, status

  READ_GIF, strFilename, image, r, g, b, /multiple
  ;; if a frame other than the first is requested, get it
  FOR i=1,self._index DO $
    READ_GIF, strFilename, image, /multiple
  READ_GIF, /close

  ;; Store image data in Image Data object.
  oImageData = OBJ_NEW('IDLitDataIDLImage', $
                       NAME=FILE_BASENAME(strFileName))

  result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

  IF (result EQ 0) THEN $
    return, 0

  ;; Store palette data in Image Data object.
  IF (N_ELEMENTS(r) GT 0) THEN BEGIN
    palette=bytarr(3,256)
    n=(size(r,/dimensions))[0]-1
    palette[0,0:n] = r
    palette[1,0:n] = g
    palette[2,0:n] = b
    
    result = oImageData->SetPalette(palette)
  ENDIF

  return, result

END

;;---------------------------------------------------------------------------
;; IDLitReadGif::Isa
;;
;; Purpose:
;;   Method that will return true if the given file a gif.
;;
;; Paramter:
;;   strFilename  - The file to check

FUNCTION IDLitReadGif::Isa, strFilename
  compile_opt idl2, hidden

  success = QUERY_GIF(strFilename, fInfo)
   
  ;; Make sure our image index is within range.
  IF (success) THEN $
    self._index <= (fInfo.num_images - 1) > 0

  return, success

END

;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadGif__Define
;
; Purpose:
; Class definition for the IDLitReadGif class
;
PRO IDLitReadGif__Define
  compile_opt idl2, hidden

  void = {IDLitReadGif, $
          inherits IDLitReader, $
          _index : 0 $          ;image index in the file to read.
         }

END
