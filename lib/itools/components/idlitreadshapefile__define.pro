; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadshapefile__define.pro#1 $
;
; Copyright (c) 2004-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadShapefile class.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadShapefile::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if (~self->IDLitReader::Init("shp", $
        NAME='ESRI Shapefile', $
        DESCRIPTION="ESRI Shapefile (shp)", $
        ICON='drawing', $
        _EXTRA=_extra)) then $
        return, 0

    self->RegisterProperty, 'COMBINE_ALL', /BOOLEAN, $
        NAME='Combine all shapes', $
        DESCRIPTION='Combine all shapes into a single data object'

    self->RegisterProperty, 'ATTRIBUTE_NAME', $
        ENUMLIST=['<Shape index>'], $
        NAME='Name attribute', $
        DESCRIPTION='Attribute to use for the shape name'

    ; Combine all shapes by default.
    self._combineAll = 1

    return, 1
end


;---------------------------------------------------------------------------
pro IDLitReadShapefile::GetProperty, $
    COMBINE_ALL=combineAll, $
    ATTRIBUTE_NAME=attributeName, $
    LIMIT=limit, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(combineAll) then $
        combineAll = self._combineAll

    if ARG_PRESENT(attributeName) then $
        attributeName = self._attributeIndex

    if ARG_PRESENT(limit) then $
        limit = self._limit

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitReader::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitReadShapefile::SetProperty, $
    COMBINE_ALL=combineAll, $
    ATTRIBUTE_NAME=attributeName, $
    LIMIT=limit, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(combineAll) eq 1) then begin
        self._combineAll = combineAll
        self->SetPropertyAttribute, 'ATTRIBUTE_NAME', $
            SENSITIVE=~self._combineAll
    endif

    if (N_ELEMENTS(attributeName) eq 1) then $
        self._attributeIndex = attributeName

    if (N_ELEMENTS(limit) gt 0) then $
        self._limit = limit

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitReader::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitReadShapefile::_GetNameAttribute
;
; Purpose:
;   Given a shape object, returns the best guess for the index of the
;   attribute to be used for the name of each shape.
;   Returns -1 if no useable attribute exists.
;
function IDLitReadShapefile::_GetNameAttribute, oShape

    compile_opt idl2, hidden

    oShape->GetProperty, N_ATTRIBUTES=nAttr
    if (~nAttr) then $
        return, -1

    oShape->GetProperty, ATTRIBUTE_INFO=attrInfo, $
        N_ENTITIES=nEntity

    ; See if we have a string attribute, and assume this is a name.
    strIndex = WHERE(attrInfo.type eq 7, nstr)
    if (~nstr) then $
        return, -1

    widest = MAX(attrInfo[strIndex].width, loc)
    nameIndex = strIndex[loc]

    ; If we have just one entity then we can go ahead
    ; and use the attribute.
    if (nEntity eq 1) then $
        return, nameIndex

    ; Otherwise, make sure that our supposed name attribute
    ; actually varies per entity.
    attr0 = oShape->GetAttributes(0)
    attr1 = oShape->GetAttributes(1)
    return, (attr0.(nameIndex) ne attr1.(nameIndex)) ? nameIndex : -1

end


;---------------------------------------------------------------------------
; This logic is to find the continent of Antartica which is screwed up
; in the shapefile.  They add a bunch of extraneous points between the
; pole and the international dateline (both + and - 180 degs), to make
; a simple plot of the vertices look good on a cylindrical map,
; centered on the prime meridian.  This screws up our polygon
; filling and adds an extraneous line on Antarctica. We then
; remove the extraneous points.
;
function IDLitReadShapefile::_FixAntarctica, pVert, $
    pStart, nSubVert, index

    compile_opt idl2, hidden

    xy = (*pVert)[*, pStart:pStart+nSubvert-1]

    ; Make sure we have the South Pole.
    if total(xy[1,*] eq -90) lt 2 then $
        goto, bailout

    ; Need to make counterclockwise for fill to work correctly.
    xy = REVERSE(xy, 2)

    ; Find the points which run along the dateline.
    bad = WHERE(ABS(xy[0, *]) eq 180, nbad)
    if (nbad lt 2) then $
        goto, bailout

    ; Tweak the points at the beginning/end of the cut so
    ; they don't lie exactly on +/-180.
    i1 = bad[0]
    i2 = bad[nbad-1]
    xy[0, i1] = (xy[0, i1] eq 180) ? 179.99 : -179.99
    xy[0, i2] = (xy[0, i2] eq 180) ? 179.99 : -179.99

    ; Put the points back together.
    xy = [[xy[*, i2:*]], [xy[*, 0:i2-1]]]
    (*pVert)[0, pStart] = xy

    ; Return connectivity array containing only the non-pole values.
    nbad = i2 - i1 - 1
    ngood = nSubVert - nbad
    return, [ngood, LINDGEN(ngood) + pStart + index]

