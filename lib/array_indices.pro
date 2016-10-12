; $Id: //depot/idl/releases/IDL_80/idldir/lib/array_indices.pro#1 $
; Copyright (c) 2002-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   ARRAY_INDICES
;
; PURPOSE:
;   Given an input array, this function converts one-dimensional
;   subscripts back into the corresponding multi-dimensional subscripts.
;
;
; CALLING SEQUENCE:
;   Result = ARRAY_INDICES(Array, Index)
;
;
; RETURN VALUE:
;   If Index is a scalar, then the Result will be a vector containing
;   the M multi-dimensional subscripts. If Index is a vector containing
;   N elements, then the Result will be a (M x N) array, with each row
;   containing the multi-dimensional subscripts corresponding to that Index.
;
;
; INPUTS:
;   Array: An array of any type, whose dimensions should be used in
;       converting the subscripts. If DIMENSIONS is set then Array
;       should be a vector containing the dimensions.
;
;   Index: A scalar or vector containing the subscript(s) to be converted.
;
;
; KEYWORD PARAMETERS:
;   DIMENSIONS: If this keyword is set, then Array is assumed to be
;       a vector containing the dimensions.
;   Tip: This keyword is useful when you don't have the actual Array,
;       and want to avoid allocating the array just to find the indices.
;
;
; EXAMPLE:
;   Simple example.
;       seed = 111
;       array = RANDOMU(seed, 10, 10)
;       mx = MAX(array, location)
;       ind = ARRAY_INDICES(array, location)
;       print, ind, array[ind[0],ind[1]], $
;           format = '(%"Value at [%d, %d] is %f")'
;
;   Example using DIMENSIONS.
;   This will give the same results as the first example.
;       dims = SIZE(array, /DIMENSIONS)
;       ind = ARRAY_INDICES(dims, location, /DIMENSIONS)
;
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, October 2002
;   Modified: CT, RSI, July 2004: Added DIMENSIONS keyword.
;             CT, Aug 2006: Return correct type when using DIMENSIONS.
;
;-

function array_indices, array, indices, DIMENSIONS=dimensions

    compile_opt idl2

    ON_ERROR, 2

    ; Error checking.
    if (N_PARAMS() ne 2) then $
        MESSAGE, 'Incorrect number of arguments.'


    ; Check for valid types.
    type = SIZE(indices, /TYPE)
    switch (type) of
        6:      ; complex
        7:      ; string
        8:      ; struct
        9:      ; dcomplex
        10:     ; pointer
        11: $   ; objref
            MESSAGE, 'Index must be an integer.'
        else: ; okay, do nothing
    endswitch


    ; Check for valid index range.
    mn = MIN(indices, MAX=mx)

    if (KEYWORD_SET(dimensions)) then begin
        ; Array contains the dimensions.
        nelts = PRODUCT(array, /INTEGER)
        tarray = SIZE(array, /TYPE)
        ndim = N_ELEMENTS(array)
        ; Return either 64-bit ints or 32-bit ints, depending on overflow.
        dim = ((nelts gt 2147483647L) || $
            (tarray eq 14) || (tarray eq 15) || $
            (type eq 14) || (type eq 15)) ? LONG64(array) : LONG(array)
    endif else begin
        ; Retrieve the dimensions from the Array variable.
        nelts = N_ELEMENTS(array)
        ndim = SIZE(array, /N_DIMENSIONS)
        dim = SIZE(array, /DIMENSIONS)
    endelse

    if (mn lt 0 || mx ge nelts) then $
        MESSAGE, 'Index out of range.'


    ; If we have a scalar or vector, we're done. Just return the indices.
    if (ndim le 1) then $
        return, indices

    ni = N_ELEMENTS(indices)

    ; Result type is either Long or Long64 depending upon platform.
    result = MAKE_ARRAY(ndim, ni, /NOZERO, TYPE=SIZE(dim, /TYPE))

    if (ndim eq 2) then begin   ; Simple 2D case.

        result[0, *] = indices mod dim[0]  ; first dimension
        result[1, *] = indices/dim[0]      ; second dimension

    endif else begin  ; Multidimensional case.

        ; Product of all "previous" dimensions.
        dimProduct = PRODUCT(dim, /CUMULATIVE, /INTEGER)

        temp = indices   ; make a working copy

        for d=ndim-1, 1, -1 do begin
            ; Remove indices from even higher dimensions.
            if (d lt ndim-1) then $
                temp mod= dimProduct[d]
            ; Indices for higher dimensions.
            result[d, *] = temp/dimProduct[d-1]
        endfor

        ; Indices for first dimension.
        result[0, *] = temp mod dim[0]

    endelse

    return, result

end

