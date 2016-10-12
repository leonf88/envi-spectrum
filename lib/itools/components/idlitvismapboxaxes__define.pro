; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvismapboxaxes__define.pro#1 $
;
; Copyright (c) 2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; CLASS_NAME:
;    IDLitvisMapBoxAxes
;
; PURPOSE:
;    The IDLitvisMapBoxAxes class implements
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-
function IDLitvisMapBoxAxes::Init, oObj, _REF_EXTRA=_extra
  
  compile_opt idl2, hidden
  on_error, 2

  ; Init our superclass
  if (~self->IDLitVisualization::Init(TYPE="IDLBOXGRID", $
      ;ICON='fitwindow', $
      DESCRIPTION="A Box Grid Visualization", $
      NAME="BoxGrid", IMPACTS_RANGE=0, _EXTRA=_extra)) then $
      RETURN, 0
  
  if ISA(oObj, 'IDLitvisMapGrid') then self._oMapGrid = oObj
  
  ; Default thickness of the box grid
  self._GridBoxThickness = 4
  self._boxColorSet = 0
  
  self._oBorderMain  = OBJ_NEW('IDLgrPolyline', THICK=self._GridBoxThickness, $
    COLOR=[0,0,0], /HIDE)
  self.Add, self._oBorderMain
  
  ; Create an IDLgrPolyline object for the white boxes
  self._oWhiteBoxes = OBJ_NEW( 'IDLgrPolyline', THICK=self._GridBoxThickness - 2, $
    COLOR=[255,255,255], /HIDE )
  self.Add, self._oWhiteBoxes
  
  ; Set any properties
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitvisMapBoxAxes::SetProperty, _EXTRA=_extra
  
  return, 1

end

;----------------------------------------------------------------------------
pro IDLitvisMapBoxAxes::Cleanup
    compile_opt idl2, hidden
    
    ; Cleanup
    self._oBorderMain->Cleanup
    self._oWhiteBoxes->Cleanup
    
    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
pro IDLitvisMapBoxAxes::SetProperty, $
    COLOR=gridColor, $
    BOX_COLOR=boxColor, $
    BOX_THICK=boxThick, $
    BOX_ANTIALIAS=boxAntialias, $
    _REF_EXTRA=_extra

  ; Keep the box axes color in synch with the grid line color
  ; until the box_color is specifically set
  if (N_ELEMENTS(gridColor) gt 0 && $
      N_ELEMENTS(boxColor) eq 0 && $
      self._boxColorSet eq 0) then begin
    if (ISA(gridColor, 'STRING') || N_ELEMENTS(gridColor) eq 1) then $
      style_convert, gridColor[0], COLOR=gridColor
    if ISA(self._oBorderMain) then $
      self._oBorderMain.SetProperty, COLOR=gridColor
  endif

  if (N_ELEMENTS(boxColor) gt 0) then begin        
    if (ISA(boxColor, 'STRING') || N_ELEMENTS(boxColor) eq 1) then $
      style_convert, boxColor[0], COLOR=boxColor    
    if ISA(self._oBorderMain) then begin
      self._boxColorSet = 1
      self._oBorderMain.SetProperty, COLOR=boxColor
    endif
  endif

  if (N_ELEMENTS(boxAntialias) gt 0) then begin
      self._oBorderMain.SetProperty, ANTIALIAS=boxAntialias
      self._oWhiteBoxes.SetProperty, ANTIALIAS=boxAntialias
  endif

  if (N_ELEMENTS(boxThick) gt 0) then begin
    newThick = self._GridBoxThickness
    case (boxThick) of
    1: begin
      newThick = 4
    end
    2: begin
      newThick = 6
    end
    3: begin
      newThick = 8
    end
    4: begin
      newThick = 10
    end
    else: begin
      ; Clip the values to the range of values 1, 2, or 3
      if ( boxThick lt 1 ) then newThick = 4
      if ( boxThick gt 4 ) then newThick = 10
    end
    endcase
    if ( newThick ne self._GridBoxThickness ) then begin
      self._GridBoxThickness = newThick
      self._oBorderMain.SetProperty, THICK=newThick
      self._oWhiteBoxes.SetProperty, THICK=newThick - 2
    endif  
  endif

  ; Set any properties
  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitVisualization::SetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
