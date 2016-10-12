; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadtiff__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadTIFF class.
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
function IDLitReadTIFF::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if( self->IDLitReader::Init(["tiff", "tif"], $
        NAME="Tag Image File Format", $
        DESCRIPTION="Tag Image File Format (TIFF)", $
        ICON='demo', $
        _EXTRA=_extra) ne 1)then $
      return, 0

    self._index=0
    ;; Register the index property
    self->RegisterProperty, 'IMAGE_INDEX', /INTEGER, $
        NAME='Image index', $
        Description='The index of the image to read from the TIFF file'
    self._stacking=0
    self->RegisterProperty, 'IMAGE_STACKING', $
        ENUMLIST=['Read Single Image', $
            'Stack in Z (from bottom)', 'Stack in Z (from top)', $
            'Stack in X (from left)', 'Stack in X (from right)', $
            'Stack in Y (from front)', 'Stack in Y (from back)'], $
        NAME='Image Stacking', $
        DESCRIPTION='Specify stacking order for reading multi-images into volumes'

    return,1
end
;;---------------------------------------------------------------------------
;; IDLitReadTiff::GetProperty
;;
;; Purpose:
;;   Property method for the reader.
;;
;; Keywords:
;;  IMAGE_INDEX   - The index of the image to retrieve
;;
;;  All other keywords are passed to the super class
pro IDLItReadTIFF::GetProperty, $
                 IMAGE_INDEX=image_index, $
                 IMAGE_STACKING=image_stacking, $
                 _REF_EXTRA=_extra

   compile_opt idl2, hidden

   if(arg_present(image_index))then $
     image_index= self._index

   if(arg_present(image_stacking))then $
     image_stacking= self._stacking

   if(n_elements(_extra) gt 0)then $
     self->IDLitReader::GetProperty, _extra=_extra

end
;;---------------------------------------------------------------------------
;; IDLitReadTiff::SetProperty
;;
;; Purpose:
;;   Property method for the reader.
;;
;; Keywords:
;;  IMAGE_INDEX   - The index of the image to retrieve
;;
;;  All other keywords are passed to the super class

pro IDLItReadTIFF::SetProperty, $
                 IMAGE_INDEX=image_index, $
                 IMAGE_STACKING=image_stacking, $
                 _EXTRA=_extra

   compile_opt idl2, hidden

   if(n_elements(image_index) gt 0)then $
     self._index = image_index

   if(n_elements(image_stacking) gt 0)then $
     self._stacking = image_stacking

   if(n_elements(_extra) gt 0)then $
     self->IDLitReader::SetProperty, _extra=_extra

end


;---------------------------------------------------------------------------
function IDLitReadTIFF::_GetImage, filename, palRed, palGreen, palBlue, $
    GEOTIFF=geotiff, $
    IMAGE_INDEX=imageIndex

    compile_opt idl2, hidden

    if (N_PARAMS() eq 4) then begin
        image = Read_Tiff(filename, palRed, palGreen, palBlue, $
            GEOTIFF=geotiff, $
            IMAGE_INDEX=imageIndex, $
            ORIENTATION=orientation)
    endif else begin
        image = Read_Tiff(filename, $
            GEOTIFF=geotiff, $
            IMAGE_INDEX=imageIndex, $
            ORIENTATION=orientation)
    endelse

    ndim = SIZE(image, /N_DIMENSIONS)

    ; Orientations >= 5 need to be transposed.
    if (orientation ge 5) then begin
        image = (ndim eq 2) ? TRANSPOSE(image) : $
            TRANSPOSE(image, [0, 2, 1])
        orientation -= 4
    endif

    ; May need to flip one or both dimensions.
    case (orientation) of
    1: image = REVERSE(image, ndim, /OVERWRITE)
    2: image = REVERSE(REVERSE(image, ndim, /OVERWRITE), $
        ndim-1, /OVERWRITE)
    3: image = REVERSE(image, ndim-1, /OVERWRITE)
    else:
    endcase

    return, image

end


