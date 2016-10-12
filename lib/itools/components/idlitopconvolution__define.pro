; $Id: //depot/idl/releases/IDL_80/idldir/lib/itools/components/idlitopconvolution__define.pro#1 $
;
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the convolution action.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitopConvolution object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass Init.
;
function IDLitopConvolution::Init, _EXTRA=_extra

    compile_opt idl2, hidden

    success = self->IDLitDataOperation::Init( $
        NAME="Convolution", $
        DESCRIPTION="Perform the convolution operation on the selected item", $
        TYPES=["IDLVECTOR", "IDLARRAY2D", "IDLIMAGE", "IDLROI"], $
        NUMBER_DS='1')
    if (~success) then $
        return, 0

    if (~self->_IDLitROIPixelOperation::Init(_EXTRA=_exta)) then begin
        self->Cleanup
        return, 0
    endif

    ; Defaults
    self._autoscale = 1
    self._center = 1
    self._edge = 1
    self._nx = 3
    self._ny = 3
    self._kernel = PTR_NEW(/ALLOCATE)

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->IDLitopConvolution::_RegisterProperties

    self->_RegisterDefaultFilters

    self->IDLitopConvolution::SetProperty, FILTER_INDEX=1, _EXTRA=_extra

    return, 1

end


;----------------------------------------------------------------------------
pro IDLitopConvolution::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    ; New properties for IDL62.
    if (registerAll || updateFromVersion lt 620) then begin

        self->RegisterProperty, 'FILTER_INDEX', ENUMLIST='', $
            NAME='Filter', $
            DESCRIPTION='Filter name'

        self->RegisterProperty, 'NCOLUMNS', /INTEGER, $
            NAME='Number of columns', $
            DESCRIPTION='Number of columns', $
            VALID_RANGE=[1,2147483646]

        self->RegisterProperty, 'NROWS', /INTEGER, $
            NAME='Number of rows', $
            DESCRIPTION='Number of rows', $
            VALID_RANGE=[1,2147483646]

    endif

    edgeEnum = ['Zero result', 'Wrap around', 'Repeat last value', 'Zero pad']
    autoScaleName = 'Auto normalize'

    if (registerAll) then begin

        self->RegisterProperty, 'Kernel', USERDEF='Click to edit', $
            Description='Convolution kernel'

        self->RegisterProperty, 'Center', /BOOLEAN, $
            DESCRIPTION='Center the kernel over each array point'

        self->RegisterProperty, 'AUTOSCALE', /BOOLEAN, $
            NAME=autoScaleName, $
            DESCRIPTION='Compute the scale factor and bias automatically'

        self->RegisterProperty, 'SCALE_FACTOR', /FLOAT, SENSITIVE=0, $
            NAME='Scale factor', $
            Description='Scale factor divided into each resulting value'

    endif

    ; New properties for IDL62.
    if (registerAll || updateFromVersion lt 620) then begin
        self->RegisterProperty, 'BIAS', /FLOAT, SENSITIVE=0, $
            NAME='Bias offset', $
            Description='Bias offset to be added to each result, after scale factor'
    endif

    if (registerAll) then begin

        self->RegisterProperty, 'EDGE', $
            NAME='Edge values', $
            ENUMLIST=edgeEnum, $
            DESCRIPTION='Method used to compute edge values'

        self->RegisterProperty, 'ONE_DIMENSIONAL', /BOOLEAN, /HIDE, $
            NAME='One dimensional', $
            DESCRIPTION='Show a one or two-dimensional kernel in the GUI'

    endif

    ; New properties for IDL62.
    if (registerAll || updateFromVersion lt 620) then begin
        self->RegisterProperty, 'USE_INVALID', /BOOLEAN, $
            NAME='Use invalid value', $
            Description='Use the invalid value'
        self->RegisterProperty, 'INVALID', /FLOAT, SENSITIVE=0, $
            NAME='Invalid value', $
            Description='Missing or invalid value that should be ignored'
        self->RegisterProperty, 'MISSING', /FLOAT, $
            NAME='Replacement value', $
            Description='Replace missing results with this value'
    endif

    ; In IDL62 we changed some attributes and
    ; added the 'Zero pad' edge option.
    if (~registerAll && updateFromVersion lt 620) then begin
        self->SetPropertyAttribute, 'AUTOSCALE', NAME=autoScaleName
        self->SetPropertyAttribute, 'EDGE', ENUMLIST=edgeEnum
        self->SetPropertyAttribute, 'ONE_DIMENSIONAL', /HIDE
    endif

