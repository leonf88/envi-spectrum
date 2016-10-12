; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_image.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;
;+
; NAME:
;   QUERY_IMAGE
;
; PURPOSE:
;   Read the header of an file and determine if it is recognized as an
;   image file.  If it is an image file retrieve a structure containing
;   information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_IMAGE([File, Info])
;
; INPUTS:
;   File:   Scalar string containing the name of the file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  Set this keyword to the index of the image to query
;       from the file.  The default is 0, the first image.
;
; Keyword Outputs:
;   CHANNELS:  Set this keyword to a named variable to retrieve the number
;       of channels in the image.
;   DIMENSIONS:  Set this keyword to a named variable to retrieve the IDL
;       Type code of the image pixel format.  See the documentation for
;       the SIZE routine for a complete list of IDL Type Codes.  The valid
;       types for PIXEL_TYPE are:
;     1    Byte
;     2    Integer
;     3    Longword Integer
;     4    Floating Point
;     5    Double-precision Floating Point
;     12   Unsigned Integer
;     13   Unsigned Longword Integer
;     14   64-bit Integer
;     15   Unsigned 64-bit Integer
;   HAS_PALETTE:  Set this keyword to a named variable to retrieve a
;       value that is true if a palette is present.
;   NUM_IMAGES:  Set this keyword to a named variable to retrieve the number
;       of images in the file.
;   PIXEL_TYPE:  Set this keyword to a named variable to retrieve the IDL
;       basic type code for a pixel sample.
;   SUPPORTED_READ:  Set this keyword to a named variable to retrieve a
;       string array of image types supported by READ_IMAGE.  If the
;       SUPPORTED_READ keyword is used the filename and info arguments
;       are optional.
;   SUPPORTED_WRITE:  Set this keyword to a named variable to retrieve a
;       string array of image types supported by WRITE_IMAGE.  If the
;       SUPPORTED_WRITE keyword is used the filename and info arguments
;       are optional.
;   TYPE:  Set this keyword to a named variable to retrieve a string
;       identifying the file format.  Valid Type values are:
;     'BMP'
;     'GIF'
;     'JPEG'
;     'PNG'
;     'PPM'
;     'SRF'
;     'TIFF'
;     'DICOM'
;       'JPEG2000'
;
; OUTPUTS:
;   Result is a long with the value of 1 if the query was successful (the
;   file was recognized as an image file) or 0 on failure.  The return
;   status will indicate failure for files that contain formats that are
;   not supported by the corresponding READ_ routine, even though the file
;   may be valid outside the IDL environment.
;
;   Info:   An anonymous structure containing information about the image.
;       This structure is valid only when the return value of the function
;       is 1.  The Info structure for all image types has the following
;       fields:
;
;           Field       IDL data type   Description
;           -----       -------------   -----------
;           CHANNELS    Long            Number of samples per pixel
;           DIMENSIONS  2-D long array  Size of the image in pixels
;           HAS_PALETTE Integer         True if a palette is present
;           NUM_IMAGES  Long            Number of images in the file
;           IMAGE_INDEX Long            Image number for this struct
;           PIXEL_TYPE  Integer         IDL basic type code for a pixel sample
;           TYPE        String          String identifying the file format
;
;       If the file is recognized as a PPM file the Info structure will
;       contain the additional field:
;
;           MAXVAL      Long            The maximum pixel value in the image.
;
;       If the file is recognized as a TIFF file the Info structure will
;       contain the additional field:
;
;           PLANAR_CONFIG   Long        Equal to 2 if the image has been stored
;                                       as separate images for the red, green
;                                       and blue planes.  See the documentation
;                                       for READ_TIFF for details on reading
;                                       a TIFF image stored with PLANAR_CONFIG
;                                       set to 2.
;
; EXAMPLE:
;   To retrieve information from the image file named "foo.bmp"
;   in the current directory, enter:
;
;       result = QUERY_IMAGE("foo.bmp", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'Image file not found or file is not a valid image format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written June 1998, ACY
;   Modified February 2000, JLP - Continue query if suffix match fails
;   CT, RSI, May 2004: Added JPEG2000 support. Add GIF support back in.
;
;-
FUNCTION QUERY_IMAGE, filename, info, $
   CHANNELS=channels, $
   DIMENSIONS=dimensions, $
   HAS_PALETTE=has_palette, $
   IMAGE_INDEX=image_index, $
   NUM_IMAGES=num_images, $
   PIXEL_TYPE=pixel_type, $
   SUPPORTED_READ=supported_read, $
   SUPPORTED_WRITE=supported_write, $
   TYPE=type

  compile_opt hidden

ON_ERROR, 2     ; return to caller if error

; List of all file types supported by READ_IMAGE and WRITE_IMAGE.
; These lists can be returned to the caller, and are not available from
; READ_IMAGE and WRITE_IMAGE.
if (!version.os ne "AIX") then begin $
    supported_read=['BMP','GIF','JPEG','PNG','PPM','SRF','TIFF', 'DICOM', 'JPEG2000']
endif else begin
    supported_read=['BMP','GIF','JPEG','PNG','PPM','SRF','TIFF', 'DICOM']
endelse

; DICOM write not supported
supported_write=['BMP','GIF','JPEG','PNG','PPM','SRF','TIFF', 'JPEG2000']

if (ARG_PRESENT(supported_read) or ARG_PRESENT(supported_write)) then begin
   if (N_ELEMENTS(filename) LE 0) then return, 1
endif

if (N_ELEMENTS(image_index) eq 0) then image_index = 0
result = 0
pos = STRPOS(filename, '.', /REVERSE_SEARCH)

if (pos GT 0) then begin

   suffix = STRUPCASE(STRMID(filename, pos+1, STRLEN(filename)-pos-1))
   if (STRPOS(suffix,';') ne -1) then $
     suffix = STRMID(suffix, 0, STRPOS(suffix,';'))

   switch suffix of

      'BMP': begin
        result = QUERY_BMP(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'GIF': begin
        result = QUERY_GIF(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'JPEG': ; fall thru
      'JPG': begin
        result = QUERY_JPEG(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'PNG': begin
        result = QUERY_PNG(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'PPM': begin
        result = QUERY_PPM(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'SRF': begin
        result = QUERY_SRF(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'TIFF': ; fall thru
      'TIF': begin
        result = QUERY_TIFF(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'DCM': ; fall thru
      'DICOM': begin
        result = QUERY_DICOM(filename, info, IMAGE_INDEX=image_index)
        break
        end

      'JP2': ; fall thru
      'JPX': begin
        result = QUERY_JPEG2000(filename, info, IMAGE_INDEX=image_index)
        break
        end

      else: begin
        result = 0
        break
        end

   endswitch

endif

if (result eq 0) then begin
   ; No suffix or suffix didn't match expected type, try each file type
   result = 0   ; assume failure
   index = 0
   while ((result eq 0) and (index lt N_ELEMENTS(supported_read))) do begin
      result = CALL_FUNCTION('QUERY_' + supported_read[index], $
                             filename, info, IMAGE_INDEX=image_index)
      index = index + 1
   endwhile
endif

; if valid file found, pass values back through keywords if necessary
if (result GT 0) then begin
   if (ARG_PRESENT(channels)) then channels = info.channels
   if (ARG_PRESENT(dimensions)) then dimensions = info.dimensions
   if (ARG_PRESENT(has_palette)) then has_palette = info.has_palette
   if (ARG_PRESENT(image_index)) then image_index = info.image_index
   if (ARG_PRESENT(num_images)) then num_images = info.num_images
   if (ARG_PRESENT(pixel_type)) then pixel_type = info.pixel_type
   if (ARG_PRESENT(type)) then type = info.type
endif

return, result

end
