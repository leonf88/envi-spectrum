; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/iplot.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   IPLOT
;
; PURPOSE:
;   Fire up the plot iTool.
;
; CALLING SEQUENCE:
;   IPLOT, [[x],y] (for 2D plot)
; OR
;   IPLOT, x,y,z (for 3D plot)
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
;   SCATTER
;   Set this keyword to generate a scatter plot.  This is equivalent
;   to setting LINESTYLE=6 (no line) and SYM_INDEX=3 (Period symbol).
;
;   [XYZ]ERROR
;   Set this keyword to either a vector or a 2xN array of error
;   values to be displayed as error bars for the [XYZ] dimension
;   of the plot.  The length of this array must be equal in length
;   to the number of vertices of the plot or it will be ignored.
;   If the value is a vector, the value will be applied as both a
;   negative and positive error and the error bar will be symmetric
;   about the plot vertex.  If the value is a 2xN array the [0,*]
;   values define the negative error and the [1,*] values define
;   the positive error, allowing asymmetric error bars.;
;
;   RGB_TABLE
;   Set this keyword to the number of the predefined IDL color table (0 to 40),
;   or to either a 3 by 256 or 256 by 3 byte array containing color values
;   to use for vertex colors. If the values supplied are not of type byte,
;   they are scaled to the byte range using BYTSCL. Use the VERT_COLORS
;   keyword to specify indices that select colors from the values specified
;   with RGB_TABLE.
;
;   VERT_COLORS
;   Set this keyword to a vector of indices into the color table
;   to select colors to use for vertex colors or a 3xN or 4xN array of
;   colors values to use directly.  If the number of indices or
;   colors is less than the number of vertices, the colors are
;   repeated cyclically.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:    AY, RSI, February 2003: Update to allow 3D data
;   Modified: CT, Oct 2006: Added helper function, TEST keyword,
;       allow RGB_TABLE to be a Loadct table number.
;
;-