bailout:
    ; Just return a regular connectivity list.
    return, [nSubVert, LINDGEN(nSubVert) + pStart + index]

end


;---------------------------------------------------------------------------
; IDLitReadShapefile::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadShapefile::GetData, oData

    compile_opt idl2, hidden

    strFilename = self->GetFilename()

    oShape = OBJ_NEW('IDLffShape')

    unableRead = "Unable to read file '" + strFilename + "'"
    if (~oShape->Open(strFilename)) then begin
        self->SignalError, unableRead, SEVERITY=2
        OBJ_DESTROY, oShape
        return, 0
    endif

    oShape->GetProperty, $
        ENTITY_TYPE=entityType, $
        N_ATTRIBUTES=nAttr, $
        N_ENTITIES=nEntity

    if (nEntity eq 0) then begin
        OBJ_DESTROY, oShape
        return, 0
    endif

    case entityType of
    1: idlshapetype = 'IDLSHAPEPOINT'
    3: idlshapetype = 'IDLSHAPEPOLYLINE'
    5: idlshapetype = 'IDLSHAPEPOLYGON'
    11: idlshapetype = 'IDLSHAPEPOINT'
    else: begin
        self->SignalError, $
            [unableRead, $
            'Cannot read shapefile entities of type: ' + $
                STRTRIM(entityType, 2)], $
            SEVERITY=2
        OBJ_DESTROY, oShape
        return, 0
    end
    endcase


    ; Two or three dimensional data.
    switch entityType of
    1: ; Point - fall thru
    3: ; Polyline - fall thru
    5: begin  ; Polygon
        ndim = 2
        break
       end
    11: ; PointZ - fall thru
    13: ; PolylineZ - fall thru
    15: begin  ; PolygonZ
        ndim = 3
        break
        end
    endswitch

    ; Minimum # of vertices. Polylines need 2, polygons need 3.
    minVert = (entityType eq 3) ? 2 : 3

    ; Best guess for name attribute.
    nameIndex = self._attributeIndex < nAttr

    filename = FILE_BASENAME(strFilename, '.shp', /FOLD_CASE)

    index = 0L

    if (~self._combineAll) then $
        oData = OBJARR(nEntity)

    ; Honor the LIMIT property if they aren't all equal (say to 0),
    ; and if they actually limit the globe to some extent.
    ; Otherwise it isn't worth the effort.
    isEqual = ARRAY_EQUAL(self._limit, self._limit[0])
    diffLon = ABS(self._limit[3] - self._limit[1])
    diffLat = ABS(self._limit[2] - self._limit[0])
    useLimit = ~isEqual && (diffLon lt 350 || diffLat lt 170)
    limit = self._limit

    if (~self._combineAll && nameIndex ge 1) then $
        names = STRARR(nEntity)

    for i=0,nEntity-1 do begin

        if (nEntity ge 10) then begin
            percent = 100*(i + 1d)/nEntity
            if (nEntity lt 100) and (percent gt 95) then $
                percent = 100
            status = self->ProgressBar('Reading ' + filename, $
                PERCENT=percent, $
                SHUTDOWN=(i ge (nEntity-1)))
            ; User hit cancel.
            if (~status) then begin
                if (~self._combineAll) then $
                    OBJ_DESTROY, oData
                break
            endif
        endif

        entity = oShape->GetEntity(i)

        if (useLimit) then begin
          xmin = entity.bounds[0]
          ymin = entity.bounds[1]
          xmax = entity.bounds[4]
          ymax = entity.bounds[5]
          if ((xmin lt limit[1] && xmax lt limit[1]) || $
            (xmin gt limit[3] && xmax gt limit[3]) || $
            (ymin lt limit[0] && ymax lt limit[0]) || $
            (ymin gt limit[2] && ymax gt limit[2])) then continue
        endif


        if (nAttr gt 0) then $
            attr = oShape->GetAttributes(i)

        isAntarctica = (filename eq 'country' || filename eq 'cntry02') && $
            nAttr ge 5 && attr.(4) eq 'Antarctica'

        ; Create empty parameter set with chosen name.
        if (~self._combineAll) then begin
            name = (nameIndex ge 1) ? $
                STRMID(STRTRIM(attr.(nameIndex - 1), 2),0,40) : $
                (filename + ' ' + STRTRIM(i,2))
            name = STRJOIN(STRSPLIT(name, '/', /EXTRACT), '_')
            if (nameIndex ge 1) then $
                names[i] = name
            oData[i] = OBJ_NEW('IDLitParameterSet', $
                NAME=name, $
                ICON='drawing', $
                TYPE=idlshapetype, $
                DESCRIPTION=strFilename)
        endif


        switch entityType of

        11: ; PointZ, fall thru
        1: begin  ; Points
            point = entity.bounds[0:ndim-1]
            if (self._combineAll) then begin
                index++
                vertices = (N_ELEMENTS(vertices) gt 0) ? $
                    [[TEMPORARY(vertices)], [point]] : point
            endif else begin
                oVert = OBJ_NEW('IDLitData', point, $
                    NAME='Vertices', TYPE=idlshapetype, ICON='segpoly')
                oData[i]->Add, oVert, PARAMETER_NAME='Vertices'
            endelse
           end

        3: ; Polyline, fall thru
        5: begin  ; Polygon
            if (entity.n_vertices lt minVert) then $
                break

            if (~self._combineAll && N_ELEMENTS(connectivity)) then $
                void = TEMPORARY(connectivity)

            if (self._combineAll) then begin
                ; The SHAPES parameter is a vector, each element of which
                ; is the starting index within the CONNECTIVITY of the
                ; next shape. This allows multiple shapes to be stored
                ; within a single parameter set, but still have the
                ; IDLitVisPolygon tessellate them separately.
                nconn = N_ELEMENTS(connectivity)
                shapes = (N_ELEMENTS(shapes) gt 0) ? $
                    [TEMPORARY(shapes), nconn] : nconn
            endif

            ; Number of polygons within the shape.
            if (entity.n_parts gt 1) then begin
                ; Construct a connectivity array.
                parts = [*entity.parts, entity.n_vertices]
                for part=0L, entity.n_parts - 1 do begin
                    pStart = parts[part]
                    nSubVert = parts[part + 1] - pStart
                    if (nSubVert lt minVert) then $
                        continue
                    if (isAntarctica) then begin
                        conn1 = self->_FixAntarctica(entity.vertices, $
                            pStart, nSubVert, index)
                    endif else begin
                        conn1 = [nSubVert, LINDGEN(nSubVert) + pStart + index]
                    endelse
                    connectivity = (N_ELEMENTS(connectivity) gt 0) ? $
                        [TEMPORARY(connectivity), conn1] : conn1
                endfor
            endif else begin
                ; If we are combining all polygons, then we need
                ; a connectivity array for each polygon.
                ; Otherwise, since we only had 1 part, we don't need
                ; a connectivity array.
                if (self._combineAll) then begin
                    conn1 = [entity.n_vertices, $
                        LINDGEN(entity.n_vertices) + index]
                    connectivity = (N_ELEMENTS(connectivity) gt 0) ? $
                        [TEMPORARY(connectivity), conn1] : conn1
                endif
            endelse

            if (self._combineAll) then begin
                index += entity.n_vertices
                vertices = (N_ELEMENTS(vertices) gt 0) ? $
                    [[TEMPORARY(vertices)], [*entity.vertices]] : $
                    *entity.vertices
            endif else begin
                oVert = OBJ_NEW('IDLitData', *entity.vertices, $
                    NAME='Vertices', TYPE=idlshapetype, ICON='segpoly')
                oData[i]->Add, oVert, PARAMETER_NAME='Vertices'
                if (N_ELEMENTS(connectivity) gt 0) then begin
                    oConn = OBJ_NEW('IDLitData', connectivity, $
                        NAME='Connectivity', TYPE='IDLCONNECTIVITY', $
                        ICON='segpoly')
                    oData[i]->Add, oConn, PARAMETER_NAME='Connectivity'
                endif
            endelse

            break
           end

        endswitch

        ; Add attributes if present.
        if (~self._combineAll && N_TAGS(attr) gt 0) then begin
            oAttr = OBJ_NEW('IDLitData', attr, $
                NAME='Attributes', TYPE='IDLSHAPEATTRIBUTES', $
                ICON='binary')
            oData[i]->Add, oAttr, PARAMETER_NAME='Attributes'
        endif

        oShape->DestroyEntity, entity

    endfor

    OBJ_DESTROY, oShape


    if (self._combineAll) then begin

        if (N_ELEMENTS(vertices) gt 0) then begin
            oData = OBJ_NEW('IDLitParameterSet', $
                NAME=filename, $
                ICON='drawing', $
                TYPE=idlshapetype, $
                DESCRIPTION=strFilename)
            oVert = OBJ_NEW('IDLitData', vertices, $
                NAME='Vertices', TYPE=idlshapetype, ICON='segpoly')
            oData->Add, oVert, PARAMETER_NAME='Vertices'
            if (N_ELEMENTS(connectivity) gt 0) then begin
                oConn = OBJ_NEW('IDLitData', connectivity, $
                    NAME='Connectivity', TYPE='IDLCONNECTIVITY', $
                    ICON='segpoly')
                oData->Add, oConn, PARAMETER_NAME='Connectivity'
            endif
            if (N_ELEMENTS(shapes) gt 0) then begin
                oShapeData = OBJ_NEW('IDLitData', shapes, $
                    NAME='Shapes', TYPE='IDLSHAPES', $
                    ICON='segpoly')
                oData->Add, oShapeData, PARAMETER_NAME='Shapes'
            endif
            return, 1
        endif
        return, 0

    endif else begin

        ; If using an attribute for name, sort the data objects.
        if (nameIndex ge 1) then begin
            oData = oData[SORT(names)]
        endif

    endelse

    ; Check all the separate data objects.
    good = WHERE(OBJ_VALID(oData), ngood)
    if (ngood gt 0) then begin
        oData = oData[good]
        return, 1
    endif

    return, 0

