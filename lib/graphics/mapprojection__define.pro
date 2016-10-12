; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/mapprojection__define.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create a Map.
;
; :Params:
;    Projection
;
; :Keywords:
;    
;
; :Author: ITTVIS, March 2010
;-

;-------------------------------------------------------------------------
pro MapProjection::SetProperty, FILL_COLOR=fillColor, _EXTRA=ex

  if ISA(fillColor) then begin
    oGrid = self['map grid']
    if ~ISA(oGrid) then MESSAGE, 'Unable to retrieve the map grid.'
    oGrid.fill_color = fillColor
  endif

  if (ISA(ex)) then self->Graphic::SetProperty, _EXTRA=ex
end


;---------------------------------------------------------------------------
function MapProjection::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['MAP_PROJECTION', 'IELLIPSOID', $
    'SEMIMAJOR_AXIS', 'SEMIMINOR_AXIS', 'CENTER_LONGITUDE', 'CENTER_LATITUDE', $
    'LONGITUDE_MIN', 'LONGITUDE_MAX', 'LATITUDE_MIN', 'LATITUDE_MAX', $
    'FALSE_EASTING', 'FALSE_NORTHING', 'UTM_ZONE', 'STATEPLANE_ZONE27', $
    'STATEPLANE_ZONE83', 'HEMISPHERE', 'STANDARD_PAR1', 'STANDARD_PAR2', $
    'MERCATOR_SCALE', 'HEIGHT', 'HOM_AZIM_ANGLE', $
    'HOM_LONGITUDE1', 'HOM_LATITUDE1', 'HOM_LONGITUDE2', 'HOM_LATITUDE2', $
    'SOM_LANDSAT_NUMBER', 'SOM_LANDSAT_PATH', 'SOM_INCLINATION', $
    'SOM_LONGITUDE', 'SOM_PERIOD', 'SOM_RATIO', 'SOM_FLAG', $
    'OEA_SHAPEM', 'OEA_SHAPEN', 'OEA_ANGLE', 'IS_ZONES', 'IS_JUSTIFY']

  return, [myprops, self->Graphic::QueryProperty()]
end


;-------------------------------------------------------------------------
pro MapProjection__define
  compile_opt idl2, hidden
  void = {MapProjection, inherits Graphic}
end

