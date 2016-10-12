; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/isurface.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iSurface
;
; PURPOSE:
;   Implements the isurface wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   ISurface
;
; INPUTS:
;   Z[,X,Y] [,...] (see IDLgrSurface)
;
; KEYWORD PARAMETERS:
;   IDENTIFIER  [out] - The identifier of the created tool.
;
;   vertColors: vector or 2D array of color indices,
;    or a two-dimensional array containing RGB triplets or RGBA values.
;
;   TEXTURE_IMAGE: 2D array (MxN), 3D array (3xMxN, Mx3xN, MxNx3,
;   4xMxN, Mx4xN, MxNx4) RGB with optional alpha channel
;
;   TEXTURE_RED, TEXTURE_GREEN, TEXTURE_BLUE, TEXTURE_ALPHA: 2D arrays
;   (must be of same size and type) specifying, respectively, red
;   channel, green channel, blue channel, and, optionally, the alpha
;   channel of the image to be used as the TEXTURE_IMAGE
;
;   RGB_TABLE: Set this keyword to the number of the predefined IDL color
;   table (0 to 40), or to either a 3 by 256 or 256 by 3 array containing
;   color values to use in a color indexed texture image or by vertex colors.
;
;   All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, January 2003
;   Modified: CT, Oct 2006: Added helper function, TEST keyword,
;       allow RGB_TABLE to be a Loadct table number.
;
;-