end


;---------------------------------------------------------------------------
; IDLitReadShapefile::Isa
;
; Purpose:
;   Method that will return true if the given file is a shapefile.
;
; Paramter:
;   strFilename  - The file to check
;
function IDLitReadShapefile::Isa, strFilename

    compile_opt idl2, hidden

    oShape = OBJ_NEW('IDLffShape')

    ; CT: Is this a sufficient test?
    ; What if the .dbf file is missing?
    success = oShape->Open(strFilename)

    ; Assume we have no attributes.
    enumlist = '<Shape index>'

    if (success) then begin
        oShape->GetProperty, N_ATTRIBUTES=nAttr, N_ENTITIES=nEntity
        if (nAttr gt 0) then begin
            oShape->GetProperty, ATTRIBUTE_NAMES=attrNames
            enumlist = [enumlist, attrNames]
            self->GetPropertyAttribute, 'ATTRIBUTE_NAME', $
                ENUMLIST=oldEnumlist
            ; If we are opening a shapefile with the same attributes as
            ; before, don't reset the name index.
            ; Only compare up to the length of the new list, since we
            ; might have tacked on a sample value below.
            if (N_ELEMENTS(enumlist) ne N_ELEMENTS(oldEnumlist) || $
                MIN(STRCMP(oldEnumlist, enumlist, $
                STRLEN(enumlist))) eq 0) then begin

                ; Best guess for name attribute.
                ; Add 1 for our default value of Shape index.
                self._attributeIndex = self->_GetNameAttribute(oShape) + 1
            endif
            if (nEntity ge 1) then begin
                ; Add a sample value to the end of each attribute.
                attr = oShape->GetAttributes(0)
                for i=0,nAttr-1 do begin
                    str = STRTRIM(attr.(i), 2)
                    if (~str) then $
                        continue
                    if (STRLEN(str) gt 19) then $
                        str = STRMID(str, 0, 16) + '...'
                    enumlist[i + 1] += ' (' + str + ')'
                endfor
            endif
        endif
    endif

    self->SetPropertyAttribute, 'ATTRIBUTE_NAME', $
        ENUMLIST=enumlist

    OBJ_DESTROY, oShape

    return, success

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadShapefile__Define
;
; Purpose:
; Class definition for the IDLitReadShapefile class
;
pro IDLitReadShapefile__Define

    compile_opt idl2, hidden

    void = {IDLitReadShapefile, $
        inherits IDLitReader, $
        _combineAll: 0b, $
        _attributeIndex: 0, $
        _limit: DBLARR(4) $
        }
end
