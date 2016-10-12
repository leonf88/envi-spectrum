; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopbytscl__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopBytscl
;
; PURPOSE:
;   Implements the Byte Scale operation.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;   IDLitDataOperation
;
; INTERFACES:
;   IIDLProperty
;-

;-------------------------------------------------------------------------
function IDLitopBytscl::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitDataOperation::Init(NAME="Byte Scale", $
        DESCRIPTION="Byte Scale", TYPES=['IDLARRAY2D'], NUMBER_DS='1')

    if (not success) then $
        return, 0

    ; Defaults.
    self._auto = 1b
    self._maximum = 255
    self._top = 255b

    ; Register properties
    self->RegisterProperty, 'Automatic', /BOOLEAN, $
        NAME='Automatic min/max', $
        Description='Automatically compute min and max values.'

    self->RegisterProperty, 'MINIMUM', /FLOAT, SENSITIVE=0, $
        NAME='Minimum cutoff', $
        Description='Minimum value of array to be considered.'

    self->RegisterProperty, 'MAXIMUM', /FLOAT, SENSITIVE=0, $
        NAME='Maximum cutoff', $
        Description='Maximum value of array to be considered.'

    self->RegisterProperty, 'BOTTOM', /INTEGER, $
        NAME='Bottom byte', $
        VALID_RANGE=[0,255], $
        Description='Minimum value of scaled result [0-255].'

    self->RegisterProperty, 'TOP', /INTEGER, $
        NAME='Top byte', $
        VALID_RANGE=[0,255], $
        Description='Maximum value of scaled result [0-255].'

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->IDLitopBytscl::SetProperty, _EXTRA=_extra

    return, 1

end


;-------------------------------------------------------------------------
pro IDLitopBytscl::GetProperty, $
    AUTOMATIC=auto, $
    BOTTOM=bottom, $
    MINIMUM=minimum, $
    MAXIMUM=maximum, $
    TOP=top, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; My properties.
    if ARG_PRESENT(auto) then $
        auto = self._auto

    if ARG_PRESENT(minimum) then $
        minimum = self._minimum

    if ARG_PRESENT(maximum) then $
        maximum = self._maximum

    if ARG_PRESENT(bottom) then $
        bottom = self._bottom

    if ARG_PRESENT(top) then $
        top = self._top

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
pro IDLitopBytscl::SetProperty, $
    AUTOMATIC=auto, $
    BOTTOM=bottom, $
    MINIMUM=minimum, $
    MAXIMUM=maximum, $
    TOP=top, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; My properties.
    if N_ELEMENTS(auto) then begin
        self._auto = KEYWORD_SET(auto)
        self->SetPropertyAttribute, 'Minimum', SENSITIVE=1-self._auto
        self->SetPropertyAttribute, 'Maximum', SENSITIVE=1-self._auto
        self->SetProperty, UVALUE=['Minimum', 'Maximum']
    endif

    if N_ELEMENTS(minimum) then $
        self._minimum = minimum

    if N_ELEMENTS(maximum) then $
        self._maximum = maximum

    if N_ELEMENTS(bottom) then $
        self._bottom = bottom

    if N_ELEMENTS(top) then $
        self._top = top

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopBytscl::DoExecuteUI
;
; Purpose:
;   Display byte scale propertysheet before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;    0 - Error, discontinue the operation
;
function IDLitopBytscl::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; For Auto mode, compute the data min/max before firing up
    ; the preview window, so that the preview looks correct.
    if (self._auto) then begin
        pData = self->_RetrieveDataPointers( $
            BYTESCALE_MIN=bytsclMin, BYTESCALE_MAX=bytsclMax)
        if (PTR_VALID(pData[0])) then begin
            self._minimum = MIN(bytsclMin)
            self._maximum = MAX(bytsclMax)
        endif
    endif

    ; Display dialog.
    return, oTool->DoUIService('OperationPreview', self)

end

;---------------------------------------------------------------------------
function IDLitopBytscl::Execute, data

    compile_opt idl2, hidden

    ; Convert from TOP & BOTTOM to actual BYTSCL top value.
    top = (self._top - self._bottom) > 0

    ; If we are within the preview UI, then the data may be just a subset.
    ; In this case we need to use our cached min/max, which were
    ; computed for the entire image (see DoExecuteUI above).
    if (self._auto && ~self._withinUI) then begin
        ; Let Bytscl compute the min/max.
        data = BYTSCL(TEMPORARY(data), TOP=top, NAN=self._nan)
    endif else begin
        data = BYTSCL(TEMPORARY(data), $
            MIN=self._minimum, MAX=self._maximum, $
            TOP=top, NAN=self._nan)
    endelse

    ; If necessary, add in the bottom.
    if (self._bottom ne 0) then $
        data = TEMPORARY(data) + self._bottom

    return,1
end


;-------------------------------------------------------------------------
; Override the superclass method, so we can force a bytescale update
; on image data.
;
function IDLitopBytscl::_ExecuteOnData, oData, $
    TARGET_VISUALIZATION=oTarget, $
    _REF_EXTRA=_extra

   compile_opt idl2, hidden

    ; If we are operating on an image, we want to disconnect the data
    ; to force a bytescale update to occur.
    reconnectData = OBJ_ISA(oTarget, 'IDLitVisImage') && $
        (oTarget->GetParameter('IMAGEPIXELS') eq oData)
    if (reconnectData) then begin
        oTarget->OnDataDisconnect, 'IMAGEPIXELS'
    endif

    success = self->IDLitDataOperation::_ExecuteOnData(oData, $
        TARGET_VISUALIZATION=oTarget, $
        _EXTRA=_extra)

    ; If we fail, we need to hook the (presumably) old data back up.
    ; Otherwise this should happen automatically.
    if (~success && reconnectData) then begin
        oTarget->OnDataChangeUpdate, oData, 'IMAGEPIXELS'
    endif

    return, success

end


;-------------------------------------------------------------------------
pro IDLitopBytscl__define

    compile_opt idl2, hidden

    struc = {IDLitopBytscl, $
        inherits IDLitDataOperation,    $
        _auto: 0b, $
        _minimum: 0d, $
        _maximum: 0d, $
        _top: 0b, $
        _bottom: 0b $
        }

end