;-----------------------------------------------------------------------
; Helper routine to construct the parameter set.
; If no parameters are supplied then oParmSet will be undefined.
;
function iSurface_GetParmSet, oParmSet, z, x, y, $
    TEST=test, $
    RGB_TABLE=rgbTableIn, $
    TEXTURE_IMAGE=textureImage, $
    TEXTURE_RED=textureRed, $
    TEXTURE_GREEN=textureGreen, $
    TEXTURE_BLUE=textureBlue, $
    TEXTURE_ALPHA=textureAlpha, $
    VERT_COLORS=vertColors, $
    NODATA=noDataIn, XRANGE=xr, YRANGE=yr, ZRANGE=zr

    compile_opt idl2, hidden

    oSrvLangCat = (_IDLitSys_GetSystem())->GetService('LANGCAT')

    if (Keyword_Set(test)) then begin
        file = FILEPATH('elevbin.dat', SUBDIRECTORY = ['examples', 'data'])
        z = READ_BINARY(file, DATA_DIMS = [64, 64])
        file = FILEPATH('elev_t.jpg', SUBDIRECTORY = ['examples', 'data'])
        Read_Jpeg, file, textureImage
    endif

    if (N_Elements(z) eq 0) then return, 0b

    noData = KEYWORD_SET(noDataIn)

    unknownData = 0b

    ;; create parameter set for holding data
    oParmSet = OBJ_NEW('IDLitParameterSet', $
                       NAME='Surface parameters', $
                       ICON='surface',$
                       DESCRIPTION='Surface parameters')
    oParmSet->setAutoDeleteMode, 1

    CASE SIZE(z, /N_DIMENSIONS) OF

      1: BEGIN
        ;; if Z is a vector then X and Y are required
        nx = N_ELEMENTS(x)
        ny = N_ELEMENTS(y)
        nz = N_ELEMENTS(z)
        IF ((nx EQ ny) && (ny EQ nz)) THEN BEGIN
          ;; Do not give parameter names when adding,
          ;; since these need to be gridded, and are not
          ;; valid surface parameters.
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT X', $
                                 REFORM(x, nz))
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Y', $
                                 REFORM(y, nz))
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Z', $
                                 REFORM(z, nz))
          ;; Fire up the unknown data wizard after starting the tool.
          unknownData = 1b
        ENDIF ELSE BEGIN
          Message, oSrvLangCat->Query('Message:iSurface:VectorNElements')
        ENDELSE

        ; auto range for /NODATA
        if (noData) then begin
          xr = [x[0], x[-1]]
          yr = [y[0], y[-1]]
          zr = [MIN(z, MAX=mx), mx]
        endif
      END

      2: BEGIN
        oDataZ = OBJ_NEW('IDLitDataIDLArray2D', Z, NAME='Z')
        oParmSet->add, oDataZ, PARAMETER_NAME= "Z"
        zDims = size(z, /dimensions)
        
        ; auto range for /NODATA
        if (noData) then begin
          zr = [MIN(z, MAX=mx), mx]
          xr = [0, zDims[0]-1]
          yr = [0, zDims[1]-1]
        endif

        nx = N_ELEMENTS(X)
        ny = N_ELEMENTS(Y)
        IF (nx NE 0 || ny NE 0) THEN BEGIN

          validXY = 0b
          xDims = size(x, /dimensions)
          yDims = size(y, /dimensions)

          ;; if both X and Y exist as vectors, add them to the data set
          IF nx EQ zDims[0] && ny EQ zDims[1] THEN BEGIN
            oDataX = obj_new('idlitDataIDLVector',  X, NAME='X')
            oParmSet->add, oDataX, PARAMETER_NAME  ="X"
            oDataY = obj_new('idlitDataIDLVector', Y, NAME='Y')
            oParmSet->add, oDataY, PARAMETER_NAME= "Y"
            validXY = 1b
          ENDIF

          ;; if both X and Y exist as 2D arrays, add them to the data set
          IF array_equal(zDims,xDims) && array_equal(zDims,yDims) THEN BEGIN
            oDataX = obj_new('IDLitDataIDLArray2D',  X, NAME='X')
            oParmSet->add, oDataX, PARAMETER_NAME  ="X"
            oDataY = obj_new('IDLitDataIDLArray2D', Y, NAME='Y')
            oParmSet->add, oDataY, PARAMETER_NAME= "Y"
            validXY = 1b
          ENDIF

          IF ~validXY THEN BEGIN
            Message, $
              oSrvLangCat->Query('Message:iSurface:XY_ELMTS_NE_Z_COLROW')
          ENDIF

          ; auto range for /NODATA
          if (noData) then begin
            xr = [MIN(x, MAX=mx), mx]
            yr = [MIN(y, MAX=mx), mx]
            ; We already did Z above.
          endif

        ENDIF

      END

      ELSE : MESSAGE, 'First argument has invalid dimensions'

    ENDCASE

  ;; Check for vertex colors. If set, add that to the data container.
  IF keyword_set(vertColors) THEN BEGIN
    vFlag = 0
    ndim = size(vertColors, /n_dimensions)
    dims = size(vertColors, /dimensions)
    zdim = size(z, /DIMENSIONS)
    IF (ndim EQ 1 || $
      (ndim EQ 2 && dims[0] eq zdim[0] && dims[1] eq zdim[1])) then BEGIN
      oVert = obj_new('idlitDataIDLVector', $
                      reform(vertColors,n_elements(vertColors)), $
                      NAME='VERTEX COLORS')
      vFlag = 1
    endif else begin
        ; Handle either RGB or RGBA.
        IF (ndim EQ 2 && $
          (dims[0] EQ 3 || dims[0] eq 4)) THEN BEGIN
          oVert = obj_new('idlitDataIDLArray2D',vertColors, $
                          NAME='VERTEX COLORS')
          vFlag = 1
        endif
    endelse
    IF vFlag THEN BEGIN
      oParmSet->add, oVert,PARAMETER_NAME="VERTEX COLORS"
    ENDIF ELSE BEGIN
      Message, oSrvLangCat->Query('Message:iSurface:BadVertColors')
    ENDELSE
  ENDIF

  ;; Check for texture map image. If set, add that to the data container.
  IF keyword_set(textureImage) && $
    (where(size(textureImage,/type) EQ [0l,6,7,8,9,10,11]) EQ -1) THEN BEGIN

    ;; if TEXTURE_IMAGE is 2D, use it directly
    IF (size(textureImage,/n_dimensions))[0] EQ 2 THEN BEGIN
      oTextMap = obj_new('idlitDataIDLArray2D', textureImage, $
                         NAME='TEXTURE')
      oParmSet->add, oTextMap,PARAMETER_NAME="TEXTURE"
    ENDIF

    ;; if TEXTURE_IMAGE is 3D move channel dimension to the first position
    IF (size(textureImage,/n_dimensions))[0] EQ 3 THEN BEGIN
      sz = size(textureImage,/dimensions)
      IF (((wh=where(sz EQ 3, complement=comp)))[0] NE -1) || $
        (((wh=where(sz EQ 4, complement=comp)))[0] NE -1) THEN BEGIN
        imageTemp = byte(transpose(textureImage,[wh,comp]))
        oTextMap = obj_new('idlitDataIDLArray3D', imageTemp, $
                           NAME='TEXTURE')
        oParmSet->add, oTextMap,PARAMETER_NAME="TEXTURE"
      ENDIF
    ENDIF

    IF ~obj_valid(oTextMap) THEN $
      Message, oSrvLangCat->Query('Message:iSurface:BadTextureImage')

  ENDIF

  ;; Check to see if texture map was passed in as 3 or 4 separate 2D
  ;; arrays.  textureRed, textureGreen, and textureBlue must all
  ;; be 2D arrays of the same size and type and textureImage must
  ;; not be set.
  IF keyword_set(textureRed) && keyword_set(textureGreen) && $
    keyword_set(textureBlue) && ~keyword_set(textureImage) && $
    (size(reform(textureRed),/n_dimensions) EQ 2) && $
    (size(reform(textureGreen),/n_dimensions) EQ 2) && $
    (size(reform(textureBlue),/n_dimensions) EQ 2) && $
    ( ((textmap_x=(size(reform(textureRed),/dimensions))[0])) EQ $
      (size(reform(textureGreen),/dimensions))[0] ) && $
    ( textmap_x EQ (size(reform(textureBlue),/dimensions))[0] ) && $
    ( ((textmap_y=(size(reform(textureRed),/dimensions))[1])) EQ $
      (size(reform(textureGreen),/dimensions))[1] ) && $
    ( textmap_y EQ (size(reform(textureBlue),/dimensions))[1] ) && $
    ( ((textmap_type=(size(reform(textureRed),/type))[0])) EQ $
      (size(reform(textureGreen),/type))[0] ) && $
    ( textmap_type EQ (size(reform(textureBlue),/type))[0] ) && $
    ( where(textmap_type EQ [0l,6,7,8,9,10,11]) EQ -1 ) THEN BEGIN
    ;; textureAlpha, if set, must match TEXTURE_* in size and type
    IF keyword_set(textureAlpha) && $
      (size(reform(textureAlpha),/n_dimensions) EQ 2) && $
      ( textmap_x EQ (size(reform(textureAlpha),/dimensions))[0]) && $
      ( textmap_y EQ (size(reform(textureAlpha),/dimensions))[1]) && $
      ( textmap_type EQ (size(reform(textureAlpha),/type))[0]) $
      THEN BEGIN
      textData = make_array(4,textmap_x,textmap_y,type=textmap_type)
      textData[0,*,*] = textureRed
      textData[1,*,*] = textureGreen
      textData[2,*,*] = textureBlue
      textData[3,*,*] = textureAlpha
    ENDIF ELSE BEGIN
      textData = make_array(3,textmap_x,textmap_y,type=textmap_type)
      textData[0,*,*] = textureRed
      textData[1,*,*] = textureGreen
      textData[2,*,*] = textureBlue
    ENDELSE
    oTextMap = obj_new('idlitDataIDLArray3d', textData, $
                       NAME='TEXTURE')
    oParmSet->add, oTextMap, PARAMETER_NAME= "TEXTURE"
  ENDIF

    ; Check for color table. If set, add that to the data container.
    if (N_Elements(rgbTableIn) gt 0) then begin
        rgbTable = rgbTableIn
        if (N_Elements(rgbTable) eq 1) then $
            Loadct, rgbTable[0], RGB_TABLE=rgbTable
        if (SIZE(rgbTable, /N_DIMENSIONS) EQ 2) then begin
            dim = SIZE(rgbTable, /DIMENSIONS)
            ;; Handle either 3xM or Mx3, but convert to 3xM to store.
            is3xM = dim[0] eq 3
            if ((is3xM || (dim[1] eq 3)) && (MAX(dim) le 256)) then begin
                tableEntries = is3xM ? rgbTable : TRANSPOSE(rgbTable)
            endif
        endif
        if (N_Elements(tableEntries) gt 0) then begin
            ramp = BINDGEN(256)
            palette = TRANSPOSE([[ramp],[ramp],[ramp]])
            palette[*,0:N_Elements(tableEntries[0,*]) -1] = tableEntries
            oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                palette, NAME='Palette')
            oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE"
        endif else begin
            MESSAGE, oSrvLangCat->Query('Message:iSurface:BadDimsRGB_Table')
        endelse
    endif

    return, unknownData
end


;-------------------------------------------------------------------------
PRO isurface, z, x, y, $
    DEBUG=debug, $
    IDENTIFIER=identifier, $
    NODATA=noData, $
    RGB_TABLE=rgbTableIn, $
    _EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    unknownData = iSurface_GetParmSet(oParmSet, z, x, y, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
      RGB_TABLE=rgbTableIn, _EXTRA=_extra)

    ; Send the data to the system for tool creation
    identifier = IDLitSys_CreateTool("Surface Tool", $
        VISUALIZATION_TYPE="SURFACE", $
        INITIAL_DATA=oParmSet, $
        UNKNOWN_DATA=unknownData, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
        WINDOW_TITLE='IDL iSurface',_EXTRA=_EXTRA)

END
