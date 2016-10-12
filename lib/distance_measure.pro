; $Id: //depot/idl/releases/IDL_80/idldir/lib/distance_measure.pro#1 $
; Copyright (c) 2003-2010, ITT Visual Information Solutions. All
;       rights reserved. Unauthorized reproduction is prohibited.
;+
; NAME:
;   DISTANCE_MEASURE
;
; PURPOSE:
;   Compute the pairwise distance between a set of items.
;
; CATEGORY:
;   Statistics.
;
; CALLING SEQUENCE:
;   Result = DISTANCE_MEASURE(Array)
;
; INPUTS:
;   Array: An n-by-m array representing the coordinates
;       (in an n-dimensional space) of m items. For example,
;       a set of m points in a two-dimensional Cartesian space
;       would be passed in as a 2-by-m array.
;
; OUTPUTS:
;   The Result is a vector of m*(m-1)/2 elements containing the
;       distance matrix in compact form. Given a distance between
;       two items, D(i,j), the distances within Result are
;       returned in the order:
;       [D(0, 1),  D(0, 2), ..., D(0, m-1), D(1, 2), ..., D(m-2, m)].
;   If keyword MATRIX is set then the distance matrix is not returned
;       in compact form, but is instead returned as an m-by-m
;       symmetric array with zeroes along the diagonal.
;
; KEYWORD PARAMETERS:
;   DOUBLE: Set this keyword to perform computations using
;       double-precision arithmetic and to return a double-precision
;       result. Set DOUBLE=0 to use single-precision for computations
;       and to return a single-precision result.
;       The default is /DOUBLE if Array is double precision,
;       otherwise the default is DOUBLE=0.
;
;   MATRIX: Set this keyword to return the distance matrix as
;       an m-by-m symmetric array. If this keyword is not set
;       then the distance matrix is returned in compact vector form.
;
;   MEASURE: Set this keyword to an integer giving the distance measure
;       (the metric) to use. Possible values are:
;           MEASURE=0 (the default): Euclidean distance. The Euclidean
;               distance is defined as Sqrt(Total((Xi - Yi)^2)).
;           MEASURE=1: CityBlock (Manhattan) distance.
;               The CityBlock distance is defined as Total(Abs(Xi - Yi)).
;           MEASURE=2: Chebyshev distance. The Chebyshev
;               distance is defined as Max(Abs(Xi - Yi)).
;           MEASURE=3: Correlative distance. The correlative distance is
;               defined as Sqrt((1-r)/2), where r is the correlation
;               coefficient between two items.
;           MEASURE=4: Percent disagreement. This distance is defined
;               as (Number of Xi ne Yi)/n, and is useful for
;               categorical data.
;       This keyword is ignored if POWER_MEASURE is set.
;
;   POWER_MEASURE: Set this keyword to a scalar or a two-element vector
;       giving the parameters p and r to be used in the power distance,
;       defined as (Total(Abs(Xi - Yi)^p)^(1/r).
;       If POWER_MEASURE is a scalar then the same value is used for both
;       p and r (this is also known as the Minkowski distance).
;       Note that POWER_MEASURE=1 is the same as the CityBlock distance,
;       while POWER_MEASURE=2 is the same as Euclidean distance.
;
; EXAMPLE:
;    ; Given a set of points in two-dimensional space.
;    data = [ $
;        [1, 1], $
;        [1, 3], $
;        [2, 2.2], $
;        [4, 1.75], $
;        [4, 4], $
;        [5, 1], $
;        [5.5, 3]]
;
;    ; Compute the Euclidean distance between each point.
;    distance = DISTANCE_MEASURE(data)
;
;    i1 = [0,0,0,0,0,0, 1,1,1,1,1, 2,2,2,2, 3,3,3, 4,4, 5]
;    i2 = [1,2,3,4,5,6, 2,3,4,5,6, 3,4,5,6, 4,5,6, 5,6, 6]
;    PRINT, 'Item#  Item#  Distance'
;    PRINT, TRANSPOSE([[i1],[i2],[distance]]), $
;    format='(I3, I7, F10.2)'
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Sept 2003
;   Modified:
;
;-


;-------------------------------------------------------------------------
; Helper routine. Given the number of items m, construct index arrays
; Index1 and Index2 to allow the distance measure to be computed all
; at once. Index1 and Index2 are vectors of length m*(m-1)/2 which
; match every item in an array up with every other item.
;
pro distance_measure_indices, m, index1, index2

    compile_opt idl2, hidden

    n = m*(m-1)/2

    ii = 0L
    index0 = LINDGEN(m - 1) + 1   ; work array
    index1 = LONARR(n, /NOZERO)
    index2 = LONARR(n, /NOZERO)

    for i=0,m-2 do begin
        n1 = m - (i+1)
        ; Indices into first pair and second pair.
        index1[ii:ii+n1-1] = i
        index2[ii] = index0[0:n1-1] + i
        ii += n1
    endfor

end


;-------------------------------------------------------------------------
; Main routine.
;
function distance_measure, array, $
    DOUBLE=double, $
    MATRIX=matrix, $
    MEASURE=measureIn, $
    POWER_MEASURE=powerIn

    compile_opt idl2

    ON_ERROR, 2

    if (N_PARAMS() lt 1) then $
        MESSAGE, 'Incorrect number of arguments.'

    dims = SIZE(array, /DIMENSIONS)
    if (N_ELEMENTS(dims) ne 2 || dims[0] lt 2 || dims[1] lt 2) then $
        MESSAGE, 'Array must have two dimensions.'

    m = dims[1]

    type = SIZE(array, /TYPE)
    dbl = (N_ELEMENTS(double) gt 0) ? KEYWORD_SET(double) : $
        ((type eq 5) || (type eq 9))

    measure = (N_ELEMENTS(measureIn) eq 1) ? measureIn : 0


    ; Correlative distance
    if (measure eq 3 && ~N_ELEMENTS(powerIn)) then begin
        if (dims[0] le 2) then MESSAGE, $
            'First dimension must be greater than 2 for Correlative distance.'
        ; Correlate performs the cross-correlation between columns,
        ; so take the transpose.
        cor = CORRELATE(TRANSPOSE(array), DOUBLE=dbl)
        ; This will give us an m-by-m symmetric matrix.
        symresult = SQRT(0.5*(1 - cor))
        ; We're done if MATRIX is set.
        if (KEYWORD_SET(matrix)) then $
            return, symresult

        ; Otherwise convert to compact form.
        result = dbl ? DBLARR(m*(m-1)/2) : FLTARR(m*(m-1)/2)
        if (m eq 2) then $   ; convert to scalar
            result = result[0]

        ii = 0L
        n1 = m - 1
        for i=0,m-2 do begin
            result[ii] = symresult[i+1:*, i]
            ii += n1
            n1--
        endfor

        return, result

    endif


    ; Construct indices to compute all of the distances at once.
    DISTANCE_MEASURE_INDICES, m, idx1, idx2

    ; Calculate abs difference.
    if (measure le 2 || N_ELEMENTS(powerIn)) then begin
        ; Convert to float/double if necessary.
        newtype = (type eq 6 || type eq 9) ? (dbl ? 9 : 6) : (dbl ? 5 : 4)
        if (newtype ne type) then begin
            ; For speed, convert to new type before indexing.
            arr = FIX(array, TYPE=newtype)
            arr1 = arr[*, TEMPORARY(idx1)]
            arr2 = arr[*, TEMPORARY(idx2)]
        endif else begin
            arr1 = array[*, TEMPORARY(idx1)]
            arr2 = array[*, TEMPORARY(idx2)]
        endelse
        diff = ABS(TEMPORARY(arr1) - TEMPORARY(arr2))
    endif


    if (N_ELEMENTS(powerIn) gt 0) then begin

        power = (N_ELEMENTS(powerIn) eq 1) ? [powerIn, powerIn] : powerIn
        power = dbl ? DOUBLE(power) : FLOAT(power)
        result = TOTAL(TEMPORARY(diff)^power[0], 1)^ $
            (1/power[1])

    endif else begin

        case measure of

            0: result = SQRT(TOTAL(TEMPORARY(diff)^2, 1))  ; Euclidean

            1: result = TOTAL(TEMPORARY(diff), 1)  ; CityBlock

            2: result = MAX(TEMPORARY(diff), DIMENSION=1)  ; Chebyshev

            4: $  ; Percent disagreement
             result = TOTAL(array[*,idx1] ne array[*,idx2], 1, $
                DOUBLE=dbl)/dims[0]

            else: MESSAGE, 'Illegal keyword value for MEASURE.'

        endcase

    endelse

    ; Expand from vector to symmetric m-by-m array.
    if (KEYWORD_SET(matrix)) then begin
        pairdistance = TEMPORARY(result)
        result = dbl ? DBLARR(m, m) : FLTARR(m, m)
        ii = 0L
        for j=0,m-2 do begin
            nn = m - j - 1
            result[j,j+1:*] = pairdistance[ii:ii + nn - 1]
            ii += nn
        endfor
        ; Create the symmetric half.
        result += TRANSPOSE(result)
    endif

    return, result
end

