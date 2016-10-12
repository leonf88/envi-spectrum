; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopresample__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopResample
;
; PURPOSE:
;   Implements the Resampling operation.
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
function IDLitopResample::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitDataOperation::Init(NAME="Resample", $
        DESCRIPTION="Resample the data by given factors", $
        TYPES=['IDLVECTOR','IDLARRAY2D','IDLARRAY3D'], $
        NUMBER_DS='1', $
        _EXTRA=_extra)

    if (not success) then $
        return, 0

    ; Defaults.
    self._xfactor = 0.5d
    self._yfactor = 0.5d
    self._zfactor = 0.5d

    ; Register properties
    self->RegisterProperty, 'X_RESAMPLE_FACTOR', /FLOAT, $
        NAME='1st dimension factor', $
        Description='Resampling factor for the first (X) dimension'

    self->RegisterProperty, 'Y_RESAMPLE_FACTOR', /FLOAT, $
        NAME='2nd dimension factor', $
        Description='Resampling factor for the first (Y) dimension'

    self->RegisterProperty, 'Z_RESAMPLE_FACTOR', /FLOAT, $
        NAME='3rd dimension factor', $
        Description='Resampling factor for the first (Z) dimension'

    self->RegisterProperty, 'RESAMPLE_METHOD', $
        ENUMLIST=['Nearest neighbor', 'Linear', 'Cubic'], $
        NAME='Interpolation method', $
        Description='Interpolation method'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopResample::SetProperty, _EXTRA=_extra

    return, 1

end


;-------------------------------------------------------------------------
pro IDLitopResample::GetProperty, $
    X_RESAMPLE_FACTOR=xfactor, $
    Y_RESAMPLE_FACTOR=yfactor, $
    Z_RESAMPLE_FACTOR=zfactor, $
    RESAMPLE_METHOD=method, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; My properties.
    if ARG_PRESENT(xfactor) then $
        xfactor = self._xfactor

    if ARG_PRESENT(yfactor) then $
        yfactor = self._yfactor

    if ARG_PRESENT(zfactor) then $
        zfactor = self._zfactor

    if ARG_PRESENT(method) then $
        method = self._method

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
pro IDLitopResample::SetProperty, $
    X_RESAMPLE_FACTOR=xfactor, $
    Y_RESAMPLE_FACTOR=yfactor, $
    Z_RESAMPLE_FACTOR=zfactor, $
    RESAMPLE_METHOD=method, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; My properties.
    if N_ELEMENTS(xfactor) && (xfactor gt 0) then $
        self._xfactor = xfactor

    if N_ELEMENTS(yfactor) && (yfactor gt 0) then $
        self._yfactor = yfactor

    if N_ELEMENTS(zfactor) && (zfactor gt 0) then $
        self._zfactor = zfactor

    if N_ELEMENTS(method) then $
        self._method = method

    ; Superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopResample::Execute, data

    compile_opt idl2, hidden

    dims = SIZE(data, /DIMENSIONS)

    case N_ELEMENTS(dims) of
        1: newdims = dims*ABS([self._xfactor]) > [2]
        2: newdims = dims*ABS([self._xfactor, self._yfactor]) > [2, 2]
        3: newdims = dims*ABS([self._xfactor, $
            self._yfactor, self._zfactor]) > [2, 2, 2]
        else: return, 0
    endcase

    ; No change in size.
    if (ARRAY_EQUAL(newdims, dims)) then $
        return, 1

    interp = 0
    cubic = 0
    case (self._method) of
        0: ;; do nothing
        1: interp = 1
        2: cubic = 1
    endcase

    case N_ELEMENTS(dims) of
        1: data = CONGRID(data, newdims[0], $
            INTERP=interp, CUBIC=cubic)
        2: data = CONGRID(data, newdims[0], newdims[1], $
            INTERP=interp, CUBIC=cubic)
           ;; CONGRID always uses linear interp with 3D
        3: data = CONGRID(data, newdims[0], newdims[1], newdims[2])
    endcase

    return,1
end

