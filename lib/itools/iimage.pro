; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iimage.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iImage
;
; PURPOSE:
;   Implements the iimage wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iImage[, Image][,X, Y]
;
; INPUTS:
;    Image   - Either a vector, two-dimensional array, or
;      three-dimensional array representing the sample values to be
;      displayed as an image.
;
;      If Image is a vector:
;        The X and Y arguments must also be present and contain the same
;        number of elements.  In this case, a dialog will be presented that
;        offers the option of gridding the data to a regular grid (the
;        results of which will be displayed as a color-indexed image).
;
;      If Image is a two-dimensional array:
;        If either dimension is 3:
;          Image represents an array of XYZ values (either:
;          [[x0,y0,z0],[x1,y1,z1],.], or [[x0,x1,.],[y0,y1,.],[z0,z1,.]]).
;          In this case, the X and Y arguments, if present, will be ignored.
;          A dialog will be presented that allows the option of gridding the
;          data to a regular grid (the results of which will be displayed as
;          a color-indexed image, using the Z values as the image data
;          values).
;
;        If neither dimension is 3:
;          If X and Y are provided, the sample values are defined as a
;          function of the corresponding (X, Y) locations; otherwise, the
;          sample values are implicitly treated as a function of the array
;          indices of each element of Image.
;
;      If Image is a three-dimensional array:
;        If one of the dimensions is 3:
;          Image is an array (3xMxN, or Mx3xN, or MxNx3) representing the
;          red, green, and blue channels of the RGB image to be displayed.
;
;        If one of the dimensions is 4:
;          Image is an array (4xMxN, or Mx4xN, or MxNx4) representing the
;          red, green, blue, and alpha channels of the RGBA image to be
;          displayed.
;    X       - Either a vector or a two-dimensional array representing the
;      X coordinates of the image grid.
;
;      If the Image argument is a vector:
;        X must be a vector with the same number of elements.
;
;      If the Image argument is a two-dimensional array (for which neither
;      dimension is 3):
;        If X is a vector, each element of X specifies the X coordinates for
;        a column of Image (e.g., X[0] specifies the X coordinate for
;        Image[0, *]).
;        If X is a two-dimensional array, each element of X specifies the
;        X coordinate of the corresponding point in Image (Xij specifies the
;        X coordinate of Imageij).
;
;      If the Image argument is a three-dimensional RGB or RGBA array:
;        X is a vector where each element specifies the X coordinate for
;        a row of Image (e.g., X[0] specifies the X coordinate for
;        Image[*,0,*]).
;
;    Y      - Either a vector or a two-dimensional array representing the
;      Y coordinates of the image grid.
;
;      If the Image argument is a vector:
;        Y must be a vector with the same number of elements.
;
;      If the Image argument is a two-dimensional array:
;        If Y is a vector, each element of Y specifies the Y coordinates for
;        a column of Image (e.g., Y[0] specifies the Y coordinate for
;        Image[*,0]).
;        If Y is a two-dimensional array, each element of Y specifies the Y
;        coordinate of the corresponding point in Image (Yij specifies the
;        Y coordinate of Imageij).
;
;      If the Image argument is a three-dimensional RGB or RGBA array:
;        Y is a vector where each element specifies the Y coordinate for
;        a column of Image (e.g., Y[0] specifies the Y coordinate for
;        Image[*,*,0]).
;
; KEYWORD PARAMETERS:
;
;    ALPHA_CHANNEL - Set this keyword to a two-dimensional array
;      representing the alpha channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the RED_CHANNEL, GREEN_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;    BLUE_CHANNEL - Set this keyword to a two-dimensional array
;      representing the blue channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, RED_CHANNEL, and GREEN_CHANNEL
;      keywords.
;
;    GREEN_CHANNEL - Set this keyword to a two-dimensional array
;      representing the green channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, RED_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;    IDENTIFIER  [out] - The identifier of the created tool.
;
;    IMAGE_LOCATION - Set this keyword to a two-element vector, [x,y],
;      specifying the location of the lower-left corner of the image
;      in data units.  The default is [0,0].
;
;    IMAGE_DIMENSIONS - Set this keyword to a two-element vector,
;      [width,height], specifying the dimensions of the image in
;      data units.  The default is the pixel dimensions of the image.
;
;    RED_CHANNEL - Set this keyword to a two-dimensional array
;      representing the red channel pixel values for the image to be
;      displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, GREEN_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;   RGB_TABLE - Set this keyword to the number of the predefined IDL color
;       table (0 to 40), or to a 3x256 or 256x3 byte array of RGB color values.
;       If no color tables are supplied, the tool will provide a
;       default 256-entry linear grayscale ramp.
;
;    All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified: CT, Nov 2006: Allow X and Y params with RGB and RGBA images.
;       Add TEST keyword, allow RGB_TABLE to be a Loadct table number.
;
;-

