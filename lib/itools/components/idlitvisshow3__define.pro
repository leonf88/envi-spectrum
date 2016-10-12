; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvisshow3__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
;----------------------------------------------------------------------------
function IDLitVisShow3::Init, z, _REF_EXTRA=_extra

   compile_opt idl2, hidden

   ; Initialize superclass
    if (self->IDLitVisImage::Init(NAME='IDLitVisShow3', $
        ICON='surface', DESCRIPTION='Show3', _EXTRA=_extra) ne 1) then $
        RETURN, 0

    self->Set3D, /ALWAYS  ; This is a 3D visualization

    ; Register the parameters we are using for data
    self->RegisterParameter, 'IMAGE', DESCRIPTION='Z Data', $
        /INPUT, TYPES='IMAGE', /OPTARGET

    ; Create object and add it to this Visualization
    self._oContour = OBJ_NEW('IDLitVisContour')
    self->Add, self._oContour, /AGGREGATE

    ; Create object and add it to this Visualization
    self._oSurface = OBJ_NEW('IDLitVisSurface')
    self->Add, self._oSurface, /AGGREGATE

    ; Override the PropertyDescriptor attributes.
    self->SetPropertyAttribute, /HIDE, $
        ['BLEND_IMAGE', 'BLEND_BACKGROUND']

    ; Register my own properties.
    self->RegisterProperty, 'SCALE_FACTOR', /FLOAT, $
        NAME='Scale factor', $
        DESCRIPTION='Scale factor between image and height.'

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisShow3::SetProperty, _EXTRA=_extra

    RETURN, 1                    ; Success
end

;----------------------------------------------------------------------------
; Don't need Cleanup, GetProperty method because it is all handled by superclass.
;pro IDLitVisShow3::Cleanup
;end


;----------------------------------------------------------------------------
pro IDLitVisShow3::GetProperty, $
    SCALE_FACTOR=scaleFactor, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(scaleFactor) then $
        scaleFactor = self._scaleFactor

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisImage::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisShow3::SetProperty, $
    SCALE_FACTOR=scaleFactor, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(scaleFactor) gt 0) then begin
        self._scaleFactor = scaleFactor
        success = self->GetParameterDataByType('IMAGE', oData)
        if (success gt 0) then begin
            success = oData[0]->GetData(zdata)
            zdata = zdata*self._scaleFactor
            self._oSurface->SetProperty, DATAZ=zdata
            self._oContour->SetProperty, DATA=zdata, ZVALUE=MAX(zdata)
        endif
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisImage::SetProperty, _EXTRA=_extra
end


;----------------------------------------------------------------------------
; This procedure method is called by a Subject via a Notifier when
; its data has changed.  This method obtains the data from the subject
; and updates the objects.
;
pro IDLitVisShow3::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmname) of
        'IMAGE':  $
            begin
                success = oSubject->GetData(zdata)
                ; Scale the data into the same range as the dimensions.
                dims = SIZE(zdata, /DIMENSIONS)
                self._scaleFactor = DOUBLE(MAX(dims))/MAX(zdata)
                zdata = zdata*self._scaleFactor
                self._oSurface->SetProperty, DATAZ=zdata
                self._oContour->SetProperty, DATA=zdata, $
                    /PLANAR, ZVALUE=MAX(zdata)
            break
            end
        else: ; ignore unknown parameters
    endcase

    ; Pass on to superclass.
    self->IDLitVisImage::OnDataChangeUpdate, oSubject, parmName

end


;----------------------------------------------------------------------------
pro IDLitVisShow3__Define

    compile_opt idl2, hidden

    struct = { IDLitVisShow3, $
        inherits IDLitVisImage, $
        _oSurface: OBJ_NEW(), $
        _oContour: OBJ_NEW(), $
        _scaleFactor: 0d $

    }
end