end


;----------------------------------------------------------------------------
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitopConvolution::Restore

    compile_opt idl2, hidden

    ; Register new properties.
    self->IDLitopConvolution::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; Required for SAVE files transitioning from IDL 6.1 to 6.2 or above.
    if (self.idlitcomponentversion lt 620) then begin

        self->_RegisterDefaultFilters

        ; Set the new ncolumns/nrows properties to the kernel size.
        dims = SIZE(*self._kernel, /DIMENSIONS)
        self._nx = dims[0]
        if (N_ELEMENTS(dims) gt 1) then $
        self._ny = dims[1]

        self->GetPropertyAttribute, 'Kernel', USERDEF=oldKernelName
        ; The default is now called Tent.
        if (oldKernelName eq 'Default') then $
            oldKernelName = 'Tent'

        ; The kernel name is now stored in the FILTER_INDEX enumlist.
        self->SetPropertyAttribute, 'Kernel', USERDEF='Click to edit'

        match = (WHERE(STRCMP(*self._filternames, oldKernelName, $
            STRLEN(*self._filternames), /FOLD_CASE)))[0]

        ; Set the filter index to match the IDL61 kernel, or reset
        ; to zero if no match.
        self->IDLitopConvolution::SetProperty, FILTER_INDEX=(match > 0)

    endif


end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor of the IDLitopConvolution object.
;
; Arguments:
;   None.
;
; Keywords:
;   None.
;
pro IDLitopConvolution::Cleanup

    compile_opt idl2, hidden

    PTR_FREE, self._kernel
    PTR_FREE, self._filternames
    PTR_FREE, self._functions
    PTR_FREE, self._fixedwidth

    self->_IDLitROIPixelOperation::Cleanup
    self->IDLitDataOperation::Cleanup
end


;-------------------------------------------------------------------------
; Purpose:
;   Retrieve property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to Init.
;
pro IDLitopConvolution::GetProperty, $
    AUTOSCALE=autoscale, $
    BIAS=bias, $
    CENTER=center, $
    EDGE=edge, $
    FILTER_INDEX=filterindex, $
    FILTER_NAME=filterName, $   ; obsolete in IDL62
    INVALID=invalid, $
    KERNEL=kernel, $
    MINIMUM_DIMENSION=minDim, $
    MISSING=missing, $
    NCOLUMNS=ncolumns, $
    NROWS=nrows, $
    ONE_DIMENSIONAL=oneDimensional, $
    SCALE_FACTOR=scale, $
    USE_INVALID=useInvalid, $
    _REF_EXTRA=_extra


    compile_opt idl2, hidden

    ; Sanity check for restored macros.
    if (~PTR_VALID(self._filternames)) then $
        self->_RegisterDefaultFilters

    if (ARG_PRESENT(bias)) then $
        bias = self._bias

    if (arg_present(filterindex)) then $
        filterindex = self._filterindex

    if (arg_present(filterName)) then $
        filterName = ''   ; obsolete in IDL62

    if (arg_present(autoscale)) then $
        autoscale = self._autoscale

    if (arg_present(center)) then $
        center = self._center

    if (arg_present(edge)) then $
        edge = self._edge

    if (arg_present(invalid)) then $
        invalid = self._invalid

    if (arg_present(missing)) then $
        missing = self._missing

    if (arg_present(kernel)) then begin
        idx = self._filterindex
        if (idx gt 0 && $
            idx lt N_ELEMENTS(*self._filternames)) then begin
            if ((*self._fixedwidth)[idx]) then begin
                kernel = CALL_FUNCTION((*self._functions)[idx])
            endif else begin
                kernel = CALL_FUNCTION((*self._functions)[idx], $
                    self._nx > 1, self._ny > 1)
            endelse
        endif else begin
            kernel = *self._kernel
        endelse
    endif

    if (arg_present(minDim)) then begin
        minDim = (self._nx > self._ny) + 1
    endif

    if (arg_present(ncolumns)) then $
        ncolumns = self._nx

    if (arg_present(nrows)) then $
        nrows = self._ny

    if (arg_present(oneDimensional)) then $
        oneDimensional = self._is1D

    if (arg_present(scale)) then $
        scale = self._scale

    if (arg_present(useInvalid)) then $
        useInvalid = self._useInvalid

    if (n_elements(_extra) gt 0) then $
        self->IDLitDataOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose:
