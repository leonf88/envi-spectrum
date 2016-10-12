; $Id: //depot/idl/releases/IDL_80/idldir/lib/read_jpeg2000.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;   READ_JPEG2000
;
; PURPOSE:
;   This function reads a JPEG2000 image.
;
; CATEGORY:
;   Input/Output
;
; CALLING SEQUENCE:
;   Result = READ_JPEG2000(File)
;
; INPUTS:
;   File: The full path name of the file to read.
;
; OUTPUTS:
;   This function returns an n x w x h array containing the image
;   data where n is 1 for grayscale or 3 for RGB images, w is the
;   width and h is the height.
;
;   Red, Green, Blue
;       Named variables that will contain the Red, Green, and Blue
;       color vectors if a color palette exists.
;
; KEYWORDS:
;   DISCARD_LEVELS: Set this keyword to indicate the number of highest
;       resolution levels which will not appear in the image.
;       Image dimensions are divided by 2 to the power of this number.
;
;   MAX_LAYERS: Set this keyword to the maximum number of quality
;       layers which will appear to be present. The default is zero,
;       which implies that all layers should be retained.
;
;   ORDER: Set this keyword to a nonzero value to store images in
;       the Result from top to bottom. By default, images are stored
;       in the Result from bottom to top.
;
;   REGION: Set this keyword to a four-element vector containing the
;       rectangular region of the image to read, in the coordinate
;       system of the original image. The region is specified as
;       [StartX, StartY, Width, Height].
;
; EXAMPLE
;    ; Read in a 24-bit JPEG image.
;    input = FILEPATH('marsglobe.jpg', SUBDIR=['examples','data'])
;    READ_JPEG, input, image
;
;    ; Create a JPEG2000 with 6 quality layers.
;    WRITE_JPEG2000, 'marsglobe.jp2', image, N_LAYERS=6
;
;    ; Verify the file information.
;    success = QUERY_JPEG2000('marsglobe.jp2', info)
;    help, info, /STRUCT
;
;    WINDOW, 0, XSIZE=2*info.dimensions[0], YSIZE=info.dimensions[1]
;
;    ; Use the DISCARD_LEVELS keyword.
;    for discard=0,5 do TV, /TRUE, $
;        READ_JPEG2000('marsglobe.jp2', DISCARD_LEVELS=discard)
;
;    ; Extract a region.
;    image = READ_JPEG2000('marsglobe.jp2', $
;        REGION=[0,0,200,100])
;    TV, REBIN(image, 3, 400, 200), 400, 0, /TRUE
;
;    ; Use the MAX_LAYERS keyword.
;    image = READ_JPEG2000('marsglobe.jp2', MAX_LAYERS=1, $
;        REGION=[0,0,200,100])
;    TV, REBIN(image, 3, 400, 200), 400, 200, /TRUE
;
; MODIFICATION HISTORY:
;   Written: CT, RSI, March 2004.
;
;-

function read_jpeg2000, File, red, green, blue, $
    DISCARD_LEVELS=discardLevels, $
    MAX_LAYERS=maxLayers, $
    ORDER=order, $
    REGION=region

    compile_opt idl2, hidden


    ON_ERROR, 2 ; return on error

    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'
    if (SIZE(file, /TYPE) ne 7) then $
        MESSAGE, 'File must be a string.'

    ; Set up CATCH routine to destroy the object if an error occurs.
    CATCH, errorStatus
    if errorStatus ne 0 then begin
        CATCH, /CANCEL
        if (OBJ_VALID(oJPEG2000)) then $
            OBJ_DESTROY, oJPEG2000
        Message, /Reissue_Last
        return, 0L
    endif


    oJPEG2000 = OBJ_NEW('IDLffJPEG2000', file, /QUIET)

    if (~OBJ_VALID(oJPEG2000)) then $
        MESSAGE, 'Unable to read JPEG2000 file: ' + File

    oJPEG2000->GetProperty, BIT_DEPTH=bitDepth, $
        N_COMPONENTS=nComponents, PALETTE=palette

    ; Set RGB to true if we have 3 byte components, so that we
    ; automatically apply all color transforms.
    rgb = MAX(bitDepth) le 8 && nComponents eq 3

    image = oJPEG2000->GetData( $
        DISCARD_LEVELS=discardLevels, $
        MAX_LAYERS=maxLayers, $
        ORDER=order, $
        REGION=region, $
        RGB=rgb)

    OBJ_DESTROY, oJPEG2000

    if (SIZE(palette, /N_DIMENSIONS) eq 2 && $
        (SIZE(palette, /DIMENSIONS))[1] eq 3) then begin
        red = palette[*,0]
        green = palette[*,1]
        blue = palette[*,2]
    endif

    return, image

end
