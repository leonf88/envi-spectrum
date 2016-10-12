; $Id: //depot/idl/releases/IDL_80/idldir/lib/write_jpeg2000.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
;  WRITE_JPEG2000
;
; PURPOSE:
;   This procedure writes a JPEG2000 image.
;
; CATEGORY:
;   Input/Output
;
; CALLING SEQUENCE:
;   WRITE_JPEG2000, File, Image
;
; INPUTS:
;   File: The full path name of the file to write.
;
;   Image: The two or three-dimensional array to write.
;
;   Red, Green, Blue: For single-channel images, these should contain
;       the red, green, and blue color vectors, respectively.
;       For multi-channel images, these arguments are ignored.
;
; OUTPUTS:
;   None.
;
; KEYWORDS:
;   N_LAYERS: Set this keyword to a positive integer specifying
;       the number of quality layers. The default is one.
;
;   N_LEVELS: Set this keyword to an integer specifying the number of
;       wavelet decomposition levels, or stages, in the range 0...15.
;       The default value is 5. When writing a JP2 file, if
;       a Red, Green, Blue palette is provided then the default
;       is N_LEVELS=0.
;
;   ORDER: Set this keyword to a nonzero value to store images in
;       the Result from top to bottom. By default, images are stored
;       in the Result from bottom to top.
;
;   REVERSIBLE: Set this keyword to 0 or 1 indicating the type of
;       compression to use. A non-zero value indicates that reversible
;       compression should be used. The default is to use irreversible
;       compression. When writing a JP2 file, if a Red, Green, Blue
;       palette is provided then the default is REVERSIBLE=1.
;
; MODIFICATION HISTORY:
;   Written: CT, RSI, March 2004.
;
;-

pro write_jpeg2000, File, image, red, green, blue, $
    N_LAYERS=nLayers, $
    N_LEVELS=nLevels, $
    ORDER=order, $
    REVERSIBLE=reversible

    compile_opt idl2


    ON_ERROR, 2 ; return on error

    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'
    if (SIZE(file, /TYPE) ne 7) then $
        MESSAGE, 'File must be a string.'
    ndim = SIZE(image, /N_DIMENSIONS)
    dims = SIZE(image, /DIMENSIONS)
    if (ndim ne 2 && ndim ne 3) then $
        MESSAGE, 'Image must be a two or three-dimensional array.'

    ; Compute the desired bit depth and sign.
    bitDepth = 8
    signed = 0

    type = SIZE(image, /TYPE)
    ; Int or uInt.
    if (type eq 2 || type eq 12) then $
        bitDepth = 16
    ; Long, uLong, Long64, uLong64.
    if (type eq 3 || (type ge 13 && type lt 15)) then $
        bitDepth = 24
    ; Int, Long, Long64.
    if (type eq 2 || type eq 3 || type eq 14) then $
        signed = 1

    ; For all other types, make sure we can convert to byte.
    if (bitDepth eq 8) then $
        void = BYTE(image[0])

    nComponent = (ndim eq 3) ? dims[0] : 1
    bitDepth = REPLICATE(bitDepth, nComponent)
    signed = REPLICATE(signed, nComponent)

    ; Verify that the palette is okay.
    nr = N_ELEMENTS(red)
    if (nComponent eq 1 && nr && $
        nr eq N_ELEMENTS(green) && nr eq N_ELEMENTS(blue)) then begin
        palette = [[red], [green], [blue]]
        if (MAX(nr eq [2,4,8,16,32,64,128,256]) eq 0) then begin
            MESSAGE, 'Red, green, blue must have length n, ' + $
                'where n is a power of two <= 256.'
        endif
    endif


    ; Set up CATCH routine to destroy the object if an error occurs.
    CATCH, errorStatus
    if errorStatus ne 0 then begin
        CATCH, /CANCEL
        if (OBJ_VALID(oJPEG2000)) then $
            OBJ_DESTROY, oJPEG2000
        Message, /Reissue_Last
        return
    endif

    oJPEG2000 = OBJ_NEW('IDLffJPEG2000', file, /QUIET, /WRITE)

    if (~OBJ_VALID(oJPEG2000)) then $
        MESSAGE, 'Unable to write JPEG2000 file: ' + File

    oJPEG2000->SetProperty, $
        BIT_DEPTH=bitDepth, $
        N_LAYERS=nLayers, $
        N_LEVELS=nLevels, $
        PALETTE=palette, $
        REVERSIBLE=reversible, $
        SIGNED=signed

    oJPEG2000->SetData, image, ORDER=order

    OBJ_DESTROY, oJPEG2000

end