;   Set property values.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to Init.
;
pro IDLitopConvolution::SetProperty, $
    AUTOSCALE=autoscale, $
    BIAS=bias, $
    CENTER=center, $
    EDGE=edge, $
    FILTER_INDEX=filterindex, $
    INVALID=invalid, $
    KERNEL=kernel, $
    MISSING=missing, $
    NCOLUMNS=ncolumns, $
    NROWS=nrows, $
    ONE_DIMENSIONAL=oneDimensional, $
    SCALE_FACTOR=scale, $
    USE_INVALID=useInvalid, $
    _EXTRA=_extra


    compile_opt idl2, hidden

    updateFilter = 0b

    ; Sanity check for restored macros.
    if (~PTR_VALID(self._filternames)) then $
        self->_RegisterDefaultFilters

    if (N_ELEMENTS(filterindex) eq 1 && $
            filterindex lt N_ELEMENTS(*self._filternames)) then begin
        self._filterindex = filterindex
        updateFilter = 1b
    endif

    if (N_ELEMENTS(autoscale) ne 0) then begin
        self._autoscale = KEYWORD_SET(autoscale)
        self->SetPropertyAttribute, ['SCALE_FACTOR', 'BIAS'], $
            SENSITIVE=~self._autoscale
        updateFilter = 1b
    endif

    if (N_ELEMENTS(bias) ne 0) then $
        self._bias = bias

    if (N_ELEMENTS(center) ne 0) then $
        self._center = KEYWORD_SET(center)

    if (N_ELEMENTS(edge) ne 0) then $
        self._edge = edge

    if (N_ELEMENTS(invalid) ne 0) then $
        self._invalid = invalid

    if (N_ELEMENTS(missing) ne 0) then $
        self._missing = missing

    if (N_ELEMENTS(ncolumns) ne 0) then begin
        self._nx = ncolumns
        ; If we are within the UI, then we have valid data and we can
        ; compute the new bias offset (only for byte or uint).
        if PTR_VALID(self._pData) then begin
            self._nx <= (SIZE(*self._pData, /DIMENSIONS))[0]
        endif
        updateFilter = 1b
    endif

    if (N_ELEMENTS(nrows) ne 0) then begin
        self._ny = nrows
        ; If we are within the UI, then we have valid data and we can
        ; compute the new bias offset (only for byte or uint).
        if PTR_VALID(self._pData) then begin
            ndim = SIZE(*self._pData, /N_DIMENSION)
            self._ny <= (ndim ge 2) ? (SIZE(*self._pData, /DIMENSIONS))[1] : 1
        endif
        updateFilter = 1b
    endif

    if (N_ELEMENTS(oneDimensional) ne 0) then $
        self._is1D = KEYWORD_SET(oneDimensional)

    if (N_ELEMENTS(scale) ne 0) then $
        self._scale = scale

    if (N_ELEMENTS(kernel) ne 0) then begin
        *self._kernel = kernel
        self._filterindex = 0   ; user defined
        updateFilter = 1b
    endif

    if (N_ELEMENTS(useInvalid) ne 0) then begin
        self._useInvalid = useInvalid
        self->SetPropertyAttribute, 'INVALID', SENSITIVE=self._useInvalid
    endif

    if (updateFilter) then $
        self->_UpdateFilter

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitDataOperation::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
function IDLitopConvolution::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

        'KERNEL': begin
            self->GetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=wasUIHide
            self->GetPropertyAttribute, 'KERNEL', HIDE=wasKernelHide
            if (~wasUIHide) then $
                self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', /HIDE
            ; Don't allow user to recursively fire up the userdef UI.
            if (~wasKernelHide) then $
                self->SetPropertyAttribute, 'KERNEL', /HIDE
            success = oTool->DoUIService('ConvolKernel', self)
            if (~wasUIHide) then $
                self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0
            if (~wasKernelHide) then $
                self->SetPropertyAttribute, 'KERNEL', HIDE=0
            return, success
            end

        else:

    endcase

    ; Call our superclass.
    return, self->IDLitDataOperation::EditUserDefProperty(oTool, identifier)

