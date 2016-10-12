; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitreadjpeg2000__define.pro#1 $
;
; Copyright (c) 2000-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitReadJPEG2000 class.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitReadJPEG2000 object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitReadJPEG2000::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init superclass
    if( self->IDLitReader::Init(["jp2", "jpx", "j2k"], $
        NAME="JPEG2000", $
        DESCRIPTION="JPEG2000 File Format (JPEG2000)", $
        ICON='demo', $
        _EXTRA=_extra) ne 1)then $
      return, 0

    self->RegisterProperty, 'DISCARD_LEVELS', $
        ENUMLIST=['None'], $
        NAME='Levels to discard', $
        Description='Number of resolution levels which will be discarded'

    self->RegisterProperty, 'QUALITY_LAYERS', $
        ENUMLIST=['All'], $
        NAME='Quality layers', $
        DESCRIPTION='Number of quality layers to include'

    return,1
end


;---------------------------------------------------------------------------
pro IDLitReadJPEG2000::GetProperty, $
    DISCARD_LEVELS=discardLevels, $
    QUALITY_LAYERS=qualityLayers, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(discardLevels)) then $
        discardLevels= self._discardLevels

    if (ARG_PRESENT(qualityLayers)) then $
        qualityLayers= self._qualityLayers

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitReader::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; IDLitReadJPEG2000::SetProperty
;
; Purpose:
;   Property method for the reader.
;
; Keywords:
;  IMAGE_INDEX   - The index of the image to retrieve
;
;  All other keywords are passed to the super class

pro IDLitReadJPEG2000::SetProperty, $
    DISCARD_LEVELS=discardLevels, $
    QUALITY_LAYERS=qualityLayers, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(discardLevels) gt 0) then $
        self._discardLevels = discardLevels

    if (N_ELEMENTS(qualityLayers) gt 0) then $
        self._qualityLayers = qualityLayers

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitReader::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
; See if we have a GeoJP2 file, with the special GeoTIFF UUID box.
; Returns a GeoTIFF structure, if one is present in the file, or a 0.
;
function IDLitReadJPEG2000::GetGeoTIFF, oJPEG2000

    compile_opt idl2, hidden

    oJPEG2000->GetProperty, FILENAME=filename, UUIDS=uuid

    geoTiffUUID = [177b,75b,248b,189b,8b,61b,75b,67b,165b,174b,140b,215b,$
          213b,166b,206b,3b]

    nUUID = N_ELEMENTS(uuid)/16
    ; Convert a single UUID into a 1x16 array, for simpler code below.
    if (nUUID eq 1) then uuid = REFORM(uuid, 1, 16)

    for i=0,nUUID-1 do begin

        ; Keep looping until we find a GeoTIFF UUID.
        if (~ARRAY_EQUAL(uuid[i,*], geoTiffUUID)) then $
            continue

        geoTIFFraw = oJPEG2000->GetUUID(uuid[i,*], LENGTH=length)
        if (~length) then $
            continue

        tmpDir = GETENV('IDL_TMPDIR')
        fileTmp = tmpDir + STRLOWCASE(FILE_BASENAME(filename)) + $
            '_geojp2tmp.tiff'

        ; Dump out the raw GeoTIFF bytes, then read them back in.
        OPENW, lun, fileTmp, /GET_LUN
        WRITEU, lun, geoTIFFraw
        FREE_LUN, lun
        success = QUERY_TIFF(fileTmp, GEOTIFF=geoTIFF)
        FILE_DELETE, fileTmp

        ; Only process the first GeoTIFF UUID
        return, success ? geoTIFF : 0

    endfor

    return, 0  ; failure

end


