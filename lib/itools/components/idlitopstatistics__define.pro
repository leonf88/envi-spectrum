; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopstatistics__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the statistics action.
;
; MODIFIED:
;   CT, RSI, Nov 2004: Fixed indexing bug with ROI centroids.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopStatistics object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitopStatistics::Init, _EXTRA=_extra
    ;; Pragmas
    compile_opt idl2, hidden

    if ~self->IDLitOperation::Init( $
        NAME="Statistics", $
        TYPE=['IDLVECTOR', 'IDLARRAY2D', 'IDLARRAY3D', $
              'IDLIMAGE','IDLROI', 'IDLLINEPROFILE'], $
        DESCRIPTION="iTools Statistics") then $
        return, 0

    ; Initialize to a null string, just in case.
    self._pText = PTR_NEW('')

    return, 1
end


;-------------------------------------------------------------------------
; IDLitopStatistics::Cleanup
;
; Purpose:
; The destructor of the IDLitopStatistics object.
;
; Parameters:
; None.
;
pro IDLitopStatistics::Cleanup
    ;; Pragmas
    compile_opt idl2, hidden

    PTR_FREE, self._pText
    self->IDLitOperation::Cleanup
end


;-------------------------------------------------------------------------
; IDLitopStatistics::GetProperty
;
; Purpose:
;
; Parameters:
; None.
;
pro IDLitopStatistics::GetProperty, $
    TEXT=text, $
    _REF_EXTRA=_extra

    ;; Pragmas
    compile_opt idl2, hidden

    if (ARG_PRESENT(text)) then $
        text = *self._pText

    if (n_elements(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; IDLitopStatistics::SetProperty
;
; Purpose:
;
; Parameters:
; None.
;
;pro IDLitopStatistics::SetProperty, $
;    _EXTRA=_extra
;
;    ;; Pragmas
;    compile_opt idl2, hidden
;
;    if (n_elements(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end


;-------------------------------------------------------------------------
function itstat_print, x, NON_FLOAT=nonFloat

    compile_opt idl2, hidden

    if (~N_ELEMENTS(x)) then $
        return, '<Undefined>'
    return, (KEYWORD_SET(nonFloat) ? $
        STRTRIM(STRING(x),2) : $
        STRTRIM(STRING(x, FORMAT='(g0)'), 2))
end

;-------------------------------------------------------------------------
function itstat_indices, dims

    compile_opt idl2, hidden

    f = '(8(I,:,", "))'
    dims = STRTRIM(STRCOMPRESS(STRING(dims, FORMAT=f)), 2)
    return, '[' + dims + ']'

end


;---------------------------------------------------------------------------
; IDLitopStatistics::Execute
;
; Purpose: Execute the operation.
;
;   Indent - String giving the current indent characters.
;
; Keywords:
;   DO_GRID_STATS: Set this keyword to a non-zero value to indicate that
;     statistics are to be computed in both grid units and geometry
;     units.  If this keyword is set, the GRID_TARGET keyword must be
;     set to a valid object.  By default, only geometry coordinate
;     statistics are computed.
;     [Note: this keyword is currently only utilized for 2D].
;
;   GRID_TARGET: Set this keyword to a reference to an _IDLitVisGrid2D
;     object for which the given data is a parameter.  If the
;     DO_GRID_STATS keyword is set, then this object is used to retrieve
;     the grid and geometry dimensions and corresponding labels.
;     If the DO_GRID_STATS keyword is not set, but the grid target object
;     is valid, then this object is only used to retrieve the geometry
;     unit label.
;
;   NAN: Set this keyword to force the statistics to look for non-finite
;     values when computing statistics.
;
function IDLitopStatistics::Execute, data, $
    DO_GRID_STATS=doGridStats, $
    GRID_TARGET=oGridTarget, $
    INDENT=indentIn, $
    NAN=nan

    compile_opt idl2, hidden

    ; We need to catch errors here...
    indent = (N_ELEMENTS(indentIn) gt 0) ? indentIn : ''

    ; Filter out types that we can't handle.
    switch SIZE(data, /TYPE) of
        8:  ; struct
        10: ; ptr
        11: return, 0   ; objref
        else: ; okay, do nothing
    endswitch

    ndim = SIZE(data, /N_DIM)

    if (ndim eq 0 || (N_ELEMENTS(data) le 1)) then begin   ; Scalar value
        *self._pText = [*self._pText, $
            indent+IDLitLangCatQuery('Dialog:Value') + ITSTAT_PRINT(data)]

        return, 1
    endif

    ; Array statistics

    haveGrid = N_ELEMENTS(oGridTarget) ? OBJ_VALID(oGridTarget) : 0
    if (KEYWORD_SET(doGridStats)) then begin
        oGridTarget->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep, $
            GRID_UNIT_LABEL=gridUnitLabel, $
            GEOMETRY_UNIT_LABEL=geomUnitLabel

        ; If the geometry unit label matches the grid unit
        ; label, use an empty string for the geometry
        ; unit label to avoid confusion.
        if (STRUPCASE(geomUnitLabel) eq STRUPCASE(gridUnitLabel)) then $
            geomUnitLabel = ''

        geomUnitsP = (geomUnitLabel ? ' ('+geomUnitLabel+')' : '')
        gridUnitsP = (gridUnitLabel ? ' ('+gridUnitLabel+')' : '')
    endif else if (haveGrid) then begin
        oGridTarget->_IDLitVisGrid2D::GetProperty, $
            GRID_UNIT_LABEL=gridUnitLabel, $
            GEOMETRY_UNIT_LABEL=geomUnitLabel
        geomUnitsP = (geomUnitLabel ? ' ('+geomUnitLabel+')' : '')
        gridUnitsP = (gridUnitLabel ? ' ('+gridUnitLabel+')' : '')
    endif else begin
        geomUnitsP = ''
        gridUnitsP = ''
    endelse

    nData = N_ELEMENTS(data)

    moments = MOMENT(data, /DOUBLE, MDEV=mdev, NAN=nan, SDEV=sdev)

    mn = MIN(data, locmin, MAX=mx, NAN=nan, SUBSCRIPT_MAX=locmax)
    tot = TOTAL(data, /DOUBLE, NAN=nan)

    ; Dimensions and number of elements.
    dims = ITSTAT_INDICES(SIZE(data, /DIM))
    if (ndim gt 1) then dims += '  (' + $
        STRTRIM(nData, 2) + ' ' + IDLitLangCatQuery('UI:Elements')

    *self._pText = [*self._pText, $
        indent+IDLitLangCatQuery('UI:Dimensions')+'         ' + dims, $
        indent+IDLitLangCatQuery('UI:Mean')+'               ' + ITSTAT_PRINT(moments[0]), $
        indent+IDLitLangCatQuery('UI:Total')+'              ' + ITSTAT_PRINT(tot)]

    xyMin = ARRAY_INDICES(data,locmin)
    xyMax = ARRAY_INDICES(data,locmax)

    f = '(2(g0,:,", "))'
    if (KEYWORD_SET(doGridStats)) then begin
        oGridTarget->GridToGeometry, [xyMin[0],xyMax[0]], $
            [xyMin[1],xyMax[1]], fxRange, fyRange

        mnLoc = '[' + $
            STRTRIM(STRING([fxRange[0],fyRange[0]], FORMAT=f),2) + ']'
        mxLoc = '[' + $
            STRTRIM(STRING([fxRange[1],fyRange[1]], FORMAT=f),2) + ']'
        pmnLoc = ITSTAT_INDICES(xyMin)
        pmxLoc = ITSTAT_INDICES(xyMax)
    endif else begin
        mnLoc = ITSTAT_INDICES(xyMin)
        mxLoc = ITSTAT_INDICES(xyMax)
    endelse

    if (KEYWORD_SET(doGridStats)) then begin
        *self._pText = [*self._pText, $
            indent+IDLitLangCatQuery('UI:Minimum')+'            ' + ITSTAT_PRINT(mn), $
            indent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mnLoc + geomUnitsP, $
            indent+'                    ' + pmnLoc + gridUnitsP, $
            indent+IDLitLangCatQuery('UI:Maximum')+'            ' + ITSTAT_PRINT(mx), $
            indent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mxLoc + geomUnitsP, $
            indent+'                    ' + pmxLoc + gridUnitsP]
    endif else begin
        *self._pText = [*self._pText, $
            indent+IDLitLangCatQuery('UI:Minimum')+'            ' + ITSTAT_PRINT(mn), $
            indent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mnLoc + geomUnitsP, $
            indent+IDLitLangCatQuery('UI:Maximum')+'            ' + ITSTAT_PRINT(mx), $
            indent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mxLoc + geomUnitsP]
    endelse

    *self._pText = [*self._pText, $
        indent+IDLitLangCatQuery('UI:Variance')+'           ' + ITSTAT_PRINT(moments[1]), $
        indent+IDLitLangCatQuery('UI:StandardDeviation')+' ' + ITSTAT_PRINT(sdev), $
        indent+IDLitLangCatQuery('UI:AbsoluteDeviation')+' ' + ITSTAT_PRINT(mdev), $
        indent+IDLitLangCatQuery('UI:Skewness')+'           ' + ITSTAT_PRINT(moments[2]), $
        indent+IDLitLangCatQuery('UI:Kurtosis3')+'         ' + ITSTAT_PRINT(moments[3]) $
        ]

    if (KEYWORD_SET(nan)) then begin
        nFinite = TOTAL(FINITE(data))
        *self._pText = [*self._pText, $
        indent+IDLitLangCatQuery('UI:NonFiniteValues')+'  ' + ITSTAT_PRINT(nData - nFinite)]
    endif

    return, 1

end


;---------------------------------------------------------------------------
; IDLitopStatistics::_ExecuteOnData
;
; Purpose:
;   Execute the operation on the given data object. This routine
;   will extract the expected data type and pass the value onto
;   the actual operation
;
; Parameters:
;   oData  - The data to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnData, oData, indent

    compile_opt idl2, hidden

    if (~OBJ_VALID(oData)) then $
        return

    ; Retrieve the data and compute statistics.
    iStatus = oData->GetData(pData, /POINTER, NAN=nan)

    if (iStatus eq 1) then begin  ; Do we have data?

        oData->GetProperty, NAME=name
        *self._pText = [*self._pText, $
            '', $
            indent + name]

        ; IDLitDataIDLImagePixels overrides its GetData to return
        ; all the image planes at once. However, we will loop
        ; over them individually down in the container code,
        ; so skip them here.
        if (~OBJ_ISA(oData, 'IDLitDataIDLImagePixels')) then begin
            for i=0,N_ELEMENTS(pData)-1 do begin
                ret = self->IDLitopStatistics::Execute(*pData[i], $
                    INDENT=indent+'  ', NAN=nan)
            endfor
        endif

    endif

    ; Recursively descend into data containers.
    if (OBJ_ISA(oData, 'IDL_Container')) then begin
        oSubdata = oData->Get(/ALL, COUNT=count)
        for i=0,count-1 do begin
            ; Descend into container, and increase indent level.
            self->IDLitopStatistics::_ExecuteOnData, $
                oSubdata[i], indent+'  '
        endfor
    endif

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given Image visualization.
;
; Parameters:
;   oVis  - The Image Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnImage, oVis, indent

    compile_opt idl2, hidden

    ; Get all of my parameters (not just OpTargets).
    oParams = oVis->GetParameter(/ALL, COUNT=count)
    if (count eq 0) then $
        return

    ; Get the Image pixels parameter.
    oImgPixelData = oVis->GetParameter('IMAGEPIXELS')
    if (OBJ_VALID(oImgPixelData)) then begin
        ; Get pixel scaling information for the target image.
        oVis->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep

        ; Determine whether statistics need to be computed for
        ; both data units and pixels.
        doPixelStats = 0b
        oVis->GetProperty, UNIT_LABEL=unitLabel
        if ((gridStep[0] ne 1.0) or $
            (gridStep[1] ne 1.0)) then $
            doPixelStats = 1b

        nChannel = 0
        if (OBJ_ISA(oImgPixelData, 'IDLitDataIDLImagePixels')) then begin
            oChannelData = oImgPixelData->Get(/ALL, COUNT=nChannel)
            if (nChannel gt 0) then begin

                ; Report the image name.
                oImgPixelData->GetProperty, NAME=name
                *self._pText = [*self._pText, $
                    '', $
                    indent + name]
                iindent = (nChannel gt 1) ? indent + '  ' : indent

                pData = PTRARR(nChannel)
                names = STRARR(nChannel)
                nan = 0b
                for i=0,nChannel-1 do begin
                    oChannelData[i]->GetProperty, NAME=name
                    result = oChannelData[i]->GetData(pChannel, /POINTER, NAN=nan1)
                    nan = nan || nan1
                    pData[i] = pChannel
                    names[i] = name
                endfor

            endif
        endif else begin
            nChannel = 1
            oImgPixelData->GetProperty, NAME=name
            result = oImgPixelData->GetData(pChannel, /POINTER, NAN=nan)
            pData = pChannel
            names = name
            iindent = indent
        endelse

        for i=0,nChannel-1 do begin
            if (nChannel gt 1) then begin
                ; Report the channel name.
                *self._pText = [*self._pText, $
                    '', $
                    iindent + names[i]]
            endif

            pChannel = pData[i]
            ret = self->IDLitOpStatistics::Execute(*pChannel, $
                INDENT=iindent+'  ', $
                DO_GRID_STATS=doPixelStats, $
                GRID_TARGET=oVis, NAN=nan)
        endfor
    endif

    ; For all other parameters, just report normal statistics.
    for i=0, count-1 do begin
        if (oParams[i] ne oImgPixelData) then $
            self->IDLitopStatistics::_ExecuteOnData, oParams[i], indent
    endfor

end

;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given ROI visualization.
;
; Parameters:
;   oVis  - The ROI Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnROI, oVis, indent

    compile_opt idl2, hidden

    oVis->GetProperty, PARENT=oParent

    success = oVis->ComputeGeometry(AREA=area, $
        CENTROID=centroid, $
        PERIMETER=perimeter)

    if (~success) then $
        return

    geomUnitLabel = ''
    gridUnitLabel = ''
    doPixelStats = 0b
    if (OBJ_VALID(oParent)) then begin
        if (OBJ_ISA(oParent, 'IDLitVisImage')) then begin
            oParent->_IDLitVisGrid2D::GetProperty, GRID_STEP=gridStep, $
                GRID_UNIT_LABEL=gridUnitLabel, $
                GEOMETRY_UNIT_LABEL=geomUnitLabel

            if ((gridStep[0] ne 1.0) or $
                (gridStep[1] ne 1.0)) then begin

                doPixelStats = oVis->ComputeGeometry(/PIXEL_GEOMETRY, $
                    AREA=pixelArea, $
                    CENTROID=pixelCentroid, $
                    PERIMETER=pixelPerimeter)

                if (doPixelStats) then begin
                    ; If the geometry unit label matches the grid unit
                    ; label, use an empty string for the geometry
                    ; unit label to avoid confusion.
                    if (STRUPCASE(geomUnitLabel) eq $
                        STRUPCASE(gridUnitLabel)) then $
                        geomUnitLabel = ''
                endif
            endif
        endif
    endif

    geomUnitsP = (geomUnitLabel ? ' ('+geomUnitLabel+')' : '')
    geomUnits = (geomUnitLabel ? ' '+geomUnitLabel : '')
    gridUnitsP = (gridUnitLabel ? ' ('+gridUnitLabel+')' : '')
    gridUnits = (gridUnitLabel ? ' '+gridUnitLabel : '')

    *self._pText = [*self._pText, $
        indent + IDLitLangCatQuery('UI:Area')+'               ' + ITSTAT_PRINT(area) + $
            geomUnits]

    if (doPixelStats) then begin
        *self._pText = [*self._pText, $
            indent + '                    ' + ITSTAT_PRINT(pixelArea) + $
            gridUnits]
    endif

    *self._pText = [*self._pText, $
        indent + IDLitLangCatQuery('UI:Perimeter')+'          ' + ITSTAT_PRINT(perimeter) + $
            geomUnits]

    if (doPixelStats) then begin
        *self._pText = [*self._pText, $
            indent + '                    ' + ITSTAT_PRINT(pixelPerimeter) + $
                gridUnits]
    endif

    *self._pText = [*self._pText, $
        indent + IDLitLangCatQuery('UI:Centroid')+'           [' + $
                   ITSTAT_PRINT(centroid[0]) + $
            ', ' + ITSTAT_PRINT(centroid[1]) + $
          (oVis->Is3D() ? $
            ', ' + ITSTAT_PRINT(centroid[2]) : '') + ']' + geomUnitsP]

    if (doPixelStats) then begin
        *self._pText = [*self._pText, $
            indent + '                    [' + $
                       ITSTAT_PRINT(pixelCentroid[0]) + $
                ', ' + ITSTAT_PRINT(pixelCentroid[1]) + ']' + gridUnitsP]
    endif

    if (OBJ_VALID(oParent) eq 0) then $
        return

    mask = oVis->ComputeMask(SUCCESS=success)
    if (~success) then $
        return

    ; Nothing within the mask?
    if (ARRAY_EQUAL(mask, 0b)) then begin
        *self._pText = [*self._pText, indent + IDLitLangCatQuery('UI:NoPoints')]
        return
    endif

    if (~OBJ_ISA(oParent, 'IDLitVisImage')) then $
        return

    oImagePixels = oParent->GetParameter('IMAGEPIXELS')
    if (~OBJ_VALID(oImagePixels)) then $
        return

    if (~oImagePixels->GetData(pData, /POINTER, NAN=nan)) then $
        return

    dims = SIZE(*pData[0], /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2) then $
        return

    nChannels = N_ELEMENTS(pData)
    multiChannel = (nChannels gt 1)

    valid = WHERE(mask, nvalid)

    ; Do we need to check for NaN's within the masked portion?
    if (nan) then begin
        nnan = 0
        for i=0,nChannels-1 do begin
            good = WHERE(FINITE((*pData[i])[valid]), ngood, $
                COMPLEMENT=bad, NCOMPLEMENT=nbad)
            if (~ngood) then $
                return
            if (nbad gt 0) then begin
                nnan += nbad
                ; Set nonfinite mask values to zero. This must be
                ; done before the next line, which modifies "valid".
                mask[valid[bad]] = 0b
                ; Keep only the finite image locations.
                valid = valid[good]
            endif
        endfor
    endif


    for i=0,nChannels-1 do begin
        IMAGE_STATISTICS, *pData[i], MASK=mask, DATA_SUM=dataSum, $
            VARIANCE=variance, COUNT=count, MINIMUM=min, $
            MAXIMUM=max, MEAN=mean, STDDEV=sdev

        ; Number of pixels will be the same for all channels,
        ; so only report once.
        if (i eq 0) then begin
            *self._pText = [*self._pText, $
                indent + IDLitLangCatQuery('UI:Pixels') + '   ' + $
                    ITSTAT_PRINT(count,/NON_FLOAT)]
            if (nan) then begin
                *self._pText = [*self._pText, $
                    indent+IDLitLangCatQuery('UI:NonFiniteValues')+'  ' + $
                    ITSTAT_PRINT(nnan)]
            endif
        endif

        if multiChannel then begin
            *self._pText = [*self._pText, '', $
                indent + IDLitLangCatQuery('UI:Channel') + ' ' + STRTRIM(i, 2)]
        endif

        ; Determine where the min and max values fall within the mask.
        tmpMin = MIN((*pData[i])[valid], iMin, $
            MAX=tmpMax, SUBSCRIPT_MAX=iMax)

        ixMin = valid[iMin] MOD dims[0]
        iyMin = valid[iMin]  /  dims[0]
        ixMax = valid[iMax] MOD dims[0]
        iyMax = valid[iMax]  /  dims[0]

        ; Map back from mask to original data locations.
        oParent->GridToGeometry, [ixMin, ixMax], [iyMin, iyMax], $
            fxRange, fyRange

        f = '(2(g0,:,", "))'
        mn = '[' + $
            STRTRIM(STRING([fxRange[0],fyRange[0]], FORMAT=f),2) + ']'
        mx = '[' + $
            STRTRIM(STRING([fxRange[1],fyRange[1]], FORMAT=f),2) + ']'
        subIndent = multiChannel ? (indent + '  ') : indent

        *self._pText = [*self._pText, $
            subIndent+IDLitLangCatQuery('UI:Mean')+'               ' + ITSTAT_PRINT(mean), $
            subIndent+IDLitLangCatQuery('UI:Total')+'              ' + $
                ITSTAT_PRINT(dataSum), $
            subIndent+IDLitLangCatQuery('UI:Minimum')+'            ' + ITSTAT_PRINT(min), $
            subIndent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mn + geomUnitsP]

        if (doPixelStats) then begin
            pmn = '[' + $
                STRTRIM(STRING([ixMin, iyMin], FORMAT=f),2) + ']'
            *self._pText = [*self._pText, $
                subIndent+'                    ' + pmn + gridUnitsP]
        endif

        *self._pText = [*self._pText, $
            subIndent+IDLitLangCatQuery('UI:Maximum')+'            ' + ITSTAT_PRINT(max), $
            subIndent+'  '+IDLitLangCatQuery('UI:At')+'               ' + mx + geomUnitsP]

        if (doPixelStats) then begin
            pmx = '[' + $
                STRTRIM(STRING([ixMax, iyMax], FORMAT=f),2) + ']'
            *self._pText = [*self._pText, $
                subIndent+'                    ' + pmx + gridUnitsP]
        endif

        *self._pText = [*self._pText, $
            subIndent+IDLitLangCatQuery('UI:StandardDeviation')+' ' + ITSTAT_PRINT(sdev), $
            subIndent+IDLitLangCatQuery('UI:Variance')+'           ' + $
                ITSTAT_PRINT(variance) $
            ]

    endfor

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given Isosurface visualization.
;
; Parameters:
;   oVis  - The Isosurface Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnIsosurface, oVis, indent

    compile_opt idl2, hidden

    oVerts = oVis->GetParameter('VERTICES')
    oConn = oVis->GetParameter('POLYGONS')
    if OBJ_VALID(oVerts) and OBJ_VALID(oConn) then begin
        success1 = oVerts->GetData(verts)
        success2 = oConn->GetData(conn)
        if success1 and success2 then begin
            dims = SIZE(verts, /DIMENSIONS)
            numTri = MESH_NUMTRIANGLES(conn)
            sa = MESH_SURFACEAREA(verts, conn, MOMENT=moment)
            bSolid = MESH_ISSOLID(conn)
            strVolume = bSolid ? MESH_VOLUME(verts, conn) : IDLitLangCatQuery('Message:Stats:NotClosedVolume')
            *self._pText = [*self._pText, $
                indent+IDLitLangCatQuery('UI:NumVerts')+'    ' + ITSTAT_PRINT(dims[1]), $
                indent+IDLitLangCatQuery('UI:NumTriangles')+'   ' + ITSTAT_PRINT(numTri), $
                indent+IDLitLangCatQuery('UI:SurfArea')+'       ' + ITSTAT_PRINT(sa), $
                indent+IDLitLangCatQuery('UI:Volume')+'             ' + strVolume, $
                indent+IDLitLangCatQuery('UI:XMoment')+'           ' + ITSTAT_PRINT(moment[0]), $
                indent+IDLitLangCatQuery('UI:YMoment')+'           ' + ITSTAT_PRINT(moment[1]), $
                indent+IDLitLangCatQuery('UI:ZMoment')+'           ' + ITSTAT_PRINT(moment[2]), $
                indent+IDLitLangCatQuery('UI:XCentroid')+'         ' + ITSTAT_PRINT(moment[0]/sa), $
                indent+IDLitLangCatQuery('UI:YCentroid')+'         ' + ITSTAT_PRINT(moment[1]/sa), $
                indent+IDLitLangCatQuery('UI:ZCentroid')+'         ' + ITSTAT_PRINT(moment[2]/sa)]
        endif
    endif
end

;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given Interval Volume visualization.
;
; Parameters:
;   oVis  - The Interval Volume Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnIntVol, oVis, indent

    compile_opt idl2, hidden

    oVerts = oVis->GetParameter('VERTICES')
    oConn = oVis->GetParameter('POLYGONS')
    oTetra = oVis->GetParameter('TETRAHEDRA')
    if OBJ_VALID(oVerts) and OBJ_VALID(oConn) and OBJ_VALID(oTetra) then begin
        success1 = oVerts->GetData(verts)
        success2 = oConn->GetData(conn)
        success3 = oTetra->GetData(tetra)
        if success1 and success2 and success3 then begin
            dims = SIZE(verts, /DIMENSIONS)
            numTri = MESH_NUMTRIANGLES(conn)
            sa = MESH_SURFACEAREA(verts, conn, MOMENT=moment)
            bSolid = MESH_ISSOLID(conn)
            vol = TETRA_VOLUME(verts, conn, MOMENT=moment)
            *self._pText = [*self._pText, $
                indent+IDLitLangCatQuery('UI:NumVerts')+'    ' + ITSTAT_PRINT(dims[1]), $
                indent+IDLitLangCatQuery('UI:NumTetra')+'  ' + ITSTAT_PRINT(N_ELEMENTS(tetra)/4), $
                indent+IDLitLangCatQuery('UI:NumSurfTris')+'   ' + ITSTAT_PRINT(numTri), $
                indent+IDLitLangCatQuery('UI:SurfArea')+'       ' + ITSTAT_PRINT(sa), $
                indent+IDLitLangCatQuery('UI:Volume')+'             ' + ITSTAT_PRINT(vol),  $
                indent+IDLitLangCatQuery('UI:XMoment')+'           ' + ITSTAT_PRINT(moment[0]), $
                indent+IDLitLangCatQuery('UI:YMoment')+'           ' + ITSTAT_PRINT(moment[1]), $
                indent+IDLitLangCatQuery('UI:ZMoment')+'           ' + ITSTAT_PRINT(moment[2]), $
                indent+IDLitLangCatQuery('UI:XCentroid')+'         ' + ITSTAT_PRINT(moment[0]/vol), $
                indent+IDLitLangCatQuery('UI:YCentroid')+'         ' + ITSTAT_PRINT(moment[1]/vol), $
                indent+IDLitLangCatQuery('UI:ZCentroid')+'         ' + ITSTAT_PRINT(moment[2]/vol)]
        endif
    endif
end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given Surface visualization.
;
; Parameters:
;   oVis  - The Surface Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnSurface, oVis, indent

  compile_opt idl2, hidden

  ;; Get all of my parameters (not just OpTargets).
  oParams = oVis->GetParameter(/ALL, COUNT=count)

  ;; For each parameter, execute the operation.
  FOR i=0, count-1 DO BEGIN
    IF NOT obj_valid(oParams[i]) THEN CONTINUE
    ;; get basic statistics
    self->IDLitopStatistics::_ExecuteOnData, oParams[i], ''

    ;; get name of parameter, if Z add a few more statistics
    oParams[i]->getProperty,name=name
    IF name EQ 'Z' THEN BEGIN
      ;; get zData from surface
      IF ~(oVis->GetParameter('Z'))->getData(zData, NAN=nan) THEN CONTINUE

      ;; get xData or create an indgen based on size of zData
      oXData = oVis->GetParameter('X')
      IF obj_valid(oXData) THEN void = oXData->getData(xData, NAN=xnan) $
      ELSE xData = indgen((size(zData,/dimensions))[0])

      ;; get yData or create an indgen based on size of zData
      oYData = oVis->GetParameter('Y')
      IF obj_valid(oYData) THEN void = oYData->getData(yData, NAN=ynan) $
      ELSE yData = indgen((size(zData,/dimensions))[1])

      ;; calculate area under surface
      xmin = MIN(xData, MAX=xmax, NAN=xnan)
      ymin = MIN(yData, MAX=ymax, NAN=ynan)
      area = (xmax - xmin)*(ymax - ymin)

      ;; calculate volume under surface
      ;; note: this is a very simple approximation done by assuming
      ;; regular columns then taking the average of four Z values * the
      ;; distance in X * the distance in Y
      zMean = (convol(zData,[[1,1],[1,1]], NAN=nan))[1:*,1:*]/4.0
      xDist = (xData[1:*]-xData[0:*])[*,intarr(n_elements(yData)-1)]
      yDist = transpose((yData[1:*]-yData[0:*])[*,intarr(n_elements(xData)-1)])
      volume = total(zMean*xDist*yDist, NAN=nan)

      ;; add data to statistics list
      *self._pText = [*self._pText, $
                      indent+IDLitLangCatQuery('UI:AreaUnderSurf')+' ' + $
                      strtrim(string(area,format='(F20.4)'),2), $
                      indent+IDLitLangCatQuery('UI:ApproxVol')+' ' + $
                      strtrim(string(volume,format='(F20.4)'),2)]
    ENDIF

  ENDFOR                         ; parameters per item

end


;---------------------------------------------------------------------------
; Purpose:
;   Execute the operation on the given Plot visualization.
;
; Parameters:
;   oVis  - The Surface Vis object to operate on.
;   Indent - String giving the current indent characters.
;
pro IDLitopStatistics::_ExecuteOnPlot, oVis, indent

    compile_opt idl2, hidden

    ;; Get all of my parameters (not just OpTargets).
    oParams = oVis->GetParameter(/ALL, COUNT=count)

    ;; For each parameter, execute the operation.
    for i=0, count-1 do begin

        if ~OBJ_VALID(oParams[i]) then $
            continue

        ; Get basic statistics.
        self->IDLitopStatistics::_ExecuteOnData, oParams[i], ''

        ; Get name of parameter, if Y add a few more statistics.
        oParams[i]->GetProperty, NAME=name
        if (STRUPCASE(name) ne 'Y') then $
            continue

        ; Get the Y data.
        oYdata = oVis->GetParameter('Y')
        if (~OBJ_VALID(oYdata) || ~oYdata->GetData(yData, NAN=ynan)) then $
            continue

        ny = N_ELEMENTS(yData)
        if (ny le 1) then $
            return

        ; Get the X data or create a findgen.
        oXdata = oVis->GetParameter('X')
        xnan = 0b
        if (~OBJ_VALID(oXdata) || ~oXdata->GetData(xData, NAN=xnan) || $
            (N_ELEMENTS(xData) ne ny)) then $
            xData = FINDGEN(ny)

        ; See if we need to remove NaN values.
        if (xnan || ynan) then begin
            good = WHERE(FINITE(xData) and FINITE(yData), ny)
            if (ny eq 0) then $
                continue
            xData = xData[good]
            yData = yData[good]
        endif

        ; Average slope. Just take the last & first points
        ; and find the slope between them. Easy.
        slope = (yData[ny-1] - yData[0])/(xData[ny-1] - xData[0])

        ; Curve length.
        xDist = xData[1:*] - xData[0:ny-2]
        yDist = yData[1:*] - yData[0:ny-2]
        length = TOTAL(SQRT(xDist^2d + yDist^2d))

        ; Area under curve.
        ; Note: this approximation assumes regular columns by taking
        ; the average of two Y values * the distances in X.
        yMeans = (yData[0:ny-2] + yData[1:*])/2d
        area = TOTAL(yMeans*xDist)

        ;; add data to statistics list
        *self._pText = [*self._pText, $
            indent + IDLitLangCatQuery('UI:AvSlope')+'      ' + ITSTAT_PRINT(slope), $
            indent + IDLitLangCatQuery('UI:CurveLen')+'       ' + ITSTAT_PRINT(length), $
            indent + IDLitLangCatQuery('UI:AreaUnderCurve')+'   ' + ITSTAT_PRINT(area)]

    endfor

end


;---------------------------------------------------------------------------
function IDLitopStatistics::DoAction, oTool

    compile_opt idl2, hidden

    ; Make sure we have a tool.
    if not obj_valid(oTool) then $
        return, obj_new()

    ; Get the selected objects.
    oSelVis = oTool->GetSelectedItems(count=nVis)

    ; If we have nothing selected, or just the dataspace, then retrieve
    ; all of the contained visualizations. The exact same code exists
    ; in IDLitOpInsertLegend. Perhaps we should encapsulate it in
    ; IDLitgrScene::GetSelectedItems()?
    if (nVis eq 0 || ((nVis eq 1) && $
        OBJ_ISA(oSelVis[0], 'IDLitVisIDataSpace'))) then begin
        oWin = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, OBJ_NEW()
        oView = oWin->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
        oSelVis = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
        if (count eq 0) then $
            return, OBJ_NEW()
    endif

    ; Clear out the statistics.
    *self._pText = [IDLitLangCatQuery('UI:StatsTitle'), SYSTIME()]

    ; For each selected Visual
    for iSelVis=0, N_ELEMENTS(oSelVis)-1 do begin

        oSelVis1 = oSelVis[iSelVis]

        if (~OBJ_VALID(oSelVis1) || $
            ~OBJ_ISA(oSelVis1, 'IDLitParameter')) then $
            continue

        ; Get all of my parameters (not just OpTargets).
        oParams = oSelVis1->GetParameter(/ALL, COUNT=count)
        if (count eq 0) then $
            continue

        ; Skip objects which don't make sense for stats.
        if OBJ_ISA(oSelVis1, 'IDLitVisText') || $
           OBJ_ISA(oSelVis1, 'IDLitVisColorbar') || $
           OBJ_ISA(oSelVis1, 'IDLitVisLegend') then $
           continue

        oSelVis1->GetProperty, NAME=visName
        *self._pText = [*self._pText, '', '', $
            STRJOIN(REPLICATE('_', 49)), $
            visName]

        case (1) of
            OBJ_ISA(oSelVis1, 'IDLitVisROI'): $
                self->IDLitopStatistics::_ExecuteOnROI, oSelVis1, '  '

            OBJ_ISA(oSelVis1, 'IDLitVisImage'): $
                self->IDLitopStatistics::_ExecuteOnImage, oSelVis1, '  '

            OBJ_ISA(oSelVis1, 'IDLitVisIsosurface'): $
                self->IDLitopStatistics::_ExecuteOnIsosurface, oSelVis1, '  '

            OBJ_ISA(oSelVis1, 'IDLitVisIntVol'): $
                self->IDLitopStatistics::_ExecuteOnIntVol, oSelVis1, '  '

            OBJ_ISA(oSelVis1, 'IDLitVisSurface'): $
                self->IDLitopStatistics::_ExecuteOnSurface, oSelVis1, '  '

            OBJ_ISA(oSelVis1, 'IDLitVisPlot'): $
                self->IDLitopStatistics::_ExecuteOnPlot, oSelVis1, '  '

            else: $   ; For each parameter, execute the operation.
                for i=0, count-1 do $
                    self->IDLitopStatistics::_ExecuteOnData, oParams[i], ''
        endcase

    endfor  ; selected items

    ; Display the text.
    success = oTool->DoUIService('TextDisplay', self)

    return, obj_new()   ; no undo/redo command

end


;-------------------------------------------------------------------------
pro IDLitopStatistics__define

    compile_opt idl2, hidden

    struc = {IDLitopStatistics, $
             inherits IDLitOperation,    $
             _pText: PTR_NEW() $
            }

end

