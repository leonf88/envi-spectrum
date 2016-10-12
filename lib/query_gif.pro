; $Id: //depot/idl/releases/IDL_80/idldir/lib/query_gif.pro#1 $
;
; Copyright (c) 1993-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;;---------------------------------------------------------------------------
;; qGifReadByte()
;;
;; Purpose:
;;   Read one byte from the gif file. Used to grab control words ..etc.
;;
FUNCTION qGifReadByte, unit
   COMPILE_OPT hidden

   ch   = 0b
   READU, unit, ch
   RETURN, ch
END
;;---------------------------------------------------------------------------
;; qGifGetNImages
;;
;; Purpose:
;;    Used to get the count of images in the file.
;;    Basically loops through the images in the file and counts.
;;
FUNCTION   qGifGetNImages, unit

   COMPILE_OPT hidden

   ;; Local Header definition
   ihdr = {     left:0u, top:0u,                $
                width_lo: 0b, width_hi:0b,      $
                height_lo:0b, height_hi:0b,     $
                image_info:0b }
   nImages      = 0
   bDone        = 0
   image        = 0b;

   while(not bDone)do begin

      ;; Get the command string

      cmd = qGifReadbyte(unit)

      ;; Now what to do?

      case string(cmd) of
      ';':  bDone=1     ; GIF trailer (0x3b), we are done

      ',':  BEGIN       ; Image description (0x2c), read over image

          READU,unit,ihdr

          ;; Width and height of this image
          width   = ihdr.width_hi * 256 + ihdr.width_lo
          height  = ihdr.height_hi * 256 + ihdr.height_lo
          image = bytarr(width, height, /nozero)

          ;; If there is a colormap, skip it.

          if(ihdr.image_info AND '80'X) NE 0 THEN begin  ;Local color map
            point_lun, (-unit), pos
            lcolor_map_size = 2^((ihdr.image_info and 7) + 1)
            point_lun, unit, pos + (3 * lcolor_map_size);
          endif

         ;; Now call special GIF-LZW routine hidden within IDL
         ;; to do the ugly serial bit stream decoding.
         ;; Only way to really skip over the image.

         DECODE_GIF,unit,image          ; magic

         ;; This should be the 0 byte that ends the series:

         dummy = qGifReadByte(unit)     ;Loop thru commands in file.
         if(dummy ne 0)then $
            message,/info,'No trailing 0 for image.'

         nImages = nImages + 1
        END

      '!':      BEGIN                   ;Gif Extention block (ignored) (0x21)

         label = qGifReadByte(unit)     ;toss extension block label
         repeat begin                   ;read and ignore blkss
            blk_size = qGifReadByte(unit)       ;block size
            if(blk_size ne 0)then begin
               dummy = BYTARR(blk_size, /NOZERO)
               READU, unit, dummy
            endif
         endrep until blk_size eq 0
        END

        ELSE:    $
            message,'Unknown GIF keyword in ' + file + $
                     string(cmd, format='(2x,Z2)')
       ENDCASE
    endwhile

    return, nImages   ;; thats it
end
;;---------------------------------------------------------------------------

