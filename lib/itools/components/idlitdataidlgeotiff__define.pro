; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitdataidlgeotiff__define.pro#1 $
;
; Copyright (c) 2005-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitDataIDLGeoTIFF class.
;   This class is used to store IDL GeoTIFF structures.
;


;---------------------------------------------------------------------------
; Purpose:
; The constructor of the IDLitDataIDLGeoTIFF object.
;
; Parameters:
; Data - The (optional) data to store in the object.
;
; Properties:
;   Passed thru to the superclass.
;
function IDLitDataIDLGeoTIFF::Init, Data, _REF_EXTRA=_extra


    compile_opt idl2, hidden

    if (~self->IDLitData::Init(Data, NAME='GeoTIFF Tags', $
        TYPE='IDLGEOTIFF', $
        ICON='vw-list', _EXTRA=_extra)) then $
        return, 0

    self->RegisterProperty, 'GEOTIFF_TAGS', USERDEF='Click to view', $
        NAME='GeoTIFF tags'
        DESCRIPTION='GeoTIFF tags (Click "Edit" to view)'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataIDLGeoTIFF::SetProperty, _EXTRA=_EXTRA

    return, 1
end


;---------------------------------------------------------------------------
pro IDLitDataIDLGeoTIFF::GetProperty, $
    TEXT=text, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(text)) then begin
        text = ''
        oSys = _IDLitSys_GetSystem(/NO_CREATE)
        oSrvGeotiff = OBJ_VALID(oSys) ? $
            oSys->GetService('GEOTIFF') : OBJ_NEW()
        if (OBJ_VALID(oSrvGeotiff) && $
            self->GetData(geotiff) && N_TAGS(geotiff) gt 0) then begin
            text = oSrvGeotiff->DumpGeoTIFF(geotiff)
        endif

    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitData::GetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
;pro IDLitDataIDLGeoTIFF::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    if(n_elements(_extra) gt 0)then $
;        self->IDLitData::SetProperty, _EXTRA=_extra
;
;end


;----------------------------------------------------------------------------
; Purpose:
;   This function method is used to edit a user-defined property.
;
; Arguments:
;   Tool: Object reference to the tool.
;
;   PropertyIdentifier: String giving the name of the userdef property.
;
; Keywords:
;   None.
;
function IDLitDataIDLGeoTIFF::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'GEOTIFF_TAGS': begin
        void = oTool->DoUIService('TextDisplay', self)
        return, 0
        end

    else:

    endcase

    ; Call our superclass.
    return, self->IDLitDataIDLGeoTIFF::EditUserDefProperty(oTool, identifier)

end


;---------------------------------------------------------------------------
pro IDLitDataIDLGeoTIFF__Define

  compile_opt idl2, hidden

  void = {IDLitDataIDLGeoTIFF, $
    inherits   IDLitData }

end
