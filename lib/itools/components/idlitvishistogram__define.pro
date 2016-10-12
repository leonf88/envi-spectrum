; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitvishistogram__define.pro#1 $
;
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;
; PURPOSE:
;   The IDLitVisHistogram class is a subclass of IDLitVisPlot,
;   that includes a histogram parameter and some properties.
;
; MODIFICATION HISTORY:
;     Written by: CT, Mar 2003
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisHistogram::Init
;
; PURPOSE:
;    Initialize this component
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLitVisPlot
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;-
function IDLitVisHistogram::Init, $
    NAME=name, $
    DESCRIPTION=description, $
    HELP=help, $
    ICON=icon, $
    TOOL=tool, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    ; Start out with a nice default color and set HISTOGRAM to true.
    if (~self->IDLitVisPlot::Init(FILL_COLOR=[128,128,128], $
        NAME=name, $
        DESCRIPTION=description, $
        HELP=help, $
        ICON=icon, $
        TOOL=tool, $
        FILL_LEVEL=0, $
        /HISTOGRAM, $
        _EXTRA=_extra)) then $
        return, 0

    ; Create Parameters
    self->RegisterParameter, 'HISTOGRAM INPUT', $
        DESCRIPTION='Histogram input data', $
        /INPUT, TYPES=['IDLVECTOR', 'IDLARRAY2D', 'IDLARRAY3D']

    self->RegisterProperty, 'HIST_BINSIZE', /FLOAT, $
        DESCRIPTION='Histogram binsize', $
        NAME='Histogram binsize', $
        /HIDE, /ADVANCED_ONLY

    self->SetPropertyAttribute, ['HISTOGRAM', 'NSUM'], ADVANCED_ONLY=0
    self->SetPropertyAttribute, ['SYMBOL', 'SYM_SIZE', 'SYM_COLOR'], $
      /ADVANCED_ONLY
    
    ; Note that these parms are already registered by IDLitVisPlot.
    ; Fix them so they are not INPUT and are OUTPUT.
    self->SetParameterAttribute, ['X', 'Y', 'VERTICES', 'PALETTE'], $
        INPUT=0, OUTPUT=1


    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0)then $
        self->IDLitVisHistogram::SetProperty, _EXTRA=_extra

    return, 1 ; success
end


;----------------------------------------------------------------------------
; PURPOSE:
;    Cleanup this component
;
;pro IDLitVisHistogram::Cleanup
;    compile_opt idl2, hidden
    ; Cleanup superclass
;    self->IDLitVisPlot::Cleanup
;end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method retrieves the
;   value of a property or group of properties.
;
pro IDLitVisHistogram::GetProperty, $
    HIST_BINSIZE=histBinsize, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if ARG_PRESENT(histBinsize) then $
        histBinsize = self._histBinsize

    ; Get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPlot::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; PURPOSE:
;   This procedure method sets the value
;   of a property or group of properties.
;
pro IDLitVisHistogram::SetProperty, $
    HIST_BINSIZE=histBinsize, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(histBinsize) eq 1) && (histBinsize gt 0) then begin
        self._histBinsize = histBinsize
        oHistInput = self->GetParameter('HISTOGRAM INPUT')
        if (OBJ_VALID(oHistInput)) then begin
            if (oHistInput->GetData(data, NAN=nan)) then $
                self->_UpdateHistogram, data, NAN=nan
        endif
    endif

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPlot::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitVisHistogram::_UpdateHistogram, data, NAN=nan, RESET=reset

    compile_opt idl2, hidden

    type = SIZE(data, /TYPE)

    minn = MIN(data, MAX=maxx, NAN=nan)

    if (KEYWORD_SET(reset)) then begin
        ; For byte data always start with a binsize of 1.
        if (type eq 1) then begin
            self._histBinsize = 1
        endif else begin
            diff = maxx - minn
            if (diff ge 5 && diff le 20) then begin
                self._histBinsize = 1
            endif else begin
                self._histBinsize = 0.05d*(DOUBLE(maxx) - minn)
            endelse
        endelse
    endif

    binsize = self._histBinsize

    ; For byte or integer the min binsize is 1
    if (type ne 4 && type ne 5 && type ne 6 && type ne 9) then $
        binsize = binsize > 1

    if (binsize le 0) then $
        binsize = 1

    ; We must specify the MAX, since for byte data it assumes 255.
    result = HISTOGRAM(data, $
        BINSIZE=binsize, $
        LOCATIONS=locations, MAX=maxx, $
        NAN=nan)

    locations = FLOAT(locations)
    minn = MIN(result, MAX=maxx)


    ; Replace the existing Y data in the parameter set.
    ; We will manually call OnDataChangeUpdate after changing X and Y.
    oDataY = self->GetParameter('Y')
    if (~OBJ_VALID(oDataY)) then $
        return
    void = oDataY->SetData(result, /NO_NOTIFY, /NO_COPY)

    ; Replace the existing X data in the parameter set.
    oDataX = self->GetParameter('X')
    if (~OBJ_VALID(oDataX)) then $
        return
    void = oDataX->SetData(locations, /NO_NOTIFY, /NO_COPY)

    ; Update our superclass.
    self->IDLitVisPlot::OnDataChangeUpdate, $
        self->GetParameterSet(), '<PARAMETER SET>'

    self->SetPropertyAttribute, 'HIST_BINSIZE', HIDE=0

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrImage object.
;
; ARGUMENTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;
;    parmName: Name of the parameter that changed.
;
pro IDLitVisHistogram::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case strupcase(parmName) of

        '<PARAMETER SET>':begin
            ; Get our data
            oData = oSubject->GetByName('HISTOGRAM INPUT')
            if (OBJ_VALID(oData)) then begin
                ; Call ourself. Avoids duplicate code.
                self->IDLitVisHistogram::OnDataChangeUpdate, $
                    oData, 'HISTOGRAM INPUT'
            endif
            end

        'HISTOGRAM INPUT': begin
            if (oSubject->GetData(data, NAN=nan)) then $
                self->_UpdateHistogram, data, NAN=nan, /RESET
            return   ; no need to call our superclass
            end

        else:
    endcase

    ; If we reach here, we need to call our superclass.
    self->IDLitVisPlot::OnDataChangeUpdate, oSubject, parmName
end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
; PURPOSE:
;    Defines the object structure for an IDLitVisHistogram object.
;
pro IDLitVisHistogram__Define

    compile_opt idl2, hidden

    struct = { IDLitVisHistogram,           $
        inherits IDLitVisPlot, $   ; Superclass
        _histBinsize: 0d $
    }
end
