; $Id: //depot/idl/releases/IDL_80/idldir/lib/graphics/graphic_getgraphic.pro#2 $
;
; Copyright (c) 2010-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;+
; PURPOSE:
;    Wrap objects in the appropriate Graphics class
;
; MODIFICATION HISTORY:
;     Written by:   AGEH, 05/2010
;-
function Graphic_GetGraphic, oObj
  compile_opt idl2, hidden
  
  if (ISA(oObj, 'Graphic')) then return, oObj
  if (~OBJ_VALID(oObj)) then return, OBJ_NEW()
  
  case TYPENAME(oObj) of
    'IDLITVISTEXT': class = 'Text'
    'IDLITVISMAPPROJECTION': class = 'MapProjection'
    'IDLITVISSHAPEPOLYGON': class = 'MapContinents'
    'IDLITVISMAPGRID': class = 'MapGrid'
    'IDLITVISPLOT' : class = 'Plot'
    'IDLITVISPLOT3D' : class = 'Plot3D'
    'IDLITVISAXIS' : class = 'Axis'
    'IDLITVISCONTOUR' : class = 'Contour'
    'IDLITVISIMAGE' : class = 'Image'
    'IDLITVISSTREAMLINE' : class = 'Streamline'
    'IDLITVISSURFACE' : class = 'Surface'
    'IDLITVISVECTOR' : class = 'Vector'
    'IDLITVISVOLUME' : class = 'Volume'
    'IDLITVISCOLORBAR' : class = 'Colorbar'
    'IDLITVISPOLYLINE' : class = 'Polyline'
    'IDLBARPLOT': class = 'Barplot'
    'IDLITVISPOLYGON' : begin
      class = 'Polygon'
      oObj->GetProperty, IDENTIFIER=id
      if (STRPOS(id, 'OVAL') ne -1) then $
        class = 'Ellipse'
    end
    else : class = 'Graphic'
  endcase
  
  return, OBJ_NEW(class, oObj)
  
end