;---------------------------------------------------------------------------
; IDLitopResample::DoDataOperation
;
; Purpose:
;  Override the superclass method so we can check for data that falls
;  within IDLitDataIDLImagePixels containers so that all channels are
;  operated upon.
;
function IDLitopResample::DoDataOperation, oTool, oCommandSet, oSelVis

    compile_opt idl2, hidden

    iStatus = self->IDLitDataOperation::DoDataOperation(oTool, $
        oCommandSet, oSelVis)

    if (iStatus ne 0) then begin
        ; For each target data item in the command set, check if
        ; it falls within an IDLitDataIDLImagePixels container.
        ; If so, make sure all channels within that container were
        ; also operated upon.

        ; Retrieve target identifiers from collected commands.
        nCmds = oCommandSet->Count()
        if (nCmds eq 0) then $
            return, iStatus
        targetIds = STRARR(nCmds)
        for i=0,nCmds-1 do begin
            oCmd = oCommandSet->Get(POSITION=j)
            oCmd->GetProperty, TARGET_IDENTIFIER=targetID
            targetIds[i] = targetID
        endfor

        ; Check each targeted data item... 
        for i=0,nCmds-1 do begin
            oDataItem = oTool->GetByIdentifier(targetIds[i])

            ; ...Identify 2D arrays...
            if (OBJ_ISA(oDataItem,'IDLitDataIDLArray2D')) then begin
                oDataItem->GetProperty, _PARENT=oParent
                ; ...that are channels within an Image Pixels object.
                if ((N_ELEMENTS(oParent) gt 0) && $
                    (OBJ_ISA(oParent, 'IDLitDataIDLImagePixels'))) then begin

                    ; Ensure all other planes of the same image 
                    ; are in the list.  If not, operate on them now.
                    oPlanes = oParent->Get(/ALL, COUNT=nPlanes)
                    if (nPlanes gt 1) then begin
                        for j=0,nPlanes-1 do begin
                            if (oPlanes[j] eq oDataItem) then $
                                continue
                            planeID = oPlanes[j]->GetFullIdentifier()
                            if (TOTAL(targetIds eq planeID) eq 0) then begin
                                ; Apply resample operation to this channel.
                                if (~self->_ExecuteOnData(oPlanes[j], $
                                    COMMAND_SET=oCommandSet)) then $
                                    return, 0
                            endif
                        endfor
                    endif
                endif
            endif
        endfor
    endif

    return, iStatus
 
end


;---------------------------------------------------------------------------
; Purpose:
;  Override the superclass method so we can return the appropriate
;  parameters.
;
; Arguments:
;   oTarget          - What to apply the operation on.
;
; Keywords:
;   COUNT: The number of returned parameter descriptor objects.
;
function IDLitopResample::_GetOpTargets, oTarget, COUNT=count

    compile_opt idl2, hidden

    oTarget->GetProperty, TYPE=visType

    case STRUPCASE(visType[0]) of

        ; Note: The first parameter in this list should have the
        ; largest dimension for that viz type, e.g. IMAGEPIXELS is 2D
        ; while the X and Y are only vectors. That way Resample
        ; gets the correct dimensions.

        'IDLPLOT': params = ['Y', 'X', $
            'Y ERROR', 'X ERROR', 'VERTEX_COLORS']

        'IDLPLOT3D': params = ['X', 'Y', 'Z', $
            'X ERROR', 'Y ERROR', 'Z ERROR', 'VERTEX_COLORS']

        'IDLIMAGE': params = ['IMAGEPIXELS', 'X', 'Y']

        'IDLSURFACE': params = ['Z', 'X', 'Y']

        'IDLCONTOUR': params = ['Z', 'X', 'Y']

        'IDLVOLUME': params = ['VOLUME0', 'VOLUME1', 'VOLUME2', 'VOLUME3']

        ; Call our superclass.
        else: return, $
            self->IDLitDataOperation::_GetOpTargets(oTarget, COUNT=count)

    endcase

    ; Return only a particular set of parameter descriptors.
    return, oTarget->QueryParameterDescriptor(params, COUNT=count)

end


;---------------------------------------------------------------------------
; Purpose:
;   Display UI before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;
;    0 - Error, discontinue the operation
;
Function IDLitopResample::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~oTool) then $
        return, 0

    ; Make sure we set up our data dimensions for the prop sheet.
    pData = self->_RetrieveDataPointers(DIMENSIONS=dims)
    if ~PTR_VALID(pData[0]) then $
        return, 0

    ; How many dimensions does our input data have?
    ndim = 1 + MAX(WHERE(dims gt 0))

    ; Desensitize properties for higher dimensions.
    case ndim of
        1: self->SetPropertyAttribute, $
            ['Y_RESAMPLE_FACTOR', 'Z_RESAMPLE_FACTOR'], SENSITIVE=0
        2: self->SetPropertyAttribute, 'Z_RESAMPLE_FACTOR', SENSITIVE=0
        3: begin
            self->SetPropertyAttribute, 'RESAMPLE_METHOD', SENSITIVE=0
            method = self._method
            self._method = 1 ; 3D always uses linear
           end
        else:
    endcase

    result = oTool->DoUIService('PropertySheet', self)

    ; Resensitize all.
    self->SetPropertyAttribute, ['Y_RESAMPLE_FACTOR', 'Z_RESAMPLE_FACTOR'], $
        /SENSITIVE

    if (ndim eq 3) then begin
        ; Restore the method
        self._method = method
        self->SetPropertyAttribute, 'RESAMPLE_METHOD', /SENSITIVE
    endif

    return, result

end


;-------------------------------------------------------------------------
pro IDLitopResample__define

    compile_opt idl2, hidden

    struc = {IDLitopResample, $
        inherits IDLitDataOperation,    $
        _xfactor: 0d, $
        _yfactor: 0d, $
        _zfactor: 0d, $
        _method: 0b $
        }

end