FUNCTION QUERY_GIF, FILE, INFO, IMAGE_INDEX=I
;
;+
; NAME:
;   QUERY_GIF
;
; PURPOSE:
;   Read the header of a GIF format image file and return a structure
;   containing information about the image.
;
; CATEGORY:
;   Input/Output.
;
; CALLING SEQUENCE:
;   result = QUERY_GIF(File, Info)
;
; INPUTS:
;   File:   Scalar string giving the name of the GIF file to query.
;
; Keyword Inputs:
;   IMAGE_INDEX:  For some image query functions this keyword can be used
;       to specify for which image in a multi-image file the information
;       should be returned.  For QUERY_GIF this keyword is ignored.
;
; OUTPUTS:
;   Result is a long with the value of 1 if the query was successful (and the
;   file type was correct) or 0 on failure.  The return status will indicate
;   failure for files that contain formats that are not supported by the
;   corresponding READ_ routine, even though the file may be valid outside
;   the IDL environment.
;
;   Info:   An anonymous structure containing information about the image.
;       This structure is valid only when the return value of the function
;       is 1.  The Info structure for all query routines has the following
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
; RESTRICTIONS:
;   This routine only retrieves information on the first image in a file
;   (the format allows many). Local colormaps are not supported.
;   Only 8 bit images are supported.
;
;   The Graphics Interchange Format(c) is the Copyright property
;   of CompuServ Incorporated.  GIF(sm) is a Service Mark property of
;   CompuServ Incorporated.
;
; EXAMPLE:
;   To retrieve information from the GIF image file named "foo.gif"
;   in the current directory, enter:
;
;       result = QUERY_GIF("foo.gif", info)
;       IF (result GT 0) THEN BEGIN
;           HELP, /STRUCT, info
;       ENDIF ELSE BEGIN
;           PRINT, 'GIF file not found or file is not a valid GIF format.'
;       ENDELSE
;
; MODIFICATION HISTORY:
;   Written June 1998, ACY
;   Aug 2000, KDB  - Added code to get the number of images in a file.
;   CT, RSI, Aug 2003: Fix bug in error code if unable to open file.
;
;-
;
compile_opt hidden

  ;; Set up error handling

  CATCH, errorStatus

  if(errorStatus ne 0)then begin
    CATCH, /CANCEL
    MESSAGE, /RESET
    if N_ELEMENTS(unit) gt 0 then $
        if (unit ne 0) then FREE_LUN, unit
    RETURN, 0L
  endif

  ;; Define the GIF header
  header   = {  magic           : bytarr(6),    $
                width_lo        : 0b,           $
                width_hi        : 0b,           $
                height_lo       : 0b,           $
                height_hi       : 0b,           $
                screen_info     : 0b,           $
                background      : 0b,           $
                reserved        : 0b }

  ;; Open the file.
  OPENR, unit, file, /GET_LUN, /BLOCK
  READU, unit, header      ;Read gif header

  ;;   Check Magic in header: GIF87a or GIF89a.
  gif = STRING(header.magic[0:2])
  vers = STRING(header.magic[3:5])

  ;; File is not valid a GIF file or not supported by IDL
  if( (gif ne 'GIF') or $
      (vers ne '87a' and vers ne '89a'))then begin
     free_lun, unit
     RETURN, 0L
  endif

  width   = header.width_hi * 256 + header.width_lo
  height  = header.height_hi * 256 + header.height_lo
  bits_per_pixel  = (header.screen_info AND 'F'X) + 1

  ;; Ok, now skip over the colormap if one exists.

  color_map_size        = 2 ^ bits_per_pixel
  if((header.screen_info and '80'x) ne 0)then begin ;; color map
     point_lun, (-unit), pos
     point_lun, unit, pos + (3 * color_map_size)
  endif

  ;; Get the number of images in the file
  nImages = qGifGetNImages(unit)

  Free_Lun, unit ;Done with unit

  ;; Define the info structure after error returns so that
  ;; info argument stays undefined in error cases.

  info = {CHANNELS:       0L, $
          DIMENSIONS:     [0L,0], $
          HAS_PALETTE:    0, $
          NUM_IMAGES:     0L, $
          IMAGE_INDEX:    0L, $
          PIXEL_TYPE:     0, $
          TYPE:           '' $
        }

  ;;   Fill in the info structure
  info.CHANNELS         = bits_per_pixel / 8
  info.DIMENSIONS       = [width, height]
  info.HAS_PALETTE      = ((header.screen_info and '80'X) ne 0)
  info.NUM_IMAGES       = nImages
  info.IMAGE_INDEX      = 0 ; Images are always the same size
  info.PIXEL_TYPE       = 1       ; byte data
  info.TYPE             = 'GIF'

  RETURN, 1L  ;success

END
