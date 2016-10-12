; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/mapcontinents__define.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; :Description:
;    Create a MapContinents graphic.
;
; :Params:
;    X
;    Y
;    Z
;    Style
;
; :Keywords:
;    DATA
;    VISUALIZATION
;    All other keywords are passed through to the MapContinents.
;
; :Author: ITTVIS, March 2010
;-
;-------------------------------------------------------------------------
function MapContinents::Init, shapeFile, $
  CANADA=canada, $
  COMBINE=combineIn, $
  CONTINENTS=continents, $
  COUNTRIES=countries, $
  COUNTRY=country, $   ; same as /COUNTRIES
  FILL_COLOR=fillColor, $
  LAKES=lakes, $
  LIMIT=limit, $
  NOCLIP=noClip, $
  RIVERS=rivers, $
  USA=usa, $
  _REF_EXTRA=ex

  compile_opt idl2, hidden

@graphic_error

  ; If we are just wrapping an existing visualization, just do it
  ; and return.
  if (ISA(shapeFile, '_IDLitVisualization')) then begin
    ; Call our superclass to cache the objref.
    !null = self->Graphic::Init(shapeFile)
    return, 1
  endif

  if (ISA(shapefile)) then begin
    if (~ISA(shapeFile, 'STRING') || ~FILE_TEST(shapefile)) then $
      MESSAGE, 'Input must be a valid shapefile.'
    ; Default is COMBINE=1
    combine = ISA(combineIn) ? combineIn : 1
  endif else begin
    ; Default is COMBINE=0 (except for CONTINENTS)
    combine = ISA(combineIn) ? combineIn : 0
    case (1) of
    KEYWORD_SET(country): data = ['Country', 'cntry02']
    KEYWORD_SET(countries): data = ['Country', 'cntry02']
    KEYWORD_SET(canada): data = ['Canada', 'canadaprovince']
    KEYWORD_SET(usa): data = ['USA', 'states']
    KEYWORD_SET(lakes): data = ['Lakes', 'lakes']
    KEYWORD_SET(rivers): data = ['Rivers', 'rivers']
  ;  'CITIES': data = ['Cities', 'cities']
    ; /CONTINENTS will just end up here as well
    else: begin
        data = ['Continents', 'continents']
        combine = ISA(combineIn) ? combineIn : 1
      end
    endcase
  
    name = data[0]
    shapeFile = FILEPATH(data[1] + '.shp', $
      SUBDIR = ['resource', 'maps', 'shape'])
  endelse


  ;; Set up parameters
  if (KEYWORD_SET(ID) || KEYWORD_SET(toolIDin)) then begin
    fullID = (iGetID(ID, TOOL = toolIDin))[0]
  endif
  if (N_ELEMENTS(fullID) eq 0) then $
    fullID = iGetCurrent()

  ; Error checking
  if (fullID[0] eq '') then $
    message, 'Graphics window does not exist.'

  ; Get the system object
  oSystem = _IDLitSys_GetSystem(/NO_CREATE)
  if (~OBJ_VALID(oSystem)) then return, obj_new()

  ; Get the object from ID
  oObj = oSystem->GetByIdentifier(fullID)
  if (~OBJ_VALID(oObj)) then return, obj_new()
  
  ; Get the tool
  oTool = oObj->GetTool()
  if (~OBJ_VALID(oTool)) then return, obj_new()
  
  oDesc = oTool->GetByIdentifier('Operations/Insert/Map/Continents')
  if (~OBJ_VALID(oDesc)) then return, obj_new()
  oOp = oDesc->GetObjectInstance()
  if (~OBJ_VALID(oOp)) then return, obj_new()

  if (ISA(limit) && N_ELEMENTS(limit) ne 4) then $
    MESSAGE, 'LIMIT must have 4 elements [Latmin, Lonmin, Latmax, Lonmax].'

  ; Set the operation properties.
  oOp->SetProperty, NAME=name, COMBINE_ALL=combine, SHAPEFILE=shapeFile

    ; Turn on FILL_BACKGROUND if FILL_COLOR is not a scalar 0
  filled = ISA(fillColor) && (ISA(fillColor,"STRING") || $
    N_ELEMENTS(fillColor) gt 1 || fillColor ne 0)

  oCmd = oOp->DoAction(oTool, LIMIT=limit, NOCLIP=noClip, $
    FILL_BACKGROUND=filled, FILL_COLOR=fillColor, $
    _EXTRA = ex, ID_VISUALIZATION = idVis)

  OBJ_DESTROY, oCmd
  
  if (ISA(idVis, 'STRING')) then begin
    obj = oTool->GetByIdentifier(idVis[0])
    if (N_ELEMENTS(idVis) gt 1) then $
      obj[0].GetProperty, PARENT = obj
    ; Call our superclass to cache the objref.
    !null = self->Graphic::Init(obj)
  endif

  return, 1
end


;-------------------------------------------------------------------------
pro MapContinents::SetProperty, FILL_COLOR=fillColor, _EXTRA=ex

  if ISA(fillColor) then begin
    ; Turn on FILL_BACKGROUND if FILL_COLOR is not a scalar 0
    filled = ISA(fillColor,"STRING") || $
      N_ELEMENTS(fillColor) gt 1 || fillColor ne 0
    self->Graphic::SetProperty, FILL_COLOR=fillColor, FILL_BACKGROUND=filled
  endif

  if (ISA(ex)) then self->Graphic::SetProperty, _EXTRA=ex
end


;---------------------------------------------------------------------------
function MapContinents::QueryProperty, propNames
  compile_opt idl2, hidden

  myprops = ['ANTIALIAS','COLOR', $
    'FILL_BACKGROUND', 'FILL_COLOR', $
    'HIDE','LINESTYLE','NAME','THICK', $
    'TRANSPARENCY']
  ; Do not return Graphic's properties, since Text is just an annotation.
  return, myprops
end


;-------------------------------------------------------------------------
pro MapContinents__define

  compile_opt idl2, hidden
  void = {MapContinents, inherits Graphic}

end