;-------------------------------------------------------------------------
; NAME:
;   iImage_TestRegularGrid
;
; PURPOSE:
;   Utility routine used to determine if the X and Y samples are
;   monotonically increasing and fall on a regular grid.
;
; INPUTS:
;   X:	A vector or 2D array of X values.
;   Y:  A vector or 2D array of Y values.
;
; OUTPUTS:
;   This function returns a 1 if the X and Y samples represent
;   a valid regular grid, or a 0 otherwise.
;
function iImage_TestRegularGrid, x, y, TOLERANCE=inTolerance
    compile_opt idl2, hidden

    tolerance = (N_ELEMENTS(inTolerance) gt 0) ? inTolerance : 0.01

    ; Check X first.
    nXDims = SIZE(x, /N_DIMENSIONS)
    xDims = SIZE(x, /DIMENSIONS)
    case nXDims of
        1: begin
            nx = xDims[0]

            ; Compute deltas between samples.
            dx = x[1:(nx-1)] - x[0:(nx-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dx le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dx, SDEV=sdev)
            if (stats[0] eq 0.0) then $
                return, 0
            if ((sdev / stats[0]) gt tolerance) then $
                return, 0
        end

        2: begin
            ; Start with first row.
            xrow = x[*,0]
            nx = xDims[0]
            ny = xDims[1]

            ; Compute deltas between samples.
            dx = xrow[1:(nx-1)] - xrow[0:(nx-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dx le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dx, SDEV=sdev)
            deltaMean = stats[0]
            if (deltaMean eq 0.0) then $
                return, 0
            if ((sdev / deltaMean) gt tolerance) then $
                return, 0

            ; Now check that columns are equal within tolerance.
            dx = x[*,1:(ny-1)] - x[*,0:(ny-2)]
            stats = MOMENT(dx)
            if ((stats[0] / deltaMean) gt tolerance) then $
                return, 0
        end

        else: return, 0
    endcase

    ; Check Y next.
    nYDims = SIZE(y, /N_DIMENSIONS)
    yDims = SIZE(y, /DIMENSIONS)
    case nYDims of
        1: begin
            ny = yDims[0]

            ; Compute deltas between samples.
            dy = y[1:(ny-1)] - y[0:(ny-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dy le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dy, SDEV=sdev)
            if (stats[0] eq 0.0) then $
                return, 0
            if ((sdev / stats[0]) gt tolerance) then $
                return, 0
        end

        2: begin
            ; Start with first column.
            ycol = y[0,*]
            nx = yDims[0]
            ny = yDims[1]

            ; Compute deltas between samples.
            dy = ycol[1:(ny-1)] - ycol[0:(ny-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dy le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dy, SDEV=sdev)
            deltaMean = stats[0]
            if (deltaMean eq 0.0) then $
                return, 0
            if ((sdev / deltaMean) gt tolerance) then $
                return, 0

            ; Now check that rows are equal within tolerance.
            dy = y[1:(nx-1),*] - y[0:(nx-2),*]
            stats = MOMENT(dy)
            if ((stats[0] / deltaMean) gt tolerance) then $
                return, 0
        end

        else: return, 0
    endcase

    return, 1
end

;-------------------------------------------------------------------------
; NAME:
;   iImage_SetPalette
;
; PURPOSE:
;   Utility routine used to add a parameter that corresponds to the
;   RGB values of a palette to the given parameter set.
;
; INPUTS:
;   oParmSet:   A reference to the parameter set object to which the
;     palette is to be added.
;   rgb:    The parameter that corresponds to the RGB values of
;     the palette.
;
; KEYWORDS:
;   None.
;
pro iImage_SetPalette, oParmSet, rgbIn

    compile_opt idl2, hidden

    if (N_Elements(rgbIn) eq 0) then return

    rgb = rgbIn
    if (N_Elements(rgb) eq 1) then $
        Loadct, rgb[0], RGB_TABLE=rgb

    nDims = SIZE(rgb, /N_DIMENSIONS)
    dims = SIZE(rgb, /DIMENSIONS)
    d3 = (dims[0] eq 3) ? 0 : 1
    if (nDims ne 2 || (dims[d3] ne 3 && dims[1-d3] ne 256)) then $
        MESSAGE, 'A palette must be 3x256 or 256x3.'
    oPalette = OBJ_NEW('IDLitDataIDLPalette', $
        (d3 eq 0) ? rgb : Transpose(rgb), $
        NAME='Palette')
    oParmSet->Add, oPalette, PARAMETER_NAME='PALETTE'

end

;-------------------------------------------------------------------------
; NAME:
;   iImage_CreateImageFromChannels
;
; PURPOSE:
;   Utility routine used to create a parameter set consisting of a
;   single RGB or RGBA image using the given channel data.
;
; KEYWORDS:
;   RED_CHANNEL: Set this keyword to two-dimensional vector representing
;      the red channel of the image.
;   GREEN_CHANNEL: Set this keyword to two-dimensional vector representing
;      the green channel of the image.
;   BLUE_CHANNEL: Set this keyword to two-dimensional vector representing
;      the blue channel of the image.
;   ALPHA_CHANNEL: Set this keyword to two-dimensional vector representing
;      the alpha channel of the image.
;   DIMENSIONS: Set this keyword to a named variable that upon return
;      will contain the dimensions of a single channel of the resulting
;      image.
;
; OUTPUTS:
;   This function returns an IDLitDataIDLImagePixels object if able to
;   successfully generate an RGB or RGBA image from the provided channels,
;   or a NULL object reference otherwise.
;
pro iImage_CreateImageFromChannels, oParmSet, $
    RED_CHANNEL=redChannel, $
    GREEN_CHANNEL=greenChannel, $
    BLUE_CHANNEL=blueChannel, $
    ALPHA_CHANNEL=alphaChannel, $
    DIMENSIONS=imgDims, $
    ORDER=order, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    haveRed = N_ELEMENTS(redChannel) ne 0
    haveGreen = N_ELEMENTS(greenChannel) ne 0
    haveBlue = N_ELEMENTS(blueChannel) ne 0
    haveAlpha = N_ELEMENTS(alphaChannel) ne 0
    maxType = 0

    ; If no channels were provided, no image can be created.
    if ((haveRed + haveGreen + haveBlue + haveAlpha) eq 0) then return

    if (haveRed) then begin
        nDims = SIZE(redChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'RED_CHANNEL must have two dimensions.'

        redDims = SIZE(redChannel, /DIMENSIONS)
        maxType = SIZE(redChannel, /TYPE)

        dimensions = (haveAlpha ? [4, redDims] : [3, redDims])
    endif

    if (haveGreen) then begin
        nDims = SIZE(greenChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'GREEN_CHANNEL must have two dimensions.'

        greenDims = SIZE(greenChannel, /DIMENSIONS)
        maxType = maxType > SIZE(greenChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, greenDims)) then begin
                MESSAGE, 'Dimensions of channel images must match.', $
                    /CONTINUE
                return
            endif
        endif else $
            dimensions = (haveAlpha ? [4, greenDims] : [3, greenDims])
    endif

    if (haveBlue) then begin
        nDims = SIZE(blueChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'BLUE_CHANNEL must have two dimensions.'

        blueDims = SIZE(blueChannel, /DIMENSIONS)
        maxType = maxType > SIZE(blueChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, blueDims)) then begin
                MESSAGE, 'Dimensions of channel images must match.', $
                    /CONTINUE
                return
            endif
        endif else if (haveGreen) then begin
            if (~ARRAY_EQUAL(greenDims, blueDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else $
            dimensions = (haveAlpha ? [4, blueDims] : [3, blueDims])
    endif

    if (haveAlpha) then begin
        nDims = SIZE(alphaChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'ALPHA_CHANNEL must have two dimensions.'

        alphaDims = SIZE(alphaChannel, /DIMENSIONS)
        maxType = maxType > SIZE(alphaChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else if (haveGreen) then begin
            if (~ARRAY_EQUAL(greenDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else if (haveBlue) then begin
            if (~ARRAY_EQUAL(blueDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else $
            dimensions = [4, alphaDims]
    endif

    imgDims = dimensions[1:2]

    imgData = MAKE_ARRAY(dimensions, TYPE=maxType)
    if (haveRed) then imgData[0,*,*] = redChannel
    if (haveGreen) then imgData[1,*,*] = greenChannel
    if (haveBlue) then imgData[2,*,*] = blueChannel
    if (haveAlpha) then imgData[3,*,*] = alphaChannel

    oImageData = OBJ_NEW('IDLitDataIDLImagePixels', $
        imgData, $
        NAME='Image Planes', $
        IDENTIFIER='ImagePixels', $
        ORDER=order, $
        _EXTRA=_extra)

    oParmSet->Add, oImageData, PARAMETER_NAME='IMAGEPIXELS'

end

;-----------------------------------------------------------------------
; Helper routine to assign dimensions and location.
;
pro iImage_SetLocDims, oParmSet, imgDims, $
    IMAGE_LOCATION=imageLocation, $
    IMAGE_DIMENSIONS=imageDimensions

    compile_opt idl2, hidden

    if ((N_ELEMENTS(imageLocation) ne 2) && $
        (N_ELEMENTS(imageDimensions) ne 2)) then return

    if (N_Elements(imgDims) ne 2) then return

    if (N_ELEMENTS(imageLocation) eq 2) then begin
        xmin = imageLocation[0]
        ymin = imageLocation[1]
    endif else begin
        xmin = 0
        ymin = 0
    endelse

    if (N_ELEMENTS(imageDimensions) eq 2) then begin
        xmax = xmin + imageDimensions[0]
        ymax = ymin + imageDimensions[1]
        delta = DOUBLE(imageDimensions) / DOUBLE(imgDims)
    endif else begin
        xmax = xmin + imgDims[0]
        ymax = ymin + imgDims[1]
        delta  = [1.0,1.0]
    endelse

    x = DINDGEN(imgDims[0])*delta[0] + xmin
    y = DINDGEN(imgDims[1])*delta[1] + ymin

    if (OBJ_VALID(oParmSet) ne 0) then begin
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', x, NAME='X'), $
            PARAMETER_NAME='X'
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', y, NAME='Y'), $
            PARAMETER_NAME='Y'
    endif

end

;-----------------------------------------------------------------------
; Helper routine for one parameter.
;
function iImage_Set1Param, oParmSet, parm1, imgDims, $
    ORDER=order, $
    NODATA=noData, XRANGE=xr, YRANGE=yr, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    unknownData = 0b

    ; Check for undefined variable.
    if (N_ELEMENTS(parm1) eq 0) then $
        MESSAGE, 'First argument is an undefined variable.'

    nDims1 = SIZE(parm1, /N_DIMENSIONS)
    if (nDims1 ne 2 && nDims1 ne 3) then $
        MESSAGE, 'First argument has invalid dimensions'

    case nDims1 of
    2: begin ; First parameter is a 2D array.
        dims1 = SIZE(parm1, /DIMENSIONS)
        iDim = WHERE(dims1 eq 3, nDimIs3)
        if (nDimIs3 gt 0) then begin
;-- SCATTERED DATA: -------------------------------------------------------
;     parm1: 3xN - [[x,y,z],[x,y,z],...], or
;            Nx3 - [[x,x,...],[y,y,...],[z,z,....]]
            ; Do not give parameter names when adding,
            ; since these need to be gridded, and are not
            ; valid image parameters.
            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                (iDim eq 0) ? REFORM(parm1[0,*]) : REFORM(parm1[*,0]), $
                NAME='X')
            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                (iDim eq 0) ? REFORM(parm1[1,*]) : REFORM(parm1[*,1]), $
                NAME='Y')
            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                (iDim eq 0) ? REFORM(parm1[2,*]) : REFORM(parm1[*,2]), $
                NAME='Z')
            unknownData = 1
        endif else begin
;-- INDEXED IMAGE : -------------------------------------------------------
;     parm1: MxN
            oParmSet->Add, OBJ_NEW('IDLitDataIDLImagePixels', $
                parm1, $
                NAME='Image Planes', $
                IDENTIFIER='ImagePixels', $
                ORDER=order, $
                _EXTRA=_extra), PARAMETER_NAME='IMAGEPIXELS'
            imgDims = SIZE(parm1, /DIMENSIONS)
        endelse
        end

    3: begin ; First parameter is a 3D array.
        dims1 = SIZE(parm1, /DIMENSIONS)
        is3or4 = (Where(dims1 eq 3 or dims1 eq 4))[0]
        if (is3or4 eq -1) then $
            MESSAGE, 'First argument has invalid dimensions'
;-- RGB IMAGE: ------------------------------------------------------------
;     parm1: 3xMxN, Mx3xN, or MxNx3, or
;            4xMxN, Mx4xN, or MxNx4, or
        oParmSet->Add, OBJ_NEW('IDLitDataIDLImagePixels', parm1, $
            NAME='Image Planes', $
            IDENTIFIER='ImagePixels', $
            ORDER=order, $
            _EXTRA=_extra), PARAMETER_NAME='IMAGEPIXELS'

        ; Keep track of primary image dimensions.
        case (is3or4) of
        0: imgDims = dims1[1:2]
        1: imgDims = dims1[[0,2]]
        2: imgDims = dims1[0:1]
        endcase
        end
    endcase

    ; auto range for /NODATA
    if (KEYWORD_SET(noData)) then begin
      xr = [0, imgDims[0]]
      yr = [0, imgDims[1]]
    endif


    return, unknownData
end

;-----------------------------------------------------------------------
; Helper routine for three parameters.
;
function iImage_Set3Param, oParmSet, parm1, parm2, parm3, imgDims, $
    ORDER=order, $
    NODATA=noData, XRANGE=xr, YRANGE=yr, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    unknownData = 0b
    nDims1 = SIZE(parm1, /N_DIMENSIONS)

    case nDims1 of
    0: MESSAGE, 'First argument has invalid dimensions'
    1: begin ; First parameter is a vector.
;-- SCATTERED DATA: ------------------------------------------------------
;     parm1: [z0,z1,z2,...]
;     parm2: [x0,x1,x2,...]
;     parm3: [y0,y1,y2,...]
        nZ = N_ELEMENTS(parm1)
        nX = N_ELEMENTS(parm2)
        nY = N_ELEMENTS(parm3)
        if (nX ne nZ || nX ne nY) then $
            MESSAGE, 'Number of elements per argument must match.'
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', REFORM(parm2, nZ), $
            NAME='X')
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', REFORM(parm3, nZ), $
            NAME='Y')
        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', REFORM(parm1, nZ), $
            NAME='Z')
        unknownData = 1b
        end
    2: begin ; First parameter is a 2D array.
;-- INDEXED IMAGE + XY: ------------------------------------------------------
;     parm1: MxN (indexed image)
;     parm2: MxN (X), or M (X)
;     parm3: MxN (Y), or N (Y)
        imgDims = SIZE(parm1, /DIMENSIONS)

        ; Check dimensions of second parameter.  Ensure it
        ; corresponds to the dimensions of the first parameter.
        nXDims = SIZE(parm2, /N_DIMENSIONS)
        if ((nXDims lt 1) or (nXDims gt 2)) then $
            MESSAGE, 'X must be a vector or 2D array.'
        xDims = SIZE(parm2, /DIMENSIONS)
        if (nXDims eq 1) then begin
            if (xdims[0] ne imgDims[0]) then $
                MESSAGE, 'Dimensions of X do not correspond to Image'
        endif else begin
            if (xdims[0] ne imgDims[0] || xdims[1] ne imgDims[1]) then $
                MESSAGE, 'Dimensions of X do not correspond to Image'
        endelse

        ; Check dimensions of third parameter.  Ensure it
        ; corresponds to the dimensions of the first parameter.
        nYDims = SIZE(parm3, /N_DIMENSIONS)
        if ((nYDims lt 1) or (nYDims gt 2)) then $
            MESSAGE, 'Y must be a vector or 2D array.'
        yDims = SIZE(parm3, /DIMENSIONS)
        if (nYDims eq 1) then begin
            if (ydims[0] ne imgDims[1]) then $
                MESSAGE, 'Dimensions of Y do not correspond to Image'
        endif else begin
            if (ydims[0] ne imgDims[0] || ydims[1] ne imgDims[1]) then $
                MESSAGE, 'Dimensions of Y do not correspond to Image'
        endelse

        ; Test whether the XY values fall on a regular grid.
        isRegular = iImage_TestRegularGrid(parm2, parm3)

        if (isRegular) then begin
            oParmSet->Add, $
                OBJ_NEW('IDLitDataIDLImagePixels', parm1, $
                    NAME='Image Planes', $
                    IDENTIFIER='ImagePixels', $
                    ORDER=order, $
                    _EXTRA=_extra), $
                PARAMETER_NAME='IMAGEPIXELS'
            oParmSet->Add, $
                OBJ_NEW((nXDims eq 2) ? 'IDLitDataIDLArray2D' : 'IDLitDataIDLVector', $
                parm2, NAME='X'), $
                PARAMETER_NAME='X'
            oParmSet->Add, $
                OBJ_NEW((nYDims eq 2) ? 'IDLitDataIDLArray2D' : 'IDLitDataIDLVector', $
                parm3, NAME='Y'), $
                PARAMETER_NAME='Y'

            ; auto range for /NODATA
            if (KEYWORD_SET(noData)) then begin
              xr = [parm2[0], parm2[-1] + (parm2[-1]-parm2[-2])]
              yr = [parm3[0], parm3[-1] + (parm3[-1]-parm3[-2])]
            endif
        endif else begin
            ; The data needs to be gridded.
            ;
            ; Do not give parameter names when adding,
            ; since these are not valid image parameters.
            oParmSet->Add, $
                OBJ_NEW('IDLitDataIDLVector', REFORM(parm2, N_ELEMENTS(parm2)), $
                NAME='X')
            oParmSet->Add, $
                OBJ_NEW('IDLitDataIDLVector', REFORM(parm3, N_ELEMENTS(parm3)), $
                NAME='Y')

            dims1 = SIZE(parm1, /DIMENSIONS)

            ; If the first dim of Z matches X and the second
            ; dim matches Y, then assume an irregular grid.
            if (nXDims eq 1 && nYDims eq 1 && $
                dims1[0] eq N_ELEMENTS(parm2) && $
                dims1[1] eq N_ELEMENTS(parm3)) then begin
                ; Do not give parameter names when adding,
                ; since these are not valid image parameters.
                oParmSet->Add, OBJ_NEW('IDLitDataIDLArray2D', parm1, NAME='Z')
            endif else begin
                oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                    REFORM(parm1, N_ELEMENTS(parm1)), NAME='Z')
            endelse

            unknownData = 1b
        endelse
        end
    3: begin ; First parameter is a 3D array.
        ; Make sure parm1 is a valid RGB or RGBA image.
        if (iImage_Set1Param(oParmSet, parm1, imgDims, ORDER=order, $
            _EXTRA=_extra)) then break
        ; Check dimensions of second parameter.  Ensure it
        ; corresponds to the dimensions of the first parameter.
        if (SIZE(parm2, /N_DIMENSIONS) ne 1) then $
            MESSAGE, 'X must be a vector.'
        if (N_Elements(parm2) ne imgDims[0]) then $
            MESSAGE, 'Dimensions of X do not correspond to Image'

        ; Check dimensions of third parameter.  Ensure it
        ; corresponds to the dimensions of the first parameter.
        if (SIZE(parm3, /N_DIMENSIONS) ne 1) then $
            MESSAGE, 'y must be a vector.'
        if (N_Elements(parm3) ne imgDims[1]) then $
            MESSAGE, 'Dimensions of Y do not correspond to Image'

        oParmSet->Add, $
            OBJ_NEW('IDLitDataIDLVector', parm2, NAME='X'), $
            PARAMETER_NAME='X'
        oParmSet->Add, $
            OBJ_NEW('IDLitDataIDLVector', parm3, NAME='Y'), $
            PARAMETER_NAME='Y'
        end
    else:
    endcase

    return, unknownData
end

;-----------------------------------------------------------------------
; Helper routine to construct the parameter set.
; If no parameters are supplied then oParmSet will be undefined.
;
function iImage_GetParmSet, oParmSet, parm1, parm2, parm3, $
    TEST=test, $
    IMAGE_LOCATION=imageLocation, $
    IMAGE_DIMENSIONS=imageDimensions, $
    RED_CHANNEL=redChannel, $
    GREEN_CHANNEL=greenChannel, $
    BLUE_CHANNEL=blueChannel, $
    ALPHA_CHANNEL=alphaChannel, $
    GEOTIFF=geoTiff, $
    RGB_TABLE=rgbTableIn, $
    ORDER=order, $
    PALETTE=palette, $
    NODATA=noData, XRANGE=xr, YRANGE=yr, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    ; Construct our own N_Params() so we can quietly pass in undefined vars.
    nParams = 1 + (N_Elements(parm1) ne 0) + $
        (N_Elements(parm2) ne 0) + (N_Elements(parm3) ne 0)

    if (Keyword_Set(test)) then begin
        file = FILEPATH('elev_t.jpg', SUBDIRECTORY = ['examples', 'data'])
        Read_Jpeg, file, parm1
        nParams = 2
    endif

    ; If no arguments then look for our image channel keywords.
    if (nParams le 1 && $
        N_Elements(redChannel) eq 0 && $
        N_Elements(greenChannel) eq 0 && $
        N_Elements(blueChannel) eq 0 && $
        N_Elements(alphaChannel) eq 0) then begin
        return, 0b   ; no data, return immediately
    endif

    unknownData = 0b

    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME='Image parameters', $
        DESCRIPTION='Image parameters', $
        ICON='demo')
    oParmSet->SetAutoDeleteMode, 1

    case (nParams) of
    1: ; do nothing
    2: unknownData = iImage_Set1Param(oParmSet, parm1, imgDims, ORDER=order, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, $
        _EXTRA=_extra)
    3: MESSAGE, 'Incorrect number of arguments.'
    4: unknownData = iImage_Set3Param(oParmSet, parm1, parm2, parm3, imgDims, ORDER=order, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, $
        _EXTRA=_extra)
    endcase

    ; RED_CHANNEL, GREEN_CHANNEL, BLUE_CHANNEL, and/or ALPHA_CHANNEL.
    iImage_CreateImageFromChannels, oParmSet, $
        RED_CHANNEL=redChannel, $
        GREEN_CHANNEL=greenChannel, $
        BLUE_CHANNEL=blueChannel, $
        ALPHA_CHANNEL=alphaChannel, $
        DIMENSIONS=imgDims, $
        ORDER=order, $
        _EXTRA=_extra

    ; IMAGE_LOCATION and IMAGE_DIMENSIONS.
    iImage_SetLocDims, oParmSet, imgDims, $
        IMAGE_LOCATION=imageLocation, $
        IMAGE_DIMENSIONS=imageDimensions

    ; If an IDLgrPalette was provided, then grab the red, green,
    ; and blue values, and pass them on to the palette data for
    ; this image.
    ; NOTE: the palette object itself will not be utilized
    ; directly.  Any changes made later to the palette object
    ; will not be reflected in the iImage tool.
    if (OBJ_VALID(palette) && OBJ_ISA(palette,'IDLgrPalette')) then begin
        palette->GetProperty, RED=rVal, GREEN=gVal, BLUE=bVal
        rgbTableIn = TRANSPOSE([[rVal],[gVal],[bVal]])
    endif

    ; RGB_TABLE.
    iImage_SetPalette, oParmSet, rgbTableIn

    if (N_Tags(geoTiff) gt 0) then begin
        oGeo = OBJ_NEW('IDLitDataIDLGeoTIFF', geotiff, $
            NAME='GeoTIFF Tags', TYPE='IDLGEOTIFF', $
            ICON='vw-list')
        oParmSet->Add, oGeo, PARAMETER_NAME='GEOTIFF'
    endif

    return, unknownData
end


;-------------------------------------------------------------------------
pro iimage, parm1, parm2, parm3, $
    DEBUG=debug, $
    TEST=test, $
    IMAGE_LOCATION=imageLocation, $
    IMAGE_DIMENSIONS=imageDimensions, $
    RED_CHANNEL=redChannel, $
    GREEN_CHANNEL=greenChannel, $
    BLUE_CHANNEL=blueChannel, $
    ALPHA_CHANNEL=alphaChannel, $
    GEOTIFF=geoTiff, $
    RGB_TABLE=rgbTableIn, $
    ORDER=order, $
    PALETTE=palette, $
    IDENTIFIER=identifier, $
    NODATA=noData, $
    _EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    ; Handle filename parameter
    if (SIZE(parm1, /TNAME) eq 'STRING') then begin
      filenameTmp = parm1
      iOpen, filenameTmp, parm1, rgbTableIn, GEOTIFF=geoTiff, _EXTRA=_extra
      ; We might have just opened an ISV file instead of returning data.
      ; If so, then we are done.
      if (ARRAY_EQUAL(parm1, 1b, /NO_TYPECONV)) then begin
        parm1 = filenameTmp
        return
      endif
    endif
    
    ; Manually pass in all keywords so keywords like ALPHA_CHANNEL don't get
    ; passed thru _extra to the CreateVisualization and cause problems.
    unknownData = iImage_GetParmSet(oParmSet, parm1, parm2, parm3, $
        TEST=test, IMAGE_LOCATION=imageLocation, $
        IMAGE_DIMENSIONS=imageDimensions, $
        GEOTIFF=geoTiff, $
        RED_CHANNEL=redChannel, GREEN_CHANNEL=greenChannel, $
        BLUE_CHANNEL=blueChannel, ALPHA_CHANNEL=alphaChannel, $
        RGB_TABLE=rgbTableIn, ORDER=order, PALETTE=palette, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, $
        _EXTRA=_extra)


    ; Reset filename parameter
    if (N_ELEMENTS(filenameTmp) gt 0) then begin
      parm1 = filenameTmp
    endif

    ; Destroy parameter set if not needed.
    if (Obj_Valid(oParmSet) && oParmSet->Count() eq 0) then OBJ_DESTROY, oParmSet

    identifier = IDLitSys_CreateTool("Image Tool", $
        GEOTIFF=geoTiff, $
        WINDOW_TITLE='IDL iImage', $
        VISUALIZATION_TYPE="IMAGE", $
        UNKNOWN_DATA=unknownData, $
        INITIAL_DATA=Obj_Valid(oParmSet) ? oParmSet : null, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, $
        _EXTRA=_extra)

end