end


;---------------------------------------------------------------------------
; IDLitopConvolution::DoExecuteUI
;
; Purpose:
;   Display convolution UI before execution.
;
; Arguments
;  None
;
; Return Value
;    1 - Success...proceed with the operation.
;
;    0 - Error, discontinue the operation
;
Function IDLitopConvolution::DoExecuteUI

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    self._pData = (self->_RetrieveDataPointers())[0]

    self->GetPropertyAttribute, 'NROWS', SENSITIVE=wasSens

    if (PTR_VALID(self._pData)) then begin
        ndim = SIZE(*self._pData, /N_DIMENSION)
        dims = SIZE(*self._pData, /DIMENSIONS)
        self._nx <= dims[0]
        self._ny <= (ndim ge 2) ? dims[1] : 1
        if (wasSens && ndim eq 1) then $
            self->SetPropertyAttribute, 'NROWS', SENSITIVE=0
    endif


    ; Fire up the UserDef property sheet.
    success = self->EditUserDefProperty(oTool, 'KERNEL')

    self._pData = PTR_NEW()

    if (wasSens) then $
        self->SetPropertyAttribute, 'NROWS', /SENSITIVE

    return, success

end


;---------------------------------------------------------------------------
; IDLitopConvolution::Execute
;
; Purpose:
;   This function method executes the convolution operation to the given
;   data.
;
; Parameters:
;   data: The data on which the operation is to be performed.
;
function IDLitopConvolution::Execute, data, MASK=mask

    compile_opt idl2, hidden

    self->GetProperty, KERNEL=kernel

    ; For vector data, just pull out the middle of the kernel.
    kdim = SIZE(kernel, /DIMENSIONS)
    if (SIZE(data, /N_DIM) eq 1) && (SIZE(kernel, /N_DIM) eq 2) then $
        kernel = kernel[*,kdim[1]/2]

    ; Either use a dummy scale or use provided scale.
    scale = self._autoscale ? 1 : self._scale
    if (scale eq 0) then $
        scale = 1

    ; Only pass in BIAS if necessary.
    if (~self._autoscale && self._bias ne 0) then $
        bias = self._bias

    if (self._useInvalid) then $
        invalid = self._invalid

    if (N_ELEMENTS(mask) ne 0) then begin
        iMask = WHERE(mask ne 0, nMask)
        if (nMask eq 0) then $
            return, 0
    endif

    ; Perform the convolution.
    result = CONVOL(data, kernel, scale, $
        BIAS=bias, $
        CENTER=self._center, $
        EDGE_TRUNCATE=(self._edge eq 2), $
        EDGE_WRAP=(self._edge eq 1), $
        EDGE_ZERO=(self._edge eq 3), $
        MISSING=self._missing, $
        INVALID=invalid, $
        NAN=self._nan, $
        NORMALIZE=self._autoscale)

    if (N_ELEMENTS(mask) ne 0) then begin
        data[iMask] = result[iMask]
    endif else begin
        data = TEMPORARY(result)
    endelse

    return,1
end


;-------------------------------------------------------------------------
pro IDLitopConvolution::_UpdateFilter

    compile_opt idl2, hidden

    self->GetProperty, KERNEL=kernel

    if (SIZE(kernel, /N_DIM) eq 0) then $
        return

    if (self._filterindex gt 0) then $
        *self._kernel = kernel
    dims = SIZE(kernel, /DIMENSIONS)
    self._nx = dims[0]
    if (N_ELEMENTS(dims) gt 1) then $
        self._ny = dims[1]

    if (self._autoscale) then begin
        self._scale = TOTAL(ABS(kernel), /DOUBLE)
        ; If we are within the UI, then we have valid data and we can
        ; compute the new bias offset (only for byte or uint).
        if PTR_VALID(self._pData) then begin
            type = SIZE(*self._pData, /TYPE)
            if (type eq 1 || type eq 12) then begin
                self._bias = -LONG(TOTAL(kernel < 0, /DOUBLE)*$
                    (((type eq 1) ? 255 : 65535)/self._scale))
            endif
        endif
    endif

    isFixed = (*self._fixedwidth)[self._filterindex]
    self->SetPropertyAttribute, ['NCOLUMNS', 'NROWS'], SENSITIVE=~isFixed

