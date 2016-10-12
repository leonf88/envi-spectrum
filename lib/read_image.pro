; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_image.pro#1 $
;
; Copyright (c) 1998-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;	READ_IMAGE
;
; PURPOSE:
;       The READ_IMAGE function reads the image contents of a file and
;       returns the image in an IDL variable. If the image contains a
;       palette it can be returned as well in three IDL variables.
;       READ_IMAGE returns the image in the form of a 2D array (for
;       grayscale images) or a (3, n, m) array (for true-color images.
;       READ_IMAGE can read most types of image files supported by IDL.
;       See QUERY_IMAGE for a list of supported formats.
;
; CATEGORY:
;       Input/Output
;
; CALLING SEQUENCE:
;       Result = READ_IMAGE(Filename [, Red, Green, Blue])
;
; INPUTS:
;	Filename: A scalar string containing the name of the file to read.
;
; OUTPUTS;
;       Red: A named variable to receive the red channel of the color
;            table if a colortable exists.
;
;       Green: A named variable to receive the green channel of the color
;            table if a colortable exists.
;
;       Blue: A named variable to receive the blue channel of the color
;            table if a colortable exists.
;
; OPTIONAL KEYWORDS:
;
;       IMAGE_INDEX - Set this keyword to the index of the image to read
;                     from the file.  The default is 0, the first image.
;
; OUTPUTS:
;	This function returns the selected image array. The default
;       is 0, the first image.
;
; EXAMPLE:
;       myImage = READ_IMAGE()
;
; MODIFICATION HISTORY:
; 	Written by:	Scott Lasica, July, 1998
;   CT, RSI, April 2004: Added JPEG2000 support.
;-
;

function READ_IMAGE, filename, red, green, blue, $
    IMAGE_INDEX = iIndex, $
    PLANARCONFIG=planar, $  ; needed for TIFF
    PALETTE=palette, $
    _REF_EXTRA=_extra

  compile_opt hidden
  ON_ERROR, 2         ; return to caller if error

  if (N_ELEMENTS(iIndex) eq 0) then begin
     iIndex=0
  endif else iIndex=(iIndex>0)

  if (not QUERY_IMAGE(filename, CHANNELS=chans, HAS_PALETTE=pal, $
                      IMAGE_INDEX=iIndex, TYPE=iType, $
                      NUM_IMAGES=nImages)) then begin
    MESSAGE,'Not a valid image file: '+STRTRIM(STRING(filename),2),/CONTINUE
    return, -1
  endif

  if (iIndex ge nImages) then begin
    MESSAGE,'Invalid image index: '+STRTRIM(STRING(iIndex),2),/CONTINUE
    return, -1
  endif

  case iType of

    'BMP':   iRet = READ_BMP(filename, red, green, blue, /RGB)

    'GIF':   READ_GIF, filename, iRet, red, green, blue

    'JPEG':  READ_JPEG, filename, iRet, _EXTRA=_extra

    'PNG':   iRet = READ_PNG(filename, red, green, blue, _EXTRA=_extra)

    'PPM':   READ_PPM, filename, iRet, _EXTRA=_extra

    'SRF':   READ_SRF, filename, iRet, red, green, blue

    'TIFF':  BEGIN
    	iRet = READ_TIFF(filename, red, green, blue, IMAGE_INDEX=iIndex, $
    		PLANARCONFIG=planar, _EXTRA=_extra)
    	IF (planar EQ 2) AND (N_ELEMENTS(iRet) EQ 1) THEN BEGIN
    	; convert RGB planes to pixel-interleave
    		dim = [1,SIZE(red,/DIMENSIONS)]
    		iRet = [REFORM(TEMPORARY(red),dim), $
    			REFORM(TEMPORARY(green),dim), $
    			REFORM(TEMPORARY(blue),dim)]
    	ENDIF
    	END

    'DICOM': iRet = READ_DICOM(filename, red, green, blue, IMAGE_INDEX=iIndex)

    'JPEG2000': iRet = READ_JPEG2000(filename, red, green, blue, $
        _EXTRA=_extra)

  endcase

  ;; There are situations where a file could pass the query, but an image
  ;; couldn't be read.
  if (N_ELEMENTS(iRet) eq 0) then iRet = -1

  if (arg_present(palette) && (N_ELEMENTS(red) ne 0) && $
      (N_ELEMENTS(green) ne 0) && (N_ELEMENTS(blue) ne 0)) then begin
    palette = TRANSPOSE([[red], [green], [blue]])
  endif
  
  return, iRet
end