;---------------------------------------------------------------------------
; IDLitReadJPEG2000::GetData
;
; Purpose:
; Read the image file and return the data in the data object.
;
; Parameters:
;
; Returns 1 for success, 0 otherwise.
;
function IDLitReadJPEG2000::GetData, oImageData

    compile_opt idl2, hidden

    filename = self->GetFilename()

    if (~QUERY_JPEG2000(filename, info)) then $
        return, 0

    ; Convert from our quality layers property to max_layers keyword.
    maxLayers = self._qualityLayers + 1
    if (maxLayers ge info.n_layers) then $
        maxLayers = 0

    oJPEG2000 = OBJ_NEW('IDLffJPEG2000', filename, /QUIET)
    oJPEG2000->GetProperty, BIT_DEPTH=bitDepth, $
        N_COMPONENTS=nComponents, PALETTE=palette, UUIDS=uuid

    ; Try to retrieve GeoTIFF information.
    geoTIFF = self->GetGeoTIFF(oJPEG2000)


    ; Set RGB to true if we have 3 byte components, so that we
    ; automatically apply all color transforms.
    rgb = MAX(bitDepth) le 8 && nComponents eq 3

    image = oJPEG2000->GetData( $
        DISCARD_LEVELS=self._discardLevels, $
        MAX_LAYERS=maxLayers, $
        RGB=rgb)

    OBJ_DESTROY, oJPEG2000

    if (N_ELEMENTS(image) lt 1) then $
        return, 0

    if (SIZE(palette, /N_DIMENSIONS) eq 2 && $
        (SIZE(palette, /DIMENSIONS))[1] eq 3) then begin
        red = palette[*,0]
        green = palette[*,1]
        blue = palette[*,2]
    endif

    ; Store image data in Image Data object.
    oImageData = OBJ_NEW('IDLitDataIDLImage', $
                         NAME=FILE_BASENAME(fileName))

    if (~oImageData->SetData(image, 'ImagePixels', /NO_COPY)) then $
        return, 0

    ; Store palette data in Image Data object.
    if (N_ELEMENTS(red) gt 0) then begin
        result = oImageData->SetPalette( $
            TRANSPOSE([[red], [green], [blue]]))
    endif

    ; If we have GEOTIFF info, construct a data container
    ; and put our image and the geotiff info within it.
    if (N_TAGS(geotiff) gt 0) then begin
        oParamSet = OBJ_NEW('IDLitParameterSet', $
            NAME=FILE_BASENAME(fileName), $
            ICON='demo', $
            DESCRIPTION=fileName)
        oParamSet->Add, oImageData, PARAMETER_NAME='IMAGEPIXELS'
        oGeo = OBJ_NEW('IDLitDataIDLGeoTIFF', geotiff, $
            NAME='GeoTIFF Tags', TYPE='IDLGEOTIFF', $
            ICON='vw-list')
        oParamSet->Add, oGeo, PARAMETER_NAME='GEOTIFF'
        ; Return our parameter set.
        oImageData = oParamSet
    endif

    return, 1

end


;---------------------------------------------------------------------------
; IDLitReadJPEG2000::Isa
;
; Purpose:
;   Return true if the given file is a TIFF file
;
; Paramter:
;   strFilename  - The file to check

function IDLitReadJPEG2000::Isa, strFilename

    compile_opt idl2, hidden

    if (~QUERY_JPEG2000(strFilename, info)) then $
        return, 0

    self->GetPropertyAttribute, 'DISCARD_LEVELS', ENUMLIST=oldLevels
    self->GetPropertyAttribute, 'QUALITY_LAYERS', ENUMLIST=oldLayers

    ; Restrict the discard levels so we have at least a 2x2 array.
    twoD = 2^DINDGEN(info.n_levels + 1)
    dim = DOUBLE(info.dimensions)
    off = DOUBLE(info.offset)
    ; Weird JPEG2000 formula for the resulting dimensions.
    dim0 = CEIL((dim[0] + off[0])/twoD) - CEIL(off[0]/twoD)
    dim1 = CEIL((dim[1] + off[1])/twoD) - CEIL(off[1]/twoD)
    good = WHERE(dim0 ge 2 and dim1 ge 2, ngood)
    if (ngood eq 0) then $
        return, 0

    discardLevels = STRARR(ngood)
    for i=0,ngood-1 do begin
        discardLevels[i] = ((i eq 0) ? 'None' : STRTRIM(i, 2)) + ' [' + $
            STRTRIM(dim0[i], 2) + ',' + STRTRIM(dim1[i], 2) + ']'
    endfor

    self->SetPropertyAttribute, 'DISCARD_LEVELS', $
        NAME='Levels to discard [dimensions]', $
        ENUMLIST=discardLevels

    qualityLayers = 'All'
    if (info.n_layers gt 1) then $
        qualityLayers = [STRTRIM(INDGEN(info.n_layers - 1) + 1, 2), qualityLayers]
    self->SetPropertyAttribute, 'QUALITY_LAYERS', ENUMLIST=qualityLayers

    ; If the # of layers & levels is the same, then don't reset. That way
    ; the properties are maintained for sets of images.
    ; Otherwise assume it is a brand-new image, and reset the properties.
    if (N_ELEMENTS(oldLayers) ne N_ELEMENTS(qualityLayers) || $
        N_ELEMENTS(oldLevels) ne N_ELEMENTS(discardLevels)) then begin
        self._discardLevels = 0
        self._qualityLayers = (info.n_layers - 1) > 0
    endif

    return, 1
end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; IDLitReadJPEG2000__Define
;
; Purpose:
; Class definition for the IDLitReadJPEG2000 class
;
pro IDLitReadJPEG2000__Define

    compile_opt idl2, hidden

    void = {IDLitReadJPEG2000, $
          inherits IDLitReader, $
          _discardLevels : 0, $
          _qualityLayers : 0 $
         }
end