end


;-------------------------------------------------------------------------
pro IDLitopConvolution::RegisterFilter, filterName, functionCall, $
    FIXED_WIDTH=fixedWidth

    compile_opt idl2, hidden

    if (~PTR_VALID(self._filternames)) then begin
        self._filternames = PTR_NEW('User defined')
        self._functions = PTR_NEW('')
        self._fixedwidth = PTR_NEW(1b)
    endif

    *self._filternames = [*self._filternames, filterName]
    *self._functions = [*self._functions, functionCall]
    *self._fixedwidth = [*self._fixedwidth, KEYWORD_SET(fixedWidth)]

    self->SetPropertyAttribute, 'FILTER_INDEX', ENUMLIST=*self._filternames
end


;-------------------------------------------------------------------------
pro IDLitopConvolution::_RegisterDefaultFilters

    compile_opt idl2, hidden

    self->RegisterFilter, 'Tent', 'IDLitopConvolution__Tent'
    self->RegisterFilter, 'Boxcar', 'IDLitopConvolution__Boxcar'
    self->RegisterFilter, 'Gaussian', 'IDLitopConvolution__Gaussian'

    self->RegisterFilter, 'Edge Horizontal', 'IDLitopConvolution__EdgeHoriz', /FIXED
    self->RegisterFilter, 'Edge Vertical', 'IDLitopConvolution__EdgeVert', /FIXED
    self->RegisterFilter, 'Edge Diagonal Right', 'IDLitopConvolution__EdgeRight', /FIXED
    self->RegisterFilter, 'Edge Diagonal Left', 'IDLitopConvolution__EdgeLeft', /FIXED
    self->RegisterFilter, 'Line Horizontal', 'IDLitopConvolution__LineHoriz', /FIXED
    self->RegisterFilter, 'Line Vertical', 'IDLitopConvolution__LineVert', /FIXED
    self->RegisterFilter, 'Line Diagonal Right', 'IDLitopConvolution__LineRight', /FIXED
    self->RegisterFilter, 'Line Diagonal Left', 'IDLitopConvolution__LineLeft', /FIXED
    self->RegisterFilter, 'Laplacian', 'IDLitopConvolution__Laplace', /FIXED
    self->RegisterFilter, 'Emboss', 'IDLitopConvolution__Emboss', /FIXED

end


;-------------------------------------------------------------------------
function IDLitopConvolution__Tent, nx, ny

    compile_opt idl2, hidden

    x = DINDGEN(nx) - (nx-1)/2
    x = (nx+2)/2 - ABS(x)
    y = DINDGEN(ny) - (ny-1)/2
    y = (ny+2)/2 - ABS(y)
    kernel = x # y + 1d-6

    factor = 1/MIN(kernel) < 16384
    kernel = TEMPORARY(kernel)*factor + 1d-6
    return, LONG(kernel)

end


;-------------------------------------------------------------------------
function IDLitopConvolution__Boxcar, nx, ny

    compile_opt idl2, hidden

    return, LONARR(nx, ny) + 1

end


;-------------------------------------------------------------------------
function IDLitopConvolution__Gaussian, nx, ny

    compile_opt idl2, hidden

    ; exp(-x^2/2) equals 0.5 at x = sqrt(-2alog(2)) = 1.17741
    ; Half amplitude will occur at -nx/2, +nx/2 from center
    ; One standard deviation occurs at (+/-)nx/(4*1.17741)
    x = 1.17741d*(DINDGEN(nx) - (nx-1)/2)/(nx/4 > 1)
    y = 1.17741d*(DINDGEN(ny) - (ny-1)/2)/(ny/4 > 1)
    kernel = EXP(-x^2/2) # EXP(-y^2/2)

    factor = 1/MIN(kernel) < 16384
    kernel = TEMPORARY(kernel)*factor + 1d-6
    return, LONG(kernel)

