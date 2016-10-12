;+
; :Description:
;    Create IDL Map graphic.
;
; :Params:
;    Projection
;
; :Keywords:
;    _REF_EXTRA
;
; :Returns:
;    Object Reference
;-
function MAP, projection, $
  FILL_COLOR=fillColor, TEST=test, _REF_EXTRA=ex

  compile_opt idl2, hidden
  ON_ERROR, 2
@map_proj_init_commonblock

  if (ISA(projection,'STRING') && N_ELEMENTS(projection) eq 1) then begin
    if (projection ne '') then begin
      ; Verify that this is a valid projection. Also pass in all map
      ; projection keywords to make sure they are valid for this projection.
      mapStruct = MAP_PROJ_INIT(projection, /GCTP, $
        _EXTRA=[c_keywordNames, 'ELLIPSOID', 'LIMIT', 'RADIANS'])
      projection = mapStruct.up_name
    endif
  endif else begin
    if ~KEYWORD_SET(test) then $
      MESSAGE, 'Projection must be specified as a scalar string.'
    projection = 'Mollweide'
    test = 0
    if (~ISA(fillColor)) then fillColor = "Lemon Chiffon"
  endelse

  name = 'Map'
  Graphic, name, MAP_PROJECTION=projection, $
    _EXTRA=ex, TEST=test, GRAPHIC=graphic, LAYOUT=[1,1,1], ASPECT_RATIO=1

  ; We usually get a MapGrid object back, since that is the selected item.
  ; So instead, find our VisMapProjection object and wrap it instead.
  if (~ISA(graphic, 'MapProjection')) then begin
    graphic = graphic.MapProjection
  endif

  if (ISA(fillColor)) then begin
    oGrid = graphic.mapgrid
    oGrid->SetProperty, FILL_COLOR=fillColor
  endif

  return, graphic
end
