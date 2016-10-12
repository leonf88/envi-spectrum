; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/mapgrid.pro#1 $
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
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
function MAPGRID, projection, FILL_COLOR=fillColor, _REF_EXTRA=_extra
  compile_opt idl2, hidden
  ON_ERROR, 2

  !NULL = iGetCurrent(TOOL=oTool)
  if (~OBJ_VALID(oTool)) then begin
    if (ISA(projection)) then begin
      m = MAP(projection, FILL_COLOR=fillColor, _EXTRA=_extra)
      return, m.mapgrid
    endif else begin
      MESSAGE, 'A map projection must exist or be specified as a scalar string.'
    endelse
  endif

  oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

  oDesc = oTool->GetByIdentifier('OPERATIONS/INSERT/MAP/GRID')
  if (OBJ_VALID(oDesc)) then begin
    oGridOp = oDesc->GetObjectInstance()
    oGridCmd = oGridOp->DoAction(oTool)
    if (OBJ_VALID(oGridCmd[0])) then begin
      oGridCmd[-1]->GetProperty, TARGET=tID
      oGrid = oTool->GetByIdentifier(tID)
      oSetProp = oTool->GetService("SET_PROPERTY")
      oCmd = oSetProp->DoSetPropertyWith_Extra(tID, _EXTRA=_extra)
      if (OBJ_VALID(oCmd)) then $
        oGridCmd = [oGridCmd, oCmd]
      oTool->_TransactCommand, oGridCmd
    endif
  endif  

  ; Set this after we've set all our other properties.
  if (ISA(fillColor)) then begin
    oGrid->SetProperty, FILL_COLOR=fillColor
  endif

  if (~previouslyDisabled) then begin
    oTool->EnableUpdates
    oTool->RefreshCurrentWindow
  endif
  
  return, OBJ_NEW('MapGrid', oGrid)
  
end