end


;-------------------------------------------------------------------------
function IDLitopConvolution__EdgeHoriz

    compile_opt idl2, hidden

    kernel = [ $
        [ 1,  0, -1], $
        [ 2,  0, -2], $
        [ 1,  0, -1]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__EdgeVert

    compile_opt idl2, hidden

    kernel = [ $
        [ 1,  2,  1], $
        [ 0,  0,  0], $
        [-1, -2, -1]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__EdgeRight

    compile_opt idl2, hidden

    kernel = [ $
        [ 0,  1,  0], $
        [-1,  0,  1], $
        [ 0, -1,  0]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__EdgeLeft

    compile_opt idl2, hidden

    kernel = [ $
        [ 0, -1,  0], $
        [-1,  0,  1], $
        [ 0,  1,  0]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__LineHoriz

    compile_opt idl2, hidden

    kernel = [ $
        [-1, -1, -1], $
        [ 2,  2,  2], $
        [-1, -1, -1]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__LineVert

    compile_opt idl2, hidden

    kernel = [ $
        [-1,  2, -1], $
        [-1,  2, -1], $
        [-1,  2, -1]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__LineRight

    compile_opt idl2, hidden

    kernel = [ $
        [ 2, -1, -1], $
        [-1,  2, -1], $
        [-1, -1,  2]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__LineLeft

    compile_opt idl2, hidden

    kernel = [ $
        [-1, -1,  2], $
        [-1,  2, -1], $
        [ 2, -1, -1]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__Laplace

    compile_opt idl2, hidden

    ; exp(-x^2/2) equals 0.5 at x = sqrt(-2alog(2)) = 1.17741
    ; Half amplitude will occur at -nx/2, +nx/2 from center
    ; One standard deviation occurs at (+/-)nx/(4*1.17741)
;    x = 0.75*1.17741d*(DINDGEN(nx) - (nx-1)/2)/(nx/4 > 1)
;    y = 0.75*1.17741d*(DINDGEN(ny) - (ny-1)/2)/(ny/4 > 1)
;    gausskernel = EXP(-x^2/2) # EXP(-y^2/2)
;
;    x2 = REBIN(x^2/2, nx, ny)
;    y2 = REBIN(TRANSPOSE(y)^2/2, nx, ny)
;    kernel = 1 - (TEMPORARY(x2) + TEMPORARY(y2))
;    kernel = TEMPORARY(kernel)*TEMPORARY(gausskernel)
;
;    if (state.isInt) then begin
;        factor = 1/MIN(ABS(kernel)) < 16384
;        kernel = TEMPORARY(kernel)*factor + 1d-6
;    endif

    kernel = [ $
        [ 0, -1,  0], $
        [-1,  4, -1], $
        [ 0, -1,  0]]
    return, kernel

end


;-------------------------------------------------------------------------
function IDLitopConvolution__Emboss

    compile_opt idl2, hidden

    kernel = [ $
        [-1,  0,  0], $
        [ 0,  0,  0], $
        [ 0,  0,  1]]
    return, kernel

end


;-------------------------------------------------------------------------
pro IDLitopConvolution__define

    compile_opt idl2, hidden

    struc = {IDLitopConvolution, $
        inherits IDLitDataOperation,    $
        inherits _IDLitROIPixelOperation, $
        _autoscale: 0b, $
        _center: 0b, $
        _edge: 0b, $
        _is1D: 0b, $
        _useInvalid: 0b, $
        _kernel: PTR_NEW(),   $
        _pData: PTR_NEW(), $
        _invalid: 0d, $
        _missing: 0d, $
        _bias: 0d, $
        _scale: 0d, $
        _filterindex: 0L, $
        _nx: 0L, $
        _ny: 0L, $
        _filternames: PTR_NEW(), $
        _functions: PTR_NEW(), $
        _fixedwidth: PTR_NEW() $
        }

end

