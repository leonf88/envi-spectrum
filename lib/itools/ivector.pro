; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/ivector.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   iMap
;
; PURPOSE:
;   Implements the iVector wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iVector[, U, V][, X, Y]
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2005
;   Modified: CT, Oct 2006: Added TEST keyword,
;       allow RGB_TABLE to be a Loadct table number.
;
;-


;-------------------------------------------------------------------------
pro iVector, parm1, parm2, parm3, parm4, $
    DEBUG=debug, $
    IDENTIFIER=identifier, $
    NODATA=noDataIn, $
    TEST=test, $
    RGB_TABLE=rgbTableIn, $
    STREAMLINES=streamlines, $
    VECTOR_COLORS=vectorColors, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    n = N_PARAMS()

    if (Keyword_Set(test)) then begin
        nx = 41
        xx = 0.25*(Findgen(nx/2))^2
        xx = [-Reverse(xx), 0, xx]
        parm1 = Rebin(-Transpose(xx),nx,nx)  ; U
        parm2 = Rebin(xx,nx,nx)  ; V
        n = 2
    endif

    noData = KEYWORD_SET(noDataIn)

    if (n gt 0) then begin

        if (n ne 2 && n ne 4) then $
            MESSAGE, 'Incorrect number of arguments.'
        ndim = SIZE(parm1, /N_DIMENSIONS)
        if (ndim ne 1 && ndim ne 2) then $
            MESSAGE, 'Arguments U and V must be vectors or 2D arrays.'
        dim = SIZE(parm1, /DIMENSIONS)
        if (~ARRAY_EQUAL(dim, SIZE(parm2, /DIMENSIONS))) then $
            MESSAGE, 'Arguments U and V must have matching dimensions.'
        if (ndim eq 1 && n ne 4) then $
            MESSAGE, 'For U and V vector inputs, X and Y must be supplied.'

        oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
            ICON='fitwindow', DESCRIPTION='Vector parameters')

        class = ndim eq 2 ? 'IDLitDataIDLArray2d' : 'IDLitDataIDLVector'
        oData1 = OBJ_NEW(class, parm1, NAME='U component')
        oData2 = OBJ_NEW(class, parm2, NAME='V component')
        oParmSet->Add, oData1, PARAMETER_NAME='U component'
        oParmSet->Add, oData2, PARAMETER_NAME='V component'

        if (n eq 4) then begin

            if (SIZE(parm3, /N_DIMENSIONS) ne 1) then $
                MESSAGE, 'Argument X must be a vector'
            if (N_ELEMENTS(parm3) ne dim[0]) then $
                MESSAGE, 'Incorrect number of elements for X.'

            if (SIZE(parm4, /N_DIMENSIONS) ne 1) then $
                MESSAGE, 'Argument Y must be a vector'
            if ((ndim eq 2 && N_ELEMENTS(parm4) ne dim[1]) || $
                (ndim eq 1 && N_ELEMENTS(parm4) ne dim[0])) then $
                MESSAGE, 'Incorrect number of elements for Y.'

            oData3 = OBJ_NEW('IDLitDataIDLVector', parm3, NAME='X')
            oData4 = OBJ_NEW('IDLitDataIDLVector', parm4, NAME='Y')
            oParmSet->Add, oData3, PARAMETER_NAME='X'
            oParmSet->Add, oData4, PARAMETER_NAME='Y'
        endif

        ; auto range for /NODATA
        if (noData) then begin
          if (n eq 4) then begin
            xr = [parm3[0], parm3[-1]]
            yr = [parm4[0], parm4[-1]]
          endif else begin
            xr = [0, dim[0]-1]
            yr = [0, dim[1]-1]
          endelse
        endif
    endif

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
            if (~OBJ_VALID(oParmSet)) then begin
                oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                    ICON='fitwindow', DESCRIPTION='Vector parameters')
            endif
            oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE"
        endif else begin
            MESSAGE, "Incorrect dimensions for RGB_TABLE."
        endelse
    endif

    ; Check for vertex colors. If set, add that to the data container.
    nColors = N_ELEMENTS(vectorColors)
    if (nColors gt 0) then begin
        ndim = SIZE(vectorColors, /N_DIMENSIONS)
        vdim = SIZE(vectorColors, /DIMENSIONS)
        if (ndim gt 2) then $
            MESSAGE, 'VECTOR_COLORS must be a one or two-dimensional array.'
        if (N_ELEMENTS(parm1) gt 0) then begin
            ; See if we have an array of RGB or RGBA values.
            if (ndim eq 2 && (vdim[0] eq 3 || vdim[0] eq 4)) then $
                nColors = vdim[1]
            if (nColors ne N_ELEMENTS(parm1)) then $
                MESSAGE, 'Number of elements in VECTOR_COLORS does not match inputs.'
        endif
        if (~OBJ_VALID(oParmSet)) then begin
            oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                ICON='fitwindow', DESCRIPTION='Vector parameters')
        endif
        oVert = OBJ_NEW((ndim eq 1) ? $
            'idlitDataIDLVector' : 'idlitDataIDLArray2D', vectorColors, $
            NAME='VECTOR COLORS')
        oParmSet->Add, oVert, PARAMETER_NAME="VECTOR COLORS"
    endif

    ; Set the autodelete mode on the parameter set.
    if (OBJ_VALID(oParmSet)) then $
        oParmSet->SetAutoDeleteMode, 1

    visType = KEYWORD_SET(streamlines) ? "STREAMLINE" : "VECTOR"

    ; Send the data to the system for tool creation
    identifier = IDLitSys_CreateTool("Vector Tool", $
        VISUALIZATION_TYPE=visType, $
        INITIAL_DATA=oParmSet, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, $
        WINDOW_TITLE='IDL iVector',_EXTRA=_EXTRA)

end



