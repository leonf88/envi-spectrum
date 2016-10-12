; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/icontour.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iContour
;
; PURPOSE:
;   Implements the icontour wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   IContour
;
; INPUTS:
;   Z[,X,Y] [,...] (see IDLgrContour)
;
; KEYWORD PARAMETERS:
;   IDENTIFIER  [out] - The identifier of the created tool.
;
;   RGB_TABLE
;   Set this keyword to the number of the predefined IDL color
;   table (0 to 40), or to either a 3 by 256 or 256 by 3 array containing
;   color values to use for contour level colors.
;
;   RGB_INDICES
;   Set this keyword to a vector of indices into the color table
;   to select colors to use for vertex colors.  If the number of
;   colors selected is less than the number of vertices, the
;   colors are repeated cyclically.
;
;   All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  Alan, RSI, January 2003
;   Modified: CT, Oct 2006: Added helper function, TEST keyword,
;       allow RGB_TABLE to be a Loadct table number.
;
;-


;-----------------------------------------------------------------------
; Helper routine to construct the parameter set.
; If no parameters are supplied then oParmSet will be undefined.
;
function iContour_GetParmSet, oParmSet, z, x, y, $
    TEST=test, $
    RGB_TABLE=rgbTableIn, $
    RGB_INDICES=rgbIndices, $
    NODATA=noDataIn, XRANGE=xr, YRANGE=yr, ZRANGE=zr

    compile_opt idl2, hidden

    if (Keyword_Set(test)) then begin
        file = FILEPATH('convec.dat', SUBDIRECTORY = ['examples', 'data'])
        z = READ_BINARY(file, DATA_DIMS = [248, 248])
        if (N_Elements(rgbTableIn) eq 0) then $
            Loadct, 39, RGB_TABLE=rgbTableIn
    endif

    if (N_Elements(z) eq 0) then return, 0b

    noData = KEYWORD_SET(noDataIn)

    unknownData = 0b

    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME='Contour parameters', $
        ICON='contour', $
        DESCRIPTION='Contour parameters')
    oParmSet->SetAutoDeleteMode, 1

    case SIZE(z, /N_DIMENSIONS) of

    1: begin
        nx = N_ELEMENTS(x)
        ny = N_ELEMENTS(y)
        nz = N_ELEMENTS(z)
        if ((nx eq ny) && (ny eq nz)) then BEGIN
            oDataX = OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT X', $
                                 REFORM(x, nz))
            oDataY = OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Y', $
                                 REFORM(y, nz))
            oDataZ = OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Z', $
                                 REFORM(z, nz))
            ; Do not give parameter names when adding,
            ; since these need to be gridded, and are not
            ; valid contour parameters.
            oParmSet->Add, oDataX
            oParmSet->Add, oDataY
            oParmSet->Add, oDataZ
            ; Fire up the unknown data wizard after starting the tool.
            unknownData = 1
        endif else begin
            MESSAGE, 'Arguments have invalid dimensions'
        endelse

        ; auto range for /NODATA
        if (noData) then begin
          xr = [x[0], x[-1]]
          yr = [y[0], y[-1]]
          zr = [MIN(z, MAX=mx), mx]
        endif
    end

    2: begin
        oDataZ = OBJ_NEW('IDLitDataIDLArray2d', Z, $
                            NAME='Z')
        oParmSet->add, oDataZ, PARAMETER_NAME="Z"
        zDims = size(z, /dimensions)
        
        ; auto range for /NODATA
        if (noData) then begin
          zr = [MIN(z, MAX=mx), mx]
          xr = [0, zDims[0]]
          yr = [0, zDims[1]]
        endif

        nx = N_ELEMENTS(X)
        ny = N_ELEMENTS(Y)
        IF (nx NE 0 || ny NE 0) THEN BEGIN
            validXY = 0b
            xDims = size(x, /dimensions)
            yDims = size(y, /dimensions)

            ; if X and Y cover the x and y dimensions, resp. of Z
            ; add them to the data set
            if ((nx eq zDims[0]) && (ny eq zDims[1])) then BEGIN
                oDataX = obj_new('idlitDataIDLVector', X, NAME='X')
                oDataY = obj_new('idlitDataIDLVector', Y, NAME='Y')
                oParmSet->add, oDataX, PARAMETER_NAME="X"
                oParmSet->add, oDataY, PARAMETER_NAME="Y"
                validXY = 1b
            endif

            ; if both X and Y exist as 2D arrays of the same dim
            ; as z add them to the data set
            IF array_equal(zDims,xDims) && array_equal(zDims,yDims) THEN BEGIN
              oDataX = obj_new('IDLitDataIDLArray2D',  X, NAME='X')
              oDataY = obj_new('IDLitDataIDLArray2D', Y, NAME='Y')
              oParmSet->add, oDataX, PARAMETER_NAME="X"
              oParmSet->add, oDataY, PARAMETER_NAME="Y"
              validXY = 1b
            ENDIF

            IF ~validXY THEN BEGIN
              MESSAGE, 'X or Y argument has invalid dimensions'
            ENDIF

            ; auto range for /NODATA
            if (noData) then begin
              xr = [MIN(x, MAX=mx), mx]
              yr = [MIN(y, MAX=mx), mx]
              ; We already did Z above.
            endif
        endif
    end

    else: MESSAGE, 'First argument has invalid dimensions'

    ENDCASE

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
            MESSAGE, "Incorrect dimensions for RGB_TABLE."
        endelse
    endif

    ; Check for color table indices. If set, add that to the data container.
    if (SIZE(rgbIndices,/n_dimensions))[0] EQ 1 then begin
      oColorIndices = OBJ_NEW('IDLitDataIDLVector', rgbIndices, $
                      NAME='RGB Indices', TYPE='IDLVECTOR', icon='layer')
      oParmSet->add, oColorIndices, PARAMETER_NAME="RGB_INDICES"
    endif

    return, unknownData

end


;-------------------------------------------------------------------------
pro icontour, z, x, y, $
    DEBUG=debug, $
    IDENTIFIER=IDENTIFIER, $
    NODATA=noData, $
    RGB_TABLE=rgbTableIn, $
    _EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    unknownData = iContour_GetParmSet(oParmSet, z, x, y, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
      RGB_TABLE=rgbTableIn, _EXTRA=_extra)

    ; Send the data to the system for tool creation
    IDENTIFIER = IDLitSys_CreateTool("Contour Tool", $
        VISUALIZATION_TYPE="CONTOUR", $
        UNKNOWN_DATA=unknownData, $
        INITIAL_DATA=oParmSet, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
        WINDOW_TITLE='IDL iContour',_EXTRA=_extra)

end