;-----------------------------------------------------------------------
; Helper routine to construct the parameter set.
; If no parameters are supplied then oParmSet will be undefined.
;
function iPlot_GetParmSet, oParmSet, parm1, parm2, parm3, $
    TEST=test, $
    RGB_TABLE=rgbTableIn, $
    VERT_COLORS=VERT_COLORS, $
    XERROR=xError, $
    YERROR=yError, $
    ZERROR=zError, $
    NODATA=noDataIn, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
    _EXTRA=_EXTRA

    compile_opt idl2, hidden

    nParams = N_Params()
    if (Keyword_Set(test)) then begin
        parm1 = Findgen(200)
        parm2 = Sin(parm1*2*!PI/25.0)*Exp(-0.01*parm1)
        nParams = 3
    endif

    if (nParams le 1) then return, ''
    
    noData = KEYWORD_SET(noDataIn)

    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME='Plot parameters', $
        ICON='plot', $
        DESCRIPTION='Plot parameters')
    oParmSet->SetAutoDeleteMode, 1b

   case (nParams) of
   2: begin
         ; Check for undefined variables.
         if (N_ELEMENTS(parm1) eq 0) then $
             MESSAGE, 'First argument is an undefined variable.'

         ; eliminate leading dimensions of 1
         parm1 = reform(parm1)

         ; y only for 2D plot
         case (SIZE(parm1, /N_DIMENSIONS)) of
         1: begin
            ; 2D plot, y in a vector
            visType = 'PLOT'
            oDataY = obj_new('idlitDataIDLVector', parm1, NAME='Y')
            oParmSet->add, oDataY, PARAMETER_NAME='Y'

            ; auto range for /NODATA
            if (noData) then begin
              xr = [0, N_ELEMENTS(parm1)-1]
              mn = MIN(parm1, y_mnloc, MAX=mx, SUBSCRIPT_MAX=y_mxloc)
              yr = [mn, mx]
            endif
         end
         2: begin
            dims = SIZE(parm1, /DIMENSIONS)
            case dims[0] of
            2: begin
               ; 2D plot, x,y in one 2xN array
               visType = 'PLOT'
               oDataXY = OBJ_NEW('IDLitDataIDLArray2D', $
                                 NAME='VERTICES', $
                                 parm1)
               oParmSet->Add, oDataXY, PARAMETER_NAME='VERTICES'

               ; auto range for /NODATA
               if (noData) then begin
                 mn = MIN(parm1, mnloc, DIM=2, MAX=mx, SUBSCRIPT_MAX=mxloc)
                 y_mnloc = mnloc[1]
                 y_mxloc = mxloc[1]
                 xr = [mn[0], mx[0]]
                 yr = [mn[1], mx[1]]
               endif
            end
            3: begin
               ; 3D plot, x,y,z in one 3xN array
               visType = 'PLOT3D'
               oDataXYZ = OBJ_NEW('IDLitDataIDLArray2D', $
                                  NAME='VERTICES', $
                                  parm1)
               oParmSet->Add, oDataXYZ, PARAMETER_NAME='VERTICES'

               ; auto range for /NODATA
               if (noData) then begin
                 mn = MIN(parm1, mnloc, DIM=2, MAX=mx, SUBSCRIPT_MAX=mxloc)
                 z_mnloc = mnloc[2]
                 z_mxloc = mxloc[2]
                 y_mnloc = mnloc[1]
                 y_mxloc = mxloc[1]
                 xr = [mn[0], mx[0]]
                 yr = [mn[1], mx[1]]
                 zr = [mn[2], mx[2]]
               endif
            end
            else: MESSAGE, 'First argument has invalid dimensions'
            endcase
         end
         else: MESSAGE, 'First argument has invalid dimensions'
         endcase
      end
   3: begin
         ; Check for undefined variables.
         if (N_ELEMENTS(parm1) eq 0) then $
             MESSAGE, 'First argument is an undefined variable.'

         ; Check for undefined variables.
         if (N_ELEMENTS(parm2) eq 0) then $
             MESSAGE, 'Second argument is an undefined variable.'

         ; eliminate leading dimensions of 1
         parm1 = reform(parm1)
         parm2 = reform(parm2)

         ; x and y for 2D plot
         if ((SIZE(parm1, /N_DIMENSIONS) eq 1) AND $
            (SIZE(parm2, /N_DIMENSIONS) eq 1) AND $
            (N_ELEMENTS(parm1) eq N_ELEMENTS(parm2))) then begin
            visType = 'PLOT'
            oDataX = obj_new('idlitDataIDLVector', parm1, NAME='X')
            oDataY = obj_new('idlitDataIDLVector', parm2, NAME='Y')
            oParmSet->add, oDataX, PARAMETER_NAME='X'
            oParmSet->add, oDataY, PARAMETER_NAME='Y'
         endif else begin
            MESSAGE, 'Arguments have invalid dimensions'
         endelse

          ; auto range for /NODATA
          if (noData) then begin
            xr = [MIN(parm1, MAX=mx), mx]
            yr = [MIN(parm2, y_mnloc, MAX=mx, SUBSCRIPT_MAX=y_mxloc), mx]
          endif

   end

   4: begin
         ; Check for undefined variables.
         if (N_ELEMENTS(parm1) eq 0) then $
             MESSAGE, 'First argument is an undefined variable.'

         ; Check for undefined variables.
         if (N_ELEMENTS(parm2) eq 0) then $
             MESSAGE, 'Second argument is an undefined variable.'

         ; Check for undefined variables.
         if (N_ELEMENTS(parm3) eq 0) then $
             MESSAGE, 'Third argument is an undefined variable.'

         ; eliminate leading dimensions of 1
         parm1 = reform(parm1)
         parm2 = reform(parm2)
         parm3 = reform(parm3)

         ; x, y, z for 3D plot
         nX = N_ELEMENTS(parm1)
         nY = N_ELEMENTS(parm2)
         nZ = N_ELEMENTS(parm3)
         if ((SIZE(parm1, /N_DIMENSIONS) eq 1) AND $
            (SIZE(parm2, /N_DIMENSIONS) eq 1) AND $
            (SIZE(parm2, /N_DIMENSIONS) eq 1) AND $
            (nX eq nY) AND $
            (nY eq nZ)) then begin
               visType = 'PLOT3D'
               oDataX = obj_new('idlitDataIDLVector', parm1, NAME='X')
               oDataY = obj_new('idlitDataIDLVector', parm2, NAME='Y')
               oDataZ = obj_new('idlitDataIDLVector', parm3, NAME='Z')
               oParmSet->add, oDataZ, PARAMETER_NAME='Z'
               oParmSet->add, oDataX, PARAMETER_NAME='X'
               oParmSet->add, oDataY, PARAMETER_NAME='Y'
         endif else begin
            MESSAGE, 'Arguments have invalid dimensions'
         endelse

          ; auto range for /NODATA
          if (noData) then begin
            xr = [MIN(parm1, MAX=mx), mx]
            mn = MIN(parm2, y_mnloc, MAX=mx, SUBSCRIPT_MAX=y_mxloc)
            yr = [mn, mx]
            mn = MIN(parm3, z_mnloc, MAX=mx, SUBSCRIPT_MAX=z_mxloc)
            zr = [mn, mx]
          endif
      end
   endcase

   ; Check for X error values. If set, add them to the data container.
   ; only process error values if a data parameter was supplied
   IF (keyword_set(xError)) THEN BEGIN
      dataDims = SIZE(parm1, /DIMENSIONS)
      nDataVertices = dataDims[0]
      ; eliminate leading dimensions of 1
      if n_elements(xError) gt 0 then xError=reform(xError)
      nErrorDims = SIZE(xError, /N_DIMENSIONS)
      errorDims = SIZE(xError, /DIMENSIONS)
      if (nErrorDims eq 1 && errorDims[0] eq nDataVertices) || $
         (nErrorDims eq 2 && errorDims[0] eq 2 && $
         errorDims[1] eq nDataVertices) then begin

         if (nErrorDims eq 1) then $
            dataType = 'VECTOR' $
         else $
            dataType = 'ARRAY2D'

         oXError = obj_new('idlitDataIDL'+dataType, $
                        xError, $
                        NAME='X ERROR')
         oParmSet->add, oXError, PARAMETER_NAME='X ERROR'
      endif else begin
         MESSAGE, 'XERROR value has invalid dimensions'
      endelse
      
      ; If we are supplying XRANGE, take error bars into account.
      if ISA(xr) then begin
        xr[0] -= xError[0]
        xr[1] += xError[-1]
      endif
   ENDIF

   ; Check for Y error values. If set, add them to the data container.
   ; only process error values if a data parameter was supplied
   IF (keyword_set(yError)) THEN BEGIN
      dataDims = SIZE(parm1, /DIMENSIONS)
      nDataVertices = dataDims[0]
      ; eliminate leading dimensions of 1
      if n_elements(yError) gt 0 then yError=reform(yError)
      nErrorDims = SIZE(yError, /N_DIMENSIONS)
      errorDims = SIZE(yError, /DIMENSIONS)
      if (nErrorDims eq 1 && errorDims[0] eq nDataVertices) || $
         (nErrorDims eq 2 && errorDims[0] eq 2 && $
         errorDims[1] eq nDataVertices) then begin

         if (nErrorDims eq 1) then $
            dataType = 'VECTOR' $
         else $
            dataType = 'ARRAY2D'

         oYError = obj_new('idlitDataIDL'+datatype, $
                        yError, $
                        NAME='Y ERROR')
         oParmSet->add, oYError, PARAMETER_NAME='Y ERROR'
      endif else begin
         MESSAGE, 'YERROR value has invalid dimensions'
      endelse

      ; If we are supplying YRANGE, take error bars into account.
      if (noData && ISA(yr)) then begin
        yr[0] -= yError[y_mnloc]
        yr[1] += yError[y_mxloc]
      endif
   ENDIF

   ; Check for Z error values. If set, add them to the data container.
   ; only process error values if a data parameter was supplied
   IF (keyword_set(zError)) THEN BEGIN
      dataDims = SIZE(parm1, /DIMENSIONS)
      nDataVertices = dataDims[0]
      ; eliminate leading dimensions of 1
      if n_elements(zError) gt 0 then zError=reform(zError)
      nErrorDims = SIZE(zError, /N_DIMENSIONS)
      errorDims = SIZE(zError, /DIMENSIONS)
      if (nErrorDims eq 1 && errorDims[0] eq nDataVertices) || $
         (nErrorDims eq 2 && errorDims[0] eq 2 && $
         errorDims[1] eq nDataVertices) then begin

         if (nErrorDims eq 1) then $
            dataType = 'VECTOR' $
         else $
            dataType = 'ARRAY2D'

         oZError = obj_new('idlitDataIDL'+dataType, $
                        zError, $
                        NAME='Z ERROR')
         oParmSet->add, oZError, PARAMETER_NAME='Z ERROR'
      endif else begin
         MESSAGE, 'ZERROR value has invalid dimensions'
      endelse

      ; If we are supplying ZRANGE, take error bars into account.
      if ISA(zr) then begin
        zr[0] -= zError[z_mnloc]
        zr[1] += zError[z_mxloc]
      endif
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
                if (size(tableEntries, /TYPE) ne 1) then $
                    tableEntries=Bytscl(tableEntries)
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

   IF keyword_set(VERT_COLORS) THEN BEGIN
      vertType = ''
      ; eliminate leading dimensions of 1
      if n_elements(VERT_COLORS) gt 0 then VERT_COLORS=reform(VERT_COLORS)
      ndim = size(VERT_COLORS,/n_dimensions)
      IF (ndim EQ 1) then begin
         vertType = 'idlitDataIDLVector'
      ENDIF else begin
        dims = size(VERT_COLORS,/dimensions)
          IF (ndim EQ 2) && (dims[0] EQ 3 || dims[0] eq 4) then begin
             vertType = 'idlitDataIDLArray2D'
          ENDIF
      endelse
      IF strlen(vertType) gt 0 THEN BEGIN
         oVert = obj_new(vertType, VERT_COLORS, $
                        NAME='Vertex Colors')
         oParmSet->add, oVert,PARAMETER_NAME="VERTEX_COLORS"
      ENDIF ELSE BEGIN
         MESSAGE, 'VERT_COLORS value has invalid dimensions'
      ENDELSE
   ENDIF

    ; Set the appropriate visualization type.
    oParmSet->SetProperty, TYPE=visType

    return, visType