;---------------------------------------------------------------------------
; IDLitReadTIFF::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadTIFF::GetData, oImageData

    compile_opt idl2, hidden

    filename = self->GetFilename()

    if (~QUERY_TIFF(filename, fInfo)) then $
        return, 0

    ; If we have a multi-image TIFF, try to retrieve info about the specific
    ; image we want.
    if ((fInfo.num_images gt 1) && (self._index gt 0)) then begin
        if (~QUERY_TIFF(filename, fInfo, image_index=self._index)) then $
            return, 0
    endif

    ;; Read a multi-image TIFF into a volume data set
    if ((fInfo.num_images gt 1) && self._stacking) then begin

        nx = fInfo.dimensions[0]
        ny = fInfo.dimensions[1]

        for index=0, fInfo.num_images-1 do begin

            ; Only need to read the palette once.
            if (index eq 0 && fInfo.has_palette) then begin
                image = self->_GetImage(filename, palRed, palGreen, palBlue, $
                    IMAGE_INDEX=index)
            endif else begin
                image = self->_GetImage(filename, IMAGE_INDEX=index)
            endelse

            ; Construct the result variable.
            if (index eq 0) then begin
                case ((self._stacking-1)/2) of
                    0: dimensions = [nx, ny, fInfo.num_images]
                    1: dimensions = [fInfo.num_images, nx, ny]
                    2: dimensions = [nx, fInfo.num_images, ny]
                    else: MESSAGE, 'Illegal value for IMAGE_STACKING'
                endcase
                ; Use the image type in case it isn't byte data.
                vol = MAKE_ARRAY(dimensions, TYPE=SIZE(image, /TYPE))
            endif

            ; Copy each image plane into the volume.
            case self._stacking of
                ; Use "0" indexing on left-hand side for efficiency.
                1: vol[0, 0, index] = image
                2: vol[0, 0, fInfo.num_images - index - 1] = image
                3: vol[index, 0, 0] = REFORM(image, 1, nx, ny, /OVER)
                4: vol[fInfo.num_images - index - 1, 0, 0] = $
                    REFORM(image, 1, nx, ny, /OVER)
                5: vol[0, index, 0] = REFORM(image, nx, 1, ny, /OVER)
                6: vol[0, fInfo.num_images-index-1, 0] = $
                    REFORM(image, nx, 1, ny, /OVER)
            endcase

            self->StatusMessage, IDLitLangCatQuery('Status:ReadChannel') + $
                                 STRTRIM(index, 2)
        endfor

        self->StatusMessage, IDLitLangCatQuery('Status:Ready')

        ; Store image data.
        oImageData = OBJ_NEW('IDLitDataContainer', $
                             NAME="Volume Data Set")

        oVol = OBJ_NEW('IDLitDataIDLArray3D', vol, $
            NAME='Volume')
        oImageData->Add, oVol

        ; Store palette data.
        if(fInfo.has_palette) then begin
            oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                TRANSPOSE([[palRed], [palGreen], [palBlue]]), $
                NAME="Volume Palette")
            result = oImageData->SetPalette(oPalette)
        endif else $
            result = 1

    endif else begin  ;; Read a single TIFF image into an image data set.

      imageIndex = $
        (fInfo.num_images gt 1) ? self._index > 0 < (fInfo.num_images-1) : 0

        if (fInfo.has_palette) then begin
            image = self->_GetImage(filename, palRed, palGreen, palBlue, $
                IMAGE_INDEX=imageIndex, $
                GEOTIFF=geotiff)
        endif else begin
            image = self->_GetImage(filename, IMAGE_INDEX=imageIndex, $
                GEOTIFF=geotiff)
        endelse

        ; Store image data in Image Data object.
        oImageData = OBJ_NEW('IDLitDataIDLImage', $
                             NAME=FILE_BASENAME(fileName))

        result = oImageData->SetData(image, 'ImagePixels', /NO_COPY)

        if (~result) then $
            return, 0

        ; Store palette data in Image Data object.
        if (fInfo.has_palette) then $
            result = oImageData->SetPalette( $
                TRANSPOSE([[palRed], [palGreen], [palBlue]]))

        ; If we have GEOTIFF info, construct a data container
        ; and put our image and the geotiff info within it.
        if (N_TAGS(geotiff) gt 0) then begin
            oParamSet = OBJ_NEW('IDLitParameterSet', $
                NAME=FILE_BASENAME(fileName), $
                ICON='demo', $
                DESCRIPTION=fileName)
            oParamSet->Add, oImageData, PARAMETER_NAME='IMAGEPIXELS'
            oGeo = OBJ_NEW('IDLitDataIDLGeoTIFF', geotiff, $
                NAME='GeoTIFF Tags', TYPE='IDLGEOTIFF', $
                ICON='vw-list')
            oParamSet->Add, oGeo, PARAMETER_NAME='GEOTIFF'
            ; Return our parameter set.
            oImageData = oParamSet
        endif

    endelse


    return, 1

end


;;---------------------------------------------------------------------------
;; IDLitReadTIFF::Isa
;;
;; Purpose:
;;   Return true if the given file is a TIFF file
;;
;; Paramter:
;;   strFilename  - The file to check

function IDLitReadTIFF::Isa, strFilename

    compile_opt idl2, hidden

    success = QUERY_TIFF(strFilename, fInfo)

    ; Make sure our image index is within range.
    if (success) then begin
        self._index <= (fInfo.num_images - 1) > 0
        self._index >= 0
    endif

    return, success
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadTIFF__Define
;
; Purpose:
; Class definition for the IDLitReadTIFF class
;

pro IDLitReadTIFF__Define
  ; Pragmas
  compile_opt idl2, hidden

  void = {IDLitReadTIFF, $
          inherits IDLitReader, $
          _index : 0, $          ;image index in the file to read.
          _stacking : 0 $        ;image stacking method
         }
end