pro IDLitvisMapBoxAxes::GetProperty, $
    BOX_COLOR=boxColor, $
    BOX_THICK=boxWidth, $
    BOX_ANTIALIAS=boxAntialias, $
    _REF_EXTRA=_extra

  if ARG_PRESENT(boxColor) then $
    self._oBorderMain.GetProperty, COLOR=boxColor

  if ARG_PRESENT(boxWidth) then begin
    case (self._GridBoxThickness) of
    4: begin
      boxWidth = 1
    end
    6: begin
      boxWidth = 2
    end
    8: begin
      boxWidth = 3
    end
    10: begin
      boxWidth = 4
    end
    endcase
  endif

  ; The two lines should always have the same antialias setting
  if ARG_PRESENT(boxAntialias) then $
    self._oBorderMain.GetProperty, ANTIALIAS=boxAntialias

  if (N_ELEMENTS(_extra) gt 0) then $
    self->IDLitVisualization::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
; Calculate the positions of the box axes relative to the visualization
;
pro IDLitvisMapBoxAxes::_UpdateBoxGrid

  ; If there is no data space, then return with no action taken
  oDataspace = self->GetDataspace( )
  if ~ISA(oDataSpace) then return

  if ~ISA(self._oMapGrid, 'IDLitvisMapGrid') then return

  ; Get the property values we need from the map grid
  self._oMapGrid.GetProperty, LONGITUDE_MIN=gridLonMin, LONGITUDE_MAX = gridLonMax, $
      LATITUDE_MIN=gridLatMin, LATITUDE_MAX=gridLatMax, $
      GRID_LATITUDE=gridLatitude, GRID_LONGITUDE=gridLongitude
  sMap = self._oMapGrid.GetProjection( )
  
  ; Get the limits from the sMap structure because the
  ; grid stores the limits as adjusted values
  latMin = sMap.LL_BOX[0]
  lonMin = sMap.LL_BOX[1]
  latMax = sMap.LL_BOX[2]
  lonMax = sMap.LL_BOX[3]
  
  ; Bring in the lon and lat endpoints just enough to
  ; prevent situations where the left and right side of
  ; the box axes are projected to the same location
  lonMin += ABS( lonMax - lonMin ) * DOUBLE( 1e-9 )
  lonMax -= ABS( lonMax - lonMin ) * DOUBLE( 1e-9 )

  ; Get the locations of the longitude lines
  ; note that some of the stored lines may be hidden
  lonLineLocs = []
  oMapGridContainer = self._oMapGrid.Get( POSITION=0 )
  oLines = oMapGridContainer.Get( /ALL )
  for i = 0, N_ELEMENTS( oLines ) - 1 do begin
    oLines[i].GetProperty, LOCATION=location, HIDE=hidden
    if ~hidden then lonLineLocs = [lonLineLocs, location]
  endfor
  
  ; Get the locations of the latitude lines
  ; note that some of the stored lines may be hidden
  latLineLocs = []
  oMapGridContainer = self._oMapGrid.Get( POSITION=1 )
  oLines = oMapGridContainer.Get( /ALL )
  for i = 0, N_ELEMENTS( oLines ) - 1 do begin
    oLines[i].GetProperty, LOCATION=location, HIDE=hidden
    if ~hidden then latLineLocs = [latLineLocs, location]
  endfor
  
  if ISA(lonLineLocs) && ISA(latLineLocs) then begin
    ; Make sure that the max and min are included list of longitudes
    lMin = MIN( lonLineLocs, MAX=lMax )
    if (lMin ne lonMin) then lonLineLocs = [lonMin, lonLineLocs]
    if (lMax ne lonMax) then lonLineLocs = [lonLineLocs,lonMax]
    ; Make sure that the max and min are included in the list of latitudes
    lMin = MIN( latLineLocs, MAX=lMax )
    if (lMin ne latMin) then latLineLocs = [latMin, latLineLocs]
    if (lMax ne latMax) then latLineLocs = [latLineLocs,latMax]
  endif else begin ; Either no lat or lon lines
    self.SetProperty, /HIDE ; map is invalid so hide the box axes
    RETURN 
  endelse
  
  ; Create the border line
  ptsPerLine = 500d ; number of points per line to use for interpolation
  bottomData = [[lonMin, (dindgen(ptsPerLine - 2) + 1.0) * (ABS( lonMax - lonMin )/ptsPerLine) + lonMin , lonMax], [dblarr(ptsPerLine) + latMin]]
  rightData = [[dblarr(ptsPerLine) + lonMax], [latMin, (dindgen(ptsPerLine - 2) + 1.0) * (ABS( latMax - latMin )/ptsPerLine) + latMin , latMax]]
  topData = [[lonMin, (dindgen(ptsPerLine - 2) + 1.0) * (ABS( lonMax - lonMin )/ptsPerLine) + lonMin , lonMax], [dblarr(ptsPerLine) + latMax]] 
  leftData = [[dblarr(ptsPerLine) + lonMin], [latMin, (dindgen(ptsPerLine - 2) + 1.0) * (ABS( latMax - latMin )/ptsPerLine) + latMin , latMax]]
  
  boxData = TRANSPOSE([bottomData,rightData,topData,leftData])
  boxData = MAP_PROJ_FORWARD( boxData, MAP_STRUCTURE=sMap )
  
  ; If we have any non-finite values, then do not show the axes
  if (MIN(FINITE(boxData)) eq 0) then begin
    self.SetProperty, /HIDE
    RETURN
  endif
  
  if ISA(self._oBorderMain) then begin
    self._oBorderMain.SetProperty, DATA=boxData, HIDE=0, $
      POLYLINES=[ptsPerLine,dindgen(ptsPerLine), ptsPerLine, dindgen(ptsPerLine) + ptsPerLine, $
                 ptsPerLine, dindgen(ptsPerLine) + 2 * ptsPerLine, ptsPerLine, dindgen(ptsPerLine) + 3 * ptsPerLine]
  endif

  ; Now calculate the connectivity array into the boxData for drawing the white boxes
  if ISA( self._oWhiteBoxes ) then begin
    WhiteBoxes = []
    nIndices = 0

    ; Calculate the white box axes for the longitude
    sortIndices = SORT( lonLineLocs )
    for i=0, N_ELEMENTS( sortIndices ) - 2, 2 do begin
      indices = WHERE( bottomData[*,0] ge lonLineLocs[sortIndices[i]] and bottomData[*,0] LE lonLineLocs[sortIndices[i + 1]], nIndices )
      WhiteBoxes = [WhiteBoxes, nIndices, indices, nIndices, indices + 2 * ptsPerLine]
    endfor
    
    ; Calculate the white box axes for the latitude
    sortIndices = SORT( latLineLocs )
    for i=1, N_ELEMENTS( sortIndices ) - 2, 2 do begin
      indices = WHERE( rightData[*,1] ge latLineLocs[sortIndices[i]] and rightData[*,1] LE latLineLocs[sortIndices[i + 1]], nIndices )
      WhiteBoxes = [WhiteBoxes, nIndices, indices + ptsPerLine, nIndices, indices + 3 * ptsPerLine]
    endfor

    ; Set the data and connectivity for the white part of the box axes
    self._oWhiteBoxes.SetProperty, DATA=boxData, HIDE=0, POLYLINES=WhiteBoxes
  endif

end

;----------------------------------------------------------------------------
;+
; IDLitvisMapBoxAxes__define
;
; PURPOSE:
;    Defines the object structure for an IDLitvisMapBoxAxes object.
;
;-
pro IDLitvisMapBoxAxes__define
  compile_opt idl2, hidden
  void = {IDLitvisMapBoxAxes, $
          inherits IDLitVisualization, $
          _oBorderMain:OBJ_NEW( ), $
          _oWhiteBoxes:OBJ_NEW( ), $
          _oMapGrid:OBJ_NEW( ), $
          _boxColorSet:0B, $
          _GridBoxThickness:0B}
end