end

;-------------------------------------------------------------------------
pro iplot, parm1, parm2, parm3, $
    DEBUG=debug, $
    IDENTIFIER=identifier, $
    RGB_TABLE=rgbTableIn, $
    SCATTER=scatter, $
    NODATA=noData, $
    _EXTRA=_extra

    compile_opt hidden, idl2

; Note: The error handler will clean up the oParmSet container.
@idlit_itoolerror.pro

    nParams = N_Params()

    case (nParams) of
    0: visType = iPlot_GetParmSet(oParmSet, RGB_TABLE=rgbTableIn, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, _EXTRA=_extra)
    1: visType = iPlot_GetParmSet(oParmSet, parm1, RGB_TABLE=rgbTableIn, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, _EXTRA=_extra)
    2: visType = iPlot_GetParmSet(oParmSet, parm1, parm2, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, RGB_TABLE=rgbTableIn, _EXTRA=_extra)
    3: visType = iPlot_GetParmSet(oParmSet, parm1, parm2, parm3, $
      NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, RGB_TABLE=rgbTableIn, _EXTRA=_extra)
    endcase
    
    if (keyword_set(scatter)) then begin
        lineStyle=6
        symIndex=3
    endif

    identifier = IDLitSys_CreateTool("Plot Tool", $
        INITIAL_DATA=oParmSet, $
        WINDOW_TITLE='IDL iPlot', $
        VISUALIZATION_TYPE=visType, $
        LINESTYLE=lineStyle, $
        SYM_INDEX=symIndex, $
        NODATA=noData, XRANGE=xr, YRANGE=yr, ZRANGE=zr, $
        _EXTRA=_extra)

end

